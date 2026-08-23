# C30S sealed AAB Crashlytics build-ID proof rejection

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`

The build-forbidden offline recovery verifier proved the sealed r60.44 AAB's exact SHA-256 and byte count, founder upload signer, package, versionCode, versionName and `google_app_id`. It then rejected because the exact `com_crashlytics_build_id` bundle resource proof did not pass.

No build, upload or install occurred during recovery. The artifact remains SHA-256 `2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`, build count `1`, upload count `0`, install count `0`.

The upload block is intentional. Bounded diagnosis must distinguish a missing/invalid artifact resource from a verifier selector or value-shape error without exposing credentials. A missing resource rejects the single AAB and requires separate founder authority for any successor. A verifier defect may be corrected and rerun only against the identical sealed artifact, with no second build.

## Resolution

Exact AAB resource inventory proved this was a verifier selector defect: Crashlytics Gradle plugin 3.0.7 generated `string/com.google.firebase.crashlytics.mapping_file_id` and `string/com.google.firebase.crashlytics.version_control_info`. The obsolete queried name returned no output. Offline recovery remains upload-blocking until the corrected exact resource/UUID proof passes against the unchanged sealed AAB.

Regression: `REG-20260813-1634-C30S-SEALED-AAB-CRASHLYTICS-BUILD-ID-PROOF-REJECTION`.
