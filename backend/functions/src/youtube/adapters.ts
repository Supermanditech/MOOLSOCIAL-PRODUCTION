import type { QuotaReservation, YouTubeQuotaPort } from "./ports.js";
import type { YouTubeCachePort } from "./ports.js";
import { AsyncTtlCache } from "./cache.js";
import type { YouTubeQuotaGovernor } from "./quota.js";

/**
 * Keeps provider clients independent from the persistence implementation while
 * retaining request metadata for redacted audit logs at the HTTP boundary.
 */
export class YouTubeQuotaGovernorAdapter implements YouTubeQuotaPort {
  constructor(private readonly governor: YouTubeQuotaGovernor) {}

  async reserve(reservation: QuotaReservation): Promise<void> {
    await this.governor.reserveMeasured(
      reservation.bucket,
      reservation.amount,
      {
      principal: reservation.principal,
      operation: reservation.operation,
      requestId: reservation.requestId,
      local: true,
      },
    );
  }
}

export class ProcessYouTubeCache implements YouTubeCachePort {
  private readonly cache = new AsyncTtlCache<string, unknown>();

  async getOrLoad<T>(
    key: string,
    ttlMs: number,
    loader: () => Promise<T>,
  ): Promise<T> {
    return this.cache.getOrLoad(
      key,
      ttlMs,
      loader as () => Promise<unknown>,
    ) as Promise<T>;
  }
}
