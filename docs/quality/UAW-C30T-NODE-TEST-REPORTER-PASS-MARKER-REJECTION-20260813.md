# C30T Node test reporter pass-marker rejection

Date: 2026-08-13
Scope: C30T qualification cycle 1 backend verification

## Evidence

Backend verification returned exit code zero with exactly 503 tests, 503 passed, 0 failed, 0 cancelled, 0 skipped and 0 todo. The active Node reporter prefixes summary rows with `ℹ`; the qualifier expected only the older `# pass 503` decoration and stopped after the successful test command.

No provider mutation, AAB build, upload, Play update, device mutation, Create write or Chat message occurred. C30T counters remain zero.

## Resolution

The qualifier continues to require a zero native exit code and now independently requires anchored summary values for exactly `pass 503` and `fail 0`, permitting only reporter decoration before those labels.
