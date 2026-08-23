import { createHash } from "node:crypto";

import {
  buyAcceptanceSlaFamilies,
  deriveAcceptanceSlaTimeline,
  type AcceptanceSlaPolicyRevision,
  type AcceptanceSlaTimelineValues,
  type BuyAcceptanceSlaFamily,
} from "./acceptance_sla_policy_contract.js";
import type { AcceptanceSlaScheduleOverrideRevision } from "./acceptance_sla_schedule_override_contract.js";
import {
  authorizePrivilegedCommand,
  completePrivilegedCommand,
  type JsonValue,
  type PrivilegedCommandActor,
  type PrivilegedCommandEnvelope,
  type PrivilegedCommandReceipt,
} from "../workspace/privileged_command_contract.js";

export type OrderTimerPolicySnapshotErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "aggregate_mismatch"
  | "unsupported_family"
  | "source_mismatch"
  | "source_not_effective"
  | "timing_conflict"
  | "invalid_state";

export class OrderTimerPolicySnapshotError extends Error {
  constructor(
    readonly code: OrderTimerPolicySnapshotErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "OrderTimerPolicySnapshotError";
  }
}

export interface OrderTimerPolicySnapshotCommandPayload
  extends Readonly<Record<string, JsonValue>> {
  readonly orderId: string;
  readonly family: BuyAcceptanceSlaFamily;
  readonly assignmentStartsAt: string;
  readonly sourceKind: "global" | "override";
  readonly policySetId: string;
  readonly globalRevisionId: string;
  readonly globalAggregateVersion: number;
  readonly globalCommandFingerprint: string;
  readonly overrideSetId: string | null;
  readonly overrideRevisionId: string | null;
  readonly overrideAggregateVersion: number | null;
  readonly overrideSelectorFingerprint: string | null;
  readonly overrideCommandFingerprint: string | null;
}

export type CreateOrderTimerPolicySnapshotCommand = Omit<
  PrivilegedCommandEnvelope,
  "payload"
> & {
  readonly payload: OrderTimerPolicySnapshotCommandPayload;
};

export type ResolvedOrderTimerPolicySource =
  | Readonly<{
      kind: "global";
      policySetId: string;
      policyRevision: AcceptanceSlaPolicyRevision;
    }>
  | Readonly<{
      kind: "override";
      policySetId: string;
      policyRevision: AcceptanceSlaPolicyRevision;
      overrideSetId: string;
      overrideRevision: AcceptanceSlaScheduleOverrideRevision;
    }>;

export type OrderTimerPolicyProvenance =
  | Readonly<{
      kind: "global";
      policySetId: string;
      globalRevisionId: string;
      globalAggregateVersion: number;
      globalCommandFingerprint: string;
    }>
  | Readonly<{
      kind: "override";
      policySetId: string;
      globalRevisionId: string;
      globalAggregateVersion: number;
      globalCommandFingerprint: string;
      overrideSetId: string;
      overrideRevisionId: string;
      overrideAggregateVersion: number;
      overrideSelectorFingerprint: string;
      overrideCommandFingerprint: string;
    }>;

export interface OrderTimerAttemptSchedule {
  readonly attemptNumber: number;
  readonly startsAt: string;
  readonly moolChatAt: string;
  readonly whatsAppAt: string;
  readonly agenticCallAt: string;
  readonly expiresAt: string;
  readonly reassignAt: string | null;
}

export interface OrderTimerPolicySnapshot extends AcceptanceSlaTimelineValues {
  readonly schemaVersion: 1;
  readonly snapshotId: string;
  readonly aggregateVersion: number;
  readonly tenantId: string;
  readonly orderId: string;
  readonly family: BuyAcceptanceSlaFamily;
  readonly provenance: OrderTimerPolicyProvenance;
  readonly assignmentStartsAt: string;
  readonly overallAssignmentEndsAt: string;
  readonly moolChatOffsetSeconds: 0;
  readonly reassignAtSeconds: number;
  readonly attempts: readonly OrderTimerAttemptSchedule[];
  readonly createdAt: string;
  readonly createdBy: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
}

