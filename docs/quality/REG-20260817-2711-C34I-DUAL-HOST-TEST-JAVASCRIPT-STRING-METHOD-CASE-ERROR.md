# REG2711 — C34I dual-host test JavaScript string-method case error

## Observation

The orchestration wrapper intended to launch four C34I parser/gate checks used
`script.Replace(...)`, a PowerShell/.NET method spelling, on a JavaScript
string. JavaScript rejected the wrapper before any terminal command or gate
was invoked. No repository, browser, Play or OPPO state changed.

## Root cause

PowerShell and JavaScript string APIs were mixed while adding unnecessary path
transformation to already fixed literal paths.

## Prevention

Do not retry the wrapper. Invoke each parser and gate as a plain direct
terminal command with the fixed repository-owned literal paths. A JavaScript
wrapper exception is zero gate evidence.
