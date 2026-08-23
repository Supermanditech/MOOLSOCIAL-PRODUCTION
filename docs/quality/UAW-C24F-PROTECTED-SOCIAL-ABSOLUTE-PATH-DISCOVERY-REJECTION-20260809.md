# C24F protected Social absolute-path discovery rejection — 2026-08-09

The first protected Social test command matched its name regex against full
absolute paths. Because the repository ancestor itself is named
`MOOLSOCIAL-PRODUCTION`, all 225 Dart tests matched and Flutter rejected the
command as too long before running any test. The retry applies the exact gate
predicate to paths relative to `apps/mobile/test` and requires 34 files before
execution.
