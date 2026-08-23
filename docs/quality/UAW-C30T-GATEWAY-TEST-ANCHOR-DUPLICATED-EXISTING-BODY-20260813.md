# C30T gateway test anchor duplicated existing body

- Regression: `REG-20260813-1973-C30T-GATEWAY-TEST-ANCHOR-DUPLICATED-EXISTING-BODY`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Result: redundant test mutation must be removed before qualification.

The negative-test insertion copied the existing SharedSession acknowledgement
test and renamed the original declaration, leaving duplicate coverage. The
correction must preserve one original test and insert only the two new negative
gateway tests before it.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
