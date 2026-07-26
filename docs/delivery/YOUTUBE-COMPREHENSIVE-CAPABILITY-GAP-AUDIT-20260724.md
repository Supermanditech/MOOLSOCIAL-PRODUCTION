# YouTube comprehensive capability gap audit and phased backlog — 24–25 July 2026

## Decision

YouTube may be the primary watch catalogue and provider-owned player inside
MoolSocial Social. MoolSocial will add independent value through its native
Feed, commerce, order attribution, creator earnings, collaboration, Chat and
workspaces.

This is not authorization to copy YouTube trade dress or claim access to
personalized YouTube Home, the native Shorts feed, Watch History, Watch Later
or the YouTube notification inbox. Those capabilities are not exposed by the
approved APIs.

It is also not a MoolSocial web-product plan. MoolSocial presentation remains
native Flutter V2. The direct official IFrame Player in one isolated Android
WebView/iOS WKWebView is the sole provider-HTML exception.

Current Screen 04 remains `DRAFT / HOLD`. This audit changes the provider
backlog, not the approved-reference workflow.

## Capability classification

| Capability | Decision | Product/API boundary |
|---|---|---|
| Public videos, channels, playlists, comments and statistics | MVP | Implemented public-catalog contract; use exact returned fields, attribution and bounded caching. |
| Official IFrame Player | MVP; next priority | The sole provider-player WebView exception. No MoolSocial UI may cover or restyle the player. |
| Explicit public search | MVP, quota-sensitive | Submit-only remote search; never provider type-ahead. It uses the separate search allowance. |
| Popular, live and approved-channel discovery | MVP | MoolSocial-curated catalogue from provider results; never call it YouTube Home or recommendations. |
| Regions, languages and categories | MVP | Long-cache official dictionaries and localized provider metadata. |
| Owner videos, subscriptions and playlists | MVP owner P1 | Connected-channel OAuth with private per-user data and short private caches. |
| Fixed owner Analytics presets | MVP owner P1 | `youtube.readonly` plus `yt-analytics.readonly`; no monetary scope or arbitrary queries. |
| Bulk Reporting API | Later workspace | Useful for delayed creator back-office reports, not consumer realtime UI. |
| Public comments and replies | MVP read-only | Provider source and authorship remain explicit; full text requires a real expansion state. |
| Comment/reply writes and moderation | Later verified OAuth | Explicit “on YouTube” action, reconciliation and a separate 50-unit mutation budget. |
| `comments.markAsSpam` | Permanently excluded | YouTube's current comments implementation guide states that the method is no longer supported in Data API v3. MoolSocial exports no route for it and must not alias it to `comments.setModerationStatus`. |
| Ratings | Later verified OAuth | Provider Like is separate from MoolSocial reactions and cannot be rewarded. |
| Subscription mutations | Later verified OAuth | Explicit acting-channel confirmation; no personalized subscription-feed endpoint follows. |
| Playlist mutations | Later verified OAuth | User-named YouTube playlists are possible; MoolSocial Save remains separate. |
| Direct resumable uploads | Private Dev, then audit | Device-to-YouTube only. Unverified projects are private-only. There is no Shorts upload endpoint or `isShort` flag. |
| Post-upload metadata, scheduling and thumbnails | After private upload proof | Owner-only provider workflow with reconciliation. |
| Captions | Deferred, high quota | Creator-owned caption management only; player captions remain provider-owned. |
| WebSub approved-channel refresh | MVP; next priority | Push upload/title/description changes, then hydrate with normal Data API calls. |
| Public live viewing | MVP read-only | Discover provider live content and play it in the official player. |
| Creator live management and live-chat writes | Later, high operational risk | Requires channel eligibility, ingestion lifecycle, moderation and provider audit. |
| Members and membership levels | Representative and eligibility gated | Requires a memberships-enabled owner channel and access requested through a Google/YouTube representative. |
| Super Chat and eligible funding events | Owner/eligibility gated | Separate from the Members representative gate; never public Social truth or MoolSocial payments. |
| Channel sections/branding writes | Later, low engagement value | Creator Studio polish only. |
| Personalized Home, native Shorts feed, history, Watch Later and notification inbox | Unsupported | Do not expose or promise them. |
| Hidden branding, ad-free playback, commerce overlays inside the player, offline extraction or background audio | Forbidden | Preserve player controls, advertising, attribution and provider links. |
| Community-post creation, Stories, public arbitrary transcripts and raw media URLs | Unsupported | Do not expose or promise them. |
| Content ID/CMS claims, assets, ownership and partner finance | Partner-only | Excluded unless YouTube grants separate partner/content-owner rights. |
| Video trainability | No-auth/no-quota but irrelevant | No MoolSocial customer feature; inventory only. |

