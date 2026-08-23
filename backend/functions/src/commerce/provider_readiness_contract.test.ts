import assert from "node:assert/strict";
import test from "node:test";

import type {
  SupplyCapabilityKind,
  SupplyParticipantType,
  SupplyParticipantWorkspace,
} from "./supply_participant_contract.js";
import {
  ProviderReadinessError,
  createProviderReadinessAggregate,
  projectProviderReadiness,
  publishProviderReadiness,
  type ProviderReadinessAggregate,
  type ProviderReadinessCommandPayload,
  type ProviderReadinessErrorCode,
  type ProviderReadinessFamily,
  type PublishProviderReadinessCommand,
} from "./provider_readiness_contract.js";
import {
  PrivilegedCommandError,
  type PrivilegedCommandErrorCode,
} from "../workspace/privileged_command_contract.js";

const TENANT_ID = "tenant.india-001";
const WORKSPACE_ID = "workspace.provider-001";
const READINESS_ID = "readiness.provider-001";
const CATEGORY_ID = "category.staples";
const SERVICE_AREA_ID = "service-area.bengaluru-east";
const OPERATOR_SCOPE = "commerce.provider_readiness.operate";

function capabilityForFamily(family: ProviderReadinessFamily): SupplyCapabilityKind {
  return family === "wholesale" ? "wholesale_supply" : "retail_fulfilment";
}

function workspace(
  participantType: SupplyParticipantType = "shop",
  family: ProviderReadinessFamily = "shop",
  overrides: Partial<SupplyParticipantWorkspace> = {},
): SupplyParticipantWorkspace {
  return {
    schemaVersion: 1,
    workspaceId: WORKSPACE_ID,
    tenantId: TENANT_ID,
    legalEntityReference: "legal-entity.provider-001",
    participantType,
    status: "registered",
    version: 3,
    capabilities: [
      {
        kind: capabilityForFamily(family),
        state: "verified",
        requestedAt: "2026-08-01T00:00:00.000Z",
        requestedBy: "operator.provider-001",
        evidence: [],
        qualifiers: {
          categoryIds: [CATEGORY_ID],
          serviceAreaIds: [SERVICE_AREA_ID],
        },
        reviewedAt: "2026-08-01T01:00:00.000Z",
        reviewedBy: "reviewer.supply-001",
        effectiveFrom: "2026-08-01T02:00:00.000Z",
        expiresAt: "2026-08-20T00:00:00.000Z",
      },
    ],
    commandReceipts: [],
    auditEvents: [],
    ...overrides,
  };
}

function aggregate(
  family: ProviderReadinessFamily = "shop",
): ProviderReadinessAggregate {
  return createProviderReadinessAggregate({
    tenantId: TENANT_ID,
    readinessId: READINESS_ID,
    workspaceId: WORKSPACE_ID,
    family,
    categoryId: CATEGORY_ID,
    serviceAreaId: SERVICE_AREA_ID,
  });
}

function payload(
  family: ProviderReadinessFamily = "shop",
  overrides: Partial<ProviderReadinessCommandPayload> = {},
): ProviderReadinessCommandPayload {
  return {
    readinessId: READINESS_ID,
    workspaceId: WORKSPACE_ID,
    family,
    categoryId: CATEGORY_ID,
    serviceAreaId: SERVICE_AREA_ID,
    state: "ready",
    effectiveFrom: "2026-08-07T04:00:00.000Z",
    expiresAt: "2026-08-07T08:00:00.000Z",
    reasonCode: "ops.accept-new-demand",
    ...overrides,
  };
}

function operator(
  overrides: Partial<ReturnType<typeof operatorBase>> = {},
) {
  return { ...operatorBase(), ...overrides };
}

function operatorBase() {
  return {
    actorId: "operator.provider-001",
    tenantId: TENANT_ID,
    workspaceId: WORKSPACE_ID,
    scopes: [OPERATOR_SCOPE],
  };
}

function command(
  current: ProviderReadinessAggregate,
  overrides: Partial<PublishProviderReadinessCommand> = {},
): PublishProviderReadinessCommand {
  return {
    schemaVersion: 1,
    commandId: `command.readiness-${current.version}`,
    aggregateId: current.readinessId,
    expectedVersion: current.version,
    occurredAt: "2026-08-07T03:00:00.000Z",
    confirmed: true,
    reason: "Publish the exact reviewed provider workspace readiness.",
    actor: operatorBase(),
    payload: payload(current.family),
    ...overrides,
  };
}

