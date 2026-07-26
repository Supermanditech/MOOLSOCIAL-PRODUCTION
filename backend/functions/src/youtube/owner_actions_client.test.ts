import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "./errors.js";
import { YouTubeOwnerClient } from "./owner_client.js";
import type { QuotaReservation, YouTubeQuotaPort } from "./ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";

const ACTOR_CHANNEL = "UCActorChannel123456789012";
const OTHER_CHANNEL = "UCOtherChannel123456789012";
const VIDEO_ID = "abc123DEF45";
const PLAYLIST_ID = "PL_owner_playlist_123";
const PLAYLIST_ITEM_ID = "PLI_owner_item_123";
const COMMENT_ID = "comment_owner_123";

class QueueTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(private readonly responses: HttpTransportResponse[]) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    const response = this.responses.shift();
    assert.ok(response, `Unexpected request: ${request.method ?? "GET"} ${request.url}`);
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
): HttpTransportResponse {
  return {
    status,
    headers: {},
    body: typeof body === "string" ? body : JSON.stringify(body),
  };
}

function context() {
  return {
    principal: "founder-user",
    requestId: "request-owner-action",
    accessToken: "short-lived-access-token",
    expectedChannelId: ACTOR_CHANNEL,
  } as const;
}

function apiComment(
  authorChannelId = ACTOR_CHANNEL,
  associatedChannelId = OTHER_CHANNEL,
  id = COMMENT_ID,
) {
  return {
    id,
    snippet: {
      textDisplay: "A useful response",
      textOriginal: "A useful response",
      authorDisplayName: "MoolSocial Founder",
      authorChannelId: { value: authorChannelId },
      channelId: associatedChannelId,
      videoId: VIDEO_ID,
      likeCount: 0,
      publishedAt: "2026-07-25T01:00:00Z",
      updatedAt: "2026-07-25T01:00:00Z",
    },
  };
}

function apiPlaylist(id = PLAYLIST_ID) {
  return {
    id,
    snippet: {
      title: "Founder picks",
      description: "Useful videos",
      channelId: ACTOR_CHANNEL,
    },
    status: { privacyStatus: "private" },
  };
}

function apiPlaylistItem(position = 0) {
  return {
    id: PLAYLIST_ITEM_ID,
    snippet: {
      playlistId: PLAYLIST_ID,
      position,
      resourceId: { videoId: VIDEO_ID },
    },
    contentDetails: { videoId: VIDEO_ID },
  };
}

function apiOwnedVideo(privacyStatus: "private" | "public") {
  return {
    id: VIDEO_ID,
    snippet: {
      title: "Private trial video",
      description: "Private Dev",
      channelId: ACTOR_CHANNEL,
      channelTitle: "MoolSocial Dev",
      publishedAt: "2026-07-25T01:00:00Z",
      categoryId: "22",
      thumbnails: {
        high: {
          url: "https://i.ytimg.com/vi/abc123DEF45/hqdefault.jpg",
          width: 480,
          height: 360,
        },
      },
    },
    status: {
      privacyStatus,
      uploadStatus: "processed",
      embeddable: true,
    },
  };
}