## Authoritative phased backlog

The current deployment manifest remains a narrow private-Dev proof. Every item
below is disabled until its phase gate passes. Later phases do not block the
minimum proof, and documenting a method does not authorize a scope, Cloud
service, UI or production traffic.

### Phase A — minimum private-Dev provider proof

Goal: prove the smallest end-to-end native-app value chain before changing
Screen 04.

| Ticket | Capability family | Required proof |
|---|---|---|
| `YT-A-PUBLIC` | Public videos, channels, playlists, playlist items, comments/replies, regions/languages/categories and explicit search | Real provider pages, omitted fields, pagination, ETags/cache, unavailable content, quota stop and source attribution |
| `YT-A-PLAYER` | Official IFrame Player | Real Android/iOS host identity, playback/events/errors/captions/fullscreen, one-player lifecycle and no MoolSocial overlay |
| `YT-A-CONNECT` | Separate YouTube channel OAuth | System-browser PKCE, exact channel confirmation, narrow scopes, cancel/revoke/delete and no MoolSocial-login coupling |
| `YT-A-UPLOAD` | Direct resumable `videos.insert` | One founder-controlled private upload, device-to-YouTube bytes, processing/retry/cancel/idempotency and zero public/unlisted availability |
| `YT-A-ANALYTICS` | `reports.query` owner presets | Real authorized results, empty/limited/revoked/quota states and clear YouTube/MoolSocial metric separation |
| `YT-A-COST` | Quota and owned-cloud controls | Cloud-console bucket values, Dev application caps, INR 1,000 alert behavior, cache/kill switch and no retry storm |

Only these currently map to the four deployment profiles
`PublicData`, `OwnerConnect`, `PrivateUpload` and `OwnerAnalytics`. The
deployment manifest must not be widened to later phases during this proof.

### Phase B — production-quality public read plane

Depends on Phase A evidence and a new approved manifest/ADR where a cloud
target is added.

| Ticket | Capability family | Required proof |
|---|---|---|
| `YT-B-CATALOGUE` | Popular India, approved-channel uploads, curated playlists, channel activity and channel sections | MoolSocial-selected ranking, no “YouTube Home/recommendation” claim, paging and 30-day refresh/delete |
| `YT-B-WEBSUB` | Approved-channel WebSub | Founder-approved registry, lease/HMAC/callback verification, deduplication, Data API hydration, tombstones, refresh quota and unsubscribe |
| `YT-B-LIVE-READ` | Public live/upcoming discovery and read-only live chat | Eligible returned broadcasts, official playback, bounded `streamList`, chat disabled/empty/restricted and no owner-write claim |
| `YT-B-SHORTS` | Positively verified YouTube Shorts | Evidence-backed classification and official player; no native Shorts-feed claim or duration/aspect-ratio guess |
| `YT-B-CHANNEL` | Public channel detail and public playlists | Hidden counts, long text, pagination, removed/empty/error and provider links |

### Phase C — connected-viewer YouTube actions

Depends on separate incremental OAuth and a per-action reconciliation
contract. These are visibly YouTube-owned actions; MoolSocial-native Save,
Discuss and Follow remain separate.

| Ticket | Capability family | Required proof |
|---|---|---|
| `YT-C-RATING` | `videos.getRating` / `videos.rate` | Acting channel, pending/confirmed/reconciled/failure/revoked and no engagement reward |
| `YT-C-COMMENT` | comment/reply insert, update, delete and supported moderation where authorized | Exact target/author, character/permission errors, reconciliation and deleted/restricted states; `comments.markAsSpam` remains excluded rather than being mapped to `comments.setModerationStatus` |
| `YT-C-SUBSCRIBE` | subscriptions list/insert/delete | Exact acting/target channels, already subscribed/not subscribed, reconciliation and no personalized-feed promise |
| `YT-C-PLAYLIST` | playlists/items CRUD and playlist-images CRUD | User-named provider destination, ordering, duplicate/private/permission/media errors and MoolSocial Save separation |
| `YT-C-REPORT` | provider abuse reasons and `videos.reportAbuse` | Localized reason validation, deliberate confirmation, rate/quota/error handling |

