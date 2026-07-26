import { YouTubeProviderError } from "./errors.js";
import type { YouTubeQuotaBucket } from "./types.js";

export interface YouTubeQuotaCaps {
  readonly search: number;
  readonly upload: number;
  readonly batchStats: number;
  readonly analytics: number;
  readonly general: number;
}

export const DEFAULT_DEV_YOUTUBE_QUOTA_CAPS: Readonly<YouTubeQuotaCaps> =
  Object.freeze({
    search: 20,
    upload: 10,
    batchStats: 500,
    analytics: 100,
    general: 2_000,
  });

const YOUTUBE_QUOTA_TIME_ZONE = "America/Los_Angeles";
const QUOTA_RESET_SEARCH_MARGIN_MS = 18 * 60 * 60 * 1_000;
const pacificDateFormatter = new Intl.DateTimeFormat(
  "en-US-u-ca-iso8601-nu-latn",
  {
    timeZone: YOUTUBE_QUOTA_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  },
);

export interface QuotaClock {
  now(): Date;
}

export class SystemQuotaClock implements QuotaClock {
  now(): Date {
    return new Date();
  }
}

export interface YouTubeQuotaWindow {
  readonly id: string;
  readonly resetAt: string;
}

export interface YouTubeQuotaReserveRequest {
  readonly bucket: YouTubeQuotaBucket;
  readonly windowId: string;
  readonly resetAt: string;
  readonly units: number;
  readonly limit: number;
}

export interface YouTubeQuotaReserveResult {
  readonly allowed: boolean;
  readonly bucket: YouTubeQuotaBucket;
  readonly windowId: string;
  readonly resetAt: string;
  readonly used: number;
  readonly remaining: number;
  readonly limit: number;
}

/**
 * Implementations must make `reserve` atomic across every function instance
 * sharing the same quota ledger. A read followed by a separate write does not
 * satisfy this contract.
 */
export interface YouTubeQuotaStore {
  reserve(
    request: YouTubeQuotaReserveRequest,
  ): Promise<YouTubeQuotaReserveResult>;
}

interface InMemoryUsage {
  used: number;
}

/**
 * Deterministic local/test store. The mutation has no await point, so each
 * reservation is one atomic operation inside a JavaScript isolate.
 */
export class InMemoryYouTubeQuotaStore implements YouTubeQuotaStore {
  private readonly usage = new Map<string, InMemoryUsage>();

  async reserve(
    request: YouTubeQuotaReserveRequest,
  ): Promise<YouTubeQuotaReserveResult> {
    const key = `${request.windowId}:${request.bucket}`;
    const current = this.usage.get(key)?.used ?? 0;
    const allowed = current + request.units <= request.limit;
    const used = allowed ? current + request.units : current;

    if (allowed) {
      this.usage.set(key, { used });
    }

    return {
      allowed,
      bucket: request.bucket,
      windowId: request.windowId,
      resetAt: request.resetAt,
      used,
      remaining: Math.max(0, request.limit - used),
      limit: request.limit,
    };
  }
}

export interface YouTubeQuotaGovernorOptions {
  readonly clock?: QuotaClock;
  readonly caps?: Partial<YouTubeQuotaCaps>;
}

function assertNonNegativeInteger(value: number, name: string): void {
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new TypeError(`${name} must be a non-negative safe integer.`);
  }
}

interface PacificCalendarDate {
  readonly year: number;
  readonly month: number;
  readonly day: number;
  readonly id: string;
}

function requiredDatePart(
  parts: readonly Intl.DateTimeFormatPart[],
  type: "year" | "month" | "day",
): number {
  const value = Number(parts.find((part) => part.type === type)?.value);
  if (!Number.isSafeInteger(value)) {
    throw new TypeError("YouTube quota timezone data is unavailable.");
  }
  return value;
}

