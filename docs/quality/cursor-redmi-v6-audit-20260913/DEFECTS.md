# Findings from the V6 Redmi APK audit

Only findings from installed candidate `UAW-CURSOR-REDMI-V6-REVIEW-20260913`, SHA256 `97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7`, Redmi `TG8HCYTGGQT885OF`. Historical closed findings are excluded. Audit and enumeration remain incomplete. No implementation authorized in this goal.

## RV6-D001 — Store empty-search recovery recommends an unavailable area control

- Status: open, confirmed device copy/navigation guidance defect. Severity: minor.
- Journey: product → Visit store → Browse all products → Search this store → enter `zzzzzz`.
- Actual: “No matching products. Try another search, category or area.” The Store-specific sheet offers search and categories, but no area selector. Its category sheet contains Store categories only.
- Expected: recovery guidance should name actions available within this Store scope, such as changing/clearing the search or category. A shopper should not be directed to hunt for a nonexistent area control or leave the selected Store without explanation.
- Evidence: `redmi-v6-037-store-empty-search.png`, `redmi-v6-038-store-categories.png`. Normal font scale 1.0, density 320, 720×1600 physical screen. Isolated catalogue fixture, Store Mool Market 000001; the defect concerns shared static recovery copy rather than fixture product content.
- Source: `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`, shared empty-state message near line 1195; `_PagedFullStoreCatalogue.build` near line 6713 creates a Store-bound query, with `showAreaControl` defaulting to false (constructor near line 854).
- Ownership: Buy frontend contextual copy. No backend or Store producer change is needed merely to correct the guidance. Implementation and retest deferred to the next authorized scope.

Provider and test-data limitations are recorded separately in BLOCKERS.md and are not counted as reproduced frontend defects.

## RV6-D002 — Removing the last item while browsing a Store exits the Store

- Status: open, confirmed device navigation defect. Severity: moderate.
- Journey: Turmeric product → Visit store → Browse all products → Fruits & vegetables → add Fresh tomatoes 1 → open cart → Continue browsing Mool Market 000001 → Browse all products → decrement Fresh tomatoes from 1 to 0.
- Precondition: only this test-added item in Shop cart; selected Store category still retained on return (capture 044).
- Actual: the product briefly becomes Add (045), then both Store sheets disappear and the app returns to the general Shop catalogue at its earlier page/horizontal position (046), without Back or Close being pressed.
- Expected: removing an item changes the basket and removes the empty basket rail while leaving the customer in the Store catalogue and selected category. General Shop is a different browsing context.
- Impact: a shopper removing their last item loses the Store browsing destination and must find/reopen it to continue shopping. The item removal itself succeeds; this is not evidence of cart data loss or a payment failure.
- Evidence: 040–046, especially 044 before decrement, 045 transition, 046 settled destination. Exact APK/device as above. No real order or message occurred.
- Source hypothesis: underlying cart-empty navigation and Store sheet restoration interact; investigate `buy_v2_screen.dart` Store route lifecycle and `buy_v2_session.dart` last-item handling. Cause not yet established by source or isolated regression. Buy frontend owner; no implementation in this audit.
- Subsequent source correlation: `BuyV2Session.decrease` (near line 10318) replaces cart/checkout with catalogue when the last line is removed. `_sessionChanged` in `buy_v2_screen.dart` (near line 607) dismisses Store routes whenever the underlying session becomes catalogue. This matches the observed Store-over-cart sequence; an isolated regression has not been run or added in this audit.

## RV6-D003 — Order Chat presents a stale delivery promise without its unavailable qualifier

- Status: open; confirmed device information-consistency defect. Severity: moderate.
- Journey: open MS-NEW-09 tracking; Refresh produces Order updates unavailable and last recorded estimate/update unavailable (112); open Help; expand Order conversation context (146–147).
- Actual: Chat context labels Delivery as Delivery in12min with no last-known or unavailable qualifier. Tracking for the same order explicitly says the update is unavailable. Order and purchase identity remain correct.
- Expected: all current order-support surfaces preserve the estimate freshness/unavailability state; an unconfirmed stored relative promise must not appear as an unqualified current countdown.
- Customer impact: a buyer seeking help after failed tracking refresh receives a conflicting apparent delivery promise. No evidence of a wrong actual delivery or a sent message is claimed.
- Evidence:112-tracking-refresh and147-order-chat-context; exact installed V6 review APK and Redmi as recorded. Fixture order MS-NEW-09; this finding concerns cross-surface freshness handling rather than whether fixture ETA is live.
- Source correlation: apps/mobile/lib/ui_v2/buy/buy_v2_chat_route_adapter.dart near108 maps delivery to order.promise; near339 also formats the raw promise. buy_v2_shop_chat.dart fromOrder near408/415 likewise uses order.promise. Runtime Chat context is observed directly; no implementation or isolated regression added.
- Ownership: Buy-to-shared-Chat metadata/freshness contract; coordinate shared consumer rendering if needed in the later implementation scope. Backend live estimates remain separately unqualified.

