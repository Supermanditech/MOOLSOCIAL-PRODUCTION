import { DisabledYouTubeAnalyticsV2Client } from "./analytics_client.js";
import {
  type AnalyticsDimension,
  type AnalyticsGroupItemType,
  type AnalyticsMetric,
  type AnalyticsReportQuery,
  type AnalyticsReportingClientOptions,
  type ReplayProtectionPort,
  type ReportListWindow,
  type VerifiedOwnerInvocation,
  YouTubeAnalyticsReportingError,
} from "./contracts.js";
import { DisabledYouTubeReportingV1Client } from "./reporting_client.js";

export const ANALYTICS_V2_OPERATIONS = [
  "analyticsV2ListGroups",
  "analyticsV2CreateGroup",
  "analyticsV2UpdateGroup",
  "analyticsV2DeleteGroup",
  "analyticsV2ListGroupItems",
  "analyticsV2InsertGroupItem",
  "analyticsV2DeleteGroupItem",
  "analyticsV2QueryReport",
] as const;

export const REPORTING_V1_OPERATIONS = [
  "reportingV1ListReportTypes",
  "reportingV1CreateJob",
  "reportingV1ListJobs",
  "reportingV1GetJob",
  "reportingV1DeleteJob",
  "reportingV1ListReports",
  "reportingV1GetReport",
  "reportingV1DownloadReportMedia",
] as const;

export const ANALYTICS_REPORTING_OPERATIONS = [
  ...ANALYTICS_V2_OPERATIONS,
  ...REPORTING_V1_OPERATIONS,
] as const;

export type AnalyticsReportingOperation =
  (typeof ANALYTICS_REPORTING_OPERATIONS)[number];

const operationSet = new Set<string>(ANALYTICS_REPORTING_OPERATIONS);

export function isAnalyticsReportingOperation(
  operation: string,
): operation is AnalyticsReportingOperation {
  return operationSet.has(operation);
}

/**
 * The router has already asked Firebase Admin to consume the limited-use App
 * Check token. This one-request bridge lets the isolated adapter verify that
 * exact authorization handoff without attempting a second provider consume.
 */
export class RouterConsumedAppCheckReplay
  implements ReplayProtectionPort
{
  private consumed = false;
  private readonly expectedKey: string;

  constructor(userId: string, replayId: string) {
    this.expectedKey = `${userId}:${replayId}`;
  }

  async consume(key: string): Promise<boolean> {
    if (this.consumed || key !== this.expectedKey) return false;
    this.consumed = true;
    return true;
  }
}

export interface AnalyticsReportingOperationClients {
  readonly analytics: Pick<
    DisabledYouTubeAnalyticsV2Client,
    | "listGroups"
    | "createGroup"
    | "updateGroup"
    | "deleteGroup"
    | "listGroupItems"
    | "insertGroupItem"
    | "deleteGroupItem"
    | "queryReport"
  >;
  readonly reporting: Pick<
    DisabledYouTubeReportingV1Client,
    | "listReportTypes"
    | "createJob"
    | "listJobs"
    | "getJob"
    | "deleteJob"
    | "listReports"
    | "getReport"
    | "downloadReportMedia"
  >;
}

export function createAnalyticsReportingClients(
  options: AnalyticsReportingClientOptions,
): AnalyticsReportingOperationClients {
  return {
    analytics: new DisabledYouTubeAnalyticsV2Client(options),
    reporting: new DisabledYouTubeReportingV1Client(options),
  };
}

function badRequest(message: string): never {
  throw new YouTubeAnalyticsReportingError(
    "bad_request",
    message,
    400,
  );
}

function allowOnly(
  body: Readonly<Record<string, unknown>>,
  fields: readonly string[],
): void {
  const allowed = new Set(["operation", ...fields]);
  if (Object.keys(body).some((field) => !allowed.has(field))) {
    badRequest("The YouTube request contains an unsupported field.");
  }
}

function requiredText(
  body: Readonly<Record<string, unknown>>,
  field: string,
): string {
  const value = body[field];
  if (typeof value !== "string" || !value.trim()) {
    badRequest(`${field} is required.`);
  }
  return value;
}

function optionalText(
  body: Readonly<Record<string, unknown>>,
  field: string,
): string | undefined {
  return body[field] === undefined ? undefined : requiredText(body, field);
}

function optionalInteger(
  body: Readonly<Record<string, unknown>>,
  field: string,
): number | undefined {
  const value = body[field];
  if (value === undefined) return undefined;
  if (!Number.isSafeInteger(value)) {
    badRequest(`${field} must be a whole number.`);
  }
  return value as number;
}

function optionalBoolean(
  body: Readonly<Record<string, unknown>>,
  field: string,
): boolean | undefined {
  const value = body[field];
  if (value === undefined) return undefined;
  if (typeof value !== "boolean") {
    badRequest(`${field} must be true or false.`);
  }
  return value;
}

