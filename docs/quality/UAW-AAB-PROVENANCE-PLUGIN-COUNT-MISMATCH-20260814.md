# UAW AAB provenance plugin-count mismatch

## Finding

The current single-AAB wrapper reads the generated release registrant and
requires exactly 16 `flutterEngine.getPlugins().add` calls. Later, the same
wrapper writes `releaseRegistrantPluginCount = 15` into the sealed AAB
provenance.

## Risk

An AAB could build successfully while its retained provenance makes a false
claim about the packaged plugin surface. That undermines post-build evidence
and is incompatible with the founder's hard gate.

## Required repair

One exact release-plugin count must own both the prebuild assertion and the
provenance field. The wrapper static gate must reject any divergence. Until the
repair passes two source-only audit cycles, build authority remains false and
no AAB may be invoked.

## Resolution

The wrapper now owns the exact expected release plugin count once and uses
that value for both the generated-registrant assertion and AAB provenance. The
static wrapper gate requires all three bindings. Build authority remains false
until the complete successor gate is source-qualified.
