import assert from "node:assert/strict";
import test from "node:test";

import {
  FirestoreOAuthAttemptStore,
  FirestoreRefreshTokenPersistence,
  FirestoreYouTubeAuditStore,
  FirestoreYouTubeConnectionStore,
  FirestoreYouTubePublicationStore,
  FirestoreYouTubeQuotaStore,
  type ProviderDocument,
  type ProviderDocumentDatabase,
  type ProviderDocumentTransaction,
} from "./firestore_store.js";
import type { OAuthAttemptRecord } from "./oauth_attempt_store.js";
import type { YouTubeProviderConnectionRecord } from "./types.js";

type StoredDocument = Readonly<Record<string, unknown>>;

function copy<T>(value: T): T {
  return structuredClone(value);
}

class InMemoryProviderDocumentDatabase
  implements ProviderDocumentDatabase
{
  private readonly documents = new Map<string, StoredDocument>();
  private transactionTail: Promise<void> = Promise.resolve();

  async get(path: string): Promise<StoredDocument | undefined> {
    const value = this.documents.get(path);
    return value === undefined ? undefined : copy(value);
  }

  async set(path: string, data: StoredDocument): Promise<void> {
    this.documents.set(path, copy(data));
  }

  async delete(path: string): Promise<void> {
    this.documents.delete(path);
  }

  async queryByField(
    collectionPath: string,
    field: string,
    value: string,
  ): Promise<readonly ProviderDocument[]> {
    const prefix = `${collectionPath}/`;
    return [...this.documents.entries()]
      .filter(
        ([path, data]) =>
          path.startsWith(prefix) && data[field] === value,
      )
      .map(([path, data]) => ({ path, data: copy(data) }));
  }

  async deleteMany(paths: readonly string[]): Promise<void> {
    for (const path of paths) this.documents.delete(path);
  }

  async runTransaction<T>(
    operation: (transaction: ProviderDocumentTransaction) => Promise<T>,
  ): Promise<T> {
    let release!: () => void;
    const previous = this.transactionTail;
    this.transactionTail = new Promise<void>((resolve) => {
      release = resolve;
    });
    await previous;
    const working = new Map<string, StoredDocument>(
      [...this.documents.entries()].map(([path, value]) => [
        path,
        copy(value),
      ]),
    );
    const transaction: ProviderDocumentTransaction = {
      get: async (path) => {
        const value = working.get(path);
        return value === undefined ? undefined : copy(value);
      },
      create: (path, data) => {
        if (working.has(path)) {
          throw new Error("Document already exists.");
        }
        working.set(path, copy(data));
      },
      set: (path, data) => {
        working.set(path, copy(data));
      },
      delete: (path) => {
        working.delete(path);
      },
    };
    try {
      const result = await operation(transaction);
      this.documents.clear();
      for (const [path, value] of working) {
        this.documents.set(path, value);
      }
      return result;
    } finally {
      release();
    }
  }

  all(): readonly ProviderDocument[] {
    return [...this.documents.entries()].map(([path, data]) => ({
      path,
      data: copy(data),
    }));
  }
}

const activeConnection: YouTubeProviderConnectionRecord = {
  connectionKey: "ytc-user-1",
  userId: "user-1",
  channelId: "channel-1",
  channelTitle: "Channel One",
  grantedScopes: ["scope.read", "scope.upload"],
  connectedAt: "2026-07-24T00:00:00.000Z",
  lastVerifiedAt: "2026-07-24T00:00:00.000Z",
  status: "ACTIVE",
};

function publication(jobKey = "ytj-job-1") {
  return {
    jobKey,
    userId: "user-1",
    connectionKey: activeConnection.connectionKey,
    idempotencyKey: "upload-once",
    requestFingerprint: "fingerprint-1",
    title: "Private provider proof",
    privacyStatus: "private" as const,
    contentLength: 1_024,
    encryptedSessionUrl: "",
    state: "SESSION_CREATING" as const,
    createdAt: "2026-07-24T00:00:00.000Z",
    updatedAt: "2026-07-24T00:00:00.000Z",
  };
}

