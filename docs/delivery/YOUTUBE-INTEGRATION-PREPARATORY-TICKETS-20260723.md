# YouTube integration preparatory tickets — 23 July 2026

Status: **active API-first Dev/Trial backlog; no production promotion**

25 July 2026 reconciliation:

- the authoritative all-family capability classification and phase order is
  `YOUTUBE-COMPREHENSIVE-CAPABILITY-GAP-AUDIT-20260724.md`;
- the exact endpoint/method/UI contract is
  `YOUTUBE-API-CAPABILITY-AND-ENDPOINT-MATRIX-20260723.md`;
- this file remains the execution-ticket register for the minimum private-Dev
  proof and its successors;
- documenting a later ticket does not widen the current deployment manifest;
  and
- no MoolSocial web product is planned. Native Flutter V2 remains mandatory,
  with only the isolated official YouTube player permitted in an OS WebView.

Authority:

- `ADR-0006-YOUTUBE-API-FIRST-SOCIAL-INTEGRATION.md`
- `SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`
- `ENVIRONMENT-PROMOTION-BOUNDARY.md`
- YouTube API Services policies and required minimum functionality

Environment order:

`local contract tests -> moolsocial-dev-503018 -> Dev App Distribution Preview
-> moolsocial-staging-503018 -> later Production`

The active Screen 04 v9 HTML is `DRAFT / HOLD`. No ticket below freezes it,
updates the approved manifest or authorizes Flutter UI changes.

## Baseline inventory before implementation

The following is a time-stamped 23 July baseline, not current-state authority:

- current Flutter YouTube catalogue, account connection, player and creator
  publication states are simulated/review-only;
- Screen 03's YouTube sign-in uses Google basic identity and correctly requests
  no YouTube channel scopes;
- no official YouTube player/WebView host, Google OAuth/PKCE, HTTP or Google
  API dependency is present in the mobile package;
- no external-account, publication-job or provider-metrics owner exists in the
  current Data Connect schema;
- the backend Functions folder is a placeholder and no token vault exists;
- `.firebaserc` correctly maps Dev to `moolsocial-dev-503018`, while local
  remains `demo-moolsocial-local`;
- no tracked provider credential or service-account file was found; and
- the current editable screenbook Screen 04 draft has SHA-256
  `667190F9E1837721BC6D9E4A19090FA089A67CFDF02A73FCE42DFE8408F91E93`.
  Existing v9 evidence targets earlier hashes and does not verify this draft.

Relevant current implementation owners:

- `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart`
- `apps/mobile/lib/ui_v2/social/social_v2_youtube_connect.dart`
- `apps/mobile/lib/features/creator/creator_services.dart`
- `apps/mobile/lib/features/creator/creator_session.dart`
- `apps/mobile/lib/features/journey01/review_journey_services.dart`
- `dataconnect/schema/universal.gql`
- `backend/functions/README.md`

These files are inventory, not authorization to patch the current Flutter UI
before the provider-observed HTML becomes founder-final and frozen.

Later local provider, Firestore, player and WebSub foundations supersede the
baseline implementation observations above. Their evidence is recorded in the
24–25 July checkpoints in ADR-0006, ADR-0008 and the capability-gap audit.

## Outcome definition

The Dev proof is complete only when MoolSocial can:

1. show a truthful, paginated native library of eligible public YouTube
   content from supported sources;
2. play a selected item in the official embedded player inside MoolSocial;
3. connect a creator's YouTube channel separately from MoolSocial sign-in;
4. upload one private test item directly to that selected channel without
   permanently storing or proxying its media through MoolSocial;
5. retrieve permitted creator-owned analytics;
6. enforce quota, policy, privacy, revocation and rollback boundaries; and
7. provide observed capability evidence for a new founder-review Screen 04
   HTML revision.

## Phase 0 — protect accepted work and establish authority

### `YT-GOV-001` — Hold Screen 04 UI work

- Owner: UI conformance
- Status: **in force**
- Work:
  - leave active v9 HTML editable and unapproved;
  - preserve immutable v8 and all existing evidence;
  - change no Screen 04 Flutter, routes, tests or manifest entries during the
    API spike.
