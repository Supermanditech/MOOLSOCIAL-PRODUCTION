import { createHash } from "node:crypto";

import type { Firestore } from "firebase-admin/firestore";

import {
  prepareYouTubeAuditEvent,
} from "./audit_store.js";
import type {
  OAuthAttemptRecord,
  OAuthAttemptStore,
} from "./oauth_attempt_store.js";
import type {
  YouTubeAuditEvent,
  YouTubeAuditPort,
  YouTubeConnectionStore,
  YouTubePublicationStore,
} from "./ports.js";
import type {
  YouTubeQuotaMeasurementRequest,
  YouTubeQuotaMeasurementStore,
  YouTubeQuotaReserveRequest,
  YouTubeQuotaReserveResult,
  YouTubeQuotaStore,
} from "./quota.js";
import type {
  EncryptedRefreshTokenPersistence,
  EncryptedRefreshTokenRecord,
} from "./token_vault.js";
import type {
  YouTubeProviderConnectionRecord,
  YouTubePublicationJobRecord,
} from "./types.js";

type StoredDocument = Readonly<Record<string, unknown>>;

export interface ProviderDocument {
  readonly path: string;
  readonly data: StoredDocument;
}

export interface ProviderDocumentTransaction {
  get(path: string): Promise<StoredDocument | undefined>;
  create(path: string, data: StoredDocument): void;
  set(path: string, data: StoredDocument): void;
  delete(path: string): void;
}

/**
 * Narrow server-only Firestore seam. Production uses the Admin SDK adapter
 * below; deterministic tests use an in-memory transaction implementation.
 */
export interface ProviderDocumentDatabase {
  get(path: string): Promise<StoredDocument | undefined>;
  set(path: string, data: StoredDocument): Promise<void>;
  delete(path: string): Promise<void>;
  queryByField(
    collectionPath: string,
    field: string,
    value: string,
  ): Promise<readonly ProviderDocument[]>;
  deleteMany(paths: readonly string[]): Promise<void>;
  runTransaction<T>(
    operation: (transaction: ProviderDocumentTransaction) => Promise<T>,
  ): Promise<T>;
}

const CONNECTIONS = "youtubeProviderConnections";
const CREDENTIALS = "youtubeProviderCredentials";
const OAUTH_ATTEMPTS = "youtubeProviderOAuthAttempts";
const PUBLICATIONS = "youtubeProviderPublicationJobs";
const QUOTA_USAGE = "youtubeProviderQuotaUsage";
const QUOTA_MEASUREMENTS = "youtubeProviderQuotaMeasurements";
const AUDIT_EVENTS = "youtubeProviderAuditEvents";

const PUBLICATION_MUTABLE_FIELDS = new Set<
  keyof YouTubePublicationJobRecord
>([
  "encryptedSessionUrl",
  "sessionExpiresAt",
  "state",
  "videoId",
  "failureCode",
  "updatedAt",
]);

function documentId(prefix: string, source: string): string {
  const digest = createHash("sha256")
    .update(source, "utf8")
    .digest("base64url");
  return `${prefix}_${digest}`;
}

function documentPath(
  collectionPath: string,
  prefix: string,
  key: string,
): string {
  return `${collectionPath}/${documentId(prefix, key)}`;
}

function connectionPath(connectionKey: string): string {
  return documentPath(CONNECTIONS, "ytc", connectionKey);
}

function credentialPath(connectionKey: string): string {
  return documentPath(CREDENTIALS, "ytk", connectionKey);
}

function oauthAttemptPath(stateHash: string): string {
  return documentPath(OAUTH_ATTEMPTS, "yto", stateHash);
}

function publicationPath(jobKey: string): string {
  return documentPath(PUBLICATIONS, "ytj", jobKey);
}

function quotaPath(windowId: string, bucket: string): string {
  return documentPath(QUOTA_USAGE, "ytq", `${windowId}:${bucket}`);
}

function quotaMeasurementPath(windowId: string, operation: string): string {
  return documentPath(
    QUOTA_MEASUREMENTS,
    "ytm",
    `${windowId}:${operation}`,
  );
}

function auditPath(eventKey: string): string {
  return `${AUDIT_EVENTS}/${eventKey}`;
}

