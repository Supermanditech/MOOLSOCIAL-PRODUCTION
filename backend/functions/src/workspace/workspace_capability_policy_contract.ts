export const workspaceCapabilityPolicyStates = [
  "enabled",
  "held",
  "disabled",
] as const;

export type WorkspaceCapabilityPolicyState =
  (typeof workspaceCapabilityPolicyStates)[number];

export const workspaceCapabilityDecisionStates = [
  "active",
  "held",
  "disabled",
  "not_yet_effective",
  "expired",
  "category_mismatch",
  "service_area_mismatch",
  "missing",
] as const;

export type WorkspaceCapabilityDecisionState =
  (typeof workspaceCapabilityDecisionStates)[number];

export type WorkspaceCapabilityPolicyErrorCode =
  | "invalid_input"
  | "duplicate_conflict"
  | "ambiguous_policy";

export class WorkspaceCapabilityPolicyError extends Error {
  constructor(
    readonly code: WorkspaceCapabilityPolicyErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "WorkspaceCapabilityPolicyError";
  }
}

export interface WorkspaceCapabilityPolicyRecord {
  readonly schemaVersion: 1;
  readonly policyId: string;
  readonly workspaceProfileId: string;
  readonly capabilityId: string;
  readonly state: WorkspaceCapabilityPolicyState;
  readonly version: number;
  readonly effectiveFrom: string;
  readonly expiresAt: string;
  readonly categoryRequired: boolean;
  readonly serviceAreaRequired: boolean;
  readonly categoryIds: readonly string[];
  readonly serviceAreaIds: readonly string[];
  readonly reason?: string;
}

export interface ResolveWorkspaceCapabilityPolicyRequest {
  readonly workspaceProfileId: string;
  readonly capabilityId: string;
  readonly at: string;
  readonly categoryId?: string;
  readonly serviceAreaId?: string;
  readonly policies: readonly WorkspaceCapabilityPolicyRecord[];
}

export interface WorkspaceCapabilityDecision {
  readonly schemaVersion: 1;
  readonly workspaceProfileId: string;
  readonly capabilityId: string;
  readonly state: WorkspaceCapabilityDecisionState;
  readonly policyId?: string;
  readonly policyVersion?: number;
  readonly effectiveFrom?: string;
  readonly expiresAt?: string;
  readonly reason?: string;
}

type NormalizedPolicy = {
  readonly schemaVersion: 1;
  readonly policyId: string;
  readonly workspaceProfileId: string;
  readonly capabilityId: string;
  readonly state: WorkspaceCapabilityPolicyState;
  readonly version: number;
  readonly effectiveFrom: string;
  readonly expiresAt: string;
  readonly categoryRequired: boolean;
  readonly serviceAreaRequired: boolean;
  readonly categoryIds: readonly string[];
  readonly serviceAreaIds: readonly string[];
  readonly reason?: string;
};

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const MAX_POLICIES_PER_RESOLUTION = 200;

