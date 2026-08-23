# C30T PowerShell inline-if expression recurrence

Date: 2026-08-13

Two bounded read-only inventory commands failed because they embedded a PowerShell `if` statement directly inside a parenthesized expression. PowerShell parsed `if` as a command name in that position. The failures changed no files, device state or external state.

Permanent prevention: compute conditional values in a preceding statement and then format the result. Do not use statement-form `if` inside string or arithmetic expressions in ad hoc PowerShell audit commands.
