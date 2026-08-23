# C30Q Flutter no-pub release registrant official findings — 2026-08-12

## Exact match

Flutter issue `flutter/flutter#169336` documents the same failure as C30P:
an Android release build with `integration_test` in `dev_dependencies` and
`--no-pub` retains a stale debug `GeneratedPluginRegistrant.java`, while
release Gradle excludes that dev dependency. `javac` then reports that
`dev.flutter.plugins.integration_test` does not exist.

Official issue: https://github.com/flutter/flutter/issues/169336

Flutter pull request `flutter/flutter#185615` remains open and describes the
root cause: platform-specific tooling regeneration is incorrectly gated by
`shouldRunPub`, so a `--no-pub` release build can keep the debug registrant.
Its manual reproduction confirms that release config-only regeneration removes
`IntegrationTestPlugin` from the registrant.

Official fix PR: https://github.com/flutter/flutter/pull/185615

## Smallest current-version correction

Until the upstream fix is merged and adopted, the official issue workaround is
to regenerate release configuration with:

`flutter build apk --release --no-pub --config-only`

and then run the intended release bundle build. The config-only command does
not build an APK; it refreshes platform tooling for release mode. C30Q must
verify afterward that the ignored generated registrant exists and contains no
`IntegrationTestPlugin`, then invoke exactly one `flutter build appbundle`.

## Rejected alternatives

- Do not remove `integration_test`: MoolSocial has a real integration-test
  suite and driver owner.
- Do not add `integration_test` to the production release classpath.
- Do not hand-edit or retain the ignored generated registrant as source.
- Do not upgrade Flutter or broad plugin dependencies under this ticket.
- Do not remove `--no-pub` and allow an unsealed dependency resolution during
  the one candidate build.
