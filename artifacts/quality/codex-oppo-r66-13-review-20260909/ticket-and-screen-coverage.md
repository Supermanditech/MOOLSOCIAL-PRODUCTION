# r66.13 bounded coverage

- REG4551: CLOSED for the bounded return-navigation correction. Focused10 and existing Files160 three tests pass locally; two historical44-file cycles each1497 passed/83 existing skips/0 failures; full analysis zero issues. Exact r66.13 installed hash matches. Native029–040 verify toolbar Back, Android Back, repeated visits, retained Store context and nested-sheet Android dismissal.
- REG4554: older shared Files200% heading layout, separately registered first-tap review pending.
- REG4555:14 inherited legacy shared-suite failures proven on accepted parent and current code; separate owner/contract disposition pending, no full-suite pass claimed.
- REG4556: OPEN — existing shared Files Add sheet Cancel is partly covered by Android navigation at normal text. Native037–038 preserve screenshot/XML proof; Cancel was not falsely counted as passed. Android dismissal and Store return pass. This is a separate dashboard first-tap sheet, not the r66.12 Work document-source sheet.
- REG4552/4553: existing r66.12 document closure remains preserved, not rerun or reopened by this navigation-only change.

Pre-dashboard/backend, physical200%/TalkBack, private cloud and unreviewed dashboard first-tap surfaces are not globally closed by this candidate.

## Founder verdict boundary — pre-dashboard is not globally closed

The approved normal-size screen journey has passed its recorded UI checks through review-only Pending, Clarification, Rejected-with-reason and Approved-to-dashboard. Contact field-specific correction and bounded A/B support-draft checks have r66.11 native evidence; document children4552/4553 have r66.12 native closure. r66.13 does not fabricate a complete rerun of those scenarios.

Still unqualified before an all-pre-dashboard frontend verdict:

- REG4550: native application-support failed-send/error-banner/dismissal and keyboard recovery, including physical large text. Host tests pass but cannot substitute for the missing device scenario.
- REG4549 remaining boundaries: A-after-B native reopening, attachment/failure recovery and restarted drafts; already exercised draft checks pass, but the ticket must not be labelled fully closed.
- Physical200%/TalkBack and remote cloud-provider completion. Backend-dependent account/application persistence and real OTP/admin authority remain separate, not inferred from session-local review fixtures.
- The seven retained exploratory assertions require their existing owner/contract disposition; the separate14 inherited shared-suite failures remain REG4555. Neither is a passing full-suite result.

Keep new dashboard first-tap review paused while reconciling those specific remaining frontend checks. REG4551 native completion is a bounded existing correction, not permission to declare all earlier journeys complete. REG4554/4556 belong to Files first-tap content and stay separate.

## Next ticket — dashboard first-tap review and carried-forward checks

**Ticket: DASH-FIRST-TAP-01 — Combined first-tap review and frontend correction batch.**

Founder instruction on 2026-09-09 supersedes the scheduling hold in the preceding section: carry the remaining pre-dashboard checks into this next ticket with dashboard first-tap findings. Use installed r66.13 for the screen-by-screen review; do not make a standalone APK solely for these carried-forward small corrections. This changes execution order, not test results or acceptance.

| Acceptance unit | Existing reference / next work | Current disposition |
| --- | --- | --- |
| Application support and draft recovery | REG4549: A-after-B reopening, failure/attachment recovery and restarted-draft boundaries. REG4550: error/retry banner, keyboard and dismissal. Preserve intentional unsent messages and exact application/account scope. | Existing fixes and bounded native passes retained; remaining checks pending. No duplicate defect IDs. |
| Physical accessibility | Large-text/200% and TalkBack, readable feedback, reachable actions, semantics and stable keyboard across relevant onboarding and first-tap views. Do not bypass Android security restrictions. | Verification pending, not automatically a confirmed defect. |
| Cloud documents | Provider selection/completion/cancellation/error, return navigation and original-document preservation. Private-provider access must be available and authorised; do not treat local picker testing as a remote download. | Verification/dependency pending. |
| Outstanding regression findings | Retain the seven exploratory assertions for exact owner/contract diagnosis; REG4555 separately retains the14 inherited shared-suite failures. Correct confirmed owned defects with focused regressions; coordinate others. | Unqualified findings, not silently waived or converted into passing tests. |
| Files first-tap corrections | REG4554: large-text heading. REG4556: Add-file sheet Cancel safe area. Preserve REG4551's qualified Store return and earlier Work document fixes. | Confirmed defects, open. |
| Other dashboard first-tap destinations | One destination at a time: Codex actual OPPO checks, founder input, deduplicated ticket entry, then next destination. Preserve approved dashboard placement/design. | Review pending; no blanket approval. |

Execution: collect and deduplicate this batch on the installed APK; implement confirmed frontend defects in their exact owners; run focused/local visual and required connected regressions; commit/push with clean remote equality; then build one combined successor OPPO APK and retest every changed acceptance unit. Close each unit only on its own passing evidence. An actually unsafe security, data-loss or payment issue must stop its affected journey rather than wait merely to save a build.

Live OTP, authenticated persistence, application/document authority, admin decisions, messaging and other backend verification remain explicitly separate dependencies. Do not fabricate them with review fixtures or describe this batching approval as production release qualification. Existing pre-dashboard visual approvals remain intact. No product/test source, policy/gate behaviour, APK or device state is changed by this ticket-record update.

## Dashboard simultaneous-work audit — 2026-09-09

### Scope, evidence and verdict

Founder asks for all retailer actions/states, 100 simultaneous customer orders alongside supplier deliveries and payments, and tickets for shortcomings. This is an audit/planning update within DASH-FIRST-TAP-01, not implementation, redesign acceptance, backend deployment or APK authority.

Audited source HEAD: e72d894d7693d410901180f9ce56455b727e1c01. Applies to Grocery/Kirana and Speciality Retail using their existing shared Store implementation. Preserve approved header, finance rail, central position, supply edge and bottom navigation. Do not create separate copies for the two retailer types.

**Verdict: the existing frontend can list and operate selected local orders, but the main dashboard is not yet qualified to run 100 simultaneous orders plus the complete mixed Store workload.** This is not a measured crash at 100; it is confirmed missing visibility/wiring plus untested concurrent-event behavior. Backend capacity and customer-facing authoritative promises cannot be certified from Flutter fixture tests.

Fresh command, from apps/mobile:

