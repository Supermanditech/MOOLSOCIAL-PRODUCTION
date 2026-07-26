# MoolSocial YouTube API compliance, quota and value proposal

Status: **official form structure captured 24 July 2026 and reconciled with the
25 July live public-data/player/Shorts proof; not ready to submit because
owner OAuth, private upload, owner Analytics, revocation/deletion, measured
Preview quota demand, the Production-project boundary, reviewer access and
founder/legal fields remain pending**

Target API client:

- product: MoolSocial
- environment: private Dev/Trial
- Google Cloud project: `moolsocial-dev-503018`
- project number: `760290687711`
- branch authority:
  `remediation/prototype-conformance-2026-07-20`

This document is the durable source for the eventual YouTube API Services
compliance audit and quota extension submission. It is not an email claiming
approval, a partnership, production readiness or existing scale.

### Founder-authorized first audit slice — 25 July 2026

The founder authorized the smallest truthful audit-readiness slice and
withheld comprehensive YouTube development until the exact Production project
receives written Google OAuth verification, YouTube API audit and initial
quota decisions.

The controlled owner-proof publisher is:

- channel: `VetoNews`
- handle: `@VetoNewslive`
- canonical channel ID: `UC7rn0BIzhULpyw1NYXh-mWQ`
- founder-supplied owner/test-user Google account:
  `vetonewslive@gmail.com`

MoolSocial is the API client under review. VetoNews is a founder-controlled
publisher used to prove explicit creator authorization; it is not a
MoolSocial master channel and grants no authority over another creator's
channel.

The authorized proof boundary is public discovery/player, contextual
`youtube.readonly` owner connection, exact channel reconciliation, one
user-confirmed private upload using incremental `youtube.upload`, minimum
owner-authorized Analytics, disconnect/revocation/deletion and bounded quota
measurement. Owner actions, creator-asset management, Live, monetary
Analytics, Content Owner/Partner operations, derived metrics and
public/unlisted uploads remain excluded.

Durable authorization:
`artifacts/quality/youtube-api-submission-readiness-20260725-01/FOUNDER-AUDIT-SLICE-AUTHORIZATION.md`.

### Environment and project-specific approval boundary

This package currently describes the private Dev API project numbered
`760290687711`. YouTube's upload restriction and compliance audit apply to each
API project. An audit, OAuth verification or quota decision for this Dev project
must not be represented as approval for a different Staging or Production
project.

MoolSocial's founder-locked environment policy creates Production later as a
separate project. Before full customer go-live, the exact Production project,
OAuth client boundary and reviewer build must therefore receive their
applicable verification/audit/quota decisions, or YouTube/Google must provide
written instructions that explicitly authorize another treatment. MoolSocial
will not assume that a Dev-project decision transfers.

## Current private Dev evidence

The local provider foundation was verified on 23 July 2026:

- TypeScript typecheck passed.
- All 50 deterministic provider tests passed.
- The compile-time-gated non-UI Flutter private-Dev provider client passed
  targeted analysis and 23/23 platform/provider tests.
- The current Data Connect schema and both connectors compiled in an isolated
  generation workspace without changing generated production Flutter files.
- The local Functions, Authentication and Data Connect emulators started
  together.
- The `capabilities` operation reported every YouTube capability disabled.
- A `publicMostPopular` request was rejected with HTTP 503
  `capability_disabled` before provider construction, secret access or quota
  reservation.
- No YouTube server API key, OAuth client, refresh token, private upload,
  Analytics result or live YouTube API response is claimed.
- The provider foundation includes a fixed backend OAuth callback, one-time
  state consumption, encrypted refresh-token and upload-session custody,
  direct-to-YouTube private resumable upload orchestration, owner/channel
  reconciliation, disconnect deletion, internal quotas and redaction.

Evidence:

`artifacts/quality/youtube-provider-private-dev-20260723-02/LOCAL-PROVIDER-FOUNDATION-EVIDENCE-02.md`

Google/Firebase reauthentication and the Dev inventory are complete. The
project is ACTIVE, the fixed Android app is registered, and the App Check API
is enabled. Billing is not attached, Play Integrity still requires founder
legal acceptance, and no restricted YouTube credential or Dev backend has been
deployed. These remaining facts must not be described as passed in the audit
submission.

