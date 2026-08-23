# C30Z PowerShell single-range nested-array unrolling recurrence

Date: 2026-08-15
Regression: `REG-20260815-2217-C30Z-POWERSHELL-SINGLE-RANGE-NESTED-ARRAY-UNROLLING-RECURRENCE`
Status: resolved; direct scalar-range loop emitted the required checker region

## Finding

A bounded C30X checker inspection iterated `@(@(610,715))`. PowerShell
unrolled the nested pair, so the loop did not receive a stable start/end
object and emitted no source lines. The empty result is not inspection
evidence.

## Prevention

A single excerpt uses direct scalar start/end values and one `for` loop.
Multiple excerpts use strongly typed objects with named fields. Nested integer
arrays are not used for required reads. No source, build, Play, OPPO, provider,
credential or external-service state changed.
