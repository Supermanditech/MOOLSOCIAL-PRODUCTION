import { createHash } from "node:crypto";

import {
  authorizePrivilegedCommand,
  completePrivilegedCommand,
  type JsonValue,
  type PrivilegedCommandActor,
  type PrivilegedCommandEnvelope,
  type PrivilegedCommandReceipt,
} from "../workspace/privileged_command_contract.js";

export const buyAcceptanceSlaFamilies = [
  "shop",
  "wholesale",
  "medicine_non_prescription",
  "medicine_prescription_pharmacist_ready",
] as const;

export type BuyAcceptanceSlaFamily =
  (typeof buyAcceptanceSlaFamilies)[number];

export type AcceptanceSlaPolicyErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "aggregate_mismatch"
  | "unsupported_family"
  | "policy_bounds"
  | "effective_time_conflict";

export class AcceptanceSlaPolicyError extends Error {
  constructor(
    readonly code: AcceptanceSlaPolicyErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "AcceptanceSlaPolicyError";
  }
}

export interface AcceptanceSlaPolicyPayload
  extends Readonly<Record<string, JsonValue>> {
  readonly family: BuyAcceptanceSlaFamily;
  readonly responseWindowSeconds: number;
  readonly maximumSequentialPartners: number;
  readonly overallAssignmentCeilingSeconds: number;
  readonly effectiveFrom: string;
  readonly reasonCode: string;
}

interface NormalizedAcceptanceSlaPolicyPayload
  extends AcceptanceSlaPolicyPayload {
  readonly whatsAppOffsetSeconds: number;
  readonly agenticCallOffsetSeconds: number;
}

export type PublishAcceptanceSlaPolicyCommand = Omit<
  PrivilegedCommandEnvelope,
  "payload"
> & {
  readonly payload: AcceptanceSlaPolicyPayload;
};

export interface AcceptanceSlaPolicyRevision {
  readonly schemaVersion: 1;
  readonly revisionId: string;
  readonly aggregateVersion: number;
  readonly family: BuyAcceptanceSlaFamily;
  readonly responseWindowSeconds: number;
  readonly maximumSequentialPartners: number;
  readonly overallAssignmentCeilingSeconds: number;
  readonly moolChatOffsetSeconds: 0;
  readonly whatsAppOffsetSeconds: number;
  readonly agenticCallOffsetSeconds: number;
  readonly reassignAtSeconds: number;
  readonly effectiveFrom: string;
  readonly publishedAt: string;
  readonly reasonCode: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
}

export interface AcceptanceSlaPolicyAuditEvent {
  readonly schemaVersion: 1;
  readonly eventId: string;
  readonly eventType: "acceptance_sla_policy_published";
  readonly aggregateVersion: number;
  readonly tenantId: string;
  readonly policySetId: string;
  readonly revisionId: string;
  readonly family: BuyAcceptanceSlaFamily;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
  readonly occurredAt: string;
}

export interface AcceptanceSlaPolicySet {
  readonly schemaVersion: 1;
  readonly tenantId: string;
  readonly policySetId: string;
  readonly version: number;
  readonly revisions: readonly AcceptanceSlaPolicyRevision[];
  readonly receipts: readonly PrivilegedCommandReceipt[];
  readonly auditEvents: readonly AcceptanceSlaPolicyAuditEvent[];
}

export interface CreateAcceptanceSlaPolicySetRequest {
  readonly tenantId: string;
  readonly policySetId: string;
}

export interface PublishAcceptanceSlaPolicyRequest {
  readonly policySet: AcceptanceSlaPolicySet;
  readonly command: PublishAcceptanceSlaPolicyCommand;
}

export interface PublishAcceptanceSlaPolicyResult {
  readonly policySet: AcceptanceSlaPolicySet;
  readonly revision: AcceptanceSlaPolicyRevision;
  readonly receipt: PrivilegedCommandReceipt;
  readonly replayed: boolean;
}

