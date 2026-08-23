# C27C formatted indicator-chain static-gate rejection

## Observation

The first C27C source gate required the class and selected-indicator property on
one physical line. Dart formatting wrapped the legal chain between
`MoolLocalNavigationTokens` and `.switcherSelectedIndicatorWidth`, so the gate
rejected a valid shared-token implementation.

## Cause

The static check depended on formatting adjacency instead of the distinctive
property suffix inside the already-bounded menu owner.

## Permanent prevention

Within a narrowly bounded owner slice, source gates match distinctive property
suffixes when Dart may wrap the qualifier chain. Widget tests prove the exact
2 by 18 rendered indicator.

## Resolution evidence

The formatted owner slice was inspected and this rejection registered before
the gate was changed or rerun.
