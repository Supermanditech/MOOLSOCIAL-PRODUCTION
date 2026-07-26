import assert from "node:assert/strict";
import test from "node:test";

import {
  mapYouTubeHttpError,
  YouTubeProviderError,
} from "./errors.js";
import {
  DEFAULT_DEV_YOUTUBE_QUOTA_CAPS,
  InMemoryYouTubeQuotaStore,
  YouTubeQuotaGovernor,
  readDevYouTubeQuotaCaps,
  type QuotaClock,
  type YouTubeQuotaReserveRequest,
  type YouTubeQuotaReserveResult,
  type YouTubeQuotaStore,
  youtubePacificDailyQuotaWindow,
} from "./quota.js";

class FakeQuotaClock implements QuotaClock {
  constructor(private current: Date) {}

  now(): Date {
    return new Date(this.current);
  }

  set(value: Date): void {
    this.current = value;
  }
}

test("uses conservative private Dev hard caps by default", () => {
  assert.deepEqual(DEFAULT_DEV_YOUTUBE_QUOTA_CAPS, {
    search: 20,
    upload: 10,
    batchStats: 500,
    analytics: 100,
    general: 2_000,
  });
  assert.deepEqual(readDevYouTubeQuotaCaps({}), {
    search: 20,
    upload: 10,
    batchStats: 500,
    analytics: 100,
    general: 2_000,
  });
});

test("allows each quota bucket to be configured independently", () => {
  assert.deepEqual(
    readDevYouTubeQuotaCaps({
      YOUTUBE_DEV_SEARCH_DAILY_CAP: "2",
      YOUTUBE_DEV_UPLOAD_DAILY_CAP: "3",
      YOUTUBE_DEV_BATCH_STATS_DAILY_CAP: "4",
      YOUTUBE_DEV_ANALYTICS_DAILY_CAP: "5",
      YOUTUBE_DEV_GENERAL_DAILY_CAP: "40",
    }),
    { search: 2, upload: 3, batchStats: 4, analytics: 5, general: 40 },
  );
});

test("environment overrides can lower but cannot raise private Dev hard caps", () => {
  assert.deepEqual(
    readDevYouTubeQuotaCaps({
      YOUTUBE_DEV_SEARCH_DAILY_CAP: "0",
      YOUTUBE_DEV_UPLOAD_DAILY_CAP: "1",
      YOUTUBE_DEV_BATCH_STATS_DAILY_CAP: "50",
      YOUTUBE_DEV_ANALYTICS_DAILY_CAP: "25",
      YOUTUBE_DEV_GENERAL_DAILY_CAP: "100",
    }),
    { search: 0, upload: 1, batchStats: 50, analytics: 25, general: 100 },
  );

  assert.throws(
    () =>
      readDevYouTubeQuotaCaps({
        YOUTUBE_DEV_ANALYTICS_DAILY_CAP: "101",
      }),
    /cannot exceed the private Dev hard cap of 100/u,
  );
  assert.throws(
    () =>
      readDevYouTubeQuotaCaps({
        YOUTUBE_DEV_SEARCH_DAILY_CAP: "21",
      }),
    /cannot exceed the private Dev hard cap of 20/u,
  );
  assert.throws(
    () =>
      readDevYouTubeQuotaCaps({
        YOUTUBE_DEV_UPLOAD_DAILY_CAP: "11",
      }),
    /cannot exceed the private Dev hard cap of 10/u,
  );
  assert.throws(
    () =>
      readDevYouTubeQuotaCaps({
        YOUTUBE_DEV_BATCH_STATS_DAILY_CAP: "501",
      }),
    /cannot exceed the private Dev hard cap of 500/u,
  );
  assert.throws(
    () =>
      readDevYouTubeQuotaCaps({
        YOUTUBE_DEV_GENERAL_DAILY_CAP: "2001",
      }),
    /cannot exceed the private Dev hard cap of 2000/u,
  );
});

test("atomic reservations cannot oversubscribe a bucket", async () => {
  const clock = new FakeQuotaClock(new Date("2026-07-23T12:00:00.000Z"));
  const governor = new YouTubeQuotaGovernor(
    new InMemoryYouTubeQuotaStore(),
    { clock, caps: { search: 5 } },
  );

  const attempts = await Promise.allSettled(
    Array.from({ length: 20 }, () => governor.reserve("search")),
  );
  assert.equal(
    attempts.filter((attempt) => attempt.status === "fulfilled").length,
    5,
  );
  assert.equal(
    attempts.filter((attempt) => attempt.status === "rejected").length,
    15,
  );

  for (const rejected of attempts.filter(
    (attempt): attempt is PromiseRejectedResult =>
      attempt.status === "rejected",
  )) {
    assert.equal(rejected.reason.code, "quota_exhausted");
    assert.equal(rejected.reason.retryable, false);
  }
});

test("all five quota buckets reserve independently", async () => {
  const governor = new YouTubeQuotaGovernor(
    new InMemoryYouTubeQuotaStore(),
    {
      caps: {
        search: 1,
        upload: 1,
        batchStats: 1,
        analytics: 1,
        general: 2,
      },
    },
  );

  await governor.reserve("search");
  await governor.reserve("upload");
  await governor.reserve("batchStats");
  await governor.reserve("analytics");
  const general = await governor.reserve("general", 2);

  assert.equal(general.remaining, 0);
  await assert.rejects(governor.reserve("batchStats"));
  await assert.rejects(
    governor.reserve("search"),
    (error: unknown) =>
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "quota_exhausted",
  );
});

