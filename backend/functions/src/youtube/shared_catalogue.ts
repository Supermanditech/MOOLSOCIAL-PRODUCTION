import type {
  ProviderDocumentDatabase,
  ProviderDocumentTransaction,
} from "./firestore_store.js";
import { YouTubeProviderError } from "./errors.js";
import type { YouTubePage, YouTubeVideoSummary } from "./types.js";

const SNAPSHOT_PATH =
  "youtubeSharedCatalogueSnapshots/india-news-shorts-v1";
const MEASUREMENT_COLLECTION = "youtubeSharedCatalogueMeasurements";
const INDIA_REGION_CODE = "IN";
const SHARED_SHORTS_QUERY = "India news #Shorts";
const TARGET_ITEMS = 20;
const SHARED_SHORTS_PAGE_SIZE = 25;
const MAXIMUM_PAGES = 4;
const MAXIMUM_SHORT_SECONDS = 180;
const SNAPSHOT_TTL_MS = 30 * 60 * 1000;
const REFRESH_LEASE_MS = 2 * 60 * 1000;
const STALE_FALLBACK_MS = 6 * 60 * 60 * 1000;

type StoredDocument = Readonly<Record<string, unknown>>;

export type SharedShortsCatalogueOutcome =
  | "cache_hit"
  | "refresh_success"
  | "stale_fallback"
  | "refresh_error"
  | "lease_contended";

export interface SharedShortsCatalogueSnapshot {
  readonly schemaVersion: 1;
  readonly items: readonly YouTubeVideoSummary[];
  readonly refreshedAt: string;
  readonly expiresAt: string;
}

export interface SharedShortsCatalogueResult
  extends SharedShortsCatalogueSnapshot {
  readonly source: "cache" | "refresh" | "stale";
}

export interface SharedShortsCatalogueRefreshLease {
  readonly leaseId: string;
  readonly acquiredAt: string;
  readonly expiresAt: string;
}

export interface SharedShortsCatalogueStore {
  read(): Promise<SharedShortsCatalogueSnapshot | null>;
  tryAcquireRefresh(lease: SharedShortsCatalogueRefreshLease): Promise<boolean>;
  commitRefresh(
    leaseId: string,
    snapshot: SharedShortsCatalogueSnapshot,
  ): Promise<void>;
  abandonRefresh(leaseId: string): Promise<void>;
  recordOutcome(
    outcome: SharedShortsCatalogueOutcome,
    occurredAt: string,
  ): Promise<void>;
}

export interface SharedShortsCatalogueCoordinatorOptions {
  readonly store: SharedShortsCatalogueStore;
  readonly loadPage: (
    requestId: string,
    pageToken?: string,
  ) => Promise<YouTubePage<YouTubeVideoSummary>>;
  readonly now?: () => Date;
}

function epoch(value: string): number | null {
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function requiredText(
  value: unknown,
  field: string,
  maximum = 5000,
): string {
  if (
    typeof value !== "string" ||
    value.trim().length === 0 ||
    value.length > maximum
  ) {
    throw new Error(`Shared YouTube catalogue has an invalid ${field}.`);
  }
  return value;
}

function snapshotItem(value: unknown): YouTubeVideoSummary {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("Shared YouTube catalogue contains an invalid item.");
  }
  const item = value as Record<string, unknown>;
  const thumbnail = item.thumbnail;
  if (
    typeof thumbnail !== "object" ||
    thumbnail === null ||
    Array.isArray(thumbnail)
  ) {
    throw new Error("Shared YouTube catalogue contains an invalid thumbnail.");
  }
  requiredText(item.videoId, "videoId", 64);
  requiredText(item.title, "title");
  requiredText(item.channelId, "channelId", 64);
  requiredText(item.channelTitle, "channelTitle");
  requiredText(item.publishedAt, "publishedAt", 64);
  requiredText(item.description, "description", 25000);
  requiredText(
    (thumbnail as Record<string, unknown>).url,
    "thumbnail URL",
    2048,
  );
  return item as unknown as YouTubeVideoSummary;
}

