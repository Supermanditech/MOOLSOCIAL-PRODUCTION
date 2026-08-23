# REG-20260817-2745: C34L evidence-fixture mixed-separator root rejection

## Truthful event

All three assigned evidence/recovery scripts parsed in PowerShell 7 and Windows
PowerShell. The first PowerShell 7 positive retained-evidence fixture then
stopped before evidence validation with
`fixture aggregate state escaped the exact fixture root.`

Read-only diagnosis identifies a separator-normalization mismatch: the state
path was normalized to `/`, while `Split-Path -Parent` can return a Windows
`\` parent and the aggregate relative path remains `/`. The failed fixture is
preserved under
`tmp/c34l-retained-evidence-fixtures-a82e2f115ef44d96a865d255dd5dd491`.

No production state, source seal, cycle, AAB, device, Google Play, credential,
secret, deployment, or external state changed.

## Root cause

The fixture root derived from the normalized relative state path was not itself
normalized before exact aggregate-root comparison.

## Prevention

- Normalize every repository-relative fixture path and derived parent to `/`
  before exact comparison.
- Assert detailed, aggregate, and evidence roots share one normalized prefix.
- Preserve the failed fixture and rerun under a new unique fixture root only
  after registration and source correction.

## Candidate consequence

C34L remains selection-only at zero release actions. The failed positive
fixture is zero retained-evidence qualification and no real owner was read or
advanced.
