import { assertProviderResponse, YouTubeProviderError } from "./errors.js";
import type { Clock, YouTubeQuotaPort } from "./ports.js";
import { systemClock } from "./ports.js";
import {
  safeYouTubeProviderImageUrl,
  safeYouTubeProviderPlainText,
} from "./provider_content.js";
import type { HttpTransport } from "./types.js";

const DATA_API = "https://www.googleapis.com/youtube/v3";
const RESOURCE_ID = /^[A-Za-z0-9_-]{1,256}$/u;
const CHANNEL_ID = /^[A-Za-z0-9_-]{6,64}$/u;
const PAGE_TOKEN = /^[A-Za-z0-9_-]{1,256}$/u;
const CURRENCY = /^[A-Z]{3}$/u;
const READ_QUOTA_COST = 1;
const WRITE_QUOTA_COST = 50;
const DEFAULT_PAGE_SIZE = 25;
const MAX_PAGE_SIZE = 50;
const MAX_CHAT_PAGE_SIZE = 200;

type BroadcastStatusFilter = "all" | "active" | "upcoming" | "completed";
type BroadcastTransition = "testing" | "live" | "complete";
type BroadcastLifecycle =
  | "created"
  | "ready"
  | "testing"
  | "live"
  | "complete"
  | "revoked"
  | "testStarting"
  | "liveStarting";
type StreamStatus = "created" | "ready" | "active" | "inactive" | "error";
type StreamResolution =
  | "240p"
  | "360p"
  | "480p"
  | "720p"
  | "1080p"
  | "1440p"
  | "2160p"
  | "variable";
type StreamFrameRate = "30fps" | "60fps" | "variable";
type StreamIngestionType = "rtmp" | "dash" | "webrtc" | "hls";
type LatencyPreference = "normal" | "low" | "ultraLow";
type LiveChatBanType = "permanent" | "temporary";

const BROADCAST_LIFECYCLES = new Set<BroadcastLifecycle>([
  "created",
  "ready",
  "testing",
  "live",
  "complete",
  "revoked",
  "testStarting",
  "liveStarting",
]);
const STREAM_STATUSES = new Set<StreamStatus>([
  "created",
  "ready",
  "active",
  "inactive",
  "error",
]);
const MESSAGE_TYPES = new Set([
  "textMessageEvent",
  "tombstone",
  "fanFundingEvent",
  "chatEndedEvent",
  "sponsorOnlyModeStartedEvent",
  "sponsorOnlyModeEndedEvent",
  "newSponsorEvent",
  "memberMilestoneChatEvent",
  "membershipGiftingEvent",
  "giftMembershipReceivedEvent",
  "messageDeletedEvent",
  "messageRetractedEvent",
  "userBannedEvent",
  "superChatEvent",
  "superStickerEvent",
  "pollEvent",
  "giftEvent",
]);

interface ListEnvelope<T> {
  readonly items?: readonly T[];
  readonly nextPageToken?: string;
  readonly pollingIntervalMillis?: number;
  readonly offlineAt?: string;
  readonly activePollItem?: ApiLiveChatMessage;
}

interface ApiThumbnail {
  readonly url?: string;
  readonly width?: number;
  readonly height?: number;
}

interface ApiLiveBroadcast {
  readonly id?: string;
  readonly snippet?: {
    readonly channelId?: string;
    readonly title?: string;
    readonly description?: string;
    readonly scheduledStartTime?: string;
    readonly scheduledEndTime?: string;
    readonly actualStartTime?: string;
    readonly actualEndTime?: string;
    readonly liveChatId?: string;
    readonly thumbnails?: Record<string, ApiThumbnail>;
  };
  readonly status?: {
    readonly lifeCycleStatus?: string;
    readonly privacyStatus?: string;
    readonly recordingStatus?: string;
    readonly madeForKids?: boolean;
    readonly selfDeclaredMadeForKids?: boolean;
  };
  readonly contentDetails?: {
    readonly boundStreamId?: string;
    readonly enableEmbed?: boolean;
    readonly enableDvr?: boolean;
    readonly recordFromStart?: boolean;
    readonly enableAutoStart?: boolean;
    readonly enableAutoStop?: boolean;
    readonly latencyPreference?: string;
  };
}

interface ApiLiveStream {
  readonly id?: string;
  readonly snippet?: {
    readonly channelId?: string;
    readonly title?: string;
    readonly description?: string;
  };
  readonly cdn?: {
    readonly resolution?: string;
    readonly frameRate?: string;
    readonly ingestionType?: string;
    readonly ingestionInfo?: {
      readonly ingestionAddress?: string;
      readonly backupIngestionAddress?: string;
      readonly rtmpsIngestionAddress?: string;
      readonly rtmpsBackupIngestionAddress?: string;
      readonly streamName?: string;
    };
  };
  readonly contentDetails?: { readonly isReusable?: boolean };
  readonly status?: { readonly streamStatus?: string };
}

interface ApiChannelProfile {
  readonly channelId?: string;
  readonly displayName?: string;
  readonly profileImageUrl?: string;
  readonly channelUrl?: string;
}

interface ApiLiveChatMessage {
  readonly id?: string;
  readonly snippet?: {
    readonly type?: string;
    readonly liveChatId?: string;
    readonly authorChannelId?: string;
    readonly publishedAt?: string;
    readonly displayMessage?: string;
    readonly textMessageDetails?: { readonly messageText?: string };
    readonly pollDetails?: {
      readonly status?: string;
      readonly metadata?: {
        readonly questionText?: string;
        readonly options?: readonly {
          readonly optionText?: string;
          readonly tally?: string;
        }[];
      };
    };
  };
  readonly authorDetails?: ApiChannelProfile & {
    readonly isVerified?: boolean;
    readonly isChatOwner?: boolean;
    readonly isChatSponsor?: boolean;
    readonly isChatModerator?: boolean;
  };
}

interface ApiLiveChatModerator {
  readonly id?: string;
  readonly snippet?: {
    readonly liveChatId?: string;
    readonly moderatorDetails?: ApiChannelProfile;
  };
}

interface ApiLiveChatBan {
  readonly id?: string;
  readonly snippet?: {
    readonly liveChatId?: string;
    readonly type?: string;
    readonly banDurationSeconds?: string;
    readonly bannedUserDetails?: ApiChannelProfile;
  };
}

interface ApiSuperChatEvent {
  readonly id?: string;
  readonly snippet?: {
    readonly channelId?: string;
    readonly createdAt?: string;
    readonly amountMicros?: string;
    readonly currency?: string;
    readonly displayString?: string;
    readonly commentText?: string;
    readonly isSuperStickerEvent?: boolean;
    readonly supporterDetails?: ApiChannelProfile;
  };
}

interface ApiMember {
  readonly snippet?: {
    readonly creatorChannelId?: string;
    readonly memberDetails?: ApiChannelProfile;
    readonly membershipsDetails?: {
      readonly highestAccessibleLevel?: string;
      readonly highestAccessibleLevelDisplayName?: string;
      readonly accessibleLevels?: readonly string[];
    };
  };
}

interface ApiMembershipLevel {
  readonly id?: string;
  readonly snippet?: {
    readonly creatorChannelId?: string;
    readonly levelDetails?: { readonly displayName?: string };
  };
}

export interface LiveOwnerRequest {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly expectedChannelId: string;
}

export interface LiveListRequest extends LiveOwnerRequest {
  readonly pageToken?: string;
  readonly maxResults?: number;
}

export interface LiveBroadcastListRequest extends LiveListRequest {
  readonly status: BroadcastStatusFilter;
}

export interface LiveBroadcastWrite {
  readonly title: string;
  readonly description: string;
  readonly scheduledStartTime: string;
  readonly scheduledEndTime: string;
  readonly selfDeclaredMadeForKids: boolean;
  readonly enableEmbed: boolean;
  readonly enableDvr: boolean;
  readonly enableAutoStart: boolean;
  readonly enableAutoStop: boolean;
  readonly latencyPreference: LatencyPreference;
}

export interface LiveBroadcastInsertRequest
  extends LiveOwnerRequest,
    LiveBroadcastWrite {}

export interface LiveBroadcastUpdateRequest
  extends LiveOwnerRequest,
    LiveBroadcastWrite {
  readonly broadcastId: string;
}

export interface LiveBroadcastBindRequest extends LiveOwnerRequest {
  readonly broadcastId: string;
  readonly streamId: string;
  readonly confirmBroadcastId: string;
  readonly confirmStreamId: string;
}

