# REG2910 — C34L FIX3 source-map rg pattern-position overmatch

## Incident

On 2026-08-18, the read-only FIX3 source-map agent constructed an `rg` command with `scripts config docs` in the pattern position rather than as search roots. Each intended Play-term query therefore produced a meaningless 411-file semantic overmatch. The agent stopped without using the result as evidence.

## Impact

- The overmatched inventory is inadmissible for identifying authoritative Play source owners.
- No later read, test, repository mutation, candidate, seal, cycle, build, Play, OPPO, browser, private/account, device, secret, or external action occurred.

## Root cause

Search roots and the fixed search pattern were placed in the wrong `rg` argument positions.

## Prevention

- Use explicit `rg --fixed-strings -- <pattern> <root...>` ordering.
- Search one exact identifier at a time and return scalar file counts before any line projection.
- Scope first to `scripts`, then expand only when a known owner reference requires it.
- Register and replay memory before any corrected source-map search.

## Disposition

Registered truthfully. Prior direct evidence that current final writers accept caller success inputs remains valid; the 411-file result proves nothing about producer availability.
