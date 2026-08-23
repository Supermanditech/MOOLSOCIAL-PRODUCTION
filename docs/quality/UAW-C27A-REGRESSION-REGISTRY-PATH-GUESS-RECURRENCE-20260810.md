# C27A regression-registry path-guess recurrence

## Observation

During the C27A read-only audit, one combined inspection command included the
nonexistent path `docs/quality/codex-development-regression-registry.json`
even though the verified permanent owner is
`config/codex-development-regression-registry.json`.

## Cause

The command mixed a guessed documentation path into a verified multi-file
inspection instead of reusing only the exact permanent owner already recorded
by REG875.

## Permanent prevention

- Use `config/codex-development-regression-registry.json` exactly.
- Never add a second registry candidate to a combined read command.
- Run the permanent regression-memory gate before and after registry mutation.

## Resolution evidence

The failed read did not mutate the workspace. The exact permanent owner was
then read directly, its 905-entry state was reconciled, and this recurrence was
registered before any implementation retry.