- Acceptance:
  - git evidence shows no API-spike mutation to the screenbook or Flutter UI;
  - no new `FINAL`, frozen reference or native-acceptance claim exists.

### `YT-GOV-002` — Register current provider authorities

- Owner: architecture/compliance
- Status: **completed by analysis; recurring before release**
- Work:
  - record the Data, Player, Analytics and Reporting API references;
  - record current quota, caching, branding, advertising and upload rules;
  - repeat the check before Staging and Production.
- Acceptance:
  - capability matrix links only to current official Google/YouTube sources;
  - the checked date and discovery-document revisions are recorded.

## Phase 1 — founder-owned Cloud access

### `YT-CLOUD-001` — Securely reauthenticate Dev access

- Owner: founder
- Status: **completed for Cloud Console and Cloud Shell; local Firebase CLI
  intentionally logged out and requires a fresh provider-owned login before
  deployment**
- Work:
  - complete Google account verification in Google's own surface;
  - run `firebase login --reauth` personally if CLI access is required;
  - never send the password, OTP or recovery code to Codex.
- Acceptance:
  - Cloud Shell and, when a CLI deployment is actually attempted, a freshly
    authenticated Firebase CLI can read the exact Dev project;
  - the Cloud Console opens `moolsocial-dev-503018` without a verification
    redirect;
  - no credential value appears in terminal history, chat or repository.

### `YT-CLOUD-002` — Verify project identity, billing and existing services

- Owner: platform
- Depends on: `YT-CLOUD-001`
- Status: **identity/billing inventory complete; deployment gates continue**
- Verified:
  - authenticated project ID: `moolsocial-dev-503018`;
  - project number: `760290687711`;
  - lifecycle: ACTIVE;
  - billing account `01F9D3-44031C-B5E225` is open and linked to this Dev
    project;
  - the only observed API key is a Firebase Browser key restricted to Firebase
    APIs, not YouTube;
  - project quotas, service account metadata and enabled services were
    inventoried without secret values;
  - Dev/Trial was the only changed environment.
- Evidence:
  - `artifacts/quality/youtube-private-dev-cloud-bootstrap-20260723-01/CLOUD-BOOTSTRAP-EVIDENCE.md`.
- Work:
  - verify active project number and organization;
  - inventory enabled services, quotas and credentials without exposing secret
    values;
  - confirm that only Dev/Trial is in scope.
- Acceptance:
  - evidence identifies project ID and project number;
  - Staging and future Production remain unchanged;
  - no duplicate project is created to gain quota.

### `YT-CLOUD-003` — Enable the minimum API set

- Owner: platform
- Depends on: `YT-CLOUD-002`
- Status: **minimum provider and reviewed server prerequisites enabled;
  Reporting remains deferred**
- Dev services:
  - `youtube.googleapis.com` — enabled 23 July 2026;
  - `youtubeanalytics.googleapis.com` — enabled 23 July 2026; and
  - `firebaseappcheck.googleapis.com` — enabled 23 July 2026;
  - `youtubereporting.googleapis.com` only when its deferred bulk-report proof
    begins.
- Evidence:
  - founder-run Cloud Shell command completed successfully;
  - Google operation:
    `operations/acat.p2-760290687711-a9ca0f31-b826-4955-8486-7e66dc423ca2`;
  - no YouTube API key or OAuth credential was created;
  - the reviewed private-Dev server prerequisites now exist under the exact
    ADR-0008 and deployment-manifest allowlist;
  - Firebase Data Connect and Cloud SQL remain deferred/disabled for this
    proof.
- Acceptance:
  - service state is captured before and after;
  - each service has a named owner, feature flag and rollback command;
  - no unrelated API is enabled.

### `YT-CLOUD-004` — Configure quota controls

- Owner: platform/SRE
- Depends on: `YT-CLOUD-003`
- Status: **project limits captured and local caps verified; live alerts and
  automatic-stop proof pending**
- Work:
  - record actual Dev granular limits shown in Cloud Console;
  - configure application-side budgets below provider limits;
  - add alerts and automatic stops for search, upload and general requests.
