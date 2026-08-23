# C30T ripgrep Windows wildcard-path recurrence — 2026-08-13

## Failure

A read-only source search passed `config/uaw-c30t-*-ticket.json` to `rg` as a positional path. PowerShell did not expand that wildcard for the native process, so `rg` rejected the literal path.

## Impact

- No repository or external state changed.
- No build, upload, install or device action occurred.
- The source search produced no result.

## Prevention

Search an existing directory and use `rg --glob`, or first discover exact paths using `rg --files`. Unresolved wildcard paths are forbidden in C30T native-tool commands.
