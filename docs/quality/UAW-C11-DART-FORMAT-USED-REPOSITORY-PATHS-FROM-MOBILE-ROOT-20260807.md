# C11 dart format used repository paths from mobile root

- Regression: `REG-20260807-258-C11-DART-FORMAT-USED-REPOSITORY-PATHS-FROM-MOBILE-ROOT`
- Date: 2026-08-07 IST

## Observation

From `apps/mobile`, the formatter received paths beginning with
`apps/mobile/` and rejected them as missing. The subsequent analyzer used
correct mobile-relative paths, passed, and left the combined shell exit zero.
The formatter output is not accepted as pass evidence.

## Permanent correction

Run formatting separately with paths relative to its exact working directory
and validate that command before analysis. Never combine stages when a later
successful process could obscure an earlier failure.
