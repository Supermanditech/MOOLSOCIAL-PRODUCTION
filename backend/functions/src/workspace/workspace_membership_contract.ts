export const workspaceMembershipStates = [
  "pending",
  "active",
  "revoked",
  "expired",
] as const;

export type WorkspaceMembershipState =
  (typeof workspaceMembershipStates)[number];

export type WorkspaceMembershipContractErrorCode =
  | "invalid_input"
  | "account_mismatch"
  | "duplicate_conflict"
  | "workspace_conflict"
  | "invalid_transition";

export class WorkspaceMembershipContractError extends Error {
  constructor(
    readonly code: WorkspaceMembershipContractErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "WorkspaceMembershipContractError";
  }
}

export interface WorkspaceMembershipRecord {
  readonly schemaVersion: 1;
  readonly membershipId: string;
  readonly accountId: string;
  readonly workspaceId: string;
  readonly workspaceProfileId: string;
  readonly state: WorkspaceMembershipState;
  readonly version: number;
  readonly grantedAt: string;
  readonly effectiveFrom?: string;
  readonly expiresAt?: string;
  readonly revokedAt?: string;
}

export interface ActiveWorkspaceMembership {
  readonly schemaVersion: 1;
  readonly membershipId: string;
  readonly workspaceId: string;
  readonly workspaceProfileId: string;
  readonly state: "active";
  readonly version: number;
  readonly effectiveFrom: string;
  readonly expiresAt?: string;
}

export interface ProjectActiveWorkspaceMembershipsRequest {
  readonly accountId: string;
  readonly at: string;
  readonly memberships: readonly WorkspaceMembershipRecord[];
}

type NormalizedWorkspaceMembership = {
  readonly schemaVersion: 1;
  readonly membershipId: string;
  readonly accountId: string;
  readonly workspaceId: string;
  readonly workspaceProfileId: string;
  readonly state: WorkspaceMembershipState;
  readonly version: number;
  readonly grantedAt: string;
  readonly effectiveFrom: string;
  readonly expiresAt?: string;
  readonly revokedAt?: string;
};

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;

function fail(
  code: WorkspaceMembershipContractErrorCode,
  message: string,
): never {
  throw new WorkspaceMembershipContractError(code, message);
}

function identifier(value: string, label: string): string {
  const normalized = value.trim();
  if (!IDENTIFIER_PATTERN.test(normalized)) {
    fail("invalid_input", `${label} must be a stable identifier.`);
  }
  return normalized;
}

function timestamp(value: string, label: string): string {
  const milliseconds = Date.parse(value);
  if (!Number.isFinite(milliseconds)) {
    fail("invalid_input", `${label} must be a valid timestamp.`);
  }
  const normalized = new Date(milliseconds).toISOString();
  if (normalized !== value) {
    fail("invalid_input", `${label} must use canonical UTC ISO-8601.`);
  }
  return normalized;
}

function optionalTimestamp(
  value: string | undefined,
  label: string,
): string | undefined {
  return value === undefined ? undefined : timestamp(value, label);
}

function state(value: WorkspaceMembershipState): WorkspaceMembershipState {
  if (!workspaceMembershipStates.includes(value)) {
    fail("invalid_input", "membership state is unsupported.");
  }
  return value;
}

function version(value: number): number {
  if (!Number.isSafeInteger(value) || value < 1) {
    fail("invalid_input", "membership version must be a positive integer.");
  }
  return value;
}