### Phase D — creator/channel management

Lives in Account/Creator Workspace, not the public consumer feed.

| Ticket | Capability family | Required proof |
|---|---|---|
| `YT-D-VIDEO` | owned-video list/update/delete, scheduling and status reconciliation | Explicit destructive confirmation, provider state, retries and unaudited private-only enforcement |
| `YT-D-THUMBNAIL` | `thumbnails.set` | media validation, 50-unit budget and provider processing/error states |
| `YT-D-CAPTIONS` | captions list/download/insert/update/delete | Owner authorization, 50/200/400/450-unit budgets, locale/media validation and no arbitrary-public transcript claim |
| `YT-D-CHANNEL` | channels update, channel sections CRUD, channel banners, watermarks | Exact writable fields, asset validation, preview/confirmation, rollback and no imitation of YouTube Studio |
| `YT-D-PLAYLIST` | owner playlists/items/images | CRUD reconciliation, visibility and quota/cost controls |
| `YT-D-BRAND` | eligible creator-initiated `brandPartner` | Provider eligibility, resolved brand channel, paid-promotion disclosure and separate MoolSocial rights/attribution/payout ledger |

### Phase E — creator live workspace

Starts only after private upload, OAuth, moderation, support and live
operational owners exist.

| Ticket | Capability family | Required proof |
|---|---|---|
| `YT-E-BROADCAST` | broadcasts CRUD/bind/transition/cuepoint | Channel eligibility, scheduled/live/complete lifecycle, geo availability and idempotent recovery |
| `YT-E-STREAM` | streams CRUD and ingest binding | Secret handling, stream health, reconnect and no ingest credential leakage |
| `YT-E-CHAT` | chat list/stream/insert/delete and poll transition | Low-latency paging, author identity, slow/rate modes, eligibility and provider errors |
| `YT-E-MODERATION` | bans and moderators | Exact actor/target, temporary/permanent ban, audit, undo and abuse owner |
| `YT-E-MONETIZATION` | eligible midroll scheduling/pause/unpause, Super Chat/member/gifting/gift events | Returned provider eligibility, YouTube-owned money labels and no MoolSocial commission inference |

Removed `liveCuepoints.insert`, `liveBroadcasts.control`, old `sponsors` and
removed live-chat delete/retract event types are never implementation tickets.

### Phase F — creator intelligence and bulk reporting

| Ticket | Capability family | Required proof |
|---|---|---|
| `YT-F-ANALYTICS` | targeted Analytics metrics/dimensions | Valid metric/dimension combinations for content, geography, device/playback, traffic, retention, subscribers, Shorts/live, cards/end screens and reach |
| `YT-F-GROUPS` | Analytics groups/groupItems CRUD | Owner-only collections, 500-item limits where applicable, CRUD confirmation and deletion |
| `YT-F-REPORTING` | channel Reporting jobs/reportTypes/reports/media | Reporting service gate, first-data delay up to ~48h, daily CSV, 30-day historical backfill, replacement backfills, 30/60-day availability and secure storage/deletion |
| `YT-F-MONETARY` | monetary Analytics/Reporting | Separate monetary scope, legal owner, pricing/privacy decision and no cross-platform inferred revenue |

Ordinary eligible channels and partner content owners are separate reporting
identities. Content-owner/system-managed reports do not become available to a
normal creator connection.

### Phase G — provider-granted capabilities only

These are not build-ready backlog:

- Members/membership levels: wait for eligible channel plus explicit
  Google/YouTube representative access.
- Content ID, CMS, assets, claims, ownership and content-owner finance:
  wait for approved partner/content-owner status.
- Any live/member/brand capability that returns ineligible: keep disabled for
  that channel.
- Merchant/YouTube Shopping and Google Ads Demand Gen: remain in the separate
  Workspace backlog with their own program eligibility and payer.

