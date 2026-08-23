import { createHash } from "node:crypto";

import {
  isSupplyCapabilityActive,
  type SupplyActor,
  type SupplyCapabilityKind,
  type SupplyParticipantType,
  type SupplyParticipantWorkspace,
} from "./supply_participant_contract.js";
import {
  authorizePrivilegedCommand,
  completePrivilegedCommand,
  type JsonValue,
  type PrivilegedCommandActor,
  type PrivilegedCommandEnvelope,
  type PrivilegedCommandReceipt,
} from "../workspace/privileged_command_contract.js";

export const providerReadinessStates = ["ready", "busy", "paused"] as const;
export type ProviderReadinessState = (typeof providerReadinessStates)[number];

export const providerReadinessFamilies = [
  "shop",
  "wholesale",
  "medicine_non_prescription",
  "medicine_prescription_pharmacist_ready",
] as const;
export type ProviderReadinessFamily = (typeof providerReadinessFamilies)[number];

export type ProviderReadinessErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "workspace_mismatch"
  | "aggregate_mismatch"
  | "participant_mismatch"
  | "capability_inactive"
  | "effective_time_conflict";

export class ProviderReadinessError extends Error {
  constructor(
    readonly code: ProviderReadinessErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "ProviderReadinessError";
  }
}

export interface ProviderReadinessCommandPayload
  extends Readonly<Record<string, JsonValue>> {
  readonly readinessId: string;
  readonly workspaceId: string;
  readonly family: ProviderReadinessFamily;
  readonly categoryId: string;
  readonly serviceAreaId: string;
  readonly state: ProviderReadinessState;
  readonly effectiveFrom: string;
  readonly expiresAt: string;
  readonly reasonCode: string;
}

export type PublishProviderReadinessCommand = Omit<
  PrivilegedCommandEnvelope,
  "payload"
> & {
  readonly payload: ProviderReadinessCommandPayload;
};

export interface ProviderReadinessRevision {
  readonly schemaVersion: 1;
  readonly revisionId: string;
  readonly aggregateVersion: number;
  readonly readinessId: string;
  readonly workspaceId: string;
  readonly family: ProviderReadinessFamily;
  readonly requiredCapability: SupplyCapabilityKind;
  readonly categoryId: string;
  readonly serviceAreaId: string;
  readonly state: ProviderReadinessState;
  readonly effectiveFrom: string;
  readonly expiresAt: string;
  readonly reasonCode: string;
  readonly publishedAt: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
}

export interface ProviderReadinessAuditEvent {
  readonly schemaVersion: 1;
  readonly eventId: string;
  readonly eventType: "provider_readiness_published";
  readonly aggregateVersion: number;
  readonly tenantId: string;
  readonly readinessId: string;
  readonly workspaceId: string;
  readonly revisionId: string;
  readonly family: ProviderReadinessFamily;
  readonly state: ProviderReadinessState;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
  readonly occurredAt: string;
}

export interface ProviderReadinessAggregate {
  readonly schemaVersion: 1;
  readonly tenantId: string;
  readonly readinessId: string;
  readonly workspaceId: string;
  readonly family: ProviderReadinessFamily;
  readonly categoryId: string;
  readonly serviceAreaId: string;
  readonly version: number;
  readonly revisions: readonly ProviderReadinessRevision[];
  readonly receipts: readonly PrivilegedCommandReceipt[];
  readonly auditEvents: readonly ProviderReadinessAuditEvent[];
}

export interface PublishProviderReadinessRequest {
  readonly aggregate: ProviderReadinessAggregate;
  readonly workspace: SupplyParticipantWorkspace;
  readonly operator: SupplyActor;
  readonly command: PublishProviderReadinessCommand;
}

export interface PublishProviderReadinessResult {
  readonly aggregate: ProviderReadinessAggregate;
  readonly revision: ProviderReadinessRevision;
  readonly receipt: PrivilegedCommandReceipt;
  readonly replayed: boolean;
}

export type ProviderReadinessProjection =
  | Readonly<{ state: "unknown" }>
  | Readonly<{ state: "stale"; lastRevision: ProviderReadinessRevision }>
  | Readonly<{ state: "ineligible" }>
  | Readonly<{
      state: ProviderReadinessState;
      revision: ProviderReadinessRevision;
    }>;

