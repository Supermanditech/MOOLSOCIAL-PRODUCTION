# Buy MVP ready-order-to-delivery end-to-end journey ticket

Prepared: 5 August 2026
State: **PARENT JOURNEY PLANNING COMPLETE — PREAUTHORIZED — NOT EXECUTING**
Parent ticket:
`BUY-MVP-READY-ORDER-TO-DELIVERY-END-TO-END-JOURNEY`
Child portfolio: `BUY-MVP-READY-ORDER-DELIVERY-PORTFOLIO-20260805`
Child manifest SHA-256:
`5CE81AB6332607A71B960C57A1E99466109E13299CD8A5995FFC3163F35893AF`

## Ticket hierarchy correction

This is the complete parent acceptance ticket. It owns the connected journeys
from customer product choice through terminal delivery or accountable recovery.
The 47 production-grade portfolio tickets are bounded child execution units of
this parent.

`BUY-MVP-ADMIN-ACCEPTANCE-SLA-POLICY` is Child Ticket 1. It owns only the
bounded Admin timing-policy foundation and the relevant part of Journey 9. It
does not, by itself, own Journeys 1–8 and must never be presented as the full
end-to-end ticket.

## Parent customer outcome

A customer can make a ready decision, place an exact product order, pay once,
have that same order assigned through a bounded sequence of eligible full
fulfilment partners, receive authoritative packing and delivery progress, and
reach either verified delivery or one accountable recovery/refund outcome.

The launch families are Shop, Wholesale and Medicine. Generic services, Eat,
Ride, salons, doctor booking and appointment reservations are outside this
ticket.

## Founder exact provider-type binding — 5 August 2026

Latest authority:
`docs/delivery/MVP-FOUNDER-ACTION-PROVIDER-SURFACE-DIRECTIVE-20260805.md`.

The Buy journey is complete only when its common actions resolve to the exact
workspace type below. A generic `provider`, `partner`, `seller`, `merchant` or
`captain` label cannot execute a child ticket by itself.

| Buy family | Exact customer/approver | Exact seller/fulfiller | Exact delivery owner |
| --- | --- | --- | --- |
| Shop | Personal user | Grocery / Kirana Shop, or General Retail Shop / Dukaan enabled for every exact ordered category | Accepted shop-owned delivery capability or Delivery Partner |
| Wholesale | Authorized buyer in an eligible verified business workspace | FMCG Supplier / Distributor; separately enabled bounded FMCG Manufacturer pilot only where every pack and term is approved | Delivery Partner for an eligible parcel load or Local Porter / Goods Transporter for an enabled Wholesale-load capability |
| Medicine | Personal user following the applicable non-prescription or secure prescription path | Medical Store / Pharmacy with current licence, service area, exact medicine/pack capability and pharmacist authority where required | Pharmacy-owned regulated delivery capability or Delivery Partner enabled for the exact medicine-handling class |

The actor binding covers readiness, complete-basket eligibility, timer policy,
MoolChat decision, separately approved WhatsApp/agentic escalation,
Accept/Decline, timeout/reassignment, stock or commercial-term commitment,
packing, verified handover, delivery, payment/settlement, support and terminal
recovery. Every actor receives exact workspace wording, permissions, regulatory
gates and failure behavior.

This binding refines the already preauthorized 47-child portfolio without
changing its child manifest or activating execution. Before a child executes,
its disclosure must name the one exact actor/capability instance that owns the
write and the applicable family-specific failure path.

## Exact operating promise

`fresh ready decision -> Cart -> exact payable review -> protected payment ->
bounded partner acceptance -> acceptance-time stock commitment -> packing ->
verified handover -> delivery tracking/proof -> delivery or accountable
recovery`

There is no pre-payment inventory reservation. A readiness result is fresh and
expiring, but it is not a stock hold. Stock becomes committed only when one
eligible provider authoritatively accepts the exact order.

MoolSocial cannot truthfully guarantee that every physical parcel will always
arrive despite accidents, fraud, stock loss, weather or lawful intervention. It
does guarantee bounded waiting, one order/payment identity, accountable
ownership, explicit failure and a terminal delivery, recovery, refund or
support state.

