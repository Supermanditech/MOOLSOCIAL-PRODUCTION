# C13 connected batch compact output truncated failure names

Date: 2026-08-07

Regression:
`REG-20260807-275-C13-CONNECTED-BATCH-COMPACT-OUTPUT-TRUNCATED-FAILURE-NAMES`

## Failure

After the FIX2 file passed independently, the six-file connected C13 batch
ended with 61 passes and six failures. Repeated startup logs made the compact
report exceed the tool output boundary, so the actual six failure names and
their stack context were not visible.

## Prevention

The truncated batch is retained only as a failed lead and is not used for
diagnosis or acceptance. Each remaining exact, inventory-proven test file runs
independently with its own exit result and bounded expanded output. The full
connected batch restarts only after every named owner passes independently;
future durable full-cycle evidence uses the established bounded reporter.
