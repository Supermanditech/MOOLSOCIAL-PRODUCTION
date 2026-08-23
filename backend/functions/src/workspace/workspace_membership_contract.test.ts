import assert from "node:assert/strict";
import test from "node:test";

import {
  WorkspaceMembershipContractError,
  projectActiveWorkspaceMemberships,
  type WorkspaceMembershipContractErrorCode,
  type WorkspaceMembershipRecord,
} from "./workspace_membership_contract.js";

const AT = "2026-08-07T01:00:00.000Z";

function membership(
  overrides: Partial<WorkspaceMembershipRecord> = {},
): WorkspaceMembershipRecord {
  return {
    schemaVersion: 1,
    membershipId: "membership.grocery-001",
    accountId: "account.personal-001",
    workspaceId: "workspace.grocery-001",
    workspaceProfileId: "profile.grocery-kirana-shop",
    state: "active",
    version: 3,
    grantedAt: "2026-08-01T00:00:00.000Z",
    ...overrides,
  };
}

function expectCode(
  callback: () => unknown,
  code: WorkspaceMembershipContractErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof WorkspaceMembershipContractError && error.code === code,
  );
}

function project(
  memberships: readonly WorkspaceMembershipRecord[],
  accountId = "account.personal-001",
  at = AT,
) {
  return projectActiveWorkspaceMemberships({ accountId, at, memberships });
}

test("projects only active memberships with stable identity and no capabilities", () => {
  const result = project([
    membership(),
    membership({
      membershipId: "membership.pending-001",
      workspaceId: "workspace.pending-001",
      state: "pending",
    }),
    membership({
      membershipId: "membership.revoked-001",
      workspaceId: "workspace.revoked-001",
      state: "revoked",
      revokedAt: "2026-08-06T00:00:00.000Z",
    }),
    membership({
      membershipId: "membership.expired-001",
      workspaceId: "workspace.expired-001",
      state: "expired",
      expiresAt: "2026-08-06T00:00:00.000Z",
    }),
  ]);

  assert.deepEqual(result, [
    {
      schemaVersion: 1,
      membershipId: "membership.grocery-001",
      workspaceId: "workspace.grocery-001",
      workspaceProfileId: "profile.grocery-kirana-shop",
      state: "active",
      version: 3,
      effectiveFrom: "2026-08-01T00:00:00.000Z",
    },
  ]);
  assert.equal("capabilities" in result[0]!, false);
  assert.equal("accountId" in result[0]!, false);
});

test("excludes active records outside their effective interval", () => {
  assert.deepEqual(
    project([
      membership({ effectiveFrom: "2026-08-08T00:00:00.000Z" }),
      membership({
        membershipId: "membership.ended-001",
        workspaceId: "workspace.ended-001",
        expiresAt: "2026-08-07T01:00:00.000Z",
      }),
    ]),
    [],
  );
});

test("preserves an unknown stable profile id without inferring permissions", () => {
  const result = project([
    membership({ workspaceProfileId: "profile.future-registered-disabled" }),
  ]);
  assert.equal(
    result[0]?.workspaceProfileId,
    "profile.future-registered-disabled",
  );
  assert.deepEqual(Object.keys(result[0]!).sort(), [
    "effectiveFrom",
    "membershipId",
    "schemaVersion",
    "state",
    "version",
    "workspaceId",
    "workspaceProfileId",
  ]);
});

test("sorts deterministically by workspace identity", () => {
  const result = project([
    membership({
      membershipId: "membership.zeta-001",
      workspaceId: "workspace.zeta-001",
    }),
    membership({
      membershipId: "membership.alpha-001",
      workspaceId: "workspace.alpha-001",
    }),
  ]);
  assert.deepEqual(
    result.map((item) => item.workspaceId),
    ["workspace.alpha-001", "workspace.zeta-001"],
  );
});

test("collapses byte-equivalent duplicate membership records", () => {
  const record = membership({ expiresAt: "2026-08-09T00:00:00.000Z" });
  const result = project([record, { ...record }]);
  assert.equal(result.length, 1);
  assert.equal(result[0]?.expiresAt, "2026-08-09T00:00:00.000Z");
});

test("rejects a membership id reused for a conflicting record", () => {
  expectCode(
    () => project([membership(), membership({ version: 4 })]),
    "duplicate_conflict",
  );
});

test("rejects two active membership identities for one workspace", () => {
  expectCode(
    () =>
      project([
        membership(),
        membership({ membershipId: "membership.grocery-002" }),
      ]),
    "workspace_conflict",
  );
});

test("rejects cross-account records instead of filtering them", () => {
  expectCode(
    () =>
      project([
        membership(),
        membership({
          membershipId: "membership.other-001",
          accountId: "account.other-001",
          workspaceId: "workspace.other-001",
        }),
      ]),
    "account_mismatch",
  );
});

test("validates every stable identifier", () => {
  for (const invalid of ["", " a ", "x", "bad/id", "bad id"]) {
    expectCode(
      () => project([membership({ membershipId: invalid })]),
      "invalid_input",
    );
  }
  expectCode(
    () => project([membership()], "account/invalid"),
    "invalid_input",
  );
});

test("requires canonical UTC timestamps", () => {
  for (const invalid of [
    "not-a-date",
    "2026-08-07T01:00:00Z",
    "2026-08-07T06:30:00.000+05:30",
  ]) {
    expectCode(
      () => project([membership()], "account.personal-001", invalid),
      "invalid_input",
    );
  }
});

test("rejects an invalid membership validity interval", () => {
  expectCode(
    () =>
      project([
        membership({
          effectiveFrom: "2026-08-05T00:00:00.000Z",
          expiresAt: "2026-08-05T00:00:00.000Z",
        }),
      ]),
    "invalid_transition",
  );
  expectCode(
    () =>
      project([
        membership({ effectiveFrom: "2026-07-31T23:59:59.000Z" }),
      ]),
    "invalid_transition",
  );
});

test("requires state-owned revoked and expired timestamps", () => {
  expectCode(
    () => project([membership({ state: "revoked" })]),
    "invalid_transition",
  );
  expectCode(
    () => project([membership({ state: "expired" })]),
    "invalid_transition",
  );
  expectCode(
    () =>
      project([
        membership({
          state: "active",
          revokedAt: "2026-08-06T00:00:00.000Z",
        }),
      ]),
    "invalid_transition",
  );
});

test("requires a positive integer aggregate version", () => {
  for (const invalid of [0, -1, 1.5, Number.NaN]) {
    expectCode(
      () => project([membership({ version: invalid })]),
      "invalid_input",
    );
  }
});

test("returns a frozen projection and does not mutate input", () => {
  const record = membership();
  const before = structuredClone(record);
  const result = project([record]);
  assert.deepEqual(record, before);
  assert.equal(Object.isFrozen(result), true);
  assert.equal(Object.isFrozen(result[0]), true);
  assert.throws(() => {
    const mutableResult = result as unknown as {
      push(value: (typeof result)[number]): number;
    };
    mutableResult.push(result[0]!);
  });
});

test("returns a frozen empty safe result", () => {
  const result = project([]);
  assert.deepEqual(result, []);
  assert.equal(Object.isFrozen(result), true);
});
