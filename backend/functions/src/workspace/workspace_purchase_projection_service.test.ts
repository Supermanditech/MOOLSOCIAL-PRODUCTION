import assert from "node:assert/strict";
import {createHash, randomUUID} from "node:crypto";
import test from "node:test";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {WorkspaceProfileError} from "./workspace_profile_service.js";
import {WorkspacePurchaseProjectionService, normalizePlacement, requireDefaultPurchaseTenant,
  WorkspaceOrderOperationsService, normalizeOperationalOrder,
  type TrustedOperationalOrderEvidence, type TrustedPlacementReceipt} from "./workspace_purchase_projection_service.js";

function operationalEvidence(): TrustedOperationalOrderEvidence {
  const now = new Date("2026-10-16T12:00:00.000Z");
  return {schemaVersion: 1, realm: "evaluation", authNamespace: "firebase-default",
    issuer: "trusted-orders", receiptId: "operations-receipt", revision: "operations-v1",
    purchaseId: "purchase-one", storeId: "store-one", orderId: "order-one",
    originalFingerprint: "a".repeat(64), sourceRevision: "revision-1",
    customerLabel: "Evaluation buyer", fulfilment: "delivery", address: "Evaluation address",
    placedAt: new Date(now.getTime() - 1000).toISOString(),
    acceptanceDeadline: new Date(now.getTime() + 60000).toISOString(),
    fulfilmentDeadline: new Date(now.getTime() + 3600000).toISOString(),
    initialStage: "Confirmed", allowedActions: ["accept", "ready", "reject"]};
}

test("operational bootstrap requires genuine bounded operational evidence", () => {
  const now = new Date("2026-10-16T12:00:00.000Z");
  const input = operationalEvidence();
  assert.deepEqual(normalizeOperationalOrder(input, "evaluation", now), input);
  for (const patch of [
    {realm: "production"}, {authNamespace: "tenant-other"}, {customerLabel: ""},
    {fulfilment: "guessed"}, {fulfilment: ["collection"]}, {address: ""},
    {initialStage: "Delivered"}, {initialStage: ["Confirmed"]},
    {placedAt: "2026-10-17T12:00:00.000Z"}, {acceptanceDeadline: "invalid-date"},
    {allowedActions: ["accept", "accept"]}, {allowedActions: ["requestTime"]},
    {originalFingerprint: "wrong"}, {paid: true},
  ]) assert.throws(() => normalizeOperationalOrder({...input, ...patch}, "evaluation", now),
    e => e instanceof WorkspaceProfileError && e.code === "invalid_input");
});

