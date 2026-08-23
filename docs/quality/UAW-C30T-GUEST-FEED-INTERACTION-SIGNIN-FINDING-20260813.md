# C30T guest Feed interaction sign-in finding

Date: 2026-08-13

Public Feed reads intentionally work for guests. Like, Save and Vote are authenticated mutations, but their card controls call `SharedSession` directly. With no Firebase user, token acquisition produces an inline authentication error and loses the real app sign-in/return journey.

The bounded correction gates only Like, Save and Vote at the Social presentation owner. A guest enters sign-in with `/app/social?sub=feed&item=<postId>` as the return location and makes zero interaction writes. An authenticated user continues through the existing App Check plus Firebase Auth provider operation. Automatic mutation replay, Reply, Repost, share-count changes, backend writes and external actions are excluded.

## Implemented and verified

- Like, Save and all poll/quiz Vote controls share one route-aware authentication gate.
- Guest taps start real sign-in with the exact Feed item return URI and leave the item unchanged.
- Authenticated interactions retain the existing server-acknowledged SharedSession operation.
- focused result: 19 passed, 0 failed; SHA-256 `880F3916BF201034DA854E6A66C9EED3F48F6ABF17CDA8D3B5E8436CA3257AAC`.
- release state readback: exact 15 plugins, no integration-test plugin, release APK absent, preserved C30S AAB SHA-256 `2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`.

No build, backend/provider, Hosting, Play, OPPO or communication action occurred.
