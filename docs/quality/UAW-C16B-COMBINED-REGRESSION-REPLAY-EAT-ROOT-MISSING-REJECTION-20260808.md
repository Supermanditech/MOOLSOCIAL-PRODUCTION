# C16B combined regression replay Eat-root missing rejection

## Incident

A combined Flutter invocation ran the established Screen 04 conformance file
and the C11 six-family placement/motion file. C11 passed all cases and Screen 04
passed every case except `every Mool main action and Social subaction stays
visible and exact`: after the Eat main-action tap, the test found no
`mvp-action-root-eat` owner at line 572.

No build, device, runtime or additional production mutation occurred after the
failure.

## Root cause and prevention

The cause is not inferred from a combined multi-file run. C16B first replays the
entire Screen 04 conformance file in isolation. Production source changes are
allowed only if the isolated failure reproduces and identifies an owned C16B
regression. Combined-run-only interference is recorded separately and cannot
be hidden by claiming the suite passed.
