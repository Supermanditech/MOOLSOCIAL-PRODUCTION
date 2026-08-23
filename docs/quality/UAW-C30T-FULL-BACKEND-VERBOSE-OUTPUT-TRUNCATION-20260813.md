# C30T full backend verbose output truncation

- Regression: `REG-20260813-1989-C30T-FULL-BACKEND-VERBOSE-OUTPUT-TRUNCATION`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: the verbose 516-test run is rejected as qualification evidence.

The default Node reporter emitted every passing backend test and exceeded the
evidence channel. Although the command exposed a passing final total, permanent
memory requires an untruncated result. Qualification therefore replays the same
compiled suite with a bounded reporter after explicit typecheck and build.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