```text
C:/Users/jisal/develop/flutter/bin/flutter.bat test --no-pub --concurrency= 1 --reporter expanded test/work_workspace_layout_safety_test.dart --plain-name "Store queue"
```

Result: **11 passed, 0 failed, 0 skipped, exit 0**. Includes 1,000 synthetic local records at 100%/140%/200%, stable keys after arrivals, retained packing actions, stale Reject/Accept/Pickup/Track protection and cross-store selection protection. This does NOT simulate 100 simultaneously changing backend orders or qualify 100-order OPPO responsiveness.

Raw log: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/dashboard-100-simultaneous-queue-evidence-20260909-attempt1.log.
SHA-256: D24DFE14A74C4E494498D4AC16819B532D9ED47069B66ABE4DB5E88CDA8CDD04.
No product/test source changed by this audit; no new device journey, message, call, payment, integration or APK.

Source references below abbreviate:

- Dashboard: apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart; SHA-256: 4B3483E73C376CBA334E6EE3D7CCD6C35549AF9FAC94CC64BDDCB63780DBEB14.
- Session: apps/mobile/lib/features/work/work_session.dart; SHA-256: 11B127772F1CA24FC7EE1E3A37D7D96FB578D5683817C327AC7DB76D8333A387.
- Models: apps/mobile/lib/features/work/work_models.dart; SHA-256: 1375357040C74E7BA8DA9F9A0B35160B3D87429562B2E659FE052E588E5AD379.
- Services: apps/mobile/lib/features/work/work_services.dart; SHA-256: 89AB638622D0DB3D11AF2AD4C084387D138443B60A7DEC981666008B17276DF1.
- Widgets: apps/mobile/lib/features/work/widgets/work_widgets.dart; SHA-256: 2F02EC39954F107799D4AAD233ADA63CC31CF125DF0377A2CD5F3F6B35A58883.
- Existing retailer offering inventory: apps/mobile/lib/features/work/work_workspace_benefits.dart, _retailerGrowth. Its 25 entries include supplier tracking/receiving, credit eligibility and returns; descriptive copy is not evidence those destinations are implemented.

### Complete action/state inventory for this approved retailer scope

Visibility: **P** = persistent compact signal/count; **C** = exact central work surface when selected; **E** = exception preview only when actionable; **D** = daily/on-demand destination; **S** = contextual Profile/settings, not a high-priority action rail. These are proposed placements inside the approved geometry, not additional rails or separate mandatory screens. Badges are states, not fabricated actions; counts never sum overlapping payment and fulfilment dimensions.

| Work family | Retailer-facing actions | States/decision information required | Visibility |
| --- | --- | --- | --- |
| Store availability | Open store; Pause orders; Close store; change hours/fulfilment/limits | Open/paused/off separately from public/private; scheduled reopening; busy/full; stale/unconfirmed availability | P signal; S changes; E failure |
| Workspace identity | Switch Workspace; add Workspace; view public store; edit authorised business settings | Exact approved business/store scope; pending new workspace separate; permissions/session change | Header/Profile; S |
| Incoming app orders | Review; Accept; Reject; Request time | Customer/order, product+pack+quantity, paid/payment condition, delivery vs collection, acceptance deadline, request pending/approved/denied/unknown, cancellation/reassignment | P count+oldest deadline; C |
| Packing | Mark item packed; correct count; report missing item; request permitted substitution; Order ready | Exact order checklist, reserved/available stock, packing progress, blocked shortage, customer decision, fulfilment target, overdue state | P count; C checklist |
| Customer collection | Order ready; show order QR; retry/check authorisation; Hand Over; view collected order | Preparing, ready, QR waiting/checking, Customer confirmed, handover pending, Collected; invalid/expired challenge, cancelled/unpaid/stale/uncertain state | P ready count; C existing collection card |
| Customer delivery | Arrange delivery; retry assignment; contact rider/customer; record authorised rider handover; track | Unassigned/searching/accepted, rider coming/at shop, packed, picked up, out for delivery, delivered, failed/reassigned/cancelled/returning; ETA/freshness; exact rider and order | P count/E exception; C |
| Counter sale | Create bill; scan/search product; add/edit/remove quantity; save/restore/discard draft; confirm permitted payment | Draft, stock unavailable, payment due/pending/paid/failed; counter handover vs booked collection vs delivery; exact totals and invoice | Sell first tap; C |
| Customer invoice and repeat visit | View bill; send bill/link through supported channel; retry/cancel share | Correct customer/order/store/invoice, draft/hand-off-to-app vs actually delivered; no false sent status; return to original work | C/E unsent bill; D |
| Phone/chat purchase conversion | Send store link; resume prepared basket where supported | Not-installed/not-signed-in/signed-in return contract; exact public store/basket/payment purpose; contact collection after sign-in; link expired/unavailable | Existing reach strip; C; consumer dependency |
| Incoming supplier stock | Track stock; review purchase; receive quantities; report shortage/damage; attach proof; confirm receipt | Exact supplier/PO/items/packs, confirmed/packing/dispatched/arriving/partial/received/disputed/cancelled; ETA, split shipments, invoice and payment independent | Restock compact arrival indicator; C |
| Wholesale/Bulk replenishment | Restock; compare supplier; choose pack/MOQ; cart; receiving address; review/pay; track purchase | Draft, minimum quantities, terms/full delivered price, pending/failed/paid, partial delivery, order history | Existing Restock; embedded procurement; C/D |
| Direct manufacturer supply | Buy Direct; compare offer; choose quantity; order/pay; track | Manufacturer identity, valid offer/stock/MOQ, credible net saving, closing/expiry, purchase progress | Existing supply edge; C |
| Group Bulk Buying | View offer; choose share; confirm/pay; pay confirmed balance; track/receive; resolve cancellation/refund | Named stores and confirmations, exact commodity/spec, target/secured/remaining quantity, deadline, fees/net saving, pending vs paid vs secured, full/closed/failed, store-specific delivery | Existing supply edge+one relevant preview; C |
| Catalogue and stock | Add/import/scan product; edit selling price/MRP/pack/quantity; publish/hide; retire; stock count | Available/reserved/sold/low/out-of-stock; public SKU parity; private purchase cost; invalid/conflicting update; shortage/expiry where recorded | Stock; E low-stock; C exact SKU |
| Stock replenishment decisions | Restock selected SKU; review suggested quantity; request missing product; clear slow stock | Genuine low-stock/reorder need, quantity/unit match, source availability, delivered cost, no invented recommendations | Restock/Stock; E/C |
| Customer dues and payments | Collect dues; open exact bill; send permitted reminder/payment link; reconcile | Due/part-paid/paid/failed/pending/uncertain/refund; correct customer balance; confirmed provider data and last purchase/contact | Existing finance rail; C/E |
| Settlements | Settle; view deductions; track request; retry safely; correct bank issue | Eligible/held/requested/processing/paid/failed/reversed; exact bank reference; no automatic payout or double request | Existing finance rail; C/E |
| Statements and books | View statement; Sales/Purchases/Expenses; period/filter; open invoice/transaction; record supported expense | Complete paginated records, settlement/payment independent of sale, reversals/returns, unknown vs zero, currency/precision, large amounts | Existing finance rail; C/D |
| Returns and discrepancies | Review return; inspect evidence; approve/reject with reason where authorised; reconcile refund/stock | Customer return vs supplier shortage, requested/awaiting goods/received/decision/refund pending/complete/disputed; exact original transaction | E; C/D |
| Customer retention | Open customer record; repeat basket; send permitted offers; follow up; inspect purchase history | Latest purchase/contact, permission/opt-out, unpaid vs fully paid, recurring basket state; no false delivery/reach claim | D via customer/dues/offer context; E due action |
| Promotions and monthly baskets | Create/edit offer; create basket; promote/store-post; pause/end; review result | Draft, scheduled, active, expired, payment/service pending, rejection; real audience/results only | Existing Promote store; C/D |
| Outcome-based business requests | Post requirement; select sourcing/stock/partner/investment/content/social/promotion/offers/baskets/sales; specify result, budget/deadline; review response | Draft/review/clarification/published/responded/full/closed; fee or plan inclusion before posting; no false funded state | Existing Post requirement; C/D |
| Business help, plans and stock credit | Request bookkeeping/GST/ITR/audit help; review service scope/fee/plan; check credit eligibility/terms | Request pending/accepted/needs information/complete; plan entitlement; credit unavailable/assessment/eligible/declined/due, only from authority | Profile/D; E only if action due |
| Communication | Open exact customer/supplier/rider/support Chat; Call when a valid number exists; read/reply | Correct identity/order/store, unread/unsent/sending/failed, unavailable channel, preserved draft and exact return | Global contextual Chat; E; C exact item |
| Alerts and exceptions | Open exact affected item; acknowledge/dismiss only when safe; retry/reconcile | New order/late packing/rider arrival/stock shortage/supplier discrepancy/payment exception/service response; severity, age, stale/resolved | Existing Alerts+P counts; C |
| Continuity and staff | Resume work; reconnect/retry; switch authorised counter/store; recover draft | Loading/saved/offline/stale/reconnecting/confirmed; permission revoked; another counter owns action; pending operation known/unknown | P small freshness signal; E/C; S permissions |

