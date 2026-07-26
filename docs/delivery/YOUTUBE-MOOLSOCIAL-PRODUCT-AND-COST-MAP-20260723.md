# YouTube–MoolSocial product and cost map — 23 July 2026

Status: **official-source decision record; Dev-only billing, the exact
INR 1,000 monthly alert, prerequisite services, Firestore, the keyless runtime
identity, restricted server key and token-encryption secrets are verified;
OAuth, live calls and production traffic are not authorized**

Environment: `moolsocial-dev-503018` only

## Cloud checkpoint

The founder enabled the minimum approved services in Dev/Trial:

- `youtube.googleapis.com`;
- `youtubeanalytics.googleapis.com`; and
- Google operation
  `operations/acat.p2-760290687711-a9ca0f31-b826-4955-8486-7e66dc423ca2`
  completed successfully.

`youtubereporting.googleapis.com`, Google Ads API, Merchant API and every
partner-only YouTube service remain deferred. One backend-only server key now
exists, restricted only to `youtube.googleapis.com` and held in Secret
Manager. No OAuth client, authorization token or production credential exists.

As of 24 July 2026, the intended organization billing account is open and
linked only to `moolsocial-dev-503018`. The sole project-scoped monthly alert
is `INR 1,000`, with 50%, 80% and 100% thresholds. It alerts but does not
hard-stop spend.

## Cost decision

YouTube currently publishes quota limits for the Data, Analytics, Reporting,
Player and Live APIs, not an ordinary per-call, per-upload or per-playback
price. That does **not** make a complete MoolSocial integration free.

The permanent cost rule is:

1. YouTube does not publish an API fee per official embedded playback;
2. MoolSocial never charges for API access, YouTube data or access to YouTube
   functionality;
3. MoolSocial may charge for independently valuable MoolSocial services;
4. any feature with external ad spend, material cloud cost or partner fees
   remains disabled until it has a named payer, price, budget and automatic
   cutoff; and
5. a provider quota is a capacity boundary, not a financial guarantee.

## Cost classes

| Class | Meaning | Release rule |
|---|---|---|
| `C0` | no published provider per-call price and no MoolSocial video storage, transcode or delivery | may enter Dev behind quota and policy controls |
| `C1` | low MoolSocial backend cost: broker, cache, webhook, database, logs and monitoring | free/basic product only while measured cost stays inside an approved allowance |
| `C2` | meaningful MoolSocial cost: OAuth verification/support, token vault, analytics jobs, moderation or creator operations | needs a monthly cost model and named product owner before public launch |
| `C3` | external spend or media-heavy cost: paid advertising, proxy upload, transcode, storage or CDN | off by default; payer, price and hard spend cap required |
| `P` | provider/audit/eligibility/partner gated | cannot be promised until the gate is passed |

“Free tier” means a limited allowance that can become billable after a
threshold. It is never described as permanently free.

## Verified private-Dev infrastructure floor

The 24 July cost-first decision uses Cloud Firestore as the active private-Dev
provider control plane. Data Connect/Cloud SQL adapters are preserved for later
relational product domains, but they are not deployed or provisioned by this
YouTube proof.

Official Google/Firebase pricing reviewed through 24 July 2026 establishes:

- Firebase Blaze linkage has no fixed subscription fee; metered services charge
  only when used.
- Request-based Functions 2nd gen can scale to zero with `minInstances=0`.
- Cloud Build includes 2,500 default-pool `e2-standard-2` build-minutes/month;
  Artifact Registry includes 0.5 GiB-month; Secret Manager includes six active
  versions and 10,000 accesses/month. Each allowance is limited and can change.
- Standard Play Integrity provides 10,000 token requests/day and 10,000
  decryptions/day. Retain the normal one-hour App Check TTL.
- The first qualifying Firestore database in a project has a limited free
  quota. The current published boundary includes 1 GiB storage, 50,000 reads
  per day, 20,000 writes per day, 20,000 deletes per day and 10 GiB outbound
  transfer per month.
- The private-Dev database is the Standard edition, Native mode `(default)`
  database in `asia-south1`. It is server-only and stores encrypted provider
  control state, idempotency, quota and redacted audit data—not video bytes.
- Provisioning must report `freeTier: true`; otherwise deployment stops.
- `firebaserules.googleapis.com` is required and the exact third deployment
  target is `firestore:rules`, alongside the two provider Functions.
- The sole Firestore client-rule source is
  `backend/firestore/youtube-private-dev.rules`, and it denies every client
  read and write. Post-deploy verification must fetch the active
  `cloud.firestore` release and referenced ruleset through the Firebase Rules
  REST API and compare the sole source file byte-for-byte with that repository
  rule.
