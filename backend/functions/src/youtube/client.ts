import { assertProviderResponse, YouTubeProviderError } from "./errors.js";
import { assessPublicVideo } from "./public_video_policy.js";
import type { YouTubeCachePort, YouTubeQuotaPort } from "./ports.js";
import type {
  HttpTransport,
  YouTubeBatchStatisticsResult,
  YouTubeChannelIdentity,
  YouTubeFilteredVideoSummary,
  YouTubeLiveStreamingDetails,
  YouTubePage,
  YouTubePublicChannelDetails,
  YouTubePublicComment,
  YouTubePublicCommentRepliesPage,
  YouTubePublicCommentThread,
  YouTubePublicCommentThreadsPage,
  YouTubePublicLanguage,
  YouTubePublicPlaylistDetails,
  YouTubePublicRegion,
  YouTubePublicVideoCategory,
  YouTubePublicVideoAvailability,
  YouTubePublicVideoUnavailableReason,
  YouTubeRegionRestriction,
  YouTubeThumbnail,
  YouTubeVideoStatisticsSnapshot,
  YouTubeVideoSummary,
} from "./types.js";
import {
  safeYouTubeProviderImageUrl,
  safeYouTubeProviderPlainText,
} from "./provider_content.js";

const DATA_API = "https://www.googleapis.com/youtube/v3";
const PUBLIC_CACHE_MS = 5 * 60 * 1000;
const DETAILS_CACHE_MS = 10 * 60 * 1000;
const CHANNEL_CACHE_MS = 10 * 60 * 1000;
const PLAYLIST_CACHE_MS = 10 * 60 * 1000;
const STATISTICS_CACHE_MS = 2 * 60 * 1000;
const COMMENT_CACHE_MS = 60 * 1000;
const DICTIONARY_CACHE_MS = 24 * 60 * 60 * 1000;
const MAX_PAGE_SIZE = 25;
const MAX_COMMENT_PAGE_SIZE = 50;
const VIDEO_ID = /^[A-Za-z0-9_-]{6,20}$/;
const CHANNEL_ID = /^[A-Za-z0-9_-]{6,64}$/;
const PLAYLIST_ID = /^[A-Za-z0-9_-]{1,160}$/;
const COMMENT_ID = /^[A-Za-z0-9_-]{1,256}$/;
const CATEGORY_ID = /^[0-9]{1,3}$/;
const LANGUAGE_TAG = /^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$/;
const HANDLE = /^[\p{L}\p{N}._\-·]{1,100}$/u;
const NON_NEGATIVE_INTEGER = /^(0|[1-9][0-9]*)$/;

interface ListEnvelope<T> {
  readonly items?: readonly T[];
  readonly nextPageToken?: string;
}

interface ApiThumbnail {
  readonly url?: string;
  readonly width?: number;
  readonly height?: number;
}

interface ApiVideo {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly description?: string;
    readonly channelId?: string;
    readonly channelTitle?: string;
    readonly publishedAt?: string;
    readonly liveBroadcastContent?: string;
    readonly categoryId?: string;
    readonly tags?: readonly string[];
    readonly defaultLanguage?: string;
    readonly defaultAudioLanguage?: string;
    readonly localized?: {
      readonly title?: string;
      readonly description?: string;
    };
    readonly thumbnails?: Record<string, ApiThumbnail>;
  };
  readonly contentDetails?: {
    readonly duration?: string;
    readonly caption?: string;
    readonly definition?: string;
    readonly licensedContent?: boolean;
    readonly projection?: string;
    readonly regionRestriction?: {
      readonly allowed?: readonly string[];
      readonly blocked?: readonly string[];
    };
    readonly contentRating?: {
      readonly ytRating?: string;
    };
  };
  readonly statistics?: {
    readonly viewCount?: string;
    readonly likeCount?: string;
    readonly commentCount?: string;
  };
  readonly status?: {
    readonly embeddable?: boolean;
    readonly privacyStatus?: string;
    readonly uploadStatus?: string;
    readonly madeForKids?: boolean;
  };
  readonly liveStreamingDetails?: {
    readonly actualStartTime?: string;
    readonly actualEndTime?: string;
    readonly scheduledStartTime?: string;
    readonly scheduledEndTime?: string;
    readonly concurrentViewers?: string;
  };
}

interface ApiChannel {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly description?: string;
    readonly customUrl?: string;
    readonly publishedAt?: string;
    readonly country?: string;
    readonly thumbnails?: Record<string, ApiThumbnail>;
  };
  readonly contentDetails?: {
    readonly relatedPlaylists?: { readonly uploads?: string };
  };
  readonly statistics?: {
    readonly viewCount?: string;
    readonly subscriberCount?: string;
    readonly hiddenSubscriberCount?: boolean;
    readonly videoCount?: string;
  };
  readonly topicDetails?: {
    readonly topicCategories?: readonly string[];
  };
}

interface ApiPlaylistItem {
  readonly snippet?: {
    readonly resourceId?: { readonly videoId?: string };
  };
  readonly contentDetails?: { readonly videoId?: string };
}

interface ApiPlaylist {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly description?: string;
    readonly publishedAt?: string;
    readonly channelId?: string;
    readonly channelTitle?: string;
    readonly defaultLanguage?: string;
    readonly localized?: {
      readonly title?: string;
      readonly description?: string;
    };
    readonly thumbnails?: Record<string, ApiThumbnail>;
  };
  readonly contentDetails?: {
    readonly itemCount?: number;
  };
  readonly status?: {
    readonly privacyStatus?: string;
  };
}

interface ApiI18nRegion {
  readonly id?: string;
  readonly snippet?: {
    readonly gl?: string;
    readonly name?: string;
  };
}

interface ApiI18nLanguage {
  readonly id?: string;
  readonly snippet?: {
    readonly hl?: string;
    readonly name?: string;
  };
}

interface ApiVideoCategory {
  readonly id?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly assignable?: boolean;
    readonly channelId?: string;
  };
}

interface ApiVideoStatistics {
  readonly id?: string;
  readonly snippet?: {
    readonly publishTime?: string;
  };
  readonly statistics?: {
    readonly viewCount?: string;
    readonly likeCount?: string;
    readonly commentCount?: string;
  };
  readonly contentDetails?: {
    readonly duration?: string;
    readonly durationMillis?: string;
  };
}

interface ApiBatchStatisticsEnvelope {
  readonly items?: readonly ApiVideoStatistics[];
  readonly summary?: {
    readonly requestedVideoCount?: string;
    readonly succeededVideoCount?: string;
    readonly failedVideoCount?: string;
    readonly failedVideoIds?: readonly string[];
  };
}

interface ApiComment {
  readonly id?: string;
  readonly snippet?: {
    readonly authorDisplayName?: string;
    readonly authorProfileImageUrl?: string;
    readonly authorChannelUrl?: string;
    readonly authorChannelId?: {
      readonly value?: string;
    };
    readonly channelId?: string;
    readonly textDisplay?: string;
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
    readonly totalReplyCount?: number;
    readonly isPublic?: boolean;
  };
  readonly replies?: {
    readonly comments?: readonly ApiComment[];
  };
}

export interface PublicVideoQuery {
  readonly regionCode?: string;
  readonly videoCategoryId?: string;
  readonly pageToken?: string;
  readonly maxResults?: number;
}

export interface ExplicitSearchQuery {
  readonly query: string;
  readonly regionCode?: string;
  readonly pageToken?: string;
  readonly maxResults?: number;
}

export interface YouTubeDataClientOptions {
  readonly transport: HttpTransport;
  readonly quota: YouTubeQuotaPort;
  readonly cache: YouTubeCachePort;
  readonly serverApiKey: string;
}

export interface PublicVideoDetailsQuery {
  readonly regionCode?: string;
  readonly syndicationConfirmedBySearch?: boolean;
}

export interface PublicCommentThreadsQuery {
  readonly videoId: string;
  readonly regionCode?: string;
  readonly pageToken?: string;
  readonly maxResults?: number;
  readonly order?: "time" | "relevance";
}

export interface PublicCommentRepliesQuery {
  readonly videoId: string;
  readonly threadId: string;
  readonly parentCommentId: string;
  readonly regionCode?: string;
  readonly pageToken?: string;
  readonly maxResults?: number;
}

export interface PublicChannelPlaylistsQuery {
  readonly channelId: string;
  readonly pageToken?: string;
  readonly maxResults?: number;
}