export interface ProjectProviderReadinessRequest {
  readonly aggregate: ProviderReadinessAggregate;
  readonly workspace: SupplyParticipantWorkspace;
  readonly tenantId: string;
  readonly readinessId: string;
  readonly actor: PrivilegedCommandActor;
  readonly operator: SupplyActor;
  readonly at: string;
}

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-F0-9]{64}$/u;
const OPERATOR_SCOPE = "commerce.provider_readiness.operate";
const MAX_HISTORY = 499;
const PAYLOAD_KEYS = [
  "categoryId",
  "effectiveFrom",
  "expiresAt",
  "family",
  "readinessId",
  "reasonCode",
  "serviceAreaId",
  "state",
  "workspaceId",
] as const;
const AGGREGATE_KEYS = [
  "auditEvents",
  "categoryId",
  "family",
  "readinessId",
  "receipts",
  "revisions",
  "schemaVersion",
  "serviceAreaId",
  "tenantId",
  "version",
  "workspaceId",
] as const;
const REVISION_KEYS = [
  "actorId",
  "aggregateVersion",
  "categoryId",
  "commandFingerprint",
  "commandId",
  "effectiveFrom",
  "expiresAt",
  "family",
  "publishedAt",
  "readinessId",
  "reasonCode",
  "requiredCapability",
  "revisionId",
  "schemaVersion",
  "serviceAreaId",
  "state",
  "workspaceId",
] as const;
const RECEIPT_KEYS = [
  "actorId",
  "aggregateId",
  "aggregateVersion",
  "commandFingerprint",
  "commandId",
  "completedAt",
  "requiredScope",
  "resultReference",
  "resultSha256",
  "schemaVersion",
] as const;
const AUDIT_KEYS = [
  "actorId",
  "aggregateVersion",
  "commandFingerprint",
  "commandId",
  "eventId",
  "eventType",
  "family",
  "occurredAt",
  "readinessId",
  "revisionId",
  "schemaVersion",
  "state",
  "tenantId",
  "workspaceId",
] as const;

function fail(code: ProviderReadinessErrorCode, message: string): never {
  throw new ProviderReadinessError(code, message);
}

function exactPlainRecord(
  value: unknown,
  expectedKeys: readonly string[],
  label: string,
): void {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    (Object.getPrototypeOf(value) !== Object.prototype &&
      Object.getPrototypeOf(value) !== null)
  ) {
    fail("invalid_input", `${label} must be a plain record.`);
  }
  const keys = Object.keys(value as Record<string, unknown>).sort();
  if (
    keys.length !== expectedKeys.length ||
    keys.some((key, index) => key !== expectedKeys[index])
  ) {
    fail("invalid_input", `${label} fields are not exact.`);
  }
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

function positiveVersion(value: number, label: string): number {
  if (!Number.isSafeInteger(value) || value < 1) {
    fail("invalid_input", `${label} must be a positive safe integer.`);
  }
  return value;
}

function family(value: unknown): ProviderReadinessFamily {
  if (
    typeof value !== "string" ||
    !providerReadinessFamilies.includes(value as ProviderReadinessFamily)
  ) {
    fail("invalid_input", "provider readiness family is unsupported.");
  }
  return value as ProviderReadinessFamily;
}

function readinessState(value: unknown): ProviderReadinessState {
  if (
    typeof value !== "string" ||
    !providerReadinessStates.includes(value as ProviderReadinessState)
  ) {
    fail("invalid_input", "provider readiness state is unsupported.");
  }
  return value as ProviderReadinessState;
}

function sha(value: string, label: string): string {
  if (!SHA256_PATTERN.test(value)) {
    fail("invalid_input", `${label} must be uppercase SHA-256.`);
  }
  return value;
}

function sha256Text(value: string): string {
  return createHash("sha256").update(value).digest("hex").toUpperCase();
}

function requiredCapability(value: ProviderReadinessFamily): SupplyCapabilityKind {
  return value === "wholesale" ? "wholesale_supply" : "retail_fulfilment";
}

function participantAllowed(
  participantType: SupplyParticipantType,
  value: ProviderReadinessFamily,
): boolean {
  if (value === "shop") return participantType === "shop" || participantType === "retailer";
  if (value === "wholesale") {
    return (
      participantType === "wholesaler" ||
      participantType === "distributor" ||
      participantType === "manufacturer"
    );
  }
  return participantType === "pharmacy";
}

