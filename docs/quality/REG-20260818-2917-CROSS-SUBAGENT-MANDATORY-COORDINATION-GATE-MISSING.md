# REG2917 — Cross-subagent mandatory coordination gate was missing

## Finding

The repository required every mistake to be registered, but it did not assign regression-number allocation exclusively to the primary, maintain machine-readable active owner claims, reject duplicate numeric prefixes, or require every subagent to pass one coordination gate before mutation/testing.

This allowed broader classes of preventable coordination defects: duplicate REG2910 allocation, concurrent registry movement invalidating readiness pins, overlapping or stale cross-owner patches, and inconsistent stop/retry discipline.

## Required permanent prevention

- Repository `AGENTS.md` mandates the coordination policy and gate for every task.
- `docs/quality/CODEX-SUBAGENT-MANDATORY-COORDINATION-POLICY-20260818.md` defines primary-only registry/action authority, owner claims, generation serialization, outage/session recovery, fixture/path controls, private/device boundaries and completion rules.
- `config/codex-subagent-coordination-policy.json` records mandatory reads, primary-only owners, active exclusive claims, incident protocol, release serialization and the complete prevention-class inventory.
- `scripts/check-codex-subagent-coordination-policy.ps1` rejects stale registry count/SHA, duplicate full or numeric IDs, duplicate tasks, overlapping owners, primary-only subagent claims, missing reads/policy tokens and branch/HEAD drift.
- Subagents report incidents and wait; only the primary assigns IDs and updates registry/policy claims.

## Scope

The prevention is repository-wide and applies to every future primary/subagent task, not only C34L or regression-number collisions.

## Impact and disposition

The policy/gate addition changes no candidate, runtime, provider, build, browser, Play, OPPO, private/account, device, secret or external state. Active FIX3 agents remain paused until the registry, policy binding, memory gate and coordination gate pass and the primary sends literal resume instructions.
