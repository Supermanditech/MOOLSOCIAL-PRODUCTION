import test from "node:test";
import assert from "node:assert/strict";
import {AccountPlansService} from "../account/plans_service.js";
import {CompositePreparationContext, OriginalCataloguePreparationContext, OriginalStoreOrderPreparationContext, OriginalPurchasedStarsPreparationContext} from "./domain_context.js";
import type {PurchaseReferencePage,ProductFeedbackTarget,ProductFeedbackTargetPage} from "../workspace/workspace_purchase_projection_service.js";
import {AssistantModelError, digest, type PreparationContext, type PreparationRequest} from "./model_contract.js";
import {canonicalContextProjection, storeProductActions} from "./domain_context_contract.js";

const actor = {uid: "domain-host-a", projectId: "domain-host-project"};
const at = new Date("2026-10-28T08:00:00.000Z");
const scope = {audience: "personal" as const, storeId: null};
const request: PreparationRequest = {scope, requestId: "host-request", requestRevision: 1,
  message: "Find rice", language: "English", history: [], actionId: "AI-ACT-001", entityId: null,
  expectedEntitlementRevision: "personal:null:1:1"};

/** Isolated existing completion-index port; no runtime completions are minted. */
function privateStarsFixture(count=13){
  const calls:Readonly<Record<string,unknown>>[]=[];
  let revision=1,ratingRevision=0,denied=false,ratingUnavailable=false,clock=new Date(at),mutate=(page:ProductFeedbackTargetPage,_call:number)=>page;
  const targets:ProductFeedbackTarget[]=Array.from({length:count},(_,i)=>{
    const listing={schemaVersion:1 as const,realm:'evaluation' as const,listingId:'host-listing-'+i,storeId:'host-seller',skuId:'host-sku-'+i,
      canonicalProductId:'host-product-'+i,verifiedPackId:'host-pack-'+i,channel:'retail' as const};
    listing.listingId='listing-'+digest([1,listing.realm,listing.storeId,listing.skuId,listing.channel]);
    const target={id:'',kind:'product' as const,purchaseId:'host-purchase',storeId:listing.storeId,orderId:'host-order-'+Math.floor(i/2),
      orderLineId:'host-line-'+i,productId:listing.listingId,productLabel:'Host purchased item '+i,
      originalFingerprint:'a'.repeat(64),sourceRevision:'source-v1',purchasedListing:listing,
      completedAt:'2026-10-27T08:00:00.000Z',completionId:'completion-'+'b'.repeat(64),completionRevision:'completion-v1'};
    target.id='feedback-'+digest([1,'evaluation','firebase-default',actor.uid,target.purchaseId,target.storeId,target.orderId,target.orderLineId,
      target.originalFingerprint,target.sourceRevision,target.productLabel,listing.listingId,listing.skuId,listing.canonicalProductId,
      listing.verifiedPackId,listing.channel,target.completionId,target.completionRevision,target.completedAt]);
    return target;
  });
  const source=new OriginalPurchasedStarsPreparationContext({projectId:actor.projectId,now:()=>clock,
    authority:{async read(_actor,input){
      if(denied)throw new AssistantModelError('ai_access_required',403);
      assert.equal(input.actionId,null);assert.equal(input.entityId,null);
      return {revision:'profile:'+revision,validUntil:'2026-10-28T08:01:00.000Z',modelContext:{audience:'personal'},
        tools:[{name:'host-personal-profile',actionId:'AI-ACT-196',entityId:null,sourceRevision:'profile:'+revision,
          description:'Host fixture authority',parameters:{},validate:()=>true}]};
    }},operations:{async listBuyerProductFeedbackTargets(uid,body){
      assert.equal(uid,actor.uid);assert.equal(body.limit,5);calls.push({...body});
      const offset=body.cursor===null?0:Number(String(body.cursor).split(':')[1]);
      return mutate({schemaVersion:1,realm:'evaluation',authNamespace:'firebase-default',viewerRole:'buyer',viewerUserId:uid,
        coverage:'indexed_recorded_completions',targets:structuredClone(targets.slice(offset,offset+5)),
        nextCursor:offset+5<targets.length?'host-stars:'+String(offset+5):null},calls.length);
    },async readBuyerProductStars(uid,body){
      assert.equal(uid,actor.uid);if(ratingUnavailable)throw new Error('Host original rating unavailable');
      const target=targets.find(target=>target.id===body.targetId);assert(target);
      return ratingRevision===0?null:{target:structuredClone(target),revision:ratingRevision,stars:3,updatedAt:'2026-10-28T07:00:00.000Z'};
    }}});
  const input={...request,actionId:'AI-ACT-055',entityId:null,message:'Give the purchased item four private stars'};
  return {source,input,targets,calls,deny:()=>{denied=true;},bump:()=>{revision++;},advance:(ms:number)=>{clock=new Date(clock.getTime()+ms);},
    mutate:(f:typeof mutate)=>{mutate=f;},rate:()=>{ratingRevision++;},ratingUnavailable:()=>{ratingUnavailable=true;}};
}
test('Private stars source traverses all original completion pages and binds exact order and purchased line',async()=>{
  const f=privateStarsFixture(),value=await f.source.read(actor,f.input),last=f.targets.at(-1)!;
  assert.equal(f.calls.length,6);assert.equal(value.nativeTargets!.length,7);
  const tool=value.tools[0]!,target=tool.resolveTarget!({orderId:last.orderId,lineId:last.orderLineId,stars:4});
  assert.equal(target.entityId,last.orderId);assert.deepEqual(target.fields,{lineId:last.orderLineId,stars:4});assert(tool.validate(target.fields));
  assert.throws(()=>tool.resolveTarget!({orderId:last.orderId,lineId:f.targets[0]!.orderLineId,stars:4}),/invalid_model_result/u);
  for(const fields of [{lineId:last.orderLineId,stars:6},{lineId:last.orderLineId,stars:0},{lineId:last.orderLineId,stars:4,comment:'public review'}])
    assert.equal(tool.validate(fields),false);
  assert(!JSON.stringify(value.modelContext).includes('originalFingerprint'));assert(!JSON.stringify(value.modelContext).includes('feedback-'));
  const recovered=await f.source.readPrepared(actor,{...f.input,entityId:last.orderId},{kind:'proposal',id:'host-private-proposal',
    actionId:'AI-ACT-055',entityId:last.orderId,sourceRevision:target.sourceRevision,title:'Private stars',summary:'Host fixture',fields:target.fields});
  assert.equal(recovered.tools[0]!.sourceRevision,target.sourceRevision);
});
for(const fault of ['foreign','realm','coverage','duplicate','cursor-cycle','identity','future'])test(`Private stars rejects original ${fault} without fabricated eligibility`,async()=>{
  const f=privateStarsFixture();f.mutate((page,call)=>{
    if(fault==='foreign')page.viewerUserId='foreign-buyer';
    if(fault==='realm'&&call===2)page.realm='production';
    if(fault==='coverage')page.coverage='not-original' as typeof page.coverage;
    if(fault==='duplicate'&&call===2)page.targets[0]={...f.targets[0]!};
    if(fault==='cursor-cycle')page.nextCursor='host-stars:5';
    if(fault==='identity')page.targets[0]!.originalFingerprint='c'.repeat(64);
    if(fault==='future')page.targets[0]!.completedAt='2026-10-29T08:00:00.000Z';
    return page;
  });await assert.rejects(f.source.read(actor,f.input),/context_unavailable/u);
});
test('Private stars source denies Workspace or foreign account and does not turn public review into private feedback',async()=>{
  const f=privateStarsFixture();
  await assert.rejects(f.source.read({...actor,projectId:'other-project'},f.input),/account_scope_mismatch/u);
  await assert.rejects(f.source.read(actor,{...f.input,scope:{audience:'workspace',storeId:'host-seller'}}),/context_unavailable/u);
  for(const actionId of ['AI-ACT-054','AI-ACT-056'])await assert.rejects(f.source.read(actor,{...f.input,actionId}),/context_unavailable/u);
  f.deny();await assert.rejects(f.source.read(actor,f.input),/ai_access_required/u);assert.equal(f.calls.length,0);
});
test('Private stars source detects changed authority or a slow complete index',async()=>{
  const changed=privateStarsFixture();changed.mutate((page,call)=>{if(call===6)changed.bump();return page;});
  await assert.rejects(changed.source.read(actor,changed.input),/stale_preparation/u);
  const slow=privateStarsFixture();slow.mutate((page,call)=>{if(call===2)slow.advance(60_001);return page;});
  await assert.rejects(slow.source.read(actor,slow.input),/stale_preparation/u);assert.equal(slow.calls.length,2);
  const empty=privateStarsFixture(0),value=await empty.source.read(actor,empty.input);assert.deepEqual(value.tools,[]);
  await assert.rejects(empty.source.read(actor,{...empty.input,entityId:'missing-order'}),/context_unavailable/u);
});
test('Private stars proof includes original saved-rating revision and never confuses unavailable with no rating',async()=>{
  const f=privateStarsFixture(),before=await f.source.read(actor,f.input);f.rate();
  const after=await f.source.read(actor,f.input);
  assert.notEqual(before.nativeTargets![0]!.sourceRevision,after.nativeTargets![0]!.sourceRevision);
  f.ratingUnavailable();await assert.rejects(f.source.read(actor,f.input),/context_unavailable/u);
  const changed=privateStarsFixture();changed.mutate((page,call)=>{if(call===4)changed.rate();return page;});
  await assert.rejects(changed.source.read(actor,changed.input),/stale_preparation/u);
});

