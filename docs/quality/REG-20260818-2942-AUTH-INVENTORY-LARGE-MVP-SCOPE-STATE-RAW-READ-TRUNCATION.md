# REG2942 — Authentication inventory large MVP scope-state raw-read truncation

## Observed event

The X and Facebook inventory agents independently raw-read mandatory `config/mvp-scope-gate-state.json`. At 5,166 lines / approximately 100,196 tokens, both results truncated. Both agents stopped before memory/coordination gates, web research, assigned-owner edits, provider/private/device actions, or external writes.

## Root cause

The machine policy required the scope state but did not define a bounded semantic projection for this append-heavy JSON, so agents treated it as a small owner.

## Mandatory prevention

1. Parse the JSON without emitting it.
2. Emit exact bytes/lines/hash, root property names, and only the current `state`, `ticket`, `founderDisclosure`, `authorization`, `execution`, `preTicketSelectionCheckpoint`, `checkpoint`, and `providerGate` subtrees.
3. Project only scalar fields and bounded arrays; never expose secret/private values.
4. Read a named historical subtree only when the applicable ticket requires it.
5. Never raw-read or fully emit the complete MVP scope state.
