# REG2777 — C34L browser producedUtc format fixture rejection

Date: 17 August 2026
State: registered first FIX1 behavioral failure; no external action

## Mistake

The first PowerShell 7 PRE-AAB-3-FIX1 self-test reached the executable checker
but its positive fixture was rejected because `producedUtc` did not satisfy the
new exact-UTC timestamp contract. The agent stopped without diagnostic, retry
or patch and fixture cleanup completed. No browser, provider, candidate,
release, private or external action occurred.

## Root cause and prevention

The fixture serializer and timestamp validator were introduced independently
without first round-tripping the exact accepted UTC wire format. Define one
explicit invariant UTC format, generate the positive fixture with that same
formatter, parse with invariant culture and round-trip equality, then add
malformed, non-UTC, expired and future-issued negatives on both hosts before
resuming the wider matrix.