- Initial Dev caps:
  - search: 20 calls/day until caching proof;
  - upload: 10 private test calls/day;
  - batch statistics: 500 calls/day;
  - Analytics: 100 queries/day; and
  - other methods: 2,000 units/day.
- Observed project limits:
  - Data API: 10,000 units/day/project;
  - `search.list`: separate default 100 calls/day/project bucket;
  - `videos.insert`: separate default 100 calls/day/project bucket; and
  - `videos.batchGetStats`: separate default 10,000 calls/day/project bucket.
- Acceptance:
  - caps can be lowered without a mobile release;
  - a quota-stop test returns a professional customer state and no retry
    storm;
  - quota exhaustion cannot spill into Staging credentials.

## Phase 2 — credential and consent design

### `YT-CRED-001` — Public metadata server credential

- Owner: security/platform
- Depends on: `YT-CLOUD-003`
- Status: **restricted Dev server key and Secret Manager secret exist; live
  provider-call/rotation proof pending**
- Work:
  - create one Dev server credential restricted to the YouTube Data API;
  - keep it in the approved secret store;
  - route public discovery through a server-side broker.
- Acceptance:
  - no API key exists in Dart, assets, repository, screenshots or logs;
  - API restriction is `youtube.googleapis.com`;
  - application/network restriction is documented and tested;
  - rotation and disable evidence exists.

### `YT-CRED-002` — Confidential backend OAuth client

- Owner: identity/security
- Depends on: `YT-CLOUD-002`
- Status: **local contract implemented; Cloud client and consent proof
  pending**
- Work:
  - create one Web application OAuth client for the privileged backend;
  - use the system browser with Authorization Code, PKCE and cryptographic
    state;
  - register the exact fixed HTTPS Firebase Functions callback;
  - keep the client secret, refresh tokens and token exchange out of Flutter.
- Acceptance:
  - no client secret is embedded in a mobile build;
  - wrong redirect URI and replayed state are rejected;
  - PKCE verifier is encrypted in the privileged short-lived OAuth-attempt
    store;
  - Google authorization never loads in the player WebView.

### `YT-CONSENT-001` — OAuth consent and policy surface

- Owner: legal/privacy/identity
- Depends on: founder policy inputs
- Status: pending
- Work:
  - configure app name, support email, authorized domains and test users;
  - publish privacy policy and terms;
  - disclose Data API and Google privacy controls;
  - request scopes incrementally from the invoking feature.
- Acceptance:
  - sign-in requests only basic identity;
  - YouTube connection is a later, separate consent;
  - selected channel, scope purpose, privacy consequence, revoke path and
    retained-data behavior are clear;
  - consent verification/audit requirements are recorded.

### `YT-SEC-001` — Token vault and ephemeral access

- Owner: security/backend
- Depends on: `YT-CRED-002`
- Status: **local contract implemented and tested; live Firestore/IAM/token
  proof pending**
- Work:
  - encrypt refresh tokens per user and environment;
  - mint short-lived access tokens for direct upload;
  - keep mobile access tokens memory-only;
  - record revocation and token-deletion events.
- Acceptance:
  - token values are redacted from all logs;
  - Dev and Staging encryption/credentials cannot cross;
  - revoke removes the refresh token and invalidates the connection;
  - compromised-credential rotation has a tested runbook.

## Phase 3 — provider adapter foundation

### `YT-CORE-001` — YouTube capability registry

- Owner: backend
- Status: **implemented and verified locally; live Dev deployment pending**
- Work:
  - represent availability, auth requirement, quota bucket, policy gate and
    feature flag for each supported endpoint;
  - expose a non-secret capability response to native clients.
- Acceptance:
  - UI can hide or disable unavailable actions truthfully;
  - a provider change does not require hard-coded screen copy;
  - no capability is inferred from a successful sign-in alone.

### `YT-CORE-002` — Request broker, cache and coalescing

- Owner: backend
- Depends on: `YT-CRED-001`
- Status: **implemented and verified locally; live provider observation
  pending**
