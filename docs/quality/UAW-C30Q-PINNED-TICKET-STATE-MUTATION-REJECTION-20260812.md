# C30Q pinned ticket state mutation rejection

Date: 2026-08-12

## Mistake

While sealing the failed Play-install readback, the already selected C30Q ticket
file was changed from its pinned prequalification state to a rejection state.
The MVP delivery discipline lock immediately rejected the next gate because the
selected-ticket manifest hash no longer matched its assessment.

## Impact

- No build, upload, install, device, provider, account, email or quota action
  occurred.
- The install rejection evidence and mutable C30Q machine-result state remain
  valid.
- The gate stopped before journey execution.

## Permanent prevention

Selected ticket manifests are immutable once their assessment hash is pinned.
Record later execution outcomes in separate evidence and the ticket's mutable
machine-result owner; never rewrite the pinned ticket to express a runtime
failure. Restore the exact pinned ticket text before retrying any gate.