export interface OrderTimerPolicySnapshotAuditEvent {
  readonly schemaVersion: 1;
  readonly eventId: string;
  readonly eventType: "order_timer_policy_snapshotted";
  readonly aggregateVersion: number;
  readonly tenantId: string;
  readonly orderId: string;
  readonly snapshotId: string;
  readonly family: BuyAcceptanceSlaFamily;
  readonly sourceKind: "global" | "override";
  readonly sourceRevisionFingerprint: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
  readonly occurredAt: string;
}

export interface OrderTimerPolicySnapshotAggregate {
  readonly schemaVersion: 1;
  readonly tenantId: string;
  readonly orderId: string;
  readonly version: number;
  readonly snapshot: OrderTimerPolicySnapshot | null;
  readonly receipts: readonly PrivilegedCommandReceipt[];
  readonly auditEvents: readonly OrderTimerPolicySnapshotAuditEvent[];
}

export interface CreateOrderTimerPolicySnapshotRequest {
  readonly aggregate: OrderTimerPolicySnapshotAggregate;
  readonly source: ResolvedOrderTimerPolicySource;
  readonly command: CreateOrderTimerPolicySnapshotCommand;
}

export interface CreateOrderTimerPolicySnapshotResult {
  readonly aggregate: OrderTimerPolicySnapshotAggregate;
  readonly snapshot: OrderTimerPolicySnapshot;
  readonly receipt: PrivilegedCommandReceipt;
  readonly replayed: boolean;
}

export type OrderTimerProgress =
  | Readonly<{
      state: "before_start";
      snapshotId: string;
      startsAt: string;
    }>
  | Readonly<{
      state: "attempt_active";
      snapshotId: string;
      attemptNumber: number;
      phase: "moolchat_only" | "whatsapp_escalated" | "agentic_call_escalated";
      attemptStartsAt: string;
      attemptExpiresAt: string;
      remainingSeconds: number;
    }>
  | Readonly<{
      state: "assignment_ceiling_reached";
      snapshotId: string;
      endedAt: string;
    }>;

export interface ProjectOrderTimerProgressRequest {
  readonly aggregate: OrderTimerPolicySnapshotAggregate;
  readonly tenantId: string;
  readonly orderId: string;
  readonly actor: PrivilegedCommandActor;
  readonly at: string;
}

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-F0-9]{64}$/u;
const ORCHESTRATOR_SCOPE = "commerce.order_assignment.timer_snapshot";
const PAYLOAD_KEYS = [
  "assignmentStartsAt",
  "family",
  "globalAggregateVersion",
  "globalCommandFingerprint",
  "globalRevisionId",
  "orderId",
  "overrideAggregateVersion",
  "overrideCommandFingerprint",
  "overrideRevisionId",
  "overrideSelectorFingerprint",
  "overrideSetId",
  "policySetId",
  "sourceKind",
] as const;

function fail(code: OrderTimerPolicySnapshotErrorCode, message: string): never {
  throw new OrderTimerPolicySnapshotError(code, message);
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
    fail("unsupported_family", "order timer family is unsupported.");
  }
  return value as BuyAcceptanceSlaFamily;
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

function addSeconds(value: string, seconds: number): string {
  return new Date(Date.parse(value) + seconds * 1000).toISOString();
}

function freezeAttempt(value: OrderTimerAttemptSchedule): OrderTimerAttemptSchedule {
  return Object.freeze({ ...value });
}

function freezeProvenance(value: OrderTimerPolicyProvenance): OrderTimerPolicyProvenance {
  return Object.freeze({ ...value });
}

