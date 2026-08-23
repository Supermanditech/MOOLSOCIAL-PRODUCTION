# C21H OPPO qualification preselection — 2026-08-08

C21H is MVP-required device acceptance work and is the final child in the locked C21 sequence. C21A–F are complete and C21G passed two consecutive unchanged-source host cycles on fingerprint `3E77391CD4BCC9A3DD6531CE5E26B56838152073C24FA6BC219D1970A1BA3B07`.

Reuse and duplicate search selected the existing single-build wrapper, APK regression machine gate and in-place ADB install/evidence workflow. No new screen, route, runtime owner, backend owner, persistent state or subaction is allowed. Runtime, build, install, backend and external writes remain closed during prebuild validation.

The connected device is OPPO CPH2375 serial `2b3e0f71`. The installed package is `com.moolsocial.app`, r60.19 / `2026080819`, first installed `2026-08-04 02:51:59`, last updated `2026-08-08 20:03:21`, with installed base SHA-256 `D97E4F8B28EAA7DDBF9C74DF7FE4BBBC1204CD118B2DEC07F85C75559A91F0F0`. That identity must remain untouched until one separate machine authorization passes.

Bounded collision search found no use of candidate `1.0.0-r60.20` / `2026080820` in the text-owner or artifact-filename inventory. Minimum scope is exactly one profile build from the qualified fingerprint, one `adb install -r` in-place install, local-versus-installed checksum identity, preserved first-install time, six-family/17-state screenshots and journeys, and founder acceptance pending review. No second build/install, uninstall, data clear, downgrade, credentials, messages/calls, funds, Production, commit, push, deploy or promotion is permitted.
