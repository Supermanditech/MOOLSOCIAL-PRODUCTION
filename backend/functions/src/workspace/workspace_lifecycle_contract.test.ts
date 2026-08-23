import assert from "node:assert/strict";
import test from "node:test";

import {
  WorkspaceLifecycleError,
  applyWorkspaceLifecycleTransition,
  createWorkspaceLifecycle,
  type WorkspaceLifecycleActor,
  type WorkspaceLifecycleAggregate,
  type WorkspaceLifecycleErrorCode,
  type WorkspaceLifecycleTransition,
} from "./workspace_lifecycle_contract.js";

const requester: WorkspaceLifecycleActor = {
  actorId: "account.personal-001",
  tenantId: "tenant.india-001",
  scopes: ["workspace.request.create"],
};

const reviewer: WorkspaceLifecycleActor = {
  actorId: "operator.identity-review-001",
  tenantId: "tenant.india-001",
  scopes: ["workspace.lifecycle.review"],
};

const operator: WorkspaceLifecycleActor = {
  actorId: "operator.launch-001",
  tenantId: "tenant.india-001",
  scopes: ["workspace.lifecycle.operate"],
};

function expectCode(
  callback: () => unknown,
  code: WorkspaceLifecycleErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof WorkspaceLifecycleError && error.code === code,
  );
}

function pending(): WorkspaceLifecycleAggregate {
  return createWorkspaceLifecycle({
    transitionId: "transition.request-001",
    occurredAt: "2026-08-07T01:00:00.000Z",
    tenantId: "tenant.india-001",
    workspaceId: "workspace.grocery-001",
    requestId: "request.workspace-001",
    workspaceProfileId: "profile.grocery-kirana-shop",
    actor: requester,
  });
}

function transition(
  lifecycle: WorkspaceLifecycleAggregate,
  type: WorkspaceLifecycleTransition["type"],
  overrides: Record<string, unknown> = {},
): WorkspaceLifecycleTransition {
  const base = {
    type,
    transitionId: `transition.${type}-${lifecycle.version}`,
    occurredAt: "2026-08-07T02:00:00.000Z",
    workspaceId: lifecycle.workspaceId,
    expectedVersion: lifecycle.version,
    reason: `Reason for ${type}.`,
    actor: type === "approve" || type === "reject" ? reviewer : operator,
  };
  return type === "approve"
    ? {
        ...base,
        type,
        effectiveFrom: "2026-08-07T03:00:00.000Z",
        expiresAt: "2026-09-07T03:00:00.000Z",
        ...overrides,
      }
    : ({ ...base, ...overrides } as WorkspaceLifecycleTransition);
}

function approved(): WorkspaceLifecycleAggregate {
  const lifecycle = pending();
  return applyWorkspaceLifecycleTransition(
    lifecycle,
    transition(lifecycle, "approve"),
  );
}

test("creates one immutable pending workspace request and audit event", () => {
  const lifecycle = pending();
  assert.equal(lifecycle.state, "pending");
  assert.equal(lifecycle.version, 1);
  assert.equal(lifecycle.auditEvents.length, 1);
  assert.equal(lifecycle.auditEvents[0]?.eventType, "workspace_requested");
  assert.equal(lifecycle.auditEvents[0]?.toState, "pending");
  assert.equal(Object.isFrozen(lifecycle), true);
  assert.equal(Object.isFrozen(lifecycle.auditEvents), true);
  assert.equal(Object.isFrozen(lifecycle.auditEvents[0]), true);
});

test("request creation requires tenant binding and create scope", () => {
  expectCode(
    () =>
      createWorkspaceLifecycle({
        transitionId: "transition.request-001",
        occurredAt: "2026-08-07T01:00:00.000Z",
        tenantId: "tenant.other-001",
        workspaceId: "workspace.grocery-001",
        requestId: "request.workspace-001",
        workspaceProfileId: "profile.grocery-kirana-shop",
        actor: requester,
      }),
    "tenant_mismatch",
  );
  expectCode(
    () =>
      createWorkspaceLifecycle({
        transitionId: "transition.request-001",
        occurredAt: "2026-08-07T01:00:00.000Z",
        tenantId: "tenant.india-001",
        workspaceId: "workspace.grocery-001",
        requestId: "request.workspace-001",
        workspaceProfileId: "profile.grocery-kirana-shop",
        actor: { ...requester, scopes: [] },
      }),
    "unauthorized",
  );
});

test("reviewer approves pending with exact validity and audit", () => {
  const lifecycle = approved();
  assert.equal(lifecycle.state, "approved");
  assert.equal(lifecycle.version, 2);
  assert.equal(lifecycle.effectiveFrom, "2026-08-07T03:00:00.000Z");
  assert.equal(lifecycle.expiresAt, "2026-09-07T03:00:00.000Z");
  assert.equal(lifecycle.auditEvents[1]?.eventType, "workspace_approved");
  assert.equal(lifecycle.auditEvents[1]?.fromState, "pending");
});

