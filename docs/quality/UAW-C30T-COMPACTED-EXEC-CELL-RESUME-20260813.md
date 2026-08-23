# C30T compacted execution-cell resume regression

## Observation

After conversation compaction, the saved continuation summary referenced a yielded static-analysis and test execution cell. The runtime no longer retained that cell, so the resume operation failed before producing verification evidence.

## Root cause

An asynchronous tool handle from the pre-compaction execution runtime was treated as durable across the compacted continuation boundary.

## Permanent prevention

- Treat execution-cell identifiers carried through compaction as provisional.
- Check for an attached durable terminal before attempting to resume a retained cell.
- If no durable session exists, do not guess or repeatedly poll the missing identifier.
- Register the lost result and rerun only the documented bounded verification command from its exact working directory.
