# C30T Feed interaction single-flight finding

Date: 2026-08-13

`SharedSession._runSocialInteraction` does not own pending state. Like, Save and poll/quiz choices therefore remain tappable until the provider responds. Concurrent toggles can race, while concurrent votes can produce one success and one conflict whose order misrepresents the final authoritative item.

The bounded correction owns one in-flight mutation per post, disables all mutation controls for that post until completion, sends at most one provider request and applies only the provider-returned item. It does not add optimistic state, a backend owner or external writes.

## Implemented and verified

`SharedSession` now owns one in-flight interaction per post and notifies Feed before and after the request. Like, Save and all poll/quiz choices are disabled while the post is pending. A concurrent second request returns false without transport; only the server-returned item becomes success state.

- focused result: 20 passed, 0 failed.
- evidence SHA-256: `F442D2DAC878D4FDE16ED38E8D4A9924C722AC328130C68E9C42A827FEDF1F8C`.
- release registrant restored to exact 15 plugins, no `IntegrationTestPlugin`.
- release APK unchanged/absent; preserved C30S AAB unchanged at SHA-256 `2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`.

No build, provider/backend, Hosting, Play, OPPO or communication mutation occurred.
