/** Exact native structured coupon terms. Validation is not buyer eligibility.
 * Native owners: StoreCouponInput v2 / StoreCouponRecord v2,
 * BuyV2StoreOfferTerms, BuyV2StoreOfferSku and BuyV2PublicListingIdentity.
 * Legacy StoreCouponInput/Record/Receipt v1 are deliberately not redefined.
 */
import {WorkspaceProfileError} from './workspace_profile_service.js';
import {cataloguePayloadHash} from './workspace_catalogue_service.js';

export type StoreOfferV2Kind = 'billDiscount' | 'productDiscount' | 'quantityPrice' |
  'nextPurchase' | 'buyerDiscount' | 'dealerIntro' | 'extraQuantity';
export type StoreOfferV2Channel = 'retail' | 'wholesale' | 'bulk';
export type StoreOfferV2Realm = 'evaluation' | 'production';
export interface StoreCouponV2Scope {account: string; store: string; realm: StoreOfferV2Realm}
export interface StoreOfferV2Listing {
  schemaVersion: 1; realm: StoreOfferV2Realm; listingId: string; storeId: string;
  skuId: string; canonicalProductId: string; verifiedPackId: string; channel: StoreOfferV2Channel;
}
export interface StoreOfferV2Sku {
  storeId: string; skuId: string; title: string; sellUnit: string; listings: StoreOfferV2Listing[];
}
export interface StoreOfferV2Terms {
  schemaVersion: 1; storeId: string; kind: StoreOfferV2Kind; skus: StoreOfferV2Sku[];
  channels: StoreOfferV2Channel[]; discountKind: 'flat' | 'percentage' | null;
  discountValue: number | null; minimumSpendMinor: number; maximumSavingMinor: number | null;
  tiers: {minimumQuantity: number; priceMinor: number}[]; buyQuantity: number | null;
  rewardSku: StoreOfferV2Sku | null; rewardQuantity: number | null; nextPurchaseDays: number | null;
}
export interface StoreCouponV2Input {
  schemaVersion: 2; name: string; structuredTerms: StoreOfferV2Terms;
  buyerReferences: string[]; startsAt: string; endsAt: string;
  totalUses: number; usesPerCustomer: number; active: boolean;
}
export interface StoreCouponV2Record {
  schemaVersion: 2; storeCouponTermsVersion: 2; accountId: string; realm: StoreOfferV2Realm;
  storeId: string; couponId: string; revision: number; observedAt: string; coupon: StoreCouponV2Input;
}
export type StoreCouponDraftCampaign = {
  id: string; storeId: string; revision: number; name: string; startsAt: string; endsAt: string;
  totalUses: number; usesPerCustomer: number;
} & ({schemaVersion: 2; structuredTerms: StoreOfferV2Terms; buyerReferences: string[]} |
  {percentage: boolean; discount: number; minimumSpendMinor: number; maximumSavingMinor: number});
export function checkedStoreCouponDraftId(raw: unknown): string {return agg09Text(raw, 128);}
const agg09MoneyMax = 9_000_000_000_000; // JS-safe: strictly below 2^53.
const agg09Channels = ['retail', 'wholesale', 'bulk'] as const;
const agg09Kinds: readonly string[] = ['billDiscount', 'productDiscount', 'quantityPrice',
  'nextPurchase', 'buyerDiscount', 'dealerIntro', 'extraQuantity'];
function agg09Invalid(): never {throw new WorkspaceProfileError('invalid_input', 'Check the exact Store offer fields.', 400);}
function agg09Exact(raw: unknown, keys: readonly string[]): Record<string, unknown> {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(raw))) agg09Invalid();
  const row = raw as Record<string, unknown>;
  if (Object.keys(row).length !== keys.length || keys.some(key => !Object.hasOwn(row, key))) agg09Invalid();
  return row;
}
function agg09Text(raw: unknown, max: number): string {
  if (typeof raw !== 'string' || raw.length === 0 || raw !== raw.trim() || raw.startsWith('\u0085') || raw.endsWith('\u0085') || raw.length > max || /[\x00-\x1f]/u.test(raw)) agg09Invalid();
  return raw;
}
function agg09Id(raw: unknown, minimumLength: 1 | 3 = 1): string {
  const value = agg09Text(raw, 128);
  if (value.length < minimumLength || !/^[A-Za-z0-9][A-Za-z0-9._:-]*$/u.test(value)) agg09Invalid();
  return value;
}
function agg09Integer(raw: unknown, minimum: number, maximum: number): number {
  if (!Number.isSafeInteger(raw) || (raw as number) < minimum || (raw as number) > maximum) agg09Invalid();
  return raw as number;
}
function agg09Array(raw: unknown): unknown[] {if (!Array.isArray(raw)) agg09Invalid(); return raw;}
function agg09Clone<T>(value: T): T {return JSON.parse(JSON.stringify(value)) as T;}

