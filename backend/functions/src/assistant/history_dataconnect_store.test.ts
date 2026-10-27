import test, {before, beforeEach, after} from "node:test";
import assert from "node:assert/strict";
import {createRequire} from "node:module";
import {randomUUID} from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import {AssistantModelError} from "./model_contract.js";
import {HISTORY_DDL, HISTORY_COMMIT_SQL, DataConnectHistoryRepository} from "./history_dataconnect_store.js";
import {AssistantHistoryService} from "./history_service.js";
import {historyCommand, type HistoryIdentity, type HistoryReceipt, type HistorySave} from "./history_contract.js";
import type {AccountPlansService} from "../account/plans_service.js";

interface Pg {exec(sql: string): Promise<unknown>; query(sql: string, values?: unknown[]): Promise<{rows: Record<string, unknown>[]}>; close(): Promise<void>}
const pkg = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_PACKAGE, root = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_DATA;
const local = {skip: !pkg || !root};
const actor = {uid: "history-host-a", projectId: "fixture-project"}, scope = {audience: "personal" as const, storeId: null};
const identity: HistoryIdentity = {actor, scope};
let db: Pg, directory: string, at = new Date("2026-10-28T00:00:00.000Z"), paid = true, revision = 1;
let revokeOnClaim = false, eraseBeforeCommit = false;
const plans = {async read() {
  if (!paid) throw new AssistantModelError("ai_access_required", 403);
  return {activeFeatureIds: ["mool_ai"], validUntil: "2026-10-29T00:00:00.000Z",
    catalogueRevision: 1, subscriptionRevision: revision};
}} as unknown as Pick<AccountPlansService, "read">; // Explicit isolated original-authority seam.
const repository = () => new DataConnectHistoryRepository({async execute(sql, values) {
  if (eraseBeforeCommit && sql === HISTORY_COMMIT_SQL) {
    eraseBeforeCommit = false;
    await db.exec("BEGIN");
    await db.query("UPDATE app_user SET status='DELETED' WHERE uid=$1", [actor.uid]);
    await db.query("DELETE FROM assistant_conversation WHERE owner_uid=$1", [actor.uid]);
    await db.query("DELETE FROM assistant_conversation_save WHERE owner_uid=$1", [actor.uid]);
    await db.exec("COMMIT");
  }
  const rows = (await db.query(sql, [...values])).rows;
  if (revokeOnClaim && sql.includes("INSERT INTO assistant_conversation_save(")) {revokeOnClaim = false; paid = false;}
  return rows;
}}, actor.projectId);
const service = () => new AssistantHistoryService({projectId: actor.projectId, plans, repository: repository(), now: () => at});
const payload = (requestId = "original-save"): HistorySave => ({scope, requestId, clientKey: "native-editor:" + requestId,
  conversationId: null, expectedRevision: 0, draft: "ચોખા 5 કિલો", language: "Auto",
  messages: [{role: "user", text: "चावल चाहिए"}, {role: "assistant", text: "Review the quantity; no order placed."}]});
const save = (p = payload(), who = actor) => service().handle(who, {operation: "save", payload: p}) as Promise<HistoryReceipt>;
async function confirmed(p = payload()) {
  const r = await save(p); assert.equal(r.state, "confirmed");
  if (r.state !== "confirmed") throw Error("No fixture acknowledgement");
  return r.conversation;
}
const open = async (): Promise<Pg> => (createRequire(__filename)(pkg!) as {PGlite: {create(options: {dataDir: string}): Promise<Pg>}}).PGlite.create({dataDir: directory});
before(async () => {
  if (local.skip) return;
  fs.mkdirSync(root!, {recursive: true}); directory = path.join(root!, "history-" + randomUUID()); db = await open();
  await db.exec("CREATE TABLE app_user(uid text PRIMARY KEY,status text NOT NULL,display_name text,profile_data_json text,profile_receipts_json text)");
  await db.exec(HISTORY_DDL);
});
beforeEach(async () => {
  if (local.skip) return;
  await db.exec("TRUNCATE assistant_conversation_save,assistant_conversation,app_user CASCADE; INSERT INTO app_user(uid,status) VALUES('history-host-a','ACTIVE'),('history-host-b','ACTIVE')");
  at = new Date("2026-10-28T00:00:00.000Z"); paid = true; revision = 1; revokeOnClaim = false; eraseBeforeCommit = false;
});
after(async () => {if (db) await db.close();});

