# UAW C33F two-static-gate combined-read truncation

Date: 2026-08-15

## Registered mistake

The initial C33F static-gate audit combined unbounded full reads of
`scripts/check-c30x-fix2-preflight-order-contract.ps1` and
`scripts/check-play-internal-aab-build-wrapper-c30v.ps1`. The combined output
was truncated before complete coverage of either file could be verified.

## Safe correction

- Register the failure before retry.
- Measure exact bytes and lines for each file.
- Read one file at a time in bounded, non-overlapping pages through EOF.
- Do not invoke or modify either gate until complete coverage is established.
- Preserve the C33F release hold; this mistake consumes no build, upload,
  activation, install, device, provider, or secret authority.