function requiredString(
  data: StoredDocument,
  field: string,
): string {
  const value = data[field];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`YouTube provider record has an invalid ${field}.`);
  }
  return value;
}

function optionalString(
  data: StoredDocument,
  field: string,
): string | undefined {
  const value = data[field];
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`YouTube provider record has an invalid ${field}.`);
  }
  return value;
}

function requiredStringAllowEmpty(
  data: StoredDocument,
  field: string,
): string {
  const value = data[field];
  if (typeof value !== "string") {
    throw new Error(`YouTube provider record has an invalid ${field}.`);
  }
  return value;
}

function stringArray(
  data: StoredDocument,
  field: string,
): readonly string[] {
  const value = data[field];
  if (
    !Array.isArray(value) ||
    !value.every((item) => typeof item === "string")
  ) {
    throw new Error(`YouTube provider record has invalid ${field}.`);
  }
  return [...value];
}

function safePositiveInteger(
  data: StoredDocument,
  field: string,
): number {
  const value = data[field];
  if (!Number.isSafeInteger(value) || Number(value) < 1) {
    throw new Error(`YouTube provider record has an invalid ${field}.`);
  }
  return Number(value);
}

function connectionRecord(
  data: StoredDocument,
): YouTubeProviderConnectionRecord {
  if (data.provider !== "YOUTUBE") {
    throw new Error("YouTube connection record has an invalid provider.");
  }
  const status = requiredString(data, "status");
  if (
    status !== "ACTIVE" &&
    status !== "REVOKED" &&
    status !== "DELETION_PENDING" &&
    status !== "DELETED"
  ) {
    throw new Error("YouTube connection record has an invalid status.");
  }
  return {
    connectionKey: requiredString(data, "connectionKey"),
    userId: requiredString(data, "userId"),
    channelId: requiredString(data, "channelId"),
    channelTitle: requiredString(data, "channelTitle"),
    grantedScopes: stringArray(data, "grantedScopes"),
    connectedAt: requiredString(data, "connectedAt"),
    lastVerifiedAt: requiredString(data, "lastVerifiedAt"),
    status,
  };
}

function storedConnection(
  record: YouTubeProviderConnectionRecord,
): StoredDocument {
  return {
    provider: "YOUTUBE",
    connectionKey: record.connectionKey,
    userId: record.userId,
    channelId: record.channelId,
    channelTitle: record.channelTitle,
    grantedScopes: [...record.grantedScopes],
    connectedAt: record.connectedAt,
    lastVerifiedAt: record.lastVerifiedAt,
    status: record.status,
  };
}

function credentialRecord(
  data: StoredDocument,
): EncryptedRefreshTokenRecord {
  if (data.provider !== "YOUTUBE") {
    throw new Error("YouTube credential record has an invalid provider.");
  }
  return {
    connectionKey: requiredString(data, "connectionKey"),
    encryptedRefreshToken: requiredString(
      data,
      "encryptedRefreshToken",
    ),
    grantedScopes: stringArray(data, "grantedScopes"),
    createdAt: requiredString(data, "createdAt"),
    updatedAt: requiredString(data, "updatedAt"),
  };
}

function storedCredential(
  record: EncryptedRefreshTokenRecord,
): StoredDocument {
  return {
    provider: "YOUTUBE",
    connectionKey: record.connectionKey,
    encryptedRefreshToken: record.encryptedRefreshToken,
    grantedScopes: [...record.grantedScopes],
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
  };
}

function oauthAttemptRecord(data: StoredDocument): OAuthAttemptRecord {
  if (data.provider !== "YOUTUBE") {
    throw new Error("YouTube OAuth attempt has an invalid provider.");
  }
  return {
    stateHash: requiredString(data, "stateHash"),
    userId: requiredString(data, "userId"),
    encryptedCodeVerifier: requiredString(
      data,
      "encryptedCodeVerifier",
    ),
    requestedScopes: stringArray(data, "requestedScopes"),
    redirectUri: requiredString(data, "redirectUri"),
    createdAt: requiredString(data, "createdAt"),
    expiresAt: requiredString(data, "expiresAt"),
  };
}

