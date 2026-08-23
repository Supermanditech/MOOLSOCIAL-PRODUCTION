# REG-20260821-3117 — Subagent policy activeTasks versus activeClaims

Date: 21 August 2026
State: registered; subagent stopped before gates

## Failure

The Android release audit subagent parsed the current coordination policy but
projected `$j.activeTasks` for its claim. The actual root property is
`activeClaims`, so the task projection returned null.

## Impact

- The subagent stopped before regression/coordination gates, source audit,
  tests or report write.
- No product, build, provider, Play, OPPO or private state changed.

## Root cause

The subagent guessed a condensed property name rather than selecting from the
already available exact root-property inventory.

## Prevention

Use `activeClaims`, filter its `task` field for the canonical task, require one
result and one exclusive owner, then run the gates with the refreshed binding.
Never convert the human phrase active tasks into a JSON property name.
