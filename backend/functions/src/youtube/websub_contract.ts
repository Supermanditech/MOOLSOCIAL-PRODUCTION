import {
  createHash,
  timingSafeEqual,
} from "node:crypto";

export const YOUTUBE_WEBSUB_HUB_URL =
  "https://pubsubhubbub.appspot.com/";
export const YOUTUBE_APPROVED_CHANNEL_REFRESH_DEFAULT_ENABLED = false;
export const DEFAULT_DEV_YOUTUBE_WEBSUB_REFRESH_DAILY_CAP = 500;

const YOUTUBE_CHANNEL_ID_PATTERN = /^UC[A-Za-z0-9_-]{22}$/u;
const YOUTUBE_VIDEO_ID_PATTERN = /^[A-Za-z0-9_-]{11}$/u;
const WEBSUB_CAPABILITY_PATTERN = /^[A-Za-z0-9_-]{22,128}$/u;
const SHA256_HEX_PATTERN = /^[a-f0-9]{64}$/u;
const MIN_WEBSUB_SECRET_BYTES = 16;
const MAX_WEBSUB_SECRET_BYTES = 199;
const MIN_WEBSUB_LEASE_SECONDS = 60;
const MAX_WEBSUB_LEASE_SECONDS = 366 * 24 * 60 * 60;
const MAX_WEBSUB_CHALLENGE_CHARACTERS = 4_096;
const MAX_WEBSUB_DENIAL_REASON_CHARACTERS = 512;
const HOUR_MS = 60 * 60 * 1_000;
const RFC3339_PROVIDER_TIMESTAMP_PATTERN =
  /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,9}))?(Z|([+-])(\d{2}):(\d{2}))$/u;
const C0_OR_DELETE_CONTROL_PATTERN = /[\u0000-\u001f\u007f]/u;

export type YouTubeWebSubMode = "subscribe" | "unsubscribe";

export type YouTubeWebSubSubscriptionState =
  | "PENDING_SUBSCRIBE"
  | "ACTIVE"
  | "RENEWING"
  | "PENDING_UNSUBSCRIBE"
  | "UNSUBSCRIBED"
  | "DENIED"
  | "EXPIRED"
  | "ERROR";

export type YouTubeWebSubEventKind =
  | "UPSERT_CANDIDATE"
  | "DELETE_HINT";

export type YouTubeWebSubMaintenanceAction =
  | "NONE"
  | "SUBSCRIBE"
  | "RENEW"
  | "UNSUBSCRIBE"
  | "MARK_EXPIRED";

export interface YouTubeWebSubSubscribeRequest {
  readonly mode: "subscribe";
  readonly callbackBaseUrl: string;
  readonly capability: string;
  readonly channelId: string;
  readonly secret: string;
  readonly requestedLeaseSeconds: number;
}

export interface YouTubeWebSubUnsubscribeRequest {
  readonly mode: "unsubscribe";
  readonly callbackBaseUrl: string;
  readonly capability: string;
  readonly channelId: string;
}

export type YouTubeWebSubHubRequest =
  | YouTubeWebSubSubscribeRequest
  | YouTubeWebSubUnsubscribeRequest;

export interface YouTubeWebSubHubForm {
  readonly hubUrl: typeof YOUTUBE_WEBSUB_HUB_URL;
  readonly callbackUrl: string;
  readonly topicUrl: string;
  readonly contentType: "application/x-www-form-urlencoded";
  readonly body: string;
}

export interface YouTubeWebSubPendingIntent {
  readonly channelId: string;
  readonly topicUrl: string;
  readonly capabilityHash: string;
  readonly state: YouTubeWebSubSubscriptionState;
  readonly pendingMode?: YouTubeWebSubMode;
  readonly generation: number;
}

export type YouTubeWebSubQueryValue =
  | string
  | readonly string[]
  | undefined;

export type YouTubeWebSubQuery = Readonly<
  Record<string, YouTubeWebSubQueryValue>
>;

