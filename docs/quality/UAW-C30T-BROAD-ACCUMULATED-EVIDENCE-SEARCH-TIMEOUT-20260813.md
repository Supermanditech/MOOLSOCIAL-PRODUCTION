# C30T broad accumulated evidence search timeout

- Regression: `REG-20260813-1988-C30T-BROAD-ACCUMULATED-EVIDENCE-SEARCH-TIMEOUT`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: the timed-out lookup is rejected as evidence.

A regression lookup unnecessarily traversed the accumulated artifacts tree and
timed out. Current work now reads the exact registry and permanent memory owners
directly and caps any filename inventory.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
