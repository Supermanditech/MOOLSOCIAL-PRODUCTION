# REG-20260816-2628 — C33R founder launcher had no visible interactive host

Date: 2026-08-16 IST

Codex opened the sealed C33R founder launcher once through `Start-Process` and
reported only that the `pwsh` process started. The persistent child was later
proved to be parented directly to `codex.exe`, with no visible window handle.
The founder therefore saw only an unrelated Windows PowerShell prompt and had
no safe surface on which to enter the three hidden inputs.

Sanitized reconciliation proved C33R remained at build/upload/install/device
acceptance `0/0/0/0`, `hiddenFounderInputsEntered=false`, no child build
process, no AAB, and neither transient founder-input file present. The exact
detached `pwsh` process was then stopped; the founder's visible Windows
PowerShell process was not touched.

C33R is rejected before build because this required incident registration
changes its sealed registry. A successor must never have Codex launch its
interactive founder prompt. After every source and build gate passes, Codex
must instead provide one literal `pwsh` command for the founder to paste into
an already visible founder-owned PowerShell window, where `PowerShell 7` and
the exact candidate prompt can be observed before any secret entry.
