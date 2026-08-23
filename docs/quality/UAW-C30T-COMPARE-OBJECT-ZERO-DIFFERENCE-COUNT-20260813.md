# C30T Compare-Object zero-difference Count failure — 2026-08-13

## Failure

The exact credential-fixture filename comparison returned no differences. Under strict mode, the null pipeline result did not expose `.Count`, so qualification cycle 1 stopped in readiness.

## Impact

No AAB, upload, install, device or external mutation occurred. Build count remains zero.

## Prevention

Every possibly empty PowerShell pipeline result must be wrapped in `@()` before its cardinality is read.
