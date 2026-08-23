# C30T Feed error multiline-semantics anchor rejection

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: navigation-only Feed CTA reproduction

The exact `Open Feed, MoolSocial` target was selected and tapped once. The resulting hierarchy contains `Feed, current, MoolSocial`, a composite multiline error node whose normalized content begins with `We couldn’t refresh your Feed`, and a separate `Create a post` label. The postcondition incorrectly anchored the error description to end after its heading and stopped after the successful transition.

No Feed retry or Create action occurred in this step. The next action must retain the current Feed state, parse the first normalized error token, resolve `Create a post` to one enabled clickable target or shared ancestor from a new hierarchy, tap it once, and recapture the result.
