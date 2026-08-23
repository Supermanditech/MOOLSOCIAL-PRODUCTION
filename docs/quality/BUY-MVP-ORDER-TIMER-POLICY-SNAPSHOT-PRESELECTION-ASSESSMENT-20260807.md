# Buy order timer-policy snapshot preselection assessment

Date: 7 August 2026
Ticket: `BUY-MVP-ORDER-TIMER-POLICY-SNAPSHOT`
Exact actor: Order Assignment Orchestrator
Exact capability: `commerce.order_assignment.timer_snapshot`
Classification: `mvp_required`

Customer outcome: when bounded provider assignment begins, one authorized
server orchestrator freezes the exact effective policy provenance, family,
window, partner-attempt limit, overall ceiling and every derived escalation
instant into the order's immutable timer snapshot. Later Admin edits cannot
change that order. After process restart, projection from the stored snapshot
and an explicit clock instant returns the same attempt and phase.

Verified production-source search returned zero order timer-policy snapshot
owners. Complete docs/config authority search returned the exact portfolio and
parent references. Ticket 1 supplies exact global family timing and Ticket 2
supplies optional effective override provenance; SAM-R07 supplies tenant/scope,
confirmation, optimistic version, fingerprint, retry/conflict and receipt
behavior. Disposition is `reuse` plus `new_necessary_work`: add one pure pending
to snapshotted order-timer aggregate and deterministic progress projector.

The command commits order ID, family, assignment start, global policy-set and
revision identity/version, and—when selected—the exact override-set,
revision/version and selector fingerprint. The server request must provide the
matching immutable source revision. The snapshot copies timing facts and
builds one through five absolute attempt schedules; the final expiry must equal
the order-level ceiling exactly. Global and override sources are explicit and
cannot be mixed, substituted or changed after snapshot creation.

Coverage includes all four families and both provenance modes; source identity
and timing mismatch; inclusive timing bounds inherited from Ticket 1; exact
attempt/WhatsApp/call/expiry instants; overall-ceiling equality; before-start,
active phase, reassignment-boundary and terminal progress; deterministic JSON
restart; authorization before hidden order values; effective source at the
assignment instant; effective-now/non-backdating; exact retry, conflict and
concurrent race; immutable payload-free audit/receipt; input nonmutation;
focused and full backend regressions twice.

New screens/routes/stores/endpoints: zero. Excluded: creating an order,
persistence, Firebase/API/callable adapter, payment or protected-funds truth,
candidate ladder/provider selection, stock, acceptance/reassignment command,
message/call execution, countdown UI, active snapshot edit, credentials,
live data/Production, APK/build/install/OPPO, commit, push, deploy and
promotion. Local estimate is under one day and inside the delivery lock.

Pre-write identity: branch
`remediation/prototype-conformance-2026-07-20`, HEAD
`f6dfe7587aa02d782e94282d14af8bafff48ded0`, manifest SHA-256
`5CE81AB6332607A71B960C57A1E99466109E13299CD8A5995FFC3163F35893AF`,
Ticket 1 source SHA-256
`969CDA34D065127FDEB0D3BFF1E1D1E92CCF37F1C2640C087B7D6400369B7C4B`,
Ticket 2 source SHA-256
`0C6129297194FE48AD376BF75F2F84EAF50FFF5A0E677A6760B1390F98F44460`.
Invocation-local long-path dirty inventory contained 49,901 entries, UTF-8/LF
SHA-256 `9CFA87DFEFAD08D807C3AED878AA2CAF813336F6F9A1D81E62F4E28B3FCA97C1`,
with zero warnings. All existing tracked and untracked files remain preserved.
