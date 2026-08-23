import assert from "node:assert/strict";
import test from "node:test";

import {
  createAcceptanceSlaPolicySet,
  publishAcceptanceSlaPolicy,
  type AcceptanceSlaPolicyPayload,
  type BuyAcceptanceSlaFamily,
} from "./acceptance_sla_policy_contract.js";
import {
  createAcceptanceSlaScheduleOverrideSet,
  publishAcceptanceSlaScheduleOverride,
  type AcceptanceSlaScheduleOverridePayload,
} from "./acceptance_sla_schedule_override_contract.js";
import {
  OrderTimerPolicySnapshotError,
  createOrderTimerPolicySnapshot,
  createPendingOrderTimerPolicySnapshotAggregate,
  projectOrderTimerProgress,
  type CreateOrderTimerPolicySnapshotCommand,
  type OrderTimerPolicySnapshotAggregate,
  type OrderTimerPolicySnapshotCommandPayload,
  type OrderTimerPolicySnapshotErrorCode,
  type ResolvedOrderTimerPolicySource,
} from "./order_timer_policy_snapshot_contract.js";
import {
  PrivilegedCommandError,
  type PrivilegedCommandErrorCode,
} from "../workspace/privileged_command_contract.js";

const TENANT_ID = "tenant.india-001";
const ORDER_ID = "order.customer-001";
const POLICY_SET_ID = "acceptance-policy.global-001";
const OVERRIDE_SET_ID = "acceptance-schedule.global-001";
const ADMIN_SCOPE = "commerce.fulfilment_policy.admin";
const ORCHESTRATOR_SCOPE = "commerce.order_assignment.timer_snapshot";

interface TimingInput {
  readonly responseWindowSeconds: number;
  readonly maximumSequentialPartners: number;
  readonly overallAssignmentCeilingSeconds: number;
}

function globalSource(
  family: BuyAcceptanceSlaFamily = "shop",
  timing: TimingInput = {
    responseWindowSeconds: 60,
    maximumSequentialPartners: 3,
    overallAssignmentCeilingSeconds: 180,
  },
): ResolvedOrderTimerPolicySource {
  const policySet = createAcceptanceSlaPolicySet({
    tenantId: TENANT_ID,
    policySetId: POLICY_SET_ID,
  });
  const payload: AcceptanceSlaPolicyPayload = {
    family,
    ...timing,
    effectiveFrom: "2026-08-07T03:00:00.000Z",
    reasonCode: "ops.snapshot-source",
  };
  const result = publishAcceptanceSlaPolicy({
    policySet,
    command: {
      schemaVersion: 1,
      commandId: `command.global-${family}`,
      aggregateId: POLICY_SET_ID,
      expectedVersion: 1,
      occurredAt: "2026-08-07T02:00:00.000Z",
      confirmed: true,
      reason: "Publish the exact source policy for snapshot tests.",
      actor: {
        actorId: "admin.commerce-policy-001",
        tenantId: TENANT_ID,
        scopes: [ADMIN_SCOPE],
      },
      payload,
    },
  });
  return Object.freeze({
    kind: "global",
    policySetId: POLICY_SET_ID,
    policyRevision: result.revision,
  });
}

