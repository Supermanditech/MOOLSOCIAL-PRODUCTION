export const REDACTED_SECRET = "[REDACTED]";
export const REDACTED_RESUMABLE_SESSION_URL =
  "[REDACTED_RESUMABLE_SESSION_URL]";
export const REDACTED_CIRCULAR_REFERENCE = "[CIRCULAR]";

const SECRET_HEADER_NAMES = new Set([
  "authorization",
  "proxyauthorization",
  "xgoogapikey",
  "xapikey",
  "apikey",
  "cookie",
  "setcookie",
]);

const SECRET_FIELD_NAMES = new Set([
  "accesstoken",
  "refreshtoken",
  "idtoken",
  "oauthtoken",
  "token",
  "authorization",
  "clientsecret",
  "apikey",
  "xgoogapikey",
  "codeverifier",
  "oauthcode",
  "authorizationcode",
  "sessionurl",
  "resumablesessionurl",
  "encryptedsessionurl",
  "uploadid",
  "streamname",
  "streamkey",
  "ingestionkey",
]);

const RESUMABLE_SESSION_URL =
  /https?:\/\/(?:upload\.youtube\.com|[a-z0-9.-]*googleapis\.com)\/[^\s"'<>]*upload\/youtube\/[^\s"'<>]*/giu;

function normalizedName(name: string): string {
  return name.toLowerCase().replace(/[^a-z0-9]/gu, "");
}

function looksLikeOAuthCode(value: string): boolean {
  return (
    value.startsWith("4/") ||
    value.startsWith("1//") ||
    /^[A-Za-z0-9_-]{24,}$/u.test(value)
  );
}

function secretField(name: string, value: unknown): boolean {
  const normalized = normalizedName(name);
  if (SECRET_FIELD_NAMES.has(normalized)) {
    return true;
  }
  if (normalized === "key" && typeof value === "string") {
    return true;
  }
  return (
    normalized === "code" &&
    typeof value === "string" &&
    looksLikeOAuthCode(value)
  );
}

export function redactText(value: string): string {
  return value
    .replace(RESUMABLE_SESSION_URL, REDACTED_RESUMABLE_SESSION_URL)
    .replace(
      /\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+/giu,
      `$1 ${REDACTED_SECRET}`,
    )
    .replace(
      /\b(authorization|proxy-authorization|x-goog-api-key|x-api-key|api-key)\s*:\s*[^\s,;]+/giu,
      `$1: ${REDACTED_SECRET}`,
    )
    .replace(/\bAIza[0-9A-Za-z_-]{20,}\b/gu, REDACTED_SECRET)
    .replace(
      /([?&](?:key|api_key|apiKey|access_token|refresh_token|id_token|oauth_token|client_secret|code|upload_id|stream_name|streamName|stream_key|streamKey|ingestion_key|ingestionKey)=)[^&#\s]+/giu,
      `$1${REDACTED_SECRET}`,
    )
    .replace(
      /("(?:access_token|refresh_token|id_token|oauth_token|client_secret|api[_-]?key|authorization|oauth[_-]?code|authorization[_-]?code|session[_-]?url|upload[_-]?id|stream[_-]?(?:name|key)|ingestion[_-]?key)"\s*:\s*")[^"]*(")/giu,
      `$1${REDACTED_SECRET}$2`,
    );
}

export function redactHeaders(
  headers: Readonly<Record<string, string>>,
): Record<string, string> {
  const redacted: Record<string, string> = {};
  for (const [name, value] of Object.entries(headers)) {
    redacted[name] = SECRET_HEADER_NAMES.has(normalizedName(name))
      ? REDACTED_SECRET
      : redactText(value);
  }
  return redacted;
}

function isObject(value: unknown): value is object {
  return typeof value === "object" && value !== null;
}

function redactValue(value: unknown, seen: WeakSet<object>): unknown {
  if (typeof value === "string") {
    return redactText(value);
  }
  if (!isObject(value)) {
    return value;
  }
  if (seen.has(value)) {
    return REDACTED_CIRCULAR_REFERENCE;
  }
  seen.add(value);

  if (value instanceof Date) {
    return value.toISOString();
  }
  if (value instanceof Error) {
    const result: Record<string, unknown> = {
      name: value.name,
      message: redactText(value.message),
    };
    if (value.stack !== undefined) {
      result.stack = redactText(value.stack);
    }
    return result;
  }
  if (Array.isArray(value)) {
    return value.map((item) => redactValue(item, seen));
  }

  const result: Record<string, unknown> = {};
  for (const [name, item] of Object.entries(value)) {
    if (secretField(name, item)) {
      result[name] = REDACTED_SECRET;
    } else if (
      normalizedName(name) === "headers" &&
      isObject(item) &&
      !Array.isArray(item)
    ) {
      const headers: Record<string, string> = {};
      for (const [headerName, headerValue] of Object.entries(item)) {
        headers[headerName] =
          typeof headerValue === "string"
            ? headerValue
            : String(headerValue);
      }
      result[name] = redactHeaders(headers);
    } else {
      result[name] = redactValue(item, seen);
    }
  }
  return result;
}

/**
 * Produces a log-safe copy. The original input is never mutated.
 */
export function redactSensitiveData(value: unknown): unknown {
  return redactValue(value, new WeakSet<object>());
}
