import type {AccountProfileActor, AccountProfileService} from "../account/profile_service.js";
import type {AccountPlansService, PlansReadback} from "../account/plans_service.js";
import type {PreparationContextSource} from "./model_service.js";
import {canonical, digest, fail, type PreparationContext, type PreparationRequest, type PreparationTool} from "./model_contract.js";
import {addressFields, authorisedWorkspaces, decodeAddressSuggestion, profileContextActions, profileSourceRevision, workspaceContextActions} from "./context_contract.js";

const strict = (properties: Record<string, unknown>) => ({type: "object", properties, required: Object.keys(properties), additionalProperties: false});
const addressSchema = strict(Object.fromEntries(addressFields.map(key => [key, {type: ["string", "null"]}])));
const empty = strict({});
const noFields = (fields: Readonly<Record<string, unknown>>) => Object.keys(fields).length === 0;
function addressValid(fields: Readonly<Record<string, unknown>>, editing: boolean): boolean {
  try {
    if (Object.keys(fields).some(key => !(addressFields as readonly string[]).includes(key))) return false;
    const parsed = decodeAddressSuggestion({...Object.fromEntries(addressFields.map(key => [key, null])), ...fields});
    return editing || Object.keys(parsed).some(key => key !== "kind");
  } catch {return false;}
}
const paidRevision = (value: PlansReadback) => `${value.catalogueRevision}:${value.subscriptionRevision}`;