function storedOAuthAttempt(record: OAuthAttemptRecord): StoredDocument {
  return {
    provider: "YOUTUBE",
    stateHash: record.stateHash,
    userId: record.userId,
    encryptedCodeVerifier: record.encryptedCodeVerifier,
    requestedScopes: [...record.requestedScopes],
    redirectUri: record.redirectUri,
    createdAt: record.createdAt,
    expiresAt: record.expiresAt,
    consumedAt: null,
  };
}

function publicationState(
  value: string,
): YouTubePublicationJobRecord["state"] {
  switch (value) {
    case "SESSION_CREATING":
    case "SESSION_READY":
    case "UPLOADING":
    case "PROCESSING":
    case "COMPLETE":
    case "FAILED":
    case "CANCELLED":
      return value;
    default:
      throw new Error("YouTube publication record has an invalid state.");
  }
}

function publicationRecord(
  data: StoredDocument,
): YouTubePublicationJobRecord {
  if (data.provider !== "YOUTUBE" || data.privacyStatus !== "private") {
    throw new Error("YouTube publication record is outside private Dev.");
  }
  const sessionExpiresAt = optionalString(data, "sessionExpiresAt");
  const videoId = optionalString(data, "videoId");
  const failureCode = optionalString(data, "failureCode");
  return {
    jobKey: requiredString(data, "jobKey"),
    userId: requiredString(data, "userId"),
    connectionKey: requiredString(data, "connectionKey"),
    idempotencyKey: requiredString(data, "idempotencyKey"),
    requestFingerprint: requiredString(data, "requestFingerprint"),
    title: requiredString(data, "title"),
    privacyStatus: "private",
    contentLength: safePositiveInteger(data, "contentLength"),
    encryptedSessionUrl: requiredStringAllowEmpty(
      data,
      "encryptedSessionUrl",
    ),
    ...(sessionExpiresAt === undefined ? {} : { sessionExpiresAt }),
    state: publicationState(requiredString(data, "state")),
    createdAt: requiredString(data, "createdAt"),
    updatedAt: requiredString(data, "updatedAt"),
    ...(videoId === undefined ? {} : { videoId }),
    ...(failureCode === undefined ? {} : { failureCode }),
  };
}

function storedPublication(
  record: YouTubePublicationJobRecord,
): StoredDocument {
  return {
    provider: "YOUTUBE",
    jobKey: record.jobKey,
    userId: record.userId,
    connectionKey: record.connectionKey,
    idempotencyKey: record.idempotencyKey,
    requestFingerprint: record.requestFingerprint,
    title: record.title,
    privacyStatus: record.privacyStatus,
    contentLength: record.contentLength,
    encryptedSessionUrl: record.encryptedSessionUrl,
    ...(record.sessionExpiresAt === undefined
      ? {}
      : { sessionExpiresAt: record.sessionExpiresAt }),
    state: record.state,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
    ...(record.videoId === undefined ? {} : { videoId: record.videoId }),
    ...(record.failureCode === undefined
      ? {}
      : { failureCode: record.failureCode }),
  };
}

function validDate(value: string): boolean {
  return Number.isFinite(Date.parse(value));
}

function assertQuotaRequest(request: YouTubeQuotaReserveRequest): void {
  if (
    !Number.isSafeInteger(request.units) ||
    request.units < 1 ||
    !Number.isSafeInteger(request.limit) ||
    request.limit < 0 ||
    !validDate(request.resetAt)
  ) {
    throw new Error("YouTube quota reservation is invalid.");
  }
}

function quotaMeasurementCounter(
  data: StoredDocument,
  field: string,
): number {
  const value = data[field];
  if (!Number.isSafeInteger(value) || Number(value) < 0) {
    throw new Error(`${field} is invalid.`);
  }
  return Number(value);
}

function assertQuotaMeasurementRequest(
  request: YouTubeQuotaMeasurementRequest,
): void {
  const validText = (value: string, maximum: number) =>
    value.length > 0 &&
    value.length <= maximum &&
    value === value.trim() &&
    !/[\u0000-\u001f\u007f]/u.test(value);
  if (
    !validText(request.principal, 128) ||
    !validText(request.operation, 128) ||
    !/^[A-Za-z0-9._-]{1,128}$/u.test(request.requestId) ||
    !/^\d{4}-\d{2}-\d{2}$/u.test(request.windowId) ||
    !Number.isSafeInteger(request.units) ||
    request.units < 1 ||
    typeof request.accepted !== "boolean" ||
    typeof request.local !== "boolean" ||
    !validDate(request.occurredAt)
  ) {
    throw new Error("YouTube quota measurement is invalid.");
  }
}

