# FSC02C Android profile YouTube player packaging preselection

- Ticket: `MOOLSOCIAL-FSC02C-ANDROID-PROFILE-YOUTUBE-PLAYER-PACKAGING`
- Classification: `mvp_supporting`
- Actor: an authenticated Personal user on an authorized Android profile review candidate.
- Customer outcome: the existing official YouTube embedded player is available in an authorized Android profile review build while release remains disabled and every closed origin, message, lifecycle, eligibility and recovery boundary remains enforced.
- Delivery impact: one shared packaging/configuration slice, estimated at one day and inside the robust-MVP delivery lock.

## Reuse and duplicate assessment

The existing player is complete enough for source-only profile packaging. It already owns:

- the provider-only bootstrap and pinned digest;
- exact `https://com.moolsocial.app` origin/base URL;
- one transferred `WebMessagePort` with a random nonce;
- a closed typed command/event envelope and bounded messages;
- no JavaScript interface, `evaluateJavascript`, wildcard message listener or customer form/navigation;
- one-player lease, eligibility, pause/lifecycle, failure, retry and external handoff behavior;
- debug native PlatformView implementation and factory;
- existing profile and release registrar variants.

The exact implementation source can be reused in profile by adding its existing directory to the profile source set. Copying the large Kotlin owner into profile would create prohibited duplicate code. Moving or deleting the clean debug files is unnecessary. No new player, bridge, screen, route, backend or service owner is justified.

## Smallest complete source scope

1. Change the Dart build contract from debug-only to debug-or-profile, always false in release.
2. Permit the Android surface in debug or profile, never release, web or non-Android.
3. Add the exact current native implementation directory to the profile Gradle source set.
4. Change the existing profile registrar from no-op to the same factory registration used by debug; keep release no-op.
5. Make WebView remote debugging depend on the Android library's debug build variant so it is false in profile.
6. Update the Android source gate and focused tests to prove these boundaries and preserve all existing security assertions.

## Explicit holds

This ticket does not enable the player in release, change iOS, add an API/provider URL, access credentials, submit to Firebase/YouTube, enable upload/OAuth, change Social UI, or authorize an APK. The existing FSC02A provider-runtime admission remains required before an available-state candidate. A fresh APK machine/host qualification is still mandatory before any build and checksum-unique OPPO install.

The pre-mutation Android source gate passed with bootstrap SHA-256 `F63983016541BF07FD5390EACB34B8CCA7B6A564957DCD647A643689B27D0FBB`. The Android port and complete runtime suites passed all 33 tests.

## Implementation result

FSC02C is source and packaging-gate complete. The Dart feature contract and Android surface now allow explicitly enabled debug or profile review builds and remain unavailable in release. The isolated Android library explicitly creates a release-derived profile build type, reuses the exact existing native implementation directory, and registers the existing factory through the profile registrar. Release retains its no-op registrar.

WebView remote debugging is now controlled by the isolated library's generated `BuildConfig.DEBUG`. BuildConfig generation is explicitly enabled; it is false in the release-derived profile variant. No second Kotlin player implementation was copied or created.

Verification passed:

- closed Android source gate with unchanged bootstrap SHA-256 `F63983016541BF07FD5390EACB34B8CCA7B6A564957DCD647A643689B27D0FBB`;
- full Gradle project configuration;
- exact `:youtube_embedded_player_private_dev:compileProfileKotlin`;
- exact `:youtube_embedded_player_private_dev:compileReleaseKotlin` with release registration still closed;
- focused Flutter analysis with no issues;
- 34 Android port and complete player/bridge/lifecycle tests;
- all 76 focused Social provider, navigation, fitment and copy tests.

The initial Gradle attempts that exposed the missing profile build type and disabled library BuildConfig generation are permanently registered; their generated problem report remains preserved. No assemble or APK task ran, no candidate was registered and the OPPO application was not changed.

The packaging blocker is resolved. A truthful available-state OPPO candidate is still held by the FSC02A provider-runtime authority: a founder-authorized valid `MOOLSOCIAL_YOUTUBE_PROVIDER_URL` for `moolsocial-dev-503018`, non-emulator private-Dev proof, Firebase Auth, Play Integrity App Check and provider `capabilities.publicData=true`. After that exact environment is lawfully supplied, a fresh APK machine and host qualification must pass before any build or install.
