# C32R historical navigation test applicability reconciliation

Ticket: `UAW-C32R-PERSONAL-MVP-HISTORICAL-NAVIGATION-TEST-APPLICABILITY-RECONCILIATION`

The preserved exploratory eight-file batch was not retried. Its five
failure-bearing or unproven historical owners were executed individually with
their pre-audit hashes sealed by the C32R gate.

## Exact historical results

| Owner | Passed | Failed | Classification |
|---|---:|---:|---|
| C22F inner chroma | 1 | 8 | stale pre-C27 local geometry and chroma contract |
| C23C single launcher shell | 1 | 1 | stale pre-C25/C26 destination topology |
| C07 global Mool navigation | 1 | 4 | stale pre-C23-C27 home and rail topology |
| C20F aggregate regression | 2 | 2 | stale pre-C20H state and test-title tokens |
| R15 copy/fitment/accessibility | 1 | 15 | stale root-rail owner blocks the current matrix |

Total: 6 passed, 30 failed. No runtime or test expectation bytes changed while
collecting these results.

## Current authority comparison

Seven later accepted owners were run individually: C26D, C27B, C27D, C29N,
R03, C24B2 and C10E. They completed 33 passes, one declared candidate-capture
skip and zero failures. This includes 320x568 compact coverage, 140-percent text
coverage, all six family and subaction navigation, fixed Mool Home, current
platform Back behavior, reduced motion and Social creator/footer edge behavior.

The evidence therefore identifies five stale test contracts and no new runtime
defect. Findings REG-2277 through REG-2281 were registered before any migration.
Each owner has a separate test-only successor ticket C32S through C32W. Runtime,
backend, build, Play, OPPO, provider, external communication and secret access
remain closed.
