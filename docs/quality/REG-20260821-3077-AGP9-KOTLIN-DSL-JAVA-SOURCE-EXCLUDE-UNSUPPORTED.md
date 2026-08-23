# REG3077 — AGP 9 Kotlin DSL Java source exclusion unsupported

- Date: 2026-08-21
- Status: registered before retry

The targeted `compileReleaseJavaWithJavac` precheck stopped during build-script
compilation because AGP 9's Kotlin DSL source-set receiver does not expose the
attempted `java.exclude(...)` API. No Flutter APK build, artifact, device or
external action occurred.

Prevention: inspect the exact source inventory and use the supported
`setSrcDirs` contract to remove the otherwise empty Java source root while
retaining Kotlin and generated variant sources.
