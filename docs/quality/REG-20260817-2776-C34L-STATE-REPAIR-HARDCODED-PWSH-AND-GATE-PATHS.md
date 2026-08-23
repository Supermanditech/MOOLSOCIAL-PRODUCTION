# REG2776 — C34L state repair hard-coded pwsh and gate paths

Date: 17 August 2026
State: registered gate-launch failure; no FIX1 mutation

## Mistake

The PRE-AAB-1 FIX1 agent invoked an unverified absolute executable path
`C:\Program Files\PowerShell\7\pwsh.exe` and also used the guessed script name
`check-codex-regression-memory.ps1`. The host could not resolve the executable,
so the required memory gate never ran. The agent stopped without discovery,
retry, edit or test. No browser, candidate, seal, cycle, build, Play, OPPO,
private or external action occurred.

## Root cause and prevention

Two already-known runtime/owner paths were retyped from convention rather than
reused from the saved qualified commands. Use the available `pwsh` command and
the exact literal owner
`scripts/check-codex-development-regression-memory.ps1`. Resolve executable and
script owners read-only before invocation; never hard-code an installation
path or abbreviate an established gate filename.
