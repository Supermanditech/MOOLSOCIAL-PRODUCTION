# C24C gate protected HOME-variable rejection — 2026-08-09

The first C24C machine-gate execution stopped immediately because the script
assigned Eat source text to `$home`. PowerShell treats that name as `$HOME`, a
protected read-only environment variable that repository instructions prohibit
repurposing.

REG645 renames the task value to `$homeSource` and permanently binds this gate
to the regression-memory check.
