# C25G guessed C25F manifest filename lookup failure

Date: 2026-08-09

## Rejection

A read-only reuse diagnostic guessed a plausible C25F conformance-manifest
filename. That owner did not exist, so the lookup could not provide evidence.

## Recovery

No product or machine state changed. The exact C25F owner is discovered from
the bounded repository file inventory or its gate before the read is retried.

## Permanent rule

Never reconstruct a versioned owner path from naming convention alone.
