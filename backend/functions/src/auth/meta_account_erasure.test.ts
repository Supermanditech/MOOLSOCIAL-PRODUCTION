import assert from "node:assert/strict";
import test from "node:test";

import {
  MetaAccountErasureCoordinator,
  MetaAccountErasureError,
  type MetaAccountErasureStore,
  type MetaErasureRecord,
} from "./meta_account_erasure.js";

class MemoryStore implements MetaAccountErasureStore {
  readonly records = new Map<string, MetaErasureRecord>();

  async read(code: string): Promise<MetaErasureRecord | undefined> {
    return this.records.get(code);
  }

  async createPending(record: MetaErasureRecord): Promise<boolean> {
    if (this.records.has(record.confirmationCode)) return false;
    this.records.set(record.confirmationCode, record);
    return true;
  }

  async markPending(code: string, attemptCount: number): Promise<void> {
    const record = this.required(code);
    const {
      completedAt: _completedAt,
      failedAt: _failedAt,
      failureStage: _failureStage,
      ...retained
    } = record;
    this.records.set(code, {
      ...retained,
      state: "pending",
      attemptCount,
    });
  }

  async markCompleted(code: string, completedAt: string): Promise<void> {
    const record = this.required(code);
    const {
      failedAt: _failedAt,
      failureStage: _failureStage,
      ...retained
    } = record;
    this.records.set(code, {
      ...retained,
      state: "completed",
      completedAt,
    });
  }

  async markFailed(
    code: string,
    failedAt: string,
    failureStage: string,
  ): Promise<void> {
    const record = this.required(code);
    this.records.set(code, {
      ...record,
      state: "failed",
      failedAt,
      failureStage,
    });
  }

  private required(code: string): MetaErasureRecord {
    const record = this.records.get(code);
    if (!record) throw new Error("Missing test erasure record.");
    return record;
  }
}

const code = "confirmation_code_1234567890";

test("completes once with an exact thirty-day target", async () => {
  const store = new MemoryStore();
  const erased: string[] = [];
  const times = [
    new Date("2026-08-21T00:00:00.000Z"),
    new Date("2026-08-21T00:00:01.000Z"),
  ];
  const coordinator = new MetaAccountErasureCoordinator({
    store,
    worker: {
      async eraseUser(userId: string): Promise<void> {
        erased.push(userId);
      },
    },
    now: () => times.shift() ?? new Date("2026-08-21T00:00:01.000Z"),
  });

  const status = await coordinator.request({
    provider: "facebook",
    confirmationCode: code,
    firebaseUserIds: ["user_b", "user_a", "user_a"],
  });

  assert.deepEqual(erased, ["user_a", "user_b"]);
  assert.deepEqual(status, {
    state: "completed",
    requestedAt: "2026-08-21T00:00:00.000Z",
    dueAt: "2026-09-20T00:00:00.000Z",
    completedAt: "2026-08-21T00:00:01.000Z",
  });
  assert.equal(store.records.get(code)?.attemptCount, 1);

  const replay = await coordinator.request({
    provider: "facebook",
    confirmationCode: code,
    firebaseUserIds: ["user_b", "user_a"],
  });
  assert.deepEqual(replay, status);
  assert.deepEqual(erased, ["user_a", "user_b"]);
});

test("partial failure remains failed and retries idempotently", async () => {
  const store = new MemoryStore();
  let fail = true;
  const erased: string[] = [];
  const coordinator = new MetaAccountErasureCoordinator({
    store,
    worker: {
      async eraseUser(userId: string): Promise<void> {
        if (userId === "user_b" && fail) throw new Error("transient");
        erased.push(userId);
      },
    },
    now: () => new Date("2026-08-21T00:00:00.000Z"),
  });

  await assert.rejects(
    coordinator.request({
      provider: "instagram",
      confirmationCode: code,
      firebaseUserIds: ["user_a", "user_b"],
    }),
    (error: unknown) =>
      error instanceof MetaAccountErasureError &&
      error.code === "erasure_failed" &&
      error.retryable,
  );
  assert.equal(store.records.get(code)?.state, "failed");
  assert.equal(store.records.get(code)?.attemptCount, 1);

  fail = false;
  const result = await coordinator.request({
    provider: "instagram",
    confirmationCode: code,
    firebaseUserIds: ["user_b", "user_a"],
  });
  assert.equal(result.state, "completed");
  assert.equal(store.records.get(code)?.attemptCount, 2);
  assert.deepEqual(erased, ["user_a", "user_a", "user_b"]);
});

test("confirmation codes cannot be rebound to another request", async () => {
  const store = new MemoryStore();
  const coordinator = new MetaAccountErasureCoordinator({
    store,
    worker: { eraseUser: async () => undefined },
    now: () => new Date("2026-08-21T00:00:00.000Z"),
  });
  await coordinator.request({
    provider: "facebook",
    confirmationCode: code,
    firebaseUserIds: ["user_a"],
  });

  await assert.rejects(
    coordinator.request({
      provider: "facebook",
      confirmationCode: code,
      firebaseUserIds: ["user_b"],
    }),
    (error: unknown) =>
      error instanceof MetaAccountErasureError && error.code === "conflict",
  );
});

test("public status exposes no provider or user identity", async () => {
  const store = new MemoryStore();
  const coordinator = new MetaAccountErasureCoordinator({
    store,
    worker: { eraseUser: async () => undefined },
    now: () => new Date("2026-08-21T00:00:00.000Z"),
  });
  await coordinator.request({
    provider: "instagram",
    confirmationCode: code,
    firebaseUserIds: ["user_private"],
  });

  const serialized = JSON.stringify(await coordinator.status(code));
  assert.doesNotMatch(serialized, /instagram|user_private|firebaseUserIds/u);
  assert.match(serialized, /completed/u);
});

test("an already absent provider account completes without inventing identity", async () => {
  const store = new MemoryStore();
  const coordinator = new MetaAccountErasureCoordinator({
    store,
    worker: {
      eraseUser: async () => assert.fail("No synthetic user may be erased."),
    },
    now: () => new Date("2026-08-21T00:00:00.000Z"),
  });

  const result = await coordinator.request({
    provider: "facebook",
    confirmationCode: code,
    firebaseUserIds: [],
  });
  assert.equal(result.state, "completed");
  assert.deepEqual(store.records.get(code)?.firebaseUserIds, []);
});
