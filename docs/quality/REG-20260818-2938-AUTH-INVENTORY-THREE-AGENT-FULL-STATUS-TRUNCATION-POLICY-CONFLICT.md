# REG2938 — Authentication inventory three-agent full-status truncation policy conflict

## Observed event

All three newly started authentication inventory agents independently followed repository `AGENTS.md` step 1 by running full `git status --short --branch` in the known-large dirty worktree. Each result truncated at approximately 146,114 tokens / 7,126 lines. Every agent stopped before memory/coordination gates, web research, its assigned document, source edits, tests, device/provider/private actions, or external writes.

## Root cause

Repository `AGENTS.md` literally required a full status command, while the newer coordination policy prohibited unbounded status projection and required claim-scoped evidence. The instruction conflict made compliant agents repeat the same truncation.

## Mandatory prevention

1. Repository `AGENTS.md` now requires independent scalar branch and HEAD commands.
2. Dirty-tree preservation is proven with a non-emitting porcelain-v1 `-z` byte/count/SHA digest plus literal assigned-owner status only.
3. Full unbounded `git status --short --branch` output is prohibited in this repository.
4. A branch header may be projected alone; it cannot be bundled with unbounded status or scalar authority evidence.
5. The coordination gate statically requires these bounded-status instruction tokens.
