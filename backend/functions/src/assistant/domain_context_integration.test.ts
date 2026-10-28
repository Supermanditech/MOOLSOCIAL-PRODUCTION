import test from "node:test";
import assert from "node:assert/strict";
import {AccountPlansService} from "../account/plans_service.js";
import {AccountProfileService} from "../account/profile_service.js";
import {ProfileWorkspacePreparationContext} from "./profile_context.js";
import {WorkspaceCatalogueService, type WorkspaceCatalogueRepository} from "../workspace/workspace_catalogue_service.js";
import {CompositePreparationContext, OriginalCataloguePreparationContext, OriginalStoreOrderPreparationContext,OriginalPurchasedStarsPreparationContext} from "./domain_context.js";
import {digest} from './model_contract.js';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {randomUUID} from 'node:crypto';
import {writeFileSync} from 'node:fs';
import {isAbsolute} from 'node:path';
import {WorkspacePurchaseProjectionService, WorkspaceOrderOperationsService,type TrustedPlacementReceipt, type PurchaseReference,type ProductFeedbackTarget} from '../workspace/workspace_purchase_projection_service.js';
import {handleAssistantCanonicalContextRequest} from "./domain_context_http.js";
import {AssistantPreparationService, type PreparationRequestStore, type PreparationState} from "./model_service.js";
const actor = {uid: "host-domain-owner", projectId: "host-domain-project"};
const at = new Date("2026-10-28T08:00:00.000Z");

// Existing Plans/Workspace services, isolated repository ports. No supplier
// master, model call, runtime provider or phone record is created by this fixture.
function supplierDraftFixture() {
  const storeId = 'WK-510001', caseId = 'HOST-supplier-case';
  let paid = true, approved = true, member = true, version = 1, clock = new Date(at), reads = 0;
  let onRead = (_count: number) => {};
  const workspaces = async (owner: {uid: string}) => {
    reads++; onRead(reads);
    if (owner.uid !== actor.uid) return {workspaces: []};
    return {workspaces: [{caseId, status: approved ? 'live' : 'pending', workspaceId: storeId,
      profileId: 'retailer-grocery', name: 'HOST private Store', access: {schemaVersion: 1, state: member ? 'active' : 'revoked',
        accountId: actor.uid, caseId, workspaceId: storeId, profileId: 'retailer-grocery', checkedAt: at.toISOString(),
        applicationUpdatedAt: '2026-10-27T08:00:00.000Z', membership: {schemaVersion: 1, state: member ? 'active' : 'revoked',
          membershipId: 'HOST-supplier-member', workspaceId: storeId, workspaceProfileId: 'retailer-grocery', version,
          effectiveFrom: '2026-10-27T00:00:00.000Z', expiresAt: '2026-10-29T00:00:00.000Z'}}}]};
  };
  const plans = new AccountPlansService({async read(uid, scope) { return {ownerUid: uid, accountStatus: 'ACTIVE',
    catalogue: {audience: scope.audience, revision: 1, state: 'approved', offers: []},
    subscription: {ownerUid: uid, scope, revision: 1, planId: 'host-paid-plan', planVersion: 'v1', name: 'Host fixture only',
      state: paid ? 'active' : 'expired', validFrom: '2026-10-27T00:00:00.000Z', validUntil: '2026-10-29T00:00:00.000Z', featureIds: ['mool_ai']}};
  }}, {projectId: actor.projectId, now: () => clock, readWorkspaces: workspaces});
  const original = new ProfileWorkspacePreparationContext({profile: {async read() { throw Error('No personal or supplier master read'); }},
    plans, workspaces, now: () => clock});
  const source = new CompositePreparationContext({original, nativeSupplierFormsEnabled: true, now: () => clock});
  const input = {scope: {audience: 'workspace' as const, storeId}, requestId: 'HOST-supplier-preparation', requestRevision: 1,
    expectedEntitlementRevision: `workspace:${storeId}:1:1`, message: 'Add the supplier I named', language: 'Hindi', history: [],
    actionId: 'AI-ACT-235', entityId: null};
  return {source, input, original, plans, onRead: (fn: typeof onRead) => {onRead = fn;},
    paid: (value: boolean) => {paid = value;}, approved: (value: boolean) => {approved = value;},
    member: (value: boolean) => {member = value;}, bump: () => {version++;}, advance: () => {clock = new Date(clock.getTime() + 60_001);}};
}

