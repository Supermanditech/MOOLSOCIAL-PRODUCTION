# C10C regression-registry property guess

## Observation

A read-only inspection queried a guessed `regressions` property and printed a misleading zero count. The durable registry uses the top-level `entries` property.

## Permanent prevention

Registry operations first inspect and validate the actual top-level schema, then address `entries`. No mutation was made from the incorrect read.
