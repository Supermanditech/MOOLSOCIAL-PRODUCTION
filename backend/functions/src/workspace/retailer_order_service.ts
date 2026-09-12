import { createHash } from "node:crypto";

import type { DocumentData, Firestore } from "firebase-admin/firestore";

import { WorkspaceProfileError } from "./workspace_profile_service.js";

export interface RetailerOrderLineRecord {
  id: string;
  name: string;
  detail: string;
  quantity: number;
  amount: number;
  packed: boolean;
}

export interface RetailerOrderRecord {
  schemaVersion: 1;
  id: string;
  retailerOwnerUserId: string;
  workspaceId: string;
  customer: string;
  area: string;
  payment: string;
  fulfilment: string;
  deliveryPromise: string;
  amount: number;
  stage: string;
  lines: RetailerOrderLineRecord[];
  updatedAt: string;
  deliveryReference?: string;
  captainName?: string;
  captainVehicle?: string;
  handoverReference?: string;
  deliveryProof?: string;
  cannotFulfilReason?: string;
  issueReference?: string;
}

export interface RetailerOrderRepository {
  list(ownerUserId: string): Promise<RetailerOrderRecord[]>;
  read(orderId: string): Promise<RetailerOrderRecord | undefined>;
  update(
    orderId: string,
    ownerUserId: string,
    patch: Readonly<Record<string, unknown>>,
  ): Promise<RetailerOrderRecord>;
}

export class RetailerOrderService {
  constructor(
    private readonly repository: RetailerOrderRepository,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async list(ownerUserId: string): Promise<object> {
    const orders = await this.repository.list(identifier(ownerUserId));
    return { orders: orders.map(publicOrder) };
  }

  async accept(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const order = await this.ownerOrder(ownerUserId, orderId(body));
    if (order.stage === "accepted" || stageAfter(order.stage, "accepted")) return publicOrder(order);
    if (order.stage !== "received") throw invalidState("Only a received order can be accepted.");
    return publicOrder(await this.update(order, { stage: "accepted" }));
  }

  async pack(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const order = await this.ownerOrder(ownerUserId, orderId(body));
    if (order.stage === "packed" || stageAfter(order.stage, "packed")) return publicOrder(order);
    if (order.stage !== "accepted" && order.stage !== "packing") {
      throw invalidState("Accept the order before saving packed status.");
    }
    return publicOrder(await this.update(order, {
      stage: "packed",
      lines: order.lines.map((line) => ({ ...line, packed: true })),
    }));
  }

  async requestDelivery(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const order = await this.ownerOrder(ownerUserId, orderId(body));
    if (order.deliveryReference) {
      return { deliveryReference: order.deliveryReference, stage: order.stage };
    }
    if (order.stage !== "packed") throw invalidState("Pack the order before requesting delivery.");
    const deliveryReference = `delivery_${digest(`${order.id}:${order.workspaceId}`).slice(0, 24)}`;
    await this.update(order, { stage: "delivery_requested", deliveryReference });
    return { deliveryReference, stage: "delivery_requested" };
  }

  async confirmHandover(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    await this.ownerOrder(ownerUserId, orderId(body));
    throw new WorkspaceProfileError(
      "service_unavailable",
      "Secure captain handover verification is unavailable right now. Keep the parcel at the shop.",
      503,
      true,
    );
  }

  async tracking(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    return publicOrder(await this.ownerOrder(ownerUserId, orderId(body)));
  }

  async decline(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const order = await this.ownerOrder(ownerUserId, orderId(body));
    if (order.stage === "cannot_fulfil") return publicOrder(order);
    if (order.stage !== "received" && order.stage !== "accepted") {
      throw invalidState("This order can no longer be declined.");
    }
    const reason = text(body, "reason", 3, 160);
    return publicOrder(await this.update(order, {
      stage: "cannot_fulfil",
      cannotFulfilReason: reason,
      refundStatus: "required",
    }));
  }

  async issue(ownerUserId: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    const order = await this.ownerOrder(ownerUserId, orderId(body));
    const reason = text(body, "reason", 3, 160);
    if (order.issueReference) return { issueReference: order.issueReference };
    const issueReference = `issue_${digest(`${order.id}:${reason}`).slice(0, 24)}`;
    await this.update(order, { issueReference, issueReason: reason });
    return { issueReference };
  }

  private async ownerOrder(ownerUserId: string, id: string): Promise<RetailerOrderRecord> {
    const owner = identifier(ownerUserId);
    const order = await this.repository.read(id);
    if (!order || order.retailerOwnerUserId !== owner) {
      throw new WorkspaceProfileError(
        "not_found",
        "That retailer order is not available for this Workspace.",
        404,
      );
    }
    return order;
  }

  private update(order: RetailerOrderRecord, patch: Readonly<Record<string, unknown>>) {
    return this.repository.update(order.id, order.retailerOwnerUserId, {
      ...patch,
      updatedAt: this.now().toISOString(),
    });
  }
}

export class FirestoreRetailerOrderRepository implements RetailerOrderRepository {
  constructor(private readonly firestore: Firestore) {}
  async list(ownerUserId: string): Promise<RetailerOrderRecord[]> {
    const snapshot = await this.firestore.collection("retailerOrders")
      .where("retailerOwnerUserId", "==", ownerUserId)
      .limit(100)
      .get();
    return snapshot.docs.map((document) => record(document.id, document.data()))
      .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));
  }
  async read(orderId: string): Promise<RetailerOrderRecord | undefined> {
    const snapshot = await this.firestore.collection("retailerOrders").doc(orderId).get();
    return snapshot.exists ? record(snapshot.id, snapshot.data()!) : undefined;
  }
  async update(orderId: string, ownerUserId: string, patch: Readonly<Record<string, unknown>>): Promise<RetailerOrderRecord> {
    const ref = this.firestore.collection("retailerOrders").doc(orderId);
    return this.firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists || snapshot.get("retailerOwnerUserId") !== ownerUserId) {
        throw new WorkspaceProfileError("not_found", "That retailer order is not available for this Workspace.", 404);
      }
      transaction.update(ref, patch);
      return record(snapshot.id, { ...snapshot.data()!, ...patch });
    });
  }
}

