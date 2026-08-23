# REG3169 - build process probe self-match

## Classification

Registered readback false positive with zero build or artifact action.

## Evidence

The first bounded process probe embedded the literal build-command markers in
its own PowerShell command line and did not exclude the current diagnostic
process. It therefore reported one active build process even though FIX8
remained unregistered, no r60.81 artifact directory existed, and no build
authority had been transitioned.

## Prevention

Exclude the current process and its ancestor diagnostic hosts before matching
build-command markers. Require a separately identified Flutter, Dart, Java or
Gradle child process plus a registered r60.81 candidate before classifying a
build as active.
