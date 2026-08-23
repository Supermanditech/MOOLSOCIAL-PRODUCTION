# C30T author card call-site context mismatch

- Regression: `REG-20260813-1979-C30T-AUTHOR-CARD-CALLSITE-INDENT-CONTEXT-MISMATCH`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: patch rejected with zero mutation.

The first consumer call-site patch used reconstructed callback order and
indentation rather than a freshly read exact region. The retry must patch the
literal current card construction.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