export interface YouTubeWebSubVerifiedLease {
  readonly kind: "SUBSCRIPTION_VERIFIED";
  readonly generation: number;
  readonly state: "ACTIVE";
  readonly verifiedAt: string;
  readonly leaseSeconds: number;
  readonly expiresAt: string;
  readonly renewAfter: string;
}

export interface YouTubeWebSubVerifiedUnsubscribe {
  readonly kind: "UNSUBSCRIPTION_VERIFIED";
  readonly generation: number;
  readonly state: "UNSUBSCRIBED";
  readonly verifiedAt: string;
}

export interface YouTubeWebSubDeniedTransition {
  readonly kind: "SUBSCRIPTION_DENIED";
  readonly generation: number;
  readonly state: "DENIED";
  readonly deniedAt: string;
  readonly reason?: string;
}

export type YouTubeWebSubVerificationTransition =
  | YouTubeWebSubVerifiedLease
  | YouTubeWebSubVerifiedUnsubscribe
  | YouTubeWebSubDeniedTransition;

export interface YouTubeWebSubAcceptedVerification {
  readonly accepted: true;
  readonly status: 200 | 204;
  readonly body: string;
  readonly transition: YouTubeWebSubVerificationTransition;
}

export interface YouTubeWebSubRejectedVerification {
  readonly accepted: false;
  readonly status: 404;
  readonly body: "";
  readonly reason:
    | "capability_mismatch"
    | "duplicate_parameter"
    | "invalid_challenge"
    | "invalid_lease"
    | "invalid_mode"
    | "invalid_pending_intent"
    | "topic_mismatch";
}

export type YouTubeWebSubVerificationDecision =
  | YouTubeWebSubAcceptedVerification
  | YouTubeWebSubRejectedVerification;

export interface YouTubeWebSubRenewalWindow {
  readonly leaseStartedAt: string;
  readonly expiresAt: string;
  readonly renewAfter: string;
  readonly leaseSeconds: number;
}

export interface YouTubeWebSubMaintenanceInput {
  readonly featureEnabled: boolean;
  readonly channelApproved: boolean;
  readonly state: YouTubeWebSubSubscriptionState;
  readonly now: Date;
  readonly expiresAt?: string;
  readonly renewAfter?: string;
  readonly nextAttemptAt?: string;
}

export interface YouTubeWebSubEventIdentity {
  readonly kind: YouTubeWebSubEventKind;
  readonly channelId: string;
  readonly videoId: string;
  readonly entryId: string;
  readonly providerTimestamp: string;
}

export interface YouTubeWebSubRefreshQuotaPlan {
  readonly projectBucket: "general";
  readonly subBudget: "approvedChannelRefresh";
  readonly projectUnits: number;
  readonly refreshUnits: number;
  readonly refreshDailyHardCap: number;
  readonly atomic: true;
  readonly reserveBeforeProviderCall: true;
}

function assertNonEmptyString(value: string, name: string): string {
  if (typeof value !== "string" || value.trim() === "") {
    throw new TypeError(`${name} must be a non-empty string.`);
  }
  return value;
}

function assertSafePositiveInteger(value: number, name: string): number {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new TypeError(`${name} must be a positive safe integer.`);
  }
  return value;
}

function dateMilliseconds(value: Date | string, name: string): number {
  const milliseconds =
    value instanceof Date ? value.getTime() : Date.parse(value);
  if (!Number.isFinite(milliseconds)) {
    throw new TypeError(`${name} must be a valid date.`);
  }
  return milliseconds;
}

function isoString(milliseconds: number, name: string): string {
  if (!Number.isSafeInteger(milliseconds)) {
    throw new TypeError(`${name} is outside the supported date range.`);
  }
  const value = new Date(milliseconds);
  if (!Number.isFinite(value.getTime())) {
    throw new TypeError(`${name} is outside the supported date range.`);
  }
  return value.toISOString();
}

