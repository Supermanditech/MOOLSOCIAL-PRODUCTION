# C22E cumulative test patch-context rejection — 2026-08-08

The first cumulative-test migration patch expected a pre-format multiline finder; the current file contained a formatter-compressed finder. `apply_patch` rejected all hunks atomically. REG-20260808-540 requires current context and separate patches.
