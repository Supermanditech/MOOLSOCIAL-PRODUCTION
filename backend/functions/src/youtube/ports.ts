import type {
  YouTubeProviderConnectionRecord,
  YouTubePublicationJobRecord,
  YouTubeQuotaBucket,
} from "./types.js";

export interface QuotaReservation {
  readonly principal: string;
  readonly bucket: YouTubeQuotaBucket;
  readonly amount: number;
  readonly operation: string;
  readonly requestId: string;
}

export interface YouTubeQuotaPort {
  reserve(reservation: QuotaReservation): Promise<void>;
}

export interface YouTubeCachePort {
  getOrLoad<T>(
    key: string,
    ttlMs: number,
    loader: () => Promise<T>,
  ): Promise<T>;
}

export interface YouTubeConnectionStore {
  getByUser(userId: string): Promise<YouTubeProviderConnectionRecord | null>;
  save(record: YouTubeProviderConnectionRecord): Promise<void>;
  markRevoked(connectionKey: string, revokedAt: string): Promise<void>;
  delete(connectionKey: string): Promise<void>;
}

export interface YouTubePublicationStore {
  reserve(
    record: YouTubePublicationJobRecord,
  ): Promise<{
    readonly created: boolean;
    readonly record: YouTubePublicationJobRecord;
  }>;
  getByKey(
    userId: string,
    jobKey: string,
  ): Promise<YouTubePublicationJobRecord | null>;
  getByIdempotencyKey(
    userId: string,
    idempotencyKey: string,
  ): Promise<YouTubePublicationJobRecord | null>;
  update(
    userId: string,
    jobKey: string,
    patch: Partial<YouTubePublicationJobRecord>,
  ): Promise<void>;
  deleteByUser(userId: string): Promise<void>;
}

export interface YouTubeAuditEvent {
  readonly userId?: string;
  readonly eventType: string;
  readonly requestId: string;
  readonly detail: unknown;
  readonly occurredAt: string;
}

export interface YouTubeAuditPort {
  record(event: YouTubeAuditEvent): Promise<void>;
}

export interface Clock {
  now(): Date;
}

export const systemClock: Clock = {
  now: () => new Date(),
};
