# Findings from the V6 Redmi APK audit

Only findings from installed candidate `UAW-CURSOR-REDMI-V6-REVIEW-20260913`, SHA256 `97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7`, Redmi `TG8HCYTGGQT885OF`. Historical closed findings are excluded. Audit and enumeration remain incomplete. No implementation authorized in this goal.

## RV6-D001 — Store empty-search recovery recommends an unavailable area control

- Status: closed after scoped Redmi r66.20 acceptance on14September2026. Severity: minor. Implementationd532b9dea97a52473a5a95e090a9831fd9635696; installed APK SHA2567734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Capturesrv620-001through011 verify corrected guidance, category/query recovery and AndroidBack through sameStore/product/Shop; details and limitations inUAT.md. No child found.
- Journey: product → Visit store → Browse all products → Search this store → enter `zzzzzz`.
- Actual: “No matching products. Try another search, category or area.” The Store-specific sheet offers search and categories, but no area selector. Its category sheet contains Store categories only.
- Expected: recovery guidance should name actions available within this Store scope, such as changing/clearing the search or category. A shopper should not be directed to hunt for a nonexistent area control or leave the selected Store without explanation.
- Evidence: `redmi-v6-037-store-empty-search.png`, `redmi-v6-038-store-categories.png`. Normal font scale 1.0, density 320, 720×1600 physical screen. Isolated catalogue fixture, Store Mool Market 000001; the defect concerns shared static recovery copy rather than fixture product content.
- Source: `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`, shared empty-state message near line 1195; `_PagedFullStoreCatalogue.build` near line 6713 creates a Store-bound query, with `showAreaControl` defaulting to false (constructor near line 854).
- Ownership: Buy frontend contextual copy. No backend or Store producer change is needed merely to correct the guidance. Implementation and retest deferred to the next authorized scope.

Provider and test-data limitations are recorded separately in BLOCKERS.md and are not counted as reproduced frontend defects.

## RV6-D002 — Removing the last item while browsing a Store exits the Store

- Status: closed; r66.20 Redmi acceptance passed. Severity: moderate.
- Journey: Turmeric product → Visit store → Browse all products → Fruits & vegetables → add Fresh tomatoes 1 → open cart → Continue browsing Mool Market 000001 → Browse all products → decrement Fresh tomatoes from 1 to 0.
- Precondition: only this test-added item in Shop cart; selected Store category still retained on return (capture 044).
- Actual: the product briefly becomes Add (045), then both Store sheets disappear and the app returns to the general Shop catalogue at its earlier page/horizontal position (046), without Back or Close being pressed.
- Expected: removing an item changes the basket and removes the empty basket rail while leaving the customer in the Store catalogue and selected category. General Shop is a different browsing context.
- Impact: a shopper removing their last item loses the Store browsing destination and must find/reopen it to continue shopping. The item removal itself succeeds; this is not evidence of cart data loss or a payment failure.
- Evidence: 040–046, especially 044 before decrement, 045 transition, 046 settled destination. Exact APK/device as above. No real order or message occurred.
- Source hypothesis: underlying cart-empty navigation and Store sheet restoration interact; investigate `buy_v2_screen.dart` Store route lifecycle and `buy_v2_session.dart` last-item handling. Cause not yet established by source or isolated regression. Buy frontend owner; no implementation in this audit.
- Subsequent source correlation: `BuyV2Session.decrease` (near line 10318) replaces cart/checkout with catalogue when the last line is removed. `_sessionChanged` in `buy_v2_screen.dart` (near line 607) dismisses Store routes whenever the underlying session becomes catalogue. This matches the observed Store-over-cart sequence; an isolated regression has not been run or added in this audit.

- Local implementation: Buy screen retains Store browsing through the exact empty-cart navigation sequence. Eight focused cases passed (legacy/paginated, Shop/Wholesale, normal/200% text), 72 connected checks passed before the four paginated additions; counts overlap. Eight Flutter captures and final analysis verified; exact evidence and limitations in UAT.md, RV6-D002 local checkpoint. Original physical 040-046 acceptance remains pending.


- Successor Redmi acceptance: captures rv620-012 through rv620-022, exact installed APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Same Store/category retained after last-item removal; basket rail removed; Back through Store overview to Shop; test-added item removed. UAT.md records entry variation, implementation commit and limitations. No child found.

## RV6-D003 — Order Chat presents a stale delivery promise without its unavailable qualifier

- Status: closed; all three recorded frontend occurrences passed r66.20 Redmi acceptance. Severity: moderate.
- Journey: open MS-NEW-09 tracking; Refresh produces Order updates unavailable and last recorded estimate/update unavailable (112); open Help; expand Order conversation context (146–147).
- Actual: Chat context labels Delivery as Delivery in12min with no last-known or unavailable qualifier. Tracking for the same order explicitly says the update is unavailable. Order and purchase identity remain correct.
- Expected: all current order-support surfaces preserve the estimate freshness/unavailability state; an unconfirmed stored relative promise must not appear as an unqualified current countdown.
- Customer impact: a buyer seeking help after failed tracking refresh receives a conflicting apparent delivery promise. No evidence of a wrong actual delivery or a sent message is claimed.
- Evidence:112-tracking-refresh and147-order-chat-context; exact installed V6 review APK and Redmi as recorded. Fixture order MS-NEW-09; this finding concerns cross-surface freshness handling rather than whether fixture ETA is live.
- Source correlation: apps/mobile/lib/ui_v2/buy/buy_v2_chat_route_adapter.dart near108 maps delivery to order.promise; near339 also formats the raw promise. buy_v2_shop_chat.dart fromOrder near408/415 likewise uses order.promise. Runtime Chat context is observed directly; no implementation or isolated regression added.
- Ownership: Buy-to-shared-Chat metadata/freshness contract; coordinate shared consumer rendering if needed in the later implementation scope. Backend live estimates remain separately unqualified.