/** Exact Dart UTC serializer spelling, including nonzero microsecond tails.
 * Date is used only to validate calendar fields at millisecond resolution;
 * the original text is never normalized, and chronology uses exact BigInt micros.
 * Signed/extended years follow Dart's four-or-signed-six-digit representation.
 */
export function storeCouponV2UtcMicros(raw: unknown): bigint {
  const value = agg09Text(raw, 32);
  const match = /^(-?[0-9]{4}|[+-][0-9]{6})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})\.([0-9]{3})([0-9]{3})?Z$/u.exec(value);
  if (!match) agg09Invalid();
  const year = Number(match[1]);
  const nativeYear = (year < 0 ? '-' : year > 9999 ? '+' : '') +
    String(Math.abs(year)).padStart(Math.abs(year) <= 9999 ? 4 : 6, '0');
  if (nativeYear !== match[1] || match[8] === '000') agg09Invalid();
  const jsYear = year >= 0 && year <= 9999 ? String(year).padStart(4, '0') :
    (year < 0 ? '-' : '+') + String(Math.abs(year)).padStart(6, '0');
  const jsText = `${jsYear}-${match[2]}-${match[3]}T${match[4]}:${match[5]}:${match[6]}.${match[7]}Z`;
  const millis = Date.parse(jsText);
  if (!Number.isFinite(millis) || new Date(millis).toISOString() !== jsText) agg09Invalid();
  const micros = BigInt(millis) * 1000n + BigInt(match[8] ?? '0');
  if (micros < -8640000000000000000n || micros > 8640000000000000000n) agg09Invalid();
  return micros;
}
function agg09Scope(raw: StoreCouponV2Scope): StoreCouponV2Scope {
  const s = agg09Exact(raw, ['account', 'store', 'realm']);
  if (s.realm !== 'evaluation' && s.realm !== 'production') agg09Invalid();
  return {account: agg09Id(s.account, 3), store: agg09Id(s.store, 3), realm: s.realm};
}
export function checkedStoreOfferV2Sku(raw: unknown): StoreOfferV2Sku {
  const v = agg09Exact(raw, ['storeId', 'skuId', 'title', 'sellUnit', 'listings']);
  const store = agg09Id(v.storeId), sku = agg09Id(v.skuId);
  agg09Text(v.title, 240); agg09Text(v.sellUnit, 240);
  const listings = agg09Array(v.listings), seen = new Set<string>();
  if (listings.length > 3) agg09Invalid();
  for (const rawListing of listings) {
    const l = agg09Exact(rawListing, ['schemaVersion', 'realm', 'listingId', 'storeId', 'skuId', 'canonicalProductId', 'verifiedPackId', 'channel']);
    if (l.schemaVersion !== 1 || !['evaluation', 'production'].includes(l.realm as string) ||
        !agg09Channels.includes(l.channel as StoreOfferV2Channel)) agg09Invalid();
    const listingId = agg09Text(l.listingId, 72);
    if (!/^listing-[a-f0-9]{64}$/u.test(listingId)) agg09Invalid();
    for (const key of ['storeId', 'skuId', 'canonicalProductId', 'verifiedPackId']) agg09Id(l[key], 3);
    if (l.storeId !== store || l.skuId !== sku || seen.has(l.channel as string)) agg09Invalid();
    seen.add(l.channel as string);
  }
  return agg09Clone(v) as unknown as StoreOfferV2Sku;
}
export function checkedStoreOfferV2Terms(raw: unknown, expectedStore?: string): StoreOfferV2Terms {
  const v = agg09Exact(raw, ['schemaVersion', 'storeId', 'kind', 'skus', 'channels', 'discountKind',
    'discountValue', 'minimumSpendMinor', 'maximumSavingMinor', 'tiers', 'buyQuantity',
    'rewardSku', 'rewardQuantity', 'nextPurchaseDays']);
  const store = agg09Id(v.storeId);
  if (v.schemaVersion !== 1 || !agg09Kinds.includes(v.kind as string) || expectedStore !== undefined && store !== expectedStore) agg09Invalid();
  const skus = agg09Array(v.skus).map(checkedStoreOfferV2Sku), channels = agg09Array(v.channels);
  if (skus.length > 1000 || skus.some(sku => sku.storeId !== store) ||
      new Set(skus.map(sku => sku.skuId)).size !== skus.length || channels.length === 0 ||
      channels.some(c => !agg09Channels.includes(c as StoreOfferV2Channel)) || new Set(channels).size !== channels.length) agg09Invalid();
  agg09Integer(v.minimumSpendMinor, 0, agg09MoneyMax);
  if (v.discountKind !== null && typeof v.discountKind !== 'string') agg09Invalid();
  // Bounds below are kind-specific, following the native constructor.
  for (const key of ['discountValue', 'maximumSavingMinor', 'buyQuantity', 'rewardQuantity', 'nextPurchaseDays']) {
    if (v[key] !== null && !Number.isSafeInteger(v[key])) agg09Invalid();
  }
  const tiers = agg09Array(v.tiers).map(rawTier => {
    const t = agg09Exact(rawTier, ['minimumQuantity', 'priceMinor']);
    return {minimumQuantity: agg09Integer(t.minimumQuantity, 1, 1_000_000_000), priceMinor: agg09Integer(t.priceMinor, 1, agg09MoneyMax)};
  });
  const reward = v.rewardSku === null ? null : checkedStoreOfferV2Sku(v.rewardSku);
  const monetary = v.kind !== 'quantityPrice' && v.kind !== 'extraQuantity';
  if (monetary) {
    if (v.discountKind !== 'flat' && v.discountKind !== 'percentage') agg09Invalid();
    const discount = agg09Integer(v.discountValue, 1, v.discountKind === 'percentage' ? 10000 : agg09MoneyMax);
    const cap = agg09Integer(v.maximumSavingMinor, 1, agg09MoneyMax);
    if (v.discountKind === 'flat' && cap !== discount || tiers.length !== 0 ||
        v.buyQuantity !== null || reward !== null || v.rewardQuantity !== null || v.kind === 'productDiscount' && skus.length === 0) agg09Invalid();
  } else {
    if (v.discountKind !== null || v.discountValue !== null || v.maximumSavingMinor !== null || skus.length !== 1) agg09Invalid();
    if (v.kind === 'quantityPrice') {
      if (tiers.length === 0 || tiers.length > 100 || v.buyQuantity !== null || reward !== null || v.rewardQuantity !== null) agg09Invalid();
      let previous = 0;
      for (const tier of tiers) {if (tier.minimumQuantity <= previous) agg09Invalid(); previous = tier.minimumQuantity;}
    } else {
      if (tiers.length !== 0 || reward === null || reward.storeId !== store) agg09Invalid();
      agg09Integer(v.buyQuantity, 1, 1_000_000_000); agg09Integer(v.rewardQuantity, 1, 1_000_000_000);
    }
  }
  if (v.kind === 'nextPurchase') agg09Integer(v.nextPurchaseDays, 1, 365);
  else if (v.nextPurchaseDays !== null) agg09Invalid();
  // Keep raw nested order/text; never sort or deduplicate into another request.
  return agg09Clone(v) as unknown as StoreOfferV2Terms;
}
export function checkedStoreCouponV2Input(raw: unknown, expectedStore?: string): StoreCouponV2Input {
  const v = agg09Exact(raw, ['schemaVersion', 'name', 'structuredTerms', 'buyerReferences',
    'startsAt', 'endsAt', 'totalUses', 'usesPerCustomer', 'active']);
  if (v.schemaVersion !== 2 || typeof v.active !== 'boolean') agg09Invalid();
  agg09Text(v.name, 80);
  const terms = checkedStoreOfferV2Terms(v.structuredTerms, expectedStore);
  const buyers = agg09Array(v.buyerReferences);
  if (buyers.length > 1000 || new Set(buyers).size !== buyers.length) agg09Invalid();
  for (const buyer of buyers) agg09Id(buyer);
  if (terms.kind === 'buyerDiscount' ? buyers.length === 0 : buyers.length !== 0) agg09Invalid();
  if (storeCouponV2UtcMicros(v.endsAt) <= storeCouponV2UtcMicros(v.startsAt)) agg09Invalid();
  const uses = agg09Integer(v.totalUses, 1, 1_000_000_000);
  agg09Integer(v.usesPerCustomer, 1, uses);
  return agg09Clone(v) as unknown as StoreCouponV2Input;
}
export function checkedStoreCouponV2Record(raw: unknown, rawScope: StoreCouponV2Scope, now: string): StoreCouponV2Record {
  const scope = agg09Scope(rawScope), v = agg09Exact(raw, ['schemaVersion', 'storeCouponTermsVersion',
    'accountId', 'realm', 'storeId', 'couponId', 'revision', 'observedAt', 'coupon']);
  if (v.schemaVersion !== 2 || v.storeCouponTermsVersion !== 2 || v.accountId !== scope.account ||
      v.realm !== scope.realm || v.storeId !== scope.store || storeCouponV2UtcMicros(v.observedAt) > storeCouponV2UtcMicros(now)) agg09Invalid();
  agg09Id(v.couponId, 3); agg09Integer(v.revision, 1, 1_000_000_000);
  checkedStoreCouponV2Input(v.coupon, scope.store);
  return agg09Clone(v) as unknown as StoreCouponV2Record;
}
/** Native StoreCouponInput.validateForSave only; no new startsAt/eligibility rule. */
export function validateStoreCouponV2ForSave(input: StoreCouponV2Input, now: string): void {
  const v = checkedStoreCouponV2Input(input);
  if (v.active && storeCouponV2UtcMicros(v.endsAt) <= storeCouponV2UtcMicros(now)) agg09Invalid();
}
/** Public TERMS only. No proposed public record/receiver envelope is invented.
 * Never use a private record spread or deletion to form a public projection.
 */
