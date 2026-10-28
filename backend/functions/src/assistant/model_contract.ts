import {createHash} from "node:crypto";
import {decodePlansScope, type PlansScope} from "../account/plans_service.js";

export class AssistantModelError extends Error {
  constructor(readonly code = "assistant_unavailable", readonly status = 503) { super(code); }
}
export const clarificationToolName = "mool_ask_clarification";
export function fail(code?: string, status?: number): never { throw new AssistantModelError(code, status); }
export function object(value: unknown, keys?: readonly string[]): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return fail("invalid_request", 400);
  const row = value as Record<string, unknown>;
  if (keys && Object.keys(row).sort().join("|") !== [...keys].sort().join("|")) return fail("invalid_request", 400);
  return row;
}
export function text(value: unknown, max = 256): string {
  if (typeof value !== "string" || !value.trim() || value.length > max || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)) return fail("invalid_request", 400);
  return value;
}
export function id(value: unknown): string {
  const result = text(value, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]*$/u.test(result)) return fail("invalid_request", 400);
  return result;
}
export function canonical(value: unknown): string {
  if (value === null || typeof value === "string" || typeof value === "boolean") return JSON.stringify(value);
  if (typeof value === "number" && Number.isFinite(value)) return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  const row = object(value);
  return `{${Object.keys(row).sort().map(key => `${JSON.stringify(key)}:${canonical(row[key])}`).join(",")}}`;
}
export function digest(value: unknown): string { return createHash("sha256").update(canonical(value)).digest("hex"); }
export interface PreparationRequest {
  readonly scope: PlansScope; readonly requestId: string; readonly requestRevision: number;
  readonly expectedEntitlementRevision: string; readonly message: string; readonly language: string; readonly history: readonly {role: "user" | "assistant"; text: string}[]; readonly actionId: string | null; readonly entityId: string | null;
  /** Original public listing selection only; never records or permission. */
  readonly catalogueListingIds?: readonly string[];
  /** Untrusted hints from captured native reviews; original sources still grant all authority. */
  readonly nativeTargets?: readonly PreparationTargetHint[];
  /** Compact readiness hints only; positions bind exact original source proofs. */
  readonly nativeTargetMask?: PreparationTargetMask;
}
export interface PreparationTargetMask {readonly version: 1; readonly fingerprint: string; readonly bits: string;}
export function nativeTargetMaskSelection(value: unknown): PreparationTargetMask {
  const row = object(value, ["version", "fingerprint", "bits"]);
  if (row.version !== 1 || typeof row.fingerprint !== "string" || !/^[a-f0-9]{64}$/u.test(row.fingerprint) ||
      typeof row.bits !== "string" || row.bits.length > 2500 || !/^[A-Za-z0-9_-]*$/u.test(row.bits)) return fail("invalid_request", 400);
  const bytes = Buffer.from(row.bits, "base64url");
  if (bytes.length > 1875 || bytes.toString("base64url") !== row.bits) return fail("invalid_request", 400);
  return Object.freeze({version: 1, fingerprint: row.fingerprint, bits: row.bits});
}
export interface PreparationTargetHint {readonly actionId: string; readonly entityId: string | null;}
export function nativeTargetSelection(value: unknown): readonly PreparationTargetHint[] {
  if (!Array.isArray(value) || value.length > 5000) return fail("invalid_request", 400);
  const seen = new Set<string>();
  return Object.freeze(value.map(raw => {
    const row = object(raw, ["actionId", "entityId"]);
    if (typeof row.actionId !== "string" || !/^AI-ACT-\d{3}$/u.test(row.actionId)) return fail("invalid_request", 400);
    const selected = {actionId: row.actionId, entityId: row.entityId === null ? null : id(row.entityId)};
    const key = canonical([selected.actionId, selected.entityId]);
    if (seen.has(key)) return fail("invalid_request", 400);
    seen.add(key); return Object.freeze(selected);
  }));
}
export function catalogueListingSelection(value: unknown): readonly string[] {
  if (!Array.isArray(value) || value.length > 500 || new Set(value).size !== value.length ||
      value.some(v => typeof v !== "string" || !/^listing-[a-f0-9]{64}$/u.test(v))) return fail("invalid_request", 400);
  return Object.freeze([...value] as string[]);
}
// Match the approved composer hints. Other languages still use original user
// text with Auto; never interpolate an arbitrary client instruction as language.
export const preparationLanguages = new Set(["Auto", "English", "हिन्दी", "मराठी", "தமிழ்", "اردو", "ಕನ್ನಡ"]);
export type AssistantCommand = {operation: "prepare"; payload: PreparationRequest} |
  {operation: "status" | "cancel"; payload: {scope: PlansScope; requestId: string}};