- Local correction: shared freshness-preserving Chat/tracking/alert summaries and historical invoice/PDF disclosure; 64 connected checks passed, final analysis zero issues, twelve relevant Flutter captures reviewed. All exact owners, test/log hashes, visual limitations and intermediate failures are recorded in UAT.md under RV6-D003 local qualification. Original 112/147, 480 and 510-511 device acceptance and real provider timestamps remain pending; no local result closes this ticket.


- Successor acceptance: UAT.md r66.20 Redmi D003 acceptance, captures023-046 and actual downloaded invoice PDF/render. Installed SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Chat, historical invoice/PDF and alert preserve freshness and exact order identity; Back verified. Provider timestamps remain unqualified. No child found.

## RV6-D004 - Display-name validation sentence is clipped at normal text size
- Status: closed; r66.20 Redmi acceptance passed on 2026-09-14. Severity: minor.
- Journey: Buy account drawer > Personal profile > Display name > submit whitespace-only draft. Validation rejects it; Android Back hides keyboard.
- Actual: error remains one truncated line, Enter a display name from 2 to 60 cha..., with and without keyboard at Redmi font scale1.0. The allowed numeric range remains visible; this is not a validation bypass or data-loss claim.
- Expected: complete validation guidance fits or wraps, including characters, without requiring inference from clipped content.
- Evidence:198-blank-name-error and199-name-error-keyboard-back. Capture197 contains an accidental whitespace from a tap while delayed autofocus opened the keyboard; it is not itself a defect. No valid profile save occurred.
- Source correlation: apps/mobile/lib/features/journey01/journey_session.dart:466 supplies the full sentence. Shared profile form owns its error layout; exact rendering cause still to inspect. Connected shared profile UI owner, not Buy catalogue. No implementation during this audit.
- Local correction: shared name editor renders the complete error as wrapping text and scrolls under constrained keyboard/text layouts. Validation, save operation and return contract unchanged.
- Local qualification: all 11 profile tests pass (four new D004 cases at 390x844/320x568 and 100%/200% text, each with 220px keyboard inset then hidden); eight themed Flutter PNGs reviewed; analysis of both changed Dart owners reports zero issues. Existing name retained after rejection; Profile return checked. Test insets are not physical Android keyboard evidence.
- Ownership admission: 41c5e36cfd2950521c918271afb56dcff2e02354 transfers only the shared profile source and existing test in this worktree. Source/test: apps/mobile/lib/ui_v2/profile/global_personal_profile_v2.dart and apps/mobile/test/ui_v2/profile/global_personal_profile_v2_test.dart. Detailed evidence and initial failed/superseded runs are recorded in UAT.md.
- Redmi closure remains pending exact successor APK reproduction of captures198/199. No device action or valid real profile save occurred during local qualification.


- Successor acceptance: captures rv620-047 through054 and UAT.md D004 acceptance. Exact installed APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Complete guidance visible with/without keyboard; rejected whitespace; Back retained original profile. No child.

## RV6-D005 - Hindi preference changes its value but observed Buy and preference UI remain English
- Status: open; r66.20 immediate disclosure passes, cold-relaunch retention fails; linked RV6-D005-C01. Severity: moderate for Hindi-dependent users.
- Journey: Buy account > Personal profile > Language > Privacy and preferences > Language > Hindi; return to Buy catalogue.
- Actual: preference reads Hindi but headings/actions on the preference screen and returned Buy catalogue remain English, including Stores or products, Wholesale, Bulk and Add. No unavailable/restart/partial-language disclosure was visible.
- Expected: choosing an offered app language applies to supported customer navigation and guidance; unavailable coverage must be explicit rather than implying the language changed throughout the experience. Supplier-authored product names are not required to be translated by this finding.
- Evidence:202-language-sheet,203-hindi-selected,204-hindi-return. Current normal-text Redmi V6 APK. Relaunch language propagation remains untested; this finding is the immediate observed selection/return behavior.
- Source correlation: features/journey01/journey_session.dart updateLanguage near443 persists languageCode and announces language changed. Shared localization and Buy strings require later owner assessment; no implementation or backend change authorized by this audit.
- Local correction (2026-09-14): language picker explicitly states Buy/settings use English and Hindi selection saves a preference only. Picker scrolls when constrained. Preferences and Personal profile summaries retain the Hindi choice while stating actual app screens are English. This follows the recorded unavailable-coverage criterion; it does not implement or claim a translated Buy experience.
- Local qualification: 42 combined profile/preferences checks passed, including D004 regressions and two D005 320x568/100%-200% selection, reopen, persisted-session restoration and English-switch checks. Four D005 Flutter captures reviewed; analysis of three changed Dart owners reports zero issues. Full Buy/physical Redmi return and Android Hindi glyph rendering await the successor APK.
- Ownership admission: 0ee85fd2d98595b0134b6190d3e9af58532990f3. Session source was explicitly rejected by the UI-lane gate and excluded before admission; its authentication, persistence and stored success message are unchanged. The recorded preference screen does not render that stored success message. Existing legacy session-message/localization behavior is not claimed corrected or translated. See UAT.md for exact qualification and preservation evidence.

