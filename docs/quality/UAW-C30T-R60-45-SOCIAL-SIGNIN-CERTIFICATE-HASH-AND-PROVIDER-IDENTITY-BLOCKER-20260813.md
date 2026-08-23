# UAW C30T r60.45 social sign-in certificate-hash and provider-identity blocker — 13 August 2026

## Release result

The Play-installed `1.0.0-r60.45 (2026081345)` cannot complete the observed social sign-in journey. One exact tap on the Google gate produced a MoolSocial-owned bottom sheet branded as YouTube and stating that sign-in was not completed because the package certificate hash could not be obtained. `Try again` loops to the same sheet. `Choose another method` returns to the provider grid. The founder separately confirmed that the YouTube, X, Instagram and Facebook gates do not proceed.

## Exact evidence

- Screenshot: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/34-auth-google-retry-loop.png`
- Screenshot SHA-256: `E971903AFAD00489C05BE4E41CEDFF82153E5BD1CA1B7B7D9642A6E6A8D2FC22`
- UI hierarchy: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/34-auth-google-retry-loop.xml`
- Installed package: `com.moolsocial.app`
- Installer: `com.android.vending`
- Installed Play signer SHA-256: `47B28C7DDE2B61CAB6A7748C9019A3B57376B3BE1DC163D48253BBA35B63CDD9`

No account identity, password, MFA, credential, token, nonce, private verdict or OAuth payload was inspected or recorded.

## Successor boundary

The smallest complete successor must diagnose the shared Android package-certificate hash owner under Play App Signing, preserve the provider actually selected through loading/cancel/error/retry, and return successful authentication to the requested Social route. Google, YouTube, X, Instagram and Facebook must be proved independently or any provider lacking a production owner must be truthfully disabled. Email OTP and Mobile OTP remain separate paths and cannot be inferred from this failure.

The founder authorized implementation of real-device defects after the complete Social/global acceptance. This exact ticket was selected for source implementation after that inventory. No second AAB, upload or install is authorized.

## Pre-selection robustness and reuse assessment

- Customer outcome: a Personal user completes MoolSocial identity with the provider they selected and returns to the exact requested Social action; cancellation and errors retain that provider identity.
- Duplicate/reuse inventory: the only production Social authentication owner is `FirebaseSocialAuthGateway` in `apps/mobile/lib/features/journey01/review_journey_services.dart`, wired by `apps/mobile/lib/main.dart`; `JourneySession` already retains the selected provider and requested return route. No native Google Sign-In adapter or duplicate production gateway exists.
- Implementation disposition: reuse the current session and gateway, add one thin native Google identity adapter, and add focused test-only acceptance. No screen, route, or backend owner is added.
- Necessity proof: official Firebase Flutter native-platform guidance requires the Google Sign-In SDK to obtain an ID token before `FirebaseAuth.signInWithCredential`. The current Android path instead calls the generic `signInWithProvider(GoogleAuthProvider())`, which escaped as the Play package-certificate-hash failure.
- Robustness coverage: Google and YouTube selections use the same basic MoolSocial Google identity contract without requesting YouTube scopes; provider identity survives loading/cancel/error/retry; unsupported providers fail truthfully; no identifier, token or credential is logged; authenticated completion continues through the existing exact return-route owner.
- Adjustments: a future release receives its Google server client identifier only through the existing founder-only transient build-input boundary; it is never committed, printed or inspected. Unsupported provider presentation is handled separately under its protected Screen 03 contract.
- Explicit exclusions: no YouTube channel OAuth, Meta/X provider activation, email/mobile OTP change, cloud/backend/Hosting/Play mutation, secret access, build, upload, install, communication or quota submission.
- Dependencies and approvals: founder source-implementation authority; exact existing Firebase Android app and Play signer registration; future separately authorized founder-only transient release input; current r60.45 remains installed and untouched.
- Timeline impact: one source day, within the locked 60–75 day delivery window.

## Source implementation result

The production gateway now uses the official native Google identity SDK to obtain an ID token and then signs into Firebase with `GoogleAuthProvider.credential`. Google and YouTube remain basic MoolSocial identity choices and request no YouTube API scopes. Native cancellation returns a cancelled result without calling Firebase. Configuration failures expose bounded customer copy and never forward SDK diagnostics, identifiers or token values.

Production runtime configuration exposes only Google and YouTube identity because no live owner has been proved for Apple, X, Instagram or Facebook. The locked Screen 03 reference presentation remains available to its visual/reference tests; the production allow-list suppresses unproved choices. The future server client identifier is a required transient release input and is absent from source.

Source-only verification after the final allow-list change:

- focused Social manifest: 59 files, 379 passed, 3 declared skips;
- focused authentication/configuration partition: 36 passed;
- backend: 505/505 passed;
- Firebase Hosting static contract: 7/7 passed;
- YouTube deployment controls passed locally with the exact no-cloud marker;
- Flutter analyzer clean;
- Android release dependency graph resolved with `BUILD SUCCESSFUL`;
- release registrant restored to 16 allowed native plugins, including `GoogleSignInPlugin`, with `IntegrationTestPlugin` absent.

No AAB/APK was built, no Play or provider state was changed, no OPPO mutation occurred and no communication or quota submission was made. This ticket is source-implemented and non-build-qualified only. Live success and production-grade acceptance remain pending a future separately founder-authorized Play candidate.
