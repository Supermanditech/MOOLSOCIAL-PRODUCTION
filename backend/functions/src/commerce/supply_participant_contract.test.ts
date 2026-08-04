import assert from "node:assert/strict";
import test from "node:test";

import {
  SupplyContractError,
  applySupplyParticipantCommand,
  isSupplyCapabilityActive,
  registerSupplyParticipantWorkspace,
  type RequestSupplyCapabilityCommand,
  type ReviewSupplyCapabilityCommand,
  type SupplyCapabilityKind,
  type SupplyContractErrorCode,
  type SupplyParticipantType,
  type SupplyParticipantWorkspace,
} from "./supply_participant_contract.js";

const HASH_A = "A".repeat(64);
const HASH_B = "B".repeat(64);

const workspaceAdmin = {
  actorId: "user.admin-001",
  tenantId: "tenant.india-001",
  workspaceId: "workspace.seller-001",
  scopes: ["supply.workspace.admin"],
} as const;

const reviewer = {
  actorId: "user.reviewer-001",
  tenantId: "tenant.india-001",
  scopes: ["supply.capability.review"],
} as const;

function expectCode(
  callback: () => unknown,
  code: SupplyContractErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof SupplyContractError && error.code === code,
  );
}

function registeredWorkspace(
  participantType: SupplyParticipantType = "retailer",
): SupplyParticipantWorkspace {
  return registerSupplyParticipantWorkspace({
    commandId: "command.register-001",
    occurredAt: "2026-08-03T01:00:00.000Z",
    workspaceId: "workspace.seller-001",
    tenantId: "tenant.india-001",
    legalEntityReference: "entity.supermandi-001",
    participantType,
    actor: workspaceAdmin,
  });
}

function requestCommand(
  workspace: SupplyParticipantWorkspace,
  capability: SupplyCapabilityKind = "wholesale_supply",
): RequestSupplyCapabilityCommand {
  return {
    type: "request_capability",
    commandId: `command.request-${capability}`,
    workspaceId: workspace.workspaceId,
    expectedVersion: workspace.version,
    occurredAt: "2026-08-03T01:10:00.000Z",
    actor: workspaceAdmin,
    capability,
    evidence: [
      { kind: "operational_capacity", sha256: HASH_B },
      { kind: "identity", sha256: HASH_A.toLowerCase() },
    ],
    qualifiers:
      capability === "delivery_fulfilment"
        ? { categoryIds: [], serviceAreaIds: ["area.342001"] }
        : capability === "product_master_stewardship"
          ? { categoryIds: ["category.fmcg"], serviceAreaIds: [] }
          : {
              categoryIds: ["category.fmcg"],
              serviceAreaIds: ["area.342001"],
            },
  };
}

function requestedWorkspace(
  capability: SupplyCapabilityKind = "wholesale_supply",
): SupplyParticipantWorkspace {
  const workspace = registeredWorkspace();
  return applySupplyParticipantCommand(
    workspace,
    requestCommand(workspace, capability),
  );
}

function verifyCommand(
  workspace: SupplyParticipantWorkspace,
  capability: SupplyCapabilityKind = "wholesale_supply",
): ReviewSupplyCapabilityCommand {
  return {
    type: "review_capability",
    commandId: `command.verify-${capability}`,
    workspaceId: workspace.workspaceId,
    expectedVersion: workspace.version,
    occurredAt: "2026-08-03T01:20:00.000Z",
    actor: reviewer,
    capability,
    decision: "verify",
    reason: "Independent evidence review passed.",
    effectiveFrom: "2026-08-03T02:00:00.000Z",
    expiresAt: "2026-09-03T02:00:00.000Z",
  };
}

test("registration creates an immutable workspace with zero active capabilities", () => {
  for (const participantType of [
    "shop",
    "retailer",
    "pharmacy",
    "wholesaler",
    "distributor",
    "manufacturer",
    "delivery_partner",
  ] as const) {
    const workspace = registeredWorkspace(participantType);
    assert.equal(workspace.participantType, participantType);
    assert.equal(workspace.version, 1);
    assert.deepEqual(workspace.capabilities, []);
    assert.equal(workspace.commandReceipts.length, 1);
    assert.equal(
      workspace.commandReceipts[0]?.commandId,
      "command.register-001",
    );
    assert.equal(workspace.auditEvents[0]?.eventType, "workspace_registered");
    assert.equal(Object.isFrozen(workspace), true);
    assert.equal(Object.isFrozen(workspace.capabilities), true);
    assert.equal(
      isSupplyCapabilityActive(workspace, {
        capability: "retail_fulfilment",
        at: "2026-08-03T03:00:00.000Z",
        categoryId: "category.fmcg",
        serviceAreaId: "area.342001",
      }),
      false,
    );
  }
});

