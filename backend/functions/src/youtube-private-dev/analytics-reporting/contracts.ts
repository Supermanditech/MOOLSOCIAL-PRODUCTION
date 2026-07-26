import type { HttpTransport } from "../../youtube/types.js";
import type { YouTubeQuotaPort } from "../../youtube/ports.js";

export const YOUTUBE_ANALYTICS_READ_SCOPE =
  "https://www.googleapis.com/auth/yt-analytics.readonly";
export const YOUTUBE_ANALYTICS_MONETARY_READ_SCOPE =
  "https://www.googleapis.com/auth/yt-analytics-monetary.readonly";

export type AnalyticsReportingErrorCode =
  | "authentication_required"
  | "app_check_required"
  | "replay_detected"
  | "scope_required"
  | "capability_disabled"
  | "bad_request"
  | "idempotency_conflict"
  | "eligibility_required"
  | "status_conflict"
  | "not_found"
  | "provider_rejected";

/**
 * Typed errors that the future registration layer must map deliberately.
 *
 * These adapters remain unregistered, so adding these codes does not mutate
 * the existing provider HTTP contract.
 */
export class YouTubeAnalyticsReportingError extends Error {
  constructor(
    readonly code: AnalyticsReportingErrorCode,
    message: string,
    readonly httpStatus: number,
    readonly retryable = false,
    readonly providerReason?: string,
  ) {
    super(message);
    this.name = "YouTubeAnalyticsReportingError";
  }
}

export interface VerifiedOwnerInvocation {
  readonly principal: string;
  readonly requestId: string;
  readonly accessToken: string;
  readonly auth: {
    readonly verified: boolean;
    readonly userId: string;
  };
  readonly appCheck: {
    readonly verified: boolean;
    readonly replayProtected: boolean;
    readonly replayId: string;
  };
  readonly owner: {
    readonly userId: string;
    readonly channelId: string;
    readonly status: "ACTIVE" | "REVOKED" | "DELETION_PENDING" | "DELETED";
    readonly grantedScopes: readonly string[];
  };
}

export interface ReplayProtectionPort {
  /**
   * Atomically consumes a previously unconsumed replay identifier.
   */
  consume(key: string): Promise<boolean>;
}

export type IdempotencyReservation =
  | { readonly state: "new" }
  | { readonly state: "in_progress" }
  | { readonly state: "conflict" }
  | { readonly state: "completed"; readonly result: unknown };

export interface IdempotencyPort {
  reserve(
    namespace: string,
    key: string,
    fingerprint: string,
  ): Promise<IdempotencyReservation>;
  complete(
    namespace: string,
    key: string,
    fingerprint: string,
    result: unknown,
  ): Promise<void>;
  release(
    namespace: string,
    key: string,
    fingerprint: string,
  ): Promise<void>;
}

export interface AnalyticsReportingClientOptions {
  readonly transport: HttpTransport;
  readonly quota: YouTubeQuotaPort;
  readonly replayProtection: ReplayProtectionPort;
  readonly idempotency: IdempotencyPort;
  /**
   * Deliberately absent/false by default. A future registration layer must
   * bind this to a founder-authorized, time-limited private-Dev proof gate.
   */
  readonly enabled?: boolean;
  /**
   * Monetary analytics remain a separate consent and product decision.
   */
  readonly monetaryMetricsEnabled?: boolean;
  readonly now?: () => Date;
}

export type AnalyticsMetric =
  | "views"
  | "engagedViews"
  | "estimatedMinutesWatched"
  | "averageViewDuration"
  | "averageViewPercentage"
  | "likes"
  | "comments"
  | "shares"
  | "subscribersGained"
  | "subscribersLost"
  | "playlistStarts"
  | "viewsPerPlaylistStart"
  | "averageTimeInPlaylist";

export type AnalyticsDimension =
  | "day"
  | "video"
  | "country"
  | "insightTrafficSourceType"
  | "deviceType"
  | "operatingSystem"
  | "subscribedStatus"
  | "playlist";

export interface AnalyticsSort {
  readonly field: AnalyticsMetric | AnalyticsDimension;
  readonly direction: "ascending" | "descending";
}

export interface AnalyticsReportQuery {
  readonly startDate: string;
  readonly endDate: string;
  readonly metrics: readonly AnalyticsMetric[];
  readonly dimensions?: readonly AnalyticsDimension[];
  readonly videoId?: string;
  readonly sort?: AnalyticsSort;
  readonly maxResults?: number;
  readonly startIndex?: number;
}

export interface AnalyticsResultRow {
  readonly dimensions: Readonly<Record<string, string>>;
  readonly metrics: Readonly<Record<string, number>>;
}

export interface AnalyticsReportResult {
  readonly channelId: string;
  readonly startDate: string;
  readonly endDate: string;
  readonly rows: readonly AnalyticsResultRow[];
  readonly continuationStartIndex?: number;
  readonly empty: boolean;
}

export type AnalyticsGroupItemType =
  | "youtube#channel"
  | "youtube#playlist"
  | "youtube#video";

export interface AnalyticsGroup {
  readonly groupId: string;
  readonly title: string;
  readonly publishedAt: string;
  readonly itemCount: number;
  readonly itemType: AnalyticsGroupItemType;
}

export interface AnalyticsGroupItem {
  readonly groupItemId: string;
  readonly groupId: string;
  readonly resourceType: AnalyticsGroupItemType;
  readonly resourceId: string;
}

export interface AnalyticsGroupsPage {
  readonly items: readonly AnalyticsGroup[];
  readonly nextPageToken?: string;
}

export interface AnalyticsGroupItemsResult {
  readonly groupId: string;
  readonly items: readonly AnalyticsGroupItem[];
}

export interface ReportingReportType {
  readonly reportTypeId: string;
  readonly name: string;
  readonly systemManaged: boolean;
  readonly deprecateTime?: string;
  readonly availability: "available" | "system-managed" | "deprecated";
}

export interface ReportingJob {
  readonly jobId: string;
  readonly reportTypeId: string;
  readonly name: string;
  readonly systemManaged: boolean;
  readonly createTime: string;
  readonly expireTime?: string;
  readonly status: "active" | "expired" | "system-managed";
}

export interface ReportingReport {
  readonly reportId: string;
  readonly jobId: string;
  readonly createTime: string;
  readonly startTime: string;
  readonly endTime: string;
  readonly jobExpireTime?: string;
  /**
   * The validated provider media resource name, never an arbitrary URL.
   */
  readonly mediaResourceName: string;
}

export interface ReportingPage<T> {
  readonly items: readonly T[];
  readonly nextPageToken?: string;
}

export interface ReportListWindow {
  readonly createdAfter?: string;
  readonly startTimeAtOrAfter?: string;
  readonly startTimeBefore?: string;
}

export interface DownloadedReportMedia {
  readonly jobId: string;
  readonly reportId: string;
  readonly byteLength: number;
  readonly sha256: string;
  readonly contentType: string;
  readonly contentEncoding: "base64";
  readonly bodyBase64: string;
}
