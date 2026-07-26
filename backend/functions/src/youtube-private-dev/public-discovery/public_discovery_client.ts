import {
  assertProviderResponse,
  YouTubeProviderError,
} from "../../youtube/errors.js";
import {
  safeYouTubeProviderImageUrl,
  safeYouTubeProviderPlainText,
} from "../../youtube/provider_content.js";
import {
  systemClock,
  type Clock,
  type YouTubeCachePort,
  type YouTubeQuotaPort,
} from "../../youtube/ports.js";
import type {
  HttpTransport,
  YouTubeThumbnail,
} from "../../youtube/types.js";

const DATA_API = "https://www.googleapis.com/youtube/v3";
const ACTIVITY_CACHE_MS = 60 * 1000;
const CHANNEL_SECTION_CACHE_MS = 5 * 60 * 1000;
const ACTIVITY_RESPONSE_BYTES = 512 * 1024;
const CHANNEL_SECTION_RESPONSE_BYTES = 128 * 1024;
const MAX_ACTIVITY_RESULTS = 50;
const MAX_CHANNEL_SECTIONS = 10;
const MAX_ACTIVITY_WINDOW_MS = 90 * 24 * 60 * 60 * 1000;
const MAX_FUTURE_CLOCK_SKEW_MS = 5 * 60 * 1000;

const CHANNEL_ID = /^UC[A-Za-z0-9_-]{22}$/u;
const VIDEO_ID = /^[A-Za-z0-9_-]{11}$/u;
const PLAYLIST_ID = /^[A-Za-z0-9_-]{1,160}$/u;
const RESOURCE_ID = /^[A-Za-z0-9_-]{1,256}$/u;
const PAGE_TOKEN = /^[A-Za-z0-9_-]{1,256}$/u;
const REGION_CODE = /^[A-Z]{2}$/u;
const RFC3339_UTC =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/u;

const ACTIVITY_FIELDS = [
  "nextPageToken,",
  "items(",
  "id,",
  "snippet(publishedAt,channelId,title,description,thumbnails,channelTitle,type,groupId),",
  "contentDetails(upload,like,favorite,playlistItem,subscription)",
  ")",
].join("");
const CHANNEL_SECTION_FIELDS =
  "items(id,snippet(type,channelId,title,position),contentDetails(playlists,channels))";

const ACTIVITY_TYPES = [
  "upload",
  "like",
  "favorite",
  "playlistItem",
  "subscription",
] as const;
const ACTIVITY_TYPE_SET = new Set<string>(ACTIVITY_TYPES);

const CHANNEL_SECTION_TYPES = [
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
] as const;
const CHANNEL_SECTION_TYPE_SET = new Set<string>(CHANNEL_SECTION_TYPES);

/**
 * These methods intentionally stay out of this server-key-only public plane.
 * `playlistImages.list` requires owner OAuth in the official API, while
 * `liveBroadcasts.list` is owned by the isolated concurrent live slice.
 */
export const PUBLIC_DISCOVERY_OMISSIONS = Object.freeze({
  "playlistImages.list": "owner_oauth_required",
  "liveBroadcasts.list": "concurrent_live_slice",
} as const);

export type YouTubePublicActivityType =
  (typeof ACTIVITY_TYPES)[number];

export type YouTubePublicChannelSectionType =
  (typeof CHANNEL_SECTION_TYPES)[number];

export type YouTubePublicActivityTarget =
  | {
      readonly kind: "video";
      readonly videoId: string;
      readonly playlistId?: string;
      readonly playlistItemId?: string;
    }
  | {
      readonly kind: "channel";
      readonly channelId: string;
    };

export interface YouTubePublicChannelActivity {
  readonly activityId: string;
  readonly channelId: string;
  readonly channelTitle: string;
  readonly publishedAt: string;
  readonly type: YouTubePublicActivityType;
  readonly title: string;
  readonly description: string;
  readonly target: YouTubePublicActivityTarget;
  readonly thumbnail?: YouTubeThumbnail;
  readonly groupId?: string;
}

