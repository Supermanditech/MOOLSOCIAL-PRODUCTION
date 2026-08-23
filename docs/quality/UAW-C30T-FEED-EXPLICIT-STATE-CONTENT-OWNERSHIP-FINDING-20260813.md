# UAW C30T Feed explicit-state content ownership finding — 2026-08-13

## Finding

The 57-file serial C30T regression completed 346 tests and exposed two Feed
failures. The `loading` state wrapper could render without its progress
indicator, and the `unavailable` state wrapper could render without its retry
control. In both cases the status card was conditionally suppressed by a
non-empty content list whose asynchronous owner was independent of the
explicit named state.

## Bounded investigation and correction

The failures must first reproduce in their two exact files. The intended
boundary is:

- explicit loading/error/unavailable routes fail closed and own their status
  indicator or recovery control;
- ordinary runtime refresh failures with previously loaded posts continue to
  show those cached posts and the existing cached Feed retry;
- no post, provider, backend or release capability is added.

## Evidence and holds

Initial evidence is retained at
`artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-continuous-audit-20260813-04/05-expanded-flutter-regression-57-files.log`.
AAB, APK, Play, OPPO, Hosting, provider writes and communication remain held.

## Result

Both failures reproduced in the exact two-file run. Explicit non-empty Feed
states now own the fail-closed status card regardless of asynchronously held
content, while the ordinary `empty` runtime state continues to render cached
posts, the refresh-failure notice and `screen04-feed-cached-retry`. The focused
set passed 19 tests (SHA-256
`F29B727F98BF2E1DDB68A5F5CDF25586033C436B51477695081F22791D03D8E1`)
and the corrected 57-file regression passed 349 tests with 3 skips and zero
failures (SHA-256
`71115A25D3786DEA9A9C3AF0FE5FC53CC89D42CB4FCBA55ABB537CA8C404AA68`).
