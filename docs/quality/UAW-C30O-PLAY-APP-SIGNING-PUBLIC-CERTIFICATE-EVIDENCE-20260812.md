# C30O Play App Signing public certificate evidence

- Date: 2026-08-12
- Play developer account: Supermandi Tech Private Limited
- Corrected Play app ID: `4974778280277295872`
- Package: `com.moolsocial.app`
- Inspection surface: signed-in Play Console `App signing | MoolSocial`

## Read-only findings

- Google Play manages and protects the app signing key.
- The current app signing key is `In use` and Play reports `Releases signed by Play`.
- The current public classical app-signing SHA-256 certificate fingerprint, exposed in the page's generated Digital Asset Links JSON for `com.moolsocial.app`, is:

  `47:B2:8C:7D:DE:2B:61:CA:B6:A7:74:8C:90:19:A3:B5:73:76:B3:BE:1D:C1:63:D4:82:53:BB:A3:5B:63:CD:D9`

- A previous app-signing key row exists with first-use time `12 Aug 2026, 12:15` and install base `0%`. No private key material or certificate file was downloaded.
- The Upload key certificate section states that certificate fingerprints will be shown after the first app bundle is uploaded. Therefore the upload certificate remains separately founder/local-qualified and must be matched after the one authorized upload.
- The Protected with Play overview reports `Play Integrity API is not integrated` and `0 of 7 services active`.

## Bounded conclusion

The public current Play app-signing identity is qualified for exact Firebase Android-app registration. Firebase App Check registration and Play project linkage have not yet occurred and remain false in machine state.

No signing key change, certificate download, Play Integrity configuration write, release upload, rollout, or Production action occurred.
