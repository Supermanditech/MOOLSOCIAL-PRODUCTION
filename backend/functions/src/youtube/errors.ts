export type YouTubeProviderErrorCode =
  | "bad_request"
  | "authentication_required"
  | "permission_denied"
  | "capability_disabled"
  | "quota_exhausted"
  | "rate_limited"
  | "provider_unavailable"
  | "provider_rejected"
  | "not_found"
  | "conflict"
  | "internal";

export class YouTubeProviderError extends Error {
  constructor(
    readonly code: YouTubeProviderErrorCode,
    message: string,
    readonly httpStatus: number,
    readonly retryable = false,
    readonly providerReason?: string,
  ) {
    super(message);
    this.name = "YouTubeProviderError";
  }
}

interface ProviderErrorBody {
  error?: {
    code?: number;
    message?: string;
    errors?: Array<{ reason?: string }>;
  };
}

function parseProviderReason(body: string): string | undefined {
  try {
    const parsed = JSON.parse(body) as ProviderErrorBody;
    return parsed.error?.errors?.[0]?.reason;
  } catch {
    return undefined;
  }
}

export function mapYouTubeHttpError(
  status: number,
  body: string,
): YouTubeProviderError {
  const reason = parseProviderReason(body);
  if (
    reason === "quotaExceeded" ||
    reason === "dailyLimitExceeded" ||
    reason === "dailyLimitExceededUnreg"
  ) {
    return new YouTubeProviderError(
      "quota_exhausted",
      "YouTube capacity is unavailable for the rest of this quota window.",
      429,
      false,
      reason,
    );
  }
  if (status === 429 || reason === "rateLimitExceeded" || reason === "userRateLimitExceeded") {
    return new YouTubeProviderError(
      "rate_limited",
      "YouTube is receiving too many requests. Try again shortly.",
      429,
      true,
      reason,
    );
  }
  if (status === 401) {
    return new YouTubeProviderError(
      "authentication_required",
      "Reconnect the selected YouTube channel.",
      401,
      false,
      reason,
    );
  }
  if (status === 403) {
    return new YouTubeProviderError(
      "permission_denied",
      "The selected YouTube channel has not granted this action.",
      403,
      false,
      reason,
    );
  }
  if (status === 404) {
    return new YouTubeProviderError(
      "not_found",
      "The requested YouTube resource is unavailable.",
      404,
      false,
      reason,
    );
  }
  if (status >= 500) {
    return new YouTubeProviderError(
      "provider_unavailable",
      "YouTube is temporarily unavailable.",
      503,
      true,
      reason,
    );
  }
  return new YouTubeProviderError(
    "provider_rejected",
    "YouTube could not complete this action.",
    400,
    false,
    reason,
  );
}

export function assertProviderResponse(
  status: number,
  body: string,
): void {
  if (status < 200 || status >= 300) {
    throw mapYouTubeHttpError(status, body);
  }
}