function normalizeMembership(
  record: WorkspaceMembershipRecord,
): NormalizedWorkspaceMembership {
  if (record.schemaVersion !== 1) {
    fail("invalid_input", "membership schema version is unsupported.");
  }
  const grantedAt = timestamp(record.grantedAt, "grantedAt");
  const effectiveFrom = optionalTimestamp(
    record.effectiveFrom,
    "effectiveFrom",
  ) ?? grantedAt;
  const expiresAt = optionalTimestamp(record.expiresAt, "expiresAt");
  const revokedAt = optionalTimestamp(record.revokedAt, "revokedAt");
  const normalizedState = state(record.state);

  if (Date.parse(effectiveFrom) < Date.parse(grantedAt)) {
    fail("invalid_transition", "membership cannot start before it is granted.");
  }
  if (
    expiresAt !== undefined &&
    Date.parse(expiresAt) <= Date.parse(effectiveFrom)
  ) {
    fail("invalid_transition", "membership expiry must follow its start.");
  }
  if (
    revokedAt !== undefined &&
    Date.parse(revokedAt) < Date.parse(grantedAt)
  ) {
    fail("invalid_transition", "membership cannot be revoked before grant.");
  }
  if (normalizedState === "revoked" && revokedAt === undefined) {
    fail("invalid_transition", "revoked membership requires revokedAt.");
  }
  if (normalizedState !== "revoked" && revokedAt !== undefined) {
    fail(
      "invalid_transition",
      "only a revoked membership may contain revokedAt.",
    );
  }
  if (normalizedState === "expired" && expiresAt === undefined) {
    fail("invalid_transition", "expired membership requires expiresAt.");
  }

  return Object.freeze({
    schemaVersion: 1 as const,
    membershipId: identifier(record.membershipId, "membership id"),
    accountId: identifier(record.accountId, "account id"),
    workspaceId: identifier(record.workspaceId, "workspace id"),
    workspaceProfileId: identifier(
      record.workspaceProfileId,
      "workspace profile id",
    ),
    state: normalizedState,
    version: version(record.version),
    grantedAt,
    effectiveFrom,
    ...(expiresAt === undefined ? {} : { expiresAt }),
    ...(revokedAt === undefined ? {} : { revokedAt }),
  });
}

function recordFingerprint(record: NormalizedWorkspaceMembership): string {
  return JSON.stringify(record);
}

function activeAt(
  record: NormalizedWorkspaceMembership,
  atMilliseconds: number,
): boolean {
  if (record.state !== "active") return false;
  if (Date.parse(record.effectiveFrom) > atMilliseconds) return false;
  return (
    record.expiresAt === undefined ||
    atMilliseconds < Date.parse(record.expiresAt)
  );
}

function project(
  record: NormalizedWorkspaceMembership,
): ActiveWorkspaceMembership {
  return Object.freeze({
    schemaVersion: 1 as const,
    membershipId: record.membershipId,
    workspaceId: record.workspaceId,
    workspaceProfileId: record.workspaceProfileId,
    state: "active" as const,
    version: record.version,
    effectiveFrom: record.effectiveFrom,
    ...(record.expiresAt === undefined ? {} : { expiresAt: record.expiresAt }),
  });
}

export function projectActiveWorkspaceMemberships(
  request: ProjectActiveWorkspaceMembershipsRequest,
): readonly ActiveWorkspaceMembership[] {
  const requestedAccountId = identifier(request.accountId, "account id");
  const at = timestamp(request.at, "at");
  const atMilliseconds = Date.parse(at);
  const byMembershipId = new Map<string, NormalizedWorkspaceMembership>();

  for (const candidate of request.memberships) {
    const normalized = normalizeMembership(candidate);
    if (normalized.accountId !== requestedAccountId) {
      fail(
        "account_mismatch",
        "membership record belongs to a different account.",
      );
    }
    const existing = byMembershipId.get(normalized.membershipId);
    if (existing === undefined) {
      byMembershipId.set(normalized.membershipId, normalized);
      continue;
    }
    if (recordFingerprint(existing) !== recordFingerprint(normalized)) {
      fail(
        "duplicate_conflict",
        "membership id was reused for a conflicting record.",
      );
    }
  }

  const byWorkspaceId = new Map<string, NormalizedWorkspaceMembership>();
  for (const membership of byMembershipId.values()) {
    if (!activeAt(membership, atMilliseconds)) continue;
    const existing = byWorkspaceId.get(membership.workspaceId);
    if (
      existing !== undefined &&
      existing.membershipId !== membership.membershipId
    ) {
      fail(
        "workspace_conflict",
        "workspace has more than one active membership for this account.",
      );
    }
    byWorkspaceId.set(membership.workspaceId, membership);
  }

  const result = [...byWorkspaceId.values()]
    .sort((left, right) =>
      left.workspaceId.localeCompare(right.workspaceId) ||
      left.membershipId.localeCompare(right.membershipId),
    )
    .map(project);
  return Object.freeze(result);
}
