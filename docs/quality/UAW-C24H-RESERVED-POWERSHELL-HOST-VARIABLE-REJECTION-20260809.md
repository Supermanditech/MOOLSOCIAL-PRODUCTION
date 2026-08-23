# C24H reserved PowerShell Host variable rejection

Date: 2026-08-09
Regression: `REG-20260809-748-C24H-QUALIFIER-USED-RESERVED-POWERSHELL-HOST-VARIABLE`

The first cycle command stopped before fingerprinting because the qualifier
assigned contract data to `$host`, colliding with PowerShell's read-only
automatic `$Host`. The cycle is not counted. The qualifier must use
`$hostContract` and both new scripts must be scanned for common reserved
automatic-variable assignments before retry.

The qualifier now uses `$hostContract` for every qualification-contract
reference.
