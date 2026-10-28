import test from "node:test";
import assert from "node:assert/strict";
import {AccountPlansService, type PlansRepositorySnapshot} from "../account/plans_service.js";
import {AssistantPreparationService, type PreparationContextSource, type PreparationRequestStore, type PreparationState} from "./model_service.js";
import type {PreparationContext, PreparationRequest} from "./model_contract.js";
import type {ModelPreparation} from "./responses_transport.js";
import {ResponsesPreparationModel} from "./responses_transport.js";
import {InMemoryWorkspaceProfileRepository,WorkspaceProfileService,type WorkspaceProfileRecord} from "../workspace/workspace_profile_service.js";
import {storeNativeSelection} from './domain_context_contract.js';
const actor = {uid: "fixture-owner", projectId: "fixture-project"};
const request: PreparationRequest = {scope: {audience: "personal", storeId: null}, requestId: "fixture-request", requestRevision: 4,
  message: "ચોખા શોધો / chawal dhoondo", language: "Auto", expectedEntitlementRevision: "personal:null:1:1", history: [], actionId: null, entityId: null};
test('Original frozen native captures never enter the actual model transport body or tool arguments', async () => {
  let wire = '';
  const model = new ResponsesPreparationModel({model: 'host-model', key: async () => 'host-only-key', fetch: async (_url, init) => {
    wire = String(init?.body);
    return new Response(JSON.stringify({status: 'completed', output: [{type: 'function_call', status: 'completed',
      name: 'store_review_original_listing_request', arguments: '{}'}]}), {status: 200, headers: {'content-type': 'application/json'}});
  }});
  const capture = 'a'.repeat(64);
  const reply = await model.prepare({...request, scope: {audience: 'workspace', storeId: 'store-one'},
    actionId: 'AI-ACT-225', nativeOriginalCaptures: [{actionId: 'AI-ACT-225', digest: capture}]},
    [{name: 'store_review_original_listing_request', actionId: 'AI-ACT-225', entityId: null, sourceRevision: 'host-owner',
      description: 'Review the original native request', parameters: {type: 'object', properties: {}, required: [], additionalProperties: false},
      validate: fields => Object.keys(fields).length === 0}], new AbortController().signal, {audience: 'workspace'});
  assert.deepEqual(reply, {kind: 'tool', name: 'store_review_original_listing_request', arguments: {}});
  assert.ok(!wire.includes(capture)); assert.ok(!wire.includes('nativeOriginalCaptures'));
  const body = JSON.parse(wire); assert.deepEqual(body.tools[0].parameters.properties, {});
});
/** Host fixture only. Runtime has no in-memory fallback. */
class FixtureRequests implements PreparationRequestStore {
  rows = new Map<string, {fingerprint: string; lease: string; result: PreparationState}>();
  async claim(key: string, fingerprint: string) {
    const row = this.rows.get(key);
    if (row) return row.fingerprint === fingerprint ? row.result : {state: "conflict" as const};
    this.rows.set(key, {fingerprint, lease: key, result: {state: "pending"}}); return {state: "claimed" as const, lease: key};
  }
  async read(key: string) { return this.rows.get(key)?.result; }
  async finish(key: string, lease: string, result: PreparationState) {
    const row = this.rows.get(key); assert.ok(row); assert.equal(row.lease, lease);
    if (row.result.state !== "cancelled") row.result = result; return row.result;
  }
  async cancel(key: string) { const row = this.rows.get(key); if (!row) return undefined;
    if (row.result.state !== "ready") row.result = {state: "cancelled"}; return row.result; }
}
function fixture() {
  let now = new Date("2026-10-27T00:00:00.000Z"), calls = 0, contexts = 0, reserved = 0;
  const row: PlansRepositorySnapshot = {ownerUid: actor.uid, accountStatus: "ACTIVE",
    catalogue: {audience: "personal", revision: 1, state: "approved", offers: []}, subscription: {
      ownerUid: actor.uid, scope: request.scope, revision: 1, planId: "fixture-plan", planVersion: "v1", name: "Host fixture plan", state: "active",
      validFrom: "2026-10-26T00:00:00.000Z", validUntil: "2026-10-28T00:00:00.000Z", featureIds: ["mool_ai"]}};
  const plans = new AccountPlansService({async read(uid) {assert.equal(uid, actor.uid); return structuredClone(row);}}, {projectId: actor.projectId, now: () => now});
  const context: PreparationContext = {revision: "fixture-context-1", validUntil: "2026-10-27T00:01:00.000Z", tools: [{
    name: "prepare_search", actionId: "AI-ACT-001", entityId: null, sourceRevision: "fixture-native-1", description: "Find a product",
    parameters: {type: "object", properties: {query: {type: "string"}}, required: ["query"], additionalProperties: false},
    validate: f => Object.keys(f).length === 1 && typeof f.query === "string" && f.query.length >= 2 && f.query.length <= 80,
  }]};
  const store = new FixtureRequests(); const settlements: string[] = [];
  const contextSource: PreparationContextSource = {async read() {contexts++; return context;}};
  let model = async (): Promise<ModelPreparation> => ({kind: "tool", name: "prepare_search", arguments: {query: "ચોખા"}});
  const deps = {plans, projectId: actor.projectId, now: () => now, requests: store,
    context: contextSource,
    usage: {async reserve() {reserved++; return {id: "fixture-permit", validUntil: context.validUntil};}, async settle(_id: string, state: string) {settlements.push(state);}},
    model: {async prepare() {calls++; return model();}}};
  return {service: new AssistantPreparationService(deps), deps, row, context, store, settlements,
    model: (fn: typeof model) => {model = fn;}, advance: (ms: number) => {now = new Date(now.getTime() + ms);}, counts: () => ({calls, contexts, reserved})};
}
test('Private purchased-stars native selection restricts model order, line choices and reference context together',async()=>{
  const f=fixture(),first='host-purchased-order-a',second='host-purchased-order-b';
  Object.assign(f.context,{nativeTargets:[{actionId:'AI-ACT-055',entityId:first,sourceRevision:'host-stars-proof-a'},
    {actionId:'AI-ACT-055',entityId:second,sourceRevision:'host-stars-proof-b'}],
    modelContext:{sourceKind:'composite-original-context-v1',sources:[{sourceKind:'original-private-product-stars-v1',
      coverage:'indexed_recorded_completions',orders:[{orderId:first,items:[{lineId:'host-line-a',label:'Host purchased item A'}]},
        {orderId:second,items:[{lineId:'host-line-b',label:'Host private item B'}]}]}]},
    tools:[{name:'host_prepare_private_stars',actionId:'AI-ACT-055',entityId:null,sourceRevision:'host-stars-root',
      description:'Host original private-stars source fixture',targetSelector:'orderId',
      parameters:{type:'object',additionalProperties:false,required:['orderId','lineId','stars'],properties:{
        orderId:{type:'string',enum:[first,second]},lineId:{type:'string',enum:['host-line-a','host-line-b']},stars:{type:'integer',minimum:1,maximum:5}}},
      validate:(fields:Readonly<Record<string,unknown>>)=>Object.keys(fields).length===2&&fields.lineId==='host-line-a'&&fields.stars===4,
      resolveTarget:(args:Readonly<Record<string,unknown>>)=>{
        assert.equal(args.orderId,first);assert.equal(args.lineId,'host-line-a');
        return {entityId:first,sourceRevision:'host-stars-proof-a',fields:{lineId:args.lineId,stars:args.stars}};
      }}]});
  let modelCalls=0;
  const service=new AssistantPreparationService({...f.deps,model:{async prepare(_input,tools,_signal,reference){
    modelCalls++;assert.equal(tools.length,1);
    const properties=tools[0]!.parameters.properties as Record<string,{enum?:unknown[]}>;
    assert.deepEqual(properties.orderId!.enum,[first]);assert.deepEqual(properties.lineId!.enum,['host-line-a']);
    assert(JSON.stringify(reference).includes('Host purchased item A'));assert(!JSON.stringify(reference).includes('Host private item B'));
    assert(!JSON.stringify(tools[0]!.parameters).includes('host-line-b'));
    return {kind:'tool',name:'host_prepare_private_stars',arguments:{orderId:first,lineId:'host-line-a',stars:4}};
  }}});
  const value=await service.handle(actor,{operation:'prepare',payload:{...request,actionId:'AI-ACT-055',nativeTargets:[{actionId:'AI-ACT-055',entityId:first}]}});
  assert.equal(value.state,'ready');assert.equal(modelCalls,1);
  if(value.state==='ready'){assert.equal(value.reply.outcome.kind,'proposal');if(value.reply.outcome.kind==='proposal'){
    assert.equal(value.reply.outcome.entityId,first);assert.deepEqual(value.reply.outcome.fields,{lineId:'host-line-a',stars:4});
  }}
});
for (const available of [true, false]) test(`Receiving native selection filters order references and tools together available=${available}`, async () => {
  const f = fixture(), selected = 'HOST-receiving-a', excluded = 'HOST-receiving-b';
  Object.assign(f.context, {nativeTargets: [selected, excluded].map(entityId =>
    ({actionId: 'AI-ACT-243', entityId, sourceRevision: `HOST-proof-${entityId}`})),
    modelContext: {sourceKind: 'composite-original-context-v1', sources: [{sourceKind: 'original-store-receiving-v1',
      orders: [{orderId: selected, purchaseId: 'HOST-visible-purchase', supplierStoreId: 'HOST-visible-supplier'},
        {orderId: excluded, purchaseId: 'HOST-excluded-purchase', supplierStoreId: 'HOST-excluded-supplier'}]}]},
    tools: [{name: 'store_review_original_receiving', actionId: 'AI-ACT-243', entityId: null, sourceRevision: 'HOST-receiving-root',
      description: 'Host original receiving port', targetSelector: 'orderId',
      parameters: {type: 'object', additionalProperties: false, required: ['orderId'], properties: {orderId: {type: 'string', enum: [selected, excluded]}}},
      validate: (fields: Readonly<Record<string, unknown>>) => Object.keys(fields).length === 0,
      resolveTarget: (args: Readonly<Record<string, unknown>>) => {
        assert.deepEqual(args, {orderId: selected}); return {entityId: selected, sourceRevision: `HOST-proof-${selected}`, fields: {}};
      }}]});
  let modelCalls = 0;
  const service = new AssistantPreparationService({...f.deps, model: {async prepare(_input, tools, _signal, reference) {
    modelCalls++; assert.deepEqual((tools[0]!.parameters.properties as Record<string, {enum: string[]}>).orderId!.enum, [selected]);
    const text = JSON.stringify(reference); assert(text.includes('HOST-visible-purchase'));
    assert(!text.includes(excluded)); assert(!text.includes('HOST-excluded-purchase')); assert(!text.includes('HOST-excluded-supplier'));
    return {kind: 'tool', name: 'store_review_original_receiving', arguments: {orderId: selected}};
  }}});
  const payload = {...request, actionId: 'AI-ACT-243', nativeTargets: available ? [{actionId: 'AI-ACT-243', entityId: selected}] : []};
  if (available) {
    const result = await service.handle(actor, {operation: 'prepare', payload});
    assert.equal(result.state, 'ready'); assert.equal(modelCalls, 1);
    if (result.state === 'ready' && result.reply.outcome.kind === 'proposal') assert.deepEqual(result.reply.outcome.fields, {});
  } else {
    await assert.rejects(service.handle(actor, {operation: 'prepare', payload}), /context_unavailable/u);
    assert.equal(modelCalls, 0);
  }
});
for(const action of ['AI-ACT-275','AI-ACT-280','AI-ACT-281','AI-ACT-285'])for(const available of [true,false])test(`Operational ${action} model references contain only ready native originals available${available}`,async()=>{
  const f=fixture(),selected='HOST-operational-selected',excluded='HOST-operational-excluded';
  const fields=action==='AI-ACT-275'?{operation:'accept'}:{};
  Object.assign(f.context,{nativeTargets:[selected,excluded].map(entityId=>({actionId:action,entityId,sourceRevision:`HOST-proof-${entityId}`})),
    modelContext:{sourceKind:'composite-original-context-v1',sources:[{sourceKind:'original-store-operational-v1',
      orders:[{orderId:selected,stage:'Confirmed'},{orderId:excluded,stage:'Confirmed'}]}]},
    tools:[{name:'HOST_operational_review',actionId:action,entityId:null,sourceRevision:'HOST-operational-root',description:'Host original read port',
      targetSelector:'orderId',parameters:{type:'object',properties:{orderId:{type:'string',enum:[selected,excluded]}},required:['orderId'],additionalProperties:false},
      validate:(value:Readonly<Record<string,unknown>>)=>JSON.stringify(value)===JSON.stringify(fields),
      resolveTarget:(args:Readonly<Record<string,unknown>>)=>{assert.deepEqual(args,{orderId:selected});return {entityId:selected,sourceRevision:`HOST-proof-${selected}`,fields};}}]});
  let calls=0;
  const service=new AssistantPreparationService({...f.deps,model:{async prepare(_input,tools,_signal,reference){
    calls++;assert.deepEqual((tools[0]!.parameters.properties as Record<string,{enum:string[]}>).orderId!.enum,[selected]);
    assert(JSON.stringify(reference).includes(selected));assert(!JSON.stringify(reference).includes(excluded));
    return {kind:'tool',name:'HOST_operational_review',arguments:{orderId:selected}};
  }}});
  const payload={...request,actionId:action,nativeTargets:available?[{actionId:action,entityId:selected}]:[]};
  if(available){const result=await service.handle(actor,{operation:'prepare',payload});assert.equal(result.state,'ready');assert.equal(calls,1);}
  else{await assert.rejects(service.handle(actor,{operation:'prepare',payload}),/context_unavailable/u);assert.equal(calls,0);}
});

