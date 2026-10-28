import {randomUUID} from "node:crypto";
import type {AccountProfileActor} from "../account/profile_service.js";
import type {AccountPlansService, PlansScope} from "../account/plans_service.js";
import {assertStrictSchema, canonical, digest, fail, id, text, object, nativeTargetSelection, nativeOriginalRequestActions, clarificationToolName, type AssistantCommand, type PreparationContext, type PreparationReply, type PreparationRequest} from "./model_contract.js";
import {maskedNativeHints, storeProductActions} from "./domain_context_contract.js";
import type {PreparationModel} from "./responses_transport.js";

export type PreparationState = {state: "pending" | "uncertain" | "cancelled" | "failed"} | {state: "ready"; reply: PreparationReply};
export interface PreparationRequestIdentity {
  readonly ownerUid: string; readonly projectId: string; readonly scope: PlansScope; readonly requestId: string;
}
export interface PreparationRequestStore {
  /** Must be atomic, owner-keyed and durable before production enablement. No in-memory runtime fallback. */
  claim(key: string, fingerprint: string, identity?: PreparationRequestIdentity): Promise<{state: "claimed"; lease: string} | {state: "conflict"} | PreparationState>;
  /** Undefined means authoritative absence; an unavailable store must throw. */
  read(key: string, identity?: PreparationRequestIdentity): Promise<PreparationState | undefined>;
  /** Atomic lease/cancellation check; a late completion cannot overwrite cancel. */
  finish(key: string, lease: string, result: PreparationState, identity?: PreparationRequestIdentity): Promise<PreparationState>;
  cancel(key: string, identity?: PreparationRequestIdentity): Promise<PreparationState | undefined>;
  /** Durable single-dispatch barrier; absent only in isolated legacy host fixtures. */
  markDispatched?(key: string, lease: string, identity?: PreparationRequestIdentity): Promise<void>;
}
export interface PreparationUsageAuthority {
  reserve(actor: AccountProfileActor, request: PreparationRequest): Promise<{id: string; validUntil: string}>;
  /** Idempotent by reservation ID. Uncertain is not confirmed token usage/charge. */
  settle(id: string, outcome: "completed" | "uncertain"): Promise<void>;
}
export interface PreparationContextSource {
  /** Original permission/source authority only; client hints never grant access. */
  read(actor: AccountProfileActor, request: PreparationRequest): Promise<PreparationContext>;
  /** Read back an already stored proposal against its original source. Never a client command or effect. */
  readPrepared?(actor: AccountProfileActor, request: PreparationRequest,
    proposal: Extract<PreparationReply['outcome'], {kind: "proposal"}>): Promise<PreparationContext>;
}
function expiry(stamp: string): number {
  const value = Date.parse(stamp);
  if (!Number.isFinite(value) || new Date(value).toISOString() !== stamp) return fail();
  return value;
}
function contextBinding(c: PreparationContext): string {
  return canonical({revision: c.revision, tools: c.tools.map(t => ({name: t.name, actionId: t.actionId, entityId: t.entityId,
    sourceRevision: t.sourceRevision, description: t.description, parameters: t.parameters,
    ...(t.targetSelector === undefined ? {} : {targetSelector: t.targetSelector})})), modelContext: c.modelContext ?? null,
    ...(c.nativeTargets === undefined ? {} : {nativeTargets: c.nativeTargets})});
}
function selectedNativeModelReference(context: PreparationContext, tools: PreparationContext['tools'],
  targets: readonly {actionId: string; entityId: string | null}[]): PreparationContext['modelContext'] {
  const skus = new Set<string>();
  const orders = new Set(targets.filter(target=>target.actionId==='AI-ACT-274'&&target.entityId!==null).map(target=>target.entityId!));
  for(const tool of tools){
    if(!storeProductActions.has(tool.actionId))continue;
    const selected=new Set(targets.filter(target=>target.actionId===tool.actionId&&target.entityId!==null).map(target=>target.entityId!));
    if(tool.entityId!==null){if(selected.has(tool.entityId))skus.add(tool.entityId);continue;}
    // Native root reviews select their saved product later. Legacy proof rows
    // may still be captured for recovery, but are not model reference inputs.
    if(tool.targetSelector===undefined)continue;
    const selector=object(object(tool.parameters.properties)[tool.targetSelector]);
    if(!Array.isArray(selector.enum)||selector.enum.some(value=>typeof value!=='string'))return fail('context_unavailable');
    for(const value of selector.enum)if(selected.has(value as string))skus.add(value as string);
  }
  function project(value: PreparationContext['modelContext']): PreparationContext['modelContext'] {
    if (value === undefined) return value;
    if(value.sourceKind==='original-store-order-facts-v1'){
      if(!Array.isArray(value.orders))return fail('context_unavailable');
      return {...value,orders:value.orders.filter(row=>{
        const orderId=object(row).orderId;if(typeof orderId!=='string')return fail('context_unavailable');
        return orders.has(orderId);
      })};
    }
    if (value.sourceKind === 'original-store-owned-skus-v1') {
      if (!Array.isArray(value.products)) return fail('context_unavailable');
      return {...value, products: value.products.filter(row => {
        const sku = object(row).skuId; if (typeof sku !== 'string') return fail('context_unavailable');
        return skus.has(sku);
      })};
    }
    if (value.sourceKind === 'composite-original-context-v1') {
      if (!Array.isArray(value.sources)) return fail('context_unavailable');
      return {...value, sources: value.sources.map(source => source === null ? null : project(object(source)))};
    }
    return value;
  }
  return project(context.modelContext);
}
/** Intersect native readiness hints with original registered source targets.
 * No caller-authored tool, field, permission or source revision is admitted. */
