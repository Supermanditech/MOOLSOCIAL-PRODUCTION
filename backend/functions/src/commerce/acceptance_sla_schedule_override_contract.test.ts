import assert from "node:assert/strict";
import test from "node:test";

import { AcceptanceSlaPolicyError } from "./acceptance_sla_policy_contract.js";
import {
  AcceptanceSlaScheduleOverrideError,
  createAcceptanceSlaScheduleOverrideSet,
  publishAcceptanceSlaScheduleOverride,
  resolveAcceptanceSlaScheduleOverride,
  type AcceptanceSlaScheduleOverrideErrorCode,
  type AcceptanceSlaScheduleOverridePayload,
  type AcceptanceSlaScheduleOverrideSet,
  type PublishAcceptanceSlaScheduleOverrideCommand,
} from "./acceptance_sla_schedule_override_contract.js";
import {
  PrivilegedCommandError,
  type PrivilegedCommandErrorCode,
} from "../workspace/privileged_command_contract.js";

const TENANT_ID = "tenant.india-001";
const SET_ID = "acceptance-schedule.global-001";
const ADMIN_SCOPE = "commerce.fulfilment_policy.admin";

function emptySet(): AcceptanceSlaScheduleOverrideSet {
  return createAcceptanceSlaScheduleOverrideSet({
    tenantId: TENANT_ID,
    overrideSetId: SET_ID,
  });
}

function overridePayload(
  overrides: Partial<AcceptanceSlaScheduleOverridePayload> = {},
): AcceptanceSlaScheduleOverridePayload {
  return {
    overrideId: "override.market-grocery-001",
    state: "enabled",
    family: "shop",
    marketTypeId: "market.grocery",
    providerTypeId: null,
    categoryId: null,
    localityId: null,
    weekdays: null,
    timeZone: null,
    startMinuteInclusive: null,
    endMinuteExclusive: null,
    readinessState: null,
    responseWindowSeconds: 60,
    maximumSequentialPartners: 3,
    overallAssignmentCeilingSeconds: 180,
    effectiveFrom: "2026-08-08T03:00:00.000Z",
    reasonCode: "ops.market-schedule",
    ...overrides,
  };
}

function command(
  overrideSet: AcceptanceSlaScheduleOverrideSet,
  overrides: Partial<PublishAcceptanceSlaScheduleOverrideCommand> = {},
): PublishAcceptanceSlaScheduleOverrideCommand {
  return {
    schemaVersion: 1,
    commandId: `command.schedule-override-${overrideSet.version}`,
    aggregateId: overrideSet.overrideSetId,
    expectedVersion: overrideSet.version,
    occurredAt: "2026-08-07T03:00:00.000Z",
    confirmed: true,
    reason: "Publish one reviewed future-order schedule override.",
    actor: {
      actorId: "admin.commerce-policy-001",
      tenantId: overrideSet.tenantId,
      scopes: [ADMIN_SCOPE],
    },
    payload: overridePayload(),
    ...overrides,
  };
}

function publish(
  overrideSet: AcceptanceSlaScheduleOverrideSet,
  overrides: Partial<PublishAcceptanceSlaScheduleOverrideCommand> = {},
) {
  return publishAcceptanceSlaScheduleOverride({
    overrideSet,
    command: command(overrideSet, overrides),
  });
}

function adminActor(scopes: readonly string[] = [ADMIN_SCOPE]) {
  return {
    actorId: "admin.commerce-policy-001",
    tenantId: TENANT_ID,
    scopes,
  };
}

function resolve(
  overrideSet: AcceptanceSlaScheduleOverrideSet,
  context: Partial<Parameters<typeof resolveAcceptanceSlaScheduleOverride>[0]["context"]> = {},
) {
  return resolveAcceptanceSlaScheduleOverride({
    overrideSet,
    tenantId: TENANT_ID,
    overrideSetId: SET_ID,
    actor: adminActor(),
    context: {
      family: "shop",
      marketTypeId: "market.grocery",
      providerTypeId: "provider.kirana",
      categoryId: "category.staples",
      localityId: "locality.bengaluru-east",
      declaredBusy: false,
      at: "2026-08-10T03:00:00.000Z",
      ...context,
    },
  });
}