export interface YouTubePublicChannelActivitiesPage {
  readonly source: "youtube";
  /**
   * A channel-scoped public feed. This is never a personalized YouTube Home,
   * watch-history, or recommendation response.
   */
  readonly feedScope: "publicChannel";
  readonly channelId: string;
  readonly regionCode: string;
  readonly items: readonly YouTubePublicChannelActivity[];
  readonly omittedByFilterOrUnsupportedCount: number;
  readonly nextPageToken?: string;
}

export interface YouTubePublicChannelActivitiesQuery {
  readonly channelId: string;
  readonly regionCode?: string;
  readonly maxResults?: number;
  readonly pageToken?: string;
  readonly publishedAfter?: string;
  readonly publishedBefore?: string;
  readonly eventTypes?: readonly YouTubePublicActivityType[];
}

export interface YouTubePublicChannelSection {
  readonly sectionId: string;
  readonly channelId: string;
  readonly type: YouTubePublicChannelSectionType;
  readonly position: number;
  readonly title?: string;
  readonly playlistIds?: readonly string[];
  readonly channelIds?: readonly string[];
}

export interface YouTubePublicChannelSectionsResult {
  readonly source: "youtube";
  readonly channelId: string;
  readonly items: readonly YouTubePublicChannelSection[];
}

export interface YouTubePublicDiscoveryClientOptions {
  readonly transport: HttpTransport;
  readonly quota: YouTubeQuotaPort;
  readonly cache: YouTubeCachePort;
  readonly serverApiKey: string;
  readonly enabled?: boolean | (() => boolean);
  readonly clock?: Clock;
}

interface ApiThumbnail {
  readonly url?: unknown;
  readonly width?: unknown;
  readonly height?: unknown;
}

interface ApiResourceId {
  readonly kind?: unknown;
  readonly videoId?: unknown;
  readonly channelId?: unknown;
}

interface ApiActivity {
  readonly id?: unknown;
  readonly snippet?: {
    readonly publishedAt?: unknown;
    readonly channelId?: unknown;
    readonly title?: unknown;
    readonly description?: unknown;
    readonly thumbnails?: Readonly<Record<string, ApiThumbnail>>;
    readonly channelTitle?: unknown;
    readonly type?: unknown;
    readonly groupId?: unknown;
  };
  readonly contentDetails?: {
    readonly upload?: {
      readonly videoId?: unknown;
    };
    readonly like?: {
      readonly resourceId?: ApiResourceId;
    };
    readonly favorite?: {
      readonly resourceId?: ApiResourceId;
    };
    readonly playlistItem?: {
      readonly resourceId?: ApiResourceId;
      readonly playlistId?: unknown;
      readonly playlistItemId?: unknown;
    };
    readonly subscription?: {
      readonly resourceId?: ApiResourceId;
    };
  };
}

interface ApiChannelSection {
  readonly id?: unknown;
  readonly snippet?: {
    readonly type?: unknown;
    readonly channelId?: unknown;
    readonly title?: unknown;
    readonly position?: unknown;
  };
  readonly contentDetails?: {
    readonly playlists?: unknown;
    readonly channels?: unknown;
  };
}

interface ListEnvelope<T> {
  readonly nextPageToken?: unknown;
  readonly items?: unknown;
}

function badRequest(message: string): never {
  throw new YouTubeProviderError("bad_request", message, 400, false);
}

function providerRejected(message: string): never {
  throw new YouTubeProviderError(
    "provider_rejected",
    message,
    502,
    false,
  );
}

function capabilityDisabled(): never {
  throw new YouTubeProviderError(
    "capability_disabled",
    "YouTube public discovery is disabled.",
    503,
    false,
  );
}

function strictRuntimeIdentifier(
  value: string,
  label: "principal" | "request",
): string {
  const candidate = value.trim();
  if (
    !candidate ||
    candidate.length > 128 ||
    /[\u0000-\u001F\u007F-\u009F]/u.test(candidate)
  ) {
    return badRequest(`A valid ${label} identifier is required.`);
  }
  return candidate;
}

