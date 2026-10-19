import {createHash, randomUUID} from "node:crypto";
import {FieldPath, type Firestore, type Transaction} from "firebase-admin/firestore";
import {WorkspaceProfileError} from "./workspace_profile_service.js";

type Realm = "evaluation" | "production";
export type PurchaseFactsVersion = 2 | 3 | 4 | 5 | 6;
export interface PlacementLine {
  sourceLineId: string; skuId: string; canonicalProductId: string;
  verifiedPackId: string; offerId: string; offerRevision: string;
  name: string; packLabel: string; quantityMilli: number;
  quantityUnit: "pack" | "kg" | "L" | "count";
  unitPriceMinor: number; lineTotalMinor: number;
  /** Absent in legacy originals; explicit empty means no additional variant. */
  variant?: string;
  /** Existing Buy desired-window DTO, not a reservation or quote acknowledgement. */
  scheduledFulfilment?: OriginalScheduledFulfilment | null;
  /** Presence is versioned; null means no verified purchased public context. */
  publicListing?: OriginalPublicListing | null;
}
export interface OriginalScheduledFulfilment {
  schemaVersion: 1; method: "scheduled";
  listing: {schemaVersion: 1; realm: Realm; listingId: string; storeId: string; skuId: string;
    canonicalProductId: string; verifiedPackId: string; channel: "retail" | "wholesale" | "bulk"};
  sourceRevision: string; locationKey: string; slotId: string; startsAt: string; endsAt: string;
}
export type OriginalPublicListing = OriginalScheduledFulfilment["listing"];
export interface PurchaseTotals {
  itemsMinor: number; discountMinor: number; taxMinor: number; deliveryMinor: number;
  freightMinor: number; paymentFeeMinor: number; tipMinor: number; totalMinor: number;
}
interface PlacementStore {
  storeId: string; caseId: string; ownerUserId: string;
  lines: PlacementLine[]; totals: PurchaseTotals;
  benefitAttribution?: OriginalBenefitAttribution;
}
/** Immutable source facts only, not eligibility, redemption or cashback payment.
 * On a placement receipt, allocation lineId references sourceLineId. The atomic
 * materializer replaces it with the saved original lineId before persistence.
 * Internal source/funder references are integrity data, not display labels. */
export interface OriginalBenefitComponent {
  componentId: string; benefitId: string; benefitRevision: string; label: string;
  publisherType: "supplier" | "platform" | "payment";
  effect: "instant_discount" | "cashback_offer";
  amountBasis: "applied" | "quoted" | "maximum";
  sourceReference: string; funderReference: string; amountMinor: number;
  allocations: {lineId: string; amountMinor: number}[];
}
export interface OriginalBenefitAttribution {schemaVersion: 1; components: OriginalBenefitComponent[]}
/** Server-owned FINAL PLACEMENT, not a quote, client command, payment or stock proof.
 * No real upstream implementation is configured in this local slice. */
export interface TrustedPlacementReceipt {
  schemaVersion: 1 | 2 | 3 | 4 | 5; realm: Realm; authNamespace: "firebase-default";
  finalPlacement: true; issuer: string; receiptId: string; revision: string;
  buyerUserId: string; stores: PlacementStore[];
}
export interface FinalPlacementSource {
  readFinalPlacement(reference: string): Promise<TrustedPlacementReceipt | undefined>;
}
export interface PurchasedLine extends Omit<PlacementLine, "sourceLineId"> {lineId: string}
export interface PurchaseOriginal {
  currency: "INR"; lines: PurchasedLine[]; totals: PurchaseTotals;
  benefitAttribution?: OriginalBenefitAttribution;
}
export interface PurchaseStoreProjection {
  factsVersion: PurchaseFactsVersion; storeId: string; orderId: string; original: PurchaseOriginal;
  originalFingerprint: string;
}
interface StoredOrder extends PurchaseStoreProjection {caseId: string; ownerUserId: string}
interface PurchaseAggregate {
  schemaVersion: PurchaseFactsVersion; realm: Realm; authNamespace: "firebase-default";
  purchaseId: string; buyerUserId: string; buyerId: string; sourceRevision: string;
  sourceFingerprint: string; createdAt: string; orders: StoredOrder[]; integrity: string;
}
export interface PurchaseProjection {
  schemaVersion: PurchaseFactsVersion; realm: Realm; authNamespace: "firebase-default";
  viewerRole: "buyer" | "seller"; viewerUserId: string;
  purchaseId: string; buyerId: string; sourceRevision: string;
  // Not a mutable payment/fulfilment/eligibility status.
  state: "original_facts"; orders: PurchaseStoreProjection[];
}
export interface PurchaseReference {
  purchaseId: string; storeId: string; orderId: string;
  originalFingerprint: string; sourceRevision: string;
}
export interface PurchaseReferencePage {
  schemaVersion: 2; realm: Realm; authNamespace: "firebase-default";
  viewerRole: "buyer" | "seller"; viewerUserId: string; storeId: string | null;
  coverage: "saved_original_facts" | "indexed_original_facts";
  references: PurchaseReference[]; nextCursor: string | null;
}
const totalKeys = ["itemsMinor", "discountMinor", "taxMinor", "deliveryMinor",
  "freightMinor", "paymentFeeMinor", "tipMinor", "totalMinor"] as const;
const lineKeys = ["sourceLineId", "skuId", "canonicalProductId", "verifiedPackId",
  "offerId", "offerRevision", "name", "packLabel", "quantityMilli", "quantityUnit",
  "unitPriceMinor", "lineTotalMinor"];
const digest = (v: unknown) => createHash("sha256").update(JSON.stringify(v)).digest("hex");
function fail(code = "invalid_input", status = 400): never {
  throw new WorkspaceProfileError(code, "Purchase information is unavailable or needs reconciliation.", status);
}
function stable(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(stable);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).sort(([a],[b]) => compare(a,b)).map(([k,v]) => [k,stable(v)]));
  }
  return value;
}
const integrityHash = (value: unknown) => digest(stable(value));

export type OperationalOrderAction = "accept" | "ready" | "reject";
export type OperationalOrderStage = "Confirmed" | "Preparing" | "Ready" | "Rejected";
export interface TrustedOperationalOrderEvidence {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default";
  issuer: string; receiptId: string; revision: string;
  purchaseId: string; storeId: string; orderId: string;
  originalFingerprint: string; sourceRevision: string;
  customerLabel: string; fulfilment: "delivery" | "collection"; address: string;
  placedAt: string; acceptanceDeadline: string | null; fulfilmentDeadline: string | null;
  initialStage: OperationalOrderStage; allowedActions: OperationalOrderAction[];
}
export interface OperationalOrderSource {
  readOperationalOrder(reference: string): Promise<TrustedOperationalOrderEvidence | undefined>;
}
/** Server integration boundary, never buyer/Store submitted completion claims. */
export interface TrustedOrderCompletionEvidence {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default";
  issuer: string; receiptId: string; revision: string;
  purchaseId: string; storeId: string; orderId: string;
  originalFingerprint: string; sourceRevision: string;
  operationalSourceRevision: string; operationalRevision: number;
  outcome: "delivered" | "collected"; occurredAt: string;
}
export interface OrderCompletionSource {
  readonly issuer: string;
  readCompletion(reference: string): Promise<TrustedOrderCompletionEvidence | undefined>;
}
interface StoredOrderCompletion {
  schemaVersion: 1; proof: TrustedOrderCompletionEvidence;
  operationalProofFingerprint: string; referenceDigest: string; recordedAt: string; integrity: string;
}
export interface OrderCompletionAcknowledgment extends OperationalScope {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default";
  originalFingerprint: string; sourceRevision: string;
  state: "recorded";
  completion: {id: string; revision: string; outcome: "delivered" | "collected"; occurredAt: string; recordedAt: string};
}
export function normalizeOrderCompletion(value: unknown, realm: Realm, now: Date): TrustedOrderCompletionEvidence {
  const r = exact(value, ["schemaVersion", "realm", "authNamespace", "issuer", "receiptId", "revision",
    "purchaseId", "storeId", "orderId", "originalFingerprint", "sourceRevision", "operationalSourceRevision",
    "operationalRevision", "outcome", "occurredAt"]);
  if (r.schemaVersion !== 1 || r.realm !== realm || !["evaluation", "production"].includes(realm) ||
      r.authNamespace !== "firebase-default" || !["delivered", "collected"].includes(String(r.outcome)) ||
      typeof r.outcome !== "string" || typeof r.originalFingerprint !== "string" ||
      !/^[a-f0-9]{64}$/u.test(r.originalFingerprint)) fail();
  const occurredAt = timestamp(r.occurredAt);
  if (occurredAt > now.toISOString()) fail();
  return {schemaVersion: 1, realm, authNamespace: "firebase-default", issuer: id(r.issuer),
    receiptId: id(r.receiptId), revision: id(r.revision), purchaseId: id(r.purchaseId), storeId: id(r.storeId),
    orderId: id(r.orderId), originalFingerprint: String(r.originalFingerprint), sourceRevision: id(r.sourceRevision),
    operationalSourceRevision: id(r.operationalSourceRevision), operationalRevision: integer(r.operationalRevision, Number.MAX_SAFE_INTEGER, 1),
    outcome: r.outcome as "delivered" | "collected", occurredAt};
}
const operationProofKeys = ["schemaVersion", "realm", "authNamespace", "issuer", "receiptId", "revision",
  "purchaseId", "storeId", "orderId", "originalFingerprint", "sourceRevision", "customerLabel",
  "fulfilment", "address", "placedAt", "acceptanceDeadline", "fulfilmentDeadline", "initialStage", "allowedActions"];
