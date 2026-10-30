import assert from "node:assert/strict";
import {createHash, randomUUID} from "node:crypto";
import {execFile} from "node:child_process";
import {readFileSync, writeFileSync} from "node:fs";
import {dirname, resolve} from "node:path";
import {promisify} from "node:util";
import test from "node:test";
import {Server, ServerCredentials, status as grpcStatus, type ServiceDefinition} from "@grpc/grpc-js";
import {GrpcClient} from "google-gax";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {WorkspaceProfileError} from "./workspace_profile_service.js";
import * as purchaseModule from "./workspace_purchase_projection_service.js";
import {WorkspacePurchaseProjectionService, normalizePlacement, requireDefaultPurchaseTenant,
  WorkspaceOrderOperationsService, normalizeOperationalOrder,
  normalizeOrderCompletion, purchaseOriginalFingerprint, type TrustedOrderCompletionEvidence,
  type TrustedOperationalOrderEvidence, type TrustedPlacementReceipt} from "./workspace_purchase_projection_service.js";
import {WorkspaceBulkQuoteService} from "./workspace_purchase_projection_service.js";
import {FirestorePromotionRepository, WorkspacePromotionService, storeCouponAttributionReferences} from './workspace_promotion_service.js';
import {cataloguePayloadHash} from './workspace_catalogue_service.js';

test('LF13 production bootstrap lets a read abort restart the whole transaction without replaying its closed ID', {
  timeout: 30000,
}, async () => {
  // Loopback transport fault fixture only: no app records or commerce outcome.
  // Use the installed wire definitions and the real SDK/default-client bootstrap.
  const protos = JSON.parse(readFileSync(resolve(dirname(require.resolve('@google-cloud/firestore')),
    '../protos/v1.json'), 'utf8'));
  const loaded = new GrpcClient().loadProtoJSON(protos) as any;
  const server = new Server();
  const started: string[] = [], aborted = new Set<string>(), replays: string[] = [], rollbacks: string[] = [];
  const commits: any[] = [];
  let queryAttempts = 0;
  const timestamp = {seconds: 1792497600, nanos: 0};
  server.addService(loaded.google.firestore.v1.Firestore.service as ServiceDefinition, {
    batchGetDocuments(call: any) {
      let transaction = Buffer.from(call.request.transaction ?? []);
      if (!transaction.length) {
        transaction = Buffer.from(`transport-attempt-${started.length + 1}`);
        started.push(transaction.toString());
      }
      const id = transaction.toString();
      if (aborted.has(id)) {
        replays.push(id);
        call.emit('error', {code: grpcStatus.INVALID_ARGUMENT, details: 'Transaction is invalid or closed.'});
        return;
      }
      if (started.length === 1 && call.request.documents[0].endsWith('/transport/second')) {
        aborted.add(id);
        call.emit('error', {code: grpcStatus.ABORTED, details: 'Transaction lock timeout.'});
        return;
      }
      for (const name of call.request.documents) call.write({transaction,
        found: {name, fields: {value: {integerValue: '2'}}, createTime: timestamp, updateTime: timestamp},
        readTime: timestamp});
      call.end();
    },
    rollback(call: any, done: any) {
      rollbacks.push(Buffer.from(call.request.transaction).toString());
      done(null, {});
    },
    commit(call: any, done: any) {
      commits.push(call.request);
      done(null, {commitTime: timestamp, writeResults: call.request.writes.map(() => ({updateTime: timestamp}))});
    },
    runQuery(call: any) {
      if (++queryAttempts === 1) {
        call.emit('error', {code: grpcStatus.UNAVAILABLE, details: 'Isolated transient query failure.'});
        return;
      }
      call.write({document: {name: `${call.request.parent}/transport/query-result`,
        fields: {value: {integerValue: '2'}}, createTime: timestamp, updateTime: timestamp}, readTime: timestamp});
      call.end();
    },
  });
  const port = await new Promise<number>((accept, reject) => server.bindAsync('127.0.0.1:0',
    ServerCredentials.createInsecure(), (error, assigned) => error ? reject(error) : accept(assigned)));
  try {
    const indexPath = resolve(__dirname, '../index.js');
    const child = `
      require(${JSON.stringify(indexPath)});
      const {getFirestore} = require('firebase-admin/firestore');
      const db = getFirestore();
      (async () => {
        let attempts = 0;
        try {
          const value = await db.runTransaction(async tx => {
            attempts++;
            const first = await tx.get(db.doc('transport/first'));
            const second = await tx.get(db.doc('transport/second'));
            const value = first.get('value') + second.get('value');
            tx.set(db.doc('transport/result'), {value});
            return value;
          });
          const query = await db.collection('transport').where('value', '==', 2).get();
          console.log('LF13_TRANSPORT ' + JSON.stringify({attempts, value, queryValues: query.docs.map(doc => doc.get('value'))}));
        } finally { await db.terminate(); }
      })().catch(error => { console.error(error); process.exitCode = 1; });`;
    const result = await promisify(execFile)(process.execPath, ['-e', child], {
      cwd: resolve(__dirname, '../..'), timeout: 20000,
      env: {...process.env, FIRESTORE_EMULATOR_HOST: `127.0.0.1:${port}`,
        GCLOUD_PROJECT: 'demo-lf13-transport', GOOGLE_CLOUD_PROJECT: 'demo-lf13-transport',
        FIREBASE_CONFIG: JSON.stringify({projectId: 'demo-lf13-transport'})},
    });
    const line = result.stdout.split('\n').find(value => value.startsWith('LF13_TRANSPORT '));
    assert.ok(line, result.stdout + result.stderr);
    assert.deepEqual(JSON.parse(line.slice('LF13_TRANSPORT '.length)), {attempts: 2, value: 4, queryValues: [2]});
    assert.deepEqual(started, ['transport-attempt-1', 'transport-attempt-2']);
    assert.deepEqual([...aborted], ['transport-attempt-1']);
    assert.deepEqual(replays, [], 'streaming layer must not resend an aborted transaction ID');
    assert.deepEqual(rollbacks, ['transport-attempt-1']);
    assert.equal(commits.length, 1);
    assert.equal(Buffer.from(commits[0].transaction).toString(), 'transport-attempt-2');
    assert.equal(commits[0].writes.length, 1);
    assert.equal(commits[0].writes[0].update.fields.value.integerValue, '4');
    assert.equal(queryAttempts, 2, 'transient query retry remains available on the configured shared client');
  } finally { server.forceShutdown(); }
});

function purchaseTestFirestore(app: ReturnType<typeof initializeApp>) {
  const db = getFirestore(app);
  // Named emulator fixtures use the same supported transport mode as production.
  // The separate bootstrap regression above exercises the real index configuration.
  db.settings({gaxServerStreamingRetries: true});
  return db;
}

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

test('LF-BULK supplier negotiation has a distinct private lifecycle, not a Checkout quote or issued PO', () => {
  const Service = Reflect.get(purchaseModule, 'WorkspaceBulkQuoteService');
  assert.equal(typeof Service, 'function');
  for (const method of ['request', 'offer', 'accept', 'withdraw', 'read', 'listBuyer', 'listStore', 'reconcile', 'preparePurchase', 'readCouponPrices']) {
    assert.equal(typeof Reflect.get(Service.prototype, method), 'function');
  }
});

test('LF-BULK HTTP operation classification separates writes from observational inbox and recovery', () => {
  const classify = Reflect.get(purchaseModule, 'bulkSupplierQuoteOperation');
  assert.equal(typeof classify, 'function');
  for (const [operation, action] of [
    ['requestBulkSupplierQuote', 'request'], ['offerBulkSupplierQuote', 'offer'],
    ['acceptBulkSupplierQuote', 'accept'], ['withdrawBulkSupplierQuote', 'withdraw'],
    ['readBulkSupplierQuote', 'read'], ['listBuyerBulkSupplierQuotes', 'list_buyer'],
    ['listStoreBulkSupplierQuotes', 'list_store'], ['reconcileBulkSupplierQuote', 'reconcile'],
  ]) assert.equal(classify(operation), action);
  for (const other of ['placeOrder', 'acceptQuote', 'readStorePurchaseProjection', null, {}, 'requestBulkSupplierQuote ']) {
    assert.equal(classify(other), undefined);
  }
});

