# C30Q post-build PowerShell fixed-path rejection

Date: 2026-08-12

## Mistake

The first independent C30Q post-build verifier invocation assumed that PowerShell 7 was installed at `C:\Program Files\PowerShell\7\pwsh.exe`. On this machine the qualified executable is the Microsoft Store package exposed through `Get-Command pwsh`, so the fixed path was not executable and the read-only verifier did not run.

## Impact

- No build, artifact, machine state, provider state, device state, credential, or secret was changed.
- The sealed C30Q AAB remained successful and unchanged.
- The transient Firebase define file was independently confirmed absent before the rejected verifier command.

## Permanent prevention

Resolve `pwsh` with `Get-Command pwsh` and invoke the returned exact executable owner. Never infer a conventional PowerShell 7 installation path on this machine.