function chunks<T>(
  values: readonly T[],
  size: number,
): readonly (readonly T[])[] {
  const output: T[][] = [];
  for (let index = 0; index < values.length; index += size) {
    output.push(values.slice(index, index + size));
  }
  return output;
}

export class AdminFirestoreProviderDatabase
  implements ProviderDocumentDatabase
{
  constructor(private readonly firestore: Firestore) {}

  async get(path: string): Promise<StoredDocument | undefined> {
    const snapshot = await this.firestore.doc(path).get();
    return snapshot.exists
      ? (snapshot.data() as StoredDocument | undefined)
      : undefined;
  }

  async set(path: string, data: StoredDocument): Promise<void> {
    await this.firestore.doc(path).set(data);
  }

  async delete(path: string): Promise<void> {
    await this.firestore.doc(path).delete();
  }

  async queryByField(
    collectionPath: string,
    field: string,
    value: string,
  ): Promise<readonly ProviderDocument[]> {
    const snapshot = await this.firestore
      .collection(collectionPath)
      .where(field, "==", value)
      .get();
    return snapshot.docs.map((document) => ({
      path: document.ref.path,
      data: document.data(),
    }));
  }

  async deleteMany(paths: readonly string[]): Promise<void> {
    for (const group of chunks(paths, 400)) {
      const batch = this.firestore.batch();
      for (const path of group) {
        batch.delete(this.firestore.doc(path));
      }
      await batch.commit();
    }
  }

  async runTransaction<T>(
    operation: (transaction: ProviderDocumentTransaction) => Promise<T>,
  ): Promise<T> {
    return this.firestore.runTransaction(async (transaction) => {
      const adapter: ProviderDocumentTransaction = {
        get: async (path) => {
          const snapshot = await transaction.get(this.firestore.doc(path));
          return snapshot.exists
            ? (snapshot.data() as StoredDocument | undefined)
            : undefined;
        },
        create: (path, data) => {
          transaction.create(this.firestore.doc(path), data);
        },
        set: (path, data) => {
          transaction.set(this.firestore.doc(path), data);
        },
        delete: (path) => {
          transaction.delete(this.firestore.doc(path));
        },
      };
      return operation(adapter);
    });
  }
}

export class FirestoreYouTubeConnectionStore
  implements YouTubeConnectionStore
{
  constructor(private readonly database: ProviderDocumentDatabase) {}

  async getByUser(
    userId: string,
  ): Promise<YouTubeProviderConnectionRecord | null> {
    const documents = await this.database.queryByField(
      CONNECTIONS,
      "userId",
      userId,
    );
    const active = documents
      .map((document) => connectionRecord(document.data))
      .filter((record) => record.status === "ACTIVE");
    if (active.length > 1) {
      throw new Error("More than one active YouTube connection exists.");
    }
    return active[0] ?? null;
  }

  async save(record: YouTubeProviderConnectionRecord): Promise<void> {
    await this.database.set(
      connectionPath(record.connectionKey),
      storedConnection(record),
    );
  }

  async markRevoked(
    connectionKey: string,
    revokedAt: string,
  ): Promise<void> {
    if (!validDate(revokedAt)) {
      throw new Error("YouTube revocation time is invalid.");
    }
    await this.database.runTransaction(async (transaction) => {
      const path = connectionPath(connectionKey);
      const existing = await transaction.get(path);
      if (existing === undefined) return;
      const record = connectionRecord(existing);
      if (record.connectionKey !== connectionKey) {
        throw new Error("YouTube connection key does not match its record.");
      }
      transaction.set(path, {
        ...storedConnection({ ...record, status: "REVOKED" }),
        revokedAt,
        deletionDueAt: new Date(
          Date.parse(revokedAt) + 7 * 24 * 60 * 60 * 1000,
        ).toISOString(),
      });
    });
  }

  async delete(connectionKey: string): Promise<void> {
    await this.database.delete(connectionPath(connectionKey));
  }
}

