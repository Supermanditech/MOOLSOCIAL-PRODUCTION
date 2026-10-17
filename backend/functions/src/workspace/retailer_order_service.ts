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
  /** Server-private authorization link; never accepted from Workspace clients. */
  purchaseLink?: RetailerOrderPurchaseLink;
}

export interface RetailerOrderPurchaseLink {
  schemaVersion: 1;
  buyerUserId: string;
  buyerId: string;
  purchaseId: string;
  storeId: string;
  orderId: string;
  sourceRevision: string;
  originalFingerprint: string;
  serviceRevision: string;
}

/** Original purchase identity is final even if payment/fulfilment later changes.
 * This source must be server-owned, not a client DTO, projection or local ledger.
 * A mutable/revocable proof cannot satisfy this interface. No live source exists
 * in this slice; absence fails closed, without manufacturing a purchase. */
export interface FinalRetailerPurchaseSource {
  readFinalStoreOrder(purchaseId: string, orderId: string): Promise<{
    finalIdentity: true;
    retailerOwnerUserId: string;
    link: Omit<RetailerOrderPurchaseLink, "schemaVersion" | "serviceRevision">;
  } | undefined>;
}

export interface RetailerOrderRepository {
  list(ownerUserId: string): Promise<RetailerOrderRecord[]>;
  read(orderId: string): Promise<RetailerOrderRecord | undefined>;
  update(
    orderId: string,
    ownerUserId: string,
    patch: Readonly<Record<string, unknown>>,
  ): Promise<RetailerOrderRecord>;
  attachPurchaseLink(orderId: string, ownerUserId: string,
    link: RetailerOrderPurchaseLink): Promise<RetailerOrderRecord>;
}

export class RetailerOrderService {
  constructor(
    private readonly repository: RetailerOrderRepository,
    private readonly now: () => Date = () => new Date(),
    private readonly purchaseSource?: FinalRetailerPurchaseSource,
  ) {}

  /** Internal producer seam only. Intentionally NOT routed as an HTTP action. */
  async bindFinalPurchase(orderId: string, purchaseId: string): Promise<void> {
    const id = identifier(orderId), purchase = identifier(purchaseId);
    if (!this.purchaseSource) {
      throw new WorkspaceProfileError("service_unavailable", "Purchase identity is unavailable.", 503, true);
    }
    const proof = await this.purchaseSource.readFinalStoreOrder(purchase, id);
    if (!proof || proof.finalIdentity !== true || proof.link.orderId !== id || proof.link.purchaseId !== purchase) {
      throw invalidState("The original purchase could not be verified.");
    }
    const link: RetailerOrderPurchaseLink = {
      ...proof.link, schemaVersion: 1,
      serviceRevision: digest(JSON.stringify([
        proof.link.buyerUserId, proof.link.buyerId, purchase, proof.link.storeId,
        id, proof.link.sourceRevision, proof.link.originalFingerprint,
      ])),
    };
    validateLink(link);
    await this.repository.attachPurchaseLink(id, identifier(proof.retailerOwnerUserId), link);
  }

