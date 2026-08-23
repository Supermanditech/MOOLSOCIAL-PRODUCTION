# UAW C09 optional rg zero-match recurrence

## Incident

An optional probe searched the C09 source-aggregate manifest for test paths
with bare `rg`. The file contained no such match, so `rg` returned its normal
zero-match exit code 1 and the task runner reported the command as failed.

This repeated the registered rule that optional searches must distinguish no
match from execution failure.

## Prevention

Unknown-content evidence files are inspected with a bounded literal read before
search assumptions are made. Optional `rg` probes use an explicit 0/1/>1
wrapper: 0 retains matches, 1 records no matches without failure, and greater
than 1 rejects the command.

The read-only probe made no product, build, device or application-data change.
