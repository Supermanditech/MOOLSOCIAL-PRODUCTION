# C23E scope transition repeated stale-context rejection

- Date: 2026-08-09
- Phase: C23D to C23E selected-ticket transition
- Result: patch rejected atomically; no scope or runtime mutation

The first transition patch contained many remembered C23D context hunks. One
exclusion line did not exactly match the live scope JSON, so `apply_patch`
rejected the complete patch. This repeated the REG-566 failure class.

REG-20260809-571 makes complete-document replacement from the freshly verified
scope owner mandatory for later C23 transitions. No runtime, build or device
action followed the rejection.
