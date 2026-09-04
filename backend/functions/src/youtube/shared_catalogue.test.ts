import assert from "node:assert/strict";
import test from "node:test";

import type {
  ProviderDocument,
  ProviderDocumentDatabase,
  ProviderDocumentTransaction,
} from "./firestore_store.js";
import { FirestoreYouTubeQuotaStore } from "./firestore_store.js";
import { YouTubeQuotaGovernorAdapter } from "./adapters.js";
import { YouTubeQuotaGovernor } from "./quota.js";
import { YouTubeProviderError } from "./errors.js";
import {
  FirestoreSharedShortsCatalogueStore,
  SharedShortsCatalogueCoordinator,
  type SharedShortsCatalogueOutcome,
  type SharedShortsCatalogueRefreshLease,
  type SharedShortsCatalogueSnapshot,
  type SharedShortsCatalogueStore,
  isEligibleSharedShort,
  sharedShortsCatalogueContract,
} from "./shared_catalogue.js";
import type { YouTubeVideoSummary } from "./types.js";

const NOW = new Date("2026-08-11T10:00:00.000Z");

function short(
  videoId: string,
  overrides: Partial<YouTubeVideoSummary> = {},
): YouTubeVideoSummary {
  return {
    videoId,
    title: `India update #Shorts ${videoId}`,
    channelId: "UC1234567890",
    channelTitle: "Verified newsroom",
    publishedAt: "2026-08-11T09:00:00.000Z",
    description: "Latest public update",
    thumbnail: { url: `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg` },
    duration: "PT45S",
    embeddable: true,
    privacyStatus: "public",
    uploadStatus: "processed",
    availability: {
      state: "available",
      regionCode: "IN",
      broadcastState: "none",
      syndication: "search_filter_confirmed",
    },
    ...overrides,
  };
}

function snapshot(
  items: readonly YouTubeVideoSummary[],
  expiresAt: string,
): SharedShortsCatalogueSnapshot {
  return {
    schemaVersion: 1,
    items,
    refreshedAt: "2026-08-11T09:00:00.000Z",
    expiresAt,
  };
}

class MemoryCatalogueStore implements SharedShortsCatalogueStore {
  constructor(
    public current: SharedShortsCatalogueSnapshot | null = null,
    public acquire = true,
  ) {}

  readonly outcomes: SharedShortsCatalogueOutcome[] = [];
  readonly abandoned: string[] = [];
  readonly committed: SharedShortsCatalogueSnapshot[] = [];

  async read(): Promise<SharedShortsCatalogueSnapshot | null> {
    return this.current;
  }

  async tryAcquireRefresh(
    _lease: SharedShortsCatalogueRefreshLease,
  ): Promise<boolean> {
    return this.acquire;
  }

  async commitRefresh(
    _leaseId: string,
    next: SharedShortsCatalogueSnapshot,
  ): Promise<void> {
    this.current = next;
    this.committed.push(next);
  }

  async abandonRefresh(leaseId: string): Promise<void> {
    this.abandoned.push(leaseId);
  }

  async recordOutcome(outcome: SharedShortsCatalogueOutcome): Promise<void> {
    this.outcomes.push(outcome);
  }
}

class MemoryDocumentDatabase implements ProviderDocumentDatabase {
  readonly documents = new Map<string, Readonly<Record<string, unknown>>>();
  failTransactionSetPrefix: string | null = null;
  private transactionTail: Promise<void> = Promise.resolve();

  async get(
    path: string,
  ): Promise<Readonly<Record<string, unknown>> | undefined> {
    return this.documents.get(path);
  }

  async set(
    path: string,
    data: Readonly<Record<string, unknown>>,
  ): Promise<void> {
    this.documents.set(path, structuredClone(data));
  }

  async delete(path: string): Promise<void> {
    this.documents.delete(path);
  }

