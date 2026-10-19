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

const discoveryQuery = {search: "", categoryId: "all", publisher: null, supplierOnly: false};
function discoveryFixture(options: {benefitTermsSupported?: boolean} = {}) {
  const repository = new Memory();
  let clock = at, directoryReads = 0;
  const row = {...source().items[0]!, listings: [{listingId: `listing-${"a".repeat(64)}`, channel: "retail"}]};
  const listing = {...source(), items: [row]};
  const catalogue = {
    publicCatalogue: async () => source(),
    publicDiscovery: async (request: Readonly<Record<string, unknown>>) => {
      directoryReads++;
      const shop = (request.query as {destination: string}).destination === "shop";
      return {schemaVersion: 1, discoveryPageVersion: 1, realm: "evaluation", state: "ready",
        coverage: "verified_public_only", directoryCoverage: "complete_bounded", orderingAvailable: false,
        observedAt: clock, query: request.query, resultKind: "products", requestedStore: null,
        items: shop ? [{channel: "retail", listing: structuredClone(listing)}] : [],
        page: {snapshotId: "b".repeat(64), startIndex: 0, totalCount: shop ? 1 : 0, previousCursor: null, nextCursor: null}};
    },
  };
  const subject = new WorkspacePromotionService(repository, catalogue, () => new Date(clock), options);
  const discover = (changes: Record<string, unknown> = {}) => subject.handleOperation("buyer-one",
    "readPublicPromotionDiscovery", {promotionDiscoveryVersion: 1, query: discoveryQuery, pageSize: 1, ...changes}) as Promise<Record<string, any>>;
  return {repository, subject, catalogue, listing, discover, setClock: (value: string) => {clock = value;}, reads: () => directoryReads};
}

function advertisedTerms(kind: "flat" | "percentage" = "flat") {
  return {schemaVersion: 1, kind, currency: "INR", flatAmountMinor: kind === "flat" ? 1025 : null,
    flatBasis: kind === "flat" ? "per_pack" : null, percentageBasisPoints: kind === "percentage" ? 750 : null,
    maximumSavingMinor: 5000, minimumSpendMinor: 0, minimumQuantity: 2};
}
function termsService(repository: PromotionRepository, enabled = true) {
  // Reflect keeps the initial missing-capability regression executable before
  // the matching optional constructor capability exists. No runtime fixture.
  return Reflect.construct(WorkspacePromotionService, [repository, {publicCatalogue: async () => source()},
    () => new Date(at), {benefitTermsSupported: enabled}]) as WorkspacePromotionService;
}
for (const kind of ["flat", "percentage"] as const) {
  test(`LF04 advertised benefit terms owner save original recovery and public readback ${kind}`, async () => {
    const repository = new Memory(), subject = termsService(repository), benefitTerms = advertisedTerms(kind);
    const original = {...body(), promotionTermsVersion: 1};
    Object.assign(original.promotion, {benefitTerms});
    const saved = await subject.handleOperation("owner-one", "saveStorePromotion", original) as Record<string, any>;
    assert.deepEqual(saved.record.benefitTerms, benefitTerms); assert.equal(saved.promotionTermsVersion, 1);
    const restart = termsService(repository);
    assert.deepEqual(await restart.handleOperation("owner-one", "reconcileStorePromotion", original), saved);
    const page = await restart.handleOperation("buyer-one", "readPublicStorePromotions",
      {storeId: "store-one", limit: 20, promotionTermsVersion: 1}) as Record<string, any>;
    assert.equal(page.state, "ready"); assert.equal(page.promotionTermsVersion, 1);
    assert.deepEqual(page.items[0].benefitTerms, benefitTerms);
    assert.equal(page.items[0].product.skuId, "sku-one"); assert.equal(page.orderingAvailable, false);
    assert.doesNotMatch(JSON.stringify(page), /"applied"|"redemption"|"savingAmountMinor"|owner-one|fingerprint/u);
    const incompatible = await restart.handleOperation("buyer-one", "readPublicStorePromotions",
      {storeId: "store-one", limit: 20}) as Record<string, any>;
    assert.equal(incompatible.state, "unavailable", "Never erase the conditions for an old public reader.");
    const paused = {...original, expectedRevision: 1, idempotencyKey: "pause-terms",
      promotion: {...original.promotion, active: false}};
    await restart.handleOperation("owner-one", "saveStorePromotion", paused);
    const hidden = await restart.handleOperation("buyer-one", "readPublicStorePromotions",
      {storeId: "store-one", limit: 20, promotionTermsVersion: 1}) as Record<string, any>;
    assert.deepEqual(hidden.items, []); assert.equal(hidden.state, "ready");
    assert.deepEqual(await restart.handleOperation("owner-one", "reconcileStorePromotion", original), saved,
      "Historical success stays original, not a new activation.");
  });
}

