# C30T PowerShell array-offset inspection failure

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1880-C30T-POWERSHELL-ARRAY-OFFSET-INSPECTION-FAILURE`

## Observation

A bounded source-inspection command failed because arithmetic expressions were embedded directly in a PowerShell array expression. It returned the exact owner line but not the requested surrounding windows.

## Root cause and prevention

PowerShell parsed `@($hit-1,$hit+19,$hit+39)` as operations on an array-like value. Future commands precompute each scalar offset separately or inspect one fixed window per command.

## External effect

None. The read-only local command did not change files or external services.
