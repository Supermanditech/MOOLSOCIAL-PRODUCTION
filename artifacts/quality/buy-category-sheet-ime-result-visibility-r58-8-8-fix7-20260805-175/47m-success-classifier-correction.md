# Legacy UiAutomator success-classifier correction

The final direct hint probe executed successfully: it emitted the exact payload,
per-test `INSTRUMENTATION_STATUS_CODE: 0`, a single dot and `OK (1 test)` with
no abort, failure or error. The legacy shell runner then emitted its normal
terminal `INSTRUMENTATION_STATUS_CODE: -1`; the first outer classifier treated
that runner-termination record as a test failure.

The corrected classifier requires the exact probe payload, per-test status 0,
`OK (1 test)`, and absence of `Test run aborted`, `FAILURES!!!` and
`Failure in`. The preserved `47l-accessibility-hint-probe-final.log` is not
rewritten. Candidate source, APK and device state remain unchanged.
