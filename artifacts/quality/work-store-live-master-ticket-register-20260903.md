# MoolSocial Store Live — consolidated master ticket register

Date: 2026-09-03
Status: planning only; no ticket in this register is implemented or authorized by this document alone.

## Founder disposition — Store first view accepted

The main Store first-view architecture is accepted. It is now the fixed design authority for the Store landing experience:

- compact Store identity and operating state;
- inline Store search, Scan, Alerts and Profile;
- Live Business Pulse;
- ranked Live Action Stage;
- first-tap retailer command band; and
- Store-owned bottom rail.

Do not replace this main Store architecture in later tickets. Only implement it faithfully, correct responsive/accessibility defects and connect it to truthful live state.

Full UI/UX replacement is permitted from the first destination tap onward. Orders, order detail, packing, pickup, delivery, Sell, catalogue, stock, customers, money, Group Bulk Buying, settings, growth, Storefront and their sheets may receive completely new destination layouts. Their existing route, session, transaction, state, draft-preservation and exact Back/return contracts must not regress.

## Authority and replacement rule

This register combines:

1. `final -MoolSocial_Store_Workspace_MVP_Plan_v2_20260902.docx`;
2. founder decisions and approved Store journeys through 2026-09-03;
3. the post-approval findings numbered 59–92; and
4. the latest MoolSocial Store Live direction.

The master plan remains authoritative for business purpose, data truth, state machines, customer consent, Group Bulk Buying, shared catalogue, Call-to-Delivery, Benefits Passport, App Sale Booster, ownership and acceptance outcomes.

The following older presentation decisions are superseded:

- The Store is not a collection of large dashboard cards.
- A permanent right-side status rail is not retained.
- The empty `Ready for customer activity` deck is not retained.
- New Sale and Deliver Order do not remain duplicate composers.
- Configuration is not mixed with live daily work.
- Repeated Store status, explanatory copy and internal terms are not retained.

The accepted compact Store header, inline search and Store bottom rail remain.

## Product standard

The retailer must understand the highest-priority action within three seconds, begin it with one tap or swipe, and normally complete the intent within two interactions. Every sale must connect order, stock, customer, invoice and money exactly once. Every screen must remain usable at 1.4x text, with the keyboard and Android system navigation visible.

## Release structure

- Wave A: Store Live foundation and first founder screenshots.
- Wave B: orders, selling, packing and delivery.
- Wave C: products, stock, Wholesale and Group Bulk Buying.
- Wave D: customers, money, growth, business identity and public trust.
- Wave E: ecosystem contracts, wording and complete production-readiness replay.

---

## Wave A — Store Live foundation

### STORE-LIVE-01 — One Store shell and one navigation hierarchy

**Goal:** Remove competing navigation without losing first-tap access.

**Implementation:**

- Keep the compact Store name, one `Open · Public` state, inline search, Scan, Alerts and Profile.
- Retain the bottom Store rail: Mool, Store, Orders, Sell, Stock and Chat.
- Replace the right bubble rail and business grid button with contextual status/action rows inside the live surface.
- Keep four compact retailer commands above the bottom rail: `Bill & Invoice`, `Deliver an Order`, `Buy Stock`, `Group Buy`.
- Preserve exact Back, filter, search, scroll and draft state.

**Acceptance:** No destination has two competing owners; every command remains reachable in one tap; compact width and 1.4x labels are complete.

**Replaces findings:** 59, 62, 63.

### STORE-LIVE-02 — Live Business Pulse

**Goal:** Make Store feel live even when no urgent order exists.

**Implementation:**

- Add one slim actionable pulse: Orders, Sales today, Low stock and Available to settle.
- Values update from existing Store session events; no invented counts.
- Each value opens the exact filtered destination.
- Keep the pulse visible while a live action card is present.

**Acceptance:** The retailer can identify sales, orders, stock risk and available money within three seconds.

