import { createHash } from "node:crypto";

export const supplyParticipantTypes = [
  "shop",
  "retailer",
  "pharmacy",
  "wholesaler",
  "distributor",
  "manufacturer",
  "delivery_partner",
] as const;

export type SupplyParticipantType = (typeof supplyParticipantTypes)[number];

export const supplyCapabilityKinds = [
  "retail_fulfilment",
  "wholesale_supply",
  "delivery_fulfilment",
  "product_master_stewardship",
] as const;

export type SupplyCapabilityKind = (typeof supplyCapabilityKinds)[number];

export const supplyEvidenceKinds = [
  "identity",
  "licence",
  "tax",
  "bank_payout",
  "service_area",
  "stock_ownership",
  "product_authenticity",
  "returns_policy",
  "operational_capacity",
  "category_authorization",
] as const;

export type SupplyEvidenceKind = (typeof supplyEvidenceKinds)[number];

export type SupplyCapabilityState =
  | "pending_review"
  | "verified"
  | "denied"
  | "suspended"
  | "revoked";

export type SupplyContractErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "workspace_mismatch"
  | "version_conflict"
  | "idempotency_conflict"
  | "invalid_transition"
  | "participant_capability_mismatch";

export class SupplyContractError extends Error {
  constructor(
    readonly code: SupplyContractErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "SupplyContractError";
  }
}

export interface SupplyActor {
  readonly actorId: string;
  readonly tenantId: string;
  readonly workspaceId?: string;
  readonly scopes: readonly string[];
}

export interface SupplyEvidenceReference {
  readonly kind: SupplyEvidenceKind;
  readonly sha256: string;
}

export interface SupplyCapabilityQualifiers {
  readonly categoryIds: readonly string[];
  readonly serviceAreaIds: readonly string[];
}

export interface SupplyCapabilityRecord {
  readonly kind: SupplyCapabilityKind;
  readonly state: SupplyCapabilityState;
  readonly requestedAt: string;
  readonly requestedBy: string;
  readonly evidence: readonly SupplyEvidenceReference[];
  readonly qualifiers: SupplyCapabilityQualifiers;
  readonly reviewedAt?: string;
  readonly reviewedBy?: string;
  readonly effectiveFrom?: string;
  readonly expiresAt?: string;
  readonly reason?: string;
}

export type SupplyAuditEventType =
  | "workspace_registered"
  | "capability_requested"
  | "capability_verified"
  | "capability_denied"
  | "capability_suspended"
  | "capability_revoked";

export interface SupplyAuditEvent {
  readonly eventId: string;
  readonly eventType: SupplyAuditEventType;
  readonly aggregateVersion: number;
  readonly commandId: string;
  readonly workspaceId: string;
  readonly tenantId: string;
  readonly actorId: string;
  readonly occurredAt: string;
  readonly capability?: SupplyCapabilityKind;
  readonly fromState?: SupplyCapabilityState;
  readonly toState?: SupplyCapabilityState;
  readonly evidenceSha256: readonly string[];
  readonly reason?: string;
}

export interface SupplyCommandReceipt {
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly aggregateVersion: number;
}

export interface SupplyParticipantWorkspace {
  readonly schemaVersion: 1;
  readonly workspaceId: string;
  readonly tenantId: string;
  readonly legalEntityReference: string;
  readonly participantType: SupplyParticipantType;
  readonly status: "registered";
  readonly version: number;
  readonly capabilities: readonly SupplyCapabilityRecord[];
  readonly commandReceipts: readonly SupplyCommandReceipt[];
  readonly auditEvents: readonly SupplyAuditEvent[];
}

interface SupplyCommandBase {
  readonly commandId: string;
  readonly workspaceId: string;
  readonly expectedVersion: number;
  readonly occurredAt: string;
  readonly actor: SupplyActor;
}

export interface RequestSupplyCapabilityCommand extends SupplyCommandBase {
  readonly type: "request_capability";
  readonly capability: SupplyCapabilityKind;
  readonly evidence: readonly SupplyEvidenceReference[];
  readonly qualifiers: SupplyCapabilityQualifiers;
}

