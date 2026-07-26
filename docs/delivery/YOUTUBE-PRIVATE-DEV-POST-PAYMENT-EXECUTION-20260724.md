# YouTube private Dev post-payment execution

Date: 24 July 2026
Status: **billing, INR 1,000 monthly alert, prerequisite APIs, the keyless
least-privilege runtime identity, Firestore, the restricted server key and
both token-encryption secrets are verified; OAuth, disabled workload
deployment and live provider proof remain**

This is the exact cost-first path from an open Cloud Billing account to a
deployed, disabled-by-default private YouTube provider proof. It supplements
`YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md` and is constrained by
`ADR-0008-YOUTUBE-PRIVATE-DEV-FIRESTORE-COST-FIRST-CONTROL-PLANE.md`.

## Immutable boundary

- Branch:
  `remediation/prototype-conformance-2026-07-20`
- Authorized project: `moolsocial-dev-503018`
- Project number: `760290687711`
- Authorized billing account: `01F9D3-44031C-B5E225`
- Billing checkpoint: account open; only `moolsocial-dev-503018` linked on
  24 July 2026
- Organization: `1067591230270`
- Region: `asia-south1`
- Runtime identity:
  `youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`
- Active persistence: Cloud Firestore Standard edition, Native mode,
  database `(default)`, `asia-south1`
- Firestore client rule: exact deny-all source at
  `backend/firestore/youtube-private-dev.rules`
- Staging and Production: forbidden
- Screen 04/Social presentation: `DRAFT / HOLD`; unchanged
- Public or unlisted YouTube upload: forbidden
- All four provider capabilities: disabled at initial deployment
- Exact deploy targets:
  `functions:provider:youtubeProvider`,
  `functions:provider:youtubeOAuthCallback` and `firestore:rules`
- Data Connect and Cloud SQL: preserved for later product domains, but
  forbidden in this private Dev deployment
- MoolSocial native long-form video storage/streaming: excluded from MVP

The INR 3,000 amount shown by Google is an account
prepayment/activation requirement. It is not a MoolSocial monthly budget
decision and does not authorize uncapped spend.

YouTube hosts and streams YouTube video bytes. For the approved private upload
proof, the phone uploads directly to the Google resumable-upload URL.
MoolSocial does not store, proxy, transcode or serve those media bytes.
YouTube API use is quota-governed rather than a per-view or per-upload media
charge.

Current standard allocation is separated into 100 `search.list` calls/day,
100 `videos.insert` uploads/day, 10,000 `videos.batchGetStats` calls/day and a
shared 10,000-unit/day bucket for other Data API methods. MoolSocial's Dev
caps remain the stricter search/upload/batch-stats/general
`20/10/500/2000`. Public or unlisted publishing remains forbidden in this
proof.

MoolSocial still owns its lightweight control-plane cost: Functions,
Firestore operations/storage, Secret Manager, build artifacts, App Check,
logging and support. The selected Firestore design removes the Cloud SQL
always-on cost floor, but the Firestore free quota is a measured boundary,
not a zero-cost guarantee.

## Remaining founder-secured inputs

These values are entered only into Google-controlled or interactive
secret-entry surfaces. They are never written into chat, source, command
history or evidence:

1. Google account password, OTP and recovery approval;
2. OAuth client secret;
3. API key string;
4. token-encryption key material; and
5. dedicated Dev test-channel authorization.

The remaining founder-secured product and consent inputs are:

1. the MoolSocial-owned OAuth support email;
2. the public Privacy Policy URL;
3. the public Terms URL;
4. the public support/revocation/deletion URL; and
5. the exact Google test users and dedicated Dev YouTube channel.

No Codex surface may invent these values.

The billing account and Dev-project link are no longer blockers. On 24 July
2026 the founder approved an exact monthly private-Dev budget alert of
`INR 1,000`, using the reviewed 50%, 80% and 100% current-spend thresholds.
This is an alerting guardrail, not a hard Google Cloud spending cap. The
application quota hard stops, max-instance boundary and feature flags remain
mandatory.

The live project-scoped budget was then created and independently re-read as
the only budget on the authorized billing account:

`billingAccounts/01F9D3-44031C-B5E225/budgets/0e7b2597-9abd-4660-bbfd-a6cd91d2d121`

Durable evidence is at
`artifacts/quality/youtube-private-dev-budget-20260724-04/LIVE-BUDGET-EVIDENCE.md`.

