# C29R composite format exit-masking rejection

Date: 2026-08-11

The first focused Flutter qualification invocation ran formatter, analyzer and
tests in one PowerShell command. `dart format --set-exit-if-changed` reported
that it changed `test/youtube_private_dev_client_test.dart`; the later 33/33
test pass then supplied the composite command's successful exit code.

The formatted source is retained, but that invocation is not accepted as a
no-change format gate. Future cycles apply formatting explicitly and run each
format check, analysis and test with an independently preserved exit status.
No build, device, deployment or external-service action occurred.