export function assertYouTubeChannelId(channelId: string): string {
  if (!YOUTUBE_CHANNEL_ID_PATTERN.test(channelId)) {
    throw new TypeError("YouTube channel ID is invalid.");
  }
  return channelId;
}

export function assertYouTubeVideoId(videoId: string): string {
  if (!YOUTUBE_VIDEO_ID_PATTERN.test(videoId)) {
    throw new TypeError("YouTube video ID is invalid.");
  }
  return videoId;
}

export function assertYouTubeWebSubCapability(
  capability: string,
): string {
  if (!WEBSUB_CAPABILITY_PATTERN.test(capability)) {
    throw new TypeError(
      "WebSub callback capability must be 22 to 128 base64url characters.",
    );
  }
  return capability;
}

export function youtubeApprovedChannelTopicUrl(
  channelId: string,
): string {
  return (
    "https://www.youtube.com/feeds/videos.xml?channel_id=" +
    encodeURIComponent(assertYouTubeChannelId(channelId))
  );
}

function normalizedCallbackBaseUrl(value: string): string {
  assertNonEmptyString(value, "WebSub callback base URL");
  let parsed: URL;
  try {
    parsed = new URL(value);
  } catch {
    throw new TypeError("WebSub callback base URL is invalid.");
  }
  if (
    parsed.protocol !== "https:" ||
    parsed.username !== "" ||
    parsed.password !== "" ||
    parsed.hash !== "" ||
    parsed.search !== "" ||
    parsed.port !== "" ||
    parsed.hostname === ""
  ) {
    throw new TypeError(
      "WebSub callback base URL must be an HTTPS URL without credentials, " +
        "query or fragment.",
    );
  }
  const pathname = parsed.pathname.replace(/\/+$/u, "");
  if (pathname === "") {
    throw new TypeError(
      "WebSub callback base URL must include a function path.",
    );
  }
  parsed.pathname = pathname;
  return parsed.toString().replace(/\/$/u, "");
}

function assertWebSubSecret(secret: string): string {
  assertNonEmptyString(secret, "WebSub secret");
  const byteLength = Buffer.byteLength(secret, "utf8");
  if (
    byteLength < MIN_WEBSUB_SECRET_BYTES ||
    byteLength > MAX_WEBSUB_SECRET_BYTES ||
    !/^[A-Za-z0-9_-]+$/u.test(secret)
  ) {
    throw new TypeError(
      `WebSub secret must be ${MIN_WEBSUB_SECRET_BYTES} to ` +
        `${MAX_WEBSUB_SECRET_BYTES} base64url bytes.`,
    );
  }
  return secret;
}

function assertLeaseSeconds(value: number): number {
  assertSafePositiveInteger(value, "WebSub lease seconds");
  if (
    value < MIN_WEBSUB_LEASE_SECONDS ||
    value > MAX_WEBSUB_LEASE_SECONDS
  ) {
    throw new TypeError(
      `WebSub lease seconds must be between ` +
        `${MIN_WEBSUB_LEASE_SECONDS} and ${MAX_WEBSUB_LEASE_SECONDS}.`,
    );
  }
  return value;
}

export function buildYouTubeWebSubHubRequest(
  request: YouTubeWebSubHubRequest,
): YouTubeWebSubHubForm {
  const callbackBaseUrl = normalizedCallbackBaseUrl(
    request.callbackBaseUrl,
  );
  const capability = assertYouTubeWebSubCapability(request.capability);
  const callbackUrl =
    `${callbackBaseUrl}/${encodeURIComponent(capability)}`;
  const topicUrl = youtubeApprovedChannelTopicUrl(request.channelId);
  const parameters = new URLSearchParams();
  parameters.set("hub.callback", callbackUrl);
  parameters.set("hub.mode", request.mode);
  parameters.set("hub.topic", topicUrl);
  if (request.mode === "subscribe") {
    parameters.set(
      "hub.lease_seconds",
      String(assertLeaseSeconds(request.requestedLeaseSeconds)),
    );
    parameters.set("hub.secret", assertWebSubSecret(request.secret));
  }

  return {
    hubUrl: YOUTUBE_WEBSUB_HUB_URL,
    callbackUrl,
    topicUrl,
    contentType: "application/x-www-form-urlencoded",
    body: parameters.toString(),
  };
}

