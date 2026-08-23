# SAM-R07 preselection robustness and reuse assessment

Date: 7 August 2026
Ticket: `SAM-R07-IDEMPOTENT-PRIVILEGED-COMMAND-PROTOCOL`
Classification: `mvp_required`

Customer/operator outcome: one exact authorized and confirmed privileged
command creates at most one attributable result. Exact retry returns the prior
receipt; a reused command ID with changed payload, scope, actor, reason,
confirmation or version fails closed.

Smallest scope: one pure shared command envelope/reservation/receipt contract
and exhaustive local tests. Reuse the supply contract's SHA-256 fingerprint,
scope-before-state, expected-version and receipt semantics plus existing
redaction/security patterns. SAM-R06 owns lifecycle; SAM-R07 owns only generic
command authorization/idempotency and does not duplicate lifecycle state.

Disposition: `reuse` plus `new_necessary_work`. A shared owner prevents every
participant/reviewer/launch adapter from implementing different replay and
confirmation behavior. New UI, route, store, endpoint and build count: zero.

Coverage: stable IDs, tenant and scope, explicit confirmation, bounded reason,
canonical time, JSON-safe bounded payload, sensitive-key rejection,
deterministic fingerprint, authorization before replay/version, exact replay,
conflicting replay, stale version, one completion receipt, result digest,
immutability and input nonmutation. Excluded: persistence, Firebase/API, live
role/command/data, money/provider action, APK/build/install, credentials,
Production, commit, push, deploy and promotion. SAM-R01/R05/R06 are complete;
reordering around held SAM-R02/R03/R04 remains within the delivery lock.
