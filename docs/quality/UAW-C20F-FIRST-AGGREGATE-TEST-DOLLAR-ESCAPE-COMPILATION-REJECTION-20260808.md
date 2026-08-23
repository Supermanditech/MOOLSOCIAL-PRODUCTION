# C20F first aggregate test — dollar-escape compilation rejection

- Date: 2026-08-08
- Scope: C20F test/gate-only implementation
- Runtime/device/build/install impact: none; closed

## Rejection

Two intended literal C20B source tokens contained `$label`. Their escape was
lost through the patch input layer, so Dart treated `label` as an undefined
interpolation identifier and rejected compilation.

## Permanent prevention

Interpolation-sensitive source tokens use Dart raw strings. Nested tool-input
escaping is not used to preserve literal dollar signs.
