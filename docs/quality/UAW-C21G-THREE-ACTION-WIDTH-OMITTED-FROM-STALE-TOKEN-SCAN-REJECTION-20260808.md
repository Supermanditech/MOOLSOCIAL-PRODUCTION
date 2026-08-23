# C21G three-action width omitted from stale-token scan — 2026-08-08

The second focused C21G run passed regression memory and all other evolved tests but rejected the historical adaptive inventory because it still expected the predecessor three-action cluster width `272`. C21 requires `268`. The first correction had searched an assumed `276` rather than inventorying the exact assertion.

The failed run is not host-cycle evidence. REG-20260808-489 requires a direct full-file inventory and zero retired `glassFill`, `0.985`, `212` or `272` expectations before retry. Runtime, build, install and OPPO state remain untouched.
