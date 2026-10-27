import test from "node:test";
import assert from "node:assert/strict";
import {authorisedWorkspaces, decodeAddressSuggestion, profileSourceRevision} from "./context_contract.js";

const at = Date.parse("2026-10-27T08:00:00.000Z");
function row() {return {workspaceId: "store-a", caseId: "case-a", profileId: "retailer-grocery", name: "Host fixture Store", status: "approved",
  access: {schemaVersion: 1, state: "active", accountId: "owner-a", workspaceId: "store-a", caseId: "case-a", profileId: "retailer-grocery",
    applicationUpdatedAt: "2026-10-27T00:00:00.000Z", checkedAt: new Date(at).toISOString(),
    membership: {schemaVersion: 1, membershipId: "member-a", workspaceId: "store-a", workspaceProfileId: "retailer-grocery", state: "active", version: 1,
      effectiveFrom: "2026-10-27T00:00:00.000Z"}}};}
test("THIN-B03 canonical Profile revision is not a client form counter", () => {
  assert.equal(profileSourceRevision({revision: 4}), "profile:4");
  for (const revision of [-1, NaN, Infinity, 1.5]) assert.throws(() => profileSourceRevision({revision}));
});
test("THIN-B03 consumes B03 active readback and omits unapproved rows", () => {
  const source = row(), raw = {workspaces: [source, {status: "pending", access: {state: "denied"}}]};
  assert.deepEqual(authorisedWorkspaces(raw, "owner-a", at), [{id: "store-a", name: source.name, profileId: source.profileId,
    revision: "workspace:6e71ffe550175578a8b42bfbecfc44754bedfd28607b95b9bf67634fb02dcd1e", validUntil: at + 60_000}]);
  assert.throws(() => authorisedWorkspaces({workspaces: [source, source]}, "owner-a", at));
});
for (const [label, change] of [
  ["foreign account", (r: ReturnType<typeof row>) => {r.access.accountId = "owner-b";}],
  ["foreign Store", (r: ReturnType<typeof row>) => {r.access.membership.workspaceId = "store-b";}],
  ["revoked", (r: ReturnType<typeof row>) => {r.access.membership.state = "revoked";}],
  ["future check", (r: ReturnType<typeof row>) => {r.access.checkedAt = new Date(at + 1).toISOString();}],
  ["stale check", (r: ReturnType<typeof row>) => {r.access.checkedAt = new Date(at - 60_001).toISOString();}],
  ["rejected", (r: ReturnType<typeof row>) => {r.status = "rejected";}],
  ["unsupported vertical", (r: ReturnType<typeof row>) => {r.profileId = r.access.profileId = r.access.membership.workspaceProfileId = "restaurant";}],
  ["invalid version", (r: ReturnType<typeof row>) => {r.access.membership.version = 0;}],
] as const) test(`THIN-B03 rejects ${label} canonical access`, () => {
  const r = row(); change(r); assert.throws(() => authorisedWorkspaces({workspaces: [r]}, "owner-a", at));
});
test("THIN-B03 nullable model slots retain only supplied native address fields", () => {
  const source = {recipient: null, phone: null, line: "नई सड़क", area: null, pinCode: "342001", landmark: null, kind: null};
  assert.deepEqual(decodeAddressSuggestion(source), {line: "नई सड़क", pinCode: "342001"});
  assert.throws(() => decodeAddressSuggestion({...source, proof: "not-a-native-field"}));
  assert.throws(() => decodeAddressSuggestion({...source, phone: "123"}));
  assert.throws(() => decodeAddressSuggestion({...source, kind: "admin"}));
  assert.throws(() => decodeAddressSuggestion({...source, line: null, pinCode: null}));
});