- Work:
  - centralize Data API calls, field masks, ETags, retries and backoff;
  - coalesce identical in-flight requests;
  - isolate public and user-authorized calls.
- Acceptance:
  - an invalid request does not loop;
  - repeated identical reads hit the cache;
  - logs contain operation name, quota bucket and correlation ID but no token
    or key.

### `YT-CORE-003` — Authorized-data lifecycle

- Owner: privacy/backend
- Status: **local disconnect/deletion and connection-gated concurrency
  contracts implemented; live revocation and retention proof pending**
- Work:
  - label source, authorization basis and retrieval time;
  - refresh or delete stored API data within the applicable 30-day boundary;
  - verify authorization and deletion status at least every 30 days.
- Acceptance:
  - scheduled refresh/deletion is idempotent;
  - revoke immediately removes access to authorized data;
  - exported data distinguishes YouTube data from MoolSocial data.

## Phase 4 — public discovery and metadata

### `YT-DISC-001` — Regional public chart

- Endpoint: `videos.list`
- Owner: backend
- Status: **local broker contract implemented; live provider proof pending**
- Work:
  - request `chart=mostPopular`, `regionCode=IN` and supported category;
  - hydrate only required public parts.
- Acceptance:
  - returns multiple distinct playable items;
  - pagination, empty, unsupported-chart and quota states pass;
  - no claim of personalization appears.

### `YT-DISC-002` — Approved-channel uploads

- Endpoints: `channels.list`, `playlistItems.list`, `videos.list`
- Owner: backend
- Status: **local channel/playlist contract implemented; approved-registry and
  live provider proof pending**
- Work:
  - resolve a channel's uploads playlist;
  - page through uploads and hydrate video records.
- Acceptance:
  - channel, title, thumbnail, publication time and video IDs remain
    internally consistent;
  - removed/private items disappear on refresh;
  - no `search.list` call is used for ordinary channel pagination.

### `YT-DISC-003` — Curated public playlists

- Endpoints: `playlists.list`, `playlistItems.list`, `videos.list`
- Owner: content operations/backend
- Status: **local playlist contract implemented; curated-source and live
  provider proof pending**
- Acceptance:
  - playlist owner and source remain visible;
  - unavailable items fail individually without breaking the page;
  - playlist order and page token are preserved.

### `YT-DISC-004` — Channel upload push notifications

- Service: PubSubHubbub webhook
- Owner: backend/SRE
- Status: **disabled local WebSub foundation implemented; ADR/manifest/cloud
  targets and live lease proof pending**
- Work:
  - subscribe only to approved channels;
  - verify callback challenges;
  - refresh affected metadata after upload/title/description notices.
- Acceptance:
  - forged or duplicate callbacks are rejected/idempotent;
  - lease renewal and unsubscribe work;
  - a push failure falls back to bounded refresh, not continuous polling.

### `YT-SEARCH-001` — Explicit search broker

- Endpoint: `search.list`
- Owner: backend
- Status: **local broker contract implemented; live quota/provider proof
  pending**
- Work:
  - allow deliberate user search with `type=video`, regional/language and
    safety/embeddability filters;
  - cache normalized query pages;
  - hydrate search IDs with `videos.list`.
- Acceptance:
  - typing alone does not issue a request;
  - one submitted query consumes at most one search call before pagination;
  - search budget stop, empty, offline and retry states pass;
  - default discovery never depends on an unrestricted search loop.

### `YT-META-001` — Video metadata projection

- Endpoints: `videos.list`, `videos.batchGetStats`
- Owner: backend
- Status: **local projection/batch contract implemented; live returned-shape
  proof pending**
- Mapped public fields:
  - ID, title, description, thumbnails, channel ID/title, published time,
    duration, category/tags/localization where returned;
  - view/like/comment counts where returned;
  - live-stream timing, caption availability, embeddability, region and age
    restrictions, Made-for-Kids status and paid-product-placement declaration
    where returned.
- Acceptance:
  - missing optional fields do not produce fabricated copy;
  - YouTube and MoolSocial metrics remain separately labelled;
  - long metadata fits the contract without truncating away access to the full
    record.

### `YT-SHORTS-001` — Positive Shorts classifier