test('Supplier drafts actual approved paid authority prepares only user text and original native query', async () => {
  const f = supplierDraftFixture(), context = await f.source.read(actor, f.input), tool = context.tools[0]!;
  assert.equal(tool.actionId, 'AI-ACT-235'); assert.equal(tool.entityId, null);
  assert.match(tool.sourceRevision, /^store-supplier-draft-owner:[a-f0-9]{64}$/u);
  const fields = {name: '  HOST મૂળ સપ્લાયર  ', phone: '+91 (98765) 43210', address: 'HOST shop 4\nMarket Road\nPune', gstin: '  27abcde1234f1z5  '};
  const target = tool.resolveTarget!(fields);
  assert.deepEqual(target.fields, fields); assert.equal(target.entityId, null);
  assert.equal(tool.validate(fields), true);
  const minimal = tool.resolveTarget!({name: fields.name, phone: null, address: null, gstin: null});
  assert.deepEqual(minimal.fields, {name: fields.name});
  assert.equal(JSON.stringify(context.modelContext).includes(fields.name), false);
  const search = await f.source.read(actor, {...f.input, actionId: 'AI-ACT-236'});
  assert.deepEqual(search.tools[0]!.resolveTarget!({query: 'મૂળ સપ્લાયર'}).fields, {query: 'મૂળ સપ્લાયર'});
  const metadata = await handleAssistantCanonicalContextRequest({method: 'POST', headers: {authorization: 'Bearer HOST-only', 'x-firebase-appcheck': 'HOST-only'},
    bodyBytes: 100, body: {operation: 'read', payload: {scope: f.input.scope, nativeSelectionVersion: 1}}},
  {projectId: actor.projectId, enabled: true, context: f.source, now: () => at, async verifyIdToken() {return actor;}, async verifyAppCheck() {return {};}});
  assert.equal(metadata.status, 200); assert(metadata.body.ok);
  assert(JSON.stringify(metadata.body).includes('AI-ACT-235')); assert(JSON.stringify(metadata.body).includes('AI-ACT-236'));
  assert(!JSON.stringify(metadata.body).includes(fields.name)); assert(!JSON.stringify(metadata.body).includes('AI-ACT-237'));
  if (process.env.AI_DOMAIN_SUPPLIER_DRAFT_EXPORT_PATH) {
    const path = process.env.AI_DOMAIN_SUPPLIER_DRAFT_EXPORT_PATH; assert(isAbsolute(path));
    writeFileSync(path, JSON.stringify({kind: 'isolated-host-original-authority-draft-contract', fields: target.fields,
      query: '91 111', entityId: target.entityId, sourceRevision: target.sourceRevision, metadata: metadata.body}, null, 2) + '\n', {flag: 'wx'});
  }
});

test('Supplier optional root does not break catalogue-selected combined contexts', async () => {
  const f = supplierDraftFixture();
  for (const selection of [{catalogueListingIds: ['HOST-listing']}]) {
    const source = await f.source.read(actor, {...f.input, actionId: null, ...selection});
    assert(source.tools.some(tool => tool.actionId === 'AI-ACT-317'));
    assert(!source.tools.some(tool => ['AI-ACT-235', 'AI-ACT-236'].includes(tool.actionId)));
  }
});

for (const actionId of ['AI-ACT-235', 'AI-ACT-236']) test(`Supplier generic composer ${actionId} actual preparation and status survive service restart without duplicate usage`, async () => {
  const f = supplierDraftFixture(), requests = new HostRequests(); let models = 0, reservations = 0;
  const service = () => new AssistantPreparationService({projectId: actor.projectId, plans: f.plans, context: f.source, requests, now: () => at,
    usage: {async reserve() {reservations++; return {id: 'HOST-supplier-permit', validUntil: '2026-10-28T08:01:00.000Z'};}, async settle() {}},
    model: {async prepare(_input, tools) {models++; assert.equal(tools.length, 1); assert.equal(tools[0]!.actionId, actionId);
      return {kind: 'tool', name: tools[0]!.name, arguments: actionId === 'AI-ACT-235'
        ? {name: 'HOST supplied supplier', phone: null, address: null, gstin: null} : {query: 'HOST supplied query'}};}}});
  const payload = {...f.input, actionId: null, nativeTargets: [{actionId, entityId: null}]};
  const result = await service().handle(actor, {operation: 'prepare', payload});
  assert.equal(result.state, 'ready');
  assert.deepEqual(await service().handle(actor, {operation: 'status', payload: {scope: payload.scope, requestId: payload.requestId}}), result);
  assert.deepEqual(await service().handle(actor, {operation: 'prepare', payload}), result);
  assert.equal(models, 1); assert.equal(reservations, 1);
  f.member(false); await assert.rejects(service().handle(actor, {operation: 'status', payload: {scope: payload.scope, requestId: payload.requestId}}));
});

test('Supplier draft rejects invented identity unknown fields invalid inputs and specific-record joins', async () => {
  const f = supplierDraftFixture(), tool = (await f.source.read(actor, f.input)).tools[0]!;
  for (const bad of [{name: ''}, {name: 'HOST', id: 'invented'}, {name: 'HOST', gstin: 'short'},
    {name: 'HOST', phone: 'invalid'}, {name: 'HOST', address: 'x'.repeat(501)}, {name: 'HOST\u0000'}]) assert.equal(tool.validate(bad), false);
  for (const bad of [{name: 'HOST'}, {name: 'HOST', phone: null, address: null, gstin: null, id: 'invented'}]) assert.throws(() => tool.resolveTarget!(bad));
  await assert.rejects(f.source.read(actor, {...f.input, entityId: 'invented'}));
  await assert.rejects(f.source.read(actor, {...f.input, catalogueListingIds: []}));
  await assert.rejects(f.source.read(actor, {...f.input, actionId: 'AI-ACT-237', entityId: 'invented'}));
  await assert.rejects(new CompositePreparationContext({original: f.original}).read(actor, f.input));
});

test('Supplier draft ownership rejects wrong account project tenant Store pending revoked and unpaid states', async () => {
  for (const fault of ['account', 'project', 'tenant', 'store', 'personal', 'pending', 'revoked', 'unpaid']) {
    const f = supplierDraftFixture();
    if (fault === 'pending') f.approved(false); if (fault === 'revoked') f.member(false); if (fault === 'unpaid') f.paid(false);
    const who = fault === 'account' ? {...actor, uid: 'foreign'} : fault === 'project' ? {...actor, projectId: 'foreign-project'} : fault === 'tenant' ? {...actor, tenantId: 'foreign'} : actor;
    const input = fault === 'store' ? {...f.input, scope: {...f.input.scope, storeId: 'foreign-store'}} : fault === 'personal' ? {...f.input, scope: {audience: 'personal' as const, storeId: null}} : f.input;
    await assert.rejects(f.source.read(who, input), Error, fault);
  }
});

