# C30S release BuildMode schema mismatch

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`
Affected candidate version: `1.0.0-r60.44 (2026081244)`

## Rejection

The second source qualification cycle completed its format, analysis, affected-test, release dependency, static readiness, device-preservation and repository gates. Its final build-readiness check then rejected before any AAB build because the C30S state checker invoked the permanent regression-memory gate with `BuildMode release`.

The regression-memory contract accepts only `none`, `debug`, or `profile`. No C30S AAB was built, uploaded, or installed.

## Root cause and correction gate

The C30S checker invented a value outside the established global enum. The exact release identity is already enforced by the C30S candidate state, signing, wrapper and post-build artifact gates.

The checker must therefore use regression-memory `Phase implementation` and `BuildMode none` for C30S release-AAB phases. The failed successful-cycle evidence remains immutable. Qualification must use a new evidence generation and run two identical complete cycles after the correction before the one build authority can become available.

Regression: `REG-20260813-1624-C30S-RELEASE-BUILDMODE-SCHEMA-MISMATCH`.
