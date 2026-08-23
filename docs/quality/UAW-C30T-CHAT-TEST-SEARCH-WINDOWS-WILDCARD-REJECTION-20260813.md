# C30T Chat test-search Windows wildcard rejection — 2026-08-13

## Finding

A read-only `rg` command used wildcard path components on Windows. The paths were rejected before any search ran.

## Containment and prevention

No file or external state changed. The corrected search uses the concrete `apps/mobile/test` root with `--glob` filters rather than wildcard path arguments.
