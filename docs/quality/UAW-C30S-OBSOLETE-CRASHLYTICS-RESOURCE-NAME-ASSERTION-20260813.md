# C30S obsolete Crashlytics resource-name assertion

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`

Bounded offline diagnosis proved the sealed AAB's complete resource inventory contains exactly the modern Crashlytics resources:

- `string/com.google.firebase.crashlytics.mapping_file_id`
- `string/com.google.firebase.crashlytics.version_control_info`

The verifier had queried `string/com_crashlytics_build_id`, a name inferred from the runtime error wording rather than the exact Gradle plugin output. The selector therefore exited successfully with zero output even though Crashlytics packaging was present.

The corrected gate must select `string/com.google.firebase.crashlytics.mapping_file_id`, require its name in output, and require the exact nonempty 32-hex value shape proven by the artifact. The AAB remains unchanged at SHA-256 `2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`; no second build is authorized or needed for this verifier correction.

Regression: `REG-20260813-1635-C30S-OBSOLETE-CRASHLYTICS-RESOURCE-NAME-ASSERTION`.
