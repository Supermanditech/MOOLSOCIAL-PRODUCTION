# C25F compaction evidence and registry-shape rejection

Date: 2026-08-09

## Rejection

The saved Screen04 Flutter execution cell `4441` was absent when resumed after
context compaction. Its truncated predecessor output cannot prove either pass
or failure. The first recovery inspection also guessed a nonexistent
`docs/quality/PERMANENT-REGRESSION-REGISTRY.jsonl` path, and the next inspection
guessed a `regressions` property instead of reading the actual `entries`
property.

## Corrective gate

- Treat the missing process result as no evidence and rerun only the bounded
  Screen04 test file.
- Resolve the registry through repository inventory, inspect its top-level
  properties, and append the mistake to the actual `entries` collection.
- Require the regression-memory gate before the test rerun.
- Never infer a qualifying result from a missing execution cell.

No build, install or protected-runtime authority was opened by this recovery.
