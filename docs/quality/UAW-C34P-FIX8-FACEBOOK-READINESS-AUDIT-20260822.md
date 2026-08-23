# FIX8 Facebook readiness audit

State: `root_cause_proven_dev_firebase_facebook_provider_absent_external_configuration_and_successor_live_acceptance_pending`

Founder-supplied notification evidence proves Facebook authorization and
public-profile consent completed for r60.81. The unresolved boundary begins
after provider authorization and covers app return, native token handoff,
Firebase credential exchange and JourneySession completion. This owner retains
only sanitized facts and no account identity, app identifier, key hash, token,
secret or private provider output. No provider tap, private login, build,
install, deployment or external mutation is authorized by this document.

## Outcome

The r60.81 failure is not a failure to obtain Facebook authorization. Founder-
supplied notification evidence proves authorization and `public_profile`
consent completed. Founder Firebase Console evidence then proves Google is
enabled while Facebook is absent from the configured Authentication provider
list. The smallest proven root cause is therefore the post-provider Firebase
credential-exchange boundary: the native SDK can return an access token, but
Firebase cannot accept a Facebook credential while its Facebook provider is
not configured.

The generic Screen03 heading alone cannot classify that boundary. The current
adapter already maps Firebase `operation-not-allowed` to the sanitized
`configurationUnavailable` outcome, and the gateway/session then return safe
customer recovery without exposing provider detail.

## Source trace

- `apps/mobile/lib/core/auth/facebook_native_sdk_adapter.dart:304` starts the
  native-only SDK flow; lines 347-359 extract the transient token without
  persistence; lines 363-392 exchange it through
  `FacebookAuthProvider.credential` and Firebase Authentication.
- The same owner maps `operation-not-allowed` and invalid credential classes to
  configuration unavailable at lines 503-513. No source rewrite is needed to
  explain or safely classify the proven provider-disabled result.
- `apps/mobile/lib/features/journey01/review_journey_services.dart:706` delegates
  Facebook to the native adapter; lines 825-850 require a completed Firebase
  user and preserve sanitized failure classes.
- `apps/mobile/lib/features/journey01/journey_session.dart:519` completes account
  bootstrap only after provider authentication. Lines 1041-1071 persist a
  successful session or roll back incomplete social authentication. A provider-
  disabled Firebase exchange fails before successful session completion.
- `apps/mobile/lib/core/auth/public_auth_runtime_configuration.dart:95` already
  requires `facebookProviderQualified` among all Facebook availability facts.
  The defect is the unproven runtime/readiness input that allowed r60.81 to
  expose Facebook, not the boolean availability predicate.

The current sanitized readiness owner is also inconsistent with r60.81
exposure: native-login qualification, complete signing-hash qualification,
exact redirect qualification, versioned revocation qualification and build-
value qualification are still false. It contains no authoritative Firebase
Facebook-provider-enabled receipt.

## Focused verification

- `uaw_c34p_facebook_native_sdk_adapter_test.dart`: 18/18 passed. This includes
  minimum permission, direct token handoff, Firebase
  `operation-not-allowed` mapping, sanitization, logout and revocation.
- `firebase_social_auth_gateway_test.dart`: 18/18 passed. This includes
  fail-closed adapter availability, Firebase-session success and sanitized
  Facebook failures.

These source tests prove safe composition and failure handling. They do not
prove live provider enablement, a successful private credential exchange or
authenticated relaunch.

## Smallest production-grade repair boundary

1. In the exact Dev Firebase project, the founder or authorized account owner
   enables the Facebook Authentication provider using the correct Meta app
   values without exposing them to Codex, repository output or evidence.
2. Retain an authoritative sanitized readback that Facebook is present and
   enabled. Until that receipt exists, set the Facebook provider-qualified fact
   false and keep the Facebook control unavailable.
3. Bind the next APK/AAB prebuild gate to that receipt so a caller-authored or
   hardcoded true value cannot expose Facebook again.
4. Under separate successor build/install and founder-private-login authority,
   prove native return, Firebase credential exchange, JourneySession ready,
   exact destination, cancellation/error rollback, sign-out and authenticated
   relaunch on the checksum-matched OPPO candidate.

No additional provider tap, private login, source rewrite, device action,
build, cloud write, deployment or credential access occurred in this audit.
