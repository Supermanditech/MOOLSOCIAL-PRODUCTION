export const workspaceLifecycleStates = [
  "pending",
  "approved",
  "rejected",
  "suspended",
  "expired",
  "revoked",
] as const;

export type WorkspaceLifecycleState =
  (typeof workspaceLifecycleStates)[number];

export type WorkspaceLifecycleErrorCode =
  | "invalid_input"
  | "unauthorized"
  | "tenant_mismatch"
  | "workspace_mismatch"
  | "version_conflict"
  | "invalid_transition";

export class WorkspaceLifecycleError extends Error {
  constructor(
    readonly code: WorkspaceLifecycleErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "WorkspaceLifecycleError";
  }
}

export interface WorkspaceLifecycleActor {
  readonly actorId: string;
  readonly tenantId: string;
  readonly scopes: readonly string[];
}

export type WorkspaceLifecycleEventType =
  | "workspace_requested"
  | "workspace_approved"
  | "workspace_rejected"
  | "workspace_suspended"
  | "workspace_resumed"
  | "workspace_expired"
  | "workspace_revoked";

export interface WorkspaceLifecycleAuditEvent {
  readonly eventId: string;
  readonly eventType: WorkspaceLifecycleEventType;
  readonly aggregateVersion: number;
  readonly transitionId: string;
  readonly tenantId: string;
  readonly workspaceId: string;
  readonly requestId: string;
  readonly actorId: string;
  readonly occurredAt: string;
  readonly fromState?: WorkspaceLifecycleState;
  readonly toState: WorkspaceLifecycleState;
  readonly reason?: string;
}

export interface WorkspaceLifecycleAggregate {
  readonly schemaVersion: 1;
  readonly tenantId: string;
  readonly workspaceId: string;
  readonly requestId: string;
  readonly workspaceProfileId: string;
  readonly state: WorkspaceLifecycleState;
  readonly version: number;
  readonly requestedAt: string;
  readonly requestedBy: string;
  readonly effectiveFrom?: string;
  readonly expiresAt?: string;
  readonly reason?: string;
  readonly auditEvents: readonly WorkspaceLifecycleAuditEvent[];
}

export interface CreateWorkspaceLifecycleRequest {
  readonly transitionId: string;
  readonly occurredAt: string;
  readonly tenantId: string;
  readonly workspaceId: string;
  readonly requestId: string;
  readonly workspaceProfileId: string;
  readonly actor: WorkspaceLifecycleActor;
}

interface WorkspaceLifecycleTransitionBase {
  readonly transitionId: string;
  readonly occurredAt: string;
  readonly workspaceId: string;
  readonly expectedVersion: number;
  readonly reason: string;
  readonly actor: WorkspaceLifecycleActor;
}

export interface ApproveWorkspaceLifecycleTransition
  extends WorkspaceLifecycleTransitionBase {
  readonly type: "approve";
  readonly effectiveFrom: string;
  readonly expiresAt: string;
}

export interface RejectWorkspaceLifecycleTransition
  extends WorkspaceLifecycleTransitionBase {
  readonly type: "reject";
}

export interface SuspendWorkspaceLifecycleTransition
  extends WorkspaceLifecycleTransitionBase {
  readonly type: "suspend";
}

export interface ResumeWorkspaceLifecycleTransition
  extends WorkspaceLifecycleTransitionBase {
  readonly type: "resume";
}

export interface ExpireWorkspaceLifecycleTransition
  extends WorkspaceLifecycleTransitionBase {
  readonly type: "expire";
}

export interface RevokeWorkspaceLifecycleTransition
  extends WorkspaceLifecycleTransitionBase {
  readonly type: "revoke";
}

export type WorkspaceLifecycleTransition =
  | ApproveWorkspaceLifecycleTransition
  | RejectWorkspaceLifecycleTransition
  | SuspendWorkspaceLifecycleTransition
  | ResumeWorkspaceLifecycleTransition
  | ExpireWorkspaceLifecycleTransition
  | RevokeWorkspaceLifecycleTransition;

