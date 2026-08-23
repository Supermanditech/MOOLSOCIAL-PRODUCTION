# C34F PowerShell foreach block empty-pipe fixture inventory

Date: 2026-08-17 IST

Status: registered pre-seal; explicit pipeline required

A read-only C34E fixture inventory placed a pipeline immediately after a
statement-level `foreach` block, and PowerShell rejected it as an empty pipe
element. No fixture result was produced and no file changed.

Use `Get-ChildItem | ForEach-Object { ... } | Format-Table`, require parser and
native exit success, and count no inventory result from the rejected command.
