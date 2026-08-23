# UAW C30W r60.47 Play cold-start configuration recovery findings — 2026-08-14

## Blocking production regression

The Google Play-installed r60.47 candidate is correctly installed and focused on OPPO CPH2375, but it renders no usable UI. App-process error evidence proves `main` aborts before `runApp` because the required Google server client ID Dart define is absent from the release artifact.

This invalidates r60.47 production-grade acceptance. The release remains Internal Testing only. No second build, upload, install, backend deployment, Hosting deployment, email, or quota submission is authorized.

## Why prior gates missed it

The two source cycles, analyzer, unit/widget/backend/Hosting suites, config-only preflight, manifest/resource checks, and sealed AAB provenance did not launch the release-configured runtime or prove the complete required Dart define key set. The Play-installed predecessor also could not prove candidate-specific embedded configuration.

## Mandatory successor controls

1. Add a secret-safe gate that checks required release define **names and presence only**, never values.
2. Add a release-runtime test that exercises the same validation contract used by `main` and proves a complete configuration reaches the app bootstrap.
3. Add a candidate cold-launch acceptance gate that requires a named interactive first screen and rejects any app-process Flutter/AndroidRuntime error, ANR, blank hierarchy, or timeout.
4. Add the new test/gate owners to the authoritative focused manifest and both-cycle qualification.
5. Do not create a successor AAB until the founder explicitly authorizes exactly one new build after fresh qualification.
