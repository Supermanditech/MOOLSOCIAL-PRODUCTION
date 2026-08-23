# Buy MVP ready-order-to-delivery portfolio

Prepared: 5 August 2026
State: **PROPOSED FOR EXACT FOUNDER PORTFOLIO PREAUTHORIZATION — NO EXECUTION AUTHORITY YET**

## Portfolio outcome

Deliver one trustworthy Shop, Wholesale and Medicine journey:

`fresh ready decision -> Cart -> protected payment -> partner acceptance ->
stock commitment -> packing -> handover -> delivery/service proof -> recovery`

There is no pre-payment inventory reservation system. A readiness quote is a
fresh, expiring decision input, not a stock hold. Stock becomes committed only
when an eligible partner authoritatively accepts the exact order. If the first
partner does not accept in time, the same order and payment identity move to
the next eligible full-fulfilment partner without a second debit.

This portfolio is limited to Shop, Wholesale and Medicine. Generic service
marketplaces, Eat, Ride, salon, doctor booking, broad B2B expansion, autonomous
personalization and unrelated phone-activity monitoring are excluded.

## Portfolio authorization model

Portfolio ID: `BUY-MVP-READY-ORDER-DELIVERY-PORTFOLIO-20260805`

Founder preauthorization of this exact version would permit the tickets marked
`portfolio lane` to execute sequentially, one active ticket at a time, without
requesting a separate product authorization after every ticket. It would not
make a dependency-held ticket executable and would not waive any payment,
finance, legal, tax, clinical, privacy, security, provider, environment,
accepted-reference, APK-machine or release gate.

The preauthorized local execution envelope may include exact scoped source
writes, deterministic tests, unique candidate registration, machine-gated APK
builds and checksum-matched OPPO qualification when the ticket's dependencies
are satisfied. It excludes commits, pushes, deployment, promotion, Production,
credentials, funds movement, live WhatsApp messages, live telephone calls and
live provider actions unless the portfolio approval or a later exact approval
expressly authorizes that action after its independent gates pass.

New customer-visible failover states are prepared as one HTML reference batch.
The repository's mandatory founder `FINAL` reference gate remains before their
native Flutter implementation. After that reference gate, qualifying native
tickets proceed without individual founder reviews and end in one consolidated
OPPO founder-acceptance pack.

Execution stops and returns to the founder before continuing when any ticket:

- changes its customer outcome, classification, minimum scope or exclusions;
- crosses an unresolved external/provider/legal/clinical/environment gate;
- requires an unlisted credential, cost, live message, call or funds action;
- fails a protected/reference/release gate and needs a materially different
  successor; or
- would change an already accepted presentation contract.

## Initial Admin-controlled acceptance policy

Every acceptance policy is server-owned, versioned, effective-dated, audited
and snapshotted into the order. An Admin edit affects future orders only.

| Family | Initial per-partner window | Initial maximum sequential partners | Initial overall assignment ceiling | Allowed per-partner range | MoolChat | WhatsApp | Agentic call | Reassign |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Shop | 60 seconds | 3 | 180 seconds | 30–300 seconds | immediately | one-third | two-thirds | expiry |
| Wholesale | 180 seconds | 3 | 540 seconds | 30–300 seconds | immediately | one-third | two-thirds | expiry |
| Medicine, non-prescription | 90 seconds | 3 | 270 seconds | 30–300 seconds | immediately | one-third | two-thirds | expiry |
| Medicine, prescription | 300 seconds after pharmacist-ready review | 2 | 600 seconds | 30–300 seconds | immediately | one-third | two-thirds | expiry |

Admin may scope a policy by market type, provider type, category, locality,
weekday/time band and declared busy schedule. MVP learning uses only consented
provider-workspace operational signals such as open/busy/paused state,
acknowledgement latency, missed/accepted orders and outstanding workload. It
may recommend a policy to Admin; it cannot autonomously change Production.
Admin may configure one to five sequential partner attempts and an overall
assignment ceiling for future orders. Acceptance, explicit decline, ladder
exhaustion, quote expiry or the order-level ceiling ends the current path at
the first applicable instant; the system never waits indefinitely or extends
an active order because policy changed.

