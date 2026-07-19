# MoolSocial full-scale production journey map

Last reconciled: 19 July 2026

## Source of truth

- Approved reference: `supermandi-uiux-screenbook/approved-final`
- Approved screen files: 167 (`00` through `166`)
- Flow definitions: 48 total
  - 1 aggregate screenbook sequence
  - 47 operational user-flow definitions
- Production client: `MOOLSOCIAL-PRODUCTION/apps/mobile`
- The HTML screenbook defines product intent, information and reachable
  outcomes. Flutter owns the production interaction design. Reviewer framing,
  phone frames, simulation panels and internal implementation wording must not
  be copied into the user application.

## Non-negotiable implementation rules

1. Implement one end-to-end vertical journey at a time.
2. Every visible tap must complete an action or reveal the next action needed
   to complete the intent.
3. Test every tap, sub-tap and reachable nested branch from a clean state.
4. Cover success, empty, invalid, duplicate, cancelled, loading, retry,
   offline, permission-denied and failure states where the journey permits.
5. A journey is not done at screen rendering. It is done only after:

   `discover → reproduce → evidence → ticket → root cause → fix → build → exact
   replay → affected-journey rerun → full regression`

6. Use customer-facing, action-oriented language. Internal terms such as
   “simulation”, “handoff”, “route”, “workspace state” or “review build” must
   not appear on a customer screen.
7. Use the shared Apple-inspired Mool design system, 44 px minimum targets,
   safe areas, large-text support, reduced-motion support and deterministic
   back navigation.
8. No external transaction is claimed as complete until its production
   provider confirms it. Review adapters remain replaceable behind gateway
   interfaces.

## Ordered vertical slices