export interface EffectiveAcceptanceSlaPolicyRequest {
  readonly policySet: AcceptanceSlaPolicySet;
  readonly tenantId: string;
  readonly policySetId: string;
  readonly actor: PrivilegedCommandActor;
  readonly family: BuyAcceptanceSlaFamily;
  readonly at: string;
}

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-F0-9]{64}$/u;
const ADMIN_SCOPE = "commerce.fulfilment_policy.admin";
const PAYLOAD_KEYS = [
  "effectiveFrom",
  "family",
  "maximumSequentialPartners",
  "overallAssignmentCeilingSeconds",
  "reasonCode",
  "responseWindowSeconds",
] as const;
const MAX_POLICY_HISTORY = 499;

function fail(code: AcceptanceSlaPolicyErrorCode, message: string): never {
  throw new AcceptanceSlaPolicyError(code, message);
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

function family(value: unknown): BuyAcceptanceSlaFamily {
  if (
    typeof value !== "string" ||
    !buyAcceptanceSlaFamilies.includes(value as BuyAcceptanceSlaFamily)
  ) {
    fail("unsupported_family", "acceptance policy family is unsupported.");
  }
  return value as BuyAcceptanceSlaFamily;
}

function wholeNumberInRange(
  value: unknown,
  minimum: number,
  maximum: number,
  label: string,
): number {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value < minimum ||
    value > maximum
  ) {
    fail(
      "policy_bounds",
      `${label} must be a whole number from ${minimum} through ${maximum}.`,
    );
  }
  return value;
}

export interface AcceptanceSlaTimelineValues {
  readonly responseWindowSeconds: number;
  readonly maximumSequentialPartners: number;
  readonly overallAssignmentCeilingSeconds: number;
  readonly whatsAppOffsetSeconds: number;
  readonly agenticCallOffsetSeconds: number;
}

export function deriveAcceptanceSlaTimeline(
  responseWindowValue: unknown,
  maximumPartnersValue: unknown,
  ceilingValue: unknown,
): AcceptanceSlaTimelineValues {
  const responseWindowSeconds = wholeNumberInRange(
    responseWindowValue,
    30,
    300,
    "response window",
  );
  const maximumSequentialPartners = wholeNumberInRange(
    maximumPartnersValue,
    1,
    5,
    "maximum sequential partners",
  );
  const expectedCeiling = responseWindowSeconds * maximumSequentialPartners;
  if (
    typeof ceilingValue !== "number" ||
    !Number.isSafeInteger(ceilingValue) ||
    ceilingValue !== expectedCeiling
  ) {
    fail(
      "policy_bounds",
      "overall assignment ceiling must equal response window multiplied by maximum sequential partners.",
    );
  }
  return {
    responseWindowSeconds,
    maximumSequentialPartners,
    overallAssignmentCeilingSeconds: expectedCeiling,
    whatsAppOffsetSeconds: Math.floor(responseWindowSeconds / 3),
    agenticCallOffsetSeconds: Math.floor((responseWindowSeconds * 2) / 3),
  };
}

function payload(value: unknown): NormalizedAcceptanceSlaPolicyPayload {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    (Object.getPrototypeOf(value) !== Object.prototype &&
      Object.getPrototypeOf(value) !== null)
  ) {
    fail("invalid_input", "acceptance policy payload must be a plain record.");
  }
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record).sort();
  if (
    keys.length !== PAYLOAD_KEYS.length ||
    keys.some((key, index) => key !== PAYLOAD_KEYS[index])
  ) {
    fail("invalid_input", "acceptance policy payload fields are not exact.");
  }
  const values = deriveAcceptanceSlaTimeline(
    record.responseWindowSeconds,
    record.maximumSequentialPartners,
    record.overallAssignmentCeilingSeconds,
  );
  return Object.freeze({
    family: family(record.family),
    ...values,
    effectiveFrom:
      typeof record.effectiveFrom === "string"
        ? timestamp(record.effectiveFrom, "effectiveFrom")
        : fail("invalid_input", "effectiveFrom must be a timestamp."),
    reasonCode:
      typeof record.reasonCode === "string"
        ? identifier(record.reasonCode, "reason code")
        : fail("invalid_input", "reason code must be a stable identifier."),
  });
}

