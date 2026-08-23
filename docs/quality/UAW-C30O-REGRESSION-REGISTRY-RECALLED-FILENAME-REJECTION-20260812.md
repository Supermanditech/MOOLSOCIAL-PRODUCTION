# C30O regression registry recalled filename rejection — 2026-08-12

## Disposition

Rejected read-only lookup. No repository or external state changed.

## Mistake

The continuation attempted to read `config/permanent-regression-memory.json`, which does not exist, instead of the repository-owned Codex development regression registry.

## Root cause

A generic remembered label was converted into a guessed filename instead of using the exact durable registry path.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Use `config/codex-development-regression-registry.json` directly.
- Use `scripts/check-codex-development-regression-memory.ps1` as its checker.
- Never guess a permanent-memory filename.
