import {
  createHmac,
  timingSafeEqual,
} from "node:crypto";

import {
  assertYouTubeChannelId,
} from "./websub_contract.js";

export const DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES = 262_144;

const MIN_ROOT_KEY_BYTES = 32;
const MAX_WEBSUB_SECRET_BYTES = 199;
const SIGNATURE_PATTERN =
  /^(sha1|sha256|sha384|sha512)=([a-fA-F0-9]+)$/u;

export type YouTubeWebSubSignatureAlgorithm =
  | "sha1"
  | "sha256"
  | "sha384"
  | "sha512";

export type YouTubeWebSubSignatureDecision =
  | {
      readonly valid: true;
      readonly algorithm: YouTubeWebSubSignatureAlgorithm;
    }
  | {
      readonly valid: false;
      readonly reason:
        | "body_too_large"
        | "invalid_header"
        | "invalid_secret"
        | "missing_header"
        | "signature_mismatch";
    };

function safeMaximumBytes(value: number | undefined): number {
  const resolved = value ?? DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES;
  if (
    !Number.isSafeInteger(resolved) ||
    resolved <= 0 ||
    resolved > DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES
  ) {
    throw new TypeError(
      "WebSub raw-body limit must be a positive integer no greater than " +
        `${DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES}.`,
    );
  }
  return resolved;
}

export function isYouTubeWebSubRawBodyBounded(
  rawBody: Uint8Array,
  maximumBytes?: number,
): boolean {
  return rawBody.byteLength <= safeMaximumBytes(maximumBytes);
}

export function deriveYouTubeWebSubSubscriptionSecret(
  rootKey: Uint8Array,
  channelId: string,
  generation: number,
): string {
  if (rootKey.byteLength < MIN_ROOT_KEY_BYTES) {
    throw new TypeError(
      `WebSub root key must contain at least ${MIN_ROOT_KEY_BYTES} bytes.`,
    );
  }
  if (!Number.isSafeInteger(generation) || generation <= 0) {
    throw new TypeError(
      "WebSub secret generation must be a positive safe integer.",
    );
  }
  const channel = assertYouTubeChannelId(channelId);
  return createHmac("sha256", rootKey)
    .update(`youtube-websub-secret-v1:${channel}:${generation}`)
    .digest("base64url");
}

export function verifyYouTubeWebSubPayloadSignature(
  rawBody: Uint8Array,
  signatureHeader: string | undefined,
  secret: string,
  maximumBytes?: number,
): YouTubeWebSubSignatureDecision {
  if (!isYouTubeWebSubRawBodyBounded(rawBody, maximumBytes)) {
    return { valid: false, reason: "body_too_large" };
  }
  const secretBytes = Buffer.byteLength(secret, "utf8");
  if (secretBytes < 16 || secretBytes > MAX_WEBSUB_SECRET_BYTES) {
    return { valid: false, reason: "invalid_secret" };
  }
  if (signatureHeader === undefined) {
    return { valid: false, reason: "missing_header" };
  }
  const match = SIGNATURE_PATTERN.exec(signatureHeader);
  if (match === null) {
    return { valid: false, reason: "invalid_header" };
  }
  const algorithm = match[1] as
    | YouTubeWebSubSignatureAlgorithm
    | undefined;
  const suppliedHex = match[2];
  if (algorithm === undefined || suppliedHex === undefined) {
    return { valid: false, reason: "invalid_header" };
  }
  const expectedHexLength =
    algorithm === "sha1"
      ? 40
      : algorithm === "sha256"
        ? 64
        : algorithm === "sha384"
          ? 96
          : 128;
  if (suppliedHex.length !== expectedHexLength) {
    return { valid: false, reason: "invalid_header" };
  }

  const supplied = Buffer.from(suppliedHex, "hex");
  const expected = createHmac(algorithm, secret)
    .update(rawBody)
    .digest();
  if (
    supplied.byteLength !== expected.byteLength ||
    !timingSafeEqual(supplied, expected)
  ) {
    return { valid: false, reason: "signature_mismatch" };
  }
  return { valid: true, algorithm };
}
