# C30W PowerShell object-property statement-if parser rejection — 2026-08-14

## Mistake

A read-only C30W owner-metrics command placed statement-form `if` expressions
directly on the right side of `Lines=` and `Length=` inside a
`[pscustomobject]` literal. PowerShell rejected the command at parse time with
`Missing closing '}' in statement block or type definition`.

## Impact

The command performed no product, release, build, upload, install, device,
provider, credential or repository-file mutation. It produced no admissible
owner inventory and was not retried before registration.

## Root cause

Conditional values were composed inline instead of being calculated into
ticket-specific scalars before object construction. This repeated the existing
repository lesson that statement-form PowerShell expressions are not valid as
bare property values.

## Prevention

Compute `Exists`, `Lines` and `Length` into explicit per-iteration scalars
before constructing the object. PowerShell diagnostic projections must contain
only scalar property assignments; statement-form `if`, `foreach` and similar
blocks remain outside object literals and formatter pipelines.

The permanent machine prevention owner is
`scripts/check-codex-development-regression-memory.ps1`.
