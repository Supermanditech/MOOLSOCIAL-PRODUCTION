export type YouTubeQuotaBucket =
  | "search"
  | "upload"
  | "batchStats"
  | "analytics"
  | "general";

export type YouTubeCapability =
  | "publicData"
  | "ownerConnect"
  | "ownerActions"
  | "creatorAssets"
  | "live"
  | "privateUpload"
  | "ownerAnalytics";

export interface YouTubeRuntimeCapabilities {
  readonly environment: "local" | "dev";
  readonly publicData: boolean;
  readonly ownerConnect: boolean;
  /**
   * Disabled when absent so older fixtures and any stale runtime configuration
   * fail closed until the dedicated private-Dev proof profile is selected.
   */
  readonly ownerActions?: boolean;
  /**
   * Channel-owner asset administration remains a separate, supervised proof
   * surface. Missing values intentionally fail closed for stale fixtures.
   */
  readonly creatorAssets?: boolean;
  /**
   * Live broadcast and live-chat administration is isolated behind its own
   * supervised private-Dev proof. Missing values fail closed.
   */
  readonly live?: boolean;
  readonly privateUpload: boolean;
  readonly ownerAnalytics: boolean;
  /**
   * These report fields describe the two isolated adapters registered under
   * the single ownerAnalytics proof profile. Missing values fail closed for
   * stale callers and fixtures.
   */
  readonly analyticsV2?: boolean;
  readonly reportingV1?: boolean;
  readonly publicOrUnlistedUpload: false;
}

export interface YouTubeThumbnail {
  readonly url: string;
  readonly width?: number;
  readonly height?: number;
}

export type YouTubeBroadcastState = "none" | "live" | "upcoming";

export type YouTubePublicVideoUnavailableReason =
  | "not_public"
  | "not_embeddable"
  | "processing"
  | "removed_or_rejected"
  | "region_restricted"
  | "age_restricted"
  | "children_directed"
  | "metadata_invalid"
  | "unavailable";

export interface YouTubePublicVideoAvailability {
  readonly state: "available";
  readonly regionCode: string;
  readonly broadcastState: YouTubeBroadcastState;
  readonly syndication:
    | "search_filter_confirmed"
    | "embeddable_status_only";
}

export interface YouTubeLiveStreamingDetails {
  readonly actualStartTime?: string;
  readonly actualEndTime?: string;
  readonly scheduledStartTime?: string;
  readonly scheduledEndTime?: string;
  readonly concurrentViewers?: string;
}

export interface YouTubeLocalizedMetadata {
  readonly title: string;
  readonly description: string;
}

export interface YouTubeRegionRestriction {
  readonly allowed?: readonly string[];
  readonly blocked?: readonly string[];
}

export interface YouTubeFilteredVideoSummary {
  readonly total: number;
  readonly reasons: Readonly<
    Partial<Record<YouTubePublicVideoUnavailableReason, number>>
  >;
}

export interface YouTubeVideoSummary {
  readonly videoId: string;
  readonly title: string;
  readonly channelId: string;
  readonly channelTitle: string;
  readonly publishedAt: string;
  readonly description: string;
  readonly thumbnail: YouTubeThumbnail;
  readonly categoryId?: string;
  readonly tags?: readonly string[];
  readonly defaultLanguage?: string;
  readonly defaultAudioLanguage?: string;
  readonly localized?: YouTubeLocalizedMetadata;
  readonly duration?: string;
  readonly captionAvailable?: boolean;
  readonly definition?: "hd" | "sd";
  readonly licensedContent?: boolean;
  readonly projection?: "rectangular" | "360";
  readonly regionRestriction?: YouTubeRegionRestriction;
  readonly viewCount?: string;
  readonly likeCount?: string;
  readonly commentCount?: string;
  readonly embeddable?: boolean;
  readonly privacyStatus?: string;
  readonly uploadStatus?: string;
  readonly availability?: YouTubePublicVideoAvailability;
  readonly liveStreamingDetails?: YouTubeLiveStreamingDetails;
}

export interface YouTubePage<T> {
  readonly items: readonly T[];
  readonly nextPageToken?: string;
  readonly filtered?: YouTubeFilteredVideoSummary;
}

export interface YouTubeChannelIdentity {
  readonly channelId: string;
  readonly title: string;
  readonly uploadsPlaylistId?: string;
  readonly thumbnail?: YouTubeThumbnail;
}

export interface YouTubePublicChannelStatistics {
  readonly viewCount?: string;
  readonly subscriberCount?: string;
  readonly hiddenSubscriberCount: boolean;
  readonly videoCount?: string;
}

export interface YouTubePublicChannelDetails
  extends YouTubeChannelIdentity {
  readonly description: string;
  readonly publishedAt: string;
  readonly customUrl?: string;
  readonly country?: string;
  readonly statistics: YouTubePublicChannelStatistics;
  readonly topicCategories: readonly string[];
}

