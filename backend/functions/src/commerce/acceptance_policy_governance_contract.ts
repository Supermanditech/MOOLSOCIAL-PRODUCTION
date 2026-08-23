import { createHash } from "node:crypto";

import {
  buyAcceptanceSlaFamilies,
  type BuyAcceptanceSlaFamily,
  AcceptanceSlaPolicyRevision,
  AcceptanceSlaPolicySet,
} from "./acceptance_sla_policy_contract.js";
import type {
  AcceptanceSlaScheduleOverrideRevision,
  AcceptanceSlaScheduleOverrideSet,
} from "./acceptance_sla_schedule_override_contract.js";
import {
  authorizePrivilegedCommand,
  completePrivilegedCommand,
  type JsonValue,
  type PrivilegedCommandActor,
  type PrivilegedCommandEnvelope,
  type PrivilegedCommandReceipt,
} from "../workspace/privileged_command_contract.js";

export type AcceptancePolicyGovernanceErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "aggregate_mismatch"
  | "source_mismatch"
  | "effective_time_conflict"
  | "invalid_state"
  | "maker_checker_conflict";

export class AcceptancePolicyGovernanceError extends Error {
  constructor(
    readonly code: AcceptancePolicyGovernanceErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "AcceptancePolicyGovernanceError";
  }
}

export type AcceptancePolicyGovernanceAction =
  | "approve_revision"
  | "rollback_to_revision";
export type AcceptancePolicyGovernanceDecision = "approved" | "rejected";

export type AcceptancePolicyRevisionReference =
  | Readonly<{
      kind: "global_policy";
      sourceSetId: string;
      revisionId: string;
      aggregateVersion: number;
      family: AcceptanceSlaPolicyRevision["family"];
      effectiveFrom: string;
      commandFingerprint: string;
      sourceFingerprint: string;
    }>
  | Readonly<{
      kind: "schedule_override";
      sourceSetId: string;
      revisionId: string;
      aggregateVersion: number;
      family: AcceptanceSlaScheduleOverrideRevision["selector"]["family"];
      overrideId: string;
      state: AcceptanceSlaScheduleOverrideRevision["state"];
      selectorFingerprint: string;
      effectiveFrom: string;
      commandFingerprint: string;
      sourceFingerprint: string;
    }>;

export type AcceptancePolicyGovernanceSource =
  | Readonly<{
      kind: "global_policy";
      policySet: AcceptanceSlaPolicySet;
      revisionId: string;
    }>
  | Readonly<{
      kind: "schedule_override";
      overrideSet: AcceptanceSlaScheduleOverrideSet;
      revisionId: string;
    }>;

export interface ProposePolicyGovernancePayload
  extends Readonly<Record<string, JsonValue>> {
  readonly governanceId: string;
  readonly action: AcceptancePolicyGovernanceAction;
  readonly sourceFingerprint: string;
  readonly effectiveFrom: string;
  readonly reasonCode: string;
  readonly explanation: string;
}

export interface DecidePolicyGovernancePayload
  extends Readonly<Record<string, JsonValue>> {
  readonly governanceId: string;
  readonly proposalId: string;
  readonly decision: AcceptancePolicyGovernanceDecision;
  readonly reasonCode: string;
  readonly explanation: string;
}

export type ProposePolicyGovernanceCommand = Omit<
  PrivilegedCommandEnvelope,
  "payload"
> & { readonly payload: ProposePolicyGovernancePayload };
export type DecidePolicyGovernanceCommand = Omit<
  PrivilegedCommandEnvelope,
  "payload"
> & { readonly payload: DecidePolicyGovernancePayload };

export interface PolicyGovernanceProposalEvent {
  readonly schemaVersion: 1;
  readonly eventKind: "proposal";
  readonly eventId: string;
  readonly aggregateVersion: number;
  readonly proposalId: string;
  readonly action: AcceptancePolicyGovernanceAction;
  readonly source: AcceptancePolicyRevisionReference;
  readonly effectiveFrom: string;
  readonly reasonCode: string;
  readonly explanation: string;
  readonly makerId: string;
  readonly occurredAt: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
}

export interface PolicyGovernanceDecisionEvent {
  readonly schemaVersion: 1;
  readonly eventKind: "decision";
  readonly eventId: string;
  readonly aggregateVersion: number;
  readonly proposalId: string;
  readonly decision: AcceptancePolicyGovernanceDecision;
  readonly reasonCode: string;
  readonly explanation: string;
  readonly checkerId: string;
  readonly occurredAt: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
}

export type PolicyGovernanceEvent =
  | PolicyGovernanceProposalEvent
  | PolicyGovernanceDecisionEvent;

export interface AcceptancePolicyGovernanceAuditEvent {
  readonly schemaVersion: 1;
  readonly eventId: string;
  readonly eventType:
    | "acceptance_policy_governance_proposed"
    | "acceptance_policy_governance_decided";
  readonly aggregateVersion: number;
  readonly tenantId: string;
  readonly governanceId: string;
  readonly governanceEventId: string;
  readonly proposalId: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
  readonly occurredAt: string;
}

export interface AcceptancePolicyGovernanceAggregate {
  readonly schemaVersion: 1;
  readonly tenantId: string;
  readonly governanceId: string;
  readonly targetKind: AcceptancePolicyRevisionReference["kind"];
  readonly sourceSetId: string;
  readonly targetSubjectId: string;
  readonly version: number;
  readonly events: readonly PolicyGovernanceEvent[];
  readonly receipts: readonly PrivilegedCommandReceipt[];
  readonly auditEvents: readonly AcceptancePolicyGovernanceAuditEvent[];
}

export interface ProposePolicyGovernanceRequest {
  readonly aggregate: AcceptancePolicyGovernanceAggregate;
  readonly source: AcceptancePolicyGovernanceSource;
  readonly command: ProposePolicyGovernanceCommand;
}