| Order | Production slice | Approved flows | Screen coverage | Status |
|---:|---|---|---|---|
| 0 | Install, setup, OTP and Universal entry | `onboarding` | 00–04 | Implemented; two clean regression cycles passed |
| 1 | Household buying, delivery, bill and issue resolution | `buy-delivery`, `buy-issue` | 04, 09–12, 14, 17–22 | Implemented in Flutter; dedicated black-box suite passed |
| 2 | At-shop payment and collection | `buy-counter` | 04, 09–12, 14–16 | Implemented in Flutter with explicit store choice, collection readiness, protected code, handoff and receipt; dedicated black-box suite passed |
| 3 | Transactional and people chat | `chat` | 04, 23–25 | Implemented in Flutter; inbox, people/business/order/support threads, attachments, reply/reaction, failed-send replay, contextual actions and protected return routes passed dedicated and full-app regression |
| 4 | Food delivery, table booking and tiffin | `eat-order`, `eat-table`, `eat-tiffin` | 04, 26–29 | Implemented in Flutter; order, basket, payment, tracking, table confirmation and tiffin controls passed dedicated black-box, two full regression cycles and physical-device replay |
| 5 | Ride booking and completion | `ride` | 04, 30–35 | Implemented in Flutter; booking, captain arrival, live trip, explicit payment approval, receipt and support passed dedicated black-box, two full regression cycles and physical-device replay |
| 6 | Doctor, salon and local task booking | `doctor-booking`, `doctor-invite`, `salon`, `get-it-done` | 03–04, 36–56 | Implemented in Flutter; consent-aware doctor care, complete salon visit and proof-protected local task paths passed dedicated black-box, two full regression cycles and physical-device replay |
| 7 | Recharge, bills, scan, request, refund and reversal | `pay-recharge`, `pay-bills`, `pay-scan`, `pay-request`, `pay-refund`, `pay-failure` | 04, 57–66 | Implemented in Flutter; safe debit confirmation, requests, pending lockout, failed-no-debit retry, refund and reversal passed dedicated black-box, two full regression cycles and physical-device replay |
| 8 | Work identity and retailer onboarding | `earn-workspace`, `retailer-onboarding` | 04, 67–74 | Implemented in Flutter; opportunity, identity, proof, review and first live retailer product passed dedicated black-box, two full regression cycles and physical-device exact crash replay |
| 9 | Retailer customer orders and delivery | `retailer-orders` | 13, 74–77 | Implemented in Flutter; paid-order acceptance, complete packing, captain assignment, OTP handover, tracking, receipt and Business Book entry passed dedicated black-box, two full regression cycles and physical-device integration replay |
| 10 | Retailer POS, procurement, books, services, growth and controls | remaining `retailer-*` operational flows | 74, 78–106 | Complete in Flutter: POS 74 → 78 → 79 → 78 → 80 → 90; wholesale 74 → 81–89; Business Book 91 → 92 → 106; operated Business Services 93–96; customers/campaigns 97–100; recovery, AI, staff, settings and issues 101–105. Every slice passed dedicated black-box, two regression cycles, visual gates and physical-device replay |
| 11 | Manufacturer sales, procurement, growth and control | all `manufacturer-*` flows | 107–115 | Complete in Flutter: home, Business Book, catalogue, sales-order review, input procurement, dispatch, demand/campaigns, claims/team/settings and operated services passed dedicated black-box, two regression cycles, nine-screen visual gates and two physical-device exact replays |
| 12 | Captain ride and earnings | `captain-workspace` | 116–123 | Complete in Flutter: availability, complete request economics, pickup/OTP, live trip safety, fare/payment, earnings/payout, compliance, support, opportunities and state-aware trip navigation passed dedicated black-box, two regression cycles, eight-screen visual gates and two physical-device exact replays |
| 13 | Creator studio, campaigns, commerce share, membership, licensing and YouTube Connect | all `creator-*` flows plus screen 166 | 05–07, 09, 12, 14, 17–18, 99–100, 113, 124–137, 152, 154, 156, 166 | Core Creator surface complete in Flutter for 124–132 and 166: Studio, business-funded 1–7 day Reels, YouTube Connect, library, performance, audience, campaigns, earnings, rights and memberships passed two regression cycles, 13 visual gates and three physical-device exact replays. Earn operations dependency 133–137 is complete in slice 14; remaining commerce and admin dependencies continue in slice 15 |
| 14 | Freelancer operations and service-provider workspace | `earn-operations`, `provider-workspace` | 133–146 | Complete in Flutter: funded opportunities, applications, active work, proof, earnings, history, provider home, catalogue, availability, requests, fulfilment, business records, growth and controls passed two regression cycles, 14 visual gates and two physical-device exact replays |
| 15 | Superadmin operations and dynamic user-type offerings | `admin-operations` | 147–156, 163–164 | Complete in a separately deployed, role-gated Next.js console: 12 owner screens, 42 governed cases, all 29 approved profile targets, business-funded 1–7 day Reel provisioning, failure/retry/duplicate protections, two responsive regression cycles and two physical OPPO Chrome exact replays |
| 16 | Shared account, security, workspace and notification controls | `shared-controls` | 157–162, 165 | Pending |

## Operational flow register

### Consumer

- `onboarding`: 00 → 01 → 02 → 03 → 04
- `social`: 04 → 05 → 06 → 07 → 08
- `buy-counter`: 04 → 09 → 10 → 11 → 12 → 14 → 15 → 16
- `buy-delivery`: 04 → 09 → 10 → 11 → 12 → 14 → 17 → 18
- `buy-issue`: 18 → 19 → 20 → 21 → 22
- `chat`: 04 → 23 → 24 → 23 → 25
- `eat-order`: 04 → 26 → 27
- `eat-table`: 04 → 26 → 28
- `eat-tiffin`: 04 → 26 → 29
- `ride`: 04 → 30 → 31 → 32 → 33 → 34 → 35
- `doctor-booking`: 04 → 36 → 37 → 38
- `doctor-invite`: 39 → 40 → 03 → 41
- `salon`: 04 → 36 → 42 → 43 → 44 → 45 → 46 → 47
- `get-it-done`: 04 → 36 → 48 → 49 → 50 → 51 → 52 → 53 → 54 → 55 → 56
- `pay-recharge`: 04 → 57 → 58 → 63 → 64
- `pay-bills`: 04 → 57 → 59 → 63 → 64
- `pay-scan`: 04 → 57 → 60 → 63 → 64
- `pay-request`: 04 → 57 → 61 → 62 → 63 → 64
- `pay-refund`: 04 → 57 → 61 → 62 → 63 → 65
- `pay-failure`: 04 → 57 → 61 → 62 → 63 → 66

