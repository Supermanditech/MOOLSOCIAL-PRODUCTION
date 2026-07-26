# YouTube private Dev integration runbook

Status: **cost-first Firestore provider foundation and Dev Play Integrity
registration verified; the billing account is open and linked only to Dev;
the exact INR 1,000 monthly budget alert target is live; deployment remains
blocked only by the remaining pre-deploy credential and security gates**

Authority:

- environment: `moolsocial-dev-503018`
- project number: `760290687711`
- branch: `remediation/prototype-conformance-2026-07-20`
- region: `asia-south1`
- API proposal:
  `YOUTUBE-API-COMPLIANCE-QUOTA-VALUE-PROPOSAL-20260723.md`
- capability inventory:
  `YOUTUBE-API-CAPABILITY-AND-ENDPOINT-MATRIX-20260723.md`

This is the architectural and verification authority for the private YouTube
provider proof. The exact cloud mutation order is the post-payment execution
runbook. It does not approve Screen 04, change the founder-review HTML, freeze
a reference, authorize Flutter presentation work, promote Staging or enable
Production.

## Current verified boundary

Verified locally through 24 July 2026:

- YouTube Data API and YouTube Analytics API were enabled only in
  `moolsocial-dev-503018`.
- The privileged Firebase Functions provider builds and typechecks.
- All deterministic provider tests pass.
- The active private-Dev persistence adapter is Cloud Firestore.
- The Firestore adapter uses atomic transactions for connection reservation,
  token compare-and-swap migration, one-use OAuth attempts, quota reservations
  and append-only redacted audit records.
- Data Connect schema/connectors remain preserved and compile as deferred
  architecture evidence. They are not deployment targets for this proof and
  do not authorize Cloud SQL provisioning.
- Every YouTube capability defaults to disabled.
- `capabilities` returns the disabled state.
- a public metadata request is rejected with HTTP 503
  `capability_disabled` before any provider call or quota reservation.
- public or unlisted upload is hard-disabled in code.
- 153/153 deterministic backend tests pass.
- the targeted Flutter platform, embedded-player runtime and compile-time-gated
  non-UI provider client pass analysis and 52/52 tests.
- the latest deferred Data Connect schema and connection-gated publication
  operations still compile in a fresh isolated generation workspace without
  becoming the active runtime adapter.
- no secret, token, authorization code, account credential or private media
  exists in the repository or evidence.

Verified in `moolsocial-dev-503018` through 24 July 2026:

- project ID/number and ACTIVE lifecycle;
- the intended organization billing account is open and linked only to
  `moolsocial-dev-503018`;
- the existing Firebase Browser key is not authorized for YouTube;
- Android app `com.moolsocial.app` is registered;
- the App Check API and Play Integrity API are enabled; and
- the founder accepted the applicable Google terms and Play Integrity is
  registered for the verified Dev signing fingerprint.
- the founder has explicitly authorized that Dev-only linkage under the
  recorded cost controls; and
- the exact project-scoped monthly Dev budget alert target is `INR 1,000`,
  with 50%, 80% and 100% current-spend notifications. It is an alerting
  target, not a hard Google Cloud spend ceiling.

Not yet claimed:

- restricted API key or OAuth client;
- Secret Manager values;
- deployed `(default)` Firestore database with `freeTier: true`;
- active `cloud.firestore` Rules release/ruleset whose sole source file is the
  exact deny-all repository rule;
- deployed Dev Functions;
- App Check enforcement against the Dev mobile app;
- live public metadata or player playback;
- a connected owner channel;
- a private upload;
- owner-authorized Analytics;
- provider revocation or live retained-data deletion; or
- measured quota, latency, cache or reliability results.

## Fixed architectural boundary

### Public discovery

- Public metadata is read by the privileged backend using a server API key.
- The key is restricted to the YouTube Data API.
- Search is invoked only after an explicit user submission.
- default discovery uses charts, creator upload playlists and curated
  playlists instead of imitating personalized YouTube Home or Shorts.
- the API does not expose personalized YouTube Home recommendations, watch
  history, Watch Later or an authoritative public Shorts resource/`isShort`
  field. MoolSocial must not claim or infer any of them.