## Shared ticket rules

Every ticket below inherits these minimum rules:

- authorize tenant/workspace/capability before existence, version or business
  data lookup;
- use stable order, payment, offer, partner and policy identities;
- make unknown, stale, ambiguous, partial, denied and unavailable explicit;
- use exact decimals/minor units and append-only state/audit events;
- make commands idempotent and reconcile unknown outcomes before retry;
- never create payment success, acceptance, stock, licence, delivery or
  clinical truth from a client callback, timer or AI response;
- preserve protected R58.8.8 FIX7 and accepted UI references unless the exact
  ticket has cleared its separate reference gate; and
- record a unique evidence directory, predecessor identity, source manifest,
  focused checks, two affected regressions and final drift check.

Shared exclusions are speculative scale, broad personalization, unrelated
phone telemetry, background location, contact import, cross-tenant data,
secrets in source/logs, hidden price or term changes, silent medicine/product
substitution, a second debit during reassignment and an unconditional physical-
delivery guarantee.

## Exact ticket register

`Portfolio lane` means the ticket may execute after exact portfolio approval
and its listed dependencies. `Held lane` means the ticket remains registered
but needs the named independent gate before any held action. `Reference lane`
and `device lane` retain their existing machine gates.

Legacy codes used only as dependencies retain their already-registered
authority identities; they are not names for any new portfolio ticket:
`SUP-001` participant/workspace capability contract, `SUP-002` verified
onboarding and eligibility review, `SUP-003` canonical product/pack/offer
contract, `SUP-004` inventory and serviceability truth, `SUP-005`
seller-specific order/PO commitment, `DISC-005` regulated-category trust facts,
`B2B-001` wholesale operating decision, `B2B-002` verified pack/logistics-unit
contract, `B2B-003` wholesale commercial-term snapshot, `B2B-004` verified
business-buyer authority, `TAX-003` tax determination policy and `PAY-001`
seller/collection/settlement/refund operating decision. Every new ticket below
uses a complete outcome-scoped production ID rather than a generic number such
as `FUL-001`.

