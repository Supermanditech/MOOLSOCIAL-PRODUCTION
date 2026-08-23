import assert from "node:assert/strict";
import test from "node:test";

import {
  AcceptanceSlaPolicyError,
  buyAcceptanceSlaFamilies,
  createAcceptanceSlaPolicySet,
  effectiveAcceptanceSlaPolicyAt,
  publishAcceptanceSlaPolicy,
  type AcceptanceSlaPolicyErrorCode,
  type AcceptanceSlaPolicyPayload,
  type AcceptanceSlaPolicySet,
  type BuyAcceptanceSlaFamily,
  type PublishAcceptanceSlaPolicyCommand,
} from "./acceptance_sla_policy_contract.js";
import {
  PrivilegedCommandError,
  type PrivilegedCommandErrorCode,
} from "../workspace/privileged_command_contract.js";

const TENANT_ID = "tenant.india-001";
const POLICY_SET_ID = "acceptance-policy.global-001";
const ADMIN_SCOPE = "commerce.fulfilment_policy.admin";

function emptyPolicySet(): AcceptanceSlaPolicySet {
  return createAcceptanceSlaPolicySet({
    tenantId: TENANT_ID,
    policySetId: POLICY_SET_ID,
  });
}

function policyPayload(
  overrides: Partial<AcceptanceSlaPolicyPayload> = {},
): AcceptanceSlaPolicyPayload {
  return {
    family: "shop",
    responseWindowSeconds: 60,
    maximumSequentialPartners: 3,
    overallAssignmentCeilingSeconds: 180,
    effectiveFrom: "2026-08-08T03:00:00.000Z",
    reasonCode: "ops.launch-default",
    ...overrides,
  };
}

function policyCommand(
  policySet: AcceptanceSlaPolicySet,
  overrides: Partial<PublishAcceptanceSlaPolicyCommand> = {},
): PublishAcceptanceSlaPolicyCommand {
  return {
    schemaVersion: 1,
    commandId: `command.acceptance-policy-${policySet.version}`,
    aggregateId: policySet.policySetId,
    expectedVersion: policySet.version,
    occurredAt: "2026-08-07T03:00:00.000Z",
    confirmed: true,
    reason: "Publish one reviewed bounded policy for future orders.",
    actor: {
      actorId: "admin.commerce-policy-001",
      tenantId: policySet.tenantId,
      scopes: [ADMIN_SCOPE],
    },
    payload: policyPayload(),
    ...overrides,
  };
}

function publish(
  policySet: AcceptanceSlaPolicySet,
  overrides: Partial<PublishAcceptanceSlaPolicyCommand> = {},
) {
  return publishAcceptanceSlaPolicy({
    policySet,
    command: policyCommand(policySet, overrides),
  });
}

