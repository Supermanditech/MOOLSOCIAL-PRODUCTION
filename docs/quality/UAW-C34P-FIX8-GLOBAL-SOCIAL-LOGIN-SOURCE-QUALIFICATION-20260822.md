# UAW-C34P FIX8 global-social-login source qualification

Date: 22 August 2026

State: original r60.81 source qualification preserved; r60.82 Google repair
locally qualified; successor build, install, private login and external
submission held

## Outcome

The comprehensive audit findings REG3137–REG3140 are repaired at the source
boundary. The exact Dev global-social-login audit mode now selects the real
Firebase provider gateway, activates Dev Play Integrity App Check, consumes the
production-qualified provider set and verifies one real Firebase session before
ready state without provisioning SQL Connect or creating business-domain data.

R60.77 through R60.80 remain immutable rejected/superseded evidence. No APK or
AAB was built, no OPPO package changed, no provider account opened, no email or
SMS sent, no Play action occurred and no YouTube API-team form was submitted.

## Implementation

- Added fail-closed `MOOLSOCIAL_GLOBAL_SOCIAL_LOGIN_AUDIT` runtime policy.
- Added a pure composition resolver separating ordinary review from live Dev
  social-auth audit behavior.
- Reused `FirebaseSocialAuthGateway` and existing Google, X, Instagram and
  Facebook adapters in the live audit lane.
- Activated the existing Dev Play Integrity App Check provider for that lane.
- Applied the production provider-availability contract; Apple and unattested
  Mobile OTP remain held.
- Added `FirebaseAuthenticatedSessionBootstrapGateway`, which reloads and
  verifies the Firebase session/token and creates no SQL or business record.
- Added exact runtime-define propagation and future APK allowlist support.
- Added focused composition, App Check, success, missing-session, sanitized
  failure, rollback and authenticated-relaunch tests.

## Frozen source identity

- Registry generation: 3121
- Registry SHA-256:
  `33A9BDDF320805DE5A19C2D4E358D1ECA96FDFF961D15D30FA083F9263D519B7`
- Stable executable/test/build-control source owner count: 13
- Source aggregate SHA-256:
  `DC284B6DDF6E792A0A72859BFDE99C3406D78CC5E158B3920872568F3F66C1B4`

Living ticket, MVP state, regression registry, qualification evidence and the
FIX5 lifecycle gate that records this aggregate are validated separately and
intentionally excluded to avoid a self-referential fingerprint.

## Qualification

Two identical clean cycles each passed:

- exact Dart format no-change gate;
- whole-mobile analyzer with no issues;
- 24 affected suites, 255/255 authored tests, zero failures/skips;
- backend strict typecheck and clean build;
- complete backend 586/586 through a bounded dot reporter;
- approved UI locks;
- shared C34P, FIX1A, FIX5 and FIX6 gates;
- public-auth sideload build controls.

Final shared, FIX1A, FIX5, FIX6 and sideload-control gates also pass in Windows
PowerShell 5.1. All report build/Play/OPPO/private actions held.

## Next gate

Source qualification does not authorize an artifact. A successor candidate
must be registered with a new version, source manifest and one-build authority;
then pass the existing cold-start and post-build production-plugin integrity
preflight before any separately confirmed OPPO in-place action.

## R60.82 Google acceptance failure and bounded repair

The founder's r60.82 OPPO test still ended with the generic Google sign-in-not-
completed result. The exact local chain proves that UI dispatch and cold-start
Firebase composition were present, but the Android `google_sign_in` Credential
Manager adapter returned `canceled` before Firebase credential exchange. That
adapter can use the same cancellation result for provider or configuration
failures after account selection, so r60.82 incorrectly collapsed the native
failure into a local user cancellation. Firebase exchange, verified-session
bootstrap and post-login navigation were not reached in that attempt.

REG3325 repairs only this boundary. Android now uses an isolated native Google
Play Services Auth compatibility bridge pinned at `21.6.0`. It requests the
exact runtime Web client ID, supplies only the returned ID token to the existing
Firebase credential exchange, preserves genuine cancellation, sanitizes every
provider/configuration/network failure, rejects concurrent requests, retries
after initialization failure and uses the same native owner for sign-out.
Non-Android platforms retain the existing plugin path.

Permanent packaging protection is installed in both APK and AAB wrappers via
`scripts/check-google-android-identity-bridge-readiness.ps1`. Its live and
negative fixture test also passes. The Google OAuth signer/server-client fixture
gate passes without emitting credentials.

Current bounded local evidence:

- three clean exact Google/Firebase/session/UI cycles at 36/36 each;
- whole-mobile analyzer: zero issues;
- Android `:app:compileDebugKotlin`: complete exit zero in quiet/plain mode;
- native bridge readiness: pass, including negative fixture;
- Google OAuth signing readiness fixtures: pass;
- public-auth sideload build controls: pass;
- shared C34P auth, Google return parity and FIX6 hardening: pass;
- no APK/AAB build, OPPO mutation, private login or external action.

