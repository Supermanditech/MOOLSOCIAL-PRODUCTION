# REG2941 — Authentication X inventory full active-handoff read truncation

## Observed event

After REG2940, the X inventory agent independently read `ACTIVE-CODEX-HANDOFF.md` but interpreted “current bounded checkpoint” as the complete 9,877-line append-only owner. The approximately 132,777-token result truncated. The agent stopped before regression-memory pages, gates, web research, its source-map owner, provider/private/device actions, or external writes.

## Root cause

The policy described a current bounded checkpoint but did not define the exact leading-section extraction algorithm, allowing a full append-only read.

## Mandatory prevention

1. Discover line numbers of only the first two `^## ` headings without emitting handoff content.
2. The current checkpoint is lines 1 through one line before the second heading.
3. Read that range only, in independent non-overlapping pages of at most 250 lines.
4. Never raw-read or fully emit the append-only active handoff.
