import assert from "node:assert/strict";
import test from "node:test";

import {
  CREATOR_CAPTION_DOWNLOAD_MAX_BYTES,
  YouTubeCreatorAssetsClient,
} from "./creator_assets_client.js";
import { YouTubeProviderError } from "./errors.js";
import type { QuotaReservation, YouTubeQuotaPort } from "./ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";

const ACTOR_CHANNEL = "UCActorChannel123456789012";
const OTHER_CHANNEL = "UCOtherChannel123456789012";
const VIDEO_ID = "abc123DEF45";
const PUBLIC_VIDEO_ID = "pub123DEF45";
const CAPTION_ID = "caption_owner_123";
const PLAYLIST_ID = "PL_owner_playlist_123";
const PLAYLIST_IMAGE_ID = "PLI_owner_image_123";
const SECTION_ID = "section_owner_123";

class QueueTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(private readonly responses: HttpTransportResponse[]) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    const response = this.responses.shift();
    assert.ok(
      response,
      `Unexpected request: ${request.method ?? "GET"} ${request.url}`,
    );
    return response;
  }
}

class RecordingQuota implements YouTubeQuotaPort {
  readonly reservations: QuotaReservation[] = [];

  async reserve(reservation: QuotaReservation): Promise<void> {
    this.reservations.push(reservation);
  }
}

function response(
  body: unknown = {},
  status = 200,
  headers: Readonly<Record<string, string>> = {},
): HttpTransportResponse {
  return {
    status,
    headers,
    body: typeof body === "string" ? body : JSON.stringify(body),
  };
}

function context() {
  return {
    principal: "founder-user",
    requestId: "request-creator-assets",
    accessToken: "short-lived-access-token",
    expectedChannelId: ACTOR_CHANNEL,
  } as const;
}

function apiVideo(
  videoId = VIDEO_ID,
  privacyStatus: "private" | "public" | "unlisted" = "private",
  channelId = ACTOR_CHANNEL,
) {
  return {
    id: videoId,
    snippet: { channelId },
    status: { privacyStatus },
  };
}

function apiCaption(
  captionId = CAPTION_ID,
  videoId = VIDEO_ID,
  isDraft = true,
) {
  return {
    id: captionId,
    snippet: {
      videoId,
      lastUpdated: "2026-07-25T01:02:03Z",
      trackKind: "standard",
      language: "en",
      name: "English",
      audioTrackType: "unknown",
      isCC: false,
      isLarge: false,
      isEasyReader: false,
      isDraft,
      isAutoSynced: false,
      status: "serving",
    },
  };
}

function apiPlaylist() {
  return {
    id: PLAYLIST_ID,
    snippet: { channelId: ACTOR_CHANNEL },
  };
}

function apiPlaylistImage() {
  return {
    id: PLAYLIST_IMAGE_ID,
    snippet: {
      playlistId: PLAYLIST_ID,
      type: "hero",
      width: 1200,
      height: 1200,
      thumbnails: {
        high: {
          url: "https://i.ytimg.com/vi/abc123DEF45/hqdefault.jpg",
          width: 1200,
          height: 1200,
        },
      },
    },
  };
}

function apiSection(
  id = SECTION_ID,
  channelId = ACTOR_CHANNEL,
) {
  return {
    id,
    snippet: {
      channelId,
      type: "multiplePlaylists",
      style: "horizontalRow",
      title: "Founder picks",
      position: 0,
    },
    contentDetails: { playlists: [PLAYLIST_ID] },
  };
}

function uploadLocation(path: string): Readonly<Record<string, string>> {
  return {
    location:
      `https://www.googleapis.com/upload/youtube/v3/${path}` +
      "?upload_id=opaque-secret",
  };
}

function client(
  responses: HttpTransportResponse[],
): {
  readonly assets: YouTubeCreatorAssetsClient;
  readonly transport: QueueTransport;
  readonly quota: RecordingQuota;
} {
  const transport = new QueueTransport(responses);
  const quota = new RecordingQuota();
  return {
    transport,
    quota,
    assets: new YouTubeCreatorAssetsClient({
      transport,
      quota,
      clock: { now: () => new Date("2026-07-25T00:00:00Z") },
    }),
  };
}