function snapshotFromDocument(
  document: StoredDocument | undefined,
): SharedShortsCatalogueSnapshot | null {
  if (document === undefined || document.snapshot === undefined) return null;
  const value = document.snapshot;
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw new Error("Shared YouTube catalogue snapshot is invalid.");
  }
  const data = value as Record<string, unknown>;
  if (data.schemaVersion !== 1 || !Array.isArray(data.items)) {
    throw new Error("Shared YouTube catalogue schema is invalid.");
  }
  if (data.items.length < 1 || data.items.length > TARGET_ITEMS) {
    throw new Error("Shared YouTube catalogue item count is invalid.");
  }
  const refreshedAt = requiredText(data.refreshedAt, "refreshedAt", 64);
  const expiresAt = requiredText(data.expiresAt, "expiresAt", 64);
  const refreshedEpoch = epoch(refreshedAt);
  const expiresEpoch = epoch(expiresAt);
  if (
    refreshedEpoch === null ||
    expiresEpoch === null ||
    expiresEpoch <= refreshedEpoch
  ) {
    throw new Error("Shared YouTube catalogue timestamps are invalid.");
  }
  const items = data.items.map(snapshotItem);
  if (!items.every(isEligibleSharedShort)) {
    throw new Error("Shared YouTube catalogue contains an ineligible item.");
  }
  return {
    schemaVersion: 1,
    items,
    refreshedAt,
    expiresAt,
  };
}

function withoutLease(document: StoredDocument): StoredDocument {
  const {
    refreshLeaseId: _refreshLeaseId,
    refreshLeaseAcquiredAt: _refreshLeaseAcquiredAt,
    refreshLeaseExpiresAt: _refreshLeaseExpiresAt,
    ...rest
  } = document;
  return rest;
}

function activeLease(
  document: StoredDocument,
  nowEpoch: number,
): boolean {
  const leaseId = document.refreshLeaseId;
  const expiresAt = document.refreshLeaseExpiresAt;
  const expiresEpoch = typeof expiresAt === "string" ? epoch(expiresAt) : null;
  return (
    typeof leaseId === "string" &&
    leaseId.length > 0 &&
    expiresEpoch !== null &&
    expiresEpoch > nowEpoch
  );
}

function validLease(lease: SharedShortsCatalogueRefreshLease): void {
  const acquired = epoch(lease.acquiredAt);
  const expires = epoch(lease.expiresAt);
  if (
    !/^[A-Za-z0-9._:-]{1,180}$/u.test(lease.leaseId) ||
    acquired === null ||
    expires === null ||
    expires <= acquired ||
    expires - acquired > REFRESH_LEASE_MS
  ) {
    throw new Error("Shared YouTube catalogue refresh lease is invalid.");
  }
}

function counter(document: StoredDocument, field: string): number {
  const value = document[field];
  if (value === undefined) return 0;
  if (!Number.isSafeInteger(value) || Number(value) < 0) {
    throw new Error(`Shared YouTube catalogue ${field} counter is invalid.`);
  }
  return Number(value);
}

export class FirestoreSharedShortsCatalogueStore
  implements SharedShortsCatalogueStore
{
  constructor(private readonly database: ProviderDocumentDatabase) {}

  async read(): Promise<SharedShortsCatalogueSnapshot | null> {
    return snapshotFromDocument(await this.database.get(SNAPSHOT_PATH));
  }

  async tryAcquireRefresh(
    lease: SharedShortsCatalogueRefreshLease,
  ): Promise<boolean> {
    validLease(lease);
    return this.database.runTransaction(async (transaction) => {
      const existing = (await transaction.get(SNAPSHOT_PATH)) ?? {};
      const acquiredEpoch = epoch(lease.acquiredAt)!;
      if (activeLease(existing, acquiredEpoch)) return false;
      transaction.set(SNAPSHOT_PATH, {
        ...withoutLease(existing),
        provider: "YOUTUBE",
        catalogue: "INDIA_NEWS_SHORTS",
        refreshLeaseId: lease.leaseId,
        refreshLeaseAcquiredAt: lease.acquiredAt,
        refreshLeaseExpiresAt: lease.expiresAt,
      });
      return true;
    });
  }

  async commitRefresh(
    leaseId: string,
    snapshot: SharedShortsCatalogueSnapshot,
  ): Promise<void> {
    snapshotFromDocument({ snapshot });
    await this.database.runTransaction(async (transaction) => {
      const existing = await transaction.get(SNAPSHOT_PATH);
      if (existing?.refreshLeaseId !== leaseId) {
        throw new Error("Shared YouTube catalogue refresh lease was lost.");
      }
      transaction.set(SNAPSHOT_PATH, {
        ...withoutLease(existing),
        provider: "YOUTUBE",
        catalogue: "INDIA_NEWS_SHORTS",
        snapshot,
        updatedAt: snapshot.refreshedAt,
      });
    });
  }

  async abandonRefresh(leaseId: string): Promise<void> {
    await this.database.runTransaction(async (transaction) => {
      const existing = await transaction.get(SNAPSHOT_PATH);
      if (existing === undefined || existing.refreshLeaseId !== leaseId) return;
      transaction.set(SNAPSHOT_PATH, withoutLease(existing));
    });
  }

  async recordOutcome(
    outcome: SharedShortsCatalogueOutcome,
    occurredAt: string,
  ): Promise<void> {
    if (epoch(occurredAt) === null) {
      throw new Error("Shared YouTube catalogue measurement time is invalid.");
    }
    const windowId = occurredAt.slice(0, 10);
    const path = `${MEASUREMENT_COLLECTION}/${windowId}`;
    await this.database.runTransaction(async (transaction) => {
      const existing = (await transaction.get(path)) ?? {};
      transaction.set(path, {
        ...existing,
        provider: "YOUTUBE",
        catalogue: "INDIA_NEWS_SHORTS",
        windowId,
        [outcome]: counter(existing, outcome) + 1,
        updatedAt: occurredAt,
      });
    });
  }
}

