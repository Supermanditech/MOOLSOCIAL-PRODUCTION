import assert from "node:assert/strict";
import test from "node:test";

import { ProcessYouTubeCache } from "./adapters.js";
import { YouTubeDataClient } from "./client.js";
import { YouTubeProviderError } from "./errors.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";
import type {
  QuotaReservation,
  YouTubeQuotaPort,
} from "./ports.js";

class RecordingTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(
    private readonly responses: readonly HttpTransportResponse[],
  ) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    const response = this.responses[this.requests.length - 1];
    if (!response) throw new Error("Unexpected request.");
    return response;
  }
}

class RecordingQuota implements YouTubeQuotaPort {
  readonly reservations: Array<{ bucket: string; amount: number }> = [];

  async reserve(value: QuotaReservation): Promise<void> {
    this.reservations.push({
      bucket: value.bucket,
      amount: value.amount,
    });
  }
}

function response(body: unknown): HttpTransportResponse {
  return {
    status: 200,
    headers: {},
    body: JSON.stringify(body),
  };
}

function apiVideo(
  id: string,
  options: {
    embeddable?: boolean;
    privacyStatus?: string;
    uploadStatus?: string;
    madeForKids?: boolean;
    liveBroadcastContent?: string;
    regionRestriction?: {
      allowed?: readonly string[];
      blocked?: readonly string[];
    };
    youtubeAgeRating?: string;
  } = {},
): unknown {
  return {
    id,
    snippet: {
      title: `Video ${id}`,
      description: "Description",
      channelId: "UC123456",
      channelTitle: "Channel",
      publishedAt: "2026-07-23T00:00:00Z",
      liveBroadcastContent: options.liveBroadcastContent ?? "none",
      thumbnails: {
        high: {
          url: `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
          width: 480,
          height: 360,
        },
      },
    },
    contentDetails: {
      duration: "PT2M",
      ...(options.regionRestriction === undefined
        ? {}
        : { regionRestriction: options.regionRestriction }),
      ...(options.youtubeAgeRating === undefined
        ? {}
        : {
            contentRating: {
              ytRating: options.youtubeAgeRating,
            },
          }),
    },
    statistics: { viewCount: "10", likeCount: "2", commentCount: "1" },
    status: {
      embeddable: options.embeddable ?? true,
      privacyStatus: options.privacyStatus ?? "public",
      uploadStatus: options.uploadStatus ?? "processed",
      madeForKids: options.madeForKids ?? false,
    },
    ...(options.liveBroadcastContent === "live"
      ? {
          liveStreamingDetails: {
            actualStartTime: "2026-07-23T00:00:00Z",
            concurrentViewers: "101",
          },
        }
      : {}),
  };
}

test("mostPopular uses the inexpensive chart endpoint and filters unavailable videos", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        apiVideo("abc12345"),
        apiVideo("hidden99", { embeddable: false }),
        apiVideo("private9", { privacyStatus: "private" }),
      ],
      nextPageToken: "NEXT_1",
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const result = await client.mostPopular("public", "request-1", {
    regionCode: "in",
  });

  assert.deepEqual(result.items.map((item) => item.videoId), ["abc12345"]);
  assert.equal(result.nextPageToken, "NEXT_1");
  assert.deepEqual(result.filtered, {
    total: 2,
    reasons: {
      not_embeddable: 1,
      not_public: 1,
    },
  });
  assert.deepEqual(result.items[0]?.availability, {
    state: "available",
    regionCode: "IN",
    broadcastState: "none",
    syndication: "embeddable_status_only",
  });
  assert.deepEqual(quota.reservations, [{ bucket: "general", amount: 1 }]);
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/youtube/v3/videos");
  assert.equal(url.searchParams.get("chart"), "mostPopular");
  assert.equal(url.searchParams.get("regionCode"), "IN");
  assert.equal(url.searchParams.has("key"), false);
  assert.equal(
    transport.requests[0]?.headers?.["x-goog-api-key"],
    "restricted-key",
  );
});

test("explicit search spends one search call then hydrates metadata in one batch", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        { id: { videoId: "abc12345" } },
        { id: { videoId: "def67890" } },
      ],
    }),
    response({ items: [apiVideo("abc12345"), apiVideo("def67890")] }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const result = await client.explicitSearch("public", "request-2", {
    query: "local business",
  });

  assert.equal(result.items.length, 2);
  assert.deepEqual(quota.reservations, [
    { bucket: "search", amount: 1 },
    { bucket: "general", amount: 1 },
  ]);
  const searchUrl = new URL(transport.requests[0]!.url);
  assert.equal(searchUrl.pathname, "/youtube/v3/search");
  assert.equal(searchUrl.searchParams.get("videoEmbeddable"), "true");
  assert.equal(searchUrl.searchParams.get("videoSyndicated"), "true");
  assert.equal(searchUrl.searchParams.get("q"), "local business");
  assert.equal(searchUrl.searchParams.has("key"), false);
  assert.equal(
    transport.requests[0]?.headers?.["x-goog-api-key"],
    "restricted-key",
  );
  const detailsUrl = new URL(transport.requests[1]!.url);
  assert.equal(detailsUrl.searchParams.get("id"), "abc12345,def67890");
  assert.equal(detailsUrl.searchParams.has("key"), false);
  assert.equal(
    transport.requests[1]?.headers?.["x-goog-api-key"],
    "restricted-key",
  );
  assert.equal(
    result.items[0]?.availability?.syndication,
    "search_filter_confirmed",
  );
});

test("public metadata calls are coalesced and cached", async () => {
  let releases = 0;
  const transport: HttpTransport = {
    send: async () => {
      releases += 1;
      await Promise.resolve();
      return response({ items: [apiVideo("abc12345")] });
    },
  };
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const [first, second] = await Promise.all([
    client.mostPopular("public", "one"),
    client.mostPopular("public", "two"),
  ]);
  const third = await client.mostPopular("public", "three");

  assert.equal(first.items[0]?.videoId, "abc12345");
  assert.equal(second.items[0]?.videoId, "abc12345");
  assert.equal(third.items[0]?.videoId, "abc12345");
  assert.equal(releases, 1);
  assert.equal(quota.reservations.length, 1);
});

test("public policy filters region, age, children, and processing states without failing the page", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        apiVideo("live1234", { liveBroadcastContent: "live" }),
        apiVideo("region99", {
          regionRestriction: { blocked: ["IN"] },
        }),
        apiVideo("age12345", {
          youtubeAgeRating: "ytAgeRestricted",
        }),
        apiVideo("kids1234", { madeForKids: true }),
        apiVideo("upload99", { uploadStatus: "uploaded" }),
        apiVideo("failed99", { uploadStatus: "failed" }),
      ],
    }),
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const result = await client.mostPopular("public", "policy-1", {
    regionCode: "IN",
  });

  assert.deepEqual(result.items.map((item) => item.videoId), ["live1234"]);
  assert.equal(result.items[0]?.availability?.broadcastState, "live");
  assert.deepEqual(result.items[0]?.liveStreamingDetails, {
    actualStartTime: "2026-07-23T00:00:00Z",
    concurrentViewers: "101",
  });
  assert.deepEqual(result.filtered, {
    total: 5,
    reasons: {
      region_restricted: 1,
      age_restricted: 1,
      children_directed: 1,
      processing: 1,
      removed_or_rejected: 1,
    },
  });
});

test("missing or malformed video details produce recoverable availability counts", async () => {
  const incomplete = apiVideo("broken99") as {
    snippet: { title?: string };
  };
  delete incomplete.snippet.title;
  const transport = new RecordingTransport([
    response({
      items: [apiVideo("abc12345"), incomplete],
    }),
    response({ items: [] }),
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const mixed = await client.videoDetailsWithAvailability(
    "public",
    "details-1",
    ["abc12345", "broken99"],
  );
  assert.deepEqual(mixed.items.map((item) => item.videoId), ["abc12345"]);
  assert.deepEqual(mixed.filtered, {
    total: 1,
    reasons: { metadata_invalid: 1 },
  });

  const unavailable = await client.videoDetailsWithAvailability(
    "public",
    "details-2",
    ["missing9"],
  );
  assert.deepEqual(unavailable.items, []);
  assert.deepEqual(unavailable.filtered, {
    total: 1,
    reasons: { unavailable: 1 },
  });
});

test("malformed search candidates are reported without failing valid results", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        { id: { videoId: "abc12345" } },
        { id: {} },
        { id: { videoId: "bad id" } },
      ],
    }),
    response({ items: [apiVideo("abc12345")] }),
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const result = await client.explicitSearch("public", "search-malformed", {
    query: "local produce",
  });

  assert.deepEqual(result.items.map((item) => item.videoId), ["abc12345"]);
  assert.deepEqual(result.filtered, {
    total: 2,
    reasons: { metadata_invalid: 2 },
  });
});

test("batch statistics use the dedicated one-unit bucket, preserve request order, and cache", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        {
          id: "second22",
          snippet: { publishTime: "2026-07-24T02:00:00Z" },
          statistics: {
            viewCount: "200",
            likeCount: "20",
            commentCount: "2",
          },
          contentDetails: {
            duration: "PT2M",
            durationMillis: "120000",
          },
        },
        {
          id: "first111",
          snippet: { publishTime: "2026-07-24T01:00:00Z" },
          statistics: {
            viewCount: "100",
            likeCount: "10",
            commentCount: "1",
          },
          contentDetails: {
            duration: "PT1M",
            durationMillis: "60000",
          },
        },
      ],
      summary: {
        requestedVideoCount: "3",
        succeededVideoCount: "2",
        failedVideoCount: "1",
        failedVideoIds: ["failed33"],
      },
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const first = await client.batchVideoStatistics(
    "public",
    "batch-1",
    ["first111", "second22", "failed33"],
  );
  const cached = await client.batchVideoStatistics(
    "public",
    "batch-2",
    ["first111", "second22", "failed33"],
  );

  assert.deepEqual(first.items.map((item) => item.videoId), [
    "first111",
    "second22",
  ]);
  assert.deepEqual(first.items[0], {
    videoId: "first111",
    publishTime: "2026-07-24T01:00:00Z",
    viewCount: "100",
    likeCount: "10",
    commentCount: "1",
    duration: "PT1M",
    durationMillis: "60000",
  });
  assert.deepEqual(first.summary, {
    requestedVideoCount: "3",
    succeededVideoCount: "2",
    failedVideoCount: "1",
    failedVideoIds: ["failed33"],
  });
  assert.deepEqual(cached, first);
  assert.deepEqual(quota.reservations, [
    { bucket: "batchStats", amount: 1 },
  ]);
  assert.equal(transport.requests.length, 1);
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/youtube/v3/videos:batchGetStats");
  assert.equal(
    url.searchParams.get("part"),
    "id,snippet,statistics,contentDetails",
  );
  assert.equal(
    url.searchParams.get("id"),
    "first111,second22,failed33",
  );
  assert.equal(url.searchParams.has("key"), false);
  assert.equal(
    transport.requests[0]?.headers?.["x-goog-api-key"],
    "restricted-key",
  );
});

test("batch statistics fail closed on inconsistent provider summaries", async () => {
  const transport = new RecordingTransport([
    response({
      items: [{ id: "first111", statistics: { viewCount: "1" } }],
      summary: {
        requestedVideoCount: "2",
        succeededVideoCount: "2",
        failedVideoCount: "0",
        failedVideoIds: [],
      },
    }),
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  await assert.rejects(
    client.batchVideoStatistics(
      "public",
      "batch-invalid",
      ["first111", "second22"],
    ),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_rejected" &&
      error.httpStatus === 502,
  );
});

test("public channel details expose validated public metadata and cache the low-cost read", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        {
          id: "UC123456",
          snippet: {
            title: "Made Across India",
            description: "Public channel description.",
            customUrl: "@madeacrossindia",
            publishedAt: "2024-01-02T03:04:05Z",
            country: "IN",
            thumbnails: {
              high: {
                url: "https://yt3.ggpht.com/channel-photo",
                width: 800,
                height: 800,
              },
            },
          },
          contentDetails: {
            relatedPlaylists: { uploads: "UU123456" },
          },
          statistics: {
            viewCount: "12345",
            subscriberCount: "678",
            hiddenSubscriberCount: false,
            videoCount: "90",
          },
          topicDetails: {
            topicCategories: [
              "https://en.wikipedia.org/wiki/Business",
            ],
          },
        },
      ],
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const first = await client.publicChannelDetails(
    "public",
    "channel-1",
    "UC123456",
  );
  const cached = await client.publicChannelDetails(
    "public",
    "channel-2",
    "UC123456",
  );

  assert.deepEqual(first, {
    channelId: "UC123456",
    title: "Made Across India",
    description: "Public channel description.",
    publishedAt: "2024-01-02T03:04:05Z",
    customUrl: "@madeacrossindia",
    country: "IN",
    uploadsPlaylistId: "UU123456",
    thumbnail: {
      url: "https://yt3.ggpht.com/channel-photo",
      width: 800,
      height: 800,
    },
    statistics: {
      hiddenSubscriberCount: false,
      viewCount: "12345",
      subscriberCount: "678",
      videoCount: "90",
    },
    topicCategories: [
      "https://en.wikipedia.org/wiki/Business",
    ],
  });
  assert.deepEqual(cached, first);
  assert.equal(transport.requests.length, 1);
  assert.deepEqual(quota.reservations, [
    { bucket: "general", amount: 1 },
  ]);
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/youtube/v3/channels");
  assert.equal(url.searchParams.get("id"), "UC123456");
  assert.equal(
    url.searchParams.get("part"),
    "snippet,contentDetails,statistics,topicDetails",
  );
});

test("public comments preserve complete plain text, attribution, pagination, and reply completeness", async () => {
  const completeComment =
    "This complete viewer comment remains available without backend truncation. ".repeat(
      20,
    );
  const transport = new RecordingTransport([
    response({ items: [apiVideo("abc12345")] }),
    response({
      nextPageToken: "COMMENTS_NEXT",
      items: [
        {
          id: "thread-one",
          snippet: {
            channelId: "UC123456",
            videoId: "abc12345",
            totalReplyCount: 2,
            isPublic: true,
            topLevelComment: {
              id: "comment-one",
              snippet: {
                authorDisplayName: "Viewer One",
                authorProfileImageUrl:
                  "https://yt3.ggpht.com/viewer-one",
                authorChannelUrl:
                  "https://www.youtube.com/channel/UCVIEWER1",
                authorChannelId: { value: "UCVIEWER1" },
                channelId: "UC123456",
                textDisplay: completeComment,
                likeCount: 7,
                publishedAt: "2026-07-24T01:00:00Z",
                updatedAt: "2026-07-24T01:05:00Z",
              },
            },
          },
          replies: {
            comments: [
              {
                id: "reply-one",
                snippet: {
                  authorDisplayName: "Viewer Two",
                  channelId: "UC123456",
                  textDisplay: "A complete reply.",
                  parentId: "comment-one",
                  likeCount: 1,
                  publishedAt: "2026-07-24T02:00:00Z",
                  updatedAt: "2026-07-24T02:00:00Z",
                },
              },
            ],
          },
        },
      ],
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const first = await client.publicCommentThreads(
    "public",
    "comments-1",
    {
      videoId: "abc12345",
      regionCode: "in",
      pageToken: "COMMENTS_PAGE",
      maxResults: 25,
      order: "time",
    },
  );
  const cached = await client.publicCommentThreads(
    "public",
    "comments-2",
    {
      videoId: "abc12345",
      regionCode: "in",
      pageToken: "COMMENTS_PAGE",
      maxResults: 25,
      order: "time",
    },
  );

  assert.deepEqual(first.attribution, {
    source: "youtube",
    videoId: "abc12345",
    videoTitle: "Video abc12345",
    channelId: "UC123456",
    channelTitle: "Channel",
  });
  assert.equal(
    first.items[0]?.topLevelComment.textDisplay,
    completeComment,
  );
  assert.ok(
    (first.items[0]?.topLevelComment.textDisplay.length ?? 0) > 1_000,
  );
  assert.equal(first.items[0]?.totalReplyCount, 2);
  assert.equal(first.items[0]?.includedReplyCount, 1);
  assert.equal(first.items[0]?.repliesComplete, false);
  assert.equal(first.items[0]?.replies[0]?.parentId, "comment-one");
  assert.equal(first.nextPageToken, "COMMENTS_NEXT");
  assert.deepEqual(cached, first);
  assert.deepEqual(quota.reservations, [
    { bucket: "general", amount: 1 },
    { bucket: "general", amount: 1 },
  ]);
  assert.equal(transport.requests.length, 2);
  const commentsUrl = new URL(transport.requests[1]!.url);
  assert.equal(commentsUrl.pathname, "/youtube/v3/commentThreads");
  assert.equal(commentsUrl.searchParams.get("part"), "snippet,replies");
  assert.equal(commentsUrl.searchParams.get("videoId"), "abc12345");
  assert.equal(commentsUrl.searchParams.get("textFormat"), "plainText");
  assert.equal(commentsUrl.searchParams.get("order"), "time");
  assert.equal(commentsUrl.searchParams.get("maxResults"), "25");
  assert.equal(
    commentsUrl.searchParams.get("pageToken"),
    "COMMENTS_PAGE",
  );
  assert.equal(
    transport.requests[1]?.headers?.["x-goog-api-key"],
    "restricted-key",
  );
});

test("public comments are explicitly native plain text and normalize unsafe controls", async () => {
  const transport = new RecordingTransport([
    response({ items: [apiVideo("abc12345")] }),
    response({
      items: [
        {
          id: "thread-one",
          snippet: {
            channelId: "UC123456",
            videoId: "abc12345",
            totalReplyCount: 0,
            isPublic: true,
            topLevelComment: {
              id: "comment-one",
              snippet: {
                authorDisplayName: "Viewer\u0000One",
                authorProfileImageUrl:
                  "https://yt3.googleusercontent.com/viewer-one",
                channelId: "UC123456",
                textDisplay:
                  "<b>literal text</b>\r\nsecond\u0000line",
                likeCount: 0,
                publishedAt: "2026-07-24T01:00:00Z",
                updatedAt: "2026-07-24T01:00:00Z",
              },
            },
          },
        },
      ],
    }),
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const page = await client.publicCommentThreads(
    "public",
    "safe-comment",
    { videoId: "abc12345" },
  );
  const comment = page.items[0]?.topLevelComment;
  assert.equal(comment?.textFormat, "plainText");
  assert.equal(
    comment?.textDisplay,
    "<b>literal text</b>\nsecond\uFFFDline",
  );
  assert.equal(comment?.author.displayName, "Viewer\uFFFDOne");
});

test("public comments fail closed on mismatched provider attribution", async () => {
  const transport = new RecordingTransport([
    response({ items: [apiVideo("abc12345")] }),
    response({
      items: [
        {
          id: "thread-one",
          snippet: {
            channelId: "UC_OTHER",
            videoId: "abc12345",
            totalReplyCount: 0,
            isPublic: true,
            topLevelComment: {
              id: "comment-one",
              snippet: {
                authorDisplayName: "Viewer",
                channelId: "UC_OTHER",
                textDisplay: "Comment",
                likeCount: 0,
                publishedAt: "2026-07-24T01:00:00Z",
                updatedAt: "2026-07-24T01:00:00Z",
              },
            },
          },
        },
      ],
    }),
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  await assert.rejects(
    client.publicCommentThreads("public", "comments-invalid", {
      videoId: "abc12345",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_rejected" &&
      error.httpStatus === 502,
  );
});

test("commentsDisabled is converted to a safe comments-unavailable response", async () => {
  const transport = new RecordingTransport([
    response({ items: [apiVideo("abc12345")] }),
    {
      status: 403,
      headers: {},
      body: JSON.stringify({
        error: {
          code: 403,
          message: "provider details must not escape",
          errors: [{ reason: "commentsDisabled" }],
        },
      }),
    },
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  await assert.rejects(
    client.publicCommentThreads("public", "comments-disabled", {
      videoId: "abc12345",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "not_found" &&
      error.httpStatus === 404 &&
      error.message === "Comments are unavailable for this video." &&
      !error.message.includes("provider details"),
  );
});

test("video reads expose provider metadata already present in the existing response", async () => {
  const enriched = apiVideo("abc12345", {
    regionRestriction: { allowed: ["IN", "US"] },
  }) as {
    snippet: Record<string, unknown>;
    contentDetails: Record<string, unknown>;
  };
  enriched.snippet.categoryId = "22";
  enriched.snippet.tags = ["local", "business"];
  enriched.snippet.defaultLanguage = "en-IN";
  enriched.snippet.defaultAudioLanguage = "hi";
  enriched.snippet.localized = {
    title: "Localised title",
    description: "Localised description",
  };
  enriched.contentDetails.caption = "true";
  enriched.contentDetails.definition = "hd";
  enriched.contentDetails.licensedContent = true;
  enriched.contentDetails.projection = "rectangular";
  const transport = new RecordingTransport([
    response({ items: [enriched] }),
  ]);
  const client = new YouTubeDataClient({
    transport,
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const result = await client.videoDetailsWithAvailability(
    "public",
    "enriched-video",
    ["abc12345"],
    { regionCode: "IN" },
  );

  assert.equal(result.items.length, 1);
  assert.deepEqual(result.items[0], {
    videoId: "abc12345",
    title: "Video abc12345",
    channelId: "UC123456",
    channelTitle: "Channel",
    publishedAt: "2026-07-23T00:00:00Z",
    description: "Description",
    thumbnail: {
      url: "https://i.ytimg.com/vi/abc12345/hqdefault.jpg",
      width: 480,
      height: 360,
    },
    categoryId: "22",
    tags: ["local", "business"],
    defaultLanguage: "en-IN",
    defaultAudioLanguage: "hi",
    localized: {
      title: "Localised title",
      description: "Localised description",
    },
    duration: "PT2M",
    captionAvailable: true,
    definition: "hd",
    licensedContent: true,
    projection: "rectangular",
    regionRestriction: { allowed: ["IN", "US"] },
    viewCount: "10",
    likeCount: "2",
    commentCount: "1",
    embeddable: true,
    privacyStatus: "public",
    uploadStatus: "processed",
    availability: {
      state: "available",
      regionCode: "IN",
      broadcastState: "none",
      syndication: "embeddable_status_only",
    },
  });
  assert.equal(transport.requests.length, 1);
});

test("public comment replies use comments.list and verify the complete provider attribution chain", async () => {
  const transport = new RecordingTransport([
    response({ items: [apiVideo("abc12345")] }),
    response({
      items: [
        {
          id: "thread-one",
          snippet: {
            channelId: "UC123456",
            videoId: "abc12345",
            totalReplyCount: 2,
            isPublic: true,
            topLevelComment: {
              id: "comment-one",
              snippet: {
                authorDisplayName: "Original viewer",
                channelId: "UC123456",
                textDisplay: "Original comment.",
                likeCount: 2,
                publishedAt: "2026-07-24T01:00:00Z",
                updatedAt: "2026-07-24T01:00:00Z",
              },
            },
          },
        },
      ],
    }),
    response({
      nextPageToken: "REPLIES_NEXT",
      items: [
        {
          id: "reply-one",
          snippet: {
            authorDisplayName: "First viewer",
            authorChannelId: { value: "UCREPLY01" },
            channelId: "UC123456",
            textDisplay: "First complete reply.",
            parentId: "comment-one",
            likeCount: 1,
            publishedAt: "2026-07-24T02:00:00Z",
            updatedAt: "2026-07-24T02:00:00Z",
          },
        },
        {
          id: "reply-two",
          snippet: {
            authorDisplayName: "Second viewer",
            channelId: "UC123456",
            textDisplay: "Second complete reply.",
            parentId: "comment-one",
            likeCount: 0,
            publishedAt: "2026-07-24T03:00:00Z",
            updatedAt: "2026-07-24T03:00:00Z",
          },
        },
      ],
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });
  const query = {
    videoId: "abc12345",
    threadId: "thread-one",
    parentCommentId: "comment-one",
    pageToken: "REPLIES_PAGE",
    maxResults: 25,
  };

  const first = await client.publicCommentReplies(
    "public",
    "replies-1",
    query,
  );
  const cached = await client.publicCommentReplies(
    "public",
    "replies-2",
    query,
  );

  assert.deepEqual(first.attribution, {
    source: "youtube",
    videoId: "abc12345",
    videoTitle: "Video abc12345",
    channelId: "UC123456",
    channelTitle: "Channel",
    threadId: "thread-one",
    parentCommentId: "comment-one",
  });
  assert.deepEqual(
    first.items.map((item) => item.textDisplay),
    ["First complete reply.", "Second complete reply."],
  );
  assert.equal(first.nextPageToken, "REPLIES_NEXT");
  assert.deepEqual(cached, first);
  assert.deepEqual(quota.reservations, [
    { bucket: "general", amount: 1 },
    { bucket: "general", amount: 1 },
    { bucket: "general", amount: 1 },
  ]);
  assert.equal(transport.requests.length, 3);
  const attributionUrl = new URL(transport.requests[1]!.url);
  assert.equal(attributionUrl.pathname, "/youtube/v3/commentThreads");
  assert.equal(attributionUrl.searchParams.get("id"), "thread-one");
  assert.equal(attributionUrl.searchParams.get("part"), "snippet");
  assert.equal(attributionUrl.searchParams.get("textFormat"), "plainText");
  const repliesUrl = new URL(transport.requests[2]!.url);
  assert.equal(repliesUrl.pathname, "/youtube/v3/comments");
  assert.equal(repliesUrl.searchParams.get("part"), "snippet");
  assert.equal(repliesUrl.searchParams.get("parentId"), "comment-one");
  assert.equal(repliesUrl.searchParams.get("textFormat"), "plainText");
  assert.equal(repliesUrl.searchParams.get("pageToken"), "REPLIES_PAGE");
  assert.equal(repliesUrl.searchParams.get("maxResults"), "25");
  assert.equal(repliesUrl.searchParams.has("key"), false);
  assert.equal(
    transport.requests[2]?.headers?.["x-goog-api-key"],
    "restricted-key",
  );
});

test("public playlist metadata and channel playlists preserve provider pagination and attribution", async () => {
  const detail = {
    id: "PL123456",
    snippet: {
      title: "Local business stories",
      description: "Public playlist description.",
      publishedAt: "2025-01-02T03:04:05Z",
      channelId: "UC123456",
      channelTitle: "Channel",
      defaultLanguage: "en-IN",
      localized: {
        title: "Local business stories",
        description: "Public playlist description.",
      },
      thumbnails: {
        high: {
          url: "https://i.ytimg.com/playlist/PL123456.jpg",
          width: 480,
          height: 360,
        },
      },
    },
    contentDetails: { itemCount: 12 },
    status: { privacyStatus: "public" },
  };
  const second = {
    ...detail,
    id: "PL654321",
    snippet: {
      ...detail.snippet,
      title: "Creator stories",
    },
    contentDetails: { itemCount: 4 },
  };
  const transport = new RecordingTransport([
    response({ items: [detail] }),
    response({
      nextPageToken: "PLAYLISTS_NEXT",
      items: [detail, second],
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const playlist = await client.publicPlaylistDetails(
    "public",
    "playlist-details",
    "PL123456",
  );
  const page = await client.publicChannelPlaylists(
    "public",
    "channel-playlists",
    {
      channelId: "UC123456",
      pageToken: "PLAYLISTS_PAGE",
      maxResults: 20,
    },
  );

  assert.deepEqual(playlist, {
    playlistId: "PL123456",
    title: "Local business stories",
    description: "Public playlist description.",
    publishedAt: "2025-01-02T03:04:05Z",
    channelId: "UC123456",
    channelTitle: "Channel",
    itemCount: 12,
    privacyStatus: "public",
    defaultLanguage: "en-IN",
    localized: {
      title: "Local business stories",
      description: "Public playlist description.",
    },
    thumbnail: {
      url: "https://i.ytimg.com/playlist/PL123456.jpg",
      width: 480,
      height: 360,
    },
  });
  assert.deepEqual(
    page.items.map((item) => item.playlistId),
    ["PL123456", "PL654321"],
  );
  assert.equal(page.nextPageToken, "PLAYLISTS_NEXT");
  assert.deepEqual(quota.reservations, [
    { bucket: "general", amount: 1 },
    { bucket: "general", amount: 1 },
  ]);
  const detailsUrl = new URL(transport.requests[0]!.url);
  assert.equal(detailsUrl.pathname, "/youtube/v3/playlists");
  assert.equal(detailsUrl.searchParams.get("id"), "PL123456");
  const pageUrl = new URL(transport.requests[1]!.url);
  assert.equal(pageUrl.searchParams.get("channelId"), "UC123456");
  assert.equal(pageUrl.searchParams.get("pageToken"), "PLAYLISTS_PAGE");
  assert.equal(pageUrl.searchParams.get("maxResults"), "20");
  assert.equal(pageUrl.searchParams.has("key"), false);
});

test("public channel handle lookup uses channels.list forHandle without spending search quota", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        {
          id: "UC123456",
          snippet: {
            title: "Made Across India",
            description: "Public channel description.",
            customUrl: "@MadeAcrossIndia",
            publishedAt: "2024-01-02T03:04:05Z",
          },
          contentDetails: {
            relatedPlaylists: { uploads: "UU123456" },
          },
          statistics: {
            viewCount: "12345",
            subscriberCount: "678",
            hiddenSubscriberCount: false,
            videoCount: "90",
          },
          topicDetails: { topicCategories: [] },
        },
      ],
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const result = await client.publicChannelByHandle(
    "public",
    "handle-1",
    "@madeacrossindia",
  );

  assert.equal(result.channelId, "UC123456");
  assert.equal(result.customUrl, "@MadeAcrossIndia");
  assert.deepEqual(quota.reservations, [
    { bucket: "general", amount: 1 },
  ]);
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/youtube/v3/channels");
  assert.equal(url.searchParams.get("forHandle"), "@madeacrossindia");
  assert.equal(url.searchParams.has("id"), false);
  assert.equal(url.searchParams.has("key"), false);
});

test("public region, language, and category dictionaries are strictly validated and cached", async () => {
  const transport = new RecordingTransport([
    response({
      items: [
        { id: "IN", snippet: { gl: "IN", name: "India" } },
        { id: "US", snippet: { gl: "US", name: "United States" } },
      ],
    }),
    response({
      items: [
        { id: "en", snippet: { hl: "en", name: "English" } },
        { id: "hi", snippet: { hl: "hi", name: "Hindi" } },
      ],
    }),
    response({
      items: [
        {
          id: "22",
          snippet: {
            title: "People & Blogs",
            assignable: true,
            channelId: "UCBROWSE",
          },
        },
        {
          id: "25",
          snippet: { title: "News & Politics", assignable: true },
        },
      ],
    }),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeDataClient({
    transport,
    quota,
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });

  const regions = await client.publicRegions("public", "regions-1");
  const languages = await client.publicLanguages("public", "languages-1");
  const categories = await client.publicVideoCategories(
    "public",
    "categories-1",
    "in",
  );
  assert.deepEqual(
    await client.publicRegions("public", "regions-2"),
    regions,
  );
  assert.deepEqual(
    await client.publicLanguages("public", "languages-2"),
    languages,
  );
  assert.deepEqual(
    await client.publicVideoCategories(
      "public",
      "categories-2",
      "IN",
    ),
    categories,
  );

  assert.deepEqual(regions, [
    { regionCode: "IN", name: "India" },
    { regionCode: "US", name: "United States" },
  ]);
  assert.deepEqual(languages, [
    { languageCode: "en", name: "English" },
    { languageCode: "hi", name: "Hindi" },
  ]);
  assert.deepEqual(categories, [
    {
      categoryId: "22",
      title: "People & Blogs",
      assignable: true,
      channelId: "UCBROWSE",
    },
    {
      categoryId: "25",
      title: "News & Politics",
      assignable: true,
    },
  ]);
  assert.equal(transport.requests.length, 3);
  assert.deepEqual(quota.reservations, [
    { bucket: "general", amount: 1 },
    { bucket: "general", amount: 1 },
    { bucket: "general", amount: 1 },
  ]);
  assert.equal(
    new URL(transport.requests[0]!.url).pathname,
    "/youtube/v3/i18nRegions",
  );
  assert.equal(
    new URL(transport.requests[1]!.url).pathname,
    "/youtube/v3/i18nLanguages",
  );
  const categoriesUrl = new URL(transport.requests[2]!.url);
  assert.equal(categoriesUrl.pathname, "/youtube/v3/videoCategories");
  assert.equal(categoriesUrl.searchParams.get("regionCode"), "IN");
  assert.equal(categoriesUrl.searchParams.has("key"), false);
});

test("catalog endpoints fail closed on mismatched provider attribution", async () => {
  const playlistClient = new YouTubeDataClient({
    transport: new RecordingTransport([
      response({
        items: [
          {
            id: "PL123456",
            snippet: {
              title: "Wrong channel",
              description: "",
              publishedAt: "2025-01-02T03:04:05Z",
              channelId: "UCOTHER1",
              channelTitle: "Other",
            },
            contentDetails: { itemCount: 1 },
            status: { privacyStatus: "public" },
          },
        ],
      }),
    ]),
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });
  await assert.rejects(
    playlistClient.publicChannelPlaylists(
      "public",
      "wrong-playlist-channel",
      { channelId: "UC123456" },
    ),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_rejected",
  );

  const handleClient = new YouTubeDataClient({
    transport: new RecordingTransport([
      response({
        items: [
          {
            id: "UC123456",
            snippet: {
              title: "Different handle",
              description: "",
              customUrl: "@different",
              publishedAt: "2024-01-02T03:04:05Z",
            },
            statistics: { hiddenSubscriberCount: false },
            topicDetails: { topicCategories: [] },
          },
        ],
      }),
    ]),
    quota: new RecordingQuota(),
    cache: new ProcessYouTubeCache(),
    serverApiKey: "restricted-key",
  });
  await assert.rejects(
    handleClient.publicChannelByHandle(
      "public",
      "wrong-handle",
      "@expected",
    ),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_rejected",
  );
});
