import { Buffer } from "node:buffer";

import { YouTubeProviderError } from "./errors.js";

export const YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES = 64 * 1024;

/**
 * Enforces the byte limit against the bytes received by the HTTP runtime.
 *
 * This must be called with Firebase/Express `request.rawBody`, never with a
 * re-serialized JavaScript object. Re-serialization is not an accurate measure
 * of the request that crossed the trust boundary.
 */
export function assertRawRequestBodyWithinLimit(
  rawBody: unknown,
  maximumBytes = YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES,
): number {
  if (!Number.isSafeInteger(maximumBytes) || maximumBytes < 1) {
    throw new Error("The request body byte limit is invalid.");
  }

  let byteLength: number;
  if (Buffer.isBuffer(rawBody)) {
    byteLength = rawBody.byteLength;
  } else if (rawBody instanceof Uint8Array) {
    byteLength = rawBody.byteLength;
  } else if (typeof rawBody === "string") {
    byteLength = Buffer.byteLength(rawBody, "utf8");
  } else {
    throw new YouTubeProviderError(
      "bad_request",
      "The raw request body is unavailable.",
      400,
    );
  }

  if (byteLength > maximumBytes) {
    throw new YouTubeProviderError(
      "bad_request",
      "The request is too large.",
      413,
    );
  }
  return byteLength;
}
