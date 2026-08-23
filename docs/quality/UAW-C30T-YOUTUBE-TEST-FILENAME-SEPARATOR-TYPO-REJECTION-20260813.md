# C30T YouTube test filename-separator typo rejection — 2026-08-13

## Rejection

The first post-format focused test invocation used `personal-mvp` in one
filename segment instead of the repository's exact `personal_mvp` spelling.
Flutter rejected the path before loading any test.

No source, backend, device, release, or external state changed. The rejected
invocation is not test evidence.

## Permanent prevention

Reuse the exact inventory-discovered path verbatim and accept evidence only
when Flutter reports the named tests and a successful total.