function normalizeProvenance(value: OrderTimerPolicyProvenance): OrderTimerPolicyProvenance {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    fail("invalid_input", "stored snapshot provenance must be a record.");
  }
  const common = {
    policySetId: identifier(value.policySetId, "stored policy set id"),
    globalRevisionId: identifier(
      value.globalRevisionId,
      "stored global revision id",
    ),
    globalAggregateVersion: positiveVersion(
      value.globalAggregateVersion,
      "stored global aggregate version",
    ),
    globalCommandFingerprint: sha(
      value.globalCommandFingerprint,
      "stored global command fingerprint",
    ),
  };
  if (value.kind === "global") {
    const keys = Object.keys(value).sort();
    const expected = [
      "globalAggregateVersion",
      "globalCommandFingerprint",
      "globalRevisionId",
      "kind",
      "policySetId",
    ];
    if (JSON.stringify(keys) !== JSON.stringify(expected)) {
      fail("invalid_input", "stored global provenance fields are not exact.");
    }
    return freezeProvenance({ kind: "global", ...common });
  }
  if (value.kind === "override") {
    const keys = Object.keys(value).sort();
    const expected = [
      "globalAggregateVersion",
      "globalCommandFingerprint",
      "globalRevisionId",
      "kind",
      "overrideAggregateVersion",
      "overrideCommandFingerprint",
      "overrideRevisionId",
      "overrideSelectorFingerprint",
      "overrideSetId",
      "policySetId",
    ];
    if (JSON.stringify(keys) !== JSON.stringify(expected)) {
      fail("invalid_input", "stored override provenance fields are not exact.");
    }
    return freezeProvenance({
      kind: "override",
      ...common,
      overrideSetId: identifier(value.overrideSetId, "stored override set id"),
      overrideRevisionId: identifier(
        value.overrideRevisionId,
        "stored override revision id",
      ),
      overrideAggregateVersion: positiveVersion(
        value.overrideAggregateVersion,
        "stored override aggregate version",
      ),
      overrideSelectorFingerprint: sha(
        value.overrideSelectorFingerprint,
        "stored override selector fingerprint",
      ),
      overrideCommandFingerprint: sha(
        value.overrideCommandFingerprint,
        "stored override command fingerprint",
      ),
    });
  }
  return fail("invalid_input", "stored snapshot provenance is unsupported.");
}

function freezeSnapshot(value: OrderTimerPolicySnapshot): OrderTimerPolicySnapshot {
  return Object.freeze({
    ...value,
    provenance: freezeProvenance(value.provenance),
    attempts: Object.freeze(value.attempts.map(freezeAttempt)),
  });
}

function freezeAggregate(
  value: OrderTimerPolicySnapshotAggregate,
): OrderTimerPolicySnapshotAggregate {
  return Object.freeze({
    ...value,
    snapshot: value.snapshot === null ? null : freezeSnapshot(value.snapshot),
    receipts: Object.freeze(value.receipts.map((item) => Object.freeze({ ...item }))),
    auditEvents: Object.freeze(
      value.auditEvents.map((item) => Object.freeze({ ...item })),
    ),
  });
}

interface NormalizedSource {
  readonly family: BuyAcceptanceSlaFamily;
  readonly provenance: OrderTimerPolicyProvenance;
  readonly timeline: AcceptanceSlaTimelineValues;
  readonly effectiveFrom: string;
  readonly sourceRevisionFingerprint: string;
}

function timelineFromRevision(
  value: AcceptanceSlaPolicyRevision | AcceptanceSlaScheduleOverrideRevision,
): AcceptanceSlaTimelineValues {
  const timeline = deriveAcceptanceSlaTimeline(
    value.responseWindowSeconds,
    value.maximumSequentialPartners,
    value.overallAssignmentCeilingSeconds,
  );
  if (
    value.moolChatOffsetSeconds !== 0 ||
    value.whatsAppOffsetSeconds !== timeline.whatsAppOffsetSeconds ||
    value.agenticCallOffsetSeconds !== timeline.agenticCallOffsetSeconds ||
    value.reassignAtSeconds !== timeline.responseWindowSeconds
  ) {
    fail("source_mismatch", "resolved policy source has invalid escalation facts.");
  }
  return Object.freeze(timeline);
}

