# C22H OPPO qualification preselection — 2026-08-09

C22H is MVP-required device acceptance work and the final child in the locked
C22 sequence. C22A–F1 are complete and C22G passed two consecutive unchanged-
source cycles on fingerprint
`2368E36B47A631096FE0B24CDD87A67EC2F7C2390773B95F463FED0C4828D77D`.

Reuse and duplicate search select the existing single-build wrapper, APK
machine gate, in-place ADB install workflow and OPPO evidence workflow. No new
screen, route, runtime owner, backend owner, persistent state or subaction is
allowed. Runtime, build, install, backend and external writes remain closed
during prebuild validation.

The connected device is OPPO CPH2375 serial `2b3e0f71`. The installed package
is `com.moolsocial.app`, r60.20 / `2026080820`, first installed
`2026-08-04 02:51:59`, last updated `2026-08-08 22:31:36`, with live base
SHA-256 `FF3932D84794BA8802946CBB04F8A346F34386F4A5C8321F3970AD8E6228EF8A`.
It has 100% battery and 84,366,864 KiB free under `/data`. This exact identity
must remain untouched until one separate build authorization and later one
separate install authorization pass.

The unique reserved candidate is
`UAW-PERSONAL-MVP-CAPSULE-SYSTEM-OPPO-QUALIFICATION-FIX5-C22H`, version
`1.0.0-r60.21` / `2026080921`, profile mode. Bounded text and artifact-name
collision search found no use of that identity. The source inventory is 3,291
files on the C22G fingerprint; zero active Gradle/Flutter build or test clients
were found. One idle Gradle daemon is reported separately and left untouched.

Minimum scope is exactly one profile build, postbuild package/version/signer/
source validation, one `adb install -r` in-place install, local-versus-installed
checksum identity, preserved first-install time, the six-family/17-state
screenshot and journey matrix, and founder acceptance pending review. No
second build/install, uninstall, data clear, downgrade, credentials,
messages/calls, funds, Production, commit, push, deploy or promotion is
permitted.
