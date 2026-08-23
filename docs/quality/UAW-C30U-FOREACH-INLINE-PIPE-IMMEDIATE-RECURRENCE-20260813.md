# C30U immediate foreach inline-pipe recurrence

## Incident

The next batched read-only reconciliation repeated the invalid direct pipeline
from a PowerShell `foreach` statement in its machine-state projection command.
The batch is rejected as qualification evidence.

## Root cause

The newly registered collection-assignment prevention was not applied to every
separately composed subcommand in the parallel batch.

## Permanent prevention

Release diagnostics must not contain the direct statement pattern `} |`.
Assign loop output to a named collection before any formatting or filtering,
and reject a batch in full when one constituent command fails to parse.

No external service, build, upload, install or device mutation occurred.