function strictIdentifier(
  value: string,
  pattern: RegExp,
  label: string,
): string {
  const candidate = value.trim();
  if (candidate !== value || !pattern.test(candidate)) {
    return badRequest(`A valid ${label} identifier is required.`);
  }
  return candidate;
}

function providerIdentifier(
  value: unknown,
  pattern: RegExp,
  message: string,
): string {
  if (
    typeof value !== "string" ||
    value !== value.trim() ||
    !pattern.test(value)
  ) {
    return providerRejected(message);
  }
  return value;
}

function pageSize(value: number | undefined): number {
  if (value === undefined) return 10;
  if (
    !Number.isInteger(value) ||
    value < 1 ||
    value > MAX_ACTIVITY_RESULTS
  ) {
    return badRequest(
      `maxResults must be between 1 and ${MAX_ACTIVITY_RESULTS}.`,
    );
  }
  return value;
}

function pageToken(value: string | undefined): string | undefined {
  if (value === undefined) return undefined;
  return strictIdentifier(value, PAGE_TOKEN, "page token");
}

function providerPageToken(value: unknown): string | undefined {
  if (value === undefined) return undefined;
  return providerIdentifier(
    value,
    PAGE_TOKEN,
    "YouTube returned an invalid page token.",
  );
}

function regionCode(value: string | undefined): string {
  const region = value?.trim().toUpperCase() ?? "IN";
  if (!REGION_CODE.test(region)) {
    return badRequest("A valid two-letter region code is required.");
  }
  return region;
}

function parseRequestedDate(value: string, label: string): Date {
  if (!RFC3339_UTC.test(value)) {
    return badRequest(`${label} must be an RFC 3339 UTC timestamp.`);
  }
  const parsed = new Date(value);
  if (!Number.isFinite(parsed.getTime())) {
    return badRequest(`${label} must be a valid timestamp.`);
  }
  return parsed;
}

function activityDateWindow(
  publishedAfter: string | undefined,
  publishedBefore: string | undefined,
  clock: Clock,
):
  | {
      readonly publishedAfter: string;
      readonly publishedBefore: string;
    }
  | undefined {
  if (publishedAfter === undefined && publishedBefore === undefined) {
    return undefined;
  }
  if (publishedAfter === undefined || publishedBefore === undefined) {
    return badRequest(
      "publishedAfter and publishedBefore must be provided together.",
    );
  }
  const after = parseRequestedDate(publishedAfter, "publishedAfter");
  const before = parseRequestedDate(publishedBefore, "publishedBefore");
  const window = before.getTime() - after.getTime();
  if (window <= 0 || window > MAX_ACTIVITY_WINDOW_MS) {
    return badRequest(
      "The activity time window must be greater than zero and no longer than 90 days.",
    );
  }
  if (
    before.getTime() >
    clock.now().getTime() + MAX_FUTURE_CLOCK_SKEW_MS
  ) {
    return badRequest("publishedBefore cannot be in the future.");
  }
  return {
    publishedAfter: after.toISOString(),
    publishedBefore: before.toISOString(),
  };
}

function eventTypes(
  values: readonly YouTubePublicActivityType[] | undefined,
): readonly YouTubePublicActivityType[] {
  if (values === undefined) return ACTIVITY_TYPES;
  if (values.length === 0 || values.length > ACTIVITY_TYPES.length) {
    return badRequest("At least one supported activity type is required.");
  }
  const unique = new Set<YouTubePublicActivityType>();
  for (const value of values) {
    if (!ACTIVITY_TYPE_SET.has(value) || unique.has(value)) {
      return badRequest(
        "Activity types must be supported and must not repeat.",
      );
    }
    unique.add(value);
  }
  return [...unique].sort();
}

function parseJsonObject<T>(body: string): T {
  try {
    const parsed = JSON.parse(body) as unknown;
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return providerRejected("YouTube returned an unreadable response.");
    }
    return parsed as T;
  } catch (error) {
    if (error instanceof YouTubeProviderError) throw error;
    return providerRejected("YouTube returned an unreadable response.");
  }
}

