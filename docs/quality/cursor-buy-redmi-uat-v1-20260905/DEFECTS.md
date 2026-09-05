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

### R66-UAT-016 — Sparse search results waste most of the product viewport

P2 visual density/fit. Search `tomato` produces two matches. With keyboard open (109) and after Finish search (111), each match occupies its own independently scrollable row with one narrow card, leaving roughly two-thirds of each row empty. The second product drops below the keyboard while it could fit alongside the first. Expected: adapt row/column allocation to the actual small result count, retaining all product information, readable text and minimum targets; preserve normal multi-item browsing and motion. No global card redesign or font shrink. Source grid owner requires focused 1/2/few-result and large-text regressions.

### R66-UAT-017 — Saved product Back drops the saved collection

P1 navigation context. Search save → Saved in Shop (112) → Fresh tomatoes (113) → Android Back (114). Actual: general Quick Shop feed, not Saved in Shop; opening Saved again (115) still finds the saved item, so this is lost view/filter context, not lost saved data. Expected: return to the exact saved collection/filter/scroll, consistent with store and order entry contexts. Capture 114's prospective filename says preserved, but its actual XML/screenshot prove the failure. Do not use the label as the verdict.

### R66-UAT-018 — Clear Saved confirmation buttons hidden under Android navigation

P1 Android action fit. From one-item Saved list, tap Clear list. Stable confirmation at normal 360dp / font 1.0 starts near y1252; Keep saved and Clear list bottom buttons are visually cut below y1506, with hierarchy bounds `[0,0][0,0]`. 116 and independently settled 117 match; an upward content swipe (118) cannot reveal them. Close X remains accessible and correctly preserves the item (119). Expected: content-adaptive safe-area sheet with both complete, reachable 44dp actions in normal/large-text and compact-height modes; no suppressed overflow or invisible tappable workaround. This is not a keyboard-transition frame.

### R66-UAT-019 — Quick 10m heading conflicts with visible delivery estimates

P2 promise truth / provider eligibility contract. Quick 10m is selected while recent quick products explicitly show 12 minutes (tomatoes) and 18 minutes (noodles), and tomato's store/status is Quick 10m while its actual detail/checkout/tracking promise is 12 minutes (003/004/020/070/106). Expected: category promise and provider-supplied eligibility/ETA are consistent; never replace real 12/18-minute values with invented 10-minute data. Determine the minimal truthful eligibility/label behaviour with the existing fulfilment contract and retain the accepted blue segmented design. Recent cross-category items alone are not a filtering defect; the specific contradiction is the same quick product/store promise.

### R66-UAT-020 — Show all products retains additional refinements

P2 recovery/copy consistency. Multipack plus Fruits produces no results (135–136). Show all products clears the category but retains Quick local and two additional refinements (137–138), yielding ten matching products rather than the full eighteen. Explicit Clear in Sort and refine resets them and exposes eighteen (139–140). Expected: the recovery action and resulting scope agree—either clear the limiting refinements or name the narrower action truthfully. Quick-local refinement correctly synchronizes the top Quick segment (131–132); that synchronization is not a defect.

### R66-UAT-021 — Scanner secondary actions lack clear availability/state

P2 visual/state feedback. Enter code is enabled and opens correctly (147) but appears white-on-grey like a disabled action (141). Torch illuminates the rear view and turns off (143–144), yet its icon/accessible label does not expose the changed on/off state. After switching to the front camera (145), Torch remains tappable and the tap has no availability explanation (146). Expected: readable manual fallback and truthful torch on/off/unavailable state using the actual camera capability; do not claim hardware failure or fabricate support. Rear camera was restored before manual entry. Numeric contrast and controller diagnosis remain pending.

### R66-UAT-022 — Empty manual barcode submission is silent

P2 validation. Manual code sheet shows enabled Find product with an empty field (147); tapping it yields neither validation feedback nor a state change (148). Unknown nonempty code correctly returns to a no-match result with Clear search recovery (149–150). Expected: disable an empty submission or explain the required input; preserve known-code lookup, unknown-code recovery, keyboard and Back. Real optical decoding has not been verified because no physical barcode is in the camera view.

### R66-UAT-023 — Wholesale cart reuses the last retail store return

P1 cross-scope navigation. After earlier retail-store browsing, open Wholesale from the global rail (155), then its retained notebook cart (156). The only line is A4 ruled notebooks from Rajasthan Paper Products, but Continue browsing names Sardarpura Supermart. Tapping it opens that retail store's ₹279 wheat catalogue (157), not a Wholesale destination. Back correctly returns to the unchanged Wholesale cart (158). Expected: preserve store return context per shopping scope/entry; never silently reuse a retail store for a Wholesale cart. Use the existing scoped navigation contract rather than duplicate cart/store routes. No retained cart item was removed.