test('LF-BULK local persisted request offer acceptance and original recovery keep exact merchandise facts private', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  // Isolated catalogue-source fixture and actual loopback Firestore only.
  // Not a phone record, real quotation, payment or live catalogue acceptance.
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-bulk-${randomUUID().slice(0, 8)}`}, `bulk-${randomUUID()}`), db = purchaseTestFirestore(app);
  let clock = '2026-10-20T12:00:00.000Z', channel = 'bulk', revision = 1, policyRevision = 1;
  const listingId = `listing-${createHash('sha256').update(JSON.stringify([1, 'evaluation', 'store-one', 'sku-one', 'bulk'])).digest('hex')}`;
  let expireDuringRead = false, sourceReads = 0;
  const sourceFixture = {bulkQuotationSnapshot: async () => [{state: 'ready', realm: 'evaluation', storeId: 'store-one',
    publicStore: {id: 'store-one', name: 'Isolated Bulk supplier', profileId: 'wholesaler'}, items: [{
    skuId: 'sku-one', revision, canonicalProductId: 'canonical-one', verifiedPackId: 'pack-one',
    content: {title: 'Isolated Bulk rice', variant: 'Aged\ngrain'}, pack: {label: '25 kg bag'},
    channels: [{kind: channel, minimumOrder: 10, quantityStep: 5, validUntil: '2026-10-21T12:00:00.000Z'}],
    listings: [{schemaVersion: 1, realm: 'evaluation', listingId, storeId: 'store-one', skuId: 'sku-one', channel,
      canonicalProductId: 'canonical-one', verifiedPackId: 'pack-one'}],
    supplierPolicy: {schemaVersion: 1, realm: 'evaluation', storeId: 'store-one', skuId: 'sku-one', observedAt: clock,
      state: 'ready', revision: policyRevision, requiresAcceptance: true, policy: {id: 'policy-one', storeId: 'store-one',
        revision: `policy-v${policyRevision}`, productIds: ['sku-one'], requiresAcceptance: true, validUntil: null,
        title: 'Isolated supplier terms', body: 'Discuss bank or delivery terms with supplier'}},
  }]}]};
  const source = {bulkQuotationSnapshot: async () => {
    sourceReads++;
    const pages = await sourceFixture.bulkQuotationSnapshot();
    if (expireDuringRead) clock = '2026-10-20T12:05:00.000Z';
    return pages;
  }};
  const service = () => new WorkspaceBulkQuoteService(db, 'evaluation', source, () => new Date(clock));
  const request = {schemaVersion: 1, requestId: 'request-one', storeId: 'store-one',
    lines: [{lineId: 'line-one', skuId: 'sku-one', listingId, skuRevision: 1, quantity: 10}]};
  const profile = {schemaVersion: 1, caseId: 'case-one', workspaceId: 'store-one', ownerUserId: 'supplier-one',
    familyId: 'products-trade', profileId: 'wholesaler', status: 'live', shopEnabled: true};
  try {
    await db.collection('workspaceProfiles').doc('case-one').set(profile);
    for (const value of ['retail', 'wholesale']) {
      channel = value; await assert.rejects(service().request('buyer-one', request));
    }
    channel = 'bulk';
    const unknownRequest = await service().reconcile('buyer-one', {schemaVersion: 1, originalOperation: 'request', original: request}) as any;
    assert.equal(unknownRequest.state, 'not_found'); assert.equal(unknownRequest.agreement, null);
    assert.equal(unknownRequest.currentHead, null); assert.equal(unknownRequest.proof, null);
    for (const change of [{buyerUserId: 'other-buyer'}, {lines: [{...request.lines[0], quantity: 11}]},
      {lines: [{...request.lines[0], quantity: 5}]}, {lines: [{...request.lines[0], unitPriceMinor: 1}]}]) {
      await assert.rejects(service().request('buyer-one', {...request, ...change}));
    }
    const created = await service().request('buyer-one', request) as any;
    assert.equal(created.state, 'requested'); assert.equal(created.orderingAvailable, false);
    assert.equal(created.storeName, 'Isolated Bulk supplier');
    assert.equal(created.kind, 'supplier_merchandise_agreement');
    const scope = {quoteId: created.quoteId};
    const supplierRequested = await service().read('supplier-one', scope) as any;
    const page = {limit: 1, cursor: null};
    const buyerPage = await service().listBuyer('buyer-one', page) as any;
    assert.equal(buyerPage.summaries.length, 1); assert.equal(buyerPage.nextCursor, null);
    assert.equal(buyerPage.paging, 'refreshable_not_snapshot'); assert.equal(buyerPage.summaries[0].quoteId, created.quoteId);
    assert.equal(JSON.stringify(buyerPage).includes('buyer-one'), false);
    assert.equal(JSON.stringify(buyerPage).includes('supplierPolicy'), false);
    assert.equal((await service().listBuyer('other-buyer', page) as any).summaries.length, 0);
    const storePage = await service().listStore('supplier-one', {storeId: 'store-one', ...page}) as any;
    assert.equal(storePage.summaries[0].quoteId, created.quoteId); assert.equal(storePage.nextCursor, null);
    await assert.rejects(service().listStore('other-supplier', {storeId: 'store-one', ...page}), {code: 'not_found'});
    await assert.rejects(service().listStore('buyer-one', {storeId: 'store-one', ...page}), {code: 'not_found'});
    assert.deepEqual(await service().request('buyer-one', request), created);
    await assert.rejects(service().request('buyer-one', {...request, lines: [{...request.lines[0], quantity: 15}]}));
    await assert.rejects(service().read('other-buyer', scope));
    const offer = {schemaVersion: 1, ...scope, operationId: 'offer-one', expectedRevision: 1,
      validUntil: '2026-10-20T12:05:00.000Z', prices: [{lineId: 'line-one', unitPriceMinor: 10025}]};
    await assert.rejects(service().offer('buyer-one', offer));
    await assert.rejects(service().offer('other-supplier', offer));
    await assert.rejects(service().offer('supplier-one', {...offer, prices: [{lineId: 'line-one', unitPriceMinor: 1.5}]}));
    const offered = await service().offer('supplier-one', offer) as any;
    const beforeReconcileReads = sourceReads;
    const unobserved = await service().reconcile('buyer-one', {schemaVersion: 1, originalOperation: 'accept',
      original: {schemaVersion: 1, ...scope, operationId: 'never-accept', expectedRevision: 2}}) as any;
    assert.equal(unobserved.state, 'not_found'); assert.equal(unobserved.currentHead.state, 'offered');
    assert.equal(unobserved.proof, null); assert.equal(sourceReads, beforeReconcileReads);
    assert.equal(offered.offer.merchandiseMinor, 100250);
    assert.equal(offered.finalChargesDetermined, false); assert.equal(offered.creditApproved, false);
    assert.equal(offered.lines[0].quantity, 10); assert.equal(offered.lines[0].supplierPolicy.revision, 1);
    assert.deepEqual(await service().offer('supplier-one', offer), offered);
    const path = db.collection('workspacePurchaseProjections').doc('evaluation').collection('bulkQuoteRequests').doc(created.quoteId);
    const originalStored = (await path.get()).data()!;
    const canonical = (v: any): any => Array.isArray(v) ? v.map(canonical) : v && typeof v === 'object'
      ? Object.fromEntries(Object.keys(v).sort().map(k => [k, canonical(v[k])])) : v;
    const hash = (v: unknown) => createHash('sha256').update(JSON.stringify(canonical(v))).digest('hex');
    for (const corrupt of [
      (body: any) => { body.state = ['offered']; },
      (body: any) => { delete body.offer.prices[0].merchandiseMinor; },
      (body: any) => { body.revision = 9; },
      (body: any) => { body.offer.offeredAt = '2026-10-20T12:02:00.000Z'; },
      (body: any) => { body.lines[0].supplierPolicy.privateAccount = 'not-public'; },
    ]) {
      const body = structuredClone(originalStored.body); corrupt(body);
      await path.set({body, integrity: hash(body)});
      await assert.rejects(service().read('buyer-one', scope));
      await assert.rejects(service().read('other-buyer', scope), {code: 'not_found', httpStatus: 404});
      await assert.rejects(service().offer('other-supplier', offer), {code: 'not_found', httpStatus: 404});
    }
    await path.set(originalStored);
    const legacy = structuredClone(originalStored.body);
    delete legacy.storeName;
    for (const line of legacy.lines) delete line.variant;
    await path.set({body: legacy, integrity: hash(legacy)});
    const legacyRead = await service().read('buyer-one', scope) as any;
    assert.equal(Object.hasOwn(legacyRead.lines[0], 'variant'), false);
    assert.deepEqual((await path.get()).data()!.body, legacy);
    await path.set(originalStored);
    // Reordered Firestore maps retain the same canonical agreement.
    await path.set(canonical(originalStored));
    assert.deepEqual(await service().read('supplier-one', scope), offered);
    const accept = {schemaVersion: 1, ...scope, operationId: 'accept-one', expectedRevision: 2};
    await assert.rejects(service().accept('supplier-one', accept));
    expireDuringRead = true;
    await assert.rejects(service().accept('buyer-one', accept));
    expireDuringRead = false; clock = '2026-10-20T12:00:00.000Z';
    assert.equal((await service().read('buyer-one', scope) as any).revision, 2);
    policyRevision = 2; await assert.rejects(service().accept('buyer-one', accept)); policyRevision = 1;
    clock = offer.validUntil; await assert.rejects(service().accept('buyer-one', accept));
    const expiredAmendment = {...offer, expectedRevision: 2, operationId: 'unobserved-expired-offer'};
    const expiredRecovery = await service().reconcile('supplier-one', {schemaVersion: 1, originalOperation: 'offer', original: expiredAmendment}) as any;
    assert.equal(expiredRecovery.state, 'not_found'); assert.equal(expiredRecovery.proof, null);
    assert.equal(expiredRecovery.currentHead.revision, 2);
    await assert.rejects(service().offer('supplier-one', expiredAmendment));
    clock = '2026-10-20T12:01:00.000Z';
    const accepted = await service().accept('buyer-one', accept) as any;
    assert.equal(accepted.state, 'accepted'); assert.equal(accepted.acceptance.offerRevision, 2);
    assert.equal(accepted.orderingAvailable, false); assert.equal(accepted.offer.merchandiseMinor, 100250);
    assert.deepEqual(await service().read('buyer-one', scope), accepted);
    // Actual local final-purchase boundary: agreed prices are not themselves a
    // final quote. Explicit isolated totals below exercise attribution only.
    const supplierQuote = {schemaVersion: 1 as const, realm: 'evaluation' as const, quoteId: accepted.quoteId,
      acceptedRevision: accepted.revision, agreementFingerprint: accepted.acceptance.agreementFingerprint,
      offerRevision: accepted.offer.revision, acceptedAt: accepted.acceptance.acceptedAt,
      validUntil: accepted.offer.validUntil, merchandiseMinor: accepted.offer.merchandiseMinor,
      lines: [{lineId: 'placed-line-one', quoteLineId: 'line-one'}]};
    const reference = {schemaVersion: 1 as const, quoteId: accepted.quoteId, acceptedRevision: accepted.revision,
      agreementFingerprint: accepted.acceptance.agreementFingerprint, lines: supplierQuote.lines};
    const queriedLine = {lineId: 'placed-line-one', skuRevision: 1, quantity: 10, listing: {
      schemaVersion: 1 as const, realm: 'evaluation' as const, storeId: 'store-one', skuId: 'sku-one', listingId,
      canonicalProductId: 'canonical-one', verifiedPackId: 'pack-one', channel: 'bulk' as const}};
    const readPrices = (actor = 'buyer-one', ref = reference, lines = [queriedLine]) =>
      db.runTransaction(tx => service().readCouponPrices(tx, actor, 'store-one', ref, lines));
    assert.deepEqual((await readPrices()).prices, [{lineId: 'placed-line-one', unitPriceMinor: 10025, merchandiseMinor: 100250}]);
    await assert.rejects(readPrices('other-buyer'), {code: 'not_found'});
    for (const changed of [{...queriedLine, quantity: 15}, {...queriedLine, skuRevision: 2},
      {...queriedLine, listing: {...queriedLine.listing, verifiedPackId: 'wrong-pack'}}]) await assert.rejects(readPrices('buyer-one', reference, [changed]));
    let couponExpireDuringRead = false;
    const couponRepo = () => new FirestorePromotionRepository(db, 'evaluation', () => new Date(clock), service());
    const couponService = () => new WorkspacePromotionService(couponRepo(), {
      publicCatalogue: async () => {throw new Error('Use actual transactional price snapshot seam');},
      couponPriceSnapshot: async (_store, ids) => {
        const pages = ids.map(skuId => {const bulk = skuId === 'sku-one', kind = bulk ? 'bulk' : 'retail';
          return {schemaVersion: 1, realm: 'evaluation', storeId: 'store-one', state: 'ready', coverage: 'verified_public_only',
            listingReadbackVersion: 1, listingCoverage: 'complete', catalogueVersion: 7, observedAt: clock, nextCursor: null,
            items: [{skuId, revision: 1, canonicalProductId: bulk ? 'canonical-one' : 'canonical-two', verifiedPackId: bulk ? 'pack-one' : 'pack-two',
              listings: [{schemaVersion: 1, realm: 'evaluation', storeId: 'store-one', skuId, channel: kind,
                canonicalProductId: bulk ? 'canonical-one' : 'canonical-two', verifiedPackId: bulk ? 'pack-one' : 'pack-two',
                listingId: `listing-${cataloguePayloadHash([1, 'evaluation', 'store-one', skuId, kind]).toLowerCase()}`}],
              channels: [{kind, offerId: `offer-${skuId}`, revision: 'host-price-v1', priceMinor: bulk ? 20000 : 500,
                minimumOrder: bulk ? 10 : 1, quantityStep: bulk ? 5 : 1, tiers: [], validUntil: '2026-10-21T12:00:00.000Z'}]}]};});
        if (couponExpireDuringRead) clock = accepted.offer.validUntil;
        return pages;
      }}, () => new Date(clock), {storeCouponTermsSupported: true, storeCouponEligibilitySupported: true});
    const campaign = {name: 'Host agreed-price savings', percentage: true, discount: 1000, minimumSpendMinor: 150000,
      maximumSavingMinor: 50000, startsAt: clock, endsAt: '2026-10-21T12:00:00.000Z', totalUses: 20, usesPerCustomer: 2, active: true};
    await couponService().handleOperation('supplier-one', 'saveStoreCoupon', {storeCouponTermsVersion: 1, storeId: 'store-one',
      couponId: 'coupon-bulk', expectedRevision: 0, idempotencyKey: 'create-bulk-coupon', fundingAcknowledged: true, coupon: campaign});
    const couponLine = {...queriedLine, offerId: 'offer-sku-one', offerRevision: 'host-price-v1'};
    const couponQuery = {storeCouponEligibilityVersion: 2, storeId: 'store-one', couponId: 'coupon-bulk', couponRevision: 1,
      selectionPolicy: 'exclusive_store_basket', supplierQuote: reference, lines: [couponLine]};
    const evaluate = (query: Record<string, unknown> = couponQuery, actor = 'buyer-one') =>
      couponService().handleOperation(actor, 'evaluateStoreCouponEligibility', query) as Promise<Record<string, any>>;
    const lower = await evaluate(); assert.equal(lower.eligible, false); assert.equal(lower.reason, 'minimum_spend');
    const {supplierQuote: _unusedQuote, ...oldQuery} = couponQuery;
    assert.equal((await evaluate({...oldQuery, storeCouponEligibilityVersion: 1})).eligible, true);
    await couponService().handleOperation('supplier-one', 'saveStoreCoupon', {storeCouponTermsVersion: 1, storeId: 'store-one',
      couponId: 'coupon-bulk', expectedRevision: 1, idempotencyKey: 'amend-bulk-coupon', fundingAcknowledged: true,
      coupon: {...campaign, minimumSpendMinor: 0}});
    couponQuery.couponRevision = 2;
    const negotiated = await evaluate(); assert.equal(negotiated.storeCouponEligibilityVersion, 2);
    assert.equal(negotiated.evaluation.eligibleSubtotalMinor, 100250); assert.equal(negotiated.evaluation.savingMinor, 10025);
    assert.deepEqual(negotiated.supplierQuote, reference); assert.equal(negotiated.reservationCreated, false);
    assert.equal(Date.parse(negotiated.validUntil) <= Date.parse(accepted.offer.validUntil), true);
    const retailLine = {lineId: 'retail-line', skuRevision: 1, quantity: 2, offerId: 'offer-sku-two', offerRevision: 'host-price-v1',
      listing: {schemaVersion: 1, realm: 'evaluation', storeId: 'store-one', skuId: 'sku-two', canonicalProductId: 'canonical-two',
        verifiedPackId: 'pack-two', channel: 'retail', listingId: `listing-${cataloguePayloadHash([1, 'evaluation', 'store-one', 'sku-two', 'retail']).toLowerCase()}`}};
    const mixed = await evaluate({...couponQuery, lines: [couponLine, retailLine]});
    assert.equal(mixed.evaluation.eligibleSubtotalMinor, 101250); assert.equal(mixed.evaluation.savingMinor, 10125);
    await assert.rejects(evaluate(couponQuery, 'other-buyer'));
    await assert.rejects(evaluate({...couponQuery, supplierQuote: {...reference, lines: []}}));
    const beforeCouponExpiry = clock; couponExpireDuringRead = true; await assert.rejects(evaluate());
    clock = beforeCouponExpiry; couponExpireDuringRead = false;
    const couponUsage = db.collection('workspaceCatalogues').doc('evaluation').collection('stores').doc('store-one').collection('storeCouponUsage').doc('coupon-bulk');
    assert.equal((await couponUsage.get()).get('heldUses'), 0);
    assert.equal((await couponUsage.collection('customers').get()).size, 0);
    if (process.env.LF_BULK_COUPON_CAPTURE === 'true') console.log(`LF_BULK_COUPON_PROJECTION=${JSON.stringify({query: couponQuery, accepted, lower, negotiated, mixed})}`);
    const placement: TrustedPlacementReceipt = {schemaVersion: 7, realm: 'evaluation', authNamespace: 'firebase-default',
      finalPlacement: true, issuer: 'isolated-final-source', receiptId: 'final-one', revision: 'revision-one', buyerUserId: 'buyer-one',
      stores: [{storeId: 'store-one', caseId: 'case-one', ownerUserId: 'supplier-one', benefitAttribution: {schemaVersion: 1, components: []},
        fulfilmentContext: null, supplierQuote, lines: [{sourceLineId: 'placed-line-one', skuId: 'sku-one',
          canonicalProductId: 'canonical-one', verifiedPackId: 'pack-one', offerId: 'isolated-offer-one', offerRevision: 'offer-v1',
          name: 'Isolated Bulk rice', packLabel: '25 kg bag', variant: 'Aged\ngrain', quantityMilli: 10000, quantityUnit: 'pack',
          unitPriceMinor: 10025, lineTotalMinor: 100250, scheduledFulfilment: null,
          publicListing: {schemaVersion: 1, realm: 'evaluation', storeId: 'store-one', skuId: 'sku-one', listingId,
            canonicalProductId: 'canonical-one', verifiedPackId: 'pack-one', channel: 'bulk'}}],
        totals: {itemsMinor: 100250, discountMinor: 0, taxMinor: 0, deliveryMinor: 0, freightMinor: 0, paymentFeeMinor: 0, tipMinor: 0, totalMinor: 100250}}]};
    assert.deepEqual(normalizePlacement(placement, 'evaluation'), placement);
    const rootForBinding = db.collection('workspacePurchaseProjections').doc('evaluation');
    const materializer = (receipt: TrustedPlacementReceipt, binding = service()) => new WorkspacePurchaseProjectionService(db,
      'evaluation', {readFinalPlacement: async () => receipt}, undefined, binding);
    await assert.rejects(new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => placement})
      .materialize('isolated-final'), {code: 'service_unavailable'});
    for (const corrupt of [
      (r: TrustedPlacementReceipt) => {r.buyerUserId = 'other-buyer';},
      (r: TrustedPlacementReceipt) => {r.stores[0]!.lines[0]!.verifiedPackId = 'other-pack';
        r.stores[0]!.lines[0]!.publicListing!.verifiedPackId = 'other-pack';},
      (r: TrustedPlacementReceipt) => {r.stores[0]!.supplierQuote!.agreementFingerprint = 'f'.repeat(64);},
      (r: TrustedPlacementReceipt) => {r.stores[0]!.supplierQuote!.validUntil = '2030-01-01T00:00:00.000Z';},
      (r: TrustedPlacementReceipt) => {r.stores[0]!.supplierQuote!.lines[0]!.quoteLineId = 'wrong-line';},
      (r: TrustedPlacementReceipt) => {r.stores[0]!.supplierQuote = null;},
    ]) {const candidate = structuredClone(placement); corrupt(candidate); await assert.rejects(materializer(candidate).materialize('isolated-final'));}
    const failingBinding = {preparePurchase: async (...args: Parameters<WorkspaceBulkQuoteService['preparePurchase']>) => {
      const prepared = await service().preparePurchase(...args);
      return {...prepared, commit: () => {prepared.commit(); throw new Error('isolated post-prepare failure');}};
    }};
    await assert.rejects(new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => placement},
      undefined, failingBinding).materialize('isolated-final'), /isolated post-prepare failure/);
    assert.equal((await rootForBinding.collection('bulkQuoteUses').get()).size, 0);
    assert.equal((await rootForBinding.collection('purchases').get()).size, 0);
    const couponPlacement = structuredClone(placement), store = couponPlacement.stores[0]!;
    const attribution = storeCouponAttributionReferences('evaluation', 'store-one', 'coupon-bulk', 2);
    store.totals.discountMinor = 10025; store.totals.totalMinor = 90225;
    store.benefitAttribution!.components = [{componentId: 'bulk-coupon-component', benefitId: 'coupon-bulk', label: campaign.name,
      ...attribution, publisherType: 'supplier', effect: 'instant_discount', amountBasis: 'applied', amountMinor: 10025,
      allocations: [{lineId: 'placed-line-one', amountMinor: 10025}]}];
    couponPlacement.couponUseContext = {schemaVersion: 1, stores: [{storeId: 'store-one', couponId: 'coupon-bulk', couponRevision: 2,
      componentId: 'bulk-coupon-component', holdUntil: negotiated.validUntil, lifecycleSourceId: 'host-future-payment-source', basket: {
        schemaVersion: 2, realm: 'evaluation', storeId: 'store-one', buyerUserId: 'buyer-one', couponRevision: 2,
        sourceId: negotiated.evaluation.basketSourceId, sourceRevision: negotiated.evaluation.basketSourceRevision,
        observedAt: negotiated.observedAt, validUntil: negotiated.validUntil, supplierQuote: reference,
        lines: [{lineId: 'placed-line-one', storeId: 'store-one', skuId: 'sku-one', packId: 'pack-one', offerId: 'isolated-offer-one',
          offerRevision: 'offer-v1', priceSourceId: cataloguePayloadHash(reference), channel: 'bulk', quantity: 10, unitPriceMinor: 10025, otherCouponApplied: false}]}}]};
    await assert.rejects(new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => couponPlacement},
      couponRepo(), failingBinding).materialize('isolated-with-coupon'), /isolated post-prepare failure/);
    assert.equal((await couponUsage.get()).get('heldUses'), 0);
    assert.equal((await rootForBinding.collection('bulkQuoteUses').get()).size, 0);
    const unexpired = clock;
    clock = accepted.offer.validUntil;
    await assert.rejects(materializer(placement).materialize('isolated-final'), {code: 'conflict'});
    assert.equal((await rootForBinding.collection('bulkQuoteUses').get()).size, 0);
    clock = unexpired;
    const expiringBinding = {preparePurchase: async (...args: Parameters<WorkspaceBulkQuoteService['preparePurchase']>) => {
      const prepared = await service().preparePurchase(...args);
      return {...prepared, commit: () => {clock = accepted.offer.validUntil; prepared.commit();}};
    }};
    await assert.rejects(new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => placement},
      undefined, expiringBinding).materialize('isolated-final'), {code: 'conflict'});
    clock = unexpired;
    assert.equal((await rootForBinding.collection('bulkQuoteUses').get()).size, 0);
    const later = {...structuredClone(placement), receiptId: 'final-two'};
    const purchases = [materializer(placement), materializer(later)];
    const attempts = await Promise.allSettled(purchases.map(p => p.materialize('isolated-final')));
    assert.equal(attempts.filter(result => result.status === 'fulfilled').length, 1);
    assert.equal((await rootForBinding.collection('bulkQuoteUses').get()).size, 1);
    await assert.rejects(evaluate(), {code: 'conflict'});
    const winnerIndex = attempts.findIndex(result => result.status === 'fulfilled'),
      purchase = (attempts[winnerIndex] as PromiseFulfilledResult<{purchaseId: string; buyerId: string}>).value;
    const originalRead = await purchases[winnerIndex]!.readBuyer('buyer-one', {purchaseId: purchase.purchaseId}) as any;
    assert.equal(originalRead.schemaVersion, 8);
    const original = originalRead.orders[0].original;
    assert.equal(original.supplierQuote.agreementFingerprint, supplierQuote.agreementFingerprint);
    assert.equal(original.supplierQuote.lines[0].lineId, original.lines[0].lineId);
    assert.notEqual(original.supplierQuote.lines[0].lineId, 'placed-line-one');
    const sellerOriginal = await purchases[winnerIndex]!.readStore('supplier-one', {purchaseId: purchase.purchaseId,
      storeId: 'store-one', orderId: originalRead.orders[0].orderId});
    assert.deepEqual(sellerOriginal.orders[0]!.original, original);
    if (process.env.LF_BULK_PURCHASE_CAPTURE === 'true') console.log(`LF_BULK_PURCHASE_PROJECTION=${JSON.stringify({buyer: originalRead, seller: sellerOriginal})}`);
    const beforeExpiry = clock;
    clock = accepted.offer.validUntil;
    await assert.rejects(materializer({...structuredClone(placement), receiptId: 'expired-new'}).materialize('isolated-final'));
    assert.deepEqual(await purchases[winnerIndex]!.materialize('isolated-final'), purchase);
    assert.deepEqual(await purchases[winnerIndex]!.readBuyer('buyer-one', {purchaseId: purchase.purchaseId}), originalRead);
    clock = beforeExpiry;
    const recovered = await service().reconcile('buyer-one', {schemaVersion: 1, originalOperation: 'request', original: request}) as any;
    assert.equal(recovered.state, 'recorded'); assert.deepEqual(recovered.agreement, created);
    assert.deepEqual(recovered.currentHead, accepted);
    if (process.env.LF_BULK_API_CAPTURE === 'true') console.log(`LF_BULK_SERVICE_API=${JSON.stringify({
      capturedAt: clock, request, offer, accept, created, supplierRequested, offered, accepted, recovered, unobserved, buyerPage, storePage})}`);
    const superseded = await service().reconcile('supplier-one', {schemaVersion: 1, originalOperation: 'offer',
      original: {...offer, operationId: 'never-offer'}}) as any;
    assert.equal(superseded.state, 'superseded'); assert.equal(superseded.agreement, null);
    assert.deepEqual(superseded.proof, {expectedRevision: 1, currentRevision: 3, currentState: 'accepted'});
    await assert.rejects(service().reconcile('supplier-one', {schemaVersion: 1, originalOperation: 'offer',
      original: {...offer, prices: [{lineId: 'line-one', unitPriceMinor: 10026}]}}), {code: 'conflict'});
    await assert.rejects(service().reconcile('other-buyer', {schemaVersion: 1, originalOperation: 'accept', original: accept}), {code: 'not_found'});
    const seller = await service().read('supplier-one', scope) as any;
    assert.equal(seller.viewerRole, 'supplier'); assert.deepEqual(seller.acceptance, accepted.acceptance);
    assert.equal(JSON.stringify(seller).includes('buyer-one'), false); assert.equal(JSON.stringify(accepted).includes('supplier-one'), false);
    await assert.rejects(service().withdraw('supplier-one', {...accept, operationId: 'withdraw-one', expectedRevision: 3}));
    await assert.rejects(service().offer('supplier-one', {...offer, operationId: 'offer-two', expectedRevision: 3}));
    const race = await service().request('buyer-one', {...request, requestId: 'race-request'}) as any;
    const raceOffer = {...offer, quoteId: race.quoteId, operationId: 'race-offer'};
    await service().offer('supplier-one', raceOffer);
    const raceAccept = {...accept, quoteId: race.quoteId, operationId: 'race-accept'};
    const raceWithdraw = {...raceAccept, operationId: 'race-withdraw'};
    const racing = await Promise.allSettled([service().accept('buyer-one', raceAccept), service().withdraw('supplier-one', raceWithdraw)]);
    assert.equal(racing.filter(r => r.status === 'fulfilled').length, 1);
    const winner = await service().read('buyer-one', {quoteId: race.quoteId}) as any;
    const firstPage = await service().listBuyer('buyer-one', page) as any;
    assert.equal(firstPage.summaries.length, 1); assert.equal(typeof firstPage.nextCursor, 'string');
    const lastPage = await service().listBuyer('buyer-one', {...page, cursor: firstPage.nextCursor}) as any;
    assert.equal(lastPage.summaries.length, 1); assert.equal(lastPage.nextCursor, null);
    assert.notEqual(firstPage.summaries[0].quoteId, lastPage.summaries[0].quoteId);
    const invalidPosition = JSON.parse(Buffer.from(firstPage.nextCursor, 'base64url').toString('utf8'));
    invalidPosition.after = `bulk-${'0'.repeat(64)}`;
    await assert.rejects(service().listBuyer('buyer-one', {...page,
      cursor: Buffer.from(JSON.stringify(invalidPosition)).toString('base64url')}), {code: 'not_found'});
    for (const candidate of [
      () => service().listBuyer('other-buyer', {...page, cursor: firstPage.nextCursor}),
      () => service().listBuyer('buyer-one', {limit: 2, cursor: firstPage.nextCursor}),
      () => service().listStore('supplier-one', {storeId: 'store-one', ...page, cursor: firstPage.nextCursor}),
      () => new WorkspaceBulkQuoteService(db, 'production', source, () => new Date(clock)).listBuyer('buyer-one', {...page, cursor: firstPage.nextCursor}),
    ]) await assert.rejects(candidate());
    assert.equal(winner.revision, 3); assert.ok(['accepted', 'withdrawn'].includes(winner.state));
    if (winner.state === 'accepted') assert.deepEqual(await service().accept('buyer-one', raceAccept), winner);
    else assert.equal((await service().withdraw('supplier-one', raceWithdraw) as any).state, 'withdrawn');
    revision = 2; clock = '2026-10-22T12:00:00.000Z';
    const frozenReads = sourceReads;
    const originalAccept = await service().reconcile('buyer-one', {schemaVersion: 1, originalOperation: 'accept', original: accept}) as any;
    assert.equal(originalAccept.state, 'recorded'); assert.deepEqual(originalAccept.agreement, accepted);
    assert.equal(sourceReads, frozenReads);
    assert.deepEqual(await service().accept('buyer-one', accept), accepted); // Original, not a new acceptance after expiry.
    assert.deepEqual(await service().offer('supplier-one', offer), offered);
    const heavyLines = Array.from({length: 80}, (_, i) => ({lineId: `line-${i}`, skuId: `sku-${i}`,
      listingId: `listing-${hash(['heavy-listing', i])}`, skuRevision: 1, quantity: 10}));
    const heavySource = {bulkQuotationSnapshot: async () => {
      const base = (await sourceFixture.bulkQuotationSnapshot())[0]!.items[0]!;
      return heavyLines.map(line => ({state: 'ready', realm: 'evaluation', storeId: 'store-one',
        publicStore: {id: 'store-one', name: 'Isolated Bulk supplier', profileId: 'wholesaler'}, items: [{...base,
        skuId: line.skuId, revision: 1, channels: [{kind: 'bulk', minimumOrder: 10, quantityStep: 5, validUntil: '2030-01-01T00:00:00.000Z'}],
        listings: [{...base.listings[0], skuId: line.skuId, listingId: line.listingId}],
        supplierPolicy: {...base.supplierPolicy, skuId: line.skuId, policy: {...base.supplierPolicy.policy,
          productIds: [line.skuId], body: 'x'.repeat(12000)}},
      }]}));
    }};
    await assert.rejects(new WorkspaceBulkQuoteService(db, 'evaluation', heavySource, () => new Date(clock)).request('buyer-one',
      {...request, requestId: 'heavy-request', lines: heavyLines}), {code: 'invalid_input', httpStatus: 400});
    await db.collection('workspaceProfiles').doc('case-one').update({ownerUserId: 'new-supplier'});
    await assert.rejects(service().read('supplier-one', scope)); await assert.rejects(service().offer('supplier-one', offer));
    await assert.rejects(service().listStore('supplier-one', {storeId: 'store-one', ...page}), {code: 'not_found'});
    await assert.rejects(service().reconcile('supplier-one', {schemaVersion: 1, originalOperation: 'offer', original: offer}), {code: 'not_found'});
    await assert.rejects(service().read('new-supplier', scope));
    assert.deepEqual(await service().read('buyer-one', scope), accepted);
    const root = db.collection('workspacePurchaseProjections').doc('evaluation');
    assert.equal((await root.collection('bulkQuoteRequests').get()).size, 2);
    assert.equal((await root.collection('bulkQuoteCommands').get()).size, 6);
    assert.equal((await root.collection('purchases').get()).size, 1);
    for (const collection of ['operationalOrders', 'orderCompletions']) assert.equal((await root.collection(collection).get()).size, 0);
    // Independent successful v2 combination after the preceding legacy count
    // checks. Real local agreement + coupon + original writes, not phone data.
    revision = 1; clock = beforeCouponExpiry;
    await db.collection('workspaceProfiles').doc('case-one').set(profile);
    const fresh: any[] = [];
    for (const suffix of ['coupon-next-one', 'coupon-next-two']) {
      const created = await service().request('buyer-one', {...request, requestId: suffix}) as any;
      await service().offer('supplier-one', {...offer, quoteId: created.quoteId, operationId: `${suffix}-offer`});
      fresh.push(await service().accept('buyer-one', {...accept, quoteId: created.quoteId, operationId: `${suffix}-accept`}));
    }
    const references = fresh.map(a => ({...reference, quoteId: a.quoteId, acceptedRevision: a.revision,
      agreementFingerprint: a.acceptance.agreementFingerprint}));
    const evaluations = await Promise.all(references.map(ref => evaluate({...couponQuery, supplierQuote: ref})));
    assert.equal(evaluations[0]!.evaluation.savingMinor, evaluations[1]!.evaluation.savingMinor);
    assert.notEqual(evaluations[0]!.requestFingerprint, evaluations[1]!.requestFingerprint);
    assert.notEqual(evaluations[0]!.evaluation.basketFingerprint, evaluations[1]!.evaluation.basketFingerprint);
    const successful = structuredClone(couponPlacement), selectedReference = references[0]!;
    successful.receiptId = 'final-coupon-success';
    successful.stores[0]!.supplierQuote = {...supplierQuote, quoteId: fresh[0].quoteId,
      agreementFingerprint: fresh[0].acceptance.agreementFingerprint, acceptedAt: fresh[0].acceptance.acceptedAt};
    const selectedBasket = successful.couponUseContext!.stores[0]!.basket;
    selectedBasket.supplierQuote = selectedReference;
    selectedBasket.sourceId = evaluations[0]!.evaluation.basketSourceId;
    for (const line of selectedBasket.lines as Record<string, unknown>[]) line.priceSourceId = cataloguePayloadHash(selectedReference);
    const combined = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => successful}, couponRepo(), service());
    const combinedPurchase = await combined.materialize('combined-coupon-final');
    const originalCombined = await combined.readBuyer('buyer-one', {purchaseId: combinedPurchase.purchaseId});
    assert.equal(originalCombined.orders[0]!.original.totals.totalMinor, 90225);
    assert.equal(originalCombined.orders[0]!.original.supplierQuote!.quoteId, fresh[0].quoteId);
    assert.equal((await couponUsage.get()).get('heldUses'), 1);
    assert.equal((await root.collection('bulkQuoteUses').get()).size, 2);
    clock = accepted.offer.validUntil;
    assert.deepEqual(await combined.materialize('combined-coupon-final'), combinedPurchase);
    assert.equal((await couponUsage.get()).get('heldUses'), 1);
    assert.equal((await root.collection('bulkQuoteUses').get()).size, 2);
  } finally { await deleteApp(app); }
});

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
  const app = initializeApp({projectId: "demo-lf-completion"}, `completion-${randomUUID()}`), db = purchaseTestFirestore(app);
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
  const db = purchaseTestFirestore(app);
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
function fulfilmentContextReceipt() {
  const value = publicListingReceipt(); value.schemaVersion = 6;
  for (const [index, store] of value.stores.entries()) store.fulfilmentContext = {
    schemaVersion: 1, method: index === 0 ? 'delivery' : 'collection',
    recipient: {name: index === 0 ? 'Evaluation recipient A' : 'Evaluation recipient B', phone: index === 0 ? '9876501234' : ''},
    address: index === 0 ? {line: 'Evaluation house 12', area: 'Evaluation area', pinCode: '342003', landmark: ''} : null,
    instructions: [{lineId: store.lines[0].sourceLineId, text: index === 0 ? 'दरवाज़े पर दें' : 'Keep the exact ordered pack'}],
  };
  return value;
}
function supplierTaxReceipt() {
  const value = fulfilmentContextReceipt(); value.schemaVersion = 8;
  for (const [index, store] of value.stores.entries()) {
    store.supplierQuote = null;
    for (const line of store.lines) line.supplierTaxSnapshot = index === 0 ? {
      schemaVersion: 1, termsRevision: 'purchased-terms-v1',
      observedAt: '2026-10-01T12:00:00.000Z', expiresAt: '2026-10-02T12:00:00.000Z',
      declaration: {version: 2, rateBasisPoints: 500, basis: 'included'},
    } : null;
  }
  return value;
}

function commodityOriginalReceipt() {
  const value = supplierTaxReceipt(); value.schemaVersion = 9;
  for (const [index, store] of value.stores.entries()) {
    for (const line of store.lines) line.commodityPriceSnapshot = null;
    if (index !== 0) continue;
    const line = store.lines[0];
    line.offerRevision = 'commodity-2-AAAAAAAAAAAAAAAA';
    line.publicListing.channel = 'bulk';
    line.publicListing.listingId = `listing-${createHash('sha256').update(JSON.stringify(
      [1, 'evaluation', store.storeId, line.skuId, 'bulk'])).digest('hex')}`;
    if (line.scheduledFulfilment) line.scheduledFulfilment.listing = structuredClone(line.publicListing);
    line.commodityPriceSnapshot = {schemaVersion: 1, termsRevision: line.offerRevision, confirmationRevision: 2,
      confirmedAt: '2026-10-01T12:00:00.000Z', validUntil: '2026-10-01T14:00:00.000Z', frequent: true,
      agreedAt: '2026-10-01T12:10:00.000Z', priceMinor: line.unitPriceMinor,
      minimumPacks: 1, incrementPacks: 1, tiers: []};
  }
  return value;
}

test('LF-COMMODITY-ORIGINAL direct Bulk preserves a purchased confirmation without a negotiated quote', () => {
  const input = commodityOriginalReceipt();
  assert.deepEqual(normalizePlacement(input, 'evaluation'), input);
  assert.equal(input.stores[0].supplierQuote, null);
  assert.equal(input.stores[1].lines[0].commodityPriceSnapshot, null);
  assert.deepEqual(input.stores.map((s: any) => s.totals), supplierTaxReceipt().stores.map((s: any) => s.totals));
  input.stores[0].lines[0].commodityPriceSnapshot.incrementPacks = 1000000;
  assert.deepEqual(normalizePlacement(input, 'evaluation'), input, 'Match the existing source quantity-step bound.');
});

test('LF-COMMODITY-ORIGINAL direct Wholesale cannot omit its confirmed-price provenance', () => {
  const input = commodityOriginalReceipt(), store = input.stores[0], l = store.lines[0];
  l.publicListing.channel = 'wholesale';
  l.publicListing.listingId = `listing-${createHash('sha256').update(JSON.stringify(
    [1, 'evaluation', store.storeId, l.skuId, 'wholesale'])).digest('hex')}`;
  if (l.scheduledFulfilment) l.scheduledFulfilment.listing = structuredClone(l.publicListing);
  assert.deepEqual(normalizePlacement(input, 'evaluation'), input);
  l.commodityPriceSnapshot = null;
  assert.throws(() => normalizePlacement(input, 'evaluation'), rejectsCode('invalid_input'));
});

test('LF-COMMODITY-ORIGINAL tier applicability and mixed quote authority remain exact', () => {
  const input = commodityOriginalReceipt(), store = input.stores[0], direct = store.lines[0];
  const oldTotal = direct.lineTotalMinor;
  direct.quantityMilli = 3000; direct.unitPriceMinor = 9001; direct.lineTotalMinor = 27003;
  direct.commodityPriceSnapshot.tiers = [{minimumPacks: 1, unitPriceMinor: 10051}, {minimumPacks: 3, unitPriceMinor: 9001}];
  store.totals.itemsMinor += direct.lineTotalMinor - oldTotal; store.totals.totalMinor += direct.lineTotalMinor - oldTotal;
  const quoted = {...structuredClone(direct), sourceLineId: 'quoted-source', skuId: 'quoted-sku',
    offerRevision: 'legacy-terms', scheduledFulfilment: null, commodityPriceSnapshot: null};
  quoted.publicListing.skuId = quoted.skuId;
  quoted.publicListing.listingId = `listing-${createHash('sha256').update(JSON.stringify(
    [1, 'evaluation', store.storeId, quoted.skuId, 'bulk'])).digest('hex')}`;
  store.lines.push(quoted); store.lines.sort((a: any,b: any) => a.sourceLineId.localeCompare(b.sourceLineId));
  store.totals.itemsMinor += quoted.lineTotalMinor; store.totals.totalMinor += quoted.lineTotalMinor;
  store.supplierQuote = {schemaVersion: 1, realm: 'evaluation', quoteId: `bulk-${'a'.repeat(64)}`,
    acceptedRevision: 3, agreementFingerprint: 'b'.repeat(64), offerRevision: 2,
    acceptedAt: '2026-10-01T12:10:00.000Z', validUntil: '2026-10-01T14:00:00.000Z',
    merchandiseMinor: quoted.lineTotalMinor, lines: [{lineId: quoted.sourceLineId, quoteLineId: 'quote-line-one'}]};
  assert.deepEqual(normalizePlacement(input, 'evaluation'), input);
  store.supplierQuote.lines.push({lineId: direct.sourceLineId, quoteLineId: 'quote-line-two'});
  assert.throws(() => normalizePlacement(input, 'evaluation'), rejectsCode('invalid_input'));
});

for (const [name, mutate] of Object.entries({
  missing: (l: any) => {delete l.commodityPriceSnapshot;},
  nullBulk: (l: any) => {l.commodityPriceSnapshot = null;},
  unknownVersion: (l: any) => {l.commodityPriceSnapshot.schemaVersion = 2;},
  revision: (l: any) => {l.commodityPriceSnapshot.confirmationRevision = 3;},
  source: (l: any) => {l.commodityPriceSnapshot.termsRevision = 'commodity-2-BBBBBBBBBBBBBBBB';},
  futureConfirmation: (l: any) => {l.commodityPriceSnapshot.confirmedAt = '2026-10-01T12:11:00.000Z';},
  expiredAgreement: (l: any) => {l.commodityPriceSnapshot.agreedAt = l.commodityPriceSnapshot.validUntil;},
  retail: (l: any) => {l.publicListing.channel = 'retail';},
  missingListing: (l: any) => {l.publicListing = null; l.scheduledFulfilment = null;},
  measured: (l: any) => {l.quantityUnit = 'L';},
  fractionalPack: (l: any) => {l.quantityMilli = 1500;},
  minimum: (l: any) => {l.commodityPriceSnapshot.minimumPacks = 2;},
  step: (l: any) => {l.commodityPriceSnapshot.incrementPacks = 0;},
  price: (l: any) => {l.commodityPriceSnapshot.priceMinor++;},
  tier: (l: any) => {l.commodityPriceSnapshot.tiers = [{minimumPacks: 2, unitPriceMinor: l.unitPriceMinor}];},
  claim: (l: any) => {l.commodityPriceSnapshot.paid = true;},
})) test(`LF-COMMODITY-ORIGINAL rejects ${name}`, () => {
  const input = commodityOriginalReceipt(); mutate(input.stores[0].lines[0]);
  assert.throws(() => normalizePlacement(input, 'evaluation'), rejectsCode('invalid_input'));
});

test('LF-COMMODITY-ORIGINAL legacy contracts reject the new field and retain original bytes', () => {
  const legacy = supplierTaxReceipt(); assert.deepEqual(normalizePlacement(legacy, 'evaluation'), legacy);
  for (const store of legacy.stores) for (const l of store.lines) l.commodityPriceSnapshot = null;
  assert.throws(() => normalizePlacement(legacy, 'evaluation'), rejectsCode('invalid_input'));
});

function purchaserReceipt(kind: 'personal' | 'store' = 'store') {
  const value = commodityOriginalReceipt(); value.schemaVersion = 10;
  value.purchaser = kind === 'personal' ? {schemaVersion: 1, kind} : {
    schemaVersion: 1, kind, storeId: 'buying-store', name: 'Evaluation buying Store', purpose: 'restock'};
  value.purchasingStoreCaseId = kind === 'personal' ? null : 'buying-case';
  for (const store of value.stores) for (const line of store.lines) {
    if (line.publicListing?.channel === 'retail') {
      line.publicListing.channel = 'wholesale';
      line.publicListing.listingId = `listing-${createHash('sha256').update(JSON.stringify(
        [1, 'evaluation', store.storeId, line.skuId, 'wholesale'])).digest('hex')}`;
      if (line.scheduledFulfilment) line.scheduledFulfilment.listing = structuredClone(line.publicListing);
    }
  }
  return value;
}

test('LF-RESTOCK-ARRIVAL existing purchase service owns private physical report and recovery', () => {
  for (const method of ['recordBuyerGoodsArrival', 'reconcileBuyerGoodsArrival', 'readBuyerGoodsReceiving', 'closeBuyerGoodsArrival']) {
    assert.equal(typeof Reflect.get(WorkspacePurchaseProjectionService.prototype, method), 'function', method);
  }
});

test('LF-RESTOCK-ARRIVAL transactional partials retries current ownership and private readback', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST, timeout: 60000,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-arrival-${randomUUID().slice(0,8)}`}, `arrival-${randomUUID()}`),
    db = purchaseTestFirestore(app), input = purchaserReceipt(), actor = input.buyerUserId;
  const profile = {schemaVersion: 1, caseId: 'buying-case', workspaceId: 'buying-store', ownerUserId: actor,
    familyId: 'products-trade', profileId: 'retailer-grocery', status: 'live', shopEnabled: false};
  const service = () => new WorkspacePurchaseProjectionService(db, 'evaluation') as any;
  try {
    for (const store of input.stores) await db.collection('workspaceProfiles').doc(store.caseId).set({schemaVersion: 1,
      caseId: store.caseId, workspaceId: store.storeId, ownerUserId: store.ownerUserId, familyId: 'products-trade',
      profileId: 'wholesaler', status: 'live', shopEnabled: true});
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    const writer = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => input});
    // Materialization requires an enabled purchasing Store; historical receiving does not require new public sales.
    await db.collection('workspaceProfiles').doc(profile.caseId).update({shopEnabled: true});
    const made = await writer.materialize('arrival-placement');
    await db.collection('workspaceProfiles').doc(profile.caseId).update({shopEnabled: false});
    const original = (await service().readBuyer(actor, {purchaseId: made.purchaseId, buyingStoreId: profile.workspaceId}))
      .orders.find((order: any) => order.storeId === input.stores[0].storeId);
    const orderedLine = original.original.lines.find((line: any) => line.skuId === input.stores[0].lines[0].skuId &&
      line.verifiedPackId === input.stores[0].lines[0].verifiedPackId);
    assert.equal(orderedLine.quantityMilli, 1000); assert.equal(orderedLine.quantityUnit, 'pack');
    const reference = {purchaseId: made.purchaseId, storeId: original.storeId, orderId: original.orderId,
      originalFingerprint: original.originalFingerprint, sourceRevision: input.revision};
    const groupId = `restock-${createHash('sha256').update(JSON.stringify(['evaluation', profile.workspaceId,
      made.purchaseId, original.storeId, original.orderId])).digest('hex')}`;
    const source = {schemaVersion: 1, realm: 'evaluation', accountScope: actor, buyingStoreId: profile.workspaceId,
      reference, lines: original.original.lines.map((line: any) => ({lineId: line.lineId,
        quantityMilli: line.quantityMilli, quantityUnit: line.quantityUnit}))};
    const command = (id: string, deliveredMilli: number) => ({schemaVersion: 1, buyingStoreId: profile.workspaceId,
      supplierId: 'host-local-supplier', receipt: {id, expectedDeliveryId: groupId, reference: 'HOST physical arrival',
        deliveredOn: '2026-10-01', recordedAt: '2026-10-21T12:00:00.000Z', recordedUtcOffsetMinutes: 0, restockOriginal: structuredClone(source),
        lines: [{sourceLineId: orderedLine.lineId, productId: 'host-stock-product', productLabel: 'HOST saved Stock',
          purchaseUnit: orderedLine.quantityUnit, stockUnit: 'piece', unitsPerPack: 10,
          deliveredMilli, acceptedMilli: deliveredMilli, damagedMilli: 0, shortMilli: 0,
          expectedMilli: orderedLine.quantityMilli, priorStockUnits: {}}]}});
    const read = {schemaVersion: 1, buyingStoreId: profile.workspaceId, reference};
    assert.equal((await service().readBuyerGoodsReceiving(actor, read)).group, null);
    const unrecorded = command('host-closed-before-record', 600);
    const closed = await service().closeBuyerGoodsArrival(actor, unrecorded);
    assert.equal(closed.state, 'closed'); assert.equal(closed.proof.outcome, 'closed');
    assert.equal(closed.group, null);
    assert.deepEqual((await service().closeBuyerGoodsArrival(actor, unrecorded)).proof, closed.proof);
    assert.deepEqual((await service().reconcileBuyerGoodsArrival(actor, unrecorded)).proof, closed.proof);
    assert.deepEqual((await service().recordBuyerGoodsArrival(actor, unrecorded)).proof, closed.proof,
      'A delayed record must lose to the immutable closure fence.');
    assert.equal((await service().readBuyerGoodsReceiving(actor, read)).group, null);
    const changedClosed = structuredClone(unrecorded); changedClosed.receipt.reference = 'HOST changed closure';
    for (const method of ['recordBuyerGoodsArrival', 'closeBuyerGoodsArrival', 'reconcileBuyerGoodsArrival']) {
      await assert.rejects(service()[method](actor, changedClosed), rejectsCode('conflict'));
    }
    await assert.rejects(service().closeBuyerGoodsArrival('other-buyer', unrecorded));
    const a = command('host-arrival-one', 600), b = command('host-arrival-two', 600);
    for (const mutate of [
      (v: any) => {v.receipt.restockOriginal.accountScope = 'other-buyer';},
      (v: any) => {v.receipt.restockOriginal.realm = 'production';},
      (v: any) => {v.receipt.restockOriginal.lines[0].quantityMilli = 2000; v.receipt.lines[0].expectedMilli = 2000;},
      (v: any) => {v.receipt.restockOriginal.lines = [];},
      (v: any) => {v.receipt.paid = true;},
      (v: any) => {v.receipt.lines[0].deliveredMilli = 1.5;},
      (v: any) => {v.receipt.lines[0].unitsPerPack = 3;},
      (v: any) => {v.receipt.lines[0].priorStockUnits = {'host-unverified-stock-entry': 7};},
      (v: any) => {v.receipt.deliveredOn = '2099-01-01';},
      (v: any) => {v.receipt.expectedDeliveryId = 'host-other-group';},
      (v: any) => {v.receipt.recordedAt = '2026-02-30T12:00:00.000Z';},
      (v: any) => {v.receipt.recordedAt = '2026-10-19T12:00:00.000Z'; v.receipt.deliveredOn = '2026-10-21';},
      (v: any) => {delete v.receipt.recordedUtcOffsetMinutes;},
      (v: any) => {v.receipt.recordedUtcOffsetMinutes = 841;},
      (v: any) => {v.receipt.recordedUtcOffsetMinutes = -721;},
      (v: any) => {v.receipt.lines[0].lotDetails = {schemaVersion: 1, batch: 'HOST\x7fLOT', manufacturedLabel: '', expiryLabel: '', mrpMinor: null};},
      (v: any) => {v.supplierId = 'HOST\x7fSUPPLIER';},
      (v: any) => {v.receipt.reference = 'HOST\x7fREFERENCE';},
      (v: any) => {v.receipt.lines[0].productLabel = 'HOST\x7fPRODUCT';},
      (v: any) => {v.receipt.recordedAt = '2026-10-21T12:00:00.123000Z';},
    ]) {
      const bad = structuredClone(a); mutate(bad);
      await assert.rejects(service().recordBuyerGoodsArrival(actor, bad));
    }
    assert.equal((await service().readBuyerGoodsReceiving(actor, read)).group, null);
    assert.equal((await service().reconcileBuyerGoodsArrival(actor, a)).state, 'not_found');
    const concurrent = await Promise.allSettled([service().recordBuyerGoodsArrival(actor, a), service().recordBuyerGoodsArrival(actor, b)]);
    assert.equal(concurrent.filter(r => r.status === 'fulfilled').length, 1);
    const loser = concurrent.find(r => r.status === 'rejected') as PromiseRejectedResult;
    assert.equal(rejectsCode('conflict')(loser.reason), true, 'A transport failure must not masquerade as cumulative protection.');
    const winner = concurrent[0].status === 'fulfilled' ? a : b;
    const saved = await service().reconcileBuyerGoodsArrival(actor, winner);
    assert.equal(saved.state, 'recorded'); assert.equal(saved.proof.report, 'owner_reported');
    assert.deepEqual((await service().recordBuyerGoodsArrival(actor, winner)).proof, saved.proof);
    assert.deepEqual((await service().closeBuyerGoodsArrival(actor, winner)).proof, saved.proof,
      'A recorded winner cannot be reversed by closing.');
    const changed = structuredClone(winner); changed.receipt.lines[0]!.deliveredMilli = 500; changed.receipt.lines[0]!.acceptedMilli = 500;
    await assert.rejects(service().recordBuyerGoodsArrival(actor, changed), rejectsCode('conflict'));
    await assert.rejects(service().reconcileBuyerGoodsArrival(actor, changed), rejectsCode('conflict'));
    const otherSupplier = command('host-arrival-other-supplier', 400); otherSupplier.supplierId = 'host-other-supplier';
    await assert.rejects(service().recordBuyerGoodsArrival(actor, otherSupplier), rejectsCode('conflict'));
    const otherMapping = command('host-arrival-other-mapping', 400); otherMapping.receipt.lines[0]!.productId = 'host-other-product';
    await assert.rejects(service().recordBuyerGoodsArrival(actor, otherMapping), rejectsCode('conflict'));
    const remaining = command('host-arrival-remaining', 400);
    // The reporting day is local to the frozen report, including across device timezone changes.
    remaining.receipt.recordedAt = '2026-10-20T20:00:00.123456Z';
    remaining.receipt.recordedUtcOffsetMinutes = 330;
    remaining.receipt.deliveredOn = '2026-10-21';
    const last = await service().recordBuyerGoodsArrival(actor, remaining);
    assert.equal(last.proof.receipt.recordedUtcOffsetMinutes, 330);
    assert.equal(last.proof.receipt.recordedAt, remaining.receipt.recordedAt);
    assert.equal(last.group.lines[0].deliveredMilli, 1000);
    await assert.rejects(service().recordBuyerGoodsArrival(actor, command('host-arrival-overrun', 100)), rejectsCode('conflict'));
    const readback = await service().readBuyerGoodsReceiving(actor, read);
    assert.equal(readback.group.lines.length, 1);
    assert.equal(readback.group.revision, 2); assert.equal(readback.group.lines[0].acceptedMilli, 1000);
    assert.equal(readback.group.lines[0].mapping.productId, 'host-stock-product');
    for (const refused of [otherSupplier, otherMapping, command('host-arrival-overrun', 100)]) {
      const resolution = await service().closeBuyerGoodsArrival(actor, refused);
      assert.equal(resolution.state, 'closed'); assert.deepEqual(resolution.group, readback.group);
      assert.equal((await service().recordBuyerGoodsArrival(actor, refused)).state, 'closed');
      assert.deepEqual((await service().readBuyerGoodsReceiving(actor, read)).group, readback.group,
        'Closure after business rejection must not alter any cumulative quantities or revision.');
    }
    // A valid integrity checksum alone cannot make a corrupted cumulative projection contain the receipt.
    const groupDoc = db.collection('workspacePurchaseProjections').doc('evaluation').collection('goodsReceiving').doc(groupId);
    const canonical = (v: any): any => Array.isArray(v) ? v.map(canonical) : v && typeof v === 'object'
      ? Object.fromEntries(Object.keys(v).sort().map(key => [key, canonical(v[key])])) : v;
    for (const mutate of [
      (v: any) => {v.supplierId = 'host-corrupt-supplier';},
      (v: any) => {v.lines[0].mapping.productId = 'host-corrupt-product';},
      (v: any) => {v.lines[0].deliveredMilli = 100; v.lines[0].acceptedMilli = 100;},
    ]) {
      const {integrity: _integrity, ...bad} = structuredClone(readback.group); mutate(bad);
      await groupDoc.set({...bad, integrity: createHash('sha256').update(JSON.stringify(canonical(bad))).digest('hex')});
      await assert.rejects(service().reconcileBuyerGoodsArrival(actor, winner), rejectsCode('conflict'));
    }
    await groupDoc.set(readback.group);
    assert.deepEqual((await service().reconcileBuyerGoodsArrival(actor, winner)).proof, saved.proof);
    // A fully damaged arrival still needs durable identity, even though local Stock adds zero.
    const otherOriginal = (await service().readBuyer(actor, {purchaseId: made.purchaseId, buyingStoreId: profile.workspaceId}))
      .orders.find((order: any) => order.storeId !== original.storeId);
    assert.equal(otherOriginal.original.lines.length, 1);
    const zero = command(winner.receipt.id, 1000), otherReference = {...reference,
      storeId: otherOriginal.storeId, orderId: otherOriginal.orderId, originalFingerprint: otherOriginal.originalFingerprint};
    zero.receipt.restockOriginal.reference = otherReference;
    zero.receipt.restockOriginal.lines = otherOriginal.original.lines.map((line: any) => ({lineId: line.lineId,
      quantityMilli: line.quantityMilli, quantityUnit: line.quantityUnit}));
    zero.receipt.lines[0]!.sourceLineId = otherOriginal.original.lines[0].lineId;
    zero.receipt.lines[0]!.expectedMilli = otherOriginal.original.lines[0].quantityMilli;
    zero.receipt.lines[0]!.purchaseUnit = otherOriginal.original.lines[0].quantityUnit;
    assert.equal(otherOriginal.original.lines[0].quantityMilli, 1000);
    zero.receipt.lines[0]!.acceptedMilli = 0; zero.receipt.lines[0]!.damagedMilli = 1000;
    zero.receipt.expectedDeliveryId = `restock-${createHash('sha256').update(JSON.stringify(['evaluation', profile.workspaceId,
      made.purchaseId, otherOriginal.storeId, otherOriginal.orderId])).digest('hex')}`;
    await assert.rejects(service().recordBuyerGoodsArrival(actor, zero), rejectsCode('conflict'));
    zero.receipt.id = 'host-all-damaged-arrival';
    const damaged = await service().recordBuyerGoodsArrival(actor, zero);
    assert.equal(damaged.proof.receipt.lines[0].acceptedMilli, 0);
    assert.equal(damaged.group.lines[0].damagedMilli, 1000);
    assert.deepEqual((await service().reconcileBuyerGoodsArrival(actor, zero)).proof, damaged.proof);
    // Lifetime accepted units can exceed one arrival/current-on-hand's bound.
    const largeInput = purchaserReceipt(); largeInput.receiptId = 'host-large-purchase';
    const largeStore = largeInput.stores[0], largeLine = largeStore.lines[0], priorAmount = largeLine.lineTotalMinor;
    largeLine.quantityMilli = 3000000; largeLine.lineTotalMinor = largeLine.unitPriceMinor * 3000;
    largeStore.totals.itemsMinor += largeLine.lineTotalMinor - priorAmount;
    largeStore.totals.totalMinor += largeLine.lineTotalMinor - priorAmount;
    await db.collection('workspaceProfiles').doc(profile.caseId).update({shopEnabled: true});
    const largeMade = await new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => largeInput}).materialize('host-large-placement');
    await db.collection('workspaceProfiles').doc(profile.caseId).update({shopEnabled: false});
    const largeOriginal = (await service().readBuyer(actor, {purchaseId: largeMade.purchaseId, buyingStoreId: profile.workspaceId}))
      .orders.find((order: any) => order.storeId === largeStore.storeId);
    const largeOrderedLine = largeOriginal.original.lines.find((line: any) => line.skuId === largeLine.skuId &&
      line.verifiedPackId === largeLine.verifiedPackId);
    assert.equal(largeOrderedLine.quantityMilli, 3000000);
    const large = command('host-large-arrival-one', 1500000);
    large.receipt.restockOriginal.reference = {purchaseId: largeMade.purchaseId, storeId: largeOriginal.storeId,
      orderId: largeOriginal.orderId, originalFingerprint: largeOriginal.originalFingerprint, sourceRevision: largeInput.revision};
    large.receipt.restockOriginal.lines = largeOriginal.original.lines.map((line: any) => ({lineId: line.lineId,
      quantityMilli: line.quantityMilli, quantityUnit: line.quantityUnit}));
    large.receipt.expectedDeliveryId = `restock-${createHash('sha256').update(JSON.stringify(['evaluation', profile.workspaceId,
      largeMade.purchaseId, largeOriginal.storeId, largeOriginal.orderId])).digest('hex')}`;
    large.receipt.lines[0]!.sourceLineId = largeOrderedLine.lineId;
    large.receipt.lines[0]!.purchaseUnit = largeOrderedLine.quantityUnit;
    large.receipt.lines[0]!.expectedMilli = 3000000; large.receipt.lines[0]!.unitsPerPack = 1000000;
    // Public buying is enabled only for placement; historical arrival stays available afterwards.
    await service().recordBuyerGoodsArrival(actor, large);
    const largeSecond = structuredClone(large); largeSecond.receipt.id = 'host-large-arrival-two';
    const largeResult = await service().recordBuyerGoodsArrival(actor, largeSecond);
    assert.equal(largeResult.group.lines.length, 1);
    assert.equal(largeResult.group.lines[0].acceptedMilli * largeResult.group.lines[0].mapping.unitsPerPack / 1000, 3000000000);
    const alternate = original.original.lines.find((line: any) => line.lineId !== orderedLine.lineId);
    assert.ok(alternate, 'The race uses a different actual ordered SKU within the full original.');
    let recordedRaces = 0;
    for (let race = 0; race < 5; race++) {
      const raced = command(`host-close-record-race-${race}`, 100), line = raced.receipt.lines[0]!;
      line.sourceLineId = alternate.lineId; line.expectedMilli = alternate.quantityMilli;
      line.purchaseUnit = alternate.quantityUnit; line.productId = 'host-stock-other-original-line';
      const pair = await Promise.all([service().recordBuyerGoodsArrival(actor, raced), service().closeBuyerGoodsArrival(actor, raced)]);
      assert.equal(pair[0].state, pair[1].state); assert.deepEqual(pair[0].proof, pair[1].proof);
      if (pair[0].state === 'recorded') recordedRaces++;
      else assert.equal(pair[0].state, 'closed');
      assert.deepEqual((await service().reconcileBuyerGoodsArrival(actor, raced)).proof, pair[0].proof);
    }
    const racedGroup = (await service().readBuyerGoodsReceiving(actor, read)).group;
    assert.equal(racedGroup.revision, 2 + recordedRaces);
    assert.equal(racedGroup.lines.find((line: any) => line.lineId === orderedLine.lineId).deliveredMilli, 1000);
    assert.equal(racedGroup.lines.find((line: any) => line.lineId === alternate.lineId)?.deliveredMilli ?? 0, recordedRaces * 100);
    if (process.env.LF_RESTOCK_ARRIVAL_EXPORT) {
      writeFileSync(process.env.LF_RESTOCK_ARRIVAL_EXPORT, JSON.stringify({schemaVersion: 1,
        evidence: 'isolated_firestore_emulator_owner_report', command: remaining,
        response: await service().reconcileBuyerGoodsArrival(actor, remaining),
        cumulative: {command: largeSecond, response: largeResult},
        closure: {command: unrecorded, response: await service().reconcileBuyerGoodsArrival(actor, unrecorded)}}), 'utf8');
    }
    for (const body of [{...read, buyingStoreId: 'other-store'}, {...read, reference: {...reference, originalFingerprint: 'b'.repeat(64)}}]) {
      await assert.rejects(service().readBuyerGoodsReceiving(actor, body));
    }
    await assert.rejects(service().readBuyerGoodsReceiving('other-buyer', read), rejectsCode('not_found'));
    const supplierView = await service().readStore(input.stores[0].ownerUserId, {purchaseId: made.purchaseId,
      storeId: original.storeId, orderId: original.orderId});
    assert.equal(JSON.stringify(supplierView).includes('host-stock-product'), false);
    assert.equal(JSON.stringify(supplierView).includes('host-local-supplier'), false);
    await db.collection('workspaceProfiles').doc(profile.caseId).update({status: 'suspended'});
    for (const action of [() => service().recordBuyerGoodsArrival(actor, winner),
      () => service().closeBuyerGoodsArrival(actor, winner), () => service().closeBuyerGoodsArrival(actor, unrecorded),
      () => service().reconcileBuyerGoodsArrival(actor, winner), () => service().readBuyerGoodsReceiving(actor, read)]) {
      await assert.rejects(action(), rejectsCode('not_found'));
    }
  } finally { await db.terminate(); await deleteApp(app); }
});