test("actual operational order initialization, revisions and original-attempt recovery", {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-operations"}, `operations-${randomUUID()}`);
  const db = getFirestore(app);
  const value = receipt(randomUUID());
  const suffix = randomUUID();
  value.buyerUserId = `buyer-${suffix}`;
  value.stores.forEach((s, i) => {
    s.caseId = `case-${suffix}-${i}`; s.storeId = `store-${suffix}-${i}`;
    s.ownerUserId = `owner-${suffix}-${i}`;
  });
  // Fractional original quantity and all eight original money components survive.
  const firstStore = value.stores[0]!;
  firstStore.lines[0]!.quantityMilli = 500;
  firstStore.lines[0]!.lineTotalMinor = 5026;
  firstStore.totals.itemsMinor = 5026; firstStore.totals.totalMinor = 4990;
  for (const s of value.stores) await db.collection("workspaceProfiles").doc(s.caseId).set({
    schemaVersion: 1, caseId: s.caseId, workspaceId: s.storeId, ownerUserId: s.ownerUserId,
    familyId: "products-trade", profileId: "retailer-grocery", status: "live", shopEnabled: true,
  });
  try {
    const originals = new WorkspacePurchaseProjectionService(db, "evaluation", {
      readFinalPlacement: async () => value,
    });
    const created = await originals.materialize("operational-source");
    const before = await originals.readBuyer(value.buyerUserId, {purchaseId: created.purchaseId});
    const partition = before.orders.find(o => o.storeId === firstStore.storeId)!;
    const tuple = {purchaseId: created.purchaseId, storeId: partition.storeId, orderId: partition.orderId};
    const source = {...operationalEvidence(), ...tuple, originalFingerprint: partition.originalFingerprint,
      sourceRevision: before.sourceRevision};
    let currentTime = new Date("2026-10-16T12:00:00.000Z");
    const clock = () => new Date(currentTime);
    const service = new WorkspaceOrderOperationsService(db, "evaluation", {
      readOperationalOrder: async () => source,
    }, clock);
    const fresh = new WorkspaceOrderOperationsService(db, "evaluation", undefined, clock);
    await assert.rejects(fresh.initialize("trusted-order"), rejectsCode("service_unavailable"));
    await assert.rejects(fresh.read(value.buyerUserId, "buyer", tuple), rejectsCode("service_unavailable"));
    await service.initialize("trusted-order");
    await service.initialize("trusted-order"); // Exact replay, no second order.
    const initial = await fresh.read(value.buyerUserId, "buyer", tuple);
    assert.equal(initial.revision, 1); assert.equal(initial.stage, "Confirmed");
    assert.deepEqual(initial.original, partition.original);
    assert.equal(initial.original.lines[0]!.quantityMilli, 500);
    assert.equal(initial.original.totals.totalMinor, 4990);
    assert.equal("address" in initial, false); // Seller-only recipient projection.
    const seller = await fresh.read(firstStore.ownerUserId, "seller", tuple);
    assert.equal(seller.address, source.address);
    assert.equal("buyerUserId" in seller, false);
    for (const [actor, role, scope] of [
      ["wrong-buyer", "buyer", tuple], [value.stores[1]!.ownerUserId, "seller", tuple],
      [firstStore.ownerUserId, "seller", {...tuple, storeId: value.stores[1]!.storeId}],
    ] as const) await assert.rejects(fresh.read(actor, role, scope), rejectsCode("not_found"));
    const command = {version: 2, ...tuple, operationId: "STORE-ORDER-test_nonce==",
      expectedRevision: 1, action: "accept", reason: null};
    await assert.rejects(fresh.command(value.buyerUserId, command), rejectsCode("not_found"));
    await assert.rejects(fresh.command(firstStore.ownerUserId, {...command, action: ["accept"]}), rejectsCode("invalid_input"));
    await assert.rejects(fresh.command(firstStore.ownerUserId, {...command, storeId: value.stores[1]!.storeId}), rejectsCode("not_found"));
    const unknown = await fresh.command(firstStore.ownerUserId, command, true);
    assert.equal(unknown.state, "pending"); assert.equal(unknown.snapshot.revision, 1);
    // Pausing new sales must not prevent fulfilment of an existing order.
    await db.collection("workspaceProfiles").doc(firstStore.caseId).update({shopEnabled: false});
    const competing = {...command, operationId: "competing-reject", action: "reject", reason: "Unavailable"};
    const outcomes = await Promise.all([fresh.command(firstStore.ownerUserId, command),
      fresh.command(firstStore.ownerUserId, competing)]);
    assert.deepEqual(outcomes.map(r => r.state).sort(), ["applied", "rejected"]);
    const accepted = outcomes.find(r => r.state === "applied")!;
    assert.equal(accepted.snapshot.revision, 2);
    const restarted = new WorkspaceOrderOperationsService(db, "evaluation", undefined, clock);
    const winner = outcomes[0]!.state === "applied" ? command : competing;
    assert.deepEqual(await restarted.command(firstStore.ownerUserId, winner, true), accepted);
    assert.deepEqual(await restarted.command(firstStore.ownerUserId, winner), accepted);
    // Isolated compatibility fixture for the earlier local receipt schema.
    // Reads normalize its projection; its original bytes/history stay unchanged.
    const receiptKey = createHash("sha256").update(JSON.stringify([firstStore.ownerUserId, winner.operationId])).digest("hex");
    const receiptPath = db.collection("workspacePurchaseProjections").doc("evaluation")
      .collection("operationalOrders").doc(tuple.orderId).collection("commands").doc(receiptKey);
    const historical = (await receiptPath.get()).data()!;
    delete historical.result.snapshot.stockVerification;
    delete historical.result.snapshot.rejectionReason;
    historical.result.snapshot.stockPosting = "not_performed";
    function canonical(v: unknown): unknown {
      if (Array.isArray(v)) return v.map(canonical);
      if (v !== null && typeof v === "object") return Object.fromEntries(
        Object.entries(v).sort(([a],[b]) => a < b ? -1 : a > b ? 1 : 0).map(([k, value]) => [k, canonical(value)]));
      return v;
    }
    const {integrity: _oldReceiptHash, ...historicalBody} = historical;
    historical.integrity = createHash("sha256").update(JSON.stringify(canonical(historicalBody))).digest("hex");
    await receiptPath.set(historical);
    const historicalBytes = JSON.stringify((await receiptPath.get()).data());
    assert.deepEqual(await restarted.command(firstStore.ownerUserId, winner, true), accepted);
    assert.equal(JSON.stringify((await receiptPath.get()).data()), historicalBytes);
    await assert.rejects(restarted.command(firstStore.ownerUserId, {...winner, reason: "Changed"}, true),
      rejectsCode("conflict"));
    // Lost-reply reconciliation remains the original outcome after its deadline.
    currentTime = new Date("2026-10-16T12:05:00.000Z");
    assert.deepEqual(await restarted.command(firstStore.ownerUserId, winner, true), accepted);
    currentTime = new Date("2026-10-16T12:00:00.000Z");
    // New placements require an open Store; the earlier pause test concerned
    // only management of an already established order.
    await db.collection("workspaceProfiles").doc(firstStore.caseId).update({shopEnabled: true});
    async function scenario(patch: Partial<TrustedOperationalOrderEvidence> = {}) {
      const placement = structuredClone(value); placement.receiptId = `receipt-${randomUUID()}`;
      const producer = new WorkspacePurchaseProjectionService(db, "evaluation", {
        readFinalPlacement: async () => placement,
      });
      const created = await producer.materialize("another-trusted-source");
      const projection = await producer.readBuyer(value.buyerUserId, {purchaseId: created.purchaseId});
      const order = projection.orders.find(o => o.storeId === firstStore.storeId)!;
      const tuple = {purchaseId: created.purchaseId, storeId: order.storeId, orderId: order.orderId};
      const proof = {...operationalEvidence(), ...tuple, ...patch, originalFingerprint: order.originalFingerprint,
        sourceRevision: projection.sourceRevision};
      const operations = new WorkspaceOrderOperationsService(db, "evaluation", {
        readOperationalOrder: async () => proof,
      }, clock);
      await operations.initialize("another-operational-source");
      const command = {version: 2, ...tuple, operationId: "isolated-accept", expectedRevision: 1,
        action: "accept", reason: null};
      return {operations, tuple, command};
    }
    const lifecycle = await scenario();
    const preparing = await lifecycle.operations.command(firstStore.ownerUserId, lifecycle.command);
    assert.equal(preparing.snapshot.stage, "Preparing");
    const ready = await lifecycle.operations.command(firstStore.ownerUserId, {...lifecycle.command,
      operationId: "isolated-ready", expectedRevision: 2, action: "ready"});
    assert.equal(ready.state, "applied"); assert.equal(ready.snapshot.stage, "Ready");
    assert.equal(ready.snapshot.revision, 3);
    assert.equal(ready.snapshot.paymentVerification, "not_supplied");
    assert.equal(ready.snapshot.stockVerification, "not_supplied");
    const denied = await scenario({allowedActions: ["reject"]});
    assert.equal((await denied.operations.command(firstStore.ownerUserId, denied.command)).state, "rejected");
    const rejection = await denied.operations.command(firstStore.ownerUserId, {...denied.command,
      operationId: "actual-reject", action: "reject", reason: "Cannot supply these items"});
    assert.equal(rejection.snapshot.stage, "Rejected");
    assert.equal((await denied.operations.read(value.buyerUserId, "buyer", denied.tuple)).rejectionReason,
      "Cannot supply these items");
    const noTiming = await scenario({acceptanceDeadline: null});
    assert.equal((await noTiming.operations.command(firstStore.ownerUserId, noTiming.command)).state, "rejected");
    const oldReady = {...noTiming.command, operationId: "legacy-null-timing", action: "ready"};
    const deniedReady = await noTiming.operations.command(firstStore.ownerUserId, oldReady);
    const oldReadyKey = createHash("sha256").update(JSON.stringify([firstStore.ownerUserId, oldReady.operationId])).digest("hex");
    const oldReadyPath = db.collection("workspacePurchaseProjections").doc("evaluation")
      .collection("operationalOrders").doc(noTiming.tuple.orderId).collection("commands").doc(oldReadyKey);
    const oldReadyReceipt = (await oldReadyPath.get()).data()!;
    delete oldReadyReceipt.result.snapshot.stockVerification;
    delete oldReadyReceipt.result.snapshot.rejectionReason;
    oldReadyReceipt.result.snapshot.stockPosting = "not_performed";
    oldReadyReceipt.result.snapshot.permittedActions = ["accept", "reject"];
    const {integrity: _oldReadyHash, ...oldReadyBody} = oldReadyReceipt;
    oldReadyReceipt.integrity = createHash("sha256").update(JSON.stringify(canonical(oldReadyBody))).digest("hex");
    await oldReadyPath.set(oldReadyReceipt);
    const oldReadyBytes = JSON.stringify((await oldReadyPath.get()).data());
    assert.deepEqual(await noTiming.operations.command(firstStore.ownerUserId, oldReady, true), deniedReady);
    assert.equal(JSON.stringify((await oldReadyPath.get()).data()), oldReadyBytes);
    const collection = await scenario({fulfilment: "collection", allowedActions: []});
    assert.equal((await collection.operations.command(firstStore.ownerUserId, collection.command)).state, "rejected");
    const expired = await scenario();
    currentTime = new Date("2026-10-16T12:05:00.000Z");
    assert.equal((await expired.operations.command(firstStore.ownerUserId, expired.command)).state, "rejected");
    currentTime = new Date("2026-10-16T12:00:00.000Z");
    source.revision = "changed-operational-proof";
    await assert.rejects(service.initialize("trusted-order"), rejectsCode("conflict"));
    await db.collection("workspaceProfiles").doc(firstStore.caseId).update({ownerUserId: "new-owner"});
    await assert.rejects(restarted.read(firstStore.ownerUserId, "seller", tuple), rejectsCode("not_found"));
    await assert.rejects(restarted.command(firstStore.ownerUserId, winner, true), rejectsCode("not_found"));
    assert.equal((await restarted.read(value.buyerUserId, "buyer", tuple)).revision, 2);
    assert.deepEqual(await originals.readBuyer(value.buyerUserId, {purchaseId: created.purchaseId}), before);
  } finally { await db.terminate(); await deleteApp(app); }
});

