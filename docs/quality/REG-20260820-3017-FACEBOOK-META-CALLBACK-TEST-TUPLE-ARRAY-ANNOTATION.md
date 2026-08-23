# REG-20260820-3017 Facebook Meta callback test tuple-array annotation

## Incident

The first backend typecheck after adding Facebook signed callback coverage
failed in the malformed-input test table. Four `[Buffer, string]` cases were
cast as one two-element tuple instead of an array of two-element tuples, which
also made the loop variables widen to an invalid union.

## Impact

- TypeScript exited nonzero before tests.
- No provider, deployment, build, Play, OPPO or external state changed.
- No password, callback signature, identifier or secret value was involved.
- The failed typecheck is not accepted as evidence.

## Root cause

Angle-bracket tuple casting was applied to the outer array expression instead
of declaring `Array<readonly [Buffer, string]>` for the case table.

## Prevention

Use one explicitly typed tuple-array variable, allow inference inside each
case, then rerun typecheck, focused Facebook/Instagram callbacks and the full
backend suite before any deployment or provider callback save.