test('Supplier recovery rechecks current authority and exact source proof without replaying an effect', async () => {
  const f = supplierDraftFixture(), tool = (await f.source.read(actor, f.input)).tools[0]!, target = tool.resolveTarget!({name: 'HOST supplier', phone: null, address: null, gstin: null});
  const proposal = {kind: 'proposal' as const, id: 'HOST-stored-draft', actionId: 'AI-ACT-235', entityId: null,
    sourceRevision: target.sourceRevision, fields: target.fields, title: 'Review supplier', summary: 'Host fixture'};
  assert.equal((await f.source.readPrepared(actor, f.input, proposal)).tools[0]!.sourceRevision, target.sourceRevision);
  await assert.rejects(f.source.readPrepared(actor, f.input, {...proposal, sourceRevision: 'forged'}));
  await assert.rejects(f.source.readPrepared(actor, f.input, {...proposal, fields: {...target.fields, id: 'invented'}}));
  f.bump(); await assert.rejects(f.source.readPrepared(actor, f.input, proposal));
  for (const kind of ['stale', 'expired', 'revoked']) {
    const changed = supplierDraftFixture();
    changed.onRead(count => {if (count === 4) {if (kind === 'stale') changed.bump(); else if (kind === 'expired') changed.advance(); else changed.member(false);}});
    await assert.rejects(changed.source.read(actor, changed.input), Error, kind);
  }
});