export interface DecidePolicyGovernanceRequest {
  readonly aggregate: AcceptancePolicyGovernanceAggregate;
  readonly command: DecidePolicyGovernanceCommand;
}

export interface PolicyGovernanceCommandResult {
  readonly aggregate: AcceptancePolicyGovernanceAggregate;
  readonly event: PolicyGovernanceEvent;
  readonly receipt: PrivilegedCommandReceipt;
  readonly replayed: boolean;
}

export type EffectiveAcceptancePolicyGovernance =
  | Readonly<{ state: "unknown" }>
  | Readonly<{
      state: "approved";
      action: AcceptancePolicyGovernanceAction;
      source: AcceptancePolicyRevisionReference;
      proposalId: string;
      decisionEventId: string;
      effectiveFrom: string;
      makerExplanation: string;
      checkerExplanation: string;
    }>;

const MAKER_SCOPE = "commerce.acceptance_policy_governance.propose";
const CHECKER_SCOPE = "commerce.acceptance_policy_governance.approve";
const SOURCE_ADMIN_SCOPE = "commerce.fulfilment_policy.admin";
const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-F0-9]{64}$/u;
const MAX_HISTORY = 500;

function fail(code: AcceptancePolicyGovernanceErrorCode, message: string): never {
  throw new AcceptancePolicyGovernanceError(code, message);
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

function sha(value: string, label: string): string {
  if (!SHA256_PATTERN.test(value)) {
    fail("invalid_input", `${label} must be uppercase SHA-256.`);
  }
  return value;
}

function sha256Text(value: string): string {
  return createHash("sha256").update(value).digest("hex").toUpperCase();
}

function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value !== null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return `{${Object.keys(record)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${canonicalJson(record[key])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function exactPlainRecord(
  value: unknown,
  expectedKeys: readonly string[],
  label: string,
): Record<string, unknown> {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    (Object.getPrototypeOf(value) !== Object.prototype &&
      Object.getPrototypeOf(value) !== null)
  ) {
    fail("invalid_input", `${label} must be a plain record.`);
  }
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record).sort();
  if (
    keys.length !== expectedKeys.length ||
    keys.some((key, index) => key !== expectedKeys[index])
  ) {
    fail("invalid_input", `${label} fields are not exact.`);
  }
  return record;
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
    fail("invalid_input", "acceptance policy family is unsupported.");
  }
  return value as BuyAcceptanceSlaFamily;
}

function explanation(value: string, label: string): string {
  const normalized = value.trim();
  if (normalized.length < 8 || normalized.length > 500 || /[\u0000-\u0008]/u.test(normalized)) {
    fail("invalid_input", `${label} must be 8 to 500 safe characters.`);
  }
  return normalized;
}

function action(value: unknown): AcceptancePolicyGovernanceAction {
  if (value !== "approve_revision" && value !== "rollback_to_revision") {
    fail("invalid_input", "governance action is unsupported.");
  }
  return value;
}

function decision(value: unknown): AcceptancePolicyGovernanceDecision {
  if (value !== "approved" && value !== "rejected") {
    fail("invalid_input", "governance decision is unsupported.");
  }
  return value;
}

const PROPOSE_PAYLOAD_KEYS = [
  "action",
  "effectiveFrom",
  "explanation",
  "governanceId",
  "reasonCode",
  "sourceFingerprint",
] as const;
const DECIDE_PAYLOAD_KEYS = [
  "decision",
  "explanation",
  "governanceId",
  "proposalId",
  "reasonCode",
] as const;

function proposePayload(value: unknown): ProposePolicyGovernancePayload {
  const record = exactPlainRecord(value, PROPOSE_PAYLOAD_KEYS, "proposal payload");
  return Object.freeze({
    governanceId:
      typeof record.governanceId === "string"
        ? identifier(record.governanceId, "payload governance id")
        : fail("invalid_input", "payload governance id is invalid."),
    action: action(record.action),
    sourceFingerprint:
      typeof record.sourceFingerprint === "string"
        ? sha(record.sourceFingerprint, "payload source fingerprint")
        : fail("invalid_input", "payload source fingerprint is invalid."),
    effectiveFrom:
      typeof record.effectiveFrom === "string"
        ? timestamp(record.effectiveFrom, "payload effectiveFrom")
        : fail("invalid_input", "payload effectiveFrom is invalid."),
    reasonCode:
      typeof record.reasonCode === "string"
        ? identifier(record.reasonCode, "proposal reason code")
        : fail("invalid_input", "proposal reason code is invalid."),
    explanation:
      typeof record.explanation === "string"
        ? explanation(record.explanation, "maker explanation")
        : fail("invalid_input", "maker explanation is invalid."),
  });
}

function decidePayload(value: unknown): DecidePolicyGovernancePayload {
  const record = exactPlainRecord(value, DECIDE_PAYLOAD_KEYS, "decision payload");
  return Object.freeze({
    governanceId:
      typeof record.governanceId === "string"
        ? identifier(record.governanceId, "payload governance id")
        : fail("invalid_input", "payload governance id is invalid."),
    proposalId:
      typeof record.proposalId === "string"
        ? identifier(record.proposalId, "payload proposal id")
        : fail("invalid_input", "payload proposal id is invalid."),
    decision: decision(record.decision),
    reasonCode:
      typeof record.reasonCode === "string"
        ? identifier(record.reasonCode, "decision reason code")
        : fail("invalid_input", "decision reason code is invalid."),
    explanation:
      typeof record.explanation === "string"
        ? explanation(record.explanation, "checker explanation")
        : fail("invalid_input", "checker explanation is invalid."),
  });
}

function freezeReference(
  value: AcceptancePolicyRevisionReference,
): AcceptancePolicyRevisionReference {
  return Object.freeze({ ...value });
}

function referenceFingerprint(
  value: unknown,
): string {
  return sha256Text(canonicalJson(value));
}

function validateSourceEvidence(request: {
  readonly tenantId: string;
  readonly sourceSetId: string;
  readonly revisionId: string;
  readonly aggregateVersion: number;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
  readonly publishedAt: string;
  readonly receipts: readonly PrivilegedCommandReceipt[];
  readonly auditValues: Readonly<{
    tenantId: string;
    sourceSetId: string;
    revisionId: string;
    aggregateVersion: number;
    commandId: string;
    commandFingerprint: string;
    actorId: string;
    occurredAt: string;
  }>;
}): void {
  const receipt = request.receipts.find(
    (item) => item.aggregateVersion === request.aggregateVersion,
  );
  if (receipt === undefined) {
    fail("source_mismatch", "policy source receipt is missing.");
  }
  sha(receipt.resultSha256, "source result digest");
  if (
    receipt.schemaVersion !== 1 ||
    receipt.commandId !== request.commandId ||
    receipt.commandFingerprint !== request.commandFingerprint ||
    receipt.aggregateId !== request.sourceSetId ||
    receipt.resultReference !== request.revisionId ||
    receipt.actorId !== request.actorId ||
    receipt.requiredScope !== SOURCE_ADMIN_SCOPE ||
    receipt.completedAt !== request.publishedAt ||
    request.auditValues.tenantId !== request.tenantId ||
    request.auditValues.sourceSetId !== request.sourceSetId ||
    request.auditValues.revisionId !== request.revisionId ||
    request.auditValues.aggregateVersion !== request.aggregateVersion ||
    request.auditValues.commandId !== request.commandId ||
    request.auditValues.commandFingerprint !== request.commandFingerprint ||
    request.auditValues.actorId !== request.actorId ||
    request.auditValues.occurredAt !== request.publishedAt
  ) {
    fail("source_mismatch", "policy source evidence is inconsistent.");
  }
}

function normalizeSource(source: AcceptancePolicyGovernanceSource): Readonly<{
  tenantId: string;
  reference: AcceptancePolicyRevisionReference;
}> {
  if (source.kind === "global_policy") {
    const set = source.policySet;
    const setVersion = positiveVersion(set.version, "source set version");
    if (
      set.schemaVersion !== 1 ||
      set.revisions.length !== setVersion - 1 ||
      set.receipts.length !== set.revisions.length ||
      set.auditEvents.length !== set.revisions.length
    ) {
      fail("source_mismatch", "global policy source history is inconsistent.");
    }
    const tenantId = identifier(set.tenantId, "source tenant id");
    const sourceSetId = identifier(set.policySetId, "policy set id");
    const revisionId = identifier(source.revisionId, "source revision id");
    const revisionIndex = set.revisions.findIndex(
      (item) => item.revisionId === revisionId,
    );
    const revision = set.revisions[revisionIndex];
    const audit = set.auditEvents.find((item) => item.revisionId === revisionId);
    if (revision === undefined || audit === undefined) {
      fail("source_mismatch", "global policy revision does not exist.");
    }
    const aggregateVersion = positiveVersion(
      revision.aggregateVersion,
      "source aggregate version",
    );
    const effectiveFrom = timestamp(revision.effectiveFrom, "source effectiveFrom");
    const publishedAt = timestamp(revision.publishedAt, "source publishedAt");
    const commandFingerprint = sha(
      revision.commandFingerprint,
      "source command fingerprint",
    );
    if (
      revision.schemaVersion !== 1 ||
      audit.schemaVersion !== 1 ||
      aggregateVersion !== revisionIndex + 2 ||
      aggregateVersion > setVersion ||
      Date.parse(publishedAt) > Date.parse(effectiveFrom) ||
      audit.eventType !== "acceptance_sla_policy_published" ||
      audit.policySetId !== sourceSetId ||
      audit.family !== revision.family
    ) {
      fail("source_mismatch", "global policy revision evidence is invalid.");
    }
    validateSourceEvidence({
      tenantId,
      sourceSetId,
      revisionId,
      aggregateVersion,
      commandId: identifier(revision.commandId, "source command id"),
      commandFingerprint,
      actorId: identifier(revision.actorId, "source actor id"),
      publishedAt,
      receipts: set.receipts,
      auditValues: {
        tenantId: audit.tenantId,
        sourceSetId: audit.policySetId,
        revisionId: audit.revisionId,
        aggregateVersion: audit.aggregateVersion,
        commandId: audit.commandId,
        commandFingerprint: audit.commandFingerprint,
        actorId: audit.actorId,
        occurredAt: audit.occurredAt,
      },
    });
    const withoutFingerprint = Object.freeze({
      kind: "global_policy" as const,
      sourceSetId,
      revisionId,
      aggregateVersion,
      family: family(revision.family),
      effectiveFrom,
      commandFingerprint,
    });
    return Object.freeze({
      tenantId,
      reference: freezeReference({
        ...withoutFingerprint,
        sourceFingerprint: referenceFingerprint(withoutFingerprint),
      }),
    });
  }

  const set = source.overrideSet;
  const setVersion = positiveVersion(set.version, "source set version");
  if (
    set.schemaVersion !== 1 ||
    set.revisions.length !== setVersion - 1 ||
    set.receipts.length !== set.revisions.length ||
    set.auditEvents.length !== set.revisions.length
  ) {
    fail("source_mismatch", "schedule override source history is inconsistent.");
  }
  const tenantId = identifier(set.tenantId, "source tenant id");
  const sourceSetId = identifier(set.overrideSetId, "override set id");
  const revisionId = identifier(source.revisionId, "source revision id");
  const revisionIndex = set.revisions.findIndex(
    (item) => item.revisionId === revisionId,
  );
  const revision = set.revisions[revisionIndex];
  const audit = set.auditEvents.find((item) => item.revisionId === revisionId);
  if (revision === undefined || audit === undefined) {
    fail("source_mismatch", "schedule override revision does not exist.");
  }
  const aggregateVersion = positiveVersion(
    revision.aggregateVersion,
    "source aggregate version",
  );
  const effectiveFrom = timestamp(revision.effectiveFrom, "source effectiveFrom");
  const publishedAt = timestamp(revision.publishedAt, "source publishedAt");
  const commandFingerprint = sha(
    revision.commandFingerprint,
    "source command fingerprint",
  );
  const selectorFingerprint = sha(
    revision.selectorFingerprint,
    "source selector fingerprint",
  );
  if (
    revision.schemaVersion !== 1 ||
    audit.schemaVersion !== 1 ||
    aggregateVersion !== revisionIndex + 2 ||
    aggregateVersion > setVersion ||
    Date.parse(publishedAt) > Date.parse(effectiveFrom) ||
    audit.eventType !== "acceptance_sla_schedule_override_published" ||
    audit.overrideSetId !== sourceSetId ||
    audit.overrideId !== revision.overrideId ||
    audit.family !== revision.selector.family ||
    audit.state !== revision.state ||
    audit.selectorFingerprint !== selectorFingerprint
  ) {
    fail("source_mismatch", "schedule override revision evidence is invalid.");
  }
  validateSourceEvidence({
    tenantId,
    sourceSetId,
    revisionId,
    aggregateVersion,
    commandId: identifier(revision.commandId, "source command id"),
    commandFingerprint,
    actorId: identifier(revision.actorId, "source actor id"),
    publishedAt,
    receipts: set.receipts,
    auditValues: {
      tenantId: audit.tenantId,
      sourceSetId: audit.overrideSetId,
      revisionId: audit.revisionId,
      aggregateVersion: audit.aggregateVersion,
      commandId: audit.commandId,
      commandFingerprint: audit.commandFingerprint,
      actorId: audit.actorId,
      occurredAt: audit.occurredAt,
    },
  });
  const withoutFingerprint = Object.freeze({
    kind: "schedule_override" as const,
    sourceSetId,
    revisionId,
    aggregateVersion,
    family: family(revision.selector.family),
    overrideId: identifier(revision.overrideId, "source override id"),
    state:
      revision.state === "enabled" || revision.state === "disabled"
        ? revision.state
        : fail("invalid_input", "source override state is unsupported."),
    selectorFingerprint,
    effectiveFrom,
    commandFingerprint,
  });
  return Object.freeze({
    tenantId,
    reference: freezeReference({
      ...withoutFingerprint,
      sourceFingerprint: referenceFingerprint(withoutFingerprint),
    }),
  });
}

const AGGREGATE_KEYS = [
  "auditEvents",
  "events",
  "governanceId",
  "receipts",
  "schemaVersion",
  "sourceSetId",
  "targetKind",
  "targetSubjectId",
  "tenantId",
  "version",
] as const;
const GLOBAL_REFERENCE_KEYS = [
  "aggregateVersion",
  "commandFingerprint",
  "effectiveFrom",
  "family",
  "kind",
  "revisionId",
  "sourceFingerprint",
  "sourceSetId",
] as const;
const OVERRIDE_REFERENCE_KEYS = [
  "aggregateVersion",
  "commandFingerprint",
  "effectiveFrom",
  "family",
  "kind",
  "overrideId",
  "revisionId",
  "selectorFingerprint",
  "sourceFingerprint",
  "sourceSetId",
  "state",
] as const;
const PROPOSAL_EVENT_KEYS = [
  "action",
  "aggregateVersion",
  "commandFingerprint",
  "commandId",
  "effectiveFrom",
  "eventId",
  "eventKind",
  "explanation",
  "makerId",
  "occurredAt",
  "proposalId",
  "reasonCode",
  "schemaVersion",
  "source",
] as const;
const DECISION_EVENT_KEYS = [
  "aggregateVersion",
  "checkerId",
  "commandFingerprint",
  "commandId",
  "decision",
  "eventId",
  "eventKind",
  "explanation",
  "occurredAt",
  "proposalId",
  "reasonCode",
  "schemaVersion",
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
  "governanceEventId",
  "governanceId",
  "occurredAt",
  "proposalId",
  "schemaVersion",
  "tenantId",
] as const;

function normalizeReference(value: AcceptancePolicyRevisionReference): AcceptancePolicyRevisionReference {
  if (value.kind === "global_policy") {
    exactPlainRecord(value, GLOBAL_REFERENCE_KEYS, "global policy reference");
    const withoutFingerprint = Object.freeze({
      kind: "global_policy" as const,
      sourceSetId: identifier(value.sourceSetId, "reference source set id"),
      revisionId: identifier(value.revisionId, "reference revision id"),
      aggregateVersion: positiveVersion(
        value.aggregateVersion,
        "reference aggregate version",
      ),
      family: family(value.family),
      effectiveFrom: timestamp(value.effectiveFrom, "reference effectiveFrom"),
      commandFingerprint: sha(
        value.commandFingerprint,
        "reference command fingerprint",
      ),
    });
    const fingerprint = sha(value.sourceFingerprint, "reference source fingerprint");
    if (fingerprint !== referenceFingerprint(withoutFingerprint)) {
      fail("source_mismatch", "global policy reference fingerprint is invalid.");
    }
    return freezeReference({ ...withoutFingerprint, sourceFingerprint: fingerprint });
  }
  exactPlainRecord(value, OVERRIDE_REFERENCE_KEYS, "schedule override reference");
  if (value.state !== "enabled" && value.state !== "disabled") {
    fail("invalid_input", "schedule override state is unsupported.");
  }
  const withoutFingerprint = Object.freeze({
    kind: "schedule_override" as const,
    sourceSetId: identifier(value.sourceSetId, "reference source set id"),
    revisionId: identifier(value.revisionId, "reference revision id"),
    aggregateVersion: positiveVersion(
      value.aggregateVersion,
      "reference aggregate version",
    ),
    family: family(value.family),
    overrideId: identifier(value.overrideId, "reference override id"),
    state: value.state,
    selectorFingerprint: sha(
      value.selectorFingerprint,
      "reference selector fingerprint",
    ),
    effectiveFrom: timestamp(value.effectiveFrom, "reference effectiveFrom"),
    commandFingerprint: sha(
      value.commandFingerprint,
      "reference command fingerprint",
    ),
  });
  const fingerprint = sha(value.sourceFingerprint, "reference source fingerprint");
  if (fingerprint !== referenceFingerprint(withoutFingerprint)) {
    fail("source_mismatch", "schedule override reference fingerprint is invalid.");
  }
  return freezeReference({ ...withoutFingerprint, sourceFingerprint: fingerprint });
}

function freezeAggregate(
  value: AcceptancePolicyGovernanceAggregate,
): AcceptancePolicyGovernanceAggregate {
  return Object.freeze({
    ...value,
    events: Object.freeze(
      value.events.map((item) =>
        Object.freeze(
          item.eventKind === "proposal"
            ? { ...item, source: freezeReference(item.source) }
            : { ...item },
        ),
      ),
    ),
    receipts: Object.freeze(value.receipts.map((item) => Object.freeze({ ...item }))),
    auditEvents: Object.freeze(
      value.auditEvents.map((item) => Object.freeze({ ...item })),
    ),
  });
}

function normalizeAggregate(
  value: AcceptancePolicyGovernanceAggregate,
): AcceptancePolicyGovernanceAggregate {
  exactPlainRecord(value, AGGREGATE_KEYS, "policy governance aggregate");
  if (value.schemaVersion !== 1) {
    fail("invalid_input", "policy governance schema is unsupported.");
  }
  const tenantId = identifier(value.tenantId, "tenant id");
  const governanceId = identifier(value.governanceId, "governance id");
  const sourceSetId = identifier(value.sourceSetId, "source set id");
  const targetSubjectId = identifier(value.targetSubjectId, "target subject id");
  if (value.targetKind !== "global_policy" && value.targetKind !== "schedule_override") {
    fail("invalid_input", "governance target kind is unsupported.");
  }
  const targetKind = value.targetKind;
  const version = positiveVersion(value.version, "governance version");
  if (
    value.events.length > MAX_HISTORY ||
    value.events.length !== version - 1 ||
    value.receipts.length !== value.events.length ||
    value.auditEvents.length !== value.events.length
  ) {
    fail("invalid_input", "policy governance history and version are inconsistent.");
  }

  let pending: PolicyGovernanceProposalEvent | undefined;
  let lastApproved: PolicyGovernanceProposalEvent | undefined;
  let previousOccurredAt: string | undefined;
  const events = value.events.map((item, index): PolicyGovernanceEvent => {
    const aggregateVersion = index + 2;
    const expectedEventId = `policy-governance-event:${aggregateVersion}`;
    if (item.eventKind === "proposal") {
      exactPlainRecord(item, PROPOSAL_EVENT_KEYS, "policy governance proposal");
      const source = normalizeReference(item.source);
      const effectiveFrom = timestamp(item.effectiveFrom, "proposal effectiveFrom");
      const occurredAt = timestamp(item.occurredAt, "proposal occurredAt");
      const proposalId = identifier(item.proposalId, "proposal id");
      const normalizedAction = action(item.action);
      if (
        item.schemaVersion !== 1 ||
        item.aggregateVersion !== aggregateVersion ||
        item.eventId !== expectedEventId ||
        proposalId !== `policy-governance-proposal:${aggregateVersion}` ||
        source.kind !== targetKind ||
        source.sourceSetId !== sourceSetId ||
        (source.kind === "global_policy"
          ? source.family !== targetSubjectId
          : source.overrideId !== targetSubjectId) ||
        item.effectiveFrom !== effectiveFrom ||
        Date.parse(effectiveFrom) < Date.parse(occurredAt) ||
        Date.parse(effectiveFrom) < Date.parse(source.effectiveFrom) ||
        (previousOccurredAt !== undefined &&
          Date.parse(occurredAt) < Date.parse(previousOccurredAt)) ||
        pending !== undefined
      ) {
        fail("invalid_input", "policy governance proposal history is inconsistent.");
      }
      if (lastApproved === undefined) {
        if (normalizedAction !== "approve_revision") {
          fail("invalid_state", "first approved lineage must begin with forward approval.");
        }
      } else if (
        Date.parse(effectiveFrom) <= Date.parse(lastApproved.effectiveFrom) ||
        (normalizedAction === "approve_revision" &&
          source.aggregateVersion <= lastApproved.source.aggregateVersion) ||
        (normalizedAction === "rollback_to_revision" &&
          source.aggregateVersion >= lastApproved.source.aggregateVersion)
      ) {
        fail("invalid_state", "proposal direction does not match its source revision.");
      }
      const normalized: PolicyGovernanceProposalEvent = Object.freeze({
        schemaVersion: 1,
        eventKind: "proposal",
        eventId: expectedEventId,
        aggregateVersion,
        proposalId,
        action: normalizedAction,
        source,
        effectiveFrom,
        reasonCode: identifier(item.reasonCode, "proposal reason code"),
        explanation: explanation(item.explanation, "maker explanation"),
        makerId: identifier(item.makerId, "maker id"),
        occurredAt,
        commandId: identifier(item.commandId, "proposal command id"),
        commandFingerprint: sha(
          item.commandFingerprint,
          "proposal command fingerprint",
        ),
      });
      pending = normalized;
      previousOccurredAt = occurredAt;
      return normalized;
    }

    exactPlainRecord(item, DECISION_EVENT_KEYS, "policy governance decision");
    const occurredAt = timestamp(item.occurredAt, "decision occurredAt");
    const normalizedDecision = decision(item.decision);
    const proposalId = identifier(item.proposalId, "decision proposal id");
    if (
      item.schemaVersion !== 1 ||
      item.aggregateVersion !== aggregateVersion ||
      item.eventId !== expectedEventId ||
      pending === undefined ||
      pending.proposalId !== proposalId ||
      (previousOccurredAt !== undefined &&
        Date.parse(occurredAt) < Date.parse(previousOccurredAt))
    ) {
      fail("invalid_input", "policy governance decision history is inconsistent.");
    }
    const checkerId = identifier(item.checkerId, "checker id");
    if (checkerId === pending.makerId) {
      fail("maker_checker_conflict", "maker cannot decide the same proposal.");
    }
    if (
      normalizedDecision === "approved" &&
      Date.parse(occurredAt) > Date.parse(pending.effectiveFrom)
    ) {
      fail("effective_time_conflict", "approval occurred after the proposal effective time.");
    }
    const normalized: PolicyGovernanceDecisionEvent = Object.freeze({
      schemaVersion: 1,
      eventKind: "decision",
      eventId: expectedEventId,
      aggregateVersion,
      proposalId,
      decision: normalizedDecision,
      reasonCode: identifier(item.reasonCode, "decision reason code"),
      explanation: explanation(item.explanation, "checker explanation"),
      checkerId,
      occurredAt,
      commandId: identifier(item.commandId, "decision command id"),
      commandFingerprint: sha(
        item.commandFingerprint,
        "decision command fingerprint",
      ),
    });
    if (normalizedDecision === "approved") lastApproved = pending;
    pending = undefined;
    previousOccurredAt = occurredAt;
    return normalized;
  });

  const receipts = value.receipts.map((item, index) => {
    exactPlainRecord(item, RECEIPT_KEYS, "policy governance receipt");
    const event = events[index];
    if (event === undefined) fail("invalid_input", "governance event is missing.");
    const requiredScope = event.eventKind === "proposal" ? MAKER_SCOPE : CHECKER_SCOPE;
    const actorId = event.eventKind === "proposal" ? event.makerId : event.checkerId;
    if (
      item.schemaVersion !== 1 ||
      item.aggregateId !== governanceId ||
      item.aggregateVersion !== event.aggregateVersion ||
      item.commandId !== event.commandId ||
      item.commandFingerprint !== event.commandFingerprint ||
      item.actorId !== actorId ||
      item.requiredScope !== requiredScope ||
      item.resultReference !== event.eventId ||
      item.resultSha256 !== sha256Text(`${event.commandFingerprint}:${event.eventId}`) ||
      item.completedAt !== event.occurredAt
    ) {
      fail("invalid_input", "policy governance receipt history is inconsistent.");
    }
    return Object.freeze({ ...item });
  });

  const auditEvents = value.auditEvents.map((item, index) => {
    exactPlainRecord(item, AUDIT_KEYS, "policy governance audit event");
    const event = events[index];
    if (event === undefined) fail("invalid_input", "governance event is missing.");
    const eventType =
      event.eventKind === "proposal"
        ? "acceptance_policy_governance_proposed"
        : "acceptance_policy_governance_decided";
    const actorId = event.eventKind === "proposal" ? event.makerId : event.checkerId;
    if (
      item.schemaVersion !== 1 ||
      item.eventId !== `policy-governance-audit:${event.aggregateVersion}` ||
      item.eventType !== eventType ||
      item.aggregateVersion !== event.aggregateVersion ||
      item.tenantId !== tenantId ||
      item.governanceId !== governanceId ||
      item.governanceEventId !== event.eventId ||
      item.proposalId !== event.proposalId ||
      item.commandId !== event.commandId ||
      item.commandFingerprint !== event.commandFingerprint ||
      item.actorId !== actorId ||
      item.occurredAt !== event.occurredAt
    ) {
      fail("invalid_input", "policy governance audit history is inconsistent.");
    }
    return Object.freeze({ ...item });
  });

  return freezeAggregate({
    schemaVersion: 1,
    tenantId,
    governanceId,
    targetKind,
    sourceSetId,
    targetSubjectId,
    version,
    events,
    receipts,
    auditEvents,
  });
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

function lastApprovedProposal(
  events: readonly PolicyGovernanceEvent[],
): PolicyGovernanceProposalEvent | undefined {
  const proposals = new Map<string, PolicyGovernanceProposalEvent>();
  let latest: PolicyGovernanceProposalEvent | undefined;
  for (const event of events) {
    if (event.eventKind === "proposal") {
      proposals.set(event.proposalId, event);
    } else if (event.decision === "approved") {
      const proposal = proposals.get(event.proposalId);
      if (proposal === undefined) {
        fail("invalid_input", "approved decision has no proposal.");
      }
      latest = proposal;
    }
  }
  return latest;
}

function commandResult(
  current: AcceptancePolicyGovernanceAggregate,
  event: PolicyGovernanceEvent,
  authorization: Exclude<
    ReturnType<typeof authorizePrivilegedCommand>,
    { readonly state: "replay" }
  >,
): PolicyGovernanceCommandResult {
  const receipts = completePrivilegedCommand({
    reservation: authorization,
    currentReceipts: current.receipts,
    newAggregateVersion: event.aggregateVersion,
    resultReference: event.eventId,
    resultSha256: sha256Text(`${event.commandFingerprint}:${event.eventId}`),
    completedAt: event.occurredAt,
  });
  const receipt = receipts.at(-1);
  if (receipt === undefined) fail("invalid_input", "governance receipt is missing.");
  const actorId = event.eventKind === "proposal" ? event.makerId : event.checkerId;
  const audit: AcceptancePolicyGovernanceAuditEvent = Object.freeze({
    schemaVersion: 1,
    eventId: `policy-governance-audit:${event.aggregateVersion}`,
    eventType:
      event.eventKind === "proposal"
        ? "acceptance_policy_governance_proposed"
        : "acceptance_policy_governance_decided",
    aggregateVersion: event.aggregateVersion,
    tenantId: current.tenantId,
    governanceId: current.governanceId,
    governanceEventId: event.eventId,
    proposalId: event.proposalId,
    commandId: event.commandId,
    commandFingerprint: event.commandFingerprint,
    actorId,
    occurredAt: event.occurredAt,
  });
  const aggregate = freezeAggregate({
    ...current,
    version: event.aggregateVersion,
    events: [...current.events, event],
    receipts,
    auditEvents: [...current.auditEvents, audit],
  });
  return Object.freeze({ aggregate, event, receipt, replayed: false });
}

export function createAcceptancePolicyGovernance(request: {
  readonly tenantId: string;
  readonly governanceId: string;
  readonly targetKind: AcceptancePolicyRevisionReference["kind"];
  readonly sourceSetId: string;
  readonly targetSubjectId: string;
}): AcceptancePolicyGovernanceAggregate {
  if (request.targetKind !== "global_policy" && request.targetKind !== "schedule_override") {
    fail("invalid_input", "governance target kind is unsupported.");
  }
  return freezeAggregate({
    schemaVersion: 1,
    tenantId: identifier(request.tenantId, "tenant id"),
    governanceId: identifier(request.governanceId, "governance id"),
    targetKind: request.targetKind,
    sourceSetId: identifier(request.sourceSetId, "source set id"),
    targetSubjectId: identifier(request.targetSubjectId, "target subject id"),
    version: 1,
    events: [],
    receipts: [],
    auditEvents: [],
  });
}

export function proposeAcceptancePolicyGovernance(
  request: ProposePolicyGovernanceRequest,
): PolicyGovernanceCommandResult {
  const authorization = authorizePrivilegedCommand({
    tenantId: request.aggregate.tenantId,
    aggregateId: request.aggregate.governanceId,
    currentVersion: request.aggregate.version,
    requiredScope: MAKER_SCOPE,
    receipts: request.aggregate.receipts,
    command: request.command,
  });
  const current = normalizeAggregate(request.aggregate);
  const source = normalizeSource(request.source);
  const payload = proposePayload(request.command.payload);
  if (source.tenantId !== current.tenantId) {
    fail("tenant_mismatch", "policy source belongs to another tenant.");
  }
  if (
    payload.governanceId !== current.governanceId ||
    source.reference.kind !== current.targetKind ||
    source.reference.sourceSetId !== current.sourceSetId ||
    (source.reference.kind === "global_policy"
      ? source.reference.family !== current.targetSubjectId
      : source.reference.overrideId !== current.targetSubjectId) ||
    payload.sourceFingerprint !== source.reference.sourceFingerprint
  ) {
    fail("aggregate_mismatch", "proposal does not match its governance target.");
  }
  if (authorization.state === "replay") {
    const event = current.events.find(
      (item) => item.aggregateVersion === authorization.receipt.aggregateVersion,
    );
    if (event === undefined) fail("invalid_input", "replay has no governance event.");
    return Object.freeze({
      aggregate: current,
      event,
      receipt: authorization.receipt,
      replayed: true,
    });
  }
  if (current.events.at(-1)?.eventKind === "proposal" || current.events.length >= MAX_HISTORY) {
    fail("invalid_state", "a policy proposal is already pending or history is full.");
  }
  if (
    Date.parse(payload.effectiveFrom) < Date.parse(authorization.occurredAt) ||
    Date.parse(payload.effectiveFrom) < Date.parse(source.reference.effectiveFrom)
  ) {
    fail("effective_time_conflict", "proposal cannot be retroactive to approval or source truth.");
  }
  const approved = lastApprovedProposal(current.events);
  if (
    (approved === undefined && payload.action !== "approve_revision") ||
    (approved !== undefined &&
      Date.parse(payload.effectiveFrom) <= Date.parse(approved.effectiveFrom)) ||
    (approved !== undefined &&
      payload.action === "approve_revision" &&
      source.reference.aggregateVersion <= approved.source.aggregateVersion) ||
    (approved !== undefined &&
      payload.action === "rollback_to_revision" &&
      source.reference.aggregateVersion >= approved.source.aggregateVersion)
  ) {
    fail("invalid_state", "proposal direction does not match approved policy lineage.");
  }
  const aggregateVersion = current.version + 1;
  const event: PolicyGovernanceProposalEvent = Object.freeze({
    schemaVersion: 1,
    eventKind: "proposal",
    eventId: `policy-governance-event:${aggregateVersion}`,
    aggregateVersion,
    proposalId: `policy-governance-proposal:${aggregateVersion}`,
    action: payload.action,
    source: source.reference,
    effectiveFrom: payload.effectiveFrom,
    reasonCode: payload.reasonCode,
    explanation: payload.explanation,
    makerId: authorization.actorId,
    occurredAt: authorization.occurredAt,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
  });
  return commandResult(current, event, authorization);
}

function authorizeGovernanceRead(request: {
  readonly actor: PrivilegedCommandActor;
  readonly tenantId: string;
  readonly governanceId: string;
  readonly aggregate: AcceptancePolicyGovernanceAggregate;
}): AcceptancePolicyGovernanceAggregate {
  const actor = readActor(request.actor);
  if (!actor.scopes.includes(MAKER_SCOPE) && !actor.scopes.includes(CHECKER_SCOPE)) {
    fail("unauthorized", "actor lacks policy governance inspection authority.");
  }
  const tenantId = identifier(request.tenantId, "tenant id");
  const governanceId = identifier(request.governanceId, "governance id");
  if (actor.tenantId !== tenantId || request.aggregate.tenantId !== tenantId) {
    fail("tenant_mismatch", "policy governance is unavailable for this tenant.");
  }
  if (request.aggregate.governanceId !== governanceId) {
    fail("aggregate_mismatch", "requested policy governance is unavailable.");
  }
  return normalizeAggregate(request.aggregate);
}

export function inspectAcceptancePolicyGovernance(request: {
  readonly aggregate: AcceptancePolicyGovernanceAggregate;
  readonly tenantId: string;
  readonly governanceId: string;
  readonly actor: PrivilegedCommandActor;
}): AcceptancePolicyGovernanceAggregate {
  return authorizeGovernanceRead(request);
}

export function inspectAcceptancePolicyGovernanceSource(request: {
  readonly source: AcceptancePolicyGovernanceSource;
  readonly tenantId: string;
  readonly actor: PrivilegedCommandActor;
}): AcceptancePolicyRevisionReference {
  const actor = readActor(request.actor);
  if (!actor.scopes.includes(MAKER_SCOPE) && !actor.scopes.includes(CHECKER_SCOPE)) {
    fail("unauthorized", "actor lacks policy source inspection authority.");
  }
  const tenantId = identifier(request.tenantId, "tenant id");
  if (actor.tenantId !== tenantId) {
    fail("tenant_mismatch", "policy source is unavailable for this tenant.");
  }
  const source = normalizeSource(request.source);
  if (source.tenantId !== tenantId) {
    fail("tenant_mismatch", "policy source belongs to another tenant.");
  }
  return source.reference;
}

export function effectiveAcceptancePolicyGovernanceAt(request: {
  readonly aggregate: AcceptancePolicyGovernanceAggregate;
  readonly tenantId: string;
  readonly governanceId: string;
  readonly actor: PrivilegedCommandActor;
  readonly at: string;
}): EffectiveAcceptancePolicyGovernance {
  const aggregate = authorizeGovernanceRead(request);
  const at = timestamp(request.at, "governance projection timestamp");
  const proposals = new Map<string, PolicyGovernanceProposalEvent>();
  let effective:
    | Readonly<{
        proposal: PolicyGovernanceProposalEvent;
        decision: PolicyGovernanceDecisionEvent;
      }>
    | undefined;
  for (const event of aggregate.events) {
    if (event.eventKind === "proposal") {
      proposals.set(event.proposalId, event);
      continue;
    }
    if (event.decision !== "approved") continue;
    const proposal = proposals.get(event.proposalId);
    if (proposal === undefined) fail("invalid_input", "approved decision has no proposal.");
    if (Date.parse(proposal.effectiveFrom) <= Date.parse(at)) {
      effective = Object.freeze({ proposal, decision: event });
    }
  }
  if (effective === undefined) return Object.freeze({ state: "unknown" });
  return Object.freeze({
    state: "approved",
    action: effective.proposal.action,
    source: effective.proposal.source,
    proposalId: effective.proposal.proposalId,
    decisionEventId: effective.decision.eventId,
    effectiveFrom: effective.proposal.effectiveFrom,
    makerExplanation: effective.proposal.explanation,
    checkerExplanation: effective.decision.explanation,
  });
}

export function decideAcceptancePolicyGovernance(
  request: DecidePolicyGovernanceRequest,
): PolicyGovernanceCommandResult {
  const authorization = authorizePrivilegedCommand({
    tenantId: request.aggregate.tenantId,
    aggregateId: request.aggregate.governanceId,
    currentVersion: request.aggregate.version,
    requiredScope: CHECKER_SCOPE,
    receipts: request.aggregate.receipts,
    command: request.command,
  });
  const current = normalizeAggregate(request.aggregate);
  const payload = decidePayload(request.command.payload);
  if (payload.governanceId !== current.governanceId) {
    fail("aggregate_mismatch", "decision does not match its governance aggregate.");
  }
  if (authorization.state === "replay") {
    const event = current.events.find(
      (item) => item.aggregateVersion === authorization.receipt.aggregateVersion,
    );
    if (event === undefined) fail("invalid_input", "replay has no governance event.");
    return Object.freeze({
      aggregate: current,
      event,
      receipt: authorization.receipt,
      replayed: true,
    });
  }
  const pending = current.events.at(-1);
  if (
    pending?.eventKind !== "proposal" ||
    pending.proposalId !== payload.proposalId ||
    current.events.length >= MAX_HISTORY
  ) {
    fail("invalid_state", "decision has no matching pending proposal.");
  }
  if (pending.makerId === authorization.actorId) {
    fail("maker_checker_conflict", "maker cannot decide the same proposal.");
  }
  if (
    payload.decision === "approved" &&
    Date.parse(authorization.occurredAt) > Date.parse(pending.effectiveFrom)
  ) {
    fail("effective_time_conflict", "approval occurred after the proposed effective time.");
  }
  const aggregateVersion = current.version + 1;
  const event: PolicyGovernanceDecisionEvent = Object.freeze({
    schemaVersion: 1,
    eventKind: "decision",
    eventId: `policy-governance-event:${aggregateVersion}`,
    aggregateVersion,
    proposalId: pending.proposalId,
    decision: payload.decision,
    reasonCode: payload.reasonCode,
    explanation: payload.explanation,
    checkerId: authorization.actorId,
    occurredAt: authorization.occurredAt,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
  });
  return commandResult(current, event, authorization);
}
