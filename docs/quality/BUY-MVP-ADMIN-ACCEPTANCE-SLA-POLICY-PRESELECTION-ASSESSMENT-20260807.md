# Buy acceptance-SLA policy preselection assessment

Date: 7 August 2026
Ticket: `BUY-MVP-ADMIN-ACCEPTANCE-SLA-POLICY`
Exact actor: Commerce Policy Administrator
Classification: `mvp_required`

An exact authorized Commerce Policy Administrator can publish bounded,
future-order-only Shop, Wholesale, non-prescription Medicine and pharmacist-
ready prescription Medicine acceptance timing. Later order snapshots can use
one immutable policy revision instead of hard-coded or indefinite time.

Production-source search found zero existing acceptance-SLA policy owners.
Complete docs/config search found the authorized exact behavioral contract.
The existing supply aggregates do not own assignment timing. SAM-R07 now owns
shared exact scope, confirmation, version, fingerprint, retry/conflict and
receipt behavior, so the Buy contract must compose it instead of duplicating
idempotency. Existing Superadmin UI remains unchanged and reference-gated.

Disposition: `reuse` plus `new_necessary_work`. Add one pure Buy acceptance
policy aggregate/effective-at contract and one test file. New screens, routes,
stores, endpoints and builds: zero. Necessity: no current source owner can
represent the four exact families, append-only revisions, 30–300-second window,
one-to-five attempts, derived ceiling and one-third/two-thirds offsets.

Coverage: four-family isolation; inclusive and adjacent-invalid bounds;
integer safety; derived ceiling and offsets; authorization/idempotency via
SAM-R07; tenant/aggregate/version binding; non-backdating and strict per-family
effective ordering; exact retry/conflict; immutable revisions, receipts and
audit; effective-at boundaries; payload-free audit; full backend regressions
twice. Excluded: presentation, persistence, active-order mutation, assignment,
stock, payment, messaging, WhatsApp, calling, provider action, APK/build/install,
credentials, Production, commit, push, deploy and promotion. Local domain slice
is under one day and inside the delivery lock; later adapter/UI slices remain
held by their environment/reference gates.
