# C25E chained format/Eat-test command — rejection

Date: 2026-08-09

The Eat migration passed, but its formatter and Flutter test were invoked in one shell command separated by a semicolon. That orchestration form violates the workspace command-output discipline and is not reused.

All later formatter, analyzer, gate and test commands must be issued as separate shell calls without separators.
