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
test("LF-VARIANT original snapshot preserves supplied variant and explicit no-variant without catalogue fallback", () => {
  const source = JSON.parse(JSON.stringify(attributedReceipt()));
  source.schemaVersion = 3;
  source.stores[0].lines[0].variant = "Pink · 128 GB";
  source.stores[1].lines[0].variant = "";
  const result = normalizePlacement(source, "evaluation");
  assert.equal((result.stores[0]!.lines[0] as unknown as {variant: string}).variant, "Pink · 128 GB");
  assert.equal((result.stores[1]!.lines[0] as unknown as {variant: string}).variant, "");
  assert.equal(JSON.stringify(result).includes("brandId"), false);
});

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

function attributedReceipt() {
  const legacy = receipt();
  return {...legacy, schemaVersion: 2, stores: legacy.stores.map(s => ({...s,
    benefitAttribution: {schemaVersion: 1, components: [
      {componentId: "discount-component", benefitId: "supplier-coupon", benefitRevision: "benefit-v1",
        label: "Supplier saving", publisherType: "supplier", effect: "instant_discount", amountBasis: "applied",
        sourceReference: "trusted-benefit-one", funderReference: "private-funder-one", amountMinor: 51,
        allocations: [{lineId: s.lines[0]!.sourceLineId, amountMinor: 51}]},
      {componentId: "cashback-component", benefitId: "payment-offer", benefitRevision: "benefit-v2",
        label: "Payment cashback offer", publisherType: "payment", effect: "cashback_offer", amountBasis: "maximum",
        sourceReference: "trusted-benefit-two", funderReference: "private-funder-two", amountMinor: 25,
        allocations: [{lineId: s.lines[0]!.sourceLineId, amountMinor: 25}]},
    ]},
  }))};
}

function variantReceipt(): TrustedPlacementReceipt {
  const base = normalizePlacement(attributedReceipt(), "evaluation");
  const stores = base.stores.map((s, i) => ({...s, lines: s.lines.map(l => ({...l,
    variant: i === 0 ? "गुलाबी\n128 GB" : ""}))}));
  const first = stores[0]!;
  first.lines.push({...first.lines[0]!, sourceLineId: "source-second-variant", skuId: "sku-second-variant",
    canonicalProductId: "product-second-variant", verifiedPackId: "pack-second-variant",
    offerId: "offer-second-variant", variant: "Blue · 512 GB"});
  first.totals = {...first.totals, itemsMinor: 20102, totalMinor: 20066};
  return {...base, schemaVersion: 3, stores};
}

for (const fault of ["missing", "null", "boolean", "array", "object", "outer-space", "whitespace", "control", "oversize", "old-version", "missing-benefits"]) {
  test(`LF-VARIANT rejects ${fault} without trimming or backfilling original descriptions`, () => {
    const input = JSON.parse(JSON.stringify(variantReceipt()));
    const first = input.stores[0].lines[0];
    if (fault === "missing") delete first.variant;
    if (fault === "null") first.variant = null;
    if (fault === "boolean") first.variant = false;
    if (fault === "array") first.variant = ["Pink"];
    if (fault === "object") first.variant = {label: "Pink"};
    if (fault === "outer-space") first.variant = " Pink";
    if (fault === "whitespace") first.variant = "\n";
    if (fault === "control") first.variant = "Pink\u0000";
    if (fault === "oversize") first.variant = "x".repeat(241);
    if (fault === "old-version") input.schemaVersion = 2;
    if (fault === "missing-benefits") delete input.stores[0].benefitAttribution;
    assert.throws(() => normalizePlacement(input, "evaluation"), rejectsCode("invalid_input"));
  });
}

test("LF-ATTR trusted original attribution preserves exact line discount and separately quoted cashback", () => {
  const input = attributedReceipt();
  const result = normalizePlacement(input, "evaluation");
  assert.deepEqual(result, input);
  assert.equal(result.stores[0]!.totals.totalMinor, 10015);
  assert.deepEqual(normalizePlacement(receipt(), "evaluation"), receipt(), "Legacy bytes/facts remain unchanged");
});

