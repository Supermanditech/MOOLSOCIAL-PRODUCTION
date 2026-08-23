# C20D first state-transition patch context rejection

- Date: 2026-08-08
- Intended transition: C20C complete to C20D selected
- Mutation from rejected patch: none
- Device/build/install impact: none; closed

## Rejection

One long scope exclusion was retyped with a missing underscore, so the atomic
multi-file patch could not verify its context and wrote nothing.

## Permanent prevention

State transitions use small exact-context patches. Long JSON state and array
literals are copied from a fresh bounded read rather than reconstructed.
