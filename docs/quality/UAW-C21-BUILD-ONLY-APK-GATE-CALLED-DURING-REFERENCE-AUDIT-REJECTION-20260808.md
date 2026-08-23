# C21 build-only APK gate called during reference audit rejection — 2026-08-08

After removing the unsupported build-mode value, C21A called `scripts/check-apk-regression-gate-state.ps1` without its mandatory candidate/build parameters. The command rejected before execution. Inspection confirmed this script is exclusively a pre-build gate and requires an approved one-build machine state.

C21A must not invoke this build-only checker. It may read and truthfully update `config/apk-regression-gate-state.json` to record founder rejection while leaving build authorization consumed/closed. The checker may run only after a later C21H prebuild seal supplies every mandatory value.
