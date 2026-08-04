# MoolSocial 9:00 AM founder decision brief

Prepared: 3 August 2026

State: **DECISIONS REQUESTED — NO PROVIDER, TAX OR COMMERCIAL FACT ASSUMED**

This brief is designed for a short founder review. Technical qualification is
not legal, finance, tax or founder approval. Where finance/legal/counsel must
co-approve, a founder answer records product intent but does not activate the
dependent runtime ticket by itself.

## What completed overnight

- All registered R56 popup families reached a terminal technical outcome.
  R56.3 and R56.4 are founder approved; R56.1, R56.2 and R56.6-R56.10 are
  technically/device qualified and await founder review; R56.5 is device
  rejected/stopped. R51 FIX16 remains explicitly deferred.
- R57.1 typo-tolerant Buy search is technically/device qualified and awaits
  founder review.
- SUP-001 participant capability, SUP-003 canonical catalogue/offer identity
  and B2B-002 FIX2 pack/logistics-unit contracts are technically qualified as local
  deterministic contracts. No endpoint, persistence or live data exists.
- Premium motion is now a mandatory pre-write policy for every future UI
  ticket and is fail-closed in the mandatory APK pre-build machine through
  qualified tooling ticket `BUY-POL-001`. Server-only tickets must record it
  as inapplicable rather than invent a UI.

## Decision 1 — remaining motion and search candidates

Review the currently installed cumulative R56.10 FIX2 binary, profile
`1.0.0-r56.10` (`2026080313`), APK/install SHA-256
`B86009EFD9A74E7AB3BC7FF20FC3690C78491F9E7D8832CF41ABA5AB2D7F1711`.
It must not be confused with the checksum of an earlier scoped candidate.

Review-preparation smoke on that exact installed checksum confirmed both
approved product-navigation continuity and `tomatos` hierarchy/detail/Back/
clear behavior. Evidence:
`artifacts/quality/production-foundation-founder-review-20260803-121/19-cumulative-navigation-review-readiness.md`.

For each candidate, record `APPROVE`, `CHANGE REQUEST` with the exact visible
defect, or `DEFER`:

| Owner | Candidate disposition requested |
| --- | --- |
| R56.1 Saved-clear confirmation | approve / change / defer |
| R56.2 scanner manual-code sheet | approve / change / defer |
| R56.6 catalogue tools/filter sheet | approve / change / defer |
| R56.7 deterministic payment-choice sheet | approve visual/interaction only / change / defer |
| R56.8 prescription sheet | approve / change / defer |
| R56.9 address-choice sheet | approve / change / defer |
| R56.10 request/add-address forms | approve / change / defer |
| R57.1 exact-first typo tolerance | approve / change / defer |

R56.5 is not review eligible. R51 FIX16 remains deferred. Async loading,
campaign/video, live/provider and other dependency-held effects are not
finished because their truthful owners do not yet exist.

Authorities:

- `docs/quality/BUY-R56-R57-9AM-OPPO-FOUNDER-WALKTHROUGH-20260803.md`
- `docs/quality/BUY-R56-POPUP-MOTION-STYLE-UX-TICKET-MATRIX-20260802.md`
- `docs/quality/BUY-FV2-R57-TYPO-TOLERANT-SEARCH-HANDOFF-20260802.md`
- `config/buy-premium-motion-policy.json`

## Decision 2 — B2B pilot (`B2B-001`)

Recommended lowest-risk pilot for founder/commercial consideration:

- category: non-regulated, packaged dry FMCG only;
- eligible supplier: separately verified manufacturer, wholesaler or
  distributor with wholesale capability for the exact category/service area;
- eligible buyer: verified retailer business workspace buying for resale;
- order authority: preparer plus a distinct workspace approver;
- cancellation: buyer may cancel before supplier acceptance; after acceptance,
  the snapshotted supplier terms and accountable exception owner apply;
- returns/damage: explicit sealed-pack, shortage, damage, batch and expiry
  evidence; no generic consumer-return promise; and
- initial payment: immediate approved gateway or verified bank transfer only.
  No invoice credit, pay-later, interest or lender claim in the first pilot.

Founder decision:

1. `APPROVE RECOMMENDED PILOT`, or list the exact category/participant changes.
2. Confirm procurement purpose: `RESALE`, `OWN BUSINESS USE`, or both with
   separately declared tax intent.
3. Confirm maker-checker requirement and spend-authority owner.
4. Confirm cancellation and return/damage owner.
5. Confirm the initial payment-policy classes; credit remains excluded unless
   separately approved with finance/legal review.

This decision alone does not unblock B2B-003: TAX-003 and its prerequisite tax
decisions must also be approved.

## Decision 3 — seller, invoice and collection model (`TAX-001`/`PAY-001`)

Recommended architecture already proposed by ADR-0010/0012:

- third-party goods: the verified participant making the supply is the seller
  and invoice owner;
- SuperMandi acts as the technology/e-commerce platform unless a separately
  named first-party supply makes SuperMandi the actual seller;
- SuperMandi's own subscriptions, AI, promotion or platform services use a
  separate SuperMandi seller/tax record;
- a consumer Cart may split into seller-specific orders/documents; and
- payment collection, settlement, refunds, disputes and TCS ownership follow
  the exact approved legal/provider arrangement and are never inferred from
  KYC completion or UI labels.

For each launch family—Shop, Medicine, Wholesale and any SuperMandi-owned
supply—name:

1. seller/merchant of record;
2. invoice issuer and GST registration owner;
3. consideration collector;
4. settlement beneficiary/owner;
5. refund and dispute owner; and
6. ECO TCS/section 9(5) treatment owner or required counsel determination.

Founder decision: `APPROVE ADR-0010/0012 ARCHITECTURE`, `AMEND`, or `DEFER`.
Indian GST counsel and finance must approve the statutory/operating entries
before TAX-002/TAX-003/PAY-003 runtime work begins.

## Decision 4 — PhonePe evidence registry and sandbox readiness

The founder reports KYC/partnership completion. Finance/provider owners should
be authorized to register only non-secret evidence for the exact SuperMandi
account:

- legal merchant/account ID and environment;
- contract-supported consumer, wholesale, marketplace and regulated-category
  scope;
- enabled methods, MCC/categories, limits, origins/package IDs and endpoint
  ownership;
- settlement bank/schedule, fees, holds, refund/dispute support and approvers;
- approved vault owner/path reference, without copying a credential; and
- UAT/go-live checklist and named PhonePe contact.

Founder decision: `AUTHORIZE NON-SECRET EVIDENCE REGISTRATION`, name finance
and security owners, or `DEFER`. This does not authorize credential access,
sandbox calls, an endpoint, deployment or funds movement.

## What becomes executable after valid decisions

- B2B-003 only after B2B-001 plus TAX-003.
- PAY-003 only after PAY-001, a production order owner and backend
  authorization.
- TAX-002/TAX-003 only after TAX-001 plus finance/counsel approval.
- DISC-002 backend/index work only after R57 founder approval and a registered
  canonical index owner.
- PhonePe adapter work only after PAY-002/PAY-003, security-approved sandbox
  authorization and provider evidence.

Until those gates are met, the qualified local contracts remain fail-closed
and no UI may claim a live price, tax, stock, payment, credit or provider fact.
