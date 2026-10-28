import {decodePlansScope, type PlansScope} from "../account/plans_service.js";
import type {AccountProfileActor} from "../account/profile_service.js";
import {catalogueListingSelection, digest, fail, id, object, text, nativeTargetMaskSelection, type PreparationContext, type PreparationRequest, type PreparationNativeTarget} from "./model_contract.js";

// Register a domain only after its original reader and native fields have been
// qualified. Neither a client's action list nor model text registers a tool.
export const catalogueProductActions = new Set(["AI-ACT-006", "AI-ACT-007", "AI-ACT-009", "AI-ACT-336", "AI-ACT-337", "AI-ACT-338", "AI-ACT-339"]);
export const nativePreferenceActions = new Set(["AI-ACT-010", "AI-ACT-011", "AI-ACT-012", "AI-ACT-013"]);
export const storeProductActions = new Set(["AI-ACT-214", "AI-ACT-221", "AI-ACT-370", "AI-ACT-220"]);
export const storeProductDefaultActions = new Set(["AI-ACT-218", "AI-ACT-219"]);
export const storeProductOwnerReadActions = new Set(["AI-ACT-372"]);
export const storeProductOwnerActions = new Set([...storeProductDefaultActions, ...storeProductOwnerReadActions]);
export const storeNativeMaskActions = new Set([...storeProductActions, ...storeProductOwnerActions]);
export const catalogueSearchActions = new Set(["AI-ACT-001", "AI-ACT-002", "AI-ACT-003", "AI-ACT-004", "AI-ACT-005", ...catalogueProductActions]);
export function canonicalContextRequest(value: unknown): {scope: PlansScope; catalogueListingIds?: readonly string[]; nativeSelectionVersion?: 1} {
  const request = object(value, ["operation", "payload"]);
  if (request.operation !== "read") return fail("invalid_request", 400);
  const raw = object(request.payload);
  const payload = object(raw, ["scope", ...(Object.hasOwn(raw, "catalogueListingIds") ? ["catalogueListingIds"] : []),
    ...(Object.hasOwn(raw, "nativeSelectionVersion") ? ["nativeSelectionVersion"] : [])]);
  const scope = decodePlansScope(payload.scope);
  if (Object.hasOwn(payload, "nativeSelectionVersion") && (payload.nativeSelectionVersion !== 1 || scope.audience !== "workspace")) return fail("invalid_request", 400);
  return {scope, ...(Object.hasOwn(payload, "catalogueListingIds") ?
    {catalogueListingIds: catalogueListingSelection(payload.catalogueListingIds)} : {}),
    ...(Object.hasOwn(payload, "nativeSelectionVersion") ? {nativeSelectionVersion: 1 as const} : {})};
}
export function canonicalContextOwner(actor: AccountProfileActor, scope: PlansScope): string {
  return digest([actor.projectId, actor.uid, scope.audience, scope.storeId]);
}
export function contextReadSelection(scope: PlansScope, catalogueListingIds?: readonly string[]): PreparationRequest {
  // Pure source query only: never claimed in the preparation/usage store and
  // never dispatched to a model. These constants are not a saved operation.
  return {scope, requestId: "canonical-source-read", requestRevision: 0,
    expectedEntitlementRevision: "source-read-only", message: "Read current permitted sources",
    language: "English", history: [], actionId: null, entityId: null,
    ...(catalogueListingIds === undefined ? {} : {catalogueListingIds: catalogueListingSelection(catalogueListingIds)})};
}
function checkedTargets(context: PreparationContext, limit: number): PreparationNativeTarget[] {
  const seen = new Set<string>();
  const targets = context.nativeTargets ?? context.tools;
  if (targets.length > limit) return fail("context_unavailable");
  return targets.map(tool => {
    if (!/^AI-ACT-\d{3}$/u.test(tool.actionId)) return fail("context_unavailable");
    if (tool.entityId !== null) id(tool.entityId);
    text(tool.sourceRevision, 256);
    const key = JSON.stringify([tool.actionId, tool.entityId]);
    if (seen.has(key)) return fail("context_unavailable");
    seen.add(key);
    return {actionId: tool.actionId, entityId: tool.entityId, sourceRevision: tool.sourceRevision};
  });
}
/** Stable ASCII action/entity ordering; null sorts before a non-null entity. */
export function storeNativeSelection(actor: AccountProfileActor, scope: PlansScope, context: PreparationContext) {
  if (scope.audience !== "workspace") return fail("invalid_request", 400);
  const targets = checkedTargets(context, 15000).filter(target => storeNativeMaskActions.has(target.actionId));
  targets.sort((a, b) => a.actionId < b.actionId ? -1 : a.actionId > b.actionId ? 1 :
    a.entityId === b.entityId ? 0 : a.entityId === null ? -1 : b.entityId === null ? 1 : a.entityId < b.entityId ? -1 : 1);
  return {targets, fingerprint: digest([canonicalContextOwner(actor, scope), scope, targets])};
}
export function maskedNativeHints(actor: AccountProfileActor, context: PreparationContext, request: PreparationRequest) {
  if (request.nativeTargetMask === undefined) return [];
  const mask = nativeTargetMaskSelection(request.nativeTargetMask), selected = storeNativeSelection(actor, request.scope, context);
  if (mask.fingerprint !== selected.fingerprint) return fail("stale_preparation", 409);
  const bytes = Buffer.from(mask.bits, "base64url"), count = selected.targets.length;
  if (bytes.length !== Math.ceil(count / 8) || count % 8 !== 0 && (bytes.at(-1)! >> (count % 8)) !== 0 ||
      request.nativeTargets?.some(target => storeNativeMaskActions.has(target.actionId))) return fail("invalid_request", 400);
  return selected.targets.filter((_, index) => ((bytes[index >> 3] ?? 0) & (1 << (index % 8))) !== 0)
    .map(({actionId, entityId}) => ({actionId, entityId}));
}
export function canonicalContextProjection(actor: AccountProfileActor, scope: PlansScope,
  context: PreparationContext, nativeSelectionVersion?: 1) {
  const revisions = checkedTargets(context, nativeSelectionVersion === 1 ? 15000 : 5000);
  if (nativeSelectionVersion === 1) {
    const selection = storeNativeSelection(actor, scope, context), groups = new Map<string,
      {entityId: string | null; sourceRevision: string; actionIds: string[]}>();
    for (const target of selection.targets) {
      const key = JSON.stringify([target.entityId, target.sourceRevision]), group = groups.get(key);
      if (group) group.actionIds.push(target.actionId);
      else groups.set(key, {entityId: target.entityId, sourceRevision: target.sourceRevision, actionIds: [target.actionId]});
    }
    const legacy = revisions.filter(target => !storeNativeMaskActions.has(target.actionId));
    if (groups.size > 5000 || legacy.length > 5000) return fail("context_unavailable");
    return {ownerKey: canonicalContextOwner(actor, scope), scope, validUntil: context.validUntil, revisions: legacy,
      nativeSelection: {version: 1, fingerprint: selection.fingerprint, groups: [...groups.values()]}};
  }
  // Tool descriptions, parameters, records and model context stay server-side.
  return {ownerKey: canonicalContextOwner(actor, scope), scope,
    validUntil: context.validUntil, revisions};
}
export function searchSuggestion(fields: Readonly<Record<string, unknown>>): Readonly<Record<string, unknown>> {
  if (Object.keys(fields).length !== 1 || typeof fields.query !== "string") return fail("invalid_model_result");
  const query = fields.query.trim().replace(/\s+/gu, " ");
  if (query.length < 2 || query.length > 80 || /[\u0000-\u001f]/u.test(query) ||
      Buffer.from(query, "utf8").toString("utf8") !== query) return fail("invalid_model_result");
  return {query};
}