function assertActorBinding(
  tenantId: string,
  workspaceId: string,
  commandActor: PrivilegedCommandActor,
  operator: SupplyActor,
): void {
  if (
    commandActor.actorId !== operator.actorId ||
    commandActor.tenantId !== operator.tenantId ||
    operator.tenantId !== tenantId
  ) {
    fail("tenant_mismatch", "readiness operator identity is not tenant-bound.");
  }
  if (operator.workspaceId !== workspaceId) {
    fail("workspace_mismatch", "readiness operator is not bound to this workspace.");
  }
}

function readActor(value: PrivilegedCommandActor): PrivilegedCommandActor {
  const scopes = value.scopes.map((scope) => identifier(scope, "actor scope"));
  if (new Set(scopes).size !== scopes.length) {
    fail("invalid_input", "actor scopes must not contain duplicates.");
  }
  return Object.freeze({
    actorId: identifier(value.actorId, "actor id"),
    tenantId: identifier(value.tenantId, "actor tenant id"),
    scopes: Object.freeze([...scopes].sort()),
  });
}

function assertWorkspaceBinding(
  aggregate: ProviderReadinessAggregate,
  workspace: SupplyParticipantWorkspace,
): void {
  if (workspace.tenantId !== aggregate.tenantId) {
    fail("tenant_mismatch", "supply workspace belongs to another tenant.");
  }
  if (workspace.workspaceId !== aggregate.workspaceId) {
    fail("workspace_mismatch", "supply workspace identity does not match readiness.");
  }
  if (!participantAllowed(workspace.participantType, aggregate.family)) {
    fail("participant_mismatch", "workspace participant type cannot own this readiness family.");
  }
}

function capabilityActive(
  aggregate: ProviderReadinessAggregate,
  workspace: SupplyParticipantWorkspace,
  at: string,
): boolean {
  return isSupplyCapabilityActive(workspace, {
    capability: requiredCapability(aggregate.family),
    categoryId: aggregate.categoryId,
    serviceAreaId: aggregate.serviceAreaId,
    at,
  });
}

interface NormalizedPayload {
  readonly readinessId: string;
  readonly workspaceId: string;
  readonly family: ProviderReadinessFamily;
  readonly categoryId: string;
  readonly serviceAreaId: string;
  readonly state: ProviderReadinessState;
  readonly effectiveFrom: string;
  readonly expiresAt: string;
  readonly reasonCode: string;
}

function payload(value: unknown): NormalizedPayload {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    (Object.getPrototypeOf(value) !== Object.prototype &&
      Object.getPrototypeOf(value) !== null)
  ) {
    fail("invalid_input", "provider readiness payload must be a plain record.");
  }
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record).sort();
  if (
    keys.length !== PAYLOAD_KEYS.length ||
    keys.some((key, index) => key !== PAYLOAD_KEYS[index])
  ) {
    fail("invalid_input", "provider readiness payload fields are not exact.");
  }
  const effectiveFrom =
    typeof record.effectiveFrom === "string"
      ? timestamp(record.effectiveFrom, "effectiveFrom")
      : fail("invalid_input", "effectiveFrom is invalid.");
  const expiresAt =
    typeof record.expiresAt === "string"
      ? timestamp(record.expiresAt, "expiresAt")
      : fail("invalid_input", "expiresAt is invalid.");
  if (Date.parse(expiresAt) <= Date.parse(effectiveFrom)) {
    fail("effective_time_conflict", "readiness expiry must follow its effective time.");
  }
  return Object.freeze({
    readinessId:
      typeof record.readinessId === "string"
        ? identifier(record.readinessId, "payload readiness id")
        : fail("invalid_input", "payload readiness id is invalid."),
    workspaceId:
      typeof record.workspaceId === "string"
        ? identifier(record.workspaceId, "payload workspace id")
        : fail("invalid_input", "payload workspace id is invalid."),
    family: family(record.family),
    categoryId:
      typeof record.categoryId === "string"
        ? identifier(record.categoryId, "payload category id")
        : fail("invalid_input", "payload category id is invalid."),
    serviceAreaId:
      typeof record.serviceAreaId === "string"
        ? identifier(record.serviceAreaId, "payload service area id")
        : fail("invalid_input", "payload service area id is invalid."),
    state: readinessState(record.state),
    effectiveFrom,
    expiresAt,
    reasonCode:
      typeof record.reasonCode === "string"
        ? identifier(record.reasonCode, "reason code")
        : fail("invalid_input", "reason code is invalid."),
  });
}

