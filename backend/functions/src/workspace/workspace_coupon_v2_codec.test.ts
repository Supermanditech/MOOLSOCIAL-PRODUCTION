/** Host-only native coupon contract regressions.
 * HOST fixtures are synthetic configuration inputs, never buyer/Store authority.
 */
import test from 'node:test';
import assert from 'node:assert/strict';
import {
  type StoreCouponV2Input, type StoreOfferV2Sku, type StoreOfferV2Terms,
  type StoreOfferV2Kind, type StoreCouponV2Record,
  checkedStoreCouponV2Input, checkedStoreCouponV2Record, checkedStoreOfferV2Terms,
  publicStoreOfferV2Terms, storeCouponV2PayloadHash, storeCouponV2UtcMicros,
  checkedStoreCouponDraftCampaign,
} from './workspace_coupon_v2_codec.js';

const HOST_SCOPE = {account: 'HOST-account', store: 'HOST-store', realm: 'evaluation' as const};
const HOST_NOW = '2026-10-30T00:00:00.000Z';
const HOST_KINDS: StoreOfferV2Kind[] = ['billDiscount', 'productDiscount', 'quantityPrice',
  'nextPurchase', 'buyerDiscount', 'dealerIntro', 'extraQuantity'];
function hostFixtures(): StoreCouponV2Input[] {
  const sku: StoreOfferV2Sku = {storeId: 'HOST-store', skuId: 'HOST-SKU', title: 'HOST product', sellUnit: 'HOST pack', listings: []};
  return HOST_KINDS.map((kind): StoreCouponV2Input => {
    const terms: StoreOfferV2Terms = {schemaVersion: 1, storeId: 'HOST-store', kind,
      skus: [], channels: ['retail'], discountKind: 'flat', discountValue: 100,
      minimumSpendMinor: 0, maximumSavingMinor: 100, tiers: [], buyQuantity: null,
      rewardSku: null, rewardQuantity: null, nextPurchaseDays: null};
    if (kind === 'productDiscount') terms.skus = [structuredClone(sku)];
    if (kind === 'nextPurchase') terms.nextPurchaseDays = 30;
    if (kind === 'quantityPrice' || kind === 'extraQuantity') {
      terms.skus = [structuredClone(sku)]; terms.discountKind = null;
      terms.discountValue = null; terms.maximumSavingMinor = null;
      if (kind === 'quantityPrice') terms.tiers = [{minimumQuantity: 2, priceMinor: 125}];
      else {terms.buyQuantity = 2; terms.rewardSku = structuredClone(sku); terms.rewardQuantity = 1;}
    }
    return {schemaVersion: 2, name: `HOST ${kind}`, structuredTerms: terms,
      buyerReferences: kind === 'buyerDiscount' ? ['HOST-buyer-reference'] : [],
      startsAt: '2026-10-01T00:00:00.000Z', endsAt: '2026-11-01T00:00:00.000Z',
      totalUses: 100, usesPerCustomer: 1, active: true};
  });
}
function hostInput(kind: StoreOfferV2Kind = 'productDiscount'): StoreCouponV2Input {
  return hostFixtures().find(input => input.structuredTerms.kind === kind)!;
}
function hostRecord(input: StoreCouponV2Input): StoreCouponV2Record {
  return {schemaVersion: 2, storeCouponTermsVersion: 2, accountId: HOST_SCOPE.account,
    realm: HOST_SCOPE.realm, storeId: HOST_SCOPE.store, couponId: 'HOST-coupon',
    revision: 1, observedAt: HOST_NOW, coupon: input};
}
function rejects(raw: unknown): void {
  assert.throws(() => checkedStoreCouponV2Input(raw, HOST_SCOPE.store),
    (error: unknown) => !!error && typeof error === 'object' && 'code' in error && error.code === 'invalid_input');
}
function setText(input: StoreCouponV2Input, field: 'name' | 'title' | 'sellUnit', value: string): void {
  if (field === 'name') input.name = value;
  else input.structuredTerms.skus[0]![field] = value;
}
for (const kind of HOST_KINDS) {
  test(`HOST normal native serializer input/record roundtrip: ${kind}`, () => {
    const input = hostInput(kind), record = hostRecord(input);
    assert.deepEqual(checkedStoreCouponV2Input(input, HOST_SCOPE.store), input);
    assert.deepEqual(checkedStoreCouponV2Record(record, HOST_SCOPE, HOST_NOW), record);
  });
}
for (const field of ['name', 'title', 'sellUnit'] as const) {
  test(`Dart trim parity rejects edge/alone NEL in ${field}`, () => {
    for (const value of ['\u0085Coupon', 'Coupon\u0085', '\u0085',
      '\u0085 Coupon', ' \u0085Coupon', 'Coupon \u0085', 'Coupon\u0085 ']) {
      const input = hostInput(); setText(input, field, value); rejects(input);
    }
  });
  test(`Dart trim parity preserves interior NEL in ${field}`, () => {
    const input = hostInput(); setText(input, field, 'Cou\u0085pon');
    assert.deepEqual(checkedStoreCouponV2Input(input, HOST_SCOPE.store), input);
  });
  test(`Dart trim parity preserves U180E at edge/alone/interior in ${field}`, () => {
    for (const value of ['\u180ECoupon', 'Coupon\u180E', '\u180E', 'Cou\u180Epon']) {
      const input = hostInput(); setText(input, field, value);
      assert.deepEqual(checkedStoreCouponV2Input(input, HOST_SCOPE.store), input);
    }
  });
  test(`Dart trim parity rejects edge FEFF and preserves interior FEFF in ${field}`, () => {
    for (const value of ['\uFEFFCoupon', 'Coupon\uFEFF', '\uFEFF']) {
      const input = hostInput(); setText(input, field, value); rejects(input);
    }
    const input = hostInput(); setText(input, field, 'Cou\uFEFFpon');
    assert.deepEqual(checkedStoreCouponV2Input(input, HOST_SCOPE.store), input);
  });
}
test('HOST IDs retain ASCII format without trimming/salvage', () => {
  for (const char of ['\u0085', '\u180E', '\uFEFF']) {
    for (const value of [char + 'HOST-SKU', 'HOST-SKU' + char, 'HOST' + char + '-SKU']) {
      const input = hostInput(); input.structuredTerms.skus[0]!.skuId = value; rejects(input);
      const buyers = hostInput('buyerDiscount'); buyers.buyerReferences = [value]; rejects(buyers);
    }
  }
});
test('HOST accepted interior text remains distinct and inputs are not normalized or mutated', () => {
  const input = hostInput(); input.name = 'Cou\u0085pon';
  const before = structuredClone(input), decoded = checkedStoreCouponV2Input(input, HOST_SCOPE.store);
  assert.deepEqual(decoded, before); assert.deepEqual(input, before);
  assert.notEqual(storeCouponV2PayloadHash(input, HOST_SCOPE.store),
    storeCouponV2PayloadHash({...input, name: 'Coupon'}, HOST_SCOPE.store));
  decoded.structuredTerms.skus[0]!.title = 'HOST changed output';
  assert.deepEqual(input, before);
});
test('HOST exact public TERMS projection excludes buyer/account data', () => {
  const input = hostInput('buyerDiscount'), projected = publicStoreOfferV2Terms(input, HOST_SCOPE.store);
  assert.deepEqual(projected, input.structuredTerms);
  for (const key of ['buyerReferences', 'accountId', 'coupon', 'observedAt']) assert.equal(Object.hasOwn(projected, key), false);
});
test('HOST strict fields reject extra private/evaluated properties and missing nullable terms', () => {
  const input = hostInput(); rejects({...input, appliedSavingMinor: 100});
  const raw = structuredClone(input) as unknown as {structuredTerms: Record<string, unknown>};
  delete raw.structuredTerms.rewardSku; rejects(raw);
});
test('HOST channels preserve raw input order and canonical hash significance', () => {
  const a = hostInput(); a.structuredTerms.channels = ['wholesale', 'retail'];
  const b = structuredClone(a); b.structuredTerms.channels = ['retail', 'wholesale'];
  assert.deepEqual(checkedStoreCouponV2Input(a).structuredTerms.channels, ['wholesale', 'retail']);
  assert.notEqual(storeCouponV2PayloadHash(a, HOST_SCOPE.store), storeCouponV2PayloadHash(b, HOST_SCOPE.store));
});
test('HOST nine trillion paise ceiling remains an accepted safe integer', () => {
  const input = hostInput(); input.structuredTerms.discountValue = 9_000_000_000_000;
  input.structuredTerms.maximumSavingMinor = 9_000_000_000_000;
  assert.deepEqual(checkedStoreCouponV2Input(input), input);
  input.structuredTerms.discountValue += 1; input.structuredTerms.maximumSavingMinor += 1; rejects(input);
});
test('HOST canonical timestamps preserve exact micros and signed extended years', () => {
  assert.equal(storeCouponV2UtcMicros('2026-10-30T00:00:00.123002Z') -
    storeCouponV2UtcMicros('2026-10-30T00:00:00.123001Z'), 1n);
  assert.throws(() => storeCouponV2UtcMicros('2026-10-30T00:00:00.123000Z'));
  for (const at of ['-0001-01-01T00:00:00.000001Z', '+010000-01-01T00:00:00.000Z', '-010000-01-01T00:00:00.000Z']) {
    assert.equal(typeof storeCouponV2UtcMicros(at), 'bigint');
  }
});
test('HOST v2 terms remain schema1; legacy v1 input not flattened/adopted', () => {
  const input = hostInput();
  assert.equal(checkedStoreOfferV2Terms(input.structuredTerms).schemaVersion, 1);
  rejects({...input, schemaVersion: 1});
});

