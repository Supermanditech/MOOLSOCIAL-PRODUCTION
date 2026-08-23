# REG2785 — C34L readiness manifest-bound source vector gap

Date: 17 August 2026
State: registered first readiness behavior failure; no external action

## Finding

The first direct PowerShell 7 readiness self-test advanced a fixture from the
selection state to `prebuild_manifest_bound_two_fresh_cycles_required`, then
injected premature `build=available_once`. Readiness applied its strict
zero-action/held-authority assertion only to the original selection state, so
the manifest-bound source phase passed the invalid vector and the negative
fixture failed. The agent stopped; cleanup completed and WinPS did not run.

## Required correction

Every source-phase precycle state must independently enforce all eight zero
action counts, held build/upload/install/journey authorities, zero release
actions and detailed/aggregate parity. Add manifest-bound wrong-count and
premature-authority negatives on both hosts before PRE-AAB-4 resumes.