function textList(
  body: Readonly<Record<string, unknown>>,
  field: string,
): readonly string[] {
  const value = body[field];
  if (
    !Array.isArray(value) ||
    !value.every((entry) => typeof entry === "string")
  ) {
    badRequest(`${field} must be a list of text values.`);
  }
  return value as readonly string[];
}

function optionalTextList(
  body: Readonly<Record<string, unknown>>,
  field: string,
): readonly string[] | undefined {
  return body[field] === undefined ? undefined : textList(body, field);
}

function objectField(
  body: Readonly<Record<string, unknown>>,
  field: string,
): Readonly<Record<string, unknown>> {
  const value = body[field];
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    badRequest(`${field} must be an object.`);
  }
  return value as Readonly<Record<string, unknown>>;
}

function analyticsGroupItemType(
  body: Readonly<Record<string, unknown>>,
  field: string,
): AnalyticsGroupItemType {
  const value = requiredText(body, field);
  if (
    value !== "youtube#channel" &&
    value !== "youtube#playlist" &&
    value !== "youtube#video"
  ) {
    badRequest("A supported analytics group item type is required.");
  }
  return value;
}

function reportQuery(
  body: Readonly<Record<string, unknown>>,
): AnalyticsReportQuery {
  allowOnly(body, [
    "startDate",
    "endDate",
    "metrics",
    "dimensions",
    "videoId",
    "sort",
    "maxResults",
    "startIndex",
  ]);
  const dimensions = optionalTextList(body, "dimensions");
  const videoId = optionalText(body, "videoId");
  const maxResults = optionalInteger(body, "maxResults");
  const startIndex = optionalInteger(body, "startIndex");
  const sort =
    body.sort === undefined
      ? undefined
      : (() => {
          const value = objectField(body, "sort");
          allowOnly(value, ["field", "direction"]);
          const direction = requiredText(value, "direction");
          if (direction !== "ascending" && direction !== "descending") {
            badRequest("A supported analytics sort direction is required.");
          }
          return {
            field: requiredText(value, "field") as
              | AnalyticsMetric
              | AnalyticsDimension,
            direction: direction as "ascending" | "descending",
          };
        })();
  return {
    startDate: requiredText(body, "startDate"),
    endDate: requiredText(body, "endDate"),
    metrics: textList(body, "metrics") as readonly AnalyticsMetric[],
    ...(dimensions === undefined
      ? {}
      : { dimensions: dimensions as readonly AnalyticsDimension[] }),
    ...(videoId === undefined ? {} : { videoId }),
    ...(sort === undefined ? {} : { sort }),
    ...(maxResults === undefined ? {} : { maxResults }),
    ...(startIndex === undefined ? {} : { startIndex }),
  };
}

function reportWindow(
  body: Readonly<Record<string, unknown>>,
): ReportListWindow | undefined {
  if (body.window === undefined) return undefined;
  const value = objectField(body, "window");
  allowOnly(value, [
    "createdAfter",
    "startTimeAtOrAfter",
    "startTimeBefore",
  ]);
  const createdAfter = optionalText(value, "createdAfter");
  const startTimeAtOrAfter = optionalText(value, "startTimeAtOrAfter");
  const startTimeBefore = optionalText(value, "startTimeBefore");
  return {
    ...(createdAfter === undefined ? {} : { createdAfter }),
    ...(startTimeAtOrAfter === undefined ? {} : { startTimeAtOrAfter }),
    ...(startTimeBefore === undefined ? {} : { startTimeBefore }),
  };
}