test('Order originals actual loopback SDK projection service to authorised AI metadata preserves all indexed references',{
  skip:!process.env.FIRESTORE_EMULATOR_HOST,timeout:120000,
},async()=>{
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!,/^127\.0\.0\.1:\d+$/u);
  const owner={uid:'host-native-scope-user',projectId:'host-order-project'},storeId='WK-510001',caseId='HOST-order-case';
  const app=initializeApp({projectId:`demo-ai-order-${randomUUID().slice(0,8)}`},`host-order-${randomUUID()}`);
  const db=getFirestore(app);db.settings({gaxServerStreamingRetries:true});
  let paid=true;
  const workspaces=async()=>({workspaces:[{caseId,status:'live',workspaceId:storeId,profileId:'retailer-grocery',name:'HOST original Store',
    access:{schemaVersion:1,state:'active',accountId:owner.uid,caseId,workspaceId:storeId,profileId:'retailer-grocery',
      checkedAt:at.toISOString(),applicationUpdatedAt:new Date(at.getTime()-1000).toISOString(),
      membership:{schemaVersion:1,state:'active',membershipId:'HOST-order-member',workspaceId:storeId,workspaceProfileId:'retailer-grocery',
        version:1,effectiveFrom:'2026-10-27T00:00:00.000Z',expiresAt:'2026-10-29T00:00:00.000Z'}}}]});
  const plans=new AccountPlansService({async read(uid,scope){return {ownerUid:uid,accountStatus:'ACTIVE',
    catalogue:{audience:scope.audience,revision:1,state:'approved',offers:[]},subscription:{ownerUid:uid,scope,revision:1,
      planId:'host-only-plan',planVersion:'v1',name:'Host fixture only',state:paid?'active':'expired',
      validFrom:'2026-10-27T00:00:00.000Z',validUntil:'2026-10-29T00:00:00.000Z',featureIds:['mool_ai']}};}},
    {projectId:owner.projectId,now:()=>at,readWorkspaces:workspaces});
  const authority=new ProfileWorkspacePreparationContext({profile:{async read(){throw Error('Personal Profile is not an order source');}},
    plans,workspaces,now:()=>at});
  try{
    const profile={schemaVersion:1,caseId,workspaceId:storeId,ownerUserId:owner.uid,familyId:'products-trade',profileId:'retailer-grocery',status:'live',shopEnabled:true};
    await db.collection('workspaceProfiles').doc(caseId).set(profile);
    // Host-only placement receipts seed actual immutable originals through the
    // production materializer. No HTTP issuer or real commerce is enabled.
    for(let index=0;index<13;index++){
      const receipt:TrustedPlacementReceipt={schemaVersion:1,realm:'evaluation',authNamespace:'firebase-default',finalPlacement:true,
        issuer:'HOST-order-fixture',receiptId:`HOST-original-receipt-${index}`,revision:'HOST-source-v1',buyerUserId:'HOST-order-buyer',
        stores:[{storeId,caseId,ownerUserId:owner.uid,lines:[{sourceLineId:'HOST-source-line',skuId:'HOST-sku',canonicalProductId:'HOST-product',
          verifiedPackId:'HOST-pack',offerId:'HOST-offer',offerRevision:'HOST-price-v1',name:'HOST original product',packLabel:'1 kg',
          quantityMilli:1000,quantityUnit:'pack',unitPriceMinor:10025,lineTotalMinor:10025}],
          totals:{itemsMinor:10025,discountMinor:0,taxMinor:0,deliveryMinor:0,freightMinor:0,paymentFeeMinor:0,tipMinor:0,totalMinor:10025}}]};
      await new WorkspacePurchaseProjectionService(db,'evaluation',{async readFinalPlacement(){return receipt;}}).materialize(`HOST-final-source-${index}`);
    }
    const purchases=new WorkspacePurchaseProjectionService(db,'evaluation');
    const orders=new OriginalStoreOrderPreparationContext({projectId:owner.projectId,authority,purchases,now:()=>at});
    const context=new CompositePreparationContext({original:authority,storeOrders:orders});
    const input={method:'POST',headers:{authorization:'Bearer HOST-only','x-firebase-appcheck':'HOST-only'},bodyBytes:100,
      body:{operation:'read',payload:{scope:{audience:'workspace',storeId},nativeSelectionVersion:1}}};
    const reply=await handleAssistantCanonicalContextRequest(input,{projectId:owner.projectId,enabled:true,context,now:()=>at,
      async verifyIdToken(){return owner;},async verifyAppCheck(){return {};}});
    assert.equal(reply.status,200);assert(reply.body.ok);
    if(!reply.body.ok)return;
    const references:PurchaseReference[]=[];let cursor:string|null=null;
    do{const page=await purchases.listStore(owner.uid,{storeId,limit:5,cursor});references.push(...page.references);cursor=page.nextCursor;}while(cursor!==null);
    assert.equal(references.length,13);
    const prepared=await orders.read(owner,{scope:{audience:'workspace',storeId},requestId:'HOST-order-source',requestRevision:1,
      expectedEntitlementRevision:'HOST-read-only',message:'View original order',language:'English',history:[],actionId:'AI-ACT-274',entityId:null});
    assert.equal(prepared.nativeTargets!.length,13);
    const projections=[];
    for(const reference of references){
      const selected=prepared.tools[0]!.resolveTarget!({orderId:reference.orderId});
      assert.equal(selected.entityId,reference.orderId);
      assert.deepEqual(selected.fields,{});
      projections.push(await purchases.readStore(owner.uid,{purchaseId:reference.purchaseId,storeId,orderId:reference.orderId}));
    }
    if(process.env.AI_DOMAIN_ORDER_ORIGINAL_EXPORT_PATH){
      const path=process.env.AI_DOMAIN_ORDER_ORIGINAL_EXPORT_PATH;assert(isAbsolute(path));
      writeFileSync(path,JSON.stringify({kind:'isolated-host-original-service-contract',storeId,ownerUid:owner.uid,references,
        projections,proofs:prepared.nativeTargets},null,2)+'\n',{flag:'wx'});
    }
    const chosen=references.at(-1)!;
    const results=new Map<string,{fingerprint:string;lease:string;result:PreparationState}>();let modelCalls=0,reservations=0;
    // Request/usage storage is an explicit host port here; durable request
    // semantics retain their separate sealed SQL integration qualification.
    const requests:PreparationRequestStore={
      async claim(key,fingerprint){
        const row=results.get(key);if(row)return row.fingerprint===fingerprint?row.result:{state:'conflict'};
        results.set(key,{fingerprint,lease:key,result:{state:'pending'}});return{state:'claimed',lease:key};
      },
      async read(key){return results.get(key)?.result;},
      async finish(key,lease,result){
        const row=results.get(key);assert(row);assert.equal(row.lease,lease);
        if(row.result.state!=='cancelled')row.result=result;return row.result;
      },
      async cancel(key){
        const row=results.get(key);if(!row)return undefined;
        if(row.result.state!=='ready')row.result={state:'cancelled'};return row.result;
      },
    };
    const preparation=new AssistantPreparationService({projectId:owner.projectId,plans,context,requests,now:()=>at,
      usage:{async reserve(){reservations++;return{id:'HOST-order-permit',validUntil:'2026-10-28T08:01:00.000Z'};},async settle(){}},
      model:{async prepare(_request,tools,_signal,modelContext){
        modelCalls++;assert.equal(tools.length,1);assert.equal(tools[0]!.actionId,'AI-ACT-274');
        assert(JSON.stringify(modelContext).includes(chosen.orderId));
        for(const other of references.filter(row=>row.orderId!==chosen.orderId))assert(!JSON.stringify(modelContext).includes(other.orderId));
        return{kind:'tool' as const,name:tools[0]!.name,arguments:{orderId:chosen.orderId}};
      }},
    });
    const payload={scope:{audience:'workspace' as const,storeId},requestId:'HOST-order-preparation',requestRevision:1,
      expectedEntitlementRevision:`workspace:${storeId}:1:1`,message:'Show this original order',language:'English',history:[],
      actionId:'AI-ACT-274',entityId:null,nativeTargets:[{actionId:'AI-ACT-274',entityId:chosen.orderId}]};
    const preparedResult=await preparation.handle(owner,{operation:'prepare',payload});
    assert.equal(preparedResult.state,'ready');
    if(preparedResult.state==='ready'){
      assert.equal(preparedResult.reply.outcome.kind,'proposal');
      if(preparedResult.reply.outcome.kind==='proposal'){
        assert.equal(preparedResult.reply.outcome.entityId,chosen.orderId);assert.deepEqual(preparedResult.reply.outcome.fields,{});
      }
    }
    assert.deepEqual(await preparation.handle(owner,{operation:'prepare',payload}),preparedResult);
    assert.equal(modelCalls,1);assert.equal(reservations,1);
    const countBefore=(await db.collection('workspacePurchaseProjections').doc('evaluation').collection('purchases').get()).size;
    await assert.rejects(purchases.listStore('HOST-foreign-owner',{storeId,limit:5,cursor:null}));
    paid=false;await assert.rejects(orders.read(owner,{scope:{audience:'workspace',storeId},requestId:'HOST-order-source',requestRevision:1,
      expectedEntitlementRevision:'HOST-read-only',message:'View original order',language:'English',history:[],actionId:'AI-ACT-274',entityId:null}));
    paid=true;await db.collection('workspaceProfiles').doc(caseId).update({ownerUserId:'HOST-new-owner'});
    await assert.rejects(orders.read(owner,{scope:{audience:'workspace',storeId},requestId:'HOST-order-source',requestRevision:1,
      expectedEntitlementRevision:'HOST-read-only',message:'View original order',language:'English',history:[],actionId:'AI-ACT-274',entityId:null}));
    assert.equal((await db.collection('workspacePurchaseProjections').doc('evaluation').collection('purchases').get()).size,countBefore);
  }finally{await db.terminate();await deleteApp(app);}
});
test('Private stars actual loopback original completion index rating receiver and authorised AI metadata retain exact purchased lines',{
  skip:!process.env.FIRESTORE_EMULATOR_HOST,timeout:120000,
},async()=>{
  assert.match(process.env.FIRESTORE_EMULATOR_HOST!,/^127\.0\.0\.1:\d+$/u);
  const owner={uid:'buyer-1',projectId:actor.projectId},storeId='HOST-native-store',caseId='HOST-private-case',f=fixture();
  const app=initializeApp({projectId:`demo-ai-stars-${randomUUID().slice(0,8)}`},`host-stars-${randomUUID()}`),db=getFirestore(app);
  db.settings({gaxServerStreamingRetries:true});
  const profile=new AccountProfileService({async readAccount(uid){return {uid,status:'ACTIVE',profile:{ownerUid:uid,revision:1,
    updatedAt:'2026-10-27T00:00:00.000Z',displayName:'Host private buyer',addresses:[],selectedAddressId:null,invoiceProfiles:[]}};},
    async readReceipt(){return undefined;},async commit(){throw Error('No Profile writes in private rating preparation');}},owner.projectId,()=>at);
  const authority=new ProfileWorkspacePreparationContext({profile,plans:f.plans,workspaces:async()=>[],now:()=>at});
  try{
    await db.collection('workspaceProfiles').doc(caseId).set({schemaVersion:1,caseId,workspaceId:storeId,ownerUserId:'HOST-private-seller',
      familyId:'products-trade',profileId:'retailer-grocery',status:'live',shopEnabled:true});
    const purchases=new WorkspacePurchaseProjectionService(db,'evaluation'),projections=[];
    // Accepted host-only source receipts exercise the actual materializers;
    // no public issuer, device provider or real completion is configured.
    for(let index=0;index<7;index++){
      const receipt:TrustedPlacementReceipt={schemaVersion:5,realm:'evaluation',authNamespace:'firebase-default',finalPlacement:true,
        issuer:'HOST-private-placement',receiptId:`HOST-private-receipt-${index}`,revision:'HOST-private-original-v1',buyerUserId:owner.uid,
        stores:[{storeId,caseId,ownerUserId:'HOST-private-seller',lines:[0,1].map(line=>({sourceLineId:`HOST-private-line-${index}-${line}`,
          skuId:`HOST-private-sku-${line}`,canonicalProductId:`HOST-private-product-${line}`,verifiedPackId:`HOST-private-pack-${line}`,
          offerId:`HOST-private-offer-${line}`,offerRevision:'HOST-private-price-v1',name:`Host purchased item ${index}/${line}`,packLabel:'1 kg',variant:'',
          quantityMilli:1000,quantityUnit:'pack',unitPriceMinor:10025,lineTotalMinor:10025,scheduledFulfilment:null,
          publicListing:{schemaVersion:1,realm:'evaluation',storeId,skuId:`HOST-private-sku-${line}`,
            listingId:'listing-'+digest([1,'evaluation',storeId,`HOST-private-sku-${line}`,'retail']),
            canonicalProductId:`HOST-private-product-${line}`,verifiedPackId:`HOST-private-pack-${line}`,channel:'retail'}})),
          benefitAttribution:{schemaVersion:1,components:[]},totals:{itemsMinor:20050,discountMinor:0,taxMinor:0,deliveryMinor:0,freightMinor:0,paymentFeeMinor:0,tipMinor:0,totalMinor:20050}}]};
      const made=await new WorkspacePurchaseProjectionService(db,'evaluation',{async readFinalPlacement(){return receipt;}}).materialize(`HOST-private-placement-${index}`);
      const projection=await purchases.readBuyer(owner.uid,{purchaseId:made.purchaseId}),order=projection.orders[0]!;
      projections.push(projection);
      const original={purchaseId:projection.purchaseId,storeId,orderId:order.orderId,originalFingerprint:order.originalFingerprint,sourceRevision:projection.sourceRevision};
      const ops=new WorkspaceOrderOperationsService(db,'evaluation',{async readOperationalOrder(){return {schemaVersion:1,realm:'evaluation',authNamespace:'firebase-default',
        issuer:'HOST-private-operations',receiptId:`HOST-private-operation-${index}`,revision:'HOST-private-operation-v1',...original,
        customerLabel:'Host buyer',fulfilment:'delivery',address:'Host original delivery',placedAt:new Date(at.getTime()-1000).toISOString(),
        acceptanceDeadline:new Date(at.getTime()+60_000).toISOString(),fulfilmentDeadline:new Date(at.getTime()+3_600_000).toISOString(),initialStage:'Ready',allowedActions:[]};}},()=>at,
        {issuer:'HOST-private-completion',async readCompletion(){return {schemaVersion:1,realm:'evaluation',authNamespace:'firebase-default',issuer:'HOST-private-completion',
          receiptId:`HOST-private-completed-${index}`,revision:'HOST-private-completion-v1',...original,operationalSourceRevision:'HOST-private-operation-v1',
          operationalRevision:1,outcome:'delivered',occurredAt:at.toISOString()};}});
      await ops.initialize(`HOST-private-ready-${index}`);
      const line=order.original.lines[0]!;
      await assert.rejects(ops.readBuyerProductFeedbackTarget(owner.uid,{...original,orderLineId:line.lineId}));
      await ops.recordCompletion(`HOST-private-completed-${index}`);
    }
    const operations=new WorkspaceOrderOperationsService(db,'evaluation',undefined,()=>at);
    const source=new OriginalPurchasedStarsPreparationContext({projectId:owner.projectId,authority,operations,now:()=>at});
    const context=new CompositePreparationContext({original:authority,privateStars:source});
    const input={scope:{audience:'personal' as const,storeId:null},requestId:'HOST-private-source',requestRevision:1,
      expectedEntitlementRevision:'personal:null:1:1',message:'Give four private stars to the purchased item',language:'English',history:[],actionId:'AI-ACT-055',entityId:null};
    const prepared=await source.read(owner,input);assert.equal(prepared.nativeTargets!.length,7);
    const targets:ProductFeedbackTarget[]=[];let cursor:string|null=null;
    do{const page=await operations.listBuyerProductFeedbackTargets(owner.uid,{limit:5,cursor});targets.push(...page.targets);cursor=page.nextCursor;}while(cursor!==null);
    assert.equal(targets.length,14);assert.equal((await operations.listBuyerProductFeedbackTargets('HOST-foreign-buyer',{limit:5,cursor:null})).targets.length,0);
    const response=await handleAssistantCanonicalContextRequest({method:'POST',headers:{authorization:'Bearer HOST-only','x-firebase-appcheck':'HOST-only'},
      bodyBytes:100,body:{operation:'read',payload:{scope:input.scope}}},{projectId:owner.projectId,enabled:true,context,now:()=>at,
        async verifyIdToken(){return owner;},async verifyAppCheck(){return {};}});
    assert.equal(response.status,200);assert(response.body.ok);
    assert.equal((await db.collection('workspacePurchaseProjections').doc('evaluation').collection('productStarRatings').get()).size,0);
    if(process.env.AI_DOMAIN_PRIVATE_STARS_EXPORT_PATH){
      const path=process.env.AI_DOMAIN_PRIVATE_STARS_EXPORT_PATH;assert(isAbsolute(path));
      writeFileSync(path,JSON.stringify({kind:'isolated-host-private-stars-original-service-contract',buyerUid:owner.uid,targets,projections,
        proofs:prepared.nativeTargets},null,2)+'\n',{flag:'wx'});
    }
    const first=targets[0]!,before=prepared.nativeTargets!.find(t=>t.entityId===first.orderId)!;
    const tool=prepared.tools[0]!,selected=tool.resolveTarget!({orderId:first.orderId,lineId:first.orderLineId,stars:4});
    assert.deepEqual(selected.fields,{lineId:first.orderLineId,stars:4});
    const saved=await operations.submitProductStars(owner.uid,{targetId:first.id,expectedRevision:0,operationId:'HOST-private-native-save',stars:2});
    assert.equal(saved.rating?.stars,2);assert.equal(saved.rating?.revision,1);
    const changed=await source.read(owner,{...input,entityId:first.orderId});assert.notEqual(changed.tools[0]!.sourceRevision,before.sourceRevision);
    assert.equal((await operations.readBuyerProductStars(owner.uid,{targetId:first.id}))!.stars,2);
    await assert.rejects(operations.readBuyerProductStars('HOST-foreign-buyer',{targetId:first.id}));
    f.deny();await assert.rejects(source.read(owner,input),/ai_access_required/u);
  }finally{await db.terminate();await deleteApp(app);}
});
/** Actual production services; explicit host-only empty directory/subscription ports. */
function fixture() {
  let reads = 0, writes = 0, state = "active", revoke = false, malformed = false;
  const plans = new AccountPlansService({async read(uid, scope) {return {ownerUid: uid, accountStatus: "ACTIVE",
    catalogue: {audience: scope.audience, revision: 1, state: "approved", offers: []},
    subscription: {ownerUid: uid, scope, revision: 1, planId: "host-only-plan", planVersion: "v1", name: "Host fixture only",
      state, validFrom: "2026-10-27T00:00:00.000Z", validUntil: "2026-10-29T00:00:00.000Z", featureIds: ["mool_ai"]}};}},
  {projectId: actor.projectId, now: () => at});
  const repository: WorkspaceCatalogueRepository = {realm: "evaluation", async store() {return undefined;},
    async save() {writes++; throw Error("No fixture writes permitted");}, async page() {return [];}, async catalogue() {return undefined;},
    async publicDiscoveryBindings() {reads++; if (revoke) state = "revoked";
      if (malformed) throw Error("Original directory cannot be confirmed"); return [];},
    async publicCatalogueSource() {return undefined;}};
  const catalogue = new WorkspaceCatalogueService(repository,
    {catalogueId: "host-catalogue", tenantId: "host-catalogue-tenant"}, () => at);
  const domain = new OriginalCataloguePreparationContext({projectId: actor.projectId, plans, catalogue, now: () => at});
  const deps = {projectId: actor.projectId, enabled: true, context: new CompositePreparationContext({catalogue: domain}),
    now: () => at, async verifyIdToken() {return actor;}, async verifyAppCheck() {return {};}};
  const input = {method: "POST", headers: {authorization: "Bearer isolated-host-proof", "x-firebase-appcheck": "isolated-host-proof"},
    bodyBytes: 100, body: {operation: "read", payload: {scope: {audience: "personal", storeId: null}}}};
  return {deps, input, plans, counts: () => ({reads, writes}), deny: () => {state = "revoked";}, revoke: () => {revoke = true;}, malformed: () => {malformed = true;}};
}
test("Domain actual HTTP Plans catalogue and source composition produce canonical search metadata", async () => {
  const f = fixture(), response = await handleAssistantCanonicalContextRequest(f.input, f.deps);
  assert.equal(response.status, 200); assert.ok(response.body.ok);
  if (!response.body.ok) return;
  assert.deepEqual(response.body.data.revisions.map(r => [r.actionId, r.entityId]), [["AI-ACT-001", null], ["AI-ACT-005", null]]);
  assert.match(response.body.data.revisions[0]!.sourceRevision, /^catalogue-search:[a-f0-9]{64}$/u);
  assert.ok(f.counts().reads >= 4); assert.equal(f.counts().writes, 0);
  assert.ok(!JSON.stringify(response).includes("host-catalogue-tenant"));
});
test("Domain original Plans revocation during actual catalogue reads retires the result", async () => {
  const f = fixture(); f.revoke(); const response = await handleAssistantCanonicalContextRequest(f.input, f.deps);
  assert.notEqual(response.status, 200); assert.equal(response.body.ok, false); assert.equal(f.counts().writes, 0);
});
test("Domain incomplete actual original directory is unavailable rather than fabricated public data", async () => {
  const f = fixture(); f.malformed(); const response = await handleAssistantCanonicalContextRequest(f.input, f.deps);
  assert.equal(response.status, 503); assert.equal(response.body.ok, false); assert.equal(f.counts().writes, 0);
});

