import assert from "node:assert/strict";
import test from "node:test";
import {randomUUID} from "node:crypto";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

import { WorkspaceProfileError } from "./workspace_profile_service.js";
import {
  InMemoryRetailerOrderRepository,
  FirestoreRetailerOrderRepository,
  RetailerOrderService,
  originalRetailerOrderFingerprint,
  type FinalRetailerPurchaseSource,
  type RetailerOrderRecord,
} from "./retailer_order_service.js";

const now = () => new Date("2026-08-29T11:00:00.000Z");

test("LF identity readback is a real service seam, not contact matching", () => {
  const {service} = subject();
  assert.equal(typeof Reflect.get(service, "readIdentity"), "function");
});

// Isolated server-source fixtures. Never an import or a real purchase producer.
function identitySubject() {
  const {repository} = subject();
  const original = order();
  let proof: Awaited<ReturnType<FinalRetailerPurchaseSource["readFinalStoreOrder"]>> = {
    finalIdentity: true, retailerOwnerUserId: original.retailerOwnerUserId,
    link: {buyerUserId: "buyer-1", buyerId: "customer-1", purchaseId: "purchase-1",
      storeId: original.workspaceId, orderId: original.id, sourceRevision: "final-1",
      originalFingerprint: originalRetailerOrderFingerprint(original)},
  };
  const source: FinalRetailerPurchaseSource = {readFinalStoreOrder: async () => structuredClone(proof)};
  const service = new RetailerOrderService(repository, now, source);
  return {repository, service, original, change: (value: typeof proof) => {proof = value;}, proof: () => structuredClone(proof!)};
}

test("LF exact final binding is idempotent and both authorized readers share original facts", async () => {
  const {repository, service, original} = identitySubject();
  await service.bindFinalPurchase(original.id, "purchase-1");
  const saved = structuredClone(repository.records.get(original.id));
  await service.bindFinalPurchase(original.id, "purchase-1");
  assert.deepEqual(repository.records.get(original.id), saved);
  const seller = await service.readIdentity("owner-1", "seller", {storeId: "workspace-1", orderId: original.id}) as Record<string, unknown>;
  const buyer = await service.readIdentity("buyer-1", "buyer", {storeId: "workspace-1", orderId: original.id, purchaseId: "purchase-1"}) as Record<string, unknown>;
  assert.deepEqual(seller.identity, buyer.identity);
  assert.equal(seller.state, "linked");
  const serialized = JSON.stringify(seller.identity);
  assert.ok(!serialized.includes("buyer-1") && !serialized.includes("owner-1"));
  assert.ok(!serialized.includes("protected") && !serialized.includes("Amit Sharma"));
  assert.deepEqual(repository.records.get(original.id)?.lines, original.lines);
  assert.equal(repository.records.get(original.id)?.stage, original.stage);
});

test("LF buyer and seller authorization reject other accounts, Store and purchase", async () => {
  const {service} = identitySubject();
  await service.bindFinalPurchase("MS-2841", "purchase-1");
  for (const [actor, role, body] of [
    ["buyer-2", "buyer", {storeId: "workspace-1", orderId: "MS-2841", purchaseId: "purchase-1"}],
    ["buyer-1", "buyer", {storeId: "workspace-1", orderId: "MS-2841", purchaseId: "purchase-2"}],
    ["buyer-1", "buyer", {storeId: "workspace-2", orderId: "MS-2841", purchaseId: "purchase-1"}],
    ["owner-2", "seller", {storeId: "workspace-1", orderId: "MS-2841"}],
    ["owner-1", "seller", {storeId: "workspace-2", orderId: "MS-2841"}],
  ] as const) await assert.rejects(service.readIdentity(actor, role, body),
    (e: unknown) => e instanceof WorkspaceProfileError && e.code === "not_found");
});

test("LF legacy orders remain unlinked, never contact-matched to a buyer", async () => {
  const {service, repository} = identitySubject();
  const reply = await service.readIdentity("owner-1", "seller", {storeId: "workspace-1", orderId: "MS-2841"}) as {state: string};
  assert.equal(reply.state, "unlinked");
  await assert.rejects(service.readIdentity("buyer-1", "buyer", {storeId: "workspace-1", orderId: "MS-2841", purchaseId: "purchase-1"}));
  assert.equal(repository.records.get("MS-2841")?.purchaseLink, undefined);
});

test("LF source absence, non-final or wrong Store proof cannot attach", async () => {
  const {service, change, proof, repository} = identitySubject();
  const absent = new RetailerOrderService(repository, now);
  await assert.rejects(absent.bindFinalPurchase("MS-2841", "purchase-1"));
  const valid = proof();
  change(undefined);
  await assert.rejects(service.bindFinalPurchase("MS-2841", "purchase-1"));
  change({...valid, finalIdentity: false} as unknown as typeof valid);
  await assert.rejects(service.bindFinalPurchase("MS-2841", "purchase-1"));
  change({...valid, link: {...valid.link, storeId: "workspace-2"}});
  await assert.rejects(service.bindFinalPurchase("MS-2841", "purchase-1"));
  assert.equal(repository.records.get("MS-2841")?.purchaseLink, undefined);
});

