import test from "node:test";
import assert from "node:assert/strict";
import {canonicalContextOwner, canonicalContextProjection, canonicalContextRequest,
  contextReadSelection, searchSuggestion} from "./domain_context_contract.js";
import type {PreparationContext} from "./model_contract.js";
const scope = {audience: "personal" as const, storeId: null};
const actor = {projectId: "host-fixture-project", uid: "host-a"};
test("Domain context read accepts only its exact read-only scope envelope", () => {
  assert.deepEqual(canonicalContextRequest({operation: "read", payload: {scope}}), {scope});
  for (const bad of [{operation: "save", payload: {scope}}, {operation: "read", payload: {scope, actionIds: ["arbitrary"]}},
    {operation: "read", payload: {scope: {...scope, admin: true}}}]) assert.throws(() => canonicalContextRequest(bad));
});
test("Domain canonical owner binds project account and exact Personal or Store context", () => {
  const a = canonicalContextOwner(actor, scope);
  for (const [who, where] of [[{...actor, uid: "host-b"}, scope], [{...actor, projectId: "another-project"}, scope],
    [actor, {audience: "workspace", storeId: "store-a"}] ] as const) assert.notEqual(canonicalContextOwner(who, where), a);
});
test("Domain source query has no History, consent or dispatched operation identity", () => {
  const q = contextReadSelection(scope); assert.deepEqual(q.history, []); assert.equal(q.actionId, null);
  assert.equal(q.entityId, null); assert.equal(q.expectedEntitlementRevision, "source-read-only");
});
test("Domain metadata projection omits private records tools and fields and rejects ambiguous keys", () => {
  const tool = {name: "host_tool", actionId: "AI-ACT-001", entityId: null, sourceRevision: "source:1",
    description: "Private source detail", parameters: {private: "not-returned"}, validate: () => true};
  const c: PreparationContext = {revision: "source:1", validUntil: "2026-10-28T08:00:00.000Z",
    tools: [tool], modelContext: {private: "not-returned"}};
  const p = canonicalContextProjection(actor, scope, c);
  assert.deepEqual(p.revisions, [{actionId: "AI-ACT-001", entityId: null, sourceRevision: "source:1"}]);
  assert.ok(!JSON.stringify(p).includes("not-returned"));
  assert.throws(() => canonicalContextProjection(actor, scope, {...c, tools: [tool, tool]}));
});
test("Domain product-search suggestion uses only exact native query and length", () => {
  assert.deepEqual(searchSuggestion({query: "  चावल   5 kg "}), {query: "चावल 5 kg"});
  for (const value of [{query: "x"}, {query: "x".repeat(81)}, {query: 10}, {query: "rice", admin: true},
    {query: "rice\u0000"}, {query: "rice\ud800"}]) assert.throws(() => searchSuggestion(value));
});

test("Domain original listing selection is only a typed read hint", () => {
  const ids = ["listing-" + "a".repeat(64)];
  assert.deepEqual(canonicalContextRequest({operation: "read", payload: {scope, catalogueListingIds: ids}}),
    {scope, catalogueListingIds: ids});
  assert.deepEqual(contextReadSelection(scope, ids).catalogueListingIds, ids);
  assert.throws(() => canonicalContextRequest({operation: "read", payload: {scope,
    catalogueListingIds: [{listingId: ids[0], admin: true}]}}));
});
test("Domain metadata exposes201 exact native targets without201 model functions", () => {
  const targets = Array.from({length: 201}, (_, n) => ({actionId: "AI-ACT-006",
    entityId: "listing-" + n.toString(16).padStart(64, "0"), sourceRevision: "record:" + n}));
  const c: PreparationContext = {revision: "catalogue:1", validUntil: "2026-10-28T08:01:00.000Z",
    nativeTargets: targets, tools: [{name: "registered_selector", actionId: "AI-ACT-006", entityId: null,
      sourceRevision: "catalogue:1", description: "Original typed product selector", parameters: {}, validate: () => true}]};
  const value = canonicalContextProjection(actor, scope, c);
  assert.equal(value.revisions.length, 201); assert.deepEqual(value.revisions, targets);
  assert.ok(value.revisions.every(t => t.entityId !== null));
});