test('LF-PURCHASER trusted receipt freezes one explicit purchaser without changing legacy facts', () => {
  for (const kind of ['personal', 'store'] as const) {
    const input = purchaserReceipt(kind);
    assert.deepEqual(normalizePlacement(input, 'evaluation'), input);
  }
  for (const legacy of [receipt(), commodityOriginalReceipt()]) {
    assert.deepEqual(normalizePlacement(legacy, 'evaluation'), legacy);
  }
});
for (const [name, change] of Object.entries({
  'missing purchaser': (v: any) => {delete v.purchaser;},
  'unsupported purpose': (v: any) => {v.purchaser.purpose = 'any-store';},
  'private account in snapshot': (v: any) => {v.purchaser.accountId = v.buyerUserId;},
  'missing case': (v: any) => {v.purchasingStoreCaseId = null;},
  'self supplier': (v: any) => {v.purchaser.storeId = v.stores[0].storeId;},
  'blank name': (v: any) => {v.purchaser.name = '';},
  'personal with Store case': (v: any) => {v.purchaser = {schemaVersion: 1, kind: 'personal'};},
  'legacy with new purchaser': (v: any) => {v.schemaVersion = 9;},
})) test(`LF-PURCHASER rejects ${name}`, () => {
  const input = purchaserReceipt(); change(input);
  assert.throws(() => normalizePlacement(input, 'evaluation'), rejectsCode('invalid_input'));
});

