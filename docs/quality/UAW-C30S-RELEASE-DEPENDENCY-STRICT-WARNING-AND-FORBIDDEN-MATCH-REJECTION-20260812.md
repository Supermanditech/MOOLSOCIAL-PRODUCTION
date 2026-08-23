# C30S release dependency strict-warning and forbidden-match rejection

Date: 2026-08-12

Gradle dependency resolution exited zero and found the required Firebase
families, but the C30S audit intentionally returned failure because one
forbidden-name line remained and its warning set exceeded the narrow allowlist.

The warnings comprise Flutter 3.44/AGP 9 legacy compatibility in upstream
Flutter plugins, three still-KGP plugins, and repository-owned legacy DSL plus
`srcDirs` use in the private YouTube player plugin. No APK, AAB, device or
external action occurred.

The next step is a filtered exact forbidden-line read, repository-owned AGP 9
cleanup and a narrow upstream-only warning allowlist. The gate still requires
Gradle exit zero, required Firebase families present and removed unused direct
SDKs absent.

## Classification and correction

The single name match was `firebase-config-interop`, not the removed Firebase
Remote Config SDK. It is a required low-level interoperability artifact and is
explicitly allowed. The gate now matches exact forbidden Maven artifacts.

Repository-owned `srcDirs` calls were migrated to the source-directory mutable
set API. Remaining Kotlin/legacy-DSL warnings are limited to Flutter 3.44 and
third-party plugin compatibility output documented by Flutter for AGP 9.
