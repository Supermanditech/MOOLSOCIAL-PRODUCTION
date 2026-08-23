# C20C rg no-match exit masked by memory gate — recurrence

- Date: 2026-08-08
- Scope: C20C source-token correction
- Mutation before observation: regression entry REG435 only
- Device/build/install impact: none; closed

## Observed recurrence

A successful regression-memory check preceded a required `rg` source query,
but only the first exit code was asserted. The query emitted no matches and its
nonzero status was not propagated.

## Permanent prevention

Required source queries run alone, or their `LASTEXITCODE` is captured and
asserted immediately before any other command executes.
