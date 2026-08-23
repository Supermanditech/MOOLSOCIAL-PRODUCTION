# C30U C30J journey-store types missing direct import

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Failure

The C30J fixture reused `MemoryJourneyStore` and `JourneySnapshot`, but the
focused analyzer rejected both names as undefined in the C30J owner.

## Root cause

The fixture body was copied from a passing Social test without also copying the
types' exact direct declaring import. `journey_session.dart` does not re-export
these store/model types.

## Prevention

Read the passing test's current import block, identify the exact declaring
library, add that direct import only, format, and rerun focused analysis before
any behavior test. Dart imports are never assumed transitive.

## Release effect

The analyzer failed before any test retry, source seal, AAB, upload, Play
activation or device mutation. Counts remain `0/0/0`.

## Repair verification

The current passing owner declares both types through
`package:moolsocial/features/journey01/journey_services.dart`. C30J now imports
that exact library directly. Dart format reports no remaining change, and the
focused three-owner analyzer passes with no issues.