export function sha256Hex(value: string | Uint8Array): string {
  return createHash("sha256").update(value).digest("hex");
}

export function youtubeWebSubCapabilityHash(
  capability: string,
): string {
  return sha256Hex(assertYouTubeWebSubCapability(capability));
}

export function matchesYouTubeWebSubCapability(
  capability: string,
  expectedHash: string,
): boolean {
  let actualHash: string;
  try {
    actualHash = youtubeWebSubCapabilityHash(capability);
  } catch {
    return false;
  }
  if (!SHA256_HEX_PATTERN.test(expectedHash)) {
    return false;
  }
  return timingSafeEqual(
    Buffer.from(actualHash, "hex"),
    Buffer.from(expectedHash, "hex"),
  );
}

function deterministicJitterMilliseconds(
  seed: string,
  maximum: number,
): number {
  if (maximum <= 0) {
    return 0;
  }
  const digest = createHash("sha256").update(seed).digest();
  const sample = digest.readUInt32BE(0);
  return Math.floor((sample / 0x1_0000_0000) * (maximum + 1));
}

export function calculateYouTubeWebSubRenewalWindow(
  leaseStartedAt: Date,
  leaseSeconds: number,
  jitterSeed: string,
): YouTubeWebSubRenewalWindow {
  const startedAtMs = dateMilliseconds(
    leaseStartedAt,
    "WebSub lease start",
  );
  assertLeaseSeconds(leaseSeconds);
  assertNonEmptyString(jitterSeed, "WebSub renewal jitter seed");

  const leaseMilliseconds = leaseSeconds * 1_000;
  const expiresAtMs = startedAtMs + leaseMilliseconds;
  if (!Number.isSafeInteger(expiresAtMs)) {
    throw new TypeError("WebSub lease expiry is outside the supported range.");
  }

  const leadMilliseconds = Math.max(
    24 * HOUR_MS,
    Math.min(72 * HOUR_MS, Math.floor(leaseMilliseconds * 0.2)),
  );
  const maximumJitter = Math.min(
    6 * HOUR_MS,
    Math.floor(leaseMilliseconds * 0.05),
  );
  const jitterMilliseconds = deterministicJitterMilliseconds(
    jitterSeed,
    maximumJitter,
  );
  const earliestRenewalMs =
    startedAtMs +
    Math.min(
      Math.floor(leaseMilliseconds * 0.5),
      Math.max(60_000, Math.floor(leaseMilliseconds * 0.1)),
    );
  const latestRenewalMs =
    startedAtMs + Math.floor(leaseMilliseconds * 0.8);
  const desiredRenewalMs =
    expiresAtMs - leadMilliseconds - jitterMilliseconds;
  const renewAfterMs = Math.max(
    earliestRenewalMs,
    Math.min(latestRenewalMs, desiredRenewalMs),
  );

  return {
    leaseStartedAt: isoString(startedAtMs, "WebSub lease start"),
    expiresAt: isoString(expiresAtMs, "WebSub lease expiry"),
    renewAfter: isoString(renewAfterMs, "WebSub renewal time"),
    leaseSeconds,
  };
}

function singleQueryValue(
  query: YouTubeWebSubQuery,
  name: string,
): string | undefined | null {
  const value = query[name];
  if (typeof value !== "string" && value !== undefined) {
    return null;
  }
  return value;
}

function rejectedVerification(
  reason: YouTubeWebSubRejectedVerification["reason"],
): YouTubeWebSubRejectedVerification {
  return {
    accepted: false,
    status: 404,
    body: "",
    reason,
  };
}