export class FirestoreRefreshTokenPersistence
  implements EncryptedRefreshTokenPersistence
{
  constructor(private readonly database: ProviderDocumentDatabase) {}

  async get(
    connectionKey: string,
  ): Promise<EncryptedRefreshTokenRecord | undefined> {
    const data = await this.database.get(credentialPath(connectionKey));
    if (data === undefined) return undefined;
    const record = credentialRecord(data);
    if (record.connectionKey !== connectionKey) {
      throw new Error("YouTube credential key does not match its record.");
    }
    return record;
  }

  async put(record: EncryptedRefreshTokenRecord): Promise<void> {
    await this.database.set(
      credentialPath(record.connectionKey),
      storedCredential(record),
    );
  }

  async replaceIfCurrent(
    expectedEncryptedRefreshToken: string,
    replacement: EncryptedRefreshTokenRecord,
  ): Promise<boolean> {
    return this.database.runTransaction(async (transaction) => {
      const path = credentialPath(replacement.connectionKey);
      const existing = await transaction.get(path);
      if (existing === undefined) return false;
      const current = credentialRecord(existing);
      if (
        current.connectionKey !== replacement.connectionKey ||
        current.encryptedRefreshToken !== expectedEncryptedRefreshToken
      ) {
        return false;
      }
      transaction.set(path, storedCredential(replacement));
      return true;
    });
  }

  async delete(connectionKey: string): Promise<void> {
    await this.database.delete(credentialPath(connectionKey));
  }
}

