import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import test from "node:test";

import { ProcessYouTubeCache } from "./adapters.js";
import { YouTubeDataClient } from "./client.js";
import { YouTubeProviderError } from "./errors.js";
import type {
  OAuthAttemptRecord,
  OAuthAttemptStore,
} from "./oauth_attempt_store.js";
import { YouTubeOwnerClient } from "./owner_client.js";
import type {
  YouTubeConnectionStore,
  YouTubePublicationStore,
  YouTubeQuotaPort,
} from "./ports.js";
import { YouTubeProviderService } from "./provider_service.js";
import {
  Aes256GcmEnvelopeCipher,
  InMemoryAccessTokenCache,
  RefreshTokenVault,
  type EncryptedRefreshTokenPersistence,
  type EncryptedRefreshTokenRecord,
} from "./token_vault.js";
import {
  YOUTUBE_ANALYTICS_READONLY_SCOPE,
  YOUTUBE_READONLY_SCOPE,
  YOUTUBE_UPLOAD_SCOPE,
} from "./oauth.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
  YouTubeProviderConnectionRecord,
  YouTubePublicationJobRecord,
} from "./types.js";

class RouteTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    if (request.url === "https://oauth2.googleapis.com/token") {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          access_token: "short-lived-access",
          expires_in: 3600,
          token_type: "Bearer",
          scope: `${YOUTUBE_READONLY_SCOPE} ${YOUTUBE_UPLOAD_SCOPE}`,
        }),
      };
    }
    if (
      request.url.startsWith(
        "https://www.googleapis.com/upload/youtube/v3/videos?",
      )
    ) {
      return {
        status: 200,
        headers: {
          location:
            "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=secret-session",
        },
        body: "",
      };
    }
    throw new Error(`Unexpected request: ${request.url}`);
  }
}

class OwnershipTransport implements HttpTransport {
  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    if (request.url === "https://oauth2.googleapis.com/token") {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          access_token: "short-lived-access",
          expires_in: 3600,
          token_type: "Bearer",
          scope: YOUTUBE_READONLY_SCOPE,
        }),
      };
    }
    if (
      request.method === "PUT" &&
      request.url.startsWith(
        "https://www.googleapis.com/upload/youtube/v3/videos?",
      )
    ) {
      return {
        status: 201,
        headers: {},
        body: JSON.stringify({ id: "video123" }),
      };
    }
    if (request.url.startsWith("https://www.googleapis.com/youtube/v3/videos?")) {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          items: [
            {
              id: "video123",
              snippet: {
                title: "Another channel video",
                description: "",
                channelId: "UC_OTHER",
                channelTitle: "Another channel",
                publishedAt: "2026-07-23T00:00:00Z",
                thumbnails: {
                  high: {
                    url: "https://i.ytimg.com/vi/video123/hqdefault.jpg",
                  },
                },
              },
              contentDetails: { duration: "PT1M" },
              status: {
                privacyStatus: "private",
                uploadStatus: "processed",
              },
            },
          ],
        }),
      };
    }
    throw new Error(`Unexpected request: ${request.url}`);
  }
}

class ConnectTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(
    private readonly tokenScopes: string = YOUTUBE_READONLY_SCOPE,
  ) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    if (request.url === "https://oauth2.googleapis.com/token") {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          access_token: "callback-access",
          refresh_token: "callback-refresh",
          expires_in: 3600,
          token_type: "Bearer",
          scope: this.tokenScopes,
        }),
      };
    }
    if (
      request.url.startsWith(
        "https://www.googleapis.com/youtube/v3/channels?",
      )
    ) {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          items: [
            {
              id: "UC_CALLBACK",
              snippet: {
                title: "Connected creator",
                thumbnails: {},
              },
              contentDetails: {
                relatedPlaylists: { uploads: "UU_CALLBACK" },
              },
            },
          ],
        }),
      };
    }
    throw new Error(`Unexpected request: ${request.url}`);
  }
}

class IncrementalReconnectTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    if (request.url === "https://oauth2.googleapis.com/token") {
      const grantType = new URLSearchParams(request.body).get("grant_type");
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          access_token:
            grantType === "refresh_token"
              ? "cold-start-access"
              : "incremental-callback-access",
          expires_in: 3600,
          token_type: "Bearer",
        }),
      };
    }
    if (
      request.url.startsWith(
        "https://www.googleapis.com/youtube/v3/channels?",
      )
    ) {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          items: [
            {
              id: "UC_CALLBACK",
              snippet: {
                title: "Connected creator",
                thumbnails: {},
              },
              contentDetails: {
                relatedPlaylists: { uploads: "UU_CALLBACK" },
              },
            },
          ],
        }),
      };
    }
    if (
      request.url.startsWith(
        "https://youtubeanalytics.googleapis.com/v2/reports?",
      )
    ) {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          columnHeaders: [
            { name: "day", columnType: "DIMENSION", dataType: "STRING" },
            { name: "views", columnType: "METRIC", dataType: "INTEGER" },
          ],
          rows: [["2026-07-23", 12]],
        }),
      };
    }
    throw new Error(`Unexpected request: ${request.url}`);
  }
}

