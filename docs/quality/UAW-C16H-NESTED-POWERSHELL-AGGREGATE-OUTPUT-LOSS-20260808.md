# UAW C16H nested PowerShell aggregate output loss — 2026-08-08

## Rejection

The first read-only source aggregate calculation exited zero but emitted no result because a here-string was passed through an unnecessary nested PowerShell process. No manifest, machine state, build authorization or device state was changed from that empty result.

## Prevention

The retry executes the aggregate function directly in the active workspace shell and requires explicit `runtime`, `contracts`, `tests`, `scoped_dirty`, `branch` and `head` lines. A missing line is a rejection and cannot be sealed.