export function publicStoreOfferV2Terms(raw: unknown, storeId: string): StoreOfferV2Terms {
  const privateInput = checkedStoreCouponV2Input(raw, storeId);
  return checkedStoreOfferV2Terms(privateInput.structuredTerms, storeId);
}
/** Object-key canonical hashing reuses the existing catalogue owner; array order
 * and original timestamp text remain significant. No eligibility/result fields.
 */
export function storeCouponV2PayloadHash(raw: unknown, storeId: string): string {
  return cataloguePayloadHash(checkedStoreCouponV2Input(raw, storeId));
}

/** Literal original native private campaign, not a publication or entitlement.
 * Private IDs follow the existing campaign text contract; hash them for storage
 * instead of broadening public coupon IDs or substituting another master ID. */
export function checkedStoreCouponDraftCampaign(raw: unknown, storeId: string, couponId?: string): StoreCouponDraftCampaign {
  const structured = !!raw && typeof raw === 'object' && (raw as Record<string, unknown>).schemaVersion === 2;
  const row = agg09Exact(raw, ['id', 'storeId', 'revision', 'name', 'startsAt', 'endsAt', 'totalUses', 'usesPerCustomer',
    ...(structured ? ['schemaVersion', 'structuredTerms', 'buyerReferences'] : ['percentage', 'discount', 'minimumSpendMinor', 'maximumSavingMinor'])]);
  const originalId = checkedStoreCouponDraftId(row.id);
  if (row.storeId !== agg09Id(storeId, 3) || couponId !== undefined && originalId !== couponId) agg09Invalid();
  agg09Integer(row.revision, 1, 1_000_000_000);
  if (structured) {
    checkedStoreCouponV2Input({schemaVersion: 2, name: row.name, structuredTerms: row.structuredTerms,
      buyerReferences: row.buyerReferences, startsAt: row.startsAt, endsAt: row.endsAt,
      totalUses: row.totalUses, usesPerCustomer: row.usesPerCustomer, active: false}, storeId);
  } else {
    if (typeof row.percentage !== 'boolean') agg09Invalid();
    // Validation reuse only. The returned/stored original stays legacy-shaped.
    checkedStoreCouponV2Input({schemaVersion: 2, name: row.name, structuredTerms: {schemaVersion: 1,
      storeId, kind: 'billDiscount', skus: [], channels: ['retail'], discountKind: row.percentage ? 'percentage' : 'flat',
      discountValue: row.discount, minimumSpendMinor: row.minimumSpendMinor, maximumSavingMinor: row.maximumSavingMinor,
      tiers: [], buyQuantity: null, rewardSku: null, rewardQuantity: null, nextPurchaseDays: null},
    buyerReferences: [], startsAt: row.startsAt, endsAt: row.endsAt, totalUses: row.totalUses,
    usesPerCustomer: row.usesPerCustomer, active: false}, storeId);
  }
  return agg09Clone(row) as StoreCouponDraftCampaign;
}


