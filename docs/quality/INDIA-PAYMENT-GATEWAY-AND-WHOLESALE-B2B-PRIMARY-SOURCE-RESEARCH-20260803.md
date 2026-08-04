# India payment-gateway and wholesale B2B primary-source research

Prepared: 3 August 2026

State: **primary-source planning research; not legal advice, provider activation,
credential authorization or a production-payment approval**

## Question being answered

SuperMandi Tech Pvt Ltd intends to accept payment for MoolSocial consumer and
wholesale purchases through PhonePe and, later, other approved providers. The
founder reports that KYC and partnership work has already been completed. The
repository does not yet contain sufficient non-secret activation evidence to
assert that a particular merchant account, payment method, settlement account
or production API is enabled.

The implementation therefore needs two distinct contracts:

1. payment orchestration, provider status, refunds and settlement; and
2. wholesale offer, pack, purchase-order, delivery and commercial terms.

Neither contract may be inferred from the current deterministic Flutter demo.

## Confirmed primary-source findings

### RBI payment-aggregator boundary

- RBI's payment-aggregator/payment-gateway framework distinguishes aggregators
  that handle funds from technology gateway providers and establishes merchant
  onboarding, settlement and escrow duties for regulated payment aggregators.
  RBI's later escrow-direction amendment expressly refers back to the
  17 March 2020 PA/PG guidelines and the PA escrow account. Source:
  [RBI — Maintenance of Escrow Account with a Scheduled Commercial Bank](https://www.rbi.org.in/scripts/NotificationUser.aspx?Id=11996).
- MoolSocial should integrate an authorized payment aggregator/acquiring
  arrangement. It must not itself pool or hold customer funds as a payment
  aggregator merely because the app coordinates an order. Any marketplace
  collection or split-settlement model requires the exact provider contract,
  TAX-001 operating decision and finance/legal review.
- RBI's card-on-file direction says actual card data must not be stored by an
  entity in the card transaction/payment chain other than the issuer or card
  network. Source:
  [RBI — Restriction on Storage of Actual Card Data](https://www.rbi.org.in/scripts/NotificationUser.aspx?Id=12345).
  MoolSocial must never persist PAN, CVV or equivalent raw card credentials.

### UPI and B2B category

- NPCI's UPI merchant guidance describes merchant participation through an
  acquiring bank and modes including QR, Intent, application and Collect.
  Source: [NPCI — UPI FAQs](https://www.npci.org.in/what-we-do/upi/faqs).
- NPCI introduced B2B as a separate UPI merchant-ecosystem category. That does
  not make every wholesale order eligible for every UPI flow or amount; actual
  enablement, limits, MCC/category and acquiring-bank/provider rules remain
  authoritative. Source:
  [NPCI circular OC 96 — Introduction of B2B as a Separate Category](https://www.npci.org.in/PDF/npci/upi/circular/2020/OC-96_UPI_Merchant_Ecosystem_Enhancements_and_Introduction_of_B2B_as_Seperate_Category.pdf).

### PhonePe integration facts

- PhonePe's business site states that PhonePe Limited is an RBI-authorized
  Payment Aggregator and advertises UPI, card, net-banking and wallet support.
  It describes Standard Checkout as a hosted option and provides transaction,
  settlement and refund reporting. Source:
  [PhonePe Payment Gateway](https://business.phonepe.com/payment-gateway).
- PhonePe Standard Checkout uses a server authorization token created from a
  client ID, client version and client secret obtained from the business
  dashboard. Sandbox and production endpoints are distinct. Source:
  [PhonePe — Generate Authorization Token](https://developer.phonepe.com/payment-gateway/website-integration/standard-checkout/api-integration/api-reference/authorization).
  The secret must stay in an approved server-side secret store; it must never be
  embedded in Flutter, source control, logs, screenshots or evidence.
- Payment creation has a merchant order identity and an amount in paise; an
  initiation response is not proof of successful collection. Source:
  [PhonePe — Initiate Payment](https://developer.phonepe.com/payment-gateway/website-integration/standard-checkout/api-integration/api-reference/create-payment/initiate-payment).
- Backend order-status checks and authenticated, idempotent webhook processing
  are both required. An app return/deep link can only trigger a pending/status
  refresh; it cannot mark an order paid. Sources:
  [PhonePe — Order Status](https://developer.phonepe.com/payment-gateway/website-integration/standard-checkout/api-integration/api-reference/order-status) and
  [PhonePe — Webhook Handling](https://developer.phonepe.com/payment-gateway/website-integration/standard-checkout/api-integration/api-reference/webhook).

## Architecture implications

### Consumer FMCG

- A server creates one idempotent payment intent against a final, revalidated
  payable order snapshot. Flutter receives only a short-lived checkout handoff
  and public status—not provider credentials.
- Show only methods enabled for the exact SuperMandi merchant account, order
  channel, amount and provider capability. Do not advertise wallets, cards,
  net banking, UPI, pay-on-delivery or offers from marketing-page availability.
- Keep `created`, `pending`, `authorized` where applicable, `paid`, `failed`,
  `expired`, `cancelled`, `refund_pending`, `refunded`, `disputed` and
  `unknown_reconcile` as explicit server-owned states. Unknown never becomes
  failure merely so the user can be charged again.
- Refund, reversal, dispute, provider fee, tax on fee, settlement and bank
  reconciliation are append-only financial events tied to the attempt and
  order. The visible checkout result is a projection of that truth.

### Wholesale B2B

- Wholesale uses the same canonical product identity but separate verified
  packs and offers: each/inner/case/pallet or weight/volume unit, sale multiple,
  loading quantity, dimensions/weight, MOQ, quantity-price breaks, validity,
  lead time, cut-off, GST/cess treatment, freight, unloading/deposit, batch or
  expiry requirements, returns/damage terms and delivery responsibility.
- A wholesale basket and purchase order never merge with the consumer Cart.
  The purchase order snapshots the accepted offer and commercial terms before
  it is committed.
- Wholesale payment policy may allow immediate provider checkout, verified bank
  transfer, deposit/balance or invoice terms. These are business-policy outcomes,
  not interchangeable UI labels. PO approval, payment authorization, provider
  success, bank settlement, invoice issue, dispatch, proof of delivery and goods
  receipt remain separate events.
- Credit limits or pay-later terms require an approved counterparty policy and,
  if lending/financing is involved, an appropriately regulated lending partner
  and separate legal review. MoolSocial must not invent a credit entitlement,
  interest rate, due date, approval or lender fact.

## Evidence needed before PhonePe sandbox or production work

The founder/finance owner must provide or verify through a secure channel:

- exact legal merchant name and merchant/account ID for SuperMandi Tech Pvt Ltd;
- confirmation of whether SuperMandi is seller/merchant of record, marketplace
  collector, agent or another role for each launch supply family;
- enabled environment, products, payment methods, MCC/category and amount rules;
- authorized web/app origins, package/bundle identifiers and redirect/webhook
  endpoints;
- non-secret credential ownership and vault path, without placing secrets in
  repository evidence;
- settlement bank account ownership, schedule, fees/taxes, reserves/holds and
  reconciliation export access;
- refund, reversal, dispute/chargeback, support and escalation terms;
- whether the signed agreement supports marketplace/seller settlement, consumer
  commerce, wholesale B2B and regulated categories such as pharmacy;
- PhonePe UAT/go-live checklist and named provider contact; and
- the approved secondary-provider strategy, if any.

Completed KYC is useful evidence but is not by itself proof of production API,
method, MCC, regulated-category, settlement or marketplace capability.

## Founder decisions required

1. Approve, amend or reject ADR-0012.
2. Name the merchant/collector/settlement owner for each retail and wholesale
   supply family consistently with TAX-001.
3. Confirm which PhonePe account and contract evidence finance may register
   without copying credentials into the repository.
4. Choose initial wholesale payment policies: immediate payment only, approved
   bank transfer, deposit/balance, invoice terms, or a constrained combination.
5. Approve the first B2B pack/offer pilot categories and participants.

