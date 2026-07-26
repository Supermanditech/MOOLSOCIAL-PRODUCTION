import type { QuotaReservation, YouTubeQuotaPort } from "../../youtube/ports.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "../../youtube/types.js";
import {
  YOUTUBE_ANALYTICS_READ_SCOPE,
  type AnalyticsReportingClientOptions,
  type IdempotencyPort,
  type IdempotencyReservation,
  type ReplayProtectionPort,
  type VerifiedOwnerInvocation,
} from "./contracts.js";

export class QueueTransport implements HttpTransport {
  readonly requests: HttpTransportRequest[] = [];

  constructor(
    private readonly responses: readonly HttpTransportResponse[],
  ) {}

  async send(request: HttpTransportRequest): Promise<HttpTransportResponse> {
    this.requests.push(request);
    const response = this.responses[this.requests.length - 1];
    if (response === undefined) {
      throw new Error(`Unexpected provider request: ${request.url}`);
    }
    return response;
  }
}

export function jsonResponse(
  body: unknown,
  status = 200,
): HttpTransportResponse {
  return {
    status,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  };
}

export class RecordingQuota implements YouTubeQuotaPort {
  readonly reservations: QuotaReservation[] = [];

  async reserve(reservation: QuotaReservation): Promise<void> {
    this.reservations.push(reservation);
  }
}

export class RecordingReplayProtection implements ReplayProtectionPort {
  readonly consumed: string[] = [];
  private readonly seen = new Set<string>();

  async consume(key: string): Promise<boolean> {
    this.consumed.push(key);
    if (this.seen.has(key)) return false;
    this.seen.add(key);
    return true;
  }
}

interface StoredIdempotency {
  readonly fingerprint: string;
  state: "in_progress" | "completed";
  result?: unknown;
}

export class InMemoryIdempotency implements IdempotencyPort {
  private readonly values = new Map<string, StoredIdempotency>();

  async reserve(
    namespace: string,
    key: string,
    fingerprint: string,
  ): Promise<IdempotencyReservation> {
    const composite = `${namespace}:${key}`;
    const existing = this.values.get(composite);
    if (existing === undefined) {
      this.values.set(composite, { fingerprint, state: "in_progress" });
      return { state: "new" };
    }
    if (existing.fingerprint !== fingerprint) return { state: "conflict" };
    if (existing.state === "in_progress") return { state: "in_progress" };
    return { state: "completed", result: existing.result };
  }

  async complete(
    namespace: string,
    key: string,
    fingerprint: string,
    result: unknown,
  ): Promise<void> {
    const composite = `${namespace}:${key}`;
    const existing = this.values.get(composite);
    if (
      existing === undefined ||
      existing.fingerprint !== fingerprint ||
      existing.state !== "in_progress"
    ) {
      throw new Error("Invalid idempotency completion.");
    }
    existing.state = "completed";
    existing.result = result;
  }

  async release(
    namespace: string,
    key: string,
    fingerprint: string,
  ): Promise<void> {
    const composite = `${namespace}:${key}`;
    const existing = this.values.get(composite);
    if (
      existing?.fingerprint === fingerprint &&
      existing.state === "in_progress"
    ) {
      this.values.delete(composite);
    }
  }
}

export function ownerInvocation(
  replayId: string,
  overrides: Partial<VerifiedOwnerInvocation> = {},
): VerifiedOwnerInvocation {
  return {
    principal: "uid-hash",
    requestId: `request-${replayId}`,
    accessToken: "private-access-token",
    auth: { verified: true, userId: "owner-user" },
    appCheck: {
      verified: true,
      replayProtected: true,
      replayId,
    },
    owner: {
      userId: "owner-user",
      channelId: "UC_OWNER_123",
      status: "ACTIVE",
      grantedScopes: [YOUTUBE_ANALYTICS_READ_SCOPE],
    },
    ...overrides,
  };
}

export function enabledOptions(
  transport: HttpTransport,
  overrides: Partial<
    Omit<
      AnalyticsReportingClientOptions,
      "transport" | "quota" | "replayProtection" | "idempotency"
    >
  > = {},
): AnalyticsReportingClientOptions & {
  readonly quota: RecordingQuota;
  readonly replayProtection: RecordingReplayProtection;
  readonly idempotency: InMemoryIdempotency;
} {
  const quota = new RecordingQuota();
  const replayProtection = new RecordingReplayProtection();
  const idempotency = new InMemoryIdempotency();
  return {
    transport,
    quota,
    replayProtection,
    idempotency,
    enabled: true,
    now: () => new Date("2026-07-25T00:00:00.000Z"),
    ...overrides,
  };
}