## Journey 1 — common customer journey

The functional labels below are behavioral requirements. Exact presentation
copy and layout remain subject to their applicable reference gates.

1. Customer opens **Buy**.
2. Customer selects **Shop**, **Wholesale** or **Medicine**.
3. Customer browses, searches or opens an eligible product result.
4. Customer opens product detail.
5. Customer selects the exact quantity or governed pack.
6. Customer taps **Add to Cart**.
7. Customer may continue shopping without any stock being reserved.
8. Customer taps **View Cart**.
9. Cart shows exact lines, quantities, family and any permitted substitution
   choice.
10. Customer taps **Continue to checkout**.
11. Customer selects or adds the destination and an available delivery or
    collection method.
12. MoolSocial performs a fresh readiness check across eligible providers.
13. Only a provider able to fulfil the complete exact basket is eligible for
    automatic assignment. Partial or mixed-family fulfilment is not silently
    created.
14. If no complete fulfiller exists, the customer receives an explicit
    unavailable/edit-Cart result before payment is presented as available.
15. Customer reviews the exact payable decision:
    - products, packs and quantities;
    - tax, delivery and other approved components;
    - delivery or collection promise;
    - substitution decision where permitted; and
    - notice that MoolSocial will confirm one eligible provider after payment.
16. Customer taps **Pay securely**.
17. Customer completes the approved provider flow.
18. MoolSocial waits for authoritative server payment truth. A client callback
    cannot create paid status.
19. Cancelled payment returns to the preserved Cart. Unknown payment status
    enters reconciliation and cannot create another debit.
20. When payment is in the verified protected state needed for assignment, the
    customer sees **Payment protected — finding your provider**.
21. The assignment state shows the current attempt, countdown, overall ceiling
    and customer-safe progress.
22. If the provider accepts, the screen becomes **Order accepted by [provider]**
    with the authoritative fulfilment promise.
23. If the provider declines or expires, the same order changes to **Finding
    the next eligible provider** without another payment.
24. After acceptance, the customer sees authoritative **Packing**, **Ready for
    handover**, **Out for delivery** and **Delivered** states.
25. Customer can open **Get help** from every nonterminal or failed state.
26. App close, Back, refresh, process death and phone restart restore the same
    server-owned order and payment state; they never fabricate success or start
    a duplicate order.

## Journey 2 — provider escalation and automatic reassignment

Each order freezes one policy version. Later Admin edits cannot change its
attempt window, attempt limit or overall ceiling.

| Family | Per-provider window | MoolChat | WhatsApp | Agentic call | Reassign | Launch ceiling |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Shop | 60 sec | 0 sec | 20 sec | 40 sec | 60 sec | 3 partners / 180 sec |
| Wholesale | 180 sec | 0 sec | 60 sec | 120 sec | 180 sec | 3 partners / 540 sec |
| Medicine — non-prescription | 90 sec | 0 sec | 30 sec | 60 sec | 90 sec | 3 pharmacies / 270 sec |
| Medicine — prescription after pharmacist-ready | 300 sec | 0 sec | 100 sec | 200 sec | 300 sec | 2 pharmacies / 600 sec |

For each attempt:

1. The nearest eligible full fulfiller receives the MoolChat order alert at
   time zero.
2. Eligibility is decided before distance: exact basket, category/capability,
   licence where applicable, destination, approved price/terms and operating
   readiness must all pass.
3. If no decision exists at one-third of the window, the consented verified
   business WhatsApp number receives one minimal notification.
4. The WhatsApp action opens the authenticated MoolSocial order. WhatsApp is
   not the order, payment or clinical authority.
5. If no decision exists at two-thirds, a bounded agentic call goes to the
   verified business number.
6. The call asks only **Accept** or **Decline**. It cannot negotiate price,
   authenticate payment, provide clinical advice or expose prescription data.
7. Ambiguous speech, silence, wrong party or no answer cannot create
   acceptance.
8. An explicit decline immediately advances to the next eligible partner.
9. At expiry, the provider's attempt closes and a late acceptance is rejected.
10. The same customer order and payable identity advance to the next eligible
    full fulfiller. No second debit is created.
