# FSC01 Social redundant family-root removal — completion

Date: 2026-08-10
Ticket: `MOOLSOCIAL-FSC01-SOCIAL-REDUNDANT-FAMILY-ROOT-REMOVAL`

## Completed outcome

The existing shared destination shell now omits the family-root cell only when
the active family is Social. The compact Mool switcher remains first, and
Shorts, Videos, Feed and Create remain in their original order as direct
one-tap local actions. Food and every other unaffected family retain their
root cell.

No screen, route, backend owner, API owner, provider state or device candidate
was added. C28D remains rejected and installed OPPO r60.27 remains untouched.

## Evidence

- `dart format`: five affected Dart files formatted, zero formatter changes.
- Focused/current shared-shell, fitment and accessibility groups: 33 passed.
- Six-family real production conformance group: 4 passed.
- Current route projection, catalogue, connected switcher and navigator group:
  19 passed, 1 pre-existing skip.
- Total attributable result: 56 passed, 1 skipped, 0 failed.
- `flutter analyze`: no issues.
- `git diff --check`: passed for all FSC01 runtime, test and authority files.
- `scripts/check-mvp-scope-gate-state.ps1 -RequireExecutionAuthorized`: passed.
- `scripts/check-codex-development-regression-memory.ps1`: passed.
- `scripts/check-approved-ui-locks.ps1`: passed.
- `scripts/check-social-protected-baseline.ps1`: passed with the predecessor
  178-file tree unchanged.

The directory-wide historical universal suite is not claimed as a green gate;
its obsolete C20–C23 removed-owner failures are permanently recorded in
REG963 and REG965. All current assertions that required Social's predecessor
root were migrated under REG964 and REG966 and pass.