class ProgressiveUploadTransport implements HttpTransport {
  uploadStatusChecks = 0;
  videoReads = 0;

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    if (request.url === "https://oauth2.googleapis.com/token") {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          access_token: "short-lived-access",
          expires_in: 3600,
          token_type: "Bearer",
          scope: YOUTUBE_READONLY_SCOPE,
        }),
      };
    }
    if (
      request.method === "PUT" &&
      request.url.startsWith(
        "https://www.googleapis.com/upload/youtube/v3/videos?",
      )
    ) {
      this.uploadStatusChecks += 1;
      return {
        status: 201,
        headers: {},
        body: JSON.stringify({ id: "video123" }),
      };
    }
    if (request.url.startsWith("https://www.googleapis.com/youtube/v3/videos?")) {
      this.videoReads += 1;
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          items: [
            {
              id: "video123",
              snippet: {
                title: "Private upload",
                description: "",
                channelId: "UC1234",
                channelTitle: "Creator",
                publishedAt: "2026-07-23T00:00:00Z",
                thumbnails: {
                  high: {
                    url: "https://i.ytimg.com/vi/video123/hqdefault.jpg",
                  },
                },
              },
              contentDetails: { duration: "PT1M" },
              status: {
                privacyStatus: "private",
                uploadStatus:
                  this.videoReads === 1 ? "uploaded" : "processed",
              },
            },
          ],
        }),
      };
    }
    throw new Error(`Unexpected request: ${request.url}`);
  }
}

class MemoryCredentialStore implements EncryptedRefreshTokenPersistence {
  private readonly records = new Map<string, EncryptedRefreshTokenRecord>();

  async get(
    connectionKey: string,
  ): Promise<EncryptedRefreshTokenRecord | undefined> {
    return this.records.get(connectionKey);
  }

  async put(record: EncryptedRefreshTokenRecord): Promise<void> {
    this.records.set(record.connectionKey, record);
  }

  async delete(connectionKey: string): Promise<void> {
    this.records.delete(connectionKey);
  }
}

class MemoryConnectionStore implements YouTubeConnectionStore {
  constructor(private record: YouTubeProviderConnectionRecord | null) {}

  async getByUser(
    userId: string,
  ): Promise<YouTubeProviderConnectionRecord | null> {
    return this.record?.userId === userId ? this.record : null;
  }

  async save(record: YouTubeProviderConnectionRecord): Promise<void> {
    this.record = record;
  }

  async markRevoked(): Promise<void> {
    if (this.record) this.record = { ...this.record, status: "REVOKED" };
  }

  async delete(): Promise<void> {
    this.record = null;
  }
}

class FailingSaveConnectionStore extends MemoryConnectionStore {
  override async save(
    _record: YouTubeProviderConnectionRecord,
  ): Promise<void> {
    throw new Error("connection write failed");
  }
}

class MemoryPublicationStore implements YouTubePublicationStore {
  readonly records = new Map<string, YouTubePublicationJobRecord>();

  async reserve(
    record: YouTubePublicationJobRecord,
  ): Promise<{
    readonly created: boolean;
    readonly record: YouTubePublicationJobRecord;
  }> {
    const existing = this.records.get(record.jobKey);
    if (existing) return { created: false, record: existing };
    this.records.set(record.jobKey, record);
    return { created: true, record };
  }

  async getByKey(
    userId: string,
    jobKey: string,
  ): Promise<YouTubePublicationJobRecord | null> {
    const record = this.records.get(jobKey);
    return record?.userId === userId ? record : null;
  }

  async getByIdempotencyKey(
    userId: string,
    idempotencyKey: string,
  ): Promise<YouTubePublicationJobRecord | null> {
    return (
      [...this.records.values()].find(
        (record) =>
          record.userId === userId &&
          record.idempotencyKey === idempotencyKey,
      ) ?? null
    );
  }

  async update(
    userId: string,
    jobKey: string,
    patch: Partial<YouTubePublicationJobRecord>,
  ): Promise<void> {
    const current = this.records.get(jobKey);
    if (!current || current.userId !== userId) throw new Error("Missing job.");
    this.records.set(jobKey, { ...current, ...patch });
  }

  async deleteByUser(userId: string): Promise<void> {
    for (const [jobKey, record] of this.records) {
      if (record.userId === userId) this.records.delete(jobKey);
    }
  }
}

function callbackConnectionKey(userId: string): string {
  return `ytc_${createHash("sha256").update(userId, "utf8").digest("base64url")}`;
}

