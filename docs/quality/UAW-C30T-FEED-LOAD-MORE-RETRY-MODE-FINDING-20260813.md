# C30T Feed Load-more retry-mode finding — 2026-08-13

## Finding

After a failed later-page request, the cached Feed correctly retained posts,
`hasMore` and its cursor. The visible Retry Feed control nevertheless always
performed `refresh: true`, abandoning the failed continuation and returning to
page one.

## Correction

The Feed session now retains whether the last failed request was a refresh or a
Load more. `retrySocialFeed()` repeats that exact mode, and the visible cached
retry control delegates to it and is disabled while a Feed request is pending.

## Verification

A focused session test proves the request cursor sequence
`[null, next-page, next-page]` across initial load, failed Load more and visible
retry ownership. The C30T auth/Feed suite passed `6` tests. Evidence SHA-256:
`B3A095747C782E28A2437D60F7B657BC0D747A4DDEF7C11E1E56C646090E862F`.

No backend/provider mutation, AAB, Play action, OPPO mutation, Hosting action or
external communication occurred.