### Workspaces and operations

- `earn-workspace`: 04 → 67 → 68 → 69 → 70 → 71 → 72 → 73
- `retailer-onboarding`: 70 → 71 → 72 → 73 → 74
- `retailer-orders`: 13 → 74 → 75 → 76 → 77
- `retailer-pos`: 74 → 78 → 79 → 78 → 80 → 90
- `retailer-wholesale`: 74 → 81 → 82 → 83 → 84 → 85 → 86 → 87 → 88 → 89 → 92
- `retailer-books`: 92 → 90 → 92 → 87 → 92 → 91 → 92 → 106
- `retailer-services`: 74 → 93 → 94 → 95 → 96
- `retailer-growth`: 74 → 97 → 98 → 97 → 74 → 99 → 100
- `retailer-controls`: 74 → 101 → 74 → 102 → 74 → 103 → 74 → 104 → 74 → 105 → 74 → 106
- `manufacturer-sales`: 107 → 109 → 107 → 110 → 112
- `manufacturer-procurement`: 107 → 111 → 108
- `manufacturer-growth`: 107 → 113 → 107 → 115
- `manufacturer-control`: 107 → 114 → 107 → 108
- `captain-workspace`: 116 → 117 → 118 → 119 → 120 → 121 → 116 → 122 → 116 → 123
- `creator-workspace`: 124 → 125 → 124 → 126 → 127 → 124 → 128 → 124 → 129 → 124 → 130 → 124 → 131 → 124 → 132
- `creator-funded-campaign`: 100 → 152 → 129 → 125 → 05 → 127 → 154 → 130
- `creator-commerce-share`: 99 → 129 → 125 → 05 → 09 → 12 → 14 → 17 → 18 → 127 → 154 → 130
- `creator-membership`: 132 → 07 → 62 → 63 → 130
- `creator-content-pool`: 06 → 127 → 154 → 130
- `creator-local-production`: 100 → 129 → 125 → 152 → 154 → 130
- `creator-onboarding`: 152 → 133 → 134 → 135 → 136 → 137 → 130
- `creator-live-event`: 113 → 156 → 129 → 125 → 07 → 62 → 63 → 127 → 130
- `creator-licence`: 99 → 131 → 154 → 130
- `earn-operations`: 133 → 134 → 135 → 136 → 137 → 138
- `provider-workspace`: 139 → 140 → 139 → 141 → 139 → 142 → 143 → 144 → 139 → 145 → 139 → 146
- `admin-operations`: 147 → 148 → 149 → 150 → 151 → 152 → 153 → 154 → 155 → 156 → 163 → 164
- `shared-controls`: 162 → 157 → 162 → 158 → 162 → 159 → 162 → 160 → 162 → 161 → 162 → 165

## Buy implementation decisions now locked

- Consumer catalogue shows household quantities only.
- Wholesale MOQ, business case prices, demand aggregation and campaigns do
  not appear in the consumer product grid.
- Home delivery is the default for a consumer shopping from home.
- Store collection becomes active only after the customer explicitly chooses
  a store.
- Duplicate adds increment one basket line instead of creating duplicate rows.
- Product, seller, quantity, price, delivery promise and refund rule are
  visible before checkout.
- Payment failure creates no order and states that no money was deducted.
- Retry uses the same basket and creates one order.
- Delivery completion exposes bill, proof, ratings, repeat purchase and order
  problem resolution.

## Chat implementation decisions now locked

- Chat has one production inbox for people, businesses, linked orders and
  support cases.
- Opening Chat from another journey preserves that exact return screen.
- People threads expose chat, shared media, household basket, polls and member
  invitations.
