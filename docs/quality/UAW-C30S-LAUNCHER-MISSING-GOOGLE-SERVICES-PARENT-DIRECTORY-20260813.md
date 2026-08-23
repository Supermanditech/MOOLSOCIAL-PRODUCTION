# C30S launcher missing Google Services parent directory

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`
Affected candidate version: `1.0.0-r60.44 (2026081244)`

## Rejection

The founder-only launcher validated both hidden inputs, wrote the transient private Dart-define file, and then rejected while creating `apps/mobile/android/app/src/release/google-services.json` because the exact release source-set parent directory did not yet exist.

The launcher `finally` path ran. Read-only state reconciliation proved build authority `available_once`, build count `0`, wrapper invocation count `0`, config-only count `0`, and no Google Services transient leaf. No APK or AAB was built, uploaded, or installed.

## Root cause and prevention

The leaf-absence guard did not also establish its parent-directory lifecycle. The correction must validate every transient output parent before founder prompts, constrain it to its intended root, require the private signing parent to exist, and create only the exact Android release source-set directory when absent. The launcher must continue erasing both transient files and process variables in `finally`.

Because the launcher is a sealed source owner, both complete source qualification cycles must be rerun under a new immutable evidence generation before the single build authority can be used.

Regression: `REG-20260813-1625-C30S-LAUNCHER-MISSING-GOOGLE-SERVICES-PARENT-DIRECTORY`.