function providerArray<T>(
  value: unknown,
  message: string,
  maximum: number,
): readonly T[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.length > maximum) {
    return providerRejected(message);
  }
  return value as readonly T[];
}

function providerText(
  value: unknown,
  message: string,
  maximum: number,
  allowEmpty = false,
): string {
  if (typeof value !== "string" || value.length > maximum) {
    return providerRejected(message);
  }
  if (allowEmpty && value === "") return "";
  return safeYouTubeProviderPlainText(value, message);
}

function providerOptionalText(
  value: unknown,
  message: string,
  maximum: number,
): string | undefined {
  if (value === undefined) return undefined;
  return providerText(value, message, maximum);
}

function providerNonNegativeInteger(
  value: unknown,
  message: string,
  maximum: number,
): number {
  if (
    typeof value !== "number" ||
    !Number.isInteger(value) ||
    value < 0 ||
    value > maximum
  ) {
    return providerRejected(message);
  }
  return value;
}

function providerDate(value: unknown, message: string): string {
  if (typeof value !== "string" || !RFC3339_UTC.test(value)) {
    return providerRejected(message);
  }
  const parsed = new Date(value);
  if (!Number.isFinite(parsed.getTime())) {
    return providerRejected(message);
  }
  return parsed.toISOString();
}

function thumbnail(
  thumbnails: Readonly<Record<string, ApiThumbnail>> | undefined,
): YouTubeThumbnail | undefined {
  if (thumbnails === undefined) return undefined;
  if (
    !thumbnails ||
    typeof thumbnails !== "object" ||
    Array.isArray(thumbnails)
  ) {
    return providerRejected("YouTube returned invalid activity artwork.");
  }
  const selected =
    thumbnails.maxres ??
    thumbnails.standard ??
    thumbnails.high ??
    thumbnails.medium ??
    thumbnails.default;
  if (selected === undefined) return undefined;
  const url = safeYouTubeProviderImageUrl(
    selected.url,
    "YouTube returned invalid activity artwork.",
  );
  const width =
    selected.width === undefined
      ? undefined
      : providerNonNegativeInteger(
          selected.width,
          "YouTube returned invalid activity artwork.",
          10_000,
        );
  const height =
    selected.height === undefined
      ? undefined
      : providerNonNegativeInteger(
          selected.height,
          "YouTube returned invalid activity artwork.",
          10_000,
        );
  return {
    url,
    ...(width === undefined ? {} : { width }),
    ...(height === undefined ? {} : { height }),
  };
}

function activityType(value: unknown): YouTubePublicActivityType | undefined {
  if (typeof value !== "string") {
    return providerRejected("YouTube returned an invalid activity type.");
  }
  if (!ACTIVITY_TYPE_SET.has(value)) return undefined;
  return value as YouTubePublicActivityType;
}

function videoResourceTarget(
  resource: ApiResourceId | undefined,
  message: string,
): YouTubePublicActivityTarget {
  if (resource?.kind !== "youtube#video") {
    return providerRejected(message);
  }
  return {
    kind: "video",
    videoId: providerIdentifier(resource.videoId, VIDEO_ID, message),
  };
}

function activityTarget(
  type: YouTubePublicActivityType,
  details: ApiActivity["contentDetails"],
): YouTubePublicActivityTarget {
  switch (type) {
    case "upload":
      return {
        kind: "video",
        videoId: providerIdentifier(
          details?.upload?.videoId,
          VIDEO_ID,
          "YouTube returned invalid upload activity details.",
        ),
      };
    case "like":
      return videoResourceTarget(
        details?.like?.resourceId,
        "YouTube returned invalid like activity details.",
      );
    case "favorite":
      return videoResourceTarget(
        details?.favorite?.resourceId,
        "YouTube returned invalid favorite activity details.",
      );
    case "playlistItem": {
      const target = videoResourceTarget(
        details?.playlistItem?.resourceId,
        "YouTube returned invalid playlist activity details.",
      );
      if (target.kind !== "video") {
        return providerRejected(
          "YouTube returned invalid playlist activity details.",
        );
      }
      return {
        ...target,
        playlistId: providerIdentifier(
          details?.playlistItem?.playlistId,
          PLAYLIST_ID,
          "YouTube returned invalid playlist activity details.",
        ),
        playlistItemId: providerIdentifier(
          details?.playlistItem?.playlistItemId,
          RESOURCE_ID,
          "YouTube returned invalid playlist activity details.",
        ),
      };
    }
    case "subscription": {
      const resource = details?.subscription?.resourceId;
      if (resource?.kind !== "youtube#channel") {
        return providerRejected(
          "YouTube returned invalid subscription activity details.",
        );
      }
      return {
        kind: "channel",
        channelId: providerIdentifier(
          resource.channelId,
          CHANNEL_ID,
          "YouTube returned invalid subscription activity details.",
        ),
      };
    }
  }
}

