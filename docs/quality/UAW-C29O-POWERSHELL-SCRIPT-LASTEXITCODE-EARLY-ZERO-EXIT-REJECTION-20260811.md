# C29O PowerShell-script LASTEXITCODE early-zero exit rejection

Date: 2026-08-11

The C29O source gate passed, but a compound root command tested
`$LASTEXITCODE` after a PowerShell script invocation. That variable is not the
script success authority in this path; its null/stale value caused an early
`exit` before the delivery, scope and regression gates, while the shell still
reported zero.

Permanent prevention: parent qualification commands set
`$ErrorActionPreference='Stop'` and invoke PowerShell gate scripts directly.
Thrown gate failures terminate the command. `$LASTEXITCODE` is reserved for
native executables and is never used to sequence `.ps1` gates.
