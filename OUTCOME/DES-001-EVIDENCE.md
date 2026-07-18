# DES-001 verification evidence

Result: **PASS**

## Delivered

- Permanent Apple-inspired full-app product design memory.
- Shared Flutter colour, spacing, radius, motion, shadow and tap-size tokens.
- Shared translucent navigation material and selected-segment component.
- Consistent platform-adaptive page transitions, buttons, fields, sheets,
  dialogs, chips and completion feedback.
- Universal navigation migrated to the shared material.
- Screen-reader selection and unread-message semantics added to Mool and Chat.
- Reduced-motion behaviour covered by an automated test.

## Automated verification

- Flutter static analysis: PASS, no issues.
- Flutter tests: PASS, 17/17.
- Universal 412 x 915 golden: PASS.
- Universal 360 x 800 golden: PASS.
- Data Connect SDK generation: PASS.
- Repository `scripts/check.ps1`: PASS.
- Android debug APK build: PASS.

## Real-device replay

- Device: OPPO CPH2375.
- Android: 13.
- ADB serial: `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Clean installation: PASS.
- Setup -> Skip -> Sign in -> Mobile OTP/local automatic verification ->
  Universal: PASS.
- Mool open/close and seven visible main actions: PASS.
- Mool and Chat accessibility descriptions present: PASS.

## Exact failure replay completed

Initial failed sequence:

1. Clean install.
2. Skip area.
3. Choose Mobile OTP.
4. Enter a valid number.
5. Continue with OTP.
6. Result: verification timeout with a retry action.

Root cause:

The first review APK used `127.0.0.1` as the Firebase emulator host. On the
physical phone that address did not reach the laptop service reliably.

Fix:

Rebuilt the review APK with
`MOOLSOCIAL_EMULATOR_HOST=192.168.31.66`, reinstalled from a clean state and
replayed the sequence.

Replay result:

Authentication completed and Universal opened. The exact original failure did
not recur.

## Evidence files

- `OUTCOME/des-001-replay-01-setup-20260718.png`
- `OUTCOME/des-001-replay-02c-state-20260719.png`
- `OUTCOME/des-001-replay-04-mool-open-20260719.png`
- `OUTCOME/des-001-replay-05-universal-buy-20260719.png`

## Build artifact

- APK:
  `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- SHA-256:
  `EED5759E26B6A0A1FEB670F155DC1C22C6B3FAD91631FD018A554F2490AE0B57`

## Non-blocking maintenance warning

Several third-party Flutter plugins still apply the Kotlin Gradle Plugin
directly. The current build passes. Their future built-in Kotlin migration must
be tracked before a later Flutter SDK upgrade.
