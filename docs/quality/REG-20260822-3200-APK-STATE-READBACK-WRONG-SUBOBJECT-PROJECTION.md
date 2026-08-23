# REG-20260822-3200 — APK state readback wrong subobject projection

## Incident

A post-edit APK gate state projection queried a wrong manifest-owning
subobject and returned null manifest fields. That projection was rejected as
readback evidence.

## Impact

- Fresh build authorization consumed: `false`
- APK builds: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The readback command reused an assumed state-object path instead of locating
the exact manifest property parent in the current JSON schema.

## Permanent prevention

For every state owner, locate the exact property with a bounded literal search
before projection, then parse and compare the established parent fields
without accepting null results.
