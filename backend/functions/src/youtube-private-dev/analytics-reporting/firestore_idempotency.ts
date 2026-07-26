import { createHash } from "node:crypto";

import type { ProviderDocumentDatabase } from "../../youtube/firestore_store.js";
import type {
  IdempotencyPort,
  IdempotencyReservation,
} from "./contracts.js";

const COLLECTION = "youtubeAnalyticsReportingIdempotency";
const PROVIDER = "YOUTUBE";
const SURFACE = "ANALYTICS_REPORTING";
const SAFE_IDENTITY = /^[A-Za-z0-9._:-]{1,160}$/u;
const SHA256_HEX = /^[a-f0-9]{64}$/u;
const IN_PROGRESS_LEASE_MILLISECONDS = 5 * 60 * 1000;
const MAX_COMPLETED_RESULT_BYTES = 256 * 1024;

type StoredDocument = Readonly<Record<string, unknown>>;

function digest(value: string): string {
  return createHash("sha256").update(value, "utf8").digest("base64url");
}

function pathFor(
  userId: string,
  namespace: string,
  key: string,
): string {
  return `${COLLECTION}/ytar_${digest(
    `${userId}\u001f${namespace}\u001f${key}`,
  )}`;
}

function requireSafeIdentity(value: string, label: string): string {
  const clean = value.trim();
  if (!SAFE_IDENTITY.test(clean)) {
    throw new Error(`YouTube analytics idempotency has an invalid ${label}.`);
  }
  return clean;
}

function requireStoredString(
  document: StoredDocument,
  field: string,
): string {
  const value = document[field];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(
      `YouTube analytics idempotency has an invalid ${field}.`,
    );
  }
  return value;
}

function validTimestamp(value: string): boolean {
  return Number.isFinite(Date.parse(value));
}

function assertStoredIdentity(
  document: StoredDocument,
  expected: {
    readonly userId: string;
    readonly namespace: string;
    readonly keyDigest: string;
  },
): void {
  if (
    document.provider !== PROVIDER ||
    document.surface !== SURFACE ||
    document.userId !== expected.userId ||
    document.namespace !== expected.namespace ||
    document.idempotencyKeyDigest !== expected.keyDigest
  ) {
    throw new Error("YouTube analytics idempotency record is invalid.");
  }
  const fingerprint = requireStoredString(document, "fingerprint");
  const createdAt = requireStoredString(document, "createdAt");
  const updatedAt = requireStoredString(document, "updatedAt");
  if (
    !SHA256_HEX.test(fingerprint) ||
    !validTimestamp(createdAt) ||
    !validTimestamp(updatedAt)
  ) {
    throw new Error("YouTube analytics idempotency record is invalid.");
  }
}

function completedResult(document: StoredDocument): unknown {
  const resultJson = requireStoredString(document, "resultJson");
  const resultBytes = Buffer.byteLength(resultJson, "utf8");
  if (
    resultBytes > MAX_COMPLETED_RESULT_BYTES ||
    document.resultByteLength !== resultBytes
  ) {
    throw new Error(
      "YouTube analytics idempotency result exceeds its storage boundary.",
    );
  }
  try {
    return JSON.parse(resultJson) as unknown;
  } catch {
    throw new Error("YouTube analytics idempotency result is invalid.");
  }
}

/**
 * Durable, user-scoped reservation store for the small mutation results
 * produced by YouTube Analytics v2 and Reporting v1. Raw idempotency keys are
 * never persisted; their digest, operation namespace, request fingerprint and
 * state remain reviewable.
 */