function overrideSource(
  family: BuyAcceptanceSlaFamily = "shop",
): ResolvedOrderTimerPolicySource {
  const base = globalSource(family);
  assert.equal(base.kind, "global");
  const overrideSet = createAcceptanceSlaScheduleOverrideSet({
    tenantId: TENANT_ID,
    overrideSetId: OVERRIDE_SET_ID,
  });
  const payload: AcceptanceSlaScheduleOverridePayload = {
    overrideId: `override.snapshot-${family}`,
    state: "enabled",
    family,
    marketTypeId: "market.grocery",
    providerTypeId: null,
    categoryId: null,
    localityId: null,
    weekdays: null,
    timeZone: null,
    startMinuteInclusive: null,
    endMinuteExclusive: null,
    readinessState: null,
    responseWindowSeconds: 90,
    maximumSequentialPartners: 3,
    overallAssignmentCeilingSeconds: 270,
    effectiveFrom: "2026-08-07T03:15:00.000Z",
    reasonCode: "ops.snapshot-override",
  };
  const result = publishAcceptanceSlaScheduleOverride({
    overrideSet,
    command: {
      schemaVersion: 1,
      commandId: `command.override-${family}`,
      aggregateId: OVERRIDE_SET_ID,
      expectedVersion: 1,
      occurredAt: "2026-08-07T02:30:00.000Z",
      confirmed: true,
      reason: "Publish the exact override source for snapshot tests.",
      actor: {
        actorId: "admin.commerce-policy-001",
        tenantId: TENANT_ID,
        scopes: [ADMIN_SCOPE],
      },
      payload,
    },
  });
  return Object.freeze({
    kind: "override",
    policySetId: POLICY_SET_ID,
    policyRevision: base.policyRevision,
    overrideSetId: OVERRIDE_SET_ID,
    overrideRevision: result.revision,
  });
}

function pendingAggregate(): OrderTimerPolicySnapshotAggregate {
  return createPendingOrderTimerPolicySnapshotAggregate({
    tenantId: TENANT_ID,
    orderId: ORDER_ID,
  });
}

function snapshotPayload(
  source: ResolvedOrderTimerPolicySource,
  overrides: Partial<OrderTimerPolicySnapshotCommandPayload> = {},
): OrderTimerPolicySnapshotCommandPayload {
  const base = {
    orderId: ORDER_ID,
    family: source.policyRevision.family,
    assignmentStartsAt: "2026-08-07T04:00:00.000Z",
    policySetId: source.policySetId,
    globalRevisionId: source.policyRevision.revisionId,
    globalAggregateVersion: source.policyRevision.aggregateVersion,
    globalCommandFingerprint: source.policyRevision.commandFingerprint,
  };
  return {
    ...base,
    ...(source.kind === "global"
      ? {
          sourceKind: "global" as const,
          overrideSetId: null,
          overrideRevisionId: null,
          overrideAggregateVersion: null,
          overrideSelectorFingerprint: null,
          overrideCommandFingerprint: null,
        }
      : {
          sourceKind: "override" as const,
          overrideSetId: source.overrideSetId,
          overrideRevisionId: source.overrideRevision.revisionId,
          overrideAggregateVersion: source.overrideRevision.aggregateVersion,
          overrideSelectorFingerprint: source.overrideRevision.selectorFingerprint,
          overrideCommandFingerprint: source.overrideRevision.commandFingerprint,
        }),
    ...overrides,
  };
}

function snapshotCommand(
  aggregate: OrderTimerPolicySnapshotAggregate,
  source: ResolvedOrderTimerPolicySource,
  overrides: Partial<CreateOrderTimerPolicySnapshotCommand> = {},
): CreateOrderTimerPolicySnapshotCommand {
  return {
    schemaVersion: 1,
    commandId: "command.order-timer-snapshot-001",
    aggregateId: aggregate.orderId,
    expectedVersion: aggregate.version,
    occurredAt: "2026-08-07T03:30:00.000Z",
    confirmed: true,
    reason: "Freeze the reviewed effective timer policy before assignment.",
    actor: {
      actorId: "orchestrator.assignment-001",
      tenantId: aggregate.tenantId,
      scopes: [ORCHESTRATOR_SCOPE],
    },
    payload: snapshotPayload(source),
    ...overrides,
  };
}

function createSnapshot(
  aggregate: OrderTimerPolicySnapshotAggregate = pendingAggregate(),
  source: ResolvedOrderTimerPolicySource = globalSource(),
  overrides: Partial<CreateOrderTimerPolicySnapshotCommand> = {},
) {
  return createOrderTimerPolicySnapshot({
    aggregate,
    source,
    command: snapshotCommand(aggregate, source, overrides),
  });
}

