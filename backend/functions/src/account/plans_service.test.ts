import test from "node:test";
import assert from "node:assert/strict";
import {AccountPlansService, type PlansRepositorySnapshot, type PlansScope} from "./plans_service.js";
import {InMemoryWorkspaceProfileRepository, WorkspaceProfileService, type WorkspaceProfileRecord} from "../workspace/workspace_profile_service.js";

const at = "2026-10-27T08:00:00.000Z";
const actor = {uid: "fixture-owner", projectId: "fixture-project"};
const personal: PlansScope = {audience: "personal", storeId: null};
const workspace: PlansScope = {audience: "workspace", storeId: "fixture-store"};
function offer(id = "fixture-plan") { return {id, version: "v1", name: "Host-only fixture plan", priceLabel: "Fixture price",
  features: ["Fixture benefit"], featureIds: ["mool_ai"], eligible: true, recommended: false}; }
function setup(scope = personal) {
  const row: PlansRepositorySnapshot = {ownerUid: actor.uid, accountStatus: "ACTIVE",
    catalogue: {audience: scope.audience, revision: 1, state: "approved", offers: [offer()]},
    subscription: {ownerUid: actor.uid, scope, revision: 1, planId: "fixture-plan", planVersion: "v1", name: "Host-only fixture plan",
      state: "active", validFrom: "2026-10-27T00:00:00.000Z", validUntil: "2026-10-28T00:00:00.000Z", featureIds: ["mool_ai"]}};
  let time = new Date(at), reads = 0;
  const repository = {async read(uid: string, requested: PlansScope) {
    assert.equal(uid, actor.uid); assert.deepEqual(requested, scope); reads++; return structuredClone(row);
  }};
  const service = new AccountPlansService(repository, {projectId: actor.projectId, now: () => time});
  return {row, repository, service, setTime: (value: string) => {time = new Date(value);}, reads: () => reads};
}
test("B02 service: approved personal read returns assigned-version benefits and bounded authority", async () => {
  const f = setup(); const result = await f.service.read(actor, personal);
  assert.deepEqual(result.owner, {userId: actor.uid, projectId: actor.projectId});
  assert.deepEqual(result.activeFeatureIds, ["mool_ai"]);
  assert.equal(result.validUntil, "2026-10-27T08:01:00.000Z");
});
test("B02 service: a later catalogue version never changes assigned subscription benefits", async () => {
  const f = setup(); (f.row.catalogue as {offers: unknown[]}).offers = [{...offer(), version: "v2", features: ["Changed current marketing"]}];
  assert.equal((await f.service.read(actor, personal)).subscription?.planVersion, "v1");
  assert.deepEqual((await f.service.read(actor, personal)).activeFeatureIds, ["mool_ai"]);
});
test("B02 service: any supported catalogue count, including empty, is not hardcoded to card count", async () => {
  const f = setup(); const cat = f.row.catalogue as {offers: unknown[]};
  cat.offers = Array.from({length: 251}, (_, i) => offer(`fixture-${i}`));
  assert.equal((await f.service.read(actor, personal)).offers.length, 251);
  cat.offers = []; assert.equal((await f.service.read(actor, personal)).offers.length, 0);
});
for (const state of ["pending", "expired", "revoked"]) {
  test(`B02 service: ${state} cannot grant paid access`, async () => {
    const f = setup(); (f.row.subscription as {state: string}).state = state;
    assert.deepEqual((await f.service.read(actor, personal)).activeFeatureIds, []);
  });
}
test("B02 service: cancellation respects confirmed paid-through date and expiry", async () => {
  const f = setup(); (f.row.subscription as {state: string}).state = "cancelled";
  assert.deepEqual((await f.service.read(actor, personal)).activeFeatureIds, ["mool_ai"]);
  f.setTime("2026-10-28T00:00:00.000Z"); assert.deepEqual((await f.service.read(actor, personal)).activeFeatureIds, []);
});
test("B02 service: missing assignment is distinct from unavailable catalogue", async () => {
  const f = setup(); Object.assign(f.row, {subscription: null});
  const result = await f.service.read(actor, personal); assert.equal(result.subscriptionRevision, 0); assert.deepEqual(result.activeFeatureIds, []);
  Object.assign(f.row, {catalogue: null}); await assert.rejects(f.service.read(actor, personal), {code: "plans_unavailable"});
});
for (const mutation of [
  (f: ReturnType<typeof setup>) => Object.assign(f.row, {ownerUid: "foreign-owner"}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row, {accountStatus: "RESTRICTED"}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row.subscription as object, {ownerUid: "foreign-owner"}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row.subscription as object, {scope: workspace}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row.subscription as object, {state: "unknown"}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row.subscription as object, {validUntil: "not-a-date"}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row.subscription as object, {featureIds: ["mool_ai", "mool_ai"]}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row.catalogue as object, {offers: [offer(), offer()]}),
  (f: ReturnType<typeof setup>) => Object.assign(f.row.catalogue as object, {state: "draft"}),
]) {
  test(`B02 service: corrupt/cross-scope snapshot rejected ${mutation.toString()}`, async () => {
    const f = setup(); mutation(f); await assert.rejects(f.service.read(actor, personal));
  });
}
for (const wrong of [{...actor, projectId: "other-project"}, {...actor, tenantId: "foreign"}]) {
  test(`B02 service: principal mismatch ${JSON.stringify(wrong)}`, async () => {
    const f = setup(); await assert.rejects(f.service.read(wrong, personal), {code: "account_scope_mismatch"}); assert.equal(f.reads(), 0);
  });
}
test("B02 service: existing B03 service readback permits only the actual approved Store", async () => {
  const f = setup(workspace);
  const repo = new InMemoryWorkspaceProfileRepository();
  const profile: WorkspaceProfileRecord = {schemaVersion: 1, caseId: "fixture-case", ownerUserId: actor.uid,
    familyId: "products-trade", profileId: "retailer-grocery", name: "Fixture store", area: "Fixture area", primaryActivity: "Fixture",
    proofReferences: {}, alternateMobileVerified: false, idempotencyKey: "fixture-key", requestFingerprint: "fixture-hash",
    status: "approved", plan: "free", createdAt: "2026-10-26T00:00:00.000Z", updatedAt: "2026-10-26T00:00:00.000Z", workspaceId: workspace.storeId!};
  await repo.createOrRead(profile);
  let revoked = false;
  const readback = new WorkspaceProfileService(repo, () => new Date(at), undefined, {async readAccount(accountId) {
    return [{schemaVersion: 1, membershipId: "fixture-member", accountId, workspaceId: workspace.storeId!,
      workspaceProfileId: profile.profileId, state: revoked ? "revoked" : "active", version: revoked ? 2 : 1,
      grantedAt: "2026-10-26T00:00:00.000Z", ...(revoked ? {revokedAt: at} : {})}];
  }});
  const service = new AccountPlansService(f.repository, {projectId: actor.projectId, now: () => new Date(at),
    readWorkspaces: who => readback.listWorkspaces(who.uid)});
  assert.deepEqual((await service.read(actor, workspace)).activeFeatureIds, ["mool_ai"]);
  const assigned = f.row.subscription;
  Object.assign(f.row, {subscription: null});
  assert.deepEqual((await service.read(actor, workspace)).activeFeatureIds, []);
  assert.equal(((await readback.listWorkspaces(actor.uid)).workspaces[0] as {access: {state: string}}).access.state, "active");
  Object.assign(f.row, {subscription: {...assigned as object, state: "expired"}});
  assert.deepEqual((await service.read(actor, workspace)).activeFeatureIds, []);
  assert.equal(((await readback.listWorkspaces(actor.uid)).workspaces[0] as {access: {state: string}}).access.state, "active");
  revoked = true; await assert.rejects(service.read(actor, workspace));
  assert.equal(f.reads(), 3);
});
test("B02 service: absent Store authority cannot be replaced by a paid subscription", async () => {
  const f = setup(workspace); await assert.rejects(f.service.read(actor, workspace), {code: "workspace_access_unavailable"}); assert.equal(f.reads(), 0);
});
