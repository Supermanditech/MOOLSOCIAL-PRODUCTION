# REG-20260821-3112 — Cursor worktree global-claim recurrence

Date: 21 August 2026
State: registered; Cursor audit stopped for this phase

## Failure

Cursor replayed its isolated coordination gate after the primary refresh. The
memory gate passed at generation 3080, but coordination again rejected the
unrelated Desktop owner:

`apps/mobile/android/app/src/main/res/xml/data_extraction_rules.xml`

## Impact

- No Cursor audit, functional test, report edit, source action or Desktop
  checkout access occurred.
- The recurrence is the same unresolved incompatibility recorded in REG3107.

## Root cause

The isolated worktree still contains the global active-claim policy rather
than a worktree-scoped claim set, so the local gate continues to require
Desktop-only uncommitted owners.

## Prevention and disposition

Do not retry the Cursor audit in this phase. Cursor remains stopped and the
primary Desktop agent retains the complete pre-APK/FIX7 audit. A future
separate-worktree task may resume only after a primary-created scoped policy
and branch-safe gate are designed, self-tested and explicitly authorized.
