# C24H aggregate text-scale integer-cast rejection

Date: 2026-08-09
Regression: `REG-20260809-746-C24H-AGGREGATE-GATE-TEXT-SCALE-CAST-TO-INTEGER`

The first aggregate gate rejected the valid C24 maximum text scale `1.4`
because the gate cast that value to `[int]` before comparison. The cycle did
not start. Tap-size and fractional text-scale checks must use their correct
numeric types and produce distinct rejection messages.

The aggregate gate now checks the 44 px target as `[int]` and maximum text
scale as `[double]`, with distinct diagnostics for each contract value.
