# REG2919 — FIX3 restart handoff raw-read truncation

## Observed event

During mandatory restart reconstruction, the journey-adapter subagent invoked a raw read of the complete `docs/quality/ACTIVE-CODEX-HANDOFF.md`. The owner is 9,878 lines and the tool explicitly truncated its 130,308-token result to an incomplete projection.

## Impact

- The command was read-only.
- The subagent stopped before reading an assigned owner, editing, parsing, testing, or invoking any real journey, device, private, build, browser, provider, or external action.
- The capture-producer owner was frozen before registry movement.

## Root cause

The restart instruction required the current bounded checkpoint, but the subagent selected `Get-Content -Raw` on the entire append-only handoff.

## Mandatory prevention

1. Discover the current checkpoint heading with a bounded fixed-string projection.
2. Read only that checkpoint in independent, non-overlapping pages of at most 100 lines.
3. Never raw-read the complete active handoff or group several dense ranges into one output.
4. Treat explicit or semantic truncation as zero reconstruction evidence and stop before any owner action.
