# REG2861 — C34L transition FIX2 WinPS junction cleanup

Date: 17 August 2026
State: registered final WinPS cleanup failure; semantic pass not accepted

## Mistake

The first final Windows PowerShell lifecycle run completed all eleven positives
and thirty-two negatives and printed pass, then its `finally` block used
`Remove-Item` to unlink the fixture junction and hit a Windows PowerShell 5.1
`NullReferenceException`. The run is not qualification evidence; its unique
fixture root may remain. No retry or later mutation followed, and real/external/
private/device writes remained zero.

## Prevention

Verify the exact checker-owned link is a reparse point, unlink it nonrecursively
with the .NET directory API, then remove only the verified target and unique run
root and assert absence. Never use `Remove-Item` directly on a WinPS fixture
junction.