After the live budget passed, the exact reviewed governance,
workload-prerequisite and provider API inventory was enabled or idempotently
confirmed. Data Connect, Cloud SQL Admin and YouTube Reporting remain disabled.
No workload or credential was created by that API action. Evidence is at
`artifacts/quality/youtube-private-dev-api-prerequisites-20260724-05/LIVE-API-PREREQUISITE-EVIDENCE.md`.

The dedicated runtime identity was then created and re-read. It has exactly
the Datastore User and App Check Token Verifier project roles, zero
user-managed keys, and one service-account-scoped Service Account User binding
for the reviewed founder-domain deployer. Evidence is at
`artifacts/quality/youtube-private-dev-runtime-identity-20260724-06/LIVE-RUNTIME-IDENTITY-EVIDENCE.md`.

The single approved Firestore Standard `(default)` database was subsequently
created in `asia-south1`. It reports `freeTier: true`, delete protection on,
PITR off, and zero TTL policies, backup schedules or retained backups.
Evidence is at
`artifacts/quality/youtube-private-dev-firestore-20260724-07/LIVE-FIRESTORE-EVIDENCE.md`.

No active `cloud.firestore` Rules release existed immediately after creation.
Do not activate a provider endpoint until the exact repository deny-all source
is deployed and its active release/ruleset is independently verified.

The exact-name server-key inventory then returned one API key restricted only
to `youtube.googleapis.com`. Its value was piped directly into
`YOUTUBE_SERVER_API_KEY`, which has one enabled version and one accessor
binding for the dedicated runtime identity. Two distinct 32-byte token
encryption keys were generated inside Cloud Shell and piped directly into
`YOUTUBE_TOKEN_ENCRYPTION_KEY_V1` and
`YOUTUBE_TOKEN_ENCRYPTION_KEY_V2`; each has one enabled version and one exact
runtime accessor binding. No value was printed or stored in the repository.
Evidence is at
`artifacts/quality/youtube-private-dev-restricted-secrets-20260724-08/LIVE-RESTRICTED-SECRETS-EVIDENCE.md`.

The OAuth client ID and client secret remain absent. No placeholder was
created. The founder-owned consent screen, public Privacy Policy, Terms and
support/deletion URLs, exact test users, dedicated Dev YouTube channel and
Google-created Web OAuth client remain required before Function deployment.

## Stage 0 — local no-cloud-write gate

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\deploy-youtube-private-dev.ps1 `
  -Mode Validate
```

`Validate` is the only no-cloud-write deployment-script mode. Do not substitute
Firebase CLI `--dry-run`: it may enable APIs or create service identities.

The local gate verifies the branch and frozen baseline, approved UI locks,
exact Dev settings, backend tests, targeted Flutter provider tests, package
content and patch integrity.

The local Windows host currently has no `gcloud` executable. Do not report the
local `-Cloud` preflight, security prerequisite or deployed-state verifier as
passed there. Founder-authenticated Google Cloud Shell is the current surface
for Cloud inventory and administrative commands. Deployment remains blocked
until the executing environment has authenticated `gcloud` and the exact
read-only gates pass.

## Non-negotiable mutation order

The durable order is governance and billing, then the exact budget, then
workload prerequisites, then the read-only security preflight, and only then
application deployment. Stages 1–2 must complete before any Stage 3–7 workload
resource is enabled or created. The security preflight depends on those
resources and therefore runs after their configuration, immediately before
Stage 8.

## Stage 1 — enable governance APIs, then verify billing

Enable the governance APIs before creating or linking a workload:

```bash
gcloud services enable \
  serviceusage.googleapis.com \
  cloudbilling.googleapis.com \
  cloudresourcemanager.googleapis.com \
  billingbudgets.googleapis.com \
  --project="moolsocial-dev-503018"
```

Run in founder-authenticated Google Cloud Shell:

```bash
PROJECT_ID="moolsocial-dev-503018"
BILLING_ACCOUNT_ID="01F9D3-44031C-B5E225"

gcloud billing accounts describe "$BILLING_ACCOUNT_ID" \
  --format="yaml(name,open,displayName)"

gcloud billing projects describe "$PROJECT_ID" \
  --format="yaml(projectId,billingEnabled,billingAccountName)"
```

The 24 July 2026 checkpoint already reports `open: true` and the Dev project
linked to this account. Retain the commands below as a repeatable read-only
verification. Run the link command only if an authorized verifier proves the
link is absent; never relink to another account:

