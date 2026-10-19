import assert from "node:assert/strict";
import test from "node:test";
import {createHash, generateKeyPairSync, randomUUID} from "node:crypto";
import {createServer} from "node:http";
import {Readable} from "node:stream";
import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {EventEmitter} from "node:events";
import {Storage} from "@google-cloud/storage";
import sharp from "sharp";
import * as catalogueModule from "./workspace_catalogue_service.js";
import {GoogleCloudStoreProductMediaObjects, type StoreProductMediaObjects, type StoreProductMediaUpload,
  type StoreProductMediaRequest, type NormalizedStoreProductImage, storeProductMediaProof, publicProductMediaPath,
  parsePublicProductMediaPath, deliverPublicProductMediaResponse} from "./workspace_catalogue_service.js";
import {initializeApp, deleteApp} from "firebase-admin/app";
import {getFirestore, setLogFunction} from "firebase-admin/firestore";
import {WorkspaceCatalogueService, cataloguePayloadHash, cataloguePublicListingBindings, channelTerms, planCatalogueSave, normalizeSku,
  planCatalogueProduction, planReviewedCatalogueSave, type CatalogueProducerAuthority,
  type CatalogueProductionReceipt, type CatalogueSave, type StoreSkuInput, type StoreSkuContent, type StoreSkuChannel,
  FirestoreWorkspaceCatalogueRepository, type StoreSkuRecord, type WorkspaceCatalogueRepository, type PublicCatalogueSource,
  planStorePublicDetailsSave, normalizeStorePublicDetails, type StorePublicDetailsCommand,
  normalizeSubmittedProduct, storeProductSubmission, storeProductSubmissionOperation, planStoreProductSubmission,
  submittedCatalogueInput, type CatalogueSubmissionReference,
  type StoreProductSubmissionInput, type StoreProductSubmissionRecord,
  type StorePublicDetailsRecord, type StorePublicDetailsReceipt,
  normalizeStoreVariantFamily, storeVariantFamilyOperation, storeVariantFamilySubmission, planStoreVariantFamilySubmission,
  planStoreVariantFamilyReview, type StoreVariantFamilyInput, type StoreVariantFamilyCandidate} from "./workspace_catalogue_service.js";
import type {WorkspaceProfileRecord} from "./workspace_profile_service.js";
import {WorkspacePromotionService, FirestorePromotionRepository, planPromotionSave, type PromotionRepository, type PromotionRecord} from "./workspace_promotion_service.js";
import {WorkspaceSupplierPolicyService, FirestoreSupplierPolicyRepository} from "./workspace_supplier_policy_service.js";
import {createCatalogueAggregate, type CatalogueAggregate} from "../commerce/catalogue_contract.js";
import {applySupplyParticipantCommand, registerSupplyParticipantWorkspace,
  type SupplyParticipantWorkspace} from "../commerce/supply_participant_contract.js";

// Isolated host fixtures: never uploaded or inserted into a device/evaluation Store.
const at = "2026-10-16T12:00:00.000Z";

test('LF03-EXEC trusted catalogue commands have an existing-service runtime facade', () => {
  assert.equal(typeof (WorkspaceCatalogueService.prototype as unknown as Record<string, unknown>).handleCatalogueProduction, 'function');
  assert.equal(typeof (catalogueModule as unknown as Record<string, unknown>).catalogueProductionOperation, 'function');
});

for (const kind of ['product', 'pack'] as const) {
  test(`LF03-EXEC dual-role owner cannot review its own base ${kind} proposal`, () => {
    let aggregate: CatalogueAggregate | undefined;
    const commands = productionCommands();
    const reviewIndex = kind === 'product' ? 2 : 4;
    for (let index = 0; index < reviewIndex; index++) {
      const owner = index === 1 || index === 3;
      aggregate = planCatalogueProduction({operatorUserId: owner ? 'owner-one' : 'reviewer-one',
        identity: catalogueIdentity, observedAt: at, input: commands[index]!}, producerAuthority(owner), aggregate,
        owner ? producerParticipant() : undefined, owner ? profile : undefined).aggregate;
    }
    const original = structuredClone(aggregate), owner = producerAuthority(), dual = {...owner,
      actor: {...owner.actor, scopes: [...owner.actor.scopes, 'supply.catalogue.review']}};
    assert.throws(() => planCatalogueProduction({operatorUserId: 'owner-one', identity: catalogueIdentity,
      observedAt: at, input: commands[reviewIndex]!}, dual, aggregate), {code: 'forbidden'});
    assert.deepEqual(aggregate, original);
    const snapshot = aggregate!, eventType = `${kind}_proposed`, proposal = snapshot.auditEvents.find(e => e.eventType === eventType)!;
    for (const corrupted of [
      {...snapshot, auditEvents: snapshot.auditEvents.filter(e => e !== proposal)},
      {...snapshot, auditEvents: [...snapshot.auditEvents, proposal]},
      {...snapshot, auditEvents: snapshot.auditEvents.map(e => e === proposal ? {...e, hashReferences: ['F'.repeat(64)]} : e)},
      {...snapshot, auditEvents: snapshot.auditEvents.map(e => e === proposal ? {...e, tenantId: 'foreign-tenant'} : e)},
      {...snapshot, commandReceipts: snapshot.commandReceipts.filter(r => r.commandId !== proposal.commandId)},
    ]) {
      assert.throws(() => planCatalogueProduction({operatorUserId: 'reviewer-one', identity: catalogueIdentity,
        observedAt: at, input: commands[reviewIndex]!}, producerAuthority(false), corrupted), {code: 'forbidden'});
    }
    const reviewed = planCatalogueProduction({operatorUserId: 'reviewer-one', identity: catalogueIdentity,
      observedAt: at, input: commands[reviewIndex]!}, producerAuthority(false), snapshot);
    assert.equal(reviewed.aggregate.version, snapshot.version + 1);
    assert.equal(planCatalogueProduction({operatorUserId: 'reviewer-one', identity: catalogueIdentity,
      observedAt: at, input: commands[reviewIndex]!}, producerAuthority(false), reviewed.aggregate, undefined, undefined,
      {fingerprint: reviewed.fingerprint, result: reviewed.aggregate}).replayed, true);
  });
}

test('LF03-EXEC exact caller envelopes cannot nominate actor, authority or configured scope', async () => {
  const classify = catalogueModule.catalogueProductionOperation;
  assert.deepEqual(['submitCatalogueSourceProposal', 'executeCatalogueProduction', 'resolveStoreProductReview'].map(classify), ['proposal', 'command', 'resolve']);
  for (const op of [null, {}, ['executeCatalogueProduction'], 'executeCatalogueProduction ', 'executeCatalogueProductionExtra', 'approveMyProduct']) assert.equal(classify(op), undefined);
  const calls: unknown[] = [];
  const repository = {realm: 'evaluation', produceCatalogue: async (...args: unknown[]) => {
    calls.push(args); return {version: 7, privateAuthority: 'must-never-return'} as unknown as CatalogueAggregate;
  }} as unknown as WorkspaceCatalogueRepository;
  const service = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(at));
  const body = {command: {type: 'create', commandId: 'operator-create'}};
  assert.deepEqual(await service.handleCatalogueProduction('reviewer-one', 'executeCatalogueProduction', body), {
    schemaVersion: 1, realm: 'evaluation', operation: 'executeCatalogueProduction', state: 'recorded', commandId: 'operator-create', catalogueVersion: 7,
  });
  assert.deepEqual(calls[0], ['reviewer-one', catalogueIdentity, body.command]);
  for (const field of ['operatorUserId', 'ownerUserId', 'actor', 'authority', 'scopes', 'realm', 'catalogueId', 'tenantId', 'identity']) {
    await assert.rejects(service.handleCatalogueProduction('owner-one', 'executeCatalogueProduction', {...body, [field]: 'reviewer-one'}));
    await assert.rejects(service.handleCatalogueProduction('owner-one', 'executeCatalogueProduction', {command: {...body.command, [field]: 'reviewer-one'}}));
  }
  for (const command of [productionCommands()[1]!, productionCommands()[3]!]) {
    await assert.rejects(service.handleCatalogueProduction('owner-one', 'executeCatalogueProduction', {command}));
  }
  assert.equal(calls.length, 1);
  await assert.rejects(new WorkspaceCatalogueService(repository).handleCatalogueProduction('reviewer-one', 'executeCatalogueProduction', body));
  await assert.rejects(new WorkspaceCatalogueService({realm: 'evaluation'} as WorkspaceCatalogueRepository, catalogueIdentity)
    .handleCatalogueProduction('reviewer-one', 'executeCatalogueProduction', body));
  await assert.rejects(service.handleCatalogueProduction('reviewer-one', 'approveMyProduct', body));
});

test('LF03-REVIEW runtime media inspection returns only exact normalized bytes to the verified reviewer', async () => {
  assert.equal(catalogueModule.catalogueProductionOperation('readCatalogueSourceMedia'), 'review_media');
  const bytes = await sharp({create: {width: 128, height: 128, channels: 3, background: '#277250'}}).png().toBuffer();
  const hash = createHash('sha256').update(bytes).digest('hex').toUpperCase();
  const uploadId = 'A'.repeat(64), generation = '1';
  const proof = {version: 1 as const, uploadId, uploadFingerprint: 'B'.repeat(64), selectedSha256: 'C'.repeat(64),
    assetId: cataloguePayloadHash({uploadId, generation, sha256: hash}), originalGeneration: generation, derivativeGeneration: '2',
    source: {sha256: 'C'.repeat(64), byteLength: 1000, width: 512, height: 512, mimeType: 'image/png'},
    file: {sha256: hash, byteLength: bytes.length, width: 128, height: 128, mimeType: 'image/png', normalized: true as const, frameCount: 1}};
  const source = {realm: 'evaluation' as const, storeId: 'store-one', skuId: 'sku-one', revision: 1, fingerprint: 'D'.repeat(64), media: proof};
  const calls: unknown[] = [];
  let returned = bytes;
  const repository = {realm: 'evaluation', readProductMediaForReview: async (...args: unknown[]) => {
    calls.push(args);
    if (args[0] !== 'reviewer-one') throw Object.assign(Error('Independent review required'), {code: 'forbidden'});
    return {bytes: returned, proof};
  }} as unknown as WorkspaceCatalogueRepository;
  const service = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(at));
  assert.deepEqual(await service.handleCatalogueProduction('reviewer-one', 'readCatalogueSourceMedia', {source}), {
    schemaVersion: 1, realm: 'evaluation', operation: 'readCatalogueSourceMedia', state: 'private_review_media',
    source, file: {mimeType: 'image/png', sha256: hash, byteLength: bytes.length, base64: bytes.toString('base64')},
  });
  assert.deepEqual(calls[0], ['reviewer-one', catalogueIdentity, source]);
  await assert.rejects(service.handleCatalogueProduction('owner-one', 'readCatalogueSourceMedia', {source}), {code: 'forbidden'});
  for (const body of [{source, actor: 'reviewer-one'}, {source: {...source, realm: 'production'}}, {source: {...source, media: undefined}}]) {
    await assert.rejects(service.handleCatalogueProduction('reviewer-one', 'readCatalogueSourceMedia', body));
  }
  returned = Buffer.from(bytes).fill(0);
  await assert.rejects(service.handleCatalogueProduction('reviewer-one', 'readCatalogueSourceMedia', {source}));
  returned = Buffer.alloc(8 * 1024 * 1024 + 1);
  await assert.rejects(service.handleCatalogueProduction('reviewer-one', 'readCatalogueSourceMedia', {source}));
  await assert.rejects(new WorkspaceCatalogueService({realm: 'evaluation'} as WorkspaceCatalogueRepository, catalogueIdentity)
    .handleCatalogueProduction('reviewer-one', 'readCatalogueSourceMedia', {source}), {code: 'service_unavailable'});
});

test('LF03-REVIEW runtime variant review preserves exact request and returns a minimal decision acknowledgement', async () => {
  assert.equal(catalogueModule.catalogueProductionOperation('reviewCatalogueVariantFamily'), 'review_family');
  const fixture = familyFixture(), calls: unknown[] = [];
  let result = planStoreVariantFamilyReview('reviewer-one', catalogueIdentity, fixture.review,
    producerAuthority(false), fixture.candidate, fixture.records, fixture.aggregate, at);
  const repository = {realm: 'evaluation', reviewVariantFamily: async (...args: unknown[]) => {
    calls.push(args);
    if (args[0] !== 'reviewer-one') throw Object.assign(Error('Independent review required'), {code: 'forbidden'});
    return structuredClone(result);
  }} as unknown as WorkspaceCatalogueRepository;
  const service = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(at));
  const body = {storeId: 'store-one', familyId: fixture.family.familyId, review: fixture.review};
  const response = await service.handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', body);
  assert.deepEqual(response, {schemaVersion: 1, realm: 'evaluation', operation: 'reviewCatalogueVariantFamily', state: 'reviewed_family',
    storeId: 'store-one', familyId: fixture.family.familyId, candidateRevision: fixture.candidate.revision,
    candidateFingerprint: fixture.candidate.fingerprint, reviewRevision: 1, decision: 'verify'});
  assert.deepEqual(calls[0], ['reviewer-one', catalogueIdentity, 'store-one', fixture.family.familyId, fixture.review]);
  assert.doesNotMatch(JSON.stringify(response), /reviewerUserId|submittedBy|members|producerAuthorities/);
  await assert.rejects(service.handleCatalogueProduction('owner-one', 'reviewCatalogueVariantFamily', body), {code: 'forbidden'});
  for (const field of ['actor', 'operatorUserId', 'authority', 'identity', 'realm', 'catalogueId', 'tenantId']) {
    await assert.rejects(service.handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', {...body, [field]: 'forged'}));
  }
  result = {...result, candidate: {...result.candidate, storeId: 'another-store'}};
  await assert.rejects(service.handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', body));
  await assert.rejects(new WorkspaceCatalogueService({realm: 'evaluation'} as WorkspaceCatalogueRepository, catalogueIdentity)
    .handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', body), {code: 'service_unavailable'});
});

test('LF03-REVIEW private byte responses use the existing bounded delivery lifecycle after authentication', () => {
  const index = readFileSync(`${__dirname}/../../src/index.ts`, 'utf8');
  const start = index.indexOf('export const moolSocialWorkspace = onRequest(');
  const route = index.slice(start, index.indexOf('function workspaceOrderOperationsService', start));
  const branch = route.indexOf('if (catalogueProductionAction === "review_media")');
  assert.ok(branch > route.indexOf('const ownerUserId = await verifySocialInvocation('));
  const guarded = route.slice(branch, route.indexOf('const result = catalogueProductionAction', branch));
  assert.ok(guarded.includes('await deliverPublicProductMediaResponse(response, async () =>'));
  assert.ok(guarded.indexOf('deliverPublicProductMediaResponse') < guarded.indexOf('handleCatalogueProduction'));
  assert.ok(guarded.includes('Buffer.from(JSON.stringify({ok: true, data:'));
  assert.ok(guarded.includes('"content-type", "application/json; charset=utf-8"'));
  assert.ok(guarded.includes('response.status(200).send(bytes)'));
  assert.match(guarded, /return;\s*\}\s*$/u);
});

test('LF03-EXEC existing HTTP dispatch pins privileged actions to verified mutation identity and default-off activation', () => {
  const index = readFileSync(`${__dirname}/../../src/index.ts`, 'utf8');
  const start = index.indexOf('export const moolSocialWorkspace = onRequest('), end = index.indexOf('function workspaceOrderOperationsService', start);
  assert.ok(start >= 0 && end > start);
  const route = index.slice(start, end);
  assert.ok(route.includes('process.env.MOOLSOCIAL_CATALOGUE_PRODUCER_V1 !== "true"'));
  assert.ok(route.indexOf('process.env.MOOLSOCIAL_CATALOGUE_PRODUCER_V1') < route.indexOf('await verifySocialInvocation('));
  assert.ok(route.slice(route.indexOf('const mutation ='), route.indexOf('const supplierPolicyOperation')).includes('catalogueProductionAction !== undefined'));
  assert.ok(route.slice(route.indexOf('const catalogueOperation ='), route.indexOf('const orderMutation =')).includes('catalogueProductionAction !== undefined'));
  assert.ok(route.includes('requireDefaultPurchaseTenant(verified.firebase?.tenant)'));
  assert.ok(route.includes('consume ? { consume: true } : undefined'));
  assert.ok(route.includes('handleCatalogueProduction(ownerUserId, operation, catalogueBody)'));
  const factory = index.slice(index.indexOf('function workspaceCatalogueService()'), index.indexOf('export const youtubeOAuthCallback'));
  for (const name of ['MOOLSOCIAL_CATALOGUE_REALM', 'MOOLSOCIAL_CATALOGUE_ID', 'MOOLSOCIAL_CATALOGUE_TENANT_ID']) assert.ok(factory.includes(`process.env.${name}`));
});

test('LF03-EXEC emulator caller path preserves source, independent review, private candidate and explicit public adoption', {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-exec-${randomUUID().slice(0, 8)}`}, `exec-${randomUUID()}`);
  const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation');
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
  const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
  const invoke = (actor: string, operation: string, body: Record<string, unknown>) => service().handleCatalogueProduction(actor, operation, body);
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant());
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const product = submittedProduct(); product.channels[0]!.priceMinor = 10025;
    const submitted = await service().handleProductSubmission('owner-one', 'submitStoreProduct', productRequest({product})) as any;
    const record = submitted.record as StoreProductSubmissionRecord;
    const source: CatalogueSubmissionReference = {realm: 'evaluation', storeId: record.storeId, skuId: record.skuId, revision: record.revision, fingerprint: record.fingerprint};
    const value: StoreSkuInput = {...input(), content: {...product.content, media: []}, provenance: product.provenance,
      channels: product.channels.map(channel => ({...channel, offerId: 'offer-one'}))};
    const commands = productionCommands(value), {contentSha256: _, categoryId: __, ...proposal} = commands[1]!,
      {descriptorSha256: ___, ...packProposal} = commands[3]!;
    const reviewIndependently = async (command: Record<string, unknown>) => {
      const owner = producerAuthority(), dual = {...owner, actor: {...owner.actor, scopes: [...owner.actor.scopes, 'supply.catalogue.review']}};
      const catalogueRef = root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId);
      const before = (await catalogueRef.get()).data(), receipts = (await catalogueRef.collection('producerReceipts').get()).docs.map(d => [d.id, d.data()]);
      await root.collection('producerAuthorities').doc('owner-one').set(dual);
      await assert.rejects(invoke('owner-one', 'executeCatalogueProduction', {command}), {code: 'forbidden'});
      assert.deepEqual((await catalogueRef.get()).data(), before);
      assert.deepEqual((await catalogueRef.collection('producerReceipts').get()).docs.map(d => [d.id, d.data()]), receipts);
      await root.collection('producerAuthorities').doc('owner-one').set(owner);
      return invoke('reviewer-one', 'executeCatalogueProduction', {command});
    };
    await assert.rejects(invoke('stranger', 'executeCatalogueProduction', {command: commands[0]!}), {code: 'forbidden'});
    await invoke('reviewer-one', 'executeCatalogueProduction', {command: commands[0]!});
    await assert.rejects(invoke('stranger', 'submitCatalogueSourceProposal', {source: {...source, fingerprint: 'F'.repeat(64)}, command: proposal}), {code: 'forbidden'});
    await assert.rejects(invoke('reviewer-one', 'submitCatalogueSourceProposal', {source, command: proposal}), {code: 'forbidden'});
    await assert.rejects(invoke('owner-one', 'submitCatalogueSourceProposal', {source: {...source, storeId: 'foreign-store'}, command: proposal}));
    await assert.rejects(invoke('owner-one', 'submitCatalogueSourceProposal', {source: {...source, fingerprint: 'F'.repeat(64)}, command: proposal}), {code: 'conflict'});
    const catalogueRef = root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId);
    const beforePrivateDenials = (await catalogueRef.get()).data(), beforePrivateReceipts = (await catalogueRef.collection('producerReceipts').get()).docs.map(d => [d.id, d.data()]);
    await db.collection('workspaceProfiles').doc(profile.caseId).update({ownerUserId: 'prior-owner'});
    await assert.rejects(invoke('owner-one', 'submitCatalogueSourceProposal', {source: {...source, fingerprint: 'F'.repeat(64)}, command: proposal}), {code: 'forbidden'});
    const previousAuthor = await service().handleProductSubmission('prior-owner', 'submitStoreProduct',
      productRequest({product: submittedProduct('prior-author-sku'), idempotencyKey: 'prior-author-source'})) as any;
    await db.collection('workspaceProfiles').doc(profile.caseId).update({ownerUserId: 'owner-one'});
    const priorSource = {realm: 'evaluation', storeId: 'store-one', skuId: 'prior-author-sku', revision: previousAuthor.record.revision, fingerprint: 'F'.repeat(64)};
    await assert.rejects(invoke('owner-one', 'submitCatalogueSourceProposal', {source: priorSource, command: proposal}), {code: 'forbidden'});
    assert.deepEqual((await catalogueRef.get()).data(), beforePrivateDenials);
    assert.deepEqual((await catalogueRef.collection('producerReceipts').get()).docs.map(d => [d.id, d.data()]), beforePrivateReceipts);
    const first = await invoke('owner-one', 'submitCatalogueSourceProposal', {source, command: proposal});
    assert.equal(Object.hasOwn(first, 'products'), false);
    assert.deepEqual(await invoke('owner-one', 'submitCatalogueSourceProposal', {source, command: proposal}), first);
    await assert.rejects(invoke('owner-one', 'submitCatalogueSourceProposal', {source, command: {...proposal, productId: 'changed-under-receipt'}}), {code: 'conflict'});
    await root.collection('producerAuthorities').doc('owner-one').update({enabled: false});
    await assert.rejects(invoke('owner-one', 'submitCatalogueSourceProposal', {source, command: proposal}), {code: 'forbidden'});
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await assert.rejects(new WorkspaceCatalogueService(repository(), {...catalogueIdentity, tenantId: 'foreign-tenant'}, () => new Date(at))
      .handleCatalogueProduction('owner-one', 'submitCatalogueSourceProposal', {source, command: proposal}), {code: 'forbidden'});
    await reviewIndependently(commands[2]!);
    await invoke('owner-one', 'submitCatalogueSourceProposal', {source, command: packProposal});
    await reviewIndependently(commands[4]!);
    await invoke('owner-one', 'executeCatalogueProduction', {command: commands[5]!});
    const resolution = {source, expectedReviewRevision: 0, idempotencyKey: 'resolve-caller', canonicalProductId: value.canonicalProductId,
      verifiedPackId: value.verifiedPackId, offers: [{kind: 'retail', offerId: 'offer-one'}]};
    for (const field of ['operatorUserId', 'authority', 'identity', 'realm', 'catalogueId', 'tenantId']) {
      await assert.rejects(invoke('owner-one', 'submitCatalogueSourceProposal', {source, command: proposal, [field]: 'reviewer-one'}), {code: 'invalid_input'});
      await assert.rejects(invoke('reviewer-one', 'resolveStoreProductReview', {...resolution, [field]: 'owner-one'}), {code: 'invalid_input'});
    }
    const owner = producerAuthority(), ownerReview = {...owner,
      actor: {...owner.actor, scopes: [...owner.actor.scopes, 'supply.catalogue.review']}};
    await root.collection('producerAuthorities').doc('owner-one').set(ownerReview);
    await assert.rejects(invoke('owner-one', 'resolveStoreProductReview', resolution), {code: 'forbidden'});
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    const resolved = await invoke('reviewer-one', 'resolveStoreProductReview', resolution) as any;
    assert.equal(resolved.state, 'reviewed_candidate'); assert.equal(resolved.reviewRevision, 1);
    assert.equal(Object.hasOwn(resolved, 'sku'), false); assert.equal(Object.hasOwn(resolved, 'reviewedBy'), false);
    assert.deepEqual(await invoke('reviewer-one', 'resolveStoreProductReview', resolution), resolved);
    await root.collection('producerAuthorities').doc('reviewer-one').update({expiresAt: at});
    await assert.rejects(invoke('reviewer-one', 'resolveStoreProductReview', resolution), {code: 'forbidden'});
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    assert.equal((await root.collection('stores').doc('store-one').collection('skus').get()).size, 0);
    assert.deepEqual((await service().publicCatalogue({storeId: 'store-one'}) as any).items, []);
    const read = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission',
      {productSubmissionVersion: 1, productReviewVersion: 1, storeId: 'store-one', skuId: product.skuId}) as any;
    const candidate = read.review.candidate;
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: candidate.sku, expectedRevision: 0,
      idempotencyKey: 'explicit-caller-adoption', reviewCandidate: {revision: candidate.revision, fingerprint: candidate.fingerprint}});
    const page = await service().publicCatalogue({storeId: 'store-one'}) as any;
    assert.equal(page.items[0].channels[0].priceMinor, 10025); assert.deepEqual(page.items[0].content, value.content);
    const changed = structuredClone(product); changed.content.title = 'Changed private source';
    await service().handleProductSubmission('owner-one', 'submitStoreProduct', productRequest({product: changed, expectedRevision: 1, idempotencyKey: 'next-private-source'}));
    await assert.rejects(invoke('reviewer-one', 'resolveStoreProductReview', {...resolution, expectedReviewRevision: 1, idempotencyKey: 'new-command-stale-source'}), {code: 'conflict'});
    assert.deepEqual(await invoke('reviewer-one', 'resolveStoreProductReview', resolution), resolved);
  } finally {await db.terminate(); await deleteApp(app);}
});
test('LF11 saved selling-Store stock has a producer and exact public quantity-query reader', () => {
  assert.equal(typeof Reflect.get(WorkspaceCatalogueService.prototype, 'handleStoreStock'), 'function');
  assert.equal(typeof Reflect.get(FirestoreWorkspaceCatalogueRepository.prototype, 'storeStock'), 'function');
});
test('LF11 Stock HTTP source admission is explicit, disabled by default and separate from payment/delivery', () => {
  const operations = {publishStoreStockSnapshot: 'save', readStoreStockSnapshot: 'read',
    reconcileStoreStockSnapshot: 'reconcile', readPublicStoreStockSnapshot: 'public'};
  for (const [operation, action] of Object.entries(operations)) assert.equal(catalogueModule.storeStockOperation(operation), action);
  for (const operation of ['assignDelivery', 'confirmPayment', 'reserveStock', 'approveStoreStock', null, {}]) {
    assert.equal(catalogueModule.storeStockOperation(operation), undefined);
  }
  const index = readFileSync(`${__dirname}/../../src/index.ts`, 'utf8');
  assert.match(index, /stockOperation !== undefined && process\.env\.MOOLSOCIAL_STORE_STOCK_V1 !== 'true'/u);
  assert.match(index, /stockOperation === "save"/u);
  assert.match(index, /catalogueOperation[\s\S]*?requireDefaultPurchaseTenant\(verified\.firebase\?\.tenant\)/u);
  assert.match(index, /stockOperation !== undefined\s*\? await workspaceCatalogueService\(\)\.handleStoreStock\(ownerUserId, operation, catalogueBody\)/u);
});
test('LF11 actual Store checkpoint publication, original recovery and private-count public quantity checks', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-stock-${randomUUID().slice(0, 8)}`}, `stock-${randomUUID()}`), db = getFirestore(app);
  const root = db.collection('workspaceCatalogues').doc('evaluation'), store = root.collection('stores').doc('store-one');
  let clock = at;
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(clock));
  const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(clock));
  const binding = {skuId: 'sku-one', skuRevision: 1, canonicalProductId: input().canonicalProductId, verifiedPackId: input().verifiedPackId};
  const scope = {stockSnapshotVersion: 1, storeId: 'store-one', binding};
  const original = {...scope, expectedRevision: 0, idempotencyKey: 'stock-original',
    source: {inventoryRevision: 12, savedAt: at, mode: 'exact_quantity', quantityPacks: 7, available: true}};
  const query = {...scope, requestedPacks: 1};
  const read = (body = query) => service().handleStoreStock('buyer-one', 'readPublicStoreStockSnapshot', body) as Promise<any>;
  const save = (body = original, actor = 'owner-one') => service().handleStoreStock(actor, 'publishStoreStockSnapshot', body) as Promise<any>;
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant());
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const value = input(), commands = productionCommands(value);
    for (let index = 0; index < commands.length; index++) await repository().produceCatalogue([0, 2, 4].includes(index)
      ? 'reviewer-one' : 'owner-one', catalogueIdentity, commands[index]!);
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: value, expectedRevision: 0, idempotencyKey: 'stock-published-binding'});
    const beforeSku = JSON.stringify((await store.collection('skus').doc('sku-one').get()).data());
    assert.equal((await read()).state, 'unknown'); assert.equal((await read()).stock, null);
    await assert.rejects(save(original, 'other-owner'));
    for (const source of [{...original.source, quantityPacks: 1.5}, {...original.source, quantityPacks: -1},
      {...original.source, quantityPacks: '7'}, {...original.source, mode: 'availability_only', quantityPacks: 7},
      {...original.source, inventoryRevision: 0}, {...original.source, savedAt: '2026-10-16T12:00:00Z'},
      {...original.source, savedAt: '2026-10-16T12:00:01.000Z'},
      {...original.source, purchaseCostMinor: 100}]) await assert.rejects(save({...original, source} as any));
    await assert.rejects(save({...original, binding: {...binding, verifiedPackId: 'other-pack'}}));
    await assert.rejects(save({...original, paid: true} as any));
    assert.equal((await store.collection('stockSnapshots').get()).size, 0);
    const first = await save();
    assert.equal(first.state, 'reported'); assert.equal(first.record.source.quantityPacks, 7);
    assert.equal(first.record.revision, 1); assert.equal(first.orderingAvailable, false); assert.equal(first.reservationConfirmed, false);
    assert.deepEqual(await save(), first);
    assert.deepEqual(await service().handleStoreStock('owner-one', 'reconcileStoreStockSnapshot', original), first);
    await assert.rejects(save({...original, source: {...original.source, quantityPacks: 8}}), {code: 'conflict'});
    await assert.rejects(save({...original, idempotencyKey: 'stock-stale-cas'}), {code: 'conflict'});
    const publicOne = await read(), publicShort = await read({...query, requestedPacks: 8});
    assert.equal(publicOne.stock.validUntil, '2026-10-16T12:05:00.000Z');
    assert.equal(publicOne.stock.quantityAvailable, true); assert.equal(publicShort.stock.quantityAvailable, false);
    assert.equal(publicOne.stock.available, true); assert.equal(publicOne.orderingAvailable, false);
    for (const privateField of ['quantityPacks', 'inventoryRevision', 'ownerUserId', 'integrity', 'fingerprint', 'purchaseCost', 'movements']) {
      assert.equal(JSON.stringify(publicOne).includes(privateField), false);
    }
    console.log('LF11_STORE_STOCK_PROJECTION=' + JSON.stringify({owner: first, publicOne, publicShort}));
    const absent = {...original, expectedRevision: 1, idempotencyKey: 'stock-not-dispatched'};
    const receiptCount = (await store.collection('stockSnapshots').doc('sku-one').collection('receipts').get()).size;
    assert.equal((await service().handleStoreStock('owner-one', 'reconcileStoreStockSnapshot', absent) as any).state, 'not_found');
    assert.equal((await store.collection('stockSnapshots').doc('sku-one').collection('receipts').get()).size, receiptCount);
    const zero = await save({...original, expectedRevision: 1, idempotencyKey: 'stock-zero',
      source: {...original.source, inventoryRevision: 13, quantityPacks: 0}});
    assert.equal(zero.record.revision, 2); assert.equal((await read()).stock.quantityAvailable, false);
    assert.equal((await read()).stock.available, false);
    await save({...original, expectedRevision: 2, idempotencyKey: 'stock-availability-only',
      source: {...original.source, inventoryRevision: 1, mode: 'availability_only', quantityPacks: null}} as any);
    assert.equal((await read()).stock.quantityAvailable, null); assert.equal((await read()).stock.available, true);
    assert.deepEqual(await service().handleStoreStock('owner-one', 'reconcileStoreStockSnapshot', original), first);
    clock = '2026-10-16T12:05:00.000Z';
    assert.equal((await read()).state, 'unknown'); assert.equal((await read()).stock, null);
    assert.deepEqual(await save(), first);
    const expiredOriginal = {...original, expectedRevision: 3, idempotencyKey: 'expired-new-stock'};
    const beforeExpiryHead = (await store.collection('stockSnapshots').doc('sku-one').get()).data();
    const expired = await save(expiredOriginal);
    assert.equal(expired.state, 'expired'); assert.equal(expired.record, null);
    assert.equal(expired.originalFingerprint, cataloguePayloadHash({realm: 'evaluation', owner: 'owner-one', request: expiredOriginal}));
    assert.equal(expired.expiredAt, clock); assert.equal(expired.settledAt, clock);
    assert.deepEqual((await store.collection('stockSnapshots').doc('sku-one').get()).data(), beforeExpiryHead);
    assert.deepEqual(await service().handleStoreStock('owner-one', 'reconcileStoreStockSnapshot', expiredOriginal), expired);
    await assert.rejects(save({...expiredOriginal, source: {...original.source, quantityPacks: 8}}), {code: 'conflict'});
    clock = at;
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: value, expectedRevision: 1, idempotencyKey: 'stock-new-binding'});
    assert.equal((await read()).state, 'unknown');
    assert.equal((await read({...query, binding: {...binding, skuRevision: 2}})).state, 'unknown');
    const newScope = {...scope, binding: {...binding, skuRevision: 2}};
    const changed = await service().handleStoreStock('owner-one', 'readStoreStockSnapshot', newScope) as any;
    assert.equal(changed.state, 'source_changed'); assert.equal(changed.record, null); assert.equal(changed.currentRevision, 3);
    await save({...original, binding: newScope.binding, expectedRevision: 3, idempotencyKey: 'stock-new-source',
      source: {...original.source, inventoryRevision: 2}});
    const newQuery = {...query, binding: newScope.binding};
    assert.equal((await read(newQuery)).stock.quantityAvailable, true);
    // An invocation delayed before its transaction cannot later publish after
    // another instance has durably settled that SAME original as expired.
    const delayedOriginal = {...original, binding: newScope.binding, expectedRevision: 4, idempotencyKey: 'late-stock-original'};
    let release!: () => void, entered!: () => void;
    const held = new Promise<void>(resolve => {release = resolve;}), started = new Promise<void>(resolve => {entered = resolve;});
    const delayedRepository = new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
    const dispatch = delayedRepository.storeStock.bind(delayedRepository);
    delayedRepository.storeStock = async (...args) => {entered(); await held; return dispatch(...args);};
    const delayedService = new WorkspaceCatalogueService(delayedRepository, catalogueIdentity, () => new Date(at));
    const late = delayedService.handleStoreStock('owner-one', 'publishStoreStockSnapshot', delayedOriginal);
    let settled: any;
    try {
      await started; clock = '2026-10-16T12:05:00.000Z';
      settled = await save(delayedOriginal);
      assert.equal(settled.state, 'expired');
    } finally {release();}
    assert.deepEqual(await late, settled);
    assert.equal((await store.collection('stockSnapshots').doc('sku-one').get()).get('revision'), 4);
    assert.deepEqual(await service().handleStoreStock('owner-one', 'reconcileStoreStockSnapshot', delayedOriginal), settled);
    const racingOriginal = {...delayedOriginal, idempotencyKey: 'racing-stock-original'};
    const freshService = new WorkspaceCatalogueService(new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at)),
      catalogueIdentity, () => new Date(at));
    const outcomes = await Promise.allSettled([
      freshService.handleStoreStock('owner-one', 'publishStoreStockSnapshot', racingOriginal),
      service().handleStoreStock('owner-one', 'publishStoreStockSnapshot', racingOriginal),
    ]);
    for (const outcome of outcomes) if (outcome.status === 'rejected') throw outcome.reason;
    const wins = outcomes.map(outcome => {assert.equal(outcome.status, 'fulfilled'); return outcome.value as any;});
    assert.deepEqual(wins[0], wins[1]); assert.ok(['reported', 'expired'].includes(wins[0].state));
    console.log('LF11_STOCK_EXPIRY_PROJECTION=' + JSON.stringify({original: expiredOriginal, expired, delayed: settled, concurrent: wins[0]}));
    const finalStockRevision = wins[0].state === 'reported' ? 5 : 4;
    assert.equal((await store.collection('stockSnapshots').doc('sku-one').get()).get('revision'), finalStockRevision);
    clock = at;
    const otherRealm = new WorkspaceCatalogueService(new FirestoreWorkspaceCatalogueRepository(db, 'production', () => new Date(clock)),
      catalogueIdentity, () => new Date(clock));
    assert.equal((await otherRealm.handleStoreStock('buyer-one', 'readPublicStoreStockSnapshot', newQuery) as any).state, 'unknown');
    const stockHead = store.collection('stockSnapshots').doc('sku-one'), validHead = (await stockHead.get()).data()!;
    await stockHead.update({'source.quantityPacks': 3});
    await assert.rejects(read(newQuery));
    await stockHead.set(validHead);
    await db.collection('workspaceProfiles').doc(profile.caseId).update({ownerUserId: 'replacement-owner'});
    assert.equal((await read(newQuery)).state, 'unknown');
    const replacementRead = await service().handleStoreStock('replacement-owner', 'readStoreStockSnapshot', newScope) as any;
    assert.equal(replacementRead.state, 'source_changed'); assert.equal(replacementRead.record, null);
    await assert.rejects(service().handleStoreStock('owner-one', 'reconcileStoreStockSnapshot', original));
    await db.collection('workspaceProfiles').doc(profile.caseId).update({ownerUserId: 'owner-one'});
    await db.collection('workspaceProfiles').doc(profile.caseId).update({shopEnabled: false});
    assert.equal((await read()).state, 'unknown');
    assert.deepEqual(await service().handleStoreStock('owner-one', 'reconcileStoreStockSnapshot', original), first);
    assert.deepEqual(await save(expiredOriginal), expired);
    assert.deepEqual(await save(delayedOriginal), settled);
    const skuAfter = (await store.collection('skus').doc('sku-one').get()).data()!;
    const skuBefore = JSON.parse(beforeSku); skuBefore.revision = 2;
    assert.deepEqual(skuAfter, skuBefore); // Reporting never changes quantities/prices in the reviewed SKU mirror.
    assert.equal((await store.collection('stockSnapshots').doc('sku-one').collection('revisions').get()).size, finalStockRevision);
    assert.equal((await store.collection('stockSnapshots').doc('sku-one').collection('receipts').get()).size, 7);
  } finally {await db.terminate(); await deleteApp(app);}
});
test('LF14 rendered-product producer and owner aggregate are implemented in the existing catalogue owner', () => {
  for (const method of ['recordProductPresentation', 'readProductPresentations', 'recordStorePresentation', 'readStorePresentations',
    'recordCartAddition', 'readCartAdditions']) {
    assert.equal(typeof (WorkspaceCatalogueService.prototype as unknown as Record<string, unknown>)[method], 'function');
    assert.equal(typeof (FirestoreWorkspaceCatalogueRepository.prototype as unknown as Record<string, unknown>)[method], 'function');
  }
});
test('LF14 discovery source contract keeps the existing HTTP reporting activation default off', () => {
  const source = readFileSync(resolve(__dirname, '../../src/index.ts'), 'utf8');
  assert.match(source, /productPresentationOperation && \(body\.schemaVersion === 2 \|\| Object\.hasOwn\(body, 'discoverySourcesVersion'\)\) &&\s*process\.env\.MOOLSOCIAL_PRODUCT_DISCOVERY_SOURCES_V1 !== 'true'/u);
  assert.match(source, /process\.env\.MOOLSOCIAL_PRODUCT_PRESENTATIONS_V1 !== 'true'/u);
  // Supplements real service/emulator coverage; does not prove endpoint/auth deployment.
});