test("LF-ATTR supplied empty attribution is distinct from legacy unknown", () => {
  const input = attributedReceipt();
  input.stores.forEach(s => {
    s.benefitAttribution.components = [];
    s.totals.discountMinor = 0; s.totals.totalMinor += 51;
  });
  assert.deepEqual(normalizePlacement(input, "evaluation"), input);
});

for (const fault of ["missing", "null", "version", "extra", "unknown-line", "duplicate-component", "duplicate-line",
  "publisher", "cashback-basis", "discount-basis", "fractional", "negative", "unsafe", "sum", "discount-total", "combined-gross"]) {
  test(`LF-ATTR rejects ${fault} without inventing or repairing allocations`, () => {
    const input = JSON.parse(JSON.stringify(attributedReceipt())) as {stores: Record<string, unknown>[]};
    const store = input.stores[0]!, group = store.benefitAttribution as Record<string, unknown>;
    const components = group.components as Record<string, unknown>[], first = components[0]!, cashback = components[1]!;
    const allocations = first.allocations as Record<string, unknown>[];
    if (fault === "missing") delete store.benefitAttribution;
    if (fault === "null") store.benefitAttribution = null;
    if (fault === "version") group.schemaVersion = 2;
    if (fault === "extra") first.paid = true;
    if (fault === "unknown-line") allocations[0]!.lineId = "source-two";
    if (fault === "duplicate-component") components.push(structuredClone(first));
    if (fault === "duplicate-line") allocations.push(structuredClone(allocations[0]!));
    if (fault === "publisher") first.publisherType = "guessed";
    if (fault === "cashback-basis") cashback.amountBasis = "applied";
    if (fault === "discount-basis") first.amountBasis = "quoted";
    if (fault === "fractional") first.amountMinor = 0.5;
    if (fault === "negative") first.amountMinor = -1;
    if (fault === "unsafe") first.amountMinor = Number.MAX_SAFE_INTEGER + 1;
    if (fault === "sum") allocations[0]!.amountMinor = 50;
    if (fault === "discount-total") {first.amountMinor = 50; allocations[0]!.amountMinor = 50;}
    if (fault === "combined-gross") {
      const lines = store.lines as Record<string, unknown>[];
      lines.push({...lines[0], sourceLineId: "source-extra"});
      const totals = store.totals as Record<string, unknown>;
      totals.itemsMinor = 20102; totals.discountMinor = 12000; totals.totalMinor = 8117;
      first.amountMinor = 6000; allocations[0]!.amountMinor = 6000;
      components.push({...structuredClone(first), componentId: "second-discount-component"});
    }
    assert.throws(() => normalizePlacement(input, "evaluation"), rejectsCode("invalid_input"));
  });
}

