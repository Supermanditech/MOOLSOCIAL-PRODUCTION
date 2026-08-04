# Legacy UiAutomator runner compatibility root cause

The first direct-hint probe jar compiled and was pushed, but Android 13's
legacy shell UiAutomator runner aborted before the test because
`android.test.RepetitiveTest` was removed from the platform. The runner still
printed `OK (1 test)` and returned exit 0 after the abort; therefore neither
string nor exit code alone is accepted as pass evidence.

The rerun bundles the removed annotation as an evidence-only compatibility
class and requires both the exact `MOOLSOCIAL_ACCESSIBILITY_HINT_PROBE` payload
and absence of `Test run aborted`/`INSTRUMENTATION_STATUS_CODE: -1`. The
candidate application, APK and source manifest are unchanged.