Cloud inventory evidence:

`artifacts/quality/youtube-private-dev-cloud-bootstrap-20260723-01/CLOUD-BOOTSTRAP-EVIDENCE.md`

### Current live public-data and playback evidence — 25 July 2026

The historical foundation record above remains valid for its date. The current
private-Dev state has advanced:

- the restricted YouTube server credential, keyless runtime identity,
  encrypted-secret custody, deny-all Firestore client boundary and Play
  Integrity-backed App Check gate are live in `moolsocial-dev-503018`;
- real eligible public YouTube video discovery and the official embedded
  player passed on the founder-authorized physical OPPO;
- the persistent, fail-closed `PublicDataReview` profile is live while
  `OwnerConnect`, `OwnerActions`, `CreatorAssets`, `Live`, `PrivateUpload` and
  `OwnerAnalytics` remain disabled;
- real public Videos and eight positively admitted YouTube Shorts were
  observed in the installed candidate;
- the latest twenty sampled app/provider requests were HTTP `200`, and the
  deliberate unauthenticated App Check probe was rejected with HTTP `401`;
- focused public-runtime, Screen 04 and official-player tests passed `63/63`;
  the persistent backend suite passed `269/269`; and
- Staging and Production remain unchanged.

Evidence:

`artifacts/quality/youtube-private-dev-oppo-public-viewing-20260725-01/LIVE-PUBLIC-VIDEOS-SHORTS-PROOF.md`

This proves only the public-data/player slice in private Dev. It is not owner
OAuth proof, a private upload, an Analytics/Reporting result, a live WebSub
subscription, a quota measurement period, an audit submission, a provider
approval or a Production release.

### Dev OAuth owner-proof preparation — 25 July 2026

The Google Auth Platform app remains External/Testing and unsubmitted.
`vetonewslive@gmail.com` is now an allowed Dev test user and
`youtube.readonly` is the only configured sensitive scope. Public product,
Privacy, Terms and support/deletion URLs remain absent.

Two existing Web OAuth clients use the exact callback. No client or secret was
changed; the exact client already stored in Secret Manager must be identified
in place before live proof. The OPPO and accepted APK are present, and the
static owner proof plus `48/48` targeted Flutter tests pass. No live owner
connection or token was created.

Evidence:
`artifacts/quality/youtube-api-submission-readiness-20260725-01/LIVE-OAUTH-TEST-CONFIGURATION.md`.

## Executive proposal

MoolSocial is a native mobile creator-and-commerce workflow product. It does
not replace or reproduce YouTube.

MoolSocial users may discover selected eligible public YouTube videos and play
them using the official embedded YouTube player. A channel owner may separately
connect a Google account, select the exact YouTube channel, upload original
content to that channel, control required metadata and visibility, monitor the
upload result and view the channel owner's authorized analytics.

MoolSocial's significant independent value is:

- creator–brand campaign workflow;
- product or service destinations controlled by MoolSocial;
- trackable MoolSocial visits and orders;
- delivered-order creator commission and payout administration;
- team approval and publication workflow; and
- operational reporting that keeps YouTube and MoolSocial records separate.

Every YouTube write is visibly identified, user initiated and confirmed before
execution.

## Intended users and market

MoolSocial is designed for a broad Indian commerce and creator market:

- consumers who want relevant public media and useful local or national
  products, services and opportunities;
- individual creators and YouTube channel owners;
- manufacturers, brands, retailers, wholesalers and local merchants;
- professionals and service providers;
- advertisers commissioning creator campaigns; and
- authorized creator/business team members after role controls are proven.

These are intended user types. Before measured private Dev/Preview evidence,
MoolSocial will not claim a user count, daily active users, retention, reach,
sales, creator income or guaranteed market impact.

### India market context — not MoolSocial traction

Official YouTube/Google reporting establishes the breadth of the ecosystem in
which an opt-in MoolSocial pilot would operate:

