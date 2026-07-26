# ADR-0006 — YouTube API-first Social integration

- Status: **accepted; comprehensive native-app capability contract recorded,
  minimum private-Dev activation and live proof pending**
- Founder direction: 23 July 2026
- Environment: `moolsocial-dev-503018` only
- Branch: `remediation/prototype-conformance-2026-07-20`
- Supersedes: only the sequencing in Gate 3 of
  `SOCIAL-MODULE-GO-LIVE-CASCADE-20260722.md`
- Does not supersede: the native Flutter V2 architecture, Screens 01–03 locks,
  immutable approved references, provider policy boundaries, or the requirement
  for explicit founder acceptance before production promotion

## Context

The founder directed an API-first checkpoint before further Screen 04 Social
UI decisions. The objective is to learn and prove the real YouTube capability
boundary before MoolSocial finalizes its Shorts and Videos interaction design.

The active Screen 04 v9 HTML remains an editable, unapproved draft. It is not
frozen, does not update the approved manifest and does not authorize additional
Flutter UI work. Immutable v8 and its native evidence remain historical
evidence, not current founder acceptance.

## Decision

MoolSocial will assess and, when the applicable gate is passed, integrate the
complete set of generally available YouTube capability families that can add
truthful value inside the native MoolSocial app:

1. **YouTube Data API v3**
   for public discovery metadata, connected-channel metadata, user-authorized
   YouTube actions, creator uploads, creator/channel management and eligible
   live operations.
2. **YouTube IFrame Player API**
   for official YouTube playback inside an OS-provided Android `WebView` or
   Apple `WKWebView`. This is the sole approved WebView exception.
3. **YouTube Analytics API v2**
   for targeted, channel-owner-authorized performance queries and authorized
   groups/group-items.
4. **YouTube Reporting API v1**
   for delayed bulk channel reports after its separate service, storage,
   retention and operating-cost gate is approved.
5. **YouTube WebSub / PubSubHubbub notifications**
   for approved-channel upload and title/description refresh hints, followed
   by normal Data API hydration.
6. **YouTube Live Streaming API resources**
   for public live discovery/read surfaces and, only after eligibility,
   moderation and operational proof, creator live management.

This is a capability inventory and phased contract, not permission to enable
every service or scope at once. Each capability stays independently disabled
until its public/OAuth, quota, cost, privacy, eligibility, audit, UI and
rollback gate passes. The current private-Dev deployment manifest remains the
minimum four-profile proof and is not silently widened by this ADR.

All surrounding discovery, navigation, commerce, attribution, account,
campaign and recovery UI remains native Flutter V2 and MoolSocial-owned.
There is no MoolSocial web product in this architecture. The only provider
HTML permitted in the app is the isolated official-player bootstrap described
above; it contains no MoolSocial presentation, authentication, form,
navigation, commerce or business logic.

## Product boundary

### MoolSocial can provide

- a native, paginated library of eligible public YouTube videos;
- public metadata, thumbnails, channel details, statistics, playlists and
  comments that the current APIs actually return;
- public charts by region/category;
- explicit user search within the small default search quota;
- curated or approved-channel upload feeds;
- official in-app playback without sending the user to the YouTube app;
- optional connected-account actions such as like, comment, subscribe and
  playlist operations, each clearly identified as a YouTube action;
- creator upload to the creator's selected YouTube channel after separate
  consent;
- optional creator-initiated brand-partner access for eligible creator/deal
  combinations using the provider's current `brandPartner` contract;
- creator-owned analytics and reporting after separate analytics consent; and
- MoolSocial-owned campaign links, product context and attributable commerce
  outside the YouTube player.

### MoolSocial cannot claim or recreate

- the user's personalized YouTube Home recommendations;
- the native YouTube Shorts recommendation feed;
- a complete YouTube application running inside MoolSocial;
- a guarantee that every provider link stays inside MoolSocial; YouTube-owned
  links or required account/help surfaces may hand off to YouTube or a system
  browser;
