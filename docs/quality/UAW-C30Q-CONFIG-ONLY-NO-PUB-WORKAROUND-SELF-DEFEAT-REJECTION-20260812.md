# C30Q config-only no-pub workaround self-defeat rejection

C30Q cycle 1 ran `flutter build apk --release --no-pub --config-only` and the
generated registrant still contained `IntegrationTestPlugin`. This is the
expected pre-fix behavior documented by Flutter PR #185615: `--no-pub` is the
incorrect gate that suppresses platform-tooling regeneration in the installed
Flutter version.

The authoritative issue workaround runs config-only without `--no-pub`, then
runs the intended AAB build with `--no-pub`. The first C30Q cycle preserved its
format, analysis, tests, gates and rejected config log. It created no APK or
AAB and changed no build authority.

Prevention: use `flutter build apk --release --config-only`, seal that
`pubspec.yaml` and `pubspec.lock` hashes do not change, prove no APK changes,
prove the release registrant excludes `IntegrationTestPlugin`, and retain
`--no-pub` only for the subsequent single AAB invocation.