| # | Production-grade ticket ID | Customer outcome and smallest complete scope | MVP classification and reason | Dependencies / explicit ticket exclusions | Test and evidence plan | Lane |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `BUY-MVP-ADMIN-ACCEPTANCE-SLA-POLICY` | Admin can set 30–300-second acceptance windows, one-to-five partner-attempt limits and an order-level ceiling by family. | `mvp_required`: core assignment cannot operate truthfully with hard-coded, missing or unbounded deadlines. | Existing Admin authorization owner; excludes automatic learning and active-order mutation. | Window, attempt, ceiling, authorization, invalid range, concurrency and audit tests. | Portfolio |
| 2 | `BUY-MVP-MARKET-SCHEDULE-TIMER-OVERRIDES` | Admin can effective-date market, locality, weekday/time-band and declared-busy overrides. | `mvp_supporting`: bounded operational control keeps the core journey usable during real market schedules. | Ticket 1; excludes per-user profiling and retroactive changes. | Precedence, overlap, timezone, DST-equivalent and rollback fixtures. | Portfolio |
| 3 | `BUY-MVP-ORDER-TIMER-POLICY-SNAPSHOT` | Every order freezes the exact timer-policy ID/version, attempt limit, overall ceiling and derived escalation instants. | `mvp_required`: customer and partner must see one stable deadline despite later Admin edits. | Tickets 1–2; excludes editing an active snapshot. | Deterministic clock, bounded ladder, restart, replay and policy-revision tests. | Portfolio |
| 4 | `BUY-MVP-PROVIDER-READY-BUSY-PAUSE-STATE` | Provider workspace declares open, busy or paused readiness before receiving new demand. | `mvp_required`: a core order cannot be assigned to a provider that says it cannot receive it. | SUP-001 capability owner; excludes inferred readiness from personal phone use. | Role, stale state, schedule, offline and duplicate command tests. | Portfolio |
| 5 | `BUY-MVP-ACCEPTANCE-POLICY-AUDIT-ROLLBACK` | Admin can inspect, approve, roll back and explain every policy revision without rewriting history. | `mvp_required`: release and trust policy changes need accountable recovery. | Tickets 1–4; excludes destructive deletion. | Maker-checker, immutable audit, rollback and tamper tests. | Portfolio |
| 6 | `BUY-MVP-NO-RESERVATION-OFFER-READINESS` | Customer receives a fresh, expiring ready decision without a pre-payment stock hold. | `mvp_required`: unblocks truthful product choice while honoring the no-reservation decision. | SUP-003 plus named inventory/fulfilment owners; excludes persistence, live stock claims and stock holds until separately authorized. | Fresh/stale/unknown/partial capability and identity fixtures. | Portfolio |
| 7 | `BUY-MVP-FULL-BASKET-FULFILLABILITY` | Only a partner able to fulfil every exact line is eligible for automatic assignment. | `mvp_required`: prevents silent splits and incomplete paid orders. | Ticket 6; excludes split orders and substitutions. | Mixed-line, missing-pack, quantity and cross-family rejection tests. | Portfolio |
| 8 | `BUY-MVP-ACCEPTANCE-TIME-STOCK-COMMIT` | Stock is revalidated and committed atomically only when the partner accepts. | `mvp_required`: prevents oversell without maintaining a reservation system. | Tickets 6–7 plus inventory command owner; excludes client-side decrement and pre-accept holds. | Concurrency, duplicate accept, insufficient stock, expiry and release tests. | Held: inventory owner |
| 9 | `BUY-MVP-FINAL-PAYABLE-DELIVERY-QUOTE` | Customer sees exact payable components and delivery/collection promise for the eligible full basket. | `mvp_required`: the consumer purchase exit requires exact price and promise before payment. | Tickets 6–7 plus tax/delivery component owners; excludes guessed tax, hidden fees and unproved `lowest`. | Decimal, component, PIN, cut-off and changed-quote fixtures. | Held: finance/logistics facts |
| 10 | `BUY-MVP-ELIGIBLE-FALLBACK-PARTNER-LADDER` | Server creates a policy-bounded ordered list of full-fulfilment alternatives before assignment without holding their stock. | `mvp_required`: enables automatic recovery when the first partner does not accept. | Tickets 6–9; excludes unbounded attempts, distance-only ranking, personalization and stale candidates. | Capability, full-order, exact-total, attempt ceiling, SLA, distance and stable tie-break tests. | Portfolio |
| 11 | `BUY-MVP-QUOTE-FRESHNESS-EXPLICIT-FAILURE` | Customer receives an honest refresh, unavailable or changed-decision outcome instead of fabricated readiness. | `mvp_required`: truthful state is required before money or commitment. | Tickets 6–10; excludes optimistic fallback to stale facts. | Expiry-boundary, offline, partial refresh and conflict tests. | Portfolio |
| 12 | `BUY-MVP-CART-COMMITMENT-SNAPSHOT` | Checkout freezes exact lines, quantities, family, destination, offer/policy references and customer approvals. | `mvp_required`: payment and reassignment need one immutable reviewed basis. | Tickets 7–11; excludes merged retail/wholesale legal ownership. | Mutation-after-review, stale Cart and exact hash tests. | Portfolio |
| 13 | `BUY-MVP-IDEMPOTENT-CUSTOMER-ORDER` | One confirmed Cart creates one customer order identity despite retries or app interruption. | `mvp_required`: duplicate orders break the core purchase journey. | Ticket 12 plus production order owner; excludes seller acceptance and payment success. | Duplicate, retry, timeout, process death and tenant tests. | Held: order owner |
| 14 | `BUY-MVP-PROVIDER-NEUTRAL-PAYABLE-INTENT` | Server creates one payable intent/attempt aggregate bound to the reviewed order. | `mvp_required`: a launch purchase needs authoritative payment state. | PAY-001, ticket 13, finance/legal/backend approval; excludes provider adapter, webhook and credential. | PAY-003 transition, idempotency, expiry and unknown-outcome tests. | Held: payment authority |
| 15 | `BUY-MVP-PAYMENT-PENDING-ASSIGNMENT` | Customer sees protected payment/assignment state without an unaccepted seller being treated as settled. | `mvp_required`: money must remain safe while a partner is being confirmed. | Ticket 14 plus verified provider capability; excludes unsupported delayed-capture claims. | Authorized/paid-protected/unknown/cancel transition tests. | Held: provider evidence |
| 16 | `BUY-MVP-REASSIGNMENT-SINGLE-DEBIT` | Every partner attempt reuses the same customer order and cannot create a second debit. | `mvp_required`: automatic failover must not multiply payment exposure. | Tickets 13–15; excludes failover while debit truth is unknown. | Multi-partner retry, late callback and second-attempt rejection tests. | Held: payment authority |
| 17 | `BUY-MVP-NO-FULFILLER-VOID-REFUND` | If the ladder exhausts, MoolSocial releases/voids or starts one authoritative full refund and explains the result. | `mvp_required`: failure must protect customer money. | Tickets 14–16 plus refund owner; excludes locally fabricated refund success. | Void/refund pending/success/failure/duplicate/reconcile tests. | Held: payment/refund authority |
| 18 | `BUY-MVP-SELLER-SETTLEMENT-AFTER-ACCEPTANCE` | Seller payable/settlement cannot begin before exact acceptance and operating-model ownership are known. | `mvp_required`: prevents paying the wrong or non-accepting seller. | TAX/PAY dual model, tickets 8 and 14–17; excludes live settlement. | Model assignment, late accept, reassignment and ledger-reference tests. | Held: finance/legal |
| 19 | `BUY-MVP-PARTNER-ACCEPT-DECLINE-COMMAND` | Authorized provider can accept or decline once with exact order, stock and deadline context. | `mvp_required`: provider commitment is the stock and fulfilment authority. | Tickets 3–4, 8 and 13; excludes partial/silent acceptance. | Role, expiry, duplicate, conflict and reason-code tests. | Portfolio after order owner |
| 20 | `BUY-MVP-MOOLCHAT-PARTNER-ORDER-ALERT` | Provider receives an immediate in-product order alert with secure Accept/Decline action. | `mvp_required`: primary owned communication is needed for timely acceptance. | Ticket 19 plus MoolChat transactional owner; excludes private unrelated Chat data. | Delivery, dedupe, read/action, offline retry and deep-link tests. | Held: MoolChat owner |
| 21 | `BUY-MVP-WHATSAPP-PARTNER-ESCALATION` | Consented provider receives a minimal fallback alert at one-third of the snapshotted window. | `mvp_supporting`: bounded fallback improves acceptance reliability but is not the order authority. | Ticket 20 plus business sender, consent, template/category, budget, security and external-service authorization; excludes secrets and prescription content. | Opt-in, template, duplicate, revoke, timeout and cost-stop evidence. | Held: external WhatsApp |
| 22 | `BUY-MVP-AGENTIC-VOICE-ACCEPTANCE-CALL` | Verified provider number receives a bounded call asking only Accept or Decline at two-thirds of the window. | `mvp_supporting`: a final bounded escalation improves core operability without becoming decision truth. | Ticket 20 plus telephony, privacy/recording, security, cost and external-service authorization; excludes negotiation, clinical advice and payment authentication. | Called-party verification, replay, no-answer, DTMF/voice ambiguity, opt-out and cost-cap tests. | Held: external telephony |
| 23 | `BUY-MVP-ACCEPTANCE-TIMEOUT-AUTO-REASSIGN` | Expired unanswered/declined attempt moves the same order to the next currently eligible full fulfiller until the snapshotted limit or ceiling. | `mvp_required`: completes the founder-directed trust recovery without indefinite waiting. | Tickets 10, 16 and 19; excludes price/term/substitution changes without consent. | Timer race, late accept, simultaneous response, attempt/overall ceiling, exhausted ladder and restart tests. | Portfolio after dependencies |
| 24 | `BUY-MVP-PROVIDER-NONRESPONSE-CAPABILITY-PAUSE` | Repeated missed orders pause new-order eligibility until the provider confirms readiness. | `mvp_supporting`: protects customers from repeatedly unresponsive providers. | Tickets 4 and 23; excludes punitive hidden scoring and permanent automatic suspension. | Threshold, recovery, Admin override, appeal and audit tests. | Portfolio |
| 25 | `BUY-MVP-CUSTOMER-ASSIGNMENT-COUNTDOWN-STATUS` | Customer sees payment-safe assignment, countdown, escalation, reassignment and accepted-partner states. | `mvp_supporting`: removes uncertainty during the core journey. | Tickets 3, 15 and 23 plus HTML founder `FINAL`; excludes technical/provider diagnostics. | Copy, accessibility, lifecycle, offline and process-recreation states. | Reference lane |
| 26 | `BUY-MVP-SHOP-FULL-BASKET-ASSIGNMENT` | One eligible Shop partner accepts every exact consumer line at the approved total/promise. | `mvp_required`: completes the launch consumer purchase assignment. | Tickets 7–23; excludes silent split, wholesale terms and hidden replacement. | Multi-line, PIN, price, stock, timeout and Back/recovery journeys. | Portfolio after dependencies |
| 27 | `BUY-MVP-SHOP-SUBSTITUTION-CONSENT` | Customer may pre-authorize narrowly defined Shop substitutions or approve a specific change. | `mvp_supporting`: avoids unnecessary failure without weakening customer control. | Ticket 26 plus reference approval; excludes automatic brand/price/allergen-sensitive substitution. | Consent absent/revoked, exact alternative, price and partial-order tests. | Reference lane |
| 28 | `BUY-MVP-WHOLESALE-EXACT-COMMERCIAL-TERMS` | Reassignment preserves exact pack, MOQ, tiers, tax references, freight, delivery and payment policy. | `mvp_required`: a Wholesale PO cannot silently change its commercial commitment. | B2B-002/003, TAX-003 and tickets 9–23; excludes credit or unapproved bank transfer. | Tier boundary, pack multiple, term drift and supplier-change tests. | Held: B2B/tax facts |
| 29 | `BUY-MVP-WHOLESALE-BUYER-APPROVAL-CONTROL` | Verified business preparer/approver controls commitment and any changed supplier term. | `mvp_required`: Wholesale launch pilot requires workspace authority. | B2B-001/004 and ticket 28; excludes personal-account authorization. | Maker-checker, spend authority, stale approval and duplicate PO tests. | Held: B2B eligibility |
| 30 | `BUY-MVP-MEDICINE-OTC-LICENSED-PHARMACY-ASSIGNMENT` | Non-prescription Medicine order goes only to a currently eligible licensed pharmacy with the exact pack. | `mvp_required`: regulated launch truth requires licensed fulfilment. | SUP-002/DISC-005 regulatory owner plus tickets 7–23; excludes inferred licence or medical advice. | Licence freshness, pack, PIN, timeout and fail-closed tests. | Held: regulatory evidence |
| 31 | `BUY-MVP-MEDICINE-RX-SECURE-PHARMACY-HANDOFF` | After pharmacist-ready review, a timed reassignment shares the minimum secure prescription context with another eligible licensed pharmacy. | `mvp_required`: prescription failure recovery must remain lawful and product exact. | Prescription/pharmacist, consent, privacy and regulatory owners; excludes WhatsApp prescription payloads and automatic approval transfer. | Consent, line identity, expiry, revoke, audit and second-pharmacist acceptance tests. | Held: clinical/privacy |
| 32 | `BUY-MVP-MEDICINE-NO-CLINICAL-SUBSTITUTION` | Medicine, strength, dosage form, pack and approved quantity never change through AI or automatic failover. | `mvp_required`: safety/legal truth cannot be traded for fulfilment speed. | Tickets 30–31; excludes diagnosis, dosing and therapeutic substitution. | Mismatch, absent line, excess quantity, stale approval and reorder tests. | Portfolio contract; live held |
| 33 | `BUY-MVP-ACCEPTED-ORDER-PACKING-DEADLINE` | Accepted partner sees line-by-line packing and a committed packing deadline. | `mvp_required`: acceptance must advance toward delivery, not become a dead end. | Tickets 8, 19 and family assignment; excludes fabricated packed state. | Incomplete packing, failure/retry, timeout and duplicate-complete tests. | Portfolio after dependencies |
| 34 | `BUY-MVP-DELIVERY-CAPABILITY-ASSIGNMENT` | Packed order is assigned once to an eligible own-delivery or verified delivery partner. | `mvp_required`: core order must obtain accountable delivery ownership. | SUP-004/005 logistics owner and ticket 33; excludes directory-style unverified drivers. | Capacity, zone, duplicate request, failure/retry and identity tests. | Held: logistics owner |
| 35 | `BUY-MVP-PARCEL-HANDOVER-OTP-PROOF` | Parcel transfers only after verified captain identity, correct OTP and separate physical handover. | `mvp_required`: prevents false or unsafe custody transfer. | Ticket 34 plus identity/OTP owner; excludes OTP-as-delivery and client-declared proof. | Wrong/expired OTP, duplicate, identity mismatch and handover retry tests. | Held: identity/logistics |
| 36 | `BUY-MVP-CUSTOMER-DELIVERY-TRACKING` | Customer sees named owner, committed promise, verified events and proof without decorative live claims. | `mvp_required`: launch exit requires authoritative order visibility. | Tickets 33–35 plus tracking owner; excludes inferred location and fake maps. | Out-of-order events, stale/offline, process death and accessibility tests. | Reference lane after logistics |
| 37 | `BUY-MVP-PREPACK-SELLER-FAILOVER` | Accepted seller failure before irreversible packing can safely reopen the ladder without another debit. | `mvp_required`: recovers early fulfilment failure while preserving money and order identity. | Tickets 16, 23 and 33; excludes failover after irreversible handover. | Stock release, late event, price drift, reassignment and refund tests. | Portfolio after dependencies |
| 38 | `BUY-MVP-POSTPICKUP-DELIVERY-RECOVERY` | After pickup, delivery failure routes to accountable logistics recovery rather than duplicating the seller order. | `mvp_required`: protects custody and customer support after irreversible handover. | Tickets 34–36 plus support/logistics owner; excludes silent seller reassignment. | Captain failure, parcel return, redelivery, loss/damage and audit tests. | Held: logistics/support |
| 39 | `BUY-MVP-DELIVERY-FAILURE-REFUND-SUPPORT` | Unrecoverable fulfilment produces one support case and authoritative refund/replacement choice. | `mvp_required`: launch trust requires a terminal recovery outcome. | Tickets 17, 32 and 38 plus refund/returns owner; excludes promised credit without finance approval. | Duplicate case, refund unknown, partial family and customer-choice tests. | Held: refund/support |
| 40 | `BUY-MVP-OPERATIONAL-RESPONSE-TELEMETRY` | Admin sees aggregate acknowledgement, acceptance, timeout and workload evidence by policy scope. | `mvp_supporting`: measured operations are needed to tune launch timers safely. | Tickets 1–5 and 19–24 plus observability/privacy approval; excludes message content and unrelated phone activity. | Redaction, retention, aggregation, tenant and opt-out tests. | Held: privacy/observability |
| 41 | `BUY-MVP-ADMIN-TIMER-RECOMMENDATIONS` | System recommends a bounded timer revision for Admin review from approved operational evidence. | `mvp_supporting`: improves operability without autonomous production control. | Ticket 40 plus measured minimum sample and policy review; excludes automatic apply, user profiling and black-box ranking. | Sparse data, bias, rollback, explanation and no-auto-mutation tests. | Portfolio after telemetry approval |
| 42 | `BUY-MVP-PHONE-ACTIVITY-PRIVACY-BOUNDARY` | Provider and customer are protected from unrelated device/activity surveillance. | `mvp_required`: privacy truth is a launch gate. | Privacy approval; permits only consented app/workspace operational events; excludes contacts, other apps, personal messages, microphone and background location. | Static egress scan, permission, revoke, retention and negative fixtures. | Portfolio contract; collection held |
| 43 | `BUY-MVP-FAILOVER-HTML-REFERENCE-BATCH` | Founder reviews every new customer/provider assignment, timeout, escalation and recovery state as one connected HTML batch. | `mvp_required`: native customer UI cannot precede accepted-reference authority. | Tickets 1–42 contracts; excludes Flutter edits and overwriting accepted v1. | Responsive state inventory, tap replay, copy and checksum package. | Reference lane: founder FINAL |
| 44 | `BUY-MVP-NATIVE-ASSIGNMENT-RECOVERY-STATES` | Native Flutter matches the frozen batch for Shop, Wholesale and Medicine without changing protected R58.8.8 behavior. | `mvp_required`: implements the customer-visible core journey after reference approval. | Ticket 43 founder `FINAL`, protected gates and backend contracts; excludes legacy UI mixing and provider fabrication. | Goldens, semantics, lifecycle, reduced motion and exact parity tests. | Portfolio after reference FINAL |
| 45 | `BUY-MVP-AFFECTED-JOURNEY-REGRESSION-MATRIX` | Every success, timeout, decline, reassign, payment-safe failure and delivery recovery path passes twice. | `mvp_required`: release qualification cannot rely on happy-path testing. | Implemented applicable tickets; excludes weakening established skips/gates. | Two full affected regressions, backend suite, drift and failure scans. | Portfolio |
| 46 | `BUY-MVP-OPPO-CUSTOMER-PROVIDER-QUALIFICATION` | Exact machine-built APK passes customer and provider workflows, interruptions, accessibility, performance and checksum identity on OPPO. | `mvp_required`: physical-device qualification is mandatory for the review candidate. | Tickets 43–45, unique APK machine state and one-use build authorization; excludes hot reload and unidentified builds. | Install/pull checksum, cold/process, IME, reduced motion, performance and logs. | Device lane |
| 47 | `BUY-MVP-BATCH-FOUNDER-ACCEPTANCE-PACK` | Founder receives one exact portfolio disposition pack after all executable tickets and OPPO journeys reach terminal evidence. | `mvp_required`: one consolidated decision protects the exact cumulative candidate. | Tickets 1–46 terminal; dependency-held items must be clearly passed, excluded or still blocked. | Candidate/source/APK identities, ticket matrix, screenshots, failures, exclusions and GO/NO-GO. | Founder final |

