# FIX8 X readiness audit

State: `source_ready_broker_dev_evidence_present_x_project_live_readback_and_successor_acceptance_pending`

This owner records sanitized X OAuth 2.0 PKCE, broker, callback, App Check and
session-completion readiness for the rejected r60.81 Dev sideload. It must not
contain client identifiers, endpoint secrets, tokens, account identities or
private provider output. No provider tap, private login, build, install,
deployment or external mutation is authorized by this document.

## Audit boundary

- Branch: `remediation/prototype-conformance-2026-07-20`.
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`.
- Registry generation: count `3244`, SHA-256
  `D51124412FFCA76D4FEAF24D02A94E81E00EE3BBABBC08AF5005542226CC7687`.
- Non-emitting dirty digest: bytes `615166`, records `7501`, SHA-256
  `13ABB2F2E9545B2A8CD077BD17ED28DDEEB8A4A811A54BF54F89D0F35D14E3FD`,
  stderr bytes `0`, exit `0`.
- Regression-memory `implementation/none`, exact recorded subagent claim and
  MVP `-RequireExecutionAuthorized` gates passed at this generation.
- This audit used source and already-retained machine evidence only. It ran no
  test, provider request, browser, cloud, device, build, install or deployment.

## Proven source path

- `backend/functions/src/auth/x_pkce_broker.ts:9-14` fixes the public-client
  flow to OAuth 2.0 and the minimum `tweet.read users.read` identity scopes;
  `offline.access` is absent.
- `backend/functions/src/auth/x_pkce_broker.ts:163-180` admits only exact
  begin and complete request shapes. `:616-667` creates high-entropy one-time
  state and verifier material, stores only the state digest, and sends an S256
  challenge. `:669-774` verifies exact callback/state, consumes the attempt
  before exchange, issues a Firebase custom token only after subject
  verification, and fails closed if access-token revocation is not confirmed.
- `backend/functions/src/index.ts:923-954` verifies a limited-use App Check
  token with replay consumption. `:2818-2837` binds the dedicated public-auth
  runtime and required secret handles without exposing their values.
  `:2925-2966` applies body/App Check checks before routing the exact X begin
  and complete operations and returns only the bounded public envelope.
- `apps/mobile/lib/main.dart:185-206` validates the callback base and obtains a
  limited-use App Check token. `:209-259` bounds network time and response size,
  launches the system browser, and exchanges only the returned Firebase custom
  token. `:376-403` constructs the X adapter only when the three required URI
  inputs are valid and the X/Instagram callbacks are distinct.
- `apps/mobile/lib/core/auth/x_oauth2_pkce_network_adapter.dart:177-263`
  performs App Check-protected begin/complete calls, validates the authorization
  response, launches externally and adopts only a safe Firebase user result.
  `:460-552` binds the X-specific adapter and validates exact redirect, minimum
  scope, state, S256 challenge and authorization-query cardinality.
- `apps/mobile/lib/features/journey01/review_journey_services.dart:637-705`
  composes the real X adapter into `FirebaseSocialAuthGateway` and returns
  authorization-pending after the browser opens. `:749-823` owns both cold and
  foreground callback completion and maps only an authenticated result to a
  completed social sign-in.
- `apps/mobile/lib/features/journey01/journey_session.dart:519-574` keeps the
  social state pending while browser authorization is outstanding.
  `:576-635` completes cold or foreground returns, rolls back incomplete
  authentication and retains truthful failure state.
- `apps/mobile/lib/app/moolsocial_app.dart:172-195` feeds an already-running
  route-information callback through the same session validator, while
  `apps/mobile/lib/main.dart:608-619` handles the cold-start callback.

## r60.81 symptom classification and repair

- Current source at
  `apps/mobile/lib/ui_v2/screens/screen03_login/login_screen_v5.dart:47-55`
  now returns immediately when `SocialAuthState.pending`; it no longer opens
  provider recovery for an expected external-browser handoff.
- `apps/mobile/test/uaw_c34p_fix8_global_social_login_runtime_composition_test.dart:165-199`
  proves that X and Instagram pending states keep their notice and render no
  recovery/failure dialog. This is focused presentation coverage using a test
  gateway; it is not live-provider acceptance.
- The current Screen03 source hash does not match its one recorded row in the
  sealed r60.81 source manifest. Therefore the installed rejected r60.81 does
  not contain this pending-state presentation repair.
- The most likely explanation for the immediate generic r60.81 message is the
  old Screen03 treating a successful browser-open/pending result as a failure.
  This is an inference, not a live-provider diagnosis. If the message appeared
  only after provider return, or if no browser opened, the same generic title
  can also mask App Check, network, provider-project, callback or exchange
  failure. Retained r60.81 logs contain no classifying X/Firebase/App Check
  marker, so the underlying live attempt cannot be proved from retained data.

## Dev readiness truth and remaining gates

- Existing sanitized readiness state records the public-auth broker as deployed
  in Dev, function active, required runtime parameters/secrets qualified,
  public reachability protection qualified, limited-use App Check consumption
  qualified, and X attempt TTL active. No new broker deployment is justified by
  this source audit.
- The same authoritative state still records X provider-project live readiness
  as **not qualified**, and FIX8 records the current authoritative provider
  readback as pending. This is the remaining Dev external blocker; it must not
  be converted into a production-ready claim from source or stale evidence.
- Production-grade acceptance still requires a current sanitized Dev readback,
  full affected X/mobile/backend requalification, a separately authorized
  successor whose checksum binds this repaired source, and founder-owned
  private X consent/account interaction on OPPO covering success, cancel,
  denial, timeout, replay, wrong return, offline, relaunch and sign-out.
- r60.81 remains rejected. Successor build/install authorization is false.
  Provider taps, private login, real authentication, build, install, Play,
  Production and external-write counts for this audit are all zero.

## Audit integrity

The first raw runtime-owner projection emitted source-declared identities and
was stopped and registered as
`REG-20260822-3256-X-SUBAGENT-RAW-RUNTIME-IDENTITY-SOURCE-WINDOW-EMITTED`.
No secret, token or credential value was emitted, and this durable report
contains no runtime identity or configuration value. All resumed source reads
used literal-redacted or boolean/line-number projections.
