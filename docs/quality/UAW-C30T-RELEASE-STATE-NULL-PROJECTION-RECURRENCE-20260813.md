# C30T release-state null projection recurrence

- Regression: `REG-20260813-2002-C30T-RELEASE-STATE-NULL-PROJECTION-RECURRENCE`
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Result: all null fields from the guessed projection are rejected as evidence.

The reconciliation correctly read the protected machine state and aggregate
1/1/1 counts, but guessed several other nested paths and returned nulls. This
repeated REG-1976. The corrected audit enumerates exact current object property
names before projecting only non-null values.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
