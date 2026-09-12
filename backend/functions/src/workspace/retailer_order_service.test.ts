import assert from "node:assert/strict";
import test from "node:test";

import { WorkspaceProfileError } from "./workspace_profile_service.js";
import {
  InMemoryRetailerOrderRepository,
  RetailerOrderService,
  type RetailerOrderRecord,
} from "./retailer_order_service.js";

const now = () => new Date("2026-08-29T11:00:00.000Z");

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