test('LF14 discovery surfaces keep legacy Unknown and immutable scoped source counts', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  // Isolated local producer fixture, not native events or live Store statistics.
  const app = initializeApp({projectId: `demo-lf-sources-${randomUUID().slice(0, 8)}`}, `sources-${randomUUID()}`), db = getFirestore(app);
  const root = db.collection('workspaceCatalogues').doc('evaluation');
  let clock = at;
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(clock));
  const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(clock));
  const range = {schemaVersion: 1, storeId: 'store-one', start: '2026-10-16T00:00:00.000Z', end: '2026-10-17T00:00:00.000Z', skuIds: []};
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant());
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const sku = input(), commands = productionCommands(sku);
    for (let index = 0; index < commands.length; index++) {
      await repository().produceCatalogue([0, 2, 4].includes(index) ? 'reviewer-one' : 'owner-one', catalogueIdentity, commands[index]!);
    }
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku, expectedRevision: 0, idempotencyKey: 'publish-source-product'});
    const page = await service().publicCatalogue({storeId: 'store-one', skuId: 'sku-one', listingReadbackVersion: 1,
      mediaReadbackVersion: 1, productFactsReadbackVersion: 1, policyReadbackVersion: 1, storeDetailsReadbackVersion: 1}) as any;
    const legacy = {schemaVersion: 1, presentationId: '1'.repeat(32), storeId: 'store-one', skuId: 'sku-one',
      listingId: page.items[0].listings[0].listingId, skuRevision: 1, catalogueVersion: 6};
    const legacyReceipt = await service().recordProductPresentation('buyer-one', legacy);
    const quick = {...legacy, schemaVersion: 2, presentationId: '2'.repeat(32), discoverySurface: 'quick'};
    const quickReceipt = await service().recordProductPresentation('buyer-one', quick);
    assert.deepEqual(await service().recordProductPresentation('buyer-one', quick), quickReceipt);
    await assert.rejects(service().recordProductPresentation('buyer-one', {...quick, discoverySurface: 'offers'}), {code: 'conflict'});
    await service().recordProductPresentation('buyer-two', {...quick, presentationId: '3'.repeat(32), discoverySurface: 'offers'});
    for (const invalid of [
      {...quick, discoverySurface: 'query=private'}, {...quick, discoverySurface: null},
      {...quick, schemaVersion: 1}, {...quick, schemaVersion: 3}, {...quick, query: 'private'},
    ]) {
      await assert.rejects(service().recordProductPresentation('buyer-one', invalid), {code: 'invalid_input'});
    }
    await assert.rejects(service().recordProductPresentation('owner-one', {...quick, presentationId: '4'.repeat(32)}));
    await assert.rejects(service().recordCartAddition('buyer-one', quick), {code: 'invalid_input'});
    clock = new Date(Date.parse(at) + 1000).toISOString();
    const requested = {...range, discoverySourcesVersion: 1};
    const aggregate = await service().readProductPresentations('owner-one', requested) as any;
    assert.equal(aggregate.count, 3);
    assert.deepEqual(aggregate.discoverySources, [
      {id: 'offers', count: 1}, {id: 'quick', count: 1}, {id: 'unknown', count: 1},
    ]);
    assert.equal(aggregate.discoverySources.reduce((sum: number, row: any) => sum + row.count, 0), aggregate.count);
    const oldRead = await service().readProductPresentations('owner-one', range) as any;
    assert.equal(oldRead.count, 3); assert.equal('discoverySources' in oldRead, false);
    const empty = await service().readProductPresentations('owner-one', {...requested, skuIds: ['another-sku']}) as any;
    assert.equal(empty.count, 0); assert.deepEqual(empty.discoverySources, []);
    await assert.rejects(service().readProductPresentations('buyer-one', requested), {code: 'not_found'});
    await assert.rejects(service().readProductPresentations('owner-one', {...requested, discoverySourcesVersion: 2}), {code: 'invalid_input'});
    await assert.rejects(service().readCartAdditions('owner-one', requested), {code: 'invalid_input'});
    await assert.rejects(service().readStorePresentations('owner-one', requested), {code: 'invalid_input'});
    assert.deepEqual(await service().recordProductPresentation('buyer-one', legacy), legacyReceipt);
    assert.equal(JSON.stringify(aggregate).includes('buyer-one'), false);
    assert.equal(JSON.stringify(aggregate).includes('buyer-two'), false);
    if (process.env.LF14_DISCOVERY_CAPTURE === 'true') {
      console.log(`LF14_DISCOVERY_PROJECTION=${JSON.stringify({legacy, legacyReceipt, quick, quickReceipt, aggregate, empty, page})}`);
    }
    for (const [index, surface] of catalogueModule.productDiscoverySurfaces.entries()) {
      const next = {...quick, presentationId: (index + 5).toString(16).repeat(32), discoverySurface: surface};
      assert.equal((await service().recordProductPresentation('buyer-one', next) as any).discoverySurface, surface);
    }
    clock = new Date(Date.parse(clock) + 1000).toISOString();
    const all = await service().readProductPresentations('owner-one', requested) as any;
    assert.equal(all.count, 10);
    assert.equal(all.discoverySources.length, catalogueModule.productDiscoverySurfaces.length);
    assert.equal(all.discoverySources.reduce((sum: number, row: any) => sum + row.count, 0), 10);
  } finally {await db.terminate(); await deleteApp(app);}
});

test('LF14 emulator reviewed public product to immutable presentation and restarted owner-only partial aggregate', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async t => {
  const app = initializeApp({projectId: `demo-lf-views-${randomUUID().slice(0, 8)}`}, `views-${randomUUID()}`), db = getFirestore(app);
  const root = db.collection('workspaceCatalogues').doc('evaluation'), store = root.collection('stores').doc('store-one');
  let clock = at;
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(clock));
  const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(clock));
  const range = {schemaVersion: 1, storeId: 'store-one', start: '2026-10-16T00:00:00.000Z', end: '2026-10-17T00:00:00.000Z', skuIds: []};
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant());
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const value = input(), commands = productionCommands(value);
    for (let index = 0; index < commands.length; index++) await repository().produceCatalogue([0, 2, 4].includes(index) ? 'reviewer-one' : 'owner-one', catalogueIdentity, commands[index]!);
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: value, expectedRevision: 0, idempotencyKey: 'publish-viewed-product'});
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: input('sku-two'), expectedRevision: 0, idempotencyKey: 'publish-alternate-viewed-product'});
    const page = await service().publicCatalogue({storeId: 'store-one', skuId: 'sku-one', listingReadbackVersion: 1,
      mediaReadbackVersion: 1, productFactsReadbackVersion: 1, policyReadbackVersion: 1, storeDetailsReadbackVersion: 1}) as any;
    const event = {schemaVersion: 1 as const, presentationId: 'a'.repeat(32), storeId: 'store-one', skuId: 'sku-one',
      listingId: page.items[0].listings[0].listingId, skuRevision: 1, catalogueVersion: 6};
    assert.equal((await service().readProductPresentations('owner-one', range) as any).state, 'unavailable');
    for (const changed of [{skuRevision: 2}, {catalogueVersion: 7}, {listingId: 'listing-' + 'b'.repeat(64)}, {skuId: 'another-sku'}, {acceptedAt: at}]) {
      await assert.rejects(service().recordProductPresentation('buyer-one', {...event, ...changed}));
    }
    await assert.rejects(service().recordProductPresentation('owner-one', event));
    assert.equal((await store.collection('productPresentations').get()).size, 0);
    const accepted = await service().recordProductPresentation('buyer-one', event);
    assert.equal((accepted as any).acceptedAt, at);
    assert.deepEqual(await service().recordProductPresentation('buyer-one', event), accepted);
    await assert.rejects(service().recordProductPresentation('buyer-one', {...event, skuRevision: 2}), {code: 'conflict'});
    assert.equal((await service().readCartAdditions('owner-one', range) as any).customers, null);
    await assert.rejects(service().recordCartAddition('owner-one', event));
    for (const change of [{skuRevision: 2}, {catalogueVersion: 7}, {listingId: 'listing-' + 'b'.repeat(64)},
      {storeId: 'other-store'}, {customerKey: 'client-chosen'}, {acceptedAt: at}, {quantity: 2}]) {
      await assert.rejects(service().recordCartAddition('buyer-one', {...event, ...change}));
    }
    await t.test('fresh simultaneous same-key additions both acknowledge the same original', async () => {
      try {
        if (process.env.LF14_CART_TRACE === 'true') setLogFunction(message => {
          const first = message.split('\n')[0]!;
          if (/transaction|error|retry/iu.test(first) && !/Sending request|Received response/u.test(first)) console.log(`LF14_CART_TX_TRACE=${first.slice(0, 500)}`);
        });
        // Settle both before continuing the independent expiry/privacy tests.
        // A failed child remains a failed suite; never convert it into a pass.
        const observe = (attempt: Promise<object>) => attempt.catch(async error => {
          if (process.env.LF14_CART_TRACE === 'true') {
            // Diagnostic read only, at failure time rather than after the sibling
            // settles. Never acknowledge, retry or weaken the original failure.
            const saved = await store.collection('cartAdditions').doc(cataloguePayloadHash(['evaluation', 'buyer-one', event.presentationId]))
              .get().catch(() => undefined);
            console.log(`LF14_CART_FAILURE=${JSON.stringify({code: error?.code, details: error?.details,
              stack: error instanceof Error ? error.stack : String(error), originalPresent: saved?.exists ?? null,
              matchingFingerprint: saved?.exists ? saved.get('fingerprint') === cataloguePayloadHash(event) : null})}`);
          }
          throw error;
        });
        const results = await Promise.allSettled([observe(service().recordCartAddition('buyer-one', event)), observe(service().recordCartAddition('buyer-one', event))]);
        for (const result of results) assert.equal(result.status, 'fulfilled', result.status === 'rejected' ? String(result.reason) : undefined);
        assert.deepEqual((results[0] as PromiseFulfilledResult<object>).value, (results[1] as PromiseFulfilledResult<object>).value);
      } finally { if (process.env.LF14_CART_TRACE === 'true') setLogFunction(null); }
    });
    // Original-key readback/replay is separate from the child concurrency result.
    const cartAccepted = await service().recordCartAddition('buyer-one', event);
    await t.test('LF14 original Cart receipt read recovers only the witnessed transport uncertainty', async t => {
      // Actual isolated producer receipt, not a native record or fabricated success.
      const originalKey = cataloguePayloadHash(['evaluation', 'buyer-one', event.presentationId]);
      const original = (await store.collection('cartAdditions').doc(originalKey).get()).data()!;
      const expectedPath = ['workspaceCatalogues', 'evaluation', 'stores', 'store-one', 'cartAdditions', originalKey];
      for (const fault of ['none', 'missing', 'corrupt schema', 'corrupt input', 'corrupt customer', 'corrupt integrity',
        'corrupt acceptedAt', 'mismatched input', 'other actor', 'other Store', 'other realm', 'read failure',
        'business error', 'other code', 'other details']) {
        await t.test(fault, async () => {
          const error = Object.assign(new Error('Host transaction read failure'), {code: 3 as string | number,
            details: 'Transaction is invalid or closed.'});
          if (fault === 'business error') error.code = 'forbidden';
          if (fault === 'other code') error.code = 14;
          if (fault === 'other details') error.details = 'Invalid request field.';
          const raw = structuredClone(original), path: string[] = [];
          if (fault === 'corrupt schema') raw.schemaVersion = 2;
          if (fault === 'corrupt input') raw.input.skuRevision++;
          if (fault === 'corrupt customer') raw.customerKey = '0'.repeat(64);
          if (fault === 'corrupt integrity') raw.integrity = '0'.repeat(64);
          if (fault === 'corrupt acceptedAt') raw.acceptedAt = 'not-a-timestamp';
          let transactions = 0, reads = 0;
          // Capture the exact path and expose only that independently persisted
          // receipt. No callback/write runs when the SDK rejects its transaction.
          const ref = {collection(name: string) {path.push(name); return this;},
            doc(name: string) {path.push(name); return this;},
            async get() {reads++;
              if (fault === 'read failure') throw new Error('Host receipt read unavailable');
              return {exists: fault !== 'missing' && JSON.stringify(path) === JSON.stringify(expectedPath), data: () => raw};
            }};
          const wrapped = new Proxy(db, {get(target, property) {
            if (property === 'runTransaction') return async () => {transactions++; throw error;};
            if (property === 'collection') return (name: string) => ref.collection(name);
            const value = Reflect.get(target, property, target); return typeof value === 'function' ? value.bind(target) : value;
          }});
          const realm = fault === 'other realm' ? 'production' : 'evaluation';
          const subject = new WorkspaceCatalogueService(new FirestoreWorkspaceCatalogueRepository(wrapped, realm,
            () => new Date('2026-10-16T12:00:02.000Z')), catalogueIdentity);
          const request = {...event, ...(fault === 'mismatched input' ? {skuRevision: 2} : {}),
            ...(fault === 'other Store' ? {storeId: 'other-store'} : {})};
          const attempt = subject.recordCartAddition(fault === 'other actor' ? 'other-buyer' : 'buyer-one', request);
          if (fault === 'none') assert.deepEqual(await attempt, cartAccepted);
          else await assert.rejects(attempt, caught => caught === error);
          assert.equal(transactions, 1); assert.equal(reads, ['business error', 'other code', 'other details'].includes(fault) ? 0 : 1);
          if (!['business error', 'other code', 'other details', 'other actor', 'other Store', 'other realm'].includes(fault)) assert.deepEqual(path, expectedPath);
        });
      }
      assert.deepEqual((await store.collection('cartAdditions').doc(originalKey).get()).data(), original);
      assert.equal((await store.collection('cartAdditions').get()).size, 1);
      assert.equal((await store.collection('cartAdditionDays').doc('2026-10-16').get()).get('count'), 1);
    });
    const secondPage = await service().publicCatalogue({storeId: 'store-one', skuId: 'sku-two', listingReadbackVersion: 1,
      mediaReadbackVersion: 1, productFactsReadbackVersion: 1, policyReadbackVersion: 1, storeDetailsReadbackVersion: 1}) as any;
    const secondAdd = {...event, presentationId: 'b'.repeat(32), skuId: 'sku-two', listingId: secondPage.items[0].listings[0].listingId};
    await service().recordCartAddition('buyer-one', secondAdd);
    await service().recordCartAddition('buyer-two', event);
    await assert.rejects(service().recordCartAddition('buyer-one', {...event, skuId: 'sku-two'}), {code: 'conflict'});
    clock = '2026-10-16T12:00:02.000Z';
    const cartAggregate = await service().readCartAdditions('owner-one', range) as any;
    assert.equal(cartAggregate.count, 3); assert.equal(cartAggregate.customers, 2);
    assert.equal(cartAggregate.coverage, 'partial'); assert.equal(cartAggregate.source, 'Reported signed-in Cart additions');
    assert.equal((await service().readCartAdditions('owner-one', {...range, skuIds: ['sku-one']}) as any).customers, 2);
    assert.equal((await service().readCartAdditions('owner-one', {...range, skuIds: ['sku-two']}) as any).customers, 1);
    const cartZero = await service().readCartAdditions('owner-one', {...range, start: '2026-10-16T12:00:00.001Z'}) as any;
    assert.equal(cartZero.count, 0); assert.equal(cartZero.customers, 0);
    await assert.rejects(service().readCartAdditions('buyer-one', range), {code: 'not_found'});
    const cartDocs = (await store.collection('cartAdditions').get()).docs;
    assert.equal(cartDocs.length, 3); assert.equal(JSON.stringify(cartDocs.map(doc => doc.data())).includes('buyer-one'), false);
    assert.equal(JSON.stringify(cartAggregate).includes('customerKey'), false);
    const savedCart = cartDocs[0]!.data(); await cartDocs[0]!.ref.update({customerKey: 'a'.repeat(64)});
    await assert.rejects(service().readCartAdditions('owner-one', range));
    await cartDocs[0]!.ref.set(savedCart);
    let cartAdmissions = 0;
    await assert.rejects(repository().recordCartAddition('buyer-one', {...event, presentationId: 'e'.repeat(32)}, catalogueIdentity, async () => {
      if (++cartAdmissions === 2) clock = '2026-10-17T00:00:00.000Z';
      return {validUntil: '2026-10-17T01:00:00.000Z'};
    }));
    assert.equal(cartAdmissions, 2); assert.equal((await store.collection('cartAdditions').get()).size, 3);
    clock = '2026-10-16T12:00:02.000Z'; cartAdmissions = 0;
    await assert.rejects(repository().recordCartAddition('buyer-one', {...event, presentationId: 'f'.repeat(32)}, catalogueIdentity, async () => {
      if (++cartAdmissions === 2) clock = '2026-10-16T13:00:00.000Z';
      return {validUntil: '2026-10-16T13:00:00.000Z'};
    }));
    assert.equal(cartAdmissions, 2); assert.equal((await store.collection('cartAdditions').get()).size, 3);
    assert.equal((await store.collection('cartAdditionDays').doc('2026-10-16').get()).get('count'), 3);
    clock = '2026-10-16T12:00:02.000Z';
    if (process.env.LF14_CART_CAPTURE === 'true') console.log(`LF14_CART_ADDITIONS_PROJECTION=${JSON.stringify({event, accepted: cartAccepted, aggregate: cartAggregate, zero: cartZero, page})}`);
    await store.collection('cartAdditionDays').doc('2026-10-16').set({schemaVersion: 1, count: 5000});
    assert.deepEqual(await service().recordCartAddition('buyer-one', event), cartAccepted);
    await assert.rejects(service().recordCartAddition('buyer-one', {...event, presentationId: 'd'.repeat(32)}));
    const aggregate = await service().readProductPresentations('owner-one', range) as any;
    assert.equal(aggregate.count, 1); assert.equal(aggregate.coverage, 'partial'); assert.equal(aggregate.coveredFrom, at);
    assert.deepEqual(aggregate.products, [{skuId: 'sku-one', label: 'Host fixture oil · 1 L', count: 1}]);
    const visit = {schemaVersion: 1 as const, presentationId: 'c'.repeat(32), storeId: 'store-one', catalogueVersion: 6, observedAt: at};
    assert.equal((await service().readStorePresentations('owner-one', range) as any).count, null);
    for (const changed of [{catalogueVersion: 7}, {observedAt: '2026-10-16T12:00:04.000Z'},
      {observedAt: '2026-10-16T11:50:00.000Z'}, {visitorKey: 'owner-supplied-identity'}, {schemaVersion: 2}]) {
      await assert.rejects(service().recordStorePresentation('buyer-one', {...visit, ...changed}));
    }
    await assert.rejects(service().recordStorePresentation('owner-one', visit));
    const visitAccepted = await service().recordStorePresentation('buyer-one', visit);
    assert.deepEqual(await service().recordStorePresentation('buyer-one', visit), visitAccepted);
    await assert.rejects(service().recordStorePresentation('buyer-one', {...visit, catalogueVersion: 7}), {code: 'conflict'});
    await service().recordStorePresentation('buyer-one', {...visit, presentationId: 'd'.repeat(32)});
    await service().recordStorePresentation('buyer-two', visit);
    clock = '2026-10-16T12:00:03.000Z';
    const visits = await service().readStorePresentations('owner-one', range) as any;
    assert.equal(visits.count, 3); assert.equal(visits.visitors, 2); assert.equal(visits.coverage, 'signed_in_partial');
    assert.equal(visits.coveredFrom, '2026-10-16T12:00:02.000Z');
    assert.equal((await service().readProductPresentations('owner-one', range) as any).count, 1);
    await assert.rejects(service().readStorePresentations('buyer-one', range), {code: 'not_found'});
    const skuVisits = await service().readStorePresentations('owner-one', {...range, skuIds: ['sku-one']}) as any;
    assert.equal(skuVisits.state, 'unavailable'); assert.equal(skuVisits.count, null); assert.equal(skuVisits.visitors, null);
    const zeroVisits = await service().readStorePresentations('owner-one', {...range, start: '2026-10-16T12:00:02.001Z'}) as any;
    assert.equal(zeroVisits.count, 0); assert.equal(zeroVisits.visitors, 0); assert.equal(zeroVisits.state, 'ready');
    const visitRows = (await store.collection('storePresentations').get()).docs;
    assert.equal(visitRows.length, 3);
    assert.equal(JSON.stringify(visitRows.map(d => d.data())).includes('buyer-one'), false);
    assert.equal(JSON.stringify(visits).includes('visitorKey'), false);
    const savedVisit = visitRows[0]!; const before = savedVisit.data();
    await savedVisit.ref.update({'input.catalogueVersion': 100});
    await assert.rejects(service().readStorePresentations('owner-one', range));
    await savedVisit.ref.set(before);
    let admissionCalls = 0;
    const visitsBeforeExpiry = (await store.collection('storePresentations').get()).size;
    await assert.rejects(repository().recordStorePresentation('buyer-one', {...visit, presentationId: 'f'.repeat(32),
      observedAt: '2026-10-16T11:55:03.001Z'}, catalogueIdentity, async () => {
        if (++admissionCalls === 2) clock = '2026-10-16T12:00:03.002Z';
        return true;
      }));
    assert.equal(admissionCalls, 2);
    assert.equal((await store.collection('storePresentations').get()).size, visitsBeforeExpiry);
    assert.equal((await store.collection('storePresentationDays').doc('2026-10-16').get()).get('count'), 3);
    clock = '2026-10-16T12:00:03.000Z';
    await store.collection('storePresentationDays').doc('2026-10-16').set({schemaVersion: 1, count: 5000});
    assert.deepEqual(await service().recordStorePresentation('buyer-one', visit), visitAccepted);
    await assert.rejects(service().recordStorePresentation('buyer-one', {...visit, presentationId: 'e'.repeat(32)}));
    const storePage = await service().publicCatalogue({storeId: 'store-one', cataloguePageVersion: 2, pageSize: 40,
      query: viewQuery, productFactsReadbackVersion: 1, storeDetailsReadbackVersion: 1});
    console.log(`LF14_STORE_VISITS_PROJECTION=${JSON.stringify({event: visit, accepted: visitAccepted, aggregate: visits, zero: zeroVisits, sku: skuVisits, page: storePage})}`);
    await assert.rejects(service().readProductPresentations('buyer-one', range), {code: 'not_found'});
    assert.equal((await service().readProductPresentations('owner-one', {...range, skuIds: ['another-sku']}) as any).count, 0);
    assert.equal((await service().readProductPresentations('owner-one', {...range, start: '2026-10-15T00:00:00.000Z', end: '2026-10-16T00:00:00.000Z'}) as any).count, null);
    await assert.rejects(service().readProductPresentations('owner-one', {...range, start: '2026-01-01T00:00:00.000Z'}));
    const stored = (await store.collection('productPresentations').get()).docs;
    assert.equal(stored.length, 1); assert.equal(JSON.stringify(stored.map(d => d.data())).includes('buyer-one'), false);
    assert.equal(JSON.stringify(aggregate).includes('buyer-one'), false);
    if (process.env.LF14_PRESENTATION_CAPTURE === 'true') console.log(`LF14_PRESENTATION_PROJECTION=${JSON.stringify({event, accepted, aggregate: await service().readProductPresentations('owner-one', range), page,
      precisionAggregate: await service().readProductPresentations('owner-one', {...range, start: '2026-10-16T00:00:00.001Z'}),
      alternatePage: await service().publicCatalogue({storeId: 'store-one', skuId: 'sku-two', listingReadbackVersion: 1,
        mediaReadbackVersion: 1, productFactsReadbackVersion: 1, policyReadbackVersion: 1, storeDetailsReadbackVersion: 1})})}`);
    await store.collection('productPresentationDays').doc('2026-10-16').set({schemaVersion: 1, count: 5000}); // Explicit isolated host capacity fixture.
    assert.deepEqual(await service().recordProductPresentation('buyer-one', event), accepted);
    await assert.rejects(service().recordProductPresentation('buyer-one', {...event, presentationId: 'b'.repeat(32)}), {code: 'service_unavailable'});
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: {...value, publicListing: false}, expectedRevision: 1, idempotencyKey: 'withdraw-viewed-product'});
    assert.deepEqual(await service().recordCartAddition('buyer-one', event), cartAccepted);
    await assert.rejects(service().recordCartAddition('other-buyer', event));
    assert.deepEqual(await service().recordProductPresentation('buyer-one', event), accepted);
    await assert.rejects(service().recordProductPresentation('other-buyer', event));
    assert.equal((await store.collection('productPresentations').get()).size, 1);
    assert.equal((await service().readProductPresentations('owner-one', range) as any).count, 1);
  } finally {await db.terminate(); await deleteApp(app);}
});
test('LF14 actual reviewed enriched brandless Store accepts visits without legacy projection rejection', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  const app = initializeApp({projectId: `demo-lf-visit-facts-${randomUUID().slice(0, 8)}`}, `visits-${randomUUID()}`), db = getFirestore(app);
  const root = db.collection('workspaceCatalogues').doc('evaluation');
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
  const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant('store-one', 'fruits-vegetables'));
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const value = input();
    value.content = {...value.content, title: 'Cucumber', brand: '', variant: '', categoryId: 'fruits-vegetables'};
    value.pack = {...value.pack, label: '1 kg', unit: 'kg'};
    Object.assign(value.content, {productFacts: descriptiveFacts()}); // Isolated authored optional facts, not a safety claim.
    const commands = productionCommands(value); commands[1]!.brandId = null;
    for (const [i, command] of commands.entries()) await repository().produceCatalogue([0, 2, 4].includes(i) ? 'reviewer-one' : 'owner-one', catalogueIdentity, command);
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: value, expectedRevision: 0, idempotencyKey: 'publish-produce-visit'});
    const page = await service().publicCatalogue({storeId: 'store-one', productFactsReadbackVersion: 1, unbrandedProduceReadbackVersion: 1}) as any;
    assert.equal(page.items[0].content.brand, '');
    assert.equal(page.items[0].content.productFacts.compliance.manufacturerName, 'Host maker');
    const visit = {schemaVersion: 1, presentationId: '1'.repeat(32), storeId: 'store-one', catalogueVersion: page.catalogueVersion, observedAt: at};
    assert.equal((await service().recordStorePresentation('buyer-produce', visit) as any).state, 'recorded');
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: {...value, publicListing: false}, expectedRevision: 1, idempotencyKey: 'hide-produce-visit'});
    await db.collection('workspaceProfiles').doc(profile.caseId).update({shopEnabled: false});
    await assert.rejects(service().recordStorePresentation('buyer-produce', {...visit, presentationId: '2'.repeat(32)}));
    assert.equal((await root.collection('stores').doc('store-one').collection('storePresentations').get()).size, 1);
  } finally {await db.terminate(); await deleteApp(app);}
});