- Owner: backend/product policy
- Status: pending
- Work:
  - implement `confirmed`, `unconfirmed` and `not-short` states;
  - never classify by duration/aspect ratio alone;
  - retain source evidence for a confirmed classification.
- Acceptance:
  - unconfirmed items remain in Videos;
  - tests cover vertical non-Short, short-duration non-Short and confirmed
    creator upload;
  - no UI label claims certainty the API did not provide.

## Phase 5 — official playback

### `YT-PLAYER-001` — Isolated official player host

- Owner: Flutter/native
- Status: blocked until observed Dev contract and founder-final HTML
- Work:
  - OS WebView/WKWebView contains only YouTube's official player;
  - all MoolSocial UI remains native outside it;
  - supply required API client identity/referrer/origin.
- Acceptance:
  - minimum player viewport is at least 200x200;
  - controls, branding, links and ads remain unobscured;
  - no HTML MoolSocial presentation or business logic is in the WebView;
  - error `153`, integrity, autoplay-blocked and unavailable states pass.

### `YT-PLAYER-002` — Playback lifecycle

- Owner: Flutter/native
- Status: blocked
- Acceptance:
  - start is user initiated unless a compliant visible autoplay policy is
    explicitly approved;
  - only one player autoplays at a time;
  - pause/resume, seek, completion, fullscreen, rotation, audio focus,
    headphones, call interruption, app switch and process return pass;
  - background playback and offline playback are absent.

### `YT-PLAYER-003` — Playback restrictions and privacy

- Owner: Flutter/privacy
- Status: blocked
- Acceptance:
  - non-embeddable, age/region restriction, removed/private and network
    failures have customer-ready recovery;
  - Made-for-Kids tracking is disabled as required;
  - YouTube source identity and privacy disclosure are visible.

## Phase 6 — optional connected-viewer actions

### `YT-OAUTH-001` — Connect and select YouTube channel

- Owner: identity/backend
- Status: **backend contract implemented and tested; Cloud OAuth consent and
  OPPO proof pending**
- Acceptance:
  - account connection is separate from MoolSocial sign-in;
  - user sees the exact selected YouTube channel;
  - cancel, wrong account, no channel, multiple channel, revoked and offline
    paths pass.

### `YT-ACTION-001` — Read connected YouTube state

- Endpoints: `channels.list(mine=true)`, `subscriptions.list`,
  `videos.getRating`, authorized playlists
- Owner: backend
- Status: deferred until public playback proof
- Acceptance:
  - each state is shown only to its authorizing user;
  - no personalized Home or watch-history claim is made.

### `YT-ACTION-002` — Explicit YouTube mutations

- Endpoints: `videos.rate`, `commentThreads.insert`, `comments.insert`,
  `subscriptions.insert/delete`, approved playlist operations
- Owner: backend/UX
- Status: deferred
- Acceptance:
  - action is visibly identified as YouTube and distinct from MoolSocial;
  - exact acting channel and target video/channel are shown;
  - each write requires a deliberate tap and success/failure reconciliation;
  - no paid/incentivized YouTube engagement exists.

## Phase 7 — creator upload and channel management

### `YT-UPLOAD-001` — Private resumable upload spike

- Endpoint: `videos.insert`
- Owner: backend/mobile
- Status: **private-only backend orchestration and non-UI direct-upload client
  implemented and tested; physical-device/provider proof pending**
- Acceptance:
  - selected media uploads directly from device to YouTube;
  - MoolSocial does not permanently store or proxy media bytes;
  - resulting item is private under the unaudited Dev project;
  - returned video ID and job state are reconciled.

### `YT-UPLOAD-002` — Required user-controlled fields

- Owner: product/Flutter
- Status: blocked pending observed spike and new founder-final HTML
- Required:
  - selected YouTube channel;
  - title up to YouTube's supported limit;
  - description up to YouTube's supported limit;
  - private visibility during unaudited Dev; no public/unlisted choice;
  - audience/Made-for-Kids declaration;
  - altered/synthetic-media declaration where applicable;
  - rights/licence attestation and Community Guidelines/copyright
    acknowledgement.