const operationStages = ["Confirmed", "Preparing", "Ready", "Rejected"];
const operationActions = ["accept", "ready", "reject"];
function timestamp(v: unknown): string {
  if (typeof v !== "string" || v.length !== 24) fail();
  const date = new Date(v);
  if (!Number.isFinite(date.getTime()) || date.toISOString() !== v) fail();
  return v;
}
/** Source proof only. No client bootstrap route and no inferred initial state. */
export function normalizeOperationalOrder(value: unknown, realm: Realm, now: Date): TrustedOperationalOrderEvidence {
  const r = exact(value, operationProofKeys);
  if (r.schemaVersion !== 1 || r.realm !== realm || r.authNamespace !== "firebase-default" ||
      !["evaluation", "production"].includes(realm) || typeof r.initialStage !== "string" ||
      !operationStages.includes(r.initialStage) || typeof r.fulfilment !== "string" ||
      !["delivery", "collection"].includes(r.fulfilment) ||
      !/^[a-f0-9]{64}$/u.test(String(r.originalFingerprint)) ||
      !Array.isArray(r.allowedActions) || r.allowedActions.length > 3 ||
      r.allowedActions.some(a => typeof a !== "string" || !operationActions.includes(a)) ||
      new Set(r.allowedActions).size !== r.allowedActions.length) fail();
  const placedAt = timestamp(r.placedAt);
  const acceptanceDeadline = r.acceptanceDeadline === null ? null : timestamp(r.acceptanceDeadline);
  const fulfilmentDeadline = r.fulfilmentDeadline === null ? null : timestamp(r.fulfilmentDeadline);
  if (placedAt > now.toISOString() ||
      (acceptanceDeadline !== null && acceptanceDeadline <= placedAt) ||
      (fulfilmentDeadline !== null && fulfilmentDeadline <= placedAt) ||
      (acceptanceDeadline !== null && fulfilmentDeadline !== null && acceptanceDeadline > fulfilmentDeadline) ||
      (r.fulfilment === "collection" && r.allowedActions.length !== 0)) fail();
  return {schemaVersion: 1, realm, authNamespace: "firebase-default", issuer: id(r.issuer),
    receiptId: id(r.receiptId), revision: id(r.revision), purchaseId: id(r.purchaseId),
    storeId: id(r.storeId), orderId: id(r.orderId), originalFingerprint: String(r.originalFingerprint),
    sourceRevision: id(r.sourceRevision), customerLabel: text(r.customerLabel, 200),
    fulfilment: r.fulfilment as "delivery" | "collection", address: text(r.address, 2000), placedAt,
    acceptanceDeadline, fulfilmentDeadline, initialStage: r.initialStage as OperationalOrderStage,
    allowedActions: [...r.allowedActions] as OperationalOrderAction[]};
}

interface StoredOperationalOrder {
  schemaVersion: 1; proof: TrustedOperationalOrderEvidence; proofFingerprint: string;
  revision: number; stage: OperationalOrderStage; integrity: string;
  rejectionReason?: string | null;
}
export interface OperationalOrderSnapshot {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default";
  viewerRole: "buyer" | "seller"; viewerUserId: string;
  purchaseId: string; storeId: string; orderId: string;
  sourceRevision: string; originalFingerprint: string; original: PurchaseOriginal;
  originalFactsVersion?: 3 | 4 | 5 | 6;
  operationalSourceRevision: string; revision: number; stage: OperationalOrderStage;
  fulfilment: "delivery" | "collection"; placedAt: string;
  acceptanceDeadline: string | null; fulfilmentDeadline: string | null;
  permittedActions: OperationalOrderAction[];
  paymentVerification: "not_supplied"; stockVerification: "not_supplied";
  rejectionReason: string | null;
  customerLabel?: string; address?: string;
}
export interface OperationalCommandResult {
  schemaVersion: 1; operationId: string; state: "applied" | "rejected" | "pending";
  snapshot: OperationalOrderSnapshot;
}
interface OperationalScope {purchaseId: string; storeId: string; orderId: string}
function operationalScope(raw: Readonly<Record<string, unknown>>): OperationalScope {
  return {purchaseId: id(raw.purchaseId), storeId: id(raw.storeId), orderId: id(raw.orderId)};
}

/** Local implementation of the operational authority, separate from originals.
 * Only trusted server evidence can initialize. No payment, Stock, assignment,
 * handover, refund, delivered-state or time-extension implementation is implied. */