export interface ReviewSupplyCapabilityCommand extends SupplyCommandBase {
  readonly type: "review_capability";
  readonly capability: SupplyCapabilityKind;
  readonly decision: "verify" | "deny";
  readonly reason: string;
  readonly effectiveFrom?: string;
  readonly expiresAt?: string;
}

export interface SuspendSupplyCapabilityCommand extends SupplyCommandBase {
  readonly type: "suspend_capability";
  readonly capability: SupplyCapabilityKind;
  readonly reason: string;
}

export interface RevokeSupplyCapabilityCommand extends SupplyCommandBase {
  readonly type: "revoke_capability";
  readonly capability: SupplyCapabilityKind;
  readonly reason: string;
}

export type SupplyParticipantCommand =
  | RequestSupplyCapabilityCommand
  | ReviewSupplyCapabilityCommand
  | SuspendSupplyCapabilityCommand
  | RevokeSupplyCapabilityCommand;

export interface RegisterSupplyParticipantWorkspaceCommand {
  readonly commandId: string;
  readonly occurredAt: string;
  readonly workspaceId: string;
  readonly tenantId: string;
  readonly legalEntityReference: string;
  readonly participantType: SupplyParticipantType;
  readonly actor: SupplyActor;
}

export interface SupplyCapabilityQuery {
  readonly capability: SupplyCapabilityKind;
  readonly at: string;
  readonly categoryId?: string;
  readonly serviceAreaId?: string;
}

const WORKSPACE_ADMIN_SCOPE = "supply.workspace.admin";
const CAPABILITY_REVIEW_SCOPE = "supply.capability.review";
const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-Fa-f0-9]{64}$/u;

function fail(code: SupplyContractErrorCode, message: string): never {
  throw new SupplyContractError(code, message);
}

function assertIdentifier(value: string, label: string): string {
  if (!IDENTIFIER_PATTERN.test(value)) {
    fail(
      "invalid_input",
      `${label} must be 3 to 128 identifier-safe characters.`,
    );
  }
  return value;
}

function normalizeTimestamp(value: string, label: string): string {
  const timestamp = Date.parse(value);
  if (!Number.isFinite(timestamp)) {
    fail("invalid_input", `${label} must be a valid timestamp.`);
  }
  return new Date(timestamp).toISOString();
}

function normalizeReason(value: string): string {
  const normalized = value.trim();
  if (normalized.length < 3 || normalized.length > 500) {
    fail("invalid_input", "reason must contain 3 to 500 characters.");
  }
  return normalized;
}

function assertKnownValue<T extends string>(
  value: string,
  values: readonly T[],
  label: string,
): T {
  if (!values.includes(value as T)) {
    fail("invalid_input", `${label} is not supported.`);
  }
  return value as T;
}

function normalizeIdentifierList(
  values: readonly string[],
  label: string,
): readonly string[] {
  const normalized = values.map((value) => assertIdentifier(value, label));
  if (new Set(normalized).size !== normalized.length) {
    fail("invalid_input", `${label} must not contain duplicates.`);
  }
  return [...normalized].sort();
}

function normalizeEvidence(
  evidence: readonly SupplyEvidenceReference[],
): readonly SupplyEvidenceReference[] {
  if (evidence.length === 0 || evidence.length > 20) {
    fail("invalid_input", "one to twenty evidence references are required.");
  }
  const normalized = evidence.map((item) => ({
    kind: assertKnownValue(item.kind, supplyEvidenceKinds, "evidence kind"),
    sha256: SHA256_PATTERN.test(item.sha256)
      ? item.sha256.toUpperCase()
      : fail("invalid_input", "evidence must use a SHA-256 reference."),
  }));
  const keys = normalized.map((item) => `${item.kind}:${item.sha256}`);
  if (new Set(keys).size !== keys.length) {
    fail("invalid_input", "evidence references must not contain duplicates.");
  }
  return normalized.sort((left, right) =>
    `${left.kind}:${left.sha256}`.localeCompare(`${right.kind}:${right.sha256}`),
  );
}

