# C29M predecessor C29L active-ticket gate ordering rejection

- Date: 2026-08-11
- Active ticket: C29M
- Result: local command stopped before static proof validation; no external mutation

The C29L gate asserts that C29L is the active scope ticket. Running it after the authorized transition to C29M correctly failed. C29L's already sealed host-qualification evidence remains the predecessor proof and is not weakened or regenerated.

C29M continues with its current scope/delivery/regression gates and the proof controller's StaticOnly contract. The predecessor gate is not retried under the successor ticket.