- Business threads expose chat, catalogue, quote, linked orders and confirmed
  payment entry.
- Order and support threads expose the linked details and chronological
  updates.
- Message attachments, replies and reactions complete visibly. An empty send
  is rejected with a customer-facing correction.
- A failed send remains visible with Retry. Replaying the original failed tap
  sequence replaces it with one delivered message; it does not duplicate it.
- Calls, video calls and potentially sensitive conversation actions require an
  explicit confirmation or show their completed state.

## Food implementation decisions now locked

- Food is a production vertical slice with separate Order, Table and Tiffin
  routes behind one shared Eat entry.
- Restaurant and kitchen selection rejects a closed or paused provider without
  replacing the user's current valid selection.
- Order fulfilment supports home delivery, pickup, table QR and confirmed
  scheduled delivery. Scheduled checkout cannot proceed without a valid date
  and time.
- Duplicate food adds increment one basket line. Customization remains attached
  to that line and is visible before payment.
- Food availability, preparation time, cancellation window, digital bill,
  delivery fee and final total remain visible before payment.
- Failed food payment creates no order, deducts no money and preserves the
  basket for one exact retry.
- Live order status covers confirmation, preparation, rider assignment,
  nearby, delivered, early cancellation, support, bill and meal rating.
- Table booking requires a restaurant, party size, time and table choice.
  Booking cost, deposit adjustment, hold time, late-arrival rule and
  cancellation window are visible before confirmation.
- A confirmed table exposes a protected arrival QR, directions, masked call,
  restaurant chat, menu preorder and safe cancellation.
- Tiffin exposes kitchen trust, food style, day-wise menu, meal count, delivery
  slot, trial/weekly/monthly price, address, pause/skip allowance and
  cancellation timing before starting.
- An active tiffin plan supports next-meal skip/restore, pause/resume, address
  change entry, receipt, kitchen chat and stop-before-renewal.
- Success or error banners are scoped to the journey where they occurred and
  are cleared when switching between Order, Table and Tiffin.

## Ride implementation decisions now locked

- Bike, Auto and Cab share one production booking route while retaining the
  user's explicit vehicle choice.
- Pickup, destination, schedule, available package, fare range, cancellation
  rule and payment method remain visible before booking.
- The customer is not charged at booking. Payment requires explicit approval
  after the final trip fare and breakdown are visible.
- Failed booking, payment and support submissions retain the user's context.
  Exact retry creates one booking, receipt or case without duplication.
- Captain identity, vehicle, rating and verified status remain visible before
  the customer confirms pickup.
- Live trip actions include call, chat, share, add stop and safety. Adding a
  stop requires an explicit fare review before confirmation.
- Receipt actions include download, share, rating, ride again and support.
- Missing item, fare, route and safety cases attach the relevant trip, route,
  captain and receipt evidence automatically.
- Real maps, captain supply, telephony, emergency response and payment remain
  replaceable external gateways and are not falsely represented as certified.

## Book implementation decisions now locked

- The main Mool Book action opens the production Book master directly. It does
  not add a generic intent-confirmation screen before Doctor, Salon or Get It
  Done.
- Doctor care separates clinic, hospital OPD, video and follow-up. Fee, wait,
  registration, clinic proof and follow-up policy remain visible.
- Medical information is linked only after the patient selects a profile,
  supplies required age/reason information and explicitly allows the verified
  clinic. The patient can pause sharing without deleting private records.
- Salon visit and home visit remain distinct. Service, mode, slot, provider
  proof, add-ons, final amount and cancellation window remain visible before
  confirmation.
- A salon payment failure never marks the bill paid. Check-in, queue, issue
  before pay, final bill, rating, repeat booking and saved-record support stay
  connected to one booking.
- Get It Done requires an exact instruction before review. The user sees the
  helper fee, spend cap and total protected hold before confirming.
- Task payment cannot release before required proof. The user sees actual
  spend and the unused return, then explicitly releases, asks for clearer
  proof or opens a case.