const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$/u;
const CREATE_SCOPE = "workspace.request.create";
const REVIEW_SCOPE = "workspace.lifecycle.review";
const OPERATE_SCOPE = "workspace.lifecycle.operate";

function fail(code: WorkspaceLifecycleErrorCode, message: string): never {
  throw new WorkspaceLifecycleError(code, message);
}

function identifier(value: string, label: string): string {
  const normalized = value.trim();
  if (!IDENTIFIER_PATTERN.test(normalized)) {
    fail("invalid_input", `${label} must be a stable identifier.`);
  }
  return normalized;
}

function timestamp(value: string, label: string): string {
  const milliseconds = Date.parse(value);
  if (!Number.isFinite(milliseconds)) {
    fail("invalid_input", `${label} must be a valid timestamp.`);
  }
  const normalized = new Date(milliseconds).toISOString();
  if (normalized !== value) {
    fail("invalid_input", `${label} must use canonical UTC ISO-8601.`);
  }
  return normalized;
}

function positiveVersion(value: number): number {
  if (!Number.isSafeInteger(value) || value < 1) {
    fail("invalid_input", "expected version must be a positive integer.");
  }
  return value;
}

function boundedReason(value: string): string {
  const normalized = value.trim();
  if (normalized.length < 5 || normalized.length > 280) {
    fail("invalid_input", "transition reason must contain 5 to 280 characters.");
  }
  return normalized;
}

function actor(value: WorkspaceLifecycleActor): WorkspaceLifecycleActor {
  const scopes = value.scopes.map((scope) => identifier(scope, "actor scope"));
  if (new Set(scopes).size !== scopes.length) {
    fail("invalid_input", "actor scopes must not contain duplicates.");
  }
  return Object.freeze({
    actorId: identifier(value.actorId, "actor id"),
    tenantId: identifier(value.tenantId, "actor tenant id"),
    scopes: Object.freeze([...scopes].sort()),
  });
}

function requireScope(
  lifecycleActor: WorkspaceLifecycleActor,
  scope: string,
): void {
  if (!lifecycleActor.scopes.includes(scope)) {
    fail("unauthorized", `actor lacks required scope ${scope}.`);
  }
}

function freezeEvent(
  event: WorkspaceLifecycleAuditEvent,
): WorkspaceLifecycleAuditEvent {
  return Object.freeze(event);
}

function freezeAggregate(
  aggregate: WorkspaceLifecycleAggregate,
): WorkspaceLifecycleAggregate {
  return Object.freeze({
    ...aggregate,
    auditEvents: Object.freeze(
      aggregate.auditEvents.map((event) => Object.freeze({ ...event })),
    ),
  });
}

export function createWorkspaceLifecycle(
  request: CreateWorkspaceLifecycleRequest,
): WorkspaceLifecycleAggregate {
  const lifecycleActor = actor(request.actor);
  const tenantId = identifier(request.tenantId, "tenant id");
  if (lifecycleActor.tenantId !== tenantId) {
    fail("tenant_mismatch", "actor cannot create a request for another tenant.");
  }
  requireScope(lifecycleActor, CREATE_SCOPE);
  const workspaceId = identifier(request.workspaceId, "workspace id");
  const requestId = identifier(request.requestId, "request id");
  const transitionId = identifier(request.transitionId, "transition id");
  const occurredAt = timestamp(request.occurredAt, "occurredAt");
  const workspaceProfileId = identifier(
    request.workspaceProfileId,
    "workspace profile id",
  );
  const event = freezeEvent({
    eventId: `${workspaceId}:1`,
    eventType: "workspace_requested",
    aggregateVersion: 1,
    transitionId,
    tenantId,
    workspaceId,
    requestId,
    actorId: lifecycleActor.actorId,
    occurredAt,
    toState: "pending",
  });
  return freezeAggregate({
    schemaVersion: 1,
    tenantId,
    workspaceId,
    requestId,
    workspaceProfileId,
    state: "pending",
    version: 1,
    requestedAt: occurredAt,
    requestedBy: lifecycleActor.actorId,
    auditEvents: [event],
  });
}