function mapActivity(
  item: ApiActivity,
  expectedChannelId: string,
  allowedTypes: ReadonlySet<YouTubePublicActivityType>,
): YouTubePublicChannelActivity | undefined {
  const snippet = item.snippet;
  if (!snippet || typeof snippet !== "object") {
    return providerRejected("YouTube returned incomplete activity metadata.");
  }
  const type = activityType(snippet.type);
  if (type === undefined || !allowedTypes.has(type)) return undefined;
  const channelId = providerIdentifier(
    snippet.channelId,
    CHANNEL_ID,
    "YouTube returned an invalid activity channel.",
  );
  if (channelId !== expectedChannelId) {
    return providerRejected("YouTube returned an unexpected activity channel.");
  }
  const groupId = providerOptionalText(
    snippet.groupId,
    "YouTube returned an invalid activity group.",
    256,
  );
  const artwork = thumbnail(snippet.thumbnails);
  return {
    activityId: providerIdentifier(
      item.id,
      RESOURCE_ID,
      "YouTube returned an invalid activity identifier.",
    ),
    channelId,
    channelTitle: providerText(
      snippet.channelTitle,
      "YouTube returned an invalid activity channel title.",
      200,
    ),
    publishedAt: providerDate(
      snippet.publishedAt,
      "YouTube returned an invalid activity timestamp.",
    ),
    type,
    title: providerText(
      snippet.title,
      "YouTube returned an invalid activity title.",
      500,
    ),
    description: providerText(
      snippet.description,
      "YouTube returned an invalid activity description.",
      20_000,
      true,
    ),
    target: activityTarget(type, item.contentDetails),
    ...(artwork === undefined ? {} : { thumbnail: artwork }),
    ...(groupId === undefined ? {} : { groupId }),
  };
}

function channelSectionType(
  value: unknown,
): YouTubePublicChannelSectionType {
  if (typeof value !== "string" || !CHANNEL_SECTION_TYPE_SET.has(value)) {
    return providerRejected(
      "YouTube returned an invalid channel section type.",
    );
  }
  return value as YouTubePublicChannelSectionType;
}

function providerIdentifierList(
  value: unknown,
  pattern: RegExp,
  message: string,
): readonly string[] {
  const values = providerArray<unknown>(value, message, 10);
  const ids = values.map((candidate) =>
    providerIdentifier(candidate, pattern, message),
  );
  if (new Set(ids).size !== ids.length) {
    return providerRejected(message);
  }
  return ids;
}