test('LF03-PUBLISHED processed assets have authorized byte review and guarded public delivery entries', () => {
  assert.equal(typeof (FirestoreWorkspaceCatalogueRepository.prototype as unknown as Record<string, unknown>).readProductMediaForReview, 'function');
  assert.equal(typeof (WorkspaceCatalogueService.prototype as unknown as Record<string, unknown>).publicProductMedia, 'function');
});
test('LF03-PUBLISHED stable image paths are scoped, canonical and attached only to Workspace HTTP owner', () => {
  const assetId = 'A'.repeat(64), path = publicProductMediaPath('evaluation', 'store-one', 'sku-one', assetId);
  assert.deepEqual(parsePublicProductMediaPath(path), {realm: 'evaluation', storeId: 'store-one', skuId: 'sku-one', assetId});
  for (const bad of [path + '?token=private', path + '/extra', path.replace('store-one', '..'), path.replace(assetId, assetId.toLowerCase()),
    path.replace('store-one', '%73tore-one'), '/private/product-media/original', ['/public-product-media']]) {
    assert.equal(parsePublicProductMediaPath(bad), undefined);
  }
  // Static placement regression supplements the actual byte-service tests below.
  const index = readFileSync(`${__dirname}/../../src/index.ts`, 'utf8'), start = index.indexOf('export const moolSocialWorkspace = onRequest(');
  assert.ok(start > 0);
  const positions = [...index.matchAll(/parsePublicProductMediaPath\(request\.path\)/gu)].map(match => match.index);
  assert.equal(positions.length, 1); assert.ok(positions[0]! > start);
  const route = index.slice(start, index.indexOf('function workspaceProfileService', start));
  assert.ok(route.includes('response.status(200).send(bytes)'));
  assert.ok(route.includes('"cache-control", "no-store"'));
});
test('LF03-PUBLISHED response slots bound work across instances, slow consumers, failure and disconnect', async () => {
  class HostResponse extends EventEmitter {
    destroyed = false; writableFinished = false;
    finish() {this.writableFinished = true; this.emit('finish');}
    disconnect() {this.destroyed = true; this.emit('close');}
  }
  const response = () => new HostResponse(), run = (r: HostResponse, work: () => Promise<Buffer>, send: (b: Buffer) => void = () => r.finish()) =>
    deliverPublicProductMediaResponse(r as unknown as Parameters<typeof deliverPublicProductMediaResponse>[0], work, send);
  let resolveFirst!: (b: Buffer) => void, resolveSecond!: (b: Buffer) => void, resolveThird!: (b: Buffer) => void, byteReads = 0, sends = 0;
  const first = response(), second = response(), third = response();
  const one = run(first, () => {byteReads++; return new Promise(resolve => {resolveFirst = resolve;});}, () => {sends++;});
  const two = run(second, () => {byteReads++; return new Promise(resolve => {resolveSecond = resolve;});}, () => {sends++;});
  await assert.rejects(run(response(), async () => {byteReads++; return Buffer.from('blocked');}), {code: 'service_unavailable'});
  assert.equal(byteReads, 2);
  resolveFirst(Buffer.from('private-approved-one')); await one;
  await assert.rejects(run(response(), async () => Buffer.alloc(1)), {code: 'service_unavailable'}); // Slow consumer still owns the first buffer.
  first.finish();
  await assert.rejects(run(response(), async () => {throw Error('object failure');}), /object failure/u);
  const three = run(third, () => new Promise(resolve => {resolveThird = resolve;}));
  second.disconnect();
  await assert.rejects(run(response(), async () => Buffer.alloc(1)), {code: 'service_unavailable'}); // Work is still outstanding after disconnect.
  resolveSecond(Buffer.from('not-sent-to-disconnected-client')); await two; assert.equal(sends, 1);
  await run(response(), async () => Buffer.from('freed-slot'));
  resolveThird(Buffer.from('approved-three')); await three;
  await run(response(), async () => Buffer.from('all-slots-released'));
  assert.equal(first.listenerCount('finish'), 0); assert.equal(second.listenerCount('close'), 0);
});
test('LF03-PUBLISHED emulator actual processed image to independent content review, explicit adoption and guarded bytes', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-media-public-${randomUUID().slice(0, 8)}`}, `media-public-${randomUUID()}`);
  const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation'), store = root.collection('stores').doc('store-one');
  const originals = new Map<string, Buffer>(), derivatives = new Map<string, Buffer>();
  let duringRead: (() => Promise<void>) | undefined, clock = at;
  const objects: StoreProductMediaObjects = {
    async prepare() {return {uploadUrl: 'https://host-private.invalid/write-only', requiredHeaders: {}};},
    async read(upload) {return {bytes: Buffer.from(originals.get(upload.uploadId)!), generation: '17'};},
    async save(upload, generation, image) {
      const assetId = cataloguePayloadHash({uploadId: upload.uploadId, generation, sha256: image.file.sha256});
      derivatives.set(assetId, Buffer.from(image.bytes)); return {assetId, generation: '23'};
    },
    async readDerivative(upload) {
      const bytes = Buffer.from(derivatives.get(upload.processed!.assetId)!);
      if (duringRead) {const action = duringRead; duringRead = undefined; await action();}
      return bytes;
    },
  };
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(clock), objects);
  const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(clock));
  const publicBytes = (assetId: string) => service().publicProductMedia({realm: 'evaluation', storeId: 'store-one', skuId: 'sku-one', assetId});
  async function upload(product: StoreProductSubmissionInput, bytes: Buffer, expectedRevision: number) {
    product.mediaIntent = {pendingUpload: true, pendingSelectionSha256: cataloguePayloadHash({privateSha256: cataloguePayloadHashBytes(bytes).toLowerCase(), skuId: product.skuId}), publishedReferences: []};
    const record = await repository().submitProduct(productCommand({product, expectedRevision, idempotencyKey: `image-product-${expectedRevision}`}));
    const request: StoreProductMediaRequest = {storeId: 'store-one', skuId: product.skuId, submissionRevision: record.revision,
      submissionFingerprint: record.fingerprint, sourceSha256: cataloguePayloadHashBytes(bytes).toLowerCase(), sourceByteLength: bytes.length,
      sourceMimeType: 'image/png', idempotencyKey: `image-upload-${expectedRevision}`};
    const prepared = await repository().productMedia('owner-one', 'prepare', request) as {uploadId: string};
    originals.set(prepared.uploadId, bytes);
    await repository().productMedia('owner-one', 'confirm', request);
    const stored = (await store.collection('productMediaUploads').doc(prepared.uploadId).get()).data() as StoreProductMediaUpload;
    const source: CatalogueSubmissionReference = {realm: 'evaluation', storeId: 'store-one', skuId: product.skuId,
      revision: record.revision, fingerprint: record.fingerprint, media: storeProductMediaProof(stored, at)};
    const {sha256: _, ...file} = source.media!.file;
    const value: StoreSkuInput = {...input(), content: {...product.content, media: [{id: source.media!.assetId, revision: `m1-${source.media!.assetId}`,
      url: 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace' + publicProductMediaPath('evaluation', source.storeId, source.skuId, source.media!.assetId),
      storeId: source.storeId, skuId: source.skuId, canonicalProductId: 'canonical-one', publisherWorkspaceId: source.storeId, file} ]}, provenance: product.provenance};
    return {record, source, value, processed: derivatives.get(source.media!.assetId)!};
  }
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant());
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const pixels = await sharp({create: {width: 640, height: 520, channels: 3, background: '#277250'}}).png().toBuffer();
    const first = await upload(submittedProduct(), pixels, 0), asset = first.source.media!.assetId;
    await assert.rejects(publicBytes(asset));
    assert.equal((await store.collection('skus').get()).size, 0);
    const preview = await repository().readProductMediaForReview('reviewer-one', catalogueIdentity, first.source);
    assert.deepEqual(preview.bytes, first.processed); assert.deepEqual(preview.proof, first.source.media);
    const inspection = () => service().handleCatalogueProduction('reviewer-one', 'readCatalogueSourceMedia', {source: first.source}) as
      Promise<{state: string; source: CatalogueSubmissionReference; file: {base64: string; sha256: string; byteLength: number}}>;
    const inspected = await inspection();
    assert.equal(inspected.state, 'private_review_media'); assert.deepEqual(inspected.source, first.source);
    assert.deepEqual(Buffer.from(inspected.file.base64, 'base64'), first.processed);
    assert.equal(inspected.file.sha256, first.source.media!.file.sha256);
    assert.equal(inspected.file.byteLength, first.processed.length);
    await assert.rejects(service().handleCatalogueProduction('owner-one', 'readCatalogueSourceMedia', {source: first.source}), {code: 'forbidden'});
    await assert.rejects(repository().readProductMediaForReview('owner-one', catalogueIdentity, first.source), {code: 'forbidden'});
    await assert.rejects(repository().readProductMediaForReview('reviewer-one', {...catalogueIdentity, tenantId: 'other-tenant'}, first.source), {code: 'forbidden'});
    for (const corrupt of [ {...first.source, realm: 'production' as const}, {...first.source, storeId: 'other-store'},
      {...first.source, media: {...first.source.media!, derivativeGeneration: '99'}},
      {...first.source, media: {...first.source.media!, source: {...first.source.media!.source, width: 128}}}]) {
      await assert.rejects(repository().readProductMediaForReview('reviewer-one', catalogueIdentity, corrupt));
    }
    duringRead = async () => {await root.collection('producerAuthorities').doc('reviewer-one').update({enabled: false});};
    await assert.rejects(inspection(), {code: 'forbidden'});
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    derivatives.set(asset, Buffer.from(first.processed).fill(0));
    await assert.rejects(inspection(), {code: 'invalid_image'});
    derivatives.set(asset, first.processed);
    const commands = productionCommands(first.value), {contentSha256: _, categoryId: __, ...proposal} = commands[1]!,
      {descriptorSha256: ___, ...packProposal} = commands[3]!;
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[0]!);
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, {...first.source, media: undefined} as unknown as CatalogueSubmissionReference, proposal));
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, first.source, proposal);
    await assert.rejects(publicBytes(asset));
    const resolution = {source: first.source, expectedReviewRevision: 0, idempotencyKey: 'resolve-image', canonicalProductId: 'canonical-one',
      verifiedPackId: 'pack-one', offers: [{kind: 'retail', offerId: 'offer-one'}]};
    await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution));
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[2]!);
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, first.source, packProposal);
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[4]!);
    await repository().produceCatalogue('owner-one', catalogueIdentity, commands[5]!);
    await assert.rejects(repository().resolveProductReview('owner-one', catalogueIdentity, resolution), {code: 'forbidden'});
    const candidate = await repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution);
    assert.equal(candidate.schemaVersion, 2); assert.deepEqual(candidate.sku, first.value);
    const read = {productSubmissionVersion: 1, productReviewVersion: 1, storeId: 'store-one', skuId: 'sku-one'};
    assert.equal(((await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', read)) as any).review.state, 'awaiting_media');
    const ready = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', {...read, productMediaReviewVersion: 1}) as any;
    assert.equal(ready.review.state, 'ready'); assert.deepEqual(ready.review.candidate, candidate);
    await assert.rejects(publicBytes(asset));
    const binding = {storeId: 'store-one', sku: candidate.sku, expectedRevision: 0, idempotencyKey: 'adopt-image',
      reviewCandidate: {revision: candidate.revision, fingerprint: candidate.fingerprint}};
    const adopted = await service().bindReviewedSku('owner-one', binding) as any;
    assert.equal(adopted.saved.revision, 1); assert.equal(adopted.publicationConfirmed, false);
    assert.deepEqual(await publicBytes(asset), first.processed);
    assert.equal((await sharp(await publicBytes(asset)).metadata()).width, 640);
    assert.deepEqual(await service().reconcileBinding('owner-one', binding), adopted);
    if (process.env.LF03_PUBLISHED_MEDIA_CAPTURE === 'true') {
      console.log(`LF03_PUBLISHED_MEDIA_PROJECTION=${JSON.stringify({ready, source: first.record, request: binding, response: adopted,
        publicPage: await service().publicCatalogue({storeId: 'store-one', skuId: 'sku-one', listingReadbackVersion: 1, productFactsReadbackVersion: 1,
          mediaReadbackVersion: 1, policyReadbackVersion: 1, storeDetailsReadbackVersion: 1}), bytesBase64: first.processed.toString('base64')})}`);
    }
    const replacementBytes = await sharp({create: {width: 640, height: 520, channels: 3, background: '#793440'}}).png().toBuffer();
    const next = await upload(submittedProduct(), replacementBytes, 1), nextAsset = next.source.media!.assetId;
    assert.notEqual(nextAsset, asset); assert.deepEqual(await publicBytes(asset), first.processed); await assert.rejects(publicBytes(nextAsset));
    const previousHash = cataloguePayloadHash(first.value.content), nextHash = cataloguePayloadHash(next.value.content);
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, next.source,
      {type: 'propose_product_revision', commandId: 'replace-image-propose', expectedVersion: 6, productId: 'canonical-one', previousContentSha256: previousHash});
    await repository().produceCatalogue('reviewer-one', catalogueIdentity,
      {type: 'review_product_revision', commandId: 'replace-image-reject', expectedVersion: 7, productId: 'canonical-one', revision: 2,
        previousContentSha256: previousHash, contentSha256: nextHash, decision: 'reject', reasonCode: 'wrong-image'});
    await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity, {...resolution, source: next.source, expectedReviewRevision: 1, idempotencyKey: 'reject-image'}));
    assert.deepEqual(await publicBytes(asset), first.processed); await assert.rejects(publicBytes(nextAsset));
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, next.source,
      {type: 'propose_product_revision', commandId: 'replace-image-repropose', expectedVersion: 8, productId: 'canonical-one', previousContentSha256: previousHash});
    await repository().readProductMediaForReview('reviewer-one', catalogueIdentity, next.source);
    await repository().produceCatalogue('reviewer-one', catalogueIdentity,
      {type: 'review_product_revision', commandId: 'replace-image-approve', expectedVersion: 9, productId: 'canonical-one', revision: 3,
        previousContentSha256: previousHash, contentSha256: nextHash, decision: 'verify', reasonCode: 'checked-exact-source'});
    const candidate2 = await repository().resolveProductReview('reviewer-one', catalogueIdentity, {...resolution, source: next.source, expectedReviewRevision: 1, idempotencyKey: 'resolve-replacement'});
    await service().bindReviewedSku('owner-one', {...binding, sku: candidate2.sku, expectedRevision: 1, idempotencyKey: 'adopt-replacement',
      reviewCandidate: {revision: candidate2.revision, fingerprint: candidate2.fingerprint}});
    assert.deepEqual(await publicBytes(nextAsset), next.processed); await assert.rejects(publicBytes(asset));
    derivatives.set(nextAsset, Buffer.alloc(next.processed.length)); await assert.rejects(publicBytes(nextAsset), {code: 'invalid_image'});
    derivatives.set(nextAsset, next.processed);
    duringRead = async () => {await service().bindReviewedSku('owner-one', {storeId: 'store-one', sku: {...candidate2.sku, publicListing: false}, expectedRevision: 2, idempotencyKey: 'withdraw-image'});};
    await assert.rejects(publicBytes(nextAsset));
    assert.equal((await store.collection('skus').doc('sku-one').get()).get('revision'), 3);
    assert.deepEqual(await service().reconcileBinding('owner-one', binding), adopted); // Original acknowledgement is not renewed publication.
    await assert.rejects(publicBytes(nextAsset));
    assert.equal((await store.collection('skus').get()).size, 1); assert.equal((await store.collection('productMediaAssets').get()).size, 2);
    // Removing a photo is another source-bound review/adoption, never reuse of its old proof.
    const removedProduct = submittedProduct();
    const removedRecord = await repository().submitProduct(productCommand({product: removedProduct, expectedRevision: 2, idempotencyKey: 'remove-image-product'}));
    const removedSource = {realm: 'evaluation' as const, storeId: 'store-one', skuId: 'sku-one', revision: removedRecord.revision, fingerprint: removedRecord.fingerprint};
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, removedSource,
      {type: 'propose_product_revision', commandId: 'remove-image-propose', expectedVersion: 10, productId: 'canonical-one', previousContentSha256: nextHash});
    await repository().produceCatalogue('reviewer-one', catalogueIdentity,
      {type: 'review_product_revision', commandId: 'remove-image-approve', expectedVersion: 11, productId: 'canonical-one', revision: 4,
        previousContentSha256: nextHash, contentSha256: cataloguePayloadHash({...removedProduct.content, media: []}), decision: 'verify', reasonCode: 'checked-photo-removal'});
    const removedCandidate = await repository().resolveProductReview('reviewer-one', catalogueIdentity,
      {...resolution, source: removedSource, expectedReviewRevision: 2, idempotencyKey: 'resolve-image-removal'});
    assert.equal(removedCandidate.schemaVersion, 1); assert.equal(removedCandidate.source.media, undefined);
    const removedReady = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', {...read, productMediaReviewVersion: 1});
    const removedBinding = {...binding, sku: removedCandidate.sku, expectedRevision: 3, idempotencyKey: 'adopt-image-removal',
      reviewCandidate: {revision: removedCandidate.revision, fingerprint: removedCandidate.fingerprint}};
    const removedResponse = await service().bindReviewedSku('owner-one', removedBinding);
    assert.deepEqual((await store.collection('skus').doc('sku-one').get()).get('content.media'), []);
    await assert.rejects(publicBytes(asset)); await assert.rejects(publicBytes(nextAsset));
    if (process.env.LF03_PUBLISHED_MEDIA_CAPTURE === 'true') console.log(`LF03_REMOVED_MEDIA_PROJECTION=${JSON.stringify({ready: removedReady, source: removedRecord, response: removedResponse})}`);
    clock = '2026-10-16T13:00:00.000Z'; await assert.rejects(publicBytes(nextAsset));
  } finally {await db.terminate(); await deleteApp(app);}
});
// Actual byte fixtures, isolated from device data and production media.
type DecodedProductImage = {bytes: Buffer; source: {sha256: string; byteLength: number;
  width: number; height: number; mimeType: string}; file: {sha256: string; byteLength: number;
  width: number; height: number; mimeType: string; normalized: boolean; frameCount: number};
  meetsPublicSourceFloor: boolean};
const decodeProductImage = (bytes: Buffer): Promise<DecodedProductImage> => {
  const decode = (catalogueModule as unknown as Record<string, unknown>).normalizeStoreProductImage;
  assert.equal(typeof decode, "function", "A full image decoder is required, not metadata claims");
  return (decode as (bytes: Buffer) => Promise<DecodedProductImage>)(bytes);
};
for (const format of ["png", "jpeg", "webp"] as const) {
  test(`LF03-MEDIA actual ${format} pixels decode to measured private PNG`, async () => {
    const bytes = await sharp({create: {width: 640, height: 520, channels: 3,
      background: "#247a62"}})[format]().toBuffer();
    const result = await decodeProductImage(bytes);
    assert.equal(result.source.byteLength, bytes.length);
    assert.equal(result.source.mimeType, `image/${format}`);
    assert.equal(result.source.sha256, cataloguePayloadHashBytes(bytes));
    assert.equal(result.file.sha256, cataloguePayloadHashBytes(result.bytes));
    assert.equal(result.file.byteLength, result.bytes.length);
    assert.deepEqual([result.file.width, result.file.height, result.file.frameCount], [640, 520, 1]);
    assert.equal(result.file.mimeType, "image/png");
    assert.equal(result.file.normalized, true);
    assert.equal(result.meetsPublicSourceFloor, true);
    const output = await sharp(result.bytes).metadata();
    assert.equal(output.format, "png");
    assert.equal(output.exif, undefined);
    assert.equal(output.icc, undefined);
    assert.equal(output.xmp, undefined);
  });
}
function cataloguePayloadHashBytes(bytes: Buffer): string {
  return createHash("sha256").update(bytes).digest("hex").toUpperCase();
}
test("LF03-MEDIA strips metadata and applies actual EXIF orientation", async () => {
  const bytes = await sharp({create: {width: 600, height: 520, channels: 3, background: "#3178aa"}})
    .withMetadata({orientation: 6}).withXmp('<x:xmpmeta xmlns:x="adobe:ns:meta/">private-camera-location</x:xmpmeta>')
    .jpeg().toBuffer();
  assert.ok((await sharp(bytes).metadata()).exif);
  const result = await decodeProductImage(bytes), metadata = await sharp(result.bytes).metadata();
  assert.deepEqual([result.file.width, result.file.height], [520, 600]);
  assert.equal(metadata.exif, undefined);
  assert.equal(metadata.xmp, undefined);
  assert.equal(metadata.icc, undefined);
  assert.equal(metadata.orientation, undefined);
  assert.equal(result.bytes.includes(Buffer.from("private-camera-location")), false);
});
test("LF03-MEDIA never fabricates the public floor by upscaling private saved photos", async () => {
  const small = await sharp({create: {width: 128, height: 256, channels: 4, background: "#206070"}}).png().toBuffer();
  const decoded = await decodeProductImage(small);
  assert.deepEqual([decoded.file.width, decoded.file.height], [128, 256]);
  assert.equal(decoded.meetsPublicSourceFloor, false);
  const large = await sharp({create: {width: 2048, height: 1024, channels: 3, background: "#a07050"}}).png().toBuffer();
  const bounded = await decodeProductImage(large);
  assert.deepEqual([bounded.file.width, bounded.file.height], [1024, 512]);
  assert.deepEqual([bounded.source.width, bounded.source.height], [2048, 1024]);
});
test("LF03-MEDIA reports the exact 512-pixel source floor without approval or enlargement", async () => {
  for (const side of [511, 512]) {
    const bytes = await sharp({create: {width: side, height: 512, channels: 3, background: "#204030"}}).png().toBuffer();
    const decoded = await decodeProductImage(bytes);
    assert.deepEqual([decoded.file.width, decoded.file.height], [side, 512]);
    assert.equal(decoded.meetsPublicSourceFloor, side === 512);
    assert.equal(Object.hasOwn(decoded, "approved"), false);
  }
});
test("LF03-MEDIA captures input before awaits and returns independent bytes", async () => {
  const original = await sharp({create: {width: 520, height: 520, channels: 3, background: "#283450"}}).png().toBuffer();
  const untouched = Buffer.from(original), pending = decodeProductImage(original);
  original.fill(0);
  const decoded = await pending;
  assert.equal(decoded.source.sha256, cataloguePayloadHashBytes(untouched));
  const again = await decodeProductImage(untouched);
  assert.deepEqual(decoded.bytes, again.bytes);
  decoded.bytes.fill(0);
  assert.notDeepEqual(decoded.bytes, again.bytes);
});
test("LF03-MEDIA rejects corrupt, header-only, truncated and unsupported input", async () => {
  const valid = await sharp({create: {width: 520, height: 520, channels: 3, background: "#316249"}}).png().toBuffer();
  for (const bytes of [Buffer.alloc(0), Buffer.from("not-image"), valid.subarray(0, 24),
    valid.subarray(0, valid.length - 20), Buffer.from('<svg width="600" height="600"></svg>'),
    await sharp({create: {width: 520, height: 520, channels: 3, background: "red"}}).gif().toBuffer(),
    Buffer.alloc(8 * 1024 * 1024 + 1)]) {
    await assert.rejects(decodeProductImage(bytes), (error: unknown) =>
      (error as {code?: string}).code === "invalid_image");
  }
});
test("LF03-MEDIA rejects excessive decoded pixels and animation rather than taking frame one", async () => {
  const bomb = await sharp({create: {width: 5000, height: 4000, channels: 3, background: "white"}}).png().toBuffer();
  await assert.rejects(decodeProductImage(bomb), (e: unknown) => (e as {code?: string}).code === "invalid_image");
  const frames = Buffer.alloc(128 * 256 * 4);
  for (let p = 0; p < frames.length; p += 4) {
    frames[p] = p < 128 * 128 * 4 ? 255 : 0;
    frames[p + 2] = p < 128 * 128 * 4 ? 0 : 255;
    frames[p + 3] = 255;
  }
  const animated = await sharp(frames, {raw: {width: 128, height: 256, pageHeight: 128,
    channels: 4}}).webp({loop: 0, delay: [50, 50]}).toBuffer();
  assert.equal((await sharp(animated).metadata()).pages, 2);
  await assert.rejects(decodeProductImage(animated), (e: unknown) => (e as {code?: string}).code === "invalid_image");
});
test("LF03-MEDIA rejects real APNG frame controls, including loaders exposing only a default frame", async () => {
  const pngChunk = (kind: string, data: Buffer) => {
    const payload = Buffer.concat([Buffer.from(kind), data]), result = Buffer.alloc(data.length + 12);
    result.writeUInt32BE(data.length, 0); payload.copy(result, 4);
    let crc = 0xffffffff;
    for (const byte of payload) {crc ^= byte; for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);}
    result.writeUInt32BE((crc ^ 0xffffffff) >>> 0, result.length - 4); return result;
  };
  const frames = await Promise.all(["red", "blue"].map(background => sharp({create: {width: 520, height: 520,
    channels: 4, background}}).png().toBuffer()));
  const chunks = (bytes: Buffer) => {
    const parts: Array<{kind: string; data: Buffer}> = [];
    for (let p = 8; p < bytes.length;) {
      const length = bytes.readUInt32BE(p); parts.push({kind: bytes.toString("ascii", p + 4, p + 8), data: bytes.subarray(p + 8, p + 8 + length)}); p += length + 12;
    }
    return parts;
  };
  const first = chunks(frames[0]!), second = chunks(frames[1]!);
  const control = Buffer.alloc(8); control.writeUInt32BE(2, 0);
  const frameControl = (sequence: number) => {
    const value = Buffer.alloc(26); value.writeUInt32BE(sequence, 0); value.writeUInt32BE(520, 4); value.writeUInt32BE(520, 8);
    value.writeUInt16BE(5, 20); value.writeUInt16BE(100, 22); return pngChunk("fcTL", value);
  };
  const pixels1 = Buffer.concat(first.filter(p => p.kind === "IDAT").map(p => p.data));
  const pixels2 = Buffer.concat(second.filter(p => p.kind === "IDAT").map(p => p.data));
  const sequence = Buffer.alloc(4); sequence.writeUInt32BE(2);
  const apng = Buffer.concat([frames[0]!.subarray(0, 8), pngChunk("IHDR", first[0]!.data), pngChunk("acTL", control),
    frameControl(0), pngChunk("IDAT", pixels1), frameControl(1), pngChunk("fdAT", Buffer.concat([sequence, pixels2])), pngChunk("IEND", Buffer.alloc(0))]);
  // libvips may decode only the PNG default frame; our container fence must still reject the animation.
  assert.equal((await sharp(apng).metadata()).width, 520);
  await assert.rejects(decodeProductImage(apng), {code: "invalid_image"});
});
test("LF03-MEDIA bounded work rejects excess requests and releases capacity after failure", async () => {
  const bytes = await sharp({create: {width: 1024, height: 1024, channels: 3, background: "white"}}).png().toBuffer();
  const requests = Array.from({length: 5}, () => decodeProductImage(bytes));
  const results = await Promise.allSettled(requests);
  assert.equal(results.filter(x => x.status === "fulfilled").length, 2);
  for (const result of results.filter(x => x.status === "rejected")) {
    assert.equal(result.reason.code, "service_unavailable");
    assert.equal(result.reason.retryable, true);
  }
  await assert.rejects(decodeProductImage(Buffer.from("invalid")));
  assert.equal((await decodeProductImage(bytes)).file.width, 1024);
});
test("LF03-MEDIA emulator persists source-bound processing, original recovery and private isolation", {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-media-${randomUUID().slice(0, 8)}`}, `media-${randomUUID()}`);
  const db = getFirestore(app), bytes = await sharp({create: {width: 640, height: 520, channels: 3, background: "#307554"}}).png().toBuffer();
  const originals = new Map<string, Buffer>(), derivatives = new Map<string, Buffer>();
  let failAfterWrite = false, duringSave: (() => Promise<void>) | undefined, reads = 0, grants = 0;
  // Labelled host object-storage double. Firestore is real local emulator; GCS is tested separately below.
  const objects: StoreProductMediaObjects = {
    async prepare(upload) {grants++; return {uploadUrl: `https://host-storage.invalid/${upload.uploadId}`, requiredHeaders: {"x-goog-if-generation-match": "0"}};},
    async read(upload) {reads++; const original = originals.get(upload.uploadId); if (!original) throw Error("host upload missing");
      return {bytes: Buffer.from(original), generation: "17"};},
    async save(upload, generation, image) {
      const assetId = cataloguePayloadHash({uploadId: upload.uploadId, generation, sha256: image.file.sha256});
      const previous = derivatives.get(assetId); if (previous) assert.deepEqual(previous, image.bytes);
      else derivatives.set(assetId, Buffer.from(image.bytes));
      if (duringSave) {const action = duringSave; duringSave = undefined; await action();}
      if (failAfterWrite) {failAfterWrite = false; throw Error("host crash after durable derivative");}
      return {assetId, generation: "23"};
    },
  };
  let clock = at;
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, "evaluation", () => new Date(clock), objects);
  const service = () => new WorkspaceCatalogueService(repository(), undefined, () => new Date(clock));
  type MediaResult = {state: string; uploadId: string; uploadUrl?: string; current: boolean; approved: boolean;
    publicationConfirmed: boolean; processed: StoreProductMediaUpload["processed"]};
  const call = async (operation: string, body: StoreProductMediaRequest, owner = "owner-one") =>
    await service().handleProductMedia(owner, operation, {productMediaVersion: 1, ...body}) as MediaResult;
  const prepare = (body: StoreProductMediaRequest) => call("prepareStoreProductMedia", body);
  const confirm = (body: StoreProductMediaRequest) => call("confirmStoreProductMedia", body);
  const read = (body: StoreProductMediaRequest) => call("readStoreProductMedia", body);
  try {
    await db.collection("workspaceProfiles").doc(profile.caseId).set(profile);
    const product = submittedProduct();
    // Same lowercase digest text used by actual saved private photos; do not rewrite the old submission hash.
    product.mediaIntent = {pendingUpload: true, pendingSelectionSha256: cataloguePayloadHash({privateSha256: cataloguePayloadHashBytes(bytes).toLowerCase(), skuId: product.skuId}), publishedReferences: []};
    const submission = await repository().submitProduct(storeProductSubmission("owner-one", "evaluation",
      {storeId: "store-one", expectedRevision: 0, idempotencyKey: "host-media-product", product}, at));
    const request: StoreProductMediaRequest = {storeId: "store-one", skuId: "sku-one", submissionRevision: submission.revision,
      submissionFingerprint: submission.fingerprint, sourceSha256: cataloguePayloadHashBytes(bytes).toLowerCase(), sourceByteLength: bytes.length,
      sourceMimeType: "image/png", idempotencyKey: "host-upload-one"};
    assert.equal((await read(request)).state, "not_found");
    for (const sourceMimeType of [["image/png"], {toString: "image/png"}, null]) {
      await assert.rejects(service().handleProductMedia("owner-one", "prepareStoreProductMedia",
        {productMediaVersion: 1, ...request, sourceMimeType}), {code: "invalid_input"});
    }
    assert.equal((await db.collection("workspaceCatalogues").doc("evaluation").collection("stores").doc("store-one")
      .collection("productMediaUploads").get()).size, 0);
    await assert.rejects(prepare({...request, sourceSha256: "A".repeat(64)}), {code: "stale_snapshot"});
    const first = await prepare(request);
    assert.equal(first.state, "awaiting_upload"); assert.equal(first.current, true);
    assert.deepEqual(await prepare(request), first); // Repository reconstructed for every call.
    originals.set(first.uploadId, bytes);
    await assert.rejects(prepare({...request, sourceByteLength: bytes.length + 1}), {code: "conflict"});
    await assert.rejects(call("readStoreProductMedia", request, "different-owner"), {code: "not_found"});
    await assert.rejects(confirm({...request, sourceMimeType: "image/jpeg"}), {code: "conflict"});
    originals.set(first.uploadId, Buffer.from(bytes).fill(0));
    await assert.rejects(confirm(request), {code: "invalid_image"});
    assert.equal((await read(request)).processed, null);
    originals.set(first.uploadId, bytes); failAfterWrite = true;
    await assert.rejects(confirm(request), /host crash after durable derivative/u);
    assert.equal(derivatives.size, 1); assert.equal((await read(request)).processed, null);
    const done = await confirm(request);
    assert.equal(done.state, "processed"); assert.equal(done.current, true);
    assert.equal(done.approved, false); assert.equal(done.publicationConfirmed, false);
    assert.equal(done.processed?.originalGeneration, "17"); assert.equal(done.processed?.derivativeGeneration, "23");
    assert.equal(done.processed?.file.width, 640); assert.equal(done.processed?.meetsPublicSourceFloor, true);
    assert.equal(done.processed?.source.sha256, request.sourceSha256.toUpperCase());
    assert.equal(done.uploadUrl, undefined);
    assert.equal(derivatives.size, 1);
    const originalReads = reads, originalGrants = grants;
    assert.deepEqual(await confirm(request), done); assert.deepEqual(await read(request), done);
    assert.deepEqual(await prepare(request), done);
    assert.equal(reads, originalReads); assert.equal(grants, originalGrants);
    const root = db.collection("workspaceCatalogues").doc("evaluation").collection("stores").doc("store-one");
    const uploadRef = root.collection("productMediaUploads").doc(first.uploadId);
    const stored = (await uploadRef.get()).data() as StoreProductMediaUpload;
    for (const corrupt of [
      {...stored, schemaVersion: 2}, {...stored, preparedAt: "bad-date"}, {...stored, expiresAt: at},
      {...stored, sourceByteLength: stored.sourceByteLength + 1},
      {...stored, processed: {...stored.processed!, assetId: "unbound-asset"}},
      {...stored, processed: {...stored.processed!, originalGeneration: ""}},
      {...stored, processed: {...stored.processed!, processedAt: "2040-01-01T00:00:00.000Z"}},
      {...stored, processed: {...stored.processed!, file: {...stored.processed!.file, width: 99999}}},
      {...stored, processed: {...stored.processed!, source: {...stored.processed!.source, sha256: "A".repeat(64)}}},
      {...stored, processed: {...stored.processed!, meetsPublicSourceFloor: false}},
      {...stored, processed: {...stored.processed!, approved: true}},
    ]) {
      await uploadRef.set(corrupt);
      await assert.rejects(read(request));
      await uploadRef.set(stored);
    }
    assert.equal((await root.collection("skus").get()).size, 0);
    assert.equal((await root.collection("productReviews").get()).size, 0);
    assert.equal((await db.collection("workspaceCatalogues").doc("evaluation").collection("publicListingBindings").get()).size, 0);
    assert.deepEqual(await repository().readProductSubmission("store-one", "sku-one", "owner-one"), submission);
    const another = {...request, idempotencyKey: "host-upload-race"}, pending = await prepare(another);
    originals.set(pending.uploadId, bytes);
    duringSave = async () => {
      const changed = {...product, content: {...product.content, title: "Newer product source"}};
      await repository().submitProduct(storeProductSubmission("owner-one", "evaluation",
        {storeId: "store-one", expectedRevision: 1, idempotencyKey: "host-source-edit", product: changed}, at));
    };
    failAfterWrite = true;
    await assert.rejects(confirm(another), /host crash after durable derivative/u);
    assert.equal((await read(another)).processed, null); assert.equal((await read(another)).current, false);
    const historical = await confirm(another);
    assert.equal(historical.state, "processed"); assert.equal(historical.current, false);
    assert.equal(historical.approved, false); assert.equal(historical.publicationConfirmed, false);
    assert.deepEqual((await read(another)).processed, historical.processed);
    const recovered = await confirm(request);
    assert.equal(recovered.current, false); assert.deepEqual(recovered.processed, done.processed);
    assert.equal((await root.collection("productSubmissions").doc("sku-one").get()).get("revision"), 2);
    await db.collection("workspaceProfiles").doc(profile.caseId).update({ownerUserId: "replacement-owner"});
    await assert.rejects(read(request), {code: "not_found"});
    await db.collection("workspaceProfiles").doc(profile.caseId).update({ownerUserId: "owner-one"});
    const current = (await repository().readProductSubmission("store-one", "sku-one", "owner-one"))!;
    const expiring = {...request, idempotencyKey: "host-expiry", submissionRevision: current.revision, submissionFingerprint: current.fingerprint};
    const oldGrant = await prepare(expiring); clock = "2026-10-16T12:06:00.000Z";
    const renewed = await prepare(expiring);
    assert.equal(renewed.uploadId, oldGrant.uploadId);
    assert.equal(renewed.state, "awaiting_upload");
    const savedRenewal = (await root.collection("productMediaUploads").doc(renewed.uploadId).get()).data() as StoreProductMediaUpload;
    assert.equal(savedRenewal.preparedAt, at); assert.equal(savedRenewal.grantIssuedAt, clock);
    assert.equal(savedRenewal.expiresAt, "2026-10-16T12:11:00.000Z");
    originals.set(renewed.uploadId, bytes);
    clock = "2026-10-16T12:12:00.000Z";
    assert.equal((await confirm(expiring)).state, "processed"); // Grant expiry does not invalidate uploaded original bytes.
    // Disabled actual storage stays unavailable and cannot produce an accepted result.
    const disabled = new WorkspaceCatalogueService(new FirestoreWorkspaceCatalogueRepository(db, "evaluation"));
    const noStorage = {...expiring, idempotencyKey: "host-disabled"};
    await assert.rejects(disabled.handleProductMedia("owner-one", "prepareStoreProductMedia", {productMediaVersion: 1, ...noStorage}), {code: "service_unavailable"});
  } finally {await db.terminate(); await deleteApp(app);}
});
function hostMediaBucket() {
  // Explicit host SDK double: exercises actual adapter choices, not a deployed bucket acceptance.
  const values = new Map<string, {bytes: Buffer; metadata: Record<string, unknown>}>();
  const calls: Array<{action: string; path: string; generation?: string}> = [];
  let privateBucket = true, signed: Record<string, unknown> | undefined, writes = 0;
  const bucket = {
    async getMetadata() {return [{iamConfiguration: {publicAccessPrevention: privateBucket ? "enforced" : "inherited",
      uniformBucketLevelAccess: {enabled: privateBucket}}}];},
    file(path: string, options?: {generation?: string}) {
      const generation = options?.generation, log = (action: string) => calls.push({action, path, ...(generation ? {generation} : {})});
      return {
        async getSignedUrl(options: Record<string, unknown>) {signed = options; log("sign"); return ["https://private-host.invalid/upload-only"];},
        async getMetadata() {
          log("metadata"); const value = values.get(path); if (!value) throw Object.assign(Error("missing"), {code: 404});
          if (generation && generation !== value.metadata.generation) throw Error("wrong generation");
          return [structuredClone(value.metadata)];
        },
        createReadStream() {log("read"); return Readable.from([Buffer.from(values.get(path)!.bytes)]);},
        async save(bytes: Buffer, options: {preconditionOpts?: {ifGenerationMatch: number}; metadata: Record<string, unknown>}) {
          log("write"); assert.equal(options.preconditionOpts?.ifGenerationMatch, 0);
          if (values.has(path)) throw Object.assign(Error("already exists"), {code: 412});
          writes++; values.set(path, {bytes: Buffer.from(bytes), metadata: {...options.metadata, generation: "31", size: String(bytes.length)}});
        },
      };
    },
  };
  return {values, calls, get writes() {return writes;}, get signed() {return signed;},
    setPrivate(value: boolean) {privateBucket = value;},
    adapter: new GoogleCloudStoreProductMediaObjects(bucket as unknown as ConstructorParameters<typeof GoogleCloudStoreProductMediaObjects>[0])};
}
async function hostUpload() {
  const bytes = await sharp({create: {width: 520, height: 640, channels: 4, background: {r: 40, g: 90, b: 70, alpha: 0.5}}}).png().toBuffer();
  const request: StoreProductMediaRequest = {storeId: "store-one", skuId: "sku-one", submissionRevision: 1,
    submissionFingerprint: "A".repeat(64), sourceSha256: cataloguePayloadHashBytes(bytes), sourceByteLength: bytes.length,
    sourceMimeType: "image/png", idempotencyKey: "host-upload-one"};
  const upload: StoreProductMediaUpload = {...request, schemaVersion: 1, realm: "evaluation", ownerUserId: "owner-one",
    uploadId: "B".repeat(64), fingerprint: "C".repeat(64), preparedAt: at, expiresAt: "2026-10-16T12:05:00.000Z", processed: null};
  return {upload, bytes};
}
test("LF03-MEDIA GCS adapter requires private storage, signs write-once bound uploads and pins generation", async () => {
  const host = hostMediaBucket(), {upload, bytes} = await hostUpload();
  host.setPrivate(false);
  await assert.rejects(host.adapter.prepare(upload), {code: "service_unavailable"});
  host.setPrivate(true);
  const grant = await host.adapter.prepare(upload);
  assert.equal(grant.requiredHeaders["x-goog-if-generation-match"], "0");
  assert.equal(grant.requiredHeaders["content-length"], String(bytes.length));
  assert.equal(host.signed?.action, "write");
  assert.equal((host.signed?.expires as Date).toISOString(), upload.expiresAt);
  const path = host.calls.find(call => call.action === "sign")!.path;
  assert.match(path, /^private\/product-media\/v1\/evaluation\//u);
  const metadata = Object.fromEntries(Object.entries(grant.requiredHeaders).filter(([k]) => k.startsWith("x-goog-meta-"))
    .map(([k, v]) => [k.slice("x-goog-meta-".length), v]));
  const object = {bytes, metadata: {metadata, contentType: "image/png", size: String(bytes.length),
    generation: "17", timeCreated: "2026-10-16T12:00:01.000Z"}};
  host.values.set(path, object);
  assert.deepEqual(await host.adapter.read(upload), {bytes, generation: "17"});
  assert.ok(host.calls.some(call => call.action === "metadata" && call.generation === "17"));
  assert.deepEqual(host.calls.filter(call => call.action === "read").map(call => call.generation), ["17"]);
  for (const changed of [
    {...object.metadata, contentType: "image/jpeg"}, {...object.metadata, size: "1"},
    {...object.metadata, timeCreated: "2026-10-16T12:06:00.000Z"},
    {...object.metadata, metadata: {...metadata, "moolsocial-binding": "other"}},
    {...object.metadata, metadata: {...metadata, firebaseStorageDownloadTokens: "forbidden"}},
  ]) {
    host.values.set(path, {bytes, metadata: changed});
    await assert.rejects(host.adapter.read(upload), {code: "invalid_image"});
  }
  host.values.set(path, {...object, bytes: Buffer.alloc(8 * 1024 * 1024 + 1)});
  await assert.rejects(host.adapter.read(upload), {code: "invalid_image"});
});
test("LF03-MEDIA GCS derivative recovery is immutable, verified, private and metadata-free", async () => {
  const host = hostMediaBucket(), {upload, bytes} = await hostUpload(), image = await decodeProductImage(bytes);
  const saved = await host.adapter.save(upload, "17", image as NormalizedStoreProductImage);
  assert.deepEqual(await host.adapter.save(upload, "17", image as NormalizedStoreProductImage), saved);
  assert.equal(host.writes, 1);
  assert.equal(saved.generation, "31");
  const path = host.calls.find(call => call.action === "write")!.path, stored = host.values.get(path)!;
  assert.match(path, /^private\/product-media\/v1\/evaluation\/.+\/derivatives\/[^/]+\.png$/u);
  assert.equal(stored.metadata.cacheControl, "private, no-store");
  assert.equal(stored.metadata.contentType, "image/png");
  assert.ok(host.calls.filter(call => call.action === "read").every(call => call.generation === "31"));
  assert.equal((await sharp(stored.bytes).metadata()).hasAlpha, true);
  const processed: StoreProductMediaUpload = {...upload, processed: {originalGeneration: '17', derivativeGeneration: saved.generation,
    assetId: saved.assetId, processedAt: at, source: image.source, file: (image as NormalizedStoreProductImage).file, meetsPublicSourceFloor: image.meetsPublicSourceFloor}};
  assert.deepEqual(await host.adapter.readDerivative(processed), image.bytes);
  await assert.rejects(host.adapter.readDerivative({...processed, processed: {...processed.processed!, derivativeGeneration: '99'}}));
  const priorMetadata = structuredClone(stored.metadata);
  stored.metadata = {...priorMetadata, metadata: {...priorMetadata.metadata as Record<string, unknown>, firebaseStorageDownloadTokens: 'forbidden'}};
  await assert.rejects(host.adapter.readDerivative(processed), {code: 'invalid_image'});
  stored.metadata = priorMetadata;
  stored.bytes = Buffer.from(stored.bytes).fill(0);
  await assert.rejects(host.adapter.readDerivative(processed), {code: 'invalid_image'});
  await assert.rejects(host.adapter.save(upload, "17", image as NormalizedStoreProductImage), {code: "invalid_image"});
  host.setPrivate(false);
  await assert.rejects(host.adapter.readDerivative(processed), {code: 'service_unavailable'});
  await assert.rejects(host.adapter.save(upload, "17", image as NormalizedStoreProductImage), {code: "service_unavailable"});
});
test("LF03-MEDIA actual offline GCS signer agrees with the strict client grant contract", async () => {
  // Ephemeral host-only key, never written/logged; no real Google credential, network request or upload.
  const {privateKey} = generateKeyPairSync("rsa", {modulusLength: 2048,
    privateKeyEncoding: {type: "pkcs8", format: "pem"}, publicKeyEncoding: {type: "spki", format: "pem"}});
  const bucket = new Storage({projectId: "demo-private-media", credentials: {client_email: "host@invalid", private_key: privateKey}}).bucket("host-private");
  Object.assign(bucket, {getMetadata: async () => [{iamConfiguration: {publicAccessPrevention: "enforced", uniformBucketLevelAccess: {enabled: true}}}]});
  const {upload} = await hostUpload(), now = new Date();
  upload.preparedAt = now.toISOString(); upload.expiresAt = new Date(now.getTime() + 300000).toISOString();
  const grant = await new GoogleCloudStoreProductMediaObjects(bucket).prepare(upload), url = new URL(grant.uploadUrl);
  assert.equal(url.host, "storage.googleapis.com");
  assert.equal(url.pathname, `/host-private/private/product-media/v1/evaluation/${upload.uploadId}/original`);
  assert.equal(url.searchParams.get("X-Goog-SignedHeaders"), [...Object.keys(grant.requiredHeaders), "host"].sort().join(";"));
  assert.equal(url.searchParams.get("X-Goog-Algorithm"), "GOOG4-RSA-SHA256");
  assert.ok(url.searchParams.get("X-Goog-Credential")!.endsWith("/auto/storage/goog4_request"));
  assert.ok(Number(url.searchParams.get("X-Goog-Expires")) <= 300);
  assert.ok(grant.uploadUrl.length > 240 && grant.uploadUrl.length < 8192);
});
test('LF03-SUBMIT new saved SKU has a private submission producer without a reviewed mirror prerequisite', () => {
  assert.equal(typeof (WorkspaceCatalogueService.prototype as unknown as Record<string, unknown>).handleProductSubmission, 'function');
  assert.equal(typeof (FirestoreWorkspaceCatalogueRepository.prototype as unknown as Record<string, unknown>).submitProduct, 'function');
});
test('LF03-SOURCE persisted submission has an actual source-bound catalogue proposal entry', () => {
  assert.equal(typeof (FirestoreWorkspaceCatalogueRepository.prototype as unknown as Record<string, unknown>)
    .proposeSubmittedCatalogue, 'function');
});
test('LF03-REVIEW has persistent private candidate production and negotiated owner readback', () => {
  const repository = FirestoreWorkspaceCatalogueRepository.prototype as unknown as Record<string, unknown>;
  assert.equal(typeof repository.resolveProductReview, 'function');
  assert.equal(typeof repository.readReviewedProductSubmission, 'function');
});
test("LF-DISCOVERY resolves directory candidates through reviewed public readback", () => {
  assert.equal(typeof (WorkspaceCatalogueService.prototype as unknown as Record<string, unknown>).publicDiscovery, "function");
  assert.equal(typeof (FirestoreWorkspaceCatalogueRepository.prototype as unknown as Record<string, unknown>).publicDiscoveryBindings, "function");
});
test("reviewed family has real persistent submission, receipt and trusted review entries", () => {
  const repository = FirestoreWorkspaceCatalogueRepository.prototype as unknown as Record<string, unknown>;
  for (const method of ["submitVariantFamily", "readVariantFamily", "reconcileVariantFamily", "reviewVariantFamily"]) {
    assert.equal(typeof repository[method], "function", method);
  }
});
test("local canonical producer has a persistent transaction entry, not only readback fixtures", () => {
  assert.equal(typeof (FirestoreWorkspaceCatalogueRepository.prototype as unknown as
    Record<string, unknown>).produceCatalogue, "function");
});
const profile = {schemaVersion: 1, caseId: "case-one", ownerUserId: "owner-one",
  name: "Host fixture Store",
  workspaceId: "store-one", status: "live", profileId: "retailer-grocery",
  familyId: "products-trade", shopEnabled: true} as WorkspaceProfileRecord;
function input(skuId = "sku-one"): StoreSkuInput {
  return {skuId, canonicalProductId: "canonical-one", verifiedPackId: "pack-one",
    sku: "SKU-ONE", publicListing: true,
    content: {title: "Host fixture oil", brand: "Host fixture", variant: "Sunflower",
      categoryId: "grocery", description: "Isolated test description", highlights: [],
      specifications: [], media: []},
    pack: {label: "1 L", quantityMilli: 1000, unit: "L", unitsPerCase: 1},
    channels: [{kind: "retail", offerId: "offer-one", priceMinor: 26000, mrpMinor: 28000,
      minimumOrder: 1, quantityStep: 1, tiers: []}],
    provenance: {entryMethod: "manual", sourceRecordId: "saved-source-one"}};
}
function submittedProduct(skuId = 'sku-one'): StoreProductSubmissionInput {
  const value = input(skuId), {media: _, ...content} = value.content;
  return {schemaVersion: 1, skuId, sku: value.sku, barcode: '', catalogueProductHint: null,
    content, pack: value.pack, channels: value.channels.map(({offerId: _, ...channel}) => channel),
    provenance: {entryMethod: 'manual', sourceRecordId: skuId},
    mediaIntent: {pendingUpload: false, pendingSelectionSha256: null, publishedReferences: []}, variantIntent: null};
}
function productRequest(overrides: Record<string, unknown> = {}) {
  return {productSubmissionVersion: 1, storeId: 'store-one', expectedRevision: 0,
    idempotencyKey: 'saved-product-one', product: submittedProduct(), ...overrides};
}
function productCommand(overrides: Record<string, unknown> = {}) {
  const {productSubmissionVersion: _, ...body} = productRequest(overrides);
  return storeProductSubmission('owner-one', 'evaluation', body, at);
}
test('LF03-SOURCE derives exact optional content/pack facts, not nominated catalogue identity or client hashes', () => {
  for (const entryMethod of ['manual', 'csv', 'catalogue'] as const) {
    const product = submittedProduct(); product.provenance.entryMethod = entryMethod;
    product.catalogueProductHint = 'nomination-not-approval';
    product.content.specifications = [{label: 'Warranty issuer', value: 'Host stated issuer'}];
    const record = planStoreProductSubmission(productCommand({product}), profile);
    const descriptor = {type: 'propose_product', commandId: 'source-product', expectedVersion: 1,
      productId: 'resolved-product', brandId: 'resolved-brand', codes: [{type: 'internal', value: 'SOURCE-ONE'}]};
    const actual = submittedCatalogueInput(record, descriptor);
    assert.equal(actual.productId, 'resolved-product');
    assert.equal(actual.categoryId, product.content.categoryId);
    assert.equal(actual.contentSha256, cataloguePayloadHash({...product.content, media: []}));
    assert.deepEqual(record.product, product);
    assert.throws(() => submittedCatalogueInput(record, {...descriptor, contentSha256: 'A'.repeat(64)}));
    const pack = submittedCatalogueInput(record, {type: 'propose_pack', commandId: 'source-pack', expectedVersion: 3,
      productId: 'resolved-product', packId: 'resolved-pack', codes: []});
    assert.equal(pack.descriptorSha256, cataloguePayloadHash(product.pack));
    const revision = submittedCatalogueInput(record, {type: 'propose_product_revision', commandId: 'source-revision', expectedVersion: 7,
      productId: 'resolved-product', previousContentSha256: 'A'.repeat(64)});
    assert.equal(revision.contentSha256, actual.contentSha256);
    for (const type of ['review_product', 'review_pack', 'create_offer', 'create', 'publish']) {
      assert.throws(() => submittedCatalogueInput(record, {...descriptor, type}));
    }
  }
});
test('LF03-SOURCE never strips pending or nominated images and rejects altered immutable input', () => {
  for (const pending of [true, false]) {
    const product = submittedProduct();
    product.mediaIntent = pending
      ? {pendingUpload: true, pendingSelectionSha256: 'A'.repeat(64), publishedReferences: []}
      : {pendingUpload: false, pendingSelectionSha256: null, publishedReferences: [{assetId: 'nominated-image', revision: 'one'}]};
    const record = planStoreProductSubmission(productCommand({product}), profile);
    assert.throws(() => submittedCatalogueInput(record, {type: 'propose_product'}), {code: 'unavailable'});
  }
  const record = planStoreProductSubmission(productCommand(), profile);
  record.product.content.title = 'Tampered persisted title';
  assert.throws(() => submittedCatalogueInput(record, {type: 'propose_product'}));
});

test('LF03-SOURCE emulator saved submission to catalogue proposals to exact reviewed public record', {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-source-${randomUUID().slice(0, 8)}`}, `source-${randomUUID()}`);
  const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation');
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
  const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant());
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const original = submittedProduct(); original.content.specifications = [{label: 'Model code', value: 'SOURCE-EXACT'}];
    original.channels[0]!.priceMinor = 10025;
    const saved = await repository().submitProduct(productCommand({product: original}));
    const source: CatalogueSubmissionReference = {realm: 'evaluation', storeId: saved.storeId,
      skuId: saved.skuId, revision: saved.revision, fingerprint: saved.fingerprint};
    const value: StoreSkuInput = {...input(), content: {...original.content, media: []},
      provenance: original.provenance, channels: original.channels.map(channel => ({...channel, offerId: 'offer-one'}))};
    const commands = productionCommands(value);
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[0]!);
    const {contentSha256: _, categoryId: __, ...productProposal} = commands[1]!;
    const pending = await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, productProposal);
    assert.equal(pending.products[0]!.contentSha256, cataloguePayloadHash(value.content));
    assert.equal(pending.products[0]!.state, 'pending_review');
    assert.deepEqual((await service().publicCatalogue({storeId: 'store-one'}) as {items: unknown[]}).items, []);
    await assert.rejects(repository().proposeSubmittedCatalogue('reviewer-one', catalogueIdentity, source, productProposal), {code: 'forbidden'});
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, {...source, fingerprint: 'F'.repeat(64)}, productProposal), {code: 'conflict'});
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, {...source, realm: 'production'}, productProposal));
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, {...source, storeId: 'other-store'}, productProposal), {code: 'forbidden'});
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source,
      {...productProposal, productId: 'changed-under-same-command'}), {code: 'conflict'});
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, commands[2]!));
    // Current private head changes; the processing request still names exact revision1.
    const updated = structuredClone(original); updated.content.title = 'Newer private version';
    updated.mediaIntent = {pendingUpload: true, pendingSelectionSha256: 'A'.repeat(64), publishedReferences: []};
    const later = await repository().submitProduct(productCommand({expectedRevision: 1, idempotencyKey: 'later', product: updated}));
    assert.deepEqual(await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, productProposal), pending);
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity,
      {...source, revision: later.revision, fingerprint: later.fingerprint}, {...productProposal, commandId: 'waiting-image'}), {code: 'unavailable'});
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity,
      {...source, revision: later.revision, fingerprint: later.fingerprint}, productProposal), {code: 'unavailable'});
    await assert.rejects(repository().produceCatalogue('owner-one', catalogueIdentity, commands[2]!), {code: 'forbidden'});
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[2]!);
    const {descriptorSha256: ___, ...packProposal} = commands[3]!;
    const pack = await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, packProposal);
    assert.equal(pack.packs[0]!.descriptorSha256, cataloguePayloadHash(original.pack));
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[4]!);
    await repository().produceCatalogue('owner-one', catalogueIdentity, commands[5]!);
    assert.equal((await root.collection('publicListingBindings').get()).size, 0);
    assert.equal((await root.collection('stores').doc('store-one').collection('skus').get()).size, 0);
    // Existing explicit owner adoption remains separate from the source proposals.
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', expectedRevision: 0, idempotencyKey: 'adopt-reviewed', sku: value});
    const publicResult = await service().publicCatalogue({storeId: 'store-one'}) as {items: Array<{content: StoreSkuContent; channels: StoreSkuChannel[]}>};
    assert.deepEqual(publicResult.items[0]!.content.specifications, original.content.specifications);
    assert.equal(publicResult.items[0]!.content.title, original.content.title);
    assert.equal(publicResult.items[0]!.channels[0]!.priceMinor, 10025);
    const revisionDoc = await root.collection('stores').doc('store-one').collection('productSubmissions')
      .doc('sku-one').collection('revisions').doc('1').get();
    assert.deepEqual(revisionDoc.data(), saved);
    assert.equal((await repository().readProductSubmission('store-one', 'sku-one', 'owner-one'))!.revision, 2);
    const receipts = await root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId).collection('producerReceipts').get();
    assert.equal(receipts.docs.filter(doc => doc.get('submission')?.revision === 1).length, 2);
    assert.deepEqual(await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, productProposal), pending);
    assert.equal((await repository().catalogue(catalogueIdentity.catalogueId))!.version, 6);
    // A later explicit media-free edit uses the same immutable canonical/SKU
    // identity, then stays private until independent review and owner adoption.
    const changed = structuredClone(original); changed.content.title = 'Reviewed source update';
    changed.content.specifications.push({label: 'Warranty duration', value: '12 stated months'});
    const savedUpdate = await repository().submitProduct(productCommand({expectedRevision: 2,
      idempotencyKey: 'changed-media-free', product: changed}));
    const updateSource = {...source, revision: savedUpdate.revision, fingerprint: savedUpdate.fingerprint};
    const revisionProposal = {type: 'propose_product_revision', commandId: 'source-content-update', expectedVersion: 6,
      productId: value.canonicalProductId, previousContentSha256: cataloguePayloadHash(value.content)};
    const changedValue = {...value, content: {...changed.content, media: []}};
    const revisionPending = await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, updateSource, revisionProposal);
    assert.equal(revisionPending.products[0]!.contentRevisions![0]!.contentSha256, cataloguePayloadHash(changedValue.content));
    assert.equal((await service().publicCatalogue({storeId: 'store-one'}) as typeof publicResult).items[0]!.content.title, original.content.title);
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, {type: 'review_product_revision',
      commandId: 'review-source-update', expectedVersion: 7, productId: value.canonicalProductId, revision: 2,
      previousContentSha256: cataloguePayloadHash(value.content), contentSha256: cataloguePayloadHash(changedValue.content),
      decision: 'verify', reasonCode: 'checked-original-submission'});
    assert.equal((await service().publicCatalogue({storeId: 'store-one'}) as typeof publicResult).items[0]!.content.title, original.content.title);
    await service().bindReviewedSku('owner-one', {storeId: 'store-one', expectedRevision: 1,
      idempotencyKey: 'adopt-reviewed-update', sku: changedValue});
    const refreshed = await service().publicCatalogue({storeId: 'store-one'}) as typeof publicResult;
    assert.deepEqual(refreshed.items[0]!.content, changedValue.content);
    assert.equal(refreshed.items[0]!.channels[0]!.priceMinor, 10025);
    assert.deepEqual(await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, productProposal), pending);
    assert.equal((await repository().catalogue(catalogueIdentity.catalogueId))!.version, 8);
    // Isolated host fixture models a later trusted withdrawal. Receipt recovery
    // must not require current publishability or rewrite the revoked aggregate.
    const aggregateRef = root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId);
    const current = (await aggregateRef.get()).data() as CatalogueAggregate;
    await aggregateRef.update({products: current.products.map(product => ({...product, state: 'rejected'}))});
    const revoked = (await aggregateRef.get()).data();
    const revisionCount = (await aggregateRef.collection('revisions').get()).size;
    assert.deepEqual(await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, packProposal), pack);
    assert.deepEqual((await aggregateRef.get()).data(), revoked);
    assert.equal((await aggregateRef.collection('revisions').get()).size, revisionCount);
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source,
      {...packProposal, commandId: 'new-pack-after-withdrawal', expectedVersion: 8, packId: 'new-pack'}), {code: 'invalid_input'});
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source,
      {...packProposal, packId: 'changed-under-pack-command'}), {code: 'conflict'});
    const expired = new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date('2026-10-17T00:00:00.000Z'));
    await assert.rejects(expired.proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, productProposal), {code: 'forbidden'});
    await root.collection('producerAuthorities').doc('owner-one').update({enabled: false});
    await assert.rejects(repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, productProposal), {code: 'forbidden'});
  } finally {await db.terminate(); await deleteApp(app);}
});
test('LF03-SUBMIT accepts authored manual, CSV and Catalogue data without approved identities', () => {
  for (const entryMethod of ['manual', 'csv', 'catalogue'] as const) {
    const product = submittedProduct(); product.provenance.entryMethod = entryMethod;
    product.channels[0]!.priceMinor = 10025;
    assert.deepEqual(normalizeSubmittedProduct(product), product);
    const candidate = planStoreProductSubmission(productCommand({product}), profile);
    assert.equal(candidate.revision, 1); assert.equal(candidate.product.channels[0]!.priceMinor, 10025);
    assert.equal(candidate.product.catalogueProductHint, null);
    for (const forbidden of ['canonicalProductId', 'verifiedPackId', 'publicListing', 'offerId', 'purchasePrice', 'stock']) {
      assert.equal(JSON.stringify(candidate).includes(`"${forbidden}"`), false);
    }
  }
  for (const [op, action] of [['submitStoreProduct', 'submit'], ['readStoreProductSubmission', 'read'],
    ['reconcileStoreProductSubmission', 'reconcile']] as const) assert.equal(storeProductSubmissionOperation(op), action);
  for (const op of ['approveStoreProduct', 'reviewStoreProduct', 'produceCatalogue', null, ['submitStoreProduct']]) {
    assert.equal(storeProductSubmissionOperation(op), undefined);
  }
});
test('LF03-SUBMIT private input rejects extra data, coerced values and mismatched source identity', () => {
  for (const edit of [
    (p: any) => {p.purchasePrice = 23000;}, (p: any) => {p.stock = 50;},
    (p: any) => {p.publicListing = true;}, (p: any) => {p.canonicalProductId = 'invented';},
    (p: any) => {p.channels[0].offerId = 'invented';}, (p: any) => {p.pack.unit = ['L'];},
    (p: any) => {p.channels[0].priceMinor = 100.25;}, (p: any) => {p.provenance.sourceRecordId = 'another-sku';},
    (p: any) => {p.mediaIntent.localPath = 'C:/private/photo.jpg';},
    (p: any) => {p.mediaIntent.pendingUpload = true;},
    (p: any) => {p.mediaIntent.pendingSelectionSha256 = 'A'.repeat(64);},
    (p: any) => {p.variantIntent = {familyId: 'family-one', localRevision: 1, selections: {}};},
  ]) {
    const value = submittedProduct(); edit(value); assert.throws(() => normalizeSubmittedProduct(value));
  }
});
test('LF03-SUBMIT image/family intent is private, frozen and changes the original request fingerprint', () => {
  const value = submittedProduct();
  value.mediaIntent = {pendingUpload: true, pendingSelectionSha256: 'A'.repeat(64), publishedReferences: []};
  value.variantIntent = {familyId: 'phone-family', localRevision: 3, selections: {colour: 'blue', storage: '256'}};
  const first = productCommand({product: value});
  value.mediaIntent.pendingSelectionSha256 = 'B'.repeat(64);
  assert.equal(first.product.mediaIntent.pendingSelectionSha256, 'A'.repeat(64));
  assert.notEqual(first.fingerprint, productCommand({product: value}).fingerprint);
  assert.equal(first.product.variantIntent!.selections.storage, '256');
});
test('LF03-SUBMIT CAS and exact original receipt replay do not mutate a newer head', () => {
  const command = productCommand(), first = planStoreProductSubmission(command, profile);
  const nextProduct = submittedProduct(); nextProduct.content.description = 'Updated saved details';
  const nextCommand = productCommand({product: nextProduct, expectedRevision: 1, idempotencyKey: 'second'});
  const next = planStoreProductSubmission(nextCommand, profile, first);
  assert.equal(next.revision, 2);
  assert.deepEqual(planStoreProductSubmission(command, profile, next, {fingerprint: command.fingerprint, record: first}), first);
  assert.throws(() => planStoreProductSubmission(command, profile, next), {code: 'revision_conflict'});
  assert.throws(() => planStoreProductSubmission({...command, product: nextProduct}, profile, next,
    {fingerprint: command.fingerprint, record: first}));
  assert.throws(() => planStoreProductSubmission(command, {...profile, ownerUserId: 'other'}), {code: 'not_found'});
  assert.throws(() => planStoreProductSubmission(command, {...profile, status: 'suspended'}), {code: 'invalid_state'});
  assert.throws(() => planStoreProductSubmission(command, profile, undefined,
    {fingerprint: command.fingerprint, record: {...first, skuId: 'wrong'}}));
});
test('LF03-SUBMIT emulator persists new private SKU, restarts, reconciles originals and fences concurrent updates',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
    const app = initializeApp({projectId: `demo-lf03-submit-${randomUUID().slice(0, 8)}`}, `submit-${randomUUID()}`);
    const db = getFirestore(app), repository = (realm: 'evaluation' | 'production' = 'evaluation') =>
      new FirestoreWorkspaceCatalogueRepository(db, realm, () => new Date(at));
    const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
    const root = db.collection('workspaceCatalogues').doc('evaluation').collection('stores').doc('store-one');
    try {
      await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
      const original = productRequest();
      const missing = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission',
        {productSubmissionVersion: 1, storeId: 'store-one', skuId: 'sku-one'}) as {state: string; record: null};
      assert.equal(missing.state, 'none'); assert.equal(missing.record, null);
      const first = await service().handleProductSubmission('owner-one', 'submitStoreProduct', original) as
        {record: StoreProductSubmissionRecord; approved: boolean; publicationConfirmed: boolean; orderingAvailable: boolean; state: string};
      assert.equal(first.state, 'submitted'); assert.equal(first.approved, false);
      assert.equal(first.publicationConfirmed, false); assert.equal(first.orderingAvailable, false);
      assert.deepEqual(await repository().readProductSubmission('store-one', 'sku-one', 'owner-one'), first.record);
      assert.equal(await repository('production').readProductSubmission('store-one', 'sku-one', 'owner-one'), undefined);
      assert.equal((await root.collection('skus').get()).size, 0);
      assert.equal((await db.collection('workspaceCatalogues').doc('evaluation').collection('publicListingBindings').get()).size, 0);
      assert.equal((await db.collection('workspaceCatalogues').doc('evaluation').collection('canonicalCatalogues').get()).size, 0);
      const updated = submittedProduct(); updated.content.description = 'Second saved revision';
      updated.mediaIntent = {pendingUpload: true, pendingSelectionSha256: 'A'.repeat(64), publishedReferences: []};
      const second = await service().handleProductSubmission('owner-one', 'submitStoreProduct',
        productRequest({expectedRevision: 1, idempotencyKey: 'second', product: updated})) as typeof first;
      assert.equal(second.record.revision, 2); assert.equal(second.state, 'awaiting_media');
      const recovered = await service().handleProductSubmission('owner-one', 'reconcileStoreProductSubmission', original) as typeof first;
      assert.deepEqual(recovered.record, first.record);
      assert.deepEqual((await service().handleProductSubmission('owner-one', 'submitStoreProduct', original) as typeof first).record, first.record);
      assert.equal((await repository().readProductSubmission('store-one', 'sku-one', 'owner-one'))!.revision, 2);
      const outcomes = await Promise.allSettled(['one', 'two'].map(key => service().handleProductSubmission('owner-one', 'submitStoreProduct',
        productRequest({expectedRevision: 2, idempotencyKey: `race-${key}`, product: {...updated, sku: key}}))));
      assert.equal(outcomes.filter(r => r.status === 'fulfilled').length, 1);
      assert.equal((await root.collection('productSubmissions').doc('sku-one').collection('revisions').get()).size, 3);
      assert.equal((await root.collection('skus').get()).size, 0);
      assert.equal((await db.collection('workspaceCatalogues').doc('evaluation').collection('publicListingBindings').get()).size, 0);
      assert.equal((await db.collection('workspaceCatalogues').doc('evaluation').collection('canonicalCatalogues').get()).size, 0);
      const notFound = await service().handleProductSubmission('owner-one', 'reconcileStoreProductSubmission',
        productRequest({idempotencyKey: 'never-sent'})) as {state: string};
      assert.equal(notFound.state, 'not_found');
      await assert.rejects(service().handleProductSubmission('other-owner', 'reconcileStoreProductSubmission', original), {code: 'not_found'});
      await assert.rejects(service().handleProductSubmission('owner-one', 'submitStoreProduct', {...original, approved: true}));
      await assert.rejects(service().handleProductSubmission('owner-one', 'approveStoreProduct', original));
      const changed = submittedProduct(); changed.content.title = 'Changed under reused key';
      await assert.rejects(service().handleProductSubmission('owner-one', 'submitStoreProduct', productRequest({product: changed})), {code: 'conflict'});
      await db.collection('workspaceProfiles').doc(profile.caseId).update({ownerUserId: 'new-owner'});
      await assert.rejects(service().handleProductSubmission('owner-one', 'reconcileStoreProductSubmission', original), {code: 'not_found'});
      if (process.env.LF03_SUBMISSION_CAPTURE === 'true') console.log(`LF_SUBMISSION_PROJECTION=${JSON.stringify(first)}`);
    } finally {await db.terminate(); await deleteApp(app);}
  });
function staticMedia(value: StoreSkuInput, storeId = "store-one"): StoreSkuContent["media"] {
  return [{id: "host-reviewed-photo", revision: "host-photo-one", url: "https://example.com/host-photo.jpg",
    storeId, skuId: value.skuId, canonicalProductId: value.canonicalProductId,
    publisherWorkspaceId: storeId, file: {mimeType: "image/jpeg", byteLength: 1024,
      width: 640, height: 640, normalized: true, frameCount: 1}}];
}

const catalogueIdentity = {catalogueId: "catalogue-one", tenantId: "tenant-one"};
function producerAuthority(owner = true, storeId = "store-one"): CatalogueProducerAuthority {
  return {schemaVersion: 1, userId: owner ? "owner-one" : "reviewer-one", revision: 1, enabled: true,
    actor: {actorId: owner ? "owner-one" : "reviewer-one", tenantId: "tenant-one",
      ...(owner ? {workspaceId: storeId} : {}),
      scopes: [owner ? "supply.workspace.admin" : "supply.catalogue.review"]},
    validFrom: "2026-10-16T00:00:00.000Z", expiresAt: "2026-10-17T00:00:00.000Z"};
}
function producerParticipant(storeId = "store-one", categoryId = "grocery",
  participantType: "retailer" | "wholesaler" | "manufacturer" = "retailer"): SupplyParticipantWorkspace {
  const actor = producerAuthority(true, storeId).actor;
  let result = registerSupplyParticipantWorkspace({commandId: "fixture-register", occurredAt: at,
    workspaceId: storeId, tenantId: "tenant-one", legalEntityReference: "fixture-legal",
    participantType, actor});
  for (const capability of ["product_master_stewardship", "retail_fulfilment", "wholesale_supply"] as const) {
    result = applySupplyParticipantCommand(result, {type: "request_capability", actor,
      commandId: `request-${capability}`, workspaceId: storeId, expectedVersion: result.version,
      occurredAt: at, capability, evidence: [{kind: "identity", sha256: "A".repeat(64)}],
      qualifiers: {categoryIds: [categoryId], serviceAreaIds: capability === "product_master_stewardship" ? [] : ["host-area"]}});
    result = applySupplyParticipantCommand(result, {type: "review_capability",
      actor: {actorId: "capability-reviewer", tenantId: "tenant-one", scopes: ["supply.capability.review"]},
      commandId: `verify-${capability}`, workspaceId: storeId, expectedVersion: result.version,
      occurredAt: at, capability, decision: "verify", reason: "Isolated host evidence",
      effectiveFrom: "2026-10-16T00:00:00.000Z", expiresAt: "2026-10-17T00:00:00.000Z"});
  }
  return result;
}
function productionCommands(value = input()): Array<Record<string, unknown>> {
  return [
    {type: "create", commandId: "producer-create"},
    {type: "propose_product", commandId: "producer-product", expectedVersion: 1,
      productId: value.canonicalProductId, categoryId: value.content.categoryId, brandId: "brand-host",
      contentSha256: cataloguePayloadHash(value.content), codes: [{type: "internal", value: "HOST-001"}]},
    {type: "review_product", commandId: "producer-product-review", expectedVersion: 2,
      productId: value.canonicalProductId, decision: "verify", reasonCode: "checked-source",
      expectedContentSha256: cataloguePayloadHash(value.content)},
    {type: "propose_pack", commandId: "producer-pack", expectedVersion: 3,
      productId: value.canonicalProductId, packId: value.verifiedPackId,
      descriptorSha256: cataloguePayloadHash(value.pack), codes: [{type: "internal", value: "PACK-001"}]},
    {type: "review_pack", commandId: "producer-pack-review", expectedVersion: 4,
      packId: value.verifiedPackId, decision: "verify", reasonCode: "checked-source",
      expectedDescriptorSha256: cataloguePayloadHash(value.pack)},
    {type: "create_offer", commandId: "producer-offer", expectedVersion: 5,
      offerId: value.channels[0]!.offerId, packId: value.verifiedPackId, buyingContext: "consumer",
      serviceAreaIds: ["host-area"], termWindows: [{termSnapshotId: "term-host-one",
        termSnapshotSha256: cataloguePayloadHash(channelTerms(value.channels[0]!)),
        effectiveFrom: at, expiresAt: "2026-10-16T13:00:00.000Z"}]},
  ];
}
test('LF03-REVIEW emulator private reviewed candidate to negotiated readback and explicit source-bound publication', {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-review-${randomUUID().slice(0, 8)}`}, `review-${randomUUID()}`);
  const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation');
  const repository = (clock = at) => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(clock));
  const service = (clock = at) => new WorkspaceCatalogueService(repository(clock), catalogueIdentity, () => new Date(clock));
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant());
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    const product = submittedProduct(); product.channels[0]!.priceMinor = 10025;
    const saved = await repository().submitProduct(productCommand({product}));
    const source = {realm: 'evaluation' as const, storeId: saved.storeId, skuId: saved.skuId,
      revision: saved.revision, fingerprint: saved.fingerprint};
    const read = {productSubmissionVersion: 1, storeId: 'store-one', skuId: 'sku-one'};
    const reviewRead = {...read, productReviewVersion: 1};
    const before = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', reviewRead) as any;
    assert.equal(before.review.state, 'pending'); assert.equal(before.review.candidate, null);
    const value = {...input(), content: {...product.content, media: []}, provenance: product.provenance,
      channels: product.channels.map(channel => ({...channel, offerId: 'offer-one'}))};
    const commands = productionCommands(value);
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[0]!);
    const {contentSha256: _, categoryId: __, ...productProposal} = commands[1]!;
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, productProposal);
    const resolution = {source, expectedReviewRevision: 0, idempotencyKey: 'resolve-private',
      canonicalProductId: value.canonicalProductId, verifiedPackId: value.verifiedPackId,
      offers: [{kind: 'retail', offerId: 'offer-one'}]};
    await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution));
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[2]!);
    const {descriptorSha256: ___, ...packProposal} = commands[3]!;
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, packProposal);
    await repository().produceCatalogue('reviewer-one', catalogueIdentity, commands[4]!);
    await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution));
    await repository().produceCatalogue('owner-one', catalogueIdentity, commands[5]!);
    await assert.rejects(repository().resolveProductReview('owner-one', catalogueIdentity, resolution), {code: 'forbidden'});
    const aggregateRef = root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId);
    const approved = (await aggregateRef.get()).data() as CatalogueAggregate;
    // Negative isolated privileged-store fixtures: a resolver must not turn
    // self-reviewed or mismatched audit evidence into an owner-ready candidate.
    for (const change of [
      (c: any) => {c.products[0].reviewedBy = 'owner-one'; c.auditEvents.find((e: any) => e.eventType === 'product_verified').actorId = 'owner-one';},
      (c: any) => {c.auditEvents.find((e: any) => e.eventType === 'product_proposed').actorId = 'reviewer-one';},
      (c: any) => {c.auditEvents = c.auditEvents.filter((e: any) => e.eventType !== 'product_proposed');},
      (c: any) => {c.packs[0].reviewedBy = 'owner-one'; c.auditEvents.find((e: any) => e.eventType === 'pack_verified').actorId = 'owner-one';},
    ]) {
      const corrupt = structuredClone(approved); change(corrupt); await aggregateRef.set(corrupt);
      await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution), {code: 'forbidden'});
      assert.equal((await root.collection('stores').doc('store-one').collection('productReviews').get()).size, 0);
    }
    await aggregateRef.set(approved);
    await assert.rejects(repository().resolveProductReview('reviewer-one', {...catalogueIdentity, tenantId: 'other-tenant'}, resolution), {code: 'forbidden'});
    const candidate = await repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution);
    assert.deepEqual(candidate.sku, value); assert.equal(candidate.expectedMirrorRevision, 0);
    assert.equal(candidate.expiresAt, '2026-10-16T13:00:00.000Z');
    assert.deepEqual(await repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution), candidate);
    await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity,
      {...resolution, verifiedPackId: 'changed-pack'}), {code: 'conflict'});
    await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity,
      {...resolution, idempotencyKey: 'stale-resolution'}), {code: 'revision_conflict'});
    const legacy = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', read) as any;
    assert.equal(Object.hasOwn(legacy, 'review'), false); assert.equal(Object.hasOwn(legacy, 'productReviewVersion'), false);
    const ready = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', reviewRead) as any;
    assert.equal(ready.review.state, 'ready'); assert.deepEqual(ready.review.candidate, candidate);
    assert.equal(ready.approved, false); assert.equal(ready.publicationConfirmed, false); assert.equal(ready.orderingAvailable, false);
    assert.equal((await root.collection('stores').doc('store-one').collection('skus').get()).size, 0);
    assert.equal((await root.collection('publicListingBindings').get()).size, 0);
    await assert.rejects(service().handleProductSubmission('other-owner', 'readStoreProductSubmission', reviewRead), {code: 'not_found'});
    await assert.rejects(service().handleProductSubmission('owner-one', 'submitStoreProduct', {...productRequest(), productReviewVersion: 1}));
    const expired = await service('2026-10-16T13:00:00.000Z').handleProductSubmission('owner-one', 'readStoreProductSubmission', reviewRead) as any;
    assert.equal(expired.review.state, 'unavailable'); assert.equal(expired.review.candidate, null);
    await root.collection('producerAuthorities').doc('owner-one').update({enabled: false});
    const revoked = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', reviewRead) as any;
    assert.equal(revoked.review.state, 'unavailable'); assert.equal(revoked.review.candidate, null);
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    const request = {storeId: 'store-one', sku: value, expectedRevision: 0, idempotencyKey: 'publish-reviewed',
      reviewCandidate: {revision: candidate.revision, fingerprint: candidate.fingerprint}};
    await assert.rejects(service().saveSku('owner-one', request));
    await assert.rejects(service().bindReviewedSku('owner-one', {...request, reviewCandidate: {...request.reviewCandidate, fingerprint: 'A'.repeat(64)}}));
    await assert.rejects(service().bindReviewedSku('owner-one', {...request, sku: {...value, channels: [{...value.channels[0]!, priceMinor: 1}]}}));
    // Newer owner edits invalidate the candidate for NEW publication, not its historical receipt.
    const changed = structuredClone(product); changed.content.title = 'Reviewed second version';
    const saved2 = await repository().submitProduct(productCommand({expectedRevision: 1, idempotencyKey: 'edit-two', product: changed}));
    await assert.rejects(service().bindReviewedSku('owner-one', request));
    const stale = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', reviewRead) as any;
    assert.equal(stale.review.state, 'outdated'); assert.equal(stale.review.candidate, null);
    assert.deepEqual(await repository().resolveProductReview('reviewer-one', catalogueIdentity, resolution), candidate);
    const source2 = {...source, revision: saved2.revision, fingerprint: saved2.fingerprint};
    const changedValue = {...value, content: {...changed.content, media: []}};
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source2,
      {type: 'propose_product_revision', commandId: 'reviewed-edit-proposal', expectedVersion: 6,
        productId: value.canonicalProductId, previousContentSha256: cataloguePayloadHash(value.content)});
    await repository().produceCatalogue('reviewer-one', catalogueIdentity,
      {type: 'review_product_revision', commandId: 'reviewed-edit-approval', expectedVersion: 7,
        productId: value.canonicalProductId, revision: 2, previousContentSha256: cataloguePayloadHash(value.content),
        contentSha256: cataloguePayloadHash(changedValue.content), decision: 'reject', reasonCode: 'more-review-needed'});
    await repository().proposeSubmittedCatalogue('owner-one', catalogueIdentity, source2,
      {type: 'propose_product_revision', commandId: 'reviewed-edit-reproposal', expectedVersion: 8,
        productId: value.canonicalProductId, previousContentSha256: cataloguePayloadHash(value.content)});
    await repository().produceCatalogue('reviewer-one', catalogueIdentity,
      {type: 'review_product_revision', commandId: 'reviewed-edit-final-approval', expectedVersion: 9,
        productId: value.canonicalProductId, revision: 3, previousContentSha256: cataloguePayloadHash(value.content),
        contentSha256: cataloguePayloadHash(changedValue.content), decision: 'verify', reasonCode: 'independent-check'});
    const candidate2 = await repository().resolveProductReview('reviewer-one', catalogueIdentity,
      {...resolution, source: source2, expectedReviewRevision: 1, idempotencyKey: 'resolve-edit'});
    assert.equal(candidate2.revision, 2); assert.equal(candidate2.source.revision, 2);
    const request2 = {...request, sku: changedValue, idempotencyKey: 'publish-reviewed-edit',
      reviewCandidate: {revision: candidate2.revision, fingerprint: candidate2.fingerprint}};
    const ready2 = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', reviewRead) as any;
    assert.equal(ready2.review.state, 'ready');
    const bound = await service().bindReviewedSku('owner-one', request2) as any;
    assert.equal(bound.saved.skuId, 'sku-one'); assert.equal(bound.saved.revision, 1);
    assert.equal(bound.publicationConfirmed, false);
    const finalRead = await service().handleProductSubmission('owner-one', 'readStoreProductSubmission', reviewRead) as any;
    assert.equal(finalRead.review.state, 'bound');
    const publicRead = await service().publicCatalogue({storeId: 'store-one'}) as any;
    assert.equal(publicRead.items[0].content.title, changed.content.title);
    assert.equal(publicRead.items[0].channels[0].priceMinor, 10025);
    const later = structuredClone(changed); later.channels[0]!.priceMinor = 10026;
    const saved3 = await repository().submitProduct(productCommand({expectedRevision: 2, idempotencyKey: 'edit-three', product: later}));
    await assert.rejects(repository().resolveProductReview('reviewer-one', catalogueIdentity, {...resolution,
      source: {...source, revision: saved3.revision, fingerprint: saved3.fingerprint}, expectedReviewRevision: 2, idempotencyKey: 'unreviewed-new-price'}), {code: 'invalid_input'});
    assert.deepEqual(await service('2026-10-16T13:00:00.000Z').reconcileBinding('owner-one', request2), bound);
    assert.equal((await root.collection('stores').doc('store-one').collection('skus').doc('sku-one').get()).get('revision'), 1);
    if (process.env.LF03_REVIEW_CAPTURE === 'true') {
      console.log(`LF_REVIEW_CANDIDATE_PROJECTION=${JSON.stringify(ready)}`);
      console.log(`LF_REVIEW_BINDING_PROJECTION=${JSON.stringify({request: request2, response: bound, source: saved2})}`);
      console.log(`LF_REVIEW_ADOPTION_PROJECTION=${JSON.stringify({ready: ready2, bound: finalRead, request: request2, response: bound, source: saved2})}`);
    }
  } finally {await db.terminate(); await deleteApp(app);}
});
function produceAll(value = input(), canonicalBrandId: string | null = "brand-host", canonicalCategoryId = value.content.categoryId,
  liveProfile = profile) {
  let aggregate: CatalogueAggregate | undefined;
  const participant = producerParticipant("store-one", canonicalCategoryId,
    liveProfile.profileId === "wholesaler" || liveProfile.profileId === "manufacturer" ? liveProfile.profileId : "retailer"),
    receipts: CatalogueProductionReceipt[] = [];
  for (const command of productionCommands(value)) {
    if (command.type === "propose_product") {command.brandId = canonicalBrandId; command.categoryId = canonicalCategoryId;}
    const owner = ["propose_product", "propose_pack", "create_offer"].includes(String(command.type));
    const authority = producerAuthority(owner);
    const result = planCatalogueProduction({operatorUserId: authority.userId, identity: catalogueIdentity,
      input: command, observedAt: at}, authority, aggregate, participant, liveProfile);
    aggregate = result.aggregate;
    receipts.push({fingerprint: result.fingerprint, result: result.aggregate});
  }
  return {aggregate: aggregate!, participant, receipts};
}

