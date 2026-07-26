import { createHash } from "node:crypto";
import assert from "node:assert/strict";
import test from "node:test";

import {
  YouTubeAnalyticsReportingError,
} from "./contracts.js";
import { DisabledYouTubeReportingV1Client } from "./reporting_client.js";
import {
  enabledOptions,
  jsonResponse,
  ownerInvocation,
  QueueTransport,
} from "./test_support.js";

function apiReportType(
  id = "channel_basic_a3",
  overrides: {
    readonly systemManaged?: boolean;
    readonly deprecateTime?: string;
  } = {},
) {
  return {
    id,
    name: "Channel basic",
    systemManaged: overrides.systemManaged ?? false,
    ...(overrides.deprecateTime === undefined
      ? {}
      : { deprecateTime: overrides.deprecateTime }),
  };
}

function apiJob(
  id = "job-1",
  overrides: {
    readonly reportTypeId?: string;
    readonly name?: string;
    readonly systemManaged?: boolean;
    readonly expireTime?: string;
  } = {},
) {
  return {
    id,
    reportTypeId: overrides.reportTypeId ?? "channel_basic_a3",
    name: overrides.name ?? "Daily channel report",
    systemManaged: overrides.systemManaged ?? false,
    createTime: "2026-07-20T00:00:00Z",
    ...(overrides.expireTime === undefined
      ? { expireTime: "2026-12-31T00:00:00Z" }
      : { expireTime: overrides.expireTime }),
  };
}

function apiReport(
  id = "report-1",
  jobId = "job-1",
  downloadUrl =
    "https://youtubereporting.googleapis.com/v1/media/channels/UC_OWNER_123/jobs/job-1/reports/report-1?alt=media",
) {
  return {
    id,
    jobId,
    createTime: "2026-07-24T01:00:00Z",
    startTime: "2026-07-23T00:00:00Z",
    endTime: "2026-07-24T00:00:00Z",
    jobExpireTime: "2026-12-31T00:00:00Z",
    downloadUrl,
  };
}

test("reporting adapter is disabled by default and cannot call the provider", async () => {
  const transport = new QueueTransport([]);
  const options = enabledOptions(transport, { enabled: false });
  const client = new DisabledYouTubeReportingV1Client(options);
  await assert.rejects(
    client.listReportTypes(ownerInvocation("reporting-disabled")),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "capability_disabled",
  );
  assert.equal(transport.requests.length, 0);
  assert.equal(options.quota.reservations.length, 0);
});

test("reportTypes.list applies bounded pagination and exposes provider availability precisely", async () => {
  const transport = new QueueTransport([
    jsonResponse({
      reportTypes: [
        apiReportType(),
        apiReportType("system_managed", { systemManaged: true }),
        apiReportType("deprecated", {
          deprecateTime: "2026-07-01T00:00:00Z",
        }),
      ],
      nextPageToken: "NEXT_REPORT_TYPES",
    }),
  ]);
  const client = new DisabledYouTubeReportingV1Client(
    enabledOptions(transport),
  );
  const page = await client.listReportTypes(
    ownerInvocation("report-types"),
    {
      pageSize: 3,
      pageToken: "REPORT_TYPES_PAGE",
      includeSystemManaged: true,
    },
  );

  assert.deepEqual(
    page.items.map((item) => item.availability),
    ["available", "system-managed", "deprecated"],
  );
  assert.equal(page.nextPageToken, "NEXT_REPORT_TYPES");
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/v1/reportTypes");
  assert.equal(url.searchParams.get("pageSize"), "3");
  assert.equal(url.searchParams.get("pageToken"), "REPORT_TYPES_PAGE");
  assert.equal(url.searchParams.get("includeSystemManaged"), "true");
  assert.equal(url.searchParams.has("onBehalfOfContentOwner"), false);
});

