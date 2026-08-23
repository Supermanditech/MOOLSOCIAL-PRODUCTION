# FIX8 r60.81 postbuild recovery and OPPO qualification

Date: 22 August 2026
Ticket: `UAW-C34P-FIX8-GLOBAL-SOCIAL-LOGIN-OPPO-SUCCESSOR-AUDIT-REPAIR`

## Outcome

The already-assembled r60.81 release APK was recovered from the REG3205
postbuild verifier false negative without another build. Mapping-aware R8
inspection proves `GeneratedPluginRegistrant`, Firebase Core and MainActivity
are present and `integration_test` is absent. APK signature verification and
signer continuity with preserved r60.80 pass.

The exact qualified APK was installed once on the connected OPPO with
`adb install -r`. Authoritative package readback is `com.moolsocial.app`,
version `1.0.0-r60.81`, version code `2026082181`. No reinstall, uninstall,
data clear or downgrade occurred.

One cold start returned status `ok`. After the founder woke and unlocked the
device, read-only window/activity checks proved MoolSocial is the exact focused
and resumed app with a live surface. Crash/ANR, MissingPluginException and
Firebase initialization failure counts are all zero. No UI content, private
identity, provider account, screenshot or hierarchy was read.

## Exact retained evidence

- Source seal: 637 rows, SHA-256
  `9C6BFBC71C82E3F4CA446AC62A335C5FD37F23B83893A6059BC9BEAF71A69182`.
- APK: 104,047,396 bytes, SHA-256
  `F127CD8DB071AB320A4DD724C3A66A2CD4AADE9CF5E8605AADC1F271569FF20B`.
- Artifact qualification:
  `artifacts/quality/uaw-c34p-fix8-global-social-login-oppo-successor-r60-81-20260822-09/04-artifact-qualification.json`.
- Installed identity:
  `artifacts/quality/uaw-c34p-fix8-global-social-login-oppo-successor-r60-81-20260822-09/05-installed-identity.json`.
- Cold-start qualification:
  `artifacts/quality/uaw-c34p-fix8-global-social-login-oppo-successor-r60-81-20260822-09/06-cold-start-qualification.json`.

## Counts and boundaries

- Total APK build attempts: 2.
- Additional build during postbuild recovery: 0.
- Sealed r60.81 APKs: 1.
- OPPO in-place installs: 1.
- Cold starts under this qualification: 1.
- Private provider logins, real email/SMS, Play, AAB, Production, SQL Connect,
  commit, push and merge actions: 0.

REG3222 records that the install command reached `Success` but its final
PowerShell receipt used invalid bare boolean tokens. The install was never
repeated; read-only package/version checks classified the one completed action.
REG3223 records the initially incomplete Android focus/timing receipt. The app
was not relaunched; exact read-only focus checks completed after device unlock.

## Permanent future APK/AAB prevention

- Mapping-aware APK and AAB plugin-integrity gates reject missing registrant,
  Firebase Core or MainActivity and reject any `integration_test` bytecode.
- Both wrappers reject the current 14 obsolete release-plugin manifest
  namespace declarations before Gradle; direct dev-only `integration_test` is
  not misclassified as a release plugin.
- Both wrappers reject the three resolved release plugins still applying the
  legacy Kotlin Gradle Plugin: `firebase_app_check`, `mobile_scanner` and
  `speech_to_text`.
- Both wrappers require the forced release resource-link preflight, and that
  Gradle preflight uses `--warning-mode=fail` so Gradle 10 deprecations cannot
  remain a successful packaging warning.
- Dependency remediation must use repository dependency upgrades or overrides;
  the machine Pub cache must never be patched.

## Remaining founder gate

The technical cold-start receipt is qualified, but founder-visible screen
acceptance and any real provider-account login matrix remain separate. Private
provider login, real email/SMS and Apple remain unauthorized in this action.