- YouTube reported in May 2025 that more than 100 million India-based channels
  uploaded content during the previous year, more than 15,000 of those
  channels had over one million subscribers, and viewers outside India watched
  45 billion hours of Indian-produced content during that year:
  <https://blog.google/intl/en-in/products/platforms/youtubes-india-bet-inr-21000-crore-paid-out-to-indian-creators-commits-inr-850-crores-to-power-indias-creator-nation/>.
- YouTube reported in September 2025 that Shorts had more than 650 million
  monthly logged-in viewers in India:
  <https://blog.google/intl/en-in/products/platforms/from-passion-to-profit-the-rise-of-the-contentrepreneur-on-youtube/>.
- YouTube reported in October 2025 that more than 200 million logged-in users
  in India made shopping-related YouTube searches in July 2025:
  <https://blog.google/intl/en-in/products/platforms/fueling-the-next-era-of-creator-led-shopping-experiences-in-india/>.
- the Government of India reported more than 7.83 crore cumulative
  registrations on the Udyam Registration Portal and Udyam Assist Platform
  from 1 July 2020 through 28 February 2026:
  <https://www.pib.gov.in/PressReleasePage.aspx?PRID=2246892&lang=2&reg=3>.

These independent figures describe YouTube channels, logged-in viewers,
shopping interest and cumulative enterprise registrations. They are not
MoolSocial users, MoolSocial reach, an addressable-customer count or evidence
of conversion. MoolSocial will not state that it reaches those audiences.

## Value to YouTube

The integration can provide YouTube with:

- compliant official playback of eligible public YouTube content;
- additional discovery through a differentiated creator-commerce workflow;
- creator-controlled publication of original content to the creator's own
  selected YouTube channel;
- continued YouTube ownership of video hosting, playback, controls,
  attribution and provider advertising;
- authorized creator analytics that help creators improve future content;
- clear paid-promotion and audience declarations; and
- a commerce workflow that does not convert YouTube engagement into artificial
  incentives or payouts.

MoolSocial will not claim that YouTube guarantees distribution, views, income,
sales or partnership status.

Private Preview will measure the possible benefit rather than assume it:

- eligible official-player sessions;
- owner-consented channel connections;
- user-confirmed private uploads reconciled to the selected channel;
- creator-authorized Analytics opens;
- genuine visits to MoolSocial-owned destinations, kept separate from
  YouTube engagement; and
- disconnect/deletion completion.

Results will be segmented by consenting viewer, creator, merchant/service
provider and authorized Workspace member where sample size permits. No metric
will be described as incremental YouTube reach until a controlled, measured
comparison supports that statement.

## Why the APIs are required

### Public content and discovery

- `videos.list`
- `channels.list`
- `playlists.list`
- `playlistItems.list`
- `videoCategories.list`
- `search.list` only after an explicit submitted search

Default discovery uses regional charts, approved-channel upload playlists and
curated playlists. It does not reproduce personalized YouTube Home or the
native Shorts recommendation feed.

### Fresh public discovery and MoolSocial ranking

MoolSocial may automatically make recent eligible public uploads discoverable
without claiming access to YouTube's private recommendation system:

1. approved channels use their uploads playlists and, after live verification,
   YouTube push notifications/WebSub for near-real-time upload or metadata
   change signals;
2. controlled topic refreshes may use `search.list(type=video, order=date,
   publishedAfter=...)` with the applicable query, India region, language,
   embeddability and availability constraints;
3. regional/category popular lists and curated public playlists provide
   lower-quota background supply;
4. returned video IDs are hydrated and revalidated for current public,
   processed, embeddable and region-available status before display; and
5. MoolSocial may rank the eligible set using disclosed MoolSocial factors such
   as recency, selected topic, language, service area, approved source,
   freshness and current public provider statistics.

This is **MoolSocial-selected discovery**, not “recommended by YouTube”.
YouTube search indexing, notification delivery, quota, channel metadata and
eligibility checks can delay or omit an upload. MoolSocial therefore must not
promise that every public video, every Short or a video uploaded exactly one
minute earlier will appear.

