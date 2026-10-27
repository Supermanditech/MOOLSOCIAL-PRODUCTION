import {AccountProfileError} from "../account/profile_service.js";
import {createHash} from "node:crypto";
import type {AccountProfileActor, AccountProfileReceipt, AccountProfileService, AccountProfile} from "../account/profile_service.js";
import type {AccountPlansService} from "../account/plans_service.js";
import {canonical, digest, id, object, fail} from "./model_contract.js";
import type {PreparationRequestStore, PreparationRequestIdentity} from "./model_service.js";
import {preparationKey, type AssistantSql} from "./preparation_dataconnect_store.js";

export interface ProfilePreparationConsent {
  readonly preparationRequestId: string; readonly proposalId: string; readonly actionId: string;
  readonly entityId: string | null; readonly sourceRevision: string; readonly entitlementRevision: string;
}
export const ASSISTANT_PROFILE_OPERATION_DDL = `CREATE TABLE IF NOT EXISTS assistant_profile_operation (
 preparation_key varchar(64) PRIMARY KEY, owner_uid text NOT NULL REFERENCES app_user(uid) ON DELETE CASCADE,
 project_id text NOT NULL, operation_id varchar(128) NOT NULL, proposal_id varchar(128) NOT NULL,
 fingerprint varchar(64) NOT NULL, consent_json text NOT NULL, confirmed_revision integer,
 created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL
);`;
const READ = `SELECT to_jsonb(r)::text AS record_json FROM assistant_profile_operation r
 WHERE preparation_key=$1 AND owner_uid=$2 AND project_id=$3
 AND EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')`;
const CLAIM = `INSERT INTO assistant_profile_operation(preparation_key,owner_uid,project_id,operation_id,proposal_id,fingerprint,consent_json,created_at,updated_at)
 SELECT $1,$2,$3,$4,$5,$6,$7,$8::timestamptz,$8::timestamptz
 WHERE EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')
 ON CONFLICT(preparation_key) DO NOTHING RETURNING to_jsonb(assistant_profile_operation)::text AS record_json`;
const CONFIRM = `UPDATE assistant_profile_operation SET confirmed_revision=$5::integer,updated_at=$6::timestamptz
 WHERE preparation_key=$1 AND owner_uid=$2 AND project_id=$3 AND operation_id=$4
 AND (confirmed_revision IS NULL OR confirmed_revision=$5::integer)
 RETURNING to_jsonb(assistant_profile_operation)::text AS record_json`;
interface Operation {preparation_key: string; owner_uid: string; project_id: string; operation_id: string;
  proposal_id: string; fingerprint: string; consent_json: string; confirmed_revision: number | null}
function decode(raw: readonly Record<string, unknown>[]): Operation | undefined {
  if (raw.length > 1) return fail("profile_operation_unavailable");
  if (!raw.length) return undefined;
  try {return JSON.parse(raw[0]!.record_json as string) as Operation;} catch {return fail("profile_operation_unavailable");}
}
function consent(raw: unknown): ProfilePreparationConsent {
  const v = object(raw, ["preparationRequestId", "proposalId", "actionId", "entityId", "sourceRevision", "entitlementRevision"]);
  if (!["AI-ACT-197", "AI-ACT-025", "AI-ACT-026"].includes(String(v.actionId)) ||
      typeof v.sourceRevision !== "string" || !/^profile:[0-9]+$/u.test(v.sourceRevision) ||
      typeof v.entitlementRevision !== "string" || v.entitlementRevision.length > 256) return fail("invalid_profile_preparation", 400);
  return {preparationRequestId: id(v.preparationRequestId), proposalId: id(v.proposalId), actionId: id(v.actionId),
    entityId: v.entityId === null ? null : id(v.entityId), sourceRevision: v.sourceRevision, entitlementRevision: v.entitlementRevision};
}

/** Native Save-only wrapper. The original Profile service owns all validation,
 * atomic mutation, receipts and post-timeout reconciliation. No new write tool. */
