import { createHash } from "node:crypto";

import {
  buyAcceptanceSlaFamilies,
  deriveAcceptanceSlaTimeline,
  type AcceptanceSlaTimelineValues,
  type BuyAcceptanceSlaFamily,
} from "./acceptance_sla_policy_contract.js";
import {
  authorizePrivilegedCommand,
  completePrivilegedCommand,
  type JsonValue,
  type PrivilegedCommandActor,
  type PrivilegedCommandEnvelope,
  type PrivilegedCommandReceipt,
} from "../workspace/privileged_command_contract.js";

export type IsoWeekday = 1 | 2 | 3 | 4 | 5 | 6 | 7;
export type AcceptanceSlaOverrideState = "enabled" | "disabled";

export type AcceptanceSlaScheduleOverrideErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "aggregate_mismatch"
  | "unsupported_family"
  | "invalid_schedule"
  | "effective_time_conflict"
  | "ambiguous_precedence";

export class AcceptanceSlaScheduleOverrideError extends Error {
  constructor(
    readonly code: AcceptanceSlaScheduleOverrideErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "AcceptanceSlaScheduleOverrideError";
  }
}

export interface AcceptanceSlaScheduleOverridePayload
  extends Readonly<Record<string, JsonValue>> {
  readonly overrideId: string;
  readonly state: AcceptanceSlaOverrideState;
  readonly family: BuyAcceptanceSlaFamily;
  readonly marketTypeId: string | null;
  readonly providerTypeId: string | null;
  readonly categoryId: string | null;
  readonly localityId: string | null;
  readonly weekdays: readonly IsoWeekday[] | null;
  readonly timeZone: string | null;
  readonly startMinuteInclusive: number | null;
  readonly endMinuteExclusive: number | null;
  readonly readinessState: "declared_busy" | null;
  readonly responseWindowSeconds: number;
  readonly maximumSequentialPartners: number;
  readonly overallAssignmentCeilingSeconds: number;
  readonly effectiveFrom: string;
  readonly reasonCode: string;
}

export type PublishAcceptanceSlaScheduleOverrideCommand = Omit<
  PrivilegedCommandEnvelope,
  "payload"
> & {
  readonly payload: AcceptanceSlaScheduleOverridePayload;
};

export interface AcceptanceSlaOverrideSelector {
  readonly family: BuyAcceptanceSlaFamily;
  readonly marketTypeId: string | null;
  readonly providerTypeId: string | null;
  readonly categoryId: string | null;
  readonly localityId: string | null;
  readonly weekdays: readonly IsoWeekday[] | null;
  readonly timeZone: string | null;
  readonly startMinuteInclusive: number | null;
  readonly endMinuteExclusive: number | null;
  readonly readinessState: "declared_busy" | null;
}

export interface AcceptanceSlaScheduleOverrideRevision
  extends AcceptanceSlaTimelineValues {
  readonly schemaVersion: 1;
  readonly revisionId: string;
  readonly aggregateVersion: number;
  readonly overrideId: string;
  readonly state: AcceptanceSlaOverrideState;
  readonly selector: AcceptanceSlaOverrideSelector;
  readonly selectorFingerprint: string;
  readonly moolChatOffsetSeconds: 0;
  readonly reassignAtSeconds: number;
  readonly effectiveFrom: string;
  readonly publishedAt: string;
  readonly reasonCode: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
}

export interface AcceptanceSlaScheduleOverrideAuditEvent {
  readonly schemaVersion: 1;
  readonly eventId: string;
  readonly eventType: "acceptance_sla_schedule_override_published";
  readonly aggregateVersion: number;
  readonly tenantId: string;
  readonly overrideSetId: string;
  readonly overrideId: string;
  readonly revisionId: string;
  readonly family: BuyAcceptanceSlaFamily;
  readonly state: AcceptanceSlaOverrideState;
  readonly selectorFingerprint: string;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly actorId: string;
  readonly occurredAt: string;
}

export interface AcceptanceSlaScheduleOverrideSet {
  readonly schemaVersion: 1;
  readonly tenantId: string;
  readonly overrideSetId: string;
  readonly version: number;
  readonly revisions: readonly AcceptanceSlaScheduleOverrideRevision[];
  readonly receipts: readonly PrivilegedCommandReceipt[];
  readonly auditEvents: readonly AcceptanceSlaScheduleOverrideAuditEvent[];
}

export interface PublishAcceptanceSlaScheduleOverrideRequest {
  readonly overrideSet: AcceptanceSlaScheduleOverrideSet;
  readonly command: PublishAcceptanceSlaScheduleOverrideCommand;
}