test("jobs.create preflights an available report type and is idempotent", async () => {
  const transport = new QueueTransport([
    jsonResponse({ reportTypes: [apiReportType()] }),
    jsonResponse(apiJob()),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeReportingV1Client(options);
  const input = {
    idempotencyKey: "create-job-001",
    reportTypeId: "channel_basic_a3",
    name: "Daily channel report",
  };
  const created = await client.createJob(
    ownerInvocation("create-job-1"),
    input,
  );
  const replayed = await client.createJob(
    ownerInvocation("create-job-2"),
    input,
  );

  assert.deepEqual(replayed, created);
  assert.equal(created.status, "active");
  assert.equal(transport.requests.length, 2);
  assert.equal(transport.requests[1]!.method, "POST");
  assert.deepEqual(JSON.parse(transport.requests[1]!.body!), {
    reportTypeId: "channel_basic_a3",
    name: "Daily channel report",
  });
  assert.doesNotMatch(JSON.stringify(created), /private-access-token/u);
});

test("jobs.create rejects unavailable, system-managed and deprecated report types with typed errors", async () => {
  for (const [suffix, response] of [
    ["missing", { reportTypes: [] }],
    [
      "system",
      {
        reportTypes: [
          apiReportType("channel_basic_a3", { systemManaged: true }),
        ],
      },
    ],
    [
      "deprecated",
      {
        reportTypes: [
          apiReportType("channel_basic_a3", {
            deprecateTime: "2026-07-01T00:00:00Z",
          }),
        ],
      },
    ],
  ] as const) {
    const transport = new QueueTransport([jsonResponse(response)]);
    const client = new DisabledYouTubeReportingV1Client(
      enabledOptions(transport),
    );
    await assert.rejects(
      client.createJob(ownerInvocation(`job-${suffix}`), {
        idempotencyKey: `job-${suffix}-001`,
        reportTypeId: "channel_basic_a3",
        name: "Daily channel report",
      }),
      (error: unknown) =>
        error instanceof YouTubeAnalyticsReportingError &&
        (suffix === "missing"
          ? error.code === "eligibility_required"
          : error.code === "status_conflict"),
    );
    assert.equal(transport.requests.length, 1);
  }
});

test("jobs.list and jobs.get map active, expired and system-managed statuses", async () => {
  const transport = new QueueTransport([
    jsonResponse({
      jobs: [
        apiJob("active"),
        apiJob("expired", { expireTime: "2026-07-01T00:00:00Z" }),
        apiJob("system", { systemManaged: true }),
      ],
      nextPageToken: "NEXT_JOBS",
    }),
    jsonResponse(apiJob("active")),
  ]);
  const client = new DisabledYouTubeReportingV1Client(
    enabledOptions(transport),
  );
  const page = await client.listJobs(ownerInvocation("jobs-list"), {
    pageSize: 3,
    includeSystemManaged: true,
  });
  assert.deepEqual(
    page.items.map((job) => job.status),
    ["active", "expired", "system-managed"],
  );
  assert.equal(page.nextPageToken, "NEXT_JOBS");
  const job = await client.getJob(ownerInvocation("jobs-get"), "active");
  assert.equal(job.jobId, "active");
  assert.equal(
    new URL(transport.requests[1]!.url).pathname,
    "/v1/jobs/active",
  );
});

test("jobs.delete preflights exact status, requires confirmation and performs an idempotent delete", async () => {
  const transport = new QueueTransport([
    jsonResponse(apiJob("job-1")),
    jsonResponse({}),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeReportingV1Client(options);
  await assert.rejects(
    client.deleteJob(ownerInvocation("delete-wrong"), {
      idempotencyKey: "delete-job-000",
      jobId: "job-1",
      confirmJobId: "wrong",
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  const input = {
    idempotencyKey: "delete-job-001",
    jobId: "job-1",
    confirmJobId: "job-1",
  };
  const deleted = await client.deleteJob(
    ownerInvocation("delete-job-1"),
    input,
  );
  const replayed = await client.deleteJob(
    ownerInvocation("delete-job-2"),
    input,
  );
  assert.deepEqual(replayed, deleted);
  assert.equal(transport.requests.length, 2);
  assert.equal(transport.requests[1]!.method, "DELETE");
});

test("jobs.delete rejects expired and system-managed jobs before DELETE", async () => {
  for (const [suffix, job] of [
    ["expired", apiJob("job-1", { expireTime: "2026-07-01T00:00:00Z" })],
    ["system", apiJob("job-1", { systemManaged: true })],
  ] as const) {
    const transport = new QueueTransport([jsonResponse(job)]);
    const client = new DisabledYouTubeReportingV1Client(
      enabledOptions(transport),
    );
    await assert.rejects(
      client.deleteJob(ownerInvocation(`delete-${suffix}`), {
        idempotencyKey: `delete-${suffix}-001`,
        jobId: "job-1",
        confirmJobId: "job-1",
      }),
      (error: unknown) =>
        error instanceof YouTubeAnalyticsReportingError &&
        error.code === "status_conflict",
    );
    assert.equal(transport.requests.length, 1);
  }
});

test("reports.list uses a bounded canonical time window and exact job path", async () => {
  const transport = new QueueTransport([
    jsonResponse({
      reports: [apiReport()],
      nextPageToken: "NEXT_REPORTS",
    }),
  ]);
  const client = new DisabledYouTubeReportingV1Client(
    enabledOptions(transport),
  );
  const page = await client.listReports(ownerInvocation("reports-list"), {
    jobId: "job-1",
    pageSize: 25,
    pageToken: "REPORT_PAGE",
    window: {
      createdAfter: "2026-07-01T00:00:00+00:00",
      startTimeAtOrAfter: "2026-07-01T00:00:00Z",
      startTimeBefore: "2026-07-25T00:00:00Z",
    },
  });

  assert.equal(page.items[0]?.reportId, "report-1");
  assert.equal(
    page.items[0]?.mediaResourceName,
    "media/channels/UC_OWNER_123/jobs/job-1/reports/report-1",
  );
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.pathname, "/v1/jobs/job-1/reports");
  assert.equal(url.searchParams.get("pageSize"), "25");
  assert.equal(url.searchParams.get("pageToken"), "REPORT_PAGE");
  assert.equal(
    url.searchParams.get("createdAfter"),
    "2026-07-01T00:00:00.000Z",
  );
});

test("reports.list rejects invalid pagination and unbounded or reversed time windows without transport", async () => {
  const transport = new QueueTransport([]);
  const client = new DisabledYouTubeReportingV1Client(
    enabledOptions(transport),
  );
  await assert.rejects(
    client.listReports(ownerInvocation("reports-page"), {
      jobId: "job-1",
      pageSize: 101,
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  await assert.rejects(
    client.listReports(ownerInvocation("reports-window"), {
      jobId: "job-1",
      window: {
        startTimeAtOrAfter: "2025-01-01T00:00:00Z",
        startTimeBefore: "2026-07-25T00:00:00Z",
      },
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  assert.equal(transport.requests.length, 0);
});

test("reports.get rejects cross-job responses", async () => {
  const transport = new QueueTransport([
    jsonResponse(apiReport("report-1", "different-job")),
  ]);
  const client = new DisabledYouTubeReportingV1Client(
    enabledOptions(transport),
  );
  await assert.rejects(
    client.getReport(ownerInvocation("cross-job"), {
      jobId: "job-1",
      reportId: "report-1",
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "provider_rejected",
  );
});

test("media download derives an allowlisted provider resource, enforces bytes and returns digest plus base64", async () => {
  const payload = Buffer.from("date,views\n2026-07-24,42\n", "utf8");
  const transport = new QueueTransport([
    jsonResponse(apiReport()),
    {
      status: 200,
      headers: { "content-type": "text/csv; charset=utf-8" },
      body: payload.toString("base64"),
    },
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeReportingV1Client(options);
  const result = await client.downloadReportMedia(
    ownerInvocation("media-download"),
    {
      jobId: "job-1",
      reportId: "report-1",
      maximumBytes: 1024,
    },
  );

  assert.equal(result.byteLength, payload.byteLength);
  assert.equal(
    result.sha256,
    createHash("sha256").update(payload).digest("hex"),
  );
  assert.equal(result.contentType, "text/csv");
  assert.equal(result.bodyBase64, payload.toString("base64"));
  const mediaRequest = transport.requests[1]!;
  const mediaUrl = new URL(mediaRequest.url);
  assert.equal(mediaUrl.origin, "https://youtubereporting.googleapis.com");
  assert.equal(
    mediaUrl.pathname,
    "/v1/media/channels/UC_OWNER_123/jobs/job-1/reports/report-1",
  );
  assert.equal(mediaUrl.searchParams.get("alt"), "media");
  assert.equal(mediaRequest.responseEncoding, "base64");
  assert.equal(mediaRequest.maxResponseBytes, 1024);
});

test("arbitrary or cross-origin provider download URLs are rejected before any media relay", async () => {
  for (const maliciousUrl of [
    "https://evil.example/v1/media/report-1?alt=media",
    "https://youtubereporting.googleapis.com/v1/media/../secrets?alt=media",
    "https://youtubereporting.googleapis.com/v1/media/report-1?redirect=https://evil.example",
  ]) {
    const transport = new QueueTransport([
      jsonResponse(apiReport("report-1", "job-1", maliciousUrl)),
    ]);
    const client = new DisabledYouTubeReportingV1Client(
      enabledOptions(transport),
    );
    await assert.rejects(
      client.downloadReportMedia(
        ownerInvocation(
          `bad-media-${createHash("sha1").update(maliciousUrl).digest("hex").slice(0, 8)}`,
        ),
        { jobId: "job-1", reportId: "report-1" },
      ),
      (error: unknown) =>
        error instanceof YouTubeAnalyticsReportingError &&
        error.code === "provider_rejected",
    );
    assert.equal(transport.requests.length, 1);
  }
});

test("media relay rejects invalid media types and oversized decoded bodies", async () => {
  const invalidType = new QueueTransport([
    jsonResponse(apiReport()),
    {
      status: 200,
      headers: { "content-type": "text/html" },
      body: Buffer.from("not a report").toString("base64"),
    },
  ]);
  await assert.rejects(
    new DisabledYouTubeReportingV1Client(
      enabledOptions(invalidType),
    ).downloadReportMedia(ownerInvocation("media-type"), {
      jobId: "job-1",
      reportId: "report-1",
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "provider_rejected",
  );

  const oversized = new QueueTransport([
    jsonResponse(apiReport()),
    {
      status: 200,
      headers: { "content-type": "text/csv" },
      body: Buffer.alloc(11).toString("base64"),
    },
  ]);
  await assert.rejects(
    new DisabledYouTubeReportingV1Client(
      enabledOptions(oversized),
    ).downloadReportMedia(ownerInvocation("media-size"), {
      jobId: "job-1",
      reportId: "report-1",
      maximumBytes: 10,
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "provider_rejected",
  );
});

test("provider 403 eligibility errors remain typed and never expose provider credentials", async () => {
  const transport = new QueueTransport([
    jsonResponse(
      {
        error: {
          errors: [{ reason: "reportingNotEnabled" }],
          message: "private-access-token",
        },
      },
      403,
    ),
  ]);
  const client = new DisabledYouTubeReportingV1Client(
    enabledOptions(transport),
  );
  await assert.rejects(
    client.listJobs(ownerInvocation("reporting-eligibility")),
    (error: unknown) => {
      assert.ok(error instanceof YouTubeAnalyticsReportingError);
      assert.equal(error.code, "eligibility_required");
      assert.doesNotMatch(error.message, /private-access-token/u);
      return true;
    },
  );
});
