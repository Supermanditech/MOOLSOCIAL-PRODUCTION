import test from "node:test";
import assert from "node:assert/strict";
import {handleAccountPlansRequest, type AccountPlansHttpDependencies, type AccountPlansHttpInput} from "./plans_http.js";
import {AccountPlansService} from "./plans_service.js";

function fixture() {
  let reads = 0;
  const proofModes: boolean[] = [];
  const deps: AccountPlansHttpDependencies = {projectId: "fixture-project", storageQualified: true,
    verifyAppCheck: async (_token, consume) => {proofModes.push(consume); return {};},
    verifyIdToken: async () => ({uid: "fixture-owner", projectId: "fixture-project"}),
    service: new AccountPlansService({async read(ownerUid) {
      reads++; return {ownerUid, accountStatus: "ACTIVE", subscription: null,
        catalogue: {audience: "personal", state: "approved", revision: 1, offers: []}};
    }}, {projectId: "fixture-project"})};
  const input: AccountPlansHttpInput = {method: "POST", headers: {authorization: "Bearer fixture-token", "x-firebase-appcheck": "fixture-proof"},
    body: {operation: "read", payload: {audience: "personal", storeId: null}}, bodyBytes: 80};
  return {deps, input, reads: () => reads, proofModes};
}
test("B02 HTTP: verified read uses token principal and standard read App Check", async () => {
  const f = fixture(); const r = await handleAccountPlansRequest(f.input, f.deps);
  assert.equal(r.status, 200); assert.deepEqual(f.proofModes, [false]); assert.equal(f.reads(), 1);
});
for (const headers of [{}, {authorization: "Bearer fixture-token"}, {"x-firebase-appcheck": "fixture-proof"}]) {
  test(`B02 HTTP: missing credential ${JSON.stringify(headers)}`, async () => {
    const f = fixture(); assert.equal((await handleAccountPlansRequest({...f.input, headers}, f.deps)).status, 401); assert.equal(f.reads(), 0);
  });
}
for (const principal of [{uid: "fixture-owner", projectId: "foreign-project"},
  {uid: "fixture-owner", projectId: "fixture-project", anonymous: true},
  {uid: "fixture-owner", projectId: "fixture-project", tenantId: "foreign-tenant"}]) {
  test(`B02 HTTP: invalid principal ${JSON.stringify(principal)}`, async () => {
    const f = fixture(); const r = await handleAccountPlansRequest(f.input, {...f.deps, verifyIdToken: async () => principal});
    assert.equal(r.status, 401); assert.equal(f.reads(), 0);
  });
}
for (const body of [null, [], {operation: "upgrade", payload: {}},
  {operation: "read", payload: {audience: "personal", storeId: "foreign-store"}},
  {operation: "read", payload: {audience: "workspace", storeId: null}},
  {operation: "read", payload: {audience: "personal", storeId: null, ownerUid: "other"}},
  {operation: "read", payload: {audience: "personal", storeId: null}, ownerUid: "other"}]) {
  test(`B02 HTTP: body cannot nominate an owner or mutate billing ${JSON.stringify(body)}`, async () => {
    const f = fixture(); assert.equal((await handleAccountPlansRequest({...f.input, body}, f.deps)).status, 400); assert.equal(f.reads(), 0);
  });
}
test("B02 HTTP: disabled qualification flag remains unavailable after valid auth", async () => {
  const f = fixture(); assert.equal((await handleAccountPlansRequest(f.input, {...f.deps, storageQualified: false})).status, 503); assert.equal(f.reads(), 0);
});
test("B02 HTTP: malformed/oversized method and body fail before repository", async () => {
  const f = fixture(); assert.equal((await handleAccountPlansRequest({...f.input, method: "GET"}, f.deps)).status, 405);
  assert.equal((await handleAccountPlansRequest({...f.input, bodyBytes: 4097}, f.deps)).status, 413); assert.equal(f.reads(), 0);
});
test("B02 HTTP: repository errors are sanitized and never reported as an empty/free plan", async () => {
  const f = fixture(); const service = new AccountPlansService({async read() {throw new Error("private fixture database details");}}, {projectId: "fixture-project"});
  const r = await handleAccountPlansRequest(f.input, {...f.deps, service});
  assert.equal(r.status, 503); assert.equal(r.body.ok, false); assert.ok(!JSON.stringify(r.body).includes("private fixture"));
});
