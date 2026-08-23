# C30O PowerShell foreach direct-pipe third recurrence rejection — 2026-08-12

## Disposition

Rejected at parse time. No environment value was read or output, and no source, build, device, provider, console or account state changed.

## Mistake

The C30O signing-environment presence audit again placed a statement-form `foreach` block directly before `Format-Table`, repeating the permanent materialize-before-format violation.

## Root cause

The command combined a scalar version read and a small environment-presence table without assigning the loop output to an explicit collection first.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Use `$rows = @(foreach (...) { ... })` before any formatter.
- Return only boolean presence; never read or print environment values.
- Treat the parser-failed command as no evidence.
