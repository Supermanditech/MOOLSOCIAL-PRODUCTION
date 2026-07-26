import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "./errors.js";
import { YouTubeLiveClient } from "./live_client.js";
import type { QuotaReservation, YouTubeQuotaPort } from "./ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "./types.js";

const OWNER = "UCActorChannel123456789012";
const OTHER = "UCOtherChannel123456789012";
const BROADCAST = "broadcast_owner_123";
const STREAM = "stream_owner_123";
const CHAT = "chat_owner_123";
const MESSAGE = "message_owner_123";
const MODERATOR = "moderator_owner_123";
const MODERATOR_CHANNEL = "UCModerator12345678901234";
const BANNED_CHANNEL = "UCBannedUser1234567890123";

class QueueTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(private readonly responses: HttpTransportResponse[]) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    const next = this.responses.shift();
    assert.ok(
      next,
      `Unexpected request: ${request.method ?? "GET"} ${request.url}`,
    );
    return next;
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
    requestId: "request-live-proof",
    accessToken: "short-lived-access-token",
    expectedChannelId: OWNER,
  } as const;
}

function broadcast(
  input: {
    readonly id?: string;
    readonly owner?: string;
    readonly privacy?: "private" | "public" | "unlisted";
    readonly lifecycle?:
      | "created"
      | "ready"
      | "testing"
      | "live"
      | "complete";
    readonly liveChatId?: string;
    readonly boundStreamId?: string;
  } = {},
) {
  return {
    id: input.id ?? BROADCAST,
    snippet: {
      channelId: input.owner ?? OWNER,
      title: "Private launch",
      description: "Founder-supervised live proof",
      scheduledStartTime: "2026-07-26T10:00:00Z",
      scheduledEndTime: "2026-07-26T11:00:00Z",
      liveChatId: input.liveChatId ?? CHAT,
    },
    status: {
      lifeCycleStatus: input.lifecycle ?? "ready",
      privacyStatus: input.privacy ?? "private",
      recordingStatus: "notRecording",
      madeForKids: false,
      selfDeclaredMadeForKids: false,
    },
    contentDetails: {
      boundStreamId: input.boundStreamId,
      enableEmbed: true,
      enableDvr: true,
      recordFromStart: true,
      enableAutoStart: false,
      enableAutoStop: false,
      latencyPreference: "low",
    },
  };
}

function stream(
  input: {
    readonly id?: string;
    readonly owner?: string;
    readonly status?: "created" | "ready" | "active" | "inactive" | "error";
    readonly ingestionAddress?: string;
  } = {},
) {
  return {
    id: input.id ?? STREAM,
    snippet: {
      channelId: input.owner ?? OWNER,
      title: "Founder encoder",
      description: "Private reusable stream",
    },
    status: { streamStatus: input.status ?? "ready" },
    cdn: {
      resolution: "1080p",
      frameRate: "30fps",
      ingestionType: "rtmp",
      ingestionInfo: {
        ingestionAddress:
          input.ingestionAddress ??
          "rtmps://a.rtmps.youtube.com/live2",
        backupIngestionAddress:
          "rtmps://b.rtmps.youtube.com/live2?backup=1",
        rtmpsIngestionAddress:
          "rtmps://a.rtmps.youtube.com/live2",
        rtmpsBackupIngestionAddress:
          "rtmps://b.rtmps.youtube.com/live2?backup=1",
        streamName: "private-stream-key",
      },
    },
    contentDetails: { isReusable: true },
  };
}

function textMessage(
  input: {
    readonly id?: string;
    readonly liveChatId?: string;
    readonly type?: "textMessageEvent" | "pollEvent";
    readonly pollStatus?: "active" | "closed";
  } = {},
) {
  const type = input.type ?? "textMessageEvent";
  return {
    id: input.id ?? MESSAGE,
    snippet: {
      liveChatId: input.liveChatId ?? CHAT,
      type,
      publishedAt: "2026-07-25T10:00:00Z",
      displayMessage:
        type === "pollEvent" ? "Which session next?" : "Welcome",
      ...(type === "textMessageEvent"
        ? { textMessageDetails: { messageText: "Welcome" } }
        : {
            pollDetails: {
              status: input.pollStatus ?? "active",
              metadata: {
                questionText: "Which session next?",
                options: [
                  { optionText: "Products", tally: "4" },
                  { optionText: "Services", tally: "2" },
                ],
              },
            },
          }),
    },
    authorDetails: {
      channelId: OWNER,
      displayName: "MoolSocial",
      profileImageUrl:
        "https://yt3.ggpht.com/a/approved-profile=s88-c-k-c0x00ffffff-no-rj",
      isVerified: true,
      isChatOwner: true,
      isChatSponsor: false,
      isChatModerator: false,
    },
  };
}