test("LF concurrent conflicting bindings cannot replace the first identity", async () => {
  const a = identitySubject();
  const changed = {...a.proof(), link: {...a.proof().link, buyerUserId: "buyer-2", buyerId: "customer-2"}};
  const b = new RetailerOrderService(a.repository, now, {readFinalStoreOrder: async () => changed});
  const results = await Promise.allSettled([
    a.service.bindFinalPurchase("MS-2841", "purchase-1"), b.bindFinalPurchase("MS-2841", "purchase-1"),
  ]);
  assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
  assert.equal(a.repository.records.get("MS-2841")?.purchaseLink?.buyerUserId, "buyer-1");
});

test("LF changed original money/lines fail binding and read; packing/status do not", async () => {
  const a = identitySubject();
  a.repository.records.get("MS-2841")!.amount++;
  await assert.rejects(a.service.bindFinalPurchase("MS-2841", "purchase-1"));
  const b = identitySubject();
  await b.service.bindFinalPurchase("MS-2841", "purchase-1");
  const current = b.repository.records.get("MS-2841")!;
  current.stage = "packed";
  current.lines[0]!.packed = true;
  await b.service.readIdentity("buyer-1", "buyer", {storeId: "workspace-1", orderId: "MS-2841", purchaseId: "purchase-1"});
  current.lines[0]!.quantity++;
  await assert.rejects(b.service.readIdentity("owner-1", "seller", {storeId: "workspace-1", orderId: "MS-2841"}),
    (e: unknown) => e instanceof WorkspaceProfileError && e.code === "invalid_state");
});

test("LF private identity link never leaks through existing seller list/tracking", async () => {
  const {service} = identitySubject();
  await service.bindFinalPurchase("MS-2841", "purchase-1");
  assert.ok(!JSON.stringify(await service.list("owner-1")).includes("purchaseLink"));
  assert.ok(!JSON.stringify(await service.tracking("owner-1", {orderId: "MS-2841"})).includes("buyer-1"));
});

test("LF existing accept/pack retain linked immutable facts and private authorization", async () => {
  const {service, repository} = identitySubject();
  await service.bindFinalPurchase("MS-2841", "purchase-1");
  const originalLink = structuredClone(repository.records.get("MS-2841")!.purchaseLink);
  await assert.rejects(service.accept("buyer-1", {orderId: "MS-2841"}), {code: "not_found"});
  await service.accept("owner-1", {orderId: "MS-2841"});
  const packed = await service.pack("owner-1", {orderId: "MS-2841"});
  assert.ok(!JSON.stringify(packed).includes("purchaseLink"));
  assert.deepEqual(repository.records.get("MS-2841")!.purchaseLink, originalLink);
  await service.readIdentity("buyer-1", "buyer", {storeId: "workspace-1", orderId: "MS-2841", purchaseId: "purchase-1"});
});

test("LF wrong purchase/order proof, extra client fields and corrupt linked identity reject", async () => {
  const a = identitySubject(), valid = a.proof();
  for (const amended of [{purchaseId: "purchase-other"}, {orderId: "order-other"}]) {
    a.change({...valid, link: {...valid.link, ...amended}});
    await assert.rejects(a.service.bindFinalPurchase("MS-2841", "purchase-1"));
  }
  a.change(valid);
  await a.service.bindFinalPurchase("MS-2841", "purchase-1");
  await assert.rejects(a.service.readIdentity("owner-1", "seller", {storeId: "workspace-1", orderId: "MS-2841", buyerId: "customer-1"}));
  a.repository.records.get("MS-2841")!.purchaseLink!.buyerId = "changed-customer";
  await assert.rejects(a.service.readIdentity("owner-1", "seller", {storeId: "workspace-1", orderId: "MS-2841"}), {code: "invalid_state"});
});

test("LF Firestore emulator: atomic conflict, fresh-client readback and immutable original facts", {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf-order-identity"}, `identity-${randomUUID()}`);
  const restart = initializeApp({projectId: "demo-lf-order-identity"}, `identity-restart-${randomUUID()}`);
  const db = getFirestore(app), restartedDb = getFirestore(restart);
  const original = order({id: `MS-${randomUUID()}`});
  const link = {buyerUserId: "buyer-1", buyerId: "customer-1", purchaseId: "purchase-1",
    storeId: original.workspaceId, orderId: original.id, sourceRevision: "final-1",
    originalFingerprint: originalRetailerOrderFingerprint(original)};
  const source = (buyer: string): FinalRetailerPurchaseSource => ({
    readFinalStoreOrder: async () => ({finalIdentity: true,
      retailerOwnerUserId: "owner-1", link: {...link, buyerUserId: buyer}}),
  });
  try {
    const ref = db.collection("retailerOrders").doc(original.id);
    await ref.set(original);
    const first = new RetailerOrderService(new FirestoreRetailerOrderRepository(db), now, source("buyer-1"));
    const second = new RetailerOrderService(new FirestoreRetailerOrderRepository(db), now, source("buyer-2"));
    const outcomes = await Promise.allSettled([
      first.bindFinalPurchase(original.id, "purchase-1"), second.bindFinalPurchase(original.id, "purchase-1"),
    ]);
    assert.equal(outcomes.filter(r => r.status === "fulfilled").length, 1);
    const saved = (await ref.get()).get("purchaseLink") as {buyerUserId: string};
    const reader = new RetailerOrderService(new FirestoreRetailerOrderRepository(restartedDb), now);
    const body = {storeId: original.workspaceId, orderId: original.id, purchaseId: "purchase-1"};
    const read = await reader.readIdentity(saved.buyerUserId, "buyer", body) as {state: string};
    assert.equal(read.state, "linked");
    await assert.rejects(reader.readIdentity("other-buyer", "buyer", body), {code: "not_found"});
    await ref.update({amount: original.amount + 1});
    await assert.rejects(reader.readIdentity(saved.buyerUserId, "buyer", body), {code: "invalid_state"});
    assert.deepEqual((await ref.get()).get("lines"), original.lines);
  } finally {
    await db.terminate(); await restartedDb.terminate();
    await deleteApp(app); await deleteApp(restart);
  }
});

