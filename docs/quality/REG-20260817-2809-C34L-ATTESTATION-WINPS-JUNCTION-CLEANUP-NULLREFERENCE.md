# REG2809 — C34L attestation WinPS junction-cleanup NullReference

Date: 17 August 2026
State: registered first WinPS cleanup failure; host run not accepted

## Mistake

The first Windows PowerShell attestation checker completed all three positives
and eleven exact negatives, then its `finally` cleanup used `Remove-Item` on a
fixture reparse junction and hit a Windows PowerShell 5.1
`NullReferenceException`. The host run is failed/uncertain and the unique
fixture root may remain; no real or external action occurred.

## Prevention

Resolve and verify the exact checker-owned fixture junction, remove only that
link with a Windows PowerShell-safe nonrecursive `DirectoryInfo.Delete()`, then
remove the confirmed unique fixture root and assert its absence. Never recurse
through a reparse link during cleanup.