- general watch history or Watch Later access;
- a dependable public Data API flag that classifies every public video as a
  Short;
- hidden or fabricated YouTube likes, comments, subscriptions or metrics;
- downloading, caching or offline playback of YouTube audiovisual content;
- covered, restyled or obstructed YouTube player controls, branding, links or
  advertising; or
- MoolSocial advertising placed on or inside YouTube content or its player.

MoolSocial also cannot claim or recreate Community-post creation, Stories,
public transcripts for arbitrary videos, raw audiovisual URLs, provider
downloads, the provider notification inbox, or a provider-authenticated
browser session. There is no dedicated Shorts upload endpoint and no reliable
general-purpose `isShort` field.

Familiar low-effort media interaction is allowed. Copying YouTube trade dress
or representing MoolSocial as YouTube is not.

## Discovery model

The default MoolSocial YouTube library uses, in order:

1. `videos.list(chart=mostPopular, regionCode=IN)` for a low-quota public
   starting set;
2. approved channel upload playlists using `channels.list` followed by
   `playlistItems.list`;
3. curated public playlists;
4. PubSubHubbub channel notifications to refresh uploads without constant
   polling;
5. `videos.list` or `videos.batchGetStats` to hydrate and refresh public
   metadata; and
6. `search.list` only for explicit user search or tightly budgeted discovery.

This is a MoolSocial-ranked library. It must not be labelled or presented as
YouTube Home, YouTube recommendations or the user's native YouTube feed.

## Shorts classification

The public Data API still does not provide a general, dependable `isShort`
field. MoolSocial may put a YouTube item into its Shorts flow only when the
classification is positively known, for example:

- the item was uploaded through MoolSocial with a qualifying vertical-media
  contract and the resulting YouTube classification is confirmed;
- the creator or an approved curator supplied a known Shorts collection; or
- an official API field or authorized analytics dimension positively
  identifies it.

Duration or aspect ratio alone is not proof. Uncertain items stay in Videos.

## Authentication and authorization

MoolSocial account sign-in remains separate from YouTube channel connection.
YouTube consent begins only from the feature that needs it.

- Public metadata: restricted server credential; no user OAuth.
- Creator upload: minimum `youtube.upload` scope.
- Connected read features: minimum `youtube.readonly` scope.
- Like, comment, subscription or playlist mutation: request the narrowest
  scope supported by YouTube only when the user invokes that feature.
- Creator analytics: `yt-analytics.readonly` plus the required YouTube read
  scope.
- Monetary analytics: excluded from MVP unless separately justified.
- Content-owner/partner and channel-membership scopes: excluded from MVP.

OAuth must use the system browser and Authorization Code with PKCE. Google
authorization must never run inside the player WebView. Client secrets,
refresh tokens, passwords and OTPs must never be committed or placed in logs.
Connected users must be able to see the selected YouTube channel, revoke the
connection and delete MoolSocial's retained authorized data.

## Upload and media-cost architecture

MoolSocial does not proxy or permanently store YouTube-bound long-form media.
The preferred upload path is:

1. the user chooses the exact YouTube channel, media, title, description,
   privacy and required audience declarations;
2. the backend validates the connected account and initializes a resumable
   `videos.insert` session;
3. the mobile app receives only a short-lived user access token and resumable
   session data, then uploads bytes directly to YouTube;
4. MoolSocial retains the job state, consent record, external video ID,
   campaign linkage and permitted metadata, not a permanent media copy; and
5. retries are idempotent and resumable.

The refresh token remains in an encrypted server-side token vault. A short-lived
access token must be memory-only in the app. A future scheduled-publishing
service may upload through controlled infrastructure, but its storage and
egress cost must be separately approved.

This design avoids MoolSocial video hosting and delivery cost for YouTube-bound
content. It does **not** make the whole feature cost-free: MoolSocial still owns
backend execution, token custody, metadata refresh, moderation, attribution,
monitoring, support and compliance costs.

## Quota and scalability decision

Google's current 2026 default allocation is:

- 100 `search.list` calls per project per day;
- 100 `videos.insert` calls per project per day; and
- 10,000 units per day combined for the remaining Data API methods.

The two first methods use separate granular quota buckets. Every request,
including an invalid request, consumes quota. These defaults are suitable for
Dev proof, not an unrestricted public launch. Production scale requires an
approved compliance/quota request; MoolSocial must never create extra projects
to evade limits.

YouTube documents quota allocation rather than per-request billing for these
services. Therefore the integration is designed for **no YouTube API
per-request charge and no MoolSocial YouTube-video hosting/streaming charge
within approved quota**, not an unconditional zero-cost guarantee.

Every capability must be classified before release as provider-quota-only,
MoolSocial low operating cost, MoolSocial material operating cost, external
spend/media-heavy cost, or provider/audit gated. “Free tier” is a limited
allowance, not a permanent price promise. The authoritative classification is
`YOUTUBE-MOOLSOCIAL-PRODUCT-AND-COST-MAP-20260723.md`.

## Commercial boundary

MoolSocial may show independent commerce or advertising on a screen containing
YouTube API data only when the non-YouTube product, service or commerce content
would independently justify that commercial placement if all YouTube data were
removed.

MoolSocial must never:

- overlay commerce on the YouTube player;
- obscure or interfere with YouTube ads or controls;
- attach fabricated commerce to an unrelated public YouTube item;
- pay or incentivize a user to watch or engage with YouTube content; or
- imply that a creator earns commission from YouTube views.

Creator commission remains attributable only to eligible delivered MoolSocial
orders under ADR-0003.

Public YouTube watching remains free. MoolSocial does not sell YouTube access
or charge for functionality YouTube ordinarily provides free. It may charge
for independent MoolSocial value such as campaign management, product
attribution, order/return/commission/payout records, creator workflow, team
approvals, MoolSocial sales analytics and explicitly selected managed-media
services. Any external advertising spend or material cloud/media cost remains
off until a named payer, price, budget and automatic cutoff are approved.

The July 2026 `brandPartner` API part may be used for an eligible creator to
share provider-recognized access with a selected brand YouTube channel. It is
not a substitute for rights agreements, paid-promotion disclosure, MoolSocial
campaign linkage, delivered-order attribution or creator payout records.

## API-first order

1. Preserve Screen 04 v9 as `DRAFT / HOLD`.
2. Freeze no new Screen 04 reference and change no Flutter UI.
3. Complete the official endpoint, quota, policy and UI-exposure inventory.
4. Reauthenticate the founder-owned Dev Cloud session without sharing secrets.
5. Enable only the approved APIs in `moolsocial-dev-503018`.
6. Create environment-restricted credentials and consent configuration.
7. Build a non-UI provider spike behind Dev-only feature flags.
8. Prove public discovery, player, private upload, analytics and failure states.
9. Record real response shapes, omitted fields, eligibility failures, quota
   behavior and player events; a documented endpoint is not UI proof.
10. Revise Screen 04 HTML only against those observed provider contracts.
11. Resume the normal founder `FINAL` -> freeze -> Flutter -> OPPO acceptance
    workflow.

No Screen 04 HTML, frozen reference or Flutter presentation may expose a
capability merely because it appears in an official reference. The binding
sequence is:

`official inventory -> disabled adapter contract -> live private-Dev proof ->
editable HTML -> founder FINAL -> immutable freeze -> native Flutter parity ->
physical OPPO acceptance`.

Partner-only, representative-gated, eligibility-gated and deprecated
capabilities never enter this sequence until the provider grants the required
access and a new explicit product decision exists.

## Live proof gates

Before any UI may rely on YouTube, Dev evidence must prove:

- multiple public videos from at least two legal discovery sources;
- official player start, pause, completion, error, fullscreen, orientation,
  audio focus, app-switch and resume behavior;
- non-embeddable, private, removed, age-restricted, region-restricted,
  Made-for-Kids and network/quota failures;
- private upload with title, description, privacy and selected-channel
  confirmation;
