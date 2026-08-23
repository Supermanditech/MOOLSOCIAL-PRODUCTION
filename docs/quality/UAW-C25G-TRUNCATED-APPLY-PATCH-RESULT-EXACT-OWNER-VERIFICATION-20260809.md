# C25G truncated mutation result exact-owner verification

Date: 2026-08-09

## Rejection

The multi-file C25F-to-C25G transition returned truncated tool output. Its
durable result was therefore unknown and could not be inferred.

## Verified recovery

Before another mutation, bounded readback verified all five intended owners:
C25F is complete, C25G is selected with reference/test-gate writes only, the
parent selects C25G after C25F, and both completion/preselection evidence files
exist. No transition retry was made.

## Permanent rule

A truncated mutation result requires exact-owner readback. Only confirmed
missing deltas may be retried.
