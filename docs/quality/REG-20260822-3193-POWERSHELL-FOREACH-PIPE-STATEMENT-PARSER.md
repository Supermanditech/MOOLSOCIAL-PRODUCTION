# REG-20260822-3193 — PowerShell foreach-pipe statement parser

## Incident

During read-only FIX8 reconstruction, Codex composed a `foreach` statement
directly before a pipeline. Windows PowerShell rejected the command with
`An empty pipe element is not allowed` before any file inventory completed.

## Impact

- Repository mutations: `0`
- External actions: `0`
- APK builds: `0`
- OPPO actions: `0`

## Root cause

The command used a compound statement as a pipeline producer without an
enclosing expression and also combined owners that should have been read by
independent scalar commands.

## Permanent prevention

Mandatory owners are read with one independently valid PowerShell command and
result each. Any genuine aggregation first constructs a bounded array before
piping, and syntax failures are registered before another attempt.
