import {decodePlansScope, type PlansScope} from "../account/plans_service.js";
import type {AccountProfileActor} from "../account/profile_service.js";
import {catalogueListingSelection, digest, fail, id, object, text, type PreparationContext, type PreparationRequest} from "./model_contract.js";

// Register a domain only after its original reader and native fields have been
// qualified. Neither a client's action list nor model text registers a tool.
export const catalogueProductActions = new Set(["AI-ACT-006", "AI-ACT-007", "AI-ACT-009", "AI-ACT-336", "AI-ACT-337", "AI-ACT-338", "AI-ACT-339"]);
export const nativePreferenceActions = new Set(["AI-ACT-010", "AI-ACT-011", "AI-ACT-012", "AI-ACT-013"]);
export const catalogueSearchActions = new Set(["AI-ACT-001", "AI-ACT-002", "AI-ACT-003", "AI-ACT-004", "AI-ACT-005", ...catalogueProductActions]);
export function canonicalContextRequest(value: unknown): {scope: PlansScope; catalogueListingIds?: readonly string[]} {
  const request = object(value, ["operation", "payload"]);
  if (request.operation !== "read") return fail("invalid_request", 400);
  const raw = object(request.payload);
  const payload = object(raw, ["scope", ...(Object.hasOwn(raw, "catalogueListingIds") ? ["catalogueListingIds"] : [])]);
  return {scope: decodePlansScope(payload.scope), ...(Object.hasOwn(payload, "catalogueListingIds") ?
    {catalogueListingIds: catalogueListingSelection(payload.catalogueListingIds)} : {})};
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
export function canonicalContextProjection(actor: AccountProfileActor, scope: PlansScope,
  context: PreparationContext) {
  const seen = new Set<string>();
  const targets = context.nativeTargets ?? context.tools;
  if (targets.length > 5000) return fail("context_unavailable");
  const revisions = targets.map(tool => {
    if (!/^AI-ACT-\d{3}$/u.test(tool.actionId)) return fail("context_unavailable");
    if (tool.entityId !== null) id(tool.entityId);
    text(tool.sourceRevision, 256);
    const key = JSON.stringify([tool.actionId, tool.entityId]);
    if (seen.has(key)) return fail("context_unavailable");
    seen.add(key);
    return {actionId: tool.actionId, entityId: tool.entityId, sourceRevision: tool.sourceRevision};
  });
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
