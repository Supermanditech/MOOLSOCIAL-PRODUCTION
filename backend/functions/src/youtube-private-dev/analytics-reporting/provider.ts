import { assertProviderResponse } from "../../youtube/errors.js";
import type {
  HttpTransport,
  HttpTransportRequest,
  HttpTransportResponse,
} from "../../youtube/types.js";
import { YouTubeAnalyticsReportingError } from "./contracts.js";

export const ANALYTICS_API_ORIGIN =
  "https://youtubeanalytics.googleapis.com";
export const REPORTING_API_ORIGIN =
  "https://youtubereporting.googleapis.com";

const PAGE_TOKEN = /^[A-Za-z0-9._~-]{1,512}$/u;
const RESOURCE_ID = /^[A-Za-z0-9._:-]{1,256}$/u;
const VIDEO_ID = /^[A-Za-z0-9_-]{6,20}$/u;
const CHANNEL_ID = /^[A-Za-z0-9_-]{6,64}$/u;
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/u;

interface ErrorEnvelope {
  readonly error?: {
    readonly errors?: readonly { readonly reason?: string }[];
    readonly status?: string;
  };
}

function providerReason(body: string): string | undefined {
  try {
    const parsed = JSON.parse(body) as ErrorEnvelope;
    return parsed.error?.errors?.[0]?.reason ?? parsed.error?.status;
  } catch {
    return undefined;
  }
}

export async function sendProviderRequest(
  transport: HttpTransport,
  request: HttpTransportRequest,
): Promise<HttpTransportResponse> {
  const response = await transport.send(request);
  if (response.status === 403) {
    const reason = providerReason(response.body);
    if (
      reason === "insufficientPermissions" ||
      reason === "forbidden" ||
      reason === "youtubeSignupRequired" ||
      reason === "reportingNotEnabled" ||
      reason === "channelNotFound"
    ) {
      throw new YouTubeAnalyticsReportingError(
        "eligibility_required",
        "This YouTube channel is not eligible for the requested analytics or reporting capability.",
        403,
        false,
        reason,
      );
    }
  }
  if (response.status === 409) {
    throw new YouTubeAnalyticsReportingError(
      "status_conflict",
      "The YouTube resource is not in a compatible state.",
      409,
      false,
      providerReason(response.body),
    );
  }
  assertProviderResponse(response.status, response.body);
  return response;
}

export function parseProviderJson<T>(body: string): T {
  try {
    return JSON.parse(body) as T;
  } catch {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an unreadable analytics or reporting response.",
      502,
    );
  }
}

export function clientPageToken(value: string | undefined): string | undefined {
  const clean = value?.trim();
  if (!clean) return undefined;
  if (!PAGE_TOKEN.test(clean)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      "The page token is invalid.",
      400,
    );
  }
  return clean;
}

export function providerPageToken(value: unknown): string | undefined {
  if (value === undefined) return undefined;
  if (typeof value !== "string" || !PAGE_TOKEN.test(value)) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      "YouTube returned an invalid page token.",
      502,
    );
  }
  return value;
}

export function clientResourceId(value: string, label: string): string {
  const clean = value.trim();
  if (!RESOURCE_ID.test(clean)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `A valid ${label} identifier is required.`,
      400,
    );
  }
  return clean;
}

export function providerResourceId(value: unknown, label: string): string {
  if (typeof value !== "string" || !RESOURCE_ID.test(value)) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      `YouTube returned an invalid ${label}.`,
      502,
    );
  }
  return value;
}

export function clientVideoId(value: string): string {
  const clean = value.trim();
  if (!VIDEO_ID.test(clean)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      "A valid video identifier is required.",
      400,
    );
  }
  return clean;
}

export function clientChannelId(value: string): string {
  const clean = value.trim();
  if (!CHANNEL_ID.test(clean)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      "A valid channel identifier is required.",
      400,
    );
  }
  return clean;
}

export function clientTitle(value: string, maximum: number): string {
  const clean = value.normalize("NFC").trim();
  if (
    clean.length < 1 ||
    clean.length > maximum ||
    /[\u0000-\u001f\u007f-\u009f]/u.test(clean)
  ) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `The title must contain between 1 and ${maximum} supported characters.`,
      400,
    );
  }
  return clean;
}

export function providerText(
  value: unknown,
  label: string,
  maximum = 1000,
): string {
  if (
    typeof value !== "string" ||
    !value.trim() ||
    value.length > maximum ||
    /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f-\u009f]/u.test(value)
  ) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      `YouTube returned invalid ${label}.`,
      502,
    );
  }
  return value;
}

export function clientDate(value: string, label: string): string {
  if (!ISO_DATE.test(value)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `${label} must use YYYY-MM-DD.`,
      400,
    );
  }
  const timestamp = new Date(`${value}T00:00:00.000Z`);
  if (
    !Number.isFinite(timestamp.getTime()) ||
    timestamp.toISOString().slice(0, 10) !== value
  ) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `${label} must be a real calendar date.`,
      400,
    );
  }
  return value;
}

export function clientTimestamp(value: string, label: string): string {
  const clean = value.trim();
  const timestamp = Date.parse(clean);
  if (!clean || !Number.isFinite(timestamp)) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `${label} must be an ISO-8601 timestamp.`,
      400,
    );
  }
  return new Date(timestamp).toISOString();
}

export function providerTimestamp(
  value: unknown,
  label: string,
): string {
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value))) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      `YouTube returned invalid ${label}.`,
      502,
    );
  }
  return new Date(Date.parse(value)).toISOString();
}

export function boundedInteger(
  value: number | undefined,
  fallback: number,
  minimum: number,
  maximum: number,
  label: string,
): number {
  const selected = value ?? fallback;
  if (
    !Number.isSafeInteger(selected) ||
    selected < minimum ||
    selected > maximum
  ) {
    throw new YouTubeAnalyticsReportingError(
      "bad_request",
      `${label} must be between ${minimum} and ${maximum}.`,
      400,
    );
  }
  return selected;
}

export function nonNegativeProviderInteger(
  value: unknown,
  label: string,
): number {
  const numeric =
    typeof value === "string" && /^\d+$/u.test(value)
      ? Number(value)
      : value;
  if (!Number.isSafeInteger(numeric) || (numeric as number) < 0) {
    throw new YouTubeAnalyticsReportingError(
      "provider_rejected",
      `YouTube returned invalid ${label}.`,
      502,
    );
  }
  return numeric as number;
}

export function daysInclusive(startDate: string, endDate: string): number {
  return (
    Math.floor(
      (Date.parse(`${endDate}T00:00:00.000Z`) -
        Date.parse(`${startDate}T00:00:00.000Z`)) /
        (24 * 60 * 60 * 1000),
    ) + 1
  );
}
