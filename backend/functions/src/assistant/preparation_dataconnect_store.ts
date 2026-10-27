import {randomUUID} from "node:crypto";
import type {DataConnect} from "firebase-admin/data-connect";
import {canonical, digest, fail} from "./model_contract.js";
import type {PreparationRequestIdentity, PreparationRequestStore, PreparationState} from "./model_service.js";

/** SQL/SDK boundary only. Every caller supplies constant SQL and bound values. */
export interface AssistantSql {
  execute(sql: string, values: readonly string[], write: boolean): Promise<readonly Record<string, unknown>[]>;
}
export class DataConnectAssistantSql implements AssistantSql {
  constructor(private readonly transport: Pick<DataConnect, "executeGraphql" | "executeGraphqlRead">) {}
  async execute(sql: string, values: readonly string[], write: boolean) {
    const declarations = values.map((_, i) => `$p${i}:String!`).join(",");
    const parameters = values.map((_, i) => `$p${i}`).join(",");
    const variables = Object.fromEntries(values.map((value, i) => [`p${i}`, value]));
    // One returning row per atomic statement. Read statements return one row at most.
    const query = `${write ? "mutation" : "query"} AssistantDurable(${declarations}) {
      row:${write ? "_executeReturningFirst" : "_executeQuery"}(sql:"""${sql}""",params:[${parameters}])
    }`;
    const result = write
      ? await this.transport.executeGraphql<{row: Record<string, unknown> | null}, Record<string, string>>(query, {variables})
      : await this.transport.executeGraphqlRead<{row: readonly Record<string, unknown>[]}, Record<string, string>>(query, {variables});
    const row = result.data.row;
    if (write) return row == null ? [] : [row as Record<string, unknown>];
    if (!Array.isArray(row)) return fail("request_state_unavailable");
    return row;
  }
}

/** Kept separately from deployment: local SQL qualification uses these exact statements. */
export const ASSISTANT_REQUEST_DDL = `CREATE TABLE IF NOT EXISTS assistant_preparation_request (
 request_key varchar(64) PRIMARY KEY, owner_uid text NOT NULL REFERENCES app_user(uid) ON DELETE CASCADE,
 project_id text NOT NULL, scope_json text NOT NULL, request_id varchar(128) NOT NULL,
 fingerprint varchar(64), lease varchar(128) NOT NULL, state varchar(16) NOT NULL,
 dispatched boolean NOT NULL DEFAULT false, valid_until timestamptz NOT NULL,
 result_json text, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL
);`;
export const ASSISTANT_REQUEST_CLAIM_SQL = `
 INSERT INTO assistant_preparation_request(request_key,owner_uid,project_id,scope_json,request_id,fingerprint,lease,state,valid_until,created_at,updated_at)
 SELECT $1,$2,$3,$4,$5,$6,$7,'pending',$9::timestamptz,$8::timestamptz,$8::timestamptz
 WHERE EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')
 ON CONFLICT(request_key) DO NOTHING RETURNING to_jsonb(assistant_preparation_request)::text AS record_json`;
export const ASSISTANT_REQUEST_CANCEL_SQL = `
 INSERT INTO assistant_preparation_request(request_key,owner_uid,project_id,scope_json,request_id,fingerprint,lease,state,valid_until,created_at,updated_at)
 SELECT $1,$2,$3,$4,$5,NULL,$6,'cancelled',$7::timestamptz,$7::timestamptz,$7::timestamptz
 WHERE EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')
 ON CONFLICT(request_key) DO UPDATE SET state='cancelled',result_json=NULL,updated_at=$7::timestamptz
 WHERE assistant_preparation_request.owner_uid=$2 AND assistant_preparation_request.project_id=$3
 AND assistant_preparation_request.scope_json=$4 AND assistant_preparation_request.request_id=$5
 RETURNING to_jsonb(assistant_preparation_request)::text AS record_json`;
const READ = `SELECT to_jsonb(r)::text AS record_json FROM assistant_preparation_request r
 WHERE request_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND request_id=$5
 AND EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')`;
const EXPIRE = `UPDATE assistant_preparation_request SET state='uncertain',result_json=NULL,updated_at=$6::timestamptz
 WHERE request_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND request_id=$5
 AND state='pending' AND valid_until<=$6::timestamptz RETURNING to_jsonb(assistant_preparation_request)::text AS record_json`;
const DISPATCH = `UPDATE assistant_preparation_request SET dispatched=true,updated_at=$7::timestamptz
 WHERE request_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND request_id=$5
 AND lease=$6 AND state='pending' AND dispatched=false AND valid_until>$7::timestamptz
 AND EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')
 RETURNING to_jsonb(assistant_preparation_request)::text AS record_json`;
const FINISH = `UPDATE assistant_preparation_request SET
 state=CASE WHEN valid_until<=$9::timestamptz THEN 'uncertain' ELSE $7 END,
 result_json=CASE WHEN valid_until<=$9::timestamptz THEN NULL ELSE $8 END,updated_at=$9::timestamptz
 WHERE request_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND request_id=$5
 AND lease=$6 AND state='pending' AND EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')
 RETURNING to_jsonb(assistant_preparation_request)::text AS record_json`;

