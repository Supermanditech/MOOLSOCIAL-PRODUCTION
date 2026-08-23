# C21 mobile workdir duplicated test path rejection — 2026-08-08

The first C21B format/test command set its working directory to `apps/mobile` but still passed `apps/mobile/...` paths. Dart reported the duplicated path as missing and the short command timeout expired before any Flutter test ran. No source, test, device or APK state was changed by the rejected command.

Commands run from `apps/mobile` must use `lib/...` and `test/...` paths. Repository-relative `apps/mobile/...` paths are used only from the repository root.
