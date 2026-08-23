# C24D PowerShell gate-loop LASTEXITCODE rejection — 2026-08-09

The first grouped qualification wrapper ran the regression-memory PowerShell
gate successfully, then compared the null native `$LASTEXITCODE` value with
zero and threw a false failure before invoking later gates.

The corrected wrapper uses `$?` immediately after each `.ps1` invocation under
`$ErrorActionPreference='Stop'`. Native exit status is not used for PowerShell
script success.
