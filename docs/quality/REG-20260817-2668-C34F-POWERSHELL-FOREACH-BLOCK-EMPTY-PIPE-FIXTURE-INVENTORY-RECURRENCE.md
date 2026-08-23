# C34F PowerShell foreach block empty-pipe fixture inventory recurrence

Date: 2026-08-17 IST

Status: registered pre-seal; corrected explicit pipeline required

During read-only C34F reconciliation after REG2667, the combined inventory
again placed a formatter pipe immediately after a statement-level `foreach`
block. PowerShell rejected the command as an empty pipe element. No inventory
result was produced and no file changed.

Keep scalar state reconciliation separate. For fixture inventory, pipe the
exact fixture-path array to `ForEach-Object`, pipe those emitted objects to the
formatter, require parser success, and count no result from the rejected
command. No source seal, test, build, browser, Play or OPPO action occurred.
