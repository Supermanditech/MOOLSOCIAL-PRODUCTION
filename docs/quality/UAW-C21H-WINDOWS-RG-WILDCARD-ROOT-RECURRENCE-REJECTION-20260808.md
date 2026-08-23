# C21H Windows ripgrep wildcard-root recurrence — 2026-08-08

The C21H application-ID lookup passed `apps/mobile/android/app/build.gradle*` as a ripgrep root on Windows and produced error 123, repeating REG-484. A separate valid literal-directory root did return `com.moolsocial.app`, but the mixed diagnostic is rejected because later success masked the invalid root.

REG-20260808-494 requires literal roots plus `--glob` and separate exit-code assertions. No device mutation occurred.
