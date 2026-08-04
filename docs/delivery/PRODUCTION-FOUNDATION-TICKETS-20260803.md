# MoolSocial production-foundation ticket register

Prepared: 3 August 2026

State: **registered planning backlog; no provider, payment, production-data or
deployment authorization**

Authorities:

- `docs/decisions/ADR-0009-UNIFIED-BUY-CATALOGUE-OFFERS-AND-FULFILMENT.md`
- `docs/decisions/ADR-0010-GST-INVOICE-SNAPSHOT-AND-SELLER-TAX-IDENTITY.md`
- `docs/decisions/ADR-0011-PAID-AI-SHOPPING-AGENT-CONSENT-BOUNDARY.md`
- `docs/decisions/ADR-0012-PAYMENT-ORCHESTRATION-CONSUMER-WHOLESALE-BOUNDARY.md`
- `docs/delivery/45-DAY-GO-LIVE-PLAN.md`
- `docs/quality/INDIA-GST-INVOICE-PRIMARY-SOURCE-RESEARCH-20260803.md`
- `docs/quality/INDIA-PAYMENT-GATEWAY-AND-WHOLESALE-B2B-PRIMARY-SOURCE-RESEARCH-20260803.md`

The tickets below are deliberately smaller than a feature launch. `READY
AFTER DECISION` means contract/test work may start only after the named
proposal is approved. It never authorizes credentials, live data, payment,
provider calls, deployment or promotion.

Post-decision implementation acceptance for DISC-002, B2B-003 and PAY-003 is
preflighted in
`docs/delivery/POST-DECISION-NEXT-TICKET-READINESS-PACK-20260803.md`; this does
not change their dependency/state gates.

## Delivery policy quality gates

| Ticket | Deliverable and acceptance | Dependency | State |
| --- | --- | --- | --- |
| BUY-POL-001 | Fail-closed APK pre-build validation of the canonical premium-motion policy, coverage/contract/disposition evidence, all four effect-disposition categories and required policy rules; deterministic positive and negative self-tests. No Flutter/runtime/APK change. | Existing APK regression machine + premium-motion policy | FIX1 TECHNICALLY QUALIFIED — TOOLING ONLY; NO APK/OPPO CHANGE |

## GST, invoice and marketplace finance

| Ticket | Deliverable and acceptance | Dependency | State |
| --- | --- | --- | --- |
| TAX-001 | Founder/legal operating decision: seller marketplace/agent versus exact merchant-of-record exceptions; name invoice issuer, consideration collector, TCS owner and section 9(5) treatment per launch supply family. | Indian GST counsel + finance | FOUNDER DUAL MODEL SELECTED — GST COUNSEL/FINANCE VALIDATION REQUIRED |
| TAX-002 | Versioned workspace tax-identity service: GSTIN/status/place/effective dates, regular/composition/exempt state, AATO/e-invoice policy, evidence hashes, reviewer, roles, suspend/revoke. Fail closed; no client verification. | TAX-001 | PROPOSED |
| TAX-003 | Effective-dated tax-policy and determination contract for HSN/SAC/UQC, place of supply, values, discounts/freight, rates/cess/reverse charge and rounding. Golden statutory fixtures and independent finance review. | TAX-001/002 | PROPOSED |
| TAX-004 | Seller-order invoice ledger and atomic serial allocator per GST registration/FY/series; <=16 permitted characters, idempotent duplicate result, immutable render/hash, concurrency and financial-year rollover tests. | TAX-002/003 + production order owner | PROPOSED |
| TAX-005 | IRP adapter with eligibility policy, credential isolation, IRN/signed-QR acknowledgement, timeout/retry/idempotency/cancellation/deadline/manual-review states and sandbox evidence. | TAX-004 + provider authorization | BLOCKED |
| TAX-006 | Append-only credit/debit-note and return adjustment aggregate linked to original invoice/order lines; no in-place invoice edit; tax/payment/stock/book reconciliation tests. | TAX-004 + returns ledger | PROPOSED |
| TAX-007 | Authorized invoice projection/download/share for customer and workspace roles; short-lived capabilities, accessible document UI, offline-safe last-known state, legal retention and support recovery. | TAX-004/005/006 + founder UI review | BLOCKED |
| TAX-008 | ECO TCS collection/return/reconciliation ledger and seller statement derived from consideration and return events; handles exclusions and multi-operator boundaries without changing invoices. | TAX-001 + payment/settlement owner | BLOCKED |
| TAX-009 | Backup, restoration, audit-trail, data-dictionary, legal-hold, 72-month-or-longer retention and export drill with tamper and disaster-recovery evidence. | TAX-002-008 | BLOCKED |

## Payment gateway, collection and settlement

