# UAW C30W YouTube-package metrics foreach-pipe parser rejection — 2026-08-14

## Scope

This record covers a read-only inventory command during the C30W overnight YouTube reviewer-package audit. It did not mutate repository, cloud, email, quota, Play, device, service, or secret state.

## Mistake

A PowerShell command attempted to pipe directly from a statement-form `foreach (...) { ... }` block into `ConvertTo-Json`. PowerShell rejected the empty/invalid pipeline element before producing the bounded file metrics.

## Impact

- No file metrics were admitted from the rejected command.
- No file contents or sensitive values were printed.
- No repository or external state changed.

## Root cause

The result-producing loop was composed as a statement at the pipeline boundary rather than being assigned to an explicit array first.

## Prevention and retry rule

- Assign `foreach` output to a task-specific array variable.
- Pipe only the completed array to `ConvertTo-Json`.
- Keep path lists explicit and bounded.
- Treat parser rejection as zero evidence and retry only after registration.

## Resolution

Registered before retry as `REG-20260814-2104-C30W-YOUTUBE-PACKAGE-METRICS-FOREACH-PIPE-PARSER-REJECTION`.
