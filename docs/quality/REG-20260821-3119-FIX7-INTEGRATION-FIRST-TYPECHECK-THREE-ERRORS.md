# REG-20260821-3119 — FIX7 integration first typecheck three errors

Date: 21 August 2026
State: registered; first integrated typecheck failed

## Failure

The first integrated FIX7 typecheck reported:

- one Instagram callback-test access to `confirmationCode` without retained
  discriminator narrowing;
- one duplicate object property in `index.ts`;
- Facebook callback construction missing its required account eraser.

## Impact

- No compiled tests, deployment, build, provider, Play or OPPO action ran.
- The isolated coordinator tests had already passed; this failure is limited
  to callback/runtime wiring and one test assertion.

## Root cause

A short insertion patch matched an earlier similar options-object boundary and
placed the Facebook eraser in the Instagram callback object. The test then
read a union-only field through an expression that TypeScript could not retain
as the narrowed variant.

## Prevention

Patch callback wiring only inside the exact named factory function, read the
complete options object after insertion, capture the narrowed deletion result
in a definite local before later assertions, then rerun strict typecheck before
compiled tests.
