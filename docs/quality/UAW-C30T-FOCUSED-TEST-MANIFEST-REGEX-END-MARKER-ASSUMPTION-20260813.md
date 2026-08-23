# C30T focused-test manifest regex end-marker assumption

Date: 2026-08-13

The first local extractor guessed the variable assignment that follows `$focusedTests` and failed before producing a file list or running tests. No partial manifest is accepted.

The corrected extraction must use the PowerShell AST assignment expression or an inspected exact boundary, require a non-empty literal Dart-file list, and verify every file exists before execution.