export interface YouTubePublicPlaylistDetails {
  readonly playlistId: string;
  readonly title: string;
  readonly description: string;
  readonly publishedAt: string;
  readonly channelId: string;
  readonly channelTitle: string;
  readonly itemCount: number;
  readonly privacyStatus: "public";
  readonly defaultLanguage?: string;
  readonly localized?: YouTubeLocalizedMetadata;
  readonly thumbnail?: YouTubeThumbnail;
}

export interface YouTubePublicRegion {
  readonly regionCode: string;
  readonly name: string;
}

export interface YouTubePublicLanguage {
  readonly languageCode: string;
  readonly name: string;
}

export interface YouTubePublicVideoCategory {
  readonly categoryId: string;
  readonly title: string;
  readonly assignable: boolean;
  readonly channelId?: string;
}

export interface YouTubeVideoStatisticsSnapshot {
  readonly videoId: string;
  readonly publishTime?: string;
  readonly viewCount?: string;
  readonly likeCount?: string;
  readonly commentCount?: string;
  readonly duration?: string;
  readonly durationMillis?: string;
}

export interface YouTubeBatchStatisticsSummary {
  readonly requestedVideoCount: string;
  readonly succeededVideoCount: string;
  readonly failedVideoCount: string;
  readonly failedVideoIds: readonly string[];
}

export interface YouTubeBatchStatisticsResult {
  readonly items: readonly YouTubeVideoStatisticsSnapshot[];
  readonly summary: YouTubeBatchStatisticsSummary;
}

export interface YouTubePublicCommentAuthor {
  readonly displayName: string;
  readonly profileImageUrl?: string;
  readonly channelId?: string;
  readonly channelUrl?: string;
}

export interface YouTubePublicComment {
  readonly commentId: string;
  /**
   * Complete provider-returned plain text. The backend never truncates this
   * field; any future presentation truncation must retain an immediate way to
   * reveal the full value.
   */
  readonly textDisplay: string;
  /**
   * A rendering contract, not provider HTML. Native clients must render
   * `textDisplay` as literal text and must never pass it to an HTML renderer.
   */
  readonly textFormat: "plainText";
  readonly author: YouTubePublicCommentAuthor;
  readonly associatedChannelId: string;
  readonly likeCount: number;
  readonly publishedAt: string;
  readonly updatedAt: string;
  readonly parentId?: string;
}

export interface YouTubePublicCommentThread {
  readonly threadId: string;
  readonly videoId: string;
  readonly channelId: string;
  readonly topLevelComment: YouTubePublicComment;
  readonly replies: readonly YouTubePublicComment[];
  readonly totalReplyCount: number;
  readonly includedReplyCount: number;
  readonly repliesComplete: boolean;
  readonly isPublic: boolean;
}

export interface YouTubePublicCommentAttribution {
  readonly source: "youtube";
  readonly videoId: string;
  readonly videoTitle: string;
  readonly channelId: string;
  readonly channelTitle: string;
}

export interface YouTubePublicCommentThreadsPage {
  readonly attribution: YouTubePublicCommentAttribution;
  readonly items: readonly YouTubePublicCommentThread[];
  readonly nextPageToken?: string;
}

export interface YouTubePublicCommentReplyAttribution
  extends YouTubePublicCommentAttribution {
  readonly threadId: string;
  readonly parentCommentId: string;
}

export interface YouTubePublicCommentRepliesPage {
  readonly attribution: YouTubePublicCommentReplyAttribution;
  readonly items: readonly YouTubePublicComment[];
  readonly nextPageToken?: string;
}

export interface YouTubeUploadMetadata {
  readonly title: string;
  readonly description: string;
  readonly categoryId: string;
  readonly madeForKids: boolean;
  readonly containsSyntheticMedia: boolean;
  readonly containsPaidPromotion: boolean;
  readonly notifySubscribers: boolean;
}

export interface YouTubeResumableUploadSession {
  readonly sessionUrl: string;
  readonly expiresAt: string;
  readonly privacyStatus: "private";
}

export interface YouTubeAnalyticsRow {
  readonly dimensions: Record<string, string>;
  readonly metrics: Record<string, number>;
}

export type YouTubeOwnerAnalyticsPreset =
  | "overview"
  | "topVideos"
  | "countries"
  | "trafficSources"
  | "devicesOs"
  | "videoRetention";

export interface YouTubeOwnerAnalyticsResult {
  readonly preset: YouTubeOwnerAnalyticsPreset;
  readonly startDate: string;
  readonly endDate: string;
  readonly requestedRange: {
    readonly startDate: string;
    readonly endDate: string;
  };
  readonly videoId?: string;
  readonly rows: readonly YouTubeAnalyticsRow[];
  readonly continuationStartIndex?: number;
  readonly empty: boolean;
  readonly providerMayExcludeRecentIncompleteDays: true;
}