- metadata is cached, requests are coalesced and unavailable or
  non-embeddable records are filtered.

### Official playback

- YouTube hosts and streams every YouTube audiovisual byte.
- Playback uses only the official YouTube IFrame Player.
- The OS WebView/WKWebView contains only that official player; changing Flutter
  or another native framework does not create a second compliant playback
  route.
- MoolSocial navigation, copy, commerce and business logic remain native
  outside that player.
- MoolSocial never downloads, proxies, caches or enables offline playback of
  YouTube media.

### Owner connection

- Google OAuth uses one confidential web-server client.
- Google receives a fixed HTTPS backend callback.
- Authorization Code, PKCE, cryptographic state and incremental scopes are
  required.
- the client secret and refresh tokens remain server-side.
- refresh tokens are AES-256-GCM encrypted at rest.
- access tokens remain process-memory-only.
- Flutter never receives the OAuth client secret or a refresh token.
- Google OAuth app verification and the YouTube API compliance/quota audit are
  separate gates.

### Creator upload

- the creator explicitly initiates and confirms each upload.
- the backend creates a private-only resumable session.
- the device sends media directly to the returned Google upload session.
- MoolSocial stores only encrypted orchestration metadata, never video bytes.
- the server binds completion to the video identity returned by that original
  resumable session and verifies owner channel and private visibility.
- idempotency, session expiry, retry and quota limits fail closed.
- public or unlisted publication remains unavailable until written YouTube
  approval.

### Analytics and commerce

- YouTube Analytics is queried only for the authorizing channel owner.
- YouTube metrics remain source-labelled and separate from MoolSocial visits,
  orders, commission and payouts.
- creator commission is calculated only from eligible delivered MoolSocial
  orders, never YouTube views, likes, comments, shares or subscriptions.

## Founder-secured Cloud configuration

The founder performs sign-in, password, OTP, recovery, consent and legal
identity steps directly in Google's surfaces. No credential value is sent to
Codex, written in a terminal command, stored in screenshots or committed.

The mandatory cloud order is governance APIs and billing, then the exact
founder-approved budget, then workload prerequisites and resources, then the
read-only cloud and security preflights, and only then deployment. The
numbered configuration details below do not authorize a different order. Follow
`YOUTUBE-PRIVATE-DEV-POST-PAYMENT-EXECUTION-20260724.md` for the exact stages.

### 1. Reauthenticate — completed 23 July 2026

Required:

- open `moolsocial-dev-503018` in Google Cloud Console;
- complete Google's password or 2-step verification directly there;
- run `firebase login --reauth` personally if the local CLI remains expired;
- confirm `firebase projects:list` can read the Dev project.

Stop if the selected project is not exactly `moolsocial-dev-503018`.

### 2. Inventory before mutation

Capture redacted evidence of:

- project ID and number;
- billing account attachment state;
- enabled APIs;
- current YouTube quota buckets;
- existing API keys and OAuth clients by identifier and restriction only;
- Functions runtime service account; and
- App Check registration for the Dev Android application.

Do not expose key values, client secrets, tokens or service-account material.

Completed inventory evidence:

`artifacts/quality/youtube-private-dev-cloud-bootstrap-20260723-01/CLOUD-BOOTSTRAP-EVIDENCE.md`

The billing account is open and linked only to Dev. The exact
founder-approved `INR 1,000` monthly alert is live with 50%, 80% and 100%
thresholds; it is not a hard spending cap. Deployment remains stopped until
every remaining OAuth and pre-deploy security prerequisite passes.

The local Windows environment does not currently contain `gcloud`. Cloud
inventory or mutation that requires `gcloud` must therefore run in the
founder-authenticated Google Cloud Shell for `moolsocial-dev-503018`; do not
copy credentials or shell session material into the repository.

### 3. Create the restricted server key

Create one backend-only API key:

- API restriction: YouTube Data API v3 only;
- application restriction: fixed server egress IP only when an approved fixed
  egress design exists;
- custody: Secret Manager as `YOUTUBE_SERVER_API_KEY`;
- never embed it in Flutter.

