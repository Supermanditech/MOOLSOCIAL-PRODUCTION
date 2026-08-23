# C24B2 semantics-label finder duplicate rejection — 2026-08-09

The all-actions semantics test searched for the `Social` label and matched both the outer semantic button and its visible text. The tap action existed, but the two-candidate finder rejected.

The test now identifies the unique keyed family/action widget and reads that owner's semantics data. This mistake is permanently registered as `REG-20260809-623-C24B2-SEMANTICS-LABEL-FINDER-MATCHED-NODE-AND-TEXT`.