function isoDurationSeconds(value: string | undefined): number | null {
  if (value === undefined) return null;
  const match = /^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/u.exec(
    value.trim().toUpperCase(),
  );
  if (match === null) return null;
  const hours = Number(match[1] ?? 0);
  const minutes = Number(match[2] ?? 0);
  const seconds = Number(match[3] ?? 0);
  return (hours * 60 * 60) + (minutes * 60) + seconds;
}

function creatorDeclaredShort(video: YouTubeVideoSummary): boolean {
  const duration = isoDurationSeconds(video.duration);
  if (
    duration === null ||
    duration <= 0 ||
    duration > MAXIMUM_SHORT_SECONDS
  ) {
    return false;
  }
  const declaration = [
    video.title,
    video.localized?.title ?? "",
    video.description,
    video.localized?.description ?? "",
    ...(video.tags ?? []),
  ].join(" ").toLowerCase();
  return /(^|[^a-z0-9])#?(?:youtube\s*)?shorts?(?=$|[^a-z0-9])/u.test(
    declaration,
  );
}

function regionAllowsIndia(video: YouTubeVideoSummary): boolean {
  const blocked = video.regionRestriction?.blocked;
  if (blocked?.some((region) => region.toUpperCase() === INDIA_REGION_CODE)) {
    return false;
  }
  const allowed = video.regionRestriction?.allowed;
  return (
    allowed === undefined ||
    allowed.some((region) => region.toUpperCase() === INDIA_REGION_CODE)
  );
}

export function isEligibleSharedShort(video: YouTubeVideoSummary): boolean {
  return (
    video.privacyStatus === "public" &&
    video.uploadStatus === "processed" &&
    video.embeddable === true &&
    video.availability?.state === "available" &&
    video.availability.regionCode.toUpperCase() === INDIA_REGION_CODE &&
    regionAllowsIndia(video) &&
    creatorDeclaredShort(video)
  );
}

async function safeRecordOutcome(
  store: SharedShortsCatalogueStore,
  outcome: SharedShortsCatalogueOutcome,
  occurredAt: string,
): Promise<void> {
  try {
    await store.recordOutcome(outcome, occurredAt);
  } catch {
    // Measurement is best effort so an already-qualified public catalogue is
    // never withheld solely because its operational counter is unavailable.
  }
}

function usableStaleSnapshot(
  snapshot: SharedShortsCatalogueSnapshot | null,
  nowEpoch: number,
): snapshot is SharedShortsCatalogueSnapshot {
  if (snapshot === null) return false;
  const expiresAt = epoch(snapshot.expiresAt);
  return expiresAt !== null && nowEpoch <= expiresAt + STALE_FALLBACK_MS;
}

function safeRefreshFailureClass(error: unknown): string {
  if (typeof error === "object" && error !== null && "code" in error) {
    const code = String((error as { readonly code?: unknown }).code ?? "");
    if (/^[A-Za-z0-9_-]{1,32}$/u.test(code)) return `code_${code}`;
  }
  if (error instanceof Error) {
    const message = error.message.toLowerCase();
    if (message.includes("refresh lease was lost")) return "lease_lost";
    if (message.includes("undefined")) return "undefined_value";
    if (message.includes("maximum") && message.includes("size")) {
      return "document_size";
    }
    if (message.includes("transaction")) return "transaction";
    if (/^[A-Za-z][A-Za-z0-9]{0,31}$/u.test(error.name)) {
      return error.name.toLowerCase();
    }
  }
  return "unknown";
}

export class SharedShortsCatalogueCoordinator {
  private readonly now: () => Date;

  constructor(private readonly options: SharedShortsCatalogueCoordinatorOptions) {
    this.now = options.now ?? (() => new Date());
  }

