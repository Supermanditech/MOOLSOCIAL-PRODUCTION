# C24D Social customer-copy removed-rail rejection

- Observed: 2026-08-09 in the complete 34-file protected Social suite.
- Rejected path: the customer-copy gate attempted to tap removed `screen04-rail-videos`, `screen04-rail-feed` and `screen04-rail-create` controls.
- Correction: mount each protected Social subaction directly, then run the unchanged customer-copy policy over its actual rendered owner.
