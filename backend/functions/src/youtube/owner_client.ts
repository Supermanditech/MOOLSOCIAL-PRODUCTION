import { assertProviderResponse, YouTubeProviderError } from "./errors.js";
import type { Clock, YouTubeQuotaPort } from "./ports.js";
import { systemClock } from "./ports.js";
import { safeYouTubeProviderPlainText } from "./provider_content.js";
import { YouTubeCreatorAssetsClient } from "./creator_assets_client.js";
import { YouTubeLiveClient } from "./live_client.js";
import type {
  HttpTransport,
  YouTubeChannelIdentity,
  YouTubeOwnerAnalyticsPreset,
  YouTubeOwnerAnalyticsResult,
  YouTubeOwnerPlaylist,
  YouTubeOwnerPlaylistsPage,
  YouTubeOwnerSubscription,
  YouTubeOwnerSubscriptionOrder,
  YouTubeOwnerSubscriptionsPage,
  YouTubeOwnerVideo,
  YouTubeOwnerVideosPage,
  YouTubePublicComment,
  YouTubeResumableUploadSession,
  YouTubeThumbnail,
  YouTubeUploadMetadata,
  YouTubeVideoSummary,
} from "./types.js";
import { safeYouTubeProviderImageUrl } from "./provider_content.js";

const DATA_API = "https://www.googleapis.com/youtube/v3";
const UPLOAD_API = "https://www.googleapis.com/upload/youtube/v3";
const ANALYTICS_API = "https://youtubeanalytics.googleapis.com/v2/reports";
const VIDEO_ID = /^[A-Za-z0-9_-]{6,20}$/;
const PAGE_TOKEN = /^[A-Za-z0-9_-]{1,256}$/;
const RESOURCE_ID = /^[A-Za-z0-9_-]{1,256}$/;
const CHANNEL_ID = /^[A-Za-z0-9_-]{6,64}$/;
const DEFAULT_OWNER_PAGE_SIZE = 25;
const MAX_OWNER_PAGE_SIZE = 50;
const ANALYTICS_PAGE_SIZE = 25;
const MAX_ANALYTICS_RANGE_DAYS = 366;

interface ApiVideo {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly description?: string;
    readonly channelId?: string;
    readonly channelTitle?: string;
    readonly publishedAt?: string;
    readonly categoryId?: string;
    readonly tags?: readonly string[];
    readonly thumbnails?: Record<
      string,
      { readonly url?: string; readonly width?: number; readonly height?: number }
    >;
  };
  readonly contentDetails?: { readonly duration?: string };
  readonly statistics?: {
    readonly viewCount?: string;
    readonly likeCount?: string;
    readonly commentCount?: string;
  };
  readonly status?: {
    readonly embeddable?: boolean;
    readonly privacyStatus?: string;
    readonly uploadStatus?: string;
  };
}

interface ApiThumbnail {
  readonly url?: string;
  readonly width?: number;
  readonly height?: number;
}

interface ApiChannel {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly thumbnails?: Record<string, ApiThumbnail>;
  };
  readonly contentDetails?: {
    readonly relatedPlaylists?: {
      readonly uploads?: string;
    };
  };
}

interface ApiPlaylistItem {
  readonly id?: string;
  readonly snippet?: {
    readonly publishedAt?: string;
    readonly position?: number;
    readonly playlistId?: string;
    readonly channelId?: string;
    readonly resourceId?: {
      readonly videoId?: string;
    };
  };
  readonly contentDetails?: {
    readonly videoId?: string;
  };
}

interface ApiSubscription {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly description?: string;
    readonly publishedAt?: string;
    readonly channelId?: string;
    readonly resourceId?: {
      readonly channelId?: string;
    };
    readonly thumbnails?: Record<string, ApiThumbnail>;
  };
}

interface ApiComment {
  readonly id?: string;
  readonly snippet?: {
    readonly textDisplay?: string;
    readonly textOriginal?: string;
    readonly authorDisplayName?: string;
    readonly authorProfileImageUrl?: string;
    readonly authorChannelId?: { readonly value?: string };
    readonly channelId?: string;
    readonly videoId?: string;
    readonly parentId?: string;
    readonly likeCount?: number;
    readonly publishedAt?: string;
    readonly updatedAt?: string;
  };
}

interface ApiCommentThread {
  readonly id?: string;
  readonly snippet?: {
    readonly channelId?: string;
    readonly videoId?: string;
    readonly topLevelComment?: ApiComment;
  };
}

interface ApiRating {
  readonly videoId?: string;
  readonly rating?: string;
}

interface ApiPlaylist {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly description?: string;
    readonly publishedAt?: string;
    readonly channelId?: string;
    readonly channelTitle?: string;
    readonly thumbnails?: Record<string, ApiThumbnail>;
  };
  readonly contentDetails?: {
    readonly itemCount?: number;
  };
  readonly status?: {
    readonly privacyStatus?: string;
  };
}

interface ListEnvelope<T> {
  readonly items?: readonly T[];
  readonly nextPageToken?: string;
}

interface AnalyticsEnvelope {
  readonly columnHeaders?: readonly {
    readonly name?: string;
    readonly columnType?: "DIMENSION" | "METRIC";
  }[];
  readonly rows?: readonly (readonly unknown[])[];
}

export interface BeginPrivateUploadRequest {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly contentType: string;
  readonly contentLength: number;
  readonly metadata: YouTubeUploadMetadata;
}

export interface OwnerPageQuery {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly expectedChannelId: string;
  readonly expectedChannelTitle: string;
  readonly pageToken?: string;
  readonly maxResults?: number;
  readonly order?: YouTubeOwnerSubscriptionOrder;
}

export interface AnalyticsPresetQuery {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly startDate: string;
  readonly endDate: string;
  readonly preset: YouTubeOwnerAnalyticsPreset;
  readonly videoId?: string;
  readonly startIndex?: number;
}

export interface CompletedUploadRequest {
  readonly accessToken: string;
  readonly sessionUrl: string;
  readonly contentLength: number;
}

export interface OwnerActionRequest {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly expectedChannelId: string;
}

export interface OwnerVideoRatingRequest extends OwnerActionRequest {
  readonly videoId: string;
}

export interface OwnerSetVideoRatingRequest
  extends OwnerVideoRatingRequest {
  readonly rating: "like" | "dislike";
}

export interface OwnerCreateCommentRequest extends OwnerActionRequest {
  readonly videoId: string;
  readonly text: string;
}

export interface OwnerCreateReplyRequest extends OwnerActionRequest {
  readonly parentCommentId: string;
  readonly text: string;
}

export interface OwnerUpdateCommentRequest extends OwnerActionRequest {
  readonly commentId: string;
  readonly text: string;
}

export interface OwnerCommentMutationRequest extends OwnerActionRequest {
  readonly commentId: string;
}

export interface OwnerModerateCommentRequest
  extends OwnerCommentMutationRequest {
  readonly moderationStatus:
    | "published"
    | "heldForReview"
    | "rejected";
  readonly banAuthor?: boolean;
}

export interface OwnerCreateSubscriptionRequest
  extends OwnerActionRequest {
  readonly channelId: string;
}

export interface OwnerDeleteSubscriptionRequest
  extends OwnerActionRequest {
  readonly subscriptionId: string;
}

export interface OwnerCreatePlaylistRequest extends OwnerActionRequest {
  readonly title: string;
  readonly description: string;
  readonly privacyStatus: "private" | "unlisted" | "public";
}

export interface OwnerUpdatePlaylistRequest
  extends OwnerCreatePlaylistRequest {
  readonly playlistId: string;
}

export interface OwnerDeletePlaylistRequest extends OwnerActionRequest {
  readonly playlistId: string;
}

export interface OwnerCreatePlaylistItemRequest
  extends OwnerActionRequest {
  readonly playlistId: string;
  readonly videoId: string;
  readonly position?: number;
}

export interface OwnerReorderPlaylistItemRequest
  extends OwnerActionRequest {
  readonly playlistItemId: string;
  readonly position: number;
}

export interface OwnerDeletePlaylistItemRequest
  extends OwnerActionRequest {
  readonly playlistItemId: string;
}

export interface OwnerUpdateVideoMetadataRequest
  extends OwnerActionRequest {
  readonly videoId: string;
  readonly title: string;
  readonly description: string;
  readonly categoryId: string;
  readonly tags?: readonly string[];
}

