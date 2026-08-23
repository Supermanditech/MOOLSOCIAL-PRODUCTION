# C16E Ride lazy-package test rejection

The first C16E focused run passed the compact rail, semantics, route identity
and in-place Cab state assertions, then failed because `ensureVisible` was
called before the lazy booking `ListView` had built the selected Cab package.

No production defect was indicated and no production source changed. The
corrected proof scrolls the existing keyed booking content in bounded steps
until the selected package is built, then verifies its hit target is reachable
above the local navigation rail.
