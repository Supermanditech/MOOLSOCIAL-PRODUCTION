import assert from "node:assert/strict";
import test from "node:test";

import {
  type VerifiedOwnerInvocation,
  YouTubeAnalyticsReportingError,
} from "./contracts.js";
import {
  ANALYTICS_REPORTING_OPERATIONS,
  type AnalyticsReportingOperation,
  type AnalyticsReportingOperationClients,
  RouterConsumedAppCheckReplay,
  dispatchAnalyticsReportingOperation,
  isAnalyticsReportingOperation,
} from "./registration.js";

const invocation: VerifiedOwnerInvocation = {
  principal: "founder-owner",
  requestId: "request-analytics-registration",
  accessToken: "access-token",
  auth: {
    verified: true,
    userId: "founder-owner",
  },
  appCheck: {
    verified: true,
    replayProtected: true,
    replayId: "request-analytics-registration",
  },
  owner: {
    userId: "founder-owner",
    channelId: "UC1234567890",
    status: "ACTIVE",
    grantedScopes: [
      "https://www.googleapis.com/auth/yt-analytics.readonly",
    ],
  },
};

interface RecordedCall {
  readonly method: string;
  readonly args: readonly unknown[];
}

function recordingClients(calls: RecordedCall[]): AnalyticsReportingOperationClients {
  const call = (method: string) => async (...args: readonly unknown[]) => {
    calls.push({ method, args });
    return { method };
  };
  return {
    analytics: {
      listGroups: call("analytics.listGroups"),
      createGroup: call("analytics.createGroup"),
      updateGroup: call("analytics.updateGroup"),
      deleteGroup: call("analytics.deleteGroup"),
      listGroupItems: call("analytics.listGroupItems"),
      insertGroupItem: call("analytics.insertGroupItem"),
      deleteGroupItem: call("analytics.deleteGroupItem"),
      queryReport: call("analytics.queryReport"),
    },
    reporting: {
      listReportTypes: call("reporting.listReportTypes"),
      createJob: call("reporting.createJob"),
      listJobs: call("reporting.listJobs"),
      getJob: call("reporting.getJob"),
      deleteJob: call("reporting.deleteJob"),
      listReports: call("reporting.listReports"),
      getReport: call("reporting.getReport"),
      downloadReportMedia: call("reporting.downloadReportMedia"),
    },
  } as unknown as AnalyticsReportingOperationClients;
}

const routingCases: readonly {
  readonly operation: AnalyticsReportingOperation;
  readonly body: Readonly<Record<string, unknown>>;
  readonly method: string;
  readonly argumentsAfterInvocation: readonly unknown[];
}[] = [
  {
    operation: "analyticsV2ListGroups",
    body: { groupId: "group_1" },
    method: "analytics.listGroups",
    argumentsAfterInvocation: [{ groupId: "group_1" }],
  },
  {
    operation: "analyticsV2CreateGroup",
    body: {
      idempotencyKey: "create-group-0001",
      title: "Priority videos",
      itemType: "youtube#video",
    },
    method: "analytics.createGroup",
    argumentsAfterInvocation: [{
      idempotencyKey: "create-group-0001",
      title: "Priority videos",
      itemType: "youtube#video",
    }],
  },
  {
    operation: "analyticsV2UpdateGroup",
    body: {
      idempotencyKey: "update-group-0001",
      groupId: "group_1",
      title: "Updated videos",
    },
    method: "analytics.updateGroup",
    argumentsAfterInvocation: [{
      idempotencyKey: "update-group-0001",
      groupId: "group_1",
      title: "Updated videos",
    }],
  },
  {
    operation: "analyticsV2DeleteGroup",
    body: {
      idempotencyKey: "delete-group-0001",
      groupId: "group_1",
      confirmGroupId: "group_1",
    },
    method: "analytics.deleteGroup",
    argumentsAfterInvocation: [{
      idempotencyKey: "delete-group-0001",
      groupId: "group_1",
      confirmGroupId: "group_1",
    }],
  },
  {
    operation: "analyticsV2ListGroupItems",
    body: { groupId: "group_1" },
    method: "analytics.listGroupItems",
    argumentsAfterInvocation: ["group_1"],
  },
  {
    operation: "analyticsV2InsertGroupItem",
    body: {
      idempotencyKey: "insert-group-item-0001",
      groupId: "group_1",
      resourceType: "youtube#playlist",
      resourceId: "playlist_1",
    },
    method: "analytics.insertGroupItem",
    argumentsAfterInvocation: [{
      idempotencyKey: "insert-group-item-0001",
      groupId: "group_1",
      resourceType: "youtube#playlist",
      resourceId: "playlist_1",
    }],
  },
  {
    operation: "analyticsV2DeleteGroupItem",
    body: {
      idempotencyKey: "delete-group-item-0001",
      groupItemId: "group_item_1",
      confirmGroupItemId: "group_item_1",
    },
    method: "analytics.deleteGroupItem",
    argumentsAfterInvocation: [{
      idempotencyKey: "delete-group-item-0001",
      groupItemId: "group_item_1",
      confirmGroupItemId: "group_item_1",
    }],
  },
  {
    operation: "analyticsV2QueryReport",
    body: {
      startDate: "2026-07-01",
      endDate: "2026-07-25",
      metrics: ["views", "likes"],
      dimensions: ["day"],
      videoId: "video_12345",
      sort: { field: "views", direction: "descending" },
      maxResults: 100,
      startIndex: 1,
    },
    method: "analytics.queryReport",
    argumentsAfterInvocation: [{
      startDate: "2026-07-01",
      endDate: "2026-07-25",
      metrics: ["views", "likes"],
      dimensions: ["day"],
      videoId: "video_12345",
      sort: { field: "views", direction: "descending" },
      maxResults: 100,
      startIndex: 1,
    }],
  },
  {
    operation: "reportingV1ListReportTypes",
    body: {
      pageToken: "next_1",
      pageSize: 25,
      includeSystemManaged: true,
    },
    method: "reporting.listReportTypes",
    argumentsAfterInvocation: [{
      pageToken: "next_1",
      pageSize: 25,
      includeSystemManaged: true,
    }],
  },
  {
    operation: "reportingV1CreateJob",
    body: {
      idempotencyKey: "create-report-job-0001",
      reportTypeId: "type_1",
      name: "Daily channel report",
    },
    method: "reporting.createJob",
    argumentsAfterInvocation: [{
      idempotencyKey: "create-report-job-0001",
      reportTypeId: "type_1",
      name: "Daily channel report",
    }],
  },
  {
    operation: "reportingV1ListJobs",
    body: { pageSize: 50, includeSystemManaged: false },
    method: "reporting.listJobs",
    argumentsAfterInvocation: [{
      pageSize: 50,
      includeSystemManaged: false,
    }],
  },
  {
    operation: "reportingV1GetJob",
    body: { jobId: "job_1" },
    method: "reporting.getJob",
    argumentsAfterInvocation: ["job_1"],
  },
  {
    operation: "reportingV1DeleteJob",
    body: {
      idempotencyKey: "delete-report-job-0001",
      jobId: "job_1",
      confirmJobId: "job_1",
    },
    method: "reporting.deleteJob",
    argumentsAfterInvocation: [{
      idempotencyKey: "delete-report-job-0001",
      jobId: "job_1",
      confirmJobId: "job_1",
    }],
  },
  {
    operation: "reportingV1ListReports",
    body: {
      jobId: "job_1",
      pageToken: "next_2",
      pageSize: 20,
      window: {
        createdAfter: "2026-07-01T00:00:00.000Z",
        startTimeAtOrAfter: "2026-07-01T00:00:00.000Z",
        startTimeBefore: "2026-07-25T00:00:00.000Z",
      },
    },
    method: "reporting.listReports",
    argumentsAfterInvocation: [{
      jobId: "job_1",
      pageToken: "next_2",
      pageSize: 20,
      window: {
        createdAfter: "2026-07-01T00:00:00.000Z",
        startTimeAtOrAfter: "2026-07-01T00:00:00.000Z",
        startTimeBefore: "2026-07-25T00:00:00.000Z",
      },
    }],
  },
  {
    operation: "reportingV1GetReport",
    body: { jobId: "job_1", reportId: "report_1" },
    method: "reporting.getReport",
    argumentsAfterInvocation: [{
      jobId: "job_1",
      reportId: "report_1",
    }],
  },
  {
    operation: "reportingV1DownloadReportMedia",
    body: {
      jobId: "job_1",
      reportId: "report_1",
      maximumBytes: 8 * 1024 * 1024,
    },
    method: "reporting.downloadReportMedia",
    argumentsAfterInvocation: [{
      jobId: "job_1",
      reportId: "report_1",
      maximumBytes: 8 * 1024 * 1024,
    }],
  },
];

