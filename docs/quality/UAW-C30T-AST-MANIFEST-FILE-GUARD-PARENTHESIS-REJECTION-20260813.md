# C30T AST manifest file-guard parenthesis rejection

Date: 2026-08-13

The first AST-based manifest command had an unbalanced inline `if (Test-Path ...)` guard and was rejected by the PowerShell parser before reading the qualifier or running tests.

The corrected command uses a multiline resolved-path guard with balanced parentheses and accepts a manifest only when every literal Dart file exists.
