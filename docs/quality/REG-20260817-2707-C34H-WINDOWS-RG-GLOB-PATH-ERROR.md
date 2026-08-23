# C34H Windows ripgrep glob-path error

Date: 2026-08-17 IST

## Mistake

A postinstall diagnostic passed shell-style wildcard path operands such as
`scripts/check-c30w*` to ripgrep on Windows. Ripgrep rejected the operands
as invalid filenames. A later exact state-owned runtime-gate path resolved the
required file without ambiguity.

## Root cause

The command mixed Unix-style operand globbing with Windows path semantics
instead of reading the exact owner already declared in candidate state.

## Permanent prevention

Resolve an exact path from the authoritative candidate owner. When pattern
selection is actually required, use ripgrep's `-g` option rather than a
wildcard path operand. An invalid-path result is zero diagnostic evidence.