function mapChannelSection(
  item: ApiChannelSection,
  expectedChannelId: string,
): YouTubePublicChannelSection {
  const snippet = item.snippet;
  if (!snippet || typeof snippet !== "object") {
    return providerRejected(
      "YouTube returned incomplete channel section metadata.",
    );
  }
  const channelId = providerIdentifier(
    snippet.channelId,
    CHANNEL_ID,
    "YouTube returned an invalid channel section channel.",
  );
  if (channelId !== expectedChannelId) {
    return providerRejected(
      "YouTube returned an unexpected channel section channel.",
    );
  }
  const type = channelSectionType(snippet.type);
  const title = providerOptionalText(
    snippet.title,
    "YouTube returned an invalid channel section title.",
    100,
  );
  const playlistIds = providerIdentifierList(
    item.contentDetails?.playlists,
    PLAYLIST_ID,
    "YouTube returned invalid channel section playlists.",
  );
  const channelIds = providerIdentifierList(
    item.contentDetails?.channels,
    CHANNEL_ID,
    "YouTube returned invalid channel section channels.",
  );

  if (type === "singlePlaylist") {
    if (playlistIds.length !== 1 || channelIds.length !== 0) {
      return providerRejected(
        "YouTube returned inconsistent single-playlist section details.",
      );
    }
  } else if (type === "multiplePlaylists") {
    if (
      playlistIds.length === 0 ||
      channelIds.length !== 0 ||
      title === undefined
    ) {
      return providerRejected(
        "YouTube returned inconsistent multi-playlist section details.",
      );
    }
  } else if (type === "multipleChannels") {
    if (
      channelIds.length === 0 ||
      channelIds.includes(expectedChannelId) ||
      playlistIds.length !== 0 ||
      title === undefined
    ) {
      return providerRejected(
        "YouTube returned inconsistent multi-channel section details.",
      );
    }
  } else if (playlistIds.length !== 0 || channelIds.length !== 0) {
    return providerRejected(
      "YouTube returned unexpected channel section details.",
    );
  }

  return {
    sectionId: providerIdentifier(
      item.id,
      RESOURCE_ID,
      "YouTube returned an invalid channel section identifier.",
    ),
    channelId,
    type,
    position: providerNonNegativeInteger(
      snippet.position,
      "YouTube returned an invalid channel section position.",
      MAX_CHANNEL_SECTIONS - 1,
    ),
    ...(title === undefined ? {} : { title }),
    ...(playlistIds.length === 0 ? {} : { playlistIds }),
    ...(channelIds.length === 0 ? {} : { channelIds }),
  };
}

export class YouTubePublicDiscoveryClient {
  private readonly clock: Clock;

  constructor(
    private readonly options: YouTubePublicDiscoveryClientOptions,
  ) {
    const apiKey = options.serverApiKey.trim();
    if (
      !apiKey ||
      apiKey !== options.serverApiKey ||
      apiKey.length > 256 ||
      /[\u0000-\u001F\u007F-\u009F]/u.test(apiKey)
    ) {
      throw new Error("A restricted YouTube server API key is required.");
    }
    this.clock = options.clock ?? systemClock;
  }

  private assertEnabled(): void {
    const enabled =
      typeof this.options.enabled === "function"
        ? this.options.enabled()
        : this.options.enabled;
    if (enabled !== true) capabilityDisabled();
  }

  private async get(url: URL, maximumBytes: number): Promise<string> {
    if (
      url.origin !== "https://www.googleapis.com" ||
      !url.pathname.startsWith("/youtube/v3/")
    ) {
      throw new Error("Unexpected YouTube provider endpoint.");
    }
    const response = await this.options.transport.send({
      url: url.toString(),
      method: "GET",
      headers: {
        "x-goog-api-key": this.options.serverApiKey,
      },
      maxResponseBytes: maximumBytes,
    });
    assertProviderResponse(response.status, response.body);
    if (Buffer.byteLength(response.body, "utf8") > maximumBytes) {
      return providerRejected("YouTube returned an oversized response.");
    }
    return response.body;
  }

