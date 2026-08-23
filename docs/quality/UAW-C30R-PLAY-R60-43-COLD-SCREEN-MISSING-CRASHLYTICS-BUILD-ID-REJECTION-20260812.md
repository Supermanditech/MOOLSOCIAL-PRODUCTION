# C30R Play r60.43 cold-screen missing Crashlytics build-ID rejection

Date: 2026-08-12

## Disposition

Google Play successfully installed `com.moolsocial.app` r60.43 (`2026081243`)
on OPPO CPH2375. Package-manager readback proves installer
`com.android.vending`, four Play-delivered APK splits and the exact registered
Play App Signing SHA-256
`47B28C7DDE2B61CAB6A7748C9019A3B57376B3BE1DC163D48253BBA35B63CDD9`.

Runtime acceptance is rejected. The activity remains resumed with a live
process but never renders a Flutter semantic node or first frame; the captured
screen is the solid-blue Android launch surface.

## Root cause

Bounded error-only logcat, with nonce/token/Integrity/App Check/private-verdict
patterns excluded before output, proves an uncaught exception during
`Firebase.initializeApp()` at `main.dart:58`:

`The Crashlytics build ID is missing.`

The exception is thrown by Firebase initialization because the release bundle
does not contain the build-time Crashlytics identifier expected by the Android
Firebase SDK. The same bounded log also reports missing `google_app_id` and
disabled Firebase Analytics measurement. This is a release packaging/
configuration defect, not evidence of a decoded Play Integrity or App Check
verdict.

## Impact

- C30R Play install count is exactly one and its install authority is consumed.
- r60.43 remains installed; do not uninstall, clear data, downgrade or sideload.
- C28D, App Check, YouTube, Feed, Create and navigation journeys did not start.
- Create writes attempted remain zero.
- No second build, upload or install occurred.
- No Production/open/public rollout, provider deployment, email or quota action
  occurred.

## Permanent prevention

Every future release-AAB source/build qualification must assert that the
release variant contains a nonblank Crashlytics build ID and the expected
Firebase Android resource identity, then execute a release-mode Firebase
initialization smoke test before consuming build/upload authority. A passing
debug/profile Firebase startup is not release-AAB proof.

## Evidence

- `artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/15-play-installed-identity-and-cold-stall-rejection.json`
- `artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/14-play-r60-43-cold-screen-stall.png`
- `artifacts/quality/uaw-personal-mvp-social-play-internal-youtube-compliance-c30q-r60-43-20260812-01/14-play-r60-43-cold-screen-stall.xml`
