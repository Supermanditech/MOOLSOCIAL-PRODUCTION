# YouTube public review, API, Shorts and Screen 04 audit

Date: 25 July 2026  
Environment: dedicated private Dev only (`moolsocial-dev-503018`)  
Staging/Production: unchanged and forbidden by this review profile

## Founder decision implemented

The accepted public catalogue and official embedded playback may remain
continuously available for founder review on the installed OPPO candidate.
This is implemented as the fail-closed `PublicDataReview` profile, not as an
extension of a timed proof:

- `YOUTUBE_PUBLIC_DATA_REVIEW_MODE=accepted`;
- `YOUTUBE_PUBLIC_DATA_ENABLED=true`;
- Owner Connect, Owner Actions, Creator Assets, Live, Private Upload and Owner
  Analytics remain false;
- timed proof fields and the accepted-review marker are mutually exclusive;
- exact Dev project, App Check, quota, API-key, runtime-identity and
  all-disabled rollback controls remain mandatory; and
- any wrong marker/project, second capability or deployment-verification
  failure fails closed.

The persistent deployment passed on revision `youtubeprovider-00024-dol`.
Candidate `youtube-shorts-oppo-20260725-06` is installed on OPPO serial
`2b3e0f71`, and the app is left open on its live YouTube-only Shorts lane.

## Comprehensive API disposition

“Comprehensive” means that each relevant official family has a recorded,
tested disposition. It does not mean activating every OAuth scope for every
user or presenting all endpoints on the consumer screen.

| Official family | MoolSocial implementation | 25 July live disposition |
|---|---|---|
| YouTube Data API v3 — public discovery/metadata | Most popular, submitted search, video hydration/statistics, channels/handles, public playlists, public comments/replies, activities, channel sections, regions, languages and categories have typed server contracts and deterministic gates | Public Videos catalogue and the admitted YouTube Shorts lane are accepted for continuous private-Dev review |
| IFrame Player API | Closed native bridge, official provider player, visible-item ownership, viewport/lifecycle/error/visibility controls | Accepted private-Dev OPPO Videos and portrait Shorts playback paths |
| Data API owner reads and OAuth | Incremental OAuth, encrypted refresh-token custody, connection status, owner uploads/subscriptions/playlists and revalidation contracts | Disabled; needs exact test-channel OAuth proof and UI admission |
| Data API connected actions | Rating, comment/reply/moderation, subscribe, playlists/items and owned-video mutations have bounded contracts | Disabled; needs point-of-use consent and exact action proofs |
| Creator assets | Thumbnails, captions, channel branding/sections/banner, watermark, playlist images and abuse-reporting contracts | Disabled; needs creator-owned provider proof |
| Private upload | Direct-to-Google resumable transfer, immutable media identity and reconciliation contracts | Disabled; private-only proof and audit gate remain |
| YouTube Analytics API v2 | Bounded owner queries, groups/items and fixed application presets | Disabled; owner-only consent and live shape proof remain |
| YouTube Reporting API v1 | Report types, jobs, reports and bounded media download contracts | Disabled; owner-only consent, retention and live shape proof remain |
| YouTube Live Streaming API | Broadcasts, streams, transitions/binding, live chat, moderation, polls and eligibility-gated owner resources | Disabled; eligible test channel and moderation proof remain |
| WebSub | Canonical topic, subscription lifecycle, verification, signature and Atom parsing contracts | Disabled; approved-channel callback/renewal proof remains |
| Partner/Content ID, memberships, commerce and Ads-adjacent products | Inventoried with representative, eligibility, legal, spend and product boundaries | Not generally available; no customer promise or UI admission |

The backend verification result for the current source is `269/269`. Service
enablement alone is not product approval: OAuth, eligibility, quota, provider
shape, retention, UI-reference and physical-device gates still apply to each
non-public family.

## Shorts decision

The public Data API does not expose an authoritative public `isShort` field or
the personalized native YouTube Shorts feed. The `search.list`
`videoDuration=short` filter means a video is shorter than four minutes; it is
not a Shorts classifier. MoolSocial therefore does not classify an item from
duration or aspect ratio alone.

Priority admission path:

1. Keep MoolSocial-native/published reels in the existing Shorts surface.
2. For the public consumer lane, require a positive creator declaration of
   `Short`, `Shorts` or `YouTube Shorts` in current provider-returned title,
   localized text, description or tags, plus a duration of 1–180 seconds.
3. Independently require the current item to be public, processed, embeddable
   and available in India.
4. Owner Analytics `creatorContentType=SHORTS` remains the stronger classifier
   for connected creator-owned inventory when Owner Analytics is separately
   admitted.
5. Keep results that lack the positive declaration in Videos, even when they
   happen to be short-duration or vertical.

The live private-Dev run admitted eight provider items. It proved two distinct
real Shorts in the official portrait player, including explicit playback and a
vertical transition. Only the visible page mounts a player, which prevents
adjacent PageView items from competing for native-player lifecycle.

## Screen 04 UI recommendation

Screen 04 now preserves the Videos discovery/watch path and adds the required
first-class Shorts exposure without turning the consumer surface into a
creator administration console:

1. **Videos:** retain public discovery, search, channel/comments sheets and the
   official watch surface.
2. **Shorts:** MoolSocial and admitted YouTube items share vertical paging;
   `YouTube` is a direct filter, the official portrait player remains
   unobscured, and real provider title/channel/count metadata appears below it.
3. **Connected viewing actions:** reveal Like, Comment and Subscribe
   contextually after Connect YouTube and point-of-use incremental consent;
   keep MoolSocial Save/Discuss/Shop visibly separate.
4. **Creator Workspace:** place uploads, owned media/assets, playlists,
   Analytics, Reporting and Live management here rather than crowding the
   consumer Screen 04.
5. **Live:** add public live/upcoming badges to Videos only when returned;
   reserve scheduling, stream keys, chat moderation and eligibility states for
   the connected creator workspace.
6. **Unavailable/revoked/quota states:** design them from captured private-Dev
   provider shapes, then require founder checksum acceptance, Flutter parity
   and physical OPPO acceptance before Staging.

The editable screenbook contains the same source-lane direction as a
founder-review draft on branch
`founder-review/youtube-screen04-2026-07-25`. Its frozen `approved-final`
reference is unchanged. This live Flutter continuation is private Dev only and
does not admit a Staging or Production release.
