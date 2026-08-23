import assert from "node:assert/strict";
import test from "node:test";

import {
  WorkspaceCapabilityPolicyError,
  resolveWorkspaceCapabilityPolicy,
  type WorkspaceCapabilityPolicyErrorCode,
  type WorkspaceCapabilityPolicyRecord,
} from "./workspace_capability_policy_contract.js";

const AT = "2026-08-07T01:00:00.000Z";

function policy(
  overrides: Partial<WorkspaceCapabilityPolicyRecord> = {},
): WorkspaceCapabilityPolicyRecord {
  return {
    schemaVersion: 1,
    policyId: "policy.grocery-shop-001",
    workspaceProfileId: "profile.grocery-kirana-shop",
    capabilityId: "capability.shop-fulfilment",
    state: "enabled",
    version: 2,
    effectiveFrom: "2026-08-01T00:00:00.000Z",
    expiresAt: "2026-09-01T00:00:00.000Z",
    categoryRequired: true,
    serviceAreaRequired: true,
    categoryIds: ["category.grocery"],
    serviceAreaIds: ["area.342001"],
    ...overrides,
  };
}

function expectCode(
  callback: () => unknown,
  code: WorkspaceCapabilityPolicyErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof WorkspaceCapabilityPolicyError && error.code === code,
  );
}

function resolve(
  policies: readonly WorkspaceCapabilityPolicyRecord[],
  overrides: ResolveOverrides = {},
) {
  const {
    omitCategoryId = false,
    omitServiceAreaId = false,
    categoryId = "category.grocery",
    serviceAreaId = "area.342001",
    ...requestOverrides
  } = overrides;
  return resolveWorkspaceCapabilityPolicy({
    workspaceProfileId: "profile.grocery-kirana-shop",
    capabilityId: "capability.shop-fulfilment",
    at: AT,
    policies,
    ...requestOverrides,
    ...(omitCategoryId ? {} : { categoryId }),
    ...(omitServiceAreaId ? {} : { serviceAreaId }),
  });
}

type ResolveOverrides = Partial<
  Omit<
    Parameters<typeof resolveWorkspaceCapabilityPolicy>[0],
    "policies" | "categoryId" | "serviceAreaId"
  >
> & {
  readonly categoryId?: string;
  readonly serviceAreaId?: string;
  readonly omitCategoryId?: boolean;
  readonly omitServiceAreaId?: boolean;
};

test("activates only the exact profile capability category area and interval", () => {
  const result = resolve([policy()]);
  assert.deepEqual(result, {
    schemaVersion: 1,
    workspaceProfileId: "profile.grocery-kirana-shop",
    capabilityId: "capability.shop-fulfilment",
    state: "active",
    policyId: "policy.grocery-shop-001",
    policyVersion: 2,
    effectiveFrom: "2026-08-01T00:00:00.000Z",
    expiresAt: "2026-09-01T00:00:00.000Z",
  });
});

test("returns missing for another profile or capability", () => {
  assert.equal(
    resolve([policy()], { workspaceProfileId: "profile.individual-doctor" })
      .state,
    "missing",
  );
  assert.equal(
    resolve([policy()], { capabilityId: "capability.book-doctor" }).state,
    "missing",
  );
});

test("returns exact category and service-area mismatch truth", () => {
  assert.equal(
    resolve([policy()], { categoryId: "category.medicine" }).state,
    "category_mismatch",
  );
  assert.equal(
    resolve([policy()], { omitCategoryId: true }).state,
    "category_mismatch",
  );
  assert.equal(
    resolve([policy()], { serviceAreaId: "area.110001" }).state,
    "service_area_mismatch",
  );
  assert.equal(
    resolve([policy()], { omitServiceAreaId: true }).state,
    "service_area_mismatch",
  );
});

test("allows absent optional qualifiers but checks them when supplied", () => {
  const optional = policy({
    categoryRequired: false,
    serviceAreaRequired: false,
  });
  assert.equal(
    resolve([optional], { omitCategoryId: true, omitServiceAreaId: true })
      .state,
    "active",
  );
  assert.equal(
    resolve([optional], { categoryId: "category.medicine" }).state,
    "category_mismatch",
  );
});

