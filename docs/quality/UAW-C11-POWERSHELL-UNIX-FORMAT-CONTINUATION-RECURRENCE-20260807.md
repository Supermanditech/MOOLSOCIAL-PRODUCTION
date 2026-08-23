# C11 PowerShell Unix formatter-continuation recurrence

Date: 2026-08-07

Regression ID:
`REG-20260807-243-C11-POWERSHELL-UNIX-FORMAT-CONTINUATION-RECURRENCE`

The first C11 Dart formatting command used Unix `\` line continuation inside
PowerShell and failed during parsing before Dart started. This repeated the
exact formatter-command class already registered as REG-013.

The source files were not formatted or otherwise changed by the rejected
command. The corrected invocation passes a PowerShell string array to Dart in
one native call and checks its exit code immediately.

Permanent prevention: PowerShell commands never use Unix continuation syntax.
Multi-file native arguments are always assembled as an explicit array or use
PowerShell's own continuation only when unavoidable.
