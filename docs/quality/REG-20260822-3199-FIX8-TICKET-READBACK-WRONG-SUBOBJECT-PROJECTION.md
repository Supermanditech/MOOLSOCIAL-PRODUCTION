# REG-20260822-3199 — FIX8 ticket readback wrong subobject projection

## Incident

A post-edit FIX8 ticket projection queried a nonexistent
`sourceQualification` subobject and returned null manifest fields. That
projection was rejected as readback evidence.

## Impact

- Fresh build authorization consumed: `false`
- APK builds: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The readback command assumed the manifest-owning subobject instead of locating
its established property name first.

## Permanent prevention

Locate the exact manifest property with a literal bounded search before
projecting its parent object. Reject null or ambiguous projections rather than
inferring a successful state update.
