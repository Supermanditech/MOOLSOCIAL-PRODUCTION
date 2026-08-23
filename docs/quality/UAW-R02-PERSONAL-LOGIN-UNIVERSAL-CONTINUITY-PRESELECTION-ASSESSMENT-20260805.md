# UAW-R02 preselection robustness/reuse assessment and disclosure

Date: 5 August 2026
Ticket: `UAW-R02-PERSONAL-LOGIN-TO-UNIVERSAL-CONTINUITY`
State: `ASSESSED_AND_SELECTED_FOR_TEST_ONLY_ACCEPTANCE`

## Customer outcome and classification

After successful email OTP, mobile OTP, supported provider authentication or
retained authentication, the normal Personal user reaches Universal without a
mandatory role, profession or workspace choice. A valid protected return route
is restored only after authentication.

Classification: `mvp_required`. Login-to-Universal continuity is the entry to
every launch action and prevents the workspace system from becoming a false
mandatory account type.

## Reuse and duplicate inventory

The existing locked owners already implement the required behavior:

- `JourneySession._completeAuthentication` owns exactly-once account bootstrap
  and the transition to `JourneyStage.ready`;
- `JourneySession.readyRoute` returns a captured protected route or the normal
  `/app/social` Universal entry;
- `JourneyRouter.redirect` prevents every `/app/**` route before ready and
  restores the exact protected route after ready; and
- locked Screen 03 email/mobile/provider UI owns authentication input and
  recovery.

Existing `screen03_session_test.dart` covers provider success/failure and OTP
process-death recovery, but it is a locked test and remains unchanged. The
smallest non-duplicate implementation is one additive R02 acceptance test for
email, mobile, retained-auth and protected-return outcomes.

Implementation disposition: `test_only_acceptance`. No new screen, route,
service, session, state owner or backend owner is necessary.

## Explicit exclusions

- No edit to locked Screens 01–03 source, accepted references, goldens or
  locked tests.
- No role/workspace selection, workspace creation or local capability grant.
- No provider/backend write, build, install, OPPO replay, external action,
  commit, push, deploy or promotion.

## Dependencies and evidence

- Locked Screens 01–03 and their current `JourneySession`/`JourneyRouter`
  owners.
- Parent manifest SHA-256
  `45D765390EA6B2D94F334CB4F5B2AB67162657A447B220A10650EB7621DB34A8`.
- Run focused R02 tests, existing Screen 03 session tests, format/analyze for
  the additive file and the Screens 01–03 protected gate.

Timeline impact: one engineering day or less. The ticket is within the
60–75-day delivery lock.
