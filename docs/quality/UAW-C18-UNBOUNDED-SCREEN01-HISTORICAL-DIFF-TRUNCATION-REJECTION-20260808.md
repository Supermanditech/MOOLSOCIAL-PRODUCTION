# UAW C18 unbounded Screen01 historical-diff truncation rejection — 2026-08-08

## Rejected attempt

The first protected-Screen01 provenance comparison requested one combined
`git diff --unified=80` across the accepted source and test owners between
commits `b2839b82f5d2164e60df3d89e5ca39e1419acf86` and
`da656725c33bff7be42c190761892dc1d6a816bb`. The execution output was
truncated by the tool and therefore cannot establish any line-level
conclusion about the divergence.

No production source, test, accepted reference, runtime, build, install or
device state was mutated by the rejected read-only attempt.

## Root cause

Two potentially large historical file diffs and eighty lines of context were
combined without first measuring their size or bounding the returned output.

## Permanent prevention

Historical provenance comparisons must first inventory `--numstat` and
`--stat`, then inspect one verified file at a time in explicit non-overlapping
bounded slices. Truncated output is rejected rather than used as evidence.
The permanent regression-memory checker remains the active pre-retry gate.