test("quota windows reset at midnight Pacific rather than midnight UTC", async () => {
  const beforeReset = youtubePacificDailyQuotaWindow(
    new Date("2026-07-24T06:59:59.999Z"),
  );
  assert.deepEqual(beforeReset, {
    id: "2026-07-23",
    resetAt: "2026-07-24T07:00:00.000Z",
  });

  const atReset = youtubePacificDailyQuotaWindow(
    new Date("2026-07-24T07:00:00.000Z"),
  );
  assert.deepEqual(atReset, {
    id: "2026-07-24",
    resetAt: "2026-07-25T07:00:00.000Z",
  });
});

test("Pacific quota resets remain correct across daylight-saving changes", () => {
  assert.deepEqual(
    youtubePacificDailyQuotaWindow(
      new Date("2026-03-08T07:59:59.999Z"),
    ),
    {
      id: "2026-03-07",
      resetAt: "2026-03-08T08:00:00.000Z",
    },
  );
  assert.deepEqual(
    youtubePacificDailyQuotaWindow(
      new Date("2026-03-08T08:00:00.000Z"),
    ),
    {
      id: "2026-03-08",
      resetAt: "2026-03-09T07:00:00.000Z",
    },
  );
  assert.deepEqual(
    youtubePacificDailyQuotaWindow(
      new Date("2026-11-01T06:59:59.999Z"),
    ),
    {
      id: "2026-10-31",
      resetAt: "2026-11-01T07:00:00.000Z",
    },
  );
  assert.deepEqual(
    youtubePacificDailyQuotaWindow(
      new Date("2026-11-01T07:00:00.000Z"),
    ),
    {
      id: "2026-11-01",
      resetAt: "2026-11-02T08:00:00.000Z",
    },
  );
});

test("a new Pacific day starts a new internal guardrail window", async () => {
  const clock = new FakeQuotaClock(
    new Date("2026-07-24T06:59:59.999Z"),
  );
  const governor = new YouTubeQuotaGovernor(
    new InMemoryYouTubeQuotaStore(),
    { clock, caps: { upload: 1 } },
  );

  const first = await governor.reserve("upload");
  assert.equal(first.windowId, "2026-07-23");
  await assert.rejects(governor.reserve("upload"));

  clock.set(new Date("2026-07-24T07:00:00.000Z"));
  const second = await governor.reserve("upload");
  assert.equal(second.windowId, "2026-07-24");
  assert.equal(second.resetAt, "2026-07-25T07:00:00.000Z");
});

test("invalid caps and reservation units fail before store mutation", async () => {
  assert.throws(
    () =>
      new YouTubeQuotaGovernor(new InMemoryYouTubeQuotaStore(), {
        caps: { general: -1 },
      }),
    /non-negative safe integer/u,
  );

  const governor = new YouTubeQuotaGovernor(
    new InMemoryYouTubeQuotaStore(),
  );
  await assert.rejects(
    governor.reserve("general", 0),
    /positive safe integer/u,
  );
});

test("invalid clock data fails closed before quota-store mutation", async () => {
  let calls = 0;
  const store: YouTubeQuotaStore = {
    async reserve(
      request: YouTubeQuotaReserveRequest,
    ): Promise<YouTubeQuotaReserveResult> {
      calls += 1;
      return {
        allowed: true,
        bucket: request.bucket,
        windowId: request.windowId,
        resetAt: request.resetAt,
        used: request.units,
        remaining: request.limit - request.units,
        limit: request.limit,
      };
    },
  };
  const governor = new YouTubeQuotaGovernor(store, {
    clock: new FakeQuotaClock(new Date(Number.NaN)),
  });

  await assert.rejects(
    governor.reserve("general"),
    /Quota clock returned an invalid date/u,
  );
  assert.equal(calls, 0);
});

test("mismatched quota-store metadata fails closed", async () => {
  const store: YouTubeQuotaStore = {
    async reserve(
      request: YouTubeQuotaReserveRequest,
    ): Promise<YouTubeQuotaReserveResult> {
      return {
        allowed: true,
        bucket: request.bucket === "search" ? "general" : "search",
        windowId: request.windowId,
        resetAt: request.resetAt,
        used: request.units,
        remaining: request.limit - request.units,
        limit: request.limit,
      };
    },
  };
  const governor = new YouTubeQuotaGovernor(store, {
    clock: new FakeQuotaClock(new Date("2026-07-24T12:00:00.000Z")),
  });

  await assert.rejects(
    governor.reserve("search"),
    /quota store returned an invalid reservation result/u,
  );
});

test("local exhaustion identifies the bucket and Pacific reset", async () => {
  const governor = new YouTubeQuotaGovernor(
    new InMemoryYouTubeQuotaStore(),
    {
      clock: new FakeQuotaClock(
        new Date("2026-07-24T12:00:00.000Z"),
      ),
      caps: { batchStats: 0 },
    },
  );

  await assert.rejects(
    governor.reserve("batchStats"),
    (error: unknown) => {
      assert.ok(error instanceof YouTubeProviderError);
      assert.equal(error.code, "quota_exhausted");
      assert.equal(error.providerReason, "localDevHardCap");
      assert.equal(error.retryable, false);
      assert.match(error.message, /YouTube batchStats capacity/u);
      assert.match(error.message, /2026-07-25T07:00:00\.000Z/u);
      return true;
    },
  );
});

test("provider quotaExceeded is explicitly non-retryable", () => {
  const error = mapYouTubeHttpError(
    403,
    JSON.stringify({
      error: {
        errors: [{ reason: "quotaExceeded" }],
      },
    }),
  );

  assert.equal(error.code, "quota_exhausted");
  assert.equal(error.retryable, false);
});
