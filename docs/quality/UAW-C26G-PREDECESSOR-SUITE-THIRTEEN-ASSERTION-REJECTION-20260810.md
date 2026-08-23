# C26G predecessor suite thirteen-assertion rejection

## Detection

The first correctly constructed 47-file C26G suite prevalidation executed the broad predecessor inventory plus the five C26 tests. It ended with 335 passing tests, 11 skips and 13 failures. The combined compact output was too large to retain every failure owner in the tool result.

This run is rejected and is not a C26G qualifying cycle.

## Required investigation

Run the predecessor files in isolation, record every exact failing test and assertion, and classify each against the immutable C26 approved navigation contract. Superseded presentation assertions may be migrated only when they contradict the approved replacement; real runtime regressions must be fixed and receive focused machine-detectable coverage. No file may be silently dropped to obtain a green host cycle.

## Resolution

Isolation found four failing files. Every failure was a superseded shared-navigation presentation assertion: the removed close button and old semantics label, removed `glass-control` keys, removed Previous/Next cells and their 44px dimensions, or platform Back in a router-less presentation harness. These were migrated to the C26 semantics, `selection` keys, 54x58 Mool/family cells and approved outside-tap dismissal. All four files then passed together with 53 tests; route, business, Chat and exact-state assertions were not weakened.