// Isolated trusted-source fixtures. Never runtime/native order acceptance.
function receipt(suffix = "one"): TrustedPlacementReceipt {
  return {schemaVersion: 1, realm: "evaluation", authNamespace: "firebase-default",
    finalPlacement: true, issuer: "local-placement", receiptId: `receipt-${suffix}`,
    revision: "revision-1", buyerUserId: "buyer-one", stores: ["one", "two"].map(s => ({
      storeId: `store-${s}`, caseId: `case-${s}`, ownerUserId: `owner-${s}`,
      lines: [{sourceLineId: `source-${s}`, skuId: `sku-${s}`, canonicalProductId: `product-${s}`,
        verifiedPackId: `pack-${s}`, offerId: `offer-${s}`, offerRevision: "offer-revision-1",
        name: "दाल", packLabel: "1 kg", quantityMilli: 1000, quantityUnit: "pack" as const,
        unitPriceMinor: 10051, lineTotalMinor: 10051}],
      totals: {itemsMinor: 10051, discountMinor: 51, taxMinor: 5, deliveryMinor: 10,
        freightMinor: 0, paymentFeeMinor: 0, tipMinor: 0, totalMinor: 10015},
    }))};
}
const rejectsCode = (code: string) => (e: unknown) =>
  e instanceof WorkspaceProfileError && e.code === code;

