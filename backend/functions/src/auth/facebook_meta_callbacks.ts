import { createHmac, timingSafeEqual } from "node:crypto";

const META_FORM_CONTENT_TYPE = "application/x-www-form-urlencoded";
const META_SIGNED_REQUEST_ALGORITHM = "HMAC-SHA256";
const DATA_DELETION_STATUS_URL = "https://moolsocial.com/delete-account/";
const MAX_SIGNED_REQUEST_LENGTH = 8192;

export const FACEBOOK_META_CALLBACK_MAX_REQUEST_BODY_BYTES = 12 * 1024;

export type FacebookMetaCallbackErrorCode =
  | "invalid_request"
  | "invalid_signature"
  | "account_cleanup_failed"
  | "account_erasure_failed";

export class FacebookMetaCallbackError extends Error {
  constructor(
    readonly code: FacebookMetaCallbackErrorCode,
    message: string,
    readonly httpStatus: number,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = "FacebookMetaCallbackError";
  }
}

export interface FacebookProviderAccountCleaner {
  removeProviderAccess(providerUid: string): Promise<void>;
}

export interface FacebookProviderAccountEraser {
  requestAccountErasure(
    providerUid: string,
    confirmationCode: string,
  ): Promise<void>;
}

export interface FacebookMetaCallbackServiceOptions {
  readonly appSecret: string;
  readonly accountCleaner: FacebookProviderAccountCleaner;
  readonly accountEraser: FacebookProviderAccountEraser;
}

export type FacebookMetaCallbackResult =
  | { readonly operation: "deauthorize" }
  | {
      readonly operation: "data_deletion";
      readonly statusUrl: string;
      readonly confirmationCode: string;
    };

function fail(
  code: FacebookMetaCallbackErrorCode,
  message: string,
  httpStatus: number,
  retryable: boolean,
): never {
  throw new FacebookMetaCallbackError(code, message, httpStatus, retryable);
}

function invalidRequest(): never {
  fail(
    "invalid_request",
    "The Facebook callback request is invalid.",
    400,
    false,
  );
}

function objectValue(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function strictBase64Url(value: string): Buffer | undefined {
  if (!/^[A-Za-z0-9_-]+$/u.test(value)) return undefined;
  try {
    const decoded = Buffer.from(value, "base64url");
    return decoded.length > 0 && decoded.toString("base64url") === value
      ? decoded
      : undefined;
  } catch {
    return undefined;
  }
}

function formSignedRequest(
  rawBody: Uint8Array,
  contentType: string | undefined,
): string {
  const normalizedType = contentType?.split(";", 1)[0]?.trim().toLowerCase();
  if (
    normalizedType !== META_FORM_CONTENT_TYPE ||
    rawBody.byteLength === 0 ||
    rawBody.byteLength > FACEBOOK_META_CALLBACK_MAX_REQUEST_BODY_BYTES
  ) {
    invalidRequest();
  }
  const formText = Buffer.from(rawBody).toString("utf8");
  if (formText.includes("\uFFFD") || /[\u0000-\u001F\u007F]/u.test(formText)) {
    invalidRequest();
  }
  const entries = [...new URLSearchParams(formText).entries()];
  if (
    entries.length !== 1 ||
    entries[0]?.[0] !== "signed_request" ||
    entries[0][1].length === 0 ||
    entries[0][1].length > MAX_SIGNED_REQUEST_LENGTH
  ) {
    invalidRequest();
  }
  return entries[0][1];
}

function verifiedSubject(signedRequest: string, secret: Buffer): string {
  const segments = signedRequest.split(".");
  if (segments.length !== 2) invalidRequest();
  const encodedSignature = segments[0] ?? "";
  const encodedPayload = segments[1] ?? "";
  const signature = strictBase64Url(encodedSignature);
  const payloadBytes = strictBase64Url(encodedPayload);
  if (!signature || !payloadBytes) invalidRequest();
  const expected = createHmac("sha256", secret)
    .update(encodedPayload, "utf8")
    .digest();
  if (
    signature.length !== expected.length ||
    !timingSafeEqual(signature, expected)
  ) {
    fail(
      "invalid_signature",
      "The Facebook callback signature is invalid.",
      403,
      false,
    );
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(payloadBytes.toString("utf8"));
  } catch {
    invalidRequest();
  }
  const payload = objectValue(parsed);
  if (
    !payload ||
    payload.algorithm !== META_SIGNED_REQUEST_ALGORITHM ||
    typeof payload.user_id !== "string" ||
    !/^[0-9]{1,32}$/u.test(payload.user_id)
  ) {
    invalidRequest();
  }
  return payload.user_id;
}

function operation(path: string): FacebookMetaCallbackResult["operation"] {
  if (path === "/facebook/deauthorize") return "deauthorize";
  if (path === "/facebook/data-deletion") return "data_deletion";
  invalidRequest();
}

export class FacebookMetaCallbackService {
  private readonly appSecret: Buffer;
  private readonly accountCleaner: FacebookProviderAccountCleaner;
  private readonly accountEraser: FacebookProviderAccountEraser;

  constructor(options: FacebookMetaCallbackServiceOptions) {
    const secret = options.appSecret.trim();
    if (secret.length < 16 || secret.length > 1024) {
      throw new Error("Facebook Meta callback configuration is invalid.");
    }
    this.appSecret = Buffer.from(secret, "utf8");
    this.accountCleaner = options.accountCleaner;
    this.accountEraser = options.accountEraser;
  }

  async execute(
    path: string,
    rawBody: Uint8Array,
    contentType: string | undefined,
  ): Promise<FacebookMetaCallbackResult> {
    const callbackOperation = operation(path);
    const subject = verifiedSubject(
      formSignedRequest(rawBody, contentType),
      this.appSecret,
    );
    if (callbackOperation === "deauthorize") {
      try {
        await this.accountCleaner.removeProviderAccess(subject);
      } catch {
        fail(
          "account_cleanup_failed",
          "The Facebook account data could not be removed.",
          503,
          true,
        );
      }
      return { operation: callbackOperation };
    }
    const confirmationCode = createHmac("sha256", this.appSecret)
      .update("moolsocial-facebook-data-deletion\0", "utf8")
      .update(subject, "utf8")
      .digest("base64url")
      .slice(0, 32);
    try {
      await this.accountEraser.requestAccountErasure(
        subject,
        confirmationCode,
      );
    } catch {
      fail(
        "account_erasure_failed",
        "The Facebook account deletion request is still pending.",
        503,
        true,
      );
    }
    const statusUrl = new URL(DATA_DELETION_STATUS_URL);
    statusUrl.searchParams.set("confirmation_code", confirmationCode);
    return {
      operation: callbackOperation,
      statusUrl: statusUrl.toString(),
      confirmationCode,
    };
  }
}