**Replaces findings:** 60, 61.

### STORE-LIVE-03 — Ranked Live Action Stage

**Goal:** Show the next retailer action, not a static dashboard.

**Implementation:**

- Rank paid-order response, delivery exception, packing deadline, secured Group Buy payment, money hold, stock risk, compliance and customer follow-up.
- Expand only the highest-priority action; show the next two as compact rows.
- Collapse the idle state to `Your store is ready` plus the Business Pulse.
- Use existing state and deterministic rules; no new AI engine.
- Automatically shift emphasis for opening, busy trading and closing periods.

**Acceptance:** No large empty deck; no zero-filled fake metrics; resolved action animates out and the next action becomes primary.

**Replaces findings:** 60, 64, 67, 92.

### STORE-LIVE-04 — Operational motion, feedback and freshness

**Goal:** Communicate state changes without decorative distraction.

**Implementation:**

- Animate incoming rows, changed numbers, accepted swipes, packing progress, rider milestones and settlement completion.
- Collapse success confirmation within about two seconds.
- Attach errors to the affected action rather than carrying them across destinations.
- Show saved/offline state and last-updated time when live freshness is unavailable.
- Respect reduced-motion settings.

**Acceptance:** No looping decorative motion; success never blocks the next action; failure never erases saved records.

**Replaces findings:** 67, 92.

### STORE-LIVE-05 — Universal Store search

**Goal:** Find orders, products, customers, invoices and settlement references from one field.

**Implementation:**

- Retain the accepted Buy-style inline search.
- Group results by Orders, Products, Customers, Invoices and Money.
- Search remains scoped to the active Workspace.
- Search closes before route exit and restores query/result scroll on return.
- Scan requests camera only after the Scan action.

**Acceptance:** One search owner across all Store destinations; no duplicate destination search bar; no inactive query remains in the header.

### STORE-LIVE-06 — Responsive and input foundation

**Goal:** Remove all large-text, keyboard and Android-safe-area failures before visual expansion.

**Implementation:**

- Define single-line/fallback behaviour for command labels, delivery steps and CTAs.
- Keep sticky actions above keyboard and Android navigation.
- Preserve typed values through Back, destination changes and recoverable failures.
- Provide native accessibility names and TalkBack order for every editable/action control.

**Acceptance:** 320–430 px, 100% and 140% text; keyboard open/closed; portrait safe area; no clipping, jumping, zero-sized action or inaccessible field.

**Replaces findings:** 62.

---

## Wave B — orders, selling, packing and delivery

### STORE-LIVE-07 — Scalable Customer Orders queue

**Goal:** Support many simultaneous orders without oversized cards.

**Implementation:**

- Use compact rows containing countdown, customer, amount, payment, fulfilment, item count and next action.
- Keep one-line counted filters: All, New, Packing, Ready and On the way.
- Move Completed/Cancelled to History.
- Sort by action deadline and promised fulfilment.

**Acceptance:** At least four realistic order rows remain readable in the first viewport at 1.4x.

**Replaces findings:** 72, 73.

### STORE-LIVE-08 — Order decision and promise control

**Goal:** Accept, extend or reject with payment, stock and customer promise visible.

**Implementation:**

- Swipe right Accept; swipe left opens compact reject confirmation; tap opens detail.
- Remove duplicate swipe instructions after guided first use.
- Show payment truth, item availability and promised response/preparation time.
- Add customer Call/Chat.
- Make acceptance and stock reservation idempotent.

**Acceptance:** A destructive action always has reason and confirmation; extending time updates the customer promise; rejection releases stock once.

**Replaces findings:** 64.

### STORE-LIVE-09 — Packing, shortage and substitution

**Goal:** Make packing an item-level operation.

**Implementation:**

- Show `0 of n units packed`, not an ambiguous product count.
- Preserve complete product lines above the sticky action.
- Add Unavailable, Replace item and Contact customer choices.
- Require customer approval when product or price changes.
- Mark ready only when every accepted line is resolved.