function fail(
  code: WorkspaceCapabilityPolicyErrorCode,
  message: string,
): never {
  throw new WorkspaceCapabilityPolicyError(code, message);
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

function positiveVersion(value: number): number {
  if (!Number.isSafeInteger(value) || value < 1) {
    fail("invalid_input", "policy version must be a positive integer.");
  }
  return value;
}

function policyState(
  value: WorkspaceCapabilityPolicyState,
): WorkspaceCapabilityPolicyState {
  if (!workspaceCapabilityPolicyStates.includes(value)) {
    fail("invalid_input", "policy state is unsupported.");
  }
  return value;
}

function identifierList(
  values: readonly string[],
  label: string,
): readonly string[] {
  const normalized = values.map((value) => identifier(value, label));
  if (new Set(normalized).size !== normalized.length) {
    fail("invalid_input", `${label} must not contain duplicates.`);
  }
  return Object.freeze([...normalized].sort());
}

function reason(
  value: string | undefined,
  state: WorkspaceCapabilityPolicyState,
): string | undefined {
  if (state === "enabled") {
    if (value !== undefined) {
      fail("invalid_input", "enabled policy cannot contain a hold reason.");
    }
    return undefined;
  }
  const normalized = value?.trim() ?? "";
  if (normalized.length < 5 || normalized.length > 280) {
    fail(
      "invalid_input",
      "held or disabled policy requires a bounded reason.",
    );
  }
  return normalized;
}

function normalizePolicy(
  record: WorkspaceCapabilityPolicyRecord,
): NormalizedPolicy {
  if (record.schemaVersion !== 1) {
    fail("invalid_input", "policy schema version is unsupported.");
  }
  const effectiveFrom = timestamp(record.effectiveFrom, "effectiveFrom");
  const expiresAt = timestamp(record.expiresAt, "expiresAt");
  if (Date.parse(expiresAt) <= Date.parse(effectiveFrom)) {
    fail("invalid_input", "policy expiry must follow its effective time.");
  }
  const categoryIds = identifierList(record.categoryIds, "category id");
  const serviceAreaIds = identifierList(
    record.serviceAreaIds,
    "service-area id",
  );
  if (record.categoryRequired && categoryIds.length === 0) {
    fail("invalid_input", "required category policy needs an allowlist.");
  }
  if (record.serviceAreaRequired && serviceAreaIds.length === 0) {
    fail("invalid_input", "required service-area policy needs an allowlist.");
  }
  const normalizedState = policyState(record.state);
  const normalizedReason = reason(record.reason, normalizedState);

  return Object.freeze({
    schemaVersion: 1 as const,
    policyId: identifier(record.policyId, "policy id"),
    workspaceProfileId: identifier(
      record.workspaceProfileId,
      "workspace profile id",
    ),
    capabilityId: identifier(record.capabilityId, "capability id"),
    state: normalizedState,
    version: positiveVersion(record.version),
    effectiveFrom,
    expiresAt,
    categoryRequired: record.categoryRequired,
    serviceAreaRequired: record.serviceAreaRequired,
    categoryIds,
    serviceAreaIds,
    ...(normalizedReason === undefined ? {} : { reason: normalizedReason }),
  });
}

function policyFingerprint(policy: NormalizedPolicy): string {
  return JSON.stringify(policy);
}

function decision(
  workspaceProfileId: string,
  capabilityId: string,
  state: WorkspaceCapabilityDecisionState,
  policy?: NormalizedPolicy,
): WorkspaceCapabilityDecision {
  return Object.freeze({
    schemaVersion: 1 as const,
    workspaceProfileId,
    capabilityId,
    state,
    ...(policy === undefined
      ? {}
      : {
          policyId: policy.policyId,
          policyVersion: policy.version,
          effectiveFrom: policy.effectiveFrom,
          expiresAt: policy.expiresAt,
          ...(policy.reason === undefined ? {} : { reason: policy.reason }),
        }),
  });
}

function assertNoOverlappingPolicies(policies: readonly NormalizedPolicy[]): void {
  for (let index = 1; index < policies.length; index += 1) {
    const previous = policies[index - 1]!;
    const current = policies[index]!;
    if (Date.parse(current.effectiveFrom) < Date.parse(previous.expiresAt)) {
      fail(
        "ambiguous_policy",
        "profile and capability policies must not overlap.",
      );
    }
  }
}

export function resolveWorkspaceCapabilityPolicy(
  request: ResolveWorkspaceCapabilityPolicyRequest,
): WorkspaceCapabilityDecision {
  const workspaceProfileId = identifier(
    request.workspaceProfileId,
    "workspace profile id",
  );
  const capabilityId = identifier(request.capabilityId, "capability id");
  const at = timestamp(request.at, "at");
  const categoryId =
    request.categoryId === undefined
      ? undefined
      : identifier(request.categoryId, "category id");
  const serviceAreaId =
    request.serviceAreaId === undefined
      ? undefined
      : identifier(request.serviceAreaId, "service-area id");
  if (request.policies.length > MAX_POLICIES_PER_RESOLUTION) {
    fail("invalid_input", "policy resolution exceeds its bounded record limit.");
  }

  const byPolicyId = new Map<string, NormalizedPolicy>();
  for (const candidate of request.policies) {
    const normalized = normalizePolicy(candidate);
    const existing = byPolicyId.get(normalized.policyId);
    if (existing === undefined) {
      byPolicyId.set(normalized.policyId, normalized);
      continue;
    }
    if (policyFingerprint(existing) !== policyFingerprint(normalized)) {
      fail("duplicate_conflict", "policy id has conflicting records.");
    }
  }

  const applicable = [...byPolicyId.values()]
    .filter(
      (policy) =>
        policy.workspaceProfileId === workspaceProfileId &&
        policy.capabilityId === capabilityId,
    )
    .sort(
      (left, right) =>
        left.effectiveFrom.localeCompare(right.effectiveFrom) ||
        left.policyId.localeCompare(right.policyId),
    );
  if (applicable.length === 0) {
    return decision(workspaceProfileId, capabilityId, "missing");
  }
  assertNoOverlappingPolicies(applicable);

  const atMilliseconds = Date.parse(at);
  const current = applicable.find(
    (policy) =>
      Date.parse(policy.effectiveFrom) <= atMilliseconds &&
      atMilliseconds < Date.parse(policy.expiresAt),
  );
  if (current === undefined) {
    const future = applicable.find(
      (policy) => Date.parse(policy.effectiveFrom) > atMilliseconds,
    );
    return future === undefined
      ? decision(
          workspaceProfileId,
          capabilityId,
          "expired",
          applicable[applicable.length - 1],
        )
      : decision(
          workspaceProfileId,
          capabilityId,
          "not_yet_effective",
          future,
        );
  }

  if (current.state === "held" || current.state === "disabled") {
    return decision(workspaceProfileId, capabilityId, current.state, current);
  }
  if (
    (current.categoryRequired && categoryId === undefined) ||
    (categoryId !== undefined &&
      current.categoryIds.length > 0 &&
      !current.categoryIds.includes(categoryId))
  ) {
    return decision(
      workspaceProfileId,
      capabilityId,
      "category_mismatch",
      current,
    );
  }
  if (
    (current.serviceAreaRequired && serviceAreaId === undefined) ||
    (serviceAreaId !== undefined &&
      current.serviceAreaIds.length > 0 &&
      !current.serviceAreaIds.includes(serviceAreaId))
  ) {
    return decision(
      workspaceProfileId,
      capabilityId,
      "service_area_mismatch",
      current,
    );
  }
  return decision(workspaceProfileId, capabilityId, "active", current);
}