The complete mobile suite was stopped after more than four hours because it
was an unbounded Google oracle and had reached 123 unrelated UI/golden/design
failures. REG3319 and REG3320 park that non-authoritative result for a later
bounded baseline audit. No unrelated golden or UI state was changed.

The historical C33E gate is non-authoritative for FIX8 until its separately
owned untracked C33F ticket generation is reconciled (REG3323). The all-eight-
provider FIX5 gate also predates the r60.82 Google-only lifecycle (REG3324).
Neither failed gate is being retried or weakened, and deferred providers remain
out of scope. A new explicit successor build/install authorization is still
required before any OPPO acceptance run.

The post-repair source closure is now sealed at 645 files with SHA-256
`322918D71E4EE4C487564993B8073BEF56BB69E203D9D46A3E665177ACA7F0BF` in
`artifacts/quality/uaw-c34p-fix8-google-native-identity-repair-local-qualification-20260822-01/source-aggregate-manifest.txt`.
The seal includes both the native-bridge readiness checker and its negative
test. A new explicit successor build/install authorization is still required;
the seal itself grants no artifact or OPPO authority.

## 2026-08-22 provider configuration done/pending checkpoint

The durable machine projection is
`config/public-auth-live-provider-readiness-state-c34p-fix5.json`; the parent
and four provider-specific return-truth tickets hold the same sanitized facts.
No provider identifier, credential, token, key hash or private account value is
recorded.

| Provider | Configuration now done | Still pending |
| --- | --- | --- |
| Google | Firebase provider, Android OAuth signer/Web client, native compatibility bridge and local Firebase exchange contract qualified | successor artifact and founder OPPO success/session/relaunch/sign-out acceptance |
| YouTube | reuses the qualified Google identity bridge; no SQL Connect dependency | five FIX7 account-erasure bindings live deployment/readback, OPPO acceptance and later API-team submission |
| Facebook | Firebase provider, Meta strict redirect/HTTPS/deauthorization, public-profile scope and provider handshake qualified | Firebase credential-exchange origin, verified session bootstrap and OPPO acceptance |
| X | active Native public client, least-privilege Read scope, email scope off, founder access and exact callback qualified | callback/broker/Firebase return-truth implementation evidence and OPPO acceptance |
| Instagram | dedicated Business Login setup, professional founder-Dev acceptance and exact callback qualified | callback/broker/Firebase return-truth implementation evidence and OPPO acceptance; public App Review remains held |

The founder-Dev full-social readiness checker is green for private Dev
sideload preparation only. It is not public-release or App-Review authority.
The live Dev function is ACTIVE with the exact four auth bindings and four auth
parameters, but is behind the nine-binding source contract because the five
YouTube/FIX7 erasure bindings remain absent. The focused cross-provider Flutter
suite is still unqualified until a complete retained JSON result replaces the
truncated run recorded by REG3339/REG3340.

The earlier 645-file Google-only seal is now superseded by these readiness gate
and ticket updates. A fresh exact source seal is mandatory before any build;
build/install counts remain zero for this checkpoint.

The founder then authorized the bounded all-social implementation sweep.
Facebook now preserves fixed preflight, native-SDK, Firebase credential-
exchange and completed origins without retaining provider detail. X and
Instagram browser/callback outcomes retain their sanitized codes through the
session owner. Device-review logs expose only provider name plus a fixed code;
no user, account, token or credential value is logged.

The accepted `MainActivity.kt` presentation/bootstrap baseline is preserved by
an exact seven-block projection that reconstructs the original accepted SHA-256
byte-for-byte. The separately mandatory Google bridge gate validates every
excluded provider seam, and its negative fixture passes. Accepted hashes were
not changed. Android release Kotlin compilation passes after using the pinned
Flutter embedding's compile-compatible activity-result delegation.

Current retained qualification is 122/122 cross-provider tests with zero skips
or failures at SHA-256
`D9949866A90C0D472B7F5A0D090BB47E668E53E61B2A83BE43EF73AEEDC9E7DF`,
plus 75/75 exact repaired-owner tests, a clean Flutter analyzer, approved UI
locks, full-social founder-Dev readiness and public-auth build controls. OPPO
provider success, authenticated relaunch and sign-out remain pending and are
not inferred from local tests.

After REG3349 removed the stale full-social FIX5 candidate label, the final
r60.83 source closure was resealed at 647 files with SHA-256
`39FFF26A68D1A8209A8FAFD29E5D49F81781730D3FAD325DE69DD941C959D028` in
`artifacts/quality/uaw-c34p-fix8-full-social-readiness-20260822-01/source-aggregate-manifest-r60-83-final.txt`.
The preceding seal remains immutable superseded evidence.

## Post-r60.83 device rejection and FIX10 local closure

r60.83 consumed exactly one release APK build and one in-place OPPO install.
Independent checksum, signature, signer, package and version readbacks passed,
but founder acceptance rejected all five social providers. Retained sanitized
receipts were `auth-unknown` for Google and YouTube,
`auth-facebook-firebase-provider-failure` for Facebook, and
`auth-provider-unavailable` for X and Instagram. Two founder-authorized latest
OPPO screenshots also proved Email Link reached its Firebase send boundary and
then showed the unclassified failure screen. The screenshots' temporary local
copies were deleted after sanitized classification; no private address or link
is retained here.

