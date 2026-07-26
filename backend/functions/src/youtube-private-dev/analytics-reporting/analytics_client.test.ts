import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "../../youtube/errors.js";
import { DisabledYouTubeAnalyticsV2Client } from "./analytics_client.js";
import {
  YOUTUBE_ANALYTICS_READ_SCOPE,
  YouTubeAnalyticsReportingError,
} from "./contracts.js";
import {
  enabledOptions,
  jsonResponse,
  ownerInvocation,
  QueueTransport,
} from "./test_support.js";

function apiGroup(
  id = "group-1",
  title = "Core videos",
  itemType = "youtube#video",
) {
  return {
    id,
    kind: "youtube#group",
    snippet: {
      title,
      publishedAt: "2026-07-01T00:00:00Z",
    },
    contentDetails: { itemCount: "2", itemType },
  };
}

function apiGroupItem(
  id = "group-item-1",
  groupId = "group-1",
  resourceId = "video000001",
) {
  return {
    id,
    kind: "youtube#groupItem",
    groupId,
    resource: { kind: "youtube#video", id: resourceId },
  };
}

test("analytics adapter is disabled by default and makes no provider or quota call", async () => {
  const transport = new QueueTransport([]);
  const options = enabledOptions(transport, { enabled: false });
  const client = new DisabledYouTubeAnalyticsV2Client(options);

  await assert.rejects(
    client.listGroups(ownerInvocation("disabled")),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "capability_disabled",
  );
  assert.equal(transport.requests.length, 0);
  assert.equal(options.quota.reservations.length, 0);
  assert.equal(options.replayProtection.consumed.length, 0);
});

