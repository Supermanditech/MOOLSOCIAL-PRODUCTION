import test from "node:test";
import assert from "node:assert/strict";
import {handleAssistantHistoryRequest, type AssistantHistoryHttpDependencies} from "./history_http.js";
import {AssistantHistoryService} from "./history_service.js";
import {AccountPlansService} from "../account/plans_service.js";
import type {HistoryRepository} from "./history_dataconnect_store.js";
function fixture() {
  let calls = 0, consume: boolean | undefined;
  const deps: AssistantHistoryHttpDependencies = {projectId: "fixture-project", enabled: true,
    service: {async handle() {calls++; return {ownerKey: "fixture-only", scope: {audience: "personal", storeId: null}, items: [], nextCursor: null};}},
    async verifyAppCheck(_token, used) {consume = used; return {};},
    async verifyIdToken() {return {uid: "host-owner", projectId: "fixture-project"};}};
  const input = {method: "POST", headers: {authorization: "Bearer host-fixture", "x-firebase-appcheck": "host-proof"}, bodyBytes: 200,
    body: {operation: "list", payload: {scope: {audience: "personal", storeId: null}, cursor: null}}};
  return {deps, input, calls: () => calls, consumed: () => consume};
}
test("History HTTP read uses verified current identity and a non-consuming proof", async () => {
  const f = fixture(); assert.equal((await handleAssistantHistoryRequest(f.input, f.deps)).status, 200);
  assert.equal(f.calls(), 1); assert.equal(f.consumed(), false);
});
test("History HTTP Save consumes a fresh proof, without a generic domain write route", async () => {
  const f = fixture(), payload = {scope: f.input.body.payload.scope, requestId: "save-a", clientKey: "editor-a",
    conversationId: null, expectedRevision: 0, draft: "Host private draft", language: "English", messages: []};
  assert.equal((await handleAssistantHistoryRequest({...f.input, body: {operation: "save", payload}}, f.deps)).status, 200);
  assert.equal(f.consumed(), true);
  const rejected = await handleAssistantHistoryRequest({...f.input, body: {operation: "save", payload}},
    {...f.deps, verifyAppCheck: async () => ({alreadyConsumed: true})});
  assert.equal(rejected.status, 401); assert.equal(f.calls(), 1);
});
for (const headers of [{}, {authorization: "Bearer host-fixture"}, {"x-firebase-appcheck": "host-proof"}]) {
  test("History HTTP missing identity/proof makes no private source call", async () => {
    const f = fixture(); assert.equal((await handleAssistantHistoryRequest({...f.input, headers}, f.deps)).status, 401); assert.equal(f.calls(), 0);
  });
}
for (const principal of [{uid: "host-owner", projectId: "other-project"}, {uid: "host-owner", projectId: "fixture-project", tenantId: "tenant"},
  {uid: "host-owner", projectId: "fixture-project", anonymous: true}]) {
  test("History HTTP foreign/anonymous principal cannot use private History", async () => {
    const f = fixture(); assert.equal((await handleAssistantHistoryRequest(f.input, {...f.deps, verifyIdToken: async () => principal})).status, 401); assert.equal(f.calls(), 0);
  });
}
test("History HTTP disabled, absent source, malformed, oversize and wrong method stay closed", async () => {
  const f = fixture();
  assert.equal((await handleAssistantHistoryRequest(f.input, {...f.deps, enabled: false})).status, 503);
  const {service: _service, ...withoutSource} = f.deps;
  assert.equal((await handleAssistantHistoryRequest(f.input, withoutSource)).status, 503);
  assert.equal((await handleAssistantHistoryRequest({...f.input, method: "GET"}, f.deps)).status, 405);
  assert.equal((await handleAssistantHistoryRequest({...f.input, bodyBytes: 3 * 1024 * 1024}, f.deps)).status, 413);
  assert.equal((await handleAssistantHistoryRequest({...f.input, body: {...f.input.body, ownerUid: "foreign"}}, f.deps)).status, 400);
  assert.equal(f.calls(), 0);
});
test("History HTTP reuses actual original Plans enforcement before repository access", async () => {
  const f = fixture(); let calls = 0;
  const plans = new AccountPlansService({async read(ownerUid) {return {ownerUid, accountStatus: "ACTIVE", subscription: null,
    catalogue: {audience: "personal", revision: 1, state: "approved", offers: []}};}}, {projectId: "fixture-project"});
  const repository = {async list() {calls++; return [];}} as unknown as HistoryRepository;
  const service = new AssistantHistoryService({projectId: "fixture-project", plans, repository});
  assert.equal((await handleAssistantHistoryRequest(f.input, {...f.deps, service})).status, 403); assert.equal(calls, 0);
});
