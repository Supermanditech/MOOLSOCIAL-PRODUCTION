# C30T reply boundary recovery message was generic

- Regression: `REG-20260813-1969-C30T-REPLY-BOUND-RECOVERY-MESSAGE-GENERIC`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Focused result: 20 passed, 1 failed; the run is rejected.

A 501-character reply was safely rejected, but the backend returned the
generic `body is invalid` message. The ticket requires a bounded, actionable
reply contract, so the service must explain that replies are 1 to 500
characters before any repository write.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
