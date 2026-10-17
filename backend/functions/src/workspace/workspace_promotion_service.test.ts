import assert from "node:assert/strict";
import test from "node:test";
import {randomUUID} from "node:crypto";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {FirestorePromotionRepository, WorkspacePromotionService, planPromotionSave,
  type PromotionCommand, type PromotionRecord, type PromotionReceipt,
  type PromotionRepository} from "./workspace_promotion_service.js";
import type {WorkspaceProfileRecord} from "./workspace_profile_service.js";

// Isolated host/emulator records, never evaluation data injected into a phone.
const at = "2026-10-17T01:00:00.000Z", until = "2026-10-18T01:00:00.000Z";
const profile = {schemaVersion: 1, caseId: "host-case", workspaceId: "store-one", ownerUserId: "owner-one",
  familyId: "products-trade", profileId: "retailer-grocery", name: "Host Store", status: "live", shopEnabled: true} as WorkspaceProfileRecord;
const sku = {schemaVersion: 1, storeId: "store-one", skuId: "sku-one", revision: 1,
  publicListing: true, canonicalProductId: "canonical-one", verifiedPackId: "pack-one",
  channels: [{kind: "retail", offerId: "offer-one"}]};
function body(changes: Record<string, unknown> = {}) {
  return {storeId: "store-one", placementId: "promotion-one", expectedRevision: 0,
    idempotencyKey: "original-one", promotion: {skuId: "sku-one", skuRevision: 1, channel: "retail",
      headline: "Host product promotion", detail: "No applied discount or targeted message.",
      validFrom: at, validUntil: until, active: true}, ...changes};
}
class Memory implements PromotionRepository {
  readonly realm = "evaluation" as const;
  profile: WorkspaceProfileRecord | undefined = structuredClone(profile);
  sku: unknown = structuredClone(sku);
  now = at;
  records = new Map<string, PromotionRecord>();
  receipts = new Map<string, PromotionReceipt>();
  writes = 0;
  async store() {return this.profile;}
  async save(command: PromotionCommand) {
    const key = `${command.ownerUserId}/${command.idempotencyKey}`;
    const receipt = this.receipts.get(key);
    const record = planPromotionSave(command, this.profile, this.sku,
      this.records.get(command.placementId), receipt, this.now);
    if (!receipt) {this.records.set(record.placementId, record);
      this.receipts.set(key, {fingerprint: command.fingerprint, record}); this.writes++;}
    return structuredClone(record);
  }
  async read(storeId: string, placementId: string, userId?: string) {
    if (!this.profile || this.profile.workspaceId !== storeId || this.profile.status !== "live" ||
        userId !== undefined && userId !== this.profile.ownerUserId || userId === undefined && !this.profile.shopEnabled) throw Error("unavailable");
    return structuredClone(this.records.get(placementId));
  }
  async page(storeId: string, after: string | undefined, limit: number, userId?: string) {
    await this.read(storeId, "unused", userId);
    return [...this.records.values()].filter(r => !after || r.placementId > after)
      .sort((a, b) => a.placementId.localeCompare(b.placementId)).slice(0, limit).map(r => structuredClone(r));
  }
  async reconcile(command: PromotionCommand) {
    const receipt = this.receipts.get(`${command.ownerUserId}/${command.idempotencyKey}`);
    return receipt ? planPromotionSave(command, this.profile, undefined, this.records.get(command.placementId), receipt, this.now) : undefined;
  }
}
function source() {
  const row = {skuId: "sku-one", canonicalProductId: "canonical-one", verifiedPackId: "pack-one",
    sku: "HOST-SKU", revision: 1, observedAt: at, content: {title: "Host item"}, pack: {label: "1 pack"},
    channels: [{kind: "retail", offerId: "offer-one", revision: "terms-one", validUntil: "2026-10-17T02:00:00.000Z"}]};
  return {schemaVersion: 1, realm: "evaluation", storeId: "store-one", state: "ready",
    orderingAvailable: false, observedAt: at, coverage: "verified_public_only", items: [row], nextCursor: null};
}
function service(repository: PromotionRepository, read = async (_body: Readonly<Record<string, unknown>>) => source()) {
  return new WorkspacePromotionService(repository, {publicCatalogue: read}, () => new Date(at));
}
test("public promotions require a real persistent producer", () => {
  assert.equal(typeof FirestorePromotionRepository.prototype.save, "function");
  assert.equal(typeof FirestorePromotionRepository.prototype.reconcile, "function");
});
test("promotion API provides owner lifecycle and separate public readback entry", () => {
  assert.equal(typeof (WorkspacePromotionService.prototype as unknown as Record<string, unknown>).handleOperation, "function");
});
test("owner API keeps absent read, saved acknowledgement, original lookup and public read distinct", async () => {
  const repository = new Memory(), subject = service(repository);
  const empty = await subject.handleOperation("owner-one", "readStorePromotion", {storeId: "store-one", placementId: "promotion-one"}) as {record: unknown};
  assert.equal(empty.record, null);
  const saved = await subject.handleOperation("owner-one", "saveStorePromotion", body()) as {record: PromotionRecord; publicationConfirmed: boolean};
  assert.equal(saved.record.revision, 1); assert.equal(saved.publicationConfirmed, false);
  assert.deepEqual((await subject.handleOperation("owner-one", "reconcileStorePromotion", body()) as {record: unknown}).record, saved.record);
  const missing = await subject.handleOperation("owner-one", "reconcileStorePromotion", body({idempotencyKey: "unknown-key"})) as {record: unknown};
  assert.equal(missing.record, null); assert.equal(repository.writes, 1);
  const listed = await subject.handleOperation("owner-one", "listStorePromotions", {storeId: "store-one", limit: 20}) as {items: PromotionRecord[]};
  assert.equal(listed.items.length, 1);
  await assert.rejects(subject.handleOperation("other-owner", "listStorePromotions", {storeId: "store-one", limit: 20}));
  const publicResult = await subject.handleOperation("another-buyer", "readPublicStorePromotions", {storeId: "store-one", limit: 20}) as {items: unknown[]};
  assert.equal(publicResult.items.length, 1);
  await assert.rejects(subject.handleOperation("owner-one", "inventDiscount", body()));
  await assert.rejects(subject.handleOperation("owner-one", "readStorePromotion", {storeId: "store-one", placementId: "promotion-one", ownerUserId: "other-owner"}));
});
test("exact immutable source, explicit copy and CAS revision; no commerce result", async () => {
  const repository = new Memory(), input = body();
  const pending = service(repository).save("owner-one", input);
  input.promotion.headline = "Changed after call";
  const saved = await pending;
  assert.equal(saved.headline, "Host product promotion"); assert.equal(saved.revision, 1);
  assert.equal(saved.skuId, "sku-one"); assert.equal(saved.skuRevision, 1);
  assert.equal(saved.realm, "evaluation"); assert.equal(saved.observedAt, at);
  assert.doesNotMatch(JSON.stringify(saved), /savingAmount|messagesAllowed|owner-one|orderCap/u);
});
test("original receipts are readonly historical results after update, withdrawal and expiry", async () => {
  const repository = new Memory(), subject = service(repository);
  const original = await subject.save("owner-one", body());
  const next = body({expectedRevision: 1, idempotencyKey: "next-one"}); next.promotion.active = false;
  await subject.save("owner-one", next);
  repository.sku = undefined; repository.now = "2026-10-20T00:00:00.000Z";
  assert.deepEqual(await subject.reconcile("owner-one", body()), original);
  assert.deepEqual(await subject.save("owner-one", body()), original);
  assert.equal(await subject.reconcile("owner-one", body({idempotencyKey: "never-sent"})), undefined);
  assert.equal(repository.records.get("promotion-one")?.active, false); assert.equal(repository.writes, 2);
  const changed = body(); changed.promotion.detail = "Changed original";
  await assert.rejects(subject.reconcile("owner-one", changed), {code: "conflict"});
});
for (const [label, change] of Object.entries<(m: Memory, b: ReturnType<typeof body>) => void>({
  "foreign owner": m => {m.profile!.ownerUserId = "another-owner";},
  "inactive Store": m => {m.profile!.status = "suspended";},
  "foreign SKU": m => {m.sku = {...sku, storeId: "another-store"};},
  "changed SKU revision": m => {m.sku = {...sku, revision: 2};},
  "private SKU": m => {m.sku = {...sku, publicListing: false};},
  "missing channel": (_, b) => {b.promotion.channel = "bulk";},
  "invented benefit": (_, b) => {Object.assign(b.promotion, {savingAmount: 100});},
  "invented audience": (_, b) => {Object.assign(b.promotion, {audience: "opted-in"});},
  "invented cap": (_, b) => {Object.assign(b.promotion, {orderCap: 10});},
  "expired": (_, b) => {b.promotion.validUntil = at;},
  "reversed validity": (_, b) => {b.promotion.validFrom = until;},
})) test(`${label} cannot create a promotional publication`, async () => {
  const repository = new Memory(), input = body(); change(repository, input);
  await assert.rejects(service(repository).save("owner-one", input)); assert.equal(repository.writes, 0);
});
test("different same-revision commands conflict; initial owner lookup grants no later authority", async () => {
  const repository = new Memory(), subject = service(repository);
  await subject.save("owner-one", body());
  const race = await Promise.allSettled([subject.save("owner-one", body({expectedRevision: 1, idempotencyKey: "race-one"})),
    subject.save("owner-one", body({expectedRevision: 1, idempotencyKey: "race-two"}))]);
  assert.equal(race.filter(r => r.status === "fulfilled").length, 1);
  repository.store = async () => {const prior = structuredClone(repository.profile); repository.profile!.ownerUserId = "new-owner"; return prior;};
  await assert.rejects(subject.save("owner-one", body({expectedRevision: 2, idempotencyKey: "late-owner"})));
});
test("public promotion comes only from current eligible exact source; validity clips to selling terms", async () => {
  const repository = new Memory(), subject = service(repository);
  await subject.save("owner-one", body());
  const result = await subject.publicPage({storeId: "store-one", limit: 1});
  assert.equal(result.state, "ready"); assert.equal(result.items.length, 1);
  const item = result.items[0]!;
  assert.equal(item.validUntil, "2026-10-17T02:00:00.000Z");
  assert.equal(item.publisherId, "store-one"); assert.equal(item.publisherName, "Host Store");
  assert.equal(item.publisherType, "retailer", "publisher role must match the accepted Buy enum, not a channel or generic supplier");
  assert.equal(item.product.skuId, "sku-one"); assert.equal(item.product.channels.length, 1);
  assert.equal(result.nextCursor, "promotion-one");
  assert.doesNotMatch(JSON.stringify(result), /owner-one|host-case|idempotency|fingerprint|savingAmount|orderCap/u);
  const end = await subject.publicPage({storeId: "store-one", limit: 1, after: result.nextCursor});
  assert.equal(end.items.length, 0); assert.equal(end.nextCursor, null);
});
test("withdrawn/paused/stale/foreign/expired source cannot appear; missing source is unavailable", async () => {
  const repository = new Memory(); await service(repository).save("owner-one", body());
  for (const mode of ["hidden", "changed", "foreign", "expired", "unavailable", "failure", "paused"]) {
    repository.records.get("promotion-one")!.active = mode !== "paused";
    const subject = service(repository, async () => {
      if (mode === "failure") throw Error("private source diagnostics");
      const response = source();
      if (mode === "hidden") response.items = [];
      if (mode === "changed") response.items[0]!.revision = 2;
      if (mode === "foreign") response.items[0]!.skuId = "foreign-sku";
      if (mode === "expired") response.items[0]!.channels[0]!.validUntil = at;
      if (mode === "unavailable") response.state = "unavailable";
      return response;
    });
    const result = await subject.publicPage({storeId: "store-one", limit: 10});
    assert.equal(result.items.length, 0, mode);
    if (["failure", "unavailable"].includes(mode)) assert.equal(result.state, "unavailable");
    assert.doesNotMatch(JSON.stringify(result), /diagnostics/u);
  }
});
test("scope or pause changing during source await never exposes old publication", async () => {
  const repository = new Memory(); await service(repository).save("owner-one", body());
  const subject = service(repository, async () => {repository.records.get("promotion-one")!.active = false; return source();});
  assert.equal((await subject.publicPage({storeId: "store-one", limit: 10})).items.length, 0);
});
test("malformed persisted channel cannot escape owner readback by string coercion", async () => {
  const repository = new Memory(), subject = service(repository);
  await subject.save("owner-one", body());
  Object.assign(repository.records.get("promotion-one")!, {channel: ["retail"]});
  await assert.rejects(subject.readOwned("owner-one", {storeId: "store-one", placementId: "promotion-one"}));
});
test("Firestore emulator: restart, atomic CAS, original lookup and realm isolation", async t => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) {t.skip("Explicit loopback emulator required"); return;}
  assert.match(host, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-promotion"}, `promotion-${randomUUID()}`), db = getFirestore(app);
  const suffix = randomUUID().replaceAll("-", ""), storeId = `store-${suffix}`, caseId = `case-${suffix}`;
  const root = db.collection("workspaceCatalogues").doc("evaluation").collection("stores").doc(storeId);
  await db.collection("workspaceProfiles").doc(caseId).create({...profile, workspaceId: storeId, caseId});
  await root.collection("skus").doc("sku-one").create({...sku, storeId});
  const input = body({storeId});
  try {
    const repository = new FirestorePromotionRepository(db, "evaluation", () => new Date(at));
    const subject = service(repository), first = await subject.save("owner-one", input);
    const restarted = service(new FirestorePromotionRepository(db, "evaluation", () => new Date(at)));
    assert.deepEqual(await restarted.readOwned("owner-one", {storeId, placementId: "promotion-one"}), first);
    const race = await Promise.allSettled([restarted.save("owner-one", {...input, expectedRevision: 1, idempotencyKey: "race-one"}),
      restarted.save("owner-one", {...input, expectedRevision: 1, idempotencyKey: "race-two"})]);
    assert.equal(race.filter(r => r.status === "fulfilled").length, 1);
    assert.deepEqual(await restarted.reconcile("owner-one", input), first);
    assert.equal(await restarted.reconcile("owner-one", {...input, idempotencyKey: "missing-original"}), undefined);
    assert.equal(await service(new FirestorePromotionRepository(db, "production")).readOwned("owner-one", {storeId, placementId: "promotion-one"}), undefined);
    const withdrawalRace = service(repository, async () => {
      const response = source(); response.storeId = storeId;
      await root.collection("skus").doc("sku-one").update({publicListing: false});
      return response;
    });
    assert.equal((await withdrawalRace.publicPage({storeId, limit: 10})).items.length, 0,
      "source withdrawn during catalogue await must not remain a visible promotion");
    const head = root.collection("promotions").doc("promotion-one");
    await head.update({placementId: "different-promotion"});
    await assert.rejects(restarted.readOwned("owner-one", {storeId, placementId: "promotion-one"}));
    await head.update({placementId: "promotion-one"});
    await db.collection("workspaceProfiles").doc(caseId).update({ownerUserId: "other-owner"});
    await assert.rejects(restarted.reconcile("owner-one", input));
  } finally {await deleteApp(app);}
});
