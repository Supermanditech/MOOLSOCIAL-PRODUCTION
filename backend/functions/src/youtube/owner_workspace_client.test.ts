import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "./errors.js";
import { YouTubeOwnerClient } from "./owner_client.js";
import type { QuotaReservation, YouTubeQuotaPort } from "./ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
  YouTubeOwnerAnalyticsPreset,
} from "./types.js";

class QueueTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(
    private readonly replies: readonly HttpTransportResponse[],
  ) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    const reply = this.replies[this.requests.length - 1];
    if (!reply) throw new Error(`Unexpected request: ${request.url}`);
    return reply;
  }
}

function json(body: unknown): HttpTransportResponse {
  return { status: 200, headers: {}, body: JSON.stringify(body) };
}

function recordingQuota(): {
  readonly reservations: QuotaReservation[];
  readonly quota: YouTubeQuotaPort;
} {
  const reservations: QuotaReservation[] = [];
  return {
    reservations,
    quota: {
      reserve: async (reservation) => {
        reservations.push(reservation);
      },
    },
  };
}

const channelResponse = json({
  items: [
    {
      id: "UC_OWNER_123",
      snippet: { title: "Owner Channel", thumbnails: {} },
      contentDetails: { relatedPlaylists: { uploads: "UU_OWNER_123" } },
    },
  ],
});

test("owner upload inventory uses mine plus uploads playlist, hydrates real videos and preserves unavailable entries", async () => {
  const { quota, reservations } = recordingQuota();
  const transport = new QueueTransport([
    channelResponse,
    json({
      nextPageToken: "NEXT_1",
      items: [
        {
          id: "playlist-item-1",
          snippet: {
            publishedAt: "2026-07-23T00:00:00Z",
            position: 0,
            resourceId: { videoId: "video000001" },
          },
          contentDetails: { videoId: "video000001" },
        },
        {
          id: "playlist-item-2",
          snippet: {
            publishedAt: "2026-07-22T00:00:00Z",
            position: 1,
            resourceId: { videoId: "video000002" },
          },
          contentDetails: { videoId: "video000002" },
        },
      ],
    }),
    json({
      items: [
        {
          id: "video000001",
          snippet: {
            title: "Owner video",
            description: "Provider description",
            channelId: "UC_OWNER_123",
            channelTitle: "Owner Channel",
            publishedAt: "2026-07-23T00:00:00Z",
            thumbnails: {
              high: {
                url: "https://i.ytimg.com/vi/video000001/hqdefault.jpg",
                width: 480,
                height: 360,
              },
            },
          },
          contentDetails: { duration: "PT1M2S" },
          statistics: { viewCount: "12", likeCount: "3" },
          status: {
            privacyStatus: "private",
            uploadStatus: "processed",
            embeddable: true,
          },
        },
      ],
    }),
  ]);
  const client = new YouTubeOwnerClient({ transport, quota });

  const page = await client.ownerVideos({
    principal: "uid-hash",
    requestId: "owner-videos-1",
    accessToken: "access",
    expectedChannelId: "UC_OWNER_123",
    expectedChannelTitle: "Owner Channel",
    maxResults: 2,
  });

  assert.equal(page.nextPageToken, "NEXT_1");
  assert.deepEqual(page.attribution, {
    source: "youtube",
    channelId: "UC_OWNER_123",
    channelTitle: "Owner Channel",
  });
  assert.equal(page.items[0]?.state, "available");
  assert.equal(
    page.items[0]?.state === "available"
      ? page.items[0].video.title
      : undefined,
    "Owner video",
  );
  assert.deepEqual(page.items[1], {
    state: "unavailable",
    playlistItemId: "playlist-item-2",
    videoId: "video000002",
    playlistPublishedAt: "2026-07-22T00:00:00Z",
    position: 1,
  });
  assert.equal(
    transport.requests.some((request) =>
      request.url.includes("/search?"),
    ),
    false,
  );
  assert.equal(
    new URL(transport.requests[0]!.url).searchParams.get("mine"),
    "true",
  );
  assert.equal(
    new URL(transport.requests[1]!.url).searchParams.get("playlistId"),
    "UU_OWNER_123",
  );
  assert.equal(
    new URL(transport.requests[2]!.url).searchParams.get("id"),
    "video000001,video000002",
  );
  assert.deepEqual(
    reservations.map((entry) => entry.operation),
    [
      "channels.list.mine.owner",
      "playlistItems.list.ownerUploads",
      "videos.list.ownerInventory",
    ],
  );
});