The proposed first provider is PhonePe under SuperMandi Tech Pvt Ltd. Founder-
reported KYC/partnership completion is recorded as an assertion to verify; it
does not authorize credentials, provider calls or a production-enabled claim.

| Ticket | Deliverable and acceptance | Dependency | State |
| --- | --- | --- | --- |
| PAY-001 | Founder/finance/legal operating decision per launch supply family: exact SuperMandi merchant role, seller/merchant of record, consideration collector, settlement owner, refund/dispute owner and marketplace/seller-payment model. Must agree with TAX-001. | ADR-0012 + TAX-001 | FOUNDER DUAL MODEL SELECTED — FINANCE/LEGAL/PROVIDER EVIDENCE REQUIRED |
| PAY-002 | Non-secret merchant activation evidence registry for PhonePe: legal name/account ID, contract scope, environment, enabled methods/categories/MCC and limits, origins/package IDs, endpoint ownership, settlement bank/schedule, fees/holds, refund/dispute support and named approvers. Secrets exist only in an approved vault. | PAY-001 + finance/provider evidence | BLOCKED |
| PAY-003 | Provider-neutral server payment-intent/attempt aggregate with merchant and provider IDs, payable snapshot, amount/currency/expiry, idempotency, explicit pending/unknown/terminal/refund/dispute states and append-only audit events. Client callbacks cannot create success. | PAY-001 + production order owner + backend authorization | READY AFTER DECISION |
| PAY-004 | PhonePe Standard Checkout sandbox adapter for server authorization, payment initiation and order-status polling. Credentials remain server-side; contract tests cover expiry, duplicate tap, timeout, invalid response and unknown debit. | PAY-002/003 + security-approved sandbox authorization | BLOCKED |
| PAY-005 | Authenticated webhook intake with replay protection, deduplication, out-of-order convergence, quarantine/dead-letter recovery and polling reconciliation. Deterministic fixtures prove no duplicate order/payment mutation. | PAY-004 + public endpoint/security authorization | BLOCKED |
| PAY-006 | Founder-reviewed mobile checkout handoff/return/status UX: enabled-method projection, pending/unknown/failure/retry/refund states, Back/deep-link/app-switch/process-death restoration, accessibility and reduced motion. Flutter holds no secret and never marks paid. | PAY-003-005 + approved reference | BLOCKED |
| PAY-007 | Append-only refund, reversal and dispute/chargeback workflow tied to payment attempt, order, return/credit note, provider result and support ownership; partial/duplicate/failed refund tests. | PAY-003/005 + TAX-006 + returns owner | BLOCKED |
| PAY-008 | Finance settlement/reconciliation ledger for gross, provider fee, tax on fee, reserve/hold, net bank settlement, seller payable and unmatched exceptions; provider/dashboard/bank imports reconcile without editing history. | PAY-001/003/005 + TAX-008 | BLOCKED |
| PAY-009 | Consumer method-policy allowlist by merchant/category/amount/provider capability: UPI, card, net banking or wallet only when verified enabled; no raw card storage. Pay-on-delivery and offers require separate owners/evidence. | PAY-002/003 | BLOCKED |
| PAY-010 | Wholesale payment-policy contract for immediate UPI/gateway, verified bank transfer, deposit/balance and approved invoice terms; maker-checker, due/hold/release, remittance matching and exception states. No app-invented credit/lending fact. | PAY-001/003 + B2B-001/003/004 + TAX | BLOCKED |
| PAY-011 | Secondary PA/provider readiness: capability mapping and adapter contract after PhonePe sandbox. Failover is a new authorized attempt only after the prior debit is terminal; unknown outcomes cannot be silently retried. | PAY-004/005/008 | BLOCKED |
| PAY-012 | UAT/go-live security and finance gate covering provider checklist, secret rotation, webhook/certificate controls, card-data boundary, cyber/fraud limits, data egress, failure drills, support, reconciliation and environment-specific promotion approval. | PAY-002-011 | BLOCKED |

## Wholesale B2B packs, pricing, terms and delivery

These tickets refine ADR-0009. They make provision for wholesale in the shared
commerce model without exposing wholesale commitments in consumer FMCG Buy.