export class WorkspaceOrderOperationsService {
  constructor(private readonly db: Firestore, private readonly realm: Realm,
    private readonly source?: OperationalOrderSource, private readonly now: () => Date = () => new Date(),
    private readonly completionSource?: OrderCompletionSource) {
    if (!["evaluation", "production"].includes(realm)) fail("service_unavailable", 503);
  }
  private root() {return this.db.collection("workspacePurchaseProjections").doc(this.realm);}
  private path(scope: OperationalScope) {return this.root().collection("operationalOrders").doc(scope.orderId);}
  private completionPath(scope: OperationalScope) {return this.root().collection("orderCompletions").doc(scope.orderId);}
  private completionStored(value: unknown): StoredOrderCompletion {
    try {
      const r = exact(value, ["schemaVersion", "proof", "operationalProofFingerprint", "referenceDigest", "recordedAt", "integrity"]);
      const {integrity, ...body} = r;
      const proof = normalizeOrderCompletion(r.proof, this.realm, this.now());
      if (r.schemaVersion !== 1 || integrity !== integrityHash(body) ||
          typeof r.referenceDigest !== "string" || typeof r.operationalProofFingerprint !== "string" ||
          !/^[a-f0-9]{64}$/u.test(r.referenceDigest) ||
          !/^[a-f0-9]{64}$/u.test(r.operationalProofFingerprint) ||
          timestamp(r.recordedAt) < proof.occurredAt || timestamp(r.recordedAt) > this.now().toISOString()) fail();
      return {schemaVersion: 1, proof, operationalProofFingerprint: r.operationalProofFingerprint,
        referenceDigest: r.referenceDigest, recordedAt: String(r.recordedAt), integrity: String(integrity)};
    } catch {return fail("invalid_state", 409);}
  }
  private completionBound(saved: StoredOrderCompletion, a: PurchaseAggregate, o: StoredOrder,
    operational?: StoredOperationalOrder): void {
    const p = saved.proof;
    if (p.purchaseId !== a.purchaseId || p.storeId !== o.storeId || p.orderId !== o.orderId ||
        p.originalFingerprint !== o.originalFingerprint || p.sourceRevision !== a.sourceRevision ||
        (operational !== undefined && (saved.operationalProofFingerprint !== operational.proofFingerprint ||
          p.operationalSourceRevision !== operational.proof.revision || p.operationalRevision !== operational.revision ||
          operational.stage !== "Ready" || p.occurredAt < operational.proof.placedAt ||
          p.outcome !== (operational.proof.fulfilment === "collection" ? "collected" : "delivered")))) {
      fail("invalid_state", 409);
    }
  }
  private completionAck(saved: StoredOrderCompletion): OrderCompletionAcknowledgment {
    const p = saved.proof;
    return {schemaVersion: 1, realm: this.realm, authNamespace: "firebase-default",
      purchaseId: p.purchaseId, storeId: p.storeId, orderId: p.orderId,
      originalFingerprint: p.originalFingerprint, sourceRevision: p.sourceRevision, state: "recorded",
      completion: {id: `completion-${digest([p.issuer, p.receiptId])}`, revision: p.revision,
        outcome: p.outcome, occurredAt: p.occurredAt, recordedAt: saved.recordedAt}};
  }
  /** Internal trusted-source materializer only. There is deliberately no HTTP write operation. */
  async recordCompletion(reference: string): Promise<OrderCompletionAcknowledgment> {
    id(reference);
    const source = this.completionSource;
    if (!source) fail("service_unavailable", 503);
    const issuer = id(source.issuer), referenceDigest = digest([issuer, reference]);
    const commandPath = this.root().collection("completionReceipts").doc(`reference-${referenceDigest}`);
    const replay = async (tx: Transaction): Promise<OrderCompletionAcknowledgment | undefined> => {
      const doc = await tx.get(commandPath);
      if (!doc.exists) return undefined;
      const saved = this.completionStored(doc.data());
      if (saved.referenceDigest !== referenceDigest || saved.proof.issuer !== issuer) fail("invalid_state", 409);
      const {aggregate, order} = await this.original(tx, saved.proof);
      this.completionBound(saved, aggregate, order);
      return this.completionAck(saved);
    };
    // Reconciliation of the original reference does not call a missing/changed
    // external source or reassess later readiness as permission to complete again.
    const earlier = await this.db.runTransaction(replay);
    if (earlier) return earlier;
    const raw = await source.readCompletion(reference);
    if (!raw) fail("not_found", 404);
    const proof = normalizeOrderCompletion(raw, this.realm, this.now());
    if (proof.issuer !== issuer) fail("forbidden", 403);
    return this.db.runTransaction(async tx => {
      const accepted = await replay(tx);
      if (accepted) return accepted;
      const {aggregate, order} = await this.original(tx, proof);
      const operational = this.stored((await tx.get(this.path(proof))).data(), aggregate, order);
      const recordedAt = this.now().toISOString();
      const body = {schemaVersion: 1 as const, proof, operationalProofFingerprint: operational.proofFingerprint,
        referenceDigest, recordedAt};
      const saved = {...body, integrity: integrityHash(body)};
      this.completionStored(saved);
      this.completionBound(saved, aggregate, order, operational);
      const receiptPath = this.root().collection("completionReceipts").doc(`source-${digest([issuer, proof.receiptId])}`);
      const existingOrder = await tx.get(this.completionPath(proof)), existingReceipt = await tx.get(receiptPath);
      if (existingOrder.exists || existingReceipt.exists) fail("conflict", 409);
      tx.create(this.completionPath(proof), saved); tx.create(commandPath, saved); tx.create(receiptPath, saved);
      return this.completionAck(saved);
    });
  }
  async readCompletion(actor: string, role: "buyer" | "seller", body: Readonly<Record<string, unknown>>): Promise<object> {
    id(actor); exact(body, ["purchaseId", "storeId", "orderId"]);
    if (role !== "buyer" && role !== "seller") fail();
    const scope = operationalScope(body);
    return this.db.runTransaction(async tx => {
      const {aggregate, order} = await this.original(tx, scope);
      if (role === "seller") await this.seller(tx, order, actor);
      else if (aggregate.buyerUserId !== actor) fail("not_found", 404);
      const operational = this.stored((await tx.get(this.path(scope))).data(), aggregate, order);
      const doc = await tx.get(this.completionPath(scope));
      let acknowledgment: OrderCompletionAcknowledgment | undefined;
      if (doc.exists) {
        const saved = this.completionStored(doc.data()); this.completionBound(saved, aggregate, order, operational);
        acknowledgment = this.completionAck(saved);
      }
      return {schemaVersion: 1, realm: this.realm, authNamespace: "firebase-default", viewerRole: role,
        viewerUserId: actor, ...scope, sourceRevision: aggregate.sourceRevision, originalFingerprint: order.originalFingerprint,
        state: acknowledgment ? "recorded" : "not_supplied", completion: acknowledgment?.completion ?? null};
    });
  }
  private async original(tx: Transaction, scope: OperationalScope) {
    const doc = await tx.get(this.root().collection("purchases").doc(scope.purchaseId));
    if (!doc.exists) fail("not_found", 404);
    const aggregate = validateAggregate(doc.data(), scope.purchaseId, this.realm);
    const order = aggregate.orders.find(o => o.storeId === scope.storeId && o.orderId === scope.orderId);
    if (!order) fail("not_found", 404);
    return {aggregate, order};
  }
  private async seller(tx: Transaction, order: StoredOrder, actor: string) {
    if (order.ownerUserId !== actor) fail("not_found", 404);
    const profile = (await tx.get(this.db.collection("workspaceProfiles").doc(order.caseId))).data();
    // An existing order remains manageable while new Store sales are paused.
    if (!profile || profile.schemaVersion !== 1 || profile.caseId !== order.caseId ||
        profile.workspaceId !== order.storeId || profile.ownerUserId !== actor ||
        profile.familyId !== "products-trade" || profile.status !== "live" ||
        !["retailer-grocery", "retailer-speciality", "wholesaler", "manufacturer"].includes(String(profile.profileId))) {
      fail("not_found", 404);
    }
  }
  private stored(value: unknown, a: PurchaseAggregate, o: StoredOrder): StoredOperationalOrder {
    if (value === undefined) fail("service_unavailable", 503);
    try {
      const r = obj(value);
      exact(r, ["schemaVersion", "proof", "proofFingerprint", "revision", "stage", "integrity",
        ...(Object.hasOwn(r, "rejectionReason") ? ["rejectionReason"] : [])]);
      const proof = normalizeOperationalOrder(r.proof, this.realm, this.now());
      if (r.schemaVersion !== 1 || typeof r.stage !== "string" || !operationStages.includes(r.stage) ||
          proof.purchaseId !== a.purchaseId || proof.storeId !== o.storeId || proof.orderId !== o.orderId ||
          proof.sourceRevision !== a.sourceRevision || proof.originalFingerprint !== o.originalFingerprint ||
          r.proofFingerprint !== integrityHash(proof)) fail();
      const {integrity, ...body} = r;
      if (integrity !== integrityHash(body)) fail();
      const rejectionReason = r.rejectionReason === undefined || r.rejectionReason === null ? null : text(r.rejectionReason, 160);
      if (rejectionReason !== null && (r.stage !== "Rejected" || rejectionReason.length < 3)) fail();
      return {schemaVersion: 1, proof, proofFingerprint: String(r.proofFingerprint),
        revision: integer(r.revision, Number.MAX_SAFE_INTEGER, 1), stage: r.stage as OperationalOrderStage,
        integrity: String(integrity), ...(Object.hasOwn(r, "rejectionReason") ? {rejectionReason} : {})};
    } catch {return fail("invalid_state", 409);}
  }
  private permitted(record: StoredOperationalOrder): OperationalOrderAction[] {
    if (record.proof.fulfilment === "collection") return [];
    const time = this.now().toISOString();
    // Null means timing evidence is unavailable, not an unlimited acceptance grant.
    const expired = record.proof.acceptanceDeadline === null || time >= record.proof.acceptanceDeadline;
    return record.proof.allowedActions.filter(action =>
      action === "ready" ? record.stage === "Preparing" : record.stage === "Confirmed" && !expired);
  }
  private snapshot(a: PurchaseAggregate, o: StoredOrder, record: StoredOperationalOrder,
    actor: string, role: "buyer" | "seller"): OperationalOrderSnapshot {
    const p = record.proof;
    return {schemaVersion: 1, realm: this.realm, authNamespace: "firebase-default",
      viewerRole: role, viewerUserId: actor, purchaseId: a.purchaseId, storeId: o.storeId, orderId: o.orderId,
      sourceRevision: a.sourceRevision, originalFingerprint: o.originalFingerprint, original: o.original,
      ...(o.factsVersion !== 2 ? {originalFactsVersion: o.factsVersion} : {}),
      operationalSourceRevision: p.revision, revision: record.revision, stage: record.stage,
      fulfilment: p.fulfilment, placedAt: p.placedAt, acceptanceDeadline: p.acceptanceDeadline,
      fulfilmentDeadline: p.fulfilmentDeadline, permittedActions: role === "seller" ? this.permitted(record) : [],
      paymentVerification: "not_supplied", stockVerification: "not_supplied",
      rejectionReason: record.rejectionReason ?? null,
      ...(role === "seller" ? {customerLabel: p.customerLabel, address: p.address} : {})};
  }

