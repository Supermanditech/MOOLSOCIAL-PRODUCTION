import { Buffer } from "node:buffer";
import { createHash } from "node:crypto";

import { YouTubeProviderError } from "./errors.js";
import type { YouTubeUploadMetadata } from "./types.js";

const SHA256_BASE64URL = /^[A-Za-z0-9_-]{43}$/u;
const SHA256_HEX = /^[A-Fa-f0-9]{64}$/u;
const MEDIA_TYPE =
  /^(?:application\/octet-stream|video\/[A-Za-z0-9][A-Za-z0-9.+-]{0,126})$/u;
const MAX_YOUTUBE_UPLOAD_BYTES = 256 * 1024 * 1024 * 1024;

export interface YouTubeUploadFileIdentityInput {
  readonly algorithm: "sha256";
  /**
   * A SHA-256 digest calculated over the exact media bytes selected by the
   * user. Hex and unpadded base64url are accepted at the boundary.
   */
  readonly digest: string;
  readonly byteLength: number;
  readonly contentType: string;
}

export interface YouTubeUploadFileIdentity {
  readonly algorithm: "sha256";
  readonly digest: string;
  readonly byteLength: number;
  readonly contentType: string;
}

function invalidFileIdentity(): never {
  throw new YouTubeProviderError(
    "bad_request",
    "A valid video file identity is required.",
    400,
  );
}

function canonicalDigest(value: string): string {
  const clean = value.trim();
  if (SHA256_BASE64URL.test(clean)) return clean;
  if (SHA256_HEX.test(clean)) {
    return Buffer.from(clean, "hex").toString("base64url");
  }
  return invalidFileIdentity();
}

export function normalizeYouTubeUploadFileIdentity(
  value: unknown,
): YouTubeUploadFileIdentity {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return invalidFileIdentity();
  }
  const candidate = value as Partial<YouTubeUploadFileIdentityInput>;
  if (
    candidate.algorithm !== "sha256" ||
    !Number.isSafeInteger(candidate.byteLength) ||
    (candidate.byteLength ?? 0) < 1 ||
    (candidate.byteLength ?? 0) > MAX_YOUTUBE_UPLOAD_BYTES ||
    typeof candidate.digest !== "string" ||
    typeof candidate.contentType !== "string"
  ) {
    return invalidFileIdentity();
  }
  const contentType = candidate.contentType.trim().toLowerCase();
  if (!MEDIA_TYPE.test(contentType)) return invalidFileIdentity();
  return {
    algorithm: "sha256",
    digest: canonicalDigest(candidate.digest),
    byteLength: candidate.byteLength!,
    contentType,
  };
}

export function assertYouTubeUploadFileIdentityMatches(
  identity: YouTubeUploadFileIdentity,
  contentType: string,
  contentLength: number,
): void {
  const expected = normalizeYouTubeUploadFileIdentity(identity);
  if (
    expected.byteLength !== contentLength ||
    expected.contentType !== contentType.trim().toLowerCase()
  ) {
    throw new YouTubeProviderError(
      "bad_request",
      "The selected video no longer matches the upload request.",
      409,
    );
  }
}

/**
 * Produces an idempotency fingerprint bound to the media bytes and metadata.
 * File names, device paths and modification timestamps are deliberately
 * excluded because they are unstable and disclose local information.
 */
export function youtubeUploadRequestFingerprint(
  identityInput: unknown,
  metadata: YouTubeUploadMetadata,
): string {
  const identity = normalizeYouTubeUploadFileIdentity(identityInput);
  const canonicalRequest = JSON.stringify({
    version: 2,
    file: identity,
    metadata: {
      title: metadata.title,
      description: metadata.description,
      categoryId: metadata.categoryId,
      madeForKids: metadata.madeForKids,
      containsSyntheticMedia: metadata.containsSyntheticMedia,
      containsPaidPromotion: metadata.containsPaidPromotion,
      notifySubscribers: metadata.notifySubscribers,
    },
  });
  return `sha256:${createHash("sha256")
    .update(canonicalRequest, "utf8")
    .digest("base64url")}`;
}
