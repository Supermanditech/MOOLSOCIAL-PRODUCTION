# UAW-INTEGRATION-REPAIR-SHOP-V2-R61-5-BUY-REGRESSION-FIX-20260828

State: `bounded_read_only_failure_inventory`

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