function failedConnectionSaveHarness(
  existingConnection: YouTubeProviderConnectionRecord | null,
): {
  readonly state: string;
  readonly service: YouTubeProviderService;
  readonly refreshTokens: RefreshTokenVault;
} {
  const now = new Date("2026-07-23T00:00:00Z");
  const state = "private-dev-state-with-failing-connection-write";
  const stateHash = createHash("sha256")
    .update(state, "utf8")
    .digest("base64url");
  const verifierCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 2),
    "k1",
    "youtube-oauth-verifier",
  );
  let consumed = false;
  const attempts: OAuthAttemptStore = {
    save: async () => undefined,
    consume: async () => null,
    consumeByState: async (candidate) => {
      if (consumed || candidate !== stateHash) return null;
      consumed = true;
      return {
        stateHash,
        userId: "user-1",
        encryptedCodeVerifier: verifierCipher.encrypt(
          "A".repeat(64),
          `oauth:${stateHash}`,
        ),
        requestedScopes: [YOUTUBE_READONLY_SCOPE],
        redirectUri:
          "https://dev.moolsocial.com/google-callback/youtube",
        createdAt: now.toISOString(),
        expiresAt: new Date(now.getTime() + 600_000).toISOString(),
      };
    },
    deleteByUser: async () => undefined,
  };
  const transport = new ConnectTransport();
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const refreshTokens = new RefreshTokenVault(
    new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 1),
      "k1",
      "youtube-refresh-token",
    ),
    new MemoryCredentialStore(),
    () => now,
  );
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: true,
      ownerConnect: true,
      privateUpload: true,
      ownerAnalytics: true,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections: new FailingSaveConnectionStore(existingConnection),
    publications: new MemoryPublicationStore(),
    oauthAttempts: attempts,
    refreshTokens,
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: verifierCipher,
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });
  return { state, service, refreshTokens };
}

const PRIVATE_UPLOAD_REQUEST = {
  userId: "user-1",
  requestId: "request-1",
  idempotencyKey: "upload-1",
  contentType: "video/mp4",
  contentLength: 2048,
  fileIdentity: {
    algorithm: "sha256",
    digest: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    byteLength: 2048,
    contentType: "video/mp4",
  },
  metadata: {
    title: "Jodhpur market",
    description: "Morning market update",
    categoryId: "22",
    madeForKids: false,
    containsSyntheticMedia: false,
    containsPaidPromotion: true,
    notifySubscribers: false,
  },
} as const;

async function privateUploadFixture(
  initialNow = new Date("2026-07-23T00:00:00Z"),
): Promise<{
  readonly service: YouTubeProviderService;
  readonly publications: MemoryPublicationStore;
  readonly transport: RouteTransport;
  readonly setNow: (value: Date) => void;
}> {
  let now = initialNow;
  const transport = new RouteTransport();
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const connection: YouTubeProviderConnectionRecord = {
    connectionKey: "ytc_connection",
    userId: "user-1",
    channelId: "UC1234",
    channelTitle: "Creator",
    grantedScopes: [YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE],
    connectedAt: now.toISOString(),
    lastVerifiedAt: now.toISOString(),
    status: "ACTIVE",
  };
  const publications = new MemoryPublicationStore();
  const refreshTokens = new RefreshTokenVault(
    new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 1),
      "k1",
      "youtube-refresh-token",
    ),
    new MemoryCredentialStore(),
    () => now,
  );
  await refreshTokens.save(
    connection.connectionKey,
    "refresh-token",
    connection.grantedScopes,
  );
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: true,
      ownerConnect: true,
      privateUpload: true,
      ownerAnalytics: true,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({
      transport,
      quota,
      clock: { now: () => now },
    }),
    transport,
    connections: new MemoryConnectionStore(connection),
    publications,
    oauthAttempts: {
      save: async () => undefined,
      consume: async () => null,
      consumeByState: async () => null,
      deleteByUser: async () => undefined,
    },
    refreshTokens,
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 2),
      "k1",
      "youtube-oauth-verifier",
    ),
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });
  return {
    service,
    publications,
    transport,
    setNow: (value: Date) => {
      now = value;
    },
  };
}

test("private upload is idempotent, encrypted at rest and never proxied", async () => {
  const now = new Date("2026-07-23T00:00:00Z");
  const transport = new RouteTransport();
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const connection: YouTubeProviderConnectionRecord = {
    connectionKey: "ytc_connection",
    userId: "user-1",
    channelId: "UC1234",
    channelTitle: "Creator",
    grantedScopes: [YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE],
    connectedAt: now.toISOString(),
    lastVerifiedAt: now.toISOString(),
    status: "ACTIVE",
  };
  const publications = new MemoryPublicationStore();
  const refreshCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 1),
    "k1",
    "youtube-refresh-token",
  );
  const refreshTokens = new RefreshTokenVault(
    refreshCipher,
    new MemoryCredentialStore(),
    () => now,
  );
  await refreshTokens.save(
    connection.connectionKey,
    "refresh-token",
    connection.grantedScopes,
  );
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: true,
      ownerConnect: true,
      privateUpload: true,
      ownerAnalytics: true,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({
      transport,
      quota,
      clock: { now: () => now },
    }),
    transport,
    connections: new MemoryConnectionStore(connection),
    publications,
    oauthAttempts: {
      save: async () => undefined,
      consume: async () => null,
      consumeByState: async () => null,
      deleteByUser: async () => undefined,
    } satisfies OAuthAttemptStore,
    refreshTokens,
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 2),
      "k1",
      "youtube-oauth-verifier",
    ),
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri: "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });
  const request = {
    userId: "user-1",
    requestId: "request-1",
    idempotencyKey: "upload-1",
    contentType: "video/mp4",
    contentLength: 2048,
    fileIdentity: {
      algorithm: "sha256",
      digest: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      byteLength: 2048,
      contentType: "video/mp4",
    },
    metadata: {
      title: "Jodhpur market",
      description: "",
      categoryId: "22",
      madeForKids: false,
      containsSyntheticMedia: false,
      containsPaidPromotion: true,
      notifySubscribers: false,
    },
  } as const;

  const first = await service.beginPrivateUpload(request);
  const second = await service.beginPrivateUpload(request);

  assert.equal(first.sessionUrl, second.sessionUrl);
  assert.equal(first.privacyStatus, "private");
  assert.equal(transport.requests.length, 2);
  assert.equal(
    transport.requests.some((item) => item.body?.includes("video") === true),
    false,
    "Only metadata is sent by Functions; media bytes are never proxied.",
  );
  const persisted = publications.records.get(first.jobKey);
  assert.ok(persisted);
  assert.equal(persisted.privacyStatus, "private");
  assert.match(persisted.requestFingerprint, /^sha256:[A-Za-z0-9_-]{43}$/);
  assert.equal(persisted.sessionExpiresAt, first.expiresAt);
  assert.equal(persisted.encryptedSessionUrl.includes("upload_id"), false);
  assert.equal(persisted.encryptedSessionUrl.startsWith("mstv1."), true);
});