  /** Server-internal bootstrap only. Reads never create operational records. */
  async initialize(reference: string): Promise<OperationalScope> {
    id(reference);
    if (!this.source) fail("service_unavailable", 503);
    const raw = await this.source.readOperationalOrder(reference);
    if (!raw) fail("not_found", 404);
    const proof = normalizeOperationalOrder(raw, this.realm, this.now());
    const scope = operationalScope(proof as unknown as Record<string, unknown>);
    return this.db.runTransaction(async tx => {
      const {aggregate, order} = await this.original(tx, scope);
      await this.seller(tx, order, order.ownerUserId);
      if (proof.sourceRevision !== aggregate.sourceRevision || proof.originalFingerprint !== order.originalFingerprint) {
        fail("conflict", 409);
      }
      const existing = await tx.get(this.path(scope));
      if (existing.exists) {
        const saved = this.stored(existing.data(), aggregate, order);
        if (saved.proofFingerprint !== integrityHash(proof)) fail("conflict", 409);
      } else {
        const body = {schemaVersion: 1, proof, proofFingerprint: integrityHash(proof),
          revision: 1, stage: proof.initialStage, rejectionReason: null};
        tx.create(this.path(scope), {...body, integrity: integrityHash(body)});
      }
      return scope;
    });
  }

  async read(actor: string, role: "buyer" | "seller", body: Readonly<Record<string, unknown>>): Promise<OperationalOrderSnapshot> {
    id(actor); exact(body, ["purchaseId", "storeId", "orderId"]);
    if (role !== "buyer" && role !== "seller") fail();
    const scope = operationalScope(body);
    return this.db.runTransaction(async tx => {
      const {aggregate, order} = await this.original(tx, scope);
      if (role === "seller") await this.seller(tx, order, actor);
      else if (aggregate.buyerUserId !== actor) fail("not_found", 404);
      const doc = await tx.get(this.path(scope));
      const record = this.stored(doc.data(), aggregate, order);
      const completion = await tx.get(this.completionPath(scope));
      if (completion.exists) this.completionBound(this.completionStored(completion.data()), aggregate, order, record);
      const snapshot = this.snapshot(aggregate, order, record, actor, role);
      return completion.exists ? {...snapshot, permittedActions: []} : snapshot;
    });
  }

