# C30V PowerShell pipeline member-access whitespace parser rejection

Date: 2026-08-14
Successor: r60.47 recovery

## Incident

A bounded `Select-String` context projection was rejected at parse time because the pipeline variable member access was typed as `$_ .Line` instead of `$_.Line`.

The command executed no accepted owner read and made no repository, Google Play or OPPO mutation.

## Prevention

Avoid custom context projection for a single already-located token. First read the exact match line number, then use one bounded numeric `Get-Content` range. If a pipeline member is needed, keep `$_.Member` contiguous and parser-check the command before execution.
