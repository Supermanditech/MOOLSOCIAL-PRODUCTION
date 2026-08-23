# C30T Create media-picker failure-containment finding — 2026-08-13

## Finding

Native image, carousel, image-poll, reel and interrupted-selection calls had
`finally` cleanup but no exception containment. A plugin or platform failure
could therefore escape the Create future as an unhandled UI error instead of
showing a retained-draft recovery.

## Correction

Every native media-selection boundary now catches unexpected failures, releases
the selection busy state, preserves the complete in-memory draft and displays
fixed image/video recovery copy. Interrupted-selection recovery is also
fail-closed. Private platform exception details are not rendered or persisted.

## Verification

A widget test enters production draft copy, injects a private native picker
failure, and proves the fixed recovery message is visible while the exact draft
text remains. The complete Social publication suite, including all five
MoolSocial-hosted formats, passed `15` tests. Evidence SHA-256:
`D69533431E78712B69D558D70F1F160C0AF03B8711ABBC61ED3A50143BCA0961`.

No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
