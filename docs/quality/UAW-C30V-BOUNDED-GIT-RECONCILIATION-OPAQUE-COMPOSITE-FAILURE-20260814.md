# C30V bounded Git reconciliation opaque composite failure

Date: 2026-08-14
Successor: r60.47 recovery

## Incident

The first post-authorization read-only Git reconciliation invoked branch, HEAD and bounded dirty-status capture inside one wrapper. The wrapper rejected because at least one component returned a diagnostic, but its combined exception did not identify which component or retain the bounded diagnostic.

No repository file, release artifact, Google Play state or OPPO state was mutated by the failed read.

## Prevention

Run branch, HEAD and dirty ownership as independent bounded reads. Each process captures stdout, stderr and exit separately, and reports only deterministic scalar evidence. Never let one component's diagnostic hide the others behind a compound exception.