function client(responses: HttpTransportResponse[]) {
  const transport = new QueueTransport(responses);
  const quota = new RecordingQuota();
  return {
    transport,
    quota,
    live: new YouTubeLiveClient({
      transport,
      quota,
      clock: { now: () => new Date("2026-07-25T00:00:00Z") },
    }),
  };
}

function errorCode(code: string) {
  return (error: unknown) =>
    error instanceof YouTubeProviderError && error.code === code;
}

test("lists only owner broadcasts with bounded pagination and quota", async () => {
  const { live, transport, quota } = client([
    response({
      items: [broadcast()],
      nextPageToken: "next_page_123",
    }),
  ]);

  const page = await live.listBroadcasts({
    ...context(),
    status: "upcoming",
    maxResults: 50,
    pageToken: "page_123",
  });

  assert.equal(page.items[0]?.broadcastId, BROADCAST);
  assert.equal(page.items[0]?.privacyStatus, "private");
  assert.equal(page.nextPageToken, "next_page_123");
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/youtube/v3/liveBroadcasts");
  assert.equal(url.searchParams.get("mine"), "true");
  assert.equal(url.searchParams.get("broadcastStatus"), "upcoming");
  assert.equal(url.searchParams.get("maxResults"), "50");
  assert.deepEqual(
    quota.reservations.map(({ operation, amount }) => ({
      operation,
      amount,
    })),
    [{ operation: "liveBroadcasts.list.owner", amount: 1 }],
  );
});

test("inserts only a private broadcast with an explicit audience declaration", async () => {
  const { live, transport } = client([response(broadcast())]);

  const result = await live.insertBroadcast({
    ...context(),
    title: "Private launch",
    description: "",
    scheduledStartTime: "2026-07-26T10:00:00Z",
    scheduledEndTime: "2026-07-26T11:00:00Z",
    selfDeclaredMadeForKids: false,
    enableEmbed: true,
    enableDvr: true,
    enableAutoStart: false,
    enableAutoStop: false,
    latencyPreference: "low",
  });

  assert.equal(result.broadcastId, BROADCAST);
  const request = transport.requests[0]!;
  assert.equal(request.method, "POST");
  const payload = JSON.parse(request.body ?? "{}") as {
    status?: {
      privacyStatus?: string;
      selfDeclaredMadeForKids?: boolean;
    };
    contentDetails?: {
      recordFromStart?: boolean;
      monitorStream?: { enableMonitorStream?: boolean };
    };
  };
  assert.equal(payload.status?.privacyStatus, "private");
  assert.equal(payload.status?.selfDeclaredMadeForKids, false);
  assert.equal(payload.contentDetails?.recordFromStart, true);
  assert.equal(
    payload.contentDetails?.monitorStream?.enableMonitorStream,
    false,
  );
});

test("blocks public broadcast mutations before a provider write", async () => {
  const { live, transport } = client([
    response({ items: [broadcast({ privacy: "public" })] }),
  ]);

  await assert.rejects(
    live.deleteBroadcast({
      ...context(),
      broadcastId: BROADCAST,
      confirmBroadcastId: BROADCAST,
    }),
    errorCode("permission_denied"),
  );
  assert.equal(transport.requests.length, 1);
  assert.equal(transport.requests[0]?.method ?? "GET", "GET");
});

test("bind and transition require owned resources and exact confirmations", async () => {
  const bound = broadcast({ boundStreamId: STREAM });
  const { live, transport } = client([
    response({ items: [broadcast()] }),
    response({ items: [stream()] }),
    response(bound),
  ]);

  const result = await live.bindBroadcast({
    ...context(),
    broadcastId: BROADCAST,
    streamId: STREAM,
    confirmBroadcastId: BROADCAST,
    confirmStreamId: STREAM,
  });
  assert.equal(result.boundStreamId, STREAM);
  assert.equal(
    new URL(transport.requests[2]!.url).pathname,
    "/youtube/v3/liveBroadcasts/bind",
  );

  const mismatch = client([
    response({ items: [bound] }),
  ]);
  await assert.rejects(
    mismatch.live.transitionBroadcast({
      ...context(),
      broadcastId: BROADCAST,
      targetStatus: "live",
      confirmBroadcastId: BROADCAST,
      confirmTargetStatus: "testing",
    }),
    errorCode("bad_request"),
  );
  assert.equal(mismatch.transport.requests.length, 1);
});

