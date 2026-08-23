# C30T Node dot reporter lacked an explicit total

- Regression: `REG-20260813-1990-C30T-NODE-DOT-REPORTER-NO-EXPLICIT-TOTAL`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: the uncounted dot stream is not final backend qualification evidence.

The installed Node dot reporter bounded its output successfully but did not
print a numerical total. The replay wrapper must preserve the Node exit and
emit an exact count of the reporter dots so both success and inventory are
machine-readable without a verbose stream.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
