# UAW C31C Flutter path-qualified loading event

## Incident

The first C31C Flutter JSON event join completed with native exit zero, no
error events and no failed test events, but reported 16 authored passes for the
focused file whose expanded output showed 15 authored tests. Flutter named the
synthetic loader event `loading <file URL>`, so an exact `loading` comparison
did not exclude it.

## Impact

The test suite passed. Only the derived authored-test count was overstated and
is inadmissible qualification evidence.

## Prevention

The counted join preserves raw `testDone` separately and excludes a test only
when its `testStart` metadata is hidden, named exactly `loading`, or begins with
`loading `. The resulting authored count is compared with the current bounded
test-name inventory before qualification is accepted.
