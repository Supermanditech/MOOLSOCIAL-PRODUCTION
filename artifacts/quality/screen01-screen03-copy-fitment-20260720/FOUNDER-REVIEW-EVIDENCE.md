# Screens 01–03 production acceptance evidence

Status: **FOUNDER ACCEPTED — PRODUCTION PRESENTATION LOCKED**

Founder acceptance was confirmed on 2026-07-20 after the mobile OTP routing
defect was corrected and the exact OPPO candidate completed separate mobile and
email OTP replays to Universal.

## Corrected regression

- Removed the Screen 03 OTP implementation explanation:
  `Email OTP uses the same verify screen with email instead of mobile.`
- Removed Screen 01 slow-start technical diagnostics about app version,
  network and route selection.
- Replaced those diagnostics with the same approved MoolSocial identity,
  promise and customer-facing opening status.
- Audited native rendered text, input labels/hints and semantic labels in
  every Screen 01–03 state.

The permanent policy is recorded in:

- `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`
- `docs/quality/CUSTOMER-COPY-MACHINE-GATE.md`
- `docs/quality/RELEASE-GATES.md`

Executable gates:

- `apps/mobile/test/ui_v2_customer_copy_machine_gate_test.dart`
- `apps/mobile/test/ui_v2_screen01_03_fitment_matrix_test.dart`
- `scripts/check-customer-copy-html.cjs`

## Candidate identity

- Candidate ID: `screen01-screen03-production-lock-v6-20260720`
- Branch: `remediation/prototype-conformance-2026-07-20`
- Source parent HEAD: `fe3ef5b`
- APK SHA-256:
  `76C40D1A3DEAD71358A72AFB77DB940F0E9F88751B4A48D958368451D2330ED0`
- Final OPPO installed-base SHA-256:
  `76C40D1A3DEAD71358A72AFB77DB940F0E9F88751B4A48D958368451D2330ED0`
- Candidate/installed byte equality: `true`
- Device: OPPO CPH2375, Android 13, serial `2b3e0f71`

## HTML candidate checksums

- Screen 01:
  `3908857907D04EC540B8C0DD7D00148E749CB76787D6281F81FDA0BF321E9C60`
- Screen 02:
  `8D7E5926B8B60CBA52AA92D1B37B2C5CB0200C572847FF633EAED0540EA843A0`
- Screen 03:
  `C8B58BED63B6616F83D06C7D95FAA335DB537B3C6DF37593D601D19037ECDFEF`

Authoritative immutable copies are recorded as Screen 01 `v3`, Screen 02 `v4`
and Screen 03 `v2` under `approved-references/screens/`.

## Automated verification

- HTML customer-copy gate: 9 Screen 01–03 states, passed.
- Native state-complete customer-copy gate: passed.
- Phone fitment matrix:
  `320×568`, `360×640`, `360×720`, `375×667`, `390×844`,
  `412×915`, `430×932`, plus compact `140%` text.
- Android and iOS-style safe-area insets: passed logical Flutter layout.
- Primary actions: reachable and at least 44 logical pixels.
- Flutter analyzer from `apps/mobile`: no issues.
- Full regression 1: `375/375`, passed.
- Full regression 2: `375/375`, passed.
- `git diff --check`: passed.

Windows validates the shared Flutter layout and Android artifact. An actual iOS
simulator/archive build remains a macOS CI staging gate; this candidate does
not claim a locally executed iOS binary.

## Exact-APK OPPO replay

- Clean install: Screen 01 → incomplete Screen 02.
- Screen 01 app-switch interruption: resumed on Screen 01; the uninterrupted
  interval then led to Screen 02.
- Android location permission: passed.
- Phone Location Services off: customer recovery and phone-settings handoff
  passed.
- Return after enabling Location Services: resolved
  `Khema-Ka-Kuwa, Jodhpur, Rajasthan`.
- Screen 02 Continue: reached the V2 Screen 03 login choices.
- Google, YouTube, Apple, X, Instagram and Facebook: each reached its own
  recoverable return and `Choose another method`.
- Email OTP and mobile OTP: masked destinations and channel labels passed.
- The prohibited implementation phrase was absent visually and from the
  Android accessibility trees.
- Invalid mobile OTP stayed recoverable.
- Valid mobile OTP reached Universal.
- Authenticated killed-process relaunch restored Universal.
- Final mobile OTP request and verification passed with `adb reverse --list`
  empty. The APK used the preflighted direct device-to-laptop review route.
- A separate clean install verified email OTP to Universal.
- The false `You appear to be offline` diagnosis was removed from the mobile
  gateway. A permanent source gate rejects its return.
- No fatal Android or Flutter exception was observed.

## Lock state

The historical Screen 01 `v2`, Screen 02 `v3` and Screen 03 `v1` reference
packages remain untouched. New immutable accepted packages are:

- `approved-references/screens/01-app-splash-first-open/v3`
- `approved-references/screens/02-first-setup-language-location/v4`
- `approved-references/screens/03-login-account-handoff/v2`

`scripts/check-approved-ui-locks.ps1` verifies the reference packages and
current accepted presentation files. Screens 01–03 remain untouched while the
next isolated UI set is developed. A later combination requires a separate
integration replay.