/** Isolated original-reader contract port; never installed as a runtime source. */
function originalOrderFixture(count=13) {
  const calls: Readonly<Record<string, unknown>>[]=[];
  let authorityRevision=1,denied=false,clock=new Date(at);
  let mutate=(page:PurchaseReferencePage,_call:number)=>page;
  const rows=Array.from({length:count},(_,i)=>({purchaseId:`host-purchase-${i}`,storeId:'host-order-store',
    orderId:`host-order-${String(i).padStart(4,'0')}`,originalFingerprint:'a'.repeat(64),sourceRevision:'source-v1'}));
  const source=new OriginalStoreOrderPreparationContext({projectId:actor.projectId,now:()=>clock,
    authority:{async read(_actor,input){
      if(denied)throw new AssistantModelError('workspace_access_unavailable',403);
      assert.equal(input.actionId,null);assert.equal(input.entityId,null);
      return {revision:`host-owner:${authorityRevision}`,validUntil:'2026-10-28T08:01:00.000Z',
        modelContext:{audience:'workspace',current:{id:'host-order-store'}},
        tools:[{name:'host-current-owner',actionId:'AI-ACT-317',entityId:'host-order-store',sourceRevision:'host-owner',
          description:'Host authority fixture',parameters:{},validate:()=>true}]};
    }},purchases:{async listStore(uid,body){
      assert.equal(uid,actor.uid);assert.equal(body.storeId,'host-order-store');assert.equal(body.limit,5);
      calls.push({...body});const offset=body.cursor===null?0:Number(String(body.cursor).split(':')[1]);
      assert(Number.isInteger(offset));
      return mutate({schemaVersion:2,realm:'evaluation',authNamespace:'firebase-default',viewerRole:'seller',viewerUserId:actor.uid,
        storeId:'host-order-store',coverage:'indexed_original_facts',references:structuredClone(rows.slice(offset,offset+5)),
        nextCursor:offset+5<rows.length?`host-cursor:${offset+5}`:null},calls.length);
    }}});
  const input:PreparationRequest={...request,scope:{audience:'workspace',storeId:'host-order-store'},message:'View the original order',actionId:'AI-ACT-274'};
  return {source,input,rows,calls,mutate:(f:typeof mutate)=>{mutate=f;},deny:()=>{denied=true;},changeOwner:()=>{authorityRevision++;},
    advance:(ms:number)=>{clock=new Date(clock.getTime()+ms);}};
}
test('Order originals preparation follows every original reference page and resolves exact final order',async()=>{
  const f=originalOrderFixture(),value=await f.source.read(actor,f.input);
  assert.equal(f.calls.length,6);assert.equal(value.nativeTargets!.length,13);
  assert.deepEqual(f.calls.map(call=>call.cursor),[null,'host-cursor:5','host-cursor:10',null,'host-cursor:5','host-cursor:10']);
  const target=value.tools[0]!.resolveTarget!({orderId:f.rows.at(-1)!.orderId});
  assert.equal(target.entityId,f.rows.at(-1)!.orderId);assert.deepEqual(target.fields,{});
  assert.equal(value.tools[0]!.validate({}),true);assert.equal(value.tools[0]!.validate({paymentState:'paid'}),false);
  assert(!JSON.stringify(value.modelContext).includes('originalFingerprint'));
  assert.throws(()=>value.tools[0]!.resolveTarget!({orderId:'another-store-order'}),/invalid_model_result/u);
});
test('Order originals exact recovery reads beyond first page and preserves the original proof',async()=>{
  const f=originalOrderFixture(),initial=await f.source.read(actor,f.input),target=initial.tools[0]!.resolveTarget!({orderId:f.rows[11]!.orderId});
  const prepared=await f.source.readPrepared(actor,{...f.input,entityId:target.entityId},{kind:'proposal',id:'host-prepared-order',
    actionId:'AI-ACT-274',entityId:target.entityId,sourceRevision:target.sourceRevision,title:'View original',summary:'Host fixture',fields:{}});
  assert.equal(prepared.tools[0]!.sourceRevision,target.sourceRevision);assert.equal(prepared.tools[0]!.entityId,target.entityId);
  await assert.rejects(f.source.read(actor,{...f.input,entityId:'missing-order'}),/context_unavailable/u);
  await assert.rejects(f.source.readPrepared(actor,f.input,{kind:'proposal',id:'host-prepared-order',actionId:'AI-ACT-274',
    entityId:target.entityId,sourceRevision:target.sourceRevision,title:'View original',summary:'Host fixture',fields:{}}),/stale_preparation/u);
});
test('Order originals reject foreign actor personal scope and missing approval before original reads',async()=>{
  const f=originalOrderFixture();
  await assert.rejects(f.source.read({...actor,projectId:'foreign-project'},f.input),/account_scope_mismatch/u);
  await assert.rejects(f.source.read(actor,{...f.input,scope}),/context_unavailable/u);
  f.deny();await assert.rejects(f.source.read(actor,f.input),/workspace_access_unavailable/u);assert.equal(f.calls.length,0);
});
for(const fault of ['actor','store','realm','coverage','duplicate','cursor-cycle'])test(`Order originals reject malformed original ${fault} without fallback`,async()=>{
  const f=originalOrderFixture();f.mutate((page,call)=>{
    if(fault==='actor')page.viewerUserId='foreign-owner';
    if(fault==='store')page.references[0]!.storeId='foreign-store';
    if(fault==='realm'&&call===2)page.realm='production';
    if(fault==='coverage')page.coverage='saved_original_facts';
    if(fault==='duplicate'&&call===2)page.references[0]={...f.rows[0]!};
    if(fault==='cursor-cycle')page.nextCursor='host-cursor:5';
    return page;
  });await assert.rejects(f.source.read(actor,f.input),/context_unavailable/u);
});
test('Order originals reject source or authority changes during the two original reads',async()=>{
  const changed=originalOrderFixture();changed.mutate((page,call)=>{
    if(call===4)page.references[0]!.originalFingerprint='b'.repeat(64);return page;
  });await assert.rejects(changed.source.read(actor,changed.input),/stale_preparation/u);
  const owner=originalOrderFixture();owner.mutate((page,call)=>{if(call===6)owner.changeOwner();return page;});
  await assert.rejects(owner.source.read(actor,owner.input),/stale_preparation/u);
});
test('Empty original index stays empty and does not manufacture an order',async()=>{
  const f=originalOrderFixture(0),value=await f.source.read(actor,f.input);
  assert.deepEqual(value.tools,[]);assert.deepEqual(value.nativeTargets,[]);assert.equal(f.calls.length,2);
});
test('Order originals stop a slow original index at the existing capture deadline without accepting a prefix',async()=>{
  const f=originalOrderFixture();f.mutate((page,call)=>{if(call===2)f.advance(60_001);return page;});
  await assert.rejects(f.source.read(actor,f.input),/stale_preparation/u);
  assert.equal(f.calls.length,2);
});
for(const [productCount,orderCount,accepted] of [[2500,2487,true],[2500,2488,false],[0,5000,true],[0,5001,false]] as const)
test(`Complete optional order index respects shared protocol capacity: ${productCount} products, ${orderCount} orders`,async()=>{
  const f=originalOrderFixture(orderCount);
  const rootActions=['218','219','372','213','215','224','225','374','231','232','233','407','408'];
  const targets:Array<{actionId:string;entityId:string|null;sourceRevision:string}>=[];
  const base:PreparationContext={revision:'host-capacity-original',validUntil:'2026-10-28T08:01:00.000Z',
    tools:[{name:'host-current-owner',actionId:'AI-ACT-317',entityId:'host-order-store',sourceRevision:'host-owner',
      description:'Host original authority',parameters:{},validate:()=>true}],nativeTargets:targets};
  targets.push({actionId:'AI-ACT-317',entityId:'host-order-store',sourceRevision:'host-owner'});
  if(productCount){
    for(let i=0;i<productCount;i++)for(const actionId of storeProductActions)
      targets.push({actionId,entityId:`host-capacity-sku-${i}`,sourceRevision:`host-sku-proof-${i}`});
    for(const action of rootActions)targets.push({actionId:`AI-ACT-${action}`,entityId:null,sourceRevision:`host-root-${action}`});
    assert.equal(base.nativeTargets!.length,25014);
  }
  const source=new CompositePreparationContext({original:{async read(){return base;}},storeOrders:f.source});
  const input={...f.input,actionId:null};
  const value=await source.read(actor,input),wire=canonicalContextProjection(actor,input.scope,value,1);
  const orders=value.nativeTargets!.filter(target=>target.actionId==='AI-ACT-274');
  assert.equal(orders.length,accepted?orderCount:0);
  assert.equal(value.nativeTargets!.length,base.nativeTargets!.length+(accepted?orderCount:0));
  assert.equal(value.tools.some(tool=>tool.actionId==='AI-ACT-317'),true);
  assert.equal(value.tools.some(tool=>tool.actionId==='AI-ACT-274'),accepted);
  assert(wire.nativeSelection!.groups.length<=5000);
  if(accepted)assert.equal(wire.nativeSelection!.groups.length,5000);
  else assert.deepEqual(value,base);
});
/** Original Plans class, explicit isolated host subscription and catalogue seams. */
function fixture() {
  let state = "active", revision = 1, reads = 0, clock = new Date(at), change = false, unavailable = false;
  let mutate = (value: Record<string, unknown>) => value;
  let familyReply = (_body: Readonly<Record<string, unknown>>): object => ({state: "unavailable"});
  const familyCalls: Readonly<Record<string, unknown>>[] = [];
  const calls: Readonly<Record<string, unknown>>[] = [];
  const plans = new AccountPlansService({async read(uid, selected) {return {ownerUid: uid, accountStatus: "ACTIVE",
    catalogue: {audience: selected.audience, revision: 1, state: "approved", offers: []},
    subscription: {ownerUid: uid, scope: selected, revision, planId: "host-only", planVersion: "v1", name: "Host-only source",
      state, validFrom: "2026-10-27T00:00:00.000Z", validUntil: "2026-10-29T00:00:00.000Z", featureIds: ["mool_ai"]}};}},
  {projectId: actor.projectId, now: () => clock});
  const catalogue = {async publicDiscovery(body: Readonly<Record<string, unknown>>) {
    reads++; calls.push(body); if (unavailable) throw Error("Private provider failure not for the model");
    return mutate({schemaVersion: 1, realm: "evaluation", discoveryPageVersion: 1, supplierPublishersVersion: 1,
      state: "ready", coverage: "verified_public_only", directoryCoverage: "complete_bounded", orderingAvailable: false,
      observedAt: at.toISOString(), query: body.query, items: [], privateRawSource: "must-not-enter-context",
      page: {snapshotId: (change && reads > 2 ? "b" : "a").repeat(64), startIndex: 0, totalCount: 0, nextCursor: null}});
  }, async publicVariantFamilies(body: Readonly<Record<string, unknown>>) {familyCalls.push(body); return familyReply(body);}};
  return {context: new OriginalCataloguePreparationContext({projectId: actor.projectId, plans, catalogue, now: () => clock}),
    calls, familyCalls, family: (fn: typeof familyReply) => {familyReply = fn;}, reads: () => reads, deny: () => {state = "revoked";}, change: () => {change = true;},
    unavailable: () => {unavailable = true;}, mutate: (fn: typeof mutate) => {mutate = fn;},
    advance: (ms: number) => {clock = new Date(clock.getTime() + ms);}, bump: () => {revision++;}};
}
test("Domain search uses current paid authority and original public snapshots only", async () => {
  const f = fixture(), c = await f.context.read(actor, request);
  assert.equal(f.reads(), 4); assert.deepEqual(c.tools.map(t => t.actionId), ["AI-ACT-001"]);
  assert.equal(c.tools[0]!.entityId, null); assert.ok(c.tools[0]!.sourceRevision.startsWith("catalogue-search:"));
  assert.deepEqual(c.tools[0]!.decodeFields!({query: " rice  5kg "}), {query: "rice 5kg"});
  assert.equal(c.tools[0]!.validate({query: "rice", owner: "other"}), false);
  assert.ok(!JSON.stringify(c.modelContext).includes("must-not-enter-context"));
  assert.deepEqual(f.calls.map(v => (v.query as {destination: string}).destination), ["shop", "wholesale", "shop", "wholesale"]);
});
test("Domain search refuses unpaid, foreign, tenant and unsupported Store context before reading catalogue", async () => {
  const f = fixture(); f.deny(); await assert.rejects(f.context.read(actor, request)); assert.equal(f.reads(), 0);
  for (const who of [{...actor, projectId: "foreign-project"}, {...actor, tenantId: "foreign-tenant"}]) {
    const next = fixture(); await assert.rejects(next.context.read(who, request)); assert.equal(next.reads(), 0);
  }
  const next = fixture(); await assert.rejects(next.context.read(actor, {...request, scope: {audience: "workspace", storeId: "store-a"}}));
  assert.equal(next.reads(), 0);
});
test("Domain search rejects a guessed entity or unregistered action", async () => {
  for (const input of [{...request, entityId: "guessed-product"}, {...request, actionId: "AI-ACT-235"}]) {
    const f = fixture(); await assert.rejects(f.context.read(actor, input)); assert.equal(f.reads(), 0);
  }
});
test("Domain source changes across awaits retire preparation", async () => {
  const f = fixture(); f.change(); await assert.rejects(f.context.read(actor, request), /stale_preparation/u);
});
test("Domain catalogue failures and incomplete or stale original evidence never become zero stock", async () => {
  const failure = fixture(); failure.unavailable(); await assert.rejects(failure.context.read(actor, request), /context_unavailable/u);
  for (const mutate of [(v: Record<string, unknown>) => ({...v, coverage: "demo"}),
    (v: Record<string, unknown>) => ({...v, directoryCoverage: "partial"}),
    (v: Record<string, unknown>) => ({...v, orderingAvailable: true}),
    (v: Record<string, unknown>) => ({...v, observedAt: "2026-10-27T08:00:00.000Z"}),
    (v: Record<string, unknown>) => ({...v, page: {snapshotId: "bad", startIndex: 0, totalCount: 0}})]) {
    const f = fixture(); f.mutate(mutate); await assert.rejects(f.context.read(actor, request));
  }
});
test("Domain paid access is rechecked after catalogue awaits", async () => {
  const f = fixture(); f.mutate(v => {if (f.reads() === 4) f.deny(); return v;});
  await assert.rejects(f.context.read(actor, request));
});
test("Domain composite preserves original Profile and separately selects exact domain actions", async () => {
  const f = fixture(); let originalReads = 0;
  const original = {async read(): Promise<PreparationContext> {originalReads++; return {revision: "profile:3",
    validUntil: "2026-10-28T08:00:30.000Z", tools: [], modelContext: {audience: "personal"}};}};
  const source = new CompositePreparationContext({original, catalogue: f.context});
  assert.equal((await source.read(actor, {...request, actionId: "AI-ACT-197"})).revision, "profile:3");
  assert.equal(originalReads, 1); assert.equal(f.reads(), 0);
  assert.equal((await source.read(actor, request)).tools[0]!.actionId, "AI-ACT-001"); assert.equal(originalReads, 1);
  const merged = await source.read(actor, {...request, actionId: null});
  assert.ok(merged.revision.startsWith("composite:")); assert.equal(merged.validUntil, "2026-10-28T08:00:30.000Z");
});
test("Domain composite missing optional catalogue does not remove established Profile tools", async () => {
  const f = fixture(); f.unavailable();
  const original = {async read(): Promise<PreparationContext> {return {revision: "profile:3", validUntil: "2026-10-28T08:01:00.000Z", tools: []};}};
  const c = new CompositePreparationContext({original, catalogue: f.context});
  assert.equal((await c.read(actor, {...request, actionId: null})).revision, "profile:3");
  await assert.rejects(c.read(actor, request));
  const denied = new CompositePreparationContext({original: {async read() {throw new AssistantModelError("ai_access_required", 403);}}, catalogue: f.context});
  await assert.rejects(denied.read(actor, {...request, actionId: null}), /ai_access_required/u);
});

