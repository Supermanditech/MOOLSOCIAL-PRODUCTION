# REG-20260818-2993 C34P historical C30X Screen03 creation gate wrong replay

Date: 18 August 2026 (IST)
State: registered; historical gate intentionally not weakened or retried

## Incident

The current approved UI reference/production lock passed. The primary then ran
`check-screen03-v4-production-acceptance-c30x-fix1.ps1`, which rejected because
its creation-era contract requires the C30X FIX1 ticket to remain the selected
MVP scope. The current authorized ticket is C34P FIX1A. No source correction or
retry followed.

## Root cause

A historical creation/acceptance gate was treated as a generic successor replay
gate even though it deliberately binds its own ticket and scope state.

## Prevention

Do not edit or retry the historical C30X gate under C34P. Use the current approved
UI lock, C34P all-eight gates, the protected Screen 03 session suite, and only an
explicit generic-successor replay gate when one exists for this lineage.

## Retained evidence

- `scripts/check-approved-ui-locks.ps1`
- `scripts/check-screen03-v4-production-acceptance-c30x-fix1.ps1`
- `apps/mobile/test/screen03_session_test.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
