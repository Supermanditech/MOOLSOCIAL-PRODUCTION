# C30S YouTube source-directory addAll vararg pre-test defect

Date: 2026-08-12

The first migration away from deprecated `srcDirs` copied the old vararg call
shape into `MutableSet.addAll`, which accepts one collection. The mismatch was
caught by source review before Gradle ran.

Both multi-directory source sets now use `addAll(listOf(...))`. Gradle
configuration remains mandatory before the migration can pass qualification.
