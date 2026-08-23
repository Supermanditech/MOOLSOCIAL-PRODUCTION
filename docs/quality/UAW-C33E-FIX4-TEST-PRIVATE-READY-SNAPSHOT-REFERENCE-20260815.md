# UAW C33E FIX4 test private ready-snapshot reference

Date: 2026-08-15
Regression: `REG-20260815-2351-C33E-FIX4-TEST-PRIVATE-READY-SNAPSHOT-UNAVAILABLE`

## Failure

The first FIX4 analyzer run failed because the new ticket-specific test referenced `readySnapshot`, a private top-level constant owned by the separate C30T test library.

## Root cause and recovery

The fixture was copied by name without checking Dart library visibility. Before retry, define a ticket-local immutable `JourneySnapshot` with the exact ready preconditions, format the full owner and rerun the same complete analyzer and focused test set.

Production runtime behavior was not exercised by the failed analyzer run. No build, provider, device or release action occurred.
