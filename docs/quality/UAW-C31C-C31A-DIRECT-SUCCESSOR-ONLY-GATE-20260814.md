# UAW C31C C31A direct-successor-only gate

## Incident

The first predecessor replay with C31C active stopped at the C31A machine
execution boundary. C31A correctly recorded C31B as its direct successor, but
its gate had no bounded rule for verifying C31B's separately recorded C31C
successor.

## Impact

The C31A gate failed closed; C31B and C31C gates did not run in that call. No
source qualification, build, deployment, device or live-data action passed on
the failed result.

## Prevention

C31A may accept the active C31C child only after checking the exact C31A to
C31B machine-state hop, the exact C31B to C31C hop and both regression-
preservation booleans. No narrative or inferred descendant is accepted.
