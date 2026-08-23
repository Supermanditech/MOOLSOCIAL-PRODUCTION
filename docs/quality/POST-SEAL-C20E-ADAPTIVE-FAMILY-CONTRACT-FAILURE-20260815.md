# Post-seal C20E adaptive family contract failure

The focused current Eat audit ran
`uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart`
individually after a clean five-file analyzer result.

Observed result: 1 passed, 5 failed.

- Eat, Book and Work expected the compact cluster center at the 160-pixel rail
  center but received the current left-anchored cluster center at 76 pixels.
- Ride expected the compact cluster center at the 160-pixel rail center but
  received the current left-anchored cluster center at 116 pixels.
- The shared reduced-motion case attempted to cast the current keyed widget,
  which is a `SizedBox`, to `AnimatedContainer`.

The earlier independent suites remain separate evidence: Eat vertical 10/10,
C16D 2/2, and C24C 5 passed with 2 declared capture skips. No retry or source
mutation is authorized from this observation alone. REG-2297 must be
registered first, then C20E must be compared with later accepted navigation
and adaptive-layout authorities to determine whether this is a stale
test-contract owner or a current runtime defect.

REG-2299 corrects the initial geometric label; the native failure counts and
coordinates are unchanged.
