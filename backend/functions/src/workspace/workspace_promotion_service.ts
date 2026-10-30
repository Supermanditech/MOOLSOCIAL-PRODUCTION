import {FieldPath, type DocumentReference, type Firestore, type Transaction} from "firebase-admin/firestore";
import type {PurchaseCouponTransactionContext, BulkPurchaseReference, BulkCouponPrices, WorkspaceBulkQuoteService} from "./workspace_purchase_projection_service.js";
import {cataloguePayloadHash, checkedPublicCatalogueListingBinding, type WorkspaceCatalogueService} from "./workspace_catalogue_service.js";
import {WorkspaceProfileError, type WorkspaceProfileRecord} from "./workspace_profile_service.js";
import {checkedStoreCouponV2Input, checkedStoreCouponV2Record, validateStoreCouponV2ForSave,
  checkedStoreCouponDraftCampaign, checkedStoreCouponDraftId, type StoreCouponDraftCampaign,
  publicStoreOfferV2Terms, checkedStoreOfferV2Terms, storeCouponV2UtcMicros,
  type StoreOfferV2Sku, type StoreCouponV2Input, type StoreCouponV2Record} from './workspace_coupon_v2_codec.js';

/** Owner-advertised terms only; never evaluated/applied savings or redemption. */
export interface PromotionBenefitTerms {
  schemaVersion: 1; kind: "flat" | "percentage"; currency: "INR";
  flatAmountMinor: number | null; flatBasis: "per_pack" | "per_order" | null;
  percentageBasisPoints: number | null; maximumSavingMinor: number | null;
  minimumSpendMinor: number | null; minimumQuantity: number | null;
}
/** Public product promotion only: no discount, consent, redemption or order authority. */
export interface PromotionInput {
  skuId: string; skuRevision: number; channel: "retail" | "wholesale" | "bulk";
  headline: string; detail: string; validFrom: string; validUntil: string; active: boolean;
  benefitTerms?: PromotionBenefitTerms;
}
export interface PromotionRecord extends PromotionInput {
  schemaVersion: 1; realm: "evaluation" | "production"; storeId: string;
  placementId: string; revision: number; observedAt: string;
}
export interface PromotionCommand {
  ownerUserId: string; realm: PromotionRecord["realm"]; storeId: string; placementId: string;
  expectedRevision: number; idempotencyKey: string; promotion: PromotionInput;
  fingerprint: string; observedAt: string;
  promotionTermsVersion?: 1;
}
export interface PromotionReceipt {fingerprint: string; record: PromotionRecord}
/** Store-wide advertised configuration. These are not evaluated savings or
 * remaining uses. Local draft revisions are never server CAS revisions. */
export interface StoreCouponInput {
  name: string; percentage: boolean; discount: number; minimumSpendMinor: number;
  maximumSavingMinor: number; startsAt: string; endsAt: string;
  totalUses: number; usesPerCustomer: number; active: boolean;
}
export interface StoreCouponRecord extends StoreCouponInput {
  schemaVersion: 1; realm: PromotionRecord["realm"]; storeId: string;
  couponId: string; revision: number; observedAt: string;
}
export interface StoreCouponCommand {
  ownerUserId: string; realm: PromotionRecord["realm"]; storeId: string;
  couponId: string; expectedRevision: number; idempotencyKey: string;
  coupon: StoreCouponInput; fundingAcknowledged: true; fingerprint: string; observedAt: string;
}
export interface StoreCouponReceipt {fingerprint: string; record: StoreCouponRecord}
export interface StoreCouponV2Command {
  ownerUserId: string; realm: PromotionRecord['realm']; storeId: string;
  couponId: string; expectedRevision: number; idempotencyKey: string;
  coupon: StoreCouponV2Input; fundingAcknowledged: true; fingerprint: string; observedAt: string;
}
export type VersionedStoreCouponRecord = StoreCouponRecord | StoreCouponV2Record;
export interface VersionedStoreCouponPage {records: VersionedStoreCouponRecord[]; nextCursor: string | null}
export interface StoreCouponDraftRecord {
  schemaVersion: 1; storeCouponDraftVersion: 1; accountId: string; realm: PromotionRecord['realm'];
  storeId: string; couponId: string; sourceRevision: number; observedAt: string; campaign: StoreCouponDraftCampaign;
}
export interface StoreCouponDraftCommand {
  ownerUserId: string; realm: PromotionRecord['realm']; storeId: string; couponId: string;
  expectedSourceRevision: number; idempotencyKey: string; campaign: StoreCouponDraftCampaign;
  observedAt: string; fingerprint: string;
}
export interface StoreCouponDraftPage {records: StoreCouponDraftRecord[]; nextCursor: string | null}
const couponDraftOperations = ['saveStoreCouponDraft', 'readStoreCouponDraft', 'listStoreCouponDrafts', 'reconcileStoreCouponDraft'];
function couponDraftRequest(userId: string, realm: PromotionRecord['realm'], raw: unknown, now: string): StoreCouponDraftCommand {
  const row = exact(raw, ['storeId', 'couponId', 'expectedSourceRevision', 'idempotencyKey', 'campaign']);
  if (!['evaluation', 'production'].includes(realm)) fail();
  const storeId = id(row.storeId), couponId = checkedStoreCouponDraftId(row.couponId), ownerUserId = id(userId);
  const facts = {storeId, couponId, expectedSourceRevision: integer(row.expectedSourceRevision, 0, 999999999),
    idempotencyKey: id(row.idempotencyKey), campaign: checkedStoreCouponDraftCampaign(row.campaign, storeId, couponId)};
  return {...facts, ownerUserId, realm, observedAt: time(now), fingerprint: cataloguePayloadHash({operation: 'saveStoreCouponDraft',
    storeCouponDraftVersion: 1, ownerUserId, realm, ...facts})};
}
function checkedCouponDraftCommand(command: StoreCouponDraftCommand): StoreCouponDraftCommand {
  const checked = couponDraftRequest(command.ownerUserId, command.realm, {storeId: command.storeId, couponId: command.couponId,
    expectedSourceRevision: command.expectedSourceRevision, idempotencyKey: command.idempotencyKey, campaign: command.campaign}, command.observedAt);
  if (checked.fingerprint !== command.fingerprint) fail();
  return checked;
}
export function couponDraftRecord(raw: unknown, accountId: string, realm: PromotionRecord['realm'], storeId: string, now: string): StoreCouponDraftRecord {
  const row = exact(raw, ['schemaVersion', 'storeCouponDraftVersion', 'accountId', 'realm', 'storeId',
    'couponId', 'sourceRevision', 'observedAt', 'campaign']);
  if (row.schemaVersion !== 1 || row.storeCouponDraftVersion !== 1 || row.accountId !== accountId || row.realm !== realm ||
      row.storeId !== storeId || time(row.observedAt) > now) fail('invalid_state', 409);
  const couponId = checkedStoreCouponDraftId(row.couponId);
  integer(row.sourceRevision, 1, 1_000_000_000);
  checkedStoreCouponDraftCampaign(row.campaign, storeId, couponId);
  return structuredClone(row) as unknown as StoreCouponDraftRecord;
}
function structuredCouponRequest(userId: string, realm: PromotionRecord['realm'], raw: unknown, observedAt: string): StoreCouponV2Command {
  const input = exact(raw, ['storeId', 'couponId', 'expectedRevision', 'idempotencyKey', 'coupon', 'fundingAcknowledged']);
  if (input.fundingAcknowledged !== true || !['evaluation', 'production'].includes(realm)) fail();
  const storeId = id(input.storeId), facts = {storeId, couponId: id(input.couponId),
    expectedRevision: integer(input.expectedRevision, 0, 999999999), idempotencyKey: id(input.idempotencyKey),
    coupon: checkedStoreCouponV2Input(input.coupon, storeId), fundingAcknowledged: true as const};
  const ownerUserId = id(userId);
  return {...facts, ownerUserId, realm, observedAt: time(observedAt), fingerprint: cataloguePayloadHash({operation: 'saveStoreCoupon',
    storeCouponTermsVersion: 2, ownerUserId, realm, ...facts})};
}
function checkedStructuredCouponCommand(command: StoreCouponV2Command): StoreCouponV2Command {
  const checked = structuredCouponRequest(command.ownerUserId, command.realm, {storeId: command.storeId,
    couponId: command.couponId, expectedRevision: command.expectedRevision, idempotencyKey: command.idempotencyKey,
    coupon: command.coupon, fundingAcknowledged: command.fundingAcknowledged}, command.observedAt);
  if (checked.fingerprint !== command.fingerprint) fail();
  return checked;
}
export interface StoreCouponSnapshot {
  profile: WorkspaceProfileRecord; records: StoreCouponRecord[]; observedAt: string;
}
export interface VersionedStoreCouponSnapshot {
  profile: WorkspaceProfileRecord; records: VersionedStoreCouponRecord[]; observedAt: string; nextCursor: string | null;
}
export interface StoreCouponEligibilityQuery {
  storeId: string; couponId: string; couponRevision: number;
  storeCouponTermsVersion?: 2;
  supplierQuote?: BulkPurchaseReference;
  commodityPriceReadbackVersion?: 1;
  selectionPolicy: "exclusive_store_basket";
  lines: {lineId: string; listing: {schemaVersion: 1; realm: PromotionRecord["realm"]; listingId: string;
    storeId: string; skuId: string; canonicalProductId: string; verifiedPackId: string;
    channel: "retail" | "wholesale" | "bulk"}; skuRevision: number;
    offerId: string; offerRevision: string; quantity: number}[];
}
type CouponPriceSnapshot = (storeId: string, skuIds: readonly string[], tx: Transaction) => Promise<object[]>;
function couponSupplierQuote(raw: unknown): BulkPurchaseReference {
  const r = exact(raw, ['schemaVersion', 'quoteId', 'acceptedRevision', 'agreementFingerprint', 'lines']);
  if (r.schemaVersion !== 1 || !/^bulk-[a-f0-9]{64}$/u.test(id(r.quoteId)) ||
      typeof r.agreementFingerprint !== 'string' || !/^[a-f0-9]{64}$/u.test(r.agreementFingerprint) ||
      !Array.isArray(r.lines) || !r.lines.length || r.lines.length > 100) fail();
  const lines = r.lines.map(raw => {const b = exact(raw, ['lineId', 'quoteLineId']);
    return {lineId: id(b.lineId), quoteLineId: id(b.quoteLineId)};}).sort((a, b) => a.lineId < b.lineId ? -1 : a.lineId > b.lineId ? 1 : 0);
  if (new Set(lines.map(b => b.lineId)).size !== lines.length || new Set(lines.map(b => b.quoteLineId)).size !== lines.length) fail();
  return {schemaVersion: 1, quoteId: id(r.quoteId), acceptedRevision: integer(r.acceptedRevision, 3, 999999999),
    agreementFingerprint: r.agreementFingerprint, lines};
}
function couponEligibilityQuery(body: Readonly<Record<string, unknown>>, realm: PromotionRecord["realm"]): StoreCouponEligibilityQuery {
  const structured=body.storeCouponTermsVersion===2;
  const mixed = body.storeCouponEligibilityVersion === 3;
  const v2 = body.storeCouponEligibilityVersion === 2 || mixed;
  const row = exact(body, ["storeCouponEligibilityVersion", "storeId", "couponId", "couponRevision", "selectionPolicy", "lines", ...(v2 ? ['supplierQuote'] : []), ...(mixed ? ['commodityPriceReadbackVersion'] : []),...(structured?['storeCouponTermsVersion']:[])]);
  if (mixed && row.commodityPriceReadbackVersion !== 1) fail();
  if ((!v2 && row.storeCouponEligibilityVersion !== 1) || row.selectionPolicy !== "exclusive_store_basket" ||
      !Array.isArray(row.lines) || !row.lines.length || row.lines.length > 100) fail();
  const storeId = id(row.storeId), seen = new Set<string>(), listings = new Set<string>();
  const lines = row.lines.map(raw => {
    const line = exact(raw, ["lineId", "listing", "skuRevision", "offerId", "offerRevision", "quantity"]);
    const binding = exact(line.listing, ["schemaVersion", "realm", "listingId", "storeId", "skuId", "canonicalProductId", "verifiedPackId", "channel"]);
    if (binding.schemaVersion !== 1 || binding.realm !== realm || binding.storeId !== storeId ||
        !["retail", "wholesale", "bulk"].includes(binding.channel as string)) fail();
    const skuId = id(binding.skuId), listingId = id(binding.listingId), lineId = id(line.lineId);
    if (listingId !== `listing-${cataloguePayloadHash([1, realm, storeId, skuId, binding.channel]).toLowerCase()}` ||
        seen.has(lineId) || listings.has(listingId)) fail();
    seen.add(lineId); listings.add(listingId);
    return {lineId, listing: {schemaVersion: 1 as const, realm, listingId, storeId, skuId,
      canonicalProductId: id(binding.canonicalProductId), verifiedPackId: id(binding.verifiedPackId),
      channel: binding.channel as "retail" | "wholesale" | "bulk"}, skuRevision: integer(line.skuRevision, 1),
      offerId: id(line.offerId), offerRevision: id(line.offerRevision), quantity: integer(line.quantity, 1)};
  }).sort((a, b) => a.lineId < b.lineId ? -1 : a.lineId > b.lineId ? 1 : 0);
  const supplierQuote = v2 ? couponSupplierQuote(row.supplierQuote) : undefined;
  const bulk = lines.filter(line => line.listing.channel === 'bulk');
  if (supplierQuote && (!mixed && supplierQuote.lines.length !== bulk.length ||
      supplierQuote.lines.some(b => !bulk.some(l => l.lineId === b.lineId)))) fail();
  return {storeId, couponId: id(row.couponId), couponRevision: integer(row.couponRevision, 1),
    selectionPolicy: "exclusive_store_basket", lines, ...(supplierQuote ? {supplierQuote} : {}), ...(mixed ? {commodityPriceReadbackVersion: 1 as const} : {}),
    ...(structured?{storeCouponTermsVersion:2 as const}:{})};
}

function couponBasketFromPrices(query: StoreCouponEligibilityQuery, pages: object[], realm: PromotionRecord["realm"],
  actor: string, now: string, negotiated?: BulkCouponPrices): StoreCouponBasket {
  if (query.supplierQuote && !negotiated) fail('unavailable', 503);
  const bySku = new Map<string, Record<string, unknown>>();
  let catalogueVersion: number | undefined, validUntil = new Date(Date.parse(now) + 60000).toISOString();
  if (negotiated) {
    if (negotiated.supplierQuote.validUntil <= now) fail('conflict', 409);
    if (negotiated.supplierQuote.validUntil < validUntil) validUntil = negotiated.supplierQuote.validUntil;
  }
  for (const raw of pages) {
    const page = object(raw);
    if (page.schemaVersion !== 1 || page.realm !== realm || page.storeId !== query.storeId || page.state !== "ready" ||
        page.coverage !== "verified_public_only" || page.listingReadbackVersion !== 1 || page.listingCoverage !== "complete" ||
        time(page.observedAt) > now || !Array.isArray(page.items) || page.items.length !== 1 || page.nextCursor !== null) fail("unavailable", 503);
    const version = integer(page.catalogueVersion, 1);
    if (catalogueVersion !== undefined && catalogueVersion !== version) fail("unavailable", 503);
    catalogueVersion = version;
    const item = object(page.items[0]), skuId = id(item.skuId);
    if (bySku.has(skuId)) fail("unavailable", 503);
    bySku.set(skuId, item);
  }
  if (bySku.size !== new Set(query.lines.map(line => line.listing.skuId)).size || catalogueVersion === undefined) fail("unavailable", 503);
  const lines = query.lines.map(line => {
    const item = bySku.get(line.listing.skuId);
    if (!item || item.revision !== line.skuRevision || item.canonicalProductId !== line.listing.canonicalProductId ||
        item.verifiedPackId !== line.listing.verifiedPackId || !Array.isArray(item.listings) ||
        !item.listings.some(binding => cataloguePayloadHash(binding) === cataloguePayloadHash(line.listing)) ||
        !Array.isArray(item.channels)) fail("conflict", 409);
    const matches = item.channels.map(object).filter(channel => channel.kind === line.listing.channel);
    if (matches.length !== 1) fail("unavailable", 503);
    const channel = matches[0]!;
    if (channel.offerId !== line.offerId || channel.revision !== line.offerRevision) fail("conflict", 409);
    const expires = time(channel.validUntil), minimum = integer(channel.minimumOrder, 1), step = integer(channel.quantityStep, 1);
    if (expires <= now || line.quantity < minimum || (line.quantity - minimum) % step !== 0) fail("conflict", 409);
    if (expires < validUntil) validUntil = expires;
    let price = integer(channel.priceMinor, 0, 9_000_000_000_000), lastMinimum = 0, lastPrice = price;
    if (!Array.isArray(channel.tiers) || channel.tiers.length > 20) fail("unavailable", 503);
    for (const [index, rawTier] of channel.tiers.entries()) {
      const tier = exact(rawTier, ["minimumQuantity", "unitPriceMinor"]), quantity = integer(tier.minimumQuantity, 1),
        amount = integer(tier.unitPriceMinor, 0, 9_000_000_000_000);
      if (quantity <= lastMinimum || (quantity - minimum) % step !== 0 || amount > lastPrice ||
          index === 0 && (quantity !== minimum || amount !== price)) fail("unavailable", 503);
      lastMinimum = quantity; lastPrice = amount;
      if (quantity <= line.quantity) price = amount;
    }
    const agreed = negotiated?.prices.find(p => p.lineId === line.lineId);
    if (line.listing.channel === 'bulk' && negotiated && (query.commodityPriceReadbackVersion !== 1 || agreed)) {
      if (!agreed || agreed.merchandiseMinor !== agreed.unitPriceMinor * line.quantity) fail('conflict', 409);
      price = agreed.unitPriceMinor;
    } else if (agreed) fail('conflict', 409);
    else if (line.listing.channel === 'bulk' && negotiated) {
      // Only the trusted catalogue snapshot can authorise the unquoted subset.
      const confirmation = object(channel.priceConfirmation);
      if (query.commodityPriceReadbackVersion !== 1 || confirmation.version !== 1 ||
          !Number.isSafeInteger(confirmation.revision) || (confirmation.revision as number) < 1 ||
          channel.revision !== line.offerRevision || !new RegExp(`^commodity-${confirmation.revision}-[A-F0-9]{16}$`, 'u').test(line.offerRevision) ||
          time(confirmation.confirmedAt) > now || time(confirmation.validUntil) !== expires) fail('conflict', 409);
    }
    return {lineId: line.lineId, storeId: query.storeId, skuId: line.listing.skuId,
      packId: line.listing.verifiedPackId, offerId: line.offerId, offerRevision: line.offerRevision,
      priceSourceId: agreed ? cataloguePayloadHash(query.supplierQuote) : line.offerRevision, channel: line.listing.channel, quantity: line.quantity, unitPriceMinor: price,
      // Explicit replacement candidate, not an observation about applied coupons.
      otherCouponApplied: false};
  });
  return {schemaVersion: negotiated ? 2 : 1, realm, storeId: query.storeId, buyerUserId: actor, couponRevision: query.couponRevision,
    sourceId: cataloguePayloadHash({operation: negotiated ? "exclusiveStoreCouponCandidateV2" : "exclusiveStoreCouponCandidateV1", query, actor, catalogueVersion,
      exclusiveSelectionRequired: true, lines}), sourceRevision: catalogueVersion, observedAt: now, validUntil, lines,
    ...(query.supplierQuote ? {supplierQuote: structuredClone(query.supplierQuote)} : {})};
}
/** Server-resolved basket facts only. Never accept this DTO from a public
 * client as price, eligibility, tax, payment or final-placement authority. */
