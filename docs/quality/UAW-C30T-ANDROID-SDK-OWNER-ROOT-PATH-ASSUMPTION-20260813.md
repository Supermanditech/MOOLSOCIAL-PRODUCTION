# UAW C30T Android SDK owner root-path assumption — 13 August 2026

## Observation

After the keytool parser was retired, the first exact-apksigner dependency lookup assumed `android/local.properties` existed at the repository root. The file is not owned there, so the lookup stopped before executing apksigner.

## Root cause

A conventional Flutter root layout was assumed instead of resolving the exact nested MoolSocial Android owner from named repository files.

## Permanent prevention

- Resolve toolchain configuration only from the exact nested Flutter app owner named by repository scripts or bounded tracked-file discovery.
- Assert that owner exists before reading it.
- Select and assert one existing `apksigner` dependency before certificate verification.
- Do not repeat the repository-root `android/local.properties` assumption.

## Safety result

No app, device, Play release, build authority, upload authority, install authority, credential or customer data was changed or accessed.
