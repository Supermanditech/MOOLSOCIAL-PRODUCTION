# C14 bounded JSON metadata interpolation recurrence

Date: 2026-08-08

Regression:
`REG-20260808-288-C14-BOUNDED-JSON-METADATA-INTERPOLATION-RECURRENCE`

## Failure

The second complete universal JSON cycle counted 250 completed tests, 231
passes and 19 failures, but every failed label rendered as an empty URL and
name. The test-ID map existed, yet the metadata string used invalid
PowerShell braced-expression interpolation.

## Root cause and prevention

The prior recurrence fix added the missing map but did not validate one
joined label before the long cycle. The bounded parser now uses PowerShell
subexpressions `$($event.test.url)` and `$($event.test.name)`, rejects empty
testStart labels, and emits an explicit unmapped ID if a join is unavailable.
The blank failure list is discarded and authorizes no source or test change.
