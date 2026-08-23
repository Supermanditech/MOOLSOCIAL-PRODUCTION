# C30T AAB count owner top-level field assumption

- Regression: `REG-20260813-1976-C30T-AAB-COUNT-OWNER-TOP-LEVEL-FIELD-ASSUMPTION`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Result: null projection rejected as release-count evidence.

A read-only reconciliation assumed build, upload and install counts were
top-level fields in both C30T state owners. All projected values were null. The
retry must first identify the exact current nested schema and then read only
those non-secret count fields.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