function normalizeSource(value: ResolvedOrderTimerPolicySource): NormalizedSource {
  const policySetId = identifier(value.policySetId, "policy set id");
  const globalRevision = value.policyRevision;
  if (globalRevision.schemaVersion !== 1) {
    fail("source_mismatch", "global policy revision schema is unsupported.");
  }
  const globalFamily = family(globalRevision.family);
  const globalRevisionId = identifier(globalRevision.revisionId, "global revision id");
  const globalAggregateVersion = positiveVersion(
    globalRevision.aggregateVersion,
    "global aggregate version",
  );
  const globalCommandFingerprint = sha(
    globalRevision.commandFingerprint,
    "global command fingerprint",
  );
  const globalEffectiveFrom = timestamp(
    globalRevision.effectiveFrom,
    "global effectiveFrom",
  );
  const globalTimeline = timelineFromRevision(globalRevision);
  if (value.kind === "global") {
    return Object.freeze({
      family: globalFamily,
      provenance: freezeProvenance({
        kind: "global",
        policySetId,
        globalRevisionId,
        globalAggregateVersion,
        globalCommandFingerprint,
      }),
      timeline: globalTimeline,
      effectiveFrom: globalEffectiveFrom,
      sourceRevisionFingerprint: globalCommandFingerprint,
    });
  }
  const override = value.overrideRevision;
  if (override.schemaVersion !== 1 || override.state !== "enabled") {
    fail("source_mismatch", "override source must be one enabled revision.");
  }
  const overrideFamily = family(override.selector.family);
  if (overrideFamily !== globalFamily) {
    fail("source_mismatch", "global and override source families do not match.");
  }
  const overrideSelectorFingerprint = sha(
    override.selectorFingerprint,
    "override selector fingerprint",
  );
  const overrideCommandFingerprint = sha(
    override.commandFingerprint,
    "override command fingerprint",
  );
  return Object.freeze({
    family: overrideFamily,
    provenance: freezeProvenance({
      kind: "override",
      policySetId,
      globalRevisionId,
      globalAggregateVersion,
      globalCommandFingerprint,
      overrideSetId: identifier(value.overrideSetId, "override set id"),
      overrideRevisionId: identifier(override.revisionId, "override revision id"),
      overrideAggregateVersion: positiveVersion(
        override.aggregateVersion,
        "override aggregate version",
      ),
      overrideSelectorFingerprint,
      overrideCommandFingerprint,
    }),
    timeline: timelineFromRevision(override),
    effectiveFrom: new Date(
      Math.max(
        Date.parse(globalEffectiveFrom),
        Date.parse(timestamp(override.effectiveFrom, "override effectiveFrom")),
      ),
    ).toISOString(),
    sourceRevisionFingerprint: overrideCommandFingerprint,
  });
}

interface NormalizedPayload {
  readonly orderId: string;
  readonly family: BuyAcceptanceSlaFamily;
  readonly assignmentStartsAt: string;
  readonly provenance: OrderTimerPolicyProvenance;
}

