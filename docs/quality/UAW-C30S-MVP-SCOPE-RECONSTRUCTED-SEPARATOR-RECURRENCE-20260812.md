# C30S MVP scope reconstructed-separator recurrence

Date: 2026-08-12

The first C30S transition of `config/mvp-scope-gate-state.json` repeated the
known C30R context failure: inherited exclusion values were reconstructed with
incorrect underscore and space separators. `apply_patch` rejected the entire
update before modification.

The recovery must use fresh literal `rg -n` reads and only one exact line per
patch. Array blocks must not be reconstructed. JSON parsing and the delivery,
scope and C30S machine gates are required after the bounded transition.
