# C30T Social unexpected-failure containment finding — 2026-08-13

## Finding

The Shared Social session handled the app's typed gateway failures, but an
unexpected Firebase plugin, platform or response-boundary exception could
escape Feed refresh, Create publish or Like/Save/Vote futures. That could
produce an unhandled UI error instead of the required retained-state recovery.

## Correction

The Shared Social boundary now contains untyped failures with fixed customer
copy. Feed keeps its cached posts and retry mode, Create returns a failed result
without clearing its draft, and interactions preserve provider-owned post state
while storing a visible error for the exact post. Private exception detail is
not rendered or persisted.

## Verification

A focused test injects unexpected failures through Feed, publish and Like. All
three return a truthful failure, the existing post remains identical, Like
remains false and sanitized messages are available. The suite passed `7`
tests. Evidence SHA-256:
`D5DB1F09D0CC74587753BD8A1365BA4CA184032F4FB2B74CA92F3E5B88A26C7A`.

No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