test("Owned native preference review reuses original Profile and paid access without reading or writing a second preference master", async () => {
  const f = fixture(); let reads = 0, writes = 0, missingProfile = false;
  const profile = new AccountProfileService({async readAccount(uid) {
    reads++; return {uid, status: "ACTIVE", profile: missingProfile ? null : {ownerUid: uid, revision: 1,
      updatedAt: "2026-10-27T00:00:00.000Z", displayName: "Isolated host account",
      addresses: [], selectedAddressId: null, invoiceProfiles: []}};
  }, async readReceipt() {return undefined;}, async commit() {writes++; throw Error("Forbidden host write");}}, actor.projectId, () => at);
  const original = new ProfileWorkspacePreparationContext({profile, plans: f.plans, workspaces: async () => [], now: () => at});
  const source = new CompositePreparationContext({original, nativePreferencesEnabled: true});
  const input = {scope: {audience: "personal" as const, storeId: null}, requestId: "host-preference-request", requestRevision: 1,
    message: "Show my saved products", language: "English", history: [], expectedEntitlementRevision: "personal:null:1:1", actionId: "AI-ACT-010", entityId: null};
  for (const actionId of ["AI-ACT-010", "AI-ACT-011", "AI-ACT-012", "AI-ACT-013"]) {
    const context = await source.read(actor, {...input, actionId});
    assert.equal(context.tools.length, 1); assert.equal(context.tools[0]!.actionId, actionId);
    if (actionId === "AI-ACT-012") assert.match(context.tools[0]!.description, /clearing my recently viewed/u);
    assert.equal(context.tools[0]!.validate({}), true);
    assert.equal(context.tools[0]!.validate({saved: []}), false);
    assert.match(context.revision, /^native-preferences-owner:[a-f0-9]{64}$/u);
    assert.equal(context.modelContext?.saved, undefined);
  }
  assert.equal(reads, 8); assert.equal(writes, 0);
  missingProfile = true;
  await assert.rejects(source.read(actor, input), /profile_record_unavailable/u);
  missingProfile = false;
  await assert.rejects(source.read(actor, {...input, entityId: "foreign"}), /context_unavailable/u);
  await assert.rejects(source.read(actor, {...input, scope: {audience: "workspace", storeId: "store-a"}}), /context_unavailable/u);
  await assert.rejects(new CompositePreparationContext({original}).read(actor, input), /context_unavailable/u);
  const firstOwner = await source.read(actor, input);
  const otherOwner = await source.read({...actor, uid: "other-account"}, input);
  assert.notEqual(firstOwner.revision, otherOwner.revision);
  f.deny();
  await assert.rejects(source.read(actor, input), /ai_access_required/u);
  assert.equal(writes, 0);
});

