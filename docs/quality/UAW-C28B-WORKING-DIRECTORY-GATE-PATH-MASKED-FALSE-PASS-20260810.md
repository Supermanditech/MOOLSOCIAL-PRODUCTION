# C28B working-directory gate-path masked false pass

- Date: 2026-08-10
- Phase: focused implementation qualification
- Valid partial results: focused analyzer passed; 9 Flutter tests passed
- Invalid qualification: four PowerShell gates did not run
- Rejection: the command ran from `apps/mobile` but invoked `./scripts/...`;
  PowerShell reported four missing paths, then the successful final Flutter test
  returned exit code 0 and masked those errors.
- Root cause: repository-root gate paths were composed relative to the mobile
  package and the command was not fail-fast, recurring the REG928 path-safety
  class.
- Prevention: invoke repository gates from repository root or through exact
  `../../scripts` paths, set `$ErrorActionPreference='Stop'`, and never combine
  gate and test phases without checking each exit status.
