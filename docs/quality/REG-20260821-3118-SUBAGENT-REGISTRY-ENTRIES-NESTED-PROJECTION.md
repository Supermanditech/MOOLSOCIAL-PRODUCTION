# REG-20260821-3118 — Subagent registry entries nested projection

Date: 21 August 2026
State: registered; all three new audit subagents stopped

## Failure

The Android release audit subagent parsed the registry but projected
`$j.registry.entries`. The current registry owns `entries` at the root, so
PowerShell null-to-array coercion produced an impossible count of one and an
empty tail at authoritative generation 3088.

## Impact

- The subagent stopped before gates, Android source audit, tests or report.
- No source, build, provider, Play, OPPO or private state changed.
- The primary stopped all three new audit subagents after repeated mandatory-
  reconstruction schema guesses.

## Root cause

The subagent invented a wrapper object instead of selecting from the exact
root-property inventory.

## Prevention

Registry entries are `registry.entries` only in prose notation; PowerShell
reads `$j.entries`. Require the exact authoritative count before tail access.
For this phase, keep the parallel audit tasks stopped and complete the audit in
the primary process to prevent further registry churn.
