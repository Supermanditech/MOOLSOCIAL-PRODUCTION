# C30T YouTube Shorts refresh page-continuity finding — 2026-08-13

## Finding

The YouTube Shorts catalogue could refresh from several items to fewer items
while the viewer was on a removed later page. The active-page index remained
outside the new bounds, so every remaining item rendered as inactive and no
official player owned the visible Short.

## Correction

A successful Shorts refresh now clamps the active page to the new catalogue
bounds and restores the `PageController` to that page after rendering.

## Verification

A widget test starts on the third cached Short, retries a failed refresh and
receives a one-Short catalogue. The remaining first Short becomes the active
official-player owner. The catalogue continuity suite passed `5` tests.
Evidence SHA-256:
`871B05EB087FB6DFDBBC7E3FE94F95A5E6701823823F427196A8E122E31A2FE3`.

No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
