import assert from "node:assert/strict";
import {createHash, randomUUID} from "node:crypto";
import test from "node:test";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {WorkspaceProfileError} from "./workspace_profile_service.js";
import {WorkspacePurchaseProjectionService, normalizePlacement, requireDefaultPurchaseTenant,
  WorkspaceOrderOperationsService, normalizeOperationalOrder,
  normalizeOrderCompletion, purchaseOriginalFingerprint, type TrustedOrderCompletionEvidence,
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

test("completion has an explicit internal producer and separate authorized reader, never inferred from Ready", () => {
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "recordCompletion"), "function");
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "readCompletion"), "function");
});

test("LF-FEEDBACK exact completed product targets have a private authenticated discovery surface", () => {
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "listBuyerProductFeedbackTargets"), "function");
});

function completionEvidence(): TrustedOrderCompletionEvidence {
  return {schemaVersion: 1, realm: "evaluation", authNamespace: "firebase-default", issuer: "trusted-fulfilment",
    receiptId: "completion-receipt", revision: "completion-v1", purchaseId: "purchase-one", storeId: "store-one", orderId: "order-one",
    originalFingerprint: "a".repeat(64), sourceRevision: "revision-1", operationalSourceRevision: "operations-v1",
    operationalRevision: 3, outcome: "delivered", occurredAt: "2026-10-16T12:00:00.000Z"};
}
test("completion proof is strict scoped source evidence, not payment or client confirmation", () => {
  const proof = completionEvidence(), now = new Date(proof.occurredAt);
  assert.deepEqual(normalizeOrderCompletion(proof, "evaluation", now), proof);
  for (const patch of [{realm: "production"}, {authNamespace: "tenant-other"}, {issuer: ""}, {receiptId: ""},
    {revision: ""}, {operationalRevision: 0}, {operationalRevision: 1.5}, {operationalSourceRevision: ""},
    {outcome: ["delivered"]}, {outcome: "ready"}, {originalFingerprint: "wrong"}, {originalFingerprint: ["a".repeat(64)]},
    {occurredAt: "2026-10-16T12:00:00.001Z"}, {occurredAt: "2026-10-16T12:00:00Z"},
    {paid: true}, {customerContact: "not-public"}]) {
    assert.throws(() => normalizeOrderCompletion({...proof, ...patch}, "evaluation", now), rejectsCode("invalid_input"));
  }
});
for (const fulfilment of ["delivery", "collection"] as const) {
test(`completion ${fulfilment} is atomic, authorized, durable and never inferred`, {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-completion"}, `completion-${randomUUID()}`), db = getFirestore(app);
  const value = receipt(randomUUID()), suffix = randomUUID(), now = new Date("2026-10-16T12:00:00.000Z");
  value.buyerUserId = `buyer-${suffix}`;
  for (const [i, store] of value.stores.entries()) {
    store.caseId = `case-${suffix}-${i}`; store.storeId = `store-${suffix}-${i}`; store.ownerUserId = `owner-${suffix}-${i}`;
    await db.collection("workspaceProfiles").doc(store.caseId).set({schemaVersion: 1, caseId: store.caseId,
      workspaceId: store.storeId, ownerUserId: store.ownerUserId, familyId: "products-trade",
      profileId: "retailer-grocery", status: "live", shopEnabled: true});
  }
  try {
    const originals = new WorkspacePurchaseProjectionService(db, "evaluation", {readFinalPlacement: async () => value});
    const made = await originals.materialize(`source-${suffix}`);
    const original = await originals.readBuyer(value.buyerUserId, {purchaseId: made.purchaseId}), partition = original.orders[0]!;
    const scope = {purchaseId: made.purchaseId, storeId: partition.storeId, orderId: partition.orderId}, owner = value.stores[0]!.ownerUserId;
    const op: TrustedOperationalOrderEvidence = {...operationalEvidence(), ...scope, fulfilment,
      originalFingerprint: partition.originalFingerprint, sourceRevision: original.sourceRevision,
      initialStage: fulfilment === "delivery" ? "Confirmed" : "Ready", allowedActions: fulfilment === "delivery" ? ["accept", "ready", "reject"] : []};
    let proof: TrustedOrderCompletionEvidence | undefined = {...completionEvidence(), ...scope,
      receiptId: `completion-${suffix}`,
      originalFingerprint: partition.originalFingerprint, sourceRevision: original.sourceRevision,
      operationalRevision: fulfilment === "delivery" ? 3 : 1, outcome: fulfilment === "delivery" ? "delivered" : "collected"};
    let reads = 0;
    const service = new WorkspaceOrderOperationsService(db, "evaluation", {readOperationalOrder: async () => op}, () => now,
      {issuer: "trusted-fulfilment", readCompletion: async () => {reads++; return proof;}});
    const fresh = new WorkspaceOrderOperationsService(db, "evaluation", undefined, () => now);
    await assert.rejects(fresh.recordCompletion("unconfigured"), rejectsCode("service_unavailable"));
    await service.initialize("trusted-operations");
    const absent = await fresh.readCompletion(value.buyerUserId, "buyer", scope) as Record<string, unknown>;
    assert.equal(absent.state, "not_supplied"); assert.equal(absent.completion, null);
    if (fulfilment === "delivery") {
      await assert.rejects(service.recordCompletion("too-early"), rejectsCode("invalid_state"));
      const accept = {version: 2, ...scope, operationId: "accepted-before-completion", expectedRevision: 1, action: "accept", reason: null};
      assert.equal((await fresh.command(owner, accept)).state, "applied");
      const ready = {version: 2, ...scope, operationId: "ready-before-completion", expectedRevision: 2, action: "ready", reason: null};
      const readyAck = await fresh.command(owner, ready);
      assert.equal(readyAck.state, "applied");
      assert.equal((await fresh.readCompletion(value.buyerUserId, "buyer", scope) as Record<string, unknown>).state, "not_supplied");
    }
    const valid = proof!;
    for (const patch of [{issuer: "unconfigured-issuer"}, {originalFingerprint: "b".repeat(64)},
      {sourceRevision: "different-original"}, {operationalSourceRevision: "different-operation"},
      {operationalRevision: 99}, {outcome: fulfilment === "delivery" ? "collected" : "delivered"},
      {occurredAt: "2026-10-16T11:59:58.000Z"}]) {
      proof = {...valid, ...patch} as TrustedOrderCompletionEvidence;
      await assert.rejects(service.recordCompletion(`invalid-${randomUUID()}`), e => e instanceof WorkspaceProfileError);
    }
    proof = valid;
    const reference = `completion-${suffix}`;
    const [first, second, competing] = await Promise.allSettled([service.recordCompletion(reference), service.recordCompletion(reference),
      fresh.command(owner, {version: 2, ...scope, operationId: "competing-rejection", expectedRevision: valid.operationalRevision, action: "reject", reason: "Late rejection"})]);
    if (first.status === "rejected") throw first.reason;
    if (second.status === "rejected") throw second.reason;
    if (competing.status === "rejected") throw competing.reason;
    assert.deepEqual(first.value, second.value); assert.equal(competing.value.state, "rejected");
    const ack = first.value;
    assert.equal(ack.completion.outcome, valid.outcome);
    assert.deepEqual(await originals.readBuyer(value.buyerUserId, {purchaseId: made.purchaseId}), original);
    assert.equal((await fresh.read(owner, "seller", scope)).permittedActions.length, 0);
    await assert.rejects(service.recordCompletion("another-reference"), rejectsCode("conflict"));
    const other = original.orders[1]!;
    const otherScope = {purchaseId: made.purchaseId, storeId: other.storeId, orderId: other.orderId};
    const otherProof = {...op, ...otherScope, originalFingerprint: other.originalFingerprint, initialStage: "Ready" as const};
    const otherService = new WorkspaceOrderOperationsService(db, "evaluation", {readOperationalOrder: async () => otherProof}, () => now,
      {issuer: "trusted-fulfilment", readCompletion: async () => ({...valid, ...otherScope,
        originalFingerprint: other.originalFingerprint, operationalRevision: 1})});
    await otherService.initialize("second-store-operations");
    await assert.rejects(otherService.recordCompletion(`reused-source-receipt-${suffix}`), rejectsCode("conflict"));
    assert.equal((await fresh.readCompletion(value.buyerUserId, "buyer", otherScope) as Record<string, unknown>).state, "not_supplied");
    const beforeReplay = reads; proof = undefined;
    assert.deepEqual(await service.recordCompletion(reference), ack); assert.equal(reads, beforeReplay);
    const restarted = new WorkspaceOrderOperationsService(db, "evaluation", undefined, () => now,
      {issuer: "trusted-fulfilment", readCompletion: async () => {throw new Error("source unavailable after acceptance");}});
    assert.deepEqual(await restarted.recordCompletion(reference), ack);
    await assert.rejects(fresh.readCompletion("unrelated-buyer", "buyer", scope), rejectsCode("not_found"));
    await assert.rejects(fresh.readCompletion(value.stores[1]!.ownerUserId, "seller", scope), rejectsCode("not_found"));
    await db.collection("workspaceProfiles").doc(value.stores[0]!.caseId).update({shopEnabled: false});
    const seller = await fresh.readCompletion(owner, "seller", scope) as Record<string, unknown>;
    const buyer = await fresh.readCompletion(value.buyerUserId, "buyer", scope) as Record<string, unknown>;
    console.log(`LF_COMPLETION_PROJECTION=${JSON.stringify({buyer, seller})}`);
    assert.equal(seller.state, "recorded"); assert.deepEqual(seller.completion, buyer.completion);
    assert.equal(JSON.stringify(seller).includes("trusted-fulfilment"), false);
    for (const privateKey of ["proof", "address", "customerLabel", "ownerUserId", "buyerUserId", "orders"]) assert.equal(privateKey in seller, false);
    if (fulfilment === "delivery") {
      const reconciled = await fresh.command(owner, {version: 2, ...scope, operationId: "ready-before-completion", expectedRevision: 2, action: "ready", reason: null}, true);
      assert.equal(reconciled.state, "applied"); assert.equal(reconciled.snapshot.revision, 3);
    }
    const terminal = db.collection("workspacePurchaseProjections").doc("evaluation").collection("orderCompletions").doc(scope.orderId);
    const stored = (await terminal.get()).data()!; await terminal.update({recordedAt: "2026-10-16T11:00:00.000Z"});
    await assert.rejects(fresh.readCompletion(owner, "seller", scope), rejectsCode("invalid_state"));
    await terminal.set(stored);
    function canonicalCompletion(v: unknown): unknown {
      if (Array.isArray(v)) return v.map(canonicalCompletion);
      if (v !== null && typeof v === "object") return Object.fromEntries(Object.entries(v)
        .sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0).map(([key, value]) => [key, canonicalCompletion(value)]));
      return v;
    }
    for (const field of ["referenceDigest", "operationalProofFingerprint"]) {
      const {integrity: _ignored, ...body} = {...stored, [field]: [stored[field]]};
      const malformed = {...body, integrity: createHash("sha256").update(JSON.stringify(canonicalCompletion(body))).digest("hex")};
      await terminal.set(malformed);
      await assert.rejects(fresh.readCompletion(owner, "seller", scope), rejectsCode("invalid_state"));
      await terminal.set(stored);
    }
  } finally {await db.terminate(); await deleteApp(app);}
});
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