for(const mode of ['ready','zero-ready','stale-same-id','forged-excluded'])test(`Coupon model fields and references use exact native SKU witness ${mode}`,async()=>{
  const f=fixture(),scope={audience:'workspace' as const,storeId:'fixture-store'},a='HOST-sku-a',b='HOST-sku-b',couponA='HOST-coupon-a',couponB='HOST-coupon-b';
  const repository=new InMemoryWorkspaceProfileRepository();
  const profile:WorkspaceProfileRecord={schemaVersion:1,caseId:'HOST-coupon-case',ownerUserId:actor.uid,familyId:'products-trade',profileId:'retailer-grocery',
    name:'HOST coupon Store',area:'HOST area',primaryActivity:'HOST',proofReferences:{},alternateMobileVerified:false,idempotencyKey:'HOST-coupon-key',
    requestFingerprint:'HOST-coupon-fingerprint',status:'approved',plan:'free',createdAt:'2026-10-26T00:00:00.000Z',updatedAt:'2026-10-26T00:00:00.000Z',workspaceId:scope.storeId};
  await repository.createOrRead(profile);
  const workspaces=new WorkspaceProfileService(repository,f.deps.now,undefined,{async readAccount(accountId){return [{schemaVersion:1,
    membershipId:'HOST-coupon-member',accountId,workspaceId:scope.storeId,workspaceProfileId:profile.profileId,state:'active',version:1,grantedAt:'2026-10-26T00:00:00.000Z'}];}});
  const plans=new AccountPlansService({async read(){return {ownerUid:actor.uid,accountStatus:'ACTIVE',subscription:{...(f.row.subscription as object),scope},
    catalogue:{audience:'workspace',state:'approved',revision:1,offers:[]}};}},{projectId:actor.projectId,now:f.deps.now,readWorkspaces:who=>workspaces.listWorkspaces(who.uid)});
  const properties={name:{type:'string'},kind:{type:'string',enum:['billDiscount','productDiscount','quantityPrice','extraQuantity']},
    skuIds:{type:'array',items:{type:'string',enum:[a,b]}},rewardSkuId:{type:'string',enum:[a,b]},tiers:{type:'array',items:{type:'integer'}}};
  Object.assign(f.context,{nativeTargets:[{actionId:'AI-ACT-309',entityId:null,sourceRevision:'HOST-new-coupon'},
    ...[couponA,couponB].flatMap(entityId=>['AI-ACT-309','AI-ACT-310'].map(actionId=>({actionId,entityId,sourceRevision:'HOST-'+entityId}))),
    ...[a,b].map(entityId=>({actionId:'AI-ACT-214',entityId,sourceRevision:'HOST-proof-'+entityId}))],
    modelContext:{sourceKind:'original-store-coupons-v1',products:[{skuId:a,title:'HOST A',sourceRevision:mode==='stale-same-id'?'HOST-stale-product':'HOST-proof-'+a},
      {skuId:b,title:'HOST B',sourceRevision:'HOST-proof-'+b}],coupons:[{couponId:couponA,name:'HOST selected coupon'},{couponId:couponB,name:'HOST private excluded coupon'}]},
    tools:[{name:'HOST_coupon_draft',actionId:'AI-ACT-309',entityId:null,sourceRevision:'HOST-coupon-index',description:'HOST original private draft selector',targetSelector:'couponId',
        parameters:{type:'object',properties:{...properties,couponId:{type:['string','null'],enum:[null,couponA,couponB]}},required:['couponId',...Object.keys(properties)],additionalProperties:false},
        validate:()=>true,resolveTarget:(args:Readonly<Record<string,unknown>>)=>{const {couponId,...fields}=args;return {entityId:couponId as string|null,sourceRevision:couponId===null?'HOST-new-coupon':'HOST-'+couponId,fields};}}]});
  const selection=storeNativeSelection(actor,scope,f.context),bits=Buffer.alloc(Math.ceil(selection.targets.length/8));
  selection.targets.forEach((target,i)=>{if(target.actionId==='AI-ACT-309'&&(target.entityId===null||target.entityId===couponA)||
    target.actionId==='AI-ACT-214'&&target.entityId===a&&mode!=='zero-ready')bits[i>>3]!|=1<<(i%8);});
  let calls=0;
  const service=new AssistantPreparationService({...f.deps,plans,model:{async prepare(_input,tools,_signal,reference){
    calls++;const root=tools.find(t=>t.name==='HOST_coupon_draft')!,edit=root;
    const ready=mode==='ready'||mode==='forged-excluded',p=root.parameters.properties as Record<string,any>;
    assert.deepEqual((reference!.products as {skuId:string}[]).map(row=>row.skuId),ready?[a]:[]);
    assert.deepEqual((reference!.coupons as {couponId:string}[]).map(row=>row.couponId),[couponA]);
    assert(!JSON.stringify(reference).includes('sourceRevision'));assert(!JSON.stringify(reference).includes('HOST private excluded coupon'));
    assert.deepEqual((edit.parameters.properties as Record<string,any>).couponId.enum,[null,couponA]);
    if(ready){assert.deepEqual(p.skuIds.items.enum,[a]);assert.deepEqual(p.rewardSkuId.enum,[a]);}
    else{assert.equal(p.skuIds,undefined);assert.equal(p.rewardSkuId,undefined);assert.equal(p.tiers,undefined);
      assert.deepEqual(p.kind.enum,['billDiscount']);assert.equal(root.validate({kind:'quantityPrice'}),false);}
    assert.equal(root.validate({skuIds:[b]}),false);assert.equal(root.validate({rewardSkuId:b}),false);
    assert.throws(()=>edit.resolveTarget!({couponId:couponA,skuIds:[b]}),/invalid_model_result/u);
    return {kind:'tool',name:'HOST_coupon_draft',arguments:{couponId:null,name:'HOST user supplied coupon',...(mode==='forged-excluded'?{skuIds:[b]}:ready?{skuIds:[a]}:{})}};
  }}});
  const payload={...request,scope,expectedEntitlementRevision:'workspace:fixture-store:1:1',actionId:'AI-ACT-309',
    nativeTargetMask:{version:1 as const,fingerprint:selection.fingerprint,bits:bits.toString('base64url')}};
  if(mode==='forged-excluded')await assert.rejects(service.handle(actor,{operation:'prepare',payload}),/invalid_model_result/u);
  else assert.equal((await service.handle(actor,{operation:'prepare',payload})).state,'ready');
  assert.equal(calls,1);
});

