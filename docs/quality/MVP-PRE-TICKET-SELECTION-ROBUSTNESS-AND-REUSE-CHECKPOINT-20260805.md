# MVP pre-ticket-selection robustness and reuse checkpoint

Authority date: 5 August 2026
State: founder required; fail closed before every successor selection

## Purpose

This is the secondary checkpoint that runs **before choosing or registering**
any preauthorized child, any other MVP ticket, or any separately authorized
beyond-MVP ticket. It prevents a ticket list from becoming duplicate coding
and ensures schedule reduction never reduces product robustness.

The currently active web/YouTube remediation ticket was selected before this
checkpoint. Its narrow transition exception applies only to selection and ends
when that exact machine-state ticket is replaced. It grants no new web scope
and no successor authority.

## Required checkpoint work

Before replacing the current ticket in `config/mvp-scope-gate-state.json`,
Codex must:

1. inventory the current native V2 routes, screens, components and state
   owners; existing tested non-UI models/controllers/services/adapters; the
   approved connected HTML reference; relevant legacy routes for containment;
   and the applicable ticket manifests and dependencies;
2. map every exact actor/outcome acceptance ticket to a shared or provably
   necessary implementation owner;
3. label each unit `reuse`, `configuration`, `thin_policy_adapter`,
   `test_only_acceptance` or `new_necessary_work`;
4. search for duplicate screens, routes, services, state owners and builds;
5. record necessity proof for every proposed new screen, route or backend
   owner;
6. preserve exact failure/recovery, truthful state, security, privacy,
   accessibility, lifecycle, observability and release coverage; and
7. record dependency order and delivery impact against the 60–75-day lock.

The completed assessment is stored with the selected ticket's disclosure and
referenced from the machine state. Missing, stale or mismatched evidence blocks
ticket selection and therefore blocks implementation.

## Permitted adjustment overlay

Codex may adjust the implementation plan without changing a protected
manifest by:

- reusing a shared screen, route, component, controller, service or backend
  owner;
- implementing an exact ticket as configuration, a thin policy adapter or
  acceptance tests where no new presentation/owner is needed;
- combining implementation waves while keeping exact actor/outcome acceptance
  and evidence separate;
- reordering tickets around real dependencies to prevent rework; and
- adding missing robustness acceptance for failure, recovery, security,
  privacy, accessibility or observability.

Codex may not remove an approved outcome, change an actor/capability, mutate a
preauthorized manifest/hash, add beyond-MVP scope or waive a gate through this
checkpoint. Any such material change needs a versioned proposal and the exact
founder authorization that would otherwise be required.

Machine contract:
`config/mvp-pre-ticket-selection-robustness-checkpoint.json`.
