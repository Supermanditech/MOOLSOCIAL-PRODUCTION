# C30O qualifier PowerShell gate LASTEXITCODE undefined rejection — 2026-08-12

## Disposition

Cycle 1 rejected before formatting, analysis or tests. Only the implementation regression-memory gate completed. No build, device, provider, console or account state changed.

## Mistake

The first C30O qualifier invoked a PowerShell gate script and then read `$LASTEXITCODE` under strict mode. No native process had set that variable in the qualifier session, so the cycle stopped with `VariableIsUndefined`.

## Root cause

PowerShell script success was incorrectly checked through the native-process exit variable instead of normal terminating-error propagation.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Let PowerShell gate scripts propagate terminating errors directly; reserve `$LASTEXITCODE` for the explicitly invoked native `dart` and `flutter` commands.
- Restart cycle 1 under new durable log filenames; never append to the rejected partial cycle.
