# C11 diagnostic repeated stale LASTEXITCODE after PowerShell gate

- Regression: `REG-20260807-255-C11-DIAGNOSTIC-REPEATED-STALE-LASTEXITCODE-AFTER-POWERSHELL-GATE`
- Recurrence of: `REG-20260807-076`, `REG-20260807-156`,
  `REG-20260807-178`
- Date: 2026-08-07 IST

## Observation

The first bounded Buy diagnostic command invoked the regression-memory
PowerShell checker, then inspected stale `$LASTEXITCODE`. The checker visibly
passed, but Flutter did not start and the combined wrapper exited zero.

## Permanent correction

Repository PowerShell gates and app-root Flutter diagnostics are separate tool
commands. PowerShell success means return without a terminating error. Flutter
output is captured first, its native exit is stored immediately, and only then
are JSON events parsed for bounded failing names and errors.
