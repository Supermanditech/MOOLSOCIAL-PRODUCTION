import { assertProviderResponse, YouTubeProviderError } from "./errors.js";
import type { Clock, YouTubeQuotaPort } from "./ports.js";
import { systemClock } from "./ports.js";
import {
  safeYouTubeProviderImageUrl,
  safeYouTubeProviderPlainText,
} from "./provider_content.js";
import type { HttpTransport } from "./types.js";

const DATA_API = "https://www.googleapis.com/youtube/v3";
const UPLOAD_API = "https://www.googleapis.com/upload/youtube/v3";
const VIDEO_ID = /^[A-Za-z0-9_-]{6,20}$/;
const CHANNEL_ID = /^[A-Za-z0-9_-]{6,64}$/;
const RESOURCE_ID = /^[A-Za-z0-9_-]{1,256}$/;
const ABUSE_ENTITY_TYPE_ID = /^[A-Za-z][A-Za-z0-9._:-]{0,127}$/;
const PAGE_TOKEN = /^[A-Za-z0-9_-]{1,256}$/;
const LANGUAGE_TAG = /^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8}){0,6}$/;
const CAPTION_DOWNLOAD_MAX_BYTES = 1024 * 1024;
const SESSION_TTL_MS = 24 * 60 * 60 * 1000;

type UploadResourceKind =
  | "thumbnail"
  | "caption"
  | "channelBanner"
  | "watermark"
  | "playlistImage";

type CaptionFormat = "sbv" | "scc" | "srt" | "ttml" | "vtt";

type ChannelSectionType =
  | "allPlaylists"
  | "completedEvents"
  | "liveEvents"
  | "multipleChannels"
  | "multiplePlaylists"
  | "popularUploads"
  | "recentUploads"
  | "singlePlaylist"
  | "subscriptions"
  | "upcomingEvents";

const CHANNEL_SECTION_TYPES = new Set<ChannelSectionType>([
  "allPlaylists",
  "completedEvents",
  "liveEvents",
  "multipleChannels",
  "multiplePlaylists",
  "popularUploads",
  "recentUploads",
  "singlePlaylist",
  "subscriptions",
  "upcomingEvents",
]);

interface ListEnvelope<T> {
  readonly items?: readonly T[];
  readonly nextPageToken?: string;
}

interface ApiVideo {
  readonly id?: string;
  readonly snippet?: { readonly channelId?: string };
  readonly status?: { readonly privacyStatus?: string };
}

interface ApiCaption {
  readonly id?: string;
  readonly snippet?: {
    readonly videoId?: string;
    readonly lastUpdated?: string;
    readonly trackKind?: string;
    readonly language?: string;
    readonly name?: string;
    readonly audioTrackType?: string;
    readonly isCC?: boolean;
    readonly isLarge?: boolean;
    readonly isEasyReader?: boolean;
    readonly isDraft?: boolean;
    readonly isAutoSynced?: boolean;
    readonly status?: string;
    readonly failureReason?: string;
  };
}

interface ApiChannel {
  readonly id?: string;
  readonly brandingSettings?: {
    readonly channel?: {
      readonly country?: string;
      readonly description?: string;
      readonly defaultLanguage?: string;
      readonly keywords?: string;
      readonly trackingAnalyticsAccountId?: string;
      readonly unsubscribedTrailer?: string;
    };
  };
}

interface ApiChannelSection {
  readonly id?: string;
  readonly snippet?: {
    readonly channelId?: string;
    readonly type?: string;
    readonly style?: string;
    readonly title?: string;
    readonly position?: number;
  };
  readonly contentDetails?: {
    readonly playlists?: readonly string[];
    readonly channels?: readonly string[];
  };
}

interface ApiPlaylist {
  readonly id?: string;
  readonly snippet?: { readonly channelId?: string };
}

interface ApiPlaylistImage {
  readonly id?: string;
  readonly snippet?: {
    readonly playlistId?: string;
    readonly type?: string;
    readonly width?: number;
    readonly height?: number;
    readonly thumbnails?: Record<
      string,
      {
        readonly url?: string;
        readonly width?: number;
        readonly height?: number;
      }
    >;
  };
}

interface ApiAbuseReason {
  readonly id?: string;
  readonly snippet?: {
    readonly label?: string;
    readonly secondaryReasons?: readonly {
      readonly id?: string;
      readonly label?: string;
    }[];
  };
}

export interface CreatorAssetRequest {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly expectedChannelId: string;
}

export interface CreatorAssetMedia {
  readonly contentType: string;
  readonly contentLength: number;
}

export interface YouTubeDirectAssetUploadSession {
  readonly sessionUrl: string;
  readonly expiresAt: string;
  readonly uploadMethod: "PUT";
  readonly contentType: string;
  readonly contentLength: number;
  readonly resourceKind: UploadResourceKind;
  readonly providerResponseEncoding: "json" | "empty";
}

export interface CreatorThumbnailRequest
  extends CreatorAssetRequest,
    CreatorAssetMedia {
  readonly videoId: string;
}

export interface CreatorCaptionListRequest extends CreatorAssetRequest {
  readonly videoId: string;
}

export interface CreatorCaptionDownloadRequest
  extends CreatorAssetRequest {
  readonly videoId: string;
  readonly captionId: string;
  readonly format: CaptionFormat;
  readonly translatedLanguage?: string;
}

export interface CreatorCaptionInsertRequest
  extends CreatorAssetRequest,
    CreatorAssetMedia {
  readonly videoId: string;
  readonly language: string;
  readonly name: string;
  readonly isDraft: boolean;
}

export interface CreatorCaptionUpdateDraftRequest
  extends CreatorAssetRequest {
  readonly videoId: string;
  readonly captionId: string;
  readonly isDraft: boolean;
}

export interface CreatorCaptionReplacementRequest
  extends CreatorCaptionUpdateDraftRequest,
    CreatorAssetMedia {}

export interface CreatorCaptionDeleteRequest extends CreatorAssetRequest {
  readonly videoId: string;
  readonly captionId: string;
}

export interface CreatorChannelBrandingPatch {
  readonly country?: string | null;
  readonly description?: string | null;
  readonly defaultLanguage?: string | null;
  readonly keywords?: string | null;
  readonly trackingAnalyticsAccountId?: string | null;
  readonly unsubscribedTrailer?: string | null;
}

export interface CreatorChannelBrandingRequest
  extends CreatorAssetRequest {
  readonly patch: CreatorChannelBrandingPatch;
}

export interface CreatorChannelSectionInput {
  readonly type: ChannelSectionType;
  readonly title?: string;
  readonly position: number;
  readonly playlistIds?: readonly string[];
  readonly channelIds?: readonly string[];
}

export interface CreatorChannelSectionMutationRequest
  extends CreatorAssetRequest {
  readonly section: CreatorChannelSectionInput;
}

export interface CreatorChannelSectionUpdateRequest
  extends CreatorChannelSectionMutationRequest {
  readonly sectionId: string;
}

export interface CreatorChannelSectionDeleteRequest
  extends CreatorAssetRequest {
  readonly sectionId: string;
}

export interface CreatorChannelBannerRequest
  extends CreatorAssetRequest,
    CreatorAssetMedia {
  readonly width: number;
  readonly height: number;
}

export interface CreatorApplyChannelBannerRequest
  extends CreatorAssetRequest {
  readonly bannerExternalUrl: string;
}

export interface CreatorWatermarkSetRequest
  extends CreatorAssetRequest,
    CreatorAssetMedia {
  readonly width: number;
  readonly height: number;
  readonly offsetMs: number;
  readonly durationMs: number;
  readonly offsetFrom: "start" | "end";
  readonly corner: "topLeft" | "topRight" | "bottomLeft" | "bottomRight";
}

