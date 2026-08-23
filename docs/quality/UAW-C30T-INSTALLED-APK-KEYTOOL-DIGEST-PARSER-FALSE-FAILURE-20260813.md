# UAW C30T installed APK keytool digest parser false failure — 13 August 2026

## Scope

This evidence records a post-install signer-inspection false failure for the single founder-authorized C30T Google Play Internal Testing update on OPPO `2b3e0f71`.

## Observation

The first installed-base signer check used `keytool -printcert -jarfile` and required exactly one `SHA256:` certificate line. The Play-generated installed base APK did not expose that output through this JAR-oriented path, so the parser stopped with zero matching lines. No signer success, install success or artifact relationship was claimed from that command.

## Root cause

The command selected a JAR certificate inspection interface without proving that its output contract covered the APK v2/v3 signature used by the installed Play split APK.

## Permanent prevention

- Never retry the keytool JAR parser for installed Play APK signer evidence.
- Use the exact Android SDK `apksigner verify --print-certs` dependency.
- Capture only the signer certificate SHA-256 digest, normalize it, and compare it to the founder-pinned Play app-signing certificate.
- Keep the sealed AAB, installed base APK and all prior evidence immutable; this operational correction grants no second build, upload or install authority.

## Safety result

No app mutation, uninstall, data clear, downgrade, sideload, ADB install, second Play tap, credential read or external rollout occurred.
