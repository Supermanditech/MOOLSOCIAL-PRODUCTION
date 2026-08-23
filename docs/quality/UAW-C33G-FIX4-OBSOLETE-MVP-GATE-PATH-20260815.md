# C33G FIX4 obsolete MVP gate path regression

- Regression: `REG-20260815-2453-C33G-FIX4-OBSOLETE-MVP-GATE-PATH`
- Failed action: a read-only continuation command requested the nonexistent `scripts/check-mvp-scope-gate.ps1`.
- Canonical owner: `scripts/check-mvp-scope-gate-state.ps1`, resolved from the repository file inventory.
- Impact: the composite diagnostic exited nonzero; no source, release state, device, provider, or external service was mutated.
- Prevention: after an interrupted continuation, resolve each gate path from `rg --files` before its first invocation. The Codex regression-memory gate carries this rule forward.