function sanitizedDenialReason(
  value: string | undefined,
): string | undefined {
  if (value === undefined) {
    return undefined;
  }
  if (C0_OR_DELETE_CONTROL_PATTERN.test(value)) {
    return undefined;
  }
  const normalized = value.trim();
  if (
    normalized === "" ||
    normalized.length > MAX_WEBSUB_DENIAL_REASON_CHARACTERS
  ) {
    return undefined;
  }
  return normalized;
}

export function evaluateYouTubeWebSubVerification(
  capability: string,
  query: YouTubeWebSubQuery,
  intent: YouTubeWebSubPendingIntent,
  receivedAt: Date,
): YouTubeWebSubVerificationDecision {
  const receivedAtMs = dateMilliseconds(
    receivedAt,
    "WebSub verification receipt",
  );
  try {
    if (
      intent.topicUrl !==
        youtubeApprovedChannelTopicUrl(intent.channelId) ||
      !Number.isSafeInteger(intent.generation) ||
      intent.generation <= 0
    ) {
      return rejectedVerification("invalid_pending_intent");
    }
  } catch {
    return rejectedVerification("invalid_pending_intent");
  }
  if (
    !matchesYouTubeWebSubCapability(
      capability,
      intent.capabilityHash,
    )
  ) {
    return rejectedVerification("capability_mismatch");
  }

  const mode = singleQueryValue(query, "hub.mode");
  const topic = singleQueryValue(query, "hub.topic");
  const challenge = singleQueryValue(query, "hub.challenge");
  const lease = singleQueryValue(query, "hub.lease_seconds");
  const reason = singleQueryValue(query, "hub.reason");
  if (
    mode === null ||
    topic === null ||
    challenge === null ||
    lease === null ||
    reason === null
  ) {
    return rejectedVerification("duplicate_parameter");
  }
  if (topic !== intent.topicUrl) {
    return rejectedVerification("topic_mismatch");
  }

  if (mode === "denied") {
    if (
      intent.pendingMode !== "subscribe" ||
      (intent.state !== "PENDING_SUBSCRIBE" &&
        intent.state !== "RENEWING")
    ) {
      return rejectedVerification("invalid_pending_intent");
    }
    const denialReason = sanitizedDenialReason(reason);
    return {
      accepted: true,
      status: 204,
      body: "",
      transition: {
        kind: "SUBSCRIPTION_DENIED",
        generation: intent.generation,
        state: "DENIED",
        deniedAt: isoString(receivedAtMs, "WebSub denial time"),
        ...(denialReason === undefined
          ? {}
          : { reason: denialReason }),
      },
    };
  }

  if (mode !== "subscribe" && mode !== "unsubscribe") {
    return rejectedVerification("invalid_mode");
  }
  if (
    intent.pendingMode !== mode ||
    (mode === "subscribe" &&
      intent.state !== "PENDING_SUBSCRIBE" &&
      intent.state !== "RENEWING") ||
    (mode === "unsubscribe" &&
      intent.state !== "PENDING_UNSUBSCRIBE")
  ) {
    return rejectedVerification("invalid_pending_intent");
  }
  if (
    challenge === undefined ||
    challenge.length === 0 ||
    challenge.length > MAX_WEBSUB_CHALLENGE_CHARACTERS ||
    challenge.includes("\u0000")
  ) {
    return rejectedVerification("invalid_challenge");
  }

  if (mode === "unsubscribe") {
    return {
      accepted: true,
      status: 200,
      body: challenge,
      transition: {
        kind: "UNSUBSCRIPTION_VERIFIED",
        generation: intent.generation,
        state: "UNSUBSCRIBED",
        verifiedAt: isoString(
          receivedAtMs,
          "WebSub unsubscribe verification time",
        ),
      },
    };
  }

  if (lease === undefined || !/^[1-9][0-9]*$/u.test(lease)) {
    return rejectedVerification("invalid_lease");
  }
  const leaseSeconds = Number(lease);
  try {
    assertLeaseSeconds(leaseSeconds);
  } catch {
    return rejectedVerification("invalid_lease");
  }
  const renewal = calculateYouTubeWebSubRenewalWindow(
    new Date(receivedAtMs),
    leaseSeconds,
    `${intent.channelId}:${intent.generation}`,
  );
  return {
    accepted: true,
    status: 200,
    body: challenge,
    transition: {
      kind: "SUBSCRIPTION_VERIFIED",
      generation: intent.generation,
      state: "ACTIVE",
      verifiedAt: renewal.leaseStartedAt,
      leaseSeconds,
      expiresAt: renewal.expiresAt,
      renewAfter: renewal.renewAfter,
    },
  };
}

