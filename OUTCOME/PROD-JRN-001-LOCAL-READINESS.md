# PROD-JRN-001 local readiness

Status date: 2026-07-18 IST
Scope: install/open through the authenticated universal Mool shell

## Result

The first production journey is complete against the isolated local Google
stack and has passed its real-device replay on the connected OPPO A76. Cloud
deployment is intentionally blocked until the new Google Cloud billing account
is activated.

## Verified implementation

- Android package and iOS bundle: `com.moolsocial.app`.
- Firebase demo project: `demo-moolsocial-local`.
- Firebase Authentication emulator: `192.168.31.66:9099` for the phone and
  `127.0.0.1:9099` for laptop checks.
- Firebase SQL Connect emulator: `192.168.31.66:9399` for the phone and
  `127.0.0.1:9399` for laptop checks.
- OS location permission is requested only after the user chooses current
  location.
- Language, area and pending destination survive intermediate failures.
- Phone verification creates an emulated Firebase user and bootstraps the
  idempotent SQL Connect account record.
- Protected destinations are restored only after authentication.
- Mool opens from every primary section and closes back to the prior section.
- Search, notifications, profile, sign-out cancellation and sign-out
  confirmation complete their visible tap intent.
- Approved prototype screens 00–04 are translated into native Flutter using
  the prototype navy, saffron and green identity; approved setup, sign-in and
  OTP wording; YouTube-connect launch model; Social action rail; and the
  persistent Mool and Chat dock.

## Failure replays fixed

### JRN1-001: protected deep link fell back to Social

Reproduction:

1. Start clean at `/app/work`.
2. Complete setup.
3. Request and verify the OTP.

Root cause: two router refreshes consumed the pending route before the protected
target rendered.

Fix: retain the destination through router refreshes and mark it consumed only
after the destination screen completes its first frame.

Exact replay: passed. Full journey regression: passed.

### JRN1-002: Social hero overflowed on phone widths

Reproduction:

1. Render the authenticated Social universal screen at 412 x 915.
2. Repeat at 360 x 800.

Observed: vertical overflow of 89 px and 140 px.

Root cause: a fixed-height hero combined with responsive text wrapping.

Fix: allow the card to size from its content and keep the screen scrollable.

Exact replay at both widths: passed. Golden baselines saved.

### JRN1-003: local OTP review code was not displayed

Reproduction:

1. Ask the Auth emulator to generate an SMS code.
2. Read the local verification-code endpoint.

Observed: the client expected the older `sessionCode` property while the
current emulator returns `code`.

Fix: read `code` with backward-compatible `sessionCode` fallback.

Exact REST replay: code retrieved, phone sign-in completed, UID and ID token
created, then emulator Auth state cleared.

### JRN1-004: OPPO ADB reverse exposed ports but passed no traffic

Reproduction:

1. Reverse ports 9099 and 9399 through ADB.
2. Request the Auth emulator from the phone.

Observed: ADB listed both reverse rules but passed zero bytes.

Root cause: the connected OPPO firmware did not forward the reverse sockets.

Fix: make the emulator host a build-time setting, bind the isolated emulators
to the laptop LAN interface and build this review APK for `192.168.31.66`.

Exact replay: both ports reached from the OPPO before installation; OTP request
and verification passed.

### JRN1-005: authenticated SQL account bootstrap returned unavailable

Reproduction:

1. Complete the real OTP verification on the OPPO.
2. Run `UpsertMyAccount` through the generated SQL Connect SDK.

Observed: authentication succeeded, but SQL Connect reported that the service
had no PostgreSQL connection string.

Root cause: the emulator did not have a persistent PGLite `dataDir`, so its
service was loaded before the integrated PostgreSQL datasource was configured.

Fix: configure `dataconnect/.dataconnect/pgliteData`, restart the emulator and
allow its schema migration to finish before replay.

Exact replay: `UpsertMyAccount` succeeded for the authenticated phone user and
the app opened the universal Social screen.

## Automated regression

- Flutter analyzer with fatal infos: passed.
- Session/unit tests: passed.
- Widget journey tests: passed.
- 412 x 915 visual baseline: passed.
- 360 x 800 visual baseline: passed.
- Total automated tests: 15 passed, 0 failed.
- Debug APK build: passed.
- Debug APK SHA-256:
  `472AE001D828CD4DF12169E29D5F6069A2775A67D30D1899A28FA3A8B82168AB`.
- APK application ID: `com.moolsocial.app`.
- APK version: `1.0.0+1`.
- Minimum Android SDK: 24.
- Target Android SDK: 36.

## Real-device replay

- Device: OPPO CPH2375 (A76), Android 13.
- Clean uninstall/install: passed.
- Skip area to sign-in: passed.
- Local Mobile OTP request and visible review code: passed.
- OTP verification and Firebase authenticated user: passed.
- Generated SQL Connect account bootstrap: passed.
- Universal Social screen: passed.
- Mool to Work: passed.
- Work to Chat: passed.
- Chat retains Mool access: passed.
- Chat Mool ribbon exposes Social and Work: passed.
- Final review state: authenticated Social universal screen.
- Evidence:
  `OUTCOME/phone-review-universal-20260718.png` and
  `OUTCOME/phone-review-mool-20260718.png`.

## Remaining external verification

The new Google Cloud billing account is still required for a real cloud staging
deployment. iOS signing and a physical iPhone build require Apple Developer
credentials and macOS/Xcode; the shared Flutter implementation and iOS bundle
identity are already in the repository.

Flutter also reports a future Kotlin build-plugin migration warning originating
inside several current Firebase plugins. It does not affect this build or
runtime and remains a dependency-maintenance ticket before a future Flutter
upgrade.
