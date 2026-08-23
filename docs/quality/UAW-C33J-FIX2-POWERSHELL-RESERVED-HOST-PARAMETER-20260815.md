# UAW C33J FIX2 PowerShell reserved Host parameter

- Regression: `REG-20260815-2515-C33J-FIX2-POWERSHELL-RESERVED-HOST-PARAMETER`
- Failure: the first static gate stopped before assertions because `$Host` is
  a read-only automatic PowerShell variable.
- Prevention: use the task-specific `$DomainHost` parameter and qualify on both
  PowerShell hosts.
- Impact: no product, external, build or device state changed.