### R66-UAT-024 — Default payment handoff is a local completion chooser

P1 launch boundary / truthful payment interaction. Wholesale PhonePe review (168) advances to Ready for secure payment (169); Pay opens an in-app sheet with Payment completed / Payment not completed (170), not a provider collection UI. Read-only source confirms `_openPaymentCollection` only returns a local boolean; the review adapter then supplies a seeded reconciliation result. Not completed correctly preserves the cart and shows retry (171); retry resets to method/review step (172), not a confirmed payment. Expected: an injected, approved collection handoff plus authoritative payment reconciliation; unavailable integration must fail closed with truthful recovery, not offer a production completion simulator. This is not evidence of a real unauthorized charge or backend accepting a forged payment. Cursor owns safe Buy fallback/interaction and tests; Codex owns provider/backend integration. No external payment site/app or real money action occurred, and Payment completed was not tapped.

### R66-UAT-025 — Supplier catalogue omits the available product used to enter it

P1 catalogue/store continuity. Open available Premium basmati rice 50 kg, seller Thar Grains Wholesale (178/184), then Visit store (185). Supplier catalogue lists only sugar and toor dal; View all still reports two available products and omits both rice variants (186). The rice is available and can be added to Cart, so it is not an observed unavailable-product exclusion. Expected: the authoritative supplier catalogue includes the eligible origin SKU/variant with matching owner identity and sale-mode rules. Diagnose supplier identity/filter joins; do not add a duplicate catalogue or silently substitute a different owner.

### R66-UAT-026 — Visually compact store cart retains an invisible full-width hit area

P1 tap interception / compact-cart contract. In the full supplier catalogue (186), Cart is visibly a compact lower-right pill but exposes clickable bounds `[0,1404][720,1438]`. Tapping the empty lower-left area `(120,1420)`, outside the pill, opens Cart (187). Expected: only the visible cart and its accessible minimum target respond; transparent surrounding product space must remain available. Retain compact amount/count and drag behaviour. This is a separately reproduced invisible-hit-area child related to 004, not a claim that a white visual strip is still present.

### R66-UAT-027 — Selected payment offer lacks applied/pending/ineligible explanation

P2 payment-price transparency. Supplier coupon ₹300 reduces ₹3,480 to ₹3,180 (194–198). Selecting the separate Pine Labs payment offer advertised as Save ₹300 now keeps ₹3,180 both with PhonePe and after selecting Pine Labs; checkout simply names the offer, and confirmation gives no qualification/result explanation (199–201). Source confirms ordinary fallback pricing deducts coupons only; payment savings require a quote/eligibility contract. Expected: distinguish selected from applied/pending/ineligible, show the authoritative saving or reason and keep the final amount consistent. Do not invent a second discount or stacking policy. Buy UI/quote-state projection is Cursor-owned; actual provider offer eligibility and funding are Codex/backend dependencies.

### R66-UAT-028 — Large text clips monetary digits in Cart

P1 price readability/accessibility. Redmi physical 720×1600, density 320, system font_scale readback 2.0. Cart scope total, line subtotal and bottom payable amount are vertically clipped (207 and independently settled 208). The footer still semantically announces ₹3,480 but only part of the rendered digits is visible, so semantics-only checks falsely miss the visual failure. Expected: measured adaptive price height/width for scaled text and large Indian amounts, including animated/static states, without disabling scaling or hiding overflow assertions. Preserve amount arithmetic and touch targets.

### R66-UAT-029 — Fixed-height Cart actions truncate enlarged labels

P2 large-text action fit. Under the same verified 2.0 scale, Browse more products wraps but its lower line is clipped by its fixed container; scope tabs also cut the lower numeric line (208). Expected: content-adaptive action and scope-tab height with readable labels/counts, intact safe areas and minimum targets. Cart's product description itself wraps; do not shrink all text or replace the established layout. Check shared Buy button usages during diagnosis and retain exact owner boundaries.

### R66-UAT-030 — Recently viewed cards overflow at enlarged text

