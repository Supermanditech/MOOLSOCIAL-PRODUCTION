# UAW C30T r60.45 auth System Back exits MoolSocial — 13 August 2026

From the Play-installed MoolSocial social-provider grid, one Android Back should cancel authentication and return to the originating protected Social route. Instead, MoolSocial left the foreground and the prior Play Store task became resumed. The retained post-Back hierarchy contains zero MoolSocial nodes.

Controlled Feed evidence proves the founder-observed Like chain precisely: one exact guest `Like` opens the MoolSocial sign-in grid while MainActivity remains foreground; the subsequent auth-cancellation contract is what exposes Play Store. Evidence: `51-feed-like-controlled-pre.xml` and `52-feed-like-controlled-result.png` in the sealed C30T artifact directory, screenshot SHA-256 `62BBD3A8C969A2019EB7186C2C3841C7336309DAF5DD6BD5528CC05EFC82B51E`.

The successor must retain the origin/requested route, handle Back as in-app cancellation, and prove Feed Like/Reply/Repost/Share/Save/Message, poll/quiz, Create, Chat and YouTube-channel cancellation and successful-return continuity. No external app or secret data may be manipulated. No second AAB/upload/install is authorized.

## Pre-selection robustness and reuse assessment

- Customer outcome: Android Back cancels authentication inside MoolSocial and returns to the exact protected Social location that requested authentication.
- Duplicate/reuse inventory: `JourneySession.returnTo` and its persisted pending route already own exact post-auth return state; `LoginScreenV2` is the single sign-in screen; `journey_router.dart` already redirects a ready session to `readyRoute()`. No second navigation or auth-origin owner is needed.
- Implementation disposition: reuse the existing session, screen and router and add focused test-only acceptance. No screen, route, backend owner, activity or external-task handling is added.
- Necessity proof: the sign-in page is reached by redirect rather than a pushed route, so a system pop has no in-app predecessor and backgrounds MoolSocial. One bounded `PopScope` plus an explicit guest-auth cancellation transition is the smallest complete correction.
- Robustness coverage: exact Feed, Create, Chat and YouTube return URIs; auth cancellation only when guest-ready and an origin is retained; first-open mandatory sign-in retains its current exit behavior; no external task or Play Store manipulation.
- Explicit exclusions: no route redesign, Activity/task hack, external-app mutation, account/secret access, device action, build, upload, install or external write.
- Dependencies and approvals: founder source-implementation authority, current ticket 1 source repair retained, future Play acceptance separately authorized.
- Timeline impact: one source day, within the locked 60–75 day delivery window.

## Source implementation and non-build qualification

The bounded correction now uses `JourneySession` as the single owner for both the requested post-authentication route and a one-shot authentication-cancellation origin. Protected Feed, Create, Chat and YouTube entries retain their exact Social origin. `LoginScreenV2` intercepts Android Back only for a cancellable guest authentication handoff and returns through the existing ready-route transition. Mandatory first-open authentication cannot be converted into guest access, and successful authentication still opens the originally requested protected route.

Qualification completed without an APK/AAB build, upload, install, device mutation or external write:

- Focused auth/navigation partition: 23 passed.
- Authoritative C30T 59-file Social manifest: 379 passed with 3 declared skips.
- Release generated-plugin registrant restored: 16 allowed release plugins; development integration-test registration absent.
- `flutter analyze`: no issues found.

The source state is therefore `source_implemented_and_non_build_qualified_live_Play_acceptance_pending`. A future separately authorized Play candidate must still prove Android Back and successful-return continuity from Feed interactions, Create, Chat and YouTube on the retained-data OPPO installation. This result is not AAB, upload, install or production-grade device acceptance authority.
