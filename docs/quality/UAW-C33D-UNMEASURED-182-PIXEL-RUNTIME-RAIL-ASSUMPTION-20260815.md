# C33D unmeasured 182-pixel runtime rail assumption

The first C33D source attempt changed the overflow decision on the assumption
that the production Ride rail receives exactly 182 logical pixels at a 320dp
surface. The new independent 181-pixel case passes, but the mounted Ride case
still finds the overflow viewport and fails its exact-fit expectation.

REG-2314 rejects another inferred-width edit. The next step is one bounded
focused diagnostic of the rendered adaptive-layout width. Diagnostic-only
output must be removed before qualification, and the failed run remains
preserved.