function publicListingReceipt() {
  const value = JSON.parse(JSON.stringify(scheduledReceipt()));
  value.schemaVersion = 5;
  value.stores.forEach((store: {storeId: string; lines: Array<Record<string, unknown>>}, index: number) => {
    for (const line of store.lines) {
      const channel = index === 0 ? "retail" : "wholesale";
      line.publicListing = {schemaVersion: 1, realm: "evaluation",
        listingId: `listing-${createHash("sha256").update(JSON.stringify([1, "evaluation", store.storeId, line.skuId, channel])).digest("hex")}`,
        storeId: store.storeId, skuId: line.skuId, canonicalProductId: line.canonicalProductId, verifiedPackId: line.verifiedPackId, channel};
    }
  });
  return value;
}
test("LF-LISTING frozen ordinary purchased context survives independently of desired Scheduled intent", () => {
  const input = publicListingReceipt();
  assert.deepEqual(normalizePlacement(input, "evaluation"), input);
  assert.equal(input.stores[1].lines[0].publicListing.channel, "wholesale");
  assert.equal(input.stores[1].lines[0].scheduledFulfilment, null);
  const bulk = publicListingReceipt(), line = bulk.stores[1].lines[0], storeId = bulk.stores[1].storeId;
  line.publicListing.channel = "bulk";
  line.publicListing.listingId = `listing-${createHash("sha256").update(JSON.stringify([1, "evaluation", storeId, line.skuId, "bulk"])).digest("hex")}`;
  assert.deepEqual(normalizePlacement(bulk, "evaluation"), bulk);
});
test("LF-LISTING explicit null stays unknown even when desired Scheduled contains a listing", () => {
  const input = publicListingReceipt();
  for (const store of input.stores) for (const line of store.lines) line.publicListing = null;
  const result = normalizePlacement(input, "evaluation");
  assert.equal(result.schemaVersion, 5);
  assert.equal(Reflect.get(result.stores[0]!.lines[0]!, "publicListing"), null);
  assert.notEqual(result.stores[0]!.lines[0]!.scheduledFulfilment, null);
});
for (const [fault, mutate] of Object.entries<(input: ReturnType<typeof publicListingReceipt>) => void>({
  "missing listing": v => delete v.stores[0].lines[0].publicListing,
  "old receipt with new field": v => v.schemaVersion = 4,
  "missing inherited Scheduled": v => delete v.stores[0].lines[0].scheduledFulfilment,
  "missing inherited variant": v => delete v.stores[0].lines[0].variant,
  "missing inherited benefits": v => delete v.stores[0].benefitAttribution,
  "wrong realm": v => v.stores[0].lines[0].publicListing.realm = "production",
  "wrong Store": v => v.stores[0].lines[0].publicListing.storeId = "other-store",
  "wrong SKU": v => v.stores[0].lines[0].publicListing.skuId = "other-sku",
  "wrong canonical": v => v.stores[0].lines[0].publicListing.canonicalProductId = "other-product",
  "wrong pack": v => v.stores[0].lines[0].publicListing.verifiedPackId = "other-pack",
  "forged stable ID": v => v.stores[0].lines[0].publicListing.listingId = `listing-${"a".repeat(64)}`,
  "unknown channel": v => v.stores[0].lines[0].publicListing.channel = "standard",
  "private extra field": v => v.stores[0].lines[0].publicListing.purchaseCost = 99,
  "array instead of identity": v => v.stores[0].lines[0].publicListing = [v.stores[0].lines[0].publicListing],
  "contradictory desired channel": v => {
    const l = v.stores[0].lines[0], s = l.scheduledFulfilment.listing;
    s.channel = "wholesale"; s.listingId = `listing-${createHash("sha256").update(JSON.stringify([1, "evaluation", s.storeId, s.skuId, s.channel])).digest("hex")}`;
  },
})) test(`LF-LISTING rejects ${fault} without guessing purchased identity`, () => {
  const input = publicListingReceipt(); mutate(input);
  assert.throws(() => normalizePlacement(input, "evaluation"), rejectsCode("invalid_input"));
});