## RV6-D004 - Display-name validation sentence is clipped at normal text size
- Status: open; confirmed device visual defect. Severity: minor.
- Journey: Buy account drawer > Personal profile > Display name > submit whitespace-only draft. Validation rejects it; Android Back hides keyboard.
- Actual: error remains one truncated line, Enter a display name from 2 to 60 cha..., with and without keyboard at Redmi font scale1.0. The allowed numeric range remains visible; this is not a validation bypass or data-loss claim.
- Expected: complete validation guidance fits or wraps, including characters, without requiring inference from clipped content.
- Evidence:198-blank-name-error and199-name-error-keyboard-back. Capture197 contains an accidental whitespace from a tap while delayed autofocus opened the keyboard; it is not itself a defect. No valid profile save occurred.
- Source correlation: apps/mobile/lib/features/journey01/journey_session.dart:466 supplies the full sentence. Shared profile form owns its error layout; exact rendering cause still to inspect. Connected shared profile UI owner, not Buy catalogue. No implementation during this audit.

## RV6-D005 - Hindi preference changes its value but observed Buy and preference UI remain English
- Status: open; confirmed device localization/wiring gap. Severity: moderate for Hindi-dependent users.
- Journey: Buy account > Personal profile > Language > Privacy and preferences > Language > Hindi; return to Buy catalogue.
- Actual: preference reads Hindi but headings/actions on the preference screen and returned Buy catalogue remain English, including Stores or products, Wholesale, Bulk and Add. No unavailable/restart/partial-language disclosure was visible.
- Expected: choosing an offered app language applies to supported customer navigation and guidance; unavailable coverage must be explicit rather than implying the language changed throughout the experience. Supplier-authored product names are not required to be translated by this finding.
- Evidence:202-language-sheet,203-hindi-selected,204-hindi-return. Current normal-text Redmi V6 APK. Relaunch language propagation remains untested; this finding is the immediate observed selection/return behavior.
- Source correlation: features/journey01/journey_session.dart updateLanguage near443 persists languageCode and announces language changed. Shared localization and Buy strings require later owner assessment; no implementation or backend change authorized by this audit.

## RV6-D006 - Cancelling sign-in loses the originating Buy Back route
- Status: open; confirmed device navigation defect. Severity: moderate.
- Controlled reproduction: fresh Buy Quick catalogue > profile drawer > Security > Sign in > Android Back returns Security > Android Back exits to Android launcher instead of Buy.
- Control: Buy > Security > Android Back without entering sign-in returns the same Buy catalogue (231-232).
- Evidence:230-235 controlled sequence;233 chooser,234 cancellation to Security,235 launcher. Earlier228 showed the same symptom after the prior Security round but is supporting observation only. No provider selected or authentication performed.
- Expected: cancellation preserves the originating Buy stack/context so subsequent Back restores shopping, just as the control path does.
- Customer impact: shopper abandoning sign-in is taken out of the app on the next Back and must reopen it. No crash or stored-data loss is claimed.
- Source correlation: Buy _openBuyProfile pushes the shared route; global_security_v2.dart _beginSignIn uses context.go('/sign-in') and only securityLocation for return/cancel. Route-stack restoration needs later shared routing assessment; source correlation is not an isolated-test proof. No code changed.
- Prior ACCOUNT-017 and ACCOUNT-019 remain narrow first-return passes; they do not qualify this second Back to Buy. PD-040 return requirements remain unresolved end to end.


