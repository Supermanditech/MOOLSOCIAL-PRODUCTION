# REG2924 — FIX3 journey WinPS offset-negative class drift

## Observed event

The corrected journey fixture passed on PowerShell 7 with six production adapters missing fail-closed, six derived rows, fifteen negatives, and zero external/browser/device/private actions. The first Windows PowerShell run then exited 1 because the offset negative did not fail with the checker's expected sanitized class.

## Impact

- The PS7 run is positive qualification evidence for that host.
- The WinPS run is not qualification evidence.
- Both owners parsed in PS7; no later diagnosis, correction, retry, real journey, device, private, build, browser, provider, or external action occurred.

## Root cause boundary

The intentionally offset timestamp reached a different validation or serialization class on Windows PowerShell than the fixture oracle expected. The exact observed class was intentionally not inspected before registration.

## Mandatory prevention

1. Capture only the sanitized WinPS rejection class for the offset fixture.
2. Prefer a host-invariant raw-wire defect that preserves a semantically canonical decoded value while violating one exact raw property/cardinality rule.
3. If two host-specific classes are intrinsically correct, accept only the enumerated exact classes and keep the semantic rejection invariant explicit.
4. Rerun a fresh WinPS fixture and then refresh PS7 only if owner bytes changed.