export interface LiveBroadcastTransitionRequest extends LiveOwnerRequest {
  readonly broadcastId: string;
  readonly targetStatus: BroadcastTransition;
  readonly confirmBroadcastId: string;
  readonly confirmTargetStatus: BroadcastTransition;
}

export interface LiveBroadcastDeleteRequest extends LiveOwnerRequest {
  readonly broadcastId: string;
  readonly confirmBroadcastId: string;
}

export interface LiveStreamWrite {
  readonly title: string;
  readonly description: string;
  readonly isReusable: boolean;
}

export interface LiveStreamInsertRequest
  extends LiveOwnerRequest,
    LiveStreamWrite {
  readonly resolution: StreamResolution;
  readonly frameRate: StreamFrameRate;
  readonly ingestionType: StreamIngestionType;
}

export interface LiveStreamUpdateRequest
  extends LiveOwnerRequest,
    LiveStreamWrite {
  readonly streamId: string;
}

export interface LiveStreamDeleteRequest extends LiveOwnerRequest {
  readonly streamId: string;
  readonly confirmStreamId: string;
}

export interface LiveChatRequest extends LiveOwnerRequest {
  readonly broadcastId: string;
  readonly liveChatId: string;
}

export interface LiveChatListRequest extends LiveChatRequest {
  readonly pageToken?: string;
  readonly maxResults?: number;
}

export interface LiveChatTextInsertRequest extends LiveChatRequest {
  readonly messageText: string;
}

export interface LiveChatPollInsertRequest extends LiveChatRequest {
  readonly questionText: string;
  readonly options: readonly string[];
}

export interface LiveChatMessageDeleteRequest extends LiveChatRequest {
  readonly messageId: string;
  readonly confirmMessageId: string;
}

export interface LiveChatPollCloseRequest extends LiveChatRequest {
  readonly pollMessageId: string;
  readonly confirmPollMessageId: string;
  readonly confirmStatus: "closed";
}

export interface LiveChatModeratorInsertRequest extends LiveChatRequest {
  readonly moderatorChannelId: string;
}

export interface LiveChatModeratorDeleteRequest extends LiveChatRequest {
  readonly moderatorId: string;
  readonly confirmModeratorId: string;
}

export interface LiveChatBanInsertRequest extends LiveChatRequest {
  readonly bannedChannelId: string;
  readonly type: LiveChatBanType;
  readonly durationSeconds?: number;
}

export interface LiveChatBanDeleteRequest extends LiveChatRequest {
  readonly banId: string;
  readonly confirmBanId: string;
}

export interface LiveSuperChatListRequest extends LiveListRequest {
  readonly language?: string;
}

export interface LiveMemberListRequest extends LiveListRequest {
  readonly mode: "all_current" | "updates";
  readonly memberChannelId?: string;
  readonly levelId?: string;
}

export interface YouTubeLiveBroadcast {
  readonly broadcastId: string;
  readonly channelId: string;
  readonly title: string;
  readonly description: string;
  readonly scheduledStartTime: string;
  readonly scheduledEndTime: string;
  readonly actualStartTime?: string;
  readonly actualEndTime?: string;
  readonly liveChatId?: string;
  readonly lifeCycleStatus: BroadcastLifecycle;
  readonly privacyStatus: "private" | "public" | "unlisted";
  readonly recordingStatus: "notRecording" | "recording" | "recorded";
  readonly madeForKids?: boolean;
  readonly selfDeclaredMadeForKids?: boolean;
  readonly boundStreamId?: string;
  readonly enableEmbed?: boolean;
  readonly enableDvr?: boolean;
  readonly recordFromStart?: boolean;
  readonly enableAutoStart?: boolean;
  readonly enableAutoStop?: boolean;
  readonly latencyPreference?: LatencyPreference;
}

export interface YouTubeLiveStream {
  readonly streamId: string;
  readonly channelId: string;
  readonly title: string;
  readonly description: string;
  readonly streamStatus: StreamStatus;
  readonly resolution: StreamResolution;
  readonly frameRate: StreamFrameRate;
  readonly ingestionType: StreamIngestionType;
  readonly isReusable: boolean;
  readonly ingestionAddress?: string;
  readonly backupIngestionAddress?: string;
  readonly rtmpsIngestionAddress?: string;
  readonly rtmpsBackupIngestionAddress?: string;
  /** Provider stream key. Treat as a secret and never log it. */
  readonly streamName?: string;
}

export interface YouTubeLiveChatMessage {
  readonly messageId: string;
  readonly liveChatId: string;
  readonly type: string;
  readonly publishedAt: string;
  readonly displayMessage?: string;
  readonly textMessage?: string;
  readonly author?: {
    readonly channelId: string;
    readonly displayName: string;
    readonly profileImageUrl?: string;
    readonly isVerified: boolean;
    readonly isChatOwner: boolean;
    readonly isChatSponsor: boolean;
    readonly isChatModerator: boolean;
  };
  readonly poll?: {
    readonly questionText: string;
    readonly status: "active" | "closed" | "unknown";
    readonly options: readonly {
      readonly optionText: string;
      readonly tally?: string;
    }[];
  };
}

export interface YouTubeLiveModerator {
  readonly moderatorId: string;
  readonly liveChatId: string;
  readonly channelId: string;
  readonly displayName: string;
  readonly profileImageUrl?: string;
}

function parseJson<T>(body: string): T {
  try {
    return JSON.parse(body) as T;
  } catch {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned an unreadable live response.",
      502,
      false,
    );
  }
}

function strictIdentifier(
  value: string,
  pattern: RegExp,
  label: string,
): string {
  const clean = value.trim();
  if (!pattern.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      `A valid ${label} is required.`,
      400,
      false,
    );
  }
  return clean;
}

function providerIdentifier(
  value: unknown,
  pattern: RegExp,
  message: string,
): string {
  if (typeof value !== "string" || !pattern.test(value)) {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  return value;
}

function expectedChannelId(value: string): string {
  return strictIdentifier(value, CHANNEL_ID, "connected channel");
}

function actionText(value: string, label: string, maximum: number): string {
  const clean = value.replace(/\r\n?/gu, "\n").normalize("NFC");
  if (
    !clean.trim() ||
    clean.length > maximum ||
    /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/u.test(clean)
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} must contain between 1 and ${maximum} characters.`,
      400,
      false,
    );
  }
  return clean;
}

function optionalActionText(
  value: string,
  label: string,
  maximum: number,
): string {
  if (value === "") return "";
  return actionText(value, label, maximum);
}

function providerText(value: unknown, message: string): string {
  return safeYouTubeProviderPlainText(value, message);
}

function providerTextAllowEmpty(value: unknown, message: string): string {
  if (typeof value !== "string") {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  if (value === "") return "";
  return providerText(value, message);
}

function providerDate(value: unknown, message: string): string {
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value))) {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  return value;
}

function requestedDate(value: string, label: string): string {
  const parsed = Date.parse(value);
  if (
    !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$/u.test(value) ||
    !Number.isFinite(parsed)
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} must be a valid UTC date and time.`,
      400,
      false,
    );
  }
  return new Date(parsed).toISOString();
}

function pageToken(value: string | undefined): string | undefined {
  return value === undefined
    ? undefined
    : strictIdentifier(value, PAGE_TOKEN, "page token");
}

function providerPageToken(value: unknown): string | undefined {
  if (value === undefined) return undefined;
  return providerIdentifier(
    value,
    PAGE_TOKEN,
    "YouTube returned an invalid page token.",
  );
}

function pageSize(
  value: number | undefined,
  maximum = MAX_PAGE_SIZE,
): number {
  const size = value ?? DEFAULT_PAGE_SIZE;
  if (!Number.isSafeInteger(size) || size < 1 || size > maximum) {
    throw new YouTubeProviderError(
      "bad_request",
      `maxResults must be between 1 and ${maximum}.`,
      400,
      false,
    );
  }
  return size;
}

function chatPageSize(value: number | undefined): number {
  /*
   * The official REST method accepts 200..2000. Private Dev deliberately
   * fixes the smallest supported page so a caller cannot amplify response
   * size while preserving provider-compatible polling.
   */
  const size = value ?? MAX_CHAT_PAGE_SIZE;
  if (size !== MAX_CHAT_PAGE_SIZE) {
    throw new YouTubeProviderError(
      "bad_request",
      `maxResults must be ${MAX_CHAT_PAGE_SIZE} for live chat.`,
      400,
      false,
    );
  }
  return size;
}