The Data API still exposes no authoritative public `isShort` field. A recent
result enters the Shorts lane only after the separately recorded positive
classification and eligibility rules pass. Duration or vertical shape alone
is not sufficient.

### Playback

The official YouTube IFrame Player runs alone inside an OS-provided Android
`WebView` or Apple `WKWebView`. MoolSocial presentation, navigation, commerce
and business logic remain native and outside the player.

### Creator connection and upload

- `channels.list(mine=true)` with the narrow read scope when connecting a
  channel;
- resumable `videos.insert` with `youtube.upload` only after the creator starts
  YouTube publication; and
- `videos.list` to reconcile processing, privacy and publication state.

Updates, thumbnails, playlist writes, comments, ratings, subscriptions, live
operations, partner scopes and monetary analytics remain excluded until the
exact feature is separately implemented, justified and evidenced.

### Creator analytics

YouTube Analytics `reports.query` is used only for the authorizing channel
owner. YouTube metrics retain source and refresh-time labels and remain
separate from MoolSocial orders, commission and payouts.

## Scope minimisation

- Public metadata and playback: no user OAuth.
- Channel connection: `youtube.readonly` only in the connection flow.
- Upload: `youtube.upload` only in the publish-to-YouTube flow.
- Analytics: `yt-analytics.readonly` plus the required YouTube read scope only
  when the user opens analytics.
- No sign-in screen requests YouTube channel scopes.
- Google authorization uses the system browser and Authorization Code with
  PKCE, never the player WebView.
- The implemented client is one confidential web-server OAuth client with a
  fixed HTTPS Firebase Functions callback.
- The client secret remains in Secret Manager, refresh tokens are encrypted
  by the privileged backend and Flutter receives neither.
- Google OAuth app verification and the YouTube API compliance/quota audit are
  separate approval processes.

## Upload control and required functionality

During unaudited private Dev, immediately before each upload MoolSocial shows:

- exact destination YouTube channel;
- title and description;
- category where supported;
- private visibility, with no public or unlisted choice;
- Made-for-Kids audience declaration;
- paid-promotion and altered/synthetic-media declarations when applicable;
- subscriber-notification choice when exposed;
- a rights/licence attestation;
- YouTube Community Guidelines and copyright acknowledgement;
- destination disclosure if the creator separately selects another external
  network for the original media;
- required YouTube upload certification/terms notice; and
- one explicit final confirmation.

MoolSocial never silently appends a link, caption, tag or disclosure and never
silently changes visibility.

The current unaudited post-28-July-2020 project keeps API uploads private.
MoolSocial will not describe public/unlisted API distribution as available
until YouTube removes that restriction in writing.

Only after written YouTube approval may a new founder-reviewed contract offer
provider-supported visibility choices. MoolSocial has no unattended,
background or bulk upload path. Per-user and project caps, idempotency,
anti-spam controls, abuse reporting, moderation and incident ownership are
required before any broader rollout.

## Monetisation

Public YouTube viewing in MoolSocial is free. MoolSocial does not:

- charge for YouTube access or ordinary free YouTube functionality;
- reward or pay for YouTube views, likes, comments, shares or subscriptions;
- cover or alter the player, YouTube controls, links, branding or ads;
- place MoolSocial ads, product cards or interaction overlays on the player;
  or
- present MoolSocial sales or creator commission as YouTube revenue.

The intended fee payers and model are:

- creators and businesses may pay a MoolSocial Workspace subscription for
  team roles, approval workflow, owned publishing tools and independent
  reporting;
- advertisers may pay an explicit MoolSocial campaign-workflow service fee,
  separate from any media budget;
- a participating merchant may pay the disclosed delivered-order commerce and
  creator-commission administration fee defined by the MoolSocial ledger; and
- a customer may separately select a capped managed-media service with a
  stated price and spend limit.

MoolSocial does not resell YouTube API access or YouTube data and does not
charge for free YouTube functionality. A paid MoolSocial feature must remain
independently useful if YouTube data is removed.

Creator commission is earned only from eligible delivered MoolSocial orders
under the MoolSocial ledger, never from YouTube engagement.

## Data, privacy and security

Before submission and public access, evidence must prove:

- public Terms linking the YouTube Terms of Service;
- a privacy policy naming YouTube API Services and Google privacy/revocation
  controls;
- clear collection, use, sharing, retention and deletion disclosure;
- TLS, least privilege, encrypted refresh-token custody and audited backend
  access;
- no secret, token or private media in the client, repository or logs;
- in-product disconnect, provider revocation and retained-data deletion;
- prompt deletion, including the applicable seven-day revocation/account-
  deletion boundary;
- refresh or deletion of retained non-authorized metadata within the applicable
  30-day policy boundary;
- clear distinction between deleting MoolSocial's retained record and deleting
  content on YouTube;
- no audiovisual download, cache, offline playback or scraping; and
- Made-for-Kids and player-identity requirements.

## Quota request

Current default project buckets recorded for July 2026 are:

- 10,000 Data API units/day/project;
- 100 `search.list` calls/day/project; and
- 100 `videos.insert` calls/day/project.

Under the current granular quota model, a `search.list` call consumes one unit
from the separate Search Queries bucket and a `videos.insert` call consumes one
unit from the separate Video Uploads bucket. Exact project rate limits shown in
Google Cloud Console must be captured independently; they must not be inferred
from these daily allocations.

MoolSocial will not invent a larger request. After 14–30 days of private
Dev/Preview measurement, and only when the sample is large enough to make
percentiles meaningful, the request will use:

- search/day = `ceil(P95 successful explicit-search pages/day * 1.30)`;
- search peak/minute = `ceil(P99 search calls/minute * 1.30)`;
- uploads/day = `ceil(P95 user-confirmed upload starts/day * 1.30)`;
- upload peak/minute = `ceil(P99 upload starts/minute * 1.30)`;
- other units/day =
  `ceil(sum(actual method calls * current method cost) * 1.30)`; and
- other peak/minute = `ceil(observed P99 units/minute * 1.30)`.

The measurement window must include at least 14 complete UTC days. For a
low-volume bucket, the proposal will use the maximum observed demand plus a
transparent launch forecast instead of presenting an unstable P95 or P99.
The forecast will state projected participants by user type, capability
opt-in, calls per participant, cache assumptions, upload-confirmation rate,
peak concentration and 30% operational headroom.

Evidence will show no search-per-keystroke, bounded pagination, batched video
IDs, policy-compliant caching, upload-playlist/WebSub refresh, backoff,
per-user/global limits, upload queues and independent kill switches. MoolSocial
will never create extra projects to evade quota.

## Evidence package before submission

- legal entity, contact, product URL and exact package/bundle identities;
- public privacy, Terms, support, revocation and deletion URLs;
- endpoint, scope and data-flow inventory;
- OAuth contextual-consent, disconnect and deletion captures;
- official player captures with attribution, no overlays and failure recovery;
- private upload confirmation, progress, resume, processing and result;
- owner-authorized Analytics result;
- architecture and token-vault diagram;
- quota dashboard, request logs, cache rate and P95/P99 calculations;
- tests for tenant authorization, revocation, deletion, quota exhaustion,
  retry/idempotency and hidden-write prevention;
- readable screenshots or PDF; and
- a dedicated review account entered only in Google's official form.

### Official form field map

The current dynamic **YouTube API Services Audit and Quota Extension Form**
was rechecked on 24 July 2026. Prepare one internally reviewed answer pack per
separately reviewable API Client. Do not combine another web, admin or provider
client with the MoolSocial client unless Google confirms that treatment in
writing.