type MutableReasonCounts = Partial<
  Record<YouTubePublicVideoUnavailableReason, number>
>;

function pageSize(value: number | undefined): number {
  if (value === undefined) return 12;
  if (!Number.isInteger(value) || value < 1 || value > MAX_PAGE_SIZE) {
    throw new YouTubeProviderError(
      "bad_request",
      `maxResults must be between 1 and ${MAX_PAGE_SIZE}.`,
      400,
    );
  }
  return value;
}

function commentPageSize(value: number | undefined): number {
  if (value === undefined) return 20;
  if (
    !Number.isInteger(value) ||
    value < 1 ||
    value > MAX_COMMENT_PAGE_SIZE
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      `maxResults must be between 1 and ${MAX_COMMENT_PAGE_SIZE}.`,
      400,
    );
  }
  return value;
}

function safeToken(value: string | undefined): string | undefined {
  const token = value?.trim();
  if (!token) return undefined;
  if (!/^[A-Za-z0-9_-]{1,256}$/.test(token)) {
    throw new YouTubeProviderError("bad_request", "Invalid page token.", 400);
  }
  return token;
}

function providerPageToken(value: unknown): string | undefined {
  if (value === undefined) return undefined;
  if (
    typeof value !== "string" ||
    !/^[A-Za-z0-9_-]{1,256}$/.test(value)
  ) {
    providerRejected("YouTube returned an invalid page token.");
  }
  return value;
}

function safeRegion(value: string | undefined): string {
  const region = value?.trim().toUpperCase() || "IN";
  if (!/^[A-Z]{2}$/.test(region)) {
    throw new YouTubeProviderError("bad_request", "Invalid region code.", 400);
  }
  return region;
}

function strictVideoIds(
  values: readonly string[],
  maximum = 50,
): readonly string[] {
  if (values.length === 0 || values.length > maximum) {
    throw new YouTubeProviderError(
      "bad_request",
      `Between 1 and ${maximum} video identifiers are required.`,
      400,
    );
  }
  const ids: string[] = [];
  const seen = new Set<string>();
  for (const candidate of values) {
    const id = candidate.trim();
    if (!VIDEO_ID.test(id) || seen.has(id)) {
      throw new YouTubeProviderError(
        "bad_request",
        "Video identifiers must be valid and unique.",
        400,
      );
    }
    seen.add(id);
    ids.push(id);
  }
  return ids;
}

function safeChannelId(value: string): string {
  const id = value.trim();
  if (!CHANNEL_ID.test(id)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid YouTube channel identifier is required.",
      400,
    );
  }
  return id;
}

function safePlaylistId(value: string): string {
  const id = value.trim();
  if (!PLAYLIST_ID.test(id)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid YouTube playlist identifier is required.",
      400,
    );
  }
  return id;
}

function safeCommentId(value: string, label: string): string {
  const id = value.trim();
  if (!COMMENT_ID.test(id)) {
    throw new YouTubeProviderError(
      "bad_request",
      `A valid ${label} is required.`,
      400,
    );
  }
  return id;
}

function safeHandle(value: string): string {
  const normalized = value.trim().replace(/^@/, "").normalize("NFC");
  if (!HANDLE.test(normalized)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid YouTube handle is required.",
      400,
    );
  }
  return normalized;
}

function comparableHandle(value: string): string {
  return value
    .trim()
    .replace(/^@/, "")
    .normalize("NFC")
    .toLocaleLowerCase("en-US");
}

function providerRejected(message: string): never {
  throw new YouTubeProviderError("provider_rejected", message, 502);
}

function providerLanguageTag(
  value: unknown,
  message: string,
): string {
  const language = requiredProviderText(value, message);
  if (!LANGUAGE_TAG.test(language)) providerRejected(message);
  return language;
}

function optionalProviderLanguageTag(
  value: unknown,
  message: string,
): string | undefined {
  if (value === undefined) return undefined;
  return providerLanguageTag(value, message);
}

function providerRegionCode(
  value: unknown,
  message: string,
): string {
  const region = requiredProviderText(value, message).toUpperCase();
  if (!/^[A-Z]{2}$/.test(region)) providerRejected(message);
  return region;
}

function providerRegionList(
  value: unknown,
  message: string,
): readonly string[] | undefined {
  if (value === undefined) return undefined;
  if (!Array.isArray(value)) providerRejected(message);
  const result = value.map((candidate) =>
    providerRegionCode(candidate, message),
  );
  if (new Set(result).size !== result.length) providerRejected(message);
  return result;
}

function localizedMetadata(
  value: {
    readonly title?: string;
    readonly description?: string;
  } | undefined,
  message: string,
): { readonly title: string; readonly description: string } | undefined {
  if (value === undefined) return undefined;
  if (
    typeof value.title !== "string" ||
    !value.title.trim() ||
    typeof value.description !== "string"
  ) {
    providerRejected(message);
  }
  return {
    title: value.title,
    description: value.description,
  };
}

function requiredProviderText(
  value: unknown,
  message: string,
): string {
  if (typeof value !== "string" || !value.trim()) {
    providerRejected(message);
  }
  return value;
}

function optionalProviderCount(
  value: unknown,
  message: string,
): string | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== "string" || !NON_NEGATIVE_INTEGER.test(value)) {
    providerRejected(message);
  }
  return value;
}

function requiredProviderCount(
  value: unknown,
  message: string,
): string {
  const result = optionalProviderCount(value, message);
  if (result === undefined) providerRejected(message);
  return result;
}

function providerDateTime(
  value: unknown,
  message: string,
): string {
  const result = requiredProviderText(value, message);
  if (!Number.isFinite(Date.parse(result))) {
    providerRejected(message);
  }
  return result;
}

function providerUrl(
  value: unknown,
  message: string,
): string {
  const result = requiredProviderText(value, message);
  try {
    const url = new URL(result);
    if (url.protocol !== "https:" && url.protocol !== "http:") {
      providerRejected(message);
    }
    if (url.protocol === "http:") url.protocol = "https:";
    return url.toString();
  } catch (error) {
    if (error instanceof YouTubeProviderError) throw error;
    providerRejected(message);
  }
}

function optionalProviderUrl(
  value: unknown,
  message: string,
): string | undefined {
  if (value === undefined) return undefined;
  return providerUrl(value, message);
}

function thumbnail(
  thumbnails: Record<string, ApiThumbnail> | undefined,
): YouTubeThumbnail {
  const candidate =
    thumbnails?.maxres ??
    thumbnails?.standard ??
    thumbnails?.high ??
    thumbnails?.medium ??
    thumbnails?.default;
  if (!candidate?.url) {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned a video without a usable thumbnail.",
      502,
    );
  }
  if (
    (candidate.width !== undefined &&
      (!Number.isSafeInteger(candidate.width) || candidate.width < 1)) ||
    (candidate.height !== undefined &&
      (!Number.isSafeInteger(candidate.height) || candidate.height < 1))
  ) {
    providerRejected("YouTube returned an invalid thumbnail.");
  }
  return {
    url: safeYouTubeProviderImageUrl(
      candidate.url,
      "YouTube returned an invalid thumbnail.",
    ),
    ...(candidate.width === undefined ? {} : { width: candidate.width }),
    ...(candidate.height === undefined ? {} : { height: candidate.height }),
  };
}

function liveStreamingDetails(
  api: ApiVideo,
): YouTubeLiveStreamingDetails | undefined {
  const details = api.liveStreamingDetails;
  if (!details) return undefined;
  const result: YouTubeLiveStreamingDetails = {
    ...(details.actualStartTime === undefined
      ? {}
      : { actualStartTime: details.actualStartTime }),
    ...(details.actualEndTime === undefined
      ? {}
      : { actualEndTime: details.actualEndTime }),
    ...(details.scheduledStartTime === undefined
      ? {}
      : { scheduledStartTime: details.scheduledStartTime }),
    ...(details.scheduledEndTime === undefined
      ? {}
      : { scheduledEndTime: details.scheduledEndTime }),
    ...(details.concurrentViewers === undefined
      ? {}
      : { concurrentViewers: details.concurrentViewers }),
  };
  return Object.keys(result).length === 0 ? undefined : result;
}