for (const includeVariants of [false, true]) {
test(`LF-ATTR actual materializer retains exact source allocations across restart and Store partitions variants=${includeVariants}`, {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-benefit-original"}, `benefits-${randomUUID()}`);
  const db = getFirestore(app), suffix = randomUUID();
  const input: TrustedPlacementReceipt = {...(includeVariants ? variantReceipt() : normalizePlacement(attributedReceipt(), "evaluation")),
    receiptId: `benefit-${suffix}`, buyerUserId: `buyer-${suffix}`, schemaVersion: includeVariants ? 3 : 2};
  input.stores.forEach((s, i) => {
    s.storeId = `store-${suffix}-${i}`; s.caseId = `case-${suffix}-${i}`; s.ownerUserId = `owner-${suffix}-${i}`;
  });
  for (const s of input.stores) await db.collection("workspaceProfiles").doc(s.caseId).set({
    schemaVersion: 1, caseId: s.caseId, workspaceId: s.storeId, ownerUserId: s.ownerUserId,
    familyId: "products-trade", profileId: "retailer-grocery", status: "live", shopEnabled: true,
  });
  try {
    const source = {readFinalPlacement: async () => input as TrustedPlacementReceipt};
    const writer = new WorkspacePurchaseProjectionService(db, "evaluation", source);
    const created = await writer.materialize("original-benefit-source");
    assert.deepEqual(await writer.materialize("original-benefit-source"), created);
    const restarted = new WorkspacePurchaseProjectionService(db, "evaluation");
    const buyer = await restarted.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId});
    if (!includeVariants && process.env.LF_ATTR_PROJECTION_CAPTURE === "true") {
      console.log(`LF_ATTR_PROJECTION=${JSON.stringify(buyer)}`);
    }
    if (includeVariants && process.env.LF_VARIANT_PROJECTION_CAPTURE === "true") {
      console.log(`LF_VARIANT_PROJECTION=${JSON.stringify(buyer)}`);
    }
    assert.equal(buyer.schemaVersion, includeVariants ? 4 : 3); assert.equal(buyer.orders.length, 2);
    for (const original of buyer.orders) {
      const source = input.stores.find(s => s.storeId === original.storeId)!;
      assert.equal(original.factsVersion, includeVariants ? 4 : 3);
      assert.deepEqual(original.original.totals, source.totals);
      const allocated = original.original.lines.find(l => l.skuId === source.lines[0]!.skuId)!;
      assert.equal(original.original.benefitAttribution!.components[0]!.allocations[0]!.lineId, allocated.lineId);
      assert.equal(original.original.benefitAttribution!.components[1]!.amountBasis, "maximum");
      for (const line of original.original.lines) {
        assert.equal(line.variant, source.lines.find(l => l.skuId === line.skuId)!.variant);
      }
    }
    const first = input.stores[0]!, order = buyer.orders.find(o => o.storeId === first.storeId)!;
    const tuple = {purchaseId: buyer.purchaseId, storeId: order.storeId, orderId: order.orderId};
    const seller = await restarted.readStore(first.ownerUserId, tuple);
    assert.deepEqual(seller.orders, [order]);
    assert.equal(JSON.stringify(seller).includes(input.stores[1]!.storeId), false);
    assert.equal((await restarted.listStore(first.ownerUserId, {storeId: first.storeId, limit: 5, cursor: null})).references[0]!.originalFingerprint,
      order.originalFingerprint);
    const proof = {...operationalEvidence(), ...tuple, originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision};
    const ops = new WorkspaceOrderOperationsService(db, "evaluation", {readOperationalOrder: async () => proof},
      () => new Date("2026-10-16T12:00:00.000Z"));
    await ops.initialize("benefit-operation-source");
    const operational = await ops.read(first.ownerUserId, "seller", tuple);
    assert.equal(operational.originalFactsVersion, includeVariants ? 4 : 3); assert.deepEqual(operational.original, order.original);
    const result = await ops.command(first.ownerUserId, {...tuple, version: 2, operationId: "STORE-ORDER-attribution_nonce==",
      expectedRevision: 1, action: "accept", reason: null});
    assert.deepEqual(result.snapshot.original, order.original);
    assert.deepEqual((await ops.command(first.ownerUserId, {...tuple, version: 2, operationId: "STORE-ORDER-attribution_nonce==",
      expectedRevision: 1, action: "accept", reason: null}, true)).snapshot.original, order.original);
    const legacyInput: TrustedPlacementReceipt = {...input, schemaVersion: 1, receiptId: `legacy-${suffix}`,
      stores: input.stores.map(({benefitAttribution: _attribution, ...store}) => ({...store,
        lines: store.lines.map(({variant: _variant, ...line}) => line)}))};
    const legacyWriter = new WorkspacePurchaseProjectionService(db, "evaluation", {readFinalPlacement: async () => legacyInput});
    const legacyCreated = await legacyWriter.materialize("legacy-original-source");
    const legacyRead = await restarted.readBuyer(input.buyerUserId, {purchaseId: legacyCreated.purchaseId});
    assert.equal(legacyRead.schemaVersion, 2); assert.equal(legacyRead.buyerId, buyer.buyerId);
    assert.equal(legacyRead.orders[0]!.original.benefitAttribution, undefined);
    const mixedBuyer = await restarted.listBuyer(input.buyerUserId, {limit: 5, cursor: null});
    assert.equal(new Set(mixedBuyer.references.map(r => r.purchaseId)).size, 2);
    const mixedStore = await restarted.listStore(first.ownerUserId, {storeId: first.storeId, limit: 5, cursor: null});
    assert.equal(mixedStore.references.length, 2);
    for (const ref of mixedStore.references) {
      const read = await restarted.readStore(first.ownerUserId, {purchaseId: ref.purchaseId, storeId: ref.storeId, orderId: ref.orderId});
      assert.equal(read.orders[0]!.originalFingerprint, ref.originalFingerprint);
    }
    if (includeVariants) {
      const original = input.stores[0]!.lines[0]!.variant!;
      input.stores[0]!.lines[0]!.variant = "Current catalogue changed";
      await assert.rejects(writer.materialize("original-benefit-source"), rejectsCode("conflict"));
      assert.deepEqual(await restarted.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId}), buyer);
      input.stores[0]!.lines[0]!.variant = original;
    }
    const component = input.stores[0]!.benefitAttribution!.components[0]!;
    component.amountMinor--; component.allocations[0]!.amountMinor--;
    input.stores[0]!.totals.discountMinor--; input.stores[0]!.totals.totalMinor++;
    await assert.rejects(writer.materialize("original-benefit-source"), rejectsCode("conflict"));
    assert.deepEqual(await restarted.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId}), buyer);
  } finally {await db.terminate(); await deleteApp(app);}
});
}