**Acceptance:** Quantity, issue state and timer survive navigation; no card height is fixed beyond its content.

**Replaces findings:** 65.

### STORE-LIVE-10 — Pickup and invoice handoff

**Goal:** Complete counter pickup safely and retain the customer.

**Implementation:**

- Compact pickup state with customer, total, payment and pickup code.
- Verify one-time order-bound pickup code.
- Complete order, invoice, stock, customer and money once.
- Offer Send in MoolSocial Chat, WhatsApp, secure link or print/QR when available.

**Acceptance:** Pickup never requests a rider; invoice retains exact recipient, products and amount; Back restores the completed order.

**Replaces findings:** 66.

### STORE-LIVE-11 — MoolSocial delivery journey

**Goal:** Give a store delivery capability without permanent delivery staff.

**Implementation:**

- Show requested, assigned, arriving, arrived, collected, en route, near customer, delivered and exception states.
- Keep customer Call/Chat, address/map, payer, delivery fee, ETA and exception actions visible.
- Show real rider identity/GPS only after assignment.
- Verify handover/pickup codes and preserve milestone truth if GPS is unavailable.

**Acceptance:** No invented rider, ETA or location; every exception names the next retailer action.

**Replaces findings:** 66.

### STORE-LIVE-12 — One sale and delivery composer

**Goal:** Replace duplicate New Sale and Deliver Order screens.

**Implementation:**

- One composer with `Counter`, `Phone`, `Chat` as order source.
- `Take now`, `Pick up later`, `My delivery`, `Mool delivery` as customer receipt choice.
- Deliver shortcut opens the same composer with delivery selected.
- Standardize journey wording: `Bill & Invoice`, `Create delivery order`, `Review order`, `Complete sale`.

**Acceptance:** Switching source or delivery does not clear customer/basket; no duplicated composer source remains.

**Replaces findings:** 73, 74.

### STORE-LIVE-13 — Fast customer and product entry

**Goal:** Let a busy retailer build a basket without excessive typing.

**Implementation:**

- Search known customer by phone/name as digits are entered; show recent customers.
- Show frequent/recent products with image/category, pack, price and stock.
- Keep Scan and Search beside Add products.
- Allow unknown-customer ordinary sale without silently creating an account.

**Acceptance:** Known customer and common product can be added with one selection each; duplicate customer records are prevented.

**Replaces findings:** 75, 76.

### STORE-LIVE-14 — Final sale review and payment truth

**Goal:** Make the final decision concise and complete.

**Implementation:**

- Show customer, source, products, amount, saving/discount, payment and delivery summary.
- Keep payment options truthful: cash, UPI, payment request, on delivery and customer due.
- Show address, fee payer and delivery promise before requesting a rider.
- Keep Edit and Confirm actions above Android navigation.

**Acceptance:** Confirmation verb matches the chosen outcome; failed payment preserves the editable basket and does not permanently post stock.

**Replaces findings:** 77.

### STORE-LIVE-15 — Call-to-Delivery and customer claim

**Goal:** Convert a phone order into delivery and a future MoolSocial customer.

**Implementation:**

- Send secure basket/address/fee/time confirmation to existing app customers or no-app mobile web/SMS recipients.
- Do not require installation for the first order.
- Assign delivery only after the customer confirms high-risk facts.
- After OTP delivery, invite the same verified mobile to claim receipt, history and eligible benefits.

**Acceptance:** No silent consumer account; unclaimed purchase remains claimable; retailer never sees cross-provider private history.

---

## Wave C — products, stock and procurement

### STORE-LIVE-16 — Shared catalogue and Store Assortment contract

**Goal:** Prevent every retailer from recreating common products.

**Implementation:**

