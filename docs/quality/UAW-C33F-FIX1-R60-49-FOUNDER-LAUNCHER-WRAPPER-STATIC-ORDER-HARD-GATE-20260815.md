# UAW C33F FIX1 r60.49 launcher/wrapper static-order hard gate

Date: 2026-08-15

## Finding

The current founder launcher and generic AAB wrapper are retargeted to C33F,
but the preserved C30V and C30X static gates validate historical contracts.
They do not independently prove the exact r60.49 pre-prompt and pre-consumption
ordering.

## Authorized repair

The selected C33F gate will fail closed unless it proves the exact current
launcher and wrapper bindings, invocation cardinality, secret-output boundary,
and gate/preflight/consumption/appbundle order. The prior source manifest is
invalidated intentionally. No build or external authority may be consumed until
a new immutable manifest and two identical full cycles pass and all four live
readiness facts qualify.