test("registration requires exact tenant, workspace binding and admin scope", () => {
  const base = {
    commandId: "command.register-002",
    occurredAt: "2026-08-03T01:00:00.000Z",
    workspaceId: "workspace.seller-001",
    tenantId: "tenant.india-001",
    legalEntityReference: "entity.supermandi-001",
    participantType: "retailer" as const,
  };
  expectCode(
    () =>
      registerSupplyParticipantWorkspace({
        ...base,
        actor: { ...workspaceAdmin, tenantId: "tenant.other-001" },
      }),
    "tenant_mismatch",
  );
  expectCode(
    () =>
      registerSupplyParticipantWorkspace({
        ...base,
        actor: { ...workspaceAdmin, workspaceId: "workspace.other-001" },
      }),
    "workspace_mismatch",
  );
  expectCode(
    () =>
      registerSupplyParticipantWorkspace({
        ...base,
        actor: { ...workspaceAdmin, scopes: [] },
      }),
    "unauthorized",
  );
});

test("workspace request remains pending and retains only normalized evidence references", () => {
  const workspace = registeredWorkspace();
  const next = applySupplyParticipantCommand(
    workspace,
    requestCommand(workspace),
  );
  assert.equal(workspace.capabilities.length, 0, "input remains unchanged");
  assert.equal(next.version, 2);
  assert.equal(next.capabilities[0]?.state, "pending_review");
  assert.deepEqual(
    next.capabilities[0]?.evidence.map((item) => item.sha256),
    [HASH_A, HASH_B],
  );
  assert.equal(next.auditEvents[1]?.eventType, "capability_requested");
  assert.equal(
    isSupplyCapabilityActive(next, {
      capability: "wholesale_supply",
      at: "2026-08-03T03:00:00.000Z",
      categoryId: "category.fmcg",
      serviceAreaId: "area.342001",
    }),
    false,
  );
});

test("request rejects cross-tenant and cross-workspace actors", () => {
  const workspace = registeredWorkspace();
  const command = requestCommand(workspace);
  expectCode(
    () =>
      applySupplyParticipantCommand(workspace, {
        ...command,
        actor: { ...workspaceAdmin, tenantId: "tenant.other-001" },
      }),
    "tenant_mismatch",
  );
  expectCode(
    () =>
      applySupplyParticipantCommand(workspace, {
        ...command,
        actor: { ...workspaceAdmin, workspaceId: "workspace.other-001" },
      }),
    "workspace_mismatch",
  );
});

test("delivery-partner registration cannot become a seller capability", () => {
  const workspace = registeredWorkspace("delivery_partner");
  expectCode(
    () =>
      applySupplyParticipantCommand(
        workspace,
        requestCommand(workspace, "wholesale_supply"),
      ),
    "participant_capability_mismatch",
  );
  const delivery = applySupplyParticipantCommand(
    workspace,
    requestCommand(workspace, "delivery_fulfilment"),
  );
  assert.equal(delivery.capabilities[0]?.kind, "delivery_fulfilment");
});

test("governance verification is effective-dated and qualifier scoped", () => {
  const requested = requestedWorkspace();
  const verified = applySupplyParticipantCommand(
    requested,
    verifyCommand(requested),
  );
  const query = {
    capability: "wholesale_supply" as const,
    categoryId: "category.fmcg",
    serviceAreaId: "area.342001",
  };
  assert.equal(
    isSupplyCapabilityActive(verified, {
      ...query,
      at: "2026-08-03T01:59:59.999Z",
    }),
    false,
  );
  assert.equal(
    isSupplyCapabilityActive(verified, {
      ...query,
      at: "2026-08-03T02:00:00.000Z",
    }),
    true,
  );
  assert.equal(
    isSupplyCapabilityActive(verified, {
      ...query,
      at: "2026-09-03T02:00:00.000Z",
    }),
    false,
    "expiry is exclusive and fail closed",
  );
  assert.equal(
    isSupplyCapabilityActive(verified, {
      ...query,
      at: "2026-08-04T02:00:00.000Z",
      categoryId: "category.medicine",
    }),
    false,
  );
  assert.equal(
    isSupplyCapabilityActive(verified, {
      capability: "wholesale_supply",
      at: "2026-08-04T02:00:00.000Z",
    }),
    false,
    "missing qualifiers never broaden access",
  );
});

test("one verified capability never activates another capability", () => {
  const requested = requestedWorkspace();
  const verified = applySupplyParticipantCommand(
    requested,
    verifyCommand(requested),
  );
  assert.equal(
    isSupplyCapabilityActive(verified, {
      capability: "retail_fulfilment",
      at: "2026-08-04T02:00:00.000Z",
      categoryId: "category.fmcg",
      serviceAreaId: "area.342001",
    }),
    false,
  );
  assert.equal(
    isSupplyCapabilityActive(verified, {
      capability: "delivery_fulfilment",
      at: "2026-08-04T02:00:00.000Z",
      serviceAreaId: "area.342001",
    }),
    false,
  );
});