- Optional only when actually supported:
  - category, tags, language, recording date/location, license, embeddability,
    scheduling and paid-product-placement disclosure.
- Acceptance:
  - MoolSocial never silently truncates or appends user text;
  - user reviews destination and visibility immediately before upload;
  - unaudited Dev clearly says the provider will keep the upload private;
  - a broader visibility choice appears only after written provider approval.

### `YT-UPLOAD-003` — Resume, cancel and idempotency

- Owner: backend/mobile
- Status: **provider-session reconciliation, complete request fingerprinting,
  stale-session termination and client range-resume implemented locally;
  device interruption and live provider proof pending**
- Acceptance:
  - interrupted upload resumes from server-confirmed range;
  - cancelled or expired session is terminal and recoverable;
  - retry does not create duplicate videos;
  - progress survives app switch and ordinary network loss without exposing a
    token.

### `YT-UPLOAD-004` — Creator metadata tools

- Endpoints: `videos.update/delete`, `thumbnails.set`, captions and playlist
  methods
- Owner: creator studio
- Status: deferred
- Acceptance:
  - every mutation is user initiated and reconciled;
  - caption, thumbnail and playlist quota costs are budgeted;
  - the user can remove a MoolSocial-uploaded video link without MoolSocial
    pretending to delete provider content unless YouTube confirms it.

### `YT-UPLOAD-005` — Creator-initiated brand-partner access

- Endpoint parts: `videos.insert`, `videos.update`, `videos.list` with
  `brandPartner`
- Owner: creator commerce/legal
- Status: candidate after private upload proof
- Work:
  - allow the creator to select an eligible brand YouTube channel by channel
    ID or handle;
  - verify provider eligibility and preserve the resolved channel ID;
  - allow removal or replacement only through an explicit creator action.
- Acceptance:
  - selected creator, video, brand channel and paid-promotion disclosure are
    visible before publication;
  - provider brand-partner access is not represented as a MoolSocial sale,
    rights agreement or commission;
  - ineligible creator/deal combinations receive a truthful provider state;
  - MoolSocial campaign attribution remains separately auditable.

### `YT-AUDIT-001` — YouTube compliance and public-upload audit

- Owner: founder/legal/platform
- Status: pending after private proof
- Work:
  - prepare architecture, scopes, data flow, screenshots, privacy, deletion,
    quota forecast and test evidence;
  - submit the official audit/quota request.
- Acceptance:
  - public upload remains feature-disabled until approval;
  - approved quota values are recorded per environment;
  - no duplicate projects or workaround behavior is used.

## Phase 8 — creator analytics

### `YT-ANALYTICS-001` — Owner-authorized Analytics query

- Endpoint: YouTube Analytics `reports.query`
- Owner: analytics/backend
- Status: **backend contract implemented and tested; live owner consent and
  result proof pending**
- Work:
  - request only creator/channel-owner-authorized metrics;
  - keep YouTube metrics separate from MoolSocial commerce and earnings.
- Acceptance:
  - date, dimensions, filters and metrics are preserved with source labels;
  - only the authorizing creator or approved agent can see the report;
  - no inferred YouTube revenue, CPM, audience or brand-safety score exists.

### `YT-ANALYTICS-002` — Campaign attribution boundary

- Owner: commerce/analytics
- Status: pending
- Acceptance:
  - YouTube video ID and approved MoolSocial campaign link join only through
    MoolSocial's attribution records;
  - creator commission derives only from eligible delivered MoolSocial orders;
  - YouTube views/likes/comments are never payout events;
  - combined dashboards label YouTube and MoolSocial data separately.

### `YT-REPORT-001` — Bulk Reporting API

- Owner: analytics
- Status: deferred
- Start only when:
  - query API volume is proven insufficient;
  - the connected creator is eligible for the required report types; and
  - storage/deletion cost has an approved owner.

## Phase 9 — independent commerce and monetization safety

### `YT-COMMERCE-001` — Independent-value test

- Owner: product/legal
- Status: pending
- Work:
  - document the MoolSocial product/service value on every screen containing
    commercial placement and YouTube data;
  - prove that value remains useful if the YouTube data is removed.
