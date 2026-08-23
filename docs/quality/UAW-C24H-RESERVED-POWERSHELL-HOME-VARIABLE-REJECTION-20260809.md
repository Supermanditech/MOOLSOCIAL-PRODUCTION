# C24H reserved PowerShell HOME variable rejection

Date: 2026-08-09
Regression: `REG-20260809-747-C24H-AGGREGATE-USED-RESERVED-POWERSHELL-HOME-VARIABLE`

The aggregate gate attempted to assign source text to `$home`. PowerShell is
case-insensitive, so this collided with the read-only automatic `$HOME`
variable and stopped the gate. The gate must use the task-specific
`$homeSource` name and new scripts must be scanned for prohibited HOME
assignments before execution.

The assignment and every downstream reference now use `$homeSource`.
