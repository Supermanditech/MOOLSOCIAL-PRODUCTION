import assert from "node:assert/strict";
import test from "node:test";

import {
  REDACTED_CIRCULAR_REFERENCE,
  REDACTED_RESUMABLE_SESSION_URL,
  REDACTED_SECRET,
  redactHeaders,
  redactSensitiveData,
  redactText,
} from "./redaction.js";

test("redacts authorization and API-key headers case-insensitively", () => {
  assert.deepEqual(
    redactHeaders({
      Authorization: "Bearer access-token",
      "X-Goog-Api-Key": "AIza012345678901234567890123456789",
      Accept: "application/json",
    }),
    {
      Authorization: REDACTED_SECRET,
      "X-Goog-Api-Key": REDACTED_SECRET,
      Accept: "application/json",
    },
  );
});

test("redacts nested tokens, API keys and OAuth authorization codes", () => {
  const original = {
    accessToken: "ya29.private",
    nested: {
      refresh_token: "1//refresh",
      apiKey: "AIza012345678901234567890123456789",
      code: "4/0AbCdEfGhIjKlMnOpQrStUvWxYz",
      codeName: "quota_exhausted",
    },
  };

  assert.deepEqual(redactSensitiveData(original), {
    accessToken: REDACTED_SECRET,
    nested: {
      refresh_token: REDACTED_SECRET,
      apiKey: REDACTED_SECRET,
      code: REDACTED_SECRET,
      codeName: "quota_exhausted",
    },
  });
  assert.equal(original.accessToken, "ya29.private");
});

test("redacts secrets embedded in URLs and arbitrary text", () => {
  const redacted = redactText(
    "Authorization: Bearer ya29.secret " +
      "https://youtube.googleapis.com/youtube/v3/search?part=snippet" +
      "&key=AIza012345678901234567890123456789&code=4%2Fsecret",
  );

  assert.doesNotMatch(redacted, /ya29\.secret/u);
  assert.doesNotMatch(redacted, /AIza012345/u);
  assert.doesNotMatch(redacted, /4%2Fsecret/u);
  assert.match(redacted, /\[REDACTED\]/u);
});

test("replaces a resumable upload session URL as one bearer secret", () => {
  const sessionUrl =
    "https://www.googleapis.com/upload/youtube/v3/videos" +
    "?uploadType=resumable&upload_id=AEnB2UqSecret";
  const redacted = redactText(`Location: ${sessionUrl}`);

  assert.equal(
    redacted,
    `Location: ${REDACTED_RESUMABLE_SESSION_URL}`,
  );
  assert.doesNotMatch(redacted, /upload_id/u);
});

test("redacts every creator-asset resumable path as a bearer secret", () => {
  for (const path of [
    "thumbnails/set",
    "captions",
    "channelBanners/insert",
    "watermarks/set",
    "playlistImages",
  ]) {
    const sessionUrl =
      `https://www.googleapis.com/resumable/upload/youtube/v3/${path}` +
      "?upload_id=CreatorAssetSecret";
    const redacted = redactText(`Location: ${sessionUrl}`);
    assert.equal(
      redacted,
      `Location: ${REDACTED_RESUMABLE_SESSION_URL}`,
      path,
    );
  }
});

test("redacts headers and upload-session fields in structured logs", () => {
  assert.deepEqual(
    redactSensitiveData({
      headers: {
        authorization: "Bearer access",
        "content-type": "application/json",
      },
      sessionUrl:
        "https://upload.youtube.com/upload/youtube/v3/videos" +
        "?uploadType=resumable&upload_id=secret",
      requestUrl:
        "https://youtube.googleapis.com/youtube/v3/videos?key=secret",
    }),
    {
      headers: {
        authorization: REDACTED_SECRET,
        "content-type": "application/json",
      },
      sessionUrl: REDACTED_SECRET,
      requestUrl:
        `https://youtube.googleapis.com/youtube/v3/videos?key=${REDACTED_SECRET}`,
    },
  );
});

test("redacts YouTube live ingestion stream names and keys", () => {
  assert.deepEqual(
    redactSensitiveData({
      streamName: "abcd-efgh-ijkl-mnop",
      nested: {
        stream_key: "private-live-key",
        ingestionKey: "provider-ingestion-secret",
      },
      ingestionAddress: "rtmps://a.rtmps.youtube.com/live2",
    }),
    {
      streamName: REDACTED_SECRET,
      nested: {
        stream_key: REDACTED_SECRET,
        ingestionKey: REDACTED_SECRET,
      },
      ingestionAddress: "rtmps://a.rtmps.youtube.com/live2",
    },
  );

  const text = redactText(
    '{"streamName":"abcd-secret","stream_key":"second-secret"} ' +
      "https://example.test/live?streamKey=url-secret",
  );
  assert.doesNotMatch(text, /abcd-secret|second-secret|url-secret/u);
});

test("handles circular structured log values without recursion failure", () => {
  const value: { name: string; self?: unknown } = { name: "request" };
  value.self = value;

  assert.deepEqual(redactSensitiveData(value), {
    name: "request",
    self: REDACTED_CIRCULAR_REFERENCE,
  });
});
