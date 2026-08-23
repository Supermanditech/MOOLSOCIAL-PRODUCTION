# C30Z r60.48 authentication-method truth and guest Feed recovery

Date: 2026-08-15
Ticket: `UAW-C30Z-R60-48-AUTHENTICATION-METHOD-TRUTH-AND-GUEST-FEED-RECOVERY`
Classification: `mvp_required`
State: unlocked source and dual-host containment passed; locked presentation, provider, deployment and successor release held

## Customer outcome

A signed-out user can browse public Feed. Protected Social writes open a
truthful sign-in surface, only qualified methods are operable, and successful
authentication returns to the exact requested action. Failure, cancellation,
Back and retry remain inside MoolSocial without a false success or half-signed
session.

## Reuse and necessity assessment

The existing `JourneySession` availability set, Screen 03, Firebase/Google/OTP
gateways, production router and Social Feed/action owners are the complete
implementation boundary. No new screen, route, backend service, state owner or
provider adapter is necessary. The smallest repair is configuration and thin
presentation/session policy over those owners plus focused acceptance tests.

The source confirms four facts:

1. production currently allows only Google and YouTube social identity;
2. Screen 03 nevertheless enables all six provider controls;
3. Screen 03 always offers Email and Mobile OTP;
4. the sealed r60.48 runtime definitions do not contain the email OTP base URL.

The founder-reported guest Feed redirect remains a reproduction-required issue
until a test distinguishes Feed tab entry from an expected authentication gate
on a write action.

## Robustness coverage

- one availability owner for visual, semantic and dispatch behavior;
- no gateway call from an unavailable method;
- accurate Google configuration, interruption, cancellation and Firebase
  recovery copy;
- no ambiguous partial social-auth state after account-bootstrap failure;
- guest Feed entry versus create/like/comment/repost/share/save/message gates;
- exact requested-route success, cancel, retry and Back continuity;
- locked Screen 03 layout and provider artwork preservation;
- no external provider, build, Play or OPPO mutation.

## Approval boundary

Founder authorization covers repository ticket/evidence, source and local
test/gate implementation. It does not cover Firebase or other provider-console
mutation, credentials, email/SMS send, deployment, AAB/APK build, Play action
or OPPO mutation. Live provider success and a successor Play-installed device
cycle therefore remain pending later exact approvals.

## Implemented source boundary

- `JourneySession` now blocks unavailable social, email OTP and mobile OTP
  methods before any gateway dispatch.
- External email OTP is available only for a syntactically valid HTTPS runtime
  endpoint; mobile OTP requires `MOOLSOCIAL_PHONE_OTP_ENABLED`.
- A provider credential followed by account-bootstrap failure is signed out so
  retry cannot inherit an ambiguous half-authenticated session.
- The existing guest Feed/read and protected-write return matrix was replayed
  with the focused auth suite: 36 tests passed, followed by 16 runtime/session
  tests; focused analysis was clean.
- The C30Z containment gate passed under PowerShell 7 and Windows PowerShell,
  and the general approved UI locks still pass.

The locked Screen 03 v4 source, behavior/copy tests, fitment tests and goldens
remain unchanged. A visible disabled/unavailable presentation requires a
founder-authorized v5 review workflow and is not claimed complete here.

## Two-cycle source qualification

The current 1,114-file source manifest is
`16F698E97C865CD8CCC75E9EE8C5E99FCCFC16AB9E912A05A67D1C74A3F62361`.
Two identical cycles each passed 418 authored Flutter tests with 3 declared
skips and zero failures/errors, a clean whole-mobile analyzer, both C30Z
PowerShell-host gates, the approved UI lock and exact manifest comparison. The
focused auth/Feed suite passed 36 tests. Backend and Hosting source were not
changed; their sealed 528/8 evidence remains bound through the prior cycle
summaries and was not regenerated through destructive package clean/build
commands.

This qualifies the unlocked source repair only. It does not qualify live
Google, email or phone authentication, the locked v5 presentation, a new AAB,
Play upload/update, OPPO acceptance, deployment or YouTube reviewer readiness.