function pacificCalendarDate(at: Date): PacificCalendarDate {
  if (!Number.isFinite(at.getTime())) {
    throw new TypeError("Quota clock returned an invalid date.");
  }

  let parts: Intl.DateTimeFormatPart[];
  try {
    parts = pacificDateFormatter.formatToParts(at);
  } catch {
    throw new TypeError("YouTube quota timezone data is unavailable.");
  }

  const year = requiredDatePart(parts, "year");
  const month = requiredDatePart(parts, "month");
  const day = requiredDatePart(parts, "day");
  if (
    year < 1 ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > 31
  ) {
    throw new TypeError("YouTube quota timezone data is invalid.");
  }

  return {
    year,
    month,
    day,
    id: [
      String(year).padStart(4, "0"),
      String(month).padStart(2, "0"),
      String(day).padStart(2, "0"),
    ].join("-"),
  };
}

function nextCalendarDate(
  current: PacificCalendarDate,
): PacificCalendarDate {
  const next = new Date(0);
  next.setUTCFullYear(current.year, current.month - 1, current.day + 1);
  next.setUTCHours(0, 0, 0, 0);
  return {
    year: next.getUTCFullYear(),
    month: next.getUTCMonth() + 1,
    day: next.getUTCDate(),
    id: next.toISOString().slice(0, 10),
  };
}

/**
 * Finds the first UTC instant that belongs to a Pacific calendar date.
 * Searching the date boundary avoids fixed-offset assumptions and therefore
 * remains correct across both 23-hour and 25-hour daylight-saving days.
 */
function pacificMidnightUtc(target: PacificCalendarDate): Date {
  const approximateUtcMidnight = new Date(0);
  approximateUtcMidnight.setUTCFullYear(
    target.year,
    target.month - 1,
    target.day,
  );
  approximateUtcMidnight.setUTCHours(0, 0, 0, 0);

  let lower =
    approximateUtcMidnight.getTime() - QUOTA_RESET_SEARCH_MARGIN_MS;
  let upper =
    approximateUtcMidnight.getTime() + QUOTA_RESET_SEARCH_MARGIN_MS;
  if (
    !Number.isFinite(lower) ||
    !Number.isFinite(upper) ||
    pacificCalendarDate(new Date(lower)).id >= target.id ||
    pacificCalendarDate(new Date(upper)).id < target.id
  ) {
    throw new TypeError("YouTube quota reset boundary is unavailable.");
  }

  while (upper - lower > 1) {
    const middle = lower + Math.floor((upper - lower) / 2);
    if (pacificCalendarDate(new Date(middle)).id >= target.id) {
      upper = middle;
    } else {
      lower = middle;
    }
  }

  const resetAt = new Date(upper);
  if (
    pacificCalendarDate(resetAt).id !== target.id ||
    pacificCalendarDate(new Date(upper - 1)).id >= target.id
  ) {
    throw new TypeError("YouTube quota reset boundary is invalid.");
  }
  return resetAt;
}

function resolveCaps(
  partial: Partial<YouTubeQuotaCaps> | undefined,
): Readonly<YouTubeQuotaCaps> {
  const caps = {
    ...DEFAULT_DEV_YOUTUBE_QUOTA_CAPS,
    ...partial,
  };
  assertNonNegativeInteger(caps.search, "search quota cap");
  assertNonNegativeInteger(caps.upload, "upload quota cap");
  assertNonNegativeInteger(caps.batchStats, "batch stats quota cap");
  assertNonNegativeInteger(caps.analytics, "analytics quota cap");
  assertNonNegativeInteger(caps.general, "general quota cap");
  return Object.freeze(caps);
}

export function youtubePacificDailyQuotaWindow(
  at: Date,
): YouTubeQuotaWindow {
  const current = pacificCalendarDate(at);
  return {
    id: current.id,
    resetAt: pacificMidnightUtc(nextCalendarDate(current)).toISOString(),
  };
}

function optionalCap(
  value: string | undefined,
  fallback: number,
  name: string,
): number {
  if (value === undefined || value.trim() === "") {
    return fallback;
  }
  const parsed = Number(value);
  assertNonNegativeInteger(parsed, name);
  if (parsed > fallback) {
    throw new TypeError(
      `${name} cannot exceed the private Dev hard cap of ${fallback}.`,
    );
  }
  return parsed;
}

