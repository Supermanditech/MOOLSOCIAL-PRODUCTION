# UAW-C33F OPPO cold-start diagnostic used reserved PowerShell PID

Date: 2026-08-15

## Preserved mistake

The first r60.49 OPPO cold-start diagnostic assigned the app process identifier to `$pid`, colliding case-insensitively with PowerShell's read-only automatic `$PID` variable. PowerShell emitted a write error and the reported `processRunning` boolean therefore reflected the diagnostic host rather than the Android app process.

Independent results from the same run remained valid: the OPPO focused `com.moolsocial.app`, the hierarchy contained 42 app-owned nodes, 18 enabled clickable nodes and 20 named nodes, and the current post-update exit history showed only the intentional force-stop with no crash or ANR entry.

## Prevention

Register before retry. Never reuse PowerShell automatic variables for device facts. Store the Android PID in an explicit `$moolSocialAppPid` scalar, set `$ErrorActionPreference='Stop'`, suppress Monkey diagnostic streams, and seal liveness only when package focus, process presence and interactive hierarchy independently agree.