function optionalDateDue(
  value: string | undefined,
  nowMs: number,
): boolean {
  return value === undefined || dateMilliseconds(value, "WebSub due time") <= nowMs;
}

export function planYouTubeWebSubMaintenance(
  input: YouTubeWebSubMaintenanceInput,
): YouTubeWebSubMaintenanceAction {
  const nowMs = dateMilliseconds(input.now, "WebSub maintenance time");

  if (!input.featureEnabled || !input.channelApproved) {
    return input.state === "ACTIVE" ||
      input.state === "RENEWING" ||
      input.state === "PENDING_SUBSCRIBE" ||
      input.state === "PENDING_UNSUBSCRIBE"
      ? "UNSUBSCRIBE"
      : "NONE";
  }

  if (
    (input.state === "ACTIVE" || input.state === "RENEWING") &&
    input.expiresAt !== undefined &&
    dateMilliseconds(input.expiresAt, "WebSub lease expiry") <= nowMs
  ) {
    return "MARK_EXPIRED";
  }

  switch (input.state) {
    case "ACTIVE":
      return optionalDateDue(input.renewAfter, nowMs) ? "RENEW" : "NONE";
    case "RENEWING":
      return optionalDateDue(input.nextAttemptAt, nowMs)
        ? "RENEW"
        : "NONE";
    case "PENDING_SUBSCRIBE":
      return optionalDateDue(input.nextAttemptAt, nowMs)
        ? "SUBSCRIBE"
        : "NONE";
    case "PENDING_UNSUBSCRIBE":
      return optionalDateDue(input.nextAttemptAt, nowMs)
        ? "UNSUBSCRIBE"
        : "NONE";
    case "UNSUBSCRIBED":
    case "EXPIRED":
    case "ERROR":
      return optionalDateDue(input.nextAttemptAt, nowMs)
        ? "SUBSCRIBE"
        : "NONE";
    case "DENIED":
      return "NONE";
  }
}

function lengthPrefixed(value: string): string {
  return `${Buffer.byteLength(value, "utf8")}:${value}`;
}

function isLeapYear(year: number): boolean {
  return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
}

function daysInMonth(year: number, month: number): number {
  if (month === 2) {
    return isLeapYear(year) ? 29 : 28;
  }
  return [4, 6, 9, 11].includes(month) ? 30 : 31;
}

/**
 * Validates the strict RFC 3339 subset emitted by YouTube and canonicalizes
 * equivalent instants for durable idempotency keys.
 *
 * Leap-second `:60` values are rejected because the JavaScript runtime cannot
 * represent them without inventing a different instant. Provider precision up
 * to nine fractional digits is preserved, with insignificant trailing zeroes
 * removed.
 */
