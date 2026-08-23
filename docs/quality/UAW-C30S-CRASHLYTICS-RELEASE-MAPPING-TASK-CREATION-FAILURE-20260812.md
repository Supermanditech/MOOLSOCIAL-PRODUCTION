# C30S Crashlytics release mapping task creation failure

Date: 2026-08-12

The first combined `processReleaseMainManifest` and Gradle task-registration
audit exited `1` while creating
`:app:uploadCrashlyticsMappingFileRelease`. APK and AAB sentinels were identical
before and after the command. No device, Play, Firebase or provider state
changed, and the C30S one-AAB authority remains unused.

The exact Gradle exception must be captured and corrected before source
qualification. Qualification remains fail-closed until release task
registration succeeds and the Crashlytics build-ID task is proved.

The captured exception was `Google-Services plugin not found` from
Crashlytics `AppIdFetcher`. Firebase's current Android Crashlytics guidance
requires Google Services Gradle plugin 4.4.1 or newer alongside Crashlytics
Gradle plugin 3. The correction applies Google Services 4.5.0, retains
Crashlytics 3.0.7 and disables mapping upload only because this release is not
obfuscated. Gradle task registration now exits zero and exposes both
`processReleaseGoogleServices` and
`injectCrashlyticsMappingFileIdRelease`. Qualification permanently requires
both tasks.
