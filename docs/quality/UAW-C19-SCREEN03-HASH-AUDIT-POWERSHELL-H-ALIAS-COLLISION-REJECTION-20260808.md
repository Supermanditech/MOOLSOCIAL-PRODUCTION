# UAW C19 Screen03 hash-audit PowerShell H-alias collision rejection — 2026-08-08

## Rejected audit

The first diagnostic intended to compare every Screen03 v2 locked owner with
the current workspace declared a helper function named `H`. PowerShell resolved
`H` as its built-in `Get-History` alias, attempted to parse each repository
path as a history identifier and returned blank actual hashes. The resulting
apparent all-file mismatch list is invalid and discarded.

No Screen03 file, accepted reference, build, install or device state changed.

## Prevention

Qualification helpers use descriptive non-alias names such as
`Get-C19FileSha256`. Every computed hash must match the 64-hexadecimal pattern
before comparison; blank results make the audit fail rather than producing a
mismatch list.
