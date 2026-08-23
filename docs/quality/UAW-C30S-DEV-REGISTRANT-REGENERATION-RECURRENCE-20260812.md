# C30S dev registrant regeneration recurrence

Date: 2026-08-12

After the failed cycle's analysis phase, static readiness found 16 Android
plugins because Flutter had regenerated the dev-only `IntegrationTestPlugin`.
The initial C30S qualifier had omitted the already-known C30Q post-test release
config-only restoration. No APK or AAB was built.

Every C30S cycle now runs `flutter build apk --release --config-only` with the
r60.44 identity after tests, proves pubspec, lock, APK and AAB sentinels are
unchanged, and requires exactly 15 release plugins with
`IntegrationTestPlugin` absent before gates and source sealing.
