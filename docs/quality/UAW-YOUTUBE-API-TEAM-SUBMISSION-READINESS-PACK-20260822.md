# MoolSocial YouTube API team submission readiness pack

Date: 2026-08-22
State: `NOT READY TO SUBMIT — PREPARATION ONLY`
Project/package: `moolsocial-dev-503018` / `com.moolsocial.app`

## Executive disposition

The existing same-thread draft and 29 July walkthrough remain useful source material, but no prior candidate identity may be reused as current proof. The current installed r60.80 is a preserved rejected historical candidate. FIX8 global social-login source is qualified, but no FIX8 successor has been built, installed or device-accepted.

No Gmail draft/reply/send, quota form, provider login, Play action, Hosting deployment or external submission occurred during this preparation.

## Current official requirements rechecked

Primary sources:

- Quota and Compliance Audits: <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>
- Developer Policies: <https://developers.google.com/youtube/terms/developer-policies>
- Required Minimum Functionality: <https://developers.google.com/youtube/terms/required-minimum-functionality>
- Compliance guide: <https://developers.google.com/youtube/terms/developer-policies-guide>
- Revision history: <https://developers.google.com/youtube/terms/revision-history>

Submission-impact summary:

1. Additional quota beyond the default requires a compliance audit through the official Audit and Quota Extension Form.
2. Each API Client must display a YouTube Terms of Service link and provide an accessible privacy policy that discloses YouTube API use, Google Privacy, accessed/stored data and user controls.
3. Mobile embedded players must identify the API Client through Referer/origin handling, use an OS-provided WebView where available, preserve the official player, controls and branding, and avoid overlays.
4. Player viewport must be at least 200 by 200 CSS pixels. Automatic playback must wait until the player is sufficiently visible and only one player may autoplay at a time.
5. The client must add independent value, clearly distinguish YouTube data from other sources, avoid unsupported derived metrics and never shard quota across projects.
6. The June 2026 policy revision introduced additional derived-metric and data-storage rules. MoolSocial's current reviewed scope should continue to exclude custom YouTube-derived metrics.

## Current MoolSocial evidence that is already aligned

- Android player uses the OS `WebView` and `loadDataWithBaseURL` with the approved HTTPS base URL.
- The injected document uses `strict-origin-when-cross-origin` and passes the approved origin to the IFrame player.
- Player configuration has `autoplay: 0`, `controls: 1`, standard YouTube host and no MoolSocial overlay inside the provider surface.
- Geometry enforces a minimum 200 CSS-pixel width and height.
- The declared current Data API boundary remains eligible public discovery through `videos.list`, `channels.list`, bounded `search.list`, official embedded playback and a separately initiated `youtube.readonly` connection.
- Upload, Like, Comment, Subscribe, playlist/channel/asset mutation, Analytics, Reporting, Live, partner, membership, Super Chat and Content Owner capabilities must not be claimed active.
- Public YouTube API, Privacy, Terms, Disconnect and Delete pages all returned HTTP 200 on 2026-08-22. The YouTube, Privacy and Terms pages expose YouTube Terms and Google Privacy links; the Disconnect page exposes Google permissions/revocation guidance.

## Confirmed blockers

### 1. Global-login/device candidate not yet accepted

- FIX8 source qualification: passed two clean cycles.
- FIX8 successor build: not authorized and not created.
- Exact OPPO install and customer-visible cold-start/login/post-login/relaunch proof: pending.
- Current r60.80 receipt is historical only and cannot be used as the reviewer candidate.

### 2. Public deletion maximum is behind source

The identical source-proven matcher finds the founder-approved 30-day maximum in current source but not in the HTTP-200 public delete page. See `REG-20260822-3163-LIVE-DELETE-PAGE-BEHIND-THIRTY-DAY-SOURCE`.

No Hosting deployment should occur until founder review. Final submission requires source/live parity.

### 3. Mobile YouTube surface lacks a direct YouTube Terms link

The audited mobile connection/control surface exposes Privacy, Disconnect, Google permissions and account deletion, but not a direct YouTube Terms link. See `REG-20260822-3164-MOBILE-YOUTUBE-SURFACE-NO-DIRECT-YOUTUBE-TERMS-LINK`.