test("the registration inventory matches all 16 Flutter operations", () => {
  assert.equal(ANALYTICS_REPORTING_OPERATIONS.length, 16);
  assert.deepEqual(
    ANALYTICS_REPORTING_OPERATIONS,
    routingCases.map((value) => value.operation),
  );
  for (const operation of ANALYTICS_REPORTING_OPERATIONS) {
    assert.equal(isAnalyticsReportingOperation(operation), true, operation);
  }
  assert.equal(isAnalyticsReportingOperation("ownerAnalyticsPreset"), false);
});

test("all 16 operations dispatch their exact bounded Flutter request shape", async () => {
  for (const value of routingCases) {
    const calls: RecordedCall[] = [];
    const result = await dispatchAnalyticsReportingOperation(
      value.operation,
      { operation: value.operation, ...value.body },
      invocation,
      recordingClients(calls),
    );
    assert.deepEqual(result, { method: value.method }, value.operation);
    assert.equal(calls.length, 1, value.operation);
    assert.equal(calls[0]?.method, value.method, value.operation);
    assert.equal(calls[0]?.args[0], invocation, value.operation);
    assert.deepEqual(
      calls[0]?.args.slice(1),
      value.argumentsAfterInvocation,
      value.operation,
    );
  }
});

test("registration rejects arbitrary URLs, content-owner fields and malformed nested inputs", async () => {
  for (const body of [
    {
      operation: "reportingV1GetReport",
      jobId: "job_1",
      reportId: "report_1",
      downloadUrl: "https://attacker.invalid/report",
    },
    {
      operation: "analyticsV2QueryReport",
      startDate: "2026-07-01",
      endDate: "2026-07-25",
      metrics: ["views"],
      onBehalfOfContentOwner: "owner",
    },
    {
      operation: "reportingV1ListReports",
      jobId: "job_1",
      window: {
        createdAfter: "2026-07-01T00:00:00.000Z",
        url: "https://attacker.invalid/report",
      },
    },
  ] as const) {
    await assert.rejects(
      dispatchAnalyticsReportingOperation(
        body.operation,
        body,
        invocation,
        recordingClients([]),
      ),
      (error: unknown) =>
        error instanceof YouTubeAnalyticsReportingError &&
        error.code === "bad_request",
    );
  }
});

test("the router-consumed App Check bridge permits only the exact handoff once", async () => {
  const replay = new RouterConsumedAppCheckReplay(
    "founder-owner",
    "request-1",
  );
  assert.equal(await replay.consume("another-owner:request-1"), false);
  assert.equal(await replay.consume("founder-owner:request-1"), true);
  assert.equal(await replay.consume("founder-owner:request-1"), false);
});