## RV6-D006 - Cancelling sign-in loses the originating Buy Back route
- Status: closed; r66.20 Redmi double-Back acceptance passed. Severity: moderate.
- Controlled reproduction: fresh Buy Quick catalogue > profile drawer > Security > Sign in > Android Back returns Security > Android Back exits to Android launcher instead of Buy.
- Control: Buy > Security > Android Back without entering sign-in returns the same Buy catalogue (231-232).
- Evidence:230-235 controlled sequence;233 chooser,234 cancellation to Security,235 launcher. Earlier228 showed the same symptom after the prior Security round but is supporting observation only. No provider selected or authentication performed.
- Expected: cancellation preserves the originating Buy stack/context so subsequent Back restores shopping, just as the control path does.
- Customer impact: shopper abandoning sign-in is taken out of the app on the next Back and must reopen it. No crash or stored-data loss is claimed.
- Source correlation: Buy _openBuyProfile pushes the shared route; global_security_v2.dart _beginSignIn uses context.go('/sign-in') and only securityLocation for return/cancel. Route-stack restoration needs later shared routing assessment; source correlation is not an isolated-test proof. No code changed.
- Prior ACCOUNT-017 and ACCOUNT-019 remain narrow first-return passes; they do not qualify this second Back to Buy. PD-040 return requirements remain unresolved end to end.

- Local correction (2026-09-14): Security PopScope allows ordinary pushed-route popping; when sign-in replacement leaves no poppable route, Android Back uses the existing safe _leave return handler. Sign-in/authentication/session/router contracts unchanged.
- Reproduced with actual MoolSocialApp/Buy/chooser: control Back passed; cancel then second Android Back failed before correction (session15193, terminal1). Final Security suite11passed, zero failures (session66862 terminal0); includes actual Buy double-Back and exact originating URI, existing success/sign-out/Work/safe-return controls. Two Flutter destination captures inspected; analysis of both changed Dart owners zero issues. Device captures230-235 still require successor APK verification; no launcher or device closure claim from host tests.
- Admission9af7e19f79d61cabc5a96ba3be252ec242f2dcbc adds only global_security_v2.dart and its existing test; claim33. Evidence in UAT.md.


- Successor acceptance: rv620-065 through070; cancellation returns Security, second AndroidBack restores same Quick Buy catalogue and retained Saved1/emptybasket. No provider selected. Exact installed SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. UAT.md records limits; no child.

## RV6-D007 - Related-product Back skips the preceding product detail
- Status: closed; recorded related-product Redmi acceptance passed on r66.20. Severity: moderate.
- Reproduction: Saved Shop wheat atta2 > product details > scroll to You may also like > related wheat from Sardarpura Supermart > Android Back.
- Actual: Back returns directly to Saved Shop instead of the preceding Mool Market product detail and its position. Customer must reopen the original product and find the previous information again.
- Expected: exploring a related offer preserves the preceding product-detail context for Back; leaving the original product then returns to its Saved/catalogue origin.
- Evidence:281-product-lower-content shows related card;282-related-canonical-product shows selected different seller;283-related-back shows Saved. The original observation CONTENT-ROUND19-03 is now classified as this failure after source reconciliation. No cart/bookmark loss or crash claimed.
- Source correlation: buy_v2_views.dart3289/3295 related card calls session.openProduct without preserveComparisonOrigin. buy_v2_session.dart8318-8355 only pushes prior selected product when that flag is true;closeProduct8488-8506 restores the root product return after an empty origin stack. Source explains the observed shortcut;no implementation or test modification performed.
- Ownership: Buy product continuation navigation/session. Future correction must preserve full previous product context and existing cart/order/Store return paths;this audit does not implement it.

- Local correction (2026-09-14): both touch and accessibility continuation actions preserve product history. Buy root retains scroll offsets per nested visit, including returning through a repeated product, and restores them only for matching Back navigation. Existing Cart/Store restoration paths remain separate; session/scope replacement clears local offset history.
- Local evidence: strengthened test first reproduced catalogue shortcut, then exposed original-scroll reset after history-only correction. Full correction passes Saved wheat and search entry, two related visits, Android Back through both preceding details, exact scroll offsets and final Saved/query origin. Connected product-continuity/partner-catalogue suites102passed/0failures; final390x844 D007 cases2passed. Eight Flutter captures reviewed across default host and phone; analysis zero issues. Counts overlap, not104 unique tests. No physical Redmi closure.
- Source owners: buy_v2_views.dart and buy_v2_screen.dart. Existing buy_v2_product_continuity_test.dart admitted at877656e54eab174f3c4dc698da23799553d8023a; claim34. Full evidence and hashes in UAT.md. Original281-283 remains pending successor APK verification.


- Successor acceptance: rv620-071 through077, same Saved wheat / Sardarpura related wheat reproduction281-283; Back restores preceding product/scroll then Saved. Installed SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. UAT.md distinguishes physical scope from additional host cases. No child.

## RV6-D008 - Wholesale buyer label runs into the business name
- Local implementation qualified 2026-09-14: _DecisionRow now reserves an explicit 8px gap between its normal-text label and value; existing enlarged-text stacked layout preserved. Four 320/360px at 100/200% text regressions pass for PO-240728, including complete buyer identity, View order and Android Back/query retention. Full Buy screen suite242passed/0failures; analysis zero issues; four actual Flutter captures reviewed. See UAT D008 section for hashes and limitations. Original device capture312 requires successor-APK Redmi verification; ticket remains open.
- Status: closed; r66.20 recorded Redmi visual acceptance passed. Severity: minor.
- Journey: Orders > search Wholesale > Delivered > PO-240728 View order.
- Actual: Delivery details renders Retailer business immediately against Shree Balaji Retail,with no clear gap at the label/value boundary. Normal font_scale1.0,720x1600 Redmi. Other details remain legible;no identity/data corruption claimed.
- Expected: buyer-type label and business-name value have a visible separation or wrap/stack so they read as distinct fields at supported text sizes.
- Evidence:312-wholesale-delivered-detail. This is a direct device visual finding,not an assertion from host analysis.
- Source correlation: buy_v2_views.dart11576-11580 passes order.buyerType and buyerName into the delivery-details row. Exact row sizing correction belongs to later implementation;no product code changed.



