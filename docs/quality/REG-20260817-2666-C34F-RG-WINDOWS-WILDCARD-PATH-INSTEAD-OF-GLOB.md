# C34F rg Windows wildcard path instead of glob

Date: 2026-08-17 IST

Status: registered pre-seal; use `--glob` before retry

A read-only `rg` inventory passed `docs/quality/UAW-C34F-*20260817.md` as a
literal Windows path. Windows rejected the path syntax, while the other exact
file arguments still returned partial results. No file changed and the result
cannot count as a complete inventory.

Use a real directory argument plus `--glob 'UAW-C34F-*20260817.md'`, require a
clean native exit, and combine its output with exact file arguments only after
the glob query succeeds.
