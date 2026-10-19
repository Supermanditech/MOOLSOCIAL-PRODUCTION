import assert from "node:assert/strict";
import test from "node:test";
import {randomUUID} from "node:crypto";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {FirestoreSupplierPolicyRepository, WorkspaceSupplierPolicyService, planSupplierPolicySave,
  type SupplierPolicyCommand, type SupplierPolicyRecord, type SupplierPolicyReceipt,
  type SupplierPolicyRepository} from "./workspace_supplier_policy_service.js";
import type {WorkspaceProfileRecord} from "./workspace_profile_service.js";

// Isolated host/emulator fixtures, never native Store records or commercial consent.
const at = "2026-10-17T01:00:00.000Z", until = "2026-10-18T01:00:00.000Z";
const store = {schemaVersion: 1, caseId: "case-host", ownerUserId: "owner-one", workspaceId: "store-one",
  familyId: "products-trade", profileId: "retailer-grocery", status: "live", shopEnabled: true} as WorkspaceProfileRecord;
function sku(skuId = "sku-one", storeId = "store-one") {
  return {schemaVersion: 1, storeId, skuId, canonicalProductId: `canonical-${skuId}`,
    verifiedPackId: `pack-${skuId}`, revision: 1, publicListing: true};
}
function input(changes: Record<string, unknown> = {}) {
  return {storeId: "store-one", expectedRevision: 0, idempotencyKey: "policy-original", policy: {
    title: "Host Store terms", body: "Isolated host policy. No commercial agreement.",
    productIds: ["sku-one"], requiresAcceptance: true, validUntil: until}, ...changes};
}
class Memory implements SupplierPolicyRepository {
  readonly realm = "evaluation" as const;
  profile: WorkspaceProfileRecord | undefined = structuredClone(store);
  current: SupplierPolicyRecord | undefined;
  now = at;
  skus = new Map<string, unknown>([["sku-one", sku()]]);
  receipts = new Map<string, SupplierPolicyReceipt>();
  lastCommand: SupplierPolicyCommand | undefined;
  async store() {return this.profile;}
  async save(command: SupplierPolicyCommand) {
    this.lastCommand = command;
    const key = `${command.ownerUserId}/${command.idempotencyKey}`;
    const receipt = this.receipts.get(key);
    const result = planSupplierPolicySave(command, this.profile, this.skus, this.current, receipt, this.now);
    if (!receipt) {this.current = result; this.receipts.set(key, {fingerprint: command.fingerprint, record: result});}
    return structuredClone(result);
  }
  async read() {return this.current && structuredClone(this.current);}
  async reconcile(command: SupplierPolicyCommand) {
    const receipt = this.receipts.get(`${command.ownerUserId}/${command.idempotencyKey}`);
    return receipt ? planSupplierPolicySave(command, this.profile, new Map(), this.current, receipt, this.now) : undefined;
  }
}
function service(repository: SupplierPolicyRepository, now = () => new Date(at)) {
  return new WorkspaceSupplierPolicyService(repository, now);
}

for (const profileId of ['wholesaler', 'manufacturer']) {
  test(`LF04-PUBLISHERS supplier policy remains exact-Store and SKU scoped ${profileId}`, async () => {
    const repository = new Memory(); repository.profile!.profileId = profileId;
    const subject = service(repository);
    const original = await subject.save('owner-one', input());
    assert.deepEqual(await service(repository).reconcile('owner-one', input()), original);
    const publicPolicy = await service(repository).forPublicSku('store-one', 'sku-one');
    assert.equal(publicPolicy.state, 'ready');
    assert.equal(publicPolicy.storeId, 'store-one');
    assert.deepEqual(publicPolicy.policy!.productIds, ['sku-one']);
    await assert.rejects(subject.save('other-owner', input()), {code: 'not_found'});
    repository.profile!.status = 'pending';
    await assert.rejects(subject.save('owner-one', input()));
  });
}