Do not put all these words on the first screen. Persistent visibility is limited to workload groups, financial balances, supply arrivals, operating/freshness signals and exception counts. Selecting a group replaces only the central work area. History, configuration and occasional business services stay contextual. Preserve readable labels, minimum touch targets and an accessible alternative when enlarged text cannot fit the same geometry.

### Confirmed current wiring and capability gaps

1. Dashboard _StoreControlDashboard:2505 and _StoreActivityDeck:3184 show one selected order/task; there is no persistent multi-order action-count row. A selected collection takes precedence; other business states remain behind their destinations.
2. Orders destination12662 uses stable keyed ListView.builder and state counts. This is useful existing implementation, not 100 independent cards rendered all at once. Its filter buckets are All/New/Packing/Ready/History; no dedicated delivery/overdue/exception group. It preserves source list order rather than explicit nearest-deadline priority.
3. _LiveOrderTicket:12920 gives a non-selected order an Open order step before its action. Selected collection opens back into the central card. Do not claim every current order action is first-tap.
4. _workspaceSearchRecords:18580 inspects catalogue, current order/current customer and activity. It does not enumerate all100 orders, their customers and invoices; the order result routes to generic orders without its ID.
5. _workspaceAlerts:18659 derives one generic customer-order alert from the current order. It does not enumerate all waiting order/payment/supplier exceptions, and does not test current order closure before adding that alert. Exact alert-to-order addressing is missing.
6. Session:1246 selection and Dashboard:12940 row guards block other-order work during store-wide busy/sync/handover or uncertain collection/time work. Session:2007 serialises complete operational snapshots per change. These safeguards prevent stale writes but do not establish independent 100-order operation; they must be replaced only with equivalent order-scoped safety, never simply removed.
7. workspaceMaximumActiveOrders defaults 8 and is clamped 1–100 when saved (Session:329/2082). The audited uses are storage/settings; no load projection/admission calculation consumes it. This is not an enforced per-device or server capacity ceiling.
8. The optional time-request contract in Services:462 exists; Session:716 safely handles identity, pending and rejected/uncertain results. It is not a complete workload feed, and ordinary gateway implementations do not declare WorkOrderTimeGateway. Automatic permission to extend 100 orders is not implemented.
9. _DeliveryDestinationSurface:13213 uses only the current order. Models:170 delivery assignment holds order/name/vehicle/ETA/stage, no GPS coordinate/freshness stream. Map in _DeliveryActivityCard searches the customer address, not a live rider location.
10. Procurement is already embedded through openScopedRoute721/_StoreProcurementSurface; do not copy Cursor Buy. But the main supply edge2625 only shows low-stock/group-offer details. It does not show inbound supplier shipments. Statement Purchases/Expenses:7498 unconditionally renders empty content; it is not a linked purchase/receiving ledger.
11. Work Models:58 uses generic string payment/stage for ordinary orders. Payment, fulfilment, claim/revision and exception projections are not modelled as a complete independent chain. Session:2495 local ordinary completion increases both sales and settlement balance, so authoritative receivable eligibility and cash/credit/refund separation require explicit qualification; this is a source risk, not evidence a real customer was overpaid.
12. Stock movements are trimmed to 100 in Session:2850 and only 12 are displayed in Dashboard:10120 without a continuation in that surface. This cannot be called a complete high-volume stock statement or audit trail. Supplier receiving and return reconciliation are not delivered by generic product import.
13. activeGroupBuy is a single object. Main group destination8008 gives an empty state when absent; _ActiveGroupBuyView:12070 is a detail view without retailer share/payment actions. The older creation form is not reached by that empty entry. Concurrent offers, join/balance/refund and per-store fulfilment remain incomplete; a create reference is not a payment receipt contract.
14. _retailerGrowth promises Track stock/Receive goods/Review returns/Check eligibility, but their complete Store operational journeys were not found in the audited operation routing. Business books fallback8182 is descriptive; business services8277 opens support Chat, not a completed filing service.
15. Contextual Chat exists, but delivery:4999 uses customer display text as recipient and no exact order ID. Some local operation navigation is widget state rather than URI, so a generic route return alone cannot prove restoration of the selected delivery/customer/bill. Existing support draft fixes must be reused, not duplicated.
16. Loading/offline/failed dashboard presentation6046 and collection authority guards already exist. The general WorkGateway:493 does not provide a complete versioned order/payment/supplier live-feed/reconnect contract. Never replace this explicit dependency with animated fixture activity.

