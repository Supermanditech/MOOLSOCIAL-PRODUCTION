import type {AssistantSql} from "./preparation_dataconnect_store.js";
import {canonical, digest, fail, object} from "./model_contract.js";
import {decodeHistorySnapshot, historyConversationKey, historyRequestKey, type HistoryIdentity,
  type HistoryReceipt, type HistorySave, type HistorySnapshot, type HistorySummary} from "./history_contract.js";

export interface HistoryRepository {
  claim(i: HistoryIdentity, save: HistorySave, now: string, accessRevision: string): Promise<HistoryReceipt>;
  commit(i: HistoryIdentity, save: HistorySave, snapshot: HistorySnapshot): Promise<HistoryReceipt>;
  status(i: HistoryIdentity, requestId: string): Promise<HistoryReceipt | undefined>;
  read(i: HistoryIdentity, id: string): Promise<HistorySnapshot | undefined>;
  list(i: HistoryIdentity, upper: string, afterAt: string, afterId: string): Promise<readonly HistorySummary[]>;
}
export const HISTORY_DDL = [
  "CREATE TABLE IF NOT EXISTS assistant_conversation (",
  " conversation_key varchar(64) PRIMARY KEY, owner_uid text NOT NULL REFERENCES app_user(uid) ON DELETE CASCADE,",
  " project_id text NOT NULL, scope_json text NOT NULL, conversation_id varchar(128) NOT NULL,",
  " revision integer NOT NULL, title text NOT NULL, snapshot_json text NOT NULL,",
  " created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL);",
  "CREATE TABLE IF NOT EXISTS assistant_conversation_save (",
  " request_key varchar(64) PRIMARY KEY, owner_uid text NOT NULL REFERENCES app_user(uid) ON DELETE CASCADE,",
  " project_id text NOT NULL, scope_json text NOT NULL, request_id varchar(128) NOT NULL,",
  " fingerprint varchar(64) NOT NULL, access_revision text NOT NULL, state varchar(16) NOT NULL, outcome_json text, created_at timestamptz NOT NULL);",
].join("\n");
const CLAIM = [
  "WITH owner AS MATERIALIZED (SELECT uid FROM app_user WHERE uid=$2 AND status='ACTIVE' FOR SHARE)",
  "INSERT INTO assistant_conversation_save(request_key,owner_uid,project_id,scope_json,request_id,fingerprint,state,created_at,access_revision)",
  "SELECT $1,$2,$3,$4,$5,$6,'pending',$7::timestamptz,$8 FROM owner",
  "ON CONFLICT(request_key) DO NOTHING RETURNING to_jsonb(assistant_conversation_save)::text AS record_json",
].join("\n");
const RECEIPT = [
  "SELECT to_jsonb(r)::text AS record_json FROM assistant_conversation_save r",
  "WHERE request_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND request_id=$5",
  "AND EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')",
].join("\n");
// The original request row is inserted in a separate durable statement. Locking
// that existing row lets PostgreSQL recheck a competing worker's current state.
// Conversation mutation and the immutable outcome receipt commit atomically.
export const HISTORY_COMMIT_SQL = [
  "WITH owner AS MATERIALIZED (SELECT uid FROM app_user WHERE uid=$2 AND status='ACTIVE' FOR SHARE),",
  "locked AS MATERIALIZED (SELECT request_key FROM assistant_conversation_save",
  " WHERE request_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND fingerprint=$7 AND state='pending'",
  " AND EXISTS(SELECT 1 FROM owner) FOR UPDATE),",
  "created AS (INSERT INTO assistant_conversation(conversation_key,owner_uid,project_id,scope_json,conversation_id,revision,title,snapshot_json,created_at,updated_at)",
  " SELECT $5,$2,$3,$4,$6,1,($8::jsonb->>'title'),$8,$9::timestamptz,$9::timestamptz FROM locked WHERE $10::int=0",
  " ON CONFLICT(conversation_key) DO NOTHING RETURNING snapshot_json),",
  "changed AS (UPDATE assistant_conversation SET revision=revision+1,title=($8::jsonb->>'title'),snapshot_json=$8,updated_at=$9::timestamptz",
  " WHERE conversation_key=$5 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND conversation_id=$6",
  " AND revision=$10::int AND $10::int>0 AND EXISTS(SELECT 1 FROM locked) RETURNING snapshot_json),",
  "applied AS (SELECT snapshot_json FROM created UNION ALL SELECT snapshot_json FROM changed)",
  "UPDATE assistant_conversation_save SET state='confirmed',outcome_json=",
  " CASE WHEN EXISTS(SELECT 1 FROM applied) THEN (SELECT jsonb_build_object('state','confirmed','conversation',snapshot_json::jsonb)::text FROM applied)",
  " ELSE jsonb_build_object('state','conflict')::text END",
  " WHERE request_key=$1 AND EXISTS(SELECT 1 FROM locked)",
  " RETURNING to_jsonb(assistant_conversation_save)::text AS record_json",
].join("\n");
const READ = [
  "SELECT to_jsonb(r)::text AS record_json FROM assistant_conversation r",
  "WHERE conversation_key=$1 AND owner_uid=$2 AND project_id=$3 AND scope_json=$4 AND conversation_id=$5",
  "AND EXISTS(SELECT 1 FROM app_user WHERE uid=$2 AND status='ACTIVE')",
].join("\n");
const LIST = [
  "SELECT jsonb_build_object('conversation_key',conversation_key,'owner_uid',owner_uid,'project_id',project_id,",
  " 'scope_json',scope_json,'conversation_id',conversation_id,'revision',revision,'title',title,'updated_at',updated_at)::text AS record_json FROM assistant_conversation r",
  "WHERE owner_uid=$1 AND project_id=$2 AND scope_json=$3 AND updated_at <= $4::timestamptz",
  "AND ($5='' OR (updated_at,conversation_id) < (NULLIF($5,'')::timestamptz,$6))",
  "AND EXISTS(SELECT 1 FROM app_user WHERE uid=$1 AND status='ACTIVE')",
  "ORDER BY updated_at DESC,conversation_id DESC LIMIT 21",
].join("\n");
function decode(raw: readonly Record<string, unknown>[], i: HistoryIdentity): Record<string, unknown> | undefined {
  if (raw.length > 1) return fail("history_unavailable");
  if (!raw.length) return undefined;
  let r: Record<string, unknown>;
  try {r = object(JSON.parse(raw[0]!.record_json as string));} catch {return fail("history_unavailable");}
  if (r.owner_uid !== i.actor.uid || r.project_id !== i.actor.projectId || r.scope_json !== canonical(i.scope)) return fail("history_unavailable");
  return r;
}
function outcome(r: Record<string, unknown>): HistoryReceipt {
  if (r.state === "pending" && r.outcome_json === null) return {state: "pending"};
  if (r.state !== "confirmed" || typeof r.outcome_json !== "string") return fail("history_unavailable");
  const value = object(JSON.parse(r.outcome_json));
  if (value.state === "conflict" && Object.keys(value).length === 1) return {state: "conflict"};
  if (value.state !== "confirmed" || Object.keys(value).sort().join("|") !== "conversation|state") return fail("history_unavailable");
  return {state: "confirmed", conversation: decodeHistorySnapshot(value.conversation)};
}
export class DataConnectHistoryRepository implements HistoryRepository {
  constructor(private readonly sql: AssistantSql, private readonly projectId: string) {}
  private check(i: HistoryIdentity) {
    if (!i.actor.uid || i.actor.projectId !== this.projectId || i.actor.tenantId !== undefined) return fail("account_scope_mismatch", 403);
  }
  private async receipt(i: HistoryIdentity, requestId: string) {
    this.check(i);
    const key = historyRequestKey(i, requestId);
    const r = decode(await this.sql.execute(RECEIPT, [key, i.actor.uid, this.projectId, canonical(i.scope), requestId], false), i);
    if (r && (r.request_key !== key || r.request_id !== requestId)) return fail("history_unavailable");
    return r;
  }
  async claim(i: HistoryIdentity, s: HistorySave, now: string, accessRevision: string) {
    this.check(i);
    const fp = digest(s), key = historyRequestKey(i, s.requestId);
    const r = decode(await this.sql.execute(CLAIM, [key, i.actor.uid, this.projectId, canonical(i.scope), s.requestId, fp, now, accessRevision], true), i)
      ?? await this.receipt(i, s.requestId) ?? fail("history_unavailable");
    if (r.request_key !== key || r.request_id !== s.requestId || r.fingerprint !== fp) return fail("history_request_conflict", 409);
    return outcome(r);
  }
  async status(i: HistoryIdentity, requestId: string) {
    const r = await this.receipt(i, requestId);
    return r ? outcome(r) : undefined;
  }
  async commit(i: HistoryIdentity, s: HistorySave, snapshot: HistorySnapshot) {
    this.check(i);
    const key = historyRequestKey(i, s.requestId);
    const r = decode(await this.sql.execute(HISTORY_COMMIT_SQL, [key, i.actor.uid, this.projectId, canonical(i.scope),
      historyConversationKey(i, snapshot.id), snapshot.id, digest(s), canonical(snapshot), snapshot.updatedAt, String(s.expectedRevision)], true), i)
      ?? await this.receipt(i, s.requestId) ?? fail("history_unavailable");
    if (r.request_key !== key || r.fingerprint !== digest(s)) return fail("history_request_conflict", 409);
    return outcome(r);
  }
  private snapshot(r: Record<string, unknown>, i: HistoryIdentity) {
    const snapshot = decodeHistorySnapshot(JSON.parse(r.snapshot_json as string));
    if (snapshot.id !== r.conversation_id || snapshot.revision !== r.revision ||
        r.conversation_key !== historyConversationKey(i, snapshot.id) || r.title !== snapshot.title ||
        new Date(r.updated_at as string).toISOString() !== snapshot.updatedAt) return fail("history_unavailable");
    return snapshot;
  }
  async read(i: HistoryIdentity, id: string) {
    this.check(i);
    const r = decode(await this.sql.execute(READ, [historyConversationKey(i, id), i.actor.uid, this.projectId, canonical(i.scope), id], false), i);
    return r ? this.snapshot(r, i) : undefined;
  }
  async list(i: HistoryIdentity, upper: string, afterAt: string, afterId: string) {
    this.check(i);
    const rows = await this.sql.execute(LIST, [i.actor.uid, this.projectId, canonical(i.scope), upper, afterAt, afterId], false);
    if (rows.length > 21) return fail("history_unavailable");
    return rows.map(row => {
      const r = decode([row], i)!;
      const snapshot = decodeHistorySnapshot({id: r.conversation_id, revision: r.revision, title: r.title,
        updatedAt: new Date(r.updated_at as string).toISOString(), draft: "", language: "Auto", messages: []});
      if (r.conversation_key !== historyConversationKey(i, snapshot.id)) return fail("history_unavailable");
      return {id: snapshot.id, revision: snapshot.revision, title: snapshot.title, updatedAt: snapshot.updatedAt};
    });
  }
}
