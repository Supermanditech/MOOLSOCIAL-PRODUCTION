# C25H REG850 nonpath gate descriptor rejection

Date: 2026-08-09

REG850 placed a descriptive audit name in its machine-readable `gates` array.
The permanent-memory checker correctly rejected it because that value was not a
repository file. The descriptor remains in prose; the gate array now contains
only the permanent-memory script path.