### Execution tickets — added to DASH-FIRST-TAP-01, no duplicate prior defects

All below remain **OPEN / implementation not started**. Source-confirmed gap, integration dependency and missing test coverage are distinguished. P1 is operationally essential; P0 denotes a production safety/financial gate, not proof of an incident in the isolated review APK. Exact edited owners and shared ownership must be checked at implementation time.

#### DASH-LOAD-01 — P1 · Visible workload and direct central actions

- Users: Grocery/Kirana and Speciality Retail; shared dashboard.
- Gap: one selected task hides other queues; non-selected rows need Open order before action (evidence 1–3).
- Smallest correction: compact Accept/Pack/Hand over/Track counts inside existing centre; selected group opens exact actionable rows, not a new landing page. Include oldest due/overdue and user-retained selection; separate collection/rider readiness within the selected group. No automatic carousel, bulk accept or button relocation.
- Acceptance:100 active mixed orders; count partition correct; queue priority visible; safe action reachable on first selected-task view; no duplicate Orders entry or hidden urgent work. Preserve keyboard/draft/scroll and existing stale-action guards.
- Owners: Dashboard, Session, existing layout/atomic tests; depends on 05/14 authoritative timing/state definitions.

#### DASH-LOAD-02 — P1 · Search every order, customer and invoice

- Gap: current-order-only search and generic return target (evidence 4).
- Correction: reuse existing inline search with all scoped order/customer/invoice records, stable exact IDs and typed result intent; retain catalogue behavior and supplier-purchase search once07 supplies its projection.
- Acceptance: find order 99 without selecting it first; exact customer with same name; exact invoice; closed order history; no cross-store results; first tap opens exact item; Back restores query/selection/scroll.
- Owners: Dashboard search/route adapter, Session selectors, focused tests. No Cursor source edit.

#### DASH-LOAD-03 — P1 · Correct alerts and urgent event addressing

- Gap: generic current-order alert, no state-based100-item coverage (evidence 5).
- Correction: deduplicated order/payment/shipment/stock exception projections with entity ID, action, age and resolution; keep Alerts position. Never show a completed order as needing delivery merely because its customer text remains set.
- Acceptance: simultaneous alerts reconcile with counts; tapping late order 99 selects 99; resolved alerts disappear; required unresolved action is not silently lost; no repeated sound/blink storm or sensitive text exposure.
- Owners: Dashboard alert builder, Session projection, tests; backend event delivery dependency 14.

#### DASH-LOAD-04 — P0 · Independent order actions and uncertain-operation safety

- Gap/risk: global busy/sync/pending guards and whole-store snapshot writes can block unrelated orders; a failed A time request prevents choosing B (evidence 6/8).
- Correction: order-scoped mutation tokens, retained reconciliation and safe concurrent reads/actions for unrelated orders; preserve store/account isolation and duplicate protection. Never remove the current safeguards before scoped equivalents exist. Define versioned/deduplicated writes with 14 rather than sending competing full-store overwrite snapshots.
- Acceptance: A has uncertain extension or handover while B accepts/packs; A remains protected; delayed A reply cannot change B or a new workspace; retry uses same operation identity; duplicate completion/invoice/stock/payment effects never occur.
- Owners: Session, scoped service contracts, atomic tests; live server enforcement pending14.

#### DASH-LOAD-05 — P1 · Honest capacity, acceptance and delivery promises

- Gap: stored 8/default and 1–100 setting is not enforced; no live workload projection; timing adapter optional (evidence 7/8).
- Correction: show server-reported load/capacity and current deadlines, pending extension and confirmed result; keep availability configuration in Profile. Define queued/not-yet-assigned/accepted distinctions and customer-facing promise contract with consumer owner. Do not present a local per-device setting as a server guarantee.
- Acceptance:100 arrive together; nothing auto-accepts or fabricates10-minute delivery; expired/unknown/reassigned order cannot be accepted locally; permitted extension changes only that order after confirmation; all dependent consumers see authoritative updated promise. Local countdown expiry says awaiting update, not falsely reassigned.
- Owners: Session/timing gateway/central and queue UI/tests. Backend admission and consumer synchronisation explicitly separate.

#### DASH-LOAD-06 — P1 · Full customer fulfilment and delivery queue

- Gap: single selected delivery, incomplete stage buckets, address map presented as only map action (evidence 2/9/11).
- Correction: independent stage/fulfilment projections with exact next actions; list all rider deliveries, customer collections and their exceptions. Reuse collection central card and existing delivery widgets; include fresh rider GPS only when supplied, otherwise honest latest update.
- Acceptance: packing, rider-at-store, customer-confirmed collection and delivered events coexist; readiness only on explicit retailer action; rider handover is not customer delivery; customer collection never falls through merchant-only/legacy completion; cancellation/reassignment/partial fulfilment represented; changing selection loses nothing.
- Owners: Dashboard, Models, Session, Widgets, existing collection contract/tests. Coordinate consumer/rider/backend contracts; do not rewrite their owners.

#### DASH-LOAD-07 — P1 · Supplier arrivals, receiving and Store purchase ledger

- Gap: embedded procurement exists but Store inbound tracking/receiving/linked purchases are absent (evidence 10/14).
- Correction: thin Store-context adapter around accepted Buy purchase records; Restock arrival count; exact supplier purchase/tracking/receiving in centre. Record delivered vs ordered packs, partial receipt, shortage/damage and linked invoice; stock changes only from confirmed receipt. Reuse existing procurement, cart, checkout, orders and address flow.
- Acceptance:8 incoming shipments alongside 100 customer orders; purchase from Store remains Store-scoped; two suppliers same SKU don't merge incorrectly; split delivery/return/cancel and Back restore exact purchase; no personal purchase leakage or double stock posting.
- Owners: Codex Store adapter/receiving UI/Session; Cursor Buy read-only contract coordination; backend receipt/purchase ownership pending.