test("preserves held and disabled reason before qualifier evaluation", () => {
  const held = resolve([
    policy({ state: "held", reason: "Licence review remains open." }),
  ], { omitCategoryId: true, omitServiceAreaId: true });
  assert.equal(held.state, "held");
  assert.equal(held.reason, "Licence review remains open.");

  const disabled = resolve([
    policy({ state: "disabled", reason: "Profile is registered but disabled." }),
  ]);
  assert.equal(disabled.state, "disabled");
});

test("distinguishes not-yet-effective and expired windows", () => {
  assert.equal(
    resolve([
      policy({
        effectiveFrom: "2026-08-08T00:00:00.000Z",
        expiresAt: "2026-09-08T00:00:00.000Z",
      }),
    ]).state,
    "not_yet_effective",
  );
  assert.equal(
    resolve([
      policy({
        effectiveFrom: "2026-07-01T00:00:00.000Z",
        expiresAt: "2026-08-07T01:00:00.000Z",
      }),
    ]).state,
    "expired",
  );
});

test("selects one current policy from adjacent non-overlapping windows", () => {
  const result = resolve([
    policy({
      policyId: "policy.grocery-shop-old",
      effectiveFrom: "2026-07-01T00:00:00.000Z",
      expiresAt: "2026-08-07T01:00:00.000Z",
    }),
    policy({
      policyId: "policy.grocery-shop-current",
      effectiveFrom: "2026-08-07T01:00:00.000Z",
      expiresAt: "2026-09-01T00:00:00.000Z",
    }),
  ]);
  assert.equal(result.policyId, "policy.grocery-shop-current");
});

test("rejects overlapping exact profile and capability policies", () => {
  expectCode(
    () =>
      resolve([
        policy(),
        policy({
          policyId: "policy.grocery-shop-overlap",
          effectiveFrom: "2026-08-15T00:00:00.000Z",
          expiresAt: "2026-10-01T00:00:00.000Z",
        }),
      ]),
    "ambiguous_policy",
  );
});

test("collapses exact duplicate policy records", () => {
  const record = policy();
  assert.equal(resolve([record, { ...record }]).state, "active");
});

test("rejects a policy id reused for conflicting data", () => {
  expectCode(
    () => resolve([policy(), policy({ version: 3 })]),
    "duplicate_conflict",
  );
});

test("requires allowlists for required qualifiers", () => {
  expectCode(
    () => resolve([policy({ categoryIds: [] })]),
    "invalid_input",
  );
  expectCode(
    () => resolve([policy({ serviceAreaIds: [] })]),
    "invalid_input",
  );
});

test("rejects duplicate qualifier identifiers", () => {
  expectCode(
    () =>
      resolve([
        policy({ categoryIds: ["category.grocery", "category.grocery"] }),
      ]),
    "invalid_input",
  );
});

test("requires bounded reasons only for held or disabled policies", () => {
  expectCode(
    () => resolve([policy({ state: "held" })]),
    "invalid_input",
  );
  expectCode(
    () => resolve([policy({ reason: "Unexpected" })]),
    "invalid_input",
  );
});

test("validates canonical timestamps and positive intervals", () => {
  expectCode(
    () => resolve([policy({ effectiveFrom: "2026-08-01T00:00:00Z" })]),
    "invalid_input",
  );
  expectCode(
    () =>
      resolve([
        policy({ expiresAt: "2026-08-01T00:00:00.000Z" }),
      ]),
    "invalid_input",
  );
});

test("validates stable request and policy identifiers", () => {
  expectCode(
    () => resolve([policy()], { capabilityId: "bad/id" }),
    "invalid_input",
  );
  expectCode(
    () => resolve([policy({ policyId: "x" })]),
    "invalid_input",
  );
});

test("bounds policy input before resolution", () => {
  const policies = Array.from({ length: 201 }, (_, index) =>
    policy({ policyId: `policy.bound-${index}` }),
  );
  expectCode(() => resolve(policies), "invalid_input");
});

test("returns immutable deterministic output without mutating policy input", () => {
  const record = policy({
    categoryIds: ["category.produce", "category.grocery"],
    serviceAreaIds: ["area.400001", "area.342001"],
  });
  const before = structuredClone(record);
  const result = resolve([record]);
  assert.deepEqual(record, before);
  assert.equal(Object.isFrozen(result), true);
  assert.throws(() => {
    const mutable = result as unknown as { state: string };
    mutable.state = "disabled";
  });
});
