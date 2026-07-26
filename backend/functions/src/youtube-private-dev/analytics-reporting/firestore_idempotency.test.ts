import assert from "node:assert/strict";
import test from "node:test";

import type {
  ProviderDocument,
  ProviderDocumentDatabase,
  ProviderDocumentTransaction,
} from "../../youtube/firestore_store.js";
import {
  FirestoreAnalyticsReportingIdempotency,
  analyticsReportingIdempotencyLimits,
} from "./firestore_idempotency.js";

type StoredDocument = Readonly<Record<string, unknown>>;

class InMemoryProviderDocumentDatabase
  implements ProviderDocumentDatabase
{
  private documents = new Map<string, StoredDocument>();

  async get(path: string): Promise<StoredDocument | undefined> {
    return this.documents.get(path);
  }

  async set(path: string, data: StoredDocument): Promise<void> {
    this.documents.set(path, structuredClone(data));
  }

  async delete(path: string): Promise<void> {
    this.documents.delete(path);
  }

  async queryByField(
    collectionPath: string,
    field: string,
    value: string,
  ): Promise<readonly ProviderDocument[]> {
    return [...this.documents.entries()]
      .filter(
        ([path, data]) =>
          path.startsWith(`${collectionPath}/`) && data[field] === value,
      )
      .map(([path, data]) => ({ path, data }));
  }

  async deleteMany(paths: readonly string[]): Promise<void> {
    for (const path of paths) this.documents.delete(path);
  }

  async runTransaction<T>(
    operation: (transaction: ProviderDocumentTransaction) => Promise<T>,
  ): Promise<T> {
    const working = new Map(
      [...this.documents.entries()].map(([path, data]) => [
        path,
        structuredClone(data),
      ]),
    );
    const result = await operation({
      get: async (path) => working.get(path),
      create: (path, data) => {
        if (working.has(path)) throw new Error("Document already exists.");
        working.set(path, structuredClone(data));
      },
      set: (path, data) => working.set(path, structuredClone(data)),
      delete: (path) => {
        working.delete(path);
      },
    });
    this.documents = working;
    return result;
  }

  allDocuments(): readonly StoredDocument[] {
    return [...this.documents.values()];
  }
}

const fingerprintA = "a".repeat(64);
const fingerprintB = "b".repeat(64);

test("Firestore idempotency reserves, conflicts and replays completed results durably", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const first = new FirestoreAnalyticsReportingIdempotency(
    database,
    "founder-owner",
  );
  assert.deepEqual(
    await first.reserve(
      "youtubeAnalytics.groups.insert",
      "create-group-0001",
      fingerprintA,
    ),
    { state: "new" },
  );
  assert.deepEqual(
    await first.reserve(
      "youtubeAnalytics.groups.insert",
      "create-group-0001",
      fingerprintA,
    ),
    { state: "in_progress" },
  );
  assert.deepEqual(
    await first.reserve(
      "youtubeAnalytics.groups.insert",
      "create-group-0001",
      fingerprintB,
    ),
    { state: "conflict" },
  );
  const result = { groupId: "group_1", title: "Priority videos" };
  await first.complete(
    "youtubeAnalytics.groups.insert",
    "create-group-0001",
    fingerprintA,
    result,
  );

  const restartedProcess = new FirestoreAnalyticsReportingIdempotency(
    database,
    "founder-owner",
  );
  assert.deepEqual(
    await restartedProcess.reserve(
      "youtubeAnalytics.groups.insert",
      "create-group-0001",
      fingerprintA,
    ),
    { state: "completed", result },
  );
  const stored = database.allDocuments().at(0);
  assert.equal(stored?.provider, "YOUTUBE");
  assert.equal(stored?.surface, "ANALYTICS_REPORTING");
  assert.equal(stored?.userId, "founder-owner");
  assert.equal(stored?.state, "COMPLETED");
  assert.equal("create-group-0001" in (stored ?? {}), false);
  assert.equal(
    JSON.stringify(stored).includes("create-group-0001"),
    false,
  );
});

test("idempotency keys are scoped by authenticated owner", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const ownerA = new FirestoreAnalyticsReportingIdempotency(
    database,
    "owner-a",
  );
  const ownerB = new FirestoreAnalyticsReportingIdempotency(
    database,
    "owner-b",
  );
  assert.deepEqual(
    await ownerA.reserve(
      "youtubereporting.jobs.create",
      "create-job-0001",
      fingerprintA,
    ),
    { state: "new" },
  );
  assert.deepEqual(
    await ownerB.reserve(
      "youtubereporting.jobs.create",
      "create-job-0001",
      fingerprintA,
    ),
    { state: "new" },
  );
  assert.equal(database.allDocuments().length, 2);
});

test("an expired in-progress lease can resume only with the same fingerprint", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  let now = new Date("2026-07-25T00:00:00.000Z");
  const store = new FirestoreAnalyticsReportingIdempotency(
    database,
    "founder-owner",
    () => now,
  );
  assert.deepEqual(
    await store.reserve(
      "youtubeAnalytics.groups.update",
      "update-group-0001",
      fingerprintA,
    ),
    { state: "new" },
  );
  now = new Date(
    now.getTime() +
      analyticsReportingIdempotencyLimits.inProgressLeaseMilliseconds +
      1,
  );
  assert.deepEqual(
    await store.reserve(
      "youtubeAnalytics.groups.update",
      "update-group-0001",
      fingerprintB,
    ),
    { state: "conflict" },
  );
  assert.deepEqual(
    await store.reserve(
      "youtubeAnalytics.groups.update",
      "update-group-0001",
      fingerprintA,
    ),
    { state: "new" },
  );
});

test("release permits a failed mutation to be retried", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const store = new FirestoreAnalyticsReportingIdempotency(
    database,
    "founder-owner",
  );
  assert.deepEqual(
    await store.reserve(
      "youtubereporting.jobs.delete",
      "delete-job-0001",
      fingerprintA,
    ),
    { state: "new" },
  );
  await store.release(
    "youtubereporting.jobs.delete",
    "delete-job-0001",
    fingerprintA,
  );
  assert.deepEqual(
    await store.reserve(
      "youtubereporting.jobs.delete",
      "delete-job-0001",
      fingerprintA,
    ),
    { state: "new" },
  );
});

test("completed mutation results have a strict Firestore storage cap", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const store = new FirestoreAnalyticsReportingIdempotency(
    database,
    "founder-owner",
  );
  await store.reserve(
    "youtubeAnalytics.groups.insert",
    "large-result-0001",
    fingerprintA,
  );
  await assert.rejects(
    store.complete(
      "youtubeAnalytics.groups.insert",
      "large-result-0001",
      fingerprintA,
      {
        value: "x".repeat(
          analyticsReportingIdempotencyLimits.maximumCompletedResultBytes,
        ),
      },
    ),
    /storage boundary/u,
  );
});
