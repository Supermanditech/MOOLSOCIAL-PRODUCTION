import {randomUUID} from "node:crypto";
import type {AccountProfileActor} from "../account/profile_service.js";
import type {AccountPlansService, PlansScope} from "../account/plans_service.js";
import {assertStrictSchema, canonical, digest, fail, id, text, clarificationToolName, type AssistantCommand, type PreparationContext, type PreparationReply, type PreparationRequest} from "./model_contract.js";
import type {PreparationModel} from "./responses_transport.js";

export type PreparationState = {state: "pending" | "cancelled" | "failed"} | {state: "ready"; reply: PreparationReply};
export interface PreparationRequestStore {
  /** Must be atomic, owner-keyed and durable before production enablement. No in-memory runtime fallback. */
  claim(key: string, fingerprint: string): Promise<{state: "claimed"; lease: string} | {state: "conflict"} | PreparationState>;
  /** Undefined means authoritative absence; an unavailable store must throw. */
  read(key: string): Promise<PreparationState | undefined>;
  /** Atomic lease/cancellation check; a late completion cannot overwrite cancel. */
  finish(key: string, lease: string, result: PreparationState): Promise<PreparationState>;
  cancel(key: string): Promise<PreparationState | undefined>;
}
export interface PreparationUsageAuthority {
  reserve(actor: AccountProfileActor, request: PreparationRequest): Promise<{id: string; validUntil: string}>;
  /** Idempotent by reservation ID. Uncertain is not confirmed token usage/charge. */
  settle(id: string, outcome: "completed" | "uncertain"): Promise<void>;
}
export interface PreparationContextSource {
  /** Original permission/source authority only; client hints never grant access. */
  read(actor: AccountProfileActor, request: PreparationRequest): Promise<PreparationContext>;
}
function expiry(stamp: string): number {
  const value = Date.parse(stamp);
  if (!Number.isFinite(value) || new Date(value).toISOString() !== stamp) return fail();
  return value;
}
function contextBinding(c: PreparationContext): string {
  return canonical({revision: c.revision, tools: c.tools.map(t => ({name: t.name, actionId: t.actionId, entityId: t.entityId,
    sourceRevision: t.sourceRevision, description: t.description, parameters: t.parameters}))});
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
  private async validateReady(actor: AccountProfileActor, state: PreparationState, revision: string): Promise<PreparationState> {
    if (state.state !== "ready") return state;
    const r = state.reply;
    if (r.entitlementRevision !== revision || expiry(r.validUntil) <= this.now()) return fail("stale_preparation", 409);
    if (r.outcome.kind === "proposal") {
      if (!this.deps.context) return fail("context_unavailable");
      const p = r.outcome;
      const current = await this.deps.context.read(actor, {scope: r.scope, requestId: r.requestId, requestRevision: r.requestRevision,
        message: "Read preparation status", language: "English", history: [], expectedEntitlementRevision: r.entitlementRevision, actionId: p.actionId, entityId: p.entityId});
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
    const key = digest({actor: {uid: actor.uid, projectId: actor.projectId}, scope: request.scope, requestId: request.requestId});
    if (cmd.operation === "cancel") {
      if (!store) return fail();
      this.cancellations.get(key)?.abort();
      if (!await store.cancel(key)) return fail("request_not_found", 404);
      // An owner may stop their own preparation after paid access expires.
      // Never return retained private proposal data through this control path.
      return {state: "cancelled"};
    }
    const before = await this.paid(actor, request.scope);
    if (!store) return fail();
    if (cmd.operation === "status") {
      const state = await store.read(key) ?? fail("request_not_found", 404);
      return this.validateReady(actor, state, before.revision);
    }
    if (cmd.operation !== "prepare") return fail("invalid_request", 400);
    const input = cmd.payload;
    if (input.expectedEntitlementRevision !== before.revision) return fail("stale_entitlement", 409);
    if (!this.deps.context || !this.deps.usage || !this.deps.model) return fail();
    const claim = await store.claim(key, digest(input));
    if (claim.state === "conflict") return fail("request_identity_conflict", 409);
    if (claim.state !== "claimed") {
      return this.validateReady(actor, claim, before.revision);
    }
    const abort = new AbortController(); this.cancellations.set(key, abort);
    let permit: {id: string; validUntil: string} | undefined;
    let settled = false;
    try {
      const context = await this.deps.context.read(actor, input);
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
      const spendingContext = await this.deps.context.read(actor, input);
      if (abort.signal.aborted || before.until <= this.now() || before.revision !== spending.revision ||
          expiry(spendingContext.validUntil) <= this.now() ||
          binding !== contextBinding({...spendingContext, tools: spendingContext.tools.filter(t => input.actionId === null || t.actionId === input.actionId)})) return fail("stale_preparation", 409);
      const prepared = await this.deps.model.prepare(input, tools, abort.signal);
      if (abort.signal.aborted) return await store.finish(key, claim.lease, {state: "cancelled"});
      const after = await this.paid(actor, input.scope);
      const current = await this.deps.context.read(actor, input);
      const latest = await store.read(key);
      if (!latest) return fail("request_state_unavailable");
      if (abort.signal.aborted || latest?.state === "cancelled") return await store.finish(key, claim.lease, {state: "cancelled"});
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
        if (!tool.validate(prepared.arguments) || Object.keys(prepared.arguments).some(k => !Object.hasOwn(tool.parameters.properties as object, k))) return fail("invalid_model_result");
        outcome = {kind: "proposal", id: randomUUID(), actionId: tool.actionId, entityId: tool.entityId,
          sourceRevision: tool.sourceRevision, title: tool.description, summary: "Review the suggested details before continuing.",
          fields: JSON.parse(canonical(prepared.arguments)) as Readonly<Record<string, unknown>>};
      }
      await this.deps.usage.settle(permit.id, "completed"); settled = true;
      const finalPaid = await this.paid(actor, input.scope);
      const finalContext = await this.deps.context.read(actor, input);
      if (finalPaid.revision !== after.revision || expiry(finalContext.validUntil) <= this.now() ||
          binding !== contextBinding({...finalContext, tools: finalContext.tools.filter(t => input.actionId === null || t.actionId === input.actionId)})) return fail("stale_preparation", 409);
      if (abort.signal.aborted || this.now() >= until) return fail("stale_preparation", 409);
      return await store.finish(key, claim.lease, {state: "ready", reply: {requestId: input.requestId, requestRevision: input.requestRevision,
        scope: input.scope, entitlementRevision: after.revision, checkedAt: new Date(checked).toISOString(), validUntil: new Date(until).toISOString(), outcome}});
    } catch (error) {
      await store.finish(key, claim.lease, {state: abort.signal.aborted ? "cancelled" : "failed"});
      throw error;
    } finally {
      if (permit && !settled) await this.deps.usage.settle(permit.id, "uncertain");
      if (this.cancellations.get(key) === abort) this.cancellations.delete(key);
    }
  }
}
