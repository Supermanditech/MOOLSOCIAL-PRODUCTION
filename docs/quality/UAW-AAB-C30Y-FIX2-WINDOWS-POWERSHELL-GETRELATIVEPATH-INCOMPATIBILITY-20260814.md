# C30Y FIX2 Windows PowerShell GetRelativePath incompatibility

- Incident: `REG-20260814-2180-AAB-C30Y-FIX2-WINDOWS-POWERSHELL-GETRELATIVEPATH-INCOMPATIBILITY`
- Checker: `scripts/check-c30y-fix2-mutation-safe-preflight-source-transaction.ps1`

The first FIX2 checker replay under Windows PowerShell stopped before its behavioral restore probe because `[IO.Path]::GetRelativePath` is unavailable in the legacy host runtime. The PowerShell 7 checker had already passed, but that result is not cross-host qualification evidence. No founder prompt, config-only task, manifest task, wrapper build path, authority mutation or AAB ran.

Before retry, the checker must derive both repository-relative probe paths from an already validated repository-root prefix without any forbidden modern path/hash API. The incident is resolved only after regression memory, the FIX2 checker on PowerShell 7, and the FIX2 checker on Windows PowerShell all pass.

Resolution: both probe paths now require the exact normalized repository prefix and use a substring relative conversion. A direct forbidden-API scan passed, regression memory passed with 2,151 entries and 1,246 applicable implementation entries, and the full FIX2 checker passed on PowerShell 7 and Windows PowerShell. No founder prompt, config-only task, authority mutation or AAB ran.