function familyFixture() {
  const value = input(), other = input("sku-two");
  const records: StoreSkuRecord[] = [value, other].map(row => ({...row, schemaVersion: 1,
    storeId: "store-one", revision: 1, observedAt: at}));
  const family: StoreVariantFamilyInput = {familyId: "family-one", localRevision: 1,
    title: value.content.title, brand: value.content.brand, categoryId: value.content.categoryId,
    options: [{dimensionId: "colour", dimensionLabel: "Colour", optionId: "pink", optionLabel: "Pink", kind: "colour", swatchArgb: 0xffffc0cb},
      {dimensionId: "colour", dimensionLabel: "Colour", optionId: "blue", optionLabel: "Blue", kind: "colour", swatchArgb: 0xff0000ff},
      {dimensionId: "storage", dimensionLabel: "Storage", optionId: "128", optionLabel: "128 GB", kind: "storage", swatchArgb: null},
      {dimensionId: "storage", dimensionLabel: "Storage", optionId: "512", optionLabel: "512 GB", kind: "storage", swatchArgb: null}],
    members: [{skuId: "sku-one", skuRevision: 1, selections: {colour: "pink", storage: "128"}},
      {skuId: "sku-two", skuRevision: 1, selections: {colour: "blue", storage: "512"}}]};
  const command = storeVariantFamilySubmission("owner-one", "evaluation", {
    storeId: "store-one", expectedRevision: 0, idempotencyKey: "family-request-one", family}, at);
  const candidate = planStoreVariantFamilySubmission(command, profile, records);
  const review = {expectedCandidateRevision: candidate.revision, expectedCandidateFingerprint: candidate.fingerprint,
    expectedReviewRevision: 0, decision: "verify", reasonCode: "checked-source", idempotencyKey: "review-family-one"};
  return {family, records, command, candidate, review, aggregate: produceAll(value).aggregate};
}

test('LF03-REVISION reviewed family can retain an original member beside an approved revised member', () => {
  const fixture = familyFixture(), {records, family} = fixture, revised = records[0]!;
  revised.content.description = 'Independently reviewed updated details'; revised.revision = 2;
  family.members[0]!.skuRevision = 2;
  const previous = cataloguePayloadHash(records[1]!.content), next = cataloguePayloadHash(revised.content);
  const proposal = {type: 'propose_product_revision', commandId: 'propose-content-revision', expectedVersion: fixture.aggregate.version,
    productId: revised.canonicalProductId, previousContentSha256: previous, contentSha256: next};
  const pending = planCatalogueProduction({operatorUserId: 'owner-one', identity: catalogueIdentity,
    input: proposal, observedAt: at}, producerAuthority(), fixture.aggregate, producerParticipant(), profile).aggregate;
  assert.throws(() => planStoreVariantFamilyReview('reviewer-one', catalogueIdentity, fixture.review,
    producerAuthority(false), fixture.candidate, records, pending, at));
  const aggregate = planCatalogueProduction({operatorUserId: 'reviewer-one', identity: catalogueIdentity,
    input: {type: 'review_product_revision', commandId: 'review-content-revision', expectedVersion: pending.version,
      productId: revised.canonicalProductId, revision: 2, previousContentSha256: previous, contentSha256: next,
      decision: 'verify', reasonCode: 'checked-revision'}, observedAt: at}, producerAuthority(false), pending).aggregate;
  const command = storeVariantFamilySubmission('owner-one', 'evaluation', {storeId: 'store-one',
    expectedRevision: 0, idempotencyKey: 'revised-family', family}, at);
  const candidate = planStoreVariantFamilySubmission(command, profile, records);
  const review = planStoreVariantFamilyReview('reviewer-one', catalogueIdentity,
    {...fixture.review, expectedCandidateFingerprint: candidate.fingerprint}, producerAuthority(false), candidate, records, aggregate, at);
  assert.equal(review.decision, 'verify'); assert.equal(review.candidate.family.members.length, 2);
});

