# REG2865 — C34L capture FIX2 five-parser nested expansion

Date: 17 August 2026
State: registered parser-launch construction failure; zero owner parsing

## Mistake

Five independent capture-owner parser invocations reused one outer double-quoted
`pwsh -Command` payload. The host expanded `$tokens`, `$errors`, and `$_` before
the target process, so all five wrappers failed at an empty pipeline element and
none parsed or mutated an owner.

## Prevention

Parse each owner directly in the current qualified PowerShell host with
`Parser.ParseFile`, or invoke a stable checker with `-File`. Do not nest parser
variables inside interpolating process-command strings, even when calls are
parallelized.
