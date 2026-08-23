# C27B state-bound gate successor-preflight rejection

## Observation

After C27B completed and C27C became the active authorized child, the durable
C27B source gate rejected because it required the active scope ticket to remain
C27B. Its runtime/source assertions were still applicable and unchanged.

## Cause

The new gate copied selection-time authorization checks into a durable
component contract without distinguishing `active` from `complete` ticket
state, repeating the predecessor state-bound-gate pattern recorded by REG895.

## Permanent prevention

Component gates require exact active scope authorization only while their ticket
manifest is active. Once the manifest is complete, the gate validates the
completed manifest and durable source/test contract without forcing the global
scope machine to remain on an earlier child.

## Resolution evidence

C26C and C27C passed before C27B reached the stale state assertion. The
rejection is registered before the C27B gate is made successor-safe.