export function readDevYouTubeQuotaCaps(
  env: NodeJS.ProcessEnv = process.env,
): Readonly<YouTubeQuotaCaps> {
  return Object.freeze({
    search: optionalCap(
      env.YOUTUBE_DEV_SEARCH_DAILY_CAP,
      DEFAULT_DEV_YOUTUBE_QUOTA_CAPS.search,
      "YOUTUBE_DEV_SEARCH_DAILY_CAP",
    ),
    upload: optionalCap(
      env.YOUTUBE_DEV_UPLOAD_DAILY_CAP,
      DEFAULT_DEV_YOUTUBE_QUOTA_CAPS.upload,
      "YOUTUBE_DEV_UPLOAD_DAILY_CAP",
    ),
    batchStats: optionalCap(
      env.YOUTUBE_DEV_BATCH_STATS_DAILY_CAP,
      DEFAULT_DEV_YOUTUBE_QUOTA_CAPS.batchStats,
      "YOUTUBE_DEV_BATCH_STATS_DAILY_CAP",
    ),
    analytics: optionalCap(
      env.YOUTUBE_DEV_ANALYTICS_DAILY_CAP,
      DEFAULT_DEV_YOUTUBE_QUOTA_CAPS.analytics,
      "YOUTUBE_DEV_ANALYTICS_DAILY_CAP",
    ),
    general: optionalCap(
      env.YOUTUBE_DEV_GENERAL_DAILY_CAP,
      DEFAULT_DEV_YOUTUBE_QUOTA_CAPS.general,
      "YOUTUBE_DEV_GENERAL_DAILY_CAP",
    ),
  });
}

function assertReserveResult(
  result: YouTubeQuotaReserveResult,
  request: YouTubeQuotaReserveRequest,
): void {
  const invalidIdentity =
    result.bucket !== request.bucket ||
    result.windowId !== request.windowId ||
    result.resetAt !== request.resetAt ||
    result.limit !== request.limit;
  const invalidCounters =
    typeof result.allowed !== "boolean" ||
    !Number.isSafeInteger(result.used) ||
    !Number.isSafeInteger(result.remaining) ||
    result.used < 0 ||
    result.used > result.limit ||
    result.remaining !== result.limit - result.used;
  const invalidDecision = result.allowed
    ? result.used < request.units
    : result.used + request.units <= request.limit;

  if (invalidIdentity || invalidCounters || invalidDecision) {
    throw new TypeError(
      "YouTube quota store returned an invalid reservation result.",
    );
  }
}

export class YouTubeQuotaGovernor {
  private readonly clock: QuotaClock;
  readonly caps: Readonly<YouTubeQuotaCaps>;

  constructor(
    private readonly store: YouTubeQuotaStore,
    options: YouTubeQuotaGovernorOptions = {},
  ) {
    this.clock = options.clock ?? new SystemQuotaClock();
    this.caps = resolveCaps(options.caps);
  }

  /**
   * Reserves capacity before the provider call. Exhaustion fails closed and
   * is deliberately non-retryable; callers must wait for the next window or
   * use an explicitly approved recovery path.
   */
  async reserve(
    bucket: YouTubeQuotaBucket,
    units = 1,
  ): Promise<YouTubeQuotaReserveResult> {
    if (!Number.isSafeInteger(units) || units <= 0) {
      throw new TypeError("Quota units must be a positive safe integer.");
    }

    const window = youtubePacificDailyQuotaWindow(this.clock.now());
    const request: YouTubeQuotaReserveRequest = {
      bucket,
      windowId: window.id,
      resetAt: window.resetAt,
      units,
      limit: this.caps[bucket],
    };
    const result = await this.store.reserve(request);
    assertReserveResult(result, request);

    if (!result.allowed) {
      throw new YouTubeProviderError(
        "quota_exhausted",
        `YouTube ${bucket} capacity is unavailable until ${result.resetAt}.`,
        429,
        false,
        "localDevHardCap",
      );
    }

    return result;
  }
}