  async command(actor: string, body: Readonly<Record<string, unknown>>, reconcile = false): Promise<OperationalCommandResult> {
    id(actor);
    const raw = exact(body, ["version", "purchaseId", "storeId", "orderId", "operationId", "expectedRevision", "action", "reason"]);
    if (raw.version !== 2 || typeof raw.action !== "string" || !operationActions.includes(raw.action)) fail();
    const scope = operationalScope(raw), operationId = text(raw.operationId, 160);
    if (!/^[A-Za-z0-9][A-Za-z0-9._:=+-]{2,159}$/u.test(operationId)) fail();
    const expectedRevision = integer(raw.expectedRevision, Number.MAX_SAFE_INTEGER, 1);
    const action = raw.action as OperationalOrderAction;
    const reason = raw.reason === null ? null : text(raw.reason, 160);
    const canonical = {version: 2, ...scope, operationId, expectedRevision, action, reason};
    const commandFingerprint = integrityHash({actor, realm: this.realm, ...canonical});
    return this.db.runTransaction(async tx => {
      const {aggregate, order} = await this.original(tx, scope);
      await this.seller(tx, order, actor);
      const doc = await tx.get(this.path(scope));
      const record = this.stored(doc.data(), aggregate, order);
      const completion = await tx.get(this.completionPath(scope));
      if (completion.exists) this.completionBound(this.completionStored(completion.data()), aggregate, order, record);
      const commandPath = this.path(scope).collection("commands").doc(digest([actor, operationId]));
      const receipt = await tx.get(commandPath);
      if (receipt.exists) {
        const saved = obj(receipt.data());
        const {integrity, ...receiptBody} = saved;
        if (integrity !== integrityHash(receiptBody) || saved.actor !== actor ||
            !["applied", "rejected"].includes(String(obj(saved.result).state))) fail("invalid_state", 409);
        if (saved.commandFingerprint !== commandFingerprint) fail("conflict", 409);
        // Project the earlier local receipt shape without rewriting its immutable
        // bytes or replacing its frozen outcome with the current order state.
        const result = exact(saved.result, ["schemaVersion", "operationId", "state", "snapshot"]);
        const frozen = obj(result.snapshot);
        const legacy = Object.hasOwn(frozen, "stockPosting");
        const expected = this.snapshot(aggregate, order, record, actor, "seller");
        const snapshotKeys = Object.keys(expected);
        exact(frozen, legacy ? [...snapshotKeys.filter(k => k !== "stockVerification" && k !== "rejectionReason"), "stockPosting"] : snapshotKeys);
        if (result.schemaVersion !== 1 || result.operationId !== operationId ||
            !["applied", "rejected"].includes(String(result.state)) ||
            (legacy && frozen.stockPosting !== "not_performed")) fail("invalid_state", 409);
        const revision = integer(frozen.revision, record.revision, 1);
        const rejectionReason = legacy ? (result.state === "applied" && action === "reject" ? reason : null) : frozen.rejectionReason;
        const projected: Record<string, unknown> = {...frozen, stockVerification: "not_supplied", rejectionReason};
        delete projected.stockPosting;
        for (const key of snapshotKeys.filter(k => !["revision", "stage", "permittedActions", "rejectionReason"].includes(k))) {
          if (integrityHash(projected[key]) !== integrityHash((expected as unknown as Record<string, unknown>)[key])) fail("invalid_state", 409);
        }
        if (typeof frozen.stage !== "string" || !operationStages.includes(frozen.stage) ||
            !Array.isArray(frozen.permittedActions) || new Set(frozen.permittedActions).size !== frozen.permittedActions.length ||
            frozen.permittedActions.some(a => typeof a !== "string" || !record.proof.allowedActions.includes(a as OperationalOrderAction) ||
              (a === "ready" ? frozen.stage !== "Preparing" : frozen.stage !== "Confirmed")) ||
            (record.proof.fulfilment === "collection" && frozen.permittedActions.length !== 0) ||
            (!legacy && record.proof.acceptanceDeadline === null && frozen.permittedActions.some(a => a !== "ready")) ||
            (rejectionReason !== null && (frozen.stage !== "Rejected" || typeof rejectionReason !== "string" || rejectionReason.length < 3 || rejectionReason.length > 160)) ||
            (result.state === "applied" && (revision !== expectedRevision + 1 ||
              frozen.stage !== ({accept: "Preparing", ready: "Ready", reject: "Rejected"} as const)[action] ||
              (action === "reject" && rejectionReason !== reason)))) fail("invalid_state", 409);
        if (legacy && record.proof.acceptanceDeadline === null) {
          projected.permittedActions = (frozen.permittedActions as string[]).filter(a => a === "ready");
        }
        return {schemaVersion: 1, operationId, state: result.state as "applied" | "rejected",
          snapshot: projected as unknown as OperationalOrderSnapshot};
      }
      if (reconcile) return {schemaVersion: 1, operationId, state: "pending",
        snapshot: this.snapshot(aggregate, order, record, actor, "seller")};
      const permitted = this.permitted(record).includes(action) &&
        (action === "reject" ? reason !== null && reason.length >= 3 : reason === null);
      const applied = !completion.exists && expectedRevision === record.revision && permitted && record.revision < Number.MAX_SAFE_INTEGER;
      const updated = applied ? {...record, revision: record.revision + 1,
        stage: ({accept: "Preparing", ready: "Ready", reject: "Rejected"} as const)[action],
        rejectionReason: action === "reject" ? reason : null} : record;
      const {integrity: _old, ...operationBody} = updated;
      if (applied) tx.set(this.path(scope), {...operationBody, integrity: integrityHash(operationBody)});
      const result: OperationalCommandResult = {schemaVersion: 1, operationId, state: applied ? "applied" : "rejected",
        snapshot: this.snapshot(aggregate, order, updated, actor, "seller")};
      const receiptBody = {actor, commandFingerprint, result};
      tx.create(commandPath, {...receiptBody, integrity: integrityHash(receiptBody)});
      return result;
    });
  }
}
/** UID-only storage is deliberately limited to the project's default tenant. */
export function requireDefaultPurchaseTenant(tenant: unknown): void {
  if (tenant !== undefined) fail("authentication_required", 401);
}
function obj(v: unknown): Record<string, unknown> {
  if (!v || typeof v !== "object" || Array.isArray(v) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(v))) fail();
  return v as Record<string, unknown>;
}
function exact(v: unknown, keys: readonly string[]): Record<string, unknown> {
  const r = obj(v);
  if (Object.keys(r).length !== keys.length || keys.some(k => !Object.hasOwn(r, k))) fail();
  return r;
}
function text(v: unknown, max = 240): string {
  if (typeof v !== "string" || !v.length || v !== v.trim() || v.length > max ||
      /[\u0000-\u001f]/u.test(v)) fail();
  return v;
}
function id(v: unknown): string {
  const r = text(v, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(r)) fail();
  return r;
}
function integer(v: unknown, max = 1_000_000_000_000, min = 0): number {
  if (!Number.isSafeInteger(v) || (v as number) < min || (v as number) > max) fail();
  return v as number;
}
function array(v: unknown, max: number): unknown[] {
  if (!Array.isArray(v) || v.length < 1 || v.length > max) fail();
  return v;
}
function unique(values: string[]): void {if (new Set(values).size !== values.length) fail();}
function benefits(value: unknown, lines: readonly {lineId: string; lineTotalMinor: number}[],
  discountMinor: number): OriginalBenefitAttribution {
  const raw = exact(value, ["schemaVersion", "components"]);
  if (raw.schemaVersion !== 1 || !Array.isArray(raw.components) || raw.components.length > 32) fail();
  const gross = new Map(lines.map(l => [l.lineId, BigInt(l.lineTotalMinor)]));
  const discounts = new Map<string, bigint>();
  let totalDiscount = 0n;
  const components = raw.components.map(value => {
    const c = exact(value, ["componentId", "benefitId", "benefitRevision", "label", "publisherType",
      "effect", "amountBasis", "sourceReference", "funderReference", "amountMinor", "allocations"]);
    if (typeof c.publisherType !== "string" || !["supplier", "platform", "payment"].includes(c.publisherType) ||
        (c.effect !== "instant_discount" && c.effect !== "cashback_offer") ||
        (c.effect === "instant_discount" ? c.amountBasis !== "applied" :
          c.amountBasis !== "quoted" && c.amountBasis !== "maximum")) fail();
    const amountMinor = integer(c.amountMinor);
    const allocations = array(c.allocations, 100).map(value => {
      const a = exact(value, ["lineId", "amountMinor"]);
      const lineId = id(a.lineId), amountMinor = integer(a.amountMinor);
      if (!gross.has(lineId)) fail();
      if (c.effect === "instant_discount") {
        discounts.set(lineId, (discounts.get(lineId) ?? 0n) + BigInt(amountMinor));
      }
      return {lineId, amountMinor};
    });
    unique(allocations.map(a => a.lineId));
    if (allocations.reduce((sum, a) => sum + BigInt(a.amountMinor), 0n) !== BigInt(amountMinor)) fail();
    if (c.effect === "instant_discount") totalDiscount += BigInt(amountMinor);
    return {componentId: id(c.componentId), benefitId: id(c.benefitId), benefitRevision: id(c.benefitRevision),
      label: text(c.label), publisherType: c.publisherType as OriginalBenefitComponent["publisherType"],
      effect: c.effect as OriginalBenefitComponent["effect"], amountBasis: c.amountBasis as OriginalBenefitComponent["amountBasis"],
      sourceReference: id(c.sourceReference), funderReference: id(c.funderReference), amountMinor, allocations};
  });
  unique(components.map(c => c.componentId));
  if (totalDiscount !== BigInt(discountMinor) ||
      [...discounts].some(([lineId, amount]) => amount > gross.get(lineId)!)) fail();
  return {schemaVersion: 1, components};
}
function totals(v: unknown, items: number): PurchaseTotals {
  const raw = exact(v, totalKeys);
  const result = Object.fromEntries(totalKeys.map(k => [k, integer(raw[k])])) as unknown as PurchaseTotals;
  if (result.itemsMinor !== items || result.discountMinor > items || result.totalMinor !==
      items - result.discountMinor + result.taxMinor + result.deliveryMinor + result.freightMinor +
      result.paymentFeeMinor + result.tipMinor) fail();
  return result;
}
/** Preserve Dart's canonical UTC precision: milliseconds plus optional nonzero
 * microseconds. Date's millisecond round-trip alone would reject or lose data. */