export interface PublishAcceptanceSlaScheduleOverrideResult {
  readonly overrideSet: AcceptanceSlaScheduleOverrideSet;
  readonly revision: AcceptanceSlaScheduleOverrideRevision;
  readonly receipt: PrivilegedCommandReceipt;
  readonly overlapWarningOverrideIds: readonly string[];
  readonly replayed: boolean;
}

export interface AcceptanceSlaScheduleOverrideContext {
  readonly family: BuyAcceptanceSlaFamily;
  readonly marketTypeId: string | null;
  readonly providerTypeId: string | null;
  readonly categoryId: string | null;
  readonly localityId: string | null;
  readonly declaredBusy: boolean;
  readonly at: string;
}

export interface ResolveAcceptanceSlaScheduleOverrideRequest {
  readonly overrideSet: AcceptanceSlaScheduleOverrideSet;
  readonly tenantId: string;
  readonly overrideSetId: string;
  readonly actor: PrivilegedCommandActor;
  readonly context: AcceptanceSlaScheduleOverrideContext;
}

export type AcceptanceSlaScheduleOverrideResolution =
  | Readonly<{ kind: "global_fallback" }>
  | Readonly<{
      kind: "override";
      revision: AcceptanceSlaScheduleOverrideRevision;
    }>;

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-F0-9]{64}$/u;
const ADMIN_SCOPE = "commerce.fulfilment_policy.admin";
const MAX_HISTORY = 499;
const PAYLOAD_KEYS = [
  "categoryId",
  "effectiveFrom",
  "endMinuteExclusive",
  "family",
  "localityId",
  "marketTypeId",
  "maximumSequentialPartners",
  "overallAssignmentCeilingSeconds",
  "overrideId",
  "providerTypeId",
  "readinessState",
  "reasonCode",
  "responseWindowSeconds",
  "startMinuteInclusive",
  "state",
  "timeZone",
  "weekdays",
] as const;

function fail(
  code: AcceptanceSlaScheduleOverrideErrorCode,
  message: string,
): never {
  throw new AcceptanceSlaScheduleOverrideError(code, message);
}

function identifier(value: string, label: string): string {
  const normalized = value.trim();
  if (!IDENTIFIER_PATTERN.test(normalized)) {
    fail("invalid_input", `${label} must be a stable identifier.`);
  }
  return normalized;
}

function nullableIdentifier(value: unknown, label: string): string | null {
  if (value === null) return null;
  return typeof value === "string"
    ? identifier(value, label)
    : fail("invalid_input", `${label} must be null or a stable identifier.`);
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
    fail("unsupported_family", "schedule override family is unsupported.");
  }
  return value as BuyAcceptanceSlaFamily;
}

function state(value: unknown): AcceptanceSlaOverrideState {
  if (value !== "enabled" && value !== "disabled") {
    fail("invalid_input", "schedule override state is unsupported.");
  }
  return value;
}

function minute(value: unknown, label: string): number {
  if (
    typeof value !== "number" ||
    !Number.isSafeInteger(value) ||
    value < 0 ||
    value > 1439
  ) {
    fail("invalid_schedule", `${label} must be a whole minute from 0 to 1439.`);
  }
  return value;
}

function canonicalTimeZone(value: unknown): string {
  if (typeof value !== "string" || value.length < 1 || value.length > 64) {
    fail("invalid_schedule", "timeZone must be a bounded IANA timezone.");
  }
  try {
    return new Intl.DateTimeFormat("en-US", { timeZone: value })
      .resolvedOptions()
      .timeZone;
  } catch {
    return fail("invalid_schedule", "timeZone must be a recognized IANA timezone.");
  }
}

function normalizedWeekdays(value: unknown): readonly IsoWeekday[] {
  if (!Array.isArray(value) || value.length < 1 || value.length > 7) {
    fail("invalid_schedule", "weekdays must contain one through seven ISO weekdays.");
  }
  const result = value.map((item) => {
    if (!Number.isSafeInteger(item) || Number(item) < 1 || Number(item) > 7) {
      fail("invalid_schedule", "weekday values must be ISO integers from 1 to 7.");
    }
    return Number(item) as IsoWeekday;
  });
  if (new Set(result).size !== result.length) {
    fail("invalid_schedule", "weekdays must not contain duplicates.");
  }
  return Object.freeze([...result].sort((left, right) => left - right));
}

function freezeSelector(
  value: AcceptanceSlaOverrideSelector,
): AcceptanceSlaOverrideSelector {
  return Object.freeze({
    ...value,
    ...(value.weekdays === null
      ? { weekdays: null }
      : { weekdays: Object.freeze([...value.weekdays]) }),
  });
}