test("History actual SQL concurrent same original save accepts one revision and receipt", local, async () => {
  const outcomes = await Promise.all(Array.from({length: 8}, () => save()));
  assert.ok(outcomes.every(r => r.state === "confirmed"));
  assert.ok(outcomes.every(r => JSON.stringify(r) === JSON.stringify(outcomes[0])));
  assert.equal((await db.query("SELECT revision FROM assistant_conversation")).rows[0]!.revision, 1);
  assert.equal((await db.query("SELECT * FROM assistant_conversation_save")).rows.length, 1);
});
test("History same request ID cannot save a different body or conversation", local, async () => {
  await confirmed();
  await assert.rejects(save({...payload(), draft: "Different private draft"}), (e: unknown) => e instanceof AssistantModelError && e.code === "history_request_conflict");
  assert.equal((await db.query("SELECT * FROM assistant_conversation")).rows.length, 1);
});
test("History delayed initial saves from one editor cannot create two conversations", local, async () => {
  const a = payload("initial-a"), b = {...payload("initial-b"), clientKey: a.clientKey, draft: "Newer user draft"};
  const outcomes = await Promise.all([save(a), save(b)]);
  assert.equal(outcomes.filter(r => r.state === "confirmed").length, 1);
  assert.equal(outcomes.filter(r => r.state === "conflict").length, 1);
  assert.equal((await db.query("SELECT * FROM assistant_conversation")).rows.length, 1);
});
test("History original lost acknowledgement survives actual disk close/reopen without a second effect", local, async () => {
  const expected = await confirmed(); await db.close(); db = await open();
  const recovered = await service().handle(actor, {operation: "status", payload: {scope, requestId: payload().requestId}});
  assert.equal((recovered as {conversation: unknown}).conversation && JSON.stringify((recovered as {conversation: unknown}).conversation), JSON.stringify(expected));
  assert.deepEqual(await confirmed(), expected);
  assert.equal((await db.query("SELECT revision FROM assistant_conversation")).rows[0]!.revision, 1);
});
test("History pending claim restart is read-only until explicit same-payload retry", local, async () => {
  await repository().claim(identity, payload(), at.toISOString(), "isolated-authority-revision");
  await db.close(); db = await open();
  assert.deepEqual(await repository().status(identity, payload().requestId), {state: "pending"});
  assert.equal((await db.query("SELECT * FROM assistant_conversation")).rows.length, 0);
  assert.equal((await confirmed()).revision, 1);
});
test("History competing editors from one source revision cannot overwrite each other", local, async () => {
  const c = await confirmed();
  const base = {...payload(), conversationId: c.id, expectedRevision: c.revision};
  const outcomes = await Promise.all([save({...base, requestId: "edit-a", draft: "Edit A"}),
    save({...base, requestId: "edit-b", draft: "Edit B"})]);
  assert.equal(outcomes.filter(r => r.state === "confirmed").length, 1);
  assert.equal(outcomes.filter(r => r.state === "conflict").length, 1);
  assert.equal((await repository().read(identity, c.id))!.revision, 2);
});
test("History current access withdrawal after claim prevents conversation mutation", local, async () => {
  revokeOnClaim = true; await assert.rejects(save()); assert.equal((await db.query("SELECT * FROM assistant_conversation")).rows.length, 0);
  paid = true; assert.equal((await confirmed()).revision, 1);
});
test("History active database owner guard blocks a stale paid fixture after restriction", local, async () => {
  await db.query("UPDATE app_user SET status='RESTRICTED' WHERE uid=$1", [actor.uid]);
  await assert.rejects(save()); assert.equal((await db.query("SELECT * FROM assistant_conversation_save")).rows.length, 0);
});
test("History account and each Store have separate read/status namespaces", local, async () => {
  const c = await confirmed();
  for (const i of [{actor: {...actor, uid: "history-host-b"}, scope},
    ...["store-a", "store-b"].map(storeId => ({actor, scope: {audience: "workspace" as const, storeId}}))]) {
    assert.equal(await repository().read(i, c.id), undefined);
    assert.equal(await repository().status(i, payload().requestId), undefined);
    assert.equal((await repository().list(i, at.toISOString(), "", "")).length, 0);
  }
});
test("History tied timestamps page deterministically and expose summaries only", local, async () => {
  for (let n = 0; n < 45; n++) await confirmed({...payload("page-" + n), draft: "Private message " + n});
  const seen = new Set<string>(); let cursor: string | null = null; const sizes: number[] = [];
  do {
    const page = await service().handle(actor, {operation: "list", payload: {scope, cursor}}) as {items: {id: string}[]; nextCursor: string | null};
    sizes.push(page.items.length); for (const item of page.items) {assert.ok(!seen.has(item.id)); seen.add(item.id); assert.deepEqual(Object.keys(item).sort(), ["id", "revision", "title", "updatedAt"]);}
    cursor = page.nextCursor;
  } while (cursor !== null);
  assert.deepEqual(sizes, [20, 20, 5]); assert.equal(seen.size, 45);
});
test("History source and cursor changes cannot disclose an earlier private page", local, async () => {
  for (let n = 0; n < 21; n++) await confirmed(payload("cursor-" + n));
  const page = await service().handle(actor, {operation: "list", payload: {scope, cursor: null}}) as {nextCursor: string};
  await assert.rejects(service().handle({...actor, uid: "history-host-b"}, {operation: "list", payload: {scope, cursor: page.nextCursor}}));
  revision++; await assert.rejects(service().handle(actor, {operation: "list", payload: {scope, cursor: page.nextCursor}}));
});
test("History unknown private result stays not-found and does not create a placeholder", local, async () => {
  await assert.rejects(service().handle(actor, historyCommand({operation: "read", payload: {scope, id: "missing"}})));
  await assert.rejects(service().handle(actor, historyCommand({operation: "status", payload: {scope, requestId: "missing"}})));
  assert.equal((await db.query("SELECT * FROM assistant_conversation")).rows.length, 0);
});
test("History account-erasure source includes both private tables in the existing transaction", () => {
  const sourceRoot = process.env.MOOLSOCIAL_ASSISTANT_SOURCE_ROOT;
  if (!sourceRoot) return;
  const code = fs.readFileSync(path.join(sourceRoot, "dataconnect/provider/youtube.gql"), "utf8");
  const operation = code.slice(code.indexOf("mutation EraseMoolSocialUser("));
  assert.match(operation, /^mutation EraseMoolSocialUser[^\n]+@transaction/u);
  for (const name of ["assistantConversation", "assistantConversationSave"]) assert.ok(operation.includes(name + "_deleteMany(where: {owner: {uid: {eq: $userId}}})"));
  assert.ok(operation.indexOf("appUser_update(") < operation.indexOf("assistantConversation_deleteMany("));
  assert.ok(HISTORY_COMMIT_SQL.indexOf("FOR SHARE") < HISTORY_COMMIT_SQL.indexOf("FOR UPDATE"));
});
test("History original erasure removes private rows and retains the principal/other owner", local, async () => {
  await confirmed(); await save(payload("other-save"), {...actor, uid: "history-host-b"});
  await db.exec("BEGIN");
  await db.query("UPDATE app_user SET status='DELETED',display_name=NULL,profile_data_json=NULL,profile_receipts_json=NULL WHERE uid=$1", [actor.uid]);
  await db.query("DELETE FROM assistant_conversation WHERE owner_uid=$1", [actor.uid]);
  await db.query("DELETE FROM assistant_conversation_save WHERE owner_uid=$1", [actor.uid]);
  await db.exec("COMMIT");
  assert.equal((await db.query("SELECT * FROM assistant_conversation WHERE owner_uid=$1", [actor.uid])).rows.length, 0);
  assert.equal((await db.query("SELECT * FROM assistant_conversation_save WHERE owner_uid=$1", [actor.uid])).rows.length, 0);
  assert.equal((await db.query("SELECT * FROM app_user WHERE uid=$1", [actor.uid])).rows.length, 1);
  assert.equal((await db.query("SELECT * FROM assistant_conversation WHERE owner_uid='history-host-b'")).rows.length, 1);
  await assert.rejects(save());
});
test("History actual SQL stores a valid emoji boundary title without changing original Unicode content", local, async () => {
  const text = "x".repeat(89) + "🛒";
  const value = await confirmed({...payload("emoji-source"), draft: "", messages: [{role: "user", text}]});
  assert.equal(value.messages[0]!.text, text);
  const restored = await repository().read(identity, value.id);
  assert.equal(restored!.messages[0]!.text, text); assert.equal(Buffer.from(restored!.title).toString(), restored!.title);
});
test("History erasure transaction rollback retains the original private records", local, async () => {
  await confirmed(); await db.exec("BEGIN"); await db.query("DELETE FROM assistant_conversation WHERE owner_uid=$1", [actor.uid]);
  await assert.rejects(db.query("UPDATE app_user SET status=NULL WHERE uid=$1", [actor.uid])); await db.exec("ROLLBACK");
  assert.equal((await db.query("SELECT * FROM assistant_conversation WHERE owner_uid=$1", [actor.uid])).rows.length, 1);
});
test("History an account tombstoned after claim cannot resurrect a transcript or receipt", local, async () => {
  eraseBeforeCommit = true; await assert.rejects(save());
  assert.equal((await db.query("SELECT * FROM assistant_conversation")).rows.length, 0);
  assert.equal((await db.query("SELECT * FROM assistant_conversation_save")).rows.length, 0);
  assert.equal((await db.query("SELECT status FROM app_user WHERE uid=$1", [actor.uid])).rows[0]!.status, "DELETED");
});
