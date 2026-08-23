# REG2829 — C34L combined producer OPPO journal wire-token divergence

Date: 17 August 2026
State: registered final PS7 combined-producer failure; diagnosis pending

## Mistake

The final PowerShell 7 combined-producer run failed while the Windows
PowerShell run passed. The OPPO writer rejected the combined fixture journal
because it did not contain exactly one canonical `preparedUtc` wire token. The
OPPO writer's independent dual-host transaction suite had passed; no diagnosis,
retry, owner mutation, real state, or external action followed.

## Prevention

After registration, inspect only the combined fixture's retained journal
construction and raw JSON token once. Reuse the qualified OPPO transaction
checker/writer interface rather than synthesizing a host-dependent journal, and
assert exact prepared/committed raw-token cardinality before invoking the writer.
