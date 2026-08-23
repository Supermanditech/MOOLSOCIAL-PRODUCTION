# Buy MVP acceptance-policy audit and rollback completion

Date: 7 August 2026
State: `LOCAL_DOMAIN_SLICE_COMPLETE_STORE_ADAPTER_UI_AND_ORCHESTRATOR_CONSUMPTION_HELD`

`BUY-MVP-ACCEPTANCE-POLICY-AUDIT-ROLLBACK` now has one pure append-only
maker-checker governance aggregate. It references exact Ticket 1 global SLA or
Ticket 2 schedule-override revisions without copying their timing or selector
truth. Each governance lineage is tenant-, source-set- and subject-scoped: one
exact global family or one exact schedule override ID.

An authorized maker proposes a bounded explained future-effective revision. A
different authorized checker approves or rejects it. The first accepted lineage
must be a forward approval; later forward approvals must advance the exact
subject revision, while a rollback must point to an older exact revision and
take effect strictly after the prior approved era. A rollback is therefore a
new decision, never deletion or history rewrite. Ticket 3 active-order snapshots
and Ticket 4 provider readiness remain unchanged.

Authenticated inspection exposes pending, rejected and approved evidence.
Effective-at projection returns only an approved decision whose explicit clock
has arrived, with both maker and checker explanation. SAM-R07 provides exact
retry, changed-retry conflict, optimistic concurrency and immutable receipts.
Restart normalization enforces exact aggregate, source-reference, proposal,
decision, receipt and audit schemas; cross-subject, source-fingerprint,
coordinated-time and undeclared-field tampering fail closed. Audit evidence is
payload-minimized and excludes explanations and policy values.

Public source inspection also normalizes deserialized source-set version,
target revision position/schema, audit schema, common source-admin receipt
scope and override-state discriminator before returning any governance
reference. Coercible runtime scalars are rejected rather than trusted as types.

Final qualification passed: regression-memory and authorized MVP gates;
focused strict TypeScript; 18/18 final focused tests twice; complete backend
TypeScript; 471/471 full backend tests twice across 45 test files; targeted diff
check. Accepted focused TAP evidence is `19-focused-final2-cycle-1.tap` and
`21-focused-final2-cycle-2.tap`; full suite evidence is
`23-full-final2-cycle-1.tap` and `25-full-final2-cycle-2.tap`.

Only the pure domain slice is complete. Production governance persistence,
Firebase/API/callable adapter, Admin UI, order-orchestrator consumption and
automatic policy publication or learning remain held. No source revision,
active order, provider state, live data, credentials, Production, APK/build,
OPPO state, commit, push, deploy or promotion changed. OPPO r60.8 remains the
preserved founder-review APK.