11. The sequence ends at the first valid acceptance, eligible-ladder
    exhaustion, quote expiry, attempt limit or order-level ceiling—whichever
    occurs first.

Live WhatsApp and live telephony remain independently held until consent,
provider, legal, privacy, security, cost, credential and environment gates
pass. Their absence cannot stop the core MoolChat plus timeout/reassignment
path.

## Journey 3 — Shop

1. Customer selects ordinary retail products and quantities.
2. Cart remains one consumer basket; Wholesale and Medicine commitments do not
   silently merge into it.
3. Readiness requires one Shop partner able to fulfil the complete exact
   basket.
4. Customer reviews one exact payable total and delivery promise.
5. Customer may give narrowly defined substitution consent for permitted Shop
   products.
6. Customer pays once and enters bounded assignment.
7. On provider acceptance, every line is revalidated and stock commits
   atomically.
8. If stock changed before acceptance, the provider cannot accept that basket;
   the same order advances to the next eligible Shop.
9. An alternative product, higher price, changed allergen-sensitive item,
   split order or changed delivery term requires explicit customer review; it
   is never silently applied.
10. The accepted Shop packs every exact line and hands one parcel into the
    delivery journey.

## Journey 4 — Wholesale

1. A verified business user enters the Wholesale workspace.
2. The preparer selects exact each/inner/case/pallet or weight/volume pack,
   quantity and governed sale/loading multiple.
3. Cart validates pack multiple, MOQ and quantity-price tier.
4. Checkout displays exact taxable/landed components, freight,
   unloading/deposit, delivery responsibility, return/damage and payment
   policy.
5. If workspace policy requires approval, the preparer taps **Submit for
   approval**.
6. The authorized buyer approver opens **Pending approvals**.
7. Approver reviews the immutable commercial snapshot and taps **Approve and
   continue** or **Reject**.
8. Payment or separately approved payment terms apply only after buyer
   authority is verified.
9. Supplier assignment starts with the snapshotted 180-second launch window.
10. Automatic supplier reassignment is permitted only when every approved
    commercial term remains exact.
11. A changed supplier price, MOQ, tier, tax reference, freight, destination,
    promise or payment term stops automatic reassignment and returns a new
    decision to the authorized buyer.
12. Personal-account membership cannot authorize or modify the Wholesale PO.

## Journey 5 — Medicine

### Non-prescription Medicine

1. Customer selects the exact medicine identity and pack.
2. Readiness checks only currently eligible licensed pharmacies able to fulfil
   the complete exact order.
3. Customer reviews quantity, payable total and delivery promise.
4. Customer pays once and enters the 90-second pharmacy-assignment sequence.
5. The accepting pharmacy revalidates and commits exact stock.
6. AI, automatic failover and distance ranking cannot change medicine name,
   strength, dosage form, pack or quantity.

### Prescription Medicine

1. Customer follows the separately approved secure prescription journey.
2. Prescription information is accessible only to authorized pharmacy and
   pharmacist roles for the approved purpose.
3. The 300-second acceptance timer begins only after pharmacist-ready review.
4. An eligible licensed pharmacy receives a generic actionable notification.
5. Prescription content is not sent through WhatsApp or spoken by the agentic
   call.
6. If the pharmacy declines or expires, only the minimum secure prescription
   context moves to the next eligible licensed pharmacy.
7. The next pharmacy performs its own required acceptance/review; approval is
   not silently transferred.
8. No automatic therapeutic, strength, dosage-form, pack or quantity
   substitution is allowed.
9. If lawful exact fulfilment cannot complete, the customer receives an
   explicit unavailable, refund and support outcome.

Live prescription execution remains held until clinical, regulatory, consent,
privacy and secure-handoff ownership pass.

## Journey 6 — provider workspace

1. Authorized provider signs in to the correct business workspace.
2. Provider selects **Ready**, **Busy** or **Paused** for new demand.
3. Paused or ineligible providers receive no new order attempt.
4. Readiness is never inferred from contacts, other apps, personal messages,
   background location, microphone use or unrelated phone activity.
5. Provider receives **New order awaiting decision** in MoolChat.
6. Provider taps **View order**.
7. Provider sees complete exact lines, quantity/pack, accountable payable
   ownership, fulfilment method, packing expectation and remaining time.
