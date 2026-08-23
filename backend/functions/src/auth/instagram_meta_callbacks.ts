import { createHmac, timingSafeEqual } from "node:crypto";

import type { InstagramSubjectProjector } from "./instagram_oauth_broker.js";

const META_FORM_CONTENT_TYPE = "application/x-www-form-urlencoded";
const META_SIGNED_REQUEST_ALGORITHM = "HMAC-SHA256";
const DATA_DELETION_STATUS_URL = "https://moolsocial.com/delete-account/";
const MAX_SIGNED_REQUEST_LENGTH = 8192;

export const INSTAGRAM_META_CALLBACK_MAX_REQUEST_BODY_BYTES = 12 * 1024;

export type InstagramMetaCallbackErrorCode =
  | "invalid_request"
  | "invalid_signature"
  | "account_deletion_failed"
  | "account_erasure_failed";

export class InstagramMetaCallbackError extends Error {
  constructor(
    readonly code: InstagramMetaCallbackErrorCode,
    message: string,
    readonly httpStatus: number,
    readonly retryable: boolean,
  ) {
    super(message);
    this.name = "InstagramMetaCallbackError";
  }
}

export interface InstagramFirebaseUserDeleter {
  deleteUser(uid: string): Promise<void>;
}

export interface InstagramAccountEraser {
  requestAccountErasure(
    firebaseUid: string,
    confirmationCode: string,
  ): Promise<void>;
}

export interface InstagramMetaCallbackServiceOptions {
  readonly appSecret: string;
  readonly subjectProjector: InstagramSubjectProjector;
  readonly firebaseUserDeleter: InstagramFirebaseUserDeleter;
  readonly accountEraser: InstagramAccountEraser;
}

export type InstagramMetaCallbackResult =
  | { readonly operation: "deauthorize" }
  | {
      readonly operation: "data_deletion";
      readonly statusUrl: string;
      readonly confirmationCode: string;
    };

interface MetaSignedRequestPayload {
  readonly subject: string;
}

function callbackError(
  code: InstagramMetaCallbackErrorCode,
  message: string,
  httpStatus: number,
  retryable: boolean,
): never {
  throw new InstagramMetaCallbackError(
    code,
    message,
    httpStatus,
    retryable,
  );
}

function invalidRequest(): never {
  callbackError(
    "invalid_request",
    "The Instagram callback request is invalid.",
    400,
    false,
  );
}

function objectValue(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function normalizedContentType(value: string | undefined): string {
  return value?.split(";", 1)[0]?.trim().toLowerCase() ?? "";
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

function readSignedRequest(
  rawBody: Uint8Array,
  contentType: string | undefined,
): string {
  if (
    normalizedContentType(contentType) !== META_FORM_CONTENT_TYPE ||
    rawBody.byteLength === 0 ||
    rawBody.byteLength > INSTAGRAM_META_CALLBACK_MAX_REQUEST_BODY_BYTES
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

function verifySignedRequest(
  signedRequest: string,
  appSecret: Buffer,
): MetaSignedRequestPayload {
  const segments = signedRequest.split(".");
  if (segments.length !== 2) invalidRequest();
  const encodedSignature = segments[0] ?? "";
  const encodedPayload = segments[1] ?? "";
  const receivedSignature = strictBase64Url(encodedSignature);
  const payloadBytes = strictBase64Url(encodedPayload);
  if (!receivedSignature || !payloadBytes) invalidRequest();

  const expectedSignature = createHmac("sha256", appSecret)
    .update(encodedPayload, "utf8")
    .digest();
  if (
    receivedSignature.length !== expectedSignature.length ||
    !timingSafeEqual(receivedSignature, expectedSignature)
  ) {
    callbackError(
      "invalid_signature",
      "The Instagram callback signature is invalid.",
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
  return { subject: payload.user_id };
}

function callbackOperation(
  path: string,
): InstagramMetaCallbackResult["operation"] {
  if (path === "/instagram/deauthorize") return "deauthorize";
  if (path === "/instagram/data-deletion") return "data_deletion";
  invalidRequest();
}

function errorCode(value: unknown): string | undefined {
  const body = objectValue(value);
  return typeof body?.code === "string" ? body.code : undefined;
}

export class InstagramMetaCallbackService {
  private readonly appSecret: Buffer;
  private readonly subjectProjector: InstagramSubjectProjector;
  private readonly firebaseUserDeleter: InstagramFirebaseUserDeleter;
  private readonly accountEraser: InstagramAccountEraser;

  constructor(options: InstagramMetaCallbackServiceOptions) {
    const appSecret = options.appSecret.trim();
    if (appSecret.length < 16 || appSecret.length > 1024) {
      throw new Error("Instagram Meta callback configuration is invalid.");
    }
    this.appSecret = Buffer.from(appSecret, "utf8");
    this.subjectProjector = options.subjectProjector;
    this.firebaseUserDeleter = options.firebaseUserDeleter;
    this.accountEraser = options.accountEraser;
  }

  async execute(
    path: string,
    rawBody: Uint8Array,
    contentType: string | undefined,
  ): Promise<InstagramMetaCallbackResult> {
    const operation = callbackOperation(path);
    const signedRequest = readSignedRequest(rawBody, contentType);
    const payload = verifySignedRequest(signedRequest, this.appSecret);
    const firebaseUid = this.subjectProjector.project(payload.subject);
    if (operation === "deauthorize") {
      try {
        await this.firebaseUserDeleter.deleteUser(firebaseUid);
      } catch (error) {
        if (errorCode(error) !== "auth/user-not-found") {
          callbackError(
            "account_deletion_failed",
            "The Instagram account data could not be deleted.",
            503,
            true,
          );
        }
      }
      return { operation };
    }
    const confirmationCode = createHmac("sha256", this.appSecret)
      .update("moolsocial-instagram-data-deletion\0", "utf8")
      .update(payload.subject, "utf8")
      .digest("base64url")
      .slice(0, 32);
    try {
      await this.accountEraser.requestAccountErasure(
        firebaseUid,
        confirmationCode,
      );
    } catch {
      callbackError(
        "account_erasure_failed",
        "The Instagram account deletion request is still pending.",
        503,
        true,
      );
    }
    const statusUrl = new URL(DATA_DELETION_STATUS_URL);
    statusUrl.searchParams.set("confirmation_code", confirmationCode);
    return {
      operation,
      statusUrl: statusUrl.toString(),
      confirmationCode,
    };
  }
}
