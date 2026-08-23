# C30O YouTube player stale debug/profile-only test expectation rejection — 2026-08-12

## Disposition

Rejected test cycle. No AAB/APK build, device, provider, console or account state changed.

## Mistake

The first focused player test cycle was run after the source and PowerShell gate were updated for release registration, but `youtube_embedded_player_android_test.dart` still asserted the superseded `!kReleaseMode` debug/profile-only boundary.

## Root cause

The exact release-boundary test owner was discovered but not updated before executing the focused suite.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Update the existing test to require build-flag control, release registrar registration and release reuse of the exact native player, while prohibiting `kReleaseMode`.
- Rerun the same three focused player test files once.
