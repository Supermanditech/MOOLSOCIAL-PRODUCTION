import assert from "node:assert/strict";
import test from "node:test";

import { YouTubeProviderError } from "./errors.js";
import {
  safeYouTubeProviderImageUrl,
  safeYouTubeProviderPlainText,
} from "./provider_content.js";

test("provider image policy accepts only known YouTube image delivery hosts", () => {
  assert.equal(
    safeYouTubeProviderImageUrl(
      "https://i.ytimg.com/vi/abc12345/hqdefault.jpg",
      "invalid",
    ),
    "https://i.ytimg.com/vi/abc12345/hqdefault.jpg",
  );
  assert.equal(
    safeYouTubeProviderImageUrl(
      "https://yt3.ggpht.com/channel-avatar",
      "invalid",
    ),
    "https://yt3.ggpht.com/channel-avatar",
  );
  assert.equal(
    safeYouTubeProviderImageUrl(
      "https://yt3.googleusercontent.com/avatar#tracking",
      "invalid",
    ),
    "https://yt3.googleusercontent.com/avatar",
  );
});

test("provider image policy rejects deceptive, insecure and arbitrary hosts", () => {
  for (const value of [
    "http://i.ytimg.com/vi/abc12345/hqdefault.jpg",
    "https://i.ytimg.com.evil.example/track",
    "https://evil.example/track",
    "https://user:password@yt3.ggpht.com/avatar",
    "https://yt3.ggpht.com:8443/avatar",
  ]) {
    assert.throws(
      () => safeYouTubeProviderImageUrl(value, "invalid"),
      (error: unknown) =>
        error instanceof YouTubeProviderError &&
        error.code === "provider_rejected" &&
        error.httpStatus === 502,
    );
  }
});

test("provider plain text remains literal and replaces unsafe controls", () => {
  assert.equal(
    safeYouTubeProviderPlainText(
      "<script>alert('literal')</script>\r\nhello\u0000world\u202E\uD800🙂",
      "invalid",
    ),
    "<script>alert('literal')</script>\nhello\uFFFDworld\uFFFD\uFFFD🙂",
  );
});