| Ticket | Deliverable and acceptance | Dependency | State |
| --- | --- | --- | --- |
| B2B-001 | Founder/commercial decision on pilot categories, eligible buyer and supplier types, procurement versus resale use, order approval, cancellation/return ownership and initial payment-term policies. | ADR-0009/0012 | FOUNDER DUAL MODEL/ELIGIBILITY SELECTED — INITIAL COMMERCIAL DEFAULTS REQUIRED |
| B2B-002 | Effective-dated verified pack and logistics-unit contract: each/inner/case/pallet or weight/volume UQC, consumer/case configuration, sale/loading multiple, dimensions/weight, barcode/codes, batch/expiry and evidence/review state. | SUP-003 + catalogue governance | FIX2 TECHNICALLY QUALIFIED — LOCAL CONTRACT; PERSISTENCE/ENDPOINT HELD |
| B2B-003 | Effective-dated wholesale offer/term snapshot with MOQ, quantity-price breaks, taxable/landed components, GST/cess, freight, unloading/deposit, validity/cut-off/lead time, delivery responsibility, return/damage and payment policy. | B2B-001/002 + TAX-003 | READY AFTER DECISION |
| B2B-004 | Verified business-buyer workspace eligibility, ship/bill destinations, GST intent, roles and maker-checker/spend authority; personal account membership cannot silently authorize a PO. | SUP-001/002 + TAX-002 | BLOCKED |
| B2B-005 | Serviceable wholesale quote/availability snapshot for destination, pack, quantity, inventory freshness, fulfilment node, promised window and landed components; stale/partial/unavailable is explicit. | B2B-002/003 + SUP-004 | BLOCKED |
| B2B-006 | Separate wholesale basket and idempotent purchase-order commitment with pack-multiple/MOQ validation, stock/price/term revalidation and immutable accepted snapshots. It never merges with consumer Cart. | B2B-004/005 + SUP-005 | BLOCKED |
| B2B-007 | Load, dispatch, delivery and receiving events for cases/pallets/weights, split/partial fulfilment, proof of delivery, goods receipt, shortages, damage, rejection and accountable exception owner. | B2B-006 + logistics owner | BLOCKED |
| B2B-008 | Wholesale invoice/payment-term and fulfilment-hold bridge: advance/deposit/balance/invoice due, remittance matching, release rules, overdue/exception projection and credit-note linkage. | B2B-006/007 + PAY-010 + TAX-004/006 | BLOCKED |
| B2B-009 | Return/claim/credit-note/stock/settlement reconciliation for quantity, batch, damage, shortage and commercial dispute; append-only evidence and seller/buyer support ownership. | B2B-007/008 | BLOCKED |
| B2B-010 | Founder-reviewed native wholesale decision UX for pack/loading quantity, MOQ, tier and landed-price explanation, terms, delivery, buyer approval and payment state. Consumer Shop hides B2B commitments. Requires 320 px/140%, Android/iOS sizes, reduced motion and OPPO qualification. | B2B-002-009 + approved reference | BLOCKED |

## Paid AI shopping agent

| Ticket | Deliverable and acceptance | Dependency | State |
| --- | --- | --- | --- |
| AIA-001 | Founder decision on value proposition, eligible users, price/limits, supported languages/categories and prohibited outcomes. | ADR-0011 | FOUNDER LAUNCH/PERMISSION MODEL SELECTED — PRICE/PRIVACY/SAFETY APPROVAL REQUIRED |
| AIA-002 | Versioned consent and purpose ledger with independent grants for query, Cart, Saved, orders, service PIN and business workspace; revoke/export/delete behavior and deterministic tests. | AIA-001 + privacy approval | PROPOSED |
| AIA-003 | Minimal context-envelope schema with tenant isolation, provenance, expiry and field-level deny list; threat model proves no credentials/payment/GST evidence/private Chat leakage. | AIA-002 | PROPOSED |
| AIA-004 | Read-only catalogue/offer/serviceability tools returning authoritative IDs, freshness and citations; unknown/stale behavior and prompt-injection resistance. | SUP-003/004 + DISC-001/003 | BLOCKED |
| AIA-005 | Draft-comparison and draft-basket policy; explicit confirmation before real Cart mutation; no order/payment/address/prescription/tax mutation. | AIA-004 + real Cart command owner | BLOCKED |
| AIA-006 | Separate paid entitlement, metering, spend cap, invoice and cancellation using ADR-0005; normal Buy remains usable without AI. | AIA-001 + payments + TAX-004 | BLOCKED |
| AIA-007 | Provider evaluation/egress gate: groundedness, unsafe medicine, fabricated facts, cross-tenant, multilingual, accessibility, outage and cost tests; Dev-only provider trial by separate authorization. | AIA-002-006 | BLOCKED |

## Supply-side workspaces and canonical commerce

