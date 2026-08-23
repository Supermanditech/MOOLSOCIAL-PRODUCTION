# C24H empty patch hunk boundary rejection

Date: 2026-08-09
Regression: `REG-20260809-751-C24H-MULTIFILE-PATCH-CONTAINED-EMPTY-HUNK-BOUNDARY`

The first child-gate inventory correction contained a standalone empty `@@`
hunk before the next file update. `apply_patch` rejected the entire patch, so
no partial change was accepted. The retry splits contract/qualifier changes
from registry/evidence status changes and uses only populated hunks.
