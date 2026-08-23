# UAW C30T Social backend operation-search PowerShell quote rejection — 2026-08-13

## Outcome

The backend operation-owner retry embedded mixed single/double-quote regex
syntax in a PowerShell double-quoted command. PowerShell parsed the intended
alternation bar as a shell pipe and rejected the command before any search ran.

No audit evidence or state change resulted.

## Permanent prevention

Use separate simple fixed-string ripgrep searches for backend operation names.
Do not combine quote-literal matching and regex alternation inside a PowerShell
double-quoted command when the audit targets are already known strings.