test('LF-PURCHASER persisted Store originals separate history and enforce current original-owner access', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  const app = initializeApp({projectId: `demo-lf-purchaser-${randomUUID().slice(0,8)}`}, `purchaser-${randomUUID()}`),
    db = purchaseTestFirestore(app), input = purchaserReceipt();
  const profile = {schemaVersion: 1, caseId: 'buying-case', workspaceId: 'buying-store', ownerUserId: input.buyerUserId,
    familyId: 'products-trade', profileId: 'retailer-grocery', status: 'live', shopEnabled: true};
  try {
    for (const store of input.stores) await db.collection('workspaceProfiles').doc(store.caseId).set({schemaVersion: 1,
      caseId: store.caseId, workspaceId: store.storeId, ownerUserId: store.ownerUserId, familyId: 'products-trade',
      profileId: 'wholesaler', status: 'live', shopEnabled: true});
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    const writer = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => input});
    const made = await writer.materialize('purchaser-source');
    assert.deepEqual(await writer.materialize('purchaser-source'), made);
    const reader = new WorkspacePurchaseProjectionService(db, 'evaluation');
    const selector = {purchaseId: made.purchaseId, buyingStoreId: profile.workspaceId};
    const buyer = await reader.readBuyer(input.buyerUserId, selector);
    assert.equal(buyer.schemaVersion, 11);
    assert.ok(buyer.orders.every(o => JSON.stringify(Reflect.get(o.original, 'purchaser')) === JSON.stringify(input.purchaser)));
    assert.equal(JSON.stringify(buyer).includes('buying-case'), false);
    assert.equal(JSON.stringify(buyer).includes('buyerUserId'), false);
    await assert.rejects(reader.readBuyer(input.buyerUserId, {purchaseId: made.purchaseId}), rejectsCode('not_found'));
    await assert.rejects(reader.readBuyer(input.buyerUserId, {...selector, buyingStoreId: 'other-store'}), rejectsCode('not_found'));
    const personalInput = purchaserReceipt('personal'); personalInput.receiptId = 'personal-purchaser-receipt';
    const personal = await new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => personalInput}).materialize('personal-source');
    const otherInput = purchaserReceipt(); otherInput.receiptId = 'other-store-receipt';
    otherInput.purchaser.storeId = 'other-buying-store'; otherInput.purchaser.purpose = 'buyDirect'; otherInput.purchasingStoreCaseId = 'other-buying-case';
    await db.collection('workspaceProfiles').doc(otherInput.purchasingStoreCaseId).set({...profile,
      caseId: otherInput.purchasingStoreCaseId, workspaceId: otherInput.purchaser.storeId, shopEnabled: false});
    const other = await new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => otherInput}).materialize('other-store-source');
    assert.equal(other.buyerId, made.buyerId, 'Existing buyerId remains account-scoped.');
    assert.equal(personal.buyerId, made.buyerId);
    const legacyInput = receipt('legacy-purchaser');
    const legacy = await new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => legacyInput}).materialize('legacy-source');
    const personalRefs = await reader.listBuyer(input.buyerUserId, {limit: 5, cursor: null});
    assert.deepEqual(new Set(personalRefs.references.map(r => r.purchaseId)), new Set([personal.purchaseId, legacy.purchaseId]));
    const storeRefs = await reader.listBuyer(input.buyerUserId, {limit: 5, cursor: null, buyingStoreId: profile.workspaceId});
    assert.deepEqual(new Set(storeRefs.references.map(r => r.purchaseId)), new Set([made.purchaseId]));
    assert.equal(storeRefs.schemaVersion, 3);
    let cursor: string | null = null; const seen: string[] = [];
    do {
      const page = await reader.listBuyer(input.buyerUserId, {limit: 1, cursor, buyingStoreId: profile.workspaceId});
      seen.push(...page.references.map(r => r.purchaseId)); cursor = page.nextCursor;
      if (cursor) await assert.rejects(reader.listBuyer(input.buyerUserId, {limit: 1, cursor}), rejectsCode('invalid_input'));
    } while (cursor);
    assert.deepEqual(new Set(seen), new Set([made.purchaseId]));
    const order = buyer.orders[0]!, tuple = {purchaseId: made.purchaseId, storeId: order.storeId, orderId: order.orderId};
    const seller = await reader.readStore(input.stores[0].ownerUserId, tuple);
    assert.deepEqual(seller.orders, [order]);
    const proof = {...operationalEvidence(), ...tuple, originalFingerprint: order.originalFingerprint,
      sourceRevision: buyer.sourceRevision, initialStage: 'Ready' as const};
    const ops = new WorkspaceOrderOperationsService(db, 'evaluation', {readOperationalOrder: async () => proof}, () => new Date('2026-10-16T12:00:00.000Z'),
      {issuer: 'trusted-fulfilment', readCompletion: async () => ({...completionEvidence(), ...tuple,
        originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision, operationalRevision: 1})});
    await ops.initialize('purchaser-operations');
    const operational = await ops.read(input.buyerUserId, 'buyer', tuple);
    assert.deepEqual(operational.original, order.original);
    await ops.recordCompletion('purchaser-completion');
    const targetScope = {...tuple, originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision,
      orderLineId: order.original.lines[0]!.lineId};
    const targetRead = await ops.readBuyerProductFeedbackTarget(input.buyerUserId, targetScope), target = targetRead.target;
    assert.deepEqual((await ops.listBuyerProductFeedbackTargets(input.buyerUserId, {limit: 5, cursor: null})).targets, [],
      'Store purchase targets do not appear in personal discovery.');
    const emptyPersonalPage = await ops.listBuyerProductFeedbackTargets(input.buyerUserId, {limit: 1, cursor: null});
    assert.deepEqual(emptyPersonalPage.targets, []); assert.equal(typeof emptyPersonalPage.nextCursor, 'string');
    const starsRead = async () => ({schemaVersion: 1, realm: 'evaluation', authNamespace: 'firebase-default',
      viewerRole: 'buyer', viewerUserId: input.buyerUserId, targetId: target.id,
      rating: await ops.readBuyerProductStars(input.buyerUserId, {targetId: target.id})});
    const beforeStars = await starsRead(); assert.equal(beforeStars.rating, null);
    const stars = {targetId: target.id, expectedRevision: 0, operationId: 'purchaser-stars', stars: 4};
    const savedStars = await ops.submitProductStars(input.buyerUserId, stars);
    const recoveredStars = await ops.submitProductStars(input.buyerUserId, stars, true);
    assert.deepEqual(recoveredStars, savedStars);
    assert.equal((await ops.readBuyerProductStars(input.buyerUserId, {targetId: target.id}))!.stars, 4);
    await db.collection('workspaceProfiles').doc(profile.caseId).update({shopEnabled: false, name: 'Current renamed Store'});
    assert.deepEqual(await reader.readBuyer(input.buyerUserId, selector), buyer, 'Historical facts survive paused sales and renaming.');
    assert.deepEqual(await ops.readBuyerProductFeedbackTarget(input.buyerUserId, targetScope), targetRead);
    if (process.env.LF_STORE_FEEDBACK_CAPTURE === 'true') console.log('LF_STORE_PURCHASE_FEEDBACK_CAPTURE=' + JSON.stringify({
      buyer, storeRefs, completion: await ops.readCompletion(input.buyerUserId, 'buyer', tuple),
      targetRead, beforeStars, afterStars: await starsRead(), savedStars, recoveredStars, command: stars, emptyPersonalPage}));
    input.purchaser.purpose = 'buyDirect';
    await assert.rejects(writer.materialize('purchaser-source'), rejectsCode('conflict'));
    input.purchaser.purpose = 'restock';
    input.purchaser.storeId = otherInput.purchaser.storeId; input.purchasingStoreCaseId = otherInput.purchasingStoreCaseId;
    await assert.rejects(writer.materialize('purchaser-source'), rejectsCode('conflict'));
    input.purchaser.storeId = profile.workspaceId; input.purchasingStoreCaseId = profile.caseId;
    await db.collection('workspaceProfiles').doc(profile.caseId).update({ownerUserId: 'new-owner'});
    for (const actor of [input.buyerUserId, 'new-owner']) {
      await assert.rejects(reader.readBuyer(actor, selector), rejectsCode('not_found'));
      await assert.rejects(ops.read(actor, 'buyer', tuple), rejectsCode('not_found'));
      await assert.rejects(ops.readCompletion(actor, 'buyer', tuple), rejectsCode('not_found'));
      await assert.rejects(ops.readBuyerProductFeedbackTarget(actor, targetScope), rejectsCode('not_found'));
      await assert.rejects(ops.readBuyerProductStars(actor, {targetId: target.id}), rejectsCode('not_found'));
      await assert.rejects(ops.submitProductStars(actor, stars, true), rejectsCode('not_found'));
    }
    assert.deepEqual(await reader.readStore(input.stores[0].ownerUserId, tuple), seller, 'Supplier history is independently authorised.');
    if (process.env.LF_PURCHASER_CAPTURE === 'true') console.log('LF_PURCHASER_PROJECTION=' + JSON.stringify({buyer, seller, operational, storeRefs}));
  } finally {await db.terminate(); await deleteApp(app);}
});

