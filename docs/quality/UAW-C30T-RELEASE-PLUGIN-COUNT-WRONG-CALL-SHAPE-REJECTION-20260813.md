# UAW C30T release plugin-count wrong-call-shape rejection — 2026-08-13

## Outcome

Release config-only generation completed, but the verification regex counted
`.registerWith(` calls as if each plugin registered through that shape. The
current generated Java registrant has one `registerWith` method and registers
each plugin with `flutterEngine.getPlugins().add(new ...)`.

The zero-plugin result is a verifier error and is rejected. Direct inspection
shows the release registrant contains the expected production plugin form and
no IntegrationTestPlugin.

## Permanent prevention

Count the exact generated Java plugin-add statements, not the enclosing method
declaration. Verify `flutterEngine.getPlugins().add(new` occurs exactly 15 times
and `IntegrationTestPlugin` is absent. Do not regenerate config a second time
when only the readback predicate was wrong.
