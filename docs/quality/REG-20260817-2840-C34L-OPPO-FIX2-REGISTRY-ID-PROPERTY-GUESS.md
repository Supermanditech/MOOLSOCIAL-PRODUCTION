# REG2840 — C34L OPPO FIX2 registry ID-property guess

Date: 17 August 2026
State: registered read-only registry projection recurrence; zero mutation

## Mistake

While projecting the current registry tail, the OPPO FIX2 agent guessed entry
property `regressionId` instead of authoritative `id`. Count and file hash were
valid, but every tail ID rendered null. The agent did not inspect schema, retry,
or mutate afterward.

## Prevention

Use the already established registry schema and exact `id` property. Treat null
tail IDs as an unexpected diagnostic failure, and never guess a projection
property that REG2793 already resolved.