function canonicalDigestValue(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(canonicalDigestValue);
  }
  if (typeof value === "object" && value !== null) {
    return Object.fromEntries(
      Object.entries(value)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, item]) => [key, canonicalDigestValue(item)]),
    );
  }
  return value;
}

function sha256(value: unknown): string {
  return createHash("sha256")
    .update(JSON.stringify(canonicalDigestValue(value)))
    .digest("hex")
    .toUpperCase();
}

function cloneReceipt(
  value: PrivilegedCommandReceipt,
): PrivilegedCommandReceipt {
  return Object.freeze({ ...value });
}

function freezeRevision(
  value: AcceptanceSlaPolicyRevision,
): AcceptanceSlaPolicyRevision {
  return Object.freeze({ ...value });
}

function freezeAudit(
  value: AcceptanceSlaPolicyAuditEvent,
): AcceptanceSlaPolicyAuditEvent {
  return Object.freeze({ ...value });
}

function freezePolicySet(
  value: AcceptanceSlaPolicySet,
): AcceptanceSlaPolicySet {
  return Object.freeze({
    ...value,
    revisions: Object.freeze(value.revisions.map(freezeRevision)),
    receipts: Object.freeze(value.receipts.map(cloneReceipt)),
    auditEvents: Object.freeze(value.auditEvents.map(freezeAudit)),
  });
}

function normalizePolicySet(
  value: AcceptanceSlaPolicySet,
): AcceptanceSlaPolicySet {
  if (value.schemaVersion !== 1) {
    fail("invalid_input", "acceptance policy schema version is unsupported.");
  }
  const tenantId = identifier(value.tenantId, "tenant id");
  const policySetId = identifier(value.policySetId, "policy set id");
  const version = positiveVersion(value.version, "policy set version");
  if (
    value.revisions.length > MAX_POLICY_HISTORY ||
    value.receipts.length > MAX_POLICY_HISTORY ||
    value.auditEvents.length > MAX_POLICY_HISTORY
  ) {
    fail("invalid_input", "acceptance policy history exceeds its bounded limit.");
  }
  if (
    value.revisions.length !== version - 1 ||
    value.receipts.length !== value.revisions.length ||
    value.auditEvents.length !== value.revisions.length
  ) {
    fail("invalid_input", "acceptance policy history and version are inconsistent.");
  }

  const lastEffectiveByFamily = new Map<BuyAcceptanceSlaFamily, number>();
  const seenCommands = new Set<string>();
  const revisions = value.revisions.map((item, index) => {
    if (item.schemaVersion !== 1 || item.aggregateVersion !== index + 2) {
      fail("invalid_input", "acceptance policy revision order is invalid.");
    }
    const policyFamily = family(item.family);
    const values = deriveAcceptanceSlaTimeline(
      item.responseWindowSeconds,
      item.maximumSequentialPartners,
      item.overallAssignmentCeilingSeconds,
    );
    if (
      item.moolChatOffsetSeconds !== 0 ||
      item.whatsAppOffsetSeconds !== values.whatsAppOffsetSeconds ||
      item.agenticCallOffsetSeconds !== values.agenticCallOffsetSeconds ||
      item.reassignAtSeconds !== values.responseWindowSeconds
    ) {
      fail("invalid_input", "acceptance policy escalation offsets are invalid.");
    }
    const effectiveFrom = timestamp(item.effectiveFrom, "revision effectiveFrom");
    const publishedAt = timestamp(item.publishedAt, "revision publishedAt");
    if (Date.parse(effectiveFrom) < Date.parse(publishedAt)) {
      fail("invalid_input", "accepted revision is backdated.");
    }
    const previousEffective = lastEffectiveByFamily.get(policyFamily);
    if (
      previousEffective !== undefined &&
      Date.parse(effectiveFrom) <= previousEffective
    ) {
      fail("invalid_input", "accepted family revisions are not strictly ordered.");
    }
    lastEffectiveByFamily.set(policyFamily, Date.parse(effectiveFrom));
    const commandId = identifier(item.commandId, "revision command id");
    if (seenCommands.has(commandId)) {
      fail("invalid_input", "accepted revisions contain a duplicate command id.");
    }
    seenCommands.add(commandId);
    if (!SHA256_PATTERN.test(item.commandFingerprint)) {
      fail("invalid_input", "revision command fingerprint must be SHA-256.");
    }
    return freezeRevision({
      schemaVersion: 1,
      revisionId: identifier(item.revisionId, "revision id"),
      aggregateVersion: item.aggregateVersion,
      family: policyFamily,
      ...values,
      moolChatOffsetSeconds: 0,
      reassignAtSeconds: values.responseWindowSeconds,
      effectiveFrom,
      publishedAt,
      reasonCode: identifier(item.reasonCode, "reason code"),
      commandId,
      commandFingerprint: item.commandFingerprint,
      actorId: identifier(item.actorId, "revision actor id"),
    });
  });

  const receipts = value.receipts.map((item, index) => {
    const revision = revisions[index];
    if (
      revision === undefined ||
      item.schemaVersion !== 1 ||
      item.aggregateVersion !== revision.aggregateVersion ||
      item.aggregateId !== policySetId ||
      item.commandId !== revision.commandId ||
      item.commandFingerprint !== revision.commandFingerprint ||
      item.actorId !== revision.actorId ||
      item.requiredScope !== ADMIN_SCOPE ||
      item.resultReference !== revision.revisionId ||
      item.resultSha256 !== sha256(revision) ||
      item.completedAt !== revision.publishedAt
    ) {
      fail("invalid_input", "acceptance policy receipt history is inconsistent.");
    }
    return cloneReceipt(item);
  });

  const auditEvents = value.auditEvents.map((item, index) => {
    const revision = revisions[index];
    if (
      revision === undefined ||
      item.schemaVersion !== 1 ||
      item.eventType !== "acceptance_sla_policy_published" ||
      item.aggregateVersion !== revision.aggregateVersion ||
      item.tenantId !== tenantId ||
      item.policySetId !== policySetId ||
      item.revisionId !== revision.revisionId ||
      item.family !== revision.family ||
      item.commandId !== revision.commandId ||
      item.commandFingerprint !== revision.commandFingerprint ||
      item.actorId !== revision.actorId ||
      item.occurredAt !== revision.publishedAt
    ) {
      fail("invalid_input", "acceptance policy audit history is inconsistent.");
    }
    return freezeAudit({
      ...item,
      eventId: identifier(item.eventId, "audit event id"),
    });
  });

  return freezePolicySet({
    schemaVersion: 1,
    tenantId,
    policySetId,
    version,
    revisions,
    receipts,
    auditEvents,
  });
}

