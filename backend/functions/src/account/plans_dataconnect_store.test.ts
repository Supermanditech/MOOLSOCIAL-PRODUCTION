import test from "node:test";
import assert from "node:assert/strict";
import type {DataConnect} from "firebase-admin/data-connect";
import {accountPlansScopeKey, ACCOUNT_PLANS_READ_SQL, DataConnectAccountPlansRepository} from "./plans_dataconnect_store.js";
import type {PlansScope} from "./plans_service.js";

const personal: PlansScope = {audience: "personal", storeId: null};
function repository(rows: unknown, observe?: (query: string, options: unknown) => void) {
  return new DataConnectAccountPlansRepository({executeGraphqlRead: async (query: string, options: unknown) => {
    observe?.(query, options); return {data: {rows}};
  }} as unknown as Pick<DataConnect, "executeGraphqlRead">);
}
test("B02 SQL adapter: account, audience and Store identity are bound parameters", async () => {
  const owner = "fixture' OR 1=1 --";
  const row = {ownerUid: owner, accountStatus: "ACTIVE", catalogue: "{}", subscription: null};
  const r = repository([row], (query, options) => {
    assert.ok(query.includes(ACCOUNT_PLANS_READ_SQL)); assert.ok(!query.includes(owner));
    assert.deepEqual(options, {variables: {uid: owner, audience: "personal", scopeKey: accountPlansScopeKey(owner, personal)}});
  });
  assert.deepEqual(await r.read(owner, personal), {ownerUid: owner, accountStatus: "ACTIVE", catalogue: {}, subscription: null});
});
test("B02 SQL adapter: scope keys isolate account/personal/each Store", () => {
  const keys = [accountPlansScopeKey("fixture-a", personal), accountPlansScopeKey("fixture-b", personal),
    accountPlansScopeKey("fixture-a", {audience: "workspace", storeId: "store-a"}),
    accountPlansScopeKey("fixture-a", {audience: "workspace", storeId: "store-b"})];
  assert.equal(new Set(keys).size, 4); for (const key of keys) assert.match(key, /^[a-f0-9]{64}$/u);
});
test("B02 SQL adapter: a missing account is unavailable, not an invented account", async () => {
  assert.equal(await repository([]).read("fixture-a", personal), undefined);
});
for (const row of [
  {ownerUid: "other", accountStatus: "ACTIVE", catalogue: "{}", subscription: null},
  {ownerUid: "fixture-a", accountStatus: "UNKNOWN", catalogue: "{}", subscription: null},
  {ownerUid: "fixture-a", accountStatus: "ACTIVE", catalogue: "broken JSON", subscription: null},
  {ownerUid: "fixture-a", accountStatus: "ACTIVE", catalogue: "{}", subscription: "broken JSON"},
]) {
  test(`B02 SQL adapter: invalid private source rejected ${JSON.stringify(row)}`, async () => {
    await assert.rejects(repository([row]).read("fixture-a", personal));
  });
}
test("B02 SQL adapter: restricted/deleted rows expose no retained subscription fields", async () => {
  for (const accountStatus of ["RESTRICTED", "DELETED"]) {
    const result = await repository([{ownerUid: "fixture-a", accountStatus, catalogue: "private invalid bytes", subscription: "private invalid bytes"}]).read("fixture-a", personal);
    assert.deepEqual(result, {ownerUid: "fixture-a", accountStatus, catalogue: null, subscription: null});
  }
});
test("B02 SQL adapter: duplicate joined rows fail closed", async () => {
  const row = {ownerUid: "fixture-a", accountStatus: "ACTIVE", catalogue: "{}", subscription: null};
  await assert.rejects(repository([row, row]).read("fixture-a", personal));
});
