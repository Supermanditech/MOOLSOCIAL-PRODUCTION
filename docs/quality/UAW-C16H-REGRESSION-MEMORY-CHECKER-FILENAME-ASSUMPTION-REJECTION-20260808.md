# UAW C16H regression-memory checker filename assumption rejection — 2026-08-08

## Rejection

The first post-host memory-gate rerun invoked the nonexistent shortened path `scripts/check-codex-regression-memory.ps1`. PowerShell rejected the command before any mutation or build authorization.

## Cause and prevention

The checker filename was recalled from its purpose instead of following the registry's exact gate path. C16H now resolves bounded script inventory first and invokes only `scripts/check-codex-development-regression-memory.ps1`. Independent read-only inspections are not treated as completed when a parallel aggregate fails.

## State impact

- No production source, APK state, device state, or authorization changed.
- C15 r60.15 remains installed and checksum-preserved.
- The C16H build authorization remains closed pending a successful corrected memory gate and the remaining machine checks.
