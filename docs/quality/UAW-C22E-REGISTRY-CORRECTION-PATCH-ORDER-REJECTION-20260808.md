# C22E registry correction patch-order rejection — 2026-08-08

The first combined REG-536 correction and REG-537 insertion used overlapping hunks against the same registry tail object. `apply_patch` rejected it atomically. REG-20260808-538 requires one exact current-tail replacement.
