# C30T YouTube format working-directory path rejection — 2026-08-13

## Rejection

The format step ran from `apps/mobile` but received repository-root-relative
`apps/mobile/...` operands. Dart format rejected both paths. A subsequent
Flutter test in the same shell command passed, causing the compound command to
exit successfully; that mixed result is not accepted as complete verification.

No source was changed by the rejected format invocation. The focused test pass
is retained only as preliminary evidence.

## Permanent prevention

Formatting now runs separately with `lib/...` and `test/...` paths relative to
the declared `apps/mobile` working directory. Verification is accepted only
after formatting, analysis, and focused tests each complete successfully.
