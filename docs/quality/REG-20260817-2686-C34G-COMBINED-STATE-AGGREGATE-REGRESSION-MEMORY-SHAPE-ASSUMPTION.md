# REG2686 — C34G state/aggregate reset assumed identical shapes

## Outcome

The first reset attempted to assign the state-only `allEntriesAppliedBeforeSeal` property on the aggregate regression-memory object. PowerShell stopped before either new C34G JSON file was written, so the cloned bytes remain the only pre-reset state and no reset result is counted.

## Prevention

Assign only verified shared fields together and handle state-only fields separately. Write each C34G owner only after all in-memory mutations succeed, then parse both and compare named shared contract fields.
