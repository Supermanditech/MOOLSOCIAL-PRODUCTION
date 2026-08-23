# C24D universal-intent lazy-package rejection — 2026-08-09

The universal-intent Ride production journey used an immediate-presence helper
for package cards after C24D moved them below destination, places and pickup
time in one vertical home. The package was reachable but not yet constructed.

The corrected journey uses the keyed Ride ListView with a bounded downward
scroll, requires exactly one package owner, reveals it and performs the real
tap after each connected type switch.
