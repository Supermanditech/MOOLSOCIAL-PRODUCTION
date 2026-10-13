# Build attempt 1 — Google Services failure

- Candidate: `UAW-SHOP-V2-R61.5-CURSOR-UI-REVIEW-20260828`.
- Version: `1.0.0-r61.5` / `2026082807`.
- Runtime profile: `CursorUiReview`.
- Result: failed before APK creation.
- Failed task: `:app:processDebugGoogleServices`.
- Cause: `google-services.json` is intentionally absent for the UI-only review
  package, but the Google Services Gradle task still executed.

No APK or build provenance file was created, no device action occurred, and
the single build authorization is recorded as `consumed_failed`. The retry may
not copy Firebase configuration or alter production/runtime variants; it must
skip Google Services processing only for the existing Cursor review debug
profile and receive a fresh one-build authorization.