test("owner subscriptions are readonly, paginated and exactly attributed to the connected owner", async () => {
  const { quota } = recordingQuota();
  const transport = new QueueTransport([
    json({
      nextPageToken: "NEXT_SUB",
      items: [
        {
          id: "subscription-1",
          snippet: {
            title: "Useful Channel",
            description: "Provider description",
            publishedAt: "2026-07-01T00:00:00Z",
            resourceId: { channelId: "UC_TARGET_123" },
            thumbnails: {
              default: { url: "https://yt3.ggpht.com/channel" },
            },
          },
        },
      ],
    }),
  ]);
  const client = new YouTubeOwnerClient({ transport, quota });
  const page = await client.ownerSubscriptions({
    principal: "uid-hash",
    requestId: "owner-subscriptions-1",
    accessToken: "access",
    expectedChannelId: "UC_OWNER_123",
    expectedChannelTitle: "Owner Channel",
    pageToken: "PAGE_1",
  });

  assert.equal(page.nextPageToken, "NEXT_SUB");
  assert.equal(page.items[0]?.channelId, "UC_TARGET_123");
  assert.equal(page.attribution.channelTitle, "Owner Channel");
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/youtube/v3/subscriptions");
  assert.equal(url.searchParams.get("mine"), "true");
  assert.equal(url.searchParams.get("pageToken"), "PAGE_1");
  assert.equal(url.searchParams.get("maxResults"), "25");
  assert.equal(url.searchParams.get("order"), "relevance");
});