test("thumbnail set verifies private ownership and returns only a validated direct session", async () => {
  const { assets, transport, quota } = client([
    response({ items: [apiVideo()] }),
    response("", 200, uploadLocation("thumbnails/set")),
  ]);

  const session = await assets.beginThumbnailSet({
    ...context(),
    videoId: VIDEO_ID,
    contentType: "image/png",
    contentLength: 1024,
  });

  assert.deepEqual(
    {
      uploadMethod: session.uploadMethod,
      resourceKind: session.resourceKind,
      contentType: session.contentType,
      contentLength: session.contentLength,
      expiresAt: session.expiresAt,
    },
    {
      uploadMethod: "PUT",
      resourceKind: "thumbnail",
      contentType: "image/png",
      contentLength: 1024,
      expiresAt: "2026-07-26T00:00:00.000Z",
    },
  );
  const upload = transport.requests[1]!;
  const url = new URL(upload.url);
  assert.equal(url.pathname, "/upload/youtube/v3/thumbnails/set");
  assert.equal(url.searchParams.get("videoId"), VIDEO_ID);
  assert.equal(url.searchParams.get("uploadType"), "resumable");
  assert.equal(upload.body, undefined);
  assert.deepEqual(
    quota.reservations.map(({ operation, amount }) => ({
      operation,
      amount,
    })),
    [
      { operation: "videos.list.creatorAssetPreflight", amount: 1 },
      { operation: "thumbnails.set.resumable.owner", amount: 50 },
    ],
  );
});

test("creator asset video mutations stay fail-closed for public and unlisted videos", async () => {
  for (const privacyStatus of ["public", "unlisted"] as const) {
    const { assets, transport } = client([
      response({ items: [apiVideo(PUBLIC_VIDEO_ID, privacyStatus)] }),
    ]);
    await assert.rejects(
      assets.beginThumbnailSet({
        ...context(),
        videoId: PUBLIC_VIDEO_ID,
        contentType: "image/jpeg",
        contentLength: 1024,
      }),
      (error: unknown) =>
        error instanceof YouTubeProviderError &&
        error.code === "permission_denied" &&
        error.httpStatus === 403,
    );
    assert.equal(transport.requests.length, 1);
  }
});

