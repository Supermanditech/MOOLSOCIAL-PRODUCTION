# REG2728 — C34K OPPO diagnostic PowerShell PID collision

Date: 2026-08-17 IST

A sanitized read-only OPPO readiness audit assigned to `$pid`, which collides
case-insensitively with PowerShell's automatic read-only `$PID`. The assignment
failed after `pidof` returned no value; `.Trim()` then threw and a stale process
interpretation could not be trusted. No Play action, install, sideload,
uninstall, data clear, downgrade, screen inspection, repository write or device
mutation occurred.

Truthful pre-error facts were retained: OPPO `2b3e0f71` / `CPH2375` was
connected and awake; `com.moolsocial.app` was present as `1.0.0-r60.72` /
`2026081372`; its installer owner was null. Therefore the current installation
is not yet proven Play-installed and a Play in-place update is blocked until an
exact sanitized machine gate proves the lawful installer/update path.

Future device diagnostics must use a task-specific variable such as
`$moolProcessId`, handle an empty `pidof` result before trimming, and never infer
process state from PowerShell's automatic PID.