  async queryByField(
    collectionPath: string,
    field: string,
    value: string,
  ): Promise<readonly ProviderDocument[]> {
    return [...this.documents.entries()]
      .filter(
        ([path, data]) =>
          path.startsWith(`${collectionPath}/`) && data[field] === value,
      )
      .map(([path, data]) => ({ path, data }));
  }

  async deleteMany(paths: readonly string[]): Promise<void> {
    paths.forEach((path) => this.documents.delete(path));
  }

  async runTransaction<T>(
    operation: (transaction: ProviderDocumentTransaction) => Promise<T>,
  ): Promise<T> {
    let release!: () => void;
    const previous = this.transactionTail;
    this.transactionTail = new Promise<void>((resolve) => {
      release = resolve;
    });
    await previous;
    try {
      const candidate = new Map(
        [...this.documents.entries()].map(([path, data]) => [
          path,
          structuredClone(data),
        ]),
      );
      let writeQueued = false;
      const transaction: ProviderDocumentTransaction = {
        get: async (path) => {
          if (writeQueued) {
            throw new Error("Firestore transaction read occurred after write");
          }
          return candidate.get(path);
        },
        create: (path, data) => {
          writeQueued = true;
          if (candidate.has(path)) throw new Error("already exists");
          candidate.set(path, structuredClone(data));
        },
        set: (path, data) => {
          writeQueued = true;
          if (path.startsWith(this.failTransactionSetPrefix ?? "\u0000")) {
            throw new Error("simulated transaction write failure");
          }
          candidate.set(path, structuredClone(data));
        },
        delete: (path) => {
          writeQueued = true;
          candidate.delete(path);
        },
      };
      const result = await operation(transaction);
      this.documents.clear();
      candidate.forEach((data, path) => this.documents.set(path, data));
      return result;
    } finally {
      release();
    }
  }
}

test("fresh shared catalogue is reused without provider search", async () => {
  const store = new MemoryCatalogueStore(
    snapshot([short("fresh")], "2026-08-11T10:10:00.000Z"),
  );
  let loads = 0;
  const coordinator = new SharedShortsCatalogueCoordinator({
    store,
    now: () => NOW,
    loadPage: async () => {
      loads += 1;
      return { items: [] };
    },
  });

  const result = await coordinator.load("request-fresh");

  assert.equal(result.source, "cache");
  assert.equal(result.items[0]?.videoId, "fresh");
  assert.equal(loads, 0);
  assert.deepEqual(store.outcomes, ["cache_hit"]);
});

test("one shared refresh filters eligibility, deduplicates and stops at 20", async () => {
  const store = new MemoryCatalogueStore();
  const pages = [
    {
      items: [
        ...Array.from({ length: 12 }, (_, index) => short(`a-${index}`)),
        short("private", { privacyStatus: "private" }),
        short("too-long", { duration: "PT3M1S" }),
      ],
      nextPageToken: "page-2",
    },
    {
      items: [
        short("a-0"),
        ...Array.from({ length: 12 }, (_, index) => short(`b-${index}`)),
      ],
      nextPageToken: "page-3",
    },
  ];
  let loads = 0;
  const coordinator = new SharedShortsCatalogueCoordinator({
    store,
    now: () => NOW,
    loadPage: async (_requestId, pageToken) => {
      assert.equal(pageToken, loads === 0 ? undefined : "page-2");
      return pages[loads++]!;
    },
  });

  const result = await coordinator.load("request-refresh");

  assert.equal(result.source, "refresh");
  assert.equal(result.items.length, sharedShortsCatalogueContract.targetItems);
  assert.equal(new Set(result.items.map((item) => item.videoId)).size, 20);
  assert.equal(loads, 2);
  assert.equal(store.committed.length, 1);
  assert.deepEqual(store.outcomes, ["refresh_success"]);
});