- Firestore rules do not constrain Admin SDK or other privileged server
  access. The dedicated runtime service account, exact IAM grants and
  server-side authorization/tenant checks remain the privileged boundary.
- The runtime service account remains keyless, with zero user-managed keys.
- Physical Dev App Check uses the registered Dev SHA-256 and approved Play
  Integrity settings. No App Check debug-token exception is allowed in this
  package.
- Point-in-time recovery, TTL deletes, backups, restore and clone operations
  are not inside the Firestore free boundary and remain disabled for this
  proof.
- Because private Dev does not provision Data Connect or Cloud SQL, it has no
  Cloud SQL always-on instance cost floor.

Firestore free quota is a capacity boundary, not a zero-cost guarantee. Budget
alerts do not stop spend; hard application caps, `minInstances=0`,
`maxInstances=1`, artifact cleanup and feature kill switches are required.

Before any cloud mutation, the read-only
`scripts/check-youtube-private-dev-security-prerequisites.ps1` gate must pass.
The local Windows environment currently has no `gcloud`; Google Cloud Shell is
the authenticated execution surface for required cloud inventory/mutation.
No credentials or Cloud Shell session material may be copied into the
repository.

## Current YouTube quota boundaries

The current Dev service-usage inventory exposes separate project/day buckets:

- 100 `search.list` calls;
- 100 `videos.insert` uploads;
- 10,000 `videos.batchGetStats` calls; and
- 10,000 general YouTube Data API units for other methods.

MoolSocial's private-Dev caps are stricter: 20 searches/day, 10 uploads/day,
500 `videos.batchGetStats` calls/day and 2,000 general units/day. List reads
normally consume one general unit. Later connected
comment/rate/subscribe/playlist writes generally consume 50 units and require
`youtube.force-ssl` plus explicit, in-context consent; they are outside the
current readonly/upload/analytics scope package.

## Product opportunity and cost matrix

| MoolSocial capability | Provider contract | Cost class | Product decision |
|---|---|---:|---|
| Popular India/category video lanes | `videos.list(chart=mostPopular)` | `C0/C1` | MVP |
| Approved-channel uploads | `channels.list` + uploads playlist + `playlistItems.list` | `C0/C1` | MVP |
| Curated playlists | `playlists.list` + `playlistItems.list` | `C0/C1` | MVP |
| Explicit public search | `search.list` | `C0/C1/P` | MVP with server cache and a strict daily cap; default is only 100 calls/project/day |
| Public video/channel metadata | `videos.list`, `videos.batchGetStats`, `channels.list` | `C0/C1` | MVP |
| In-app playback | official YouTube IFrame Player in the isolated OS WebView/WKWebView exception | `C0` plus user data usage | sole compliant playback route; YouTube controls player, attribution and ads |
| Playlist continuation | IFrame player queue APIs using MoolSocial-selected eligible IDs | `C0/C1` | MVP; never call it YouTube “Up next” |
| Public comments read | `commentThreads.list`, `comments.list` | `C0/C1` | optional after capacity proof |
| Connected subscriptions | `subscriptions.list(mine=true)` | `C1/C2/P` | optional connected “Following” source |
| WebSub upload notices | PubSubHubbub callback | `C1` | later; cheaper than polling |
| Connected YouTube writes | comment/rate/subscribe/playlist methods | `C1/C2/P` | later; exact YouTube action and explicit consent |
| Direct creator upload | resumable `videos.insert`, phone directly to YouTube | `C0/C1/C2/P` | MVP creator proof; private only until audit |
| Scheduled creator publishing | private upload plus supported `status.publishAt` update | `C1/C2/P` | later creator plan |
| Thumbnail/caption/playlist tools | supported write methods | `C1/C2/P` | later creator plan; quota-heavy operations measured separately |
| Creator analytics | YouTube Analytics `reports.query` | `C1/C2/P` | MVP proof for the connected channel owner |
| Bulk reporting | YouTube Reporting API | `C2/P` | deferred; service remains disabled |
| Creator–brand access | `videos` `brandPartner` part for eligible users | `C1/C2/P` | later campaign workflow |
| Trackable product link and creator payout | MoolSocial campaign, order and ledger services | `C2` | core paid MoolSocial value |
| Live broadcast and live chat | Live Streaming API, including `streamList` | `C2/P` | later |
| Membership/Super Chat insights | eligible channel resources/events | `C2/P` | later; not generally available |
| YouTube Shopping affiliate reports | Merchant API reports for eligible merchants/program participants | `C2/P` | Workspace-owned later feasibility; alpha/eligibility gated and not a general product-tagging or order API |
| Demand Gen campaigns on YouTube/Shorts | Google Ads API | `C3/P` | Business Workspace-owned later product; advertiser pays media spend plus an approved MoolSocial service fee |
| Content ID operations | YouTube Content ID/Partner APIs | `P` | exclude from MVP; partner-only |
| Cross-platform managed media | MoolSocial storage/transcode/variants | `C3` | optional paid creator/business service only |
| MoolSocial-native Reel/Feed media | MoolSocial media stack | `C3` | excluded from this MVP deployment; no native video storage until a separate payer, budget, retention and media-cost approval exists |

