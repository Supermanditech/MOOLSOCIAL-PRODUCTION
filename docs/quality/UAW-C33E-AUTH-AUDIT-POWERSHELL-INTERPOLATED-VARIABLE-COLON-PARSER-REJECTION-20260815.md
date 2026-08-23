# UAW C33E auth audit PowerShell interpolated-variable colon rejection

Date: 2026-08-15

A bounded, read-only source-symbol lookup attempted to format an evidence line
as `$f:$line`. PowerShell interpreted the colon as part of the variable name
and rejected the command at parse time. The command produced no source
evidence and changed no repository, runtime, build, provider, Play or device
state.

The retry is permitted only after this registration and must delimit the file
variable explicitly as `${f}:...`. Future audit output uses the format operator
where practical so a colon never directly follows an interpolated variable.