test("lease contention and provider error use only bounded stale content", async () => {
  const stale = snapshot(
    [short("stale")],
    "2026-08-11T09:30:00.000Z",
  );
  const contended = new MemoryCatalogueStore(stale, false);
  let contendedLoads = 0;
  const contendedCoordinator = new SharedShortsCatalogueCoordinator({
    store: contended,
    now: () => NOW,
    loadPage: async () => {
      contendedLoads += 1;
      return { items: [] };
    },
  });
  const contendedResult = await contendedCoordinator.load("request-contended");
  assert.equal(contendedResult.source, "stale");
  assert.equal(contendedLoads, 0);
  assert.deepEqual(contended.outcomes, [
    "lease_contended",
    "stale_fallback",
  ]);

  const failed = new MemoryCatalogueStore(stale, true);
  const failedCoordinator = new SharedShortsCatalogueCoordinator({
    store: failed,
    now: () => NOW,
    loadPage: async () => {
      throw new Error("provider unavailable");
    },
  });
  const failedResult = await failedCoordinator.load("request-failed");
  assert.equal(failedResult.source, "stale");
  assert.deepEqual(failed.abandoned, ["request-failed"]);
  assert.deepEqual(failed.outcomes, ["refresh_error", "stale_fallback"]);
});

test("expired fallback fails truthfully when refresh cannot start", async () => {
  const store = new MemoryCatalogueStore(
    snapshot([short("expired")], "2026-08-11T03:59:59.000Z"),
    false,
  );
  const coordinator = new SharedShortsCatalogueCoordinator({
    store,
    now: () => NOW,
    loadPage: async () => ({ items: [] }),
  });

  await assert.rejects(
    coordinator.load("request-expired"),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_unavailable" &&
      error.retryable,
  );
});

test("expired refresh reports only its safe failing phase", async () => {
  const store = new MemoryCatalogueStore(
    snapshot([short("expired")], "2026-08-11T03:59:59.000Z"),
    true,
  );
  const coordinator = new SharedShortsCatalogueCoordinator({
    store,
    now: () => NOW,
    loadPage: async () => {
      throw new Error("private transport detail");
    },
  });

  await assert.rejects(
    coordinator.load("request-expired-refresh"),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.code === "provider_unavailable" &&
      error.providerReason === "sharedShortsCatalogue.load_page.error" &&
      !error.message.includes("private transport detail"),
  );
});

test("commit refresh reports a whitelisted persistence code", async () => {
  const store = new MemoryCatalogueStore();
  store.commitRefresh = async () => {
    throw Object.assign(new Error("private persistence detail"), { code: 3 });
  };
  const coordinator = new SharedShortsCatalogueCoordinator({
    store,
    now: () => NOW,
    loadPage: async () => ({ items: [short("commit-failure")] }),
  });

  await assert.rejects(
    coordinator.load("request-commit-failure"),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.providerReason === "sharedShortsCatalogue.commit_refresh.code_3" &&
      !error.message.includes("private persistence detail"),
  );
});

test("Firestore store enforces a cross-instance lease and durable outcomes", async () => {
  const database = new MemoryDocumentDatabase();
  const store = new FirestoreSharedShortsCatalogueStore(database);
  const lease: SharedShortsCatalogueRefreshLease = {
    leaseId: "lease-1",
    acquiredAt: NOW.toISOString(),
    expiresAt: "2026-08-11T10:02:00.000Z",
  };
  assert.equal(await store.tryAcquireRefresh(lease), true);
  assert.equal(
    await store.tryAcquireRefresh({ ...lease, leaseId: "lease-2" }),
    false,
  );
  const next = snapshot([short("stored")], "2026-08-11T10:30:00.000Z");
  await assert.rejects(store.commitRefresh("lease-2", next));
  await store.commitRefresh("lease-1", next);
  assert.deepEqual(await store.read(), next);

  await store.recordOutcome("cache_hit", NOW.toISOString());
  await store.recordOutcome("cache_hit", NOW.toISOString());
  const measurement = await database.get(
    "youtubeSharedCatalogueMeasurements/2026-08-11",
  );
  assert.equal(measurement?.cache_hit, 2);
  await database.set("youtubeSharedCatalogueMeasurements/2026-08-11", {
    ...measurement,
    cache_hit: -1,
  });
  await assert.rejects(store.recordOutcome("cache_hit", NOW.toISOString()));
});