## RV6-D007 - Related-product Back skips the preceding product detail
- Status: open; confirmed device navigation defect. Severity: moderate.
- Reproduction: Saved Shop wheat atta2 > product details > scroll to You may also like > related wheat from Sardarpura Supermart > Android Back.
- Actual: Back returns directly to Saved Shop instead of the preceding Mool Market product detail and its position. Customer must reopen the original product and find the previous information again.
- Expected: exploring a related offer preserves the preceding product-detail context for Back; leaving the original product then returns to its Saved/catalogue origin.
- Evidence:281-product-lower-content shows related card;282-related-canonical-product shows selected different seller;283-related-back shows Saved. The original observation CONTENT-ROUND19-03 is now classified as this failure after source reconciliation. No cart/bookmark loss or crash claimed.
- Source correlation: buy_v2_views.dart3289/3295 related card calls session.openProduct without preserveComparisonOrigin. buy_v2_session.dart8318-8355 only pushes prior selected product when that flag is true;closeProduct8488-8506 restores the root product return after an empty origin stack. Source explains the observed shortcut;no implementation or test modification performed.
- Ownership: Buy product continuation navigation/session. Future correction must preserve full previous product context and existing cart/order/Store return paths;this audit does not implement it.


## RV6-D008 - Wholesale buyer label runs into the business name
- Status: open; confirmed Redmi visual defect. Severity: minor.
- Journey: Orders > search Wholesale > Delivered > PO-240728 View order.
- Actual: Delivery details renders Retailer business immediately against Shree Balaji Retail,with no clear gap at the label/value boundary. Normal font_scale1.0,720x1600 Redmi. Other details remain legible;no identity/data corruption claimed.
- Expected: buyer-type label and business-name value have a visible separation or wrap/stack so they read as distinct fields at supported text sizes.
- Evidence:312-wholesale-delivered-detail. This is a direct device visual finding,not an assertion from host analysis.
- Source correlation: buy_v2_views.dart11576-11580 passes order.buyerType and buyerName into the delivery-details row. Exact row sizing correction belongs to later implementation;no product code changed.


## RV6-D009 - Confirmation deep link displays success without a confirmed purchase
Status: open. Severity: high (false order confirmation). APK: UAW-CURSOR-REDMI-V6-REVIEW-20260913;Redmi TG8HCYTGGQT885OF.
Reproduction: with empty cart and no order submitted,deliver declared HTTPS intent https://moolsocial.com/app/buy?view=confirmation to installed Cursor Review. Capture358 shows green check,Order placed,0 products/0 total,0 deliveries,and current saved recipient/address. This is a device-reproduced false-success state,not a completed order/payment.
Expected: require authoritative confirmed purchase identity and nonempty accepted orders before any success claim;otherwise show unavailable/recovery or return safely without inventing success or using an unrelated saved address.
Source: journey_router.dart2025 maps confirmation query;buy_v2_screen.dart544-546 directly sets initialView;buy_v2_views.dart8739-8804 unconditionally renders success/confirmed totals and selectedAddress. Normal completion path session11231-11261 is separate and was not invoked by this test.
Impact: a stale/shared/malformed link can tell a customer an order was placed despite no purchase. Real payment/account backend behavior remains unqualified. Do not fix during this audit. Evidence358 retained. View order details opens existing Active orders with unchanged12active/2delivered359. Reopening link then Continue shopping returns Shop/empty cart360. No new order/payment created by tested navigation.


## RV6-D010 - Recovery return changes selected destination while retaining order detail
Status: open. Severity: minor navigation inconsistency. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: open existing MS-240782 via declared HTTPS /app/buy/order/MS-240782 (371;Orders selected). Open declared /app/buy?view=recovery&recovery=delay,then Return to order372-373. Same order/detail retained,but Shop is selected in bottom rail instead of original Orders.
Expected: exact return context includes originating destination as well as order ID;tracking should restore original Orders selection.
Source: buy_v2_screen.dart527-529 overwrites destination with initialDestination before openRecovery;session11548-11560 records that replaced destination in origin. Generic recovery link defaults to Shop in journey_router. Conditional Help and other origin contexts need separate checks. No order/data mutation or implementation.


## RV6-D011 - Wholesale product repeats summary data across several content sections
Status: open. Severity: minor visual/content usability defect. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: Wholesale Fresh tomatoes1/10kg580 product407;scroll408-410. Product details repeats Brand not provided/variant/pack/policy;Product and pack information repeats product/pack/unit price;Highlights repeats variant/unit price/policy;Specifications repeats brand/pack/variant;Description repeats title/variant/pack/unit price. Customer must scroll through repeated information before ratings/reviews. This is actual default content,not distinct technical specifications.
Expected: preserve useful supplier-specific information while suppressing identical summary-only highlights/specifications/generated description in Wholesale as in Shop. Keep the price/MOQ/pack decision accessible;do not remove genuinely distinct supplier facts.
Source corroboration: buy_v2_views.dart3877-3910 suppresses identical content only when destination is Shop (`!shop` admits all Wholesale duplicates). This is a frontend deduplication gap. Physical scope verified for this Wholesale listing;other products/Bulk require separate qualification. No implementation.


