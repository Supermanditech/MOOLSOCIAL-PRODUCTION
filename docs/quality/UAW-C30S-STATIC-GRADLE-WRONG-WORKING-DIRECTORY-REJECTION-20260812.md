# C30S static Gradle wrong-working-directory rejection

Date: 2026-08-12

The static gate invoked `gradlew.bat` by absolute path while its process
working directory remained the repository root. Gradle task registration
therefore exited `1`. No artifact or external state changed.

The gate now enters `apps/mobile/android`, invokes the wrapper there and
restores its prior location in `finally`. It requires exit zero and the exact
Google Services and Crashlytics release task names.
