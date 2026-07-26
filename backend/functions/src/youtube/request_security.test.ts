import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "./errors.js";
import {
  assertRawRequestBodyWithinLimit,
  YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES,
} from "./request_security.js";

test("raw request limit measures received UTF-8 bytes instead of characters", () => {
  assert.equal(assertRawRequestBodyWithinLimit("₹", 3), 3);
  assert.throws(
    () => assertRawRequestBodyWithinLimit("₹", 2),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.httpStatus === 413 &&
      error.code === "bad_request",
  );
});

test("raw request limit accepts the exact boundary and rejects one byte more", () => {
  assert.equal(
    assertRawRequestBodyWithinLimit(
      Buffer.alloc(YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES),
    ),
    YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES,
  );
  assert.throws(
    () =>
      assertRawRequestBodyWithinLimit(
        Buffer.alloc(YOUTUBE_PROVIDER_MAX_REQUEST_BODY_BYTES + 1),
      ),
    (error: unknown) =>
      error instanceof YouTubeProviderError && error.httpStatus === 413,
  );
});

test("raw request limit fails closed when runtime bytes are unavailable", () => {
  assert.throws(
    () => assertRawRequestBodyWithinLimit({ operation: "capabilities" }),
    (error: unknown) =>
      error instanceof YouTubeProviderError &&
      error.httpStatus === 400 &&
      error.message === "The raw request body is unavailable.",
  );
});
