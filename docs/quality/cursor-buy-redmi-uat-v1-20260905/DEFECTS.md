# Fresh Redmi defect register

Fresh Redmi observations are being collected on installed r66.1, code 2026090501, APK SHA `30A71FE8B6696BF51400FBED5A90C3179E25CE0A6153A998F5A041657C9D35C3`. Audit is incomplete; no all-journey verdict yet.

Use `R66-UAT-NNN` only after a current-candidate observation, with exact steps, expected/actual, severity, customer/actor, screenshot/XML/log hashes, owning source, minimal proposed correction, local result and original-sequence Redmi retest. Register corresponding permanent regression incidents before implementation. Do not carry old totals of 59/75/76 forward as new findings.

## Carried source checkpoint, not fresh Redmi findings

- REG4489: featured-card vertical overflow; implemented at e2dd3bc7, local 34 focused passes; fresh Redmi acceptance pending.
- CARD-CHILD-A: compact card information allocation at large text, same source checkpoint and test coverage; device pending.
- CARD-CHILD-B: promotion host height above 140% text, same source checkpoint; device pending.
- Three unchanged-baseline store/delivery test contracts reproduce on f94cfd47; five historical R58.8.7 golden comparisons remain legacy evidence findings. No new device defect is inferred from them.

Shared Care routing, global Chat, Work/Workspace and real backend/delivery/payment adapters are Codex-owned dependencies. Record exact missing fields/events/returns if observed; do not duplicate their source in this lane. WhatsApp verification is held by founder, not a product failure.

## Fresh device findings

Evidence-tool event E01 (no product verdict): capture 021 after Ask store did not produce a remote XML hierarchy even though the uiautomator command returned zero. The helper correctly stopped when the subsequent pull failed; no PNG/JSON or Chat pass was recorded. Its stderr remains preserved. Apply REG4491's incomplete-result prevention: obtain an independently identified fresh frame/hierarchy rather than treating the missing capture as a completed observation. This is an unavailable evidence attempt, not proof that Ask store failed.

### R66-UAT-001 — Landscape catalogue viewport dominated by fixed chrome

- Severity: P2 usability/fit; owner split requires source diagnosis (Buy header layout and shared orientation/shell boundary).
- Reproduction: in-place r66.1 install; cold launch while Redmi auto-rotation selects landscape 1600x720; scroll the catalogue upwards once.
- Actual: search/order-status/filters consume y68–372 and bottom navigation starts at y560. Initial content viewport shows promotion cards but no SKU; after scrolling, recently-viewed SKU semantics have only y551–560 visible. The shell has broad side gutters and catalogue decisions require repeated scrolling in a very shallow viewport.
- Expected: the supported orientation should retain usable product decision space and reachable actions. If portrait is the intended phone policy, that shared policy must be implemented by its owner; do not silently claim landscape qualification.
- Evidence: `redmi-r66-1/001-launch-buy.png/.xml` and `002-landscape-grid-scroll.png/.xml`, per-capture JSON hashes in the external UAT directory. First screenshot SHA `D329146C0D89BCA45D76D39BF5354335F928417A79465DB753475653C29625EB`.
- Status: observed; no fix yet. Link the previously parked Codex orientation issue instead of duplicating native configuration work. Portrait inspection continues with a temporary device rotation lock, not an app fix.

### R66-UAT-002 — Active order strip mixes preparation with delivered wording

- Severity: P2 customer-copy/state clarity; candidate Buy-side owner pending exact diagnosis.
- Reproduction: current retained-data cold launch, Quick 10m selected; inspect and read the collapsed active-order strip in landscape and portrait.
- Actual: accessibility text is `Preparing your order · Delivered in 12 min`, with `40% complete, Preparing your order`; visible text truncates after `Delivered ...`.
- Expected: distinguish a future arrival estimate from completed delivery and keep essential status comprehensible. Do not infer delivery completion from a catalogue promise.
- Evidence: captures 001, 002 and 003; portrait screenshot SHA `7A19CD1A276288F245BE8A19B60798723C968943C1974997FE677CC572AC4359` and XML SHA `3541168F7CCE1C4523E4A39CA2B4B9D36D6DD47E7EB4B029664F341962DB720A`.
- Status: observed; no fix yet. Review order data is not live supplier evidence.

### R66-UAT-003 — Product detail repeats decision fields before primary actions

P2 visual density/discoverability. Fresh tomatoes repeats price, pack, availability, seller and delivery in the headline card, a separate delivered-price card, a long price/pack/delivery table and the action card. Further down, Product details, Product and pack information, Highlights and Specifications repeat brand/pack/variant again. Add requires scrolling; Visit store is several screens below the named seller. Evidence: captures 004, 005, 012, 013. Expected: retain every unique decision/policy fact, but consolidate repetition and make the existing purchase/store actions easy to reach. No unapproved wholesale redesign; exact minimal source fix to be assessed after collection.