- Failed booking, payment, helper matching, release, support and resolution
  submissions keep their context and exact retry cannot create a duplicate.
- Medical storage, provider licensing, live availability, maps, telephony,
  payment/hold/refund and safety operations remain replaceable external
  gateways and are not falsely represented as certified.

## Pay implementation decisions now locked

- Pay home contains personal recharge, bill, QR/UPI and payment-request
  actions. Business disbursements remain inside the relevant business
  workspace.
- A scan, request or fetched bill cannot debit by itself. Payee, purpose,
  linked reference, amount and payment method remain visible before explicit
  approval.
- Unknown requesters and invalid payment identifiers cannot reach debit
  confirmation.
- Camera permission denial keeps typed UPI entry available and provides a
  recoverable permission path.
- Provider and payment failure preserve the original intent and state that no
  money was deducted. Exact retry cannot create a duplicate debit or receipt.
- Pending payment locks repeat payment. Status refresh checks the existing
  bank reference and cannot create a second debit.
- Failed-no-debit can be retried with the same payee, purpose and amount.
  Reversal cannot be retried and its return stays linked to the original
  reference and payment method.
- Successful, pending and returned records remain searchable, shareable and
  connected to support.
- RBI/UPI, BBPS, bank reconciliation, KYC/risk, refund/reversal,
  tokenization, QR validation and production support remain replaceable
  external gateways and are not falsely represented as certified.

## Work implementation decisions now locked

- Earn and My Work are separate intents: Earn discovers verified
  opportunities; My Work creates, reviews and operates the user's own work
  identities.
- Applying without a verified workspace saves the exact opportunity and sends
  the user to My Work. It does not create a false application.
- One personal MoolSocial account may hold multiple verified workspaces.
  Starting another work identity does not replace or hide existing work.
- Business activity, exact profile, contact, business details, proof and
  declaration remain visible and editable before review submission.
- An unsupported activity creates a trackable request, not a fake workspace.
- Optional GST proof can be added now or later. Missing optional GST does not
  erase the submitted work profile.
- Proof, submission, GST and status failures keep the user's existing fields
  and one review reference. Exact retry cannot duplicate a workspace or case.
- Approval is not the end intent for a retailer. The workspace becomes usable
  only after one valid product, quantity, household selling price and
  fulfilment method are confirmed.
- Home delivery and store collection are explicit retailer capabilities.
  Store collection is not presented to consumers unless the retailer enables
  it and the customer chooses that store.
- Firebase production collection stays disabled in local debug builds that use
  emulator credentials. Production configuration is a release gate, not a
  simulated success.
- Employer funding, work eligibility, KYC/document review, GST validation,
  payouts, catalogue/inventory, delivery, payment and moderation remain
  replaceable external gateways and are not falsely represented as certified.

## Retailer customer-order implementation decisions now locked

- A paid order remains in Needs review until the retailer explicitly accepts
  it. Payment protection, delivery promise and refund rule stay visible.
- Home delivery is an operating fulfilment mode. Store collection is not
  inserted into a home-delivery order.
- Every product group must be checked before packing can complete. Failed
  packing preserves every checked line.
- Delivery assignment starts only after packing. A failed request cannot
  create a second delivery reference or captain assignment.
- Parcel ready, captain at shop, OTP verified and parcel handed over are
  separate irreversible checkpoints.
- An invalid OTP keeps the parcel with the retailer. OTP verification alone
  does not record physical handover.
- Delivery status refresh updates the existing delivery and cannot create a
  new order, debit or delivery reference.
- Delivered proof creates one customer-visible receipt and one Business Book
  entry.
- Cannot fulfil and delivery issue paths require explicit reasons, support
  cancellation and preserve the order through exact failure retry.
- Retailer Mool and Chat actions retain the originating operating screen.
- Orders, inventory reservation, payment/refund, delivery matching, captain
  identity, OTP, live location, customer proof and Business Book posting
  remain replaceable external gateways and are not falsely represented as
  certified production services.

## Retailer POS and Sales Book implementation decisions now locked

