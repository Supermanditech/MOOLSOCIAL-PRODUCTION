# REG-20260816-2633 — C33S PowerShell-script LASTEXITCODE caused an early exit

Date: 2026-08-16 IST

After the C33S source manifest was sealed, a combined orchestration invoked the
regression-memory PowerShell script and then tested `$LASTEXITCODE`. That value
is a native-process status and was null or stale after the PowerShell script,
so the orchestration exited successfully before invoking the delivery, scope
or C33S source gates.

Only the regression-memory gate passed. No remaining gate, source cycle,
hidden-input prompt, build, browser write, Play action or OPPO action ran. The
combined command is not counted as a cycle or gate pass.

Required registration changes the post-seal registry, so C33S is rejected at
`0/0/0/0`. A successor must invoke PowerShell gates separately or rely on
terminating errors under `ErrorActionPreference=Stop`. `$LASTEXITCODE` may be
read only immediately after an actual native executable.
