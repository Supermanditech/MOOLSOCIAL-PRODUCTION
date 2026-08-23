# C33E hash table formatter suppressed the hash column

Date: 15 August 2026
Regression: `REG-20260815-2338-C33E-HASH-TABLE-FORMAT-SUPPRESSED-HASH-COLUMN`

The first integrity read for the C30Z, C33E and C33E FIX1 ticket manifests used
a width-dependent PowerShell table. Long absolute paths consumed the rendered
width and the required hash column was not visible. No digest is accepted from
that output. Recovery emits one repository-relative `filename=SHA256` scalar
line per owner. No product, device, build, provider or external state changed.
