# C30T Comment ticket qualification hash was not resealed

- Regression: `REG-20260813-1975-C30T-COMMENT-TICKET-QUALIFICATION-HASH-NOT-RESEALED`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Gate result: rejected before any build or external action.

The selected ticket JSON changed when source qualification evidence was sealed,
but the scope assessment still held the pre-implementation manifest hash. The
MVP discipline lock correctly rejected the mismatch.

The correction recomputes the exact ticket SHA-256 and changes only the
selected-assessment hash before replaying the gate. This incident does not
authorize an AAB, upload, install, deployment or device mutation.
