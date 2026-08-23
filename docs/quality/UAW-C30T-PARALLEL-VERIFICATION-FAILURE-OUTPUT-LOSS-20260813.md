# C30T parallel verification failure-output regression

## Observation

Static analysis and a bounded Flutter regression suite were launched in one fail-fast promise aggregation. Static analysis returned four actionable warnings, and the orchestration failure suppressed the sibling test result.

## Root cause

Independent verification jobs were coupled without per-job nonzero-exit capture.

## Permanent prevention

- Run verification jobs independently when either result may be nonzero during active correction.
- If parallel execution is warranted, capture each job's success or failure independently before composing the output.
- Never treat one verification job's failure as permission to discard another job's evidence.