test("shared snapshot retains a valid Short with no description", async () => {
  const database = new MemoryDocumentDatabase();
  const store = new FirestoreSharedShortsCatalogueStore(database);
  const lease: SharedShortsCatalogueRefreshLease = {
    leaseId: "empty-description-lease",
    acquiredAt: NOW.toISOString(),
    expiresAt: "2026-08-11T10:02:00.000Z",
  };
  assert.equal(await store.tryAcquireRefresh(lease), true);
  const next = snapshot(
    [short("empty-description", { description: "" })],
    "2026-08-11T10:30:00.000Z",
  );

  await store.commitRefresh(lease.leaseId, next);

  assert.deepEqual(await store.read(), next);
});

test("eligibility requires public processed embeddable India Shorts", () => {
  assert.equal(isEligibleSharedShort(short("eligible")), true);
  assert.equal(
    isEligibleSharedShort(short("not-declared", { title: "Regular video" })),
    false,
  );
  assert.equal(
    isEligibleSharedShort(short("blocked", {
      regionRestriction: { blocked: ["IN"] },
    })),
    false,
  );
});

test("quota decisions durably separate search, upload and general purpose", async () => {
  const database = new MemoryDocumentDatabase();
  const governor = new YouTubeQuotaGovernor(
    new FirestoreYouTubeQuotaStore(database),
    {
      clock: { now: () => NOW },
      caps: { search: 1, upload: 2, general: 2 },
    },
  );
  const quota = new YouTubeQuotaGovernorAdapter(governor);

  await quota.reserve({
    principal: "shared-shorts-catalogue",
    bucket: "search",
    amount: 1,
    operation: "search.list.sharedShortsRefresh",
    requestId: "request-search-1",
  });
  await assert.rejects(
    quota.reserve({
      principal: "shared-shorts-catalogue",
      bucket: "search",
      amount: 1,
      operation: "search.list.sharedShortsRefresh",
      requestId: "request-search-2",
    }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "quota_exhausted",
  );
  await quota.reserve({
    principal: "creator-1",
    bucket: "upload",
    amount: 1,
    operation: "videos.insert.private",
    requestId: "request-upload",
  });
  await quota.reserve({
    principal: "public",
    bucket: "general",
    amount: 1,
    operation: "videos.list.chart",
    requestId: "request-general",
  });

  const measurements = await database.queryByField(
    "youtubeProviderQuotaMeasurements",
    "provider",
    "YOUTUBE",
  );
  const byOperation = new Map(
    measurements.map((document) => [
      document.data.operation,
      document.data,
    ]),
  );
  assert.deepEqual(
    {
      accepted: byOperation.get("search.list.sharedShortsRefresh")
        ?.acceptedReservations,
      rejected: byOperation.get("search.list.sharedShortsRefresh")
        ?.rejectedReservations,
      localReservations: byOperation.get("search.list.sharedShortsRefresh")
        ?.acceptedLocalReservations,
    },
    { accepted: 1, rejected: 1, localReservations: 1 },
  );
  assert.equal(byOperation.get("videos.insert.private")?.bucket, "upload");
  assert.equal(byOperation.get("videos.list.chart")?.bucket, "general");

  const searchMeasurement = measurements.find(
    (document) =>
      document.data.operation === "search.list.sharedShortsRefresh",
  )!;
  await database.set(searchMeasurement.path, {
    ...searchMeasurement.data,
    acceptedReservations: -1,
  });
  await assert.rejects(
    quota.reserve({
      principal: "shared-shorts-catalogue",
      bucket: "search",
      amount: 1,
      operation: "search.list.sharedShortsRefresh",
      requestId: "request-search-corrupt",
    }),
    /acceptedReservations is invalid/u,
  );
});

test("measured quota reservation rolls back usage when measurement write fails", async () => {
  const database = new MemoryDocumentDatabase();
  const governor = new YouTubeQuotaGovernor(
    new FirestoreYouTubeQuotaStore(database),
    {
      clock: { now: () => NOW },
      caps: { general: 2 },
    },
  );
  const quota = new YouTubeQuotaGovernorAdapter(governor);
  const reservation = {
    principal: "public",
    bucket: "general" as const,
    amount: 1,
    operation: "videos.list.chart",
    requestId: "measurement-rollback",
  };

  database.failTransactionSetPrefix = "youtubeProviderQuotaMeasurements/";
  await assert.rejects(
    quota.reserve(reservation),
    /simulated transaction write failure/,
  );
  assert.equal(
    (await database.queryByField(
      "youtubeProviderQuotaUsage",
      "provider",
      "YOUTUBE",
    )).length,
    0,
  );
  assert.equal(
    (await database.queryByField(
      "youtubeProviderQuotaMeasurements",
      "provider",
      "YOUTUBE",
    )).length,
    0,
  );

  database.failTransactionSetPrefix = null;
  await quota.reserve(reservation);
  assert.equal(
    (await database.queryByField(
      "youtubeProviderQuotaUsage",
      "provider",
      "YOUTUBE",
    )).length,
    1,
  );
  assert.equal(
    (await database.queryByField(
      "youtubeProviderQuotaMeasurements",
      "provider",
      "YOUTUBE",
    )).length,
    1,
  );
});

test("corrupt measurement prevents a new usage mutation", async () => {
  const database = new MemoryDocumentDatabase();
  const quota = new YouTubeQuotaGovernorAdapter(
    new YouTubeQuotaGovernor(new FirestoreYouTubeQuotaStore(database), {
      clock: { now: () => NOW },
      caps: { general: 2 },
    }),
  );
  const reservation = {
    principal: "public",
    bucket: "general" as const,
    amount: 1,
    operation: "videos.list.chart",
    requestId: "measurement-corruption",
  };
  await quota.reserve(reservation);
  const usage = await database.queryByField(
    "youtubeProviderQuotaUsage",
    "provider",
    "YOUTUBE",
  );
  const measurements = await database.queryByField(
    "youtubeProviderQuotaMeasurements",
    "provider",
    "YOUTUBE",
  );
  assert.equal(usage.length, 1);
  assert.equal(measurements.length, 1);
  await database.delete(usage[0]!.path);
  await database.set(measurements[0]!.path, {
    ...measurements[0]!.data,
    acceptedReservations: -1,
  });

  await assert.rejects(
    quota.reserve({ ...reservation, requestId: "measurement-corruption-2" }),
    /acceptedReservations is invalid/u,
  );
  assert.equal(
    (await database.queryByField(
      "youtubeProviderQuotaUsage",
      "provider",
      "YOUTUBE",
    )).length,
    0,
  );
});

test("measurement counter overflow rolls back accepted and rejected usage", async () => {
  const acceptedDatabase = new MemoryDocumentDatabase();
  const acceptedQuota = new YouTubeQuotaGovernorAdapter(
    new YouTubeQuotaGovernor(
      new FirestoreYouTubeQuotaStore(acceptedDatabase),
      { clock: { now: () => NOW }, caps: { general: 2 } },
    ),
  );
  const acceptedReservation = {
    principal: "public",
    bucket: "general" as const,
    amount: 1,
    operation: "videos.list.chart",
    requestId: "accepted-overflow-seed",
  };
  await acceptedQuota.reserve(acceptedReservation);
  const acceptedUsage = await acceptedDatabase.queryByField(
    "youtubeProviderQuotaUsage",
    "provider",
    "YOUTUBE",
  );
  const acceptedMeasurements = await acceptedDatabase.queryByField(
    "youtubeProviderQuotaMeasurements",
    "provider",
    "YOUTUBE",
  );
  await acceptedDatabase.delete(acceptedUsage[0]!.path);
  await acceptedDatabase.set(acceptedMeasurements[0]!.path, {
    ...acceptedMeasurements[0]!.data,
    acceptedReservations: Number.MAX_SAFE_INTEGER,
    acceptedLocalReservations: Number.MAX_SAFE_INTEGER,
  });
  await assert.rejects(
    acceptedQuota.reserve({
      ...acceptedReservation,
      requestId: "accepted-overflow-retry",
    }),
    /acceptedReservations cannot be incremented safely/u,
  );
  assert.equal(
    (await acceptedDatabase.queryByField(
      "youtubeProviderQuotaUsage",
      "provider",
      "YOUTUBE",
    )).length,
    0,
  );
  assert.equal(
    (await acceptedDatabase.queryByField(
      "youtubeProviderQuotaMeasurements",
      "provider",
      "YOUTUBE",
    ))[0]?.data.acceptedReservations,
    Number.MAX_SAFE_INTEGER,
  );

  const rejectedDatabase = new MemoryDocumentDatabase();
  const rejectedQuota = new YouTubeQuotaGovernorAdapter(
    new YouTubeQuotaGovernor(
      new FirestoreYouTubeQuotaStore(rejectedDatabase),
      { clock: { now: () => NOW }, caps: { general: 0 } },
    ),
  );
  const rejectedReservation = {
    ...acceptedReservation,
    requestId: "rejected-overflow-seed",
  };
  await assert.rejects(
    rejectedQuota.reserve(rejectedReservation),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.code === "quota_exhausted",
  );
  const rejectedMeasurements = await rejectedDatabase.queryByField(
    "youtubeProviderQuotaMeasurements",
    "provider",
    "YOUTUBE",
  );
  await rejectedDatabase.set(rejectedMeasurements[0]!.path, {
    ...rejectedMeasurements[0]!.data,
    rejectedReservations: Number.MAX_SAFE_INTEGER,
  });
  await assert.rejects(
    rejectedQuota.reserve({
      ...rejectedReservation,
      requestId: "rejected-overflow-retry",
    }),
    /rejectedReservations cannot be incremented safely/u,
  );
  assert.equal(
    (await rejectedDatabase.queryByField(
      "youtubeProviderQuotaUsage",
      "provider",
      "YOUTUBE",
    )).length,
    0,
  );
  assert.equal(
    (await rejectedDatabase.queryByField(
      "youtubeProviderQuotaMeasurements",
      "provider",
      "YOUTUBE",
    ))[0]?.data.rejectedReservations,
    Number.MAX_SAFE_INTEGER,
  );
});

test("concurrent measured reservations keep usage and decision counters exact", async () => {
  const database = new MemoryDocumentDatabase();
  const quota = new YouTubeQuotaGovernorAdapter(
    new YouTubeQuotaGovernor(new FirestoreYouTubeQuotaStore(database), {
      clock: { now: () => NOW },
      caps: { general: 5 },
    }),
  );
  const results = await Promise.allSettled(
    Array.from({ length: 20 }, (_, index) =>
      quota.reserve({
        principal: "public",
        bucket: "general",
        amount: 1,
        operation: "videos.list.chart",
        requestId: `concurrent-measurement-${index}`,
      }),
    ),
  );
  assert.equal(
    results.filter((result) => result.status === "fulfilled").length,
    5,
  );
  assert.equal(
    results.filter((result) => result.status === "rejected").length,
    15,
  );
  const usage = await database.queryByField(
    "youtubeProviderQuotaUsage",
    "provider",
    "YOUTUBE",
  );
  const measurements = await database.queryByField(
    "youtubeProviderQuotaMeasurements",
    "provider",
    "YOUTUBE",
  );
  assert.equal(usage.length, 1);
  assert.equal(usage[0]?.data.used, 5);
  assert.equal(measurements.length, 1);
  assert.equal(measurements[0]?.data.acceptedReservations, 5);
  assert.equal(measurements[0]?.data.rejectedReservations, 15);
  assert.equal(measurements[0]?.data.acceptedLocalReservations, 5);
});