- upload cancellation, retry, resume and idempotency;
- connection revocation and retained-data deletion;
- metadata refresh/deletion within the 30-day policy boundary;
- quota stop, cache fallback and service-disable rollback; and
- no credential, token, API key or personal data in repository artifacts.

Public upload remains blocked until the YouTube API compliance audit removes
the unaudited-project private-only restriction.

## Live Dev activation checkpoint

On 23 July 2026 the founder completed the approved minimum service enablement
inside Google Cloud Shell for `moolsocial-dev-503018`:

- project number observed in the successful operation:
  `760290687711`;
- enabled service: `youtube.googleapis.com`;
- enabled service: `youtubeanalytics.googleapis.com`;
- successful Google operation:
  `operations/acat.p2-760290687711-a9ca0f31-b826-4955-8486-7e66dc423ca2`;
- `youtubereporting.googleapis.com` remains disabled/deferred until the bulk
  reporting proof is approved; and
- no API key, OAuth client, refresh token or other credential was created.

This service activation is not a live integration, does not approve a UI and
does not authorize Staging or Production. The next Cloud gates are the
read-only service/quota/credential inventory, restricted credential design,
OAuth consent configuration and private Dev provider proof.

The workspace now contains a portable Google Cloud SDK, but every local call
must use the repository-scoped isolated Cloud configuration for
`moolsocial-dev-503018`; the machine-default Google configuration is unrelated
and forbidden. The isolated configuration currently has no active account.
Firebase CLI `15.5.1` is intentionally logged out and requires a fresh
provider-owned login if local deployment access becomes necessary. Passwords,
OTPs, recovery codes, API keys and OAuth secrets must never be sent to Codex;
the founder enters them only into the provider's own surface.

## Authoritative provider sources

- Data API reference:
  <https://developers.google.com/youtube/v3/docs>
- 2026 quota calculator:
  <https://developers.google.com/youtube/v3/determine_quota_cost>
- 2026 revision history:
  <https://developers.google.com/youtube/v3/revision_history>
- Resumable uploads:
  <https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol>
- IFrame Player API:
  <https://developers.google.com/youtube/iframe_api_reference>
- Required minimum functionality:
  <https://developers.google.com/youtube/terms/required-minimum-functionality>
- Developer policies:
  <https://developers.google.com/youtube/terms/developer-policies>
- Policy compliance guide:
  <https://developers.google.com/youtube/terms/developer-policies-guide>
- Installed-app OAuth:
  <https://developers.google.com/identity/protocols/oauth2/native-app>
- Analytics API:
  <https://developers.google.com/youtube/analytics/reference/reports/query>
- Reporting API:
  <https://developers.google.com/youtube/reporting>
- Push notifications:
  <https://developers.google.com/youtube/v3/guides/push_notifications>
- Current discovery documents:
  <https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest>,
  <https://youtubeanalytics.googleapis.com/$discovery/rest?version=v2> and
  <https://youtubereporting.googleapis.com/$discovery/rest?version=v1>

## Founder override — YouTube-centred Screen 04 after provider proof

On 24 July 2026 the founder authorized the editable Screen 04 Social
presentation to be substantially adapted around YouTube as a primary
MoolSocial engagement centre when the verified provider contract requires it.
This supersedes the earlier instruction to preserve the current Screen 04
layout unchanged, but it does not bypass the conformance workflow:

1. complete and verify the permitted Dev API contracts first;
2. revise the editable HTML against those observed contracts;
3. present the exact HTML URL and checksum for founder review;
4. freeze nothing and change no Flutter presentation until the founder marks
   that HTML state `FINAL`; and
5. after `FINAL`, implement native Flutter parity and repeat physical OPPO
   acceptance.

“YouTube-centred” does not mean an indistinguishable YouTube clone. YouTube
source identity, unmodified metadata, standard player controls, ads, outbound
links and required attribution remain visible. MoolSocial must add independent
value through its own Feed, commerce, creator campaign, attribution, earning
and workspace services. Personalized YouTube Home, native recommendation
ranking, Watch History, Watch Later and an authoritative public Shorts feed
remain unavailable because the APIs do not expose them.