export function command(value: unknown): AssistantCommand {
  const row = object(value, ["operation", "payload"]);
  const prepare = row.operation === "prepare";
  if (!prepare && row.operation !== "status" && row.operation !== "cancel") return fail("invalid_request", 400);
  const payload = object(row.payload);
  const p = object(payload, prepare ? ["scope", "requestId", "requestRevision", "message", "language", "actionId", "entityId", "history", "expectedEntitlementRevision",
    ...(Object.hasOwn(payload, "catalogueListingIds") ? ["catalogueListingIds"] : []),
    ...(Object.hasOwn(payload, "nativeTargets") ? ["nativeTargets"] : []),
    ...(Object.hasOwn(payload, "nativeTargetMask") ? ["nativeTargetMask"] : [])] : ["scope", "requestId"]);
  const scope = decodePlansScope(p.scope), requestId = id(p.requestId);
  if (!prepare) return {operation: row.operation as "status" | "cancel", payload: {scope, requestId}};
  if (Object.hasOwn(p, "nativeTargetMask") && scope.audience !== "workspace") return fail("invalid_request", 400);
  if (!Number.isSafeInteger(p.requestRevision) || (p.requestRevision as number) < 0) return fail("invalid_request", 400);
  if (typeof p.language !== "string" || !preparationLanguages.has(p.language)) return fail("invalid_request", 400);
  if (!Array.isArray(p.history) || p.history.length > 20) return fail("invalid_request", 400);
  const history = p.history.map(v => {const item = object(v, ["role", "text"]);
    if (item.role !== "user" && item.role !== "assistant") return fail("invalid_request", 400);
    return {role: item.role as "user" | "assistant", text: text(item.text, 8000)};});
  return {operation: "prepare", payload: {scope, requestId, history, expectedEntitlementRevision: text(p.expectedEntitlementRevision), requestRevision: p.requestRevision as number,
    message: text(p.message, 8000), language: text(p.language, 80), actionId: p.actionId === null ? null : id(p.actionId), entityId: p.entityId === null ? null : id(p.entityId),
    ...(Object.hasOwn(p, "catalogueListingIds") ? {catalogueListingIds: catalogueListingSelection(p.catalogueListingIds)} : {}),
    ...(Object.hasOwn(p, "nativeTargets") ? {nativeTargets: nativeTargetSelection(p.nativeTargets)} : {}),
    ...(Object.hasOwn(p, "nativeTargetMask") ? {nativeTargetMask: nativeTargetMaskSelection(p.nativeTargetMask)} : {})}};
}
export interface PreparationNativeTarget {
  readonly actionId: string; readonly entityId: string | null; readonly sourceRevision: string;
}
export interface ResolvedPreparationTarget {
  readonly entityId: string | null; readonly sourceRevision: string;
  readonly fields: Readonly<Record<string, unknown>>;
  readonly title?: string; readonly summary?: string;
}
export interface PreparationTool {
  readonly name: string; readonly actionId: string; readonly entityId: string | null;
  readonly sourceRevision: string; readonly description: string; readonly parameters: Record<string, unknown>;
  /** Registered original selector property. Caller/model cannot define or rename it. */
  readonly targetSelector?: string;
  validate(fields: Readonly<Record<string, unknown>>): boolean;
  /** Registered schema normalisation only; never supplied by a caller/model. */
  decodeFields?(fields: Readonly<Record<string, unknown>>): Readonly<Record<string, unknown>>;
  /** Registered source-backed selector, never model-authored routing/code. */
  resolveTarget?(fields: Readonly<Record<string, unknown>>): ResolvedPreparationTarget;
}
export interface PreparationContext {
  readonly revision: string; readonly validUntil: string; readonly tools: readonly PreparationTool[];
  /** Minimal original-source data selected by the trusted context adapter. */
  readonly modelContext?: Readonly<Record<string, unknown>>;
  /** Exact original source targets, independent of compact model tool schemas. */
  readonly nativeTargets?: readonly PreparationNativeTarget[];
}
export type PreparationOutcome = {readonly kind: "clarification"; readonly text: string} |
  {readonly kind: "proposal"; readonly id: string; readonly actionId: string; readonly entityId: string | null;
    readonly sourceRevision: string; readonly title: string; readonly summary: string; readonly fields: Readonly<Record<string, unknown>>};
export interface PreparationReply {
  readonly requestId: string; readonly requestRevision: number; readonly scope: PlansScope;
  readonly entitlementRevision: string; readonly checkedAt: string; readonly validUntil: string;
  readonly outcome: PreparationOutcome;
}
/** Strict schemas plus the original capability validator: schemas never grant permission. */
export function assertStrictSchema(value: unknown, depth = 0): void {
  if (depth > 12) return fail();
  const s = object(value);
  if (s.type === "object") {
    const props = object(s.properties);
    if (s.additionalProperties !== false || !Array.isArray(s.required) ||
        [...s.required].sort().join("|") !== Object.keys(props).sort().join("|")) return fail();
    for (const v of Object.values(props)) assertStrictSchema(v, depth + 1);
  } else if (s.type === "array") assertStrictSchema(s.items, depth + 1);
  else if (!(typeof s.type === "string" && ["string", "number", "integer", "boolean", "null"].includes(s.type)) &&
    !(Array.isArray(s.type) && s.type.length === 2 && s.type.includes("null") && s.type.every(v => ["string", "number", "integer", "boolean", "null"].includes(String(v))))) return fail();
}