- Counter, Phone and order-linked Chat use one order builder and one live-stock
  truth. The order source controls only the relevant customer, fulfilment and
  payment choices.
- Counter mobile is optional. It is used only for customer lookup, invoice
  delivery and purchase history; an anonymous counter sale remains possible.
- Barcode and voice entry can add only a reviewed match from My Stock.
  Permission denial leaves manual search and Add fully usable.
- Order creation reserves available quantity once. Failure keeps the complete
  draft, and exact retry cannot create another order.
- Every counter retains its purpose, operator, availability, order and sales
  trail while sharing the shop's authoritative inventory.
- Cash needs explicit physical-receipt confirmation. UPI and Card expose the
  matched transaction or authorisation before completion.
- Sale completion posts stock, payment, invoice and the Sales Book only after
  authoritative success. Failure preserves the existing order and payment for
  retry.
- WhatsApp and SMS invoice delivery require customer consent. MoolSocial Chat
  and QR/Print remain available without using external messaging consent.
- Sales Book is a read projection of orders, payments, invoices, inventory and
  returns. Refresh and export cannot create or mutate a sale.
- Business Book financial views and exports remain role controlled.
- Orders, stock, payment, invoice, consent delivery, tax export and financial
  projection remain replaceable external gateways and are not falsely
  represented as certified production services.

## Retailer wholesale and Purchase Book decisions now locked

- Wholesale Buy is a shop procurement surface. MOQ cases, supplier payment,
  delivery and landed value never appear in consumer Buy.
- Canonical products stay separate from supplier offers. The authoritative
  gateway chooses a serviceable offer; no screen renders millions of duplicate
  supplier listings.
- Adding a product starts at its exact MOQ. Current availability is enforced,
  and the cart survives offline and gateway failure for an exact retry.
- Commercial terms are revalidated immediately before placement. Any changed
  term requires explicit retailer confirmation; there is no silent
  substitution.
- One placement command creates supplier-wise purchase orders once. A purchase
  order is not a GST invoice and ordered quantity is not available stock.
- Delivery tracking distinguishes committed time, verified dispatch and live
  telemetry. It never displays a decorative map as live tracking.
- Only accepted goods post to inventory and the Purchase Book. Short, damaged,
  wrong or invoice-mismatched goods keep the affected settlement protected.
- A goods-receipt command posts one GRN and one inventory event. Exact retry
  cannot increase stock twice.
- The Purchase Book normalizes MoolSocial purchase orders and direct supplier
  bills without mislabelling their source. Financial views and exports remain
  role controlled.
- Supplier payment authorization is not settlement. Processing blocks a second
  authorization; failed or reversed outcomes restore the payable obligation.
- Catalogue matching, PO placement, transport events, GRN/stock posting,
  invoice validation, exports and supplier payment remain replaceable external
  gateways and are not falsely represented as certified production services.

## Retailer Business Services decisions now locked

- Business Services sells MoolSocial-operated outcomes, not a directory of
  delivery partners, creators, salespeople or professionals.
- Delivery Support, Grow Sales, Tax & Books and Offers & Ads are separate
  entitlements with independent plan, spend cap, evidence, renewal and
  cancellation.
- Monthly fee, included work, variable charge, non-billable events, proof,
  taxes and maximum payable amount are visible before activation.
- A validated retailer limit blocks new chargeable work above the approved
  amount unless the retailer explicitly changes it.
- Commercial consent is never preselected. Tax & Books additionally requires
  separate purpose-limited, logged and revocable business-data consent.
- Activation is one idempotent payment-plus-entitlement command. Failure
  retains every choice and creates no payment or entitlement; exact retry can
  create only one.
- An active service opens its first useful operating action, usage, spend,
  setup, proof activity, billing, support and cancellation; it is never a
  receipt dead end.
- Plans, payments, entitlements, usage, attributed results, filings,
  advertising spend, evidence and cancellation remain replaceable external
  gateways and are not falsely represented as live production services.

## Retailer customer and campaign decisions now locked

