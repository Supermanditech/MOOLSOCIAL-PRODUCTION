# C12 48px rail two-pixel inset produced 43px target

- Regression: `REG-20260807-267-C12-48PX-RAIL-TWO-PIXEL-INSET-43PX-TARGET`
- Phase: focused widget qualification

The first C12 geometry run kept the complete family rail at 48 logical pixels,
but the Social control and the shared Eat/Ride/Book/Work control measured only
43 logical pixels at the keyed tap owner. Buy passed. The two-pixel vertical
inset on each side left exactly 44 nominal pixels, and final layout rounding
removed one pixel from the interactive owner.

Prevention: keep the outer family rail exactly 48px, reduce only its internal
vertical inset to one pixel per side, retain each cell's explicit 44px minimum,
and measure the actual keyed tap owner in all six destinations at normal and
compact/large-text sizes.
