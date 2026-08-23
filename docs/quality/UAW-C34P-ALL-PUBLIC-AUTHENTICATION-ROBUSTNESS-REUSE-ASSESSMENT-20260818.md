# UAW-C34P all-public-authentication robustness and reuse assessment

Date: 18 August 2026 (IST)
Ticket: `UAW-C34P-ALL-PUBLIC-AUTHENTICATION-SHARED-GATEWAY-EXECUTION`
Classification: `beyond_mvp`
State: selected parent assessment for source and local-test execution

## Customer outcome and classification

A signed-out Personal user can use Google, YouTube through the same Google
identity, Firebase passwordless email link, Firebase mobile OTP, X or Facebook
from the existing MoolSocial login gateway. Each available method reaches the
exact protected destination once or returns a truthful, sanitized, recoverable
public result.

Google/YouTube, passwordless email link and mobile OTP are launch-required.
The parent is classified `beyond_mvp` because it deliberately includes the
separately and explicitly founder-authorized X and Facebook expansions in the
same non-duplicating implementation wave.

## Reuse and duplicate inventory

- Presentation: reuse founder-approved Screen 03 v5 and its existing
  `LoginScreenV5`; no presentation owner is edited.
- Route/lifecycle: reuse `/sign-in`, `/verify`, `MoolSocialApp` route-information
  delivery and `JourneySession`; no route or lifecycle owner is duplicated.
- Protected return and rollback: reuse `JourneySession` authentication return,
  bootstrap, Firebase rollback, relaunch and sign-out owners.
- Google/YouTube: reuse `NativeGoogleIdentityGateway` and
  `FirebaseSocialAuthGateway`; both controls already select one Google ID-token
  and Firebase credential path.
- Passwordless email: reuse `EmailLinkGateway`, `FirebaseEmailLinkGateway`, the
  C33J foreground/cold-return owner, exact Android App Links and the C33J/FIX1/
  FIX2 focused suites.
- Mobile OTP: reuse `OtpGateway`, `FirebaseOtpGateway`, C33H bootstrap rollback,
  India-only policy evidence and independent phone-auth tests.
- Account/session: reuse `AccountBootstrapGateway`, the one Firebase session and
  current protected destination persistence.
- Duplicate searches found no second production login screen, route, session,
  passwordless gateway, Phone Auth gateway or bootstrap owner is necessary.

## Smallest complete implementation

Implementation dispositions are `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance` and `new_necessary_work`.

The new necessary work is limited to:

1. one centralized sanitized public-authentication failure taxonomy used by
   GoogleSignIn, Firebase social, Phone Auth and Email Link boundaries;
2. one non-secret runtime availability/configuration contract that keeps each
   control disabled until all of its exact dependencies are qualified;
3. one pure X OAuth 2.0 authorization-code/PKCE contract with high-entropy
   state and verifier, S256, exact redirect, minimal scopes, single-use callback,
   expiry and revocation semantics;
4. one Facebook Login contract for `public_profile` only, exact Android
   package/activity/key-hash/redirect facts, cancellation, logout/revocation
   and data-deletion readiness; and
5. focused source/configuration/privacy tests plus one C34P static gate.

No new screen, route or backend owner is authorized or required. X cannot be
truthfully converted into a Firebase session by reusing Firebase's Twitter
provider: the Firebase provider requires the legacy OAuth 1.0 credential pair,
whereas the founder requires X OAuth 2.0 authorization code with PKCE. Firebase
custom authentication requires a server to validate the X result and mint a
Firebase custom token. Backend source writes are outside this parent authority,
so source will expose and test the exact PKCE boundary while keeping public X
availability fail-closed until an existing or separately authorized broker is
qualified. This is a disclosed dependency, not a protocol downgrade.

Facebook native Firebase authentication likewise remains fail-closed until the
native Facebook SDK path and exact non-secret app/package/activity/key-hash/
redirect configuration are present. The contract requests no email permission
by default and never commits an app secret, client token or access token.

## Robustness coverage

- GoogleSignIn and Firebase errors map by enumerated code; provider messages,
  email fields and credentials are never returned to UI or evidence.
- Google and YouTube cannot diverge into different identity or Firebase paths.
- Email Link covers foreground, cold start, same-device confirmation after
  process loss, invalid/expired/used/replayed callback, exact return and
  bootstrap rollback without persisting email or link values.
- Mobile OTP covers send, automatic/manual completion, timeout, invalid,
  expired, resend, process return, exact return and bootstrap rollback without
  persisting phone or OTP values.
- X covers state, verifier/challenge, S256, exact redirect, minimal scopes,
  callback cardinality, expiry, denial, cancellation and revocation without a
  client secret or retained token evidence.
- Facebook covers minimum permission, exact Android/provider configuration,
  cancellation, account collision, logout/revocation and data-deletion
  readiness without default email permission.
- Account collision, missing configuration, provider denial, network failure,
  throttling, rollback, sign-out and protected return remain fail-closed.
- Screen 03 presentation, accepted references, locked tests, C34L work and the
  rejected r60.72 candidate remain untouched.

## Explicit exclusions and dependencies

Excluded: duplicate UI/routes/sessions/backends; numeric email OTP exposure;
separate YouTube credentials; Instagram or Apple expansion; provider-console
writes; app/key creation; secrets or private account data; real SMS/email;
funds; build; Play; OPPO; commit; push; merge; and any r60.72 reuse.

External dependencies remain founder-owned: qualified Google/Firebase/Play
signing facts; Firebase Email Link/Phone/App Links/attestation configuration;
X native-public-client app, exact callback and a separately authorized custom
Firebase-token broker; Facebook native SDK/app/package/activity/key hashes,
valid redirect, privacy and data-deletion endpoints; and a later separately
authorized release candidate.

## Test and timeline assessment

Run focused unit/widget/configuration/privacy tests, whole-mobile analysis, the
existing C33H/C33J/Google shared-identity matrices, approved UI locks and two
affected regression passes. Live provider, email, SMS, build and OPPO evidence
remain separate.

The shared wave adds zero routes, zero screens and zero backend owners and does
not change the 60–75-day public-go-live planning window. Timeline impact is
recorded as zero calendar days; unresolved external provider prerequisites are
reported rather than hidden by weakening the contracts.
