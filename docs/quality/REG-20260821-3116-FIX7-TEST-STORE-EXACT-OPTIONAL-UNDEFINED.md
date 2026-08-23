# REG-20260821-3116 — FIX7 test-store exact-optional undefined

Date: 21 August 2026
State: registered; first strict typecheck failed

## Failure

The first FIX7 TypeScript typecheck reported two TS2379 errors in the new
in-memory test store. `markPending` and `markCompleted` assigned explicit
`undefined` to exact-optional `failedAt` and `failureStage` fields.

## Impact

- Production coordinator source was not reported in error.
- No test execution, deployment, build, provider, Play or OPPO action ran.

## Root cause

The test fake attempted to clear exact-optional properties by assigning
`undefined` instead of structurally omitting them.

## Prevention

Destructure stale optional failure/completion fields out of the stored record
and build the replacement from the remaining exact fields. Rerun strict
typecheck before compiled tests and retain the fixed-length/idempotent cases.
