# REG3075 — release APK compiled a stale ignored integration-test registrant

- Date: 2026-08-21
- Status: registered before retry
- Candidate: `UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS`

## Incident

The registered release retry passed every prebuild gate and compiled far enough
to reach Java. A stale ignored
`android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
then referenced Flutter's development-only `integration_test` plugin, which is
not on the release classpath. Java compilation exited 1.

## Impact

- no APK or provenance artifact was produced;
- no OPPO, Play, provider or other external state changed;
- founder-held inputs remained only in the open local process.

## Root cause

An ignored generated registrant created before this build remained inside the
production source set. Because it was ignored, it was absent from durable
source qualification while still affecting the local release compiler.

## Prevention

Preserve the exact stale file as retained evidence, remove it from the Android
main source set, and add a prebuild control that rejects any future ignored
registrant in that path. Let the Flutter Gradle integration own release plugin
registration.
