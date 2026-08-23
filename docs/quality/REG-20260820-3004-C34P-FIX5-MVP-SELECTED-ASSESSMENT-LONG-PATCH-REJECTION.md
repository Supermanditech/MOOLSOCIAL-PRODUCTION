# REG3004 — C34P FIX5 MVP selected-assessment long-patch rejection

Date: 20 August 2026 (IST)
State: registered before bounded state retry

## Incident

The primary attempted to replace the complete current
`selectedTicketAssessment` in one long patch. One reconstructed line differed
from the literal current JSON, so `apply_patch` rejected the operation
atomically. The previously read-back `currentTicketId` change remained; no
selected-assessment, runtime, provider, build, Play, OPPO or external state
changed in the rejected operation.

## Root cause

A dense append-heavy machine-state subtree was reconstructed into patch context
instead of updating small, freshly verified field groups. This repeated the
permanent MVP-state long-context rejection class.

## Prevention

Do not retry the long replacement. Update one uniquely anchored scalar or one
small exact array at a time, parse and project the selected assessment after
each accepted hunk, and run the complete scope gate only after the exact ticket
hash, assessment and execution subtrees agree.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/uaw-c34p-fix5-all-eight-public-auth-live-provider-readiness-ticket.json`
- `config/codex-development-regression-registry.json`
