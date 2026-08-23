# REG-20260816-2543 — FIX1 gate cannot replay after parent reselection

## Observed failure

The first post-FIX1 C33L cycle passed source comparison, regression memory,
delivery discipline, MVP scope, approved UI locks, and the C33L parent gate on
both PowerShell hosts. The next FIX1 prevention-gate step rejected with
`ticket id differs from the build candidate` because the gate still required
FIX1 to be the active scope ticket after control had correctly returned to the
parent C33L candidate.

No Flutter retry, analyzer, backend test, Hosting test, AAB, Play action, OPPO
mutation, email, SMS, provider write, or secret access occurred.

## Root cause

The FIX1 gate covered only child-active implementation qualification. It lacked
a fail-closed parent-replay path that proves the exact qualified child ticket,
hash, state, and evidence remain pinned in the parent MVP scope state.

## Required repair

Ticket `UAW-C33L-FIX2-FIX1-GATE-PARENT-REPLAY-COMPATIBILITY` must preserve the
child-active path and add only a parent C33L replay path tied to the exact
qualified FIX1 assessment. Every other selected ticket must be rejected. The
partial cycle and prior manifest remain immutable failed-attempt evidence; both
complete C33L cycles restart from zero under a fresh source seal.