- Successor acceptance: rv620-078 through083, PO-240728 buyer label/value visibly separated at normal text; Back retains Wholesale query and Delivered tab. Installed SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. UAT.md records exact scope/limits. No child.

## RV6-D009 - Confirmation deep link displays success without a confirmed purchase
- Local implementation qualified 2026-09-14: confirmation view requires confirmed session state, nonblank purchase reference, nonzero product count and nonempty matching identified orders. Invalid entries show recovery with Orders/Shop actions and no success/address claim. Valid delivery address comes from confirmed order snapshots, never the currently selected saved address. Fifteen D009 cases plus connected confirmation/invoice checks pass; full screen suite257passed/0failures and final focused18passed (overlapping); analysis zero issues; two recovery Flutter captures reviewed. See UAT D009 evidence. Physical Redmi358-360 remains pending successor APK; status remains open. Backend authority not qualified by fixtures.
Status: open. Severity: high (false order confirmation). APK: UAW-CURSOR-REDMI-V6-REVIEW-20260913;Redmi TG8HCYTGGQT885OF.
Reproduction: with empty cart and no order submitted,deliver declared HTTPS intent https://moolsocial.com/app/buy?view=confirmation to installed Cursor Review. Capture358 shows green check,Order placed,0 products/0 total,0 deliveries,and current saved recipient/address. This is a device-reproduced false-success state,not a completed order/payment.
Expected: require authoritative confirmed purchase identity and nonempty accepted orders before any success claim;otherwise show unavailable/recovery or return safely without inventing success or using an unrelated saved address.
Source: journey_router.dart2025 maps confirmation query;buy_v2_screen.dart544-546 directly sets initialView;buy_v2_views.dart8739-8804 unconditionally renders success/confirmed totals and selectedAddress. Normal completion path session11231-11261 is separate and was not invoked by this test.
Impact: a stale/shared/malformed link can tell a customer an order was placed despite no purchase. Real payment/account backend behavior remains unqualified. Do not fix during this audit. Evidence358 retained. View order details opens existing Active orders with unchanged12active/2delivered359. Reopening link then Continue shopping returns Shop/empty cart360. No new order/payment created by tested navigation.


## RV6-D010 - Recovery return changes selected destination while retaining order detail
- Local implementation qualified 2026-09-14: recovery entry no longer overwrites the current session destination with generic route defaults before capturing return context. Nine tests cover Orders action/Android Back, unavailable Help fallback, routed Shop Chat Help/Back and retained Wholesale origin. Full screen suite266passed/0failures; final focused9passed (overlapping), analysis zero issues; two Flutter return captures reviewed. Original Redmi371-373 remains pending successor-APK verification; status stays open.
Status: open. Severity: minor navigation inconsistency. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: open existing MS-240782 via declared HTTPS /app/buy/order/MS-240782 (371;Orders selected). Open declared /app/buy?view=recovery&recovery=delay,then Return to order372-373. Same order/detail retained,but Shop is selected in bottom rail instead of original Orders.
Expected: exact return context includes originating destination as well as order ID;tracking should restore original Orders selection.
Source: buy_v2_screen.dart527-529 overwrites destination with initialDestination before openRecovery;session11548-11560 records that replaced destination in origin. Generic recovery link defaults to Shop in journey_router. Conditional Help and other origin contexts need separate checks. No order/data mutation or implementation.


## RV6-D011 - Wholesale product repeats summary data across several content sections
- Local implementation qualified 2026-09-14: identical summary highlights/specifications/generated description are filtered in Wholesale/Bulk as in Shop, including the displayed brand fallback. Distinct supplier facts and purchase/compliance information remain. Empty content no longer leaves extra spacing. Twelve Shop/Wholesale/Bulk100/200% cases pass; screen suite278passed and two affected D007 return checks passed; analysis zero issues; four final Flutter captures reviewed. Original Redmi407-410 remains pending successor APK; ticket stays open.
Status: closed; recorded r66.20 Redmi content acceptance passed. Severity: minor visual/content usability defect. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: Wholesale Fresh tomatoes1/10kg580 product407;scroll408-410. Product details repeats Brand not provided/variant/pack/policy;Product and pack information repeats product/pack/unit price;Highlights repeats variant/unit price/policy;Specifications repeats brand/pack/variant;Description repeats title/variant/pack/unit price. Customer must scroll through repeated information before ratings/reviews. This is actual default content,not distinct technical specifications.
Expected: preserve useful supplier-specific information while suppressing identical summary-only highlights/specifications/generated description in Wholesale as in Shop. Keep the price/MOQ/pack decision accessible;do not remove genuinely distinct supplier facts.
Source corroboration: buy_v2_views.dart3877-3910 suppresses identical content only when destination is Shop (`!shop` admits all Wholesale duplicates). This is a frontend deduplication gap. Physical scope verified for this Wholesale listing;other products/Bulk require separate qualification. No implementation.



- Successor acceptance: captures rv620-084 through089; summary-only Highlights/Specifications/generated Description removed, retained commercial details and Wholesale Back. APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. UAT.md defines physical scope, no global deduplication claim. No child.