function scheduledInstantMicros(value: unknown): bigint {
  if (typeof value !== "string") fail();
  const m = /^(-?\d{4}|[+-]\d{6})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{3})(\d{3})?Z$/u.exec(value);
  if (!m || m[8] === "000") fail();
  const [year, month, day, hour, minute, second, millis] = m.slice(1, 8).map(Number) as [number, number, number, number, number, number, number];
  const canonicalYear = Math.abs(year) <= 9999
    ? `${year < 0 ? "-" : ""}${String(Math.abs(year)).padStart(4, "0")}`
    : `${year < 0 ? "-" : "+"}${String(Math.abs(year)).padStart(6, "0")}`;
  const date = new Date(0);
  date.setUTCFullYear(year, month - 1, day); date.setUTCHours(hour, minute, second, millis);
  if (m[1] !== canonicalYear || !Number.isFinite(date.getTime()) || date.getUTCFullYear() !== year ||
      date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day || date.getUTCHours() !== hour ||
      date.getUTCMinutes() !== minute || date.getUTCSeconds() !== second || date.getUTCMilliseconds() !== millis) fail();
  const micros = BigInt(date.getTime()) * 1000n + BigInt(m[8] ?? 0);
  if (micros < -8640000000000000000n || micros > 8640000000000000000n) fail();
  return micros;
}
function scheduledOriginal(value: unknown, realm: Realm, storeId: string, line: PlacementLine): OriginalScheduledFulfilment | null {
  if (value === null) return null;
  const s = exact(value, ["schemaVersion", "method", "listing", "sourceRevision", "locationKey", "slotId", "startsAt", "endsAt"]);
  const l = exact(s.listing, ["schemaVersion", "realm", "listingId", "storeId", "skuId", "canonicalProductId", "verifiedPackId", "channel"]);
  if (s.schemaVersion !== 1 || s.method !== "scheduled" || l.schemaVersion !== 1 || l.realm !== realm ||
      l.storeId !== storeId || l.skuId !== line.skuId || l.canonicalProductId !== line.canonicalProductId ||
      l.verifiedPackId !== line.verifiedPackId || typeof l.listingId !== "string" || !/^listing-[a-f0-9]{64}$/u.test(l.listingId) ||
      typeof l.channel !== "string" || !["retail", "wholesale", "bulk"].includes(l.channel) ||
      [s.sourceRevision, s.locationKey, s.slotId].some(v => typeof v !== "string" || !v.length || v !== v.trim()) ||
      scheduledInstantMicros(s.endsAt) <= scheduledInstantMicros(s.startsAt)) fail();
  return {schemaVersion: 1, method: "scheduled", listing: {schemaVersion: 1, realm,
    listingId: l.listingId, storeId, skuId: line.skuId, canonicalProductId: line.canonicalProductId,
    verifiedPackId: line.verifiedPackId, channel: l.channel as OriginalScheduledFulfilment["listing"]["channel"]},
    sourceRevision: s.sourceRevision as string, locationKey: s.locationKey as string, slotId: s.slotId as string,
    startsAt: s.startsAt as string, endsAt: s.endsAt as string};
}
function originalPublicListing(value: unknown, realm: Realm, storeId: string, line: PlacementLine): OriginalPublicListing | null {
  if (value === null) return null;
  const l = exact(value, ["schemaVersion", "realm", "listingId", "storeId", "skuId", "canonicalProductId", "verifiedPackId", "channel"]);
  if (l.schemaVersion !== 1 || l.realm !== realm || l.storeId !== storeId || l.skuId !== line.skuId ||
      l.canonicalProductId !== line.canonicalProductId || l.verifiedPackId !== line.verifiedPackId ||
      typeof l.channel !== "string" || !["retail", "wholesale", "bulk"].includes(l.channel) ||
      l.listingId !== `listing-${digest([1, realm, storeId, line.skuId, l.channel])}`) fail();
  return {schemaVersion: 1, realm, listingId: l.listingId as string, storeId, skuId: line.skuId,
    canonicalProductId: line.canonicalProductId, verifiedPackId: line.verifiedPackId, channel: l.channel as OriginalPublicListing["channel"]};
}
function line(v: unknown, withVariant = false, scheduledScope?: {realm: Realm; storeId: string}, withPublicListing = false): PlacementLine {
  const r = exact(v, [...lineKeys, ...(withVariant ? ["variant"] : []), ...(scheduledScope ? ["scheduledFulfilment"] : []),
    ...(withPublicListing ? ["publicListing"] : [])]);
  // Match reviewed catalogue variant text, including its permitted line breaks.
  if (withVariant && (typeof r.variant !== "string" || r.variant !== r.variant.trim() ||
      r.variant.length > 240 || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(r.variant))) fail();
  if (typeof r.quantityUnit !== "string" || !["pack", "kg", "L", "count"].includes(r.quantityUnit)) fail();
  const result: PlacementLine = {sourceLineId: id(r.sourceLineId), skuId: id(r.skuId), canonicalProductId: id(r.canonicalProductId),
    verifiedPackId: id(r.verifiedPackId), offerId: id(r.offerId), offerRevision: id(r.offerRevision),
    name: text(r.name), packLabel: text(r.packLabel), quantityMilli: integer(r.quantityMilli, 1_000_000_000, 1),
    quantityUnit: r.quantityUnit as PlacementLine["quantityUnit"],
    unitPriceMinor: integer(r.unitPriceMinor), lineTotalMinor: integer(r.lineTotalMinor),
    ...(withVariant ? {variant: r.variant as string} : {})};
  if (scheduledScope) result.scheduledFulfilment = scheduledOriginal(r.scheduledFulfilment, scheduledScope.realm, scheduledScope.storeId, result);
  if (withPublicListing) {
    if (!scheduledScope) fail();
    result.publicListing = originalPublicListing(r.publicListing, scheduledScope.realm, scheduledScope.storeId, result);
    if (result.publicListing !== null && result.scheduledFulfilment != null &&
        integrityHash(result.publicListing) !== integrityHash(result.scheduledFulfilment.listing)) fail();
  }
  // Contract: gross unit price per quantityUnit; quantity in thousandths;
  // gross line rounded half-up to paise. Discounts are explicit order totals.
  // This validates supplied facts, never derives a price/discount/eligibility.
  if ((BigInt(result.unitPriceMinor) * BigInt(result.quantityMilli) + 500n) / 1000n !==
      BigInt(result.lineTotalMinor)) fail();
  return result;
}
export function normalizePlacement(value: unknown, realm: Realm): TrustedPlacementReceipt {
  const r = exact(value, ["schemaVersion", "realm", "authNamespace", "finalPlacement", "issuer",
    "receiptId", "revision", "buyerUserId", "stores"]);
  if ((r.schemaVersion !== 1 && r.schemaVersion !== 2 && r.schemaVersion !== 3 && r.schemaVersion !== 4 && r.schemaVersion !== 5) || r.realm !== realm || r.authNamespace !== "firebase-default" ||
      r.finalPlacement !== true || !["evaluation", "production"].includes(realm)) fail();
  const stores = array(r.stores, 10).map(raw => {
    const s = exact(raw, ["storeId", "caseId", "ownerUserId", "lines", "totals",
      ...(r.schemaVersion !== 1 ? ["benefitAttribution"] : [])]);
    const lines = array(s.lines, 100).map(value => line(value, (r.schemaVersion as number) >= 3,
      (r.schemaVersion as number) >= 4 ? {realm, storeId: id(s.storeId)} : undefined, r.schemaVersion === 5)).sort((a,b) => compare(a.sourceLineId, b.sourceLineId));
    unique(lines.map(l => l.sourceLineId));
    const amounts = totals(s.totals, lines.reduce((sum, l) => sum + l.lineTotalMinor, 0));
    return {storeId: id(s.storeId), caseId: id(s.caseId), ownerUserId: id(s.ownerUserId), lines, totals: amounts,
      ...(r.schemaVersion !== 1 ? {benefitAttribution: benefits(s.benefitAttribution,
        lines.map(l => ({lineId: l.sourceLineId, lineTotalMinor: l.lineTotalMinor})), amounts.discountMinor)} : {})};
  }).sort((a,b) => compare(a.storeId, b.storeId));
  unique(stores.map(s => s.storeId)); unique(stores.map(s => s.caseId));
  if (stores.reduce((sum, s) => sum + s.lines.length, 0) > 200) fail();
  const result: TrustedPlacementReceipt = {schemaVersion: r.schemaVersion, realm, authNamespace: "firebase-default",
    finalPlacement: true, issuer: id(r.issuer), receiptId: id(r.receiptId), revision: id(r.revision),
    buyerUserId: id(r.buyerUserId), stores};
  // Strictly below Firestore's 1MiB aggregate bound, including generated IDs.
  if (Buffer.byteLength(JSON.stringify(result), "utf8") > 300_000) fail();
  return result;
}
function compare(a: string, b: string): number {return a < b ? -1 : a > b ? 1 : 0;}
function requireStore(value: unknown, expected: {caseId: string; storeId: string; ownerUserId: string}, requireNewSales = true): void {
  if (!value) fail("not_found", 404);
  const p = obj(value);
  if (p.schemaVersion !== 1 || p.caseId !== expected.caseId || p.workspaceId !== expected.storeId ||
      p.ownerUserId !== expected.ownerUserId || p.familyId !== "products-trade" ||
      !["retailer-grocery", "retailer-speciality", "wholesaler", "manufacturer"].includes(String(p.profileId)) ||
      p.status !== "live" || (requireNewSales && p.shopEnabled !== true)) fail("not_found", 404);
}
export function purchaseOriginalFingerprint(storeId: string, orderId: string, original: PurchaseOriginal): string {
  return digest({factsVersion: original.lines.some(l => l.publicListing !== undefined) ? 6 : original.lines.some(l => l.scheduledFulfilment !== undefined) ? 5 : original.lines.some(l => l.variant !== undefined) ? 4 :
    original.benefitAttribution === undefined ? 2 : 3, storeId, orderId, original});
}
function validateAggregate(value: unknown, purchaseId: string, realm: Realm): PurchaseAggregate {
  try {
    const r = exact(value, ["schemaVersion", "realm", "authNamespace", "purchaseId", "buyerUserId",
      "buyerId", "sourceRevision", "sourceFingerprint", "createdAt", "orders", "integrity"]);
    if ((r.schemaVersion !== 2 && r.schemaVersion !== 3 && r.schemaVersion !== 4 && r.schemaVersion !== 5 && r.schemaVersion !== 6) || r.realm !== realm || r.authNamespace !== "firebase-default" ||
        r.purchaseId !== purchaseId || !/^[a-f0-9]{64}$/u.test(String(r.sourceFingerprint))) fail();
    id(r.buyerUserId); id(r.buyerId); id(r.sourceRevision);
    if (typeof r.createdAt !== "string" || new Date(r.createdAt).toISOString() !== r.createdAt) fail();
    const orders = array(r.orders, 10).map(raw => {
      const o = exact(raw, ["factsVersion", "storeId", "orderId", "original", "originalFingerprint", "caseId", "ownerUserId"]);
      if (o.factsVersion !== r.schemaVersion) fail();
      const original = exact(o.original, ["currency", "lines", "totals",
        ...(o.factsVersion !== 2 ? ["benefitAttribution"] : [])]);
      if (original.currency !== "INR") fail();
      const lines = array(original.lines, 100).map(rawLine => {
        const l = exact(rawLine, [...lineKeys.filter(k => k !== "sourceLineId"), "lineId",
          ...((o.factsVersion as number) >= 4 ? ["variant"] : []), ...((o.factsVersion as number) >= 5 ? ["scheduledFulfilment"] : []),
          ...(o.factsVersion === 6 ? ["publicListing"] : [])]);
        const {lineId, ...rest} = l;
        const {sourceLineId, ...normalized} = line({...rest, sourceLineId: lineId}, (o.factsVersion as number) >= 4,
          (o.factsVersion as number) >= 5 ? {realm, storeId: id(o.storeId)} : undefined, o.factsVersion === 6);
        return {lineId: sourceLineId, ...normalized};
      }).sort((a,b) => compare(a.lineId, b.lineId));
      unique(lines.map(l => l.lineId));
      const canonical: PurchaseOriginal = {currency: "INR", lines,
        totals: totals(original.totals, lines.reduce((sum,l) => sum + l.lineTotalMinor, 0))};
      if (o.factsVersion !== 2) canonical.benefitAttribution = benefits(original.benefitAttribution, lines, canonical.totals.discountMinor);
      const result: StoredOrder = {factsVersion: o.factsVersion as PurchaseFactsVersion, storeId: id(o.storeId), orderId: id(o.orderId),
        original: canonical, originalFingerprint: String(o.originalFingerprint),
        caseId: id(o.caseId), ownerUserId: id(o.ownerUserId)};
      if (result.originalFingerprint !== purchaseOriginalFingerprint(result.storeId, result.orderId, canonical)) fail();
      return result;
    });
    unique(orders.map(o => o.storeId)); unique(orders.map(o => o.orderId));
    const {integrity, ...body} = r;
    if (integrity !== integrityHash(body)) fail();
    return {...r, orders} as unknown as PurchaseAggregate;
  } catch {return fail("invalid_state", 409);}
}