function publish(
  current: ProviderReadinessAggregate = aggregate(),
  supplyWorkspace: SupplyParticipantWorkspace = workspace(),
  overrides: Partial<PublishProviderReadinessCommand> = {},
  operatorOverrides: Partial<ReturnType<typeof operatorBase>> = {},
) {
  return publishProviderReadiness({
    aggregate: current,
    workspace: supplyWorkspace,
    operator: operator(operatorOverrides),
    command: command(current, overrides),
  });
}

function project(
  current: ProviderReadinessAggregate,
  supplyWorkspace: SupplyParticipantWorkspace,
  at: string,
) {
  return projectProviderReadiness({
    aggregate: current,
    workspace: supplyWorkspace,
    tenantId: TENANT_ID,
    readinessId: READINESS_ID,
    actor: operatorBase(),
    operator: operatorBase(),
    at,
  });
}

function expectReadinessCode(
  callback: () => unknown,
  code: ProviderReadinessErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof ProviderReadinessError && error.code === code,
  );
}

function expectCommandCode(
  callback: () => unknown,
  code: PrivilegedCommandErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof PrivilegedCommandError && error.code === code,
  );
}

test("creates one immutable unknown readiness aggregate", () => {
  const current = aggregate();
  assert.equal(current.version, 1);
  assert.deepEqual(current.revisions, []);
  assert.equal(Object.isFrozen(current), true);
  assert.equal(Object.isFrozen(current.revisions), true);
});

test("publishes ready busy and paused as nonoverlapping scheduled revisions", () => {
  const supply = workspace();
  const ready = publish(aggregate(), supply);
  const busy = publish(ready.aggregate, supply, {
    commandId: "command.readiness-busy",
    occurredAt: "2026-08-07T03:10:00.000Z",
    payload: payload("shop", {
      state: "busy",
      effectiveFrom: "2026-08-07T08:00:00.000Z",
      expiresAt: "2026-08-07T12:00:00.000Z",
      reasonCode: "ops.declared-busy",
    }),
  });
  const paused = publish(busy.aggregate, supply, {
    commandId: "command.readiness-paused",
    occurredAt: "2026-08-07T03:20:00.000Z",
    payload: payload("shop", {
      state: "paused",
      effectiveFrom: "2026-08-07T12:00:00.000Z",
      expiresAt: "2026-08-07T16:00:00.000Z",
      reasonCode: "ops.manual-pause",
    }),
  });
  assert.deepEqual(
    paused.aggregate.revisions.map((item) => item.state),
    ["ready", "busy", "paused"],
  );
  assert.equal(project(paused.aggregate, supply, "2026-08-07T07:59:59.999Z").state, "ready");
  assert.equal(project(paused.aggregate, supply, "2026-08-07T08:00:00.000Z").state, "busy");
  assert.equal(project(paused.aggregate, supply, "2026-08-07T12:00:00.000Z").state, "paused");
});

test("accepts only exact participant types for each family", () => {
  const allowed: readonly [ProviderReadinessFamily, SupplyParticipantType[]][] = [
    ["shop", ["shop", "retailer"]],
    ["wholesale", ["wholesaler", "distributor", "manufacturer"]],
    ["medicine_non_prescription", ["pharmacy"]],
    ["medicine_prescription_pharmacist_ready", ["pharmacy"]],
  ];
  for (const [family, participantTypes] of allowed) {
    for (const participantType of participantTypes) {
      const current = aggregate(family);
      const supply = workspace(participantType, family);
      const result = publish(current, supply, { payload: payload(family) });
      assert.equal(result.revision.family, family);
      assert.equal(result.revision.requiredCapability, capabilityForFamily(family));
    }
  }
  expectReadinessCode(
    () => publish(aggregate("wholesale"), workspace("shop", "wholesale"), {
      payload: payload("wholesale"),
    }),
    "participant_mismatch",
  );
  expectReadinessCode(
    () => publish(aggregate("medicine_non_prescription"), workspace("retailer", "medicine_non_prescription"), {
      payload: payload("medicine_non_prescription"),
    }),
    "participant_mismatch",
  );
});