8. Provider taps **Accept complete order** or **Decline**.
9. Accept triggers server authorization, attempt-expiry, exact-stock and
   command-idempotency checks.
10. Successful acceptance atomically commits stock and assigns the provider.
11. Failed validation shows an explicit expired, conflict or unavailable
    result; it cannot assign the provider.
12. Accepted provider taps **Start packing**.
13. Provider confirms every exact line and quantity.
14. Provider taps **Packing complete**, then **Ready for handover**.
15. Provider verifies delivery-owner identity and the handover OTP.
16. Provider separately confirms physical parcel handover. OTP alone is not
    proof that custody physically changed.

## Journey 7 — delivery and proof

1. A packed order is assigned once to an eligible own-delivery capability or
   verified delivery partner.
2. The delivery owner accepts the exact pickup task.
3. Captain opens pickup details and reaches the provider.
4. Provider verifies captain identity and the correct unexpired OTP.
5. Parcel custody changes only after separate physical handover confirmation.
6. Customer sees authoritative owner, committed promise and delivery events.
7. Out-of-order, stale or missing events are shown as such; they do not drive a
   decorative fake map or inferred location.
8. Delivery completion requires authoritative proof under the approved
   delivery contract.
9. Customer sees **Delivered** and can open the receipt/proof.
10. Customer can tap **Get help** for missing, damaged, incorrect or disputed
    delivery.

## Journey 8 — failure, refund and support recovery

| Failure | Required customer-visible outcome |
| --- | --- |
| No complete fulfiller before payment | Do not present pay as available; offer Cart edit or explicit unavailable exit. |
| Readiness/quote changed | Show exact change and require a new customer decision. |
| Payment cancelled | Preserve Cart; create no assignment or debit. |
| Payment unknown | Pause and reconcile; do not invite a second debit. |
| Provider declines | Immediately advance the same order to the next eligible provider. |
| Provider expires | Reject late acceptance and advance safely. |
| Stock fails at acceptance | Do not assign or fabricate stock; advance or terminate. |
| All attempts/ceiling exhausted | Release/void when supported or start one authoritative refund; show pending truth. |
| Accepted seller fails before irreversible packing | Release its stock commitment and reopen only the safe same-order ladder. |
| Failure after parcel pickup | Enter logistics recovery; do not create a duplicate seller order. |
| Delivery owner fails | Reassign delivery only when custody and proof permit; otherwise recover/return/support. |
| Parcel lost or damaged | Open one accountable case with delivery, seller, refund/replacement and evidence owners. |
| Changed Shop substitution | Require explicit customer consent. |
| Changed Wholesale term | Require authorized buyer reapproval. |
| Medicine mismatch | Fail closed; never perform automatic clinical substitution. |
| App/process interruption | Restore authoritative server state with no local success fabrication. |

An unrecoverable journey ends with one support case and authoritative refund,
replacement or other separately approved remedy. Locally displayed success can
never replace provider/finance truth.

## Journey 9 — Admin policy and operational control

### Acceptance policy

1. Authorized Admin opens **Commerce**.
2. Admin selects **Order acceptance policy**.
3. Authorization and tenant checks occur before policy existence or values are
   retrieved.
4. Admin selects Shop, Wholesale, non-prescription Medicine or prescription
   Medicine after pharmacist-ready review.
5. Admin sets a whole-second provider window from 30 to 300 seconds.
6. Admin sets one to five sequential partner attempts.
7. The overall ceiling is derived without truncating the final provider
   attempt.
8. Admin reviews the MoolChat, WhatsApp, call and reassignment instants.
9. Admin chooses a non-backdated effective time and records the reason.
10. Admin reviews before/after values and confirms the future-order-only effect.
11. Admin publishes one immutable version.
12. Active orders keep their snapshotted version.

### Market and busy-schedule control

1. After the global policy exists, Admin may create a more specific future
   override for approved market type, provider type, category, locality,
   weekday/time band or declared busy schedule.
2. Admin sees deterministic precedence and overlap warnings before publishing.
3. The effective policy is resolved server-side and frozen into a later order
   snapshot.