test('LF03-REVISION emulator approved updates preserve another Store original and historical receipts',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
    const app = initializeApp({projectId: `demo-lf03-revisions-${randomUUID().slice(0, 8)}`}, `revision-${randomUUID()}`);
    const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation');
    const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
    const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
    try {
      await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
      await root.collection('participants').doc('store-one').set(producerParticipant());
      await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
      await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
      for (const command of productionCommands()) {
        const owner = ['propose_product', 'propose_pack', 'create_offer'].includes(String(command.type));
        await repository().produceCatalogue(owner ? 'owner-one' : 'reviewer-one', catalogueIdentity, command);
      }
      const original = await service().bindReviewedSku('owner-one', save()) as {saved: StoreSkuRecord};
      const second = input('sku-two'); second.channels[0]!.offerId = 'offer-two'; second.channels[0]!.priceMinor = 10025;
      await db.collection('workspaceProfiles').doc('case-two').set({...profile, caseId: 'case-two', workspaceId: 'store-two', name: 'Second original Store'});
      await root.collection('participants').doc('store-two').set(producerParticipant('store-two'));
      await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority(true, 'store-two'));
      await repository().produceCatalogue('owner-one', catalogueIdentity,
        {...productionCommands(second).at(-1)!, commandId: 'second-original-offer', expectedVersion: 6});
      await service().bindReviewedSku('owner-one', save(second, {storeId: 'store-two'}));
      await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
      const updated = input(); updated.content.description = 'Independently reviewed updated product details';
      // Explicit host source copy only; no manufacturer entitlement or live data.
      updated.content.specifications = Object.entries({'Warranty issuer': 'Host manufacturer', 'Warranty duration': '12 months',
        'Warranty start basis': 'From original invoice', 'Warranty coverage': 'Manufacturing faults',
        'Warranty exclusions': 'Accidental damage', 'Warranty service': 'Use the manufacturer service process',
        'Warranty contact': 'Public warranty support', 'Warranty reference': 'Warranty sheet PF07'}).map(([label, value]) => ({label, value}));
      const previousContentSha256 = cataloguePayloadHash(input().content), contentSha256 = cataloguePayloadHash(updated.content);
      const proposal = {type: 'propose_product_revision', commandId: 'actual-content-update', expectedVersion: 7,
        productId: updated.canonicalProductId, previousContentSha256, contentSha256};
      const pending = await repository().produceCatalogue('owner-one', catalogueIdentity, proposal);
      assert.equal(pending.version, 8);
      const updateRequest = save(updated, {expectedRevision: 1, idempotencyKey: 'publish-reviewed-update'});
      await assert.rejects(service().bindReviewedSku('owner-one', updateRequest));
      const review = {type: 'review_product_revision', commandId: 'actual-independent-review', expectedVersion: 8,
        productId: updated.canonicalProductId, revision: 2, previousContentSha256, contentSha256,
        decision: 'verify', reasonCode: 'checked-source'};
      const approved = await repository().produceCatalogue('reviewer-one', catalogueIdentity, review);
      assert.equal(approved.version, 9);
      assert.deepEqual(await repository().produceCatalogue('owner-one', catalogueIdentity, proposal), pending);
      const saved = await service().bindReviewedSku('owner-one', updateRequest) as {saved: StoreSkuRecord};
      assert.equal(saved.saved.revision, 2); assert.equal(saved.saved.skuId, original.saved.skuId);
      assert.deepEqual(saved.saved.provenance, original.saved.provenance);
      const page = await service().publicDiscovery(discoveryRequest({pageSize: 50})) as DiscoveryResult;
      assert.equal(page.page.totalCount, 2);
      assert.doesNotMatch(JSON.stringify(page), /contentRevisions|proposedByActorId|reviewedBy|previousContentSha256/u);
      const descriptions = page.items.map(item => ({storeId: item.listing.storeId,
        description: (item.listing.items[0] as unknown as {content: StoreSkuContent}).content.description}));
      assert.deepEqual(descriptions, [{storeId: 'store-two', description: input().content.description},
        {storeId: 'store-one', description: updated.content.description}]);
      const projectedSpecs = page.items.map(item => ({storeId: item.listing.storeId,
        specifications: (item.listing.items[0] as unknown as {content: StoreSkuContent}).content.specifications}));
      assert.deepEqual(projectedSpecs, [{storeId: 'store-two', specifications: []},
        {storeId: 'store-one', specifications: updated.content.specifications}]);
      console.log(`LF_REVISION_PROJECTION=${JSON.stringify(page)}`); // Actual isolated emulator output, never native data.
      const replay = await service().bindReviewedSku('owner-one', save()) as {saved: StoreSkuRecord};
      assert.deepEqual(replay.saved, original.saved);
      assert.equal((await root.collection('stores').doc('store-one').collection('skus').doc('sku-one').get()).get('revision'), 2);
      const rejected = input(); rejected.content.description = 'Rejected later content';
      await repository().produceCatalogue('owner-one', catalogueIdentity, {type: 'propose_product_revision',
        commandId: 'rejected-next', expectedVersion: 9, productId: rejected.canonicalProductId,
        previousContentSha256: contentSha256, contentSha256: cataloguePayloadHash(rejected.content)});
      await repository().produceCatalogue('reviewer-one', catalogueIdentity, {type: 'review_product_revision',
        commandId: 'reject-third', expectedVersion: 10, productId: rejected.canonicalProductId, revision: 3,
        previousContentSha256: contentSha256, contentSha256: cataloguePayloadHash(rejected.content), decision: 'reject', reasonCode: 'incorrect-details'});
      await assert.rejects(service().bindReviewedSku('owner-one', save(rejected, {expectedRevision: 2, idempotencyKey: 'unapproved-third'})));
      const final = await service().publicDiscovery(discoveryRequest({pageSize: 50})) as DiscoveryResult;
      assert.deepEqual(final.items.map(item => ({storeId: item.listing.storeId,
        description: (item.listing.items[0] as unknown as {content: StoreSkuContent}).content.description})), descriptions);
    } finally { await db.terminate(); await deleteApp(app); }
  });

test('LF03-CONNECTED live family bridge', {
  skip: process.env.LF03_FAMILY_SERVER !== 'true', timeout: 180000,
}, async () => {
  // One opt-in cross-language acceptance test, never imported by index.ts or
  // used by a phone. Ordinary requests cannot select the actor or invoke review.
  assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: `demo-lf-family-${randomUUID().slice(0, 8)}`}, `family-${randomUUID()}`);
  const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation');
  const repository = new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
  const service = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(at));
  const controlToken = randomUUID(), operations: string[] = [];
  const promotions = new WorkspacePromotionService(new FirestorePromotionRepository(db, 'evaluation', () => new Date(at)), service, () => new Date(at));
  let explicitFinish = false;
  let complete!: () => void;
  const finished = new Promise<void>(resolve => {complete = resolve;});
  const server = createServer(async (request, response) => {
    try {
      if (request.method !== 'POST') throw new Error('Host bridge requires POST');
      let size = 0; const chunks: Buffer[] = [];
      for await (const raw of request) {
        const chunk = Buffer.from(raw); size += chunk.length;
        if (size > 384 * 1024) throw new Error('Host bridge body too large');
        chunks.push(chunk);
      }
      const body = JSON.parse(Buffer.concat(chunks).toString('utf8')) as Record<string, unknown>;
      let data: object;
      if (request.url === '/control') {
        if (request.headers['x-lf-control'] !== controlToken) {response.writeHead(403).end(); return;}
        if (body.action === 'review-product') {
          assert.match(String(body.skuId), /^sku-(one|two|food|care|electronics|appliance)$/u);
          const skuId = String(body.skuId), saved = await repository.readProductSubmission('store-one', skuId, 'owner-one');
          assert.ok(saved);
          // Isolated fixture provisioning only, never an owner-selected grant.
          // Each reviewed source still passes the real category/actor guards.
          await root.collection('participants').doc('store-one').set(producerParticipant('store-one', saved.product.content.categoryId));
          const source: CatalogueSubmissionReference = {realm: 'evaluation', storeId: 'store-one', skuId,
            revision: saved.revision, fingerprint: saved.fingerprint};
          const value: StoreSkuInput = {skuId, sku: saved.product.sku, canonicalProductId: `resolved-${skuId}`,
            verifiedPackId: `resolved-pack-${skuId}`, publicListing: true, content: {...saved.product.content, media: []},
            pack: saved.product.pack, provenance: saved.product.provenance,
            channels: saved.product.channels.map(channel => ({...channel, offerId: `offer-${skuId}`}))};
          let aggregate = await repository.catalogue(catalogueIdentity.catalogueId);
          if (!aggregate) aggregate = await repository.produceCatalogue('reviewer-one', catalogueIdentity,
            {type: 'create', commandId: 'bridge-create'});
          const commands = productionCommands(value);
          for (let index = 1; index < commands.length; index++) {
            const command = {...commands[index]!, commandId: `bridge-${skuId}-${index}`, expectedVersion: aggregate.version};
            if (index === 1 || index === 3) {
              const nomination: Record<string, unknown> = {...command, codes: [{type: 'internal', value: `${skuId}-${index}`}]};
              delete nomination.contentSha256; delete nomination.categoryId; delete nomination.descriptorSha256;
              aggregate = await repository.proposeSubmittedCatalogue('owner-one', catalogueIdentity, source, nomination);
            } else aggregate = await repository.produceCatalogue(index === 5 ? 'owner-one' : 'reviewer-one', catalogueIdentity, command);
          }
          const resolution = {source, expectedReviewRevision: 0, idempotencyKey: `resolve-${skuId}`,
            canonicalProductId: value.canonicalProductId, verifiedPackId: value.verifiedPackId,
            offers: [{kind: 'retail', offerId: `offer-${skuId}`}]};
          await assert.rejects(repository.resolveProductReview('owner-one', catalogueIdentity, resolution), {code: 'forbidden'});
          data = await repository.resolveProductReview('reviewer-one', catalogueIdentity, resolution);
        } else if (body.action === 'review-family') {
          const head = await repository.readVariantFamily('store-one', 'family-one', 'owner-one'); assert.ok(head?.candidate);
          const review = {expectedCandidateRevision: head.candidate.revision, expectedCandidateFingerprint: head.candidate.fingerprint,
            expectedReviewRevision: 0, decision: 'verify', reasonCode: 'checked-source', idempotencyKey: 'bridge-family-review'};
          await assert.rejects(repository.reviewVariantFamily('owner-one', catalogueIdentity, 'store-one', 'family-one', review), {code: 'forbidden'});
          data = await repository.reviewVariantFamily('reviewer-one', catalogueIdentity, 'store-one', 'family-one', review);
        } else if (body.action === 'finish') {
          assert.equal((await root.collection('stores').doc('store-one').collection('skus').get()).size, 6);
          for (const operation of ['submitStoreProduct', 'bindReviewedStoreCatalogueSku', 'submitStoreVariantFamily', 'readPublicStoreVariantFamilies',
            'saveStorePromotion', 'readPublicPromotionDiscovery']) {
            assert.ok(operations.includes(operation), `Missing actual request ${operation}`);
          }
          explicitFinish = true; data = {finished: true}; response.once('finish', complete);
        } else throw new Error('Unknown host control');
      } else {
        if (request.url !== '/gateway' || request.headers.authorization !== 'Bearer isolated-host-token') {
          response.writeHead(403).end(); return;
        }
        const {operation, ...input} = body;
        assert.equal(typeof operation, 'string'); operations.push(operation as string);
        if (storeProductSubmissionOperation(operation)) data = await service.handleProductSubmission('owner-one', operation as string, input);
        else if (operation === 'listStoreCatalogueSkus') data = await service.listSkus('owner-one', input);
        else if (operation === 'bindReviewedStoreCatalogueSku') data = await service.bindReviewedSku('owner-one', input);
        else if (operation === 'reconcileStoreCatalogueBinding') data = await service.reconcileBinding('owner-one', input);
        else if (operation === 'readPublicStoreCatalogue') data = await service.publicCatalogue(input);
        else if (operation === 'readPublicStoreVariantFamilies') data = await service.publicVariantFamilies(input);
        else if (operation === 'readPublicCatalogueDiscovery') data = await service.publicDiscovery(input);
        else if (['readStorePromotion', 'saveStorePromotion', 'reconcileStorePromotion', 'readPublicStorePromotions',
          'readPublicPromotionDiscovery'].includes(String(operation))) data = await promotions.handleOperation('owner-one', String(operation), input);
        else if (storeVariantFamilyOperation(operation)) data = await service.handleStoreVariantFamily('owner-one', operation as string, input);
        else throw new Error('Unsupported host operation');
      }
      response.writeHead(200, {'content-type': 'application/json'}).end(JSON.stringify({ok: true, data}));
    } catch (error) {
      const value = error as {httpStatus?: number; code?: string; message?: string};
      response.writeHead(value.httpStatus ?? 500, {'content-type': 'application/json'})
        .end(JSON.stringify({ok: false, error: {code: value.code ?? 'host_failure', message: value.message ?? 'Host failure'}}));
    }
  });
  server.requestTimeout = 10000; server.headersTimeout = 10000;
  const deadline = setTimeout(complete, 150000);
  try {
    await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
    await root.collection('participants').doc('store-one').set(producerParticipant('store-one', 'electronics'));
    await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
    await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
    await new Promise<void>(resolve => server.listen(0, '127.0.0.1', resolve));
    const address = server.address(); assert.ok(address && typeof address !== 'string');
    console.log(`LF03_FAMILY_READY=${JSON.stringify({port: address.port, controlToken})}`);
    await finished;
    assert.equal(explicitFinish, true, 'Bridge deadline/abort is not successful completion');
    assert.ok(operations.includes('readPublicStoreVariantFamilies'), 'Bridge did not finish public selection');
  } finally {
    clearTimeout(deadline); server.closeAllConnections();
    await new Promise<void>(resolve => server.close(() => resolve()));
    await db.terminate(); await deleteApp(app);
  }
});

test("family submission freezes only actual combinations, not a Cartesian inventory", () => {
  const {family, candidate} = familyFixture();
  assert.equal(candidate.family.members.length, 2);
  assert.equal(candidate.family.options.length, 4);
  assert.equal(Object.hasOwn(candidate, "approved"), false);
  family.members[0]!.selections.colour = "blue";
  assert.equal(candidate.family.members[0]!.selections.colour, "pink");
  assert.equal(Object.hasOwn(candidate, "stock"), false);
});

test("family HTTP classification exposes only bounded reads and owner submission, never trusted review", () => {
  assert.equal(storeVariantFamilyOperation("submitStoreVariantFamily"), "submit");
  assert.equal(storeVariantFamilyOperation("readStoreVariantFamily"), "owner_read");
  assert.equal(storeVariantFamilyOperation("reconcileStoreVariantFamily"), "owner_read");
  assert.equal(storeVariantFamilyOperation("readPublicStoreVariantFamilies"), "public_read");
  for (const operation of ["reviewVariantFamily", "produceCatalogue", ["submitStoreVariantFamily"], null, ""]) {
    assert.equal(storeVariantFamilyOperation(operation), undefined);
  }
});

test("family rejects coercive option kinds, review decisions, timestamps and public identity fields", async () => {
  const {family, candidate, records, review, aggregate} = familyFixture();
  const badFamily = structuredClone(family); Object.assign(badFamily.options[0]!, {kind: ["colour"]});
  assert.throws(() => normalizeStoreVariantFamily(badFamily));
  assert.throws(() => planStoreVariantFamilyReview("reviewer-one", catalogueIdentity, {...review, decision: ["verify"]},
    producerAuthority(false), candidate, records, aggregate, at));
  assert.throws(() => storeVariantFamilySubmission("owner-one", "evaluation", {storeId: "store-one", expectedRevision: 0,
    idempotencyKey: "time-test", family}, [at] as unknown as string));
  const binding = cataloguePublicListingBindings("evaluation", records[0]!)[0]!;
  for (const listing of [{listingId: [binding.listingId], skuId: binding.skuId, channel: "retail"},
    {listingId: binding.listingId, skuId: binding.skuId, channel: ["retail"]}]) {
    await assert.rejects(new WorkspaceCatalogueService(new Memory(), catalogueIdentity, () => new Date(at))
      .publicVariantFamilies({storeId: "store-one", listings: [listing]}), {code: "invalid_input"});
  }
});

test("family submission original receipt survives later member edits, but changed request cannot replay", () => {
  const {command, candidate, records} = familyFixture();
  const receipt = {fingerprint: command.fingerprint, record: candidate};
  records[0]!.revision = 2;
  assert.deepEqual(planStoreVariantFamilySubmission({...command, submittedAt: "2026-10-16T12:10:00.000Z"}, profile, [], undefined, receipt), candidate);
  const changed = storeVariantFamilySubmission("owner-one", "evaluation", {storeId: "store-one", expectedRevision: 0,
    idempotencyKey: command.idempotencyKey, family: {...command.family, title: "Changed"}}, at);
  assert.throws(() => planStoreVariantFamilySubmission(changed, profile, [], undefined, receipt), /changed/u);
  assert.throws(() => planStoreVariantFamilySubmission(command, {...profile, ownerUserId: "another-owner"}, records, undefined, receipt));
});

test("family corrupt persisted timestamp cannot normalize into a valid original receipt", () => {
  const {command, candidate} = familyFixture();
  const corrupt = {...candidate, submittedAt: [candidate.submittedAt]} as unknown as StoreVariantFamilyCandidate;
  assert.throws(() => planStoreVariantFamilySubmission(command, profile, [], undefined,
    {fingerprint: command.fingerprint, record: corrupt}));
});

for (const [label, mutate] of Object.entries({
  "duplicate tuple": (f: StoreVariantFamilyInput) => { f.members[1]!.selections = {...f.members[0]!.selections}; },
  "duplicate SKU": (f: StoreVariantFamilyInput) => { f.members[1]!.skuId = f.members[0]!.skuId; },
  "unknown option": (f: StoreVariantFamilyInput) => { f.members[0]!.selections.colour = "green"; },
  "missing dimension": (f: StoreVariantFamilyInput) => { delete f.members[0]!.selections.storage; },
  "extra dimension": (f: StoreVariantFamilyInput) => { f.members[0]!.selections.ram = "8"; },
  "duplicate option": (f: StoreVariantFamilyInput) => { f.options.push({...f.options[0]!}); },
  "different dimension label": (f: StoreVariantFamilyInput) => { f.options[1]!.dimensionLabel = "Paint"; },
  "swatch on storage": (f: StoreVariantFamilyInput) => { f.options[2]!.swatchArgb = 0; },
  "no members": (f: StoreVariantFamilyInput) => { f.members = []; },
  "private field": (f: StoreVariantFamilyInput) => { Object.assign(f, {purchaseCostMinor: 100}); },
})) test(`family rejects ${label}`, () => {
  const family = structuredClone(familyFixture().family); mutate(family);
  assert.throws(() => normalizeStoreVariantFamily(family));
});

for (const change of ["revision", "store", "title", "missing"] as const) test(`family rejects changed member ${change}`, () => {
  const {command, records} = familyFixture();
  if (change === "revision") records[0]!.revision++;
  if (change === "store") records[0]!.storeId = "store-two";
  if (change === "title") records[0]!.content.title = "Changed";
  if (change === "missing") records.splice(0, 1);
  assert.throws(() => planStoreVariantFamilySubmission(command, profile, records));
});

test("family candidate revision and realm cannot be silently replaced", () => {
  const {command, candidate, records} = familyFixture();
  assert.throws(() => planStoreVariantFamilySubmission(command, profile, records, candidate), /changed/u);
  assert.throws(() => planStoreVariantFamilySubmission({...command, expectedRevision: 1}, profile, records, candidate));
  const production = storeVariantFamilySubmission("owner-one", "production", {storeId: "store-one", expectedRevision: 1,
    idempotencyKey: "realm-change", family: command.family}, at);
  assert.throws(() => planStoreVariantFamilySubmission(production, profile, records, candidate));
});

test("trusted family approval pins candidate and does not alter product review or prices", () => {
  const {candidate, records, review, aggregate} = familyFixture();
  const before = cataloguePayloadHash({aggregate, records});
  const result = planStoreVariantFamilyReview("reviewer-one", catalogueIdentity, review, producerAuthority(false),
    candidate, records, aggregate, at);
  assert.equal(result.decision, "verify"); assert.equal(result.candidate.fingerprint, candidate.fingerprint);
  assert.equal(cataloguePayloadHash({aggregate, records}), before);
});

for (const change of ["owner", "revoked", "hash", "revision", "private", "unreviewed", "terms"] as const) {
  test(`family review rejects ${change}`, () => {
    const {candidate, records, review, aggregate} = familyFixture();
    const authority = producerAuthority(false); let operator = "reviewer-one";
    if (change === "owner") { authority.userId = "owner-one"; authority.actor = {...authority.actor, actorId: "owner-one"}; operator = "owner-one"; }
    if (change === "revoked") authority.enabled = false;
    if (change === "hash") review.expectedCandidateFingerprint = "0".repeat(64);
    if (change === "revision") records[0]!.revision++;
    if (change === "private") records[0]!.publicListing = false;
    if (change === "terms") records[0]!.channels[0]!.priceMinor++;
    const source: CatalogueAggregate = change === "unreviewed" ? {...aggregate,
      products: aggregate.products.map(p => ({...p, state: "rejected" as const}))} : aggregate;
    assert.throws(() => planStoreVariantFamilyReview(operator, catalogueIdentity, review, authority, candidate, records, source, at));
  });
}

test("trusted rejection grants no public family and needs no current offer", () => {
  const {candidate, review} = familyFixture();
  const result = planStoreVariantFamilyReview("reviewer-one", catalogueIdentity, {...review, decision: "reject"},
    producerAuthority(false), candidate, [], undefined, at);
  assert.equal(result.decision, "reject");
});

test("family emulator private submit, trusted approval, public exact siblings, restart, conflicts and withdrawal", {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf03-family"}, `family-${randomUUID()}`), db = getFirestore(app);
  const storeId = `store-${randomUUID()}`, caseId = `case-${randomUUID()}`;
  const identity = {...catalogueIdentity, catalogueId: `catalogue-${randomUUID()}`};
  const localProfile = {...profile, workspaceId: storeId, caseId};
  const root = db.collection("workspaceCatalogues").doc("evaluation"), first = input(), second = input("sku-two");
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, "evaluation", () => new Date(at));
  const service = () => new WorkspaceCatalogueService(repository(), identity, () => new Date(at));
  try {
    await db.collection("workspaceProfiles").doc(caseId).set(localProfile);
    await root.collection("participants").doc(storeId).set(producerParticipant(storeId));
    await root.collection("producerAuthorities").doc("owner-one").set(producerAuthority(true, storeId));
    await root.collection("producerAuthorities").doc("reviewer-one").set(producerAuthority(false));
    for (const command of productionCommands(first)) {
      const owner = ["propose_product", "propose_pack", "create_offer"].includes(String(command.type));
      await repository().produceCatalogue(owner ? "owner-one" : "reviewer-one", identity, command);
    }
    for (const value of [first, second]) await repository().bindReviewed({ownerUserId: "owner-one", profile: localProfile,
      input: value, expectedRevision: 0, idempotencyKey: `bind-${value.skuId}`,
      fingerprint: cataloguePayloadHash({storeId, input: value, expectedRevision: 0}), observedAt: at}, identity);
    const family = familyFixture().family;
    const original = {storeId, expectedRevision: 0, idempotencyKey: "submit-family", family};
    const command = storeVariantFamilySubmission("owner-one", "evaluation", original, at);
    const [candidate, retried] = await Promise.all([repository().submitVariantFamily(command), repository().submitVariantFamily(command)]);
    assert.deepEqual(candidate, retried);
    assert.equal((await root.collection("stores").doc(storeId).collection("variantFamilies").doc(family.familyId).collection("revisions").get()).size, 1);
    assert.deepEqual(await repository().reconcileVariantFamily(command), candidate);
    assert.equal((await repository().readVariantFamily(storeId, family.familyId, "owner-one")).review, null);
    await assert.rejects(repository().readVariantFamily(storeId, family.familyId, "other-owner"));
    const binding = (await repository().publicListingBindings({...first, schemaVersion: 1, storeId, revision: 1, observedAt: at}))![0]!;
    const query = {storeId, listings: [{listingId: binding.listingId, skuId: first.skuId, channel: "retail"}]};
    type Result = {state: string; revision: number; memberships: Array<{familyId: string | null; attributes: Array<{optionLabel: string}>}>;
      family: {products: Array<{product: {skuId: string; channels: Array<{priceMinor: number}>}; membership: {listing: {skuId: string}}}>} | null};
    const before = await service().publicVariantFamilies(query) as Result;
    assert.equal(before.state, "ready"); assert.equal(before.memberships[0]!.familyId, null);
    assert.equal((await service().publicVariantFamilies({...query, familyId: family.familyId}) as Result).state, "unavailable");
    const review = {expectedCandidateRevision: 1, expectedCandidateFingerprint: candidate.fingerprint,
      expectedReviewRevision: 0, decision: "verify", reasonCode: "checked-source", idempotencyKey: "family-review-one"};
    const reviewBody = {storeId, familyId: family.familyId, review};
    await assert.rejects(service().handleCatalogueProduction('owner-one', 'reviewCatalogueVariantFamily', reviewBody), {code: 'forbidden'});
    for (const changedOwner of ['reviewer-one', 'another-owner']) {
      await db.collection('workspaceProfiles').doc(caseId).update({ownerUserId: changedOwner});
      await assert.rejects(service().handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', reviewBody), {code: 'not_found'});
      assert.equal((await root.collection('stores').doc(storeId).collection('variantFamilyReviews').doc(family.familyId).get()).exists, false,
        'A pending family from a former owner cannot be newly approved after transfer.');
    }
    await db.collection('workspaceProfiles').doc(caseId).update({ownerUserId: 'owner-one'});
    const acknowledgement = await service().handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', reviewBody);
    assert.deepEqual(acknowledgement, {schemaVersion: 1, realm: 'evaluation', operation: 'reviewCatalogueVariantFamily', state: 'reviewed_family',
      storeId, familyId: family.familyId, candidateRevision: candidate.revision, candidateFingerprint: candidate.fingerprint,
      reviewRevision: 1, decision: 'verify'});
    assert.deepEqual(await service().handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', reviewBody), acknowledgement);
    await db.collection('workspaceProfiles').doc(caseId).update({ownerUserId: 'reviewer-one'});
    assert.deepEqual(await service().handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', reviewBody), acknowledgement,
      'Recover an already-recorded original result without creating a new decision.');
    await assert.rejects(service().handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily', {...reviewBody,
      review: {...review, expectedReviewRevision: 1, decision: 'reject', idempotencyKey: 'new-after-transfer'}}), {code: 'not_found'});
    assert.equal((await root.collection('stores').doc(storeId).collection('variantFamilyReviews').doc(family.familyId).get()).get('revision'), 1);
    await db.collection('workspaceProfiles').doc(caseId).update({ownerUserId: 'owner-one'});
    const approved = await repository().reviewVariantFamily("reviewer-one", identity, storeId, family.familyId, review);
    assert.deepEqual(await repository().reviewVariantFamily("reviewer-one", identity, storeId, family.familyId, review), approved);
    const after = await service().publicVariantFamilies({...query, familyId: family.familyId}) as Result;
    assert.equal(after.state, "ready"); assert.equal(after.revision, before.revision + 1);
    assert.equal(after.family!.products.length, 2);
    await service().handleStorePublicDetails('owner-one', 'saveStorePublicDetails', {
      ...detailsRequest({storeClassificationReadbackVersion: 1, details: {...publicDetails, businessType: 'manufacturer'}}), storeId});
    const classified = await service().publicVariantFamilies({...query, familyId: family.familyId,
      storeClassificationReadbackVersion: 1}) as {state: string; storeClassificationReadbackVersion: number;
        publicStore: {details: {details: {businessType: string}}}};
    assert.equal(classified.state, 'ready'); assert.equal(classified.storeClassificationReadbackVersion, 1);
    assert.equal(classified.publicStore.details.details.businessType, 'manufacturer');
    assert.deepEqual(Object.keys((await service().publicVariantFamilies(query) as {publicStore: object}).publicStore).sort(), ['id', 'name', 'profileId']);
    assert.deepEqual(after.family!.products.map(row => row.product.skuId).sort(), ["sku-one", "sku-two"]);
    for (const row of after.family!.products) {
      assert.equal(row.membership.listing.skuId, row.product.skuId); assert.equal(row.product.channels[0]!.priceMinor, 26000);
      assert.equal(Object.hasOwn(row.product, "provenance"), false);
    }
    await assert.rejects(service().handleCatalogueProduction('reviewer-one', 'reviewCatalogueVariantFamily',
      {...reviewBody, review: {...review, reasonCode: 'changed-original'}}), {code: 'conflict'});
    const competing = {...family, familyId: "another-family"};
    const another = await repository().submitVariantFamily(storeVariantFamilySubmission("owner-one", "evaluation",
      {...original, idempotencyKey: "other-family", family: competing}, at));
    await assert.rejects(repository().reviewVariantFamily("reviewer-one", identity, storeId, competing.familyId,
      {...review, idempotencyKey: "other-review", expectedCandidateFingerprint: another.fingerprint}), {code: "conflict"});
    const edited = structuredClone(family); edited.options.find(o => o.optionId === "pink")!.optionLabel = "Light Pink";
    await repository().submitVariantFamily(storeVariantFamilySubmission("owner-one", "evaluation",
      {...original, expectedRevision: 1, idempotencyKey: "family-edit", family: edited}, at));
    assert.deepEqual(await repository().reconcileVariantFamily(command), candidate, "Original acknowledgement survives later private candidate");
    const unchanged = await service().publicVariantFamilies({...query, familyId: family.familyId}) as Result;
    assert.equal(unchanged.revision, after.revision);
    assert.equal(unchanged.memberships[0]!.attributes.some(a => a.optionLabel === "Pink"), true);
    const withdrawn = {...second, publicListing: false};
    await repository().bindReviewed({ownerUserId: "owner-one", profile: localProfile, input: withdrawn,
      expectedRevision: 1, idempotencyKey: "withdraw-member", observedAt: at,
      fingerprint: cataloguePayloadHash({storeId, input: withdrawn, expectedRevision: 1})}, identity);
    assert.equal((await service().publicVariantFamilies({...query, familyId: family.familyId}) as Result).state, "unavailable");
    assert.equal((await new FirestoreWorkspaceCatalogueRepository(db, "production").readVariantFamily(storeId, family.familyId, "owner-one")).candidate, null);
  } finally { await db.terminate(); await deleteApp(app); }
});

test("LF03-BRAND real producer-to-Store-public flow needs no invented brand for produce", async () => {
  const value = input();
  value.content = {...value.content, title: "Cucumber", brand: "", variant: "", categoryId: "fruits-vegetables"};
  value.pack = {...value.pack, label: "1 kg", unit: "kg"};
  const {aggregate, participant, receipts} = produceAll(value, null);
  assert.equal(aggregate.products[0]!.brandId, null);
  assert.equal(aggregate.products[0]!.state, "verified");
  const command: CatalogueSave = {ownerUserId: "owner-one", profile, input: value, expectedRevision: 0,
    idempotencyKey: "unbranded-bind", fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0}), observedAt: at};
  const saved = planReviewedCatalogueSave(command, catalogueIdentity, aggregate, producerAuthority(), participant);
  const repository = new Memory(); repository.aggregate = aggregate; repository.records.set("store-one/sku-one", saved);
  const page = await subject(repository).publicCatalogue({storeId: "store-one", unbrandedProduceReadbackVersion: 1}) as
    {items: Array<{content: {brand: string; title: string}}>};
  assert.equal(page.items[0]!.content.brand, ""); assert.equal(page.items[0]!.content.title, "Cucumber");
  const original = {...productionCommands(value)[1]!, brandId: null};
  const replay = planCatalogueProduction({operatorUserId: "owner-one", identity: catalogueIdentity, input: original, observedAt: at},
    producerAuthority(), aggregate, participant, profile, receipts[1]);
  assert.equal(replay.aggregate.products[0]!.brandId, null); assert.equal(replay.replayed, true);
});

test("LF03-BRAND reviewed category cannot diverge from hashed Store content category", () => {
  const value = input(); value.content.categoryId = "fruits-vegetables";
  const {aggregate, participant} = produceAll(value, "brand-host", "grocery");
  const command: CatalogueSave = {ownerUserId: "owner-one", profile, input: value, expectedRevision: 0,
    idempotencyKey: "wrong-category-bind", fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0}), observedAt: at};
  assert.throws(() => planReviewedCatalogueSave(command, catalogueIdentity, aggregate, producerAuthority(), participant), {code: "invalid_input"});
});

for (const fault of ["branded-null", "category-mismatch"] as const) {
  test(`LF03-BRAND ${fault} cannot bind or leak through public readback even with matching hashes`, async () => {
    const value = input(); value.content.categoryId = "fruits-vegetables";
    const valid = produceAll(value);
    const command: CatalogueSave = {ownerUserId: "owner-one", profile, input: value, expectedRevision: 0,
      idempotencyKey: "contradiction-bind", fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0}), observedAt: at};
    const saved = planReviewedCatalogueSave(command, catalogueIdentity, valid.aggregate, producerAuthority(), valid.participant);
    const invalid = produceAll(value, fault === "branded-null" ? null : "brand-host", fault === "category-mismatch" ? "grocery" : "fruits-vegetables");
    assert.throws(() => planReviewedCatalogueSave(command, catalogueIdentity, invalid.aggregate, producerAuthority(), invalid.participant), {code: "invalid_input"});
    const repository = new Memory(); repository.records.set("store-one/sku-one", saved);
    repository.aggregate = valid.aggregate;
    const request = {storeId: "store-one", unbrandedProduceReadbackVersion: 1};
    assert.equal(((await subject(repository).publicCatalogue(request)) as {items: unknown[]}).items.length, 1);
    repository.aggregate = invalid.aggregate;
    assert.equal(((await subject(repository).publicCatalogue(request)) as {items: unknown[]}).items.length, 0);
    assert.deepEqual(repository.records.get("store-one/sku-one"), saved, "Withhold inconsistent public data; never rewrite owner history");
  });
}

test("LF03-BRAND family review rechecks canonical brand/category rather than hashes alone", () => {
  const f = familyFixture();
  assert.doesNotThrow(() => planStoreVariantFamilyReview("reviewer-one", catalogueIdentity, f.review, producerAuthority(false), f.candidate, f.records, f.aggregate, at));
  const inconsistent = structuredClone(f.aggregate);
  (inconsistent.products[0] as {brandId: string | null}).brandId = null;
  assert.throws(() => planStoreVariantFamilyReview("reviewer-one", catalogueIdentity, f.review, producerAuthority(false), f.candidate, f.records, inconsistent, at), {code: "invalid_input"});
});

test("local producer uses real contract transitions before exact binding and public readback", async () => {
  const repository = new Memory(), value = input();
  const {aggregate, participant} = produceAll(value);
  assert.equal(aggregate.version, 6);
  assert.deepEqual(aggregate.auditEvents.map(e => e.eventType), ["catalogue_created", "product_proposed",
    "product_verified", "pack_proposed", "pack_verified", "offer_created"]);
  const command: CatalogueSave = {ownerUserId: "owner-one", profile, input: value, expectedRevision: 0,
    idempotencyKey: "bound-one", fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0}), observedAt: at};
  const binding = planReviewedCatalogueSave(command, catalogueIdentity, aggregate,
    producerAuthority(), participant);
  repository.aggregate = aggregate; repository.records.set("store-one/sku-one", binding);
  const page = await subject(repository).publicCatalogue({storeId: "store-one"}) as
    {items: Array<{skuId: string; channels: unknown[]}>; orderingAvailable: boolean};
  assert.equal(page.items[0]?.skuId, value.skuId); assert.equal(page.items[0]?.channels.length, 1);
  assert.equal(page.orderingAvailable, false);
});

test("producer retry returns the original immutable result after later commands", () => {
  const {aggregate, receipts, participant} = produceAll();
  const original = productionCommands()[1]!, authority = producerAuthority();
  const replay = planCatalogueProduction({operatorUserId: authority.userId, identity: catalogueIdentity,
    input: original, observedAt: "2026-10-16T12:30:00.000Z"}, authority, aggregate, participant, profile, receipts[1]);
  assert.equal(replay.aggregate.version, 2); assert.equal(replay.replayed, true);
  assert.equal(aggregate.version, 6);
  assert.throws(() => planCatalogueProduction({operatorUserId: authority.userId, identity: catalogueIdentity,
    input: {...original, brandId: "changed-brand"}, observedAt: at}, authority, aggregate, participant, profile, receipts[1]), {code: "conflict"});
});

test("producer does not grant review authority from Store ownership or request fields", () => {
  const {aggregate, participant} = produceAll();
  const review = productionCommands()[2]!;
  assert.throws(() => planCatalogueProduction({operatorUserId: "owner-one", identity: catalogueIdentity,
    input: review, observedAt: at}, producerAuthority(), aggregate, participant, profile), {code: "forbidden"});
  for (const extra of [{actor: producerAuthority(false).actor}, {occurredAt: at}, {tenantId: "tenant-one"}]) {
    assert.throws(() => planCatalogueProduction({operatorUserId: "reviewer-one", identity: catalogueIdentity,
      input: {...productionCommands()[0], ...extra}, observedAt: at}, producerAuthority(false)), {code: "invalid_input"});
  }
});

test("missing revoked expired and foreign-tenant authority cannot write or replay", () => {
  const {aggregate, participant, receipts} = produceAll(), original = productionCommands()[1]!;
  for (const authority of [undefined, {...producerAuthority(), enabled: false},
    {...producerAuthority(), expiresAt: at},
    {...producerAuthority(), actor: {...producerAuthority().actor, tenantId: "tenant-other"}}]) {
    assert.throws(() => planCatalogueProduction({operatorUserId: "owner-one", identity: catalogueIdentity,
      input: original, observedAt: at}, authority, aggregate, participant, profile, receipts[1]), {code: "forbidden"});
  }
});

test("review pins the proposed hash and stale versions never produce another revision", () => {
  const {participant} = produceAll(), commands = productionCommands();
  let current = planCatalogueProduction({operatorUserId: "reviewer-one", identity: catalogueIdentity,
    input: commands[0]!, observedAt: at}, producerAuthority(false)).aggregate;
  current = planCatalogueProduction({operatorUserId: "owner-one", identity: catalogueIdentity,
    input: commands[1]!, observedAt: at}, producerAuthority(), current, participant, profile).aggregate;
  assert.throws(() => planCatalogueProduction({operatorUserId: "reviewer-one", identity: catalogueIdentity,
    input: {...commands[2], expectedContentSha256: "B".repeat(64)}, observedAt: at}, producerAuthority(false), current), {code: "invalid_input"});
  assert.throws(() => planCatalogueProduction({operatorUserId: "reviewer-one", identity: catalogueIdentity,
    input: {...commands[2], expectedVersion: 1}, observedAt: at}, producerAuthority(false), current), {code: "version_conflict"});
  assert.equal(current.products[0]?.state, "pending_review"); assert.equal(current.version, 2);
});

test("producer rejects non-string review decisions instead of silently rejecting the product", () => {
  const {receipts} = produceAll();
  assert.throws(() => planCatalogueProduction({operatorUserId: "reviewer-one", identity: catalogueIdentity,
    input: {...productionCommands()[2], decision: ["verify"]}, observedAt: at},
    producerAuthority(false), receipts[1]!.result), {code: "invalid_input"});
});

test("producer rejects persisted capabilities with malformed dates", () => {
  const {aggregate, participant} = produceAll();
  const corrupt = {...participant, capabilities: participant.capabilities.map(c =>
    c.kind === "product_master_stewardship" ? {...c, effectiveFrom: "invalid", expiresAt: "invalid"} : c)};
  assert.throws(() => planCatalogueProduction({operatorUserId: "owner-one", identity: catalogueIdentity,
    input: {...productionCommands()[1], productId: "canonical-two", expectedVersion: 6, commandId: "other-proposal"}, observedAt: at},
    producerAuthority(), aggregate, corrupt, profile), {code: "forbidden"});
});

test("fresh authorization time rejects expiry even when the original command time was valid", () => {
  const {aggregate, participant, receipts} = produceAll();
  assert.throws(() => planCatalogueProduction({operatorUserId: "owner-one", identity: catalogueIdentity,
    input: productionCommands()[1]!, observedAt: at}, producerAuthority(), aggregate, participant,
    profile, receipts[1], "2026-10-17T00:00:00.000Z"), {code: "forbidden"});
});