## Portfolio-wide qualification and evidence plan

For every activated ticket:

1. Record branch, HEAD, complete dirty inventory and predecessor source
   manifest before the first write.
2. Record the ticket's full disclosure and portfolio authorization evidence in
   the MVP machine state; only one ticket may be active.
3. Run `scripts/check-mvp-scope-gate-state.ps1
   -RequireExecutionAuthorized` before the first runtime/backend write or
   build.
4. Run focused deterministic tests, authorization/tenant/idempotency/data-
   egress checks, two affected regressions and the final source-drift check.
5. For UI work, run every protected/reference/copy/accessibility/responsive/
   reduced-motion gate and use the founder-final immutable reference.
6. For each APK, register one unique candidate/version/source identity and use
   the mandatory wrapper and one-use APK machine authorization.
7. Preserve every rejected candidate, build, log, screenshot, accessibility
   tree and disposition.

## Founder preauthorization decision requested

The founder may approve the exact machine manifest at SHA-256
`5CE81AB6332607A71B960C57A1E99466109E13299CD8A5995FFC3163F35893AF` with:

`PREAUTHORIZE BUY-MVP-READY-ORDER-DELIVERY-PORTFOLIO-20260805 FOR SEQUENTIAL
MVP EXECUTION WITHIN EACH LISTED SCOPE. AUTHORIZE LOCAL RUNTIME/BACKEND WRITES,
MACHINE-GATED BUILDS AND CHECKSUM-MATCHED OPPO TESTING WHEN LISTED DEPENDENCIES
PASS. DO NOT AUTHORIZE CREDENTIALS, LIVE PAYMENT, FUNDS MOVEMENT, LIVE WHATSAPP,
LIVE TELEPHONY, DEPLOYMENT, PROMOTION, COMMIT OR PUSH. RETAIN THE HTML FOUNDER
FINAL GATE AND ONE CONSOLIDATED FINAL OPPO FOUNDER ACCEPTANCE. MANIFEST SHA-256
5CE81AB6332607A71B960C57A1E99466109E13299CD8A5995FFC3163F35893AF.`

Any amendment to the ticket list, scope, classification, exclusions or
authorization envelope creates a new portfolio version and requires an exact
new founder decision.