```bash
gcloud billing projects link "$PROJECT_ID" \
  --billing-account="$BILLING_ACCOUNT_ID"

gcloud billing projects describe "$PROJECT_ID" \
  --format="yaml(projectId,billingEnabled,billingAccountName)"
```

Required result:

```text
billingEnabled: true
billingAccountName: billingAccounts/01F9D3-44031C-B5E225
```

Do not link any other project.

## Stage 2 — exact project budget before workload APIs

Record the founder-approved amount in
`deployment/youtube-private-dev/deployment-manifest.json` at
`budget.approvedMonthlyAmount`.

List the exact display name before any create command:

```bash
gcloud billing budgets list \
  --billing-account="01F9D3-44031C-B5E225" \
  --filter='displayName="MoolSocial Dev Trial monthly guardrail"' \
  --format="json(name,displayName,amount,budgetFilter,thresholdRules)"
```

Stop if more than one result exists. Create the budget only if the result is
empty:

```bash
APPROVED_MONTHLY_BUDGET_INR="<FOUNDER_APPROVED_MONTHLY_BUDGET_INR>"

gcloud billing budgets create \
  --billing-account="01F9D3-44031C-B5E225" \
  --display-name="MoolSocial Dev Trial monthly guardrail" \
  --budget-amount="${APPROVED_MONTHLY_BUDGET_INR}INR" \
  --calendar-period=month \
  --filter-projects="projects/760290687711" \
  --threshold-rule=percent=0.50 \
  --threshold-rule=percent=0.80 \
  --threshold-rule=percent=1.00
```

If that display name already exists, verify its amount, currency, monthly
calendar period, exact project filter and 50/80/100 percent current-spend
thresholds. Do not create a duplicate to work around a mismatch.

Budgets alert; they do not stop service. Disabled capability flags, application
quota caps, scale-to-zero Functions, `maxInstances: 1` and provider rollback
are the hard operational controls.

The YouTube daily caps constrain this provider's request paths. They are not a
global Cloud Billing cap and cannot prevent charges from an unrelated enabled
service, build, log sink or administrator action.

## Stage 3 — enable only the workload service inventory

Enable only the services listed in
`deployment/youtube-private-dev/deployment-manifest.json`.
The workload prerequisites, enabled only after Stage 2, are:

```bash
gcloud services enable \
  apikeys.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  cloudfunctions.googleapis.com \
  eventarc.googleapis.com \
  firebase.googleapis.com \
  firebaserules.googleapis.com \
  firestore.googleapis.com \
  iam.googleapis.com \
  pubsub.googleapis.com \
  run.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  --project="moolsocial-dev-503018"
```

The provider services are Firebase App Check, Play Integrity, YouTube Data API
and YouTube Analytics API. They are already expected to be enabled and must be
verified.

Keep these services disabled:

- Firebase Data Connect;
- Cloud SQL Admin; and
- YouTube Reporting.

Do not enable Maps, Places, Routes, Merchant, Google Ads or another unowned API
during this proof. `storage.googleapis.com` supports only Functions
source/build artifacts in this deployment. It is not authorization for
MoolSocial video or app-media storage.

The first Functions 2nd-gen deployment normally materializes Google-managed
deployment resources even though the application scales to zero: a Google
Cloud Functions source bucket, Cloud Build execution, the `gcf-artifacts`
Artifact Registry repository, and Eventarc/Pub/Sub service identities or
transport resources. These are expected deployment mutations, not product
media infrastructure. They must remain in the exact Dev project/region, use
Google-managed identities where applicable, and pass one-day artifact cleanup
verification.

## Stage 4 — create the least-privilege runtime identity

Create the dedicated identity only if it does not already exist:

```bash
PROJECT_ID="moolsocial-dev-503018"
RUNTIME_SA="youtube-provider-runtime@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create youtube-provider-runtime \
  --display-name="YouTube provider private Dev runtime" \
  --project="$PROJECT_ID"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/firebaseappcheck.tokenVerifier"
```

Grant `roles/secretmanager.secretAccessor` to this identity separately on each
of the five named provider secrets after the secrets exist. Do not grant
project Owner, Editor, Datastore Owner, broad Secret Manager administration or
an unrelated service-agent role.

Both provider Functions must execute as this exact identity.

Do not create or download a service-account key. The runtime identity must
have zero `USER_MANAGED` keys. Functions use the attached service account and
Google-managed credentials.