function orchestrator(scopes: readonly string[] = [ORCHESTRATOR_SCOPE]) {
  return {
    actorId: "orchestrator.assignment-001",
    tenantId: TENANT_ID,
    scopes,
  };
}

function progress(
  aggregate: OrderTimerPolicySnapshotAggregate,
  at: string,
) {
  return projectOrderTimerProgress({
    aggregate,
    tenantId: TENANT_ID,
    orderId: ORDER_ID,
    actor: orchestrator(),
    at,
  });
}

function expectSnapshotCode(
  callback: () => unknown,
  code: OrderTimerPolicySnapshotErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof OrderTimerPolicySnapshotError && error.code === code,
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

test("creates one immutable pending order timer aggregate", () => {
  const aggregate = pendingAggregate();
  assert.equal(aggregate.version, 1);
  assert.equal(aggregate.snapshot, null);
  assert.equal(Object.isFrozen(aggregate), true);
  assert.equal(Object.isFrozen(aggregate.receipts), true);
});

test("freezes a global policy into exact absolute attempt instants", () => {
  const result = createSnapshot();
  assert.equal(result.snapshot.provenance.kind, "global");
  assert.equal(result.snapshot.attempts.length, 3);
  assert.deepEqual(result.snapshot.attempts[0], {
    attemptNumber: 1,
    startsAt: "2026-08-07T04:00:00.000Z",
    moolChatAt: "2026-08-07T04:00:00.000Z",
    whatsAppAt: "2026-08-07T04:00:20.000Z",
    agenticCallAt: "2026-08-07T04:00:40.000Z",
    expiresAt: "2026-08-07T04:01:00.000Z",
    reassignAt: "2026-08-07T04:01:00.000Z",
  });
  assert.equal(
    result.snapshot.attempts[2]?.expiresAt,
    result.snapshot.overallAssignmentEndsAt,
  );
  assert.equal(result.snapshot.overallAssignmentEndsAt, "2026-08-07T04:03:00.000Z");
});

test("supports all four exact families without mixing identity", () => {
  const families = [
    "shop",
    "wholesale",
    "medicine_non_prescription",
    "medicine_prescription_pharmacist_ready",
  ] as const;
  for (const family of families) {
    const aggregate = createPendingOrderTimerPolicySnapshotAggregate({
      tenantId: TENANT_ID,
      orderId: `order.${family}`,
    });
    const source = globalSource(family);
    const result = createOrderTimerPolicySnapshot({
      aggregate,
      source,
      command: snapshotCommand(aggregate, source, {
        commandId: `command.snapshot-${family}`,
        payload: snapshotPayload(source, { orderId: aggregate.orderId }),
      }),
    });
    assert.equal(result.snapshot.family, family);
  }
});

test("freezes exact override provenance and override timing facts", () => {
  const source = overrideSource();
  const result = createSnapshot(pendingAggregate(), source);
  assert.equal(result.snapshot.provenance.kind, "override");
  assert.equal(result.snapshot.responseWindowSeconds, 90);
  assert.equal(result.snapshot.whatsAppOffsetSeconds, 30);
  assert.equal(result.snapshot.overallAssignmentEndsAt, "2026-08-07T04:04:30.000Z");
  if (result.snapshot.provenance.kind === "override") {
    assert.equal(
      result.snapshot.provenance.overrideSelectorFingerprint,
      source.kind === "override" ? source.overrideRevision.selectorFingerprint : "",
    );
  }
});

test("rejects command source identity, family and fingerprint mismatch", () => {
  const source = globalSource();
  for (const payload of [
    snapshotPayload(source, { policySetId: "acceptance-policy.other-001" }),
    snapshotPayload(source, { family: "wholesale" }),
    snapshotPayload(source, { globalCommandFingerprint: "A".repeat(64) }),
  ]) {
    expectSnapshotCode(
      () => createSnapshot(pendingAggregate(), source, { payload }),
      "source_mismatch",
    );
  }
});

test("rejects mixed or incomplete global and override provenance", () => {
  const source = globalSource();
  expectSnapshotCode(
    () =>
      createSnapshot(pendingAggregate(), source, {
        payload: snapshotPayload(source, {
          overrideSetId: OVERRIDE_SET_ID,
        }),
      }),
    "source_mismatch",
  );
  const override = overrideSource();
  expectSnapshotCode(
    () =>
      createSnapshot(pendingAggregate(), override, {
        payload: snapshotPayload(override, { overrideRevisionId: null }),
      }),
    "source_mismatch",
  );
});

test("rejects a source not effective at assignment and a backdated start", () => {
  const source = globalSource();
  expectSnapshotCode(
    () =>
      createSnapshot(pendingAggregate(), source, {
        payload: snapshotPayload(source, {
          assignmentStartsAt: "2026-08-07T02:59:59.999Z",
        }),
      }),
    "source_not_effective",
  );
  expectSnapshotCode(
    () =>
      createSnapshot(pendingAggregate(), source, {
        occurredAt: "2026-08-07T04:00:01.000Z",
      }),
    "timing_conflict",
  );
  const override = overrideSource();
  assert.equal(override.kind, "override");
  const futureBase = {
    ...override,
    policyRevision: {
      ...override.policyRevision,
      effectiveFrom: "2026-08-07T05:00:00.000Z",
    },
  };
  expectSnapshotCode(
    () => createSnapshot(pendingAggregate(), futureBase),
    "source_not_effective",
  );
});

test("authorization denies before hidden snapshot values and stale version", () => {
  const base = pendingAggregate();
  const hidden = {
    ...base,
    get snapshot(): never {
      throw new Error("snapshot values were accessed");
    },
  } as unknown as OrderTimerPolicySnapshotAggregate;
  const source = globalSource();
  expectCommandCode(
    () =>
      createOrderTimerPolicySnapshot({
        aggregate: hidden,
        source,
        command: snapshotCommand(base, source, {
          expectedVersion: 99,
          actor: { ...orchestrator(), scopes: [] },
        }),
      }),
    "unauthorized",
  );
});

test("exact retry returns one snapshot while conflict and stale race fail", () => {
  const aggregate = pendingAggregate();
  const source = globalSource();
  const originalCommand = snapshotCommand(aggregate, source);
  const first = createOrderTimerPolicySnapshot({ aggregate, source, command: originalCommand });
  const retry = createOrderTimerPolicySnapshot({
    aggregate: first.aggregate,
    source,
    command: originalCommand,
  });
  assert.equal(retry.replayed, true);
  assert.deepEqual(retry.snapshot, first.snapshot);
  assert.equal(retry.aggregate.auditEvents.length, 1);
  expectCommandCode(
    () =>
      createOrderTimerPolicySnapshot({
        aggregate: first.aggregate,
        source,
        command: {
          ...originalCommand,
          payload: snapshotPayload(source, {
            assignmentStartsAt: "2026-08-07T04:01:00.000Z",
          }),
        },
      }),
    "idempotency_conflict",
  );
  expectCommandCode(
    () =>
      createOrderTimerPolicySnapshot({
        aggregate: first.aggregate,
        source,
        command: snapshotCommand(aggregate, source, {
          commandId: "command.concurrent-second",
        }),
      }),
    "version_conflict",
  );
});

test("a second newly authorized snapshot cannot edit the active snapshot", () => {
  const first = createSnapshot();
  const source = globalSource();
  expectSnapshotCode(
    () =>
      createOrderTimerPolicySnapshot({
        aggregate: first.aggregate,
        source,
        command: snapshotCommand(first.aggregate, source, {
          commandId: "command.second-snapshot",
          payload: snapshotPayload(source),
        }),
      }),
    "invalid_state",
  );
});

test("projects every exact escalation and reassignment boundary", () => {
  const aggregate = createSnapshot().aggregate;
  assert.equal(progress(aggregate, "2026-08-07T03:59:59.999Z").state, "before_start");
  assert.deepEqual(progress(aggregate, "2026-08-07T04:00:00.000Z"), {
    state: "attempt_active",
    snapshotId: "order-timer-snapshot:2",
    attemptNumber: 1,
    phase: "moolchat_only",
    attemptStartsAt: "2026-08-07T04:00:00.000Z",
    attemptExpiresAt: "2026-08-07T04:01:00.000Z",
    remainingSeconds: 60,
  });
  const whatsApp = progress(aggregate, "2026-08-07T04:00:20.000Z");
  assert.equal(whatsApp.state, "attempt_active");
  if (whatsApp.state === "attempt_active") {
    assert.equal(whatsApp.phase, "whatsapp_escalated");
  }
  const call = progress(aggregate, "2026-08-07T04:00:40.000Z");
  assert.equal(call.state, "attempt_active");
  if (call.state === "attempt_active") {
    assert.equal(call.phase, "agentic_call_escalated");
  }
  const second = progress(aggregate, "2026-08-07T04:01:00.000Z");
  assert.equal(second.state, "attempt_active");
  if (second.state === "attempt_active") assert.equal(second.attemptNumber, 2);
  assert.equal(
    progress(aggregate, "2026-08-07T04:03:00.000Z").state,
    "assignment_ceiling_reached",
  );
});

test("five-attempt maximum ends exactly at the derived ceiling", () => {
  const source = globalSource("shop", {
    responseWindowSeconds: 300,
    maximumSequentialPartners: 5,
    overallAssignmentCeilingSeconds: 1500,
  });
  const snapshot = createSnapshot(pendingAggregate(), source).snapshot;
  assert.equal(snapshot.attempts.length, 5);
  assert.equal(snapshot.attempts[4]?.expiresAt, snapshot.overallAssignmentEndsAt);
  assert.equal(snapshot.attempts[4]?.reassignAt, null);
  assert.equal(snapshot.overallAssignmentEndsAt, "2026-08-07T04:25:00.000Z");
});

test("JSON restart preserves the exact deterministic progress projection", () => {
  const original = createSnapshot().aggregate;
  const restarted = JSON.parse(JSON.stringify(original)) as OrderTimerPolicySnapshotAggregate;
  assert.deepEqual(
    progress(restarted, "2026-08-07T04:01:40.000Z"),
    progress(original, "2026-08-07T04:01:40.000Z"),
  );
});

test("restart rejects tampered nested provenance and audit binding", () => {
  const original = createSnapshot().aggregate;
  const tampered = JSON.parse(JSON.stringify(original)) as OrderTimerPolicySnapshotAggregate;
  const mutable = tampered.snapshot as unknown as {
    provenance: Record<string, unknown>;
  };
  mutable.provenance.extra = "untrusted";
  expectSnapshotCode(
    () => progress(tampered, "2026-08-07T04:00:00.000Z"),
    "invalid_input",
  );
  const auditTampered = JSON.parse(JSON.stringify(original)) as OrderTimerPolicySnapshotAggregate;
  const audit = auditTampered.auditEvents[0] as unknown as {
    sourceRevisionFingerprint: string;
  };
  audit.sourceRevisionFingerprint = "A".repeat(64);
  expectSnapshotCode(
    () => progress(auditTampered, "2026-08-07T04:00:00.000Z"),
    "invalid_input",
  );
  const timeTampered = JSON.parse(JSON.stringify(original)) as OrderTimerPolicySnapshotAggregate;
  const snapshot = timeTampered.snapshot as unknown as { createdAt: string };
  const receipt = timeTampered.receipts[0] as unknown as { completedAt: string };
  const timeAudit = timeTampered.auditEvents[0] as unknown as { occurredAt: string };
  snapshot.createdAt = "2026-08-07T04:00:00.001Z";
  receipt.completedAt = snapshot.createdAt;
  timeAudit.occurredAt = snapshot.createdAt;
  expectSnapshotCode(
    () => progress(timeTampered, "2026-08-07T04:00:01.000Z"),
    "invalid_input",
  );
});

test("rejects a disabled or malformed resolved override source", () => {
  const source = overrideSource();
  assert.equal(source.kind, "override");
  const disabled = {
    ...source,
    overrideRevision: { ...source.overrideRevision, state: "disabled" as const },
  };
  expectSnapshotCode(
    () => createSnapshot(pendingAggregate(), disabled),
    "source_mismatch",
  );
  const badOffsets = {
    ...source,
    overrideRevision: {
      ...source.overrideRevision,
      whatsAppOffsetSeconds: 1,
    },
  };
  expectSnapshotCode(
    () => createSnapshot(pendingAggregate(), badOffsets),
    "source_mismatch",
  );
});

test("progress authorization denies before hidden values and binds tenant", () => {
  const base = createSnapshot().aggregate;
  const hidden = {
    ...base,
    get snapshot(): never {
      throw new Error("snapshot values were accessed");
    },
  } as unknown as OrderTimerPolicySnapshotAggregate;
  expectSnapshotCode(
    () =>
      projectOrderTimerProgress({
        aggregate: hidden,
        tenantId: TENANT_ID,
        orderId: ORDER_ID,
        actor: orchestrator([]),
        at: "2026-08-07T04:00:00.000Z",
      }),
    "unauthorized",
  );
  expectSnapshotCode(
    () =>
      projectOrderTimerProgress({
        aggregate: base,
        tenantId: "tenant.other-001",
        orderId: ORDER_ID,
        actor: orchestrator(),
        at: "2026-08-07T04:00:00.000Z",
      }),
    "tenant_mismatch",
  );
});

test("pending progress and noncanonical clock fail explicitly", () => {
  expectSnapshotCode(
    () => progress(pendingAggregate(), "2026-08-07T04:00:00.000Z"),
    "invalid_state",
  );
  const complete = createSnapshot().aggregate;
  expectSnapshotCode(
    () => progress(complete, "2026-08-07T04:00:00Z"),
    "invalid_input",
  );
});

test("snapshot remains independent of later source objects", () => {
  const source = globalSource();
  const result = createSnapshot(pendingAggregate(), source);
  const before = JSON.stringify(result.snapshot);
  const mutableSource = JSON.parse(JSON.stringify(source)) as {
    policyRevision: { responseWindowSeconds: number };
  };
  mutableSource.policyRevision.responseWindowSeconds = 300;
  assert.equal(JSON.stringify(result.snapshot), before);
  assert.equal(result.snapshot.responseWindowSeconds, 60);
});

test("does not mutate inputs and returns immutable payload-free evidence", () => {
  const aggregate = JSON.parse(JSON.stringify(pendingAggregate())) as OrderTimerPolicySnapshotAggregate;
  const source = globalSource();
  const beforeAggregate = JSON.stringify(aggregate);
  const beforeSource = JSON.stringify(source);
  const result = createSnapshot(aggregate, source);
  assert.equal(JSON.stringify(aggregate), beforeAggregate);
  assert.equal(JSON.stringify(source), beforeSource);
  assert.equal(Object.isFrozen(result), true);
  assert.equal(Object.isFrozen(result.snapshot), true);
  assert.equal(Object.isFrozen(result.snapshot.attempts), true);
  assert.equal(Object.isFrozen(result.snapshot.provenance), true);
  assert.equal(Object.isFrozen(result.receipt), true);
  assert.equal(Object.isFrozen(result.aggregate.auditEvents[0]), true);
  assert.doesNotMatch(
    JSON.stringify(result.aggregate.auditEvents[0]),
    /email|phone|prescription|message|secret|token|password|payment/iu,
  );
  assert.throws(() => {
    const target = result.snapshot as unknown as { responseWindowSeconds: number };
    target.responseWindowSeconds = 999;
  }, TypeError);
});
