# REG3158 - PowerShell single nested range flattening

## Classification

Registered partial read rejected with zero source mutation.

## Evidence

PowerShell flattened the single nested range arrays for two files, causing `Math.Min` argument-type errors. Only bridge ranges emitted. The partial output was not accepted as a completed source audit.

## Prevention

Use explicit integer start/end scalars or named range objects, enable terminating errors, and reject partial projections.