export class ProfilePreparationExecutionService {
  constructor(private readonly deps: {projectId: string; sql: AssistantSql; requests: PreparationRequestStore;
    profile: AccountProfileService; plans: AccountPlansService; now?: () => Date}) {}
  private now() {return this.deps.now?.() ?? new Date();}
  private identity(actor: AccountProfileActor, c: ProfilePreparationConsent): PreparationRequestIdentity {
    if (actor.projectId !== this.deps.projectId || !actor.uid || actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
    return {ownerUid: actor.uid, projectId: actor.projectId, scope: {audience: "personal", storeId: null}, requestId: c.preparationRequestId};
  }
  private async operation(actor: AccountProfileActor, c: ProfilePreparationConsent, operationId: string) {
    const identity = this.identity(actor, c), key = preparationKey(identity);
    const row = decode(await this.deps.sql.execute(READ, [key, actor.uid, actor.projectId], false));
    if (row && (row.preparation_key !== key || row.owner_uid !== actor.uid || row.project_id !== actor.projectId ||
        row.operation_id !== operationId || row.proposal_id !== c.proposalId || row.consent_json !== canonical(c))) return fail("profile_operation_conflict", 409);
    return {row, key, identity};
  }
  private async confirm(actor: AccountProfileActor, key: string, receipt: AccountProfileReceipt) {
    const operation = decode(await this.deps.sql.execute(READ, [key, actor.uid, actor.projectId], false));
    if (!operation) return fail("profile_operation_unavailable");
    const binding = consent(JSON.parse(operation.consent_json) as unknown);
    const change = binding.actionId === "AI-ACT-197"
      ? {kind: "name", displayName: receipt.profile.displayName}
      : {kind: "delivery", addresses: receipt.profile.addresses, selectedAddressId: receipt.profile.selectedAddressId};
    const expectedRevision = receipt.profile.revision - 1;
    const fingerprint = digest({requestId: receipt.requestId, expectedRevision, change});
    const originalFingerprint = createHash("sha256").update(JSON.stringify({expectedRevision, change})).digest("hex");
    if (operation.operation_id !== receipt.requestId || operation.owner_uid !== actor.uid || operation.project_id !== actor.projectId ||
        operation.fingerprint !== fingerprint || receipt.fingerprint !== originalFingerprint) return fail("profile_operation_conflict", 409);
    const saved = decode(await this.deps.sql.execute(CONFIRM, [key, actor.uid, actor.projectId,
      receipt.requestId, String(receipt.profile.revision), this.now().toISOString()], true));
    if (!saved || saved.confirmed_revision !== receipt.profile.revision || saved.operation_id !== receipt.requestId ||
        saved.owner_uid !== actor.uid || saved.project_id !== actor.projectId) return fail("profile_operation_unavailable");
    return receipt;
  }
  private validateChange(profile: AccountProfile, c: ProfilePreparationConsent, raw: unknown) {
    const change = object(raw);
    // Native forms submit trimmed canonical text. Reject a different wire payload
    // rather than duplicating the original Profile service's normalisation rules.
    function canonicalText(value: unknown): boolean {
      if (typeof value === "string") return value === value.trim();
      if (value === null) return true;
      if (Array.isArray(value)) return value.every(canonicalText);
      if (value && typeof value === "object") return Object.values(value).every(canonicalText);
      return false;
    }
    if (!canonicalText(change)) return fail("invalid_profile_preparation", 400);
    if (c.actionId === "AI-ACT-197") {
      if (c.entityId !== null || change.kind !== "name" || Object.keys(change).sort().join("|") !== "displayName|kind") return fail("invalid_profile_preparation", 400);
      if (typeof change.displayName !== "string" || change.displayName.length<2 || change.displayName.length>60 || change.displayName.replace(/\s+/gu, " ") !== change.displayName) return fail("invalid_profile_preparation", 400);
      return;
    }
    if (change.kind !== "delivery" || Object.keys(change).sort().join("|") !== "addresses|kind|selectedAddressId" || !Array.isArray(change.addresses)) return fail("invalid_profile_preparation", 400);
    const before = profile.addresses, after = change.addresses as readonly Record<string, unknown>[];
    const ids = after.map(row => row?.id);
    if (ids.some(value => typeof value !== "string") || new Set(ids).size !== ids.length) return fail("invalid_profile_preparation", 400);
    if (c.actionId === "AI-ACT-025") {
      const added = after.filter(row => !before.some(original => original.id === row.id));
      if (c.entityId !== null || after.length !== before.length + 1 || added.length !== 1 ||
          change.selectedAddressId !== added[0]!.id || before.some(original => !after.some(row => canonical(row) === canonical(original)))) return fail("invalid_profile_preparation", 400);
    } else if (c.entityId === null || after.length !== before.length || change.selectedAddressId !== profile.selectedAddressId ||
        !before.some(row => row.id === c.entityId) || !after.some(row => row.id === c.entityId) ||
        before.filter(row => row.id !== c.entityId).some(original => !after.some(row => canonical(row) === canonical(original)))) return fail("invalid_profile_preparation", 400);
  }
  async reconcile(actor: AccountProfileActor, raw: unknown): Promise<AccountProfileReceipt | null> {
    const payload = object(raw, ["requestId", "assistant"]), operationId = id(payload.requestId), c = consent(payload.assistant);
    const original = await this.operation(actor, c, operationId);
    if (!original.row) return null;
    // Recovery of an already-confirmed original effect does not issue a fresh
    // paid action or disclose a retained model proposal after access expires.
    const receipt = await this.deps.profile.reconcile(actor, {requestId: operationId});
    return receipt ? this.confirm(actor, original.key, receipt) : null;
  }
  async save(actor: AccountProfileActor, raw: unknown): Promise<AccountProfileReceipt> {
    const payload = object(raw, ["requestId", "expectedRevision", "change", "assistant"]);
    const operationId = id(payload.requestId), c = consent(payload.assistant);
    const originalRequest = {requestId: operationId, expectedRevision: payload.expectedRevision, change: payload.change};
    const fingerprint = digest(originalRequest), original = await this.operation(actor, c, operationId);
    if (original.row && original.row.fingerprint !== fingerprint) return fail("profile_operation_conflict", 409);
    if (original.row) {
      const receipt = await this.deps.profile.reconcile(actor, {requestId: operationId});
      if (receipt) return this.confirm(actor, original.key, await this.deps.profile.save(actor, originalRequest));
    }
    const state = await this.deps.requests.read(original.key, original.identity);
    if (state?.state !== "ready" || state.reply.outcome.kind !== "proposal") return fail("profile_preparation_unavailable");
    const reply = state.reply, proposal = state.reply.outcome;
    if (proposal.id !== c.proposalId || proposal.actionId !== c.actionId || proposal.entityId !== c.entityId ||
        proposal.sourceRevision !== c.sourceRevision || reply.entitlementRevision !== c.entitlementRevision ||
        Date.parse(reply.validUntil) <= this.now().getTime() || `profile:${payload.expectedRevision}` !== c.sourceRevision) return fail("stale_preparation", 409);
    const plans = await this.deps.plans.read(actor, original.identity.scope);
    if (!plans.activeFeatureIds.includes("mool_ai") || Date.parse(plans.validUntil) <= this.now().getTime() ||
        `${plans.scope.audience}:${plans.scope.storeId}:${plans.catalogueRevision}:${plans.subscriptionRevision}` !== c.entitlementRevision) return fail("ai_access_required", 403);
    const profile = await this.deps.profile.read(actor);
    if (`profile:${profile.revision}` !== c.sourceRevision) return fail("stale_preparation", 409);
    this.validateChange(profile, c, payload.change);
    if (!original.row) {
      if (await this.deps.profile.reconcile(actor, {requestId: operationId})) return fail("profile_operation_conflict", 409);
      const inserted = decode(await this.deps.sql.execute(CLAIM, [original.key, actor.uid, actor.projectId, operationId,
        c.proposalId, fingerprint, canonical(c), this.now().toISOString()], true));
      const bound = inserted ?? (await this.operation(actor, c, operationId)).row;
      if (!bound || bound.fingerprint !== fingerprint || bound.operation_id !== operationId || bound.consent_json !== canonical(c)) return fail("profile_operation_conflict", 409);
    }
    const finalState = await this.deps.requests.read(original.key, original.identity);
    if (finalState?.state !== "ready" || finalState.reply.outcome.kind !== "proposal" ||
        finalState.reply.outcome.id !== c.proposalId || Date.parse(finalState.reply.validUntil) <= this.now().getTime()) return fail("stale_preparation", 409);
    const finalPlans = await this.deps.plans.read(actor, original.identity.scope);
    if (!finalPlans.activeFeatureIds.includes("mool_ai") || Date.parse(finalPlans.validUntil) <= this.now().getTime() ||
        `${finalPlans.scope.audience}:${finalPlans.scope.storeId}:${finalPlans.catalogueRevision}:${finalPlans.subscriptionRevision}` !== c.entitlementRevision) return fail("ai_access_required", 403);
    // Original revision/receipt transaction is the final atomic write boundary.
    // Any uncertain outcome keeps this exact linkage for original reconciliation.
    try {
      const receipt = await this.deps.profile.save(actor, originalRequest);
      return await this.confirm(actor, original.key, receipt);
    } catch (error) {
      if (error instanceof AccountProfileError) throw error;
      throw new AccountProfileError("profile_outcome_unknown", 503, true);
    }
  }
}
