# C30T Create explicit tool-route continuity finding — 2026-08-13

## Finding

The parent Social content key included `_createView`. A new explicit Create
`state=` route therefore remounted the workbench. Because the shared draft was
already initialized, the remounted child correctly retained it but ignored the
new requested Image, Carousel, Image Poll, Quick Poll or Quiz tool.

## Correction

The Create workbench key is now stable across in-place tool changes while real
Social tab changes remain separately keyed. The workbench consumes a newly
changed explicit intent in `didUpdateWidget`, updates the requested tool and
persists the same draft without clearing its content.

## Verification

A widget test enters a Text caption, updates the mounted route to Quiz and
proves the Quiz owner renders with the exact caption retained. The complete
Social publication suite passed `16` tests, including all five hosted formats
and the Feed round-trip draft matrix. Evidence SHA-256:
`07B7423629EED9068705955A8231C9976D837E1AC7A90D40A1F37D980E5970C2`.

No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