function expectScheduleCode(
  callback: () => unknown,
  code: AcceptanceSlaScheduleOverrideErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof AcceptanceSlaScheduleOverrideError && error.code === code,
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

test("creates one empty tenant-scoped deeply immutable override set", () => {
  const overrideSet = emptySet();
  assert.equal(overrideSet.version, 1);
  assert.equal(overrideSet.tenantId, TENANT_ID);
  assert.equal(Object.isFrozen(overrideSet), true);
  assert.equal(Object.isFrozen(overrideSet.revisions), true);
});

test("accepts all approved selector dimensions in one exact override", () => {
  const result = publish(emptySet(), {
    payload: overridePayload({
      providerTypeId: "provider.kirana",
      categoryId: "category.staples",
      localityId: "locality.bengaluru-east",
      weekdays: [1, 3, 5],
      timeZone: "Asia/Kolkata",
      startMinuteInclusive: 540,
      endMinuteExclusive: 1020,
      readinessState: "declared_busy",
    }),
  });
  assert.deepEqual(result.revision.selector.weekdays, [1, 3, 5]);
  assert.equal(result.revision.selector.timeZone, "Asia/Calcutta");
  assert.equal(result.revision.selector.readinessState, "declared_busy");
  assert.equal(result.revision.selectorFingerprint.length, 64);
});

test("keeps all four exact Buy families isolated", () => {
  let overrideSet = emptySet();
  const families = [
    "shop",
    "wholesale",
    "medicine_non_prescription",
    "medicine_prescription_pharmacist_ready",
  ] as const;
  families.forEach((family, index) => {
    const result = publish(overrideSet, {
      commandId: `command.family-${index + 1}`,
      occurredAt: `2026-08-07T03:0${index}:00.000Z`,
      payload: overridePayload({
        overrideId: `override.family-${index + 1}`,
        family,
      }),
    });
    overrideSet = result.overrideSet;
  });
  assert.deepEqual(
    overrideSet.revisions.map((item) => item.selector.family),
    families,
  );
  assert.equal(
    resolve(overrideSet, { family: "wholesale" }).kind,
    "override",
  );
});

test("rejects a global selector and unsupported generic family", () => {
  expectScheduleCode(
    () =>
      publish(emptySet(), {
        payload: overridePayload({ marketTypeId: null }),
      }),
    "invalid_input",
  );
  expectScheduleCode(
    () =>
      publish(emptySet(), {
        payload: overridePayload({ family: "generic_service" as "shop" }),
      }),
    "unsupported_family",
  );
});

test("rejects partial, invalid and zero-duration schedule fields", () => {
  expectScheduleCode(
    () =>
      publish(emptySet(), {
        payload: overridePayload({ weekdays: [1] }),
      }),
    "invalid_schedule",
  );
  for (const payload of [
    overridePayload({
      weekdays: [1, 1],
      timeZone: "Asia/Kolkata",
      startMinuteInclusive: 540,
      endMinuteExclusive: 600,
    }),
    overridePayload({
      weekdays: [1],
      timeZone: "Not/A_Real_Zone",
      startMinuteInclusive: 540,
      endMinuteExclusive: 600,
    }),
    overridePayload({
      weekdays: [1],
      timeZone: "Asia/Kolkata",
      startMinuteInclusive: 540,
      endMinuteExclusive: 540,
    }),
  ]) {
    expectScheduleCode(
      () => publish(emptySet(), { payload }),
      "invalid_schedule",
    );
  }
});

test("reuses Ticket 1 bounds and deterministic timeline derivation", () => {
  const result = publish(emptySet(), {
    payload: overridePayload({
      responseWindowSeconds: 300,
      maximumSequentialPartners: 5,
      overallAssignmentCeilingSeconds: 1500,
    }),
  });
  assert.equal(result.revision.whatsAppOffsetSeconds, 100);
  assert.equal(result.revision.agenticCallOffsetSeconds, 200);
  assert.equal(result.revision.reassignAtSeconds, 300);
  assert.throws(
    () =>
      publish(emptySet(), {
        payload: overridePayload({ responseWindowSeconds: 301 }),
      }),
    (error: unknown) =>
      error instanceof AcceptanceSlaPolicyError && error.code === "policy_bounds",
  );
});

test("authorization denies before hidden override values and stale version", () => {
  const base = emptySet();
  const hidden = {
    ...base,
    get revisions(): readonly never[] {
      throw new Error("override values were accessed");
    },
  } as unknown as AcceptanceSlaScheduleOverrideSet;
  expectCommandCode(
    () =>
      publishAcceptanceSlaScheduleOverride({
        overrideSet: hidden,
        command: command(base, {
          expectedVersion: 99,
          actor: { ...adminActor(), scopes: [] },
        }),
      }),
    "unauthorized",
  );
});

test("exact retry is idempotent while changed retry and stale race fail", () => {
  const initial = emptySet();
  const originalCommand = command(initial);
  const first = publishAcceptanceSlaScheduleOverride({
    overrideSet: initial,
    command: originalCommand,
  });
  const retry = publishAcceptanceSlaScheduleOverride({
    overrideSet: first.overrideSet,
    command: originalCommand,
  });
  assert.equal(retry.replayed, true);
  assert.equal(retry.overrideSet.revisions.length, 1);
  assert.deepEqual(retry.receipt, first.receipt);
  expectCommandCode(
    () =>
      publishAcceptanceSlaScheduleOverride({
        overrideSet: first.overrideSet,
        command: {
          ...originalCommand,
          payload: overridePayload({ responseWindowSeconds: 90 }),
        },
      }),
    "idempotency_conflict",
  );
  expectCommandCode(
    () =>
      publishAcceptanceSlaScheduleOverride({
        overrideSet: first.overrideSet,
        command: command(initial, { commandId: "command.concurrent-second" }),
      }),
    "version_conflict",
  );
});

test("accepts effective-now but rejects backdating and same-override overlap", () => {
  const first = publish(emptySet(), {
    occurredAt: "2026-08-07T03:00:00.000Z",
    payload: overridePayload({ effectiveFrom: "2026-08-07T03:00:00.000Z" }),
  });
  assert.equal(first.revision.effectiveFrom, first.revision.publishedAt);
  expectScheduleCode(
    () =>
      publish(emptySet(), {
        payload: overridePayload({ effectiveFrom: "2026-08-07T02:59:59.999Z" }),
      }),
    "effective_time_conflict",
  );
  expectScheduleCode(
    () =>
      publish(first.overrideSet, {
        payload: overridePayload({ effectiveFrom: "2026-08-07T03:00:00.000Z" }),
      }),
    "effective_time_conflict",
  );
});

test("more qualifiers win and publishing returns an overlap warning", () => {
  const broad = publish(emptySet());
  const specific = publish(broad.overrideSet, {
    commandId: "command.locality-specific",
    payload: overridePayload({
      overrideId: "override.locality-001",
      localityId: "locality.bengaluru-east",
      responseWindowSeconds: 90,
      overallAssignmentCeilingSeconds: 270,
    }),
  });
  assert.deepEqual(specific.overlapWarningOverrideIds, [
    "override.market-grocery-001",
  ]);
  const resolution = resolve(specific.overrideSet);
  assert.equal(resolution.kind, "override");
  if (resolution.kind === "override") {
    assert.equal(resolution.revision.overrideId, "override.locality-001");
  }
  const otherLocality = resolve(specific.overrideSet, {
    localityId: "locality.mysuru",
  });
  assert.equal(otherLocality.kind, "override");
  if (otherLocality.kind === "override") {
    assert.equal(otherLocality.revision.overrideId, "override.market-grocery-001");
  }
});

test("fixed dimension vector breaks equal-count ties deterministically", () => {
  const category = publish(emptySet(), {
    payload: overridePayload({
      overrideId: "override.market-category-001",
      categoryId: "category.staples",
    }),
  });
  const locality = publish(category.overrideSet, {
    commandId: "command.market-locality",
    payload: overridePayload({
      overrideId: "override.market-locality-001",
      localityId: "locality.bengaluru-east",
    }),
  });
  const resolution = resolve(locality.overrideSet);
  assert.equal(resolution.kind, "override");
  if (resolution.kind === "override") {
    assert.equal(resolution.revision.overrideId, "override.market-locality-001");
  }
});

test("rejects equal-vector intersecting overrides but accepts disjoint scope", () => {
  const first = publish(emptySet());
  expectScheduleCode(
    () =>
      publish(first.overrideSet, {
        commandId: "command.ambiguous-market",
        payload: overridePayload({ overrideId: "override.same-market-002" }),
      }),
    "ambiguous_precedence",
  );
  const disjoint = publish(first.overrideSet, {
    commandId: "command.disjoint-market",
    payload: overridePayload({
      overrideId: "override.market-wholesale-001",
      marketTypeId: "market.wholesale",
    }),
  });
  assert.deepEqual(disjoint.overlapWarningOverrideIds, []);
});

test("Kolkata time band includes its start and excludes its end", () => {
  const scheduled = publish(emptySet(), {
    payload: overridePayload({
      weekdays: [1],
      timeZone: "Asia/Kolkata",
      startMinuteInclusive: 540,
      endMinuteExclusive: 600,
    }),
  }).overrideSet;
  assert.equal(resolve(scheduled, { at: "2026-08-10T03:30:00.000Z" }).kind, "override");
  assert.equal(resolve(scheduled, { at: "2026-08-10T04:29:59.999Z" }).kind, "override");
  assert.equal(resolve(scheduled, { at: "2026-08-10T04:30:00.000Z" }).kind, "global_fallback");
});

test("cross-midnight band remains owned by its starting weekday", () => {
  const scheduled = publish(emptySet(), {
    payload: overridePayload({
      weekdays: [1],
      timeZone: "Asia/Kolkata",
      startMinuteInclusive: 1320,
      endMinuteExclusive: 120,
    }),
  }).overrideSet;
  assert.equal(resolve(scheduled, { at: "2026-08-10T17:00:00.000Z" }).kind, "override");
  assert.equal(resolve(scheduled, { at: "2026-08-10T20:00:00.000Z" }).kind, "override");
  assert.equal(resolve(scheduled, { at: "2026-08-10T21:00:00.000Z" }).kind, "global_fallback");
});

test("DST repeated local time matches twice without guessing an offset", () => {
  const scheduled = publish(emptySet(), {
    occurredAt: "2026-10-01T00:00:00.000Z",
    payload: overridePayload({
      weekdays: [7],
      timeZone: "America/New_York",
      startMinuteInclusive: 60,
      endMinuteExclusive: 120,
      effectiveFrom: "2026-10-02T00:00:00.000Z",
    }),
  }).overrideSet;
  assert.equal(resolve(scheduled, { at: "2026-11-01T05:30:00.000Z" }).kind, "override");
  assert.equal(resolve(scheduled, { at: "2026-11-01T06:30:00.000Z" }).kind, "override");
});

test("DST skipped local time is not fabricated", () => {
  const scheduled = publish(emptySet(), {
    occurredAt: "2026-02-01T00:00:00.000Z",
    payload: overridePayload({
      weekdays: [7],
      timeZone: "America/New_York",
      startMinuteInclusive: 120,
      endMinuteExclusive: 180,
      effectiveFrom: "2026-02-02T00:00:00.000Z",
    }),
  }).overrideSet;
  assert.equal(resolve(scheduled, { at: "2026-03-08T06:59:00.000Z" }).kind, "global_fallback");
  assert.equal(resolve(scheduled, { at: "2026-03-08T07:00:00.000Z" }).kind, "global_fallback");
});

test("declared-busy qualifier never infers busy from other context", () => {
  const busy = publish(emptySet(), {
    payload: overridePayload({
      marketTypeId: null,
      readinessState: "declared_busy",
    }),
  }).overrideSet;
  assert.equal(resolve(busy, { declaredBusy: false }).kind, "global_fallback");
  assert.equal(resolve(busy, { declaredBusy: true }).kind, "override");
});

test("append-only disable revision restores global fallback at its boundary", () => {
  const enabled = publish(emptySet());
  const disabled = publish(enabled.overrideSet, {
    commandId: "command.disable-market-override",
    occurredAt: "2026-08-07T04:00:00.000Z",
    payload: overridePayload({
      state: "disabled",
      effectiveFrom: "2026-08-09T03:00:00.000Z",
      reasonCode: "ops.restore-global",
    }),
  });
  assert.equal(resolve(disabled.overrideSet, { at: "2026-08-09T02:59:59.999Z" }).kind, "override");
  assert.equal(resolve(disabled.overrideSet, { at: "2026-08-09T03:00:00.000Z" }).kind, "global_fallback");
  assert.equal(disabled.overrideSet.revisions.length, 2);
});

test("override identity cannot change selector and disable preserves timing", () => {
  const enabled = publish(emptySet());
  expectScheduleCode(
    () =>
      publish(enabled.overrideSet, {
        payload: overridePayload({
          localityId: "locality.changed",
          effectiveFrom: "2026-08-09T03:00:00.000Z",
        }),
      }),
    "invalid_input",
  );
  expectScheduleCode(
    () =>
      publish(enabled.overrideSet, {
        payload: overridePayload({
          state: "disabled",
          responseWindowSeconds: 90,
          overallAssignmentCeilingSeconds: 270,
          effectiveFrom: "2026-08-09T03:00:00.000Z",
        }),
      }),
    "invalid_input",
  );
});

test("resolver authorization and tenant binding precede hidden values", () => {
  const base = emptySet();
  const hidden = {
    ...base,
    get revisions(): readonly never[] {
      throw new Error("override values were accessed");
    },
  } as unknown as AcceptanceSlaScheduleOverrideSet;
  expectScheduleCode(
    () =>
      resolveAcceptanceSlaScheduleOverride({
        overrideSet: hidden,
        tenantId: TENANT_ID,
        overrideSetId: SET_ID,
        actor: adminActor([]),
        context: {
          family: "shop",
          marketTypeId: null,
          providerTypeId: null,
          categoryId: null,
          localityId: null,
          declaredBusy: false,
          at: "2026-08-10T03:00:00.000Z",
        },
      }),
    "unauthorized",
  );
  expectScheduleCode(
    () =>
      resolveAcceptanceSlaScheduleOverride({
        overrideSet: base,
        tenantId: "tenant.other-001",
        overrideSetId: SET_ID,
        actor: adminActor(),
        context: {
          family: "shop",
          marketTypeId: null,
          providerTypeId: null,
          categoryId: null,
          localityId: null,
          declaredBusy: false,
          at: "2026-08-10T03:00:00.000Z",
        },
      }),
    "tenant_mismatch",
  );
});

test("resolver rejects malformed runtime context after authorization", () => {
  const overrideSet = publish(emptySet()).overrideSet;
  const invalidBusyContext = {
    family: "shop",
    marketTypeId: "market.grocery",
    providerTypeId: null,
    categoryId: null,
    localityId: null,
    declaredBusy: "yes",
    at: "2026-08-10T03:00:00.000Z",
  } as unknown as Parameters<
    typeof resolveAcceptanceSlaScheduleOverride
  >[0]["context"];
  expectScheduleCode(
    () =>
      resolveAcceptanceSlaScheduleOverride({
        overrideSet,
        tenantId: TENANT_ID,
        overrideSetId: SET_ID,
        actor: adminActor(),
        context: invalidBusyContext,
      }),
    "invalid_input",
  );
  const invalidIdContext = {
    ...invalidBusyContext,
    marketTypeId: "not a stable id",
    declaredBusy: false,
  } as unknown as Parameters<
    typeof resolveAcceptanceSlaScheduleOverride
  >[0]["context"];
  expectScheduleCode(
    () =>
      resolveAcceptanceSlaScheduleOverride({
        overrideSet,
        tenantId: TENANT_ID,
        overrideSetId: SET_ID,
        actor: adminActor(),
        context: invalidIdContext,
      }),
    "invalid_input",
  );
});

test("does not mutate inputs and keeps revision receipt and audit deeply immutable", () => {
  const mutable = JSON.parse(JSON.stringify(emptySet())) as AcceptanceSlaScheduleOverrideSet;
  const before = JSON.stringify(mutable);
  const result = publish(mutable);
  assert.equal(JSON.stringify(mutable), before);
  assert.equal(Object.isFrozen(result), true);
  assert.equal(Object.isFrozen(result.revision), true);
  assert.equal(Object.isFrozen(result.revision.selector), true);
  assert.equal(Object.isFrozen(result.receipt), true);
  assert.equal(Object.isFrozen(result.overrideSet.auditEvents[0]), true);
  const auditJson = JSON.stringify(result.overrideSet.auditEvents[0]);
  assert.doesNotMatch(
    auditJson,
    /email|phone|prescription|message|secret|token|password|personal/iu,
  );
  assert.throws(() => {
    const target = result.revision as unknown as { responseWindowSeconds: number };
    target.responseWindowSeconds = 999;
  }, TypeError);
});