function selectorFromRecord(
  record: Record<string, unknown>,
): AcceptanceSlaOverrideSelector {
  const weekdaysPresent = record.weekdays !== null;
  const zonePresent = record.timeZone !== null;
  const startPresent = record.startMinuteInclusive !== null;
  const endPresent = record.endMinuteExclusive !== null;
  if (
    new Set([weekdaysPresent, zonePresent, startPresent, endPresent]).size !== 1
  ) {
    fail(
      "invalid_schedule",
      "weekdays, timeZone and both minute bounds must be all present or all null.",
    );
  }
  let weekdays: readonly IsoWeekday[] | null = null;
  let timeZone: string | null = null;
  let startMinuteInclusive: number | null = null;
  let endMinuteExclusive: number | null = null;
  if (weekdaysPresent) {
    weekdays = normalizedWeekdays(record.weekdays);
    timeZone = canonicalTimeZone(record.timeZone);
    startMinuteInclusive = minute(record.startMinuteInclusive, "start minute");
    endMinuteExclusive = minute(record.endMinuteExclusive, "end minute");
    if (startMinuteInclusive === endMinuteExclusive) {
      fail("invalid_schedule", "time band cannot have zero or ambiguous full-day duration.");
    }
  }
  const readinessState =
    record.readinessState === null
      ? null
      : record.readinessState === "declared_busy"
        ? "declared_busy"
        : fail("invalid_input", "readinessState must be null or declared_busy.");
  const selector = freezeSelector({
    family: family(record.family),
    marketTypeId: nullableIdentifier(record.marketTypeId, "market type id"),
    providerTypeId: nullableIdentifier(record.providerTypeId, "provider type id"),
    categoryId: nullableIdentifier(record.categoryId, "category id"),
    localityId: nullableIdentifier(record.localityId, "locality id"),
    weekdays,
    timeZone,
    startMinuteInclusive,
    endMinuteExclusive,
    readinessState,
  });
  if (specificityVector(selector)[0] === 0) {
    fail("invalid_input", "schedule override requires at least one scope qualifier.");
  }
  return selector;
}

interface NormalizedOverridePayload {
  readonly overrideId: string;
  readonly state: AcceptanceSlaOverrideState;
  readonly selector: AcceptanceSlaOverrideSelector;
  readonly timeline: AcceptanceSlaTimelineValues;
  readonly effectiveFrom: string;
  readonly reasonCode: string;
}