for (const [name, change] of Object.entries<Record<string, unknown>>({
  "unknown version": {schemaVersion: 2}, "coerced version": {schemaVersion: "1"}, "wrong currency": {currency: "USD"},
  "coerced kind": {kind: ["flat"]}, "coerced basis": {flatBasis: ["per_pack"]}, "missing flat": {flatAmountMinor: null},
  "ambiguous amount": {percentageBasisPoints: 100}, "fractional paise": {flatAmountMinor: 10.5},
  "zero advertised amount": {flatAmountMinor: 0}, "unsafe amount": {flatAmountMinor: Number.MAX_SAFE_INTEGER},
  "zero cap": {maximumSavingMinor: 0}, "negative threshold": {minimumSpendMinor: -1},
  "fractional packs": {minimumQuantity: 1.5}, "zero packs": {minimumQuantity: 0},
  "invented applied status": {applied: true}, "missing percent": {kind: "percentage", flatAmountMinor: null, flatBasis: null},
  "zero percent": {kind: "percentage", flatAmountMinor: null, flatBasis: null, percentageBasisPoints: 0},
  "over100percent": {kind: "percentage", flatAmountMinor: null, flatBasis: null, percentageBasisPoints: 10001},
  "fractional basispoints": {kind: "percentage", flatAmountMinor: null, flatBasis: null, percentageBasisPoints: 7.5},
})) test(`LF04 advertised benefit terms rejects ${name} without writing`, async () => {
  const repository = new Memory(), subject = termsService(repository), original = {...body(), promotionTermsVersion: 1};
  Object.assign(original.promotion, {benefitTerms: {...advertisedTerms(), ...change}});
  await assert.rejects(subject.handleOperation("owner-one", "saveStorePromotion", original),
    (error: any) => error.code === "invalid_input");
  assert.equal(repository.writes, 0);
});

test("LF04 advertised terms capability is explicit and old originals retain their fingerprint", async () => {
  const a = new Memory(), b = new Memory(), original = body();
  assert.deepEqual(await termsService(a).handleOperation("owner-one", "saveStorePromotion", original),
    await termsService(b, false).handleOperation("owner-one", "saveStorePromotion", original));
  assert.deepEqual([...a.receipts.values()], [...b.receipts.values()]);
  const rich = {...body(), promotionTermsVersion: 1}; Object.assign(rich.promotion, {benefitTerms: advertisedTerms()});
  await assert.rejects(termsService(new Memory(), false).handleOperation("owner-one", "saveStorePromotion", rich),
    (error: any) => error.code === "unavailable");
  const {promotionTermsVersion, ...missing} = rich; assert.equal(promotionTermsVersion, 1);
  await assert.rejects(termsService(new Memory()).handleOperation("owner-one", "saveStorePromotion", missing),
    (error: any) => error.code === "unavailable");
});

