import test from "node:test";
import assert from "node:assert/strict";
import {canonicalContextOwner, canonicalContextProjection, canonicalContextRequest,
  contextReadSelection, searchSuggestion, storeNativeSelection, maskedNativeHints} from "./domain_context_contract.js";
import type {PreparationContext, PreparationNativeTarget} from "./model_contract.js";
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

test('Store compact metadata preserves5003 original anchors and stable owner/proof ordering within byte bounds', () => {
  const where = {audience: 'workspace' as const, storeId: 'store-one'};
  const nativeTargets: PreparationNativeTarget[] = Array.from({length: 1250}, (_, n) => ['AI-ACT-214', 'AI-ACT-221', 'AI-ACT-370', 'AI-ACT-220']
    .map(actionId => ({actionId, entityId: `owned-sku-${n}`, sourceRevision: `store-owned-product:evaluation:1:${n}`}))).flat();
  for (const actionId of ['AI-ACT-218', 'AI-ACT-219', 'AI-ACT-372']) nativeTargets.push({actionId, entityId: null, sourceRevision: `owner:${actionId}`});
  const context: PreparationContext = {revision: 'original', validUntil: '2026-10-28T08:01:00.000Z', tools: [], nativeTargets};
  assert.throws(() => canonicalContextProjection(actor, where, context), /context_unavailable/u, 'Legacy bound stays intact');
  const projected = canonicalContextProjection(actor, where, context, 1);
  assert.ok('nativeSelection' in projected); if (!('nativeSelection' in projected)) return;
  assert.equal(projected.nativeSelection.groups.length, 1253);
  assert.equal(projected.nativeSelection.groups.reduce((n, group) => n + group.actionIds.length, 0), 5003);
  assert.ok(Buffer.byteLength(JSON.stringify(projected), 'utf8') < 2 * 1024 * 1024);
  const selected = storeNativeSelection(actor, where, context);
  assert.equal(storeNativeSelection(actor, where, {...context, nativeTargets: [...nativeTargets].reverse()}).fingerprint, selected.fingerprint);
  assert.notEqual(storeNativeSelection({...actor, uid: 'foreign'}, where, context).fingerprint, selected.fingerprint);
  assert.notEqual(storeNativeSelection(actor, where, {...context, nativeTargets: nativeTargets.map((t, i) => i === 0 ? {...t, sourceRevision: 'changed'} : t)}).fingerprint, selected.fingerprint);
  const bytes = Buffer.alloc(Math.ceil(selected.targets.length / 8)); bytes[0] = 1;
  const request = {...contextReadSelection(where), nativeTargets: [], nativeTargetMask: {version: 1 as const, fingerprint: selected.fingerprint, bits: bytes.toString('base64url')}};
  assert.deepEqual(maskedNativeHints(actor, context, request), [{actionId: selected.targets[0]!.actionId, entityId: selected.targets[0]!.entityId}]);
  assert.ok(Buffer.byteLength(JSON.stringify({operation: 'prepare', payload: request}), 'utf8') < 64 * 1024);
});

test('Store mask rejects stale ownership, legacy overlap, bad trailing bits, duplicate sources and unsupported selection reads', () => {
  const where = {audience: 'workspace' as const, storeId: 'store-one'};
  const context: PreparationContext = {revision: 'original', validUntil: '2026-10-28T08:01:00.000Z', tools: [],
    nativeTargets: [{actionId: 'AI-ACT-214', entityId: 'sku-one', sourceRevision: 'source-one'}]};
  const selected = storeNativeSelection(actor, where, context);
  const request = {...contextReadSelection(where), nativeTargetMask: {version: 1 as const, fingerprint: selected.fingerprint, bits: 'AQ'}};
  assert.deepEqual(maskedNativeHints(actor, context, request), [{actionId: 'AI-ACT-214', entityId: 'sku-one'}]);
  for (const bits of ['', 'Ag', 'AQA']) assert.throws(() => maskedNativeHints(actor, context, {...request, nativeTargetMask: {...request.nativeTargetMask, bits}}));
  assert.throws(() => maskedNativeHints({...actor, uid: 'foreign'}, context, request), /stale_preparation/u);
  assert.throws(() => maskedNativeHints(actor, context, {...request, nativeTargets: [{actionId: 'AI-ACT-214', entityId: 'sku-one'}]}));
  assert.throws(() => storeNativeSelection(actor, where, {...context, nativeTargets: [...context.nativeTargets!, ...context.nativeTargets!]}));
  assert.deepEqual(canonicalContextRequest({operation: 'read', payload: {scope: where, nativeSelectionVersion: 1}}), {scope: where, nativeSelectionVersion: 1});
  for (const bad of [{scope, nativeSelectionVersion: 1}, {scope: where, nativeSelectionVersion: 2}]) {
    assert.throws(() => canonicalContextRequest({operation: 'read', payload: bad}));
  }
});


test('Domain retained quote read hints are bounded exact buyer-owned identifiers, never agreement writes', () => {
  const ids = ['bulk-' + 'a'.repeat(64), 'bulk-' + 'b'.repeat(64)];
  assert.deepEqual(canonicalContextRequest({operation: 'read', payload: {scope, retainedSupplierQuoteIds: ids}}),
    {scope, retainedSupplierQuoteIds: ids});
  assert.deepEqual(contextReadSelection(scope, undefined, ids).nativeTargets,
    ids.map(entityId => ({actionId: 'AI-ACT-349', entityId})));
  assert.deepEqual(contextReadSelection(scope, undefined, []).nativeTargets, []);
  for (const bad of [null, {}, ['bulk-short'], [ids[0], ids[0]], [1], [{quoteId: ids[0]}],
    Array.from({length: 501}, (_, n) => 'bulk-' + n.toString(16).padStart(64, '0'))]) {
    assert.throws(() => canonicalContextRequest({operation: 'read', payload: {scope, retainedSupplierQuoteIds: bad}}));
  }
  const workspace = {audience: 'workspace' as const, storeId: 'host-store'};
  assert.throws(() => canonicalContextRequest({operation: 'read', payload: {scope: workspace, retainedSupplierQuoteIds: ids}}));
  assert.throws(() => contextReadSelection(workspace, undefined, ids));
  assert.throws(() => canonicalContextRequest({operation: 'read', payload: {scope, retainedSupplierQuoteIds: ids, acceptQuote: true}}));
});


test('AGG02 typed preview opt-in stays explicit through the read-only context query', () => {
  const where = {audience: 'workspace' as const, storeId: 'store-one'};
  assert.deepEqual(canonicalContextRequest({operation: 'read', payload: {scope: where}}), {scope: where});
  assert.deepEqual(canonicalContextRequest({operation: 'read', payload: {scope: where, nativeProductPreviewVersion: 1}}),
    {scope: where, nativeProductPreviewVersion: 1});
  assert.equal(Object.hasOwn(contextReadSelection(where), 'nativeProductPreviewVersion'), false);
  assert.equal(contextReadSelection(where, undefined, undefined, 1).nativeProductPreviewVersion, 1);
  for (const value of [null, true, 0, 2, '1']) assert.throws(() => canonicalContextRequest({operation: 'read',
    payload: {scope: where, nativeProductPreviewVersion: value}}));
  assert.throws(() => canonicalContextRequest({operation: 'read', payload: {scope, nativeProductPreviewVersion: 1}}));
});
