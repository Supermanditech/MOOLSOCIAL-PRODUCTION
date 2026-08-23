# C30Y FIX2 PowerShell state-needle interpolation recurrence

- Incident: `REG-20260814-2179-AAB-C30Y-FIX2-POWERSHELL-STATE-NEEDLE-INTERPOLATION-RECURRENCE`
- Checker: `scripts/check-c30y-fix2-mutation-safe-preflight-source-transaction.ps1`

The first checker run stopped under strict mode because its authority-consumption source needle was double quoted and interpolated `$state`. No behavioral probe, wrapper, config-only task, AAB, state transition or authority mutation ran.

Before retry, every FIX2 checker needle containing a dollar sign must be inspected and converted to a literal single-quoted source string. The recurrence is resolved only after the checker passes on PowerShell 7 and Windows PowerShell.

Resolution: the `$state` needle is literal, all sibling source needles were audited, and the complete FIX2 transaction checker passed on both PowerShell 7 and Windows PowerShell. Both runs proved the positive exact-byte restore, the negative hash rejection, two qualified snapshots, preflight and postbuild restoration, and exactly one appbundle invocation. No founder prompt, authority mutation or AAB ran.
