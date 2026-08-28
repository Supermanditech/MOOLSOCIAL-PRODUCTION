# r61.6 prebuild validation

State: `passed_build_authorized_once`.

- Candidate: `UAW-SHOP-LOCATION-ADDRESS-R61.6-CURSOR-UI-REVIEW-20260828`.
- Version: `1.0.0-r61.6` / `2026082808`.
- Source HEAD: `fd19fd4adb4ffa5a14552154f661506ed33fdb2e`.
- Source manifest: `636` files, SHA-256
  `A99577653849E0121FA1924383FEEB0F256E480DC31A744CF1B6802B0B472CEF`.
- Focused result: `142` passed, `3` intentional capture skips, `0` failed.
- Analysis: clean across all changed source and focused test owners.
- Responsive evidence: `12` r61.6 address/request/add captures inspected.
- Runtime: `CursorUiReview`, Firebase/backend startup bypassed.
- Package/device: `com.moolsocial.app.cursorreview`, Redmi
  `TG8HCYTGGQT885OF` only.
- OPPO and `com.moolsocial.app.runtime`: untouched.

Post-build closure:

- Wrapper build passed on its first authorized attempt.
- Built and installed APK SHA-256:
  `66C6F44F592688C9B14839BCA4D1F961E38DA0DDF530626E83958DDA8CB198F5`.
- Redmi install was byte-identical and version readback passed.
- The founder approved the complete location/address journey on 2026-08-29.