This is not part of the active FIX8 auth ticket. Proposed dependency-held successor identity for founder review:

`UAW-YOUTUBE-COMPLIANCE-FIX1-MOBILE-DIRECT-POLICY-LINKS-AND-PUBLIC-PARITY`

No ticket was selected and no source implementation was performed.

### 4. Play/reviewer distribution proof is absent

The prior C30T draft names stale r60.45 and pending Play evidence. It must not be sent or minimally edited into a current claim. A final reviewer candidate needs exact Play-installed package/version/signer/installer/artifact provenance and a valid eligible-reviewer path.

### 5. Final screencast and founder approval are absent

The 29 July screencast script remains the structural reference, but the final video must use the exact accepted candidate, show dated cuts honestly, reveal no credential/token/private identity, record its SHA-256 and receive founder approval before same-thread submission.

## Exact completion sequence

1. Founder reviews this pack.
2. If approved, authorize one FIX8 successor build and in-place OPPO sideload using the exact build authority marker already requested.
3. Pass post-build plugin/Firebase integrity, cold start, global social login, callback return, post-login navigation, sign-out and relaunch on OPPO without data clear.
4. Select and qualify the dependency-held mobile policy-links successor; add direct YouTube Terms and Google Privacy controls with focused tests and two clean source cycles.
5. Separately authorize and deploy only the required Hosting source, then prove public 30-day parity and all five compliance URLs.
6. Produce one exact reviewer-distributed candidate only after Play authority and signing/reset prerequisites are actually ready.
7. Record the final 3–5 minute walkthrough using the exact candidate and calculate the recording SHA-256.
8. Replace every pending field below with sealed evidence.
9. Founder approves the exact same-thread text and attachments.
10. Submit once; record the provider receipt/status. Do not infer approval from send success.

## Final evidence ledger

| Field | Required value | Current state |
|---|---|---|
| Review candidate version/code | Exact accepted build | `PENDING` |
| Candidate APK/AAB SHA-256 | Exact distributed artifact | `PENDING` |
| Source aggregate/commit | Exact candidate provenance | FIX8 source aggregate known; candidate `PENDING` |
| Device | OPPO CPH2375 | Available; exact candidate `PENDING` |
| Installer and signer relationship | Play-installed authoritative readback | `PENDING` |
| Global social login acceptance | Cold start/login/return/post-login/relaunch | `PENDING` |
| YouTube public discovery/playback | Exact candidate device proof | `PENDING` |
| Read-only channel connection | Supervised exact-candidate proof or clearly dated prior proof | `PENDING FOUNDER CHOICE` |
| Direct in-app policy links | Device proof | `BLOCKED BY REG3164` |
| Public 30-day deletion maximum | Source/live parity | `BLOCKED BY REG3163` |
| Screencast URL/attachment and SHA-256 | Founder-approved reviewer copy | `PENDING` |
| Same-thread final text | Exact, no stale version or overclaim | `PENDING` |
| Founder approval | Explicit | `PENDING` |

## Safe claim boundary for the future reply

Permitted only after exact evidence is sealed:

- MoolSocial provides independently valuable, source-attributed public YouTube discovery inside a broader MoolSocial experience.
- Playback uses the official embedded player with provider controls, branding and advertising intact.
- Channel connection is separate, optional and read-only.
- The submitted candidate does not expose YouTube upload or mutation features.

Never claim:

- Production approval or public availability;
- active upload, viewer mutation, Analytics/Reporting or Live management;
- all historically selected methods are implemented;
- YouTube Home/Shorts recommendation equivalence;
- provider approval based on an email or form submission alone.

## Morning decisions requested

1. Whether to issue the exact FIX8 r60.81 build/in-place-sideload authority after reviewing the source and r60.80 historical receipt.
2. Whether to approve the proposed dependency-held YouTube policy-links successor after FIX8 device acceptance.
3. Whether to reconfirm the exact Dev Hosting-only promotion/readback for the already-qualified 30-day pages after the mobile fix is source-qualified.

Until those decisions, the correct state is preparation complete, submission not ready.