FIX8/FIX9/FIX9A-D and the Email Link ticket now supersede source-only readiness
claims with the device evidence. Local repairs separate native bridge,
provider credential, Firebase exchange, App Check, broker response/error,
authorization URL, callback, custom-token, session bootstrap and timeout
stages. Email Link now separates configuration, network, provider-internal,
Firebase-unclassified and platform-bridge failures and records send, callback,
credential and session stages without an address.

The mandatory APK/AAB foundation gate now rejects mobile/backend broker schema
or safe-code drift and any missing real-device stage taxonomy. One retained
combined local cycle passes 157/157 with zero failures or skips and empty stderr
at SHA-256
`C02E02FB9F6F54067F3E148ED18B9A3AFB1D72D304FEE88B1BEBFF693998E80E`.
Flutter analysis is clean, backend strict typecheck passes, Android release
Kotlin compilation exits zero, and public-auth build controls pass. These are
local diagnostic and pre-APK qualifications, not provider/device or live-email
success. r60.83 remains rejected; build, deploy, provider-console write, private
login/link and OPPO mutation authority remain false. Any future candidate needs
a fresh source seal and separate founder authorization.

## Email Link Firebase-console and Hosting-domain correction

Founder console screenshots on 2026-08-22 prove both Email/Password and Email
Link (passwordless sign-in) are enabled in the Dev Firebase project. They also
prove the authorized-domain list contains the default `firebaseapp.com` and
`web.app` domains plus `moolsocial.com`. Provider-disabled and missing-
authorized-domain explanations are therefore excluded.

The supplied current Android guidance requires the modern Firebase Hosting
email-action flow. The checked source already uses `handleCodeInApp: true`,
package `com.moolsocial.app`, HTTPS, and `/__/auth/links` App Links for the
default and custom hosts. The resolved Flutter plugin is `firebase_auth 6.5.6`
and its Android dependency uses Firebase BoM `34.15.0`; this is not the retired
Dynamic Links implementation.

r60.83 nevertheless packaged `MOOLSOCIAL_EMAIL_LINK_DOMAIN=moolsocial.com`.
An authorized Authentication domain is not by itself proof that the domain is
attached to Firebase Hosting, while Firebase accepts `linkDomain` only for a
configured Hosting domain. The first bounded Hosting CLI readback failed once
because its credential session had expired; it was registered and not retried.
No custom Hosting binding is claimed.

The safe local repair omits `linkDomain`, which instructs Firebase Auth to use
the project's default Firebase Hosting domain, while preserving the authorized
exact-return URL `https://moolsocial.com/app`. APK and AAB build wrappers plus
the APK machine gate now reject any non-empty Dev Email Link domain before
artifact creation. The mandatory build-foundation self-test passes, as does
the post-correction focused Email Link cycle at 17/17. No Firebase
write, email send, private link open, build, deploy or OPPO mutation occurred.
Functional Email Link success remains pending a separately authorized future
candidate and founder-private live flow.

## FIX10 final local implementation checkpoint

The current Flutter/Firebase Authentication contract is now applied across the
shared session owner and each provider adapter. The immediate `UserCredential`
is authoritative after credential exchange; authentication-state persistence
and initialization remain bounded; sanitized account-collision handling is
centralized without `fetchSignInMethodsForEmail`; and Email Link uses the
current Firebase Hosting action-code flow with no Dynamic Links dependency.
Email/Password remains enabled because Email Link depends on that provider,
but no password UI was added. Anonymous Authentication remains disabled.

X and Instagram now have exact hosted return pages that validate the bounded
callback query and hand control back to `moolsocial://auth/{provider}`. The
mobile adapters accept only the exact hosted or delivery URI and normalize the
delivery URI back to the registered HTTPS broker callback before completion.
The full-social runtime gate also requires the exact private-Dev YouTube facts:
private review enabled, public review disabled, provider URL present, embedded
player enabled and Shorts autoplay disabled.

Authoritative local results are: focused auth terminal suite 115/115, public
web compliance 10/10, backend 586/586, clean Flutter analyzer, Android release
Kotlin compile success, Android release lint with zero errors and one reviewed
existing Meta false-positive warning, release-resource integrity pass, and the
full-social, shared-auth, FIX1A and FIX5 successor-lifecycle gates green. The
stronger FIX5 live-provider qualification intentionally remains false until
checksum-matched OPPO/provider and founder-private live-email reproof exists.

No `firebase init auth`, `firebase deploy --only auth`, provider-console write,
Hosting deploy, function deploy, APK/AAB build, device mutation, private login,
email send, SMS, Play, SQL Connect or Production action was performed in this
checkpoint. r60.83 remains rejected and consumed; a future artifact requires a
fresh exact source seal and separate action-time build/install authorization.
