# C15 IgnorePointer ancestor-count false rejection

Date: 2026-08-08

Regression ID:
`REG-20260808-295-C15-IGNORE-POINTER-ANCESTOR-COUNT-FALSE-REJECTION`

The first C15 focused run rejected all six normal-motion cases because the test
expected exactly one `IgnorePointer` ancestor above the keyed wave. Each wave
had the required direct `IgnorePointer(ignoring: true)` owner plus an unrelated
framework ancestor with `ignoring: false`. The reduced-motion matrix passed,
and the failure occurred before the directional motion assertions.

Root cause: the test counted widget types across the entire ancestor chain
instead of asserting the required behavioral property on the matching owner.

Permanent prevention: noninteractive-overlay tests enumerate matching
ancestors and require exactly one owner with `ignoring == true`; unrelated
non-ignoring framework ancestors are not treated as duplicate interaction
owners. Semantics exclusion is asserted by the presence of an excluding
ancestor rather than by a total ancestor-type count.