export interface OwnerDeleteVideoRequest extends OwnerActionRequest {
  readonly videoId: string;
  readonly confirmVideoId: string;
}

export interface YouTubeOwnerCommentMutation {
  readonly threadId?: string;
  readonly comment: YouTubePublicComment;
}

export interface YouTubeOwnerSubscriptionMutation {
  readonly subscriptionId: string;
  readonly actorChannelId: string;
  readonly targetChannelId: string;
}

export interface YouTubeOwnerPlaylistMutation {
  readonly playlistId: string;
  readonly actorChannelId: string;
  readonly title: string;
  readonly description: string;
  readonly privacyStatus: "private" | "public" | "unlisted";
}

export interface YouTubeOwnerPlaylistItemMutation {
  readonly playlistItemId: string;
  readonly playlistId: string;
  readonly videoId: string;
  readonly position: number;
}

export interface YouTubeOwnerClientOptions {
  readonly transport: HttpTransport;
  readonly quota: YouTubeQuotaPort;
  readonly clock?: Clock;
}

function parseJson<T>(body: string): T {
  try {
    return JSON.parse(body) as T;
  } catch {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned an unreadable response.",
      502,
    );
  }
}

function validDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return (
    Number.isFinite(parsed.getTime()) &&
    parsed.toISOString().slice(0, 10) === value
  );
}

function dateRangeDays(startDate: string, endDate: string): number {
  const start = Date.parse(`${startDate}T00:00:00.000Z`);
  const end = Date.parse(`${endDate}T00:00:00.000Z`);
  return Math.floor((end - start) / (24 * 60 * 60 * 1000)) + 1;
}

function ownerPageSize(value: number | undefined): number {
  if (value === undefined) return DEFAULT_OWNER_PAGE_SIZE;
  if (
    !Number.isSafeInteger(value) ||
    value < 1 ||
    value > MAX_OWNER_PAGE_SIZE
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      `maxResults must be between 1 and ${MAX_OWNER_PAGE_SIZE}.`,
      400,
    );
  }
  return value;
}

function subscriptionOrder(
  value: YouTubeOwnerSubscriptionOrder | undefined,
): YouTubeOwnerSubscriptionOrder {
  const order = value ?? "relevance";
  if (
    order !== "alphabetical" &&
    order !== "relevance" &&
    order !== "unread"
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "A supported subscription order is required.",
      400,
    );
  }
  return order;
}

function analyticsStartIndex(value: number | undefined): number | undefined {
  if (value === undefined) return undefined;
  if (!Number.isSafeInteger(value) || value < 1) {
    throw new YouTubeProviderError(
      "bad_request",
      "Analytics startIndex must be a positive integer.",
      400,
    );
  }
  return value;
}

function pageToken(value: string | undefined): string | undefined {
  const clean = value?.trim();
  if (!clean) return undefined;
  if (!PAGE_TOKEN.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      "Invalid page token.",
      400,
    );
  }
  return clean;
}

function providerPageToken(value: unknown): string | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== "string" || !PAGE_TOKEN.test(value)) {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned an invalid page token.",
      502,
    );
  }
  return value;
}

function thumbnail(
  values: Record<string, ApiThumbnail> | undefined,
): YouTubeThumbnail | undefined {
  if (!values) return undefined;
  const image =
    values.maxres ??
    values.standard ??
    values.high ??
    values.medium ??
    values.default;
  if (!image?.url) return undefined;
  if (
    (image.width !== undefined &&
      (!Number.isSafeInteger(image.width) || image.width < 1)) ||
    (image.height !== undefined &&
      (!Number.isSafeInteger(image.height) || image.height < 1))
  ) {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned an invalid thumbnail.",
      502,
    );
  }
  return {
    url: safeYouTubeProviderImageUrl(
      image.url,
      "YouTube returned an invalid thumbnail.",
    ),
    ...(image.width === undefined ? {} : { width: image.width }),
    ...(image.height === undefined ? {} : { height: image.height }),
  };
}

function strictChannelId(value: string): string {
  const clean = value.trim();
  if (!CHANNEL_ID.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid connected channel identifier is required.",
      400,
    );
  }
  return clean;
}

function strictResourceId(value: string, label: string): string {
  const clean = value.trim();
  if (!RESOURCE_ID.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      `A valid ${label} identifier is required.`,
      400,
    );
  }
  return clean;
}

function actionText(
  value: string,
  label: string,
  maximumLength: number,
): string {
  const clean = value
    .replace(/\r\n?/gu, "\n")
    .normalize("NFC");
  if (!clean.trim() || clean.length > maximumLength) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} must contain between 1 and ${maximumLength} characters.`,
      400,
    );
  }
  if (/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/u.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} contains unsupported characters.`,
      400,
    );
  }
  return clean;
}

function actionDescription(value: string, maximumLength: number): string {
  const clean = value.replace(/\r\n?/gu, "\n").normalize("NFC");
  if (
    clean.length > maximumLength ||
    /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/u.test(clean)
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      `Description cannot exceed ${maximumLength} characters or contain unsupported characters.`,
      400,
    );
  }
  return clean;
}

function videoTags(values: readonly string[] | undefined): readonly string[] {
  if (values === undefined) return [];
  if (values.length > 100) {
    throw new YouTubeProviderError(
      "bad_request",
      "Too many video tags were supplied.",
      400,
    );
  }
  const normalized = values.map((value) =>
    actionText(value, "Video tag", 500).trim(),
  );
  if (normalized.join(",").length > 500) {
    throw new YouTubeProviderError(
      "bad_request",
      "Video tags exceed YouTube's metadata limit.",
      400,
    );
  }
  return normalized;
}

function position(value: number | undefined): number | undefined {
  if (value === undefined) return undefined;
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new YouTubeProviderError(
      "bad_request",
      "Playlist position must be a non-negative whole number.",
      400,
    );
  }
  return value;
}

function expectedChannel(value: string): string {
  return strictChannelId(value);
}

function requireActorChannel(
  actual: unknown,
  expected: string,
  message: string,
): string {
  const actualId = providerIdentifier(actual, CHANNEL_ID, message);
  if (actualId !== expected) {
    throw new YouTubeProviderError("permission_denied", message, 403);
  }
  return actualId;
}

function strictVideoId(value: string): string {
  const clean = value.trim();
  if (!VIDEO_ID.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid video identifier is required.",
      400,
    );
  }
  return clean;
}

function requiredText(
  value: unknown,
  message: string,
): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
    );
  }
  return value;
}

function providerIdentifier(
  value: unknown,
  pattern: RegExp,
  message: string,
): string {
  const clean = requiredText(value, message).trim();
  if (!pattern.test(clean)) {
    throw new YouTubeProviderError("provider_rejected", message, 502);
  }
  return clean;
}

function providerTimestamp(value: unknown, message: string): string {
  const timestamp = requiredText(value, message).trim();
  if (!Number.isFinite(Date.parse(timestamp))) {
    throw new YouTubeProviderError("provider_rejected", message, 502);
  }
  return timestamp;
}

function providerNonNegativeInteger(
  value: unknown,
  message: string,
): number {
  if (!Number.isSafeInteger(value) || (value as number) < 0) {
    throw new YouTubeProviderError("provider_rejected", message, 502);
  }
  return value as number;
}

function privacyStatus(
  value: unknown,
): "private" | "public" | "unlisted" {
  if (value === "private" || value === "public" || value === "unlisted") {
    return value;
  }
  throw new YouTubeProviderError(
    "provider_rejected",
    "YouTube returned an invalid playlist privacy state.",
    502,
  );
}

function requestedPlaylistPrivacy(
  value: unknown,
): "private" | "public" | "unlisted" {
  if (value === "private" || value === "public" || value === "unlisted") {
    return value;
  }
  throw new YouTubeProviderError(
    "bad_request",
    "A supported playlist privacy state is required.",
    400,
  );
}

function validateMetadata(metadata: YouTubeUploadMetadata): void {
  const title = metadata.title.trim();
  if (title.length < 1 || title.length > 100) {
    throw new YouTubeProviderError(
      "bad_request",
      "Video title must contain between 1 and 100 characters.",
      400,
    );
  }
  if (metadata.description.length > 5000) {
    throw new YouTubeProviderError(
      "bad_request",
      "Video description is too long.",
      400,
    );
  }
  if (!/^\d{1,3}$/.test(metadata.categoryId)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid YouTube category is required.",
      400,
    );
  }
}