- Master catalogue owns barcode, canonical identity, brand, category, pack, media, description, origin and common regulatory facts.
- Store Assortment owns Store SKU, selling price, private purchase cost, stock mode, quantity/availability, threshold, fulfilment and public state.
- Unknown products remain private drafts until reviewed.

**Acceptance:** One saved public Store SKU maps to the exact Buy product contract; private cost never appears publicly.

### STORE-LIVE-17 — Fast catalogue onboarding and scanner dependency

**Goal:** Launch large stores without entering thousands of products manually.

**Implementation:**

- Barcode match, CSV/Excel/POS import, Wholesale receipt matching, starter assortment and missing-product request.
- Review only unmatched, conflicting or duplicate rows.
- Support Availability only and Exact quantity stock modes.
- Consume the shared scanner after Cursor/Buy supplies visible capture/automatic-status behaviour.

**Acceptance:** A 5,000-row import is resumable; no product becomes public without confirmed price and availability.

**Replaces findings:** 70, 71.

### STORE-LIVE-18 — Premium Store catalogue

**Goal:** Make catalogue the clear source of the public Store.

**Implementation:**

- Title: `Products customers can buy`.
- Primary actions: Scan and Add; secondary Import/Low stock in compact overflow.
- Dense SKU rows with product image, complete product/pack, price, MRP, stock and public/private.
- Quick Change price, Update stock and Publish/Hide.
- Rename verified-source actions to `Add from MoolSocial catalogue` and `Add this product`.

**Acceptance:** No clipped shortcut row; at least five useful SKU rows fit the normal first viewport.

**Replaces findings:** 78, 79.

### STORE-LIVE-19 — Fast Product editor

**Goal:** Make common SKU changes immediate while retaining complete public data.

**Implementation:**

- First block: image, product/pack, selling price, MRP, stock and public state.
- Prefill shared product facts after scan/match.
- Collapse advanced customer facts, origin, return, regulatory and composition sections.
- Keep Save sticky and preserve every value through keyboard/navigation failures.

**Acceptance:** Price/stock/public change completes without traversing the entire form; complete Buy-required facts remain available.

**Replaces findings:** 70, 80.

### STORE-LIVE-20 — Stock Statement and restock action

**Goal:** Explain every quantity and connect stock risk to supply.

**Implementation:**

- Available, Reserved, Low stock and Out of stock summaries.
- Movement rows for sale, return, goods received, adjustment and damage/expiry.
- Rule-based days-of-stock recommendation using sales velocity, stock, threshold and open purchase orders.
- Open exact Wholesale recommendation and restore Store state on Back.

**Acceptance:** Stock changes once per source event; adjustment requires reason; recommendation never invents supplier availability.

### STORE-LIVE-21 — In-Store Wholesale and Purchase Book

**Goal:** Keep procurement inside Store while reusing the existing Buy owner.

**Implementation:**

- Use current Wholesale/Bulk catalogue, cart, checkout, PO and tracking.
- Preserve Store identity and compact return contract.
- Add goods receipt, condition/shortage evidence and Purchase Book linkage.
- Increase Store stock only after verified receipt.

**Acceptance:** No duplicate Wholesale implementation; keyboard never exposes the wrong navigation owner.

### STORE-LIVE-22 — Live Group Bulk Buying

**Goal:** Make cooperative purchasing a flagship retailer advantage.

**Implementation:**

- Compact product specification, sourced reference value, group delivered price, fees, net saving and selected quantity.
- Show verified participating business name, locality, quantity and milestone with consent.
- Keep closing countdown, secured quantity, remaining quantity and payment milestone live.
- First successful confirmation payment automatically pins the same deal for other eligible retailers.
- Keep `Secure my quantity`, balance payment, delivery tracking and goods receipt visible at the applicable stage.

**Acceptance:** No hidden fee, invented saving or silent deal change; closed/full/invalid deals leave the top area; stock updates only on receipt.

**Replaces findings:** 87.

---

