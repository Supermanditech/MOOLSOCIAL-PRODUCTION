# REG2679 — C34F post-rejection reconstruction was overbroad

## Outcome

A combined read-only reconstruction emitted the known huge dirty-tree status together with multiple document reads, exceeded the retained output boundary, and stopped on the stale nonexistent path `docs/quality/REGRESSION-RETEST-MEMORY.md`. Only the independently visible branch and HEAD scalars are retained. No complete status, memory, handoff or candidate-state conclusion is counted from that command.

## Prevention

Resolve exact repository-owned filenames through a bounded `rg --files` filter, summarize status with counts rather than the full path inventory, and read each exact owner separately with bounded output. C34F remains rejected at `0/0/0/0`; this diagnostic record grants no successor or external-action authority.