P1 responsive layout child of the paused catalogue correction. At verified font_scale=2.0, Recently viewed Fresh tomatoes shows a yellow/black RenderFlex stripe and `BOTTOM OVERFLOWED BY 19 PIXELS`; noodles also overflows (212–213). Main featured tomato/rice cards below it fit their price/pack/supplier/actions in the same capture, so this is an uncovered recent-card component, not proof the completed featured-card fix failed. Promo cards break words into fragments and truncate descriptive text; top Quick/Scheduled labels lose their endings (extend 029 for segment fit). Expected: fit recent-card content adaptively while retaining real fields, legible scale, compact layout and motion. Add exact recent-card regressions; do not suppress framework overflow reporting or regenerate goldens blindly.

### R66-UAT-031 — Manual-code keyboard sheet clips enlarged action labels

P2 scanner keyboard/large-text fit. With font_scale=2.0, Enter code opens with the focused field above Gboard, but Cancel wraps as `Cance` plus a clipped final character and Find product loses its second line (215). Cancel remains tappable and restores the active scanner (216), so this is not a failed Cancel route. Scanner's enlarged instruction panel also overlaps the lower scan-frame corners (214). Expected: adaptive action layout/height and scan-frame bounds for actual available space, preserving readable scaling, fallback, camera lifecycle and minimum targets. Link 021/022 for one narrow scanner correction with focused regressions.

### R66-UAT-032 — Monthly basket preview hides full price and selected-mode scope

P2 purchase-decision/context clarity. Preview advertises 12 products/21 packs/Save ₹415 and Add basket without the basket total (224/230). See 12 products shows six Quick products; Scheduled reveals the other six, with no explicit six-of-twelve scope explanation (225/228). Add correctly adds all twelve/21 packs at ₹5,145 and preserves Wholesale (231–232). Expected: expose the current basket price, quantities and basis of savings before Add, and clearly present all included fulfilment groups or label the filtered subset. Do not fabricate discounts or change the bundle contents. Monthly-product Back passes (226–227). After scoped Shop removal, the Monthly basket banner remains above the remaining Wholesale notebook Cart (240); align contextual banners with the actual cart scope. Add acknowledgement says only the last product and global 22 while visible scoped count is 21 (extends 005).

### R66-UAT-033 — Shopping-alert Back loses the alerts/settings context

P2 return continuity. Shopping settings → Shopping alerts → Delivery update opens retained Wholesale order PO-NEW-01 (245–246). Android Back returns to Orders with the previously selected Delivered filter, not to the alerts list/settings entry (247). Expected: restore the actual origin and its selection/scroll so customers can inspect the next alert without rebuilding the path. Preserve the correct order target and existing direct Orders flow. Link Saved/store return corrections where a shared Buy return-context owner can be reused; do not copy shared Chat navigation.

## Additional evidence and ownership boundaries

- E02 evidence-helper correction: capture 061 is Android DocumentsUI opened by this review invoice download, not the review app itself. Its original JSON incorrectly names the originating package because the helper read an older `mResumedActivity` rather than `topResumedActivity`. Preserve 061 unchanged with this correction. Helper now requires exactly one top-resumed activity, validates it again after hierarchy capture, records the actual package, and permits DocumentsUI only with explicit `-AllowInvoicePicker`. Fresh 062 verifies that system save step; no WhatsApp or unrelated file was opened. Existing captures 001–060 show the review flow; 061 is not an app-screen proof.
- Shared Chat observation 022 is linked to Codex-owned UAT-BUY-004–014/022 and later accepted Chat commit `30b9b8c7eb92b7ee688a40550a438175bb522e08`, absent from this baseline. Generic loading/supplier context remains a dependency, not duplicate Cursor implementation. Settled keyboard and exact store Back were independently observed.
- COD appears and selects for this Shop basket. Source eligibility currently checks Shop-only lines and amount ≤₹5000, not an authoritative customer-eligibility result. Record the required customer/supplier/payment adapter boundary with Codex; this device pass does not prove eligibility for a real customer. Do not invent new eligibility policy.
- A read-only search included one nonexistent guessed commerce-adapter path and returned exit 1. Required code was then read from the discovered `buy_v2_session.dart` and existing contracts; the failed search is not complete evidence. COD review submission was verified to use local `confirmOrder`, not a real commerce request, before the tap.
- E03 input-probe correction: trying to remove the four-character test suffix with MOVE_END/Backspace affected an earlier line, and injected Ctrl+A did not select all (082/083). No message was sent. Used the observed long-press Select all toolbar (084), restored the exact original auto-draft and verified the full text (085). These unsuccessful synthetic key sequences are not a Chat product-defect claim. Prefer observed touch selection to assumed desktop shortcuts on Android.
