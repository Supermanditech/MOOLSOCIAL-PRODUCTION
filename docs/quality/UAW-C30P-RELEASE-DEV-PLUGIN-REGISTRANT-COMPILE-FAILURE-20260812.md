# C30P release dev-plugin registrant compile failure — 2026-08-12

## Rejected attempt

The single C30P release AAB build ran under qualified PowerShell 7 and correctly
captured native stdout/stderr. Gradle failed `:app:compileReleaseJavaWithJavac`
because the generated Android `GeneratedPluginRegistrant.java` referenced
`dev.flutter.plugins.integration_test.IntegrationTestPlugin`, while Flutter's
release Gradle configuration intentionally omits plugins marked
`dev_dependency=true` from the release classpath.

This is an application dependency/registrant release-configuration defect, not
a recurrence of the C30O native-stderr host error.

## Preserved result

- C30P is `single_release_AAB_failed_authority_consumed`.
- Exactly one C30P wrapper invocation and attempted build are recorded.
- The durable build log contains the exact `javac` failure.
- No generated or sealed AAB and no provenance file exist.
- No upload, Play install, device mutation or Dev Create write occurred.
- The transient Firebase define file was erased after the process exited.
- No password, API key, private key, token, nonce or private verdict was read,
  printed, copied or retained by Codex.

## Mandatory prevention

C30P is permanently closed and must not be rerun. A successor may correct only
the exact unused dev-plugin ownership or generation boundary proven by a
repository usage audit. It must not add `integration_test` to the production
release classpath, edit the ignored generated registrant by hand, broaden
dependency upgrades or reuse C30P authority. The successor needs a new exact
candidate, two unchanged complete qualification cycles and one new build gate.