test("LF04 advertised terms cannot be erased by a legacy owner; negotiated explicit clear is preserved", async () => {
  const repository = new Memory(), subject = termsService(repository), original = {...body(), promotionTermsVersion: 1};
  Object.assign(original.promotion, {benefitTerms: advertisedTerms()});
  await subject.handleOperation("owner-one", "saveStorePromotion", original);
  await assert.rejects(subject.handleOperation("owner-one", "readStorePromotion", {storeId: "store-one", placementId: "promotion-one"}),
    (error: any) => error.code === "unavailable");
  await assert.rejects(subject.handleOperation("owner-one", "listStorePromotions", {storeId: "store-one", limit: 20}),
    (error: any) => error.code === "unavailable");
  const plain = {...body(), expectedRevision: 1, idempotencyKey: "explicit-clear"};
  await assert.rejects(subject.handleOperation("owner-one", "saveStorePromotion", plain), (error: any) => error.code === "unavailable");
  assert.equal(repository.writes, 1);
  const cleared = await subject.handleOperation("owner-one", "saveStorePromotion", {...plain, promotionTermsVersion: 1}) as Record<string, any>;
  assert.equal(Object.hasOwn(cleared.record, "benefitTerms"), false); assert.equal(repository.writes, 2);
  const legacyRead = await subject.handleOperation("buyer-one", "readPublicStorePromotions", {storeId: "store-one", limit: 20}) as Record<string, any>;
  assert.equal(legacyRead.state, "ready"); assert.equal(Object.hasOwn(legacyRead, "promotionTermsVersion"), false);
});

test("LF04 advertised terms global discovery preserves conditions and retires changed-condition cursors", async () => {
  const fixture = discoveryFixture({benefitTermsSupported: true}), first = {...body(), promotionTermsVersion: 1};
  Object.assign(first.promotion, {benefitTerms: advertisedTerms()});
  await fixture.subject.handleOperation("owner-one", "saveStorePromotion", first);
  await fixture.subject.handleOperation("owner-one", "saveStorePromotion", {...first, placementId: "promotion-two", idempotencyKey: "second-placement"});
  const page = await fixture.discover({promotionTermsVersion: 1});
  assert.equal(page.promotionTermsVersion, 1); assert.deepEqual(page.items[0].publication.benefitTerms, advertisedTerms());
  assert.equal(page.orderingAvailable, false); assert.equal(page.page.totalCount, 2);
  await assert.rejects(fixture.discover(), (error: any) => error.code === "unavailable");
  await fixture.subject.handleOperation("owner-one", "saveStorePromotion", {...first, expectedRevision: 1, idempotencyKey: "changed-conditions",
    promotion: {...first.promotion, benefitTerms: {...advertisedTerms(), minimumQuantity: 3}}});
  await assert.rejects(fixture.discover({promotionTermsVersion: 1, cursor: page.page.nextCursor}),
    (error: any) => error.code === "stale_cursor");
});

test("ordinary promotion discovery uses owner publications and paginates placements, not products", async () => {
  const f = discoveryFixture();
  await f.subject.save("owner-one", body());
  await f.subject.save("owner-one", body({placementId: "promotion-two", idempotencyKey: "original-two"}));
  const first = await f.discover();
  assert.equal(first.state, "ready"); assert.equal(first.page.totalCount, 2);
  assert.deepEqual(first.coverage, {kind: "connected_publishers", publisherTypes: ["retailer"], countBasis: "publications"});
  assert.equal(first.items[0].publication.publicationId, "promotion-one");
  assert.deepEqual(first.items[0].listing, f.listing);
  const next = await f.discover({cursor: first.page.nextCursor});
  assert.equal(next.items[0].publication.publicationId, "promotion-two");
  const back = await f.discover({cursor: next.page.previousCursor});
  assert.equal(back.page.snapshotId, first.page.snapshotId);
  await assert.rejects(f.discover({cursor: first.page.nextCursor, query: {...discoveryQuery, search: "other"}}));
  assert.ok(f.reads() >= 6, "directory must be checked after the last promotion await");
});

test("ordinary promotions keep partial publisher coverage and fail closed on unsupported sources", async () => {
  const f = discoveryFixture();
  assert.equal((await f.discover()).page.totalCount, 0);
  await assert.rejects(f.discover({query: {...discoveryQuery, publisher: "moolSocial"}}));
  await assert.rejects(f.discover({query: {...discoveryQuery, regionId: "region-one"}}));
  f.catalogue.publicDiscovery = async () => {throw Error("source unavailable");};
  await assert.rejects(f.discover());
});

