# REG2691 — C34G source-gate session identities were not retained

## Outcome

Both corrected dual-host source gates reached the execution yield, but the orchestration projection omitted their returned session IDs. Their results are unknown and neither is counted.

## Prevention

Prove exact sanitized process absence first. Then run each host separately, retain the complete execution result, and poll only the returned session until an explicit exit result is available.
