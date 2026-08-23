# C27E scope-transition oversized-hunk context rejection

The first C27E scope transition used one oversized patch spanning assessment,
ticket and protected-candidate sections. An exclusion string in the patch did
not exactly match the current JSON, so `apply_patch` safely rejected the entire
mutation.

Scope transitions must use smaller owner-bounded hunks with exact current
context. No scope field changed during the rejected attempt.
