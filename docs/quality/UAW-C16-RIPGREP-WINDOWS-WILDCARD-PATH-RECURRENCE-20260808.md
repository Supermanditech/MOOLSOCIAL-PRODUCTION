# C16 ripgrep Windows wildcard-path recurrence

## Incident

A read-only C16 Hero-owner search passed `scripts/check-personal-*` and
`scripts/check-*navigation*` as ripgrep path operands on Windows. Ripgrep
reported path-syntax errors. Although one exact test hit printed first, the
grouped lookup is discarded in full and no implementation decision relies on
it.

## Root cause and prevention

Shell wildcard expansion was again assumed for native Windows ripgrep path
operands. C16 passes only exact literal roots (`apps/mobile/test` and `scripts`)
to ripgrep. If filename narrowing is required it starts with `rg --files` and a
separate explicitly classified filter.