| Ticket | Deliverable and acceptance | Dependency | State |
| --- | --- | --- | --- |
| SUP-001 | Server participant/workspace/capability model for shop, retailer, pharmacy, wholesaler, distributor, manufacturer and delivery partner; capability states are independently verified and audited. | ADR-0009 | TECHNICALLY QUALIFIED — LOCAL CONTRACT; PERSISTENCE/ENDPOINT HELD |
| SUP-002 | Progressive onboarding/review cases for identity, licences, tax, bank/payout, service area, category and operational capacity; registration alone activates nothing. | SUP-001 + identity/document providers | BLOCKED |
| SUP-003 | Canonical product -> verified pack -> participant offer contracts with stable IDs, product-master stewardship, barcode/code matching, duplicate/merge/dispute workflow and effective-dated offer terms. | SUP-001 + catalogue governance owner | TECHNICALLY QUALIFIED — LOCAL CONTRACT; PERSISTENCE/ENDPOINT HELD |
| SUP-004 | Inventory/reservation and serviceability quote: node, PIN/geography, pack/quantity, stock, lead time, cut-off, delivery/collection, landed price, reliability and category handling. Stale/partial/unavailable truth is explicit. | SUP-003 + inventory/logistics owners | BLOCKED |
| SUP-005 | Seller-specific retail orders and wholesale POs with stock/price/term revalidation, idempotent commitment, fulfilment/returns/payment/tax event bridges. Retail and wholesale baskets never merge. | SUP-004 + order/payment/TAX | BLOCKED |
| SUP-006 | Workspace projections for catalogue, stock, orders, procurement, invoices and books that reuse QA-008–QA-017 interaction contracts and never create client ledgers. | SUP-002-005 + founder HTML/native review | BLOCKED |
| SUP-007 | Capability rollout and support runbook by PIN/category, with kill switch, fraud/quality thresholds, seller SLA, dispute/return ownership and reconciliation. | SUP-001-006 | BLOCKED |

## Nearby store, pharmacy, wholesaler and factory discovery

| Ticket | Deliverable and acceptance | Dependency | State |
| --- | --- | --- | --- |
| DISC-001 | Service-area model using declared/verified fulfilment zones and destination PIN; precise location is optional and consented. Do not infer `nearby` from seller text or a seeded city string. | SUP-001/004 | PROPOSED |
| DISC-002 | Query normalization and typo-tolerant matching reuse the approved R57 search contract across product, participant type, name, category, brand, code and locality. Exact matches lead; near matches are labelled, deterministic and non-personalized. | canonical indexes + R57 | PROPOSED |
| DISC-003 | Explainable ranking: serviceable first, then exact/near relevance, capability/category eligibility, delivered/landed price, promise and reliability. Sponsored placement is disclosed and cannot falsify organic rank or `lowest`. | DISC-001/002 + offer quote | BLOCKED |
| DISC-004 | Privacy/permission contract for PIN, coarse area and optional current location; no background tracking, contact import or precise-location requirement for ordinary discovery. | privacy approval | PROPOSED |
| DISC-005 | Regulated-category trust facts: licensed pharmacy/food/other required capability, verification freshness and fail-closed unavailable state; no clinical or authenticity inference from distance. | SUP-002 + regulatory provider | BLOCKED |
| DISC-006 | Founder-reviewed discovery UI for list/map choice, filters, empty/stale/retry, seller comparison and exact return to product/context; 320 px/140%, reduced motion and OPPO qualification. | DISC-001-005 + HTML approval | BLOCKED |

## Recommended production sequence

1. Decide TAX-001, PAY-001, B2B-001 and AIA-001; approve, reject or amend
   ADR-0010/0011/0012.
2. Verify PAY-002 without putting credentials in the repository. Implement
   server contracts SUP-001 and SUP-003 plus B2B-002 and TAX-002/003 in local
   deterministic tests only.
3. Establish inventory/serviceability SUP-004 and location DISC-001 before
   any `nearby`, stock or delivery claim.
4. Establish the production order/payment event owners, PAY-003 and B2B-003-006,
   then TAX-004/006 and seller-specific SUP-005.
5. Prove PhonePe PAY-004/005 and IRP sandboxes by separate authorization; then
   build reconciliation, invoice and supply projections against founder-reviewed
   UI. Add another payment provider only through PAY-011.
6. Qualify wholesale delivery, payment terms and settlement through B2B-007-009
   plus PAY-007/008/010 before any wholesale production promise.
7. Build AI consent/context/tools only after authoritative catalogue,
   serviceability and invoice/payment boundaries exist. AI is never on the
   critical path for core Buy.

## Common qualification gate

Every implemented ticket requires a unique candidate/evidence identity, exact
source manifest, threat and data-egress review, authorization/tenant/idempotency
tests, invalid/empty/duplicate/cancel/offline/retry lifecycle, audit events,
two unchanged-source affected regressions, accessibility/responsive proof and
environment-specific promotion decision. No deterministic fixture may be
presented as a live government, payment, seller, pharmacy, provider, stock,
delivery, tax or AI result.

Every ticket that changes customer UI or runtime motion must apply
`config/buy-premium-motion-policy.json` before its first runtime write and
record applied, reused, dependency-held and inapplicable effects. It must
qualify immediate/static reduced motion and the applicable responsive/OPPO
journey. Server-only contracts must explicitly record motion/device evidence
as inapplicable; they must not invent a UI merely to satisfy the gate.