function freezeRevision(value: ProviderReadinessRevision): ProviderReadinessRevision {
  return Object.freeze({ ...value });
}

function freezeAggregate(value: ProviderReadinessAggregate): ProviderReadinessAggregate {
  return Object.freeze({
    ...value,
    revisions: Object.freeze(value.revisions.map(freezeRevision)),
    receipts: Object.freeze(value.receipts.map((item) => Object.freeze({ ...item }))),
    auditEvents: Object.freeze(
      value.auditEvents.map((item) => Object.freeze({ ...item })),
    ),
  });
}

function normalizeAggregate(value: ProviderReadinessAggregate): ProviderReadinessAggregate {
  exactPlainRecord(value, AGGREGATE_KEYS, "provider readiness aggregate");
  if (value.schemaVersion !== 1) {
    fail("invalid_input", "provider readiness schema is unsupported.");
  }
  const tenantId = identifier(value.tenantId, "tenant id");
  const readinessId = identifier(value.readinessId, "readiness id");
  const workspaceId = identifier(value.workspaceId, "workspace id");
  const readinessFamily = family(value.family);
  const categoryId = identifier(value.categoryId, "category id");
  const serviceAreaId = identifier(value.serviceAreaId, "service area id");
  const version = positiveVersion(value.version, "readiness version");
  if (
    value.revisions.length > MAX_HISTORY ||
    value.revisions.length !== version - 1 ||
    value.receipts.length !== value.revisions.length ||
    value.auditEvents.length !== value.revisions.length
  ) {
    fail("invalid_input", "provider readiness history and version are inconsistent.");
  }
  let previous: ProviderReadinessRevision | undefined;
  const revisions = value.revisions.map((item, index) => {
    exactPlainRecord(item, REVISION_KEYS, "provider readiness revision");
    const effectiveFrom = timestamp(item.effectiveFrom, "revision effectiveFrom");
    const expiresAt = timestamp(item.expiresAt, "revision expiresAt");
    if (
      item.schemaVersion !== 1 ||
      item.aggregateVersion !== index + 2 ||
      item.readinessId !== readinessId ||
      item.workspaceId !== workspaceId ||
      item.family !== readinessFamily ||
      item.requiredCapability !== requiredCapability(readinessFamily) ||
      item.categoryId !== categoryId ||
      item.serviceAreaId !== serviceAreaId ||
      Date.parse(expiresAt) <= Date.parse(effectiveFrom) ||
      (previous !== undefined &&
        Date.parse(effectiveFrom) < Date.parse(previous.expiresAt)) ||
      Date.parse(item.publishedAt) > Date.parse(effectiveFrom)
    ) {
      fail("invalid_input", "provider readiness revision history is inconsistent.");
    }
    const commandFingerprint = sha(item.commandFingerprint, "command fingerprint");
    const revision = freezeRevision({
      schemaVersion: 1,
      revisionId: identifier(item.revisionId, "revision id"),
      aggregateVersion: item.aggregateVersion,
      readinessId,
      workspaceId,
      family: readinessFamily,
      requiredCapability: requiredCapability(readinessFamily),
      categoryId,
      serviceAreaId,
      state: readinessState(item.state),
      effectiveFrom,
      expiresAt,
      reasonCode: identifier(item.reasonCode, "reason code"),
      publishedAt: timestamp(item.publishedAt, "revision publishedAt"),
      commandId: identifier(item.commandId, "revision command id"),
      commandFingerprint,
      actorId: identifier(item.actorId, "revision actor id"),
    });
    previous = revision;
    return revision;
  });
  const receipts = value.receipts.map((item, index) => {
    exactPlainRecord(item, RECEIPT_KEYS, "provider readiness receipt");
    const revision = revisions[index];
    if (
      revision === undefined ||
      item.schemaVersion !== 1 ||
      item.aggregateId !== readinessId ||
      item.aggregateVersion !== revision.aggregateVersion ||
      item.commandId !== revision.commandId ||
      item.commandFingerprint !== revision.commandFingerprint ||
      item.actorId !== revision.actorId ||
      item.requiredScope !== OPERATOR_SCOPE ||
      item.resultReference !== revision.revisionId ||
      item.resultSha256 !==
        sha256Text(`${revision.commandFingerprint}:${revision.revisionId}`) ||
      item.completedAt !== revision.publishedAt
    ) {
      fail("invalid_input", "provider readiness receipt history is inconsistent.");
    }
    return Object.freeze({
      schemaVersion: 1 as const,
      commandId: revision.commandId,
      commandFingerprint: revision.commandFingerprint,
      aggregateId: readinessId,
      aggregateVersion: revision.aggregateVersion,
      actorId: revision.actorId,
      requiredScope: OPERATOR_SCOPE,
      resultReference: revision.revisionId,
      resultSha256: item.resultSha256,
      completedAt: revision.publishedAt,
    });
  });
  const auditEvents = value.auditEvents.map((item, index) => {
    exactPlainRecord(item, AUDIT_KEYS, "provider readiness audit event");
    const revision = revisions[index];
    if (
      revision === undefined ||
      item.schemaVersion !== 1 ||
      item.eventType !== "provider_readiness_published" ||
      item.aggregateVersion !== revision.aggregateVersion ||
      item.tenantId !== tenantId ||
      item.readinessId !== readinessId ||
      item.workspaceId !== workspaceId ||
      item.revisionId !== revision.revisionId ||
      item.family !== readinessFamily ||
      item.state !== revision.state ||
      item.commandId !== revision.commandId ||
      item.commandFingerprint !== revision.commandFingerprint ||
      item.actorId !== revision.actorId ||
      item.occurredAt !== revision.publishedAt
    ) {
      fail("invalid_input", "provider readiness audit history is inconsistent.");
    }
    return Object.freeze({
      schemaVersion: 1 as const,
      eventId: identifier(item.eventId, "audit event id"),
      eventType: "provider_readiness_published" as const,
      aggregateVersion: revision.aggregateVersion,
      tenantId,
      readinessId,
      workspaceId,
      revisionId: revision.revisionId,
      family: readinessFamily,
      state: revision.state,
      commandId: revision.commandId,
      commandFingerprint: revision.commandFingerprint,
      actorId: revision.actorId,
      occurredAt: revision.publishedAt,
    });
  });
  return freezeAggregate({
    schemaVersion: 1,
    tenantId,
    readinessId,
    workspaceId,
    family: readinessFamily,
    categoryId,
    serviceAreaId,
    version,
    revisions,
    receipts,
    auditEvents,
  });
}