/** Reads original services only. No caller profile, membership or capability list. */
export class ProfileWorkspacePreparationContext implements PreparationContextSource {
  constructor(private readonly services: {
    readonly profile: Pick<AccountProfileService, "read">;
    readonly plans: Pick<AccountPlansService, "read">;
    readonly workspaces: (actor: AccountProfileActor) => Promise<unknown>;
    readonly now?: () => Date;
  }) {}
  async read(actor: AccountProfileActor, input: PreparationRequest): Promise<PreparationContext> {
    const now = () => (this.services.now?.() ?? new Date()).getTime();
    const before = await this.services.plans.read(actor, input.scope);
    if (!before.activeFeatureIds.includes("mool_ai")) return fail("ai_access_required", 403);
    if (before.owner.userId !== actor.uid || before.owner.projectId !== actor.projectId ||
        canonical(before.scope) !== canonical(input.scope)) return fail("account_scope_mismatch", 403);
    let context: PreparationContext;
    if (input.scope.audience === "personal") {
      if (input.actionId !== null && !profileContextActions.has(input.actionId)) return fail("context_unavailable");
      const profile = await this.services.profile.read(actor);
      if (profile.ownerUid !== actor.uid) return fail("account_scope_mismatch", 403);
      const revision = profileSourceRevision(profile), tools: PreparationTool[] = [
        {name: "profile_view", actionId: "AI-ACT-196", entityId: null, sourceRevision: revision,
          description: "View my personal profile", parameters: strict({section: {type: "string", enum: ["identity", "delivery", "invoices"]}}),
          validate: f => Object.keys(f).length === 1 && typeof f.section === "string" && ["identity", "delivery", "invoices"].includes(f.section)},
        {name: "profile_prepare_name", actionId: "AI-ACT-197", entityId: null, sourceRevision: revision,
          description: "Review my display name", parameters: strict({displayName: {type: "string"}}),
          decodeFields: f => {
            if (Object.keys(f).length !== 1 || typeof f.displayName !== "string") return fail("invalid_model_result");
            return {displayName: f.displayName.trim().replace(/\s+/gu, " ")};
          },
          validate: f => Object.keys(f).length === 1 && typeof f.displayName === "string" &&
            f.displayName.length >= 2 && f.displayName.length <= 60 && !/[\u0000-\u001f]/u.test(f.displayName)},
        {name: "profile_prepare_address_add", actionId: "AI-ACT-025", entityId: null, sourceRevision: revision,
          description: "Review a new delivery address", parameters: addressSchema,
          decodeFields: decodeAddressSuggestion, validate: f => addressValid(f, false)},
        {name: "profile_view_plans", actionId: "AI-ACT-210", entityId: null, sourceRevision: revision,
          description: "View my personal plans", parameters: empty, validate: noFields},
      ];
      for (const [index, address] of [...profile.addresses].sort((a, b) => a.id.localeCompare(b.id, "en")).entries()) {
        tools.push({name: `profile_prepare_address_edit_${index}`, actionId: "AI-ACT-026", entityId: address.id,
          sourceRevision: revision, description: "Review changes to my delivery address", parameters: addressSchema,
          decodeFields: decodeAddressSuggestion, validate: f => addressValid(f, true)});
      }
      const selected = tools.filter(t => (input.actionId === null || t.actionId === input.actionId) &&
        (input.entityId === null || t.entityId === input.entityId));
      if (!selected.length) return fail("context_unavailable");
      // Native forms retain omitted values. The model needs selection labels,
      // never all phone numbers, street addresses, GSTINs or invoice records.
      const resource: Record<string, unknown> = {audience: "personal"};
      if (input.actionId === null || ["AI-ACT-196", "AI-ACT-197"].includes(input.actionId)) resource.displayName = profile.displayName;
      if (input.actionId === null || input.actionId === "AI-ACT-026") resource.deliveryChoices = profile.addresses
        .filter(a => input.entityId === null || a.id === input.entityId).map(a => ({id: a.id, label: a.label, area: a.area}));
      const fresh = await this.services.profile.read(actor);
      if (canonical(fresh) !== canonical(profile)) return fail("stale_preparation", 409);
      context = {revision, validUntil: before.validUntil, tools: selected, modelContext: resource};
    } else {
      if (input.actionId !== null && !workspaceContextActions.has(input.actionId)) return fail("context_unavailable");
      const choices = authorisedWorkspaces(await this.services.workspaces(actor), actor.uid, now());
      const current = choices.find(row => row.id === input.scope.storeId);
      if (!current) return fail("workspace_access_unavailable");
      const tools: PreparationTool[] = choices.filter(row => input.entityId === null || row.id === input.entityId).map(row => ({
        name: `workspace_open_${choices.indexOf(row)}`, actionId: "AI-ACT-317", entityId: row.id,
        sourceRevision: row.revision, description: "Review opening an authorised Store",
        parameters: strict({workspaceId: {type: "string", enum: [row.id]}}),
        validate: f => Object.keys(f).length === 1 && f.workspaceId === row.id,
      }));
      if (!tools.length) return fail("context_unavailable");
      const fresh = authorisedWorkspaces(await this.services.workspaces(actor), actor.uid, now());
      const binding = (rows: typeof choices) => rows.map(row => ({id: row.id, name: row.name, profileId: row.profileId, revision: row.revision}));
      if (canonical(binding(choices)) !== canonical(binding(fresh))) return fail("stale_preparation", 409);
      context = {revision: `workspace-context:${digest(binding(choices))}`,
        validUntil: new Date(Math.min(Date.parse(before.validUntil), ...choices.map(row => row.validUntil), ...fresh.map(row => row.validUntil))).toISOString(),
        tools, modelContext: {audience: "workspace", current: {id: current.id, name: current.name, kind: current.profileId},
          choices: choices.map(row => ({id: row.id, name: row.name, kind: row.profileId}))}};
    }
    const after = await this.services.plans.read(actor, input.scope);
    if (after.owner.userId !== actor.uid || after.owner.projectId !== actor.projectId ||
        canonical(after.scope) !== canonical(input.scope) || !after.activeFeatureIds.includes("mool_ai") ||
        paidRevision(before) !== paidRevision(after)) return fail("stale_preparation", 409);
    const until = Math.min(Date.parse(context.validUntil), Date.parse(after.validUntil));
    if (!Number.isFinite(until) || until <= now()) return fail("stale_preparation", 409);
    return {...context, validUntil: new Date(until).toISOString()};
  }
}
