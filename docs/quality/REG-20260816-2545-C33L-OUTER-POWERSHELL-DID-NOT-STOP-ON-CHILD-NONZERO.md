# REG-20260816-2545 — outer PowerShell did not stop on child nonzero

The checkpoint shell used external `pwsh` processes. A child nonzero exit does
not become a terminating PowerShell error merely because
`$ErrorActionPreference` is `Stop`, so later read-only gates ran after regression
memory had rejected.

Every future external stage must be followed immediately by an explicit
`$LASTEXITCODE` assertion. No Flutter, analyzer, backend, Hosting, build, Play,
OPPO, provider, email, SMS, or secret action occurred in this failed batch.