A fixed outbound IP normally requires billable network infrastructure. Until
finance approves that cost, the compensating controls are Secret Manager,
backend-only use, App Check, Authentication where applicable, method
allow-listing, internal quotas, logs and immediate key revocation. The absence
of a fixed IP must not be represented as equivalent to an IP restriction.

### 4. Configure the OAuth consent client

Create one Web application OAuth client:

- exact callback:
  `https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeOAuthCallback`
- support email and authorized domains owned by MoolSocial;
- Dev test users only until OAuth verification permits broader access;
- scopes requested incrementally and in context:
  - `youtube.readonly`
  - `youtube.upload`
  - `yt-analytics.readonly`
- client ID in Secret Manager as `YOUTUBE_OAUTH_CLIENT_ID`;
- client secret in Secret Manager as `YOUTUBE_OAUTH_CLIENT_SECRET`;
- callback environment value as `YOUTUBE_OAUTH_REDIRECT_URI`.

The integration never uses Google basic sign-in as consent for YouTube channel
access.

### 5. Create encryption material

Generate two distinct sets of 32 cryptographically random bytes and store the
base64url values only in Secret Manager as:

`YOUTUBE_TOKEN_ENCRYPTION_KEY_V1`

`YOUTUBE_TOKEN_ENCRYPTION_KEY_V2`

V2 is the current write key. V1 is the previous read-only rotation key.
Credential reads select the key only by the authenticated envelope version and
atomically migrate legacy V1 ciphertext to V2. Record secret version
identifiers and access policies, never values.

### 6. App Check and service identity

- register the exact Dev Android package and signing certificates;
- activate the supported Android App Check provider in the Dev app;
- use limited-use App Check tokens for owner connection, upload, Analytics and
  disconnect operations;
- grant the Functions runtime service account the minimum role required to
  consume limited-use App Check tokens;
- keep that runtime identity keyless: zero user-managed service-account keys;
- keep local emulator bypass limited to local mode;
- prove missing, invalid, expired and replayed tokens return HTTP 401.

The official replay-protection flow adds a network verification call and may
add latency. Measure it in Preview rather than hiding it.

The mobile client uses `AndroidPlayIntegrityProvider`. A USB-installed or
sideloaded Dev APK is not Play-licensed or `PLAY_RECOGNIZED` by default.
Before physical OPPO proof, the exact Dev Play Integrity configuration must be:

- `appIntegrity.allowUnrecognizedVersion = true`;
- `accountDetails.requireLicensed = false`; and
- `deviceIntegrity.minDeviceRecognitionLevel = MEETS_DEVICE_INTEGRITY`.

This is the sole current route. The expected SHA-256 certificate must be
registered and no App Check debug token may remain. There is no debug-token
exception in the private-Dev deployment package. A debug-provider build/token
is deferred and not implemented by this package. Do not claim OPPO readiness
from certificate registration alone; missing, invalid, expired and
replayed-token tests remain required.

## Deploy with every capability disabled

Non-secret runtime settings:

```text
MOOLSOCIAL_PROVIDER_ENV=dev
YOUTUBE_OAUTH_REDIRECT_URI=https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeOAuthCallback
YOUTUBE_PUBLIC_DATA_ENABLED=false
YOUTUBE_OWNER_CONNECT_ENABLED=false
YOUTUBE_PRIVATE_UPLOAD_ENABLED=false
YOUTUBE_OWNER_ANALYTICS_ENABLED=false
YOUTUBE_DEV_SEARCH_DAILY_CAP=20
YOUTUBE_DEV_UPLOAD_DAILY_CAP=10
YOUTUBE_DEV_BATCH_STATS_DAILY_CAP=500
YOUTUBE_DEV_ANALYTICS_DAILY_CAP=100
YOUTUBE_DEV_GENERAL_DAILY_CAP=2000
```

Deploy exactly these three targets:

- `functions:provider:youtubeProvider`;
- `functions:provider:youtubeOAuthCallback`; and
- `firestore:rules`.

