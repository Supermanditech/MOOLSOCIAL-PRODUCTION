# C21 unsupported APK-gate BuildMode none rejection — 2026-08-08

The C21A reference-only state check passed `-BuildMode none` to `scripts/check-apk-regression-gate-state.ps1`. Parameter binding rejected the value because the checker accepts only `debug`, `profile` or `release`. No build, install, runtime or device mutation occurred.

During non-build phases the APK state checker must be called without `-BuildMode`. A concrete build mode may be supplied only inside an authorized build workflow.