function actorForRead(value: PrivilegedCommandActor): PrivilegedCommandActor {
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

export function createAcceptanceSlaPolicySet(
  request: CreateAcceptanceSlaPolicySetRequest,
): AcceptanceSlaPolicySet {
  return freezePolicySet({
    schemaVersion: 1,
    tenantId: identifier(request.tenantId, "tenant id"),
    policySetId: identifier(request.policySetId, "policy set id"),
    version: 1,
    revisions: [],
    receipts: [],
    auditEvents: [],
  });
}

export function publishAcceptanceSlaPolicy(
  request: PublishAcceptanceSlaPolicyRequest,
): PublishAcceptanceSlaPolicyResult {
  const authorization = authorizePrivilegedCommand({
    tenantId: request.policySet.tenantId,
    aggregateId: request.policySet.policySetId,
    currentVersion: request.policySet.version,
    requiredScope: ADMIN_SCOPE,
    receipts: request.policySet.receipts,
    command: request.command,
  });
  const current = normalizePolicySet(request.policySet);

  if (authorization.state === "replay") {
    const revision = current.revisions.find(
      (item) => item.aggregateVersion === authorization.receipt.aggregateVersion,
    );
    if (revision === undefined) {
      fail("invalid_input", "command receipt has no matching policy revision.");
    }
    return Object.freeze({
      policySet: current,
      revision,
      receipt: authorization.receipt,
      replayed: true,
    });
  }

  const commandPayload = payload(request.command.payload);
  if (Date.parse(commandPayload.effectiveFrom) < Date.parse(authorization.occurredAt)) {
    fail(
      "effective_time_conflict",
      "acceptance policy cannot be backdated before publication.",
    );
  }
  const previousForFamily = [...current.revisions]
    .reverse()
    .find((item) => item.family === commandPayload.family);
  if (
    previousForFamily !== undefined &&
    Date.parse(commandPayload.effectiveFrom) <= Date.parse(previousForFamily.effectiveFrom)
  ) {
    fail(
      "effective_time_conflict",
      "family policy effective time must follow its prior revision.",
    );
  }

  const aggregateVersion = current.version + 1;
  const revisionId = `acceptance-sla-revision:${aggregateVersion}`;
  const revision = freezeRevision({
    schemaVersion: 1,
    revisionId,
    aggregateVersion,
    family: commandPayload.family,
    responseWindowSeconds: commandPayload.responseWindowSeconds,
    maximumSequentialPartners: commandPayload.maximumSequentialPartners,
    overallAssignmentCeilingSeconds:
      commandPayload.overallAssignmentCeilingSeconds,
    moolChatOffsetSeconds: 0,
    whatsAppOffsetSeconds: commandPayload.whatsAppOffsetSeconds,
    agenticCallOffsetSeconds: commandPayload.agenticCallOffsetSeconds,
    reassignAtSeconds: commandPayload.responseWindowSeconds,
    effectiveFrom: commandPayload.effectiveFrom,
    publishedAt: authorization.occurredAt,
    reasonCode: commandPayload.reasonCode,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
    actorId: authorization.actorId,
  });
  const resultSha256 = sha256(revision);
  const receipts = completePrivilegedCommand({
    reservation: authorization,
    currentReceipts: current.receipts,
    newAggregateVersion: aggregateVersion,
    resultReference: revisionId,
    resultSha256,
    completedAt: authorization.occurredAt,
  });
  const receipt = receipts.at(-1);
  if (receipt === undefined) {
    fail("invalid_input", "completed policy command did not produce a receipt.");
  }
  const audit = freezeAudit({
    schemaVersion: 1,
    eventId: `acceptance-sla-event:${aggregateVersion}`,
    eventType: "acceptance_sla_policy_published",
    aggregateVersion,
    tenantId: current.tenantId,
    policySetId: current.policySetId,
    revisionId,
    family: commandPayload.family,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
    actorId: authorization.actorId,
    occurredAt: authorization.occurredAt,
  });
  const policySet = freezePolicySet({
    ...current,
    version: aggregateVersion,
    revisions: [...current.revisions, revision],
    receipts,
    auditEvents: [...current.auditEvents, audit],
  });
  return Object.freeze({ policySet, revision, receipt, replayed: false });
}

export function effectiveAcceptanceSlaPolicyAt(
  request: EffectiveAcceptanceSlaPolicyRequest,
): AcceptanceSlaPolicyRevision | null {
  const queryActor = actorForRead(request.actor);
  const requestedTenantId = identifier(request.tenantId, "tenant id");
  if (!queryActor.scopes.includes(ADMIN_SCOPE)) {
    fail("unauthorized", "actor lacks acceptance policy authority.");
  }
  if (queryActor.tenantId !== requestedTenantId) {
    fail("tenant_mismatch", "actor cannot read another tenant's policy.");
  }
  const requestedPolicySetId = identifier(request.policySetId, "policy set id");
  if (request.policySet.tenantId !== requestedTenantId) {
    fail("tenant_mismatch", "policy is unavailable for this tenant.");
  }
  if (request.policySet.policySetId !== requestedPolicySetId) {
    fail("aggregate_mismatch", "requested policy set is unavailable.");
  }
  const policySet = normalizePolicySet(request.policySet);
  const policyFamily = family(request.family);
  const at = timestamp(request.at, "effective-at timestamp");
  const matching = policySet.revisions.filter(
    (item) =>
      item.family === policyFamily &&
      Date.parse(item.effectiveFrom) <= Date.parse(at),
  );
  return matching.at(-1) ?? null;
}