export class FirestoreOAuthAttemptStore implements OAuthAttemptStore {
  constructor(
    private readonly database: ProviderDocumentDatabase,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async save(record: OAuthAttemptRecord): Promise<void> {
    await this.database.runTransaction(async (transaction) => {
      const path = oauthAttemptPath(record.stateHash);
      if ((await transaction.get(path)) !== undefined) {
        throw new Error("YouTube OAuth state already exists.");
      }
      transaction.create(path, storedOAuthAttempt(record));
    });
  }

  async consume(
    stateHash: string,
    userId: string,
  ): Promise<OAuthAttemptRecord | null> {
    return this.consumeInternal(stateHash, userId);
  }

  async consumeByState(
    stateHash: string,
  ): Promise<OAuthAttemptRecord | null> {
    return this.consumeInternal(stateHash);
  }

  async deleteByUser(userId: string): Promise<void> {
    const documents = await this.database.queryByField(
      OAUTH_ATTEMPTS,
      "userId",
      userId,
    );
    await this.database.deleteMany(
      documents.map((document) => document.path),
    );
  }

  private async consumeInternal(
    stateHash: string,
    expectedUserId?: string,
  ): Promise<OAuthAttemptRecord | null> {
    return this.database.runTransaction(async (transaction) => {
      const path = oauthAttemptPath(stateHash);
      const existing = await transaction.get(path);
      if (existing === undefined) return null;
      const attempt = oauthAttemptRecord(existing);
      if (
        attempt.stateHash !== stateHash ||
        (expectedUserId !== undefined && attempt.userId !== expectedUserId) ||
        existing.consumedAt !== null ||
        !validDate(attempt.expiresAt) ||
        Date.parse(attempt.expiresAt) <= this.now().getTime()
      ) {
        return null;
      }
      transaction.set(path, {
        ...existing,
        consumedAt: this.now().toISOString(),
      });
      return attempt;
    });
  }
}

export class FirestoreYouTubePublicationStore
  implements YouTubePublicationStore
{
  constructor(private readonly database: ProviderDocumentDatabase) {}

  async reserve(
    record: YouTubePublicationJobRecord,
  ): Promise<{
    readonly created: boolean;
    readonly record: YouTubePublicationJobRecord;
  }> {
    if (
      record.state !== "SESSION_CREATING" ||
      record.encryptedSessionUrl !== "" ||
      record.privacyStatus !== "private"
    ) {
      throw new Error("A publication reservation must not contain a session.");
    }
    return this.database.runTransaction(async (transaction) => {
      const connectionData = await transaction.get(
        connectionPath(record.connectionKey),
      );
      const jobPath = publicationPath(record.jobKey);
      const jobData = await transaction.get(jobPath);
      if (connectionData === undefined) {
        throw new Error("The YouTube connection is not active.");
      }
      const connection = connectionRecord(connectionData);
      if (
        connection.status !== "ACTIVE" ||
        connection.connectionKey !== record.connectionKey ||
        connection.userId !== record.userId
      ) {
        throw new Error("The YouTube connection is not active.");
      }
      if (jobData !== undefined) {
        const existing = publicationRecord(jobData);
        if (
          existing.userId !== record.userId ||
          existing.idempotencyKey !== record.idempotencyKey
        ) {
          throw new Error("Publication reservation could not be resolved.");
        }
        return { created: false, record: existing };
      }
      transaction.create(jobPath, storedPublication(record));
      return { created: true, record };
    });
  }

  async getByKey(
    userId: string,
    jobKey: string,
  ): Promise<YouTubePublicationJobRecord | null> {
    const data = await this.database.get(publicationPath(jobKey));
    if (data === undefined) return null;
    const record = publicationRecord(data);
    return record.userId === userId && record.jobKey === jobKey
      ? record
      : null;
  }

  async getByIdempotencyKey(
    userId: string,
    idempotencyKey: string,
  ): Promise<YouTubePublicationJobRecord | null> {
    const documents = await this.database.queryByField(
      PUBLICATIONS,
      "userId",
      userId,
    );
    const matches = documents
      .map((document) => publicationRecord(document.data))
      .filter((record) => record.idempotencyKey === idempotencyKey);
    if (matches.length > 1) {
      throw new Error("Duplicate YouTube upload idempotency records exist.");
    }
    return matches[0] ?? null;
  }

  async update(
    userId: string,
    jobKey: string,
    patch: Partial<YouTubePublicationJobRecord>,
  ): Promise<void> {
    const unsupported = Object.keys(patch).filter(
      (key) =>
        !PUBLICATION_MUTABLE_FIELDS.has(
          key as keyof YouTubePublicationJobRecord,
        ),
    );
    if (unsupported.length > 0) {
      throw new Error(
        `Publication update contains immutable fields: ${unsupported.join(", ")}.`,
      );
    }
    await this.database.runTransaction(async (transaction) => {
      const path = publicationPath(jobKey);
      const jobData = await transaction.get(path);
      if (jobData === undefined) {
        throw new Error(
          "Publication job does not exist or its YouTube connection is not active.",
        );
      }
      const current = publicationRecord(jobData);
      const connectionData = await transaction.get(
        connectionPath(current.connectionKey),
      );
      if (
        current.userId !== userId ||
        current.jobKey !== jobKey ||
        connectionData === undefined
      ) {
        throw new Error(
          "Publication job does not exist or its YouTube connection is not active.",
        );
      }
      const connection = connectionRecord(connectionData);
      if (
        connection.status !== "ACTIVE" ||
        connection.userId !== current.userId ||
        connection.connectionKey !== current.connectionKey
      ) {
        throw new Error(
          "Publication job does not exist or its YouTube connection is not active.",
        );
      }
      const next: YouTubePublicationJobRecord = {
        ...current,
        ...patch,
      };
      transaction.set(path, storedPublication(next));
    });
  }

  async deleteByUser(userId: string): Promise<void> {
    const documents = await this.database.queryByField(
      PUBLICATIONS,
      "userId",
      userId,
    );
    await this.database.deleteMany(
      documents.map((document) => document.path),
    );
  }
}

export class FirestoreYouTubeQuotaStore
  implements YouTubeQuotaStore, YouTubeQuotaMeasurementStore
{
  constructor(private readonly database: ProviderDocumentDatabase) {}

  async reserve(
    request: YouTubeQuotaReserveRequest,
  ): Promise<YouTubeQuotaReserveResult> {
    assertQuotaRequest(request);
    return this.database.runTransaction(async (transaction) => {
      const path = quotaPath(request.windowId, request.bucket);
      const existing = await transaction.get(path);
      let current = 0;
      if (existing !== undefined) {
        if (
          existing.provider !== "YOUTUBE" ||
          existing.windowId !== request.windowId ||
          existing.bucket !== request.bucket ||
          !Number.isSafeInteger(existing.used) ||
          Number(existing.used) < 0
        ) {
          throw new Error("YouTube quota record is invalid.");
        }
        current = Number(existing.used);
      }
      const allowed = current + request.units <= request.limit;
      const used = allowed ? current + request.units : current;
      if (allowed) {
        transaction.set(path, {
          provider: "YOUTUBE",
          bucket: request.bucket,
          windowId: request.windowId,
          used,
          hardCap: request.limit,
          resetAt: request.resetAt,
          updatedAt: new Date().toISOString(),
        });
      }
      return {
        allowed,
        bucket: request.bucket,
        windowId: request.windowId,
        resetAt: request.resetAt,
        used,
        remaining: Math.max(0, request.limit - used),
        limit: request.limit,
      };
    });
  }

  async recordMeasurement(
    request: YouTubeQuotaMeasurementRequest,
  ): Promise<void> {
    assertQuotaMeasurementRequest(request);
    await this.database.runTransaction(async (transaction) => {
      const path = quotaMeasurementPath(
        request.windowId,
        request.operation,
      );
      const existing = await transaction.get(path);
      let acceptedReservations = 0;
      let rejectedReservations = 0;
      let acceptedLocalReservations = 0;
      if (existing !== undefined) {
        if (
          existing.provider !== "YOUTUBE" ||
          existing.operation !== request.operation ||
          existing.bucket !== request.bucket ||
          existing.windowId !== request.windowId
        ) {
          throw new Error("YouTube quota measurement identity is invalid.");
        }
        acceptedReservations = quotaMeasurementCounter(
          existing,
          "acceptedReservations",
        );
        rejectedReservations = quotaMeasurementCounter(
          existing,
          "rejectedReservations",
        );
        acceptedLocalReservations = quotaMeasurementCounter(
          existing,
          "acceptedLocalReservations",
        );
        if (acceptedLocalReservations > acceptedReservations) {
          throw new Error("acceptedLocalReservations is invalid.");
        }
      }
      if (request.accepted) {
        acceptedReservations += 1;
        if (request.local) acceptedLocalReservations += 1;
      } else {
        rejectedReservations += 1;
      }
      transaction.set(path, {
        provider: "YOUTUBE",
        operation: request.operation,
        bucket: request.bucket,
        windowId: request.windowId,
        acceptedReservations,
        rejectedReservations,
        acceptedLocalReservations,
        updatedAt: request.occurredAt,
      });
    });
  }
}

export class FirestoreYouTubeAuditStore implements YouTubeAuditPort {
  constructor(private readonly database: ProviderDocumentDatabase) {}

