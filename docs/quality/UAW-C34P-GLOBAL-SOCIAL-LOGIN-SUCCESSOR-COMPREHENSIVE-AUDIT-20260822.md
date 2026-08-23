# UAW-C34P global-social-login successor comprehensive audit

Date: 22 August 2026

State: confirmed findings; exact repair ticket required before implementation

## Authority and preserved evidence

This primary-owned audit resumes the founder-directed comprehensive phase. The
stopped Cursor and audit subagents remain stopped. R60.77 through R60.80,
their APKs, screenshots, logs and rejection evidence remain immutable.

The required sequence is audit, regression registration, one exact ticket,
smallest root-cause implementation, two clean source cycles, cold-start and
post-build plugin-integrity preflight, one gated sideload successor, then OPPO
global-social-login and post-login regression. No new candidate, build,
install, provider login, email/SMS, Play or SQL Connect action is authorized by
this audit.

## Confirmed findings

### AUDIT-01 — live social authentication is unreachable in the sideload profile

`MOOLSOCIAL_DEVICE_REVIEW=true` and
`MOOLSOCIAL_SIDELOAD_PREFLIGHT_ENABLED=true` are required by the current APK
machine state. In that exact branch, `main.dart` constructs
`ReviewSocialAuthGateway` with only a response delay. Its default result is
cancelled, it does not implement `SocialAuthCallbackGateway`, and it does not
use the configured Firebase, Google, X, Instagram or Facebook adapters.

Therefore the preserved sideload candidate can exercise login UI and bounded
cancellation only. It cannot authenticate a provider, complete X/Instagram
foreground or cold-start callbacks, or prove a Firebase-backed session.

### AUDIT-02 — public-auth App Check is not activated

The X and Instagram adapters request a limited-use App Check token before the
broker call. Startup activates Play Integrity App Check only when
`MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF` is true. That define is absent from the
public-auth sideload machine state, so a corrected live gateway would still
fail before X/Instagram broker completion.

### AUDIT-03 — device-review availability is not production truth

The same branch passes `null` for `availableSocialAuthProviders`, which makes
`JourneySession` expose every provider, including founder-held Apple. It also
forces review availability for Mobile OTP despite the machine state's false
attestation qualification. This contradicts the sideload qualification's
truthful unavailable-method boundary.

### AUDIT-04 — post-login completion is split between a fake and held SQL Connect

Successful authentication always calls `AccountBootstrapGateway` before the
session becomes ready. Device review uses `ReviewAccountBootstrapGateway`,
which does not prove a Firebase-backed retained session. The live branch uses
`DataConnectAccountBootstrapGateway`, but SQL Connect provisioning and
migration are founder-held until the complete application database map.

There is no current runtime composition that simultaneously provides real
provider authentication, truthful provider availability, Play Integrity App
Check, a non-provisional shared authentication-session check and retained
post-login readiness without SQL Connect.

## Existing protections that remain valid

- A named Flutter-owned frame precedes Firebase bootstrap.
- Firebase initialization and each pre-app stage are bounded and fail closed.
- Foreground route-information handling and cold-start route parsing share the
  same session callback owner.
- X/Instagram timeout, expiry, provider-error and bounded-body protections are
  locally qualified.
- Facebook native outcome classification and rollback are locally qualified.
- The post-build APK gate requires the production plugin registrant and
  Firebase Core while forbidding `integration_test`.

These passes do not close the four production-composition findings above.

## Required repair boundary

Create one explicit live global-social-login audit mode that is allowed only
for the exact Dev sideload profile. It must reuse the real Firebase social-auth
gateway and configured provider adapters, activate Dev Play Integrity App
Check, expose only production-qualified providers, and complete post-login
through a shared Firebase-authenticated-session verifier that creates no
provisional business-domain schema. SQL Connect remains absent and held.

The repair must add main-composition, cold/foreground callback, provider
availability, App Check activation, account completion, rollback, relaunch and
negative runtime-mode tests before a successor candidate can be selected.