| Form section | MoolSocial submission posture | Evidence or owner still required |
| --- | --- | --- |
| 1. Request | Compliance audit and additional quota only after measured Preview usage | Founder/legal selects the final request type and the measured values |
| 2. Organization and contacts | Apply as the actual registered organization or individual; use the exact legal identity | Legal name, organization name, parent if applicable, HTTPS website, full postal address, country, business category, organization size/type, primary contact, technical contact and business contact |
| 3. Business model and Google relationships | Describe MoolSocial's independent creator-commerce value in 100–5,000 characters; disclose only current, implemented monetization | Target-audience categories, monetization selections, advertising disclosure, Google/YouTube/Ads representative or `None`, discovery source, Content Owner IDs if applicable and current Google Ads customer IDs only if this submitted client actually manages Ads |
| 4. API Client | Client name is `MoolSocial`; it does not contain `YouTube`; submit the exact reviewer-accessible Dev/Preview entry point | Primary HTTPS access URL, public Privacy URL, optional Terms URL, public-access answer, full-access demo login URL, sample data and reviewer instructions |
| 5. Project and use cases | One numeric project: `760290687711`; OAuth is `Yes`; select only implemented use cases | Exact API-client identifiers, package/bundle identities, use-case categories, endpoint list, evidence files, expected traffic and three measured quota requests |
| 6. Evidence quality | Screenshots are readable, factual and tied to the submitted client | Minimum 1280x720 captures; web captures include the address bar; descriptive filenames; JPEG/PNG or PDF attachments |
| 7. Attestations | Founder/legal reads and confirms every current attestation | YouTube Terms/API policies, Google Privacy Policy, change-notification duty, suspension/termination, demo waiver, truth/accuracy, processing consent, recording notice and post-submit email verification |

The reviewer account must provide the complete submitted feature set and sample
data. Its username, password, recovery material and any special access secret
are entered only into Google's official form. They must not be written in this
repository, chat, tickets, screenshots or evidence.

### Current use-case selection rule

For the client described by this document, the likely current form categories
are:

- Video Uploading & Account Management;
- Tools for Creators;
- Brand Deals & Influencer Search, only when the submitted build exposes that
  implemented workflow;
- Websites & Mobile Apps; and
- Analytics & Reporting.

Do not select `Tools for Advertisers` merely because MoolSocial has brands,
campaigns or commerce attribution. Select it only if the submitted YouTube API
client actually implements the form's advertising-tool use case.

Merchant API and Google Ads Demand Gen are future Workspace integrations under
ADR-0007. Their future scopes, developer token, Merchant account IDs, Google
Ads customer IDs and claims do not belong in this YouTube audit unless they are
actually part of the submitted API Client at submission time. For the current
private YouTube proof, they are not.

### Monetization and advertising answer rule

The form's monetization and advertising answers must describe the exact build
Google reviews:

- public YouTube playback is not sold or paywalled;
- MoolSocial may charge for its independent workflow, attribution,
  administration or subscription value;
- nothing may cover, alter or be inserted inside the YouTube player; and
- any MoolSocial-paid placement displayed on a page alongside YouTube content
  must be disclosed honestly. Founder/legal must not answer `No` merely because
  the placement sits outside the player.

The final advertising answer and explanation remain a founder/legal field until
the reviewer build is frozen.

### YouTube data, statistical storage and derived metrics

The form now offers audited developers an optional agreement for certain
derived metrics and longer use of eligible public statistics. MoolSocial's
initial submission defaults to **not requesting this optional permission**
unless the implemented product needs it and founder/legal approves its exact
use.

Without that additional written permission:

- do not create a replacement YouTube score, ranking or blended provider
  metric;
- do not merge YouTube API data and MoolSocial commerce data into an
  undisclosed number;
- keep YouTube metrics source-labelled and visually distinct from MoolSocial
  orders, attribution, commission and payout records; and
- apply the normal refresh, retention and deletion requirements.

If later evidence proves a need for the optional permission, the submission
must name every derived metric, source field, formula, display, retention
period and deletion path before founder/legal opts in.

### Quota requests required by the current form

The form asks for three separate measured forecasts:

1. total general YouTube Data API units per day and peak operations per minute;
2. `search.list` calls per day and peak calls per minute; and
3. `videos.insert` uploads per day and peak uploads per minute.

Each bucket needs its own detailed justification. The request must be derived
from the 14–30 day Preview evidence, not from the maximum default or an
unverified growth target. Attach method counts, participants, calls per
participant, cache behavior, batching, pagination, retry rate, upload
completion rate, peak concentration and operational headroom. No duplicate
project may be used to bypass any bucket.

### Mandatory evidence manifest

The final attachment set must include, when applicable to the submitted client:

- Privacy Policy captures showing the YouTube-specific disclosure, Google
  Privacy Policy link, retention/deletion language and disconnect path;
- product home/entry capture showing a visible Privacy link and correct
  YouTube attribution;
- Terms documentation;
- OAuth consent, selected scopes, return, disconnect and revocation captures;
- private upload controls, user-entered title/description/privacy, progress,
  processing and result captures;
- official player and surrounding mobile/web UI captures;
- Analytics/dashboard captures that clearly label YouTube-source data;
- architecture, user-flow, token-custody and deletion diagrams;
- quota dashboard, endpoint measurements and forecast worksheet; and
- deterministic and physical-device test evidence.

Every image must be at least 1280x720, readable and unblurred. Web evidence
includes the browser address bar. Use descriptive filenames and submit only
JPEG, PNG or PDF files accepted by the form.

### Founder/legal fields still required

Before submission, the founder or named legal/platform owner must supply or
approve:

- exact applicant type, legal entity, parent company if any, business
  category, organization size/type and complete postal address;
- public HTTPS product, Privacy, Terms, support, revocation and deletion URLs;
- primary, technical and business contact names and monitored email addresses;
- exact business description, target audiences, monetization selections and
  advertising answer for the frozen reviewer build;
- Google/YouTube/Ads representative details or `None`, how the API was
  discovered, Content Owner IDs if any and current Ads customer IDs if
  applicable;
- exact API Client boundary and whether any separately reviewable client
  requires its own form;
- OAuth client identifiers, Android package, iOS bundle, reviewer URL and
  navigation instructions;
- full-access demo account entered only in the official form;
- final implemented use-case categories, endpoints and optional-derived-metric
  decision;
- the measured general, `search.list` and `videos.insert` quota requests and
  justifications;
- the final evidence manifest and attachment identifiers; and
- every attestation plus authorization to submit.

### Submission receipt record

After submission, record only non-secret governance evidence:

- submission date/time and named submitting owner;
- project ID and number;
- request type and the three requested quota values;
- final evidence-package identifier and checksums;
- form confirmation/reference if Google supplies one;
- completion of the required email-verification step; and
- subsequent Google questions, decisions and conditions.

Do not claim submission, approval or extended quota until that evidence exists.

## Authoritative implementation plan

Execution, ownership, cost gates and proof order are defined in:

`YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md`

The fixed sequence is:

1. restricted credentials and App Check;
2. deploy with every capability disabled;
3. public metadata;
4. official player on the physical OPPO;
5. owner OAuth;
6. one direct private upload;
7. owner-authorized Analytics;
8. revoke/delete and quota-stop tests;
9. 14–30 day App Distribution Preview measurement;
10. evidence pack and founder/legal review; and
11. official form submission.

## Claim gates

### Permitted before private Dev proof

- intended product, users and business model;
- APIs enabled in the Dev project;
- documented API capabilities, restrictions and default quotas;
- planned architecture and compliance controls; and
- current lack of production access or quota approval.

### Permitted only after verified private Dev evidence

- public metadata returned successfully;
- official playback passed on the physical OPPO;
- a consenting owner connected the selected channel;
- one private upload and status reconciliation succeeded;
- an owner-authorized Analytics query succeeded;
- revocation and retained-data deletion passed; and
- measured latency, cache, error and quota results.

### Permitted only after written YouTube/Google approval

- public/unlisted API uploads from the audited project;
- approved increased quota values;
- verified production OAuth access; and
- any partnership or provider-specific programme status.

## Official submission route and timing

YouTube publishes no ordinary email address for this audit. Submit through the
official **YouTube API Services Audit and Quota Extension Form**:

<https://support.google.com/youtube/contact/yt_api_form?hl=en>

Guidance:

<https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>

Submit only after the private Dev provider proof and evidence pack are
complete. The founder or named legal/platform owner enters all contact and
review-account credentials directly into Google's form. Nothing secret is
stored in this document or sent to Codex.

## Gated cover-message template

Do not submit or copy this template as a statement of fact until every
bracketed item has been replaced with verified evidence and the founder/legal
owner has approved the complete form.