  async listChannelActivities(
    principalInput: string,
    requestIdInput: string,
    query: YouTubePublicChannelActivitiesQuery,
  ): Promise<YouTubePublicChannelActivitiesPage> {
    this.assertEnabled();
    const principal = strictRuntimeIdentifier(principalInput, "principal");
    const requestId = strictRuntimeIdentifier(requestIdInput, "request");
    const channelId = strictIdentifier(
      query.channelId,
      CHANNEL_ID,
      "channel",
    );
    const region = regionCode(query.regionCode);
    const maximum = pageSize(query.maxResults);
    const token = pageToken(query.pageToken);
    const dates = activityDateWindow(
      query.publishedAfter,
      query.publishedBefore,
      this.clock,
    );
    const types = eventTypes(query.eventTypes);
    const allowedTypes = new Set(types);
    const cacheKey = [
      "youtube-public-discovery",
      "activities",
      channelId,
      region,
      maximum,
      token ?? "first",
      dates?.publishedAfter ?? "any-after",
      dates?.publishedBefore ?? "any-before",
      types.join(","),
    ].join(":");

    return this.options.cache.getOrLoad(
      cacheKey,
      ACTIVITY_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "activities.list.publicChannel",
          requestId,
        });
        const url = new URL(`${DATA_API}/activities`);
        url.searchParams.set("part", "snippet,contentDetails");
        url.searchParams.set("channelId", channelId);
        url.searchParams.set("regionCode", region);
        url.searchParams.set("maxResults", String(maximum));
        url.searchParams.set("fields", ACTIVITY_FIELDS);
        if (token !== undefined) url.searchParams.set("pageToken", token);
        if (dates !== undefined) {
          url.searchParams.set("publishedAfter", dates.publishedAfter);
          url.searchParams.set("publishedBefore", dates.publishedBefore);
        }
        const envelope = parseJsonObject<ListEnvelope<ApiActivity>>(
          await this.get(url, ACTIVITY_RESPONSE_BYTES),
        );
        const providerItems = providerArray<ApiActivity>(
          envelope.items,
          "YouTube returned invalid activity items.",
          maximum,
        );
        const items: YouTubePublicChannelActivity[] = [];
        let omittedByFilterOrUnsupportedCount = 0;
        for (const item of providerItems) {
          const mapped = mapActivity(item, channelId, allowedTypes);
          if (mapped === undefined) {
            omittedByFilterOrUnsupportedCount += 1;
          } else {
            items.push(mapped);
          }
        }
        const nextPageToken = providerPageToken(envelope.nextPageToken);
        return {
          source: "youtube" as const,
          feedScope: "publicChannel" as const,
          channelId,
          regionCode: region,
          items,
          omittedByFilterOrUnsupportedCount,
          ...(nextPageToken === undefined ? {} : { nextPageToken }),
        };
      },
    );
  }

  async listChannelSections(
    principalInput: string,
    requestIdInput: string,
    channelIdInput: string,
  ): Promise<YouTubePublicChannelSectionsResult> {
    this.assertEnabled();
    const principal = strictRuntimeIdentifier(principalInput, "principal");
    const requestId = strictRuntimeIdentifier(requestIdInput, "request");
    const channelId = strictIdentifier(
      channelIdInput,
      CHANNEL_ID,
      "channel",
    );
    const cacheKey = [
      "youtube-public-discovery",
      "channel-sections",
      channelId,
    ].join(":");
    return this.options.cache.getOrLoad(
      cacheKey,
      CHANNEL_SECTION_CACHE_MS,
      async () => {
        await this.options.quota.reserve({
          principal,
          bucket: "general",
          amount: 1,
          operation: "channelSections.list.publicChannel",
          requestId,
        });
        const url = new URL(`${DATA_API}/channelSections`);
        url.searchParams.set("part", "snippet,contentDetails");
        url.searchParams.set("channelId", channelId);
        url.searchParams.set("fields", CHANNEL_SECTION_FIELDS);
        const envelope = parseJsonObject<ListEnvelope<ApiChannelSection>>(
          await this.get(url, CHANNEL_SECTION_RESPONSE_BYTES),
        );
        const providerItems = providerArray<ApiChannelSection>(
          envelope.items,
          "YouTube returned invalid channel section items.",
          MAX_CHANNEL_SECTIONS,
        );
        const items = providerItems.map((item) =>
          mapChannelSection(item, channelId),
        );
        if (
          new Set(items.map((item) => item.sectionId)).size !== items.length ||
          new Set(items.map((item) => item.position)).size !== items.length
        ) {
          return providerRejected(
            "YouTube returned duplicate channel sections.",
          );
        }
        return {
          source: "youtube" as const,
          channelId,
          items: items.slice().sort((left, right) => {
            if (left.position !== right.position) {
              return left.position - right.position;
            }
            return left.sectionId.localeCompare(right.sectionId);
          }),
        };
      },
    );
  }
}
