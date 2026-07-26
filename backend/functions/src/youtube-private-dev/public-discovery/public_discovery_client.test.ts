import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "../../youtube/errors.js";
import type {
  QuotaReservation,
  YouTubeCachePort,
  YouTubeQuotaPort,
} from "../../youtube/ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "../../youtube/types.js";
import {
  PUBLIC_DISCOVERY_OMISSIONS,
  YouTubePublicDiscoveryClient,
} from "./public_discovery_client.js";

const CHANNEL = `UC${"a".repeat(22)}`;
const OTHER_CHANNEL = `UC${"b".repeat(22)}`;
const VIDEO = "abcDEF123_-";
const PLAYLIST = "PL-public-playlist";
const FIXED_NOW = new Date("2026-07-25T08:00:00.000Z");

function response(
  body: unknown,
  status = 200,
): HttpTransportResponse {
  return {
    status,
    headers: {},
    body: typeof body === "string" ? body : JSON.stringify(body),
  };
}

class QueueTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(
    private readonly responses: HttpTransportResponse[],
  ) {}

  async send(
    request: HttpTransportRequest,
  ): Promise<HttpTransportResponse> {
    this.requests.push(request);
    const next = this.responses.shift();
    if (next === undefined) {
      throw new Error("No fake provider response is available.");
    }
    return next;
  }
}

class RecordingQuota implements YouTubeQuotaPort {
  readonly reservations: QuotaReservation[] = [];

  async reserve(reservation: QuotaReservation): Promise<void> {
    this.reservations.push(reservation);
  }
}

class MemoryCache implements YouTubeCachePort {
  readonly calls: Array<{ readonly key: string; readonly ttlMs: number }> =
    [];
  private readonly values = new Map<string, unknown>();

  async getOrLoad<T>(
    key: string,
    ttlMs: number,
    loader: () => Promise<T>,
  ): Promise<T> {
    this.calls.push({ key, ttlMs });
    if (this.values.has(key)) return this.values.get(key) as T;
    const value = await loader();
    this.values.set(key, value);
    return value;
  }
}

function makeClient(
  providerResponses: HttpTransportResponse[],
  enabled: boolean | (() => boolean) = true,
): {
  readonly client: YouTubePublicDiscoveryClient;
  readonly transport: QueueTransport;
  readonly quota: RecordingQuota;
  readonly cache: MemoryCache;
} {
  const transport = new QueueTransport(providerResponses);
  const quota = new RecordingQuota();
  const cache = new MemoryCache();
  return {
    client: new YouTubePublicDiscoveryClient({
      transport,
      quota,
      cache,
      serverApiKey: "restricted-test-server-key",
      enabled,
      clock: { now: () => FIXED_NOW },
    }),
    transport,
    quota,
    cache,
  };
}

async function rejectsCode(
  action: Promise<unknown>,
  code: YouTubeProviderError["code"],
): Promise<void> {
  await assert.rejects(
    action,
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === code,
  );
}

function uploadActivity(
  overrides: Readonly<Record<string, unknown>> = {},
): Readonly<Record<string, unknown>> {
  return {
    id: "activity_upload_1",
    snippet: {
      publishedAt: "2026-07-24T06:00:00Z",
      channelId: CHANNEL,
      title: "Fresh market dispatch",
      description: "",
      thumbnails: {
        high: {
          url: "https://i.ytimg.com/vi/abcDEF123_-/hqdefault.jpg",
          width: 480,
          height: 360,
        },
      },
      channelTitle: "MoolSocial Public Channel",
      type: "upload",
      groupId: "group_1",
    },
    contentDetails: {
      upload: { videoId: VIDEO },
    },
    ...overrides,
  };
}

test("public discovery is fail-closed unless explicitly enabled", async () => {
  const harness = makeClient([], false);
  await rejectsCode(
    harness.client.listChannelActivities("viewer", "request-1", {
      channelId: CHANNEL,
    }),
    "capability_disabled",
  );
  assert.equal(harness.transport.requests.length, 0);
  assert.equal(harness.quota.reservations.length, 0);
  assert.equal(harness.cache.calls.length, 0);
});

test("a warm public discovery client rechecks capability before every request", async () => {
  let enabled = true;
  const harness = makeClient(
    [response({ items: [] })],
    () => enabled,
  );

  await harness.client.listChannelSections("viewer", "request-1", CHANNEL);
  assert.equal(harness.transport.requests.length, 1);
  assert.equal(harness.quota.reservations.length, 1);

  enabled = false;
  await rejectsCode(
    harness.client.listChannelSections("viewer", "request-2", OTHER_CHANNEL),
    "capability_disabled",
  );
  assert.equal(harness.transport.requests.length, 1);
  assert.equal(harness.quota.reservations.length, 1);
});