test("owner subscriptions pass every supported provider order and reject unsupported order", async () => {
  const { quota } = recordingQuota();
  const transport = new QueueTransport([json({ items: [] }), json({ items: [] }), json({ items: [] })]);
  const client = new YouTubeOwnerClient({ transport, quota });
  for (const order of ["alphabetical", "relevance", "unread"] as const) {
    await client.ownerSubscriptions({
      principal: "uid-hash",
      requestId: `owner-subscriptions-${order}`,
      accessToken: "access",
      expectedChannelId: "UC_OWNER_123",
      expectedChannelTitle: "Owner Channel",
      order,
    });
  }
  assert.deepEqual(
    transport.requests.map((request) =>
      new URL(request.url).searchParams.get("order"),
    ),
    ["alphabetical", "relevance", "unread"],
  );
  await assert.rejects(
    client.ownerSubscriptions({
      principal: "uid-hash",
      requestId: "owner-subscriptions-invalid",
      accessToken: "access",
      expectedChannelId: "UC_OWNER_123",
      expectedChannelTitle: "Owner Channel",
      order: "newest" as "relevance",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "bad_request",
  );
});

test("owner pages default to 25 and accept the provider-supported maximum of 50", async () => {
  const { quota } = recordingQuota();
  const transport = new QueueTransport([json({ items: [] }), json({ items: [] })]);
  const client = new YouTubeOwnerClient({ transport, quota });
  await client.ownerPlaylists({
    principal: "uid-hash",
    requestId: "owner-playlists-default",
    accessToken: "access",
    expectedChannelId: "UC_OWNER_123",
    expectedChannelTitle: "Owner Channel",
  });
  await client.ownerPlaylists({
    principal: "uid-hash",
    requestId: "owner-playlists-maximum",
    accessToken: "access",
    expectedChannelId: "UC_OWNER_123",
    expectedChannelTitle: "Owner Channel",
    maxResults: 50,
  });
  assert.deepEqual(
    transport.requests.map((request) =>
      new URL(request.url).searchParams.get("maxResults"),
    ),
    ["25", "50"],
  );
});

test("owner playlists preserve provider privacy and reject cross-channel results", async () => {
  const { quota } = recordingQuota();
  const valid = new QueueTransport([
    json({
      items: [
        {
          id: "PL_OWNER_1",
          snippet: {
            title: "Private planning",
            description: "",
            publishedAt: "2026-07-01T00:00:00Z",
            channelId: "UC_OWNER_123",
            channelTitle: "Owner Channel",
            thumbnails: {},
          },
          contentDetails: { itemCount: 4 },
          status: { privacyStatus: "private" },
        },
      ],
    }),
  ]);
  const client = new YouTubeOwnerClient({ transport: valid, quota });
  const page = await client.ownerPlaylists({
    principal: "uid-hash",
    requestId: "owner-playlists-1",
    accessToken: "access",
    expectedChannelId: "UC_OWNER_123",
    expectedChannelTitle: "Owner Channel",
  });
  assert.equal(page.items[0]?.privacyStatus, "private");
  assert.equal(page.items[0]?.itemCount, 4);

  const invalid = new YouTubeOwnerClient({
    quota,
    transport: new QueueTransport([
      json({
        items: [
          {
            id: "PL_OTHER_1",
            snippet: {
              title: "Other",
              publishedAt: "2026-07-01T00:00:00Z",
              channelId: "UC_OTHER_123",
              channelTitle: "Other",
            },
            contentDetails: { itemCount: 1 },
            status: { privacyStatus: "public" },
          },
        ],
      }),
    ]),
  });
  await assert.rejects(
    invalid.ownerPlaylists({
      principal: "uid-hash",
      requestId: "owner-playlists-2",
      accessToken: "access",
      expectedChannelId: "UC_OWNER_123",
      expectedChannelTitle: "Owner Channel",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_rejected",
  );
});

test("fixed analytics presets produce only server-controlled official query shapes and use the analytics bucket", async () => {
  const presets: readonly {
    readonly preset: YouTubeOwnerAnalyticsPreset;
    readonly dimensions?: string;
    readonly metrics: string;
    readonly sort?: string;
    readonly filters?: string;
  }[] = [
    {
      preset: "overview",
      metrics:
        "views,engagedViews,estimatedMinutesWatched,averageViewDuration,averageViewPercentage,likes,comments,shares,subscribersGained,subscribersLost",
    },
    {
      preset: "topVideos",
      dimensions: "video",
      metrics:
        "views,engagedViews,estimatedMinutesWatched,averageViewDuration,averageViewPercentage,likes,comments,shares,subscribersGained,subscribersLost",
      sort: "-views",
    },
    {
      preset: "countries",
      dimensions: "country",
      metrics:
        "views,engagedViews,estimatedMinutesWatched,averageViewDuration,averageViewPercentage",
      sort: "-views",
    },
    {
      preset: "trafficSources",
      dimensions: "insightTrafficSourceType",
      metrics: "views,engagedViews,estimatedMinutesWatched",
      sort: "-views",
    },
    {
      preset: "devicesOs",
      dimensions: "deviceType,operatingSystem",
      metrics: "views,engagedViews,estimatedMinutesWatched",
      sort: "-views",
    },
    {
      preset: "videoRetention",
      dimensions: "elapsedVideoTimeRatio",
      metrics:
        "audienceWatchRatio,relativeRetentionPerformance,startedWatching,stoppedWatching,totalSegmentImpressions",
      filters: "video==video000001",
    },
  ];

  for (const expected of presets) {
    const { quota, reservations } = recordingQuota();
    const transport = new QueueTransport([
      json({
        columnHeaders: [
          { name: "views", columnType: "METRIC" },
        ],
        rows: [[12]],
      }),
    ]);
    const client = new YouTubeOwnerClient({ transport, quota });
    const result = await client.analyticsPreset({
      principal: "uid-hash",
      requestId: `analytics-${expected.preset}`,
      accessToken: "access",
      preset: expected.preset,
      startDate: "2025-07-24",
      endDate: "2026-07-24",
      ...(expected.preset === "videoRetention"
        ? { videoId: "video000001" }
        : {}),
      ...(expected.preset === "overview" ? {} : { startIndex: 26 }),
    });
    assert.equal(result.preset, expected.preset);
    assert.equal(result.rows[0]?.metrics.views, 12);
    assert.deepEqual(result.requestedRange, {
      startDate: "2025-07-24",
      endDate: "2026-07-24",
    });
    assert.equal(result.empty, false);
    assert.equal(result.providerMayExcludeRecentIncompleteDays, true);
    assert.equal(result.continuationStartIndex, undefined);
    const url = new URL(transport.requests[0]!.url);
    assert.equal(url.searchParams.get("ids"), "channel==MINE");
    assert.equal(url.searchParams.get("dimensions"), expected.dimensions ?? null);
    assert.equal(url.searchParams.get("metrics"), expected.metrics);
    assert.equal(url.searchParams.get("sort"), expected.sort ?? null);
    assert.equal(url.searchParams.get("filters"), expected.filters ?? null);
    assert.equal(url.searchParams.get("maxResults"), "25");
    assert.equal(
      url.searchParams.get("startIndex"),
      expected.preset === "overview" ? null : "26",
    );
    assert.equal(reservations[0]?.bucket, "analytics");
  }
});

test("paginated analytics return the next 1-based continuation and mark empty pages exactly", async () => {
  const { quota } = recordingQuota();
  const fullRows = Array.from({ length: 25 }, (_, index) => [index + 1]);
  const transport = new QueueTransport([
    json({
      columnHeaders: [{ name: "views", columnType: "METRIC" }],
      rows: fullRows,
    }),
    json({
      columnHeaders: [{ name: "views", columnType: "METRIC" }],
      rows: [],
    }),
  ]);
  const client = new YouTubeOwnerClient({ transport, quota });
  const full = await client.analyticsPreset({
    principal: "uid-hash",
    requestId: "analytics-full-page",
    accessToken: "access",
    preset: "topVideos",
    startDate: "2026-07-01",
    endDate: "2026-07-24",
    startIndex: 51,
  });
  assert.equal(full.continuationStartIndex, 76);
  assert.equal(full.empty, false);
  const empty = await client.analyticsPreset({
    principal: "uid-hash",
    requestId: "analytics-empty-page",
    accessToken: "access",
    preset: "countries",
    startDate: "2026-07-01",
    endDate: "2026-07-24",
    startIndex: 76,
  });
  assert.equal(empty.continuationStartIndex, undefined);
  assert.equal(empty.empty, true);
});

test("analytics presets reject invalid ranges, arbitrary video filters and invalid pagination", async () => {
  const { quota } = recordingQuota();
  const client = new YouTubeOwnerClient({
    transport: new QueueTransport([]),
    quota,
  });
  await assert.rejects(
    client.analyticsPreset({
      principal: "uid",
      requestId: "range",
      accessToken: "access",
      preset: "overview",
      startDate: "2025-07-23",
      endDate: "2026-07-24",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "bad_request",
  );
  await assert.rejects(
    client.analyticsPreset({
      principal: "uid",
      requestId: "filter",
      accessToken: "access",
      preset: "overview",
      startDate: "2026-07-01",
      endDate: "2026-07-24",
      videoId: "video000001",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "bad_request",
  );
  await assert.rejects(
    client.analyticsPreset({
      principal: "uid",
      requestId: "aggregate-pagination",
      accessToken: "access",
      preset: "overview",
      startDate: "2026-07-01",
      endDate: "2026-07-24",
      startIndex: 2,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "bad_request",
  );
  await assert.rejects(
    client.analyticsPreset({
      principal: "uid",
      requestId: "invalid-start-index",
      accessToken: "access",
      preset: "topVideos",
      startDate: "2026-07-01",
      endDate: "2026-07-24",
      startIndex: 0,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "bad_request",
  );
  await assert.rejects(
    client.ownerSubscriptions({
      principal: "uid",
      requestId: "paging",
      accessToken: "access",
      expectedChannelId: "UC_OWNER_123",
      expectedChannelTitle: "Owner",
      maxResults: 51,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "bad_request",
  );
});
