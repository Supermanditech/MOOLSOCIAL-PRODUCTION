# C30Z cycle-2 summary copied an unrerun focused result

Date: 2026-08-15
Regression: `REG-20260815-2227-C30Z-CYCLE2-SUMMARY-UNRERUN-FOCUSED-RESULT-COPY`
Status: resolved; exact focused cycle-2 rerun passed 36 with native exit zero

## Finding

The cycle-2 JSON repeated `focusedAuthAndFeed.passed=36` from cycle 1 before
the exact three-file focused suite had a second execution. The full 418/3
manifest run and analyzer were valid, but the copied focused field was not yet
cycle-2 evidence.

## Prevention

The exact focused suite is rerun for cycle 2 with native exit zero before the
field is retained. Future cycle summaries bind every named suite to one exact
execution in that cycle or state that it was not rerun. No build, Play, OPPO,
provider, credential or external-service state changed.