function publicRegionRestriction(
  value:
    | {
        readonly allowed?: readonly string[];
        readonly blocked?: readonly string[];
      }
    | undefined,
): YouTubeRegionRestriction | undefined {
  if (value === undefined) return undefined;
  const allowed = providerRegionList(
    value.allowed,
    "YouTube returned an invalid allowed-region list.",
  );
  const blocked = providerRegionList(
    value.blocked,
    "YouTube returned an invalid blocked-region list.",
  );
  if (allowed !== undefined && blocked !== undefined) {
    providerRejected("YouTube returned conflicting region restrictions.");
  }
  if (allowed === undefined && blocked === undefined) {
    providerRejected("YouTube returned an empty region restriction.");
  }
  return {
    ...(allowed === undefined ? {} : { allowed }),
    ...(blocked === undefined ? {} : { blocked }),
  };
}

function publicTags(value: unknown): readonly string[] | undefined {
  if (value === undefined) return undefined;
  if (
    !Array.isArray(value) ||
    value.some((tag) => typeof tag !== "string" || !tag.trim())
  ) {
    providerRejected("YouTube returned invalid video tags.");
  }
  return value;
}

function video(
  api: ApiVideo,
  availability: YouTubePublicVideoAvailability,
): YouTubeVideoSummary {
  const id = api.id?.trim();
  const title = api.snippet?.title?.trim();
  const channelId = api.snippet?.channelId?.trim();
  const channelTitle = api.snippet?.channelTitle?.trim();
  const publishedAt = api.snippet?.publishedAt?.trim();
  if (!id || !title || !channelId || !channelTitle || !publishedAt) {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned incomplete video metadata.",
      502,
    );
  }
  const live = liveStreamingDetails(api);
  const categoryId =
    api.snippet?.categoryId === undefined
      ? undefined
      : requiredProviderText(
          api.snippet.categoryId,
          "YouTube returned an invalid video category.",
        );
  if (categoryId !== undefined && !CATEGORY_ID.test(categoryId)) {
    providerRejected("YouTube returned an invalid video category.");
  }
  const tags = publicTags(api.snippet?.tags);
  const defaultLanguage = optionalProviderLanguageTag(
    api.snippet?.defaultLanguage,
    "YouTube returned an invalid default video language.",
  );
  const defaultAudioLanguage = optionalProviderLanguageTag(
    api.snippet?.defaultAudioLanguage,
    "YouTube returned an invalid default audio language.",
  );
  const localized = localizedMetadata(
    api.snippet?.localized,
    "YouTube returned invalid localized video metadata.",
  );
  const caption = api.contentDetails?.caption;
  if (
    caption !== undefined &&
    caption !== "true" &&
    caption !== "false"
  ) {
    providerRejected("YouTube returned an invalid caption state.");
  }
  const definition = api.contentDetails?.definition;
  if (
    definition !== undefined &&
    definition !== "hd" &&
    definition !== "sd"
  ) {
    providerRejected("YouTube returned an invalid video definition.");
  }
  const licensedContent = api.contentDetails?.licensedContent;
  if (
    licensedContent !== undefined &&
    typeof licensedContent !== "boolean"
  ) {
    providerRejected("YouTube returned an invalid licensed-content state.");
  }
  const projection = api.contentDetails?.projection;
  if (
    projection !== undefined &&
    projection !== "rectangular" &&
    projection !== "360"
  ) {
    providerRejected("YouTube returned an invalid video projection.");
  }
  const regionRestriction = publicRegionRestriction(
    api.contentDetails?.regionRestriction,
  );
  return {
    videoId: id,
    title,
    channelId,
    channelTitle,
    publishedAt,
    description: api.snippet?.description ?? "",
    thumbnail: thumbnail(api.snippet?.thumbnails),
    ...(categoryId === undefined ? {} : { categoryId }),
    ...(tags === undefined ? {} : { tags }),
    ...(defaultLanguage === undefined ? {} : { defaultLanguage }),
    ...(defaultAudioLanguage === undefined
      ? {}
      : { defaultAudioLanguage }),
    ...(localized === undefined ? {} : { localized }),
    ...(api.contentDetails?.duration === undefined
      ? {}
      : { duration: api.contentDetails.duration }),
    ...(caption === undefined
      ? {}
      : { captionAvailable: caption === "true" }),
    ...(definition === undefined ? {} : { definition }),
    ...(licensedContent === undefined ? {} : { licensedContent }),
    ...(projection === undefined ? {} : { projection }),
    ...(regionRestriction === undefined ? {} : { regionRestriction }),
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
    availability,
    ...(live === undefined ? {} : { liveStreamingDetails: live }),
  };
}

function addReason(
  reasons: MutableReasonCounts,
  reason: YouTubePublicVideoUnavailableReason,
  amount = 1,
): void {
  reasons[reason] = (reasons[reason] ?? 0) + amount;
}

function filteredSummary(
  reasons: MutableReasonCounts,
): YouTubeFilteredVideoSummary | undefined {
  const total = Object.values(reasons).reduce(
    (sum, value) => sum + (value ?? 0),
    0,
  );
  return total === 0 ? undefined : { total, reasons };
}

function mergeFiltered(
  first: YouTubeFilteredVideoSummary | undefined,
  second: YouTubeFilteredVideoSummary | undefined,
): YouTubeFilteredVideoSummary | undefined {
  if (!first) return second;
  if (!second) return first;
  const reasons: MutableReasonCounts = {};
  for (const [reason, count] of Object.entries(first.reasons)) {
    if (count !== undefined) {
      addReason(
        reasons,
        reason as YouTubePublicVideoUnavailableReason,
        count,
      );
    }
  }
  for (const [reason, count] of Object.entries(second.reasons)) {
    if (count !== undefined) {
      addReason(
        reasons,
        reason as YouTubePublicVideoUnavailableReason,
        count,
      );
    }
  }
  return filteredSummary(reasons);
}

