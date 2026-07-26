import assert from "node:assert/strict";
import test from "node:test";

import { assessPublicVideo } from "./public_video_policy.js";

const ELIGIBLE = {
  regionCode: "IN",
  privacyStatus: "public",
  embeddable: true,
  uploadStatus: "processed",
  madeForKids: false,
  liveBroadcastContent: "none",
} as const;

test("accepts standard, live, and upcoming public playback states", () => {
  const standard = assessPublicVideo(ELIGIBLE);
  const live = assessPublicVideo({
    ...ELIGIBLE,
    liveBroadcastContent: "live",
    syndicationConfirmedBySearch: true,
  });
  const upcoming = assessPublicVideo({
    ...ELIGIBLE,
    liveBroadcastContent: "upcoming",
  });

  assert.deepEqual(standard, {
    eligible: true,
    availability: {
      state: "available",
      regionCode: "IN",
      broadcastState: "none",
      syndication: "embeddable_status_only",
    },
  });
  assert.equal(
    live.eligible && live.availability.syndication,
    "search_filter_confirmed",
  );
  assert.equal(
    live.eligible && live.availability.broadcastState,
    "live",
  );
  assert.equal(
    upcoming.eligible && upcoming.availability.broadcastState,
    "upcoming",
  );
});

test("requires an explicitly public, processed, embeddable video", () => {
  assert.deepEqual(
    assessPublicVideo({ ...ELIGIBLE, privacyStatus: "unlisted" }),
    { eligible: false, reason: "not_public" },
  );
  assert.deepEqual(
    assessPublicVideo({ ...ELIGIBLE, embeddable: false }),
    { eligible: false, reason: "not_embeddable" },
  );
  assert.deepEqual(
    assessPublicVideo({ ...ELIGIBLE, uploadStatus: "uploaded" }),
    { eligible: false, reason: "processing" },
  );
  assert.deepEqual(
    assessPublicVideo({ ...ELIGIBLE, uploadStatus: "rejected" }),
    { eligible: false, reason: "removed_or_rejected" },
  );
  const { uploadStatus: _uploadStatus, ...missingStatus } = ELIGIBLE;
  assert.deepEqual(assessPublicVideo(missingStatus), {
    eligible: false,
    reason: "metadata_invalid",
  });
});

test("applies allowed and blocked region rules exactly", () => {
  assert.equal(
    assessPublicVideo({
      ...ELIGIBLE,
      regionRestriction: { allowed: ["in", "GB"] },
    }).eligible,
    true,
  );
  assert.deepEqual(
    assessPublicVideo({
      ...ELIGIBLE,
      regionRestriction: { allowed: [] },
    }),
    { eligible: false, reason: "region_restricted" },
  );
  assert.deepEqual(
    assessPublicVideo({
      ...ELIGIBLE,
      regionRestriction: { blocked: ["US", "IN"] },
    }),
    { eligible: false, reason: "region_restricted" },
  );
  assert.equal(
    assessPublicVideo({
      ...ELIGIBLE,
      regionRestriction: { blocked: [] },
    }).eligible,
    true,
  );
  assert.deepEqual(
    assessPublicVideo({
      ...ELIGIBLE,
      regionRestriction: {
        allowed: ["IN"],
        blocked: ["US"],
      },
    }),
    { eligible: false, reason: "metadata_invalid" },
  );
});

test("fails closed for age-restricted and children-directed video", () => {
  assert.deepEqual(
    assessPublicVideo({
      ...ELIGIBLE,
      youtubeAgeRating: "ytAgeRestricted",
    }),
    { eligible: false, reason: "age_restricted" },
  );
  assert.deepEqual(
    assessPublicVideo({ ...ELIGIBLE, madeForKids: true }),
    { eligible: false, reason: "children_directed" },
  );
});

test("fails closed for unknown provider policy metadata", () => {
  assert.deepEqual(
    assessPublicVideo({
      ...ELIGIBLE,
      youtubeAgeRating: "futureRating",
    }),
    { eligible: false, reason: "metadata_invalid" },
  );
  assert.deepEqual(
    assessPublicVideo({
      ...ELIGIBLE,
      liveBroadcastContent: "premiere",
    }),
    { eligible: false, reason: "metadata_invalid" },
  );
  assert.deepEqual(
    assessPublicVideo({
      ...ELIGIBLE,
      regionRestriction: { blocked: ["IND"] },
    }),
    { eligible: false, reason: "metadata_invalid" },
  );
  const { madeForKids: _madeForKids, ...missingAudience } = ELIGIBLE;
  assert.deepEqual(assessPublicVideo(missingAudience), {
    eligible: false,
    reason: "metadata_invalid",
  });
  const {
    liveBroadcastContent: _liveBroadcastContent,
    ...missingBroadcastState
  } = ELIGIBLE;
  assert.deepEqual(assessPublicVideo(missingBroadcastState), {
    eligible: false,
    reason: "metadata_invalid",
  });
});
