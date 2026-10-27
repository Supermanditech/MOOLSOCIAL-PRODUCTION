import test from "node:test";
import assert from "node:assert/strict";
import {AccountPlansService, type PlansRepositorySnapshot} from "../account/plans_service.js";
import {AssistantPreparationService, type PreparationRequestStore, type PreparationState} from "./model_service.js";
import type {PreparationContext, PreparationRequest} from "./model_contract.js";
import type {ModelPreparation} from "./responses_transport.js";
import {InMemoryWorkspaceProfileRepository,WorkspaceProfileService,type WorkspaceProfileRecord} from "../workspace/workspace_profile_service.js";
const actor = {uid: "fixture-owner", projectId: "fixture-project"};
const request: PreparationRequest = {scope: {audience: "personal", storeId: null}, requestId: "fixture-request", requestRevision: 4,
  message: "ચોખા શોધો / chawal dhoondo", language: "Auto", expectedEntitlementRevision: "personal:null:1:1", history: [], actionId: null, entityId: null};
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
  let model = async (): Promise<ModelPreparation> => ({kind: "tool", name: "prepare_search", arguments: {query: "ચોખા"}});
  const deps = {plans, projectId: actor.projectId, now: () => now, requests: store,
    context: {async read() {contexts++; return context;}},
    usage: {async reserve() {reserved++; return {id: "fixture-permit", validUntil: context.validUntil};}, async settle(_id: string, state: string) {settlements.push(state);}},
    model: {async prepare() {calls++; return model();}}};
  return {service: new AssistantPreparationService(deps), deps, row, context, store, settlements,
    model: (fn: typeof model) => {model = fn;}, advance: (ms: number) => {now = new Date(now.getTime() + ms);}, counts: () => ({calls, contexts, reserved})};
}
test("AI-B01 actual paid service prepares a typed native proposal without domain execution", async () => {
  const f = fixture(); const result = await f.service.handle(actor, {operation: "prepare", payload: request});
  assert.equal(result.state, "ready"); if (result.state !== "ready") return;
  assert.equal(result.reply.outcome.kind, "proposal"); assert.deepEqual(result.reply.scope, request.scope);
  assert.equal(result.reply.entitlementRevision, "personal:null:1:1"); assert.deepEqual(f.settlements, ["completed"]);
  assert.equal(f.counts().calls, 1);
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
