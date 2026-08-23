# C25H malformed machine-state authorization patch

Date: 2026-08-09

## Rejection

The first multi-section APK machine-state patch contained a malformed escaped
removed-line marker. Patch verification rejected the entire machine-state
mutation.

Ticket/scope intent had already opened build authority, but the independent APK
machine state remained the rejected-r60.23 closed state, so the wrapper could
not build.

## Recovery

The retry uses small exact machine-state sections, updates the regression count
and source-manifest checksum, then requires a positive machine-gate proof before
the single wrapper build.

## Permanent rule

No partial or assumed machine-state authorization may reach the build wrapper.