function payload(value: unknown): NormalizedPayload {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    (Object.getPrototypeOf(value) !== Object.prototype &&
      Object.getPrototypeOf(value) !== null)
  ) {
    fail("invalid_input", "order timer snapshot payload must be a plain record.");
  }
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record).sort();
  if (
    keys.length !== PAYLOAD_KEYS.length ||
    keys.some((key, index) => key !== PAYLOAD_KEYS[index])
  ) {
    fail("invalid_input", "order timer snapshot payload fields are not exact.");
  }
  const sourceKind = record.sourceKind;
  const base = {
    policySetId:
      typeof record.policySetId === "string"
        ? identifier(record.policySetId, "payload policy set id")
        : fail("invalid_input", "payload policy set id is invalid."),
    globalRevisionId:
      typeof record.globalRevisionId === "string"
        ? identifier(record.globalRevisionId, "payload global revision id")
        : fail("invalid_input", "payload global revision id is invalid."),
    globalAggregateVersion:
      typeof record.globalAggregateVersion === "number"
        ? positiveVersion(record.globalAggregateVersion, "payload global version")
        : fail("invalid_input", "payload global version is invalid."),
    globalCommandFingerprint:
      typeof record.globalCommandFingerprint === "string"
        ? sha(record.globalCommandFingerprint, "payload global fingerprint")
        : fail("invalid_input", "payload global fingerprint is invalid."),
  };
  let provenance: OrderTimerPolicyProvenance;
  if (sourceKind === "global") {
    if (
      record.overrideSetId !== null ||
      record.overrideRevisionId !== null ||
      record.overrideAggregateVersion !== null ||
      record.overrideSelectorFingerprint !== null ||
      record.overrideCommandFingerprint !== null
    ) {
      fail("source_mismatch", "global snapshot payload cannot mix override provenance.");
    }
    provenance = freezeProvenance({ kind: "global", ...base });
  } else if (sourceKind === "override") {
    if (
      typeof record.overrideSetId !== "string" ||
      typeof record.overrideRevisionId !== "string" ||
      typeof record.overrideAggregateVersion !== "number" ||
      typeof record.overrideSelectorFingerprint !== "string" ||
      typeof record.overrideCommandFingerprint !== "string"
    ) {
      fail("source_mismatch", "override snapshot payload requires exact provenance.");
    }
    provenance = freezeProvenance({
      kind: "override",
      ...base,
      overrideSetId: identifier(record.overrideSetId, "payload override set id"),
      overrideRevisionId: identifier(
        record.overrideRevisionId,
        "payload override revision id",
      ),
      overrideAggregateVersion: positiveVersion(
        record.overrideAggregateVersion,
        "payload override version",
      ),
      overrideSelectorFingerprint: sha(
        record.overrideSelectorFingerprint,
        "payload override selector fingerprint",
      ),
      overrideCommandFingerprint: sha(
        record.overrideCommandFingerprint,
        "payload override command fingerprint",
      ),
    });
  } else {
    fail("source_mismatch", "snapshot source kind is unsupported.");
  }
  return Object.freeze({
    orderId:
      typeof record.orderId === "string"
        ? identifier(record.orderId, "payload order id")
        : fail("invalid_input", "payload order id is invalid."),
    family: family(record.family),
    assignmentStartsAt:
      typeof record.assignmentStartsAt === "string"
        ? timestamp(record.assignmentStartsAt, "assignmentStartsAt")
        : fail("invalid_input", "assignmentStartsAt is invalid."),
    provenance,
  });
}

function sameProvenance(
  left: OrderTimerPolicyProvenance,
  right: OrderTimerPolicyProvenance,
): boolean {
  return JSON.stringify(left) === JSON.stringify(right);
}

function attemptSchedules(
  assignmentStartsAt: string,
  timeline: AcceptanceSlaTimelineValues,
): readonly OrderTimerAttemptSchedule[] {
  const result: OrderTimerAttemptSchedule[] = [];
  for (
    let attemptNumber = 1;
    attemptNumber <= timeline.maximumSequentialPartners;
    attemptNumber += 1
  ) {
    const startsAt = addSeconds(
      assignmentStartsAt,
      (attemptNumber - 1) * timeline.responseWindowSeconds,
    );
    const expiresAt = addSeconds(startsAt, timeline.responseWindowSeconds);
    result.push(
      freezeAttempt({
        attemptNumber,
        startsAt,
        moolChatAt: startsAt,
        whatsAppAt: addSeconds(startsAt, timeline.whatsAppOffsetSeconds),
        agenticCallAt: addSeconds(startsAt, timeline.agenticCallOffsetSeconds),
        expiresAt,
        reassignAt:
          attemptNumber === timeline.maximumSequentialPartners ? null : expiresAt,
      }),
    );
  }
  return Object.freeze(result);
}

