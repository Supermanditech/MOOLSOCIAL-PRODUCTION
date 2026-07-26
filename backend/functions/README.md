# Privileged functions

This codebase owns provider calls and asynchronous commands that must never run
inside Flutter. The private-Dev YouTube control plane uses privileged,
server-only Cloud Firestore access. Firebase Data Connect and Cloud SQL remain
preserved and deferred for later relational product domains.

## YouTube private Dev boundary

The YouTube provider is intentionally disabled until environment flags and
Secret Manager values are configured in `moolsocial-dev-503018`.

Implemented server boundaries:

- public, embeddable video metadata from documented YouTube Data API methods;
- explicit search only, guarded by a separate daily hard cap;
- Google Authorization Code with PKCE and incremental YouTube scopes;
- encrypted refresh-token storage in privileged Firestore provider documents;
- process-memory-only access tokens;
- private-only resumable upload initialization;
- direct client-to-YouTube video transfer, with no video bytes proxied or stored
  by MoolSocial Functions;
- owner upload inventory, subscriptions and playlists through readonly
  `mine=true` operations with exact connected-channel attribution;
- server-controlled owner YouTube Analytics presets only (`overview`,
  `topVideos`, `countries`, `trafficSources`, `devicesOs` and
  ownership-validated `videoRetention`);
- 30-day connected-channel revalidation before stale owner work;
- encrypted resumable-session storage, idempotent publication jobs, App Check,
  Firebase Auth for owner actions, redacted logs and atomic quota reservations;
- canonical upload request fingerprints, expiring creation leases and
  resumable-session expiry;
- atomic publication writes conditional on the ACTIVE YouTube connection; and
- OAuth credential compensation if connection persistence fails.

Public or unlisted API upload is not enabled. Projects created after
28 July 2020 remain private-only until YouTube confirms a successful compliance
audit.

## Local verification

```powershell
npm ci
npm run verify
```

The local provider environment defaults to every capability disabled and uses
conservative caps:

- 20 explicit searches per Pacific day;
- 10 upload initializations per Pacific day;
- 500 `videos.batchGetStats` calls per Pacific day;
- 100 YouTube Analytics queries per Pacific day; and
- 2,000 general YouTube Data API units per Pacific day.

These are internal safety caps below the provider allocation. They are not
claims about approved production quota.

The analytics bucket is currently one atomic project-wide Pacific-day ledger.
Per-user daily and minute-burst limits are deferred until the quota store can
reserve project, pseudonymous-user and minute windows in one Firestore
transaction. Do not emulate those limits with sequential reservations because
partial quota burns would make the control non-atomic and unfair.

Current verification:

- backend TypeScript and deterministic tests: 153/153 passed;
- targeted Flutter platform, embedded-player runtime and non-UI private-Dev
  client tests: 52/52 passed;
- deferred Data Connect schema/connector generation: passed; it is not the
  private-Dev YouTube runtime store.

The independently rerun public-catalogue and owner P1 evidence is at
`../../artifacts/quality/youtube-provider-schema-validation-20260724-08/PUBLIC-OWNER-P1-VERIFICATION-EVIDENCE.md`.

Execution authority:

`../../docs/delivery/YOUTUBE-PRIVATE-DEV-INTEGRATION-RUNBOOK-20260723.md`

## Secrets

Configure through Firebase or Google Secret Manager only:

- `YOUTUBE_SERVER_API_KEY`
- `YOUTUBE_OAUTH_CLIENT_ID`
- `YOUTUBE_OAUTH_CLIENT_SECRET`
- `YOUTUBE_TOKEN_ENCRYPTION_KEY_V1`
- `YOUTUBE_TOKEN_ENCRYPTION_KEY_V2`

`YOUTUBE_TOKEN_ENCRYPTION_KEY_V1` is 32 random bytes encoded as base64url.
The OAuth client is a confidential web-server client. Its exact HTTPS redirect
URI is supplied by the non-secret `YOUTUBE_OAUTH_REDIRECT_URI` environment
setting and must match Google Cloud exactly. The client secret remains only in
Secret Manager and never enters Flutter. Never put secret values, OAuth codes,
tokens, authorization headers or resumable session URLs in source, `.env`
files, tickets, screenshots or logs.

The current Functions construction binds all five secrets even when public
data is the only enabled capability. Therefore every named secret resource and
value must exist before the first live deployment. Do not weaken this
fail-closed behavior by inserting placeholders.

## Capability flags

- `YOUTUBE_PUBLIC_DATA_ENABLED`
- `YOUTUBE_OWNER_CONNECT_ENABLED`
- `YOUTUBE_PRIVATE_UPLOAD_ENABLED`
- `YOUTUBE_OWNER_ANALYTICS_ENABLED`

Each flag can be disabled independently. `MOOLSOCIAL_PROVIDER_ENV=dev` removes
the local emulator App Check bypass.

Screen 04 and Flutter presentation are deliberately outside this codebase. A
compile-time-gated non-UI proof client exists under
`apps/mobile/lib/core/youtube/`; it activates only for the exact Dev project
and endpoint. Provider proof must be observed before approved UI contracts are
changed.

## Promotion gate

Local verification proves contracts and failure behavior; it does not prove a
live Google integration. Private Dev is complete only after all of the
following have evidence against `moolsocial-dev-503018`:

1. restricted server API key and OAuth client inventory;
2. Secret Manager custody with no value copied into source or logs;
3. deployed fail-closed capability response;
4. public metadata and official-player handoff;
5. consenting owner OAuth with the exact incremental scope;
6. one private resumable upload sent directly from the proof client to
   YouTube;
7. processing reconciliation and owner-authorized Analytics;
8. disconnect, provider revocation and retained-data deletion;
9. independent quota and feature-flag stop tests; and
10. redacted evidence suitable for the YouTube API compliance audit.

Until that checklist passes, keep all capability flags disabled outside an
explicitly supervised Dev proof and do not connect Flutter presentation.
