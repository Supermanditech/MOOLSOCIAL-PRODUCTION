# REG-20260817-2754: C34L postimage proof-history singleton unrolling

## Truthful event

After REG2752 and REG2753 were registered and their transaction corrections
were implemented, the implementation regression-memory gate passed at 2724
entries and 1732 applicable lessons. The first PowerShell 7 lifecycle fixture
then stopped inside postimage proof-history validation because `.Count` was
read from a singleton proof-history value that PowerShell had unrolled to a
scalar under strict mode. The transaction sub-agent stopped without inspection,
retry, correction, or further test.

The run was fixture-only. No real C34L state, aggregate, source seal, cycle,
AAB, Google Play, device, credential, secret, deployment, or external state
changed.

## Root cause

The new history validator did not normalize every pipeline/property result to
an array before count and index operations, so the one-record case had a
different runtime shape from the multi-record case.

## Prevention

- Wrap detailed history, aggregate history, filtered records, and paired
  enumerations in explicit `@(...)` array normalization before `.Count` or
  indexing.
- Exercise zero, one, and multiple history records under strict mode on both
  PowerShell hosts.
- Resume from a new unique fixture root only after registration and a passing
  updated regression-memory gate.

## Candidate consequence

C34L remains selection-only. The failed run is zero qualification evidence and
authorizes no real state creation or external action.