export interface StoreCouponBasket {
  schemaVersion: 1 | 2; realm: PromotionRecord["realm"]; storeId: string; buyerUserId: string;
  supplierQuote?: BulkPurchaseReference;
  couponRevision: number; sourceId: string; sourceRevision: number;
  observedAt: string; validUntil: string;
  lines: {lineId: string; storeId: string; skuId: string; packId: string;
    offerId: string; offerRevision: number | string; priceSourceId: string;
    channel: "retail" | "wholesale" | "bulk"; quantity: number;
    unitPriceMinor: number; otherCouponApplied: boolean}[];
}
export interface StoreCouponEvaluation {
  schemaVersion: 1; realm: PromotionRecord["realm"]; storeId: string; buyerUserId: string;
  couponId: string; couponRevision: number; name: string;
  basketSourceId: string; basketSourceRevision: number; basketFingerprint: string;
  eligibleSubtotalMinor: number; savingMinor: number;
  allocations: {lineId: string; skuId: string; packId: string; offerId: string;
    offerRevision: number | string; subtotalMinor: number; savingMinor: number}[];
}
export interface StoreCouponUse {
  schemaVersion: 1; realm: PromotionRecord["realm"]; storeId: string; buyerUserId: string;
  couponId: string; couponRevision: number; purchaseId: string; storeOrderId: string;
  basketFingerprint: string; savingMinor: number; revision: number;
  state: "held" | "consumed" | "released"; heldAt: string; holdUntil: string;
  lifecycleSourceId: string; lastSourceRevision: number; lastObservedAt: string; fulfilmentStarted: boolean;
}
/** Internal verified lifecycle source, never a public callback/request body. */
export interface StoreCouponUseEvent {
  eventId: string; sourceId: string; sourceRevision: number; observedAt: string;
  realm: PromotionRecord["realm"]; storeId: string; buyerUserId: string;
  couponId: string; couponRevision: number; purchaseId: string; storeOrderId: string;
  basketFingerprint: string; expectedRevision: number;
  outcome: "payment_confirmed" | "payment_failed" | "payment_expired" |
    "cancelled_before_fulfilment" | "fulfilment_started" | "completed_order_refunded";
}
export interface StoreCouponUseReceipt {
  eventId: string; fingerprint: string; record: StoreCouponUse;
}
/** Exact private attribution references emitted by the trusted coupon producer.
 * Public campaign copy is never funding or redemption authority. */
export function storeCouponAttributionReferences(realm: PromotionRecord["realm"], storeId: string,
  couponId: string, couponRevision: number) {
  if (!["evaluation", "production"].includes(realm)) fail();
  id(storeId); id(couponId); integer(couponRevision, 1);
  return {benefitRevision: `store-coupon-v${couponRevision}`,
    sourceReference: cataloguePayloadHash(["storeCouponCampaignV1", realm, storeId, couponId, couponRevision]),
    funderReference: cataloguePayloadHash(["storeCouponFunderV1", realm, storeId])};
}

/** Atomic repository must read current use + exact event receipt and persist
 * both together with aggregate/customer usage. Does not call payment or Stock. */
export function planStoreCouponUseEvent(current: StoreCouponUse, event: StoreCouponUseEvent,
  priorReceipt?: StoreCouponUseReceipt): StoreCouponUseReceipt {
  const row = exact(current, ["schemaVersion", "realm", "storeId", "buyerUserId", "couponId", "couponRevision",
    "purchaseId", "storeOrderId", "basketFingerprint", "savingMinor", "revision", "state", "heldAt", "holdUntil",
    "lifecycleSourceId", "lastSourceRevision", "lastObservedAt", "fulfilmentStarted"]);
  const command = exact(event, ["eventId", "sourceId", "sourceRevision", "observedAt", "realm", "storeId", "buyerUserId",
    "couponId", "couponRevision", "purchaseId", "storeOrderId", "basketFingerprint", "expectedRevision", "outcome"]);
  if (row.schemaVersion !== 1 || !["evaluation", "production"].includes(row.realm as string) ||
      !["held", "consumed", "released"].includes(row.state as string)) fail();
  for (const key of ["storeId", "buyerUserId", "couponId", "purchaseId", "storeOrderId"]) {
    id(row[key]); if (command[key] !== row[key]) fail("conflict", 409);
  }
  if (command.realm !== row.realm || integer(command.couponRevision, 1) !== integer(row.couponRevision, 1) ||
      typeof row.basketFingerprint !== "string" || !/^[A-F0-9]{64}$/u.test(row.basketFingerprint) ||
      command.basketFingerprint !== row.basketFingerprint) fail("conflict", 409);
  integer(row.savingMinor, 1, Number.MAX_SAFE_INTEGER);
  const revision = integer(row.revision, 1), expectedRevision = integer(command.expectedRevision, 1);
  id(command.eventId); id(command.sourceId); integer(command.sourceRevision, 1);
  id(row.lifecycleSourceId); integer(row.lastSourceRevision, 0);
  if (command.sourceId !== row.lifecycleSourceId || typeof row.fulfilmentStarted !== "boolean" ||
      row.fulfilmentStarted && row.state !== "consumed") fail("conflict", 409);
  const observedAt = time(command.observedAt), heldAt = time(row.heldAt), holdUntil = time(row.holdUntil);
  const lastObservedAt = time(row.lastObservedAt);
  if (lastObservedAt < heldAt) fail();
  if (heldAt >= holdUntil || observedAt < heldAt || !["payment_confirmed", "payment_failed", "payment_expired",
      "cancelled_before_fulfilment", "fulfilment_started", "completed_order_refunded"].includes(command.outcome as string)) fail();
  const fingerprint = cataloguePayloadHash({operation: "storeCouponUseEventV1", ...event});
  if (priorReceipt) {
    exact(priorReceipt, ["eventId", "fingerprint", "record"]);
    const retained = exact(priorReceipt.record, Object.keys(row));
    const outcomeState = event.outcome === "payment_confirmed" || event.outcome === "completed_order_refunded" || event.outcome === "fulfilment_started"
      ? "consumed" : "released";
    for (const key of ["schemaVersion", "realm", "storeId", "buyerUserId", "couponId", "couponRevision",
      "purchaseId", "storeOrderId", "basketFingerprint", "savingMinor", "heldAt", "holdUntil", "lifecycleSourceId"]) {
      if (retained[key] !== row[key]) fail("conflict", 409);
    }
    if (priorReceipt.eventId !== event.eventId || priorReceipt.fingerprint !== fingerprint ||
        retained.revision !== expectedRevision + 1 || retained.state !== outcomeState ||
        retained.lastSourceRevision !== event.sourceRevision || retained.lastObservedAt !== event.observedAt ||
        typeof retained.fulfilmentStarted !== "boolean" ||
        event.outcome === "payment_confirmed" && retained.fulfilmentStarted !== false ||
        (event.outcome === "completed_order_refunded" || event.outcome === "fulfilment_started") && retained.fulfilmentStarted !== true ||
        retained.state !== "consumed" && retained.fulfilmentStarted !== false ||
        revision < (retained.revision as number)) fail("conflict", 409);
    return structuredClone(priorReceipt);
  }
  if (expectedRevision !== revision || revision >= 1_000_000_000) fail("conflict", 409);
  if (event.sourceRevision <= current.lastSourceRevision || observedAt < lastObservedAt) fail("conflict", 409);
  let state = current.state;
  let fulfilmentStarted = current.fulfilmentStarted;
  switch (event.outcome) {
    case "payment_confirmed":
      if (state !== "held") fail("conflict", 409);
      state = "consumed"; break;
    case "payment_failed": case "payment_expired":
      if (state !== "held" || event.outcome === "payment_expired" && observedAt < holdUntil) fail("conflict", 409);
      state = "released"; break;
    case "cancelled_before_fulfilment":
      if (state === "released" || fulfilmentStarted) fail("conflict", 409);
      state = "released"; break;
    case "fulfilment_started": case "completed_order_refunded":
      if (state !== "consumed") fail("conflict", 409);
      fulfilmentStarted = true;
      // Approved MVP: a completed-order refund never restores coupon usage.
      break;
  }
  return {eventId: event.eventId, fingerprint, record: {...structuredClone(current), state, revision: revision + 1,
    lifecycleSourceId: event.sourceId, lastSourceRevision: event.sourceRevision, lastObservedAt: observedAt, fulfilmentStarted}};
}

/** Pure calculation, not a use/hold/redemption or an authoritative quote.
 * Trusted caller must resolve prices/tiers/revisions and usage eligibility.
 * Floor once per Store, then apportion exact paise in stable line-ID order. */
