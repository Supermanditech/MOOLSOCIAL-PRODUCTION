# C30O YouTube player feature-flag exact-whitespace gate rejection — 2026-08-12

## Disposition

Rejected as a source-gate result. No build, device, provider, console or account state changed.

## Mistake

The first release-player source-gate correction bound the feature-flag assertion to one exact newline and indentation sequence. Dart formatting used a different valid layout, so the gate rejected the present build-time flag.

## Root cause

A semantic source requirement was implemented as a whitespace-sensitive multi-line substring.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Assert the independent required tokens `bool.fromEnvironment` and `MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED`.
- Keep the separate prohibition on `kReleaseMode`.
- Retry the same source gate once after the bounded correction.
