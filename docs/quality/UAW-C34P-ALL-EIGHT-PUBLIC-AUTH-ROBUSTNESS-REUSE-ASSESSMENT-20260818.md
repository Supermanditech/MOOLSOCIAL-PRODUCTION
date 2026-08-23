# UAW-C34P all-eight public-authentication robustness and reuse assessment

Date: 18 August 2026 (IST)
Ticket: `UAW-C34P-FIX1A-ALL-EIGHT-PUBLIC-AUTH-LIVE-ADAPTER-BLOCKER-RESOLUTION`
Classification: `beyond_mvp`
State: founder-corrected successor assessment for runtime, platform, backend
and local-test source execution

## Corrected customer outcome

A signed-out Personal user can use the exact eight-method shared gateway:
Google, YouTube through the same Google identity, Apple, X, eligible Instagram
professional login, Facebook, passwordless Email Link or Mobile OTP. Each
qualified method establishes one Firebase-backed MoolSocial session to the exact
protected destination or returns a truthful sanitized recovery.

The repeated Facebook word in the founder correction remains one Facebook
control. Instagram eligibility is provider-truthful: unsupported personal
Instagram accounts do not receive a fabricated success.

## Reuse and duplicate inventory

- Reuse locked Screen 03 v5 and its existing eight visible controls; no UI,
  reference, golden, route or customer-copy change is needed.
- Reuse `/sign-in`, `/verify`, `MoolSocialApp`, `JourneySession`, one
  `FirebaseSocialAuthGateway`, account bootstrap/rollback, exact return,
  relaunch and sign-out.
- Reuse the already qualified Google/YouTube shared identity, passwordless
  Email Link and Mobile OTP owners and their regression suites.
- Reuse Firebase's supported `AppleAuthProvider`; Apple needs configuration and
  availability hardening, not a new auth backend.
- Reuse the C34P X PKCE and Facebook minimum-permission contracts.
- Reuse one `MOOLSOCIAL_AUTH_API_BASE_URL`, one existing
  `backend/functions` package, its Firebase Admin initialization and App Check
  verification conventions for both X and Instagram privileged exchanges.
- Duplicate searches found no existing X/Instagram public-login broker, X or
  Instagram mobile broker adapter, or Facebook native SDK adapter. These are
  necessary trust-boundary adapters; they do not duplicate screens, routes,
  sessions or backend packages.

## Smallest complete topology

Implementation dispositions are `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance` and `new_necessary_work`.

New necessary work is limited to:

1. one public-auth broker family inside the existing Functions package, with
   separate X and Instagram operations and shared App Check, attempt,
   redaction, Firebase-token and subject-projection primitives;
2. thin X and Instagram mobile broker/browser adapters using the existing
   app/session callback lifecycle;
3. one Facebook native SDK adapter and environment-backed Android/iOS
   configuration;
4. Apple availability/configuration and sanitized Firebase provider coverage;
   and
5. focused tests plus one successor static gate.

No new screen, Flutter route, JourneySession, Firebase project or provider app
is created. The previous two-provider FIX1 ticket remains preserved as a
superseded planning predecessor; FIX1A is the versioned founder correction and
does not mutate that selected manifest.

## Robustness, privacy and recovery

- Google and YouTube remain two controls with one Google credential/session.
- Apple uses Firebase's supported provider path and is disabled without exact
  Apple/Firebase configuration; private keys and tokens remain external.
- X keeps OAuth 2.0 PKCE, exact redirect/state, `tweet.read` + `users.read`, no
  `offline.access`, server-retained one-time attempt, custom Firebase token and
  immediate transient provider-token revocation.
- Instagram uses exact state/redirect and `instagram_business_basic` only for
  an eligible professional account; no content, message, comment, insight, ad
  or publishing permissions are authorized.
- Facebook requests `public_profile` only and uses the native SDK plus Firebase
  credential; email and unrelated permissions stay absent.
- App Check protects unauthenticated broker operations. Methods, body limits,
  content types, request/response schemas, attempt cardinality and expiry fail
  closed.
- Provider subjects are transformed through a secret-keyed non-reversible
  project-scoped identity; raw subjects, provider tokens, codes, state,
  verifiers and Firebase custom tokens are not logged or persisted in mobile
  or evidence.
- Missing, placeholder, partial or mismatched configuration disables the exact
  provider control before dispatch.
- Provider/Firebase/network/collision/cancel/denial/ineligible/unknown errors
  map to sanitized enumerated outcomes; provider-authored messages never reach
  customer copy.
- Bootstrap failure rolls back partial identity while the exact protected
  destination remains retryable.
- Screen 03 presentation and accepted references remain immutable.

## Exclusions, dependencies and timeline

Excluded: fake Instagram personal login, Facebook-as-Instagram, duplicate
auth owners, X OAuth 1, numeric email OTP, provider content capabilities,
committed real provider values or private data, console/external writes, real
authentication, email/SMS, funds, build, Play, OPPO, commit, push and merge.

Dependencies: founder-owned Google/Apple/X/Meta/Instagram provider
configuration; keyless Firebase Admin plus App Check/Auth/Firestore runtime;
later provider readback; and a separately authorized release/device/private
acceptance phase.

The shared wave adds zero routes, zero screens and one necessary backend
trust-boundary family inside the existing package. Estimated engineering impact
is three calendar days and remains within the 60–75-day lock. Provider review,
paid credits and store/device timing remain external and are reported
separately.

## Test plan

Run strict backend typecheck/build/unit suites, mobile format/analyzer/unit/
widget suites, Android/iOS configuration static tests, dual-host PowerShell
gates, all eight provider availability/dispatch/error/revocation matrices,
cold/foreground/process-death/rollback/exact-return tests, approved UI locks and
two identical affected authentication regression cycles. No live provider or
private journey is automated by Codex.