test('LF-COMMODITY-ORIGINAL materializer restart preserves buyer Store and operational originals', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  const app = initializeApp({projectId: `demo-lf-commodity-original-${randomUUID().slice(0,8)}`}, `commodity-original-${randomUUID()}`),
    db = purchaseTestFirestore(app), input = commodityOriginalReceipt();
  try {
    for (const store of input.stores) await db.collection('workspaceProfiles').doc(store.caseId).set({schemaVersion: 1,
      caseId: store.caseId, workspaceId: store.storeId, ownerUserId: store.ownerUserId, familyId: 'products-trade',
      profileId: 'retailer-grocery', status: 'live', shopEnabled: true});
    const writer = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => input});
    const created = await writer.materialize('commodity-original-source');
    assert.deepEqual(await writer.materialize('commodity-original-source'), created);
    const reader = new WorkspacePurchaseProjectionService(db, 'evaluation');
    const buyer = await reader.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId});
    assert.equal(buyer.schemaVersion, 10);
    const sellers = [], operational = [];
    for (const order of buyer.orders) {
      const source = input.stores.find((s: any) => s.storeId === order.storeId)!;
      const tuple = {purchaseId: created.purchaseId, storeId: order.storeId, orderId: order.orderId};
      for (const saved of order.original.lines) {
        const supplied = source.lines.find((l: any) => l.skuId === saved.skuId)!;
        assert.deepEqual(saved.commodityPriceSnapshot, supplied.commodityPriceSnapshot);
        assert.equal(saved.unitPriceMinor, supplied.unitPriceMinor);
      }
      assert.deepEqual(order.original.totals, source.totals);
      sellers.push(await reader.readStore(source.ownerUserId, tuple));
      assert.deepEqual(sellers.at(-1)!.orders, [order]);
      await assert.rejects(reader.readStore('foreign-owner', tuple), rejectsCode('not_found'));
      const proof = {...operationalEvidence(), ...tuple, originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision,
        fulfilment: source.fulfilmentContext.method,
        allowedActions: source.fulfilmentContext.method === 'collection' ? [] : operationalEvidence().allowedActions};
      const ops = new WorkspaceOrderOperationsService(db, 'evaluation', {readOperationalOrder: async () => proof},
        () => new Date('2026-10-16T12:00:00.000Z'));
      await ops.initialize('commodity-operation-source');
      const sellerOperation = await ops.read(source.ownerUserId, 'seller', tuple), buyerOperation = await ops.read(input.buyerUserId, 'buyer', tuple);
      assert.equal(sellerOperation.originalFactsVersion, 10); assert.deepEqual(sellerOperation.original, order.original);
      operational.push(sellerOperation, buyerOperation);
    }
    const changed = input.stores[0].lines[0];
    changed.commodityPriceSnapshot.confirmationRevision = 3;
    changed.offerRevision = changed.commodityPriceSnapshot.termsRevision = 'commodity-3-BBBBBBBBBBBBBBBB';
    await assert.rejects(writer.materialize('commodity-original-source'), rejectsCode('conflict'));
    assert.deepEqual(await reader.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId}), buyer);
    if (process.env.LF_COMMODITY_ORIGINAL_CAPTURE === 'true') console.log('LF_COMMODITY_ORIGINAL_PROJECTION=' + JSON.stringify({buyer, sellers, operational}));
  } finally {await db.terminate(); await deleteApp(app);}
});

