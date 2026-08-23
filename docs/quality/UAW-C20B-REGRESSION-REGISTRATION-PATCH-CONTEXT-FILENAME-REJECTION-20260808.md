# C20B regression-registration patch-context filename rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B`

The first attempt to register the guessed C17 gate filename used an unverified
registry context line. It changed the real focused test filename
`uaw_personal_mvp_subaction_disclosure_overflow_c20b_test.dart` into a
hyphenated form. `apply_patch` could not find that context and rejected the
entire patch atomically; neither the evidence file nor the registry entry was
written.

The retry read the literal registry tail and uses that exact context. Future
registry patches copy the final entry verbatim from a bounded tail read rather
than reconstructing long paths from memory.