function validateMedia(contentType: string, contentLength: number): void {
  if (
    contentType !== "application/octet-stream" &&
    !/^video\/[A-Za-z0-9.+-]+$/.test(contentType)
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "A supported video content type is required.",
      400,
    );
  }
  if (!Number.isSafeInteger(contentLength) || contentLength < 1) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid video size is required.",
      400,
    );
  }
  const maxBytes = 256 * 1024 * 1024 * 1024;
  if (contentLength > maxBytes) {
    throw new YouTubeProviderError(
      "bad_request",
      "The video exceeds YouTube's upload size limit.",
      400,
    );
  }
}

function isoAfter(clock: Clock, milliseconds: number): string {
  return new Date(clock.now().getTime() + milliseconds).toISOString();
}

function uploadSessionUrl(value: string): string {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new YouTubeProviderError(
      "provider_rejected",
      "The YouTube upload session is invalid.",
      502,
    );
  }
  if (
    url.protocol !== "https:" ||
    url.hostname !== "www.googleapis.com" ||
    url.pathname !== "/upload/youtube/v3/videos" ||
    !url.searchParams.get("upload_id")
  ) {
    throw new YouTubeProviderError(
      "provider_rejected",
      "The YouTube upload session is invalid.",
      502,
    );
  }
  return url.toString();
}

export class YouTubeOwnerClient {
  private readonly clock: Clock;
  readonly creatorAssets: YouTubeCreatorAssetsClient;
  readonly live: YouTubeLiveClient;

  constructor(private readonly options: YouTubeOwnerClientOptions) {
    this.clock = options.clock ?? systemClock;
    this.creatorAssets = new YouTubeCreatorAssetsClient(options);
    this.live = new YouTubeLiveClient(options);
  }

  private async ownerApi(
    request: OwnerActionRequest,
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

  private mapOwnerComment(
    value: ApiComment,
    ownershipMessage: string,
  ): YouTubePublicComment {
    const snippet = value.snippet;
    const commentId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid comment.",
    );
    const associatedChannelId = providerIdentifier(
      snippet?.channelId,
      CHANNEL_ID,
      "YouTube returned an invalid comment.",
    );
    const authorChannelId = providerIdentifier(
      snippet?.authorChannelId?.value,
      CHANNEL_ID,
      ownershipMessage,
    );
    const authorProfileImageUrl =
      snippet?.authorProfileImageUrl === undefined
        ? undefined
        : safeYouTubeProviderImageUrl(
            snippet.authorProfileImageUrl,
            "YouTube returned an invalid comment author image.",
          );
    const publishedAt = providerTimestamp(
      snippet?.publishedAt,
      "YouTube returned an invalid comment.",
    );
    const updatedAt = providerTimestamp(
      snippet?.updatedAt,
      "YouTube returned an invalid comment.",
    );
    const parentId =
      snippet?.parentId === undefined
        ? undefined
        : providerIdentifier(
            snippet.parentId,
            RESOURCE_ID,
            "YouTube returned an invalid comment.",
          );
    return {
      commentId,
      textDisplay: safeYouTubeProviderPlainText(
        snippet?.textDisplay ?? snippet?.textOriginal,
        "YouTube returned an invalid comment.",
      ),
      textFormat: "plainText",
      author: {
        displayName: requiredText(
          snippet?.authorDisplayName,
          "YouTube returned an invalid comment.",
        ),
        channelId: authorChannelId,
        ...(authorProfileImageUrl === undefined
          ? {}
          : { profileImageUrl: authorProfileImageUrl }),
      },
      associatedChannelId,
      likeCount: providerNonNegativeInteger(
        snippet?.likeCount,
        "YouTube returned an invalid comment.",
      ),
      publishedAt,
      updatedAt,
      ...(parentId === undefined ? {} : { parentId }),
    };
  }

