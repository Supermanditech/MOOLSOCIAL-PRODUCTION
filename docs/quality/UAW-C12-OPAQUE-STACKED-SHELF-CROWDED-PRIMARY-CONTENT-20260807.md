# C12 opaque stacked shelf crowded primary content

- Regression: `REG-20260807-264-C12-OPAQUE-STACKED-SHELF-CROWDED-PRIMARY-CONTENT`
- Ticket: `UAW-PERSONAL-MVP-TRANSLUCENT-SUBACTION-FAMILY-RAIL-FIX1-C12`
- Phase: OPPO visual qualification

The checksum-matched r60.11 device candidate used an almost opaque shared
surface plus destination-local controls whose combined height reached 56–70
logical pixels. The shelf was reachable but visually competed with Buy
product grids and other primary content, so it failed founder device review.

The source-level cause was validating placement, one-tap reachability and
minimum targets without bounding the complete shared rail envelope or its
opacity. A technically correct lower control therefore passed host tests while
remaining too visually heavy on the real device.

Permanent prevention: all six destinations must compose the same shared
family rail; its envelope is at most 48 logical pixels, every action remains
at least 44-by-44, the surface is translucent and low-shadow, the family
relationship is explicit, the global rail is unchanged, and an OPPO
screenshot matrix must pass before founder acceptance.