> MoolSocial requests a compliance audit of the private Dev API client
> identified in this submission and, after review of `[attached measured
> usage period and figures]`, an appropriate quota extension of `[requested
> bucket and amount]`. MoolSocial is a native
> creator-and-commerce workflow product, not a substitute for YouTube. It uses
> YouTube APIs for selected public metadata, the official embedded player,
> creator-controlled publication to the creator's own selected channel and
> owner-authorized analytics. MoolSocial's independent value is campaign
> workflow, product/service destinations, delivered-order attribution,
> creator commission administration and operational reporting. Public YouTube
> viewing is free, YouTube actions are user initiated and labelled, and
> YouTube data and MoolSocial commerce records remain separate. The attached
> evidence package `[evidence identifier]` records the tested scope
> minimisation, explicit upload controls, encrypted credential custody,
> revocation/deletion, quota protection and official-player behavior. Every
> numerical claim in this submission is limited to the cited Preview evidence
> or clearly labelled external market context.

## 25 July 2026 submission-readiness checkpoint

This checkpoint updates the factual preparation state for the future official
form. It is not proof of live use, an audit submission, a quota request,
provider approval or customer availability.

### Method and service inventory

The official `99`-method inventory is completely reconciled:

- `87` methods are implemented locally through disabled privileged-backend,
  typed native-Flutter and focused deterministic-test contracts;
- `8` methods remain provider/representative/content-owner/channel/programme
  eligibility gated;
- `3` methods are unsupported, deprecated or have no approved MoolSocial
  customer value; and
- `liveChatMessages.streamList` remains disabled because its generated-stub
  and long-lived streaming transport boundary is not safely complete.
  Bounded read-only live chat uses `liveChatMessages.list` as the approved
  fallback.

These counts describe code coverage and deliberate exclusions. They must not
be presented to YouTube as evidence that all methods were exercised live or
that every method will appear to customers.

The exact private-Dev project has:

- `youtube.googleapis.com` enabled;
- `youtubeanalytics.googleapis.com` enabled;
- `youtubereporting.googleapis.com` enabled; and
- an external Google Auth Platform brand plus a dedicated confidential
  backend OAuth client created.

No OAuth identifier, secret, access/refresh token, test-user credential or
review-account credential is stored in this document or repository. Secure
secret custody, contextual consent and live provider reconciliation remain
pending evidence.

### Seven-profile proof discipline

The bounded private-Dev profiles are `PublicData`, `OwnerConnect`,
`OwnerActions`, `CreatorAssets`, `Live`, `PrivateUpload` and
`OwnerAnalytics`. Every profile:

- defaults to `false`;
- is activated only for one supervised proof;
- has a maximum activation window of 30 minutes; and
- is returned to `false` after the proof or on rollback.

Live public-data responses, official-player OPPO proof and continuing
private-Dev public Videos/Shorts availability are now established by the
25 July evidence cited above.

The following remain unestablished and may not be claimed in a submission:

- consenting owner connection and exact-channel reconciliation;
- owner actions or creator-asset mutations;
- a live approved-channel WebSub subscription and delivery;
- live-management operations;
- one private upload, resume, processing and final reconciliation;
- owner-authorized Analytics/Reporting results;
- disconnect, Google revocation and retained-data deletion replay;
- a complete reviewer-accessible build/account;
- the 14–30 complete-day Preview quota measurement and numerical request;
- founder/legal answers and attestations; and
- Staging or Production customer availability.

Merchant API and Google Ads Demand Gen are deferred to the separately governed
signed-in Workspaces module. They are excluded from this YouTube API client,
its OAuth evidence, its quota calculation and its audit-form use cases unless a
future frozen reviewer build actually implements them and receives a separate
founder/legal decision.

## 25 July 2026 submission-readiness determination

The package is **prepared but not ready to submit**. The exact gate register,
evidence manifest, project-specific approval boundary and founder/legal input
list are preserved at:

`artifacts/quality/youtube-api-submission-readiness-20260725-01/SUBMISSION-READINESS-AUDIT.md`

No form was submitted, no OAuth verification was requested, no quota extension
was requested and no provider approval is claimed by this update.
