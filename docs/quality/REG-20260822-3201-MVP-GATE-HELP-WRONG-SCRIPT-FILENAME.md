# REG-20260822-3201 — MVP gate help wrong script filename

## Incident

A read-only `Get-Help` lookup used a nonexistent
`check-mvp-scope-gate.ps1` filename and failed to return the MVP gate
parameters.

## Impact

- Fresh build authorization consumed: `false`
- APK builds: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The checker filename was assumed from its conceptual name instead of being
resolved from the scripts directory first.

## Permanent prevention

Resolve exact checker paths with `rg --files` before `Get-Help` or invocation,
and register a failed lookup before retrying with the discovered filename.
