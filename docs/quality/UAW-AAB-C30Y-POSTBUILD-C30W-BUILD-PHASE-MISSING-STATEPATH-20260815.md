# UAW AAB C30Y postbuild C30W build-phase missing StatePath

Date: 2026-08-15
Regression: `REG-20260815-2208-AAB-C30Y-POSTBUILD-C30W-BUILD-PHASE-MISSING-STATEPATH`
Status: resolved; exact StatePath and full postbuild regression passed

Postbuild audit attempt 01 omitted the required C30X candidate state path from
the C30W build-phase replay. C30W rejected before executable tests. The next
attempt must copy the proven C30X invocation and pass
`config/successor-aab-regression-hard-gate-state-c30x.json` explicitly.

No source, artifact, count, upload, Play or device action changed.

## Resolution

Attempt 02 passed the exact C30X state path to C30W under both PowerShell hosts.
The complete static matrix, Flutter 417/3, analyzer, backend 528 and Hosting 8
then passed with the source manifest and sealed AAB hash unchanged.