  async record(event: YouTubeAuditEvent): Promise<void> {
    const prepared = prepareYouTubeAuditEvent(event);
    await this.database.runTransaction(async (transaction) => {
      const path = auditPath(prepared.eventKey);
      if ((await transaction.get(path)) !== undefined) return;
      transaction.create(path, {
        provider: "YOUTUBE",
        eventKey: prepared.eventKey,
        ...(prepared.userId === undefined
          ? {}
          : { userId: prepared.userId }),
        eventType: prepared.eventType,
        requestId: prepared.requestId,
        redactedDetailJson: prepared.redactedDetailJson,
        occurredAt: prepared.occurredAt,
      });
    });
  }
}

export interface FirestoreYouTubeStores {
  readonly database: AdminFirestoreProviderDatabase;
  readonly connections: FirestoreYouTubeConnectionStore;
  readonly refreshTokens: FirestoreRefreshTokenPersistence;
  readonly oauthAttempts: FirestoreOAuthAttemptStore;
  readonly publications: FirestoreYouTubePublicationStore;
  readonly quota: FirestoreYouTubeQuotaStore;
  readonly audit: FirestoreYouTubeAuditStore;
}

export function createFirestoreYouTubeStores(
  firestore: Firestore,
): FirestoreYouTubeStores {
  const database = new AdminFirestoreProviderDatabase(firestore);
  return {
    database,
    connections: new FirestoreYouTubeConnectionStore(database),
    refreshTokens: new FirestoreRefreshTokenPersistence(database),
    oauthAttempts: new FirestoreOAuthAttemptStore(database),
    publications: new FirestoreYouTubePublicationStore(database),
    quota: new FirestoreYouTubeQuotaStore(database),
    audit: new FirestoreYouTubeAuditStore(database),
  };
}
