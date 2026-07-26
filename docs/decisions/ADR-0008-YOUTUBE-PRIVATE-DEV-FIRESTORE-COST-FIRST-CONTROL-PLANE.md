# ADR-0008: YouTube private Dev Firestore cost-first control plane

- Status: **accepted for the private Dev YouTube proof**
- Decision date: 24 July 2026
- Environment: `moolsocial-dev-503018` only
- Region: `asia-south1`
- UI impact: none

## Context

The private YouTube provider proof needs durable OAuth attempt state,
encrypted channel credentials, connection ownership, idempotent upload
orchestration, quota reservations and redacted audit evidence.

The earlier implementation adapters included Firebase Data Connect and Cloud
SQL. Provisioning that stack for this narrow proof would introduce an
always-on relational database cost floor even though YouTube hosts and streams
the audiovisual media and the phone uploads directly to Google's resumable
upload endpoint.

The founder requires the lowest-cost compliant proof before any public
commitment. Screen 04 remains `DRAFT / HOLD`; this backend decision must not
change HTML, Flutter UI, routes, accepted references or Screens 01–03.

Cloud checkpoint recorded 24 July 2026: billing account
`01F9D3-44031C-B5E225` now reports open and is linked to only
`moolsocial-dev-503018`. This resolves the account-link prerequisite, not the
deployment gate. The founder subsequently approved, and Cloud Shell verified,
the exact `INR 1,000` monthly project-scoped alert with 50%, 80% and 100%
thresholds. It is an alert target, not a hard spending cap.

## Decision

Use one Cloud Firestore database as the active private-Dev YouTube control
plane:

- database ID: `(default)`;
- edition: Standard;
- mode: Native;
- location: `asia-south1`;
- delete protection: enabled;
- point-in-time recovery: disabled;
- TTL policies: disabled;
- backups and backup schedules: disabled; and
- client access: disabled.

Use Firestore only for:

- one-use OAuth authorization attempts;
- encrypted provider credentials and their compare-and-swap key migration;
- active YouTube channel connections;
- resumable-upload orchestration metadata and idempotency state;
- atomic search/upload/batch-stats/general quota reservations; and
- append-only redacted provider audit events.

Direct mobile and web access is denied by the exact deployed Rules source:

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

The source authority is
`backend/firestore/youtube-private-dev.rules`, referenced by `firebase.json`.
The deployment target is exactly `firestore:rules`. Enabling
`firebaserules.googleapis.com` is a prerequisite for publishing and verifying
this release.

Firestore Rules do not authorize or deny server Admin SDK calls. Firebase
server libraries use Application Default Credentials and IAM and bypass
Firestore Security Rules. The dedicated runtime identity therefore remains
the only application server principal, with `roles/datastore.user` as the
Firestore data boundary. Deny-all Rules protect untrusted mobile/web clients;
least-privilege IAM protects privileged server access. Neither control
substitutes for the other.

The existing Data Connect/Cloud SQL adapters are preserved and deferred. They
remain available for future relational commerce, order, settlement and
workspace domains, but are not deployed, enabled or provisioned by this
private YouTube proof.

## Media boundary

- YouTube hosts and streams every YouTube audiovisual byte.
- Official embedded playback is provider-served; MoolSocial does not pay a
  MoolSocial storage/CDN bill for those YouTube media bytes.
- For private creator proof, the device sends media directly to the Google
  resumable-upload URL. Functions and Firestore do not receive the media body.
- MoolSocial stores only the minimum encrypted connection and orchestration
  records.
- No MoolSocial-native long-form video storage is part of MVP.
- Native MoolSocial Reel video storage is also outside this private proof and
  remains disabled until a separate media architecture, payer, budget,
  retention policy and founder approval exist.

## Cost boundary

YouTube API calls are quota-governed rather than an ordinary per-watch or
per-upload media charge. The selected design removes a Cloud SQL always-on
instance from the private-Dev cost floor.

Firestore's published free quota may absorb a small controlled proof, but it
is a capacity boundary and not a zero-cost guarantee. Operations, stored data,
network, Functions, build artifacts, Secret Manager, logging, App Check and
support can become chargeable when their included allowances are exceeded.

Private Dev therefore keeps:

- all four provider capability flags false at initial deployment;
- search/upload/batch-stats/general application caps at or below
  `20/10/500/2000` per day;
- Functions at `minInstances: 0`, `maxInstances: 1`, `concurrency: 1`;
- Functions artifact retention at one day;
- a founder-approved exact project-scoped monthly budget before deployment;
- no PITR, TTL, backups, clone or restore operations; and
- immediate per-capability disable and credential-revocation paths.

Provider quota posture current through 24 July 2026:

- `search.list`: separate default bucket of 100 calls/day/project;
- `videos.insert`: separate default bucket of 100 uploads/day/project;
- `videos.batchGetStats`: separate default bucket of 10,000 calls/day/project;
- other Data API methods: shared default 10,000 units/day/project; and
- MoolSocial Dev application caps remain the stricter
  `20/10/500/2000` for search/upload/batch-stats/general respectively.

These are capacity allocations, not purchased media-delivery units. YouTube
serves official embedded playback without a MoolSocial video-egress charge,
while MoolSocial still pays its own backend/control-plane usage after
applicable allowances.

## Runtime and authorization boundary

Deploy only:

- `functions:provider:youtubeProvider`; and
- `functions:provider:youtubeOAuthCallback`;
- plus the exact deny-all `firestore:rules` target that protects direct client
  access to the server-only control plane.

Both Functions run as:

`youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`

The identity receives only:

- project `roles/datastore.user`;
- project `roles/firebaseappcheck.tokenVerifier`; and
- `roles/secretmanager.secretAccessor` on each exact provider secret.

It must not receive Owner, Editor, Datastore Owner, Secret Manager
administrator or unrelated service-agent roles.

The runtime identity is keyless. It must have zero `USER_MANAGED`
service-account keys. Functions use the attached runtime identity and
Google-managed credentials; no service-account JSON key is created, copied to
Flutter, placed in Secret Manager or stored in repository evidence.

Firebase Authentication is required for owner operations. App Check is
required for deployed calls, with limited-use token replay protection on
sensitive owner operations.

## Physical OPPO proof condition

The Flutter Dev client uses `AndroidPlayIntegrityProvider`. A USB-installed or
sideloaded APK is not Play-licensed or `PLAY_RECOGNIZED` by default.

Physical OPPO readiness therefore requires the sole current off-Play Dev
configuration:

- `appIntegrity.allowUnrecognizedVersion = true`;
- `accountDetails.requireLicensed = false`; and
- `deviceIntegrity.minDeviceRecognitionLevel = MEETS_DEVICE_INTEGRITY`.

The expected Dev SHA-256 certificate must be registered and no App Check debug
token may remain. A debug-provider build/token is deferred and not implemented
by this package.

There is no debug-token exception in the current deployment package. The
security prerequisite and deployed-state verifier must both prove the
registered debug-token inventory is empty.

Certificate registration alone is not OPPO acceptance evidence.

## Consequences

### Positive

- no Cloud SQL always-on instance for the private provider proof;
- provider media never traverses MoolSocial storage or Functions;
- atomic Firestore transactions satisfy connection, idempotency, quota and
  audit invariants;
- the provider can remain completely disabled while deployment identity,
  secrets and cost controls are verified; and
- the relational adapters remain available for domains that genuinely require
  them.

### Trade-offs

- Firestore usage is metered after free quota;
- transactional document design requires strict server-only collection and
  index discipline;
- retention without TTL requires explicit bounded administrative cleanup; and
- Firestore is not approved as the system of record for commerce, stock,
  checkout, settlement or payout ledgers.

## Deployment gate

Before a live private-Dev deployment:

1. the already-open authorized billing account remains linked only to
   `moolsocial-dev-503018`;
2. the exact founder-approved `INR 1,000` monthly alert remains the sole
   project-scoped budget for project `760290687711`, with 50%, 80% and 100%
   thresholds and explicit non-cap treatment;
3. `firebaserules.googleapis.com` is enabled with the reviewed workload
   services;
4. one `(default)` Standard/Native `asia-south1` database exists, reports
   `freeTier: true`, has delete protection and has no PITR, TTL, backup or
   backup-schedule feature;
5. the read-only
   `scripts/check-youtube-private-dev-security-prerequisites.ps1` gate passes
   before deployment mutation, including restricted server-key, Android app,
   Play Integrity, SHA-256 and zero-debug-token checks;
6. Data Connect and Cloud SQL Admin remain disabled;
7. the keyless dedicated runtime identity has only the approved roles and zero
   user-managed keys;
8. the five secrets exist and grant accessor only to the runtime identity;
9. the exact three targets deploy:
   `functions:provider:youtubeProvider`,
   `functions:provider:youtubeOAuthCallback` and `firestore:rules`;
10. the active `cloud.firestore` release resolves to a Ruleset whose one source
    file is byte-for-byte the deny-all rule above;
11. both Functions remain disabled by capability flags and one-day artifact
    cleanup is active; and
12. the read-only verifier proves the deployed inventory before a capability
    is enabled.

The workspace now contains a portable Google Cloud SDK. Every local invocation
must use the repository-scoped isolated configuration for
`moolsocial-dev-503018`; the machine-default Google configuration is unrelated
and forbidden. The isolated configuration currently has no active account, so
Google Cloud Shell remains the authenticated Cloud inventory/administration
surface. A local deployment or cloud-verification claim is forbidden until
that isolated configuration is freshly authenticated and the exact read-only
gates pass.

## Revisit conditions

Revisit this decision only when measured Preview evidence proves one of:

- the Firestore control-plane cost or transaction model is unsuitable;
- a relational invariant cannot be preserved safely;
- provider audit or legal retention requires a different durable store; or
- a later production domain needs the deferred relational architecture.

Any change requires a new ADR, cost comparison, migration/rollback evidence
and explicit founder authorization. It does not authorize changing Screen 04.

## Official references

- Firestore pricing and free quota:
  <https://firebase.google.com/docs/firestore/pricing>
- Firestore database creation:
  <https://docs.cloud.google.com/sdk/gcloud/reference/firestore/databases/create>
- Firestore Security Rules deployment:
  <https://firebase.google.com/docs/firestore/security/get-started>
- Firestore server IAM and Security Rules boundary:
  <https://firebase.google.com/docs/firestore/security/rules-conditions#authentication>
- Firebase Rules REST API:
  <https://firebase.google.com/docs/reference/rules/rest>
- Service-account key security:
  <https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys>
- YouTube IFrame Player API:
  <https://developers.google.com/youtube/iframe_api_reference>
- YouTube quota costs:
  <https://developers.google.com/youtube/v3/determine_quota_cost>
- YouTube Data API revision history:
  <https://developers.google.com/youtube/v3/revision_history>
- YouTube developer policies:
  <https://developers.google.com/youtube/terms/developer-policies>
- YouTube quota and compliance audits:
  <https://developers.google.com/youtube/v3/guides/quota_and_compliance_audits>
