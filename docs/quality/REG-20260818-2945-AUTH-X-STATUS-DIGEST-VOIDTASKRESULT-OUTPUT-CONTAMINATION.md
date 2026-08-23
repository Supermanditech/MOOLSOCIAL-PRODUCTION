# REG2945 — X inventory status-digest VoidTaskResult output contamination

## Observed event

The X inventory agent's non-emitting porcelain-v1-z digest completed successfully with zero stderr and emitted no status body or paths, but the PowerShell wrapper leaked `System.Threading.Tasks.VoidTaskResult` from an unassigned `CopyToAsync().GetResult()` return. The agent stopped before gates, web, source-map edit, provider/private/device action, or external write.

## Root cause

An async helper return object was left on the PowerShell success pipeline instead of explicitly assigned to `$null`.

## Mandatory prevention

Assign every async/helper `.GetResult()` return to `$null`. The bounded status digest output allowlist is exactly `bytes`, `records`, `sha256`, `stderrBytes`, and `exitCode`; reject any extra output object or line.
