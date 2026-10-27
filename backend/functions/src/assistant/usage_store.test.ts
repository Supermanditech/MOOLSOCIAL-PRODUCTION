import test, {before, beforeEach, after} from "node:test";
import assert from "node:assert/strict";
import {createRequire} from "node:module";
import {randomUUID} from "node:crypto";
import path from "node:path";
import {ASSISTANT_USAGE_DDL, DurablePreparationUsageAuthority, type ApprovedUsageGrant, type ApprovedUsageAuthorizer} from "./usage_store.js";
import type {AssistantSql} from "./preparation_dataconnect_store.js";
import type {PreparationRequest} from "./model_contract.js";

interface Pg {exec(sql: string): Promise<unknown>; query(sql: string, values?: unknown[]): Promise<{rows: Record<string, unknown>[]}>; close(): Promise<void>}
const packagePath = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_PACKAGE, dataRoot = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_DATA;
const local = {skip: !packagePath || !dataRoot};
const actor = {uid: "host-a", projectId: "host-project"};
const request: PreparationRequest = {scope: {audience: "personal", storeId: null}, requestId: "host-request", requestRevision: 1,
  message: "Host fixture request", language: "English", history: [], expectedEntitlementRevision: "personal:null:1:1", actionId: "AI-ACT-197", entityId: null};
const now = new Date("2026-10-27T08:00:00.000Z");
let db: Pg, directory: string, sqlCalls = 0, authorizations = 0, statusReads = 0, loseAuthorizationReply = false;
const grants = new Map<string, ApprovedUsageGrant>();
const sql: AssistantSql = {async execute(statement, values) {sqlCalls++; return (await db.query(statement, [...values])).rows;}};
const authorizer: ApprovedUsageAuthorizer = {
  async authorize(owner, input, reservationId) {
    authorizations++;
    const grant: ApprovedUsageGrant = {authorizationId: "host-approved-authorization", ownerUid: owner.uid,
      projectId: owner.projectId, scope: input.scope, requestId: input.requestId, entitlementRevision: input.expectedEntitlementRevision,
      validUntil: "2026-10-27T08:01:00.000Z"};
    grants.set(reservationId, grant);
    if (loseAuthorizationReply) throw Error("Host-only lost authorization response");
    return grant;
  },
  async status(_owner, _input, reservationId) {statusReads++; return grants.get(reservationId);},
};
const store = (approved: ApprovedUsageAuthorizer | undefined = authorizer) =>
  new DurablePreparationUsageAuthority(sql, actor.projectId, approved, () => now);
const open = async (): Promise<Pg> => (createRequire(__filename)(packagePath!) as {PGlite: {create(options: {dataDir: string}): Promise<Pg>}}).PGlite.create({dataDir: directory});
before(async () => {
  if (local.skip) return;
  directory = path.join(dataRoot!, `usage-${randomUUID()}`); db = await open();
  await db.exec("CREATE TABLE app_user(uid text PRIMARY KEY,status text NOT NULL)"); await db.exec(ASSISTANT_USAGE_DDL);
});
beforeEach(async () => {
  sqlCalls = authorizations = statusReads = 0; grants.clear(); loseAuthorizationReply = false;
  if (!local.skip) await db.exec("TRUNCATE assistant_usage_reservation,app_user CASCADE; INSERT INTO app_user VALUES('host-a','ACTIVE')");
});
after(async () => {if (db) await db.close();});

test("B07 missing approved usage authority never invents an allowance", async () => {
  await assert.rejects(new DurablePreparationUsageAuthority(sql, actor.projectId).reserve(actor, request));
  assert.equal(sqlCalls, 0); assert.equal(authorizations, 0);
});
test("B07 actual usage SQL repeat reservation uses one original authorization", local, async () => {
  const first = await store().reserve(actor, request), repeated = await store().reserve(actor, request);
  assert.deepEqual(first, repeated); assert.equal(authorizations, 1); assert.equal(statusReads, 0);
});
test("B07 actual usage SQL uncertain authorization recovers only by original status", local, async () => {
  loseAuthorizationReply = true;
  await assert.rejects(store().reserve(actor, request));
  const permit = await store().reserve(actor, request);
  assert.ok(permit.id); assert.equal(authorizations, 1); assert.equal(statusReads, 1);
});
test("B07 actual usage SQL settlement is idempotent and cannot downgrade completion", local, async () => {
  const permit = await store().reserve(actor, request);
  await store().settle(permit.id, "completed"); await store().settle(permit.id, "completed"); await store().settle(permit.id, "uncertain");
  assert.equal((await db.query("SELECT state FROM assistant_usage_reservation")).rows[0]!.state, "completed");
  await assert.rejects(store().reserve(actor, request)); assert.equal(authorizations, 1);
});
test("B07 actual usage SQL original reservation persists across disk reopen", local, async () => {
  const first = await store().reserve(actor, request);
  await db.close(); db = await open();
  assert.deepEqual(await store().reserve(actor, request), first); assert.equal(authorizations, 1);
});
test("B07 actual usage SQL same request identity with changed payload or entitlement conflicts", local, async () => {
  await store().reserve(actor, request);
  for (const changed of [{...request, message: "Different final request"}, {...request, expectedEntitlementRevision: "personal:null:1:2"}]) {
    await assert.rejects(store().reserve(actor, changed));
  }
  assert.equal(authorizations, 1);
});
test("B07 actual usage SQL foreign authorization cannot reserve model spending", local, async () => {
  await assert.rejects(store({...authorizer, async authorize(...args) {return {...await authorizer.authorize(...args), ownerUid: "host-b"};}}).reserve(actor, request));
  assert.equal((await db.query("SELECT state FROM assistant_usage_reservation")).rows[0]!.state, "pending");
});