test("rating operations use the official endpoints and declared quota costs", async () => {
  const transport = new QueueTransport([
    response({ items: [{ videoId: VIDEO_ID, rating: "like" }] }),
    response("", 204),
    response("", 204),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeOwnerClient({ transport, quota });

  assert.deepEqual(
    await client.ownerGetRating({ ...context(), videoId: VIDEO_ID }),
    { videoId: VIDEO_ID, rating: "like" },
  );
  await client.ownerSetRating({
    ...context(),
    videoId: VIDEO_ID,
    rating: "dislike",
  });
  await client.ownerRemoveRating({ ...context(), videoId: VIDEO_ID });

  const urls = transport.requests.map((request) => new URL(request.url));
  assert.equal(urls[0]!.pathname, "/youtube/v3/videos/getRating");
  assert.equal(urls[0]!.searchParams.get("id"), VIDEO_ID);
  assert.equal(urls[1]!.pathname, "/youtube/v3/videos/rate");
  assert.equal(urls[1]!.searchParams.get("rating"), "dislike");
  assert.equal(urls[2]!.searchParams.get("rating"), "none");
  assert.deepEqual(
    quota.reservations.map(({ operation, amount }) => ({ operation, amount })),
    [
      { operation: "videos.getRating.owner", amount: 1 },
      { operation: "videos.rate.owner", amount: 50 },
      { operation: "videos.rate.remove.owner", amount: 50 },
    ],
  );
});

test("comment create, reply, update and moderation bind results to the connected actor", async () => {
  const reply = {
    ...apiComment(ACTOR_CHANNEL, OTHER_CHANNEL, "reply_owner_123"),
    snippet: {
      ...apiComment(ACTOR_CHANNEL, OTHER_CHANNEL).snippet,
      parentId: COMMENT_ID,
    },
  };
  const moderated = apiComment(OTHER_CHANNEL, ACTOR_CHANNEL);
  const transport = new QueueTransport([
    response({
      id: "thread_owner_123",
      snippet: {
        videoId: VIDEO_ID,
        channelId: OTHER_CHANNEL,
        topLevelComment: apiComment(),
      },
    }),
    response(reply),
    response({ items: [apiComment()] }),
    response(apiComment()),
    response({ items: [moderated] }),
    response("", 204),
  ]);
  const quota = new RecordingQuota();
  const client = new YouTubeOwnerClient({ transport, quota });

  const created = await client.ownerCreateComment({
    ...context(),
    videoId: VIDEO_ID,
    text: "A useful response",
  });
  assert.equal(created.threadId, "thread_owner_123");
  assert.equal(created.comment.author.channelId, ACTOR_CHANNEL);

  const createdReply = await client.ownerCreateReply({
    ...context(),
    parentCommentId: COMMENT_ID,
    text: "A useful response",
  });
  assert.equal(createdReply.comment.parentId, COMMENT_ID);

  const updated = await client.ownerUpdateComment({
    ...context(),
    commentId: COMMENT_ID,
    text: "A useful response",
  });
  assert.equal(updated.comment.commentId, COMMENT_ID);

  const moderation = await client.ownerSetCommentModeration({
    ...context(),
    commentId: COMMENT_ID,
    moderationStatus: "rejected",
    banAuthor: true,
  });
  assert.deepEqual(moderation, {
    commentId: COMMENT_ID,
    moderationStatus: "rejected",
    authorBanned: true,
  });

  const moderationUrl = new URL(transport.requests.at(-1)!.url);
  assert.equal(
    moderationUrl.pathname,
    "/youtube/v3/comments/setModerationStatus",
  );
  assert.equal(moderationUrl.searchParams.get("banAuthor"), "true");
  assert.equal(
    transport.requests[0]!.body,
    JSON.stringify({
      snippet: {
        videoId: VIDEO_ID,
        topLevelComment: {
          snippet: { textOriginal: "A useful response" },
        },
      },
    }),
  );
});

test("comment update and delete fail closed before mutation when author ownership differs", async () => {
  for (const action of ["update", "delete"] as const) {
    const transport = new QueueTransport([
      response({ items: [apiComment(OTHER_CHANNEL)] }),
    ]);
    const client = new YouTubeOwnerClient({
      transport,
      quota: new RecordingQuota(),
    });
    await assert.rejects(
      action === "update"
        ? client.ownerUpdateComment({
            ...context(),
            commentId: COMMENT_ID,
            text: "Not permitted",
          })
        : client.ownerDeleteComment({
            ...context(),
            commentId: COMMENT_ID,
          }),
      (error: unknown) =>
        error instanceof YouTubeProviderError &&
        error.code === "permission_denied",
    );
    assert.equal(transport.requests.length, 1);
  }
});

test("subscription create and delete bind the mutation to the connected channel", async () => {
  const subscriptionId = "subscription_owner_123";
  const transport = new QueueTransport([
    response({
      id: subscriptionId,
      snippet: {
        channelId: ACTOR_CHANNEL,
        resourceId: { channelId: OTHER_CHANNEL },
      },
    }),
    response({
      items: [
        {
          id: subscriptionId,
          snippet: {
            channelId: ACTOR_CHANNEL,
            resourceId: { channelId: OTHER_CHANNEL },
          },
        },
      ],
    }),
    response("", 204),
  ]);
  const client = new YouTubeOwnerClient({
    transport,
    quota: new RecordingQuota(),
  });
  assert.deepEqual(
    await client.ownerSubscribe({
      ...context(),
      channelId: OTHER_CHANNEL,
    }),
    {
      subscriptionId,
      actorChannelId: ACTOR_CHANNEL,
      targetChannelId: OTHER_CHANNEL,
    },
  );
  assert.deepEqual(
    await client.ownerUnsubscribe({
      ...context(),
      subscriptionId,
    }),
    { deleted: true, subscriptionId },
  );
  assert.equal(transport.requests[0]!.method, "POST");
  assert.equal(transport.requests[2]!.method, "DELETE");
});

test("playlist and playlist-item mutations preflight ownership and preserve exact ordering", async () => {
  const transport = new QueueTransport([
    response(apiPlaylist()),
    response({ items: [apiPlaylist()] }),
    response(apiPlaylist()),
    response({ items: [apiPlaylist()] }),
    response(apiPlaylistItem()),
    response({ items: [apiPlaylistItem()] }),
    response({ items: [apiPlaylist()] }),
    response(apiPlaylistItem(3)),
    response({ items: [apiPlaylistItem(3)] }),
    response({ items: [apiPlaylist()] }),
    response("", 204),
    response({ items: [apiPlaylist()] }),
    response("", 204),
  ]);
  const client = new YouTubeOwnerClient({
    transport,
    quota: new RecordingQuota(),
  });

  const created = await client.ownerCreatePlaylist({
    ...context(),
    title: "Founder picks",
    description: "Useful videos",
    privacyStatus: "private",
  });
  assert.equal(created.actorChannelId, ACTOR_CHANNEL);
  await client.ownerUpdatePlaylist({
    ...context(),
    playlistId: PLAYLIST_ID,
    title: "Founder picks",
    description: "Useful videos",
    privacyStatus: "private",
  });
  await client.ownerCreatePlaylistItem({
    ...context(),
    playlistId: PLAYLIST_ID,
    videoId: VIDEO_ID,
  });
  const reordered = await client.ownerReorderPlaylistItem({
    ...context(),
    playlistItemId: PLAYLIST_ITEM_ID,
    position: 3,
  });
  assert.equal(reordered.position, 3);
  await client.ownerDeletePlaylistItem({
    ...context(),
    playlistItemId: PLAYLIST_ITEM_ID,
  });
  await client.ownerDeletePlaylist({
    ...context(),
    playlistId: PLAYLIST_ID,
  });

  const reorderRequest = transport.requests[7]!;
  assert.equal(reorderRequest.method, "PUT");
  assert.deepEqual(JSON.parse(reorderRequest.body!), {
    id: PLAYLIST_ITEM_ID,
    snippet: {
      playlistId: PLAYLIST_ID,
      position: 3,
      resourceId: { kind: "youtube#video", videoId: VIDEO_ID },
    },
  });
});

test("playlist mutation rejects a provider resource owned by another channel", async () => {
  const transport = new QueueTransport([
    response({
      items: [
        {
          ...apiPlaylist(),
          snippet: {
            ...apiPlaylist().snippet,
            channelId: OTHER_CHANNEL,
          },
        },
      ],
    }),
  ]);
  const client = new YouTubeOwnerClient({
    transport,
    quota: new RecordingQuota(),
  });
  await assert.rejects(
    client.ownerDeletePlaylist({
      ...context(),
      playlistId: PLAYLIST_ID,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "permission_denied",
  );
  assert.equal(transport.requests.length, 1);
});

test("video metadata update is private-only and deletion requires exact confirmation", async () => {
  const transport = new QueueTransport([
    response({ items: [apiOwnedVideo("private")] }),
    response({
      id: VIDEO_ID,
      snippet: {
        title: "Updated private video",
        description: "Still private",
        categoryId: "22",
        channelId: ACTOR_CHANNEL,
      },
    }),
    response({ items: [apiOwnedVideo("private")] }),
    response("", 204),
  ]);
  const client = new YouTubeOwnerClient({
    transport,
    quota: new RecordingQuota(),
  });
  const updated = await client.ownerUpdateVideoMetadata({
    ...context(),
    videoId: VIDEO_ID,
    title: "Updated private video",
    description: "Still private",
    categoryId: "22",
    tags: ["moolsocial", "private-dev"],
  });
  assert.equal(updated.privacyStatus, "private");
  assert.deepEqual(
    await client.ownerDeleteVideo({
      ...context(),
      videoId: VIDEO_ID,
      confirmVideoId: VIDEO_ID,
    }),
    { deleted: true, videoId: VIDEO_ID },
  );
  assert.equal(transport.requests.at(-1)!.method, "DELETE");
});

test("public videos and wrong confirmation never reach a destructive mutation", async () => {
  const wrongConfirmation = new QueueTransport([]);
  const client = new YouTubeOwnerClient({
    transport: wrongConfirmation,
    quota: new RecordingQuota(),
  });
  await assert.rejects(
    client.ownerDeleteVideo({
      ...context(),
      videoId: VIDEO_ID,
      confirmVideoId: "differentVideo",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "bad_request",
  );
  assert.equal(wrongConfirmation.requests.length, 0);

  const publicVideo = new QueueTransport([
    response({ items: [apiOwnedVideo("public")] }),
  ]);
  const publicClient = new YouTubeOwnerClient({
    transport: publicVideo,
    quota: new RecordingQuota(),
  });
  await assert.rejects(
    publicClient.ownerDeleteVideo({
      ...context(),
      videoId: VIDEO_ID,
      confirmVideoId: VIDEO_ID,
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "permission_denied",
  );
  assert.equal(publicVideo.requests.length, 1);
});
