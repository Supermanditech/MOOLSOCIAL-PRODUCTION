import { createHash } from "node:crypto";

import type {
  HttpTransportRequest,
  HttpTransportResponse,
} from "../../youtube/types.js";
import {
  type AnalyticsReportingClientOptions,
  type DownloadedReportMedia,
  type ReportListWindow,
  type ReportingJob,
  type ReportingPage,
  type ReportingReport,
  type ReportingReportType,
  type VerifiedOwnerInvocation,
  YouTubeAnalyticsReportingError,
} from "./contracts.js";
import {
  boundedInteger,
  clientPageToken,
  clientResourceId,
  clientTimestamp,
  clientTitle,
  parseProviderJson,
  providerPageToken,
  providerResourceId,
  providerText,
  providerTimestamp,
  REPORTING_API_ORIGIN,
  sendProviderRequest,
} from "./provider.js";
import {
  authorizeOwnerInvocation,
  idempotentMutation,
} from "./security.js";

const REPORTING_API = `${REPORTING_API_ORIGIN}/v1`;
const MAX_PAGE_SIZE = 100;
const DEFAULT_PAGE_SIZE = 50;
const MAX_REPORT_TYPE_LOOKUP_PAGES = 3;
const MAX_REPORT_WINDOW_MILLISECONDS = 366 * 24 * 60 * 60 * 1000;
const MAX_MEDIA_BYTES = 8 * 1024 * 1024;
const MEDIA_RESOURCE_NAME = /^media\/[A-Za-z0-9._~:/-]{1,900}$/u;
const ALLOWED_MEDIA_TYPES = new Set([
  "text/csv",
  "application/csv",
  "application/gzip",
  "application/zip",
  "application/octet-stream",
]);

interface ApiReportType {
  readonly id?: string;
  readonly name?: string;
  readonly systemManaged?: boolean;
  readonly deprecateTime?: string;
}

interface ApiReportTypesEnvelope {
  readonly reportTypes?: readonly ApiReportType[];
  readonly nextPageToken?: string;
}

interface ApiJob {
  readonly id?: string;
  readonly reportTypeId?: string;
  readonly name?: string;
  readonly systemManaged?: boolean;
  readonly createTime?: string;
  readonly expireTime?: string;
}

interface ApiJobsEnvelope {
  readonly jobs?: readonly ApiJob[];
  readonly nextPageToken?: string;
}

interface ApiReport {
  readonly id?: string;
  readonly jobId?: string;
  readonly createTime?: string;
  readonly startTime?: string;
  readonly endTime?: string;
  readonly jobExpireTime?: string;
  readonly downloadUrl?: string;
}

interface ApiReportsEnvelope {
  readonly reports?: readonly ApiReport[];
  readonly nextPageToken?: string;
}

function providerBoolean(value: unknown, label: string): boolean {
  if (typeof value !== "boolean") {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      `YouTube returned invalid ${label}.`,
      502,
    );
  }
  return value;
}

function optionalProviderTimestamp(
  value: unknown,
  label: string,
): string | undefined {
  return value === undefined ? undefined : providerTimestamp(value, label);
}

function mediaResourceName(value: unknown): string {
  if (typeof value !== "string" || value.length > 1200) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid report media location.",
      502,
    );
  }
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid report media location.",
      502,
    );
  }
  const queryNames = [...url.searchParams.keys()];
  if (
    url.protocol !== "https:" ||
    url.hostname !== "youtubereporting.googleapis.com" ||
    url.port !== "" ||
    url.username !== "" ||
    url.password !== "" ||
    url.hash !== "" ||
    !url.pathname.startsWith("/v1/media/") ||
    queryNames.some((name) => name !== "alt") ||
    (url.searchParams.has("alt") && url.searchParams.get("alt") !== "media")
  ) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid report media location.",
      502,
    );
  }
  const resourceName = url.pathname.slice("/v1/".length);
  if (
    !MEDIA_RESOURCE_NAME.test(resourceName) ||
    resourceName.includes("..") ||
    resourceName.includes("//") ||
    resourceName.includes("%")
  ) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid report media location.",
      502,
    );
  }
  return resourceName;
}