Merchant API and Demand Gen are governed by
`ADR-0007-GOOGLE-COMMERCE-AND-PAID-GROWTH-WORKSPACE-BOUNDARY.md` and
`GOOGLE-COMMERCE-AND-DEMAND-GEN-WORKSPACE-BACKLOG-20260723.md`. Neither is part
of Screen 04 or the current Social MVP provider spike.

## Lowest-cost compliant architecture

### Watching

- Build native MoolSocial discovery from low-cost charts, approved channels,
  curated playlists and explicit cached search.
- Hydrate cards with permitted metadata and retain YouTube source attribution.
- Load only the selected video in the official player.
- Keep MoolSocial Save, Discuss, commerce and campaign functions outside the
  player.
- Use one active player; do not preload or autoplay a scrolling wall of
  players.
- Use ETags, coalescing, `videos.batchGetStats` and WebSub rather than frequent
  polling.

YouTube hosts and streams the video. The viewer uses their own mobile or Wi-Fi
data. YouTube does not publish a media-delivery charge to MoolSocial per
official embedded playback. MoolSocial remains responsible for its catalogue
broker, metadata cache, Firestore control-plane usage, Functions, Secret
Manager, observability, support and network costs when applicable allowances
are exceeded.

### Creator upload

- Use the narrow `youtube.upload` scope first.
- The backend validates the selected channel and opens a resumable upload.
- The phone uploads directly to YouTube; MoolSocial does not proxy, retain,
  transcode or serve the YouTube-bound media.
- Keep only authorized metadata, consent, job state, provider video ID,
  campaign linkage and audit evidence.
- Store refresh tokens encrypted server-side; access tokens remain short-lived
  and memory-only on the device.

This removes MoolSocial's YouTube-video storage and delivery bill and avoids a
MoolSocial media-ingress path for the upload. Token security, Firestore control
state, job reconciliation, support and audit work remain MoolSocial costs.

### Analytics and commerce

- Show YouTube metrics with a YouTube source and refresh time.
- Show MoolSocial clicks, orders, returns, commission and payouts as separate
  MoolSocial records.
- Do not create blended creator scores, earnings estimates or other derived
  YouTube metrics unless the YouTube audit explicitly approves that use.
- Creator commission comes only from eligible delivered MoolSocial orders,
  never YouTube views, likes, comments or subscriptions.

## Chargeable MoolSocial value

The following can support paid creator or business plans because they are
independent MoolSocial services:

- brand–creator matching and campaign management;
- product/service selection and trackable MoolSocial links;
- click, order, return, commission and payout tracking;
- drafts, scheduling, approvals and business workspaces;
- destination-specific media validation and cross-platform workflow;
- MoolSocial sales/conversion analytics and audit trails;
- bulk/agency operations when approved; and
- optional managed storage/transcoding when the customer explicitly chooses
  it and sees the price.

MoolSocial does not paywall API access, YouTube data or access to the official
YouTube player.

## Hard exclusions

MoolSocial must not:

- clone or present itself as a substitute for YouTube;
- claim to expose personalized YouTube Home, the native Shorts feed, watch
  history, Watch Later or the notification inbox;
- claim an authoritative public Shorts resource or infer a Shorts identity
  where the API provides no such resource/field;
- scrape, download or cache YouTube audiovisual bytes;
- hide YouTube attribution, controls, links or advertising;
- place MoolSocial advertising or commerce on or inside the player;
- charge a user to watch an embedded YouTube video;
- reward or pay for YouTube viewing or engagement;
- attach products to unrelated public videos without a real campaign/right;
- promise public automated uploads before the compliance audit; or
- enable additional APIs merely because their service-enablement step appears
  free.

## Release and pricing gates

Before a capability can leave Dev:

