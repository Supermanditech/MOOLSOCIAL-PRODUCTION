# UAW C33E live-auth, release and OPPO read-only checkpoint

Date: 2026-08-15
Active source ticket: `UAW-C33E-FIX4-PROTECTED-SOCIAL-ACTION-INTENT-RETURN-CONTINUITY`
Live-readiness gate: `UAW-C33E-FIX2-GOOGLE-AUTH-LIVE-PROVIDER-READINESS-HARD-GATE`

## Repository and release identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Project/package/track: `moolsocial-dev-503018` / `com.moolsocial.app` / Google Play Internal Testing only
- Failed installed candidate: `1.0.0-r60.48` / `2026081348`
- Failed candidate build/upload/install counts remain `1/1/1`; its four C30X authorities remain consumed.
- The existing release AAB is the historical r60.48 artifact: 94,589,100 bytes, last-written `2026-08-14T21:17:01.9312733Z`. No new AAB was produced by this checkpoint.

## Hard-gate result

The C33E FIX2 implementation gate passed under PowerShell 7 and Windows PowerShell 5.1. A direct build-phase evaluation rejected with the exact expected reason before authority consumption: all four sanitized live-readiness facts must qualify before a build.

Current readiness remains `0/4`:

1. Firebase Android app includes the Google Play app-signing certificate relationship — pending.
2. Firebase Authentication Google provider is enabled for the exact Dev project — pending.
3. Android OAuth relationship matches `com.moolsocial.app` and the Play app signer — pending.
4. The mobile runtime server-side Google relationship uses the qualified Web application relationship for the exact Dev project — pending.

Readiness-state SHA-256: `5C7B0CAFF119AC0BDF4B18666FBE0DF8D11F1B6197F8AA66650C92ABA523C1D0`.

## Sanitized console check

A read-only check reached the exact Firebase project's Authentication > Sign-in providers page and found one `Google` provider row. The page did not expose an authoritative enabled/disabled signal without entering configuration details that may expose a prohibited OAuth client-ID value. The check stopped there, the browser tab was finalized, and the fact remains pending. No password, API-key value, OAuth client-ID value, token, nonce, App Check token, private verdict, private key, attestation payload, browser cookie, local storage, password store, or session store was read or recorded.

## OPPO read-only identity

- Serial/model: `2b3e0f71` / `CPH2375`
- ADB authorization state: connected device
- Package: `com.moolsocial.app`
- Installer: `com.android.vending`
- Installed version: `1.0.0-r60.48` / `2026081348`
- Last update time reported by the package manager: `2026-08-15 03:31:46`

No app launch, tap, log read, install, update, uninstall, downgrade, data clear, sideload, backend/provider deployment, email send, or YouTube quota submission occurred. The device check does not qualify runtime success.

## Release decision

Founder release/device approval is acknowledged, but approval does not establish the four external configuration facts. The release chain remains fail-closed and no successor candidate authority may be consumed until four sanitized, non-secret evidence records qualify. The historical r60.48 AAB must not be reused or represented as containing the FIX3/FIX4 source repairs.
