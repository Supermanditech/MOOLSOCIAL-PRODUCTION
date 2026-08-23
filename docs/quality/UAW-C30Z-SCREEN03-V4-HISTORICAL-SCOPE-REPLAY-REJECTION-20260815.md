# C30Z Screen 03 v4 historical-scope replay rejection

Date: 2026-08-15
Regression: `REG-20260815-2223-C30Z-SCREEN03-V4-HISTORICAL-SCOPE-REPLAY-REJECTION`
Status: resolved; C30Z successor containment passed on both PowerShell hosts

## Finding

The general approved-UI lock passed. The unchanged historical C30X FIX1
Screen 03 v4 gate then rejected because the active MVP ticket had transitioned
to C30Z and its exact creation/read-only successor replay allowlist does not
include that ticket. This is valid historical fail-closed behavior and is not
weakened.

## Prevention

C30Z adds a separate containment gate. It proves the historical gate remains
unchanged, replays its substantive accepted-reference, layout, source and test
locks, and adds only C30Z method-availability truth. No source retry occurs
before registration, and no build, Play, OPPO, provider, credential or external
service state changed.

## Resolution

`scripts/check-c30z-authentication-method-truth-and-guest-feed-recovery.ps1`
pins the unchanged historical gate hash, replays the approved UI locks, binds
the exact C30Z source-only scope and verifies the new availability, rollback,
guest Feed and protected-write invariants. It passed under PowerShell 7 and
Windows PowerShell. The locked Screen 03 presentation remains byte-identical.
