# REG-20260821-3053 secure build session wrong upload-keystore environment name

## Observed failure

The secure signing setup stored the keystore path in
`MOOLSOCIAL_UPLOAD_KEYSTORE_PATH`. Android Gradle and all 43 current release
owners require `MOOLSOCIAL_UPLOAD_STORE_FILE`. No build had started, so the
mismatch was caught before signing validation.

## Root cause

The founder guidance reused a stale remembered environment name instead of
reading the current `build.gradle.kts` signing contract first.

## Impact

- the new upload key and its passwords remain valid and founder-controlled;
- no secret or path value was emitted;
- no build, Play, OPPO, provider or device action occurred;
- an AAB would have failed the release-signing precondition if uncorrected.

## Prevention and authorized continuation

Treat `MOOLSOCIAL_UPLOAD_STORE_FILE` as the sole canonical path variable. Before
any build instruction, mechanically compare every required signing variable
against current Gradle and wrapper owners. In the existing secure process, copy
the already-held path value to the canonical variable without displaying it.