export interface YouTubeDisconnectResult {
  readonly disconnected: true;
  readonly providerRevocationConfirmed: boolean;
}

export type YouTubeOwnerSubscriptionOrder =
  | "alphabetical"
  | "relevance"
  | "unread";

export interface YouTubeOwnerAttribution {
  readonly source: "youtube";
  readonly channelId: string;
  readonly channelTitle: string;
}

export interface YouTubeOwnerUnavailableVideo {
  readonly state: "unavailable";
  readonly playlistItemId: string;
  readonly videoId?: string;
  readonly playlistPublishedAt?: string;
  readonly position?: number;
}

export interface YouTubeOwnerAvailableVideo {
  readonly state: "available";
  readonly playlistItemId: string;
  readonly playlistPublishedAt?: string;
  readonly position?: number;
  readonly video: YouTubeVideoSummary;
}

export type YouTubeOwnerVideo =
  | YouTubeOwnerAvailableVideo
  | YouTubeOwnerUnavailableVideo;

export interface YouTubeOwnerVideosPage {
  readonly attribution: YouTubeOwnerAttribution;
  readonly items: readonly YouTubeOwnerVideo[];
  readonly nextPageToken?: string;
}

export interface YouTubeOwnerSubscription {
  readonly subscriptionId: string;
  readonly channelId: string;
  readonly channelTitle: string;
  readonly description: string;
  readonly publishedAt: string;
  readonly thumbnail?: YouTubeThumbnail;
}

export interface YouTubeOwnerSubscriptionsPage {
  readonly attribution: YouTubeOwnerAttribution;
  readonly items: readonly YouTubeOwnerSubscription[];
  readonly nextPageToken?: string;
}

export interface YouTubeOwnerPlaylist {
  readonly playlistId: string;
  readonly title: string;
  readonly description: string;
  readonly publishedAt: string;
  readonly channelId: string;
  readonly channelTitle: string;
  readonly itemCount: number;
  readonly privacyStatus: "private" | "public" | "unlisted";
  readonly thumbnail?: YouTubeThumbnail;
}

export interface YouTubeOwnerPlaylistsPage {
  readonly attribution: YouTubeOwnerAttribution;
  readonly items: readonly YouTubeOwnerPlaylist[];
  readonly nextPageToken?: string;
}

export interface YouTubeProviderConnectionRecord {
  readonly connectionKey: string;
  readonly userId: string;
  readonly channelId: string;
  readonly channelTitle: string;
  readonly grantedScopes: readonly string[];
  readonly connectedAt: string;
  readonly lastVerifiedAt: string;
  readonly status: "ACTIVE" | "REVOKED" | "DELETION_PENDING" | "DELETED";
}

export interface YouTubePublicationJobRecord {
  readonly jobKey: string;
  readonly userId: string;
  readonly connectionKey: string;
  readonly idempotencyKey: string;
  readonly requestFingerprint: string;
  readonly title: string;
  readonly privacyStatus: "private";
  readonly contentLength: number;
  readonly encryptedSessionUrl: string;
  readonly sessionExpiresAt?: string;
  readonly state:
    | "SESSION_CREATING"
    | "SESSION_READY"
    | "UPLOADING"
    | "PROCESSING"
    | "COMPLETE"
    | "FAILED"
    | "CANCELLED";
  readonly createdAt: string;
  readonly updatedAt: string;
  readonly videoId?: string;
  readonly failureCode?: string;
}

export interface YouTubeTokenResponse {
  readonly access_token: string;
  readonly expires_in: number;
  readonly scope?: string;
  readonly token_type: string;
  readonly refresh_token?: string;
}

export interface HttpTransportRequest {
  readonly url: string;
  readonly method?: "GET" | "POST" | "PUT" | "DELETE";
  readonly headers?: Readonly<Record<string, string>>;
  readonly body?: string;
  readonly signal?: AbortSignal;
  /**
   * Binary provider responses are returned as base64 only after a successful
   * status. Provider error bodies remain text so the normal error mapper can
   * classify them without ever exposing the provider response to callers.
   */
  readonly responseEncoding?: "text" | "base64";
  /**
   * A hard byte ceiling for bounded relays such as owner-only caption
   * downloads. The transport cancels the provider stream before crossing it.
   */
  readonly maxResponseBytes?: number;
}

export interface HttpTransportResponse {
  readonly status: number;
  readonly headers: Readonly<Record<string, string>>;
  readonly body: string;
}

export interface HttpTransport {
  send(request: HttpTransportRequest): Promise<HttpTransportResponse>;
}
