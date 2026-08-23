# C23E1 scope-gate mobile-working-directory recurrence — 2026-08-09

## Observed rejection

The C23E1 verification rerun attempted to call the repository-root scope gate
through `./scripts/...` while the process working directory was `apps/mobile`.
PowerShell rejected the missing relative path. No Dart format, Flutter analysis
or Flutter test step ran in that command.

## Root cause

Repository-root and mobile-package commands were grouped under one working
directory even though their path owners differ.

## Permanent prevention

Repository gates run first from the repository root. Dart and Flutter commands
then run separately from `apps/mobile`, with native exit codes checked
immediately. A failed preliminary gate authorizes no later-step inference.