### Permanent exclusions

Do not ticket personalized Home, native Shorts recommendations, Watch History,
Watch Later, provider notification inbox, Community-post creation, Stories,
arbitrary public transcripts, raw media URLs/download/offline/background
playback, provider-session embedding, ad-free playback, hidden attribution,
commerce/ads inside the player or the removed `comments.markAsSpam` method.
`comments.setModerationStatus` remains a distinct supported owner-moderation
capability and is never a substitute alias for the removed method.

## UI exposure contract

Each visible provider action must be either:

1. a real public capability backed by current provider data;
2. an authenticated capability for the exact connected YouTube channel; or
3. an eligibility-gated action shown only after a successful capability probe.

Customer UI must never show a decorative “coming soon” provider control, a
fabricated count/comment/connection, or a success state inferred from MoolSocial
sign-in. Missing provider fields are omitted.

Screen 04 remains blocked until Phase A live proof. The mandatory sequence is:

`live private-Dev proof -> editable HTML revision -> browser/state verification
-> founder FINAL -> new immutable reference -> native Flutter parity ->
physical OPPO acceptance`.

## Quota and cost truth

- Current documented defaults are 100 `search.list` calls/day/project,
  100 `videos.insert` calls/day/project, 10,000
  `videos.batchGetStats` calls/day/project and 10,000 general
  units/day/project. The current project console remains the promotion
  authority.
- Common reads are generally 1 unit, `members.list` is 2, most writes are 50,
  and caption download/insert/update are 200/400/450 respectively.
- Live, Analytics and Reporting limits must be captured from the exact Cloud
  project/service; do not invent a limit from the Data API unit table.
- Quota exhaustion rejects calls; it is not ordinary pay-as-you-go API media
  billing.
- Official embedded playback and direct YouTube upload avoid MoolSocial video
  streaming/storage cost, but MoolSocial still pays for Functions/Cloud Run,
  Firestore, logging, cache, network and operations it owns.
- Search pagination consumes another search call.
- Caption operations are high quota and remain deferred.
- Public or unlisted automated upload remains gated by the applicable YouTube
  compliance audit.
- The INR 1,000 monthly Dev budget is an alert target, not a hard cap.
- Higher quota uses the official audit/request path. Duplicate projects may
  not be created to evade quota.

## Immediate provider contracts within the phased backlog

1. **Embedded-player runtime**
   - eligibility, origin/Referer, one-player lifecycle, visibility/autoplay,
     fullscreen, state/error mapping, pause/dispose, provider links and
     lifecycle/interruption testing;
   - highest immediate Screen 04 value.
2. **WebSub approved-channel refresh**
   - approved-channel registry, leases, callback verification, deduplication,
     upload/update hydration, tombstones and scheduled renewal.
3. **Viewer actions**
   - incremental OAuth for ratings, comments/replies, subscriptions and
     user-named playlists;
   - each action remains visibly owned by YouTube.
4. **Creator post-upload lifecycle**
   - processing/status reconciliation, metadata, scheduling, thumbnail and
     separately gated captions.
5. **Live read plane**
   - live/upcoming discovery, provider playback and read-only live chat before
     any creator-live write plane.

The first two contracts and disabled local foundations are now recorded as:

- [YouTube embedded-player runtime contract](YOUTUBE-EMBEDDED-PLAYER-RUNTIME-CONTRACT-20260724.md)
- [YouTube WebSub approved-channel refresh contract](YOUTUBE-WEBSUB-APPROVED-CHANNEL-REFRESH-CONTRACT-20260724.md)

Local verification evidence:

- `artifacts/quality/youtube-embedded-player-local-20260724-01/LOCAL-PLAYER-FOUNDATION-EVIDENCE.md`
- `artifacts/quality/youtube-websub-local-20260724-01/LOCAL-WEBSUB-FOUNDATION-EVIDENCE.md`

These checkpoints prove typed local behavior only. No WebView platform adapter,
provider playback, WebSub endpoint, subscription, export, cloud activation,
Screen 04 revision or OPPO provider acceptance is claimed.

## Screen 04 consequences

- Videos may become the first Social destination.
- The next editable HTML may change its prior rail, hierarchy and placement
  when provider-observed behavior warrants it.
