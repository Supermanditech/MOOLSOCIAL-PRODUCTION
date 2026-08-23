import assert from "node:assert/strict";
import test from "node:test";

import {
  PrivilegedCommandError,
  authorizePrivilegedCommand,
  completePrivilegedCommand,
  type AuthorizePrivilegedCommandRequest,
  type NewPrivilegedCommandReservation,
  type PrivilegedCommandEnvelope,
  type PrivilegedCommandErrorCode,
  type PrivilegedCommandReceipt,
} from "./privileged_command_contract.js";

const RESULT_HASH = "A".repeat(64);

function command(
  overrides: Partial<PrivilegedCommandEnvelope> = {},
): PrivilegedCommandEnvelope {
  return {
    schemaVersion: 1,
    commandId: "command.approve-001",
    aggregateId: "workspace.grocery-001",
    expectedVersion: 2,
    occurredAt: "2026-08-07T01:00:00.000Z",
    confirmed: true,
    reason: "Verified evidence permits this exact capability.",
    actor: {
      actorId: "operator.identity-review-001",
      tenantId: "tenant.india-001",
      scopes: ["workspace.lifecycle.review"],
    },
    payload: {
      decision: "approve",
      workspaceProfileId: "profile.grocery-kirana-shop",
    },
    ...overrides,
  };
}

function request(
  overrides: Partial<AuthorizePrivilegedCommandRequest> = {},
): AuthorizePrivilegedCommandRequest {
  return {
    tenantId: "tenant.india-001",
    aggregateId: "workspace.grocery-001",
    currentVersion: 2,
    requiredScope: "workspace.lifecycle.review",
    receipts: [],
    command: command(),
    ...overrides,
  };
}

function expectCode(
  callback: () => unknown,
  code: PrivilegedCommandErrorCode,
): void {
  assert.throws(
    callback,
    (error: unknown) =>
      error instanceof PrivilegedCommandError && error.code === code,
  );
}

function newReservation(
  overrides: Partial<AuthorizePrivilegedCommandRequest> = {},
): NewPrivilegedCommandReservation {
  const result = authorizePrivilegedCommand(request(overrides));
  assert.equal(result.state, "new");
  return result as NewPrivilegedCommandReservation;
}

function complete(
  reservation: NewPrivilegedCommandReservation,
  currentReceipts: readonly PrivilegedCommandReceipt[] = [],
) {
  return completePrivilegedCommand({
    reservation,
    currentReceipts,
    newAggregateVersion: reservation.expectedVersion + 1,
    resultReference: "result.workspace-approved-001",
    resultSha256: RESULT_HASH,
    completedAt: "2026-08-07T01:01:00.000Z",
  });
}

test("authorizes one exact confirmed scoped command reservation", () => {
  const result = newReservation();
  assert.equal(result.state, "new");
  assert.equal(result.commandFingerprint.length, 64);
  assert.equal(result.requiredScope, "workspace.lifecycle.review");
  assert.equal(Object.isFrozen(result), true);
});

test("authorization and tenant binding precede replay or version state", () => {
  const reservation = newReservation();
  const receipts = complete(reservation);
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({
          currentVersion: 999,
          receipts,
          command: command({
            actor: { ...command().actor, scopes: [] },
          }),
        }),
      ),
    "unauthorized",
  );
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({
          receipts,
          command: command({
            actor: { ...command().actor, tenantId: "tenant.other-001" },
          }),
        }),
      ),
    "tenant_mismatch",
  );
});

test("requires explicit confirmation", () => {
  expectCode(
    () => authorizePrivilegedCommand(request({ command: command({ confirmed: false }) })),
    "unauthorized",
  );
});

test("rejects aggregate mismatch and stale version", () => {
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({ command: command({ aggregateId: "workspace.other-001" }) }),
      ),
    "aggregate_mismatch",
  );
  expectCode(
    () => authorizePrivilegedCommand(request({ currentVersion: 3 })),
    "version_conflict",
  );
});

test("canonical payload order produces one deterministic fingerprint", () => {
  const left = newReservation({
    command: command({ payload: { alpha: 1, beta: { left: true, right: false } } }),
  });
  const right = newReservation({
    command: command({ payload: { beta: { right: false, left: true }, alpha: 1 } }),
  });
  assert.equal(left.commandFingerprint, right.commandFingerprint);
});

test("exact retry returns the immutable prior receipt", () => {
  const reservation = newReservation();
  const receipts = complete(reservation);
  const replay = authorizePrivilegedCommand(
    request({ currentVersion: 3, receipts }),
  );
  assert.equal(replay.state, "replay");
  if (replay.state === "replay") {
    assert.equal(replay.receipt.resultSha256, RESULT_HASH);
    assert.equal(Object.isFrozen(replay.receipt), true);
  }
});

test("changed payload under one command id is an idempotency conflict", () => {
  const reservation = newReservation();
  const receipts = complete(reservation);
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({
          currentVersion: 3,
          receipts,
          command: command({ payload: { decision: "reject" } }),
        }),
      ),
    "idempotency_conflict",
  );
});

