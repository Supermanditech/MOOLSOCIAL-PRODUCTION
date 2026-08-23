# C17F build orchestration timeout while child active

- Date: 2026-08-08
- Candidate: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-CUMULATIVE-OPPO-QUALIFICATION-FIX2-C17F`
- Build identity: `1.0.0-r60.17` (`2026080817`), profile.
- State at observation: original single guarded build process tree still active; no retry authorized or performed.

## Observation

The exact guarded PowerShell 7 wrapper was invoked after the positive 17-gate machine result. The outer shell call used an insufficient command timeout and returned exit 124 without the wrapper output. A read-only process audit immediately proved that the original PowerShell wrapper, Flutter/Dart and Gradle/Java processes remained active. The reserved C17F APK and provenance paths did not yet exist at that instant.

## Required disposition

The timeout is not treated as a build failure and must never trigger a retry. The original process tree is monitored to terminal completion. Only an APK plus wrapper provenance at the reserved unique paths, or a proven terminal failure with no produced candidate, can determine the single build outcome. Any ambiguous or second output stops C17F.

This new governance evidence changes only the bounded dirty path/status inventory after build launch; it does not change `apps/mobile/lib`, `apps/mobile/test`, `scripts`, the sealed source manifest, the APK inputs, or the installed OPPO predecessor.
