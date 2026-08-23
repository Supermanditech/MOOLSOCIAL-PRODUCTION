# REG2790 — C34L attestation parser nested expansion

Date: 17 August 2026
State: registered parser-wrapper failure; no owner parser or external action

## Mistake

The evidence-attestation agent embedded `$p`, `$paths` and `$errors` in an outer
double-quoted `pwsh -Command`. The host expanded them, producing an
`InvalidOperation` and malformed `foreach` parser error before any assigned
owner parser ran. The agent stopped without retry; no external state changed.

## Prevention

Do not use nested interpolating parser command strings. Execute stable checker
owners directly with `-File` on each host, or use a literal non-interpolating
script block whose variables are parsed only by the target process. Keep one
owner/parser invocation per command.
