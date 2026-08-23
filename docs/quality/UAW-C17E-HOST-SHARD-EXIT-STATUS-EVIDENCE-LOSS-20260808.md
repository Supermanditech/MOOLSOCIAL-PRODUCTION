# C17E host shard exit-status evidence loss — 2026-08-08

## Rejection

The first attempted C17E host-cycle shard 1 execution yielded a running cell, but its later completion output and exit status were not retained. Resuming cell `609` returned `cell not found`, and the Codex desktop terminal reported that no terminal session was attached to the task.

This attempt is not a qualifying host-cycle result. No pass or failure is inferred from partial progress output.

## Permanent prevention

- A host shard counts only when its own command returns a final exit code and explicit Flutter completion line in a retained tool result.
- If an execution cell disappears before final status is collected, record the evidence loss and rerun the whole shard as a new, uncounted attempt.
- Use bounded output for long Flutter shards and wait on the execution cell until final completion; never credit partial output.
- Each shard remains an independent command so no later success can mask its status.

No production source, installed application, device data, build artifact, or protected runtime was changed while resolving this evidence failure.
