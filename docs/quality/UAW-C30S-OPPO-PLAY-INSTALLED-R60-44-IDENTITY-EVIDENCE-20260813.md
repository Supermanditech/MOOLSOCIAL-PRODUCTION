# C30S OPPO Play-installed r60.44 identity evidence — 2026-08-13

## Device and update boundary

- Device serial: `2b3e0f71`.
- Model: OPPO CPH2375.
- Package: `com.moolsocial.app`.
- Update source: Google Play Store exact **Update** control on the MoolSocial internal-test page.
- Uninstall: not performed.
- Data clear: not performed.
- Downgrade: not performed.
- ADB install: not performed.

## Installed package identity

- Version code: `2026081244`.
- Version name: `1.0.0-r60.44`.
- Installer package: `com.android.vending`.
- First install time: `2026-08-12 22:49:56`.
- Last update time: `2026-08-13 02:01:52`.
- First install time remained the r60.43 value, proving an in-place update rather than uninstall/reinstall.

## Split and signing proof

Installed paths contained exactly:

- `base.apk`
- `split_config.arm64_v8a.apk`
- `split_config.en.apk`
- `split_config.xhdpi.apk`

The pulled read-only base evidence is `tmp/c30s-oppo-r60-44-base.apk`:

- Bytes: `17490773`.
- SHA-256: `1B0A98BC6C513AC1095CC5F9381E6B2933666255F31604982632C1314834E301`.
- `apksigner` certificate SHA-256: `47B28C7DDE2B61CAB6A7748C9019A3B57376B3BE1DC163D48253BBA35B63CDD9`.

That certificate equals the registered Google Play app-signing identity and differs from the private upload certificate, as required. The Play Console artifact version, installed version, Play installer and Play signing certificate form the qualified provenance relationship; the installed split APK checksum is not expected to equal the source AAB checksum.

This evidence does not yet claim a Flutter first frame, App Check acceptance or reviewer-journey pass.
