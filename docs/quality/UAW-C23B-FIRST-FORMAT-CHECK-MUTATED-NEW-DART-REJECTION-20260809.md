# C23B initial format-gate rejection

- Date: 2026-08-09
- Build/device mutation: none

The initial no-diff format command encountered newly patched, unnormalized
Dart, reported both files would change and returned exit 1. Because
`--output=none` writes nothing, both files remained unformatted. The batch
stopped before analysis or tests, so it did not qualify C23B.

The corrected workflow first runs plain `dart format`, then reruns the no-diff
format gate and performs focused analysis/tests.