test("projection reads require default Firebase namespace, not UID equality across tenants", () => {
  requireDefaultPurchaseTenant(undefined);
  for (const tenant of ["tenant-one", "", null]) {
    assert.throws(() => requireDefaultPurchaseTenant(tenant), rejectsCode("authentication_required"));
  }
});

test("normalization preserves exact paise, SKU/pack identities and canonical order", () => {
  const input = receipt();
  input.stores.reverse();
  const result = normalizePlacement(input, "evaluation");
  assert.equal(result.stores[0]?.storeId, "store-one");
  assert.equal(result.stores[0]?.totals.totalMinor, 10015);
  assert.equal(result.stores[0]?.lines[0]?.verifiedPackId, "pack-one");
  assert.equal(input.stores[0]?.storeId, "store-two"); // never mutate source
});

test("fractional quantity uses declared gross half-up paise without floating arithmetic", () => {
  const input = receipt();
  const s = input.stores[0]!;
  s.lines[0]!.quantityMilli = 500; s.lines[0]!.lineTotalMinor = 5026;
  s.totals.itemsMinor = 5026; s.totals.totalMinor = 4990;
  assert.equal(normalizePlacement(input, "evaluation").stores[0]?.totals.itemsMinor, 5026);
  s.lines[0]!.lineTotalMinor = 5025; s.totals.itemsMinor--; s.totals.totalMinor--;
  assert.throws(() => normalizePlacement(input, "evaluation"), rejectsCode("invalid_input"));
});

