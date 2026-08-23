# C09 PowerShell checker stale-LASTEXITCODE failure

Date: 2026-08-07

`check-user-facing-copy.ps1` printed its passing result. The orchestration then
tested `$LASTEXITCODE`, which belongs to native commands and still held an
unrelated older value. It falsely threw `Copy gate failed` after the gate had
passed.

Repository PowerShell checkers use terminating errors and are invoked as
independent commands. Their success is the absence of a terminating error;
`$LASTEXITCODE` is checked only immediately after a native executable.
