import test from "node:test";
import assert from "node:assert/strict";
import {handleAssistantCanonicalContextRequest, type AssistantCanonicalContextHttpDependencies} from "./domain_context_http.js";
function fixture() {
  let calls = 0, consumed: boolean | undefined;
  const deps: AssistantCanonicalContextHttpDependencies = {projectId: "fixture-project", enabled: true,
    now: () => new Date("2026-10-28T08:00:00.000Z"),
    context: {async read(actor, input) {calls++; assert.equal(actor.uid, "host-owner"); assert.deepEqual(input.history, []);
      return {revision: "catalogue:1", validUntil: "2026-10-28T08:01:00.000Z",
        modelContext: {private: "not-for-client"}, tools: [{name: "original_query", actionId: "AI-ACT-001",
          entityId: null, sourceRevision: "catalogue:1", description: "Original source", parameters: {}, validate: () => true}]};}},
    async verifyAppCheck(_token, consume) {consumed = consume; return {};},
    async verifyIdToken() {return {uid: "host-owner", projectId: "fixture-project"};}};
  const input = {method: "POST", headers: {authorization: "Bearer host-token", "x-firebase-appcheck": "host-proof"},
    bodyBytes: 120, body: {operation: "read", payload: {scope: {audience: "personal", storeId: null}}}};
  return {deps, input, calls: () => calls, consumed: () => consumed};
}
test("Domain HTTP canonical read uses current authenticated actor and non-consuming proof", async () => {
  const f = fixture(), result = await handleAssistantCanonicalContextRequest(f.input, f.deps);
  assert.equal(result.status, 200); assert.equal(f.calls(), 1); assert.equal(f.consumed(), false);
  assert.ok(!JSON.stringify(result).includes("not-for-client"));
  assert.ok(result.body.ok && result.body.data.revisions[0]!.sourceRevision === "catalogue:1");
});
test("Domain HTTP missing auth or AppCheck cannot read source metadata", async () => {
  for (const headers of [{}, {authorization: "Bearer host-token"}]) {
    const f = fixture(); assert.equal((await handleAssistantCanonicalContextRequest({...f.input, headers}, f.deps)).status, 401);
    assert.equal(f.calls(), 0);
  }
});
test("Domain HTTP foreign anonymous or tenant principals cannot read metadata", async () => {
  for (const who of [{uid: "host-owner", projectId: "foreign-project"},
    {uid: "host-owner", projectId: "fixture-project", anonymous: true},
    {uid: "host-owner", projectId: "fixture-project", tenantId: "other"}]) {
    const f = fixture(); assert.equal((await handleAssistantCanonicalContextRequest(f.input,
      {...f.deps, verifyIdToken: async () => who})).status, 401); assert.equal(f.calls(), 0);
  }
});
test("Domain HTTP rejects client tools source records instructions and write operations", async () => {
  for (const body of [{operation: "save", payload: {scope: {audience: "personal", storeId: null}}},
    {operation: "read", payload: {scope: {audience: "personal", storeId: null}, tools: [{admin: true}]}},
    {operation: "read", payload: {scope: {audience: "personal", storeId: null}, source: "invented"}}]) {
    const f = fixture(); assert.equal((await handleAssistantCanonicalContextRequest({...f.input, body}, f.deps)).status, 400);
    assert.equal(f.calls(), 0);
  }
});
test("Domain HTTP disabled or absent qualified source remains unavailable", async () => {
  const f = fixture(); assert.equal((await handleAssistantCanonicalContextRequest(f.input, {...f.deps, enabled: false})).status, 503);
  const {context: _removed, ...without} = f.deps;
  assert.equal((await handleAssistantCanonicalContextRequest(f.input, without)).status, 503); assert.equal(f.calls(), 0);
});
test("Domain HTTP refuses expired source context", async () => {
  const f = fixture(); assert.equal((await handleAssistantCanonicalContextRequest(f.input,
    {...f.deps, now: () => new Date("2026-10-28T09:00:00.000Z")})).status, 409);
});
test("Domain HTTP does not reveal private failures", async () => {
  const f = fixture(), result = await handleAssistantCanonicalContextRequest(f.input,
    {...f.deps, context: {async read() {throw Error("private street/token/provider detail");}}});
  assert.equal(result.status, 503); assert.ok(!JSON.stringify(result).includes("private street"));
});
test("Domain HTTP bounds metadata requests and methods before any source read", async () => {
  const f = fixture();
  assert.equal((await handleAssistantCanonicalContextRequest({...f.input, bodyBytes: 65537}, f.deps)).status, 413);
  assert.equal((await handleAssistantCanonicalContextRequest({...f.input, method: "GET"}, f.deps)).status, 405);
  assert.equal(f.calls(), 0);
});

test("Domain HTTP forwards201 validated listing hints to the original reader without creating caller tools", async () => {
  const f = fixture(), ids = Array.from({length: 201}, (_, n) => "listing-" + n.toString(16).padStart(64, "0"));
  const original = f.deps.context!.read;
  f.deps.context!.read = async (actor, input) => {
    assert.deepEqual(input.catalogueListingIds, ids); assert.equal(input.actionId, null);
    return original(actor, input);
  };
  const body = {operation: "read", payload: {...f.input.body.payload, catalogueListingIds: ids}};
  const response = await handleAssistantCanonicalContextRequest({...f.input, body,
    bodyBytes: Buffer.byteLength(JSON.stringify(body), "utf8")}, f.deps);
  assert.equal(response.status, 200); assert.equal(f.calls(), 1);
});