function normalizeQualifiers(
  capability: SupplyCapabilityKind,
  qualifiers: SupplyCapabilityQualifiers,
): SupplyCapabilityQualifiers {
  const categoryIds = normalizeIdentifierList(
    qualifiers.categoryIds,
    "category id",
  );
  const serviceAreaIds = normalizeIdentifierList(
    qualifiers.serviceAreaIds,
    "service-area id",
  );
  const categoryRequired = capability !== "delivery_fulfilment";
  const serviceAreaRequired = capability !== "product_master_stewardship";
  if (categoryRequired && categoryIds.length === 0) {
    fail("invalid_input", `${capability} requires at least one category.`);
  }
  if (serviceAreaRequired && serviceAreaIds.length === 0) {
    fail("invalid_input", `${capability} requires at least one service area.`);
  }
  return { categoryIds, serviceAreaIds };
}

function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value !== null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return Object.fromEntries(
      Object.keys(record)
        .sort()
        .filter((key) => record[key] !== undefined)
        .map((key) => [key, canonicalize(record[key])]),
    );
  }
  return value;
}

function commandFingerprint(command: unknown): string {
  return createHash("sha256")
    .update(JSON.stringify(canonicalize(command)))
    .digest("hex")
    .toUpperCase();
}

function deepFreeze<T>(value: T): T {
  if (value !== null && typeof value === "object" && !Object.isFrozen(value)) {
    Object.freeze(value);
    for (const child of Object.values(value as Record<string, unknown>)) {
      deepFreeze(child);
    }
  }
  return value;
}

function assertActorTenant(
  workspace: SupplyParticipantWorkspace,
  actor: SupplyActor,
): void {
  assertIdentifier(actor.actorId, "actor id");
  if (actor.tenantId !== workspace.tenantId) {
    fail("tenant_mismatch", "actor tenant does not own this workspace.");
  }
}

function requireScope(actor: SupplyActor, scope: string): void {
  if (!actor.scopes.includes(scope)) {
    fail("unauthorized", `actor lacks required scope ${scope}.`);
  }
}

function requireWorkspaceAdmin(
  workspace: SupplyParticipantWorkspace,
  actor: SupplyActor,
): void {
  assertActorTenant(workspace, actor);
  requireScope(actor, WORKSPACE_ADMIN_SCOPE);
  if (actor.workspaceId !== workspace.workspaceId) {
    fail("workspace_mismatch", "actor is not bound to this workspace.");
  }
}

function requireCapabilityReviewer(
  workspace: SupplyParticipantWorkspace,
  actor: SupplyActor,
): void {
  assertActorTenant(workspace, actor);
  requireScope(actor, CAPABILITY_REVIEW_SCOPE);
}

function assertCapabilityAllowed(
  participantType: SupplyParticipantType,
  capability: SupplyCapabilityKind,
): void {
  if (
    participantType === "delivery_partner" &&
    capability !== "delivery_fulfilment"
  ) {
    fail(
      "participant_capability_mismatch",
      "a delivery partner cannot receive seller or product-master rights.",
    );
  }
}

function capabilityIndex(
  workspace: SupplyParticipantWorkspace,
  capability: SupplyCapabilityKind,
): number {
  return workspace.capabilities.findIndex((item) => item.kind === capability);
}

function appendOutcome(
  workspace: SupplyParticipantWorkspace,
  command: SupplyParticipantCommand,
  capability: SupplyCapabilityRecord,
  eventType: Exclude<SupplyAuditEventType, "workspace_registered">,
  fromState?: SupplyCapabilityState,
): SupplyParticipantWorkspace {
  const index = capabilityIndex(workspace, capability.kind);
  const capabilities = [...workspace.capabilities];
  if (index < 0) capabilities.push(capability);
  else capabilities[index] = capability;
  capabilities.sort((left, right) => left.kind.localeCompare(right.kind));

  const version = workspace.version + 1;
  const fingerprint = commandFingerprint(command);
  const event: SupplyAuditEvent = {
    eventId: `${workspace.workspaceId}:${version}`,
    eventType,
    aggregateVersion: version,
    commandId: command.commandId,
    workspaceId: workspace.workspaceId,
    tenantId: workspace.tenantId,
    actorId: command.actor.actorId,
    occurredAt: normalizeTimestamp(command.occurredAt, "occurredAt"),
    capability: capability.kind,
    ...(fromState === undefined ? {} : { fromState }),
    toState: capability.state,
    evidenceSha256: capability.evidence.map((item) => item.sha256),
    ...(capability.reason === undefined ? {} : { reason: capability.reason }),
  };
  const receipt: SupplyCommandReceipt = {
    commandId: command.commandId,
    commandFingerprint: fingerprint,
    aggregateVersion: version,
  };
  return deepFreeze({
    ...workspace,
    version,
    capabilities,
    commandReceipts: [...workspace.commandReceipts, receipt],
    auditEvents: [...workspace.auditEvents, event],
  });
}

