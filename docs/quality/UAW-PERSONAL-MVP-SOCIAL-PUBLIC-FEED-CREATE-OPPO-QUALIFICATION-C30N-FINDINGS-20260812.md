# C30N public Feed/Create OPPO qualification findings

## Founder observation

The installed r60.39 Feed shows no real public posts, so the founder cannot yet
judge whether text, image, carousel, Image Poll, Quick Poll and Quiz work end to
end before the YouTube API quota submission.

## Reuse and duplicate analysis

No additional review users or seed posts are required.

- C30K already created three deterministic Firebase Auth personas: Asha,
  Kabir and Meera.
- Each persona owns two public text posts, two public image posts, two public
  carousels, two four-choice Image Polls, two four-choice Quick Polls and two
  four-choice Quizzes: 12 posts per persona and 36 total.
- The independent Dev readback verified all three Auth records, 36 posts, 36
  idempotency records and 48 referenced Storage objects with zero mismatches.
- The deployed `moolSocialContent` revision `moolsocialcontent-00003-juw`
  includes the corrected text-choice persistence owner and remains active.
- Direct client Firestore and Storage access remains deny-all. Flutter must use
  Firebase Auth, Play Integrity App Check and the deployed gateway.

Creating two more users or another copy of the corpus would duplicate accepted
Dev state and would not solve the visible Feed problem.

## Exact remaining defect

r60.39 cannot call `moolSocialContent` because its immutable compile-time
configuration omitted `MOOLSOCIAL_SOCIAL_CONTENT_URL`. C30M hardened the build
gate so a Social successor rejects missing, empty, runtime-omitted or wrong-
environment values and accepts only the exact Dev endpoint. The correction has
not yet been built or installed.

## End-to-end acceptance still missing

Existing source and backend tests prove the contracts, but the following must
still be demonstrated on one endpoint-enabled OPPO candidate:

- live authenticated Feed reads all three authors and every format;
- images and all carousel pages load from authorized gateway responses;
- every poll/quiz exposes exactly four choices and records a vote truthfully;
- Feed refresh, retained relaunch, offline and retry behave without fake data;
- the currently signed-in personal user publishes one post through each of the
  six Create CTAs and sees the accepted server result after Feed refresh and
  process relaunch;
- keyboard/IME return preserves the complete Create screen;
- YouTube Home, Shorts and creator account truth remain green.

## Exact founder execution authority

On 2026-08-12 the founder explicitly authorized C30N fresh host
qualification, one APK build, one checksum-matched OPPO install, device
launch/taps and six signed-in Dev Create writes: text, image, carousel, Image
Poll, Quick Poll and Quiz. Production deployment and YouTube quota submission
remain explicitly excluded.

The authority is consumed only by the single C30N candidate and exactly those
six Dev content writes. It does not authorize a second build/install, corpus
reapplication, user creation, provider deployment, credential access,
Production write or quota submission.