test('native UTC range includes exact endpoints, rejects one microsecond beyond and invalid calendar dates', () => {
  assert.equal(storeCouponV2UtcMicros('-271821-04-20T00:00:00.000Z'), -8640000000000000000n);
  assert.equal(storeCouponV2UtcMicros('+275760-09-13T00:00:00.000Z'), 8640000000000000000n);
  for (const raw of ['+275760-09-13T00:00:00.000001Z', '-271821-04-19T23:59:59.999999Z',
    '2026-02-29T00:00:00.000Z', '2026-04-31T00:00:00.000Z', '2026-10-30T24:00:00.000Z']) {
    assert.throws(() => storeCouponV2UtcMicros(raw));
  }
});

test('private records reject foreign scope and one-microsecond future observations', () => {
  const record = hostRecord(hostInput());
  for (const changes of [{accountId: 'HOST-other'}, {realm: 'production'},
    {storeId: 'HOST-other'}, {observedAt: '2026-10-30T00:00:00.000001Z'}]) {
    assert.throws(() => checkedStoreCouponV2Record({...record, ...changes}, HOST_SCOPE, HOST_NOW));
  }
  const changed = structuredClone(record); changed.coupon.structuredTerms.storeId = 'HOST-other';
  assert.throws(() => checkedStoreCouponV2Record(changed, HOST_SCOPE, HOST_NOW));
});

