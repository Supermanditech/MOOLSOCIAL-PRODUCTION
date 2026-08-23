# C30T required-owner grouped read truncation

Date: 2026-08-13
Disposition: resolved diagnostic mistake; grouped read rejected

## What happened

Nine required UI, release, traceability, copy, state, plan and backlog owners
were concatenated into one pre-implementation read. The tool output truncated
mid-group, so it could not establish a complete read of any later file and the
entire grouped result was rejected.

## Permanent rule

Required owners are read one small file at a time. Large owners are read in
explicit line-numbered, non-overlapping windows through the exact known EOF.
Any truncated window is rejected in full and retried under a smaller window
only after this registry gate passes.

No source, ticket-selection state, build state or external service changed.
