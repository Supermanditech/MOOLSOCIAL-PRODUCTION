# C30U C30J signed-out auth-handoff regression

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Failure identity

The bounded authoritative JSON diagnostic reproduced one authored error:

`C30J signed-out viewer starts the distinct MoolSocial auth handoff`

The manifest totals remained `403 passed / 3 skipped / 2 failed` with Flutter
exit `1`. The exact assertion/error text has not yet been diagnosed, so no
product or test mutation is authorized from inference.

## Suspected affected contract, not yet root cause

C30U intentionally added an explanation-first signed-out YouTube account
journey before MoolSocial authentication. The C30J test may still encode a
direct first-tap handoff, or the implementation may have broken a retained
distinct-account invariant. The exact current test and production owners must
be inspected before deciding which is true.

## Prevention

Resolve the exact test owner from the current tree, read its bounded assertion
region, then run only this exact named test with the expanded reporter. Preserve
the distinct MoolSocial-versus-YouTube account contract while migrating only a
superseded first-tap expectation, if proven. Add positive and negative coverage
before a new full manifest attempt.

## Release effect

No C30U source manifest or cycle seal exists. C30U build/upload/install counts
remain `0/0/0`; no C30U AAB, upload, Play activation or OPPO mutation occurred.

## Root cause and repair

The C30J test both bypassed truthful session startup and encoded a direct
first-tap sign-in expectation. C30U intentionally adds an explanation-first
step. The repaired fixture seeds completed setup in the exact in-memory store,
starts into `ready` while unauthenticated, proves the dialog does not navigate
or change authentication, taps the explicit continuation, and then proves the
same YouTube-channel-connection purpose, return and Videos cancellation routes.

The exact named test passes with one authored test and no failure.