## Wave D — customers, money, growth and business identity

### STORE-LIVE-23 — Customer Book and Customer Statement

**Goal:** Turn every completed Store sale into useful repeat-business memory.

**Implementation:**

- Compact searchable customer list with last purchase, purchase count, total spend, due and last contact.
- Filters: Recent, Repeat, Payment due, Following Store and Messages allowed.
- Statement: purchases, paid, due, refunded and average basket for week/month/quarter/financial year/custom.
- Exact order/invoice drill-down and period restoration.

**Acceptance:** Four or more customer rows fit first viewport; data remains Store-specific; restricted staff cannot see protected fields.

**Replaces findings:** 81, 83.

### STORE-LIVE-24 — Customer retention actions

**Goal:** Convert customer history into repeat sales without a marketing maze.

**Implementation:**

- First-tap Call, Chat/WhatsApp, Repeat basket, Send invoice and Send offer.
- Separate operational communication from promotional permission.
- Create useful groups: regular, new, not returning, payment due, likely reorder and offer accepted.
- Revalidate current price/stock before a repeat basket reaches checkout.

**Acceptance:** Opted-out customers are excluded immediately; no unavailable product is silently added.

**Replaces findings:** 82.

### STORE-LIVE-25 — Money and settlement clarity

**Goal:** Make sold, pending, held, due and payable amounts understandable.

**Implementation:**

- Keep the premium dark Money surface.
- Put `Request settlement` beside the available balance.
- Show an aligned table: completed sales, awaiting completion, MoolSocial fees, delivery adjustments, refunds/holds, tax and net available.
- Settlement review shows bank name, masked account, requested amount, deductions, net payout and expected date.
- Every total drills into source transactions.

**Acceptance:** No ambiguous `Pending fulfilment`, `Requested`, `Platform adjustments` or generic `Workspace bank account` wording.

**Replaces findings:** 84, 85, 86.

### STORE-LIVE-26 — Growth hub, offers and repeat campaigns

**Goal:** Make growth measurable and immediately usable.

**Implementation:**

- Grow shows live counts: repeat customers, active offers, paid work open and Store reach.
- Offer templates: Monthly essentials, Back in stock, Festival saving and Repeat your basket.
- Choose eligible customers and available products, set end date/order cap and preview customer presentation.
- Promote opens existing Social Create with Store/product/offer and exact return.

**Acceptance:** No full marketing studio; no publication without permission, stock and capacity truth.

**Replaces findings:** 88.

### STORE-LIVE-27 — Funded Store work

**Goal:** Publish a verified, funded Store requirement into Earn Today.

**Implementation:**

- Position/task, work, candidate need, city/area/PIN, people needed, payment format/amount and deadline.
- Add concise review showing Store publisher, funded amount and candidate-facing result.
- Support draft, clarification, published, closed and full states.

**Acceptance:** Earn Today receives the existing opportunity contract; no unfunded or unverified posting appears active.

**Replaces findings:** 88.

### STORE-LIVE-28 — Store controls, delivery area and staff

**Goal:** Keep configuration truthful and separate from live work.

**Implementation:**

- Make hours, maximum active orders and alert rows genuinely editable.
- Rename `Fulfilment` to `Pickup and delivery`.
- Delivery settings support city/area/PIN/radius, fee, free-delivery threshold and pickup.
- Staff supports named member, role, counter, PIN/access and permissions; otherwise narrow the MVP promise.
- Unsaved settings always offer Keep editing or Discard.

**Acceptance:** No visible chevron is a no-op; public availability changes only after Save succeeds.

**Replaces findings:** 68, 69.

### STORE-LIVE-29 — Business Profile, plans, documents and services

**Goal:** Keep identity/configuration out of the daily dashboard while making it easy to find.

**Implementation:**

