# C13 regression entry referenced a future test

Date: 2026-08-07

Regression:
`REG-20260807-271-C13-REGRESSION-ENTRY-REFERENCED-FUTURE-TEST`

## Failure

The first C13 implementation-phase regression-memory gate stopped before any
runtime write because REG270 named
`apps/mobile/test/ui_v2/universal/uaw_personal_mvp_direct_default_subaction_landing_c13_test.dart`
as a gate before that test file existed.

## Root cause and prevention

The intended successor test was treated as present evidence while the ticket
was still in prewrite governance. A registry entry may reference only files
that exist at the moment it is parsed. REG270 therefore begins with the
existing static and regression-memory gates. The dedicated test is added to
the entry only after `apply_patch` creates it and a read-only inventory proves
the exact path exists.

No runtime source was changed before this rejection.
