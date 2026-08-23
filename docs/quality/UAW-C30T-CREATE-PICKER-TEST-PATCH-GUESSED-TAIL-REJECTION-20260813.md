# C30T Create picker-test patch guessed-tail rejection — 2026-08-13

## Rejection

A Create picker-failure test patch guessed the exact formatted tail of the
existing fake picker. The expected typed `const` line did not match the current
file, so `apply_patch` rejected the operation atomically.

## Prevention

The retry reads the exact insertion point and tail, then patches the widget test
and failing picker separately. No test file was partially changed and no
provider, build, Play, OPPO, Hosting or communication action occurred.
