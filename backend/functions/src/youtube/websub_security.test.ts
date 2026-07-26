import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import test from "node:test";

import {
  DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES,
  deriveYouTubeWebSubSubscriptionSecret,
  isYouTubeWebSubRawBodyBounded,
  verifyYouTubeWebSubPayloadSignature,
  type YouTubeWebSubSignatureAlgorithm,
} from "./websub_security.js";

const CHANNEL_ID = `UC${"a".repeat(22)}`;
const RAW_BODY = Buffer.from(
  "<feed xmlns=\"http://www.w3.org/2005/Atom\"></feed>",
  "utf8",
);
const SECRET = "s".repeat(32);

function signature(
  algorithm: YouTubeWebSubSignatureAlgorithm,
  body = RAW_BODY,
  secret = SECRET,
): string {
  return `${algorithm}=${createHmac(algorithm, secret)
    .update(body)
    .digest("hex")}`;
}

test("derives a stable unique per-subscription secret from one root", () => {
  const root = Buffer.alloc(32, 7);
  const first = deriveYouTubeWebSubSubscriptionSecret(
    root,
    CHANNEL_ID,
    1,
  );
  assert.equal(
    deriveYouTubeWebSubSubscriptionSecret(root, CHANNEL_ID, 1),
    first,
  );
  assert.notEqual(
    deriveYouTubeWebSubSubscriptionSecret(root, CHANNEL_ID, 2),
    first,
  );
  assert.match(first, /^[A-Za-z0-9_-]{43}$/u);
  assert.ok(Buffer.byteLength(first, "utf8") < 200);
  assert.throws(
    () =>
      deriveYouTubeWebSubSubscriptionSecret(
        Buffer.alloc(31),
        CHANNEL_ID,
        1,
      ),
    /at least 32 bytes/u,
  );
  assert.throws(
    () =>
      deriveYouTubeWebSubSubscriptionSecret(root, CHANNEL_ID, 0),
    /positive safe integer/u,
  );
});

test("validates each WebSub-recognized HMAC algorithm over exact raw bytes", () => {
  for (const algorithm of [
    "sha1",
    "sha256",
    "sha384",
    "sha512",
  ] as const) {
    assert.deepEqual(
      verifyYouTubeWebSubPayloadSignature(
        RAW_BODY,
        signature(algorithm),
        SECRET,
      ),
      { valid: true, algorithm },
    );
  }
});

test("signature changes when any raw byte changes", () => {
  const header = signature("sha256");
  const modified = Buffer.concat([RAW_BODY, Buffer.from("\n")]);
  assert.deepEqual(
    verifyYouTubeWebSubPayloadSignature(
      modified,
      header,
      SECRET,
    ),
    { valid: false, reason: "signature_mismatch" },
  );
});

test("rejects missing, malformed, ambiguous and unsupported signatures", () => {
  const malformed = [
    "",
    "md5=00",
    "sha256",
    "sha256=not-hex",
    "sha256=00",
    `${signature("sha256")},${signature("sha1")}`,
    ` SHA256=${"0".repeat(64)}`,
  ];
  assert.deepEqual(
    verifyYouTubeWebSubPayloadSignature(
      RAW_BODY,
      undefined,
      SECRET,
    ),
    { valid: false, reason: "missing_header" },
  );
  for (const header of malformed) {
    assert.deepEqual(
      verifyYouTubeWebSubPayloadSignature(
        RAW_BODY,
        header,
        SECRET,
      ),
      { valid: false, reason: "invalid_header" },
    );
  }
});

test("rejects the wrong signature or secret without exposing expected data", () => {
  assert.deepEqual(
    verifyYouTubeWebSubPayloadSignature(
      RAW_BODY,
      `sha256=${"0".repeat(64)}`,
      SECRET,
    ),
    { valid: false, reason: "signature_mismatch" },
  );
  assert.deepEqual(
    verifyYouTubeWebSubPayloadSignature(
      RAW_BODY,
      signature("sha256"),
      "short",
    ),
    { valid: false, reason: "invalid_secret" },
  );
  assert.deepEqual(
    verifyYouTubeWebSubPayloadSignature(
      RAW_BODY,
      signature("sha256"),
      "x".repeat(200),
    ),
    { valid: false, reason: "invalid_secret" },
  );
});

test("enforces a hard raw-body ceiling that callers may only lower", () => {
  const atLimit = Buffer.alloc(
    DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES,
  );
  const overLimit = Buffer.alloc(
    DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES + 1,
  );
  assert.equal(isYouTubeWebSubRawBodyBounded(atLimit), true);
  assert.equal(isYouTubeWebSubRawBodyBounded(overLimit), false);
  assert.equal(isYouTubeWebSubRawBodyBounded(Buffer.alloc(10), 10), true);
  assert.equal(isYouTubeWebSubRawBodyBounded(Buffer.alloc(11), 10), false);
  assert.deepEqual(
    verifyYouTubeWebSubPayloadSignature(
      overLimit,
      signature("sha256", overLimit),
      SECRET,
    ),
    { valid: false, reason: "body_too_large" },
  );
  assert.throws(
    () =>
      isYouTubeWebSubRawBodyBounded(
        Buffer.alloc(1),
        DEFAULT_YOUTUBE_WEBSUB_MAX_RAW_BODY_BYTES + 1,
      ),
    /no greater than/u,
  );
});