export interface CreatorPlaylistImagesListRequest
  extends CreatorAssetRequest {
  readonly playlistId: string;
  readonly pageToken?: string;
  readonly maxResults?: number;
}

export interface CreatorPlaylistImageInsertRequest
  extends CreatorAssetRequest,
    CreatorAssetMedia {
  readonly playlistId: string;
  readonly width: number;
  readonly height: number;
}

export interface CreatorPlaylistImageUpdateRequest
  extends CreatorPlaylistImageInsertRequest {
  readonly playlistImageId: string;
}

export interface CreatorPlaylistImageDeleteRequest
  extends CreatorAssetRequest {
  readonly playlistId: string;
  readonly playlistImageId: string;
}

export interface CreatorAbuseReasonsRequest extends CreatorAssetRequest {
  readonly language?: string;
}

export interface CreatorReportAbuseRequest extends CreatorAssetRequest {
  readonly videoId: string;
  readonly reasonId: string;
  readonly secondaryReasonId?: string;
  readonly comments?: string;
  readonly language?: string;
  readonly confirmVideoId: string;
  readonly confirmReasonId: string;
}

export interface CreatorInsertAbuseReportRequest
  extends CreatorAssetRequest {
  readonly subjectTypeId: string;
  readonly subjectId: string;
  readonly abuseTypeIds: readonly string[];
  readonly description?: string;
  readonly relatedEntities?: readonly {
    readonly typeId: string;
    readonly id: string;
  }[];
  readonly confirmSubjectTypeId: string;
  readonly confirmSubjectId: string;
  readonly confirmAbuseTypeIds: readonly string[];
}

export interface YouTubeCreatorAssetsClientOptions {
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
      `A valid ${label} identifier is required.`,
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
  if (typeof value !== "string" || !pattern.test(value.trim())) {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  return value.trim();
}

function expectedChannelId(value: string): string {
  return strictIdentifier(value, CHANNEL_ID, "connected channel");
}

function strictVideoId(value: string): string {
  return strictIdentifier(value, VIDEO_ID, "video");
}

function strictResourceId(value: string, label: string): string {
  return strictIdentifier(value, RESOURCE_ID, label);
}

function actionText(
  value: string,
  label: string,
  maximumLength: number,
  allowEmpty = false,
): string {
  const clean = value.replace(/\r\n?/gu, "\n").normalize("NFC");
  if (
    (!allowEmpty && !clean.trim()) ||
    clean.length > maximumLength ||
    /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/u.test(clean)
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      allowEmpty
        ? `${label} cannot exceed ${maximumLength} characters or contain unsupported characters.`
        : `${label} must contain between 1 and ${maximumLength} characters.`,
      400,
      false,
    );
  }
  return clean;
}

function safeProviderText(value: unknown, message: string): string {
  return safeYouTubeProviderPlainText(value, message);
}

function safeProviderTextAllowEmpty(
  value: unknown,
  message: string,
): string {
  if (typeof value !== "string") {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  return value === "" ? "" : safeProviderText(value, message);
}

function positiveInteger(
  value: number,
  label: string,
  maximum: number,
): number {
  if (!Number.isSafeInteger(value) || value < 1 || value > maximum) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} must be between 1 and ${maximum}.`,
      400,
      false,
    );
  }
  return value;
}

function nonNegativeInteger(
  value: number,
  label: string,
  maximum: number,
): number {
  if (!Number.isSafeInteger(value) || value < 0 || value > maximum) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} must be between 0 and ${maximum}.`,
      400,
      false,
    );
  }
  return value;
}

function providerNonNegativeInteger(
  value: unknown,
  message: string,
): number | undefined {
  if (value === undefined) return undefined;
  if (!Number.isSafeInteger(value) || (value as number) < 0) {
    throw new YouTubeProviderError(
      "provider_rejected",
      message,
      502,
      false,
    );
  }
  return value as number;
}

function languageTag(value: string, label: string): string {
  const clean = value.trim();
  if (!LANGUAGE_TAG.test(clean) || clean.length > 63) {
    throw new YouTubeProviderError(
      "bad_request",
      `A valid ${label} language is required.`,
      400,
      false,
    );
  }
  return clean;
}

function optionalPageToken(value: string | undefined): string | undefined {
  const clean = value?.trim();
  if (!clean) return undefined;
  if (!PAGE_TOKEN.test(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      "Invalid page token.",
      400,
      false,
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
      false,
    );
  }
  return value;
}

function contentType(
  value: string,
  supported: readonly string[],
  label: string,
): string {
  const clean = value.trim().toLowerCase();
  if (!supported.includes(clean)) {
    throw new YouTubeProviderError(
      "bad_request",
      `A supported ${label} content type is required.`,
      400,
      false,
    );
  }
  return clean;
}