for (const [name, change] of Object.entries({
  "missing final proof": (r: TrustedPlacementReceipt) => {r.finalPlacement = false as true;},
  "wrong realm": (r: TrustedPlacementReceipt) => {r.realm = "production";},
  "tenant not supported": (r: TrustedPlacementReceipt) => {r.authNamespace = "tenant-one" as "firebase-default";},
  "wrong totals": (r: TrustedPlacementReceipt) => {r.stores[0]!.totals.totalMinor++;},
  "wrong line subtotal": (r: TrustedPlacementReceipt) => {r.stores[0]!.totals.itemsMinor++;},
  "duplicate Store": (r: TrustedPlacementReceipt) => {r.stores[1]!.storeId = r.stores[0]!.storeId;},
  "duplicate source line": (r: TrustedPlacementReceipt) => {r.stores[0]!.lines.push(r.stores[0]!.lines[0]!);},
  "unsafe number": (r: TrustedPlacementReceipt) => {r.stores[0]!.lines[0]!.unitPriceMinor = Number.MAX_SAFE_INTEGER + 1;},
  "unit price mismatch": (r: TrustedPlacementReceipt) => {r.stores[0]!.lines[0]!.unitPriceMinor = 1;},
  "array quantity unit": (r: TrustedPlacementReceipt) => {r.stores[0]!.lines[0]!.quantityUnit = ["pack"] as unknown as "pack";},
  "overlarge aggregate": (r: TrustedPlacementReceipt) => {r.stores = Array(11).fill(r.stores[0]!);},
})) {
  test(`rejects ${name} before persistence`, () => {
    const input = receipt(); change(input);
    assert.throws(() => normalizePlacement(input, "evaluation"), rejectsCode("invalid_input"));
  });
}