#### DASH-LOAD-08 — P0 · Independent payment and settlement states

- Gap/risk: string payment with local completion/balance mutation is not authoritative sales-receivable qualification; purchase/expense statement branches are empty (evidence 10/11).
- Correction: typed provider outcome and reconciliation projection, exact transaction/bill/settlement links; separate customer cash/direct payment, platform-held paid sale, credit/due, pending/failed/refund and settlement eligible/held/requested/paid. Existing amount layout and full exact values retained.
- Acceptance:25 payment updates overlap100 fulfilment states; paid does not mean delivered and delivered does not mean platform cash held; no duplicate settlement; no false zero when service unavailable; amounts through 100–1,000 crore, fees/precision/negative adjustments fit. Purchases/expenses use actual scoped data or explicit unavailable state.
- Owners: Store Models/Session/finance surfaces/tests; authoritative payment/ledger contract 14. No payment-provider or regulatory action in this UI ticket.

#### DASH-LOAD-09 — P1 · Returns, item shortages and corrective action

- Gap: Review returns/receiving commitments lack complete routed Store action; refund total alone is not a return journey (evidence 12/14).
- Correction: reuse central detail/checklist/attachments and original order/PO references for customer returns, packing shortages and supplier discrepancies; record permitted choice/reason, customer confirmation if substituting, payment/stock consequences pending authority.
- Acceptance: wrong/missing item, refused substitution, partial return, damaged supplier carton and cancelled order never silently complete; clear responsibility/next action; repeated submission no double refund/restock; keep collection safety unchanged.
- Owners: Store detail/state adapters/tests; policy/consumer/supplier/backend decisions remain explicit dependencies, not invented entitlements.

#### DASH-LOAD-10 — P1 · Complete stock history and public SKU consistency

- Gap: local100-movement truncation and 12-row display without complete history continuation (evidence 12).
- Correction: treat limited records as a labelled recent preview, not the complete ledger; add scoped paginated/date-filtered history/receipt links using existing statement surface. Match stock units, pack/MRP/selling price/availability to Buy public contract; private cost remains private.
- Acceptance:100 orders with several SKUs produce more than 100 movements with no silently lost auditable history; matching/reservation/release/receipt/return exactly once; stale SKU update cannot oversell; long names, large figures and 5,000-item catalogue remain usable.
- Owners: Store Session/Models/catalogue/statement/tests; authoritative stock ledger and Cursor public mapping dependencies. Do not create a copied public catalogue.

#### DASH-LOAD-11 — P1 · Multiple supplier offers and actionable group purchase

- Gap: one activeGroupBuy; no active-offer selection/join/balance action in routed detail; creation path/receipt semantics incomplete (evidence 13).
- Correction: scoped offer list with stable selected deal, lifecycle and per-retailer quantity/payment status; reuse current price/spec/participants components. Manufacturer offers remain embedded Buy products, not duplicated checkout.
- Acceptance:4 group offers and manufacturer offers change while orders are being packed; first confirmed payment publishes only on authority; other retailers choose/share/pay, deadline/full/failed/cancel/refund/arrival handled; savings include disclosed charges; no selection jump or false paid state from a generic create reference.
- Owners: Store offer adapter/Session/UI/tests; admin/payment/consumer trade and Cursor purchase contracts pending.

#### DASH-LOAD-12 — P1 · Exact communication, share and return context

- Gap: delivery Chat uses display text and generic URI without exact order; local operation depth may not survive external entry/return (evidence 15).
- Correction: reuse shared Chat/draft context contract with stable account/store/order/customer/rider/supplier identity; typed purpose and exact origin. Call unavailable/failed states explicit; invoice/link share must not claim message delivered from successful app launch.
- Acceptance: support/rider/customer/supplier with same names remain distinct; draft preserved while100 events arrive; cancel/app switch/Back/relaunch restores exact item and unsent text; no real WhatsApp/call/send in automated review. Public-store-link auth resume coordinated, not invented.
- Owners: Store adapters plus exact shared Chat owner coordination; reuse REG4549/4550 carried-forward work, do not duplicate it.

#### DASH-LOAD-13 — P1 · Reachability of daily business actions and truthful copy

- Gap: some approved retailer offerings lead only to descriptive/help surfaces; retained generic wording differs from approved precise actions (evidence 14 and operation titles).
- Correction: inventory all 23 existing _WorkspaceOperation routes plus 25 retailer offering entries; mark each implemented, request-only, dependency-held or unavailable. Ensure customer records, repeat basket, invoices, offers, Post requirement, tax help, plans and eligibility have a deliberate first-tap/context route. Keep rare configuration in Profile; no large new tile grid or repeated hero. Audit actual mounted customer-facing labels for internal strings and inconsistent readiness wording.
- Acceptance: every offering maps to a reachable purposeful view or honest dependency state; no fake complete filing/credit/promotion service; fees/plan inclusions shown before request; default/public/store identity correct; returning from every first tap restores centre and draft.
- Owners: Dashboard/benefit wiring/scoped shared entries/tests. Exact service/backend admission separate; no blanket new feature authority.

#### DASH-LOAD-14 — P0 · Versioned live-state and restart integration contract

- Gap/dependency: no complete general Store order/payment/purchase feed or event version/reconnect contract in WorkGateway; collection/timing already have stronger narrow safeguards (evidence 6/16).
- Correction: define minimal typed snapshots/events/capabilities/freshness/expected revision/op IDs and per-store/account reconciliation, reusing existing services. Distinguish optimistic local draft, submitted command, authority-confirmed result and unknown outcome. Do not deploy backend or count fixture success as authority.
- Acceptance: duplicate/out-of-order/missing events, offline reconnect, process restart, another counter action and permission/store switch never overwrite new state, duplicate money/stock or leak accounts. Unknown state never says live/paid/collected. Backend implementation and integrated consumer/retailer/rider qualification remain explicit.
- Owners: Codex shared Store contract definition with consumer/Buy/backend owners coordinating exact schema; independent branch discipline unchanged.

