# MoolSocial environment and promotion boundary

Status: **founder-locked**

Decision date: 21 July 2026

This document is mandatory reading before any Google Cloud, Firebase, API,
authentication, maps, distribution or environment action. It governs Codex in
Android Studio and every other Codex surface.

## Permanent environment order

### 1. Local Firebase emulators

- Remain the zero-cost first testing boundary.
- Run component, screenwise, failure, retry and destructive integration tests
  here before any real-service deployment.
- Emulator identities and data are never staging or production evidence.

### 2. Dev / real-service Trial

- Google/Firebase project ID: `moolsocial-dev-503018`.
- This is the separate real-service Trial environment.
- It may contain disposable test users and test data only.
- Use strict API-key restrictions, least-privilege identities, quotas, budget
  alerts and journey kill switches.
- Never copy production users, credentials, payments or business records here.

### 3. Screenwise Preview

- Preview is a Firebase App Distribution tester group inside the Dev project.
- It is a distribution channel, not a fourth backend environment.
- Each preview build records branch, commit, dirty state, candidate ID, APK
  checksum and the exact enabled journey.
- Screenwise Preview may exercise only the approved test slice. A pass here
  does not authorize staging promotion.

### 4. Clean Staging

- Google/Firebase project ID: `moolsocial-staging-503018`.
- Staging receives only promoted candidates that have passed emulator,
  Trial/Preview, affected-journey and required regression gates.
- Do not use staging for API experiments, manual schema trials, disposable
  prototypes or partial UI combinations.
- Staging data, identities, keys, quotas, alerts and App Check configuration
  remain isolated from Dev and Production.

### 5. Production

- The production project is created later.
- Production is never used for experimentation, Trial, Preview or unfinished
  screenwise testing.
- Its final globally unique project ID is recorded before creation and cannot
  be inferred, guessed or silently substituted.
- Production provisioning requires the applicable staging acceptance and a
  separate explicit founder action.

## Promotion rule

The order is:

`emulators → Dev/Trial → Dev App Distribution Preview → clean Staging → Production`

Promotion moves the same identified candidate and versioned contracts forward.
It does not rebuild different source, switch an installed client at runtime or
copy Dev data into Staging. Every non-emulator client is compile-time bound to
one environment and fails closed when its protected configuration is missing.

Before promotion:

1. record the source branch, commit, dirty state and artifact checksum;
2. pass the exact screen/journey and every nested tap in scope;
3. replay invalid, denied, cancelled, offline, timeout, retry and interruption
   conditions owned by that journey;
4. run affected regressions and the release-gate regression count;
5. verify API restrictions, quotas, budgets, alerts and rollback controls;
6. verify that the destination environment contains no unapproved manual
   experiment;
7. obtain the required founder acceptance.

## API enablement rule

Do not enable APIs merely because they appear free or useful. Every enabled API
must have:

- an approved journey owner;
- an environment-specific credential;
- Android/iOS/application restrictions where supported;
- least-privilege IAM;
- quota and cost guardrails;
- failure, denial and retry behavior;
- a disable/rollback path;
- retained verification evidence.

Google identity for sign-in does not by itself authorize YouTube Data access.
Maps, Places, geocoding, routes, Cloud SQL, Storage and other chargeable
services are enabled only when their owning vertical reaches the applicable
environment gate.

## Current provisioning checkpoint

Observed on 21 July 2026:

- Firebase CLI reauthentication succeeded.
- The Google Cloud billing account exists.
- Google Cloud reported that the completed free-trial prepayment may require up
  to 24 hours to be credited; live billing status must be rechecked before a
  billable API or service is attached.
- The authoritative MoolSocial organisation ID is `1067591230270`. Do not copy,
  infer or silently substitute this identifier; an earlier transposed value
  (`1067591730370`) caused a false permission/organisation failure.
- Organisation IAM directly grants the MoolSocial admin principal both
  Organisation Administrator and Project Creator. The `moolsocial.com` domain
  also retains its default Project Creator and Billing Account Creator grants.
- Google Cloud project `moolsocial-dev-503018` was created inside the
  `moolsocial.com` organisation with display name `MoolSocial Dev Trial`.
- Firebase was added to that project through the Firebase console after the
  immediate CLI add-Firebase request returned `403 PERMISSION_DENIED`.
  Firebase's documented causes for that response include missing required
  permissions or an account that has not yet accepted the Firebase Terms.
  Project IAM independently verified the admin principal as project Owner
  before console completion.
- Firebase CLI independently reports the Dev/Trial project as `ACTIVE`, with
  project number `760290687711`.
- Adding Firebase automatically provisions a Browser API key. Firebase
  documents that it is auto-restricted to Firebase-related APIs, but its
  application restrictions remain an explicit pre-registration audit item; do
  not assume that product-level API restrictions are sufficient for Android or
  iOS client safety.
- `moolsocial-staging-503018` has not been created. No Production Firebase
  project has been created.
- No billing account has been attached to Dev/Trial in this checkpoint, and no
  billable Maps, Places, Routes or other API is authorized by project creation.

Do not work around the organisation boundary by creating an unmanaged project.
Before app registration, Authentication provider enablement, App Distribution
setup or API enablement, verify the owning journey, credential restrictions and
the applicable action-time confirmation. Preserve the CLI and console evidence
in:

`artifacts/quality/cloud-environment-bootstrap-20260721/CLOUD-ENVIRONMENT-BOOTSTRAP-EVIDENCE.md`