test("an idempotency key is bound to every upload input", async () => {
  const { service, publications, transport } =
    await privateUploadFixture();
  const first = await service.beginPrivateUpload(PRIVATE_UPLOAD_REQUEST);
  const mutations = [
    {
      ...PRIVATE_UPLOAD_REQUEST,
      contentType: "video/webm",
      fileIdentity: {
        ...PRIVATE_UPLOAD_REQUEST.fileIdentity,
        contentType: "video/webm",
      },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      contentLength: 4096,
      fileIdentity: {
        ...PRIVATE_UPLOAD_REQUEST.fileIdentity,
        byteLength: 4096,
      },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      fileIdentity: {
        ...PRIVATE_UPLOAD_REQUEST.fileIdentity,
        digest: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
      },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      metadata: { ...PRIVATE_UPLOAD_REQUEST.metadata, title: "New title" },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      metadata: {
        ...PRIVATE_UPLOAD_REQUEST.metadata,
        description: "Different description",
      },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      metadata: { ...PRIVATE_UPLOAD_REQUEST.metadata, categoryId: "24" },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      metadata: { ...PRIVATE_UPLOAD_REQUEST.metadata, madeForKids: true },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      metadata: {
        ...PRIVATE_UPLOAD_REQUEST.metadata,
        containsSyntheticMedia: true,
      },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      metadata: {
        ...PRIVATE_UPLOAD_REQUEST.metadata,
        containsPaidPromotion: false,
      },
    },
    {
      ...PRIVATE_UPLOAD_REQUEST,
      metadata: {
        ...PRIVATE_UPLOAD_REQUEST.metadata,
        notifySubscribers: true,
      },
    },
  ] as const;

  for (const changed of mutations) {
    await assert.rejects(
      service.beginPrivateUpload(changed),
      (error: unknown) => {
        assert.ok(error instanceof YouTubeProviderError);
        assert.equal(error.code, "conflict");
        assert.equal(error.retryable, false);
        return true;
      },
    );
  }

  assert.equal(
    transport.requests.length,
    2,
    "Changed retries must not create or refresh a provider upload session.",
  );
  assert.match(
    publications.records.get(first.jobKey)?.requestFingerprint ?? "",
    /^sha256:[A-Za-z0-9_-]{43}$/,
  );
});

test("an abandoned session-creation lease becomes terminal", async () => {
  const startedAt = new Date("2026-07-23T00:00:00Z");
  const { service, publications, setNow } =
    await privateUploadFixture(startedAt);
  const request = {
    ...PRIVATE_UPLOAD_REQUEST,
    idempotencyKey: "stale-creation",
  };
  const started = await service.beginPrivateUpload(request);
  await publications.update("user-1", started.jobKey, {
    encryptedSessionUrl: "",
    state: "SESSION_CREATING",
    updatedAt: startedAt.toISOString(),
  });
  setNow(new Date(startedAt.getTime() + 2 * 60 * 1000));

  await assert.rejects(
    service.beginPrivateUpload(request),
    (error: unknown) => {
      assert.ok(error instanceof YouTubeProviderError);
      assert.equal(error.code, "conflict");
      assert.equal(error.retryable, false);
      return true;
    },
  );

  const failed = publications.records.get(started.jobKey);
  assert.equal(failed?.state, "FAILED");
  assert.equal(
    failed?.failureCode,
    "upload_session_creation_expired",
  );
  assert.equal(failed?.encryptedSessionUrl, "");
});

test("an expired ready session becomes terminal before reconciliation", async () => {
  const startedAt = new Date("2026-07-23T00:00:00Z");
  const { service, publications, setNow } =
    await privateUploadFixture(startedAt);
  const request = {
    ...PRIVATE_UPLOAD_REQUEST,
    idempotencyKey: "expired-ready-session",
  };
  const started = await service.beginPrivateUpload(request);
  setNow(new Date(Date.parse(started.expiresAt) + 1));

  await assert.rejects(
    service.reconcileUpload(
      "user-1",
      "reconcile-expired",
      started.jobKey,
    ),
    (error: unknown) => {
      assert.ok(error instanceof YouTubeProviderError);
      assert.equal(error.code, "conflict");
      assert.equal(error.retryable, false);
      return true;
    },
  );

  const failed = publications.records.get(started.jobKey);
  assert.equal(failed?.state, "FAILED");
  assert.equal(failed?.failureCode, "upload_session_expired");
  assert.equal(failed?.encryptedSessionUrl, "");
});

