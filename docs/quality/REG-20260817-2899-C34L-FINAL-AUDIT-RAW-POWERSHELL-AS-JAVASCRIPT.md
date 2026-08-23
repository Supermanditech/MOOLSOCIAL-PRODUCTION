# REG2899 — C34L final-audit raw PowerShell submitted as JavaScript

## Incident

On 2026-08-17, the independent PRE-AAB FIX2 auditor submitted raw PowerShell syntax as the JavaScript source of the orchestration wrapper. The wrapper rejected the input with `SyntaxError: Invalid or unexpected token` before any shell process launched.

## Impact

- The intended read-only bounded source search did not run.
- No repository, candidate, source seal, cycle, build, Play, OPPO, browser, private/account, secret, device, or external state changed.
- The auditor stopped before retry or further inspection.

## Root cause

The auditor crossed the tool-layer boundary incorrectly: PowerShell command text was placed directly in the JavaScript orchestration input instead of being passed as the `cmd` value to `tools.exec_command`.

## Prevention

- Keep orchestration input valid JavaScript.
- Pass PowerShell only as the literal `cmd` property of one `tools.exec_command` call.
- Use bounded fixed-string searches and one authoritative read/gate per shell call.
- Register this failure and replay the applicable regression-memory gate before the audit resumes.

## Disposition

Registered truthfully before retry. The prior dual-host C34L FIX2 qualification results and owner bytes remain unchanged.
