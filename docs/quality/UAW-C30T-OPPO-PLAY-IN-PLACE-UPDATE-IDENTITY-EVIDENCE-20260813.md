# UAW C30T OPPO Google Play in-place update identity evidence — 13 August 2026

## Qualified outcome

The one founder-authorized MoolSocial C30T update completed in place on OPPO `2b3e0f71` through Google Play Internal Testing. The existing app installation and its retained data boundary were preserved.

## Installed identity

- Package: `com.moolsocial.app`
- Version code: `2026081345`
- Version name: `1.0.0-r60.45`
- Installer: `com.android.vending`
- First install time retained: `2026-08-12 22:49:56`
- Last update time: `2026-08-13 17:04:01`
- Play app-signing SHA-256: `47B28C7DDE2B61CAB6A7748C9019A3B57376B3BE1DC163D48253BBA35B63CDD9`

The signer was verified with Android build-tools 36.0.0 `apksigner verify --print-certs` against the pulled installed base APK. Only the normalized signer certificate digest was retained in command evidence.

## Installed artifact

- Installed base APK: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/oppo-installed-r60-45-base.apk`
- Installed base APK bytes: `17490773`
- Installed base APK SHA-256: `3AB2D9F6241FC917DD4E0CDCAEEE087BB331EB18D14E7A96D40A12639EFEFB9C`

## Release relationship

- Sealed uploaded AAB: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/MoolSocial-1.0.0-r60.45-2026081345-release.aab`
- Sealed AAB SHA-256: `96555FA225F3C135324C3A3DCFD0CDF78E5A9DA66D9F01A340FCD778257CBACA`
- Sealed AAB upload signer SHA-256: `63491BE78A01F4514319AE5D2A3957611833F32CA1CBFD57AB2982B01D39C0D6`
- Google Play Internal release: track `internal`, track ID `4700716609720808604`, release ID `3`
- Play-parsed release and installed package both identify `2026081345 / 1.0.0-r60.45`.

The AAB upload signer and installed APK signer differ exactly as expected under Google Play App Signing: the upload certificate authenticates the uploaded bundle, while Google Play signs the delivered APK with the founder-pinned Play app-signing certificate.

## Single-action and safety proof

- Candidate build count: `1 / 1`
- Candidate upload count: `1 / 1`
- Candidate install count: `1 / 1`
- Second build, upload or install: not performed
- Uninstall: not performed
- Data clear: not performed
- Downgrade: not performed
- Sideload or ADB install: not performed
- Production, open testing, closed testing or public listing rollout: not performed

ADB was used only for read-only package identity, installed-path and artifact evidence collection. It was never used to install the app.
