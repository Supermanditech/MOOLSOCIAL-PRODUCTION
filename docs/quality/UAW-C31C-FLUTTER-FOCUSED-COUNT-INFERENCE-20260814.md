# UAW C31C Flutter focused-count inference

## Incident

The first combined C31C run asserted 39 authored tests by adding the new tests
to a remembered historical total. The exact selected three-file JSON event join
instead identified 28 authored tests before visual repair.

## Prevention

Qualification counts are derived from the exact current manifest and joined
`testStart` metadata. Historical narrative totals are never used as arithmetic
inputs for a changed file set.