function couponMoneyConfiguration(raw:VersionedStoreCouponRecord,realm:PromotionRecord['realm'],storeId:string,accountId:string,now:string){
  const original=raw.schemaVersion===2?checkedStoreCouponV2Record(raw,{account:accountId,realm,store:storeId},now):couponRecord(raw,realm,storeId);
  if(original.schemaVersion!==2)return {original,coupon:original,terms:null};
  const input=original.coupon,terms=input.structuredTerms;
  if(terms.kind!=='billDiscount'&&terms.kind!=='productDiscount')fail('unavailable',503);
  return {original,terms,coupon:{couponId:original.couponId,revision:original.revision,observedAt:original.observedAt,
    name:input.name,active:input.active,startsAt:input.startsAt,endsAt:input.endsAt,totalUses:input.totalUses,
    usesPerCustomer:input.usesPerCustomer,percentage:terms.discountKind==='percentage',discount:terms.discountValue!,
    minimumSpendMinor:terms.minimumSpendMinor,maximumSavingMinor:terms.maximumSavingMinor!}};
}
function couponMoneyActive(configuration:ReturnType<typeof couponMoneyConfiguration>,now:string){
  const coupon=configuration.coupon;
  return coupon.active&&(configuration.terms===null?coupon.startsAt<=now&&coupon.endsAt>now:
    storeCouponV2UtcMicros(coupon.startsAt)<=storeCouponV2UtcMicros(now)&&storeCouponV2UtcMicros(coupon.endsAt)>storeCouponV2UtcMicros(now));
}
function couponMoneyLine(configuration:ReturnType<typeof couponMoneyConfiguration>,storeId:string,
    line:{storeId:string;skuId:string;channel:unknown;otherCouponApplied:boolean}){
  const terms=configuration.terms;
  return line.storeId===storeId&&!line.otherCouponApplied&&(terms===null||
    terms.channels.includes(line.channel as 'retail'|'wholesale'|'bulk')&&(!terms.skus.length||terms.skus.some(sku=>sku.skuId===line.skuId)));
}
export function evaluateStoreCouponBasket(rawCoupon: VersionedStoreCouponRecord,
  profile: WorkspaceProfileRecord | undefined, rawBasket: StoreCouponBasket,
  evaluatedAt: string): StoreCouponEvaluation {
  const now = time(evaluatedAt), row = exact(rawBasket, ["schemaVersion", "realm", "storeId", "buyerUserId",
    "couponRevision", "sourceId", "sourceRevision", "observedAt", "validUntil", "lines", ...(rawBasket.schemaVersion === 2 ? ['supplierQuote'] : [])]);
  if (![1, 2].includes(row.schemaVersion as number) || !["evaluation", "production"].includes(row.realm as string)) fail();
  const supplierQuote = row.schemaVersion === 2 ? couponSupplierQuote(row.supplierQuote) : undefined;
  const realm = row.realm as PromotionRecord["realm"], storeId = id(row.storeId), buyerUserId = id(row.buyerUserId);
  owner(profile, storeId);
  const configuration=couponMoneyConfiguration(rawCoupon,realm,storeId,profile!.ownerUserId,now),coupon=configuration.coupon;
  const revision = integer(row.couponRevision, 1), sourceId = id(row.sourceId), sourceRevision = integer(row.sourceRevision, 1);
  const observedAt = time(row.observedAt), validUntil = time(row.validUntil);
  if (revision !== coupon.revision || !couponMoneyActive(configuration,now) || coupon.observedAt > now || observedAt > now ||
      observedAt >= validUntil || validUntil <= now || !Array.isArray(row.lines) ||
      row.lines.length === 0 || row.lines.length > 500) fail("invalid_state", 409);
  const seen = new Set<string>();
  const lines = row.lines.map(raw => {
    const line = exact(raw, ["lineId", "storeId", "skuId", "packId", "offerId", "offerRevision",
      "priceSourceId", "channel", "quantity", "unitPriceMinor", "otherCouponApplied"]);
    const lineId = id(line.lineId);
    if (seen.has(lineId) || !["retail", "wholesale", "bulk"].includes(line.channel as string) ||
        typeof line.otherCouponApplied !== "boolean") fail();
    seen.add(lineId);
    const quantity = integer(line.quantity, 1), unitPriceMinor = integer(line.unitPriceMinor, 0, 9_000_000_000_000);
    const subtotal = BigInt(quantity) * BigInt(unitPriceMinor);
    if (subtotal > BigInt(Number.MAX_SAFE_INTEGER)) fail();
    return {lineId, storeId: id(line.storeId), skuId: id(line.skuId), packId: id(line.packId),
      offerId: id(line.offerId), offerRevision: typeof line.offerRevision === "string" ? id(line.offerRevision) : integer(line.offerRevision, 1), priceSourceId: id(line.priceSourceId),
      channel: line.channel, quantity, unitPriceMinor, otherCouponApplied: line.otherCouponApplied,
      subtotalMinor: Number(subtotal)};
  }).sort((a, b) => a.lineId < b.lineId ? -1 : a.lineId > b.lineId ? 1 : 0);
  if (supplierQuote) {
    const bulk = lines.filter(l => l.channel === 'bulk' &&
      !(typeof l.offerRevision === 'string' && /^commodity-[1-9][0-9]*-[A-F0-9]{16}$/u.test(l.offerRevision) && l.priceSourceId === l.offerRevision));
    if (bulk.length !== supplierQuote.lines.length || bulk.some(l =>
        !supplierQuote.lines.some(b => b.lineId === l.lineId) || l.priceSourceId !== cataloguePayloadHash(supplierQuote))) fail();
  }
  const eligible = lines.filter(line => couponMoneyLine(configuration,storeId,line) && line.subtotalMinor > 0);
  const subtotal = eligible.reduce((sum, line) => sum + BigInt(line.subtotalMinor), 0n);
  if (subtotal <= 0n || subtotal > BigInt(Number.MAX_SAFE_INTEGER) || subtotal < BigInt(coupon.minimumSpendMinor)) {
    fail("invalid_state", 409);
  }
  const calculated = coupon.percentage ? subtotal * BigInt(coupon.discount) / 10000n : BigInt(coupon.discount);
  const cap = BigInt(coupon.maximumSavingMinor);
  const saving = calculated < cap ? calculated : cap;
  const bounded = saving < subtotal ? saving : subtotal;
  if (bounded <= 0n) fail("invalid_state", 409);
  let cumulative = 0n, allocated = 0n;
  const allocations = eligible.map(line => {
    cumulative += BigInt(line.subtotalMinor);
    const next = cumulative * bounded / subtotal, savingMinor = Number(next - allocated);
    allocated = next;
    return {lineId: line.lineId, skuId: line.skuId, packId: line.packId, offerId: line.offerId,
      offerRevision: line.offerRevision, subtotalMinor: line.subtotalMinor, savingMinor};
  });
  return {schemaVersion: 1, realm, storeId, buyerUserId, couponId: coupon.couponId,
    couponRevision: coupon.revision, name: coupon.name, basketSourceId: sourceId,
    basketSourceRevision: sourceRevision,
    basketFingerprint: cataloguePayloadHash({operation: configuration.terms===null?"storeCouponBasketV1":"storeCouponBasketV2", realm, storeId, buyerUserId,
      sourceId, sourceRevision, observedAt, validUntil, coupon:configuration.original, lines: lines.filter(line => line.storeId === storeId)}),
    eligibleSubtotalMinor: Number(subtotal), savingMinor: Number(bounded), allocations};
}
export interface PromotionRepository {
  readonly realm: PromotionRecord["realm"];
  store(storeId: string): Promise<WorkspaceProfileRecord | undefined>;
  save(command: PromotionCommand): Promise<PromotionRecord>;
  read(storeId: string, placementId: string, userId?: string): Promise<PromotionRecord | undefined>;
  page(storeId: string, after: string | undefined, limit: number, userId?: string): Promise<PromotionRecord[]>;
  reconcile(command: PromotionCommand): Promise<PromotionRecord | undefined>;
  saveCoupon?(command: StoreCouponCommand): Promise<StoreCouponRecord>;
  readCoupon?(storeId: string, couponId: string, userId?: string): Promise<StoreCouponRecord | undefined>;
  pageCoupons?(storeId: string, after: string | undefined, limit: number, userId?: string): Promise<StoreCouponRecord[]>;
  reconcileCoupon?(command: StoreCouponCommand): Promise<StoreCouponRecord | undefined>;
  publicCouponSnapshot?(storeId: string, after: string | undefined, limit: number): Promise<StoreCouponSnapshot>;
  publicCouponSnapshotV2?(storeId: string, after: string | undefined, limit: number): Promise<VersionedStoreCouponSnapshot>;
  saveCouponV2?(command: StoreCouponV2Command): Promise<StoreCouponV2Record>;
  readCouponV2?(storeId: string, couponId: string, userId: string): Promise<VersionedStoreCouponRecord | undefined>;
  pageCouponsV2?(storeId: string, after: string | undefined, limit: number, userId: string): Promise<VersionedStoreCouponPage>;
  reconcileCouponV2?(command: StoreCouponV2Command): Promise<StoreCouponV2Record | undefined>;
  saveCouponDraft?(command: StoreCouponDraftCommand): Promise<StoreCouponDraftRecord>;
  readCouponDraft?(storeId: string, couponId: string, userId: string): Promise<StoreCouponDraftRecord | undefined>;
  pageCouponDrafts?(storeId: string, after: string | undefined, limit: number, userId: string): Promise<StoreCouponDraftPage>;
  reconcileCouponDraft?(command: StoreCouponDraftCommand): Promise<StoreCouponDraftRecord | undefined>;
  evaluateStoreCouponEligibility?(actor: string, query: StoreCouponEligibilityQuery, prices: CouponPriceSnapshot): Promise<object>;
}
interface PublicSku extends Record<string, unknown> {skuId: string; channels: Record<string, unknown>[]}
export interface PublicPromotion {
  publicationId: string; revision: number; publisherType: "retailer" | "wholesaler" | "manufacturer"; publisherId: string;
  publisherName: string; headline: string; detail: string; sourceId: string;
  observedAt: string; validUntil: string; product: PublicSku;
  benefitTerms?: PromotionBenefitTerms;
}
interface PublicPromotionPage {
  schemaVersion: 1; realm: PromotionRecord["realm"]; storeId: string; observedAt: string;
  state: "ready" | "unavailable"; coverage: "verified_public_promotions_only";
  orderingAvailable: false; items: PublicPromotion[]; nextCursor: string | null;
  promotionTermsVersion?: 1;
  supplierPublishersVersion?: 1;
}
function fail(code = "invalid_input", status = 400): never {
  throw new WorkspaceProfileError(code, "Product promotion could not be confirmed.", status);
}
function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(value))) fail();
  return value as Record<string, unknown>;
}
function exact(value: unknown, keys: string[], optional: string[] = []): Record<string, unknown> {
  const row = object(value);
  if (keys.some(k => !Object.hasOwn(row, k)) || Object.keys(row).some(k => ![...keys, ...optional].includes(k))) fail();
  return row;
}
function text(value: unknown, max: number): string {
  if (typeof value !== "string" || !value || value !== value.trim() || value.length > max ||
      /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)) fail();
  return value;
}
function id(value: unknown): string {
  const result = text(value, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u.test(result)) fail();
  return result;
}
function integer(value: unknown, minimum = 0, maximum = 1_000_000_000): number {
  if (!Number.isSafeInteger(value) || (value as number) < minimum || (value as number) > maximum) fail();
  return value as number;
}
function time(value: unknown): string {
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value)) || new Date(value).toISOString() !== value) fail();
  return value;
}
const inputKeys = ["skuId", "skuRevision", "channel", "headline", "detail", "validFrom", "validUntil", "active"];
export function promotionBenefitTerms(value: unknown): PromotionBenefitTerms {
  const row = exact(value, ["schemaVersion", "kind", "currency", "flatAmountMinor", "flatBasis", "percentageBasisPoints",
    "maximumSavingMinor", "minimumSpendMinor", "minimumQuantity"]);
  if (row.schemaVersion !== 1 || row.currency !== "INR" || typeof row.kind !== "string" || !["flat", "percentage"].includes(row.kind)) fail();
  const money = (value: unknown, minimum = 1) => value === null ? null : integer(value, minimum, 4_503_599_627_370_495);
  const flatAmountMinor = money(row.flatAmountMinor), maximumSavingMinor = money(row.maximumSavingMinor);
  const minimumSpendMinor = money(row.minimumSpendMinor, 0);
  const percentageBasisPoints = row.percentageBasisPoints === null ? null : integer(row.percentageBasisPoints, 1, 10000);
  const minimumQuantity = row.minimumQuantity === null ? null : integer(row.minimumQuantity, 1);
  if (row.kind === "flat" ? flatAmountMinor === null || percentageBasisPoints !== null ||
      typeof row.flatBasis !== "string" || !["per_pack", "per_order"].includes(row.flatBasis) : flatAmountMinor !== null || row.flatBasis !== null || percentageBasisPoints === null) fail();
  return {schemaVersion: 1, currency: "INR", kind: row.kind as PromotionBenefitTerms["kind"], flatAmountMinor,
    flatBasis: row.flatBasis as PromotionBenefitTerms["flatBasis"], percentageBasisPoints, maximumSavingMinor, minimumSpendMinor, minimumQuantity};
}
function inputFromRecord(row: Record<string, unknown>): PromotionInput {
  return input(Object.fromEntries([...inputKeys, ...(Object.hasOwn(row, "benefitTerms") ? ["benefitTerms"] : [])].map(k => [k, row[k]])));
}
function input(value: unknown): PromotionInput {
  const row = exact(value, inputKeys, ["benefitTerms"]);
  if (typeof row.channel !== "string" || !["retail", "wholesale", "bulk"].includes(row.channel) || typeof row.active !== "boolean") fail();
  const validFrom = time(row.validFrom), validUntil = time(row.validUntil);
  if (validFrom >= validUntil) fail();
  return {skuId: id(row.skuId), skuRevision: integer(row.skuRevision, 1), channel: row.channel as PromotionInput["channel"],
    headline: text(row.headline, 160), detail: text(row.detail, 2000), validFrom, validUntil, active: row.active,
    ...(Object.hasOwn(row, "benefitTerms") ? {benefitTerms: promotionBenefitTerms(row.benefitTerms)} : {})};
}
function record(value: unknown, realm: PromotionRecord["realm"], storeId: string): PromotionRecord {
  const row = exact(value, [...inputKeys, "schemaVersion", "realm", "storeId", "placementId", "revision", "observedAt"], ["benefitTerms"]);
  if (row.schemaVersion !== 1 || row.realm !== realm || row.storeId !== storeId) fail();
  return {...inputFromRecord(row), schemaVersion: 1, realm, storeId,
    placementId: id(row.placementId), revision: integer(row.revision, 1), observedAt: time(row.observedAt)};
}
function profilePublisher(profileId: string): PublicPromotion["publisherType"] | undefined {
  return profileId.startsWith("retailer-") ? "retailer" :
    profileId === "wholesaler" || profileId === "manufacturer" ? profileId : undefined;
}
function owner(profile: WorkspaceProfileRecord | undefined, storeId: string, userId?: string): WorkspaceProfileRecord {
  if (!profile || profile.schemaVersion !== 1 || profile.workspaceId !== storeId ||
      userId !== undefined && profile.ownerUserId !== userId) fail("not_found", 404);
  if (profile.familyId !== "products-trade" || !profilePublisher(profile.profileId) || profile.status !== "live") fail("invalid_state", 409);
  if (userId === undefined && profile.shopEnabled !== true) fail("not_found", 404);
  return profile;
}
const couponKeys = ["name", "percentage", "discount", "minimumSpendMinor", "maximumSavingMinor",
  "startsAt", "endsAt", "totalUses", "usesPerCustomer", "active"];
function couponInput(raw: unknown): StoreCouponInput {
  const row = exact(raw, couponKeys);
  if (typeof row.percentage !== "boolean" || typeof row.active !== "boolean") fail();
  const name = text(row.name, 80);
  if (/[\u0000-\u001f]/u.test(name)) fail();
  const discount = integer(row.discount, 1, row.percentage ? 10000 : 9_000_000_000_000);
  const maximumSavingMinor = integer(row.maximumSavingMinor, 1, 9_000_000_000_000);
  const startsAt = time(row.startsAt), endsAt = time(row.endsAt);
  const totalUses = integer(row.totalUses, 1), usesPerCustomer = integer(row.usesPerCustomer, 1);
  if (endsAt <= startsAt || !row.percentage && maximumSavingMinor !== discount || usesPerCustomer > totalUses) fail();
  return {name, percentage: row.percentage, discount,
    minimumSpendMinor: integer(row.minimumSpendMinor, 0, 9_000_000_000_000), maximumSavingMinor,
    startsAt, endsAt, totalUses, usesPerCustomer, active: row.active};
}
function couponFromRecord(raw: Record<string, unknown>): StoreCouponInput {
  return couponInput(Object.fromEntries(couponKeys.map(k => [k, raw[k]])));
}
function couponRecord(raw: unknown, realm: PromotionRecord["realm"], storeId: string): StoreCouponRecord {
  const row = exact(raw, [...couponKeys, "schemaVersion", "realm", "storeId", "couponId", "revision", "observedAt"]);
  if (row.schemaVersion !== 1 || row.realm !== realm || row.storeId !== storeId) fail();
  return {...couponFromRecord(row), schemaVersion: 1, realm, storeId, couponId: id(row.couponId),
    revision: integer(row.revision, 1), observedAt: time(row.observedAt)};
}
function couponPage(raw: StoreCouponRecord[], realm: PromotionRecord["realm"], storeId: string,
  after: string | undefined, limit: number): StoreCouponRecord[] {
  if (!Array.isArray(raw) || raw.length > limit) fail();
  const rows = raw.map(r => couponRecord(r, realm, storeId));
  let prior = after;
  for (const row of rows) {if (prior !== undefined && row.couponId <= prior) fail(); prior = row.couponId;}
  return rows;
}
function couponRequest(userId: string, realm: PromotionRecord["realm"], raw: unknown, now: string): StoreCouponCommand {
  const row = exact(raw, ["storeId", "couponId", "expectedRevision", "idempotencyKey", "coupon", "fundingAcknowledged"]);
  if (row.fundingAcknowledged !== true || !["evaluation", "production"].includes(realm)) fail();
  const facts = {ownerUserId: id(userId), realm, storeId: id(row.storeId), couponId: id(row.couponId),
    expectedRevision: integer(row.expectedRevision), coupon: couponInput(row.coupon), fundingAcknowledged: true as const};
  return {...facts, idempotencyKey: id(row.idempotencyKey), observedAt: time(now),
    fingerprint: cataloguePayloadHash({operation: "saveStoreCoupon", storeCouponTermsVersion: 1, ...facts})};
}
function originalCoupon(command: StoreCouponCommand, receipt: StoreCouponReceipt): StoreCouponRecord {
  const result = couponRecord(receipt.record, command.realm, command.storeId);
  if (receipt.fingerprint !== command.fingerprint || result.couponId !== command.couponId ||
      result.revision !== command.expectedRevision + 1 ||
      cataloguePayloadHash(couponFromRecord(result as unknown as Record<string, unknown>)) !== cataloguePayloadHash(command.coupon)) fail("conflict", 409);
  return result;
}
export function planStoreCouponSave(command: StoreCouponCommand, profile: WorkspaceProfileRecord | undefined,
  current?: StoreCouponRecord, receipt?: StoreCouponReceipt, authorizationAt = command.observedAt): StoreCouponRecord {
  owner(profile, command.storeId, command.ownerUserId);
  const checked = couponRequest(command.ownerUserId, command.realm, {
    storeId: command.storeId, couponId: command.couponId, expectedRevision: command.expectedRevision,
    idempotencyKey: command.idempotencyKey, coupon: command.coupon, fundingAcknowledged: command.fundingAcknowledged}, command.observedAt);
  if (checked.fingerprint !== command.fingerprint) fail();
  if (receipt) return originalCoupon(command, receipt);
  const prior = current && couponRecord(current, command.realm, command.storeId);
  if (prior && prior.couponId !== command.couponId || (prior?.revision ?? 0) !== command.expectedRevision ||
      command.expectedRevision >= 1_000_000_000) fail("conflict", 409);
  if (command.observedAt > time(authorizationAt)) fail();
  if (!command.coupon.active && prior) {
    if (cataloguePayloadHash({...couponFromRecord(prior as unknown as Record<string, unknown>), active: false}) !==
        cataloguePayloadHash(command.coupon)) fail("invalid_state", 409);
  } else if (!command.coupon.active || command.coupon.endsAt <= authorizationAt) fail("invalid_state", 409);
  return {...structuredClone(command.coupon), schemaVersion: 1, realm: command.realm, storeId: command.storeId,
    couponId: command.couponId, revision: command.expectedRevision + 1, observedAt: command.observedAt};
}
function checkSku(raw: unknown, storeId: string, promotion: PromotionInput): void {
  const sku = object(raw);
  if (sku.schemaVersion !== 1 || sku.storeId !== storeId || sku.skuId !== promotion.skuId ||
      sku.revision !== promotion.skuRevision || sku.publicListing !== true ||
      !Array.isArray(sku.channels) || !sku.channels.some(c => object(c).kind === promotion.channel)) fail("invalid_state", 409);
  id(sku.canonicalProductId); id(sku.verifiedPackId);
}
function request(userId: string, realm: PromotionRecord["realm"], raw: Readonly<Record<string, unknown>>, now: string, terms = false): PromotionCommand {
  const row = exact(structuredClone(raw), ["storeId", "placementId", "expectedRevision", "idempotencyKey", "promotion"]);
  const facts = {ownerUserId: id(userId), realm, storeId: id(row.storeId), placementId: id(row.placementId),
    expectedRevision: integer(row.expectedRevision), promotion: input(row.promotion)};
  if (facts.promotion.benefitTerms !== undefined && !terms) fail("unavailable", 503);
  return {...facts, idempotencyKey: id(row.idempotencyKey), fingerprint: cataloguePayloadHash(facts), observedAt: time(now),
    ...(terms ? {promotionTermsVersion: 1 as const} : {})};
}
function original(command: PromotionCommand, receipt: PromotionReceipt): PromotionRecord {
  const result = record(receipt.record, command.realm, command.storeId);
  if (receipt.fingerprint !== command.fingerprint || result.placementId !== command.placementId ||
      result.revision !== command.expectedRevision + 1 ||
      cataloguePayloadHash(inputFromRecord(result as unknown as Record<string, unknown>)) !== cataloguePayloadHash(command.promotion)) fail("conflict", 409);
  return result;
}
/** Atomic planner. Historical receipt is not current publication or renewed validity. */
export function planPromotionSave(command: PromotionCommand, profile: WorkspaceProfileRecord | undefined,
  sku: unknown, current?: PromotionRecord, receipt?: PromotionReceipt, authorizationAt = command.observedAt): PromotionRecord {
  owner(profile, command.storeId, command.ownerUserId);
  if (receipt) return original(command, receipt);
  const prior = current && record(current, command.realm, command.storeId);
  if (prior?.benefitTerms && command.promotionTermsVersion !== 1) fail("unavailable", 503);
  if (prior?.placementId !== undefined && prior.placementId !== command.placementId ||
      (prior?.revision ?? 0) !== command.expectedRevision) fail("conflict", 409);
  if (command.observedAt > time(authorizationAt)) fail();
  // Pausing an original publication must remain possible after source/expiry loss.
  if (!command.promotion.active && prior) {
    const old = inputFromRecord(prior as unknown as Record<string, unknown>);
    if (cataloguePayloadHash({...old, active: false}) !== cataloguePayloadHash(command.promotion)) fail("invalid_state", 409);
  } else {
    if (!command.promotion.active || command.promotion.validUntil <= authorizationAt) fail();
    checkSku(sku, command.storeId, command.promotion);
  }
  return {...structuredClone(command.promotion), schemaVersion: 1, realm: command.realm, storeId: command.storeId,
    placementId: command.placementId, revision: command.expectedRevision + 1, observedAt: command.observedAt};
}