- Registered MoolSocial Business Partner, Store plan, team, business documents, status and public-preview entry.
- Remove repeated Active/approved Store labels.
- Use truthful document wording such as `1 document on file`.
- Business services remain scoped request flows for GST, ITR, books and audit, with provider/scope/price/status.

**Acceptance:** Personal identity remains global; business data remains Workspace-scoped; no pre-approval state appears for an approved Store.

**Replaces findings:** 90, 91.

### STORE-LIVE-30 — Exact public Storefront and Trust Profile

**Goal:** Show the retailer exactly what customers see and give customers reasons to buy/follow.

**Implementation:**

- Separate a slim owner toolbar from the exact customer rendering.
- Remove self-Follow from owner preview.
- Show live open/reopening state, available products, pickup/delivery, Ask the Store and Buy again.
- Show transparent trust signals only: verified business/address/licence, stock accuracy, acceptance, on-time packing, cancellation, issue resolution, invoice availability, rating count and last active.
- No opaque composite score.

**Acceptance:** Public facts equal saved Store facts; no generic product image when valid Store media exists; one Back restores Storefront.

**Replaces findings:** 89.

---

## Wave E — ecosystem contracts and release quality

### STORE-LIVE-31 — Benefits Passport Store handoff

**Goal:** Give customers a strong reason to place/confirm purchases through MoolSocial.

**Implementation:**

- A customer-confirmed purchase creates one private purchase event.
- Show receipt, savings, repeat basket, delivery-benefit and reward progress truthfully.
- Existing/no-app customers use secure confirmation and later claim by verified mobile.
- Retailer sees only this Store relationship, not cross-provider private history.

**Acceptance:** No guaranteed income, free delivery or credit claim; no silent account creation; refunded purchases reconcile once.

### STORE-LIVE-32 — App Sale Booster and retailer Growth Credit

**Goal:** Give both customer and retailer a reason to move counter sales into MoolSocial.

**Implementation:**

- Show customer saving and its funding source before confirmation.
- Show retailer settlement, contracted charges and non-cash Growth Credit separately.
- Growth Credit applies only to eligible Wholesale, delivery or plan use, with cap/expiry/terms.
- Margin guard blocks unsafe retailer-funded discounts.

**Acceptance:** No hard-coded commercial value; funding split is visible; cancellation/refund reverses pending benefit safely.

### STORE-LIVE-33 — Global Chat, Profile and Promote contracts

**Goal:** Preserve a dedicated Store experience without duplicating shared systems.

**Implementation:**

- Pass Workspace ID, order/customer/delivery/product/offer intent and exact return route.
- Customer/order entry opens the correct conversation or draft, not only the generic inbox.
- Remove stale Workspace-review emphasis after approval.
- Promote uses plain retailer language and exact Store identity while remaining Social-owned.

**Acceptance:** One global Chat/Profile/Promote owner; Back returns to exact Store state; no duplicate top Chat icon.

**Replaces findings:** 90.

### STORE-LIVE-34 — Retailer wording and premium design system

**Goal:** Remove commentary/internal language and create one recognisable Store operating style.

**Implementation:**

- Use MoolSocial navy as the operating base, white work surfaces, mint for positive/paid, amber for deadlines and red only for real risk.
- Use tabular figures, compact adaptive rows and one dominant action.
- Replace internal/corporate terms according to finding 91, including `Fulfilment`, `Customer relationships`, `Customer serviceability`, `document references`, `Workspace bank account`, `attributable` and `eligible enquiries`.
- Keep wording bilingual-ready and safe for regional-language expansion.

**Acceptance:** Complete visible-string audit passes; no commentary, engineering, permission-internal or placeholder wording remains.

**Replaces findings:** 79, 85, 88, 90, 91, 92.

### STORE-LIVE-35 — Full state, navigation and device qualification

**Goal:** Qualify the complete Store journey before founder APK review.

**Implementation:**