## RV6-D012 - Store listing count is labelled available despite non-orderable products
Status: open. Severity: minor customer-copy inconsistency. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: closed Pet Family Store423;View all428. Header says Retailer - 4 available products in green while all four cards say Store closed and expose information instead of Add. Count describes listed products,not current orderability. Closed state and purchase restriction remain correctly enforced.
Expected: use neutral listing count or distinguish listed from currently orderable products;do not label total listings available when current facts reject ordering.
Source: buy_v2_catalogue.dart6916 interpolates products.length with literal available products,without per-product orderability. No implementation;other unavailable/mixed inventories require follow-up qualification.

## RV6-D013 - Store conversation expands without any additional content
Status: open. Severity: minor empty-action/spacing defect. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: Pet Family Store431 Ask opens correct conversation432. Expand Store conversation433 reveals only a divider and blank spacing, with no extra facts or destination. AndroidBack434 restores exact Store. No message sent;automatic draft retained unsent.
Expected: expose expansion only when additional facts or an applicable product action exist;otherwise retain a compact static context summary. Do not invent missing facts.
Source corroboration: chat_thread_screen.dart _ChatCommerceContextCard near1966-2055 always constructs ExpansionTile with divider/spacing;fact rows depend on decisionFacts and View product depends on productAppRoute. Store-only context has neither. Shared Chat presentation owner;Buy supplies Store context. No implementation.

## RV6-D014 - Warm order link with Store overlay produces navigation error
Status: open. Severity: high in installed review APK (Buy interrupted by error screen);release behavior unverified. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: Pet Family Store sheet remains open after Other Store navigation and Back440. Deliver declared HTTPS https://moolsocial.com/app/buy/order/MS-240782 to installed package. Capture441 shows Flutter navigator.dart assertion line5909 !_debugLocked rather than order. App-scoped logcat at07:33:45 additionally records navigator.dart3249 !navigator._debugLocked in _RouteEntry.handlePush. Exact root cause not established;do not equate assertions with release behavior.
AndroidBack442 leaves app to prior Android Display task. Explicit normal activity reopen443 then settled444 recovers Shop catalogue;requested order context is not restored. No force-stop,uninstall,clear-data or order/payment mutation. Saved badge remains1;full saved/address preservation check remains pending.
Expected: serialize declared-link navigation with modal dismissal safely;reach requested order or show recoverable unavailable state without error or unrelated task exit. Shared route/modal integration owner must investigate;no product implementation during audit. This is distinct from recovery rail-selection D010 and sign-in cancellation D006.

### RV6-D003 additional occurrence - downloaded invoice relative delivery promise
Round44 capture480:existing saved MS-NEW-09 PDF opens on Redmi at08:07 and shows Expected: Delivery in12min with no recorded-time qualifier. Same order tracking previously labels this as last-recorded/unavailable. This is another output of the existing freshness-loss defect,not a separate counted defect. PDF line source buy_v2_invoice_downloader.dart102 writes raw order.promise;on-screen invoice source buy_v2_invoice.dart546 does likewise (source correlation,not a new on-screen invoice reproduction this round). Preserve an absolute promised window or a clearly dated original estimate in a historical document;do not present an undated stored relative countdown as current expectation. Correct invoice identity/item amount does not qualify this freshness claim. PDF bytes matched retained artifact SHA256 D618A5FF426512D2B2D30DCC12B6BCBF528D40E9FEB532C0D9CEE146C8FCD2E2. No PDF or source edited.

## RV6-D015 - Recently viewed offers Add for non-orderable products
Status: open. Severity: moderate customer action/availability inconsistency. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction:SavedShop -> Sort/filter483 -> Shoppingtools484-485 -> Recentlyviewed486. Adultdogfood from closed PetFamilyStore shows Delivery time confirmed at checkout and enabledAdd;Dailycare shampoo says Currently unavailable but also enabledAdd. Taps487/488 leave Add unchanged and no visible recovery explanation in retained sheet captures. Product489 explicitly confirms Storeclosed/tomorrow8am;AndroidBack490 returns exacthistory. No item added or restriction bypass observed.
Source:_RecentlyViewedProductInfoRow7486 onward displays buyV2BuyerDeliveryPromise in green and unconditional onPressed:onAdd. Parent7420 calls session.addProduct without handling returnedfalse or presenting sheet-local feedback. Session10071 onward correctly rejects closed/unavailable and emits notice. Expected:consistent orderability/closure explanation and appropriate unavailable/recovery control on history rows;rejected action feedback must be visible in the sheet. Do not weaken session restrictions. No implementation;existing D012 misleading Store count is a separate surface/problem.