function expectPolicyCode(
  callback: () => unknown,
  code: AcceptanceSlaPolicyErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof AcceptanceSlaPolicyError && error.code === code,
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

function adminActor(scopes: readonly string[] = [ADMIN_SCOPE]) {
  return {
    actorId: "admin.commerce-policy-001",
    tenantId: TENANT_ID,
    scopes,
  };
}

test("creates one empty tenant-scoped immutable policy set", () => {
  const policySet = emptyPolicySet();
  assert.equal(policySet.version, 1);
  assert.equal(policySet.tenantId, TENANT_ID);
  assert.equal(policySet.policySetId, POLICY_SET_ID);
  assert.deepEqual(policySet.revisions, []);
  assert.equal(Object.isFrozen(policySet), true);
  assert.equal(Object.isFrozen(policySet.revisions), true);
});

test("publishes all four exact launch defaults with deterministic timelines", () => {
  const fixtures: readonly [BuyAcceptanceSlaFamily, number, number, number, number, number][] = [
    ["shop", 60, 3, 180, 20, 40],
    ["wholesale", 180, 3, 540, 60, 120],
    ["medicine_non_prescription", 90, 3, 270, 30, 60],
    ["medicine_prescription_pharmacist_ready", 300, 2, 600, 100, 200],
  ];
  let policySet = emptyPolicySet();
  fixtures.forEach(([family, window, partners, ceiling, whatsApp, call], index) => {
    const result = publish(policySet, {
      commandId: `command.launch-default-${index + 1}`,
      occurredAt: `2026-08-07T03:0${index}:00.000Z`,
      payload: policyPayload({
        family,
        responseWindowSeconds: window,
        maximumSequentialPartners: partners,
        overallAssignmentCeilingSeconds: ceiling,
      }),
    });
    assert.equal(result.revision.moolChatOffsetSeconds, 0);
    assert.equal(result.revision.whatsAppOffsetSeconds, whatsApp);
    assert.equal(result.revision.agenticCallOffsetSeconds, call);
    assert.equal(result.revision.reassignAtSeconds, window);
    assert.equal(result.revision.overallAssignmentCeilingSeconds, ceiling);
    policySet = result.policySet;
  });
  assert.deepEqual(
    policySet.revisions.map((item) => item.family),
    [...buyAcceptanceSlaFamilies],
  );
  assert.equal(policySet.version, 5);
});

test("accepts inclusive numeric boundaries and derives the full final attempt", () => {
  const minimum = publish(emptyPolicySet(), {
    payload: policyPayload({
      responseWindowSeconds: 30,
      maximumSequentialPartners: 1,
      overallAssignmentCeilingSeconds: 30,
    }),
  });
  assert.equal(minimum.revision.whatsAppOffsetSeconds, 10);
  assert.equal(minimum.revision.agenticCallOffsetSeconds, 20);
  assert.equal(minimum.revision.reassignAtSeconds, 30);

  const maximum = publish(emptyPolicySet(), {
    payload: policyPayload({
      responseWindowSeconds: 300,
      maximumSequentialPartners: 5,
      overallAssignmentCeilingSeconds: 1500,
    }),
  });
  assert.equal(maximum.revision.overallAssignmentCeilingSeconds, 1500);
});

test("rejects adjacent-invalid, fractional and unsafe numeric inputs", () => {
  for (const responseWindowSeconds of [29, 301, 60.5, Number.MAX_SAFE_INTEGER + 1]) {
    expectPolicyCode(
      () =>
        publish(emptyPolicySet(), {
          payload: policyPayload({ responseWindowSeconds }),
        }),
      "policy_bounds",
    );
  }
  for (const maximumSequentialPartners of [0, 6, 2.5]) {
    expectPolicyCode(
      () =>
        publish(emptyPolicySet(), {
          payload: policyPayload({ maximumSequentialPartners }),
        }),
      "policy_bounds",
    );
  }
});

test("rejects an unsupported generic service family and missing payload field", () => {
  expectPolicyCode(
    () =>
      publish(emptyPolicySet(), {
        payload: policyPayload({
          family: "generic_service" as BuyAcceptanceSlaFamily,
        }),
      }),
    "unsupported_family",
  );
  const missingReason = {
    family: "shop",
    responseWindowSeconds: 60,
    maximumSequentialPartners: 3,
    overallAssignmentCeilingSeconds: 180,
    effectiveFrom: "2026-08-08T03:00:00.000Z",
  } as unknown as AcceptanceSlaPolicyPayload;
  expectPolicyCode(
    () => publish(emptyPolicySet(), { payload: missingReason }),
    "invalid_input",
  );
});

test("rejects ceiling mismatch instead of truncating an attempt", () => {
  expectPolicyCode(
    () =>
      publish(emptyPolicySet(), {
        payload: policyPayload({ overallAssignmentCeilingSeconds: 179 }),
      }),
    "policy_bounds",
  );
});

test("command authorization denies before hidden policy values or stale version", () => {
  const base = emptyPolicySet();
  const hidden = {
    ...base,
    get revisions(): readonly never[] {
      throw new Error("policy values were accessed");
    },
  } as unknown as AcceptanceSlaPolicySet;
  expectCommandCode(
    () =>
      publishAcceptanceSlaPolicy({
        policySet: hidden,
        command: policyCommand(base, {
          expectedVersion: 999,
          actor: adminActor([]),
        }),
      }),
    "unauthorized",
  );
  expectCommandCode(
    () =>
      publishAcceptanceSlaPolicy({
        policySet: hidden,
        command: policyCommand(base, {
          actor: { ...adminActor(), tenantId: "tenant.other-001" },
        }),
      }),
    "tenant_mismatch",
  );
});

test("read authorization denies before hidden policy values", () => {
  const base = emptyPolicySet();
  const hidden = {
    ...base,
    get revisions(): readonly never[] {
      throw new Error("policy values were accessed");
    },
  } as unknown as AcceptanceSlaPolicySet;
  expectPolicyCode(
    () =>
      effectiveAcceptanceSlaPolicyAt({
        policySet: hidden,
        tenantId: TENANT_ID,
        policySetId: POLICY_SET_ID,
        actor: adminActor([]),
        family: "shop",
        at: "2026-08-08T03:00:00.000Z",
      }),
    "unauthorized",
  );
});

test("requires confirmation and exact tenant, aggregate, scope and version", () => {
  expectCommandCode(
    () => publish(emptyPolicySet(), { confirmed: false }),
    "unauthorized",
  );
  expectCommandCode(
    () => publish(emptyPolicySet(), { aggregateId: "policy.other-001" }),
    "aggregate_mismatch",
  );
  expectCommandCode(
    () => publish(emptyPolicySet(), { expectedVersion: 2 }),
    "version_conflict",
  );
});

test("exact retry returns the original receipt and creates no second revision", () => {
  const initial = emptyPolicySet();
  const command = policyCommand(initial);
  const first = publishAcceptanceSlaPolicy({ policySet: initial, command });
  const retry = publishAcceptanceSlaPolicy({
    policySet: first.policySet,
    command,
  });
  assert.equal(retry.replayed, true);
  assert.deepEqual(retry.receipt, first.receipt);
  assert.deepEqual(retry.revision, first.revision);
  assert.equal(retry.policySet.revisions.length, 1);
  assert.equal(retry.policySet.version, 2);
});

test("changed retry payload is an idempotency conflict", () => {
  const initial = emptyPolicySet();
  const command = policyCommand(initial);
  const first = publishAcceptanceSlaPolicy({ policySet: initial, command });
  expectCommandCode(
    () =>
      publishAcceptanceSlaPolicy({
        policySet: first.policySet,
        command: {
          ...command,
          payload: policyPayload({
            responseWindowSeconds: 90,
            overallAssignmentCeilingSeconds: 270,
          }),
        },
      }),
    "idempotency_conflict",
  );
});

test("concurrent stale commands cannot overwrite a successful revision", () => {
  const initial = emptyPolicySet();
  const first = publish(initial, { commandId: "command.concurrent-first" });
  expectCommandCode(
    () =>
      publishAcceptanceSlaPolicy({
        policySet: first.policySet,
        command: policyCommand(initial, { commandId: "command.concurrent-second" }),
      }),
    "version_conflict",
  );
  assert.equal(first.policySet.revisions.length, 1);
});

test("accepts effective-now for future orders but rejects backdating", () => {
  const effectiveNow = publish(emptyPolicySet(), {
    payload: policyPayload({ effectiveFrom: "2026-08-07T03:00:00.000Z" }),
  });
  assert.equal(
    effectiveNow.revision.effectiveFrom,
    effectiveNow.revision.publishedAt,
  );
  expectPolicyCode(
    () =>
      publish(emptyPolicySet(), {
        payload: policyPayload({ effectiveFrom: "2026-08-07T02:59:59.999Z" }),
      }),
    "effective_time_conflict",
  );
  expectPolicyCode(
    () =>
      publish(emptyPolicySet(), {
        payload: policyPayload({ effectiveFrom: "2026-08-08T03:00:00Z" }),
      }),
    "invalid_input",
  );
});

test("orders effective timestamps strictly per family while isolating families", () => {
  const first = publish(emptyPolicySet(), {
    commandId: "command.shop-first",
    payload: policyPayload({ effectiveFrom: "2026-08-08T03:00:00.000Z" }),
  });
  expectPolicyCode(
    () =>
      publish(first.policySet, {
        commandId: "command.shop-overlap",
        occurredAt: "2026-08-07T04:00:00.000Z",
        payload: policyPayload({ effectiveFrom: "2026-08-08T03:00:00.000Z" }),
      }),
    "effective_time_conflict",
  );
  const wholesale = publish(first.policySet, {
    commandId: "command.wholesale-same-effective",
    occurredAt: "2026-08-07T04:00:00.000Z",
    payload: policyPayload({
      family: "wholesale",
      effectiveFrom: "2026-08-08T03:00:00.000Z",
    }),
  });
  assert.equal(wholesale.policySet.revisions.length, 2);
});

test("effective-at returns only the latest already-effective family revision", () => {
  const first = publish(emptyPolicySet(), {
    commandId: "command.shop-effective-first",
    payload: policyPayload({ effectiveFrom: "2026-08-08T03:00:00.000Z" }),
  });
  const second = publish(first.policySet, {
    commandId: "command.shop-effective-second",
    occurredAt: "2026-08-07T04:00:00.000Z",
    payload: policyPayload({
      responseWindowSeconds: 90,
      overallAssignmentCeilingSeconds: 270,
      effectiveFrom: "2026-08-09T03:00:00.000Z",
    }),
  });
  const query = (at: string) =>
    effectiveAcceptanceSlaPolicyAt({
      policySet: second.policySet,
      tenantId: TENANT_ID,
      policySetId: POLICY_SET_ID,
      actor: adminActor(),
      family: "shop",
      at,
    });
  assert.equal(query("2026-08-08T02:59:59.999Z"), null);
  assert.equal(query("2026-08-08T03:00:00.000Z")?.aggregateVersion, 2);
  assert.equal(query("2026-08-09T02:59:59.999Z")?.aggregateVersion, 2);
  assert.equal(query("2026-08-09T03:00:00.000Z")?.aggregateVersion, 3);
  assert.equal(
    effectiveAcceptanceSlaPolicyAt({
      policySet: second.policySet,
      tenantId: TENANT_ID,
      policySetId: POLICY_SET_ID,
      actor: adminActor(),
      family: "wholesale",
      at: "2026-08-10T03:00:00.000Z",
    }),
    null,
  );
});

test("effective-at enforces tenant and aggregate binding", () => {
  const policySet = publish(emptyPolicySet()).policySet;
  expectPolicyCode(
    () =>
      effectiveAcceptanceSlaPolicyAt({
        policySet,
        tenantId: "tenant.other-001",
        policySetId: POLICY_SET_ID,
        actor: adminActor(),
        family: "shop",
        at: "2026-08-09T03:00:00.000Z",
      }),
    "tenant_mismatch",
  );
  expectPolicyCode(
    () =>
      effectiveAcceptanceSlaPolicyAt({
        policySet,
        tenantId: TENANT_ID,
        policySetId: "acceptance-policy.other-001",
        actor: adminActor(),
        family: "shop",
        at: "2026-08-09T03:00:00.000Z",
      }),
    "aggregate_mismatch",
  );
});

test("does not mutate inputs and returns deeply immutable revisions and evidence", () => {
  const mutableInput = JSON.parse(JSON.stringify(emptyPolicySet())) as AcceptanceSlaPolicySet;
  const before = JSON.stringify(mutableInput);
  const result = publish(mutableInput);
  assert.equal(JSON.stringify(mutableInput), before);
  assert.equal(Object.isFrozen(result), true);
  assert.equal(Object.isFrozen(result.policySet), true);
  assert.equal(Object.isFrozen(result.policySet.revisions), true);
  assert.equal(Object.isFrozen(result.revision), true);
  assert.equal(Object.isFrozen(result.receipt), true);
  assert.equal(Object.isFrozen(result.policySet.auditEvents[0]), true);
  assert.throws(() => {
    const mutable = result.revision as unknown as { responseWindowSeconds: number };
    mutable.responseWindowSeconds = 999;
  }, TypeError);
});

test("audit contains governed identifiers and hashes without personal or secret payload", () => {
  const result = publish(emptyPolicySet());
  const audit = result.policySet.auditEvents[0];
  assert.ok(audit);
  assert.equal(audit.commandFingerprint.length, 64);
  assert.equal(audit.revisionId, result.revision.revisionId);
  assert.deepEqual(Object.keys(audit).sort(), [
    "actorId",
    "aggregateVersion",
    "commandFingerprint",
    "commandId",
    "eventId",
    "eventType",
    "family",
    "occurredAt",
    "policySetId",
    "revisionId",
    "schemaVersion",
    "tenantId",
  ]);
  assert.doesNotMatch(
    JSON.stringify(audit),
    /email|phone|prescription|message|secret|token|password/iu,
  );
  assert.match(result.receipt.resultSha256, /^[A-F0-9]{64}$/u);
});