test("stream insert returns validated provider ingestion data and keeps the key explicit", async () => {
  const { live, transport } = client([response(stream())]);

  const result = await live.insertStream({
    ...context(),
    title: "Founder encoder",
    description: "",
    isReusable: true,
    resolution: "1080p",
    frameRate: "30fps",
    ingestionType: "rtmp",
  });

  assert.equal(result.streamName, "private-stream-key");
  assert.equal(
    result.ingestionAddress,
    "rtmps://a.rtmps.youtube.com/live2",
  );
  assert.equal(
    result.rtmpsBackupIngestionAddress,
    "rtmps://b.rtmps.youtube.com/live2?backup=1",
  );
  const payload = JSON.parse(transport.requests[0]!.body ?? "{}") as {
    cdn?: {
      resolution?: string;
      frameRate?: string;
      ingestionType?: string;
    };
  };
  assert.deepEqual(payload.cdn, {
    resolution: "1080p",
    frameRate: "30fps",
    ingestionType: "rtmp",
  });
});

test("rejects a non-provider ingestion endpoint", async () => {
  const { live } = client([
    response({
      items: [
        stream({
          ingestionAddress: "rtmps://attacker.example/live",
        }),
      ],
    }),
  ]);

  await assert.rejects(
    live.listStreams({ ...context() }),
    errorCode("provider_rejected"),
  );
});

test("lists live chat through the bounded REST fallback and maps the active poll", async () => {
  const poll = textMessage({ id: "poll_owner_123", type: "pollEvent" });
  const { live, transport } = client([
    response({ items: [broadcast()] }),
    response({
      items: [textMessage()],
      activePollItem: poll,
      nextPageToken: "chat_next_123",
      pollingIntervalMillis: 5_000,
    }),
  ]);

  const page = await live.listMessages({
    ...context(),
    broadcastId: BROADCAST,
    liveChatId: CHAT,
    maxResults: 200,
  });

  assert.equal(page.items[0]?.textMessage, "Welcome");
  assert.equal(page.activePoll?.poll?.status, "active");
  assert.equal(page.pollingIntervalMillis, 5_000);
  const chatUrl = new URL(transport.requests[1]!.url);
  assert.equal(chatUrl.pathname, "/youtube/v3/liveChat/messages");
  assert.equal(chatUrl.searchParams.get("maxResults"), "200");
  assert.equal(chatUrl.searchParams.get("profileImageSize"), "88");
  assert.equal(
    transport.requests.some((request) =>
      request.url.includes("streamList"),
    ),
    false,
  );
});

test("chat text and polls write only to a private owned chat", async () => {
  const textProof = client([
    response({ items: [broadcast()] }),
    response(textMessage()),
  ]);
  const textResult = await textProof.live.insertTextMessage({
    ...context(),
    broadcastId: BROADCAST,
    liveChatId: CHAT,
    messageText: "Welcome",
  });
  assert.equal(textResult.type, "textMessageEvent");
  assert.equal(textProof.transport.requests[1]?.method, "POST");

  const pollProof = client([
    response({ items: [broadcast()] }),
    response(textMessage({ id: "poll_owner_123", type: "pollEvent" })),
  ]);
  const pollResult = await pollProof.live.insertPoll({
    ...context(),
    broadcastId: BROADCAST,
    liveChatId: CHAT,
    questionText: "Which session next?",
    options: ["Products", "Services"],
  });
  assert.equal(pollResult.poll?.questionText, "Which session next?");
  const payload = JSON.parse(
    pollProof.transport.requests[1]!.body ?? "{}",
  ) as {
    snippet?: {
      type?: string;
      pollDetails?: {
        metadata?: { options?: readonly { optionText?: string }[] };
      };
    };
  };
  assert.equal(payload.snippet?.type, "pollEvent");
  assert.deepEqual(
    payload.snippet?.pollDetails?.metadata?.options,
    [{ optionText: "Products" }, { optionText: "Services" }],
  );
});

test("closing a poll uses the official transition method after exact owner and state checks", async () => {
  const activePoll = textMessage({
    id: "poll_owner_123",
    type: "pollEvent",
    pollStatus: "active",
  });
  const closedPoll = textMessage({
    id: "poll_owner_123",
    type: "pollEvent",
    pollStatus: "closed",
  });
  const { live, transport } = client([
    response({ items: [broadcast()] }),
    response({ items: [broadcast()] }),
    response({ items: [broadcast()] }),
    response({
      items: [activePoll],
      pollingIntervalMillis: 5_000,
    }),
    response(closedPoll),
  ]);

  const result = await live.closePoll({
    ...context(),
    broadcastId: BROADCAST,
    liveChatId: CHAT,
    pollMessageId: "poll_owner_123",
    confirmPollMessageId: "poll_owner_123",
    confirmStatus: "closed",
  });

  assert.equal(result.poll?.status, "closed");
  const transition = new URL(transport.requests[4]!.url);
  assert.equal(
    transition.pathname,
    "/youtube/v3/liveChat/messages/transition",
  );
  assert.equal(transition.searchParams.get("status"), "closed");
});

