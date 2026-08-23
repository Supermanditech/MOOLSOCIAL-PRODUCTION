# REG-20260816-2542 — C33L continuation guessed the regression-registry path

## Observed failure

The post-restart read-only verification attempted to open
`config/codex-regression-memory.json`. That file does not exist, so the command
stopped before it could verify the interrupted C33L FIX1 qualification patch.
No repository file, build state, device state, credential, provider, or remote
service was changed by the failed command.

## Root cause

The continuation used a shortened path inferred from a compacted handoff label
instead of discovering and reusing the repository-owned literal path. This is a
recurrence of the permanent no-path-guessing rule and therefore must remain
visible even though the failed operation was read-only.

## Permanent prevention

- Discover the exact owner with a bounded `rg --files` query before its first
  use in a resumed session.
- Use only `config/codex-development-regression-registry.json` for this
  repository's permanent regression registry.
- Register any recurrence before retrying the intended check.
- Because the registry is source-sealed, create a fresh uniquely named source
  manifest and repeat both qualification cycles after this record is final.

## Resolution evidence

Bounded repository discovery returned the exact literal registry path. This
entry and evidence document were added before the interrupted-patch verification
was retried.
