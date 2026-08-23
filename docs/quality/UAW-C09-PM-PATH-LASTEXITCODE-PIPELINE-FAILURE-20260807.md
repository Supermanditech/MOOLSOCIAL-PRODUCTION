# C09 pm-path LASTEXITCODE pipeline failure

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

The first installed-APK pull preflight piped native `adb shell pm path` through
`Select-Object` inside the assignment, then tested `$LASTEXITCODE`. The terminal
PowerShell pipeline stage left `$LASTEXITCODE` unset, so `$null -ne 0` was true
and the valid `package:` response was rejected. No pull file was created and
the installed app was unchanged.

Native output is now captured first and `$LASTEXITCODE` is checked immediately,
before any PowerShell pipeline. Only the already validated array is then
normalized to one line. Native exit status is never read after a PowerShell
pipeline stage.