function contentLength(
  value: number,
  maximum: number,
  label: string,
): number {
  if (!Number.isSafeInteger(value) || value < 1 || value > maximum) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} must contain between 1 and ${maximum} bytes.`,
      400,
      false,
    );
  }
  return value;
}

function isoAfter(clock: Clock, milliseconds: number): string {
  return new Date(clock.now().getTime() + milliseconds).toISOString();
}

function uploadSessionUrl(value: string, resourcePath: string): string {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned an invalid media upload session.",
      502,
      false,
    );
  }
  const allowedPath = `/upload/youtube/v3/${resourcePath}`;
  if (
    url.protocol !== "https:" ||
    (url.hostname !== "www.googleapis.com" &&
      url.hostname !== "youtube.googleapis.com") ||
    (url.pathname !== allowedPath &&
      url.pathname !== `/resumable${allowedPath}`) ||
    !url.searchParams.get("upload_id") ||
    url.username !== "" ||
    url.password !== "" ||
    url.hash !== ""
  ) {
    throw new YouTubeProviderError(
      "provider_rejected",
      "YouTube returned an invalid media upload session.",
      502,
      false,
    );
  }
  return url.toString();
}

function safeBannerExternalUrl(value: string): string {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid YouTube channel banner URL is required.",
      400,
      false,
    );
  }
  const providerHost =
    url.hostname === "googleusercontent.com" ||
    url.hostname.endsWith(".googleusercontent.com") ||
    url.hostname === "ggpht.com" ||
    url.hostname.endsWith(".ggpht.com");
  if (
    url.protocol !== "https:" ||
    !providerHost ||
    url.username !== "" ||
    url.password !== "" ||
    url.hash !== "" ||
    url.toString().length > 2048
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "A valid YouTube channel banner URL is required.",
      400,
      false,
    );
  }
  return url.toString();
}

function squareDimensions(
  widthInput: number,
  heightInput: number,
  minimum: number,
  maximum: number,
  label: string,
): { readonly width: number; readonly height: number } {
  const width = positiveInteger(widthInput, `${label} width`, maximum);
  const height = positiveInteger(heightInput, `${label} height`, maximum);
  if (width < minimum || height < minimum || width !== height) {
    throw new YouTubeProviderError(
      "bad_request",
      `${label} must be a square image of at least ${minimum} by ${minimum} pixels.`,
      400,
      false,
    );
  }
  return { width, height };
}

function channelSectionPayload(
  input: CreatorChannelSectionInput,
  actorChannelId: string,
): {
  readonly snippet: {
    readonly type: ChannelSectionType;
    readonly style: "horizontalRow";
    readonly position: number;
    readonly title?: string;
  };
  readonly contentDetails?: {
    readonly playlists?: readonly string[];
    readonly channels?: readonly string[];
  };
} {
  if (!CHANNEL_SECTION_TYPES.has(input.type)) {
    throw new YouTubeProviderError(
      "bad_request",
      "A supported YouTube channel section type is required.",
      400,
      false,
    );
  }
  const sectionPosition = nonNegativeInteger(
    input.position,
    "Channel section position",
    9,
  );
  const playlistIds = (input.playlistIds ?? []).map((value) =>
    strictResourceId(value, "playlist"),
  );
  const channelIds = (input.channelIds ?? []).map((value) =>
    strictIdentifier(value, CHANNEL_ID, "channel"),
  );
  if (
    new Set(playlistIds).size !== playlistIds.length ||
    new Set(channelIds).size !== channelIds.length
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "Channel section resources must be unique.",
      400,
      false,
    );
  }
  const titled =
    input.type === "multiplePlaylists" ||
    input.type === "multipleChannels";
  const title =
    input.title === undefined
      ? undefined
      : actionText(input.title, "Channel section title", 100);
  if ((titled && title === undefined) || (!titled && title !== undefined)) {
    throw new YouTubeProviderError(
      "bad_request",
      titled
        ? "This channel section requires a title."
        : "This channel section does not accept a custom title.",
      400,
      false,
    );
  }
  if (title?.includes("<") || title?.includes(">")) {
    throw new YouTubeProviderError(
      "bad_request",
      "Channel section title contains unsupported characters.",
      400,
      false,
    );
  }
  if (input.type === "singlePlaylist" && playlistIds.length !== 1) {
    throw new YouTubeProviderError(
      "bad_request",
      "A single-playlist section requires exactly one playlist.",
      400,
      false,
    );
  }
  if (
    input.type === "multiplePlaylists" &&
    (playlistIds.length < 1 || playlistIds.length > 10)
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "A multiple-playlists section requires between 1 and 10 playlists.",
      400,
      false,
    );
  }
  if (
    input.type === "multipleChannels" &&
    (channelIds.length < 1 ||
      channelIds.length > 10 ||
      channelIds.includes(actorChannelId))
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "A multiple-channels section requires 1 to 10 other channels.",
      400,
      false,
    );
  }
  const usesPlaylists =
    input.type === "singlePlaylist" ||
    input.type === "multiplePlaylists";
  const usesChannels = input.type === "multipleChannels";
  if (
    (!usesPlaylists && playlistIds.length > 0) ||
    (!usesChannels && channelIds.length > 0)
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "The selected channel section does not accept those resources.",
      400,
      false,
    );
  }
  return {
    snippet: {
      type: input.type,
      style: "horizontalRow",
      position: sectionPosition,
      ...(title === undefined ? {} : { title }),
    },
    ...(usesPlaylists
      ? { contentDetails: { playlists: playlistIds } }
      : usesChannels
        ? { contentDetails: { channels: channelIds } }
        : {}),
  };
}

export class YouTubeCreatorAssetsClient {
  private readonly clock: Clock;

  constructor(private readonly options: YouTubeCreatorAssetsClientOptions) {
    this.clock = options.clock ?? systemClock;
  }

  private async api(
    request: CreatorAssetRequest,
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

  private async beginResumableUpload(
    request: CreatorAssetRequest,
    input: {
      readonly resourcePath: string;
      readonly resourceKind: UploadResourceKind;
      readonly operation: string;
      readonly quotaUnits: number;
      readonly contentType: string;
      readonly contentLength: number;
      readonly initiationMethod?: "POST" | "PUT";
      readonly query?: Readonly<Record<string, string>>;
      readonly metadata?: unknown;
      readonly providerResponseEncoding?: "json" | "empty";
    },
  ): Promise<YouTubeDirectAssetUploadSession> {
    await this.options.quota.reserve({
      principal: request.principal,
      bucket: "general",
      amount: input.quotaUnits,
      operation: input.operation,
      requestId: request.requestId,
    });
    const url = new URL(`${UPLOAD_API}/${input.resourcePath}`);
    url.searchParams.set("uploadType", "resumable");
    for (const [name, value] of Object.entries(input.query ?? {})) {
      url.searchParams.set(name, value);
    }
    const response = await this.options.transport.send({
      url: url.toString(),
      method: input.initiationMethod ?? "POST",
      headers: {
        authorization: `Bearer ${request.accessToken}`,
        "x-upload-content-length": String(input.contentLength),
        "x-upload-content-type": input.contentType,
        ...(input.metadata === undefined
          ? {}
          : { "content-type": "application/json; charset=UTF-8" }),
      },
      ...(input.metadata === undefined
        ? {}
        : { body: JSON.stringify(input.metadata) }),
    });
    assertProviderResponse(response.status, response.body);
    const session = response.headers.location;
    if (!session) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube did not return a media upload session.",
        502,
        false,
      );
    }
    return {
      sessionUrl: uploadSessionUrl(session, input.resourcePath),
      expiresAt: isoAfter(this.clock, SESSION_TTL_MS),
      uploadMethod: "PUT",
      contentType: input.contentType,
      contentLength: input.contentLength,
      resourceKind: input.resourceKind,
      providerResponseEncoding:
        input.providerResponseEncoding ?? "json",
    };
  }

  private async ownedVideo(
    request: CreatorAssetRequest,
    videoIdInput: string,
    privateMutation = false,
  ): Promise<{ readonly videoId: string; readonly privacyStatus: string }> {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const videoId = strictVideoId(videoIdInput);
    const url = new URL(`${DATA_API}/videos`);
    url.searchParams.set("part", "snippet,status");
    url.searchParams.set("id", videoId);
    const body = await this.api(
      request,
      "videos.list.creatorAssetPreflight",
      1,
      url,
    );
    const item = parseJson<ListEnvelope<ApiVideo>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube video is unavailable.",
        404,
        false,
      );
    }
    const actualVideoId = providerIdentifier(
      item.id,
      VIDEO_ID,
      "YouTube returned an invalid video.",
    );
    const owner = providerIdentifier(
      item.snippet?.channelId,
      CHANNEL_ID,
      "YouTube returned an invalid video owner.",
    );
    if (actualVideoId !== videoId || owner !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube video does not belong to the connected channel.",
        403,
        false,
      );
    }
    const privacyStatus = item.status?.privacyStatus;
    if (
      privacyStatus !== "private" &&
      privacyStatus !== "public" &&
      privacyStatus !== "unlisted"
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid video privacy state.",
        502,
        false,
      );
    }
    if (privateMutation && privacyStatus !== "private") {
      throw new YouTubeProviderError(
        "permission_denied",
        "Public or unlisted YouTube videos cannot be changed during private Dev proof.",
        403,
        false,
      );
    }
    return { videoId, privacyStatus };
  }

  private async ownedPlaylist(
    request: CreatorAssetRequest,
    playlistIdInput: string,
  ): Promise<string> {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const playlistId = strictResourceId(playlistIdInput, "playlist");
    const url = new URL(`${DATA_API}/playlists`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("id", playlistId);
    const body = await this.api(
      request,
      "playlists.list.creatorAssetPreflight",
      1,
      url,
    );
    const item = parseJson<ListEnvelope<ApiPlaylist>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube playlist is unavailable.",
        404,
        false,
      );
    }
    const actualId = providerIdentifier(
      item.id,
      RESOURCE_ID,
      "YouTube returned an invalid playlist.",
    );
    const owner = providerIdentifier(
      item.snippet?.channelId,
      CHANNEL_ID,
      "YouTube returned an invalid playlist owner.",
    );
    if (actualId !== playlistId || owner !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube playlist does not belong to the connected channel.",
        403,
        false,
      );
    }
    return playlistId;
  }

  private mapCaption(
    value: ApiCaption,
    expectedVideoId?: string,
  ): {
    readonly captionId: string;
    readonly videoId: string;
    readonly language: string;
    readonly name: string;
    readonly isDraft: boolean;
    readonly status: "serving" | "syncing" | "failed";
    readonly lastUpdated?: string;
    readonly trackKind?: string;
    readonly audioTrackType?: string;
    readonly isCC?: boolean;
    readonly isLarge?: boolean;
    readonly isEasyReader?: boolean;
    readonly isAutoSynced?: boolean;
    readonly failureReason?: string;
  } {
    const captionId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid caption.",
    );
    const videoId = providerIdentifier(
      value.snippet?.videoId,
      VIDEO_ID,
      "YouTube returned an invalid caption.",
    );
    if (expectedVideoId !== undefined && videoId !== expectedVideoId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube caption does not belong to the selected video.",
        403,
        false,
      );
    }
    const language = safeProviderText(
      value.snippet?.language,
      "YouTube returned an invalid caption language.",
    );
    const name =
      value.snippet?.name === undefined
        ? ""
        : safeProviderTextAllowEmpty(
            value.snippet.name,
            "YouTube returned an invalid caption name.",
          );
    const status = value.snippet?.status;
    if (
      status !== "serving" &&
      status !== "syncing" &&
      status !== "failed"
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid caption status.",
        502,
        false,
      );
    }
    if (typeof value.snippet?.isDraft !== "boolean") {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid caption.",
        502,
        false,
      );
    }
    const optionalText = (
      input: unknown,
      message: string,
    ): string | undefined =>
      input === undefined ? undefined : safeProviderText(input, message);
    const optionalBoolean = (
      input: unknown,
      message: string,
    ): boolean | undefined => {
      if (input === undefined) return undefined;
      if (typeof input !== "boolean") {
        throw new YouTubeProviderError(
          "provider_rejected",
          message,
          502,
          false,
        );
      }
      return input;
    };
    const lastUpdated =
      value.snippet.lastUpdated === undefined
        ? undefined
        : (() => {
            const clean = safeProviderText(
              value.snippet?.lastUpdated,
              "YouTube returned an invalid caption timestamp.",
            );
            if (!Number.isFinite(Date.parse(clean))) {
              throw new YouTubeProviderError(
                "provider_rejected",
                "YouTube returned an invalid caption timestamp.",
                502,
                false,
              );
            }
            return clean;
          })();
    const trackKind = optionalText(
      value.snippet.trackKind,
      "YouTube returned an invalid caption track kind.",
    );
    const audioTrackType = optionalText(
      value.snippet.audioTrackType,
      "YouTube returned an invalid caption audio track type.",
    );
    const isCC = optionalBoolean(
      value.snippet.isCC,
      "YouTube returned an invalid caption.",
    );
    const isLarge = optionalBoolean(
      value.snippet.isLarge,
      "YouTube returned an invalid caption.",
    );
    const isEasyReader = optionalBoolean(
      value.snippet.isEasyReader,
      "YouTube returned an invalid caption.",
    );
    const isAutoSynced = optionalBoolean(
      value.snippet.isAutoSynced,
      "YouTube returned an invalid caption.",
    );
    const failureReason = optionalText(
      value.snippet.failureReason,
      "YouTube returned an invalid caption failure reason.",
    );
    return {
      captionId,
      videoId,
      language,
      name,
      isDraft: value.snippet.isDraft,
      status,
      ...(lastUpdated === undefined ? {} : { lastUpdated }),
      ...(trackKind === undefined ? {} : { trackKind }),
      ...(audioTrackType === undefined ? {} : { audioTrackType }),
      ...(isCC === undefined ? {} : { isCC }),
      ...(isLarge === undefined ? {} : { isLarge }),
      ...(isEasyReader === undefined ? {} : { isEasyReader }),
      ...(isAutoSynced === undefined ? {} : { isAutoSynced }),
      ...(failureReason === undefined ? {} : { failureReason }),
    };
  }

  private async ownedCaption(
    request: CreatorCaptionDeleteRequest,
    privateMutation: boolean,
  ): Promise<ReturnType<YouTubeCreatorAssetsClient["mapCaption"]>> {
    const video = await this.ownedVideo(
      request,
      request.videoId,
      privateMutation,
    );
    const captionId = strictResourceId(request.captionId, "caption");
    const url = new URL(`${DATA_API}/captions`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("videoId", video.videoId);
    url.searchParams.set("id", captionId);
    const body = await this.api(
      request,
      "captions.list.ownerPreflight",
      50,
      url,
    );
    const item = parseJson<ListEnvelope<ApiCaption>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube caption is unavailable.",
        404,
        false,
      );
    }
    const caption = this.mapCaption(item, video.videoId);
    if (caption.captionId !== captionId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube caption does not belong to the selected video.",
        403,
        false,
      );
    }
    return caption;
  }

  async beginThumbnailSet(
    request: CreatorThumbnailRequest,
  ): Promise<YouTubeDirectAssetUploadSession> {
    const video = await this.ownedVideo(request, request.videoId, true);
    const mediaType = contentType(
      request.contentType,
      ["image/jpeg", "image/png", "application/octet-stream"],
      "thumbnail",
    );
    const bytes = contentLength(
      request.contentLength,
      2 * 1024 * 1024,
      "Thumbnail",
    );
    return this.beginResumableUpload(request, {
      resourcePath: "thumbnails/set",
      resourceKind: "thumbnail",
      operation: "thumbnails.set.resumable.owner",
      quotaUnits: 50,
      contentType: mediaType,
      contentLength: bytes,
      query: { videoId: video.videoId },
    });
  }

  async listCaptions(request: CreatorCaptionListRequest) {
    const video = await this.ownedVideo(request, request.videoId);
    const url = new URL(`${DATA_API}/captions`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("videoId", video.videoId);
    const body = await this.api(
      request,
      "captions.list.owner",
      50,
      url,
    );
    return {
      videoId: video.videoId,
      items: (parseJson<ListEnvelope<ApiCaption>>(body).items ?? []).map(
        (item) => this.mapCaption(item, video.videoId),
      ),
    };
  }

  async downloadCaption(request: CreatorCaptionDownloadRequest) {
    const caption = await this.ownedCaption(request, false);
    if (!["sbv", "scc", "srt", "ttml", "vtt"].includes(request.format)) {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported caption download format is required.",
        400,
        false,
      );
    }
    const translatedLanguage =
      request.translatedLanguage === undefined
        ? undefined
        : languageTag(request.translatedLanguage, "caption translation");
    await this.options.quota.reserve({
      principal: request.principal,
      bucket: "general",
      amount: 200,
      operation: "captions.download.owner",
      requestId: request.requestId,
    });
    const url = new URL(
      `${DATA_API}/captions/${encodeURIComponent(caption.captionId)}`,
    );
    url.searchParams.set("tfmt", request.format);
    if (translatedLanguage) {
      url.searchParams.set("tlang", translatedLanguage);
    }
    const response = await this.options.transport.send({
      url: url.toString(),
      headers: { authorization: `Bearer ${request.accessToken}` },
      responseEncoding: "base64",
      maxResponseBytes: CAPTION_DOWNLOAD_MAX_BYTES,
    });
    assertProviderResponse(response.status, response.body);
    return {
      captionId: caption.captionId,
      videoId: caption.videoId,
      format: request.format,
      ...(translatedLanguage === undefined
        ? {}
        : { translatedLanguage }),
      encoding: "base64" as const,
      data: response.body,
      byteLimit: CAPTION_DOWNLOAD_MAX_BYTES,
      contentType:
        response.headers["content-type"] ?? "application/octet-stream",
    };
  }

  async beginCaptionInsert(
    request: CreatorCaptionInsertRequest,
  ): Promise<YouTubeDirectAssetUploadSession> {
    const video = await this.ownedVideo(request, request.videoId, true);
    const mediaType = contentType(
      request.contentType,
      [
        "application/octet-stream",
        "application/ttml+xml",
        "application/x-subrip",
        "application/xml",
        "text/plain",
        "text/srt",
        "text/vtt",
      ],
      "caption",
    );
    const bytes = contentLength(
      request.contentLength,
      100 * 1024 * 1024,
      "Caption",
    );
    const language = languageTag(request.language, "caption");
    const name = actionText(request.name, "Caption name", 150, true);
    if (typeof request.isDraft !== "boolean") {
      throw new YouTubeProviderError(
        "bad_request",
        "Caption draft state must be confirmed.",
        400,
        false,
      );
    }
    return this.beginResumableUpload(request, {
      resourcePath: "captions",
      resourceKind: "caption",
      operation: "captions.insert.resumable.owner",
      quotaUnits: 400,
      contentType: mediaType,
      contentLength: bytes,
      query: { part: "snippet" },
      metadata: {
        snippet: {
          videoId: video.videoId,
          language,
          name,
          isDraft: request.isDraft,
        },
      },
    });
  }

  async updateCaptionDraft(request: CreatorCaptionUpdateDraftRequest) {
    const caption = await this.ownedCaption(request, true);
    if (typeof request.isDraft !== "boolean") {
      throw new YouTubeProviderError(
        "bad_request",
        "Caption draft state must be confirmed.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/captions`);
    url.searchParams.set("part", "snippet");
    const body = await this.api(
      request,
      "captions.update.draft.owner",
      450,
      url,
      "PUT",
      { id: caption.captionId, snippet: { isDraft: request.isDraft } },
    );
    return this.mapCaption(parseJson<ApiCaption>(body), caption.videoId);
  }

  async beginCaptionReplacement(
    request: CreatorCaptionReplacementRequest,
  ): Promise<YouTubeDirectAssetUploadSession> {
    const caption = await this.ownedCaption(request, true);
    const mediaType = contentType(
      request.contentType,
      [
        "application/octet-stream",
        "application/ttml+xml",
        "application/x-subrip",
        "application/xml",
        "text/plain",
        "text/srt",
        "text/vtt",
      ],
      "caption",
    );
    const bytes = contentLength(
      request.contentLength,
      100 * 1024 * 1024,
      "Caption",
    );
    if (typeof request.isDraft !== "boolean") {
      throw new YouTubeProviderError(
        "bad_request",
        "Caption draft state must be confirmed.",
        400,
        false,
      );
    }
    return this.beginResumableUpload(request, {
      resourcePath: "captions",
      resourceKind: "caption",
      operation: "captions.update.resumable.owner",
      quotaUnits: 450,
      contentType: mediaType,
      contentLength: bytes,
      query: { part: "snippet" },
      initiationMethod: "PUT",
      metadata: {
        id: caption.captionId,
        snippet: { isDraft: request.isDraft },
      },
    });
  }

  async deleteCaption(request: CreatorCaptionDeleteRequest) {
    const caption = await this.ownedCaption(request, true);
    const url = new URL(`${DATA_API}/captions`);
    url.searchParams.set("id", caption.captionId);
    await this.api(
      request,
      "captions.delete.owner",
      50,
      url,
      "DELETE",
    );
    return { deleted: true as const, captionId: caption.captionId };
  }

  private async currentChannelBranding(request: CreatorAssetRequest) {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const url = new URL(`${DATA_API}/channels`);
    url.searchParams.set("part", "brandingSettings");
    url.searchParams.set("mine", "true");
    const body = await this.api(
      request,
      "channels.list.branding.ownerPreflight",
      1,
      url,
    );
    const item = parseJson<ListEnvelope<ApiChannel>>(body).items?.[0];
    const actualId = providerIdentifier(
      item?.id,
      CHANNEL_ID,
      "YouTube returned an invalid connected channel.",
    );
    if (actualId !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "YouTube returned a different connected channel.",
        403,
        false,
      );
    }
    return item?.brandingSettings?.channel ?? {};
  }

  async updateChannelBranding(request: CreatorChannelBrandingRequest) {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const allowed = new Set([
      "country",
      "description",
      "defaultLanguage",
      "keywords",
      "trackingAnalyticsAccountId",
      "unsubscribedTrailer",
    ]);
    const keys = Object.keys(request.patch);
    if (
      keys.length === 0 ||
      keys.some((key) => !allowed.has(key))
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "At least one supported channel branding field is required.",
        400,
        false,
      );
    }
    const current = await this.currentChannelBranding(request);
    const cleanCurrent = {
      ...(typeof current.country === "string"
        ? {
            country: safeProviderTextAllowEmpty(
              current.country,
              "YouTube returned invalid channel branding.",
            ),
          }
        : {}),
      ...(typeof current.description === "string"
        ? {
            description: safeProviderTextAllowEmpty(
              current.description,
              "YouTube returned invalid channel branding.",
            ),
          }
        : {}),
      ...(typeof current.defaultLanguage === "string"
        ? {
            defaultLanguage: safeProviderTextAllowEmpty(
              current.defaultLanguage,
              "YouTube returned invalid channel branding.",
            ),
          }
        : {}),
      ...(typeof current.keywords === "string"
        ? {
            keywords: safeProviderTextAllowEmpty(
              current.keywords,
              "YouTube returned invalid channel branding.",
            ),
          }
        : {}),
      ...(typeof current.trackingAnalyticsAccountId === "string"
        ? {
            trackingAnalyticsAccountId:
              safeProviderTextAllowEmpty(
                current.trackingAnalyticsAccountId,
                "YouTube returned invalid channel branding.",
              ),
          }
        : {}),
      ...(typeof current.unsubscribedTrailer === "string"
        ? {
            unsubscribedTrailer: safeProviderTextAllowEmpty(
              current.unsubscribedTrailer,
              "YouTube returned invalid channel branding.",
            ),
          }
        : {}),
    };
    const channel: Record<string, string> = { ...cleanCurrent };
    const nullable = (
      name: keyof CreatorChannelBrandingPatch,
    ): string | undefined => {
      const value = request.patch[name];
      if (value === undefined) return undefined;
      if (value === null) return "";
      return value;
    };
    const country = nullable("country");
    if (country !== undefined) {
      const normalized = country.trim().toUpperCase();
      if (normalized !== "" && !/^[A-Z]{2}$/u.test(normalized)) {
        throw new YouTubeProviderError(
          "bad_request",
          "Channel country must be a two-letter country code.",
          400,
          false,
        );
      }
      channel.country = normalized;
    }
    const description = nullable("description");
    if (description !== undefined) {
      channel.description = actionText(
        description,
        "Channel description",
        1000,
        true,
      );
    }
    const defaultLanguage = nullable("defaultLanguage");
    if (defaultLanguage !== undefined) {
      channel.defaultLanguage =
        defaultLanguage.trim() === ""
          ? ""
          : languageTag(defaultLanguage, "channel default");
    }
    const keywords = nullable("keywords");
    if (keywords !== undefined) {
      channel.keywords = actionText(
        keywords,
        "Channel keywords",
        500,
        true,
      );
    }
    const trackingId = nullable("trackingAnalyticsAccountId");
    if (trackingId !== undefined) {
      const clean = trackingId.trim();
      if (clean !== "" && !/^[A-Za-z0-9_-]{1,64}$/u.test(clean)) {
        throw new YouTubeProviderError(
          "bad_request",
          "A valid channel analytics tracking identifier is required.",
          400,
          false,
        );
      }
      channel.trackingAnalyticsAccountId = clean;
    }
    const trailer = nullable("unsubscribedTrailer");
    if (trailer !== undefined) {
      const clean = trailer.trim();
      if (clean !== "") {
        await this.ownedVideo(request, clean);
      }
      channel.unsubscribedTrailer =
        clean === "" ? "" : strictVideoId(clean);
    }
    const url = new URL(`${DATA_API}/channels`);
    url.searchParams.set("part", "brandingSettings");
    const body = await this.api(
      request,
      "channels.update.branding.owner",
      50,
      url,
      "PUT",
      { id: actorChannelId, brandingSettings: { channel } },
    );
    const item = parseJson<ApiChannel>(body);
    if (
      providerIdentifier(
        item.id,
        CHANNEL_ID,
        "YouTube returned an invalid channel update.",
      ) !== actorChannelId
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid channel update.",
        502,
        false,
      );
    }
    return { channelId: actorChannelId, branding: channel };
  }

  private mapChannelSection(value: ApiChannelSection, actorChannelId: string) {
    const sectionId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid channel section.",
    );
    const owner = providerIdentifier(
      value.snippet?.channelId,
      CHANNEL_ID,
      "YouTube returned an invalid channel section.",
    );
    if (owner !== actorChannelId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube channel section does not belong to the connected channel.",
        403,
        false,
      );
    }
    const type = value.snippet?.type;
    if (
      typeof type !== "string" ||
      !CHANNEL_SECTION_TYPES.has(type as ChannelSectionType)
    ) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid channel section.",
        502,
        false,
      );
    }
    const position = providerNonNegativeInteger(
      value.snippet?.position,
      "YouTube returned an invalid channel section.",
    );
    if (position === undefined || position > 9) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid channel section.",
        502,
        false,
      );
    }
    const title =
      value.snippet?.title === undefined
        ? undefined
        : safeProviderText(
            value.snippet.title,
            "YouTube returned an invalid channel section title.",
          );
    const playlists = (value.contentDetails?.playlists ?? []).map(
      (item) =>
        providerIdentifier(
          item,
          RESOURCE_ID,
          "YouTube returned an invalid channel section playlist.",
        ),
    );
    const channels = (value.contentDetails?.channels ?? []).map((item) =>
      providerIdentifier(
        item,
        CHANNEL_ID,
        "YouTube returned an invalid channel section channel.",
      ),
    );
    return {
      sectionId,
      channelId: owner,
      type: type as ChannelSectionType,
      style: "horizontalRow" as const,
      position,
      ...(title === undefined ? {} : { title }),
      ...(playlists.length === 0 ? {} : { playlistIds: playlists }),
      ...(channels.length === 0 ? {} : { channelIds: channels }),
    };
  }

  private async ownedChannelSection(
    request: CreatorChannelSectionDeleteRequest,
  ) {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const sectionId = strictResourceId(request.sectionId, "channel section");
    const url = new URL(`${DATA_API}/channelSections`);
    url.searchParams.set("part", "snippet,contentDetails");
    url.searchParams.set("id", sectionId);
    const body = await this.api(
      request,
      "channelSections.list.ownerPreflight",
      1,
      url,
    );
    const item =
      parseJson<ListEnvelope<ApiChannelSection>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube channel section is unavailable.",
        404,
        false,
      );
    }
    const mapped = this.mapChannelSection(item, actorChannelId);
    if (mapped.sectionId !== sectionId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube channel section does not belong to the connected channel.",
        403,
        false,
      );
    }
    return mapped;
  }

  async listChannelSections(request: CreatorAssetRequest) {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const url = new URL(`${DATA_API}/channelSections`);
    url.searchParams.set("part", "snippet,contentDetails");
    url.searchParams.set("mine", "true");
    const body = await this.api(
      request,
      "channelSections.list.mine.owner",
      1,
      url,
    );
    return {
      channelId: actorChannelId,
      items: (
        parseJson<ListEnvelope<ApiChannelSection>>(body).items ?? []
      ).map((item) => this.mapChannelSection(item, actorChannelId)),
    };
  }

  async insertChannelSection(
    request: CreatorChannelSectionMutationRequest,
  ) {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const payload = channelSectionPayload(request.section, actorChannelId);
    const url = new URL(`${DATA_API}/channelSections`);
    url.searchParams.set("part", "snippet,contentDetails");
    const body = await this.api(
      request,
      "channelSections.insert.owner",
      50,
      url,
      "POST",
      payload,
    );
    return this.mapChannelSection(
      parseJson<ApiChannelSection>(body),
      actorChannelId,
    );
  }

  async updateChannelSection(
    request: CreatorChannelSectionUpdateRequest,
  ) {
    const actorChannelId = expectedChannelId(request.expectedChannelId);
    const existing = await this.ownedChannelSection(request);
    const payload = channelSectionPayload(request.section, actorChannelId);
    const url = new URL(`${DATA_API}/channelSections`);
    url.searchParams.set("part", "snippet,contentDetails");
    const body = await this.api(
      request,
      "channelSections.update.owner",
      50,
      url,
      "PUT",
      { id: existing.sectionId, ...payload },
    );
    return this.mapChannelSection(
      parseJson<ApiChannelSection>(body),
      actorChannelId,
    );
  }

  async deleteChannelSection(
    request: CreatorChannelSectionDeleteRequest,
  ) {
    const existing = await this.ownedChannelSection(request);
    const url = new URL(`${DATA_API}/channelSections`);
    url.searchParams.set("id", existing.sectionId);
    await this.api(
      request,
      "channelSections.delete.owner",
      50,
      url,
      "DELETE",
    );
    return { deleted: true as const, sectionId: existing.sectionId };
  }

  async beginChannelBannerInsert(
    request: CreatorChannelBannerRequest,
  ): Promise<YouTubeDirectAssetUploadSession> {
    expectedChannelId(request.expectedChannelId);
    const mediaType = contentType(
      request.contentType,
      ["image/jpeg", "image/png", "application/octet-stream"],
      "channel banner",
    );
    const bytes = contentLength(
      request.contentLength,
      6 * 1024 * 1024,
      "Channel banner",
    );
    const width = positiveInteger(
      request.width,
      "Channel banner width",
      8192,
    );
    const height = positiveInteger(
      request.height,
      "Channel banner height",
      8192,
    );
    if (
      width < 2048 ||
      height < 1152 ||
      Math.abs(width / height - 16 / 9) > 0.02
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "Channel banner must be a 16:9 image of at least 2048 by 1152 pixels.",
        400,
        false,
      );
    }
    return this.beginResumableUpload(request, {
      resourcePath: "channelBanners/insert",
      resourceKind: "channelBanner",
      operation: "channelBanners.insert.resumable.owner",
      quotaUnits: 50,
      contentType: mediaType,
      contentLength: bytes,
    });
  }

  async applyChannelBanner(request: CreatorApplyChannelBannerRequest) {
    const channelId = expectedChannelId(request.expectedChannelId);
    const bannerExternalUrl = safeBannerExternalUrl(
      request.bannerExternalUrl,
    );
    await this.currentChannelBranding(request);
    const url = new URL(`${DATA_API}/channels`);
    url.searchParams.set("part", "brandingSettings");
    const body = await this.api(
      request,
      "channels.update.banner.owner",
      50,
      url,
      "PUT",
      {
        id: channelId,
        brandingSettings: { image: { bannerExternalUrl } },
      },
    );
    const returnedId = providerIdentifier(
      parseJson<ApiChannel>(body).id,
      CHANNEL_ID,
      "YouTube returned an invalid channel banner update.",
    );
    if (returnedId !== channelId) {
      throw new YouTubeProviderError(
        "provider_rejected",
        "YouTube returned an invalid channel banner update.",
        502,
        false,
      );
    }
    return { channelId, bannerApplied: true as const };
  }

  async beginWatermarkSet(
    request: CreatorWatermarkSetRequest,
  ): Promise<YouTubeDirectAssetUploadSession> {
    const channelId = expectedChannelId(request.expectedChannelId);
    const mediaType = contentType(
      request.contentType,
      ["image/jpeg", "image/png", "application/octet-stream"],
      "watermark",
    );
    const bytes = contentLength(
      request.contentLength,
      10 * 1024 * 1024,
      "Watermark",
    );
    squareDimensions(
      request.width,
      request.height,
      150,
      1000,
      "Watermark",
    );
    const offsetMs = nonNegativeInteger(
      request.offsetMs,
      "Watermark offset",
      86_400_000,
    );
    const durationMs = positiveInteger(
      request.durationMs,
      "Watermark duration",
      86_400_000,
    );
    if (request.offsetFrom !== "start" && request.offsetFrom !== "end") {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported watermark offset is required.",
        400,
        false,
      );
    }
    const corners = [
      "topLeft",
      "topRight",
      "bottomLeft",
      "bottomRight",
    ];
    if (!corners.includes(request.corner)) {
      throw new YouTubeProviderError(
        "bad_request",
        "A supported watermark position is required.",
        400,
        false,
      );
    }
    return this.beginResumableUpload(request, {
      resourcePath: "watermarks/set",
      resourceKind: "watermark",
      operation: "watermarks.set.resumable.owner",
      quotaUnits: 50,
      contentType: mediaType,
      contentLength: bytes,
      query: { channelId },
      providerResponseEncoding: "empty",
      metadata: {
        targetChannelId: channelId,
        timing: {
          type:
            request.offsetFrom === "start"
              ? "offsetFromStart"
              : "offsetFromEnd",
          offsetMs,
          durationMs,
        },
        position: {
          type: "corner",
          cornerPosition: request.corner,
        },
      },
    });
  }

  async unsetWatermark(request: CreatorAssetRequest) {
    const channelId = expectedChannelId(request.expectedChannelId);
    const url = new URL(`${DATA_API}/watermarks/unset`);
    url.searchParams.set("channelId", channelId);
    await this.api(
      request,
      "watermarks.unset.owner",
      50,
      url,
      "POST",
    );
    return { channelId, watermarkUnset: true as const };
  }

  private mapPlaylistImage(value: ApiPlaylistImage, playlistId: string) {
    const playlistImageId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid playlist image.",
    );
    const returnedPlaylistId = providerIdentifier(
      value.snippet?.playlistId,
      RESOURCE_ID,
      "YouTube returned an invalid playlist image.",
    );
    if (returnedPlaylistId !== playlistId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube playlist image does not belong to the selected playlist.",
        403,
        false,
      );
    }
    const width = providerNonNegativeInteger(
      value.snippet?.width,
      "YouTube returned an invalid playlist image.",
    );
    const height = providerNonNegativeInteger(
      value.snippet?.height,
      "YouTube returned an invalid playlist image.",
    );
    const thumbnails = value.snippet?.thumbnails;
    const thumbnail =
      thumbnails?.maxres ??
      thumbnails?.standard ??
      thumbnails?.high ??
      thumbnails?.medium ??
      thumbnails?.default;
    const imageUrl =
      thumbnail?.url === undefined
        ? undefined
        : safeYouTubeProviderImageUrl(
            thumbnail.url,
            "YouTube returned an invalid playlist image URL.",
          );
    return {
      playlistImageId,
      playlistId: returnedPlaylistId,
      type:
        value.snippet?.type === undefined
          ? "hero"
          : safeProviderText(
              value.snippet.type,
              "YouTube returned an invalid playlist image type.",
            ),
      ...(width === undefined ? {} : { width }),
      ...(height === undefined ? {} : { height }),
      ...(imageUrl === undefined ? {} : { imageUrl }),
    };
  }

  private async ownedPlaylistImage(
    request: CreatorPlaylistImageDeleteRequest,
  ) {
    const playlistId = await this.ownedPlaylist(
      request,
      request.playlistId,
    );
    const playlistImageId = strictResourceId(
      request.playlistImageId,
      "playlist image",
    );
    const url = new URL(`${DATA_API}/playlistImages`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("id", playlistImageId);
    const body = await this.api(
      request,
      "playlistImages.list.ownerPreflight",
      1,
      url,
    );
    const item =
      parseJson<ListEnvelope<ApiPlaylistImage>>(body).items?.[0];
    if (!item) {
      throw new YouTubeProviderError(
        "not_found",
        "The requested YouTube playlist image is unavailable.",
        404,
        false,
      );
    }
    const mapped = this.mapPlaylistImage(item, playlistId);
    if (mapped.playlistImageId !== playlistImageId) {
      throw new YouTubeProviderError(
        "permission_denied",
        "The YouTube playlist image does not belong to the selected playlist.",
        403,
        false,
      );
    }
    return mapped;
  }

  async listPlaylistImages(request: CreatorPlaylistImagesListRequest) {
    const playlistId = await this.ownedPlaylist(
      request,
      request.playlistId,
    );
    const page = optionalPageToken(request.pageToken);
    const maxResults =
      request.maxResults === undefined
        ? 5
        : positiveInteger(
            request.maxResults,
            "Playlist image page size",
            50,
          );
    const url = new URL(`${DATA_API}/playlistImages`);
    url.searchParams.set("part", "snippet");
    url.searchParams.set("playlistId", playlistId);
    url.searchParams.set("maxResults", String(maxResults));
    if (page) url.searchParams.set("pageToken", page);
    const body = await this.api(
      request,
      "playlistImages.list.owner",
      1,
      url,
    );
    const envelope = parseJson<ListEnvelope<ApiPlaylistImage>>(body);
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      playlistId,
      items: (envelope.items ?? []).map((item) =>
        this.mapPlaylistImage(item, playlistId),
      ),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async beginPlaylistImageInsert(
    request: CreatorPlaylistImageInsertRequest,
  ): Promise<YouTubeDirectAssetUploadSession> {
    const playlistId = await this.ownedPlaylist(
      request,
      request.playlistId,
    );
    const mediaType = contentType(
      request.contentType,
      ["image/jpeg", "image/png"],
      "playlist image",
    );
    const bytes = contentLength(
      request.contentLength,
      2 * 1024 * 1024,
      "Playlist image",
    );
    const dimensions = squareDimensions(
      request.width,
      request.height,
      1,
      8192,
      "Playlist image",
    );
    return this.beginResumableUpload(request, {
      resourcePath: "playlistImages",
      resourceKind: "playlistImage",
      operation: "playlistImages.insert.resumable.owner",
      quotaUnits: 50,
      contentType: mediaType,
      contentLength: bytes,
      query: { part: "snippet" },
      metadata: {
        snippet: { playlistId, type: "hero", ...dimensions },
      },
    });
  }

  async beginPlaylistImageUpdate(
    request: CreatorPlaylistImageUpdateRequest,
  ): Promise<YouTubeDirectAssetUploadSession> {
    const existing = await this.ownedPlaylistImage(request);
    const mediaType = contentType(
      request.contentType,
      ["image/jpeg", "image/png"],
      "playlist image",
    );
    const bytes = contentLength(
      request.contentLength,
      2 * 1024 * 1024,
      "Playlist image",
    );
    const dimensions = squareDimensions(
      request.width,
      request.height,
      1,
      8192,
      "Playlist image",
    );
    return this.beginResumableUpload(request, {
      resourcePath: "playlistImages",
      resourceKind: "playlistImage",
      operation: "playlistImages.update.resumable.owner",
      quotaUnits: 50,
      contentType: mediaType,
      contentLength: bytes,
      query: { part: "snippet" },
      initiationMethod: "PUT",
      metadata: {
        id: existing.playlistImageId,
        snippet: {
          playlistId: existing.playlistId,
          type: "hero",
          ...dimensions,
        },
      },
    });
  }

  async deletePlaylistImage(request: CreatorPlaylistImageDeleteRequest) {
    const existing = await this.ownedPlaylistImage(request);
    const url = new URL(`${DATA_API}/playlistImages`);
    url.searchParams.set("id", existing.playlistImageId);
    await this.api(
      request,
      "playlistImages.delete.owner",
      50,
      url,
      "DELETE",
    );
    return {
      deleted: true as const,
      playlistImageId: existing.playlistImageId,
      playlistId: existing.playlistId,
    };
  }

  private mapAbuseReason(value: ApiAbuseReason) {
    const reasonId = providerIdentifier(
      value.id,
      RESOURCE_ID,
      "YouTube returned an invalid abuse-report reason.",
    );
    const label = safeProviderText(
      value.snippet?.label,
      "YouTube returned an invalid abuse-report reason.",
    );
    return {
      reasonId,
      label,
      secondaryReasons: (value.snippet?.secondaryReasons ?? []).map(
        (secondary) => ({
          reasonId: providerIdentifier(
            secondary.id,
            RESOURCE_ID,
            "YouTube returned an invalid abuse-report reason.",
          ),
          label: safeProviderText(
            secondary.label,
            "YouTube returned an invalid abuse-report reason.",
          ),
        }),
      ),
    };
  }

  async listVideoAbuseReasons(request: CreatorAbuseReasonsRequest) {
    expectedChannelId(request.expectedChannelId);
    const language =
      request.language === undefined
        ? undefined
        : languageTag(request.language, "abuse-report");
    const url = new URL(`${DATA_API}/videoAbuseReportReasons`);
    url.searchParams.set("part", "id,snippet");
    if (language) url.searchParams.set("hl", language);
    const body = await this.api(
      request,
      "videoAbuseReportReasons.list.owner",
      1,
      url,
    );
    return {
      ...(language === undefined ? {} : { language }),
      items: (
        parseJson<ListEnvelope<ApiAbuseReason>>(body).items ?? []
      ).map((item) => this.mapAbuseReason(item)),
    };
  }

  async reportVideoAbuse(request: CreatorReportAbuseRequest) {
    expectedChannelId(request.expectedChannelId);
    const videoId = strictVideoId(request.videoId);
    const reasonId = strictResourceId(request.reasonId, "abuse reason");
    if (
      request.confirmVideoId.trim() !== videoId ||
      request.confirmReasonId.trim() !== reasonId
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "Confirm the selected video and abuse-report reason.",
        400,
        false,
      );
    }
    const secondaryReasonId =
      request.secondaryReasonId === undefined
        ? undefined
        : strictResourceId(
            request.secondaryReasonId,
            "secondary abuse reason",
          );
    const comments =
      request.comments === undefined
        ? undefined
        : actionText(
            request.comments,
            "Abuse-report comments",
            5000,
            true,
          );
    const language =
      request.language === undefined
        ? undefined
        : languageTag(request.language, "abuse-report");
    const reasonList = await this.listVideoAbuseReasons({
      ...request,
      ...(language === undefined ? {} : { language }),
    });
    const reason = reasonList.items.find(
      (item) => item.reasonId === reasonId,
    );
    if (!reason) {
      throw new YouTubeProviderError(
        "bad_request",
        "The selected abuse-report reason is unavailable.",
        400,
        false,
      );
    }
    if (
      secondaryReasonId !== undefined &&
      !reason.secondaryReasons.some(
        (item) => item.reasonId === secondaryReasonId,
      )
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "The selected secondary reason does not belong to the confirmed reason.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/videos/reportAbuse`);
    await this.api(
      request,
      "videos.reportAbuse.owner",
      50,
      url,
      "POST",
      {
        videoId,
        reasonId,
        ...(secondaryReasonId === undefined
          ? {}
          : { secondaryReasonId }),
        ...(comments === undefined ? {} : { comments }),
        ...(language === undefined ? {} : { language }),
      },
    );
    return { reported: true as const, videoId, reasonId };
  }

  async insertAbuseReport(request: CreatorInsertAbuseReportRequest) {
    expectedChannelId(request.expectedChannelId);
    const subjectTypeId = strictIdentifier(
      request.subjectTypeId,
      ABUSE_ENTITY_TYPE_ID,
      "abuse-report subject type",
    );
    const subjectId = strictResourceId(
      request.subjectId,
      "abuse-report subject",
    );
    const abuseTypeIds = [...new Set(request.abuseTypeIds.map((value) =>
      strictIdentifier(
        value,
        ABUSE_ENTITY_TYPE_ID,
        "abuse-report type",
      ),
    ))];
    if (abuseTypeIds.length < 1 || abuseTypeIds.length > 5) {
      throw new YouTubeProviderError(
        "bad_request",
        "Select between one and five abuse-report types.",
        400,
        false,
      );
    }
    const confirmedAbuseTypeIds = [...new Set(
      request.confirmAbuseTypeIds.map((value) =>
        strictIdentifier(
          value,
          ABUSE_ENTITY_TYPE_ID,
          "confirmed abuse-report type",
        ),
      ),
    )];
    if (
      request.confirmSubjectTypeId.trim() !== subjectTypeId ||
      request.confirmSubjectId.trim() !== subjectId ||
      confirmedAbuseTypeIds.length !== abuseTypeIds.length ||
      confirmedAbuseTypeIds.some(
        (value, index) => value !== abuseTypeIds[index],
      )
    ) {
      throw new YouTubeProviderError(
        "bad_request",
        "Confirm the selected abuse-report subject and reasons.",
        400,
        false,
      );
    }
    const description =
      request.description === undefined
        ? undefined
        : actionText(
            request.description,
            "Abuse-report description",
            5000,
            true,
          );
    const relatedEntities = (request.relatedEntities ?? []).map(
      (item) => ({
        entity: {
          typeId: strictIdentifier(
            item.typeId,
            ABUSE_ENTITY_TYPE_ID,
            "related entity type",
          ),
          id: strictResourceId(item.id, "related entity"),
        },
      }),
    );
    if (relatedEntities.length > 10) {
      throw new YouTubeProviderError(
        "bad_request",
        "No more than ten related entities may be reported.",
        400,
        false,
      );
    }
    const url = new URL(`${DATA_API}/abuseReports`);
    url.searchParams.set(
      "part",
      "abuseTypes,subject,description,relatedEntities",
    );
    await this.api(
      request,
      "abuseReports.insert.owner",
      50,
      url,
      "POST",
      {
        subject: { typeId: subjectTypeId, id: subjectId },
        abuseTypes: abuseTypeIds.map((id) => ({ id })),
        ...(description === undefined ? {} : { description }),
        ...(relatedEntities.length === 0 ? {} : { relatedEntities }),
      },
    );
    return {
      submitted: true as const,
      subjectTypeId,
      subjectId,
      abuseTypeIds,
    };
  }
}

export const CREATOR_CAPTION_DOWNLOAD_MAX_BYTES =
  CAPTION_DOWNLOAD_MAX_BYTES;
