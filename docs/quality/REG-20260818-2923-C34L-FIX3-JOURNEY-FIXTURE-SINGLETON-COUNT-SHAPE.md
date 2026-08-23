# REG2923 — FIX3 journey fixture singleton Count shape

## Observed event

After REG2922 correction, both journey owners parsed and the fresh direct PS7 fixture advanced beyond UTC validation, then StrictMode failed with `The property 'Count' cannot be found on this object.`

## Impact

- Runtime-normalized UTC plus exact raw `.fffZ`/cardinality validation is preserved.
- Offset, precision, duplicate, stale, file-root, and directory-leaf negatives are preserved.
- Windows PowerShell was not run; no later diagnosis, edit, retry, real journey, device, private, build, browser, provider, or external action occurred.

## Root cause boundary

A fixture collection boundary returned a scalar for a singleton result, while the checker accessed `.Count` without first normalizing zero/one/many shapes.

## Mandatory prevention

1. Identify the exact sanitized fixture collection at the failing assertion.
2. Normalize every zero/one/many boundary with `@(...)` before `.Count`, indexing, or equality checks.
3. Add explicit zero, singleton, and multiple-row shape fixtures where the source can unroll.
4. Parse both owners, rerun fresh PS7, then independent WinPS.