function transitionOutcome(
  current: WorkspaceLifecycleState,
  transition: WorkspaceLifecycleTransition,
): { state: WorkspaceLifecycleState; eventType: WorkspaceLifecycleEventType } {
  switch (transition.type) {
    case "approve":
      if (current !== "pending") break;
      return { state: "approved", eventType: "workspace_approved" };
    case "reject":
      if (current !== "pending") break;
      return { state: "rejected", eventType: "workspace_rejected" };
    case "suspend":
      if (current !== "approved") break;
      return { state: "suspended", eventType: "workspace_suspended" };
    case "resume":
      if (current !== "suspended") break;
      return { state: "approved", eventType: "workspace_resumed" };
    case "expire":
      if (current !== "approved" && current !== "suspended") break;
      return { state: "expired", eventType: "workspace_expired" };
    case "revoke":
      if (current !== "approved" && current !== "suspended") break;
      return { state: "revoked", eventType: "workspace_revoked" };
  }
  fail(
    "invalid_transition",
    `${transition.type} is not permitted from ${current}.`,
  );
}

export function applyWorkspaceLifecycleTransition(
  lifecycle: WorkspaceLifecycleAggregate,
  transition: WorkspaceLifecycleTransition,
): WorkspaceLifecycleAggregate {
  if (lifecycle.schemaVersion !== 1) {
    fail("invalid_input", "workspace lifecycle schema version is unsupported.");
  }
  const lifecycleActor = actor(transition.actor);
  if (lifecycleActor.tenantId !== lifecycle.tenantId) {
    fail("tenant_mismatch", "actor cannot change another tenant's workspace.");
  }
  if (identifier(transition.workspaceId, "workspace id") !== lifecycle.workspaceId) {
    fail("workspace_mismatch", "transition targets a different workspace.");
  }
  if (positiveVersion(transition.expectedVersion) !== lifecycle.version) {
    fail(
      "version_conflict",
      `expected version ${transition.expectedVersion} does not match ${lifecycle.version}.`,
    );
  }
  requireScope(
    lifecycleActor,
    transition.type === "approve" || transition.type === "reject"
      ? REVIEW_SCOPE
      : OPERATE_SCOPE,
  );
  const occurredAt = timestamp(transition.occurredAt, "occurredAt");
  if (Date.parse(occurredAt) < Date.parse(lifecycle.requestedAt)) {
    fail("invalid_transition", "transition cannot predate the workspace request.");
  }
  const reason = boundedReason(transition.reason);
  const outcome = transitionOutcome(lifecycle.state, transition);
  let effectiveFrom = lifecycle.effectiveFrom;
  let expiresAt = lifecycle.expiresAt;

  if (transition.type === "approve") {
    effectiveFrom = timestamp(transition.effectiveFrom, "effectiveFrom");
    expiresAt = timestamp(transition.expiresAt, "expiresAt");
    if (Date.parse(expiresAt) <= Date.parse(effectiveFrom)) {
      fail("invalid_transition", "workspace expiry must follow activation.");
    }
  }
  if (transition.type === "expire") {
    if (
      expiresAt === undefined ||
      Date.parse(occurredAt) < Date.parse(expiresAt)
    ) {
      fail("invalid_transition", "workspace cannot expire before its expiry.");
    }
  }

  const version = lifecycle.version + 1;
  const event = freezeEvent({
    eventId: `${lifecycle.workspaceId}:${version}`,
    eventType: outcome.eventType,
    aggregateVersion: version,
    transitionId: identifier(transition.transitionId, "transition id"),
    tenantId: lifecycle.tenantId,
    workspaceId: lifecycle.workspaceId,
    requestId: lifecycle.requestId,
    actorId: lifecycleActor.actorId,
    occurredAt,
    fromState: lifecycle.state,
    toState: outcome.state,
    reason,
  });
  return freezeAggregate({
    ...lifecycle,
    state: outcome.state,
    version,
    ...(effectiveFrom === undefined ? {} : { effectiveFrom }),
    ...(expiresAt === undefined ? {} : { expiresAt }),
    reason,
    auditEvents: [...lifecycle.auditEvents, event],
  });
}
