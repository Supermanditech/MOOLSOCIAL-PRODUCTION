# C30T ripgrep Windows wildcard path failure

Date: 2026-08-13

A bounded read-only source audit supplied `scripts/*c30t*.ps1` as a ripgrep path. PowerShell did not expand the wildcard on Windows, so ripgrep reported an invalid filename after the useful exact-file results.

Permanent prevention: use `rg --glob '*c30t*.ps1' PATTERN scripts` or pass exact literal files. The audit error changed no repository, device or external state.
