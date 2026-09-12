# UAW-INTEGRATION-REPAIR-SHOP-V2-R61-5-BUY-REGRESSION-FIX-20260828

State: `repair_committed_two_full_cycles_passed_build_overlay_pending`

- Work ID: `shop-v2-r61-5-buy-regression-fix-20260828`.
- Branch: `work/integration-repair/shop-v2-r61-5-buy-regression-fix-20260828`.
- Baseline: `14fcd6b2be25cd9ebee0ca803606069f49dd74c3`.

Customer outcome: preserve the production-grade Shop landing and shared global
profile experience while proving the complete Buy journey is regression-safe
before the Redmi review build.

Scope is `mvp_supporting`: retain one complete JSON test event stream, identify
the two exact failures from the rejected 461-pass/28-skip run, and create one
bounded Cursor-owned defect child only if a demonstrated UI or test owner must
change. This diagnosis does not alter backend, APIs, Firebase, Android
configuration, OPPO, or `com.moolsocial.app.runtime`.

The smallest complete path is: run the full Buy suite once through the
clean-support wrapper with JSON reporting, join failed `testDone` events to
their `testStart` names and URLs, then either record an environment-only cause
or transfer only the exact failing owner for repair. Two fresh full Buy cycles
must pass after any repair before build authorization resumes.

Resolved outcome:

- repair commit:
  `e7a62825d0bf91e409f3dece7509c627bbb093f7`;
- the two failures were missing c24f versioned golden sets from accepted
  runtime `f105195b`, not Shop/profile production source regressions;
- R58.8.7 image settling now uses the established `tester.runAsync` pattern;
- ten new c24f captures were created and visually inspected; all old protected
  PNGs remain byte-identical;
- full Buy cycle 1: `463` passed, `28` intentional skips, `0` failures;
- full Buy cycle 2: `463` passed, `28` intentional skips, `0` failures.

Build authorization is not consumed by this ticket. The next action is an
exact overlay of the repair commit into the unique r61.5 CursorUiReview build
candidate, followed by the APK machine gate and Redmi-only installation.