test("supplier policy has a persistent local producer rather than native fixtures", () => {
  assert.equal(typeof FirestoreSupplierPolicyRepository.prototype.save, "function");
  assert.equal(typeof FirestoreSupplierPolicyRepository.prototype.reconcile, "function");
});
test("owner policy API entry preserves read/save/original-reconcile separation", () => {
  assert.equal(typeof (WorkspaceSupplierPolicyService.prototype as unknown as Record<string, unknown>).handleOwnerOperation, "function");
});
test("owner API empty read, exact saved response and missing original have distinct semantics", async () => {
  const repository = new Memory(), subject = service(repository);
  assert.deepEqual(await subject.handleOwnerOperation("owner-one", "readStoreSupplierPolicy", {storeId: "store-one"}), {
    schemaVersion: 1, realm: "evaluation", storeId: "store-one", record: null, publicAvailabilityConfirmed: false});
  const saved = await subject.handleOwnerOperation("owner-one", "saveStoreSupplierPolicy", input()) as {record: SupplierPolicyRecord};
  assert.equal(saved.record.revision, 1);
  assert.deepEqual((await subject.handleOwnerOperation("owner-one", "reconcileStoreSupplierPolicy", input()) as {record: unknown}).record, saved.record);
  const missing = await subject.handleOwnerOperation("owner-one", "reconcileStoreSupplierPolicy", input({idempotencyKey: "unknown-original"})) as {record: unknown};
  assert.equal(missing.record, null); assert.equal(repository.receipts.size, 1);
  await assert.rejects(subject.handleOwnerOperation("owner-one", "readStoreSupplierPolicy", {storeId: "store-one", ownerUserId: "owner-two"}));
  await assert.rejects(subject.handleOwnerOperation("owner-two", "readStoreSupplierPolicy", {storeId: "store-one"}), {code: "not_found"});
  await assert.rejects(subject.handleOwnerOperation("owner-one", "inventConsent", input()));
});
test("exact source IDs, explicit acceptance, immutable input and server version are retained", async () => {
  const repository = new Memory(), body = input();
  const pending = service(repository).save("owner-one", body);
  body.policy.body = "Mutated caller copy";
  const result = await pending;
  assert.equal(result.revision, 1); assert.equal(result.realm, "evaluation");
  assert.equal(result.storeId, "store-one"); assert.equal(result.publishedAt, at);
  assert.equal(result.requiresAcceptance, true); assert.match(result.body, /Isolated host policy/u);
  assert.deepEqual(result.productIds, ["sku-one"]);
  assert.notEqual(result.id, body.idempotencyKey);
});
test("original replay and read-only reconciliation do not revert newer text or renew expiry", async () => {
  const repository = new Memory(), subject = service(repository);
  const original = await subject.save("owner-one", input());
  const next = input({expectedRevision: 1, idempotencyKey: "policy-next"});
  next.policy.body = "Updated explicit host policy";
  await subject.save("owner-one", next);
  repository.now = "2026-10-19T00:00:00.000Z";
  repository.skus.clear();
  const late = service(repository, () => new Date(repository.now));
  assert.deepEqual(await late.save("owner-one", input()), original);
  assert.deepEqual(await late.reconcile("owner-one", input()), original);
  assert.equal(repository.current?.revision, 2);
  assert.equal(repository.current?.body, next.policy.body);
  assert.equal(await late.reconcile("owner-one", input({idempotencyKey: "missing-original"})), undefined);
});
test("changed original conflicts and concurrent same-revision requests cannot both replace the head", async () => {
  const repository = new Memory(), subject = service(repository);
  await subject.save("owner-one", input());
  const changed = input(); changed.policy.requiresAcceptance = false;
  await assert.rejects(subject.save("owner-one", changed), {code: "conflict"});
  const results = await Promise.allSettled([subject.save("owner-one", input({expectedRevision: 1, idempotencyKey: "update-one"})),
    subject.save("owner-one", input({expectedRevision: 1, idempotencyKey: "update-two"}))]);
  assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
  assert.equal(repository.current?.revision, 2);
});
test("ownership and policy expiry are rechecked after the initial service lookup", async () => {
  for (const revoke of [true, false]) {
    const repository = new Memory();
    repository.store = async () => {
      const observed = structuredClone(repository.profile);
      if (revoke) repository.profile!.ownerUserId = "owner-two";
      else repository.now = until;
      return observed;
    };
    await assert.rejects(service(repository).save("owner-one", input()), {code: revoke ? "not_found" : "invalid_input"});
    assert.equal(repository.current, undefined);
  }
});
for (const [name, mutate] of Object.entries<(r: Memory, b: ReturnType<typeof input>) => void>({
  "foreign owner": r => {r.profile!.ownerUserId = "owner-two";},
  "suspended Store": r => {r.profile!.status = "suspended";},
  "foreign SKU": r => {r.skus.set("sku-one", sku("sku-one", "store-two"));},
  "missing SKU": r => {r.skus.clear();},
  "duplicate scope": (_, b) => {b.policy.productIds = ["sku-one", "sku-one"];},
  "invented revision": (_, b) => {Object.assign(b.policy, {revision: "approved-by-client"});},
  "invalid acceptance": (_, b) => {Object.assign(b.policy, {requiresAcceptance: "false"});},
  "invalid expiry": (_, b) => {b.policy.validUntil = "not-a-date";},
  "expired new policy": (_, b) => {b.policy.validUntil = at;},
  "empty text": (_, b) => {b.policy.body = "";},
})) {
  test(`${name} cannot create a policy`, async () => {
    const repository = new Memory(), body = input(); mutate(repository, body);
    await assert.rejects(service(repository).save("owner-one", body));
    assert.equal(repository.current, undefined); assert.equal(repository.receipts.size, 0);
  });
}
test("public policy is exact-SKU scoped; expiry and failed reads never become optional consent", async () => {
  const repository = new Memory(), subject = service(repository);
  repository.skus.set("sku-two", sku("sku-two"));
  const body = input(); body.policy.productIds = ["sku-two", "sku-one"];
  await subject.save("owner-one", body);
  const one = await subject.forPublicSku("store-one", "sku-one");
  const two = await subject.forPublicSku("store-one", "sku-two");
  assert.equal(one.state, "ready"); assert.deepEqual(one.policy!.productIds, ["sku-one"]);
  assert.notEqual(one.policy!.id, two.policy!.id);
  assert.doesNotMatch(JSON.stringify(one), /owner-one|case-host|sku-two|fingerprint/u);
  const expired = await service(repository, () => new Date(until)).forPublicSku("store-one", "sku-one");
  assert.equal(expired.state, "unavailable"); assert.equal(expired.requiresAcceptance, true); assert.equal(expired.policy, null);
  repository.read = async () => {throw new Error("isolated read failure");};
  const failed = await subject.forPublicSku("store-one", "sku-one");
  assert.equal(failed.state, "unavailable"); assert.equal(failed.requiresAcceptance, null);
});
test("only an authoritative absent/non-applicable current policy means acceptance not required", async () => {
  const repository = new Memory(), subject = service(repository);
  assert.equal((await subject.forPublicSku("store-one", "sku-one")).state, "none");
  await subject.save("owner-one", input());
  assert.equal((await subject.forPublicSku("store-one", "sku-two")).state, "none");
  repository.profile!.shopEnabled = false;
  assert.equal((await subject.forPublicSku("store-one", "sku-one")).requiresAcceptance, null);
});
test("malformed persisted policy cannot become an optional-public-policy claim", async () => {
  const repository = new Memory(), subject = service(repository);
  await subject.save("owner-one", input());
  repository.current!.publishedAt = "not-a-time";
  const result = await subject.forPublicSku("store-one", "sku-one");
  assert.equal(result.state, "unavailable"); assert.equal(result.requiresAcceptance, null);
  assert.equal(result.revision, null); assert.equal(result.policy, null);
});
test("Firestore emulator: policy CAS, scope, receipt recovery, restart and realm separation", async t => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) {t.skip("Explicit local Firestore emulator required"); return;}
  assert.match(host, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-policy"}, `supplier-policy-${randomUUID()}`);
  const db = getFirestore(app), suffix = randomUUID().replaceAll("-", "");
  const workspace = `store-${suffix}`, caseId = `case-${suffix}`, skuId = `sku-${suffix}`;
  const profile = {...store, workspaceId: workspace, caseId};
  const storeRef = db.collection("workspaceProfiles").doc(caseId);
  const root = db.collection("workspaceCatalogues").doc("evaluation").collection("stores").doc(workspace);
  await storeRef.create(profile);
  await root.collection("skus").doc(skuId).create(sku(skuId, workspace));
  let clock = new Date(at);
  const subject = service(new FirestoreSupplierPolicyRepository(db, "evaluation", () => clock), () => clock);
  const body = input({storeId: workspace}); body.policy.productIds = [skuId];
  try {
    const first = await subject.save("owner-one", body);
    assert.equal(first.revision, 1);
    const restarted = service(new FirestoreSupplierPolicyRepository(db, "evaluation", () => clock), () => clock);
    assert.deepEqual(await restarted.readOwned("owner-one", workspace), first);
    const results = await Promise.allSettled([restarted.save("owner-one", {...body, expectedRevision: 1, idempotencyKey: "race-one"}),
      restarted.save("owner-one", {...body, expectedRevision: 1, idempotencyKey: "race-two"})]);
    assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
    const source = root.collection("supplierPolicies").doc("current");
    assert.equal((await source.collection("revisions").get()).size, 2);
    const before = (await source.get()).data();
    clock = new Date("2026-10-19T00:00:00.000Z");
    assert.deepEqual(await restarted.reconcile("owner-one", body), first);
    assert.deepEqual((await source.get()).data(), before);
    assert.equal((await restarted.forPublicSku(workspace, skuId)).requiresAcceptance, true);
    assert.equal((await service(new FirestoreSupplierPolicyRepository(db, "production")).forPublicSku(workspace, skuId)).state,
      "unavailable");
    const changed = structuredClone(body); changed.policy.body = "Changed original";
    await assert.rejects(restarted.reconcile("owner-one", changed), {code: "conflict"});
    await storeRef.update({ownerUserId: "owner-two"});
    await assert.rejects(restarted.reconcile("owner-one", body), {code: "not_found"});
    assert.equal((await source.collection("revisions").get()).size, 2);
  } finally {await deleteApp(app);}
});