test("LF-ATTR allocation-heavy source cannot commit an original exceeding client readback budget", {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-benefit-budget"}, `budget-${randomUUID()}`);
  const db = getFirestore(app), suffix = randomUUID();
  const input: TrustedPlacementReceipt = {...receipt(), schemaVersion: 2, buyerUserId: `buyer-${suffix}`, receiptId: `receipt-${suffix}`};
  input.stores.forEach((s, index) => {
    s.storeId = `store-${suffix}-${index}`; s.caseId = `case-${suffix}-${index}`; s.ownerUserId = `owner-${suffix}-${index}`;
    s.lines = Array.from({length: 100}, (_, i) => ({sourceLineId: `${index === 0 ? "a" : "b"}${String(i).padStart(2, "0")}`,
      skuId: "sku", canonicalProductId: "prd", verifiedPackId: "pak", offerId: "ofr", offerRevision: "rev",
      name: "d", packLabel: "p", quantityMilli: 1000, quantityUnit: "pack", unitPriceMinor: 10051, lineTotalMinor: 10051}));
    s.totals = {...s.totals, itemsMinor: 1005100, discountMinor: 3200, totalMinor: 1001915};
    s.benefitAttribution = {schemaVersion: 1, components: Array.from({length: 32}, (_, i) => ({
      componentId: `component-${i}`, benefitId: `benefit-${i}`, benefitRevision: "rev", label: "x".repeat(200),
      publisherType: "supplier", effect: "instant_discount", amountBasis: "applied", sourceReference: "src", funderReference: "fund",
      amountMinor: 100, allocations: s.lines.map(l => ({lineId: l.sourceLineId, amountMinor: 1})),
    }))};
  });
  assert.ok(Buffer.byteLength(JSON.stringify(normalizePlacement(input, "evaluation")), "utf8") < 300000,
    "The original source must be valid below the established source bound");
  for (const s of input.stores) await db.collection("workspaceProfiles").doc(s.caseId).set({
    schemaVersion: 1, caseId: s.caseId, workspaceId: s.storeId, ownerUserId: s.ownerUserId,
    familyId: "products-trade", profileId: "retailer-grocery", status: "live", shopEnabled: true,
  });
  try {
    const service = new WorkspacePurchaseProjectionService(db, "evaluation", {readFinalPlacement: async () => input});
    await assert.rejects(service.materialize("allocation-heavy-source"), rejectsCode("invalid_input"));
    const root = db.collection("workspacePurchaseProjections").doc("evaluation");
    assert.equal((await root.collection("purchases").where("buyerUserId", "==", input.buyerUserId).get()).empty, true);
    const digest = (v: unknown) => createHash("sha256").update(JSON.stringify(v)).digest("hex");
    assert.equal((await root.collection("buyers").doc(digest([input.authNamespace, input.buyerUserId])).get()).exists, false);
    assert.equal((await root.collection("receipts").doc(digest([input.realm, input.authNamespace, input.buyerUserId, input.issuer, input.receiptId])).get()).exists, false);
  } finally {await db.terminate(); await deleteApp(app);}
});

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