- Cover loading, saved/offline, empty, error, permission, retry, success and interruption per destination.
- Replay Back/forward, exact return, draft preservation, process restart and duplicate-action protection.
- Render every state locally at compact width and 1.4x text.
- Cross-check every prior finding against its equivalent implementation.
- Only after founder screenshot approval: build one APK, install on OPPO and replay all Store journeys.

**Acceptance:** No open Store-owned visual, keyboard, Android inset, route, state or wording defect; shared-owner failures remain explicitly separated.

## Accepted Store first-view implementation package

The first package should contain STORE-LIVE-01 through STORE-LIVE-06. These tickets implement and qualify the accepted architecture; they do not reopen its design direction:

1. one Store shell;
2. Live Business Pulse;
3. ranked Live Action Stage;
4. operational motion/feedback;
5. universal search continuity;
6. responsive/input foundation.

This package gives the founder the accepted complete first view and proves every first-tap entry. Destination replacement begins with STORE-LIVE-07.

## Destination replacement sequence after the accepted Store first view

1. **Orders:** STORE-LIVE-07 and 08 replace the current Orders list and decision presentation while preserving order identity, filter and stock-reservation rules.
2. **Packing, pickup and delivery:** STORE-LIVE-09 through 11 replace the current operational cards/sheets while preserving the order state machine and invoice/delivery owners.
3. **Sell:** STORE-LIVE-12 through 15 replace New Sale and Deliver Order with one composer and the approved Call-to-Delivery/customer-claim flow.
4. **Products and stock:** STORE-LIVE-16 through 20 replace catalogue/product/stock presentation around the shared catalogue and Store Assortment contract.
5. **Procurement:** STORE-LIVE-21 and 22 retain the existing Wholesale owner but replace Store-host and Group Buy presentation where Work owns it.
6. **Customers and money:** STORE-LIVE-23 through 25 replace customer, statement and settlement layouts with dense operational views.
7. **Growth:** STORE-LIVE-26 and 27 replace the current sparse Grow, Offers and funded-work destination layouts.
8. **Settings and identity:** STORE-LIVE-28 and 29 replace configuration/business-record layouts while preserving approval truth and Store scope.
9. **Storefront:** STORE-LIVE-30 replaces the mixed owner/customer preview with an exact public rendering plus a slim owner toolbar.
10. **Connected ecosystem:** STORE-LIVE-31 through 35 add the approved benefits/contracts and qualify shared handoffs without duplicating their owners.

## Finding coverage

- 59–67: STORE-LIVE-01 through 11.
- 68–71: STORE-LIVE-17, 28 and shared scanner dependency.
- 72–77: STORE-LIVE-07 through 14.
- 78–80: STORE-LIVE-18 and 19.
- 81–83: STORE-LIVE-23 and 24.
- 84–86: STORE-LIVE-25.
- 87: STORE-LIVE-22.
- 88: STORE-LIVE-26 and 27.
- 89: STORE-LIVE-30.
- 90: STORE-LIVE-29 and 33.
- 91–92: STORE-LIVE-04, 06 and 34.

## Ownership boundary

- Codex Work Store: Store shell, Store screens, Store session/state, Work-owned tests and Store copy.
- Cursor Buy: shared scanner and Wholesale/Bulk internal implementation.
- Work-to-Buy contract: complete Store SKU facts, selected Workspace and exact return.
- Global shared owners: Chat, Profile and Promote implementations; Work owns context and return parameters.
- No second Chat, Social composer, Wholesale flow, public catalogue, lending engine, tax engine or ledger is authorized.

## Deferred engines, not omitted product value

- Machine-learning forecasting remains rule-based restocking in MVP.
- Opaque trust scoring remains transparent trust signals.
- Lending remains a regulated-partner eligibility/status handoff.
- Tax filing remains a professional-service request and status flow.
- Complex campaign design remains four reusable Store offer templates.

These are deliberate MVP reductions in implementation effort, not removal of the retailer or consumer benefit.
