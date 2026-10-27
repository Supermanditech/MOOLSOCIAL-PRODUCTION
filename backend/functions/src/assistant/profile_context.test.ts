import test from "node:test";
import assert from "node:assert/strict";
import {AccountProfileService, type AccountProfileAccount} from "../account/profile_service.js";
import {AccountPlansService} from "../account/plans_service.js";
import {InMemoryWorkspaceProfileRepository, WorkspaceProfileService, type WorkspaceProfileRecord} from "../workspace/workspace_profile_service.js";
import type {WorkspaceMembershipRecord} from "../workspace/workspace_membership_contract.js";
import type {PreparationRequest} from "./model_contract.js";
import {ProfileWorkspacePreparationContext} from "./profile_context.js";

const actor = {uid: "context-owner", projectId: "host-fixture-project"};
const at = new Date("2026-10-27T08:00:00.000Z");
const personal = {audience: "personal" as const, storeId: null};
const input: PreparationRequest = {scope: personal, requestId: "context-request", requestRevision: 1,
  message: "मेरा नाम बदलें", language: "Auto", history: [], expectedEntitlementRevision: "personal:null:1:1", actionId: null, entityId: null};
/** Original production services, isolated host repositories; never device data. */
async function fixture() {
  let profileReads = 0, writes = 0, state = "active", changedDuringRead = false, now = new Date(at);
  const account: AccountProfileAccount = {uid: actor.uid, status: "ACTIVE", profile: {ownerUid: actor.uid, revision: 3,
    updatedAt: "2026-10-27T00:00:00.000Z", displayName: "Host fixture owner", selectedAddressId: "address-a",
    addresses: [{id: "address-a", label: "Home", kind: "home", recipient: "Private recipient", phone: "9999999999", line: "Private street", area: "Jodhpur", pinCode: "342001", landmark: ""}],
    invoiceProfiles: [{id: "invoice-a", legalName: "Private business", gstin: "", billingAddress: "Private billing street", registration: "unregistered"}]}};
  const profile = new AccountProfileService({async readAccount() {
    profileReads++; if (changedDuringRead && profileReads % 2 === 0) Object.assign(account.profile!, {revision: account.profile!.revision + 1});
    return structuredClone(account);
  }, async readReceipt() {return undefined;}, async commit() {writes++; throw new Error("No fixture write permitted");}}, actor.projectId, () => now);
  const repository = new InMemoryWorkspaceProfileRepository();
  const records: WorkspaceProfileRecord[] = ["a", "b"].map(suffix => ({schemaVersion: 1, caseId: `case-${suffix}`, ownerUserId: actor.uid,
    familyId: "products-trade", profileId: "retailer-grocery", name: `Host fixture Store ${suffix}`, area: "Jodhpur", primaryActivity: "Fixture",
    proofReferences: {"personal-kyc": "private-proof-not-model-data"}, alternateMobileVerified: false,
    idempotencyKey: `key-${suffix}`, requestFingerprint: `fingerprint-${suffix}`, status: "approved", plan: "free",
    createdAt: "2026-10-26T00:00:00.000Z", updatedAt: "2026-10-26T00:00:00.000Z", workspaceId: `store-${suffix}`}));
  for (const record of records) await repository.createOrRead(record);
  let memberships: WorkspaceMembershipRecord[] = records.map(record => ({schemaVersion: 1, membershipId: `member-${record.workspaceId}`,
    accountId: actor.uid, workspaceId: record.workspaceId!, workspaceProfileId: record.profileId, state: "active", version: 1,
    grantedAt: "2026-10-26T00:00:00.000Z"}));
  const workspaces = new WorkspaceProfileService(repository, () => now, undefined, {async readAccount() {return structuredClone(memberships);}});
  const plans = new AccountPlansService({async read(uid, scope) {return {ownerUid: uid, accountStatus: "ACTIVE",
    catalogue: {audience: scope.audience, revision: 1, state: "approved", offers: []},
    subscription: {ownerUid: uid, scope, revision: 1, planId: "host-fixture-plan", planVersion: "v1", name: "Host fixture", state,
      validFrom: "2026-10-26T00:00:00.000Z", validUntil: "2026-10-28T00:00:00.000Z", featureIds: ["mool_ai"]}};}},
  {projectId: actor.projectId, now: () => now, readWorkspaces: a => workspaces.listWorkspaces(a.uid)});
  const context = new ProfileWorkspacePreparationContext({profile, plans, workspaces: a => workspaces.listWorkspaces(a.uid), now: () => now});
  return {context, account, plans, workspaces, repository, records,
    counts: () => ({profileReads, writes}), state: (value: string) => {state = value;},
    memberships: (value: WorkspaceMembershipRecord[]) => {memberships = value;},
    revoke: () => {memberships = memberships.map(m => ({...m, state: "revoked", version: m.version + 1}));},
    changed: () => {changedDuringRead = true;}, advance: (ms: number) => {now = new Date(now.getTime() + ms);}};
}
test("THIN-B03 original Profile/Plans services expose minimal preparation context without writes", async () => {
  const f = await fixture(), result = await f.context.read(actor, input);
  assert.equal(result.revision, "profile:3");
  assert.deepEqual(result.modelContext, {audience: "personal", displayName: "Host fixture owner", deliveryChoices: [{id: "address-a", label: "Home", area: "Jodhpur"}]});
  const text = JSON.stringify(result.modelContext);
  for (const privateValue of ["9999999999", "Private street", "Private business", "Private billing street", "private-proof", actor.uid]) assert.ok(!text.includes(privateValue));
  assert.equal(f.counts().writes, 0);
  assert.ok(result.tools.every(t => t.sourceRevision === "profile:3"));
});
test("THIN-B03 name and address native schemas accept only their original fields", async () => {
  const f = await fixture(), result = await f.context.read(actor, input);
  const name = result.tools.find(t => t.actionId === "AI-ACT-197")!;
  assert.equal(name.validate({displayName: "मोहन"}), true); assert.equal(name.validate({displayName: "मोहन", admin: true}), false);
  assert.deepEqual(name.decodeFields!({displayName: "  राम   कुमार  "}), {displayName: "राम कुमार"});
  const view = result.tools.find(t => t.actionId === "AI-ACT-196")!;
  assert.equal(view.validate({section: ["identity"]}), false);
  const address = result.tools.find(t => t.actionId === "AI-ACT-025")!;
  const raw = {recipient: "मोहन", phone: null, line: null, area: "Jodhpur", pinCode: null, landmark: null, kind: null};
  const fields = address.decodeFields!(raw); assert.deepEqual(fields, {recipient: "मोहन", area: "Jodhpur"}); assert.equal(address.validate(fields), true);
  assert.equal(address.validate({kind: "home"}), false);
  const edit = result.tools.find(t => t.actionId === "AI-ACT-026")!;
  assert.equal(edit.entityId, "address-a"); assert.equal(edit.validate({kind: "work"}), true);
});
for (const state of ["pending", "expired", "revoked"]) test(`THIN-B03 ${state} entitlement reads no private Profile`, async () => {
  const f = await fixture(); f.state(state);
  await assert.rejects(f.context.read(actor, input), {code: "ai_access_required"}); assert.equal(f.counts().profileReads, 0);
});
test("THIN-B03 foreign project/tenant and restricted/foreign Profile are rejected", async () => {
  const f = await fixture();
  await assert.rejects(f.context.read({...actor, projectId: "other"}, input));
  await assert.rejects(f.context.read({...actor, tenantId: "other"}, input));
  Object.assign(f.account, {status: "RESTRICTED"}); await assert.rejects(f.context.read(actor, input));
  Object.assign(f.account, {status: "ACTIVE", uid: "other-owner"}); await assert.rejects(f.context.read(actor, input));
});
test("THIN-B03 missing/foreign entity and unrelated capabilities cannot be substituted", async () => {
  const f = await fixture();
  await assert.rejects(f.context.read(actor, {...input, actionId: "AI-ACT-026", entityId: "foreign-address"}), {code: "context_unavailable"});
  await assert.rejects(f.context.read(actor, {...input, actionId: "AI-ACT-213"}), {code: "context_unavailable"});
});
test("THIN-B03 Profile changes across original-source awaits retire preparation", async () => {
  const f = await fixture(); f.changed(); await assert.rejects(f.context.read(actor, input), {code: "stale_preparation"});
});
test("THIN-B03 selected operation omits unrelated contact and invoice data", async () => {
  const f = await fixture(), result = await f.context.read(actor, {...input, actionId: "AI-ACT-210"});
  assert.deepEqual(result.modelContext, {audience: "personal"}); assert.equal(result.tools.length, 1);
});
test("THIN-B03 real B03 approved/free readback supplies Store choices, not personal records", async () => {
  const f = await fixture(), scope = {audience: "workspace" as const, storeId: "store-a"};
  const result = await f.context.read(actor, {...input, scope, actionId: "AI-ACT-317"});
  assert.equal(result.tools.length, 2); assert.deepEqual(result.tools.map(t => t.entityId), ["store-a", "store-b"]);
  const target = result.tools[1]!; assert.equal(target.validate({workspaceId: "store-b"}), true); assert.equal(target.validate({workspaceId: "foreign"}), false);
  assert.equal((result.modelContext!.current as {id: string}).id, "store-a");
  assert.equal(f.counts().profileReads, 0); assert.ok(!JSON.stringify(result.modelContext).includes("private-proof"));
  f.state("expired"); await assert.rejects(f.context.read(actor, {...input, scope}));
  const original = (await f.workspaces.listWorkspaces(actor.uid)).workspaces[0] as {plan: string; access: {state: string}};
  assert.equal(original.plan, "free"); assert.equal(original.access.state, "active");
});
test("THIN-B03 revoked membership and pending/rejected/suspended approval reject Store context", async () => {
  const scope = {audience: "workspace" as const, storeId: "store-a"};
  const f = await fixture(); f.revoke(); await assert.rejects(f.context.read(actor, {...input, scope}));
  for (const status of ["pending", "rejected", "suspended"]) {
    const current = await fixture(); await current.repository.update("case-a", actor.uid, {status});
    await assert.rejects(current.context.read(actor, {...input, scope}));
  }
});
