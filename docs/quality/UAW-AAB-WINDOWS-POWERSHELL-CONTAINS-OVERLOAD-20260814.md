# AAB wrapper Windows PowerShell `Contains` overload rejection

Date: 14 August 2026
Scope: source-only successor AAB preparation audit

## Observed result

The C30V wrapper static gate passed under PowerShell 7, then Windows
PowerShell rejected the same script with `MethodException: Cannot find an
overload for Contains and the argument count: 2`.

## Root cause and prevention

`String.Contains(value, StringComparison)` is not available on the Windows
PowerShell .NET Framework runtime. The gate must use explicit ordinal
`IndexOf` comparisons and must pass unchanged in both PowerShell hosts before
any successor build authority is permitted.

No AAB, upload, Play/OPPO action, deployment or secret access occurred.

## Resolution

The static gate now uses ordinal `IndexOf` comparisons. The unchanged gate
passed in PowerShell 7 and Windows PowerShell; evidence is retained at
`artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/wrapper-static-cross-host-attempt-02.log`.
