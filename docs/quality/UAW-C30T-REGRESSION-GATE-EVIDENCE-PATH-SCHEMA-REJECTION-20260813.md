# UAW C30T regression-gate evidence-path schema rejection — 2026-08-13

The regression-memory gate rejected REG-1810 because its `gates` array
contained the command label `PowerShell ConvertFrom-Json`. Registry gate values
are repository evidence paths, not narrative command names. The failed gate
stopped the composed command before formatter or analyzer execution. REG-1810
now references the exact machine-state JSON and regression-memory checker.