test("reconcile rejects a video outside the connected channel", async () => {
  const now = new Date("2026-07-23T00:00:00Z");
  const uploadCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 3),
    "k1",
    "youtube-upload-session",
  );
  const connection: YouTubeProviderConnectionRecord = {
    connectionKey: "ytc_connection",
    userId: "user-1",
    channelId: "UC1234",
    channelTitle: "Creator",
    grantedScopes: [YOUTUBE_READONLY_SCOPE],
    connectedAt: now.toISOString(),
    lastVerifiedAt: now.toISOString(),
    status: "ACTIVE",
  };
  const publications = new MemoryPublicationStore();
  publications.records.set("job-user-1", {
    jobKey: "job-user-1",
    userId: "user-1",
    connectionKey: connection.connectionKey,
    idempotencyKey: "upload-1",
    requestFingerprint: "sha256:reconcile-request",
    title: "Private upload",
    privacyStatus: "private",
    contentLength: 2048,
    encryptedSessionUrl: uploadCipher.encrypt(
      "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=session",
      "upload:job-user-1",
    ),
    state: "SESSION_READY",
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  });
  const refreshTokens = new RefreshTokenVault(
    new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 1),
      "k1",
      "youtube-refresh-token",
    ),
    new MemoryCredentialStore(),
    () => now,
  );
  await refreshTokens.save(
    connection.connectionKey,
    "refresh-token",
    connection.grantedScopes,
  );
  const transport = new OwnershipTransport();
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: true,
      ownerConnect: true,
      privateUpload: true,
      ownerAnalytics: true,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections: new MemoryConnectionStore(connection),
    publications,
    oauthAttempts: {
      save: async () => undefined,
      consume: async () => null,
      consumeByState: async () => null,
      deleteByUser: async () => undefined,
    },
    refreshTokens,
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 2),
      "k1",
      "youtube-oauth-verifier",
    ),
    uploadSessionCipher: uploadCipher,
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri: "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });

  await assert.rejects(
    service.reconcileUpload(
      "user-1",
      "request-1",
      "job-user-1",
    ),
    (error: unknown) => {
      assert.ok(error instanceof YouTubeProviderError);
      assert.equal(error.code, "permission_denied");
      return true;
    },
  );
});

test("reconcile binds the session once then polls the stored video to completion", async () => {
  const now = new Date("2026-07-23T00:00:00Z");
  const connection: YouTubeProviderConnectionRecord = {
    connectionKey: "ytc_connection",
    userId: "user-1",
    channelId: "UC1234",
    channelTitle: "Creator",
    grantedScopes: [YOUTUBE_READONLY_SCOPE],
    connectedAt: now.toISOString(),
    lastVerifiedAt: now.toISOString(),
    status: "ACTIVE",
  };
  const uploadCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 3),
    "k1",
    "youtube-upload-session",
  );
  const publications = new MemoryPublicationStore();
  publications.records.set("job-user-1", {
    jobKey: "job-user-1",
    userId: "user-1",
    connectionKey: connection.connectionKey,
    idempotencyKey: "upload-1",
    requestFingerprint: "sha256:reconcile-request",
    title: "Private upload",
    privacyStatus: "private",
    contentLength: 2048,
    encryptedSessionUrl: uploadCipher.encrypt(
      "https://www.googleapis.com/upload/youtube/v3/videos?upload_id=session",
      "upload:job-user-1",
    ),
    state: "SESSION_READY",
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  });
  const refreshTokens = new RefreshTokenVault(
    new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 1),
      "k1",
      "youtube-refresh-token",
    ),
    new MemoryCredentialStore(),
    () => now,
  );
  await refreshTokens.save(
    connection.connectionKey,
    "refresh-token",
    connection.grantedScopes,
  );
  const transport = new ProgressiveUploadTransport();
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: true,
      ownerConnect: true,
      privateUpload: true,
      ownerAnalytics: true,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections: new MemoryConnectionStore(connection),
    publications,
    oauthAttempts: {
      save: async () => undefined,
      consume: async () => null,
      consumeByState: async () => null,
      deleteByUser: async () => undefined,
    },
    refreshTokens,
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 2),
      "k1",
      "youtube-oauth-verifier",
    ),
    uploadSessionCipher: uploadCipher,
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });

  const first = await service.reconcileUpload(
    "user-1",
    "request-1",
    "job-user-1",
  );
  const processing = publications.records.get("job-user-1");
  const second = await service.reconcileUpload(
    "user-1",
    "request-2",
    "job-user-1",
  );
  const complete = publications.records.get("job-user-1");

  assert.equal(first.uploadStatus, "uploaded");
  assert.equal(processing?.state, "PROCESSING");
  assert.equal(processing?.videoId, "video123");
  assert.equal(processing?.encryptedSessionUrl, "");
  assert.equal(second.uploadStatus, "processed");
  assert.equal(complete?.state, "COMPLETE");
  assert.equal(transport.uploadStatusChecks, 1);
  assert.equal(transport.videoReads, 2);
});

