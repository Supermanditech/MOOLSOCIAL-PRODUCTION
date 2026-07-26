import type { HttpTransportRequest } from "../../youtube/types.js";
import {
  type AnalyticsDimension,
  type AnalyticsGroup,
  type AnalyticsGroupItem,
  type AnalyticsGroupItemsResult,
  type AnalyticsGroupItemType,
  type AnalyticsGroupsPage,
  type AnalyticsMetric,
  type AnalyticsReportQuery,
  type AnalyticsReportResult,
  type AnalyticsReportingClientOptions,
  type VerifiedOwnerInvocation,
  YouTubeAnalyticsReportingError,
} from "./contracts.js";
import {
  ANALYTICS_API_ORIGIN,
  boundedInteger,
  clientChannelId,
  clientDate,
  clientPageToken,
  clientResourceId,
  clientTitle,
  clientVideoId,
  daysInclusive,
  nonNegativeProviderInteger,
  parseProviderJson,
  providerPageToken,
  providerResourceId,
  providerText,
  providerTimestamp,
  sendProviderRequest,
} from "./provider.js";
import {
  authorizeOwnerInvocation,
  idempotentMutation,
} from "./security.js";

const ANALYTICS_API = `${ANALYTICS_API_ORIGIN}/v2`;
const MAX_ANALYTICS_RANGE_DAYS = 366;
const MAX_ANALYTICS_METRICS = 10;
const MAX_ANALYTICS_DIMENSIONS = 3;
const MAX_ANALYTICS_RESULTS = 200;
const MAX_GROUP_ITEMS = 200;

const ANALYTICS_METRICS = new Set<AnalyticsMetric>([
  "views",
  "engagedViews",
  "estimatedMinutesWatched",
  "averageViewDuration",
  "averageViewPercentage",
  "likes",
  "comments",
  "shares",
  "subscribersGained",
  "subscribersLost",
  "playlistStarts",
  "viewsPerPlaylistStart",
  "averageTimeInPlaylist",
]);

const ANALYTICS_DIMENSIONS = new Set<AnalyticsDimension>([
  "day",
  "video",
  "country",
  "insightTrafficSourceType",
  "deviceType",
  "operatingSystem",
  "subscribedStatus",
  "playlist",
]);

interface ApiGroup {
  readonly id?: string;
  readonly kind?: string;
  readonly snippet?: {
    readonly title?: string;
    readonly publishedAt?: string;
  };
  readonly contentDetails?: {
    readonly itemCount?: string;
    readonly itemType?: string;
  };
}

interface ApiGroupItem {
  readonly id?: string;
  readonly kind?: string;
  readonly groupId?: string;
  readonly resource?: {
    readonly kind?: string;
    readonly id?: string;
  };
}

interface ApiGroupsEnvelope {
  readonly items?: readonly ApiGroup[];
  readonly nextPageToken?: string;
}

interface ApiGroupItemsEnvelope {
  readonly items?: readonly ApiGroupItem[];
}

interface ApiAnalyticsEnvelope {
  readonly columnHeaders?: readonly {
    readonly name?: string;
    readonly columnType?: "DIMENSION" | "METRIC";
  }[];
  readonly rows?: readonly (readonly unknown[])[];
}

function uniqueAllowlisted<T extends string>(
  values: readonly T[],
  allowlist: ReadonlySet<T>,
  maximum: number,
  label: string,
): readonly T[] {
  if (values.length < 1 || values.length > maximum) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `${label} must contain between 1 and ${maximum} values.`,
      400,
    );
  }
  const unique = new Set(values);
  if (unique.size !== values.length || values.some((value) => !allowlist.has(value))) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `${label} contains an unsupported or duplicate value.`,
      400,
    );
  }
  return [...values];
}