/** Internal producer + read projections only. No pricing, payment, inventory,
 * seller transition, legacy retailerOrders writes or externally callable create. */
export class WorkspacePurchaseProjectionService {
  constructor(private readonly db: Firestore, private readonly realm: Realm,
    private readonly source?: FinalPlacementSource) {
    if (!["evaluation", "production"].includes(realm)) fail("service_unavailable", 503);
  }
  private root() {return this.db.collection("workspacePurchaseProjections").doc(this.realm);}

  async materialize(reference: string): Promise<{purchaseId: string; buyerId: string}> {
    id(reference);
    if (!this.source) fail("service_unavailable", 503);
    const raw = await this.source.readFinalPlacement(reference);
    if (!raw) fail("not_found", 404);
    const input = normalizePlacement(raw, this.realm);
    const sourceFingerprint = digest(input);
    // Revision deliberately excluded: a changed revision cannot create a second purchase.
    const receipt = this.root().collection("receipts").doc(digest([
      this.realm, input.authNamespace, input.buyerUserId, input.issuer, input.receiptId]));
    const buyer = this.root().collection("buyers").doc(digest([input.authNamespace, input.buyerUserId]));
    // Allocate outside transaction retries, use persisted directory winner inside retries.
    const purchaseId = `purchase-${randomUUID()}`, candidateBuyerId = `buyer-${randomUUID()}`;
    const allocatedOrders = input.stores.map(s => ({
      ...s, orderId: `order-${randomUUID()}`,
      lines: s.lines.map(l => ({...l, lineId: `line-${randomUUID()}`})),
    }));
    const createdAt = new Date().toISOString();
    return this.db.runTransaction(async tx => {
      const receiptDoc = await tx.get(receipt);
      if (receiptDoc.exists) {
        const saved = receiptDoc.data()!;
        if (saved.sourceFingerprint !== sourceFingerprint) fail("conflict", 409);
        const stored = await tx.get(this.root().collection("purchases").doc(id(saved.purchaseId)));
        const aggregate = validateAggregate(stored.data(), saved.purchaseId, this.realm);
        if (aggregate.sourceFingerprint !== sourceFingerprint || aggregate.buyerUserId !== input.buyerUserId) fail("invalid_state", 409);
        return {purchaseId: aggregate.purchaseId, buyerId: aggregate.buyerId};
      }
      const buyerDoc = await tx.get(buyer);
      const buyerData = buyerDoc.data();
      if (buyerDoc.exists && (buyerData?.userId !== input.buyerUserId || buyerData.authNamespace !== input.authNamespace)) fail("invalid_state", 409);
      const buyerId = buyerDoc.exists ? id(buyerData!.buyerId) : candidateBuyerId;
      for (const store of input.stores) {
        const profile = await tx.get(this.db.collection("workspaceProfiles").doc(store.caseId));
        requireStore(profile.data(), store);
      }
      const orders: StoredOrder[] = allocatedOrders.map(s => {
        const lines = s.lines.map(l => {
          const {sourceLineId: _source, lineId, ...facts} = l;
          return {lineId, ...facts};
        }).sort((a,b) => compare(a.lineId, b.lineId));
        const original: PurchaseOriginal = {currency: "INR", lines, totals: s.totals};
        if (s.benefitAttribution !== undefined) {
          const savedIds = new Map(s.lines.map(l => [l.sourceLineId, l.lineId]));
          original.benefitAttribution = {...s.benefitAttribution, components: s.benefitAttribution.components.map(c => ({
            ...c, allocations: c.allocations.map(a => ({...a, lineId: savedIds.get(a.lineId)!})),
          }))};
        }
        return {factsVersion: (input.schemaVersion + 1) as PurchaseFactsVersion, storeId: s.storeId, orderId: s.orderId, original,
          originalFingerprint: purchaseOriginalFingerprint(s.storeId, s.orderId, original),
          caseId: s.caseId, ownerUserId: s.ownerUserId};
      });
      const body = {schemaVersion: (input.schemaVersion + 1) as PurchaseFactsVersion, realm: this.realm, authNamespace: "firebase-default" as const,
        purchaseId, buyerUserId: input.buyerUserId, buyerId, sourceRevision: input.revision,
        sourceFingerprint, createdAt, orders};
      // Saved UUID line IDs expand each allocation. Bound the actual buyer
      // projection, not only source bytes, before any transaction creates.
      // Leave room below the existing 512KiB client cap for operational context
      // and the response envelope. Never truncate immutable original facts.
      const projection = this.projection(body, input.buyerUserId, "buyer", orders);
      if (Buffer.byteLength(JSON.stringify({ok: true, data: projection}), "utf8") > 480 * 1024) fail();
      tx.create(this.root().collection("purchases").doc(purchaseId), {...body, integrity: integrityHash(body)});
      for (const order of orders) tx.create(this.referencePath(order), this.pointer(body, order));
      tx.create(receipt, {purchaseId, sourceFingerprint});
      if (!buyerDoc.exists) tx.create(buyer, {userId: input.buyerUserId, authNamespace: input.authNamespace, buyerId});
      return {purchaseId, buyerId};
    });
  }