function normalizeSnapshot(value: OrderTimerPolicySnapshot): OrderTimerPolicySnapshot {
  if (value.schemaVersion !== 1 || value.aggregateVersion !== 2) {
    fail("invalid_input", "order timer snapshot identity is invalid.");
  }
  const timeline = deriveAcceptanceSlaTimeline(
    value.responseWindowSeconds,
    value.maximumSequentialPartners,
    value.overallAssignmentCeilingSeconds,
  );
  if (
    value.moolChatOffsetSeconds !== 0 ||
    value.whatsAppOffsetSeconds !== timeline.whatsAppOffsetSeconds ||
    value.agenticCallOffsetSeconds !== timeline.agenticCallOffsetSeconds ||
    value.reassignAtSeconds !== timeline.responseWindowSeconds
  ) {
    fail("invalid_input", "stored order timer escalation facts are invalid.");
  }
  const assignmentStartsAt = timestamp(
    value.assignmentStartsAt,
    "stored assignmentStartsAt",
  );
  const expectedAttempts = attemptSchedules(assignmentStartsAt, timeline);
  if (JSON.stringify(value.attempts) !== JSON.stringify(expectedAttempts)) {
    fail("invalid_input", "stored order timer attempt schedule is invalid.");
  }
  const overallAssignmentEndsAt = addSeconds(
    assignmentStartsAt,
    timeline.overallAssignmentCeilingSeconds,
  );
  if (value.overallAssignmentEndsAt !== overallAssignmentEndsAt) {
    fail("invalid_input", "stored order timer ceiling instant is invalid.");
  }
  const createdAt = timestamp(value.createdAt, "snapshot createdAt");
  if (Date.parse(createdAt) > Date.parse(assignmentStartsAt)) {
    fail("invalid_input", "stored snapshot was created after assignment began.");
  }
  const provenance = normalizeProvenance(value.provenance);
  return freezeSnapshot({
    ...value,
    snapshotId: identifier(value.snapshotId, "snapshot id"),
    tenantId: identifier(value.tenantId, "snapshot tenant id"),
    orderId: identifier(value.orderId, "snapshot order id"),
    family: family(value.family),
    provenance,
    ...timeline,
    moolChatOffsetSeconds: 0,
    reassignAtSeconds: timeline.responseWindowSeconds,
    assignmentStartsAt,
    overallAssignmentEndsAt,
    attempts: expectedAttempts,
    createdAt,
    createdBy: identifier(value.createdBy, "snapshot actor id"),
    commandId: identifier(value.commandId, "snapshot command id"),
    commandFingerprint: sha(value.commandFingerprint, "snapshot command fingerprint"),
  });
}