/** Only the already-qualified request/usage/model boundaries are isolated here.
 * Production continues using its existing durable request and usage classes. */
class HostRequests implements PreparationRequestStore {
  readonly rows = new Map<string, {fingerprint: string; lease: string; result: PreparationState}>();
  async claim(key: string, fingerprint: string) {
    const row = this.rows.get(key);
    if (row) return row.fingerprint === fingerprint ? row.result : {state: "conflict" as const};
    this.rows.set(key, {fingerprint, lease: key, result: {state: "pending"}});
    return {state: "claimed" as const, lease: key};
  }
  async read(key: string) {return this.rows.get(key)?.result;}
  async finish(key: string, lease: string, result: PreparationState) {
    const row = this.rows.get(key)!; assert.equal(row.lease, lease);
    if (row.result.state !== "cancelled") row.result = result;
    return row.result;
  }
  async cancel(key: string) {
    const row = this.rows.get(key); if (!row) return undefined;
    if (row.result.state !== "ready") row.result = {state: "cancelled"}; return row.result;
  }
}

for (const actionId of ['AI-ACT-024', 'AI-ACT-027']) test(`Domain original Profile address ${actionId} prepares only an owned choice and recovers without a write`, async () => {
  const f = fixture(); let writes = 0, revision = 3, changes = false;
  const profile = new AccountProfileService({async readAccount() {if (changes) revision++;
    return {uid: actor.uid, status: 'ACTIVE', profile: {ownerUid: actor.uid, revision, updatedAt: '2026-10-27T00:00:00.000Z',
      displayName: 'HOST owner', selectedAddressId: 'address-one', invoiceProfiles: [], addresses: [
        {id: 'address-one', label: 'Home', kind: 'home', recipient: 'Private recipient', phone: '9999999999',
          line: 'Private street', area: 'Jodhpur', pinCode: '342001', landmark: ''},
        {id: 'address-two', label: 'Office', kind: 'work', recipient: 'Private other', phone: '9999999999',
          line: 'Private other street', area: 'Jaipur', pinCode: '302001', landmark: ''}]}};
  }, async readReceipt() {return undefined;}, async commit() {writes++; throw Error('No preparation writes');}}, actor.projectId, () => at);
  const original = new ProfileWorkspacePreparationContext({profile, plans: f.plans, workspaces: async () => [], now: () => at});
  const source = new CompositePreparationContext({original, nativeBuyerFormsEnabled: true});
  const input = {scope: {audience: 'personal' as const, storeId: null}, requestId: `HOST-address-${actionId}`, requestRevision: 1,
    message: 'Use my Home address', language: 'English', history: [], expectedEntitlementRevision: 'personal:null:1:1', actionId, entityId: null};
  const context = await source.read(actor, input), tool = context.tools[0]!;
  assert.equal(context.tools.length, 1); assert.equal(tool.targetSelector, 'addressId');
  assert.deepEqual(tool.resolveTarget!({addressId: 'address-one'}), {entityId: 'address-one', sourceRevision: 'profile:3', fields: {},
    title: actionId === 'AI-ACT-024' ? 'Review delivery address' : 'Review address removal', summary: 'Home · Jodhpur'});
  for (const args of [{addressId: 'foreign'}, {addressId: 'address-one', phone: 'invented'}, {addressId: 'address-one', approved: true}]) assert.throws(() => tool.resolveTarget!(args));
  for (const privateText of ['Private street', 'Private recipient', '9999999999', '342001']) assert.ok(!JSON.stringify(context.modelContext).includes(privateText));
  const requests = new HostRequests(); let models = 0;
  const service = () => new AssistantPreparationService({projectId: actor.projectId, plans: f.plans, context: source, requests, now: () => at,
    usage: {async reserve() {return {id: 'HOST-address-permit', validUntil: '2026-10-28T08:01:00.000Z'};}, async settle() {}},
    model: {async prepare(_input, tools) {models++; return {kind: 'tool', name: tools[0]!.name, arguments: {addressId: 'address-one'}};}}});
  const payload = {...input, nativeTargets: [{actionId, entityId: 'address-one'}]};
  const prepared = await service().handle(actor, {operation: 'prepare', payload});
  assert.equal(prepared.state, 'ready');
  if (prepared.state === 'ready' && prepared.reply.outcome.kind === 'proposal') {
    assert.equal(prepared.reply.outcome.entityId, 'address-one'); assert.deepEqual(prepared.reply.outcome.fields, {});
  } else assert.fail('Expected exact saved address proposal');
  assert.deepEqual(await service().handle(actor, {operation: 'prepare', payload}), prepared);
  assert.deepEqual(await service().handle(actor, {operation: 'status', payload: {scope: input.scope, requestId: input.requestId}}), prepared);
  assert.equal(models, 1); assert.equal(writes, 0);
  await assert.rejects(source.read(actor, {...input, entityId: 'foreign'}));
  await assert.rejects(source.read({...actor, uid: 'foreign-user'}, input));
  await assert.rejects(source.read(actor, {...input, scope: {audience: 'workspace', storeId: 'foreign'}}));
  revision++;
  await assert.rejects(service().handle(actor, {operation: 'status', payload: {scope: input.scope, requestId: input.requestId}}));
  changes = true; await assert.rejects(source.read(actor, input), /stale_preparation/u); changes = false;
  f.deny(); await assert.rejects(source.read(actor, input), /ai_access_required/u); assert.equal(writes, 0);
});
test("Domain original preparation service accepts only the source-bound native search and reconciles duplicate request", async () => {
  const f = fixture(); let models = 0; const settled: string[] = [];
  const service = new AssistantPreparationService({projectId: actor.projectId, plans: f.plans,
    context: f.deps.context, requests: new HostRequests(), now: () => at,
    usage: {async reserve() {return {id: "host-technical-permit", validUntil: "2026-10-28T08:01:00.000Z"};},
      async settle(_id, state) {settled.push(state);}},
    model: {async prepare(_request, tools) {
      models++; assert.equal(tools.length, 1); assert.equal(tools[0]!.actionId, "AI-ACT-001");
      return {kind: "tool", name: tools[0]!.name, arguments: {query: "  चावल   5kg "}};
    }},
  });
  const payload = {scope: {audience: "personal" as const, storeId: null}, requestId: "host-original-search",
    requestRevision: 1, expectedEntitlementRevision: "personal:null:1:1", message: "Find rice", language: "English",
    history: [], actionId: "AI-ACT-001", entityId: null};
  const result = await service.handle(actor, {operation: "prepare", payload});
  assert.equal(result.state, "ready"); if (result.state !== "ready") return;
  assert.equal(result.reply.outcome.kind, "proposal");
  if (result.reply.outcome.kind === "proposal") {
    assert.equal(result.reply.outcome.actionId, "AI-ACT-001");
    assert.deepEqual(result.reply.outcome.fields, {query: "चावल 5kg"});
    assert.match(result.reply.outcome.sourceRevision, /^catalogue-search:[a-f0-9]{64}$/u);
  }
  assert.deepEqual(await service.handle(actor, {operation: "prepare", payload}), result);
  assert.equal(models, 1); assert.deepEqual(settled, ["completed"]); assert.equal(f.counts().writes, 0);
  f.revoke(); await assert.rejects(service.handle(actor, {operation: "status", payload: {scope: payload.scope, requestId: payload.requestId}}));
  assert.equal(models, 1); assert.equal(f.counts().writes, 0);
});
