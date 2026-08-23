# REG-20260821-3106 — Cursor worktree historical registered evidence missing

Date: 21 August 2026
State: registered; retry blocked until complete evidence reconciliation

## Failure

After REG3105 was applied, the isolated Cursor worktree's first regression-
memory replay stopped on a missing historical registered evidence owner:

`artifacts/quality/uaw-personal-mvp-main-subaction-bottom-panel-fix1-20260806-01/56-run-regression-memory-self-test.ps1`

## Impact

- No Cursor audit read, test, source edit, build, provider, Play or OPPO action
  ran after the rejection.
- The production checkout and existing Cursor B1/B2 outputs were preserved.
- The earlier 502-file refresh is retained but is not accepted as a complete
  worktree evidence reconciliation.

## Root cause

The primary refresh admitted its own pre-copy missing-file projection as
complete without running the worktree's regression-memory evidence resolver.
At least one historical evidence owner required by the refreshed registry was
not materialized in the isolated worktree.

## Prevention

Before another Cursor gate attempt, enumerate every refreshed registry
evidence owner in memory, require each source owner to exist in the production
checkout, copy every remaining absent owner sequentially with source/target
length and SHA-256 equality, and require a zero-missing bounded readback. Only
then may the isolated memory and coordination gates replay.
