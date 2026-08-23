# C30T mixed-property evidence table misclassification

Date: 2026-08-13
Disposition: resolved harness/diagnostic mistake; no product action occurred

## What happened

A read-only inventory mixed existing-file objects containing `Length` and
`SHA256` with missing-file objects containing `Missing=true`. PowerShell's
implicit table chose a heterogeneous projection that left misleading blank
cells, and the absent page-2 capture names were incorrectly described as
one-byte placeholders. A subsequent exact path resolution proved that the
names did not exist.

## Permanent rule

Evidence inventories must materialize a uniform explicit schema containing
`Name`, `Exists`, `Length` and `SHA256`. Hashes and byte reads are permitted
only after `Test-Path -LiteralPath` returns true. Missing evidence is reported
as missing and is never inferred from blank implicit-table columns.

No existing evidence was overwritten or deleted, and no product tap was
repeated before this mistake was registered.
