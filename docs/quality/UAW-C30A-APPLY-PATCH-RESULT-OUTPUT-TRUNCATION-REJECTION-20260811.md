# C30A apply-patch result output truncation rejection

- Regression: `REG-20260811-1350-C30A-APPLY-PATCH-RESULT-OUTPUT-TRUNCATION-REJECTION`
- Date: 2026-08-11
- Result: rejected before any retry or target inspection.

## Rejection

The mutation call that attempted to add the C30A ticket and its preselection evidence returned a truncated tool result. Neither file is accepted as materialized from that response alone.

## Permanent prevention

The two exact target paths are inspected only after this regression is registered. Any materialized JSON must parse before reuse. Future durable ticket creation uses one file per patch and then a bounded existence, parse and SHA-256 check. Unknown mutation results are never assumed successful.

## Scope safety

No app build, install, backend deployment, rule write, provider mutation, credential access, app-data clear, uninstall or downgrade is authorized by this regression record.