### Audit, rollback and recommendations

1. Admin can inspect immutable policy history and exact affected scope.
2. Authorized rollback creates a new revision; it never deletes or rewrites
   history.
3. Aggregate operational evidence may show acknowledgement, acceptance,
   timeout and workload outcomes by policy scope.
4. The system may recommend a bounded policy change with its sample and reason.
5. Admin must review and explicitly publish it. No model or background job may
   autonomously change Production.
6. Unrelated phone activity and private content are never inputs.

The detailed Child Ticket 1 Admin journey is recorded in
`docs/delivery/BUY-MVP-ADMIN-ACCEPTANCE-SLA-POLICY-TICKET-20260805.md`.

## Cross-journey production rules

- authorize tenant, workspace and capability before existence or business-data
  lookup;
- use stable order, payment, offer, provider, policy and audit identities;
- make unknown, stale, ambiguous, partial, denied and unavailable explicit;
- use exact decimals/minor units and append-only business events;
- make every state-changing command idempotent;
- reconcile unknown payment, messaging and provider outcomes before retry;
- never create payment, acceptance, stock, licence, clinical, custody or
  delivery truth from a client callback, countdown or AI response;
- never silently change price, terms, product, medicine, provider ownership or
  customer consent;
- protect Back, refresh, offline, process-death, retry and duplicate paths;
- provide keyboard, screen-reader, reduced-motion and responsive behavior for
  every later accepted presentation; and
- preserve protected R58.8.8 FIX7 until an exact successor passes its retained
  gates.

## Parent-to-child execution traceability