export class WorkspacePromotionService {
  constructor(private readonly repository: PromotionRepository,
    private readonly catalogue: Pick<WorkspaceCatalogueService, "publicCatalogue"> & Partial<Pick<WorkspaceCatalogueService, "publicDiscovery" | "couponPriceSnapshot">>,
    private readonly now: () => Date = () => new Date(),
    private readonly options: {benefitTermsSupported?: boolean; storeCouponTermsSupported?: boolean;
      storeCouponTermsV2Supported?: boolean; storeCouponDraftsSupported?: boolean; storeCouponEligibilitySupported?: boolean} = {}) {}
  private negotiation(body: Readonly<Record<string, unknown>>) {
    const {promotionTermsVersion, supplierPublishersVersion, commodityPriceReadbackVersion, ...plain} = body;
    if (Object.hasOwn(body, "promotionTermsVersion") && promotionTermsVersion !== 1) fail();
    if (Object.hasOwn(body, "supplierPublishersVersion") && supplierPublishersVersion !== 1) fail();
    if (Object.hasOwn(body, 'commodityPriceReadbackVersion') && commodityPriceReadbackVersion !== 1) fail();
    if (promotionTermsVersion === 1 && !this.options.benefitTermsSupported) fail("unavailable", 503);
    return {body: plain, terms: promotionTermsVersion === 1, suppliers: supplierPublishersVersion === 1,
      commodity: commodityPriceReadbackVersion === 1};
  }
  /** Endpoint still performs Firebase/default-tenant/AppCheck verification. */
  async handleOperation(userId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    id(userId); body = structuredClone(body);
    const structuredCoupon = body.storeCouponTermsVersion === 2 &&
      ['saveStoreCoupon', 'readStoreCoupon', 'reconcileStoreCoupon', 'listStoreCoupons','evaluateStoreCouponEligibility'].includes(operation);
    const privateDraft = body.storeCouponDraftVersion === 1 && couponDraftOperations.includes(operation);
    if (Buffer.byteLength(JSON.stringify({operation, ...body}), "utf8") > (structuredCoupon || privateDraft ? 8 * 1024 * 1024 : 60000)) fail();
    if (couponDraftOperations.includes(operation)) return this.couponDraftOperation(userId, operation, body);
    if (operation === "evaluateStoreCouponEligibility") {
      if (!this.options.storeCouponEligibilitySupported ||
          (body.storeCouponTermsVersion===2?!this.options.storeCouponTermsV2Supported:!this.options.storeCouponTermsSupported) ||
          !this.repository.evaluateStoreCouponEligibility || !this.catalogue.couponPriceSnapshot) fail("unavailable", 503);
      return this.repository.evaluateStoreCouponEligibility(userId, couponEligibilityQuery(body, this.repository.realm),
        this.catalogue.couponPriceSnapshot.bind(this.catalogue));
    }
    if (["saveStoreCoupon", "readStoreCoupon", "listStoreCoupons", "reconcileStoreCoupon", "readPublicStoreCoupons", "readPublicStoreCouponSnapshot"].includes(operation)) {
      return this.storeCouponOperation(userId, operation, body);
    }
    const negotiated = this.negotiation(body);
    if (operation === "readPublicStorePromotions") return this.publicPage(body);
    if (operation === "readPublicPromotionDiscovery") return this.publicDiscovery(body);
    if (negotiated.suppliers || negotiated.commodity) fail(); // Read negotiation never grants owner authority.
    if (operation === "listStorePromotions") {
      const query = exact(negotiated.body, ["storeId", "limit"], ["after"]), storeId = id(query.storeId);
      const limit = integer(query.limit, 1, 20), after = query.after === undefined ? undefined : id(query.after);
      owner(await this.repository.store(storeId), storeId, userId);
      const rows = (await this.repository.page(storeId, after, limit, userId)).map(r => record(r, this.repository.realm, storeId));
      if (!negotiated.terms && rows.some(row => row.benefitTerms)) fail("unavailable", 503);
      return {schemaVersion: 1, realm: this.repository.realm, storeId, items: rows,
        nextCursor: rows.length === limit ? rows.at(-1)!.placementId : null, publicationConfirmed: false,
        ...(negotiated.terms ? {promotionTermsVersion: 1} : {})};
    }
    let result: PromotionRecord | undefined;
    if (operation === "saveStorePromotion") result = await this.save(userId, body);
    else if (operation === "readStorePromotion") result = await this.readOwned(userId, body);
    else if (operation === "reconcileStorePromotion") result = await this.reconcile(userId, body);
    else fail();
    return {schemaVersion: 1, realm: this.repository.realm, storeId: id(body.storeId),
      record: result ?? null, publicationConfirmed: false, ...(negotiated.terms ? {promotionTermsVersion: 1} : {})};
  }
  private async storeCouponOperation(userId: string, operation: string, raw: Readonly<Record<string, unknown>>): Promise<object> {
    const {storeCouponTermsVersion, ...body} = raw;
    if (storeCouponTermsVersion === 2) return this.structuredCouponOperation(userId, operation, body);
    if (storeCouponTermsVersion !== 1 || !this.options.storeCouponTermsSupported) fail("unavailable", 503);
    const storeId = id(body.storeId), repo = this.repository;
    const envelope = () => ({schemaVersion: 1, storeCouponTermsVersion: 1, realm: repo.realm,
      storeId, orderingAvailable: false, redemptionAvailable: false});
    if (operation === "saveStoreCoupon" || operation === "reconcileStoreCoupon") {
      const command = couponRequest(userId, repo.realm, body, this.now().toISOString());
      owner(await repo.store(storeId), storeId, userId);
      const action = operation === "saveStoreCoupon" ? repo.saveCoupon : repo.reconcileCoupon;
      if (!action) fail("unavailable", 503);
      const result = await action.call(repo, command);
      if (operation === "saveStoreCoupon" && !result) fail("unavailable", 503);
      return {...envelope(), record: result ? originalCoupon(command, {fingerprint: command.fingerprint, record: result}) : null,
        publicationConfirmed: false};
    }
    if (operation === "readStoreCoupon") {
      const query = exact(body, ["storeId", "couponId"]), couponId = id(query.couponId);
      owner(await repo.store(storeId), storeId, userId);
      if (!repo.readCoupon) fail("unavailable", 503);
      const result = await repo.readCoupon(storeId, couponId, userId);
      const value = result && couponRecord(result, repo.realm, storeId);
      if (value && value.couponId !== couponId) fail();
      return {...envelope(), record: value ?? null, publicationConfirmed: false};
    }
    const completeSnapshot = operation === "readPublicStoreCouponSnapshot";
    const query = completeSnapshot ? exact(body, ["storeId", "storeCouponSnapshotVersion"]) : exact(body, ["storeId", "limit"], ["after"]);
    if (completeSnapshot && query.storeCouponSnapshotVersion !== 1) fail("unavailable", 503);
    const limit = completeSnapshot ? 401 : integer(query.limit, 1, 20);
    const after = completeSnapshot || query.after === undefined ? undefined : id(query.after);
    if (operation === "listStoreCoupons") {
      if (!repo.pageCoupons) fail("unavailable", 503);
      owner(await repo.store(storeId), storeId, userId);
      const rows = couponPage(await repo.pageCoupons(storeId, after, limit, userId), repo.realm, storeId, after, limit);
      return {...envelope(), items: rows, nextCursor: rows.length === limit ? rows.at(-1)!.couponId : null,
        publicationConfirmed: false};
    }
    try {
      if (!repo.publicCouponSnapshot) fail("unavailable", 503);
      // Profile and the complete returned page come from one transaction. No
      // subsequent async enrichment can mix earlier heads with a later Store.
      const snapshot = structuredClone(await repo.publicCouponSnapshot(storeId, after, limit));
      const profile = owner(snapshot.profile, storeId);
      const observedAt = time(snapshot.observedAt), now = this.now().toISOString();
      if (observedAt > now) fail("stale_snapshot", 409);
      const rows = couponPage(snapshot.records, repo.realm, storeId, after, limit);
      if (completeSnapshot && rows.length > 400) fail("incomplete_snapshot", 503);
      const items: object[] = [];
      for (const row of rows) {
        if (row.observedAt > observedAt) fail("stale_snapshot", 409);
        if (row.active && row.startsAt > observedAt && row.startsAt <= now) fail("stale_snapshot", 409);
        if (!row.active || row.startsAt > observedAt || row.endsAt <= observedAt) continue;
        if (row.endsAt <= now) fail("stale_snapshot", 409);
        items.push({couponId: row.couponId, revision: row.revision, scope: "store_basket", storeId,
          publisherType: profilePublisher(profile.profileId)!, publisherName: text(profile.name, 240),
          terms: couponFromRecord(row as unknown as Record<string, unknown>),
          sourceId: `store-coupon:${repo.realm}:${storeId}:${row.couponId}:${row.revision}`});
      }
      return {...envelope(), state: "ready", coverage: "published_store_coupon_terms_only",
        observedAt, items, ...(completeSnapshot ? {storeCouponSnapshotVersion: 1, complete: true} :
          {nextCursor: rows.length === limit ? rows.at(-1)!.couponId : null})};
    } catch {
      return {...envelope(), state: "unavailable", coverage: "published_store_coupon_terms_only",
        observedAt: this.now().toISOString(), items: [], ...(completeSnapshot ? {storeCouponSnapshotVersion: 1, complete: false} : {nextCursor: null})};
    }
  }
  private async structuredCouponOperation(userId: string, operation: string, body: Readonly<Record<string, unknown>>): Promise<object> {
    if (!this.options.storeCouponTermsV2Supported) fail('unavailable', 503);
    if(operation==='readPublicStoreCoupons'||operation==='readPublicStoreCouponSnapshot')return this.structuredCouponPublicPage(operation,body);
    const repo = this.repository, storeId = id(body.storeId);
    owner(await repo.store(storeId), storeId, userId);
    const envelope = {schemaVersion: 1, storeCouponTermsVersion: 2, realm: repo.realm, storeId,
      orderingAvailable: false, redemptionAvailable: false, publicationConfirmed: false};
    if (operation === 'listStoreCoupons') {
      const query = exact(body, ['storeId', 'limit'], ['after']), limit = integer(query.limit, 1, 20);
      const after = query.after === undefined ? undefined : id(query.after);
      if (!repo.pageCouponsV2) fail('unavailable', 503);
      const page = await repo.pageCouponsV2(storeId, after, limit, userId);
      if (!Array.isArray(page.records) || page.records.length > limit) fail();
      const records = page.records.map(raw => raw.schemaVersion === 2 ? checkedStoreCouponV2Record(raw,
        {account: userId, realm: repo.realm, store: storeId}, this.now().toISOString()) : couponRecord(raw, repo.realm, storeId));
      let previous = after;
      for (const record of records) {if (previous !== undefined && record.couponId <= previous) fail(); previous = record.couponId;}
      if (page.nextCursor !== null && (!records.length || page.nextCursor !== previous)) fail();
      const response = {...envelope, items: records, nextCursor: page.nextCursor};
      if (Buffer.byteLength(JSON.stringify(response), 'utf8') > 8 * 1024 * 1024) fail('unavailable', 503);
      return response;
    }
    if (operation === 'readStoreCoupon') {
      const query = exact(body, ['storeId', 'couponId']);
      if (!repo.readCouponV2) fail('unavailable', 503);
      const result = await repo.readCouponV2(storeId, id(query.couponId), userId);
      const record = result && (result.schemaVersion === 2 ? checkedStoreCouponV2Record(result,
        {account: userId, realm: repo.realm, store: storeId}, this.now().toISOString()) : couponRecord(result, repo.realm, storeId));
      if (record && record.couponId !== query.couponId) fail();
      return {...envelope, record: record ?? null};
    }
    if (operation !== 'saveStoreCoupon' && operation !== 'reconcileStoreCoupon') fail('unavailable', 503);
    const command = structuredCouponRequest(userId, repo.realm, body, this.now().toISOString());
    const action = operation === 'saveStoreCoupon' ? repo.saveCouponV2 : repo.reconcileCouponV2;
    if (!action) fail('unavailable', 503);
    const result = await action.call(repo, command);
    if (!result && operation === 'saveStoreCoupon') fail('unavailable', 503);
    const record = result && checkedStoreCouponV2Record(result, {account: userId, realm: repo.realm, store: storeId}, this.now().toISOString());
    if (record && (record.couponId !== command.couponId || record.revision !== command.expectedRevision + 1 ||
        JSON.stringify(record.coupon) !== JSON.stringify(command.coupon))) fail('invalid_state', 409);
    return {...envelope, record: record ?? null};
  }
  private async structuredCouponPublicPage(operation:string,body:Readonly<Record<string,unknown>>):Promise<object>{
    const storeId=id(body.storeId),complete=operation==='readPublicStoreCouponSnapshot',
      query=complete?exact(body,['storeId','storeCouponSnapshotVersion']):exact(body,['storeId','limit'],['after']);
    if(complete&&query.storeCouponSnapshotVersion!==1)fail('unavailable',503);
    const limit=complete?401:integer(query.limit,1,20),after=complete||query.after===undefined?undefined:id(query.after),repo=this.repository,
      envelope=(observedAt:string)=>({schemaVersion:1,storeCouponTermsVersion:2,realm:repo.realm,storeId,orderingAvailable:false,
        redemptionAvailable:false,coverage:'published_store_coupon_terms_only',observedAt,...(complete?{storeCouponSnapshotVersion:1}:{})});
    try{
      if(!repo.publicCouponSnapshotV2)fail('unavailable',503);
      const deadline=this.now().getTime()+20_000,snapshot=await repo.publicCouponSnapshotV2(storeId,after,limit),
        profile=owner(snapshot.profile,storeId),observedAt=time(snapshot.observedAt),
        stable=(value:VersionedStoreCouponSnapshot)=>cataloguePayloadHash([value.profile,value.records,value.nextCursor]);
      if(observedAt>this.now().toISOString()||snapshot.records.length>limit||complete&&
        (snapshot.records.length>400||snapshot.nextCursor!==null))fail('incomplete_snapshot',503);
      let previous=after;
      const rows=snapshot.records.map(raw=>{
        const row=raw.schemaVersion===2?checkedStoreCouponV2Record(raw,{account:profile.ownerUserId,realm:repo.realm,store:storeId},this.now().toISOString()):couponRecord(raw,repo.realm,storeId);
        if(previous!==undefined&&row.couponId<=previous)fail('invalid_state',409);previous=row.couponId;return row;
      });
      if(snapshot.nextCursor!==null&&(!rows.length||snapshot.nextCursor!==previous))fail('invalid_state',409);
      const inputs=rows.map(row=>row.schemaVersion===2?row.coupon:couponFromRecord(row as unknown as Record<string,unknown>)),
        active=(input:StoreCouponV2Input|ReturnType<typeof couponFromRecord>,when:string)=>input.active&&
          storeCouponV2UtcMicros(input.startsAt)<=storeCouponV2UtcMicros(when)&&storeCouponV2UtcMicros(input.endsAt)>storeCouponV2UtcMicros(when);
      const readSku=async(skuId:string)=>{
        if(this.now().getTime()>=deadline)fail('unavailable',503);
        const data=object(await this.catalogue.publicCatalogue({storeId,skuId,listingReadbackVersion:1,
          mediaReadbackVersion:1,policyReadbackVersion:1,productFactsReadbackVersion:1,unbrandedProduceReadbackVersion:1,
          supplierPublishersVersion:1,supplierTaxReadbackVersion:1,commodityPriceReadbackVersion:1}));
        if(data.schemaVersion!==1||data.realm!==repo.realm||data.storeId!==storeId||data.state!=='ready'||
          data.coverage!=='verified_public_only'||data.orderingAvailable!==false||data.listingReadbackVersion!==1||
          data.listingCoverage!=='complete'||data.nextCursor!==null||time(data.observedAt)>this.now().toISOString()||
          !Array.isArray(data.items)||data.items.length!==1)fail('unavailable',503);
        const row=object(data.items[0]),content=object(row.content),pack=object(row.pack);
        if(row.skuId!==skuId||!Array.isArray(row.channels)||!Array.isArray(row.listings)||!row.listings.length||row.listings.length>3)fail('unavailable',503);
        const bindings=row.listings.map(value=>checkedPublicCatalogueListingBinding(value,repo.realm)),channels=row.channels.map(object);
        if(new Set(bindings.map(value=>value.channel)).size!==bindings.length||bindings.some(value=>value.storeId!==storeId||value.skuId!==skuId||
          value.canonicalProductId!==row.canonicalProductId||value.verifiedPackId!==row.verifiedPackId)||
          channels.some(value=>bindings.filter(binding=>binding.channel===value.kind).length!==1))fail('invalid_state',409);
        return {skuId,revision:integer(row.revision,1),title:text(content.title,240),variant:content.variant??'',
          sellUnit:text(pack.label,240),bindings,channels};
      };
      const sources=new Map<string,Awaited<ReturnType<typeof readSku>>>();
      const bindSku=async(sku:StoreOfferV2Sku,channels:readonly string[])=>{
        const source=sources.get(sku.skuId)??await readSku(sku.skuId);sources.set(sku.skuId,source);
        const title=source.variant===''?source.title:`${source.title} · ${text(source.variant,240)}`;
        if(sku.storeId!==storeId||sku.sellUnit!==source.sellUnit||sku.title!==title||sku.listings.some(retained=>
          !source.bindings.some(binding=>cataloguePayloadHash(binding)===cataloguePayloadHash(retained))))fail('unavailable',503);
        const listings=source.bindings.filter(binding=>channels.includes(binding.channel));
        if(!listings.length||listings.some(binding=>{
          const matches=source.channels.filter(channel=>channel.kind===binding.channel);
          return matches.length!==1||matches[0]!.priceState==='expired'||time(matches[0]!.validUntil)<=this.now().toISOString();
        }))fail('unavailable',503);
        return {...sku,listings};
      };
      const items:object[]=[];let bytes=4096;
      const add=(item:object)=>{bytes+=Buffer.byteLength(JSON.stringify(item),'utf8')+1;if(bytes>8*1024*1024)fail('unavailable',503);items.push(item);};
      for(const [index,row] of rows.entries()){
        if(row.observedAt>observedAt)fail('stale_snapshot',409);
        const input=inputs[index]!;
        if(!active(input,observedAt))continue;
        if(row.schemaVersion!==2){add({couponId:row.couponId,revision:row.revision,scope:'store_basket',storeId,
          publisherType:profilePublisher(profile.profileId)!,publisherName:text(profile.name,240),terms:input,
          sourceId:`store-coupon:${repo.realm}:${storeId}:${row.couponId}:${row.revision}`});continue;}
        const original=publicStoreOfferV2Terms(row.coupon,storeId);
        // A private customer record is not an authenticated buyer identity.
        if(original.kind==='buyerDiscount')fail('unavailable',503);
        const skus:StoreOfferV2Sku[]=[];for(const sku of original.skus)skus.push(await bindSku(sku,original.channels));
        const rewardSku=original.rewardSku===null?null:await bindSku(original.rewardSku,original.channels),
          structuredTerms=checkedStoreOfferV2Terms({...original,skus,rewardSku},storeId);
        add({schemaVersion:2,currency:'INR',realm:repo.realm,storeId,couponId:row.couponId,revision:row.revision,
          name:row.coupon.name,publisherName:text(profile.name,240),publisherType:profilePublisher(profile.profileId)!,
          sourceId:`store-offer-v2:${repo.realm}:${storeId}:${row.couponId}:${row.revision}`,observedAt,
          validFrom:row.coupon.startsAt,validUntil:row.coupon.endsAt,structuredTerms,
          configuredTotalUses:row.coupon.totalUses,configuredUsesPerCustomer:row.coupon.usesPerCustomer,viewerAccountId:null});
      }
      for(const [skuId,source] of sources)if(cataloguePayloadHash(await readSku(skuId))!==cataloguePayloadHash(source))fail('stale_snapshot',409);
      const fresh=await repo.publicCouponSnapshotV2(storeId,after,limit),now=this.now().toISOString();
      if(this.now().getTime()>=deadline||time(fresh.observedAt)>now||stable(fresh)!==stable(snapshot)||
        inputs.some(input=>active(input,observedAt)!==active(input,now)))fail('stale_snapshot',409);
      const result={...envelope(observedAt),state:'ready',items,...(complete?{complete:true}:{nextCursor:snapshot.nextCursor})};
      if(Buffer.byteLength(JSON.stringify(result),'utf8')>8*1024*1024)fail('unavailable',503);
      return result;
    }catch{return {...envelope(this.now().toISOString()),state:'unavailable',items:[],...(complete?{complete:false}:{nextCursor:null})};}
  }
  private async couponDraftOperation(userId: string, operation: string, raw: Readonly<Record<string, unknown>>): Promise<object> {
    const {storeCouponDraftVersion, ...body} = raw;
    if (storeCouponDraftVersion !== 1 || !this.options.storeCouponDraftsSupported) fail('unavailable', 503);
    const storeId = id(body.storeId), repo = this.repository;
    owner(await repo.store(storeId), storeId, userId);
    const envelope = {schemaVersion: 1, storeCouponDraftVersion: 1, accountId: userId,
      realm: repo.realm, storeId, observedAt: this.now().toISOString(), publicationConfirmed: false};
    const checked = (record: unknown) => couponDraftRecord(record, userId, repo.realm, storeId, this.now().toISOString());
    if (operation === 'readStoreCouponDraft') {
      const query = exact(body, ['storeId', 'couponId']), couponId = checkedStoreCouponDraftId(query.couponId);
      if (!repo.readCouponDraft) fail('unavailable', 503);
      const original = await repo.readCouponDraft(storeId, couponId, userId), record = original && checked(original);
      if (record && record.couponId !== couponId) fail('invalid_state', 409);
      return {...envelope, record: record ?? null};
    }
    if (operation === 'listStoreCouponDrafts') {
      const query = exact(body, ['storeId', 'limit'], ['after']), limit = integer(query.limit, 1, 20);
      const after = query.after === undefined ? undefined : text(query.after, 64);
      if (after !== undefined && !/^[a-f0-9]{64}$/u.test(after)) fail();
      if (!repo.pageCouponDrafts) fail('unavailable', 503);
      const page = await repo.pageCouponDrafts(storeId, after, limit, userId);
      if (!Array.isArray(page.records) || page.records.length > limit) fail();
      const records = page.records.map(checked);
      let prior = after;
      for (const record of records) {const key = cataloguePayloadHash([userId, record.couponId]).toLowerCase(); if (prior !== undefined && key <= prior) fail(); prior = key;}
      if (page.nextCursor !== null && (!records.length || page.nextCursor !== prior)) fail();
      const result = {...envelope, items: records, nextCursor: page.nextCursor};
      if (Buffer.byteLength(JSON.stringify(result), 'utf8') > 8 * 1024 * 1024) fail('unavailable', 503);
      return result;
    }
    const command = couponDraftRequest(userId, repo.realm, body, this.now().toISOString());
    const method = operation === 'saveStoreCouponDraft' ? repo.saveCouponDraft : repo.reconcileCouponDraft;
    if (!method) fail('unavailable', 503);
    const original = await method.call(repo, command), record = original && checked(original);
    if (operation === 'saveStoreCouponDraft' && !record) fail('unavailable', 503);
    if (record && (record.couponId !== command.couponId || record.sourceRevision !== command.expectedSourceRevision + 1 ||
        JSON.stringify(record.campaign) !== JSON.stringify(command.campaign))) fail('invalid_state', 409);
    return {...envelope, record: record ?? null};
  }
  private async command(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionCommand> {
    const n = this.negotiation(body);
    if (n.suppliers) fail();
    const command = request(userId, this.repository.realm, n.body, this.now().toISOString(), n.terms);
    owner(await this.repository.store(command.storeId), command.storeId, userId);
    return command;
  }
  async save(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionRecord> {
    return this.repository.save(await this.command(userId, body));
  }
  async reconcile(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionRecord | undefined> {
    return this.repository.reconcile(await this.command(userId, body));
  }
  async readOwned(userId: string, body: Readonly<Record<string, unknown>>): Promise<PromotionRecord | undefined> {
    const n = this.negotiation(body), query = exact(n.body, ["storeId", "placementId"]), storeId = id(query.storeId), placementId = id(query.placementId);
    if (n.suppliers) fail();
    id(userId); owner(await this.repository.store(storeId), storeId, userId);
    const result = await this.repository.read(storeId, placementId, userId);
    if (result?.benefitTerms && !n.terms) fail("unavailable", 503);
    return result && record(result, this.repository.realm, storeId);
  }
  /** Descriptive placements only. Coverage/counts do not assert platform or
   * other publisher feeds, geography, discounts, eligibility or redemption. */
  async publicDiscovery(body: Readonly<Record<string, unknown>>): Promise<object> {
    const negotiated = this.negotiation(body); body = negotiated.body;
    exact(body, ["promotionDiscoveryVersion", "query", "pageSize"], ["cursor"]);
    if (body.promotionDiscoveryVersion !== 1) fail();
    const raw = exact(body.query, ["search", "categoryId", "publisher", "supplierOnly"]);
    if (typeof raw.search !== "string" || raw.search.length > 240 || typeof raw.supplierOnly !== "boolean" ||
        raw.publisher !== null && (typeof raw.publisher !== "string" || !["retailer", "manufacturer", "wholesaler", "moolSocial"].includes(raw.publisher))) fail();
    const query = {search: raw.search.trim().toLowerCase().replace(/\s+/gu, " "), categoryId: id(raw.categoryId),
      publisher: raw.publisher, supplierOnly: raw.supplierOnly};
    const unavailable = (): never => fail("unavailable", 503);
    const publisherTypes = negotiated.suppliers ? ["retailer", "wholesaler", "manufacturer"] : ["retailer"];
    if (!this.catalogue.publicDiscovery || query.publisher !== null && !publisherTypes.includes(String(query.publisher))) unavailable();
    const pageSize = integer(body.pageSize, 1, 50);
    const coverage = {kind: "connected_publishers", publisherTypes, countBasis: "publications"};
    // Remove ONLY generated read observations. Persisted SKU observations,
    // revisions, content and validity remain part of the cohort fingerprint.
    const stableListing = (value: Record<string, unknown>) => {
      const copy = structuredClone(value); delete copy.observedAt;
      const store = copy.publicStore as Record<string, unknown> | undefined;
      if (store?.details) delete (store.details as Record<string, unknown>).observedAt;
      for (const row of copy.items as Record<string, unknown>[]) {
        if (row.supplierPolicy) delete (row.supplierPolicy as Record<string, unknown>).observedAt;
      }
      return copy;
    };
    const directory = async () => {
      const rows: Array<{channel: string; listing: Record<string, unknown>}> = [], snapshots: string[] = [];
      for (const destination of ["shop", "wholesale"]) {
        const catalogueQuery = {destination, search: "", categoryId: "all", sort: "relevance", brands: [],
          maximumPriceMinor: null, tradeType: null, listingIds: []};
        let cursor: string | undefined, snapshot: string | undefined, count = 0, complete = false;
        const cursors = new Set<string>();
        for (let pageIndex = 0; pageIndex < 11; pageIndex++) {
          const page = object(await this.catalogue.publicDiscovery!({discoveryPageVersion: 1,
            ...(negotiated.commodity ? {commodityPriceReadbackVersion: 1} : {}),
            ...(negotiated.suppliers ? {supplierPublishersVersion: 1} : {}),
            query: catalogueQuery, pageSize: 50, resultKind: "products", ...(cursor ? {cursor} : {})}));
          const metadata = object(page.page);
          if ((negotiated.suppliers ? page.supplierPublishersVersion !== 1 : Object.hasOwn(page, "supplierPublishersVersion")) ||
              page.schemaVersion !== 1 || page.discoveryPageVersion !== 1 || page.realm !== this.repository.realm ||
              page.state !== "ready" || page.coverage !== "verified_public_only" || page.directoryCoverage !== "complete_bounded" ||
              page.orderingAvailable !== false || page.resultKind !== "products" || page.requestedStore !== null ||
              time(page.observedAt) > this.now().toISOString() || cataloguePayloadHash(page.query) !== cataloguePayloadHash(catalogueQuery) ||
              !Array.isArray(page.items) || page.items.length > 50 || metadata.startIndex !== count ||
              snapshot !== undefined && metadata.snapshotId !== snapshot) unavailable();
          snapshot = text(metadata.snapshotId, 64);
          const total = integer(metadata.totalCount, 0, 500);
          for (const rawRow of page.items as unknown[]) {
            const row = exact(rawRow, ["channel", "listing"]), listing = object(row.listing);
            if (negotiated.suppliers ? listing.supplierPublishersVersion !== 1 : Object.hasOwn(listing, "supplierPublishersVersion")) unavailable();
            if (destination === "shop" ? row.channel !== "retail" : !["wholesale", "bulk"].includes(String(row.channel))) unavailable();
            id(listing.storeId);
            if (!Array.isArray(listing.items) || listing.items.length !== 1) unavailable();
            rows.push({channel: String(row.channel), listing});
          }
          const returned = (page.items as unknown[]).length;
          count += returned;
          if (count > total || count < total && returned !== 50 || rows.length > 500) unavailable();
          if (metadata.nextCursor === null) {if (count !== total) unavailable(); complete = true; break;}
          cursor = text(metadata.nextCursor, 2048);
          if (!cursors.add(cursor) || count >= total) unavailable();
        }
        if (!complete) unavailable();
        snapshots.push(snapshot!);
      }
      const stores = [...new Set(rows.map(row => id(row.listing.storeId)))].sort();
      if (stores.length > 20) unavailable();
      return {rows, stores, fingerprint: cataloguePayloadHash([snapshots, rows.map(row => ({channel: row.channel, listing: stableListing(row.listing)}))])};
    };
    type Item = {publication: PublicPromotion; listing: Record<string, unknown>};
    let nextActivation: string | undefined;
    const cohort = async (catalogue: Awaited<ReturnType<typeof directory>>) => {
      const items: Item[] = [], keys = new Set<string>();
      let scanned = 0, scannedRecords = 0;
      for (const storeId of catalogue.stores) {
        let after: string | undefined, complete = false;
        for (let pageIndex = 0; pageIndex < 26; pageIndex++) {
          const page = await this.publicPage({storeId, limit: 20, ...(after ? {after} : {}),
            ...(negotiated.commodity ? {commodityPriceReadbackVersion: 1} : {}),
            ...(negotiated.suppliers ? {supplierPublishersVersion: 1} : {}),
            ...(negotiated.terms ? {promotionTermsVersion: 1} : {})}, promotion => {
            if (++scannedRecords > 500) unavailable();
            if (promotion.active && promotion.validFrom > this.now().toISOString() &&
                (nextActivation === undefined || promotion.validFrom < nextActivation)) nextActivation = promotion.validFrom;
          });
          if (page.state !== "ready") unavailable();
          for (const publication of page.items) {
            const key = cataloguePayloadHash([storeId, publication.publicationId]);
            if (!keys.add(key) || ++scanned > 500) unavailable();
            const matches = catalogue.rows.filter(row => row.listing.storeId === storeId &&
              row.channel === publication.product.channels[0]?.kind &&
              object((row.listing.items as unknown[])[0]).skuId === publication.product.skuId);
            if (matches.length !== 1) unavailable();
            const listing = matches[0]!.listing, sku = object((listing.items as unknown[])[0]);
            const expected = structuredClone(Object.fromEntries(["skuId", "canonicalProductId", "verifiedPackId", "sku", "revision", "observedAt", "content", "pack"]
              .filter(k => Object.hasOwn(sku, k)).map(k => [k, sku[k]])));
            const actual: Record<string, unknown> = structuredClone(publication.product); delete actual.supplierPolicy; delete actual.channels;
            // publicPage's legacy static-media contract omits frameCount=1.
            const media = (actual.content as Record<string, unknown>)?.media;
            const expectedMedia = (expected.content as Record<string, unknown>)?.media;
            if (Array.isArray(media) && Array.isArray(expectedMedia)) expectedMedia.forEach((value, index) => {
              const file = (value as Record<string, any>).file, other = (media[index] as Record<string, any> | undefined)?.file;
              if (file?.frameCount === 1 && other && !Object.hasOwn(other, "frameCount")) delete file.frameCount;
            });
            const channel = (sku.channels as Record<string, unknown>[]).find(c => c.kind === publication.product.channels[0]?.kind);
            if (cataloguePayloadHash(expected) !== cataloguePayloadHash(actual) ||
                cataloguePayloadHash(channel) !== cataloguePayloadHash(publication.product.channels[0])) unavailable();
            items.push({publication, listing});
          }
          if (page.nextCursor === null) {complete = true; break;}
          if (after !== undefined && page.nextCursor <= after) unavailable();
          after = page.nextCursor;
        }
        if (!complete) unavailable();
      }
      return items;
    };
    const stableItems = (items: Item[]) => items.map(({publication, listing}) => {
      const copy = structuredClone(publication); delete (copy as Partial<PublicPromotion>).observedAt;
      if (copy.product.supplierPolicy) delete (copy.product.supplierPolicy as Record<string, unknown>).observedAt;
      return {publication: copy, listing: stableListing(listing)};
    });
    const firstDirectory = await directory(), first = await cohort(firstDirectory);
    const secondDirectory = await directory(), confirmed = await cohort(secondDirectory);
    const lastDirectory = await directory();
    if (firstDirectory.fingerprint !== secondDirectory.fingerprint || secondDirectory.fingerprint !== lastDirectory.fingerprint ||
        cataloguePayloadHash(stableItems(first)) !== cataloguePayloadHash(stableItems(confirmed))) fail("stale_snapshot", 409);
    const observedAt = this.now().toISOString();
    if (nextActivation !== undefined && nextActivation <= observedAt ||
        confirmed.some(item => item.publication.validUntil <= observedAt)) fail("stale_snapshot", 409);
    const selected = confirmed.filter(({publication, listing}) => {
      const sku = object((listing.items as unknown[])[0]), content = object(sku.content), pack = object(sku.pack);
      return (query.publisher === null || publication.publisherType === query.publisher) &&
        (query.categoryId === "all" || content.categoryId === query.categoryId) &&
        (!query.search || [publication.headline, publication.detail, content.title, content.brand, content.variant, pack.label]
          .join(" ").toLowerCase().replace(/\s+/gu, " ").includes(query.search));
    }).sort((a, b) => a.publication.publisherId.localeCompare(b.publication.publisherId) ||
      a.publication.publicationId.localeCompare(b.publication.publicationId));
    const snapshotId = cataloguePayloadHash([this.repository.realm, coverage, firstDirectory.fingerprint, stableItems(confirmed)]).toLowerCase();
    const queryHash = cataloguePayloadHash([this.repository.realm, query, coverage, ...(negotiated.terms ? [1] : []),
      ...(negotiated.suppliers ? ["supplier-publishers-v1"] : []), ...(negotiated.commodity ? ['commodity-price-v1'] : [])]).toLowerCase();
    let index = 0;
    if (body.cursor !== undefined) {
      const encoded = text(body.cursor, 2048);
      let cursor: Record<string, unknown>;
      try {cursor = exact(JSON.parse(Buffer.from(encoded, "base64url").toString("utf8")), ["v", "q", "s", "n", "i"]);} catch {fail();}
      if (Buffer.from(JSON.stringify(cursor)).toString("base64url") !== encoded || cursor.v !== 1 || cursor.q !== queryHash ||
          cursor.s !== snapshotId || cursor.n !== pageSize) fail("stale_cursor", 409);
      index = integer(cursor.i, 0, 500);
      if (index % pageSize || index >= selected.length) fail("stale_cursor", 409);
    }
    const cursorAt = (i: number) => Buffer.from(JSON.stringify({v: 1, q: queryHash, s: snapshotId, n: pageSize, i})).toString("base64url");
    const result = {schemaVersion: 1, promotionDiscoveryVersion: 1, realm: this.repository.realm, state: "ready", coverage,
      ...(negotiated.commodity ? {commodityPriceReadbackVersion: 1} : {}),
      ...(negotiated.suppliers ? {supplierPublishersVersion: 1} : {}),
      ...(negotiated.terms ? {promotionTermsVersion: 1} : {}),
      orderingAvailable: false, observedAt, query, items: selected.slice(index, index + pageSize),
      page: {snapshotId, startIndex: index, totalCount: selected.length,
        previousCursor: index === 0 ? null : cursorAt(index - pageSize),
        nextCursor: index + pageSize < selected.length ? cursorAt(index + pageSize) : null}};
    if (Buffer.byteLength(JSON.stringify(result), "utf8") > 480 * 1024) unavailable();
    return result;
  }
  async publicPage(body: Readonly<Record<string, unknown>>, observe?: (record: PromotionRecord) => void): Promise<PublicPromotionPage> {
    const negotiated = this.negotiation(body);
    const query = exact(structuredClone(negotiated.body), ["storeId", "limit"], ["after"]), storeId = id(query.storeId);
    const limit = integer(query.limit, 1, 20), after = query.after === undefined ? undefined : id(query.after);
    const base = (): Omit<PublicPromotionPage, "state" | "items" | "nextCursor"> => ({schemaVersion: 1,
      realm: this.repository.realm, storeId, observedAt: this.now().toISOString(), orderingAvailable: false,
      coverage: "verified_public_promotions_only", ...(negotiated.terms ? {promotionTermsVersion: 1} : {}),
      ...(negotiated.commodity ? {commodityPriceReadbackVersion: 1} : {}),
      ...(negotiated.suppliers ? {supplierPublishersVersion: 1} : {})});
    try {
      const initialStore = owner(await this.repository.store(storeId), storeId);
      if (!negotiated.suppliers && profilePublisher(initialStore.profileId) !== "retailer") fail("unavailable", 503);
      const rows = (await this.repository.page(storeId, after, limit)).map(r => record(r, this.repository.realm, storeId));
      const items: PublicPromotion[] = [];
      for (const promotion of rows) {
        observe?.(promotion);
        let now = this.now().toISOString();
        if (!promotion.active || promotion.observedAt > now || promotion.validFrom > now || promotion.validUntil <= now) continue;
        if (promotion.benefitTerms && !negotiated.terms) fail("unavailable", 503);
        const response = object(await this.catalogue.publicCatalogue({storeId, skuId: promotion.skuId,
          ...(negotiated.commodity ? {commodityPriceReadbackVersion: 1} : {}),
          ...(negotiated.suppliers ? {supplierPublishersVersion: 1} : {}),
          policyReadbackVersion: 1, productFactsReadbackVersion: 1, unbrandedProduceReadbackVersion: 1}));
        if ((negotiated.suppliers ? response.supplierPublishersVersion !== 1 : Object.hasOwn(response, "supplierPublishersVersion")) ||
            response.schemaVersion !== 1 || response.realm !== this.repository.realm || response.storeId !== storeId ||
            response.state !== "ready" || response.orderingAvailable !== false || response.coverage !== "verified_public_only" ||
            time(response.observedAt) > this.now().toISOString() || !Array.isArray(response.items) || response.items.length > 1) fail();
        if (!response.items.length) continue;
        const source = object(response.items[0]);
        if (source.skuId !== promotion.skuId || source.revision !== promotion.skuRevision || !Array.isArray(source.channels)) continue;
        const channels = source.channels.map(object).filter(c => c.kind === promotion.channel);
        if (channels.length !== 1) continue;
        now = this.now().toISOString();
        const validUntil = [promotion.validUntil, time(channels[0]!.validUntil)].sort()[0]!;
        if (validUntil <= now || promotion.validFrom > now) continue;
        const fresh = await this.repository.read(storeId, promotion.placementId);
        if (!fresh || cataloguePayloadHash(record(fresh, this.repository.realm, storeId)) !== cataloguePayloadHash(promotion)) continue;
        const freshStore = owner(await this.repository.store(storeId), storeId);
        const publisherType = profilePublisher(freshStore.profileId)!;
        if (!negotiated.suppliers && publisherType !== "retailer") fail("unavailable", 503);
        now = this.now().toISOString();
        if (validUntil <= now) continue;
        const product = Object.fromEntries(["skuId", "canonicalProductId", "verifiedPackId", "sku", "revision", "observedAt",
          "content", "pack", "supplierPolicy"].filter(k => Object.hasOwn(source, k)).map(k => [k, structuredClone(source[k])])) as PublicSku;
        product.channels = structuredClone(channels);
        items.push({publicationId: promotion.placementId, revision: promotion.revision, publisherType,
          publisherId: storeId, publisherName: text(freshStore.name, 240), headline: promotion.headline, detail: promotion.detail,
          sourceId: `store-promotion:${this.repository.realm}:${storeId}:${promotion.placementId}:${promotion.revision}`,
          observedAt: now, validUntil, product, ...(promotion.benefitTerms ? {benefitTerms: structuredClone(promotion.benefitTerms)} : {})});
      }
      return {...base(), state: "ready", items, nextCursor: rows.length === limit ? rows.at(-1)!.placementId : null};
    } catch {return {...base(), state: "unavailable", items: [], nextCursor: null};}
  }
}

export class FirestorePromotionRepository implements PromotionRepository {
  constructor(private readonly firestore: Firestore, readonly realm: PromotionRecord["realm"],
    private readonly now: () => Date = () => new Date(),
    private readonly bulkQuotes?: Pick<WorkspaceBulkQuoteService, 'readCouponPrices'>) {
    if (!["evaluation", "production"].includes(realm)) fail();
  }
  private root(storeId: string) {return this.firestore.collection("workspaceCatalogues").doc(this.realm).collection("stores").doc(id(storeId));}
  private profiles(storeId: string) {return this.firestore.collection("workspaceProfiles").where("workspaceId", "==", id(storeId)).limit(2);}
  private couponOrderPath(storeId: string, buyerUserId: string, purchaseId: string, storeOrderId: string) {
    return this.root(storeId).collection("storeCouponOrderUses").doc(cataloguePayloadHash([id(buyerUserId), id(purchaseId), id(storeOrderId)]));
  }
  private couponCounts(raw: unknown, storeId: string, couponId: string, buyerUserId?: string) {
    const row = exact(raw, ["schemaVersion", "realm", "storeId", "couponId", "usageRevision", "heldUses", "redeemedUses",
      ...(buyerUserId === undefined ? ["origin"] : ["buyerUserId"])]);
    if (row.schemaVersion !== 1 || row.realm !== this.realm || row.storeId !== storeId || row.couponId !== couponId ||
        buyerUserId !== undefined && row.buyerUserId !== buyerUserId) fail("invalid_state", 409);
    integer(row.usageRevision); integer(row.heldUses); integer(row.redeemedUses);
    if ((row.heldUses as number) + (row.redeemedUses as number) > 1_000_000_000) fail("invalid_state", 409);
    return row;
  }
  private async couponOrigin(tx: Transaction, storeId: string, couponId: string, usage: Record<string, unknown>) {
    const origin = exact(usage.origin, ["couponRevision", "ownerUserId", "receiptId", "requestFingerprint", "observedAt"]);
    if (origin.couponRevision !== 1) fail("invalid_state", 409);
    id(origin.ownerUserId); time(origin.observedAt);
    if (typeof origin.requestFingerprint !== "string" || !/^[A-F0-9]{64}$/u.test(origin.requestFingerprint) ||
        typeof origin.receiptId !== "string" || !/^[A-F0-9]{64}$/u.test(origin.receiptId)) fail("invalid_state", 409);
    const receipt = (await tx.get(this.root(storeId).collection("storeCouponReceipts").doc(origin.receiptId))).data();
    if (!receipt || receipt.fingerprint !== origin.requestFingerprint) fail("invalid_state", 409);
    if(receipt.schemaVersion===2)exact(receipt,['schemaVersion','fingerprint','manifest']);
    const original = receipt.schemaVersion===2?await this.structuredCouponRecord(tx,receipt.manifest,storeId,couponId,origin.ownerUserId as string):
      couponRecord(receipt.record, this.realm, storeId);
    if (original.couponId !== couponId || original.revision !== 1 || original.observedAt !== origin.observedAt) fail("invalid_state", 409);
  }
  /** Authenticated standalone replacement evaluation. Read-only: browsing must
   * neither initialize historical usage nor reserve/consume a customer's use. */
  private couponMoneySourceBindings(configuration:ReturnType<typeof couponMoneyConfiguration>,query:StoreCouponEligibilityQuery,pages:object[]){
    const terms=configuration.terms;if(terms===null)return;
    for(const line of query.lines){
      if(!terms.channels.includes(line.listing.channel))continue;
      const selected=terms.skus.find(sku=>sku.skuId===line.listing.skuId);if(!selected)continue;
      const matches=pages.flatMap(page=>object(page).items as unknown[]).map(object).filter(row=>row.skuId===selected.skuId);
      if(matches.length!==1)fail('unavailable',503);
      const source=matches[0]!,pack=object(source.pack),content=object(source.content),variant=content.variant??'',
        title=variant===''?content.title:`${text(content.title,240)} · ${text(variant,240)}`;
      if(pack.label!==selected.sellUnit||title!==selected.title||selected.listings.length&&
        !selected.listings.some(binding=>cataloguePayloadHash(binding)===cataloguePayloadHash(line.listing)))fail('conflict',409);
    }
  }
  async evaluateStoreCouponEligibility(actor: string, query: StoreCouponEligibilityQuery, prices: CouponPriceSnapshot): Promise<object> {
    actor = id(actor); query = structuredClone(query);
    return this.firestore.runTransaction(async tx => {
      const root = this.root(query.storeId), headRef = root.collection("storeCouponUsage").doc(query.couponId);
      const buyerRef = headRef.collection("customers").doc(cataloguePayloadHash(actor));
      const [profiles, campaignDoc, usageDoc, customerDoc, pages] = await Promise.all([
        tx.get(this.profiles(query.storeId)), tx.get(root.collection("storeCoupons").doc(query.couponId)),
        tx.get(headRef), tx.get(buyerRef), prices(query.storeId, [...new Set(query.lines.map(line => line.listing.skuId))].sort(), tx)]);
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const currentProfile=owner(profile, query.storeId),original=campaignDoc.get('schemaVersion')===2?
        await this.structuredCouponRecord(tx,campaignDoc.data(),query.storeId,query.couponId,currentProfile.ownerUserId):
        couponRecord(campaignDoc.data(), this.realm, query.storeId);
      if((original.schemaVersion===2)!==(query.storeCouponTermsVersion===2))fail('unavailable',503);
      if (original.couponId !== query.couponId || original.revision !== query.couponRevision) fail("conflict", 409);
      const usage = this.couponCounts(usageDoc.data(), query.storeId, query.couponId);
      await this.couponOrigin(tx, query.storeId, query.couponId, usage);
      let customerHeld = 0, customerRedeemed = 0;
      if (customerDoc.exists) {
        const customer = this.couponCounts(customerDoc.data(), query.storeId, query.couponId, actor);
        customerHeld = customer.heldUses as number; customerRedeemed = customer.redeemedUses as number;
      } else if (!(await tx.get(buyerRef.collection("orders").limit(1))).empty) fail("invalid_state", 409);
      if (query.supplierQuote && !this.bulkQuotes) fail('unavailable', 503);
      const negotiated = query.supplierQuote ? await this.bulkQuotes!.readCouponPrices(tx, actor, query.storeId,
        query.supplierQuote, query.lines.filter(l => l.listing.channel === 'bulk' &&
          (query.commodityPriceReadbackVersion !== 1 || query.supplierQuote!.lines.some(b => b.lineId === l.lineId)))) : undefined;
      const now = this.now().toISOString(), basket = couponBasketFromPrices(query, pages, this.realm, actor, now, negotiated),
        configuration=couponMoneyConfiguration(original,this.realm,query.storeId,currentProfile.ownerUserId,now),campaign=configuration.coupon;
      this.couponMoneySourceBindings(configuration,query,pages);
      if (campaign.observedAt > now) fail("unavailable", 503);
      const subtotal = basket.lines.filter(line=>couponMoneyLine(configuration,query.storeId,line))
        .reduce((sum, line) => sum + BigInt(line.quantity) * BigInt(line.unitPriceMinor), 0n);
      const reason = !couponMoneyActive(configuration,now) ? "inactive" :
        (usage.heldUses as number) + (usage.redeemedUses as number) >= campaign.totalUses ||
          customerHeld + customerRedeemed >= campaign.usesPerCustomer ? "usage_limit" :
          subtotal < BigInt(campaign.minimumSpendMinor) ? "minimum_spend" :
            subtotal === 0n || campaign.percentage && subtotal * BigInt(campaign.discount) / 10000n === 0n ? "zero_saving" : null;
      // This is a replacement scenario, not an assertion about the client's
      // currently selected platform/Store coupons. Apply/quote must enforce it.
      const evaluation = reason === null ? evaluateStoreCouponBasket(original, profile, basket, now) : null;
      // The existing price-context protocol has millisecond TTLs. Clip its
      // derived authorisation conservatively; retain literal v2 terms intact.
      const end=reason!==null?basket.validUntil:configuration.terms===null?campaign.endsAt:new Date(Date.parse(campaign.endsAt)).toISOString(),
        expires = reason === null && end < basket.validUntil ? end : basket.validUntil;
      if(expires<=now)fail('conflict',409);
      return {schemaVersion: 1, storeCouponEligibilityVersion: query.commodityPriceReadbackVersion === 1 ? 3 : query.supplierQuote ? 2 : 1, realm: this.realm,
        viewerUserId: actor, storeId: query.storeId, selectionPolicy: query.selectionPolicy,
        exclusiveSelectionRequired: true, state: "ready", eligible: evaluation !== null, reason,
        observedAt: now, validUntil: expires,
        requestFingerprint: cataloguePayloadHash({operation: query.commodityPriceReadbackVersion === 1 ? "storeCouponEligibilityV3" : query.supplierQuote ? "storeCouponEligibilityV2" : "storeCouponEligibilityV1", realm: this.realm, actor,
          query, exclusiveSelectionRequired: true}),
        orderingAvailable: false, reservationCreated: false, evaluation,
        ...(query.storeCouponTermsVersion===2?{storeCouponTermsVersion:2}:{}),
        attribution: evaluation ? storeCouponAttributionReferences(this.realm, query.storeId, campaign.couponId, campaign.revision) : null,
        ...(query.supplierQuote ? {supplierQuote: structuredClone(query.supplierQuote)} : {})};
    });
  }
  /** Internal purchase-materializer participant. No independent hold endpoint.
   * Reads all Stores first, then stages capacity/hold writes in its purchase tx. */
  async prepareCouponHolds(tx: Transaction, context: PurchaseCouponTransactionContext): Promise<() => void> {
    const writes: (() => void)[] = [];
    const finalChecks: ((now: string) => void)[] = [];
    const receipt = context.receipt;
    if (receipt.realm !== this.realm || !receipt.couponUseContext) fail("invalid_state", 409);
    for (const selection of receipt.couponUseContext.stores) {
      const store = receipt.stores.find(s => s.storeId === selection.storeId);
      const allocated = context.orders.find(s => s.storeId === selection.storeId);
      if (!store || !allocated) fail("invalid_state", 409);
      const root = this.root(store.storeId), headRef = root.collection("storeCouponUsage").doc(selection.couponId);
      const buyerRef = headRef.collection("customers").doc(cataloguePayloadHash(receipt.buyerUserId));
      const holdRef = this.couponOrderPath(store.storeId, receipt.buyerUserId, context.purchaseId, allocated.orderId);
      const [campaignDoc, usageDoc, buyerDoc, holdDoc, profiles] = await Promise.all([
        tx.get(root.collection("storeCoupons").doc(selection.couponId)), tx.get(headRef), tx.get(buyerRef), tx.get(holdRef), tx.get(this.profiles(store.storeId))]);
      if (holdDoc.exists) fail("conflict", 409); // Exact placement replay returns before this participant.
      const usage = this.couponCounts(usageDoc.data(), store.storeId, selection.couponId);
      await this.couponOrigin(tx, store.storeId, selection.couponId, usage);
      let customer: Record<string, unknown>;
      if (buyerDoc.exists) customer = this.couponCounts(buyerDoc.data(), store.storeId, selection.couponId, receipt.buyerUserId);
      else {
        if (!(await tx.get(buyerRef.collection("orders").limit(1))).empty) fail("invalid_state", 409);
        customer = {schemaVersion: 1, realm: this.realm, storeId: store.storeId, couponId: selection.couponId,
          buyerUserId: receipt.buyerUserId, usageRevision: 0, heldUses: 0, redeemedUses: 0};
      }
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const original=campaignDoc.get('schemaVersion')===2?await this.structuredCouponRecord(tx,campaignDoc.data(),store.storeId,selection.couponId,
        owner(profile,store.storeId).ownerUserId):couponRecord(campaignDoc.data(),this.realm,store.storeId),
        now=this.now().toISOString(),configuration=couponMoneyConfiguration(original,this.realm,store.storeId,profile?.ownerUserId??'',now),
        campaign=configuration.coupon;
      const basket = selection.basket as unknown as StoreCouponBasket;
      if (basket.schemaVersion === 2) {
        const binding = couponSupplierQuote(basket.supplierQuote), agreed = store.supplierQuote;
        if (!agreed || cataloguePayloadHash(binding) !== cataloguePayloadHash({schemaVersion: 1, quoteId: agreed.quoteId,
          acceptedRevision: agreed.acceptedRevision, agreementFingerprint: agreed.agreementFingerprint, lines: agreed.lines}) ||
          basket.validUntil > agreed.validUntil) fail('invalid_state', 409);
      } else if (store.supplierQuote && basket.lines?.some(l => l.channel === 'bulk')) fail('invalid_state', 409);
      if (basket.realm !== this.realm || basket.storeId !== store.storeId || basket.buyerUserId !== receipt.buyerUserId ||
          basket.couponRevision !== selection.couponRevision || campaign.couponId !== selection.couponId ||
          !Array.isArray(basket.lines) || basket.lines.length !== store.lines.length) fail("invalid_state", 409);
      const component = store.benefitAttribution?.components.find(c => c.componentId === selection.componentId);
      const attribution = storeCouponAttributionReferences(this.realm, store.storeId, campaign.couponId, campaign.revision);
      if (!component || component.benefitId !== campaign.couponId || component.label !== campaign.name ||
          component.benefitRevision !== attribution.benefitRevision || component.sourceReference !== attribution.sourceReference ||
          component.funderReference !== attribution.funderReference ||
          component.publisherType !== "supplier" || component.effect !== "instant_discount" || component.amountBasis !== "applied") fail("invalid_state", 409);
      for (const line of basket.lines) {
        const placed = store.lines.find(l => l.sourceLineId === line.lineId);
        const otherCoupon = store.benefitAttribution!.components.some(c => c.componentId !== component.componentId &&
          c.effect === "instant_discount" && c.amountBasis === "applied" && c.allocations.some(a => a.lineId === line.lineId && a.amountMinor > 0));
        if (!placed || !placed.publicListing || line.storeId !== store.storeId || line.skuId !== placed.skuId ||
            line.packId !== placed.verifiedPackId || line.offerId !== placed.offerId || String(line.offerRevision) !== placed.offerRevision ||
            line.channel !== placed.publicListing.channel || line.quantity * 1000 !== placed.quantityMilli ||
            line.unitPriceMinor !== placed.unitPriceMinor || line.quantity * line.unitPriceMinor !== placed.lineTotalMinor ||
            line.otherCouponApplied !== otherCoupon) fail("invalid_state", 409);
        if(configuration.terms!==null&&couponMoneyLine(configuration,store.storeId,line)){
          const selected=configuration.terms.skus.find(sku=>sku.skuId===line.skuId),
            title=placed.variant?`${placed.name} · ${placed.variant}`:placed.name;
          if(selected&&(selected.sellUnit!==placed.packLabel||selected.title!==title||selected.listings.length&&
            !selected.listings.some(binding=>cataloguePayloadHash(binding)===cataloguePayloadHash(placed.publicListing))))fail('invalid_state',409);
        }
      }
      const evaluation = evaluateStoreCouponBasket(original, profile, basket, now);
      if (evaluation.savingMinor !== component.amountMinor || component.allocations.length !== evaluation.allocations.filter(a => a.savingMinor > 0).length ||
          evaluation.allocations.some(a => a.savingMinor > 0 && !component.allocations.some(p => p.lineId === a.lineId && p.amountMinor === a.savingMinor))) fail("invalid_state", 409);
      if ((usage.heldUses as number) + (usage.redeemedUses as number) >= campaign.totalUses ||
          (customer.heldUses as number) + (customer.redeemedUses as number) >= campaign.usesPerCustomer) fail("conflict", 409);
      const holdUntil = time(selection.holdUntil);
      if (holdUntil <= now) fail("invalid_state", 409);
      const current: StoreCouponUse = {schemaVersion: 1, realm: this.realm, storeId: store.storeId,
        buyerUserId: receipt.buyerUserId, couponId: campaign.couponId, couponRevision: campaign.revision,
        purchaseId: context.purchaseId, storeOrderId: allocated.orderId, basketFingerprint: evaluation.basketFingerprint,
        savingMinor: evaluation.savingMinor, revision: 1, state: "held", heldAt: now, holdUntil,
        lifecycleSourceId: id(selection.lifecycleSourceId), lastSourceRevision: 0, lastObservedAt: now, fulfilmentStarted: false};
      const mapped = evaluation.allocations.map(a => ({...a, lineId: allocated.lines.find(l => l.sourceLineId === a.lineId)!.lineId}));
      finalChecks.push(finalNow => {
        evaluateStoreCouponBasket(original, profile, basket, finalNow);
        if (holdUntil <= finalNow) fail("invalid_state", 409);
        current.heldAt = finalNow; current.lastObservedAt = finalNow;
      });
      const next = (counts: Record<string, unknown>) => ({...counts, heldUses: (counts.heldUses as number) + 1,
        usageRevision: integer(counts.usageRevision, 0, 999_999_999) + 1});
      writes.push(() => {
        tx.create(holdRef, {schemaVersion: 1, original: current, current, evaluation: {...evaluation, allocations: mapped}});
        tx.set(headRef, next(usage)); tx.set(buyerRef, next(customer));
        tx.create(buyerRef.collection("orders").doc(holdRef.id), {purchaseId: context.purchaseId, orderId: allocated.orderId});
      });
    }
    return () => {
      const finalNow = this.now().toISOString();
      for (const check of finalChecks) check(finalNow);
      for (const write of writes) write();
    };
  }
  /** Called only by verified internal lifecycle production; never dispatched by
   * handleOperation. Original event replay never rewrites current/counters. */
  async applyCouponUseEvent(event: StoreCouponUseEvent): Promise<StoreCouponUseReceipt> {
    event = structuredClone(event);
    if (event.realm !== this.realm || time(event.observedAt) > this.now().toISOString()) fail();
    const holdRef = this.couponOrderPath(event.storeId, event.buyerUserId, event.purchaseId, event.storeOrderId);
    const eventRef = holdRef.collection("events").doc(cataloguePayloadHash([event.sourceId, event.eventId]));
    const headRef = this.root(event.storeId).collection("storeCouponUsage").doc(id(event.couponId));
    const buyerRef = headRef.collection("customers").doc(cataloguePayloadHash(event.buyerUserId));
    return this.firestore.runTransaction(async tx => {
      const [holdDoc, eventDoc, headDoc, buyerDoc] = await Promise.all([tx.get(holdRef), tx.get(eventRef), tx.get(headRef), tx.get(buyerRef)]);
      const held = exact(holdDoc.data(), ["schemaVersion", "original", "current", "evaluation"]);
      if (held.schemaVersion !== 1) fail("invalid_state", 409);
      const current = held.current as StoreCouponUse, original = held.original as StoreCouponUse;
      for (const key of ["schemaVersion", "realm", "storeId", "buyerUserId", "couponId", "couponRevision", "purchaseId",
        "storeOrderId", "basketFingerprint", "savingMinor", "heldAt", "holdUntil", "lifecycleSourceId"] as const) {
        if (current[key] !== original[key]) fail("invalid_state", 409);
      }
      const next = planStoreCouponUseEvent(current, event, eventDoc.exists ? eventDoc.data() as StoreCouponUseReceipt : undefined);
      if (eventDoc.exists) return next;
      const head = this.couponCounts(headDoc.data(), event.storeId, event.couponId);
      const customer = this.couponCounts(buyerDoc.data(), event.storeId, event.couponId, event.buyerUserId);
      await this.couponOrigin(tx, event.storeId, event.couponId, head);
      const heldDelta = Number(next.record.state === "held") - Number(current.state === "held");
      const consumedDelta = Number(next.record.state === "consumed") - Number(current.state === "consumed");
      const update = (counts: Record<string, unknown>) => ({...counts,
        heldUses: integer((counts.heldUses as number) + heldDelta),
        redeemedUses: integer((counts.redeemedUses as number) + consumedDelta),
        usageRevision: integer(counts.usageRevision, 0, 999_999_999) + 1});
      tx.set(headRef, update(head)); tx.set(buyerRef, update(customer));
      tx.update(holdRef, {current: next.record}); tx.create(eventRef, next);
      return next;
    });
  }
  async store(storeId: string): Promise<WorkspaceProfileRecord | undefined> {
    const result = await this.profiles(storeId).get();
    return result.size === 1 && result.docs[0]!.id === result.docs[0]!.get("caseId") ? result.docs[0]!.data() as WorkspaceProfileRecord : undefined;
  }
  async save(command: PromotionCommand): Promise<PromotionRecord> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    const root = this.root(command.storeId), head = root.collection("promotions").doc(id(command.placementId));
    const receiptRef = root.collection("promotionReceipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    return this.firestore.runTransaction(async transaction => {
      const [profiles, current, receipt] = await Promise.all([transaction.get(this.profiles(command.storeId)), transaction.get(head), transaction.get(receiptRef)]);
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const sku = receipt.exists ? undefined : (await transaction.get(root.collection("skus").doc(id(command.promotion.skuId)))).data();
      const result = planPromotionSave(command, profile, sku, current.exists ? current.data() as PromotionRecord : undefined,
        receipt.exists ? receipt.data() as PromotionReceipt : undefined, this.now().toISOString());
      if (!receipt.exists) {
        transaction.set(head, result);
        transaction.create(head.collection("revisions").doc(String(result.revision)), result);
        transaction.create(receiptRef, {fingerprint: command.fingerprint, record: result});
      }
      return result;
    });
  }
  async read(storeId: string, placementId: string, userId?: string): Promise<PromotionRecord | undefined> {
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      const result = await transaction.get(this.root(storeId).collection("promotions").doc(id(placementId)));
      if (!result.exists) return undefined;
      const value = record(result.data(), this.realm, storeId);
      if (value.placementId !== placementId) fail();
      if (userId === undefined) {
        const sku = await transaction.get(this.root(storeId).collection("skus").doc(value.skuId));
        checkSku(sku.data(), storeId, value);
      }
      return value;
    });
  }
  async page(storeId: string, after: string | undefined, limit: number, userId?: string): Promise<PromotionRecord[]> {
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      let query = this.root(storeId).collection("promotions").orderBy(FieldPath.documentId()).limit(integer(limit, 1, 20));
      if (after !== undefined) query = query.startAfter(id(after));
      const result = await transaction.get(query);
      return result.docs.map(d => {const value = record(d.data(), this.realm, storeId); if (value.placementId !== d.id) fail(); return value;});
    });
  }
  async reconcile(command: PromotionCommand): Promise<PromotionRecord | undefined> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    return this.firestore.runTransaction(async transaction => {
      const [profiles, receipt] = await Promise.all([transaction.get(this.profiles(command.storeId)),
        transaction.get(this.root(command.storeId).collection("promotionReceipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey])))]);
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        command.storeId, command.ownerUserId);
      return receipt.exists ? original(command, receipt.data() as PromotionReceipt) : undefined;
    });
  }
  async saveCoupon(command: StoreCouponCommand): Promise<StoreCouponRecord> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    const root = this.root(command.storeId), head = root.collection("storeCoupons").doc(id(command.couponId));
    const receiptRef = root.collection("storeCouponReceipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey]));
    const usageRef = root.collection("storeCouponUsage").doc(command.couponId);
    return this.firestore.runTransaction(async transaction => {
      const [profiles, current, receipt, usage] = await Promise.all([transaction.get(this.profiles(command.storeId)),
        transaction.get(head), transaction.get(receiptRef), transaction.get(usageRef)]);
      const profile = profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined;
      const result = planStoreCouponSave(command, profile, current.exists ? current.data() as StoreCouponRecord : undefined,
        receipt.exists ? receipt.data() as StoreCouponReceipt : undefined, this.now().toISOString());
      if (!receipt.exists) {
        if (!current.exists) {
          // Initialization provenance only, not remaining capacity or funding.
          // A missing historical origin is never silently backfilled on edit.
          if (usage.exists) fail("invalid_state", 409);
          transaction.create(usageRef, {schemaVersion: 1, realm: this.realm,
            storeId: command.storeId, couponId: command.couponId, usageRevision: 0,
            heldUses: 0, redeemedUses: 0, origin: {couponRevision: 1,
              ownerUserId: command.ownerUserId, receiptId: receiptRef.id,
              requestFingerprint: command.fingerprint, observedAt: command.observedAt}});
        }
        transaction.set(head, result);
        transaction.create(head.collection("revisions").doc(String(result.revision)), result);
        transaction.create(receiptRef, {fingerprint: command.fingerprint, record: result});
      }
      return result;
    });
  }
  async readCoupon(storeId: string, couponId: string, userId?: string): Promise<StoreCouponRecord | undefined> {
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        storeId, userId);
      const snapshot = await transaction.get(this.root(storeId).collection("storeCoupons").doc(id(couponId)));
      if (!snapshot.exists) return undefined;
      const result = couponRecord(snapshot.data(), this.realm, storeId);
      if (result.couponId !== couponId) fail();
      return result;
    });
  }
  private async couponSnapshot(storeId: string, after: string | undefined, limit: number, userId?: string): Promise<StoreCouponSnapshot> {
    // Only the internal complete public read may request its overflow sentinel.
    const boundedLimit = limit === 401 && after === undefined && userId === undefined ? 401 : integer(limit, 1, 20);
    return this.firestore.runTransaction(async transaction => {
      const profiles = await transaction.get(this.profiles(storeId));
      const profile = owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        storeId, userId);
      let query = this.root(storeId).collection("storeCoupons").orderBy(FieldPath.documentId()).limit(boundedLimit);
      if (after !== undefined) query = query.startAfter(id(after));
      const snapshot = await transaction.get(query);
      const records = snapshot.docs.map(d => {const value = couponRecord(d.data(), this.realm, storeId); if (value.couponId !== d.id) fail(); return value;});
      return {profile: structuredClone(profile), records, observedAt: this.now().toISOString()};
    });
  }
  async pageCoupons(storeId: string, after: string | undefined, limit: number, userId?: string): Promise<StoreCouponRecord[]> {
    integer(limit, 1, 20);
    return (await this.couponSnapshot(storeId, after, limit, userId)).records;
  }
  async publicCouponSnapshot(storeId: string, after: string | undefined, limit: number): Promise<StoreCouponSnapshot> {
    return this.couponSnapshot(storeId, after, limit);
  }
  async reconcileCoupon(command: StoreCouponCommand): Promise<StoreCouponRecord | undefined> {
    command = structuredClone(command);
    if (command.realm !== this.realm) fail();
    return this.firestore.runTransaction(async transaction => {
      const [profiles, receipt] = await Promise.all([transaction.get(this.profiles(command.storeId)),
        transaction.get(this.root(command.storeId).collection("storeCouponReceipts").doc(cataloguePayloadHash([command.ownerUserId, command.idempotencyKey])))]);
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get("caseId") ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        command.storeId, command.ownerUserId);
      return receipt.exists ? originalCoupon(command, receipt.data() as StoreCouponReceipt) : undefined;
    });
  }
  /** Literal input pages preserve native pending fingerprints across Firestore's
   * map-key ordering. Immutable revision pages and the receipt commit atomically. */
  private couponPayload(value: unknown) {
    const literal = JSON.stringify(value);
    if (typeof literal !== 'string') fail();
    const payloadBytes = Buffer.byteLength(literal, 'utf8');
    if (payloadBytes > 8 * 1024 * 1024) fail();
    const pages: string[] = [];
    for (let start = 0; start < literal.length;) {
      let end = Math.min(start + 65536, literal.length);
      if (end < literal.length && /[\uD800-\uDBFF]/u.test(literal[end - 1]!)) end--;
      pages.push(literal.slice(start, end)); start = end;
    }
    if (!pages.length || pages.length > 128) fail();
    return {pages, payloadBytes, payloadHash: cataloguePayloadHash(literal)};
  }
  private async couponLiteral(tx: Transaction, revisionRef: DocumentReference, manifest: Record<string, unknown>): Promise<unknown> {
    const original = await tx.get(revisionRef);
    if (!original.exists || cataloguePayloadHash(original.data()) !== cataloguePayloadHash(manifest)) fail('invalid_state', 409);
    const pages = await Promise.all(Array.from({length: manifest.pageCount as number}, (_, index) =>
      tx.get(revisionRef.collection('payloadPages').doc(String(index)))));
    let literal = '';
    for (const [index, page] of pages.entries()) {
      if (!page.exists) fail('invalid_state', 409);
      const row = exact(page.data(), ['schemaVersion', 'index', 'text']);
      if (row.schemaVersion !== 1 || row.index !== index || typeof row.text !== 'string' || row.text.length > 65536) fail('invalid_state', 409);
      literal += row.text;
    }
    if (Buffer.byteLength(literal, 'utf8') !== manifest.payloadBytes || cataloguePayloadHash(literal) !== manifest.payloadHash) fail('invalid_state', 409);
    try {return JSON.parse(literal);} catch {fail('invalid_state', 409);}
  }
  private structuredCouponManifest(raw: unknown, storeId: string, couponId: string) {
    const row = exact(raw, ['schemaVersion', 'storeCouponTermsVersion', 'realm', 'storeId', 'couponId',
      'revision', 'observedAt', 'payloadHash', 'payloadBytes', 'pageCount']);
    if (row.schemaVersion !== 2 || row.storeCouponTermsVersion !== 2 || row.realm !== this.realm ||
        row.storeId !== storeId || row.couponId !== couponId || typeof row.payloadHash !== 'string' ||
        !/^[a-f0-9]{64}$/iu.test(row.payloadHash)) fail('invalid_state', 409);
    integer(row.revision, 1, 1_000_000_000); integer(row.payloadBytes, 1, 8 * 1024 * 1024);
    integer(row.pageCount, 1, 128);
    if (time(row.observedAt) > this.now().toISOString()) fail('invalid_state', 409);
    return row;
  }
  private async structuredCouponRecord(tx: Transaction, raw: unknown, storeId: string, couponId: string,
    userId: string): Promise<StoreCouponV2Record> {
    const manifest = this.structuredCouponManifest(raw, storeId, couponId);
    const revisionRef = this.root(storeId).collection('storeCoupons').doc(couponId)
      .collection('revisions').doc(String(manifest.revision));
    const input = await this.couponLiteral(tx, revisionRef, manifest);
    return checkedStoreCouponV2Record({schemaVersion: 2, storeCouponTermsVersion: 2,
      accountId: userId, realm: this.realm, storeId, couponId, revision: manifest.revision,
      observedAt: manifest.observedAt, coupon: checkedStoreCouponV2Input(input, storeId)},
    {account: userId, realm: this.realm, store: storeId}, this.now().toISOString());
  }
  private async originalStructuredCoupon(tx: Transaction, command: StoreCouponV2Command, raw: unknown) {
    const receipt = exact(raw, ['schemaVersion', 'fingerprint', 'manifest']);
    if (receipt.schemaVersion !== 2 || receipt.fingerprint !== command.fingerprint) fail('conflict', 409);
    const record = await this.structuredCouponRecord(tx, receipt.manifest, command.storeId, command.couponId, command.ownerUserId);
    if (record.revision !== command.expectedRevision + 1 || JSON.stringify(record.coupon) !== JSON.stringify(command.coupon)) fail('invalid_state', 409);
    return record;
  }
  async saveCouponV2(command: StoreCouponV2Command): Promise<StoreCouponV2Record> {
    command = checkedStructuredCouponCommand(structuredClone(command));
    if (command.realm !== this.realm) fail();
    checkedStoreCouponV2Input(command.coupon, command.storeId);
    const root = this.root(command.storeId), head = root.collection('storeCoupons').doc(id(command.couponId));
    const receiptRef = root.collection('storeCouponReceipts').doc(cataloguePayloadHash([id(command.ownerUserId), id(command.idempotencyKey)]));
    const usageRef = root.collection('storeCouponUsage').doc(command.couponId);
    return this.firestore.runTransaction(async tx => {
      const [profiles, current, receipt, usage] = await Promise.all([tx.get(this.profiles(command.storeId)),
        tx.get(head), tx.get(receiptRef), tx.get(usageRef)]);
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        command.storeId, command.ownerUserId);
      if (receipt.exists) return this.originalStructuredCoupon(tx, command, receipt.data());
      const previous = current.exists ? current.get('schemaVersion') === 2 ?
        await this.structuredCouponRecord(tx, current.data(), command.storeId, command.couponId, command.ownerUserId) :
        couponRecord(current.data(), this.realm, command.storeId) : undefined;
      if (previous && previous.couponId !== command.couponId || (previous?.revision ?? 0) !== command.expectedRevision) fail('conflict', 409);
      const observedAt = this.now().toISOString();
      if (command.observedAt > observedAt) fail();
      if (!command.coupon.active && (!previous || previous.schemaVersion !== 2 ||
          cataloguePayloadHash({...previous.coupon, active: false}) !== cataloguePayloadHash(command.coupon))) fail('invalid_state', 409);
      validateStoreCouponV2ForSave(command.coupon, observedAt);
      const {pages, payloadBytes, payloadHash} = this.couponPayload(command.coupon);
      const manifest = {schemaVersion: 2, storeCouponTermsVersion: 2, realm: this.realm, storeId: command.storeId,
        couponId: command.couponId, revision: command.expectedRevision + 1, observedAt,
        payloadHash, payloadBytes, pageCount: pages.length};
      const version = head.collection('revisions').doc(String(manifest.revision));
      if (!current.exists) {
        if (usage.exists) fail('invalid_state', 409);
        tx.create(usageRef, {schemaVersion: 1, realm: this.realm, storeId: command.storeId, couponId: command.couponId,
          usageRevision: 0, heldUses: 0, redeemedUses: 0, origin: {couponRevision: 1, ownerUserId: command.ownerUserId,
            receiptId: receiptRef.id, requestFingerprint: command.fingerprint, observedAt}});
      }
      tx.set(head, manifest); tx.create(version, manifest);
      for (const [index, text] of pages.entries()) tx.create(version.collection('payloadPages').doc(String(index)), {schemaVersion: 1, index, text});
      tx.create(receiptRef, {schemaVersion: 2, fingerprint: command.fingerprint, manifest});
      return checkedStoreCouponV2Record({schemaVersion: 2, storeCouponTermsVersion: 2, accountId: command.ownerUserId,
        realm: this.realm, storeId: command.storeId, couponId: command.couponId, revision: manifest.revision,
        observedAt, coupon: command.coupon}, {account: command.ownerUserId, realm: this.realm, store: command.storeId}, observedAt);
    });
  }
  async readCouponV2(storeId: string, couponId: string, userId: string): Promise<VersionedStoreCouponRecord | undefined> {
    id(couponId); id(userId);
    return this.firestore.runTransaction(async tx => {
      const profiles = await tx.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      const snapshot = await tx.get(this.root(storeId).collection('storeCoupons').doc(couponId));
      if (!snapshot.exists) return undefined;
      const record = snapshot.get('schemaVersion') === 2 ? await this.structuredCouponRecord(tx, snapshot.data(), storeId, couponId, userId) : couponRecord(snapshot.data(), this.realm, storeId);
      if (record.couponId !== couponId) fail('invalid_state', 409);
      return record;
    });
  }
  async pageCouponsV2(storeId: string, after: string | undefined, limit: number, userId: string): Promise<VersionedStoreCouponPage> {
    id(userId); integer(limit, 1, 20); if (after !== undefined) id(after);
    return this.firestore.runTransaction(async tx => {
      const profiles = await tx.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      let query = this.root(storeId).collection('storeCoupons').orderBy(FieldPath.documentId()).limit(limit + 1);
      if (after !== undefined) query = query.startAfter(after);
      const snapshot = await tx.get(query), records: VersionedStoreCouponRecord[] = [];
      let bytes = 4096; // Envelope/cursor allowance; includes every returned record.
      for (const doc of snapshot.docs.slice(0, limit)) {
        const record = doc.get('schemaVersion') === 2 ? await this.structuredCouponRecord(tx, doc.data(), storeId, doc.id, userId) : couponRecord(doc.data(), this.realm, storeId);
        if (record.couponId !== doc.id) fail('invalid_state', 409);
        const size = Buffer.byteLength(JSON.stringify(record), 'utf8') + 1;
        if (bytes + size > 8 * 1024 * 1024) {if (!records.length) fail('unavailable', 503); break;}
        records.push(record); bytes += size;
      }
      return {records, nextCursor: snapshot.docs.length > records.length ? records.at(-1)!.couponId : null};
    });
  }
  async publicCouponSnapshotV2(storeId: string, after: string | undefined, limit: number): Promise<VersionedStoreCouponSnapshot> {
    integer(limit,1,401);if(after!==undefined)id(after);
    return this.firestore.runTransaction(async tx=>{
      const profiles=await tx.get(this.profiles(storeId)),profile=owner(profiles.size===1&&profiles.docs[0]!.id===profiles.docs[0]!.get('caseId')?
        profiles.docs[0]!.data() as WorkspaceProfileRecord:undefined,storeId);
      let query=this.root(storeId).collection('storeCoupons').orderBy(FieldPath.documentId()).limit(limit+1);
      if(after!==undefined)query=query.startAfter(after);
      const snapshot=await tx.get(query),records:VersionedStoreCouponRecord[]=[];let bytes=4096;
      for(const doc of snapshot.docs.slice(0,limit)){
        const record=doc.get('schemaVersion')===2?await this.structuredCouponRecord(tx,doc.data(),storeId,doc.id,profile.ownerUserId):
          couponRecord(doc.data(),this.realm,storeId);
        if(record.couponId!==doc.id)fail('invalid_state',409);
        bytes+=Buffer.byteLength(JSON.stringify(record),'utf8')+1;
        if(bytes>8*1024*1024)fail('unavailable',503);
        records.push(record);
      }
      return {profile:structuredClone(profile),records,observedAt:this.now().toISOString(),
        nextCursor:snapshot.docs.length>records.length?records.at(-1)!.couponId:null};
    });
  }
  async reconcileCouponV2(command: StoreCouponV2Command): Promise<StoreCouponV2Record | undefined> {
    command = checkedStructuredCouponCommand(structuredClone(command));
    if (command.realm !== this.realm) fail();
    return this.firestore.runTransaction(async tx => {
      const [profiles, receipt] = await Promise.all([tx.get(this.profiles(command.storeId)),
        tx.get(this.root(command.storeId).collection('storeCouponReceipts').doc(cataloguePayloadHash([id(command.ownerUserId), id(command.idempotencyKey)])))]);
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        command.storeId, command.ownerUserId);
      return receipt.exists ? this.originalStructuredCoupon(tx, command, receipt.data()) : undefined;
    });
  }
  private couponDraftRoot(storeId: string, accountId: string) {
    return this.root(storeId).collection('storeCouponDraftOwners').doc(cataloguePayloadHash(id(accountId)).toLowerCase());
  }
  private couponDraftHead(storeId: string, accountId: string, couponId: string) {
    return this.couponDraftRoot(storeId, accountId).collection('campaigns')
      .doc(cataloguePayloadHash([accountId, checkedStoreCouponDraftId(couponId)]).toLowerCase());
  }
  private async readDraftManifest(tx: Transaction, raw: unknown, accountId: string, storeId: string, expectedCouponId?: string): Promise<StoreCouponDraftRecord> {
    const manifest = exact(raw, ['schemaVersion', 'storeCouponDraftVersion', 'accountId', 'realm', 'storeId', 'couponId',
      'sourceRevision', 'observedAt', 'payloadHash', 'payloadBytes', 'pageCount']);
    const couponId = checkedStoreCouponDraftId(manifest.couponId);
    if (manifest.schemaVersion !== 1 || manifest.storeCouponDraftVersion !== 1 || manifest.accountId !== accountId ||
        manifest.realm !== this.realm || manifest.storeId !== storeId || expectedCouponId !== undefined && couponId !== expectedCouponId ||
        typeof manifest.payloadHash !== 'string' || !/^[a-f0-9]{64}$/iu.test(manifest.payloadHash)) fail('invalid_state', 409);
    integer(manifest.sourceRevision, 1, 1_000_000_000); integer(manifest.payloadBytes, 1, 8 * 1024 * 1024); integer(manifest.pageCount, 1, 128);
    const version = this.couponDraftHead(storeId, accountId, couponId).collection('revisions').doc(String(manifest.sourceRevision));
    const campaign = await this.couponLiteral(tx, version, manifest);
    return couponDraftRecord({schemaVersion: 1, storeCouponDraftVersion: 1, accountId, realm: this.realm, storeId, couponId,
      sourceRevision: manifest.sourceRevision, observedAt: manifest.observedAt, campaign}, accountId, this.realm, storeId, this.now().toISOString());
  }
  private async originalCouponDraft(tx: Transaction, command: StoreCouponDraftCommand, raw: unknown): Promise<StoreCouponDraftRecord> {
    const receipt = exact(raw, ['schemaVersion', 'fingerprint', 'manifest']);
    if (receipt.schemaVersion !== 1 || receipt.fingerprint !== command.fingerprint) fail('conflict', 409);
    const record = await this.readDraftManifest(tx, receipt.manifest, command.ownerUserId, command.storeId, command.couponId);
    if (record.sourceRevision !== command.expectedSourceRevision + 1 || JSON.stringify(record.campaign) !== JSON.stringify(command.campaign)) fail('invalid_state', 409);
    return record;
  }
  async saveCouponDraft(command: StoreCouponDraftCommand): Promise<StoreCouponDraftRecord> {
    command = checkedCouponDraftCommand(structuredClone(command));
    if (command.realm !== this.realm) fail();
    const head = this.couponDraftHead(command.storeId, command.ownerUserId, command.couponId);
    const receiptRef = this.couponDraftRoot(command.storeId, command.ownerUserId).collection('receipts').doc(cataloguePayloadHash(command.idempotencyKey));
    return this.firestore.runTransaction(async tx => {
      const [profiles, current, receipt] = await Promise.all([tx.get(this.profiles(command.storeId)), tx.get(head), tx.get(receiptRef)]);
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        command.storeId, command.ownerUserId);
      if (receipt.exists) return this.originalCouponDraft(tx, command, receipt.data());
      const previous = current.exists ? await this.readDraftManifest(tx, current.data(), command.ownerUserId, command.storeId, command.couponId) : undefined;
      if ((previous?.sourceRevision ?? 0) !== command.expectedSourceRevision || previous && previous.campaign.revision >= command.campaign.revision) fail('conflict', 409);
      const observedAt = this.now().toISOString(); if (command.observedAt > observedAt) fail();
      const {pages, payloadBytes, payloadHash} = this.couponPayload(command.campaign);
      const manifest = {schemaVersion: 1, storeCouponDraftVersion: 1, accountId: command.ownerUserId, realm: this.realm,
        storeId: command.storeId, couponId: command.couponId, sourceRevision: command.expectedSourceRevision + 1,
        observedAt, payloadHash, payloadBytes, pageCount: pages.length};
      const version = head.collection('revisions').doc(String(manifest.sourceRevision));
      tx.set(head, manifest); tx.create(version, manifest);
      for (const [index, text] of pages.entries()) tx.create(version.collection('payloadPages').doc(String(index)), {schemaVersion: 1, index, text});
      tx.create(receiptRef, {schemaVersion: 1, fingerprint: command.fingerprint, manifest});
      return couponDraftRecord({schemaVersion: 1, storeCouponDraftVersion: 1, accountId: command.ownerUserId,
        realm: this.realm, storeId: command.storeId, couponId: command.couponId, sourceRevision: manifest.sourceRevision,
        observedAt, campaign: command.campaign}, command.ownerUserId, this.realm, command.storeId, observedAt);
    });
  }
  async readCouponDraft(storeId: string, couponId: string, userId: string): Promise<StoreCouponDraftRecord | undefined> {
    const head = this.couponDraftHead(storeId, userId, couponId);
    return this.firestore.runTransaction(async tx => {
      const profiles = await tx.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      const current = await tx.get(head);
      return current.exists ? this.readDraftManifest(tx, current.data(), userId, storeId, couponId) : undefined;
    });
  }
  async pageCouponDrafts(storeId: string, after: string | undefined, limit: number, userId: string): Promise<StoreCouponDraftPage> {
    integer(limit, 1, 20); if (after !== undefined && !/^[a-f0-9]{64}$/u.test(after)) fail();
    return this.firestore.runTransaction(async tx => {
      const profiles = await tx.get(this.profiles(storeId));
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined, storeId, userId);
      let query = this.couponDraftRoot(storeId, userId).collection('campaigns').orderBy(FieldPath.documentId()).limit(limit + 1);
      if (after !== undefined) query = query.startAfter(after);
      const snapshot = await tx.get(query), records: StoreCouponDraftRecord[] = [];
      let bytes = 4096, last: string | null = null;
      for (const doc of snapshot.docs.slice(0, limit)) {
        const record = await this.readDraftManifest(tx, doc.data(), userId, storeId);
        if (doc.id !== cataloguePayloadHash([userId, record.couponId]).toLowerCase()) fail('invalid_state', 409);
        const size = Buffer.byteLength(JSON.stringify(record), 'utf8') + 1;
        if (bytes + size > 8 * 1024 * 1024) {if (!records.length) fail('unavailable', 503); break;}
        records.push(record); bytes += size; last = doc.id;
      }
      return {records, nextCursor: snapshot.size > records.length ? last : null};
    });
  }
  async reconcileCouponDraft(command: StoreCouponDraftCommand): Promise<StoreCouponDraftRecord | undefined> {
    command = checkedCouponDraftCommand(structuredClone(command));
    if (command.realm !== this.realm) fail();
    return this.firestore.runTransaction(async tx => {
      const [profiles, receipt] = await Promise.all([tx.get(this.profiles(command.storeId)), tx.get(
        this.couponDraftRoot(command.storeId, command.ownerUserId).collection('receipts').doc(cataloguePayloadHash(command.idempotencyKey)))]);
      owner(profiles.size === 1 && profiles.docs[0]!.id === profiles.docs[0]!.get('caseId') ? profiles.docs[0]!.data() as WorkspaceProfileRecord : undefined,
        command.storeId, command.ownerUserId);
      return receipt.exists ? this.originalCouponDraft(tx, command, receipt.data()) : undefined;
    });
  }
}
