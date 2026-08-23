# REG3073 — APK gate runtime-define array lost through nested PowerShell

- Date: 2026-08-21
- Status: registered before retry

The APK machine-gate dry run passed an array to a nested `pwsh -File`
invocation. The first item bound to `-RuntimeDefine`; subsequent items were
treated as positional arguments, so parameter binding stopped before gate
execution. No Flutter build, APK, device or external action occurred.

Prevention: invoke the gate script directly in the current PowerShell process
when passing `string[]`, or use a separately verified argument-file contract.
