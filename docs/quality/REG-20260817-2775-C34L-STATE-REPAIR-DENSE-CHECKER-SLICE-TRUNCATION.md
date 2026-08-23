# REG2775 — C34L state repair dense checker slice truncation

Date: 17 August 2026
State: registered read-only reconstruction failure; no FIX1 mutation

## Mistake

The PRE-AAB-1 FIX1 agent read the first 160 lines of the dense 708-line
blocker/browser checker in one terminal result. The result exceeded the
available model context and was truncated. The agent stopped without retry,
REG2774 read, edit or test. Branch and HEAD were exact; no browser, state
transition, seal, cycle, build, Play, OPPO, private or external action occurred.

## Root cause and prevention

The page was bounded only by line count after compaction, not by the unusually
dense bytes per line and current result budget. Read this owner in independent
non-overlapping pages no larger than 80 lines, require every page to return
without truncation and cover exact EOF before FIX1 mutation.