function order(overrides: Partial<RetailerOrderRecord> = {}): RetailerOrderRecord {
  return {
    schemaVersion: 1,
    id: "MS-2841",
    retailerOwnerUserId: "owner-1",
    workspaceId: "workspace-1",
    customer: "Amit Sharma",
    area: "Sardarpura · 2.1 km",
    payment: "Paid online · ₹1,240 protected",
    fulfilment: "Home delivery",
    deliveryPromise: "Deliver by 8:15 PM",
    amount: 1240,
    stage: "received",
    lines: [{
      id: "atta",
      name: "Aashirvaad Whole Wheat Atta",
      detail: "1 kg",
      quantity: 2,
      amount: 110,
      packed: false,
    }],
    updatedAt: "2026-08-29T10:00:00.000Z",
    ...overrides,
  };
}

function subject(initial = order()) {
  const repository = new InMemoryRetailerOrderRepository();
  repository.records.set(initial.id, structuredClone(initial));
  return { repository, service: new RetailerOrderService(repository, now) };
}

test("lists only the signed-in retailer orders", async () => {
  const { repository, service } = subject();
  repository.records.set("MS-OTHER", order({
    id: "MS-OTHER",
    retailerOwnerUserId: "owner-2",
  }));

  const result = await service.list("owner-1") as { orders: Array<{ id: string }> };
  assert.deepEqual(result.orders.map((item) => item.id), ["MS-2841"]);
  await assert.rejects(
    service.accept("owner-2", { orderId: "MS-2841" }),
    (error: unknown) => error instanceof WorkspaceProfileError && error.code === "not_found",
  );
});

test("accept and pack are state-checked and idempotent", async () => {
  const { repository, service } = subject();

  await service.accept("owner-1", { orderId: "MS-2841" });
  await service.accept("owner-1", { orderId: "MS-2841" });
  await service.pack("owner-1", { orderId: "MS-2841" });
  await service.pack("owner-1", { orderId: "MS-2841" });

  assert.equal(repository.records.get("MS-2841")?.stage, "packed");
  assert.equal(repository.records.get("MS-2841")?.lines[0]?.packed, true);
});

test("delivery request stops at awaiting assignment and reuses its reference", async () => {
  const { repository, service } = subject(order({
    stage: "packed",
    lines: [{
      id: "atta",
      name: "Aashirvaad Whole Wheat Atta",
      detail: "1 kg",
      quantity: 2,
      amount: 110,
      packed: true,
    }],
  }));

  const first = await service.requestDelivery("owner-1", { orderId: "MS-2841" });
  const second = await service.requestDelivery("owner-1", { orderId: "MS-2841" });

  assert.deepEqual(second, first);
  assert.equal(repository.records.get("MS-2841")?.stage, "delivery_requested");
  assert.match(String((first as { deliveryReference: string }).deliveryReference), /^delivery_/u);
});

test("secure handover fails closed until authoritative OTP integration", async () => {
  const { service } = subject(order({ stage: "captain_arrived" }));
  await assert.rejects(
    service.confirmHandover("owner-1", { orderId: "MS-2841" }),
    (error: unknown) =>
      error instanceof WorkspaceProfileError &&
      error.code === "service_unavailable" &&
      error.retryable,
  );
});

test("decline records refund-required outcome and issue creation is idempotent", async () => {
  const { repository, service } = subject();
  await service.decline("owner-1", {
    orderId: "MS-2841",
    reason: "Required product unavailable",
  });
  assert.equal(repository.records.get("MS-2841")?.stage, "cannot_fulfil");

  const issueOrder = order({ id: "MS-2842", stage: "out_for_delivery" });
  repository.records.set(issueOrder.id, issueOrder);
  const first = await service.issue("owner-1", {
    orderId: "MS-2842",
    reason: "Captain delayed",
  });
  const second = await service.issue("owner-1", {
    orderId: "MS-2842",
    reason: "Captain delayed",
  });
  assert.deepEqual(second, first);
});