- Acceptance:
  - no placement is on or inside the player;
  - no YouTube control/ad/link is obscured;
  - unrelated public YouTube content has no fabricated product linkage;
  - sponsor and affiliate disclosures are truthful.

### `YT-COMMERCE-002` — Campaign-linked creator upload

- Owner: creator commerce
- Status: pending after upload proof
- Acceptance:
  - creator selects an eligible MoolSocial campaign before publishing;
  - the description/link insertion is previewed and explicitly accepted;
  - click/order/return/commission records are independently auditable;
  - removing provider content terminates future attribution without rewriting
    historical orders.

### `YT-COST-001` — Per-capability cost and pricing gate

- Owner: product/finance/SRE
- Status: pending before any public Dev audience
- Work:
  - classify every capability using
    `YOUTUBE-MOOLSOCIAL-PRODUCT-AND-COST-MAP-20260723.md`;
  - forecast monthly API calls, backend invocations, token custody, database,
    storage, monitoring, moderation and support;
  - identify the free allowance, billable threshold and named payer;
  - set application-side caps and independent kill switches.
- Acceptance:
  - public YouTube watching is not paywalled;
  - no plan sells YouTube access or ordinary free YouTube functionality;
  - independently valuable MoolSocial paid features have an approved price;
  - external spend/media-heavy features cannot run without a hard cap;
  - a cost-threshold test stops the feature without disabling native
    MoolSocial Reels or Feed.

### `YT-LIVE-001` — Eligible creator live proof

- Owner: creator/platform/moderation
- Status: deferred
- Start only after upload and OAuth proof.
- Acceptance:
  - eligible channel, broadcast, stream and lifecycle ownership are verified;
  - live chat uses the supported low-latency `streamList` contract where
    appropriate;
  - moderation, abuse, member/funding event and operating-cost owners exist;
  - no MoolSocial UI promises unavailable YouTube live functionality.

### `YT-ADS-001` — Brand-funded Google Ads Demand Gen feasibility

- Owner: business advertising/legal/finance
- Status: **deferred handoff to the Workspace backlog; excluded from the
  active YouTube provider proof; Google Ads API not enabled**
- Successor:
  `GOOGLE-COMMERCE-AND-DEMAND-GEN-WORKSPACE-BACKLOG-20260723.md`
- Acceptance before enablement:
  - advertiser account, developer-token and policy eligibility are proven;
  - advertiser pays media spend under an explicit budget;
  - MoolSocial service fee and refund/failure rules are approved;
  - YouTube in-stream, in-feed and Shorts placement controls are truthful;
  - no ad is placed on or over MoolSocial's embedded YouTube player.

### `YT-SHOP-001` — Merchant/YouTube Shopping feasibility

- Owner: merchant commerce/legal
- Status: **deferred handoff to the Workspace backlog; excluded from the
  active YouTube provider proof; Merchant API not enabled**
- Successor:
  `GOOGLE-COMMERCE-AND-DEMAND-GEN-WORKSPACE-BACKLOG-20260723.md`
- Acceptance before enablement:
  - merchant and affiliate-program eligibility are proven;
  - supported affiliate reports are distinguished from ordinary Data API
    metadata;
  - no UI promises programmatic product tagging for arbitrary public videos;
  - data retention, reconciliation and cost owners are approved.

### `YT-PARTNER-001` — Partner-only capability boundary

- Owner: legal/platform
- Status: excluded from MVP
- Work:
  - keep Content ID and other partner-only APIs unavailable;
  - revisit only after Google/YouTube grants the required partner status.

## Phase 10 — quality, operations and rollback

### `YT-QA-001` — Contract test harness

- Owner: QA
- Status: **50/50 backend tests, 23/23 Flutter provider tests and fresh Data
  Connect generation pass; live-provider fixtures remain pending**
- Acceptance:
  - fixtures cover every supported endpoint and missing optional field;
  - live Dev tests are separated from deterministic local tests;
  - no real token, key or personal data is recorded in fixtures.

### `YT-QA-002` — Physical OPPO provider matrix