## RV6-D012 - Store listing count is labelled available despite non-orderable products
- Local implementation qualified 2026-09-14: full Store count now says products listed in neutral text, with singular/plural wording; product availability/Add restrictions unchanged. Required closed-Store setup at200% exposed a111px status-badge overflow; its label now wraps without truncating status or changing rules. Six closed/open/mixed100/200% cases and76 Store catalogue regressions pass; analysis zero issues; four final Flutter captures reviewed. Original Redmi423/428 and affected closed-status setup remain pending successor-APK qualification; status remains open.
Status: open. Severity: minor customer-copy inconsistency. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: closed Pet Family Store423;View all428. Header says Retailer - 4 available products in green while all four cards say Store closed and expose information instead of Add. Count describes listed products,not current orderability. Closed state and purchase restriction remain correctly enforced.
Expected: use neutral listing count or distinguish listed from currently orderable products;do not label total listings available when current facts reject ordering.
Source: buy_v2_catalogue.dart6916 interpolates products.length with literal available products,without per-product orderability. No implementation;other unavailable/mixed inventories require follow-up qualification.

## RV6-D013 - Store conversation expands without any additional content
Status: open. Severity: minor empty-action/spacing defect. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: Pet Family Store431 Ask opens correct conversation432. Expand Store conversation433 reveals only a divider and blank spacing, with no extra facts or destination. AndroidBack434 restores exact Store. No message sent;automatic draft retained unsent.
Expected: expose expansion only when additional facts or an applicable product action exist;otherwise retain a compact static context summary. Do not invent missing facts.
Source corroboration: chat_thread_screen.dart _ChatCommerceContextCard near1966-2055 always constructs ExpansionTile with divider/spacing;fact rows depend on decisionFacts and View product depends on productAppRoute. Store-only context has neither. Shared Chat presentation owner;Buy supplies Store context. No implementation during the audit.
Local qualification2026-09-14: corrected empty context presentation in chat_thread_screen.dart; facts/action contexts remain expandable, Store-only summary is static. During required connected verification, normal/direct Buy entry exposed missing Store overlay after Chat Back despite correct product return. Buy-owned route visibility fallback now restores the matching pending Store once with request/session/account guards; stale/rejected context is not reopened. No shared router/auth implementation changed. This necessary local return dependency is separate from D014 warm-order-link qualification, which remains pending.
Eight real-app cases cover Shop/Wholesale,100/200% text, normal/direct product entry, both Back controls, repeat enquiry, retained unsent draft and exact Store/product/cart context; additional account-context rejection fixture. Final connected328checks passed, analysis zero issues; eight actual Flutter captures reviewed. Focused8 overlap328. Owners, diagnostic limits, admission da9555f36919292a19f74ee1bff162a5730dec27, source preservation and25artifact hashes are recorded in UAT.md. Status remains open pending successor Redmi APK verification of431-434 and affected return behavior; no APK/device action or closure.

## RV6-D014 - Warm order link with Store overlay produces navigation error
Status: open. Severity: high in installed review APK (Buy interrupted by error screen);release behavior unverified. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction: Pet Family Store sheet remains open after Other Store navigation and Back440. Deliver declared HTTPS https://moolsocial.com/app/buy/order/MS-240782 to installed package. Capture441 shows Flutter navigator.dart assertion line5909 !_debugLocked rather than order. App-scoped logcat at07:33:45 additionally records navigator.dart3249 !navigator._debugLocked in _RouteEntry.handlePush. Exact root cause not established;do not equate assertions with release behavior.
AndroidBack442 leaves app to prior Android Display task. Explicit normal activity reopen443 then settled444 recovers Shop catalogue;requested order context is not restored. No force-stop,uninstall,clear-data or order/payment mutation. Saved badge remains1;full saved/address preservation check remains pending.
Expected: serialize declared-link navigation with modal dismissal safely;reach requested order or show recoverable unavailable state without error or unrelated task exit. Shared route/modal integration owner must investigate;no product implementation during audit. This is distinct from recovery rail-selection D010 and sign-in cancellation D006.

Local qualification2026-09-14: reproduced Navigator finalizeRoute lifecycle failure followed by !_debugLocked using the real app and simulated platform pushRouteInformation for the declared HTTPS order URL, over both original Store states. Corrected Buy-owned showBuyV2PartnerCatalogue to await the sheet route's completed future instead of manually reversing an already removed route; dispose the controller after overlay completion. No shared router, native, auth, policy/checker or backend change.
Final19 focused cases pass across Shop/Wholesale, root/nested/returned/full Store overlays,100/200% text, link during opening motion and missing-order recovery. Exact Cart/Saved-ID/address preservation and return behavior asserted. Final connected423checks passed, analysis zero issues; six final Flutter captures reviewed. Focused19 overlap423. Full source/test owners, failure and setup corrections,18artifact hashes and limitations are in UAT.md. Status remains open pending successor Redmi verification of440-444 and affected Store depths with exact APK checksum; no host-to-device or release-safety claim, no APK/device action.

Prebuild combined regression follow-up2026-09-14: awaiting modal completion exposed six product-origin scroll restoration failures in existing R5 007/R66 nested Store Cart cases. The restoration callback could be queued after the final animation frame. Buy screen now requests a frame for that existing guarded callback; controller lifetime, account/session/generation guards and return identity remain unchanged. All8 R5 007,22 R66 nested Store Cart and19 D014 warm-link checks pass without assertion edits. Final combined qualification remains pending; no Redmi closure. See successor qualification evidence in UAT.md.

