import {createHash} from "node:crypto";
import type {DataConnect} from "firebase-admin/data-connect";
import {plansFail, type AccountPlansRepository, type PlansRepositorySnapshot, type PlansScope} from "./plans_service.js";

/** One PostgreSQL snapshot, using the existing AppUser account master.
 * Parameters cannot become SQL text. Missing catalogue differs from an empty
 * approved catalogue; no subscription row means no assigned paid benefits. */
export const ACCOUNT_PLANS_READ_SQL = `
SELECT a.uid AS "ownerUid", a.status AS "accountStatus",
       c.document_json AS catalogue, s.document_json AS subscription
FROM app_user a
LEFT JOIN account_plan_catalogue c ON c.audience = $2
LEFT JOIN account_plan_subscription s ON s.scope_key = $3 AND s.owner_uid = a.uid
WHERE a.uid = $1
`;
export function accountPlansScopeKey(ownerUid: string, scope: PlansScope): string {
  return createHash("sha256").update(JSON.stringify([ownerUid, scope.audience, scope.storeId])).digest("hex");
}
export class DataConnectAccountPlansRepository implements AccountPlansRepository {
  constructor(private readonly transport: Pick<DataConnect, "executeGraphqlRead">) {}
  async read(ownerUid: string, scope: PlansScope): Promise<PlansRepositorySnapshot | undefined> {
    const result = await this.transport.executeGraphqlRead<{
      rows: readonly {ownerUid: string; accountStatus: string; catalogue: string | null; subscription: string | null}[];
    }, {uid: string; audience: string; scopeKey: string}>(`
      query ReadScopedAccountPlans($uid:String!,$audience:String!,$scopeKey:String!) {
        rows:_executeQuery(sql:"""${ACCOUNT_PLANS_READ_SQL}""",params:[$uid,$audience,$scopeKey])
      }`, {variables: {uid: ownerUid, audience: scope.audience, scopeKey: accountPlansScopeKey(ownerUid, scope)}});
    const rows = result.data.rows;
    if (!Array.isArray(rows) || rows.length > 1) return plansFail();
    if (rows.length === 0) return undefined;
    const row = rows[0]!;
    if (row.ownerUid !== ownerUid || !["ACTIVE", "RESTRICTED", "DELETED"].includes(row.accountStatus)) return plansFail();
    if (row.accountStatus !== "ACTIVE") return {ownerUid, accountStatus: row.accountStatus, catalogue: null, subscription: null};
    function parse(value: string | null): unknown {
      if (value === null) return null;
      if (typeof value !== "string" || Buffer.byteLength(value, "utf8") > 1024 * 1024) return plansFail();
      try { return JSON.parse(value) as unknown; } catch { return plansFail(); }
    }
    return {ownerUid, accountStatus: row.accountStatus, catalogue: parse(row.catalogue), subscription: parse(row.subscription)};
  }
}
