import type {AccountProfileActor} from "./profile_service.js";

export class AccountPlansError extends Error {
  constructor(readonly code: string, readonly status = 503) { super(code); }
}
export interface PlansScope { readonly audience: "personal" | "workspace"; readonly storeId: string | null }
export interface PlansOffer {
  readonly id: string; readonly version: string; readonly name: string;
  readonly priceLabel: string; readonly features: readonly string[];
  readonly featureIds: readonly string[];
  readonly eligible: boolean; readonly recommended: boolean;
}
export interface PlansSubscription {
  readonly ownerUid: string; readonly scope: PlansScope; readonly revision: number;
  readonly planId: string; readonly planVersion: string; readonly name: string;
  readonly state: "active" | "cancelled" | "pending" | "expired" | "revoked";
  readonly validFrom: string; readonly validUntil: string;
  /** Immutable assigned-version benefits, not the current catalogue's benefits. */
  readonly featureIds: readonly string[];
}
export interface PlansRepositorySnapshot {
  readonly ownerUid: string; readonly accountStatus: string;
  readonly catalogue: unknown; readonly subscription: unknown;
}
/** Read all rows in one durable snapshot. No billing or entitlement writer. */
export interface AccountPlansRepository {
  read(ownerUid: string, scope: PlansScope): Promise<PlansRepositorySnapshot | undefined>;
}
export interface PlansReadback {
  readonly schemaVersion: 1; readonly owner: {readonly userId: string; readonly projectId: string};
  readonly scope: PlansScope; readonly catalogueRevision: number;
  readonly subscriptionRevision: number; readonly checkedAt: string; readonly validUntil: string;
  readonly offers: readonly PlansOffer[]; readonly subscription: PlansSubscription | null;
  readonly activeFeatureIds: readonly string[];
}
export function plansFail(code = "plans_unavailable", status = 503): never {
  throw new AccountPlansError(code, status);
}
export function plansObject(value: unknown, keys?: readonly string[]): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return plansFail();
  const row = value as Record<string, unknown>;
  if (keys && Object.keys(row).sort().join("|") !== [...keys].sort().join("|")) return plansFail();
  return row;
}
function text(value: unknown, max = 180): string {
  if (typeof value !== "string" || !value.trim() || value !== value.trim() || value.length > max || /[\u0000-\u001f]/u.test(value)) return plansFail();
  return value;
}
export function plansId(value: unknown): string {
  const id = text(value, 128);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]*$/u.test(id)) return plansFail();
  return id;
}
function integer(value: unknown, minimum = 1): number {
  if (!Number.isSafeInteger(value) || (value as number) < minimum) return plansFail();
  return value as number;
}
function stamp(value: unknown): number {
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value)) || new Date(value).toISOString() !== value) return plansFail();
  return Date.parse(value);
}
function strings(value: unknown, ids = false): string[] {
  if (!Array.isArray(value)) return plansFail();
  const result = value.map(item => ids ? plansId(item) : text(item, 320));
  if (new Set(result).size !== result.length) return plansFail();
  return result;
}
export function decodePlansScope(value: unknown): PlansScope {
  const row = plansObject(value, ["audience", "storeId"]);
  if (row.audience === "personal" && row.storeId === null) return {audience: "personal", storeId: null};
  if (row.audience === "workspace") return {audience: "workspace", storeId: plansId(row.storeId)};
  return plansFail("invalid_plans_request", 400);
}
function sameScope(a: PlansScope, b: PlansScope): boolean { return a.audience === b.audience && a.storeId === b.storeId; }
function offer(value: unknown): PlansOffer {
  const row = plansObject(value, ["id", "version", "name", "priceLabel", "features", "featureIds", "eligible", "recommended"]);
  if (typeof row.eligible !== "boolean" || typeof row.recommended !== "boolean") return plansFail();
  return {id: plansId(row.id), version: plansId(row.version), name: text(row.name), priceLabel: text(row.priceLabel, 240),
    features: strings(row.features), featureIds: strings(row.featureIds, true), eligible: row.eligible, recommended: row.recommended};
}
function subscription(value: unknown, owner: string, scope: PlansScope): PlansSubscription | null {
  if (value === null) return null;
  const row = plansObject(value, ["ownerUid", "scope", "revision", "planId", "planVersion", "name", "state", "validFrom", "validUntil", "featureIds"]);
  if (row.ownerUid !== owner || !sameScope(decodePlansScope(row.scope), scope) ||
      !["active", "cancelled", "pending", "expired", "revoked"].includes(String(row.state)) ||
      stamp(row.validUntil) <= stamp(row.validFrom)) return plansFail();
  return {ownerUid: owner, scope, revision: integer(row.revision), planId: plansId(row.planId),
    planVersion: plansId(row.planVersion), name: text(row.name), state: row.state as PlansSubscription["state"],
    validFrom: row.validFrom as string, validUntil: row.validUntil as string, featureIds: strings(row.featureIds, true)};
}