### R66-UAT-004 — Floating cart intercepts product quantity action

P1 functional tap obstruction. After first Add on Fresh tomatoes, quantity Add-one bounds are `[592,1196][680,1284]` while floating cart bounds are `[440,1238][704,1334]`. Tapping the Add-one centre `(636,1240)` opens Cart, retaining quantity 1, instead of incrementing. Captures 006 → 007; 008 proves root-product Back continuity. After two cart drags clear the control, the same tap correctly produces quantity 2 / ₹74 (011). Expected: default floating cart never covers a primary action; keep the transparent compact design and drag capability. Confirmed Buy defect, no fix yet.

### R66-UAT-005 — Added acknowledgement announces global count for scoped cart

P2 accessibility/state consistency. Capture 006 says `Fresh tomatoes added · 2 items, ₹37` while the visible dock says `1 item ₹37`, and Cart confirms Shop has one item; a pre-existing Wholesale line accounts for the global count. After acknowledgement expires, semantics correctly says `1 item ready` (008). Expected: added acknowledgement, visible count, amount and opened scope agree; avoid mixing global quantity with Shop subtotal. No other cart was cleared to reproduce.

### R66-UAT-006 — Drag movement does not follow the user's displacement

P2 interaction. Two vertical drags from the floating-cart centre, `(568,1285)→(555,725)` over 650ms and `(560,1216)→(556,600)` over 1000ms, move the cart only about 65px and 73px respectively (009, 010), not near the requested valid destination. The first drag still leaves Add-one covered. Expected: predictable drag displacement with explicit safe-area clamping, not repeated small nudges. Exact gesture/source diagnosis pending; no claim of fixed drag behaviour.

### R66-UAT-007 — Cart Back loses the nested store-product context

P1 navigation. Main product → Visit Shree Balaji Fresh (014) → store SKU (015, visible `Back to Shree Balaji Fresh`, no global rail) → visible Cart (016) → Android Back (017). Actual: returns to the standalone root product with global rail and order strip, rather than the nested Store SKU/store return context. The cart's explicit Continue browsing Store action exists, but Android Back must preserve the entry depth too. Expected: store/SKU/scroll/cart context retained across both directions. Fresh reproduction is distinct from the correctly passing root product → Cart → Back sequence.

### R66-UAT-008 — Compact store quantity targets fall below minimum size

P2 accessibility/fit. On Redmi density 320 (2 physical px/dp), store quantity minus/plus nodes are `[64,692][122,776]` and `[170,692][228,776]`: 29×42dp, below 44×44dp. Evidence 014; normal font scale 1.0. Expected: minimum touch targets without overlapping adjacent SKU controls or shrinking text. This is the compact store grid, not the locally passed featured-card action matrix. Device interaction and equivalent layouts across Wholesale/Bulk remain to be inspected before selecting the smallest fix.

### R66-UAT-009 — Payment-choice instruction truncates at normal text size

P2 visual/action clarity. At normal 360dp portrait / font 1.0, before selecting payment, the footer visibly reads `Choose payment m...`; accessibility has the complete `Choose payment method`. Capture 043, PNG SHA `A9F408E035911DA065E6D445A1C966CEE87E388E028A1A77077716F19B1FDAE9`. Expected: the short required next action fits without ellipsis, font shrinking, wider obstructive footer or smaller touch target. Selection enables a correctly readable Review order action (044–047). Exact Buy footer owner to be selected after collection.

### R66-UAT-010 — New review purchase groups unrelated retained deliveries

P1 order identity/navigation/data consistency. Fresh two-store COD review purchase confirms `BUY-NEW-01`, exactly two deliveries `MS-NEW-01` ₹74 and `MS-NEW-02` ₹279, total ₹353 (058/068). Tap View order details: Orders shows `Purchase BUY-NEW-01 · 9 deliveries · ₹3,663`, including unrelated retained Wholesale `PO-NEW-01` ₹1290 (069). The newly submitted purchase is therefore not isolated from previous review purchases. Expected: stable collision-free purchase/order identity across in-place updates/restarts; exact purchase grouping and return navigation; never mix unrelated supplier deliveries or amounts. Capture 069 PNG SHA `15E5BDA8D5E8B2A6D64D972644A75D8182D4E77A351077AC339398785B6C4298`, XML SHA `EABC8781010795CA4E69247E3B91DBC72B23303C35A4EA41CC68142E511EBF60`. Likely local sequence/persistence contract requires diagnosis; production backend identity impact is not established. Do not delete retained orders to hide the reproduction.

