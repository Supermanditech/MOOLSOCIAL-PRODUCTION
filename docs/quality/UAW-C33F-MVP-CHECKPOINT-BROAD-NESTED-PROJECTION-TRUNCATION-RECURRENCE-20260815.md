# UAW C33F MVP checkpoint broad nested projection truncation recurrence

Date: 2026-08-15
Regression: `REG-20260815-2361-C33F-MVP-CHECKPOINT-BROAD-NESTED-PROJECTION-TRUNCATION-RECURRENCE`

While preparing the exact r60.49 release ticket, a read-only inspection converted the complete `preTicketSelectionCheckpoint` object to JSON. That object contains a long chain of historical ticket assessments, so the tool output truncated. This repeats the broad-scope projection class already registered earlier in C33E. No repository, release, device, provider, browser, or external-service state changed.

Recovery: register the recurrence before any further release preparation. Do not retry the broad projection. Every remaining scope or release-state read must use a named scalar/array field allowlist with a bounded output expectation; historical objects are accessed only by a specific property name established through the top-level property-name list.
