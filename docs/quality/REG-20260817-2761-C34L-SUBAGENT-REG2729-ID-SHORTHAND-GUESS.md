# REG2761 — C34L subagent REG2729 ID shorthand guess

Date: 17 August 2026
State: registered read-only projection failure; no mutation

## Mistake

The PRE-AAB-3 agent parsed the regression registry and searched the `id`
property for the shorthand value `REG2729`. Registry IDs use their complete
durable form, so the projection returned null and the agent threw
`REG2729 missing`. The agent stopped without retry or mutation. No candidate,
seal, cycle, build, Play, OPPO, browser, device, private, secret or external
state changed.

## Root cause and prevention

The requested incident number was treated as an exact registry ID without
first discovering the complete ID or its durable document path. Resolve
incident references from `rg --files` or project full registry IDs ending in
the exact numeric segment; then read the resolved literal owner. Never invent a
shorthand registry key.
