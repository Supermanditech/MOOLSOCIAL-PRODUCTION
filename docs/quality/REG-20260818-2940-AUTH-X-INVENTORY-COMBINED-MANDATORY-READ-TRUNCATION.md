# REG2940 — Authentication X inventory combined mandatory-read truncation

## Observed event

On resumed reconstruction, the X inventory agent combined both AGENTS owners, coordination policy/JSON, REG2938/2939 and the large regression-memory document into one command. The result truncated at approximately 55,713 original tokens / 3,328 lines. The agent stopped before memory/coordination gates, web research, its source-map owner, provider/private/device actions, or external writes.

## Root cause

Mandatory reads were treated as one aggregate output budget. The dense append-only regression memory alone requires bounded independent paging.

## Mandatory prevention

1. Read every mandatory owner in its own command/result.
2. Read `CODEX-DEVELOPMENT-REGRESSION-MEMORY.md` in independent, non-overlapping pages of at most 250 lines through verified EOF.
3. Never group regression memory with AGENTS, handoff, registry, policy, ticket, or source owners.
4. Explicit or semantic truncation is zero reconstruction evidence and blocks gates/action.