export function createProviderReadinessAggregate(request: {
  readonly tenantId: string;
  readonly readinessId: string;
  readonly workspaceId: string;
  readonly family: ProviderReadinessFamily;
  readonly categoryId: string;
  readonly serviceAreaId: string;
}): ProviderReadinessAggregate {
  return freezeAggregate({
    schemaVersion: 1,
    tenantId: identifier(request.tenantId, "tenant id"),
    readinessId: identifier(request.readinessId, "readiness id"),
    workspaceId: identifier(request.workspaceId, "workspace id"),
    family: family(request.family),
    categoryId: identifier(request.categoryId, "category id"),
    serviceAreaId: identifier(request.serviceAreaId, "service area id"),
    version: 1,
    revisions: [],
    receipts: [],
    auditEvents: [],
  });
}

export function publishProviderReadiness(
  request: PublishProviderReadinessRequest,
): PublishProviderReadinessResult {
  const authorization = authorizePrivilegedCommand({
    tenantId: request.aggregate.tenantId,
    aggregateId: request.aggregate.readinessId,
    currentVersion: request.aggregate.version,
    requiredScope: OPERATOR_SCOPE,
    receipts: request.aggregate.receipts,
    command: request.command,
  });
  const current = normalizeAggregate(request.aggregate);
  assertActorBinding(
    current.tenantId,
    current.workspaceId,
    request.command.actor,
    request.operator,
  );
  assertWorkspaceBinding(current, request.workspace);
  if (authorization.state === "replay") {
    const revision = current.revisions.find(
      (item) => item.aggregateVersion === authorization.receipt.aggregateVersion,
    );
    if (revision === undefined) {
      fail("invalid_input", "readiness receipt has no matching revision.");
    }
    return Object.freeze({
      aggregate: current,
      revision,
      receipt: authorization.receipt,
      replayed: true,
    });
  }
  const commandPayload = payload(request.command.payload);
  if (
    commandPayload.readinessId !== current.readinessId ||
    commandPayload.workspaceId !== current.workspaceId ||
    commandPayload.family !== current.family ||
    commandPayload.categoryId !== current.categoryId ||
    commandPayload.serviceAreaId !== current.serviceAreaId
  ) {
    fail("aggregate_mismatch", "readiness command scope does not match its aggregate.");
  }
  if (Date.parse(commandPayload.effectiveFrom) < Date.parse(authorization.occurredAt)) {
    fail("effective_time_conflict", "readiness declaration cannot be backdated.");
  }
  const previous = current.revisions.at(-1);
  if (
    previous !== undefined &&
    Date.parse(commandPayload.effectiveFrom) < Date.parse(previous.expiresAt)
  ) {
    fail("effective_time_conflict", "readiness declarations cannot overlap.");
  }
  if (
    !capabilityActive(current, request.workspace, commandPayload.effectiveFrom) ||
    !capabilityActive(
      current,
      request.workspace,
      new Date(Date.parse(commandPayload.expiresAt) - 1).toISOString(),
    )
  ) {
    fail("capability_inactive", "required SUP-001 capability is not active for the full declaration.");
  }
  const aggregateVersion = current.version + 1;
  const revisionId = `provider-readiness-revision:${aggregateVersion}`;
  const revision = freezeRevision({
    schemaVersion: 1,
    revisionId,
    aggregateVersion,
    readinessId: current.readinessId,
    workspaceId: current.workspaceId,
    family: current.family,
    requiredCapability: requiredCapability(current.family),
    categoryId: current.categoryId,
    serviceAreaId: current.serviceAreaId,
    state: commandPayload.state,
    effectiveFrom: commandPayload.effectiveFrom,
    expiresAt: commandPayload.expiresAt,
    reasonCode: commandPayload.reasonCode,
    publishedAt: authorization.occurredAt,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
    actorId: authorization.actorId,
  });
  const receipts = completePrivilegedCommand({
    reservation: authorization,
    currentReceipts: current.receipts,
    newAggregateVersion: aggregateVersion,
    resultReference: revisionId,
    resultSha256: sha256Text(`${authorization.commandFingerprint}:${revisionId}`),
    completedAt: authorization.occurredAt,
  });
  const receipt = receipts.at(-1);
  if (receipt === undefined) fail("invalid_input", "readiness receipt is missing.");
  const audit = Object.freeze({
    schemaVersion: 1 as const,
    eventId: `provider-readiness-event:${aggregateVersion}`,
    eventType: "provider_readiness_published" as const,
    aggregateVersion,
    tenantId: current.tenantId,
    readinessId: current.readinessId,
    workspaceId: current.workspaceId,
    revisionId,
    family: current.family,
    state: commandPayload.state,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
    actorId: authorization.actorId,
    occurredAt: authorization.occurredAt,
  });
  const aggregate = freezeAggregate({
    ...current,
    version: aggregateVersion,
    revisions: [...current.revisions, revision],
    receipts,
    auditEvents: [...current.auditEvents, audit],
  });
  return Object.freeze({ aggregate, revision, receipt, replayed: false });
}

