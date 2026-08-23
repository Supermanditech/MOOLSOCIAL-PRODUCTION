# C11 complete Buy suite omitted from first affected batch

- Regression: `REG-20260807-254-C11-COMPLETE-BUY-SUITE-OMITTED-FROM-FIRST-AFFECTED-BATCH`
- Ticket: `UAW-PERSONAL-MVP-CONTEXTUAL-SUBACTION-THUMB-SHELF-FIX1-C11`
- State: `resolved_gate_active`
- Date: 2026-08-07 IST

## Observation

The dedicated C11 suite passed 7/7 and two identical 26-file navigation and
destination cycles passed 236/236. Before APK sealing, an additional complete
run of all 47 Buy test files produced 348 passes, 20 skips and 14 failures.
No build or device mutation was started.

## Required correction

Extract every failing test and error with a bounded JSON reporter. Classify
each as product behavior, fitment or a superseded r60.10 assertion; correct the
smallest rightful owner; rerun each focused failure; then require two identical
complete Buy-suite passes before changing this regression to resolved or
opening the APK gate.

## Resolution

The exact failures were corrected or classified. Two final complete functional
Buy cycles each passed 360 tests with 20 skips and zero failures. The two
intentional pre-C11 golden references are tagged, retained unchanged and
excluded pending founder visual acceptance; they are not relabeled as passes.
