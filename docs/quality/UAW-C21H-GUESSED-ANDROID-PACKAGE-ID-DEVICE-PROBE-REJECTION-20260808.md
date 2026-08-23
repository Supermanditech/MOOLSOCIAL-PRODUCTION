# C21H guessed Android package ID device-probe rejection — 2026-08-08

The first C21H read-only OPPO reconciliation guessed `com.supermandi.moolsocial`. `adb shell pm path` returned no package path, so the probe did not inspect the installed MoolSocial APK. REG-20260808-492 requires the exact Gradle `applicationId` or accepted machine evidence before any retry.

No build, install, uninstall, data clear, downgrade or other device mutation occurred.
