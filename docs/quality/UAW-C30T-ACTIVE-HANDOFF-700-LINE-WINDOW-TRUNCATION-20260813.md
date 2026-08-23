# C30T active handoff 700-line window truncation

Date: 2026-08-13
Disposition: resolved diagnostic mistake; truncated window rejected

## What happened

A single-file 700-line read of `ACTIVE-CODEX-HANDOFF.md` still exceeded the
available output context. No portion of that read was accepted as proof that
the required handoff owner had been read.

## Permanent rule

Read this dense handoff owner in explicit 200-line, numbered, non-overlapping
windows through its exact measured EOF. Reject any truncated window in full
and reduce the window again only after registering the recurrence.

No source, ticket-selection state, build state or external service changed.