function normalizeAggregate(
  value: OrderTimerPolicySnapshotAggregate,
): OrderTimerPolicySnapshotAggregate {
  if (value.schemaVersion !== 1 || (value.version !== 1 && value.version !== 2)) {
    fail("invalid_input", "order timer aggregate identity is invalid.");
  }
  const tenantId = identifier(value.tenantId, "tenant id");
  const orderId = identifier(value.orderId, "order id");
  if (
    (value.version === 1 &&
      (value.snapshot !== null || value.receipts.length !== 0 || value.auditEvents.length !== 0)) ||
    (value.version === 2 &&
      (value.snapshot === null || value.receipts.length !== 1 || value.auditEvents.length !== 1))
  ) {
    fail("invalid_input", "order timer aggregate state is inconsistent.");
  }
  if (value.version === 1) {
    return freezeAggregate({
      schemaVersion: 1,
      tenantId,
      orderId,
      version: 1,
      snapshot: null,
      receipts: [],
      auditEvents: [],
    });
  }
  const snapshot = normalizeSnapshot(value.snapshot as OrderTimerPolicySnapshot);
  const receipt = value.receipts[0];
  const audit = value.auditEvents[0];
  if (
    snapshot.tenantId !== tenantId ||
    snapshot.orderId !== orderId ||
    receipt === undefined ||
    receipt.schemaVersion !== 1 ||
    receipt.aggregateId !== orderId ||
    receipt.aggregateVersion !== 2 ||
    receipt.commandId !== snapshot.commandId ||
    receipt.commandFingerprint !== snapshot.commandFingerprint ||
    receipt.actorId !== snapshot.createdBy ||
    receipt.requiredScope !== ORCHESTRATOR_SCOPE ||
    receipt.resultReference !== snapshot.snapshotId ||
    receipt.resultSha256 !==
      sha256Text(`${snapshot.commandFingerprint}:${snapshot.snapshotId}`) ||
    receipt.completedAt !== snapshot.createdAt ||
    audit === undefined ||
    audit.schemaVersion !== 1 ||
    audit.eventType !== "order_timer_policy_snapshotted" ||
    audit.aggregateVersion !== 2 ||
    audit.tenantId !== tenantId ||
    audit.orderId !== orderId ||
    audit.snapshotId !== snapshot.snapshotId ||
    audit.family !== snapshot.family ||
    audit.sourceKind !== snapshot.provenance.kind ||
    audit.sourceRevisionFingerprint !==
      (snapshot.provenance.kind === "global"
        ? snapshot.provenance.globalCommandFingerprint
        : snapshot.provenance.overrideCommandFingerprint) ||
    !SHA256_PATTERN.test(audit.sourceRevisionFingerprint) ||
    audit.commandId !== snapshot.commandId ||
    audit.commandFingerprint !== snapshot.commandFingerprint ||
    audit.actorId !== snapshot.createdBy ||
    audit.occurredAt !== snapshot.createdAt
  ) {
    fail("invalid_input", "order timer evidence history is inconsistent.");
  }
  return freezeAggregate({
    schemaVersion: 1,
    tenantId,
    orderId,
    version: 2,
    snapshot,
    receipts: [Object.freeze({ ...receipt })],
    auditEvents: [
      Object.freeze({
        ...audit,
        eventId: identifier(audit.eventId, "snapshot audit event id"),
      }),
    ],
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

export function createPendingOrderTimerPolicySnapshotAggregate(request: {
  readonly tenantId: string;
  readonly orderId: string;
}): OrderTimerPolicySnapshotAggregate {
  return freezeAggregate({
    schemaVersion: 1,
    tenantId: identifier(request.tenantId, "tenant id"),
    orderId: identifier(request.orderId, "order id"),
    version: 1,
    snapshot: null,
    receipts: [],
    auditEvents: [],
  });
}

export function createOrderTimerPolicySnapshot(
  request: CreateOrderTimerPolicySnapshotRequest,
): CreateOrderTimerPolicySnapshotResult {
  const authorization = authorizePrivilegedCommand({
    tenantId: request.aggregate.tenantId,
    aggregateId: request.aggregate.orderId,
    currentVersion: request.aggregate.version,
    requiredScope: ORCHESTRATOR_SCOPE,
    receipts: request.aggregate.receipts,
    command: request.command,
  });
  const current = normalizeAggregate(request.aggregate);
  if (authorization.state === "replay") {
    if (current.snapshot === null) {
      fail("invalid_input", "snapshot receipt has no matching snapshot.");
    }
    return Object.freeze({
      aggregate: current,
      snapshot: current.snapshot,
      receipt: authorization.receipt,
      replayed: true,
    });
  }
  if (current.snapshot !== null) {
    fail("invalid_state", "order timer policy is already snapshotted.");
  }
  const commandPayload = payload(request.command.payload);
  const source = normalizeSource(request.source);
  if (
    commandPayload.orderId !== current.orderId ||
    commandPayload.family !== source.family ||
    !sameProvenance(commandPayload.provenance, source.provenance)
  ) {
    fail("source_mismatch", "snapshot command does not match its resolved policy source.");
  }
  if (Date.parse(source.effectiveFrom) > Date.parse(commandPayload.assignmentStartsAt)) {
    fail("source_not_effective", "resolved policy is not effective when assignment starts.");
  }
  if (Date.parse(commandPayload.assignmentStartsAt) < Date.parse(authorization.occurredAt)) {
    fail("timing_conflict", "assignment start cannot predate snapshot creation.");
  }
  const attempts = attemptSchedules(commandPayload.assignmentStartsAt, source.timeline);
  const aggregateVersion = 2;
  const snapshotId = "order-timer-snapshot:2";
  const snapshot = freezeSnapshot({
    schemaVersion: 1,
    snapshotId,
    aggregateVersion,
    tenantId: current.tenantId,
    orderId: current.orderId,
    family: source.family,
    provenance: source.provenance,
    ...source.timeline,
    moolChatOffsetSeconds: 0,
    reassignAtSeconds: source.timeline.responseWindowSeconds,
    assignmentStartsAt: commandPayload.assignmentStartsAt,
    overallAssignmentEndsAt: addSeconds(
      commandPayload.assignmentStartsAt,
      source.timeline.overallAssignmentCeilingSeconds,
    ),
    attempts,
    createdAt: authorization.occurredAt,
    createdBy: authorization.actorId,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
  });
  const resultSha256 = sha256Text(
    `${authorization.commandFingerprint}:${snapshotId}`,
  );
  const receipts = completePrivilegedCommand({
    reservation: authorization,
    currentReceipts: current.receipts,
    newAggregateVersion: aggregateVersion,
    resultReference: snapshotId,
    resultSha256,
    completedAt: authorization.occurredAt,
  });
  const receipt = receipts[0];
  if (receipt === undefined) {
    fail("invalid_input", "completed snapshot command did not produce a receipt.");
  }
  const audit = Object.freeze({
    schemaVersion: 1 as const,
    eventId: "order-timer-snapshot-event:2",
    eventType: "order_timer_policy_snapshotted" as const,
    aggregateVersion,
    tenantId: current.tenantId,
    orderId: current.orderId,
    snapshotId,
    family: source.family,
    sourceKind: source.provenance.kind,
    sourceRevisionFingerprint: source.sourceRevisionFingerprint,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
    actorId: authorization.actorId,
    occurredAt: authorization.occurredAt,
  });
  const aggregate = freezeAggregate({
    ...current,
    version: 2,
    snapshot,
    receipts,
    auditEvents: [audit],
  });
  return Object.freeze({ aggregate, snapshot, receipt, replayed: false });
}

export function projectOrderTimerProgress(
  request: ProjectOrderTimerProgressRequest,
): OrderTimerProgress {
  const actor = readActor(request.actor);
  const tenantId = identifier(request.tenantId, "tenant id");
  if (!actor.scopes.includes(ORCHESTRATOR_SCOPE)) {
    fail("unauthorized", "actor lacks order timer snapshot authority.");
  }
  if (actor.tenantId !== tenantId) {
    fail("tenant_mismatch", "actor cannot read another tenant's order timer.");
  }
  const orderId = identifier(request.orderId, "order id");
  if (request.aggregate.tenantId !== tenantId) {
    fail("tenant_mismatch", "order timer is unavailable for this tenant.");
  }
  if (request.aggregate.orderId !== orderId) {
    fail("aggregate_mismatch", "requested order timer is unavailable.");
  }
  const at = timestamp(request.at, "progress timestamp");
  const aggregate = normalizeAggregate(request.aggregate);
  const snapshot = aggregate.snapshot;
  if (snapshot === null) {
    fail("invalid_state", "order timer has not been snapshotted.");
  }
  if (Date.parse(at) < Date.parse(snapshot.assignmentStartsAt)) {
    return Object.freeze({
      state: "before_start",
      snapshotId: snapshot.snapshotId,
      startsAt: snapshot.assignmentStartsAt,
    });
  }
  if (Date.parse(at) >= Date.parse(snapshot.overallAssignmentEndsAt)) {
    return Object.freeze({
      state: "assignment_ceiling_reached",
      snapshotId: snapshot.snapshotId,
      endedAt: snapshot.overallAssignmentEndsAt,
    });
  }
  const attempt = snapshot.attempts.find(
    (item) =>
      Date.parse(at) >= Date.parse(item.startsAt) &&
      Date.parse(at) < Date.parse(item.expiresAt),
  );
  if (attempt === undefined) {
    fail("invalid_input", "order timer has no attempt for an in-ceiling instant.");
  }
  const phase =
    Date.parse(at) >= Date.parse(attempt.agenticCallAt)
      ? "agentic_call_escalated"
      : Date.parse(at) >= Date.parse(attempt.whatsAppAt)
        ? "whatsapp_escalated"
        : "moolchat_only";
  return Object.freeze({
    state: "attempt_active",
    snapshotId: snapshot.snapshotId,
    attemptNumber: attempt.attemptNumber,
    phase,
    attemptStartsAt: attempt.startsAt,
    attemptExpiresAt: attempt.expiresAt,
    remainingSeconds: Math.ceil(
      (Date.parse(attempt.expiresAt) - Date.parse(at)) / 1000,
    ),
  });
}