The authenticated deployer must hold
`iam.serviceAccounts.actAs` on the runtime identity, normally through
`roles/iam.serviceAccountUser` scoped to that service account. Do not grant a
project-wide owner role as a shortcut.

Grant that role on the service account itself to the exact authenticated
founder/deployer account:

```bash
DEPLOYER_ACCOUNT="$(gcloud config get-value account 2>/dev/null)"
test -n "$DEPLOYER_ACCOUNT" || {
  echo "No active gcloud account is selected." >&2
  exit 1
}

gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_SA" \
  --member="user:${DEPLOYER_ACCOUNT}" \
  --role="roles/iam.serviceAccountUser" \
  --project="$PROJECT_ID"

gcloud iam service-accounts get-iam-policy "$RUNTIME_SA" \
  --project="$PROJECT_ID" \
  --format="table(bindings.role,bindings.members)"
```

Stop if the selected account is not the intended human deployer. If a reviewed
service-account deployer is introduced later, use its explicit
`serviceAccount:` member instead of changing the human-member command
silently. The cloud preflight verifies the scoped
`roles/iam.serviceAccountUser` binding and independently calls
`testIamPermissions` for `iam.serviceAccounts.actAs` before deployment.

## Stage 5 — create the cost-first Firestore control plane

First inventory existing databases:

```bash
gcloud firestore databases list \
  --project="moolsocial-dev-503018" \
  --format="table(name,type,locationId,databaseEdition,deleteProtectionState)"
```

Firestore database location is effectively an architectural commitment for
this project. If `(default)` already exists with a different location, mode,
edition or protection state, stop. Do not delete, recreate, migrate or create a
second database during this workflow.

Create exactly one default database only when `(default)` does not already
exist:

```bash
gcloud firestore databases create \
  --database="(default)" \
  --location="asia-south1" \
  --type="firestore-native" \
  --edition="standard" \
  --delete-protection \
  --project="moolsocial-dev-503018"
```

Required state:

- database ID `(default)`;
- Standard edition;
- Native mode;
- location `asia-south1`;
- delete protection enabled;
- point-in-time recovery disabled;
- no TTL policies;
- no backup schedules or retained backups; and
- no direct mobile/web client access to provider records.

The database description must explicitly report `freeTier: true`. Stop if it
does not. The free-tier flag is a deployment gate, not an assumption derived
from database order or project age.

Direct client access is denied by this exact source:

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

The source remains
`backend/firestore/youtube-private-dev.rules`, mapped by `firebase.json` and
deployed only through `firestore:rules`.

Firestore Rules do not restrict Admin SDK/server-library access. The server
uses Application Default Credentials and IAM, so the dedicated runtime
identity and its exact `roles/datastore.user` grant are the privileged access
boundary. Deny-all Rules and least-privilege IAM are both mandatory.

Do not create a named second database, Enterprise edition, Data Connect
service or Cloud SQL instance. Firestore is used only for encrypted provider
connection/control state, idempotency, quota counters and redacted audit
records. It never stores YouTube media bytes.

## Stage 6 — restricted credentials and consent

In project `moolsocial-dev-503018`:

1. create one backend-only API key restricted to YouTube Data API v3;
2. create one Web OAuth client named for MoolSocial private Dev;
3. register the exact callback:
   `https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeOAuthCallback`;
4. keep the consent app in test-user mode;
5. add only the approved Dev test users;
6. use only MoolSocial-owned support/authorized domains; and
7. request YouTube scopes incrementally from the invoking feature.

The server key cannot receive a fixed-egress-IP application restriction until
an approved fixed-egress design exists. Interim controls are backend-only
custody, YouTube-API restriction, Secret Manager, App Check, Authentication,
strict operation allow-lists, application quota caps, one-instance scaling,
redacted logs and immediate key revocation.

Set secrets through the interactive Firebase CLI so values never appear in
arguments:

```powershell
firebase login --reauth
firebase functions:secrets:set YOUTUBE_SERVER_API_KEY `
  --project moolsocial-dev-503018
firebase functions:secrets:set YOUTUBE_OAUTH_CLIENT_ID `
  --project moolsocial-dev-503018
firebase functions:secrets:set YOUTUBE_OAUTH_CLIENT_SECRET `
  --project moolsocial-dev-503018
