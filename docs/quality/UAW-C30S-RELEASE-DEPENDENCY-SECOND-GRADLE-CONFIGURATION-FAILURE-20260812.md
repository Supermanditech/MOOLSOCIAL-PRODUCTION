# C30S release dependency second Gradle configuration failure

Date: 2026-08-12

After correcting the overbroad signing guard, the second
`releaseRuntimeClasspath` audit still exited `1` before resolving dependencies.
It also exposed the `android {}` legacy-DSL deprecation produced by Flutter
3.44's documented `android.newDsl=false` compatibility mode.

No APK, AAB, device or external action occurred. The complete bounded output
must identify and resolve the hard failure; only the exact documented Flutter
3.44 legacy-KGP/legacy-DSL warnings may remain classified, and the dependency
gate must exit zero before source qualification.

## Root cause and correction

AGP 9 disables custom `resValue` generation unless the feature is explicitly
enabled. The three non-secret Firebase Android identity resources therefore
failed configuration before dependency resolution. C30S now enables only
`buildFeatures.resValues` and keeps the API key outside Gradle/resources.
