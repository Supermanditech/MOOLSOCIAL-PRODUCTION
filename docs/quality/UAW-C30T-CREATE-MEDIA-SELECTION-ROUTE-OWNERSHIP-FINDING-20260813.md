# C30T Create media-selection route-ownership finding — 2026-08-13

## Finding

A native image/carousel/reel picker result was applied whenever its future completed, even if an explicit route or local tool change had moved the composer to another format. Because the publish mapping used the shared media list for text polls and quizzes, hidden media from an older picker could be sent with the current public post.

## Bounded correction

Give each picker call request-generation and visible format/tool ownership, invalidate it on composer changes, ignore stale results, and derive public media only from the active visible format. Text, choices and existing visible draft state remain intact.

## Verification

A delayed fake-picker widget test opens Image, retains a pending result, changes the same workbench to Quiz, returns the old image, completes all four choices and captures the publish request. The active Quiz remains media-free and the request contains zero media paths. The focused Create/Feed suite passed `17` tests. Evidence SHA-256: `EE8DC3EEDD1FC1F7C9F36F6E96C17C4541F6908DC9BBB320F6654BD9A93F5DDD`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. No real media selection, Create write, backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
