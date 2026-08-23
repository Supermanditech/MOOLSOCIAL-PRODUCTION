# REG2944 — Supported-auth MVP checkpoint historical projection truncation

## Observed event

The supported-auth inventory correctly avoided full MVP-state emission but projected every property under `preTicketSelectionCheckpoint`, expanding more than 100 historical assessment objects. The 2,093-line / approximately 63,880-token result truncated. The agent stopped before memory/coordination gates, web, source-map edit, provider/private/device action, or external write.

## Root cause

REG2942 bounded the top-level state projection but did not distinguish the five current checkpoint scalars and `selectedTicketAssessment` from append-only historical assessment properties nested in that subtree.

## Mandatory prevention

For `preTicketSelectionCheckpoint`, project only `checkpointId`, `path`, `sha256`, `state`, `currentTicketId`, and the exact `selectedTicketAssessment` subtree. A historical assessment is read only by one explicitly named property. Never enumerate all checkpoint properties or assessments.
