# UAW-C34P blocker-resolution robustness and reuse assessment

Date: 18 August 2026 (IST)
Ticket: `UAW-C34P-FIX1-PUBLIC-AUTH-LIVE-ADAPTER-BLOCKER-RESOLUTION`
Classification: `beyond_mvp`
State: selected parent assessment for runtime, platform, backend and local-test
source execution

## Customer outcome and authority

A signed-out Personal user can use X or Facebook from the existing shared
MoolSocial login gateway, privately complete the provider handoff, establish one
Firebase-backed MoolSocial session and return to the exact protected
destination, or recover truthfully while incomplete configuration remains
disabled.

The work remains `beyond_mvp` because X and Facebook are optional provider
expansions. The founder explicitly resumed all C34P fixes, pending tickets and
blocker resolution on 18 August 2026. The authorization permits runtime,
platform-configuration, backend, test and gate source only; external/provider,
private, build, Play and OPPO actions remain separately held.

## Reuse inventory and duplicate search

- Reuse Screen 03 v5, `/sign-in`, `/verify`, `MoolSocialApp`,
  `JourneySession`, the current provider availability contract and one
  `FirebaseSocialAuthGateway`.
- Reuse Firebase Auth, Firebase App Check, account bootstrap/rollback,
  authenticated relaunch, sign-out and protected-return owners.
- Reuse the existing `MOOLSOCIAL_AUTH_API_BASE_URL` runtime boundary for the X
  broker; do not create a second mobile backend base URL.
- Reuse the existing `backend/functions` package, Firebase Admin application,
  App Check verification and region/runtime conventions. No second Functions
  package or authentication server is permitted.
- Reuse the qualified pure X PKCE owner for S256, scopes, exact callback,
  attempt outcomes and revocation request rules.
- Reuse the qualified pure Facebook contract for package/activity/key-hash
  readiness, exact redirect, minimum permissions, outcomes and account-control
  requests.
- Duplicate searches found no production X broker, X mobile network adapter or
  Facebook native SDK adapter. Those are new necessary trust-boundary owners,
  not duplicate UI or business services.

## Smallest complete topology

Implementation dispositions are `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance` and `new_necessary_work`.

New necessary work is limited to:

1. one `backend/functions/src/auth` X broker/service plus tests and one thin
   export inside the existing Functions `index.ts`;
2. one mobile X broker/browser adapter plus callback delivery through the
   existing app/session lifecycle and exact Android/iOS link configuration;
3. one Facebook native SDK adapter plus package-managed dependency and
   environment-backed Android/iOS platform configuration; and
4. one successor static/configuration gate and focused test owners.

No new screen, Flutter route, JourneySession, Firebase project, provider app or
parallel backend package is necessary. The broker retains a short-lived one-time
PKCE attempt server-side so foreground and cold callbacks share one truth. It
exchanges the X code as a public client, verifies the transient provider subject,
derives a non-reversible project-scoped Firebase UID, mints a custom token and
revokes the X access token before returning. It never stores the provider token
or requests `offline.access`.

Facebook uses the supported native SDK only. Real app identifiers, client
tokens and key hashes remain founder-controlled build/provider inputs and are
never committed. The adapter stays unreachable unless every exact configuration
fact is qualified.

## Robustness and privacy coverage

- App Check protects unauthenticated broker begin/complete operations and body
  size, method, content type and runtime schemas fail closed.
- X attempts are one-time, expiring, exact-redirect and exact-state; duplicate,
  wrong-state, wrong-redirect, denial, cancellation, timeout and provider error
  paths remain distinguishable and sanitized.
- X uses only `tweet.read` and `users.read`; access tokens are memory-only and
  always revoked after identity proof or terminal failure cleanup.
- Provider subjects are never logged, returned or stored raw. Firebase UIDs use
  a secret-keyed non-reversible projection and custom-token issuance remains
  keyless through Firebase Admin.
- Facebook requests exactly `public_profile`; email and every unrelated
  permission remain absent by default and test-gated.
- Native/provider/Firebase errors are enumerated; provider-authored messages,
  account data and tokens cannot reach UI, logs, exceptions or evidence.
- Account bootstrap failure rolls back Firebase/provider state while exact
  protected return remains retryable.
- Missing, placeholder, mismatched or partially qualified configuration keeps
  the Screen 03 control disabled and prevents gateway dispatch.
- Locked Screen 03 presentation and all accepted references remain untouched.

## Exclusions, dependencies and timeline

Excluded: provider-console creation/configuration, paid X credits, real Meta
values, secrets or private account data, real provider login, email/SMS, build,
Play, OPPO, commit, push, merge and rejected-candidate reuse.

Dependencies: founder-owned X/Meta apps and exact provider values; an approved
keyless Functions runtime with Firestore/Auth/App Check permissions; later
external readback; and a separately authorized release candidate with
founder-only private actions.

The work adds zero routes and zero screens, reuses the current backend package,
and adds one necessary backend trust-boundary family. Estimated engineering
impact is two calendar days within the 60–75-day lock. Provider review, paid
credits and store/device timing are external and remain reported separately.

## Test plan

Run strict backend typecheck/build/unit tests, mobile format/analyzer/unit/widget
tests, Android/iOS configuration static tests, dual-host PowerShell gates, App
Check/PKCE/replay/redaction fixtures, X/Facebook exact-return and bootstrap
rollback tests, approved UI locks and two identical affected authentication
regression cycles. No live provider or private journey is automated by Codex.
