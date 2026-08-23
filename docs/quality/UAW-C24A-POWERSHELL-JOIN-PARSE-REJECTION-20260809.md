# C24A PowerShell join parse rejection — 2026-08-09

The first C24A verification command used an invalid `@(...) -cjoin ','` expression inside an `if` condition. PowerShell rejected the command at parse time, so no reference, contract or source verification ran and no completion claim was made.

The retry assigns each joined action list to a ticket-specific scalar using the valid parenthesized `-join` form before comparison.

This mistake is permanently registered as `REG-20260809-610-C24A-POWERSHELL-JOIN-OPERATOR-PARSE-ERROR`.
