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
