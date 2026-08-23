# C30T poll/quiz expiry-enforcement finding — 2026-08-13

## Finding

The public poll/quiz footer always displayed `Closes in 7 days` before a vote, regardless of the provider `closesAt` timestamp. Choices remained enabled after that time. The Firestore vote transaction enforced one vote per user but did not enforce closure, so a stale or modified client could mutate an expired poll.

## Bounded correction

Derive truthful minute/hour/day/closed copy from `closesAt`, make a missing timestamp carry no invented deadline, disable expired choices, and reject late votes inside the transaction before any counter or interaction write.

## Verification

The complete Create/Feed Flutter file passed `21` tests, including exact minute/hour/day/closed labels and four disabled expired-quiz choices. Flutter evidence SHA-256: `BCD56110848C64847E8E4A2DDF327B4FE427258A1F9FEDFBDBF3B66BC1CEAA19`.

The isolated compiled Firestore repository file passed `9` tests. The expired-vote case proves the transaction rejects at the authoritative instant before either `update` or `set`; existing cursor, idempotency, cleanup and serialization cases remain green. Backend evidence SHA-256: `CA102F6505598459C36D3A997210BB8D1C32A02751E65BBFE5246EDE15B18224`.

Release configuration was restored to 15 plugins with no Integration Test plugin and no release APK. The preserved C30S r60.44 AAB remains byte-identical. No Dev deployment, real vote, AAB, Play, OPPO, Hosting or communication action occurred.