function mapReportType(
  value: ApiReportType,
  now: Date,
): ReportingReportType {
  const reportTypeId = providerResourceId(value.id, "report type");
  const systemManaged = providerBoolean(
    value.systemManaged,
    "report type status",
  );
  const deprecateTime = optionalProviderTimestamp(
    value.deprecateTime,
    "report type deprecation time",
  );
  const deprecated =
    deprecateTime !== undefined &&
    Date.parse(deprecateTime) <= now.getTime();
  return {
    reportTypeId,
    name: providerText(value.name, "report type name", 100),
    systemManaged,
    ...(deprecateTime === undefined ? {} : { deprecateTime }),
    availability: deprecated
      ? "deprecated"
      : systemManaged
        ? "system-managed"
        : "available",
  };
}

function mapJob(value: ApiJob, now: Date): ReportingJob {
  const systemManaged = providerBoolean(value.systemManaged, "job status");
  const expireTime = optionalProviderTimestamp(
    value.expireTime,
    "job expiration time",
  );
  const expired =
    expireTime !== undefined && Date.parse(expireTime) <= now.getTime();
  return {
    jobId: providerResourceId(value.id, "reporting job"),
    reportTypeId: providerResourceId(value.reportTypeId, "report type"),
    name: providerText(value.name, "reporting job name", 100),
    systemManaged,
    createTime: providerTimestamp(value.createTime, "job creation time"),
    ...(expireTime === undefined ? {} : { expireTime }),
    status: systemManaged ? "system-managed" : expired ? "expired" : "active",
  };
}

function mapReport(value: ApiReport, expectedJobId: string): ReportingReport {
  const reportId = providerResourceId(value.id, "report");
  const jobId = providerResourceId(value.jobId, "reporting job");
  if (jobId !== expectedJobId) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned a report from a different job.",
      502,
    );
  }
  const startTime = providerTimestamp(value.startTime, "report start time");
  const endTime = providerTimestamp(value.endTime, "report end time");
  if (startTime >= endTime) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid report time range.",
      502,
    );
  }
  const jobExpireTime = optionalProviderTimestamp(
    value.jobExpireTime,
    "report job expiration time",
  );
  return {
    reportId,
    jobId,
    createTime: providerTimestamp(value.createTime, "report creation time"),
    startTime,
    endTime,
    ...(jobExpireTime === undefined ? {} : { jobExpireTime }),
    mediaResourceName: mediaResourceName(value.downloadUrl),
  };
}

function normalizedContentType(value: string | undefined): string {
  const mediaType = (value ?? "").split(";", 1)[0]!.trim().toLowerCase();
  if (!ALLOWED_MEDIA_TYPES.has(mediaType)) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an unsupported report media type.",
      502,
    );
  }
  return mediaType;
}

export class DisabledYouTubeReportingV1Client {
  private readonly now: () => Date;

  constructor(private readonly options: AnalyticsReportingClientOptions) {
    this.now = options.now ?? (() => new Date());
  }

  private async providerRequest(
    invocation: VerifiedOwnerInvocation,
    operation: string,
    request: Omit<HttpTransportRequest, "headers">,
  ): Promise<HttpTransportResponse> {
    await this.options.quota.reserve({
      principal: invocation.principal,
      bucket: "analytics",
      amount: 1,
      operation,
      requestId: invocation.requestId,
    });
    return sendProviderRequest(this.options.transport, {
      ...request,
      headers: {
        authorization: `Bearer ${invocation.accessToken}`,
        ...(request.body === undefined
          ? {}
          : { "content-type": "application/json; charset=UTF-8" }),
      },
    });
  }

  private async requestJson<T>(
    invocation: VerifiedOwnerInvocation,
    operation: string,
    request: Omit<HttpTransportRequest, "headers">,
  ): Promise<T> {
    const response = await this.providerRequest(
      invocation,
      operation,
      request,
    );
    return parseProviderJson<T>(response.body || "{}");
  }

  private pageSize(value: number | undefined): number {
    return boundedInteger(
      value,
      DEFAULT_PAGE_SIZE,
      1,
      MAX_PAGE_SIZE,
      "Reporting pageSize",
    );
  }

