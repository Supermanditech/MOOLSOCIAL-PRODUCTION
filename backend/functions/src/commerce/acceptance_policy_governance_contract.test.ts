import assert from "node:assert/strict";
import test from "node:test";

import {
  createAcceptanceSlaPolicySet,
  publishAcceptanceSlaPolicy,
  type AcceptanceSlaPolicyPayload,
  type AcceptanceSlaPolicySet,
  type PublishAcceptanceSlaPolicyCommand,
} from "./acceptance_sla_policy_contract.js";
import {
  createAcceptanceSlaScheduleOverrideSet,
  publishAcceptanceSlaScheduleOverride,
  type AcceptanceSlaScheduleOverridePayload,
  type AcceptanceSlaScheduleOverrideSet,
  type PublishAcceptanceSlaScheduleOverrideCommand,
} from "./acceptance_sla_schedule_override_contract.js";
import {
  AcceptancePolicyGovernanceError,
  createAcceptancePolicyGovernance,
  decideAcceptancePolicyGovernance,
  effectiveAcceptancePolicyGovernanceAt,
  inspectAcceptancePolicyGovernance,
  inspectAcceptancePolicyGovernanceSource,
  proposeAcceptancePolicyGovernance,
  type AcceptancePolicyGovernanceAggregate,
  type AcceptancePolicyGovernanceErrorCode,
  type AcceptancePolicyGovernanceSource,
  type DecidePolicyGovernanceCommand,
  type DecidePolicyGovernancePayload,
  type ProposePolicyGovernanceCommand,
  type ProposePolicyGovernancePayload,
} from "./acceptance_policy_governance_contract.js";
import {
  PrivilegedCommandError,
  type PrivilegedCommandActor,
  type PrivilegedCommandErrorCode,
} from "../workspace/privileged_command_contract.js";

const TENANT_ID = "tenant.india-001";
const POLICY_SET_ID = "acceptance-policy.global-001";
const OVERRIDE_SET_ID = "acceptance-schedule.global-001";
const GOVERNANCE_ID = "acceptance-governance.global-001";
const POLICY_ADMIN_SCOPE = "commerce.fulfilment_policy.admin";
const MAKER_SCOPE = "commerce.acceptance_policy_governance.propose";
const CHECKER_SCOPE = "commerce.acceptance_policy_governance.approve";

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
  set: AcceptanceSlaPolicySet,
  index: number,
  overrides: Partial<PublishAcceptanceSlaPolicyCommand> = {},
): PublishAcceptanceSlaPolicyCommand {
  return {
    schemaVersion: 1,
    commandId: `command.policy-source-${index}`,
    aggregateId: set.policySetId,
    expectedVersion: set.version,
    occurredAt: `2026-08-07T0${index + 2}:00:00.000Z`,
    confirmed: true,
    reason: "Publish reviewed acceptance policy source revision.",
    actor: {
      actorId: "admin.policy-source-001",
      tenantId: set.tenantId,
      scopes: [POLICY_ADMIN_SCOPE],
    },
    payload: policyPayload({
      responseWindowSeconds: index === 1 ? 60 : 90,
      overallAssignmentCeilingSeconds: index === 1 ? 180 : 270,
      effectiveFrom: `2026-08-08T0${index + 2}:00:00.000Z`,
      reasonCode: `ops.policy-source-${index}`,
    }),
    ...overrides,
  };
}

