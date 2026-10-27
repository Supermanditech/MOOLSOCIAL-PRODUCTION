import test from "node:test";
import assert from "node:assert/strict";
import {AssistantHistoryService} from "./history_service.js";
import type {HistoryRepository} from "./history_dataconnect_store.js";
import type {AccountPlansService} from "../account/plans_service.js";
import {AssistantModelError} from "./model_contract.js";
const actor = {uid: "host-owner", projectId: "fixture-project"}, scope = {audience: "personal" as const, storeId: null};
const now = new Date("2026-10-28T00:00:00.000Z");
function fixture() {
  let paid = true, expired = false, reads = 0, accesses = 0, revision = 1, changeAfterRead = false;
  const repository: HistoryRepository = {
    async list() {reads++; if (changeAfterRead) revision++; return [];},
    async read() {reads++; return undefined;}, async status() {reads++; return undefined;},
    async claim() {reads++; return {state: "pending"};}, async commit() {reads++; return {state: "pending"};},
  };
  const plans = {async read() {accesses++; return {activeFeatureIds: paid ? ["mool_ai"] : [],
    validUntil: expired ? "2026-10-27T00:00:00.000Z" : "2026-10-29T00:00:00.000Z", catalogueRevision: 1, subscriptionRevision: revision};}} as unknown as Pick<AccountPlansService, "read">;
  return {service: new AssistantHistoryService({projectId: actor.projectId, plans, repository, now: () => now}),
    values: () => ({reads, accesses}), unpaid: () => paid = false, expire: () => expired = true,
    revokeOnRead: () => changeAfterRead = true};
}
test("History requires current paid authority before any private repository read", async () => {
  for (const kind of ["unpaid", "expired"]) {
    const f = fixture(); if (kind === "unpaid") f.unpaid(); else f.expire();
    await assert.rejects(f.service.handle(actor, {operation: "list", payload: {scope, cursor: null}}));
    assert.equal(f.values().reads, 0);
  }
});
test("History project/default-tenant mismatch is rejected before authority/source calls", async () => {
  for (const who of [{...actor, projectId: "foreign"}, {...actor, tenantId: "foreign"}, {...actor, uid: ""}]) {
    const f = fixture(); await assert.rejects(f.service.handle(who, {operation: "list", payload: {scope, cursor: null}}));
    assert.deepEqual(f.values(), {reads: 0, accesses: 0});
  }
});
test("History late access revision changes discard the private result", async () => {
  const f = fixture(); f.revokeOnRead();
  await assert.rejects(f.service.handle(actor, {operation: "list", payload: {scope, cursor: null}}),
    (e: unknown) => e instanceof AssistantModelError && e.code === "history_access_changed");
});
test("History rejects malformed cursor instead of treating it as an empty history", async () => {
  for (const cursor of ["not+base64", "e30", Buffer.from('{"role":"admin"}').toString("base64url")]) {
    const f = fixture(); await assert.rejects(f.service.handle(actor, {operation: "list", payload: {scope, cursor}}));
    assert.equal(f.values().reads, 0);
  }
});
test("History unavailable original status stays unknown, never a confirmed empty save", async () => {
  const f = fixture();
  await assert.rejects(f.service.handle(actor, {operation: "status", payload: {scope, requestId: "missing"}}),
    (e: unknown) => e instanceof AssistantModelError && e.code === "history_request_not_found");
});
