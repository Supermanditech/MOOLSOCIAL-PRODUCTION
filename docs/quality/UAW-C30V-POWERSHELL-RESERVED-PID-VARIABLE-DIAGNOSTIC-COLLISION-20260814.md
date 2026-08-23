# UAW C30V PowerShell reserved PID variable diagnostic collision — 2026-08-14

The first post-cold-launch diagnostic assigned `adb shell pidof` output to PowerShell's automatic `$PID` variable. PowerShell rejected the assignment because the variable is read-only, so the command's emitted process scalar and combined conclusion were discarded.

No device mutation occurred. Recovery is to rerun the read-only process, focus, and UI-state reads with ticket-specific variables and separately captured native exits before deciding whether the cold-start timeout represents a runtime defect.
