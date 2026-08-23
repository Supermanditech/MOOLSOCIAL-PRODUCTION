# C30T release-readiness harness timeout rejection — 2026-08-13

## Finding

The first combined, read-only C30T JSON and release-readiness audit was launched with a one-second shell timeout. JSON validation completed, but the parent shell timed out before the readiness script's bounded Gradle task-registration check could report a result.

## Containment

- No AAB, APK, upload, install, provider deployment, device write or external communication was performed.
- The incomplete log is rejected as readiness evidence.
- Any surviving child process must be identified before retry.
- The retry must use a timeout appropriate for Gradle configuration and must independently report its exit code and SHA-256 evidence hash.

## Permanent prevention

Release-readiness scripts that configure Gradle receive a bounded runtime of at least two minutes. Fast JSON parsing and slower release-task discovery are not assigned the same orchestration timeout.
