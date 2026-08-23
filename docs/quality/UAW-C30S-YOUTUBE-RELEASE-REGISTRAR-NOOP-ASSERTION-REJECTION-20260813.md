# C30S YouTube release registrar no-op assertion rejection

Date: 2026-08-13

The affected suite observed `registerViewFactory` where its release registrar
contract requires a no-op. The exact debug/profile/release registrar files and
Gradle source mapping are inspected before any correction. No artifact was
built.

Inspection proved the implementation is correct and the assertion was stale.
The founder-authorized Play reviewer journey requires official embedded
playback, so debug, profile and release register the same closed PlatformView
factory. The player build flag remains disabled by default and C30S explicitly
enables it. The test now preserves the Android-only boundary and every
forbidden JavaScript bridge check without incorrectly requiring a release
no-op.