#### DASH-LOAD-15 — P1 · 100-simultaneous mixed-workload UI and device qualification

- Gap:11 passing focused queue tests prove local list/safe selection only; no comprehensive 100-live-order mixed-event/OPPO performance proof.
- Correction: deterministic frontend replay using existing fixture/test harness, bounded virtualised lists and change notifications; add no test-only approval authority to production. Test stable controls/scroll/composer and adaptive centre under continuous realistic updates. Profile debug correctness separately from profile/release performance.
- Acceptance dataset:30 awaiting acceptance + 20 packing + 10 ready customer collections + 5 customer-confirmed collections + 15 ready/waiting rider + 15 out for delivery + 5 exception orders = 100 unique active customer orders. Payment states overlay those same IDs, not extra orders. Add 8 inbound supplier shipments, 4 group offers, 2 settlement updates, an unsent counter bill and a Chat draft.
- Replay: burst arrivals, expiry/time approval, cancellation while selected, partial packing, duplicate/reordered payment/stock events, rider/consumer updates, supplier partial receipt and offline/reconnect. Update one order while retaining another; no button movement during touch; completed history does not consume active screen. The 100th/1000th row reachable with correct action and no whole-list eager build.
- Viewports 100%/140%/200%, compact 320px and OPPO; keyboard open, TalkBack, reduced motion, long/localised text, 100–1,000 crore, app switch/Back/lock/relaunch. Record memory/frame/tap latency and sustained-run method/device/build; do not claim throughput from fixture count alone.
- Owners: existing Store layout/atomic tests and existing capture harness. Physical/cloud checks carried from the earlier batch are reused, not duplicated. Full authoritative load test belongs to backend/integration qualification.

### Founder clarification — more than 1,000 daily orders and many state updates

The 100-simultaneous scenario is an audit case, not an approved product limit. On 2026-09-09 the founder explicitly asked for more than 1,000 actions/states over a day. Extend DASH-LOAD-01/02/03/04/05/07/08/10/14/15; do not create duplicate tickets.

- Separate three measures: total orders/transactions during a period; currently active orders/tasks; and incoming state-change events. One order can generate several events, and its payment and fulfilment dimensions can overlap. Do not count every event as a new order or add overlapping state totals.
- Preserve complete searchable, filtered, paginated history through the authoritative data contract. A bounded local cache and recent-activity preview must not silently become the full ledger. Do not eagerly download/render all historical rows on every update.
- The dashboard shows compact workload counts, oldest deadline and actionable exceptions; the centre renders only the selected scoped queue/task. Supplier arrivals, customer deliveries, payments and returns retain separate meaningful counts. Completed work leaves the active queue but remains in history.
- New events must not steal selection, move the tapped control, overwrite drafts or trigger continuous alerts. Aggregate notifications, deduplicate events, reconcile revisions and show freshness honestly. Prioritise deadlines and waiting age without hiding lower-frequency supplier or financial exceptions indefinitely.
- Extend local qualification to proposed history datasets of 1,000 and 10,000 orders/transactions per day, with multiple state updates per record. Separately exercise 100 and 1,000 active mixed-order UI records plus supplier/payment events; the larger active case is a stress scenario, not a claim one retailer can fulfil them at once.
- Record sustained and burst event rates, event backlog, device frame/tap latency, memory and correctness under restart/reconnect; define acceptance budgets before implementation. Do not infer throughput from list length or call a 1,000-row fixture a 1,000-simultaneous server test.
- Backend must later enforce store/account-wide assignment, capacity, inventory and payment authority across counters/devices. The UI displays those truthful limits and permitted time changes; it must neither impose an arbitrary 100-order lifetime limit nor promise unlimited throughput or 10-minute fulfilment while overloaded.

Current qualification remains exactly the 11 focused local queue tests recorded above. The expanded scenarios are OPEN acceptance work, not passed tests.

### Dependency-aware execution order and closure rule

1. During current first-tap review, capture real visual/navigation issues and add founder inputs without duplicating these root-cause tickets.
2. Define 05/06/08/14 state/capability boundaries first; implement 04 without weakening existing guards. Build 01/02/03 projections against those definitions.
3. Reuse Buy for 07/11; complete 09/10 and 12/13 in their scoped destinations. Exact shared ownership must be confirmed before edits; no Cursor dirty worktree or integration mutation.
4. Run 15 and the carried-forward pre-dashboard checks; combine qualified fixes into the agreed next APK, not one APK per ticket. Review only is permitted on current r66.13.
5. All 15 audit children are open. They are a mixture of confirmed frontend shortcomings, coverage work and explicit backend/consumer dependencies. Do not represent them as 15 reproduced OPPO crashes, silently close old pending checks, or claim all current dashboard journeys are production ready.

## OPPO dashboard / first-tap audit — 2026-09-09, bounded round completed

Founder limits this round to the dashboard, its states and first-tap destinations. The prior DASH-LOAD inventory is the complete requirement map, not permission to implement deeper checkout, external sending, money movement, backend deployment or later screens. For each ticket, implement only its dashboard projection, exact first-tap action/state, recovery and frontend contract in this round; retain deeper execution as a named dependency.

Device: OPPO 2b3e0f71 only, r66.13 runtime 2026090903. Installed base.apk SHA-256 independently re-read: 51CCCCEDA86C1DA803B4919467C3CF7BFAC9B5A1A6E40CD3A76B2E23143B3C10. Redmi untouched. Source unchanged. QA Store OPPO-QA-r6612-Document-Test is off/private with no recorded orders, stock or customer dues; populated/live/large-load states cannot be qualified from its empty state.

Native evidence continues without overwriting earlier captures: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-13-native-20260909, starting 041.

Bounded checks through capture 077:

- 041–043: dashboard and compact read-only status panel. Both statuses are visible; Android Back restores the same Store.
- 044–052: statement first view, Purchases tab, period menu/Month, Collect dues and zero-balance Settle; correct return each time. No populated statement, eligible payout or payment transaction tested. Purchases adapter remains DASH-LOAD-07/08.
- 053–058: setup alert, inline Search, nonmatching ZZQA1000 query, keyboard dismissal then dashboard return. Keyboard field and feedback fit. No all-order search qualification; DASH-LOAD-02/03 remains open.
- 059–064: Store-context Restock, manufacturer offer list and empty Group Bulk Buying, each with dashboard return. Do not treat older embedded Buy content as latest Cursor acceptance. Store wrapper/offer decision information remains DASH-LOAD-07/11/13.
- 065–068: Orders empty view, Packing filter and horizontal reveal of Ready/History. No delivery/exception bucket appears; deduplicate into DASH-LOAD-01/06. No 100-order native test claimed.
- 069–075: Sell empty bill; customer editor; keyboard; short-number error for 123; Close cancels and preserves the blank bill; Back restores dashboard. No customer saved or invoice created.
- 076–077: Stock first view and More product tools sheet. A new bottom-inset defect is visible, below.