### R66-UAT-011 — Route graphic implies delivery travel before assignment

P2 truthful state presentation. Tracking newly created COD order MS-NEW-01 (070/071) says packing/current, delivery partner not assigned and live updates unavailable, but the separate store-to-address `Delivery route` graphic is 40% filled and announced `40% complete, Delivery route`. Expected: distinguish order preparation progress from physical delivery travel; an unassigned courier must not appear part-way to the address. Use an honest static route/label until authoritative delivery state, without inventing coordinates, ETA or driver activity. Source and connected adapter implications require diagnosis; no live movement was observed.

### R66-UAT-012 — Tracking address sheet omits the full recorded address

P2 order verification. Address action for MS-NEW-01 (072) shows only `Basni, Jodhpur · 342005`, while the same order invoice (059) holds `Business receiving desk, Basni, Jodhpur 342005` and recipient Aarav Sharma. Expected: show the immutable order recipient and complete delivery address so the customer can verify the actual destination; retain explicit wording that editing saved addresses affects future checkout, not this order. Do not substitute the latest profile address or mutate placed orders.

### R66-UAT-013 — Product Back label disagrees with its order return

P2 navigation copy. Order tracking → Items → Fresh tomatoes detail (073/074): top Back action is labelled `Shop`, but both Android Back (075) and that labelled on-screen action (076) correctly return to Items in this order. Expected: contextual return label agrees with the actual destination (order/items), preserving the already-working return stack. Not a broken Back route and not a reason to replace the flow.

### R66-UAT-014 — Catalogue accessibility exposes implementation narration

P2 consumer-facing language. Fresh Orders catalogue (092) announces `Showing 8 of 18 in 2 independently scrollable lanes. More products load near the end.` and `Product lane 1`. The same internal lane narration was observed in the store catalogue (014). Expected: concise consumer instructions describing available products and swipe/load behaviour without implementation terms. Preserve useful accessibility count/load announcements; do not remove semantics to hide the wording. Shared Buy catalogue owner, not global Chat.

### R66-UAT-015 — Return options omit item-specific policy/eligibility context

P2 purchase-resolution clarity / provider-contract dependency. A delivered seed order dated 25 Jul exposes all return/replacement/refund options and selectable products (093, 096–103) without an item-specific window, eligible-until date, excluded-item reason or applicable policy alongside selection. Fresh tomato detail elsewhere says quality refund within 24 hours; the resolution screen does not explain which policy applies. This is a review-data observation, not proof of unlawful acceptance or a real expired return: the review adapter rejects every submit. Expected: render authoritative per-order-line eligibility/window/reason and retain support when unavailable; no invented policy deadlines or accepted refund state. Existing snapshot carries only order-level options/sourceId; the API boundary must support these facts before production. Buy UI/contract owner with Codex Workspace/backend dependency.

## Additional evidence and ownership boundaries

- E02 evidence-helper correction: capture 061 is Android DocumentsUI opened by this review invoice download, not the review app itself. Its original JSON incorrectly names the originating package because the helper read an older `mResumedActivity` rather than `topResumedActivity`. Preserve 061 unchanged with this correction. Helper now requires exactly one top-resumed activity, validates it again after hierarchy capture, records the actual package, and permits DocumentsUI only with explicit `-AllowInvoicePicker`. Fresh 062 verifies that system save step; no WhatsApp or unrelated file was opened. Existing captures 001–060 show the review flow; 061 is not an app-screen proof.
- Shared Chat observation 022 is linked to Codex-owned UAT-BUY-004–014/022 and later accepted Chat commit `30b9b8c7eb92b7ee688a40550a438175bb522e08`, absent from this baseline. Generic loading/supplier context remains a dependency, not duplicate Cursor implementation. Settled keyboard and exact store Back were independently observed.
- COD appears and selects for this Shop basket. Source eligibility currently checks Shop-only lines and amount ≤₹5000, not an authoritative customer-eligibility result. Record the required customer/supplier/payment adapter boundary with Codex; this device pass does not prove eligibility for a real customer. Do not invent new eligibility policy.
- A read-only search included one nonexistent guessed commerce-adapter path and returned exit 1. Required code was then read from the discovered `buy_v2_session.dart` and existing contracts; the failed search is not complete evidence. COD review submission was verified to use local `confirmOrder`, not a real commerce request, before the tap.
- E03 input-probe correction: trying to remove the four-character test suffix with MOVE_END/Backspace affected an earlier line, and injected Ctrl+A did not select all (082/083). No message was sent. Used the observed long-press Select all toolbar (084), restored the exact original auto-draft and verified the full text (085). These unsuccessful synthetic key sequences are not a Chat product-defect claim. Prefer observed touch selection to assumed desktop shortcuts on Android.