export class FirestoreAnalyticsReportingIdempotency
  implements IdempotencyPort
{
  private readonly userId: string;

  constructor(
    private readonly database: ProviderDocumentDatabase,
    userId: string,
    private readonly now: () => Date = () => new Date(),
  ) {
    this.userId = requireSafeIdentity(userId, "user");
  }

  async reserve(
    namespaceInput: string,
    key: string,
    fingerprint: string,
  ): Promise<IdempotencyReservation> {
    const namespace = requireSafeIdentity(namespaceInput, "namespace");
    if (!SHA256_HEX.test(fingerprint)) {
      throw new Error(
        "YouTube analytics idempotency fingerprint is invalid.",
      );
    }
    const keyDigest = digest(key);
    const path = pathFor(this.userId, namespace, key);
    return this.database.runTransaction(async (transaction) => {
      const existing = await transaction.get(path);
      const timestamp = this.now();
      const timestampText = timestamp.toISOString();
      const leaseExpiresAt = new Date(
        timestamp.getTime() + IN_PROGRESS_LEASE_MILLISECONDS,
      ).toISOString();
      if (existing === undefined) {
        transaction.create(path, {
          provider: PROVIDER,
          surface: SURFACE,
          userId: this.userId,
          namespace,
          idempotencyKeyDigest: keyDigest,
          fingerprint,
          state: "IN_PROGRESS",
          createdAt: timestampText,
          updatedAt: timestampText,
          leaseExpiresAt,
        });
        return { state: "new" };
      }
      assertStoredIdentity(existing, {
        userId: this.userId,
        namespace,
        keyDigest,
      });
      if (existing.fingerprint !== fingerprint) {
        return { state: "conflict" };
      }
      if (existing.state === "COMPLETED") {
        return {
          state: "completed",
          result: completedResult(existing),
        };
      }
      if (existing.state !== "IN_PROGRESS") {
        throw new Error(
          "YouTube analytics idempotency state is invalid.",
        );
      }
      const existingLease = requireStoredString(
        existing,
        "leaseExpiresAt",
      );
      if (!validTimestamp(existingLease)) {
        throw new Error(
          "YouTube analytics idempotency lease is invalid.",
        );
      }
      if (Date.parse(existingLease) > timestamp.getTime()) {
        return { state: "in_progress" };
      }
      transaction.set(path, {
        ...existing,
        updatedAt: timestampText,
        leaseExpiresAt,
      });
      return { state: "new" };
    });
  }

  async complete(
    namespaceInput: string,
    key: string,
    fingerprint: string,
    result: unknown,
  ): Promise<void> {
    const namespace = requireSafeIdentity(namespaceInput, "namespace");
    const keyDigest = digest(key);
    const resultJson = JSON.stringify(result);
    if (typeof resultJson !== "string") {
      throw new Error("YouTube analytics idempotency result is invalid.");
    }
    const resultByteLength = Buffer.byteLength(resultJson, "utf8");
    if (resultByteLength > MAX_COMPLETED_RESULT_BYTES) {
      throw new Error(
        "YouTube analytics idempotency result exceeds its storage boundary.",
      );
    }
    const path = pathFor(this.userId, namespace, key);
    await this.database.runTransaction(async (transaction) => {
      const existing = await transaction.get(path);
      if (existing === undefined) {
        throw new Error(
          "YouTube analytics idempotency reservation is missing.",
        );
      }
      assertStoredIdentity(existing, {
        userId: this.userId,
        namespace,
        keyDigest,
      });
      if (
        existing.state !== "IN_PROGRESS" ||
        existing.fingerprint !== fingerprint
      ) {
        throw new Error(
          "YouTube analytics idempotency reservation does not match.",
        );
      }
      transaction.set(path, {
        ...existing,
        state: "COMPLETED",
        resultJson,
        resultByteLength,
        updatedAt: this.now().toISOString(),
        leaseExpiresAt: null,
      });
    });
  }

  async release(
    namespaceInput: string,
    key: string,
    fingerprint: string,
  ): Promise<void> {
    const namespace = requireSafeIdentity(namespaceInput, "namespace");
    const keyDigest = digest(key);
    const path = pathFor(this.userId, namespace, key);
    await this.database.runTransaction(async (transaction) => {
      const existing = await transaction.get(path);
      if (existing === undefined) return;
      assertStoredIdentity(existing, {
        userId: this.userId,
        namespace,
        keyDigest,
      });
      if (
        existing.state === "IN_PROGRESS" &&
        existing.fingerprint === fingerprint
      ) {
        transaction.delete(path);
      }
    });
  }
}

export const analyticsReportingIdempotencyLimits = Object.freeze({
  inProgressLeaseMilliseconds: IN_PROGRESS_LEASE_MILLISECONDS,
  maximumCompletedResultBytes: MAX_COMPLETED_RESULT_BYTES,
});