test('LF-GST-ORIGINAL trusted receipt retains the historical supplier declaration without changing money', () => {
  for (const declaration of [null, {version: 2, rateBasisPoints: 0, basis: 'additional'},
    {version: 2, rateBasisPoints: 500, basis: 'included'}, {version: 1, amountMinor: 7, basis: 'additional'}]) {
    const input = supplierTaxReceipt();
    input.stores[0].lines[0].supplierTaxSnapshot = declaration === null ? null : {
      ...input.stores[0].lines[0].supplierTaxSnapshot, declaration};
    assert.deepEqual(normalizePlacement(input, 'evaluation'), input);
    assert.deepEqual(input.stores.map((s: any) => s.totals), fulfilmentContextReceipt().stores.map((s: any) => s.totals));
  }
  for (const legacy of [receipt(), attributedReceipt(), variantReceipt(), scheduledReceipt(), publicListingReceipt(), fulfilmentContextReceipt()]) {
    assert.deepEqual(normalizePlacement(legacy, 'evaluation'), legacy);
    assert.equal(Object.hasOwn(legacy.stores[0].lines[0], 'supplierTaxSnapshot'), false);
  }
});

test('LF-GST-ORIGINAL legacy amounts require a bound pack while rates retain supported units', () => {
  for (const unit of ['kg', 'L', 'count']) {
    const input = supplierTaxReceipt(), line = input.stores[0].lines[0]; line.quantityUnit = unit;
    assert.deepEqual(normalizePlacement(input, 'evaluation'), input);
    line.supplierTaxSnapshot.declaration = {version: 1, amountMinor: 7, basis: 'additional'};
    assert.throws(() => normalizePlacement(input, 'evaluation'), rejectsCode('invalid_input'));
  }
});

test('LF-GST-ORIGINAL persisted historical declarations survive restart and both role readbacks', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: 'demo-lf-gst-original'}, `gst-original-${randomUUID()}`), db = purchaseTestFirestore(app);
  const input = supplierTaxReceipt(), suffix = randomUUID();
  input.receiptId = `gst-${suffix}`; input.buyerUserId = `buyer-${suffix}`;
  for (const [index, store] of input.stores.entries()) {
    const previous = store.storeId;
    store.storeId = `store-${suffix}-${index}`; store.caseId = `case-${suffix}-${index}`; store.ownerUserId = `owner-${suffix}-${index}`;
    for (const l of store.lines) {
      for (const listing of [l.publicListing, l.scheduledFulfilment?.listing]) if (listing) {
        listing.storeId = store.storeId;
        listing.listingId = `listing-${createHash('sha256').update(JSON.stringify([1, 'evaluation', store.storeId, l.skuId, listing.channel])).digest('hex')}`;
      }
    }
    assert.notEqual(previous, store.storeId);
    await db.collection('workspaceProfiles').doc(store.caseId).set({schemaVersion: 1, caseId: store.caseId,
      workspaceId: store.storeId, ownerUserId: store.ownerUserId, familyId: 'products-trade', profileId: 'retailer-grocery', status: 'live', shopEnabled: true});
  }
  const first = input.stores[0], originalLine = first.lines[0];
  first.lines.push({...structuredClone(originalLine), sourceLineId: 'source-zero', supplierTaxSnapshot: {
    ...originalLine.supplierTaxSnapshot, declaration: {version: 2, rateBasisPoints: 0, basis: 'additional'}}},
  {...structuredClone(originalLine), sourceLineId: 'source-unknown', supplierTaxSnapshot: null});
  first.totals.itemsMinor += 20102; first.totals.totalMinor += 20102;
  input.stores[1].lines[0].supplierTaxSnapshot = {...originalLine.supplierTaxSnapshot,
    declaration: {version: 1, amountMinor: 7, basis: 'additional'}};
  try {
    const writer = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => input});
    const created = await writer.materialize('gst-original-source');
    assert.deepEqual(await writer.materialize('gst-original-source'), created);
    const reader = new WorkspacePurchaseProjectionService(db, 'evaluation');
    const buyer = await reader.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId});
    assert.equal(buyer.schemaVersion, 9);
    const sellers = [];
    for (const order of buyer.orders) {
      const source = input.stores.find((s: any) => s.storeId === order.storeId)!;
      assert.deepEqual(order.original.totals, source.totals);
      assert.deepEqual(order.original.lines.map(l => l.supplierTaxSnapshot).sort((a,b) => JSON.stringify(a).localeCompare(JSON.stringify(b))),
        source.lines.map((l: any) => l.supplierTaxSnapshot).sort((a: any,b: any) => JSON.stringify(a).localeCompare(JSON.stringify(b))));
      const seller = await reader.readStore(source.ownerUserId, {purchaseId: created.purchaseId, storeId: order.storeId, orderId: order.orderId});
      assert.deepEqual(seller.orders[0], order); sellers.push(seller);
      await assert.rejects(reader.readStore('foreign-owner', {purchaseId: created.purchaseId, storeId: order.storeId, orderId: order.orderId}), rejectsCode('not_found'));
    }
    originalLine.supplierTaxSnapshot.declaration.rateBasisPoints = 1800;
    await assert.rejects(writer.materialize('gst-original-source'), rejectsCode('conflict'));
    assert.deepEqual(await reader.readBuyer(input.buyerUserId, {purchaseId: created.purchaseId}), buyer);
    if (process.env.LF_GST_ORIGINAL_CAPTURE === 'true') console.log(`LF_GST_ORIGINAL_PROJECTION=${JSON.stringify({buyer, sellers})}`);
  } finally {await db.terminate(); await deleteApp(app);}
});

for (const [name, mutate] of Object.entries({
  missing: (s: any) => {delete s.supplierTaxSnapshot;},
  boolean: (s: any) => {s.supplierTaxSnapshot = false;},
  version: (s: any) => {s.supplierTaxSnapshot.schemaVersion = 2;},
  revision: (s: any) => {s.supplierTaxSnapshot.termsRevision = '';},
  observed: (s: any) => {s.supplierTaxSnapshot.observedAt = 'not-a-date';},
  expiry: (s: any) => {s.supplierTaxSnapshot.expiresAt = '2026-10-01T11:59:59.000Z';},
  absentDeclaration: (s: any) => {delete s.supplierTaxSnapshot.declaration;},
  nullDeclaration: (s: any) => {s.supplierTaxSnapshot.declaration = null;},
  fractional: (s: any) => {s.supplierTaxSnapshot.declaration.rateBasisPoints = 5.5;},
  overflow: (s: any) => {s.supplierTaxSnapshot.declaration.rateBasisPoints = 10001;},
  amountOverflow: (s: any) => {s.supplierTaxSnapshot.declaration = {version: 1, amountMinor: 1000000000001, basis: 'additional'};},
  contradictory: (s: any) => {s.supplierTaxSnapshot.declaration.amountMinor = 7;},
  authorityClaim: (s: any) => {s.supplierTaxSnapshot.verifiedRegistration = true;},
})) test(`LF-GST-ORIGINAL rejects malformed frozen declaration ${name}`, () => {
  const input = supplierTaxReceipt(); mutate(input.stores[0].lines[0]);
  assert.throws(() => normalizePlacement(input, 'evaluation'), rejectsCode('invalid_input'));
});

test('LF-CONTEXT trusted placement preserves per-Store recipient and line instructions without current-profile inference', () => {
  const value = fulfilmentContextReceipt();
  assert.deepEqual(normalizePlacement(value, 'evaluation'), value);
  const unknown = fulfilmentContextReceipt(); unknown.stores.forEach((store: Record<string, unknown>) => {store.fulfilmentContext = null;});
  assert.deepEqual(normalizePlacement(unknown, 'evaluation'), unknown);
  for (const legacy of [receipt(), attributedReceipt(), scheduledReceipt(), publicListingReceipt()]) {
    assert.deepEqual(normalizePlacement(legacy, 'evaluation'), legacy);
    assert.equal(Object.hasOwn(legacy.stores[0]!, 'fulfilmentContext'), false);
  }
});
for (const [name, mutate] of Object.entries({
  'missing context': (v: any) => {delete v.stores[0].fulfilmentContext;},
  'old version enrichment': (v: any) => {v.schemaVersion = 5;},
  'address book identity': (v: any) => {v.stores[0].fulfilmentContext.address.id = 'private-address-id';},
  'recipient account identity': (v: any) => {v.stores[0].fulfilmentContext.recipient.accountId = 'private-account';},
  'cross Store instruction': (v: any) => {v.stores[0].fulfilmentContext.instructions[0].lineId = v.stores[1].lines[0].sourceLineId;},
  'duplicate instruction': (v: any) => {v.stores[0].fulfilmentContext.instructions.push(v.stores[0].fulfilmentContext.instructions[0]);},
  'blank note': (v: any) => {v.stores[0].fulfilmentContext.instructions[0].text = '';},
  'oversized note': (v: any) => {v.stores[0].fulfilmentContext.instructions[0].text = 'द'.repeat(1001);},
  'control character': (v: any) => {v.stores[0].fulfilmentContext.instructions[0].text = 'note\u0000';},
  'collection residence': (v: any) => {v.stores[1].fulfilmentContext.address = v.stores[0].fulfilmentContext.address;},
  'invalid phone': (v: any) => {v.stores[0].fulfilmentContext.recipient.phone = 'not-a-phone';},
})) test(`LF-CONTEXT rejects ${name}`, () => {
  const value = fulfilmentContextReceipt(); mutate(value);
  assert.throws(() => normalizePlacement(value, 'evaluation'), rejectsCode('invalid_input'));
});

