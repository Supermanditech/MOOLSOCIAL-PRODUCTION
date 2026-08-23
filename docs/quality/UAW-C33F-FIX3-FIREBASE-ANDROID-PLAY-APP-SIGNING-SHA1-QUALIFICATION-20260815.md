# UAW-C33F FIX3 Firebase Android Play app-signing SHA-1 qualification

Ticket: `UAW-C33F-FIX3-FIREBASE-ANDROID-PLAY-APP-SIGNING-SHA1-REGISTRATION`

The existing Firebase Android app now contains a SHA-1 that matches the Google Play App signing key. The authoritative post-reauthentication Firebase CLI inventory exited zero and was compared in memory only. It reported two SHA-1 and two SHA-256 records; the Play signer match is true.

All prior Firebase fingerprints were preserved. Exactly one provider relationship was added through the authorized Firebase Console flow. The console returned a misleading generic error, so the later authoritative backend inventory—not the stale page DOM—owns the result. No CLI mutation was performed.

No certificate value, password, API key, OAuth client identifier, token, nonce, App Check material, private key, account identifier, or attestation payload is present in the retained evidence. C33F live readiness advances from 1/4 to 2/4. AAB, Play, and OPPO actions remain held until the Android OAuth package/Play-signer and Web server-client/mobile relationships also qualify.