Provision exactly one Cloud Firestore Standard edition, Native mode,
`(default)` database in `asia-south1` before Function deployment. Keep delete
protection enabled and PITR, TTL policies, backups and backup schedules off.
The provisioning proof must report `freeTier: true`; otherwise stop before
deployment.
The database is a server-only provider control plane; mobile/web clients do not
receive direct access to its provider collections.

Enable `firebaserules.googleapis.com` and deploy only
`backend/firestore/youtube-private-dev.rules`, whose complete source is:

```text
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Firestore Security Rules do not restrict Admin SDK or other privileged server
access. The deny-all client rule is therefore only one layer; the dedicated
runtime service account, exact IAM roles and server-side tenant/authorization
checks remain mandatory.

Do not deploy Data Connect or provision Cloud SQL for this proof. The existing
Data Connect adapters are preserved for later relational product domains.

Both Functions run as the dedicated
`youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`
identity. The deployer needs `iam.serviceAccounts.actAs` on that identity,
normally through service-account-scoped `roles/iam.serviceAccountUser`.
Project Owner is not an acceptable shortcut. The runtime identity must remain
keyless, with zero user-managed keys.

Grant the active human deployer that role on the service account itself:

```bash
PROJECT_ID="moolsocial-dev-503018"
RUNTIME_SA="youtube-provider-runtime@${PROJECT_ID}.iam.gserviceaccount.com"
DEPLOYER_ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
test -n "$DEPLOYER_ACCOUNT" || {
  echo "No active gcloud account is selected." >&2
  exit 1
}

gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_SA" \
  --member="user:${DEPLOYER_ACCOUNT}" \
  --role="roles/iam.serviceAccountUser" \
  --project="$PROJECT_ID"
```

Stop if the active account is not the intended founder/deployer. A future
reviewed service-account deployer must use its explicit `serviceAccount:`
member. The cloud preflight verifies both the scoped binding and
`iam.serviceAccounts.actAs` before deployment.

The first Functions 2nd-gen deploy may create the expected source bucket,
Cloud Build execution, `gcf-artifacts` repository and Eventarc/Pub/Sub service
identities or transport resources. They must remain in the exact Dev
project/region and are deployment infrastructure, never an application video
store. Apply and verify one-day Functions artifact cleanup immediately after
deployment.

The Functions predeploy hook must compile the TypeScript source before any
deployment.

After governance, budget and every workload/security prerequisite above is in
place, but before deploying Functions or Rules, run the read-only security
prerequisite gate:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\check-youtube-private-dev-security-prerequisites.ps1 `
  -ProjectId moolsocial-dev-503018 `
  -ServerApiKeyUid <SERVER_API_KEY_UID> `
  -AndroidAppId <FIREBASE_ANDROID_APP_ID> `
  -ExpectedSha256 <DEV_SIGNING_SHA256_WITH_COLONS> `
  -AllowNoServerIpRestriction
