# Buy provider ready/busy/pause state preselection assessment

Date: 7 August 2026
Ticket: `BUY-MVP-PROVIDER-READY-BUSY-PAUSE-STATE`
Exact actor: authorized operator bound to the exact qualified supply workspace
Exact capability: `commerce.provider_readiness.operate`
Classification: `mvp_required`

Actor binding is exact: Grocery/Kirana Shop or enabled General Retail Shop for
Shop; FMCG Supplier/Distributor or separately enabled Manufacturer pilot for
Wholesale; and licensed Medical Store/Pharmacy for Medicine. A generic
provider identity cannot declare readiness. The operator must be bound to the
same tenant/workspace and the applicable SUP-001 `retail_fulfilment` or
`wholesale_supply` capability must be active for the exact category, service
area and declaration instant.

Reviewed production search returned only unrelated YouTube/UI wording and
Ticket 2's read-only `declared_busy` selector. No backend owner can append or
resolve provider `ready`, `busy` or `paused` declarations. SUP-001 is locally
qualified and supplies workspace/capability truth; SAM-R07 supplies exact
scope, confirmation, version, retry/conflict and receipt behavior. Disposition
is `reuse` plus `new_necessary_work`: add one pure workspace readiness
aggregate, append-only scheduled declarations and authenticated effective-at
projection.

Every declaration has canonical non-backdated `effectiveFrom` and a later
`expiresAt`; no readiness is indefinite. Revisions are strictly ordered.
Projection is explicit: `ready`, `busy`, `paused`, `unknown` before the first
effective declaration, `stale` after expiry, or `ineligible` when the exact
SUP-001 capability is not active. Later declarations never rewrite history.
No client timer or local state can create capability or readiness truth.

Coverage includes all exact workspace/family bindings, retail versus wholesale
capability, category/service-area mismatch, suspended/expired capability,
wrong role/tenant/workspace, future schedule boundaries, backdating, expiry,
stale/unknown/ineligible results, exact retry/conflict/concurrent update,
offline-safe same-command replay, JSON restart, immutable payload-free audit,
input nonmutation, focused tests twice and complete backend regressions twice.

New screens/routes/stores/endpoints: zero. Excluded: inferred state, personal
phone/apps/messages/contacts/microphone/background location, live workspace or
provider action, order assignment, policy snapshot, nonresponse penalties,
Admin override, persistence/Firebase/API, presentation, messaging/calling,
payment/funds, credentials, Production, APK/build/install/OPPO, commit, push,
deploy and promotion. Local estimate is under one day and inside the delivery
lock; live adapter and UI slices remain held.

Pre-write identity: branch
`remediation/prototype-conformance-2026-07-20`, HEAD
`f6dfe7587aa02d782e94282d14af8bafff48ded0`, portfolio manifest SHA-256
`5CE81AB6332607A71B960C57A1E99466109E13299CD8A5995FFC3163F35893AF`,
SUP-001 source SHA-256
`C3FF8514C12DC7500F02E8BE91C99EA72A7F508C4E4D8285E67150C1AA4A8B07`.
Invocation-local long-path dirty inventory contained 50,218 entries, UTF-8/LF
SHA-256 `9F493670E0C325C3F2548C77852D7F69F9F34BC646346BCB4DFF6FD100DD2E5F`,
with zero warnings. Existing tracked/untracked files remain preserved.
