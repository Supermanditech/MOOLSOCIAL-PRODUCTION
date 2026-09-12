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
