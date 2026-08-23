# REG2697 — C34H multi-file patch used a stale remembered anchor

## Outcome

The combined gate/runner/wrapper patch was rejected atomically at an unmatched focused-gate anchor. It made zero changes and grants no candidate or release authority.

## Prevention

Every owner is patched through bounded freshly read anchors, parsed and read back independently. C34H is rebound to the new registry generation before any seal or cycle.
