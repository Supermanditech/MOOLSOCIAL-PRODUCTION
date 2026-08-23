# UAW AAB C30Y MVP device-install authority promoted before postupload

Date: 2026-08-15
Regression: `REG-20260815-2205-AAB-C30Y-MVP-DEVICE-INSTALL-AUTHORITY-PROMOTED-BEFORE-POSTUPLOAD`
Status: resolved; build-true/device-false final replay passed

## Finding

The second available-authority replay passed build memory, MVP scope and
approved UI, then C31C rejected the successor phase. C31C explicitly permits
C30Y `buildAuthorized=true` but requires `deviceInstallAuthorized=false` until
the later postupload/preinstall phase. Scope had incorrectly promoted both.

## Resolution

MVP scope now exposes build authority while keeping device-install authority
false. Final replay attempt 03 passed C31C with `build=true; device=false`.
Machine install authority remains a separate one-time value governed by the
later postupload/preinstall transition.

No C30X build phase, founder launcher, AAB, upload, activation, install, device,
provider or credential action occurred. The failed replay remains preserved.

## Prevention

- Pre-prompt scope: build true, device install false.
- Machine upload/install/device authorities remain separate one-time values
  governed by their later gates.
- Scope device-install authority changes only after the exact artifact is
  uploaded/activated and the postupload/preinstall transition passes.
- Run two fresh versioned cycles after registration.
