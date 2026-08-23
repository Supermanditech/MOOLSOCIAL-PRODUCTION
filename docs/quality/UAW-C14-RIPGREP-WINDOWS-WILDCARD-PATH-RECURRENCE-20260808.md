# C14 ripgrep Windows wildcard path recurrence

Date: 2026-08-08

Regression:
`REG-20260808-292-C14-RIPGREP-WINDOWS-WILDCARD-PATH-RECURRENCE`

## Failure

A read-only pre-build provenance lookup passed `docs/quality/UAW-C13*` and
`docs/quality/UAW-C12*` to ripgrep as path operands. Windows did not expand
them, ripgrep returned path-syntax errors, and the grouped lookup output was
discarded.

## Root cause and prevention

The command again assumed POSIX-style wildcard expansion for a native Windows
path operand. Provenance discovery now starts from `rg --files` with a bounded
filename filter, then reads exact literal files. Any grouped lookup containing
a path error is discarded in full and cannot establish build state.