for (const allNull of [false, true]) {
test(`LF-LISTING actual persisted originals preserve explicit provenance across restart allNull=${allNull}`, {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async (t) => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  // Isolated demo project per run: historical fixtures must not populate this
  // Store's private paginated feed or contend with another test's transactions.
  const app = initializeApp({projectId: `demo-lf-listing-${randomUUID().slice(0, 8)}`}, `listing-${randomUUID()}`), db = getFirestore(app);
  const value = publicListingReceipt(); value.receiptId = `receipt-${randomUUID()}`; value.buyerUserId = `buyer-${randomUUID()}`;
  if (allNull) for (const store of value.stores) for (const line of store.lines) line.publicListing = null;
  for (const store of value.stores) await db.collection("workspaceProfiles").doc(store.caseId).set({
    schemaVersion: 1, caseId: store.caseId, workspaceId: store.storeId, ownerUserId: store.ownerUserId,
    familyId: "products-trade", profileId: "retailer-grocery", status: "live", shopEnabled: true,
  });
  try {
    const producer = new WorkspacePurchaseProjectionService(db, "evaluation", {readFinalPlacement: async () => value});
    const created = await producer.materialize("listing-original");
    assert.deepEqual(await producer.materialize("listing-original"), created);
    const reader = new WorkspacePurchaseProjectionService(db, "evaluation");
    const buyer = await reader.readBuyer(value.buyerUserId, {purchaseId: created.purchaseId});
    assert.equal(buyer.schemaVersion, 6);
    for (const order of buyer.orders) {
      assert.equal(order.factsVersion, 6);
      const source = value.stores.find((s: {storeId: string}) => s.storeId === order.storeId);
      for (const line of order.original.lines) {
        assert.equal(Object.hasOwn(line, "publicListing"), true);
        assert.deepEqual(line.publicListing, source.lines.find((l: {skuId: string}) => l.skuId === line.skuId).publicListing);
        assert.equal(line.unitPriceMinor, source.lines[0].unitPriceMinor);
      }
      const legacy = {...order.original, lines: order.original.lines.map(({publicListing: _unknown, ...line}) => line)};
      assert.notEqual(purchaseOriginalFingerprint(order.storeId, order.orderId, legacy), order.originalFingerprint);
    }
    const first = buyer.orders[0]!, scope = {purchaseId: buyer.purchaseId, storeId: first.storeId, orderId: first.orderId};
    const savedBefore = JSON.stringify((await db.collection("workspacePurchaseProjections").doc("evaluation").collection("purchases").doc(created.purchaseId).get()).data());
    await db.collection("workspaceProfiles").doc(value.stores[0].caseId).update({shopEnabled: false});
    const seller = await reader.readStore(value.stores[0].ownerUserId, scope);
    assert.deepEqual(seller.orders, [first]);
    const pageBody = {storeId: first.storeId, limit: 5, cursor: null};
    assert.equal((await reader.listStore(value.stores[0].ownerUserId, pageBody)).viewerRole, "seller");
    await assert.rejects(reader.readStore(value.stores[1].ownerUserId, scope), rejectsCode("not_found"));
    await assert.rejects(reader.listStore(value.stores[1].ownerUserId, pageBody), rejectsCode("not_found"));
    assert.deepEqual(await producer.materialize("listing-original"), created);
    const oldReceipt = value.receiptId; value.receiptId = `new-paused-${randomUUID()}`;
    await assert.rejects(producer.materialize("new-sales-while-paused"), rejectsCode("not_found"));
    value.receiptId = oldReceipt;
    assert.equal(JSON.stringify((await db.collection("workspacePurchaseProjections").doc("evaluation").collection("purchases").doc(created.purchaseId).get()).data()), savedBefore);
    const operations = new WorkspaceOrderOperationsService(db, "evaluation", {readOperationalOrder: async () => ({...operationalEvidence(), ...scope,
      originalFingerprint: first.originalFingerprint, sourceRevision: buyer.sourceRevision, initialStage: "Ready"})}, () => new Date(),
      {issuer: "trusted-fulfilment", readCompletion: async () => ({...completionEvidence(), ...scope,
        receiptId: `listing-completion-${buyer.purchaseId}`, originalFingerprint: first.originalFingerprint,
        sourceRevision: buyer.sourceRevision, operationalRevision: 1})});
    await operations.initialize("listing-operation");
    const operational = await operations.read(value.buyerUserId, "buyer", scope);
    assert.equal(operational.originalFactsVersion, 6); assert.deepEqual(operational.original, first.original);
    assert.deepEqual((await operations.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 5, cursor: null})).targets, []);
    const completionReference = `listing-completion-${buyer.purchaseId}`;
    const completed = await operations.recordCompletion(completionReference);
    assert.equal(completed.state, "recorded");
    assert.equal(completed.purchaseId, buyer.purchaseId);
    assert.equal(completed.orderId, first.orderId);
    const targets = await operations.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 1, cursor: null});
    assert.equal(targets.coverage, "indexed_recorded_completions");
    assert.equal(targets.targets.length, allNull ? 0 : 1);
    assert.deepEqual((await operations.listBuyerProductFeedbackTargets("unrelated-buyer", {limit: 5, cursor: null})).targets, []);
    await assert.rejects(operations.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 6, cursor: null}), rejectsCode("invalid_input"));
    await assert.rejects(operations.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 1, cursor: null, buyerUserId: value.buyerUserId}), rejectsCode("invalid_input"));
    if (!allNull) {
      const target = targets.targets[0]!;
      const purchased = first.original.lines.find(line => line.lineId === target.orderLineId)!;
      assert.deepEqual(target.purchasedListing, purchased.publicListing);
      assert.equal(target.completionId, completed.completion.id);
      assert.equal(target.productLabel, purchased.name);
      assert.equal(target.originalFingerprint, first.originalFingerprint);
      assert.equal(Object.hasOwn(target, "buyerUserId"), false);
      assert.equal(Object.hasOwn(target, "customerLabel"), false);
      const starCommand = {targetId: target.id, expectedRevision: 0, operationId: "stars-first", stars: 1};
      t.diagnostic("private stars: target validated; checking read-only reconcile and payload rejection");
      const root = db.collection("workspacePurchaseProjections").doc("evaluation");
      const receiptCount = (await root.collection("productStarReceipts").get()).size;
      assert.equal((await operations.submitProductStars(value.buyerUserId, starCommand, true)).state, "not_recorded");
      assert.equal((await root.collection("productStarReceipts").get()).size, receiptCount);
      assert.equal(await operations.readBuyerProductStars(value.buyerUserId, {targetId: target.id}), null);
      await assert.rejects(operations.submitProductStars("unrelated-buyer", starCommand), rejectsCode("not_found"));
      for (const stars of [0, 6, 1.5, "5", null]) {
        await assert.rejects(operations.submitProductStars(value.buyerUserId, {...starCommand, stars}), rejectsCode("invalid_input"));
      }
      for (const extra of [{comment: "not collected"}, {storeId: first.storeId}, {public: true}]) {
        await assert.rejects(operations.submitProductStars(value.buyerUserId, {...starCommand, ...extra}), rejectsCode("invalid_input"));
      }
      t.diagnostic("private stars: reconcile and invalid payloads passed; starting concurrent same-key save");
      const [starOne, replayOne] = await Promise.all([operations.submitProductStars(value.buyerUserId, starCommand),
        operations.submitProductStars(value.buyerUserId, starCommand)]);
      t.diagnostic("private stars: concurrent original attempt accepted");
      assert.deepEqual(starOne, replayOne); assert.equal(starOne.rating!.stars, 1);
      const restart = new WorkspaceOrderOperationsService(db, "evaluation");
      assert.deepEqual(await restart.submitProductStars(value.buyerUserId, starCommand, true), starOne);
      for (let stars = 2; stars <= 5; stars++) {
        const next = await restart.submitProductStars(value.buyerUserId, {...starCommand,
          operationId: `stars-edit-${stars}`, expectedRevision: stars - 1, stars});
        assert.equal(next.rating!.stars, stars); assert.equal(next.rating!.revision, stars);
      }
      // Historical original receipt stays1star, even after later five-star edit.
      assert.deepEqual(await restart.submitProductStars(value.buyerUserId, starCommand), starOne);
      await assert.rejects(restart.submitProductStars(value.buyerUserId, {...starCommand, stars: 2}), rejectsCode("conflict"));
      await assert.rejects(restart.submitProductStars(value.buyerUserId, {...starCommand, operationId: "stale-edit"}), rejectsCode("conflict"));
      assert.equal((await restart.readBuyerProductStars(value.buyerUserId, {targetId: target.id}))!.stars, 5);
      const downgraded = await restart.submitProductStars(value.buyerUserId, {...starCommand, operationId: "stars-lower", expectedRevision: 5, stars: 1});
      assert.equal(downgraded.rating!.stars, 1);
      const sellerStars = await restart.listStoreProductStars(value.stores[0].ownerUserId, {storeId: first.storeId, limit: 5, cursor: null});
      t.diagnostic("private stars: all1-5 values and Store readback accepted");
      const sellerPage = sellerStars as {ratings: {stars: number; target: {id: string}}[]};
      assert.equal(sellerPage.ratings.find(r => r.target.id === target.id)!.stars, 1);
      assert.equal(JSON.stringify(sellerStars).includes(value.buyerUserId), false);
      assert.equal(JSON.stringify(sellerStars).includes("comment"), false);
      await assert.rejects(restart.listStoreProductStars(value.stores[1].ownerUserId,
        {storeId: first.storeId, limit: 5, cursor: null}), rejectsCode("not_found"));
      const ratingPath = root.collection("productStarRatings").doc(target.id), frozenStars = (await ratingPath.get()).data()!;
      await ratingPath.update({"rating.stars": 4});
      await assert.rejects(restart.readBuyerProductStars(value.buyerUserId, {targetId: target.id}), rejectsCode("invalid_state"));
      await assert.rejects(restart.listStoreProductStars(value.stores[0].ownerUserId,
        {storeId: first.storeId, limit: 5, cursor: null}), rejectsCode("invalid_state"));
      await ratingPath.set(frozenStars);
      console.log(`LF_PRIVATE_PRODUCT_STARS=${JSON.stringify({target, buyer: downgraded, seller: sellerStars})}`);
      await assert.rejects(operations.listBuyerProductFeedbackTargets("unrelated-buyer", {limit: 1, cursor: targets.nextCursor}), rejectsCode("invalid_input"));
      const path = db.collection("workspacePurchaseProjections").doc("evaluation").collection("productFeedbackTargets").doc(target.id);
      const frozen = (await path.get()).data()!;
      await path.update({"target.productLabel": "tampered"});
      await assert.rejects(operations.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 1, cursor: null}), rejectsCode("invalid_state"));
      await assert.rejects(operations.recordCompletion(completionReference), rejectsCode("invalid_state"));
      await path.set(frozen);
      await path.delete();
      const offline = new WorkspaceOrderOperationsService(db, "evaluation", undefined, () => new Date(),
        {issuer: "trusted-fulfilment", readCompletion: async () => {throw new Error("accepted reference must not call source");}});
      assert.deepEqual(await offline.recordCompletion(completionReference), completed);
      assert.deepEqual((await path.get()).data(), frozen);
      assert.deepEqual(await offline.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 1, cursor: null}), targets);
    }
    console.log(`LF_PRODUCT_TARGET_PROJECTION=${JSON.stringify(targets)}`);
    assert.deepEqual((await operations.read(value.buyerUserId, "buyer", scope)).original, first.original);
    console.log(`LF_LISTING_PROJECTION=${JSON.stringify({buyer, seller, operational})}`);
    await db.collection("workspaceProfiles").doc(value.stores[0].caseId).update({status: "suspended"});
    await assert.rejects(reader.readStore(value.stores[0].ownerUserId, scope), rejectsCode("not_found"));
    await assert.rejects(reader.listStore(value.stores[0].ownerUserId, pageBody), rejectsCode("not_found"));
  } finally {await db.terminate(); await deleteApp(app);}
});
}