interface Row {request_key: string; owner_uid: string; project_id: string; scope_json: string; request_id: string;
 fingerprint: string | null; lease: string; state: string; dispatched: boolean; valid_until: string; result_json: string | null}
export function preparationKey(identity: PreparationRequestIdentity): string {
  return digest({actor: {uid: identity.ownerUid, projectId: identity.projectId}, scope: identity.scope, requestId: identity.requestId});
}
export class DataConnectPreparationRequestStore implements PreparationRequestStore {
  constructor(readonly sql: AssistantSql, readonly projectId: string,
    private readonly now: () => Date = () => new Date(), private readonly leaseId: () => string = randomUUID) {}
  private values(key: string, identity?: PreparationRequestIdentity): string[] {
    if (!identity || identity.projectId !== this.projectId || !identity.ownerUid || preparationKey(identity) !== key) return fail("account_scope_mismatch", 403);
    return [key, identity.ownerUid, identity.projectId, canonical(identity.scope), identity.requestId];
  }
  private decode(raw: readonly Record<string, unknown>[], values: readonly string[]): Row | undefined {
    if (raw.length > 1) return fail("request_state_unavailable");
    if (!raw.length) return undefined;
    let value: unknown;
    try {value = JSON.parse(raw[0]!.record_json as string);} catch {return fail("request_state_unavailable");}
    const row = value as Row;
    if (!row || row.request_key !== values[0] || row.owner_uid !== values[1] || row.project_id !== values[2] ||
        row.scope_json !== values[3] || row.request_id !== values[4] || typeof row.lease !== "string" ||
        typeof row.dispatched !== "boolean" || !Number.isFinite(Date.parse(row.valid_until)) ||
        !["pending", "uncertain", "cancelled", "failed", "ready"].includes(row.state)) return fail("request_state_unavailable");
    return row;
  }
  private state(row: Row): PreparationState {
    if (row.state !== "ready") return {state: row.state as "pending" | "uncertain" | "cancelled" | "failed"};
    let result: PreparationState;
    try {result = JSON.parse(row.result_json!) as PreparationState;} catch {return fail("request_state_unavailable");}
    if (result?.state !== "ready" || result.reply.requestId !== row.request_id ||
        canonical(result.reply.scope) !== row.scope_json) return fail("request_state_unavailable");
    return result;
  }
  async claim(key: string, fingerprint: string, identity?: PreparationRequestIdentity) {
    const values = this.values(key, identity), lease = this.leaseId(), at = this.now();
    if (!/^[a-f0-9]{64}$/u.test(fingerprint)) return fail("invalid_request", 400);
    const inserted = this.decode(await this.sql.execute(ASSISTANT_REQUEST_CLAIM_SQL,
      [...values, fingerprint, lease, at.toISOString(), new Date(at.getTime() + 120_000).toISOString()], true), values);
    if (inserted) return {state: "claimed" as const, lease};
    const row = await this.load(values);
    if (!row) return fail("request_state_unavailable");
    if (row.state === "cancelled") return {state: "cancelled" as const};
    if (row.fingerprint !== fingerprint) return {state: "conflict" as const};
    return this.state(row);
  }
  private async load(values: string[]) {
    await this.sql.execute(EXPIRE, [...values, this.now().toISOString()], true);
    return this.decode(await this.sql.execute(READ, values, false), values);
  }
  async read(key: string, identity?: PreparationRequestIdentity) {
    const row = await this.load(this.values(key, identity)); return row ? this.state(row) : undefined;
  }
  async markDispatched(key: string, lease: string, identity?: PreparationRequestIdentity) {
    const values = this.values(key, identity);
    const row = this.decode(await this.sql.execute(DISPATCH, [...values, lease, this.now().toISOString()], true), values);
    if (!row) return fail("request_state_unavailable");
  }
  async finish(key: string, lease: string, result: PreparationState, identity?: PreparationRequestIdentity) {
    const values = this.values(key, identity);
    if (!["ready", "failed", "cancelled", "uncertain"].includes(result.state)) return fail("invalid_request", 400);
    const row = this.decode(await this.sql.execute(FINISH,
      [...values, lease, result.state, canonical(result), this.now().toISOString()], true), values) ?? await this.load(values);
    if (!row || row.lease !== lease && row.state !== "cancelled") return fail("request_state_unavailable");
    return this.state(row);
  }
  async cancel(key: string, identity?: PreparationRequestIdentity) {
    const values = this.values(key, identity);
    const row = this.decode(await this.sql.execute(ASSISTANT_REQUEST_CANCEL_SQL,
      [...values, this.leaseId(), this.now().toISOString()], true), values);
    if (!row) return fail("request_state_unavailable");
    return this.state(row);
  }
}