test('LF-CONTEXT emulator freezes two Store contexts, remaps notes, preserves feedback and rejects contradictory operations', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-context-${randomUUID().slice(0,8)}`}, `context-${randomUUID()}`), db = purchaseTestFirestore(app);
  const value = fulfilmentContextReceipt(), originalSource = structuredClone(value), now = new Date('2026-10-16T12:00:00.000Z');
  const service = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => value});
  const reader = new WorkspacePurchaseProjectionService(db, 'evaluation');
  try {
    for (const store of value.stores) await db.collection('workspaceProfiles').doc(store.caseId).set({schemaVersion: 1,
      caseId: store.caseId, workspaceId: store.storeId, ownerUserId: store.ownerUserId, familyId: 'products-trade',
      profileId: 'retailer-grocery', status: 'live', shopEnabled: true});
    const made = await service.materialize('original-context-source'), buyer = await reader.readBuyer(value.buyerUserId, {purchaseId: made.purchaseId});
    assert.equal(buyer.schemaVersion, 7);
    assert.deepEqual(await service.materialize('original-context-source'), made);
    const seller: unknown[] = [], operations: unknown[] = [];
    for (const [index, order] of buyer.orders.entries()) {
      const supplied = value.stores[index], context = order.original.fulfilmentContext!;
      assert.equal(order.factsVersion, 7); assert.equal(context.recipient!.name, supplied.fulfilmentContext.recipient.name);
      const sourceLine = supplied.lines[0], purchasedLine = order.original.lines.find(line => line.skuId === sourceLine.skuId &&
        line.verifiedPackId === sourceLine.verifiedPackId && line.offerId === sourceLine.offerId && line.variant === sourceLine.variant)!;
      assert.ok(purchasedLine);
      assert.equal(context.instructions[0]!.lineId, purchasedLine.lineId);
      assert.notEqual(context.instructions[0]!.lineId, supplied.lines[0].sourceLineId);
      assert.equal(context.instructions[0]!.text, supplied.fulfilmentContext.instructions[0].text);
      const scope = {purchaseId: made.purchaseId, storeId: order.storeId, orderId: order.orderId};
      const view = await reader.readStore(supplied.ownerUserId, scope); seller.push(view);
      assert.equal(view.orders.length, 1); assert.deepEqual(view.orders[0], order);
      assert.doesNotMatch(JSON.stringify(view), new RegExp(value.stores[1-index].fulfilmentContext.recipient.name));
      await assert.rejects(reader.readStore(value.stores[1-index].ownerUserId, scope), rejectsCode('not_found'));
      const proof: TrustedOperationalOrderEvidence = {...operationalEvidence(), ...scope,
        originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision, fulfilment: context.method,
        initialStage: context.method === 'collection' ? 'Ready' : 'Confirmed', allowedActions: context.method === 'collection' ? [] : ['accept', 'ready', 'reject']};
      if (index === 0) {
        const contradiction = new WorkspaceOrderOperationsService(db, 'evaluation', {readOperationalOrder: async () => ({...proof,
          fulfilment: 'collection', initialStage: 'Ready', allowedActions: []})}, () => now);
        await assert.rejects(contradiction.initialize('contradictory-original-mode'), rejectsCode('conflict'));
      }
      const operational = new WorkspaceOrderOperationsService(db, 'evaluation', {readOperationalOrder: async () => proof}, () => now,
        {issuer: 'trusted-fulfilment', readCompletion: async () => ({...completionEvidence(), ...scope,
          originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision, operationalRevision: 1, outcome: 'collected'})});
      await operational.initialize(`context-operations-${index}`);
      const snapshot = await operational.read(supplied.ownerUserId, 'seller', scope); operations.push(snapshot);
      assert.equal(snapshot.originalFactsVersion, 7); assert.deepEqual(snapshot.original, order.original);
      if (context.method === 'collection') {
        await operational.recordCompletion('context-collection-complete');
        const targets = await operational.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 5, cursor: null});
        assert.equal(targets.targets.length, 1);
        assert.doesNotMatch(JSON.stringify(targets), /Evaluation recipient|9876501234|Evaluation house|Keep the exact ordered pack/);
      }
    }
    value.stores[0].fulfilmentContext.instructions[0].text = 'Changed after the original placement';
    await assert.rejects(service.materialize('original-context-source'), rejectsCode('conflict'));
    value.stores = originalSource.stores;
    assert.deepEqual(await reader.readBuyer(value.buyerUserId, {purchaseId: made.purchaseId}), buyer);
    console.log(`LF10_CONTEXT_PROJECTION=${JSON.stringify({buyer, seller, operations})}`); // Isolated emulator fixtures only.
  } finally {await db.terminate(); await deleteApp(app);}
});

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
  const app = initializeApp({projectId: `demo-lf-listing-${randomUUID().slice(0, 8)}`}, `listing-${randomUUID()}`), db = purchaseTestFirestore(app);
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
    const exactTargetScope = {...scope, originalFingerprint: first.originalFingerprint, sourceRevision: buyer.sourceRevision,
      orderLineId: first.original.lines[0]!.lineId};
    await assert.rejects(operations.readBuyerProductFeedbackTarget(value.buyerUserId, exactTargetScope), rejectsCode("not_found"));
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
      const exactScope = {...exactTargetScope, orderLineId: target.orderLineId};
      assert.deepEqual((await operations.readBuyerProductFeedbackTarget(value.buyerUserId, exactScope)).target, target);
      await assert.rejects(operations.readBuyerProductFeedbackTarget("unrelated-buyer", exactScope), rejectsCode("not_found"));
      for (const changed of [{orderLineId: "missing-line"}, {sourceRevision: "other-revision"}, {originalFingerprint: "b".repeat(64)}]) {
        await assert.rejects(operations.readBuyerProductFeedbackTarget(value.buyerUserId, {...exactScope, ...changed}), rejectsCode("not_found"));
      }
      await assert.rejects(operations.readBuyerProductFeedbackTarget(value.buyerUserId, {...exactScope, buyerUserId: value.buyerUserId}), rejectsCode("invalid_input"));
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
      const outcomes = await Promise.allSettled([operations.submitProductStars(value.buyerUserId, starCommand),
        operations.submitProductStars(value.buyerUserId, starCommand)]);
      t.diagnostic(`private stars concurrent outcomes: ${outcomes.map(r => r.status === "fulfilled" ? "saved" : String(r.reason)).join(" | ")}`);
      // Await both before any fixture teardown; neither failure is hidden by
      // cancellation/termination of its still-running sibling transaction.
      for (const outcome of outcomes) if (outcome.status === "rejected") throw outcome.reason;
      const [starOne, replayOne] = outcomes.map(outcome => {
        assert.equal(outcome.status, "fulfilled");
        return outcome.value;
      });
      assert.ok(starOne); assert.ok(replayOne);
      t.diagnostic("private stars: concurrent original attempt accepted");
      assert.deepEqual(starOne, replayOne); assert.equal(starOne.rating!.stars, 1);
      const [savedRatings, savedReceipts] = await Promise.all([
        root.collection('productStarRatings').get(), root.collection('productStarReceipts').get()]);
      assert.equal(savedRatings.size, 1);
      assert.equal(savedRatings.docs[0]!.id, target.id);
      assert.equal(savedReceipts.size, receiptCount + 1, 'concurrent original creates exactly one immutable operation receipt');
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
      const stale = await restart.submitProductStars(value.buyerUserId, {...starCommand, operationId: "stale-edit"}, true);
      assert.deepEqual(stale, {...starOne, operationId: "stale-edit", state: "superseded", rating: null,
        targetId: target.id, observedRevision: 5});
      assert.deepEqual(await restart.submitProductStars(value.buyerUserId, starCommand, true), starOne);
      assert.equal((await restart.submitProductStars(value.buyerUserId,
        {...starCommand, operationId: "not-sent-next", expectedRevision: 5}, true)).state, "not_recorded");
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
      await assert.rejects(restart.submitProductStars(value.buyerUserId,
        {...starCommand, operationId: "stale-edit"}, true), rejectsCode("invalid_state"));
      await assert.rejects(restart.readBuyerProductStars(value.buyerUserId, {targetId: target.id}), rejectsCode("invalid_state"));
      await assert.rejects(restart.listStoreProductStars(value.stores[0].ownerUserId,
        {storeId: first.storeId, limit: 5, cursor: null}), rejectsCode("invalid_state"));
      await ratingPath.set(frozenStars);
      console.log(`LF_PRIVATE_PRODUCT_STARS=${JSON.stringify({target, buyer: downgraded, seller: sellerStars})}`);
      await assert.rejects(operations.listBuyerProductFeedbackTargets("unrelated-buyer", {limit: 1, cursor: targets.nextCursor}), rejectsCode("invalid_input"));
      const path = db.collection("workspacePurchaseProjections").doc("evaluation").collection("productFeedbackTargets").doc(target.id);
      const frozen = (await path.get()).data()!;
      await path.update({"target.productLabel": "tampered"});
      await assert.rejects(operations.readBuyerProductFeedbackTarget(value.buyerUserId, exactScope), rejectsCode("invalid_state"));
      await assert.rejects(operations.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 1, cursor: null}), rejectsCode("invalid_state"));
      await assert.rejects(operations.recordCompletion(completionReference), rejectsCode("invalid_state"));
      await path.set(frozen);
      await path.delete();
      await assert.rejects(operations.readBuyerProductFeedbackTarget(value.buyerUserId, exactScope), rejectsCode("service_unavailable"));
      assert.equal((await path.get()).exists, false);
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

test('LF13-RECOVERY real original stars survive unknown acknowledgements without automatic retries',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async (t) => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-stars-recovery-${randomUUID().slice(0, 8)}`}, `recovery-${randomUUID()}`);
  const db = purchaseTestFirestore(app), root = db.collection('workspacePurchaseProjections').doc('evaluation');
  try {
    const value = publicListingReceipt(); value.receiptId = `receipt-${randomUUID()}`; value.buyerUserId = `buyer-${randomUUID()}`;
    for (const store of value.stores) await db.collection('workspaceProfiles').doc(store.caseId).set({
      schemaVersion: 1, caseId: store.caseId, workspaceId: store.storeId, ownerUserId: store.ownerUserId,
      familyId: 'products-trade', profileId: 'retailer-grocery', status: 'live', shopEnabled: true,
    });
    const producer = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => value});
    const created = await producer.materialize('stars-recovery-original');
    const buyer = await producer.readBuyer(value.buyerUserId, {purchaseId: created.purchaseId}), order = buyer.orders[0]!;
    const scope = {purchaseId: buyer.purchaseId, storeId: order.storeId, orderId: order.orderId};
    const restart = new WorkspaceOrderOperationsService(db, 'evaluation',
      {readOperationalOrder: async () => ({...operationalEvidence(), ...scope, originalFingerprint: order.originalFingerprint,
        sourceRevision: buyer.sourceRevision, initialStage: 'Ready'})}, () => new Date(),
      {issuer: 'trusted-fulfilment', readCompletion: async () => ({...completionEvidence(), ...scope,
        receiptId: `completion-${buyer.purchaseId}`, originalFingerprint: order.originalFingerprint,
        sourceRevision: buyer.sourceRevision, operationalRevision: 1})});
    await restart.initialize('stars-recovery-operations'); await restart.recordCompletion('stars-recovery-completion');
    const target = (await restart.listBuyerProductFeedbackTargets(value.buyerUserId, {limit: 5, cursor: null})).targets[0]!;
    assert.ok(target);
    const ratingPath = root.collection('productStarRatings').doc(target.id);
    await restart.submitProductStars(value.buyerUserId, {targetId: target.id, expectedRevision: 0,
      operationId: 'host-existing-rating', stars: 1});
      for (const phase of ['before-commit', 'after-commit'] as const) {
        await t.test(`LF13-RECOVERY explicit original reconciliation after ${phase} lost reply`, async () => {
          const previous = (await restart.readBuyerProductStars(value.buyerUserId, {targetId: target.id}))!;
          const command = {targetId: target.id, expectedRevision: previous.revision,
            operationId: `host-lost-${phase}`, stars: phase === 'before-commit' ? 2 : 3};
          const receipts = root.collection('productStarReceipts');
          const receiptCountBefore = (await receipts.get()).size;
          const originalTransaction = db.runTransaction;
          const lost = Object.assign(new Error('Isolated unknown transaction acknowledgement'),
            {code: 3, details: 'Transaction is invalid or closed.'});
          let calls = 0, committed: unknown;
          // Failure injection is confined to this isolated test DB instance.
          // Preserve the production method and strict concurrent-save assertion.
          db.runTransaction = (async (...args: unknown[]) => {
            calls++;
            if (phase === 'after-commit') committed = await Reflect.apply(originalTransaction, db, args);
            throw lost;
          }) as typeof originalTransaction;
          try {
            await assert.rejects(restart.submitProductStars(value.buyerUserId, command), error => error === lost);
          } finally {db.runTransaction = originalTransaction;}
          assert.equal(calls, 1, 'An uncertain acknowledgement must not trigger an automatic write retry.');
          const receiptCountAfterFailure = (await receipts.get()).size;
          assert.equal(receiptCountAfterFailure, receiptCountBefore + (phase === 'after-commit' ? 1 : 0));
          const frozenRating = (await ratingPath.get()).data();
          const resumed = new WorkspaceOrderOperationsService(db, 'evaluation');
          const recovered = await resumed.submitProductStars(value.buyerUserId, command, true);
          const receiptCountAfterRecovery = (await receipts.get()).size;
          assert.equal(receiptCountAfterRecovery, receiptCountAfterFailure, 'Reconciliation must not create a receipt.');
          assert.deepEqual((await ratingPath.get()).data(), frozenRating, 'Reconciliation must not modify the rating.');
          let retried: unknown = null;
          if (phase === 'after-commit') {
            assert.deepEqual(recovered, committed, 'Recover the original acknowledgement, not the latest rating.');
            assert.equal(recovered.rating!.revision, previous.revision + 1);
          } else {
            assert.equal(recovered.state, 'not_recorded'); assert.equal(recovered.rating, null);
            assert.equal((await resumed.readBuyerProductStars(value.buyerUserId, {targetId: target.id}))!.revision, previous.revision);
            // Only a deliberate retry of the unchanged original request writes.
            retried = await resumed.submitProductStars(value.buyerUserId, command);
            assert.deepEqual(await resumed.submitProductStars(value.buyerUserId, command, true), retried);
            assert.equal((await receipts.get()).size, receiptCountBefore + 1);
          }
          console.log(`LF13_RECOVERY_PROJECTION=${JSON.stringify({phase, target, command, recovered, retried,
            receiptCountBefore, receiptCountAfterFailure, receiptCountAfterRecovery})}`);
        });
      }
  } finally {await db.terminate(); await deleteApp(app);}
});

test("LF-FEEDBACK private stars have submit/reconcile and retailer reader surfaces", () => {
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "readBuyerProductFeedbackTarget"), "function");
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "submitProductStars"), "function");
  assert.equal(typeof Reflect.get(WorkspaceOrderOperationsService.prototype, "listStoreProductStars"), "function");
});

