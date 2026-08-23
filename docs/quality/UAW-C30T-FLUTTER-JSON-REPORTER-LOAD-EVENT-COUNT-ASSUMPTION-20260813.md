# C30T Flutter JSON reporter load-event count assumption

- Regression: `REG-20260813-2001-C30T-FLUTTER-JSON-REPORTER-LOAD-EVENT-COUNT-ASSUMPTION`
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Result: the unfiltered 459-event total is rejected as authored-test inventory.

The JSON reporter replay returned process exit zero, zero failure events and
459 successful `testDone` records. Exactly 58 were synthetic per-file load
events, one for each manifest owner. The corrected parser joins start metadata
by test ID, excludes only hidden/loading protocol tests and emits both raw and
filtered totals.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