### RV6-D003 additional occurrence - Shopping settings alert freshness
Round48 captures510-511:Shopping settings -> Shopping alerts shows Delivery update / Shop order Delivery in12min / Updated recently. Tap opens MS-NEW-09 tracking with LAST KNOWN;Last recorded estimate Delivery in12min;live updates unavailable. The alert loses the freshness qualification visible at its own destination. Same existing freshness-loss defect;no new distinct count. This is physical UI evidence,not proof of live delivery or provider timestamps. Alert route source catalogue5015 uses beginShoppingAlertVisit and router.push with origin restoration;exact alert-data producer mapping remains to reconcile.

## RV6-D016 - New Shop offers alert opens ordinary catalogue
Status: open. Severity: moderate navigation/destination failure. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction:Shopping settings -> Shopping alerts510;tap New Shop offers from516. Destination517 is ordinary Scheduled Shop product grid with Shop selected,not Offers or its product/payment offer content. AndroidBack518 correctly restores alert sheet. Customer cannot reach advertised offer results through this alert. No cart/order/message change.
Source:buy_v2_shopping_alerts.dart158 onward maps offer to /app/buy?sub=offers;catalogue5035 pushes generated location. Screen1811 _openOffers explicitly sets _offersActive and same route when using normal navigation. Exact route-initialization cause is not yet proven;do not claim unsupported query without inspecting route parser. Expected:alert opens actual Offers surface,retains origin,Back restores alert list. Source cause and correction remain unimplemented.

## RV6-D017 - Saved GST profile selected chip has unreadable identity
Status: open. Severity: moderate visual identification failure. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction:one isolated wheat pack279;Confirm order -> enable GST -> Add;enter local test name AuditRedmiTest, host-fixture GSTIN and test billing text;leave temporary reuse enabled;Use GST details. Captures691 and settled692 show dark selected Saved GST details chip with no readable name and low-contrast check/remove icons. The separate green current-details card is readable. Customers cannot identify the saved profile through its chip, especially when choosing among profiles. Expected:readable profile identity and selected/remove affordances. Source cause not established;no product correction. No order or payment submitted.

### RV6-D017 source correlation
Buy GST InputChip at buy_v2_views.dart6158-6175 uses Text(profile.legalName),selected state and no explicit foreground styling. Shared core/design/mool_theme.dart174-185 supplies selectedColor navy and labelStyle navy;secondaryLabelStyle white is separately defined. This supports the captured selected-chip contrast failure;exact Flutter theme resolution should be verified during correction. Prefer a scoped Buy fix or separately owned shared-theme regression assessment;no ownership expansion or implementation during this audit.


## RV6-D018 - Product Back loses paginated search destination and position
Status: open. Severity: moderate navigation/retention failure. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913; APK SHA256 97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7.
Reproduction: Scheduled Shop -> search milk -> keyboard Search after settled query (898) -> Next (899, range41-80) -> open Toned fresh milk1184 (900) -> Android Back. Settled902 returns main Shop catalogue starting milk8/cereal74/chocolate144, not originating search page41-80. Query milk is retained but page and dedicated search surface are lost. Capture901 is a transition frame, not a separate blank-screen defect. Expected: return to the same search result page and retained query so the customer can continue browsing without repaging. No cart mutation or real transaction. Distinct from related-product Back D007: origin here is paginated search results. Ordinary catalogue page return passed round124; it does not cover this branch. Root cause and implementation remain pending; preserve exact route/search context in correction.


### RV6-D018 recovery clarification
Capture904 after explicitly reopening the search field restores range41-80 and milk1184. The search pager state is retained internally: the confirmed failure is wrong Back destination and visible loss of browsing position until an extra search tap, not irreversible cursor/data loss. Clearing query905 and Done906/settled907 restores ordinary Scheduled Shop, Saved1 and empty cart. Correct the return surface; do not reset or replace preserved search state unnecessarily.
