# REG2857 — C34L capture FIX2 WinPS journey row shape

Date: 17 August 2026
State: registered first WinPS source-attestation fixture failure

## Mistake

After the PS7 source-attestation FIX2 gate passed in 5.1 seconds with three
positives and twenty-two exact negatives, the first Windows PowerShell run
failed the positive journey writer with `journey acceptance-manifest row set
changed`. Source, Play, and OPPO positives had passed; cleanup completed. The
likely cause is host-specific JSON array enumeration, but no diagnosis, retry,
or later mutation followed.

## Prevention

Normalize the parsed journey manifest with a shape helper that distinguishes a
top-level JSON array from pipeline unrolling and always returns exactly six row
objects on both hosts. Assert exact row count, unique ordered journey IDs, and
no nested/singleton shape before validation.
