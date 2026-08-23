# REG3074 — release APK custom Android resource values feature disabled

- Date: 2026-08-21
- Status: registered before retry
- Candidate: `UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS`

## Incident

The authorized release APK passed every prebuild gate and started Gradle.
Android configuration then failed because `defaultConfig` declares the app
name and Facebook values with `resValue`, while the current Android Gradle
Plugin requires the custom resource-values feature to be explicitly enabled.

## Impact

- Gradle exited 1 during project configuration;
- no APK or provenance artifact was produced;
- no OPPO, Play, provider or other external state changed;
- founder-held inputs remained only in the open local process.

## Prevention

Enable `android.buildFeatures.resValues` in the Android application module and
retain a source gate that proves custom Facebook resource values cannot be
configured while the feature is disabled. Refresh the source manifest and
one-retry machine state before the next build.
