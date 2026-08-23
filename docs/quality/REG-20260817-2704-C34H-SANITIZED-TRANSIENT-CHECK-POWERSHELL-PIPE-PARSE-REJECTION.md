# C34H sanitized transient-check PowerShell pipe parse rejection

Date: 2026-08-17 IST

## Mistake

After the C34H source seal, a read-only command intended to report three
credential-transient existence booleans placed a pipeline directly after a
`foreach` statement. PowerShell rejected the command at parse time. It did
not read a transient, mutate repository state, start a build, or perform an
external action. A corrected two-statement form later proved all three
transients absent.

## Root cause

The command compressed collection and serialization into an invalid
PowerShell statement shape instead of assigning the `foreach` result before
piping it to `ConvertTo-Json`.

## Permanent prevention

Sanitized multi-row PowerShell diagnostics must assign the loop output to a
task-specific variable, then serialize that variable in a separate statement.
Parser rejection is zero evidence and must never be silently retried.
