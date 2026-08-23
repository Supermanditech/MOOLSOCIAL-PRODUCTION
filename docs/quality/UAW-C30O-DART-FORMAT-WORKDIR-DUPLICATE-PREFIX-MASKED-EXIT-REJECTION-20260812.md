# C30O Dart format workdir duplicate-prefix masked-exit rejection — 2026-08-12

## Disposition

The format subcommand is rejected as no evidence. The following focused Flutter test completed successfully, but its exit code masked the earlier path failure. No build, device, provider, console or account state changed.

## Mistake

From the `apps/mobile` working directory, the combined command passed `apps/mobile/test/platform_configuration_test.dart` to `dart format`, producing a nonexistent duplicate prefix. The later successful test made the overall shell exit zero.

## Root cause

Repository-root paths were reused after changing the working directory, and two commands were combined without preserving the first native exit.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Use `test/platform_configuration_test.dart` from the mobile working directory.
- Run formatting and tests as separate commands so each native exit is authoritative.