test("moderator and ban writes are owner-preflighted and confirmed", async () => {
  const moderatorResource = {
    id: MODERATOR,
    snippet: {
      liveChatId: CHAT,
      moderatorDetails: {
        channelId: MODERATOR_CHANNEL,
        displayName: "Moderator",
        profileImageUrl:
          "https://yt3.ggpht.com/a/moderator=s88-c-k-c0x00ffffff-no-rj",
      },
    },
  };
  const insertModerator = client([
    response({ items: [broadcast()] }),
    response(moderatorResource),
  ]);
  assert.equal(
    (
      await insertModerator.live.insertModerator({
        ...context(),
        broadcastId: BROADCAST,
        liveChatId: CHAT,
        moderatorChannelId: MODERATOR_CHANNEL,
      })
    ).moderatorId,
    MODERATOR,
  );

  const deleteModerator = client([
    response({ items: [broadcast()] }),
    response({ items: [broadcast()] }),
    response({ items: [moderatorResource] }),
    response(""),
  ]);
  assert.deepEqual(
    await deleteModerator.live.deleteModerator({
      ...context(),
      broadcastId: BROADCAST,
      liveChatId: CHAT,
      moderatorId: MODERATOR,
      confirmModeratorId: MODERATOR,
    }),
    { deletedModeratorId: MODERATOR },
  );

  const ban = {
    id: "ban_owner_123",
    snippet: {
      liveChatId: CHAT,
      type: "temporary",
      banDurationSeconds: "600",
      bannedUserDetails: {
        channelId: BANNED_CHANNEL,
        displayName: "Blocked user",
      },
    },
  };
  const insertBan = client([
    response({ items: [broadcast()] }),
    response(ban),
  ]);
  const inserted = await insertBan.live.insertBan({
    ...context(),
    broadcastId: BROADCAST,
    liveChatId: CHAT,
    bannedChannelId: BANNED_CHANNEL,
    type: "temporary",
    durationSeconds: 600,
  });
  assert.equal(inserted.banId, "ban_owner_123");
  assert.equal(inserted.durationSeconds, 600);

  const deleteBan = client([
    response({ items: [broadcast()] }),
    response(""),
  ]);
  assert.deepEqual(
    await deleteBan.live.deleteBan({
      ...context(),
      broadcastId: BROADCAST,
      liveChatId: CHAT,
      banId: "ban_owner_123",
      confirmBanId: "ban_owner_123",
    }),
    { deletedBanId: "ban_owner_123" },
  );
});

test("monetization reads carry explicit provider eligibility classifications", async () => {
  const superChat = client([
    response({
      items: [
        {
          id: "super_chat_123",
          snippet: {
            supporterDetails: {
              channelId: OTHER,
              displayName: "Supporter",
              profileImageUrl:
                "https://yt3.ggpht.com/a/supporter=s88-c-k-c0x00ffffff-no-rj",
            },
            createdAt: "2026-07-25T10:00:00Z",
            amountMicros: "1000000",
            currency: "INR",
            displayString: "₹1.00",
            commentText: "Great session",
            isSuperStickerEvent: false,
          },
        },
      ],
    }),
  ]);
  const events = await superChat.live.listSuperChatEvents({
    ...context(),
    language: "en-IN",
  });
  assert.equal(events.eligibility, "provider_approved_channel_only");
  assert.equal(events.items[0]?.currency, "INR");

  const members = client([
    response({
      items: [
        {
          snippet: {
            creatorChannelId: OWNER,
            memberDetails: {
              channelId: OTHER,
              displayName: "Member",
            },
            membershipsDetails: {
              highestAccessibleLevel: "level_123",
              highestAccessibleLevelDisplayName: "Supporter",
              accessibleLevels: ["level_123"],
            },
          },
        },
      ],
    }),
  ]);
  const membership = await members.live.listMembers({
    ...context(),
    mode: "all_current",
  });
  assert.equal(
    membership.eligibility,
    "youtube_representative_and_memberships_enabled_required",
  );

  const levels = client([
    response({
      items: [
        {
          id: "level_123",
          snippet: {
            creatorChannelId: OWNER,
            levelDetails: { displayName: "Supporter" },
          },
        },
      ],
    }),
  ]);
  const membershipLevels = await levels.live.listMembershipLevels(
    context(),
  );
  assert.equal(
    membershipLevels.eligibility,
    "youtube_representative_and_memberships_enabled_required",
  );
  assert.equal(membershipLevels.items[0]?.displayName, "Supporter");
});

test("owner attribution failures are rejected before data can cross channels", async () => {
  const { live } = client([
    response({ items: [broadcast({ owner: OTHER })] }),
  ]);

  await assert.rejects(
    live.listBroadcasts({ ...context(), status: "all" }),
    errorCode("permission_denied"),
  );
});