test("AI-B01 actual paid service prepares a typed native proposal without domain execution", async () => {
  const f = fixture(); const result = await f.service.handle(actor, {operation: "prepare", payload: request});
  assert.equal(result.state, "ready"); if (result.state !== "ready") return;
  assert.equal(result.reply.outcome.kind, "proposal"); assert.deepEqual(result.reply.scope, request.scope);
  assert.equal(result.reply.entitlementRevision, "personal:null:1:1"); assert.deepEqual(f.settlements, ["completed"]);
  assert.equal(f.counts().calls, 1);
});
test("Stored proposal status uses original readback without re-preparing, charging or replaying an effect", async () => {
  const f = fixture(); let reads = 0, missing = false;
  f.deps.context.readPrepared = async (who, input, proposal) => {
    reads++; assert.deepEqual(who, actor); assert.equal(input.actionId, proposal.actionId);
    assert.equal(input.entityId, proposal.entityId); assert.deepEqual(proposal.fields, {query: "ચોખા"});
    assert.equal(input.catalogueListingIds, undefined);
    if (missing) throw Error("Original source unavailable");
    return f.context;
  };
  const result = await f.service.handle(actor, {operation: "prepare", payload: request});
  assert.equal(result.state, "ready"); const before = f.counts(), originalReads = reads;
  assert.deepEqual(await f.service.handle(actor, {operation: "status", payload: {scope: request.scope, requestId: request.requestId}}), result);
  assert.ok(reads > originalReads); assert.equal(f.counts().calls, before.calls); assert.equal(f.counts().reserved, before.reserved);
  missing = true;
  await assert.rejects(f.service.handle(actor, {operation: "status", payload: {scope: request.scope, requestId: request.requestId}}));
  assert.equal(f.counts().calls, before.calls); assert.equal(f.counts().reserved, before.reserved);
});

