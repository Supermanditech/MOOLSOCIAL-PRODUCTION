# ADR-0011: Paid AI shopping agent consent boundary

Status: **FOUNDER LAUNCH/PERMISSION MODEL SELECTED — privacy, safety and commercial price approval still required**

Prepared: 3 August 2026

Founder amendment, 4 August 2026: the optional agent is in launch scope. Under
an explicit bounded/revocable permission it may mutate Cart and place the
specific authorized order, while the user alone owns OTP, UPI PIN, bank and
other payment authentication. The earlier blanket prohibition on order
placement is superseded only to that bounded extent. Exact authority and
remaining price/privacy/safety gates are in
`artifacts/quality/production-foundation-founder-decisions-20260804-153`.

## Context

MoolSocial may offer a paid shopping assistant that helps a person discover
and compare products or build a reviewable basket. The current Buy surface has
truthful deterministic search, seller offers and user-owned Cart mutation. It
has no production model provider, AI entitlement, consent ledger, tool policy,
retrieval provenance, quality evaluation or paid-service invoice owner.

An AI assistant must not infer entitlements, health needs, prescriptions,
creditworthiness, wholesale eligibility or seller facts. It must not become a
second order, payment, catalogue or invoice authority.

## Proposed decision

1. The assistant is an optional, separately priced MoolSocial service. Plan,
   price, billing interval, trial/grant, limits and tax invoice owner are
   explicit before purchase and follow ADR-0005.
2. Every session has purpose-bound consent. The user chooses what may be used:
   current query and Buy context by default; optional Cart, Saved products,
   past orders, location/service PIN or business workspace only through
   separate visible grants. Contacts, private Chat, prescriptions, health
   records and unrelated Social data are denied by default.
3. Consent is revocable and versioned. Revocation stops new use immediately;
   retention/deletion behavior and any legal exception are disclosed.
4. The model sees a minimal server-prepared context envelope with field-level
   provenance and expiry. Raw credentials, payment instruments, full GST
   evidence, private provider tokens and unrestricted databases never enter a
   model prompt.
5. The assistant retrieves only canonical products, eligible offers and
   serviceability facts returned by authoritative tools. Every price, stock,
   seller, delivery, MOQ, tax and promotion claim carries a source record and
   freshness timestamp. Missing/stale facts are stated as unknown.
6. The assistant may propose filters, comparisons and a draft basket. It may
   mutate the real Cart only after an explicit reviewable user confirmation.
   It cannot place an order, accept trade terms, upload a prescription, change
   an address, authorize payment or submit tax identity.
7. Medicine and regulated-category guidance is limited to discovery and
   product facts. No diagnosis, dosing recommendation, prescription approval
   or substitution is generated. Licensed provider workflows remain
   authoritative.
8. Model/provider identity, prompt/tool-policy version, consent version,
   retrieved record IDs, citations, tool results, safety decision, user
   confirmation and cost are audit events. Sensitive prompt content is
   minimized and retained only under an approved policy.
9. A deterministic fallback preserves normal Buy search and checkout when AI
   is unavailable, denied, out of entitlement or unsafe. Paid access never
   degrades core catalogue access or worker access.

## Quality and launch gates

- Threat model and data-protection impact assessment.
- Provider data-use, residency, retention and no-training configuration proof.
- Prompt-injection, data-exfiltration, cross-tenant, unsafe medicine,
  fabricated offer and unauthorized-tool test suites.
- Grounded answer and citation evaluations across Indian languages, typo
  tolerance, compact UI, reduced motion and accessibility.
- Hard per-session/tool/token cost budgets, rate limits and abuse controls.
- Deterministic no-AI parity and provider outage recovery.
- Founder-reviewed HTML before Flutter, certified payment sandbox before paid
  activation, and separate Dev/Staging/Production promotion decisions.

## Explicitly deferred

No provider integration, paid entitlement, customer AI UI, autonomous order,
personalization model, prescription use, external message, campaign action,
credential or production data egress is authorized by this proposal.