test("connection and publication transactions fail closed after revocation", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const connections = new FirestoreYouTubeConnectionStore(database);
  const publications = new FirestoreYouTubePublicationStore(database);

  await connections.save(activeConnection);
  assert.deepEqual(await connections.getByUser("user-1"), activeConnection);

  const first = await publications.reserve(publication());
  assert.equal(first.created, true);
  const duplicate = await publications.reserve(publication());
  assert.equal(duplicate.created, false);
  assert.equal(duplicate.record.requestFingerprint, "fingerprint-1");

  await publications.update("user-1", "ytj-job-1", {
    encryptedSessionUrl: "mstv1.k2.nonce.cipher.tag",
    sessionExpiresAt: "2026-07-24T01:00:00.000Z",
    state: "SESSION_READY",
    updatedAt: "2026-07-24T00:01:00.000Z",
  });
  assert.equal(
    (await publications.getByKey("user-1", "ytj-job-1"))?.state,
    "SESSION_READY",
  );
  assert.equal(
    (
      await publications.getByIdempotencyKey("user-1", "upload-once")
    )?.jobKey,
    "ytj-job-1",
  );

  await connections.markRevoked(
    activeConnection.connectionKey,
    "2026-07-24T00:02:00.000Z",
  );
  assert.equal(await connections.getByUser("user-1"), null);
  await assert.rejects(
    publications.update("user-1", "ytj-job-1", {
      state: "PROCESSING",
    }),
    /connection is not active/u,
  );
  await assert.rejects(
    publications.reserve(publication("ytj-job-2")),
    /connection is not active/u,
  );
});

test("publication storage rejects immutable mutation and deletes only the owner records", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const connections = new FirestoreYouTubeConnectionStore(database);
  const publications = new FirestoreYouTubePublicationStore(database);
  await connections.save(activeConnection);
  await publications.reserve(publication());

  await assert.rejects(
    publications.update("user-1", "ytj-job-1", {
      title: "Changed after reservation",
    }),
    /immutable fields: title/u,
  );
  assert.equal(
    await publications.getByKey("another-user", "ytj-job-1"),
    null,
  );
  await publications.deleteByUser("user-1");
  assert.equal(
    await publications.getByKey("user-1", "ytj-job-1"),
    null,
  );
});

test("encrypted refresh-token migration uses compare-and-set", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const persistence = new FirestoreRefreshTokenPersistence(database);
  const original = {
    connectionKey: activeConnection.connectionKey,
    encryptedRefreshToken: "mstv1.k1.nonce.cipher.tag",
    grantedScopes: ["scope.read"],
    createdAt: "2026-07-24T00:00:00.000Z",
    updatedAt: "2026-07-24T00:00:00.000Z",
  };
  await persistence.put(original);
  assert.deepEqual(await persistence.get(original.connectionKey), original);

  const replacements = ["replacement-a", "replacement-b"].map(
    (encryptedRefreshToken, index) =>
      persistence.replaceIfCurrent(original.encryptedRefreshToken, {
        ...original,
        encryptedRefreshToken,
        updatedAt: `2026-07-24T00:0${index + 1}:00.000Z`,
      }),
  );
  const outcomes = await Promise.all(replacements);
  assert.equal(outcomes.filter(Boolean).length, 1);
  assert.notEqual(
    (await persistence.get(original.connectionKey))
      ?.encryptedRefreshToken,
    original.encryptedRefreshToken,
  );
  await persistence.delete(original.connectionKey);
  assert.equal(await persistence.get(original.connectionKey), undefined);
});