test("fails closed for missing category service area suspended or short capability", () => {
  const base = workspace();
  for (const qualifiers of [
    { categoryIds: ["category.other"], serviceAreaIds: [SERVICE_AREA_ID] },
    { categoryIds: [CATEGORY_ID], serviceAreaIds: ["service-area.other"] },
  ]) {
    expectReadinessCode(
      () => publish(aggregate(), workspace("shop", "shop", {
        capabilities: [{ ...base.capabilities[0]!, qualifiers }],
      })),
      "capability_inactive",
    );
  }
  expectReadinessCode(
    () => publish(aggregate(), workspace("shop", "shop", {
      capabilities: [{ ...base.capabilities[0]!, state: "suspended" }],
    })),
    "capability_inactive",
  );
  expectReadinessCode(
    () => publish(aggregate(), workspace("shop", "shop", {
      capabilities: [{ ...base.capabilities[0]!, expiresAt: "2026-08-07T06:00:00.000Z" }],
    })),
    "capability_inactive",
  );
});

test("authorization denies before hidden readiness values and stale version", () => {
  const base = aggregate();
  const hidden = {
    ...base,
    get revisions(): readonly never[] {
      throw new Error("readiness values were accessed");
    },
  } as unknown as ProviderReadinessAggregate;
  expectCommandCode(
    () =>
      publishProviderReadiness({
        aggregate: hidden,
        workspace: workspace(),
        operator: operatorBase(),
        command: command(base, {
          expectedVersion: 99,
          actor: { ...operatorBase(), scopes: [] },
        }),
      }),
    "unauthorized",
  );
});

test("binds command actor and supply operator to exact tenant and workspace", () => {
  expectReadinessCode(
    () => publish(aggregate(), workspace(), {}, { workspaceId: "workspace.other-001" }),
    "workspace_mismatch",
  );
  expectReadinessCode(
    () => publish(aggregate(), workspace(), {}, { tenantId: "tenant.other-001" }),
    "tenant_mismatch",
  );
  expectReadinessCode(
    () => publish(aggregate(), workspace("shop", "shop", {
      workspaceId: "workspace.other-001",
    })),
    "workspace_mismatch",
  );
});

test("accepts effective-now and rejects backdating expiry inversion and overlap", () => {
  const now = publish(aggregate(), workspace(), {
    occurredAt: "2026-08-07T04:00:00.000Z",
    payload: payload("shop", { effectiveFrom: "2026-08-07T04:00:00.000Z" }),
  });
  assert.equal(now.revision.effectiveFrom, now.revision.publishedAt);
  expectReadinessCode(
    () => publish(aggregate(), workspace(), {
      payload: payload("shop", { effectiveFrom: "2026-08-07T02:59:59.999Z" }),
    }),
    "effective_time_conflict",
  );
  expectReadinessCode(
    () => publish(aggregate(), workspace(), {
      payload: payload("shop", { expiresAt: "2026-08-07T04:00:00.000Z" }),
    }),
    "effective_time_conflict",
  );
  expectReadinessCode(
    () => publish(now.aggregate, workspace(), {
      payload: payload("shop", {
        effectiveFrom: "2026-08-07T07:59:59.999Z",
        expiresAt: "2026-08-07T09:00:00.000Z",
      }),
    }),
    "effective_time_conflict",
  );
});

test("projects unknown before schedule and stale after declaration expiry", () => {
  const supply = workspace();
  const ready = publish(aggregate(), supply).aggregate;
  assert.equal(project(ready, supply, "2026-08-07T03:59:59.999Z").state, "unknown");
  assert.equal(project(ready, supply, "2026-08-07T04:00:00.000Z").state, "ready");
  const stale = project(ready, supply, "2026-08-07T08:00:00.000Z");
  assert.equal(stale.state, "stale");
  if (stale.state === "stale") assert.equal(stale.lastRevision.state, "ready");
});

test("projects ineligible when SUP-001 capability is inactive at query time", () => {
  const supply = workspace();
  const ready = publish(aggregate(), supply).aggregate;
  const suspended = workspace("shop", "shop", {
    capabilities: [{ ...supply.capabilities[0]!, state: "suspended" }],
  });
  assert.equal(project(ready, suspended, "2026-08-07T05:00:00.000Z").state, "ineligible");
});