export function projectProviderReadiness(
  request: ProjectProviderReadinessRequest,
): ProviderReadinessProjection {
  const actor = readActor(request.actor);
  if (!actor.scopes.includes(OPERATOR_SCOPE)) {
    fail("unauthorized", "actor lacks provider readiness authority.");
  }
  const tenantId = identifier(request.tenantId, "tenant id");
  const readinessId = identifier(request.readinessId, "readiness id");
  assertActorBinding(
    tenantId,
    request.aggregate.workspaceId,
    actor,
    request.operator,
  );
  if (request.aggregate.tenantId !== tenantId) {
    fail("tenant_mismatch", "readiness is unavailable for this tenant.");
  }
  if (request.aggregate.readinessId !== readinessId) {
    fail("aggregate_mismatch", "requested readiness is unavailable.");
  }
  const at = timestamp(request.at, "projection timestamp");
  const aggregate = normalizeAggregate(request.aggregate);
  assertWorkspaceBinding(aggregate, request.workspace);
  if (!capabilityActive(aggregate, request.workspace, at)) {
    return Object.freeze({ state: "ineligible" });
  }
  const effective = aggregate.revisions.filter(
    (item) => Date.parse(item.effectiveFrom) <= Date.parse(at),
  );
  const latest = effective.at(-1);
  if (latest === undefined) return Object.freeze({ state: "unknown" });
  if (Date.parse(at) >= Date.parse(latest.expiresAt)) {
    return Object.freeze({ state: "stale", lastRevision: latest });
  }
  return Object.freeze({ state: latest.state, revision: latest });
}
