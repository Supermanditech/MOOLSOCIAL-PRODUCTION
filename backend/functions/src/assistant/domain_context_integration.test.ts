import test from "node:test";
import assert from "node:assert/strict";
import {AccountPlansService} from "../account/plans_service.js";
import {AccountProfileService} from "../account/profile_service.js";
import {ProfileWorkspacePreparationContext} from "./profile_context.js";
import {WorkspaceCatalogueService, type WorkspaceCatalogueRepository} from "../workspace/workspace_catalogue_service.js";
import {CompositePreparationContext, OriginalCataloguePreparationContext} from "./domain_context.js";
import {handleAssistantCanonicalContextRequest} from "./domain_context_http.js";
import {AssistantPreparationService, type PreparationRequestStore, type PreparationState} from "./model_service.js";
const actor = {uid: "host-domain-owner", projectId: "host-domain-project"};
const at = new Date("2026-10-28T08:00:00.000Z");
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
