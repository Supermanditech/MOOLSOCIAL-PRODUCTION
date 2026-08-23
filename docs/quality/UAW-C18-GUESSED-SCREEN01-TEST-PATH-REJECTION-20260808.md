# UAW C18 guessed Screen01 test-path rejection — 2026-08-08

## Rejected attempt

The first bounded historical comparison for the Screen01 test used the
guessed path
`apps/mobile/test/ui_v2/screen01_app_splash/app_splash_screen_v2_test.dart`.
Git returned no diff because that owner does not exist. The result was not
used as evidence of equality or divergence.

The immutable v3 acceptance record was then read directly and identifies the
real locked owner as `apps/mobile/test/ui_v2_screen01_app_splash_test.dart`.
No production source, test, accepted reference, runtime, build, install or
device state was mutated by the rejected read-only attempt.

## Root cause

A conventional directory-shaped Flutter test path was inferred from the
production source layout instead of being taken from the lock manifest.

## Permanent prevention

Protected-owner comparisons derive every path from the exact accepted lock
record or a verified repository file inventory. An empty diff for an
unverified operand cannot prove file equality. The regression-memory checker
must pass before retrying the comparison with the declared owner.