- Owner: QA/mobile
- Status: blocked until Dev build
- Acceptance:
  - discovery, player, OAuth, private upload, analytics and revocation replay;
  - Wi-Fi/mobile/offline, call, app switch, force-stop, process death, rotation,
    text scale, safe area, keyboard and accessibility tests;
  - screenshots redact account and credential data.

### `YT-QA-003` — Compile-time-gated private Dev proof client

- Owner: mobile/platform
- Status: **implemented and verified locally; live App Check and endpoint proof
  pending**
- Acceptance:
  - activates only with the explicit private-Dev build define;
  - rejects every Firebase project except `moolsocial-dev-503018`;
  - rejects every provider URL except the exact Dev Function;
  - uses standard or limited-use App Check tokens according to operation risk;
  - sends media only to the approved Google resumable-upload host;
  - never changes Screen 01–04 UI, routes or approved references.

### `YT-OBS-001` — Observability

- Owner: SRE
- Status: **independent server flags implemented locally; live deployment and
  rollback evidence pending**
- Acceptance:
  - per-method count, latency, quota bucket, cache hit, provider status and
    job state are observable;
  - tokens, API keys, raw authorization headers and private content are
    redacted;
  - alert and incident owner are named.

### `YT-ROLLBACK-001` — Layered kill switches

- Owner: platform/SRE
- Status: pending
- Required flags:
  - public discovery;
  - explicit search;
  - embedded playback;
  - YouTube account connection;
  - creator upload;
  - connected actions;
  - analytics/reporting; and
  - MoolSocial commerce adjacent to YouTube data.
- Acceptance:
  - each feature can stop independently without an app release;
  - disabling YouTube preserves native MoolSocial Reels and Feed;
  - revoke/delete workflows remain available after a feature stop.

### `YT-UI-001` — Provider-observed Screen 04 HTML revision

- Owner: HTML conformance
- Status: blocked until phases 4–8 produce evidence
- Work:
  - revise Shorts/Videos only to the supported and observed provider contract;
  - use real returned field shapes and truthful error states;
  - present exact HTML for founder review.
- Acceptance:
  - no unsupported YouTube Home/Shorts/feed claim;
  - no commentary/example/internal wording in production UI;
  - founder marks one exact checksum `FINAL` before freezing.

### `YT-FLUTTER-001` — Native parity

- Owner: Flutter V2
- Status: blocked until `YT-UI-001` is founder-final and frozen
- Acceptance:
  - exact native parity at identical viewport/state/text scale;
  - only official provider player uses WebView/WKWebView;
  - OPPO acceptance and regressions pass before any Staging candidate.

## Founder actions — separate from engineering

The founder must personally complete or approve:

1. Google account and Firebase CLI reauthentication; never send credentials to
   Codex.
2. The Dev OAuth consent app name, support email, authorized domain, privacy
   policy URL, terms URL and deletion/revocation URL.
3. A dedicated Dev YouTube test channel and permission for private test
   uploads.
4. Final acceptance of each proven incremental viewer-authorized
   like/comment/subscribe/playlist action before it becomes visible. The
   comprehensive inventory is approved, but scopes and UI remain
   capability-by-capability gates.
5. Acceptance that MoolSocial cannot receive the personalized YouTube Home or
   native Shorts recommendation feed.
6. Acceptance that YouTube branding, controls and YouTube-served ads remain
   visible.
7. The audience/Made-for-Kids policy and responsible legal/privacy owner.
8. The entity/contact that will submit YouTube's API compliance and quota
   request.
9. A small non-media operational budget owner for backend, security,
   monitoring, moderation and support even though YouTube hosts/streams its
   audiovisual content.
10. Approval of the permanent pricing rule: public watching is free; paid
    plans cover only MoolSocial-owned campaign, commerce, workflow, analytics,
    payout, team or managed-media value.

## Go/no-go rule

API enablement and private Dev proof do not approve the Screen 04 UI, Staging
or Production. The next UI gate is a new provider-observed HTML candidate,
founder `FINAL`, immutable freeze, native parity and physical-device
acceptance.
