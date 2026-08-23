# REG2663 — C34E preseal phase-fixture historical-candidate mirror omission

Date: 2026-08-16 IST

The first C34E transition-matrix attempt failed closed before any source cycle, hidden input, build, Play write or device action. The real C34E state and aggregate contained 20 historical candidates, including rejected C34D, while all four cloned phase fixtures retained 19.

Root cause: fixture registry and manifest bindings were updated without first comparing their `historicalCandidates` arrays with the final candidate state and aggregate.

Permanent prevention:

- Count no pass from the rejected fixture invocations.
- Retain the registry-2633 draft manifest without overwrite or promotion.
- Append the exact rejected C34D contract to both fixture states and both fixture aggregates.
- Before every phase matrix, assert all six state/aggregate owners have the same historical count and last version/machine-state identity.
- Rebind registry 2634 and create a new registry-2634 draft manifest before retry.

C34E remains preseal at `0/0/0/0`; this is not an app, build, AAB, Play, authentication or OPPO failure.