/** Uses B03's existing readback, not its descriptive free/paid plan label. */
function storeProof(value: unknown, actor: AccountProfileActor, scope: PlansScope, at: number): {revision: string; expires: number} {
  const list = plansObject(value).workspaces;
  if (!Array.isArray(list)) return plansFail();
  const matches = list.map(item => plansObject(item)).filter(item => item.workspaceId === scope.storeId);
  if (matches.length !== 1) return plansFail("workspace_access_unavailable");
  const row = matches[0]!;
  const access = plansObject(row.access);
  const member = plansObject(access.membership);
  if (!["approved", "live"].includes(String(row.status)) || access.schemaVersion !== 1 || access.state !== "active" ||
      access.accountId !== actor.uid || access.workspaceId !== scope.storeId || access.caseId !== row.caseId ||
      access.profileId !== row.profileId || !["retailer-grocery", "retailer-speciality", "wholesaler", "manufacturer"].includes(String(row.profileId)) ||
      member.workspaceId !== scope.storeId || member.workspaceProfileId !== row.profileId || member.state !== "active" ||
      stamp(access.applicationUpdatedAt) > at || stamp(access.checkedAt) > at || at - stamp(access.checkedAt) > 60_000 ||
      stamp(member.effectiveFrom) > at) return plansFail("workspace_access_unavailable");
  const expires = member.expiresAt === undefined ? at + 60_000 : stamp(member.expiresAt);
  if (expires <= at) return plansFail("workspace_access_unavailable");
  return {revision: `${plansId(row.caseId)}:${access.applicationUpdatedAt}:${plansId(member.membershipId)}:${integer(member.version)}`, expires};
}

export class AccountPlansService {
  constructor(private readonly repository: AccountPlansRepository,
    private readonly options: {readonly projectId: string; readonly now?: () => Date;
      readonly readWorkspaces?: (actor: AccountProfileActor) => Promise<unknown>}) {}
  async read(actor: AccountProfileActor, input: unknown): Promise<PlansReadback> {
    if (!actor.uid || actor.uid.length > 128 || actor.projectId !== this.options.projectId || actor.tenantId !== undefined) return plansFail("account_scope_mismatch", 403);
    const scope = decodePlansScope(input);
    const now = this.options.now ?? (() => new Date());
    const initial = now().getTime();
    const readProof = async () => {
      if (!this.options.readWorkspaces) return plansFail("workspace_access_unavailable");
      return storeProof(await this.options.readWorkspaces(actor), actor, scope, now().getTime());
    };
    const before = scope.audience === "workspace" ? await readProof() : null;
    const snapshot = await this.repository.read(actor.uid, scope);
    if (!snapshot || snapshot.ownerUid !== actor.uid) return plansFail();
    if (snapshot.accountStatus !== "ACTIVE") return plansFail("account_restricted", 403);
    const catalogue = plansObject(snapshot.catalogue, ["audience", "revision", "state", "offers"]);
    if (catalogue.audience !== scope.audience || catalogue.state !== "approved" || !Array.isArray(catalogue.offers)) return plansFail();
    const offers = catalogue.offers.map(offer);
    if (new Set(offers.map(item => item.id)).size !== offers.length) return plansFail();
    const sub = subscription(snapshot.subscription, actor.uid, scope);
    const after = before ? await readProof() : null;
    const checked = now().getTime();
    if (checked < initial || checked - initial > 60_000 || (before && after?.revision !== before.revision)) return plansFail();
    const active = sub !== null && ["active", "cancelled"].includes(sub.state) && stamp(sub.validFrom) <= checked && stamp(sub.validUntil) > checked;
    const until = Math.min(checked + 60_000, before?.expires ?? Infinity, after?.expires ?? Infinity,
      active ? stamp(sub!.validUntil) : Infinity);
    if (until <= checked) return plansFail();
    const result: PlansReadback = {schemaVersion: 1, owner: {userId: actor.uid, projectId: actor.projectId}, scope,
      catalogueRevision: integer(catalogue.revision), subscriptionRevision: sub?.revision ?? 0,
      checkedAt: new Date(checked).toISOString(), validUntil: new Date(until).toISOString(), offers,
      subscription: sub, activeFeatureIds: active ? sub!.featureIds : []};
    if (Buffer.byteLength(JSON.stringify({ok: true, data: result}), "utf8") > 1024 * 1024) return plansFail();
    return result;
  }
}