for (const kind of HOST_KINDS) test(`HOST original private campaign retains exact ${kind} fields without publication`, () => {
  const {active: _, schemaVersion: _version, ...input} = hostInput(kind);
  const campaign = {schemaVersion: 2, id: 'मेरा कूपन', storeId: HOST_SCOPE.store, revision: 27,
    ...input};
  assert.deepEqual(checkedStoreCouponDraftCampaign(campaign, HOST_SCOPE.store, campaign.id), campaign);
  assert.equal(Object.hasOwn(checkedStoreCouponDraftCampaign(campaign, HOST_SCOPE.store), 'active'), false);
  assert.throws(() => checkedStoreCouponDraftCampaign(campaign, 'HOST-other'));
  assert.throws(() => checkedStoreCouponDraftCampaign(campaign, HOST_SCOPE.store, 'HOST-other'));
  assert.throws(() => checkedStoreCouponDraftCampaign({...campaign, active: true}, HOST_SCOPE.store));
});

test('HOST legacy private campaign stays legacy-shaped and allows a saved expired draft', () => {
  const raw = {id: 'A', storeId: HOST_SCOPE.store, revision: 12, name: 'HOST saved draft', percentage: false,
    discount: 100, minimumSpendMinor: 0, maximumSavingMinor: 100, startsAt: '2020-01-01T00:00:00.000001Z',
    endsAt: '2020-02-01T00:00:00.000001Z', totalUses: 10, usesPerCustomer: 1};
  assert.deepEqual(checkedStoreCouponDraftCampaign(raw, HOST_SCOPE.store, 'A'), raw);
  assert.throws(() => checkedStoreCouponDraftCampaign({...raw, discount: 101}, HOST_SCOPE.store));
  assert.throws(() => checkedStoreCouponDraftCampaign({...raw, id: '\u0085A'}, HOST_SCOPE.store));
  assert.throws(() => checkedStoreCouponDraftCampaign({...raw, revision: 0}, HOST_SCOPE.store));
});
