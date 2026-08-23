# FSC02E Dev Firebase Android client-key restriction completion — 11 August 2026

## Outcome

`MOOLSOCIAL-FSC02E-DEV-FIREBASE-ANDROID-CLIENT-KEY-RESTRICTION` is complete. The existing Firebase-managed Android client key in `moolsocial-dev-503018` is now application-restricted to exactly:

- package `com.moolsocial.app`;
- signing SHA-1 `1E4345AA0707C8A4C74F5485B47B14E911923B46`.

The complete 27-entry Firebase API-target collection was preserved with the same semantic SHA-256 `B5DD4EAA37BB473AA4A56B1A01E06569AC350ECFAECB05BC481DC3DE67F8772D` before and after the write.

## Write and verification boundary

One `restrictions`-only API Keys v2 patch ran against existing key UID `14fee65f-18c4-48b7-a7dd-aa5ce35d4353` under isolated gcloud configuration `moolsocial-dev-fsc02d`, account `hello@moolsocial.com`, project `moolsocial-dev-503018`. The long-running operation completed and the command verified the changed etag, unchanged API targets and exact Android application before its final safe-summary line encountered the registered PowerShell boolean-literal reporting error.

The mutation was not retried. A separate read-only metadata GET independently proved the final exact restriction and unchanged API-target digest.

No `getKeyString` request was made. No key string, credential, access-token value, OAuth secret, App Check debug token or other secret was read, copied, hashed, printed or persisted. No Function, Auth, App Check, IAM, billing, Hosting, Production or Staging setting changed.

## Protected state

No APK build or install ran. The connected OPPO remains on protected `1.0.0-r60.28` (`2026081028`), and all C28D evidence remains preserved. Cloud-write authority ends with this ticket and does not transfer to C29B.

## Durable evidence

- Prewrite metadata: `artifacts/quality/moolsocial-fsc02e-dev-firebase-android-client-key-restriction-20260811-01/prewrite-metadata.json`
- Postwrite metadata: `artifacts/quality/moolsocial-fsc02e-dev-firebase-android-client-key-restriction-20260811-01/postwrite-metadata.json`
- Permanent reporting regression: `REG-20260811-1103-FSC02E-POWERSHELL-BOOLEAN-LITERAL-REPORTING-ERROR`

C29B may resume only after its own delivery, scope, build-control and prebuild machine gates pass with `externalServiceWriteAuthorized` false.
