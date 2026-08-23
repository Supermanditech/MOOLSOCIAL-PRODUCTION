# C25F generated menu-key search rejection

Date: 2026-08-09

A bare ripgrep search for a guessed generated main-menu key returned exit code
1. That result is not evidence of absence and cannot guide a test migration.
Further inventory must inspect the actual key constructor or explicitly handle
ripgrep's zero-match exit code. The regression-memory gate remains mandatory.