for (const profileId of ["wholesaler", "manufacturer"]) {
  test(`LF04-SUPPLIER reviewed publication and legacy-write boundary ${profileId}`, () => {
    const liveProfile = {...profile, profileId}, value = input();
    const {aggregate, participant} = produceAll(value, "brand-host", value.content.categoryId, liveProfile);
    assert.equal(participant.participantType, profileId);
    const command: CatalogueSave = {ownerUserId: "owner-one", profile: liveProfile, input: value,
      expectedRevision: 0, idempotencyKey: "supplier-reviewed-bind", observedAt: at,
      fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0})};
    assert.throws(() => planCatalogueSave(command), {code: "forbidden"},
      "Do not admit a supplier through the legacy unreviewed public-write route.");
    const saved = planReviewedCatalogueSave(command, catalogueIdentity, aggregate, producerAuthority(), participant);
    assert.equal(saved.publicListing, true);
    assert.equal(saved.skuId, value.skuId);
    const receipt = {fingerprint: command.fingerprint, record: saved};
    assert.deepEqual(planCatalogueSave(command, saved, receipt), saved,
      "Historical owned receipts replay; this is not renewed publishing authority.");
    for (const capability of [undefined, {...participant, capabilities: participant.capabilities.map(c =>
      c.kind === "retail_fulfilment" ? {...c, state: "revoked" as const} : c)}]) {
      assert.throws(() => planReviewedCatalogueSave(command, catalogueIdentity, aggregate, producerAuthority(), capability));
    }
    assert.throws(() => planReviewedCatalogueSave(command, catalogueIdentity, aggregate, undefined, participant));
    assert.throws(() => planReviewedCatalogueSave({...command, ownerUserId: "other-owner"},
      catalogueIdentity, aggregate, producerAuthority(), participant));
    for (const status of ["pending", "approved", "suspended"] as const) {
      assert.throws(() => planReviewedCatalogueSave({...command, profile: {...liveProfile, status}},
        catalogueIdentity, aggregate, producerAuthority(), participant));
    }
    const hidden = {...value, publicListing: false};
    const withdrawal = {...command, input: hidden, expectedRevision: 1,
      fingerprint: cataloguePayloadHash({storeId: "store-one", input: hidden, expectedRevision: 1})};
    assert.equal(planReviewedCatalogueSave(withdrawal, catalogueIdentity, undefined, undefined, undefined, saved).publicListing, false);
  });
}

test("reviewed binding rejects different content pack price Store and revoked selling capability", () => {
  const {aggregate, participant} = produceAll();
  for (const kind of ["content", "pack", "price", "store", "capability"]) {
    const value = input();
    if (kind === "content") value.content.description = "Unreviewed replacement";
    if (kind === "pack") value.pack.quantityMilli = 2000;
    if (kind === "price") value.channels[0]!.priceMinor = 25000;
    const command: CatalogueSave = {ownerUserId: "owner-one", profile, input: value, expectedRevision: 0,
      idempotencyKey: "bound-one", fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0}), observedAt: at};
    const source = kind === "capability" ? {...participant, capabilities: participant.capabilities.map(c =>
      c.kind === "retail_fulfilment" ? {...c, state: "revoked" as const} : c)} : participant;
    assert.throws(() => planReviewedCatalogueSave(command, catalogueIdentity, aggregate,
      kind === "store" ? producerAuthority(true, "store-other") : producerAuthority(), source), Error, kind);
  }
});

test("lost binding response recovers the original receipt after offer expiry without republishing", () => {
  const value = input(), {aggregate, participant} = produceAll(value);
  const command: CatalogueSave = {ownerUserId: "owner-one", profile, input: value, expectedRevision: 0,
    idempotencyKey: "lost-binding", fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0}), observedAt: at};
  const record = planReviewedCatalogueSave(command, catalogueIdentity, aggregate, producerAuthority(), participant);
  const receipt = {fingerprint: command.fingerprint, record};
  assert.deepEqual(planReviewedCatalogueSave(command, catalogueIdentity, aggregate, producerAuthority(),
    participant, record, receipt, "2026-10-16T14:00:00.000Z"), record);
  assert.throws(() => planReviewedCatalogueSave({...command, fingerprint: "B".repeat(64)}, catalogueIdentity,
    aggregate, producerAuthority(), participant, record, receipt, "2026-10-16T14:00:00.000Z"), {code: "invalid_input"});
});

test("exact owner withdrawal does not require selling authority or upload changed product facts", () => {
  const value = input(), {aggregate, participant} = produceAll(value);
  const original: CatalogueSave = {ownerUserId: "owner-one", profile, input: value, expectedRevision: 0,
    idempotencyKey: "listed-original", fingerprint: cataloguePayloadHash({storeId: "store-one", input: value, expectedRevision: 0}), observedAt: at};
  const current = planReviewedCatalogueSave(original, catalogueIdentity, aggregate, producerAuthority(), participant);
  const hidden = {...value, publicListing: false};
  const withdrawal = {...original, input: hidden, expectedRevision: 1, idempotencyKey: "withdraw-original",
    fingerprint: cataloguePayloadHash({storeId: "store-one", input: hidden, expectedRevision: 1})};
  const saved = planReviewedCatalogueSave(withdrawal, catalogueIdentity, undefined, undefined, undefined, current);
  assert.equal(saved.publicListing, false); assert.equal(saved.revision, 2);
  assert.deepEqual(saved.channels, current.channels);
  const changed = {...hidden, content: {...hidden.content, description: "Unreviewed replacement"}};
  assert.throws(() => planReviewedCatalogueSave({...withdrawal, input: changed,
    fingerprint: cataloguePayloadHash({storeId: "store-one", input: changed, expectedRevision: 1})},
    catalogueIdentity, aggregate, undefined, undefined, current), {code: "invalid_input"});
});
class Memory implements WorkspaceCatalogueRepository {
  readonly realm = "evaluation" as const;
  readonly stores = new Map([["store-one", profile]]);
  readonly records = new Map<string, StoreSkuRecord>();
  readonly receipts = new Map<string, {fingerprint: string; record: StoreSkuRecord}>();
  aggregate?: CatalogueAggregate;
  readonly details = new Map<string, StorePublicDetailsRecord>();
  readonly detailsReceipts = new Map<string, StorePublicDetailsReceipt>();
  async readStorePublicDetails(storeId: string, _owner?: string) { return structuredClone(this.details.get(storeId)); }
  async saveStorePublicDetails(command: StorePublicDetailsCommand) {
    const key = `${command.storeId}/${command.ownerUserId}/${command.idempotencyKey}`;
    const prior = this.detailsReceipts.get(key);
    const record = planStorePublicDetailsSave(command, this.stores.get(command.storeId), this.details.get(command.storeId), prior);
    if (!prior) {
      this.details.set(command.storeId, record); this.detailsReceipts.set(key, {fingerprint: command.fingerprint, record});
    }
    return structuredClone(record);
  }
  async reconcileStorePublicDetails(command: StorePublicDetailsCommand) {
    const receipt = this.detailsReceipts.get(`${command.storeId}/${command.ownerUserId}/${command.idempotencyKey}`);
    return receipt ? planStorePublicDetailsSave(command, this.stores.get(command.storeId), undefined, receipt) : undefined;
  }
  async store(id: string) {return structuredClone(this.stores.get(id));}
  async save(command: CatalogueSave): Promise<StoreSkuRecord> {
    const key = `${command.profile.workspaceId}/${command.input.skuId}`;
    const receiptKey = `${key}/${command.ownerUserId}/${command.idempotencyKey}`;
    const record = planCatalogueSave(command, this.records.get(key), this.receipts.get(receiptKey));
    if (!this.receipts.has(receiptKey)) {
      this.records.set(key, structuredClone(record));
      this.receipts.set(receiptKey, {fingerprint: command.fingerprint, record: structuredClone(record)});
    }
    return structuredClone(record);
  }
  async page(store: WorkspaceProfileRecord, _owner: string | undefined,
    after: string | undefined, limit: number, skuId?: string) {
    return structuredClone([...this.records.values()]
      .filter(r => r.storeId === store.workspaceId && (!after || r.skuId > after) && (!skuId || r.skuId === skuId))
      .sort((a, b) => a.skuId.localeCompare(b.skuId)).slice(0, limit));
  }
  async catalogue() {return structuredClone(this.aggregate);}
}
function subject(repository: Memory) {
  return new WorkspaceCatalogueService(repository,
    {catalogueId: "catalogue-one", tenantId: "tenant-one"}, () => new Date(at));
}
function descriptiveFacts() {
  return {schemaVersion: 1, compliance: {
    genericName: "Host oil", netQuantity: "1 L", manufacturerName: "Host maker",
    manufacturerAddress: "Host manufacturer address", packerName: null, packerAddress: null,
    importerName: null, importerAddress: null, countryOfOrigin: "India",
    manufacturedOrPackedOn: "See pack", bestBeforeOrUseBy: "See pack",
    fssaiLicenseNumber: "Host descriptive licence", consumerCare: "Host care details"},
  composition: "Host ingredients", regulatoryNote: "Host pack directions", requiresPrescription: false};
}
test("LF-FACTS legacy absence preserves exact input and hash", () => {
  const legacy = input(), original = structuredClone(legacy), hash = cataloguePayloadHash(legacy);
  assert.deepEqual(normalizeSku(legacy, "store-one"), original);
  assert.equal(cataloguePayloadHash(normalizeSku(legacy, "store-one")), hash);
  assert.equal(Object.hasOwn(normalizeSku(legacy, "store-one").content, "productFacts"), false);
});
test("LF-PRODUCE empty brand is exact optional produce data, not a generated brand", () => {
  const value = input(); value.content.categoryId = "fruits-vegetables"; value.content.brand = "";
  assert.deepEqual(normalizeSku(value, "store-one"), value);
  assert.equal(cataloguePayloadHash(normalizeSku(value, "store-one")), cataloguePayloadHash(value));
});
test("LF-PRODUCE other categories and malformed produce brand remain rejected", () => {
  for (const [category, brand] of [["grocery", ""], ["electronics", ""],
    ["fruits-vegetables", " "], ["fruits-vegetables", null], ["fruits-vegetables", 7]]) {
    const value = input(); Object.assign(value.content, {categoryId: category, brand});
    assert.throws(() => normalizeSku(value, "store-one"), {code: "invalid_input"});
  }
});
test("LF-FACTS strict versioned descriptive facts survive normalization", () => {
  const value = input(), facts = descriptiveFacts();
  Object.assign(value.content, {productFacts: facts});
  const normalized = normalizeSku(value, "store-one");
  assert.deepEqual((normalized.content as unknown as Record<string, unknown>).productFacts, facts);
  assert.equal(cataloguePayloadHash(normalized), cataloguePayloadHash(value));
});
test("LF-FACTS malformed versions unknown fields and coercions are rejected", () => {
  const facts = descriptiveFacts();
  for (const bad of [null, {...facts, schemaVersion: 2}, {...facts, extra: true},
    {...facts, requiresPrescription: "false"}, {...facts, compliance: {...facts.compliance, countryOfOrigin: 9}},
    {...facts, compliance: {...facts.compliance, manufacturerName: " Host maker"}},
    {...facts, composition: "x".repeat(4001)}]) {
    const value = input(); Object.assign(value.content, {productFacts: bad});
    assert.throws(() => normalizeSku(value, "store-one"), {code: "invalid_input"});
  }
});
test("LF-FACTS public and owner readback negotiate exact facts without altering legacy records", async () => {
  const repository = new Memory(), value = input(), facts = descriptiveFacts();
  Object.assign(value.content, {productFacts: facts});
  repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku("owner-one", save(value));
  await assert.rejects(subject(repository).listSkus("owner-one", {storeId: "store-one"}), {code: "unsupported_version"});
  await assert.rejects(subject(repository).publicCatalogue({storeId: "store-one"}), {code: "unsupported_version"});
  const owned = await subject(repository).listSkus("owner-one", {storeId: "store-one", productFactsReadbackVersion: 1}) as
    {items: Array<{content: Record<string, unknown>}>};
  const published = await subject(repository).publicCatalogue({storeId: "store-one", productFactsReadbackVersion: 1}) as
    {items: Array<{content: Record<string, unknown>}>; orderingAvailable: boolean};
  assert.deepEqual(owned.items[0]!.content.productFacts, facts);
  assert.deepEqual(published.items[0]!.content.productFacts, facts);
  assert.equal(published.orderingAvailable, false);
  const stored = repository.records.get("store-one/sku-one")!;
  assert.deepEqual(stored.content, value.content);
});
test("LF-FACTS changed facts cannot reuse the prior reviewed content hash", async () => {
  const repository = new Memory(), value = input();
  repository.aggregate = produceAll(value).aggregate;
  Object.assign(value.content, {productFacts: descriptiveFacts()});
  await subject(repository).saveSku("owner-one", save(value));
  const response = await subject(repository).publicCatalogue({storeId: "store-one", productFactsReadbackVersion: 1}) as
    {items: unknown[]};
  assert.deepEqual(response.items, []);
});
function save(sku = input(), extra: Record<string, unknown> = {}) {
  return {storeId: "store-one", sku, expectedRevision: 0,
    idempotencyKey: `save-${sku.skuId}`, ...extra};
}

test("reviewed static-photo metadata survives Store save and public readback without assumed frame proof", async () => {
  const repository = new Memory(), value = input(); value.content.media = staticMedia(value);
  repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku("owner-one", save(value));
  const result = await subject(repository).publicCatalogue({storeId: "store-one", mediaReadbackVersion: 1}) as
    {items: Array<{content: StoreSkuContent}>};
  assert.equal(result.items[0]!.content.media[0]!.file.frameCount, 1);
  const projected = await subject(repository).publicCatalogue({storeId: "store-one"}) as
    {items: Array<{content: StoreSkuContent}>};
  assert.equal(Object.hasOwn(projected.items[0]!.content.media[0]!.file, "frameCount"), false);
  assert.equal(repository.records.get("store-one/sku-one")!.content.media[0]!.file.frameCount, 1);
  await assert.rejects(subject(repository).listSkus("owner-one", {storeId: "store-one"}), {code: "unsupported_version"});
  const owned = await subject(repository).listSkus("owner-one", {storeId: "store-one", mediaReadbackVersion: 1}) as
    {items: StoreSkuRecord[]; mediaReadbackVersion: number};
  assert.equal(owned.mediaReadbackVersion, 1); assert.deepEqual(owned.items[0]!.content, value.content);
  await assert.rejects(subject(repository).publicCatalogue({storeId: "store-one", mediaReadbackVersion: 2}), {code: "invalid_input"});
  await assert.rejects(subject(repository).listSkus("owner-one", {storeId: "store-one", mediaReadbackVersion: 2}), {code: "invalid_input"});
  const legacy = input(); legacy.content.media = staticMedia(legacy);
  delete legacy.content.media[0]!.file.frameCount;
  const other = new Memory(); other.aggregate = produceAll(legacy).aggregate;
  await subject(other).saveSku("owner-one", save(legacy));
  const old = await subject(other).publicCatalogue({storeId: "store-one"}) as {items: Array<{content: StoreSkuContent}>};
  assert.equal(Object.hasOwn(old.items[0]!.content.media[0]!.file, "frameCount"), false);
});
for (const invalid of [null, 0, 2, 1.5, "1"]) {
  test(`static photo rejects unsupported explicit frame proof ${String(invalid)}`, async () => {
    const value = input(); value.content.media = staticMedia(value);
    (value.content.media[0]!.file as unknown as Record<string, unknown>).frameCount = invalid;
    await assert.rejects(subject(new Memory()).saveSku("owner-one", save(value)), {code: "invalid_input"});
  });
}
test("public listing identity readback requires real server bindings, not Store-local SKU inference", async () => {
  const repository = new Memory(), value = input();
  repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku("owner-one", save(value));
  const before = await subject(repository).publicCatalogue({storeId: "store-one"}) as {state: string; items: unknown[]};
  assert.equal(before.state, "ready"); assert.equal(before.items.length, 1);
  const unbound = await subject(repository).publicCatalogue({storeId: "store-one", listingReadbackVersion: 1}) as
    {state: string; listingCoverage: string; items: unknown[]};
  assert.equal(unbound.state, "unavailable");
  assert.equal(unbound.listingCoverage, "partial");
  assert.deepEqual(unbound.items, []);
});
test("public listing identities isolate Store realm channel and retain original SKU across revisions", async () => {
  const repository = new Memory();
  const saved = await subject(repository).saveSku("owner-one", save()) as {saved: StoreSkuRecord};
  const a = cataloguePublicListingBindings("evaluation", saved.saved)[0]!;
  const later = cataloguePublicListingBindings("evaluation", {...saved.saved, revision: 2,
    observedAt: "2026-10-16T12:01:00.000Z"})[0]!;
  assert.deepEqual(a, later);
  assert.equal(a.skuId, saved.saved.skuId); assert.notEqual(a.listingId, a.skuId);
  const otherStore = cataloguePublicListingBindings("evaluation", {...saved.saved, storeId: "store-two"})[0]!;
  const otherRealm = cataloguePublicListingBindings("production", saved.saved)[0]!;
  const both = cataloguePublicListingBindings("evaluation", {...saved.saved, channels: [saved.saved.channels[0]!,
    {...saved.saved.channels[0]!, kind: "wholesale", offerId: "offer-trade"}]});
  assert.equal(new Set([a.listingId, otherStore.listingId, otherRealm.listingId, both[1]!.listingId]).size, 4);
  assert.equal(both[0]!.listingId, a.listingId);
});
class BoundMemory extends Memory {
  async publicListingBindings(record: StoreSkuRecord) { return cataloguePublicListingBindings(this.realm, record); }
  async confirmPublicListingSnapshot(storeId: string, records: readonly StoreSkuRecord[],
    identity: {catalogueId: string; tenantId: string}, fingerprint: string, detailsFingerprint?: string) {
    const catalogue = await this.catalogue(), store = await this.store(storeId);
    if (!catalogue || catalogue.catalogueId !== identity.catalogueId || catalogue.tenantId !== identity.tenantId ||
        cataloguePayloadHash(catalogue) !== fingerprint || detailsFingerprint !== undefined &&
          cataloguePayloadHash(this.details.get(storeId) ?? null) !== detailsFingerprint || records.some(record =>
          cataloguePayloadHash(this.records.get(`${storeId}/${record.skuId}`)) !== cataloguePayloadHash(record))) return undefined;
    return store;
  }
}
class ViewMemory extends BoundMemory {
  sourceReads = 0;
  onSourceRead?: (read: number) => void;
  async publicCatalogueSource(storeId: string, _identity: {catalogueId: string; tenantId: string}): Promise<PublicCatalogueSource | undefined> {
    const profile = await this.store(storeId), catalogue = await this.catalogue();
    if (!profile || !catalogue) return undefined;
    const records = [...this.records.values()].filter(record => record.storeId === storeId)
      .sort((a, b) => a.skuId < b.skuId ? -1 : a.skuId === b.skuId ? 0 : 1);
    const result = structuredClone({profile, catalogue, records,
      bindings: records.flatMap(record => cataloguePublicListingBindings(this.realm, record)), policy: null,
      publicDetails: this.details.get(storeId) ?? null});
    this.onSourceRead?.(++this.sourceReads);
    return result;
  }
}

test("family membership batch supports two valid families with more than80 actual combined SKUs", async () => {
  const repository = new ViewMemory(), aggregate = produceAll().aggregate;
  repository.aggregate = aggregate;
  const reviews: ReturnType<typeof planStoreVariantFamilyReview>[] = [];
  const selected: Array<{listingId: string; skuId: string; channel: string}> = [];
  for (const group of ["one", "two"]) {
    const family = familyFixture().family;
    family.familyId = `family-${group}`; family.options = []; family.members = [];
    const records: StoreSkuRecord[] = [];
    for (let n = 0; n < 41; n++) {
      const skuId = `sku-${group}-${String(n).padStart(3, "0")}`, optionId = `size-${String(n).padStart(3, "0")}`;
      family.options.push({dimensionId: "size", dimensionLabel: "Size", optionId, optionLabel: `${n} units`, kind: "size", swatchArgb: null});
      family.members.push({skuId, skuRevision: 1, selections: {size: optionId}});
      const record: StoreSkuRecord = {...input(skuId), schemaVersion: 1, storeId: "store-one", revision: 1, observedAt: at};
      records.push(record); repository.records.set(`store-one/${skuId}`, record);
      if (n === 0) { const binding = cataloguePublicListingBindings("evaluation", record)[0]!;
        selected.push({listingId: binding.listingId, skuId, channel: "retail"}); }
    }
    const command = storeVariantFamilySubmission("owner-one", "evaluation", {storeId: "store-one",
      expectedRevision: 0, idempotencyKey: `submit-${group}`, family}, at);
    const candidate = planStoreVariantFamilySubmission(command, profile, records);
    reviews.push(planStoreVariantFamilyReview("reviewer-one", catalogueIdentity, {expectedCandidateRevision: 1,
      expectedCandidateFingerprint: candidate.fingerprint, expectedReviewRevision: 0, decision: "verify",
      reasonCode: "checked-source", idempotencyKey: `review-${group}`}, producerAuthority(false), candidate, records, aggregate, at));
  }
  const original = repository.publicCatalogueSource.bind(repository);
  repository.publicCatalogueSource = async (...args) => {
    const source = await original(...args);
    return source ? {...source, variantFamilies: {revision: 3, reviews}} : undefined;
  };
  const response = await subject(repository).publicVariantFamilies({storeId: "store-one", listings: selected}) as {
    state: string; memberships: Array<{familyId: string}>};
  assert.equal(response.state, "ready");
  assert.deepEqual(response.memberships.map(m => m.familyId), ["family-one", "family-two"]);
});

test("family corrupt persisted review decision cannot become a standalone public product", async () => {
  const repository = new ViewMemory(), {candidate, records, review, aggregate} = familyFixture();
  repository.aggregate = aggregate;
  for (const record of records) repository.records.set(`store-one/${record.skuId}`, record);
  const approved = planStoreVariantFamilyReview("reviewer-one", catalogueIdentity, review,
    producerAuthority(false), candidate, records, aggregate, at);
  const corrupt = {...approved, decision: ["verify"]} as unknown as typeof approved;
  const original = repository.publicCatalogueSource.bind(repository);
  repository.publicCatalogueSource = async (...args) => {
    const source = await original(...args);
    return source ? {...source, variantFamilies: {revision: 2, reviews: [corrupt]}} : undefined;
  };
  const binding = cataloguePublicListingBindings("evaluation", records[0]!)[0]!;
  await assert.rejects(subject(repository).publicVariantFamilies({storeId: "store-one",
    listings: [{listingId: binding.listingId, skuId: binding.skuId, channel: "retail"}]}));
});
const viewQuery = {destination: 'shop', search: '', categoryId: 'all', sort: 'relevance',
  brands: [], maximumPriceMinor: null, tradeType: null, listingIds: []};
test('LF-PRODUCE negotiated owner public and paged readback preserve reviewed empty brand', async () => {
  const repository = new ViewMemory(), value = input();
  value.content.categoryId = 'fruits-vegetables'; value.content.brand = '';
  repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku('owner-one', save(value));
  const capability = {unbrandedProduceReadbackVersion: 1};
  await assert.rejects(subject(repository).listSkus('owner-one', {storeId: 'store-one'}), {code: 'unsupported_version'});
  await assert.rejects(subject(repository).publicCatalogue({storeId: 'store-one'}), {code: 'unsupported_version'});
  const request = {storeId: 'store-one', cataloguePageVersion: 1, query: viewQuery, pageSize: 10};
  await assert.rejects(subject(repository).publicCatalogue(request), {code: 'unsupported_version'});
  const owned = await subject(repository).listSkus('owner-one', {storeId: 'store-one', ...capability}) as
    {unbrandedProduceReadbackVersion: number; items: Array<{content: StoreSkuContent}>};
  const published = await subject(repository).publicCatalogue({storeId: 'store-one', ...capability}) as typeof owned;
  const paged = await subject(repository).publicCatalogue({...request, ...capability}) as
    {unbrandedProduceReadbackVersion: number; items: Array<{row: {content: StoreSkuContent}}>; page: {totalCount: number}};
  assert.equal(owned.unbrandedProduceReadbackVersion, 1);
  assert.equal(published.unbrandedProduceReadbackVersion, 1);
  assert.equal(paged.unbrandedProduceReadbackVersion, 1);
  assert.deepEqual(owned.items[0]!.content, value.content);
  assert.deepEqual(published.items[0]!.content, value.content);
  assert.deepEqual(paged.items[0]!.row.content, value.content);
  assert.equal(paged.page.totalCount, 1);
  await assert.rejects(subject(repository).listSkus('other-owner', {storeId: 'store-one', ...capability}), {code: 'not_found'});
  repository.records.get('store-one/sku-one')!.content.description = 'Unreviewed change';
  const changed = await subject(repository).publicCatalogue({storeId: 'store-one', ...capability}) as {items: unknown[]};
  assert.deepEqual(changed.items, []);
});
test('LF-PRODUCE promotions preserve branded and unbranded reviewed source facts together', async () => {
  const values = [input('sku-branded'), input('sku-produce')];
  values[1]!.content.categoryId = 'fruits-vegetables'; values[1]!.content.brand = '';
  Object.assign(values[1]!.content, {productFacts: descriptiveFacts()});
  const sources = new Map<string, WorkspaceCatalogueService>();
  const publications: PromotionRecord[] = [];
  for (const value of values) {
    const repository = new Memory(); repository.aggregate = produceAll(value).aggregate;
    const catalogue = subject(repository); sources.set(value.skuId, catalogue);
    await catalogue.saveSku('owner-one', save(value));
    const promotion = {skuId: value.skuId, skuRevision: 1, channel: 'retail' as const,
      headline: 'Host source promotion', detail: 'Isolated host fixture, not an applied discount',
      validFrom: at, validUntil: '2026-10-16T12:30:00.000Z', active: true};
    publications.push(planPromotionSave({ownerUserId: 'owner-one', realm: 'evaluation', storeId: 'store-one',
      placementId: `promotion-${value.skuId}`, expectedRevision: 0, idempotencyKey: `key-${value.skuId}`,
      promotion, fingerprint: cataloguePayloadHash(promotion), observedAt: at}, profile,
      repository.records.get(`store-one/${value.skuId}`)));
  }
  const repository: PromotionRepository = {realm: 'evaluation', store: async () => profile,
    page: async () => structuredClone(publications),
    read: async (_store, id) => structuredClone(publications.find(p => p.placementId === id)),
    save: async () => { throw Error('Read-only host test'); },
    reconcile: async () => { throw Error('Read-only host test'); }};
  const service = new WorkspacePromotionService(repository, {publicCatalogue: async body => {
    assert.equal(body.unbrandedProduceReadbackVersion, 1);
    assert.equal(body.productFactsReadbackVersion, 1);
    assert.equal(Object.hasOwn(body, 'limit'), false, 'Exact SKU lookup implies one result; limit plus skuId is invalid.');
    return sources.get(String(body.skuId))!.publicCatalogue(body);
  }}, () => new Date(at));
  const page = await service.publicPage({storeId: 'store-one', limit: 10});
  assert.equal(page.state, 'ready'); assert.equal(page.items.length, 2);
  assert.deepEqual(page.items.map(p => (p.product.content as StoreSkuContent).brand), ['Host fixture', '']);
  assert.deepEqual((page.items[1]!.product.content as StoreSkuContent).productFacts, descriptiveFacts());
  assert.equal(Object.hasOwn(page, 'unbrandedProduceReadbackVersion'), false,
    'The existing promotion envelope stays exact; public listing resolution negotiates independently.');
});
test('LF-PRODUCE new capability leaves branded records and response shape unchanged', async () => {
  const repository = new ViewMemory(), value = input(); repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku('owner-one', save(value));
  const request = {storeId: 'store-one'};
  assert.deepEqual(await subject(repository).publicCatalogue({...request, unbrandedProduceReadbackVersion: 1}),
    await subject(repository).publicCatalogue(request));
  assert.deepEqual(await subject(repository).listSkus('owner-one', {...request, unbrandedProduceReadbackVersion: 1}),
    await subject(repository).listSkus('owner-one', request));
});
test('LF-PRODUCE malformed capability is rejected before owner public or paged readback', async () => {
  const repository = new ViewMemory();
  for (const version of [null, 2, '1', true]) {
    const request = {storeId: 'store-one', unbrandedProduceReadbackVersion: version};
    await assert.rejects(subject(repository).listSkus('owner-one', request), {code: 'invalid_input'});
    await assert.rejects(subject(repository).publicCatalogue(request), {code: 'invalid_input'});
    await assert.rejects(subject(repository).publicCatalogue({...request, cataloguePageVersion: 1,
      query: viewQuery, pageSize: 10}), {code: 'invalid_input'});
  }
});
test('LF-FACTS paged readback carries the same reviewed extension and snapshot identity', async () => {
  const repository = new ViewMemory(), value = input(), facts = descriptiveFacts();
  Object.assign(value.content, {productFacts: facts});
  repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku('owner-one', save(value));
  const request = {storeId: 'store-one', cataloguePageVersion: 1, query: viewQuery, pageSize: 10,
    productFactsReadbackVersion: 1};
  const response = await subject(repository).publicCatalogue(request) as
    {productFactsReadbackVersion: number; items: Array<{row: {content: StoreSkuContent}}>};
  assert.equal(response.productFactsReadbackVersion, 1);
  assert.deepEqual(response.items[0]!.row.content.productFacts, facts);
  await assert.rejects(subject(repository).publicCatalogue({...request, productFactsReadbackVersion: 2}), {code: 'invalid_input'});
});
test('LF-FACTS retry retains original facts and rejects changed payload with the same key', async () => {
  const repository = new Memory(), value = input(), facts = descriptiveFacts();
  Object.assign(value.content, {productFacts: facts});
  const service = subject(repository), request = save(value);
  const original = await service.saveSku('owner-one', request);
  const replay = await service.saveSku('owner-one', structuredClone(request));
  assert.deepEqual(replay, original);
  facts.composition = 'Changed after original dispatch';
  await assert.rejects(service.saveSku('owner-one', request), {code: 'conflict'});
  assert.equal(repository.records.get('store-one/sku-one')!.content.productFacts!.composition, 'Host ingredients');
});
test('LF-PAGER public opt-in supplies stable query snapshot and listing counts', async () => {
  const repository = new ViewMemory(), value = input();
  repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku('owner-one', save(value));
  const result = await subject(repository).publicCatalogue({storeId: 'store-one', cataloguePageVersion: 1,
    query: viewQuery, pageSize: 10}) as {state: string; page: {totalCount: number; startIndex: number; snapshotId: string}};
  assert.equal(result.state, 'ready'); assert.equal(result.page.totalCount, 1);
  assert.equal(result.page.startIndex, 0); assert.match(result.page.snapshotId, /^[a-f0-9]{64}$/u);
});
async function viewRepository(count = 3) {
  const repository = new ViewMemory();
  repository.aggregate = produceAll().aggregate;
  const original = structuredClone(repository.aggregate.offers[0]!);
  repository.aggregate = {...repository.aggregate, offers: []};
  for (let i = 0; i < count; i++) {
    const value = input(`sku-${String(i).padStart(3, '0')}`);
    value.channels[0]!.priceMinor = 26000 - i * 100;
    value.channels[0]!.offerId = `offer-${i}`;
    repository.aggregate = {...repository.aggregate, offers: [...repository.aggregate.offers,
      {...structuredClone(original), offerId: value.channels[0]!.offerId,
      termWindows: original.termWindows.map(window => ({...window,
        termSnapshotSha256: cataloguePayloadHash(channelTerms(value.channels[0]!))}))}]};
    await subject(repository).saveSku('owner-one', save(value));
  }
  return repository;
}
type ViewResult = {state: string; items: Array<{channel: string; row: {skuId: string}}>;
  page: {snapshotId: string; totalCount: number; startIndex: number; nextCursor: string | null; previousCursor: string | null}};
const viewRequest = (extra: Record<string, unknown> = {}) => ({storeId: 'store-one', cataloguePageVersion: 1,
  query: viewQuery, pageSize: 1, ...extra});
class DiscoveryMemory extends ViewMemory {
  directoryOverride?: unknown[];
  async publicDiscoveryBindings() {
    return structuredClone(this.directoryOverride ?? [...this.records.values()]
      .flatMap(record => cataloguePublicListingBindings(this.realm, record))) as ReturnType<typeof cataloguePublicListingBindings>;
  }
}
type DiscoveryResult = {state: string; orderingAvailable: boolean; items: Array<{channel: string;
  listing: {storeId: string; items: Array<{skuId: string; channels: StoreSkuChannel[]}>}}>;
  page: {snapshotId: string; totalCount: number; startIndex: number; nextCursor: string | null; previousCursor: string | null}};
const discoveryRequest = (extra: Record<string, unknown> = {}) => ({discoveryPageVersion: 1,
  query: {...viewQuery, sort: 'priceLowToHigh'}, pageSize: 1, ...extra});
async function discoveryFixture() {
  const repository = new DiscoveryMemory();
  repository.stores.set('store-two', {...profile, workspaceId: 'store-two', caseId: 'case-two', name: 'Host fixture second Store'});
  repository.aggregate = produceAll().aggregate;
  const second = input('sku-two'); second.channels[0]!.offerId = 'offer-two'; second.channels[0]!.priceMinor = 10025;
  const firstOffer = repository.aggregate.offers[0]!;
  repository.aggregate = {...repository.aggregate, offers: [...repository.aggregate.offers, {...firstOffer,
    offerId: 'offer-two', workspaceId: 'store-two', termWindows: firstOffer.termWindows.map(window => ({...window,
      termSnapshotSha256: cataloguePayloadHash(channelTerms(second.channels[0]!))}))}]};
  await subject(repository).saveSku('owner-one', save());
  await subject(repository).saveSku('owner-one', save(second, {storeId: 'store-two'}));
  await subject(repository).saveSku('owner-one', save({...input('private-one'), publicListing: false}));
  const unreviewed = input('unreviewed-one'); unreviewed.content.title = 'Unreviewed private replacement';
  await subject(repository).saveSku('owner-one', save(unreviewed));
  return repository;
}
for (const profileId of ['wholesaler', 'manufacturer']) {
  test(`LF04-PUBLISHERS explicit catalogue and discovery readback ${profileId}`, async () => {
    const repository = await discoveryFixture(), service = subject(repository);
    repository.stores.set('store-two', {...repository.stores.get('store-two')!, profileId});
    const legacy = await service.publicDiscovery(discoveryRequest()) as DiscoveryResult;
    assert.equal(legacy.page.totalCount, 1, 'A validated supplier cannot break or enter the legacy retailer cohort.');
    assert.equal(legacy.items[0]!.listing.storeId, 'store-one');
    assert.equal(Object.hasOwn(legacy, 'supplierPublishersVersion'), false);
    const opted = await service.publicDiscovery(discoveryRequest({supplierPublishersVersion: 1})) as
      DiscoveryResult & {supplierPublishersVersion: number};
    assert.equal(opted.supplierPublishersVersion, 1);
    assert.equal(opted.page.totalCount, 2);
    assert.equal(opted.items[0]!.listing.storeId, 'store-two');
    assert.equal((opted.items[0]!.listing as any).supplierPublishersVersion, 1);
    assert.equal((opted.items[0]!.listing as any).publicStore.profileId, profileId);
    const direct = await service.publicCatalogue({storeId: 'store-two', listingReadbackVersion: 1}) as any;
    assert.equal(direct.state, 'unavailable');
    const checked = await service.publicCatalogue({storeId: 'store-two', listingReadbackVersion: 1,
      supplierPublishersVersion: 1}) as any;
    assert.equal(checked.state, 'ready');
    assert.equal(checked.supplierPublishersVersion, 1);
    assert.equal(checked.publicStore.profileId, profileId);
    assert.equal(checked.items[0].skuId, 'sku-two');
    await assert.rejects(service.publicDiscovery(discoveryRequest({cursor: opted.page.nextCursor})));
    for (const version of [0, 2, '1', null, true]) {
      await assert.rejects(service.publicCatalogue({storeId: 'store-two', supplierPublishersVersion: version}));
      await assert.rejects(service.publicDiscovery(discoveryRequest({supplierPublishersVersion: version})));
    }
    repository.stores.set('store-two', {...repository.stores.get('store-two')!, profileId: `${profileId}-unrecognised`});
    await assert.rejects(service.publicDiscovery(discoveryRequest()), 'Corrupt profiles are not truthful empty coverage.');
  });
}

for (const requested of [false, true]) {
  test(`LF04-PUBLISHERS fresh profile change respects legacy non-listing mode ${requested}`, async () => {
    const repository = await discoveryFixture(), service = subject(repository);
    const page = repository.page.bind(repository);
    repository.page = async (...args) => {
      const rows = await page(...args);
      repository.stores.set('store-one', {...repository.stores.get('store-one')!, profileId: 'wholesaler'});
      return rows;
    };
    const result = await service.publicCatalogue({storeId: 'store-one',
      ...(requested ? {supplierPublishersVersion: 1} : {})}) as any;
    assert.equal(result.state, requested ? 'ready' : 'unavailable');
    if (!requested) assert.deepEqual(result.items, []);
  });
}

