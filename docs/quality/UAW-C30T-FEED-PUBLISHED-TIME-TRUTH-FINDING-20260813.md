# C30T Feed published-time truth finding

Date: 2026-08-13

`SocialPublishedItem` carries the provider-returned `publishedAt`, but `_PublicAuthorLine` renders the literal `Just now` for every item. This makes the real preserved review corpus appear newly published and is not acceptable reviewer metadata.

The bounded correction is presentation-only: derive a deterministic label from `publishedAt`, clamp future/subminute skew to `Just now`, show minutes/hours/days for recent content, and use an English calendar date for older content. No backend, corpus, provider, device, AAB, Play or communication state is changed.

## Implemented and verified

`_PublicAuthorLine` now uses `socialPublishedAgeLabel(item.publishedAt)`. Exact future, subminute, minute, hour, day and seven-day calendar-date boundaries are covered. The focused Feed/Create/Screen 04 corpus passed 47 tests with zero failures.

- evidence: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-continuous-audit-20260813-03/feed-published-time-focused-tests.log`
- SHA-256: `EAA4C904B3B1BC36E1C464942116981257391BF8F8EDBEF60659402BDBA0B165`
- post-test release registrant: exact 15 plugins, no `IntegrationTestPlugin`
- existing release APK/AAB: unchanged

The correction remains source-only. AAB, Play, OPPO, backend/provider and communication authority remain held.