  private async reportTypesPage(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly pageToken?: string;
      readonly pageSize?: number;
      readonly includeSystemManaged?: boolean;
    },
  ): Promise<ReportingPage<ReportingReportType>> {
    const pageSize = this.pageSize(input.pageSize);
    const pageToken = clientPageToken(input.pageToken);
    const url = new URL(`${REPORTING_API}/reportTypes`);
    url.searchParams.set("pageSize", String(pageSize));
    url.searchParams.set(
      "includeSystemManaged",
      input.includeSystemManaged === true ? "true" : "false",
    );
    if (pageToken !== undefined) url.searchParams.set("pageToken", pageToken);
    const envelope = await this.requestJson<ApiReportTypesEnvelope>(
      invocation,
      "youtubereporting.reportTypes.list",
      { url: url.toString() },
    );
    const values = envelope.reportTypes ?? [];
    if (values.length > pageSize) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned too many report types.",
        502,
      );
    }
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      items: values.map((value) => mapReportType(value, this.now())),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  async listReportTypes(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly pageToken?: string;
      readonly pageSize?: number;
      readonly includeSystemManaged?: boolean;
    } = {},
  ): Promise<ReportingPage<ReportingReportType>> {
    await authorizeOwnerInvocation(this.options, invocation);
    return this.reportTypesPage(invocation, input);
  }

  private async findReportType(
    invocation: VerifiedOwnerInvocation,
    reportTypeId: string,
  ): Promise<ReportingReportType> {
    let token: string | undefined;
    for (let page = 0; page < MAX_REPORT_TYPE_LOOKUP_PAGES; page += 1) {
      const result = await this.reportTypesPage(invocation, {
        pageSize: MAX_PAGE_SIZE,
        includeSystemManaged: true,
        ...(token === undefined ? {} : { pageToken: token }),
      });
      const match = result.items.find(
        (value) => value.reportTypeId === reportTypeId,
      );
      if (match !== undefined) return match;
      token = result.nextPageToken;
      if (token === undefined) break;
    }
    throw new YouTubeAnalyticsReportingError(
      "eligibility_required",
      "This report type is not available to the connected YouTube channel.",
      403,
    );
  }

  async createJob(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly idempotencyKey: string;
      readonly reportTypeId: string;
      readonly name: string;
    },
  ): Promise<ReportingJob> {
    await authorizeOwnerInvocation(this.options, invocation);
    const reportTypeId = clientResourceId(input.reportTypeId, "report type");
    const name = clientTitle(input.name, 100);
    return idempotentMutation(
      this.options,
      "youtubereporting.jobs.create",
      input.idempotencyKey,
      { reportTypeId, name, channelId: invocation.owner.channelId },
      async () => {
        const reportType = await this.findReportType(
          invocation,
          reportTypeId,
        );
        if (reportType.availability !== "available") {
          throw new YouTubeAnalyticsReportingError(
            "status_conflict",
            "This report type cannot be used to create a reporting job.",
            409,
          );
        }
        const value = await this.requestJson<ApiJob>(
          invocation,
          "youtubereporting.jobs.create",
          {
            url: `${REPORTING_API}/jobs`,
            method: "POST",
            body: JSON.stringify({ reportTypeId, name }),
          },
        );
        const job = mapJob(value, this.now());
        if (
          job.reportTypeId !== reportTypeId ||
          job.name !== name ||
          job.status !== "active"
        ) {
          throw new YouTubeAnalyticsReportingError(
            "provider_rejected",
            "YouTube returned a different or inactive reporting job.",
            502,
          );
        }
        return job;
      },
    );
  }

  async listJobs(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly pageToken?: string;
      readonly pageSize?: number;
      readonly includeSystemManaged?: boolean;
    } = {},
  ): Promise<ReportingPage<ReportingJob>> {
    await authorizeOwnerInvocation(this.options, invocation);
    const pageSize = this.pageSize(input.pageSize);
    const pageToken = clientPageToken(input.pageToken);
    const url = new URL(`${REPORTING_API}/jobs`);
    url.searchParams.set("pageSize", String(pageSize));
    url.searchParams.set(
      "includeSystemManaged",
      input.includeSystemManaged === true ? "true" : "false",
    );
    if (pageToken !== undefined) url.searchParams.set("pageToken", pageToken);
    const envelope = await this.requestJson<ApiJobsEnvelope>(
      invocation,
      "youtubereporting.jobs.list",
      { url: url.toString() },
    );
    const values = envelope.jobs ?? [];
    if (values.length > pageSize) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned too many reporting jobs.",
        502,
      );
    }
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      items: values.map((value) => mapJob(value, this.now())),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  private async getJobInternal(
    invocation: VerifiedOwnerInvocation,
    jobId: string,
  ): Promise<ReportingJob> {
    const value = await this.requestJson<ApiJob>(
      invocation,
      "youtubereporting.jobs.get",
      { url: `${REPORTING_API}/jobs/${encodeURIComponent(jobId)}` },
    );
    const job = mapJob(value, this.now());
    if (job.jobId !== jobId) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned a different reporting job.",
        502,
      );
    }
    return job;
  }

  async getJob(
    invocation: VerifiedOwnerInvocation,
    jobIdValue: string,
  ): Promise<ReportingJob> {
    await authorizeOwnerInvocation(this.options, invocation);
    return this.getJobInternal(
      invocation,
      clientResourceId(jobIdValue, "reporting job"),
    );
  }

  async deleteJob(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly idempotencyKey: string;
      readonly jobId: string;
      readonly confirmJobId: string;
    },
  ): Promise<{ readonly deleted: true; readonly jobId: string }> {
    await authorizeOwnerInvocation(this.options, invocation);
    const jobId = clientResourceId(input.jobId, "reporting job");
    if (input.confirmJobId.trim() !== jobId) {
      throw new YouTubeAnalyticsReportingError(
        "bad_request",
        "Confirm the reporting job before deleting it.",
        400,
      );
    }
    return idempotentMutation(
      this.options,
      "youtubereporting.jobs.delete",
      input.idempotencyKey,
      { jobId, channelId: invocation.owner.channelId },
      async () => {
        const job = await this.getJobInternal(invocation, jobId);
        if (job.status !== "active") {
          throw new YouTubeAnalyticsReportingError(
            "status_conflict",
            "Only an active user-managed reporting job can be deleted.",
            409,
          );
        }
        await this.requestJson<Record<string, never>>(
          invocation,
          "youtubereporting.jobs.delete",
          {
            url: `${REPORTING_API}/jobs/${encodeURIComponent(jobId)}`,
            method: "DELETE",
          },
        );
        return { deleted: true, jobId };
      },
    );
  }

  private reportWindow(window: ReportListWindow): {
    readonly createdAfter?: string;
    readonly startTimeAtOrAfter?: string;
    readonly startTimeBefore?: string;
  } {
    const createdAfter =
      window.createdAfter === undefined
        ? undefined
        : clientTimestamp(window.createdAfter, "createdAfter");
    const startTimeAtOrAfter =
      window.startTimeAtOrAfter === undefined
        ? undefined
        : clientTimestamp(
            window.startTimeAtOrAfter,
            "startTimeAtOrAfter",
          );
    const startTimeBefore =
      window.startTimeBefore === undefined
        ? undefined
        : clientTimestamp(window.startTimeBefore, "startTimeBefore");
    if (
      startTimeAtOrAfter !== undefined &&
      startTimeBefore !== undefined &&
      (startTimeAtOrAfter >= startTimeBefore ||
        Date.parse(startTimeBefore) - Date.parse(startTimeAtOrAfter) >
          MAX_REPORT_WINDOW_MILLISECONDS)
    ) {
      throw new YouTubeAnalyticsReportingError(
        "bad_request",
        "The report time window must be ordered and no longer than 366 days.",
        400,
      );
    }
    return {
      ...(createdAfter === undefined ? {} : { createdAfter }),
      ...(startTimeAtOrAfter === undefined
        ? {}
        : { startTimeAtOrAfter }),
      ...(startTimeBefore === undefined ? {} : { startTimeBefore }),
    };
  }

  async listReports(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly jobId: string;
      readonly pageToken?: string;
      readonly pageSize?: number;
      readonly window?: ReportListWindow;
    },
  ): Promise<ReportingPage<ReportingReport>> {
    await authorizeOwnerInvocation(this.options, invocation);
    const jobId = clientResourceId(input.jobId, "reporting job");
    const pageSize = this.pageSize(input.pageSize);
    const pageToken = clientPageToken(input.pageToken);
    const window = this.reportWindow(input.window ?? {});
    const url = new URL(
      `${REPORTING_API}/jobs/${encodeURIComponent(jobId)}/reports`,
    );
    url.searchParams.set("pageSize", String(pageSize));
    if (pageToken !== undefined) url.searchParams.set("pageToken", pageToken);
    for (const [name, value] of Object.entries(window)) {
      url.searchParams.set(name, value);
    }
    const envelope = await this.requestJson<ApiReportsEnvelope>(
      invocation,
      "youtubereporting.jobs.reports.list",
      { url: url.toString() },
    );
    const values = envelope.reports ?? [];
    if (values.length > pageSize) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned too many reports.",
        502,
      );
    }
    const nextPageToken = providerPageToken(envelope.nextPageToken);
    return {
      items: values.map((value) => mapReport(value, jobId)),
      ...(nextPageToken === undefined ? {} : { nextPageToken }),
    };
  }

  private async getReportInternal(
    invocation: VerifiedOwnerInvocation,
    jobId: string,
    reportId: string,
  ): Promise<ReportingReport> {
    const value = await this.requestJson<ApiReport>(
      invocation,
      "youtubereporting.jobs.reports.get",
      {
        url:
          `${REPORTING_API}/jobs/${encodeURIComponent(jobId)}` +
          `/reports/${encodeURIComponent(reportId)}`,
      },
    );
    const report = mapReport(value, jobId);
    if (report.reportId !== reportId) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned a different report.",
        502,
      );
    }
    return report;
  }

  async getReport(
    invocation: VerifiedOwnerInvocation,
    input: { readonly jobId: string; readonly reportId: string },
  ): Promise<ReportingReport> {
    await authorizeOwnerInvocation(this.options, invocation);
    const jobId = clientResourceId(input.jobId, "reporting job");
    const reportId = clientResourceId(input.reportId, "report");
    return this.getReportInternal(invocation, jobId, reportId);
  }

  async downloadReportMedia(
    invocation: VerifiedOwnerInvocation,
    input: {
      readonly jobId: string;
      readonly reportId: string;
      readonly maximumBytes?: number;
    },
  ): Promise<DownloadedReportMedia> {
    await authorizeOwnerInvocation(this.options, invocation);
    const jobId = clientResourceId(input.jobId, "reporting job");
    const reportId = clientResourceId(input.reportId, "report");
    const maximumBytes = boundedInteger(
      input.maximumBytes,
      MAX_MEDIA_BYTES,
      1,
      MAX_MEDIA_BYTES,
      "Report media byte limit",
    );
    const report = await this.getReportInternal(
      invocation,
      jobId,
      reportId,
    );
    const url = new URL(`${REPORTING_API}/${report.mediaResourceName}`);
    url.searchParams.set("alt", "media");
    const response = await this.providerRequest(
      invocation,
      "youtubereporting.media.download",
      {
        url: url.toString(),
        responseEncoding: "base64",
        maxResponseBytes: maximumBytes,
      },
    );
    const contentType = normalizedContentType(
      response.headers["content-type"],
    );
    if (
      response.body.length % 4 !== 0 ||
      !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/u.test(
        response.body,
      )
    ) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned invalid report media.",
        502,
      );
    }
    const bytes = Buffer.from(response.body, "base64");
    if (bytes.byteLength > maximumBytes) {
      throw new YouTubeAnalyticsReportingError(
        "provider_rejected",
        "YouTube returned report media above the approved limit.",
        502,
      );
    }
    return {
      jobId,
      reportId,
      byteLength: bytes.byteLength,
      sha256: createHash("sha256").update(bytes).digest("hex"),
      contentType,
      contentEncoding: "base64",
      bodyBase64: response.body,
    };
  }
}
