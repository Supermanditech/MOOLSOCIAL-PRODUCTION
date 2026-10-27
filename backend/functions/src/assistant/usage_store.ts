import {randomUUID} from "node:crypto";
import type {AccountProfileActor} from "../account/profile_service.js";
import type {PlansScope} from "../account/plans_service.js";
import {canonical, digest, fail, id} from "./model_contract.js";
import type {PreparationRequest} from "./model_contract.js";
import type {PreparationUsageAuthority} from "./model_service.js";
import {preparationKey, type AssistantSql} from "./preparation_dataconnect_store.js";

export interface ApprovedUsageGrant {
  readonly authorizationId: string; readonly ownerUid: string; readonly projectId: string;
  readonly scope: PlansScope; readonly requestId: string; readonly entitlementRevision: string; readonly validUntil: string;
}
/** Issuance, quota and billing rules belong to a separately approved authority.
 * It must deduplicate by reservation ID and expose original-status lookup. */
export interface ApprovedUsageAuthorizer {
  authorize(actor: AccountProfileActor, request: PreparationRequest, reservationId: string): Promise<ApprovedUsageGrant>;
  status(actor: AccountProfileActor, request: PreparationRequest, reservationId: string): Promise<ApprovedUsageGrant | undefined>;
}
export const ASSISTANT_USAGE_DDL = `CREATE TABLE IF NOT EXISTS assistant_usage_reservation (
 request_key varchar(64) PRIMARY KEY, reservation_id varchar(128) UNIQUE NOT NULL,
 owner_uid text NOT NULL REFERENCES app_user(uid) ON DELETE CASCADE, project_id text NOT NULL,
 scope_json text NOT NULL, request_id varchar(128) NOT NULL, fingerprint varchar(64) NOT NULL,
 state varchar(16) NOT NULL, grant_json text, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL
);`;
const CLAIM = `INSERT INTO assistant_usage_reservation(request_key,reservation_id,owner_uid,project_id,scope_json,request_id,fingerprint,state,created_at,updated_at)
 SELECT $1,$2,$3,$4,$5,$6,$7,'pending',$8::timestamptz,$8::timestamptz
 WHERE EXISTS(SELECT 1 FROM app_user WHERE uid=$3 AND status='ACTIVE')
 ON CONFLICT(request_key) DO NOTHING RETURNING to_jsonb(assistant_usage_reservation)::text AS record_json`;
const READ = `SELECT to_jsonb(r)::text AS record_json FROM assistant_usage_reservation r
 WHERE request_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND request_id=$5
 AND EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')`;
const GRANT = `UPDATE assistant_usage_reservation SET state='reserved',grant_json=$4,updated_at=$5::timestamptz
 WHERE request_key=$1 AND reservation_id=$2 AND project_id=$3 AND state='pending'
 AND EXISTS(SELECT 1 FROM app_user WHERE uid=owner_uid AND status='ACTIVE')
 RETURNING to_jsonb(assistant_usage_reservation)::text AS record_json`;
const SETTLE = `UPDATE assistant_usage_reservation SET state=CASE WHEN state='completed' THEN state ELSE $3 END,
 updated_at=$4::timestamptz WHERE reservation_id=$1 AND project_id=$2 AND grant_json IS NOT NULL
 RETURNING to_jsonb(assistant_usage_reservation)::text AS record_json`;
interface Row {request_key: string; reservation_id: string; owner_uid: string; project_id: string;
  scope_json: string; request_id: string; fingerprint: string; state: string; grant_json: string | null}
function row(raw: readonly Record<string, unknown>[]): Row | undefined {
  if (raw.length > 1) return fail("usage_state_unavailable");
  if (!raw.length) return undefined;
  try {
    const value = JSON.parse(raw[0]!.record_json as string) as Row;
    if (!value || typeof value.reservation_id !== "string" || !["pending", "reserved", "completed", "uncertain"].includes(value.state)) return fail("usage_state_unavailable");
    return value;
  } catch {return fail("usage_state_unavailable");}
}
export class DurablePreparationUsageAuthority implements PreparationUsageAuthority {
  constructor(private readonly sql: AssistantSql, private readonly projectId: string,
    private readonly authorizer?: ApprovedUsageAuthorizer, private readonly now: () => Date = () => new Date(),
    private readonly reservationId: () => string = randomUUID) {}
  private grant(raw: unknown, actor: AccountProfileActor, request: PreparationRequest): ApprovedUsageGrant {
    const grant = raw as ApprovedUsageGrant;
    if (!grant || Object.keys(grant).sort().join("|") !== "authorizationId|entitlementRevision|ownerUid|projectId|requestId|scope|validUntil" ||
        grant.ownerUid !== actor.uid || grant.projectId !== actor.projectId || grant.requestId !== request.requestId ||
        canonical(grant.scope) !== canonical(request.scope) || grant.entitlementRevision !== request.expectedEntitlementRevision ||
        !Number.isFinite(Date.parse(grant.validUntil)) || new Date(grant.validUntil).toISOString() !== grant.validUntil ||
        Date.parse(grant.validUntil) <= this.now().getTime()) return fail("usage_authorization_unavailable");
    id(grant.authorizationId); return grant;
  }
  async reserve(actor: AccountProfileActor, request: PreparationRequest) {
    if (actor.projectId !== this.projectId || !actor.uid || actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
    if (!this.authorizer) return fail("usage_authorization_unavailable");
    const key = preparationKey({ownerUid: actor.uid, projectId: actor.projectId, scope: request.scope, requestId: request.requestId});
    const fingerprint = digest(request), scope = canonical(request.scope), reservation = this.reservationId();
    const inserted = row(await this.sql.execute(CLAIM, [key, reservation, actor.uid, actor.projectId, scope,
      request.requestId, fingerprint, this.now().toISOString()], true));
    let current = inserted ?? row(await this.sql.execute(READ, [key, actor.uid, actor.projectId, scope, request.requestId], false));
    if (!current || current.request_key !== key || current.owner_uid !== actor.uid || current.project_id !== actor.projectId ||
        current.scope_json !== scope || current.request_id !== request.requestId || current.fingerprint !== fingerprint) return fail("usage_identity_conflict", 409);
    if (current.state === "completed" || current.state === "uncertain") return fail("usage_original_outcome_required", 409);
    if (current.state === "pending") {
      // Only the inserting caller can initiate authorization. Recovery is status-only.
      const granted = inserted
        ? await this.authorizer.authorize(actor, request, current.reservation_id)
        : await this.authorizer.status(actor, request, current.reservation_id);
      const value = this.grant(granted, actor, request);
      const saved = row(await this.sql.execute(GRANT, [key, current.reservation_id, this.projectId,
        canonical(value), this.now().toISOString()], true));
      current = saved ?? row(await this.sql.execute(READ, [key, actor.uid, actor.projectId, scope, request.requestId], false));
    }
    if (!current || current.state !== "reserved" || current.project_id !== this.projectId) return fail("usage_state_unavailable");
    let value: unknown;
    try {value = JSON.parse(current.grant_json!);} catch {return fail("usage_state_unavailable");}
    const grant = this.grant(value, actor, request);
    return {id: current.reservation_id, validUntil: grant.validUntil};
  }
  async settle(reservationId: string, outcome: "completed" | "uncertain") {
    id(reservationId);
    if (!["completed", "uncertain"].includes(outcome)) return fail("invalid_request", 400);
    const result = row(await this.sql.execute(SETTLE, [reservationId, this.projectId, outcome, this.now().toISOString()], true));
    if (!result || result.reservation_id !== reservationId || result.project_id !== this.projectId) return fail("usage_state_unavailable");
  }
}