export class InMemoryRetailerOrderRepository implements RetailerOrderRepository {
  readonly records = new Map<string, RetailerOrderRecord>();
  async list(ownerUserId: string): Promise<RetailerOrderRecord[]> {
    return [...this.records.values()]
      .filter((item) => item.retailerOwnerUserId === ownerUserId)
      .map((item) => structuredClone(item));
  }
  async read(orderId: string): Promise<RetailerOrderRecord | undefined> {
    const value = this.records.get(orderId);
    return value ? structuredClone(value) : undefined;
  }
  async update(orderId: string, ownerUserId: string, patch: Readonly<Record<string, unknown>>): Promise<RetailerOrderRecord> {
    const current = this.records.get(orderId);
    if (!current || current.retailerOwnerUserId !== ownerUserId) {
      throw new WorkspaceProfileError("not_found", "That retailer order is not available for this Workspace.", 404);
    }
    const updated = { ...current, ...patch } as RetailerOrderRecord;
    this.records.set(orderId, updated);
    return structuredClone(updated);
  }
}

function publicOrder(order: RetailerOrderRecord): object {
  return {
    id: order.id,
    customer: order.customer,
    area: order.area,
    payment: order.payment,
    fulfilment: order.fulfilment,
    deliveryPromise: order.deliveryPromise,
    amount: order.amount,
    stage: order.stage,
    lines: order.lines,
    ...(order.deliveryReference ? { deliveryReference: order.deliveryReference } : {}),
    ...(order.captainName ? { captainName: order.captainName } : {}),
    ...(order.captainVehicle ? { captainVehicle: order.captainVehicle } : {}),
    ...(order.handoverReference ? { handoverReference: order.handoverReference } : {}),
    ...(order.deliveryProof ? { deliveryProof: order.deliveryProof } : {}),
    ...(order.cannotFulfilReason ? { cannotFulfilReason: order.cannotFulfilReason } : {}),
    ...(order.issueReference ? { issueReference: order.issueReference } : {}),
  };
}

function record(id: string, data: DocumentData): RetailerOrderRecord {
  return { ...data, id } as RetailerOrderRecord;
}

function orderId(body: Readonly<Record<string, unknown>>): string {
  return text(body, "orderId", 3, 100);
}
function text(body: Readonly<Record<string, unknown>>, key: string, minimum: number, maximum: number): string {
  const value = body[key];
  if (typeof value !== "string" || value.trim().length < minimum || value.trim().length > maximum) {
    throw new WorkspaceProfileError("invalid_input", `${key} is invalid.`, 400);
  }
  return value.trim();
}
function identifier(value: string): string {
  const normalized = value.trim();
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(normalized)) {
    throw new WorkspaceProfileError("invalid_input", "owner is invalid.", 400);
  }
  return normalized;
}
function digest(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}
function invalidState(message: string): WorkspaceProfileError {
  return new WorkspaceProfileError("invalid_state", message, 409);
}
const stages = [
  "received", "accepted", "packing", "packed", "delivery_requested",
  "captain_assigned", "parcel_ready", "captain_arrived", "handover_verified",
  "handed_over", "out_for_delivery", "nearby", "delivered", "returned",
] as const;
function stageAfter(current: string, target: string): boolean {
  return stages.indexOf(current as typeof stages[number]) > stages.indexOf(target as typeof stages[number]);
}
