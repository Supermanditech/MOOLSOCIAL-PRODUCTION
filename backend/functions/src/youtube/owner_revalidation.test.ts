import assert from "node:assert/strict";
import test from "node:test";

import { ProcessYouTubeCache } from "./adapters.js";
import { YouTubeDataClient } from "./client.js";
import type { OAuthAttemptStore } from "./oauth_attempt_store.js";
import {
  YOUTUBE_READONLY_SCOPE,
} from "./oauth.js";
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
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
  YouTubeProviderConnectionRecord,
  YouTubePublicationJobRecord,
} from "./types.js";

class Credentials implements EncryptedRefreshTokenPersistence {
  private readonly values = new Map<string, EncryptedRefreshTokenRecord>();
  async get(key: string): Promise<EncryptedRefreshTokenRecord | undefined> {
    return this.values.get(key);
  }
  async put(value: EncryptedRefreshTokenRecord): Promise<void> {
    this.values.set(value.connectionKey, value);
  }
  async delete(key: string): Promise<void> {
    this.values.delete(key);
  }
}

class Connections implements YouTubeConnectionStore {
  constructor(public record: YouTubeProviderConnectionRecord | null) {}
  async getByUser(userId: string): Promise<YouTubeProviderConnectionRecord | null> {
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

const publications: YouTubePublicationStore = {
  reserve: async (record: YouTubePublicationJobRecord) => ({
    created: true,
    record,
  }),
  getByKey: async () => null,
  getByIdempotencyKey: async () => null,
  update: async () => undefined,
  deleteByUser: async () => undefined,
};

const attempts: OAuthAttemptStore = {
  save: async () => undefined,
  consume: async () => null,
  consumeByState: async () => null,
  deleteByUser: async () => undefined,
};

class OwnerReadTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(
    private readonly revalidatedChannelId: string,
    private readonly channelStatus = 200,
  ) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    if (request.url === "https://oauth2.googleapis.com/token") {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          access_token: "fresh-owner-access",
          expires_in: 3600,
          token_type: "Bearer",
          scope: YOUTUBE_READONLY_SCOPE,
        }),
      };
    }
    const url = new URL(request.url);
    if (url.pathname === "/youtube/v3/channels") {
      if (this.channelStatus !== 200) {
        return {
          status: this.channelStatus,
          headers: {},
          body: JSON.stringify({ error: { message: "temporary" } }),
        };
      }
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({
          items: [
            {
              id: this.revalidatedChannelId,
              snippet: {
                title: "Renamed Owner Channel",
                thumbnails: {},
              },
              contentDetails: {
                relatedPlaylists: { uploads: "UU_OWNER_123" },
              },
            },
          ],
        }),
      };
    }
    if (url.pathname === "/youtube/v3/subscriptions") {
      return {
        status: 200,
        headers: {},
        body: JSON.stringify({ items: [] }),
      };
    }
    throw new Error(`Unexpected request: ${request.url}`);
  }
}

async function harness(
  now: Date,
  lastVerifiedAt: string,
  revalidatedChannelId = "UC_OWNER_123",
  channelStatus = 200,
): Promise<{
  readonly service: YouTubeProviderService;
  readonly transport: OwnerReadTransport;
  readonly connections: Connections;
}> {
  const connection: YouTubeProviderConnectionRecord = {
    connectionKey: "ytc_owner",
    userId: "user-owner",
    channelId: "UC_OWNER_123",
    channelTitle: "Owner Channel",
    grantedScopes: [YOUTUBE_READONLY_SCOPE],
    connectedAt: "2026-01-01T00:00:00.000Z",
    lastVerifiedAt,
    status: "ACTIVE",
  };
  const connections = new Connections(connection);
  const transport = new OwnerReadTransport(
    revalidatedChannelId,
    channelStatus,
  );
  const quota: YouTubeQuotaPort = { reserve: async () => undefined };
  const refreshTokens = new RefreshTokenVault(
    new Aes256GcmEnvelopeCipher(
      Buffer.alloc(32, 1),
      "k1",
      "youtube-refresh-token",
    ),
    new Credentials(),
    () => now,
  );
  await refreshTokens.save(
    connection.connectionKey,
    "refresh-token",
    connection.grantedScopes,
  );
  const ownerClient = new YouTubeOwnerClient({
    transport,
    quota,
    clock: { now: () => now },
  });
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
      serverApiKey: "restricted-server-key",
    }),
    ownerClient,
    transport,
    connections,
    publications,
    oauthAttempts: attempts,
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
    oauthRedirectUri: "https://dev.moolsocial.com/youtube/callback",
    clock: { now: () => now },
  });
  return { service, transport, connections };
}