### RV6-D003 additional occurrence - downloaded invoice relative delivery promise
Round44 capture480:existing saved MS-NEW-09 PDF opens on Redmi at08:07 and shows Expected: Delivery in12min with no recorded-time qualifier. Same order tracking previously labels this as last-recorded/unavailable. This is another output of the existing freshness-loss defect,not a separate counted defect. PDF line source buy_v2_invoice_downloader.dart102 writes raw order.promise;on-screen invoice source buy_v2_invoice.dart546 does likewise (source correlation,not a new on-screen invoice reproduction this round). Preserve an absolute promised window or a clearly dated original estimate in a historical document;do not present an undated stored relative countdown as current expectation. Correct invoice identity/item amount does not qualify this freshness claim. PDF bytes matched retained artifact SHA256 D618A5FF426512D2B2D30DCC12B6BCBF528D40E9FEB532C0D9CEE146C8FCD2E2. No PDF or source edited.

## RV6-D015 - Recently viewed offers Add for non-orderable products
Status: open. Severity: moderate customer action/availability inconsistency. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction:SavedShop -> Sort/filter483 -> Shoppingtools484-485 -> Recentlyviewed486. Adultdogfood from closed PetFamilyStore shows Delivery time confirmed at checkout and enabledAdd;Dailycare shampoo says Currently unavailable but also enabledAdd. Taps487/488 leave Add unchanged and no visible recovery explanation in retained sheet captures. Product489 explicitly confirms Storeclosed/tomorrow8am;AndroidBack490 returns exacthistory. No item added or restriction bypass observed.
Source:_RecentlyViewedProductInfoRow7486 onward displays buyV2BuyerDeliveryPromise in green and unconditional onPressed:onAdd. Parent7420 calls session.addProduct without handling returnedfalse or presenting sheet-local feedback. Session10071 onward correctly rejects closed/unavailable and emits notice. Expected:consistent orderability/closure explanation and appropriate unavailable/recovery control on history rows;rejected action feedback must be visible in the sheet. Do not weaken session restrictions. No implementation;existing D012 misleading Store count is a separate surface/problem.

Local qualification2026-09-14: Recently Viewed now reuses the catalogue offer decision, shows closure/unavailability detail and Details instead of Add for non-orderable products. Rejected session additions show their actual explanation above the sheet with Close/View product recovery; session restrictions unchanged. Six focused320x568100/200% cases pass for the two recorded Shop products and Wholesale rejection, including product/Back/history and Cart/address retention. Twelve final Flutter views reviewed; new dialog fit corrected before qualification. Connected339passed before the final dialog-only fit refinement; final affected6+29passed, analysis zero issues (overlapping counts). Exact owners, evidence hashes and limitations in UAT.md. Status remains open pending complete successor Redmi483-490 verification; no device closure or APK.

### RV6-D003 additional occurrence - Shopping settings alert freshness
Round48 captures510-511:Shopping settings -> Shopping alerts shows Delivery update / Shop order Delivery in12min / Updated recently. Tap opens MS-NEW-09 tracking with LAST KNOWN;Last recorded estimate Delivery in12min;live updates unavailable. The alert loses the freshness qualification visible at its own destination. Same existing freshness-loss defect;no new distinct count. This is physical UI evidence,not proof of live delivery or provider timestamps. Alert route source catalogue5015 uses beginShoppingAlertVisit and router.push with origin restoration;exact alert-data producer mapping remains to reconcile.

## RV6-D016 - New Shop offers alert opens ordinary catalogue
Status: closed; recorded r66.20 Redmi Offers destination and Back acceptance passed. Severity: moderate navigation/destination failure. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction:Shopping settings -> Shopping alerts510;tap New Shop offers from516. Destination517 is ordinary Scheduled Shop product grid with Shop selected,not Offers or its product/payment offer content. AndroidBack518 correctly restores alert sheet. Customer cannot reach advertised offer results through this alert. No cart/order/message change.
Source:buy_v2_shopping_alerts.dart158 onward maps offer to /app/buy?sub=offers;catalogue5035 pushes generated location. Screen1811 _openOffers explicitly sets _offersActive and same route when using normal navigation. Exact route-initialization cause is not yet proven;do not claim unsupported query without inspecting route parser. Expected:alert opens actual Offers surface,retains origin,Back restores alert list. Source cause and correction remain unimplemented.

Local qualification2026-09-14: reproduced missing actual Offers view in real-app alert navigation. Route and query were already correct; Buy now initializes the existing Offers flag before first render instead of relying on a later session notification. Four focused checks pass, including repeated alert-to-Offers navigation and Android Back, Cart/Saved/address preservation and first-frame Offers/ordinary Shop. Connected327passed, analysis zero issues; four Flutter captures reviewed at100/200%. UAT.md records exact owners, failure, correction,10artifact hashes and limitations. Still open pending successor Redmi510,516-518; no device closure, APK, router or backend change.

Redmi acceptance2026-09-14: captures097-103 verify actual Offers destination and restored original alert list. APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. See UAT.md; historical local-only qualification above is superseded for this recorded reproduction. No child found.

## RV6-D017 - Saved GST profile selected chip has unreadable identity
Status: closed; recorded r66.20 Redmi selected-profile contrast and affected actions passed. Severity: moderate visual identification failure. Redmi TG8HCYTGGQT885OF;UAW-CURSOR-REDMI-V6-REVIEW-20260913.
Reproduction:one isolated wheat pack279;Confirm order -> enable GST -> Add;enter local test name AuditRedmiTest, host-fixture GSTIN and test billing text;leave temporary reuse enabled;Use GST details. Captures691 and settled692 show dark selected Saved GST details chip with no readable name and low-contrast check/remove icons. The separate green current-details card is readable. Customers cannot identify the saved profile through its chip, especially when choosing among profiles. Expected:readable profile identity and selected/remove affordances. Source cause not established;no product correction. No order or payment submitted.