test("constructor requires a nonempty restricted server key", () => {
  assert.throws(
    () =>
      new YouTubePublicDiscoveryClient({
        transport: new QueueTransport([]),
        quota: new RecordingQuota(),
        cache: new MemoryCache(),
        serverApiKey: " ",
        enabled: true,
      }),
    /restricted YouTube server API key/u,
  );
});

test("channel activities use fixed public filters, fields, cache and one-unit quota", async () => {
  const harness = makeClient([
    response({
      nextPageToken: "NEXT_PAGE",
      items: [
        uploadActivity(),
        {
          id: "activity_subscription_1",
          snippet: {
            publishedAt: "2026-07-24T07:00:00.125Z",
            channelId: CHANNEL,
            title: "A channel joined the public network",
            description: "Public channel activity",
            channelTitle: "MoolSocial Public Channel",
            type: "subscription",
          },
          contentDetails: {
            subscription: {
              resourceId: {
                kind: "youtube#channel",
                channelId: OTHER_CHANNEL,
              },
            },
          },
        },
        {
          id: "activity_recommendation_1",
          snippet: {
            publishedAt: "2026-07-24T07:30:00Z",
            channelId: CHANNEL,
            title: "Provider recommendation",
            description: "",
            channelTitle: "MoolSocial Public Channel",
            type: "recommendation",
          },
        },
      ],
    }),
  ]);
  const query = {
    channelId: CHANNEL,
    regionCode: "in",
    maxResults: 3,
    pageToken: "PAGE_1",
    publishedAfter: "2026-07-20T00:00:00Z",
    publishedBefore: "2026-07-25T07:59:00Z",
    eventTypes: ["upload", "subscription"] as const,
  };

  const first = await harness.client.listChannelActivities(
    "viewer-1",
    "request-1",
    query,
  );
  const second = await harness.client.listChannelActivities(
    "viewer-1",
    "request-2",
    query,
  );

  assert.deepEqual(first, second);
  assert.equal(first.source, "youtube");
  assert.equal(first.feedScope, "publicChannel");
  assert.equal(first.channelId, CHANNEL);
  assert.equal(first.regionCode, "IN");
  assert.equal(first.items.length, 2);
  assert.equal(first.items[0]?.type, "upload");
  assert.deepEqual(first.items[0]?.target, {
    kind: "video",
    videoId: VIDEO,
  });
  assert.equal(
    first.items[0]?.thumbnail?.url,
    "https://i.ytimg.com/vi/abcDEF123_-/hqdefault.jpg",
  );
  assert.deepEqual(first.items[1]?.target, {
    kind: "channel",
    channelId: OTHER_CHANNEL,
  });
  assert.equal(first.omittedByFilterOrUnsupportedCount, 1);
  assert.equal(first.nextPageToken, "NEXT_PAGE");

  assert.equal(harness.transport.requests.length, 1);
  assert.equal(harness.quota.reservations.length, 1);
  assert.deepEqual(harness.quota.reservations[0], {
    principal: "viewer-1",
    bucket: "general",
    amount: 1,
    operation: "activities.list.publicChannel",
    requestId: "request-1",
  });
  assert.equal(harness.cache.calls[0]?.ttlMs, 60_000);
  assert.ok(!harness.cache.calls[0]?.key.includes("restricted-test"));

  const sent = harness.transport.requests[0];
  assert.ok(sent);
  const url = new URL(sent.url);
  assert.equal(url.origin, "https://www.googleapis.com");
  assert.equal(url.pathname, "/youtube/v3/activities");
  assert.equal(url.searchParams.get("part"), "snippet,contentDetails");
  assert.equal(url.searchParams.get("channelId"), CHANNEL);
  assert.equal(url.searchParams.get("regionCode"), "IN");
  assert.equal(url.searchParams.get("maxResults"), "3");
  assert.equal(url.searchParams.get("pageToken"), "PAGE_1");
  assert.equal(
    url.searchParams.get("publishedAfter"),
    "2026-07-20T00:00:00.000Z",
  );
  assert.equal(
    url.searchParams.get("publishedBefore"),
    "2026-07-25T07:59:00.000Z",
  );
  assert.equal(url.searchParams.get("home"), null);
  assert.equal(url.searchParams.get("mine"), null);
  assert.equal(url.searchParams.get("key"), null);
  assert.match(url.searchParams.get("fields") ?? "", /^nextPageToken,items/u);
  assert.deepEqual(sent.headers, {
    "x-goog-api-key": "restricted-test-server-key",
  });
  assert.equal(sent.method, "GET");
  assert.equal(sent.maxResponseBytes, 512 * 1024);
});

