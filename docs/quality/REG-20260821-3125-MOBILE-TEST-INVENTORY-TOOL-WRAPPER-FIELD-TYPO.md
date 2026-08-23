# REG-20260821-3125 — Mobile test-inventory tool-wrapper field typo

Date: 21 August 2026
State: registered; shell command did not execute

## Failure

A tool wrapper for a read-only mobile test inventory used an invalid JavaScript
field token instead of the declared `workdir` property. The wrapper parser
rejected it before `rg` or PowerShell execution.

## Impact

- No inventory, source, test, build, provider, Play, OPPO or private action ran.

## Root cause

The tool-call object was edited with a shell-style prefix on a JavaScript
property name.

## Prevention

Use the exact `cmd`, `workdir`, `yield_time_ms` and `max_output_tokens` schema.
Do not retry discovery in this phase; invoke the already-known literal focused
auth/startup test owners directly.