function assertCommandEnvelope(
  workspace: SupplyParticipantWorkspace,
  command: SupplyParticipantCommand,
): SupplyParticipantWorkspace | undefined {
  assertIdentifier(command.commandId, "command id");
  assertIdentifier(command.workspaceId, "workspace id");
  normalizeTimestamp(command.occurredAt, "occurredAt");
  if (command.workspaceId !== workspace.workspaceId) {
    fail("workspace_mismatch", "command targets a different workspace.");
  }
  const existingReceipt = workspace.commandReceipts.find(
    (receipt) => receipt.commandId === command.commandId,
  );
  if (existingReceipt !== undefined) {
    if (existingReceipt.commandFingerprint !== commandFingerprint(command)) {
      fail(
        "idempotency_conflict",
        "command id was already used for a different payload.",
      );
    }
    return workspace;
  }
  if (command.expectedVersion !== workspace.version) {
    fail(
      "version_conflict",
      `expected version ${command.expectedVersion} does not match ${workspace.version}.`,
    );
  }
  return undefined;
}

export function registerSupplyParticipantWorkspace(
  command: RegisterSupplyParticipantWorkspaceCommand,
): SupplyParticipantWorkspace {
  const workspaceId = assertIdentifier(command.workspaceId, "workspace id");
  const tenantId = assertIdentifier(command.tenantId, "tenant id");
  const actorId = assertIdentifier(command.actor.actorId, "actor id");
  assertIdentifier(command.commandId, "command id");
  const legalEntityReference = assertIdentifier(
    command.legalEntityReference,
    "legal-entity reference",
  );
  const participantType = assertKnownValue(
    command.participantType,
    supplyParticipantTypes,
    "participant type",
  );
  if (command.actor.tenantId !== tenantId) {
    fail("tenant_mismatch", "actor tenant cannot register this workspace.");
  }
  if (command.actor.workspaceId !== workspaceId) {
    fail("workspace_mismatch", "actor is not bound to this workspace.");
  }
  requireScope(command.actor, WORKSPACE_ADMIN_SCOPE);
  const occurredAt = normalizeTimestamp(command.occurredAt, "occurredAt");
  const event: SupplyAuditEvent = {
    eventId: `${workspaceId}:1`,
    eventType: "workspace_registered",
    aggregateVersion: 1,
    commandId: command.commandId,
    workspaceId,
    tenantId,
    actorId,
    occurredAt,
    evidenceSha256: [],
  };
  return deepFreeze({
    schemaVersion: 1,
    workspaceId,
    tenantId,
    legalEntityReference,
    participantType,
    status: "registered",
    version: 1,
    capabilities: [],
    commandReceipts: [
      {
        commandId: command.commandId,
        commandFingerprint: commandFingerprint(command),
        aggregateVersion: 1,
      },
    ],
    auditEvents: [event],
  });
}

