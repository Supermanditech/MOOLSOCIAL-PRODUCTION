# Social and YouTube compliance protected baseline

Date: 29 July 2026
Branch: `remediation/prototype-conformance-2026-07-20`
Pre-commit HEAD: `0aaa32bfd383b77a392b3426a49e6ef3744493dd`

## Outcome

The founder approved the r20 YouTube API compliance walkthrough and explicitly
requested that the latest Social module be committed before the next Buy
Flutter task begins.

This checkpoint deliberately replaces only the protected Social source-tree
hash used by `scripts/check-social-protected-baseline.ps1`. It does not rewrite
or invalidate:

- the immutable Screens 01–03 references;
- the historical 26 July Social baseline and its retained trial evidence;
- the complete founder-final Buy HTML reference; or
- the historical Buy evidence that records the Social tree against which it
  was originally tested.

## Protected source

- Inventory: `119` Social, YouTube and dedicated regression files.
- Portable tree SHA-256:
  `54851B4769C6A0087F586CE6C9325BBEE1D7C790E06488ECCAE3A62CA953332E`.
- Line-ending policy: UTF-8 text is normalized from CRLF to LF; binary files
  use raw bytes.
- Gate: `scripts/check-social-protected-baseline.ps1`.

## Submitted compliance package

- Candidate: `youtube-compliance-followup-20260729-20`.
- Physical device: OPPO CPH2375, Android 13.
- Submitted walkthrough:
  `output/video/MoolSocial-YouTube-API-Compliance-Walkthrough-r20.mp4`.
- Walkthrough SHA-256:
  `735029A8D4D46669388283C4A6093E8181CBFF17748EA1E6694B8BBE428CD8A6`.
- Submitted reference:
  `output/pdf/MoolSocial-YouTube-API-Compliance-Reference-r20.pdf`.
- Reference SHA-256:
  `09EA7347D0597C7733277307FEC857F6835EF6BF7BA85E70EDD7E2503F9B30CD`.
- Reply body:
  `output/email/YOUTUBE-API-COMPLIANCE-REPLY-r20.txt`.
- Gmail thread: `19f9f78a25a287ee`.
- Gmail sent message: `19fae0e9620d9306`.
- Sender: `hello@moolsocial.com`.

The approximately 216 MB r20 APK remains retained locally at
`artifacts/quality/youtube-compliance-follow-up-20260729-01/` with SHA-256
`641957A49AFC9F6A8D742CF71A4F22E65832F2443701BDB89F7C06BEE6EAC8FC`.
It is intentionally excluded from the Git commit because of normal Git-hosting
binary limits.

## Current demonstrated boundary

The submitted reviewer slice demonstrates:

- public discovery using `videos.list(chart=mostPopular, regionCode=IN)`;
- returned-channel enrichment using `channels.list`;
- bounded, quota-sensitive `search.list` candidate discovery for Shorts,
  followed by `videos.list` metadata hydration;
- user-initiated playback through the official YouTube embedded player; and
- a separate `youtube.readonly` owner-channel connection with server-side
  refresh credentials.

The reviewer build does not claim uploads, viewer mutations, playlist/channel/
asset mutations, Analytics/Reporting, Live management, Production approval or
an unlimited global YouTube catalogue.

## Regression closure

The pre-commit audit found and corrected one navigation defect: Mool → Buy was
replacing the Social route, preventing system Back from restoring the exact
prior Social state. It now pushes the native Buy V2 route directly and Back
returns to Social.

Verification:

- Dart format: `15` files, `0` changed.
- Targeted Flutter analysis: no issues.
- Affected Social/YouTube Flutter tests: `57` passed, `3` skipped,
  `0` failed.
- Updated r20 operational goldens: visually inspected.
- Approved UI locks: passed.
- App brand-integrity gate: passed.
- Git diff hygiene: passed before staging.

## Next boundary

Subsequent Buy work must pass this new protected Social gate. It must not edit
Social, YouTube, Screens 01–03 or any immutable approved reference without a
new explicit founder decision.