for (const profileId of ['wholesaler', 'manufacturer']) {
  test(`LF04-PUBLISHERS actual reviewed supplier persistence and readback ${profileId}`, {
    skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
  }, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
    const app = initializeApp({projectId: `demo-lf-publisher-${randomUUID().slice(0, 8)}`}, `publisher-${randomUUID()}`);
    const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation');
    const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
    const policies = () => new WorkspaceSupplierPolicyService(
      new FirestoreSupplierPolicyRepository(db, 'evaluation', () => new Date(at)), () => new Date(at));
    const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at), policies());
    const promotions = () => new WorkspacePromotionService(
      new FirestorePromotionRepository(db, 'evaluation', () => new Date(at)), service(), () => new Date(at));
    try {
      // Isolated approved-profile/grant fixtures, not native identities or approval actions.
      const liveProfile = {...profile, profileId}, value = input();
      const {aggregate, participant} = produceAll(value, 'brand-host', value.content.categoryId, liveProfile);
      await db.collection('workspaceProfiles').doc(liveProfile.caseId).set(liveProfile);
      await root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId).set(aggregate);
      await root.collection('participants').doc('store-one').set(participant);
      await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
      const original = save(value);
      await assert.rejects(service().saveSku('owner-one', original), {code: 'forbidden'});
      assert.equal((await root.collection('stores').doc('store-one').collection('skus').get()).size, 0);
      const bound = await service().bindReviewedSku('owner-one', original) as any;
      assert.equal(bound.saved.publicListing, true);
      assert.equal((await repository().publicDiscoveryBindings()).length, 1);
      const read = await service().publicCatalogue({storeId: 'store-one', listingReadbackVersion: 1,
        supplierPublishersVersion: 1}) as any;
      assert.equal(read.state, 'ready');
      assert.equal(read.publicStore.profileId, profileId);
      assert.equal(read.items[0].skuId, value.skuId);
      assert.equal((await service().publicDiscovery(discoveryRequest()) as any).page.totalCount, 0);
      const discovered = await service().publicDiscovery(discoveryRequest({supplierPublishersVersion: 1})) as any;
      assert.equal(discovered.page.totalCount, 1);
      assert.equal(discovered.items[0].listing.publicStore.profileId, profileId);
      assert.doesNotMatch(JSON.stringify(discovered), /ownerUserId|sourceRecordId|provenance|producerAuthorities/u);
      const until = new Date(Date.parse(at) + 3600000).toISOString();
      await policies().save('owner-one', {storeId: 'store-one', expectedRevision: 0, idempotencyKey: 'supplier-policy',
        policy: {title: 'Host supplier policy', body: 'Isolated descriptive terms, not payment authority.',
          productIds: [value.skuId], requiresAcceptance: true, validUntil: until}});
      const offerRequest = {storeId: 'store-one', placementId: 'supplier-promotion', expectedRevision: 0,
        idempotencyKey: 'supplier-promotion-original', promotion: {skuId: value.skuId, skuRevision: bound.saved.revision,
          channel: 'retail', headline: 'Host supplier product', detail: 'Descriptive promotion, not applied savings.',
          validFrom: at, validUntil: until, active: true}};
      const promotion = await promotions().save('owner-one', offerRequest);
      assert.deepEqual(await promotions().reconcile('owner-one', offerRequest), promotion);
      const storeOffers = await promotions().publicPage({storeId: 'store-one', limit: 20, supplierPublishersVersion: 1});
      assert.equal(storeOffers.state, 'ready'); assert.equal(storeOffers.items[0]!.publisherType, profileId);
      assert.equal((storeOffers.items[0]!.product.supplierPolicy as any).requiresAcceptance, true);
      const offerQuery = {search: '', categoryId: 'all', publisher: profileId, supplierOnly: true};
      const globalOffers = await promotions().publicDiscovery({promotionDiscoveryVersion: 1, supplierPublishersVersion: 1,
        query: offerQuery, pageSize: 20}) as any;
      assert.equal(globalOffers.page.totalCount, 1);
      assert.equal(globalOffers.items[0].publication.publisherType, profileId);
      const policyRead = await service().publicCatalogue({storeId: 'store-one', listingReadbackVersion: 1,
        policyReadbackVersion: 1, supplierPublishersVersion: 1}) as any;
      assert.equal(policyRead.items[0].supplierPolicy.requiresAcceptance, true);
      console.info(`LF04_SUPPLIER_PROJECTION=${JSON.stringify({profileId, catalogue: policyRead,
        discovery: discovered, storeOffers, globalOffers})}`);
      await root.collection('producerAuthorities').doc('owner-one').delete();
      assert.deepEqual(await service().reconcileBinding('owner-one', original), bound,
        'Original owned receipt recovery must not create renewed publication authority.');
      const changed = {...value, channels: value.channels.map(c => ({...c, priceMinor: 25000}))};
      await assert.rejects(service().bindReviewedSku('owner-one', save(changed,
        {expectedRevision: 1, idempotencyKey: 'supplier-no-authority'})));
      const hidden = {...value, publicListing: false};
      await service().bindReviewedSku('owner-one', save(hidden,
        {expectedRevision: 1, idempotencyKey: 'supplier-withdraw'}));
      assert.equal((await service().publicDiscovery(discoveryRequest({supplierPublishersVersion: 1})) as any).page.totalCount, 0);
      assert.equal((await promotions().publicDiscovery({promotionDiscoveryVersion: 1, supplierPublishersVersion: 1,
        query: offerQuery, pageSize: 20}) as any).page.totalCount, 0);
    } finally {
      await db.terminate();
      await deleteApp(app);
    }
  });
}

test('LF04-PUBLISHERS legacy retailer page cursors cannot cross negotiated modes', async () => {
  const repository = await viewRepository(), service = subject(repository);
  const legacy = await service.publicCatalogue(viewRequest()) as ViewResult;
  assert.ok(legacy.page.nextCursor);
  const opted = await service.publicCatalogue(viewRequest({supplierPublishersVersion: 1})) as
    ViewResult & {supplierPublishersVersion: number};
  assert.equal(opted.supplierPublishersVersion, 1);
  assert.equal(opted.page.totalCount, legacy.page.totalCount);
  await assert.rejects(service.publicCatalogue(viewRequest({supplierPublishersVersion: 1,
    cursor: legacy.page.nextCursor})), {code: 'stale_cursor'});
  await assert.rejects(service.publicCatalogue(viewRequest({cursor: opted.page.nextCursor})), {code: 'stale_cursor'});
});

test('LF-DISCOVERY two Stores exact paise filters deterministic pages and isolated public envelopes', async () => {
  const repository = await discoveryFixture(), service = subject(repository);
  const first = await service.publicDiscovery(discoveryRequest()) as DiscoveryResult;
  assert.equal(first.page.totalCount, 2); assert.equal(first.orderingAvailable, false);
  assert.equal(first.items[0]!.listing.storeId, 'store-two');
  assert.equal(first.items[0]!.listing.items[0]!.channels[0]!.priceMinor, 10025);
  const second = await service.publicDiscovery(discoveryRequest({cursor: first.page.nextCursor})) as DiscoveryResult;
  assert.equal(second.page.snapshotId, first.page.snapshotId); assert.equal(second.page.startIndex, 1);
  assert.equal(second.items[0]!.listing.storeId, 'store-one'); assert.equal(second.page.nextCursor, null);
  const previous = await service.publicDiscovery(discoveryRequest({cursor: second.page.previousCursor})) as DiscoveryResult;
  assert.deepEqual(previous.items, first.items);
  assert.doesNotMatch(JSON.stringify(first), /ownerUserId|sourceRecordId|provenance|unreviewed-one|private-one|Unreviewed private/);
  const filtered = await service.publicDiscovery(discoveryRequest({query: {...viewQuery, maximumPriceMinor: 10025}})) as DiscoveryResult;
  assert.equal(filtered.page.totalCount, 1); assert.equal(filtered.items[0]!.listing.storeId, 'store-two');
  const empty = await service.publicDiscovery(discoveryRequest({query: {...viewQuery, search: 'absent'}})) as DiscoveryResult;
  assert.equal(empty.page.totalCount, 0); assert.equal(empty.page.nextCursor, null); assert.deepEqual(empty.items, []);
});
for (const change of ['withdrawn', 'unreviewed', 'closed', 'expired']) {
  test(`LF-DISCOVERY refresh excludes ${change} despite retained directory identity`, async () => {
    const repository = await discoveryFixture();
    const directory = await repository.publicDiscoveryBindings(); repository.directoryOverride = directory;
    if (change === 'withdrawn') repository.records.get('store-two/sku-two')!.publicListing = false;
    if (change === 'unreviewed') repository.records.get('store-two/sku-two')!.content.title = 'Changed without review';
    if (change === 'closed') repository.stores.set('store-two', {...repository.stores.get('store-two')!, shopEnabled: false});
    if (change === 'expired') repository.aggregate = {...repository.aggregate!, offers: repository.aggregate!.offers.map(offer =>
      offer.workspaceId === 'store-two' ? {...offer, termWindows: offer.termWindows.map(window => ({...window, expiresAt: at}))} : offer)};
    const result = await subject(repository).publicDiscovery(discoveryRequest({pageSize: 50})) as DiscoveryResult;
    assert.equal(result.page.totalCount, 1); assert.equal(result.items[0]!.listing.storeId, 'store-one');
    assert.equal((await repository.publicDiscoveryBindings()).length, directory.length);
  });
}
test('LF-DISCOVERY strict identity capacity and cursor binding never produce false complete pages', async () => {
  for (const kind of ['realm', 'listingId', 'duplicate', 'capacity']) {
    const repository = await discoveryFixture(), bindings = await repository.publicDiscoveryBindings();
    repository.directoryOverride = kind === 'duplicate' ? [...bindings, bindings[0]!] : kind === 'capacity'
      ? Array(501).fill(bindings[0]) : bindings.map((row, i) => i ? row : {...row, [kind]: 'foreign'});
    await assert.rejects(subject(repository).publicDiscovery(discoveryRequest()), Error, kind);
  }
  const repository = await discoveryFixture(), service = subject(repository);
  const first = await service.publicDiscovery(discoveryRequest()) as DiscoveryResult;
  for (const extra of [{pageSize: 2}, {query: {...viewQuery, search: 'oil'}}]) {
    await assert.rejects(service.publicDiscovery(discoveryRequest({...extra, cursor: first.page.nextCursor})), {code: 'stale_cursor'});
  }
  repository.records.get('store-one/sku-one')!.publicListing = false;
  await assert.rejects(service.publicDiscovery(discoveryRequest({cursor: first.page.nextCursor})), {code: 'stale_cursor'});
  for (const request of [{discoveryPageVersion: 2}, {query: {...viewQuery, quick: true}},
    {query: {...viewQuery, sort: 'deliveryFastest'}}, {resultKind: 'unsupported'}, {resultKind: null}]) {
    await assert.rejects(service.publicDiscovery(discoveryRequest(request)), {code: 'invalid_input'});
  }
});
test('LF-DISCOVERY Store pager counts each matched Store once and binds kind and exact Store filter', async () => {
  const repository = await discoveryFixture(), service = subject(repository);
  await service.saveSku('owner-one', save(input('another-public-sku')));
  const products = await service.publicDiscovery(discoveryRequest()) as DiscoveryResult;
  assert.equal(products.page.totalCount, 3);
  const first = await service.publicDiscovery(discoveryRequest({resultKind: 'stores'})) as DiscoveryResult;
  assert.equal(first.page.totalCount, 2); assert.equal(first.items[0]!.listing.storeId, 'store-two');
  const second = await service.publicDiscovery(discoveryRequest({resultKind: 'stores', cursor: first.page.nextCursor})) as DiscoveryResult;
  assert.equal(second.items[0]!.listing.storeId, 'store-one'); assert.equal(second.page.nextCursor, null);
  await assert.rejects(service.publicDiscovery(discoveryRequest({cursor: first.page.nextCursor})), {code: 'stale_cursor'});
  await assert.rejects(service.publicDiscovery(discoveryRequest({storeId: 'store-one', cursor: products.page.nextCursor})), {code: 'stale_cursor'});
  const scoped = await service.publicDiscovery(discoveryRequest({storeId: 'store-one', pageSize: 50})) as DiscoveryResult;
  assert.equal(scoped.page.totalCount, 2); assert.ok(scoped.items.every(item => item.listing.storeId === 'store-one'));
  const missing = await service.publicDiscovery(discoveryRequest({storeId: 'not-published'})) as DiscoveryResult;
  assert.equal(missing.page.totalCount, 0);
});
test('LF-DISCOVERY hidden source mutation and temporal expiry reject stale snapshots', async () => {
  const repository = await discoveryFixture();
  repository.onSourceRead = read => { if (read === 1) repository.records.get('store-one/private-one')!.revision++; };
  await assert.rejects(subject(repository).publicDiscovery(discoveryRequest()), {code: 'stale_snapshot'});
  const clean = await discoveryFixture(); let clockReads = 0;
  const service = new WorkspaceCatalogueService(clean, catalogueIdentity,
    () => new Date(++clockReads === 1 ? at : '2026-10-16T14:00:00.000Z'));
  await assert.rejects(service.publicDiscovery(discoveryRequest()), {code: 'stale_snapshot'});
});
test('LF-DISCOVERY unresolved canonical source is unavailable not a complete empty catalogue', async () => {
  const repository = await discoveryFixture();
  delete repository.aggregate;
  await assert.rejects(subject(repository).publicDiscovery(discoveryRequest()), {code: 'unavailable'});
});
test('LF-DISCOVERY directory insertion during confirmed source reread cannot escape complete coverage', async () => {
  const repository = await discoveryFixture();
  repository.directoryOverride = await repository.publicDiscoveryBindings();
  repository.onSourceRead = read => {
    if (read === 3) repository.directoryOverride!.push(cataloguePublicListingBindings('evaluation',
      {...input('later-one'), schemaVersion: 1, storeId: 'store-later', revision: 1, observedAt: at})[0]!);
  };
  await assert.rejects(subject(repository).publicDiscovery(discoveryRequest()), {code: 'stale_snapshot'});
});
test('LF-DISCOVERY emulator actual trusted production binding restart discovery and withdrawal',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
    const app = initializeApp({projectId: `demo-lf03-discovery-${randomUUID().slice(0, 8)}`}, `discovery-${randomUUID()}`);
    const db = getFirestore(app), root = db.collection('workspaceCatalogues').doc('evaluation');
    const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
    const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
    try {
      await db.collection('workspaceProfiles').doc(profile.caseId).set(profile);
      await root.collection('participants').doc('store-one').set(producerParticipant());
      await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority());
      await root.collection('producerAuthorities').doc('reviewer-one').set(producerAuthority(false));
      for (const command of productionCommands()) {
        const owner = ['propose_product', 'propose_pack', 'create_offer'].includes(String(command.type));
        await repository().produceCatalogue(owner ? 'owner-one' : 'reviewer-one', catalogueIdentity, command);
      }
      await service().bindReviewedSku('owner-one', save());
      const secondProfile = {...profile, caseId: 'case-two', workspaceId: 'store-two', name: 'Second produced Store'};
      const second = input('sku-two'); second.channels[0]!.offerId = 'offer-two'; second.channels[0]!.priceMinor = 10025;
      await db.collection('workspaceProfiles').doc(secondProfile.caseId).set(secondProfile);
      await root.collection('participants').doc('store-two').set(producerParticipant('store-two'));
      await root.collection('producerAuthorities').doc('owner-one').set(producerAuthority(true, 'store-two'));
      await repository().produceCatalogue('owner-one', catalogueIdentity,
        {...productionCommands(second).at(-1)!, commandId: 'producer-second-offer', expectedVersion: 6});
      await service().bindReviewedSku('owner-one', save(second, {storeId: 'store-two'}));
      await service().saveSku('owner-one', save({...input('private-one'), publicListing: false}));
      const unreviewed = input('unreviewed-one'); unreviewed.content.description = 'Not approved for publication';
      await service().saveSku('owner-one', save(unreviewed));
      const first = await service().publicDiscovery(discoveryRequest({pageSize: 50})) as DiscoveryResult;
      assert.equal(first.page.totalCount, 2); assert.equal(first.items[0]!.listing.storeId, 'store-two');
      assert.equal(first.items[0]!.listing.items[0]!.channels[0]!.priceMinor, 10025);
      assert.deepEqual(await service().publicDiscovery(discoveryRequest({pageSize: 50})), first);
      assert.equal((await repository().publicDiscoveryBindings()).length, 4);
      assert.deepEqual(await new FirestoreWorkspaceCatalogueRepository(db, 'production').publicDiscoveryBindings(), []);
      console.log(`LF_DISCOVERY_PROJECTION=${JSON.stringify(first)}`); // Isolated emulator response for the actual Dart decoder.
      await service().bindReviewedSku('owner-one', save({...second, publicListing: false}, {
        storeId: 'store-two', expectedRevision: 1, idempotencyKey: 'withdraw-second'}));
      const refreshed = await service().publicDiscovery(discoveryRequest({pageSize: 50})) as DiscoveryResult;
      assert.equal(refreshed.page.totalCount, 1); assert.equal(refreshed.items[0]!.listing.storeId, 'store-one');
      assert.equal((await repository().publicDiscoveryBindings()).length, 4);
      await root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId).update({tenantId: 'foreign-tenant'});
      await assert.rejects(service().publicDiscovery(discoveryRequest()), {code: 'unavailable'});
    } finally { await db.terminate(); await deleteApp(app); }
  });
const publicDetails = {street: 'Host building, market road', city: 'Jodhpur', state: 'Rajasthan', pinCode: '342003',
  publicContactPhone: '+91 90000 00001', openingTime: '09:00', closingTime: '9:00 PM'};
const detailsRequest = (extra: Record<string, unknown> = {}) => ({storeId: 'store-one', expectedRevision: 0,
  idempotencyKey: 'details-original-one', details: publicDetails, ...extra});

test('LF-CLASS published descriptive business type preserves legacy bytes and original recovery', async () => {
  const repository = await viewRepository(1), service = subject(repository);
  const legacy = await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest()) as {record: StorePublicDetailsRecord};
  assert.deepEqual(legacy.record.details, publicDetails);
  const request = detailsRequest({storeClassificationReadbackVersion: 1, expectedRevision: 1,
    idempotencyKey: 'classification-one', details: {...publicDetails, businessType: 'manufacturer'}});
  const saved = await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', request) as {record: StorePublicDetailsRecord; storeClassificationReadbackVersion: number};
  assert.equal(saved.storeClassificationReadbackVersion, 1);
  assert.deepEqual(saved.record.details, {...publicDetails, businessType: 'manufacturer'});
  assert.deepEqual((await service.handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', request) as {record: unknown}).record, saved.record);
  assert.deepEqual((await service.handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', detailsRequest()) as {record: unknown}).record, legacy.record);
  await assert.rejects(service.handleStorePublicDetails('owner-one', 'readStorePublicDetails', {storeId: 'store-one'}), {code: 'unsupported_version'});
  await assert.rejects(service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({expectedRevision: 2,
    idempotencyKey: 'old-writer'})), {code: 'invalid_input'});
  assert.deepEqual(repository.details.get('store-one')!.details, saved.record.details);
  const oldPublic = await service.publicCatalogue({storeId: 'store-one', listingReadbackVersion: 1, storeDetailsReadbackVersion: 1}) as
    {publicStore: {details: {details: object}}};
  assert.deepEqual(oldPublic.publicStore.details.details, publicDetails);
  const current = await service.publicCatalogue({storeId: 'store-one', listingReadbackVersion: 1, storeDetailsReadbackVersion: 1,
    storeClassificationReadbackVersion: 1}) as {storeClassificationReadbackVersion: number; publicStore: {details: {details: object}}};
  assert.equal(current.storeClassificationReadbackVersion, 1);
  assert.deepEqual(current.publicStore.details.details, saved.record.details);
  const paged = await service.publicCatalogue(viewRequest({storeDetailsReadbackVersion: 1,
    storeClassificationReadbackVersion: 1})) as {publicStore: {details: {details: object}}};
  assert.deepEqual(paged.publicStore.details.details, saved.record.details);
  await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({storeClassificationReadbackVersion: 1,
    expectedRevision: 2, idempotencyKey: 'explicit-hide', details: {...publicDetails, businessType: ''}}));
  assert.deepEqual(repository.details.get('store-one')!.details, {...publicDetails, businessType: ''});
});

test('LF-CLASS rejects malformed roles, capability markers and unnegotiated enrichment', async () => {
  const service = subject(new Memory());
  for (const businessType of ['Manufacturer', ' manufacturer', 'delivery-operator', null, 1, {}, true]) {
    await assert.rejects(service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({
      storeClassificationReadbackVersion: 1, details: {...publicDetails, businessType}})), {code: 'invalid_input'});
  }
  for (const marker of ['1', true, 2, null]) {
    await assert.rejects(service.handleStorePublicDetails('owner-one', 'readStorePublicDetails', {
      storeId: 'store-one', storeClassificationReadbackVersion: marker}), {code: 'invalid_input'});
  }
  await assert.rejects(service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({
    details: {...publicDetails, businessType: 'supplier'}})), {code: 'invalid_input'});
  assert.deepEqual(normalizeStorePublicDetails(publicDetails), publicDetails);
});
test('LF-METADATA owner API saves only descriptive public fields and distinguishes original recovery', async () => {
  const repository = new ViewMemory(), service = subject(repository);
  const empty = await service.handleStorePublicDetails('owner-one', 'readStorePublicDetails', {storeId: 'store-one'}) as {record: unknown};
  assert.equal(empty.record, null);
  const first = await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest()) as
    {record: StorePublicDetailsRecord; locationVerified: boolean; publicAvailabilityConfirmed: boolean};
  assert.equal(first.record.revision, 1); assert.deepEqual(first.record.details, publicDetails);
  assert.equal(first.locationVerified, false); assert.equal(first.publicAvailabilityConfirmed, false);
  await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({expectedRevision: 1,
    idempotencyKey: 'details-next', details: {...publicDetails, publicContactPhone: ''}}));
  const replay = await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest()) as {record: unknown};
  const original = await service.handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', detailsRequest()) as {record: unknown};
  assert.deepEqual(replay.record, first.record); assert.deepEqual(original.record, first.record);
  assert.equal(repository.details.get('store-one')!.revision, 2);
  const absent = await service.handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', detailsRequest({idempotencyKey: 'missing-original'})) as {record: unknown};
  assert.equal(absent.record, null);
  await assert.rejects(service.handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', detailsRequest({details: {...publicDetails, city: 'Changed'}})), {code: 'conflict'});
  await assert.rejects(service.handleStorePublicDetails('other-owner', 'readStorePublicDetails', {storeId: 'store-one'}), {code: 'not_found'});
});
test('LF-METADATA never accepts private settings or invented location and operating claims', async () => {
  const service = subject(new Memory());
  for (const patch of [{pan: 'PRIVATE'}, {billingAddress: 'PRIVATE'}, {customerPaymentTerms: {}},
    {regionId: 'invented-region'}, {locationVerified: true}, {openNow: true},
    {street: ''}, {city: ''}, {pinCode: '000001'}, {publicContactPhone: 'not a phone'},
    {openingTime: '25:00'}, {closingTime: ''}, {openingTime: 900}, {state: ['Rajasthan']}]) {
    await assert.rejects(service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails',
      detailsRequest({details: {...publicDetails, ...patch}})), {code: 'invalid_input'});
  }
  assert.deepEqual(normalizeStorePublicDetails({...publicDetails, publicContactPhone: '', openingTime: '', closingTime: ''}),
    {...publicDetails, publicContactPhone: '', openingTime: '', closingTime: ''});
});
test('LF-METADATA same revision and changed authority cannot replace public head', async () => {
  const repository = new Memory(), service = subject(repository);
  const results = await Promise.allSettled(['one', 'two'].map(idempotencyKey =>
    service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({idempotencyKey: `request-${idempotencyKey}`}))));
  assert.equal(results.filter(result => result.status === 'fulfilled').length, 1);
  assert.equal((results.find(result => result.status === 'rejected') as PromiseRejectedResult).reason.code, 'revision_conflict');
  repository.stores.set('store-one', {...profile, status: 'suspended'});
  await assert.rejects(service.handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', detailsRequest()), {code: 'invalid_state'});
});
test('LF-METADATA public opt-in preserves legacy shape without verification or private data leakage', async () => {
  const repository = await viewRepository(1), service = subject(repository);
  await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest());
  const legacy = await service.publicCatalogue({storeId: 'store-one', listingReadbackVersion: 1}) as {publicStore: object};
  assert.deepEqual(Object.keys(legacy.publicStore).sort(), ['id', 'name', 'profileId']);
  const data = await service.publicCatalogue({storeId: 'store-one', listingReadbackVersion: 1, storeDetailsReadbackVersion: 1}) as
    {publicStore: {name: string; details: {state: string; revision: number; details: object; locationVerified: boolean}}};
  assert.equal(data.publicStore.name, profile.name); assert.equal(data.publicStore.details.state, 'ready');
  assert.equal(data.publicStore.details.revision, 1); assert.equal(data.publicStore.details.locationVerified, false);
  assert.deepEqual(data.publicStore.details.details, publicDetails);
});
test('LF-METADATA changed metadata invalidates page cursor while read timestamps do not', async () => {
  const repository = await viewRepository(), clock = {at};
  const service = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(clock.at));
  await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest());
  const request = viewRequest({storeDetailsReadbackVersion: 1});
  const first = await service.publicCatalogue(request) as ViewResult;
  clock.at = '2026-10-16T12:00:01.000Z';
  const second = await service.publicCatalogue({...request, cursor: first.page.nextCursor}) as ViewResult;
  assert.equal(second.page.snapshotId, first.page.snapshotId);
  await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({expectedRevision: 1,
    idempotencyKey: 'changed-metadata', details: {...publicDetails, street: 'New host building'}}));
  await assert.rejects(service.publicCatalogue({...request, cursor: first.page.nextCursor}), {code: 'stale_cursor'});
});
test('LF-METADATA final exact-SKU confirmation rejects a header changed during its read', async () => {
  class ChangedDetails extends ViewMemory {
    override async readStorePublicDetails(storeId: string) {
      const result = await super.readStorePublicDetails(storeId);
      this.details.set(storeId, {...result!, revision: 2, details: {...result!.details, city: 'Changed'}});
      return result;
    }
  }
  const repository = new ChangedDetails(), service = subject(repository);
  repository.aggregate = produceAll().aggregate; await service.saveSku('owner-one', save());
  await service.handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest());
  const result = await service.publicCatalogue({storeId: 'store-one', listingReadbackVersion: 1, storeDetailsReadbackVersion: 1}) as {state: string; items: unknown[]};
  assert.equal(result.state, 'unavailable'); assert.deepEqual(result.items, []);
});
test('LF-METADATA emulator persists original receipts and CAS across repository restart without granting public availability',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
    const app = initializeApp({projectId: 'demo-lf03-public-details'}, `public-details-${randomUUID()}`);
    const db = getFirestore(app), storeId = `store-${randomUUID()}`, caseId = `case-${randomUUID()}`;
    const profiles = db.collection('workspaceProfiles'), root = db.collection('workspaceCatalogues').doc('evaluation');
    const repository = (realm: 'evaluation' | 'production' = 'evaluation') => new FirestoreWorkspaceCatalogueRepository(db, realm);
    const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
    try {
      await profiles.doc(caseId).set({...profile, workspaceId: storeId, caseId});
      const originalRequest = detailsRequest({storeId});
      const first = await service().handleStorePublicDetails('owner-one', 'saveStorePublicDetails', originalRequest) as
        {record: StorePublicDetailsRecord; idempotencyKey: string; publicAvailabilityConfirmed: boolean};
      assert.equal(first.idempotencyKey, originalRequest.idempotencyKey); assert.equal(first.publicAvailabilityConfirmed, false);
      const current = await repository().readStorePublicDetails(storeId, 'owner-one');
      assert.deepEqual(current, first.record); assert.deepEqual(await repository().readStorePublicDetails(storeId), first.record);
      assert.equal(await repository('production').readStorePublicDetails(storeId, 'owner-one'), undefined);
      await service().handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({storeId,
        expectedRevision: 1, idempotencyKey: 'second-save', details: {...publicDetails, city: 'Updated city'}}));
      const recovered = await service().handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', originalRequest) as {record: unknown};
      assert.deepEqual(recovered.record, first.record); assert.equal((await repository().readStorePublicDetails(storeId, 'owner-one'))!.revision, 2);
      const concurrent = await Promise.allSettled(['one', 'two'].map(value => service().handleStorePublicDetails('owner-one',
        'saveStorePublicDetails', detailsRequest({storeId, expectedRevision: 2, idempotencyKey: `concurrent-${value}`,
          details: {...publicDetails, street: `Building ${value}`}}))));
      assert.equal(concurrent.filter(result => result.status === 'fulfilled').length, 1);
      const all = await root.collection('stores').doc(storeId).collection('publicDetails').doc('current').collection('revisions').get();
      assert.equal(all.size, 3);
      await assert.rejects(repository().readStorePublicDetails(storeId, 'other-owner'), {code: 'not_found'});
      await profiles.doc(caseId).update({shopEnabled: false});
      await assert.rejects(repository().readStorePublicDetails(storeId), {code: 'not_found'});
      assert.equal((await repository().readStorePublicDetails(storeId, 'owner-one'))!.revision, 3);
      await profiles.doc(caseId).update({status: 'suspended'});
      await assert.rejects(service().handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', originalRequest), {code: 'invalid_state'});
    } finally { await db.terminate(); await deleteApp(app); }
  });
test('LF-METADATA emulator exact original retry races late dispatch without duplicate revision or rollback',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
    const app = initializeApp({projectId: 'demo-lf03-public-details-race'}, `details-race-${randomUUID()}`);
    const db = getFirestore(app), storeId = `store-${randomUUID()}`, caseId = `case-${randomUUID()}`;
    let release!: () => void, entered!: () => void;
    const held = new Promise<void>(resolve => { release = resolve; });
    const dispatched = new Promise<void>(resolve => { entered = resolve; });
    class DelayedOriginal extends FirestoreWorkspaceCatalogueRepository {
      override async saveStorePublicDetails(original: StorePublicDetailsCommand) {
        entered(); await held; return super.saveStorePublicDetails(original);
      }
    }
    const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation');
    const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
    let originalPending: Promise<unknown> | undefined;
    try {
      await db.collection('workspaceProfiles').doc(caseId).set({...profile, workspaceId: storeId, caseId});
      const request = detailsRequest({storeId});
      originalPending = new WorkspaceCatalogueService(new DelayedOriginal(db, 'evaluation'), catalogueIdentity, () => new Date(at))
        .handleStorePublicDetails('owner-one', 'saveStorePublicDetails', request);
      await dispatched;
      const absent = await service().handleStorePublicDetails('owner-one', 'reconcileStorePublicDetails', request) as {record: unknown};
      assert.equal(absent.record, null); // Not evidence the still-running original cannot commit.
      const retry = await service().handleStorePublicDetails('owner-one', 'saveStorePublicDetails', request) as {record: StorePublicDetailsRecord};
      release();
      const late = await originalPending as {record: StorePublicDetailsRecord};
      assert.deepEqual(late.record, retry.record); assert.equal(retry.record.revision, 1);
      const head = db.collection('workspaceCatalogues').doc('evaluation').collection('stores').doc(storeId)
        .collection('publicDetails').doc('current');
      assert.equal((await head.collection('revisions').get()).size, 1);
      await service().handleStorePublicDetails('owner-one', 'saveStorePublicDetails', detailsRequest({storeId,
        expectedRevision: 1, idempotencyKey: 'newer-head', details: {...publicDetails, street: 'Newer saved address'}}));
      const replay = await service().handleStorePublicDetails('owner-one', 'saveStorePublicDetails', request) as {record: StorePublicDetailsRecord};
      assert.deepEqual(replay.record, retry.record);
      assert.equal((await repository().readStorePublicDetails(storeId, 'owner-one'))!.revision, 2);
    } finally { release(); await originalPending?.catch(() => undefined); await db.terminate(); await deleteApp(app); }
  });

test('LF-PAGER filters sorts counts and navigates both directions within one snapshot', async () => {
  const repository = await viewRepository(), service = subject(repository);
  const query = {...viewQuery, sort: 'priceLowToHigh', maximumPriceMinor: 25900};
  const first = await service.publicCatalogue(viewRequest({query})) as ViewResult;
  assert.equal(first.page.totalCount, 2); assert.equal(first.items[0]!.row.skuId, 'sku-002');
  const second = await service.publicCatalogue(viewRequest({query, cursor: first.page.nextCursor})) as ViewResult;
  assert.equal(second.page.snapshotId, first.page.snapshotId); assert.equal(second.page.startIndex, 1);
  assert.equal(second.items[0]!.row.skuId, 'sku-001'); assert.equal(second.page.nextCursor, null);
  const previous = await service.publicCatalogue(viewRequest({query, cursor: second.page.previousCursor})) as ViewResult;
  assert.equal(previous.items[0]!.row.skuId, 'sku-002');
  const none = await service.publicCatalogue(viewRequest({query: {...viewQuery, search: 'absent'}})) as ViewResult;
  assert.equal(none.page.totalCount, 0); assert.equal(none.page.nextCursor, null); assert.deepEqual(none.items, []);
});
test('LF-PAGER channel listings and exact-ID resolution preserve one original Store SKU', async () => {
  const repository = await viewRepository(1), record = repository.records.get('store-one/sku-000')!;
  const channel = {...record.channels[0]!, kind: 'wholesale' as const, offerId: 'trade-offer', minimumOrder: 10};
  record.channels.push(channel);
  const offer = repository.aggregate!.offers[0]!;
  repository.aggregate = {...repository.aggregate!, offers: [...repository.aggregate!.offers,
    {...offer, offerId: channel.offerId, buyingContext: 'wholesale', termWindows: offer.termWindows.map(window => ({...window,
      termSnapshotSha256: cataloguePayloadHash(channelTerms(channel))}))}]};
  const service = subject(repository);
  const retail = await service.publicCatalogue(viewRequest()) as ViewResult;
  const trade = await service.publicCatalogue(viewRequest({query: {...viewQuery, destination: 'wholesale', tradeType: 'wholesale'}})) as ViewResult;
  assert.equal(retail.page.totalCount, 1); assert.equal(trade.page.totalCount, 1);
  assert.equal(retail.items[0]!.row.skuId, trade.items[0]!.row.skuId);
  assert.equal(trade.items[0]!.channel, 'wholesale'); assert.equal(repository.records.size, 1);
  const originalBinding = cataloguePublicListingBindings('evaluation', record).find(value => value.channel === 'retail')!;
  const resolved = await service.publicCatalogue(viewRequest({query: {...viewQuery, listingIds: [originalBinding.listingId]}})) as ViewResult;
  assert.equal(resolved.items[0]!.row.skuId, originalBinding.skuId);
  const absent = await service.publicCatalogue(viewRequest({query: {...viewQuery, listingIds: [`listing-${'f'.repeat(64)}`]}})) as ViewResult;
  assert.equal(absent.page.totalCount, 0);
});
test('LF-PAGER cursor cannot cross query page size Store snapshot or validity window', async () => {
  const repository = await viewRepository(), service = subject(repository);
  const first = await service.publicCatalogue(viewRequest()) as ViewResult;
  for (const extra of [{query: {...viewQuery, search: 'oil'}}, {pageSize: 2}]) {
    await assert.rejects(service.publicCatalogue(viewRequest({...extra, cursor: first.page.nextCursor})), {code: 'stale_cursor'});
  }
  for (const cursor of ['not-a-cursor', Buffer.from('{}').toString('base64url')]) {
    await assert.rejects(service.publicCatalogue(viewRequest({cursor})), {code: 'invalid_input'});
  }
  repository.records.get('store-one/sku-002')!.publicListing = false;
  await assert.rejects(service.publicCatalogue(viewRequest({cursor: first.page.nextCursor})), {code: 'stale_cursor'});
  const expired = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date('2026-10-16T13:00:00.000Z'));
  await assert.rejects(expired.publicCatalogue(viewRequest({cursor: first.page.nextCursor})), {code: 'stale_cursor'});
});
for (const change of ['insert', 'excluded becomes public', 'private facts', 'policy']) {
  test(`LF-PAGER final read detects whole-candidate change: ${change}`, async () => {
    const repository = await viewRepository();
    const hidden = {...structuredClone(repository.records.get('store-one/sku-000')!), skuId: 'hidden-one', publicListing: false};
    repository.records.set('store-one/hidden-one', hidden);
    repository.onSourceRead = read => {
      if (read !== 1) return;
      if (change === 'insert') repository.records.set('store-one/new-one', {...structuredClone(hidden), skuId: 'new-one'});
      if (change === 'excluded becomes public') hidden.publicListing = true;
      if (change === 'private facts') hidden.revision++;
    };
    if (change === 'policy') {
      const original = repository.publicCatalogueSource.bind(repository);
      repository.publicCatalogueSource = async (...args) => {
        const source = await original(...args);
        return source && repository.sourceReads > 1 ? {...source, policy: {changed: true}} : source;
      };
    }
    await assert.rejects(subject(repository).publicCatalogue(viewRequest()), {code: 'stale_snapshot'});
  });
}
test('LF-PAGER unsupported semantics capacity and monetary precision never become false complete results', async () => {
  const repository = await viewRepository(), service = subject(repository);
  for (const query of [{...viewQuery, sort: 'deliveryFastest'}, {...viewQuery, destination: 'orders'},
    {...viewQuery, quick: true}, {...viewQuery, procurementContext: {storeId: 'store-one'}}]) {
    await assert.rejects(service.publicCatalogue(viewRequest({query})), {code: 'invalid_input'});
  }
  const original = repository.records.get('store-one/sku-000')!;
  for (let i = 0; i < 501; i++) repository.records.set(`store-one/extra-${i}`, {...original, skuId: `extra-${i}`});
  await assert.rejects(service.publicCatalogue(viewRequest()), {code: 'unavailable'});
  const paise = await viewRepository(1), saved = paise.records.get('store-one/sku-000')!;
  saved.channels[0]!.priceMinor = 26001;
  paise.aggregate = {...paise.aggregate!, offers: paise.aggregate!.offers.map(offer => ({...offer,
    termWindows: offer.termWindows.map(window => ({...window,
      termSnapshotSha256: cataloguePayloadHash(channelTerms(saved.channels[0]!))}))}))};
  await assert.rejects(subject(paise).publicCatalogue(viewRequest()), {code: 'unsupported_representation'});
});
for (const field of ['price', 'mrp', 'tier'] as const) test(`LF-MONEY2 exact ${field} is negotiated without loosening legacy money`, async () => {
  const repository = await viewRepository(1), row = repository.records.get('store-one/sku-000')!;
  if (field === 'price') row.channels[0]!.priceMinor = 26001;
  if (field === 'mrp') row.channels[0]!.mrpMinor = 28001;
  if (field === 'tier') row.channels[0]!.tiers = [{minimumQuantity: 1, unitPriceMinor: 26000}, {minimumQuantity: 2, unitPriceMinor: 25999}];
  repository.aggregate = {...repository.aggregate!, offers: repository.aggregate!.offers.map(offer => ({...offer,
    termWindows: offer.termWindows.map(window => ({...window, termSnapshotSha256: cataloguePayloadHash(channelTerms(row.channels[0]!))}))}))};
  await assert.rejects(subject(repository).publicCatalogue(viewRequest()), {code: 'unsupported_representation'});
  const result = await subject(repository).publicCatalogue(viewRequest({cataloguePageVersion: 2})) as any;
  assert.equal(result.cataloguePageVersion, 2); assert.equal(result.moneyUnit, 'paise');
  assert.equal(result.page.totalCount, 1); assert.deepEqual(result.items[0].row.channels[0], {
    ...row.channels[0], revision: 'term-host-one', validUntil: '2026-10-16T13:00:00.000Z'});
});
test('LF-MONEY2 cursor versions never cross while legacy response stays unchanged', async () => {
  const service = subject(await viewRepository(3));
  const old = await service.publicCatalogue(viewRequest({pageSize: 1})) as any;
  const exact = await service.publicCatalogue(viewRequest({cataloguePageVersion: 2, pageSize: 1})) as any;
  assert.equal(Object.hasOwn(old, 'moneyUnit'), false); assert.equal(old.cataloguePageVersion, 1);
  assert.equal(exact.page.totalCount, 3);
  await assert.rejects(service.publicCatalogue(viewRequest({cataloguePageVersion: 2, pageSize: 1, cursor: old.nextCursor})), {code: 'stale_cursor'});
  await assert.rejects(service.publicCatalogue(viewRequest({pageSize: 1, cursor: exact.nextCursor})), {code: 'stale_cursor'});
  const next = await service.publicCatalogue(viewRequest({cataloguePageVersion: 2, pageSize: 1, cursor: exact.nextCursor})) as any;
  assert.equal(next.page.startIndex, 1); assert.equal(next.moneyUnit, 'paise');
  for (const version of ['2', [2], null, 3]) await assert.rejects(service.publicCatalogue(viewRequest({cataloguePageVersion: version})), {code: 'invalid_input'});
});

