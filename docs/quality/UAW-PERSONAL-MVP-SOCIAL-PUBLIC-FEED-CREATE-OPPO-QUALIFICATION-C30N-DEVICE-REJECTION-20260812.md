# C30N r60.40 OPPO device rejection

Date: 2026-08-12
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PUBLIC-FEED-CREATE-OPPO-QUALIFICATION-C30N`
Device: OPPO CPH2375, serial `2b3e0f71`
Installed identity: `1.0.0-r60.40` (`2026081240`)

## Outcome

C30N is device-rejected at the signed-in real Dev Feed read gate. The six
authorized Create writes were not attempted because a successful authoritative
Feed read is the required precondition for truthful write/readback testing.

The installed APK remains preserved. No second build, second install,
uninstall, data clear, downgrade, Production write or YouTube quota submission
occurred.

## Passed evidence

- One profile APK build and one in-place install were consumed.
- The candidate APK and installed `base.apk` match SHA-256
  `50A5CBA08A68895B3BCCCB235E5BD7209CBDDC45673BA5FC607F365C611F5121`.
- Package/signature/version qualification passed.
- C28D passed from two matching no-tap first-native semantic frames: six
  enabled exported navigation nodes, minimum logical width 54 and minimum
  logical height 44.
- YouTube Home settled to real provider-owned catalogue content without an
  unavailable or loading overlay.

## Rejected Feed evidence

The first Feed attempt and one bounded `Try again` attempt both rendered:

- `We couldn’t refresh your Feed`
- `Your Feed stays clear until real MoolSocial posts are available.`

The before and after UI hierarchies are byte-identical and share SHA-256
`2381035ABFC1523E2A99ACA2C2AFB0FB29338E9F4995EAE4F9601A48F45AFA4E`.
The exact Cloud Run request-log window from `2026-08-12T10:10:00Z` through
`10:12:00Z` contains zero `moolSocialContent` request rows. This places the
failure before server transport.

Evidence:

- `artifacts/quality/uaw-personal-mvp-social-public-feed-create-oppo-qualification-c30n-r60-40-20260812-01/11-feed-retry-before.xml`
- `artifacts/quality/uaw-personal-mvp-social-public-feed-create-oppo-qualification-c30n-r60-40-20260812-01/11-feed-retry-before.png`
- `artifacts/quality/uaw-personal-mvp-social-public-feed-create-oppo-qualification-c30n-r60-40-20260812-01/12-feed-retry-after.xml`
- `artifacts/quality/uaw-personal-mvp-social-public-feed-create-oppo-qualification-c30n-r60-40-20260812-01/12-feed-retry-after.png`
- `artifacts/quality/uaw-personal-mvp-social-public-feed-create-oppo-qualification-c30n-r60-40-20260812-01/13-feed-retry-cloud-request-audit.json`

## Cause boundary

The exact client build contains the Dev content endpoint, Firebase Auth is
signed in, the registered Android package/signing identity matches, Play
Integrity token work completed on-device, and no function request arrived.
The installed package reports installer `pc`, so it is an ADB-sideloaded
profile candidate on Android 13.

The evidence-compatible cause is the App Check/Play Integrity distribution
gate, but the private verdict and advanced Firebase setting were not read and
the conclusion is therefore explicitly an inference, not a claimed decoded
verdict. Firebase documents that App Check requires `PLAY_RECOGNIZED` by
default and that Android 13+ apps installed outside Google Play can be denied;
Google documents that a sideloaded app can be unlicensed or an unrecognized
version.

Official references:

- https://firebase.google.com/docs/app-check/android/play-integrity-provider
- https://firebase.google.com/docs/reference/appcheck/rest/v1/projects.apps.playIntegrityConfig
- https://developer.android.com/google/play/integrity/verdicts

## Required successor gate

Before another APK/AAB build or install, a separately authorized successor
must qualify its distribution path against the exact Dev App Check policy.
The production-grade route is a Google Play-recognized internal-test build and
install, followed by a successful signed-in Feed read before any Create write.
Changing the Dev App Check acceptance policy or using an App Check debug
provider would be a separate security/configuration decision and is not
authorized by C30N.

The existing r60.40 install and every C30N/C30M/C30L/C28D artifact remain
immutable until that successor is explicitly selected and authorized.
