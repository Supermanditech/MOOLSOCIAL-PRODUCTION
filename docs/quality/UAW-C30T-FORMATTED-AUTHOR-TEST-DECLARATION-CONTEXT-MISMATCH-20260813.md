# C30T formatted author test declaration context mismatch

- Regression: `REG-20260813-1982-C30T-FORMATTED-AUTHOR-TEST-DECLARATION-CONTEXT-MISMATCH`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: patch rejected with zero mutation.

The response-containment test insertion reused a one-line Follow test anchor
from before `dart format`; current source had wrapped that declaration. The
retry must use the exact formatted boundary.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
