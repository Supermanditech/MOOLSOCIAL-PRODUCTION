# REG2920 — FIX3 restart full dirty-status truncation

## Observed event

During mandatory restart reconstruction, the capture-producer subagent combined `git status --short --branch`, branch, and HEAD commands. The repository's large dirty tree caused the status projection to truncate at 145,730 tokens / 7,109 lines.

## Impact

- The command was read-only.
- Visible branch/HEAD text from the truncated combined result is inadmissible.
- No owner edit, parser, test, build, browser, Play, OPPO, device, private, or external action followed.

## Root cause

An unbounded full-tree status was used in a repository already known to contain thousands of preserved user and agent files, and it was bundled with scalar branch/HEAD evidence.

## Mandatory prevention

1. Run branch and HEAD as independent scalar commands.
2. Use `git status --short --branch --untracked-files=no` only when its bounded size is established; otherwise project the branch header independently and query only the task's literal claimed owners.
3. Never combine potentially unbounded status with authoritative scalar evidence.
4. Treat any explicit or semantic truncation as zero evidence and stop before owner action.