test("upload-only capability completes readonly-rooted OAuth without ownerConnect", async () => {
  const now = new Date("2026-07-23T00:00:00Z");
  const savedAttempts: OAuthAttemptRecord[] = [];
  let consumed = false;
  const attempts: OAuthAttemptStore = {
    save: async (record) => {
      savedAttempts.push(record);
    },
    consume: async (stateHash, userId) => {
      const savedAttempt = savedAttempts.at(-1);
      if (
        consumed ||
        savedAttempt === undefined ||
        savedAttempt.stateHash !== stateHash ||
        savedAttempt.userId !== userId
      ) {
        return null;
      }
      consumed = true;
      return savedAttempt;
    },
    consumeByState: async () => null,
    deleteByUser: async () => undefined,
  };
  const transport = new ConnectTransport(
    `${YOUTUBE_READONLY_SCOPE} ${YOUTUBE_UPLOAD_SCOPE}`,
  );
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const connections = new MemoryConnectionStore(null);
  const verifierCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 2),
    "k1",
    "youtube-oauth-verifier",
  );
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: false,
      ownerConnect: false,
      privateUpload: true,
      ownerAnalytics: false,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections,
    publications: new MemoryPublicationStore(),
    oauthAttempts: attempts,
    refreshTokens: new RefreshTokenVault(
      new Aes256GcmEnvelopeCipher(
        Buffer.alloc(32, 1),
        "k1",
        "youtube-refresh-token",
      ),
      new MemoryCredentialStore(),
      () => now,
    ),
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: verifierCipher,
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });

  for (const purpose of ["readonly", "analytics"] as const) {
    await assert.rejects(
      service.beginConnect({ userId: "user-1", purpose }),
      (error: unknown) =>
        error instanceof YouTubeProviderError &&
        error.code === "capability_disabled",
    );
  }

  const started = await service.beginConnect({
    userId: "user-1",
    purpose: "upload",
  });
  const state = new URL(started.authorizationUrl).searchParams.get("state");
  assert.ok(state);
  assert.deepEqual(savedAttempts.at(-1)?.requestedScopes, [
    YOUTUBE_READONLY_SCOPE,
    YOUTUBE_UPLOAD_SCOPE,
  ]);

  const channel = await service.completeConnect({
    userId: "user-1",
    state,
    code: "authorization-code",
  });

  assert.equal(channel.channelId, "UC_CALLBACK");
  assert.deepEqual(
    (await connections.getByUser("user-1"))?.grantedScopes,
    [YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE].sort(),
  );
});

test("disconnect purges local owner data when every feature flag is off", async () => {
  const now = new Date("2026-07-23T00:00:00Z");
  const connection: YouTubeProviderConnectionRecord = {
    connectionKey: "ytc_connection",
    userId: "user-1",
    channelId: "UC1234",
    channelTitle: "Creator",
    grantedScopes: [YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE],
    connectedAt: now.toISOString(),
    lastVerifiedAt: now.toISOString(),
    status: "ACTIVE",
  };
  const connections = new MemoryConnectionStore(connection);
  const publications = new MemoryPublicationStore();
  publications.records.set("job-user-1", {
    jobKey: "job-user-1",
    userId: "user-1",
    connectionKey: connection.connectionKey,
    idempotencyKey: "upload-1",
    requestFingerprint: "sha256:disconnect-test",
    title: "Private upload",
    privacyStatus: "private",
    contentLength: 2048,
    encryptedSessionUrl: "mstv1.deleted-by-disconnect",
    state: "SESSION_READY",
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  });
  let attemptsDeletedFor: string | null = null;
  const oauthAttempts: OAuthAttemptStore = {
    save: async () => undefined,
    consume: async () => null,
    consumeByState: async () => null,
    deleteByUser: async (userId) => {
      attemptsDeletedFor = userId;
    },
  };
  const credentialStore = new MemoryCredentialStore();
  const refreshTokens = new RefreshTokenVault(
    new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 1),
      "k1",
      "youtube-refresh-token",
    ),
    credentialStore,
    () => now,
  );
  await refreshTokens.save(
    connection.connectionKey,
    "refresh-token",
    connection.grantedScopes,
  );
  const accessTokens = new InMemoryAccessTokenCache(() => now.getTime());
  accessTokens.set(connection.connectionKey, {
    accessToken: "access-token",
    expiresAtEpochMs: now.getTime() + 60 * 60 * 1000,
    grantedScopes: connection.grantedScopes,
  });
  const revokeRequests: HttpTransportRequest[] = [];
  const transport: HttpTransport = {
    send: async (request) => {
      revokeRequests.push(request);
      assert.equal(request.url, "https://oauth2.googleapis.com/revoke");
      return { status: 200, headers: {}, body: "" };
    },
  };
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: false,
      ownerConnect: false,
      privateUpload: false,
      ownerAnalytics: false,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections,
    publications,
    oauthAttempts,
    refreshTokens,
    accessTokens,
    oauthVerifierCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 2),
      "k1",
      "youtube-oauth-verifier",
    ),
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });

  const result = await service.disconnect("user-1");

  assert.deepEqual(result, {
    disconnected: true,
    providerRevocationConfirmed: true,
  });
  assert.equal(revokeRequests.length, 1);
  assert.equal(
    new URLSearchParams(revokeRequests[0]?.body).get("token"),
    "refresh-token",
  );
  assert.equal(await connections.getByUser("user-1"), null);
  assert.equal(await refreshTokens.load(connection.connectionKey), undefined);
  assert.equal(accessTokens.get(connection.connectionKey), undefined);
  assert.equal(publications.records.size, 0);
  assert.equal(attemptsDeletedFor, "user-1");
});