  async load(requestId: string): Promise<SharedShortsCatalogueResult> {
    const cleanRequestId = requestId.trim();
    if (!/^[A-Za-z0-9._:-]{1,180}$/u.test(cleanRequestId)) {
      throw new YouTubeProviderError(
        "bad_request",
        "A valid request identifier is required.",
        400,
      );
    }
    const now = this.now();
    const nowEpoch = now.getTime();
    const nowIso = now.toISOString();
    let snapshot: SharedShortsCatalogueSnapshot | null;
    try {
      snapshot = await this.options.store.read();
    } catch {
      throw new YouTubeProviderError(
        "provider_unavailable",
        "The shared YouTube catalogue is temporarily unavailable.",
        503,
        true,
      );
    }
    const expiresAt = snapshot === null ? null : epoch(snapshot.expiresAt);
    if (snapshot !== null && expiresAt !== null && expiresAt > nowEpoch) {
      await safeRecordOutcome(this.options.store, "cache_hit", nowIso);
      return { ...snapshot, source: "cache" };
    }

    const lease: SharedShortsCatalogueRefreshLease = {
      leaseId: cleanRequestId,
      acquiredAt: nowIso,
      expiresAt: new Date(nowEpoch + REFRESH_LEASE_MS).toISOString(),
    };
    let acquired: boolean;
    try {
      acquired = await this.options.store.tryAcquireRefresh(lease);
    } catch {
      acquired = false;
    }
    if (!acquired) {
      await safeRecordOutcome(this.options.store, "lease_contended", nowIso);
      if (usableStaleSnapshot(snapshot, nowEpoch)) {
        await safeRecordOutcome(this.options.store, "stale_fallback", nowIso);
        return { ...snapshot, source: "stale" };
      }
      throw new YouTubeProviderError(
        "provider_unavailable",
        "The shared YouTube catalogue is refreshing. Try again shortly.",
        503,
        true,
      );
    }

    let refreshPhase = "load_page";
    try {
      const items: YouTubeVideoSummary[] = [];
      const videoIds = new Set<string>();
      const pageTokens = new Set<string>();
      let pageToken: string | undefined;
      for (let index = 0; index < MAXIMUM_PAGES; index += 1) {
        const identity = pageToken ?? "__first_page__";
        if (pageTokens.has(identity)) break;
        pageTokens.add(identity);
        const page = await this.options.loadPage(
          cleanRequestId,
          pageToken,
        );
        for (const item of page.items) {
          if (!isEligibleSharedShort(item) || videoIds.has(item.videoId)) {
            continue;
          }
          videoIds.add(item.videoId);
          items.push(item);
          if (items.length === TARGET_ITEMS) break;
        }
        if (items.length === TARGET_ITEMS) break;
        const next = page.nextPageToken?.trim();
        if (!next) break;
        pageToken = next;
      }
      if (items.length === 0) {
        throw new YouTubeProviderError(
          "provider_unavailable",
          "No eligible public YouTube Shorts are currently available.",
          503,
          true,
        );
      }
      const refreshedAt = this.now();
      const next: SharedShortsCatalogueSnapshot = {
        schemaVersion: 1,
        items,
        refreshedAt: refreshedAt.toISOString(),
        expiresAt: new Date(
          refreshedAt.getTime() + SNAPSHOT_TTL_MS,
        ).toISOString(),
      };
      refreshPhase = "commit_refresh";
      await this.options.store.commitRefresh(lease.leaseId, next);
      await safeRecordOutcome(
        this.options.store,
        "refresh_success",
        next.refreshedAt,
      );
      return { ...next, source: "refresh" };
    } catch (error) {
      await this.options.store.abandonRefresh(lease.leaseId).catch(() => undefined);
      await safeRecordOutcome(
        this.options.store,
        "refresh_error",
        this.now().toISOString(),
      );
      if (usableStaleSnapshot(snapshot, nowEpoch)) {
        await safeRecordOutcome(
          this.options.store,
          "stale_fallback",
          this.now().toISOString(),
        );
        return { ...snapshot, source: "stale" };
      }
      if (error instanceof YouTubeProviderError) throw error;
      throw new YouTubeProviderError(
        "provider_unavailable",
        "The shared YouTube catalogue is temporarily unavailable.",
        503,
        true,
        `sharedShortsCatalogue.${refreshPhase}.${safeRefreshFailureClass(error)}`,
      );
    }
  }
}

export const sharedShortsCatalogueContract = Object.freeze({
  regionCode: INDIA_REGION_CODE,
  query: SHARED_SHORTS_QUERY,
  targetItems: TARGET_ITEMS,
  pageSize: SHARED_SHORTS_PAGE_SIZE,
  maximumPages: MAXIMUM_PAGES,
  maximumShortSeconds: MAXIMUM_SHORT_SECONDS,
  snapshotTtlMs: SNAPSHOT_TTL_MS,
  refreshLeaseMs: REFRESH_LEASE_MS,
  staleFallbackMs: STALE_FALLBACK_MS,
});