function analyticsGroupItemType(value: unknown): AnalyticsGroupItemType {
  if (
    value === "youtube#channel" ||
    value === "youtube#playlist" ||
    value === "youtube#video"
  ) {
    return value;
  }
  if (value === "youtubePartner#asset") {
    throw new YouTubeAnalyticsReportingError(
      "eligibility_required",
      "YouTube partner asset groups require content-owner eligibility.",
      403,
    );
  }
  throw new YouTubeAnalyticsReportingError(
    "provider_rejected",
    "YouTube returned an invalid analytics group item type.",
    502,
  );
}

function mapGroup(value: ApiGroup): AnalyticsGroup {
  if (value.kind !== undefined && value.kind !== "youtube#group") {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid analytics group.",
      502,
    );
  }
  return {
    groupId: providerResourceId(value.id, "analytics group"),
    title: providerText(value.snippet?.title, "analytics group title", 500),
    publishedAt: providerTimestamp(
      value.snippet?.publishedAt,
      "analytics group creation time",
    ),
    itemCount: nonNegativeProviderInteger(
      value.contentDetails?.itemCount,
      "analytics group item count",
    ),
    itemType: analyticsGroupItemType(value.contentDetails?.itemType),
  };
}

function mapGroupItem(value: ApiGroupItem): AnalyticsGroupItem {
  if (value.kind !== undefined && value.kind !== "youtube#groupItem") {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid analytics group item.",
      502,
    );
  }
  const resourceType = analyticsGroupItemType(value.resource?.kind);
  return {
    groupItemId: providerResourceId(value.id, "analytics group item"),
    groupId: providerResourceId(value.groupId, "analytics group"),
    resourceType,
    resourceId: providerResourceId(
      value.resource?.id,
      "analytics group resource",
    ),
  };
}

function groupResourceId(
  resourceType: AnalyticsGroupItemType,
  value: string,
): string {
  switch (resourceType) {
    case "youtube#channel":
      return clientChannelId(value);
    case "youtube#video":
      return clientVideoId(value);
    case "youtube#playlist":
      return clientResourceId(value, "playlist");
  }
}

export class DisabledYouTubeAnalyticsV2Client {
  constructor(private readonly options: AnalyticsReportingClientOptions) {}

  private async requestJson<T>(
    invocation: VerifiedOwnerInvocation,
    operation: string,
    request: Omit<HttpTransportRequest, "headers">,
    quotaAmount = 1,
  ): Promise<T> {
    await this.options.quota.reserve({
      principal: invocation.principal,
      bucket: "analytics",
      amount: quotaAmount,
      operation,
      requestId: invocation.requestId,
    });
    const response = await sendProviderRequest(this.options.transport, {
      ...request,
      headers: {
        authorization: `Bearer ${invocation.accessToken}`,
        ...(request.body === undefined
          ? {}
          : { "content-type": "application/json; charset=UTF-8" }),
      },
    });
    return parseProviderJson<T>(response.body || "{}");
  }

