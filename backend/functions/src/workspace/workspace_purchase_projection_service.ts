import {createHash, randomUUID} from "node:crypto";
import {FieldPath, type Firestore, type Transaction} from "firebase-admin/firestore";
import {WorkspaceProfileError} from "./workspace_profile_service.js";
import type {WorkspaceCatalogueService} from "./workspace_catalogue_service.js";

type Realm = "evaluation" | "production";
export type PurchaseFactsVersion = 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10;
/** Accepted public selling-pack terms supplied by the trusted final-placement
 * source. Confirmation/acceptance times are distinct; neither is a payment
 * deadline or evidence of payment/reservation. Never refresh from today's SKU. */
export interface OriginalCommodityPriceSnapshot {
  schemaVersion: 1; termsRevision: string; confirmationRevision: number;
  confirmedAt: string; validUntil: string; frequent: boolean; agreedAt: string;
  priceMinor: number; minimumPacks: number; incrementPacks: number;
  tiers: {minimumPacks: number; unitPriceMinor: number}[];
}
/** Frozen supplier statement, not verified tax, an invoice or a charged amount.
 * The trusted placement producer supplies the accepted source; never hydrate
 * this from today's catalogue or interpret ingestion time as purchase time. */
export interface OriginalSupplierTaxSnapshot {
  schemaVersion: 1; termsRevision: string; observedAt: string; expiresAt: string | null;
  declaration: {version: 2; rateBasisPoints: number; basis: "included" | "additional"} |
    {version: 1; amountMinor: number; basis: "included" | "additional"};
}
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
  supplierTaxSnapshot?: OriginalSupplierTaxSnapshot | null;
  commodityPriceSnapshot?: OriginalCommodityPriceSnapshot | null;
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
  fulfilmentContext?: OriginalFulfilmentContext | null;
  supplierQuote?: OriginalSupplierQuote | null;
}
/** Frozen customer details, not address verification, serviceability or delivery
 * assignment. Instruction lineId references sourceLineId before materializing.
 * Never project this private context into catalogue, feedback or analytics. */
