# ADR-0012: Payment orchestration and consumer/wholesale boundary

Status: **Founder dual collection model selected — finance, legal and provider evidence still required**

Date: 3 August 2026

Founder amendment, 4 August 2026: collection, settlement, refund/dispute and
invoice ownership follow the exact effective-dated platform/agent or
SuperMandi purchase/resale assignment. No order may change model after
commitment. Exact authority and remaining PhonePe/finance/legal gates are in
`artifacts/quality/production-foundation-founder-decisions-20260804-153`.

## Context

MoolSocial needs consumer and wholesale payment collection using PhonePe under
the legal merchant identity SuperMandi Tech Pvt Ltd, with the option to add
other approved payment aggregators later. The founder reports completed KYC and
partnership work. Production credentials and capabilities have not been
verified in the repository and must not be inferred.

Consumer FMCG checkout and wholesale procurement also have different pack,
quantity, price, purchase-order, delivery and payment-term contracts. Treating
wholesale as a larger consumer Cart would make commitments, tax, settlement and
recovery ambiguous.

## Decision proposed

### 1. Provider credentials and payment truth are server owned

- SuperMandi's approved backend creates provider authorization, payment orders,
  status checks, refunds and webhook verification. No provider secret or raw
  payment credential enters Flutter or source control.
- The mobile client can request a payment intent, launch an approved checkout
  handoff and ask for current status. A return URL, SDK callback or screenshot
  never marks an order paid.
- The authoritative outcome is a reconciled server state derived from
  authenticated provider events/status and finance settlement evidence.

### 2. One idempotent attempt identity per provider submission

Every attempt records stable internal intent/attempt IDs, merchant order ID,
provider order/transaction IDs when known, merchant/legal entity, buyer and
workspace, seller-order or wholesale-PO obligation, currency, amount, expiry,
method class, provider, environment, idempotency key and append-only state
events. Repeated taps reuse or read the same valid attempt. They do not create a
new debit while an earlier attempt is pending or unknown.

Provider failover can occur only as a newly authorized attempt after the prior
attempt is definitively terminal or finance/support owns the exception. It is
never a transparent retry after an unknown debit.

### 3. Consumer payment policy is explicit

Consumer checkout exposes only provider-enabled methods allowed for the exact
merchant, category, amount and order. Hosted/standard checkout is preferred for
the first PhonePe integration. Actual card data is never stored. Pay-on-delivery
or any promotional offer is unavailable unless its own owner and evidence
authorize it.

### 4. Wholesale payment and commercial terms are separate

- A wholesale offer snapshots verified pack/loading unit, sale multiple, MOQ,
  tier pricing, taxes, freight/unloading/deposit, validity, lead time, delivery
  responsibility, return/damage terms and payment policy.
- Wholesale uses a distinct basket and purchase order. It does not merge with
  the consumer Cart or inherit consumer payment-method availability.
- Supported policies may include immediate gateway payment, verified bank
  transfer, deposit/balance and approved invoice terms. Each has explicit
  authorization, due, matching, hold/release and exception states.
- Buyer credit, pay-later or financing is never fabricated by MoolSocial. It
  requires approved underwriting/counterparty policy and, where relevant, a
  separately contracted regulated lender.

### 5. Settlement and accounting are first-class

Payment success, order acceptance, invoice issue, provider settlement, seller
payable, refund, reversal, dispute and bank reconciliation are distinct events.
Append-only ledgers record gross amount, provider fee, tax on fee, reserve/hold,
net settlement, seller payable and unmatched exceptions. TAX-001 decides the
merchant/collector/TCS owner per supply family before this contract is built.

### 6. Provider abstraction follows a proven first adapter

The domain contract is provider-neutral, but PhonePe is the first proposed
adapter. A secondary provider is added only after sandbox evidence proves the
common state and reconciliation model. The UI never claims automatic failover,
best success rate or method availability without authoritative capability data.

## Consequences

- Current Flutter payment choices remain deterministic review UI and cannot be
  described as a live gateway.
- PhonePe backend/sandbox implementation is blocked until merchant evidence,
  TAX-001, backend authorization and secure secret/endpoint ownership exist.
- Wholesale pack/offer and PO work can proceed as deterministic contracts after
  founder approval, without making a payment-provider call.
- Every implementation needs idempotency, duplicate/out-of-order webhook,
  offline/return/process-death, unknown-outcome, refund, reconciliation,
  authorization, data-egress and audit tests.

## Rejected alternatives

- Embedding PhonePe client credentials or payment success logic in Flutter.
- Marking an order paid from a redirect, app callback or locally selected method.
- Treating completed KYC as proof that every production capability is enabled.
- Storing card details to accelerate repeat checkout.
- Merging consumer and wholesale baskets, prices, terms or payment policies.
- Retrying another provider automatically while the first debit is unknown.
- Presenting MoolSocial-created credit terms as approved lending.

## Required approval

Founder, finance and legal must approve the merchant/collector/settlement model,
the first wholesale payment policy and the evidence registry. Backend/security
must separately authorize sandbox credentials and endpoints. This ADR does not
authorize live payment, credential access, provider calls, deployment or funds
movement.
