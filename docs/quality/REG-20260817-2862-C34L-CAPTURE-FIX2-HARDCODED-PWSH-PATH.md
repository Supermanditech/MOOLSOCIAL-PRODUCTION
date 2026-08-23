# REG2862 — C34L capture FIX2 hardcoded pwsh path

Date: 17 August 2026
State: registered pre-script launcher failure; zero mutation

## Mistake

The capture FIX2 agent retried the memory gate through guessed executable
`C:\Program Files\PowerShell\7\pwsh.exe`. That path is not the configured
workspace runtime; PowerShell returned command-not-recognized before the gate
script started. No cleanup, test, or mutation followed.

## Prevention

Use the already qualified bare `pwsh` command for PowerShell 7 and
`powershell.exe` for Windows PowerShell. Do not hardcode installation paths;
if runtime identity is needed, query the active command after the memory gate.
