# C24B2 ambiguous regression-gate patch rejection — 2026-08-09

A repeated-array patch added the new fixed-Home test to REG613 as intended, then matched REG614 instead of REG615. That would falsely claim the Home layout test prevents the destination-switch regression, which remains assigned to C24B3.

The corrected patch anchors each gate array to its unique regression id: REG613 and the Home portion of REG615 use the C24B2 test; REG614 remains contract-gated until its C24B3 connected-navigation test exists.

This mistake is permanently registered as `REG-20260809-621-C24B2-AMBIGUOUS-GATE-ARRAY-PATCH-STRENGTHENED-WRONG-REGRESSION`.