test("reviewer rejects pending into a terminal reasoned state", () => {
  const lifecycle = pending();
  const rejected = applyWorkspaceLifecycleTransition(
    lifecycle,
    transition(lifecycle, "reject"),
  );
  assert.equal(rejected.state, "rejected");
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        rejected,
        transition(rejected, "approve"),
      ),
    "invalid_transition",
  );
});

test("operator suspends and resumes approved workspace", () => {
  const active = approved();
  const suspended = applyWorkspaceLifecycleTransition(
    active,
    transition(active, "suspend"),
  );
  assert.equal(suspended.state, "suspended");
  const resumed = applyWorkspaceLifecycleTransition(
    suspended,
    transition(suspended, "resume"),
  );
  assert.equal(resumed.state, "approved");
  assert.equal(resumed.effectiveFrom, active.effectiveFrom);
  assert.equal(resumed.expiresAt, active.expiresAt);
  assert.equal(resumed.auditEvents[3]?.eventType, "workspace_resumed");
});

test("workspace expires only at or after its exact expiry", () => {
  const active = approved();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        active,
        transition(active, "expire"),
      ),
    "invalid_transition",
  );
  const expired = applyWorkspaceLifecycleTransition(
    active,
    transition(active, "expire", {
      occurredAt: "2026-09-07T03:00:00.000Z",
    }),
  );
  assert.equal(expired.state, "expired");
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        expired,
        transition(expired, "revoke", {
          occurredAt: "2026-09-07T04:00:00.000Z",
        }),
      ),
    "invalid_transition",
  );
});

test("operator revokes approved or suspended workspace", () => {
  const active = approved();
  const revoked = applyWorkspaceLifecycleTransition(
    active,
    transition(active, "revoke"),
  );
  assert.equal(revoked.state, "revoked");

  const another = approved();
  const suspended = applyWorkspaceLifecycleTransition(
    another,
    transition(another, "suspend"),
  );
  assert.equal(
    applyWorkspaceLifecycleTransition(
      suspended,
      transition(suspended, "revoke"),
    ).state,
    "revoked",
  );
});

test("review and operation scopes never substitute for each other", () => {
  const lifecycle = pending();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", { actor: operator }),
      ),
    "unauthorized",
  );
  const active = approved();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        active,
        transition(active, "suspend", { actor: reviewer }),
      ),
    "unauthorized",
  );
});

test("rejects cross-tenant and cross-workspace transitions", () => {
  const active = approved();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        active,
        transition(active, "suspend", {
          actor: { ...operator, tenantId: "tenant.other-001" },
        }),
      ),
    "tenant_mismatch",
  );
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        active,
        transition(active, "suspend", {
          workspaceId: "workspace.other-001",
        }),
      ),
    "workspace_mismatch",
  );
});

test("rejects stale expected version before transition", () => {
  const active = approved();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        active,
        transition(active, "suspend", { expectedVersion: 1 }),
      ),
    "version_conflict",
  );
});

test("enforces exact transition graph", () => {
  const lifecycle = pending();
  for (const type of ["suspend", "resume", "expire", "revoke"] as const) {
    expectCode(
      () =>
        applyWorkspaceLifecycleTransition(
          lifecycle,
          transition(lifecycle, type),
        ),
      "invalid_transition",
    );
  }
  const active = approved();
  for (const type of ["approve", "reject", "resume"] as const) {
    expectCode(
      () =>
        applyWorkspaceLifecycleTransition(active, transition(active, type)),
      "invalid_transition",
    );
  }
});

test("validates approval interval and transition time", () => {
  const lifecycle = pending();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", {
          occurredAt: "2026-08-06T00:00:00.000Z",
        }),
      ),
    "invalid_transition",
  );
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", {
          expiresAt: "2026-08-07T03:00:00.000Z",
        }),
      ),
    "invalid_transition",
  );
});

test("requires canonical timestamps stable identifiers and valid version", () => {
  const lifecycle = pending();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", {
          occurredAt: "2026-08-07T02:00:00Z",
        }),
      ),
    "invalid_input",
  );
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", { transitionId: "x" }),
      ),
    "invalid_input",
  );
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", { expectedVersion: 1.5 }),
      ),
    "invalid_input",
  );
});

test("requires bounded reasons and unique stable scopes", () => {
  const lifecycle = pending();
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", { reason: "no" }),
      ),
    "invalid_input",
  );
  expectCode(
    () =>
      applyWorkspaceLifecycleTransition(
        lifecycle,
        transition(lifecycle, "approve", {
          actor: {
            ...reviewer,
            scopes: ["workspace.lifecycle.review", "workspace.lifecycle.review"],
          },
        }),
      ),
    "invalid_input",
  );
});

test("audit is append-only attributable and payload-free", () => {
  const original = pending();
  const before = structuredClone(original);
  const active = applyWorkspaceLifecycleTransition(
    original,
    transition(original, "approve"),
  );
  assert.deepEqual(original, before);
  assert.equal(active.auditEvents.length, 2);
  assert.equal(active.auditEvents[1]?.actorId, reviewer.actorId);
  assert.equal(active.auditEvents[1]?.aggregateVersion, 2);
  assert.equal("evidence" in active.auditEvents[1]!, false);
  assert.equal(Object.isFrozen(active.auditEvents[1]), true);
});