test("analytics boundary enforces verified auth, active owner, App Check, replay protection and owner scope", async () => {
  const transport = new QueueTransport([]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  const failures = [
    ownerInvocation("auth", {
      auth: { verified: false, userId: "owner-user" },
    }),
    ownerInvocation("owner", {
      owner: {
        userId: "different-user",
        channelId: "UC_OWNER_123",
        status: "ACTIVE",
        grantedScopes: [YOUTUBE_ANALYTICS_READ_SCOPE],
      },
    }),
    ownerInvocation("status", {
      owner: {
        userId: "owner-user",
        channelId: "UC_OWNER_123",
        status: "REVOKED",
        grantedScopes: [YOUTUBE_ANALYTICS_READ_SCOPE],
      },
    }),
    ownerInvocation("appcheck", {
      appCheck: {
        verified: false,
        replayProtected: true,
        replayId: "appcheck",
      },
    }),
    ownerInvocation("scope", {
      owner: {
        userId: "owner-user",
        channelId: "UC_OWNER_123",
        status: "ACTIVE",
        grantedScopes: [],
      },
    }),
  ];
  const expected = [
    "authentication_required",
    "authentication_required",
    "status_conflict",
    "app_check_required",
    "scope_required",
  ];
  for (let index = 0; index < failures.length; index += 1) {
    await assert.rejects(
      client.listGroups(failures[index]!),
      (error: unknown) =>
        error instanceof YouTubeAnalyticsReportingError &&
        error.code === expected[index],
    );
  }
  assert.equal(transport.requests.length, 0);
  assert.equal(options.quota.reservations.length, 0);
});

test("consumed App Check replay identifiers are rejected before a second provider call", async () => {
  const transport = new QueueTransport([
    jsonResponse({ items: [], nextPageToken: undefined }),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  const invocation = ownerInvocation("same-replay");

  await client.listGroups(invocation);
  await assert.rejects(
    client.listGroups(invocation),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "replay_detected",
  );
  assert.equal(transport.requests.length, 1);
});

test("groups.list is owner-bound, paginated and rejects mixed id plus page token", async () => {
  const transport = new QueueTransport([
    jsonResponse({ items: [apiGroup()], nextPageToken: "NEXT_PAGE" }),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  const page = await client.listGroups(ownerInvocation("groups-list"), {
    pageToken: "PAGE_1",
  });

  assert.equal(page.items[0]?.groupId, "group-1");
  assert.equal(page.nextPageToken, "NEXT_PAGE");
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.origin, "https://youtubeanalytics.googleapis.com");
  assert.equal(url.pathname, "/v2/groups");
  assert.equal(url.searchParams.get("mine"), "true");
  assert.equal(url.searchParams.get("pageToken"), "PAGE_1");
  assert.equal(
    transport.requests[0]!.headers?.authorization,
    "Bearer private-access-token",
  );

  await assert.rejects(
    client.listGroups(ownerInvocation("groups-mixed"), {
      groupId: "group-1",
      pageToken: "PAGE_2",
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  assert.equal(transport.requests.length, 1);
});

test("groups.insert is idempotent and never returns or logs the access token", async () => {
  const transport = new QueueTransport([
    jsonResponse(apiGroup("group-created", "Campaign videos")),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  const input = {
    idempotencyKey: "create-group-001",
    title: "Campaign videos",
    itemType: "youtube#video" as const,
  };
  const first = await client.createGroup(
    ownerInvocation("create-group-1"),
    input,
  );
  const replayed = await client.createGroup(
    ownerInvocation("create-group-2"),
    input,
  );

  assert.deepEqual(replayed, first);
  assert.equal(transport.requests.length, 1);
  assert.equal(transport.requests[0]!.method, "POST");
  assert.deepEqual(JSON.parse(transport.requests[0]!.body!), {
    kind: "youtube#group",
    snippet: { title: "Campaign videos" },
    contentDetails: { itemType: "youtube#video" },
  });
  assert.doesNotMatch(JSON.stringify(first), /private-access-token/u);
});

test("an idempotency key cannot be rebound to a different group mutation", async () => {
  const transport = new QueueTransport([
    jsonResponse(apiGroup("group-created", "First title")),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  await client.createGroup(ownerInvocation("idempotent-1"), {
    idempotencyKey: "same-group-key",
    title: "First title",
    itemType: "youtube#video",
  });
  await assert.rejects(
    client.createGroup(ownerInvocation("idempotent-2"), {
      idempotencyKey: "same-group-key",
      title: "Different title",
      itemType: "youtube#video",
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "idempotency_conflict",
  );
  assert.equal(transport.requests.length, 1);
});

test("groups.update and groups.delete bind exact IDs and require destructive confirmation", async () => {
  const transport = new QueueTransport([
    jsonResponse(apiGroup("group-1", "Updated")),
    jsonResponse({}),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  const updated = await client.updateGroup(ownerInvocation("update-group"), {
    idempotencyKey: "update-group-001",
    groupId: "group-1",
    title: "Updated",
  });
  assert.equal(updated.title, "Updated");

  await assert.rejects(
    client.deleteGroup(ownerInvocation("delete-wrong"), {
      idempotencyKey: "delete-group-000",
      groupId: "group-1",
      confirmGroupId: "other",
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  const deleted = await client.deleteGroup(ownerInvocation("delete-group"), {
    idempotencyKey: "delete-group-001",
    groupId: "group-1",
    confirmGroupId: "group-1",
  });
  assert.deepEqual(deleted, { deleted: true, groupId: "group-1" });
  assert.equal(transport.requests[1]!.method, "DELETE");
  assert.equal(
    new URL(transport.requests[1]!.url).searchParams.get("id"),
    "group-1",
  );
});

test("groupItems list, insert and delete use only structured ordinary-owner resources", async () => {
  const transport = new QueueTransport([
    jsonResponse({ items: [apiGroupItem()] }),
    jsonResponse(apiGroupItem("group-item-2", "group-1", "video000002")),
    jsonResponse({}),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  const listed = await client.listGroupItems(
    ownerInvocation("items-list"),
    "group-1",
  );
  assert.equal(listed.items.length, 1);
  const inserted = await client.insertGroupItem(
    ownerInvocation("items-insert"),
    {
      idempotencyKey: "insert-item-001",
      groupId: "group-1",
      resourceType: "youtube#video",
      resourceId: "video000002",
    },
  );
  assert.equal(inserted.resourceId, "video000002");
  assert.deepEqual(JSON.parse(transport.requests[1]!.body!), {
    kind: "youtube#groupItem",
    groupId: "group-1",
    resource: { kind: "youtube#video", id: "video000002" },
  });
  const deleted = await client.deleteGroupItem(
    ownerInvocation("items-delete"),
    {
      idempotencyKey: "delete-item-001",
      groupItemId: "group-item-2",
      confirmGroupItemId: "group-item-2",
    },
  );
  assert.equal(deleted.deleted, true);
});

test("partner asset group items produce an eligibility error rather than a false ordinary-user capability", async () => {
  const transport = new QueueTransport([
    jsonResponse({
      items: [
        {
          ...apiGroupItem(),
          resource: { kind: "youtubePartner#asset", id: "asset-1" },
        },
      ],
    }),
  ]);
  const client = new DisabledYouTubeAnalyticsV2Client(
    enabledOptions(transport),
  );
  await assert.rejects(
    client.listGroupItems(ownerInvocation("partner-item"), "group-1"),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "eligibility_required",
  );
});

test("reports.query accepts only bounded allowlisted metrics, dimensions, filters and sorting", async () => {
  const rows = Array.from({ length: 2 }, (_, index) => [
    `video00000${index + 1}`,
    100 + index,
    10 + index,
  ]);
  const transport = new QueueTransport([
    jsonResponse({
      columnHeaders: [
        { name: "video", columnType: "DIMENSION" },
        { name: "views", columnType: "METRIC" },
        { name: "likes", columnType: "METRIC" },
      ],
      rows,
    }),
  ]);
  const options = enabledOptions(transport);
  const client = new DisabledYouTubeAnalyticsV2Client(options);
  const result = await client.queryReport(ownerInvocation("analytics-query"), {
    startDate: "2026-07-01",
    endDate: "2026-07-25",
    metrics: ["views", "likes"],
    dimensions: ["video"],
    videoId: "video000001",
    sort: { field: "views", direction: "descending" },
    maxResults: 2,
    startIndex: 3,
  });

  assert.equal(result.rows[0]?.metrics.views, 100);
  assert.equal(result.continuationStartIndex, 5);
  assert.equal(result.channelId, "UC_OWNER_123");
  const url = new URL(transport.requests[0]!.url);
  assert.equal(url.searchParams.get("ids"), "channel==MINE");
  assert.equal(url.searchParams.get("metrics"), "views,likes");
  assert.equal(url.searchParams.get("dimensions"), "video");
  assert.equal(url.searchParams.get("filters"), "video==video000001");
  assert.equal(url.searchParams.get("sort"), "-views");
  assert.equal(url.searchParams.has("onBehalfOfContentOwner"), false);
});

test("reports.query rejects arbitrary fields, oversized ranges and invalid pagination before transport", async () => {
  const transport = new QueueTransport([]);
  const client = new DisabledYouTubeAnalyticsV2Client(
    enabledOptions(transport),
  );
  await assert.rejects(
    client.queryReport(ownerInvocation("bad-metric"), {
      startDate: "2026-07-01",
      endDate: "2026-07-25",
      metrics: ["estimatedRevenue" as "views"],
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  await assert.rejects(
    client.queryReport(ownerInvocation("bad-range"), {
      startDate: "2025-01-01",
      endDate: "2026-07-25",
      metrics: ["views"],
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  await assert.rejects(
    client.queryReport(ownerInvocation("bad-page"), {
      startDate: "2026-07-01",
      endDate: "2026-07-25",
      metrics: ["views"],
      maxResults: 201,
    }),
    (error: unknown) =>
      error instanceof YouTubeAnalyticsReportingError &&
      error.code === "bad_request",
  );
  assert.equal(transport.requests.length, 0);
});

test("provider eligibility failures are typed and provider credentials never enter the error", async () => {
  const transport = new QueueTransport([
    jsonResponse(
      {
        error: {
          errors: [{ reason: "insufficientPermissions" }],
          message: "private-access-token",
        },
      },
      403,
    ),
  ]);
  const client = new DisabledYouTubeAnalyticsV2Client(
    enabledOptions(transport),
  );
  await assert.rejects(
    client.listGroups(ownerInvocation("eligibility")),
    (error: unknown) => {
      assert.ok(error instanceof YouTubeAnalyticsReportingError);
      assert.equal(error.code, "eligibility_required");
      assert.doesNotMatch(error.message, /private-access-token/u);
      return true;
    },
  );
});

test("generic provider failures retain the shared YouTube error mapping", async () => {
  const transport = new QueueTransport([
    jsonResponse({ error: { errors: [{ reason: "quotaExceeded" }] } }, 403),
  ]);
  const client = new DisabledYouTubeAnalyticsV2Client(
    enabledOptions(transport),
  );
  await assert.rejects(
    client.listGroups(ownerInvocation("quota")),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "quota_exhausted",
  );
});