```

The complete pre-deployment proof is the cloud preflight followed by this
security prerequisite. Together they prove the YouTube-only API-key
restriction, exact Android application/package and signing fingerprint, Play
Integrity configuration, zero App Check debug tokens, the keyless runtime
identity and the required project/IAM boundary. A failure is a deployment
stop, not a waiver.

Pass before enabling a capability:

- deployed `capabilities` returns all false;
- an attempted public request returns `capability_disabled`;
- an owner request without Firebase Authentication and App Check fails;
- logs contain request ID and redacted error only;
- the active `cloud.firestore` release is fetched through the Firebase Rules
  REST API, its referenced ruleset is fetched, and that ruleset contains
  exactly one file with the exact deny-all source above; and
- Staging and Production service lists remain unchanged.

## Capability proof sequence

Use only `scripts/activate-youtube-private-dev-proof.ps1`. Select one of its
seven enum-only profiles, use that profile's unique confirmation phrase and
choose a server-enforced proof window of 1–30 minutes. The script verifies the
all-disabled deployed state before activation, deploys only the exact two
reviewed Functions, verifies the one-profile state, and returns to the
all-disabled state in `finally`. A second capability cannot be injected through
generic command arguments.

The founder-accepted continuous public-viewing exception is a separate,
fail-closed deployment profile:

- use only `scripts/deploy-youtube-private-dev.ps1 -Mode Deploy
  -CapabilityProfile PublicDataReview`;
- pass the exact confirmation
  `KEEP_YOUTUBE_PUBLIC_DATA_REVIEW_LIVE_IN_DEV`;
- target only `moolsocial-dev-503018`;
- require `YOUTUBE_PUBLIC_DATA_REVIEW_MODE=accepted`;
- permit only `YOUTUBE_PUBLIC_DATA_ENABLED=true`;
- keep Owner Connect, Owner Actions, Creator Assets, Live, Private Upload and
  Owner Analytics false;
- keep Firebase App Check enforcement and the existing quota caps; and
- never deploy this accepted-review profile to Staging or Production.

The accepted-review marker and timed proof controls are mutually exclusive.
Any wrong project, wrong marker, proof-control conflict or second capability
fails closed. A failed deployment or verification automatically deploys and
verifies the all-disabled profile. This exception authorizes repeatable
founder review of accepted public metadata and official playback only; it does
not waive any later OAuth, upload, live, Analytics, UI or release gate.

### Gate A — public metadata

Use only the `PublicData` supervised profile. It is the sole authority to set
`YOUTUBE_PUBLIC_DATA_ENABLED=true` during its bounded proof.

Prove:

1. India most-popular page;
2. known eligible playlist;
3. explicit submitted search;
4. batched video details;
5. pagination;
6. cache hit and request coalescing;
7. missing optional metadata;
8. private, removed, rejected and non-embeddable filtering;
9. invalid page token, provider 429/5xx, timeout and offline recovery; and
10. application quota stop at the configured cap.

This gate proves MoolSocial-curated discovery, not personalized YouTube Home,
native recommendations, watch history, Watch Later or an authoritative Shorts
feed. Those experiences are not exposed by the approved API contract.

### Gate B — official player on physical OPPO

No owner OAuth is required.

Entry is blocked until the exact off-Play Dev Play Integrity configuration in
Founder-secured Cloud configuration step 6 is proven on the exact OPPO
candidate. A sideloaded build rejected because those verdict requirements are
wrong is not a provider or customer-network failure.

Prove:

- user-selected start;
- visible YouTube controls, branding, links and provider ads;
- at least 200x200 player viewport;
- pause, resume, seek, completion and fullscreen;
- rotation and safe areas;
- audio focus, headphones, call interruption and app switch;
- age, region, embed, removed/private, error 153, integrity and offline states;
- no MoolSocial overlay or ad on the player; and
- no background or offline playback.

This proof can inform a new HTML candidate. It does not authorize changing the
current founder-review Screen 04 or Flutter presentation.

### Gate C — owner connection

Use only the `OwnerConnect` supervised profile.

Using a dedicated Dev test channel:

1. request `youtube.readonly` only when Connect YouTube is tapped;
2. complete Google consent in the system browser;
3. verify the fixed backend callback;
4. read `channels.list(mine=true)`;
5. show the exact selected channel through sanitized connection status;
6. cancel and wrong-account paths;
7. no-channel and revoked-token paths;
8. callback replay rejection;
9. App Check token replay rejection; and
10. disconnect with immediate local credential, job and OAuth-attempt deletion.

### Gate D — private direct upload

Use only the `PrivateUpload` supervised profile.

Before upload, record creator confirmation of:

- destination channel;
- title and full description;
- category;
- Made-for-Kids choice;
- paid-promotion declaration;
- altered/synthetic-media declaration;
- subscriber-notification choice;
- rights/licence attestation;
- YouTube Community Guidelines and copyright acknowledgement; and
- private Dev visibility.

Prove:

1. one resumable session is created for one idempotency key;
2. changed input under the same key is rejected;
3. the device uploads directly to Google;
4. interruption resumes from provider-confirmed range;
5. stale or expired sessions stop without duplicate creation;
6. the returned video identity belongs to the connected channel;
7. privacy remains private;
8. processing reaches a terminal state;
9. no unattended or bulk upload path exists;
10. upload cap exhaustion does not retry or create a second project.

### Gate E — owner Analytics

Use only the `OwnerAnalytics` supervised profile and only after incremental
analytics consent.

Prove:

- date range and allowed metrics;
- exact selected channel;
- source and refresh-time labels;
- tenant isolation;
- revoked or missing scope;
- provider empty result and failure;
- separation from MoolSocial commerce metrics; and
- no inferred YouTube revenue or payout.

### Gate F — deletion and rollback

Prove:

- Google token revocation is attempted;
- local tokens, connection, publication jobs and OAuth attempts are deleted
  even if provider revocation is temporarily unavailable;
- provider revocation result is truthfully reported;
- each capability flag stops independently;
- disconnect/deletion remains available during a feature stop;
- native MoolSocial Reels and Feed remain unaffected; and
- server API key and OAuth client can be revoked without a mobile release.

Every baseline or proof deploy failure must first attempt an exact
Functions-only all-disabled rollback and verify the latest Cloud Run revision
receives 100% of traffic. If that rollback cannot be verified, invoke
`scripts/contain-youtube-private-dev.ps1` with its unique containment
confirmation. Hard containment removes only the unconditional `allUsers`
`roles/run.invoker` binding from the exact two reviewed Run services. It does
not mutate other IAM bindings or any other service.

## Preview measurement

Run a private App Distribution Preview for 14–30 days and continue until both
conditions are met:

- at least 14 complete UTC days; and
- enough calls to describe each requested quota bucket without a misleading
  percentile. A low-volume bucket uses maximum observed demand plus an
  explicit forecast instead of unstable P95/P99 language.

Measure:

- eligible official-player sessions;
- opted-in connected channels;
- user-confirmed private upload starts and completions;
- Analytics opens by consenting channel owners;
- per-method calls, quota units and peak minute;
- cache and coalescing rate;
- provider latency and failure categories;
- App Check verification and replay failures;
- disconnect/deletion success; and
- genuine MoolSocial destination visits separately from YouTube engagement.

Combine measured Preview results with a transparent launch forecast:

- projected users by type;
- percentage opting into each capability;
- calls per participating user;
- cache assumptions;
- upload confirmation rate;
- expected daily and peak volume; and
- 30% operational headroom.

No evidence may claim incremental YouTube reach, MoolSocial adoption, sales or
creator income until it has actually been measured.

## Cost and pricing gate

YouTube API quota is an allocation, not a pay-as-you-go product. The current
Dev service-usage inventory exposes separate project/day buckets:

- 100 `search.list` calls/day/project;
- 100 `videos.insert` uploads/day/project;
- 10,000 `videos.batchGetStats` calls/day/project; and
- 10,000 general YouTube Data API units/day/project for the other methods.

The private-Dev application caps remain stricter:

- 20 searches/day;
- 10 uploads/day;
- 500 `videos.batchGetStats` calls/day; and
- 2,000 general units/day.

List reads normally consume one general unit. Later connected write methods
such as comment, rate, subscribe and playlist mutation generally consume 50
units and require the broader `youtube.force-ssl` scope plus explicit,
in-context owner consent. They are outside the current readonly/upload/analytics
proof.

Additional quota requires the official compliance audit and quota extension
form. MoolSocial must not create duplicate projects to evade limits.

Google/Firebase infrastructure can still cost money:

- Functions invocations and network;
- Firestore operations, storage and network after applicable free quota;
- Secret Manager;
- App Check verification traffic;
- logging and monitoring;
- fixed egress/NAT if approved;
- moderation and support; and
- any later Google Ads media spend.

The intended organization billing account is now open and linked only to
`moolsocial-dev-503018`. The exact project-scoped monthly budget alert target
is live at `INR 1,000`, with 50%, 80% and 100% notifications. This budget does
not stop spend. The actual hard controls remain application quota caps,
`maxInstances=1`, one expiring capability profile, verified disable-all
rollback and IAM containment.

The measured minimum-cost boundary current through 24 July 2026 is:

- attaching the Firebase Blaze plan has no fixed subscription charge by
  itself; usage of enabled billable services is charged;
- request-based Functions 2nd gen can scale to zero with `minInstances=0` and
  has a billing-account free allowance;
- Cloud Build's default pool, Artifact Registry and Secret Manager each have
  limited included allowances;
- Play Integrity standard requests are limited to 10,000/day by default;
- the first qualifying Firestore database in a project has a limited free
  quota that currently includes 1 GiB stored data, 50,000 document reads/day,
  20,000 writes/day, 20,000 deletes/day and 10 GiB outbound/month;
- TTL deletes, point-in-time recovery, backups, restore and clone operations
  are outside that free boundary; therefore they remain disabled in private
  Dev; and
- Data Connect and Cloud SQL are preserved/deferred and create no private-Dev
  cost because they are not provisioned by this deployment.

Firestore's free quota is a capacity boundary, not a promise of permanent zero
cost. Budget alerts are notifications, not hard spending stops, so application
quota caps and feature kill switches remain mandatory.

The search/upload/batch-stats/general caps apply only to the provider request
paths. They are not a global Cloud Billing cap and cannot stop charges from
unrelated services, builds, logs or administrator actions.

YouTube does not publish an API fee per official embedded playback. Paid
MoolSocial plans cover only MoolSocial-owned Workspace, campaign, commerce
attribution, order/commission administration, team workflow, independent
analytics or capped managed-media services. MoolSocial never resells API
access, YouTube data or access to YouTube functionality.

## Audit submission

Official guidance:

<https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>

Official form:

<https://support.google.com/youtube/contact/yt_api_form?hl=en>

There is no published ordinary submission email. The founder or named
legal/platform owner submits the form after the Preview evidence gate and
enters every legal identity, reviewer account and contact detail directly.

Required package:

- legal entity and contact;
- project ID/number and OAuth client identifiers without secrets;
- Android package, iOS bundle and review entry points;
- product, privacy, Terms, support, revocation and deletion URLs;
- requested scopes and endpoint inventory;
- architecture, data flow and token custody;
- public metadata/player evidence;
- connection, private upload, Analytics and deletion evidence;
- quota dashboard and transparent forecast;
- rights, abuse, anti-spam, moderation and incident controls;
- readable screenshots/PDF; and
- founder/legal accuracy sign-off.

## Stop conditions

Stop and disable the affected capability if:

- the project, OAuth client or callback differs from this runbook;
- any secret appears in Flutter, source, chat, terminal history or evidence;
- media bytes pass through MoolSocial infrastructure;
- an upload is not private before written approval;
- ownership or scope cannot be reconciled;
- App Check or Authentication is bypassed in Dev;
- quota, cost or abuse limits fail;
- the official player is altered or obscured; or
- evidence would require an unverified claim.

## Completion definition

Private Dev integration is complete only after Gates A–F pass against
`moolsocial-dev-503018`, the redacted evidence package is durable, and the
founder has reviewed the actual OPPO journey. Local tests, API enablement or a
draft proposal alone do not satisfy this definition.

The OPPO completion claim additionally requires a proven App Check route for
the exact installed candidate. Neither Play Integrity registration nor a
registered signing fingerprint alone satisfies that requirement.

## Official authorities

- YouTube quota costs:
  <https://developers.google.com/youtube/v3/determine_quota_cost>
- YouTube API revision history and current separate quota buckets:
  <https://developers.google.com/youtube/v3/revision_history>
- Playlist-item limitations, including Watch Later/history access:
  <https://developers.google.com/youtube/v3/docs/playlistItems/list>
- Official IFrame Player API:
  <https://developers.google.com/youtube/iframe_api_reference>
- Required minimum functionality:
  <https://developers.google.com/youtube/terms/required-minimum-functionality>
- YouTube API Services developer policies:
  <https://developers.google.com/youtube/terms/developer-policies>
- Server-side OAuth:
  <https://developers.google.com/youtube/v3/guides/auth/server-side-web-apps>
- Firestore Security Rules:
  <https://firebase.google.com/docs/firestore/security/get-started>
- Firestore server/Admin authorization boundary:
  <https://firebase.google.com/docs/firestore/security/rules-conditions#authentication>
- Firebase Rules REST API:
  <https://firebase.google.com/docs/reference/rules/rest>
- Keyless service-account guidance:
  <https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys>
