# REG3095 — full mobile suite reported 247 visual golden failures

- Date: 2026-08-21
- Status: registered; classification pending representative diagnostics

The comprehensive `flutter test` run completed with 1,617 passes, 36 skips and
247 failures. The terminal failure list identified visual golden baseline tests
across Buy, Captain and other surfaces. Functional startup/auth suites were not
listed as failures. No build or device action followed.

This aggregate is not accepted as green and is not assumed to be 247 unrelated
defects. One representative golden must be rerun with bounded full diagnostics,
then the shared cause and affected owner set must be classified before any
baseline update or source change.

Prevention: every comprehensive pre-APK audit records pass/skip/fail totals and
classifies shared golden infrastructure failures separately from functional
journey defects; no automatic golden regeneration is allowed.
