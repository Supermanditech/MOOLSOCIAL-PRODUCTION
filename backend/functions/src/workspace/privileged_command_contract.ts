import { createHash } from "node:crypto";

export type JsonValue =
  | null
  | boolean
  | number
  | string
  | readonly JsonValue[]
  | { readonly [key: string]: JsonValue };

export type PrivilegedCommandErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "aggregate_mismatch"
  | "version_conflict"
  | "idempotency_conflict"
  | "reservation_conflict"
  | "sensitive_payload";

export class PrivilegedCommandError extends Error {
  constructor(
    readonly code: PrivilegedCommandErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "PrivilegedCommandError";
  }
}

export interface PrivilegedCommandActor {
  readonly actorId: string;
  readonly tenantId: string;
  readonly scopes: readonly string[];
}

export interface PrivilegedCommandEnvelope {
  readonly schemaVersion: 1;
  readonly commandId: string;
  readonly aggregateId: string;
  readonly expectedVersion: number;
  readonly occurredAt: string;
  readonly confirmed: boolean;
  readonly reason: string;
  readonly actor: PrivilegedCommandActor;
  readonly payload: JsonValue;
}

export interface PrivilegedCommandReceipt {
  readonly schemaVersion: 1;
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly aggregateId: string;
  readonly aggregateVersion: number;
  readonly actorId: string;
  readonly requiredScope: string;
  readonly resultReference: string;
  readonly resultSha256: string;
  readonly completedAt: string;
}

export interface AuthorizePrivilegedCommandRequest {
  readonly tenantId: string;
  readonly aggregateId: string;
  readonly currentVersion: number;
  readonly requiredScope: string;
  readonly receipts: readonly PrivilegedCommandReceipt[];
  readonly command: PrivilegedCommandEnvelope;
}

export interface NewPrivilegedCommandReservation {
  readonly state: "new";
  readonly commandId: string;
  readonly commandFingerprint: string;
  readonly aggregateId: string;
  readonly expectedVersion: number;
  readonly actorId: string;
  readonly requiredScope: string;
  readonly occurredAt: string;
}

export interface ReplayedPrivilegedCommandReservation {
  readonly state: "replay";
  readonly receipt: PrivilegedCommandReceipt;
}

export type PrivilegedCommandAuthorization =
  | NewPrivilegedCommandReservation
  | ReplayedPrivilegedCommandReservation;

export interface CompletePrivilegedCommandRequest {
  readonly reservation: NewPrivilegedCommandReservation;
  readonly currentReceipts: readonly PrivilegedCommandReceipt[];
  readonly newAggregateVersion: number;
  readonly resultReference: string;
  readonly resultSha256: string;
  readonly completedAt: string;
}

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const SHA256_PATTERN = /^[A-Fa-f0-9]{64}$/u;
const MAX_RECEIPTS = 500;
const MAX_PAYLOAD_BYTES = 16_384;
const MAX_JSON_DEPTH = 8;
const MAX_COLLECTION_ITEMS = 100;
const MAX_STRING_LENGTH = 4_000;
const SENSITIVE_KEY =
  /(?:authorization|cookie|credential|password|secret|token|api.?key|session.?url)/iu;

function fail(code: PrivilegedCommandErrorCode, message: string): never {
  throw new PrivilegedCommandError(code, message);
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
    fail("invalid_input", `${label} must be a positive integer.`);
  }
  return value;
}

function reason(value: string): string {
  const normalized = value.trim();
  if (normalized.length < 5 || normalized.length > 280) {
    fail("invalid_input", "command reason must contain 5 to 280 characters.");
  }
  return normalized;
}