### DASH-FIRST-TAP-02 — Product-tools sheet bottom inset

Durable incident: REG4558. No source fix yet.

- State: OPEN; OPPO-confirmed on 077-stock-tools-state.png/XML, normal font.
- User/outcome: Grocery/Kirana retailer can read and reach every product tool from the Stock first-tap destination; the same shared presentation also serves Speciality Retail.
- Reproduction: dashboard → Stock → More product tools; the last Open stock statement description reaches the Android navigation boundary and is visibly clipped. Do not confuse this with the visually fitting read-only Store status panel.
- Correction scope: existing Work sheet layout only; content-sized height with actual bottom inset, bounded scrolling when necessary, accessible dismissal and full final-row touch area. No new destination or duplicate stock statement.
- Verify normal/large text, keyboard transitions if reused by an input sheet, both Back mechanisms, final-row scroll/reach and original Store context. Do not relabel existing shared Files defect REG4556 as closed; its owner is distinct unless source tracing proves a common fix.

### DASH-FIRST-TAP-03 — Counter-bill customer mobile validation

Durable incident: REG4559. No source fix yet.

- State: OPEN source-confirmed validation gap; native short-number rejection passes on 073. Overlength/alphabetic acceptance has not been exercised by saving a customer.
- Owner: existing _StoreSaleCustomerSheetState._confirm in work_workspace_dashboard_screen.dart (around 17580); it strips nondigits and tests only length < 10.
- User/outcome: Grocery/Kirana retailer adds the correct customer contact to the counter bill; the shared Speciality Retail flow gets the same correction.
- Correction scope: reuse existing canonical mobile validation/normalisation; accept supported country-prefix formatting, reject excess digits, letters and invalid supported numbering forms. Show field-specific correction, retain input and allow Cancel without saving. Never treat format validity as verified identity or send an OTP automatically.
- Verify malformed/valid formatted contacts, correction/retry, recent-customer selection, keyboard/large text, unsent bill retention and Back. No actual message, invoice publication or payment required for this first-tap ticket.

Audit-runner incident REG4557: capture 084 succeeded, but a guard then expected the off-screen Bring customers back heading after keyboard dismissal. Promotion fields, selected shortcut and the same Store remained visible; retained scroll is not a navigation failure. The guarded subsequent 085/086 actions did not run in that invocation; they were performed only after registration and refreshed passing gates. An overbroad registry inspection truncated unrelated historical output. A later source lookup included an absent ui_v2/chat path; the existing features/chat owner was subsequently read directly. No missing output or partial failed lookup is qualification evidence.

### DASH-FIRST-TAP-04 — Shared Chat first-view inline search

- State: OPEN, native presentation confirmed on 092; durable REG4560. This is a child of existing DASH-LOAD-12/13, not a new Chat implementation.
- User/outcome: Grocery/Kirana retailer enters contextual Chat without a boxed/truncated search or duplicated idle search symbols. Speciality Retail reuses the same shared Chat.
- Evidence: Search conversati... is clipped in a pill-like wrapper, with both leading and trailing search icons. Existing chat_inbox_screen.dart around 695–731 declares both icons; InputBorder.none alone does not establish the actual rendered inline treatment.
- Scope: exact existing shared Chat search/wrapper and focused tests, subject to current owner check; retain compact New conversation, filters, query, drafts and Store return. Do not change thread sending or Cursor Buy. Coordinate with REG4549/4550 rather than duplicating their error/recovery scope.
- Acceptance: full professional search label, one clear search affordance, query/clear/close/keyboard states, 100%/200%, touch targets, focus/semantics and exact Back. Current native Chat entry/Back passes; this is not all-Chat acceptance.

### DASH-FIRST-TAP-05 — Select the retailer's actual first product

- State: OPEN; native102 plus source-confirmed; durable REG4561. Reuse DASH-LOAD-10/13 catalogue work.
- User/outcome: Grocery/Kirana retailer chooses the product/pack actually sold before setting price and quantity; Speciality Retail must not be forced through an unrelated grocery default.
- Current Continue store setup chooses existing catalogue.firstOrNull or workspaceMasterCatalogue.first; the QA first view displays Fortune Sunflower Oil with Add but no in-view chooser. Dashboard Add products instead reaches the already-existing Stock catalogue.
- Scope: reuse the existing catalogue selector/editor inside this same first-tap setup surface; retain exact SKU/pack/private cost/public selling-price mapping, deliberate selection, cancellation and existing Store return. Do not build another catalogue, reintroduce pre-dashboard documentation or change business type approval.
- Acceptance: empty/existing catalogue, actual chosen SKU rather than default substitution, long labels, unavailable product, Back/cancel/draft and large text. Keep pricing-validation review linked to DASH-LOAD-08: this setup uses int.tryParse(... ) ?? 0; verify supported decimal/minor-unit rules and reject malformed amounts without silent zero substitution before any live save. No product or price was saved in this OPPO audit.

### Native round completion and evidence

Captured **63 PNG/XML/log sets, 041–103** across **23 dashboard controls/entries and their bounded states/returns**, not 63 separate screens. The extra entries include multiple ways to reach the same existing destination; they do not authorise duplicate pages.

Manifest: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/oppo-r66-13-native-20260909/dashboard-first-tap-audit-041-103-manifest.json.
Manifest SHA-256: 73D45BFC1F68C519AEA0434184A4BAE3B3BC525351F4E6EB1864D7FCBBF446E1.
The manifest binds all 189 files and their byte sizes/hashes (9,534,775 bytes total). Prior001–040 evidence and manifest-v1 are untouched.