function candidateVideoIds(
  candidates: readonly (string | undefined)[],
): {
  readonly ids: readonly string[];
  readonly filtered?: YouTubeFilteredVideoSummary;
} {
  const ids: string[] = [];
  const reasons: MutableReasonCounts = {};
  for (const candidate of candidates) {
    const id = candidate?.trim();
    if (!id || !VIDEO_ID.test(id)) {
      addReason(reasons, "metadata_invalid");
      continue;
    }
    ids.push(id);
  }
  const filtered = filteredSummary(reasons);
  return {
    ids,
    ...(filtered === undefined ? {} : { filtered }),
  };
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

function providerVideoId(value: unknown, message: string): string {
  const id = requiredProviderText(value, message).trim();
  if (!VIDEO_ID.test(id)) providerRejected(message);
  return id;
}

function providerChannelId(value: unknown, message: string): string {
  const id = requiredProviderText(value, message).trim();
  if (!CHANNEL_ID.test(id)) providerRejected(message);
  return id;
}

function publicChannel(
  item: ApiChannel,
  expectedChannelId: string,
): YouTubePublicChannelDetails {
  const channelId = providerChannelId(
    item.id,
    "YouTube returned an invalid channel identifier.",
  );
  if (channelId !== expectedChannelId) {
    providerRejected("YouTube returned an unexpected channel.");
  }
  const snippet = item.snippet;
  const statistics = item.statistics;
  if (
    !snippet ||
    !statistics ||
    typeof statistics.hiddenSubscriberCount !== "boolean"
  ) {
    providerRejected("YouTube returned incomplete channel metadata.");
  }
  if (
    snippet.description !== undefined &&
    typeof snippet.description !== "string"
  ) {
    providerRejected("YouTube returned invalid channel metadata.");
  }
  const topicCategories = item.topicDetails?.topicCategories ?? [];
  if (!Array.isArray(topicCategories)) {
    providerRejected("YouTube returned invalid channel topics.");
  }
  const topics = topicCategories.map((value) =>
    providerUrl(value, "YouTube returned an invalid channel topic."),
  );
  const viewCount = optionalProviderCount(
    statistics.viewCount,
    "YouTube returned an invalid channel view count.",
  );
  const subscriberCount = optionalProviderCount(
    statistics.subscriberCount,
    "YouTube returned an invalid channel subscriber count.",
  );
  const videoCount = optionalProviderCount(
    statistics.videoCount,
    "YouTube returned an invalid channel video count.",
  );
  const result: YouTubePublicChannelDetails = {
    channelId,
    title: requiredProviderText(
      snippet.title,
      "YouTube returned a channel without a title.",
    ),
    description: snippet.description ?? "",
    publishedAt: providerDateTime(
      snippet.publishedAt,
      "YouTube returned an invalid channel publication date.",
    ),
    statistics: {
      hiddenSubscriberCount: statistics.hiddenSubscriberCount,
      ...(viewCount === undefined ? {} : { viewCount }),
      ...(subscriberCount === undefined ? {} : { subscriberCount }),
      ...(videoCount === undefined ? {} : { videoCount }),
    },
    topicCategories: topics,
    ...(snippet.customUrl === undefined
      ? {}
      : {
          customUrl: requiredProviderText(
            snippet.customUrl,
            "YouTube returned an invalid channel URL.",
          ),
        }),
    ...(snippet.country === undefined
      ? {}
      : {
          country: requiredProviderText(
            snippet.country,
            "YouTube returned an invalid channel country.",
          ),
        }),
    ...(item.contentDetails?.relatedPlaylists?.uploads === undefined
      ? {}
      : {
          uploadsPlaylistId: requiredProviderText(
            item.contentDetails.relatedPlaylists.uploads,
            "YouTube returned an invalid uploads playlist.",
          ),
        }),
  };
  const thumbnails = snippet.thumbnails;
  return thumbnails && Object.keys(thumbnails).length > 0
    ? { ...result, thumbnail: thumbnail(thumbnails) }
    : result;
}

function publicPlaylist(
  item: ApiPlaylist,
  expectedPlaylistId?: string,
  expectedChannelId?: string,
): YouTubePublicPlaylistDetails {
  const playlistId = requiredProviderText(
    item.id,
    "YouTube returned a playlist without an identifier.",
  ).trim();
  if (
    !PLAYLIST_ID.test(playlistId) ||
    (expectedPlaylistId !== undefined && playlistId !== expectedPlaylistId)
  ) {
    providerRejected("YouTube returned an unexpected playlist.");
  }
  const snippet = item.snippet;
  const contentDetails = item.contentDetails;
  const status = item.status;
  if (
    !snippet ||
    !contentDetails ||
    !Number.isSafeInteger(contentDetails.itemCount) ||
    (contentDetails.itemCount ?? -1) < 0 ||
    status?.privacyStatus !== "public"
  ) {
    providerRejected("YouTube returned incomplete public playlist metadata.");
  }
  const channelId = providerChannelId(
    snippet.channelId,
    "YouTube returned an invalid playlist channel.",
  );
  if (
    expectedChannelId !== undefined &&
    channelId !== expectedChannelId
  ) {
    providerRejected("YouTube returned an unexpected playlist channel.");
  }
  const defaultLanguage = optionalProviderLanguageTag(
    snippet.defaultLanguage,
    "YouTube returned an invalid playlist language.",
  );
  const localized = localizedMetadata(
    snippet.localized,
    "YouTube returned invalid localized playlist metadata.",
  );
  if (
    snippet.description !== undefined &&
    typeof snippet.description !== "string"
  ) {
    providerRejected("YouTube returned an invalid playlist description.");
  }
  const result: YouTubePublicPlaylistDetails = {
    playlistId,
    title: requiredProviderText(
      snippet.title,
      "YouTube returned a playlist without a title.",
    ),
    description: snippet.description ?? "",
    publishedAt: providerDateTime(
      snippet.publishedAt,
      "YouTube returned an invalid playlist publication date.",
    ),
    channelId,
    channelTitle: requiredProviderText(
      snippet.channelTitle,
      "YouTube returned a playlist without a channel title.",
    ),
    itemCount: contentDetails.itemCount!,
    privacyStatus: "public",
    ...(defaultLanguage === undefined ? {} : { defaultLanguage }),
    ...(localized === undefined ? {} : { localized }),
  };
  const thumbnails = snippet.thumbnails;
  return thumbnails && Object.keys(thumbnails).length > 0
    ? { ...result, thumbnail: thumbnail(thumbnails) }
    : result;
}

function publicRegions(
  envelope: ListEnvelope<ApiI18nRegion>,
): readonly YouTubePublicRegion[] {
  if (!Array.isArray(envelope.items)) {
    providerRejected("YouTube returned invalid region metadata.");
  }
  const seen = new Set<string>();
  return envelope.items.map((item) => {
    const regionCode = providerRegionCode(
      item.id,
      "YouTube returned an invalid region identifier.",
    );
    const snippetRegion = providerRegionCode(
      item.snippet?.gl,
      "YouTube returned invalid region metadata.",
    );
    if (regionCode !== snippetRegion || seen.has(regionCode)) {
      providerRejected("YouTube returned inconsistent region metadata.");
    }
    seen.add(regionCode);
    return {
      regionCode,
      name: requiredProviderText(
        item.snippet?.name,
        "YouTube returned a region without a name.",
      ),
    };
  });
}

function publicLanguages(
  envelope: ListEnvelope<ApiI18nLanguage>,
): readonly YouTubePublicLanguage[] {
  if (!Array.isArray(envelope.items)) {
    providerRejected("YouTube returned invalid language metadata.");
  }
  const seen = new Set<string>();
  return envelope.items.map((item) => {
    const languageCode = providerLanguageTag(
      item.id,
      "YouTube returned an invalid language identifier.",
    );
    const snippetLanguage = providerLanguageTag(
      item.snippet?.hl,
      "YouTube returned invalid language metadata.",
    );
    if (
      languageCode.toLowerCase() !== snippetLanguage.toLowerCase() ||
      seen.has(languageCode.toLowerCase())
    ) {
      providerRejected("YouTube returned inconsistent language metadata.");
    }
    seen.add(languageCode.toLowerCase());
    return {
      languageCode,
      name: requiredProviderText(
        item.snippet?.name,
        "YouTube returned a language without a name.",
      ),
    };
  });
}

function publicVideoCategories(
  envelope: ListEnvelope<ApiVideoCategory>,
): readonly YouTubePublicVideoCategory[] {
  if (!Array.isArray(envelope.items)) {
    providerRejected("YouTube returned invalid video categories.");
  }
  const seen = new Set<string>();
  return envelope.items.map((item) => {
    const categoryId = requiredProviderText(
      item.id,
      "YouTube returned an invalid video category identifier.",
    );
    if (!CATEGORY_ID.test(categoryId) || seen.has(categoryId)) {
      providerRejected("YouTube returned inconsistent video categories.");
    }
    if (typeof item.snippet?.assignable !== "boolean") {
      providerRejected("YouTube returned an invalid video category.");
    }
    seen.add(categoryId);
    const channelId =
      item.snippet.channelId === undefined
        ? undefined
        : providerChannelId(
            item.snippet.channelId,
            "YouTube returned an invalid video category channel.",
          );
    return {
      categoryId,
      title: requiredProviderText(
        item.snippet.title,
        "YouTube returned a video category without a title.",
      ),
      assignable: item.snippet.assignable,
      ...(channelId === undefined ? {} : { channelId }),
    };
  });
}

function batchStatistics(
  envelope: ApiBatchStatisticsEnvelope,
  requestedIds: readonly string[],
): YouTubeBatchStatisticsResult {
  if (!Array.isArray(envelope.items) || !envelope.summary) {
    providerRejected("YouTube returned incomplete batch statistics.");
  }
  const summary = envelope.summary;
  const requestedVideoCount = requiredProviderCount(
    summary.requestedVideoCount,
    "YouTube returned an invalid requested-video count.",
  );
  const succeededVideoCount = requiredProviderCount(
    summary.succeededVideoCount,
    "YouTube returned an invalid successful-video count.",
  );
  const failedVideoCount = requiredProviderCount(
    summary.failedVideoCount,
    "YouTube returned an invalid failed-video count.",
  );
  if (!Array.isArray(summary.failedVideoIds)) {
    providerRejected("YouTube returned invalid failed-video details.");
  }
  const requested = new Set(requestedIds);
  const failedIds: string[] = [];
  const failedSet = new Set<string>();
  for (const value of summary.failedVideoIds) {
    const id = providerVideoId(
      value,
      "YouTube returned an invalid failed-video identifier.",
    );
    if (!requested.has(id) || failedSet.has(id)) {
      providerRejected("YouTube returned inconsistent failed-video details.");
    }
    failedSet.add(id);
    failedIds.push(id);
  }

  const items: YouTubeVideoStatisticsSnapshot[] = [];
  const succeededSet = new Set<string>();
  for (const item of envelope.items) {
    const videoId = providerVideoId(
      item.id,
      "YouTube returned an invalid video statistics identifier.",
    );
    if (
      !requested.has(videoId) ||
      failedSet.has(videoId) ||
      succeededSet.has(videoId)
    ) {
      providerRejected("YouTube returned inconsistent batch statistics.");
    }
    succeededSet.add(videoId);
    const publishTime =
      item.snippet?.publishTime === undefined
        ? undefined
        : providerDateTime(
            item.snippet.publishTime,
            "YouTube returned an invalid video publish time.",
          );
    const duration =
      item.contentDetails?.duration === undefined
        ? undefined
        : requiredProviderText(
            item.contentDetails.duration,
            "YouTube returned an invalid video duration.",
          );
    if (duration !== undefined && !duration.startsWith("P")) {
      providerRejected("YouTube returned an invalid video duration.");
    }
    const durationMillis = optionalProviderCount(
      item.contentDetails?.durationMillis,
      "YouTube returned an invalid video duration.",
    );
    const viewCount = optionalProviderCount(
      item.statistics?.viewCount,
      "YouTube returned an invalid video view count.",
    );
    const likeCount = optionalProviderCount(
      item.statistics?.likeCount,
      "YouTube returned an invalid video like count.",
    );
    const commentCount = optionalProviderCount(
      item.statistics?.commentCount,
      "YouTube returned an invalid video comment count.",
    );
    items.push({
      videoId,
      ...(publishTime === undefined ? {} : { publishTime }),
      ...(viewCount === undefined ? {} : { viewCount }),
      ...(likeCount === undefined ? {} : { likeCount }),
      ...(commentCount === undefined ? {} : { commentCount }),
      ...(duration === undefined ? {} : { duration }),
      ...(durationMillis === undefined ? {} : { durationMillis }),
    });
  }

  const requestedCount = Number(requestedVideoCount);
  const succeededCount = Number(succeededVideoCount);
  const failedCount = Number(failedVideoCount);
  if (
    requestedCount !== requestedIds.length ||
    succeededCount !== items.length ||
    failedCount !== failedIds.length ||
    succeededCount + failedCount !== requestedCount
  ) {
    providerRejected("YouTube returned inconsistent batch statistics.");
  }
  for (const id of requestedIds) {
    if (!succeededSet.has(id) && !failedSet.has(id)) {
      providerRejected("YouTube returned incomplete batch statistics.");
    }
  }
  const order = new Map(requestedIds.map((id, index) => [id, index]));
  items.sort(
    (left, right) =>
      (order.get(left.videoId) ?? Number.MAX_SAFE_INTEGER) -
      (order.get(right.videoId) ?? Number.MAX_SAFE_INTEGER),
  );
  return {
    items,
    summary: {
      requestedVideoCount,
      succeededVideoCount,
      failedVideoCount,
      failedVideoIds: failedIds,
    },
  };
}

function publicComment(api: ApiComment): YouTubePublicComment {
  const snippet = api.snippet;
  if (
    !snippet ||
    !Number.isSafeInteger(snippet.likeCount) ||
    (snippet.likeCount ?? -1) < 0
  ) {
    providerRejected("YouTube returned incomplete comment metadata.");
  }
  const authorChannelId =
    snippet.authorChannelId?.value === undefined
      ? undefined
      : providerChannelId(
          snippet.authorChannelId.value,
          "YouTube returned an invalid comment author.",
        );
  const profileImageUrl =
    snippet.authorProfileImageUrl === undefined
      ? undefined
      : safeYouTubeProviderImageUrl(
          snippet.authorProfileImageUrl,
          "YouTube returned an invalid comment author image.",
        );
  const channelUrl = optionalProviderUrl(
    snippet.authorChannelUrl,
    "YouTube returned an invalid comment author URL.",
  );
  return {
    commentId: requiredProviderText(
      api.id,
      "YouTube returned a comment without an identifier.",
    ),
    textDisplay: safeYouTubeProviderPlainText(
      snippet.textDisplay,
      "YouTube returned a comment without text.",
    ),
    textFormat: "plainText",
    author: {
      displayName: safeYouTubeProviderPlainText(
        snippet.authorDisplayName,
        "YouTube returned a comment without an author.",
      ),
      ...(profileImageUrl === undefined ? {} : { profileImageUrl }),
      ...(authorChannelId === undefined ? {} : { channelId: authorChannelId }),
      ...(channelUrl === undefined ? {} : { channelUrl }),
    },
    associatedChannelId: providerChannelId(
      snippet.channelId,
      "YouTube returned a comment without channel attribution.",
    ),
    likeCount: snippet.likeCount!,
    publishedAt: providerDateTime(
      snippet.publishedAt,
      "YouTube returned an invalid comment publication date.",
    ),
    updatedAt: providerDateTime(
      snippet.updatedAt,
      "YouTube returned an invalid comment update date.",
    ),
    ...(snippet.parentId === undefined
      ? {}
      : {
          parentId: requiredProviderText(
            snippet.parentId,
            "YouTube returned an invalid reply parent.",
          ),
        }),
  };
}

function publicCommentThread(
  api: ApiCommentThread,
  expectedVideoId: string,
  expectedChannelId: string,
): YouTubePublicCommentThread {
  const snippet = api.snippet;
  if (
    !snippet ||
    !Number.isSafeInteger(snippet.totalReplyCount) ||
    (snippet.totalReplyCount ?? -1) < 0 ||
    typeof snippet.isPublic !== "boolean"
  ) {
    providerRejected("YouTube returned incomplete comment-thread metadata.");
  }
  const videoId = providerVideoId(
    snippet.videoId,
    "YouTube returned invalid comment video attribution.",
  );
  const channelId = providerChannelId(
    snippet.channelId,
    "YouTube returned invalid comment channel attribution.",
  );
  if (videoId !== expectedVideoId || channelId !== expectedChannelId) {
    providerRejected("YouTube returned unexpected comment attribution.");
  }
  if (!snippet.topLevelComment) {
    providerRejected("YouTube returned a comment thread without a comment.");
  }
  const topLevelComment = publicComment(snippet.topLevelComment);
  if (topLevelComment.associatedChannelId !== channelId) {
    providerRejected("YouTube returned unexpected comment attribution.");
  }
  const replies = (api.replies?.comments ?? []).map(publicComment);
  for (const reply of replies) {
    if (
      reply.associatedChannelId !== channelId ||
      reply.parentId !== topLevelComment.commentId
    ) {
      providerRejected("YouTube returned unexpected reply attribution.");
    }
  }
  if (replies.length > snippet.totalReplyCount!) {
    providerRejected("YouTube returned inconsistent reply counts.");
  }
  return {
    threadId: requiredProviderText(
      api.id,
      "YouTube returned a comment thread without an identifier.",
    ),
    videoId,
    channelId,
    topLevelComment,
    replies,
    totalReplyCount: snippet.totalReplyCount!,
    includedReplyCount: replies.length,
    repliesComplete: replies.length === snippet.totalReplyCount,
    isPublic: snippet.isPublic!,
  };
}

export class YouTubeDataClient {
  constructor(private readonly options: YouTubeDataClientOptions) {
    if (!options.serverApiKey.trim()) {
      throw new Error("A restricted YouTube server API key is required.");
    }
  }

  async mostPopular(
    principal: string,
    requestId: string,
    query: PublicVideoQuery = {},
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    const maxResults = pageSize(query.maxResults);
    const regionCode = safeRegion(query.regionCode);
    const pageToken = safeToken(query.pageToken);
    const category = query.videoCategoryId?.trim();
    const cacheKey = [
      "youtube",
      "popular",
      regionCode,
      category ?? "all",
      pageToken ?? "first",
      maxResults,
    ].join(":");
    return this.options.cache.getOrLoad(cacheKey, PUBLIC_CACHE_MS, async () => {
      await this.options.quota.reserve({
        principal,
        bucket: "general",
        amount: 1,
        operation: "videos.list.chart",
        requestId,
      });
      const url = new URL(`${DATA_API}/videos`);
      url.searchParams.set(
        "part",
        "snippet,contentDetails,statistics,status,liveStreamingDetails",
      );
      url.searchParams.set("chart", "mostPopular");
      url.searchParams.set("regionCode", regionCode);
      url.searchParams.set("maxResults", String(maxResults));
      if (category) url.searchParams.set("videoCategoryId", category);
      if (pageToken) url.searchParams.set("pageToken", pageToken);
      return this.loadVideoPage(url, regionCode);
    });
  }

  async explicitSearch(
    principal: string,
    requestId: string,
    query: ExplicitSearchQuery,
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    const text = query.query.trim();
    if (text.length < 3 || text.length > 120) {
      throw new YouTubeProviderError(
        "bad_request",
        "Search must contain between 3 and 120 characters.",
        400,
      );
    }
    const maxResults = pageSize(query.maxResults);
    const regionCode = safeRegion(query.regionCode);
    const pageToken = safeToken(query.pageToken);
    await this.options.quota.reserve({
      principal,
      bucket: "search",
      amount: 1,
      operation: "search.list.explicit",
      requestId,
    });
    const url = new URL(`${DATA_API}/search`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("type", "video");
    url.searchParams.set("videoEmbeddable", "true");
    url.searchParams.set("videoSyndicated", "true");
    url.searchParams.set("safeSearch", "moderate");
    url.searchParams.set("q", text);
    url.searchParams.set("regionCode", regionCode);
    url.searchParams.set("maxResults", String(maxResults));
    if (pageToken) url.searchParams.set("pageToken", pageToken);
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { "x-goog-api-key": this.options.serverApiKey },
    });
    assertProviderResponse(response.status, response.body);
    const results = parseJson<
      ListEnvelope<{ readonly id?: { readonly videoId?: string } }>
    >(response.body);
    const candidates = candidateVideoIds(
      (results.items ?? []).map((item) => item.id?.videoId),
    );
    const details = candidates.ids.length
      ? await this.videoDetailsWithAvailability(
          principal,
          requestId,
          candidates.ids,
          {
            regionCode,
            syndicationConfirmedBySearch: true,
          },
        )
      : { items: [] };
    const filtered = mergeFiltered(
      candidates.filtered,
      details.filtered,
    );
    return {
      items: details.items,
      ...(results.nextPageToken === undefined
        ? {}
        : { nextPageToken: results.nextPageToken }),
      ...(filtered === undefined
        ? {}
        : { filtered }),
    };
  }

  async sharedCatalogueSearch(
    requestId: string,
    query: ExplicitSearchQuery,
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    const text = query.query.trim();
    if (text.length < 3 || text.length > 120) {
      throw new YouTubeProviderError(
        "bad_request",
        "Search must contain between 3 and 120 characters.",
        400,
      );
    }
    const maxResults = pageSize(query.maxResults);
    const regionCode = safeRegion(query.regionCode);
    const pageToken = safeToken(query.pageToken);
    await this.options.quota.reserve({
      principal: "shared-shorts-catalogue",
      bucket: "search",
      amount: 1,
      operation: "search.list.sharedShortsRefresh",
      requestId,
    });
    const url = new URL(`${DATA_API}/search`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("type", "video");
    url.searchParams.set("videoEmbeddable", "true");
    url.searchParams.set("videoSyndicated", "true");
    url.searchParams.set("safeSearch", "moderate");
    url.searchParams.set("q", text);
    url.searchParams.set("regionCode", regionCode);
    url.searchParams.set("maxResults", String(maxResults));
    if (pageToken) url.searchParams.set("pageToken", pageToken);
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { "x-goog-api-key": this.options.serverApiKey },
    });
    assertProviderResponse(response.status, response.body);
    const results = parseJson<
      ListEnvelope<{ readonly id?: { readonly videoId?: string } }>
    >(response.body);
    const candidates = candidateVideoIds(
      (results.items ?? []).map((item) => item.id?.videoId),
    );
    const details = candidates.ids.length
      ? await this.videoDetailsWithAvailability(
          "shared-shorts-catalogue",
          requestId,
          candidates.ids,
          {
            regionCode,
            syndicationConfirmedBySearch: true,
          },
        )
      : { items: [] };
    const filtered = mergeFiltered(
      candidates.filtered,
      details.filtered,
    );
    return {
      items: details.items,
      ...(results.nextPageToken === undefined
        ? {}
        : { nextPageToken: results.nextPageToken }),
      ...(filtered === undefined ? {} : { filtered }),
    };
  }

  async batchVideoStatistics(
    principal: string,
    requestId: string,
    videoIds: readonly string[],
  ): Promise<YouTubeBatchStatisticsResult> {
    const ids = strictVideoIds(videoIds);
    const cacheKey = [
      "youtube",
      "batch-statistics",
      ids.join(","),
    ].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      STATISTICS_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "batchStats",
          amount: 1,
          operation: "videos.batchGetStats",
          requestId,
        });
        const url = new URL(`${DATA_API}/videos:batchGetStats`);
        url.searchParams.set(
          "part",
          "id,snippet,statistics,contentDetails",
        );
        url.searchParams.set("id", ids.join(","));
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        return batchStatistics(
          parseJson<ApiBatchStatisticsEnvelope>(response.body),
          ids,
        );
      },
    );
  }

  async publicChannelDetails(
    principal: string,
    requestId: string,
    channelId: string,
  ): Promise<YouTubePublicChannelDetails> {
    const id = safeChannelId(channelId);
    const cacheKey = ["youtube", "public-channel", id].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      CHANNEL_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "channels.list.publicDetails",
          requestId,
        });
        const url = new URL(`${DATA_API}/channels`);
        url.searchParams.set(
          "part",
          "snippet,contentDetails,statistics,topicDetails",
        );
        url.searchParams.set("id", id);
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        const envelope = parseJson<ListEnvelope<ApiChannel>>(response.body);
        if (!Array.isArray(envelope.items) || envelope.items.length === 0) {
          throw new YouTubeProviderError(
            "not_found",
            "The requested YouTube channel is unavailable.",
            404,
          );
        }
        if (envelope.items.length !== 1) {
          providerRejected("YouTube returned unexpected channel metadata.");
        }
        return publicChannel(envelope.items[0]!, id);
      },
    );
  }

  async publicChannelByHandle(
    principal: string,
    requestId: string,
    handle: string,
  ): Promise<YouTubePublicChannelDetails> {
    const cleanHandle = safeHandle(handle);
    const cacheKey = [
      "youtube",
      "public-channel-handle",
      comparableHandle(cleanHandle),
    ].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      CHANNEL_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "channels.list.forHandle",
          requestId,
        });
        const url = new URL(`${DATA_API}/channels`);
        url.searchParams.set(
          "part",
          "snippet,contentDetails,statistics,topicDetails",
        );
        url.searchParams.set("forHandle", `@${cleanHandle}`);
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        const envelope = parseJson<ListEnvelope<ApiChannel>>(response.body);
        if (!Array.isArray(envelope.items) || envelope.items.length === 0) {
          throw new YouTubeProviderError(
            "not_found",
            "The requested YouTube channel is unavailable.",
            404,
          );
        }
        if (envelope.items.length !== 1) {
          providerRejected("YouTube returned unexpected channel metadata.");
        }
        const item = envelope.items[0]!;
        const channelId = providerChannelId(
          item.id,
          "YouTube returned an invalid channel identifier.",
        );
        const result = publicChannel(item, channelId);
        if (
          result.customUrl === undefined ||
          comparableHandle(result.customUrl) !==
            comparableHandle(cleanHandle)
        ) {
          providerRejected("YouTube returned an unexpected channel handle.");
        }
        return result;
      },
    );
  }

  async publicPlaylistDetails(
    principal: string,
    requestId: string,
    playlistId: string,
  ): Promise<YouTubePublicPlaylistDetails> {
    const id = safePlaylistId(playlistId);
    const cacheKey = ["youtube", "public-playlist", id].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      PLAYLIST_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "playlists.list.publicDetails",
          requestId,
        });
        const url = new URL(`${DATA_API}/playlists`);
        url.searchParams.set("part", "snippet,contentDetails,status");
        url.searchParams.set("id", id);
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        const envelope = parseJson<ListEnvelope<ApiPlaylist>>(response.body);
        if (!Array.isArray(envelope.items) || envelope.items.length === 0) {
          throw new YouTubeProviderError(
            "not_found",
            "The requested YouTube playlist is unavailable.",
            404,
          );
        }
        if (envelope.items.length !== 1) {
          providerRejected("YouTube returned unexpected playlist metadata.");
        }
        return publicPlaylist(envelope.items[0]!, id);
      },
    );
  }

  async publicChannelPlaylists(
    principal: string,
    requestId: string,
    query: PublicChannelPlaylistsQuery,
  ): Promise<YouTubePage<YouTubePublicPlaylistDetails>> {
    const channelId = safeChannelId(query.channelId);
    const pageToken = safeToken(query.pageToken);
    const maxResults = pageSize(query.maxResults);
    const cacheKey = [
      "youtube",
      "public-channel-playlists",
      channelId,
      pageToken ?? "first",
      maxResults,
    ].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      PLAYLIST_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "playlists.list.channel",
          requestId,
        });
        const url = new URL(`${DATA_API}/playlists`);
        url.searchParams.set("part", "snippet,contentDetails,status");
        url.searchParams.set("channelId", channelId);
        url.searchParams.set("maxResults", String(maxResults));
        if (pageToken) url.searchParams.set("pageToken", pageToken);
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        const envelope = parseJson<ListEnvelope<ApiPlaylist>>(response.body);
        if (!Array.isArray(envelope.items)) {
          providerRejected("YouTube returned invalid channel playlists.");
        }
        const items = envelope.items.map((item) =>
          publicPlaylist(item, undefined, channelId),
        );
        const nextPageToken = providerPageToken(envelope.nextPageToken);
        return {
          items,
          ...(nextPageToken === undefined ? {} : { nextPageToken }),
        };
      },
    );
  }

  async publicRegions(
    principal: string,
    requestId: string,
  ): Promise<readonly YouTubePublicRegion[]> {
    return this.options.cache.getOrLoad(
      "youtube:public-regions:v1",
      DICTIONARY_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "i18nRegions.list",
          requestId,
        });
        const url = new URL(`${DATA_API}/i18nRegions`);
        url.searchParams.set("part", "snippet");
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        return publicRegions(
          parseJson<ListEnvelope<ApiI18nRegion>>(response.body),
        );
      },
    );
  }

  async publicLanguages(
    principal: string,
    requestId: string,
  ): Promise<readonly YouTubePublicLanguage[]> {
    return this.options.cache.getOrLoad(
      "youtube:public-languages:v1",
      DICTIONARY_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "i18nLanguages.list",
          requestId,
        });
        const url = new URL(`${DATA_API}/i18nLanguages`);
        url.searchParams.set("part", "snippet");
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        return publicLanguages(
          parseJson<ListEnvelope<ApiI18nLanguage>>(response.body),
        );
      },
    );
  }

  async publicVideoCategories(
    principal: string,
    requestId: string,
    regionCode?: string,
  ): Promise<readonly YouTubePublicVideoCategory[]> {
    const region = safeRegion(regionCode);
    return this.options.cache.getOrLoad(
      `youtube:public-video-categories:${region}:v1`,
      DICTIONARY_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "videoCategories.list",
          requestId,
        });
        const url = new URL(`${DATA_API}/videoCategories`);
        url.searchParams.set("part", "snippet");
        url.searchParams.set("regionCode", region);
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        return publicVideoCategories(
          parseJson<ListEnvelope<ApiVideoCategory>>(response.body),
        );
      },
    );
  }

  async publicCommentThreads(
    principal: string,
    requestId: string,
    query: PublicCommentThreadsQuery,
  ): Promise<YouTubePublicCommentThreadsPage> {
    const videoId = strictVideoIds([query.videoId], 1)[0]!;
    const regionCode = safeRegion(query.regionCode);
    const pageToken = safeToken(query.pageToken);
    const maxResults = commentPageSize(query.maxResults);
    const order = query.order ?? "relevance";
    if (order !== "time" && order !== "relevance") {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported comment order is required.",
        400,
      );
    }
    const cacheKey = [
      "youtube",
      "public-comments",
      videoId,
      regionCode,
      order,
      pageToken ?? "first",
      maxResults,
    ].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      COMMENT_CACHE_MS,
      async () => {
        const videoPage = await this.videoDetailsWithAvailability(
          principal,
          requestId,
          [videoId],
          { regionCode },
        );
        const video = videoPage.items[0];
        if (!video) {
          throw new YouTubeProviderError(
            "not_found",
            "Comments are unavailable for this video.",
            404,
          );
        }

        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "commentThreads.list.public",
          requestId,
        });
        const url = new URL(`${DATA_API}/commentThreads`);
        url.searchParams.set("part", "snippet,replies");
        url.searchParams.set("videoId", videoId);
        url.searchParams.set("textFormat", "plainText");
        url.searchParams.set("order", order);
        url.searchParams.set("maxResults", String(maxResults));
        if (pageToken) url.searchParams.set("pageToken", pageToken);

        let response: Awaited<ReturnType<HttpTransport["send"]>>;
        try {
          response = await this.options.transport.send({
            url: url.toString(),
            headers: { "x-goog-api-key": this.options.serverApiKey },
          });
          assertProviderResponse(response.status, response.body);
        } catch (error) {
          if (
            error instanceof YouTubeProviderError &&
            error.providerReason === "commentsDisabled"
          ) {
            throw new YouTubeProviderError(
              "not_found",
              "Comments are unavailable for this video.",
              404,
            );
          }
          throw error;
        }
        const envelope = parseJson<ListEnvelope<ApiCommentThread>>(
          response.body,
        );
        if (!Array.isArray(envelope.items)) {
          providerRejected("YouTube returned invalid comment threads.");
        }
        const items = envelope.items.map((item) =>
          publicCommentThread(item, videoId, video.channelId),
        );
        const nextPageToken = providerPageToken(envelope.nextPageToken);
        return {
          attribution: {
            source: "youtube",
            videoId,
            videoTitle: video.title,
            channelId: video.channelId,
            channelTitle: video.channelTitle,
          },
          items,
          ...(nextPageToken === undefined ? {} : { nextPageToken }),
        };
      },
    );
  }

  async publicCommentReplies(
    principal: string,
    requestId: string,
    query: PublicCommentRepliesQuery,
  ): Promise<YouTubePublicCommentRepliesPage> {
    const videoId = strictVideoIds([query.videoId], 1)[0]!;
    const threadId = safeCommentId(query.threadId, "comment thread");
    const parentCommentId = safeCommentId(
      query.parentCommentId,
      "parent comment identifier",
    );
    const regionCode = safeRegion(query.regionCode);
    const pageToken = safeToken(query.pageToken);
    const maxResults = commentPageSize(query.maxResults);
    const cacheKey = [
      "youtube",
      "public-comment-replies",
      videoId,
      threadId,
      parentCommentId,
      regionCode,
      pageToken ?? "first",
      maxResults,
    ].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      COMMENT_CACHE_MS,
      async () => {
        const videoPage = await this.videoDetailsWithAvailability(
          principal,
          requestId,
          [videoId],
          { regionCode },
        );
        const video = videoPage.items[0];
        if (!video) {
          throw new YouTubeProviderError(
            "not_found",
            "Replies are unavailable for this video.",
            404,
          );
        }

        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "commentThreads.list.replyAttribution",
          requestId,
        });
        const threadUrl = new URL(`${DATA_API}/commentThreads`);
        threadUrl.searchParams.set("part", "snippet");
        threadUrl.searchParams.set("id", threadId);
        threadUrl.searchParams.set("textFormat", "plainText");
        const threadResponse = await this.options.transport.send({
          url: threadUrl.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(threadResponse.status, threadResponse.body);
        const threadEnvelope = parseJson<ListEnvelope<ApiCommentThread>>(
          threadResponse.body,
        );
        if (
          !Array.isArray(threadEnvelope.items) ||
          threadEnvelope.items.length === 0
        ) {
          throw new YouTubeProviderError(
            "not_found",
            "Replies are unavailable for this comment.",
            404,
          );
        }
        if (threadEnvelope.items.length !== 1) {
          providerRejected("YouTube returned unexpected comment attribution.");
        }
        const thread = publicCommentThread(
          threadEnvelope.items[0]!,
          videoId,
          video.channelId,
        );
        if (
          !thread.isPublic ||
          thread.threadId !== threadId ||
          thread.topLevelComment.commentId !== parentCommentId
        ) {
          providerRejected("YouTube returned unexpected comment attribution.");
        }

        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "comments.list.publicReplies",
          requestId,
        });
        const url = new URL(`${DATA_API}/comments`);
        url.searchParams.set("part", "snippet");
        url.searchParams.set("parentId", parentCommentId);
        url.searchParams.set("textFormat", "plainText");
        url.searchParams.set("maxResults", String(maxResults));
        if (pageToken) url.searchParams.set("pageToken", pageToken);
        const response = await this.options.transport.send({
          url: url.toString(),
          headers: { "x-goog-api-key": this.options.serverApiKey },
        });
        assertProviderResponse(response.status, response.body);
        const envelope = parseJson<ListEnvelope<ApiComment>>(response.body);
        if (!Array.isArray(envelope.items)) {
          providerRejected("YouTube returned invalid comment replies.");
        }
        const items = envelope.items.map(publicComment);
        for (const reply of items) {
          if (
            reply.parentId !== parentCommentId ||
            reply.associatedChannelId !== video.channelId
          ) {
            providerRejected("YouTube returned unexpected reply attribution.");
          }
        }
        const nextPageToken = providerPageToken(envelope.nextPageToken);
        return {
          attribution: {
            source: "youtube",
            videoId,
            videoTitle: video.title,
            channelId: video.channelId,
            channelTitle: video.channelTitle,
            threadId,
            parentCommentId,
          },
          items,
          ...(nextPageToken === undefined ? {} : { nextPageToken }),
        };
      },
    );
  }

  async channel(
    principal: string,
    requestId: string,
    channelId: string,
    accessToken?: string,
  ): Promise<YouTubeChannelIdentity> {
    const cleanId = channelId.trim();
    if (!cleanId && !accessToken) {
      throw new YouTubeProviderError(
        "bad_request",
        "A channel identifier is required.",
        400,
      );
    }
    await this.options.quota.reserve({
      principal,
      bucket: "general",
      amount: 1,
      operation: accessToken ? "channels.list.mine" : "channels.list.id",
      requestId,
    });
    const url = new URL(`${DATA_API}/channels`);
    url.searchParams.set("part", "snippet,contentDetails");
    if (accessToken) {
      url.searchParams.set("mine", "true");
    } else {
      url.searchParams.set("id", cleanId);
    }
    const response = await this.options.transport.send({
      url: url.toString(),
      ...(accessToken
        ? { headers: { authorization: `Bearer ${accessToken}` } }
        : { headers: { "x-goog-api-key": this.options.serverApiKey } }),
    });
    assertProviderResponse(response.status, response.body);
    const envelope = parseJson<ListEnvelope<ApiChannel>>(response.body);
    const item = envelope.items?.[0];
    if (!item?.id || !item.snippet?.title) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube channel is unavailable.",
        404,
      );
    }
    const result: YouTubeChannelIdentity = {
      channelId: item.id,
      title: item.snippet.title,
      ...(item.contentDetails?.relatedPlaylists?.uploads === undefined
        ? {}
        : {
            uploadsPlaylistId:
              item.contentDetails.relatedPlaylists.uploads,
          }),
    };
    const thumbnails = item.snippet.thumbnails;
    if (thumbnails && Object.keys(thumbnails).length > 0) {
      return { ...result, thumbnail: thumbnail(thumbnails) };
    }
    return result;
  }

  async playlistVideos(
    principal: string,
    requestId: string,
    playlistId: string,
    pageToken?: string,
    maxResults?: number,
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    const cleanId = safePlaylistId(playlistId);
    const token = safeToken(pageToken);
    const size = pageSize(maxResults);
    await this.options.quota.reserve({
      principal,
      bucket: "general",
      amount: 1,
      operation: "playlistItems.list",
      requestId,
    });
    const url = new URL(`${DATA_API}/playlistItems`);
    url.searchParams.set("part", "snippet,contentDetails");
    url.searchParams.set("playlistId", cleanId);
    url.searchParams.set("maxResults", String(size));
    if (token) url.searchParams.set("pageToken", token);
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { "x-goog-api-key": this.options.serverApiKey },
    });
    assertProviderResponse(response.status, response.body);
    const envelope = parseJson<ListEnvelope<ApiPlaylistItem>>(response.body);
    const candidates = candidateVideoIds(
      (envelope.items ?? []).map(
        (item) =>
          item.contentDetails?.videoId ?? item.snippet?.resourceId?.videoId,
      ),
    );
    const details = candidates.ids.length
      ? await this.videoDetailsWithAvailability(
          principal,
          requestId,
          candidates.ids,
        )
      : { items: [] };
    const filtered = mergeFiltered(
      candidates.filtered,
      details.filtered,
    );
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      items: details.items,
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
      ...(filtered === undefined
        ? {}
        : { filtered }),
    };
  }

  async videoDetails(
    principal: string,
    requestId: string,
    videoIds: readonly string[],
  ): Promise<readonly YouTubeVideoSummary[]> {
    return (
      await this.videoDetailsWithAvailability(
        principal,
        requestId,
        videoIds,
      )
    ).items;
  }

  async videoDetailsWithAvailability(
    principal: string,
    requestId: string,
    videoIds: readonly string[],
    query: PublicVideoDetailsQuery = {},
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    const ids = Array.from(
      new Set(
        videoIds
          .map((value) => value.trim())
          .filter((value) => VIDEO_ID.test(value)),
      ),
    );
    if (ids.length === 0 || ids.length > 50) {
      throw new YouTubeProviderError(
        "bad_request",
        "Between 1 and 50 valid video identifiers are required.",
        400,
      );
    }
    const regionCode = safeRegion(query.regionCode);
    const syndicationConfirmed =
      query.syndicationConfirmedBySearch === true;
    const cacheKey = [
      "youtube",
      "details",
      regionCode,
      syndicationConfirmed ? "search-syndicated" : "embed-status",
      ids.slice().sort().join(","),
    ].join(":");
    return this.options.cache.getOrLoad(cacheKey, DETAILS_CACHE_MS, async () => {
      await this.options.quota.reserve({
        principal,
        bucket: "general",
        amount: 1,
        operation: "videos.list.ids",
        requestId,
      });
      const url = new URL(`${DATA_API}/videos`);
      url.searchParams.set(
        "part",
        "snippet,contentDetails,statistics,status,liveStreamingDetails",
      );
      url.searchParams.set("id", ids.join(","));
      const page = await this.loadVideoPage(
        url,
        regionCode,
        syndicationConfirmed,
      );
      const order = new Map(ids.map((id, index) => [id, index]));
      const items = page.items
        .slice()
        .sort(
          (left, right) =>
            (order.get(left.videoId) ?? 999) -
            (order.get(right.videoId) ?? 999),
        );
      const returnedCount =
        items.length + (page.filtered?.total ?? 0);
      const missingCount = Math.max(0, ids.length - returnedCount);
      const missing =
        missingCount === 0
          ? undefined
          : {
              total: missingCount,
              reasons: { unavailable: missingCount },
            };
      const filtered = mergeFiltered(page.filtered, missing);
      return {
        items,
        ...(filtered === undefined ? {} : { filtered }),
      };
    });
  }

  private async loadVideoPage(
    url: URL,
    regionCode: string,
    syndicationConfirmedBySearch = false,
  ): Promise<YouTubePage<YouTubeVideoSummary>> {
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { "x-goog-api-key": this.options.serverApiKey },
    });
    assertProviderResponse(response.status, response.body);
    const envelope = parseJson<ListEnvelope<ApiVideo>>(response.body);
    const items: YouTubeVideoSummary[] = [];
    const reasons: MutableReasonCounts = {};
    for (const candidate of envelope.items ?? []) {
      const decision = assessPublicVideo({
        regionCode,
        ...(candidate.status?.privacyStatus === undefined
          ? {}
          : { privacyStatus: candidate.status.privacyStatus }),
        ...(candidate.status?.embeddable === undefined
          ? {}
          : { embeddable: candidate.status.embeddable }),
        ...(candidate.status?.uploadStatus === undefined
          ? {}
          : { uploadStatus: candidate.status.uploadStatus }),
        ...(candidate.status?.madeForKids === undefined
          ? {}
          : { madeForKids: candidate.status.madeForKids }),
        ...(candidate.contentDetails?.contentRating?.ytRating === undefined
          ? {}
          : {
              youtubeAgeRating:
                candidate.contentDetails.contentRating.ytRating,
            }),
        ...(candidate.contentDetails?.regionRestriction === undefined
          ? {}
          : {
              regionRestriction:
                candidate.contentDetails.regionRestriction,
            }),
        ...(candidate.snippet?.liveBroadcastContent === undefined
          ? {}
          : {
              liveBroadcastContent:
                candidate.snippet.liveBroadcastContent,
            }),
        syndicationConfirmedBySearch,
      });
      if (!decision.eligible) {
        addReason(reasons, decision.reason);
        continue;
      }
      try {
        items.push(video(candidate, decision.availability));
      } catch (error) {
        if (
          error instanceof YouTubeProviderError &&
          error.code === "provider_rejected"
        ) {
          addReason(reasons, "metadata_invalid");
          continue;
        }
        throw error;
      }
    }
    const filtered = filteredSummary(reasons);
    return {
      items,
      ...(envelope.nextPageToken === undefined
        ? {}
        : { nextPageToken: envelope.nextPageToken }),
      ...(filtered === undefined ? {} : { filtered }),
    };
  }
}