test("OAuth attempts are consumed once, bound to the user and expire", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  let now = new Date("2026-07-24T00:05:00.000Z");
  const store = new FirestoreOAuthAttemptStore(database, () => now);
  const attempt: OAuthAttemptRecord = {
    stateHash: "state-hash-1",
    userId: "user-1",
    encryptedCodeVerifier: "mstv1.k2.nonce.cipher.tag",
    requestedScopes: ["scope.read"],
    redirectUri: "https://example.invalid/oauth/callback",
    createdAt: "2026-07-24T00:00:00.000Z",
    expiresAt: "2026-07-24T00:10:00.000Z",
  };
  await store.save(attempt);
  assert.equal(await store.consume(attempt.stateHash, "other-user"), null);
  const concurrent = await Promise.all([
    store.consume(attempt.stateHash, attempt.userId),
    store.consume(attempt.stateHash, attempt.userId),
  ]);
  assert.equal(
    concurrent.filter((result) => result !== null).length,
    1,
  );
  assert.deepEqual(concurrent.find((result) => result !== null), attempt);

  const expired = { ...attempt, stateHash: "state-hash-expired" };
  await store.save(expired);
  now = new Date("2026-07-24T00:11:00.000Z");
  assert.equal(await store.consumeByState(expired.stateHash), null);
  await store.deleteByUser("user-1");
  assert.equal(database.all().length, 0);
});

test("quota reservations are atomic and never exceed the Dev cap", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const quota = new FirestoreYouTubeQuotaStore(database);
  const request = {
    bucket: "search" as const,
    windowId: "2026-07-24",
    resetAt: "2026-07-25T00:00:00.000Z",
    units: 3,
    limit: 10,
  };
  const results = await Promise.all(
    Array.from({ length: 4 }, () => quota.reserve(request)),
  );
  assert.equal(results.filter((result) => result.allowed).length, 3);
  assert.equal(results.filter((result) => !result.allowed).length, 1);
  assert.ok(results.every((result) => result.used <= 9));
  const rejected = await quota.reserve({ ...request, units: 2 });
  assert.equal(rejected.allowed, false);
  assert.equal(rejected.used, 9);
});

test("audit storage is append-only, idempotent and redacts credentials", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const audit = new FirestoreYouTubeAuditStore(database);
  const event = {
    userId: "user-1",
    eventType: "connection.disconnect_completed",
    requestId: "request-1",
    detail: {
      accessToken: "must-not-persist",
      providerRevocationConfirmed: true,
    },
    occurredAt: "2026-07-24T00:00:00.000Z",
  };
  await audit.record(event);
  await audit.record({
    ...event,
    detail: { accessToken: "a-different-secret" },
  });

  const records = database.all();
  assert.equal(records.length, 1);
  const serialized = String(records[0]?.data.redactedDetailJson);
  assert.doesNotMatch(serialized, /must-not-persist|a-different-secret/u);
  assert.match(serialized, /\[REDACTED\]/u);
  assert.equal(records[0]?.data.eventType, event.eventType);

  await assert.rejects(
    audit.record({
      ...event,
      requestId: "request-too-large",
      detail: { value: "x".repeat(17_000) },
    }),
    /safe size limit/u,
  );
});

test("provider document IDs do not expose raw account or OAuth values", async () => {
  const database = new InMemoryProviderDocumentDatabase();
  const connections = new FirestoreYouTubeConnectionStore(database);
  const oauth = new FirestoreOAuthAttemptStore(database);
  await connections.save(activeConnection);
  await oauth.save({
    stateHash: "sensitive-oauth-state",
    userId: "sensitive-user-id",
    encryptedCodeVerifier: "encrypted",
    requestedScopes: ["scope.read"],
    redirectUri: "https://example.invalid/callback",
    createdAt: "2026-07-24T00:00:00.000Z",
    expiresAt: "2026-07-24T00:10:00.000Z",
  });
  const paths = database.all().map((document) => document.path);
  assert.ok(
    paths.every(
      (path) =>
        !path.includes("sensitive-user-id") &&
        !path.includes("sensitive-oauth-state") &&
        !path.includes(activeConnection.connectionKey),
    ),
  );
});