  async readIdentity(viewerUserId: string, role: "buyer" | "seller",
    body: Readonly<Record<string, unknown>>): Promise<object> {
    const actor = identifier(viewerUserId);
    if (role !== "buyer" && role !== "seller") throw invalidState("Unsupported identity reader.");
    const fields = role === "buyer" ? ["orderId", "storeId", "purchaseId"] : ["orderId", "storeId"];
    if (Object.keys(body).length !== fields.length || fields.some(k => typeof body[k] !== "string")) {
      throw new WorkspaceProfileError("invalid_input", "Order scope is invalid.", 400);
    }
    const order = await this.repository.read(identifier(body.orderId as string));
    const storeId = identifier(body.storeId as string);
    const purchase = role === "buyer" ? identifier(body.purchaseId as string) : undefined;
    if (!order || order.workspaceId !== storeId ||
        (role === "seller" ? order.retailerOwnerUserId !== actor :
          order.purchaseLink?.buyerUserId !== actor || order.purchaseLink.purchaseId !== purchase)) {
      throw new WorkspaceProfileError("not_found", "That order identity is not available.", 404);
    }
    const base = {schemaVersion: 1, viewerRole: role, viewerUserId: actor, storeId, orderId: order.id};
    if (order.purchaseLink === undefined) return {...base, state: "unlinked"};
    const link = order.purchaseLink;
    validateLink(link);
    if (link.orderId !== order.id || link.storeId !== storeId ||
        link.originalFingerprint !== originalRetailerOrderFingerprint(order)) {
      throw invalidState("The original order identity needs reconciliation.");
    }
    return {...base, state: "linked", identity: {
      buyerId: link.buyerId, purchaseId: link.purchaseId,
      sourceRevision: link.sourceRevision, serviceRevision: link.serviceRevision,
      originalFingerprint: link.originalFingerprint, original: originalRetailerOrderFacts(order),
    }};
  }

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
  async attachPurchaseLink(orderId: string, ownerUserId: string,
    link: RetailerOrderPurchaseLink): Promise<RetailerOrderRecord> {
    const ref = this.firestore.collection("retailerOrders").doc(orderId);
    return this.firestore.runTransaction(async transaction => {
      const snapshot = await transaction.get(ref);
      const current = snapshot.exists ? record(snapshot.id, snapshot.data()!) : undefined;
      requireAttach(current, ownerUserId, link);
      if (current!.purchaseLink === undefined) transaction.update(ref, {purchaseLink: link});
      return {...current!, purchaseLink: current!.purchaseLink ?? link};
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
  async attachPurchaseLink(orderId: string, ownerUserId: string,
    link: RetailerOrderPurchaseLink): Promise<RetailerOrderRecord> {
    // No await between compare and set, matching the transaction's atomic unit.
    const current = this.records.get(orderId);
    requireAttach(current, ownerUserId, link);
    const updated = {...current!, purchaseLink: current!.purchaseLink ?? structuredClone(link)};
    this.records.set(orderId, updated);
    return structuredClone(updated);
  }
}

function validateLink(link: RetailerOrderPurchaseLink): void {
  if (!link || typeof link !== "object" || link.schemaVersion !== 1 ||
      ![link.buyerUserId, link.buyerId, link.purchaseId, link.storeId, link.orderId,
        link.sourceRevision].every(v => typeof v === "string" && identifier(v) === v) ||
      !/^[a-f0-9]{64}$/u.test(link.originalFingerprint) ||
      !/^[a-f0-9]{64}$/u.test(link.serviceRevision) ||
      link.serviceRevision !== digest(JSON.stringify([
        link.buyerUserId, link.buyerId, link.purchaseId, link.storeId,
        link.orderId, link.sourceRevision, link.originalFingerprint,
      ]))) throw invalidState("Invalid purchase identity.");
}

/** Existing legacy money is explicitly whole INR; no inferred tax/fee sums. */
export function originalRetailerOrderFacts(order: RetailerOrderRecord) {
  const minor = (v: number) => {
    if (!Number.isSafeInteger(v) || v < 0 || !Number.isSafeInteger(v * 100)) {
      throw invalidState("Original order money is invalid.");
    }
    return v * 100;
  };
  if (!Array.isArray(order.lines) || !order.lines.length || order.lines.length > 500 ||
      new Set(order.lines.map(l => l.id)).size !== order.lines.length) throw invalidState("Original order lines are invalid.");
  const lines = order.lines.map(l => {
    identifier(l.id);
    if (!Number.isSafeInteger(l.quantity) || l.quantity <= 0 ||
        typeof l.name !== "string" || typeof l.detail !== "string" ||
        !l.name.trim() || l.name.length > 500 || l.detail.length > 2000) throw invalidState("Original order line is invalid.");
    return {lineId: l.id, name: l.name, detail: l.detail,
      quantity: l.quantity, amountMinor: minor(l.amount)};
  }).sort((a, b) => a.lineId < b.lineId ? -1 : a.lineId > b.lineId ? 1 : 0);
  return {currency: "INR", amountMinor: minor(order.amount), lines};
}

export function originalRetailerOrderFingerprint(order: RetailerOrderRecord): string {
  return digest(JSON.stringify({storeId: order.workspaceId, orderId: order.id,
    original: originalRetailerOrderFacts(order)}));
}

function requireAttach(current: RetailerOrderRecord | undefined, owner: string,
  link: RetailerOrderPurchaseLink): void {
  validateLink(link);
  if (!current || current.retailerOwnerUserId !== owner || current.id !== link.orderId ||
      current.workspaceId !== link.storeId) throw invalidState("Purchase Store/order does not match.");
  if (originalRetailerOrderFingerprint(current) !== link.originalFingerprint) throw invalidState("Original purchase facts differ.");
  if (current.purchaseLink !== undefined) {
    validateLink(current.purchaseLink);
    for (const key of Object.keys(link) as Array<keyof RetailerOrderPurchaseLink>) {
      if (current.purchaseLink[key] !== link[key]) throw invalidState("Purchase identity is already bound.");
    }
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