export function canonicalYouTubeWebSubProviderTimestamp(
  value: string,
): string {
  const match = RFC3339_PROVIDER_TIMESTAMP_PATTERN.exec(value);
  if (match === null) {
    throw new TypeError(
      "WebSub provider timestamp is not a supported RFC 3339 timestamp.",
    );
  }
  const [
    ,
    yearText,
    monthText,
    dayText,
    hourText,
    minuteText,
    secondText,
    fractionText,
    zoneText,
    signText,
    offsetHourText,
    offsetMinuteText,
  ] = match;
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  const hour = Number(hourText);
  const minute = Number(minuteText);
  const second = Number(secondText);
  const offsetHour = offsetHourText === undefined
    ? 0
    : Number(offsetHourText);
  const offsetMinute = offsetMinuteText === undefined
    ? 0
    : Number(offsetMinuteText);
  if (
    !Number.isInteger(year) ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > daysInMonth(year, month) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59 ||
    second < 0 ||
    second > 59 ||
    offsetHour < 0 ||
    offsetHour > 23 ||
    offsetMinute < 0 ||
    offsetMinute > 59
  ) {
    throw new TypeError(
      "WebSub provider timestamp is not a supported RFC 3339 timestamp.",
    );
  }

  const localSeconds = Date.parse(
    `${yearText}-${monthText}-${dayText}T` +
      `${hourText}:${minuteText}:${secondText}Z`,
  );
  if (!Number.isFinite(localSeconds)) {
    throw new TypeError(
      "WebSub provider timestamp is outside the supported date range.",
    );
  }
  const offsetSign = signText === "-" ? -1 : 1;
  const offsetMilliseconds =
    zoneText === "Z"
      ? 0
      : offsetSign *
        (offsetHour * 60 + offsetMinute) *
        60 *
        1_000;
  const instantMilliseconds = localSeconds - offsetMilliseconds;
  const canonicalSeconds = new Date(instantMilliseconds)
    .toISOString()
    .slice(0, 19);
  if (!/^\d{4}-\d{2}-\d{2}T/u.test(canonicalSeconds)) {
    throw new TypeError(
      "WebSub provider timestamp is outside the supported RFC 3339 year range.",
    );
  }
  const canonicalFraction = fractionText?.replace(/0+$/u, "") ?? "";
  return (
    canonicalSeconds +
    (canonicalFraction === "" ? "" : `.${canonicalFraction}`) +
    "Z"
  );
}

export function deriveYouTubeWebSubEventKey(
  identity: YouTubeWebSubEventIdentity,
): string {
  assertYouTubeChannelId(identity.channelId);
  assertYouTubeVideoId(identity.videoId);
  assertNonEmptyString(identity.entryId, "WebSub Atom entry ID");
  assertNonEmptyString(
    identity.providerTimestamp,
    "WebSub provider timestamp",
  );
  const canonicalTimestamp =
    canonicalYouTubeWebSubProviderTimestamp(identity.providerTimestamp);
  const expectedEntryId = `yt:video:${identity.videoId}`;
  if (identity.entryId !== expectedEntryId) {
    throw new TypeError(
      "WebSub Atom entry ID does not match the YouTube video ID.",
    );
  }
  const canonical = [
    "youtube-websub-event-v1",
    identity.kind,
    identity.channelId,
    identity.videoId,
    identity.entryId,
    canonicalTimestamp,
  ]
    .map(lengthPrefixed)
    .join("|");
  return sha256Hex(canonical);
}

export function planYouTubeWebSubRefreshQuota(
  units = 1,
  refreshDailyHardCap = DEFAULT_DEV_YOUTUBE_WEBSUB_REFRESH_DAILY_CAP,
): YouTubeWebSubRefreshQuotaPlan {
  assertSafePositiveInteger(units, "WebSub refresh quota units");
  assertSafePositiveInteger(
    refreshDailyHardCap,
    "WebSub refresh daily hard cap",
  );
  if (
    refreshDailyHardCap >
    DEFAULT_DEV_YOUTUBE_WEBSUB_REFRESH_DAILY_CAP
  ) {
    throw new TypeError(
      "WebSub refresh daily hard cap cannot exceed the reviewed Dev cap.",
    );
  }
  if (units > refreshDailyHardCap) {
    throw new TypeError(
      "WebSub refresh reservation cannot exceed its daily hard cap.",
    );
  }
  return {
    projectBucket: "general",
    subBudget: "approvedChannelRefresh",
    projectUnits: units,
    refreshUnits: units,
    refreshDailyHardCap,
    atomic: true,
    reserveBeforeProviderCall: true,
  };
}