function nativeContext(actor: AccountProfileActor, context: PreparationContext, request: PreparationRequest,
  maskContext: PreparationContext = context): PreparationContext {
  const originals = new Set((request.nativeOriginalCaptures ?? []).map(value => value.actionId));
  context = {...context, tools: context.tools.filter(tool => !nativeOriginalRequestActions.has(tool.actionId) || originals.has(tool.actionId))};
  if (request.nativeTargets === undefined && request.nativeTargetMask === undefined) return {...context,
    ...(context.modelContext === undefined ? {} : {modelContext: selectedNativeModelReference(context, context.tools, context.nativeTargets ?? context.tools)!})};
  if (request.nativeTargetMask !== undefined && maskContext !== context) {
    const proofs = new Map((maskContext.nativeTargets ?? maskContext.tools).map(target => [canonical([target.actionId, target.entityId]), target.sourceRevision]));
    if ((context.nativeTargets ?? context.tools).some(target => proofs.get(canonical([target.actionId, target.entityId])) !== target.sourceRevision)) {
      return fail("stale_preparation", 409);
    }
  }
  const selected = [...nativeTargetSelection(request.nativeTargets ?? []), ...maskedNativeHints(actor, maskContext, request)]
    .filter(target => request.nativeTargetMask === undefined ||
      (request.actionId === null || target.actionId === request.actionId) && (request.entityId === null || target.entityId === request.entityId));
  const hints = new Set(selected.map(value => canonical([value.actionId, value.entityId])));
  const targets = context.nativeTargets ?? context.tools.map(({actionId, entityId, sourceRevision}) => ({actionId, entityId, sourceRevision}));
  const nativeTargets = targets.filter(target => hints.has(canonical([target.actionId, target.entityId])));
  const tools = context.tools.flatMap(tool => {
    if (tool.targetSelector === undefined) return hints.has(canonical([tool.actionId, tool.entityId])) ? [tool] : [];
    const properties = object(tool.parameters.properties), selector = object(properties[tool.targetSelector]);
    if (!tool.resolveTarget || !Array.isArray(selector.enum) || selector.enum.some(value => typeof value !== "string")) return fail("context_unavailable");
    const permitted = new Set(nativeTargets.filter(target => target.actionId === tool.actionId && target.entityId !== null).map(target => target.entityId));
    const values = selector.enum.filter(value => permitted.has(value as string));
    if (!values.length) return [];
    return [{...tool, parameters: {...tool.parameters, properties: {...properties,
      [tool.targetSelector]: {...selector, enum: values}}}}];
  });
  return {...context, tools, nativeTargets,
    ...(context.modelContext === undefined ? {} : {modelContext: selectedNativeModelReference(context, tools, nativeTargets)!})};
}
export class AssistantPreparationService {
  private readonly cancellations = new Map<string, AbortController>();
  constructor(private readonly deps: {plans: AccountPlansService; projectId: string;
    context?: PreparationContextSource; requests?: PreparationRequestStore; usage?: PreparationUsageAuthority;
    model?: PreparationModel; now?: () => Date}) {}
  private now(): number { return (this.deps.now?.() ?? new Date()).getTime(); }
  private async paid(actor: AccountProfileActor, scope: PlansScope) {
    if (!actor.uid || actor.projectId !== this.deps.projectId || actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
    const value = await this.deps.plans.read(actor, scope);
    if (!value.activeFeatureIds.includes("mool_ai") || expiry(value.validUntil) <= this.now()) return fail("ai_access_required", 403);
    return {revision: `${scope.audience}:${scope.storeId}:${value.catalogueRevision}:${value.subscriptionRevision}`, until: expiry(value.validUntil)};
  }
  private async readContext(actor: AccountProfileActor, input: PreparationRequest) {
    if (!this.deps.context) return fail("context_unavailable");
    // The compact hint positions bind the same full original scope used by the
    // metadata read. Apply selected action/entity only after validating it.
    if (input.nativeTargetMask === undefined) return nativeContext(actor, await this.deps.context.read(actor, input), input);
    const captured = await this.deps.context.read(actor, {...input, actionId: null, entityId: null});
    const context = input.entityId === null ? captured : await this.deps.context.read(actor, input);
    return nativeContext(actor, context, input, captured);
  }
  private async validateReady(actor: AccountProfileActor, state: PreparationState, revision: string): Promise<PreparationState> {
    if (state.state !== "ready") return state;
    const r = state.reply;
    if (r.entitlementRevision !== revision || expiry(r.validUntil) <= this.now()) return fail("stale_preparation", 409);
    if (r.outcome.kind === "proposal") {
      if (!this.deps.context) return fail("context_unavailable");
      const p = r.outcome;
      const selection: PreparationRequest = {scope: r.scope, requestId: r.requestId, requestRevision: r.requestRevision,
        message: "Read preparation status", language: "English", history: [], expectedEntitlementRevision: r.entitlementRevision, actionId: p.actionId, entityId: p.entityId};
      const current = await (this.deps.context.readPrepared?.(actor, selection, p) ?? this.deps.context.read(actor, selection));
      const tools = current.tools.filter(t => t.actionId === p.actionId && t.entityId === p.entityId);
      if (expiry(current.validUntil) <= this.now() || tools.length !== 1 || tools[0]!.sourceRevision !== p.sourceRevision || !tools[0]!.validate(p.fields)) return fail("stale_preparation", 409);
    }
    if ((await this.paid(actor, r.scope)).revision !== revision || expiry(r.validUntil) <= this.now()) return fail("stale_preparation", 409);
    return state;
  }
  async handle(actor: AccountProfileActor, cmd: AssistantCommand): Promise<PreparationState> {
    const request = cmd.payload;
    if (!actor.uid || actor.projectId !== this.deps.projectId || actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
    const store = this.deps.requests;
    const identity: PreparationRequestIdentity = {ownerUid: actor.uid, projectId: actor.projectId, scope: request.scope, requestId: request.requestId};
    const key = digest({actor: {uid: actor.uid, projectId: actor.projectId}, scope: request.scope, requestId: request.requestId});
    if (cmd.operation === "cancel") {
      if (!store) return fail();
      this.cancellations.get(key)?.abort();
      if (!await store.cancel(key, identity)) return fail("request_not_found", 404);
      // An owner may stop their own preparation after paid access expires.
      // Never return retained private proposal data through this control path.
      return {state: "cancelled"};
    }
    const before = await this.paid(actor, request.scope);
    if (!store) return fail();
    if (cmd.operation === "status") {
      const state = await store.read(key, identity) ?? fail("request_not_found", 404);
      return this.validateReady(actor, state, before.revision);
    }
    if (cmd.operation !== "prepare") return fail("invalid_request", 400);
    const input = cmd.payload;
    if (input.expectedEntitlementRevision !== before.revision) return fail("stale_entitlement", 409);
    if (!this.deps.context || !this.deps.usage || !this.deps.model) return fail();
    const claim = await store.claim(key, digest(input), identity);
    if (claim.state === "conflict") return fail("request_identity_conflict", 409);
    if (claim.state !== "claimed") {
      return this.validateReady(actor, claim, before.revision);
    }
    const abort = new AbortController(); this.cancellations.set(key, abort);
    let permit: {id: string; validUntil: string} | undefined;
    let settled = false;
    try {
      const context = await this.readContext(actor, input);
      text(context.revision); if (expiry(context.validUntil) <= this.now() || !context.tools.length) return fail("context_unavailable");
      const tools = context.tools.filter(t => input.actionId === null || t.actionId === input.actionId);
      if (!tools.length || new Set(tools.map(t => t.name)).size !== tools.length || new Set(tools.map(t => `${t.actionId}:${t.entityId}`)).size !== tools.length) return fail("context_unavailable");
      for (const tool of tools) {
        if (!/^[a-zA-Z][a-zA-Z0-9_]{0,63}$/u.test(tool.name) || tool.name === clarificationToolName) return fail();
        id(tool.actionId); text(tool.sourceRevision); text(tool.description, 1000); assertStrictSchema(tool.parameters);
        if (input.entityId !== null && tool.entityId !== input.entityId) return fail("context_unavailable");
      }
      const binding = contextBinding({...context, tools});
      permit = await this.deps.usage.reserve(actor, input);
      id(permit.id); if (expiry(permit.validUntil) <= this.now() || abort.signal.aborted) return fail("request_cancelled", 409);
      // Usage/source reads may await external authority. Revalidate immediately
      // before spending on a model call, not merely after its result arrives.
      const spending = await this.paid(actor, input.scope);
      const spendingContext = await this.readContext(actor, input);
      if (abort.signal.aborted || before.until <= this.now() || before.revision !== spending.revision ||
          expiry(spendingContext.validUntil) <= this.now() ||
          binding !== contextBinding({...spendingContext, tools: spendingContext.tools.filter(t => input.actionId === null || t.actionId === input.actionId)})) return fail("stale_preparation", 409);
      await store.markDispatched?.(key, claim.lease, identity);
      const prepared = await this.deps.model.prepare(input, tools, abort.signal, context.modelContext);
      if (abort.signal.aborted) return await store.finish(key, claim.lease, {state: "cancelled"}, identity);
      const after = await this.paid(actor, input.scope);
      const current = await this.readContext(actor, input);
      const latest = await store.read(key, identity);
      if (!latest) return fail("request_state_unavailable");
      if (abort.signal.aborted || latest?.state === "cancelled") return await store.finish(key, claim.lease, {state: "cancelled"}, identity);
      if (before.revision !== after.revision || binding !== contextBinding({...current, tools: current.tools.filter(t => input.actionId === null || t.actionId === input.actionId)})) return fail("stale_preparation", 409);
      const checked = this.now(), until = Math.min(before.until, after.until, expiry(context.validUntil), expiry(current.validUntil), expiry(permit.validUntil));
      if (until <= checked) return fail("stale_preparation", 409);
      let outcome: PreparationReply["outcome"];
      if (prepared.kind === "clarification") outcome = {kind: "clarification", text: text(prepared.text, 2000)};
      else {
        const matches = tools.filter(t => t.name === prepared.name);
        if (matches.length !== 1) return fail("invalid_model_result");
        const tool = matches[0]!;
        // Field and meaning validation belongs to the registered original capability.
        if (Object.keys(prepared.arguments).some(k => !Object.hasOwn(tool.parameters.properties as object, k))) return fail("invalid_model_result");
        const target = tool.resolveTarget ? tool.resolveTarget(prepared.arguments) : null;
        if (tool.resolveTarget && !target) return fail("invalid_model_result");
        const fields = target ? target.fields : tool.decodeFields?.(prepared.arguments) ?? prepared.arguments;
        const entityId = target ? target.entityId === null ? null : id(target.entityId) : tool.entityId;
        const sourceRevision = text(target ? target.sourceRevision : tool.sourceRevision, 256);
        if (target && !context.nativeTargets || context.nativeTargets &&
            context.nativeTargets.filter(t => t.actionId === tool.actionId &&
              t.entityId === entityId && t.sourceRevision === sourceRevision).length !== 1) return fail("invalid_model_result");
        if (!tool.validate(fields)) return fail("invalid_model_result");
        outcome = {kind: "proposal", id: randomUUID(), actionId: tool.actionId, entityId,
          sourceRevision, title: text(target?.title ?? tool.description, 1000),
          summary: text(target?.summary ?? "Review the suggested details before continuing.", 2000),
          fields: JSON.parse(canonical(fields)) as Readonly<Record<string, unknown>>};
      }
      await this.deps.usage.settle(permit.id, "completed"); settled = true;
      const finalPaid = await this.paid(actor, input.scope);
      const finalContext = await this.readContext(actor, input);
      if (finalPaid.revision !== after.revision || expiry(finalContext.validUntil) <= this.now() ||
          binding !== contextBinding({...finalContext, tools: finalContext.tools.filter(t => input.actionId === null || t.actionId === input.actionId)})) return fail("stale_preparation", 409);
      if (abort.signal.aborted || this.now() >= until) return fail("stale_preparation", 409);
      return await store.finish(key, claim.lease, {state: "ready", reply: {requestId: input.requestId, requestRevision: input.requestRevision,
        scope: input.scope, entitlementRevision: after.revision, checkedAt: new Date(checked).toISOString(), validUntil: new Date(until).toISOString(), outcome}}, identity);
    } catch (error) {
      await store.finish(key, claim.lease, {state: abort.signal.aborted ? "cancelled" : "failed"}, identity);
      throw error;
    } finally {
      if (permit && !settled) await this.deps.usage.settle(permit.id, "uncertain");
      if (this.cancellations.get(key) === abort) this.cancellations.delete(key);
    }
  }
}