test("changed actor reason scope or expected version conflicts on replay", () => {
  const reservation = newReservation();
  const receipts = complete(reservation);
  const variants = [
    command({ reason: "A different valid command reason." }),
    command({ expectedVersion: 3 }),
    command({ actor: { ...command().actor, actorId: "operator.other-001" } }),
  ];
  for (const changedCommand of variants) {
    expectCode(
      () =>
        authorizePrivilegedCommand(
          request({ currentVersion: 3, receipts, command: changedCommand }),
        ),
      "idempotency_conflict",
    );
  }
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({
          currentVersion: 3,
          receipts,
          requiredScope: "workspace.lifecycle.operate",
          command: command({
            actor: {
              ...command().actor,
              scopes: [
                "workspace.lifecycle.review",
                "workspace.lifecycle.operate",
              ],
            },
          }),
        }),
      ),
    "idempotency_conflict",
  );
});

test("completion appends one immutable SHA-bound receipt", () => {
  const reservation = newReservation();
  const receipts = complete(reservation);
  assert.equal(receipts.length, 1);
  assert.equal(receipts[0]?.aggregateVersion, 3);
  assert.equal(receipts[0]?.commandFingerprint, reservation.commandFingerprint);
  assert.equal(receipts[0]?.resultSha256, RESULT_HASH);
  assert.equal(Object.isFrozen(receipts), true);
  assert.equal(Object.isFrozen(receipts[0]), true);
});

test("one reservation cannot be completed twice", () => {
  const reservation = newReservation();
  const receipts = complete(reservation);
  expectCode(() => complete(reservation, receipts), "reservation_conflict");
});

test("completion advances exactly one version and validates result identity", () => {
  const reservation = newReservation();
  expectCode(
    () =>
      completePrivilegedCommand({
        reservation,
        currentReceipts: [],
        newAggregateVersion: 4,
        resultReference: "result.workspace-approved-001",
        resultSha256: RESULT_HASH,
        completedAt: "2026-08-07T01:01:00.000Z",
      }),
    "version_conflict",
  );
  expectCode(
    () =>
      completePrivilegedCommand({
        reservation,
        currentReceipts: [],
        newAggregateVersion: 3,
        resultReference: "bad/result",
        resultSha256: RESULT_HASH,
        completedAt: "2026-08-07T01:01:00.000Z",
      }),
    "invalid_input",
  );
});

test("rejects sensitive fields anywhere in payload", () => {
  for (const payload of [
    { accessToken: "secret" },
    { nested: { authorization: "Bearer secret" } },
    { credential_value: "secret" },
  ]) {
    expectCode(
      () => authorizePrivilegedCommand(request({ command: command({ payload }) })),
      "sensitive_payload",
    );
  }
});

test("rejects non-JSON finite unsafe or oversized payload values", () => {
  for (const payload of [
    { bad: Number.NaN },
    { bad: Number.POSITIVE_INFINITY },
    { bad: new Date() },
    { bad: () => true },
  ]) {
    expectCode(
      () =>
        authorizePrivilegedCommand(
          request({ command: command({ payload: payload as never }) }),
        ),
      "invalid_input",
    );
  }
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({ command: command({ payload: { value: "x".repeat(4_001) } }) }),
      ),
    "invalid_input",
  );
});

test("bounds payload depth collection size and receipt history", () => {
  let nested: Record<string, unknown> = { value: true };
  for (let index = 0; index < 9; index += 1) nested = { nested };
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({ command: command({ payload: nested as never }) }),
      ),
    "invalid_input",
  );
  expectCode(
    () =>
      authorizePrivilegedCommand(
        request({ command: command({ payload: Array.from({ length: 101 }, () => 1) }) }),
      ),
    "invalid_input",
  );
  const sampleReceipt = complete(newReservation())[0]!;
  const receipts = Array.from({ length: 501 }, (_, index) => ({
    ...sampleReceipt,
    commandId: `command.history-${index}`,
  }));
  expectCode(
    () => authorizePrivilegedCommand(request({ receipts })),
    "invalid_input",
  );
});

test("validates command and receipt identifiers timestamps hashes and reasons", () => {
  expectCode(
    () => authorizePrivilegedCommand(request({ command: command({ commandId: "x" }) })),
    "invalid_input",
  );
  expectCode(
    () => authorizePrivilegedCommand(request({ command: command({ occurredAt: "bad" }) })),
    "invalid_input",
  );
  expectCode(
    () => authorizePrivilegedCommand(request({ command: command({ reason: "no" }) })),
    "invalid_input",
  );
  const reservation = newReservation();
  expectCode(
    () =>
      completePrivilegedCommand({
        reservation,
        currentReceipts: [],
        newAggregateVersion: 3,
        resultReference: "result.workspace-approved-001",
        resultSha256: "bad",
        completedAt: "2026-08-07T01:01:00.000Z",
      }),
    "invalid_input",
  );
});

test("does not mutate command payload or prior receipts", () => {
  const originalCommand = command({
    payload: { beta: [2, 1], alpha: { enabled: true } },
  });
  const beforeCommand = structuredClone(originalCommand);
  const reservation = newReservation({ command: originalCommand });
  assert.deepEqual(originalCommand, beforeCommand);
  const prior = complete(reservation);
  const beforeReceipts = structuredClone(prior);
  authorizePrivilegedCommand(request({ currentVersion: 3, receipts: prior, command: originalCommand }));
  assert.deepEqual(prior, beforeReceipts);
});
