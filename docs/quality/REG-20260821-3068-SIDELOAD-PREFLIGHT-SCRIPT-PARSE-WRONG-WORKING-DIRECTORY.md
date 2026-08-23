# REG3068 — sideload preflight parse used the wrong working directory

- Date: 2026-08-21
- Status: registered before retry
- Scope: local sideload preflight tooling and affected mobile authentication regression

## Incident

The bounded command started in `apps/mobile` but resolved
`scripts/prepare-moolsocial-sideload-build-environment.ps1` as though it were
running from the repository root. `Resolve-Path` failed, the parser check threw
`SIDELOAD_PREPARE_SCRIPT_PARSE_FAILED`, and PowerShell stopped before Flutter
tests started.

## Impact

- no APK build;
- no OPPO mutation;
- no provider, Play, Firebase or external action;
- no repository mutation by the failed command;
- the test result is not accepted as regression evidence.

## Root cause

The command combined a repository-root script path with a mobile-package
working directory without first resolving the repository root.

## Prevention

Resolve the helper using its absolute repository path, then run mobile tests
from `apps/mobile`. Keep the parse check and test invocation independently
addressable so a path failure cannot be mistaken for test execution.
