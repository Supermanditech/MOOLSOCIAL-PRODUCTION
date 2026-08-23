# C30S test inventory split parser rejection

Date: 2026-08-12

A read-only test-inventory grouping command used regex-literal syntax as a
PowerShell `.Split` method argument and rejected during parsing. It never
executed; no file, artifact, device or external state changed.

Prevention is to use normalized repository-relative paths and platform path
APIs. The permanent C30S qualifier enumerates exact Dart test files without
ad hoc grouping expressions.