export async function dispatchAnalyticsReportingOperation(
  operation: AnalyticsReportingOperation,
  body: Readonly<Record<string, unknown>>,
  invocation: VerifiedOwnerInvocation,
  clients: AnalyticsReportingOperationClients,
): Promise<unknown> {
  switch (operation) {
    case "analyticsV2ListGroups": {
      allowOnly(body, ["groupId", "pageToken"]);
      const groupId = optionalText(body, "groupId");
      const pageToken = optionalText(body, "pageToken");
      return clients.analytics.listGroups(invocation, {
        ...(groupId === undefined ? {} : { groupId }),
        ...(pageToken === undefined ? {} : { pageToken }),
      });
    }
    case "analyticsV2CreateGroup":
      allowOnly(body, ["idempotencyKey", "title", "itemType"]);
      return clients.analytics.createGroup(invocation, {
        idempotencyKey: requiredText(body, "idempotencyKey"),
        title: requiredText(body, "title"),
        itemType: analyticsGroupItemType(body, "itemType"),
      });
    case "analyticsV2UpdateGroup":
      allowOnly(body, ["idempotencyKey", "groupId", "title"]);
      return clients.analytics.updateGroup(invocation, {
        idempotencyKey: requiredText(body, "idempotencyKey"),
        groupId: requiredText(body, "groupId"),
        title: requiredText(body, "title"),
      });
    case "analyticsV2DeleteGroup":
      allowOnly(body, [
        "idempotencyKey",
        "groupId",
        "confirmGroupId",
      ]);
      return clients.analytics.deleteGroup(invocation, {
        idempotencyKey: requiredText(body, "idempotencyKey"),
        groupId: requiredText(body, "groupId"),
        confirmGroupId: requiredText(body, "confirmGroupId"),
      });
    case "analyticsV2ListGroupItems":
      allowOnly(body, ["groupId"]);
      return clients.analytics.listGroupItems(
        invocation,
        requiredText(body, "groupId"),
      );
    case "analyticsV2InsertGroupItem":
      allowOnly(body, [
        "idempotencyKey",
        "groupId",
        "resourceType",
        "resourceId",
      ]);
      return clients.analytics.insertGroupItem(invocation, {
        idempotencyKey: requiredText(body, "idempotencyKey"),
        groupId: requiredText(body, "groupId"),
        resourceType: analyticsGroupItemType(body, "resourceType"),
        resourceId: requiredText(body, "resourceId"),
      });
    case "analyticsV2DeleteGroupItem":
      allowOnly(body, [
        "idempotencyKey",
        "groupItemId",
        "confirmGroupItemId",
      ]);
      return clients.analytics.deleteGroupItem(invocation, {
        idempotencyKey: requiredText(body, "idempotencyKey"),
        groupItemId: requiredText(body, "groupItemId"),
        confirmGroupItemId: requiredText(body, "confirmGroupItemId"),
      });
    case "analyticsV2QueryReport":
      return clients.analytics.queryReport(invocation, reportQuery(body));
    case "reportingV1ListReportTypes": {
      allowOnly(body, [
        "pageToken",
        "pageSize",
        "includeSystemManaged",
      ]);
      const pageToken = optionalText(body, "pageToken");
      const pageSize = optionalInteger(body, "pageSize");
      const includeSystemManaged = optionalBoolean(
        body,
        "includeSystemManaged",
      );
      return clients.reporting.listReportTypes(invocation, {
        ...(pageToken === undefined ? {} : { pageToken }),
        ...(pageSize === undefined ? {} : { pageSize }),
        ...(includeSystemManaged === undefined
          ? {}
          : { includeSystemManaged }),
      });
    }
    case "reportingV1CreateJob":
      allowOnly(body, [
        "idempotencyKey",
        "reportTypeId",
        "name",
      ]);
      return clients.reporting.createJob(invocation, {
        idempotencyKey: requiredText(body, "idempotencyKey"),
        reportTypeId: requiredText(body, "reportTypeId"),
        name: requiredText(body, "name"),
      });
    case "reportingV1ListJobs": {
      allowOnly(body, [
        "pageToken",
        "pageSize",
        "includeSystemManaged",
      ]);
      const pageToken = optionalText(body, "pageToken");
      const pageSize = optionalInteger(body, "pageSize");
      const includeSystemManaged = optionalBoolean(
        body,
        "includeSystemManaged",
      );
      return clients.reporting.listJobs(invocation, {
        ...(pageToken === undefined ? {} : { pageToken }),
        ...(pageSize === undefined ? {} : { pageSize }),
        ...(includeSystemManaged === undefined
          ? {}
          : { includeSystemManaged }),
      });
    }
    case "reportingV1GetJob":
      allowOnly(body, ["jobId"]);
      return clients.reporting.getJob(
        invocation,
        requiredText(body, "jobId"),
      );
    case "reportingV1DeleteJob":
      allowOnly(body, [
        "idempotencyKey",
        "jobId",
        "confirmJobId",
      ]);
      return clients.reporting.deleteJob(invocation, {
        idempotencyKey: requiredText(body, "idempotencyKey"),
        jobId: requiredText(body, "jobId"),
        confirmJobId: requiredText(body, "confirmJobId"),
      });
    case "reportingV1ListReports": {
      allowOnly(body, [
        "jobId",
        "pageToken",
        "pageSize",
        "window",
      ]);
      const pageToken = optionalText(body, "pageToken");
      const pageSize = optionalInteger(body, "pageSize");
      const window = reportWindow(body);
      return clients.reporting.listReports(invocation, {
        jobId: requiredText(body, "jobId"),
        ...(pageToken === undefined ? {} : { pageToken }),
        ...(pageSize === undefined ? {} : { pageSize }),
        ...(window === undefined ? {} : { window }),
      });
    }
    case "reportingV1GetReport":
      allowOnly(body, ["jobId", "reportId"]);
      return clients.reporting.getReport(invocation, {
        jobId: requiredText(body, "jobId"),
        reportId: requiredText(body, "reportId"),
      });
    case "reportingV1DownloadReportMedia": {
      allowOnly(body, ["jobId", "reportId", "maximumBytes"]);
      const maximumBytes = optionalInteger(body, "maximumBytes");
      return clients.reporting.downloadReportMedia(invocation, {
        jobId: requiredText(body, "jobId"),
        reportId: requiredText(body, "reportId"),
        ...(maximumBytes === undefined ? {} : { maximumBytes }),
      });
    }
  }
}