function providerBoolean(value: unknown, message: string): boolean {
  if (typeof value !== "boolean") {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  return value;
}

function providerOptionalBoolean(
  value: unknown,
  message: string,
): boolean | undefined {
  if (value === undefined) return undefined;
  return providerBoolean(value, message);
}

function providerIngestionUrl(value: unknown, message: string): string {
  if (typeof value !== "string" || !value.trim() || value.length > 2048) {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  try {
    const url = new URL(value);
    if (
      !["rtmp:", "rtmps:", "https:"].includes(url.protocol) ||
      !url.hostname ||
      !(
        url.hostname === "youtube.com" ||
        url.hostname.endsWith(".youtube.com") ||
        url.hostname === "google.com" ||
        url.hostname.endsWith(".google.com") ||
        url.hostname === "googleapis.com" ||
        url.hostname.endsWith(".googleapis.com")
      ) ||
      url.username ||
      url.password ||
      url.hash
    ) {
      throw new Error("unsafe ingestion URL");
    }
    return url.toString();
  } catch {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
}

function providerProfile(
  input: ApiChannelProfile | undefined,
  message: string,
): {
  readonly channelId: string;
  readonly displayName: string;
  readonly profileImageUrl?: string;
} {
  const channelId = providerIdentifier(
    input?.channelId,
    CHANNEL_ID,
    message,
  );
  const displayName = providerText(input?.displayName, message);
  const profileImageUrl =
    input?.profileImageUrl === undefined
      ? undefined
      : safeYouTubeProviderImageUrl(input.profileImageUrl, message);
  return {
    channelId,
    displayName,
    ...(profileImageUrl === undefined ? {} : { profileImageUrl }),
  };
}

function confirmation(actual: string, confirmed: string, label: string): void {
  if (actual !== confirmed.trim()) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} confirmation does not match.`,
      400,
      false,
    );
  }
}

export class YouTubeLiveClient {
  private readonly clock: Clock;

  constructor(
    private readonly options: {
      readonly transport: HttpTransport;
      readonly quota: YouTubeQuotaPort;
      readonly clock?: Clock;
    },
  ) {
    this.clock = options.clock ?? systemClock;
  }

  private async api(
    request: LiveOwnerRequest,
    operation: string,
    amount: number,
    url: URL,
    method: "GET" | "POST" | "PUT" | "DELETE" = "GET",
    body?: unknown,
  ): Promise<string> {
    await this.options.quota.reserve({
      principal: request.principal,
      bucket: "general",
      amount,
      operation,
      requestId: request.requestId,
    });
    const response = await this.options.transport.send({
      url: url.toString(),
      method,
      headers: {
        authorization: `Bearer ${request.accessToken}`,
        ...(body === undefined
          ? {}
          : { "content-type": "application/json; charset=UTF-8" }),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    assertProviderResponse(response.status, response.body);
    return response.body;
  }

  private mapBroadcast(
    value: ApiLiveBroadcast,
    expectedOwner: string,
  ): YouTubeLiveBroadcast {
    const broadcastId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid live broadcast.",
    );
    const channelId = providerIdentifier(
      value.snippet?.channelId,
      CHANNEL_ID,
      "YouTube returned an invalid live broadcast owner.",
    );
    if (channelId !== expectedOwner) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The live broadcast does not belong to the connected channel.",
        403,
        false,
      );
    }
    const lifecycle = value.status?.lifeCycleStatus;
    if (
      typeof lifecycle !== "string" ||
      !BROADCAST_LIFECYCLES.has(lifecycle as BroadcastLifecycle)
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid live broadcast state.",
        502,
        false,
      );
    }
    const privacy = value.status?.privacyStatus;
    if (
      privacy !== "private" &&
      privacy !== "public" &&
      privacy !== "unlisted"
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid live broadcast privacy state.",
        502,
        false,
      );
    }
    const recording = value.status?.recordingStatus;
    if (
      recording !== "notRecording" &&
      recording !== "recording" &&
      recording !== "recorded"
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid live recording state.",
        502,
        false,
      );
    }
    const liveChatId =
      value.snippet?.liveChatId === undefined
        ? undefined
        : providerIdentifier(
            value.snippet.liveChatId,
            RESOURCE_ID,
            "YouTube returned an invalid live chat.",
          );
    const boundStreamId =
      value.contentDetails?.boundStreamId === undefined
        ? undefined
        : providerIdentifier(
            value.contentDetails.boundStreamId,
            RESOURCE_ID,
            "YouTube returned an invalid bound live stream.",
          );
    const latency = value.contentDetails?.latencyPreference;
    if (
      latency !== undefined &&
      latency !== "normal" &&
      latency !== "low" &&
      latency !== "ultraLow"
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid live latency setting.",
        502,
        false,
      );
    }
    return {
      broadcastId,
      channelId,
      title: providerText(
        value.snippet?.title,
        "YouTube returned an invalid live broadcast title.",
      ),
      description: providerTextAllowEmpty(
        value.snippet?.description ?? "",
        "YouTube returned an invalid live broadcast description.",
      ),
      scheduledStartTime: providerDate(
        value.snippet?.scheduledStartTime,
        "YouTube returned an invalid scheduled start time.",
      ),
      scheduledEndTime: providerDate(
        value.snippet?.scheduledEndTime,
        "YouTube returned an invalid scheduled end time.",
      ),
      ...(value.snippet?.actualStartTime === undefined
        ? {}
        : {
            actualStartTime: providerDate(
              value.snippet.actualStartTime,
              "YouTube returned an invalid actual start time.",
            ),
          }),
      ...(value.snippet?.actualEndTime === undefined
        ? {}
        : {
            actualEndTime: providerDate(
              value.snippet.actualEndTime,
              "YouTube returned an invalid actual end time.",
            ),
          }),
      ...(liveChatId === undefined ? {} : { liveChatId }),
      lifeCycleStatus: lifecycle as BroadcastLifecycle,
      privacyStatus: privacy,
      recordingStatus: recording,
      ...(value.status?.madeForKids === undefined
        ? {}
        : {
            madeForKids: providerBoolean(
              value.status.madeForKids,
              "YouTube returned an invalid audience setting.",
            ),
          }),
      ...(value.status?.selfDeclaredMadeForKids === undefined
        ? {}
        : {
            selfDeclaredMadeForKids: providerBoolean(
              value.status.selfDeclaredMadeForKids,
              "YouTube returned an invalid audience declaration.",
            ),
          }),
      ...(boundStreamId === undefined ? {} : { boundStreamId }),
      ...(value.contentDetails?.enableEmbed === undefined
        ? {}
        : {
            enableEmbed: providerBoolean(
              value.contentDetails.enableEmbed,
              "YouTube returned an invalid embed setting.",
            ),
          }),
      ...(value.contentDetails?.enableDvr === undefined
        ? {}
        : {
            enableDvr: providerBoolean(
              value.contentDetails.enableDvr,
              "YouTube returned an invalid DVR setting.",
            ),
          }),
      ...(value.contentDetails?.recordFromStart === undefined
        ? {}
        : {
            recordFromStart: providerBoolean(
              value.contentDetails.recordFromStart,
              "YouTube returned an invalid recording setting.",
            ),
          }),
      ...(value.contentDetails?.enableAutoStart === undefined
        ? {}
        : {
            enableAutoStart: providerBoolean(
              value.contentDetails.enableAutoStart,
              "YouTube returned an invalid automatic start setting.",
            ),
          }),
      ...(value.contentDetails?.enableAutoStop === undefined
        ? {}
        : {
            enableAutoStop: providerBoolean(
              value.contentDetails.enableAutoStop,
              "YouTube returned an invalid automatic stop setting.",
            ),
          }),
      ...(latency === undefined
        ? {}
        : { latencyPreference: latency as LatencyPreference }),
    };
  }

  private async ownedBroadcast(
    request: LiveOwnerRequest,
    broadcastIdInput: string,
    privateMutation = false,
  ): Promise<YouTubeLiveBroadcast> {
    const broadcastId = strictIdentifier(
      broadcastIdInput,
      RESOURCE_ID,
      "broadcast",
    );
    const owner = expectedChannelId(request.expectedChannelId);
    const url = new URL(`${DATA_API}/liveBroadcasts`);
    url.searchParams.set("part", "id,snippet,status,contentDetails");
    url.searchParams.set("id", broadcastId);
    const body = await this.api(
      request,
      "liveBroadcasts.list.ownerPreflight",
      READ_QUOTA_COST,
      url,
    );
    const item = parseJson<ListEnvelope<ApiLiveBroadcast>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested live broadcast is unavailable.",
        404,
        false,
      );
    }
    const mapped = this.mapBroadcast(item, owner);
    if (mapped.broadcastId !== broadcastId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an inconsistent live broadcast.",
        502,
        false,
      );
    }
    if (privateMutation && mapped.privacyStatus !== "private") {
      throw new YouTubeProviderError(
        "permission_denied",
        "Public or unlisted broadcasts cannot be changed during private Dev proof.",
        403,
        false,
      );
    }
    return mapped;
  }

  async listBroadcasts(
    request: LiveBroadcastListRequest,
  ): Promise<{
    readonly items: readonly YouTubeLiveBroadcast[];
    readonly nextPageToken?: string;
  }> {
    if (
      request.status !== "all" &&
      request.status !== "active" &&
      request.status !== "upcoming" &&
      request.status !== "completed"
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported live broadcast filter is required.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveBroadcasts`);
    url.searchParams.set("part", "id,snippet,status,contentDetails");
    url.searchParams.set("mine", "true");
    url.searchParams.set("broadcastStatus", request.status);
    url.searchParams.set("maxResults", String(pageSize(request.maxResults)));
    const token = pageToken(request.pageToken);
    if (token !== undefined) url.searchParams.set("pageToken", token);
    const body = await this.api(
      request,
      "liveBroadcasts.list.owner",
      READ_QUOTA_COST,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiLiveBroadcast>>(body);
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    const owner = expectedChannelId(request.expectedChannelId);
    return {
      items: (envelope.items ?? []).map((item) =>
        this.mapBroadcast(item, owner),
      ),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  private broadcastWrite(
    request: LiveBroadcastWrite,
  ): {
    readonly snippet: {
      readonly title: string;
      readonly description: string;
      readonly scheduledStartTime: string;
      readonly scheduledEndTime: string;
    };
    readonly status: {
      readonly privacyStatus: "private";
      readonly selfDeclaredMadeForKids: boolean;
    };
    readonly contentDetails: {
      readonly enableEmbed: boolean;
      readonly enableDvr: boolean;
      readonly recordFromStart: true;
      readonly enableAutoStart: boolean;
      readonly enableAutoStop: boolean;
      readonly latencyPreference: LatencyPreference;
      readonly monitorStream: { readonly enableMonitorStream: false };
    };
  } {
    const start = requestedDate(
      request.scheduledStartTime,
      "scheduledStartTime",
    );
    const end = requestedDate(
      request.scheduledEndTime,
      "scheduledEndTime",
    );
    const now = this.clock.now().getTime();
    if (
      Date.parse(start) <= now ||
      Date.parse(end) <= Date.parse(start) ||
      Date.parse(start) - now > 366 * 24 * 60 * 60 * 1000
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "The live broadcast schedule must start in the future and end after it starts.",
        400,
        false,
      );
    }
    if (
      request.latencyPreference !== "normal" &&
      request.latencyPreference !== "low" &&
      request.latencyPreference !== "ultraLow"
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported live latency setting is required.",
        400,
        false,
      );
    }
    return {
      snippet: {
        title: actionText(request.title, "Broadcast title", 100),
        description: optionalActionText(
          request.description,
          "Broadcast description",
          5_000,
        ),
        scheduledStartTime: start,
        scheduledEndTime: end,
      },
      status: {
        privacyStatus: "private",
        selfDeclaredMadeForKids: request.selfDeclaredMadeForKids,
      },
      contentDetails: {
        enableEmbed: request.enableEmbed,
        enableDvr: request.enableDvr,
        recordFromStart: true,
        enableAutoStart: request.enableAutoStart,
        enableAutoStop: request.enableAutoStop,
        latencyPreference: request.latencyPreference,
        monitorStream: { enableMonitorStream: false },
      },
    };
  }

  async insertBroadcast(
    request: LiveBroadcastInsertRequest,
  ): Promise<YouTubeLiveBroadcast> {
    const payload = this.broadcastWrite(request);
    const url = new URL(`${DATA_API}/liveBroadcasts`);
    url.searchParams.set("part", "id,snippet,status,contentDetails");
    const body = await this.api(
      request,
      "liveBroadcasts.insert.privateOwner",
      WRITE_QUOTA_COST,
      url,
      "POST",
      payload,
    );
    return this.mapBroadcast(
      parseJson<ApiLiveBroadcast>(body),
      expectedChannelId(request.expectedChannelId),
    );
  }

  async updateBroadcast(
    request: LiveBroadcastUpdateRequest,
  ): Promise<YouTubeLiveBroadcast> {
    const existing = await this.ownedBroadcast(
      request,
      request.broadcastId,
      true,
    );
    if (
      existing.lifeCycleStatus !== "created" &&
      existing.lifeCycleStatus !== "ready"
    ) {
      throw new YouTubeProviderError(
        "permission_denied",
        "Only a private upcoming broadcast can be edited during private Dev proof.",
        403,
        false,
      );
    }
    const payload = this.broadcastWrite(request);
    const url = new URL(`${DATA_API}/liveBroadcasts`);
    url.searchParams.set("part", "snippet,status,contentDetails");
    const body = await this.api(
      request,
      "liveBroadcasts.update.privateOwner",
      WRITE_QUOTA_COST,
      url,
      "PUT",
      { id: existing.broadcastId, ...payload },
    );
    return this.mapBroadcast(
      parseJson<ApiLiveBroadcast>(body),
      expectedChannelId(request.expectedChannelId),
    );
  }

  private mapStream(
    value: ApiLiveStream,
    expectedOwner: string,
  ): YouTubeLiveStream {
    const streamId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid live stream.",
    );
    const channelId = providerIdentifier(
      value.snippet?.channelId,
      CHANNEL_ID,
      "YouTube returned an invalid live stream owner.",
    );
    if (channelId !== expectedOwner) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The live stream does not belong to the connected channel.",
        403,
        false,
      );
    }
    const streamStatus = value.status?.streamStatus;
    const resolution = value.cdn?.resolution;
    const frameRate = value.cdn?.frameRate;
    const ingestionType = value.cdn?.ingestionType;
    if (
      typeof streamStatus !== "string" ||
      !STREAM_STATUSES.has(streamStatus as StreamStatus) ||
      (resolution !== "240p" &&
        resolution !== "360p" &&
        resolution !== "480p" &&
        resolution !== "720p" &&
        resolution !== "1080p" &&
        resolution !== "1440p" &&
        resolution !== "2160p" &&
        resolution !== "variable") ||
      (frameRate !== "30fps" &&
        frameRate !== "60fps" &&
        frameRate !== "variable") ||
      (ingestionType !== "rtmp" &&
        ingestionType !== "dash" &&
        ingestionType !== "webrtc" &&
        ingestionType !== "hls")
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned invalid live stream settings.",
        502,
        false,
      );
    }
    const info = value.cdn?.ingestionInfo;
    const ingestionAddress =
      info?.ingestionAddress === undefined
        ? undefined
        : providerIngestionUrl(
            info.ingestionAddress,
            "YouTube returned an invalid ingestion address.",
          );
    const backupIngestionAddress =
      info?.backupIngestionAddress === undefined
        ? undefined
        : providerIngestionUrl(
            info.backupIngestionAddress,
            "YouTube returned an invalid backup ingestion address.",
          );
    const rtmpsIngestionAddress =
      info?.rtmpsIngestionAddress === undefined
        ? undefined
        : providerIngestionUrl(
            info.rtmpsIngestionAddress,
            "YouTube returned an invalid secure ingestion address.",
          );
    const rtmpsBackupIngestionAddress =
      info?.rtmpsBackupIngestionAddress === undefined
        ? undefined
        : providerIngestionUrl(
            info.rtmpsBackupIngestionAddress,
            "YouTube returned an invalid secure backup ingestion address.",
          );
    const streamName =
      info?.streamName === undefined
        ? undefined
        : providerText(
            info.streamName,
            "YouTube returned an invalid live stream key.",
          );
    return {
      streamId,
      channelId,
      title: providerText(
        value.snippet?.title,
        "YouTube returned an invalid live stream title.",
      ),
      description: providerTextAllowEmpty(
        value.snippet?.description ?? "",
        "YouTube returned an invalid live stream description.",
      ),
      streamStatus: streamStatus as StreamStatus,
      resolution: resolution as StreamResolution,
      frameRate: frameRate as StreamFrameRate,
      ingestionType: ingestionType as StreamIngestionType,
      isReusable: providerBoolean(
        value.contentDetails?.isReusable,
        "YouTube returned an invalid live stream reuse setting.",
      ),
      ...(ingestionAddress === undefined ? {} : { ingestionAddress }),
      ...(backupIngestionAddress === undefined
        ? {}
        : { backupIngestionAddress }),
      ...(rtmpsIngestionAddress === undefined
        ? {}
        : { rtmpsIngestionAddress }),
      ...(rtmpsBackupIngestionAddress === undefined
        ? {}
        : { rtmpsBackupIngestionAddress }),
      ...(streamName === undefined ? {} : { streamName }),
    };
  }

  private async ownedStream(
    request: LiveOwnerRequest,
    streamIdInput: string,
  ): Promise<YouTubeLiveStream> {
    const streamId = strictIdentifier(streamIdInput, RESOURCE_ID, "stream");
    const url = new URL(`${DATA_API}/liveStreams`);
    url.searchParams.set("part", "id,snippet,cdn,contentDetails,status");
    url.searchParams.set("id", streamId);
    const body = await this.api(
      request,
      "liveStreams.list.ownerPreflight",
      READ_QUOTA_COST,
      url,
    );
    const item = parseJson<ListEnvelope<ApiLiveStream>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested live stream is unavailable.",
        404,
        false,
      );
    }
    const mapped = this.mapStream(
      item,
      expectedChannelId(request.expectedChannelId),
    );
    if (mapped.streamId !== streamId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an inconsistent live stream.",
        502,
        false,
      );
    }
    return mapped;
  }

  async listStreams(
    request: LiveListRequest,
  ): Promise<{
    readonly items: readonly YouTubeLiveStream[];
    readonly nextPageToken?: string;
  }> {
    const url = new URL(`${DATA_API}/liveStreams`);
    url.searchParams.set("part", "id,snippet,cdn,contentDetails,status");
    url.searchParams.set("mine", "true");
    url.searchParams.set("maxResults", String(pageSize(request.maxResults)));
    const token = pageToken(request.pageToken);
    if (token !== undefined) url.searchParams.set("pageToken", token);
    const body = await this.api(
      request,
      "liveStreams.list.owner",
      READ_QUOTA_COST,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiLiveStream>>(body);
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    const owner = expectedChannelId(request.expectedChannelId);
    return {
      items: (envelope.items ?? []).map((item) =>
        this.mapStream(item, owner),
      ),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async insertStream(
    request: LiveStreamInsertRequest,
  ): Promise<YouTubeLiveStream> {
    const resolutions = new Set<StreamResolution>([
      "240p",
      "360p",
      "480p",
      "720p",
      "1080p",
      "1440p",
      "2160p",
      "variable",
    ]);
    const frameRates = new Set<StreamFrameRate>([
      "30fps",
      "60fps",
      "variable",
    ]);
    const ingestionTypes = new Set<StreamIngestionType>([
      "rtmp",
      "dash",
      "webrtc",
      "hls",
    ]);
    if (
      !resolutions.has(request.resolution) ||
      !frameRates.has(request.frameRate) ||
      !ingestionTypes.has(request.ingestionType)
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "Supported live stream encoding settings are required.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveStreams`);
    url.searchParams.set("part", "id,snippet,cdn,contentDetails,status");
    const body = await this.api(
      request,
      "liveStreams.insert.owner",
      WRITE_QUOTA_COST,
      url,
      "POST",
      {
        snippet: {
          title: actionText(request.title, "Stream title", 128),
          description: optionalActionText(
            request.description,
            "Stream description",
            10_000,
          ),
        },
        cdn: {
          resolution: request.resolution,
          frameRate: request.frameRate,
          ingestionType: request.ingestionType,
        },
        contentDetails: { isReusable: request.isReusable },
      },
    );
    return this.mapStream(
      parseJson<ApiLiveStream>(body),
      expectedChannelId(request.expectedChannelId),
    );
  }

  async updateStream(
    request: LiveStreamUpdateRequest,
  ): Promise<YouTubeLiveStream> {
    const existing = await this.ownedStream(request, request.streamId);
    if (existing.streamStatus === "active") {
      throw new YouTubeProviderError(
        "permission_denied",
        "An active live stream cannot be edited during private Dev proof.",
        403,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveStreams`);
    url.searchParams.set("part", "snippet,contentDetails");
    const body = await this.api(
      request,
      "liveStreams.update.owner",
      WRITE_QUOTA_COST,
      url,
      "PUT",
      {
        id: existing.streamId,
        snippet: {
          title: actionText(request.title, "Stream title", 128),
          description: optionalActionText(
            request.description,
            "Stream description",
            10_000,
          ),
        },
        contentDetails: { isReusable: request.isReusable },
      },
    );
    /*
     * The update response may omit CDN/status parts that were not selected.
     * Re-read through the owner preflight to return one coherent DTO.
     */
    const updated = parseJson<ApiLiveStream>(body);
    const updatedId = providerIdentifier(
      updated.id,
      RESOURCE_ID,
      "YouTube returned an invalid updated live stream.",
    );
    if (updatedId !== existing.streamId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an inconsistent updated live stream.",
        502,
        false,
      );
    }
    return this.ownedStream(request, existing.streamId);
  }

  async bindBroadcast(
    request: LiveBroadcastBindRequest,
  ): Promise<YouTubeLiveBroadcast> {
    const broadcast = await this.ownedBroadcast(
      request,
      request.broadcastId,
      true,
    );
    const stream = await this.ownedStream(request, request.streamId);
    confirmation(
      broadcast.broadcastId,
      request.confirmBroadcastId,
      "Broadcast",
    );
    confirmation(stream.streamId, request.confirmStreamId, "Stream");
    if (
      broadcast.lifeCycleStatus !== "created" &&
      broadcast.lifeCycleStatus !== "ready"
    ) {
      throw new YouTubeProviderError(
        "permission_denied",
        "Only an upcoming private broadcast can be bound during private Dev proof.",
        403,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveBroadcasts/bind`);
    url.searchParams.set("id", broadcast.broadcastId);
    url.searchParams.set("streamId", stream.streamId);
    url.searchParams.set("part", "id,snippet,status,contentDetails");
    const body = await this.api(
      request,
      "liveBroadcasts.bind.privateOwner",
      WRITE_QUOTA_COST,
      url,
      "POST",
    );
    return this.mapBroadcast(
      parseJson<ApiLiveBroadcast>(body),
      expectedChannelId(request.expectedChannelId),
    );
  }

  async transitionBroadcast(
    request: LiveBroadcastTransitionRequest,
  ): Promise<YouTubeLiveBroadcast> {
    const broadcast = await this.ownedBroadcast(
      request,
      request.broadcastId,
      true,
    );
    confirmation(
      broadcast.broadcastId,
      request.confirmBroadcastId,
      "Broadcast",
    );
    if (request.targetStatus !== request.confirmTargetStatus) {
      throw new YouTubeProviderError(
        "bad_request",
        "Broadcast status confirmation does not match.",
        400,
        false,
      );
    }
    const allowed =
      (request.targetStatus === "testing" &&
        (broadcast.lifeCycleStatus === "created" ||
          broadcast.lifeCycleStatus === "ready")) ||
      (request.targetStatus === "live" &&
        (broadcast.lifeCycleStatus === "created" ||
          broadcast.lifeCycleStatus === "ready" ||
          broadcast.lifeCycleStatus === "testing")) ||
      (request.targetStatus === "complete" &&
        broadcast.lifeCycleStatus === "live");
    if (!allowed) {
      throw new YouTubeProviderError(
        "bad_request",
        "The requested live broadcast transition is not valid from its current state.",
        400,
        false,
      );
    }
    if (
      request.targetStatus !== "complete" &&
      broadcast.boundStreamId === undefined
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "Bind an owned live stream before starting the broadcast.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveBroadcasts/transition`);
    url.searchParams.set("id", broadcast.broadcastId);
    url.searchParams.set("broadcastStatus", request.targetStatus);
    url.searchParams.set("part", "id,snippet,status,contentDetails");
    const body = await this.api(
      request,
      "liveBroadcasts.transition.privateOwner",
      WRITE_QUOTA_COST,
      url,
      "POST",
    );
    return this.mapBroadcast(
      parseJson<ApiLiveBroadcast>(body),
      expectedChannelId(request.expectedChannelId),
    );
  }

  async deleteBroadcast(
    request: LiveBroadcastDeleteRequest,
  ): Promise<{ readonly deletedBroadcastId: string }> {
    const broadcast = await this.ownedBroadcast(
      request,
      request.broadcastId,
      true,
    );
    confirmation(
      broadcast.broadcastId,
      request.confirmBroadcastId,
      "Broadcast",
    );
    if (
      broadcast.lifeCycleStatus === "testing" ||
      broadcast.lifeCycleStatus === "live" ||
      broadcast.lifeCycleStatus === "testStarting" ||
      broadcast.lifeCycleStatus === "liveStarting"
    ) {
      throw new YouTubeProviderError(
        "permission_denied",
        "An active live broadcast cannot be deleted during private Dev proof.",
        403,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveBroadcasts`);
    url.searchParams.set("id", broadcast.broadcastId);
    await this.api(
      request,
      "liveBroadcasts.delete.privateOwner",
      WRITE_QUOTA_COST,
      url,
      "DELETE",
    );
    return { deletedBroadcastId: broadcast.broadcastId };
  }

  async deleteStream(
    request: LiveStreamDeleteRequest,
  ): Promise<{ readonly deletedStreamId: string }> {
    const stream = await this.ownedStream(request, request.streamId);
    confirmation(stream.streamId, request.confirmStreamId, "Stream");
    if (stream.streamStatus === "active") {
      throw new YouTubeProviderError(
        "permission_denied",
        "An active live stream cannot be deleted during private Dev proof.",
        403,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveStreams`);
    url.searchParams.set("id", stream.streamId);
    await this.api(
      request,
      "liveStreams.delete.owner",
      WRITE_QUOTA_COST,
      url,
      "DELETE",
    );
    return { deletedStreamId: stream.streamId };
  }

  private async ownedChat(
    request: LiveChatRequest,
    privateMutation = false,
  ): Promise<{ readonly broadcast: YouTubeLiveBroadcast; readonly liveChatId: string }> {
    const broadcast = await this.ownedBroadcast(
      request,
      request.broadcastId,
      privateMutation,
    );
    const liveChatId = strictIdentifier(
      request.liveChatId,
      RESOURCE_ID,
      "live chat",
    );
    if (broadcast.liveChatId !== liveChatId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The live chat does not belong to the selected broadcast.",
        403,
        false,
      );
    }
    return { broadcast, liveChatId };
  }

  private mapMessage(
    value: ApiLiveChatMessage,
    expectedChatId: string,
  ): YouTubeLiveChatMessage {
    const messageId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid live chat message.",
    );
    const liveChatId = providerIdentifier(
      value.snippet?.liveChatId,
      RESOURCE_ID,
      "YouTube returned an invalid live chat message attribution.",
    );
    if (liveChatId !== expectedChatId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "YouTube returned a message from another live chat.",
        403,
        false,
      );
    }
    const type = value.snippet?.type;
    if (typeof type !== "string" || !MESSAGE_TYPES.has(type)) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid live chat message type.",
        502,
        false,
      );
    }
    const author =
      value.authorDetails === undefined
        ? undefined
        : (() => {
            const profile = providerProfile(
              value.authorDetails,
              "YouTube returned invalid live chat author details.",
            );
            return {
              ...profile,
              isVerified: providerBoolean(
                value.authorDetails?.isVerified,
                "YouTube returned invalid live chat author details.",
              ),
              isChatOwner: providerBoolean(
                value.authorDetails?.isChatOwner,
                "YouTube returned invalid live chat author details.",
              ),
              isChatSponsor: providerBoolean(
                value.authorDetails?.isChatSponsor,
                "YouTube returned invalid live chat author details.",
              ),
              isChatModerator: providerBoolean(
                value.authorDetails?.isChatModerator,
                "YouTube returned invalid live chat author details.",
              ),
            };
          })();
    const poll =
      value.snippet?.pollDetails === undefined
        ? undefined
        : (() => {
            const status = value.snippet?.pollDetails?.status as
              | "active"
              | "closed"
              | "unknown"
              | undefined;
            if (
              status !== "active" &&
              status !== "closed" &&
              status !== "unknown"
            ) {
              throw new YouTubeProviderError(
                "provider_rejected",
                "YouTube returned an invalid live poll state.",
                502,
                false,
              );
            }
            const options = value.snippet?.pollDetails?.metadata?.options;
            if (!Array.isArray(options) || options.length < 2 || options.length > 4) {
              throw new YouTubeProviderError(
                "provider_rejected",
                "YouTube returned invalid live poll options.",
                502,
                false,
              );
            }
            return {
              questionText: providerText(
                value.snippet?.pollDetails?.metadata?.questionText,
                "YouTube returned an invalid live poll question.",
              ),
              status,
              options: options.map((option) => ({
                optionText: providerText(
                  option.optionText,
                  "YouTube returned an invalid live poll option.",
                ),
                ...(option.tally === undefined
                  ? {}
                  : {
                      tally: providerIdentifier(
                        option.tally,
                        /^\d+$/u,
                        "YouTube returned an invalid live poll tally.",
                      ),
                    }),
              })),
            };
          })();
    return {
      messageId,
      liveChatId,
      type,
      publishedAt: providerDate(
        value.snippet?.publishedAt,
        "YouTube returned an invalid live chat time.",
      ),
      ...(value.snippet?.displayMessage === undefined
        ? {}
        : {
            displayMessage: providerText(
              value.snippet.displayMessage,
              "YouTube returned an invalid live chat display message.",
            ),
          }),
      ...(value.snippet?.textMessageDetails?.messageText === undefined
        ? {}
        : {
            textMessage: providerText(
              value.snippet.textMessageDetails.messageText,
              "YouTube returned an invalid live chat message.",
            ),
          }),
      ...(author === undefined ? {} : { author }),
      ...(poll === undefined ? {} : { poll }),
    };
  }

  async listMessages(
    request: LiveChatListRequest,
  ): Promise<{
    readonly items: readonly YouTubeLiveChatMessage[];
    readonly nextPageToken?: string;
    readonly pollingIntervalMillis: number;
    readonly offlineAt?: string;
    readonly activePoll?: YouTubeLiveChatMessage;
  }> {
    const { liveChatId } = await this.ownedChat(request);
    const url = new URL(`${DATA_API}/liveChat/messages`);
    url.searchParams.set("part", "id,snippet,authorDetails");
    url.searchParams.set("liveChatId", liveChatId);
    url.searchParams.set(
      "maxResults",
      String(chatPageSize(request.maxResults)),
    );
    url.searchParams.set("profileImageSize", "88");
    const token = pageToken(request.pageToken);
    if (token !== undefined) url.searchParams.set("pageToken", token);
    const body = await this.api(
      request,
      "liveChatMessages.list.owner",
      READ_QUOTA_COST,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiLiveChatMessage>>(body);
    if (
      !Number.isSafeInteger(envelope.pollingIntervalMillis) ||
      (envelope.pollingIntervalMillis ?? 0) < 250 ||
      (envelope.pollingIntervalMillis ?? 0) > 120_000
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid live chat polling interval.",
        502,
        false,
      );
    }
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    const activePoll =
      envelope.activePollItem === undefined
        ? undefined
        : this.mapMessage(envelope.activePollItem, liveChatId);
    return {
      items: (envelope.items ?? []).map((item) =>
        this.mapMessage(item, liveChatId),
      ),
      pollingIntervalMillis: envelope.pollingIntervalMillis!,
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
      ...(envelope.offlineAt === undefined
        ? {}
        : {
            offlineAt: providerDate(
              envelope.offlineAt,
              "YouTube returned an invalid live chat offline time.",
            ),
          }),
      ...(activePoll === undefined ? {} : { activePoll }),
    };
  }

  private async currentMessage(
    request: LiveChatRequest,
    messageIdInput: string,
  ): Promise<YouTubeLiveChatMessage> {
    await this.ownedChat(request, true);
    const messageId = strictIdentifier(
      messageIdInput,
      RESOURCE_ID,
      "live chat message",
    );
    const page = await this.listMessages({
      ...request,
      maxResults: MAX_CHAT_PAGE_SIZE,
    });
    const message = page.items.find((item) => item.messageId === messageId);
    if (!message) {
      throw new YouTubeProviderError(
        "not_found",
        "The live chat message is not present in the current owned chat window.",
        404,
        false,
      );
    }
    return message;
  }

  async insertTextMessage(
    request: LiveChatTextInsertRequest,
  ): Promise<YouTubeLiveChatMessage> {
    const { liveChatId } = await this.ownedChat(request, true);
    const url = new URL(`${DATA_API}/liveChat/messages`);
    url.searchParams.set("part", "snippet");
    const body = await this.api(
      request,
      "liveChatMessages.insert.text.owner",
      WRITE_QUOTA_COST,
      url,
      "POST",
      {
        snippet: {
          liveChatId,
          type: "textMessageEvent",
          textMessageDetails: {
            messageText: actionText(
              request.messageText,
              "Live chat message",
              200,
            ),
          },
        },
      },
    );
    return this.mapMessage(parseJson<ApiLiveChatMessage>(body), liveChatId);
  }

  async insertPoll(
    request: LiveChatPollInsertRequest,
  ): Promise<YouTubeLiveChatMessage> {
    const { liveChatId } = await this.ownedChat(request, true);
    if (
      request.options.length < 2 ||
      request.options.length > 4
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "A live poll requires between 2 and 4 options.",
        400,
        false,
      );
    }
    const options = request.options.map((option) =>
      actionText(option, "Poll option", 80),
    );
    if (new Set(options.map((option) => option.trim().toLocaleLowerCase())).size !== options.length) {
      throw new YouTubeProviderError(
        "bad_request",
        "Live poll options must be unique.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveChat/messages`);
    url.searchParams.set("part", "snippet");
    const body = await this.api(
      request,
      "liveChatMessages.insert.poll.owner",
      WRITE_QUOTA_COST,
      url,
      "POST",
      {
        snippet: {
          liveChatId,
          type: "pollEvent",
          pollDetails: {
            metadata: {
              questionText: actionText(
                request.questionText,
                "Poll question",
                200,
              ),
              options: options.map((optionText) => ({ optionText })),
            },
          },
        },
      },
    );
    return this.mapMessage(parseJson<ApiLiveChatMessage>(body), liveChatId);
  }

  async closePoll(
    request: LiveChatPollCloseRequest,
  ): Promise<YouTubeLiveChatMessage> {
    const { liveChatId } = await this.ownedChat(request, true);
    const poll = await this.currentMessage(request, request.pollMessageId);
    confirmation(
      poll.messageId,
      request.confirmPollMessageId,
      "Poll message",
    );
    if (
      request.confirmStatus !== "closed" ||
      poll.type !== "pollEvent" ||
      poll.poll?.status !== "active"
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "Only the confirmed active poll can be closed.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveChat/messages/transition`);
    url.searchParams.set("id", poll.messageId);
    url.searchParams.set("status", "closed");
    const body = await this.api(
      request,
      "liveChatMessages.transition.pollClosed.owner",
      WRITE_QUOTA_COST,
      url,
      "POST",
    );
    return this.mapMessage(parseJson<ApiLiveChatMessage>(body), liveChatId);
  }

  async deleteMessage(
    request: LiveChatMessageDeleteRequest,
  ): Promise<{ readonly deletedMessageId: string }> {
    const message = await this.currentMessage(request, request.messageId);
    confirmation(
      message.messageId,
      request.confirmMessageId,
      "Live chat message",
    );
    const url = new URL(`${DATA_API}/liveChat/messages`);
    url.searchParams.set("id", message.messageId);
    await this.api(
      request,
      "liveChatMessages.delete.owner",
      WRITE_QUOTA_COST,
      url,
      "DELETE",
    );
    return { deletedMessageId: message.messageId };
  }

  private mapModerator(
    value: ApiLiveChatModerator,
    expectedChatId: string,
  ): YouTubeLiveModerator {
    const moderatorId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid live chat moderator.",
    );
    const liveChatId = providerIdentifier(
      value.snippet?.liveChatId,
      RESOURCE_ID,
      "YouTube returned invalid moderator attribution.",
    );
    if (liveChatId !== expectedChatId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "YouTube returned a moderator from another live chat.",
        403,
        false,
      );
    }
    return {
      moderatorId,
      liveChatId,
      ...providerProfile(
        value.snippet?.moderatorDetails,
        "YouTube returned invalid moderator details.",
      ),
    };
  }

  async listModerators(
    request: LiveChatListRequest,
  ): Promise<{
    readonly items: readonly YouTubeLiveModerator[];
    readonly nextPageToken?: string;
  }> {
    const { liveChatId } = await this.ownedChat(request);
    const url = new URL(`${DATA_API}/liveChat/moderators`);
    url.searchParams.set("part", "id,snippet");
    url.searchParams.set("liveChatId", liveChatId);
    url.searchParams.set("maxResults", String(pageSize(request.maxResults)));
    const token = pageToken(request.pageToken);
    if (token !== undefined) url.searchParams.set("pageToken", token);
    const body = await this.api(
      request,
      "liveChatModerators.list.owner",
      READ_QUOTA_COST,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiLiveChatModerator>>(body);
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      items: (envelope.items ?? []).map((item) =>
        this.mapModerator(item, liveChatId),
      ),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async insertModerator(
    request: LiveChatModeratorInsertRequest,
  ): Promise<YouTubeLiveModerator> {
    const { liveChatId } = await this.ownedChat(request, true);
    const moderatorChannelId = strictIdentifier(
      request.moderatorChannelId,
      CHANNEL_ID,
      "moderator channel",
    );
    if (moderatorChannelId === expectedChannelId(request.expectedChannelId)) {
      throw new YouTubeProviderError(
        "bad_request",
        "The connected channel is already the live chat owner.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveChat/moderators`);
    url.searchParams.set("part", "snippet");
    const body = await this.api(
      request,
      "liveChatModerators.insert.owner",
      WRITE_QUOTA_COST,
      url,
      "POST",
      {
        snippet: {
          liveChatId,
          moderatorDetails: { channelId: moderatorChannelId },
        },
      },
    );
    return this.mapModerator(
      parseJson<ApiLiveChatModerator>(body),
      liveChatId,
    );
  }

  async deleteModerator(
    request: LiveChatModeratorDeleteRequest,
  ): Promise<{ readonly deletedModeratorId: string }> {
    await this.ownedChat(request, true);
    const moderatorId = strictIdentifier(
      request.moderatorId,
      RESOURCE_ID,
      "moderator",
    );
    const page = await this.listModerators({ ...request, maxResults: 50 });
    const moderator = page.items.find(
      (item) => item.moderatorId === moderatorId,
    );
    if (!moderator) {
      throw new YouTubeProviderError(
        "not_found",
        "The moderator is not present in the current owned live chat.",
        404,
        false,
      );
    }
    confirmation(
      moderator.moderatorId,
      request.confirmModeratorId,
      "Moderator",
    );
    const url = new URL(`${DATA_API}/liveChat/moderators`);
    url.searchParams.set("id", moderator.moderatorId);
    await this.api(
      request,
      "liveChatModerators.delete.owner",
      WRITE_QUOTA_COST,
      url,
      "DELETE",
    );
    return { deletedModeratorId: moderator.moderatorId };
  }

  async insertBan(
    request: LiveChatBanInsertRequest,
  ): Promise<{
    readonly banId: string;
    readonly liveChatId: string;
    readonly bannedChannelId: string;
    readonly type: LiveChatBanType;
    readonly durationSeconds?: number;
  }> {
    const { liveChatId } = await this.ownedChat(request, true);
    const bannedChannelId = strictIdentifier(
      request.bannedChannelId,
      CHANNEL_ID,
      "banned channel",
    );
    if (request.type !== "permanent" && request.type !== "temporary") {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported live chat ban type is required.",
        400,
        false,
      );
    }
    let durationSeconds: number | undefined;
    if (request.type === "temporary") {
      durationSeconds = request.durationSeconds;
      if (
        !Number.isSafeInteger(durationSeconds) ||
        (durationSeconds ?? 0) < 60 ||
        (durationSeconds ?? 0) > 86_400
      ) {
        throw new YouTubeProviderError(
          "bad_request",
          "A temporary live chat ban must last between 60 and 86400 seconds.",
          400,
          false,
        );
      }
    } else if (request.durationSeconds !== undefined) {
      throw new YouTubeProviderError(
        "bad_request",
        "A permanent live chat ban cannot include a duration.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/liveChat/bans`);
    url.searchParams.set("part", "snippet");
    const body = await this.api(
      request,
      "liveChatBans.insert.owner",
      WRITE_QUOTA_COST,
      url,
      "POST",
      {
        snippet: {
          liveChatId,
          type: request.type,
          bannedUserDetails: { channelId: bannedChannelId },
          ...(durationSeconds === undefined
            ? {}
            : { banDurationSeconds: String(durationSeconds) }),
        },
      },
    );
    const ban = parseJson<ApiLiveChatBan>(body);
    const banId = providerIdentifier(
      ban.id,
      RESOURCE_ID,
      "YouTube returned an invalid live chat ban.",
    );
    const returnedChatId = providerIdentifier(
      ban.snippet?.liveChatId,
      RESOURCE_ID,
      "YouTube returned invalid live chat ban attribution.",
    );
    const returnedProfile = providerProfile(
      ban.snippet?.bannedUserDetails,
      "YouTube returned invalid banned channel details.",
    );
    if (
      returnedChatId !== liveChatId ||
      returnedProfile.channelId !== bannedChannelId ||
      ban.snippet?.type !== request.type
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an inconsistent live chat ban.",
        502,
        false,
      );
    }
    return {
      banId,
      liveChatId,
      bannedChannelId,
      type: request.type,
      ...(durationSeconds === undefined ? {} : { durationSeconds }),
    };
  }

  async deleteBan(
    request: LiveChatBanDeleteRequest,
  ): Promise<{ readonly deletedBanId: string }> {
    await this.ownedChat(request, true);
    const banId = strictIdentifier(request.banId, RESOURCE_ID, "ban");
    confirmation(banId, request.confirmBanId, "Ban");
    const url = new URL(`${DATA_API}/liveChat/bans`);
    url.searchParams.set("id", banId);
    await this.api(
      request,
      "liveChatBans.delete.ownerConfirmed",
      WRITE_QUOTA_COST,
      url,
      "DELETE",
    );
    return { deletedBanId: banId };
  }

  async listSuperChatEvents(
    request: LiveSuperChatListRequest,
  ): Promise<{
    readonly eligibility: "provider_approved_channel_only";
    readonly items: readonly {
      readonly eventId: string;
      readonly supporterChannelId: string;
      readonly supporterDisplayName: string;
      readonly supporterProfileImageUrl?: string;
      readonly createdAt: string;
      readonly amountMicros: string;
      readonly currency: string;
      readonly displayString: string;
      readonly commentText: string;
      readonly isSuperStickerEvent: boolean;
    }[];
    readonly nextPageToken?: string;
  }> {
    const url = new URL(`${DATA_API}/superChatEvents`);
    url.searchParams.set("part", "id,snippet");
    url.searchParams.set("maxResults", String(pageSize(request.maxResults)));
    const token = pageToken(request.pageToken);
    if (token !== undefined) url.searchParams.set("pageToken", token);
    if (request.language !== undefined) {
      const language = request.language.trim();
      if (!/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8}){0,6}$/u.test(language)) {
        throw new YouTubeProviderError(
          "bad_request",
          "A valid display language is required.",
          400,
          false,
        );
      }
      url.searchParams.set("hl", language);
    }
    const body = await this.api(
      request,
      "superChatEvents.list.eligibilityGatedOwner",
      READ_QUOTA_COST,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiSuperChatEvent>>(body);
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      eligibility: "provider_approved_channel_only",
      items: (envelope.items ?? []).map((item) => {
        const supporter = providerProfile(
          item.snippet?.supporterDetails,
          "YouTube returned invalid Super Chat supporter details.",
        );
        const amountMicros = providerIdentifier(
          item.snippet?.amountMicros,
          /^\d+$/u,
          "YouTube returned an invalid Super Chat amount.",
        );
        const currency = providerIdentifier(
          item.snippet?.currency,
          CURRENCY,
          "YouTube returned an invalid Super Chat currency.",
        );
        return {
          eventId: providerIdentifier(
            item.id,
            RESOURCE_ID,
            "YouTube returned an invalid Super Chat event.",
          ),
          supporterChannelId: supporter.channelId,
          supporterDisplayName: supporter.displayName,
          ...(supporter.profileImageUrl === undefined
            ? {}
            : { supporterProfileImageUrl: supporter.profileImageUrl }),
          createdAt: providerDate(
            item.snippet?.createdAt,
            "YouTube returned an invalid Super Chat time.",
          ),
          amountMicros,
          currency,
          displayString: providerText(
            item.snippet?.displayString,
            "YouTube returned an invalid Super Chat display amount.",
          ),
          commentText: providerTextAllowEmpty(
            item.snippet?.commentText ?? "",
            "YouTube returned an invalid Super Chat comment.",
          ),
          isSuperStickerEvent: providerBoolean(
            item.snippet?.isSuperStickerEvent,
            "YouTube returned an invalid Super Chat event type.",
          ),
        };
      }),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async listMembers(
    request: LiveMemberListRequest,
  ): Promise<{
    readonly eligibility:
      "youtube_representative_and_memberships_enabled_required";
    readonly items: readonly {
      readonly creatorChannelId: string;
      readonly memberChannelId?: string;
      readonly memberDisplayName?: string;
      readonly memberProfileImageUrl?: string;
      readonly highestAccessibleLevelId: string;
      readonly highestAccessibleLevelDisplayName: string;
      readonly accessibleLevelIds: readonly string[];
    }[];
    readonly nextPageToken?: string;
  }> {
    if (request.mode !== "all_current" && request.mode !== "updates") {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported membership list mode is required.",
        400,
        false,
      );
    }
    const owner = expectedChannelId(request.expectedChannelId);
    const url = new URL(`${DATA_API}/members`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("mode", request.mode);
    url.searchParams.set("maxResults", String(pageSize(request.maxResults)));
    const token = pageToken(request.pageToken);
    if (token !== undefined) url.searchParams.set("pageToken", token);
    if (request.memberChannelId !== undefined) {
      url.searchParams.set(
        "filterByMemberChannelId",
        strictIdentifier(
          request.memberChannelId,
          CHANNEL_ID,
          "member channel",
        ),
      );
    }
    if (request.levelId !== undefined) {
      url.searchParams.set(
        "hasAccessToLevel",
        strictIdentifier(request.levelId, RESOURCE_ID, "membership level"),
      );
    }
    const body = await this.api(
      request,
      "members.list.explicitEligibilityOwner",
      READ_QUOTA_COST,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiMember>>(body);
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      eligibility:
        "youtube_representative_and_memberships_enabled_required",
      items: (envelope.items ?? []).map((item) => {
        const creatorChannelId = providerIdentifier(
          item.snippet?.creatorChannelId,
          CHANNEL_ID,
          "YouTube returned invalid membership attribution.",
        );
        if (creatorChannelId !== owner) {
          throw new YouTubeProviderError(
            "permission_denied",
            "YouTube returned a membership from another creator channel.",
            403,
            false,
          );
        }
        const profile = item.snippet?.memberDetails;
        const member =
          profile?.channelId === undefined
            ? undefined
            : providerProfile(
                profile,
                "YouTube returned invalid member details.",
              );
        const levelId = providerIdentifier(
          item.snippet?.membershipsDetails?.highestAccessibleLevel,
          RESOURCE_ID,
          "YouTube returned an invalid membership level.",
        );
        const accessible = (
          item.snippet?.membershipsDetails?.accessibleLevels ?? []
        ).map((value) =>
          providerIdentifier(
            value,
            RESOURCE_ID,
            "YouTube returned an invalid accessible membership level.",
          ),
        );
        return {
          creatorChannelId,
          ...(member === undefined
            ? {}
            : {
                memberChannelId: member.channelId,
                memberDisplayName: member.displayName,
                ...(member.profileImageUrl === undefined
                  ? {}
                  : { memberProfileImageUrl: member.profileImageUrl }),
              }),
          highestAccessibleLevelId: levelId,
          highestAccessibleLevelDisplayName: providerText(
            item.snippet?.membershipsDetails
              ?.highestAccessibleLevelDisplayName,
            "YouTube returned an invalid membership level name.",
          ),
          accessibleLevelIds: accessible,
        };
      }),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async listMembershipLevels(
    request: LiveOwnerRequest,
  ): Promise<{
    readonly eligibility:
      "youtube_representative_and_memberships_enabled_required";
    readonly items: readonly {
      readonly levelId: string;
      readonly creatorChannelId: string;
      readonly displayName: string;
    }[];
  }> {
    const owner = expectedChannelId(request.expectedChannelId);
    const url = new URL(`${DATA_API}/membershipsLevels`);
    url.searchParams.set("part", "id,snippet");
    const body = await this.api(
      request,
      "membershipsLevels.list.explicitEligibilityOwner",
      READ_QUOTA_COST,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiMembershipLevel>>(body);
    return {
      eligibility:
        "youtube_representative_and_memberships_enabled_required",
      items: (envelope.items ?? []).map((item) => {
        const creatorChannelId = providerIdentifier(
          item.snippet?.creatorChannelId,
          CHANNEL_ID,
          "YouTube returned invalid membership-level attribution.",
        );
        if (creatorChannelId !== owner) {
          throw new YouTubeProviderError(
            "permission_denied",
            "YouTube returned a membership level from another channel.",
            403,
            false,
          );
        }
        return {
          levelId: providerIdentifier(
            item.id,
            RESOURCE_ID,
            "YouTube returned an invalid membership level.",
          ),
          creatorChannelId,
          displayName: providerText(
            item.snippet?.levelDetails?.displayName,
            "YouTube returned an invalid membership level name.",
          ),
        };
      }),
    };
  }
}
