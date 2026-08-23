# C30T Feed refresh pagination-cursor continuity finding — 2026-08-13

## Finding

`SharedSession.loadSocialFeed(refresh: true)` cleared the committed cursor
before transport. If that refresh failed, cached posts and `hasMore` remained,
but the next Load more call used a null cursor and requested page one again.
Upsert-by-id hid duplicates while preventing the user from reaching later pages.

## Correction

Refresh now passes a null request cursor without mutating the committed cursor.
The cursor and `hasMore` are replaced only by a successful authoritative Feed
response. Cached posts, failure notice and continuation position therefore stay
consistent.

## Verification

A focused session test loads page one with `next-page`, fails a refresh, then
loads more and proves the exact cursor sequence `[null, null, next-page]` and two
distinct posts. The C30T auth/Feed file passed `5` tests. Evidence SHA-256:
`DD28798FBD387C945E322ED0F7007AD0F3ECC924D1E0A51D3D4DB85ACA1E187B`.

No provider/backend mutation, AAB, Play action, OPPO mutation, Hosting action or
external communication occurred.
