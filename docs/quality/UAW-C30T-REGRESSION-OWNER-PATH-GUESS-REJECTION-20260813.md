# C30T regression owner path guess rejection

Date: 2026-08-13
Disposition: resolved diagnostic mistake; guessed paths rejected

## What happened

A read-only diagnostic guessed that the regression memory lived at the
repository root and that the registry filename ended in `memory.json`. Both
guesses were wrong, and the guessed name of the immediately preceding defect
document was also wrong. The failed read changed nothing.

## Permanent rule

Use `rg --files` with narrow filename patterns to resolve required regression
owners before reading them. The durable owners are currently
`docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md` and
`config/codex-development-regression-registry.json`; do not reconstruct or
guess paths from memory.

No source, ticket-selection state, build state or external service changed.