test("exact duplicate commands are idempotent and conflicting replay is rejected", () => {
  const workspace = registeredWorkspace();
  const command = requestCommand(workspace);
  const applied = applySupplyParticipantCommand(workspace, command);
  const replayed = applySupplyParticipantCommand(applied, command);
  assert.strictEqual(replayed, applied);
  assert.equal(replayed.version, 2);
  assert.equal(replayed.auditEvents.length, 2);
  expectCode(
    () =>
      applySupplyParticipantCommand(applied, {
        ...command,
        evidence: [{ kind: "identity", sha256: HASH_B }],
      }),
    "idempotency_conflict",
  );
});

test("stale aggregate version is rejected before mutation", () => {
  const requested = requestedWorkspace();
  expectCode(
    () =>
      applySupplyParticipantCommand(requested, {
        ...verifyCommand(requested),
        expectedVersion: 1,
      }),
    "version_conflict",
  );
  assert.equal(requested.version, 2);
  assert.equal(requested.capabilities[0]?.state, "pending_review");
});

test("evidence, qualifier and date validation fail closed", () => {
  const workspace = registeredWorkspace();
  const command = requestCommand(workspace);
  expectCode(
    () =>
      applySupplyParticipantCommand(workspace, { ...command, evidence: [] }),
    "invalid_input",
  );
  expectCode(
    () =>
      applySupplyParticipantCommand(workspace, {
        ...command,
        evidence: [{ kind: "identity", sha256: "not-a-hash" }],
      }),
    "invalid_input",
  );
  expectCode(
    () =>
      applySupplyParticipantCommand(workspace, {
        ...command,
        qualifiers: { categoryIds: [], serviceAreaIds: ["area.342001"] },
      }),
    "invalid_input",
  );
  const requested = requestedWorkspace();
  expectCode(
    () =>
      applySupplyParticipantCommand(requested, {
        ...verifyCommand(requested),
        expiresAt: "2026-08-03T01:59:59.999Z",
      }),
    "invalid_input",
  );
});

test("review, suspension and revocation require governance scope", () => {
  const requested = requestedWorkspace();
  expectCode(
    () =>
      applySupplyParticipantCommand(requested, {
        ...verifyCommand(requested),
        expectedVersion: 1,
        actor: workspaceAdmin,
      }),
    "unauthorized",
  );
  const verified = applySupplyParticipantCommand(
    requested,
    verifyCommand(requested),
  );
  const suspended = applySupplyParticipantCommand(verified, {
    type: "suspend_capability",
    commandId: "command.suspend-wholesale",
    workspaceId: verified.workspaceId,
    expectedVersion: verified.version,
    occurredAt: "2026-08-04T01:00:00.000Z",
    actor: reviewer,
    capability: "wholesale_supply",
    reason: "Operational capacity evidence requires review.",
  });
  assert.equal(suspended.capabilities[0]?.state, "suspended");
  assert.equal(
    isSupplyCapabilityActive(suspended, {
      capability: "wholesale_supply",
      at: "2026-08-04T02:00:00.000Z",
      categoryId: "category.fmcg",
      serviceAreaId: "area.342001",
    }),
    false,
  );
  const revoked = applySupplyParticipantCommand(suspended, {
    type: "revoke_capability",
    commandId: "command.revoke-wholesale",
    workspaceId: suspended.workspaceId,
    expectedVersion: suspended.version,
    occurredAt: "2026-08-04T01:10:00.000Z",
    actor: reviewer,
    capability: "wholesale_supply",
    reason: "Governance review revoked this capability.",
  });
  assert.equal(revoked.capabilities[0]?.state, "revoked");
  assert.deepEqual(
    revoked.auditEvents.slice(-2).map((event) => event.eventType),
    ["capability_suspended", "capability_revoked"],
  );
});

test("denial is auditable and a later request needs a new command", () => {
  const requested = requestedWorkspace();
  const denied = applySupplyParticipantCommand(requested, {
    type: "review_capability",
    commandId: "command.deny-wholesale",
    workspaceId: requested.workspaceId,
    expectedVersion: requested.version,
    occurredAt: "2026-08-03T01:20:00.000Z",
    actor: reviewer,
    capability: "wholesale_supply",
    decision: "deny",
    reason: "Submitted evidence did not meet the governed policy.",
  });
  assert.equal(denied.capabilities[0]?.state, "denied");
  const rerequested = applySupplyParticipantCommand(denied, {
    ...requestCommand(denied),
    commandId: "command.request-wholesale-retry",
    occurredAt: "2026-08-05T01:00:00.000Z",
  });
  assert.equal(rerequested.capabilities[0]?.state, "pending_review");
  assert.equal(rerequested.auditEvents.at(-1)?.fromState, "denied");
});

test("audit projection contains references and never embeds evidence payloads", () => {
  const requested = requestedWorkspace();
  const serialized = JSON.stringify(requested.auditEvents);
  assert.match(serialized, new RegExp(HASH_A, "u"));
  assert.doesNotMatch(serialized, /document|credential|bank account|secret/iu);
  assert.equal(requested.auditEvents[1]?.tenantId, requested.tenantId);
  assert.equal(requested.auditEvents[1]?.workspaceId, requested.workspaceId);
});
