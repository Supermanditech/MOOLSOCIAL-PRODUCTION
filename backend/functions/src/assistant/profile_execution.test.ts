import test, {before, beforeEach, after} from "node:test";
import assert from "node:assert/strict";
import {createRequire} from "node:module";
import {randomUUID} from "node:crypto";
import path from "node:path";
import fs from "node:fs";
import {ASSISTANT_USAGE_DDL} from "./usage_store.js";
import {AccountProfileService} from "../account/profile_service.js";
import {DataConnectAccountProfileRepository, ACCOUNT_PROFILE_COMMIT_SQL} from "../account/profile_dataconnect_store.js";
import {AccountPlansService} from "../account/plans_service.js";
import {ASSISTANT_REQUEST_DDL, DataConnectPreparationRequestStore, preparationKey, type AssistantSql} from "./preparation_dataconnect_store.js";
import {ASSISTANT_PROFILE_OPERATION_DDL, ProfilePreparationExecutionService, type ProfilePreparationConsent} from "./profile_execution.js";
import {digest} from "./model_contract.js";

interface Pg {exec(sql: string): Promise<unknown>; query(sql: string, values?: unknown[]): Promise<{rows: Record<string, unknown>[]}>; close(): Promise<void>}
const packagePath = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_PACKAGE, dataRoot = process.env.MOOLSOCIAL_ASSISTANT_SQL_TEST_DATA;
const local = {skip: !packagePath || !dataRoot};
const actor = {uid: "host-a", projectId: "host-project"}, scope = {audience: "personal" as const, storeId: null};
const now = new Date("2026-10-27T08:00:00.000Z");
let db: Pg, directory: string, writes = 0, paid = true, loseConfirmation = false;
let cancelDuringClaim=false, revokeDuringClaim=false;
const sql: AssistantSql = {async execute(statement, values) {
  if (loseConfirmation && statement.includes("UPDATE assistant_profile_operation SET confirmed_revision")) {loseConfirmation = false; throw Error("Host-only lost linkage acknowledgement");}
  const result=(await db.query(statement,[...values])).rows;
  if(statement.includes('INSERT INTO assistant_profile_operation')){
    if(cancelDuringClaim){cancelDuringClaim=false;const c=binding();const identity={ownerUid:actor.uid,projectId:actor.projectId,scope,requestId:c.preparationRequestId};await requests().cancel(preparationKey(identity),identity);}
    if(revokeDuringClaim){revokeDuringClaim=false;paid=false;}
  }
  return result;
}};
const transport = {
  async executeGraphqlRead(query: string, options: {variables: Record<string, unknown>}) {
    const v = options.variables;
    if (query.includes("ReadOwnedAccountProfile")) {
      const row = (await db.query('SELECT uid,status,display_name AS "displayName",updated_at AS "updatedAt",profile_revision AS "profileRevision",profile_data_json AS "profileDataJson" FROM app_user WHERE uid=$1', [v.uid])).rows[0];
      if (row) row.updatedAt = new Date(row.updatedAt as string).toISOString();
      return {data: {appUser: row ?? null}};
    }
    assert.ok(query.includes("ReadOriginalAccountProfileReceipt"));
    const statement = query.match(/sql:"""([\s\S]*?)"""/u)?.[1]; assert.ok(statement);
    return {data: {receipts: (await db.query(statement, [v.uid, v.requestId])).rows}};
  },
  async executeGraphql(query: string, options: {variables: Record<string, unknown>}) {
    assert.ok(query.includes(ACCOUNT_PROFILE_COMMIT_SQL)); const v = options.variables; writes++;
    return {data: {committed: (await db.query(ACCOUNT_PROFILE_COMMIT_SQL, [v.uid, v.requestId, v.expectedRevision, v.fingerprint, v.profile, v.receipt])).rows[0] ?? null}};
  },
};
const repository = new DataConnectAccountProfileRepository(transport as unknown as ConstructorParameters<typeof DataConnectAccountProfileRepository>[0]);
const profile = () => new AccountProfileService(repository, actor.projectId);
const plans = new AccountPlansService({async read(uid, selected) {return {ownerUid: uid, accountStatus: "ACTIVE",
  catalogue: {audience: selected.audience, revision: 1, state: "approved", offers: []},
  subscription: {ownerUid: uid, scope: selected, revision: 1, planId: "host-plan", planVersion: "v1", name: "Host-only paid fixture",
    state: paid ? "active" : "revoked", validFrom: "2026-10-26T00:00:00.000Z", validUntil: "2026-10-29T00:00:00.000Z", featureIds: ["mool_ai"]}};}},
  {projectId: actor.projectId, now: () => now});