1. record its API method, scope, quota bucket and current provider rules;
2. record expected monthly requests, backend invocations, storage, database,
   monitoring, support and moderation;
3. set an application cap below the provider quota;
4. set a cloud budget alert and an application-side automatic stop;
5. identify who pays when the free allowance is exceeded;
6. publish truthful free/paid plan copy without selling YouTube access;
7. test quota, billing-threshold, revocation and feature-disable states; and
8. obtain the applicable OAuth, YouTube audit, partner and founder approvals.

Google Cloud budget alerts are warnings; they are not automatic spending caps.
MoolSocial must implement its own request and feature kill switches.

## Current next action

Keep Screen 04 HTML and Flutter on hold. Next:

1. publish and approve the OAuth consent/policy package, public legal/support
   URLs, exact test users and dedicated Dev YouTube channel;
2. create the Google Web OAuth client and transfer its ID/secret only through
   Google-controlled or interactive secret-entry surfaces;
3. run the complete pre-deploy package and read-only security-prerequisite
   gates;
4. deploy only the two provider
   Functions plus `firestore:rules`, with every capability flag off;
5. prove the sole physical-OPPO App Check path:
   `allowUnrecognizedVersion=true`, `requireLicensed=false` and
   `minDeviceRecognitionLevel=MEETS_DEVICE_INTEGRITY`, with the exact Dev
   SHA-256 registered and no debug-token exception;
6. measure real request and infrastructure usage through the private Dev
   evidence gates; and
7. revise Screen 04 only from observed provider behavior through the normal
   founder `FINAL` workflow.

## Official authorities

- YouTube Data API and quota:
  <https://developers.google.com/youtube/v3/getting-started>
- Granular quota calculator:
  <https://developers.google.com/youtube/v3/determine_quota_cost>
- Quota and compliance audits:
  <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>
- YouTube revision history:
  <https://developers.google.com/youtube/v3/revision_history>
- Resumable upload:
  <https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol>
- Player API:
  <https://developers.google.com/youtube/iframe_api_reference>
- Playlist-item limitations, including Watch Later/history access:
  <https://developers.google.com/youtube/v3/docs/playlistItems/list>
- Required minimum functionality:
  <https://developers.google.com/youtube/terms/required-minimum-functionality>
- Developer policies:
  <https://developers.google.com/youtube/terms/developer-policies>
- Policy compliance guide:
  <https://developers.google.com/youtube/terms/developer-policies-guide>
- Terms revision history:
  <https://developers.google.com/youtube/terms/revision-history>
- OAuth verification:
  <https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification>
- Analytics metrics:
  <https://developers.google.com/youtube/analytics/metrics>
- Live chat:
  <https://developers.google.com/youtube/v3/live/docs/liveChatMessages>
- Merchant API updates:
  <https://developers.google.com/merchant/api/latest-updates>
- Google Ads Demand Gen:
  <https://developers.google.com/google-ads/api/docs/demand-gen/overview>
- Demand Gen channel controls:
  <https://developers.google.com/google-ads/api/docs/demand-gen/channel-controls>
- Cloud Run pricing:
  <https://cloud.google.com/run/pricing>
- Firebase pricing plans:
  <https://firebase.google.com/docs/projects/billing/firebase-pricing-plans>
- Firebase SQL Connect pricing:
  <https://firebase.google.com/docs/sql-connect/pricing>
- Firebase SQL Connect database management and regions:
  <https://firebase.google.com/docs/sql-connect/manage-services-and-databases>
- Cloud Build pricing:
  <https://cloud.google.com/build/pricing>
- Artifact Registry pricing:
  <https://cloud.google.com/artifact-registry/pricing>
- Firestore pricing:
  <https://cloud.google.com/firestore/pricing>
- Firestore Security Rules:
  <https://firebase.google.com/docs/firestore/security/get-started>
- Firestore server/Admin authorization boundary:
  <https://firebase.google.com/docs/firestore/security/rules-conditions#authentication>
- Firebase Rules REST API:
  <https://firebase.google.com/docs/reference/rules/rest>
- Keyless service-account guidance:
  <https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys>
- Secret Manager pricing:
  <https://cloud.google.com/secret-manager/pricing>
- Cloud KMS pricing:
  <https://cloud.google.com/kms/pricing>
- Firebase App Check:
  <https://firebase.google.com/docs/app-check>
- Play Integrity quota and setup:
  <https://developer.android.com/google/play/integrity/setup>
- Cloud Billing budgets:
  <https://cloud.google.com/billing/docs/how-to/budgets>
