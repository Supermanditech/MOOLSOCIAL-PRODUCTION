# C20H active-build probe self-match rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The first process probe reported one active build, but the returned executable
was the probe's own `pwsh.exe`. Its command line contained the literal detection
regex, so this was a false positive and was not admitted as prebuild evidence.
No APK build or device mutation occurred.

## Prevention

The corrected inventory excludes the current PID and applies executable-aware
matching: `GradleWrapperMain` is evaluated only on Java processes and Flutter
build commands only on Flutter/Dart/cmd processes. Shell probes cannot match
their own pattern text.