- Customer search combines order history, repeat timing, dues, open issues and
  current messaging permission without treating marketing consent as invoice
  consent.
- Repeat baskets use current stock and price before creating a real retailer
  order. A reminder never creates an order.
- Every customer reminder records purpose, operator, channel, current
  permission and opt-out. Duplicate submission cannot send twice.
- Open customer issues appear before promotion and can suppress an offer.
- Campaigns are stock backed. Maximum orders cannot exceed the lowest selected
  sellable stock, and stock is committed only on accepted orders.
- Retailer-approved spend is a hard maximum. Views and unverified leads are not
  charged as sales.
- Only paid, non-refunded attributed orders count; completed attribution is
  locked.
- Draft, publish, pause and delete are idempotent commands with explicit
  cancelled, failed, offline and exact-retry behavior.
- Customers, consent, messaging, inventory, campaign budgets, attribution and
  refunds remain replaceable external gateways and are not falsely represented
  as server-certified production services.

## Retailer operating-control decisions now locked

- Slow-stock recovery uses only eligible sellable units and enforces quantity,
  floor price, route, duration and owner review before publish.
- Mool AI is grounded in role-authorized workspace records and prepares drafts;
  it never autonomously purchases, publishes, refunds or changes shop data.
- Staff access is least privilege, role based, auditable and inactive until an
  invite is accepted.
- Store settings commit as one idempotent version so the client cannot present
  a partial save as a completed business outcome.
- Customer issues retain evidence, message, selected resolution and protected
  payment context through failure and exact retry.
- Recovery, AI, invitation, access, settings and resolution commands reject
  offline or unauthorized execution and never duplicate protected outcomes.
- Inventory, AI, identity, authorization, compliance, payments, evidence and
  messaging remain replaceable external gateways and are not falsely
  represented as server-certified production services.

## Manufacturer operating decisions now locked

- Pausing supply affects new availability only; existing confirmed orders
  remain visible and actionable.
- Buyer-visible products require valid stock, price, MOQ, terms and confirmed
  manufacturing-input mapping.
- Full, partial and cannot-fulfil are explicit order decisions. Partial
  quantity is bounded and cannot-fulfil requires a buyer-readable reason.
- Purchase carts survive failure. A purchase order uses verified input MOQs
  and commits once; receipt records grade, quantity and condition once.
- Dispatch requires GST invoice, LR, e-way bill and the chosen fleet identity.
  Delivery proof precedes ledger-controlled payment release.
- Manufacturer campaigns have a hard funding maximum. Only approved
  activations or paid, non-refunded attributed orders count; views do not.
- Claims, team invitations, settings versions and service requests are
  permission checked, failure safe and idempotent.
- Business Services disclose coverage, base price, success charge, minimum
  term, proof and cancellation before a request; no charge is taken at request.
- Product, stock, order, ledger, payment, procurement, compliance, logistics,
  attribution, identity and service-entitlement systems remain replaceable
  external gateways and are not falsely represented as certified production
  services.

## Captain operating decisions now locked

- Location sharing for new rides begins only after the Captain explicitly goes
  Online and stops after the Captain goes Offline.
- A ride decision exposes pickup, destination, distance, duration, fare,
  platform charge, estimated fuel and expected net earning before acceptance.
- Accept, decline, trip start, destination arrival, payment confirmation,
  verification, support and opportunity application are permission checked,
  failure safe and idempotent.
- Pickup confirmation requires current pickup location and the matching rider
  OTP; destination completion requires a started trip and current destination
  location.
- The persistent Trip action follows pickup, live and fare-completion state;
  it never sends an active Captain back to the beginning.
- A failed payment check cannot close a trip or credit earnings. One confirmed
  receipt credits one trip earning and exposes its charge breakdown.
- Vehicle requirements are derived from vehicle and service use. Verification
  requires explicit consent and never changes eligibility before confirmation.
- Safety, support and found-item paths retain the relevant trip and vehicle
  context. Paid opportunities disclose geography, payment, approval rule,
  proof and capacity before application.
