# REG-20260821-3126 — APK integrity gate single tool-path Count

Date: 21 August 2026
State: registered; first negative fixture stopped before APK inspection

## Failure

The new post-build APK integrity gate resolved one `apkanalyzer` path, then
accessed `.Count` after PowerShell unwrapped the singleton to a string. Strict
mode rejected the missing property before dex inspection.

## Impact

- No APK, build, source artifact, device or external state changed.
- The gate is not accepted until positive and negative fixtures pass.

## Root cause

The tool-path selection result was not explicitly normalized with `@(...)`
after pipeline evaluation.

## Prevention

Store candidates in an explicit array, require exactly one element, then copy
that scalar into the executable path. Run the immutable r60.80 missing-
registrant negative fixture and one known-good plugin fixture before any build
wrapper may invoke the gate.