test("LF-FEEDBACK private stars have submit/reconcile and retailer reader surfaces", () => {
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "submitProductStars"), "function");
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "listStoreProductStars"), "function");
});

test("LF-FEEDBACK collected maximum100-line Store completion creates bounded exact targets atomically", {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
  const app = initializeApp({projectId: "demo-lf-feedback-max"}, `feedback-${randomUUID()}`), db = getFirestore(app);
  const value = publicListingReceipt(), store = value.stores[0], base = store.lines[0], suffix = randomUUID();
  value.stores = [store]; value.receiptId = `max-${suffix}`; value.buyerUserId = `buyer-${suffix}`;
  store.caseId = `case-${suffix}`;
  store.lines = Array.from({length: 100}, (_, i) => {
    const skuId = `sku-${i.toString().padStart(3, "0")}`;
    return {...base, sourceLineId: `source-${skuId}`, skuId, scheduledFulfilment: null,
      publicListing: {...base.publicListing, skuId,
        listingId: `listing-${createHash("sha256").update(JSON.stringify([1, "evaluation", store.storeId, skuId, "retail"])).digest("hex")}`}};
  });
  const items = store.lines.reduce((sum: number, line: {lineTotalMinor: number}) => sum + line.lineTotalMinor, 0);
  store.totals = {itemsMinor: items, discountMinor: 0, taxMinor: 0, deliveryMinor: 0, freightMinor: 0, paymentFeeMinor: 0, tipMinor: 0, totalMinor: items};
  store.benefitAttribution = {schemaVersion: 1, components: []};
  await db.collection("workspaceProfiles").doc(store.caseId).set({schemaVersion: 1, caseId: store.caseId,
    workspaceId: store.storeId, ownerUserId: store.ownerUserId, familyId: "products-trade", profileId: "retailer-grocery", status: "live", shopEnabled: true});
  try {
    const originals = new WorkspacePurchaseProjectionService(db, "evaluation", {readFinalPlacement: async () => value});
    const made = await originals.materialize("max-placed"), buyer = await originals.readBuyer(value.buyerUserId, {purchaseId: made.purchaseId});
    const order = buyer.orders[0]!, scope = {purchaseId: buyer.purchaseId, storeId: order.storeId, orderId: order.orderId};
    const service = new WorkspaceOrderOperationsService(db, "evaluation", {readOperationalOrder: async () => ({...operationalEvidence(), ...scope,
      originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision, fulfilment: "collection", initialStage: "Ready", allowedActions: []})},
    () => new Date("2026-10-16T12:00:00.000Z"), {issuer: "trusted-fulfilment", readCompletion: async () => ({...completionEvidence(), ...scope,
      receiptId: `completion-${suffix}`, originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision,
      outcome: "collected", operationalRevision: 1})});
    await service.initialize("max-ready");
    const [one, two] = await Promise.all([service.recordCompletion(`max-complete-${suffix}`), service.recordCompletion(`max-complete-${suffix}`)]);
    assert.deepEqual(one, two);
    assert.equal(one.purchaseId, buyer.purchaseId);
    const root = db.collection("workspacePurchaseProjections").doc("evaluation");
    assert.equal((await root.collection("productFeedbackTargets").where("buyerUserId", "==", value.buyerUserId).get()).size, 100);
    const page = await service.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 5, cursor: null});
    assert.equal(page.targets.length, 5); assert.ok(page.nextCursor);
    const next = await service.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 5, cursor: page.nextCursor});
    assert.equal(next.targets.length, 5);
    assert.equal(new Set([...page.targets, ...next.targets].map(t => t.id)).size, 10);
    assert.equal((await originals.readBuyer(value.buyerUserId, {purchaseId: made.purchaseId})).orders[0]!.original.totals.totalMinor, items);
  } finally {await db.terminate(); await deleteApp(app);}
});