  private referencePath(o: StoredOrder) {
    return this.root().collection("stores").doc(o.storeId).collection("orderReferences").doc(o.orderId);
  }
  private pointer(a: Pick<PurchaseAggregate, "purchaseId" | "sourceRevision">, o: StoredOrder) {
    return {...this.reference(a, o), caseId: o.caseId, ownerUserId: o.ownerUserId};
  }
  private reference(a: Pick<PurchaseAggregate, "purchaseId" | "sourceRevision">, o: StoredOrder): PurchaseReference {
    return {purchaseId: a.purchaseId, storeId: o.storeId, orderId: o.orderId,
      originalFingerprint: o.originalFingerprint, sourceRevision: a.sourceRevision};
  }

  /** Explicit server-internal compatibility repair. Never called by HTTP reads.
   * Pointers only; original aggregate and commercial states remain immutable. */
  async indexReferences(purchaseId: string): Promise<void> {
    id(purchaseId);
    await this.db.runTransaction(async tx => {
      const doc = await tx.get(this.root().collection("purchases").doc(purchaseId));
      const a = validateAggregate(doc.data(), purchaseId, this.realm);
      const missing: StoredOrder[] = [];
      for (const order of a.orders) {
        // Historical pointers attest only immutable original ownership. Current
        // eligibility is enforced on reads, independently for each Store.
        const pointer = await tx.get(this.referencePath(order));
        if (!pointer.exists) missing.push(order);
        else if (integrityHash(pointer.data()) !== integrityHash(this.pointer(a, order))) fail("conflict", 409);
      }
      for (const order of missing) tx.create(this.referencePath(order), this.pointer(a, order));
    });
  }

  private pageQuery(actor: string, body: Readonly<Record<string, unknown>>, seller: boolean) {
    exact(body, seller ? ["storeId", "limit", "cursor"] : ["limit", "cursor"]);
    id(actor);
    const storeId = seller ? id(body.storeId) : null;
    const limit = integer(body.limit, 5, 1);
    const scope = digest([this.realm, "firebase-default", actor, seller ? "seller" : "buyer", storeId]);
    let after: string | undefined;
    if (body.cursor !== null) {
      try {
        const token = text(body.cursor, 512);
        const parsed = exact(JSON.parse(Buffer.from(token, "base64url").toString("utf8")), ["version", "scope", "after"]);
        if (parsed.version !== 1 || parsed.scope !== scope) fail();
        after = id(parsed.after);
        if (Buffer.from(JSON.stringify(parsed)).toString("base64url") !== token) fail();
      } catch {fail();}
    }
    return {storeId, limit, after, cursor: (last: string | undefined) => last
      ? Buffer.from(JSON.stringify({version: 1, scope, after: last})).toString("base64url") : null};
  }
  private page(actor: string, seller: boolean, storeId: string | null,
    references: PurchaseReference[], nextCursor: string | null): PurchaseReferencePage {
    return {schemaVersion: 2, realm: this.realm, authNamespace: "firebase-default",
      viewerRole: seller ? "seller" : "buyer", viewerUserId: actor, storeId,
      coverage: seller ? "indexed_original_facts" : "saved_original_facts", references, nextCursor};
  }

  async listBuyer(actor: string, body: Readonly<Record<string, unknown>>): Promise<PurchaseReferencePage> {
    const p = this.pageQuery(actor, body, false);
    let query = this.root().collection("purchases").where("buyerUserId", "==", actor)
      .orderBy(FieldPath.documentId()).limit(p.limit);
    if (p.after) query = query.startAfter(p.after);
    const docs = await query.get();
    const references = docs.docs.flatMap(doc => {
      const a = validateAggregate(doc.data(), doc.id, this.realm);
      if (a.buyerUserId !== actor) fail("invalid_state", 409);
      return a.orders.map(o => this.reference(a, o));
    });
    return this.page(actor, false, null, references,
      p.cursor(docs.size === p.limit ? docs.docs.at(-1)?.id : undefined));
  }

  async listStore(actor: string, body: Readonly<Record<string, unknown>>): Promise<PurchaseReferencePage> {
    const p = this.pageQuery(actor, body, true);
    const storeId = p.storeId!;
    return this.db.runTransaction(async tx => {
      // Current exact-Store capability, before pointer lookup, consistent with partition reads.
      const profiles = await tx.get(this.db.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2));
      if (profiles.size !== 1) fail("not_found", 404);
      const profileDoc = profiles.docs[0]!;
      // Historical references remain private to the current approved owner,
      // independently of whether this Store is accepting new sales.
      requireStore(profileDoc.data(), {caseId: profileDoc.id, storeId, ownerUserId: actor}, false);
      let query = this.root().collection("stores").doc(storeId).collection("orderReferences")
        .orderBy(FieldPath.documentId()).limit(p.limit);
      if (p.after) query = query.startAfter(p.after);
      const docs = await tx.get(query);
      const references: PurchaseReference[] = [];
      // At most5 pointers/aggregates per page. Do not loop to fill excluded slots.
      for (const pointer of docs.docs) {
        const value = pointer.data();
        let purchaseId: string;
        try {purchaseId = id(value.purchaseId);} catch {continue;}
        const doc = await tx.get(this.root().collection("purchases").doc(purchaseId));
        if (!doc.exists) continue;
        let a: PurchaseAggregate;
        try {a = validateAggregate(doc.data(), purchaseId, this.realm);} catch {continue;}
        const order = a.orders.find(o => o.storeId === storeId && o.orderId === pointer.id &&
          o.ownerUserId === actor && o.caseId === profileDoc.id);
        if (!order || integrityHash(value) !== integrityHash(this.pointer(a, order))) continue;
        references.push(this.reference(a, order));
      }
      return this.page(actor, true, storeId, references,
        p.cursor(docs.size === p.limit ? docs.docs.at(-1)?.id : undefined));
    });
  }

  async readBuyer(actor: string, body: Readonly<Record<string, unknown>>): Promise<PurchaseProjection> {
    exact(body, ["purchaseId"]); id(actor);
    const purchaseId = id(body.purchaseId);
    const doc = await this.root().collection("purchases").doc(purchaseId).get();
    if (!doc.exists || doc.data()?.buyerUserId !== actor) fail("not_found", 404);
    const aggregate = validateAggregate(doc.data(), purchaseId, this.realm);
    return this.projection(aggregate, actor, "buyer", aggregate.orders);
  }

  async readStore(actor: string, body: Readonly<Record<string, unknown>>): Promise<PurchaseProjection> {
    exact(body, ["purchaseId", "storeId", "orderId"]); id(actor);
    const purchaseId = id(body.purchaseId), storeId = id(body.storeId), orderId = id(body.orderId);
    return this.db.runTransaction(async tx => {
      const doc = await tx.get(this.root().collection("purchases").doc(purchaseId));
      if (!doc.exists) fail("not_found", 404);
      const aggregate = validateAggregate(doc.data(), purchaseId, this.realm);
      const order = aggregate.orders.find(o => o.storeId === storeId && o.orderId === orderId && o.ownerUserId === actor);
      if (!order) fail("not_found", 404);
      const profile = await tx.get(this.db.collection("workspaceProfiles").doc(order.caseId));
      requireStore(profile.data(), {caseId: order.caseId, storeId, ownerUserId: actor}, false);
      return this.projection(aggregate, actor, "seller", [order]);
    });
  }

  private projection(a: Pick<PurchaseAggregate, "schemaVersion" | "purchaseId" | "buyerId" | "sourceRevision">,
    actor: string, role: "buyer" | "seller", orders: StoredOrder[]): PurchaseProjection {
    return {schemaVersion: a.schemaVersion, realm: this.realm, authNamespace: "firebase-default",
      viewerRole: role, viewerUserId: actor, purchaseId: a.purchaseId, buyerId: a.buyerId,
      sourceRevision: a.sourceRevision, state: "original_facts",
      orders: orders.map(({caseId: _caseId, ownerUserId: _owner, ...publicFacts}) => publicFacts)};
  }
}
