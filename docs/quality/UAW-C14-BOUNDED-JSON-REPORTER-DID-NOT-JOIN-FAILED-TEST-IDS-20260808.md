# C14 bounded JSON reporter did not join failed test IDs

Date: 2026-08-08

Regression:
`REG-20260808-285-C14-BOUNDED-JSON-REPORTER-DID-NOT-JOIN-FAILED-TEST-IDS`

## Failure

The first complete 28-file universal cycle produced a bounded result of 210
passes and 38 failures, but the diagnostic summary emitted only numeric
`testDone.testID` values for most failures. It did not join those IDs to the
corresponding `testStart.test.name` and `test.url`, so the output was
insufficient for complete owner-by-owner diagnosis.

## Prevention

Bounded JSON diagnostics build an ID-to-name-and-URL map from `testStart`
events before rendering failed `testDone` entries. Until the suite is ready
for a new complete cycle, visible descriptions are mapped to exact files by a
bounded live-test source search and each owner runs independently. Numeric IDs
alone never authorize a test mutation.