function globalPolicySet(): AcceptanceSlaPolicySet {
  let set = createAcceptanceSlaPolicySet({
    tenantId: TENANT_ID,
    policySetId: POLICY_SET_ID,
  });
  for (const index of [1, 2]) {
    set = publishAcceptanceSlaPolicy({
      policySet: set,
      command: policyCommand(set, index),
    }).policySet;
  }
  return set;
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

function overrideCommand(
  set: AcceptanceSlaScheduleOverrideSet,
): PublishAcceptanceSlaScheduleOverrideCommand {
  return {
    schemaVersion: 1,
    commandId: "command.override-source-1",
    aggregateId: set.overrideSetId,
    expectedVersion: set.version,
    occurredAt: "2026-08-07T03:00:00.000Z",
    confirmed: true,
    reason: "Publish reviewed schedule override source revision.",
    actor: {
      actorId: "admin.policy-source-001",
      tenantId: set.tenantId,
      scopes: [POLICY_ADMIN_SCOPE],
    },
    payload: overridePayload(),
  };
}

function overrideSet(): AcceptanceSlaScheduleOverrideSet {
  const empty = createAcceptanceSlaScheduleOverrideSet({
    tenantId: TENANT_ID,
    overrideSetId: OVERRIDE_SET_ID,
  });
  return publishAcceptanceSlaScheduleOverride({
    overrideSet: empty,
    command: overrideCommand(empty),
  }).overrideSet;
}

function maker(overrides: Partial<PrivilegedCommandActor> = {}): PrivilegedCommandActor {
  return {
    actorId: "admin.policy-maker-001",
    tenantId: TENANT_ID,
    scopes: [MAKER_SCOPE],
    ...overrides,
  };
}

function checker(
  overrides: Partial<PrivilegedCommandActor> = {},
): PrivilegedCommandActor {
  return {
    actorId: "admin.policy-checker-001",
    tenantId: TENANT_ID,
    scopes: [CHECKER_SCOPE],
    ...overrides,
  };
}

function globalSource(index = 1): AcceptancePolicyGovernanceSource {
  const policySet = globalPolicySet();
  return {
    kind: "global_policy",
    policySet,
    revisionId: policySet.revisions[index]!.revisionId,
  };
}

function scheduleSource(): AcceptancePolicyGovernanceSource {
  const set = overrideSet();
  return {
    kind: "schedule_override",
    overrideSet: set,
    revisionId: set.revisions[0]!.revisionId,
  };
}

function emptyGovernance(
  targetKind: "global_policy" | "schedule_override" = "global_policy",
  targetSubjectId =
    targetKind === "global_policy" ? "shop" : "override.market-grocery-001",
): AcceptancePolicyGovernanceAggregate {
  return createAcceptancePolicyGovernance({
    tenantId: TENANT_ID,
    governanceId: GOVERNANCE_ID,
    targetKind,
    sourceSetId: targetKind === "global_policy" ? POLICY_SET_ID : OVERRIDE_SET_ID,
    targetSubjectId,
  });
}

function sourceFingerprint(source: AcceptancePolicyGovernanceSource): string {
  return inspectAcceptancePolicyGovernanceSource({
    source,
    tenantId: TENANT_ID,
    actor: maker(),
  }).sourceFingerprint;
}

function proposalPayload(
  source: AcceptancePolicyGovernanceSource,
  overrides: Partial<ProposePolicyGovernancePayload> = {},
): ProposePolicyGovernancePayload {
  return {
    governanceId: GOVERNANCE_ID,
    action: "approve_revision",
    sourceFingerprint: sourceFingerprint(source),
    effectiveFrom: "2026-08-08T06:00:00.000Z",
    reasonCode: "ops.policy-approval",
    explanation: "Approve reviewed acceptance timing for future orders only.",
    ...overrides,
  };
}

function proposalCommand(
  aggregate: AcceptancePolicyGovernanceAggregate,
  source: AcceptancePolicyGovernanceSource,
  overrides: Partial<ProposePolicyGovernanceCommand> = {},
): ProposePolicyGovernanceCommand {
  return {
    schemaVersion: 1,
    commandId: `command.policy-governance-propose-${aggregate.version}`,
    aggregateId: aggregate.governanceId,
    expectedVersion: aggregate.version,
    occurredAt: "2026-08-07T06:00:00.000Z",
    confirmed: true,
    reason: "Propose one reviewed acceptance policy governance decision.",
    actor: maker(),
    payload: proposalPayload(source),
    ...overrides,
  };
}

function propose(
  aggregate: AcceptancePolicyGovernanceAggregate,
  source: AcceptancePolicyGovernanceSource,
  overrides: Partial<ProposePolicyGovernanceCommand> = {},
) {
  return proposeAcceptancePolicyGovernance({
    aggregate,
    source,
    command: proposalCommand(aggregate, source, overrides),
  });
}

function decisionPayload(
  proposalId: string,
  overrides: Partial<DecidePolicyGovernancePayload> = {},
): DecidePolicyGovernancePayload {
  return {
    governanceId: GOVERNANCE_ID,
    proposalId,
    decision: "approved",
    reasonCode: "ops.policy-check",
    explanation: "Checker independently verified the future-order policy evidence.",
    ...overrides,
  };
}

function decisionCommand(
  aggregate: AcceptancePolicyGovernanceAggregate,
  overrides: Partial<DecidePolicyGovernanceCommand> = {},
): DecidePolicyGovernanceCommand {
  const pending = aggregate.events.at(-1);
  assert.equal(pending?.eventKind, "proposal");
  return {
    schemaVersion: 1,
    commandId: `command.policy-governance-decide-${aggregate.version}`,
    aggregateId: aggregate.governanceId,
    expectedVersion: aggregate.version,
    occurredAt: "2026-08-07T07:00:00.000Z",
    confirmed: true,
    reason: "Independently decide one policy governance proposal.",
    actor: checker(),
    payload: decisionPayload(pending!.proposalId),
    ...overrides,
  };
}

function decide(
  aggregate: AcceptancePolicyGovernanceAggregate,
  overrides: Partial<DecidePolicyGovernanceCommand> = {},
) {
  return decideAcceptancePolicyGovernance({
    aggregate,
    command: decisionCommand(aggregate, overrides),
  });
}

function project(
  aggregate: AcceptancePolicyGovernanceAggregate,
  at: string,
) {
  return effectiveAcceptancePolicyGovernanceAt({
    aggregate,
    tenantId: TENANT_ID,
    governanceId: GOVERNANCE_ID,
    actor: checker(),
    at,
  });
}

function expectGovernanceCode(
  callback: () => unknown,
  code: AcceptancePolicyGovernanceErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof AcceptancePolicyGovernanceError && error.code === code,
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

test("creates an immutable governance aggregate for one exact source set", () => {
  const aggregate = emptyGovernance();
  assert.equal(aggregate.version, 1);
  assert.equal(aggregate.targetKind, "global_policy");
  assert.equal(aggregate.sourceSetId, POLICY_SET_ID);
  assert.equal(aggregate.targetSubjectId, "shop");
  assert.equal(Object.isFrozen(aggregate), true);
  assert.equal(Object.isFrozen(aggregate.events), true);
});

test("authenticates and fingerprints global and schedule-override sources", () => {
  const global = inspectAcceptancePolicyGovernanceSource({
    source: globalSource(1),
    tenantId: TENANT_ID,
    actor: maker(),
  });
  assert.equal(global.kind, "global_policy");
  assert.equal(global.aggregateVersion, 3);
  assert.equal(global.sourceFingerprint.length, 64);
  const schedule = inspectAcceptancePolicyGovernanceSource({
    source: scheduleSource(),
    tenantId: TENANT_ID,
    actor: checker(),
  });
  assert.equal(schedule.kind, "schedule_override");
  if (schedule.kind === "schedule_override") {
    assert.equal(schedule.overrideId, "override.market-grocery-001");
    assert.equal(schedule.selectorFingerprint.length, 64);
  }
});

test("requires source-inspection authority before hidden source values", () => {
  const source = globalSource(1);
  if (source.kind !== "global_policy") throw new Error("global fixture required");
  const hidden = {
    ...source.policySet,
    get revisions(): readonly never[] {
      throw new Error("source revisions were accessed");
    },
  } as unknown as AcceptanceSlaPolicySet;
  expectGovernanceCode(
    () =>
      inspectAcceptancePolicyGovernanceSource({
        source: { ...source, policySet: hidden },
        tenantId: TENANT_ID,
        actor: maker({ scopes: [] }),
      }),
    "unauthorized",
  );
});

test("proposes and independently approves a future global policy revision", () => {
  const source = globalSource(1);
  const proposal = propose(emptyGovernance(), source);
  assert.equal(proposal.event.eventKind, "proposal");
  assert.equal(proposal.aggregate.version, 2);
  assert.equal(project(proposal.aggregate, "2026-08-08T06:00:00.000Z").state, "unknown");
  const approval = decide(proposal.aggregate);
  assert.equal(approval.event.eventKind, "decision");
  assert.equal(project(approval.aggregate, "2026-08-08T05:59:59.999Z").state, "unknown");
  const effective = project(approval.aggregate, "2026-08-08T06:00:00.000Z");
  assert.equal(effective.state, "approved");
  if (effective.state === "approved") {
    assert.equal(effective.action, "approve_revision");
    assert.equal(effective.source.aggregateVersion, 3);
  }
});

test("records rejection without making the proposed revision effective", () => {
  const proposal = propose(emptyGovernance(), globalSource(1));
  const rejected = decide(proposal.aggregate, {
    payload: decisionPayload(proposal.event.proposalId, {
      decision: "rejected",
      reasonCode: "ops.policy-rejected",
      explanation: "Checker found the evidence incomplete and rejected activation.",
    }),
  });
  assert.equal(project(rejected.aggregate, "2026-08-09T00:00:00.000Z").state, "unknown");
  assert.equal(rejected.aggregate.events.length, 2);
});

test("enforces different maker and checker identities", () => {
  const proposal = propose(emptyGovernance(), globalSource(1));
  expectGovernanceCode(
    () =>
      decide(proposal.aggregate, {
        actor: maker({ scopes: [CHECKER_SCOPE] }),
      }),
    "maker_checker_conflict",
  );
});

test("appends a future-only rollback and preserves both effective eras", () => {
  const newer = globalSource(1);
  const firstProposal = propose(emptyGovernance(), newer);
  const firstApproval = decide(firstProposal.aggregate);
  const older = globalSource(0);
  const rollbackProposal = propose(firstApproval.aggregate, older, {
    commandId: "command.policy-governance-propose-rollback",
    occurredAt: "2026-08-07T08:00:00.000Z",
    payload: proposalPayload(older, {
      action: "rollback_to_revision",
      effectiveFrom: "2026-08-08T07:00:00.000Z",
      reasonCode: "ops.policy-rollback",
      explanation: "Restore the previously approved bounded timing for future orders.",
    }),
  });
  const rollbackApproval = decide(rollbackProposal.aggregate, {
    commandId: "command.policy-governance-decide-rollback",
    occurredAt: "2026-08-07T09:00:00.000Z",
  });
  const before = project(rollbackApproval.aggregate, "2026-08-08T06:59:59.999Z");
  const after = project(rollbackApproval.aggregate, "2026-08-08T07:00:00.000Z");
  assert.equal(before.state, "approved");
  assert.equal(after.state, "approved");
  if (before.state === "approved" && after.state === "approved") {
    assert.equal(before.source.aggregateVersion, 3);
    assert.equal(after.source.aggregateVersion, 2);
    assert.equal(after.action, "rollback_to_revision");
  }
  assert.equal(rollbackApproval.aggregate.events.length, 4);
});

test("rejects invalid direction, nonmonotonic effective time and late approval", () => {
  const older = globalSource(0);
  expectGovernanceCode(
    () =>
      propose(emptyGovernance(), older, {
        payload: proposalPayload(older, { action: "rollback_to_revision" }),
      }),
    "invalid_state",
  );
  const firstProposal = propose(emptyGovernance(), globalSource(1));
  const firstApproval = decide(firstProposal.aggregate);
  expectGovernanceCode(
    () =>
      propose(firstApproval.aggregate, older, {
        occurredAt: "2026-08-07T08:00:00.000Z",
        payload: proposalPayload(older, {
          action: "rollback_to_revision",
          effectiveFrom: "2026-08-08T06:00:00.000Z",
        }),
      }),
    "invalid_state",
  );
  const pending = propose(emptyGovernance(), globalSource(1), {
    payload: proposalPayload(globalSource(1), {
      effectiveFrom: "2026-08-08T05:00:00.000Z",
    }),
  });
  expectGovernanceCode(
    () =>
      decide(pending.aggregate, {
        occurredAt: "2026-08-08T05:00:00.001Z",
      }),
    "effective_time_conflict",
  );
});

test("allows only one pending proposal and an exact matching decision", () => {
  const source = globalSource(1);
  const pending = propose(emptyGovernance(), source);
  expectGovernanceCode(
    () =>
      propose(pending.aggregate, source, {
        commandId: "command.second-pending-proposal",
        expectedVersion: pending.aggregate.version,
      }),
    "invalid_state",
  );
  expectGovernanceCode(
    () =>
      decide(pending.aggregate, {
        payload: decisionPayload("policy-governance-proposal:999"),
      }),
    "invalid_state",
  );
});

test("denies proposal authorization before hidden governance values", () => {
  const base = emptyGovernance();
  const hidden = {
    ...base,
    get events(): readonly never[] {
      throw new Error("governance events were accessed");
    },
  } as unknown as AcceptancePolicyGovernanceAggregate;
  const source = globalSource(1);
  expectCommandCode(
    () =>
      proposeAcceptancePolicyGovernance({
        aggregate: hidden,
        source,
        command: proposalCommand(base, source, {
          actor: maker({ scopes: [] }),
        }),
      }),
    "unauthorized",
  );
});

test("rejects wrong source fingerprint, kind and tampered source evidence", () => {
  const source = globalSource(1);
  expectGovernanceCode(
    () =>
      propose(emptyGovernance(), source, {
        payload: proposalPayload(source, { sourceFingerprint: "A".repeat(64) }),
      }),
    "aggregate_mismatch",
  );
  const schedule = scheduleSource();
  expectGovernanceCode(
    () => propose(emptyGovernance(), schedule),
    "aggregate_mismatch",
  );
  expectGovernanceCode(
    () => propose(emptyGovernance("global_policy", "wholesale"), source),
    "aggregate_mismatch",
  );
  if (source.kind !== "global_policy") throw new Error("global fixture required");
  const tampered = JSON.parse(JSON.stringify(source.policySet)) as AcceptanceSlaPolicySet;
  const receipt = tampered.receipts[1] as unknown as { resultReference: string };
  receipt.resultReference = "acceptance-sla-policy-revision:999";
  expectGovernanceCode(
    () =>
      inspectAcceptancePolicyGovernanceSource({
        source: { ...source, policySet: tampered },
        tenantId: TENANT_ID,
        actor: maker(),
      }),
    "source_mismatch",
  );
  const coercible = JSON.parse(
    JSON.stringify(source.policySet),
  ) as unknown as { version: unknown };
  coercible.version = "3";
  expectGovernanceCode(
    () =>
      inspectAcceptancePolicyGovernanceSource({
        source: {
          ...source,
          policySet: coercible as unknown as AcceptanceSlaPolicySet,
        },
        tenantId: TENANT_ID,
        actor: maker(),
      }),
    "invalid_input",
  );
  const auditTamper = JSON.parse(
    JSON.stringify(source.policySet),
  ) as AcceptanceSlaPolicySet;
  (auditTamper.auditEvents[1] as unknown as { schemaVersion: number }).schemaVersion = 2;
  expectGovernanceCode(
    () =>
      inspectAcceptancePolicyGovernanceSource({
        source: { ...source, policySet: auditTamper },
        tenantId: TENANT_ID,
        actor: maker(),
      }),
    "source_mismatch",
  );
});

test("supports exact proposal and decision replay but rejects changed retries", () => {
  const current = emptyGovernance();
  const source = globalSource(1);
  const proposeCommandValue = proposalCommand(current, source);
  const first = proposeAcceptancePolicyGovernance({
    aggregate: current,
    source,
    command: proposeCommandValue,
  });
  const retry = proposeAcceptancePolicyGovernance({
    aggregate: first.aggregate,
    source,
    command: proposeCommandValue,
  });
  assert.equal(retry.replayed, true);
  expectCommandCode(
    () =>
      proposeAcceptancePolicyGovernance({
        aggregate: first.aggregate,
        source,
        command: {
          ...proposeCommandValue,
          payload: proposalPayload(source, { reasonCode: "ops.changed-retry" }),
        },
      }),
    "idempotency_conflict",
  );
  const decideCommandValue = decisionCommand(first.aggregate);
  const approved = decideAcceptancePolicyGovernance({
    aggregate: first.aggregate,
    command: decideCommandValue,
  });
  const decisionRetry = decideAcceptancePolicyGovernance({
    aggregate: approved.aggregate,
    command: decideCommandValue,
  });
  assert.equal(decisionRetry.replayed, true);
});

test("governs an exact Ticket 2 schedule override without copying selector truth", () => {
  const source = scheduleSource();
  const proposal = propose(emptyGovernance("schedule_override"), source);
  const approved = decide(proposal.aggregate);
  const effective = project(approved.aggregate, "2026-08-08T06:00:00.000Z");
  assert.equal(effective.state, "approved");
  if (effective.state === "approved") {
    assert.equal(effective.source.kind, "schedule_override");
    if (effective.source.kind === "schedule_override") {
      assert.equal(effective.source.selectorFingerprint.length, 64);
    }
  }
});

test("authenticates inspection before exposing governance explanations", () => {
  const proposal = propose(emptyGovernance(), globalSource(1));
  const inspected = inspectAcceptancePolicyGovernance({
    aggregate: proposal.aggregate,
    tenantId: TENANT_ID,
    governanceId: GOVERNANCE_ID,
    actor: maker(),
  });
  assert.equal(inspected.events.length, 1);
  const hidden = {
    ...proposal.aggregate,
    get events(): readonly never[] {
      throw new Error("governance explanations were accessed");
    },
  } as unknown as AcceptancePolicyGovernanceAggregate;
  expectGovernanceCode(
    () =>
      inspectAcceptancePolicyGovernance({
        aggregate: hidden,
        tenantId: TENANT_ID,
        governanceId: GOVERNANCE_ID,
        actor: checker({ scopes: [] }),
      }),
    "unauthorized",
  );
  expectGovernanceCode(
    () =>
      inspectAcceptancePolicyGovernance({
        aggregate: proposal.aggregate,
        tenantId: "tenant.other-001",
        governanceId: GOVERNANCE_ID,
        actor: checker({ tenantId: "tenant.other-001" }),
      }),
    "tenant_mismatch",
  );
});

test("JSON restart preserves projection and rejects undeclared fields at every level", () => {
  const proposal = propose(emptyGovernance(), globalSource(1));
  const approved = decide(proposal.aggregate).aggregate;
  const restarted = JSON.parse(JSON.stringify(approved)) as AcceptancePolicyGovernanceAggregate;
  assert.deepEqual(
    project(restarted, "2026-08-08T06:00:00.000Z"),
    project(approved, "2026-08-08T06:00:00.000Z"),
  );
  for (const target of ["root", "event", "receipt", "audit"] as const) {
    const unsafe = JSON.parse(JSON.stringify(approved)) as unknown as Record<
      string,
      unknown
    >;
    if (target === "root") {
      unsafe.deletedRevision = true;
    } else {
      const key = target === "event" ? "events" : target === "receipt" ? "receipts" : "auditEvents";
      const records = unsafe[key] as Array<Record<string, unknown>>;
      records[0]!.deletedRevision = true;
    }
    expectGovernanceCode(
      () =>
        inspectAcceptancePolicyGovernance({
          aggregate: unsafe as unknown as AcceptancePolicyGovernanceAggregate,
          tenantId: TENANT_ID,
          governanceId: GOVERNANCE_ID,
          actor: checker(),
        }),
      "invalid_input",
    );
  }
});

test("rejects source-reference and coordinated history tampering after restart", () => {
  const proposal = propose(emptyGovernance(), globalSource(1));
  const approved = decide(proposal.aggregate).aggregate;
  const sourceTamper = JSON.parse(
    JSON.stringify(approved),
  ) as AcceptancePolicyGovernanceAggregate;
  const source = (sourceTamper.events[0] as unknown as {
    source: { revisionId: string };
  }).source;
  source.revisionId = "acceptance-sla-policy-revision:999";
  expectGovernanceCode(
    () => project(sourceTamper, "2026-08-08T06:00:00.000Z"),
    "source_mismatch",
  );

  const timeTamper = JSON.parse(
    JSON.stringify(approved),
  ) as AcceptancePolicyGovernanceAggregate;
  const earlier = "2026-08-07T05:00:00.000Z";
  (timeTamper.events[1] as unknown as { occurredAt: string }).occurredAt = earlier;
  (timeTamper.receipts[1] as unknown as { completedAt: string }).completedAt = earlier;
  (timeTamper.auditEvents[1] as unknown as { occurredAt: string }).occurredAt = earlier;
  expectGovernanceCode(
    () => project(timeTamper, "2026-08-08T06:00:00.000Z"),
    "invalid_input",
  );
});

test("rejects stale commands and retroactive proposals", () => {
  const source = globalSource(1);
  expectCommandCode(
    () => propose(emptyGovernance(), source, { expectedVersion: 99 }),
    "version_conflict",
  );
  expectGovernanceCode(
    () =>
      propose(emptyGovernance(), source, {
        payload: proposalPayload(source, {
          effectiveFrom: "2026-08-07T05:00:00.000Z",
        }),
      }),
    "effective_time_conflict",
  );
});

test("does not mutate inputs and returns deeply immutable payload-minimized evidence", () => {
  const current = emptyGovernance();
  const source = globalSource(1);
  const beforeAggregate = JSON.stringify(current);
  const beforeSource = JSON.stringify(source);
  const result = propose(current, source);
  assert.equal(JSON.stringify(current), beforeAggregate);
  assert.equal(JSON.stringify(source), beforeSource);
  assert.equal(Object.isFrozen(result), true);
  assert.equal(Object.isFrozen(result.aggregate), true);
  assert.equal(Object.isFrozen(result.aggregate.events), true);
  assert.equal(Object.isFrozen(result.event), true);
  assert.equal(Object.isFrozen(result.receipt), true);
  assert.equal(Object.isFrozen(result.aggregate.auditEvents[0]), true);
  assert.doesNotMatch(
    JSON.stringify(result.aggregate.auditEvents[0]),
    /explanation|reasonCode|responseWindow|phone|message|contact|secret|token/iu,
  );
  assert.throws(() => {
    const target = result.event as unknown as { explanation: string };
    target.explanation = "mutated explanation";
  }, TypeError);
});