export interface OriginalFulfilmentContext {
  schemaVersion: 1; method: "delivery" | "collection";
  recipient: {name: string; phone: string} | null;
  address: {line: string; area: string; pinCode: string; landmark: string} | null;
  instructions: {lineId: string; text: string}[];
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
  schemaVersion: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9; realm: Realm; authNamespace: "firebase-default";
  finalPlacement: true; issuer: string; receiptId: string; revision: string;
  buyerUserId: string; stores: PlacementStore[];
  /** Private independently versioned commit facts; never a public projection. */
  couponUseContext?: {schemaVersion: 1; stores: {
    storeId: string; couponId: string; couponRevision: number; componentId: string;
    basket: Record<string, unknown>; holdUntil: string; lifecycleSourceId: string;
  }[]};
}
export interface PurchaseCouponTransactionContext {
  receipt: TrustedPlacementReceipt; purchaseId: string; createdAt: string;
  orders: {storeId: string; orderId: string; lines: {sourceLineId: string; lineId: string}[]}[];
}
export interface PurchaseCouponCommitter {
  /** Read all Stores first; returned writer runs before the purchase creates. */
  prepareCouponHolds(tx: Transaction, context: PurchaseCouponTransactionContext): Promise<() => void>;
}
export interface FinalPlacementSource {
  readFinalPlacement(reference: string): Promise<TrustedPlacementReceipt | undefined>;
}
export interface PurchasedLine extends Omit<PlacementLine, "sourceLineId"> {lineId: string}
export interface PurchaseOriginal {
  currency: "INR"; lines: PurchasedLine[]; totals: PurchaseTotals;
  benefitAttribution?: OriginalBenefitAttribution;
  fulfilmentContext?: OriginalFulfilmentContext | null;
  supplierQuote?: OriginalSupplierQuote | null;
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
/** Private eligible purchased context, not a published review or save permission. */
export interface ProductFeedbackTarget extends PurchaseReference {
  id: string; kind: "product"; orderLineId: string; productId: string; productLabel: string;
  purchasedListing: OriginalPublicListing; completedAt: string; completionId: string; completionRevision: string;
}
interface StoredProductFeedbackTarget {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default"; buyerUserId: string;
  target: ProductFeedbackTarget; integrity: string;
}
export interface ProductFeedbackTargetPage {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default";
  viewerRole: "buyer"; viewerUserId: string; coverage: "indexed_recorded_completions";
  targets: ProductFeedbackTarget[]; nextCursor: string | null;
}
/** Private retailer improvement signal. Never a public review/aggregate. */
export interface ProductStars {
  target: ProductFeedbackTarget; stars: number; revision: number; updatedAt: string;
}
interface StoredProductStars {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default";
  buyerUserId: string; storeId: string; rating: ProductStars; integrity: string;
}
export interface ProductStarsResult {
  schemaVersion: 1; realm: Realm; authNamespace: "firebase-default";
  viewerRole: "buyer"; viewerUserId: string; operationId: string;
  state: "saved" | "not_recorded" | "superseded"; rating: ProductStars | null;
  targetId?: string; observedRevision?: number;
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
  originalFactsVersion?: 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10;
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

interface BulkRequestLine {lineId: string; skuId: string; listingId: string; skuRevision: number; quantity: number}
// Match reviewed catalogue text; do not narrow legitimate stored SKU variants
// merely because the purchase-identity text validator has different rules.
function bulkVariant(value: unknown): string {
  if (typeof value !== 'string' || value !== value.trim() || !value.length || value.length > 240 ||
    /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)) fail();
  return value as string;
}
interface BulkQuotedLine extends BulkRequestLine {
  canonicalProductId: string; verifiedPackId: string; name: string; packLabel: string;
  variant?: string;
  supplierPolicy: Record<string, unknown> | null;
}
interface BulkPrice {lineId: string; unitPriceMinor: number; merchandiseMinor: number}
interface BulkOffer {revision: number; offeredAt: string; validUntil: string; prices: BulkPrice[];
  merchandiseMinor: number; policyFingerprint: string}
interface BulkAgreementRecord {
  schemaVersion: 1; realm: Realm; quoteId: string; storeId: string; storeCaseId: string;
  storeName?: string;
  buyerUserId: string; supplierUserId: string; revision: number;
  state: 'requested' | 'offered' | 'accepted' | 'withdrawn';
  requestedAt: string; updatedAt: string; lines: BulkQuotedLine[]; offer: BulkOffer | null;
  acceptance: {offerRevision: number; acceptedAt: string; agreementFingerprint: string} | null;
}
export type BulkSupplierQuoteAction = 'request' | 'offer' | 'accept' | 'withdraw' | 'read' | 'list_buyer' | 'list_store' | 'reconcile';
/** Exact merchandise attribution, not final charges or a payment/credit grant.
 * lineId is the trusted placement source ID; the materializer remaps it once. */
export interface OriginalSupplierQuote {
  schemaVersion: 1; realm: Realm; quoteId: string; acceptedRevision: number;
  agreementFingerprint: string; offerRevision: number; acceptedAt: string;
  validUntil: string; merchandiseMinor: number;
  lines: {lineId: string; quoteLineId: string}[];
}
export interface BulkPurchaseReference {
  schemaVersion: 1; quoteId: string; acceptedRevision: number; agreementFingerprint: string;
  lines: {lineId: string; quoteLineId: string}[];
}
export interface BulkCouponPriceLine {
  lineId: string; listing: OriginalPublicListing; skuRevision: number; quantity: number;
}
export interface BulkCouponPrices {
  supplierQuote: OriginalSupplierQuote;
  prices: {lineId: string; unitPriceMinor: number; merchandiseMinor: number}[];
}
export function bulkSupplierQuoteOperation(operation: unknown): BulkSupplierQuoteAction | undefined {
  switch (operation) {
    case 'requestBulkSupplierQuote': return 'request';
    case 'offerBulkSupplierQuote': return 'offer';
    case 'acceptBulkSupplierQuote': return 'accept';
    case 'withdrawBulkSupplierQuote': return 'withdraw';
    case 'readBulkSupplierQuote': return 'read';
    case 'listBuyerBulkSupplierQuotes': return 'list_buyer';
    case 'listStoreBulkSupplierQuotes': return 'list_store';
    case 'reconcileBulkSupplierQuote': return 'reconcile';
    default: return undefined;
  }
}
/** Private merchandise negotiation, NOT a final Checkout quote, purchase, PO,
 * credit entitlement, reservation, payment or delivery instruction. The real
 * reviewed catalogue is read in the same transaction as the agreement write. */
export class WorkspaceBulkQuoteService {
  constructor(private readonly db: Firestore, private readonly realm: Realm,
    private readonly catalogue: Pick<WorkspaceCatalogueService, 'bulkQuotationSnapshot'>,
    private readonly now: () => Date = () => new Date()) {
    if (!['evaluation', 'production'].includes(realm)) fail('service_unavailable', 503);
  }
  private root() {return this.db.collection('workspacePurchaseProjections').doc(this.realm);}
  private path(quoteId: string) {return this.root().collection('bulkQuoteRequests').doc(quoteId);}
  /** Server-internal final-purchase seam. Perform ALL preparation reads before
   * calling commit in the SAME transaction as the immutable purchase create.
   * Browsing/selection never calls this, and this method creates no purchase. */
  async preparePurchase(tx: Transaction, context: {buyerUserId: string; storeId: string;
    caseId: string; ownerUserId: string; purchaseId: string}, reference: BulkPurchaseReference,
    lines: readonly PlacementLine[]): Promise<{supplierQuote: OriginalSupplierQuote; commit: () => void}> {
    for (const value of Object.values(context)) id(value);
    const {record, bindings, supplierQuote, use} = await this.acceptedForUse(tx, context.buyerUserId, context.storeId, reference);
    if (record.storeCaseId !== context.caseId || record.supplierUserId !== context.ownerUserId || bindings.length !== lines.length) fail('not_found', 404);
    for (const binding of bindings) {
      const agreed = record.lines.find(l => l.lineId === binding.quoteLineId),
        purchased = lines.find(l => l.sourceLineId === binding.lineId),
        price = record.offer!.prices.find(p => p.lineId === binding.quoteLineId);
      if (!agreed || !purchased || !price || purchased.skuId !== agreed.skuId ||
          purchased.canonicalProductId !== agreed.canonicalProductId || purchased.verifiedPackId !== agreed.verifiedPackId ||
          purchased.quantityUnit !== 'pack' || purchased.quantityMilli !== agreed.quantity * 1000 ||
          purchased.unitPriceMinor !== price.unitPriceMinor || purchased.lineTotalMinor !== price.merchandiseMinor ||
          purchased.publicListing?.realm !== this.realm || purchased.publicListing.storeId !== context.storeId ||
          purchased.publicListing.channel !== 'bulk' || purchased.publicListing.skuId !== agreed.skuId ||
          purchased.publicListing.listingId !== agreed.listingId || purchased.publicListing.canonicalProductId !== agreed.canonicalProductId ||
          purchased.publicListing.verifiedPackId !== agreed.verifiedPackId || purchased.variant !== (agreed.variant ?? '') ||
          purchased.name !== agreed.name || purchased.packLabel !== agreed.packLabel) fail('conflict', 409);
    }
    const frozen = structuredClone({supplierQuote, context});
    return {supplierQuote: structuredClone(supplierQuote), commit: () => {
      if (this.now().toISOString() >= frozen.supplierQuote.validUntil) fail('conflict', 409);
      const body = {schemaVersion: 1, realm: this.realm, quoteId: frozen.supplierQuote.quoteId, purchaseId: frozen.context.purchaseId,
        buyerUserId: frozen.context.buyerUserId, storeId: frozen.context.storeId,
        acceptedRevision: frozen.supplierQuote.acceptedRevision, agreementFingerprint: frozen.supplierQuote.agreementFingerprint, usedAt: this.now().toISOString()};
      tx.create(use, {...body, integrity: integrityHash(body)});
    }};
  }
  /** Read-only, caller-transaction authority. Browsing neither consumes the
   * agreement nor reserves a coupon. Catalogue revisions remain independently
   * verified by the coupon producer in this same transaction. */
  async readCouponPrices(tx: Transaction, buyerUserId: string, storeId: string, reference: BulkPurchaseReference,
    lines: readonly BulkCouponPriceLine[]): Promise<BulkCouponPrices> {
    const {record, bindings, supplierQuote} = await this.acceptedForUse(tx, buyerUserId, storeId, reference);
    if (lines.length !== bindings.length || new Set(lines.map(l => l.lineId)).size !== lines.length) fail('conflict', 409);
    const prices = bindings.map(binding => {
      const agreed = record.lines.find(l => l.lineId === binding.quoteLineId), line = lines.find(l => l.lineId === binding.lineId),
        price = record.offer!.prices.find(p => p.lineId === binding.quoteLineId);
      if (!agreed || !line || !price || line.skuRevision !== agreed.skuRevision || line.quantity !== agreed.quantity ||
          line.listing.schemaVersion !== 1 || line.listing.realm !== this.realm || line.listing.storeId !== storeId ||
          line.listing.channel !== 'bulk' || line.listing.listingId !== agreed.listingId || line.listing.skuId !== agreed.skuId ||
          line.listing.canonicalProductId !== agreed.canonicalProductId || line.listing.verifiedPackId !== agreed.verifiedPackId) fail('conflict', 409);
      return {lineId: binding.lineId, unitPriceMinor: price.unitPriceMinor, merchandiseMinor: price.merchandiseMinor};
    });
    return {supplierQuote: structuredClone(supplierQuote), prices};
  }
  private async acceptedForUse(tx: Transaction, actor: string, storeId: string, reference: BulkPurchaseReference) {
    id(actor); id(storeId);
    const r = exact(reference, ['schemaVersion', 'quoteId', 'acceptedRevision', 'agreementFingerprint', 'lines']);
    const quoteId = id(r.quoteId), acceptedRevision = integer(r.acceptedRevision, 999999999, 3);
    if (r.schemaVersion !== 1 || !/^bulk-[a-f0-9]{64}$/u.test(quoteId) ||
        typeof r.agreementFingerprint !== 'string' || !/^[a-f0-9]{64}$/u.test(r.agreementFingerprint)) fail();
    const bindings = array(r.lines, 100).map(raw => {
      const b = exact(raw, ['lineId', 'quoteLineId']); return {lineId: id(b.lineId), quoteLineId: id(b.quoteLineId)};
    }).sort((a, b) => compare(a.lineId, b.lineId));
    unique(bindings.map(b => b.lineId)); unique(bindings.map(b => b.quoteLineId));
    const doc = await tx.get(this.path(quoteId));
    const record = await this.authorized(tx, doc.data(), actor, quoteId);
    if (record.buyerUserId !== actor || record.storeId !== storeId) fail('not_found', 404);
    await this.profile(tx, storeId, record.supplierUserId, record.storeCaseId);
    if (record.state !== 'accepted' || record.revision !== acceptedRevision || !record.offer || !record.acceptance ||
        record.acceptance.agreementFingerprint !== r.agreementFingerprint || bindings.length !== record.lines.length ||
        bindings.some(b => !record.lines.some(l => l.lineId === b.quoteLineId))) fail('conflict', 409);
    const use = this.root().collection('bulkQuoteUses').doc(quoteId), used = await tx.get(use);
    if (used.exists || this.now().toISOString() >= record.offer.validUntil) fail('conflict', 409);
    const supplierQuote: OriginalSupplierQuote = {schemaVersion: 1, realm: this.realm, quoteId,
      acceptedRevision, agreementFingerprint: r.agreementFingerprint, offerRevision: record.offer.revision,
      acceptedAt: record.acceptance.acceptedAt, validUntil: record.offer.validUntil,
      merchandiseMinor: record.offer.merchandiseMinor, lines: bindings};
    return {record, bindings, supplierQuote, use};
  }
  private policy(raw: unknown, storeId: string, skuId: string): Record<string, unknown> {
    const p = exact(raw, ['schemaVersion', 'realm', 'storeId', 'skuId', 'state', 'revision', 'requiresAcceptance', 'policy']);
    if (p.schemaVersion !== 1 || p.realm !== this.realm || p.storeId !== storeId || p.skuId !== skuId ||
      typeof p.state !== 'string' || !['ready', 'none'].includes(p.state) || typeof p.requiresAcceptance !== 'boolean') fail('service_unavailable', 503);
    integer(p.revision, 999999999);
    if (p.state === 'none' && (p.policy !== null || p.requiresAcceptance !== false) || p.state === 'ready' && p.policy === null) fail('service_unavailable', 503);
    if (p.policy !== null) {
      const policy = exact(p.policy, ['id', 'storeId', 'revision', 'title', 'body', 'productIds', 'requiresAcceptance', 'validUntil']);
      if (policy.storeId !== storeId || !Array.isArray(policy.productIds) || policy.productIds.length !== 1 ||
        policy.productIds[0] !== skuId || policy.revision !== `policy-v${p.revision}` ||
        policy.requiresAcceptance !== p.requiresAcceptance) fail('service_unavailable', 503);
      id(policy.id); text(policy.title);
      if (typeof policy.body !== 'string' || !policy.body.trim() || policy.body.length > 12000) fail('service_unavailable', 503);
      if (policy.validUntil !== null) timestamp(policy.validUntil);
    }
    return structuredClone(p);
  }
  private requestLines(raw: unknown): BulkRequestLine[] {
    const lines = array(raw, 100).map(value => {
      const r = exact(value, ['lineId', 'skuId', 'listingId', 'skuRevision', 'quantity']);
      const listingId = text(r.listingId, 72);
      if (!/^listing-[a-f0-9]{64}$/u.test(listingId)) fail();
      return {lineId: id(r.lineId), skuId: id(r.skuId), listingId,
        skuRevision: integer(r.skuRevision, 999999999, 1), quantity: integer(r.quantity, 1000000, 1)};
    }).sort((a, b) => compare(a.lineId, b.lineId));
    unique(lines.map(l => l.lineId)); unique(lines.map(l => l.listingId)); return lines;
  }
  private stored(raw: unknown): BulkAgreementRecord {
    const r = exact(raw, ['body', 'integrity']), body = obj(r.body);
    if (Buffer.byteLength(JSON.stringify(body), 'utf8') > 400000) {
      throw new WorkspaceProfileError('invalid_input', 'This Bulk request is too large. Request fewer products together.', 400);
    }
    exact(body, ['schemaVersion', 'realm', 'quoteId', 'storeId', 'storeCaseId', 'buyerUserId', 'supplierUserId',
      'revision', 'state', 'requestedAt', 'updatedAt', 'lines', 'offer', 'acceptance', ...(Object.hasOwn(body, 'storeName') ? ['storeName'] : [])]);
    if (Object.hasOwn(body, 'storeName')) bulkVariant(body.storeName);
    if (r.integrity !== integrityHash(body) || body.schemaVersion !== 1 || body.realm !== this.realm ||
      typeof body.state !== 'string' || !['requested', 'offered', 'accepted', 'withdrawn'].includes(body.state)) fail('invalid_state', 409);
    for (const key of ['quoteId', 'storeId', 'storeCaseId', 'buyerUserId', 'supplierUserId']) id(body[key]);
    integer(body.revision, 999999999, 1); timestamp(body.requestedAt); timestamp(body.updatedAt);
    if (String(body.updatedAt) < String(body.requestedAt) || String(body.updatedAt) > this.now().toISOString()) fail('invalid_state', 409);
    const lines = array(body.lines, 100).map(value => {
      const line = exact(value, ['lineId', 'skuId', 'listingId', 'skuRevision', 'quantity',
        'canonicalProductId', 'verifiedPackId', 'name', 'packLabel', 'supplierPolicy',
        ...(Object.hasOwn(obj(value), 'variant') ? ['variant'] : [])]);
      const request = this.requestLines([Object.fromEntries(['lineId', 'skuId', 'listingId', 'skuRevision', 'quantity'].map(k => [k, line[k]]))])[0]!;
      id(line.canonicalProductId); id(line.verifiedPackId); text(line.name); text(line.packLabel);
      this.policy(line.supplierPolicy, String(body.storeId), request.skuId);
      return {...request, canonicalProductId: String(line.canonicalProductId), verifiedPackId: String(line.verifiedPackId),
        name: String(line.name), packLabel: String(line.packLabel), supplierPolicy: line.supplierPolicy as Record<string, unknown> | null,
        ...(Object.hasOwn(line, 'variant') ? {variant: bulkVariant(line.variant)} : {})};
    });
    unique(lines.map(l => l.lineId)); unique(lines.map(l => l.listingId));
    if (body.offer !== null) {
      const offer = exact(body.offer, ['revision', 'offeredAt', 'validUntil', 'prices', 'merchandiseMinor', 'policyFingerprint']);
      integer(offer.revision, Number(body.revision), 2); timestamp(offer.offeredAt); timestamp(offer.validUntil);
      const prices = this.prices(offer.prices, lines, true);
      if (offer.merchandiseMinor !== prices.reduce((sum, p) => sum + p.merchandiseMinor, 0) ||
          offer.policyFingerprint !== integrityHash(lines.map(l => [l.lineId, l.supplierPolicy])) ||
          String(offer.offeredAt) < String(body.requestedAt) || String(offer.offeredAt) > String(body.updatedAt) ||
          String(offer.validUntil) <= String(offer.offeredAt)) fail('invalid_state', 409);
    }
    if (body.acceptance !== null) {
      const a = exact(body.acceptance, ['offerRevision', 'acceptedAt', 'agreementFingerprint']);
      const offer = obj(body.offer);
      if (body.state !== 'accepted' || a.offerRevision !== offer.revision || timestamp(a.acceptedAt) >= timestamp(offer.validUntil) ||
        a.agreementFingerprint !== integrityHash({lines, offer}) || a.acceptedAt !== body.updatedAt ||
        Number(offer.revision) + 1 !== body.revision || String(a.acceptedAt) < String(offer.offeredAt)) fail('invalid_state', 409);
    } else if (body.state === 'accepted') fail('invalid_state', 409);
    if (body.state === 'requested' && body.offer !== null || body.state === 'offered' && body.offer === null) fail('invalid_state', 409);
    if (body.state === 'requested' && (body.revision !== 1 || body.updatedAt !== body.requestedAt) ||
        body.state === 'offered' && (obj(body.offer).revision !== body.revision || obj(body.offer).offeredAt !== body.updatedAt) ||
        body.state === 'withdrawn' && (Number(body.revision) < 2 || body.acceptance !== null ||
          body.offer !== null && Number(obj(body.offer).revision) >= Number(body.revision))) fail('invalid_state', 409);
    return body as unknown as BulkAgreementRecord;
  }
  private prices(raw: unknown, lines: BulkQuotedLine[], persisted = false): BulkPrice[] {
    const prices = array(raw, 100).map(value => {
      // Persisted prices include the independently checked multiplication.
      const r = obj(value), keys = persisted
        ? ['lineId', 'unitPriceMinor', 'merchandiseMinor'] : ['lineId', 'unitPriceMinor'];
      exact(r, keys);
      const lineId = id(r.lineId), line = lines.find(l => l.lineId === lineId);
      if (!line) fail();
      const unitPriceMinor = integer(r.unitPriceMinor, 1000000000000, 1), amount = unitPriceMinor * line.quantity;
      if (!Number.isSafeInteger(amount) || amount > 1000000000000 ||
        persisted && r.merchandiseMinor !== amount) fail();
      return {lineId, unitPriceMinor, merchandiseMinor: amount};
    }).sort((a, b) => compare(a.lineId, b.lineId));
    unique(prices.map(p => p.lineId));
    if (prices.length !== lines.length || prices.reduce((sum, p) => sum + p.merchandiseMinor, 0) > 1000000000000) fail();
    return prices;
  }
  private async profile(tx: Transaction, storeId: string, actor?: string, caseId?: string, newSales = true) {
    const profiles = await tx.get(this.db.collection('workspaceProfiles').where('workspaceId', '==', storeId).limit(2));
    if (profiles.size !== 1) fail('not_found', 404);
    const doc = profiles.docs[0]!, p = obj(doc.data());
    requireStore(p, {caseId: caseId ?? doc.id, storeId, ownerUserId: actor ?? id(p.ownerUserId)}, newSales);
    return {caseId: doc.id, ownerUserId: id(p.ownerUserId)};
  }
  private async authorized(tx: Transaction, raw: unknown, actor: string, quoteId: string): Promise<BulkAgreementRecord> {
    let header: Record<string, unknown>;
    try { header = obj(obj(raw).body); } catch { return fail('not_found', 404); }
    if (header.quoteId !== quoteId || typeof header.buyerUserId !== 'string' || typeof header.supplierUserId !== 'string' ||
      actor !== header.buyerUserId && actor !== header.supplierUserId) fail('not_found', 404);
    if (actor === header.supplierUserId && actor !== header.buyerUserId) {
      let storeId: string, caseId: string;
      try { storeId = id(header.storeId); caseId = id(header.storeCaseId); } catch { return fail('not_found', 404); }
      await this.profile(tx, storeId, actor, caseId, false);
    }
    return this.stored(raw);
  }
  private async source(tx: Transaction, storeId: string, lines: BulkRequestLine[]) {
    const pages = await this.catalogue.bulkQuotationSnapshot(storeId, [...new Set(lines.map(l => l.skuId))], tx);
    const facts: BulkQuotedLine[] = [], deadlines: string[] = [];
    let storeName: string | undefined;
    for (const line of lines) {
      let matched: Record<string, unknown> | undefined;
      for (const value of pages) {
        const page = obj(value);
        if (page.state !== 'ready' || page.realm !== this.realm || page.storeId !== storeId) fail('service_unavailable', 503);
        const publicStore = obj(page.publicStore), name = bulkVariant(publicStore.name);
        if (publicStore.id !== storeId || storeName !== undefined && storeName !== name) fail('service_unavailable', 503);
        storeName = name;
        for (const item of array(page.items, 100)) {
          const row = obj(item);
          if (row.skuId === line.skuId) {
            if (matched) fail('service_unavailable', 503);
            matched = row;
          }
        }
      }
      if (!matched || matched.revision !== line.skuRevision) fail('conflict', 409);
      const listings = array(matched.listings, 3).map(obj), listing = listings.find(l => l.listingId === line.listingId);
      const term = array(matched.channels, 3).map(obj).find(c => c.kind === 'bulk');
      if (!listing || listing.channel !== 'bulk' || listing.realm !== this.realm || listing.storeId !== storeId ||
        listing.skuId !== line.skuId || listing.canonicalProductId !== matched.canonicalProductId ||
        listing.verifiedPackId !== matched.verifiedPackId || !term ||
        line.quantity < integer(term.minimumOrder, 1000000, 1) ||
        (line.quantity - integer(term.minimumOrder, 1000000, 1)) % integer(term.quantityStep, 1000000, 1) !== 0) fail('conflict', 409);
      deadlines.push(timestamp(term.validUntil));
      const content = obj(matched.content), pack = obj(matched.pack);
      const variant = content.variant === undefined || content.variant === '' ? undefined : bulkVariant(content.variant);
      const p = obj(matched.supplierPolicy), {observedAt, ...stablePolicy} = p;
      if (timestamp(observedAt) > this.now().toISOString()) fail('service_unavailable', 503);
      const supplierPolicy = this.policy(stablePolicy, storeId, line.skuId);
      if (supplierPolicy.policy !== null) {
        const policy = obj(supplierPolicy.policy);
        if (policy.validUntil !== null) deadlines.push(timestamp(policy.validUntil));
      }
      facts.push({...line, canonicalProductId: id(matched.canonicalProductId), verifiedPackId: id(matched.verifiedPackId),
        name: text(content.title), packLabel: text(pack.label), supplierPolicy, ...(variant === undefined ? {} : {variant})});
    }
    if (!storeName) fail('service_unavailable', 503);
    return {lines: facts, validUntil: deadlines.sort()[0]!, storeName};
  }
  private view(record: BulkAgreementRecord, actor: string) {
    const {buyerUserId, supplierUserId: _supplier, storeCaseId: _case, ...body} = structuredClone(record);
    return {...body, viewerRole: actor === buyerUserId ? 'buyer' : 'supplier',
      customerReference: `customer-${integrityHash([this.realm, record.storeId, buyerUserId]).slice(0, 32)}`,
      kind: 'supplier_merchandise_agreement', currency: 'INR', orderingAvailable: false, finalChargesDetermined: false, creditApproved: false};
  }
  async handleOperation(actor: string, action: BulkSupplierQuoteAction, body: Readonly<Record<string, unknown>>): Promise<object> {
    switch (action) {
      case 'request': return this.request(actor, body);
      case 'offer': return this.offer(actor, body);
      case 'accept': return this.accept(actor, body);
      case 'withdraw': return this.withdraw(actor, body);
      case 'read': return this.read(actor, body);
      case 'list_buyer': return this.listBuyer(actor, body);
      case 'list_store': return this.listStore(actor, body);
      case 'reconcile': return this.reconcile(actor, body);
      default: return fail();
    }
  }
  private acknowledged(raw: unknown, actor: string, quoteId: string, fingerprint: string, current: BulkAgreementRecord) {
    const p = exact(raw, ['actor', 'quoteId', 'fingerprint', 'record', 'integrity']);
    const {integrity, ...body} = p;
    if (p.actor !== actor || p.quoteId !== quoteId || p.fingerprint !== fingerprint || integrity !== integrityHash(body)) fail('conflict', 409);
    const original = this.stored(p.record);
    if (original.quoteId !== quoteId || original.buyerUserId !== current.buyerUserId ||
      original.supplierUserId !== current.supplierUserId || original.storeId !== current.storeId ||
      original.storeCaseId !== current.storeCaseId || original.requestedAt !== current.requestedAt ||
      original.revision > current.revision) fail('invalid_state', 409);
    return original;
  }
  async request(actor: string, raw: Readonly<Record<string, unknown>>): Promise<object> {
    actor = id(actor); const r = exact(structuredClone(raw), ['schemaVersion', 'requestId', 'storeId', 'lines']);
    if (r.schemaVersion !== 1) fail();
    const requestId = id(r.requestId), storeId = id(r.storeId), lines = this.requestLines(r.lines);
    const quoteId = `bulk-${integrityHash([this.realm, actor, requestId])}`;
    return this.command(actor, quoteId, requestId, r, async (tx, saved) => {
      if (saved) fail('conflict', 409);
      const profile = await this.profile(tx, storeId), source = await this.source(tx, storeId, lines), at = this.now().toISOString();
      if (at >= source.validUntil) fail('service_unavailable', 503);
      return {schemaVersion: 1, realm: this.realm, quoteId, storeId, storeCaseId: profile.caseId,
        buyerUserId: actor, supplierUserId: profile.ownerUserId, revision: 1, state: 'requested', requestedAt: at,
        updatedAt: at, storeName: source.storeName, lines: source.lines, offer: null, acceptance: null};
    }, true);
  }
  private async command(actor: string, quoteId: string, operationId: string, input: object,
    change: (tx: Transaction, saved: BulkAgreementRecord | null) => Promise<BulkAgreementRecord>, create = false) {
    const fingerprint = integrityHash(input), receipt = this.root().collection('bulkQuoteCommands').doc(integrityHash([actor, operationId]));
    return this.db.runTransaction(async tx => {
      const [doc, prior] = await tx.getAll(this.path(quoteId), receipt);
      const saved = doc!.exists ? await this.authorized(tx, doc!.data(), actor, quoteId) : null;
      if (!saved && !create) fail('not_found', 404);
      if (prior!.exists) {
        if (!saved) fail('invalid_state', 409);
        return this.view(this.acknowledged(prior!.data(), actor, quoteId, fingerprint, saved), actor);
      }
      const result = await change(tx, saved), stored = {body: result, integrity: integrityHash(result)};
      this.stored(stored); // Same strict contract on write/read/replay.
      const acknowledgement = {actor, quoteId, fingerprint, record: stored};
      if (Buffer.byteLength(JSON.stringify(stored), 'utf8') > 420000 ||
          Buffer.byteLength(JSON.stringify(acknowledgement), 'utf8') > 440000) fail('invalid_input', 400);
      tx.set(this.path(quoteId), stored);
      tx.create(receipt, {...acknowledgement, integrity: integrityHash(acknowledgement)});
      return this.view(result, actor);
    });
  }
  private transition(actor: string, raw: Readonly<Record<string, unknown>>, action: 'offer' | 'accept' | 'withdraw') {
    actor = id(actor); const r = exact(structuredClone(raw), ['schemaVersion', 'quoteId', 'operationId', 'expectedRevision',
      ...(action === 'offer' ? ['validUntil', 'prices'] : [])]);
    if (r.schemaVersion !== 1) fail();
    const quoteId = id(r.quoteId), operationId = id(r.operationId), expected = integer(r.expectedRevision, 999999998, 1);
    return this.command(actor, quoteId, operationId, {action, ...r}, async (tx, record) => {
      if (!record || record.revision !== expected || record.state === 'accepted' || record.state === 'withdrawn') fail('conflict', 409);
      if (action === 'offer' && actor !== record.supplierUserId || action === 'accept' && actor !== record.buyerUserId) fail('not_found', 404);
      const at = this.now().toISOString();
      if (at < record.updatedAt) fail('invalid_state', 409);
      const next: BulkAgreementRecord = {...structuredClone(record), revision: expected + 1, updatedAt: at};
      if (action === 'withdraw') { next.state = 'withdrawn'; return next; }
      await this.profile(tx, record.storeId, record.supplierUserId, record.storeCaseId);
      const source = await this.source(tx, record.storeId, this.requestLines(record.lines.map(l => ({lineId: l.lineId,
        skuId: l.skuId, listingId: l.listingId, skuRevision: l.skuRevision, quantity: l.quantity}))));
      if (source.lines.some((line, index) => line.canonicalProductId !== record.lines[index]?.canonicalProductId ||
        line.verifiedPackId !== record.lines[index]?.verifiedPackId)) fail('conflict', 409);
      const finalAt = this.now().toISOString();
      if (finalAt < at || finalAt >= source.validUntil) fail('service_unavailable', 503);
      next.updatedAt = finalAt;
      if (action === 'offer') {
        const validUntil = timestamp(r.validUntil); if (validUntil <= finalAt) fail('conflict', 409);
        const prices = this.prices(r.prices, record.lines);
        next.lines = source.lines; next.storeName = source.storeName; next.state = 'offered';
        next.offer = {revision: next.revision, offeredAt: finalAt, validUntil, prices,
          merchandiseMinor: prices.reduce((sum, p) => sum + p.merchandiseMinor, 0),
          policyFingerprint: integrityHash(next.lines.map(l => [l.lineId, l.supplierPolicy]))};
      } else {
        if (record.state !== 'offered' || !record.offer || record.offer.revision !== expected ||
          finalAt >= record.offer.validUntil || record.offer.policyFingerprint !== integrityHash(source.lines.map(l => [l.lineId, l.supplierPolicy]))) fail('conflict', 409);
        next.state = 'accepted'; next.acceptance = {offerRevision: record.offer.revision, acceptedAt: finalAt,
          agreementFingerprint: integrityHash({lines: record.lines, offer: record.offer})};
      }
      return next;
    });
  }
  offer(actor: string, body: Readonly<Record<string, unknown>>) {return this.transition(actor, body, 'offer');}
  accept(actor: string, body: Readonly<Record<string, unknown>>) {return this.transition(actor, body, 'accept');}
  withdraw(actor: string, body: Readonly<Record<string, unknown>>) {return this.transition(actor, body, 'withdraw');}
  async read(actor: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    actor = id(actor); const r = exact(body, ['quoteId']), quoteId = id(r.quoteId);
    return this.db.runTransaction(async tx => {
      const doc = await tx.get(this.path(quoteId)); if (!doc.exists) fail('not_found', 404);
      const record = await this.authorized(tx, doc.data(), actor, quoteId);
      return this.view(record, actor);
    });
  }
  /** Original acknowledgement only. No source refresh, mutation, retry or
   * inferred rejection when a receipt has not been observed. Current head is
   * returned separately so an old receipt cannot overwrite newer visible state. */
  async reconcile(actor: string, raw: Readonly<Record<string, unknown>>): Promise<object> {
    actor = id(actor);
    const r = exact(structuredClone(raw), ['schemaVersion', 'originalOperation', 'original']);
    if (r.schemaVersion !== 1 || typeof r.originalOperation !== 'string' ||
      !['request', 'offer', 'accept', 'withdraw'].includes(r.originalOperation)) fail();
    const action = r.originalOperation, original = exact(r.original, action === 'request'
      ? ['schemaVersion', 'requestId', 'storeId', 'lines']
      : ['schemaVersion', 'quoteId', 'operationId', 'expectedRevision', ...(action === 'offer' ? ['validUntil', 'prices'] : [])]);
    if (original.schemaVersion !== 1) fail();
    let quoteId: string, operationId: string;
    if (action === 'request') {
      operationId = id(original.requestId); id(original.storeId); this.requestLines(original.lines);
      quoteId = `bulk-${integrityHash([this.realm, actor, operationId])}`;
    } else {
      quoteId = id(original.quoteId); operationId = id(original.operationId); integer(original.expectedRevision, 999999998, 1);
      if (action === 'offer') {
        timestamp(original.validUntil);
        const prices = array(original.prices, 100).map(p => exact(p, ['lineId', 'unitPriceMinor']));
        for (const p of prices) { id(p.lineId); integer(p.unitPriceMinor, 1000000000000, 1); }
        unique(prices.map(p => String(p.lineId)));
      }
    }
    const fingerprint = integrityHash(action === 'request' ? original : {action, ...original});
    return this.db.runTransaction(async tx => {
      const [head, receipt] = await tx.getAll(this.path(quoteId),
        this.root().collection('bulkQuoteCommands').doc(integrityHash([actor, operationId])));
      const saved = head!.exists ? await this.authorized(tx, head!.data(), actor, quoteId) : null;
      if (!saved && action !== 'request') fail('not_found', 404);
      if (saved && (action === 'request' || action === 'accept') && actor !== saved.buyerUserId ||
          saved && action === 'offer' && actor !== saved.supplierUserId) fail('not_found', 404);
      const base = {schemaVersion: 1, realm: this.realm, authNamespace: 'firebase-default', originalOperation: action,
        quoteId, operationId, requestFingerprint: fingerprint, currentHead: saved ? this.view(saved, actor) : null};
      if (receipt!.exists) {
        if (!saved) fail('invalid_state', 409);
        return {...base, state: 'recorded', agreement: this.view(this.acknowledged(receipt!.data(), actor, quoteId, fingerprint, saved), actor), proof: null};
      }
      const superseded = saved && action !== 'request' && (saved.revision > Number(original.expectedRevision) ||
        saved.state === 'accepted' || saved.state === 'withdrawn');
      return {...base, state: superseded ? 'superseded' : 'not_found', agreement: null,
        proof: superseded ? {expectedRevision: original.expectedRevision, currentRevision: saved.revision, currentState: saved.state} : null};
    });
  }
  private async list(actor: string, raw: Readonly<Record<string, unknown>>, supplier: boolean): Promise<object> {
    actor = id(actor); const r = exact(raw, supplier ? ['storeId', 'limit', 'cursor'] : ['limit', 'cursor']);
    const storeId = supplier ? id(r.storeId) : null, limit = integer(r.limit, 5, 1);
    const scope = integrityHash([this.realm, 'firebase-default', 'bulk-quotation-inbox', actor, supplier ? 'supplier' : 'buyer', storeId, limit]);
    let after: string | undefined;
    if (r.cursor !== null) {
      try {
        const token = text(r.cursor, 512), c = exact(JSON.parse(Buffer.from(token, 'base64url').toString('utf8')), ['version', 'scope', 'after']);
        if (c.version !== 1 || c.scope !== scope || typeof c.after !== 'string' || !/^bulk-[a-f0-9]{64}$/u.test(c.after) ||
          Buffer.from(JSON.stringify(c)).toString('base64url') !== token) fail();
        after = c.after;
      } catch { fail(); }
    }
    return this.db.runTransaction(async tx => {
      if (supplier) await this.profile(tx, storeId!, actor, undefined, false);
      if (after) {
        const position = await tx.get(this.path(after));
        if (!position.exists) fail('not_found', 404);
        const record = await this.authorized(tx, position.data(), actor, after);
        if (supplier ? record.storeId !== storeId || record.supplierUserId !== actor : record.buyerUserId !== actor) fail('not_found', 404);
      }
      let query = this.root().collection('bulkQuoteRequests')
        .where(supplier ? 'body.supplierUserId' : 'body.buyerUserId', '==', actor);
      if (supplier) query = query.where('body.storeId', '==', storeId);
      query = query.orderBy(FieldPath.documentId()).limit(limit + 1);
      if (after) query = query.startAfter(after);
      const docs = await tx.get(query), visible = docs.docs.slice(0, limit), summaries = [];
      for (const doc of visible) {
        const record = await this.authorized(tx, doc.data(), actor, doc.id);
        if (supplier && (record.storeId !== storeId || record.supplierUserId !== actor) ||
          !supplier && record.buyerUserId !== actor) fail('not_found', 404);
        const view = this.view(record, actor);
        summaries.push({quoteId: record.quoteId, storeId: record.storeId, revision: record.revision, state: record.state,
          ...(record.storeName === undefined ? {} : {storeName: record.storeName}),
          requestedAt: record.requestedAt, updatedAt: record.updatedAt, productCount: record.lines.length,
          offerMerchandiseMinor: record.offer?.merchandiseMinor ?? null, offerValidUntil: record.offer?.validUntil ?? null,
          customerReference: view.customerReference});
      }
      const last = docs.size > limit ? visible.at(-1)?.id : undefined;
      return {schemaVersion: 1, realm: this.realm, authNamespace: 'firebase-default', viewerRole: supplier ? 'supplier' : 'buyer',
        storeId, currency: 'INR', paging: 'refreshable_not_snapshot', coverage: 'saved_private_requests', summaries,
        nextCursor: last ? Buffer.from(JSON.stringify({version: 1, scope, after: last})).toString('base64url') : null};
    });
  }
  listBuyer(actor: string, body: Readonly<Record<string, unknown>>) {return this.list(actor, body, false);}
  listStore(actor: string, body: Readonly<Record<string, unknown>>) {return this.list(actor, body, true);}
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
  private productFeedbackTargets(a: PurchaseAggregate, o: StoredOrder, saved: StoredOrderCompletion): StoredProductFeedbackTarget[] {
    if (o.factsVersion < 6) return [];
    const completion = this.completionAck(saved).completion;
    return o.original.lines.flatMap(line => {
      if (!line.publicListing) return [];
      const target: ProductFeedbackTarget = {id: `feedback-${digest([1, this.realm, "firebase-default", a.buyerUserId,
        a.purchaseId, o.storeId, o.orderId, line.lineId, o.originalFingerprint, a.sourceRevision, line.name,
        line.publicListing.listingId, line.publicListing.skuId, line.publicListing.canonicalProductId,
        line.publicListing.verifiedPackId, line.publicListing.channel, completion.id, completion.revision, completion.occurredAt])}`,
      kind: "product", purchaseId: a.purchaseId, storeId: o.storeId, orderId: o.orderId,
      orderLineId: line.lineId, productId: line.publicListing.listingId, productLabel: line.name,
      originalFingerprint: o.originalFingerprint, sourceRevision: a.sourceRevision,
      purchasedListing: line.publicListing, completedAt: completion.occurredAt,
      completionId: completion.id, completionRevision: completion.revision};
      const body = {schemaVersion: 1 as const, realm: this.realm, authNamespace: "firebase-default" as const,
        buyerUserId: a.buyerUserId, target};
      return [{...body, integrity: integrityHash(body)}];
    });
  }
  private async indexProductFeedback(tx: Transaction, a: PurchaseAggregate, o: StoredOrder, saved: StoredOrderCompletion): Promise<void> {
    const targets = this.productFeedbackTargets(a, o, saved);
    if (!targets.length) return;
    // At most100 lines in one Store order: <=100 target writes plus3 completion
    // receipts. Read all candidates before writing, including accepted replay repair.
    const paths = targets.map(t => this.root().collection("productFeedbackTargets").doc(t.target.id));
    const docs = await tx.getAll(...paths);
    for (const [i, doc] of docs.entries()) {
      if (doc.exists && integrityHash(doc.data()) !== integrityHash(targets[i])) fail("invalid_state", 409);
    }
    for (const [i, doc] of docs.entries()) if (!doc.exists) tx.create(paths[i]!, targets[i]!);
  }
  async listBuyerProductFeedbackTargets(actor: string, body: Readonly<Record<string, unknown>>): Promise<ProductFeedbackTargetPage> {
    id(actor); exact(body, ["limit", "cursor"]);
    const limit = integer(body.limit, 5, 1), scope = digest([1, this.realm, "firebase-default", actor, "product-feedback"]);
    let after: string | undefined;
    if (body.cursor !== null) {
      try {
        const token = text(body.cursor, 512);
        const parsed = exact(JSON.parse(Buffer.from(token, "base64url").toString("utf8")), ["version", "scope", "after"]);
        if (parsed.version !== 1 || parsed.scope !== scope || !/^feedback-[a-f0-9]{64}$/u.test(String(parsed.after)) ||
            typeof parsed.after !== "string" || Buffer.from(JSON.stringify(parsed)).toString("base64url") !== token) fail();
        after = parsed.after;
      } catch {fail();}
    }
    return this.db.runTransaction(async tx => {
      let query = this.root().collection("productFeedbackTargets").where("buyerUserId", "==", actor)
        .orderBy(FieldPath.documentId()).limit(limit);
      if (after) query = query.startAfter(after);
      const docs = await tx.get(query), targets: ProductFeedbackTarget[] = [];
      for (const doc of docs.docs) {
        const raw = exact(doc.data(), ["schemaVersion", "realm", "authNamespace", "buyerUserId", "target", "integrity"]);
        if (raw.schemaVersion !== 1 || raw.realm !== this.realm || raw.authNamespace !== "firebase-default" || raw.buyerUserId !== actor) {
          fail("invalid_state", 409);
        }
        const target = obj(raw.target);
        const {aggregate, order} = await this.original(tx, operationalScope(target));
        if (aggregate.buyerUserId !== actor) fail("not_found", 404);
        const terminal = await tx.get(this.completionPath({purchaseId: aggregate.purchaseId, storeId: order.storeId, orderId: order.orderId}));
        if (!terminal.exists) fail("invalid_state", 409);
        const saved = this.completionStored(terminal.data()); this.completionBound(saved, aggregate, order);
        const expected = this.productFeedbackTargets(aggregate, order, saved).find(t => t.target.id === doc.id);
        if (!expected || integrityHash(raw) !== integrityHash(expected)) fail("invalid_state", 409);
        targets.push(expected.target);
      }
      const last = docs.size === limit ? docs.docs.at(-1)?.id : undefined;
      return {schemaVersion: 1, realm: this.realm, authNamespace: "firebase-default", viewerRole: "buyer", viewerUserId: actor,
        coverage: "indexed_recorded_completions", targets,
        nextCursor: last ? Buffer.from(JSON.stringify({version: 1, scope, after: last})).toString("base64url") : null};
    });
  }
  async readBuyerProductFeedbackTarget(actor: string, body: Readonly<Record<string, unknown>>) {
    id(actor); exact(body, ["purchaseId", "storeId", "orderId", "originalFingerprint", "sourceRevision", "orderLineId"]);
    const scope = operationalScope(body), lineId = id(body.orderLineId);
    const fingerprint = text(body.originalFingerprint, 64), revision = id(body.sourceRevision);
    if (!/^[a-f0-9]{64}$/u.test(fingerprint)) fail();
    return this.db.runTransaction(async tx => {
      const {aggregate, order} = await this.original(tx, scope);
      if (aggregate.buyerUserId !== actor) fail("not_found", 404);
      if (aggregate.sourceRevision !== revision || order.originalFingerprint !== fingerprint) fail("not_found", 404);
      const terminal = await tx.get(this.completionPath(scope));
      if (!terminal.exists) fail("not_found", 404);
      const saved = this.completionStored(terminal.data()); this.completionBound(saved, aggregate, order);
      const expected = this.productFeedbackTargets(aggregate, order, saved).find(t => t.target.orderLineId === lineId);
      if (!expected) fail("not_found", 404);
      const indexed = await tx.get(this.root().collection("productFeedbackTargets").doc(expected.target.id));
      // A read never repairs a missing index or manufactures completion eligibility.
      if (!indexed.exists) fail("service_unavailable", 503);
      if (integrityHash(indexed.data()) !== integrityHash(expected)) fail("invalid_state", 409);
      return {schemaVersion: 1, realm: this.realm, authNamespace: "firebase-default", viewerRole: "buyer",
        viewerUserId: actor, target: expected.target};
    });
  }
  private async feedbackTarget(tx: Transaction, targetId: string) {
    if (!/^feedback-[a-f0-9]{64}$/u.test(targetId)) fail();
    const doc = await tx.get(this.root().collection("productFeedbackTargets").doc(targetId));
    if (!doc.exists) fail("not_found", 404);
    const raw = exact(doc.data(), ["schemaVersion", "realm", "authNamespace", "buyerUserId", "target", "integrity"]);
    const {aggregate, order} = await this.original(tx, operationalScope(obj(raw.target)));
    const terminal = await tx.get(this.completionPath({purchaseId: aggregate.purchaseId, storeId: order.storeId, orderId: order.orderId}));
    if (!terminal.exists) fail("invalid_state", 409);
    const saved = this.completionStored(terminal.data()); this.completionBound(saved, aggregate, order);
    const expected = this.productFeedbackTargets(aggregate, order, saved).find(t => t.target.id === targetId);
    if (!expected || integrityHash(raw) !== integrityHash(expected)) fail("invalid_state", 409);
    return {target: expected.target, aggregate, order};
  }
  private starsStored(raw: unknown, target: ProductFeedbackTarget, buyerUserId: string): StoredProductStars {
    try {
      const r = exact(raw, ["schemaVersion", "realm", "authNamespace", "buyerUserId", "storeId", "rating", "integrity"]);
      const rating = exact(r.rating, ["target", "stars", "revision", "updatedAt"]), {integrity, ...body} = r;
      if (r.schemaVersion !== 1 || r.realm !== this.realm || r.authNamespace !== "firebase-default" ||
          r.buyerUserId !== buyerUserId || r.storeId !== target.storeId || integrity !== integrityHash(body) ||
          integrityHash(rating.target) !== integrityHash(target) || timestamp(rating.updatedAt) < target.completedAt ||
          timestamp(rating.updatedAt) > this.now().toISOString()) fail();
      integer(rating.stars, 5, 1); integer(rating.revision, Number.MAX_SAFE_INTEGER, 1);
      return r as unknown as StoredProductStars;
    } catch {return fail("invalid_state", 409);}
  }
  async readBuyerProductStars(actor: string, body: Readonly<Record<string, unknown>>): Promise<ProductStars | null> {
    id(actor); exact(body, ["targetId"]); const targetId = id(body.targetId);
    return this.db.runTransaction(async tx => {
      const {target, aggregate} = await this.feedbackTarget(tx, targetId);
      if (aggregate.buyerUserId !== actor) fail("not_found", 404);
      const doc = await tx.get(this.root().collection("productStarRatings").doc(targetId));
      return doc.exists ? this.starsStored(doc.data(), target, actor).rating : null;
    });
  }
  async submitProductStars(actor: string, body: Readonly<Record<string, unknown>>, reconcile = false): Promise<ProductStarsResult> {
    id(actor); const r = exact(body, ["targetId", "expectedRevision", "operationId", "stars"]);
    const targetId = id(r.targetId), operationId = id(r.operationId), stars = integer(r.stars, 5, 1);
    const expectedRevision = integer(r.expectedRevision, Number.MAX_SAFE_INTEGER - 1);
    const commandFingerprint = integrityHash({realm: this.realm, actor, targetId, operationId, expectedRevision, stars});
    const receiptPath = this.root().collection("productStarReceipts").doc(digest([actor, targetId, operationId]));
    return this.db.runTransaction(async tx => {
      const {target, aggregate} = await this.feedbackTarget(tx, targetId);
      if (aggregate.buyerUserId !== actor) fail("not_found", 404);
      const receipt = await tx.get(receiptPath);
      if (receipt.exists) {
        const saved = exact(receipt.data(), ["schemaVersion", "realm", "authNamespace", "buyerUserId", "commandFingerprint", "result", "integrity"]);
        const {integrity, ...receiptBody} = saved;
        if (saved.schemaVersion !== 1 || saved.realm !== this.realm || saved.authNamespace !== "firebase-default" ||
            saved.buyerUserId !== actor || integrity !== integrityHash(receiptBody)) fail("invalid_state", 409);
        if (saved.commandFingerprint !== commandFingerprint) fail("conflict", 409);
        const result = exact(saved.result, ["schemaVersion", "realm", "authNamespace", "viewerRole", "viewerUserId", "operationId", "state", "rating"]);
        const rating = obj(result.rating);
        if (result.schemaVersion !== 1 || result.realm !== this.realm || result.authNamespace !== "firebase-default" ||
            result.viewerRole !== "buyer" || result.viewerUserId !== actor || result.operationId !== operationId ||
            result.state !== "saved" || rating.stars !== stars || rating.revision !== expectedRevision + 1) fail("invalid_state", 409);
        const ratingBody = {schemaVersion: 1 as const, realm: this.realm, authNamespace: "firebase-default" as const,
          buyerUserId: actor, storeId: target.storeId, rating};
        this.starsStored({...ratingBody, integrity: integrityHash(ratingBody)}, target, actor);
        return result as unknown as ProductStarsResult;
      }
      const base = {schemaVersion: 1 as const, realm: this.realm, authNamespace: "firebase-default" as const,
        viewerRole: "buyer" as const, viewerUserId: actor, operationId};
      const ratingPath = this.root().collection("productStarRatings").doc(targetId), existing = await tx.get(ratingPath);
      const previous = existing.exists ? this.starsStored(existing.data(), target, actor).rating : null;
      // Same transaction as the absent original receipt. Monotonic revisions
      // prove this stale CAS can never commit; no replacement attempt is sent.
      if (reconcile) return previous && previous.revision > expectedRevision
        ? {...base, state: "superseded", rating: null, targetId, observedRevision: previous.revision}
        : {...base, state: "not_recorded", rating: null};
      if ((previous?.revision ?? 0) !== expectedRevision) fail("conflict", 409);
      const rating: ProductStars = {target, stars, revision: expectedRevision + 1, updatedAt: this.now().toISOString()};
      const ratingBody = {schemaVersion: 1 as const, realm: this.realm, authNamespace: "firebase-default" as const,
        buyerUserId: actor, storeId: target.storeId, rating};
      this.starsStored({...ratingBody, integrity: integrityHash(ratingBody)}, target, actor);
      const result: ProductStarsResult = {...base, state: "saved", rating};
      const receiptBody = {schemaVersion: 1 as const, realm: this.realm, authNamespace: "firebase-default" as const,
        buyerUserId: actor, commandFingerprint, result};
      tx.set(ratingPath, {...ratingBody, integrity: integrityHash(ratingBody)});
      tx.create(receiptPath, {...receiptBody, integrity: integrityHash(receiptBody)});
      return result;
    });
  }
  async listStoreProductStars(actor: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    id(actor); exact(body, ["storeId", "limit", "cursor"]);
    const storeId = id(body.storeId), limit = integer(body.limit, 5, 1);
    const scope = digest([1, this.realm, "firebase-default", actor, storeId, "product-stars"]);
    let after: string | undefined;
    if (body.cursor !== null) {
      try {
        const token = text(body.cursor, 512), parsed = exact(JSON.parse(Buffer.from(token, "base64url").toString("utf8")), ["version", "scope", "after"]);
        if (parsed.version !== 1 || parsed.scope !== scope || typeof parsed.after !== "string" ||
            !/^feedback-[a-f0-9]{64}$/u.test(parsed.after) || Buffer.from(JSON.stringify(parsed)).toString("base64url") !== token) fail();
        after = parsed.after;
      } catch {fail();}
    }
    return this.db.runTransaction(async tx => {
      const profiles = await tx.get(this.db.collection("workspaceProfiles").where("workspaceId", "==", storeId).limit(2));
      if (profiles.size !== 1) fail("not_found", 404);
      const profile = profiles.docs[0]!;
      requireStore(profile.data(), {caseId: profile.id, storeId, ownerUserId: actor}, false);
      let query = this.root().collection("productStarRatings").where("storeId", "==", storeId).orderBy(FieldPath.documentId()).limit(limit);
      if (after) query = query.startAfter(after);
      const docs = await tx.get(query), ratings: ProductStars[] = [];
      for (const doc of docs.docs) {
        const {target, aggregate, order} = await this.feedbackTarget(tx, doc.id);
        if (target.storeId !== storeId) fail("invalid_state", 409);
        await this.seller(tx, order, actor);
        ratings.push(this.starsStored(doc.data(), target, aggregate.buyerUserId).rating);
      }
      const last = docs.size === limit ? docs.docs.at(-1)?.id : undefined;
      return {schemaVersion: 1, realm: this.realm, authNamespace: "firebase-default", viewerRole: "seller", viewerUserId: actor,
        storeId, coverage: "recorded_private_product_stars", ratings,
        nextCursor: last ? Buffer.from(JSON.stringify({version: 1, scope, after: last})).toString("base64url") : null};
    });
  }
  /** Internal trusted-source materializer only. There is deliberately no HTTP completion write operation. */
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
      await this.indexProductFeedback(tx, aggregate, order, saved);
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
      await this.indexProductFeedback(tx, aggregate, order, saved);
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
      if (o.original.fulfilmentContext != null && proof.fulfilment !== o.original.fulfilmentContext.method) fail();
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
      if (proof.sourceRevision !== aggregate.sourceRevision || proof.originalFingerprint !== order.originalFingerprint ||
          order.original.fulfilmentContext != null && proof.fulfilment !== order.original.fulfilmentContext.method) {
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
function supplierTaxSnapshot(value: unknown): OriginalSupplierTaxSnapshot | null {
  if (value === null) return null;
  const s = exact(value, ['schemaVersion', 'termsRevision', 'observedAt', 'expiresAt', 'declaration']);
  if (s.schemaVersion !== 1) fail();
  const observedAt = timestamp(s.observedAt), expiresAt = s.expiresAt === null ? null : timestamp(s.expiresAt);
  if (expiresAt !== null && expiresAt <= observedAt) fail();
  const raw = obj(s.declaration);
  if (raw.version !== 1 && raw.version !== 2) fail();
  const d = exact(raw, ['version', raw.version === 2 ? 'rateBasisPoints' : 'amountMinor', 'basis']);
  if (d.basis !== 'included' && d.basis !== 'additional') fail();
  const declaration: OriginalSupplierTaxSnapshot['declaration'] = d.version === 2
    ? {version: 2, rateBasisPoints: integer(d.rateBasisPoints, 10000), basis: d.basis}
    : {version: 1, amountMinor: integer(d.amountMinor), basis: d.basis};
  return {schemaVersion: 1, termsRevision: id(s.termsRevision), observedAt, expiresAt, declaration};
}
function commodityPriceSnapshot(value: unknown, line: PlacementLine): OriginalCommodityPriceSnapshot | null {
  if (value === null) return null;
  const r = exact(value, ['schemaVersion', 'termsRevision', 'confirmationRevision', 'confirmedAt', 'validUntil',
    'frequent', 'agreedAt', 'priceMinor', 'minimumPacks', 'incrementPacks', 'tiers']);
  const confirmationRevision = integer(r.confirmationRevision, 1000000000, 1), termsRevision = id(r.termsRevision);
  const confirmedAt = timestamp(r.confirmedAt), validUntil = timestamp(r.validUntil), agreedAt = timestamp(r.agreedAt);
  if (r.schemaVersion !== 1 || typeof r.frequent !== 'boolean' ||
      !new RegExp(`^commodity-${confirmationRevision}-[A-F0-9]{16}$`, 'u').test(termsRevision) ||
      termsRevision !== line.offerRevision || !line.publicListing || !['wholesale', 'bulk'].includes(line.publicListing.channel) ||
      line.quantityUnit !== 'pack' || line.quantityMilli % 1000 !== 0 ||
      confirmedAt > agreedAt || agreedAt >= validUntil || !Array.isArray(r.tiers) || r.tiers.length > 20) fail();
  const priceMinor = integer(r.priceMinor, 99999999900, 1), minimumPacks = integer(r.minimumPacks, 100000000, 1),
    incrementPacks = integer(r.incrementPacks, 100000000, 1), quantity = line.quantityMilli / 1000;
  if (quantity < minimumPacks || (quantity - minimumPacks) % incrementPacks !== 0) fail();
  let lastMinimum = 0, lastPrice = priceMinor, selectedPrice = priceMinor;
  const tiers = r.tiers.map((raw, index) => {
    const t = exact(raw, ['minimumPacks', 'unitPriceMinor']), minimum = integer(t.minimumPacks, 999999, 1),
      amount = integer(t.unitPriceMinor, 99999999900, 1);
    if (minimum <= lastMinimum || (minimum - minimumPacks) % incrementPacks !== 0 || minimum < minimumPacks ||
        amount > lastPrice || index === 0 && (minimum !== minimumPacks || amount !== priceMinor)) fail();
    lastMinimum = minimum; lastPrice = amount;
    if (minimum <= quantity) selectedPrice = amount;
    return {minimumPacks: minimum, unitPriceMinor: amount};
  });
  if (selectedPrice !== line.unitPriceMinor) fail();
  return {schemaVersion: 1, termsRevision, confirmationRevision, confirmedAt, validUntil, frequent: r.frequent,
    agreedAt, priceMinor, minimumPacks, incrementPacks, tiers};
}
function line(v: unknown, withVariant = false, scheduledScope?: {realm: Realm; storeId: string}, withPublicListing = false,
  withSupplierTax = false, withCommodityPrice = false): PlacementLine {
  const r = exact(v, [...lineKeys, ...(withVariant ? ["variant"] : []), ...(scheduledScope ? ["scheduledFulfilment"] : []),
    ...(withPublicListing ? ["publicListing"] : []), ...(withSupplierTax ? ['supplierTaxSnapshot'] : []),
    ...(withCommodityPrice ? ['commodityPriceSnapshot'] : [])]);
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
  if (withSupplierTax) {
    result.supplierTaxSnapshot = supplierTaxSnapshot(r.supplierTaxSnapshot);
    if (result.supplierTaxSnapshot?.declaration.version === 1 && result.quantityUnit !== 'pack') fail();
  }
  if (withCommodityPrice) result.commodityPriceSnapshot = commodityPriceSnapshot(r.commodityPriceSnapshot, result);
  if (withCommodityPrice && result.commodityPriceSnapshot === null && result.publicListing?.channel === 'wholesale' &&
      /^commodity-[1-9][0-9]*-[A-F0-9]{16}$/u.test(result.offerRevision)) fail();
  // Contract: gross unit price per quantityUnit; quantity in thousandths;
  // gross line rounded half-up to paise. Discounts are explicit order totals.
  // This validates supplied facts, never derives a price/discount/eligibility.
  if ((BigInt(result.unitPriceMinor) * BigInt(result.quantityMilli) + 500n) / 1000n !==
      BigInt(result.lineTotalMinor)) fail();
  return result;
}
function fulfilmentContext(value: unknown, lines: readonly {lineId: string}[], hasScheduled = false): OriginalFulfilmentContext | null {
  if (value === null) return null;
  const r = exact(value, ["schemaVersion", "method", "recipient", "address", "instructions"]);
  if (r.schemaVersion !== 1 || r.method !== "delivery" && r.method !== "collection" ||
      r.method === "collection" && (r.address !== null || hasScheduled)) fail();
  const part = (v: unknown, max: number): string => {
    if (typeof v !== "string" || v !== v.trim() || v.length > max || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(v)) fail();
    return v;
  };
  let recipient: OriginalFulfilmentContext["recipient"] = null;
  if (r.recipient !== null) {
    const p = exact(r.recipient, ["name", "phone"]);
    const name = p.name === "" ? "" : text(p.name, 240), phone = p.phone === "" ? "" : text(p.phone, 30);
    if (!name && !phone || phone && (!/^\+?[0-9][0-9 ()-]*$/u.test(phone) ||
        phone.replace(/[^0-9]/gu, "").length < 7 || phone.replace(/[^0-9]/gu, "").length > 15)) fail();
    recipient = {name, phone};
  }
  let address: OriginalFulfilmentContext["address"] = null;
  if (r.address !== null) {
    const a = exact(r.address, ["line", "area", "pinCode", "landmark"]);
    address = {line: part(a.line, 1000), area: part(a.area, 240), pinCode: part(a.pinCode, 6), landmark: part(a.landmark, 240)};
    if (!Object.values(address).some(v => v.length) || address.pinCode !== "" && !/^[1-9][0-9]{5}$/u.test(address.pinCode)) fail();
  }
  if (!Array.isArray(r.instructions) || r.instructions.length > lines.length) fail();
  const instructions = r.instructions.map(value => {
    const i = exact(value, ["lineId", "text"]), lineId = id(i.lineId), note = part(i.text, 1000);
    if (!note || !lines.some(l => l.lineId === lineId)) fail();
    return {lineId, text: note};
  }).sort((a,b) => compare(a.lineId, b.lineId));
  unique(instructions.map(i => i.lineId));
  return {schemaVersion: 1, method: r.method, recipient, address, instructions};
}
function supplierQuote(value: unknown, realm: Realm,
  lines: readonly {lineId: string; lineTotalMinor: number; publicListing?: OriginalPublicListing | null;
    commodityPriceSnapshot?: OriginalCommodityPriceSnapshot | null}[], withCommodityPrice = false): OriginalSupplierQuote | null {
  const bulk = lines.filter(l => l.publicListing?.channel === 'bulk' && !(withCommodityPrice && l.commodityPriceSnapshot != null));
  if (value === null) { if (bulk.length) fail(); return null; }
  const r = exact(value, ['schemaVersion', 'realm', 'quoteId', 'acceptedRevision', 'agreementFingerprint',
    'offerRevision', 'acceptedAt', 'validUntil', 'merchandiseMinor', 'lines']);
  const quoteId = id(r.quoteId), acceptedRevision = integer(r.acceptedRevision, 999999999, 3),
    offerRevision = integer(r.offerRevision, 999999998, 2), acceptedAt = timestamp(r.acceptedAt), validUntil = timestamp(r.validUntil);
  if (r.schemaVersion !== 1 || r.realm !== realm || !/^bulk-[a-f0-9]{64}$/u.test(quoteId) ||
      typeof r.agreementFingerprint !== 'string' || !/^[a-f0-9]{64}$/u.test(r.agreementFingerprint) ||
      acceptedRevision !== offerRevision + 1 || acceptedAt >= validUntil) fail();
  const bindings = array(r.lines, 100).map(raw => {
    const b = exact(raw, ['lineId', 'quoteLineId']); return {lineId: id(b.lineId), quoteLineId: id(b.quoteLineId)};
  }).sort((a,b) => compare(a.lineId, b.lineId));
  unique(bindings.map(b => b.lineId)); unique(bindings.map(b => b.quoteLineId));
  if (bindings.length !== bulk.length || bindings.some(b => !bulk.some(l => l.lineId === b.lineId))) fail();
  const merchandiseMinor = integer(r.merchandiseMinor, 1000000000000, 1);
  if (bulk.reduce((sum,l) => sum + l.lineTotalMinor, 0) !== merchandiseMinor) fail();
  return {schemaVersion: 1, realm, quoteId, acceptedRevision, agreementFingerprint: r.agreementFingerprint,
    offerRevision, acceptedAt, validUntil, merchandiseMinor, lines: bindings};
}
export function normalizePlacement(value: unknown, realm: Realm): TrustedPlacementReceipt {
  const hasCouponContext = Object.hasOwn(obj(value), "couponUseContext");
  const r = exact(value, ["schemaVersion", "realm", "authNamespace", "finalPlacement", "issuer",
    "receiptId", "revision", "buyerUserId", "stores", ...(hasCouponContext ? ["couponUseContext"] : [])]);
  if ((r.schemaVersion !== 1 && r.schemaVersion !== 2 && r.schemaVersion !== 3 && r.schemaVersion !== 4 && r.schemaVersion !== 5 && r.schemaVersion !== 6 && r.schemaVersion !== 7 && r.schemaVersion !== 8 && r.schemaVersion !== 9) || r.realm !== realm || r.authNamespace !== "firebase-default" ||
      r.finalPlacement !== true || !["evaluation", "production"].includes(realm)) fail();
  const stores = array(r.stores, 10).map(raw => {
    const s = exact(raw, ["storeId", "caseId", "ownerUserId", "lines", "totals",
      ...(r.schemaVersion !== 1 ? ["benefitAttribution"] : []), ...((r.schemaVersion as number) >= 6 ? ["fulfilmentContext"] : []),
      ...((r.schemaVersion as number) >= 7 ? ['supplierQuote'] : [])]);
    const lines = array(s.lines, 100).map(value => line(value, (r.schemaVersion as number) >= 3,
      (r.schemaVersion as number) >= 4 ? {realm, storeId: id(s.storeId)} : undefined, (r.schemaVersion as number) >= 5,
      (r.schemaVersion as number) >= 8, (r.schemaVersion as number) >= 9)).sort((a,b) => compare(a.sourceLineId, b.sourceLineId));
    unique(lines.map(l => l.sourceLineId));
    const amounts = totals(s.totals, lines.reduce((sum, l) => sum + l.lineTotalMinor, 0));
    return {storeId: id(s.storeId), caseId: id(s.caseId), ownerUserId: id(s.ownerUserId), lines, totals: amounts,
      ...(r.schemaVersion !== 1 ? {benefitAttribution: benefits(s.benefitAttribution,
        lines.map(l => ({lineId: l.sourceLineId, lineTotalMinor: l.lineTotalMinor})), amounts.discountMinor)} : {}),
      ...((r.schemaVersion as number) >= 6 ? {fulfilmentContext: fulfilmentContext(s.fulfilmentContext,
        lines.map(l => ({lineId: l.sourceLineId})), lines.some(l => l.scheduledFulfilment != null))} : {}),
      ...((r.schemaVersion as number) >= 7 ? {supplierQuote: supplierQuote(s.supplierQuote, realm,
        lines.map(l => ({...l, lineId: l.sourceLineId})), (r.schemaVersion as number) >= 9)} : {})};
  }).sort((a,b) => compare(a.storeId, b.storeId));
  unique(stores.map(s => s.storeId)); unique(stores.map(s => s.caseId));
  if (stores.reduce((sum, s) => sum + s.lines.length, 0) > 200) fail();
  const result: TrustedPlacementReceipt = {schemaVersion: r.schemaVersion, realm, authNamespace: "firebase-default",
    finalPlacement: true, issuer: id(r.issuer), receiptId: id(r.receiptId), revision: id(r.revision),
    buyerUserId: id(r.buyerUserId), stores};
  const declaredStoreCoupons = stores.flatMap(store => (store.benefitAttribution?.components ?? [])
    .filter(component => /^store-coupon-v[1-9][0-9]*$/u.test(component.benefitRevision))
    .map(component => ({storeId: store.storeId, componentId: component.componentId})));
  if (declaredStoreCoupons.length && !hasCouponContext) fail();
  if (hasCouponContext) {
    if (r.schemaVersion !== 6 && r.schemaVersion !== 7 && r.schemaVersion !== 8 && r.schemaVersion !== 9) fail();
    const context = exact(r.couponUseContext, ["schemaVersion", "stores"]);
    if (context.schemaVersion !== 1) fail();
    const coupons = array(context.stores, 10).map(raw => {
      const c = exact(raw, ["storeId", "couponId", "couponRevision", "componentId", "basket", "holdUntil", "lifecycleSourceId"]);
      const storeId = id(c.storeId), componentId = id(c.componentId);
      const store = stores.find(s => s.storeId === storeId);
      if (!store || !store.benefitAttribution?.components.some(component => component.componentId === componentId)) fail();
      return {storeId, couponId: id(c.couponId), couponRevision: integer(c.couponRevision, 1_000_000_000, 1), componentId,
        basket: structuredClone(obj(c.basket)), holdUntil: timestamp(c.holdUntil), lifecycleSourceId: id(c.lifecycleSourceId)};
    }).sort((a, b) => compare(a.storeId, b.storeId));
    unique(coupons.map(c => c.storeId));
    result.couponUseContext = {schemaVersion: 1, stores: coupons};
    if (declaredStoreCoupons.some(component => !coupons.some(c =>
      c.storeId === component.storeId && c.componentId === component.componentId))) fail();
  }
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
  return digest({factsVersion: original.lines.some(l => Object.hasOwn(l, 'commodityPriceSnapshot')) ? 10 : original.lines.some(l => Object.hasOwn(l, 'supplierTaxSnapshot')) ? 9 : Object.hasOwn(original, "supplierQuote") ? 8 : Object.hasOwn(original, "fulfilmentContext") ? 7 : original.lines.some(l => l.publicListing !== undefined) ? 6 : original.lines.some(l => l.scheduledFulfilment !== undefined) ? 5 : original.lines.some(l => l.variant !== undefined) ? 4 :
    original.benefitAttribution === undefined ? 2 : 3, storeId, orderId, original});
}
function validateAggregate(value: unknown, purchaseId: string, realm: Realm): PurchaseAggregate {
  try {
    const r = exact(value, ["schemaVersion", "realm", "authNamespace", "purchaseId", "buyerUserId",
      "buyerId", "sourceRevision", "sourceFingerprint", "createdAt", "orders", "integrity"]);
    if ((r.schemaVersion !== 2 && r.schemaVersion !== 3 && r.schemaVersion !== 4 && r.schemaVersion !== 5 && r.schemaVersion !== 6 && r.schemaVersion !== 7 && r.schemaVersion !== 8 && r.schemaVersion !== 9 && r.schemaVersion !== 10) || r.realm !== realm || r.authNamespace !== "firebase-default" ||
        r.purchaseId !== purchaseId || !/^[a-f0-9]{64}$/u.test(String(r.sourceFingerprint))) fail();
    id(r.buyerUserId); id(r.buyerId); id(r.sourceRevision);
    if (typeof r.createdAt !== "string" || new Date(r.createdAt).toISOString() !== r.createdAt) fail();
    const orders = array(r.orders, 10).map(raw => {
      const o = exact(raw, ["factsVersion", "storeId", "orderId", "original", "originalFingerprint", "caseId", "ownerUserId"]);
      if (o.factsVersion !== r.schemaVersion) fail();
      const original = exact(o.original, ["currency", "lines", "totals",
        ...(o.factsVersion !== 2 ? ["benefitAttribution"] : []), ...((o.factsVersion as number) >= 7 ? ["fulfilmentContext"] : []),
        ...((o.factsVersion as number) >= 8 ? ['supplierQuote'] : [])]);
      if (original.currency !== "INR") fail();
      const lines = array(original.lines, 100).map(rawLine => {
        const l = exact(rawLine, [...lineKeys.filter(k => k !== "sourceLineId"), "lineId",
          ...((o.factsVersion as number) >= 4 ? ["variant"] : []), ...((o.factsVersion as number) >= 5 ? ["scheduledFulfilment"] : []),
          ...((o.factsVersion as number) >= 6 ? ["publicListing"] : []), ...((o.factsVersion as number) >= 9 ? ['supplierTaxSnapshot'] : []),
          ...((o.factsVersion as number) >= 10 ? ['commodityPriceSnapshot'] : [])]);
        const {lineId, ...rest} = l;
        const {sourceLineId, ...normalized} = line({...rest, sourceLineId: lineId}, (o.factsVersion as number) >= 4,
          (o.factsVersion as number) >= 5 ? {realm, storeId: id(o.storeId)} : undefined, (o.factsVersion as number) >= 6,
          (o.factsVersion as number) >= 9, (o.factsVersion as number) >= 10);
        return {lineId: sourceLineId, ...normalized};
      }).sort((a,b) => compare(a.lineId, b.lineId));
      unique(lines.map(l => l.lineId));
      const canonical: PurchaseOriginal = {currency: "INR", lines,
        totals: totals(original.totals, lines.reduce((sum,l) => sum + l.lineTotalMinor, 0))};
      if (o.factsVersion !== 2) canonical.benefitAttribution = benefits(original.benefitAttribution, lines, canonical.totals.discountMinor);
      if ((o.factsVersion as number) >= 7) canonical.fulfilmentContext = fulfilmentContext(original.fulfilmentContext, lines,
        lines.some(l => l.scheduledFulfilment != null));
      if ((o.factsVersion as number) >= 8) canonical.supplierQuote = supplierQuote(original.supplierQuote, realm, lines,
        (o.factsVersion as number) >= 10);
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
    private readonly source?: FinalPlacementSource, private readonly coupons?: PurchaseCouponCommitter,
    private readonly bulkQuotes?: Pick<WorkspaceBulkQuoteService, 'preparePurchase'>) {
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
      if (input.couponUseContext && !this.coupons) fail("service_unavailable", 503);
      const buyerDoc = await tx.get(buyer);
      const buyerData = buyerDoc.data();
      if (buyerDoc.exists && (buyerData?.userId !== input.buyerUserId || buyerData.authNamespace !== input.authNamespace)) fail("invalid_state", 409);
      const buyerId = buyerDoc.exists ? id(buyerData!.buyerId) : candidateBuyerId;
      for (const store of input.stores) {
        const profile = await tx.get(this.db.collection("workspaceProfiles").doc(store.caseId));
        requireStore(profile.data(), store);
      }
      const bulkCommits: (() => void)[] = [];
      for (const store of input.stores) {
        if (store.supplierQuote == null) continue;
        if (!this.bulkQuotes) fail('service_unavailable', 503);
        const q = store.supplierQuote;
        const prepared = await this.bulkQuotes.preparePurchase(tx, {buyerUserId: input.buyerUserId, storeId: store.storeId,
          caseId: store.caseId, ownerUserId: store.ownerUserId, purchaseId},
        {schemaVersion: 1, quoteId: q.quoteId, acceptedRevision: q.acceptedRevision,
          agreementFingerprint: q.agreementFingerprint, lines: q.lines},
        store.lines.filter(l => q.lines.some(b => b.lineId === l.sourceLineId)));
        if (integrityHash(prepared.supplierQuote) !== integrityHash(q)) fail('conflict', 409);
        bulkCommits.push(prepared.commit);
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
        if (Object.hasOwn(s, "fulfilmentContext")) {
          const savedIds = new Map(s.lines.map(l => [l.sourceLineId, l.lineId]));
          original.fulfilmentContext = s.fulfilmentContext == null ? null : {...s.fulfilmentContext,
            instructions: s.fulfilmentContext.instructions.map(i => ({...i, lineId: savedIds.get(i.lineId)!})).sort((a,b) => compare(a.lineId, b.lineId))};
        }
        if (Object.hasOwn(s, 'supplierQuote')) {
          const savedIds = new Map(s.lines.map(l => [l.sourceLineId, l.lineId]));
          original.supplierQuote = s.supplierQuote == null ? null : {...s.supplierQuote,
            lines: s.supplierQuote.lines.map(b => ({...b, lineId: savedIds.get(b.lineId)!})).sort((a,b) => compare(a.lineId, b.lineId))};
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
      const writeCouponHolds = input.couponUseContext ? await this.coupons!.prepareCouponHolds(tx,
        {receipt: input, purchaseId, createdAt, orders: allocatedOrders}) : undefined;
      for (const commit of bulkCommits) commit();
      writeCouponHolds?.();
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
