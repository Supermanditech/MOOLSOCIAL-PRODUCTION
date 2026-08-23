# REG-20260821-3115 — FIX7 index owner-claim overlap

Date: 21 August 2026
State: registered; index mutation blocked pending primary resolution

## Failure

After the primary claimed the new FIX7 coordinator owners, coordination
rejected because `backend/functions/src/index.ts` was already held by another
active task.

## Impact

- The new isolated coordinator and unit-test files exist.
- No index wiring, callback change, build, provider, Play or OPPO action ran.
- The overlap was not bypassed.

## Root cause

The primary added an existing shared runtime owner without first projecting
the current active owner-to-task map.

## Prevention

The primary must identify the exact existing claimant, confirm it is inactive
or transfer the owner explicitly, leave only one canonical claim, parse the
policy and replay coordination before any index mutation. Future shared-owner
claims require an immediate owner-to-task preflight.
