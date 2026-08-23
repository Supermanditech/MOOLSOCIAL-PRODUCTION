# REG2831 — C34L evidence-audit huge status truncation

Date: 17 August 2026
State: registered read-only audit recurrence; zero mutation

## Mistake

The independent evidence auditor ran mandatory full
`git status --short --branch` against the known huge dirty tree. The command
exited zero but its approximately 143,470-token output truncated at the direct
tool cap, so it cannot serve as complete workspace inventory evidence. No
mutation or later audit command followed.

## Prevention

Accept the exact command only for branch-boundary confirmation, then use
explicit scoped status calls for audited owners. Do not request or depend on the
complete huge dirty-tree body as one direct result.
