# C21H orphaned pixel-test process prebuild rejection — 2026-08-08

C21H preflight found `dart.exe` PID 9536 still running `flutter_tools.snapshot test test/core/design/mool_optical_delta_device_pixel_proxy_c21g_test.dart`. It was the child of the earlier terminated fake-async hang. The separate Java process was an idle Gradle daemon, not an active build.

The active-test gate rejects build authorization until the exact verified orphan is stopped and re-enumeration reports zero Flutter build/test commands. REG-20260808-499 requires post-termination child-process cleanup. No APK or device mutation occurred.
