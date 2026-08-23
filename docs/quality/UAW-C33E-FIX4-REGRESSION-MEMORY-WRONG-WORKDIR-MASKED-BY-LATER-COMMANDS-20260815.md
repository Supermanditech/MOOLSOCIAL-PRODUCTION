# UAW C33E FIX4 regression-memory wrong workdir masked by later commands

Date: 2026-08-15
Regression: `REG-20260815-2352-C33E-FIX4-REGRESSION-MEMORY-WRONG-WORKDIR-MASKED`

## Failure

The FIX4 retry command ran from `apps/mobile` while its first two preflight paths were repository-root relative. Registry validation and the regression-memory gate therefore failed before format, analyzer and Flutter tests ran. PowerShell continued to later commands, so later analyzer/test output cannot substitute for the missing preflight.

## Recovery

Discard the combined run as qualification evidence. Register all failures first. Run registry validation and the memory gate in a separate fail-fast repository-root command, then run mobile format/analyzer/tests from `apps/mobile` only after that preflight succeeds.

No build, provider, device or release action occurred.
