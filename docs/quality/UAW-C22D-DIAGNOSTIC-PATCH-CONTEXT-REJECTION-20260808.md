# C22D diagnostic patch-context rejection — 2026-08-08

The first combined shadow-revert and raster-coordinate diagnostic patch used the pre-format test-helper shape. `apply_patch` rejected the patch atomically and changed no runtime or test source. REG-20260808-533 requires current-file rereads and independent hunks.