| # | Child execution ticket | Parent journeys |
| ---: | --- | --- |
| 1 | `BUY-MVP-ADMIN-ACCEPTANCE-SLA-POLICY` | 2, 9 |
| 2 | `BUY-MVP-MARKET-SCHEDULE-TIMER-OVERRIDES` | 9 |
| 3 | `BUY-MVP-ORDER-TIMER-POLICY-SNAPSHOT` | 1, 2, 9 |
| 4 | `BUY-MVP-PROVIDER-READY-BUSY-PAUSE-STATE` | 2, 6, 9 |
| 5 | `BUY-MVP-ACCEPTANCE-POLICY-AUDIT-ROLLBACK` | 9 |
| 6 | `BUY-MVP-NO-RESERVATION-OFFER-READINESS` | 1, 3, 4, 5 |
| 7 | `BUY-MVP-FULL-BASKET-FULFILLABILITY` | 1, 3, 4, 5 |
| 8 | `BUY-MVP-ACCEPTANCE-TIME-STOCK-COMMIT` | 1, 3, 4, 5, 6 |
| 9 | `BUY-MVP-FINAL-PAYABLE-DELIVERY-QUOTE` | 1, 3, 4, 5 |
| 10 | `BUY-MVP-ELIGIBLE-FALLBACK-PARTNER-LADDER` | 1, 2, 8 |
| 11 | `BUY-MVP-QUOTE-FRESHNESS-EXPLICIT-FAILURE` | 1, 8 |
| 12 | `BUY-MVP-CART-COMMITMENT-SNAPSHOT` | 1 |
| 13 | `BUY-MVP-IDEMPOTENT-CUSTOMER-ORDER` | 1, 8 |
| 14 | `BUY-MVP-PROVIDER-NEUTRAL-PAYABLE-INTENT` | 1, 8 |
| 15 | `BUY-MVP-PAYMENT-PENDING-ASSIGNMENT` | 1, 8 |
| 16 | `BUY-MVP-REASSIGNMENT-SINGLE-DEBIT` | 1, 2, 8 |
| 17 | `BUY-MVP-NO-FULFILLER-VOID-REFUND` | 1, 8 |
| 18 | `BUY-MVP-SELLER-SETTLEMENT-AFTER-ACCEPTANCE` | 1, 8 |
| 19 | `BUY-MVP-PARTNER-ACCEPT-DECLINE-COMMAND` | 2, 6 |
| 20 | `BUY-MVP-MOOLCHAT-PARTNER-ORDER-ALERT` | 2, 6 |
| 21 | `BUY-MVP-WHATSAPP-PARTNER-ESCALATION` | 2, 6 |
| 22 | `BUY-MVP-AGENTIC-VOICE-ACCEPTANCE-CALL` | 2, 6 |
| 23 | `BUY-MVP-ACCEPTANCE-TIMEOUT-AUTO-REASSIGN` | 1, 2, 8 |
| 24 | `BUY-MVP-PROVIDER-NONRESPONSE-CAPABILITY-PAUSE` | 2, 6, 9 |
| 25 | `BUY-MVP-CUSTOMER-ASSIGNMENT-COUNTDOWN-STATUS` | 1, 2 |
| 26 | `BUY-MVP-SHOP-FULL-BASKET-ASSIGNMENT` | 3 |
| 27 | `BUY-MVP-SHOP-SUBSTITUTION-CONSENT` | 3 |
| 28 | `BUY-MVP-WHOLESALE-EXACT-COMMERCIAL-TERMS` | 4 |
| 29 | `BUY-MVP-WHOLESALE-BUYER-APPROVAL-CONTROL` | 4 |
| 30 | `BUY-MVP-MEDICINE-OTC-LICENSED-PHARMACY-ASSIGNMENT` | 5 |
| 31 | `BUY-MVP-MEDICINE-RX-SECURE-PHARMACY-HANDOFF` | 5 |
| 32 | `BUY-MVP-MEDICINE-NO-CLINICAL-SUBSTITUTION` | 5, 8 |
| 33 | `BUY-MVP-ACCEPTED-ORDER-PACKING-DEADLINE` | 6, 7 |
| 34 | `BUY-MVP-DELIVERY-CAPABILITY-ASSIGNMENT` | 7 |
| 35 | `BUY-MVP-PARCEL-HANDOVER-OTP-PROOF` | 7 |
| 36 | `BUY-MVP-CUSTOMER-DELIVERY-TRACKING` | 1, 7 |
| 37 | `BUY-MVP-PREPACK-SELLER-FAILOVER` | 8 |
| 38 | `BUY-MVP-POSTPICKUP-DELIVERY-RECOVERY` | 7, 8 |
| 39 | `BUY-MVP-DELIVERY-FAILURE-REFUND-SUPPORT` | 8 |
| 40 | `BUY-MVP-OPERATIONAL-RESPONSE-TELEMETRY` | 2, 9 |
| 41 | `BUY-MVP-ADMIN-TIMER-RECOMMENDATIONS` | 9 |
| 42 | `BUY-MVP-PHONE-ACTIVITY-PRIVACY-BOUNDARY` | 1, 5, 6, 9 |
| 43 | `BUY-MVP-FAILOVER-HTML-REFERENCE-BATCH` | 1–9 presentation authority |
| 44 | `BUY-MVP-NATIVE-ASSIGNMENT-RECOVERY-STATES` | 1–8 native projection |
| 45 | `BUY-MVP-AFFECTED-JOURNEY-REGRESSION-MATRIX` | 1–9 regression |
| 46 | `BUY-MVP-OPPO-CUSTOMER-PROVIDER-QUALIFICATION` | 1–8 device qualification |
| 47 | `BUY-MVP-BATCH-FOUNDER-ACCEPTANCE-PACK` | 1–9 final disposition |

## Parent acceptance criteria

The parent journey may reach final acceptance only when:

1. every applicable child ticket reaches qualified, explicitly excluded or
   accurately dependency-held disposition;
2. every customer, provider, Wholesale approver, pharmacy, delivery, support
   and Admin path above has authoritative success and failure evidence;
3. payment/reassignment tests prove one order and no second debit;
4. readiness and stock tests prove no pre-payment reservation;
5. Shop, Wholesale and Medicine preserve their separate legal/product rules;
6. late, duplicate, offline, stale, unknown and concurrent events fail safely;
7. all new visible states pass their retained reference/accessibility gates;
8. exact machine-built APK identity passes the required OPPO journeys twice;
9. source drift and protected R58.8.8 regressions pass; and
10. the founder receives one consolidated exact-candidate acceptance pack.

This parent ticket creates no independent implementation authority beyond its
preauthorized child manifest and never bypasses a child ticket's retained gate.
