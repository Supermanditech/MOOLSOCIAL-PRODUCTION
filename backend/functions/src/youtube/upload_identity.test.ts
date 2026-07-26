import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "./errors.js";
import {
  assertYouTubeUploadFileIdentityMatches,
  normalizeYouTubeUploadFileIdentity,
  youtubeUploadRequestFingerprint,
} from "./upload_identity.js";

const metadata = {
  title: "Morning market",
  description: "Jodhpur market",
  categoryId: "22",
  madeForKids: false,
  containsSyntheticMedia: false,
  containsPaidPromotion: true,
  notifySubscribers: false,
} as const;

test("upload identity canonicalizes SHA-256 and binds the fingerprint to bytes", () => {
  const digestHex = "00".repeat(32);
  const identity = normalizeYouTubeUploadFileIdentity({
    algorithm: "sha256",
    digest: digestHex,
    byteLength: 1_024,
    contentType: "Video/MP4",
  });
  assert.deepEqual(identity, {
    algorithm: "sha256",
    digest: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    byteLength: 1_024,
    contentType: "video/mp4",
  });

  const first = youtubeUploadRequestFingerprint(identity, metadata);
  const sameBytes = youtubeUploadRequestFingerprint(
    { ...identity, digest: digestHex },
    metadata,
  );
  const otherBytes = youtubeUploadRequestFingerprint(
    { ...identity, digest: "11".repeat(32) },
    metadata,
  );
  assert.equal(first, sameBytes);
  assert.notEqual(first, otherBytes);
});

test("upload identity rejects malformed digests and size-only substitutions", () => {
  assert.throws(
    () => normalizeYouTubeUploadFileIdentity(null),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.httpStatus === 400,
  );
  assert.throws(
    () =>
      normalizeYouTubeUploadFileIdentity({
        algorithm: "sha256",
        digest: "not-a-digest",
        byteLength: 1_024,
        contentType: "video/mp4",
      }),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.httpStatus === 400,
  );

  const identity = normalizeYouTubeUploadFileIdentity({
    algorithm: "sha256",
    digest: "00".repeat(32),
    byteLength: 1_024,
    contentType: "video/mp4",
  });
  assert.throws(
    () =>
      assertYouTubeUploadFileIdentityMatches(
        identity,
        "video/mp4",
        2_048,
      ),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.httpStatus === 409 &&
      error.message ===
        "The selected video no longer matches the upload request.",
  );
});
