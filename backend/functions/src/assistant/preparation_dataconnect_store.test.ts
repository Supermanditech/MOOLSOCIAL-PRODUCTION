import test, {before, after, beforeEach} from "node:test";
import assert from "node:assert/strict";
import {createRequire} from "node:module";
import {randomUUID} from "node:crypto";
import path from "node:path";
import {ASSISTANT_REQUEST_DDL, DataConnectPreparationRequestStore, preparationKey, type AssistantSql} from "./preparation_dataconnect_store.js";
import type {PreparationRequestIdentity, PreparationState} from "./model_service.js";
import {digest} from "./model_contract.js";

interface Pg {exec(sql: string): Promise<unknown>; query(sql: string, params?: unknown[]): Promise<{rows: Record<string, unknown>[]}>; close(): Promise<void>}
const packagePath = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_PACKAGE;
const dataRoot = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_DATA;
const qualified = !!packagePath && !!dataRoot;
const identity: PreparationRequestIdentity = {ownerUid: "host-a", projectId: "host-project", scope: {audience: "personal", storeId: null}, requestId: "request-one"};
const key = preparationKey(identity), fingerprint = digest({hostOnly: "one"});
let db: Pg, sqlCalls = 0, directory: string;
let now = new Date("2026-10-27T08:00:00.000Z");
const sql: AssistantSql = {async execute(statement, values) {sqlCalls++; return (await db.query(statement, [...values])).rows;}};
const store = () => new DataConnectPreparationRequestStore(sql, identity.projectId, () => now);
const open = async (directory: string): Promise<Pg> => {
  const module = createRequire(__filename)(packagePath!) as {PGlite: {create(options: {dataDir: string}): Promise<Pg>}};
  return module.PGlite.create({dataDir: directory});
};
before(async () => {
  if (!qualified) return;
  directory = path.join(dataRoot!, `requests-${randomUUID()}`);
  db = await open(directory);
  await db.exec("CREATE TABLE app_user(uid text PRIMARY KEY,status text NOT NULL)");
  await db.exec(ASSISTANT_REQUEST_DDL);
});
beforeEach(async () => {
  if (!qualified) return;
  await db.exec("TRUNCATE assistant_preparation_request,app_user CASCADE; INSERT INTO app_user VALUES('host-a','ACTIVE'),('host-b','ACTIVE')");
  now = new Date("2026-10-27T08:00:00.000Z"); sqlCalls = 0;
});
after(async () => {if (db) await db.close();});
const local = {skip: !qualified};

test("B07 durable store requires explicit original owner identity before SQL", async () => {
  await assert.rejects(store().read(key));
  await assert.rejects(store().claim(key, fingerprint, {...identity, ownerUid: "host-b"}));
  assert.equal(sqlCalls, 0);
});
test("B07 actual SQL concurrent identical claims admit one lease", local, async () => {
  const values = await Promise.all(Array.from({length: 12}, () => store().claim(key, fingerprint, identity)));
  assert.equal(values.filter(row => row.state === "claimed").length, 1);
  assert.equal(values.filter(row => row.state === "pending").length, 11);
  assert.deepEqual(await store().claim(key, digest({hostOnly: "different"}), identity), {state: "conflict"});
});
test("B07 actual SQL dispatch barrier is one-shot, including recreated service", local, async () => {
  const claimed = await store().claim(key, fingerprint, identity); assert.equal(claimed.state, "claimed");
  if (claimed.state !== "claimed") throw Error("No lease");
  await store().markDispatched(key, claimed.lease, identity);
  await assert.rejects(store().markDispatched(key, claimed.lease, identity));
  assert.deepEqual(await store().claim(key, fingerprint, identity), {state: "pending"});
});
test("B07 actual SQL cancellation before any claim leaves a durable tombstone", local, async () => {
  assert.deepEqual(await store().cancel(key, identity), {state: "cancelled"});
  assert.deepEqual(await store().claim(key, fingerprint, identity), {state: "cancelled"});
});
test("B07 actual SQL late result cannot overwrite cancellation", local, async () => {
  const claimed = await store().claim(key, fingerprint, identity);
  if (claimed.state !== "claimed") throw Error("No lease");
  await store().markDispatched(key, claimed.lease, identity);
  await store().cancel(key, identity);
  assert.deepEqual(await store().finish(key, claimed.lease, {state: "failed"}, identity), {state: "cancelled"});
});
test("B07 actual SQL lost worker expires to uncertain and never admits another dispatch", local, async () => {
  const claimed = await store().claim(key, fingerprint, identity);
  if (claimed.state !== "claimed") throw Error("No lease");
  await store().markDispatched(key, claimed.lease, identity);
  await db.close(); db = await open(directory); // independent durable backend storage reopening
  now = new Date(now.getTime() + 120001);
  assert.deepEqual(await store().read(key, identity), {state: "uncertain"});
  assert.deepEqual(await store().claim(key, fingerprint, identity), {state: "uncertain"});
  await assert.rejects(store().markDispatched(key, claimed.lease, identity));
});
test("B07 actual SQL original ready result survives disk database close and reopen", local, async () => {
  const claimed = await store().claim(key, fingerprint, identity);
  if (claimed.state !== "claimed") throw Error("No lease");
  const ready: PreparationState = {state: "ready", reply: {requestId: identity.requestId, requestRevision: 1,
    scope: identity.scope, entitlementRevision: "personal:null:1:1", checkedAt: now.toISOString(),
    validUntil: new Date(now.getTime() + 60000).toISOString(), outcome: {kind: "clarification", text: "Host fixture question"}}};
  await store().finish(key, claimed.lease, ready, identity);
  await db.close();
  db = await open(directory);
  assert.deepEqual(await store().read(key, identity), ready);
});
test("B07 actual SQL separates owners, personal and each Store", local, async () => {
  await store().claim(key, fingerprint, identity);
  for (const candidate of [{...identity, ownerUid: "host-b"}, {...identity, scope: {audience: "workspace" as const, storeId: "host-store-a"}},
    {...identity, scope: {audience: "workspace" as const, storeId: "host-store-b"}}]) {
    assert.equal(await store().read(preparationKey(candidate), candidate), undefined);
    assert.equal((await store().claim(preparationKey(candidate), fingerprint, candidate)).state, "claimed");
  }
});
test("B07 actual SQL restricted/deleted account cannot disclose a retained result", local, async () => {
  await store().claim(key, fingerprint, identity);
  await db.query("UPDATE app_user SET status='RESTRICTED' WHERE uid=$1", [identity.ownerUid]);
  assert.equal(await store().read(key, identity), undefined);
  await assert.rejects(store().claim(key, fingerprint, identity));
  await db.query("DELETE FROM app_user WHERE uid=$1", [identity.ownerUid]);
  assert.equal((await db.query("SELECT * FROM assistant_preparation_request")).rows.length, 0);
});
