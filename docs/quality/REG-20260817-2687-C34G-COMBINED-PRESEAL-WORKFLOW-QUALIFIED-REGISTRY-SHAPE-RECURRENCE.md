# REG2687 — C34G pre-seal workflow shape recurrence

## Outcome

The second in-memory reset attempted another state-only property on aggregate: `qualifiedRegistryEntryCount`. It stopped before either C34G JSON owner was written, so no reset is counted.

## Prevention

Enumerate nested state and aggregate property names, use only their intersection in shared assignments, and assign every owner-specific property explicitly before writing.