const requests = () => new DataConnectPreparationRequestStore(sql, actor.projectId, () => now);
const execution = () => new ProfilePreparationExecutionService({projectId: actor.projectId, sql, requests: requests(), profile: profile(), plans, now: () => now});
const binding = (actionId = "AI-ACT-197", entityId: string | null = null): ProfilePreparationConsent => ({preparationRequestId: "host-preparation", proposalId: "host-proposal", actionId,
  entityId, sourceRevision: "profile:0", entitlementRevision: "personal:null:1:1"});
const original = (displayName = "Final native name", assistant = binding()) => ({requestId: "host-original-save", expectedRevision: 0,
  change: {kind: "name", displayName}, assistant});
async function prepare(c = binding()) {
  const identity = {ownerUid: actor.uid, projectId: actor.projectId, scope, requestId: c.preparationRequestId}, key = preparationKey(identity);
  const claim = await requests().claim(key, digest({hostOnly: true}), identity);
  if (claim.state !== "claimed") throw Error("No host preparation lease");
  await requests().finish(key, claim.lease, {state: "ready", reply: {requestId: c.preparationRequestId, requestRevision: 1, scope,
    entitlementRevision: c.entitlementRevision, checkedAt: now.toISOString(), validUntil: "2026-10-27T08:01:00.000Z",
    outcome: {kind: "proposal", id: c.proposalId, actionId: c.actionId, entityId: c.entityId, sourceRevision: c.sourceRevision,
      title: "Host native review", summary: "Explicit fixture", fields: c.actionId==="AI-ACT-197"?{displayName: "Suggested name"}:{line:"Host test road"}}}}, identity);
}
const open = async (): Promise<Pg> => (createRequire(__filename)(packagePath!) as {PGlite: {create(options: {dataDir: string}): Promise<Pg>}}).PGlite.create({dataDir: directory});
before(async () => {
  if (local.skip) return;
  directory = path.join(dataRoot!, `profile-execution-${randomUUID()}`); db = await open();
  await db.exec("CREATE TABLE app_user(uid text PRIMARY KEY,status text NOT NULL,display_name text,updated_at timestamptz NOT NULL,profile_revision integer NOT NULL DEFAULT 0,profile_data_json text,profile_receipts_json text)");
  await db.exec(ASSISTANT_REQUEST_DDL); await db.exec(ASSISTANT_PROFILE_OPERATION_DDL); await db.exec(ASSISTANT_USAGE_DDL);
});
beforeEach(async () => {
  if (local.skip) return;
  await db.exec("TRUNCATE assistant_usage_reservation,assistant_profile_operation,assistant_preparation_request,app_user CASCADE; INSERT INTO app_user(uid,status,display_name,updated_at) VALUES('host-a','ACTIVE','Original name','2026-10-27T00:00:00Z'),('host-b','ACTIVE','Other owner','2026-10-27T00:00:00Z')");
  paid = true; loseConfirmation = false; writes = 0;cancelDuringClaim=revokeDuringClaim=false;
});
after(async () => {if (db) await db.close();});

