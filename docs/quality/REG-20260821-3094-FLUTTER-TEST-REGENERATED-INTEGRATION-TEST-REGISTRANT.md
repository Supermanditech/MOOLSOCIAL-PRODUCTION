# REG3094 — Flutter test regenerated the integration-test registrant

- Date: 2026-08-21
- Status: registered before variant-aware repair

The comprehensive source control test failed after focused Flutter tests.
Flutter tooling regenerated the ignored `GeneratedPluginRegistrant.java` and
reintroduced `IntegrationTestPlugin`, proving that manually editing and
unignoring a generated owner is not durable. Firebase Core remained present.
No build or device action followed.

Prevention: keep the generated registrant ignored, add a release-variant Gradle
sanitization task that removes only the integration-test registration before
release Java compilation, require Firebase Core to remain, and verify the final
APK dex contains the production registrant/Firebase Core but not integration
test.
