# FIX8 Google and YouTube readiness audit

State: `bounded_read_only_audit_complete_runtime_web_client_binding_unproven`

This owner records sanitized Google and YouTube shared-identity readiness for
the rejected r60.81 Dev sideload. It contains no client identifier,
certificate fingerprint, project or account identity, token, secret or private
provider output. No provider tap, private login, build, install, deployment,
cloud read or external mutation occurred in this audit.

## Proven readiness facts

- The Android namespace and application ID are the same fixed package identity
  in `apps/mobile/android/app/build.gradle.kts:138` and `:155`.
- The current Android Firebase configuration exists, parses, contains exactly
  one client for that package, and exposes three Android OAuth client records
  plus exactly one Web OAuth client record. Only counts and equality booleans
  were projected; no identifier or certificate value was emitted.
- A separate sanitized readback proved the installed r60.81 signer is present
  among the Android OAuth certificate registrations. This disproves a missing
  signer registration as the cause of the observed Google/YouTube failures; it
  does not prove the runtime Web client binding.
- The founder-provided Firebase Console readback authoritatively shows the
  Google sign-in provider enabled. No live provider interaction was performed
  by Codex.
- Current release build intermediates cannot be inspected: the Android app
  build root is absent. Therefore generated release google-services resources
  are `not_currently_inspectable`, not proven missing from r60.81. REG3272 and
  REG3273 preserve the rejected path assumptions and the exact absent-root
  readback.

## Shared runtime path

- `apps/mobile/lib/main.dart:147-156` obtains one compile-time Google server
  client value and passes it into release runtime configuration.
- `apps/mobile/lib/core/auth/public_auth_runtime_configuration.dart:64-68`
  exposes Google and YouTube only when that value is non-empty, the provider is
  qualified, and either Play signing or the sideload signing preflight is
  qualified.
- `apps/mobile/lib/main.dart:449-454` constructs that availability policy;
  `:486-488` derives the exported provider set; and `:567-583` composes the
  production Firebase gateway for the FIX8 live-auth mode.
- `apps/mobile/lib/features/journey01/review_journey_services.dart:541-590`
  initializes the native Google identity SDK with the supplied server client,
  requires interactive authentication support, obtains one non-empty ID token
  and classifies SDK cancellation separately.
- `apps/mobile/lib/features/journey01/review_journey_services.dart:623-630`
  exchanges that ID token for a Firebase credential.
- Google and YouTube deliberately share the exact same identity branch at
  `apps/mobile/lib/features/journey01/review_journey_services.dart:714-716`.
  The shared login path requests an identity token only; it does not request
  YouTube Data API scopes and is not a YouTube channel-connection grant.
- Provider SDK, Firebase credential and unexpected-object failures are bounded
  at `apps/mobile/lib/features/journey01/review_journey_services.dart:724-746`.
  Both public buttons can therefore show the same generic not-completed title
  for one underlying Google-identity failure.

## Remaining unproven boundary and leading hypothesis

The current source proves only that the compile-time server client value is
non-empty. The signer gate proves only that the APK signer matches an Android
OAuth registration. Neither proof establishes that the hidden r60.81 runtime
server client value exactly equals the sole Web OAuth client in the Android
Firebase configuration.

That equality is required by the native Google identity flow and is the
smallest shared readiness gap capable of explaining both Google and YouTube
failing despite a registered signer and an enabled Firebase provider. It is a
leading hypothesis, not an asserted root cause: retained r60.81 logs contained
no useful Google, Firebase Auth or App Check markers, and the founder-visible
generic title does not distinguish cancellation, native initialization,
missing token, Firebase credential or post-authentication bootstrap failure.

## Smallest production-grade repair and tests

1. Extend the existing sanitized Android OAuth/signing prebuild gate to require
   exactly one package client, at least one matching Android signer record,
   exactly one Web OAuth client, and constant-time equality between that Web
   client and the hidden runtime server client input. Emit booleans/counts only.
2. Keep Google and YouTube on one shared identity adapter. Do not add YouTube
   API scopes or a second OAuth flow to global login.
3. Preserve a small safe diagnostic class through the session and recovery
   body for: native client configuration, UI unavailable, cancellation,
   missing ID token, Firebase credential rejection and post-auth bootstrap
   rollback. Never expose raw exception text, account data or configuration
   values.
4. Add focused coverage in
   `apps/mobile/test/firebase_social_auth_gateway_test.dart` and the FIX8
   runtime-composition test for Google/YouTube shared dispatch, cancellation,
   each sanitized native/Firebase failure class, null/empty identity, exact Web
   client equality positive/negative fixtures, and rollback after bootstrap
   failure.
5. Re-run the complete affected auth/startup cycles and analyzer before any
   successor build. A later checksum-matched OPPO run remains founder-operated
   at the account chooser/consent boundary and must test Google and YouTube
   independently even though their implementation is shared.

## Acceptance truth

Static source composition, package alignment, provider enablement, Android
OAuth registration shape and installed-signer registration are proven. Exact
runtime Web-client equality, an authenticated Firebase session, protected
return, rollback/retry and OPPO relaunch are pending. r60.81 remains rejected;
this audit does not authorize or recommend reusing it.
