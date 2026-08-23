# Post-C32P PowerShell script LASTEXITCODE null rejection

Date: 15 August 2026
Regression: `REG-20260815-2269-POST-C32P-POWERSHELL-SCRIPT-LASTEXITCODE-NULL-REJECTION`

The regression-memory gate printed an explicit pass for 2,239 entries. Its caller then falsely threw because it checked the unset native-process `$LASTEXITCODE` variable after invoking a PowerShell script. The gate did not fail; later commands in that diagnostic block did not run.

Subsequent repository PowerShell gate calls must use PowerShell success semantics and terminating errors. `$LASTEXITCODE` is reserved for native commands that set it.
