# SAM-R06 preselection robustness and reuse assessment

Date: 7 August 2026
Ticket: `SAM-R06-SERVER-WORKSPACE-LIFECYCLE-AUDIT-CONTRACT`
Classification: `mvp_required`

Customer outcome: every workspace request has one authoritative pending,
approved, rejected, suspended, expired or revoked state with a versioned,
attributable audit event and safe reason. Invalid or stale transitions fail
closed and cannot fabricate approval.

Smallest scope: one pure lifecycle aggregate/transition contract and exhaustive
local tests. Reuse the existing supply aggregate's state, expected-version,
immutable append-only audit and actor/reason patterns without merging supply
capability ownership. SAM-R01 supplies stable membership identity and SAM-R05
supplies capability policy; neither owns workspace lifecycle. Repository search
found no general cross-vertical workspace lifecycle aggregate.

Disposition: `reuse` plus `new_necessary_work`. One shared owner prevents each
profile adapter from inventing lifecycle transitions. New UI, route, store,
endpoint and build count: zero. SAM-R07 will add the separate general
idempotency/receipt protocol; SAM-R06 does not silently absorb that ticket.

Coverage: exact IDs, tenant/workspace binding, permitted transitions,
expected-version conflict, canonical time, reason ownership, terminal-state
protection, expiry boundary, append-only audit, deterministic immutable output
and input nonmutation. Excluded: UI, persistence, Firebase/API, live roles or
data, capability activation, money/provider action, APK/build/install,
credentials, Production, commit, push, deploy and promotion. Dependency-safe
reordering around SAM-R02/R03/R04 remains within the 60–75-day lock.
