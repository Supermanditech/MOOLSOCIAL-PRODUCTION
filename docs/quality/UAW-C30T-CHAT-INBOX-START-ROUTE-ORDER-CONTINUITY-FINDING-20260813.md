# C30T Chat inbox start-route order continuity finding — 2026-08-13

## Finding

The production Chat inbox consumed its initial filter and `start=` recipient only during `initState`. If the router reused that inbox State while direct-thread creation for an older recipient was pending, the newest route could be ignored and the older completion could navigate to the wrong conversation.

## Bounded correction

The inbox now reapplies changed session, filter, recipient and return-route inputs, assigns one request generation to the full load/create/navigation chain, serializes overlapping route work, drains to the newest route and rejects stale navigation after every asynchronous boundary.

## Verification

A delayed route-reuse widget test begins direct-thread creation for an older recipient, replaces the inbox route with a new recipient, completes the older request and proves that only the new recipient is created next and opened. The focused production Chat suite passed `5` tests. Evidence SHA-256: `98B902860F1AF2038D5729BCE168006A13EAC78A18CCB4B065AEDCA01929B0DD`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. No message send, backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
