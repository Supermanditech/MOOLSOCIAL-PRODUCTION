# UAW C31C Flutter expanded pass-line anchor

## Incident

The focused C31C Flutter test completed with native exit zero and visibly
reported all 15 authored tests plus `All tests passed!`. An auxiliary summary
regex looked for lines beginning directly with `+N:` and emitted a false zero
because the expanded reporter prefixes each line with elapsed time.

## Impact

No test failed and no source or runtime state changed. The native result and
visible authored test names remain useful diagnostic evidence, but the derived
`expandedPassLines=0` value is inadmissible as a qualification count.

## Prevention

Counted Flutter qualification uses the JSON reporter. It joins `testDone`
events to their `testStart` metadata, excludes only loading or synthetic tests,
reports exact pass/skip/fail totals and preserves the native exit. Every failed
authored test name is printed before retry.
