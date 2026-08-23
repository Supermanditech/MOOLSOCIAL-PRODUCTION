# C14 r60.12 boxed 48px family rail remains visually heavy

Date: 2026-08-07

Regression:
`REG-20260807-279-C14-R60-12-BOXED-48PX-FAMILY-RAIL-REMAINS-VISUALLY-HEAVY`

## Founder-visible defect

The r60.12 family rail obeyed the 48px maximum and preserved 44px targets, but
its separate family tile, per-action boxes and filled selected tile made the
layer look larger and heavier than the founder's category-strip direction.
The result competed with Buy grids and did not read as one lightweight family.

## Permanent prevention

The shared strip is no taller than 44 logical pixels and every keyed action
still measures at least 44-by-44. The surface is transparent or at most 45%
neutral tint, with no raised card shadow. Actions have no individual box
border; selection uses text/icon tint and a two-pixel identity line. A thin
family accent connector and the selected global action below establish family
ownership without a separate family tile. Social, Buy, Eat, Ride, Book and
Work must all pass host geometry plus first-frame OPPO screenshots.

Design evidence:
`artifacts/quality/uaw-personal-mvp-direct-default-subaction-landing-fix1-c13-design-reference-20260807-01/01-founder-myntra-category-reference.jpg`.
