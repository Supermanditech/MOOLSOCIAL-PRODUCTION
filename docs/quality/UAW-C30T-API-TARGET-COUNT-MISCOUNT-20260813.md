# C30T Firebase API target count miscount

## Observation

The authorized Android API key restriction update completed successfully. The result contains both the preserved prior certificate and the Google Play app-signing certificate for `com.moolsocial.app`. The post-write wrapper then failed because it asserted a manually entered count of 25 API targets; the preserved list actually contains 27.

## Impact

The external configuration write succeeded. No key value, OAuth credential, App Check token, or private attestation payload was read. The same write must not be repeated merely to correct the verification logic.

## Permanent prevention

- Capture and normalize the exact pre-write restriction set mechanically.
- Compare complete pre/post target identities rather than a manually counted number.
- If a write succeeds but a later assertion fails, register the mistake and use a read-only re-verification; do not repeat the external mutation.
