# REG-20260822-3197 — Shared-auth bounded source read tool-context truncation

## Incident

A bounded read of the shared-auth gate source returned a tool-level
context-truncation result. The incomplete output was rejected as evidence.

## Impact

- Fresh build authorization consumed: `false`
- APK builds: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The requested source slice and output allowance remained too broad for the
active conversation context.

## Permanent prevention

Register every truncated read before retry. Locate one exact literal anchor
first, then read only the smallest independently bounded source slice needed
for the decision. Never infer completeness from truncated output.
