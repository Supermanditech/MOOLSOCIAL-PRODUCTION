# C30U PowerShell foreach inline-pipe parser error

## Incident

A read-only inventory of required documents piped directly from a PowerShell
`foreach` statement. The parser rejected the command, so it produced no usable
inventory evidence.

## Root cause

The statement output was not assigned to an explicit collection before the
formatting pipeline.

## Permanent prevention

Assign `foreach` output to a task-specific collection variable and pipe only
that collection. Treat the failed command as zero evidence and verify the
bounded retry's exit status.

No source, release, deployment or device state changed.