test("a day-29 owner call proceeds without repeated channel verification", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, transport, connections } = await harness(
    now,
    "2026-06-25T00:00:00.001Z",
  );
  const result = await service.ownerSubscriptions(
    "user-owner",
    "day-29",
  );
  assert.equal(result.attribution.channelTitle, "Owner Channel");
  assert.equal(
    transport.requests.some(
      (request) => new URL(request.url).pathname === "/youtube/v3/channels",
    ),
    false,
  );
  assert.equal(
    connections.record?.lastVerifiedAt,
    "2026-06-25T00:00:00.001Z",
  );
});

test("a day-30 owner call revalidates with a refreshed token and atomically updates owner identity", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, transport, connections } = await harness(
    now,
    "2026-06-24T00:00:00.000Z",
  );
  const result = await service.ownerSubscriptions(
    "user-owner",
    "day-30",
  );
  assert.equal(result.attribution.channelTitle, "Renamed Owner Channel");
  assert.equal(connections.record?.channelTitle, "Renamed Owner Channel");
  assert.equal(connections.record?.lastVerifiedAt, now.toISOString());
  const channelRequest = transport.requests.find(
    (request) => new URL(request.url).pathname === "/youtube/v3/channels",
  );
  assert.equal(
    channelRequest?.headers?.authorization,
    "Bearer fresh-owner-access",
  );
});

test("channel mismatch marks the stale connection revoked and fails closed", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, connections } = await harness(
    now,
    "2026-06-24T00:00:00.000Z",
    "UC_OTHER_123",
  );
  await assert.rejects(
    service.ownerSubscriptions("user-owner", "mismatch"),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "authentication_required",
  );
  assert.equal(connections.record?.status, "REVOKED");
});

test("transient day-30 revalidation failure blocks owner work without falsely revoking the connection", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, connections } = await harness(
    now,
    "2026-06-24T00:00:00.000Z",
    "UC_OWNER_123",
    503,
  );
  await assert.rejects(
    service.ownerSubscriptions("user-owner", "transient"),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "provider_unavailable",
  );
  assert.equal(connections.record?.status, "ACTIVE");
  assert.equal(
    connections.record?.lastVerifiedAt,
    "2026-06-24T00:00:00.000Z",
  );
});

test("owner connection status exposes a current day-29 verification window without provider revalidation", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, transport } = await harness(
    now,
    "2026-06-25T00:00:00.001Z",
  );
  const result = await service.connectionStatus(
    "user-owner",
    "connection-status-day-29",
  );
  assert.deepEqual(result, {
    connected: true,
    channelId: "UC_OWNER_123",
    channelTitle: "Owner Channel",
    grantedScopes: [YOUTUBE_READONLY_SCOPE],
    lastVerifiedAt: "2026-06-25T00:00:00.001Z",
    nextVerificationDueAt: "2026-07-25T00:00:00.001Z",
    verificationState: "current",
  });
  assert.equal(
    transport.requests.some(
      (request) => new URL(request.url).pathname === "/youtube/v3/channels",
    ),
    false,
  );
});

test("owner connection status revalidates at day 30 and reports the refreshed identity window", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service } = await harness(
    now,
    "2026-06-24T00:00:00.000Z",
  );
  const result = await service.connectionStatus(
    "user-owner",
    "connection-status-day-30",
  );
  assert.deepEqual(result, {
    connected: true,
    channelId: "UC_OWNER_123",
    channelTitle: "Renamed Owner Channel",
    grantedScopes: [YOUTUBE_READONLY_SCOPE],
    lastVerifiedAt: now.toISOString(),
    nextVerificationDueAt: "2026-08-23T00:00:00.000Z",
    verificationState: "current",
  });
});

test("owner connection status revokes a day-30 channel mismatch instead of reporting it current", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, connections } = await harness(
    now,
    "2026-06-24T00:00:00.000Z",
    "UC_OTHER_123",
  );
  await assert.rejects(
    service.connectionStatus("user-owner", "connection-status-mismatch"),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "authentication_required",
  );
  assert.equal(connections.record?.status, "REVOKED");
});

test("owner connection status fails closed on transient day-30 verification without false revocation", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, connections } = await harness(
    now,
    "2026-06-24T00:00:00.000Z",
    "UC_OWNER_123",
    503,
  );
  await assert.rejects(
    service.connectionStatus("user-owner", "connection-status-transient"),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "provider_unavailable",
  );
  assert.equal(connections.record?.status, "ACTIVE");
});

test("owner connection status exposes reconnect-required state for a non-active connection", async () => {
  const now = new Date("2026-07-24T00:00:00.000Z");
  const { service, connections } = await harness(
    now,
    "2026-06-24T00:00:00.000Z",
  );
  if (connections.record) {
    connections.record = { ...connections.record, status: "REVOKED" };
  }
  const result = await service.connectionStatus(
    "user-owner",
    "connection-status-revoked",
  );
  assert.deepEqual(result, {
    connected: false,
    lastVerifiedAt: "2026-06-24T00:00:00.000Z",
    nextVerificationDueAt: "2026-07-24T00:00:00.000Z",
    verificationState: "reconnect_required",
  });
});
