# C30T gate defect-list stale patch-context rejection — 2026-08-13

## Rejection

A multi-file patch expected conventional trailing-comma formatting in the
C30T gate defect list. The exact dirty-tree file used leading commas for the
supplemental entries, so apply-patch rejected the operation atomically.

No file from the rejected patch changed. In particular, no ticket, machine
state, source, backend, device, release or external state was mutated.

## Permanent prevention

Read exact file text immediately before dirty-tree edits, preserve its current
format, and apply machine-state, registry, ticket and documentation updates as
smaller atomic patches. Parsed JSON renderings are not patch context.