  async listGroups(
    invocation: VerifiedOwnerInvocation,
    query: {
      readonly groupId?: string;
      readonly pageToken?: string;
    } = {},
  ): Promise<AnalyticsGroupsPage> {
    await authorizeOwnerInvocation(this.options, invocation);
    const groupId =
      query.groupId === undefined
        ? undefined
        : clientResourceId(query.groupId, "analytics group");
    const token = clientPageToken(query.pageToken);
    if (groupId !== undefined && token !== undefined) {
      throw new YouTubeAnalyticsReportingError(
        "bad_request",
        "A group identifier and page token cannot be combined.",
        400,
      );
    }
    const url = new URL(`${ANALYTICS_API}/groups`);
    if (groupId === undefined) {
      url.searchParams.set("mine", "true");
    } else {
      url.searchParams.set("id", groupId);
    }
    if (token !== undefined) url.searchParams.set("pageToken", token);
    const envelope = await this.requestJson<ApiGroupsEnvelope>(
      invocation,
      "youtubeAnalytics.groups.list",
      { url: url.toString() },
    );
    const values = envelope.items ?? [];
    if (values.length > MAX_GROUP_ITEMS) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned too many analytics groups.",
        502,
      );
    }
    const items = values.map(mapGroup);
    if (
      groupId !== undefined &&
      (items.length > 1 || (items[0] !== undefined && items[0].groupId !== groupId))
    ) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned a different analytics group.",
        502,
      );
    }
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      items,
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async createGroup(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly idempotencyKey: string;
      readonly title: string;
      readonly itemType: AnalyticsGroupItemType;
    },
  ): Promise<AnalyticsGroup> {
    await authorizeOwnerInvocation(this.options, invocation);
    const title = clientTitle(input.title, 500);
    const itemType = analyticsGroupItemType(input.itemType);
    return idempotentMutation(
      this.options,
      "youtubeAnalytics.groups.insert",
      input.idempotencyKey,
      { title, itemType, channelId: invocation.owner.channelId },
      async () => {
        const value = await this.requestJson<ApiGroup>(
          invocation,
          "youtubeAnalytics.groups.insert",
          {
            url: `${ANALYTICS_API}/groups`,
            method: "POST",
            body: JSON.stringify({
              kind: "youtube#group",
              snippet: { title },
              contentDetails: { itemType },
            }),
          },
        );
        return mapGroup(value);
      },
    );
  }

  async updateGroup(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly idempotencyKey: string;
      readonly groupId: string;
      readonly title: string;
    },
  ): Promise<AnalyticsGroup> {
    await authorizeOwnerInvocation(this.options, invocation);
    const groupId = clientResourceId(input.groupId, "analytics group");
    const title = clientTitle(input.title, 500);
    return idempotentMutation(
      this.options,
      "youtubeAnalytics.groups.update",
      input.idempotencyKey,
      { groupId, title, channelId: invocation.owner.channelId },
      async () => {
        const value = await this.requestJson<ApiGroup>(
          invocation,
          "youtubeAnalytics.groups.update",
          {
            url: `${ANALYTICS_API}/groups`,
            method: "PUT",
            body: JSON.stringify({
              id: groupId,
              kind: "youtube#group",
              snippet: { title },
            }),
          },
        );
        const group = mapGroup(value);
        if (group.groupId !== groupId) {
          throw new YouTubeAnalyticsReportingError(
            "provider_rejected",
            "YouTube returned a different analytics group.",
            502,
          );
        }
        return group;
      },
    );
  }

  async deleteGroup(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly idempotencyKey: string;
      readonly groupId: string;
      readonly confirmGroupId: string;
    },
  ): Promise<{ readonly deleted: true; readonly groupId: string }> {
    await authorizeOwnerInvocation(this.options, invocation);
    const groupId = clientResourceId(input.groupId, "analytics group");
    if (input.confirmGroupId.trim() !== groupId) {
      throw new YouTubeAnalyticsReportingError(
        "bad_request",
        "Confirm the analytics group before deleting it.",
        400,
      );
    }
    return idempotentMutation(
      this.options,
      "youtubeAnalytics.groups.delete",
      input.idempotencyKey,
      { groupId, channelId: invocation.owner.channelId },
      async () => {
        const url = new URL(`${ANALYTICS_API}/groups`);
        url.searchParams.set("id", groupId);
        await this.requestJson<Record<string, never>>(
          invocation,
          "youtubeAnalytics.groups.delete",
          { url: url.toString(), method: "DELETE" },
        );
        return { deleted: true, groupId };
      },
    );
  }

  async listGroupItems(
    invocation: VerifiedOwnerInvocation,
    groupIdValue: string,
  ): Promise<AnalyticsGroupItemsResult> {
    await authorizeOwnerInvocation(this.options, invocation);
    const groupId = clientResourceId(groupIdValue, "analytics group");
    const url = new URL(`${ANALYTICS_API}/groupItems`);
    url.searchParams.set("groupId", groupId);
    const envelope = await this.requestJson<ApiGroupItemsEnvelope>(
      invocation,
      "youtubeAnalytics.groupItems.list",
      { url: url.toString() },
    );
    const values = envelope.items ?? [];
    if (values.length > MAX_GROUP_ITEMS) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned too many analytics group items.",
        502,
      );
    }
    const items = values.map(mapGroupItem);
    if (items.some((item) => item.groupId !== groupId)) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned an item from a different analytics group.",
        502,
      );
    }
    return { groupId, items };
  }

  async insertGroupItem(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly idempotencyKey: string;
      readonly groupId: string;
      readonly resourceType: AnalyticsGroupItemType;
      readonly resourceId: string;
    },
  ): Promise<AnalyticsGroupItem> {
    await authorizeOwnerInvocation(this.options, invocation);
    const groupId = clientResourceId(input.groupId, "analytics group");
    const resourceType = analyticsGroupItemType(input.resourceType);
    const resourceId = groupResourceId(resourceType, input.resourceId);
    return idempotentMutation(
      this.options,
      "youtubeAnalytics.groupItems.insert",
      input.idempotencyKey,
      { groupId, resourceType, resourceId },
      async () => {
        const value = await this.requestJson<ApiGroupItem>(
          invocation,
          "youtubeAnalytics.groupItems.insert",
          {
            url: `${ANALYTICS_API}/groupItems`,
            method: "POST",
            body: JSON.stringify({
              kind: "youtube#groupItem",
              groupId,
              resource: { kind: resourceType, id: resourceId },
            }),
          },
        );
        const item = mapGroupItem(value);
        if (
          item.groupId !== groupId ||
          item.resourceType !== resourceType ||
          item.resourceId !== resourceId
        ) {
          throw new YouTubeAnalyticsReportingError(
            "provider_rejected",
            "YouTube returned a different analytics group item.",
            502,
          );
        }
        return item;
      },
    );
  }

  async deleteGroupItem(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly idempotencyKey: string;
      readonly groupItemId: string;
      readonly confirmGroupItemId: string;
    },
  ): Promise<{ readonly deleted: true; readonly groupItemId: string }> {
    await authorizeOwnerInvocation(this.options, invocation);
    const groupItemId = clientResourceId(
      input.groupItemId,
      "analytics group item",
    );
    if (input.confirmGroupItemId.trim() !== groupItemId) {
      throw new YouTubeAnalyticsReportingError(
        "bad_request",
        "Confirm the analytics group item before deleting it.",
        400,
      );
    }
    return idempotentMutation(
      this.options,
      "youtubeAnalytics.groupItems.delete",
      input.idempotencyKey,
      { groupItemId, channelId: invocation.owner.channelId },
      async () => {
        const url = new URL(`${ANALYTICS_API}/groupItems`);
        url.searchParams.set("id", groupItemId);
        await this.requestJson<Record<string, never>>(
          invocation,
          "youtubeAnalytics.groupItems.delete",
          { url: url.toString(), method: "DELETE" },
        );
        return { deleted: true, groupItemId };
      },
    );
  }

  async queryReport(
    invocation: VerifiedOwnerInvocation,
    query: AnalyticsReportQuery,
  ): Promise<AnalyticsReportResult> {
    await authorizeOwnerInvocation(this.options, invocation);
    const startDate = clientDate(query.startDate, "Analytics start date");
    const endDate = clientDate(query.endDate, "Analytics end date");
    if (
      startDate > endDate ||
      daysInclusive(startDate, endDate) > MAX_ANALYTICS_RANGE_DAYS
    ) {
      throw new YouTubeAnalyticsReportingError(
        "bad_request",
        `Analytics date range must be ordered and no longer than ${MAX_ANALYTICS_RANGE_DAYS} days.`,
        400,
      );
    }
    const metrics = uniqueAllowlisted(
      query.metrics,
      ANALYTICS_METRICS,
      MAX_ANALYTICS_METRICS,
      "Analytics metrics",
    );
    const dimensions =
      query.dimensions === undefined
        ? []
        : uniqueAllowlisted(
            query.dimensions,
            ANALYTICS_DIMENSIONS,
            MAX_ANALYTICS_DIMENSIONS,
            "Analytics dimensions",
          );
    const maxResults = boundedInteger(
      query.maxResults,
      50,
      1,
      MAX_ANALYTICS_RESULTS,
      "Analytics maxResults",
    );
    const startIndex = boundedInteger(
      query.startIndex,
      1,
      1,
      10_000,
      "Analytics startIndex",
    );
    const videoId =
      query.videoId === undefined ? undefined : clientVideoId(query.videoId);
    if (query.sort !== undefined) {
      if (
        !metrics.includes(query.sort.field as AnalyticsMetric) &&
        !dimensions.includes(query.sort.field as AnalyticsDimension)
      ) {
        throw new YouTubeAnalyticsReportingError(
          "bad_request",
          "Analytics sort must reference a selected metric or dimension.",
          400,
        );
      }
      if (
        query.sort.direction !== "ascending" &&
        query.sort.direction !== "descending"
      ) {
        throw new YouTubeAnalyticsReportingError(
          "bad_request",
          "Analytics sort direction is unsupported.",
          400,
        );
      }
    }
    const url = new URL(`${ANALYTICS_API}/reports`);
    url.searchParams.set("ids", "channel==MINE");
    url.searchParams.set("startDate", startDate);
    url.searchParams.set("endDate", endDate);
    url.searchParams.set("metrics", metrics.join(","));
    if (dimensions.length > 0) {
      url.searchParams.set("dimensions", dimensions.join(","));
    }
    if (videoId !== undefined) {
      url.searchParams.set("filters", `video==${videoId}`);
    }
    if (query.sort !== undefined) {
      url.searchParams.set(
        "sort",
        `${query.sort.direction === "descending" ? "-" : ""}${query.sort.field}`,
      );
    }
    url.searchParams.set("maxResults", String(maxResults));
    url.searchParams.set("startIndex", String(startIndex));
    const envelope = await this.requestJson<ApiAnalyticsEnvelope>(
      invocation,
      "youtubeAnalytics.reports.query.bounded",
      { url: url.toString() },
    );
    const headers = envelope.columnHeaders ?? [];
    const expectedColumns = new Set<string>([...dimensions, ...metrics]);
    if (
      headers.length !== expectedColumns.size ||
      headers.some(
        (header) =>
          typeof header.name !== "string" ||
          !expectedColumns.has(header.name) ||
          (header.columnType !== "DIMENSION" &&
            header.columnType !== "METRIC"),
      ) ||
      new Set(headers.map((header) => header.name)).size !== headers.length
    ) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned analytics columns outside the requested contract.",
        502,
      );
    }
    const providerRows = envelope.rows ?? [];
    if (providerRows.length > maxResults) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned too many analytics rows.",
        502,
      );
    }
    const rows = providerRows.map((values) => {
      if (values.length !== headers.length) {
        throw new YouTubeAnalyticsReportingError(
          "provider_rejected",
          "YouTube returned an invalid analytics row.",
          502,
        );
      }
      const dimensionsOutput: Record<string, string> = {};
      const metricsOutput: Record<string, number> = {};
      headers.forEach((header, index) => {
        const name = header.name!;
        const value = values[index];
        if (header.columnType === "DIMENSION") {
          if (
            typeof value !== "string" &&
            typeof value !== "number" &&
            typeof value !== "boolean"
          ) {
            throw new YouTubeAnalyticsReportingError(
              "provider_rejected",
              "YouTube returned an invalid analytics dimension.",
              502,
            );
          }
          dimensionsOutput[name] = String(value);
        } else {
          const numeric = Number(value);
          if (!Number.isFinite(numeric)) {
            throw new YouTubeAnalyticsReportingError(
              "provider_rejected",
              "YouTube returned an invalid analytics metric.",
              502,
            );
          }
          metricsOutput[name] = numeric;
        }
      });
      return { dimensions: dimensionsOutput, metrics: metricsOutput };
    });
    const continuationStartIndex =
      rows.length === maxResults ? startIndex + rows.length : undefined;
    return {
      channelId: invocation.owner.channelId,
      startDate,
      endDate,
      rows,
      ...(continuationStartIndex === undefined
        ? {}
        : { continuationStartIndex }),
      empty: rows.length === 0,
    };
  }
}
