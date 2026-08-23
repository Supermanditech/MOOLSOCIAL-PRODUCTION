# C22G regression registry guessed-path rejection

- Observed: 2026-08-08 while registering the reserved-variable failure.
- Rejection: a diagnostic read guessed
  `config/regression-memory-registry.json`, which does not exist. The durable
  owner is `config/codex-development-regression-registry.json`.
- Root cause: the registry filename was inferred instead of discovered from a
  bounded repository inventory.
- Permanent prevention: locate the exact registry with `rg --files` before
  reading or patching it, and use only that literal verified path.
- Runtime/device effect: none. The failed read made no mutation and authorized
  no retry, build or install.