test("media sessions reject oversized payloads and untrusted provider locations", async () => {
  const oversized = client([response({ items: [apiVideo()] })]);
  await assert.rejects(
    oversized.assets.beginThumbnailSet({
      ...context(),
      videoId: VIDEO_ID,
      contentType: "image/jpeg",
      contentLength: 2 * 1024 * 1024 + 1,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "bad_request",
  );
  assert.equal(oversized.transport.requests.length, 1);

  const redirected = client([
    response({ items: [apiVideo()] }),
    response("", 200, {
      location: "https://evil.example/upload?upload_id=stolen",
    }),
  ]);
  await assert.rejects(
    redirected.assets.beginThumbnailSet({
      ...context(),
      videoId: VIDEO_ID,
      contentType: "image/jpeg",
      contentLength: 1024,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_rejected",
  );
});

test("caption list and bounded download stay owner-scoped without exposing OAuth", async () => {
  const { assets, transport, quota } = client([
    response({ items: [apiVideo()] }),
    response({ items: [apiCaption()] }),
    response({ items: [apiVideo()] }),
    response({ items: [apiCaption()] }),
    response(Buffer.from("WEBVTT\n").toString("base64"), 200, {
      "content-type": "text/vtt",
    }),
  ]);

  const listed = await assets.listCaptions({
    ...context(),
    videoId: VIDEO_ID,
  });
  assert.equal(listed.items[0]?.captionId, CAPTION_ID);
  const downloaded = await assets.downloadCaption({
    ...context(),
    videoId: VIDEO_ID,
    captionId: CAPTION_ID,
    format: "vtt",
    translatedLanguage: "hi",
  });
  assert.equal(downloaded.encoding, "base64");
  assert.equal(downloaded.byteLimit, CREATOR_CAPTION_DOWNLOAD_MAX_BYTES);
  assert.equal(downloaded.data, Buffer.from("WEBVTT\n").toString("base64"));
  const downloadRequest = transport.requests[4]!;
  assert.equal(downloadRequest.responseEncoding, "base64");
  assert.equal(
    downloadRequest.maxResponseBytes,
    CREATOR_CAPTION_DOWNLOAD_MAX_BYTES,
  );
  assert.match(downloadRequest.headers?.authorization ?? "", /^Bearer /);
  assert.equal(
    JSON.stringify(downloaded).includes("short-lived-access-token"),
    false,
  );
  assert.deepEqual(
    quota.reservations.map(({ operation, amount }) => ({
      operation,
      amount,
    })),
    [
      { operation: "videos.list.creatorAssetPreflight", amount: 1 },
      { operation: "captions.list.owner", amount: 50 },
      { operation: "videos.list.creatorAssetPreflight", amount: 1 },
      { operation: "captions.list.ownerPreflight", amount: 50 },
      { operation: "captions.download.owner", amount: 200 },
    ],
  );
});

test("caption insert and replacement use the documented direct resumable methods", async () => {
  const { assets, transport } = client([
    response({ items: [apiVideo()] }),
    response("", 200, uploadLocation("captions")),
    response({ items: [apiVideo()] }),
    response({ items: [apiCaption()] }),
    response("", 200, uploadLocation("captions")),
  ]);

  await assets.beginCaptionInsert({
    ...context(),
    videoId: VIDEO_ID,
    language: "en",
    name: "English",
    isDraft: true,
    contentType: "text/vtt",
    contentLength: 2048,
  });
  await assets.beginCaptionReplacement({
    ...context(),
    videoId: VIDEO_ID,
    captionId: CAPTION_ID,
    isDraft: false,
    contentType: "application/x-subrip",
    contentLength: 4096,
  });

  const insert = transport.requests[1]!;
  const update = transport.requests[4]!;
  assert.equal(insert.method, "POST");
  assert.equal(update.method, "PUT");
  assert.equal(new URL(insert.url).pathname, "/upload/youtube/v3/captions");
  assert.equal(new URL(update.url).pathname, "/upload/youtube/v3/captions");
  const insertMetadata = JSON.parse(insert.body ?? "{}") as {
    snippet?: { videoId?: string; language?: string; isDraft?: boolean };
  };
  assert.deepEqual(insertMetadata.snippet, {
    videoId: VIDEO_ID,
    language: "en",
    name: "English",
    isDraft: true,
  });
  const updateMetadata = JSON.parse(update.body ?? "{}") as {
    id?: string;
    snippet?: { isDraft?: boolean };
  };
  assert.deepEqual(updateMetadata, {
    id: CAPTION_ID,
    snippet: { isDraft: false },
  });
});

test("caption draft update and delete preflight the selected owner caption", async () => {
  const { assets, transport } = client([
    response({ items: [apiVideo()] }),
    response({ items: [apiCaption()] }),
    response(apiCaption(CAPTION_ID, VIDEO_ID, false)),
    response({ items: [apiVideo()] }),
    response({ items: [apiCaption(CAPTION_ID, VIDEO_ID, false)] }),
    response("", 204),
  ]);

  const updated = await assets.updateCaptionDraft({
    ...context(),
    videoId: VIDEO_ID,
    captionId: CAPTION_ID,
    isDraft: false,
  });
  assert.equal(updated.isDraft, false);
  const deleted = await assets.deleteCaption({
    ...context(),
    videoId: VIDEO_ID,
    captionId: CAPTION_ID,
  });
  assert.deepEqual(deleted, { deleted: true, captionId: CAPTION_ID });
  assert.equal(transport.requests[2]?.method, "PUT");
  assert.equal(transport.requests[5]?.method, "DELETE");
});

test("channel branding preserves existing writable fields and rejects hidden fields", async () => {
  const original = {
    id: ACTOR_CHANNEL,
    brandingSettings: {
      channel: {
        country: "IN",
        description: "Existing",
        defaultLanguage: "en",
        keywords: "market",
        trackingAnalyticsAccountId: "tracking_1",
      },
    },
  };
  const { assets, transport } = client([
    response({ items: [original] }),
    response({
      id: ACTOR_CHANNEL,
      brandingSettings: {
        channel: { ...original.brandingSettings.channel, description: "New" },
      },
    }),
  ]);
  const result = await assets.updateChannelBranding({
    ...context(),
    patch: { description: "New", country: null },
  });
  assert.equal(result.branding.description, "New");
  assert.equal(result.branding.country, "");
  assert.equal(result.branding.keywords, "market");
  const update = JSON.parse(transport.requests[1]?.body ?? "{}") as {
    brandingSettings?: { channel?: Record<string, string> };
  };
  assert.deepEqual(update.brandingSettings?.channel, result.branding);

  await assert.rejects(
    assets.updateChannelBranding({
      ...context(),
      patch: { hiddenField: "forbidden" } as never,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "bad_request",
  );
});

test("channel sections validate placement, ownership and nested resources", async () => {
  const { assets, transport } = client([
    response(apiSection("new_section_123")),
    response({ items: [apiSection()] }),
    response(apiSection()),
    response({ items: [apiSection()] }),
    response("", 204),
  ]);

  const inserted = await assets.insertChannelSection({
    ...context(),
    section: {
      type: "multiplePlaylists",
      title: "Founder picks",
      position: 0,
      playlistIds: [PLAYLIST_ID],
    },
  });
  assert.equal(inserted.sectionId, "new_section_123");
  const updated = await assets.updateChannelSection({
    ...context(),
    sectionId: SECTION_ID,
    section: {
      type: "multiplePlaylists",
      title: "Founder picks",
      position: 0,
      playlistIds: [PLAYLIST_ID],
    },
  });
  assert.equal(updated.sectionId, SECTION_ID);
  assert.deepEqual(
    await assets.deleteChannelSection({
      ...context(),
      sectionId: SECTION_ID,
    }),
    { deleted: true, sectionId: SECTION_ID },
  );
  assert.equal(transport.requests[0]?.method, "POST");
  assert.equal(transport.requests[2]?.method, "PUT");
  assert.equal(transport.requests[4]?.method, "DELETE");

  await assert.rejects(
    assets.insertChannelSection({
      ...context(),
      section: {
        type: "multipleChannels",
        title: "Channels",
        position: 0,
        channelIds: [ACTOR_CHANNEL],
      },
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "bad_request",
  );
});

test("banner and watermark operations enforce media geometry and never proxy bytes", async () => {
  const { assets, transport } = client([
    response("", 200, uploadLocation("channelBanners/insert")),
    response({ items: [{ id: ACTOR_CHANNEL, brandingSettings: {} }] }),
    response({ id: ACTOR_CHANNEL }),
    response("", 200, uploadLocation("watermarks/set")),
    response("", 204),
  ]);

  await assets.beginChannelBannerInsert({
    ...context(),
    contentType: "image/jpeg",
    contentLength: 1024,
    width: 2560,
    height: 1440,
  });
  await assets.applyChannelBanner({
    ...context(),
    bannerExternalUrl:
      "https://yt3.googleusercontent.com/channel-banner-token",
  });
  await assets.beginWatermarkSet({
    ...context(),
    contentType: "image/png",
    contentLength: 512,
    width: 150,
    height: 150,
    offsetMs: 0,
    durationMs: 10_000,
    offsetFrom: "start",
    corner: "bottomRight",
  });
  await assets.unsetWatermark(context());

  assert.equal(transport.requests[0]?.body, undefined);
  const watermarkMetadata = JSON.parse(
    transport.requests[3]?.body ?? "{}",
  ) as {
    targetChannelId?: string;
    timing?: { type?: string; offsetMs?: number; durationMs?: number };
    position?: { cornerPosition?: string };
  };
  assert.deepEqual(watermarkMetadata, {
    targetChannelId: ACTOR_CHANNEL,
    timing: {
      type: "offsetFromStart",
      offsetMs: 0,
      durationMs: 10_000,
    },
    position: { type: "corner", cornerPosition: "bottomRight" },
  });
  assert.equal(transport.requests[4]?.method, "POST");
});

test("playlist images use owner preflights and direct insert/update sessions", async () => {
  const { assets, transport } = client([
    response({ items: [apiPlaylist()] }),
    response("", 200, uploadLocation("playlistImages")),
    response({ items: [apiPlaylist()] }),
    response({ items: [apiPlaylistImage()] }),
    response("", 200, uploadLocation("playlistImages")),
    response({ items: [apiPlaylist()] }),
    response({ items: [apiPlaylistImage()] }),
    response("", 204),
  ]);

  await assets.beginPlaylistImageInsert({
    ...context(),
    playlistId: PLAYLIST_ID,
    contentType: "image/png",
    contentLength: 1024,
    width: 1200,
    height: 1200,
  });
  await assets.beginPlaylistImageUpdate({
    ...context(),
    playlistId: PLAYLIST_ID,
    playlistImageId: PLAYLIST_IMAGE_ID,
    contentType: "image/jpeg",
    contentLength: 2048,
    width: 1200,
    height: 1200,
  });
  await assets.deletePlaylistImage({
    ...context(),
    playlistId: PLAYLIST_ID,
    playlistImageId: PLAYLIST_IMAGE_ID,
  });

  assert.equal(transport.requests[1]?.method, "POST");
  assert.equal(transport.requests[4]?.method, "PUT");
  assert.equal(transport.requests[7]?.method, "DELETE");
});

test("playlist image list enforces playlist ownership, paging and provider image safety", async () => {
  const { assets, transport } = client([
    response({ items: [apiPlaylist()] }),
    response({
      items: [apiPlaylistImage()],
      nextPageToken: "next_page",
    }),
  ]);
  const result = await assets.listPlaylistImages({
    ...context(),
    playlistId: PLAYLIST_ID,
    maxResults: 10,
  });
  assert.equal(result.items[0]?.playlistImageId, PLAYLIST_IMAGE_ID);
  assert.equal(result.nextPageToken, "next_page");
  assert.equal(
    new URL(transport.requests[1]!.url).searchParams.get("maxResults"),
    "10",
  );
});

test("abuse reporting requires explicit video and reason confirmation", async () => {
  const reasons = {
    items: [
      {
        id: "spam",
        snippet: {
          label: "Spam",
          secondaryReasons: [
            { id: "commercial", label: "Commercial spam" },
          ],
        },
      },
    ],
  };
  const { assets, transport, quota } = client([
    response(reasons),
    response("", 204),
  ]);

  const result = await assets.reportVideoAbuse({
    ...context(),
    videoId: PUBLIC_VIDEO_ID,
    reasonId: "spam",
    secondaryReasonId: "commercial",
    comments: "Repeated deceptive links",
    language: "en",
    confirmVideoId: PUBLIC_VIDEO_ID,
    confirmReasonId: "spam",
  });
  assert.deepEqual(result, {
    reported: true,
    videoId: PUBLIC_VIDEO_ID,
    reasonId: "spam",
  });
  const report = JSON.parse(transport.requests[1]?.body ?? "{}") as {
    videoId?: string;
    reasonId?: string;
    secondaryReasonId?: string;
  };
  assert.deepEqual(report, {
    videoId: PUBLIC_VIDEO_ID,
    reasonId: "spam",
    secondaryReasonId: "commercial",
    comments: "Repeated deceptive links",
    language: "en",
  });
  assert.deepEqual(
    quota.reservations.map(({ operation, amount }) => ({
      operation,
      amount,
    })),
    [
      { operation: "videoAbuseReportReasons.list.owner", amount: 1 },
      { operation: "videos.reportAbuse.owner", amount: 50 },
    ],
  );

  await assert.rejects(
    assets.reportVideoAbuse({
      ...context(),
      videoId: PUBLIC_VIDEO_ID,
      reasonId: "spam",
      confirmVideoId: VIDEO_ID,
      confirmReasonId: "spam",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "bad_request",
  );
  assert.equal(transport.requests.length, 2);
});

test("abuse reports reject secondary reasons outside the confirmed parent", async () => {
  const { assets, transport } = client([
    response({
      items: [
        {
          id: "spam",
          snippet: {
            label: "Spam",
            secondaryReasons: [{ id: "commercial", label: "Commercial" }],
          },
        },
      ],
    }),
  ]);
  await assert.rejects(
    assets.reportVideoAbuse({
      ...context(),
      videoId: PUBLIC_VIDEO_ID,
      reasonId: "spam",
      secondaryReasonId: "violence",
      confirmVideoId: PUBLIC_VIDEO_ID,
      confirmReasonId: "spam",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "bad_request",
  );
  assert.equal(transport.requests.length, 1);
});

test("general abuse reports are distinct, confirmed and bounded", async () => {
  const { assets, transport, quota } = client([response({})]);
  const result = await assets.insertAbuseReport({
    ...context(),
    subjectTypeId: "youtube.channel",
    subjectId: ACTOR_CHANNEL,
    abuseTypeIds: ["spam", "impersonation"],
    description: "Repeated deceptive impersonation.",
    relatedEntities: [
      { typeId: "youtube.video", id: PUBLIC_VIDEO_ID },
    ],
    confirmSubjectTypeId: "youtube.channel",
    confirmSubjectId: ACTOR_CHANNEL,
    confirmAbuseTypeIds: ["spam", "impersonation"],
  });

  assert.deepEqual(result, {
    submitted: true,
    subjectTypeId: "youtube.channel",
    subjectId: ACTOR_CHANNEL,
    abuseTypeIds: ["spam", "impersonation"],
  });
  const request = transport.requests[0]!;
  const url = new URL(request.url);
  assert.equal(url.pathname, "/youtube/v3/abuseReports");
  assert.equal(
    url.searchParams.get("part"),
    "abuseTypes,subject,description,relatedEntities",
  );
  assert.deepEqual(JSON.parse(request.body ?? "{}"), {
    subject: { typeId: "youtube.channel", id: ACTOR_CHANNEL },
    abuseTypes: [{ id: "spam" }, { id: "impersonation" }],
    description: "Repeated deceptive impersonation.",
    relatedEntities: [
      {
        entity: {
          typeId: "youtube.video",
          id: PUBLIC_VIDEO_ID,
        },
      },
    ],
  });
  assert.deepEqual(
    quota.reservations.map(({ operation, amount }) => ({
      operation,
      amount,
    })),
    [{ operation: "abuseReports.insert.owner", amount: 50 }],
  );

  await assert.rejects(
    assets.insertAbuseReport({
      ...context(),
      subjectTypeId: "youtube.channel",
      subjectId: ACTOR_CHANNEL,
      abuseTypeIds: ["spam"],
      confirmSubjectTypeId: "youtube.channel",
      confirmSubjectId: OTHER_CHANNEL,
      confirmAbuseTypeIds: ["spam"],
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "bad_request",
  );
  assert.equal(transport.requests.length, 1);
});

test("owner preflights reject cross-channel assets before mutation", async () => {
  const video = client([
    response({ items: [apiVideo(VIDEO_ID, "private", OTHER_CHANNEL)] }),
  ]);
  await assert.rejects(
    video.assets.beginThumbnailSet({
      ...context(),
      videoId: VIDEO_ID,
      contentType: "image/png",
      contentLength: 1,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "permission_denied",
  );

  const section = client([
    response({ items: [apiSection(SECTION_ID, OTHER_CHANNEL)] }),
  ]);
  await assert.rejects(
    section.assets.deleteChannelSection({
      ...context(),
      sectionId: SECTION_ID,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "permission_denied",
  );
});