test("ordinary promotion snapshots retire paused, expired and changed sources, including cursor reuse", async () => {
  const f = discoveryFixture();
  await f.subject.save("owner-one", body());
  await f.subject.save("owner-one", body({placementId: "promotion-two", idempotencyKey: "original-two"}));
  const first = await f.discover();
  const pause = body({expectedRevision: 1, idempotencyKey: "pause-one"}); pause.promotion.active = false;
  await f.subject.save("owner-one", pause);
  assert.equal((await f.discover()).page.totalCount, 1);
  await assert.rejects(f.discover({cursor: first.page.nextCursor}));
  f.setClock("2026-10-17T02:00:00.000Z");
  assert.equal((await f.discover()).page.totalCount, 0);
});

test("ordinary promotions detect scheduled activation during final directory await", async () => {
  const f = discoveryFixture(), scheduled = body(); scheduled.promotion.validFrom = "2026-10-17T01:00:01.000Z";
  await f.subject.save("owner-one", scheduled);
  const read = f.catalogue.publicDiscovery;
  f.catalogue.publicDiscovery = async input => {
    const response = await read(input);
    if (f.reads() === 5) f.setClock("2026-10-17T01:00:01.000Z");
    return response;
  };
  await assert.rejects(f.discover(), {code: "stale_snapshot"});
});

test("ordinary promotion discovery rejects directory mutation after final promotion reads", async () => {
  const f = discoveryFixture(); await f.subject.save("owner-one", body());
  const read = f.catalogue.publicDiscovery;
  f.catalogue.publicDiscovery = async input => {
    const response = await read(input);
    if (f.reads() >= 5) response.page.snapshotId = "c".repeat(64);
    return response;
  };
  await assert.rejects(f.discover(), {code: "stale_snapshot"});
});

test("ordinary promotion discovery does not turn unreadable promotion coverage into zero", async () => {
  const f = discoveryFixture(); f.repository.page = async () => {throw Error("read failed");};
  await assert.rejects(f.discover(), {code: "unavailable"});
});
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
    const richInput = {...body({storeId, placementId: "rich-promotion", idempotencyKey: "rich-original"}), promotionTermsVersion: 1};
    Object.assign(richInput.promotion, {benefitTerms: advertisedTerms("percentage")});
    const richService = () => new WorkspacePromotionService(new FirestorePromotionRepository(db, "evaluation", () => new Date(at)),
      {publicCatalogue: async () => ({...source(), storeId})}, () => new Date(at), {benefitTermsSupported: true});
    const savedRich = await richService().handleOperation("owner-one", "saveStorePromotion", richInput) as Record<string, any>;
    assert.deepEqual(savedRich.record.benefitTerms, advertisedTerms("percentage"));
    const richRestart = richService();
    assert.deepEqual(await richRestart.handleOperation("owner-one", "reconcileStorePromotion", richInput), savedRich);
    const richPage = await richRestart.handleOperation("buyer-one", "readPublicStorePromotions",
      {storeId, limit: 20, promotionTermsVersion: 1}) as Record<string, any>;
    assert.deepEqual(richPage.items.find((item: any) => item.publicationId === "rich-promotion").benefitTerms, advertisedTerms("percentage"));
    await richRestart.handleOperation("owner-one", "saveStorePromotion", {...richInput, expectedRevision: 1,
      idempotencyKey: "rich-pause", promotion: {...richInput.promotion, active: false}});
    const pausedRich = await richService().handleOperation("buyer-one", "readPublicStorePromotions",
      {storeId, limit: 20, promotionTermsVersion: 1}) as Record<string, any>;
    assert.equal(pausedRich.items.some((item: any) => item.publicationId === "rich-promotion"), false);
    assert.deepEqual(await richService().handleOperation("owner-one", "reconcileStorePromotion", richInput), savedRich);
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