test("server OAuth callback consumes one-time state and stores one user connection", async () => {
  const now = new Date("2026-07-23T00:00:00Z");
  const state = "private-dev-state";
  const stateHash = createHash("sha256")
    .update(state, "utf8")
    .digest("base64url");
  const verifierCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 2),
    "k1",
    "youtube-oauth-verifier",
  );
  let consumed = false;
  const attempts: OAuthAttemptStore = {
    save: async () => undefined,
    consume: async () => null,
    consumeByState: async (candidate) => {
      if (consumed || candidate !== stateHash) return null;
      consumed = true;
      return {
        stateHash,
        userId: "user-1",
        encryptedCodeVerifier: verifierCipher.encrypt(
          "A".repeat(64),
          `oauth:${stateHash}`,
        ),
        requestedScopes: [YOUTUBE_READONLY_SCOPE],
        redirectUri:
          "https://dev.moolsocial.com/google-callback/youtube",
        createdAt: now.toISOString(),
        expiresAt: new Date(now.getTime() + 600_000).toISOString(),
      };
    },
    deleteByUser: async () => undefined,
  };
  const transport = new ConnectTransport();
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const connections = new MemoryConnectionStore(null);
  const credentials = new MemoryCredentialStore();
  const service = new YouTubeProviderService({
    capabilities: {
      environment: "dev",
      publicData: true,
      ownerConnect: true,
      privateUpload: true,
      ownerAnalytics: true,
      publicOrUnlistedUpload: false,
    },
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections,
    publications: new MemoryPublicationStore(),
    oauthAttempts: attempts,
    refreshTokens: new RefreshTokenVault(
      new Aes256GcmEnvelopeCipher(
        Buffer.alloc(32, 1),
        "k1",
        "youtube-refresh-token",
      ),
      credentials,
      () => now,
    ),
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: verifierCipher,
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });

  const channel = await service.completeConnectFromCallback(state, "code");
  const saved = await connections.getByUser("user-1");

  assert.equal(channel.channelId, "UC_CALLBACK");
  assert.equal(saved?.channelId, "UC_CALLBACK");
  assert.ok(saved?.connectionKey.startsWith("ytc_"));
  assert.equal(
    transport.requests[0]?.body?.includes("client_secret=server-held-secret"),
    true,
  );
  await assert.rejects(
    service.completeConnectFromCallback(state, "code"),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "authentication_required",
  );
});