function actor(value: PrivilegedCommandActor): PrivilegedCommandActor {
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

function canonicalJson(value: unknown, depth = 0): JsonValue {
  if (depth > MAX_JSON_DEPTH) {
    fail("invalid_input", "command payload exceeds its maximum depth.");
  }
  if (value === null || typeof value === "boolean" || typeof value === "string") {
    if (typeof value === "string" && value.length > MAX_STRING_LENGTH) {
      fail("invalid_input", "command payload string is too long.");
    }
    return value;
  }
  if (typeof value === "number") {
    if (!Number.isFinite(value)) {
      fail("invalid_input", "command payload numbers must be finite.");
    }
    return Object.is(value, -0) ? 0 : value;
  }
  if (Array.isArray(value)) {
    if (value.length > MAX_COLLECTION_ITEMS) {
      fail("invalid_input", "command payload array is too large.");
    }
    return Object.freeze(value.map((item) => canonicalJson(item, depth + 1)));
  }
  if (typeof value !== "object" || value === undefined) {
    fail("invalid_input", "command payload must contain JSON-safe values only.");
  }
  const prototype = Object.getPrototypeOf(value);
  if (prototype !== Object.prototype && prototype !== null) {
    fail("invalid_input", "command payload objects must be plain records.");
  }
  const entries = Object.entries(value as Record<string, unknown>);
  if (entries.length > MAX_COLLECTION_ITEMS) {
    fail("invalid_input", "command payload object has too many fields.");
  }
  const result: Record<string, JsonValue> = {};
  for (const [key, item] of entries.sort(([left], [right]) =>
    left.localeCompare(right),
  )) {
    if (SENSITIVE_KEY.test(key)) {
      fail("sensitive_payload", "command payload contains a sensitive field.");
    }
    const normalizedKey = identifier(key, "payload field");
    result[normalizedKey] = canonicalJson(item, depth + 1);
  }
  return Object.freeze(result);
}

function fingerprint(value: unknown): string {
  return createHash("sha256").update(JSON.stringify(value)).digest("hex").toUpperCase();
}

function receipt(value: PrivilegedCommandReceipt): PrivilegedCommandReceipt {
  if (value.schemaVersion !== 1) {
    fail("invalid_input", "receipt schema version is unsupported.");
  }
  if (!SHA256_PATTERN.test(value.commandFingerprint)) {
    fail("invalid_input", "receipt command fingerprint must be SHA-256.");
  }
  if (!SHA256_PATTERN.test(value.resultSha256)) {
    fail("invalid_input", "receipt result digest must be SHA-256.");
  }
  return Object.freeze({
    schemaVersion: 1,
    commandId: identifier(value.commandId, "receipt command id"),
    commandFingerprint: value.commandFingerprint.toUpperCase(),
    aggregateId: identifier(value.aggregateId, "receipt aggregate id"),
    aggregateVersion: positiveVersion(
      value.aggregateVersion,
      "receipt aggregate version",
    ),
    actorId: identifier(value.actorId, "receipt actor id"),
    requiredScope: identifier(value.requiredScope, "receipt required scope"),
    resultReference: identifier(value.resultReference, "result reference"),
    resultSha256: value.resultSha256.toUpperCase(),
    completedAt: timestamp(value.completedAt, "receipt completedAt"),
  });
}

function normalizedReceipts(
  values: readonly PrivilegedCommandReceipt[],
): readonly PrivilegedCommandReceipt[] {
  if (values.length > MAX_RECEIPTS) {
    fail("invalid_input", "command receipt history exceeds its bounded limit.");
  }
  const normalized = values.map(receipt);
  const commandIds = normalized.map((item) => item.commandId);
  if (new Set(commandIds).size !== commandIds.length) {
    fail("invalid_input", "command receipt history contains duplicate IDs.");
  }
  return Object.freeze(normalized);
}

export function authorizePrivilegedCommand(
  request: AuthorizePrivilegedCommandRequest,
): PrivilegedCommandAuthorization {
  const tenantId = identifier(request.tenantId, "tenant id");
  const aggregateId = identifier(request.aggregateId, "aggregate id");
  const requiredScope = identifier(request.requiredScope, "required scope");
  const currentVersion = positiveVersion(request.currentVersion, "current version");
  const commandActor = actor(request.command.actor);

  if (commandActor.tenantId !== tenantId) {
    fail("tenant_mismatch", "actor cannot command another tenant's aggregate.");
  }
  if (!commandActor.scopes.includes(requiredScope)) {
    fail("unauthorized", `actor lacks required scope ${requiredScope}.`);
  }
  if (request.command.schemaVersion !== 1) {
    fail("invalid_input", "command schema version is unsupported.");
  }
  const commandId = identifier(request.command.commandId, "command id");
  if (identifier(request.command.aggregateId, "command aggregate id") !== aggregateId) {
    fail("aggregate_mismatch", "command targets a different aggregate.");
  }
  if (!request.command.confirmed) {
    fail("unauthorized", "privileged command requires explicit confirmation.");
  }
  const expectedVersion = positiveVersion(
    request.command.expectedVersion,
    "expected version",
  );
  const occurredAt = timestamp(request.command.occurredAt, "occurredAt");
  const commandReason = reason(request.command.reason);
  const payload = canonicalJson(request.command.payload);
  const serializedPayload = JSON.stringify(payload);
  if (Buffer.byteLength(serializedPayload, "utf8") > MAX_PAYLOAD_BYTES) {
    fail("invalid_input", "command payload exceeds its byte limit.");
  }
  const commandFingerprint = fingerprint({
    schemaVersion: 1,
    commandId,
    aggregateId,
    expectedVersion,
    occurredAt,
    confirmed: true,
    reason: commandReason,
    actor: commandActor,
    requiredScope,
    payload,
  });
  const receipts = normalizedReceipts(request.receipts);
  const existing = receipts.find((item) => item.commandId === commandId);
  if (existing !== undefined) {
    if (existing.commandFingerprint !== commandFingerprint) {
      fail(
        "idempotency_conflict",
        "command id was already used for a different command.",
      );
    }
    return Object.freeze({ state: "replay", receipt: existing });
  }
  if (expectedVersion !== currentVersion) {
    fail(
      "version_conflict",
      `expected version ${expectedVersion} does not match ${currentVersion}.`,
    );
  }
  return Object.freeze({
    state: "new",
    commandId,
    commandFingerprint,
    aggregateId,
    expectedVersion,
    actorId: commandActor.actorId,
    requiredScope,
    occurredAt,
  });
}

export function completePrivilegedCommand(
  request: CompletePrivilegedCommandRequest,
): readonly PrivilegedCommandReceipt[] {
  const receipts = normalizedReceipts(request.currentReceipts);
  if (receipts.some((item) => item.commandId === request.reservation.commandId)) {
    fail("reservation_conflict", "command reservation was already completed.");
  }
  const newAggregateVersion = positiveVersion(
    request.newAggregateVersion,
    "new aggregate version",
  );
  if (newAggregateVersion !== request.reservation.expectedVersion + 1) {
    fail(
      "version_conflict",
      "completed aggregate version must advance exactly once.",
    );
  }
  const resultSha256 = SHA256_PATTERN.test(request.resultSha256)
    ? request.resultSha256.toUpperCase()
    : fail("invalid_input", "result digest must be SHA-256.");
  const completed = receipt({
    schemaVersion: 1,
    commandId: request.reservation.commandId,
    commandFingerprint: request.reservation.commandFingerprint,
    aggregateId: request.reservation.aggregateId,
    aggregateVersion: newAggregateVersion,
    actorId: request.reservation.actorId,
    requiredScope: request.reservation.requiredScope,
    resultReference: identifier(request.resultReference, "result reference"),
    resultSha256,
    completedAt: timestamp(request.completedAt, "completedAt"),
  });
  return Object.freeze([...receipts, completed]);
}
