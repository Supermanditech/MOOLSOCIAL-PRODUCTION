# C30T required-owner reconciliation truncation recurrence

## Incident

After the laptop restart, the first reconciliation command grouped the root
and repository `AGENTS.md` owners with branch, HEAD and the complete dirty-tree
status. The output exceeded the available tool context and was truncated.
The entire grouped output was rejected; it is not evidence that any required
owner or repository state was reconciled.

## Impact

No source, ticket, build, upload, install, cloud runtime or device state was
changed by the rejected read. The only mutation before retry is this regression
record and its registry/memory entries, as required by the permanent project
regression rule.

## Prevention

On every restart or compaction:

1. Read each required `AGENTS.md` owner independently.
2. Measure dense owners before reading and use numbered, non-overlapping
   windows of at most 200 lines through exact EOF.
3. Reconcile branch and HEAD separately from dirty ownership.
4. Never print the entire intentionally huge dirty tree in the same tool output
   as a required policy owner.

## Retry qualification

The retry is admissible only after the regression-memory gate passes and every
required owner has been read completely using bounded output.