### RV6-D017 source correlation
Buy GST InputChip at buy_v2_views.dart6158-6175 uses Text(profile.legalName),selected state and no explicit foreground styling. Shared core/design/mool_theme.dart174-185 supplies selectedColor navy and labelStyle navy;secondaryLabelStyle white is separately defined. This supports the captured selected-chip contrast failure;exact Flutter theme resolution should be verified during correction. Prefer a scoped Buy fix or separately owned shared-theme regression assessment;no ownership expansion or implementation during this audit.


Local qualification2026-09-14: reproduced1.0rendered label contrast on selected navy chips in Shop/Wholesale100/200%. Buy-only InputChip styling now sets white selected text/check/remove icons and navy unselected foreground, preserving font and callbacks. Four focused selection/contrast/removal-cancel cases and54connected GST/checkout cases pass; analysis zero issues. Eight qualified Flutter captures reviewed;29artifact hashes, fixture/setup corrections and full limitations are in UAT.md. Still open pending complete successor Redmi691-692 and affected profile actions; no device closure, APK, shared-theme or backend change.

Redmi acceptance2026-09-14: captures104-124, selected chip117, Keep119, named removal120 and restored empty cart124. APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. UAT.md records scope and restoration. No child; historical local-only status above is superseded for recorded acceptance.

## RV6-D018 - Product Back loses paginated search destination and position
Status: open. Severity: moderate navigation/retention failure. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913; APK SHA256 97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7.
Reproduction: Scheduled Shop -> search milk -> keyboard Search after settled query (898) -> Next (899, range41-80) -> open Toned fresh milk1184 (900) -> Android Back. Settled902 returns main Shop catalogue starting milk8/cereal74/chocolate144, not originating search page41-80. Query milk is retained but page and dedicated search surface are lost. Capture901 is a transition frame, not a separate blank-screen defect. Expected: return to the same search result page and retained query so the customer can continue browsing without repaging. No cart mutation or real transaction. Distinct from related-product Back D007: origin here is paginated search results. Ordinary catalogue page return passed round124; it does not cover this branch. Root cause and implementation remain pending; preserve exact route/search context in correction.


### RV6-D018 recovery clarification
Capture904 after explicitly reopening the search field restores range41-80 and milk1184. The search pager state is retained internally: the confirmed failure is wrong Back destination and visible loss of browsing position until an extra search tap, not irreversible cursor/data loss. Clearing query905 and Done906/settled907 restores ordinary Scheduled Shop, Saved1 and empty cart. Correct the return surface; do not reset or replace preserved search state unnecessarily.


**Local implementation disposition (14 September 2026):** D018 corrected in Buy screen/test owners. Eight focused checks and 379 connected checks passed (overlapping counts); analysis zero issues; five actual Flutter captures reviewed. Search page/query/offset return is retained for Android/content Back and cart roundtrip; stale account/query/mode context is rejected. See UAT.md D018 qualification and hashed evidence. Remains open pending successor-APK Redmi acceptance of 898-904; host results are not device closure.

## RV6-D019 - Minimized delivery rail retains collapse chevron instead of delivery identity
Status: closed; evidence-reconciled and successor Redmi135-139 confirmed. No product change justified. Severity: minor visual/state feedback. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913.
From Scheduled Shop908 with bike9+ rail, open delivery909 (12 deliveries;MS-NEW-09). Tap panel Minimize chevron643,1162. Panel closes910;settled911 retains only downward collapse chevron in rail, with bike/count absent. Tap rail reopens912 same order. Repeat Minimize913 shows same result. Reopen914 then Hide915 restores bike9+ correctly. Expected: minimized status remains identifiable as deliveries with the appropriate icon/count and show affordance. Actual functional reopen works; no claim of lost order data or inaccessible tracking. Source screen1381-1423 chooses collapse icon only when expanded; screen1584 and2766-2768 bind Minimize to expanded=false. Exact cause of stale displayed state is unproven; no implementation. Hide restores observed initial rail appearance; sound off and Keep off unchanged.


**Evidence correction (14 September 2026):** The original narrative above is preserved for traceability but is contradicted by the original images. Captures910/911 and913 show bike +9+ after Minimize; hashes exactly match EVIDENCE.csv. Full-app normal/200% local checks pass on unchanged product code. See UAT.md D019 reconciliation. Do not count as an implemented fix or new device closure. Retain the bounded successor-APK confirmation; no broad retesting.

Redmi acceptance2026-09-14: Minimize and Hide retain bike9+; reopen preserves MS-NEW-09 and12 deliveries. Captures135-139, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. See UAT.md. No child.

## RV6-D020 - Message audience sheet clips final privacy explanation
Status: closed; recorded r66.20 Redmi description fit and dismissal passed. Severity: minor visual/content accessibility. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913; font_scale1.0 confirmed.
Reproduction: public Buy -> Chat -> More -> Chat settings -> Privacy and spam -> Who can message you. Captures931 and settled932 show No new conversations explanation only as Existing conversations stay at the Android navigation boundary. Upward swipe933 does not reveal the rest. Source chat_settings_screen.dart529 supplies Existing conversations stay available; no one new can start. Customer cannot read the complete consequence before choosing a privacy setting. Expected: complete readable option descriptions above system navigation, with scrolling when needed. Source85-125 uses a Column in sheet padding; exact layout correction remains unimplemented. No permission choice selected and no service update issued. Separate from existing Buy address validation clippingD004; distinct shared Chat surface and reproduction.


**Local implementation disposition (14 September 2026):** D020 corrected with bottom-inset scroll padding. Two focused normal/200% Android-inset checks and12 connected Chat settings checks pass; analysis zero issues; two actual Flutter captures reviewed. See UAT.md for admission and hashed evidence. Remains open pending successor Redmi reproduction931-933 and dismissal; no host-only device closure.