test("activity event filtering is local, strict and never claims Home/history", async () => {
  const harness = makeClient([
    response({
      items: [
        uploadActivity(),
        {
          id: "activity_like_1",
          snippet: {
            publishedAt: "2026-07-24T06:30:00Z",
            channelId: CHANNEL,
            title: "Public like",
            description: "",
            channelTitle: "MoolSocial Public Channel",
            type: "like",
          },
          contentDetails: {
            like: {
              resourceId: {
                kind: "youtube#video",
                videoId: VIDEO,
              },
            },
          },
        },
      ],
    }),
  ]);
  const result = await harness.client.listChannelActivities(
    "viewer",
    "request",
    {
      channelId: CHANNEL,
      eventTypes: ["like"],
    },
  );
  assert.deepEqual(
    result.items.map((item) => item.type),
    ["like"],
  );
  assert.equal(result.omittedByFilterOrUnsupportedCount, 1);
  assert.equal(result.feedScope, "publicChannel");
  const url = new URL(harness.transport.requests[0]!.url);
  assert.equal(url.searchParams.has("eventType"), false);
  assert.equal(url.searchParams.has("home"), false);
  assert.equal(url.searchParams.has("mine"), false);
});

test("activity input rejects malformed IDs, pagination, event sets and date windows before quota", async () => {
  const harness = makeClient([]);
  const invalidQueries = [
    { channelId: "not-a-channel" },
    { channelId: CHANNEL, pageToken: "bad token" },
    {
      channelId: CHANNEL,
      eventTypes: ["upload", "upload"] as const,
    },
    {
      channelId: CHANNEL,
      publishedAfter: "2026-07-01T00:00:00Z",
    },
    {
      channelId: CHANNEL,
      publishedAfter: "2026-01-01T00:00:00Z",
      publishedBefore: "2026-07-01T00:00:00Z",
    },
    {
      channelId: CHANNEL,
      publishedAfter: "2026-07-24T00:00:00Z",
      publishedBefore: "2026-07-26T00:00:00Z",
    },
    { channelId: CHANNEL, maxResults: 51 },
  ];
  for (const query of invalidQueries) {
    await rejectsCode(
      harness.client.listChannelActivities(
        "viewer",
        "request",
        query,
      ),
      "bad_request",
    );
  }
  await rejectsCode(
    harness.client.listChannelActivities("", "request", {
      channelId: CHANNEL,
    }),
    "bad_request",
  );
  assert.equal(harness.transport.requests.length, 0);
  assert.equal(harness.quota.reservations.length, 0);
});

test("activity provider validation rejects mismatched targets, invalid tokens and oversized responses", async () => {
  const mismatched = makeClient([
    response({
      items: [
        uploadActivity({
          contentDetails: {
            upload: { videoId: "not-video" },
          },
        }),
      ],
    }),
  ]);
  await rejectsCode(
    mismatched.client.listChannelActivities("viewer", "request", {
      channelId: CHANNEL,
    }),
    "provider_rejected",
  );

  const badToken = makeClient([
    response({ items: [], nextPageToken: "bad token" }),
  ]);
  await rejectsCode(
    badToken.client.listChannelActivities("viewer", "request", {
      channelId: CHANNEL,
    }),
    "provider_rejected",
  );

  const oversized = makeClient([
    response(`{"items":[],"padding":"${"x".repeat(512 * 1024)}"}`),
  ]);
  await rejectsCode(
    oversized.client.listChannelActivities("viewer", "request", {
      channelId: CHANNEL,
    }),
    "provider_rejected",
  );
});

test("provider HTTP errors are mapped and never expose provider bodies", async () => {
  const harness = makeClient([
    response(
      {
        error: {
          errors: [{ reason: "quotaExceeded" }],
          message: "secret provider detail",
        },
      },
      403,
    ),
  ]);
  await assert.rejects(
    harness.client.listChannelActivities("viewer", "request", {
      channelId: CHANNEL,
    }),
    (error: unknown) => {
      assert.ok(error instanceof YouTubeProviderError);
      assert.equal(error.code, "quota_exhausted");
      assert.ok(!error.message.includes("secret provider detail"));
      return true;
    },
  );
});