firebase functions:secrets:set YOUTUBE_TOKEN_ENCRYPTION_KEY_V1 `
  --project moolsocial-dev-503018
firebase functions:secrets:set YOUTUBE_TOKEN_ENCRYPTION_KEY_V2 `
  --project moolsocial-dev-503018
```

Each encryption key is a distinct set of exactly 32 cryptographically random
bytes encoded as base64url. V2 encrypts new credentials; V1 remains read-only
rotation compatibility until the atomic migration audit passes.

Grant the runtime identity accessor permission on each exact secret, for
example:

```bash
gcloud secrets add-iam-policy-binding YOUTUBE_SERVER_API_KEY \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/secretmanager.secretAccessor" \
  --project="$PROJECT_ID"
```

Repeat for the other four manifest secret names. Record only resource names,
versions and policies—never secret values.

## Stage 7 — configure the sole approved Dev App Check route

The mobile client uses `AndroidPlayIntegrityProvider`. A USB-installed or
sideloaded Dev APK is not Play-licensed or `PLAY_RECOGNIZED` by default.
Physical OPPO proof is therefore blocked until the exact Dev Play Integrity
registration is configured and verified as:

```text
appIntegrity.allowUnrecognizedVersion = true
accountDetails.requireLicensed = false
deviceIntegrity.minDeviceRecognitionLevel = MEETS_DEVICE_INTEGRITY
```

This is the sole current OPPO route. The Firebase project/app must be linked
and registered correctly, the exact Dev SHA-256 fingerprint must be present,
and no App Check debug token may remain registered.

A debug-provider build/token is deferred and not implemented by this package.
Do not register one as a workaround. Do not claim OPPO readiness before the
exact advanced configuration and missing, invalid, expired and replayed-token
tests pass.

After Stages 1–7 have created and configured the reviewed prerequisites, but
immediately before the Stage 8 application deployment, run the dedicated
read-only security prerequisite from an authenticated environment that has
`gcloud`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\check-youtube-private-dev-security-prerequisites.ps1 `
  -ProjectId moolsocial-dev-503018 `
  -ServerApiKeyUid <SERVER_API_KEY_UID> `
  -AndroidAppId <FIREBASE_ANDROID_APP_ID> `
  -ExpectedSha256 <DEV_SIGNING_SHA256_WITH_COLONS> `
  -AllowNoServerIpRestriction
```

It performs no cloud mutation. It must prove the API key is backend-only and
restricted to YouTube Data API v3, the Android app/package is exact, the
off-Play Play Integrity contract is exact, the expected SHA-256 is registered
and the registered App Check debug-token count is zero. There is no
`-AllowRegisteredDebugTokens` exception.

## Stage 8 — exact disabled-by-default deployment

The non-secret runtime settings at deployment are:

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

On a workstation with authenticated Google Cloud and Firebase CLIs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\deploy-youtube-private-dev.ps1 `
  -Mode Deploy `
  -ProjectId moolsocial-dev-503018 `
  -BillingAccountId 01F9D3-44031C-B5E225 `
  -Confirmation DEPLOY_MOOLSOCIAL_PRIVATE_DEV_ONLY `
  -ServerApiKeyUid <SERVER_API_KEY_UID> `
  -AndroidAppId <FIREBASE_ANDROID_APP_ID> `
  -ExpectedSha256 <DEV_SIGNING_SHA256_WITH_COLONS> `
  -AllowNoServerIpRestriction
```

The current cost-first design has no approved fixed server egress IP, so
`-AllowNoServerIpRestriction` is an explicit temporary acceptance of the
documented compensating controls. Do not pass
`-AllowRegisteredDebugTokens`; the current OPPO route requires none.

The only deploy targets are:

- `functions:provider:youtubeProvider`;
- `functions:provider:youtubeOAuthCallback`; and
- `firestore:rules`.

No Data Connect or Cloud SQL target is permitted.

`firebaserules.googleapis.com` must be enabled. The deployed
`cloud.firestore` release must resolve to one active Ruleset source file whose
content is exactly the deny-all rule recorded in Stage 5.

The deployed Functions must remain:

- Node.js 22;
- `asia-south1`;
- `minInstances: 0`;
- `maxInstances: 1`;
- `concurrency: 1`;
- timeout 120 seconds;
- memory 512 MiB;
- exact dedicated runtime identity;
- all provider capabilities false; and
- public/unlisted upload hard-disabled.

Immediately after Function deployment, retain Functions build artifacts for
only one day:

```powershell
firebase functions:artifacts:setpolicy `
  --days 1 `
  --project moolsocial-dev-503018 `
  --location asia-south1 `
  --force
```

## Stage 9 — read-only deployed-state proof

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\verify-youtube-private-dev-deployment.ps1 `
  -ProjectId moolsocial-dev-503018 `
  -BillingAccountId 01F9D3-44031C-B5E225 `
  -ServerApiKeyUid <SERVER_API_KEY_UID> `
  -AndroidAppId <FIREBASE_ANDROID_APP_ID> `
  -ExpectedSha256 <DEV_SIGNING_SHA256_WITH_COLONS> `
  -AllowNoServerIpRestriction
```

Do not add `-AllowRegisteredDebugTokens`; registered debug tokens are not part
of the current private-Dev execution contract.

The verifier must prove:

1. exact project, organization, billing account and monthly budget;
2. every required service present and every named deferred service still
   disabled;
3. exactly one `(default)` Firestore Standard/Native database in
   `asia-south1` with `freeTier: true`;
4. delete protection on, with PITR, TTL and backups absent;
5. exact deny-all Firestore Rules by reading the active
   `cloud.firestore` release, resolving its Ruleset and comparing the returned
   source;
6. only the two named provider Functions and no extra provider-codebase
   Function;
7. exact region, scaling, concurrency, timeout, memory and runtime identity;
8. each second-generation Function's underlying Cloud Run service has exactly
   the reviewed unconditional `allUsers` `roles/run.invoker` public binding,
   no `allAuthenticatedUsers` binding, and remains application-gated by App
   Check and OAuth/Firebase Authentication as applicable;
9. the runtime identity has only required project/secret access, no broad
   owner role and zero user-managed service-account keys;
10. one-day Functions artifact cleanup;
11. every provider capability remains false;
12. the protected endpoint rejects a request without App Check with HTTP 401
    `permission_denied`; and
13. no token-backed capability or provider operation is claimed by this
    read-only verifier.

The `capability_disabled`, authenticated owner, token replay and real-provider
proofs belong to the separately supervised Stage 10 gates after the read-only
inventory passes.

Store sanitized evidence under a new
`artifacts/quality/youtube-private-dev-*` directory. Never store credentials,
authorization codes, tokens, resumable URLs or private video bytes.

## Stage 10 — supervised private proof order

Run only `scripts/activate-youtube-private-dev-proof.ps1`. It exposes four
enum-only profiles, requires a profile-specific activation phrase, and writes
a server-enforced UTC expiry no more than 30 minutes in the future. It verifies
the all-disabled state before the proof and deploys only
`youtubeProvider` and `youtubeOAuthCallback`.

Enable and prove one profile at a time:

1. Gate A — public metadata;
2. Gate B — official player on the physical OPPO, only after Stage 7;
3. Gate C — owner connection;
4. Gate D — direct private upload;
5. Gate E — owner Analytics; and
6. Gate F — disconnect, deletion and rollback.

The script's `finally` path restores all four flags to false, removes the proof
profile and expiry, redeploys only the exact two Functions, and verifies the
all-disabled state. A dead operator process is still bounded by the
server-enforced expiry. Provider proof does not authorize Screen 04 changes.

## Immediate rollback

Rollback does not depend on a mobile release:

1. restore the immutable all-false runtime baseline and remove the proof
   profile and expiry;
2. redeploy only the two exact provider Functions;
3. verify 100% of Cloud Run traffic targets the latest ready revision;
4. if disable-all redeploy or verification fails, run
   `scripts/contain-youtube-private-dev.ps1` with its unique confirmation;
5. hard containment removes only unconditional `allUsers`
   `roles/run.invoker` from the exact two reviewed Run services;
6. revoke the server API key if compromised;
7. disable or delete the OAuth client if compromised;
8. preserve the disconnect/deletion operation;
9. verify native MoolSocial Reels and Feed remain unaffected; and
10. preserve redacted incident/audit evidence.

No Staging or Production action follows automatically.

## Official references

- Firestore pricing and free quota:
  <https://firebase.google.com/docs/firestore/pricing>
- Firestore database creation command:
  <https://docs.cloud.google.com/sdk/gcloud/reference/firestore/databases/create>
- Firestore Security Rules:
  <https://firebase.google.com/docs/firestore/security/get-started>
- Firestore server IAM and Security Rules boundary:
  <https://firebase.google.com/docs/firestore/security/rules-conditions#authentication>
- Firebase Rules REST API:
  <https://firebase.google.com/docs/reference/rules/rest>
- Service-account key security:
  <https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys>
- Firebase Functions partial deployment and codebases:
  <https://firebase.google.com/docs/functions/organize-functions>
- Firebase Functions runtime and artifact management:
  <https://firebase.google.com/docs/functions/manage-functions>
- Firebase environment and Secret Manager configuration:
  <https://firebase.google.com/docs/functions/config-env>
- Google Cloud budget command:
  <https://cloud.google.com/sdk/gcloud/reference/billing/budgets/create>
- YouTube quota and compliance audits:
  <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>
- YouTube quota costs:
  <https://developers.google.com/youtube/v3/determine_quota_cost>
- YouTube revision history:
  <https://developers.google.com/youtube/v3/revision_history>
- YouTube IFrame/WebView player:
  <https://developers.google.com/youtube/terms/required-minimum-functionality>

## 24 July founder payment and Screen 04 direction update

The founder supplied a successful INR 3,000 Google Cloud payment confirmation.
Cloud Shell independently reports billing account
`01F9D3-44031C-B5E225` open and the exact Dev project linked. Do not interpret
the payment as the monthly project budget alert. The separate
founder-approved `INR 1,000` monthly alert target is now recorded in the
manifest and live in the project. It alerts but does not stop spend.

After provider proof, Screen 04 may now be materially reworked to make YouTube
a primary engagement centre. The mandatory order remains provider proof,
editable HTML revision, founder `FINAL`, immutable freeze, native Flutter
parity and physical OPPO acceptance. No Flutter presentation change is
authorized by this payment or direction alone.

## 24 July live App Check configuration checkpoint

The founder-authenticated Cloud Shell read the exact registered Android app
configuration through the Firebase App Check REST API. Before correction it
reported:

- token TTL `3600s`;
- `appIntegrity.allowUnrecognizedVersion` absent/effective false;
- `deviceIntegrity.minDeviceRecognitionLevel = NO_INTEGRITY`; and
- `accountDetails.requireLicensed` absent/effective false.

The Dev configuration was then updated through the documented
`projects.apps.playIntegrityConfig.patch` method to the approved off-Play
physical-device contract:

- token TTL remains `3600s`;
- `appIntegrity.allowUnrecognizedVersion = true`;
- `deviceIntegrity.minDeviceRecognitionLevel = MEETS_DEVICE_INTEGRITY`; and
- `accountDetails.requireLicensed` remains absent/effective false.

A separate paginated REST inventory reports `debugTokenCount=0` and no next
page. This mutation does not enable App Check enforcement, deploy a workload
or enable Secret Manager. Missing-token, invalid-token, expired-token, replay
and genuine physical-OPPO attestation proofs remain mandatory before a
provider capability is enabled.

The exact YouTube-centred presentation contract is now durable at
`docs/delivery/SCREEN-04-YOUTUBE-CENTRED-INTERACTION-CONTRACT-20260724.md`.
It permits a material HTML revision after provider proof, but still requires
the founder `FINAL` gate before a new immutable reference or Flutter change.

## 24 July local provider-contract verification checkpoint

The expanded public-catalogue and owner P1 contracts pass `116/116` backend
tests and the full private-Dev package gate. The gate also proves the exact
branch/project boundary, disabled provider capabilities, Screen 01–03 locks,
71 UTF-8 package files and local deployment-package integrity.

Sanitized evidence:
`artifacts/quality/youtube-provider-schema-validation-20260724-08/PUBLIC-OWNER-P1-VERIFICATION-EVIDENCE.md`.

This completes a local prerequisite only. The exact Stage 2 INR 1,000 monthly
alert target is complete. Remaining cloud/provider work is still gated by the
credential, security, deployment and supervised-proof stages.

The subsequent read-only Cloud Shell inventory is durable at
`artifacts/quality/youtube-private-dev-readiness-20260724-03/READ-ONLY-CLOUD-INVENTORY.md`.
It confirms the exact Dev billing link and live provider quotas, while also
confirming that Firestore, workload APIs, provider secrets and the dedicated
runtime identity are not yet provisioned. No service was enabled during that
inventory.

That readiness file is a preserved historical checkpoint. Its absent-resource
findings are superseded by the later API, runtime-identity, Firestore and
restricted-secret evidence linked above.