Redmi acceptance2026-09-14: captures140-146 show complete final explanation above Android navigation and unchanged Everyone after dismissal. APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. See UAT.md; supersedes historical local-only pending status for this reproduction. No child.

## RV6-D021 - Empty-cart catalogue retains expanded quantity space until Shop reentry
Status: closed; r66.20 Redmi quantity and compact-grid restoration passed. Severity: minor catalogue visual density/state refresh. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913; APK SHA256 97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7.
Reproduction: Scheduled Shop empty cart1037 -> Add wheat2 -> quantity edit/update/cancel round150 -> remove both units using minus. Capture1043 shows Add restored, but first-row bottom remains about880 rather than initial792. Settled1044 retains the same extra88 physical pixels per row. Switch to Wholesale and back to Shop:1045 restores row bottom792 and the compact image area without changing cart or saved state. Expected: restore compact empty-cart layout when quantity controls disappear, without requiring module reentry. Customer impact: fewer products/actions visible while browsing after cart removal. No clipped content, lost item or broken Add claim. Source catalogue8801-8864 conditionally adds quantity-label height; exact stale width/state cause remains unproven. This promotes round150 QTY-ROUND150-03 observation to confirmed minor defect; it is not a second independent finding. Original Saved1, empty cart and Scheduled mode preserved. No implementation.


**Local implementation disposition (14 September 2026):** D021 corrected by resetting retained grid quantity width when all displayed quantities are zero. Focused2 and connected408 checks passed (overlap); final analysis zero issues; four actual Flutter captures reviewed. See UAT.md for baseline limitations and hashed evidence. Remains open pending successor-APK Redmi1037-1045 quantity workflow; no host-only closure.

Redmi acceptance2026-09-14: captures147-162 verify original quantity edit/update/cancel/removal and directly affected Wholesale/Offers restoration. APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. See UAT.md. No child; all test items removed.

## RV6-D022 - Shopping area chooser does not identify the selected area
Status: closed; r66.20 Redmi area indication, filtering and restoration passed. Severity: minor selection/state feedback. Redmi TG8HCYTGGQT885OF; UAW-CURSOR-REDMI-V6-REVIEW-20260913; APK SHA256 97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7.
Reproduction: original Any-area catalogue -> Shopping area1087 -> choose Jaipur ->1088 suppliers change to Mool Market000002;search milk1089 explicitly reports Jaipur. Clear active query and reopen Shopping area1090: Jaipur is an ordinary unmarked row, no active-city summary is shown, and the chooser looks the same as1087 before selection. The In this area chip marks a scope, not the selected city. Expected: identify active city/area (or Any area) in the chooser so a customer can verify the scope before choosing another supplier. Actual selection works; no claim of wrong filtering or lost address. Source catalogue1719-1743 renders ordinary Any area/area ListTiles with no selected indication. Different from provider lookup B001 and earlier address validation clipping. Tap Any area1091 restores original catalogue supplier000001 and saved wheat marker;Saved1 and emptycart preserved. No delivery-address edit, permission change or product implementation.


**Local implementation disposition (14 September 2026):** D022 corrected with current-area summary and selected city/Any-area indication. Two actual tap/reopen checks and26 connected area checks pass; analysis zero issues; four Flutter captures reviewed. UAT.md records evidence and fixture limitations. Original remains open pending successor-APK Redmi1087-1091; no host-only closure.

Redmi acceptance2026-09-14: captures163-169 verify selected Any area/Jaipur summary and checkmark after query clearing/reopen, then original scope restoration. APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. See UAT.md; no child.

### RV6-D001 local implementation qualification

Area guidance now follows actual showAreaControl availability. Four focused regressions reproduce the old area-absent failure at normal/200% text and pass after correction;full search-recovery suite27passed;analysis zero issues;four actual Flutter component captures reviewed at320x568. See UAT.md RV6-D001 implementation section for owners,admission,results and artifact hashes. Original physical reproduction037-038 must be checked on the later successor APK before closure. This does not add a physical pass or close the defect. Founder authorized implementation of22 findings after the historical audit freeze;all original evidence remains retained.

## RV6-D005-C01 - Saved Hindi preference resets to English after cold relaunch

- Parent: RV6-D005. Status: open, device reproduced; no implementation authorized in this round. Severity: moderate.
- Actor/outcome: signed-out Buy customer choosing Hindi as a saved language preference expects the selected preference and honest coverage disclosure to survive restarting the app.
- Reproduction: Personal profile > Language preference > Privacy & preferences > Language > Hindi; observe Hindi preferred / App screens: English; Back to profile (same summary), Back to Shop. Force-stop only com.moolsocial.app.cursorreview, cold launch declared MainActivity, account > Privacy and preferences > Language.
- Actual: preference summary and selected radio return to English. Before restart picker explicitly promises Selecting Hindi saves your preference only. No sign-out, account switch, data clear, uninstall or preference restoration was performed between selection and observation.
- Expected: retain the selected preference across restart, or explicitly disclose a temporary selection instead of claiming it is saved. Buy translation itself is outside this child.
- Evidence: rv620-055 through063; selection057/profile058, cold launch060 (am start Status ok/COLD, tool7472bd), English summary062 and radio063. Redmi TG8HCYTGGQT885OF, r66.20, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8.
- Scope/ownership: shared preference persistence or review startup dependency; cause not yet established. Host restored-session tests did not establish actual Android durability. No claim this affects authenticated production accounts. Original English state is currently restored by the observed reset; no user data cleared.
- Qualification: immediate D005 disclosure and Hindi glyph rendering pass, full D005 acceptance remains open because directly affected retention fails. Distinct from unavailable translation disclosure; deduplicated as one child. No code/checker/policy change or new APK.
