import { createHash } from "node:crypto";

import {
  YOUTUBE_ANALYTICS_MONETARY_READ_SCOPE,
  YOUTUBE_ANALYTICS_READ_SCOPE,
  YouTubeAnalyticsReportingError,
  type AnalyticsReportingClientOptions,
  type VerifiedOwnerInvocation,
} from "./contracts.js";

const SAFE_IDENTITY = /^[A-Za-z0-9._:-]{1,160}$/u;
const SAFE_CHANNEL_ID = /^[A-Za-z0-9_-]{6,64}$/u;
const IDEMPOTENCY_KEY = /^[A-Za-z0-9._:-]{8,128}$/u;

function safeIdentity(value: string, label: string): string {
  const clean = value.trim();
  if (!SAFE_IDENTITY.test(clean)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `A valid ${label} is required.`,
      400,
    );
  }
  return clean;
}

function stableValue(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(stableValue);
  if (typeof value !== "object" || value === null) return value;
  return Object.fromEntries(
    Object.entries(value as Record<string, unknown>)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, entry]) => [key, stableValue(entry)]),
  );
}

export function operationFingerprint(
  operation: string,
  input: unknown,
): string {
  return createHash("sha256")
    .update(
      JSON.stringify({
        operation: safeIdentity(operation, "operation"),
        input: stableValue(input),
      }),
    )
    .digest("hex");
}

export function requireAdapterEnabled(
  options: AnalyticsReportingClientOptions,
): void {
  if (options.enabled !== true) {
    throw new YouTubeAnalyticsReportingError(
      "capability_disabled",
      "YouTube analytics and reporting are disabled in private Dev.",
      503,
    );
  }
}

export async function authorizeOwnerInvocation(
  options: AnalyticsReportingClientOptions,
  invocation: VerifiedOwnerInvocation,
): Promise<void> {
  requireAdapterEnabled(options);
  const principal = safeIdentity(invocation.principal, "principal");
  const requestId = safeIdentity(invocation.requestId, "request identifier");

  if (
    invocation.auth.verified !== true ||
    !SAFE_IDENTITY.test(invocation.auth.userId)
  ) {
    throw new YouTubeAnalyticsReportingError(
      "authentication_required",
      "Sign in to continue.",
      401,
    );
  }
  if (
    invocation.owner.userId !== invocation.auth.userId ||
    !SAFE_CHANNEL_ID.test(invocation.owner.channelId)
  ) {
    throw new YouTubeAnalyticsReportingError(
      "authentication_required",
      "Reconnect the selected YouTube channel.",
      401,
    );
  }
  if (invocation.owner.status !== "ACTIVE") {
    throw new YouTubeAnalyticsReportingError(
      "status_conflict",
      "The selected YouTube connection is not active.",
      409,
    );
  }
  if (
    invocation.appCheck.verified !== true ||
    invocation.appCheck.replayProtected !== true
  ) {
    throw new YouTubeAnalyticsReportingError(
      "app_check_required",
      "App verification is required.",
      401,
    );
  }
  const replayId = safeIdentity(
    invocation.appCheck.replayId,
    "replay identifier",
  );
  if (!invocation.accessToken.trim()) {
    throw new YouTubeAnalyticsReportingError(
      "authentication_required",
      "Reconnect the selected YouTube channel.",
      401,
    );
  }
  const scopes = new Set(
    invocation.owner.grantedScopes.map((scope) => scope.trim()),
  );
  if (
    !scopes.has(YOUTUBE_ANALYTICS_READ_SCOPE) &&
    !(
      options.monetaryMetricsEnabled === true &&
      scopes.has(YOUTUBE_ANALYTICS_MONETARY_READ_SCOPE)
    )
  ) {
    throw new YouTubeAnalyticsReportingError(
      "scope_required",
      "Reconnect YouTube and approve analytics read access.",
      403,
    );
  }
  const consumed = await options.replayProtection.consume(
    `${invocation.auth.userId}:${replayId}`,
  );
  if (!consumed) {
    throw new YouTubeAnalyticsReportingError(
      "replay_detected",
      "App verification has expired. Try again.",
      401,
    );
  }

  // Keep validation variables live so accidental removal is caught by linting
  // or review even though provider calls use the original values.
  void principal;
  void requestId;
}

export async function idempotentMutation<T>(
  options: AnalyticsReportingClientOptions,
  namespace: string,
  idempotencyKey: string,
  input: unknown,
  action: () => Promise<T>,
): Promise<T> {
  const cleanNamespace = safeIdentity(namespace, "idempotency namespace");
  const cleanKey = idempotencyKey.trim();
  if (!IDEMPOTENCY_KEY.test(cleanKey)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      "A valid idempotency key is required.",
      400,
    );
  }
  const fingerprint = operationFingerprint(cleanNamespace, input);
  const reservation = await options.idempotency.reserve(
    cleanNamespace,
    cleanKey,
    fingerprint,
  );
  if (reservation.state === "completed") {
    return reservation.result as T;
  }
  if (
    reservation.state === "conflict" ||
    reservation.state === "in_progress"
  ) {
    throw new YouTubeAnalyticsReportingError(
      "idempotency_conflict",
      "This idempotency key is already bound to another or incomplete action.",
      409,
      reservation.state === "in_progress",
    );
  }
  try {
    const result = await action();
    await options.idempotency.complete(
      cleanNamespace,
      cleanKey,
      fingerprint,
      result,
    );
    return result;
  } catch (error) {
    await options.idempotency.release(
      cleanNamespace,
      cleanKey,
      fingerprint,
    );
    throw error;
  }
}