test("cold start preserves cumulative scopes when incremental OAuth omits refresh token and scope", async () => {
  const now = new Date("2026-07-24T00:00:00Z");
  const state = "incremental-reconnect-state";
  const stateHash = createHash("sha256")
    .update(state, "utf8")
    .digest("base64url");
  const connectionKey = callbackConnectionKey("user-1");
  const verifierCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 2),
    "k1",
    "youtube-oauth-verifier",
  );
  let consumed = false;
  const attempts: OAuthAttemptStore = {
    save: async () => undefined,
    consume: async () => null,
    consumeByState: async (candidate) => {
      if (consumed || candidate !== stateHash) return null;
      consumed = true;
      return {
        stateHash,
        userId: "user-1",
        encryptedCodeVerifier: verifierCipher.encrypt(
          "A".repeat(64),
          `oauth:${stateHash}`,
        ),
        requestedScopes: [
          YOUTUBE_READONLY_SCOPE,
          YOUTUBE_ANALYTICS_READONLY_SCOPE,
        ],
        redirectUri:
          "https://dev.moolsocial.com/google-callback/youtube",
        createdAt: now.toISOString(),
        expiresAt: new Date(now.getTime() + 600_000).toISOString(),
      };
    },
    deleteByUser: async () => undefined,
  };
  const existingConnection: YouTubeProviderConnectionRecord = {
    connectionKey,
    userId: "user-1",
    channelId: "UC_CALLBACK",
    channelTitle: "Connected creator",
    grantedScopes: [YOUTUBE_READONLY_SCOPE, YOUTUBE_UPLOAD_SCOPE],
    connectedAt: "2026-07-23T00:00:00.000Z",
    lastVerifiedAt: "2026-07-23T00:00:00.000Z",
    status: "ACTIVE",
  };
  const connections = new MemoryConnectionStore(existingConnection);
  const credentials = new MemoryCredentialStore();
  const tokenCipher = new Aes256GcmEnvelopeCipher(
    Buffer.alloc(32, 1),
    "k1",
    "youtube-refresh-token",
  );
  const refreshTokens = new RefreshTokenVault(
    tokenCipher,
    credentials,
    () => now,
  );
  await refreshTokens.save(
    connectionKey,
    "existing-refresh-token",
    existingConnection.grantedScopes,
  );
  const transport = new IncrementalReconnectTransport();
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const publications = new MemoryPublicationStore();
  const capabilities = {
    environment: "dev",
    publicData: true,
    ownerConnect: true,
    privateUpload: true,
    ownerAnalytics: true,
    publicOrUnlistedUpload: false,
  } as const;
  const service = new YouTubeProviderService({
    capabilities,
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections,
    publications,
    oauthAttempts: attempts,
    refreshTokens,
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: verifierCipher,
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });

  await service.completeConnectFromCallback(state, "code");

  const expectedScopes = [
    YOUTUBE_ANALYTICS_READONLY_SCOPE,
    YOUTUBE_READONLY_SCOPE,
    YOUTUBE_UPLOAD_SCOPE,
  ].sort();
  assert.deepEqual(
    (await connections.getByUser("user-1"))?.grantedScopes,
    expectedScopes,
  );

  const coldVault = new RefreshTokenVault(
    new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 1),
      "k1",
      "youtube-refresh-token",
    ),
    credentials,
    () => now,
  );
  assert.deepEqual(
    (await coldVault.load(connectionKey))?.grantedScopes,
    expectedScopes,
  );
  const coldService = new YouTubeProviderService({
    capabilities,
    dataClient: new YouTubeDataClient({
      transport,
      quota,
      cache: new ProcessYouTubeCache(),
      serverApiKey: "restricted-key",
    }),
    ownerClient: new YouTubeOwnerClient({ transport, quota }),
    transport,
    connections,
    publications,
    oauthAttempts: {
      save: async () => undefined,
      consume: async () => null,
      consumeByState: async () => null,
      deleteByUser: async () => undefined,
    },
    refreshTokens: coldVault,
    accessTokens: new InMemoryAccessTokenCache(() => now.getTime()),
    oauthVerifierCipher: verifierCipher,
    uploadSessionCipher: new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 3),
      "k1",
      "youtube-upload-session",
    ),
    oauthClientId: "confidential-web-client-id",
    oauthClientSecret: "server-held-secret",
    oauthRedirectUri:
      "https://dev.moolsocial.com/google-callback/youtube",
    clock: { now: () => now },
  });

  const registeredAccess =
    await coldService.ownerAnalyticsReportingAccess(
      "user-1",
      "analytics-registration-after-cold-start",
    );
  assert.equal(registeredAccess.principal, "user-1");
  assert.equal(
    registeredAccess.requestId,
    "analytics-registration-after-cold-start",
  );
  assert.equal(registeredAccess.accessToken.length > 0, true);
  assert.deepEqual(registeredAccess.owner, {
    userId: "user-1",
    channelId: "UC_CALLBACK",
    status: "ACTIVE",
    grantedScopes: expectedScopes,
  });

  const analytics = await coldService.ownerAnalyticsPreset(
    "user-1",
    "analytics-after-cold-start",
    {
      preset: "overview",
      startDate: "2026-07-23",
      endDate: "2026-07-23",
    },
  );
  assert.deepEqual(analytics.rows, [
    {
      dimensions: { day: "2026-07-23" },
      metrics: { views: 12 },
    },
  ]);
  assert.equal(
    transport.requests.some(
      (request) =>
        request.url === "https://oauth2.googleapis.com/token" &&
        new URLSearchParams(request.body).get("grant_type") ===
          "refresh_token",
    ),
    true,
  );
});

test("OAuth connection-save failure restores the previous refresh credential", async () => {
  const connectionKey = callbackConnectionKey("user-1");
  const existingConnection: YouTubeProviderConnectionRecord = {
    connectionKey,
    userId: "user-1",
    channelId: "UC_CALLBACK",
    channelTitle: "Previously connected creator",
    grantedScopes: [YOUTUBE_READONLY_SCOPE],
    connectedAt: "2026-07-22T00:00:00.000Z",
    lastVerifiedAt: "2026-07-22T00:00:00.000Z",
    status: "ACTIVE",
  };
  const harness = failedConnectionSaveHarness(existingConnection);
  await harness.refreshTokens.save(
    connectionKey,
    "previous-refresh-token",
    [YOUTUBE_READONLY_SCOPE],
  );

  await assert.rejects(
    harness.service.completeConnectFromCallback(harness.state, "code"),
    /connection write failed/,
  );

  const restored = await harness.refreshTokens.load(connectionKey);
  assert.equal(restored?.refreshToken, "previous-refresh-token");
  assert.deepEqual(restored?.grantedScopes, [YOUTUBE_READONLY_SCOPE]);
});

test("OAuth first-connect save failure deletes the newly stored refresh credential", async () => {
  const connectionKey = callbackConnectionKey("user-1");
  const harness = failedConnectionSaveHarness(null);

  await assert.rejects(
    harness.service.completeConnectFromCallback(harness.state, "code"),
    /connection write failed/,
  );

  assert.equal(await harness.refreshTokens.load(connectionKey), undefined);
});
