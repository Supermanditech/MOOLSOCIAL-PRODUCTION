# REG-20260822-3198 — Registry inspection wrong collection name

## Incident

A read-only registry inspection queried a nonexistent `regressions`
collection and failed before returning the last entry.

## Impact

- Fresh build authorization consumed: `false`
- APK builds: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The query assumed a collection name instead of using the registry's
established `entries` property.

## Permanent prevention

Inspect or retain the top-level schema before indexing, use the exact
`entries` property for bounded last-entry readback, and register any failed
query before issuing its corrected form.
