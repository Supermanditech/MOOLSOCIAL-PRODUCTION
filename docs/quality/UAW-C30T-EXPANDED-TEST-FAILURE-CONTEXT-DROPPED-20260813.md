# C30T expanded test failure context dropped — 2026-08-13

## Observed result

The first expanded pre-AAB Flutter audit selected 49 Social, YouTube, Chat, customer-copy, fitment, accessibility, cold-launch and global-navigation test files. It completed with 303 passing tests, one intentional skip and six failures.

## Diagnostic mistake

Only the final 120 compact-reporter lines were emitted. Compact progress output displaced the earlier failure blocks, so the six failing files and assertions were not retained in the tool result.

## Correction

The next read-only diagnostic isolates test files and retains each failure block before any source correction or aggregate retry. Tests for separately gated YouTube upload capabilities must be classified against the founder-declared read-only reviewer scope instead of being silently treated as candidate acceptance.

## Prevention

Never truncate a newly widened failing test partition until the failing file names, assertion text and stack locations have been durably captured.