function scheduledReceipt() {
  const value = JSON.parse(JSON.stringify(variantReceipt()));
  value.schemaVersion = 4;
  for (const store of value.stores) for (const line of store.lines) line.scheduledFulfilment = null;
  const store = value.stores[0], line = store.lines[0];
  line.scheduledFulfilment = {schemaVersion: 1, method: "scheduled", listing: {
    schemaVersion: 1, realm: "evaluation",
    listingId: `listing-${createHash("sha256").update(JSON.stringify([1, "evaluation", store.storeId, line.skuId, "retail"])).digest("hex")}`,
    storeId: store.storeId, skuId: line.skuId, canonicalProductId: line.canonicalProductId,
    verifiedPackId: line.verifiedPackId, channel: "retail"},
    sourceRevision: "eligibility-original-one", locationKey: "opaque-destination-one", slotId: "slot-original-one",
    startsAt: "2026-10-15T23:59:59.123456Z", endsAt: "2026-10-16T00:00:00.000001Z"};
  return value;
}

test("LF-SCHEDULE original preserves exact historical desired context and explicit null without booking claims", () => {
  const input = scheduledReceipt();
  const result = normalizePlacement(input, "evaluation");
  assert.deepEqual(result, input);
  const line = result.stores[0]!.lines[0] as unknown as {scheduledFulfilment: {startsAt: string}};
  assert.equal(line.scheduledFulfilment.startsAt, "2026-10-15T23:59:59.123456Z");
});