function payload(value: unknown): NormalizedOverridePayload {
  if (
    typeof value !== "object" ||
    value === null ||
    Array.isArray(value) ||
    (Object.getPrototypeOf(value) !== Object.prototype &&
      Object.getPrototypeOf(value) !== null)
  ) {
    fail("invalid_input", "schedule override payload must be a plain record.");
  }
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record).sort();
  if (
    keys.length !== PAYLOAD_KEYS.length ||
    keys.some((key, index) => key !== PAYLOAD_KEYS[index])
  ) {
    fail("invalid_input", "schedule override payload fields are not exact.");
  }
  return Object.freeze({
    overrideId:
      typeof record.overrideId === "string"
        ? identifier(record.overrideId, "override id")
        : fail("invalid_input", "override id must be a stable identifier."),
    state: state(record.state),
    selector: selectorFromRecord(record),
    timeline: deriveAcceptanceSlaTimeline(
      record.responseWindowSeconds,
      record.maximumSequentialPartners,
      record.overallAssignmentCeilingSeconds,
    ),
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

function sha256Text(value: string): string {
  return createHash("sha256").update(value).digest("hex").toUpperCase();
}

function selectorFingerprint(value: AcceptanceSlaOverrideSelector): string {
  return sha256Text(
    [
      value.family,
      value.marketTypeId ?? "*",
      value.providerTypeId ?? "*",
      value.categoryId ?? "*",
      value.localityId ?? "*",
      value.weekdays?.join(",") ?? "*",
      value.timeZone ?? "*",
      value.startMinuteInclusive?.toString() ?? "*",
      value.endMinuteExclusive?.toString() ?? "*",
      value.readinessState ?? "*",
    ].join("|"),
  );
}

function specificityVector(
  value: AcceptanceSlaOverrideSelector,
): readonly number[] {
  const busy = value.readinessState === null ? 0 : 1;
  const schedule = value.weekdays === null ? 0 : 1;
  const locality = value.localityId === null ? 0 : 1;
  const category = value.categoryId === null ? 0 : 1;
  const provider = value.providerTypeId === null ? 0 : 1;
  const market = value.marketTypeId === null ? 0 : 1;
  return Object.freeze([
    busy + schedule + locality + category + provider + market,
    busy,
    schedule,
    locality,
    category,
    provider,
    market,
  ]);
}

function comparePrecedence(
  left: AcceptanceSlaOverrideSelector,
  right: AcceptanceSlaOverrideSelector,
): number {
  const leftVector = specificityVector(left);
  const rightVector = specificityVector(right);
  for (let index = 0; index < leftVector.length; index += 1) {
    const delta = (rightVector[index] ?? 0) - (leftVector[index] ?? 0);
    if (delta !== 0) return delta;
  }
  return 0;
}

function scalarSelectorsIntersect(
  left: string | null,
  right: string | null,
): boolean {
  return left === null || right === null || left === right;
}

type WeeklySegment = readonly [number, number];

function weeklySegments(
  value: AcceptanceSlaOverrideSelector,
): readonly WeeklySegment[] {
  if (
    value.weekdays === null ||
    value.startMinuteInclusive === null ||
    value.endMinuteExclusive === null
  ) {
    return [];
  }
  const segments: WeeklySegment[] = [];
  for (const weekday of value.weekdays) {
    const dayIndex = weekday - 1;
    const base = dayIndex * 1440;
    if (value.startMinuteInclusive < value.endMinuteExclusive) {
      segments.push([base + value.startMinuteInclusive, base + value.endMinuteExclusive]);
      continue;
    }
    segments.push([base + value.startMinuteInclusive, base + 1440]);
    const nextDayIndex = (dayIndex + 1) % 7;
    segments.push([
      nextDayIndex * 1440,
      nextDayIndex * 1440 + value.endMinuteExclusive,
    ]);
  }
  return Object.freeze(segments);
}

function schedulesIntersect(
  left: AcceptanceSlaOverrideSelector,
  right: AcceptanceSlaOverrideSelector,
): boolean {
  if (left.weekdays === null || right.weekdays === null) return true;
  if (left.timeZone !== right.timeZone) return true;
  return weeklySegments(left).some(([leftStart, leftEnd]) =>
    weeklySegments(right).some(
      ([rightStart, rightEnd]) =>
        Math.max(leftStart, rightStart) < Math.min(leftEnd, rightEnd),
    ),
  );
}

function selectorsIntersect(
  left: AcceptanceSlaOverrideSelector,
  right: AcceptanceSlaOverrideSelector,
): boolean {
  return (
    left.family === right.family &&
    scalarSelectorsIntersect(left.marketTypeId, right.marketTypeId) &&
    scalarSelectorsIntersect(left.providerTypeId, right.providerTypeId) &&
    scalarSelectorsIntersect(left.categoryId, right.categoryId) &&
    scalarSelectorsIntersect(left.localityId, right.localityId) &&
    scalarSelectorsIntersect(left.readinessState, right.readinessState) &&
    schedulesIntersect(left, right)
  );
}

function freezeRevision(
  value: AcceptanceSlaScheduleOverrideRevision,
): AcceptanceSlaScheduleOverrideRevision {
  return Object.freeze({ ...value, selector: freezeSelector(value.selector) });
}

function freezeAudit(
  value: AcceptanceSlaScheduleOverrideAuditEvent,
): AcceptanceSlaScheduleOverrideAuditEvent {
  return Object.freeze({ ...value });
}

function freezeSet(
  value: AcceptanceSlaScheduleOverrideSet,
): AcceptanceSlaScheduleOverrideSet {
  return Object.freeze({
    ...value,
    revisions: Object.freeze(value.revisions.map(freezeRevision)),
    receipts: Object.freeze(value.receipts.map((item) => Object.freeze({ ...item }))),
    auditEvents: Object.freeze(value.auditEvents.map(freezeAudit)),
  });
}

interface EffectiveInterval {
  readonly revision: AcceptanceSlaScheduleOverrideRevision;
  readonly start: number;
  readonly end: number | null;
}

function effectiveIntervals(
  revisions: readonly AcceptanceSlaScheduleOverrideRevision[],
): readonly EffectiveInterval[] {
  const grouped = new Map<string, AcceptanceSlaScheduleOverrideRevision[]>();
  for (const revision of revisions) {
    const group = grouped.get(revision.overrideId) ?? [];
    group.push(revision);
    grouped.set(revision.overrideId, group);
  }
  const intervals: EffectiveInterval[] = [];
  for (const group of grouped.values()) {
    group.forEach((revision, index) => {
      if (revision.state !== "enabled") return;
      const next = group[index + 1];
      intervals.push({
        revision,
        start: Date.parse(revision.effectiveFrom),
        end: next === undefined ? null : Date.parse(next.effectiveFrom),
      });
    });
  }
  return intervals;
}

function intervalsIntersect(left: EffectiveInterval, right: EffectiveInterval): boolean {
  const leftEnd = left.end ?? Number.POSITIVE_INFINITY;
  const rightEnd = right.end ?? Number.POSITIVE_INFINITY;
  return Math.max(left.start, right.start) < Math.min(leftEnd, rightEnd);
}

function assertNoAmbiguousAcceptedIntervals(
  revisions: readonly AcceptanceSlaScheduleOverrideRevision[],
): void {
  const intervals = effectiveIntervals(revisions);
  for (let leftIndex = 0; leftIndex < intervals.length; leftIndex += 1) {
    const left = intervals[leftIndex];
    if (left === undefined) continue;
    for (let rightIndex = leftIndex + 1; rightIndex < intervals.length; rightIndex += 1) {
      const right = intervals[rightIndex];
      if (
        right !== undefined &&
        left.revision.overrideId !== right.revision.overrideId &&
        intervalsIntersect(left, right) &&
        selectorsIntersect(left.revision.selector, right.revision.selector) &&
        comparePrecedence(left.revision.selector, right.revision.selector) === 0
      ) {
        fail("ambiguous_precedence", "accepted schedule overrides have equal precedence and overlapping scope.");
      }
    }
  }
}

function normalizeSet(
  value: AcceptanceSlaScheduleOverrideSet,
): AcceptanceSlaScheduleOverrideSet {
  if (value.schemaVersion !== 1) {
    fail("invalid_input", "schedule override schema version is unsupported.");
  }
  const tenantId = identifier(value.tenantId, "tenant id");
  const overrideSetId = identifier(value.overrideSetId, "override set id");
  const version = positiveVersion(value.version, "override set version");
  if (
    value.revisions.length > MAX_HISTORY ||
    value.receipts.length > MAX_HISTORY ||
    value.auditEvents.length > MAX_HISTORY ||
    value.revisions.length !== version - 1 ||
    value.receipts.length !== value.revisions.length ||
    value.auditEvents.length !== value.revisions.length
  ) {
    fail("invalid_input", "schedule override history and version are inconsistent.");
  }
  const lastByOverride = new Map<string, AcceptanceSlaScheduleOverrideRevision>();
  const revisions = value.revisions.map((item, index) => {
    if (item.schemaVersion !== 1 || item.aggregateVersion !== index + 2) {
      fail("invalid_input", "schedule override revision order is invalid.");
    }
    const record: Record<string, unknown> = {
      family: item.selector.family,
      marketTypeId: item.selector.marketTypeId,
      providerTypeId: item.selector.providerTypeId,
      categoryId: item.selector.categoryId,
      localityId: item.selector.localityId,
      weekdays: item.selector.weekdays,
      timeZone: item.selector.timeZone,
      startMinuteInclusive: item.selector.startMinuteInclusive,
      endMinuteExclusive: item.selector.endMinuteExclusive,
      readinessState: item.selector.readinessState,
    };
    const selector = selectorFromRecord(record);
    const timeline = deriveAcceptanceSlaTimeline(
      item.responseWindowSeconds,
      item.maximumSequentialPartners,
      item.overallAssignmentCeilingSeconds,
    );
    if (
      item.moolChatOffsetSeconds !== 0 ||
      item.whatsAppOffsetSeconds !== timeline.whatsAppOffsetSeconds ||
      item.agenticCallOffsetSeconds !== timeline.agenticCallOffsetSeconds ||
      item.reassignAtSeconds !== timeline.responseWindowSeconds
    ) {
      fail("invalid_input", "schedule override escalation offsets are invalid.");
    }
    const overrideId = identifier(item.overrideId, "override id");
    const effectiveFrom = timestamp(item.effectiveFrom, "revision effectiveFrom");
    const publishedAt = timestamp(item.publishedAt, "revision publishedAt");
    if (Date.parse(effectiveFrom) < Date.parse(publishedAt)) {
      fail("invalid_input", "accepted schedule override is backdated.");
    }
    const previous = lastByOverride.get(overrideId);
    if (
      previous !== undefined &&
      Date.parse(effectiveFrom) <= Date.parse(previous.effectiveFrom)
    ) {
      fail("invalid_input", "override revisions are not strictly effective-ordered.");
    }
    const fingerprint = selectorFingerprint(selector);
    if (item.selectorFingerprint !== fingerprint) {
      fail("invalid_input", "schedule override selector fingerprint is invalid.");
    }
    if (previous !== undefined && previous.selectorFingerprint !== fingerprint) {
      fail("invalid_input", "one override id cannot change its governed selector.");
    }
    if (previous === undefined && item.state === "disabled") {
      fail("invalid_input", "first override revision cannot be disabled.");
    }
    if (
      item.state === "disabled" &&
      previous !== undefined &&
      (previous.responseWindowSeconds !== timeline.responseWindowSeconds ||
        previous.maximumSequentialPartners !== timeline.maximumSequentialPartners ||
        previous.overallAssignmentCeilingSeconds !==
          timeline.overallAssignmentCeilingSeconds)
    ) {
      fail("invalid_input", "disabled override must preserve its prior timing facts.");
    }
    const commandFingerprint = item.commandFingerprint;
    if (!SHA256_PATTERN.test(commandFingerprint)) {
      fail("invalid_input", "override command fingerprint must be SHA-256.");
    }
    const revision = freezeRevision({
      schemaVersion: 1,
      revisionId: identifier(item.revisionId, "revision id"),
      aggregateVersion: item.aggregateVersion,
      overrideId,
      state: state(item.state),
      selector,
      selectorFingerprint: fingerprint,
      ...timeline,
      moolChatOffsetSeconds: 0,
      reassignAtSeconds: timeline.responseWindowSeconds,
      effectiveFrom,
      publishedAt,
      reasonCode: identifier(item.reasonCode, "reason code"),
      commandId: identifier(item.commandId, "revision command id"),
      commandFingerprint,
      actorId: identifier(item.actorId, "revision actor id"),
    });
    lastByOverride.set(overrideId, revision);
    return revision;
  });
  assertNoAmbiguousAcceptedIntervals(revisions);

  const receipts = value.receipts.map((item, index) => {
    const revision = revisions[index];
    if (
      revision === undefined ||
      item.schemaVersion !== 1 ||
      item.aggregateVersion !== revision.aggregateVersion ||
      item.aggregateId !== overrideSetId ||
      item.commandId !== revision.commandId ||
      item.commandFingerprint !== revision.commandFingerprint ||
      item.actorId !== revision.actorId ||
      item.requiredScope !== ADMIN_SCOPE ||
      item.resultReference !== revision.revisionId ||
      item.resultSha256 !==
        sha256Text(`${revision.commandFingerprint}:${revision.revisionId}`) ||
      item.completedAt !== revision.publishedAt
    ) {
      fail("invalid_input", "schedule override receipt history is inconsistent.");
    }
    return Object.freeze({ ...item });
  });
  const auditEvents = value.auditEvents.map((item, index) => {
    const revision = revisions[index];
    if (
      revision === undefined ||
      item.schemaVersion !== 1 ||
      item.eventType !== "acceptance_sla_schedule_override_published" ||
      item.aggregateVersion !== revision.aggregateVersion ||
      item.tenantId !== tenantId ||
      item.overrideSetId !== overrideSetId ||
      item.overrideId !== revision.overrideId ||
      item.revisionId !== revision.revisionId ||
      item.family !== revision.selector.family ||
      item.state !== revision.state ||
      item.selectorFingerprint !== revision.selectorFingerprint ||
      item.commandId !== revision.commandId ||
      item.commandFingerprint !== revision.commandFingerprint ||
      item.actorId !== revision.actorId ||
      item.occurredAt !== revision.publishedAt
    ) {
      fail("invalid_input", "schedule override audit history is inconsistent.");
    }
    return freezeAudit({
      ...item,
      eventId: identifier(item.eventId, "audit event id"),
    });
  });
  return freezeSet({
    schemaVersion: 1,
    tenantId,
    overrideSetId,
    version,
    revisions,
    receipts,
    auditEvents,
  });
}

function overlapWarnings(
  revisions: readonly AcceptanceSlaScheduleOverrideRevision[],
  candidate: AcceptanceSlaScheduleOverrideRevision,
): readonly string[] {
  if (candidate.state === "disabled") return Object.freeze([]);
  const combined = [...revisions, candidate];
  const candidateInterval = effectiveIntervals(combined).find(
    (item) => item.revision.revisionId === candidate.revisionId,
  );
  if (candidateInterval === undefined) return Object.freeze([]);
  const warnings = new Set<string>();
  for (const interval of effectiveIntervals(combined)) {
    if (
      interval.revision.overrideId === candidate.overrideId ||
      !intervalsIntersect(candidateInterval, interval) ||
      !selectorsIntersect(candidate.selector, interval.revision.selector)
    ) {
      continue;
    }
    if (comparePrecedence(candidate.selector, interval.revision.selector) === 0) {
      fail("ambiguous_precedence", "override would create equal-precedence overlapping scope.");
    }
    warnings.add(interval.revision.overrideId);
  }
  return Object.freeze([...warnings].sort());
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

function localWeekdayAndMinute(
  at: string,
  timeZone: string,
): { weekday: IsoWeekday; minute: number } {
  const parts = new Intl.DateTimeFormat("en-US-u-ca-iso8601", {
    timeZone,
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(new Date(at));
  const weekdayText = parts.find((part) => part.type === "weekday")?.value;
  const hourText = parts.find((part) => part.type === "hour")?.value;
  const minuteText = parts.find((part) => part.type === "minute")?.value;
  const weekdayMap: Readonly<Record<string, IsoWeekday>> = {
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
    Sun: 7,
  };
  const weekday = weekdayText === undefined ? undefined : weekdayMap[weekdayText];
  const hour = Number(hourText);
  const minute = Number(minuteText);
  if (
    weekday === undefined ||
    !Number.isSafeInteger(hour) ||
    !Number.isSafeInteger(minute)
  ) {
    fail("invalid_schedule", "timezone projection could not produce local schedule facts.");
  }
  return { weekday, minute: hour * 60 + minute };
}

function previousWeekday(value: IsoWeekday): IsoWeekday {
  return (value === 1 ? 7 : value - 1) as IsoWeekday;
}

function scheduleMatches(
  selector: AcceptanceSlaOverrideSelector,
  at: string,
): boolean {
  if (
    selector.weekdays === null ||
    selector.timeZone === null ||
    selector.startMinuteInclusive === null ||
    selector.endMinuteExclusive === null
  ) {
    return true;
  }
  const local = localWeekdayAndMinute(at, selector.timeZone);
  if (selector.startMinuteInclusive < selector.endMinuteExclusive) {
    return (
      selector.weekdays.includes(local.weekday) &&
      local.minute >= selector.startMinuteInclusive &&
      local.minute < selector.endMinuteExclusive
    );
  }
  return (
    (selector.weekdays.includes(local.weekday) &&
      local.minute >= selector.startMinuteInclusive) ||
    (selector.weekdays.includes(previousWeekday(local.weekday)) &&
      local.minute < selector.endMinuteExclusive)
  );
}

function selectorMatches(
  selector: AcceptanceSlaOverrideSelector,
  context: AcceptanceSlaScheduleOverrideContext,
  at: string,
): boolean {
  return (
    selector.family === family(context.family) &&
    (selector.marketTypeId === null || selector.marketTypeId === context.marketTypeId) &&
    (selector.providerTypeId === null ||
      selector.providerTypeId === context.providerTypeId) &&
    (selector.categoryId === null || selector.categoryId === context.categoryId) &&
    (selector.localityId === null || selector.localityId === context.localityId) &&
    (selector.readinessState === null || context.declaredBusy) &&
    scheduleMatches(selector, at)
  );
}

function normalizedContext(
  value: AcceptanceSlaScheduleOverrideContext,
): AcceptanceSlaScheduleOverrideContext {
  if (typeof value.declaredBusy !== "boolean") {
    fail("invalid_input", "declaredBusy must be a boolean workspace fact.");
  }
  return Object.freeze({
    family: family(value.family),
    marketTypeId: nullableIdentifier(value.marketTypeId, "context market type id"),
    providerTypeId: nullableIdentifier(
      value.providerTypeId,
      "context provider type id",
    ),
    categoryId: nullableIdentifier(value.categoryId, "context category id"),
    localityId: nullableIdentifier(value.localityId, "context locality id"),
    declaredBusy: value.declaredBusy,
    at: timestamp(value.at, "resolution timestamp"),
  });
}

export function createAcceptanceSlaScheduleOverrideSet(request: {
  readonly tenantId: string;
  readonly overrideSetId: string;
}): AcceptanceSlaScheduleOverrideSet {
  return freezeSet({
    schemaVersion: 1,
    tenantId: identifier(request.tenantId, "tenant id"),
    overrideSetId: identifier(request.overrideSetId, "override set id"),
    version: 1,
    revisions: [],
    receipts: [],
    auditEvents: [],
  });
}

export function publishAcceptanceSlaScheduleOverride(
  request: PublishAcceptanceSlaScheduleOverrideRequest,
): PublishAcceptanceSlaScheduleOverrideResult {
  const authorization = authorizePrivilegedCommand({
    tenantId: request.overrideSet.tenantId,
    aggregateId: request.overrideSet.overrideSetId,
    currentVersion: request.overrideSet.version,
    requiredScope: ADMIN_SCOPE,
    receipts: request.overrideSet.receipts,
    command: request.command,
  });
  const current = normalizeSet(request.overrideSet);
  if (authorization.state === "replay") {
    const revision = current.revisions.find(
      (item) => item.aggregateVersion === authorization.receipt.aggregateVersion,
    );
    if (revision === undefined) {
      fail("invalid_input", "command receipt has no matching override revision.");
    }
    return Object.freeze({
      overrideSet: current,
      revision,
      receipt: authorization.receipt,
      overlapWarningOverrideIds: Object.freeze([]),
      replayed: true,
    });
  }
  const commandPayload = payload(request.command.payload);
  if (Date.parse(commandPayload.effectiveFrom) < Date.parse(authorization.occurredAt)) {
    fail("effective_time_conflict", "schedule override cannot be backdated.");
  }
  const previous = [...current.revisions]
    .reverse()
    .find((item) => item.overrideId === commandPayload.overrideId);
  const fingerprint = selectorFingerprint(commandPayload.selector);
  if (
    previous !== undefined &&
    Date.parse(commandPayload.effectiveFrom) <= Date.parse(previous.effectiveFrom)
  ) {
    fail("effective_time_conflict", "override effective time must follow its prior revision.");
  }
  if (previous !== undefined && previous.selectorFingerprint !== fingerprint) {
    fail("invalid_input", "one override id cannot change its governed selector.");
  }
  if (previous === undefined && commandPayload.state === "disabled") {
    fail("invalid_input", "first override revision cannot be disabled.");
  }
  if (
    commandPayload.state === "disabled" &&
    previous !== undefined &&
    (previous.responseWindowSeconds !== commandPayload.timeline.responseWindowSeconds ||
      previous.maximumSequentialPartners !==
        commandPayload.timeline.maximumSequentialPartners ||
      previous.overallAssignmentCeilingSeconds !==
        commandPayload.timeline.overallAssignmentCeilingSeconds)
  ) {
    fail("invalid_input", "disabled override must preserve its prior timing facts.");
  }
  const aggregateVersion = current.version + 1;
  const revisionId = `acceptance-sla-override-revision:${aggregateVersion}`;
  const revision = freezeRevision({
    schemaVersion: 1,
    revisionId,
    aggregateVersion,
    overrideId: commandPayload.overrideId,
    state: commandPayload.state,
    selector: commandPayload.selector,
    selectorFingerprint: fingerprint,
    ...commandPayload.timeline,
    moolChatOffsetSeconds: 0,
    reassignAtSeconds: commandPayload.timeline.responseWindowSeconds,
    effectiveFrom: commandPayload.effectiveFrom,
    publishedAt: authorization.occurredAt,
    reasonCode: commandPayload.reasonCode,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
    actorId: authorization.actorId,
  });
  const warnings = overlapWarnings(current.revisions, revision);
  const resultSha256 = sha256Text(
    `${authorization.commandFingerprint}:${revisionId}`,
  );
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
    fail("invalid_input", "completed override command did not produce a receipt.");
  }
  const audit = freezeAudit({
    schemaVersion: 1,
    eventId: `acceptance-sla-override-event:${aggregateVersion}`,
    eventType: "acceptance_sla_schedule_override_published",
    aggregateVersion,
    tenantId: current.tenantId,
    overrideSetId: current.overrideSetId,
    overrideId: commandPayload.overrideId,
    revisionId,
    family: commandPayload.selector.family,
    state: commandPayload.state,
    selectorFingerprint: fingerprint,
    commandId: authorization.commandId,
    commandFingerprint: authorization.commandFingerprint,
    actorId: authorization.actorId,
    occurredAt: authorization.occurredAt,
  });
  const overrideSet = freezeSet({
    ...current,
    version: aggregateVersion,
    revisions: [...current.revisions, revision],
    receipts,
    auditEvents: [...current.auditEvents, audit],
  });
  return Object.freeze({
    overrideSet,
    revision,
    receipt,
    overlapWarningOverrideIds: warnings,
    replayed: false,
  });
}

export function resolveAcceptanceSlaScheduleOverride(
  request: ResolveAcceptanceSlaScheduleOverrideRequest,
): AcceptanceSlaScheduleOverrideResolution {
  const actor = readActor(request.actor);
  const tenantId = identifier(request.tenantId, "tenant id");
  if (!actor.scopes.includes(ADMIN_SCOPE)) {
    fail("unauthorized", "actor lacks acceptance policy authority.");
  }
  if (actor.tenantId !== tenantId) {
    fail("tenant_mismatch", "actor cannot read another tenant's overrides.");
  }
  const overrideSetId = identifier(request.overrideSetId, "override set id");
  if (request.overrideSet.tenantId !== tenantId) {
    fail("tenant_mismatch", "override set is unavailable for this tenant.");
  }
  if (request.overrideSet.overrideSetId !== overrideSetId) {
    fail("aggregate_mismatch", "requested override set is unavailable.");
  }
  const context = normalizedContext(request.context);
  const current = normalizeSet(request.overrideSet);
  const at = context.at;
  const latestByOverride = new Map<string, AcceptanceSlaScheduleOverrideRevision>();
  for (const revision of current.revisions) {
    if (Date.parse(revision.effectiveFrom) <= Date.parse(at)) {
      latestByOverride.set(revision.overrideId, revision);
    }
  }
  const matches = [...latestByOverride.values()]
    .filter(
      (revision) =>
        revision.state === "enabled" &&
        selectorMatches(revision.selector, context, at),
    )
    .sort((left, right) => comparePrecedence(left.selector, right.selector));
  const winner = matches[0];
  if (winner === undefined) return Object.freeze({ kind: "global_fallback" });
  const second = matches[1];
  if (
    second !== undefined &&
    comparePrecedence(winner.selector, second.selector) === 0
  ) {
    fail("ambiguous_precedence", "matching overrides have ambiguous precedence.");
  }
  return Object.freeze({ kind: "override", revision: winner });
}