const originalListingId = (n: number) => "listing-" + n.toString(16).padStart(64, "0");
function populatedFixture(count = 2, channel = "retail", contactReady = false) {
  const f = fixture(), ids = Array.from({length: count}, (_, n) => originalListingId(n + 1));
  f.mutate(data => {
    const query = data.query as {listingIds: string[]; destination: string; categoryId: string; tradeType: string | null};
    const matches = query.destination === (channel === "retail" ? "shop" : "wholesale") &&
      ["all", "grocery"].includes(query.categoryId) && (query.tradeType === null || query.tradeType === channel);
    const selected = matches ? query.listingIds.length ? query.listingIds : ids.slice(0, 1) : [];
    return {...data, items: selected.map(listingId => ({channel, listing: {storeId: "original-store", realm: "evaluation",
      publicStore: {id: "original-store", name: "Original supplier", ...(contactReady ? {details: {
        schemaVersion: 1, realm: "evaluation", storeId: "original-store", state: "ready", revision: 1,
        details: {publicContactPhone: "+919000000000"}}} : {})},
      items: [{skuId: listingId, canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack", content: {title: "Original rice", brand: "Original brand", variant: "", categoryId: "grocery", description: "Untrusted text must stay out", productFacts: {requiresPrescription: false}},
        pack: {label: "5 kg", quantityMilli: 5000, unit: "kg", unitsPerCase: 1},
        channels: [{kind: channel, priceMinor: 10000, mrpMinor: 12000, minimumOrder: 1, quantityStep: 1,
          revision: "original-term", validUntil: "2026-10-28T09:00:00.000Z", supplierTax: {version: 2, rateBasisPoints: 1800, basis: "included"}}],
        listings: [{schemaVersion: 1, realm: "evaluation", listingId, storeId: "original-store", skuId: listingId,
          canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack", channel}]}]}})),
      page: {...data.page as object, totalCount: matches && !query.listingIds.length ? count : selected.length}};
  });
  return {...f, ids};
}
test("Original listing selector maps public record to exact native entity without descriptive instructions", async () => {
  const f = populatedFixture(), c = await f.context.read(actor, {...request, actionId: null, catalogueListingIds: f.ids});
  const tool = c.tools.find(t => t.actionId === "AI-ACT-006")!;
  const result = tool.resolveTarget!({listingId: f.ids[1]});
  assert.equal(result.entityId, f.ids[1]); assert.deepEqual(result.fields, {});
  assert.ok(c.nativeTargets!.some(t => t.entityId === f.ids[1] && t.sourceRevision === result.sourceRevision));
  assert.ok(!JSON.stringify(c.modelContext).includes("Untrusted text"));
  assert.throws(() => tool.resolveTarget!({listingId: originalListingId(99)}));
  assert.throws(() => tool.resolveTarget!({listingId: f.ids[0], owner: "foreign"}));
  const recovered = await f.context.read(actor, {...request, actionId: "AI-ACT-006", entityId: f.ids[1]!});
  assert.equal(recovered.tools.length, 1); assert.equal(recovered.tools[0]!.entityId, result.entityId);
  assert.equal(recovered.tools[0]!.sourceRevision, result.sourceRevision);
  assert.equal(recovered.tools[0]!.validate({}), true);
});
test("Original listing reads batch 201 products within original 50-ID source bound", async () => {
  const f = populatedFixture(201), c = await f.context.read(actor, {...request, actionId: "AI-ACT-006", catalogueListingIds: f.ids});
  assert.equal(c.tools.length, 1); assert.equal(c.nativeTargets!.length, 201);
  assert.equal(f.calls.length, 14);
  assert.ok(f.calls.every(call => ((call.query as {listingIds: string[]}).listingIds.length <= 50)));
});

test("Product preference link and Store-search proposals retain the original listing and native confirmation", async () => {
  const f = populatedFixture(), input = {...request, actionId: null, catalogueListingIds: f.ids};
  const context = await f.context.read(actor, input);
  for (const action of ["AI-ACT-009", "AI-ACT-336", "AI-ACT-337", "AI-ACT-338"]) {
    const tool = context.tools.find(value => value.actionId === action)!;
    assert.ok(tool); assert.equal(tool.targetSelector, "listingId");
    const fields = action === "AI-ACT-009" ? {saved: true} : action === "AI-ACT-338" ? {query: " rice  pack "} : {};
    const result = tool.resolveTarget!({listingId: f.ids[1], ...fields});
    assert.equal(result.entityId, f.ids[1]);
    assert.deepEqual(result.fields, action === "AI-ACT-338" ? {query: "rice pack"} : fields);
    assert.ok(context.nativeTargets!.some(value => value.actionId === action && value.entityId === f.ids[1] && value.sourceRevision === result.sourceRevision));
    assert.throws(() => tool.resolveTarget!({listingId: originalListingId(99), ...fields}));
    assert.throws(() => tool.resolveTarget!({listingId: f.ids[1], ...fields, execute: true}));
    const recovery = await f.context.read(actor, {...request, actionId: action, entityId: f.ids[1]!});
    assert.equal(recovery.tools.length, 1);
    assert.equal(recovery.tools[0]!.sourceRevision, result.sourceRevision);
    assert.equal(recovery.tools[0]!.validate(result.fields), true);
    assert.equal(recovery.tools[0]!.validate({...result.fields, listingId: f.ids[0]}), false);
  }
  assert.equal(context.tools.some(value => value.actionId === "AI-ACT-339"), false);
  assert.equal(context.tools.some(value => value.actionId === "AI-ACT-008"), false);
  await assert.rejects(f.context.read(actor, {...request, actionId: "AI-ACT-339", entityId: f.ids[0]!}), /context_unavailable/u);
});

test("Supplier contact prepares only a ready original public contact and never copies its phone into model context", async () => {
  const f = populatedFixture(1, "retail", true), input = {...request, actionId: "AI-ACT-339", entityId: f.ids[0]!};
  const context = await f.context.read(actor, input);
  assert.equal(context.tools.length, 1);
  assert.equal(context.tools[0]!.actionId, "AI-ACT-339");
  assert.equal(context.tools[0]!.validate({}), true);
  assert.equal(context.tools[0]!.validate({phone: "+919000000000"}), false);
  assert.equal(JSON.stringify(context.modelContext).includes("9000000000"), false);
  assert.equal((context.modelContext as {products: {supplier: {contactAvailable: boolean}}[]}).products[0]!.supplier.contactAvailable, true);
});
test("Missing original listing cannot turn a model selector into an invented product", async () => {
  const f = fixture();
  await assert.rejects(f.context.read(actor, {...request, actionId: "AI-ACT-006", catalogueListingIds: [originalListingId(1)]}), /context_unavailable/u);
});
test("Withdrawn listing disables record actions but preserves independent original search recovery", async () => {
  const f = fixture(), missing = originalListingId(1);
  const context = await f.context.read(actor, {...request, actionId: null, catalogueListingIds: [missing]});
  assert.deepEqual(context.tools.map(tool => tool.actionId), ["AI-ACT-001", "AI-ACT-005"]);
  assert.deepEqual(context.modelContext!.unavailableListingIds, [missing]);
  assert.deepEqual(context.modelContext!.products, []);
  await assert.rejects(f.context.read(actor, {...request, actionId: "AI-ACT-006", entityId: missing}), /context_unavailable/u);
});
test("Category choices come only from original selected records; area search grants no delivery eligibility", async () => {
  const f = populatedFixture(), c = await f.context.read(actor, {...request, actionId: null, catalogueListingIds: f.ids});
  const category = c.tools.find(tool => tool.actionId === "AI-ACT-002")!;
  assert.equal(category.validate({categoryId: "grocery"}), true);
  assert.equal(category.validate({categoryId: "invented-category"}), false);
  assert.equal(category.validate({categoryId: "grocery", storeId: "foreign"}), false);
  assert.equal(c.tools.some(tool => tool.actionId === "AI-ACT-004"), false);
  assert.ok(c.nativeTargets!.some(target => target.actionId === category.actionId && target.sourceRevision === category.sourceRevision));
  const area = c.tools.find(tool => tool.actionId === "AI-ACT-005")!;
  assert.deepEqual(area.decodeFields!({query: " Jaipur "}), {query: "Jaipur"});
  assert.equal(area.validate({query: "Jaipur", deliveryAvailable: true}), false);
});
test("Trade channel selector preserves the original Wholesale/Bulk listing channel", async () => {
  for (const channel of ["wholesale", "bulk"]) {
    const f = populatedFixture(2, channel), c = await f.context.read(actor, {...request, actionId: "AI-ACT-004", catalogueListingIds: f.ids});
    assert.equal(c.tools.length, 1); assert.equal(c.tools[0]!.validate({saleType: channel}), true);
    assert.equal(c.tools[0]!.validate({saleType: channel === "bulk" ? "wholesale" : "bulk"}), false);
    assert.equal(c.tools[0]!.validate({saleType: "retail"}), false);
  }
});
test("Stored category and trade choices re-read originals without persisting the old listing selection", async () => {
  for (const action of ["AI-ACT-002", "AI-ACT-004"]) {
    const f = populatedFixture(2, "wholesale");
    const c = await f.context.read(actor, {...request, actionId: action, catalogueListingIds: f.ids});
    assert.equal(c.tools.length, 1);
    const tool = c.tools[0]!;
    const fields = action === "AI-ACT-002" ? {categoryId: "grocery"} : {saleType: "wholesale"};
    const proposal = {kind: "proposal" as const, id: "host-stored-proposal", actionId: action, entityId: null,
      sourceRevision: tool.sourceRevision, title: tool.description, summary: "Host original choice", fields};
    const source = new CompositePreparationContext({catalogue: f.context});
    const recovered = await source.readPrepared(actor, {...request, actionId: action}, proposal);
    assert.equal(recovered.tools.length, 1); assert.equal(recovered.tools[0]!.sourceRevision, tool.sourceRevision);
    assert.equal(recovered.tools[0]!.validate(fields), true);
    const invalid = {...proposal, fields: action === "AI-ACT-002" ? {categoryId: "invented"} : {saleType: "bulk"}};
    await assert.rejects(source.readPrepared(actor, {...request, actionId: action}, invalid));
    f.deny();
    await assert.rejects(source.readPrepared(actor, {...request, actionId: action}, proposal), /ai_access_required/u);
  }
});
test("Filter preparation applies only requested native fields and preserves unrelated native choices", async () => {
  const f = populatedFixture(), c = await f.context.read(actor, {...request, actionId: "AI-ACT-003", catalogueListingIds: f.ids});
  const tool = c.tools[0]!, args = {apply: ["sort"], brands: [], maximumPrice: null, pack: null,
    sort: "priceLowToHigh", availableOnly: false};
  const result = tool.resolveTarget!(args);
  assert.deepEqual(result.fields, {sort: "priceLowToHigh"});
  assert.equal(tool.validate({brands: ["Invented brand"]}), false);
  assert.equal(tool.validate({maximumPrice: 2000}), false);
  assert.equal(tool.validate({pack: "bulk"}), false);
  assert.equal(tool.validate({sort: "deliveryFastest"}), false);
  assert.throws(() => tool.resolveTarget!({...args, apply: ["brands"], brands: ["Invented brand"]}));
  assert.throws(() => tool.resolveTarget!({...args, apply: ["sort", "sort"]}));
  const clear = tool.resolveTarget!({...args, apply: ["maximumPrice"], maximumPrice: null});
  assert.deepEqual(clear.fields, {maximumPrice: null});
  const proposal = {kind: "proposal" as const, id: "host-stored-filter", actionId: tool.actionId, entityId: null,
    sourceRevision: result.sourceRevision, title: tool.description, summary: "Host original filters", fields: result.fields};
  const recovered = await new CompositePreparationContext({catalogue: f.context}).readPrepared(actor, {...request, actionId: tool.actionId}, proposal);
  assert.equal(recovered.tools[0]!.sourceRevision, proposal.sourceRevision);
  assert.equal(recovered.tools[0]!.validate(proposal.fields), true);
  assert.equal(recovered.tools[0]!.validate({sort: "relevance"}), false);
});
function reviewedFamilyFixture() {
  const f = populatedFixture(2), sourceId = "store-reviewed-variants:evaluation:original-store";
  let mutate = (value: Record<string, unknown>) => value;
  const membership = (listingId: string, index: number) => ({listing: {schemaVersion: 1, realm: "evaluation",
    listingId, storeId: "original-store", skuId: listingId, channel: "retail",
    canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack"}, skuRevision: 1,
    familyId: "original-family", sourceId, revision: 2, attributes: [{dimensionId: "colour", dimensionLabel: "Colour",
      optionId: index ? "brown" : "white", optionLabel: index ? "Brown" : "White", kind: "colour", swatchArgb: null}]});
  f.family(body => mutate({schemaVersion: 1, state: "ready", realm: "evaluation", storeId: "original-store", orderingAvailable: false,
    sourceId, revision: 2, observedAt: at.toISOString(), validUntil: "2026-10-28T08:00:30.000Z",
    memberships: [membership(f.ids[0]!, 0)],
    family: body.familyId === undefined ? null : {familyId: "original-family", products: f.ids.map((listingId, index) => ({
      product: {skuId: listingId, revision: 1, canonicalProductId: "canonical-rice", verifiedPackId: "verified-pack",
        content: {title: "Original rice", variant: index ? "Brown" : "White", productFacts: {requiresPrescription: false}}, pack: {label: "5 kg"}},
      membership: membership(listingId, index)}))}}));
  return {...f, mutateFamily: (fn: typeof mutate) => {mutate = fn;}};
}
test("Reviewed variant family selects only an original same-channel member and preserves printed option labels", async () => {
  const f = reviewedFamilyFixture(), input = {...request, actionId: "AI-ACT-007", catalogueListingIds: [f.ids[0]!]};
  const c = await f.context.read(actor, input), tool = c.tools[0]!;
  const target = tool.resolveTarget!({listingId: f.ids[0], variantId: f.ids[1]});
  assert.equal(target.entityId, f.ids[0]); assert.deepEqual(target.fields, {variantId: f.ids[1]});
  assert.equal(c.validUntil, "2026-10-28T08:00:30.000Z");
  assert.equal(f.familyCalls.length, 2);
  assert.ok(JSON.stringify(c.modelContext).includes('"value":"Brown"'));
  assert.throws(() => tool.resolveTarget!({listingId: f.ids[0], variantId: originalListingId(99)}));
  assert.throws(() => tool.resolveTarget!({listingId: f.ids[1], variantId: f.ids[0]}));
  const recovered = await f.context.readPrepared(actor, {...request, actionId: "AI-ACT-007", entityId: f.ids[0]!}, {
    kind: "proposal", id: "original-stored-variant", actionId: "AI-ACT-007", entityId: f.ids[0]!,
    sourceRevision: target.sourceRevision, title: "Original variant", summary: "Host fixture only", fields: target.fields});
  assert.equal(recovered.tools[0]!.entityId, f.ids[0]);
  assert.equal(recovered.tools[0]!.sourceRevision, target.sourceRevision);
  assert.equal(recovered.tools[0]!.validate(target.fields), true);
  assert.equal(recovered.tools[0]!.validate({variantId: originalListingId(99)}), false);
});
test("Missing expired duplicate cross-Store or prescription family does not fabricate a variant or remove product review", async () => {
  for (const kind of ["missing", "expired", "duplicate", "foreign", "prescription"]) {
    const f = reviewedFamilyFixture();
    f.mutateFamily(data => {
      if (kind === "missing") return {...data, state: "unavailable"};
      if (kind === "expired") return {...data, validUntil: "2026-10-28T07:59:00.000Z"};
      if (!data.family) return data;
      const family = data.family as {products: Array<{product: {content: {productFacts: {requiresPrescription: boolean}}}; membership: {listing: {storeId: string}}}>};
      if (kind === "duplicate") family.products.push(structuredClone(family.products[0]!));
      if (kind === "foreign") family.products[1]!.membership.listing.storeId = "foreign-store";
      if (kind === "prescription") family.products[1]!.product.content.productFacts.requiresPrescription = true;
      return data;
    });
    const input = {...request, actionId: null, catalogueListingIds: [f.ids[0]!]};
    const c = await f.context.read(actor, input);
    assert.equal(c.tools.some(tool => tool.actionId === "AI-ACT-007"), false, kind);
    assert.equal(c.tools.some(tool => tool.actionId === "AI-ACT-006"), true, kind);
    await assert.rejects(f.context.read(actor, {...input, actionId: "AI-ACT-007"}), /context_unavailable/u);
  }
});