  private async comment(
    request: OwnerCommentMutationRequest,
  ): Promise<ApiComment> {
    const commentId = strictResourceId(request.commentId, "comment");
    const url = new URL(`${DATA_API}/comments`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("id", commentId);
    url.searchParams.set("textFormat", "plainText");
    const body = await this.ownerApi(
      request,
      "comments.list.ownerPreflight",
      1,
      url,
    );
    const comment = parseJson<ListEnvelope<ApiComment>>(body).items?.[0];
    if (!comment) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube comment is unavailable.",
        404,
      );
    }
    return comment;
  }

  private async playlist(
    request: OwnerDeletePlaylistRequest,
  ): Promise<ApiPlaylist> {
    const playlistId = strictResourceId(request.playlistId, "playlist");
    const url = new URL(`${DATA_API}/playlists`);
    url.searchParams.set("part", "snippet,status");
    url.searchParams.set("id", playlistId);
    const body = await this.ownerApi(
      request,
      "playlists.list.ownerPreflight",
      1,
      url,
    );
    const playlist = parseJson<ListEnvelope<ApiPlaylist>>(body).items?.[0];
    if (!playlist) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube playlist is unavailable.",
        404,
      );
    }
    requireActorChannel(
      playlist.snippet?.channelId,
      expectedChannel(request.expectedChannelId),
      "The YouTube playlist does not belong to the connected channel.",
    );
    return playlist;
  }

  private async playlistItem(
    request: OwnerDeletePlaylistItemRequest,
  ): Promise<ApiPlaylistItem> {
    const playlistItemId = strictResourceId(
      request.playlistItemId,
      "playlist item",
    );
    const url = new URL(`${DATA_API}/playlistItems`);
    url.searchParams.set("part", "snippet,contentDetails");
    url.searchParams.set("id", playlistItemId);
    const body = await this.ownerApi(
      request,
      "playlistItems.list.ownerPreflight",
      1,
      url,
    );
    const item = parseJson<ListEnvelope<ApiPlaylistItem>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube playlist item is unavailable.",
        404,
      );
    }
    const playlistId = providerIdentifier(
      item.snippet?.playlistId,
      RESOURCE_ID,
      "YouTube returned an invalid playlist item.",
    );
    await this.playlist({ ...request, playlistId });
    return item;
  }

  private async subscription(
    request: OwnerDeleteSubscriptionRequest,
  ): Promise<ApiSubscription> {
    const subscriptionId = strictResourceId(
      request.subscriptionId,
      "subscription",
    );
    const url = new URL(`${DATA_API}/subscriptions`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("id", subscriptionId);
    const body = await this.ownerApi(
      request,
      "subscriptions.list.ownerPreflight",
      1,
      url,
    );
    const subscription =
      parseJson<ListEnvelope<ApiSubscription>>(body).items?.[0];
    if (!subscription) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube subscription is unavailable.",
        404,
      );
    }
    requireActorChannel(
      subscription.snippet?.channelId,
      expectedChannel(request.expectedChannelId),
      "The YouTube subscription does not belong to the connected channel.",
    );
    return subscription;
  }

  async connectedChannel(
    principal: string,
    requestId: string,
    accessToken: string,
  ): Promise<YouTubeChannelIdentity> {
    await this.options.quota.reserve({
      principal,
      bucket: "general",
      amount: 1,
      operation: "channels.list.mine.owner",
      requestId,
    });
    const url = new URL(`${DATA_API}/channels`);
    url.searchParams.set("part", "snippet,contentDetails");
    url.searchParams.set("mine", "true");
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { authorization: `Bearer ${accessToken}` },
    });
    assertProviderResponse(response.status, response.body);
    const items = parseJson<ListEnvelope<ApiChannel>>(response.body).items ?? [];
    if (items.length !== 1) {
      throw new YouTubeProviderError(
        "authentication_required",
        "Reconnect the selected YouTube channel.",
        401,
      );
    }
    const item = items[0]!;
    const channelId = providerIdentifier(
      item.id,
      /^[A-Za-z0-9_-]{6,64}$/,
      "YouTube returned an invalid connected channel.",
    );
    const title = requiredText(
      item.snippet?.title,
      "YouTube returned an invalid connected channel.",
    );
    const uploadsPlaylistId =
      item.contentDetails?.relatedPlaylists?.uploads?.trim();
    const image = thumbnail(item.snippet?.thumbnails);
    return {
      channelId,
      title,
      ...(uploadsPlaylistId ? { uploadsPlaylistId } : {}),
      ...(image === undefined ? {} : { thumbnail: image }),
    };
  }

  async ownerGetRating(
    request: OwnerVideoRatingRequest,
  ): Promise<{ readonly videoId: string; readonly rating: "like" | "dislike" | "none" }> {
    expectedChannel(request.expectedChannelId);
    const videoId = strictVideoId(request.videoId);
    const url = new URL(`${DATA_API}/videos/getRating`);
    url.searchParams.set("id", videoId);
    const body = await this.ownerApi(
      request,
      "videos.getRating.owner",
      1,
      url,
    );
    const item = parseJson<ListEnvelope<ApiRating>>(body).items?.[0];
    if (
      !item ||
      item.videoId !== videoId ||
      (item.rating !== "like" &&
        item.rating !== "dislike" &&
        item.rating !== "none")
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid video rating.",
        502,
      );
    }
    return { videoId, rating: item.rating };
  }

  async ownerSetRating(
    request: OwnerSetVideoRatingRequest,
  ): Promise<{ readonly videoId: string; readonly rating: "like" | "dislike" }> {
    expectedChannel(request.expectedChannelId);
    const videoId = strictVideoId(request.videoId);
    if (request.rating !== "like" && request.rating !== "dislike") {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported YouTube rating is required.",
        400,
      );
    }
    const url = new URL(`${DATA_API}/videos/rate`);
    url.searchParams.set("id", videoId);
    url.searchParams.set("rating", request.rating);
    await this.ownerApi(request, "videos.rate.owner", 50, url, "POST");
    return { videoId, rating: request.rating };
  }

  async ownerRemoveRating(
    request: OwnerVideoRatingRequest,
  ): Promise<{ readonly videoId: string; readonly rating: "none" }> {
    expectedChannel(request.expectedChannelId);
    const videoId = strictVideoId(request.videoId);
    const url = new URL(`${DATA_API}/videos/rate`);
    url.searchParams.set("id", videoId);
    url.searchParams.set("rating", "none");
    await this.ownerApi(request, "videos.rate.remove.owner", 50, url, "POST");
    return { videoId, rating: "none" };
  }

  async ownerCreateComment(
    request: OwnerCreateCommentRequest,
  ): Promise<YouTubeOwnerCommentMutation> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const videoId = strictVideoId(request.videoId);
    const commentText = actionText(request.text, "Comment", 10_000);
    const url = new URL(`${DATA_API}/commentThreads`);
    url.searchParams.set("part", "snippet");
    const body = await this.ownerApi(
      request,
      "commentThreads.insert.owner",
      50,
      url,
      "POST",
      {
        snippet: {
          videoId,
          topLevelComment: { snippet: { textOriginal: commentText } },
        },
      },
    );
    const thread = parseJson<ApiCommentThread>(body);
    const threadId = providerIdentifier(
      thread.id,
      RESOURCE_ID,
      "YouTube returned an invalid comment thread.",
    );
    if (thread.snippet?.videoId !== videoId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned the comment on a different video.",
        502,
      );
    }
    const comment = this.mapOwnerComment(
      thread.snippet?.topLevelComment ?? {},
      "YouTube did not attribute the comment to the connected channel.",
    );
    if (comment.author.channelId !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "YouTube did not attribute the comment to the connected channel.",
        403,
      );
    }
    return { threadId, comment };
  }

  async ownerCreateReply(
    request: OwnerCreateReplyRequest,
  ): Promise<YouTubeOwnerCommentMutation> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const parentCommentId = strictResourceId(
      request.parentCommentId,
      "parent comment",
    );
    const commentText = actionText(request.text, "Reply", 10_000);
    const url = new URL(`${DATA_API}/comments`);
    url.searchParams.set("part", "snippet");
    const body = await this.ownerApi(
      request,
      "comments.insert.reply.owner",
      50,
      url,
      "POST",
      { snippet: { parentId: parentCommentId, textOriginal: commentText } },
    );
    const comment = this.mapOwnerComment(
      parseJson<ApiComment>(body),
      "YouTube did not attribute the reply to the connected channel.",
    );
    if (
      comment.author.channelId !== actorChannelId ||
      comment.parentId !== parentCommentId
    ) {
      throw new YouTubeProviderError(
        "permission_denied",
        "YouTube did not attribute the reply to the connected channel.",
        403,
      );
    }
    return { comment };
  }

  async ownerUpdateComment(
    request: OwnerUpdateCommentRequest,
  ): Promise<YouTubeOwnerCommentMutation> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const commentId = strictResourceId(request.commentId, "comment");
    const existing = this.mapOwnerComment(
      await this.comment(request),
      "The YouTube comment does not belong to the connected channel.",
    );
    if (existing.author.channelId !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube comment does not belong to the connected channel.",
        403,
      );
    }
    const url = new URL(`${DATA_API}/comments`);
    url.searchParams.set("part", "snippet");
    const body = await this.ownerApi(
      request,
      "comments.update.owner",
      50,
      url,
      "PUT",
      {
        id: commentId,
        snippet: { textOriginal: actionText(request.text, "Comment", 10_000) },
      },
    );
    const comment = this.mapOwnerComment(
      parseJson<ApiComment>(body),
      "YouTube did not return the connected channel's comment.",
    );
    if (
      comment.commentId !== commentId ||
      comment.author.channelId !== actorChannelId
    ) {
      throw new YouTubeProviderError(
        "permission_denied",
        "YouTube did not return the connected channel's comment.",
        403,
      );
    }
    return { comment };
  }

  async ownerDeleteComment(
    request: OwnerCommentMutationRequest,
  ): Promise<{ readonly deleted: true; readonly commentId: string }> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const commentId = strictResourceId(request.commentId, "comment");
    const existing = this.mapOwnerComment(
      await this.comment(request),
      "The YouTube comment does not belong to the connected channel.",
    );
    if (existing.author.channelId !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube comment does not belong to the connected channel.",
        403,
      );
    }
    const url = new URL(`${DATA_API}/comments`);
    url.searchParams.set("id", commentId);
    await this.ownerApi(request, "comments.delete.owner", 50, url, "DELETE");
    return { deleted: true, commentId };
  }

  async ownerSetCommentModeration(
    request: OwnerModerateCommentRequest,
  ): Promise<{
    readonly commentId: string;
    readonly moderationStatus: "published" | "heldForReview" | "rejected";
    readonly authorBanned: boolean;
  }> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const commentId = strictResourceId(request.commentId, "comment");
    const existing = this.mapOwnerComment(
      await this.comment(request),
      "YouTube returned an invalid moderated comment.",
    );
    if (existing.associatedChannelId !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "Only comments associated with the connected channel can be moderated.",
        403,
      );
    }
    if (
      request.moderationStatus !== "published" &&
      request.moderationStatus !== "heldForReview" &&
      request.moderationStatus !== "rejected"
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported moderation status is required.",
        400,
      );
    }
    if (request.banAuthor === true && request.moderationStatus !== "rejected") {
      throw new YouTubeProviderError(
        "bad_request",
        "An author can be banned only when rejecting a comment.",
        400,
      );
    }
    const url = new URL(`${DATA_API}/comments/setModerationStatus`);
    url.searchParams.set("id", commentId);
    url.searchParams.set("moderationStatus", request.moderationStatus);
    if (request.banAuthor === true) {
      url.searchParams.set("banAuthor", "true");
    }
    await this.ownerApi(
      request,
      "comments.setModerationStatus.owner",
      50,
      url,
      "POST",
    );
    return {
      commentId,
      moderationStatus: request.moderationStatus,
      authorBanned: request.banAuthor === true,
    };
  }

  async ownerSubscribe(
    request: OwnerCreateSubscriptionRequest,
  ): Promise<YouTubeOwnerSubscriptionMutation> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const targetChannelId = strictChannelId(request.channelId);
    if (targetChannelId === actorChannelId) {
      throw new YouTubeProviderError(
        "bad_request",
        "A channel cannot subscribe to itself.",
        400,
      );
    }
    const url = new URL(`${DATA_API}/subscriptions`);
    url.searchParams.set("part", "snippet");
    const body = await this.ownerApi(
      request,
      "subscriptions.insert.owner",
      50,
      url,
      "POST",
      {
        snippet: {
          resourceId: { kind: "youtube#channel", channelId: targetChannelId },
        },
      },
    );
    const subscription = parseJson<ApiSubscription>(body);
    const subscriptionId = providerIdentifier(
      subscription.id,
      RESOURCE_ID,
      "YouTube returned an invalid subscription.",
    );
    requireActorChannel(
      subscription.snippet?.channelId,
      actorChannelId,
      "YouTube did not create the subscription for the connected channel.",
    );
    if (subscription.snippet?.resourceId?.channelId !== targetChannelId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned a different subscription target.",
        502,
      );
    }
    return { subscriptionId, actorChannelId, targetChannelId };
  }

  async ownerUnsubscribe(
    request: OwnerDeleteSubscriptionRequest,
  ): Promise<{ readonly deleted: true; readonly subscriptionId: string }> {
    const subscriptionId = strictResourceId(
      request.subscriptionId,
      "subscription",
    );
    await this.subscription(request);
    const url = new URL(`${DATA_API}/subscriptions`);
    url.searchParams.set("id", subscriptionId);
    await this.ownerApi(
      request,
      "subscriptions.delete.owner",
      50,
      url,
      "DELETE",
    );
    return { deleted: true, subscriptionId };
  }

  async ownerCreatePlaylist(
    request: OwnerCreatePlaylistRequest,
  ): Promise<YouTubeOwnerPlaylistMutation> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const title = actionText(request.title, "Playlist title", 150);
    const description = actionDescription(request.description, 5_000);
    const requestedPrivacy = requestedPlaylistPrivacy(request.privacyStatus);
    const url = new URL(`${DATA_API}/playlists`);
    url.searchParams.set("part", "snippet,status");
    const body = await this.ownerApi(
      request,
      "playlists.insert.owner",
      50,
      url,
      "POST",
      {
        snippet: { title, description },
        status: { privacyStatus: requestedPrivacy },
      },
    );
    return this.mapPlaylistMutation(
      parseJson<ApiPlaylist>(body),
      actorChannelId,
    );
  }

  async ownerUpdatePlaylist(
    request: OwnerUpdatePlaylistRequest,
  ): Promise<YouTubeOwnerPlaylistMutation> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const playlistId = strictResourceId(request.playlistId, "playlist");
    await this.playlist(request);
    const title = actionText(request.title, "Playlist title", 150);
    const description = actionDescription(request.description, 5_000);
    const requestedPrivacy = requestedPlaylistPrivacy(request.privacyStatus);
    const url = new URL(`${DATA_API}/playlists`);
    url.searchParams.set("part", "snippet,status");
    const body = await this.ownerApi(
      request,
      "playlists.update.owner",
      50,
      url,
      "PUT",
      {
        id: playlistId,
        snippet: { title, description },
        status: { privacyStatus: requestedPrivacy },
      },
    );
    const result = this.mapPlaylistMutation(
      parseJson<ApiPlaylist>(body),
      actorChannelId,
    );
    if (result.playlistId !== playlistId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned a different playlist.",
        502,
      );
    }
    return result;
  }

  async ownerDeletePlaylist(
    request: OwnerDeletePlaylistRequest,
  ): Promise<{ readonly deleted: true; readonly playlistId: string }> {
    const playlistId = strictResourceId(request.playlistId, "playlist");
    await this.playlist(request);
    const url = new URL(`${DATA_API}/playlists`);
    url.searchParams.set("id", playlistId);
    await this.ownerApi(request, "playlists.delete.owner", 50, url, "DELETE");
    return { deleted: true, playlistId };
  }

  async ownerCreatePlaylistItem(
    request: OwnerCreatePlaylistItemRequest,
  ): Promise<YouTubeOwnerPlaylistItemMutation> {
    expectedChannel(request.expectedChannelId);
    const playlistId = strictResourceId(request.playlistId, "playlist");
    const videoId = strictVideoId(request.videoId);
    const requestedPosition = position(request.position);
    await this.playlist(request);
    const url = new URL(`${DATA_API}/playlistItems`);
    url.searchParams.set("part", "snippet");
    const body = await this.ownerApi(
      request,
      "playlistItems.insert.owner",
      50,
      url,
      "POST",
      {
        snippet: {
          playlistId,
          resourceId: { kind: "youtube#video", videoId },
          ...(requestedPosition === undefined
            ? {}
            : { position: requestedPosition }),
        },
      },
    );
    return this.mapPlaylistItemMutation(
      parseJson<ApiPlaylistItem>(body),
      playlistId,
      videoId,
    );
  }

  async ownerReorderPlaylistItem(
    request: OwnerReorderPlaylistItemRequest,
  ): Promise<YouTubeOwnerPlaylistItemMutation> {
    expectedChannel(request.expectedChannelId);
    const playlistItemId = strictResourceId(
      request.playlistItemId,
      "playlist item",
    );
    const requestedPosition = position(request.position);
    if (requestedPosition === undefined) {
      throw new YouTubeProviderError(
        "bad_request",
        "Playlist position is required.",
        400,
      );
    }
    const existing = await this.playlistItem(request);
    const playlistId = providerIdentifier(
      existing.snippet?.playlistId,
      RESOURCE_ID,
      "YouTube returned an invalid playlist item.",
    );
    const videoId = providerIdentifier(
      existing.contentDetails?.videoId ??
        existing.snippet?.resourceId?.videoId,
      VIDEO_ID,
      "YouTube returned an invalid playlist item.",
    );
    const url = new URL(`${DATA_API}/playlistItems`);
    url.searchParams.set("part", "snippet");
    const body = await this.ownerApi(
      request,
      "playlistItems.update.position.owner",
      50,
      url,
      "PUT",
      {
        id: playlistItemId,
        snippet: {
          playlistId,
          position: requestedPosition,
          resourceId: { kind: "youtube#video", videoId },
        },
      },
    );
    const result = this.mapPlaylistItemMutation(
      parseJson<ApiPlaylistItem>(body),
      playlistId,
      videoId,
    );
    if (
      result.playlistItemId !== playlistItemId ||
      result.position !== requestedPosition
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube did not confirm the requested playlist order.",
        502,
      );
    }
    return result;
  }

  async ownerDeletePlaylistItem(
    request: OwnerDeletePlaylistItemRequest,
  ): Promise<{ readonly deleted: true; readonly playlistItemId: string }> {
    const playlistItemId = strictResourceId(
      request.playlistItemId,
      "playlist item",
    );
    await this.playlistItem(request);
    const url = new URL(`${DATA_API}/playlistItems`);
    url.searchParams.set("id", playlistItemId);
    await this.ownerApi(
      request,
      "playlistItems.delete.owner",
      50,
      url,
      "DELETE",
    );
    return { deleted: true, playlistItemId };
  }

  async ownerUpdateVideoMetadata(
    request: OwnerUpdateVideoMetadataRequest,
  ): Promise<{
    readonly videoId: string;
    readonly actorChannelId: string;
    readonly title: string;
    readonly description: string;
    readonly categoryId: string;
    readonly tags: readonly string[];
    readonly privacyStatus: "private";
  }> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const videoId = strictVideoId(request.videoId);
    const existing = await this.ownedVideo(
      request.principal,
      request.requestId,
      request.accessToken,
      videoId,
    );
    if (
      existing.channelId !== actorChannelId ||
      existing.privacyStatus !== "private"
    ) {
      throw new YouTubeProviderError(
        "permission_denied",
        "Private Dev can update only private videos owned by the connected channel.",
        403,
      );
    }
    const title = actionText(request.title, "Video title", 100);
    const description = actionDescription(request.description, 5_000);
    if (!/^\d{1,3}$/u.test(request.categoryId)) {
      throw new YouTubeProviderError(
        "bad_request",
        "A valid YouTube category is required.",
        400,
      );
    }
    const tags = videoTags(request.tags);
    const url = new URL(`${DATA_API}/videos`);
    url.searchParams.set("part", "snippet");
    const body = await this.ownerApi(
      request,
      "videos.update.metadata.private.owner",
      50,
      url,
      "PUT",
      {
        id: videoId,
        snippet: {
          title,
          description,
          categoryId: request.categoryId,
          ...(tags.length === 0 ? {} : { tags }),
        },
      },
    );
    const updated = parseJson<ApiVideo>(body);
    if (
      updated.id !== videoId ||
      updated.snippet?.channelId !== actorChannelId ||
      updated.snippet.title !== title ||
      updated.snippet.categoryId !== request.categoryId
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube did not confirm the private video metadata update.",
        502,
      );
    }
    return {
      videoId,
      actorChannelId,
      title,
      description,
      categoryId: request.categoryId,
      tags,
      privacyStatus: "private",
    };
  }

  async ownerDeleteVideo(
    request: OwnerDeleteVideoRequest,
  ): Promise<{ readonly deleted: true; readonly videoId: string }> {
    const actorChannelId = expectedChannel(request.expectedChannelId);
    const videoId = strictVideoId(request.videoId);
    if (request.confirmVideoId.trim() !== videoId) {
      throw new YouTubeProviderError(
        "bad_request",
        "Confirm the exact private video identifier before deletion.",
        400,
      );
    }
    const existing = await this.ownedVideo(
      request.principal,
      request.requestId,
      request.accessToken,
      videoId,
    );
    if (
      existing.channelId !== actorChannelId ||
      existing.privacyStatus !== "private"
    ) {
      throw new YouTubeProviderError(
        "permission_denied",
        "Private Dev can delete only private videos owned by the connected channel.",
        403,
      );
    }
    const url = new URL(`${DATA_API}/videos`);
    url.searchParams.set("id", videoId);
    await this.ownerApi(
      request,
      "videos.delete.private.owner",
      50,
      url,
      "DELETE",
    );
    return { deleted: true, videoId };
  }

  private mapPlaylistMutation(
    playlist: ApiPlaylist,
    expectedChannelId: string,
  ): YouTubeOwnerPlaylistMutation {
    const playlistId = providerIdentifier(
      playlist.id,
      RESOURCE_ID,
      "YouTube returned an invalid playlist.",
    );
    const actorChannelId = requireActorChannel(
      playlist.snippet?.channelId,
      expectedChannelId,
      "YouTube did not return the connected channel's playlist.",
    );
    return {
      playlistId,
      actorChannelId,
      title: requiredText(
        playlist.snippet?.title,
        "YouTube returned an invalid playlist.",
      ),
      description: playlist.snippet?.description ?? "",
      privacyStatus: privacyStatus(playlist.status?.privacyStatus),
    };
  }

  private mapPlaylistItemMutation(
    item: ApiPlaylistItem,
    expectedPlaylistId: string,
    expectedVideoId: string,
  ): YouTubeOwnerPlaylistItemMutation {
    const playlistItemId = providerIdentifier(
      item.id,
      RESOURCE_ID,
      "YouTube returned an invalid playlist item.",
    );
    const playlistId = providerIdentifier(
      item.snippet?.playlistId,
      RESOURCE_ID,
      "YouTube returned an invalid playlist item.",
    );
    const videoId = providerIdentifier(
      item.contentDetails?.videoId ?? item.snippet?.resourceId?.videoId,
      VIDEO_ID,
      "YouTube returned an invalid playlist item.",
    );
    if (playlistId !== expectedPlaylistId || videoId !== expectedVideoId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned a different playlist item.",
        502,
      );
    }
    return {
      playlistItemId,
      playlistId,
      videoId,
      position: providerNonNegativeInteger(
        item.snippet?.position,
        "YouTube returned an invalid playlist position.",
      ),
    };
  }

  async ownerVideos(query: OwnerPageQuery): Promise<YouTubeOwnerVideosPage> {
    const expectedChannelId = strictChannelId(query.expectedChannelId);
    const token = pageToken(query.pageToken);
    const size = ownerPageSize(query.maxResults);
    const channel = await this.connectedChannel(
      query.principal,
      query.requestId,
      query.accessToken,
    );
    if (channel.channelId !== expectedChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The connected YouTube channel no longer matches this account.",
        403,
      );
    }
    if (!channel.uploadsPlaylistId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube did not return the connected channel upload inventory.",
        502,
      );
    }
    await this.options.quota.reserve({
      principal: query.principal,
      bucket: "general",
      amount: 1,
      operation: "playlistItems.list.ownerUploads",
      requestId: query.requestId,
    });
    const playlistUrl = new URL(`${DATA_API}/playlistItems`);
    playlistUrl.searchParams.set("part", "snippet,contentDetails");
    playlistUrl.searchParams.set("playlistId", channel.uploadsPlaylistId);
    playlistUrl.searchParams.set("maxResults", String(size));
    if (token) playlistUrl.searchParams.set("pageToken", token);
    const playlistResponse = await this.options.transport.send({
      url: playlistUrl.toString(),
      headers: { authorization: `Bearer ${query.accessToken}` },
    });
    assertProviderResponse(playlistResponse.status, playlistResponse.body);
    const envelope = parseJson<ListEnvelope<ApiPlaylistItem>>(
      playlistResponse.body,
    );
    const entries = (envelope.items ?? []).map((item) => {
      const playlistItemId = providerIdentifier(
        item.id,
        /^[A-Za-z0-9_-]{1,256}$/,
        "YouTube returned an invalid upload inventory item.",
      );
      const rawVideoId =
        item.contentDetails?.videoId ?? item.snippet?.resourceId?.videoId;
      const videoId =
        typeof rawVideoId === "string" && VIDEO_ID.test(rawVideoId)
          ? rawVideoId
          : undefined;
      const position =
        item.snippet?.position === undefined
          ? undefined
          : providerNonNegativeInteger(
              item.snippet.position,
              "YouTube returned an invalid upload inventory item.",
            );
      const playlistPublishedAt =
        item.snippet?.publishedAt === undefined
          ? undefined
          : providerTimestamp(
              item.snippet.publishedAt,
              "YouTube returned an invalid upload inventory item.",
            );
      return {
        playlistItemId,
        ...(videoId === undefined ? {} : { videoId }),
        ...(playlistPublishedAt === undefined ? {} : { playlistPublishedAt }),
        ...(position === undefined ? {} : { position }),
      };
    });
    const videoIds = entries
      .map((entry) => entry.videoId)
      .filter((value): value is string => value !== undefined);
    const byId = new Map<string, ApiVideo>();
    if (videoIds.length > 0) {
      await this.options.quota.reserve({
        principal: query.principal,
        bucket: "general",
        amount: 1,
        operation: "videos.list.ownerInventory",
        requestId: query.requestId,
      });
      const videosUrl = new URL(`${DATA_API}/videos`);
      videosUrl.searchParams.set(
        "part",
        "snippet,contentDetails,statistics,status",
      );
      videosUrl.searchParams.set("id", videoIds.join(","));
      const videosResponse = await this.options.transport.send({
        url: videosUrl.toString(),
        headers: { authorization: `Bearer ${query.accessToken}` },
      });
      assertProviderResponse(videosResponse.status, videosResponse.body);
      for (const item of parseJson<ListEnvelope<ApiVideo>>(
        videosResponse.body,
      ).items ?? []) {
        if (item.id) byId.set(item.id, item);
      }
    }
    const items: YouTubeOwnerVideo[] = entries.map((entry) => {
      const api = entry.videoId ? byId.get(entry.videoId) : undefined;
      if (!api) {
        return {
          state: "unavailable",
          playlistItemId: entry.playlistItemId,
          ...(entry.videoId === undefined ? {} : { videoId: entry.videoId }),
          ...(entry.playlistPublishedAt === undefined
            ? {}
            : { playlistPublishedAt: entry.playlistPublishedAt }),
          ...(entry.position === undefined ? {} : { position: entry.position }),
        };
      }
      const video = this.mapOwnedVideo(api);
      if (video.channelId !== channel.channelId) {
        throw new YouTubeProviderError(
          "provider_rejected",
          "YouTube returned a video outside the connected channel.",
          502,
        );
      }
      return {
        state: "available",
        playlistItemId: entry.playlistItemId,
        ...(entry.playlistPublishedAt === undefined
          ? {}
          : { playlistPublishedAt: entry.playlistPublishedAt }),
        ...(entry.position === undefined ? {} : { position: entry.position }),
        video,
      };
    });
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      attribution: {
        source: "youtube",
        channelId: channel.channelId,
        channelTitle: channel.title,
      },
      items,
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async ownerSubscriptions(
    query: OwnerPageQuery,
  ): Promise<YouTubeOwnerSubscriptionsPage> {
    const expectedChannelId = strictChannelId(query.expectedChannelId);
    const token = pageToken(query.pageToken);
    const size = ownerPageSize(query.maxResults);
    const order = subscriptionOrder(query.order);
    await this.options.quota.reserve({
      principal: query.principal,
      bucket: "general",
      amount: 1,
      operation: "subscriptions.list.mine",
      requestId: query.requestId,
    });
    const url = new URL(`${DATA_API}/subscriptions`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("mine", "true");
    url.searchParams.set("maxResults", String(size));
    url.searchParams.set("order", order);
    if (token) url.searchParams.set("pageToken", token);
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { authorization: `Bearer ${query.accessToken}` },
    });
    assertProviderResponse(response.status, response.body);
    const envelope = parseJson<ListEnvelope<ApiSubscription>>(response.body);
    const items: YouTubeOwnerSubscription[] = (envelope.items ?? []).map(
      (item) => {
        const snippet = item.snippet;
        const subscriptionId = providerIdentifier(
          item.id,
          /^[A-Za-z0-9_-]{1,256}$/,
          "YouTube returned an invalid subscription.",
        );
        const channelId = providerIdentifier(
          snippet?.resourceId?.channelId,
          /^[A-Za-z0-9_-]{6,64}$/,
          "YouTube returned an invalid subscription.",
        );
        const channelTitle = requiredText(
          snippet?.title,
          "YouTube returned an invalid subscription.",
        );
        const publishedAt = providerTimestamp(
          snippet?.publishedAt,
          "YouTube returned an invalid subscription.",
        );
        const image = thumbnail(snippet?.thumbnails);
        return {
          subscriptionId,
          channelId,
          channelTitle,
          description: snippet?.description ?? "",
          publishedAt,
          ...(image === undefined ? {} : { thumbnail: image }),
        };
      },
    );
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      attribution: {
        source: "youtube",
        channelId: expectedChannelId,
        channelTitle: query.expectedChannelTitle,
      },
      items,
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async ownerPlaylists(
    query: OwnerPageQuery,
  ): Promise<YouTubeOwnerPlaylistsPage> {
    const expectedChannelId = strictChannelId(query.expectedChannelId);
    const token = pageToken(query.pageToken);
    const size = ownerPageSize(query.maxResults);
    await this.options.quota.reserve({
      principal: query.principal,
      bucket: "general",
      amount: 1,
      operation: "playlists.list.mine",
      requestId: query.requestId,
    });
    const url = new URL(`${DATA_API}/playlists`);
    url.searchParams.set("part", "snippet,contentDetails,status");
    url.searchParams.set("mine", "true");
    url.searchParams.set("maxResults", String(size));
    if (token) url.searchParams.set("pageToken", token);
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { authorization: `Bearer ${query.accessToken}` },
    });
    assertProviderResponse(response.status, response.body);
    const envelope = parseJson<ListEnvelope<ApiPlaylist>>(response.body);
    const items: YouTubeOwnerPlaylist[] = (envelope.items ?? []).map((item) => {
      const snippet = item.snippet;
      const playlistId = providerIdentifier(
        item.id,
        /^[A-Za-z0-9_-]{1,160}$/,
        "YouTube returned an invalid owner playlist.",
      );
      const channelId = providerIdentifier(
        snippet?.channelId,
        /^[A-Za-z0-9_-]{6,64}$/,
        "YouTube returned an invalid owner playlist.",
      );
      if (channelId !== expectedChannelId) {
        throw new YouTubeProviderError(
          "provider_rejected",
          "YouTube returned a playlist outside the connected channel.",
          502,
        );
      }
      const channelTitle = requiredText(
        snippet?.channelTitle,
        "YouTube returned an invalid owner playlist.",
      );
      const image = thumbnail(snippet?.thumbnails);
      return {
        playlistId,
        title: requiredText(
          snippet?.title,
          "YouTube returned an invalid owner playlist.",
        ),
        description: snippet?.description ?? "",
        publishedAt: providerTimestamp(
          snippet?.publishedAt,
          "YouTube returned an invalid owner playlist.",
        ),
        channelId,
        channelTitle,
        itemCount: providerNonNegativeInteger(
          item.contentDetails?.itemCount,
          "YouTube returned an invalid owner playlist.",
        ),
        privacyStatus: privacyStatus(item.status?.privacyStatus),
        ...(image === undefined ? {} : { thumbnail: image }),
      };
    });
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      attribution: {
        source: "youtube",
        channelId: expectedChannelId,
        channelTitle: query.expectedChannelTitle,
      },
      items,
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async beginPrivateUpload(
    request: BeginPrivateUploadRequest,
  ): Promise<YouTubeResumableUploadSession> {
    validateMedia(request.contentType, request.contentLength);
    validateMetadata(request.metadata);
    await this.options.quota.reserve({
      principal: request.principal,
      bucket: "upload",
      amount: 1,
      operation: "videos.insert.resumable.private",
      requestId: request.requestId,
    });
    const url = new URL(`${UPLOAD_API}/videos`);
    url.searchParams.set("uploadType", "resumable");
    url.searchParams.set(
      "part",
      "snippet,status,paidProductPlacementDetails",
    );
    url.searchParams.set(
      "notifySubscribers",
      request.metadata.notifySubscribers ? "true" : "false",
    );
    const response = await this.options.transport.send({
      url: url.toString(),
      method: "POST",
      headers: {
        authorization: `Bearer ${request.accessToken}`,
        "content-type": "application/json; charset=UTF-8",
        "x-upload-content-length": String(request.contentLength),
        "x-upload-content-type": request.contentType,
      },
      body: JSON.stringify({
        snippet: {
          title: request.metadata.title.trim(),
          description: request.metadata.description,
          categoryId: request.metadata.categoryId,
        },
        status: {
          privacyStatus: "private",
          selfDeclaredMadeForKids: request.metadata.madeForKids,
          containsSyntheticMedia: request.metadata.containsSyntheticMedia,
        },
        paidProductPlacementDetails: {
          hasPaidProductPlacement:
            request.metadata.containsPaidPromotion,
        },
      }),
    });
    assertProviderResponse(response.status, response.body);
    const sessionUrl = response.headers.location;
    if (!sessionUrl?.startsWith("https://")) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube did not return a secure upload session.",
        502,
      );
    }
    return {
      sessionUrl,
      expiresAt: isoAfter(this.clock, 24 * 60 * 60 * 1000),
      privacyStatus: "private",
    };
  }

  async completedUploadVideoId(
    request: CompletedUploadRequest,
  ): Promise<string> {
    validateMedia("application/octet-stream", request.contentLength);
    const response = await this.options.transport.send({
      url: uploadSessionUrl(request.sessionUrl),
      method: "PUT",
      headers: {
        authorization: `Bearer ${request.accessToken}`,
        "content-length": "0",
        "content-range": `bytes */${request.contentLength}`,
      },
      body: "",
    });
    if (response.status === 308) {
      throw new YouTubeProviderError(
        "conflict",
        "The YouTube upload is still in progress.",
        409,
        true,
      );
    }
    assertProviderResponse(response.status, response.body);
    const videoId = parseJson<ApiVideo>(response.body).id?.trim();
    if (!videoId || !/^[A-Za-z0-9_-]{6,20}$/.test(videoId)) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube did not confirm the completed upload.",
        502,
      );
    }
    return videoId;
  }

  private mapOwnedVideo(api: ApiVideo): YouTubeVideoSummary {
    const snippet = api.snippet;
    const image = thumbnail(snippet?.thumbnails);
    if (
      !snippet?.title ||
      !snippet.channelTitle ||
      !image
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned invalid owner video metadata.",
        502,
      );
    }
    const videoId = providerIdentifier(
      api.id,
      VIDEO_ID,
      "YouTube returned invalid owner video metadata.",
    );
    const channelId = providerIdentifier(
      snippet.channelId,
      /^[A-Za-z0-9_-]{6,64}$/,
      "YouTube returned invalid owner video metadata.",
    );
    const publishedAt = providerTimestamp(
      snippet.publishedAt,
      "YouTube returned invalid owner video metadata.",
    );
    return {
      videoId,
      title: snippet.title,
      description: snippet.description ?? "",
      channelId,
      channelTitle: snippet.channelTitle,
      publishedAt,
      thumbnail: image,
      ...(snippet.categoryId === undefined
        ? {}
        : { categoryId: snippet.categoryId }),
      ...(snippet.tags === undefined ? {} : { tags: snippet.tags }),
      ...(api.contentDetails?.duration === undefined
        ? {}
        : { duration: api.contentDetails.duration }),
      ...(api.statistics?.viewCount === undefined
        ? {}
        : { viewCount: api.statistics.viewCount }),
      ...(api.statistics?.likeCount === undefined
        ? {}
        : { likeCount: api.statistics.likeCount }),
      ...(api.statistics?.commentCount === undefined
        ? {}
        : { commentCount: api.statistics.commentCount }),
      ...(api.status?.embeddable === undefined
        ? {}
        : { embeddable: api.status.embeddable }),
      ...(api.status?.privacyStatus === undefined
        ? {}
        : { privacyStatus: api.status.privacyStatus }),
      ...(api.status?.uploadStatus === undefined
        ? {}
        : { uploadStatus: api.status.uploadStatus }),
    };
  }

  async ownedVideo(
    principal: string,
    requestId: string,
    accessToken: string,
    videoId: string,
  ): Promise<YouTubeVideoSummary> {
    const cleanId = videoId.trim();
    if (!/^[A-Za-z0-9_-]{6,20}$/.test(cleanId)) {
      throw new YouTubeProviderError(
        "bad_request",
        "A valid video identifier is required.",
        400,
      );
    }
    await this.options.quota.reserve({
      principal,
      bucket: "general",
      amount: 1,
      operation: "videos.list.owner",
      requestId,
    });
    const url = new URL(`${DATA_API}/videos`);
    url.searchParams.set(
      "part",
      "snippet,contentDetails,statistics,status,processingDetails",
    );
    url.searchParams.set("id", cleanId);
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { authorization: `Bearer ${accessToken}` },
    });
    assertProviderResponse(response.status, response.body);
    const api = parseJson<{ readonly items?: readonly ApiVideo[] }>(
      response.body,
    ).items?.[0];
    if (!api) {
      throw new YouTubeProviderError(
        "not_found",
        "The uploaded YouTube video is unavailable.",
        404,
      );
    }
    return this.mapOwnedVideo(api);
  }

  async analyticsPreset(
    query: AnalyticsPresetQuery,
  ): Promise<YouTubeOwnerAnalyticsResult> {
    if (!validDate(query.startDate) || !validDate(query.endDate)) {
      throw new YouTubeProviderError(
        "bad_request",
        "Analytics dates must use YYYY-MM-DD.",
        400,
      );
    }
    if (query.startDate > query.endDate) {
      throw new YouTubeProviderError(
        "bad_request",
        "Analytics start date must not follow the end date.",
        400,
      );
    }
    if (dateRangeDays(query.startDate, query.endDate) > MAX_ANALYTICS_RANGE_DAYS) {
      throw new YouTubeProviderError(
        "bad_request",
        `Analytics date range cannot exceed ${MAX_ANALYTICS_RANGE_DAYS} days.`,
        400,
      );
    }
    const performanceMetrics = [
      "views",
      "engagedViews",
      "estimatedMinutesWatched",
      "averageViewDuration",
      "averageViewPercentage",
    ] as const;
    const engagementMetrics = [
      ...performanceMetrics,
      "likes",
      "comments",
      "shares",
      "subscribersGained",
      "subscribersLost",
    ] as const;
    const trafficMetrics = [
      "views",
      "engagedViews",
      "estimatedMinutesWatched",
    ] as const;
    let dimensions: readonly string[] = [];
    let metrics: readonly string[];
    let sort: string | undefined;
    let filters: string | undefined;
    let paginated = false;
    switch (query.preset) {
      case "overview":
        metrics = engagementMetrics;
        break;
      case "topVideos":
        dimensions = ["video"];
        metrics = engagementMetrics;
        sort = "-views";
        paginated = true;
        break;
      case "countries":
        dimensions = ["country"];
        metrics = performanceMetrics;
        sort = "-views";
        paginated = true;
        break;
      case "trafficSources":
        dimensions = ["insightTrafficSourceType"];
        metrics = trafficMetrics;
        sort = "-views";
        paginated = true;
        break;
      case "devicesOs":
        dimensions = ["deviceType", "operatingSystem"];
        metrics = trafficMetrics;
        sort = "-views";
        paginated = true;
        break;
      case "videoRetention": {
        const videoId = strictVideoId(query.videoId ?? "");
        dimensions = ["elapsedVideoTimeRatio"];
        metrics = [
          "audienceWatchRatio",
          "relativeRetentionPerformance",
          "startedWatching",
          "stoppedWatching",
          "totalSegmentImpressions",
        ];
        filters = `video==${videoId}`;
        paginated = true;
        break;
      }
      default:
        throw new YouTubeProviderError(
          "bad_request",
          "A supported analytics preset is required.",
          400,
        );
    }
    if (query.preset !== "videoRetention" && query.videoId !== undefined) {
      throw new YouTubeProviderError(
        "bad_request",
        "A video identifier is supported only for video retention.",
        400,
      );
    }
    if (!paginated && query.startIndex !== undefined) {
      throw new YouTubeProviderError(
        "bad_request",
        "Analytics startIndex is supported only for paginated presets.",
        400,
      );
    }
    const startIndex = paginated
      ? analyticsStartIndex(query.startIndex)
      : undefined;
    await this.options.quota.reserve({
      principal: query.principal,
      bucket: "analytics",
      amount: 1,
      operation: `youtubeAnalytics.reports.query.${query.preset}`,
      requestId: query.requestId,
    });
    const url = new URL(ANALYTICS_API);
    url.searchParams.set("ids", "channel==MINE");
    url.searchParams.set("startDate", query.startDate);
    url.searchParams.set("endDate", query.endDate);
    if (dimensions.length > 0) {
      url.searchParams.set("dimensions", dimensions.join(","));
    }
    url.searchParams.set("metrics", metrics.join(","));
    url.searchParams.set("maxResults", String(ANALYTICS_PAGE_SIZE));
    if (startIndex !== undefined) {
      url.searchParams.set("startIndex", String(startIndex));
    }
    if (filters) url.searchParams.set("filters", filters);
    if (sort) url.searchParams.set("sort", sort);
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { authorization: `Bearer ${query.accessToken}` },
    });
    assertProviderResponse(response.status, response.body);
    const envelope = parseJson<AnalyticsEnvelope>(response.body);
    const headers = envelope.columnHeaders ?? [];
    const rows = (envelope.rows ?? []).map((values) => {
      const row: {
        dimensions: Record<string, string>;
        metrics: Record<string, number>;
      } = { dimensions: {}, metrics: {} };
      headers.forEach((header, index) => {
        if (
          !header.name ||
          (header.columnType !== "DIMENSION" &&
            header.columnType !== "METRIC")
        ) {
          throw new YouTubeProviderError(
            "provider_rejected",
            "YouTube returned invalid analytics columns.",
            502,
          );
        }
        const value = values[index];
        if (header.columnType === "DIMENSION") {
          row.dimensions[header.name] = String(value ?? "");
        } else {
          const numeric = Number(value);
          if (!Number.isFinite(numeric)) {
            throw new YouTubeProviderError(
              "provider_rejected",
              "YouTube returned invalid analytics metrics.",
              502,
            );
          }
          row.metrics[header.name] = numeric;
        }
      });
      return row;
    });
    const continuationStartIndex =
      paginated && rows.length === ANALYTICS_PAGE_SIZE
        ? (startIndex ?? 1) + rows.length
        : undefined;
    return {
      preset: query.preset,
      startDate: query.startDate,
      endDate: query.endDate,
      requestedRange: {
        startDate: query.startDate,
        endDate: query.endDate,
      },
      ...(query.preset === "videoRetention"
        ? { videoId: strictVideoId(query.videoId ?? "") }
        : {}),
      rows,
      ...(continuationStartIndex === undefined
        ? {}
        : { continuationStartIndex }),
      empty: rows.length === 0,
      providerMayExcludeRecentIncompleteDays: true,
    };
  }
}
