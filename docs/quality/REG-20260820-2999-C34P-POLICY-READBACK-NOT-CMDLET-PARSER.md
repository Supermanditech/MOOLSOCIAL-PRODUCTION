# REG2999 — C34P policy-readback `-not` cmdlet parser failure

Date: 20 August 2026 (IST)
State: registered before readback retry

## Incident

The first coordination-policy readback wrapper placed `-not` directly before a
parameterized `Test-Path` invocation inside an `if` condition. PowerShell
rejected the command before execution with `Unexpected token '{'`. The policy
patch had already completed, but this command produced no parse, owner count or
existence evidence and changed nothing.

## Root cause

The conditional did not wrap the complete cmdlet invocation in a parenthesized
expression before applying unary negation.

## Prevention

Compute each `Test-Path` result into an explicit boolean scalar, then negate the
scalar in the `if`. Keep parsing, root-claim selection and missing-owner counts
as simple sequential statements before object construction.

## Retained evidence

- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`
