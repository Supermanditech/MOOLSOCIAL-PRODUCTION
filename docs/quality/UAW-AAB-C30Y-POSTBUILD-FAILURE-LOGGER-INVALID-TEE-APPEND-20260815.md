# UAW AAB C30Y postbuild failure logger invalid Tee append

Date: 2026-08-15
Regression: `REG-20260815-2209-AAB-C30Y-POSTBUILD-FAILURE-LOGGER-INVALID-TEE-APPEND`
Status: resolved; Add-Content failure path and exit evidence verified

The attempt-01 catch path used an unsupported `Tee-Object` append form. Its
secondary error prevented the planned static exit file from being written.
The failed static log remains preserved.

The retry uses `Add-Content -LiteralPath` for a bounded catch message and then
writes and verifies the exit file independently. No source, artifact, count,
upload, Play or device action changed.

## Resolution

Attempt 02 used `Add-Content -LiteralPath` only in its catch path and created a
single zero exit-code evidence file after the successful full static matrix.
All executable postbuild suites then passed.