test('LF-PAGER rejects array-valued query enums instead of coercing them', async () => {
  const repository = await viewRepository(1);
  for (const query of [{...viewQuery, destination: ['shop'], tradeType: 'bulk'},
    {...viewQuery, sort: ['relevance']}, {...viewQuery, destination: 'wholesale', tradeType: ['bulk']}]) {
    await assert.rejects(subject(repository).publicCatalogue(viewRequest({query})), {code: 'invalid_input'});
  }
});
test('LF-PAGER new time-eligible candidate cannot disappear from complete final count', async () => {
  const repository = await viewRepository(1);
  repository.aggregate = {...repository.aggregate!, offers: repository.aggregate!.offers.map(offer => ({...offer,
    termWindows: offer.termWindows.map(window => ({...window, effectiveFrom: '2026-10-16T12:00:00.001Z'}))}))};
  let clock = at;
  repository.onSourceRead = read => { if (read === 2) clock = '2026-10-16T12:00:00.002Z'; };
  const service = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(clock));
  await assert.rejects(service.publicCatalogue(viewRequest()), {code: 'stale_snapshot'});
});
test('LF-PAGER emulator atomic source survives repository restart and includes excluded membership and policy',
  {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
    assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
    const app = initializeApp({projectId: 'demo-lf03-public-pages'}, `public-pages-${randomUUID()}`);
    const db = getFirestore(app), storeId = `store-${randomUUID()}`, caseId = `case-${randomUUID()}`;
    const localProfile = {...profile, workspaceId: storeId, caseId};
    const value = input(), aggregate = produceAll(value).aggregate;
    const root = db.collection('workspaceCatalogues').doc('evaluation');
    const repository = () => new FirestoreWorkspaceCatalogueRepository(db, 'evaluation', () => new Date(at));
    const service = () => new WorkspaceCatalogueService(repository(), catalogueIdentity, () => new Date(at));
    const command = (sku: StoreSkuInput): CatalogueSave => ({ownerUserId: 'owner-one', profile: localProfile,
      input: sku, expectedRevision: 0, idempotencyKey: `save-${sku.skuId}`, observedAt: at,
      fingerprint: cataloguePayloadHash({storeId, input: sku, expectedRevision: 0})});
    try {
      await db.collection('workspaceProfiles').doc(caseId).set(localProfile);
      await root.collection('canonicalCatalogues').doc(catalogueIdentity.catalogueId).set({...aggregate,
        offers: aggregate.offers.map(offer => ({...offer, workspaceId: storeId}))});
      await repository().save(command(value));
      await repository().save(command({...input('hidden-one'), publicListing: false}));
      const source = await repository().publicCatalogueSource(storeId, catalogueIdentity);
      assert.ok(source); assert.equal(source.records.length, 2); assert.equal(source.policy, null);
      assert.deepEqual(await repository().publicCatalogueSource(storeId, catalogueIdentity), source);
      const first = await service().publicCatalogue(viewRequest({storeId})) as ViewResult;
      assert.equal(first.page.totalCount, 1); assert.equal(first.items[0]!.row.skuId, 'sku-one');
      const foreign = await repository().publicCatalogueSource(`foreign-${randomUUID()}`, catalogueIdentity);
      assert.equal(foreign, undefined);
      assert.equal(await new FirestoreWorkspaceCatalogueRepository(db, 'production').publicCatalogueSource(storeId, catalogueIdentity), undefined);
      await root.collection('stores').doc(storeId).collection('supplierPolicies').doc('current').set({privateFixture: 'not-public'});
      const changed = await repository().publicCatalogueSource(storeId, catalogueIdentity);
      assert.notEqual(cataloguePayloadHash(changed), cataloguePayloadHash(source));
      const policyView = await service().publicCatalogue(viewRequest({storeId}));
      assert.equal(JSON.stringify(policyView).includes('privateFixture'), false);
      await root.collection('stores').doc(storeId).collection('skus').doc('hidden-one').update({revision: 2});
      assert.notEqual(cataloguePayloadHash(await repository().publicCatalogueSource(storeId, catalogueIdentity)), cataloguePayloadHash(changed));
    } finally { await db.terminate(); await deleteApp(app); }
  });
test("opt-in public listing readback includes only correlated bindings and public Store metadata", async () => {
  const repository = new BoundMemory(), value = input();
  repository.aggregate = produceAll(value).aggregate;
  await subject(repository).saveSku("owner-one", save(value));
  const result = await subject(repository).publicCatalogue({storeId: "store-one", listingReadbackVersion: 1}) as
    {state: string; listingCoverage: string; publicStore: unknown; orderingAvailable: boolean;
      items: Array<{skuId: string; listings: Array<{listingId: string; skuId: string; channel: string}>}>};
  assert.equal(result.state, "ready"); assert.equal(result.listingCoverage, "complete");
  assert.equal(result.orderingAvailable, false);
  assert.deepEqual(result.publicStore, {id: "store-one", name: profile.name, profileId: profile.profileId});
  assert.equal(result.items[0]!.skuId, "sku-one");
  assert.equal(result.items[0]!.listings[0]!.skuId, "sku-one");
  assert.equal(result.items[0]!.listings[0]!.channel, "retail");
  assert.match(result.items[0]!.listings[0]!.listingId, /^listing-[a-f0-9]{64}$/u);
  assert.doesNotMatch(JSON.stringify(result), /ownerUserId|provenance|sourceRecordId|billingAddress|publicContactPhone/u);
  const legacy = await subject(repository).publicCatalogue({storeId: "store-one"}) as {items: object[]};
  assert.equal(Object.hasOwn(legacy, "listingReadbackVersion"), false);
  assert.equal(Object.hasOwn(legacy.items[0]!, "listings"), false);
});
for (const changed of ["listingId", "storeId", "skuId", "canonicalProductId", "verifiedPackId", "channel", "extra"]) {
  test(`public readback rejects mismatched immutable listing ${changed}`, async () => {
    class Changed extends BoundMemory {
      override async publicListingBindings(record: StoreSkuRecord) {
        const rows = await super.publicListingBindings(record);
        return rows.map(row => ({...row, [changed]: "foreign-value"}));
      }
    }
    const repository = new Changed(); repository.aggregate = produceAll().aggregate;
    await subject(repository).saveSku("owner-one", save());
    const result = await subject(repository).publicCatalogue({storeId: "store-one", listingReadbackVersion: 1}) as
      {state: string; listingCoverage: string; items: unknown[]};
    assert.equal(result.state, "unavailable"); assert.equal(result.listingCoverage, "partial");
    assert.deepEqual(result.items, []);
  });
}
test("public listing readback rejects canonical revocation during policy await", async () => {
  const repository = new BoundMemory(); repository.aggregate = produceAll().aggregate;
  await subject(repository).saveSku("owner-one", save());
  const service = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(at), {
    forPublicSku: async () => {
      repository.aggregate = {...repository.aggregate!, version: repository.aggregate!.version + 1,
        products: repository.aggregate!.products.map(p => ({...p, state: "rejected"}))};
      throw new Error("Host policy unavailable");
    },
  });
  const result = await service.publicCatalogue({storeId: "store-one", listingReadbackVersion: 1, policyReadbackVersion: 1}) as
    {state: string; items: unknown[]};
  assert.equal(result.state, "unavailable"); assert.deepEqual(result.items, []);
});
test("public listing readback cannot outlive terms during its final metadata await", async () => {
  let currentTime = at;
  class Delayed extends BoundMemory {
    reads = 0;
    override async catalogue() {
      const result = await super.catalogue();
      if (++this.reads === 3) currentTime = "2026-10-16T14:00:00.000Z";
      return result;
    }
  }
  const repository = new Delayed(); repository.aggregate = produceAll().aggregate;
  await subject(repository).saveSku("owner-one", save());
  const result = await new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(currentTime))
    .publicCatalogue({storeId: "store-one", listingReadbackVersion: 1}) as {state: string; items: unknown[]};
  assert.equal(result.state, "unavailable"); assert.deepEqual(result.items, []);
});
test("public listing readback rejects an earlier SKU withdrawn while a later binding loads", async () => {
  class Withdrawal extends BoundMemory {
    override async publicListingBindings(record: StoreSkuRecord) {
      const bindings = await super.publicListingBindings(record);
      if (record.skuId === "sku-two") {
        const old = this.records.get("store-one/sku-one")!;
        this.records.set("store-one/sku-one", {...old, publicListing: false, revision: old.revision + 1});
      }
      return bindings;
    }
  }
  const repository = new Withdrawal(); repository.aggregate = produceAll().aggregate;
  await subject(repository).saveSku("owner-one", save());
  await subject(repository).saveSku("owner-one", save(input("sku-two")));
  const result = await subject(repository).publicCatalogue({storeId: "store-one", listingReadbackVersion: 1}) as
    {state: string; items: unknown[]};
  assert.equal(result.state, "unavailable"); assert.deepEqual(result.items, []);
});

test("Firestore emulator: public listing bindings persist atomically and never migrate on original replay", {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf03-public-listings"}, `listings-${randomUUID()}`);
  const db = getFirestore(app), storeId = `store-${randomUUID()}`, otherStore = `store-${randomUUID()}`;
  const caseId = `case-${randomUUID()}`, otherCase = `case-${randomUUID()}`;
  const localProfile = {...profile, workspaceId: storeId, caseId};
  const value = input(); value.channels.push({...value.channels[0]!, kind: "wholesale", offerId: "trade-offer"});
  const command: CatalogueSave = {ownerUserId: "owner-one", profile: localProfile, input: value,
    expectedRevision: 0, idempotencyKey: "original-listing-save", observedAt: at,
    fingerprint: cataloguePayloadHash({storeId, input: value, expectedRevision: 0})};
  const repo = (realm: "evaluation" | "production" = "evaluation") => new FirestoreWorkspaceCatalogueRepository(db, realm);
  const bindings = db.collection("workspaceCatalogues").doc("evaluation").collection("publicListingBindings");
  try {
    await db.collection("workspaceProfiles").doc(caseId).set(localProfile);
    await db.collection("workspaceProfiles").doc(otherCase).set({...localProfile, caseId: otherCase, workspaceId: otherStore});
    const first = await repo().save(command);
    const originalBindings = await repo().publicListingBindings(first);
    assert.equal(originalBindings?.length, 2);
    assert.notEqual(originalBindings![0]!.listingId, originalBindings![1]!.listingId);
    assert.deepEqual(await repo().publicListingBindings(first), originalBindings, "Fresh repository restores real persisted IDs");
    const secondStore = await repo().save({...command, profile: {...localProfile, workspaceId: otherStore, caseId: otherCase},
      fingerprint: cataloguePayloadHash({storeId: otherStore, input: value, expectedRevision: 0})});
    const other = await repo().publicListingBindings(secondStore);
    assert.notEqual(other![0]!.listingId, originalBindings![0]!.listingId);
    const production = await repo("production").save(command);
    const productionBindings = await repo("production").publicListingBindings(production);
    assert.notEqual(productionBindings![0]!.listingId, originalBindings![0]!.listingId);

    // Isolated host fixture deletion checks absence handling; never native data.
    const missing = bindings.doc(originalBindings![0]!.listingId);
    await missing.delete();
    assert.equal(await repo().publicListingBindings(first), undefined);
    assert.deepEqual(await repo().save(command), first);
    assert.equal((await missing.get()).exists, false, "Historical receipt must not create a fresh binding");
    const nextCommand = {...command, expectedRevision: 1, idempotencyKey: "explicit-next-save",
      fingerprint: cataloguePayloadHash({storeId, input: value, expectedRevision: 1})};
    const second = await repo().save(nextCommand);
    assert.deepEqual(await repo().publicListingBindings(second), originalBindings, "Explicit valid save preserves/recreates original identity");
    assert.equal(await repo().publicListingBindings(first), undefined, "Stale record cannot pass current readback");

    await missing.update({skuId: "foreign-sku"});
    const next = {...command, expectedRevision: 2, idempotencyKey: "must-not-overwrite-corrupt-binding",
      fingerprint: cataloguePayloadHash({storeId, input: value, expectedRevision: 2})};
    await assert.rejects(repo().save(next), {code: "invalid_input"});
    const head = db.collection("workspaceCatalogues").doc("evaluation").collection("stores").doc(storeId)
      .collection("skus").doc(value.skuId);
    assert.equal((await head.get()).get("revision"), 2, "Binding conflict rolls back the SKU update too");
    await assert.rejects(repo().publicListingBindings(second), {code: "invalid_input"});
    await missing.set(originalBindings![0]!);
    const hiddenInput = {...value, publicListing: false};
    const hidden = await repo().save({...command, input: hiddenInput, expectedRevision: 2, idempotencyKey: "withdraw-listing",
      fingerprint: cataloguePayloadHash({storeId, input: hiddenInput, expectedRevision: 2})});
    assert.equal(await repo().publicListingBindings(hidden), undefined);
    assert.equal((await missing.get()).exists, true, "Withdrawal retains immutable identity/history");
    assert.equal((await head.collection("revisions").get()).size, 3);
  } finally { await db.terminate(); await deleteApp(app); }
});
test("two saved SKUs retain identities and provenance across service restart", async () => {
  const repository = new Memory();
  await subject(repository).saveSku("owner-one", save());
  await subject(repository).saveSku("owner-one", save(input("sku-two")));
  const result = await subject(repository).listSkus("owner-one", {storeId: "store-one"}) as
    {items: StoreSkuRecord[]};
  assert.deepEqual(result.items.map(v => v.skuId), ["sku-one", "sku-two"]);
  assert.equal(result.items[0]?.provenance.sourceRecordId, "saved-source-one");
  assert.equal(result.items[0]?.revision, 1);
});
test("exact Store owner required even when a SKU or command ID is reused", async () => {
  const repository = new Memory();
  await assert.rejects(subject(repository).saveSku("other-owner", save()), {code: "not_found"});
  assert.equal(repository.records.size, 0);
});
test("missing canonical feed is unavailable, not fabricated public products", async () => {
  const result = await subject(new Memory()).publicCatalogue({storeId: "store-one"}) as
    {state: string; items: unknown[]; orderingAvailable: boolean};
  assert.equal(result.state, "unavailable");
  assert.deepEqual(result.items, []);
  assert.equal(result.orderingAvailable, false);
});

test("reviewed owner binding fails closed instead of falling back to private mirror save", async () => {
  const repository = new Memory();
  await assert.rejects(subject(repository).bindReviewedSku("owner-one", save()), {code: "service_unavailable"});
  assert.equal(repository.records.size, 0);
});

test("reviewed owner service returns exact saved facts without publication acknowledgement", async () => {
  class ReviewedMemory extends Memory {
    async bindReviewed(command: CatalogueSave) {
      const {aggregate, participant} = produceAll(command.input);
      planReviewedCatalogueSave(command, catalogueIdentity, aggregate, producerAuthority(), participant);
      return this.save(command);
    }
  }
  const repository = new ReviewedMemory();
  const result = await subject(repository).bindReviewedSku("owner-one", save()) as
    {saved: StoreSkuRecord; publicationConfirmed: boolean};
  assert.equal(result.saved.skuId, "sku-one"); assert.equal(result.saved.revision, 1);
  assert.equal(result.publicationConfirmed, false); assert.equal(repository.records.size, 1);
  await assert.rejects(subject(repository).bindReviewedSku("other-owner", save()), {code: "not_found"});
  await assert.rejects(subject(repository).bindReviewedSku("owner-one", {...save(), actor: producerAuthority().actor}), {code: "invalid_input"});
});

test("identical retry returns original immutable revision; changed payload conflicts", async () => {
  const repository = new Memory();
  const first = await subject(repository).saveSku("owner-one", save());
  const replay = await subject(repository).saveSku("owner-one", save());
  assert.deepEqual(replay, first);
  assert.equal(repository.receipts.size, 1);
  const changed = input(); changed.content.title = "Changed host fixture";
  await assert.rejects(subject(repository).saveSku("owner-one", save(changed)), {code: "conflict"});
  assert.equal(repository.records.get("store-one/sku-one")?.revision, 1);
});
test("concurrent stale updates have one winner without partial writes", async () => {
  const repository = new Memory();
  await subject(repository).saveSku("owner-one", save());
  const results = await Promise.allSettled(["update-one", "update-two"].map(key =>
    subject(repository).saveSku("owner-one", save(input(), {expectedRevision: 1, idempotencyKey: key}))));
  assert.equal(results.filter(r => r.status === "fulfilled").length, 1);
  assert.equal(repository.records.get("store-one/sku-one")?.revision, 2);
});
test("saved canonical/pack and provenance identities cannot be overwritten", async () => {
  const repository = new Memory();
  await subject(repository).saveSku("owner-one", save());
  for (const update of [{canonicalProductId: "canonical-two"}, {verifiedPackId: "pack-two"},
    {provenance: {entryMethod: "csv" as const, sourceRecordId: "other-source"}}]) {
    await assert.rejects(subject(repository).saveSku("owner-one", save({...input(), ...update},
      {expectedRevision: 1, idempotencyKey: "identity-update"})), {code: "conflict"});
  }
});
test("same SKU/idempotency values remain isolated across Stores", async () => {
  const repository = new Memory();
  repository.stores.set("store-two", {...profile, caseId: "case-two", workspaceId: "store-two", ownerUserId: "owner-two"});
  await subject(repository).saveSku("owner-one", save());
  await subject(repository).saveSku("owner-two", save(input(), {storeId: "store-two"}));
  assert.equal(repository.records.size, 2);
  await assert.rejects(subject(repository).listSkus("owner-one", {storeId: "store-two"}), {code: "not_found"});
});
test("quantity steps and tier boundaries start from the selected minimum, not zero", async () => {
  const repository = new Memory(), value = input();
  value.channels[0] = {...value.channels[0]!, kind: "wholesale", minimumOrder: 3, quantityStep: 2,
    tiers: [{minimumQuantity: 3, unitPriceMinor: 26000}, {minimumQuantity: 5, unitPriceMinor: 25000}]};
  await subject(repository).saveSku("owner-one", save(value));
  const saved = repository.records.get("store-one/sku-one")!;
  assert.equal(saved.channels[0]!.minimumOrder, 3);
  assert.equal(saved.channels[0]!.quantityStep, 2);
  value.channels[0]!.tiers[1]!.minimumQuantity = 4;
  await assert.rejects(subject(repository).saveSku("owner-one", save(value, {idempotencyKey: "bad-step", expectedRevision: 1})),
    {code: "invalid_input"});
});
for (const [name, mutate] of Object.entries<(v: StoreSkuInput) => void>({
  "foreign image": v => {v.content.media = [{id: "photo-one", revision: "media-one", url: "https://example.invalid/p.png",
    storeId: "store-two", skuId: v.skuId, canonicalProductId: v.canonicalProductId, publisherWorkspaceId: "publisher-one",
    file: {mimeType: "image/png", byteLength: 4000, width: 800, height: 800, normalized: true}}];},
  "credential URL": v => {v.content.media = [{id: "photo-one", revision: "media-one", url: "https://example.invalid/p.png?token=private",
    storeId: "store-one", skuId: v.skuId, canonicalProductId: v.canonicalProductId, publisherWorkspaceId: "publisher-one",
    file: {mimeType: "image/png", byteLength: 4000, width: 800, height: 800, normalized: true}}];},
  "both trade types": v => {v.channels = [{...v.channels[0]!, kind: "wholesale"}, {...v.channels[0]!, kind: "bulk"}];},
  "invalid pack quantity": v => {v.pack.quantityMilli = 0;},
  "negative price": v => {v.channels[0]!.priceMinor = -1;},
  "MRP below price": v => {v.channels[0]!.mrpMinor = 10;},
  "invalid tier order": v => {v.channels[0]!.tiers = [{minimumQuantity: 2, unitPriceMinor: 26000}];},
  "unknown private field": v => {Object.assign(v.content, {purchasePrice: 100});},
})) {
  test(`${name} is rejected without saving`, async () => {
    const repository = new Memory(), value = input(); mutate(value);
    await assert.rejects(subject(repository).saveSku("owner-one", save(value)), {code: "invalid_input"});
    assert.equal(repository.records.size, 0);
  });
}

function verifiedCatalogue(value: StoreSkuInput): CatalogueAggregate {
  const base = createCatalogueAggregate({commandId: "create-host-catalogue", catalogueId: "catalogue-one",
    tenantId: "tenant-one", occurredAt: at,
    actor: {actorId: "host-reviewer", tenantId: "tenant-one", scopes: ["supply.catalogue.review"]}});
  // Explicit isolated reviewed-state fixture, not a bypass exposed by the service.
  return {...base, products: [{productId: value.canonicalProductId, categoryId: value.content.categoryId,
    brandId: "brand-host", contentSha256: cataloguePayloadHash(value.content), codes: [], state: "verified",
    proposedByWorkspaceId: "store-one", proposedAt: at, reviewedBy: "host-reviewer", reviewedAt: at}],
    packs: [{packId: value.verifiedPackId, productId: value.canonicalProductId,
      descriptorSha256: cataloguePayloadHash(value.pack), codes: [], state: "verified",
      proposedByWorkspaceId: "store-one", proposedAt: at, reviewedBy: "host-reviewer", reviewedAt: at}],
    offers: value.channels.map(c => ({offerId: c.offerId, workspaceId: "store-one", packId: value.verifiedPackId,
      buyingContext: c.kind === "retail" ? "consumer" : "wholesale", serviceAreaIds: ["host-area"],
      termWindows: [{termSnapshotId: "term-host-one", termSnapshotSha256: cataloguePayloadHash(channelTerms(c)),
        effectiveFrom: "2026-10-16T11:00:00.000Z", expiresAt: "2026-10-16T13:00:00.000Z"}], status: "active", createdAt: at}))};
}

test("policy readback attaches only after exact catalogue eligibility, never to hidden rows", async () => {
  const repository = new Memory(), value = input();
  repository.aggregate = verifiedCatalogue(value);
  await subject(repository).saveSku("owner-one", save(value));
  let reads = 0;
  const reader = {forPublicSku: async (storeId: string, skuId: string) => {
    reads++;
    return {schemaVersion: 1 as const, realm: "evaluation" as const, storeId, skuId, observedAt: at, state: "none" as const,
      revision: 0, requiresAcceptance: false, policy: null};
  }};
  const combined = new WorkspaceCatalogueService(repository, catalogueIdentity, () => new Date(at), reader);
  const legacy = await combined.publicCatalogue({storeId: "store-one"}) as {items: Array<{supplierPolicy?: unknown}>};
  assert.equal(legacy.items[0]?.supplierPolicy, undefined); assert.equal(reads, 0);
  const result = await combined.publicCatalogue({storeId: "store-one", policyReadbackVersion: 1}) as {items: Array<{supplierPolicy?: unknown}>};
  assert.deepEqual(result.items[0]?.supplierPolicy, await reader.forPublicSku("store-one", "sku-one"));
  assert.equal(reads, 2);
  repository.records.get("store-one/sku-one")!.publicListing = false;
  assert.deepEqual((await combined.publicCatalogue({storeId: "store-one", policyReadbackVersion: 1}) as {items: unknown[]}).items, []);
  assert.equal(reads, 2);
});
test("public readback includes verified fields/revision, never provenance or commerce authority", async () => {
  const repository = new Memory(), value = input(); repository.aggregate = verifiedCatalogue(value);
  await subject(repository).saveSku("owner-one", save(value));
  const result = await subject(repository).publicCatalogue({storeId: "store-one"}) as
    {state: string; items: Array<Record<string, unknown>>; orderingAvailable: boolean};
  assert.equal(result.state, "ready"); assert.equal(result.items.length, 1);
  assert.equal(result.items[0]?.revision, 1); assert.equal(result.items[0]?.skuId, value.skuId);
  assert.equal(Object.hasOwn(result.items[0]!, "provenance"), false);
  assert.equal(JSON.stringify(result).includes("saved-source-one"), false);
  assert.equal(result.orderingAvailable, false);
});
test("changed content, pack, offer Store, expiry, or hidden listing cannot leak publicly", async () => {
  for (const kind of ["content", "pack", "offer", "expiry", "hidden"]) {
    const repository = new Memory(), value = input(); repository.aggregate = verifiedCatalogue(value);
    if (kind === "content") value.content.title = "Unreviewed title";
    if (kind === "pack") value.pack.label = "Unreviewed pack";
    if (kind === "offer") repository.aggregate = {...repository.aggregate,
      offers: repository.aggregate.offers.map(o => ({...o, workspaceId: "store-two"}))};
    if (kind === "expiry") repository.aggregate = {...repository.aggregate,
      offers: repository.aggregate.offers.map(o => ({...o, termWindows: o.termWindows.map(t =>
        ({...t, expiresAt: at}))}))};
    if (kind === "hidden") value.publicListing = false;
    await subject(repository).saveSku("owner-one", save(value));
    const result = await subject(repository).publicCatalogue({storeId: "store-one"}) as {items: unknown[]};
    assert.deepEqual(result.items, [], kind);
  }
});
test("pagination preserves Store scope and cannot inject a foreign cursor path", async () => {
  const repository = new Memory();
  for (const key of ["sku-one", "sku-two"]) await subject(repository).saveSku("owner-one", save(input(key)));
  const first = await subject(repository).listSkus("owner-one", {storeId: "store-one", limit: 1}) as
    {items: StoreSkuRecord[]; nextCursor: string};
  assert.equal(first.nextCursor, "sku-one");
  const second = await subject(repository).listSkus("owner-one", {storeId: "store-one", limit: 1, after: first.nextCursor}) as
    {items: StoreSkuRecord[]};
  assert.equal(second.items[0]?.skuId, "sku-two");
  await assert.rejects(subject(repository).listSkus("owner-one", {storeId: "store-one", after: "../store-two"}), {code: "invalid_input"});
});

test("exact SKU query finds a later saved SKU without returning another product", async () => {
  const repository = new Memory();
  for (const key of ["sku-one", "sku-two"]) await subject(repository).saveSku("owner-one", save(input(key)));
  const result = await subject(repository).listSkus("owner-one", {storeId: "store-one", skuId: "sku-two"}) as
    {items: StoreSkuRecord[]; nextCursor: string | null};
  assert.deepEqual(result.items.map(r => r.skuId), ["sku-two"]); assert.equal(result.nextCursor, null);
  await assert.rejects(subject(repository).publicCatalogue({storeId: "store-one", skuId: "sku-two", after: "sku-one"}), {code: "invalid_input"});
});
test("readback rechecks catalogue approval and Store eligibility after loading rows", async () => {
  for (const revoke of ["catalogue", "store"]) {
    class RevokeDuringRead extends Memory {
      reads = 0;
      override async catalogue() {
        this.reads++;
        if (this.reads === 2) {
          if (revoke === "catalogue") this.aggregate = {...this.aggregate!, version: 2};
          else this.stores.set("store-one", {...profile, shopEnabled: false});
        }
        return super.catalogue();
      }
    }
    const repository = new RevokeDuringRead(); repository.aggregate = verifiedCatalogue(input());
    await subject(repository).saveSku("owner-one", save());
    const result = await subject(repository).publicCatalogue({storeId: "store-one"}) as {state: string; items: unknown[]};
    assert.equal(result.state, "unavailable"); assert.deepEqual(result.items, []);
  }
});
test("multiline product text is retained without fabricating structured variant IDs", async () => {
  const repository = new Memory(), value = input(); value.content.description = "Line one\nLine two";
  await subject(repository).saveSku("owner-one", save(value));
  assert.equal(repository.records.get("store-one/sku-one")?.content.description, value.content.description);
  assert.equal(Object.hasOwn(repository.records.get("store-one/sku-one")!.content, "variantAttributes"), false);
});

test("Firestore emulator: atomic revisions/retries/CAS, restart, revocation and realm isolation", {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf03-catalogue"}, `lf03-${randomUUID()}`);
  const db = getFirestore(app), storeId = `host-${randomUUID()}`, caseId = `host-${randomUUID()}`;
  try {
    const profileRef = db.collection("workspaceProfiles").doc(caseId);
    await profileRef.set({...profile, workspaceId: storeId, caseId});
    const repo = new FirestoreWorkspaceCatalogueRepository(db, "evaluation");
    const service = () => new WorkspaceCatalogueService(repo,
      {catalogueId: "catalogue-one", tenantId: "tenant-one"}, () => new Date(at));
    const command = (skuId: string, expectedRevision = 0, key = `save-${skuId}`) =>
      save(input(skuId), {storeId, expectedRevision, idempotencyKey: key});
    const original = await service().saveSku("owner-one", command("sku-one"));
    await service().saveSku("owner-one", command("sku-two"));
    const restarted = await service().listSkus("owner-one", {storeId}) as {items: StoreSkuRecord[]};
    assert.deepEqual(restarted.items.map(r => r.skuId), ["sku-one", "sku-two"]);
    assert.equal(restarted.items[0]?.provenance.sourceRecordId, "saved-source-one");
    const competing = await Promise.allSettled(["cas-one", "cas-two"].map(key =>
      service().saveSku("owner-one", command("sku-one", 1, key))));
    assert.equal(competing.filter(r => r.status === "fulfilled").length, 1);
    assert.equal(competing.filter(r => r.status === "rejected" && r.reason.code === "conflict").length, 1);
    assert.deepEqual(await service().saveSku("owner-one", command("sku-one")), original);
    const root = db.collection("workspaceCatalogues").doc("evaluation").collection("stores").doc(storeId);
    const head = root.collection("skus").doc("sku-one");
    assert.equal((await head.get()).get("revision"), 2);
    assert.equal((await head.collection("revisions").get()).size, 2);
    const withPhoto = input("sku-one"); withPhoto.content.media = staticMedia(withPhoto, storeId);
    await service().saveSku("owner-one", {...command("sku-one", 2, "explicit-photo-input"), sku: withPhoto});
    await assert.rejects(service().listSkus("owner-one", {storeId}), {code: "unsupported_version"});
    const upgraded = await service().listSkus("owner-one", {storeId, mediaReadbackVersion: 1}) as {items: StoreSkuRecord[]};
    assert.equal(upgraded.items[0]!.content.media[0]!.file.frameCount, 1);
    const oldReceipt = await service().reconcileBinding("owner-one", command("sku-one")) as {saved: StoreSkuRecord};
    assert.deepEqual(oldReceipt.saved, (original as {saved: StoreSkuRecord}).saved);
    assert.deepEqual(oldReceipt.saved.content.media, [], "Old receipt retains exact original content after a newer photo revision");
    const production = new WorkspaceCatalogueService(new FirestoreWorkspaceCatalogueRepository(db, "production"));
    const productionRows = await production.listSkus("owner-one", {storeId}) as {items: unknown[]};
    assert.deepEqual(productionRows.items, []);
    await profileRef.update({ownerUserId: "replacement-owner"});
    await assert.rejects(service().saveSku("owner-one", command("sku-one")), {code: "not_found"});
    await assert.rejects(service().listSkus("owner-one", {storeId}), {code: "not_found"});
    assert.equal((await head.get()).get("revision"), 3);
  } finally { await db.terminate(); await deleteApp(app); }
});

for (const unbranded of [false, true]) {
test(`Firestore emulator: trusted producer to exact binding to restarted public reader unbranded=${unbranded}`, {
  skip: process.env.FIRESTORE_EMULATOR_HOST === undefined,
}, async () => {
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!, /^127\.0\.0\.1:\d+$/u);
  const app = initializeApp({projectId: "demo-lf03-catalogue"}, `producer-${randomUUID()}`);
  const db = getFirestore(app), storeId = `store-${randomUUID()}`, caseId = `case-${randomUUID()}`;
  const identity = {...catalogueIdentity, catalogueId: `catalogue-${randomUUID()}`};
  const root = db.collection("workspaceCatalogues").doc("evaluation");
  const localProfile = {...profile, workspaceId: storeId, caseId};
  const value = input();
  if (unbranded) {
    value.content = {...value.content, title: "Cucumber", brand: "", variant: "", categoryId: "fruits-vegetables"};
    value.pack = {...value.pack, label: "1 kg", unit: "kg"};
    value.channels[0]!.priceMinor = 5000; value.channels[0]!.mrpMinor = 5000;
  }
  const participant = producerParticipant(storeId, value.content.categoryId);
  value.content.media = staticMedia(value, storeId);
  const repository = () => new FirestoreWorkspaceCatalogueRepository(db, "evaluation", () => new Date(at));
  try {
    await db.collection("workspaceProfiles").doc(caseId).set(localProfile);
    await root.collection("participants").doc(storeId).set(participant);
    // Only isolated emulator authority fixtures. The service has no grant writer.
    await root.collection("producerAuthorities").doc("owner-one").set(producerAuthority(true, storeId));
    await root.collection("producerAuthorities").doc("reviewer-one").set(producerAuthority(false));
    const commands = productionCommands(value);
    if (unbranded) commands[1]!.brandId = null;
    for (const command of commands) {
      const owner = ["propose_product", "propose_pack", "create_offer"].includes(String(command.type));
      await repository().produceCatalogue(owner ? "owner-one" : "reviewer-one", identity, command);
    }
    const aggregateRef = root.collection("canonicalCatalogues").doc(identity.catalogueId);
    assert.equal((await aggregateRef.get()).get("version"), 6);
    assert.equal((await repository().catalogue(identity.catalogueId))!.products[0]!.brandId, unbranded ? null : "brand-host");
    assert.equal((await aggregateRef.collection("revisions").get()).size, 6);
    const command: CatalogueSave = {ownerUserId: "owner-one", profile: localProfile,
      input: value, expectedRevision: 0, idempotencyKey: "reviewed-binding",
      fingerprint: cataloguePayloadHash({storeId, input: value, expectedRevision: 0}), observedAt: at};
    const bound = await repository().bindReviewed(command, identity);
    assert.equal(bound.skuId, value.skuId); assert.equal(bound.provenance.sourceRecordId, "saved-source-one");
    assert.deepEqual(await repository().bindReviewed(command, identity), bound);
    const serviceResult = await new WorkspaceCatalogueService(repository(), identity, () => new Date(at))
      .bindReviewedSku("owner-one", {storeId, sku: value, expectedRevision: 0, idempotencyKey: "reviewed-binding"}) as
      {saved: StoreSkuRecord; publicationConfirmed: boolean};
    assert.deepEqual(serviceResult.saved, bound); assert.equal(serviceResult.publicationConfirmed, false);
    let releaseSave!: () => void, enteredSave!: () => void;
    const saveEntered = new Promise<void>(resolve => {enteredSave = resolve;});
    const saveReleased = new Promise<void>(resolve => {releaseSave = resolve;});
    const suspended = {collection: db.collection.bind(db),
      runTransaction: async (action: Parameters<typeof db.runTransaction>[0]) => {
        enteredSave(); await saveReleased; return db.runTransaction(action);
      }} as unknown as typeof db;
    const callerCommand = structuredClone(command), callerIdentity = {...identity};
    const originalOnly = new FirestoreWorkspaceCatalogueRepository(suspended, "evaluation", () => new Date(at))
      .bindReviewed(callerCommand, callerIdentity);
    await saveEntered; callerIdentity.tenantId = "tenant-other";
    callerCommand.input.content.description = "Mutated during save";
    callerCommand.fingerprint = cataloguePayloadHash({storeId, input: callerCommand.input, expectedRevision: 0});
    releaseSave(); assert.deepEqual(await originalOnly, bound);
    const page = await new WorkspaceCatalogueService(repository(), identity, () => new Date(at))
      .publicCatalogue({storeId, ...(unbranded ? {unbrandedProduceReadbackVersion: 1} : {})}) as {items: Array<{skuId: string}>; orderingAvailable: boolean};
    assert.equal(page.items[0]?.skuId, value.skuId); assert.equal(page.orderingAvailable, false);
    const linked = await new WorkspaceCatalogueService(repository(), identity, () => new Date(at))
      .publicCatalogue({storeId, listingReadbackVersion: 1, ...(unbranded ? {
        unbrandedProduceReadbackVersion: 1, productFactsReadbackVersion: 1, mediaReadbackVersion: 1, policyReadbackVersion: 1} : {})}) as
      {state: string; listingCoverage: string; items: Array<{listings: Array<{listingId: string; skuId: string}>}>};
    assert.equal(linked.state, "ready"); assert.equal(linked.listingCoverage, "complete");
    if (unbranded && process.env.LF03_CANONICAL_PUBLIC_CAPTURE === "true") {
      console.log(`LF03_CANONICAL_PUBLIC=${JSON.stringify(linked)}`);
    }
    assert.equal(linked.items[0]!.listings[0]!.skuId, value.skuId);
    assert.equal(linked.items[0]!.listings[0]!.listingId, (await repository().publicListingBindings(bound))![0]!.listingId,
      "Real reviewed producer/binding and restarted public reader retain the same persisted listing");
    const replay = await repository().produceCatalogue("owner-one", identity, commands[1]!);
    assert.equal(replay.version, 2); assert.equal((await aggregateRef.get()).get("version"), 6);
    await assert.rejects(repository().produceCatalogue("owner-one", identity,
      {...commands[1], brandId: "changed-brand"}), {code: "conflict"});
    const races = await Promise.allSettled(["cas-one", "cas-two"].map(key => repository().produceCatalogue(
      "owner-one", identity, {...commands[1], commandId: key, productId: key, expectedVersion: 6})));
    assert.equal(races.filter(r => r.status === "fulfilled").length, 1);
    assert.equal(races.filter(r => r.status === "rejected" && r.reason.code === "version_conflict").length, 1);
    assert.equal((await aggregateRef.get()).get("version"), 7);
    const delayed = new FirestoreWorkspaceCatalogueRepository(db, "evaluation", (() => {
      let reads = 0; return () => new Date(++reads === 1 ? at : "2026-10-17T00:00:00.000Z");
    })());
    await assert.rejects(delayed.produceCatalogue("owner-one", identity, commands[1]!), {code: "forbidden"});
    const production = new FirestoreWorkspaceCatalogueRepository(db, "production", () => new Date(at));
    await assert.rejects(production.produceCatalogue("reviewer-one", identity, commands[0]!), {code: "forbidden"});
    await root.collection("producerAuthorities").doc("owner-one").update({enabled: false, revision: 2});
    await assert.rejects(repository().produceCatalogue("owner-one", identity, commands[1]!), {code: "forbidden"});
    await assert.rejects(repository().bindReviewed(command, identity), {code: "forbidden"});
    const recoveringService = new WorkspaceCatalogueService(repository(), identity, () => new Date(at));
    const originalRequest = {storeId, sku: value, expectedRevision: 0, idempotencyKey: "reviewed-binding"};
    const recovered = await recoveringService.reconcileBinding("owner-one", originalRequest) as
      {saved: StoreSkuRecord; publicationConfirmed: boolean};
    assert.deepEqual(recovered.saved, bound); assert.equal(recovered.publicationConfirmed, false);
    const absent = await recoveringService.reconcileBinding("owner-one",
      {...originalRequest, idempotencyKey: "not-submitted"}) as {saved: unknown};
    assert.equal(absent.saved, null);
    await assert.rejects(recoveringService.reconcileBinding("other-owner", originalRequest), {code: "not_found"});
    await assert.rejects(recoveringService.reconcileBinding("owner-one", {...originalRequest,
      sku: {...value, sku: "DIFFERENT-SKU"}}), {code: "conflict"});
    assert.equal((await root.collection("stores").doc(storeId).collection("skus").get()).size, 1);
    assert.equal((await aggregateRef.collection("revisions").get()).size, 7);
  } finally { await db.terminate(); await deleteApp(app); }
});
}
