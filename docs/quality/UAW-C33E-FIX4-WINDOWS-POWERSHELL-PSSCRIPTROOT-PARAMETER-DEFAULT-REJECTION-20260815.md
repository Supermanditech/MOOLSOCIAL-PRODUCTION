# UAW C33E FIX4 Windows PowerShell PSScriptRoot parameter-default rejection

Date: 2026-08-15
Regression: `REG-20260815-2357-C33E-FIX4-WINDOWS-POWERSHELL-PSSCRIPTROOT-PARAMETER-DEFAULT-REJECTED`

PowerShell 7 passed the complete FIX4 gate, but Windows PowerShell 5.1 evaluated the `RepositoryRoot` parameter default before `$PSScriptRoot` was populated and rejected `Split-Path` with an empty path.

Recovery: keep the parameter default empty and resolve the repository root from `$PSScriptRoot` inside the script body. Rerun the complete gate on both hosts; the PowerShell 7 pass does not substitute for the failed Windows PowerShell cycle.
