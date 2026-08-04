# Post-decision next-ticket readiness pack

Prepared: 3 August 2026

State: **IMPLEMENTATION-READY SPECIFICATIONS; RUNTIME DEPENDENCY HELD**

This pack reduces restart time after founder/finance/tax decisions. It creates
no runtime candidate or authorization and does not change the states in
`PRODUCTION-FOUNDATION-TICKETS-20260803.md`.

Common requirements for every eventual candidate:

- register one unique candidate before its first runtime write;
- record exact predecessor source manifest and dirty status;
- authorize tenant/workspace before lookup, version or business details;
- use exact decimals/minor units rather than binary floating point;
- make unknown, stale, ambiguous and unavailable explicit;
- persist only IDs, policy/evidence hashes and approved facts—not credentials;
- run focused tests, two complete unchanged-source regressions and every
  boundary/data-egress/protected gate; and
- apply `config/buy-premium-motion-policy.json` to any UI work, or explicitly
  record it inapplicable for a server-only candidate.

## DISC-002 — canonical exact/near search index

Runtime may register only after R57.1 founder approval and a named canonical
index owner. SUP-003 supplies stable product/pack/code identities; it does not
by itself create a deployed index.

### Bounded contract

A versioned read-only index snapshot contains tenant, source catalogue version,
generated timestamp, expiry/freshness policy and normalized entries for:

- canonical product title/aliases from governed content;
- brand and category identity;
- exact product/pack code keys;
- separately verified participant type/name;
- declared locality/service-area labels only when their owner is authoritative;
  and
- source IDs and hashes needed to explain a result.

The index does not contain popularity, search history, contacts, precise
location, profiling, ads, provider availability or a recommendation score.

### Matching/ranking acceptance

1. Apply tenant, buying context, category and authoritative service-area
   eligibility before text relevance.
2. Normalize Unicode/case/spacing deterministically without translating or
   silently adding synonyms.
3. Exact whole query, exact token, prefix and substring results lead in that
   order.
4. Only when no direct result satisfies the query, allow bounded
   Damerau-Levenshtein token fallback for tokens of four or more characters.
5. Every query token must match; IDs, GTIN/EAN/UPC and other governed codes are
   literal-only and never fuzzed.
6. Mark each result `exact` or `near` and include matched field/source IDs.
7. Equal relevance uses stable canonical ID ordering. No user history or
   randomized tie-break exists.
8. Missing/stale/ambiguous index state returns an explicit outcome, not a
   fabricated zero result or a guessed entity.

Required golden cases include `tomato`, `tomatos`, `frsh tomatos`, short `mlk`,
literal `s-tomato`, cross-context `w-tomato`, Medicine `paracetmol`, seller
`balajii`, duplicate names and normalized-code ambiguity.

Motion for the server/index candidate is inapplicable. A later Flutter
projection must reuse protected R48/R40 result motion and static reduced motion
rather than adding a second relevance animation owner.

## B2B-003 — wholesale offer/commercial-term snapshot

Runtime remains held until B2B-001 and TAX-003 are approved. B2B-002 provides
only physical pack/logistics truth and must never be mutated by this ticket.

### Bounded contract

One effective-dated participant offer-term snapshot references:

- SUP-003 offer/participant/service-area identity;
- B2B-002 verified profile and exact sale/loading level;
- buyer-use eligibility and approval policy from B2B-001;
- exact MOQ and allowed ordering multiple;
- non-overlapping exact quantity tiers with minor-unit price references;
- TAX-003 determination-policy/version references for HSN/SAC/UQC, GST/cess,
  place of supply and rounding;
- separately identified freight, unloading and deposit components;
- validity, order cut-off, lead-time range and delivery responsibility;
- batch/expiry acceptance, return/damage and shortage policy references; and
- an approved payment-policy class reference, never an invented credit term.

The snapshot contains no floating-point money, tax rate guessed by code,
provider method, available stock, promised serviceability, buyer credit limit
or order acceptance. Those require their separate owners.

### Acceptance and failure cases

- participant wholesale capability covers creation and the complete effective
  window for exact category/service area;
- MOQ and every tier boundary align with the B2B-002 sale multiple;
- tiers are contiguous/non-overlapping with deterministic boundary behavior;
- landed components are named and exact, never hidden in a display total;
- tax/payment fields are immutable approved references, not free text;
- past/backdated or overlapping windows fail;
- revision creates a new snapshot and never edits an accepted one;
- cancellation/return/damage responsibility is explicit;
- authorization, idempotency, optimistic version and append-only audit pass;
  and
- serialization/audit scans contain no credential or actual payment result.

Motion/device is inapplicable until B2B-010. The native B2B UI must later
explain pack, MOQ, tier, landed components, approval and payment truth under
reduced motion and OPPO qualification.

## PAY-003 — provider-neutral payment intent/attempt aggregate

Runtime remains held until PAY-001, the production order/obligation owner and
backend authorization are recorded. It must precede any PhonePe adapter.

### Bounded contract

- An immutable payable snapshot ID/hash owns legal merchant, buyer/workspace,
  seller order or wholesale PO obligation, exact amount/currency and expiry.
- One payment intent may own explicitly authorized attempts. Every provider
  submission uses a unique attempt/idempotency identity.
- State is server owned: `created`, `pending`, `authorized` when applicable,
  `paid`, `failed`, `expired`, `cancelled`, `unknown_reconcile`,
  `refund_pending`, `refunded` and `disputed`.
- A client redirect, app callback, local selection or screenshot cannot create
  authorization or success.
- An unknown debit remains unknown/reconcile; it cannot be mapped to failure
  merely to permit another charge.
- Provider failover is a separately authorized attempt only after the prior
  outcome is terminal or a named finance/support exception owns it.
- Refund, reversal, dispute, fee, settlement and bank reconciliation events are
  append-only references and do not edit the original attempt.

### Required deterministic tests

- duplicate tap/idempotent retry;
- stale payable snapshot, amount/currency mismatch and expiry boundary;
- unauthorized/cross-tenant access before existence/version checks;
- client callback cannot mark paid;
- timeout/invalid provider payload produces unknown/manual reconciliation, not
  a fabricated failure;
- duplicate, late and out-of-order event convergence;
- terminal-state transition matrix and no silent failover;
- partial/full refund references without double mutation; and
- audit/data-egress scan proving no credential, raw card data or secret.

This ticket has no provider transport, webhook, credential, endpoint or mobile
handoff. PAY-004/PAY-005/PAY-006 own those later boundaries. Motion and OPPO are
therefore inapplicable to PAY-003 itself.

## Immediate sequence after decisions

1. If R57.1 and index ownership are approved, register/implement DISC-002.
2. If B2B-001 plus TAX-001/002/003 are approved, register/implement B2B-003.
3. If PAY-001 plus the order owner are approved, register/implement PAY-003.
4. PhonePe sandbox work remains later and requires non-secret activation
   evidence plus explicit security/provider authorization.