test("public channel sections are strict, sorted and server-key-only", async () => {
  const harness = makeClient([
    response({
      items: [
        {
          id: "section_multiple_playlists",
          snippet: {
            type: "multiplePlaylists",
            channelId: CHANNEL,
            title: "Market explainers",
            position: 2,
          },
          contentDetails: {
            playlists: [PLAYLIST, "PL-second"],
          },
        },
        {
          id: "section_recent",
          snippet: {
            type: "recentUploads",
            channelId: CHANNEL,
            position: 0,
          },
          contentDetails: {},
        },
        {
          id: "section_channels",
          snippet: {
            type: "multipleChannels",
            channelId: CHANNEL,
            title: "Channels",
            position: 1,
          },
          contentDetails: {
            channels: [OTHER_CHANNEL],
          },
        },
      ],
    }),
  ]);

  const first = await harness.client.listChannelSections(
    "viewer-1",
    "request-1",
    CHANNEL,
  );
  const second = await harness.client.listChannelSections(
    "viewer-1",
    "request-2",
    CHANNEL,
  );

  assert.deepEqual(first, second);
  assert.equal(first.source, "youtube");
  assert.deepEqual(
    first.items.map((item) => item.type),
    ["recentUploads", "multipleChannels", "multiplePlaylists"],
  );
  assert.deepEqual(first.items[1]?.channelIds, [OTHER_CHANNEL]);
  assert.deepEqual(first.items[2]?.playlistIds, [
    PLAYLIST,
    "PL-second",
  ]);
  assert.equal(harness.transport.requests.length, 1);
  assert.deepEqual(harness.quota.reservations, [
    {
      principal: "viewer-1",
      bucket: "general",
      amount: 1,
      operation: "channelSections.list.publicChannel",
      requestId: "request-1",
    },
  ]);
  assert.equal(harness.cache.calls[0]?.ttlMs, 5 * 60_000);

  const sent = harness.transport.requests[0]!;
  const url = new URL(sent.url);
  assert.equal(url.pathname, "/youtube/v3/channelSections");
  assert.equal(url.searchParams.get("part"), "snippet,contentDetails");
  assert.equal(url.searchParams.get("channelId"), CHANNEL);
  assert.equal(url.searchParams.get("mine"), null);
  assert.equal(url.searchParams.get("key"), null);
  assert.equal(
    url.searchParams.get("fields"),
    "items(id,snippet(type,channelId,title,position),contentDetails(playlists,channels))",
  );
  assert.deepEqual(sent.headers, {
    "x-goog-api-key": "restricted-test-server-key",
  });
  assert.equal(sent.maxResponseBytes, 128 * 1024);
});

test("channel section validation rejects invalid cardinality, ownership, position and duplicates", async () => {
  const invalidProviderBodies = [
    {
      items: [
        {
          id: "section_1",
          snippet: {
            type: "singlePlaylist",
            channelId: CHANNEL,
            position: 0,
          },
          contentDetails: { playlists: [PLAYLIST, "PL-second"] },
        },
      ],
    },
    {
      items: [
        {
          id: "section_1",
          snippet: {
            type: "multiplePlaylists",
            channelId: CHANNEL,
            position: 0,
          },
          contentDetails: { playlists: [PLAYLIST] },
        },
      ],
    },
    {
      items: [
        {
          id: "section_1",
          snippet: {
            type: "multipleChannels",
            channelId: CHANNEL,
            title: "Channels",
            position: 0,
          },
          contentDetails: { channels: [CHANNEL] },
        },
      ],
    },
    {
      items: [
        {
          id: "section_1",
          snippet: {
            type: "recentUploads",
            channelId: CHANNEL,
            position: 10,
          },
          contentDetails: {},
        },
      ],
    },
    {
      items: [
        {
          id: "section_1",
          snippet: {
            type: "recentUploads",
            channelId: CHANNEL,
            position: 0,
          },
          contentDetails: {},
        },
        {
          id: "section_1",
          snippet: {
            type: "popularUploads",
            channelId: CHANNEL,
            position: 1,
          },
          contentDetails: {},
        },
      ],
    },
  ];

  for (const body of invalidProviderBodies) {
    const harness = makeClient([response(body)]);
    await rejectsCode(
      harness.client.listChannelSections(
        "viewer",
        `request-${harness.transport.requests.length}`,
        CHANNEL,
      ),
      "provider_rejected",
    );
  }
});

test("owner-only playlist images and overlapping live broadcasts are absent from the public adapter", () => {
  const harness = makeClient([]);
  const adapter = harness.client as unknown as Record<string, unknown>;
  assert.equal(adapter.listPlaylistImages, undefined);
  assert.equal(adapter.listLiveBroadcasts, undefined);
  assert.deepEqual(PUBLIC_DISCOVERY_OMISSIONS, {
    "playlistImages.list": "owner_oauth_required",
    "liveBroadcasts.list": "concurrent_live_slice",
  });
});
