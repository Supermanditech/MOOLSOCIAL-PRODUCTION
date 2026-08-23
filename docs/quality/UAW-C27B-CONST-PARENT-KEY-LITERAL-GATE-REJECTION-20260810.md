# C27B const-parent key-literal gate rejection

## Observation

The first C27B source-gate run required the contiguous literal
`key: const Key('mool-compact-launcher-icon-label')`. Dart formatting kept the
parent `MoolDestinationIconLabel` constructor const and therefore emitted the
child as `key: Key(...)`. The runtime and widget test were valid, but the gate
rejected.

## Cause

The static gate encoded one equivalent const spelling instead of the stable key
value and the independently asserted const component owner.

## Permanent prevention

Static source gates assert stable semantic keys and behavior tokens without
requiring redundant `const` placement that Dart formatting may legally move to
the parent constructor. Widget tests remain the authority for rendered type and
geometry.

## Resolution evidence

The rejection occurred before any retry. The exact formatted source was
inspected and the gate will require the stable key literal only.