test("THIN-B03 registered field normalisation returns original native fields only", async () => {
  const f = fixture();
  Object.assign(f.context.tools[0]!, {decodeFields: (fields: Readonly<Record<string, unknown>>) => ({query: (fields.query as string).trim()})});
  f.model(async () => ({kind: "tool", name: "prepare_search", arguments: {query: "  चावल  "}}));
  const result = await f.service.handle(actor, {operation: "prepare", payload: request});
  assert.equal(result.state, "ready"); if (result.state !== "ready" || result.reply.outcome.kind !== "proposal") return;
  assert.deepEqual(result.reply.outcome.fields, {query: "चावल"});
});
test("THIN-B03 changed source reference data retires a result even when a source reuses its revision", async () => {
  const f = fixture(); Object.assign(f.context, {modelContext: {displayName: "Original"}});
  f.model(async () => {
    Object.assign(f.context, {modelContext: {displayName: "Changed"}});
    return {kind: "tool", name: "prepare_search", arguments: {query: "चावल"}};
  });
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}), {code: "stale_preparation"});
  assert.equal(f.counts().calls, 1); assert.deepEqual(f.settlements, ["uncertain"]);
});
for (const state of ["pending", "expired", "revoked"]) test(`AI-B01 ${state} makes zero model/context/usage calls`, async () => {
  const f = fixture(); Object.assign(f.row.subscription as object, {state});
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}), {code: "ai_access_required"});
  assert.deepEqual(f.counts(), {calls: 0, contexts: 0, reserved: 0});
});
test("AI-B01 wrong actor/project/tenant cannot prepare", async () => {
  const f = fixture(); for (const who of [{...actor, projectId: "foreign"}, {...actor, tenantId: "foreign"}])
    await assert.rejects(f.service.handle(who, {operation: "prepare", payload: request}));
  assert.equal(f.counts().calls, 0);
});
test("AI-B01 missing real context/usage/request/model services remain unavailable", async () => {
  const f = fixture(); const service = new AssistantPreparationService({plans: f.deps.plans, projectId: actor.projectId, now: f.deps.now});
  await assert.rejects(service.handle(actor, {operation: "prepare", payload: request}), {code: "assistant_unavailable"});
  assert.equal(f.counts().calls, 0);
});
test("AI-B01 personal paid access cannot authorize an unverified Store scope", async () => {
  const f=fixture();
  await assert.rejects(f.service.handle(actor,{operation:"prepare",payload:{...request,scope:{audience:"workspace",storeId:"foreign-store"}}}),{code:"workspace_access_unavailable"});
  assert.deepEqual(f.counts(),{calls:0,contexts:0,reserved:0});
});
test("AI-B01 approved Store uses actual B03 readback and loses AI, not free approval, on expiry", async () => {
  const f=fixture(),scope={audience:"workspace" as const,storeId:"fixture-store"};
  const repository=new InMemoryWorkspaceProfileRepository();
  const profile:WorkspaceProfileRecord={schemaVersion:1,caseId:"fixture-case",ownerUserId:actor.uid,familyId:"products-trade",profileId:"retailer-grocery",
    name:"Host fixture Store",area:"Host fixture area",primaryActivity:"Fixture",proofReferences:{},alternateMobileVerified:false,
    idempotencyKey:"fixture-key",requestFingerprint:"fixture-hash",status:"approved",plan:"free",createdAt:"2026-10-26T00:00:00.000Z",updatedAt:"2026-10-26T00:00:00.000Z",workspaceId:scope.storeId};
  await repository.createOrRead(profile);
  const workspaces=new WorkspaceProfileService(repository,f.deps.now,undefined,{async readAccount(accountId){return [{schemaVersion:1,
    membershipId:"fixture-member",accountId,workspaceId:scope.storeId,workspaceProfileId:profile.profileId,state:"active",version:1,grantedAt:"2026-10-26T00:00:00.000Z"}];}});
  const subscription={...(f.row.subscription as object),scope};
  const plans=new AccountPlansService({async read(){return {ownerUid:actor.uid,accountStatus:"ACTIVE",subscription,
    catalogue:{audience:"workspace",state:"approved",revision:1,offers:[]}};}},{projectId:actor.projectId,now:f.deps.now,readWorkspaces:a=>workspaces.listWorkspaces(a.uid)});
  f.model(async()=>({kind:"clarification",text:"कौन सा उत्पाद?"}));
  const service=new AssistantPreparationService({...f.deps,plans,context:{async read(){return {...f.context,tools:[{
    name:"prepare_product",actionId:"AI-ACT-213",entityId:null,sourceRevision:"fixture-store-draft-1",description:"Add a product",
    parameters:{type:"object",properties:{name:{type:"string"}},required:["name"],additionalProperties:false},validate:()=>true,
  }]};}}});
  const result=await service.handle(actor,{operation:"prepare",payload:{...request,scope,expectedEntitlementRevision:"workspace:fixture-store:1:1"}});
  assert.equal(result.state,"ready");if(result.state==="ready")assert.equal(result.reply.entitlementRevision,"workspace:fixture-store:1:1");
  Object.assign(subscription,{state:"expired",revision:2});
  await assert.rejects(service.handle(actor,{operation:"prepare",payload:{...request,scope,expectedEntitlementRevision:"workspace:fixture-store:1:1",requestId:"another-request"}}),{code:"ai_access_required"});
  const current=(await workspaces.listWorkspaces(actor.uid)).workspaces[0] as {status:string;plan:string;access:{state:string}};
  assert.equal(current.status,"approved");assert.equal(current.plan,"free");assert.equal(current.access.state,"active");
});
test("AI-B01 registered context permission denial makes zero model/usage calls", async () => {
  const f=fixture();f.deps.context.read=async()=>{throw new Error("original capability is not permitted");};
  await assert.rejects(f.service.handle(actor,{operation:"prepare",payload:request}));
  assert.equal(f.counts().calls,0);assert.equal(f.counts().reserved,0);
});
test("AI-B01 an unknown selected action cannot call another capability", async () => {
  const f=fixture();await assert.rejects(f.service.handle(actor,{operation:"prepare",payload:{...request,actionId:"unregistered_action"}}),{code:"context_unavailable"});
  assert.equal(f.counts().calls,0);
});
test("AI-B01 stale client entitlement revision makes zero model calls", async () => {
  const f=fixture();
  await assert.rejects(f.service.handle(actor,{operation:"prepare",payload:{...request,expectedEntitlementRevision:"personal:null:0:0"}}),{code:"stale_entitlement"});
  assert.equal(f.counts().calls,0);
});
test("AI-B01 duplicates return original and changed body conflicts without another model call", async () => {
  const f = fixture(); const first = await f.service.handle(actor, {operation: "prepare", payload: request});
  assert.deepEqual(await f.service.handle(actor, {operation: "prepare", payload: request}), first);
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: {...request, message: "changed"}}), {code: "request_identity_conflict"});
  assert.equal(f.counts().calls, 1);
});
test("AI-B01 replay/status rechecks source and expiry", async () => {
  const f = fixture(); await f.service.handle(actor, {operation: "prepare", payload: request});
  Object.assign(f.context.tools[0]!, {sourceRevision: "changed"});
  await assert.rejects(f.service.handle(actor, {operation: "status", payload: {scope: request.scope, requestId: request.requestId}}), {code: "stale_preparation"});
  f.advance(61_000); await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}), {code: "stale_preparation"});
  assert.equal(f.counts().calls, 1);
});
for (const invalid of [{kind: "tool", name: "publish_everything", arguments: {}}, {kind: "tool", name: "prepare_search", arguments: {query: "rice", ownerUid: "other"}}] as const) {
  test(`AI-B01 unregistered/invalid suggestion ${invalid.name} cannot become proposal`, async () => {
    const f = fixture(); f.model(async () => invalid);
    await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}), {code: "invalid_model_result"});
    assert.deepEqual(f.settlements, ["uncertain"]);
  });
}
test("AI-B01 concurrent cancellation and authority revocation retire late work", async () => {
  const f = fixture(); let release!: (v: ModelPreparation) => void; let started!: () => void;
  const ready = new Promise<void>(r => {started = r;}); f.model(() => {started(); return new Promise(r => {release = r;});});
  const pending = f.service.handle(actor, {operation: "prepare", payload: request}); await ready;
  assert.deepEqual(await f.service.handle(actor, {operation: "prepare", payload: request}), {state: "pending"});
  assert.deepEqual(await f.service.handle(actor, {operation: "cancel", payload: {scope: request.scope, requestId: request.requestId}}), {state: "cancelled"});
  release({kind: "clarification", text: "Which pack?"}); assert.deepEqual(await pending, {state: "cancelled"});
  assert.equal(f.counts().calls, 1);
});
test("AI-B01 changed entitlement during asynchronous model work rejects its result", async () => {
  const f = fixture(); f.model(async () => {Object.assign(f.row.subscription as object, {state: "revoked", revision: 2}); return {kind: "clarification", text: "Which pack?"};});
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}), {code: "ai_access_required"});
});
test("AI-B01 owner may cancel after subscription expiry without reading retained proposal data", async () => {
  const f = fixture(); let release!: (v: ModelPreparation) => void; let started!: () => void;
  const ready = new Promise<void>(r => {started = r;}); f.model(() => {started(); return new Promise(r => {release = r;});});
  const pending = f.service.handle(actor, {operation: "prepare", payload: request}); await ready;
  Object.assign(f.row.subscription as object, {state: "expired"});
  assert.deepEqual(await f.service.handle(actor, {operation: "cancel", payload: {scope: request.scope, requestId: request.requestId}}), {state: "cancelled"});
  release({kind: "clarification", text: "Which pack?"}); assert.deepEqual(await pending, {state: "cancelled"});
  assert.equal(f.counts().calls, 1);
});
test("AI-B01 provider timeout is recorded failed and never blindly reissued", async () => {
  const f = fixture(); f.model(async () => {throw new Error("host-only timeout details");});
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}));
  assert.deepEqual(await f.service.handle(actor, {operation: "prepare", payload: request}), {state: "failed"}); assert.equal(f.counts().calls, 1);
});
test("AI-B01 revocation while usage authority awaits makes zero model calls", async () => {
  const f = fixture();
  f.deps.usage.reserve = async () => {
    Object.assign(f.row.subscription as object, {state: "revoked", revision: 2});
    return {id: "fixture-permit", validUntil: f.context.validUntil};
  };
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}));
  assert.equal(f.counts().calls, 0);
});
test("AI-B01 source change while usage authority awaits makes zero model calls", async () => {
  const f = fixture();
  f.deps.usage.reserve = async () => {
    Object.assign(f.context.tools[0]!, {sourceRevision: "changed-before-model"});
    return {id: "fixture-permit", validUntil: f.context.validUntil};
  };
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}));
  assert.equal(f.counts().calls, 0);
});

