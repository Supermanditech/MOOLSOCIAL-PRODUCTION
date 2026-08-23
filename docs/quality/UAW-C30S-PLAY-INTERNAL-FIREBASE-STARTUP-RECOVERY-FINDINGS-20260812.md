# C30S Play Internal Firebase startup recovery findings

Date: 2026-08-12

## Founder disclosure and authority

Customer outcome: one r60.44 Dev release corrects the confirmed Android
Firebase/Crashlytics release-packaging defect, is uploaded only to the existing
Google Play Internal Testing track and updates r60.43 in place on the OPPO
without uninstall or data clear.

Classification: `mvp_required`. The Play-installed reviewer app cannot render
its first frame, so this is a confirmed release blocker in the supported Social
journey and the time-bounded YouTube Android-link response.

Founder authorization received on 2026-08-12:

> Authorize C30S: implement the release Firebase/Crashlytics packaging fix,
> build exactly one r60.44 AAB, upload only to Google Play Internal Testing,
> and update the OPPO in place without uninstall or data clear.

## Robustness and reuse assessment

C30S reuses the current Flutter application, Firebase Dev app, Play
application, Play App Signing identity, tester track, provider revisions,
C30K corpus and bounded reviewer journey. It creates no screen, route, backend
owner or provider capability. The only new owners are the fail-closed C30S
machine state, release-configuration qualifier and single-build wrapper because
C30Q and C30R authorities are consumed and immutable.

Minimum scope: apply the Crashlytics Gradle plugin, provide the exact
non-secret Dev `google_app_id` Android resource without persisting or exposing
the API key, prove source/static gates twice, build exactly one r60.44 AAB,
prove its release resources/signing/checksum/provenance, upload only to Internal
Testing and update the OPPO in place through Google Play.

Excluded: UI/product/backend/provider changes, YouTube scope expansion,
Production/open/public rollout, Staging/Production backend, email/quota action,
uninstall/data clear/downgrade/sideload, secret/private-verdict/nonce access,
second build/upload/install, commit/push/merge/main and external messages,
calls or funds.

Dependencies: founder-only hidden signing/API-key inputs if requested by the
launcher; r60.43 remains Play-installed; Play signing and Firebase App Check
configuration remain unchanged; provider revisions remain
`moolsocialcontent-00003-juw`, `youtubeprovider-00036-qer` and
`youtubeoauthcallback-00035-cir`.

Test plan: static Android release contract; two identical source cycles; one
AAB with bundle resource, version, package, signer, checksum and provenance
proof; Internal-only release readback; in-place Play update; first frame/C28D;
bounded secret-safe error log; App Check; reviewer journeys; exactly six Dev
Create writes/readbacks; unsent reviewer package.

## Founder-added comprehensive release discipline

Before the single AAB authority is consumed, C30S must audit startup and
lifecycle behavior for every registered native/Firebase plugin; Android
resources, components and permissions; release dependencies, generated
registrants, R8 and split/ABI behavior; signing, version and package identity;
secret and environment handling; provider URLs; retained-data update behavior;
offline, retry and process recovery; and the full affected Flutter regression
set. Two identical qualification cycles are required.

The one built AAB must then pass artifact-level resource, signing, package,
version, split and provenance inspection before upload. If it fails, it is
preserved and not uploaded; its one-build authority remains consumed and a new
exact founder-authorized successor is required.

Timeline impact: one day, within the locked 60–75-day plan. No duplicate
production owner is introduced.

## Audit corrections and fail-closed result

The dependency and generated-plugin audit removed unused direct Analytics,
Messaging, Performance, Remote Config, Firebase UI Auth, desktop webview auth
and app-links owners. The release registrant is now exactly 15 classified
plugins: App Check, Auth, Core, Crashlytics, lifecycle, image picker, JNI,
JNI Flutter, scanner, permission handler, shared preferences, speech, URL
launcher, video player and the private embedded YouTube player.

Crashlytics Gradle plugin `3.0.7` requires Google Services Gradle plugin
`4.4.1` or newer. Manual `resValue` identities alone failed release task
creation with `Google-Services plugin not found`. C30S now uses the official
Google Services `4.5.0` and Crashlytics `3.0.7` pair. The founder launcher
creates the exact Dev Google Services configuration transiently from the
hidden Android client API key, and erases it after exit. The agent never reads
or prints that key. Mapping upload is disabled only because this release is
not obfuscated; the Crashlytics mapping-file-ID/build-ID resource remains
required and is proved in the compiled AAB before upload.

The source and merged C30Q outputs were reconciled against the Play-installed
device. Flutter `3.44.6` resolves the current source minimum to Android API 24;
the earlier Play-installed `dumpsys` token `minSdk=32` is the device-targeted
base APK constraint generated from the bundle for this Android 13 device, not
the source AAB manifest minimum. The current Flutter release baseline is
therefore preserved without a toolchain upgrade. The existing Play delivery is a normal
split install with base, arm64, English and xhdpi splits. C30S requires the AAB
base manifest/resources plus arm64 `libapp.so` and `libflutter.so` before
upload.

Qualification refuses a pre-existing `google-services.json` or transient Dart
define, credential-shaped source/log output, unused Firebase runtime artifacts,
unexpected plugin registration, source cleartext, expanded exported-component
surface, debug signing, obfuscation/mapping mismatch, predecessor removal,
provider drift, APK/AAB mutation or any source fingerprint drift. Two complete
identical cycles are mandatory before the founder prompt.

The repository-wide diagnostic suite is not the acceptance suite: it truthfully
exposed 323 pre-existing failures in frozen unrelated product/golden owners.
C30S therefore seals a deterministic affected-test manifest containing every
C30Q-owned test plus every Social, YouTube, Firebase/App Check/Auth, startup,
platform, session, retained-state, retry and Android-adapter test. The exact
manifest hash must pass twice; no failing frozen owner is deleted, rewritten or
misreported.
# 2026-08-13 Play-installed runtime outcome

C30S r60.44 was published only to Google Play Internal Testing and updated the OPPO in place. The Play-installed package reached two byte-identical no-tap Flutter frames, resolving the r60.43 Crashlytics preframe failure. Live reviewer reads then rejected: YouTube Home/Videos/Shorts did not load and MoolSocial Public Feed did not show the preserved C30K corpus. Exactly zero Create writes were attempted. C30T was registered for later authorized recovery; YouTube email/quota submission remains blocked.
