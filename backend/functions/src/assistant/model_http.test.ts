import test from "node:test";
import assert from "node:assert/strict";
import {handleAssistantModelRequest, type AssistantModelHttpDependencies} from "./model_http.js";
import {AssistantPreparationService} from "./model_service.js";
import {AccountPlansService} from "../account/plans_service.js";
function fixture() {
  let reads = 0;
  const projectId = "fixture-project";
  const plans = new AccountPlansService({async read(ownerUid) {reads++; return {ownerUid, accountStatus: "ACTIVE", subscription: null,
    catalogue: {audience: "personal", revision: 1, state: "approved", offers: []}};}}, {projectId});
  const deps: AssistantModelHttpDependencies = {projectId, enabled: true, service: new AssistantPreparationService({plans, projectId}),
    async verifyAppCheck(_token, consume) {assert.equal(consume, false); return {};},
    async verifyIdToken() {return {uid: "fixture-owner", projectId};}};
  const input = {method: "POST", headers: {authorization: "Bearer fixture-token", "x-firebase-appcheck": "fixture-proof"}, bodyBytes: 150,
    body: {operation: "prepare", payload: {scope: {audience: "personal", storeId: null}, requestId: "fixture-id", requestRevision: 1,
      message: "चावल", language: "Auto", expectedEntitlementRevision: "personal:null:1:1", history: [], actionId: null, entityId: null}}};
  return {deps, input, reads: () => reads};
}
test("AI-B01 HTTP paid enforcement uses actual Plans service", async () => {
  const f = fixture(); const result = await handleAssistantModelRequest(f.input, f.deps);
  assert.equal(result.status, 403); assert.equal(result.body.ok, false); assert.equal(f.reads(), 1);
});
for (const headers of [{}, {authorization: "Bearer fixture-token"}, {"x-firebase-appcheck": "fixture-proof"}]) test("AI-B01 HTTP missing auth/AppCheck has no source/model calls", async () => {
  const f = fixture(); assert.equal((await handleAssistantModelRequest({...f.input, headers}, f.deps)).status, 401); assert.equal(f.reads(), 0);
});
for (const principal of [{uid: "fixture-owner", projectId: "other"}, {uid: "fixture-owner", projectId: "fixture-project", anonymous: true}, {uid: "fixture-owner", projectId: "fixture-project", tenantId: "foreign"}]) test("AI-B01 HTTP rejects foreign/anonymous principal", async () => {
  const f = fixture(); const result = await handleAssistantModelRequest(f.input, {...f.deps, verifyIdToken: async () => principal});
  assert.equal(result.status, 401); assert.equal(f.reads(), 0);
});
test("AI-B01 HTTP disabled/malformed/oversize/GET stay unavailable without a source read", async () => {
  const f = fixture(); assert.equal((await handleAssistantModelRequest(f.input, {...f.deps, enabled: false})).status, 503);
  assert.equal((await handleAssistantModelRequest({...f.input, method: "GET"}, f.deps)).status, 405);
  assert.equal((await handleAssistantModelRequest({...f.input, bodyBytes: 65537}, f.deps)).status, 413);
  assert.equal((await handleAssistantModelRequest({...f.input, body: {...f.input.body, ownerUid: "other"}}, f.deps)).status, 400);
  assert.equal(f.reads(), 0);
});