function selectedCatalogueFixture() {
  const f = fixture(), listingId = "listing-" + "a".repeat(64), generic = f.context.tools[0]!;
  Object.assign(generic, {actionId: "AI-ACT-006", sourceRevision: "catalogue:1", targetSelector: "listingId",
    parameters: {type: "object", properties: {listingId: {type: "string", enum: [listingId]}},
      required: ["listingId"], additionalProperties: false},
    validate: (fields: Readonly<Record<string, unknown>>) => Object.keys(fields).length === 0,
    resolveTarget: (fields: Readonly<Record<string, unknown>>) => {
      assert.deepEqual(fields, {listingId});
      return {entityId: listingId, sourceRevision: "record:1", fields: {}, title: "Original public product"};
    }});
  Object.assign(f.context, {nativeTargets: [{actionId: "AI-ACT-006", entityId: listingId, sourceRevision: "record:1"}]});
  f.deps.context.read = async (...args: unknown[]) => {
    const selected = args[1] as PreparationRequest | undefined;
    if (selected?.entityId !== null && selected?.entityId !== undefined) {
      const {resolveTarget: _selector, targetSelector: _property, ...tool} = generic;
      return {...f.context, tools: [{...tool, entityId: listingId, sourceRevision: "record:1",
        parameters: {type: "object", properties: {}, required: [], additionalProperties: false}}]};
    }
    return f.context;
  };
  f.model(async () => ({kind: "tool", name: generic.name, arguments: {listingId}}));
  return {...f, listingId, generic};
}
test("Domain typed selector resolves only an original witnessed entity and strips selector before native fields", async () => {
  const f = selectedCatalogueFixture(), result = await f.service.handle(actor, {operation: "prepare", payload: request});
  assert.equal(result.state, "ready"); if (result.state !== "ready" || result.reply.outcome.kind !== "proposal") return;
  assert.equal(result.reply.outcome.actionId, "AI-ACT-006"); assert.equal(result.reply.outcome.entityId, f.listingId);
  assert.equal(result.reply.outcome.sourceRevision, "record:1"); assert.deepEqual(result.reply.outcome.fields, {});
  assert.equal(result.reply.outcome.title, "Original public product");
  assert.deepEqual(await f.service.handle(actor, {operation: "status", payload: {scope: request.scope, requestId: request.requestId}}), result);
  assert.equal(f.counts().calls, 1);
});
test("Native hints cannot grant an absent backend action or target and spend no model usage", async () => {
  for (const hints of [[], [{actionId: "AI-ACT-999", entityId: null}],
    [{actionId: "AI-ACT-006", entityId: "listing-" + "b".repeat(64)}]]) {
    const f = selectedCatalogueFixture();
    await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: {...request, nativeTargets: hints}}), /context_unavailable/u);
    assert.equal(f.counts().calls, 0); assert.equal(f.counts().reserved, 0);
  }
});
test("Model selector is narrowed to original targets with native review anchors; forged model target still fails", async () => {
  for (const forged of [false, true]) {
    const f = selectedCatalogueFixture(), other = "listing-" + "b".repeat(64);
    Object.assign(f.generic, {parameters: {...f.generic.parameters, properties: {listingId: {type: "string", enum: [f.listingId, other]}}},
      resolveTarget: (fields: Readonly<Record<string, unknown>>) => ({entityId: fields.listingId, sourceRevision: "record:1", fields: {}})});
    Object.assign(f.context, {nativeTargets: [f.context.nativeTargets![0], {actionId: "AI-ACT-006", entityId: other, sourceRevision: "record:1"}]});
    let calls = 0;
    f.deps.model.prepare = async (...args: unknown[]) => {
      calls++;
      const tools = args[1] as Array<{name: string; parameters: {properties: {listingId: {enum: string[]}}}}>; 
      assert.deepEqual(tools[0]!.parameters.properties.listingId.enum, [f.listingId]);
      return {kind: "tool" as const, name: tools[0]!.name, arguments: {listingId: forged ? other : f.listingId}};
    };
    const result = f.service.handle(actor, {operation: "prepare", payload: {...request,
      nativeTargets: [{actionId: "AI-ACT-006", entityId: f.listingId}]}});
    if (forged) await assert.rejects(result, /invalid_model_result/u);
    else assert.equal((await result).state, "ready");
    assert.equal(calls, 1); assert.equal(f.counts().reserved, 1);
  }
});
test("Domain selector cannot invent a target outside the original captured witness", async () => {
  const f = selectedCatalogueFixture();
  Object.assign(f.generic, {resolveTarget: () => ({entityId: "listing-" + "b".repeat(64), sourceRevision: "record:1", fields: {}})});
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}), /invalid_model_result/u);
  assert.ok([...f.store.rows.values()].every(row => row.result.state === "failed"));
});
test("Domain target witness changes during inference retire preparation even when tool schema is unchanged", async () => {
  const f = selectedCatalogueFixture();
  f.model(async () => {
    Object.assign(f.context, {nativeTargets: [{actionId: "AI-ACT-006", entityId: f.listingId, sourceRevision: "record:2"}]});
    return {kind: "tool", name: f.generic.name, arguments: {listingId: f.listingId}};
  });
  await assert.rejects(f.service.handle(actor, {operation: "prepare", payload: request}), /stale_preparation/u);
});
