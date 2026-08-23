# REG3182 - FIX8 release resource link missing launch background

## Classification

Registered authoritative first Flutter/Gradle r60.81 build-attempt failure.
No APK, provenance, install, Play action or device mutation was produced.

## Evidence

The founder's authorized wrapper passed the MVP, premium-motion and 17 APK
prebuild gates, then invoked `assembleRelease`. Android resource linking failed
in `:app:processReleaseResources` because merged release styles referenced
`@drawable/launch_background` while that drawable resource was absent. Gradle
failed after 2 minutes 50 seconds and the wrapper threw its bounded build
failure. The Kotlin-plugin messages were warnings and were not the cause.

## Root cause and prevention boundary

The pre-APK control graph verified manifests, runtime defines, source checksums,
tests, analyzer, lint and postbuild plugin membership, but it did not perform an
authoritative release resource-link task or a complete static Android resource
reference/owner audit immediately before `assembleRelease`.

Before any successor build authorization or retry:

1. Audit every checked-in Android XML resource reference against live owners.
2. Restore or replace the missing launch-background owner with the smallest
   source-consistent repair.
3. Add a pre-APK Android resource-integrity gate that fails before Flutter APK
   assembly.
4. Prove the exact release resource-processing task clean, then rerun all
   affected Android, source-manifest and APK gates.
5. Create a distinct successor source seal; never reuse the r60.81 `...-03`
   fingerprint after Android source or build-control changes.
6. Do not infer or perform another APK build without a newly recorded action
   count and explicit authority consistent with the one-build limit.