test("B04 original SQL name Save accepts edited final text once, preserving original receipt", local, async () => {
  await prepare(); assert.equal(writes, 0);
  const first = await execution().save(actor, original());
  const repeated = await execution().save(actor, original());
  assert.deepEqual(repeated, first); assert.equal(first.profile.displayName, "Final native name"); assert.equal(writes, 1);
  assert.equal((await db.query("SELECT confirmed_revision FROM assistant_profile_operation")).rows[0]!.confirmed_revision, 1);
});
test("B04 actual SQL concurrent Save taps have one original accepted effect", local, async () => {
  await prepare();
  const results = await Promise.allSettled(Array.from({length: 5}, () => execution().save(actor, original())));
  assert.ok(results.some(row => row.status === "fulfilled"));
  assert.equal((await db.query("SELECT profile_revision FROM app_user WHERE uid='host-a'")).rows[0]!.profile_revision, 1);
  assert.equal((await db.query("SELECT count(*)::integer AS n FROM app_user u, jsonb_object_keys(u.profile_receipts_json::jsonb) k WHERE uid='host-a'")).rows[0]!.n, 1);
});
test("B04 actual original receipt recovers after lost linkage response and disk reopen, without new paid action", local, async () => {
  await prepare(); loseConfirmation = true;
  await assert.rejects(execution().save(actor, original()), error => (error as {uncertain?: boolean}).uncertain === true);
  assert.equal(writes, 1); await db.close(); db = await open(); paid = false;
  const receipt = await execution().reconcile(actor, {requestId: original().requestId, assistant: binding()});
  assert.equal(receipt?.profile.displayName, "Final native name"); assert.equal(writes, 1);
});
test("B04 actual SQL changed final payload cannot reuse an accepted operation or proposal", local, async () => {
  await prepare(); await execution().save(actor, original());
  await assert.rejects(execution().save(actor, original("Another name")));
  await assert.rejects(execution().save(actor, {...original(), requestId: "different-operation"}));
  assert.equal(writes, 1);
});
test("B04 actual SQL stale source, wrong proposal, foreign actor and revoked access cannot write", local, async () => {
  await prepare();
  await assert.rejects(execution().save(actor, {...original(), assistant: {...binding(), proposalId: "foreign-proposal"}}));
  await assert.rejects(execution().save({...actor, uid: "host-b"}, original()));
  paid = false; await assert.rejects(execution().save(actor, original()));
  paid = true; await profile().save(actor, {requestId: "other-device", expectedRevision: 0, change: {kind: "name", displayName: "Newer name"}});
  await assert.rejects(execution().save(actor, original())); assert.equal(writes, 1);
});
test("B04 actual SQL cancelled preparation cannot be saved", local, async () => {
  await prepare(); const c = binding(); const identity = {ownerUid: actor.uid, projectId: actor.projectId, scope, requestId: c.preparationRequestId};
  await requests().cancel(preparationKey(identity), identity);
  await assert.rejects(execution().save(actor, original())); assert.equal(writes, 0);
});
test("B04 original SQL address add uses native full record; cannot alter unrelated sections", local, async () => {
  const c = binding("AI-ACT-025"); await prepare(c);
  const address = {id: "native-address", kind: "home", label: "Home", recipient: "Host buyer", phone: "9999999999", line: "Host test road", area: "Host area", pinCode: "342001", landmark: ""};
  const saved = await execution().save(actor, {...original(), change: {kind: "delivery", addresses: [address], selectedAddressId: address.id}, assistant: c});
  assert.equal(saved.profile.addresses.length, 1); assert.equal(saved.profile.selectedAddressId, address.id); assert.equal(writes, 1);
});

for(const revoke of [false,true])test(`B04 actual SQL ${revoke?'revocation':'cancellation'} during consent linkage denies dispatch`,local,async()=>{
 await prepare();if(revoke)revokeDuringClaim=true;else cancelDuringClaim=true;
 await assert.rejects(execution().save(actor,original()));assert.equal(writes,0);
});
test("B04 original SQL edit changes only the selected address and preserves selection",local,async()=>{
 const a={id:"address-a",kind:"home",label:"Home",recipient:"Host buyer",phone:"9999999999",line:"Old road",area:"Host area",pinCode:"342001",landmark:""};
 const b={...a,id:"address-b",label:"Work",kind:"work"};
 await profile().save(actor,{requestId:"setup-only",expectedRevision:0,change:{kind:"delivery",addresses:[a,b],selectedAddressId:b.id}});
 const c={...binding("AI-ACT-026",a.id),sourceRevision:"profile:1"};await prepare(c);
 await assert.rejects(execution().save(actor,{...original(),expectedRevision:1,change:{kind:"delivery",addresses:[{...a,line:"New road"},{...b,line:"Unrelated change"}],selectedAddressId:b.id},assistant:c}));
 assert.equal(writes,1);
 const saved=await execution().save(actor,{...original(),expectedRevision:1,change:{kind:"delivery",addresses:[{...a,line:"New road"},b],selectedAddressId:b.id},assistant:c});
 assert.equal(saved.profile.addresses[0]!.line,"New road");assert.equal(saved.profile.addresses[1]!.line,b.line);assert.equal(saved.profile.selectedAddressId,b.id);assert.equal(writes,2);
});

