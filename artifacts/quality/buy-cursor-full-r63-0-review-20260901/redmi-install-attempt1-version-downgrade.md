# Redmi install attempt 1 — rejected safely

- Candidate: `UAW-BUY-CURSOR-FULL-R63.0-UI-REVIEW-20260901`
- APK version code: `2026090101`
- Existing Redmi Cursor-review version code: `2026090111`
- Device: Redmi `TG8HCYTGGQT885OF`
- Result: `INSTALL_FAILED_VERSION_DOWNGRADE`
- Device mutation: none
- App-data mutation: none
- OPPO action: none

The APK itself built and passed package/plugin integrity. Installation was rejected before replacement because the new review version code was lower than the already installed review package. Forced downgrade is prohibited. The successor must use a new candidate identity and a version code greater than `2026090111`.
