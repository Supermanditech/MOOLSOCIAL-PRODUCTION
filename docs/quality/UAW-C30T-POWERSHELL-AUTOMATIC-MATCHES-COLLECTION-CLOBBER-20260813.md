# C30T PowerShell automatic Matches clobber

Date: 2026-08-13
Regression: `REG-20260813-2006-C30T-POWERSHELL-AUTOMATIC-MATCHES-COLLECTION-CLOBBER`

## Incident

The reply-test inventory assigned search results to `$matches`, which is the
case-insensitive PowerShell automatic `$Matches` variable, then used regex
matching in the same command. The collection was clobbered and the command
failed. No output was accepted.

## Permanent prevention

Never use PowerShell automatic variable names for task collections. Use an
explicit name such as `$foundLines`, calculate the filtered collection once,
then report it.

This incident grants no AAB, upload, install, deployment, or device authority.
