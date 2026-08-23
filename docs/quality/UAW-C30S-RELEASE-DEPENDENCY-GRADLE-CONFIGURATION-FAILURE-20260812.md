# C30S release dependency Gradle configuration failure

Date: 2026-08-12

The first `releaseRuntimeClasspath` audit exited `1` during Gradle
configuration. The bounded result contained 47 lines, an unsupported Kotlin
plugin warning and a hard `BUILD FAILED` result. No APK, AAB, device or external
action was performed.

The first command deliberately returned only classified warning/failure lines,
so the exact causal lines remain to be read in one complete bounded diagnostic.
Source qualification and the single AAB authority stay blocked until the root
cause is fixed and the release dependency audit exits zero without the removed
unused Firebase/UI SDKs.

## Root cause and correction

The signing guard matched any Gradle start-parameter text containing
`release`. It therefore treated the read-only `releaseRuntimeClasspath`
configuration as an artifact packaging task and demanded founder signing
secrets. The guard now recognizes only release assemble, bundle, package,
install and signing-validation task families. Actual AAB packaging remains
fail closed; dependency inspection remains secret-free.

Flutter 3.44 documents the AGP 9 legacy-KGP compatibility flags currently in
this project, and built-in Kotlin migration requires Flutter 3.47 or later.
C30S therefore permits only that exact known warning and does not broaden into
a Flutter/toolchain upgrade.
