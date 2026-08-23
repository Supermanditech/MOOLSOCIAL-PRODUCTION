# UAW C30T PowerShell script LASTEXITCODE null misclassification recurrence — 13 August 2026

## Observation

A wrapper called the regression-memory PowerShell gate, tested `$LASTEXITCODE`, and intended to call the C30T journey gate next. The first PowerShell script passed, but the native-process status variable was not a valid success channel for it; the condition skipped the second invocation while the host command exited zero.

## Permanent prevention

- Run repository PowerShell gates directly under `$ErrorActionPreference = 'Stop'`.
- Let terminating errors stop the sequence.
- Never read `$LASTEXITCODE` after a PowerShell script; use it only immediately after a native executable.
- Prove every intended gate emitted its own pass marker.

## Safety result

No device input, app mutation, build, upload, install, external write or credential action occurred.
