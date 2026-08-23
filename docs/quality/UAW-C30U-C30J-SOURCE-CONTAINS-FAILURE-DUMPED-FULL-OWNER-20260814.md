# C30U C30J source-contains failure dumped full owner

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

The independently named C30J source-shape test failed an exact `contains`
matcher against the complete `social_v2_consumer.dart` string. Flutter's
expanded reporter rendered the entire actual source value, overflowing and
truncating the task output. The transcript is rejected as complete evidence.

The visible bounded assertion was sufficient only to identify the exact stale
token at test line 93:

- Expected: `void _openYouTubeChannelStatus() {`
- Current owner: async `Future<void> _openYouTubeChannelStatus() async {`

Earlier avatar protections in the same test had already progressed, but their
pass is not inferred from the truncated transcript; they must be replayed in a
bounded passing run after correction.

## Root cause

The test used a whole-source `contains` expectation. On failure, Matcher
serialized the entire large source string instead of a bounded diagnostic.

## Prevention

Keep semantic negative assertions, but make owner-shape checks use a bounded
method region or a boolean `source.contains(...)` assertion so failure output
cannot print the complete source. Named expanded diagnostics remain bounded.

## Release effect

No product/test repair has yet been applied. No C30U source manifest or cycle
seal exists; build/upload/install counts remain `0/0/0`.

## Repair verification

The async YouTube status owner is now isolated between its exact signature and
the next method. Callback-presence/absence checks use boolean results, so an
unexpected failure cannot serialize the complete Social source. The exact
C30J source test passes with bounded expanded output.