export function applySupplyParticipantCommand(
  workspace: SupplyParticipantWorkspace,
  command: SupplyParticipantCommand,
): SupplyParticipantWorkspace {
  if (command.type === "request_capability") {
    requireWorkspaceAdmin(workspace, command.actor);
  } else {
    requireCapabilityReviewer(workspace, command.actor);
  }
  const duplicate = assertCommandEnvelope(workspace, command);
  if (duplicate !== undefined) return duplicate;
  const capability = assertKnownValue(
    command.capability,
    supplyCapabilityKinds,
    "capability",
  );
  assertCapabilityAllowed(workspace.participantType, capability);
  const index = capabilityIndex(workspace, capability);
  const current = index < 0 ? undefined : workspace.capabilities[index];

  switch (command.type) {
    case "request_capability": {
      if (
        current !== undefined &&
        current.state !== "denied" &&
        current.state !== "revoked"
      ) {
        fail(
          "invalid_transition",
          `${capability} cannot be requested from ${current.state}.`,
        );
      }
      const record: SupplyCapabilityRecord = {
        kind: capability,
        state: "pending_review",
        requestedAt: normalizeTimestamp(command.occurredAt, "occurredAt"),
        requestedBy: command.actor.actorId,
        evidence: normalizeEvidence(command.evidence),
        qualifiers: normalizeQualifiers(capability, command.qualifiers),
      };
      return appendOutcome(
        workspace,
        command,
        record,
        "capability_requested",
        current?.state,
      );
    }
    case "review_capability": {
      if (current === undefined || current.state !== "pending_review") {
        fail(
          "invalid_transition",
          `${capability} must be pending before review.`,
        );
      }
      const reviewedAt = normalizeTimestamp(command.occurredAt, "occurredAt");
      const reason = normalizeReason(command.reason);
      if (command.decision === "deny") {
        if (command.effectiveFrom !== undefined || command.expiresAt !== undefined) {
          fail("invalid_input", "a denied capability cannot have active dates.");
        }
        return appendOutcome(
          workspace,
          command,
          {
            ...current,
            state: "denied",
            reviewedAt,
            reviewedBy: command.actor.actorId,
            reason,
          },
          "capability_denied",
          current.state,
        );
      }
      if (command.effectiveFrom === undefined || command.expiresAt === undefined) {
        fail(
          "invalid_input",
          "verified capability requires effective and expiry timestamps.",
        );
      }
      const effectiveFrom = normalizeTimestamp(
        command.effectiveFrom,
        "effectiveFrom",
      );
      const expiresAt = normalizeTimestamp(command.expiresAt, "expiresAt");
      if (Date.parse(expiresAt) <= Date.parse(effectiveFrom)) {
        fail("invalid_input", "capability expiry must follow its effective start.");
      }
      return appendOutcome(
        workspace,
        command,
        {
          ...current,
          state: "verified",
          reviewedAt,
          reviewedBy: command.actor.actorId,
          effectiveFrom,
          expiresAt,
          reason,
        },
        "capability_verified",
        current.state,
      );
    }
    case "suspend_capability": {
      if (current === undefined || current.state !== "verified") {
        fail(
          "invalid_transition",
          `${capability} must be verified before suspension.`,
        );
      }
      return appendOutcome(
        workspace,
        command,
        {
          ...current,
          state: "suspended",
          reviewedAt: normalizeTimestamp(command.occurredAt, "occurredAt"),
          reviewedBy: command.actor.actorId,
          reason: normalizeReason(command.reason),
        },
        "capability_suspended",
        current.state,
      );
    }
    case "revoke_capability": {
      if (
        current === undefined ||
        current.state === "denied" ||
        current.state === "revoked"
      ) {
        fail(
          "invalid_transition",
          `${capability} cannot be revoked from ${current?.state ?? "missing"}.`,
        );
      }
      return appendOutcome(
        workspace,
        command,
        {
          ...current,
          state: "revoked",
          reviewedAt: normalizeTimestamp(command.occurredAt, "occurredAt"),
          reviewedBy: command.actor.actorId,
          reason: normalizeReason(command.reason),
        },
        "capability_revoked",
        current.state,
      );
    }
  }
}

export function isSupplyCapabilityActive(
  workspace: SupplyParticipantWorkspace,
  query: SupplyCapabilityQuery,
): boolean {
  const at = Date.parse(query.at);
  if (!Number.isFinite(at) || workspace.status !== "registered") return false;
  const record = workspace.capabilities.find(
    (item) => item.kind === query.capability,
  );
  if (
    record?.state !== "verified" ||
    record.effectiveFrom === undefined ||
    record.expiresAt === undefined ||
    at < Date.parse(record.effectiveFrom) ||
    at >= Date.parse(record.expiresAt)
  ) {
    return false;
  }
  const categoryRequired = query.capability !== "delivery_fulfilment";
  const serviceAreaRequired =
    query.capability !== "product_master_stewardship";
  if (
    categoryRequired &&
    (query.categoryId === undefined ||
      !record.qualifiers.categoryIds.includes(query.categoryId))
  ) {
    return false;
  }
  if (
    serviceAreaRequired &&
    (query.serviceAreaId === undefined ||
      !record.qualifiers.serviceAreaIds.includes(query.serviceAreaId))
  ) {
    return false;
  }
  return true;
}