// Explicit host SQL translation of the compiler-qualified GraphQL erasure mutation.
// It qualifies transaction/isolation behaviour locally, not the deployed SDK connector.
async function eraseHostOwner(uid: string, failBeforeTombstone = false) {
  await db.exec("BEGIN");
  try {
    for (const table of ["assistant_preparation_request", "assistant_usage_reservation", "assistant_profile_operation"]) {
      await db.query(`DELETE FROM ${table} WHERE owner_uid=$1`, [uid]);
    }
    if (failBeforeTombstone) await db.query("UPDATE app_user SET status=NULL WHERE uid=$1", [uid]);
    await db.query("UPDATE app_user SET status='DELETED',display_name=NULL,profile_data_json=NULL,profile_receipts_json=NULL,updated_at=$2 WHERE uid=$1", [uid, now]);
    await db.exec("COMMIT");
  } catch (error) {await db.exec("ROLLBACK"); throw error;}
}
async function seedPrivateRecords() {
  await prepare(); await execution().save(actor, original());
  for (const uid of [actor.uid, "host-b"]) {
    await db.query("INSERT INTO assistant_usage_reservation(request_key,reservation_id,owner_uid,project_id,scope_json,request_id,fingerprint,state,grant_json,created_at,updated_at) VALUES($1,$2,$3,'host-project','{}','host-request','host-fingerprint','completed','host-private-grant',$4,$4)", [digest(uid), `reservation-${uid}`, uid, now]);
  }
}
test("B07/B04 erasure operation is server-only and atomically removes all new private records", () => {
  const root = process.env.MOOLSOCIAL_ASSISTANT_SOURCE_ROOT;
  if (!root) return;
  const source = fs.readFileSync(path.join(root, "dataconnect/provider/youtube.gql"), "utf8");
  const operation = source.slice(source.indexOf("mutation EraseMoolSocialUser("));
  assert.match(operation, /^mutation EraseMoolSocialUser[^\n]+@auth\(level: NO_ACCESS\) @transaction \{/u);
  for (const table of ["assistantPreparationRequest", "assistantUsageReservation", "assistantProfileOperation"]) {
    assert.ok(operation.includes(`${table}_deleteMany(where: {owner: {uid: {eq: $userId}}})`));
  }
  assert.ok(operation.includes("appUser_update(")); assert.ok(operation.includes("status: DELETED"));
});
test("B07/B04 account tombstone clears AI private data but preserves principal and other owner", local, async () => {
  await seedPrivateRecords(); await eraseHostOwner(actor.uid);
  for (const table of ["assistant_preparation_request", "assistant_profile_operation", "assistant_usage_reservation"]) {
    assert.equal((await db.query(`SELECT * FROM ${table} WHERE owner_uid=$1`, [actor.uid])).rows.length, 0);
  }
  const owner=(await db.query("SELECT * FROM app_user WHERE uid=$1", [actor.uid])).rows[0]!;
  assert.equal(owner.status,"DELETED"); assert.equal(owner.display_name,null); assert.equal(owner.profile_data_json,null); assert.equal(owner.profile_receipts_json,null);
  assert.equal((await db.query("SELECT * FROM assistant_usage_reservation WHERE owner_uid='host-b'")).rows.length,1);
  assert.equal((await db.query("SELECT status FROM app_user WHERE uid='host-b'")).rows[0]!.status,"ACTIVE");
  const id={ownerUid:actor.uid,projectId:actor.projectId,scope,requestId:binding().preparationRequestId};
  assert.equal(await requests().read(preparationKey(id),id),undefined);
  await assert.rejects(requests().claim(preparationKey(id),digest({hostOnly:true}),id));
  await assert.rejects(execution().save(actor,original())); assert.equal(writes,1);
  await eraseHostOwner(actor.uid); // idempotent original erasure retry
});
test("B07/B04 erasure rolls back all private deletions when tombstoning fails", local, async () => {
  await seedPrivateRecords(); await assert.rejects(eraseHostOwner(actor.uid,true));
  for (const table of ["assistant_preparation_request", "assistant_profile_operation", "assistant_usage_reservation"]) {
    assert.equal((await db.query(`SELECT * FROM ${table} WHERE owner_uid=$1`, [actor.uid])).rows.length,1);
  }
  assert.equal((await db.query("SELECT status FROM app_user WHERE uid=$1",[actor.uid])).rows[0]!.status,"ACTIVE");
});
