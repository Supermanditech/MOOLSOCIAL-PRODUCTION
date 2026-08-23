# REG3180 - FIX8 manifest membership foreach pipe parser

## Classification

Registered read-only PowerShell parser rejection with zero build, APK, install,
repository-state transition or device action.

## Evidence

The bounded manifest-membership projection attempted to pipe directly from a
top-level `foreach` statement. PowerShell rejected the empty pipe position
before any manifest read completed. No Flutter, ADB, build or device command
ran.

## Prevention

Collect the projected membership objects into an explicit result array, then
format or serialize that array after the loop.
