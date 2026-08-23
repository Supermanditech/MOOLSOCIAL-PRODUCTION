# C12 regression-memory wrong working directory

- Regression: `REG-20260807-266-C12-REGRESSION-MEMORY-WRONG-WORKING-DIRECTORY`
- Phase: tooling

A combined command ran from `apps/mobile` but invoked the repository checker
as `scripts/check-codex-development-regression-memory.ps1`. PowerShell could
not resolve that repository-relative operand, while the following analyzer
still ran and made the mixed command harder to interpret.

Prevention: repository PowerShell gates run alone from the repository root.
Flutter/Dart tools run alone from `apps/mobile`. Each command has one working-
directory owner and one independently checked exit result.
