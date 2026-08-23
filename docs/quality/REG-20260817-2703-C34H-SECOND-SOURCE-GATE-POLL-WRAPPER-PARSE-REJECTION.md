# REG2703 — second C34H retained-session poll was not delivered

## Outcome

The poll wrapper was rejected before contacting PowerShell session `76488`. The gate result remained unknown at that moment; no seal or external authority followed.

## Prevention

Use a minimal single-call polling wrapper. Because registration advances the pre-seal registry, the affected matrix is superseded and replayed after rebinding.
