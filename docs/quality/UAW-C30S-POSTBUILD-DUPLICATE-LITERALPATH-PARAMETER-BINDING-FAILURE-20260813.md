# C30S post-build duplicate LiteralPath parameter-binding failure

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`

The single authorized release build passed configuration-only, fresh merged-manifest, Firebase/Crashlytics task, permission and exported-component preflights. Authority was then consumed exactly once and the r60.44 AAB was sealed at 93,201,374 bytes with SHA-256 `2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`.

Post-build verification then aborted before provenance/state finalization because a PowerShell command bound `LiteralPath` more than once. The founder launcher erased both transient input files and process values. No upload or install occurred.

This artifact is unqualified and upload-blocked until a corrected build-forbidden recovery verifier proves the existing sealed AAB only. It must never invoke Flutter, Gradle, appbundle, APK generation or a second signing operation. It must prove upload signer, package/version, Google app ID, Crashlytics build ID, base resources/manifest/arm64 payload, merged manifest and merger-blame evidence, credential-free logs and binding to the original accepted source manifest. The upload gate remains closed until that proof passes.

Regression: `REG-20260813-1632-C30S-POSTBUILD-DUPLICATE-LITERALPATH-PARAMETER-BINDING-FAILURE`.