- Delivery tasks remain in the separate Delivery Partner workspace.
- Identity, request dispatch, maps/location, communications, safety, payment,
  ledger, payout, document and opportunity systems remain replaceable external
  gateways and are not falsely represented as certified production services.

## Creator operating decisions now locked

- A native promotional Reel is funded by a verified business; the creator does
  not pay to publish the sponsored campaign deliverable.
- Native Reels are limited to 60 seconds and use a precise 1, 2, 3, 4, 5, 6 or
  7 day paid run. They automatically leave the live campaign at expiry.
- The selected sponsor, reserved creator earning, material connection, paid
  disclosure, rights and expiry remain visible before publish.
- Persistent Shorts and long-form video stay on YouTube. YouTube Connect adds
  one Mool action and may add a time-bound discovery placement without
  rehosting or claiming ownership of the video.
- Text and image posts are native formats and do not inherit paid Reel
  duration.
- Views, likes and attention do not become guaranteed sales or payable
  outcomes. Only approved campaign work or paid, non-refunded attributed
  commerce can move to the creator ledger.
- Drafts, publication, campaign acceptance, statement preparation, appeals and
  membership changes are permission checked, failure safe and idempotent.
- Audience reporting stays aggregated. Private viewer identities, contact
  books and purchase histories are not exposed to creators.
- Identity, media, YouTube, moderation, rights, campaign funding, attribution,
  membership, ledger, tax and payout systems remain replaceable external
  gateways and are not falsely represented as certified production services.

## Earn and provider operating decisions now locked

- Workers never pay to apply for or start funded work. The verified business
  or MoolSocial reserves payout for approved output.
- Potential earnings are not salary or guaranteed income. Eligibility, open
  capacity, proof and approved outcome control payment.
- Protected actions are permission checked, failure safe and idempotent. An
  offline, unauthorized or failed command cannot create a false result.
- Pausing new provider demand preserves every already accepted customer
  commitment.
- Provider growth keeps both economic directions explicit: funded work pays
  the provider; a business growth campaign uses the provider’s approved
  maximum budget.
- A growth-campaign request is not represented as charged before final
  business and external-payment confirmation.
- Fulfilment needs arrival and outcome confirmation. Completion can move money
  only to settlement review, not directly to paid.
- Identity, eligibility, funding, dispatch, location, proof, fraud,
  communications, catalogue, availability, request, campaign, payment,
  ledger, tax, payout and support systems remain replaceable external gateways
  and are not falsely represented as certified production services.

## Superadmin and provisioning decisions now locked

- Superadmin is a separately deployed responsive web console. It is not
  embedded in the consumer/business app or public marketing site.
- Production access denies by default and requires a verified server session,
  least-privilege role, permitted scope, reason and immutable audit history.
- Dynamic provisioning targets the permanent personal profile and every one of
  the 28 approved workspace profiles without hard-coding broad substitutes.
- An offering draft cannot reach users or charge budget. Product, Finance,
  policy and Operations approval precede a small test group and health-gated
  expansion.
- Business-funded creator Reels use a controlled 1, 2, 3, 4, 5, 6 or 7 day
  run, with explicit 24/48-hour clarification, sponsor disclosure, reserved pay
  and automatic expiry.
- Every privileged command is confirmation-gated, failure safe, idempotent and
  blocked offline or without permission.
- Signals resolve eligible recipients only at permitted use time. Raw audience
  lists and private viewer/customer identities are not exportable.
- Identity, roles, audit, payments, verification, catalogue, ride safety,
  proof, moderation, appeals, campaigns, messaging and analytics remain
  replaceable external gateways and are not falsely represented as certified
  production services.

## Release boundary

“Full prototype implemented” and “production live” are different gates. Full
Flutter intent completion can continue against deterministic gateway
interfaces. Public production launch additionally requires live cloud billing,
Firebase production configuration, payment-provider credentials, release
signing, iOS signing/build infrastructure, privacy/legal approval and real
provider sandbox certification.