- Discovery is a MoolSocial catalogue with clear YouTube source identity, not a
  claim of native YouTube ranking.
- The official player is the playback authority. HTML can model layout,
  loading, unavailable and recovery boundaries but cannot prove player
  behavior.
- MoolSocial commerce, campaigns and advertising stay outside the player and
  cannot imply YouTube endorsement or attach arbitrary products to unrelated
  provider content.
- MoolSocial Feed/Create remain proprietary, and MoolSocial history, saves,
  notifications and discussions must be labelled as MoolSocial-owned.

## Official authorities

- <https://developers.google.com/youtube/terms/developer-policies-guide>
- <https://developers.google.com/youtube/terms/required-minimum-functionality>
- <https://developers.google.com/youtube/v3/determine_quota_cost>
- <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>
- <https://developers.google.com/youtube/iframe_api_reference>
- <https://developers.google.com/youtube/v3/guides/push_notifications>
- <https://developers.google.com/youtube/v3/docs/videos/insert>
- <https://developers.google.com/youtube/v3/guides/implementation/comments>
- <https://developers.google.com/youtube/v3/revision_history>
- <https://developers.google.com/youtube/v3/docs/captions/download>
- <https://developers.google.com/youtube/analytics/reference/reports/query>
- <https://developers.google.com/youtube/reporting/v1/reports>
- <https://developers.google.com/youtube/v3/live/docs>
- <https://developers.google.com/youtube/v3/live/revision_history>
- <https://developers.google.com/youtube/v3/docs/members>
- <https://developers.google.com/youtube/reporting/v1/reports>
- <https://developers.google.com/youtube/reporting/v1/reports/full_report_list>
- <https://developers.google.com/youtube/reporting/revision_history>
- <https://developers.google.com/youtube/partner>

## Authoritative 25 July 2026 reconciliation checkpoint

This section supersedes the earlier method-coverage and four-profile
operational descriptions in this audit without deleting their historical
context.

### Complete official-method accounting

The current registry reconciles every one of the `99` official methods:

| Classification | Count | Release meaning |
| --- | ---: | --- |
| Implemented locally | 87 | Privileged backend route, typed native-Flutter contract and focused local tests exist; customer availability remains disabled. |
| Provider/eligibility gated | 8 | Requires provider, representative, content-owner, channel or programme access before any proof or UI claim. |
| Excluded/no approved customer value | 3 | Unsupported, deprecated or intentionally excluded from the MoolSocial product. |
| Disabled transport gap | 1 | `liveChatMessages.streamList` is not safely bridged by the present generated-stub and long-lived transport architecture. |
| **Total** | **99** | Complete official inventory; no method is silently unclassified. |

The bounded read-only live-chat path uses
`liveChatMessages.list`. It remains behind the `Live` proof profile and is not
a claim that streaming or customer live chat is available.

An implemented method is not automatically a visible control. The native UI
exposes customer intents, groups related plumbing behind those intents and
hides every capability that has not passed its own consent, eligibility,
quota, cost, recovery and founder gate.

### Current private-Dev control plane

The exact Dev project has these three approved services enabled:

- `youtube.googleapis.com`;
- `youtubeanalytics.googleapis.com`; and
- `youtubereporting.googleapis.com`.

The Google Auth Platform external brand and dedicated confidential backend
OAuth client have been created. No identifier, secret, token or reviewer
credential belongs in this audit.

The seven proof profiles are `PublicData`, `OwnerConnect`, `OwnerActions`,
`CreatorAssets`, `Live`, `PrivateUpload` and `OwnerAnalytics`. All seven are
`false` by default, activate only for a supervised private-Dev proof, expire
within at most 30 minutes and return to `false` after the proof.

This checkpoint records local readiness only. It does not claim a live
provider response, completed YouTube consent, connected channel, owner
mutation, creator asset operation, private upload, Analytics/Reporting result,
live operation, Screen 04 customer availability, Flutter provider parity,
physical OPPO acceptance, Staging or Production.

Merchant API and Google Ads Demand Gen remain separate signed-in Workspace
work. They are not YouTube Social methods, are not enabled by this inventory
and may not appear in the private-Dev proof or its customer UI.