| Dashboard entry / state | OPPO evidence | Bounded result / ticket |
| --- | --- | --- |
| Store status | 041–043 | Taking orders Off and Storefront Private both visible; compact read-only panel; Back retains Store. No state toggled. |
| View statement | 044–048 | Sales/Purchases entry, period menu and Month selection fit and respond; Back retains Store. Populated data/linked purchase ledger remain DASH-LOAD-07/08. |
| Collect dues | 049–050 | Honest no-dues view and Back. No reminder, collection or paid-account history exercised. |
| Settle | 051–052 | Zero recorded balance, breakdown and disabled Review payout; Back. No eligibility/payment qualification. |
| Alerts | 053–054 | One setup alert matches this QA Store; Back. Multi-order/exception addressing remains DASH-LOAD-03. |
| Inline Search | 055–058 | Focus/keyboard, ZZQA1000 no-result response and two-stage Android Back work. No record search success in empty Store; DASH-LOAD-02 remains open. |
| Restock | 059–060 | Existing Store-scoped embedded procurement opens and returns. Large wrapper/shortcut height is a first-view compaction review under DASH-LOAD-13, not permission to redesign Cursor Buy. |
| Buy Direct | 061–062 | Manufacturer offer list opens/returns. Product/pack/price/dispatch shown; unit comparison, minimum total, fees and supportable saving need DASH-LOAD-11/13. Do not fabricate missing comparison data. |
| Group Bulk Buying | 063–064 | Honest empty view and Back. Multiple live deals/commitments/arrivals remain DASH-LOAD-11; no payment or subscription tested. |
| Orders | 065–068 | Empty active queue, Packing filter, horizontal Ready/History reveal and Back. Missing dedicated delivery/exception overview maps to DASH-LOAD-01/06, not another duplicate ticket. |
| Sell | 069–075 | Blank bill, customer editor, keyboard, short contact error, Close without saving and dashboard return. REG4559 covers remaining format gap. |
| Stock | 076–079 | Catalogue entry, tools sheet and Back; REG4558 records clipped final subtitle. No SKU imported/published/changed. |
| Send store link | 080–081 | Correct unavailable/setup prerequisite state for off/private Store; Back. No WhatsApp, share, public link or auth-resume test. |
| Promote store | 082–085 | No-public-products/no-opt-in state and disabled publication; field focus, keyboard dismissal, retained scroll and dashboard return. No offer saved or published. |
| Post requirement | 086–087 | Compact ten-choice selector is visible and Close restores dashboard. Category selection/submission beyond this selector was not executed. Service fee/entitlement and posting states remain dependencies. |
| Choose Workspace | 088–089 | Active QA Store separated from saved application; Request another Workspace visible; Back. No switch to another account/application or new request made. |
| Profile | 090–091 | Contextual drawer shows current Store and access/settings; Back preserves dashboard. No nested account/security/provider action. |
| Chat | 092–093 | Inbox shows two support threads and returns correctly. REG4560 records first-view search presentation; no thread/message/send tested in this round. |
| Central Delivery or pickup | 094–095 | Inline choices expand/collapse within dashboard; no setting changed. Normal-size centre and actions fit. |
| Scanner | 096–097 | Scanner entry has Scan now/Enter code and Close returns to Store. UI XML reports both actions enabled. Camera image is black in capture; lens scene and image-read pipeline were not controlled, so this is neither a camera-failure finding nor scan-success evidence. Manual entry/product decoding remain untested; Cursor-owned implementation unchanged. |
| Mool | 098–099 | Global menu opens in place and Android Back closes it. No other module opened. |
| Central Add products | 100–101 | Reuses Stock first view and returns; no new product added. |
| Continue store setup | 102–103 | Existing setup first view and Back; REG4561 records fixed-first-product gap. No Finish setup, price or availability mutation. |

Final device state: same OPPO QA Store dashboard, off/private, setup0/2, zero orders/stock/dues. No messaging, calling, payment, publication, real order change, account clear, device setting change, APK installation or Redmi action.

### Implementation scope lock — dashboard, states, first tap only

**19 open dashboard acceptance children:** DASH-LOAD-01–15 plus DASH-FIRST-TAP-02–05. These are not 19 reproduced native crashes. REG4557 is an audit-runner incident and is not included as a product ticket. Older carried-forward Files/support/accessibility/regression checks remain in DASH-FIRST-TAP-01 without duplication.

| Existing ticket(s) | Implement within this round | Explicitly held beyond this round |
| --- | --- | --- |
| DASH-LOAD-01/02/03 | Dashboard counts/priority/freshness; selected queue/central state; exact search/alert-to-item addressing and Back | New deeper order-detail journeys unrelated to the central/first-tap work |
| DASH-LOAD-04/05/06/14 | Order-scoped frontend state/recovery; typed readiness, timing, payment, rider/collection and load contracts; safe disabled/pending/unknown states | Server capacity/assignment/security enforcement and live consumer/rider integration; no fixture qualifies them |
| DASH-LOAD-07/11 | Incoming-supply and deal previews/counts; exact first-tap tracking/offer state; thin accepted Buy return/identity adapter | New cart/checkout/payment/receiving completion backend or copied Buy screens |
| DASH-LOAD-08/09/10 | Exact money/stock/return summaries, transaction/stock first view, validated first-view fields, pagination contract and exception entry | Actual settlement/refund/ledger execution, tax work and full downstream return journeys |
| DASH-LOAD-12/13 | Existing first-tap wording/label fit, relevant actions, Chat/link context and honest unavailable/entitlement states | Real external sends, promotion/requirement publishing, filing/credit service execution and unrelated shared-screen redesign |
| DASH-LOAD-15 | Controlled local mixed-state fixture replay/captures and subsequent OPPO UI qualification for the above | Production/server throughput claims or claims that one retailer can fulfil 1,000 concurrent orders |
| DASH-FIRST-TAP-02–05 | Exact sheet inset, sale-contact validation, shared Chat first-view search, and setup product selection corrections | New onboarding flows, duplicate catalogue or broader product redesign |

Pending scenarios must remain explicit: populated active/overdue/exception customer queues; 100/1,000 simultaneous mixed-state replay and larger daily history; real supplier/GPS events; approved/denied/unknown timing changes; order-specific collection authorisation; loaded dues/settlements/returns; populated search/alert identity; interruption/relaunch and multi-counter updates; physical200%/TalkBack, remaining cloud/support recovery and genuine barcode decoding. Empty QA views cannot close these.

The approved main dashboard geometry is preserved. Correct first-tap fit/decision hierarchy through existing components, not additional rail layers, giant hero cards, new landing pages or duplicated business logic. Implement only after exact current owner checks and focused regression plans; no product/test source was changed by this audit.
