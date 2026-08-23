import assert from "node:assert/strict";
import { test } from "node:test";

import {
  buildDevReviewCorpus,
  buildDevReviewPublishRequest,
  DEV_REVIEW_PERSONAS,
  DEV_REVIEW_PROJECT_ID,
  summarizeDevReviewCorpus,
} from "./dev_review_corpus.js";

test("C30K seals three disabled-passwordless persona identities and 36 posts", () => {
  assert.equal(DEV_REVIEW_PROJECT_ID, "moolsocial-dev-503018");
  assert.equal(DEV_REVIEW_PERSONAS.length, 3);
  assert.equal(new Set(DEV_REVIEW_PERSONAS.map((item) => item.uid)).size, 3);
  assert.equal(new Set(DEV_REVIEW_PERSONAS.map((item) => item.email)).size, 3);
  for (const persona of DEV_REVIEW_PERSONAS) {
    assert.match(persona.uid, /^moolsocial-c30k-community-/u);
    assert.match(persona.email, /^preview\.[a-z]+@dev\.moolsocial\.com$/u);
    assert.match(persona.displayName, /^MoolSocial Preview · /u);
  }

  const corpus = buildDevReviewCorpus();
  const summary = summarizeDevReviewCorpus(corpus);
  assert.deepEqual(summary, {
    personas: 3,
    posts: 36,
    mediaObjects: 48,
    byType: {
      post: 12,
      carousel: 6,
      imagePoll: 6,
      quickPoll: 6,
      quiz: 6,
    },
  });
  assert.equal(new Set(corpus.map((item) => item.idempotencyKey)).size, 36);
});

test("C30K encodes every requested format through the production publish contract", () => {
  const requests = buildDevReviewCorpus().map(buildDevReviewPublishRequest);
  for (const request of requests) {
    assert.equal(request.audience, "Public");
    assert.match(request.idempotencyKey, /^[A-Za-z0-9][A-Za-z0-9._-]{15,127}$/u);
    if (request.contentType === "imagePoll" ||
        request.contentType === "quickPoll" ||
        request.contentType === "quiz") {
      assert.equal(request.choices.length, 4);
    }
    if (request.contentType === "quiz") {
      assert.ok(request.correctChoiceIndex === 0 || request.correctChoiceIndex === 1);
    } else {
      assert.equal(request.correctChoiceIndex, undefined);
    }
    for (const media of request.media) {
      const bytes = Buffer.from(media.bytesBase64, "base64");
      assert.equal(bytes.length, media.byteLength);
      assert.deepEqual(
        [...bytes.subarray(0, 8)],
        [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      );
      assert.match(media.sha256, /^[a-f0-9]{64}$/u);
      assert.equal(media.contentType, "image/png");
    }
  }
});

test("C30K is deterministic and keeps all image poll media server-owned", () => {
  const first = buildDevReviewCorpus().map(buildDevReviewPublishRequest);
  const second = buildDevReviewCorpus().map(buildDevReviewPublishRequest);
  assert.deepEqual(first, second);
  for (const request of first.filter((item) => item.contentType === "imagePoll")) {
    assert.equal(request.mediaSlots.length, 0);
    assert.equal(request.media.length, 4);
    assert.deepEqual(
      request.choices.map((choice) => choice.mediaSlot),
      ["choice:0", "choice:1", "choice:2", "choice:3"],
    );
  }
});