test("actual atomic producer, recovery and exact-Store projections", {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const projectId = "demo-lf-purchase";
  const firstApp = initializeApp({projectId}, `producer-${randomUUID()}`);
  const secondApp = initializeApp({projectId}, `reader-${randomUUID()}`);
  const db = getFirestore(firstApp), fresh = getFirestore(secondApp);
  const source = new Map<string, TrustedPlacementReceipt>();
  const suffix = randomUUID();
  const value = receipt(suffix);
  value.buyerUserId = `buyer-${suffix}`;
  value.stores.forEach((s, i) => {
    s.caseId = `case-${suffix}-${i}`; s.storeId = `store-${suffix}-${i}`;
    s.ownerUserId = `owner-${suffix}-${i}`;
  });
  const trusted = {readFinalPlacement: async (ref: string) => structuredClone(source.get(ref))};
  const service = new WorkspacePurchaseProjectionService(db, "evaluation", trusted);
  const reader = new WorkspacePurchaseProjectionService(fresh, "evaluation");
  const root = db.collection("workspacePurchaseProjections").doc("evaluation");
  const before = (await root.collection("purchases").get()).size;
  const receiptsBefore = (await root.collection("receipts").get()).size;
  try {
    await assert.rejects(reader.materialize("missing-ref"), rejectsCode("service_unavailable"));
    source.set("trusted-ref", value);
    // No partial first Store, buyer directory or receipt when second profile missing.
    await db.collection("workspaceProfiles").doc(value.stores[0]!.caseId).set({
      schemaVersion: 1, caseId: value.stores[0]!.caseId, workspaceId: value.stores[0]!.storeId,
      ownerUserId: value.stores[0]!.ownerUserId, familyId: "products-trade",
      profileId: "retailer-grocery", status: "live", shopEnabled: true,
    });
    await assert.rejects(service.materialize("trusted-ref"), rejectsCode("not_found"));
    assert.equal((await root.collection("purchases").get()).size, before);
    assert.equal((await root.collection("buyers").get()).docs.filter(d => d.data().userId === value.buyerUserId).length, 0);
    assert.equal((await root.collection("receipts").get()).size, receiptsBefore);
    await db.collection("workspaceProfiles").doc(value.stores[1]!.caseId).set({
      schemaVersion: 1, caseId: value.stores[1]!.caseId, workspaceId: value.stores[1]!.storeId,
      ownerUserId: value.stores[1]!.ownerUserId, familyId: "products-trade",
      profileId: "wholesaler", status: "live", shopEnabled: true,
    });
    const [a, b] = await Promise.all([service.materialize("trusted-ref"), service.materialize("trusted-ref")]);
    assert.deepEqual(a, b);
    source.set("trusted-ref", reverseMaps(value) as TrustedPlacementReceipt);
    assert.deepEqual(await service.materialize("trusted-ref"), a);
    const storedRef = root.collection("purchases").doc(a.purchaseId);
    await storedRef.set(reverseMaps((await storedRef.get()).data()) as Record<string, unknown>);
    const buyer = await reader.readBuyer(value.buyerUserId, {purchaseId: a.purchaseId});
    assert.equal(buyer.orders.length, 2);
    assert.equal(buyer.orders[0]!.original.totals.totalMinor, 10015);
    assert.notEqual(buyer.buyerId, value.buyerUserId);
    assert.equal(buyer.orders[0]!.original.lines[0]!.skuId, "sku-one");
    await assert.rejects(new WorkspacePurchaseProjectionService(fresh, "production")
      .readBuyer(value.buyerUserId, {purchaseId: a.purchaseId}), rejectsCode("not_found"));
    await assert.rejects(reader.readBuyer(value.buyerUserId, {purchaseId: a.purchaseId, storeId: "extra-store"}), rejectsCode("invalid_input"));
    const order = buyer.orders[0]!;
    const buyerPage = await reader.listBuyer(value.buyerUserId, {limit: 1, cursor: null});
    assert.equal(buyerPage.references.length, 2);
    assert.equal(buyerPage.coverage, "saved_original_facts");
    assert.equal((await reader.listBuyer("other-buyer", {limit: 1, cursor: null})).references.length, 0);
    const storeBody = {storeId: order.storeId, limit: 1, cursor: null};
    const storePage = await reader.listStore(value.stores[0]!.ownerUserId, storeBody);
    assert.equal(storePage.references.length, 1);
    assert.equal(storePage.references[0]?.orderId, order.orderId);
    assert.equal(storePage.coverage, "indexed_original_facts");
    assert.equal(JSON.stringify(storePage).includes(value.stores[1]!.storeId), false);
    await assert.rejects(reader.listStore(value.stores[1]!.ownerUserId, storeBody), rejectsCode("not_found"));
    await assert.rejects(reader.listBuyer("other-buyer", {limit: 1, cursor: buyerPage.nextCursor}), rejectsCode("invalid_input"));
    // Existing v2 aggregate unchanged when its missing pointer projection is repaired.
    const pointer = root.collection("stores").doc(order.storeId).collection("orderReferences").doc(order.orderId);
    const originalAggregate = (await storedRef.get()).data();
    await pointer.delete();
    assert.equal((await reader.listStore(value.stores[0]!.ownerUserId, storeBody)).references.length, 0);
    await service.indexReferences(a.purchaseId);
    await service.indexReferences(a.purchaseId);
    assert.deepEqual((await storedRef.get()).data(), originalAggregate);
    assert.equal((await reader.listStore(value.stores[0]!.ownerUserId, storeBody)).references.length, 1);
    await pointer.update({purchaseId: "unrelated-purchase"});
    await assert.rejects(service.indexReferences(a.purchaseId), rejectsCode("conflict"));
    const excluded = await reader.listStore(value.stores[0]!.ownerUserId, storeBody);
    assert.equal(excluded.references.length, 0);
    assert.ok(excluded.nextCursor); // advance past scanned stale index, never stall
    await pointer.delete(); await service.indexReferences(a.purchaseId);
    const seller = await reader.readStore(value.stores[0]!.ownerUserId, {
      purchaseId: a.purchaseId, storeId: order.storeId, orderId: order.orderId,
    });
    assert.equal(seller.orders.length, 1);
    assert.equal(JSON.stringify(seller).includes(value.buyerUserId), false);
    assert.equal(JSON.stringify(seller).includes(value.stores[1]!.storeId), false);
    assert.equal((await db.collection("retailerOrders").doc(order.orderId).get()).exists, false);
    await assert.rejects(reader.readBuyer("other-buyer", {purchaseId: a.purchaseId}), rejectsCode("not_found"));
    await assert.rejects(reader.readStore(value.stores[1]!.ownerUserId, {
      purchaseId: a.purchaseId, storeId: order.storeId, orderId: order.orderId,
    }), rejectsCode("not_found"));
    const changed = structuredClone(value); changed.revision = "revision-2";
    source.set("trusted-ref", changed);
    await assert.rejects(service.materialize("trusted-ref"), rejectsCode("conflict"));
    changed.revision = value.revision; changed.stores[0]!.lines[0]!.name = "Changed";
    await assert.rejects(service.materialize("trusted-ref"), rejectsCode("conflict"));
    // New receipt for same actor converges on directory identity, not losing candidate.
    const next = structuredClone(value); next.receiptId += "-next";
    source.set("second-ref", next);
    const c = await service.materialize("second-ref");
    assert.notEqual(c.purchaseId, a.purchaseId); assert.equal(c.buyerId, a.buyerId);
    const pageOne = await reader.listBuyer(value.buyerUserId, {limit: 1, cursor: null});
    const pageTwo = await reader.listBuyer(value.buyerUserId, {limit: 1, cursor: pageOne.nextCursor});
    assert.notEqual(pageOne.references[0]?.purchaseId, pageTwo.references[0]?.purchaseId);
    await assert.rejects(reader.listStore(value.stores[1]!.ownerUserId,
      {storeId: value.stores[1]!.storeId, limit: 1, cursor: storePage.nextCursor}), rejectsCode("invalid_input"));
    const concurrentOne = structuredClone(value), concurrentTwo = structuredClone(value);
    concurrentOne.buyerUserId = concurrentTwo.buyerUserId = `new-buyer-${suffix}`;
    concurrentTwo.receiptId += "-different";
    source.set("concurrent-one", concurrentOne); source.set("concurrent-two", concurrentTwo);
    const [d, e] = await Promise.all([service.materialize("concurrent-one"), service.materialize("concurrent-two")]);
    assert.notEqual(d.purchaseId, e.purchaseId); assert.equal(d.buyerId, e.buyerId);
    await db.collection("workspaceProfiles").doc(value.stores[0]!.caseId).update({status: "suspended"});
    await assert.rejects(reader.listStore(value.stores[0]!.ownerUserId, storeBody), rejectsCode("not_found"));
    // Historical index repair for active Store B is not blocked by suspended Store A.
    const otherOrder = buyer.orders[1]!;
    await root.collection("stores").doc(otherOrder.storeId).collection("orderReferences").doc(otherOrder.orderId).delete();
    await service.indexReferences(a.purchaseId);
    const activePage = await reader.listStore(value.stores[1]!.ownerUserId,
      {storeId: otherOrder.storeId, limit: 5, cursor: null});
    assert.ok(activePage.references.some(r => r.orderId === otherOrder.orderId));
    await assert.rejects(reader.readStore(value.stores[0]!.ownerUserId, {
      purchaseId: a.purchaseId, storeId: order.storeId, orderId: order.orderId,
    }), rejectsCode("not_found"));
    // Immutable buyer facts remain readable after Store suspension; no current eligibility claim.
    assert.equal((await reader.readBuyer(value.buyerUserId, {purchaseId: a.purchaseId})).orders.length, 2);
    const doc = root.collection("purchases").doc(a.purchaseId);
    const corrupt = (await doc.get()).data()!;
    corrupt.orders[0].original.totals.totalMinor++;
    await doc.set(corrupt);
    await assert.rejects(reader.readBuyer(value.buyerUserId, {purchaseId: a.purchaseId}), rejectsCode("invalid_state"));
  } finally {
    await Promise.all([db.terminate(), fresh.terminate()]);
    await Promise.all([deleteApp(firstApp), deleteApp(secondApp)]);
  }
});

function reverseMaps(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(reverseMaps);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).reverse().map(([k,v]) => [k, reverseMaps(v)]));
  }
  return value;
}
