# FIX11 Google Sign-In forensic robustness and reuse assessment

Date: 23 August 2026  
Ticket: `UAW-C34P-FIX11-GOOGLE-SIGN-IN-OPPO-FORENSIC-REPAIR`  
Classification: `mvp_required`

## Customer outcome

A Personal user can tap `Continue with Google` on the exact installed OPPO
candidate, complete the Google-owned account handoff and Firebase-backed
MoolSocial session, reach the preserved destination, and remain correctly
authenticated after relaunch with truthful cancel, collision, retry and
failure recovery.

## Why this is required now

The founder rejected the consumed r60.84 APK after real OPPO testing because
Google Sign-In did not complete. Earlier static, configuration, mock and local
contract gates did not prove the installed provider journey. Authentication is
a core launch path, so the escaped defect is MVP-required remediation rather
than optional provider breadth.

## Existing owner inventory and reuse decision

The current tree was inventoried from verified literal mobile, Android, test
and script roots. The existing Google path already owns every production layer
needed for the investigation:

- `apps/mobile/lib/features/journey01/screens/sign_in_screen.dart` owns the
  locked Screen 03 Google action presentation and tap callback.
- `apps/mobile/lib/features/journey01/journey_services.dart` owns the shared
  social-auth gateway contract and Firebase implementation boundary.
- `apps/mobile/lib/features/journey01/journey_session.dart` owns busy/error,
  auth-state, bootstrap, navigation and persistence behavior.
- `apps/mobile/lib/main.dart` owns runtime composition, Firebase/App Check
  initialization and the live Dev auth cohort.
- `apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt`
  owns the Android Google identity compatibility bridge.
- `apps/mobile/android/app/build.gradle.kts` and the Android manifest own
  package, signing/build and native registration inputs.
- `apps/mobile/lib/core/auth/public_auth_failure.dart` and
  `apps/mobile/lib/core/auth/public_auth_runtime_configuration.dart` own
  sanitized public failure and availability contracts.
- `apps/mobile/test/firebase_social_auth_gateway_test.dart`, the existing
  C33E/C33G Google tests, FIX8 runtime-composition tests and Android readiness
  gates already provide the focused test seams to extend.
- `scripts/check-google-android-oauth-signing-readiness.ps1` and
  `scripts/check-google-android-identity-bridge-readiness.ps1` already own
  package/signing/OAuth and bridge preflight contracts.

Disposition is therefore:

- `reuse` for Screen 03, session, gateway, runtime composition, Android bridge,
  package identity and existing gate owners;
- `thin_policy_adapter` only where the exact Google-only runtime or telemetry
  classification needs an existing boundary tightened;
- `test_only_acceptance` for exact prior failure fixtures and locally provable
  stage contracts; and
- `new_necessary_work` only for sanitized stage receipts or focused test/gate
  owners that cannot fit an existing single-purpose owner without weakening
  ownership. No new screen, route or backend owner is justified.

## Duplicate search result

The bounded current-tree inventory found one Screen 03 Google action owner, one
shared Firebase social-auth gateway owner, one JourneySession state owner, one
runtime composition owner and one Android MainActivity identity bridge. The
repository also contains historical C33E/C33G/FIX8 tests and Google readiness
gates, which are reusable evidence boundaries rather than reasons to create a
second sign-in screen, route, gateway, session or backend.

No duplicate production screen, route, gateway, session, Android activity or
backend service is authorized. Any new production owner requires an evidenced
missing trust boundary and a new necessity amendment before creation.

## Smallest complete repair

1. Preserve Screens 01–03 presentation and r60.84 evidence.
2. Inspect the exact installed r60.84 artifact and compare its package,
   signature, manifest, resources, dex/plugin closure and runtime provenance
   with source.
3. Trace UI dispatch, Android identity, OAuth client selection, Firebase
   credential exchange, collision/linking, auth-state, bootstrap, navigation
   and relaunch persistence.
4. Add sanitized stage receipts so cancellation, native failure, Firebase
   failure, collision, bootstrap failure and navigation failure cannot collapse
   into one generic message.
5. Fix only demonstrated Google defects and add exact positive/negative tests.
6. Publish a pre-APK evidence matrix that explicitly marks the real provider
   and OPPO layers as unproved locally.
7. After green preflight, build one unique successor, verify it independently,
   install it once in place, run non-private checks, and request the founder's
   minimal private Google action.

## Explicit exclusions and holds

YouTube, Facebook, X, Instagram, Apple, Email Link, Mobile OTP, SQL Connect,
UI expansion, backend expansion, AAB, Play, Production and all unrelated
tickets remain on hold. No uninstall, data clear, downgrade, private Codex
login, real email/SMS, commit, push or merge is authorized. r60.84 is rejected,
consumed and non-reusable.

## Robustness and evidence boundary

Local/static proof can cover tap wiring, bridge compilation/availability,
stage result propagation, Firebase exchange contracts, auth-state/bootstrap/
navigation logic, retry safety, collision handling, sanitization, package
identity expectations and artifact contents. It cannot prove Google account
selection, OAuth client acceptance, live Firebase credential exchange, live
App Check, installed-session persistence or founder-visible success on OPPO.

Final acceptance therefore requires the exact successor APK installed once in
place, founder-completed real Google Sign-In, the expected authenticated
destination, consistent Firebase/shared-session state and authenticated
relaunch with no private or credential material in retained evidence.

Timeline impact is two focused days and remains inside the founder's 60–75-day
robust-MVP planning lock. The smallest lawful mitigation is to block every
other provider until this single launch-critical identity path is accepted.

## 2026-08-23 forensic implementation checkpoint

The exact installed r60.84 APK was matched to its preserved artifact and source
provenance. Package, signer-to-Android-OAuth certificate, compiled Web OAuth
client, Firebase configuration, generated registrant, Firebase Core/Auth and
integration-test exclusion were independently checked. These locally rule out
a wrong artifact, wrong package/version, evidenced signer/OAuth mismatch and
missing Firebase plugin packaging; they do not prove live sign-in.

The rejected r60.84 source forced Android through a deprecated custom
GoogleSignIn activity-result bridge, collapsed a data-less canceled result into
generic cancellation, and did not separate native identity from Firebase
credential stages. The selected repair now uses the locked official
google_sign_in_android Credential Manager owner, removes the custom bridge,
emits only fixed sanitized stage codes, preserves a `GSI-N01` no-identity
receipt, and fail-closes the entire runtime/build profile to Google only.

Focused gateway, collision, retry, bootstrap, navigation, relaunch and widget
tests pass. The modified Dart owners have no analyzer issues; forced Android
release resource link and release Kotlin compile pass. The complete local/live
boundary is recorded in
`docs/quality/UAW-C34P-FIX11-GOOGLE-SIGN-IN-PRE-APK-EVIDENCE-MATRIX-20260823.md`.

The earlier sanitized Admin config readback and non-private public auth URI
probe both returned HTTP 403. Founder-provided Dev console evidence on
2026-08-23 now confirms Google is enabled and the Web SDK configuration section
is present. No identifier or secret value is retained and no console mutation
was required. The historical APK/AAB control replay, FIX11 gates, unique r60.85
version and 650-row cycle-03 final source seal are now green. The sealed local
preflight/build launchers are parser-checked, reject PowerShell 5 before any
prompt, and require a same-process preflight marker before the build. The build remains
machine-held only for the actual signer/OAuth preflight using founder-entered
upload-keystore passwords in one secure local PowerShell process. No password
value may enter Codex output. No upload, Play, AAB or remote project mutation is
authorized.
