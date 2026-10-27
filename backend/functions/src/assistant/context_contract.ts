import {digest, fail, object, text} from "./model_contract.js";
import type {AccountProfile} from "../account/profile_service.js";

export const profileContextActions = new Set(["AI-ACT-025", "AI-ACT-026", "AI-ACT-196", "AI-ACT-197", "AI-ACT-210"]);
export const workspaceContextActions = new Set(["AI-ACT-317"]);
export const addressFields = ["recipient", "phone", "line", "area", "pinCode", "landmark", "kind"] as const;
export function profileSourceRevision(profile: Pick<AccountProfile, "revision">): string {
  if (!Number.isSafeInteger(profile.revision) || profile.revision < 0) return fail("context_unavailable");
  return `profile:${profile.revision}`;
}
export interface AuthorisedWorkspace {
  readonly id: string; readonly name: string; readonly profileId: string;
  readonly revision: string; readonly validUntil: number;
}
export function workspaceSourceRevision(workspaceId: string, membershipId: string,
  version: number, applicationUpdatedAt: string): string {
  return `workspace:${digest({applicationUpdatedAt, membershipId, version, workspaceId})}`;
}
/** Consumes the existing B03 readback. It does not issue or project membership. */
export function authorisedWorkspaces(raw: unknown, accountId: string, now: number): readonly AuthorisedWorkspace[] {
  const rows = object(raw).workspaces;
  if (!Array.isArray(rows)) return fail("context_unavailable");
  const result: AuthorisedWorkspace[] = [], ids = new Set<string>();
  for (const value of rows) {
    const row = object(value), access = object(row.access);
    if (row.workspaceId !== undefined) {
      const seenId = text(row.workspaceId, 128);
      if (ids.has(seenId)) return fail("context_unavailable"); ids.add(seenId);
    }
    if (access.state !== "active") continue;
    const member = object(access.membership), id = text(row.workspaceId, 128);
    if (access.schemaVersion !== 1 || access.accountId !== accountId || access.workspaceId !== id ||
        access.caseId !== row.caseId || access.profileId !== row.profileId || member.workspaceId !== id ||
        member.workspaceProfileId !== row.profileId || member.schemaVersion !== 1 || member.state !== "active" ||
        !["approved", "live"].includes(String(row.status)) ||
        !["retailer-grocery", "retailer-speciality", "wholesaler", "manufacturer"].includes(String(row.profileId)) ||
        !Number.isSafeInteger(member.version) || (member.version as number) < 1) return fail("context_unavailable");
    const checked = stamp(access.checkedAt), updated = stamp(access.applicationUpdatedAt), effective = stamp(member.effectiveFrom);
    const expires = member.expiresAt === undefined ? checked + 60_000 : stamp(member.expiresAt);
    if (checked > now || now - checked > 60_000 || updated > checked || effective > now || expires <= now) return fail("context_unavailable");
    result.push({id, name: text(row.name, 200), profileId: row.profileId as string,
      revision: workspaceSourceRevision(id, text(member.membershipId, 128), member.version as number, access.applicationUpdatedAt as string),
      validUntil: Math.min(checked + 60_000, expires)});
  }
  return result.sort((a, b) => a.id.localeCompare(b.id, "en"));
}
function stamp(value: unknown): number {
  const string = text(value, 40), at = Date.parse(string);
  if (!Number.isFinite(at) || new Date(at).toISOString() !== string) return fail("context_unavailable");
  return at;
}
/** Strict nullable tool slots become only actually supplied original form keys. */
export function decodeAddressSuggestion(value: Readonly<Record<string, unknown>>): Readonly<Record<string, string>> {
  const fields = object(value, addressFields), result: Record<string, string> = {};
  for (const key of addressFields) {
    if (fields[key] === null) continue;
    const string = key === "landmark" && fields[key] === "" ? "" : text(fields[key], key === "line" ? 2000 : 200);
    if (key === "phone" && !/^\d{10}$/u.test(string.trim()) ||
        key === "pinCode" && !/^\d{6}$/u.test(string.trim()) ||
        key === "kind" && !["home", "work", "thirdParty", "other"].includes(string)) return fail("invalid_model_result");
    result[key] = string;
  }
  if (!Object.keys(result).length) return fail("invalid_model_result");
  return Object.freeze(result);
}
