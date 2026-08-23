# FSC02D Dev YouTube public-data runtime qualification completion

- Ticket: `MOOLSOCIAL-FSC02D-DEV-YOUTUBE-PUBLIC-DATA-RUNTIME-QUALIFICATION`
- Project: `moolsocial-dev-503018` (`760290687711`), region `asia-south1`
- Android app: `1:760290687711:android:4202409fd3ab38f6ce076a`, package `com.moolsocial.app`
- Installed protected predecessor: OPPO `2b3e0f71`, `1.0.0-r60.28` (`2026081028`)

## Qualified live runtime

The accepted persistent Dev `PublicDataReview` deployment passed the complete no-secret post-deployment verifier. `youtubeProvider` and `youtubeOAuthCallback` are active with scale-to-zero, one maximum instance and one request concurrency. `publicData` is true; owner connection, owner actions, creator assets, live, private upload and owner analytics remain false. Invocation is Play Integrity App Check guarded. Runtime IAM, secret bindings, enabled secret-version metadata, API restrictions, Firebase Android identity and both registered signing fingerprints passed without reading or outputting any secret value. Billing is open and linked, and the project budget exists. No cloud mutation or redeploy was performed.

Public catalogue operations intentionally require genuine App Check and do not request a Firebase ID token. The review app initializes the exact Firebase Android app and presents the authenticated Personal review session, but this ticket does not misstate public YouTube Data API calls as owner-authenticated calls and enables no OAuth or owner capability.

The installed OPPO certificate SHA-256 `CBDFC5969AD51ED570AFB1CF2FE60377E559D43F59D59E2AB66CCAF78EA9AC25` and SHA-1 `1E4345AA0707C8A4C74F5485B47B14E911923B46` match Firebase registration. App Check uses Play Integrity, accepts the founder-authorized off-Play review boundary, requires `MEETS_DEVICE_INTEGRITY` and has zero debug tokens.

## Source and build boundary

The security verifier no longer fetches Secret Manager payloads or API-key strings. It proves exact resources, one enabled metadata version, runtime-only accessor IAM, App Check, signing identity and endpoint behavior. Firebase Extensions inventory uses the stable authenticated management REST API rather than a separate stale Firebase CLI session.

The existing one-build wrapper now owns an exact `YouTubePublicDevReview` profile. It retrieves the public-by-design Firebase Android SDK configuration from the official Firebase Management API in memory, verifies project/app/package identity, never logs the client value, passes it through a temporary Dart define file, deletes that file, and records only `present_not_logged`. No YouTube server API key, OAuth secret, token encryption key or provider secret enters the APK. The wrapper supplies the exact non-emulator Dev provider, Play Integrity proof and profile-enabled official embedded player.

## Verification

- Google Cloud/Firebase read-only preflight: passed.
- Full live `PublicDataReview` post-deployment verifier: passed; cloud mutations `none`.
- Backend Node `22.23.2`: typecheck, build and all `471/471` tests passed.
- Flutter focused analysis: no issues.
- Six Social files: `76/76` tests passed before build-control integration.
- Platform plus Social replay: `82/82` tests passed after build-control integration.
- YouTube public Dev build-control static and PowerShell parse gates: passed.
- Approved UI locks, MVP delivery lock, authorized MVP scope and permanent regression memory: passed.

## Device boundary and successor

No APK was built or installed. The protected r60.28 package and all C28D rejection evidence remain unchanged. The next sequential ticket is fresh host qualification `UAW-PERSONAL-MVP-SOCIAL-YOUTUBE-PUBLIC-DATA-HOST-QUALIFICATION-C29A`. It must pass twice against one stable source fingerprint before a separately registered checksum-unique OPPO candidate may receive one build authorization.
