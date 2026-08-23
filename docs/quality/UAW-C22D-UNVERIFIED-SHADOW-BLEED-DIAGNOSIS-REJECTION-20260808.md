# C22D unverified shadow-bleed diagnosis rejection — 2026-08-08

Clipping the global rail did not alter the rejected outer pixel for any family: it remained `[254,247,255]`. The shadow diagnosis was therefore not evidence-backed. REG-20260808-532 requires validating raster dimensions and boundary-local coordinates before another runtime correction. No build or device action occurred.