test("exact retry is offline-safe while changed retry and stale race fail", () => {
  const current = aggregate();
  const supply = workspace();
  const original = command(current);
  const first = publishProviderReadiness({
    aggregate: current,
    workspace: supply,
    operator: operatorBase(),
    command: original,
  });
  const retry = publishProviderReadiness({
    aggregate: first.aggregate,
    workspace: supply,
    operator: operatorBase(),
    command: original,
  });
  assert.equal(retry.replayed, true);
  assert.equal(retry.aggregate.revisions.length, 1);
  assert.deepEqual(retry.receipt, first.receipt);
  expectReadinessCode(
    () => publishProviderReadiness({
      aggregate: first.aggregate,
      workspace: supply,
      operator: { ...operatorBase(), workspaceId: "workspace.other-001" },
      command: original,
    }),
    "workspace_mismatch",
  );
  expectReadinessCode(
    () => publishProviderReadiness({
      aggregate: first.aggregate,
      workspace: workspace("shop", "shop", {
        workspaceId: "workspace.other-001",
      }),
      operator: operatorBase(),
      command: original,
    }),
    "workspace_mismatch",
  );
  expectCommandCode(
    () => publishProviderReadiness({
      aggregate: first.aggregate,
      workspace: supply,
      operator: operatorBase(),
      command: { ...original, payload: payload("shop", { state: "busy" }) },
    }),
    "idempotency_conflict",
  );
  expectCommandCode(
    () => publishProviderReadiness({
      aggregate: first.aggregate,
      workspace: supply,
      operator: operatorBase(),
      command: command(current, { commandId: "command.concurrent-second" }),
    }),
    "version_conflict",
  );
});

test("rejects personal telemetry and inferred-state payload fields", () => {
  const unsafePayload = {
    ...payload(),
    personalActivity: "other-app-open",
  } as unknown as ProviderReadinessCommandPayload;
  expectReadinessCode(
    () => publish(aggregate(), workspace(), { payload: unsafePayload }),
    "invalid_input",
  );
});

test("JSON restart preserves exact projection and rejects tampered history", () => {
  const supply = workspace();
  const ready = publish(aggregate(), supply).aggregate;
  const restarted = JSON.parse(JSON.stringify(ready)) as ProviderReadinessAggregate;
  assert.deepEqual(
    project(restarted, supply, "2026-08-07T05:00:00.000Z"),
    project(ready, supply, "2026-08-07T05:00:00.000Z"),
  );
  const tampered = JSON.parse(JSON.stringify(ready)) as ProviderReadinessAggregate;
  const revision = tampered.revisions[0] as unknown as { state: string };
  revision.state = "inferred_ready";
  expectReadinessCode(
    () => project(tampered, supply, "2026-08-07T05:00:00.000Z"),
    "invalid_input",
  );
  for (const target of ["root", "revision", "receipt", "audit"] as const) {
    const unsafe = JSON.parse(JSON.stringify(ready)) as unknown as Record<
      string,
      unknown
    >;
    if (target === "root") {
      unsafe.personalActivity = "other-app-open";
    } else {
      const key =
        target === "revision"
          ? "revisions"
          : target === "receipt"
            ? "receipts"
            : "auditEvents";
      const records = unsafe[key] as Array<Record<string, unknown>>;
      records[0]!.personalActivity = "other-app-open";
    }
    expectReadinessCode(
      () =>
        project(
          unsafe as unknown as ProviderReadinessAggregate,
          supply,
          "2026-08-07T05:00:00.000Z",
        ),
      "invalid_input",
    );
  }
});

test("projection authorization denies before hidden values", () => {
  const base = publish(aggregate(), workspace()).aggregate;
  const hidden = {
    ...base,
    get revisions(): readonly never[] {
      throw new Error("readiness values were accessed");
    },
  } as unknown as ProviderReadinessAggregate;
  expectReadinessCode(
    () =>
      projectProviderReadiness({
        aggregate: hidden,
        workspace: workspace(),
        tenantId: TENANT_ID,
        readinessId: READINESS_ID,
        actor: { ...operatorBase(), scopes: [] },
        operator: operatorBase(),
        at: "2026-08-07T05:00:00.000Z",
      }),
    "unauthorized",
  );
});

test("does not mutate inputs and returns deeply immutable payload-free evidence", () => {
  const current = JSON.parse(JSON.stringify(aggregate())) as ProviderReadinessAggregate;
  const supply = workspace();
  const before = JSON.stringify(current);
  const result = publish(current, supply);
  assert.equal(JSON.stringify(current), before);
  assert.equal(Object.isFrozen(result), true);
  assert.equal(Object.isFrozen(result.aggregate), true);
  assert.equal(Object.isFrozen(result.revision), true);
  assert.equal(Object.isFrozen(result.receipt), true);
  assert.equal(Object.isFrozen(result.aggregate.auditEvents[0]), true);
  assert.doesNotMatch(
    JSON.stringify(result.aggregate.auditEvents[0]),
    /email|phone|message|contact|microphone|location|secret|token|password/iu,
  );
  assert.throws(() => {
    const target = result.revision as unknown as { state: string };
    target.state = "busy";
  }, TypeError);
});