The founder also supplied evidence of a successful INR 3,000 Google Cloud
payment. Separate Cloud Shell verification reports billing account
`01F9D3-44031C-B5E225` open and linked to
`moolsocial-dev-503018`. The payment is not the monthly Dev budget-alert
value. The founder subsequently approved, and Cloud Shell independently
verified, the exact `INR 1,000` monthly project-scoped alert with 50%, 80% and
100% thresholds. It is an alert target, not a hard spending cap.

## 24 July public and owner P1 local verification

The MVP public-catalogue and owner P1 server contracts now pass `116/116`
backend tests and the complete private-Dev package gate with every provider
capability disabled. The owner contract includes provider-supported page
sizes and subscription ordering, fixed Analytics presets with 1-based
continuation, and fail-closed 30-day channel-identity revalidation.

Evidence:
`artifacts/quality/youtube-provider-schema-validation-20260724-08/PUBLIC-OWNER-P1-VERIFICATION-EVIDENCE.md`.

This does not authorize cloud deployment, Screen 04 revision, Flutter
presentation changes, Staging or Production. The next provider-proof
boundaries are:

- `docs/delivery/YOUTUBE-EMBEDDED-PLAYER-RUNTIME-CONTRACT-20260724.md`; and
- `docs/delivery/YOUTUBE-WEBSUB-APPROVED-CHANNEL-REFRESH-CONTRACT-20260724.md`.

## 25 July 2026 superseding private-Dev checkpoint

This checkpoint supersedes earlier operational statements in this ADR that
described only two enabled YouTube services, deferred Reporting, four proof
profiles or no Google Auth Platform brand/client. Those statements remain
historical records of the sequence in which the environment was prepared.

The current official inventory contains `99` YouTube methods:

- `87/99` are implemented locally through the privileged backend contract,
  typed native-Flutter client contract and focused deterministic tests;
- `8/99` require provider, representative, content-owner, channel or
  programme eligibility and therefore remain provider-gated;
- `3/99` are excluded because they are unsupported, deprecated or have no
  approved MoolSocial customer value; and
- `liveChatMessages.streamList` remains deliberately disabled because the
  current generated-stub and long-lived streaming transport boundary cannot be
  completed safely. Bounded `liveChatMessages.list` is the approved read-only
  live-chat fallback.

“Implemented locally” proves a disabled adapter contract. It does not prove a
live YouTube response, provider eligibility, a customer-visible feature or
production readiness.

The exact private-Dev project now has all three approved service families
enabled:

- `youtube.googleapis.com`;
- `youtubeanalytics.googleapis.com`; and
- `youtubereporting.googleapis.com`.

An external Google Auth Platform brand and the dedicated confidential backend
OAuth client have been created for `moolsocial-dev-503018`. Client identifiers,
client secrets, tokens and review credentials remain outside this document and
repository. Secure secret custody, test-user consent and live provider
reconciliation remain open gates.

The deployment control plane now has seven independently bounded proof
profiles:

1. `PublicData`;
2. `OwnerConnect`;
3. `OwnerActions`;
4. `CreatorAssets`;
5. `Live`;
6. `PrivateUpload`; and
7. `OwnerAnalytics`.

Every profile defaults to `false`, may be activated only for one supervised
private-Dev proof, and has a maximum activation window of 30 minutes. Initial
deployment and every rollback return all seven profiles to `false`.

No live public-data proof, owner connection, owner action, creator-asset
mutation, live operation, private upload, Analytics/Reporting result, physical
OPPO provider acceptance or customer availability is claimed by this
checkpoint. Screen 04 remains bound to the normal observed-provider ->
editable-HTML -> founder `FINAL` -> immutable-freeze -> native-Flutter ->
physical-OPPO sequence.

Merchant API and Google Ads Demand Gen remain deferred to the signed-in
Workspaces module under ADR-0007. They are not part of the YouTube Social
proof, its OAuth client, its customer UI or this ADR's release scope.