test("LF-SCHEDULE maximum Dart timestamp cannot overflow by one microsecond", () => {
  const input = scheduledReceipt(), s = input.stores[0].lines[0].scheduledFulfilment;
  s.startsAt = "+275760-09-12T23:59:59.999999Z";
  s.endsAt = "+275760-09-13T00:00:00.000Z";
  assert.deepEqual(normalizePlacement(input, "evaluation"), input);
  s.endsAt = "+275760-09-13T00:00:00.000001Z";
  assert.throws(() => normalizePlacement(input, "evaluation"), rejectsCode("invalid_input"));
});

test("LF-SCHEDULE all-null supplied context stays new-version, not legacy or Quick", () => {
  const value = scheduledReceipt();
  for (const store of value.stores) for (const line of store.lines) line.scheduledFulfilment = null;
  const result = normalizePlacement(value, "evaluation");
  assert.equal(result.schemaVersion, 4);
  assert.equal(result.stores.every(s => s.lines.every(l => l.scheduledFulfilment === null)), true);
});

for (const [start, end] of [
  ["2026-10-15T23:59:59.123456Z", "2026-10-15T23:59:59.123457Z"],
  ["2026-10-15T23:59:59.123Z", "2026-10-16T00:00:00.000Z"],
  ["0000-02-29T23:59:59.000001Z", "0000-03-01T00:00:00.000Z"],
  ["-0001-01-01T00:00:00.000001Z", "-0001-01-01T00:00:00.000002Z"],
  ["+010000-01-01T00:00:00.123456Z", "+010000-01-01T00:00:00.123457Z"],
]) {
  test(`LF-SCHEDULE retains canonical UTC precision ${start}`, () => {
    const value = scheduledReceipt(), selected = value.stores[0].lines[0].scheduledFulfilment;
    selected.startsAt = start; selected.endsAt = end;
    assert.deepEqual(normalizePlacement(value, "evaluation"), value);
  });
}
for (const fault of ["missing", "boolean", "array", "object", "version", "method", "nested-version", "realm", "store", "sku", "product", "pack", "listing", "channel", "revision", "location", "slot", "extra", "invalid-day", "invalid-hour", "offset", "precision", "redundant-zero", "equal", "micro-before", "old-version"]) {
  test(`LF-SCHEDULE rejects ${fault} rather than silently converting desired context`, () => {
    const value = scheduledReceipt(), line = value.stores[0].lines[0], s = line.scheduledFulfilment;
    if (fault === "missing") delete line.scheduledFulfilment;
    if (fault === "boolean") line.scheduledFulfilment = false;
    if (fault === "array") line.scheduledFulfilment = [];
    if (fault === "object") line.scheduledFulfilment = {};
    if (fault === "version") s.schemaVersion = true;
    if (fault === "method") s.method = "quick";
    if (fault === "nested-version") s.listing.schemaVersion = 2;
    if (fault === "realm") s.listing.realm = "production";
    if (fault === "store") s.listing.storeId = "other-store";
    if (fault === "sku") s.listing.skuId = "other-sku";
    if (fault === "product") s.listing.canonicalProductId = "other-product";
    if (fault === "pack") s.listing.verifiedPackId = "other-pack";
    if (fault === "listing") s.listing.listingId = "made-up-listing";
    if (fault === "channel") s.listing.channel = "unknown";
    if (fault === "revision") s.sourceRevision = " ";
    if (fault === "location") delete s.locationKey;
    if (fault === "slot") s.slotId = null;
    if (fault === "extra") s.booked = true;
    if (fault === "invalid-day") s.startsAt = "2026-02-30T00:00:00.000Z";
    if (fault === "invalid-hour") s.startsAt = "2026-10-15T24:00:00.000Z";
    if (fault === "offset") s.startsAt = "2026-10-15T23:59:59.123456+00:00";
    if (fault === "precision") s.startsAt = "2026-10-15T23:59:59.1234567Z";
    if (fault === "redundant-zero") s.startsAt = "2026-10-15T23:59:59.123000Z";
    if (fault === "equal") s.endsAt = s.startsAt;
    if (fault === "micro-before") s.endsAt = "2026-10-15T23:59:59.123455Z";
    if (fault === "old-version") value.schemaVersion = 3;
    assert.throws(() => normalizePlacement(value, "evaluation"), rejectsCode("invalid_input"));
  });
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

for (const context of ["attribution", "variants", "scheduled"]) {
const includeVariants = context !== "attribution", includeScheduled = context === "scheduled";
test(`LF-ATTR actual materializer retains exact source allocations across restart and Store partitions context=${context}`, {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-benefit-original"}, `benefits-${randomUUID()}`);
  const db = getFirestore(app), suffix = randomUUID();
  const input: TrustedPlacementReceipt = {...(includeScheduled ? normalizePlacement(scheduledReceipt(), "evaluation") :
    includeVariants ? variantReceipt() : normalizePlacement(attributedReceipt(), "evaluation")),
    receiptId: `benefit-${suffix}`, buyerUserId: `buyer-${suffix}`, schemaVersion: includeScheduled ? 4 : includeVariants ? 3 : 2};
  input.stores.forEach((s, i) => {
    s.storeId = `store-${suffix}-${i}`; s.caseId = `case-${suffix}-${i}`; s.ownerUserId = `owner-${suffix}-${i}`;
    for (const l of s.lines) if (l.scheduledFulfilment) {
      l.scheduledFulfilment.listing.storeId = s.storeId;
      l.scheduledFulfilment.listing.listingId = `listing-${createHash("sha256").update(JSON.stringify([1, "evaluation", s.storeId, l.skuId, "retail"])).digest("hex")}`;
      l.scheduledFulfilment.startsAt = "2026-10-16T23:59:59.123456Z";
      l.scheduledFulfilment.endsAt = "2026-10-17T00:00:00.000001Z";
    }
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
    if (includeVariants && !includeScheduled && process.env.LF_VARIANT_PROJECTION_CAPTURE === "true") {
      console.log(`LF_VARIANT_PROJECTION=${JSON.stringify(buyer)}`);
    }
    if (includeScheduled && process.env.LF_SCHEDULE_PROJECTION_CAPTURE === "true") {
      console.log(`LF_SCHEDULE_PROJECTION=${JSON.stringify(buyer)}`);
    }
    assert.equal(buyer.schemaVersion, includeScheduled ? 5 : includeVariants ? 4 : 3); assert.equal(buyer.orders.length, 2);
    for (const original of buyer.orders) {
      const source = input.stores.find(s => s.storeId === original.storeId)!;
      assert.equal(original.factsVersion, includeScheduled ? 5 : includeVariants ? 4 : 3);
      assert.deepEqual(original.original.totals, source.totals);
      const allocated = original.original.lines.find(l => l.skuId === source.lines[0]!.skuId)!;
      assert.equal(original.original.benefitAttribution!.components[0]!.allocations[0]!.lineId, allocated.lineId);
      assert.equal(original.original.benefitAttribution!.components[1]!.amountBasis, "maximum");
      for (const line of original.original.lines) {
        assert.equal(line.variant, source.lines.find(l => l.skuId === line.skuId)!.variant);
        assert.deepEqual(line.scheduledFulfilment, source.lines.find(l => l.skuId === line.skuId)!.scheduledFulfilment);
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
    assert.equal(operational.originalFactsVersion, includeScheduled ? 5 : includeVariants ? 4 : 3); assert.deepEqual(operational.original, order.original);
    const result = await ops.command(first.ownerUserId, {...tuple, version: 2, operationId: "STORE-ORDER-attribution_nonce==",
      expectedRevision: 1, action: "accept", reason: null});
    assert.deepEqual(result.snapshot.original, order.original);
    assert.deepEqual((await ops.command(first.ownerUserId, {...tuple, version: 2, operationId: "STORE-ORDER-attribution_nonce==",
      expectedRevision: 1, action: "accept", reason: null}, true)).snapshot.original, order.original);
    const legacyInput: TrustedPlacementReceipt = {...input, schemaVersion: 1, receiptId: `legacy-${suffix}`,
      stores: input.stores.map(({benefitAttribution: _attribution, ...store}) => ({...store,
        lines: store.lines.map(({variant: _variant, scheduledFulfilment: _scheduled, ...line}) => line)}))};
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
    if (includeScheduled) {
      const none = structuredClone(input); none.receiptId = `all-null-${suffix}`;
      for (const store of none.stores) for (const line of store.lines) line.scheduledFulfilment = null;
      const allNullWriter = new WorkspacePurchaseProjectionService(db, "evaluation", {readFinalPlacement: async () => none});
      const allNullCreated = await allNullWriter.materialize("all-null-requested-context");
      const allNullOriginals = await restarted.readBuyer(input.buyerUserId, {purchaseId: allNullCreated.purchaseId});
      assert.equal(allNullOriginals.schemaVersion, 5);
      assert.equal(allNullOriginals.orders.every(o => o.factsVersion === 5 && o.original.lines.every(l => l.scheduledFulfilment === null)), true);
      const selected = input.stores[0]!.lines[0]!.scheduledFulfilment!;
      const original = selected.slotId; selected.slotId = "changed-slot";
      await assert.rejects(writer.materialize("original-benefit-source"), rejectsCode("conflict"));
      assert.deepEqual(await restarted.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId}), buyer);
      selected.slotId = original;
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
