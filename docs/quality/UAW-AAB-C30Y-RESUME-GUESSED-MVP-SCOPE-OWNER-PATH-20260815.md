# UAW AAB C30Y resume guessed MVP scope owner path

Date: 2026-08-15
Regression: `REG-20260815-2206-AAB-C30Y-RESUME-GUESSED-MVP-SCOPE-OWNER-PATH`
Status: resolved; exact owner inventory and post-registration cycles passed

## Finding

The first post-resume reconciliation probe guessed
`config/mvp-scope-state.json`. That file does not exist. The bounded config
inventory established that the durable owner is
`config/mvp-scope-gate-state.json`.

## Resolution

Regression memory passed after registration. Both fresh qualification cycles,
the substantive comparison and final available-authority replay used the exact
scope owner and passed without changing release action counts.

No build, upload, activation, install, device, provider, deployment or
credential action occurred. The failed read-only probe changed no release
counts or authority.

## Prevention

- Resolve every resumed release owner from exact repository references or a
  bounded `rg --files` inventory before reading it.
- Treat a missing inferred path as a registered failed probe; never silently
  substitute it inside the same assertion.
- Re-run regression memory after registration before any qualification retry.