test("LF-FEEDBACK collected maximum100-line Store completion creates bounded exact targets atomically", {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
  const app = initializeApp({projectId: "demo-lf-feedback-max"}, `feedback-${randomUUID()}`), db = purchaseTestFirestore(app);
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
    const outsideFirstPage = order.original.lines.find(l => !page.targets.some(t => t.orderLineId === l.lineId))!;
    const exact = await service.readBuyerProductFeedbackTarget(value.buyerUserId, {...scope,
      originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision, orderLineId: outsideFirstPage.lineId});
    assert.equal(exact.target.orderLineId, outsideFirstPage.lineId);
    assert.deepEqual(exact.target.purchasedListing, outsideFirstPage.publicListing);
    const exactScope = {...scope, originalFingerprint: order.originalFingerprint, sourceRevision: buyer.sourceRevision,
      orderLineId: outsideFirstPage.lineId};
    const path = root.collection("productFeedbackTargets").doc(exact.target.id), frozen = (await path.get()).data()!;
    const completionBefore = JSON.stringify(await service.readCompletion(value.buyerUserId, "buyer", scope));
    const ratingCount = (await root.collection("productStarRatings").get()).size;
    const receiptCount = (await root.collection("productStarReceipts").get()).size;
    await assert.rejects(service.readBuyerProductFeedbackTarget("another-buyer", exactScope), rejectsCode("not_found"));
    for (const changed of [{orderLineId: "missing"}, {sourceRevision: "changed"}, {originalFingerprint: "b".repeat(64)}]) {
      await assert.rejects(service.readBuyerProductFeedbackTarget(value.buyerUserId, {...exactScope, ...changed}), rejectsCode("not_found"));
    }
    await path.update({"target.productLabel": "tampered"});
    await assert.rejects(service.readBuyerProductFeedbackTarget(value.buyerUserId, exactScope), rejectsCode("invalid_state"));
    await path.delete();
    await assert.rejects(service.readBuyerProductFeedbackTarget(value.buyerUserId, exactScope), rejectsCode("service_unavailable"));
    assert.equal((await path.get()).exists, false);
    await path.set(frozen);
    assert.deepEqual((await path.get()).data(), frozen);
    assert.equal((await root.collection("productStarRatings").get()).size, ratingCount);
    assert.equal((await root.collection("productStarReceipts").get()).size, receiptCount);
    assert.equal(JSON.stringify(await service.readCompletion(value.buyerUserId, "buyer", scope)), completionBefore);
    console.log(`LF_EXACT_PRODUCT_TARGET=${JSON.stringify(exact)}`);
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
  const db = purchaseTestFirestore(app), suffix = randomUUID();
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
  const db = purchaseTestFirestore(app), suffix = randomUUID();
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
  const db = purchaseTestFirestore(firstApp), fresh = purchaseTestFirestore(secondApp);
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
  let phase = "initial-counts";
  // Keep both calls concurrent, but never tear down a client while its sibling
  // is still running. Report only static phases/statuses, not private facts.
  async function concurrentPair<T>(left: Promise<T>, right: Promise<T>): Promise<[T, T]> {
    const results = await Promise.allSettled([left, right]);
    console.info(`LF10_ATOMIC_PHASE=${phase}; outcomes=${results.map(r => r.status).join(",")}`);
    for (const result of results) {
      if (result.status === "rejected") throw result.reason;
    }
    assert.equal(results[0]!.status, "fulfilled");
    assert.equal(results[1]!.status, "fulfilled");
    return [
      (results[0] as PromiseFulfilledResult<T>).value,
      (results[1] as PromiseFulfilledResult<T>).value,
    ];
  }
  try {
    const before = (await root.collection("purchases").get()).size;
    const receiptsBefore = (await root.collection("receipts").get()).size;
    phase = "missing-profile-atomicity";
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
    phase = "same-receipt-concurrency";
    const [a, b] = await concurrentPair(service.materialize("trusted-ref"), service.materialize("trusted-ref"));
    assert.deepEqual(a, b);
    phase = "replay-and-authorized-readback";
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
    phase = "reference-repair-and-privacy";
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
    phase = "second-receipt-and-paging";
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
    phase = "distinct-receipt-shared-buyer-concurrency";
    const [d, e] = await concurrentPair(service.materialize("concurrent-one"), service.materialize("concurrent-two"));
    assert.notEqual(d.purchaseId, e.purchaseId); assert.equal(d.buyerId, e.buyerId);
    phase = "suspension-and-historical-repair";
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
    phase = "immutable-buyer-and-corruption-guard";
    assert.equal((await reader.readBuyer(value.buyerUserId, {purchaseId: a.purchaseId})).orders.length, 2);
    const doc = root.collection("purchases").doc(a.purchaseId);
    const corrupt = (await doc.get()).data()!;
    corrupt.orders[0].original.totals.totalMinor++;
    await doc.set(corrupt);
    await assert.rejects(reader.readBuyer(value.buyerUserId, {purchaseId: a.purchaseId}), rejectsCode("invalid_state"));
  } catch (error) {
    const code = (error as {code?: unknown})?.code;
    console.error(`LF10_ATOMIC_FAILURE=${phase}; code=${typeof code === "number" ? code : "non-numeric"}`);
    throw error;
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

test('AGG08-DEVICE actual SDK original sharing mismatch recovery and bounded pages', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST, timeout: 180000,
}, async t => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: 'demo-agg08-private-device'}, `device-${randomUUID()}`);
  const db = purchaseTestFirestore(app), input = receipt(`device-${randomUUID()}`);
  const clock = () => new Date();
  try {
    for (const store of input.stores) await db.collection('workspaceProfiles').doc(store.caseId).set({
      schemaVersion: 1, caseId: store.caseId, workspaceId: store.storeId, ownerUserId: store.ownerUserId,
      familyId: 'products-trade', profileId: 'retailer-grocery', status: 'live', shopEnabled: true,
    });
    const projection = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => input});
    const made = await projection.materialize('isolated-device-original');
    for (const store of input.stores) await db.collection('workspaceProfiles').doc(store.caseId).update({shopEnabled: false});
    const before = await projection.readBuyer(input.buyerUserId, {purchaseId: made.purchaseId});
    const order = before.orders[0]!, owner = input.stores[0]!.ownerUserId;
    const reference = {purchaseId: before.purchaseId, storeId: order.storeId, orderId: order.orderId,
      originalFingerprint: order.originalFingerprint, sourceRevision: before.sourceRevision};
    const hash = (v: unknown) => createHash('sha256').update(JSON.stringify(v)).digest('hex');
    const canonical = (v: unknown): unknown => Array.isArray(v) ? v.map(canonical) : v && typeof v === 'object'
      ? Object.fromEntries(Object.keys(v).sort().map(k => [k, canonical((v as Record<string, unknown>)[k])])) : v;
    const frozenLine = order.original.lines[0]!;
    const nativeLine = {lineId: frozenLine.lineId, skuId: frozenLine.skuId, canonicalProductId: frozenLine.canonicalProductId,
      verifiedPackId: frozenLine.verifiedPackId, offerId: frozenLine.offerId, offerRevision: frozenLine.offerRevision,
      name: frozenLine.name, packLabel: frozenLine.packLabel, quantityMilli: frozenLine.quantityMilli,
      quantityUnit: frozenLine.quantityUnit, unitPriceMinor: frozenLine.unitPriceMinor, lineTotalMinor: frozenLine.lineTotalMinor};
    const target = (actor: string, role: 'buyer' | 'seller', change: Record<string, unknown> = {}) => {
      const target = {role, realm: 'evaluation', buyingStoreId: null, reference, lineFacts: nativeLine, ...change};
      return {...target, binding: hash(canonical([actor, target.role, target.realm, target.buyingStoreId, target.reference, target.lineFacts]))};
    };
    const seller = target(owner, 'seller'), buyer = target(input.buyerUserId, 'buyer');
    const service = () => new WorkspaceOrderOperationsService(db, 'evaluation', undefined, clock);
    const call = async (actor: string, operation: string, target: object, rest: object = {}) =>
      await service().purchasedDevices(actor, operation, {target, ...rest}) as any;
    const key = (actor: string, target: typeof seller) => ({account: actor, realm: 'evaluation', store: order.storeId, binding: target.binding});
    const share = (operationId: string, expectedRevision: number, rows: object[]) => {
      const k = key(owner, seller);
      return {version: 1, key: k, operationId, expectedRevision, rows, fingerprint: hash([1, k, operationId, expectedRevision, rows])};
    };
    const row = {id: 'unit-one', serial: 'printed SERIAL-01', imei1: 'printed IMEI-01', imei2: ''};
    await t.test('empty authorized original read does not create records or grants for a stranger', async () => {
      assert.equal((await call(owner, 'readPurchasedUnits', seller)).record.revision, 0);
      assert.equal((await call(input.buyerUserId, 'readPurchasedUnits', buyer)).record.complete, true);
      await assert.rejects(call('foreign-user', 'readPurchasedUnits', target('foreign-user', 'buyer')), rejectsCode('not_found'));
      await assert.rejects(call(input.buyerUserId, 'readPurchasedUnits', {...buyer, binding: seller.binding}), rejectsCode('invalid_input'));
      await assert.rejects(call(owner, 'readPurchasedUnits', target(owner, 'seller', {buyingStoreId: 'foreign-store'})), rejectsCode('not_found'));
      await assert.rejects(call(owner, 'readPurchasedUnits', target(owner, 'seller', {lineFacts: {...seller.lineFacts, skuId: 'forged-sku'}})), rejectsCode('conflict'));
      assert.equal((await db.collection('workspacePurchaseProjections').doc('evaluation').collection('purchasedUnits').get()).size, 0);
    });
    const command = share('a'.repeat(32), 0, [row]);
    await t.test('unknown status is observational and concurrent duplicates apply once', async () => {
      assert.equal((await call(owner, 'reconcilePurchasedUnits', seller, {command})).state, 'pending');
      const [a, b] = await Promise.all([call(owner, 'sharePurchasedUnits', seller, {command}), call(owner, 'sharePurchasedUnits', seller, {command})]);
      assert.deepEqual(a, b); assert.equal(a.record.revision, 1); assert.deepEqual(a.record.rows, [row]);
      assert.deepEqual(await call(owner, 'reconcilePurchasedUnits', seller, {command}), a);
      await assert.rejects(call(owner, 'sharePurchasedUnits', seller, {command: share(command.operationId, 0, [{...row, serial: 'different'}])}), rejectsCode('conflict'));
      await assert.rejects(call(owner, 'sharePurchasedUnits', seller, {command: share('b'.repeat(32), 0, [row])}), rejectsCode('conflict'));
    });
    let snapshot = (await call(input.buyerUserId, 'readPurchasedUnits', buyer)).record;
    const mismatch = (operationId: string, rows = [row], note = 'Printed identifier does not match received unit') => {
      const k = key(input.buyerUserId, buyer), sourceFingerprint = hash(canonical([buyer.binding, snapshot.revision, snapshot.rows, true]));
      return {version: 1, key: k, operationId, sourceRevision: snapshot.revision, sourceFingerprint, note, rows,
        fingerprint: hash([1, k, operationId, snapshot.revision, sourceFingerprint, note, rows])};
    };
    const reportCommand = mismatch('c'.repeat(32));
    await t.test('private buyer observation is exact, idempotent and separate from supplier identifiers', async () => {
      assert.equal((await call(input.buyerUserId, 'reconcilePurchasedUnitMismatch', buyer, {command: reportCommand})).state, 'pending');
      const [a, b] = await Promise.all([call(input.buyerUserId, 'reportPurchasedUnitMismatch', buyer, {command: reportCommand}),
        call(input.buyerUserId, 'reportPurchasedUnitMismatch', buyer, {command: reportCommand})]);
      assert.deepEqual(a, b); assert.equal(a.state, 'applied');
      assert.deepEqual(await call(input.buyerUserId, 'reconcilePurchasedUnitMismatch', buyer, {command: reportCommand}), a);
      await assert.rejects(call(input.buyerUserId, 'reportPurchasedUnitMismatch', buyer,
        {command: mismatch('d'.repeat(32), [{...row, serial: 'not supplied'}])}), rejectsCode('conflict'));
      const inbox = await call(owner, 'readReceivedDeviceReports', seller, {cursor: null});
      assert.equal(inbox.reports.length, 1); assert.equal(inbox.reports[0].id, a.reportId);
      assert.equal('supportCase' in inbox.reports[0], false); assert.deepEqual(inbox.reports[0].rows, [row]);
      assert.deepEqual((await call(input.buyerUserId, 'readPurchasedUnits', buyer)).record.rows, [row]);
      await assert.rejects(call(input.buyerUserId, 'readReceivedDeviceReports', buyer, {cursor: null}), rejectsCode('not_found'));
      if (process.env.AGG08_DEVICE_WIRE_EXPORT_PATH) writeFileSync(process.env.AGG08_DEVICE_WIRE_EXPORT_PATH,
        JSON.stringify({data: 'ISOLATED HOST SDK output; never install on phone', before,
          sellerProjection: {...before, viewerRole: 'seller', viewerUserId: owner, orders: [order]},
          seller, buyer, command, reportCommand, shareResult: await call(owner, 'reconcilePurchasedUnits', seller, {command}),
          reportResult: a, sellerRead: await call(owner, 'readPurchasedUnits', seller),
          buyerRead: await call(input.buyerUserId, 'readPurchasedUnits', buyer), inbox}, null, 2), {flag: 'wx'});
    });
    await t.test('1000 Unicode-heavy rows persist below document limits with frozen old receipt recovery', async () => {
      const rows = Array.from({length: 1000}, (_, i) => ({id: `unit-${i}`, serial: 'क'.repeat(240), imei1: '字'.repeat(240), imei2: 'م'.repeat(240)}));
      assert.ok(Buffer.byteLength(JSON.stringify(rows), 'utf8') > 1048576);
      const big = share('e'.repeat(32), 1, rows);
      const result = await call(owner, 'sharePurchasedUnits', seller, {command: big});
      assert.equal(result.record.rows.length, 1000); assert.equal(result.record.revision, 2);
      assert.deepEqual((await call(owner, 'reconcilePurchasedUnits', seller, {command})).record.rows, [row]);
      const root = db.collection('workspacePurchaseProjections').doc('evaluation').collection('purchasedUnits');
      const docs = await root.get(); assert.equal(docs.size, 1);
      assert.equal('rows' in docs.docs[0]!.data(), false);
      const pages = await docs.docs[0]!.ref.collection('revisions').doc('2').collection('pages').get();
      assert.equal(pages.size, 10); assert.ok(pages.docs.every(d => Buffer.byteLength(JSON.stringify(d.data()), 'utf8') < 1048576));
      assert.deepEqual((await call(input.buyerUserId, 'readPurchasedUnits', buyer)).record.rows, rows);
      await assert.rejects(call(input.buyerUserId, 'reportPurchasedUnitMismatch', buyer, {command: mismatch('f'.repeat(32))}), rejectsCode('conflict'));
      await call(owner, 'sharePurchasedUnits', seller, {command: share('1'.repeat(32), 2, [row])});
      snapshot = (await call(input.buyerUserId, 'readPurchasedUnits', buyer)).record;
    });
    await t.test('seller inbox is bounded and cursor binds current complete revision', async () => {
      for (let i = 0; i < 51; i++) await call(input.buyerUserId, 'reportPurchasedUnitMismatch', buyer,
        {command: mismatch(i.toString(16).padStart(32, '0'), [row], `Received mismatch observation ${i}`)});
      const first = await call(owner, 'readReceivedDeviceReports', seller, {cursor: null});
      assert.equal(first.reports.length, 50); assert.equal(first.complete, false); assert.ok(first.nextCursor);
      const second = await call(owner, 'readReceivedDeviceReports', seller, {cursor: first.nextCursor});
      assert.equal(second.reports.length, 2); assert.equal(second.complete, true);
      assert.equal(new Set([...first.reports, ...second.reports].map((r: {id: string}) => r.id)).size, 52);
      await call(input.buyerUserId, 'reportPurchasedUnitMismatch', buyer, {command: mismatch('2'.repeat(32))});
      await assert.rejects(call(owner, 'readReceivedDeviceReports', seller, {cursor: first.nextCursor}), rejectsCode('conflict'));
    });
    await t.test('revoked current seller access blocks read, mutation and original-status replay', async () => {
      await db.collection('workspaceProfiles').doc(input.stores[0]!.caseId).update({status: 'suspended'});
      for (const [operation, rest] of [['readPurchasedUnits', {}], ['reconcilePurchasedUnits', {command}],
        ['sharePurchasedUnits', {command}], ['readReceivedDeviceReports', {cursor: null}]] as const)
        await assert.rejects(call(owner, operation, seller, rest), rejectsCode('not_found'));
      assert.deepEqual(await projection.readBuyer(input.buyerUserId, {purchaseId: made.purchaseId}), before);
    });
  } finally {await db.terminate(); await deleteApp(app);}
});

test('AGG08-DEVICE Store buyer history requires the original current buying Store independently of paid access', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST, timeout: 60000,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: 'demo-agg08-device-store-buyer'}, `device-store-${randomUUID()}`), db = purchaseTestFirestore(app);
  const input = purchaserReceipt(), buyingStore = input.purchaser.storeId!, caseId = input.purchasingStoreCaseId!;
  const hash = (v: unknown) => createHash('sha256').update(JSON.stringify(v)).digest('hex');
  const canonical = (v: unknown): unknown => Array.isArray(v) ? v.map(canonical) : v && typeof v === 'object'
    ? Object.fromEntries(Object.keys(v).sort().map(k => [k, canonical((v as Record<string, unknown>)[k])])) : v;
  try {
    for (const s of input.stores) await db.collection('workspaceProfiles').doc(s.caseId).set({schemaVersion: 1,
      caseId: s.caseId, workspaceId: s.storeId, ownerUserId: s.ownerUserId, familyId: 'products-trade', profileId: 'wholesaler', status: 'live', shopEnabled: true});
    await db.collection('workspaceProfiles').doc(caseId).set({schemaVersion: 1, caseId, workspaceId: buyingStore,
      ownerUserId: input.buyerUserId, familyId: 'products-trade', profileId: 'retailer-grocery', status: 'live', shopEnabled: false});
    const originals = new WorkspacePurchaseProjectionService(db, 'evaluation', {readFinalPlacement: async () => input});
    const made = await originals.materialize('HOST-device-buying-Store-original');
    const before = await originals.readBuyer(input.buyerUserId, {purchaseId: made.purchaseId, buyingStoreId: buyingStore});
    const order = before.orders[0]!, reference = {purchaseId: made.purchaseId, storeId: order.storeId, orderId: order.orderId,
      originalFingerprint: order.originalFingerprint, sourceRevision: before.sourceRevision};
    const target = (actor: string, role: 'buyer' | 'seller', buying: string | null) => {
      const t = {role, realm: 'evaluation', buyingStoreId: buying, reference, lineFacts: order.original.lines[0]!};
      return {...t, binding: hash(canonical([actor, role, 'evaluation', buying, reference, t.lineFacts]))};
    };
    const buyer = target(input.buyerUserId, 'buyer', buyingStore), seller = target(input.stores[0]!.ownerUserId, 'seller', null);
    const service = new WorkspaceOrderOperationsService(db, 'evaluation');
    const call = (actor: string, operation: string, target: object, rest: object = {}) => service.purchasedDevices(actor, operation, {target, ...rest}) as Promise<any>;
    const rows = [{id: 'HOST-device-one', serial: 'Printed device number', imei1: '', imei2: ''}], operationId = 'a'.repeat(32);
    const key = {account: input.stores[0]!.ownerUserId, realm: 'evaluation', store: order.storeId, binding: seller.binding};
    const command = {version: 1, key, operationId, expectedRevision: 0, rows, fingerprint: hash([1, key, operationId, 0, rows])};
    await call(input.stores[0]!.ownerUserId, 'sharePurchasedUnits', seller, {command});
    assert.equal((await call(input.buyerUserId, 'readPurchasedUnits', buyer)).record.rows[0].serial, rows[0]!.serial);
    for (const wrong of [target(input.buyerUserId, 'buyer', null), target(input.buyerUserId, 'buyer', 'foreign-store'),
      target('foreign-buyer', 'buyer', buyingStore)]) await assert.rejects(call(input.buyerUserId, 'readPurchasedUnits', wrong));
    const malformed = {...buyer, role: ['buyer']}; malformed.binding = hash(canonical([input.buyerUserId, ['buyer'], 'evaluation', buyingStore, reference, buyer.lineFacts]));
    await assert.rejects(call(input.buyerUserId, 'readPurchasedUnits', malformed), rejectsCode('not_found'));
    const unknownKey = {account: input.buyerUserId, realm: 'evaluation', store: order.storeId, binding: buyer.binding};
    const sourceFingerprint = hash(canonical([buyer.binding, 1, rows, true])), note = 'Received unit differs';
    const unknown = {version: 1, key: unknownKey, operationId, sourceRevision: 1, sourceFingerprint, note, rows,
      fingerprint: hash([1, unknownKey, operationId, 1, sourceFingerprint, note, rows])};
    assert.equal((await call(input.buyerUserId, 'reconcilePurchasedUnitMismatch', buyer, {command: unknown})).state, 'pending');
    await db.collection('workspaceProfiles').doc(caseId).update({status: 'pending'});
    for (const [operation, rest] of [['readPurchasedUnits', {}], ['reportPurchasedUnitMismatch', {command: unknown}],
      ['reconcilePurchasedUnitMismatch', {command: unknown}]] as const) await assert.rejects(call(input.buyerUserId, operation, buyer, rest), rejectsCode('not_found'));
    await db.collection('workspaceProfiles').doc(caseId).update({status: 'live', ownerUserId: 'foreign-owner'});
    await assert.rejects(call(input.buyerUserId, 'readPurchasedUnits', buyer), rejectsCode('not_found'));
    await db.collection('workspaceProfiles').doc(caseId).update({ownerUserId: input.buyerUserId});
    assert.deepEqual(await originals.readBuyer(input.buyerUserId, {purchaseId: made.purchaseId, buyingStoreId: buyingStore}), before);
  } finally {await db.terminate(); await deleteApp(app);}
});
