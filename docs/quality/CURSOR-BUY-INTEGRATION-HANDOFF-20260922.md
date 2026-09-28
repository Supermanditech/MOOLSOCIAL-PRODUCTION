# Cursor Buy integration handoff and new-baseline request — 22 September 2026

## Qualified Cart preservation checkpoint — 27 September 2026

Pre-commit ownership reconciliation: gate identified wholesale_checkout_receiving_lines_test.dart under historical /root/cursor_redmi_v6_audit_20260913 claim. Live-agent inventory showed only /root running. Under existing primary-only exclusive-owner protocol, transferred this one exact approved wording-test owner from historical claim to current /root claim (155->156,44->43). No registry entries, policy rules, gate logic, permissions or source files changed in this reconciliation. Original failure and current scope recorded; subsequent pre-commit gate must pass.

Final qualification PASSED:812 distinct scenarios /871 selected references, both successful terminal logs, zero failed/skipped scenarios, no hit-test/overflow warnings and unchanged source51a71dae7975944d35ce282d144633ca06df88bd945be0895778e01570fd3161. Receipts bound in config/buy-founder-regression.json from cart-approved-qualified-20260927. Source analysis clean;74 focused cases also passed. Two inspected Cart golden references updated to the approved UI; original references and generated diagnostics retained locally. Latest Redmi hot reload2833ms and comparison-to-Cart return showed correct Item total / Items subtotal,2packs/1160. Navigation strip founder-approved; overall fresh visual acceptance is not claimed for every historical ticket.

Checkpoint preserves approved Cart navigation, inline coupon/payment choices, compact tabs, solid bottom35% benefit colours, accessible contrast and neutral amount wording. Existing action-polish parent remains in_progress because delivery-instruction redesign is queued; comparison R6633-D05-A01 remains reopened/queued. Neither queued redesign is implemented. No backend/Maps/APK/integration work. Required pre-commit gate and normal push/readback follow this qualified source; do not infer release or all-backlog completion from the checkpoint.

## Queued delivery-instruction selector — 27 September 2026

Founder next queued request: replace oversized Trade receiving cards with compact radio-style choices scrolling horizontally. Current implementation uses138px width/min82px height and destination-scoped state. Proposed common heading Delivery instructions; mixed basket retains independent Shop delivery / Wholesale delivery groups, supplied eligible options and No special instruction mapping to existing null choice. Do not merge selections across destinations or invent per-shipment authority; future Store/shipment grouping depends on actual provider fulfilment IDs. Test long labels/enlarged text, radio semantics, clear/select persistence, Cart/checkout return and no cross-basket leakage. Status QUEUED / NOT IMPLEMENTED / NOT TESTED. Recorded under existing BUY-ACTION-POLISH-20260926-01; no duplicate registry ID invented.

## Reopened comparison design defect — 27 September 2026

Founder rejected the current Redmi Compare prices layout. Reopened existing R6633-D05-A01 (comparison repeats full product cards and delivery/price content), without creating a duplicate ticket. Evidence: apps/mobile/build/cart-compact-tabs-20260927/redmi-comparison-founder-defect.png, SHA256 4e1b5d8b2c9a3ee5584572d342b9220fd60ce5a39d5e6efe86655401f8c11487. Observed oversized header, tall padded cards, blank right-side space, repeated price/delivery/date wording, inconsistent text hierarchy and low visible result density. Scope: compact aligned comparison rows/table, standard text, aligned Add/Save, full-width use, maximum real supplied results with scrolling/pagination; preserve exact item/pack/quantity and total/delivery truth. Test large amounts/long names/enlarged text, provider refresh and Cart return. Status OPEN, redesign NOT IMPLEMENTED / NOT QUALIFIED; fresh Redmi founder approval required. Registration does not revoke unrelated technical receipts or approve this design.

## Cart inline benefits and compact Store navigation — 27 September 2026

Visual reference reconciliation: final pre-reference replay had810/812 checks pass; two Cart golden references still represented pre-approved UI. Inspected Android360x800 and iOS430x932 generated images, verified approved new strip/inline benefits/neutral wording with intact totals and layout. Preserved prior two references and all8 generated failure images in apps/mobile/build/cart-reference-refresh-20260927. Restored tracked diagnostics changed by the failed test to their previously clean HEAD bytes; refreshed only the two existing claimed Cart reference PNGs. Both refresh cases passed and reference bytes exactly match the inspected images. Application source unchanged. Fresh full replay uses cart-approved-qualified-20260927; only that successful unchanged-source replay may qualify final commit.

Approved neutral wording update: Cart product/checkout receiving line uses Item total, header and checkout product aggregate use Items subtotal. Cart footer uses Cart total (incl. tip when applicable); final checkout/invoice already uses Order total. Replaced landed-price wording in freight explanation with plain included-in-price wording; freight and GST conditional facts and all amounts unchanged. Invoice already has Items subtotal, Order total and conditional charges, so no invoice runtime edit needed. Source analysis clean. Focused wording tests repaired only superseded text and scoped footer finder (the global Cart dock also has Cart total); exact amount/freight/MOQ assertions retained. Latest Redmi reload2833ms; comparison -> Android Back returned to same Cart2packs/1160, captured apps/mobile/build/cart-neutral-final-20260927/redmi-cart-wording.png. Final replay now cart-neutral-final-20260927. Founder instructed comparison redesign to remain queued, not implemented.

Current implementation supersedes earlier CTA previews: full-width Browse more products / Compare prices / Offers strip with separate chevron actions, approved by founder. Browse retains original context route; Offers uses existing Offers destination; Compare reuses exact-product comparison with a Cart-product chooser for multiple lines and provider refresh validation. Four new normal/200% single/mixed basket navigation cases cover actual action/return and unchanged quantities/totals. Test setup now selects All baskets after browsing Shop before expecting a mixed-product chooser; no runtime scope rule was weakened.

Latest Coupons/Payment offers refinement: text-fit selector with subtle highlight, no full-width filled tabs, horizontal overflow at enlarged text; remove duplicate heading row when expanded and put Collapse beside the selectors. Empty basket still retains the header/close control. Reopen test now scrolls the collapsed header into view before tapping. All59 focused cases passed, five-owner analysis clean. Redmi hot reload4215ms and apps/mobile/build/cart-compact-tabs-final-20260927/redmi-compact-tabs.png inspected. Cart2packs/1160 retained. Current comparison design separately rejected/reopened above; no redesign or closure claimed. Final812-case replay/Git checkpoint pending. No APK.

Preceding approved Store checkpoint ecc7b9325d7541c9825c4b70ce75fdd7aeb23e2e was committed/pushed, local/remote equal and clean; handoff gate passed. Founder next screenshot identifies blue oversized Store/Browse controls and excessive whitespace, plus a request to select coupons/offers within Cart. Internet interruption resumed without losing checkpoint.

Implemented under the existing public action-polish ticket: shared Cart neutral Store/Browse row; one compact expandable Coupons and offers panel; eligible coupon/payment selection and removal directly in Cart. Existing provider adapter, basket constraints, totals, payment confirmation and checkout pricing remain authoritative. Removed obsolete separate benefits route, completion bar and duplicate entry cards. No Store workspace/backend/configuration or APK change.

Child findings during local testing: (1) default expander state collided with Cart scroll restoration; replaced with local controlled state and retained Cart scrolling; (2) payment status duplicated in expanded and collapsed content; render summary only while collapsed; (3) stale separate-page test navigation was updated to scroll to the actual inline controls before tapping, without dropping eligibility/totals checks. Scope-switch regression added: same Cart route, correct destination offers, preserved quantities/total. Historical test names remain to preserve ledger identity but their completion action now collapses inline content.

Latest CTA Redmi preview: hot reload2500ms, actual cart-price-cta-final-20260927/redmi-cta.png inspected. Full price/offer wording fits one thin horizontal line on Redmi. Four-owner analysis clean. Preview left on Cart; founder approval and final replay/Git readback remain separately pending.

Latest CTA amendment supersedes the larger outlined Browse button: slim #EFEAF7 highlight with #51356B text, text-fitted width, 44px accessible target, no raised border/shadow. Add “Compare prices & find offers” only when the complete line fits available width; otherwise retain Browse more products. Rejected “Complete your basket” wording removed. Existing Browse navigation reused; no unsupported discount/lowest-price claims. Final replay uses cart-price-cta-final-20260927; all prior incomplete runs remain preserved and do not qualify this source.

Latest founder refinements: Browse more products is an outlined white CTA; multiple coupons/payment offers scroll horizontally inside the expanded Cart panel, with the next card visible. Each card uses a distinct adjacent solid pastel colour across its bottom35%, decorative coupon/wallet mark, and Select/Remove alongside the title. Terms use the full width below, removing the standalone action lane. Colours remain unchanged through select/remove and scrolling. Source analysis is clean. Focused55 checks passed before the final adjacent-colour repair; final808-case replay is running and must pass before commit.

Additional child repairs: basket-switch recreation now retains expansion in the Cart owner; absent Store context no longer leaves a blank full-width navigation container. Device found neighbouring offer IDs hashing to the same colour, repaired to alternate palette entries in the displayed offer sequence. Existing normal/200% coupon tests now verify title/action alignment, opaque distinct adjacent bands, exact savings/quantity, removal restoring original height and unchanged colour. Compiler typo was repaired before successful reload; failed/cancelled logs are retained and excluded from qualification.

Redmi preview restored with hot restart8084ms after the installed app restarted into its older bundled source, then final colour/layout hot reload4075ms. No APK was built/installed. Current screenshot: apps/mobile/build/cart-solid-final-20260927/redmi-offer-final.png. No separate coupons route; no payment or checkout submitted. Provider campaign publication remains a Store dependency; review fixtures do not establish backend integration. Founder visual approval of these new Cart changes remains pending. Full replay and Git synchronization remain pending until recorded below. Final contrast audit repaired green3.44:1 and muted4.16:1 on coloured bands to #17652C and #505568 (minimum5.34:1 and5.52:1). Final reload2789ms; final cards/swipe inspected in cart-solid-qualified-20260927/redmi-offer.png and redmi-second-offer.png. Latest selection capture showed collapsed Cart instead, so it is not counted as fresh selected-state device acceptance; earlier selection/removal proof and local journey tests remain separately identified.

## Approved Store checkpoint and consolidated Maps inventory — 27 September 2026

Final checkpoint qualification: 753 distinct selected cases / 812 ticket references passed across47 files, zero failures, source unchanged: cac671ca16f78b2ee64b04423fefa5ab5be0c86c3f581cd3089664950e0bbb83. Both terminal-success JSON receipts are bound in config/buy-founder-regression.json (store-approved-accessible-20260927). Four-owner analysis clean; enlarged-text child repaired and Redmi reloaded7227ms. Founder-approved normal-size card retained. Git preservation requested; commit/push readback follows unchanged repository gate. Maps and follow-up Cart redesign remain explicitly open; no APK built.

Founder approval: stronger colour across the bottom 40%, no right-side ribbon, matching Visit text, compact three-row Store cards. This approval supersedes earlier rejected previews below. Runtime design is frozen for cumulative qualification and Git preservation. Latest Redmi hot reload succeeded (7299ms); three focused checks and analysis passed. Full selected replay and synchronization are being qualified separately; approval does not imply live Maps completion.

Inventory is a source audit, not device acceptance or authorization to activate deferred modules. Read-only coverage: Buy branch f6661a0ff84acc5009a668774a4222c6ccf95e19 plus current uncommitted approved UI; central production 745664fcfe0bdd9049065d7eb0644425462bcfe6; latest Store/add-product worktree ef5ab124c117699a412d2831a1de4cd100d2f296. Store worktree was not modified. Counts below are 12 scope groups, not 12 newly registered defects. Existing D10-C2 / CHILD-8-MAP-PROVIDER records remain authoritative; no duplicate IDs invented.

| Scope group | Found implementation / owner | Remaining dependency and disposition |
| --- | --- | --- |
| 1. Shared native Google Maps foundation | No Google Maps renderer dependency found in audited mobile pubspecs; current links use url_launcher. | Platform owner: SDK, restricted Dev key, actual package/signing SHA-1, API availability and approved billing. New native APK required. Pending before next map-enabled APK. |
| 2. Location permissions and GPS | features/journey01/journey_services.dart exposes LocationPermissionGateway and review gateway. | Verify production binding, denied/permanently denied/services-off recovery. GPS permission is separate from Maps; Store display alone needs no buyer GPS. Reuse shared owner. |
| 3. Public shopping area / place selection | buy_v2_content_contracts.dart BuyV2ShoppingArea and provider contract; buy_v2_session.dart resolves selection; catalogue has external View pin. Saved state retains Place ID. | CHILD-8-MAP-PROVIDER: real Places/location-to-authoritative-region wiring, India/serviceability boundaries, stale selection recovery. Do not treat a review place as production coverage. |
| 4. Store branch location publication | Public BuyV2StoreListing supplies name/address/area/region; collection capability does not contain coordinates. Latest Store publication serializes shopping-area Place ID, which is not proof of branch location. | Store workspace owns verified branch coordinates/optional Place ID, public name and exact storeId. Missing/withdrawn branch location must stay unavailable. Provider mapping pending. |
| 5. Store embedded map preview | buy_v2_store_address.dart currently opens external Google Maps; no embedded map. | Founder-parked next-APK prerequisite: short horizontal interactive map, expanded by default, collapse/reopen, exact named marker, pan/zoom, full Maps. Replace repeated top details only once real map is available. |
| 6. External directions and navigation return | buy_v2_store_address.dart, catalogue shopping pin and Work dashboard open Google Maps search. | Preserve exact Store identity, URL validation, unavailable-app/failure recovery, Back and Cart. External launch does not require implementing a separate Routes service. |
| 7. Checkout / collection location consistency | Public shopping-area and Store collection contracts are separate from map display. | Bind selected address/branch to authoritative serviceability/order/collection identity. No inferred distance, fee or collection pin. Integration acceptance must cover switching Store/address, stale location and order persistence. |
| 8. Customer live delivery tracking | buy_v2_views.dart accepts optional liveDeliveryMapBuilder; honest unavailable state exists. GeoPoint contract validates ranges. | D10-C2: authenticated assignment/shipment identity, fresh courier coordinates, ETA/state and real renderer. Cover Shop, Wholesale, Bulk, Offers and Store orders through shared owner; stop access on terminal order state. |
| 9. Store dispatch and Bulk/Biker location source | Work dashboard exposes tracking and unavailable live-rider state; latest Store dashboard still states live location unavailable. Legacy retailer_delivery_screens.dart uses painted _TrackingMap. | One shared authorized delivery source for Bulk/Biker, assignment/handover lifecycle, freshness/offline recovery and role access. Painted route is not live GPS. Backend/location publication remains pending, not enabled by UI approval. |
| 10. Customer location sharing with courier | Legacy features/buy/screens/buy_tracking_screen.dart has Share live location UI. | UI is not evidence of working secure streaming. Reconcile consent, recipient/order authorization, expiry/revocation and permissions before activation; reuse order location service, never permanent sharing. |
| 11. Passenger Ride / Captain route maps | ride_trip_screen.dart _RouteMap; captain_widgets.dart CaptainRouteMap and painter; multiple trip/request callers. | Existing illustrated maps are not Google integration. Passenger journeys remain deferred/protected. Do not activate them through goods-delivery Maps work. |
| 12. Other modules and potential location consumers | Food tracking is stage UI; Book source search found no Google renderer; manufacturer has authorized-route location wording. No concrete Google map renderer found by app-wide literal renderer/URL audit in Chat or Social. | Food, Care/Book, Social and broader manufacturer scope remain deferred. No new map feature inferred from an address label or Dart Map collection. Re-audit actual routed provider owners at integration before declaring app-wide device acceptance. |

Shared acceptance checklist: exact Store/order identity; invalid/missing coordinate and stale-location handling; key/API/network failure and retry; foreground/background lifecycle; permission denial/revocation where needed; map gesture/sheet scrolling; expansion/collapse; accessibility; external Maps return and Cart continuity; terminal delivery privacy; no fake routes, ETAs or GPS. Device/native checks follow a separately qualified APK. Existing provider tracking operations must not be mistaken for customer-authorized live location.

Enable only APIs required by the chosen implementation: Maps SDK for display, Places for actual place search, Geocoding only if an authorized conversion is needed, Routes only if in-app routing/ETA is required. Static Maps is not an interactive map substitute. No API, billing, credentials, backend, platform configuration or new APK changed by this inventory. Official setup: https://developers.google.com/maps/flutter-package/config ; key restrictions: https://developers.google.com/maps/api-security-best-practices .

### Follow-up Cart review captured before checkpoint

Redmi screenshot: apps/mobile/build/store-approved-final-20260927/redmi-next-review.png. Founder identifies oversized blue Store/Browse links, excessive vertical whitespace/right-side vacancy, and coupons/payment offers leaving Cart. Next bounded public-UI change: compact neutral Store/Browse row; expand/select/remove eligible provider benefits within Cart, preserving exact basket scope, totals, eligibility, offline/retry and existing provider adapter. No invented savings or backend activation. Current screenshot is Cart, not the approved Other stores card. Status: captured and source traced, not yet implemented. Source owners buy_v2_views.dart, existing benefit selection/cart relevance/screen tests. Reuse _CartBenefitCard, selectors and session cartBenefits/chooseCartBenefit/removeCartBenefit; replace navigation wrapper, not business rules. Required checks: inline action with unchanged route, scope switching, empty/withdrawn eligibility, apply/remove, large amount/text, Cart/checkout continuity and Redmi hot reload. This is launch-supporting public Cart polish; provider publication remains a Store dependency.

Qualification repair: full selected run passed750/753; three 200%-text nested Store journeys exposed a complete-word fit failure (Stone-ground). Repaired product/price row to reflow at enlarged text without reducing text scale or weakening tests. All three targeted journeys pass; four-owner analysis is clean. Redmi repair hot reload succeeded in7227ms (one library), without navigating away from the founder Cart. Fresh753-case replay running against repaired source. Previous failed receipts retained and not bound as passing.

## Store-details polish — 27 September 2026

### Store map: founder-parked prerequisite for NEXT APK — 27 September 2026

Status: PENDING, not implemented, not locally/device tested. Founder authorizes preparatory steps now; resume real integration before next APK. This is an explicit next-candidate prerequisite, not current hot-reload completion. No automated build gate is changed by this record.

Preparation completed: inspected current public Store listing/address owners and installed dependencies; identified external-only Maps launcher and absent embedded SDK/location binding; verified official Google Flutter setup and Android key restriction guidance. Existing card work is independent. No Cloud/API enablement, billing, credentials, platform/dependency edits or build performed.

Before the next build, in dependency order:
1. Store owner supplies a verified public branch location tied to exact storeId: public display name, latitude/longitude with validity/range validation and provenance; optional Google Place ID for precise external directions. Do not geocode synthetic review supplier addresses or infer coordinates from product origin. Obtain one real founder-authorized review Store location; missing/withdrawn location stays unavailable rather than mapping another branch.
2. Coordinate the current Buy UI owner with the platform/dependency owner for Google Maps Flutter SDK, pubspec/lock, Android manifest/config and minimum platform compatibility. Native zoom/pan means an SDK integration, not a fake image or WebView workaround. Use existing Google-first project/environment workflow, initially Dev only.
3. Verify Maps SDK for Android/API availability and approved billing configuration; configure a restricted key through the authorized configuration owner. Restrict to required API and actual Android applicationId + signing certificate SHA-1 for each intended candidate. Verify candidate values from its build manifest; do not reuse a guessed fingerprint, confuse SHA-256 with SHA-1, or paste key material into source/chat. Do not silently enable Places, Static Maps, geocoding or directions billing APIs.
4. Implement one shared short horizontal native map in the public Store-info sheet: visible/expanded by default, collapse/reopen, exact Store marker with supplied name, pan/zoom without stealing sheet scroll, open full Google Maps/directions. Replace repeated name/address/role/product text as requested; retain accessible Close/Ask and navigation. Data absence/loading/offline/key rejection receive an honest compact recovery state; current external link remains usable where valid. No buyer-location permission is necessary merely to display the Store.
5. Local checks: source contract validation, exact Store switching/no stale marker, default expansion/collapse, long names/accessibility, constrained map height, scroll/zoom gesture boundaries, missing/invalid data, load failure/retry, Maps return and Cart preservation. Check shared Buy/Wholesale/Offers/Store entry paths.
6. Reconcile all source/tests/records, cumulative regressions and required repository gates; commit/push and verify clean local/remote equality BEFORE requesting/building the next candidate. Existing map dependency stays visibly open until wiring/config checks pass; do not silently omit it from that candidate.
7. Build the separately authorized unique APK with native Maps included, then verify installed checksum and Redmi cold restart, real tiles/Store marker, zoom/collapse, external Maps return and failure recovery. Record child defects and repair before acceptance. Device acceptance necessarily follows installing that candidate; it cannot be claimed before build.

Official references: https://developers.google.com/maps/flutter-package/config ; https://developers.google.com/maps/api-security-best-practices . SDK setup, API/key availability and exact Store location are outstanding inputs, not completed configuration. Native map remains parked; no account/credential action is implied by this checklist.

Founder clarified MAP replacement (not a directions text bar): replace existing top Store-name/address/role/detail text block with a short horizontal Google map preview; expanded/visible by default, user can collapse and reopen. Store name belongs on its actual map marker; open full Google Maps/directions for that exact Store. Keep Close and existing Ask accessible without duplicate descriptive text. Comparison cards remain below. Do not invent location, map imagery, Store identity or route results.

Dependency audit: mobile pubspec has url_launcher but no Google Maps renderer; current BuyV2StoreAddress only launches external Google Maps search from Store name/address. BuyV2StoreListing carries name/address/area/region and optional collection capability, but no verified latitude/longitude, Place ID or authenticated preview contract; collection capability has no location. No Maps setup references found in searched mobile runtime/Android/config/script owners. This is a genuine Store/Maps integration dependency; in-app Maps cannot be represented as completed by an external link. Provider handoff needs verified branch coordinates or Place ID, public name and address tied to exact storeId; approved restricted Google Maps access and preview strategy. Static preview could use authorized Maps Static image and tap to full Maps; in-preview zoom requires native SDK/platform dependency and a rebuilt APK. Google requires enabled API/key and billing for Static map requests; no Cloud/API/billing changes are authorized by this UI request. No fake map, dependency/platform edit, removed working details, or APK performed. Map replacement is OPEN / NOT IMPLEMENTED / NOT TESTED pending actual integration inputs. Current bottom-tint card preview is independently implemented/tested. Acceptance after wiring: exact Store location/name, expanded default, collapse/reopen retention, Maps return, absent location/offline/retry, no stale cross-Store marker, normal/enlarged text and Redmi checks.

Bottom-only preview verified on Redmi: reload7299ms; apps/mobile/build/store-white-cards-20260927/redmi-bottom-only.png inspected. Right decoration removed, full-width bottom26%-strength tint confined to lower40%, colour-matched Visit text and darker readable detail text. Three focused cases passed after contrast child repair; analysis clean. Interactive-map vs directions-header question remains pending, no map SDK/provider work started. Git cumulative qualification and commit/push pending.

Latest request: remove right ribbon, denser horizontal bottom40% colour, coordinate Visit foreground; map/header request awaits clarification (embedded interactive map versus compact directions). Removed obsolete ribbon painter, restored full text width, tint26%, Visit uses matching dark purple/blue/brown. Contrast test detected prior muted foreground4.23:1; repaired details to #505568 without lowering4.5 threshold. Current Buy uses external Maps search based on Store name/address; no embedded-map SDK or Store coordinates in Store listing. No map/backend/dependency changes made. Final focused/device checks pending.

Compact header + bottom40% preview verified: seven focused scenarios passed including collapsed/expanded Store details at normal/200% text, navigation and card contrast. Analysis clean across4 owners. Redmi reload6208ms; inspected expanded and collapsed states, final screen apps/mobile/build/store-white-cards-20260927/redmi-compact-header-collapsed.png left open. Repeated top product/price/delivery removed; Ask visible once; address/fulfilment accessible on expansion. Cumulative qualification and Git commit/push pending; no APK.

Founder identifies duplicate top product/pack/price/delivery/role/address summary and unused width. Compact Store header now name15px + Ask + Close; secondary truth/fulfilment/address remains in one collapsed Store details expander. Removed duplicated product/price/delivery summary above comparison; Ask retained once in header. Existing four viewport tests now expand details to verify retained functionality. Bottom40% tint, ribbon and soft lift retained. Local/device qualification pending.

Founder asks colour horizontally across bottom40% and says ribbon/lift direction looks better. Add vertical fade only within lower40% (stops0/.6/1, bottom tint18% over white), keep narrow side ribbon and soft shadow. Darkest-tint contrast tested for all three Store colours; typography/spacing/routes unchanged. Device qualification pending.

Ribbon + lift preview verified on Redmi: hot reload6898ms, actual apps/mobile/build/store-white-cards-20260927/redmi-ribbon-lift.png inspected. Narrow coloured curves stay outside text; three-row content intact, soft shadows separate white cards. Seven ribbon layout/navigation/enlarged-text checks passed, then three shadow-impact cases passed; final analyzer clean. Screen left open. Cumulative qualification and Git commit/push remain pending; no APK.

Founder additionally requests card lift above background. Add one soft downward shadow (alpha31/255, blur10, offset0/3, spread-1) to same three-row ribbon card; no content-height increase or heavy colour fill. Ribbon-only seven focused checks passed; final shadow checks/device preview pending.

Founder requests reference-inspired curved ribbon on Redmi. Existing three-row WHITE comparison card retained; narrow two-layer lavender/blue/peach ribbon selected deterministically from Store identity, confined to rightmost24px with30px text inset and rounded clipping. Dark text remains on white instead of dynamically crossing colour; no provider role inference or new fields. CustomPainter is decorative/noninteractive; existing exact Visit route retained. Focused/enlarged-text/device checks pending.

Three-row preview now visible on Redmi. Seven focused checks passed; device inspection identified right-column prices not reaching edge, repaired with constrained right alignment, then three impacted card/navigation cases passed again and analyzer clean. Final hot reload5671ms; inspected apps/mobile/build/store-white-cards-20260927/redmi-three-row-final.png. White three-row cards show plain Visit, product/current price and delivery/unit price, no repeated role/availability/icon clutter. Screen left open. Cumulative qualification and Git commit/push pending; no new APK.

Latest founder approval supersedes black reference: implement quiet light THREE-ROW comparison and show Redmi. Row1 Store name / Visit; row2 product+pack / current price; row3 supplied delivery / unit value. Remove repeated Retailer, Available to add, decorative icons and nonessential variant metadata on card fronts; detailed product/Store pages retained. Reuse exact shared card and routes; preserve dynamic price and stale-unit guard. No backend/APK. Focused checks updated for this explicit simplification; qualification pending.

Correct BLACK reference now visible on Redmi: reload5931ms, inspected apps/mobile/build/store-white-cards-20260927/redmi-approved-black.png and left open. Seven focused scenarios passed including contrast, C14, navigation and enlarged text. Analyzer redundant-const info repaired without behaviour change; fresh analysis clean. Final cumulative qualification and Git commit/push remain pending. No APK.

Correction: founder attached BLACK-card screenshot and confirms this was the approved second attempt. Agent misinterpreted approval as white cards; white implementation is superseded, not accepted. Exact latest target: solid #111114, white names/product/prices, #DADAE0 metadata, compact white Visit store CTA, no gradients/coloured strips/price badges. Existing shared card updated; local contrast/navigation and Redmi verification pending. Preserve earlier evidence, do not claim white preview as acceptance.

Approved white concept applied and inspected on Redmi: reload5798ms; apps/mobile/build/store-white-cards-20260927/redmi-approved-white.png shows white compact cards, lavender/blue/terracotta thin accents, dark text, unboxed prices and outlined Visit store. Seven focused scenarios passed including 320px/200% text, navigation and C14; analysis clean. Screen left open. Full cumulative source qualification and commit/push remain pending; no new APK.

Founder approved second clean WHITE-card concept and explicitly requests application on Redmi. Implemented white surface with subtle grey border, stable muted Store-specific left accent, dark text, plain bold price and compact outlined Visit store. Removed superseded saturated palette implementation. Existing C14 assertion updated from old required-gradient styling to approved white surface while preserving exact Visit navigation checks. Focused/device qualification pending; no APK.

Distinct-colour preview verified: 3 focused scenarios passed, all 3 palettes >=4.5 white-text contrast throughout sampled gradients, analyzer clean. Redmi reload5558ms; inspected redmi-distinct-cards.png in apps/mobile/build/store-white-cards-20260927, showing orange/coral, blue/violet and rose/purple Store cards with white text. Screen left open for founder review. No new APK. Cumulative qualification and Git commit/push remain pending.

Latest reference supersedes uniform colour: three distinct saturated gradients (orange/coral, blue/violet, rose/purple), deterministically selected from exact Store identity; white text, white compact CTA and price surface with dark text. No random recolouring on rebuild or provider branding claims. Tests cover white-text contrast at11 positions in each palette and actual metadata colours. Simplified delivery icon remains white on colour. Prior rich-uniform and near-white previews are superseded; cumulative qualification/Git remain pending.

Founder rejected dark plum/indigo cards as distracting and cluttered. Superseding preview: near-white surface with very subtle lavender transition, narrow muted plum edge, charcoal hierarchy, quieter CTA/price treatment, no contrasting icon boxes. Remove rejected dark implementation, retain historical evidence only. Existing card contrast/navigation tests updated; qualification pending. Dark-preview analyzer also flagged one test-only missing-braces lint; superseding test removes that loop entirely, fresh analysis required.

Latest founder-requested Redmi preview supersedes pastel card styling: three-stop deep plum #48265F -> violet #503A79 -> indigo #28365F; white details, white Visit store surface with dark text, gold price highlight with dark text. Delivery artwork receives a small white backing for contrast. Existing shared Other stores card only; no provider/route/APK changes. Focused checks cover every displayed dark-surface text colour and >=4.5 contrast across both gradient segments, plus existing navigation and enlarged-text cases. Qualification pending.

Coloured preview evidence: three focused Store-card scenarios passed, including contrast >=4.5 at11 gradient positions for all three text colours; analyzer clean for runtime and two test owners. Redmi hot reload7049ms; actual new cards inspected and left open, evidence apps/mobile/build/store-white-cards-20260927/redmi-coloured-cards-final.png. Cumulative requalification and commit/push remain pending; no claim of clean Git or final founder acceptance.

Latest founder amendment supersedes white gradient on Other stores only: muted lavender #EDE6FA to warm ivory #FFF0E6, dark charcoal names/actions, restrained price highlight. Existing journey checks enforce >=4.5 text contrast at11 gradient positions for primary/ink/muted text. Previous white-card batch1 passed453; batch2 was deliberately cancelled for this amendment, its exact remaining runner tree stopped and logs preserved. That run does not qualify final coloured source. No new APK or provider changes.

Current preview: white-to-#F0F4F5 card gradient; 13px Store/price, 12px product/Visit store, 11px metadata/delivery; price retains restrained yellow emphasis. Removed generic Store/Shop => Retailer inference. Existing supplier classification is displayed; Store focus/benefit fields without a supplied contract are not fabricated. Store workspace remains authoritative. Seven focused checks passed including both C14 gradient cases; classification correction is included in fresh cumulative source replay. Final analyzer clean. Redmi hot reload succeeded in4160ms; product -> Visit store -> information sheet inspected at redmi-store-cards.png in apps/mobile/build/store-white-cards-20260927. No new APK; founder approval and cumulative Git qualification pending.

Founder refinement: use a subtle white gradient on Store decision cards, consistent 13px Store/price emphasis, 12px product/action text and 11px supporting facts. One Visit store CTA; supplied price, product/pack/variant, delivery and availability explain the purchase opportunity. Do not invent lowest-price, quality, rating or specialist claims. Provider identity/classification comes from Store workspace; no provider/backend edits. Prior cumulative replay has 451 passes and two C14 failures because those existing checks require a gradient; the new requested white gradient must satisfy that contract. Prior run is retained, not final qualification.

Founder clarification: promote buyer decision facts, not address. Store branding, offered product/pack, current supplied price/unit value, delivery promise and orderability are primary. Address/Maps become collapsed secondary details; no address on alternate-card fronts. Repeated partnership wording moves to the icon tooltip. No invented quality, ratings, discount or lowest-price claim. Price now uses current session facts rather than stale preview price; existing exact-branch navigation test now taps Visit instead of address and still proves the branch identity and Back continuity.

Founder reviewed redmi-20260927-154200.png and requests defect inventory, repair and hot reload. Existing BUY-ACTION-POLISH-20260926-01 follow-up, mvp_supporting public buyer outcome: readable compact Store identity and alternate-store comparison while retaining Ask, location, fulfilment and Visit navigation. Defects: oversized drag/header area; separated/duplicated address summary; large centred Other stores heading; repeated heavy navy content/gradient cards; product/price/unit/delivery stacked with unused right-hand space. Reuse _showStoreInfo, _PublicStoreTruthPanel and _RelatedStoreCard in buy_v2_catalogue.dart; existing Store and related-store tests. Smallest complete change: compact left-aligned headings, embedded current-store summary with single full address, neutral card styling and adaptive side-by-side product/price information. No provider data/route redesign, backend or APK. Preserve full long names/addresses, large prices, enlarged text, safe bottom inset, Ask/Maps/Visit and return state. Local/device qualification pending.

## Store filter UX follow-up — 27 September 2026

Current qualification: radio options now include 1,000/10,000/1,00,000/10,00,000/1,00,00,000, using existing en_IN money formatting. All four scoped viewport journeys passed five amount selections, crore Apply/reopen retention, Store/Home isolation, sorting, Reset/cancel and long provider-name wrap/bounds/tap accessibility at320px/200% text. Existing adaptive title needed no runtime repair. Test finder collision with an existing storeName variable was fixed; no assertion weakened. Final analyzer clean; hot reload4362ms. Redmi horizontal scroll exposes full 10,00,000 and1,00,00,000 labels together without overlap (redmi-large-options.png); crore option tapped and left as an unapplied review draft. Final cumulative replay passed753 distinct scenarios/812 selected references, zero failures, unchanged source c18e4faa4c73c6534d510efdda507a6ac1cd79c9d2714fdb35a86d5ef0e8f575. Fresh ledger receipts bind selected-1.jsonl/selected-2.jsonl in store-radio-final-20260927. Earlier superseded runs do not qualify final source. Git pre-commit and normal push follow this evidence; no APK or founder acceptance claim.

Founder supersedes the input/dropdown preview: use compact tap-only radio options. Price and sort each occupy a horizontally scrollable row; native radio grouping and label taps retained. Field/dropdown implementation removed. Prior cumulative run cancelled and does not qualify the radio source. Scope, Reset/Apply/cancel and Store identity remain unchanged.

Founder requests compact Store-specific filters. Public buyer outcome (mvp_supporting): adjust maximum price and ordering for the opened Store without changing Home/another Store. Existing catalogue query already binds storeId and destination, including Saved filtering. Reuse _chooseFilters in buy_v2_catalogue.dart and existing scoped-control journeys in buy_v2_partner_catalogue_test.dart. Replace generic price chips with optional maximum-price input, show authoritative Store name, use a compact sort selector, preserve draft/apply/cancel/reset and accessible keyboard/enlarged-text layout. No provider edits or fabricated Store facets. Verify Store query identity, Home isolation, invalid input, cancel/reset, compact geometry and Redmi hot reload. Implemented named Store header, optional validated price cap, compact sort dropdown and Reset/Apply. Four scoped journeys passed including 200% text, invalid zero, Reset and cancelled draft; analysis clean. Initial enlarged-text footer reached 111px; concise Reset/Apply labels repaired it without relaxing the <=100px assertion. Added actual sort selection/query assertion to the final cumulative replay. Redmi hot reload succeeded in4010ms. Entered100 using numeric keyboard, applied, confirmed same Store and products below the cap, then reset. Evidence directory apps/mobile/build/store-filter-20260927. Cumulative source-bound replay and Git checkpoint pending.

## Store toolbar omission follow-up — 27 September 2026

Founder found public Store unchanged after the shared toolbar amendment. Previous Store coverage statement was incorrect: buy-store-catalogue-toolbar has its own gradient, bottom border and 6px vertical padding. This is an open omission under BUY-ACTION-POLISH-20260926-01. Actor: public buyer visiting a Store from Shop/Wholesale/Offers. mvp_supporting outcome: consistent compact white catalogue controls without reducing tap targets or losing store-specific category/search/filter/saved scope. Reuse the existing Store toolbar in buy_v2_catalogue.dart; remove its gradient/border/vertical padding and unnecessary preceding gap; preserve adaptive Store-name wrapping and 44px controls. No global navigation or provider Store edits. Existing buy_v2_partner_catalogue_test.dart Store parity journeys cover Shop/Wholesale at normal and 200% text; extend their actual toolbar geometry/colour assertions. Inventory the shared catalogue and Offers controls and inspect native Store after hot reload. Four extended Store parity journeys passed (Shop/Wholesale at 1.0/2.0 text scale); analyzer clean. A test variable initially collided with the existing category-surface finder; renamed toolbarSurface, then all four passed without weakening assertions. Native Redmi hot reload succeeded in 2943ms; opened product -> Visit store and inspected redmi-store.png in apps/mobile/build/store-toolbar-20260927. Store screen left open. Inventory: buy-catalogue-toolbar serves Buy/Wholesale/Bulk and paged catalogue; buy-offers-publisher-summary serves Offers; buy-store-catalogue-toolbar serves public Store across entry paths. All three use white fill and compact controls; Store-specific search/category/filter/saved scope retained. Non-storefront search mode uses the shared charcoal category action and no separate strip. Global bottom navigation remains deferred. Final cumulative replay passed all 753 distinct scenarios (812 selected references), zero failures, unchanged source ff559bc1ad3a5603f1f8133d471f02f5cd6b318d731ff2305da175aca505290d. Fresh receipts are bound in the ledger; qualification.json retains batch hashes. Pre-commit gate and normal push follow this qualification. No new APK; founder visual approval remains separate.

## Deferred request BUY-BOTTOM-NAV-20260927-01 — compact bottom navigation

Status: deferred until shared-navigation integration; unimplemented and untested. Founder explicitly permits this fallback when a safe global or Buy-only change cannot be made before integration. Actor/outcome: public buyer gets more usable content height while navigating Buy, Wholesale, Offers, Orders and Chat. Classification: mvp_supporting; improve the existing navigation without adding destinations or backend behavior.

Reuse assessment: buy_v2_screen.dart builds MoolDestinationNavigationV2 from apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart; apps/mobile/lib/core/design/mool_design_system.dart owns the shared 58px destinationRailHeight and MoolLocalNavigationRail. No Buy-only height override exists. Android exported-semantics clearance depends on that same height: reducing height alone increases clearance and may recover no content area. Shared owners are outside the current Buy claim. Do not clip or scale the rail as a workaround.

Smallest complete future change: coordinate the two existing shared owners at integration, reduce actual excess vertical padding/height with safe-area and accessibility compensation treated together, and preserve routes, selected states, badges and Cart identity. Excludes provider data, new screens, authentication and new navigation destinations. Order: reconcile shared owner commits, inspect native insets, implement once, test affected entry paths, then Redmi visual approval.

Acceptance: demonstrate content space actually recovered; readable labels and no clipped badges at normal/enlarged text and portrait/landscape; accessible tap targets; correct gesture/three-button system insets and keyboard return; route/selection/Cart preservation across Buy, Wholesale, Offers, Orders and Chat. Record child defects and fix before qualification. No implementation, local pass or device closure is claimed for this deferred request.

## Founder superseding colour — pure white, 27 September 2026

Founder follow-up extends the same public palette ticket to the top catalogue strip: charcoal Quick/Scheduled, Wholesale/Bulk and Suppliers/MoolSocial labels; no blue underline; pure-white backgrounds; 44px strip and 44px tap targets at normal scale, adaptive larger text. Reuse _CatalogueToolbar, _CatalogueSaleTypeSelector, _CatalogueSaleSegment, _OffersCategoryControl and _CatalogueChromeAction in buy_v2_catalogue.dart. Public Store uses the existing context-specific shared controls; no provider worktree or backend integration required. Existing screen and pending-defect tests preserve switching, swipe, reduced-motion, hit-target and large-text coverage. This is mvp_supporting, explicitly requested, and excludes provider Store editing. Earlier pure-white cumulative run was cancelled when this new runtime amendment arrived; no interrupted run qualifies final source.

The founder rejected the grey appearance of #F0F4F5 and requested pure white. This supersedes the colour amendment below. Shared action fill is now #FFFFFF, pressed/selected feedback #F7F9FA, border #DEE4E8, normal elevation 1 and reduced neutral shadow alpha. No button gradients; Cart identity stays blue. Existing compact geometry, labels, taps and accessible state feedback remain. Scanner/video/chat and all earlier public action owners are included.

Eight focused colour/contrast checks passed, analysis clean, protected UI locks passed. Hot reload session66763 applied 30 libraries in4745ms. Actual Redmi Shop and Offers frames show white Add/control faces. Screenshot named redmi-cart.png in button-pure-white-20260927 actually shows Offers (phone navigated during review), so it is NOT Cart evidence. No new APK or release claim. Earlier grey-colour cumulative run was cancelled when founder changed the requirement; it cannot qualify this source.

Seven versioned Cart/checkout reference fixtures in candidate_captures/cursor-pure-white-20260927 preserve earlier approved files. These are deterministic local regression fixtures for the explicitly requested palette; they do not assert new founder/device approval. Comparison retains identical viewport dimensions; visual inspection includes Cart and compact enlarged-text checkout. All ten capture scenarios passed when producing the new fixtures. Final cumulative qualification passed 753 distinct scenarios (812 selected case references), zero failures, across 47 test files in two successful batches. Source fingerprint 80cdb0b61e46787c80e8e40c5bed2b34c4f6dfbb0c7b9a8c94e0903c6a04f631 remained unchanged throughout; exact case receipts are bound in the ledger. Evidence: apps/mobile/build/button-pure-white-20260927/qualification.json and selected-1.jsonl/selected-2.jsonl. No skipped case is counted as passing. Git pre-commit and remote synchronization follow these completed checks. This remains BUY-ACTION-POLISH-20260926-01, not an added feature.

Focused compact-toolbar replay passed 17 scenarios; latest analysis is clean. Redmi hot reload applied seven libraries in 4380ms. Actual Shop frame shows charcoal labels, no blue selection underline and 32 physical pixels recovered vertically (60px to 44px logical strip). Integration repair policy self-test fails its repair-owner fixture identically on unchanged HEAD and the current files; this is a pre-existing integration-test issue, not a passing check. Actual current-owner coordination implementation gate passed with 155 owners. No shared bottom-navigation runtime change was made.

## Historical superseded founder colour amendment — solid #F0F4F5, 27 September 2026

Actor/outcome: public buyer receives consistent solid cool-white action backgrounds through Buy, Wholesale/Bulk, Offers, public Store catalogue/product, Cart and checkout. `mvp_supporting`: founder explicitly selected `#F0F4F5` after rejecting coloured button gradients. This amends existing `BUY-ACTION-POLISH-20260926-01`; it does not create another business feature or a new APK authorization.

Reuse: `BuyV2ActionStyle` already owns 76 button-style applications (60 views, 15 catalogue, 1 invoice), the shared SKU Add/quantity surface, selection surfaces and Cart basket tabs. Smallest complete change: exact normal fill `Color(0xFFF0F4F5)`, neutral pressed/disabled treatment, and replacement of separately painted action gradients. Preserve shapes, compact sizing, callbacks, keyboard/focus/disabled states, prices and all existing blue-cart identity. Bare Category/Filter/Save/Profile/Location controls stay unboxed, as previously approved; colour swatches and semantic danger/status indicators retain their meaning. Product artwork/card backgrounds are not button fills. Public Store is in scope; provider Store workspace is excluded.

Exact runtime owners: `buy_v2_design.dart`, `buy_v2_views.dart`, `buy_v2_catalogue.dart`, `buy_v2_scanner.dart`, `buy_v2_product_video.dart`, `buy_v2_shop_chat.dart` under `apps/mobile/lib/ui_v2/buy/`. Existing Cart and manual-code regression tests were extended. Exact owner registration was synchronized with the existing gate allowlist (three runtime files and one test only); no gate assertion or release rule was weakened. The first registration attempt failed its exact-list check before any additional runtime edit; the matching list was corrected and the implementation gate passed with 148 owners.

Inventory: 266 Material button/icon constructors plus 12 chip/floating-action constructors (278 sites), along with custom shared Add, quantity, selection and Cart-tab surfaces. 85 primary/outlined action-style applications now share the palette (previously 76); newly covered owners include Recently Viewed fallback Add, scanner/manual-code actions, product-video retry and Store-chat recovery/info actions. Chat compose/new-conversation buttons, quick replies and filter chips also use the palette. Catalogue toolbar/category control rows, checkout steps, product assurance actions, reset zoom and prescription action backgrounds no longer paint separate gradients. Bare navigation/close icons remain unboxed; product swatches, stock/error meanings, video/camera context and decorative card/system backgrounds are distinct from action fills.

Verification in `apps/mobile/build/button-f0f4f5-20260927/`: focused Cart/Orders colour, contrast, enabled/disabled callbacks and scope retention passed at normal/200% text size; four actual Flutter-rendered frames inspected. Initial impact run: 137 pass, one stale scanner contrast assertion failed because it read the transparent Material underlay rather than the opaque Ink surface and assumed white text on dark fill. The test now measures the rendered exact #F0F4F5 surface, no gradient, opacity and direction-independent WCAG contrast >=4.5. Scanner/chat busy indicators were changed to readable muted ink. Final impact run: 138/138 passed, terminal success=true, exit 0. Focused run: 7/7 passed (145 total local checks). Analysis of all six runtime owners and both changed tests is clean; git diff --check passed.

Redmi preview update: founder authorized hot reload. Device-memory gate passed using the preserved archive root (4618 entries, 482 device-applicable). Verified TG8HCYTGGQT885OF, debug package com.moolsocial.app.cursorreview, r66.36/code2026092701; no native/dependency delta from APK build source. Attach session66763 used the same review-only/emulator/candidate defines and completed source sync; explicit reload succeeded (1386ms), but Shop still showed the previous constant fill. Hot restart succeeded (6884ms); redmi-shop-restarted.png then showed the new controls and 91809 exact RGB(240,244,245) pixels. No new APK, data clear or production activation. Shop frame is device proof only, not founder acceptance. Phone switched to dialer during attempted Cart verification; device interaction stopped, Cart verification pending. Store/OPPO attach was untouched. Keep session66763 attached; do not launch a duplicate.

Git: branch work/cursor-ui/buy-ready-20260921, committed local/remote HEAD6857b3bcd2ee2584455f0b242434243cdd06c291 verified equal. Eleven task files remain modified. Explicit pre-commit gate rejected `Changed application owner missing from affected-route ledger`; no commit/push attempted. Next: reconcile exact new scanner/video/chat/test owners in the affected-route ledger, rerun required cumulative qualification and bind fresh evidence before commit/push. Prior whole-application fingerprint cannot qualify this colour amendment. No clean-worktree or synchronized-new-source claim.

## Current APK preparation — 27 September 2026

**Installed and stopped:** r66.36 (`1.0.0-r66.36-cursorreview`, code `2026092701`) built successfully from clean synchronized `7d8f5b14f4b713ee6e00b9ea7d24fdd7223db768`; package `com.moolsocial.app.cursorreview`. APK/plugin-integrity and signature checks passed. Signer SHA-256 `cbdfc5969ad51ed570afb1cf2fe60377e559d43f59d59e2ab66ccaf78ea9ac25` matches the previous review APK. Installed with `adb -s TG8HCYTGGQT885OF install -r`, preserving app data. Candidate and installed SHA-256 both `7d2e95b6a3d7be9136457d9103dbf262ceca306788c904e4170e85f16f70c4d5` (215,833,965 bytes).

Cold start: force-stopped and launched the installed package. Android's `am start -W` initially reported timeout at 10,610 ms; subsequently PID 14441 was resumed/focused and the native Shop rendered successfully. Actual screenshot and UI hierarchy show Fresh tomatoes, Premium basmati rice and approved cool-grey Add controls. Captured app log has no fatal exception, fatal signal or unhandled exception. Screenshot SHA-256 `793A7B89C058A41198C31FC4883F94CFAA04BA8559111026A1F476D47E92D38A`; XML SHA-256 `353F067C4579C1FBEB028F3DC5D4F90BEEDA68E24310D375A1AF92ACFF11C765`. Redmi's UI-dump utility emitted a MIUI theme-file warning but produced the complete hierarchy. Evidence: `installed-identity.json`, `cold-start.log`, `cold-start-app.log`, `redmi-cold-start.png/xml`, `install.log`, `wrapper-build.log`, `apk-signature.log` and `apk-badging.log` in the r6636 evidence directory below. One-build authorization is consumed. No further device interaction, tickets or extended qualification: founder requested stop after verified installation/cold start. Full journey/founder/backend acceptance remains separate and is not claimed.

Build-foundation preflight found CRLF checkout bytes in the regression registry although `.gitattributes` and its committed blob require LF. Preserved the original bytes at `C:/GUARANTEED OUTCOME/BUY-SOURCE-RECOVERY-20260927/r6636-prequalification/registry-before-lf.bin`, then restored bytes exactly equal to the committed blob (zero registry Git diff, 4,618 entries unchanged). Updated only the coordination checksum pin to `465F811B8C519F753A2228CFC16BBFB219E2043ED66CDF5A3C83E55786FD7A6F`; old raw pin was `462609A597ED8178C35D4D3FCF19E5E10AEF53982A7F7A6A91B691F20C98A2F6`. Existing canonical-byte rejection remains active. Fresh coordination and build-foundation checks are required after this correction.

Founder authorized one fresh incremental Redmi review APK, then stop after installation identity and cold-start verification. Qualified application source is `7ca0a91b4dbbbb2baa9c8d17d7cddc238c6f8f0d`; application/test fingerprint `7f627ee419561348aa714084bb2f0e451d05d65cbf0e27785fa6c2d988ad802e`. Two full Buy runs each passed 2,959 cases with zero failures/layout warnings and the same 27 optional capture skips; related external navigation passed 104 cases. All 806 selected references (747 unique scenarios) have current local evidence. This is not full ticket closure or production/backend acceptance.

Evidence directory: `apps/mobile/build/review-candidates/cursor-buy-r6636-20260927/`. Source checkpoint passed `precommit-qualified-staged.log` and was pushed with exact remote readback. The initial unstaged pre-commit attempt correctly rejected; no commit preceded the fully staged pass. Failed diagnostic runs remain retained. Planned candidate: `UAW-CURSOR-BUY-R6636-20260927`, `1.0.0-r66.36`, code `2026092701`, isolated CursorUiReview/debug package, app data preserved. Build and installation remain pending.

Exact candidate admission preserves the existing protected baseline and rejects source drift. `current-boundary-seams.json` verifies inherited Store Maps, scanner, chat and arrival-sound seams. The approved explicit Store-copy tap copies only displayed seller name/address. Four Apple reference-photo URLs belong to the explicit review catalogue. The payment launcher is disabled by `session.reviewDataEnabled`; these review-only allowances authorize no real payment or production provider connection. The first boundary checks rejected these unrecorded seams; corrected exact-commit/file-hash checks retain the original findings. Initial new hash generation used the Windows default text encoding; canonical UTF-8/LF hashes corrected it without touching application source. Exact-source fixtures verify accepted bytes and reject altered bytes/wrong commits. Production release plugin-namespace migration remains REG3209; this authorized debug profile uses its existing debug resource-integrity gate.


### D08 / D08-C1 execution assessment - provider-assigned mode and grouping

Buyer outcome: supplied delivery transport/service is respected independently of delivery timing from product through cart/checkout. mvp_supporting, closing the selected assignment frontend gap while live logistics remains deferred. Reuse existing BuyV2ProductFactsSnapshot.fulfilmentMode/deliveryProviderName/deliveryServiceLevel, eligibility, session fulfilment grouping and existing checkout summary. No new endpoint, owner or screen is needed. Source inspection found fulfilmentModeFor ignores the supplied mode; grouping combines different provider/service facts when Store/mode/timing agree. Smallest complete repair: consume an eligible supplied mode, reject contradictory supplied transport eligibility, and split groups by provider/service while retaining independent supplied schedule and existing stable membership key. Exact owners: buy_v2_session.dart and buy_v2_session_test.dart; checkout rendering remains the existing shared owner. Verify supplied courier versus quick availability, scheduled timing independence, distinct provider/service groups, malformed assignment recovery and impacted checkout/quote/navigation. Do not claim server-issued assignment or shipment identity, or live delivery integration, complete from these frontend tests.


## Current continuation - C05 frontend and Redmi hot reload amendment, 25 September 2026

Redmi attach preflight succeeded: TG8HCYTGGQT885OF, model23106RN0DA, com.moolsocial.app.cursorreview r66.35/code2026092302 DEBUGGABLE, installed SHA2563fd6dccb8eac215053e33ccacd6cbfb65b1c1213365079fa4af67d6ed80cc096 matches retained candidate. Native/platform/pubspec diff from build HEAD5b58240f5df9c7dbbbc5d660158fca4e069e1b45 was empty. Existing review-only/emulator defines retained; no live backend activated. Flutter attach session27993 remains active: initial sync completed, hot reload succeeded, then one hot restart initialized current code in6124ms. Do not start a second attach or kill this session; poll its exact handle first. Current visible screen: Fresh tomatoes product page. No APK build/install or data clear. No approval claimed.

Attach evidence: apps/mobile/build/buy-bounded-19-20260924/redmi-hotreload-review/attach-source-evidence.json binds273 Dart/pubspec files with fingerprint f3abf76fe1f0c40ed4591ca9b7014e616c92dd9729457443b0fd8448123b83c7. Three actual device screenshots retained there. The default review catalogue currently supplies one illustration for this product; gallery multi-image/provider scenarios still need controlled review fixtures before device acceptance. Continue completing7 original frontend qualifications while preparing all19 plus applicable child screens for sequential Redmi founder review.

Founder now requests screen-by-screen visual review on connected Redmi through the installed debug app and hot reload instead of local-only screenshots or another APK. Check installed package/debug capability, attachable Flutter VM, source/runtime configuration compatibility and applicable device gates before attachment. No new APK build/install, data clear, uninstall, live transaction or backend activation is authorized by this change. Device review is not release qualification or Git closure.

C05 now carries optional itemised receipt evidence through the existing delivery-exception adapter. Exact fields: receipt orderId/purchaseId; each line productId/variant/pack/orderedQuantity/receivedQuantity. Require complete purchased-line coverage, unique matching identities, positive ordered quantities and received quantities within0..ordered. Reject mismatches with Retry. Display received and missing quantities; reuse existing dispute action without changing order/payment/invoice amounts. Deferred backend owner supplies authoritative receipt, settlement and invoice adjustments; this is not a Store-worktree merge request.

Registered and fixed child R6634-C05-A01: the existing fixed-height receipt action clipped text at200percent despite passing widget assertions. Receipt and reschedule actions now grow to content; tests measure full text and button bounds. Rejected and corrected native frames are retained. Final compact subheading adjustment is covered by local tests; founder review remains on Redmi. Controlled fixture frames do not prove real fulfilment or settlement.

Evidence in apps/mobile/build/buy-bounded-19-20260924/: frontend-c05-checkout-final.jsonl112 passes; frontend-c05-session-order-impact.jsonl566 passes; frontend-c05-native-fixed.jsonl2 passes; frontend-c05-analysis-final.log clean. Manifest binds hashes. No active test process at this checkpoint. Branch work/cursor-ui/buy-ready-20260921, HEAD5dc6885ada1fe0cd23f3d5d0a2bc62fe56cc0abd; existing work preserved and uncommitted.

Current aggregate supersedes older counts below:37 references =19 originals +18 additional/linked children;30 have frontend local-pass evidence (12 originals +18 children),7 originals still pending completion/current qualification: D08,D08-C1,D09,D09-C1,D10,D10-C2,D17. Backend deferred; founder/Redmi approval pending. No APK produced.


### C05 itemised receipt frontend execution assessment — 25 September 2026

Actor: the buyer viewing their existing order receipt. Classification: mvp_supporting, completing the founder-selected C05 local acceptance gap. Reuse BuyV2DeliveryExceptionSnapshot/Adapter, BuyV2Session validation, the existing delivery proof card and its dispute action; no new route, service or Help entry.

Smallest complete frontend change: optional order/purchase-correlated receipt with exact purchased product/variant/pack quantities, received and missing counts, validation against retained order lines, compact accessible rendering, and retry/dispute regression coverage. Owners: buy_v2_content_contracts.dart, buy_v2_session.dart, buy_v2_views.dart and existing checkout_cart_return_continuity_test.dart under their recorded Buy paths. No Store worktree edits. Provider decides received quantities; the client must reject unmatched, duplicate, negative or over-received lines. Omitted itemised data remains an aggregate proof, never a claim of full receipt. Invoice/refund/settlement changes, live customer authorization and backend persistence remain deferred.

Acceptance: full/partial receipts, variant/pack mismatch, unknown/duplicate/missing lines, invalid quantities, correlation mismatch, failure/retry, repeat dispute and unchanged payment/order amounts; native narrow and enlarged-text screens. Frontend implementation and test results remain pending until evidence is recorded.


## Current frontend evidence - 25 September 2026

D17 current native review:24 selected PO checks passed;10 images captured under `apps/mobile/build/buy-bounded-19-20260924/d17-founder-current-20260925`. Normal draft,200-percent revised and normal accepted collection reviewed locally. These are actual Flutter renders with controlled fixtures. The standalone PO panel is not a full checkout; collection fixture deliberately lacks its gateway and shows unavailable status, disabled payment and differing fixture supplier display labels. Do not claim live checkout or founder approval. Exact image hashes are in D17 currentNativeReviewEvidence. All other pending references remain visible.

D09 identity audit repair: an order refresh previously accepted a different purchase under the same order ID. It now requires the retained purchase ID and destination before replacing the original order. **2 targeted checks +109 order-resolution/tracking impact cases passed**, analysis clean; evidence hashes are in D09 refreshIdentityRepairEvidence. This does not close D09: the current model has display delivery/tracking facts, but no explicit authoritative shipment/assignment identity contract. D08 scheduling/customer assignment and D09 shipment/quote correlation remain pending; backend authority is deferred.

Reconciled scope: **19 original +17 additional/linked references =36**. **28 have frontend local-pass evidence;8 originals remain pending completion/current qualification.** Two historical references were previously omitted: D06-B-A01 (supplier filtering/paging/navigation) and C08 (compact comparison header). They are existing registered work, not newly invented defects. Backend, founder and Redmi acceptance remain separate; older counts below are historical.

Current D05/D06-B/C07 audit: **43 comparison/Offers/GST cases passed**, including compact comparison layouts, matching/rejection, product/cart return, publisher filtering, profile save/edit/remove/reuse, account-change and failure handling. Runtime consumers use the existing session comparison source, supplier query and GST profile store. Supplier child navigation replay separately passed; its source/filter checks are covered by the existing464-session replay. Three collected-receipt cases passed. C05 itemised partial-receipt outcome remains unaudited and is not closed by these receipt tests.

Live dependencies remain deferred: authoritative Store/public comparison and offer publication, source-side supplier filtering/counting/pagination, and authenticated GST profile persistence/order snapshot. The GST restart fixture is controlled account-store evidence, not production persistence. No Store worktree integration requested.

**D17 interruption-before-response recovery now locally verified:** a persisted submitting attempt with an idempotency key stays unresolved even when no payment reference arrived. Optional `BuyV2PendingOrderRecoveryAdapter.recoverOrder(idempotencyKey)` retrieves the original attempt without another placement/payment. Missing connector, exceptions and unavailable responses keep retry-payment blocked; a changed account/session rejects a late response. Exact approved PO and purchased lines remain validated before order admission.

Provider obligation (deferred payment backend, not Store integration): implement authenticated read-only lookup by the original idempotency key, retaining the immutable purchase correlation and returning authoritative status. Do not substitute a new order or payment. Store worktree integration is not requested.

Evidence: **464 full session +93 checkout cases passed**, then **20 overlapping focused recovery cases passed** following a test-only braces correction; four-owner analysis clean. Logs/hashes are in D17 interruptedPlacementEvidence. Native founder review and cross-ticket qualification remain pending.

**R6633-D17-A05 fixed locally:** PO payment waits until its recovery snapshot is saved. Missing or failed customer-state storage prevents provider placement. A delayed write holds the submission; owner/session and approved PO request/revision are checked again before payment. Corrected storage retry places once. The full session replay passed **459 tests**, plus **93 checkout tests**, zero failures/skips; analysis clean. Evidence hashes are in D17 durablePrepaymentEvidence. Five older test expectations were updated to the approved Compare prices action/sheet and same-category product alternatives; navigation/cart semantics remain tested. No runtime comparison behavior changed in this repair.

Remaining parent audit includes cross-ticket cumulative replay and actual native founder review. Backend remains deferred; no APK or integration is requested.

**R6633-D17-A04 fixed locally:** pending delivery checkout retains PO account/request/revision in the existing customer-state codec. After restart, the existing provider refresh operation retrieves that request; owner, revision, delivery destination, accepted line quantities/prices and order confirmation must match. Wrong account/request/revision or unavailable provider leaves payment unresolved. Corrected retry reconciles once without another issue or placement. The submission lock also covers asynchronous PO recovery. The existing address decoder now preserves an empty optional landmark; otherwise a valid saved address was discarded.

Evidence: **65 session/collection +93 checkout +4 existing persistence checks passed**, analysis clean. Actual serialized customer-state roundtrip is exercised, not only an in-memory snapshot. D17 restartRecoveryEvidence in the manifest contains log paths/hashes. D17 remains open for final persistence/failure audit, cumulative replay and native founder review.

Provider connector requirement: `refresh(requestId)` must recover the exact account-authorized accepted request and revision for an interrupted purchase without issuing another PO. Retained identifiers are correlation only, never payment proof or authorization. Store publication and payment confirmation remain separate authorities; backend is deferred and no worktree integration is requested.

**R6633-D17-A03 fixed and locally verified:** confirmed PO checkout now matches purchase identity, supplier, approved PO references and complete purchased line identity/quantities before admitting orders. An unrelated PO, changed quantity or changed supplier leaves payment unresolved and preserves the cart. A corrected response completes the original placement without issuing another PO or paying again. Latest evidence: **59 recovery/session + 93 checkout cases passed**, zero failures/skips; analysis clean. Logs and SHA256 values are in the regression manifest under D17 confirmationBindingEvidence.

Provider confirmation must preserve the accepted purchase/request correlation, Store/product/variant/pack identities, quantities and PO document references. This is a data-contract requirement for the existing connector, not a request to integrate worktrees or implement deferred backend now. Store-owned published data stays separate from payment-service confirmation authority.

Remaining D17: fresh-session delivery PO review/payment recovery, cumulative replay and actual native founder review. Backend remains deferred. No APK, commit, push or worktree integration performed.

## Founder frontend-only continuation — 24 September 2026

D17 confirmed delivery/revision verification: existing real session now tested through two suppliers, explicit revised-document approval, rejected unrelated document approval, one payment reconciliation into two orders, exact PO reference retained in invoice document data and existing Help -> original order return. The fixture validates request/review/document revision arguments before approving only the selected supplier. **56 collection/delivery impact cases passed**, zero failures/skips, analysis clean. Runtime source unchanged in this extension; prior93 checkout replay remains relevant to the same runtime. Log `apps/mobile/build/buy-bounded-19-20260924/frontend-d17-delivery-revision-impact.jsonl` is hashed in the manifest. This is controlled adapter evidence, not backend settlement or native invoice approval.

Next D17 checks: reject mismatched confirmed response identity/PO binding; fresh-session PO review recovery; cumulative replay and native founder review. Do not close the parent from the positive confirmation path alone. Store-side requirements remain unchanged by these tests; no integration or backend work is requested.

Latest D17 delivery checkpoint: production-mode two-supplier checkout now has actual session evidence. One supplier acceptance cannot authorize the other; both accepted documents bind exact Store lines, PO request/revision and separate PhonePe payment to one placement. Pending payment cannot be resubmitted. **Child R6633-D17-A02 reproduced:** revoking PO identity during final facts refresh still allowed commerce placement. Final approval guards now recheck before provider placement and local review order creation. **56 collection/delivery cases and93 checkout cases passed**, zero errors/skips, analysis clean. The 12 new children are locally verified; original19 +12 new children =31 references. Device/founder/backend acceptance stays separate.

Evidence: `frontend-d17-preflight-reproduction-actual.jsonl` retains the failed placement reproduction; `frontend-d17-preflight-impact.jsonl` and `frontend-d17-preflight-checkout-impact.jsonl` retain passing impact results under `apps/mobile/build/buy-bounded-19-20260924/`, with hashes in the manifest. Earlier delivery fixture failures were missing/incorrect explicit business, clock, public payment and delivery-estimate data, not reasons to weaken production guards. Remaining D17: confirmed delivery orders through document/invoice/existing support, supplier revision recovery, cumulative replay and founder native approval. No new Store-side field request or worktree integration is introduced by this guard fix.

D17 collection UI/session checkpoint: existing collection confirmation now renders the shared PO panel and disables placement until current supplier acceptance. Accepted PO request/revision changes the basket fingerprint, invalidates the old quote, and requires Update total. **93 checkout checks +53 collection checks passed**, zero errors/skips, analysis clean; targeted journey replay overlaps these counts. The actual session test uses the existing catalogue/gateway/pending-store harness (not overridden session getters): Wholesale Store selection -> quote -> draft -> issue -> supplier acceptance -> stale quote blocked -> fresh quote -> one placement with exact PO IDs -> only purchased Store lines removed. Normal/200-percent checkout-view interaction also passed after settling scroll before taps. Logs/hashes in D17 manifest. Backend/provider/device/founder acceptance remain pending.

D17 collection document gap resolved locally: accepted provider `reference` values are retained as `BuyV2CollectionBasket.purchaseOrderReference` with the request/revision binding and contribute to intent correlation. `_completeCollectionPurchase` copies that reference from the retained intent into the existing order field, including fresh-session reconciliation without an in-memory PO review. Existing order/invoice UI and customer-state serialization already consume this field. **93 checkout +54 collection cases passed**, analysis clean; two targeted direct/recovery cases overlap. Full delivery/multi-supplier/revision/support/native-founder qualification remains open.

Two native capture cases passed; four actual collection checkout images are in `apps/mobile/build/buy-bounded-19-20260924/d17-collection-native` at normal/200-percent text. These use controlled panel fixtures with an intentionally unavailable collection gateway, not a complete live/provider checkout. Draft normal and accepted enlarged images were inspected. Founder approval is pending; do not present these as proof of live Store or payment readiness.

D17 next verification uses the already claimed `apps/mobile/test/ui_v2/buy/buy_v2_session_test.dart` and its existing collection catalogue/gateway/pending-store harness. Extend that fixture with PO operations to test actual catalogue admission, Wholesale collection checkout, accepted PO quote invalidation, one placement and order/cart continuity; no additional runtime checkout or provider is introduced.

Latest D17 local checkpoint: **91/91 checkout continuity cases passed**, zero errors/skips, terminal exit0; four-owner analysis clean. Includes four new regressions for delivery-to-collection approval isolation, same-Store changed collection address, invalid/ambiguous/wrong-Store destinations and accepted-PO revision correlation in collection basket fingerprints. Evidence `apps/mobile/build/buy-bounded-19-20260924/frontend-d17-destination-impact.jsonl`, SHA256 `19963b85c11e940d30abfccadc262e3a2aad744980c8164b17991949e407847d`. Collection contract/controller checks are local evidence, not full collection PO UI/quote/payment/order journey acceptance. That journey remains open; the Store handoff does not ask for worktree integration.

D17 collection-context execution: extend existing PO review/controller and collection basket, not a new checkout. Bind exactly one destination: delivery address or identified collection Store with published address. Existing collection gateway must receive accepted PO request/revision in basket correlation; changed destination invalidates approval and quote. Reuse collection confirm panel and payment guards. Same claimed content-contract/session/views/checkout-continuity-test owners. Backend issuance, payment and account persistence remain deferred. Validate wrong/missing destination, same-ID changed address, delivery-to-collection transition and accepted-reference propagation before allowing collection payment.

D17 delivery-panel progress: optional purchaseOrderAdapter plus existing verified account/session identity creates a session-owned PO controller. Existing checkout confirm renders BuyV2PurchaseOrderPanel (buyer, supplier, exact lines/totals/terms, draft/awaiting/accepted/revised/rejected, explicit approval/status/retry). Both placement CTA and submitOrder guard require current accepted PO matching actual basket quantities/prices. OrderPlacementRequest now carries optional purchaseOrderRequestId/purchaseOrderRevision separately from payment. Supplier revised requestedQuantity remains bound to original request, while an accepted document can match explicitly updated basket quantity. Missing identity disables review. Collection submission cannot bypass approval: destination-specific PO contract/controller binding and accepted-reference basket correlation now have local regression evidence; the complete collection UI/quote/order journey remains unfinished. Delivery approval does not authorize collection.

Local evidence: 18 PO cases,87 checkout impact cases passed; two native panel cases subsequently pass at320px normal/200-percent text after compact draft actions and logout guard. Analysis clean. Suites overlap and no complete end-to-end PO claim. Tests use injected panel basket/account fixtures, not full real catalogue/auth acceptance. Native images in d17-native-first/second/third are preserved. **Capture discrepancy resolved:** raw pixel verification proves all15 enlarged saved images have identical complete heading regions (top300 RGB rows SHA256 b702b5c41274a91688dc882b5d416a498ea121a4ca61cb23e254db722fe54235). Earlier preview-based claims of missing headings were incorrect. Evidence: apps/mobile/build/buy-bounded-19-20260924/d17-native-pixel-verification.json. No runtime clipping defect established; unnecessary capture diagnostics removed. Founder approval and full checkout journey remain pending.

Remaining D17: complete collection context, full checkout/order/document/invoice and existing chat continuity, multi-supplier and restart recovery, real source composition and native founder approval. Backend still deferred; no issuance/payment/message/APK/commit/push. Original19 +11 new children =30 references retained.

D17 controller progress: BuyV2PurchaseOrderController now handles review, issue, refresh and explicit supplier revision approval; uses existing verified account/session identity, rejects changed buyer/basket/address, serializes mutations, rejects silent accepted-term changes, and reconciles uncertain issue outcomes. Supplier quantity revisions preserve original requestedQuantity separately. New child **R6633-D17-A01** reproduced stale approval after failed refresh, repaired with separate review freshness, and locally verified. **16/16 focused PO contract/controller cases and 85/85 checkout impact cases passed**, zero errors/skips, analyzer clean after a braces-only correction and focused replay. Evidence hashes live in D17 and child manifest rows. Corrected derived count: original19 +11 new children =30 references; all11 new children locally verified, Redmi pending. Parent D17 still incomplete: controller is not yet composed into session/UI; approval/status screens, cart/address edits, order-chat/payment linkage, restart transport recovery and native review still need integration. Backend remains deferred. No APK/commit/push or external PO/payment/message.

D17 boundary progress: BuyV2PurchaseOrderLine/Document/Review and PurchaseOrderAdapter now model draft, awaiting supplier, accepted, revised and rejected documents independently of payment. Connector operations are review/issue/refresh/approveRevision with explicit request and revision identities; no successful default adapter. Binding validates exact public listing ID, variant, pack, Store and quantities (BuyV2Product has no generic skuId property; internal SKU projection belongs to adapter), line coverage, duplicate documents/lines, integer minor-unit totals, expiry and required issue/revision metadata. Lists are immutable. **9 focused and 78 checkout impact cases passed**, zero failures/skips, analyzer clean; suites overlap. Hashes recorded in D17 manifest. This is partial implementation, not full frontend acceptance: buyer/session ownership, receiving address continuity, approval/controller/recovery, supplier states, order chat/payment navigation and native screens remain to be wired and tested. Backend deferred; no PO issued or message/payment sent.

D17 frontend execution assessment: public verified Wholesale/Bulk buyer reviews basket-derived supplier-specific PO documents before issue; supplier acceptance/revision is separate from payment. MVP-required; reuse existing cart lines, checkout address, session/view and order conversation. Exact first owners: buy_v2_content_contracts.dart and existing checkout continuity test; subsequent session/view wiring remains within recorded Buy owners. Introduce only the missing typed document/review boundary because current purchaseOrderReference string cannot encode lines, supplier decisions or revisions. Backend returns identities, issue/revision outcomes and idempotent request resolution later; no client-generated official PO number or successful default adapter. Validate exact supplier and line coverage, buyer identity, expiry, integer minor-unit arithmetic, revision approval; local state fixtures only, no issue/payment/chat external action. Parent stays incomplete until UI/navigation/recovery and native review are qualified.

D11 native frontend wiring is implemented: BuyV2Screen now resolves an installed url_launcher external-application handoff for non-review sessions across checkout and tracking; injected callbacks retain precedence and review fixtures receive no native fallback. Only HTTPS/UPI URIs with host and without userinfo are admitted; missing handler/errors return failure. Opening a handler does not confirm payment. **4/4 focused cases and 82 impact cases passed**, analyzer clean after test-helper braces correction; impact includes one pre-existing skip:true R56.7 legacy golden-capture test, not a passing visual check. Exact evidence hashes are retained in D11 manifest. Real payment/backend/device acceptance remains deferred/pending. D10 embedded-map SDK/platform authorization question is pending. D17 remains incomplete and is next independent frontend work. No new dependency, platform/backend mutation, real external payment, APK, commit or push.

D11 frontend selection: authenticated public Buy customer continues an authoritative pending payment using the installed OS handler. MVP-required checkout connection; reuse existing url_launcher, BuyV2PaymentHandoff and session reconciliation. Exact owners: buy_v2_screen.dart and existing checkout continuity test. No backend, payment execution, dependency/platform changes or fake confirmation. Non-review sessions receive a native fallback; review sessions retain explicit test callbacks only. Validate URI, failure/exception handling, injected override, and existing pending/reconciliation navigation; platform/device acceptance remains pending. D10 SDK/configuration authority question remains pending while independent D11 work proceeds.

D09-C1 repair supersedes the prior unchanged-runtime statement for current source: a supplied assigned delivery time change could leave the previous quote accepted. New regression failed at quote-review-required, then passed after binding retained/in-flight quote context to delivery promise, assigned time, dispatch, provider/service, address values and purchased lines. **65/65 checkout impact checks passed**, including the new regression; targeted replay 1/1 overlaps. Analysis clean. Exact reproduction/pass log hashes and current session source SHA are in the D09-C1 manifest row. No new child ID or backend implementation. Shipment identity integration and full frontend/native approval remain open. No APK/commit/push.

Latest frontend replay: **103/103 delivery/tracking cases passed**, zero errors/skips, process terminal exit0. Log `apps/mobile/build/buy-bounded-19-20260924/frontend-delivery-tracking.jsonl`, SHA256 `51cd259d50d1ec1218d25f03fee961acc9138e32e4cab8c54ca6eb43e11d7276`. Combined with D07 replays this phase has 256 passing executions; these are overlapping regression checks, not 256 newly added tests. No newly reproduced child. D08/C1 and D09/C1 contract-gap audit remains next; passing shared tests does not prove those full contracts. D10/C2 actual map renderer is still frontend work (no installed Google Maps Flutter dependency found); D17 basket PO/approval/revised-terms lifecycle also remains frontend work. Backend deferral does not close either gap.

Founder explicitly deferred backend implementation/integration and resumed all 19 original references plus children for frontend completion, local and impacted testing, reusable connector contracts and actual native founder screens. This supersedes the earlier whole-goal provider block for the current frontend phase. Real backend/provider outcomes and Redmi remain separately pending; no fixtures may be represented as live data.

D07 frontend audit: existing collection identity lifecycle, purchase controller and ScanPick connector are reused. Fresh local replay passed **101/101 order-resolution cases and 52/52 collection-purchase cases**, no failures/skips/errors; both processes terminal exit0. Coverage includes late replies after identity change, uncertain-operation recovery, duplicate scans, exact paid-order receipts, collection navigation and narrow/enlarged layouts. No new runtime defect confirmed in this replay. Native founder approval is still pending. Actual identity/gateway/account storage implementation remains deferred backend integration.

Evidence: `apps/mobile/build/buy-bounded-19-20260924/frontend-d07-order-resolution.jsonl` SHA256 `15d4bf04b20b362dd8adb69abaaa2158f72abffff18fcf2071e1f62799860a01`; `frontend-d07-purchase.jsonl` SHA256 `8c84ddb9a0b1c836e3e0c4ba5553595db1531cabba7805c829b0d2d26883b263`. These counts are additional selected replays, not a claim of new unique cumulative scenarios. Runtime/test sources unchanged during this phase so far.

## Provider-to-public Buy mapping working draft — 24 September 2026

### Founder direction — Store-side dependencies only

**This handoff requests Store-side fields and capabilities needed by the implemented Buy frontend. It does not request integration, copying, merging, rebasing, checkout or synchronization of the Cursor and Codex worktrees.** The Store agent should implement the missing Store-owned requirements in its existing authorized Store worktree and report the owner paths and field mapping. Cross-worktree integration is a separate later task. Historical integration procedures elsewhere in this document are not instructions to execute now.

**Act on these Store-owned requirements for implemented Buy consumers:**

| Store-owned requirement | Required Store information / capability | Implemented Buy consumer / ticket |
| --- | --- | --- |
| Public Store identity | Stable Store/branch ID; matching public Store name, area, address, region; truthful partnership/fulfilment metadata. Maintain one authoritative name and identity across Store and public product projections. | Compact Store cards and product seller identity; PDP and Offers consumers. |
| Published product identity and media | Stable public listing/product ID mapped to Store/internal SKU, canonical product identity, exact variant/pack; ordered published photos/admitted video with revision and valid asset/poster metadata. | PDP-01 media and its three locally verified children. |
| Variants, dimensions and prices | Exact variant/pack/size options; category-appropriate size chart; current selling price and applicable MRP/discount facts; dated previous/current selling prices, currency, minor-unit amounts and validity for real price-drop history. | PDP-02 and its two locally verified children. No invented discounts or histories. |
| Purchase eligibility and policies | Current stock/orderability, minimum order where applicable, destination/service eligibility, supplied delivery promise/dispatch/fee facts, applicable return policy and supported COD eligibility. Backend confirmation remains separately deferred. | PDP-02/03; existing checkout comparison and D09-C1 quote invalidation. |
| Product information | Structured highlights/specification attributes, description, generic/legal/manufacturer/packer/importer/contact/date/origin fields using stable attribute IDs and explicit missing values. | PDP-04/05 and locally verified content children; no repeated old/new text. |
| Discoverable public listings and offers | Current public Store catalogue and offer IDs/revisions/status; matching product/variant/pack identity, seller, prices, stock and eligibility/expiry; paginated provider-specific products. Withdrawn or private entries must not appear public. | PDP-04/06 recommendations/history; D05 comparison and D06-B Offers consumers. Final comparison/Offers frontend acceptance remains open. |
| Collection location | Real collection Store/branch ID, public name, address, area and region. Keep this consistent with the published product's Store ID. | Existing D07 collection frontend. D17-specific collection approval wiring remains under development and is not an immediate contract to freeze. |
| Supplier PO information and decision capability | For existing authorized retailer/supplier capability: exact buyer-visible supplier identity, requested/approved listing lines and quantities, prices/charges/totals, terms, supplier decision and revision explanation. Use existing Store order workflow if it owns this behavior; do not create a new manufacturer/supplier workspace. | D17 delivery PO controller/panel has local evidence. The exact connector is listed below; full journey and collection additions remain open. Official issuance/concurrency/auth transport are deferred backend work. |

For each row, first map existing Store fields/controls; implement only missing Store-owned data or behavior within the Store lane's authorization. Record `available / missing / pending backend`, exact Store owner path, field name, meaning/unit, and public visibility. Do not duplicate Store inventory, counter sale or ledger solely to satisfy Buy. Buy needs the public projection and relevant order information, not private ledger/customer/settlement records.

**Not Store frontend implementation requests:** customer login/session authorization, customer GST profile persistence, payment gateway execution/reconciliation, customer-authorized shipment/live tracking services, secure handover, partial-receipt settlement and durable account recovery. Keep those with their backend/account/delivery owners for the deferred phase. Store onboarding GST is not the customer's saved invoice GST profile. Native map rendering remains Buy frontend work.

**Advance notice only:** D17 collection-specific PO destination/reference declarations below are unfinished Buy work. They describe the current direction for planning; do not implement against them as a frozen contract or treat them as locally qualified. Buy will update the tested handoff once that behavior is complete.

### Latest provider delta — read before implementing the earlier map

Updated during the active D17 frontend implementation on 24 September 2026 at the founder's request. This section supersedes older field/status summaries below where they conflict. Backend execution remains deferred in the Buy lane; Store frontend work may continue independently. This is an uncommitted working contract, not an accepted integration commit. The Store agent should use this document to map Store-owned shortcomings only. No worktree integration or adapter transport implementation is requested by this update.

| Change since the earlier mapping | Provider / Store action | Qualification boundary |
| --- | --- | --- |
| D09-C1 now invalidates checkout quotes when supplied delivery timing/service, address values or basket prices/quantities change. | Return the current delivery facts (`deliveryPromise`, `promisedByLabel`, `dispatchPromise`, `deliveryProviderName`, `deliveryServiceLevel`) with quote context. Revalidate server-side; a retained quote ID alone is insufficient. | Local regression and 65 checkout impact cases passed before later D17 edits. Shipment/backend acceptance remains deferred. |
| D11 has a native external payment handoff through the existing installed launcher. | Supply `paymentActionUri` only for the authorized pending payment and implement existing placement/reconciliation contracts. Current frontend admits HTTPS/UPI URIs with a host and no userinfo. Payment status must come from reconciliation, never handler launch. | 4 focused and 82 impact cases passed before later D17 edits; one existing legacy capture test skipped. No real payment/device acceptance. |
| D17 now has typed PO documents, review/issue/refresh/explicit revision approval and session-owned approval state. | Implement `BuyV2PurchaseOrderAdapter` using the exact fields and operations below. Bind authenticated buyer, supplier, listing, variant, pack, destination, commercial terms and revisions. Reuse existing order/payment/invoice/chat paths. | Delivery controller/panel had 18 local PO cases and 87 checkout impact cases pass. Full PO journey and founder approval remain open. |
| D17 collection destination and accepted PO references are being added now. | Support exactly one destination: delivery `address` or `collectionStore`. Carry accepted `purchaseOrderRequestId` and `purchaseOrderRevision` into both normal placement and collection basket validation. Reject stale/cross-buyer/wrong-store revisions. | IN PROGRESS: collection extensions must not be treated as frozen or locally qualified until their subsequent test evidence is recorded. |
| D17-A01 revokes approval freshness after failed status checks. | Failed/unavailable/mismatched responses must not imply accepted/current terms. An uncertain issue must reconcile the same request before another issue. | Child locally verified; backend and Redmi pending. |

Provider data belongs to three distinct owners: Store workspace publication and supplier decisions; customer account/profile and authorization; order/payment/delivery services. Store settings, stock, counter sale and ledger are not substitutes for customer-authorized endpoints. Project only appropriate public/customer-order fields; keep private ledger, counter-sale customer records and settlement data private.

Do not restore PO as a payment method, create a second Help/chat owner, manufacture official PO/shipment IDs on the client, or publish review fixtures as real offers. New collection/PO declarations below are source-level connector requirements; API routes, durable reconciliation storage and transport permissions still require implementation and verification in their responsible lane.

Founder clarification: Store is still halfway through implementation. Missing Store capabilities below are pending integration dependencies, not regressions against a completed Store. This is the requested working handoff for Codex Desktop; refresh it against final Store code before final delivery. No original ticket is removed or closed by this mapping. Manufacturer/supplier metadata does not authorize new manufacturer/supplier transactional workspaces.

### Source and acceptance boundaries

Buy branch: `work/cursor-ui/buy-ready-20260921`, HEAD `5dc6885ada1fe0cd23f3d5d0a2bc62fe56cc0abd`, with preserved uncommitted implementation. Last inspected Store HEAD: `c381cc666fb51999d11d1ef6c36dabb43b34faa3`; Store can advance independently. These commit references identify evidence only; they are not a request to integrate or copy worktrees.

Reuse `apps/mobile/lib/features/buy/buy_v2_content_contracts.dart`, `buy_v2_models.dart`, `buy_v2_session.dart` and `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`. Public composition is `apps/mobile/lib/features/journey01/journey_router.dart`. Store's newer `apps/mobile/lib/features/work/work_publication.dart` and `work_models.dart` contain publication projections; the former is absent in this Buy checkout. Its absence here is integration drift, not proof Store has no publication implementation.

The six PDP parents have independent frontend local evidence. Original older thirteen references retain unfinished acceptance; they include implemented behavior and missing integration, not thirteen untouched implementations. Twelve new children are locally verified and awaiting Redmi, giving 19 original + 12 new = 31 tracked references. Historical cumulative evidence (453 selected checks, 83 overlapping content/history checks and 2 native cases) predates the later D09/D11/D17 changes and must not qualify the current dirty source. See the latest per-ticket evidence and current in-progress boundaries above. Existing two undeclared test-tag warnings remain. All 19 original references remain visible for outstanding frontend/founder/Redmi and deferred backend acceptance.

### Ticket-by-ticket dependency reference — not an integration execution order

| Original reference | Public consumer / existing integration point | Authoritative information or remaining connection | Required integration proof |
| --- | --- | --- | --- |
| BUY-PDP-REF-20260924-01 | Shared PDP media; `BuyV2ProductContentAdapter` | Published product media, ordered assets and revisions, exact Store/SKU/variant/pack binding, admitted file and poster metadata. Store publication must supply accepted assets, not review pictures. | Multiple photos and admitted video; changed revision resets selection; revoked/mismatched/failed media cannot show another product; narrow and enlarged layouts. |
| BUY-PDP-REF-20260924-02 | Variant and purchase decision area; product facts/content | Exact variant/pack/size and price identity; supported size chart; real current selling price, eligibility and dated price history. | Variant switch updates facts and cart identity together; stale or mismatched histories do not claim a price drop; delivery eligibility is re-evaluated. |
| BUY-PDP-REF-20260924-03 | Return/COD/support facts and existing Help journey | Seller/category return policy, authoritative payment eligibility, support context tied to order/product. Reuse existing cart Help implementation. | Product → existing Help → order → product preserves cart and return destination; no duplicate Help owner or fabricated COD availability. |
| BUY-PDP-REF-20260924-04 | Similar products shared continuation cards | Current public catalogue, exact product identity, applicable destination and procurement visibility. | Same applicable scope; current item and duplicates excluded; Add/quantity/navigation use existing cart path; withdrawn/stale items disappear. |
| BUY-PDP-REF-20260924-05 | Highlights/specification/description/manufacturer sections | Structured content and stable attribute IDs; legal and manufacturer/packer/importer information from authoritative publication. | No repeated facts across old/new sections; unavailable/invalid publication cannot become ready fallback; long text and retry work. |
| BUY-PDP-REF-20260924-06 | Recently viewed and More products; catalogue pager | Current published catalogue and eligibility timestamps. Recent history is customer history, not Store-created personalization. | Exact viewed variant restored; unpublished items removed; pagination retry retains current page; displayed eligibility expiry removes item without interaction; product/Back/cart preserved. |
| R6633-D07 | Collection identity, `ScanPickGateway`, pending/purchase stores | Verified customer `accountId` and login `sessionId`, authorized collection operations and durable account-scoped recovery storage. | Account switch/logout cannot reuse another buyer's basket or pending purchase; restart/retry reconciles one authoritative outcome. |
| R6633-D08 | Customer delivery assignment | Authorized customer projection of assigned fulfilment and delivery capability. Existing retailer-owner request operation is not customer authorization. | Correct order owner, assignment updates, pending/unavailable/retry and cancellation handling. |
| R6633-D08-C1 | Assignment/scheduling child | Approved scheduling/assignment contract including allowed changes; do not invent selectable slots. | Unsupported schedule cannot be submitted; authoritative update and recovery retain correct order context. |
| R6633-D09 | Checkout/order/shipment identity | Server-issued order/shipment identities bound to authoritative quote and fulfilment groups. | Mixed fulfilments retain identity through cart, payment, order, invoice and tracking; no client-generated authoritative shipment ID. |
| R6633-D09-C1 | Quote/shipment continuity child | Quote expiry/revision and identity reconciliation for changed cart/address/payment. | Stale quote rejected and refreshed; retry cannot attach another shipment or duplicate order. |
| R6633-D10 | Live tracking; `BuyV2LiveDeliveryAdapter` | Customer-authorized live snapshot, legitimate assignment/tracking identity and positions. | Wrong-order data rejected; offline/stale/no-location truthfully displayed; privacy and freshness verified. |
| R6633-D10-C2 | Native live-map rendering | Approved map composition plus valid snapshot coordinates, destination and update lifecycle. | Real renderer receives correct points; invalid/missing/stale positions cannot appear live; return navigation retains order. |
| R6633-D11 | `BuyV2PaymentHandoff`, commerce placement/reconciliation | Approved payment launch URI, authoritative result/reconciliation and idempotency identity. | Cancel/failure/timeout/app return/duplicate callbacks; launching payment never proves payment success. |
| R6633-D17 | `BuyV2PurchaseOrderAdapter`, session PO controller, existing checkout/collection/order/invoice paths | Buyer-scoped review, issue, refresh, supplier decision and explicit revision approval; exact destination and accepted request/revision references. See latest DTO delta below. | Exact supplier line coverage, destination changes, uncertain issue recovery, revision approval, separate payment and existing chat; full journey/collection qualification still pending. |
| R6633-D05 | `BuyV2ComparisonSource` | Published comparable offers with established product/variant/pack conversion, prices, stock and delivery eligibility. | Exact comparisons, loading/empty/error/retry, refreshed eligibility, selection and cart/product return; no unverified lowest-price claim. |
| R6633-D06-B | Offers; `BuyV2PublishedCatalogueSource` | Real published Store offers and supplier identity with current publication/eligibility. | Visible seller matches Store workspace; revoked/out-of-scope offers excluded; review fixtures never become live listings. |
| R6634-C07 | `BuyV2GstInvoiceProfileStore` | Customer account-scoped GST profile read/write and stable owner scope; this is separate from Store onboarding GST verification. | Save once, reuse next checkout, edit/profile entry, failure recovery, logout/account isolation; no duplicate Shop/Wholesale prompt. |
| R6634-C05 | Existing order-resolution contracts | Authoritative per-line partial receipt outcome and corresponding order/invoice/adjustment state. | Partial/full/duplicate/retried receipt, disputed lines and refresh reconcile with backend; local UI evidence cannot prove settlement. |

### Exact current DTO field map

These are current Dart names, not invented API endpoints. Backend transport must explicitly map to these contracts; unresolved transport units/permissions must be agreed before runtime injection.

* `BuyV2ProductContentSnapshot`: required `productId`, `state`, `sourceId`; optional/default content `media`, `highlights`, `highlightFields`, `specifications`, `description`, `customerMessage`, `observedAt`, `sizeChart`, `priceHistory`, `retryable`. `BuyV2ProductContentAdapter.snapshotFor(product)` consumes it. `BuyV2ProductSpecification` uses optional `attributeId`, `groupLabel` and required `label`, `value`. Stable attribute IDs deduplicate structured legal facts; free labels alone must not create repeated content.
* PDP legal IDs: `generic_name`, `manufacturer_name`, `manufacturer_address`, `packer_name`, `packer_address`, `importer_name`, `importer_address`, `country_of_origin`, `manufactured_or_packed_on`, `best_before_or_use_by`, `fssai_license_number`, `consumer_care`. Keep `net_quantity` and `pack_count` semantically distinct. `BuyV2Product` also has nullable `manufacturerAddress`, `packerAddress`, `importerAddress`; do not invent missing legal values.
* `BuyV2ProductSizeChart`: `categoryId`, `sourceRevision`, `dimensionLabel`, `columns`, `rows`, `instructions`. Publish category-appropriate data; do not generate grocery size tables from fashion examples.
* `BuyV2ProductPriceHistory`: `storeId`, `canonicalProductId`, `skuId`, `pack`, `variant`, `sourceRevision`, `currency`, optional `offerId`, `previousSellingPriceMinor`, `currentSellingPriceMinor`, `previousEffectiveAt`, `currentEffectiveAt`, `validUntil`. The two price amounts explicitly use minor units. MRP alone is not proof of a historical price drop.
* `BuyV2ProductFactsSnapshot`: `productId`, `price`, `deliveryPromise`, `partner`, `orderabilityLabel`, `sourceId`; optional `promisedByLabel`, `dispatchPromise`, `deliveryProviderName`, `deliveryServiceLevel`, `fulfilmentMode`, `eligibility`, `storeCollection`, `nextOpeningLabel`, `orderCutoffLabel`, `deliveryFeeLabel`, `observedAt`; also `storeOperatingState`, `stale`. Price/fee transport must preserve existing display arithmetic and explicitly reconcile units; do not assume every integer is a minor-unit amount.
* `BuyV2CollectionIdentity`: required `accountId`, `sessionId`. Current public display/contact identity is insufficient. Neither email nor display name is an authorization key.
* `BuyV2CheckoutQuote`: `id`, `sourceId`, `evaluatedAt`, `validUntil`, `lines`, `total`. Each `BuyV2CheckoutQuoteLine`: `fulfilmentKey`, `itemSubtotal`, `couponSaving`, `tax`, `freight`, `deliveryFee`, `tip`, `paymentCharge`, `total`. `loadQuote` consumes `groups`, `address`, `selectedPaymentMethod`, `selectedBenefits`, `tipAmountsByFulfilmentKey`. Agree currency/units and authoritative identity binding at the transport boundary.
* `BuyV2OrderPlacementRequest`: `lines`, `address`, `paymentMethod`, `total`, `amountDueNow`, `idempotencyKey`, `commercialPaymentTermIds`, optional `checkoutQuoteId`, `purchaseOrderRequestId`, `purchaseOrderRevision`, `procurementContext`. Both PO references bind the accepted approval and are separate from payment. `BuyV2CommerceAdapter` already exposes `placeOrder`, `reconcileOrder(idempotencyKey, paymentReference)`, `refreshOrder(orderId)`. Use these paths rather than a second checkout state owner.
* `BuyV2LiveDeliverySnapshot`: `orderId`, `state`, `customerMessage`, `sourceId`; optional `courierPosition`, `destinationPosition`, `driverName`, `vehicleLabel`, `etaLabel`, `lastUpdatedAt`, `routeProgress`, `trackingReference`. Positions are `BuyV2GeoPoint(latitude, longitude)` with finite/range validation. `BuyV2LiveDeliveryAdapter.load(orderId)` needs a customer-authorized provider; a Store tracking response cannot bypass that boundary.
* `BuyV2GstInvoiceProfileRecord`: `id`, `legalName`, `gstin`, `billingAddress`. `BuyV2GstInvoiceProfileStore`: stable `ownerScope`, `read()` snapshot, `write(snapshot)` success. Null scope disables persistence. Store's `submitGst` concerns onboarding and is not this customer profile API.

### D17 exact connector additions — active frontend contract

* `BuyV2PurchaseOrderLine`: `productId`, `variant`, `pack`, `quantity`, `unitPriceMinor`; optional `requestedQuantity` retains the original requested basket quantity during supplier revision. `totalMinor` is derived. Use the public listing `BuyV2Product.id`; that product model does not declare `skuId`. Map any private SKU key explicitly.
* `BuyV2PurchaseOrderDocument`: `id`, `revision`, `supplierStoreId`, `supplierName`, `state`, `lines`, `itemSubtotalMinor`, `chargesMinor`, `totalMinor`, `terms`; optional `reference`, `decisionMessage`. States: `draft`, `awaitingSupplier`, `accepted`, `revised`, `rejected`. Non-draft documents require a reference; revised/rejected documents require a decision message. Exact line sums and nonnegative charges must agree with the total. PO monetary fields explicitly use minor units; do not silently change existing cart price units.
* `BuyV2PurchaseOrderReview`: `requestId`, `revision`, `buyerAccountId`, `buyerName`, `validUntil`, `documents`; exactly one of nullable `address` (`BuyV2Address`) or `collectionStore` (`BuyV2StoreListing`). Delivery binds address identity and recipient/contact/location values. Collection binds Store `id`, `name`, `address`, `area`, `regionId` and all lines to that Store; it cannot inherit delivery approval. Collection extension is still under local implementation/testing.
* `BuyV2PurchaseOrderAdapter.review(lines, address?, collectionStore?)`; `issue(requestId, expectedRevision)`; `refresh(requestId)`; `approveRevision(requestId, expectedRevision, documentId, documentRevision)`. All return `BuyV2PurchaseOrderReview`. Enforce authenticated account/session ownership and revision concurrency server-side. Duplicate or uncertain issue requests must reconcile one issuance. Changed terms require buyer approval; supplier acceptance is not payment confirmation.
* `BuyV2CollectionBasket` adds optional paired `purchaseOrderRequestId` and `purchaseOrderRevision`, plus `purchaseOrderReference` (provider-issued display reference retained for order/recovery, requiring the request binding), alongside existing `identity`, `store`, `lines`, `paymentMethod`. Accepted PO context contributes to the basket fingerprint, requiring a fresh matching collection quote. The collection provider must validate these references against owner, destination, current approved lines/prices and terms. No PO request/revision may be trusted solely because the client supplied it.
* `BuyV2Session` composition must receive both an authenticated `collectionIdentity` notifier and `purchaseOrderAdapter` for this PO controller. Logout/session changes invalidate local approval and late responses. Existing public route composition is not yet proof of live identity/provider injection. Missing providers must remain honestly unavailable.

Open D17 contract work still includes full delivery/collection checkout-to-order/document/invoice/support continuity, multi-supplier and restart recovery, complete local replay and native founder approval. Coordinate final field changes before implementing a transport adapter; do not close D17 based on the declarations alone.

### Store reconciliation and completion gates

Current inspected backend `backend/functions/src/workspace/retailer_order_service.ts` supports retailer-owner delivery request/tracking, and explicitly leaves secure captain handover unavailable. It cannot be represented as customer collection, assignment, shipment, live-location or payment acceptance. The customer projection must expose only permitted public/order-owner fields; private stock ledger, counter-sale/customer data and seller settlement metadata must not leak into Buy.

For a separately authorized future integration phase, dependencies are: verified identity and permissions; Store publication identity/content; fresh price/stock/eligibility and comparison; quote/order/payment; delivery/collection/handover and tracking; invoice/receipt/account persistence. Do not execute that integration from this handoff. Maintain each original reference separately even where a shared adapter resolves several. Preserve approved frontend Help, cart, compact SKU and Store-card behavior.

Before marking any dependency implemented: record exact provider owner/commit, request/response mapping, account/public visibility, lifecycle and freshness rules, unavailable/error/retry behavior, and idempotency where applicable. Run the relevant existing local tests plus real adapter tests for changed fields, cross-account denial, mismatched identity, stale/revoked data and recovery. Replay impacted navigation across Buy, Wholesale/Bulk where authorized, Offers, Store, PDP, cart, order and invoice. Register and resolve newly reproduced children against their parents. Finish with native founder screens and separately gated Redmi/provider testing. Do not call local fixtures production integration or close backend outcomes on frontend tests.

This working map is documentation progress, not provider implementation or final founder approval. It reflects active, uncommitted Buy frontend changes; the latest collection additions remain under verification. No Store worktree mutation, APK, device action, commit or push was performed for this handoff update.

## Active bounded 19-reference implementation — 24 September 2026


Latest qualification supersedes the running/audit checkpoints below: PDP06 independent frontend behavior is locally qualified on source46d60695e6d4136cc138f47e2f7dad38b8ac59f2fa80cb5aee1fbe3b80d6d4c9. **453/453 cumulative,83/83 content/history impact,2/2 native cases** passed; suites overlap. No failures/skips/missed taps/overflow, analyzer and focused Git whitespace check clean. Two existing undeclared protected-reference test-tag warnings remain explicitly recorded. Three fresh native images match previously inspected images byte-for-byte. Both PDP06-A01 (valid pack history) and A02 (expiry after rail deduplication) are locally verified. Original19 plus10 children =29 references; all ten new children Redmi pending. No active test process.

PDP01–06 each have independent frontend local evidence. This does NOT close six full parents or all19: actual Store/public provider acceptance, founder approval and Redmi remain outstanding on them. D07 is next in sequence but implementation admission awaits the verified account/session identity, authoritative ScanPickGateway, durable pending-intent storage and approved runtime composition contract. Exact actor/reuse/data/owner findings are recorded in boundedGoal19_20260924.nextTicketAdmission; display/contact identity must not become authorization. The original older13 references remain tracked and incomplete. Existing request for approved provider contracts remains unanswered; do not repeatedly ask or fabricate a contract.

Final PDP06 evidence is appended under bounded19-pdp06-local-20260924/ in docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip; SHA256797b95cc283b2d91cb22a3da6a0295592e577dd7be6c6f3cff403dd2895c6331,74,608,522 bytes. All prior CRC/size preserved, including fixture/setup failures and exact runtime child reproduction. Full19 goal remains active; no commit/push/APK/device or full founder-approval-set claim.


Current continuation: PDP06-A02 is confirmed by pdp06-expiry-fifth.jsonl and repaired. The discovery timer now excludes the same Similar/Recent identities as the displayed More grid. The provider-path regression proves an expired displayed product disappears without interaction. Three focused cases and83/83 product-content/history impact cases pass with zero errors/skips/overflow/missed taps; analysis clean. Original19 plus10 children =29 references; A02 awaits cumulative qualification. selected-tenth is running453 cases on frozen source46d60695e6d4136cc138f47e2f7dad38b8ac59f2fa80cb5aee1fbe3b80d6d4c9. The earlier452 result is historical and does not qualify this newer source. No commit/push/APK/device.

Read-only next-ticket recheck: public Journey router still constructs BuyV2Session(core: buySession) without collection identity/gateway or quote/delivery adapters. AuthenticatedAccountIdentity in journey_services.dart exposes display/contact/provider labels, not accountId/sessionId; JourneySession does not expose these authoritative identifiers. Store HEAD advanced to c381cc666fb51999d11d1ef6c36dabb43b34faa3; relevant work_models/work_publication/work_services owners still have no new structured producer fields or collection/quote injection from the requested contracts. Do not substitute display identity or review data. D07 and other existing provider dependencies remain explicit; no Store/auth owner changed.


Latest PDP06 checkpoint: **452/452 cumulative cases**, **81/81 content/history**, **8/8 provider/account/cache impact**, and **2/2 native cases producing3 inspected images** passed. Suites overlap; no failures/skips/missed taps/overflow. Analysis clean. Two existing undeclared protected-reference tag warnings were retained separately. Source unchanged at33eaf9ae959100ff2f0e82952ce83f95e567d77249e3e5dae869598d7bd70cf4. No active process. PDP06-A01 is locally verified; original19 plus9 children =28 references, all nine new children Redmi pending.

PDP06 is still in progress: audit _ProductDiscoverySections._scheduleExpiry nonpaged candidates against the actual Similar→Recent→More exclusions before final local qualification. The timer currently takes the first limit+1 unexcluded discovery candidates, whereas the rendered grid excludes earlier rails; confirm with a focused regression and repair any missed expiry boundary. This is an unresolved source-audit concern, not a closed or device-tested outcome. After06, resume the original older13 references in sequence. D07 needs authenticated collection account injection/lifecycle/authoritative gateway; D08 assignment/schedule and D09 shipment/quote identities remain explicit.

All current PDP06 successes, failures, gates and native images are appended under bounded19-pdp06-progress-20260924/ in docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip, SHA256 a563184e4f03144af54ae90c0e77ed758742085d65029c4bddea5de32d1f5548,71,366,765 bytes. Previous entries retain CRC/size. The older progress paragraphs below describe earlier checkpoints; this paragraph supersedes their running-process and archive state. Full19 goal stays active. No founder approval claimed and no commit/push/APK/device performed.

Latest founder clarification: fully implement all original19 tickets/defects plus children, complete local/impacted verification, then produce actual native screens for founder approval. Progress checkpoints do not satisfy the full goal. No APK/device/commit/push in this implementation phase.

PDP05 independent local behavior qualified: **444/444 selected,129/129 impact and6/6 native cases passed**, zero failures/skips/missed taps/overflow warnings, unchanged source `5177d056036a9993065589b7efe83ec0d1931e30cdd88e2c39cb27dcb1304d82`; suites overlap. Six native images inspected. Tab/expansion/scroll restore across SKU/Back, exact supplied units/paragraphs/producer addresses, legal partition, retry/missing states, both shells and Cart are covered. PDP05-A01 font/large-text review actions and A02 invalid-source ready fallback are repaired and locally verified. Original19 plus8 children =27 references; all eight children locally verified, Redmi pending.

PDP05 remains OPEN for actual Store publication/integration, founder approval and Redmi. Read-only Store checkpoint `fbd4f91c88f932456c25d954906fc02329fcaa76` has the public content adapter/projection; these are not integrated in the Buy branch and do not yet supply the new structured attribute/address/revision fields. Exact producer/DTO/consumer mapping and invalid-source child reproduction are retained. No backend or Store owner edited.

PDP05 evidence appended under `bounded19-pdp05-local-20260924/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `399c9256bafc46d234c6ec110afab5f93ffc00a63fbdc17cc52286d808218ca7`,69,202,600 bytes. All prior entries preserve CRC/size, including failed tests, rejected visuals and execution-gate incidents.

Active sequential implementation frontier: PDP06 Recently viewed and More products for you. Runtime and seven acceptance cases are implemented using existing history, shared product cards, current catalogue and provider pager. History View-all/product/Back/Cart and both product shells are covered. Original19 plus9 children =28 references; PDP06-A01 repairs valid non-listing pack variants hidden by an incorrect publication assumption. Recently viewed now resolves current catalogue membership instead of accepting retained cart snapshots. The complete content/history impact replay passed81/81, with zero errors/skips/overflow/missed taps; a separate provider next-failure/retry/previous case passed1/1. Three native normal/enlarged-text states inspected. PDP06 is NOT fully qualified yet: selected-ninth cumulative452-case replay is running on source33eaf9ae959100ff2f0e82952ce83f95e567d77249e3e5dae869598d7bd70cf4; batch1 passed133. Final native captures, expiry/account impact audit and cumulative completion remain pending. Full provider acceptance, founder approval and Redmi remain explicit on the same ticket. No APK/device/commit/push. Existing catalogue More products remains preserved.

PDP06 source audit: session.recentlyViewedProductsFor (currently procurement/destination filtering), _knownCatalogueProducts, existing _availableForDiscovery and catalogueQuery are the relevant selectors. Reuse acquireCatalogueProducts/releaseCatalogueProducts and BuyV2CataloguePager open/next/previous/retry for paged sources; it retains the last page on failed next requests and bounds cached pages. Do not create a second pagination controller. For nonpaged current catalogue, use the existing loaded source with bounded presentation. showBuyV2RecentlyViewed is the existing View-all owner; preserve its clear/account persistence and product-return callback. _ProductContinuationSection/Card supply the Similar geometry and data fields. Existing BuyV2ProgressiveProductGrid has catalogue-specific gutters/controls; reuse card logic without silently changing all catalogue layouts. Next: implement exact source visibility and Similar→Recent→More deduplication, wire shared lower-PDP section/pager/history action, then mapped tests plus existing recent/discovery/persistence and affected navigation checks. No PDP06 qualification claimed.

The PDP05 progress paragraphs below are historical and superseded by the444/129/6 qualification above.

Founder selected all 19 references for sequential complete implementation and local/impacted/child verification. This supersedes registration-only authority for the six PDP tickets. Exact sequence and per-reference implementation/local/Redmi/child statuses live in config/buy-founder-regression.json, boundedGoal19_20260924. Start: clean pushed 5dc6885a. Six PDP tickets → D07, D08/C1, D09/C1, D10/C2, D11, D17 → D05, D06-B, C07, C05. Parent/child overlap remains explicit (16 work groups, 19 references).

Active PDP05 resumed after network interruption: shared commerce Product highlights and All details (Specifications / Description / Manufacturer info) are implemented, with per-SKU PageStorage tab/expansion state, structured attribute partition, supplied groups/units/paragraphs, explicit retryability and separate full-width producer addresses. Replaced commerce inline compliance/content cards; Medicine retains its presentation. Existing shared Help remains reused. Scope/ownership/memory gates passed; no Store owner changed or supplied data invented.

PDP05 progress, NOT full qualification: content run38 passed before the final three cases; impact run124/125 passed and the remaining older inline-field test passed after navigation-only correction preserving all field assertions. Final native run3/3 passed, no missed taps/overflow warnings, screenshots inspected. Changed UI/test analysis clean. Current source `40e9fce706df1cd1c525f561da9520872bdf7cfb52e2cfa37d895b2e637722f6`. Suites overlap; these are not a single clean cumulative replay. All seven planned PDP05 cases now exist and have focused/impact pass evidence. Cross-SKU state isolation, missing/retry-state audit, structured/legal cross-section partition and cumulative replay still require completion before frontend qualification. Actual Store publication, founder approval and Redmi remain pending.

Child PDP05-A01 registered and repaired: tabs now inherit resolved theme font; review actions stack at enlarged text to prevent word splitting. Native font/word-box checks passed. Original19 remain unchanged; seven additional children =26 references, all seven children locally verified, Redmi pending. All failed attempts are retained and registered (live-log parse, zero-test selection, navigation fixtures, incomplete font repair and stale inline-field impact test).

Progress evidence appended under `bounded19-pdp05-progress-20260924/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `f5610421d4bc6bb7070c1445edc8568a8a7d00ccba7000c39e5ab1687d6c6e6e`,66,655,307 bytes. Prior archive entries preserve CRC/size. No commit/push/APK/device action. No running test/build process at this checkpoint. Continue PDP05 audit before PDP06 and older13; no ticket skipped or fully closed.

PDP04 independent local behavior qualified: **433/433 selected cases,65/65 impact checks and6/6 native cases passed**, zero failures/skips/missed taps/overflow warnings, source `3297ebf5f61135332e5335b874221e7cf2ee34f82d640687a79f7a1781e925d7`; suites overlap. Native normal/enlarged-text screens inspected. Child PDP04-A01 adaptive width/word layout is locally passed, Redmi pending. Original19 plus6 new children =25 references; all six children locally verified. Full PDP04 remains open for actual Store/publication integration, founder approval and Redmi.

Evidence archived under `bounded19-pdp04-local-20260924/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `e04d00062ea34dd910201e5b8223f4b1704ea5bf7c621168a7c898cf95000a2b`,65,258,795 bytes. All prior entry CRCs/sizes preserved. Failed attempts, original/repaired captures, provider mapping and source diff retained. The433-case result is the prior frozen source and does not qualify newer PDP05 edits. No commit/push/APK/device action.

PDP03 independent local behavior qualified: **427/427 selected cases passed**, zero failures/skips/missed taps/overflow warnings on unchanged source `640ee94cbedab6e40dd5b2a643eca95999e09931bd07b58ae2a4882c500e846f`. Earlier runtime impact101 and existing Shopping Help14 passed; suites overlap. Both Shop/Wholesale product -> help -> order/items -> help -> product preserve exact product, mixed Cart, query and product scroll. Four native assurance/help images inspected; 200-percent support behavior passed. Founder instruction is durable: reuse existing Shopping Help/order Help/Chat, no duplicate support implementation. Structured return policy takes precedence; old inline and ratings-panel duplication removed. Analysis and scope/ownership gates passed.

PDP03 remains OPEN for approved COD quote/placement/collector/cash receipt/invoice/ledger contracts and actual Store publication, founder approval and Redmi. An unconfirmed COD information sheet is not completed COD functionality. PDP01/02 publication dependencies remain open too. No new child reference in03; original19 plus5 existing children remain24 total. No commit/push/APK/device action.

Evidence preserved under `bounded19-pdp03-local-20260924/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `eef82dcc2228ea45b04fafa48cce0f7d72a1e385687a016ed644871c703b6539`, 64,682,994 bytes. All previous entries preserve CRC/size, including failed attempts. Next independent sequential boundary: PDP04 Similar products rail using existing source, session navigation and shared product owners; actual related-publication integration remains an explicit requirement.

Previous qualified checkpoint: BUY-PDP-REF-20260924-02 (mvp_supporting), independent local behavior verified; full ticket remains OPEN for authoritative Store publication, founder visual approval and Redmi. Shared native implementation now orders variants before identity/price, exposes category-provided size charts, current-price/MRP details and exact Store/SKU/pack-bound expiring price history, and keeps delivery/Store/reputation/actions in one owner. Existing address, Store, comparison, Chat, Cart and checkout handlers remain wired.

Previous PDP02-source selected replay: **419/419 passed**, zero failures/skips/missed taps/overflow warnings, source `7e657dc91ebeb48edccdad73c9d86b19890cd07b4dee18234b09189316cfc873`. Fifteen cumulative impact test failures were repaired without dropping their original quantity/selection/Back assertions. The earlier runtime-identical checkpoint `c5763f2e063ac58180b294b9eec6677bb0c8916c9f65a4956453fdf557e24d73` passed238 behavioral impact cases,20 content/native cases and2 native layout cases; only four test owners changed afterward. Suites overlap. Two pre-existing skip:true golden-writing utilities were explicitly excluded; all behavioral address/feedback motion cases ran. Changed-owner analysis and scope/coordination gates pass.

PDP02 children A01 (unverified/expired delivery transport) and A02 (large-text address wrapping) are locally passed and pending Redmi. Timed/resumed expiry hides stale transport/history claims; address and Change stack at enlarged text. Original scope remains19 references, plus5 registered children =24. No original ticket is dropped or closed by fixture evidence. Native normal/200-percent captures were inspected using controlled test data; they are not actual Store publication or founder approval.

Evidence appended under `bounded19-pdp02-local-20260924/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `ccfbc9fdc97dfb3f9a187ed0ed85d8fc87d618db9cc186e845ddc21a280e4596`, 64,024,390 bytes. Every prior archive entry preserves CRC and size. Retained evidence includes failed attempts, native images, source diff, typed provider mapping and selected-fifth receipts. Store chart/history projection, retail offer-history identity, producer permissions/revisions and actual publication integration remain dependencies on02. PDP01 multi-photo publication also remains open. No commit/push/APK/device action. Next sequential independent boundary:03 return/payment-information/support, reusing existing Shopping Help and order-return handling while the exact COD provider/collection contract remains unresolved.

PDP01 checkpoint below is historical; its original22-reference count describes that checkpoint, not the current24-reference total.

The older six workstreams are PARTIALLY IMPLEMENTED with existing local evidence, not wholly unimplemented/untested. D10-C2 already has eight current-source passing local cases; live renderer/provider integration is outstanding. Comparison/Offers/GST/partial receipts similarly retain qualified frontend work. Historical receipts are not automatically current after source edits.

Current execution checkpoint (not completion): PDP-01 gallery and fixed purchase controls are implemented in the shared commerce product view. Failed-image retry, publication identity/page/zoom reset, responsive segments and short-screen bounds reuse the existing content/media owners. The dock reuses existing cart scope and buyProductNow handlers; it preserves unrelated lines and Wholesale MOQ. Empty-cart Continue shopping preserves the source return; nonempty Go to cart uses the correct scope. Compact inline Add remains the distinct add-without-checkout action and quantity owner. Medicine remains outside this redesign.

Local behavior qualification: 410/410 selected scenarios, 112/112 media scenarios and 15/15 repaired impact scenarios passed on frozen source `a15229a3ba414fca5e6847edd54a9d4cb1ca97f8f7c2edfcddcc021ea06f987b`. Suites overlap. Zero failures, skips, missed taps or overflow warnings; eight changed Dart owners analyze cleanly. Native normal/200-percent captures inspected using TEST image fixtures, not actual Store product photos or founder-approved visuals. Three children A01/A02/A03 are locally passed and pending Redmi. Original scope remains19 references plus3 new children =22 tracked references; no original reference was removed.

Evidence appended under `bounded19-pdp01-local-20260924/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `ecfa1d44b86ab1e25518af855925f4182799dda5abbe1fc5f016fea7e7a8ce2e`, 60,949,200 bytes. Earlier archive entries preserve CRC and size. Current raw receipts, failed attempts, source diff, provider mapping and captures are retained. Parent01 stays in_progress with full-acceptance cases unqualified: local fixture behavior does not satisfy actual Store publication. No commit, push, APK or device action. Next sequential work: PDP-02 independent Buy composition/typed consumer behavior, while01's explicit publication dependency remains open.

PDP-01 dependency confirmed by read-only Store source at20932c38: `WorkspaceCatalogueItem.toBuyPublicContent` projects `toBuyPublicProduct(...).mediaAssets` from a single catalogue-photo owner. Authoritative multiple-photo publication remains required, alongside remaining shared product composition work. Requested the approved Store/backend integration checkpoint/contracts while independent Buy work continues. No Store source was copied or changed, no source list was fabricated, and no production provider verification is claimed.


## Definitive product-page ticket audit — 24 September 2026, revision 2

Status: the SAME six BUY-PDP-REF-20260924-01 through -06 tickets remain open and unimplemented. This revision replaces the initial active specification, not accepted application code. No new implementation, test pass, APK or device qualification is claimed. Existing 23 selected entries are unchanged.

Audit baseline: Buy 75727e249593ca92d45d06878928e4d014ec4288; Store read-only 20932c3869f360b71cd09d0b840368a86ee89b9d. Reference: 29 retained Redmi Flipkart captures, 720×1600 physical pixels, density 320 (360×800 dp). Captures 20/21 have failed accessibility dumps but valid pixel evidence. Original one-item Cart was restored; no order or payment was made.

### Definitive shared screen contract

Use the existing native BuyV2ProductView, with the same composition for Buy/Shop, Wholesale, Bulk product offers, MoolSocial/Supplier Offers and Visit Store product entry. Bulk remains an existing capability/pack context, not a new wholesale workspace. Preserve channel-specific MOQ, increments, tiers, restrictions and permissions. Do not apply this redesign to Medicine or other deferred transactions.

Vertical order: existing navigation → photo gallery → applicable variant controls → brand/title/selected pack and price → delivery and seller panel → Return/Cash on Delivery/Customer support row → Similar products → Product highlights → All details tabs → existing ratings/reviews where supplied → Recently viewed → More products for you. Purchase actions remain fixed above the bottom safe area; content bottom padding includes their full measured height. Hide unavailable optional sections without blank containers.

Reference-derived implementation targets (chosen measurements, not a claim of exact original font extraction): 360 dp baseline; 16 dp content gutter, 8 dp internal gaps, 20 dp section separation; body 14 sp, secondary 12 sp, headings 18 sp semibold, main price 28 sp bold. Gallery is full width with a 4:5 frame and 16 dp lower corner radius, image contained without crop. Thin segmented indicator below image. Save/Share at upper right and factual rating badge at lower left. Interactive targets at least 48 dp even when glyphs/visual buttons are smaller. Sticky action visual height 44 dp with accessible padded hit area, two equal columns, 8 dp gap and 16 dp gutters. Use existing MoolSocial color/type tokens nearest the reference; do not copy Flipkart identity, assets, advertisements or product values. At 320 dp/200% text, wrap or stack instead of clipping; section order remains unchanged. Verify actual native screenshots against retained references at matching width/state.

Sticky actions: left `Go to cart`; right `Buy now` for eligible retail offers. Buy now uses existing selection, quantity, eligibility and checkout handlers; no second cart or silent removal of unrelated lines. Existing Wholesale/Bulk trade action labels and procurement guards remain authoritative. Catalogue cards keep the already approved Add-on-right layout; do not restore the old full-width bottom Add. Remove a redundant PDP Add when the migrated purchase dock owns that action. Disabled actions expose the actual eligibility reason.

One inline owner per fact: price in price summary; Store identity in seller panel; delivery promise in delivery panel; returns in assurance row/sheet; technical attributes in highlights or specifications; legal producer details in Manufacturer info. Sheets may repeat a value only as needed for its breakdown or policy context. Partition highlights/specifications by stable attribute key, retaining all source facts once. Manufacturer and seller are different identities, not duplicate names to merge. Never deduplicate facts or products merely by visible text.

### 01 — Photos and composition

Owner: apps/mobile/lib/ui_v2/buy/buy_v2_views.dart: BuyV2ProductView, _BuyV2ProductGallery, _ProductContentMediaSurface. Reuse content.media/mediaAssets, admission rules, PageView and Save/Share handlers. Replace the current inset gradient/bordered hero layout with the shared composition; do not append another gallery.

Photo order and primary index come from the approved Store/SKU/variant/pack media revision. Swipe updates the segment and accessible `Photo {index} of {count}`. One image has no misleading pagination. No approved image shows the existing explicitly labelled illustration, not a fabricated photo. Failed remote media shows `Image unavailable` and a retry icon; loading retains geometry. Variant changes replace the complete media set atomically; late responses cannot show the previous SKU. No duplicated cover images to simulate multiple photos. Preserve existing supported video/accessibility behavior. Fullscreen zoom was not inspected and is not claimed as reference behavior.

Evidence: captures 02-product, 03-gallery. Verify 0/1/many images, swipe versus page scrolling, retry, revision changes, variant switching, save/share identities, both page shells, and enlarged text with purchase dock visible.

### 02 — Variants, prices, delivery and seller

Owners: buy_v2_views.dart (_ProductVariantSelector, _WholesaleTradePriceSummary, _ProductStoreSummary, _ProductOfferDecisionPanel, _PublicProductOrderInformation), buy_v2_session.dart and existing models/content contracts. Move the variant selector above identity/price. Move the existing Store summary and scattered delivery facts into ONE panel; preserve trade information once. Do not append a second Store card or duplicate quick actions.

| Placement | Exact label/template and data | Tap/state outcome |
| --- | --- | --- |
| Below gallery | `Select {dimension}`; selected option; `Size chart` only with category chart data | Exact SKU/variant/pack change refreshes media, quote, stock and eligibility together; unavailable choices disabled with reason. Size chart opens scrollable modal, Close/Back returns without changing selection. |
| Chart | Category supplied column labels/units and measurement instructions | Footwear reference columns UK/India, Foot Length (cm), Euro, US (Men) are examples only; never put shoe conversions on groceries. Long rows scroll/wrap accessibly. |
| Identity | Optional real brand, product title, selected variant and pack once | No generic `Store product`, no repeated Store name or repeated pack subtitle. |
| Price | `{discount}% off`, struck MRP when valid, current `{currency}{amount}`, unit/pack basis; factual tax treatment | Tap opens `Price details`: MRP, Discount, Total, then actual cart-dependent fee explanation. Missing/invalid MRP suppresses discount; arithmetic uses existing money rules. Preserve MOQ/tier/minimum total for trade. |
| Optional below price | `Price dropped by {amount}` with comparable previous price and effective date | Only verified price history of the same SKU/pack; MRP markdown is not a price drop. No fabricated sold count. This addition was requested but not observed in reference. |
| Delivery panel top | `Deliver to {location/PIN}` and `Change` | Existing location/address flow; return to same SKU and refresh quote/serviceability. Latest response wins. |
| Delivery panel body | Actual service/date/charge or `Check delivery availability` | Never imply a date/Quick ETA when unknown. Retry a failed lookup without discarding variant/cart. |
| Seller area | Authoritative Store name; rating/count/tenure only when supplied; `Visit store`, `Compare prices`, `Ask` | Existing Store catalogue, comparison and contextual question handlers. Back restores PDP selection/scroll. No copied ratings/tenure or duplicate Ask row. |

Evidence: 04-price, 06-price-details, 08-size-chart. Verify small/large monetary values, no discount, price rise/drop, chart absent, long Store names, address changes, stale replies, stock changes, Wholesale MOQ/tier/increment, and Cart quote consistency. Reference Cart/PDP discount percentages conflict; do not reproduce that rounding inconsistency.

### 03 — Return, COD and support, including complete COD wiring

Owner: buy_v2_views.dart existing protection/return/payment surfaces; buy_v2_session.dart choosePayment, submitOrder, _submitOrderAsync, _handleOrderPlacement; buy_v2_content_contracts.dart commerce/payment contracts; buy_v2_invoice.dart and buy_v2_saved_products_store.dart for downstream payment state. Coordinate Store work_services.dart/work_models.dart/work_session.dart changes with that lane. Do not edit Store from Buy ownership.

Replace the hero return fact and old inline Return _DecisionPanel with one compact three-control assurance row. `Returns` (or source window, e.g. `{days}-day returns`) opens the policy sheet; `Cash on Delivery` opens eligibility/payment information; `Customer support` opens existing contextual help. No extra inline policy card. Return sheet has only supported Replacement/Refund/Exchange remedies, actual conditions/exclusions, and `How to return` linked to the actual order flow. Missing policy says `Return policy unavailable`, never unconditional returns. COD sheet uses supported payment tabs and amount/timing/fee facts. Support sheet has actual help topics and an explicit help action; no invented 24×7 promise, auto-call or auto-message. Close/Back returns to the same product state.

Current gaps verified in code: COD eligibility is client-only Shop/all-lines plus <=₹5,000; checkout hides COD for collectionCheckoutSelected. Default _BuyV2UnavailableCommerceAdapter cannot place production orders. Device-review adapter is synthetic. Store's older public handoff says retail is full advance. The founder's request now requires conditional COD end to end; the old full-advance statement and client cap cannot be treated as an approved authoritative COD contract. Coordinate and record actual Store/location/amount/fee/collector rules before dependent implementation. Wholesale/Bulk COD is capability-driven, not automatically enabled. Payment-on-delivery timing is not itself proof of a cash payment method. Keep QR/Store collection restrictions separate from delivery cash collection.

| Stage | Required observable result and authoritative boundary |
| --- | --- |
| PDP/Cart eligibility | Server/Store-approved policy bound to Store, customer, SKU/pack, address, quote revision and expiry. Mixed-Store/mixed-eligibility handling explicitly defined; no stale client-only allowance. |
| Payment selection | Select `Cash on Delivery`; show amount due now and amount due on delivery from quote, including authorized fees. A pure COD order has no invented advance. Revalidate after address/quantity/offer changes; explain withdrawal and require valid reselection. |
| Place order | Existing idempotency/reconciliation path; confirmed authoritative order, payment `Cash due on delivery`, never `Paid in full` merely because placement succeeded. Unknown/timeout retains pending identity and resolves before retry. |
| Store acceptance/packing | Store receives exact order, payable amount and payment method; acceptance, stock and cancellation transitions agree with Buy. No parallel shadow order. |
| Delivery assignment/handover | Authorized Biker/Bulk collector sees only assigned collectible order/shipment and current amount. Assignment changes/revocation checked server-side; recipient identity and permissions enforced. |
| Cash collection | Authoritative receipt with order/Store/customer/shipment/collector identity, currency, amount in minor units, revision, timestamp and idempotency key. Duplicate taps/replays produce one receipt. Offline submission stays pending; neither delivery completion nor client tap alone proves payment. Partial collection only if explicitly supported. |
| Buyer receipt/invoice | Confirmed receipt updates order payment status, balance, invoice/receipt and persisted recovery state consistently. Cash collected and seller settled remain separate states. |
| Store ledger/reconciliation | Exactly-once posting against correct order/invoice/account; collected cash, amount due and settlement remain reconcilable. Existing WorkCustomerCollectionGateway/ledger checkpoint contracts are reuse candidates; StoreReviewCustomerCollectionGateway is test-only evidence, not a production collection service. |
| Failure/cancel/return | Refused delivery/uncollected cancellation does not generate a cash refund; confirmed collected amounts follow authorized return/refund policy with independent idempotent records. Stale, duplicate, wrong-account and wrong-collector events rejected. |

Dependencies remain on ticket 03: R6633-D11 payment handoff, D08/D09 delivery/quote coordination, authoritative COD policy/placement/collection/ledger adapters and Store full-advance contract amendment. Exact backend/delivery owners and policy values must be registered by the owning lane before execution; they are unresolved, not guessed. Acceptance requires real sandbox backend/Store/delivery reconciliation in addition to local tests. Review data cannot satisfy end-to-end closure.

Evidence: 11-return-policy-loaded, 14-cod-loaded, 17-support. Flipkart COD information was viewed; no COD checkout was performed. Test allowed/denied/expired COD, collection exclusion, mixed cart, process restart, network timeout before/after server commit, duplicate placement/collection, wrong identity, cancellation before/after collection, invoice/ledger balances, refund recovery, and no false paid state.

### 04 — Similar products

Replace Shop/Wholesale _ProductContinuationSection (`You may also like` / `More for business restocking`) with ONE `Similar products` horizontal rail between assurance row and highlights. Reuse session.productContinuationsFor and existing product card/open handlers, after validating related-product semantics. Preserve unrelated category behavior.

At 360 dp use 148 dp cards with 8 dp gap and next-card peek; image, optional actual rating, two-line title, exact variant/pack, price/MRP/discount and actual delivery date. No fake empty card. Current exact SKU excluded; alternatives retain their own Store/SKU/variant/pack. Source failure has compact Retry; successful empty result collapses. Tap opens existing PDP; Back restores original selected variant, scroll and rail offset, with unchanged cart. Evidence 19-similar-highlights, 20-highlights. Test 0/1/many, duplicates, unpublished records, own-Store versus other-Store identity, nested Back and horizontal/vertical gestures.

### 05 — Highlights and All details

Replace _ProductContentSections' three independent _ProductContentCard blocks with `Product highlights` followed by `All details`. Move PDP BuyV2ProductCompliancePanel facts into `Manufacturer info`; retain reusable compliance component for other callers. No standalone duplicate specifications/description/compliance card remains on this PDP.

Highlights: source-ordered label-above-value cells in two columns, thin horizontal separators, expandable only when additional facts exist. All details: tabs `Specifications`, `Description`, `Manufacturer info`, active dark-filled tab, horizontal tab scrolling at narrow widths. Specifications uses `General` only where applicable, source-labelled two-column fields; stack at large text. Description uses approved paragraphs, not copied promotional reference prose. Manufacturer info: Generic name/Country of origin paired when supplied; manufacturer, packer, importer names and addresses full-width, then applicable license/date/consumer-care facts. Store address cannot substitute for producer address. Partition fields already shown in highlights; never repeat brand/title/pack mechanically in new tables. Preserve legally required facts and category units.

Retain active tab/expansion/reading position for same SKU; reset for another SKU; late revisions cannot overwrite current identity. Missing fields are omitted; entire missing details section says `Product details unavailable` once with Retry only if retryable. Evidence 20-highlights, 22-all-details, 23-specifications, 24-description, 25-manufacturer. Test long addresses/labels, category-specific rows, empty/partial content, all tabs, stale responses, screen readers, 200% text and bottom dock clearance.

### 06 — Recently viewed and More products for you

After existing ratings/reviews (one existing instance), add `Recently viewed` with View-all arrow and the same horizontal card geometry as ticket 04; then `More products for you` in a two-column grid, 8 dp gap, equal flexible width. Stack to one column when enlarged text cannot fit. Existing catalogue `More products` is not this PDP section and must not be globally renamed.

Reuse session.recentlyViewedProductsFor and existing history/account persistence; open the existing history entry via View-all. Reuse bounded discovery for further products, with truthful generic recommendations if no personalization contract exists. Exact Store/SKU/variant/pack key governs deduplication: exclude current SKU and suppress repeated cards across Similar/Recently viewed/More on this PDP (precedence Similar → Recent → More); View-all history still includes full valid history. No invented history/rating/sponsorship. No blank section on empty results. Failed source shows compact Retry; pagination retains already loaded products and stable position.

Evidence 26-lower-page, 27-recommendations, 28-more-products. Test recency, repeated view, clear/remove/account switch, persisted restart, stale/unpublished history, pagination/retry, product/Cart/Back continuity and accessible grid. No advertising system, new reviews engine or Q&A feature is implied by captured surroundings.

### Mandatory Store/provider workspace connectors — founder clarification

Applies to all six BUY-PDP-REF-20260924 tickets and their Buy, Wholesale, Bulk, Offers, Visit Store and Cart consumers. Information must come from the authoritative owning workspace/publication path, including manufacturer, supplier and retailer roles where supported. Do not hard-code final product information or build a second Buy catalogue. Recording a manufacturer/supplier source role does not activate a new operational workspace outside approved launch scope.

Reuse and complete existing content/media/compliance snapshots, offer/quote adapters and Store toBuyPublicContent projection before introducing another interface. Keep a documented, typed producer-to-consumer boundary so the Store lane can connect its published data without rewriting the UI. Each field mapping must name the exact producer model/projection, public DTO field, Buy adapter, consumer and test. If a producer field or production adapter is missing, leave its explicit contract and tracked dependency on the SAME ticket; do not report an empty connector, TODO or review fixture as functioning production integration.

| Data | Authoritative producer / required consumer connection |
| --- | --- |
| Product identity, category, variants, size charts, pack and media | Approved product owner/public catalogue projection; preserve manufacturer-origin identity separately from supplier/retailer offer ownership. Gallery, selector and product facts consume the same published product revision. |
| Description, highlights, specifications, manufacturer/packer/importer information | Approved product metadata from the owning workspace; Store publishes permitted public fields. Map structured units/addresses without substituting seller data or repeating fields across sections. |
| Selling Store name/address/partnership, offer price/MRP, stock, MOQ/tiers, tax treatment | Actual selling retailer/supplier offer and Store identity; Buy cards, PDP, comparison, Cart and quote agree on exact offer/pack. Counter Sale/private procurement records are not public offer authority merely because they contain a price. |
| Delivery, returns, COD and support | Authorized policy/serviceability/quote providers associated with the selling Store and destination; eligibility and payment/collection status are verified operational facts, never inferred from descriptive manufacturer data. |
| Price drop, related/discovery products, ratings | Existing approved public history/discovery/rating source; absent source remains a named dependency, never fabricated data. Recently viewed stays account-scoped browsing history referencing current published identities. |

Contract keys: provider/workspace role and ID, selling Store ID, canonical product ID, SKU/variant/pack ID, offer ID where applicable, schema/source revision and effective/expiry times. Document each field's type, units/currency, nullability, provenance and public visibility. Join by stable identities, not names. Resolve conflicting sources by documented field ownership; do not let late or lower-revision data overwrite current selection. Product manufacturer, publishing workspace and selling Store can be different actors.

Expose loading, empty, unpublished/unavailable, stale, denied and retryable-error states through the existing adapters. Provider revisions refresh the affected UI consistently; Cart/payment uses authoritative quote revalidation rather than trusting cached PDP facts. Preserve selected variant and navigation when still valid, and explain invalidated selections. Enforce workspace/account authorization at publication/backend boundaries; never publish purchase cost, private ledger, bank or settlement data. Account/Store switching must not leak cached private content.

Acceptance requires producer projection tests, adapter contract tests and connected UI tests using distinguishable manufacturer/supplier/retailer/Store identities, two stores selling the same product, different packs, partial fields, stale/out-of-order updates, unpublished offers and permission failures. Controlled fixtures may test these contracts locally, but must be isolated from production. Before closure, the owning Store/backend lane must prove actual publication → connector → Buy/Wholesale/Bulk/Offers/PDP/Cart flow; COD additionally requires the ticket-03 operational lifecycle. Register mapping/integration child defects on their parent and repair affected consumers before qualifying them.

### Connected wiring and impacted-code closure matrix — mandatory for every ticket

Both product shells in apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart must be wired: embedded product at the existing BuyV2ProductView call around 2498, main product view around 2819. Reuse onVisitComparisonProduct, onOpenPartnerCatalogue, onAskSeller, session.openProduct/openLinkedProduct and current Cart handlers. Line numbers are audit hints; symbols own the change.

| Entry/interaction | Required return and state assertion |
| --- | --- |
| Buy/Shop, category, search, saved | Same source route/query/filter/scroll after Back; selected Store/SKU/variant/pack preserved; no duplicate route stack. |
| Wholesale and Bulk | Same mode, pack, MOQ, increment, price tier and procurement restrictions; no retail-only amount or payment eligibility leak. |
| MoolSocial/Supplier Offers | Same offer/Store identity and offer-list offset on return; no fixture in production; expired offer handled truthfully. |
| Visit Store / Store category | Store data matches provider revision; correct Store catalogue/back stack; name/address/partnership shown once. |
| Cart line → PDP → Cart | Correct exact line selection; quantity and other lines retained; deliberate variant changes follow existing cart semantics; no silent replacement or extra add. |
| Compare / alternate seller | Exact comparable product/pack; return to original PDP and comparison state; no redirect loop. |
| Similar / Recent / More | New identity/media/content/price together, Back restores prior product and section offset; no shared mutable variant state. |
| Save / Share / Ask / Support | Existing authenticated permissions and stable product identity; cancellation returns correctly; no automatic external message. |
| Address / quote / payment / checkout | Stale responses discarded; authoritative eligibility rechecked; cart/order state survives pending handoff, error/retry and restart. |
| Orders / invoices / Store / delivery / ledger | Payment state and identity agree end to end; unauthorized or unverified events cannot mark paid or collected. |

For each affected owner: trace callers, update superseded layout expectations while preserving behavioral assertions, run targeted existing regressions plus necessary new behavior cases, run analyzer and required repository gates. Inspect and register child defects before retest; repair in-scope children and replay parent plus affected navigation/state checks. Record exact tests/counts/source fingerprint and unresolved dependencies. No ticket closes on visual approval alone, and no backend dependency may be relabelled as frontend completion. Native founder captures, full connected local checks and later checksum-matched Redmi journeys are separate evidence gates.

No implementation or fresh tests occurred in this definition audit. Six ticket definitions are now explicit; source/backend behavior still must be implemented and verified under their recorded dependencies.

Evidence: `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `927e9a22fdb2b6ed02579a0be11fc2577f4b5fd6e3bd10aab3aedc7cc51da571`; revision-1 and all prior archive entries preserved.

## Visit Store Close surround — R6634-C10-A02 — 24 September 2026

Founder requested registration, implementation, local testing and repair of any affected children. Registered as a child of C10 before execution. Removed the circular Close outline from paged/full Store catalogue and finite Shop/Wholesale supplier sheets. Kept existing icon, minimum accessible tap size, tooltip, callbacks and Cart/Back state. Brand and pharmacy presentation remain unchanged. Two application/test files changed; no backend or Store workspace changes.

All 16 focused connected checks and 404 selected behavior scenarios pass on unchanged source `806acfa1b632978aa68922ee4b42b3b41ae15f313aff47edb86580c4d119001f`; these suites overlap. Zero failures/skips/missed taps/overflow warnings; analysis and formatting clean. Actual Shop normal and Wholesale 200-percent captures inspected. No additional child defect found. The selected ledger now contains 23 entries, with prior tickets and scenarios preserved.

Evidence appended under `store-close-20260924/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `f3182150c883da65288b965859041bdf3903afd603ec1833afbe8e7065b75635`, 38,172,348 bytes. Every earlier archive entry retains its CRC and size. Registered reproduction, raw test logs, captures and source diff are retained. Local screen review: `apps/mobile/build/store-close-20260924/captures/eight-store-shop-1.0.png` and `eight-store-wholesale-2.0.png`.

Local pass does not close the device gate. No APK built/installed; founder visual acceptance and successor Redmi verification pending. Existing Store/public integration and backend dependencies remain separate.


## Redmi child repairs locally qualified — 24 September 2026

Latest founder instruction: implement and test locally. Both registered children are implemented and locally passed; neither is closed or verified on the installed Redmi APK.

- `R6633-D06-B-A01`: Suppliers now excludes MoolSocial at the source before counts and pagination, has a distinct query/cursor identity, and rejects a mismatched publisher response before admitting products. Finite and paged views agree. Existing category, Saved, refresh/retry, Store, Cart and Back journeys are retained.
- `R6634-C10-A01`: Store details displays its canonical current Store name once in the heading; the compact details panel does not repeat it. Long names wrap, including narrow 200-percent text; address, partnership, Ask, Close and Back remain covered.

Final qualification: 22 selected ticket entries, all 392 selected scenarios passed, including the existing complete scoped navigation selection. The complete four affected test files passed 640 active tests. These suites overlap; their counts must not be added as unique cases. Zero failures, zero new skips, zero missed-tap or overflow warnings. All six changed Dart owners pass analysis and formatting. Frozen source: `14f65a9f9cdb4569bea4de638103b3bb60694069584ee1528af55176d750c60f`.

The first focused attempt exposed nullable-count and widget-fixture assumptions; the first broader run exposed four historical expectations that Suppliers includes all publishers. Original failure evidence remains preserved. Corrected tests assert exact supplier-only totals and keep paging, failure/retry, Store, Cart, Saved and Back checks. Final source was unchanged throughout both qualifying runs. No additional customer-visible child was found in this local impact replay.

Durable evidence: `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`, SHA256 `e2bc90c39244c5181974c7db4b51934cef22185fb9db80705148a69cca3a91d6`, 18,814,185 bytes. Contains raw failed/passing logs, 200-percent/standard Store and supplier captures, source/test diff and qualification receipt. Prior 95,080,457-byte Redmi archive remains unchanged at `f0b0b0dac485fafbc8429268b4d6cab8322eb6b4c1f28a6769e4aec31a65c7f5`.

Final checkpoint gates passed after synchronizing the exact new archive owner with the paired checker and supplying the existing retained evidence archive path. Both diagnostic failures are registered and preserved; ownership equality and evidence requirements remain enforced.

Local screenshots are under `redmi-child-fixes-20260924/store-captures/` and `offer-captures/` within the new archive. Founder visual acceptance of these exact repair captures and a successor checksum-matched Redmi replay remain pending. Installed r66.35 is unchanged; no APK build/install occurred. Existing Store/backend dependencies remain open. A future published-offer backend must honor `supplierOffersOnly` before counting/paging; the session rejects out-of-scope publications.


## Latest founder gate: Git checkpoint and successor APK authorized after qualification

### Founder-requested Redmi defect replay — 24 September 2026

Test and register issues only. The same installed r66.35 (`2026092302`) was exercised through 38 retained PNG/XML screen states against the 20 selected entries. Application, tests and APK are unchanged. The matrix records observed states and partial coverage explicitly; it does not convert 388 local cases into device passes.

Two confirmed open children are registered in the founder ledger and regression record:

- `R6633-D06-B-A01`: selecting Suppliers sets the paged publisher query to null/All publishers, while the promotion removes MoolSocial from only the current page. Redmi shows “No current offers from this publisher” above a populated grid. Correct source/grid/promotion agreement and publisher page-boundary recovery need implementation.
- `R6634-C10-A01`: Store details has a generic heading and a compact identity panel without the current Store's visible name. Mool Market 1 is available in semantics and on the underlying browse screen but absent from the open details sheet. Restore one visible canonical name without duplicates; preserve Ask/address/Visit/Back.

Observed working paths include comparison results/refresh/Add/Cart price, mixed baskets and totals, one GST entry, Bulk minimum packs and compact trade table, quantity Cancel above the keyboard, required address validation and last-field scrolling, Cart-to-Offers return, order status/payment presentation, category/filter and Store browsing. The missing live-update state remains truthful. Signed-in GST persistence, authoritative receipts/Store integration, live map expansion, full interruption/enlarged-text variants and unavailable retired Android link entry remain unqualified. Original rice Cart (one pack, 395) and Saved state were retained; test additions were removed. No order, payment or message was submitted; no address/GST profile was saved.

Evidence archive SHA256 `f0b0b0dac485fafbc8429268b4d6cab8322eb6b4c1f28a6769e4aec31a65c7f5`, 95,080,457 bytes: all 950 earlier entries preserved; 115 files appended under `defect-replay-r6635-20260924/`, including the per-ticket matrix and screenshot/XML hashes. Parents D06-B and C10 cannot close while their children remain open. Child implementation is not part of this test-only instruction.

### Current installed candidate and Git discipline — 24 September 2026

r66.35 (`2026092302`, isolated package `com.moolsocial.app.cursorreview`) was built only after repairs and qualification were committed/pushed, remote parity and clean Git were verified, and all 13 prebuild gates passed. Exact build HEAD: `5b58240f5df9c7dbbbc5d660158fca4e069e1b45`; application source pin remains `0fd4da937635e159354d5213d134b80516873242`. APK identity, signer and provenance passed. Data-preserving installation on Redmi `TG8HCYTGGQT885OF` succeeded. Pulled installed base APK and built artifact both have SHA256 `3fd6dccb8eac215053e33ccacd6cbfb65b1c1213365079fa4af67d6ed80cc096`. One-build authority is consumed. This evidence-only checkpoint does not change the APK's build HEAD.

Native smoke evidence verifies Shop, MoolSocial Offers, product, Visit Store, Android Back, retained Cart, address/payment/review, single GST entry and editor, Wholesale, global Profile, Personal profile GST entry and return to Shop. The signed-out review session truthfully describes temporary GST retention; account-backed persistence remains dependent work. No order/payment/message was submitted. Original one-item Cart remained intact. Device tooling intermittently returned a null accessibility root during transitions; failure PNGs and diagnostic evidence are retained, and the helper now checks dump completion and retains stderr. Settled captures succeeded.

Current evidence archive: `docs/quality/CURSOR-BUY-R6634-EVIDENCE-20260923.zip`, SHA256 `939c36d4d291d5231f0f37bdf4ffaf42881662330415b8f711e3a9a6a4e776c1`, 85,568,259 bytes. All 889 previous entries are preserved unchanged; 61 build/install/device records were appended under `device-smoke-r6635-20260924/`. The ledger and registry bind this archive. Current local qualification remains 388 selected scenarios including all 120 navigation cases, and two full runs of 2666 active tests each, zero failures.

This is installed smoke verification, not full device acceptance of all 20 selected entries. Comparison, mixed baskets, receipt/payment outcomes, tracking and the interruption matrix still require complete Redmi replay. Tracking visual approval and the already-listed authoritative backend/contract-dependent frontend work remain open. No ticket receives a blanket physical-device pass or production-ready claim.

### Historical prebuild checkpoints (superseded by the installed-candidate record above)

### Successor APK authorization — latest founder instruction

Final local qualification passed on24 September:388 selected scenarios, including all120 scoped navigation cases, with zero failures/skips; two complete Buy cycles4/5 each passed2666 active tests with zero failures and zero interaction warnings. Both retained the same27 inherited opt-in capture cases and unchanged source fingerprint `43c89f54c31d90b4a23607c699ba788530e98d14cbca349ea62749454370be46`. The12 changed Dart owners have clean formatting and analysis. The application repairs are committed as `0fd4da937635e159354d5213d134b80516873242`; this remains the exact review source pin when gate/evidence metadata is committed afterward. No source/test change occurred during either qualifying full run.

The exact source gate, backend/data-egress review gates, brand, approved-reference locks,18 approved integration tips/2 rejected tips, negative boundary fixtures, wrapper/package isolation, support-cleanup fixtures and regression memory all passed. The first successor boundary attempt rejected three inherited imports because the per-owner allowances were pinned to r66.34. Git comparisons and an independent read-only audit prove the Maps methods/imports, local arrival-sound class, complete Store-address owner and Chat Copy owner unchanged; only exact new source/hash pins were added. Original restrictions and old pins remain intact. The unsealed d49 source is rejected. Review exceptions are explicitly not production/backend acceptance.

Final qualification archive: all858 earlier entries retained unchanged,31 completed records appended under `full-qualification-r6635-20260924/`, integrity passed;78,539,834bytes; SHA256 `37abfa20997aeac1da5bb0c53a73be8fdd9369224d23d42c69960259dc4aca39`. Raw full-run log and result hashes are bound in the ledger/registry. The r66.33 and r66.34 APKs still match their original provenance hashes. Final precommit, push/readback, clean Git, source manifest and machine seal precede the authorized r66.35 build; no APK has yet been built at this recording. Device qualification, tracking visual approval and disclosed backend/contract-dependent frontend work remain pending.

Current source checkpoint qualification: selected-r4 passed388/388 (133+130+125), zero failures, zero skips, no missed taps, unchanged source `43c89f54c31d90b4a23607c699ba788530e98d14cbca349ea62749454370be46`. All120 scoped navigation cases across12 files are included. All12 changed Dart owners have clean analysis/format evidence, including the latest tooltip and feedback checks. All20 selected entries have current-source local receipts; physical Redmi acceptance and disclosed backend dependencies remain open. Two complete Buy cycles4/5 are now running before APK clearance; selected pass is sufficient for the source repair checkpoint, not APK authority.

Final selected evidence archive: `prebuild-final-r6635-20260924/`, all798 earlier entries preserved,60 completed files appended, integrity passed;78,292,113bytes; SHA256 `43d9c9359dca6dafebb4dadf8cf37f2560ef3a174463ea9efafbac48fe35598b`. Superseded selected-r3 is retained:387 passed/1 missing-tooltip failure and source changed; final-r4 repaired this with zero failures. Full-cycle receipts will be appended after completion. No APK built or installed at this checkpoint.

Final independent C09 audit found the Profile tooltip missing after its semantics/44px-target repair. Restored a Tooltip with excluded tooltip semantics around the existing single labelled control; the existing compact enlarged-text Offers/Profile/Chat case now long-presses and verifies the visible tooltip before exercising Profile and Chat return. Targeted replay passed with no errors; analysis is recorded in `profile-tooltip-analysis.log`. No new scenario ID was needed: C09-offers-profile-chat-impact already covers this route. Selected count remains20 entries/388 scenarios. Source after this correction supersedes selected-r3; selected-r4 and full cycles4/5 must qualify the final unchanged bytes. Earlier receipts remain historical, never APK clearance.

Feedback keyboard repair passed all11 active tests with zero errors or missed-tap warnings; its existing optional capture case remains opt-in. Formatting and analysis passed. Full cycle3 finished2666 passed/0failed/27 inherited optional capture cases, but correctly failed qualification because source changed during the run. This is diagnostic proof only. All fixes, evidence and gates must be committed on the assigned Buy branch, with clean Git and verified remote parity, before the fresh authorized APK.

Inherited prebuild coverage gap under C13: `review keyboard keeps composer and final actions above the Android boundary` emits a missed-rating-tap warning, also present in r66.34 and diagnostics1/2. It asserts only keyboard geometry, so its passing result is not rating interaction evidence. Independent audit confirms missing settle/reveal and rating/Save-enabled assertions; no runtime rating failure is established. Admit exactly `buy_v2_product_feedback_sheet_motion_test.dart`, settle keyboard focus/scroll, explicitly reveal and hit-test the rating, require its callback and saved draft rating5, and retain all keyboard-boundary checks plus enabled Save. Do not silence the warning. Replay this and existing submission coverage, then refresh selected/current-source full qualification. Earlier387/source66c4 receipts remain historical after this test edit; no APK may use them as current qualification.

Final selected replay passed387/387 with zero failures, zero skips and unchanged source fingerprint `66c4ba0ffa2fc7c0c7163530683cdeaed64783af88d1281fdb0f31c496f1ad8e` (`apps/mobile/build/r6635-selected-final-r2/summary.json`; batches133+130+124). This includes all120 navigation cases across all12 affected files; no navigation case is missing. Ledger local receipts are bound to these exact current logs. Full Buy qualification cycles, final analysis, evidence archival, committed clean Git and exact review-source gates remain required before APK. Physical Redmi acceptance remains pending; no selected or backend ticket is closed by this local result.

Final11-owner analysis and formatting both passed. Repair evidence archived under `prebuild-repairs-r6635-20260924/`: all607 historical entries retained with identical CRC/size,191 completed evidence files appended, archive integrity passed. Current ZIP size72,958,453bytes, SHA256 `5a621c4f2f9b539808afd88dcece8c20c79e24d05207a5a88b5989b150e6e241`; ledger/scope hashes rebound. Full-cycle evidence will be appended only after completion. Diagnostic cycle2 ended2650passed/16failed/27inherited capture skips; all16 dispositions have passing targeted proof. Qualifying cycles3/4 use unchanged source66c4… and stop on failures. Remote readback is `fcba2aba7971fa757b15479df6f0e2c701b6dc7f`, matching the tracked remote; five local checkpoints retain the complete approved work, with no divergence.

Current selected matrix is387 scenarios across the existing20 ticket entries. All120 navigation cases from the previous complete12-file navigation run are explicitly included (r6635 `navigation-selected-coverage.json`:120 included,0 missing); successful current selected receipts will therefore also establish complete scoped navigation replay without redundant execution. All20 Featured cases and all38 supplier-media cases passed targeted replay. Supplier-media fixture uses onlythree products and no indicator inset: normal Shop320=2,360/390/430=3; Wholesale320/360=2,390=3. Do not substitute the paged metadata fixture's counts. The first media replay incorrectly reused that390 expectation and failed3 cases; corrected exact geometry passed all38, preserving decoded-photo aspect/source, badge/Save separation, no placeholders, card containment and cart state.

Formatting passed all11 changed Dart owners. Earlier analysis passed10 owners; latest catalogue/media-test changes require final analysis. Scope,124-owner admission, approved UI locks,21 founder-evidence checker tests and clean-support regression passed. Two complete full Buy cycles are queued behind successful current selected replay and completion of diagnostic cycle2; temporary runner stops on any failure or source fingerprint change. No new APK, installation, final commit or push has occurred.

Prebuild continuation, 24 September: original full diagnostic ended with2617 passed,50 failed and27 inherited skipped cases. It is not qualification evidence. The48-case compact SKU/Offers/Compare/preview child replay passed. Late targeted replay passed all but the old related-Store border/shadow expectation; that final exact case subsequently passed after reconciling the already-approved gradient card. Profile runtime now explicitly labels its Semantics owner and retains the exact44px unboxed target. Store tests assert the single sheet title and accessible partnership identity rather than the retired duplicate heading; closed/empty status, Ask, Cart, Back and enlarged-text checks remain. No new skips or weakened behavioral assertions.

Second full diagnostic exposed four C13 metadata fixtures that still assumed three columns with inline Add. Correct exact fixture geometry to Shop320=2, Shop360/390=3, Wholesale320/360/390=2, retaining containment, no truncation, semantics and ten-pixel row gap. All18 metadata variants plus the unchanged four-product Store case passed in `metadata-columns-replay.jsonl`. Independent impact audit also confirmed an actual C13 child: Featured cards use Add over the image and a full-width price, so the shared resolver must not subtract inline-action width. The existing grid now takes an explicit inline-price-action flag, defaulttrue for compact cards and false only for Featured, whose measured body/highlight inset is26px. Preserve Featured three-column and enlarged-text tests; never relax them to conceal this child.

All310 selected scenarios passed their assertions, but the runner correctly rejected source consistency because the two new Cart reference images were added to the tracked Git inventory during replay. Retain `r6635-selected-final/summary.json` as nonqualifying; replay after final fixes and the tracked inventory are frozen. Second full run is diagnostic once the Featured fix changes source; require two subsequent complete passing cycles. No build authorization is consumed by diagnostic runs.

The two Cart golden differences are confined to recommendation Save surrounds (Android360 bbox157,630–338,651; iOS430 bbox157,604–354,626), independently reviewed by reconciliation agent. Existing C09 founder approval covers unboxed Save on all applicable surfaces. New immutable successor references live in `candidate_captures/cursor-r6635-approved-unboxed-save-20260923/`; prior references are untouched. All eight generated diagnostics were copied with hashes to r6635 `golden-diagnostics/` before restoring the historical tracked diagnostic bytes. Ownership admission initially rejected missing new files, then diagnostic changes outside the claim; both receipts retained. Admission passed124 exact owners after staging the new reference files on disk and preserving/restoring diagnostics. This is not a waiver of ownership checks.

Selected ledger now registers310 scenarios across the same20 entries, including12 late Profile/Cart/Store impacted cases. Frozen-source selected replay and corrected full Buy cycle started; all new receipts remain pending. Original250-source receipts and120 navigation result are historical until successor replay completes. Founder Git discipline is binding: no APK from dirty source, no skipped failures, no source pin to an older checkpoint. No APK built or installed.

Founder clarification during prebuild: latest approved implementation supersedes older behavior wherever applicable; fix stale tests and actual defects before APK. No APK until all required candidate checks report zero failures/errors. A diagnostic failing run is retained, never counted as qualification. This is a hard build condition, not permission to waive assertions, skip cases or mark production dependencies passed.

Additional founder clarification: every fix must follow Git discipline before APK. Completed approved batch is checkpointed locally at `d49e630f`; newly discovered prebuild repairs remain uncommitted until qualified. The candidate must bind the final committed source, pass clean-state/ownership/secret/evidence gates and preserve ancestry and remote readback discipline. Do not build from uncommitted repairs or use the earlier checkpoint to conceal later source changes.

Prebuild impacted-test finding under existing C12/C13: all six `Offers cinema toolbar media` variants still assert that Add is the last row. Founder subsequently approved Add beside price, with required delivery/details below. Actual48px measured below Add is not itself empty space. Reconcile this exact owned test to assert right-of-price placement/44px tap target and a tight card boundary after the final visible text; retain masonry spacing, quantity add/increment/remove, unchanged neighbour size, filter and enlarged-text assertions. Actor is buyer browsing Offers; mvp_supporting, no runtime redesign or provider change. Retain first full-run failures under the r6635 candidate and rerun the complete file plus full Buy suites before APK qualification. This is an impacted old-layout assertion, not permission to weaken spacing coverage or skip cases.

Second impacted fixture under D05/C08: `compact Compare unavailable and product Add 2.0` now receives the newly implemented debug comparison provider, so it measures a populated742.72px results sheet against an unavailable-sheet650px cap. Explicitly disable review data in this unavailable-state fixture and assert the provider is absent. Preserve the650px cap; populated comparison is independently covered by D05 and C08 cases. Reuse owned `buy_v2_post_redmi_fixes_test.dart`; no production layout/source change is justified by this fixture mismatch. Replay both normal/enlarged variants and keep all product action checks.

Confirmed runtime child under C12/C13: inline Add reduces price width in three-column320px cards; the existing exact large-price fixture wraps `INR1 crore` over three lines at normal text. Preserve minimum12px price readability and44px Add targets. Reuse `_resolveCompactProductGridLayout` and existing text measurement to reduce columns only when price and inline Add cannot fit; no clipping, hidden digits, tiny scaling or return to a bottom Add row. Verify existing long-metadata Shop/Wholesale cases, responsive grids and Offers masonry, then show changed adaptive screens. No new model/provider/dependency.

Independent reconciliation audit found two related details before qualification: include both one-pixel card borders in price-width measurement (22px total horizontal border/body/highlight allowance), and resolve each cached adjacent page against its own products during swipe previews. Otherwise a short-price current page could squeeze long-price next-page cards until the page changes. Keep the same sizing function and qualify preview/navigation paths; fewer columns are an explicit readability exception to normal three-column presentation, not a claim that the original fixed layout is untouched.

The same run also found Recent `w-rice-50kg` price word wider than its allocated line; include this existing test in the adaptive-price replay without relaxing its complete-text requirement. Two RV6 D002 enlarged-text Store re-add tests tap at negative y after `ensureVisible` without a frame; settle and recheck visibility/hit testing before tapping, retaining zero-to-minimum quantity, Store retention and subsequent Back/other-destination assertions. Reuse the already-owned partner-catalogue test; do not suppress missed-tap warnings.

First targeted Offers replay exposed two errors in the new measurement helper: identical const Add Text widgets made a global widget finder ambiguous, and text-edge measurement omitted the one-pixel card border. Measure each exact Text element's RenderBox and allow only the existing five pixels (2 line +2 body +1 border), with no row filler allowance. Retain `child-replay-1.jsonl`; this failed repair attempt is not acceptance.

That replay passed all four large-price cases, both Recent cases and all four Store re-add cases. Comparison fixture repair also disabled its seed product, removing Add before reaching Compare. Use a test-only session that retains the product fixture while explicitly exposing no comparison source, preserving original unavailable-state intent and the650px limit. Offers fixture at320 contains1680/3480 prices that cannot fit alongside44px Add in three columns; explicitly expect two columns there and retain three-column alignment at390/wide, square images and all geometry/action checks. No passing count is claimed for unreplayed corrections.

Measured follow-up supersedes the estimated390px assumption above: the same long-price Offers fixture requires two columns at390 as well, while wide844 retains its multiple-column first row. Assert those fixed fixture outcomes explicitly. Full prebuild also exposes24 identical old-bottom-Add assertions in `buy_v2_shared_sku_fit_test.dart` across Shop/Wholesale/Medicine/Store/Saved/Search. Admit this exact test owner; migrate only that geometry contract to right-of-price/44px action plus final-detail5px boundary, retaining save, badges, square media, containment and10px masonry gaps. These are24 affected cases of the same approved C12/C13 change, not24 unrelated customer defects.

Additional existing responsive case must explicitly expect two columns at320 for its fixture while retaining three at360/430, complete metadata, bounded card geometry and reachable actions. Existing Offers Profile/Chat case requires the retired exact44x44 box; approved unboxed action is48x45. Keep a44–48px bounded touch target and actual hit testing, preserving Profile/Chat opening and exact Offers return. These owned tests are C13/C09 impacted coverage; no runtime route changes or navigation assertions removed.

Further Profile audit refines that disposition: source explicitly requests44x44 but inherited Material tap padding expands it to48x45. Preserve the established44px contract by setting standard density and shrink-wrapped outer tap padding, retaining the full44px target and unboxed icon. Restore the descriptive `Open your MoolSocial profile` tooltip/semantics removed by the visual conversion. Keep the original exact-size and semantic route tests; this corrects the runtime child rather than accepting incidental geometry. The original first full command also included nonexistent `test/features/buy`; retain its load failure and use the actual full `test/ui_v2/buy` directory in corrected cycles.

Build-control child: the wrapper correctly checks the native Python founder-regression gate exit, but its self-test enumerates only the previous five native calls. Admit exactly `scripts/test-public-auth-sideload-build-controls.ps1` to the primary review-qualification claim and add the precise Python invocation/exit binding as the sixth expected pattern. Keep rejection of unmatched native exit checks and PowerShell-to-PowerShell misuse. Retain failed foundation receipt and rerun the unchanged wrapper safety suite after the test correction.

Founder now explicitly authorizes the Git checkpoint, a fresh incremental Redmi APK and device testing, with build/validation defects repaired before installation. This supersedes the earlier Git/APK hold for the isolated review candidate; it does not authorize production promotion or invent missing provider contracts. Buyer review of the complete latest branch is mvp_supporting. Reuse the existing CursorUiReview debug wrapper, separate `com.moolsocial.app.cursorreview` package and preserved-data upgrade. Current Redmi is r66.34/code2026092301; reserve successor r66.35/code2026092302 after checking no conflicting candidate. Do not downgrade, cherry-pick away earlier work, uninstall or clear app data.

Exact owners remain the120 recorded claim; build evidence stays under ignored `apps/mobile/build/review-candidates/cursor-buy-r6635-20260923/` and is archived into the already-owned evidence ZIP. Reuse source manifest, UI/reference locks, boundary review checks, clean-support controls, all250 selected receipts/all120 navigation tests, and two full Buy prebuild cycles. Retain any failed attempt, fix its root cause and replay impacted parents/children before qualifying a successor. New tracking captures remain subject to founder visual review, distinct from technical/device checks. Shared Store/Counter Sale work and all previous evidence remain preserved. Payment/order authority and live location are explicitly unavailable where contracts remain absent; no real transaction or sent message is part of review. Verify candidate package/version/signer and installed APK checksum before Redmi acceptance. No blanket production-ready claim follows a debug build.

### Historical qualification at d49e630f — 23 September 2026

This result supersedes the incomplete replay counts below. All120 tests in all12 affected navigation files passed, with zero failures and zero skips (`apps/mobile/build/pending-full-navigation-machine.jsonl`). The consolidated selected matrix also passed250/250 scenarios across20 ticket entries, with zero missing cases and unchanged source fingerprint `76ba164afcc258d1c072f6b96a3209df7b96c82e1f44050c01436528519f5607`. Navigation tests overlap this matrix; do not add120 and250 as unique coverage. Exact per-case receipts are now in `config/buy-founder-regression.json`; batch receipts and runner are in `apps/mobile/build/pending-successor-final/`. Analysis passed all19 changed Dart owners with no issues.

Final metadata checks: Buy regression `pre_commit` evidence validation passed without staging or committing; coordination implementation passed120 claimed owners/4618 registry entries; scope authorization passed; whitespace check passed. The first scope receipt rejected a raw file hash because its contract hashes canonical LF text. Rebound only the manifest hash using the existing canonical rule and retained both receipts (`pending-final-scope.log`, `pending-final-scope-canonical.log`). No gate was weakened. Inventory retains its historical snapshot with an additive current HEAD/75-commit qualification record.

The14 historical findings have been reconciled and replayed. The real Create child under C06-A01 is fixed: legacy/default/empty/unrecognized Create entry uses the existing post editor state, preserving failed-save blocking, retry and return to Feed. Recognized editor modes remain intact. Test-only cache injection isolates widget-test async lifetimes without resetting production persistence barriers. Two documented forwarding lines narrowly suppress the visible-for-testing diagnostic; no global analyzer settings changed. Tracking D10-C2 compact fallback, map expansion/collapse and order-change reset passed normal and140-percent text tests. Actual Google Maps/provider integration remains open.

Durable archive `docs/quality/CURSOR-BUY-R6634-EVIDENCE-20260923.zip` now has SHA256 `6d47f9f2bed98b1c808e704f69e12889774d000ff70b374f9b76dbae235eba29`. All486 prior entries were preserved with identical CRC/size and121 new files appended under `pending-successor-local-20260923/`; archive integrity passed. New entries retain repository-relative paths for restoration into the same workspace without overwriting newer evidence. Includes passing and failed replay logs, approved gallery and approval records, and four new native tracking captures. Original19-entry founder approval remains valid for those visuals; new tracking presentation is not yet approved.

Production backend-boundary gate failed20 existing findings, retained in `apps/mobile/build/pending-backend-boundary.log`. Relevant transport/scanner owners and offending imports were unchanged by this batch. Do not waive this result or describe local acceptance as production clearance. D07 identity, D08 assignment, D09 shipment identity, D10 actual map/access lifecycle, D11 payment handoff and D17 PO issuance/decision contracts remain open, including dependent frontend wiring. Production AGENTS.md requires stopping dependent implementation when the required authoritative contract is unresolved. No simulated authority is substituted. Git checkpoint/commit/push and APK/device work remain held; no all-backlog-complete claim is made.

### Resumed pending implementation after founder cleanup

Historical13 navigation/projection follow-up now selected under C06-A01, mvp_supporting regression qualification only. Reuse existing action-wording, contextual-subaction C11, dock-parity and navigation C03 tests. Admit the two previously unclaimed owners `uaw_personal_mvp_contextual_subaction_thumb_shelf_c11_test.dart` and `uaw_personal_mvp_dock_projection_parity_fix1_test.dart`; other two are already root-owned. Accepted authority: C32I Home-first successor ticket (videos/Home, shorts/Shorts, create/Create, feed/Feed), C32L specialized dock and C25F protected successor audit (Products/Wholesale/Orders and Medicine under Care). Current compact launcher opens an overlay preserving Social; it does not open the retired Home route. Migrate obsolete expected projection/menu/Feed/Create owners and use controlled existing YouTube fixture for watch/Back coverage. Preserve exact family labels, IDs, order, touch targets, removed actions, route selection, video lifecycle, draft/no-send and Back assertions. No protected Social runtime edits, skips, deletions, provider requests or historical JSON rewrites. Replay all four files and retained Chat file; register any actual runtime finding separately. This is reconciliation of known findings, not new feature activation.

Tracking/chat implementation replay:17 tests passed in `apps/mobile/build/pending-tracking-chat-03.log`. The preceding02 Chat log exposed a test parser mistake (link is inline after `Product link: `, not a separate line); corrected parser preserves exact host/path/product/route checks. D10-C2 now has compact absent-renderer copy and expand/collapse with order-change reset, plus normal/140-percent tests. Live Google map and authoritative contracts remain pending; approval of earlier screens does not automatically approve this new tracking presentation.

First migrated four-file navigation replay retained29 passes and3 failures in `apps/mobile/build/pending-navigation-reconciliation-01.jsonl`: two Create return assertions cannot find the assumed Feed rail after system Back; the video/menu case incorrectly assumes navigator.canPop remains false while the overlay owns a LocalHistoryEntry. Investigate actual Create exit before changing its expected owner; preserve origin and composer lifecycle coverage. The menu must consume Back before leaving Social, so its local-history entry is expected, not an app defect. No skipped case or Social runtime mutation is justified by these failures.

Confirmed affected-navigation child under C06-A01: router maps direct Create to historical `home` state, which the current composer displays as a post but whose Back handler treats it as the retired landing. It routes to retired Home/Buy instead of saving and returning Feed. Select the smallest root-owned correction in journey_router.dart: canonicalize default Create and explicit legacy state/mode=home to existing `post` editor state. Other specialized states remain unchanged. Actor existing authenticated Create user returning to public navigation; mvp_supporting preservation of draft/Back guarantees, not activation/expansion of Social. Reuse existing editor save/failure handling; no Social/auth/persistence implementation changes. This narrowly supersedes test-only exclusion for the already-claimed router owner. Verify default and explicit home links, dirty-save failure retention, rapid Back, and unchanged video/menu route lifecycle. Parent stays open until child tests pass.

Second replay11 passed/2 failed: corrected route now truthfully retains Create when test has no durable draft binding, rather than bypassing saving. Bind a controlled repository in these two navigation tests using the existing RT-08-02 fixture pattern, and explicitly verify failed-save retention for legacy state/mode=home. Existing RT-08-02 rapid-double-Back and failed-confirmed-flush cases already pass (2/2; pending-create-draft-impact.log). Do not disable durability to force navigation.

Sequence investigation (pending-create-barrier.log) proves the global draft write barrier never settles after the preceding widget test, while the exact Create case passes alone. Global cache futures retained across Flutter FakeAsync zones make this a test isolation defect. Explicit unmount, setUpAll and root-zone initialization did not repair that retained chain; temporary diagnostic prints/direct-pop probes must be removed. Reuse SocialUniversalV2's existing visibleForTesting createDraftStateCache parameter via a narrow optional pass-through in createJourneyRouter and MoolSocialApp. Admit only apps/mobile/lib/app/moolsocial_app.dart to current root for this composition seam; default null preserves production behavior and no authentication/persistence logic changes. Each affected test gets a fresh cache and controlled repository. Do not reset production _tail or bypass failed saves. Re-run full sequences, all aliases, error/retry and parent navigation. Independent impact audit also identified malformed/empty Create state aliases; normalize unsupported states to post while preserving every recognized specialized editor state and state-over-mode precedence.

Resolution: construct each fresh cache inside the widget-test body (not setUp's different async context), pass it through the existing router/UI chain, and bind its controlled repository. Fifth replay passes15/15 across C03 and dock parity together, including both failed-save/retry aliases; temporary diagnostic prints and direct-pop probes removed. Admit existing rt0802_dirty_create_back_contract_test.dart as affected test owner: its first draft test still expects the retired hub after Feed. Migrate only that return interaction to the compact menu and keep draft/discard/rapid-Back/failure/specialized-content assertions; use the same fresh injected cache pattern. Full affected navigation files must pass, not selected isolated successes. Malformed/empty aliases and valid mode preservation are part of this final replay.

Next independent implementation selection: existing R6633-D10-C2 compact expandable tracking presentation, mvp_required. Actor authorized Buy customer viewing an active order; outcome readable ETA/partner/freshness with a compact provider map that expands on request, and no oversized empty map when no map renderer exists. Reuse BuyV2LiveDeliveryPanel in buy_v2_views.dart and buy_v2_live_delivery_tracking_test.dart. No new screen, provider, dependency, native setup, auth/shared model or Store owner. Admission adds only the existing tracking test to root's claim and exact gate list. Existing mapBuilder contract remains unchanged. Start collapsed, offer accessible expand/collapse only for an actual injected renderer, retain existing stale/offline/retry/lifecycle behavior, and reset expansion on order change. Test normal/enlarged text, expansion, collapse, order change and truthful absent-map fallback. This completes only independently implementable presentation; actual Google Maps/provider/access contracts remain open and must not be reported as implemented by this local correction.

Founder explicitly resumes pending implementation after cleanup; no repeat deletion or APK is authorized. The final149-case log, approval JSON and committed evidence ZIP survived. First bounded execution is historical supplier-chat regression reconciliation under the existing C06-A01 affected-test scope: actor Buy customer; outcome opening supplier Chat, retaining unsent draft and exact product return without sending messages; mvp_supporting. Reuse existing `uaw_r11_personal_global_chat_continuity_test.dart`, already claimed by root; no runtime/route/provider owner changes. The reproduced tap was at y916 outside800x600 because scrolling had not settled. Settle scrolling and assert actual hit-testability before tapping, including the return visit. Keep all identity/context/draft/no-send/Back assertions. Run the exact case, then the whole affected Chat test file. A new failure must retain its evidence and receive a disposition before retry. Continue remaining13 historical findings and provider-dependent work separately; this test correction does not close those dependencies.

Contract audit for D07 finds the exposed AuthenticatedAccountIdentity contains displayName/email/phone/provider label and sign-in methods, not the accountId/sessionId required by BuyV2CollectionIdentity. No display identity may be substituted for verified authorization. D17 has existing line/quote/idempotency order-placement foundations but no authoritative PO issuance/terms revision/supplier-decision contract; fixed retailer review PO identifiers are not issuers. Preserve these exact dependencies pending coordinated contracts while implementing independent verified frontend work.

Supplier-chat replay `apps/mobile/build/pending-chat-reconciliation-01.log`:8 passed,1 failed. Settling scroll now reaches Chat; the next historical assertion expects literal `SKU: w-oil`, while current prepared context uses the canonical product link with `product=w-oil`, plus variant, pack and quantity. Reconcile this assertion to exact product identity in the parsed link rather than restoring redundant customer copy. This is a second stale assertion within the same historical finding, not a new app defect; retain no-send, draft and exact-return checks.

23 September: founder approved the final right-side SKU Add with "APPROVED NOW", then required that no ticket/defect remain unimplemented before Git checkout. This latest gate overrides any earlier readiness wording below. No commit, push, checkout, APK or device action has been performed for this batch. Preserve the branch and dirty work; a clean Git tree alone cannot establish completion.

The selected19 entries now have149 exact passing scenarios on source fingerprint `d77f2a81601f695e17965d8479455a1df52e0b76231c94fb6ccb2bc2d1b76af9`; the runner confirms unchanged source. Receipt: `apps/mobile/build/visual-approved-final/machine.jsonl`, SHA256 `9e479ab10eb49b2d93692c7b0634d0e8ca033e38a4c95a931ee7379a58ca49b9`. Analysis of10 changed Dart owners is clean. Final approval: `apps/mobile/build/founder-final-visual-approval-20260923.json`; gallery: `apps/mobile/build/founder-approved-20260923/index.html`. Ledger receipts and approval now reflect this final source. These local artifacts still need durable evidence archival before eventual handoff. No selected entry is marked fully closed; live dependencies and Redmi verification remain pending.

Independent read-only reconciliation by the founder-requested sub-agent, plus root review of D17, confirms19 is the selected batch, NOT the entire backlog. The following older work must not disappear behind a backend-only label:

| Existing references | Implemented frontend | Remaining work / honest disposition |
| --- | --- | --- |
| R6633-D07 | Duplicate collection sign-in removed; unavailable/account-unverified states | Runtime collection identity injection absent; account lifecycle composition and authoritative gateway still required. |
| R6633-D08 / D08-C1 | Platform labels and separate service/timing facts | Authoritative assignment/scheduling contract integration pending; obsolete customer-slot chooser is not required. |
| R6633-D09 / D09-C1 | Store-ID grouping and compact review | Authoritative shipment/quote identity and client consumption pending; do not invent client shipment IDs. |
| R6633-D10 / D10-C2 | Polling/lifecycle, freshness, offline/unavailable and map-builder interface | Actual Google map frontend/runtime injection missing; compact expandable map and permission/reassignment/access lifecycle need coordinated contracts. Explicitly deferred integration remains required before launch. |
| R6633-D11 | Payment selection/recovery and handoff interface | Runtime approved payment-provider handoff and authoritative order/payment integration missing. |
| R6633-D17 | Retired PO-as-payment removed; supplier contact and concise contextual draft | Basket-derived PO issuance journey, explicit buyer approval, supplier acceptance/revised terms and connected lifecycle remain incomplete. Shared Store/PO contract coordination is necessary; existing reference checks/review fixed IDs cannot replace it. |

These are6 workstreams with9 overlapping references, not9 additional independent defects. D05/D06-B live offer providers, C07 account persistence and C05 authoritative partial receipt remain dependencies within already-counted entries. Founder previously permitted deferred backend business logic; that permission does not mark missing client integration implemented and does not override the latest Git hold.

Historical14 findings also remain visible:13 Social/projection/rail/video assertions target retired navigation and need reconciliation/replay against the accepted contract; one supplier-chat test taps outside its800x600 viewport before Chat opens and needs corrected scroll/hit-testing followed by the unchanged draft/return assertions. They are unqualified test findings, not14 confirmed runtime defects. Preserve their evidence; do not skip/delete tests or restore retired UI to force a pass. D06-G visual children overlap C01-C05 and existing dispositions; no additional independent unimplemented visual defect was confirmed by this audit.

Next execution must select exact older ticket owners/contracts through the existing scope and ownership gates before editing. Current scope excludes production identity/payment/logistics/backend integration; read-only reconciliation does not silently authorize those protected owners. Keep Git held until each applicable frontend item is implemented and verified or its unresolved contract is explicitly resolved; backend/provider exceptions must remain individually visible. For every fix, inspect child/affected journeys, register any finding before retry, and rerun the parent plus affected regressions. No all-tickets-complete or production-grade claim is justified yet.

## Current disposition — 23 September 2026

The six original R6634 fixes and current frontend follow-ups are included in the
complete Buy branch: C06-A01 production-route test migration, C07 Profile GST and
single checkout entry, D05 controlled comparison and D06-B MoolSocial/Suppliers
offers. **131 registered scenarios passed on the final source; 171 tests passed,
zero failures/skips; analysis clean across19 changed Dart files.** Native compact
and enlarged-text screens were inspected. This is local frontend qualification,
not fresh Redmi, founder approval, real account persistence or production acceptance.

Build later from the ENTIRE final branch, not a cherry-pick or inherited r66.34 APK.
All72 prior commits from integration123ff42c, original22 ticket records and37 prior
Redmi replay records remain included. The latest evidence index/inclusion manifest
is under `pending-local-final-20260923/` in `CURSOR-BUY-R6634-EVIDENCE-20260923.zip`.
The machine ledger retains current-source local receipts for every selected cell.
Backend GST continuation remains `R6634-C07/backendBusinessLogic`; Store offers,
payment/logistics and the inherited D17 purchase-order workflow remain explicitly
pending. Fourteen separate historical Social/projection/chat test assumptions are
retained as unqualified audit findings; no whole-universal-suite pass is claimed.
No APK build/install/device action or push occurred. Origin was read back at
fcba2aba; the final local source and documentation commit seals follow below.

Historical eight-ticket implementation assessment follows:

22 September, latest founder authorization: implement the eight OPEN follow-up
tickets below, locally test connected journeys, register impacted-code/child
defects and retest, then show actual local Flutter screens for founder approval.
This supersedes their earlier registration-only status for this bounded batch.
Integration is explicitly postponed while Codex is busy. No APK, backend,
unrelated module, other-worktree or policy changes belong to this batch.
Starting checkpoint: `757640edd252f61bdd03e3c05d43bf56b525834a`, clean and remote-exact.
Application source at start remains d9ec753b; prior fixes/evidence are preserved.

Execution assessment: mvp_supporting; consumer Buy discovery, product decisions,
order/invoice access and scoped location controls. Reuse existing Buy views,
catalogue, screen, design helpers and session/provider contracts; no separate
screen stack or parallel Store catalogue. Implementation owners are the existing
claimed Buy UI files and focused Buy test owners. Shared models, native setup,
provider deployment and Codex-owned invoice/profile implementation are excluded.
Reuse `_openOrderInvoice` and existing downloads wiring rather than fork them.
Sequence: compact Compare/orders/promotions and fixed Cart/search presentation;
product hierarchy; category/search consistency; location popup; focused journey
tests, child inspection/corrections and rerun; actual local captures for review.

Initial dependency `CHILD-8-MAP-PROVIDER`: this baseline exposes
`BuyV2ShoppingAreaSource.locate/resolve` but supplies no production implementation
and no embedded Google Maps dependency/component. Its area value has a Google
place ID/label, not a current GPS coordinate or map controller. Reuse the existing
interface for the compact current-location UI and truthful failure/retry states;
record any remaining actual map/provider integration separately. Do not draw a
fake map, show sample coordinates as current, or claim live location acceptance.
No provider/permission/native change is silently authorized by a local mock test.
Check this dependency while completing independent UI work; it must remain
visible in the final ticket disposition if unresolved.

Validation: reuse focused production-widget/session tests for Shop, Wholesale,
Offers, Orders, Store and nested product/Cart returns, normal/large text, short/
long content, Android/keyboard insets and missing/failed provider states. Capture
real Flutter renders, explicitly distinguish fixtures from live provider proof,
retain failed logs and register any child before retry. No approved reference
image is overwritten and founder visual approval remains pending.

Founder explicitly requests reconciliation of ALL Cursor work after the previous
integrated baseline, clean local Git, remote preservation and a detailed Codex
handoff. This is a source/evidence handoff, not production or device acceptance.
The original parked source checkpoint is `a78b1b38803b4dca6fcc7d715ee9ccc9528a4482`;
the original evidence-only completion commit is its direct child
`a4ff1e5fde01cdfea29f1bf576bde35aa64a3b6e`. The three authorized product-control
repairs below are a subsequent source delta. Integrate the complete branch
including that delta, not only a78b1b38. The original inventory/receipt remains
bound to the historical checkpoint; it is not relabelled as the later source.
Latest application source: `0a224e546b7c570cf2ba7772cf25e2c030ffee98`.
The eight-ticket source `f4d2e116bb1a42f10d588ac82e36cd23065d6523` remains an ancestor.
The d9ec753b product-control source remains preserved in its ancestry.
Backend implementation has NOT started. No APK is made.

Actor/outcome: the integration owner can preserve the complete Buy frontend and
its Store-facing contract while combining it with Store, Counter Sale and CSV.
Classification: mvp_supporting; prerequisite for non-regressive commerce integration.
Reuse the existing branch, repository, source owners, tests and gate mechanisms.
The smallest complete operation is inventory, preservation, commit, validation,
remote readback and this handoff. No production merge, history rewrite, new
feature, provider deployment, release, credential operation or unrelated policy
work is authorized. Cursor's existing narrow blocker authority covers the exact
historical commit-label admission described below.

## Exact history to preserve

- Worktree: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921`.
- Branch: `work/cursor-ui/buy-ready-20260921`; remote: existing repository `origin`.
- Previous Store/Buy integration: `123ff42cf8179b272d33b480e8267dfa83af2de3`.
- Previously integrated Cursor tip: `ee42be0e21f1707e1cbf2ba3ad966579f118b209`.
- Originally assigned checkpoint: `06432e2b946b02007d9946c562f922294f485632`.
- Full inherited checkpoint including subsequent Store CSV work:
  `79d5401338881f55e65b08c0e7843cbac016fcfb`.
- Pre-reconciliation Cursor HEAD: `87bc96d4c28300146c9e2c3c3b37c7c3aacffed0`.
- Thirteen Cursor commits follow the full inherited checkpoint. Fourteen commits
  follow the originally assigned checkpoint because that range also includes
  Codex's `79d54013` CSV checkpoint. Both ranges must remain reachable.

The adjacent `CURSOR-BUY-INTEGRATION-INVENTORY-20260922.json` records full commit
SHAs, parents, trees, changed owners, working-file fingerprints, inherited tips,
protected-owner equality and evidence disposition. Integrate the complete branch
history; selecting only the latest eleven fixes would omit earlier work.

At reconciliation start, all 40 files in the prior parked-source manifest matched
their recorded SHA-256 exactly. The 41-record status also contained unchanged
generated files with stale index metadata. Their content equals HEAD; no source
is discarded to obtain a clean status. The generated Flutter private-plugin path
correctly points into this Cursor worktree. Regenerate local tool metadata for
the integration worktree; never bind it to another owner's filesystem directory.

## Complete functional scope retained

Earlier commits and the pre-APK local changes include the public Visit Store
redesign; compact Store identity with long-name support and founder-reviewed
motion; Store-only catalogue/search/filter/category scope; More stores wiring;
unboxed Store search; keyboard and Android inset repairs; compact filters and
controls across Buy; active-only Delivery rail; theme-consistent Offers cards;
Saved SKU action clearance; explicit Delivery/Collect at store checkout choices;
Store-sourced concise address and user-tapped Google Maps link; precise customer
copy, product information and unavailable-state repairs from the Redmi audit.
The full historical reports and candidate reference captures are retained.

Latest eleven-ticket local cutoff (details and child evidence in
`CURSOR-BUY-LOCAL-CUTOFF-20260922.md`):

| Ticket | Result retained for integration |
| --- | --- |
| 1 / RB006 | Exact generated Store names normalized in Cart/checkout; genuine names preserved. |
| 2 / RB007 | Store search expands; Finish/Android Back restores scoped controls, filters and paging. |
| 3 / RB008 | Consistent names in Store/draft/Maps handoff; authentic destination still needs Store data. |
| 4 / RB011 | Existing Security return preserves pickup checkout and Cart on sign-in cancellation. |
| 5 / RB012 | Local provider-unavailable/payment-failure/retry behavior verified; live completion remains DEP-01. |
| 6 / RB013 | Pickup promotion removed from both public Store info and Wholesale preview; compact Recent Add; visible area checkmark. |
| 7 / RB018 | Compact unselected payment-benefit cards without an empty status row. |
| 8 / RB022 | One stable accessible recipient-field name while focused; no duplicate editable node. |
| 9 / RB026 | Active estimate says Delivery, without changing actual delivered history/status. |
| 10 / RB029 | Exact Store/SKU/variant identity and honest missing-data boundaries; authentic media/projection remains DEP-02. |
| 11 | Explicit offer classification and location/time-bound multi-option eligibility throughout public Buy. |

Nine implementation tickets are locally closed. Tickets 5 and 10 are complete
only for their frontend portion, with external dependencies explicitly OPEN.
Additional locally corrected children cover cached eligibility after invalid
refresh, address changes, missing Store address, available browsing despite
unavailable ordering, courier versus Scheduled labels and MOQ-independent
Wholesale artwork. No unresolved local child is knowingly hidden. These local
results do not imply fresh Redmi acceptance or live commerce completion.

## Shared public contract returned to Codex

Authoritative implementation: `apps/mobile/lib/features/buy/buy_v2_models.dart`,
`buy_v2_content_contracts.dart` and `buy_v2_session.dart`. The inventory binds
their exact Git blobs and SHA-256s to the source checkpoint. Reuse these types;
do not create a competing Buy fixture catalogue or four standalone Store toggles.

- `BuyV2Product.offerClass`: nullable `retail | wholesale | bulk`; unknown stays
  unknown. MOQ, pack size, quantity tiers and freight are independent concepts.
- `BuyV2ProductFactsSnapshot.eligibility`: nullable `BuyV2OfferEligibility`.
- JSON schema version `1`; required fields: `productId`, `storeId`,
  `sourceRevision`, `customerLocationKey`, UTC `observedAt`, UTC `expiresAt`,
  `offerClass`, `channelEnabled`, `storeReady`, `fleetAvailable`,
  `customerLocationConfirmed`, `options`.
- `options`: zero or more `quick | scheduled | courier | freight | collection`.
  A SKU can have several options. Optional `scheduledSlotId`, UTC
  `scheduledStart` and `scheduledEnd` are required for a valid Scheduled grant.
  Optional `reviewFixture` defaults false; simulated grants never qualify live
  production eligibility.
- Malformed schema/enums, missing/expired/future observations, identity/class or
  location mismatch, disabled channel and unready Store fail closed. Quick and
  Scheduled require fleet and confirmed customer location. Scheduled also needs
  a named future interval. Courier alone is not a booked slot.
- Public location keys bind region, selected Google place and selection revision.
  Catalogue query key v4 includes this identity. Empty-location v2/v3 compatibility
  and the separate Store-procurement purchaser/supplier contract are preserved.
  Providers must echo the exact requested location key; never construct a nearby
  but different identity or accept an earlier page after location/filter change.
- Facts are checked at use time, not just when loaded. Add and checkout preserve
  Cart when eligibility expires/changes, and recheck before provider submission.
  Store catalogue may remain browsable when ordering eligibility is unknown.

Codex owns Store settings, shared product editor, CSV and provider projection.
Use the same versioned Store identities, variants, photographs, prices, stock,
address/location and channel/payment terms. The unfinished Store handoff is a
dependency, not proof that this mapping already works. Resolve the recorded
founder rule that every Store offers collection against the earlier Store-side
disable flag; do not hide the disagreement in successful fixtures. An authentic
Store address is still required to give a customer a usable pickup destination.

## Local verification and its limits

The adjacent evidence ZIP retains sanitized host logs, manifests and the exact
historical-admission test. Failed intermediate runs remain available; none is
relabeled passed. The local-only raw evidence archive additionally preserves
device screenshots/XML, videos and APKs without publishing customer/device data.

- Final local regression selection: 630 passed and one old persistence expectation
  failed; its corrected focused rerun passed (1). All 631 selected checks therefore
  passed across those runs, not one claimed all-green run. No runtime change
  followed the main run.
- Partner suite: 11 passed and four old missing-address fixture expectations
  failed; the 20-pass child rerun includes corrected checks refusing fabricated
  Store addresses and retaining Cart.
- Focused router/semantics run: 44 passed, one existing capture-only skip.
- Procurement/payment/retry/paging/eligibility contract run: 146 passed.
- Analysis: zero errors/warnings, style-only information retained.
- Previous r66.32 qualification had two full Buy passes: 2472 passed, 27 skipped,
  zero failed each. Those qualify the old APK source ONLY, not this cutoff.
- Reconciliation reruns the history/owner/secret/whitespace/handoff checks. It does
  not repeat long app suites without a source change or represent a Git-only
  operation as new runtime qualification.

The original r66.32 APK remains `1.0.0-r66.32+2026092201`, debug review only,
SHA-256 `F74ADCD10DE5A5DFA3F6A29F024484DCB8CAF294FB0682C01680EB7190F2CF8A`.
Its build authorization is consumed; its sealed manifest is immutable. It does
not contain the latest eleven-ticket cutoff. Never reuse that APK authorization
or rewrite its source record to suggest that it does.

## Preservation and narrow handoff repair

All 18 required integrated tips are ancestors; the coverage gate also rejects
the two recorded rejected tips. Store/Counter Sale/CSV, native implementation,
backend and dependency owners remain equal to the full inherited checkpoint.
No other worktree has been edited. Existing source-admission/brand/egress changes
belong to the historical exact r66.32 review snapshot, not a grant for new source.

The historical subject blocker is solved without rebase, squash or changed SHAs:
the bootstrap remains validated by its original exact binding; seven subsequent
legacy labels are admitted by exact commit AND subject only in this worktree,
branch, task, ticket and handoff phase. Twenty-five positive/negative checks prove
unknown commits, altered labels and wrong contexts remain rejected. Future
commits still require `ui(buy-ready-20260921): ...`. Cleanliness, owner, ancestry,
secret, integration, acceptance and release checks are unchanged.

Local recovery: `C:/GUARANTEED OUTCOME/outputs/buy-integration-handoff-20260922`.
Initial source ZIP/patch and manifest preserve the pre-commit bytes. A separate
hash-verified archive preserves every file in the five task-specific evidence
directories, deduplicating equal bytes with exact restore-path mappings. Raw
APKs/device evidence remain local; Git receives source, reports, approved local
captures and the sanitized host-evidence archive. Generated build caches are not
application source. A verified Git bundle and final remote readback receipt are
recorded there at completion. No original evidence is deleted or moved.

## Message to Codex: integrate, then hand over the next baseline

Please use the exact source and handoff commits in the completion record below.
Fetch this branch, verify the remote SHA and inventory, and retain its entire
ancestry back through `79d54013`, `123ff42c` and the prior Cursor tip. Do not
integrate only the most recent commit or copy loose files over your checkout.

Use the authorized isolated integration worktree and existing integration rules.
Preserve Store, Counter Sale, CSV, approved Buy layouts, shared navigation and
the above public eligibility contract. Resolve overlaps deliberately, especially
Buy models/content/session, shared Store projections and existing coordination
controls; never replace your current controls wholesale with Cursor's older copy.
Record source-to-integrated owner fingerprints and explain every conflict change.

Run applicable changed-owner, secret, dependency, source/brand/egress/UI-lock,
focused and combined regressions. Cover Store-specific discovery/search/SKU,
variant identity, Saved/details/Cart, quantity/price/stock, pickup versus delivery,
authentication return, unavailable providers, procurement/Counter Sale/CSV,
stale pagination and every eligibility failure case. If the sealed-source gates
reject new integrated code, qualify that exact revision through their existing
process; never carry the r66.32 snapshot exception forward by changing its hash.

After integration, hand Cursor a clean, remotely verified FULL baseline: exact
repository/worktree and branch, commit plus any required annotated tag, both
source branch SHAs included, reconciliation manifest, shared contract hashes,
combined test evidence, remaining dependency list and next ticket ownership.
Confirm that no Cursor commit/file or Store work was omitted. Backend starts
only from that delivered baseline with the required accepted UI/contract binding.
Cursor remains parked until then; this handoff does not start backend work.

Mandatory next Redmi replay, together with backend tickets: all eleven local
dispositions and children, keyboard/Back/insets, Store search and scope, names,
compact Recent/benefit/Offers, accessible request field, active delivery wording,
live authentication/payment/order recovery, authentic Store SKUs/photos/address/
Maps, multiple eligibility options and expiry/location changes. Keep DEP-01
(live providers), DEP-02 (authentic Store projection/media/destination) and DEP-03
(isolated zero-active Delivery rail dataset) open until actually verified. The
founder explicitly deferred an APK for this eleven-ticket batch.

## Completion record

Source commit: `a78b1b38803b4dca6fcc7d715ee9ccc9528a4482`.
Source tree: `087809d63073b6528fe59237efe5180965348136`.
It preserves all 13 earlier Cursor commits and commits all 43 remaining changed
files, including earlier uncommitted source/test/evidence. All 56 payload blobs
match the inventory. The three generated/native files that had stale status
metadata equal HEAD byte-for-byte and contain no omitted changes.

Verified at the source checkpoint:

- Coordination implementation, pre-commit and clean handoff: PASS; 59 exact
  owners, registry 4616 and its original SHA binding unchanged.
- Incremental handoff: PASS. Its r66.32 version arguments identify the historical
  ticket only; this is not a fresh APK build authorization or source qualification.
- All 18 required inherited tips: PASS; two rejected tips remain rejected.
- Historical secret scan: all 13 Cursor commits, 84 unique blobs / 77 text blobs,
  zero matches; staged and committed gate scans also passed.
- Historical subject-admission tests: 25 positive/negative checks passed.
- Staged whitespace: PASS. Payload fingerprints: 56/56 matched.
- Source, tests and captures remain byte-identical to the verified pre-reconcile
  snapshot; only the documented narrow handoff controls and documentation changed.
- Clean status: 0 staged, 0 unstaged, 0 untracked. Empty status SHA-256:
  `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
- Actual `origin` branch readback equals the source commit. No force push,
  history rewrite, merge, production/main or other-worktree mutation occurred.

Verified recovery artifacts:

- `cursor-source-since-integration.bundle`, SHA-256
  `f655abb8230a4d8b616bfffcd7b100a6fe8d2f269a767629d3dd55a2b6f44418`.
  This is an incremental Git bundle containing the complete source branch since
  `123ff42cf8179b272d33b480e8267dfa83af2de3`; that existing integrated commit is
  the explicit prerequisite, not an omitted new change. Bundle verification passed.
- Local raw evidence: 1,560 files, 1,301 hash-verified unique blobs; archive SHA-256
  `bfc6ffb9784e180458b307593cdaff5fefeb316f02748858758490deff77fec6`.
- Remote host-evidence ZIP: 62 retained files, 525,213 bytes; exact hashes and
  per-file mapping are in the committed inventory and ZIP manifest.
- Original r66.32 source manifest is unchanged. Prior archives and evidence are
  preserved in place; the new archive is an additional recovery copy.

The completion commit changes only this handoff and its inventory, with no source,
test, control or asset change. The final receipt at
`C:/GUARANTEED OUTCOME/outputs/buy-integration-handoff-20260922/final-verification.json`
binds that commit, clean status, both handoff gate results, final bundle and exact
remote readback after publication. Verify that receipt/remote ref before consuming
the handoff. This does not claim `ticket_acceptance`, `ticket_close`, new device
acceptance, production promotion or integration of Codex's unfinished Store work.

Cursor is parked pending Codex's new full integrated baseline requested above.

## Reopened ticket: CURSOR-BUY-COMPARE-SHEET-REGRESSION-20260922

Status: **OPEN — previously implemented behavior reported regressed by founder**.
Registered after the original eleven-ticket cutoff and Git handoff. This is a
separate follow-up, not a claim that the prior eleven-ticket batch fixes it.
Founder instruction: "register ticket - earlier this was implemented".
The earlier implementation is founder-reported; its exact commit and where the
behavior was lost must be traced before repair. Do not label this a new feature
or assert an integration-loss cause without that evidence.

Actor/outcome: a public Buy/Wholesale shopper opens Product details -> Compare
prices and sees a compact, readable comparison state with an accessible retry.
Classification: mvp_supporting; restore the previously requested compact Buy UI.
Current authorization is registration only; no implementation or APK in this turn.

Observed on Redmi at 16:50:23 local, 22 September 2026:

- Installed app: `1.0.0-r66.32-cursorreview`, version code `2026092201`.
- Product: Stone-ground wheat atta, Case of 10 x 5 kg; Compare prices is open.
- Supplier prices are unavailable; the retry action is visible, followed by a
  very large unused white area. The sheet does not shrink to the short content.
- The parked source also retains `FractionallySizedBox(heightFactor: .88)` in
  `_showBuyV2ProductComparison`, `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`.
  This is the observed sizing cause; earlier-fix provenance remains to be traced.
- Screenshot: `C:/GUARANTEED OUTCOME/outputs/redmi-current-screen-20260922-165023/current-screen.png`.
  SHA-256: `ed38f866139ea95c5db17f441b30c9db4d94aacf39171d80941bc4875ad1c604`.
  Adjacent `capture.json` records build, foreground app and assessment. No device
  taps or navigation were performed during the capture.

Expected repair scope: reuse the existing comparison sheet, controller and route.
Size unavailable, empty and loading states to their content with safe viewport
limits. Populated comparison results may grow and scroll. Preserve approved
typography, touch targets, SafeArea, Android navigation clearance and retry.
Find and reconcile the earlier implementation rather than introducing a second
comparison UI. No backend, Store-worktree, policy or unrelated redesign work.

Acceptance and child checks for the implementation ticket:

1. Identify the earlier implementation/acceptance revision and record why the
   current source and installed build do not exhibit it; preserve unrelated work.
2. Cover unavailable/error, loading, empty, short and paged/populated results at
   normal and enlarged text, narrow screens and Android system insets. Short
   states must not reserve an almost-full-screen blank area or clip text/actions.
3. Refresh, dismiss and Back retain the exact originating product, Store, filters
   and Cart. Preserve same-SKU/pack comparison, pagination and eligibility checks.
4. Keep supplier-provider data unavailability as the existing separate dependency.
   The layout repair must be testable without live data and must not invent offers
   or prices, turn a failed request into success, or mark provider completion closed.
5. Run focused local layout/navigation tests; inspect children; replay on the next
   authorized Redmi candidate together with the existing eleven-ticket/backend
   obligations. Do not mark this reopened defect closed from registration alone.

Handoff addition for Codex: carry this OPEN regression and its screenshot into
the new integrated baseline/backlog. The app source, existing local test results
and deferred provider/Redmi obligations are unchanged by this registration.

## Authorized follow-up: product controls and truthful Delivery rail

22 September 2026: founder explicitly reopens Buy-only frontend work for the
three defects below after parking. Actor/outcome: a shopper can change quantity,
reach the same Cart while scrolling product details, and see Delivery only for
current confirmed delivery records. Classification: mvp_supporting; repair existing
commerce controls. Reuse screen, views, session and existing focused tests. No new
screen, backend, Store, Counter Sale, CSV, routing, policy or APK work. The separate
Compare-sheet ticket above remains registered, not implicitly implemented here.

Evidence directory: `C:/GUARANTEED OUTCOME/outputs/buy-controls-regressions-20260922-170230`.
Initial Redmi screenshot `001-current-screen.png`, SHA-256
`af7e3692dcb32ae2b8c309fb3913b94dd55a0ab3670e10c076a8c9d9911d87d5`.
Installed r66.32/2026092201; starting source
`fd87c94eff19c8c741624d20b2cf22790f9aab63`. Screenshots 002/003 record scrolling
and the Delivery panel; existing device Cart/orders were not erased.

| Ticket | Observed defect and intended correction | Status |
| --- | --- | --- |
| CURSOR-BUY-QUANTITY-WIDTH-20260922 | Wholesale product `− quantity +` spans the entire screen. Repaired with intrinsic width, readable quantity, 44px targets and existing MOQ/stock/amount behavior. | LOCALLY IMPLEMENTED AND TESTED; Redmi replay pending |
| CURSOR-BUY-DELIVERY-PROVENANCE-20260922 | Main rail shows 9+; panel exposes 12 retained review orders including seed MS-240782. Active delivery now requires current provider confirmation or a fresh completed placement; history is retained. | LOCALLY IMPLEMENTED AND TESTED; Redmi replay pending |
| CURSOR-BUY-CART-SCROLL-STABILITY-20260922 | Product scrolling moves Cart between floating summary and rail. Shop/Wholesale details now keep one fixed Cart target in the bottom rail with basket and return state preserved. | LOCALLY IMPLEMENTED AND TESTED; Redmi replay pending |

Exact implementation owners: `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`,
`buy_v2_screen.dart`, `apps/mobile/lib/features/buy/buy_v2_session.dart` and
existing `buy_v2_post_redmi_fixes_test.dart` / `buy_v2_session_test.dart` plus
affected focused Buy tests if a fixture requires a current placed/provider order.
No shared model or provider schema change is proposed. Eligibility, auth and
live order/payment completion still use the existing contract and dependencies.

Local acceptance: normal/enlarged text, narrow portrait and short landscape;
compact stepper plus/minus/edit/MOQ; stable Cart at top/middle/bottom and Back from
Cart; no badge for no orders, samples, cached-only, completed, Care or pickup;
badge for freshly confirmed/provider-active delivery; provider refresh/expiry of
retained records; existing delivery and cart regression. Capture actual local
screens. New fixes require the next authorized Redmi build for device closure.

Local results and child inspection:

- Ten focused new checks pass, including 320/360/390px portrait, 800x360 landscape,
  100/140/200% text, Android insets, stepper plus/minus/edit, MOQ, Cart top/middle/
  bottom, correct basket and exact product/scroll return. Retained-only orders
  remain history; ready provider confirmation activates Delivery and an empty
  current provider response removes it. New explicit review placement activates
  its own record without activating the inherited samples.
- Initial five-file regression: 725 passed / 53 failed. Investigation found
  38 tracking-double failures (the double declared current order/quick state but
  not the new current-delivery list), 10 comparison/Cart fixture failures (missing
  explicit eligibility prevented Add) and five existing active-delivery image
  fixtures. Focused rerun: 57/57 passed. The final Cart/comparison/reference rerun
  after adding explicit successful-Add assertions: 17/17 passed. No test was
  skipped, no assertion removed and no protected reference image updated.
- Tracking doubles now explicitly declare current deliveries. The existing five
  golden cases explicitly exercise their two-active-delivery fixture, preserving
  the approved images. Separate new real-session tests prove samples alone do
  not activate the rail. The comparison fixture supplies versioned, time/location-
  bound eligibility instead of depending on absent provider data.
- Child found in visual review: enlarged Cart count covered the cart glyph.
  Badge text is bounded at 130% while the full count/total remains accessible.
  All ten new checks and four native Flutter captures were repeated afterwards.
- Analysis of all seven changed Dart owners: exit 0; zero errors/warnings and
  eight existing style information items. No live provider or payment completion
  is claimed. This was a frontend presentation/provenance defect, not proof that
  the backend had an active delivery.
- Logs: `regression-r1.log`, `regression-fixtures-r2.log`,
  `cart-fixtures-final.log`, `controls-captures-final.log`, `analysis-r2.log` in
  the evidence directory. Final images: `local-captures-final/`. The initial
  20 generated failure images and their earlier tracked bytes were archived and
  hash-verified before restoring only those generated owners to exact HEAD bytes;
  `reference-evidence-preservation.json` records this. Nothing was deleted.

Stop boundary: no new APK, backend work or implementation of the OPEN
registered tickets (Compare-sheet height, search Delivery fleet and compact
order/invoice actions, Medicine promotions, cross-Buy Cart movement, and product
information organization, category/search consistency, and the current-location
Shopping area popup). All earlier
eleven-ticket device/provider obligations continue. Carry these three repairs
into the integrated baseline and replay them on the next authorized Redmi APK.

### Registration only: Delivery fleet appears in Buy search

`CURSOR-BUY-SEARCH-DELIVERY-FLEET-20260922` — OPEN, not implemented.
Founder supplied this fourth defect during the three-control repair, then
explicitly limited subsequent inputs to registration. Finish only the three
already-started implementations and their local tests; stop afterwards.

Current Redmi capture `004-buy-search-delivery-fleet.png` in the evidence
directory above shows the expanded Buy search, keyboard and a truck/9+ delivery
control next to the search completion tick. Screenshot SHA-256:
`22a849bb4071ac832d8cfe1629f5f9746768907985c9003a4d08c27a35a62a6d`.
Installed build remains r66.32/2026092201. No navigation was used for this capture.

Expected: no delivery fleet/tracking control or expanded tracking panel anywhere
in the Buy search surface, even when genuine deliveries are active. Preserve
the active order and its tracking outside search. Reuse existing search state
and delivery presentation; no backend or provider change is implied. Future
acceptance must exercise active/no-active delivery, expanded/collapsed tracking,
keyboard shown/hidden, query entry/results, search exit and product/Back return.
The existing keyboard header `trailingAction` calls `_buildDeliveryControl`;
this is the source lead for the future implementation, not a completed fix.

### Registration only: compact order management and invoice actions

`CURSOR-BUY-ORDER-INVOICE-ACTIONS-20260922` — OPEN, not implemented.
Founder reports excessive screen use by Manage order / View invoice and asks
for a decision that preserves Codex's newer invoice/consumer Downloads work.
Current Redmi screenshot `005-offers-order-invoice-actions.png` shows order
tracking with **Orders** selected in the bottom rail (the request called it
Offers). Two large full-width outlined actions are stacked below Address,
Items and Help. SHA-256:
`fc2016ef39b6c81ed3d8d2674cbe3a4861ee8119be3d83559a6545ef48cc8dfe`.
Installed r66.32 remains unchanged; capture used no navigation.

Founder agreed to this design decision (Annotation 1); implementation remains
unauthorized under the explicit registration-only instruction. Retain a compact
**Invoice** action for this exact order, alongside **Manage order** in the
existing lower action area. Use one compact icon/text row where space permits,
with accessible wrapping at enlarged text; preserve at least 44px tap targets.
No new top tabs, oversized full-width cards or second invoice implementation.
Consumer-profile Downloads should remain the central document list. The
contextual action must open the same authoritative invoice/download flow by
order ID, not require searching the full Downloads list for a known order.

Source lead: tracking actions in `buy_v2_views.dart`, keys
`buy-tracking-manage-order-<id>` / `buy-tracking-invoice-<id>` and existing
`_openOrderInvoice`. Retain Manage order eligibility, return/replace/refund,
support and correct Back navigation. Preserve honest invoice-pending/error
states. Inspect the other View invoice/Manage order placements for the same
layout issue when this ticket is authorized; avoid unrelated redesign.

Dependency: verify the exact Codex invoice-format and consumer Downloads source
revision at integration before wiring it. The latest Codex implementation is
reported by the founder, not verified as present in this installed APK or Cursor
baseline. Do not fork its invoice renderer or modify Codex's checkout.
Future checks: same-order invoice identity, visibility by availability/permission,
view/download success/failure/retry, pending invoice, active/delivered order
actions, normal/large text, Android insets and retained scroll/Back context.
Standing instruction remains registration only; no application change for this
ticket was made during the current three-defect repair.

### Follow-up source parking and Codex handoff

Exact application commit: `d9ec753b6c2f1dae9a7f9689ac6e1303b80353db`,
subject `ui(buy-ready-20260921): repair product controls and delivery provenance`.
It directly follows the Compare registration checkpoint
`fd87c94eff19c8c741624d20b2cf22790f9aab63`. All earlier parked/inherited source
checkpoints remain ancestors; no prior commit was rewritten or omitted.
The seven tested Dart owner blobs exactly match the committed source manifest.
No Store, Counter Sale, CSV, shared model/schema, native, backend, dependency or
policy owner changed in this follow-up. The ninth changed file is the existing
evidence ZIP; the eighth is this handoff.

`CURSOR-BUY-INTEGRATION-EVIDENCE-20260922.zip` retains all 63 earlier entries
byte-for-byte and adds the new captures, failed/passing logs, preservation record,
and `product-controls-followup-20260922/followup-manifest.json`. Archive SHA-256:
`247e99e235c7a88cb52c9c78d27735e400ee1b73163807cf7c2e79a36f898980`.
The later invoice registration screenshot and agreed decision have their own
`registration-addendum.json` entry. The original inventory's ZIP fingerprint
continues to identify its original commit, not this extended archive.

Codex: integrate through this latest application commit with the full earlier
history. Carry the OPEN registration-only tickets below and all pending eleven-
ticket/provider/next-Redmi obligations. Return an exact integrated baseline SHA
before Cursor begins the separately authorized backend phase. Latest source
eligibility fields/schema are unchanged; delivery provenance is internal session
state populated through existing current snapshots, order refresh and placement.
No new provider API is requested by these three frontend repairs.

This final metadata commit contains no additional runtime changes. Local receipt
`source-checkpoint.json` binds the tested source; `parking-verification.json` in
the same evidence directory records final clean Git, handoff gate results,
exact remote readback and incremental recovery bundle after the metadata commit.

### Registration only: remove deferred Medicine promotions from public Buy

`CURSOR-BUY-MVP-MEDICINE-PROMO-20260922` — OPEN, reproduced on Redmi.
No implementation started.
Founder requests removal of lower Medicine promotion tiles, or replacement with
a relevant consumer promotion, consistent with the launch scope.

Verified authority: central production `AGENTS.md`, Git commit
`745664fcfe0bdd9049065d7eb0644425462bcfe6`
(`docs(launch-scope): record bounded Buy Store and shared delivery launch`),
20 September decision. Buy, Retailer/Grocery Store and the supporting Bulk/Biker
delivery workspaces are included; Care/Medicine transactional exposure is
deferred and its source/evidence must be preserved. This ticket removes public
promotion/entry affordances; it does not delete the deferred module or rewrite
the launch decision. Broader route/backend exposure controls remain their own
existing launch obligation.

Design decision: remove these lower Medicine promotions and collapse the vacated
space. Do not invent replacement offers or add a new promotional subsystem.
Only reuse an already-wired, launch-relevant consumer Buy/Store promotion if its
content and availability are verified. Preserve products, store navigation,
scroll continuity, Android clearance and brand styling.

Capture attempt after power/network recovery: `006-medicine-promotion.png`
actually shows Android Home, not the reported promotion. SHA-256
`36df3ac3b757eb81910e7c929bd22bd77e5fd88bda2afe25b7a20a4a7d242de5`.
One tap on the visible Cursor Review launcher icon resumed a noodles product
detail screen; `007-review-app-after-resume.png`, SHA-256
`c635b7173a3d06b0a5600590d1ca54df05c0ed1bacde8c74b2eb408805a51d57`.
Neither image proves the Medicine promotion. Founder has been asked to display
the exact screen. Do not mislabel these captures as a reproduced defect.

Founder subsequently displayed the target and requested capture (Annotation 1).
`008-medicine-promotion-target.png` now proves the lower **Medicine and Wellness**
promotion, subtitle **Browse the licensed pharmacy catalogue**, next to another
promotion beneath the SKU grid. Orders is selected and the header reads Search
orders or ID; preserve this observed context without inferring its full entry
journey. Capture used no taps or navigation. SHA-256:
`3527bc6892cc8d2a29069f8ae21a4a78b3ed829289ffafaa602b8ace72724de8`.
This is the target defect evidence; earlier 006/007 remain labelled capture
attempts only. Requested disposition remains remove the Medicine promotion and
collapse the space, without a speculative replacement or module deletion.
The exact subtitle is present in `buy_v2_views.dart` in the lower promotion
owner. The existing evidence ZIP now additionally preserves capture 008 and
`medicine-promotion-confirmed.json`; its extended SHA-256 is
`b1730d10bf1cb7ae2a8234bf31975e4a730a3def7c8fc63543da202820bc4b50`.
The earlier ZIP fingerprint above remains the fingerprint at source commit d9ec753b.

Future acceptance: identify the exact lower promotion owner from the target
screen, remove its deferred Medicine call to action without an empty spacer,
check normal/enlarged text and narrow/landscape layouts, and verify existing
consumer Buy/Store actions and scroll/Back behavior. Retain registration-only
status until the founder separately authorizes implementation.

### Registration only: predictable Cart position across the full Buy module

`CURSOR-BUY-CART-POSITION-ALL-SURFACES-20260922` — OPEN, founder-reported.
Founder reports that the moving Cart is not controllable. Proposed choices are
(A) a fixed position or (B) a fixed default position with movement only when the
customer explicitly drags it. Coverage must include Buy/Shop, Wholesale, Offers
and Orders rather than only one product page.

Recommended design: option A, one fixed Cart position in the existing lower
navigation/action area wherever a Cart entry is appropriate. Eliminate automatic
floating/repositioning while scrolling, changing content or opening overlays.
Reuse the existing Cart target and scope resolution; do not introduce another
Cart or a new gesture/state subsystem. No implementation of this new ticket is
authorized under the standing registration-only instruction. Option B is a
recorded alternative, not permission to add draggable behavior by default.

Relationship to the completed three-defect batch: source commit d9ec753b fixes
the Cart position on Shop/Wholesale product details, with local top/middle/bottom
and return tests. It intentionally leaves catalogue dragging/avoidance intact.
That narrower repair does not close this wider ticket, and the installed Redmi
r66.32 does not contain it. Do not count an older installed observation as proof
that the parked source fix regressed.

Future audit/acceptance: catalogue, category/filter/search and results, Saved,
Visit Store, product details, Offers, Orders and nested order/product return;
Shop/Wholesale and aggregate Cart scope; empty/single/mixed baskets and quantity
changes; active/no-active Delivery; scroll top/middle/bottom, keyboard, overlays,
orientation, enlarged text and Android insets. The Cart must remain reachable,
must not obscure SKU actions, and must preserve basket, scroll and Back context.
Inspect Cart/checkout's own actions for duplicates without adding a floating Cart
to screens that already own the Cart journey. Verify no hidden auto-drag or
reposition callbacks keep moving the control after the fixed design is applied.
Register any uncovered child issue; preserve routing, amounts and checkout wiring.

### Registration only: compact, organized public product information

`CURSOR-BUY-PRODUCT-INFORMATION-REDESIGN-20260922` — OPEN, founder-reported;
registration only. No application implementation or new APK authorized by this
entry. Actor/outcome: a consumer opening an SKU from Shop, Wholesale or Visit
Store can quickly understand the product, price/pack and applicable purchase
terms using only information intended for that public audience. Classification:
mvp_supporting; improve the existing product-information journey.

Founder requirements (a–i), retained in full:

1. Categorize and reorder all text into a clear hierarchy: product identity and
   selected variant; price/pack/quantity; key product facts/specifications; relevant
   fulfilment and purchase terms; concise seller identity and Store access.
   Use existing public fields and condition sections on the actual product data.
2. Highlight decision-critical information with restrained typography and accent
   treatment. Avoid making every label equally prominent or relying on colour
   alone to express availability or other meaningful state.
3. Remove exact repetition and repeated meaning across titles, badges, facts,
   descriptions and terms. Preserve distinct facts: pack price versus unit price,
   MOQ versus pack size or quantity tiers, variant identity and required terms
   must not be mistaken for duplicates. Do not rewrite provider facts inaccurately.
4. Use compact, subtle label/value rows or a responsive tabular arrangement.
   Adapt to short/long provider text, missing optional fields, number of facts and
   available width. Allow useful wrapping/expansion without clipping information,
   oversized blank rows, tiny text or forced equal-height empty sections.
5. Repair the **+ Add** action's largely empty full-width lane. Place the existing
   Add/quantity control compactly with the purchase summary where appropriate;
   retain accessible tap targets, prices/totals, stock/MOQ validation and Cart
   updates. The earlier compact-stepper repair does not close this Add-lane issue.
6. Make the complete page compact, professional and premium, including spacing,
   information density, alignment and the relationship between image and text.
   Keep important purchase information and actions easy to find.
7. Polish text colours, surfaces and gradients within the approved MoolSocial
   brand. Use light/ restrained accents; do not clutter the page with large solid
   colour blocks or a collection of competing highlighted cards.
8. Apply the same information organization wherever this product page is wired:
   Shop/Buy, Wholesale, public Store/supplier pages, search, categories/filters,
   Saved, Offers and existing related/compared/order-to-product entry paths.
   Retain the correct Store/SKU/variant and channel-specific meaning on each path.
   Do not activate deferred Medicine/Care or add new journeys to obtain coverage.
9. Add, remove, retain or relocate information between product and Store pages
   according to its purpose. Keep product-specific facts and relevant purchase
   terms on the product page; centralize general Store information on its existing
   page with concise context/link here. Preserve access to all applicable public
   information supplied by Store instead of deleting it solely to save space.

Data boundary: use the existing Store-to-public mapping and provider contracts.
Only publish fields explicitly intended for the consumer/current permitted
channel; never dump the Store record or expose private stock operations, internal
notes, purchasing costs or account data. Preserve authoritative field values and
their SKU/variant/Store identity. Do not invent information to fill a section.
Omit empty optional presentation; keep honest unavailable/loading/error states
and existing ordering restrictions for missing critical data. Any missing shared
public field requires coordination with Codex, not an unrelated Store-worktree
edit, parallel backend or invented Buy-only fixture contract.

Reuse assessment: existing `BuyV2ProductView`, purchase-action/quantity owners in
`apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`, product-entry/return wiring in
`buy_v2_screen.dart`, and existing public product content/facts/session contracts.
Reuse public Store pages for Store-level information. No separate product screen,
new navigation framework, backend, shared-schema edit or policy work is included.
Record the precise implementation owners and public-field mapping before a future
authorized implementation. Current registration changes only this MD.

Acceptance for that future implementation: normal/large text and narrow/landscape
screens; short/long product, variant and Store names; dense and sparse public
metadata; long prices, units, descriptions and terms; genuine missing provider
data; image fit; contrast/brand consistency; Android/keyboard clearance; compact
Add, quantity editing and totals; correct selected variant, basket, checkout,
originating Store/filter/search and scroll/Back return. Review every existing
entry path for duplicate meaning, blank lanes and inconsistent presentation.
Take actual local screens for visual approval, run focused interaction/regression
tests, register child defects and retain next-Redmi replay as separate acceptance.
Coordinate with the OPEN cross-Buy Cart-position ticket so the redesigned page
does not reintroduce moving Cart or obstruct its product actions.

### Registration only: category presentation, inline search and thumbnails

`CURSOR-BUY-CATEGORY-SEARCH-CONSISTENCY-20260922` — OPEN, founder-reported;
registration only. No application implementation or APK authorized by this entry.
Actor/outcome: a consumer can browse the appropriate category set and search
within Shop, Wholesale or the selected public Store using consistent controls.
Classification: mvp_supporting; presentation and interaction consistency in
existing public catalogue journeys. Store's category-layout mismatch is reported,
not newly reproduced or independently tested during this registration.

Founder requirements:

1. **Separate categories, shared presentation.** Shop, Wholesale and each Store
   retain their own purpose-specific category data, selections and product scope.
   Use the same full-page category picker/pop-up design across all three, including
   title/close controls, typography, spacing, selection treatment, image placement,
   scrolling and Android clearance. A common layout must not merge category sets
   or inject general-home categories/SKUs into a Store. Reuse the existing approved
   category presentation rather than developing three independent screens.
2. **Unboxed, expanding search.** Make the Shop, Wholesale and public Store search
   bars inline/unboxed and expand inline when tapped, matching the Buy-home search
   interaction and visual treatment. Preserve focus/keyboard, clear and finish/
   collapse actions, Android Back, recent/query state and result selection. Store
   search stays within that exact Store; Wholesale and Shop retain their respective
   channel/category/filter context. Returning from a product restores the source
   search, query, selection and scroll position. Do not replace expansion with a
   permanently boxed field, separate new search route or unrelated search service.
3. **Small category photo thumbnails everywhere.** Add compact square photos to
   public category entries wherever those categories appear across Shop, Wholesale
   and Store. Follow the SKU photo-square treatment with a visibly smaller category
   thumbnail, consistent fit/corner treatment and alignment. Keep category labels
   readable and the overall selection target accessible; image size must not force
   tiny tap targets or oversized rows. Use existing public category imagery/mapping,
   with a compact honest fallback for missing/failed images. Do not arbitrarily
   substitute unrelated SKU photos, invent provider content or build a separate
   category taxonomy. Coordinate any genuinely missing shared image field with
   Codex before changing a contract; no Store-worktree edit is included here.

Reuse/relationship: inspect existing category and Store catalogue presentation in
`apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`, search presentation in
`buy_v2_screen.dart`, existing sheets in `buy_v2_views.dart`, and current session
category/search state. Exact owners must be confirmed before future implementation.
RB007 already implements Store search expansion in the earlier local cutoff;
compare its exact source and current route against installed r66.32 first. Carry
forward that work and repair uncovered presentation/entry cases instead of
reimplementing it or claiming a pre-existing fix failed solely from an older APK.
The OPEN search Delivery-fleet ticket remains separate and must not be lost.

Future acceptance: visual parity of the full-page category picker in all three
contexts; distinct category identities and correct scoped results; short/long
labels and sparse/large category lists; thumbnails loaded/loading/missing/broken;
normal/enlarged text, narrow portrait and landscape; keyboard and Android system
insets; search open/type/clear/finish/Back/product-return; selected category/filter
and pagination retained; stale requests after Store/filter/location changes must
not replace current results. Confirm no horizontal clipping, oversized blank
areas, accidental global Store search or deferred Medicine exposure. Reuse current
navigation/providers, preserve Cart and checkout state, capture actual local
screens and inspect child defects when implementation is separately authorized.

### Registration only: compact Shopping area popup with current-location map

`CURSOR-BUY-SHOPPING-AREA-CURRENT-LOCATION-20260922` — OPEN;
registration only under the standing instruction. No application change or APK.
Founder clarifies that the top location icon represents the customer's current
shopping location. Replace the existing Shopping area popup content and manual
area-choice screen with a compact Google Map/pin popup that automatically centers
on where the customer is presently located when opened.

Actor/outcome: a consumer can establish the current shopping location directly
from the top location control without selecting a predefined area list.
Classification: mvp_supporting; location selection supports the existing scoped
catalogue and fulfilment eligibility. The requested design replaces the current
popup; do not layer a second manual-area interface beside it.

Future implementation requirements:

1. Reuse the top location entry and existing shopping-location state. Show a
   compact map with a clearly visible current-location pin, concise resolved
   location label if available, and minimal apply/close controls. Automatically
   request a fresh foreground position when opened with permission, then center
   the map. Do not require typing or choosing an area before showing the location.
2. Respect the OS foreground-location permission flow. Explain loading, denied
   permission, disabled location services, timeout, approximate/low-accuracy
   position and map/network failure truthfully, with a suitable retry/settings
   action. Do not claim an old saved address, default city or invented coordinate
   is the customer's present position. Do not introduce background tracking.
3. On applying a valid location, reuse the existing catalogue-area/provider
   mapping and location-bound eligibility refresh. Prevent stale location or
   search responses from replacing newer results; preserve pagination rules and
   Store/channel scope. A map pin alone does not prove delivery serviceability,
   Store readiness or fleet availability.
4. Keep this browsing location distinct from a Store's physical address, a
   Google Maps route to the Store and the customer's confirmed checkout delivery
   address. Do not silently overwrite checkout addresses or an existing order.
   Dismiss/Back without applying must preserve the prior selected shopping area.
5. Remove the old manual-area content from this entry and reclaim blank space.
   Use compact brand-consistent styling, a useful map viewport and accessible
   controls. Do not add extra tabs, decorative panels or a large empty sheet.
6. Explicitly verify keyboard and Android-hidden-content defects after the
   future implementation. Opening from focused search must handle its keyboard;
   map, pin, close and apply controls must remain reachable above keyboard/system
   navigation insets. Test Android Back, permission/settings return, repeated
   open/close, narrow/short screens, landscape and enlarged text. Do not treat
   keyboard absence in the default map state as sufficient coverage.

Reuse/dependencies: inspect `showBuyV2CatalogueArea`, the top location handler in
`buy_v2_screen.dart`, current location/map adapters and the shopping-area source
in `buy_v2_session.dart`. Confirm the existing Google Maps/current-position
capability before implementation; actual GPS, permission, map credentials and
location-to-catalogue mapping must work for runtime acceptance. If a capability
or shared contract is missing, register and coordinate that exact dependency
instead of substituting a screenshot/sample pin or claiming live integration.
No native configuration, new dependency, backend, Store-worktree or policy change
is performed or implicitly authorized by this registration.

Future evidence: real current-location centering on Redmi with permission,
denied/offline/services-disabled recovery, fresh versus stale position, apply
and cancel behavior, correctly refreshed scoped catalogue/eligibility, preserved
Cart/checkout state, and local keyboard/inset/layout/navigation tests. Inspect
and register child defects; visual approval is separate from technical/device
acceptance. Existing manual-area behavior remains installed until this ticket
receives implementation authorization and a later authorized APK is qualified.


### Founder additions during the eight-ticket implementation — 22 September 2026
- CHILD-7-STORE-SEARCH-EXPANSION: Visit Store search must expand horizontally when focused/typing, not merely hide its toolbar. Hide the redundant outside close/info chrome while typing, keep an inline Back action, preserve query and Store scope; verify keyboard and Android Back.
- CHILD-7-WHOLESALE-STOREFRONT: Wholesale Visit Store still takes the legacy supplier-preview branch even with a paged Store provider. Use the same Store catalogue and home-style SKU tiles for both public channels; preserve Wholesale prices, MOQ, filtering, save, product navigation and scoped Cart. No Store-provider or Codex-worktree edits.
Both are authorized additions to the current frontend/local-test batch; integration and APK remain postponed.

Founder clarification (Annotation 1): CHILD-7-STORE-SEARCH-EXPANSION applies to every applicable newly implemented public Store entry in Buy/Shop and Wholesale, including alternate full-catalogue routes. Verify focus, typed query, clear, finish, keyboard dismissal and back navigation with exact Store/channel scope; do not limit the fix to a single entry screen.

Founder visual refinement: category popup header must be thinner so categories start higher; support dragging upward to full screen. Applied to the shared Shop, Wholesale and Store picker, preserving safe insets, scroll and category scope.

### Local implementation checks and child findings (in progress)
- CHILD-7-SAVED-SEARCH-BACK: Saved-at-Store branch omitted the normal search PopScope; Android Back could dismiss the Store instead of finish search. Fixed in the shared saved branch; targeted regression pending.
- CHILD-7-CATEGORY-KEYBOARD: shared category grid needs explicit keyboard clearance after draggable expansion. Added bottom clearance and focus-to-full-height; keyboard/large-text verification pending.
- Visual review: duplicated product rating/return summary, fallback pack facts and empty benefit panel took unnecessary space. Removed only already-present fallback/identical summary content; explicit manufacturer, quantity, legal/public metadata and failure/retry remain.
- Preserved failed local evidence: store-r1 exposed an incorrect Wholesale test selector (supplier-action vs actual store-action); focused-r3 caught a duplicate modal argument inserted into the wrong similarly named helper and was corrected; focused-r4 invoice test used a historical seed with no order lines and the wrong page key. The corrected test uses an actual locally confirmed review order with line records and the existing invoice-page identity. No runtime invoice guard was weakened.
- Focused-r2: 11 tests passed before subsequent visual refinements. This is intermediate evidence, not final acceptance.

CHILD-6-ADD-LANE: final screenshot showed compact Add still in a mostly blank hero row. Move the existing Shop Add/quantity control beside the price when width/text size allows, with wrapping at large text. Existing eligibility and cart callbacks remain authoritative; Wholesale retains its dedicated compact trade dock.

CHILD-TEST-CHECKOUT-DELIVERY-FIXTURE: broader run passed 119 functional checks and failed five immutable checkout images. Visual comparison identifies the inherited inactive-seed Delivery rail change, not a Cart/check-out defect from this batch. The protected fixture now explicitly provides its two current deliveries, following the existing scoped-Cart reference-fixture pattern; ordinary sessions and provenance guards are unchanged. Twenty generated diagnostic images were hash-preserved externally before restoring exact pre-run tracked evidence. Original golden images are unchanged. Exact pass/fail logs remain retained.

CHILD-TEST-WHOLESALE-ROUTE: two RV6 assertions still expected the superseded supplier preview underneath the full Store. Updated the expected Back destination to the direct Store route used by both channels, retaining quantity, Store scope, empty-cart and destination-change assertions. Fresh-source behavior passed through the journey before the outdated final route assertion.


## Eight-ticket frontend batch — local review checkpoint

Latest implementation supersedes historical OPEN/registration-only labels for this batch. Founder visual approval, integration and fresh-device acceptance are still pending; no APK or backend work was performed.

| Ticket | Local disposition |
| --- | --- |
| Compare sheet regression | Content-sized short/error sheet, capped and scrollable for populated results; unavailable and populated/nested-return checks pass. |
| Delivery fleet in search | Hidden throughout public search even with a current delivery; restores after search without losing order state. |
| Order/invoice actions | Compact wrapping inline actions with 44px targets; exact-order invoice and resolution routes verified. Existing invoice implementation reused. |
| Medicine promotion | Removed only the deferred Medicine card from public Orders continuation; relevant Shop/Wholesale cards remain. |
| Cart position | Fixed rail Cart on public catalogue/product/Orders/Offers paths; scope, quantity, product return, large text and landscape continuity verified. |
| Product information | Larger readable adaptive fact rows; conservative duplicate/empty-content removal; explicit public compliance retained; compact Add beside price where it fits; Wholesale trade dock preserved. |
| Categories/search consistency | Shared thumbnail grid and thin draggable popup across Shop/Wholesale/Store; drag to full height, keyboard clearance, independent selection; Store search expands horizontally on focus, including saved mode. Wholesale paged Visit Store now uses the same home-style SKU tiles. |
| Shopping location | Compact automatic locate/retry/confirm UI through existing provider interface; selected place opens its Google Maps pin externally. Manual area lists removed. Live current location and embedded Google Map remain dependent on CHILD-8-MAP-PROVIDER; do not close live-map acceptance. |

### Child inspection and validation

In-scope children resolved and retested: saved-Store search Back, category keyboard clearance, Wholesale route parity, Store search width, thin/draggable category header, product Add empty lane, repeated/fallback product facts, and explicit historical reference fixture state. No remaining observed frontend child failure in the exercised checks. This does not claim exhaustive Buy/backend/device acceptance.

- `focused-r5.log`: 13/13 focused checks passed before the final Add-lane refinement.
- `regression-r1.log`: 119 functional checks passed; five inherited active-delivery reference fixture failures subsequently corrected without changing any reference images.
- `store-regression-r1.log`: 18 passed; two assertions still expected the removed Wholesale preview route. Corrected only that expected destination and retested all four affected RV6 journeys.
- `final-validation-r1.log`: **38/38 passed** on final runtime source, covering two root category journeys, 13 targeted cases, 10 product-control checks, four RV6 Store continuation cases, four populated Compare/Offers returns, and five unchanged checkout image comparisons.
- `analyze-final.log`: seven changed Dart source/test owners, **no issues**.
- `git diff --check`: passed. Historical reference files unchanged; 20 generated failure diagnostics preserved with hashes before exact pre-test restoration.

Actual local review screens and every failed/passing log are in:
`C:/GUARANTEED OUTCOME/outputs/buy-eight-ticket-local-review-20260922`.
`review.html` links the final unedited Flutter renders. `captures-final` includes normal/200% text, Store/Wholesale parity, expanded search, category keyboard and drag behavior, product/Cart, order/invoice, comparison and provider-failure states. Test catalogue artwork is explicitly labelled Illustration; fixture data is not a production Store handoff or live location proof.

No shared model/schema, Store, Counter Sale, CSV, native/dependency, backend or policy owner changed. Retain all prior integration ancestry and pending next-Redmi obligations. Codex integration remains postponed; request/verify its exact new baseline before backend work starts.

### Source parked safely; integration postponed

Application commit: **`f4d2e116bb1a42f10d588ac82e36cd23065d6523`**, directly after the clean registration checkpoint `757640edd252f61bdd03e3c05d43bf56b525834a`. All seven changed Dart owners match the tested files and committed normalized blobs. Earlier source and integration checkpoints remain ancestors. Nine changed owners: four Buy UI, three focused tests, this handoff and its existing evidence ZIP.

The source commit is pushed to `origin/work/cursor-ui/buy-ready-20260921`; exact remote readback matched. Pre-commit and clean source handoff checks passed. The incremental handoff initially rejected the staged tree, as designed; rerunning after the commit passed with no control changes. No governance/policy file was edited. Historical r66.32 gate arguments do not authorize a new APK or qualify these changes for device release.

The evidence ZIP retains all 93 pre-batch entries byte-for-byte and adds final screenshots, test logs including failures, diagnostic preservation, source fingerprints and source parking receipts. Final archive SHA-256: `e0ac969d3e12302aaa39e782c3bf0cf2137f42890f77fbe799ae4a6e425072b2`.

Founder review is pending. CHILD-8-MAP-PROVIDER remains an integration prerequisite for real auto-location and an embedded Google Map. Permission/offline/retry/late-result behavior was tested through the existing interface with labelled local fixtures. Do not claim live GPS or complete Store backend acceptance. Preserve the previously recorded next-Redmi replay obligations alongside this batch; no APK was made.

Final metadata parking receipts and incremental recovery bundle will be in the same local evidence directory. Codex should eventually integrate this complete branch, then return its exact new baseline before backend development begins; integration remains postponed now.


### Founder rejection — product information remains scattered

The founder rejected the product information arrangement in the f4d2e116 local screenshots. Those commits are safely parked technical checkpoints, not approved UI. Continue the same bounded product-information ticket from clean `3d837cb54f50c4dfef7c10b3ee6e680f5b66f453`.

Strengthened acceptance: (1) one product/variant/pack/price/Add group, (2) one explicitly labelled Store identity/status/Visit Store group, (3) one aligned Delivery & returns table with promise, method, address and applicable provider terms, (4) Wholesale-only commercial terms in their own group, and (5) specifications/protection/reviews below. No delivery/return sentences floating in the product hero and repeated in a second card; no generic fulfilment explanation occupying its own row. Preserve distinct pack/unit prices, MOQ/tiers, public compliance, actual provider state and all action callbacks. Readable aligned labels/values must wrap for long content and large text, without distributing words across the screen. Reuse the shared product page across Shop, Wholesale and Store entry paths, locally test and show new actual renders for founder approval. No APK/integration/backend/policy changes.

Implemented review revision: compact price/pack/savings and Add group; Store identity, seller type, operating status, provider location and Visit store together; one aligned Delivery & returns table shared by Shop and Wholesale; Wholesale freight/tax/verification grouped under Wholesale terms. Removed repeated hero delivery/returns and generic fulfilment row. Separate fields retain identical values when their meaning differs; only equivalent dispatch/method/return summaries are deduplicated. Existing public compliance, trade quantities, recovery/navigation and purchase callbacks remain. Wholesale Add minimum height restored to its existing 50-pixel regression requirement (CHILD-PRODUCT-TOUCH-TARGET fixed and retested).

Validation on this revision: 42 selected tests passed in `product-organization-final.log`; the one new long-provider test initially failed because it tried to reveal an unbuilt lazy-list child. Corrected to scroll through the actual list; that test and both original Wholesale touch-target/decision cases passed 3/3 in `product-provider-final.log`. Total 45 distinct passing checks include normal/200% text, long provider terms, same-value/different-label retention, closed Store blocking Add, Store/Wholesale route parity, Cart/search, Compare and five unchanged checkout goldens. Analyzer and whitespace checks passed. Actual unedited Flutter screenshots: `product-organization-final` and `product-provider-final` in the existing local evidence directory. These are local fixture renders, not a Redmi APK or live Store-provider acceptance.

CHILD-PRODUCT-LEGACY-ASSERTIONS remains OPEN: a separate historical four-suite run had 12 passes, one existing skip and 11 failed cases. Two Wholesale touch-target cases now pass after the 50-pixel correction. Nine cases still assert superseded presentation/selectors: Wholesale facts/Seller in the old fulfilment card (2), generic fulfilment prose (1), availability text/delivery inside the hero (1), old Delivery details/List price/Available to add copy (3), old catalogue review-button selector (1), and absence of Visit store (1). Exact failures are preserved in `product-contract-regression-r1.log`. Those four test files are outside the current recorded focused-test owners; they were inspected/run, not edited, and no ownership or policy controls changed. Updated layout, data-retention, Store status and actions are asserted in the already-owned focused test. Reconcile the legacy assertions before full-suite/integration acceptance; do not report the complete historical suite or all child tickets closed. Founder approval of this revised screen remains pending. Safe parking is not integration approval.

### Founder approval and propagation verification — 22 September 2026

Annotation 1: founder approved the product information preview at `0a224e546b7c570cf2ba7772cf25e2c030ffee98` and instructed application across Buy, Store, Wholesale and affected entry points. This supersedes the pending visual-review statement for that product layout only. Same bounded ticket: verify the shared `BuyV2ProductView` in root and nested Store routes, including search/saved/recent entry paths. Add focused route assertions in existing owned tests; preserve channel data, minimum quantities, scoped navigation and Cart. No separate screen, provider/backend/APK/integration or policy changes. Approval is visual acceptance, not complete technical or live-provider acceptance.

Propagation evidence: both root and nested Store routes instantiate the same `BuyV2ProductView` (`buy_v2_screen.dart`); search, saved, recently viewed, comparison and order-item entry paths reach those owners. The approved application source remains exactly `0a224e54`; no separate layout or runtime changes were necessary. Ten route-level checks passed in `approved-propagation-r4.log`: Shop/Wholesale search, saved and recently-viewed product actions (6), and Visit Store product opening/return with scoped search/categories at normal/200% text (4). Correct minimum Add quantities and preserved Store search/category state were checked. Analyzer and whitespace checks passed. The recently-viewed tests invoke the existing sheet entry function, then tap its actual product row; they do not claim that every menu entry was exercised.

Earlier failed propagation attempts are retained: initial test setup remained on the product view, missed settling after scroll, toggled an already-saved fixture, and omitted the Bulk filter for the Wholesale rice fixture. A suspected duplicate seller row was investigated: the Store fixture supplies different public seller names, so its existing information was preserved; no such runtime change was retained. The final run uses actual UI taps and the correct channel/filter preconditions. Screens are in `approved-propagation-r4` under the existing local evidence directory.

An external legacy-test candidate preparation aborted on a replacement-count assertion before writing candidate files. The following empty-directory test attempt unintentionally selected the default suite; its live session was interrupted. Its log is preserved at `legacy-assertion-review/validation-r1.log` and is not qualification evidence. Repository Git status was immediately verified unchanged. Subsequent runs used explicit repository test filenames. The nine historical assertion cases and live-map provider dependency remain open as previously recorded; this propagation verification does not close them. Previous goal turn classification: progress (approved layout propagated by shared ownership and verified with new route evidence).

### Verified legacy assertion patch and bounded-goal audit

The nine historical assertion cases have a concrete test-only reconciliation patch: `legacy-assertion-candidates/legacy-layout-assertions-final.patch` in the local evidence directory and `legacy-assertion-reconciliation/legacy-layout-assertions-final.patch` inside this evidence ZIP. SHA-256 `e686e9db2b96a2449b3b4fe28bce46fe4163493b1c779964b1668ebdd5c9a62e`. It updates only the four previously listed historical test files, preserves business/recovery/Cart/MOQ/compliance assertions, verifies facts in their approved groups, and checks stale products remain unavailable in discovery and cannot bypass the decision through a direct product route. No new skips or golden replacements. `git apply --check` passed against the unchanged originals; the patch is NOT applied.

Four isolated candidate suites passed 23 tests with the one pre-existing capture-only skip (`legacy-assertion-candidates/validation-r2.log`). They used this checkout's exact `test/flutter_test_config.dart`, bundled fonts and original helper imports. The unique external group prefix and absolute imports are harness-only and are excluded from the proposed patch. `verified-patch-manifest-final.json` records original/candidate/proposed hashes and the unchanged application revision. The preliminary external run omitted the repository font loader; its findings are not application defects or acceptance evidence. Preliminary patch files used Windows-translated newlines; only the literal-LF final patch above passed applicability. All attempts are retained as evidence.

| Goal requirement | Current evidence and limits |
| --- | --- |
| Compact Compare | Implemented in shared comparison sheet; short/unavailable and populated navigation cases pass in the saved focused runs. |
| Hide Delivery in search | Root delivery control and restore control are suppressed for active catalogue search; active-order tests cover Shop/Wholesale and retain order state. |
| Compact order/invoice actions | Existing order-specific callbacks are compact actions; saved normal/200% tests verify Manage order and exact invoice identity. |
| Remove Medicine promotion | The out-of-scope Orders continuation promotion was removed; MVP promotion assertions pass. Protected Care/Medicine journeys were not redesigned. |
| Fixed Cart | Public catalogue/product/Offers/Orders use fixed Cart behavior; saved drag, scroll, landscape and large-text checks pass. |
| Organized product information | Application `0a224e54` is founder approved; 45 focused checks, 10 entry-route checks and the 23 candidate legacy checks support the new layout and preserved data/actions. Shared root/nested product owners cover public entry routes; source unchanged at `34e51875`. |
| Scoped categories/search/thumbnails | Shared draggable category design and expanding Store search cover Shop/Wholesale, regular and saved Store paths; normal/200% search, keyboard, scoped query and Back checks pass. |
| Current-location popup | Compact locate/retry/confirm UI exists and simulated-interface failure/late-result checks pass. Full requested live-location/map outcome is NOT complete: no production `BuyV2ShoppingAreaSource` implementation or injection exists in `apps/mobile/lib`; `locateShoppingArea()` fails unavailable without it. The existing contract carries region/Google Place ID/label, not map coordinates. Only the resolved-place external Google Maps link is wired. |
| Screens and safe parking | Actual local Flutter galleries and founder product approval are recorded. Approved source and all earlier history are retained locally/remotely. No APK, backend or integration was performed. |

Remaining blockers are unchanged across the product-review, propagation and this audit: (1) applying the verified four-file test patch requires those exact test owners to be admitted or the owning agent to apply it; the current recorded owners omit them and the repository explicitly prohibits unclaimed edits; (2) live location/Google map needs its real provider, permissions/Place-to-region resolution and approved map integration. The user's prohibition on policy/backend/unrelated work remains in force. No control was weakened or amended. All meaningful work available within the admitted frontend owners is parked; do not claim all eight outcomes technically complete or close the live-map dependency. The goal is ready to be marked blocked on these external prerequisites, not complete.

### Latest founder decision — defer integration dependencies and proceed with frontend

Annotation 1: founder instructed: "mark this backend or google dependencies and move on - we will again do it through google api after front end complets , google api is ready with us".

This supersedes the preceding stop/block disposition for the current frontend batch. Live current-location and map integration is a DEFERRED GOOGLE API / PROVIDER DEPENDENCY, to be resumed after frontend completion. The founder confirms the Google API is ready; no credentials or live API capability were inspected or validated in this work. Preserve `CHILD-8-MAP-PROVIDER` with its existing interface, failure/retry states, exact missing integration and future verification requirements. Do not substitute simulated location for live acceptance or close this deferred dependency as implemented.

The four-file legacy assertion patch is a separate DEFERRED TEST-MAINTENANCE / INTEGRATION HANDOFF item, not a Google/backend defect. Its exact verified patch, fingerprints and 23-pass/one-existing-skip evidence remain preserved; it is still unapplied to the repository originals. Carry it forward for the appropriate file owners before full-suite/integration qualification. It does not block further authorized frontend work under this founder decision. No policy or ownership edits are authorized or needed by this deferral.

Current bounded frontend batch: implemented, locally checked and screens presented; product layout founder-approved and verified across public entry routes. Frontend batch can be closed with these explicit carry-forward dependencies. No live-provider/full-suite/device/integration acceptance is claimed. Preserve the approved application revision `0a224e54`, all prior commits, the next-Redmi testing obligations and the latest evidence archive. Backend/API work and APK remain deferred; integration remains postponed. Continue with founder-authorized frontend scope without repeatedly stopping on these deferred items.

### Next Redmi APK — full ticket and source reconciliation

Bounded actor/outcome: Cursor preserves the complete Buy frontend for a future device-review candidate. Classification: mvp_supporting. Reuse the current worktree/branch, APK source manifest, ticket registers, existing Git checks and handoff/evidence owners. This task inventories and preserves; no feature, backend/API integration, APK build, other-worktree edit or policy change. Reconciliation does not reuse consumed r66.32 build authority or claim new release qualification.

Baseline was verified directly on Redmi `TG8HCYTGGQT885OF`: package `com.moolsocial.app.cursorreview`, version `1.0.0-r66.32-cursorreview`, code `2026092201`. Installed APK SHA-256 equals both the retained local APK and its record: `f74adcd10de5a5dfa3f6a29f024484dcb8caf294fb0682c01680eb7190f2cf8a`. APK Git label is `87bc96d4c28300146c9e2c3c3b37c7c3aacffed0`; its actual 3,233-file source manifest was also verified, SHA-256 `75d1b6f69eee462c70c1205e37011f4f4ee9b461cf006235a50d0a2398dae73d`. Comparing against this manifest prevents counting pre-APK local changes as new work merely because they were committed later.

**22 ticket outcomes since that APK:** the 11 rows in the local cutoff, the three quantity/Delivery-provenance/product-Cart controls, and the eight rows in the latest frontend batch. The exact numbered list and implementation-commit mapping are in `APK-INCLUSION-REPORT.md` and `apk-inclusion-manifest.json` under `C:/GUARANTEED OUTCOME/outputs/buy-next-redmi-reconciliation-20260922`, and under `next-redmi-reconciliation/` in the evidence ZIP. Provider-related tickets count their implemented/verified frontend portion only; live provider completion is not claimed. Later Store search/Wholesale SKU/category/header/product-polish child work is included under these parents, not silently omitted or double-counted.

Preservation results at `5f2b4428`: 16 post-APK work commits, including four runtime-source commits (`a78b1b38`, `d9ec753b`, `f4d2e116`, `0a224e54`); all parents and exact changed-owner lists retained. All 18 required integrated tips plus the previous integration, inherited/assigned checkpoints, prior Cursor tip and APK label remain ancestors. Git connectivity passed. Local branch equals origin; zero staged/unstaged/untracked records. All 3,233 candidate inputs exist, are tracked and match their Git blobs (accounting for Git text line endings); no ignored source/assets under lib/assets. No committed input or required baseline tip is missing.

Relative to the actual APK manifest: 3,215 input files unchanged; 18 changed. Nine are substantive Buy runtime files, eight are focused test files, and the generated Android plugin registrant is line-ending-only (the exact APK hash is reproduced from current bytes using CRLF). Native, Store/Counter Sale, backend, shared packages/contracts and dependency Git trees are unchanged. The evidence archive's 337 pre-reconciliation entries were integrity-checked and preserved. Pending four-file test maintenance remains archived as an unapplied patch with 23 passing candidate tests; it is not an omitted application source change.

The next APK must include the entire branch at its final clean remotely verified reconciliation HEAD and all exact input fingerprints from this manifest. Metadata-only reconciliation commits do not change the qualified application input set; recompute and verify it when the fresh candidate is prepared. Create a unique next candidate/version and run its required fresh gates before any build/install; r66.32 authorization is consumed. Replay all 22 post-APK outcomes and their children on the new APK. Current result is **Git-safe and source-reconciled, not yet a qualified/built new APK**. Google API/location/map, live Store/provider mapping and legacy-test maintenance remain explicitly deferred as instructed. No new app or device test run was necessary for this documentation/inventory task; no application source changed.

### Fresh r66.33 Redmi authorization and qualification

Founder now authorizes: "if git is safe then move ahead with redme apk". Start `3959b3c23ba09f66397b74313b8ddfb90c761442` is clean and equals live origin. Outcome: consumer reviews all 22 reconciled Buy frontend outcomes on Redmi; mvp_supporting. Reuse the complete existing branch, isolated CursorUiReview debug package and guarded build wrapper. No Store integration, backend/Google work, production promotion or new feature scope. Candidate `UAW-CURSOR-BUY-R6633-20260922`, version `1.0.0-r66.33`, code `2026092202`; prior r66.32 remains immutable and consumed.

The previously deferred four-file test patch is now required for fresh full Buy qualification. It was applied from the exact archived patch (SHA-256 `e686e9db2b96a2449b3b4fe28bce46fe4163493b1c779964b1668ebdd5c9a62e`) after `git apply --check`; its four repository suites pass 23 tests, with one existing capture-only skip. Logs: `apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/legacy.log` and `.result.json`. Formatting changes only the wrapped Wholesale test import. Application source is unchanged. The existing admission lists transfer only these four test owners to Cursor's primary claim; no rule, regression requirement or other worktree changes. This uses standing narrow authority to resolve necessary APK blockers.

Initial regression-memory invocation omitted the retained evidence archive and reported missing historical evidence; passing the existing `EvidenceArchiveRoot` parameter resolved it without file changes. The paired owner-list admission rejected the intermediate policy-only edit and passed after the exact four entries were added to its matching checker. A documentation patch guessed an absent title and made no change; the actual tail was then read before this edit. No failed invocation is counted as acceptance evidence. Two fresh complete Buy passes, source/positive gates, APK identity and installed checksum remain pending.

### r66.33 prebuild regression replay — diagnostic run 1

Retained log: `apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/buy1.log`.
Result: 2,407 passed, 27 skipped, 120 failed test cases (many repeat the same assertion at multiple viewport/text sizes). This is not a qualification pass. No APK built or installed.

- Child R6633-C01: public current-location popup intercepted Store procurement address entry. Restore the original address route for Store procurement; retain the public popup. Existing Store return tests must pass unchanged.
- R6633-T01: reconcile superseded product sections, compact Add/Cart, removed empty benefits/Medicine promotion, expandable category sheet and automatic location popup assertions. Preserve actual purchase, cart, Back, Android inset, accessible tap and provider-data checks.
- R6633-T02: custom review/photo provider fixtures must supply explicit eligibility for their named test SKUs. Do not bypass production fail-closed eligibility or use unrelated review-data shortcuts.
- R6633-C02 investigation: Recent card action and narrow-screen delivery controls must be visibly reachable; distinguish an offscreen test tap from a real inaccessible control with focused geometry/tap replay.

Only exact Buy test owners were admitted in the existing worktree registration to repair the APK qualification blocker. No broader rules changed. Backend/Google dependencies remain deferred.

Focused follow-up: C01's two existing procurement return tests pass unchanged after the one-condition route repair. C02 reproduced as offscreen test actions: Recent opens after centering its actual control; narrow navigation remains horizontally reachable; search correctly removes fleet controls. No extra runtime layout change was needed. T01/T02 were reconciled with named simulated provider identities, explicit eligibility, actual grouped information and the approved fixed Cart/current-location UI. Retained runs: `focused-r1` (513 pass, 18 fail, 1 skip), `focused-r2` (96 pass, 19 fail), `focused-r3` (14 pass, 5 fail), `focused-r4` (5 pass, no failures). Each follow-up reran the remaining failures; complete qualification is still pending two full Buy passes. Analysis exits 0 with no errors/warnings and eight existing informational brace-style notices in unchanged eligibility/session code.


### r66.33 built, installed and source-safe — final qualification disposition

This section supersedes earlier pending-build/full-test/test-maintenance descriptions above; historical entries remain preserved. Founder authorized the new Redmi APK after Git reconciliation. All 22 post-r66.32 outcomes, including explicit Quick/Scheduled/Wholesale/Bulk frontend eligibility, are included. Google/API/backend/Store-provider dependencies remain deferred; no integration or backend development performed.

- Frozen build source: `1650a1ddb3bf3672530c8d345d0a5c3e9f475aba`; exact qualified review source pin `02369e96a293e4588cca06efad17a02bf53470a8`. All 18 required integrated tips retained. Source was clean, pushed and live-origin verified before build; local recovery bundle retained.
- Manifest: 3,236 inputs, SHA-256 `AFCDD9532CEB895C144414C0ED7066F78813A825A27E2616CC6BB5B357ADA799`; every input matched again after both complete test passes, build and device replay. No new runtime edits after freeze.
- Two full Buy runs: **2,527 passed, 27 skipped, zero failures EACH** (`buy2`, `buy3`). Analyzer: zero errors/warnings and eight existing informational notices. Formatting unchanged. Required source/brand/native/negative-control/prebuild checks passed; APK native plugin integrity passed. Earlier failed diagnostics retained, not counted as passes.
- Installed isolated review candidate `UAW-CURSOR-BUY-R6633-20260922`, `1.0.0-r66.33-cursorreview`, code `2026092202`, package `com.moolsocial.app.cursorreview`, Redmi `TG8HCYTGGQT885OF`. The one-build authorization is consumed. Production/backend acceptance is not claimed.
- APK SHA-256 **968933D16519BBE6AC757C10ACA39368F87A7605CFAB0CF1F6C4E28DD73E1FC7** exactly matches on-device `base.apk` and separately pulled installed bytes. Same verified signer as predecessor. `adb install -r`; no uninstall or data clear. Binary: `apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/uaw-cursor-buy-r6633-20260922-device-review-debug.apk` (215,594,961 bytes).
- Six packs in three Wholesale lines and one Saved product retained. Work/Basni address and Delivery restored after replay; Redmi left on Shop. No order, payment, chat or message submitted. Displayed total rose from INR14,692 to INR14,992; investigation O01 below remains open.

Focused Redmi replay captured 48 actual screenshots including preinstall/startup evidence. Confirmed grouped Shop/Wholesale/nested product information, compact primary Add/Cart quantities, main-rail Cart stability, Store and Wholesale Store expanding search, scoped search/price filter, full-height draggable categories and thumbnails, Store details without pickup banner, Android-visible Store filter controls, honest unavailable checkout/comparison/location states and pickup sign-in Back retention. Screenshots do not substitute for live provider qualification or all device-case closure. Recipient edit/keyboard and the specific Offers Manage order/View invoice context were not repeated on device in this bounded replay; their host checks passed, device obligations remain explicit. Full per-ticket dispositions are in `device-replay.json` and `DEVICE-REPORT.md` in the candidate directory and evidence ZIP.

**Open device findings — registered, not implemented in this frozen APK:**

| Finding | Parent / evidence | Required follow-up |
|---|---|---|
| R6633-D01 | RB026; `redmi/027-orders-lower.png` | Historical mixed-product MS-NEW-03 is Preparing but combined estimate retains “Delivered in 30 min”. Normalize each component; preserve real completed history. |
| R6633-D02 | Cart across surfaces; `redmi/043-product-actions.png` | Product opened through Recently viewed omits aggregate Cart access when six Wholesale packs exist. Root Shop product retains it. Check nested route scope/fixed control. |
| R6633-D03 — founder reopened | RB013 / Recently viewed compactness; `redmi/042-recently-viewed.png` | Narrower Add still sits on its own row, leaving wasted space. Large thumbnail/card and separate Clear row keep popup sparse. Full compact premium requirement is incomplete. |
| R6633-O01 — investigation | Retained-data update; preinstall screenshot and `018`, `019`, `024` | Same six packs but displayed total increases INR300. Determine selected coupon persistence/revalidation; no price-change or data-loss cause claimed yet. |

**Founder correction on Recently viewed:** the partial change is present in Git and in the verified APK; no commit was omitted. `_RecentlyViewedProductInfoRow` still ends its metadata Column with a right-aligned Add on a separate row. The earlier assessment accepted button width too narrowly and overstated completion. Reopen the original requirement as R6633-D03: compact header/Clear and product card, thumbnail/metadata/action grouped without an empty full-width Add lane, readable long text and accessible tap targets, Android/keyboard-safe sheet, same SKU/navigation wiring. Validate actual Redmi/Flutter geometry and founder screen approval; button width alone is not acceptance. Initial replay report retained and explicitly superseded by corrected report.

Google location/map API, authentic Store/public catalogue/photos, live identity/provider mapping, delivery fleet/booked slots and payment execution remain deferred. All source is included; **not all 22 tickets are device-closed**. Three confirmed children plus one investigation remain open. No new APK rebuild for these findings is implied by this evidence-only parking.

Evidence ZIP SHA-256: `7bb5e85be9152971818f3b495c278386ae438cea59801ba2aae35d7f98d7f8ab` (68,279,648 bytes). All 342 prior entries verified unchanged; 222 candidate evidence files plus 24 helper files appended under `r6633-qualification/`. APK binaries remain locally retained; reproducible source, receipts, logs and screenshots are Git-backed. Final metadata commit changes only this handoff, inventory and evidence archive.


### R6633-D04 — founder white strip behind Cart, register only

Founder explicitly requests inspection and registration only; **do not implement**. OPEN, launch-supporting public Buy visual defect.

Current Redmi screenshot `051-founder-cart-strip.png` confirms the full-width empty white strip behind the right-aligned Cart pill in Store search. Catalogue and nested Store product reproduce it (052/053). Retained same-APK Wholesale Store screenshot032 confirms that variant; current Wholesale basket is empty, so no new scoped Cart was fabricated. Root Shop/Wholesale/product/Orders/Offers/Saved Cart placements were inspected (055–062): their normal navigation rail has no separate Store-style blank strip. Preserve that distinction.

The three shared Store Cart placements are in buy_v2_catalogue.dart (Store sheet/full catalogue) and buy_v2_screen.dart (nested product). Register all shared callers and their Saved/Recent/related routes for future regression; no claim that every route variant was separately tapped. Expected correction: eliminate only redundant opaque Cart-only whitespace, preserve fixed compact Cart, product visibility/scrolling, theme continuity, accessible targets and Android/keyboard safe areas. No backend dependency. No source/test/APK change made.

Full ticket and 14 fresh PNG/XML/receipt sets are archived under `r6633-cart-strip-D04/` in the existing evidence ZIP. Latest ZIP SHA-256 `c47201d6b956cf86a94112bf867a4ad1193dfd8b3356361de4729008544bc0d7`; all 588 earlier entries integrity-checked and preserved. Five Shop items / INR694 and one Saved item unchanged; device returned to public Shop Visit Store. R6633-D04 remains open alongside D01/D02/D03 and observation O01.


### R6633-D05 — Compare prices remains functionally incomplete (23 September)

Founder-current Redmi capture065: A4 ruled notebooks / Carton of120, unavailable supplier prices. Tapping Refresh yields the same state in066. **OPEN functional provider-wiring gap; registration only, no fix now.** The prior Compare ticket fixed sheet sizing, while its acceptance item4 explicitly deferred supplier data. Layout inclusion is not a missing Git commit, and local fixture success is not functional device acceptance.

Read-only source trace: `_reload` in buy_v2_views.dart (~1964) returns unavailable before loading when nullable `session.comparisonSource` or query is absent. The full apps/mobile/lib tree has a BuyV2ComparisonSource interface and controller/session references, but no implementation or constructor injection. Therefore Refresh cannot fetch comparison offers in this app configuration; restoring internet cannot supply the missing adapter. Earlier completion wording must distinguish the implemented sheet layout from this unimplemented end-to-end outcome.

Future acceptance: wire the existing contract to coordinated, versioned Store-origin identities/offers; same SKU/variant/pack, correct prices/stock/eligibility, pagination and stale/location rejection, genuine recovery and exact product/Cart return. Distinguish missing configuration from transient network errors so retry is truthful. Preserve compact layout and Android safety. Backend/Store provider work remains deferred; no invented live prices, new screen, policy or other-worktree work. Device left on the comparison sheet; no basket or transaction changes.

Full ticket and before/after Refresh screenshots are preserved under `r6633-compare-D05/` in the evidence ZIP. Latest SHA-256 `887b6cba1d44bee296afdd80b0df9ef1054bcc2b6e26a31161f36b5eafaf165b`; all 631 previous entries preserved. No source/test/APK changes.


### R6633-D06 — Offers and Cart journey, registration only (23 September)

Founder requested inspection and full visual/technical ticket definition, explicitly no implementation. **OPEN: one parent with seven work packages**: A publisher-tab visibility/loading; B authentic MoolSocial admin/Store offer-data dependency; C compact publisher filter; D inline Saved parity and correct scope; E approved price-row Add across SKU entry routes; F compact Cart browsing actions; G premium compact Cart through final review, including keyboard/insets and state correctness. Future actual local Flutter screens remain required for founder approval after authorized implementation.

Redmi captures067–081 and timed070/071 reproduce Suppliers text becoming invisible during switching, no MoolSocial review offers, oversized filter/Saved sheets, Wholesale SKU bottom Add dock and competing full-width Cart browsing controls. Read-only source inspection confirms review offer generation never emits the moolSocial publisher type; no backend/admin data was injected. Future data must come from exact Store/admin identities and the existing BuyV2PublishedCatalogueOffer mapping, with simulated transport labelled and no claim of live eligibility.

Two linked child defects: **R6633-D06-D-C1**, Offers Saved uses the last Shop destination and omits the saved Wholesale item shown in Offers; **R6633-D06-G-C1**, Shop payment chooser shows a stale Purchase order reference despite that method being unavailable. Both remain OPEN. Final payment/order/provider success was not tested or claimed. Address recipient keyboard was inspected, but lower-field reachability still needs its explicit future checks.

Cart restored unchanged: four products / six Shop items / ₹760. No quantity/Saved/payment selection, address save, transaction, app/test/config/policy changes, new APK or other-worktree work. Existing D03/D04/D05 remain separate linked issues. Detailed acceptance covers query freshness/pagination, accessible compact layout, product MOQ/stock/verification, exact Cart totals/routes, keyboard/Android safety, and honest provider-deferred states.

Full ticket: `r6633-offers-cart-D06/OFFERS-CART-JOURNEY-D06.md` inside the evidence ZIP. Archive SHA-256 `254abfb88c033055f1159abea9ed9a30adf7da4304c2eb7598f2f7721cf44c0e`, 79,403,754 bytes; all 638 prior entries preserved, 50 new entries. Registration complete; all seven work packages and two children remain open.


### R6633-D07–D10 — Authenticated checkout and customer delivery audit (23 September)

**Delivery wording/choice correction:** the founder subsequently rejected the service/time chooser described below. The platform-assigned delivery correction at the end of this handoff is authoritative for D08/D09/D10 and D06-G; original observations remain historical evidence.

**Four new OPEN tickets, registration only:** D07 remove redundant checkout sign-in by connecting the authoritative app identity; D08 consumer delivery wording and explicit service/slot eligibility; D09 delivery selection, stable fulfilment grouping and complete compact review; D10 live order/delivery updates for consumer, Wholesale, retailer procurement and bulk buyers. **D06-G extended** to require compact premium polish from Cart through address/collection, payment, review and tracking; this is not an extra duplicate ticket.

Current Redmi082 confirms the collection sign-in notice/button. The review harness deliberately starts Buy without normal account entry, and no collectionIdentity injection was found in runtime lib; reaching that review Cart is not authentication evidence. Future fix must reuse real app identity, remove normal-session duplicate login, distinguish provider unavailability from expiry, and preserve authorization/account isolation. No auth bypass.

Proposed consumer copy: **Express delivery** for eligible retail biker service; **Choose a delivery time** for scheduled Wholesale/Bulk; **Standard delivery** for eligible retail/Wholesale parcels; retain **Collect at store**. Show verified ETA/date/slot/fee, not operational fleet language or invented capacities. Existing explicit eligibility checks stay intact. Source child D08-C1: scheduled is an eligibility option but the three-mode display/group model cannot represent its selected slot distinctly. Source child D09-C1: current grouping keys use seller display text and promise strings rather than stable Store/fulfilment/quote IDs; no cross-Store collision was reproduced.

Device095–098 reaches delivery review with six items/₹760; delivery remains correctly blocked as unconfirmed. Three same-Store products occupy separate shipment cards with different estimates, requiring compact provider-correct grouping, not blindly merged deliveries. Existing Retail088/089 and Wholesale/retailer091 tracking show last-known state and unavailable live updates. Existing tracking polls an optional adapter; no runtime liveDeliveryAdapter injection was found. Provider/Google/order lifecycle integration remains explicitly pending. Bulk checkout and retailer-owned procurement end-to-end were source-audited/spec'd, not device-passed.

All actors have a documented acceptance matrix, including live/stale/offline/reconnect/slot/quantity/address/payment and multi-delivery recovery. Actual local Flutter screens are required after later implementation for founder approval. No application/test/policy changes, data injection, APK, payment/order submission or provider workspace edits. Basket preserved and original five-item collection/payment choice restored in102; Pine Labs was preselected before inspection.

Full report and fresh device evidence: `r6633-checkout-delivery-D07-D10/CART-CHECKOUT-DELIVERY-AUDIT-D07-D10.md` inside the evidence ZIP. SHA-256 `cd260c05d34acee1440d35801ff4f8b10a46ebf7fcb38fe1124c0d4d077bf178`; 84,177,530 bytes; all 688 existing entries preserved plus 61 new entries. All four tickets and two source children remain OPEN.


### Founder correction — platform-assigned MoolSocial delivery (23 September)

**Annotation1: customers do not choose a delivery service or time slot.** Supplier/Store and logistics partners follow MoolSocial's delivery algorithm; it assigns the service, timing and subsequent updates. This supersedes the earlier Express / Choose a delivery time / Standard proposal, D09's suggested customer chooser, and the slot-picker preview requirement. Absence of that chooser is not a defect.

Professional platform labels proposed for the registered design: **MoolSocial Quick Delivery** for eligible small biker orders; **MoolSocial Scheduled Delivery** for Wholesale/bulk; **MoolSocial Courier Delivery** for remote parcels, which are also scheduled. Courier service and assigned timing must coexist. No invented thresholds, promised minutes or local assignment algorithm.

Product descriptions show the existing intended Store/supplier-backed delivery type and estimate. Cart/checkout show the platform-assigned service, timing and charges compactly, without delivery-service/time selectors. After placement, all buyers see the actual live/scheduled/courier progress, assigned date/window and freshness updates from the order/Store/logistics source. D08-C1 now concerns assigned schedule separate from transport, including courier; D09-C1 stable shipment identity remains open. D06-G full compact premium polish and D07 auth work remain required. Existing Store collection scope is preserved; no new pickup rule is inferred.

Updated D08/D09/D10 requirements and future preview/test matrix; no additional ticket count. No implementation, provider/algorithm work, APK, device interaction or tests in this documentation correction.

Operative report: `r6633-platform-delivery-correction/PLATFORM-ASSIGNED-DELIVERY-CORRECTION-20260923.md` in the evidence ZIP. Latest SHA-256 `e10bce97ca96eec54ae7baf8db70529f566c282be3cc9a59257c57d96e28ce3a`; 749 prior entries preserved plus one correction. Earlier audit reports are retained for observations but their rejected chooser/copy requirements are superseded.


### R6633-D11–D16 — Add-to-order real-user Redmi replay (23 September)

**Six NEW OPEN defects, registration only:** D11 missing online payment handoff after final review; D12 misleading locked method controls/cancelled-state recovery (child C1 blocks Shop Add from an unavailable Wholesale attempt); D13 dispatch promise labelled Arrives; D14 Add/Edit basket opens deep recommendations rather than affected items; D15 required PO reference below viewport without focus on validation; D16 inconsistent public Store/product names after order. Existing D07 collection identity/service block, D09 unconfirmed delivery, D10 missing live updates, D06-G-C1 orphan PO field and compact Cart/white-band tickets have fresh linked evidence, not duplicate closures.

**30 route/state checks across Shop, Wholesale, Bulk, Offers and Visit Store:** online method selection can reach review, then Place order returns to unavailable handoff. Collection PhonePe/Paytm/Pine Labs leave Review disabled. Cancel alone leaves a contradictory complete-payment instruction; Choose again restores idle. Empty PO correctly blocks, but its field is not brought into view. Bulk MOQ validation, category recovery, offer refresh, invalid carried payment method gating, below-minimum benefit protection, exact totals and removal of test items passed their stated checks. Bulk and some Store products correctly block on unavailable delivery timing; those provider outcomes remain open.

One existing-review-adapter COD order was created for the test-added Shop tomato: **BUY-NEW-05 / MS-NEW-10 / ₹37**, local simulation only. Actual confirmation, invoice preview, Android save-picker cancellation and tracking were inspected. No real order/payment/delivery or saved PDF success claimed. Current invoice/tracking exposes Mool Market000001 and invoice Fresh tomatoes1 where preceding public screens showed Mool Market1/Fresh tomatoes. No arbitrary number stripping or alteration of legal invoice identity is authorized by registration.

Original founder basket preserved: **Fresh red onions, Wholesale25kg sacks,2packs,₹1550**. Other test additions explicitly removed, temporary PO reference cleared, temporary benefit removed, Paytm restored.183 leaves payment idle/Review available after cancelling the initial failed attempt. Local test order retained and disclosed. No address/Saved edits, app/test/config/policy change, APK, provider injection or external payment/message. Two private Android picker-context captures132/133 remain local-only; app proof, manifest and other captures are archived unchanged. Full live/authenticated retailer/procurement/delivery combinations remain dependency-pending and are not claimed tested.

Full report `r6633-add-checkout-replay-D11-D16/ADD-CART-CHECKOUT-REPLAY-D11-D16.md` and capture manifest `r6633-add-checkout-replay-D11-D16/ADD-CART-CHECKOUT-REPLAY-MANIFEST.json` in evidence ZIP. SHA-256 `b70a51f7a7a06593d7e36e40074976dc12f7a3777f47c53ae306d59517093563`, 101,158,738 bytes; all 750 previous entries preserved plus 238 entries. No implementation; six findings plus D12-C1 and existing linked defects remain OPEN.


### Frontend Add-to-Cart through completion — nine visual/workflow children (23 September)

Founder clarification: missing providers must not stop frontend visual/workflow registration or local frontend qualification. **R6633-D06-G-V01–V09 are OPEN**, refining the existing Cart-polish parent rather than duplicating D06-E/F, D12–D16. Scope: product/Add parity; compact Cart and bill; address/collection forms; payment/reference/recovery; final review; confirmation; tracking/invoice actions; brand/typography; keyboard/Android/edit continuity. Each child has evidence, expected layout/behavior and acceptance criteria. Applies across Shop, Wholesale, Bulk, Offers and Visit Store.

Required sequence: product/quantity → Cart → address or collection → payment → review → placement result → tracking/invoice/support. Platform assigns delivery service/timing; no customer slot/service picker. Keep approved collection choice. Existing state/contracts and screens must be reused; no new backend or invented provider success. Nine visual/workflow children are registered, not implemented or passed. Existing 30 route/state checks and screenshots reused; six frames visually re-inspected, no new device run or order. Lower-field keyboard, enlarged-text and unexecuted lifecycle variants remain explicit acceptance checks rather than invented passed results.

Full actionable MD: `r6633-frontend-journey-visual/FRONTEND-CART-JOURNEY-VISUAL-TICKETS-20260923.md` inside evidence ZIP (local review artifact `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921/apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/FRONTEND-CART-JOURNEY-VISUAL-TICKETS-20260923.md`). Archive SHA-256 `9dbc8698a4520de9a409c48860e65943a9a07d8f9336e3e721d16e9030c32419`, 101,164,838 bytes; all 988 earlier entries preserved. Source untouched. Provider/live acceptance is separate and deferred; visual tickets remain actionable.


### Founder correction — only MoolSocial-issued Purchase Orders (23 September)

**Binding requirement for D15 and D06-G-V04:** a Purchase Order must be issued by MoolSocial before its reference can be accepted. Arbitrary buyer-entered text, a supplier PO or a non-empty field is not proof of a valid MoolSocial PO. This supersedes any earlier wording that suggested a procurement-approved reference alone was sufficient.

Frontend ticket: label the field “MoolSocial purchase order reference”; explain concisely that it must refer to a MoolSocial-issued PO. Distinguish empty, checking, verified, not found/not MoolSocial-issued, unusable and verification unavailable states. Changing the reference or relevant purchase context invalidates the previous verification. Do not imply acceptance or allow submission on an unverified reference. Preserve entered text for correction and expose inline errors above the keyboard. Keep the compact payment layout and field-reveal requirements.

Backend dependency: authoritative MoolSocial PO issuance/lookup and validation against the authenticated buyer and applicable order. Exact validity, status and purchase constraints must come from the coordinated contract, not locally invented rules or a reference-prefix check. Local frontend fixtures may demonstrate these states but cannot issue a real PO or establish production validity. Include tests for arbitrary/non-empty text, unknown/foreign reference, valid issued reference, changed reference/context and unavailable verification. Existing AUDIT-R6633-LOCAL was a review-only form-validation probe, NOT an issued/accepted MoolSocial PO; it must not be cited as business PO acceptance.

Status: registered only; no code, provider or APK change. This is a refinement of the existing payment/PO ticket, not a duplicate parent ticket.

### Wholesale/Bulk PO journey inspection and implementation authorization

Founder now authorizes the missing Wholesale/Bulk PO frontend journey, reusing the existing workflow and adding only what is necessary. This supersedes registration-only for this specific PO ticket; all other newly registered visual tickets remain registration-only.

Read-only findings: BuyV2Session.purchaseOrderEligibleForCheckout checks verified business and Wholesale-destination lines; purchaseOrderDetailsComplete checks only trimmed reference length >=3. Both continueCheckoutFromPayment and submitOrder use that insufficient check. The shared payment view exposes a free-text reference, not a MoolSocial issuance/verification journey. Bulk replay153/154 previously traversed this same field into review; that proves form navigation only. Existing retailer placeWholesaleOrders/ReviewRetailerWholesaleGateway generate fixed review PO IDs and supplier records, not an authoritative issuer suitable for reuse as production validation.

Reuse decision: retain Buy's existing Cart, quantity/MOQ, address, payment, review and order details owners; do not route public checkout into the legacy retailer review workflow or copy its fixed IDs. Issuance/lookup can join the existing checkout through a narrowly scoped provider contract. Backend implementation remains deferred.

Required product clarification presented to founder: should MoolSocial issue the PO from this reviewed basket, or must the buyer bring a MoolSocial PO issued beforehand? This is a workflow decision, not an additional permission request. It determines whether the frontend needs a generate/request outcome or a reference verification action; no operational issuance rule is inferred while the answer is pending. No runtime changes yet. Future focused checks must cover Wholesale and Bulk, arbitrary references, issued reference/context binding, unavailable verification, edit/back continuity and keyboard visibility.

### R6633-D17 — MoolSocial-generated buyer PO and connected Wholesale/Bulk journey

**OPEN; founder decision resolved.** MoolSocial generates the PO from the reviewed basket on the buyer's behalf. Identify the actual buyer and supplier; MoolSocial is the generating platform, not automatically the buyer. PO is an order document, NOT a payment method. This supersedes the earlier existing-reference-input proposal and the pending clarification above. Link D15/D06-G-V04; do not implement a parallel free-text PO authorization workflow.

Required sequence: products/variants/quantities → Cart → receiving address or collection → review commercial terms and buyer/supplier details → explicit buyer confirmation → platform-generated PO/reference → supplier acceptance or clearly stated exception → separate payment under agreed terms → packing/dispatch → assigned delivery or collection → completion → invoice/support. Avoid extra screens: reuse existing Cart, checkout/review, order details, document access and order conversation. For a multi-supplier basket, bind each supplier-facing PO to its exact lines; final grouping/issuance and payment timing are authoritative contract data, not frontend guesses. Changes/rejections require explicit revised terms and buyer confirmation where applicable, never silent changes in chat.

Order-linked chat is required between buyer and supplier, and logistics where relevant and authorized. PO/order identity and concise context must remain accessible in the conversation; messages alone do not change price, quantity, payment, acceptance or delivery state. Distinguish supplier chat from MoolSocial support. Reuse the existing order-conversation route demonstrated in195/199/200; do not build another chat system. Show pending/failed/retry states truthfully, preserve drafts and prevent duplicate PO/order submissions.

Classification: mvp_required connected commerce frontend. Existing Buy session/views and shared order-chat owner are the reuse boundary; shared Store acceptance, PO issuance and party permissions need coordinated contracts, with no edits to another worktree. Backend remains deferred, but frontend layouts and all state transitions must be locally qualified with explicitly labelled fixtures. Register rather than implement in the current audit. No PO issued or message sent.

Acceptance: Wholesale and Bulk, single/multiple supplier, MOQ/variant totals, buyer identity, address edits, terms changes, issuance pending/failure/retry, acceptance/rejection, payment independent of PO, order-linked chat/back/draft retention, delivery/collection, completion and invoice/support. Apply the V01–V09 compactness, brand, text grouping, Android and keyboard criteria at every stage. Actual local screens and focused regression are required after implementation; no live-provider claim from fixtures.

### Frontend audit continuation — order management and communication (23 September)

Latest founder clarification again confirms visual/workflow tickets only. Existing nine D06-G visual children cover product/Add, Cart, address/collection, payment, review, confirmation, tracking/invoice, brand and keyboard. New actual Redmi captures184–200 inspect remaining Orders → Wholesale tracking → Manage order → cancellation reason → contact → order-linked chat → keyboard → expanded order context → Back. Earlier30 route/state checks are not recounted as new. All observations below are OPEN; no source changes.

**R6633-D06-G-V07-C1 — Tracking and history repetition.** 185–191 repeat status text in history cards and tracking, then repeat balance/date in both delivery details and Upcoming balance. Expected one current-state/timing summary, one aligned payment table (paid/due/when), compact conditional payment action, concise timeline and secondary order actions. Keep meaningful operational differences; remove repeated meaning and oversized panels, not necessary facts. This refines V07 rather than duplicating the parent.

**R6633-D06-G-V07-C2 — Manage-order form density.** 192/193 show large action selection, repeated headings, tall reason field and full-width support action for one cancellation option. Expected compact action/reason grouping with concise order context, one primary submission action and quiet secondary contact.194 is a dropdown, NOT a keyboard screenshot despite its filename; all four choices were visible above Android navigation. Empty reason correctly leaves submission disabled. Do not claim a clipping failure here. Register long-text/text-scale and correction/back cases for local qualification. No cancellation submitted or reason persisted.

**R6633-D17-C1 — Contact-support label opens supplier chat.** From Wholesale PO-240783: Manage order → Contact support instead opens Marwar Foods Distribution conversation (193→195). Expected action label and destination agree: Contact supplier for supplier chat, separately scoped MoolSocial support where required. Do not silently route platform escalation to the seller. Preserve order ID, party scope and return location. Reuse existing callback; coordinated Chat change only where necessary.

**R6633-D17-C2 — Order-chat compactness and duplicate draft.** 195/196/199: tall conversation header/card plus oversized empty-state text; long generated draft duplicates amount, delivery and payment details already in expandable order context. Header truncates partner/order detail. Expected compact persistent party/order identification, restrained empty state, concise editable help draft and accessible expandable facts; prevent required identity from becoming ambiguous. Keep brand typography/neutral surfaces and restrained accents, not additional solid-colour blocks. Composer and Send were physically above the keyboard in196;197 dismissed keyboard;198 cleared only this newly generated audit draft;199 expanded correct order context;200 Back returned to original tracking position. No messages sent. Do not label keyboard concealment as reproduced here.

**R6633-D06-G-V07-C3 — Completion/receipt/return frontend coverage.** Registration/acceptance gap, NOT a claimed reproduced delivered-state visual defect. The installed Orders list reached its recommendation section in189 with only preparing/supplier-confirmed records; no delivered record was available. Do not wait for live backend to design/qualify frontend states: use the existing order model and labelled local fixtures in the future implementation/test batch to expose delivered/collected summary, received items, partial/problem receipt where supported, balance/invoice, help/return/refund eligibility and unavailable states. Show actual recorded completion time, concise outcome and next relevant actions; hide obsolete active-delivery/promotional clutter. Group products, payment and service facts consistently. Inspect every conditional form for long text, validation, keyboard, Android safe areas, edit/cancel/back. Missing contract states become explicit integration requirements, not invented customer promises. No false claim that a full live Add-to-delivered run was completed.

Current audit outcome: frontend tickets specify the complete purchase lifecycle; actual device evidence covers available states, with completion-only states explicitly unrendered and awaiting local fixture coverage. All defects remain open. Backend absence is not a reason to postpone frontend polish. Original basket remains untouched; no payment, new order, cancellation, message, source change or APK in this continuation. Redmi left on Wholesale tracking after correct chat return.

### Active implementation checkpoint — post-r66.33 bounded replay

No ticket is closed by this checkpoint. Source is local and qualification is in progress; r66.33 remains installed. The final stopping point is the fresh APK replay and a disposition for every parent/child, with unresolved or new findings registered and no further fix cycle after that replay.

Implemented locally for qualification: D01 combined active-estimate copy; D02 aggregate Cart on nested product routes; D03 compact Recent header, thumbnails and inline Add with accessible large-text fallback; D04 transparent overlay Cart on Store/product surfaces with final-content clearance; D06-A publisher switch transition, C compact filter chips, D inline Saved across offer destinations, E Wholesale price/Add parity, F quiet Cart browsing controls; D07 remove redundant collection sign-in entry without bypassing account validation; D08 platform delivery labels; D09 grouping by Store identity when available; D12 truthful disabled unresolved-payment methods and terminal retry recovery; D13 dispatch/arrival-neutral Timing label; D14 new-Add/Edit basket entry reveals items while normal Cart-return offset stays retained; D15/D06-G-C1 retire PO-as-payment and stale reference field; D16 consistent public names in confirmation/tracking/invoice and PDF; D17-C1 supplier contact label and C2 concise editable help draft retaining structured order facts. V04/V05/V06/V07 shared changes include compact payment rows, progress header, success mark, separated payment facts and one balance owner.

Explicit dependencies remain open: D05 authoritative comparison data; D06-B authoritative administrator/Store offers; D07 actual account/provider binding; D08-C1 authoritative service assignment and scheduling independent of transport; D10/D10-C2 live logistics/Google Maps; D11 real payment handoff; D17 authoritative PO issuance, supplier acceptance and lifecycle integration. Removing PO from payment does not implement or qualify its whole lifecycle. Shared Chat header/empty-state density still needs its exact disposition; concise draft alone does not close D17-C2. Completion/receipt states require explicit test evidence. No production success may be inferred from labelled review fixtures.

Qualification evidence retained under `C:/GUARANTEED OUTCOME/outputs/buy-r6633-qualification/`: `successor-chat-continuity-02.log` (89 pass, three obsolete-expectation failures, corrected locally); `successor-product-offers-01.log` (39 pass, test import failure and obsolete Saved popup expectation, corrected); `successor-trade-payment-02.log` (24 pass, one existing capture-only skip). Recent Android last-Add and all Recent text-scale cases pass. Full Buy regression is now running; these are not final candidate results.

Exact ownership registration only: transferred Buy invoice view/downloader and state-invariant test from historical Cursor audit claim to current primary; admitted Offers visual and payment-sheet tests. No rule/registry requirement changed. `successor-admission-02.log` passes with78 current owners. All changes remain confined to this worktree. Fresh candidate planned as r66.34; no build authorization is consumed until source and required gates qualify.

### R6633-D10-C2 — Customer live Google Maps delivery tracking; required before go-live

### Active bounded successor execution — founder authorized

Starting source checkpoint 0b11940a3c57176ea96e0bc5fd071279bf115f91; installed predecessor remains r66.33. Founder authorizes implementation, local tests, a fresh Redmi APK and one final affected-journey device replay. Close only verified outcomes; if final replay finds unresolved/new child defects, register them and stop without a further implementation cycle. This is not authorization to close deferred provider work using review simulations.

Scope: D01–D17 and registered children, reusing Buy catalogue/session/product/Cart/checkout/tracking and order-chat entry owners. Frontend logic and visuals are required; live Google Maps, real payment handoff, authoritative identity/catalogue/PO issuance and delivery services explicitly deferred by the founder remain tracked integration dependencies. Preserve Store/CSV/Counter Sale and all current working data. Shared changes require exact contract handoff. No other worktree edits.

Plan: shared presentation and navigation defects → payment recovery and PO/order semantics → focused cross-route tests and actual Flutter screens → fresh version/source reconciliation and required build checks → checksum-verified Redmi install → final device defect/closure report. Test meaningful state, quantities, amounts, source scope, keyboard/insets, long text, stale results and recovery using existing tests first. Do not treat screenshots as technical acceptance or fixture orders as live commerce. All ticket status remains open until its evidence is recorded.

Local D03 correction evidence: first focused run40 pass/1skip/2fail. Isolated four Android-last-Add checks proved both normal-scale cases pass and both200% text cases miss the Add tap because the tall compact row puts its centred action behind the sheet header when scrolled to the end. Exact log retained at outputs/buy-r6633-qualification/successor-recent-isolation.log in the workspace. Correct large-text arrangement without weakening hit testing or Android insets; retain compact side-by-side action at normal text size. This is an implementation-stage correction, not final Redmi acceptance or a reason to stop the authorized local-fix cycle.

Founder explicitly requires customer-visible live delivery on Google Maps. Extend existing D10 live-delivery ticket; do not count this as another duplicate parent. **OPEN, mvp_required, scheduled for later provider/backend integration phase, mandatory before go-live.** The current installed review build does not demonstrate verified live Google Maps delivery tracking. Current frontend visual audit can proceed independently.

Outcome: from the relevant order/tracking screen, the authorized customer sees the assigned delivery partner's current position on Google Maps during active delivery, destination, provider-backed ETA/status and update freshness. Apply across Shop/Visit Store/Offers and Wholesale/Bulk deliveries using the shared tracking owner. Scheduled orders show the assigned schedule before dispatch and transition to active tracking when authoritative location becomes available. Courier must expose truthful carrier status and supported tracking; absence of carrier coordinates cannot be disguised as a moving live map. Any unavailable courier live-map capability remains an explicit pre-launch scope/acceptance decision, not an assumed pass. Collect-at-store retains Store directions and pickup progress, not an invented moving driver.

Dependencies: delivery workspace location publication and assignment; authenticated order/party authorization; backend delivery events and subscription; Google Maps integration and configuration; authoritative timing and completion. Reuse BuyV2LiveDeliveryAdapter, BuyV2Session and existing tracking UI in buy_v2_views.dart, plus shared delivery contracts. Do not build separate Biker/Bulk tracking systems or expose another customer's order, unrelated driver location or location after access ends.

Frontend acceptance: compact expandable map with clear status/ETA and restrained brand styling; no oversized empty map while awaiting assignment; accessible controls, Android safe areas, correct Back/resume and order-linked contact. Live/stale/offline/permission-denied states clearly distinguished; last update shown, no synthetic movement/countdown. Test assignment/reassignment, schedule-to-dispatch, moving updates, reconnect/out-of-order events, app background/resume, delivered/cancelled end state and access revocation. Verify with actual provider-fed Redmi journey before launch; fixtures only qualify frontend states. No implementation, credentials, provider setup or APK authorized by this registration.

Order-chat D17-C2 exact frontend scope: reuse chat_thread_screen.dart and chat_widgets.dart for a compact order-only header and empty state, preserving all non-order Chat layouts and existing contextual identity, message, call and composer handlers. Exact owners moved into the current Cursor claim; no contract, provider or other-worktree edits. Validate Buy order-chat return/draft/context and keyboard cases; no real messages sent.

### r66.34 local qualification continuation

The initial complete diagnostic Buy run retained 2,451 passes, 27 skips and 84 failures. Failures are not hidden: obsolete UI expectations were updated to the current inline controls and Timing/Checkout wording, while actual payment feedback, UPI submission and dropdown clipping regressions were corrected. The new check rejects retired PO-as-payment without rejecting a provider-supplied UPI method. Cancelled/failed payment feedback remains visible while selecting another method; pending/unknown attempts stay locked.

Confirmed evidence in outputs/buy-r6633-qualification: successor-corrections-03.log (306 passes, one existing skip); successor-session-05.log (440 passes); successor-screen-corrections-07.log (10 passes); successor-store-corrections-04.log (12 passes); successor-captures-03.log (10 new candidate captures, previous reference images preserved); successor-order-chat-visual-01.log (two actual renders at 100/200%); successor-completion-visual-01.log (two collected-order/receipt journeys at 320px, 100/200%). These labelled fixtures prove frontend states, not live delivery or real payment.

Inspected actual Cart, checkout at enlarged text, order-chat expanded facts and collected receipt images. Collected receipt groups status/payment, purchased items and receipt identity with Order help and no active-delivery control. Buy order-chat header/empty state is compact; full supplier identity wraps and structured facts remain expandable. Non-Buy/Care conversations preserve their existing header behavior. Shared Chat regression and remaining continuity/full Buy qualification are running. No Redmi defect closure or new APK is claimed yet.

Exact admission now passes with 94 owners (successor-admission-03.log), including two shared Chat presentation files and ten new candidate images. Historical tracked failure images generated by the diagnostic were preserved under outputs/buy-r6633-qualification/successor-full-01-failure-artifacts before restoring their original tracked bytes. No old evidence was discarded. Full app commit history remains unchanged pending the authorized source commit.

Final r66.34 evidence will be retained in a separate `docs/quality/CURSOR-BUY-R6634-EVIDENCE-20260923.zip`: the existing evidence ZIP is already near the remote file-size limit and remains unchanged. Exact archive ownership added only; no broader rule changes. Runtime implementation d029c185 and format-only test adjustment 71c48d9c are preserved. Source gates bind the exact latter snapshot. First full Buy qualification: 2,535 pass, 27 skip, zero failures. Second full pass is running. Format now passes; analyzer has zero errors/warnings and one inherited informational brace-style notice. All 37 parent/child records are listed in the candidate replay plan; no device closure yet. Redmi still runs r66.33 pending fresh build/install.

### Final r66.34 Redmi replay — 23 September 2026


Build source 821590ce845f6719439fc92077ce3bf1eea23053. Installed SHA-256 6B624757007AF342491BE1360DC0EE0D625C5E265C889DF3C0A43BD6F5FD21AC.
Two full local Buy runs: 2535 passed / 27 skipped each. All 3246 sealed source inputs unchanged after build/device replay.

Review fixtures only. No live payment, sent chat, provider-issued PO, real delivery or production acceptance. One local COD order BUY-NEW-06/MS-NEW-11 was created. Original Wholesale basket remains 2 packs/INR1550; temporary Shop basket item removed. Invoice save dialog cancelled.

All 37 original records have a disposition; this is not a claim that all defects are closed. Five child records registered, including one explicit acceptance-coverage gap. Stop now without another implementation/build cycle.

{'closed_verified': 13, 'partial_child_registered': 12, 'open_dependency': 6, 'partial_dependency': 4, 'closed_superseded': 2}

| Record | Status | Disposition |
|---|---|---|
| R6633-D01 | closed_verified | Mixed MS-NEW-03 preparing estimate now says Delivery; delivered history remains Delivered. Evidence: redmi/r34-order-wording-search.png |
| R6633-D02 | partial_child_registered | Original Recent nested product Cart fixed. Retail Visit Store with only Wholesale basket still lacks aggregate Cart; C01. Evidence: redmi/r34-recent-product-final.png, redmi/r34-nested-product-scroll.png, redmi/r34-store-ready.png |
| R6633-D03 | closed_verified | Compact header and inline Add; host large-text variants qualified separately. Evidence: redmi/r34-recent.png, redmi/r34-recent-final.png |
| R6633-D04 | closed_verified | Transparent floating Cart on inspected Store and nested product surfaces; no white backing strip. Evidence: redmi/r34-store-added.png, redmi/r34-wholesale-store-ready.png, redmi/r34-nested-product-scroll.png |
| R6633-D05 | open_dependency | Authoritative comparable supplier/variant offers unavailable; refresh remains truthful. Evidence: redmi/r34-compare.png |
| R6633-D06 | partial_child_registered | Compact filter, inline Saved, inline price/Add and quiet browse verified; administrator data and C03/C05 remain. Evidence: redmi/r34-offers-filter-ready.png, redmi/r34-offers-saved.png, redmi/r34-offer-wholesale-product.png, redmi/r34-cart-scope.png |
| R6633-D07 | partial_dependency | Duplicate sign-in removed. Account binding unavailable; collection does not bypass verification. Evidence: redmi/r34-collection.png |
| R6633-D08 | partial_dependency | Platform delivery names render; authoritative service assignment remains deferred. Evidence: redmi/r34-shop-product.png, redmi/r34-offer-wholesale-product.png |
| R6633-D09 | partial_dependency | Store identity grouping qualified locally; authoritative shipment identity not supplied. Evidence: redmi/r34-wholesale-review.png |
| R6633-D10 | open_dependency | Live delivery explicitly unavailable; no live provider route or physical delivery claimed. Evidence: redmi/r34-tracking.png |
| R6633-D11 | open_dependency | PhonePe/Paytm review flow works but real provider handoff unavailable; no live payment. Evidence: redmi/r34-payment-unavailable.png, redmi/r34-wholesale-provider-unavailable.png |
| R6633-D12 | closed_verified | Unavailable attempt locks methods; cancellation restores selection and next review. Evidence: redmi/r34-payment-unavailable.png, redmi/r34-payment-cancelled.png, redmi/r34-review-cod.png |
| R6633-D13 | closed_verified | Timing preserves Dispatch within one day, not a fabricated arrival promise. Evidence: redmi/r34-wholesale-review.png |
| R6633-D14 | partial_child_registered | New Add reveals purchased item. Exhaustive Edit basket/scroll matrix remains C05. Evidence: redmi/r34-crossscope-add-cart.png |
| R6633-D15 | closed_superseded | PO reference and PO-as-payment removed; legitimate PO workflow remains D17. Evidence: redmi/r34-wholesale-payment.png, redmi/r34-payment.png |
| R6633-D16 | partial_child_registered | New Buy/invoice names normalized; historical Orders and chat retain padded names, C02. Evidence: redmi/r34-supplier-chat.png, redmi/r34-orders.png, redmi/r34-invoice.png |
| R6633-D17 | partial_dependency | PO removed from payment and supplier chat works. Issuance, buyer approval, supplier acceptance, communication lifecycle still incomplete, not solely backend acceptance. Evidence: redmi/r34-wholesale-payment.png, redmi/r34-supplier-chat.png |
| R6633-D06-D-C1 | closed_verified | Saved Wholesale offer is accessible from Offers even after Shop context; inline presentation. Evidence: redmi/r34-offers-saved.png, redmi/r34-offer-wholesale-product.png |
| R6633-D06-G-C1 | closed_superseded | No stale PO reference field remains; D17 owns replacement workflow. Evidence: redmi/r34-payment.png, redmi/r34-wholesale-payment.png |
| R6633-D08-C1 | open_dependency | Schedule independent of transport requires authoritative Store/logistics assignment. Evidence: redmi/r34-wholesale-review.png |
| R6633-D09-C1 | open_dependency | Authoritative stable fulfilment IDs remain integration dependency. Evidence: redmi/r34-wholesale-review.png |
| R6633-D12-C1 | closed_verified | Cancelled Wholesale payment then Shop Add succeeds, original basket preserved. Evidence: redmi/r34-wholesale-provider-unavailable.png, redmi/r34-crossscope-add-cart.png |
| R6633-D06-G-V01 | closed_verified | Inline price/Add on Shop and Wholesale offer details; Cart item visible on entry. Evidence: redmi/r34-shop-product.png, redmi/r34-offer-wholesale-product.png, redmi/r34-cart-scope.png |
| R6633-D06-G-V02 | closed_verified | Quiet browse, aligned price/quantity and persistent total/Checkout on inspected scopes. Evidence: redmi/r34-cart-scope.png, redmi/r34-wholesale-cart.png |
| R6633-D06-G-V03 | partial_child_registered | Address/pickup frontends inspected. Compact lower-field/validation matrix remains C05; account binding deferred. Evidence: redmi/r34-address-edit.png, redmi/r34-address-keyboard.png, redmi/r34-collection.png |
| R6633-D06-G-V04 | closed_verified | Compact methods, no PO field, explicit recovery; production provider success excluded. Evidence: redmi/r34-payment.png, redmi/r34-payment-cancelled.png, redmi/r34-wholesale-payment.png |
| R6633-D06-G-V05 | partial_child_registered | Review works, but Wholesale duplicates product/amount across shipment and trade table, C03. Evidence: redmi/r34-review-phonepe.png, redmi/r34-wholesale-review.png |
| R6633-D06-G-V06 | closed_verified | Compact confirmation and next action verified with labelled local COD order only. Evidence: redmi/r34-local-cod-confirmation.png |
| R6633-D06-G-V07 | partial_child_registered | Compact actions work; empty historical Payment section C04 and provider completion remain. Evidence: redmi/r34-tracking-actions.png, redmi/r34-invoice.png, redmi/r34-delivered-detail.png |
| R6633-D06-G-V08 | partial_child_registered | Normal-size device samples inspected and local enlarged-text renders passed; complete physical-device variant matrix C05. Evidence: redmi/r34-shop-product.png, redmi/r34-cart-scope.png, redmi/r34-wholesale-review.png |
| R6633-D06-G-V09 | partial_child_registered | Inspected keyboard/form cases retain content; exhaustive lower-field/correction matrix C05, not a blanket keyboard pass. Evidence: redmi/r34-address-keyboard.png, redmi/r34-chat-keyboard.png, redmi/r34-wholesale-quantity.png |
| R6633-D06-G-V07-C1 | partial_child_registered | Payment facts reduced; historical status repetition and empty Payment remain C04. Evidence: redmi/r34-orders.png, redmi/r34-tracking.png, redmi/r34-delivered-detail.png |
| R6633-D06-G-V07-C2 | closed_verified | Compact single cancellation choice and correctly named quiet supplier action. Evidence: redmi/r34-manage-order.png |
| R6633-D06-G-V07-C3 | partial_child_registered | Historical delivered fixture visible; returns correctly unavailable. Collected/partial receipt qualified locally only, full device matrix C05. Evidence: redmi/r34-delivered-detail.png, redmi/r34-delivered-return.png, redmi/r34-return-reason.png |
| R6633-D17-C1 | closed_verified | Contact supplier opens supplier order conversation. No message sent. Evidence: redmi/r34-manage-order.png, redmi/r34-supplier-chat.png |
| R6633-D17-C2 | partial_child_registered | Concise draft and compact context; padded name/truncated party subtitle remain C02. Evidence: redmi/r34-supplier-chat.png, redmi/r34-chat-keyboard.png |
| R6633-D10-C2 | open_dependency | Google live map and provider location/events remain mandatory before go-live. Evidence: redmi/r34-tracking.png |

## Open children

### R6634-C01 — Retail Visit Store hides aggregate Cart when only Wholesale basket exists
Parents: R6633-D02. Retain a reachable aggregate Cart on every nested Store surface, even with no local-scope items. Do not add empty carts.
Evidence: redmi/r34-store-ready.png

### R6634-C02 — Public Store naming and chat header remain inconsistent
Parents: R6633-D16, R6633-D17-C2. Use the same safe public display identity in historical Orders and order chat, retaining full party/order access and legal identity. Header subtitle currently ellipsizes.
Evidence: redmi/r34-supplier-chat.png, redmi/r34-orders.png

### R6634-C03 — Wholesale review repeats product and subtotal
Parents: R6633-D06, R6633-D06-G-V05. Combine shipment items with pack/MOQ/unit-price facts in one compact table; preserve totals, tax, returns and Store grouping.
Evidence: redmi/r34-wholesale-review.png

### R6634-C04 — Historical tracking has empty Payment section and repeated status
Parents: R6633-D06-G-V07, R6633-D06-G-V07-C1. Hide empty payment group or provide truthful concise unavailable information; avoid repeated current status in history while preserving timeline facts.
Evidence: redmi/r34-delivered-detail.png, redmi/r34-orders.png

### R6634-C05 — Remaining acceptance matrix is not device-qualified
Parents: R6633-D06, R6633-D14, R6633-D06-G-V03, R6633-D06-G-V08, R6633-D06-G-V09, R6633-D06-G-V07-C3. Coverage gap, not a reproduced failure: complete Bulk-specific paths, every editable lower field/validation/back case, Edit basket scroll matrix, publisher rapid-switch frames, physical-device enlarged text and collected/partial receipt states using labelled fixtures. Existing local passes do not imply this entire Redmi matrix passed.
Evidence: redmi/r34-address-keyboard.png, redmi/r34-return-reason.png


Evidence archive SHA-256: b97036ace077a798bb571099b0197967dac768995c7c136292a7c0a07144edf2. Previous archive entries preserved byte-for-byte. Source implementation is unchanged after qualification; this update records evidence only. No integration into Codex/Store or main performed.

### Founder-authorized recurrence prevention gate — 23 September 2026

Scope: gate setup only, before any R6634 child implementation. Actor is Cursor Buy; launch-supporting reliability work prevents repeated founder-visible defects and false closure. Reuse the permanent founder-repeat regression entry, current owner check and existing review APK wrapper. No application, Store, backend or other-worktree changes; no APK and no child fix authorized by this setup.

Root cause: host test counts and broad partial acceptance did not prove each affected route/state; review-only provider boundaries and visual checks were conflated with complete acceptance. Permanent REG-20260807-058-REPEATED-FOUNDER-NAVIGATION-DIRECTIVE-NOT-GATED now also records this Buy recurrence, retaining its original evidence and gates.

Mandatory machine gate: `scripts/check-buy-founder-regression.py`, ledger `config/buy-founder-regression.json`. The 5 open children have 64 explicit route/state cells linked to founder requirements and retained r66.34 evidence. No test or device pass has been fabricated. `selected` is deliberately empty: the next authorized implementation must select exact ticket(s), name behavior tests and preserve reproduction evidence before editing. Tests may be added in the preparation step; runtime fixes require the implementation gate. Old records remain in the existing handoff/archive.

- Implementation rejects missing selection, missing original reproduction, unnamed behavior tests and deleted/weakened original scenario cells.
- Pre-commit rejects application deltas outside the declared affected owners and requires exact, non-skipped Flutter machine-log success for every selected scenario, bound to current source bytes.
- The existing APK wrapper invokes the same local-evidence gate before building. It does not require future device proof before a review APK can exist.
- Closure additionally requires each scenario's current-source Redmi evidence, screenshot and hierarchy hashes, built and pulled-installed APK hashes matching, visual inspection, separate recorded founder approval, no open children and no unresolved dependencies.
- A coverage gap remains open. A backend dependency cannot be called a completed frontend journey. A partial improvement cannot close its parent. Historical screenshots or unrelated passing tests cannot substitute for an exact scenario.
- These gates enforce evidence and completeness, not an impossible guarantee of zero future bugs. Human visual judgment and truthful evidence collection remain necessary. Raw filesystem writes are not intercepted; the mandatory workflow boundaries enforce the contract.

Commands: `python -B scripts/check-buy-founder-regression.py --phase setup|implementation|pre_commit|build|close`. Obtain current input fingerprint with `--phase setup --fingerprint`. Run regression self-tests with `python -B scripts/test-buy-founder-regression.py`. Local evidence uses the Flutter `test --machine` JSON event log, exact test name, file hash and source fingerprint; device entries additionally identify Redmi TG8HCYTGGQT885OF, retained APKs, PNG/XML, visual review and outcome. Keep original evidence immutable and add new attempt records. Do not weaken expected outcomes to match an implementation.

Validation: 21 focused gate tests passed (including wrong APK/device, missing visual approval, skipped or unrelated tests, stale source, removed scenarios and open children). Both PowerShell hooks parsed. Existing permanent regression checker passed 4,616 entries / 2,550 applicable. Setup and metadata pre-commit pass; implementation/build deliberately fail with no selected ticket. Application source/tests and installed r66.34 are unchanged.

### Authorized child implementation and local qualification

Founder selected R6634-C01 through C05 for implementation/local testing only. Actor: Buy shoppers and trade buyers. Launch-supporting corrections reuse existing Store/product cart callbacks, identity presentation, checkout summaries, tracking and Chat header. Exact owner lists and 64 required route/state scenarios are in the founder ledger; no new provider/model workflow, Store worktree edit, APK or device acceptance. C01-C04 repair retained failures; C05 prepares and executes local state/keyboard/receipt coverage. Sequence: reproduce focused failures, apply smallest frontend corrections, verify all selected local scenarios and affected regressions, inspect actual local screens, record residual children. Preserve identity validation, legal names, payment authority and all original Redmi evidence. Device-dependent closure remains blocked until a later authorized Redmi replay and founder approval.

### R6634-C06 — Cart → Offers reported to open the main-actions menu

Status: OPEN, founder-reported; reproduction pending. Registration-only authorization received during C01–C05 local qualification. Actor: buyer moving from Cart to Offers; launch-supporting navigation reliability. No implementation selected. Reuse existing Buy Offers/main-menu callbacks; no new screen or backend requirement inferred.

Untouched Redmi capture at 15:19 on 23 September shows the MoolSocial main-actions screen (Social, Shop, Food, Travel, Care, Work). The preceding tap was reported by the founder and was not captured. Installed package remains `com.moolsocial.app.cursorreview`, r66.34 / 2026092301. Two narrow replays, Shop → scoped Cart → Offers and Offers → combined Cart → Offers, both opened Offers correctly. Root cause is unconfirmed; do not blame the backend or infer an accidental founder tap. No source fix, install, purchase, message, sign-out or restart performed. Existing 4 items / ₹2,120 combined basket preserved; final screen Offers.

Expected: every visible Offers tap opens Offers within Buy; the main-actions menu appears only after its own explicit action. Future acceptance must cover scoped/combined baskets, current rail positions and scroll state, quick successive taps, visible target hit bounds, Back restoration and unchanged basket contents. Capture the transition when it recurs before assigning a cause.

Evidence: `apps/mobile/build/review-candidates/cursor-buy-r6634-20260923/redmi/cart-offers-registration-151911/registration.json`, original `01-current.png` / XML and two Cart/Offers PNG/XML replay pairs. Initial PNG SHA-256 `beda28a4d0c59208cc46c97ea6ddda01187b8b9064e03d12a1d54a9804bb5da7`. Registration archive destination: `children-local-20260923/redmi-cart-offers/` in the retained R6634 evidence ZIP. This record does not close or expand the five-child implementation goal.

Founder follow-up: R6634-C06 is queued for implementation after the current C01–C05 batch completes. Reproduce and establish the cause before changing navigation; no speculative fix. Current batch remains implementation/local qualification only. This new authorization does not mark C06 reproduced or resolved.

### C01–C05 local implementation result — 23 September 2026

- C01: both Store catalogue variants show the existing Cart whenever any basket has items. If the current Store scope is empty, the same Cart callback opens the combined basket; otherwise the original scoped behavior remains. Quantities and return routes are retained. Shop/Wholesale Visit Store, Recently viewed and Offers entry routes each pass opposite/same/mixed/last-content checks.
- C02: retained orders without line snapshots recover the generated Store display identity only when every persisted SKU proves the same Store. Actual supplier names and stored conversation identity remain unchanged. Order-chat subtitles use the order reference; the existing expandable context retains full details. New/retained order names and chat have explicit normal, long-name and enlarged-text checks.
- C03: the existing Wholesale trade-pack summary now lives inside its shipment. The generic duplicate product/subtotal row is omitted only for Wholesale. Pack quantities, protection facts, totals and payment behavior remain. Checks cover explicit Bulk classification, multiple Stores and long provider text at 200%.
- C04: historical tracking renders Payment only when payment facts exist. The order-history status has one semantic owner: the progress indicator retains live announcements; the duplicate visible status/percentage row is excluded from semantics. Paid/balance information and tracking timeline facts are retained.
- C05: local checks cover Bulk Cart → address → payment → review → Edit basket, lower address field/invalid PIN and keyboard visibility, scrolled baskets, rapid publisher switches, correlated collection receipt and delivery-problem reporting. These are labelled local provider fixtures, not live fulfilment. Routes without an editable field have Back/cancel checks; no artificial keyboard field is added to a receipt. Itemised partial-receipt provider outcomes remain deferred and are not claimed verified.

All 64 exact founder-matrix scenarios passed against source fingerprint `a59838acb52c4de37a59310df4f8c976fbc67a4d3b9adf61dfcaa28b7f20d970`; receipts are in the founder ledger. Static analysis of the 12 modified Dart owners passed; the final semantics-only adjustment separately passed analysis and the same 64-case matrix. Actual local Flutter screenshots were captured and inspected for Cart visibility, Store-name wrapping, consolidated review and empty-Payment removal. Source formatting and whitespace checks passed. The broader regression result is recorded below when complete.

Status is `local_passed`, not `closed`. No new APK was built or installed. C01–C05 still need their mandatory current-source Redmi scenario evidence and separate founder visual acceptance before device closure. C05 additionally retains its partial-receipt provider dependency. The only new Redmi work in this batch was the separately requested C06 capture/reproduction registration on the unchanged r66.34 build. No new confirmed child failure was found in the completed exact local matrix; C06 is an additional founder report with cause still unconfirmed.

The local evidence log lives under `apps/mobile/build/review-candidates/cursor-buy-r6634-20260923/children-64-final-machine.jsonl`; the durable ZIP also stores its exact bytes. On a fresh checkout, restore archived local evidence to the recorded build path before running the evidence gate. Existing protected reference captures were not regenerated or accepted by these tests.

Final additional regression results: children-local-final-machine.jsonl: 734 passed / 1 skipped; children-chat-final-machine.jsonl: 163 passed / 0 skipped; children-progress-final-machine.jsonl: 95 passed / 0 skipped; children-64-final-machine.jsonl: 64 passed / 0 skipped. The skipped legacy cases are not counted as acceptance; all 64 mandatory matrix scenarios ran without skips. No failures.

Evidence archive extended only under `children-local-20260923/`; every previous ZIP entry was verified byte-for-byte unchanged. Original wrapper SHA-256 remains recoverable from prior commit c43c1d6d and the local original archive copy. Current ZIP SHA-256: `ea603a5a24a8ea3586ee6aa1bd709c5ff877cf09eec3e446ca59b5752c4bd572`. The founder ledger reproduction wrapper hashes were updated to this verified append-only archive; original Redmi reproduction contents were not changed. All current-source local receipts retain their original machine-log SHA-256.

### C06 authorized implementation/local testing

Founder authorizes C06 implementation and local tests. Buyer Cart → Offers is launch-supporting navigation reliability. Reuse existing Buy route callbacks, root/nested Cart and the production router harness; preserve all basket scopes, identities and explicit main-menu/Back behavior. Owners: buy_v2_screen.dart and existing scoped_cart_checkout_dock_continuity_test.dart. No shared Store contract, backend, APK, other-worktree or general navigation redesign. First reproduce against production routing, then apply only the demonstrated root-cause correction. Acceptance includes Shop/Wholesale/Offers/Store Cart entry, rapid taps and pending route-return frames, exact Offers URI, no main-actions navigation, retained baskets and impacted prior founder regressions. Device acceptance remains pending; original C06 device report is reproduction-pending.

### C06 local investigation — unresolved, no runtime correction claimed

18 production-router cases cover Shop, Wholesale, Offers, nested Visit Store Cart, Cart pushed over the main-actions page and Offers Cart pushed over that page; each checks a settled tap, rapid repeat tap and a tap during checkout → Cart return. All reach the visible Offers screen and its actual GoRouterState URI, preserving basket quantities. Earlier two Redmi replays also did not reproduce the reported unexpected main-actions screen.

Two test-harness issues were corrected: a Back from nested Store Cart temporarily covers the rail with the Store sheet, so the pending-return case now exercises the real checkout → Cart return control; pushed GoRouter routes keep the base URL in routeInformationProvider, so the visible route assertion correctly uses GoRouterState.of the mounted Buy screen. Neither harness failure reproduced the founder defect. No application code changed and no root cause/fix is claimed. The new regression tests are retained; C06 stays OPEN with reproduction pending. An asynchronous question asks which entry surface and popup/keyboard state preceded the founder's tap. Do not close C06 on these passing replays. No APK, device change, Store contract change or policy change in this investigation.

C06 investigation verification: 82 exact scenarios passed (64 existing + 18 C06), none skipped; static analysis of the sole changed Dart test file reports no issues. Runtime source is unchanged from 97c71953. Updated source/test fingerprint: `41fd728587c071415e50bb31cdade8670adfcc3f7a4f133c0f06e1ae64f6ca01`. Evidence appended at `c06-investigation-20260923/`; all 402 earlier archive entries were verified unchanged. Current ZIP SHA-256: `1739a1530f188e838f886ecd7e3fb3b13694e5d47350ee32b0c49ae15b01ef91`. Original diagnostic harness failures are retained separately; only the completed 82-case machine log supplies local receipts. C06 remains OPEN: these tests qualify existing behavior and do not prove the founder-reported failure fixed.


### C06 forensic replay and founder-authorized legacy route retirement

23 September: founder explicitly confirms PersonalMoolRootV2 is legacy and authorizes its removal. Buyer navigation reliability is launch-supporting. Existing r66.34 Redmi replay reproduced Cart -> Offers -> Android Back -> full-screen main-actions menu; the retained historical app log contains KEYCODE_BACK at 15:17:04 before the original 15:19 screenshot, but does not prove the original complete tap sequence. No direct Offers-tap failure is claimed reproduced.

Smallest complete change: remove the legacy screen from the production router, redirect retained /app/mool links to existing Buy home, and prevent root Buy Back from routing into a redirect loop. Preserve pushed-route return, explicit Store-dashboard return, compact global navigation and basket state. Reuse existing router, Buy screen and continuity tests; no new screen/provider. Historical isolated widget tests remain historical evidence, not an active production entry point. Exact additional owners: apps/mobile/lib/features/journey01/journey_router.dart and apps/mobile/test/ui_v2/buy/buy_route_continuity_test.dart. No authentication, Store data, payment, manifest, other-worktree or backend changes. This shared routing delta must be included in the later Codex integration handoff; integration remains postponed.

Acceptance: legacy links with/without origin, Cart/Offers/Back with retained basket, root exit without redirect loop, pushed return, search Back, compact Store navigation, and all existing founder matrix cases. New local tests cannot close Redmi acceptance before a successor APK. Existing physical replay evidence is under redmi/c06-forensics-162951. Device data and baskets are preserved.


### C06 production-route retirement: local result

Removed the production import and mount of PersonalMoolRootV2 (61-line route block). Retained /app/mool links resolve to /app/buy?sub=shop, including origin-query links. Root Buy Back requests native exit instead of routing through a retired menu and back into Buy; pushed-route return and the validated Store-dashboard return remain intact. Standalone Buy fallback follows the same exit behavior. The old widget file remains only for historical isolated tests; it has no production importer. No shared global-navigation implementation was deleted.

All **87 mandatory cases passed**, no skips, against source/test SHA-256 `f4be21ad89c10267bebd599f6e701fc716478c2455918131f696dc6856c46a3c`. The 18 C06 Cart/Offers scenarios now also exercise Android Back and preserve basket quantities. Five additional scenarios cover legacy links/repeated native exit and compact Work access. All **16 route-continuity tests passed**, including pushed Social return, search Back, persisted destination, router refresh and cold launch preservation. Static analysis of all four affected Dart owners passed. No further confirmed application child defect in these local checks. C06 is local_passed, not device-closed; direct Offers tap alone remains an unproven original trigger.

The first diagnostic run exposed an accidentally changed unrelated cold-launch assertion; it was restored before final passing tests. Two pre-existing gate self-tests assumed an empty initial ledger; their negative test inputs now explicitly clear selection/name. All 21 gate self-tests pass; checker requirements were not weakened. Exact owner admission adds only journey_router.dart and its existing continuity test. The latter moves from the historical September 13 Cursor claim to this current founder-authorized C06 claim. No other checkout was changed.

Device forensic PNG/XML and sanitized report plus final local logs are archived under c06-retirement-20260923/. All 407 previous ZIP entries were byte-verified unchanged. Archive SHA-256 `7a3d19a6003ade49229f644d8b819ee0e93ad8c8bca7a9282879dab2ef344bc5`. Raw app logs containing session-specific diagnostic URLs remain unshared; the report includes only relevant Back-key excerpts. Device restored to Offers with four basket items; no new APK built/installed. Shared router delta must be reconciled by Codex at postponed integration. Test the successor APK on Redmi before closure.


### Six-ticket impact audit — 23 September 2026

Founder asks whether C01-C06 frontend is production-grade and to inspect impacted/child defects. All six retain local_passed status and current-source 87-case receipts. C05 is a coverage ticket, not a sixth independent feature fix; real-device coverage and itemised partial-receipt provider outcome remain pending. C06 direct Offers-tap causation remains unproven; its reproduced Back variant is covered. Do not claim complete frontend production qualification or device closure.

Additional focused execution: Buy router + Chat exact-return suites **11 passed / zero failures**. Shared legacy navigation suite selected by Home: **1 passed / 3 failed**. Three failures require the now-retired PersonalMoolRootV2 or mool-home-family-work target. Registered **R6634-C06-A01 — shared navigation regression contract migration** (OPEN), linked as a C06 child in the founder ledger. Owner: apps/mobile/test/ui_v2/universal/uaw_personal_mvp_global_mool_navigation_c02_test.dart. Confirmed failing tests: ["Home is the fixed six-family entry owner without a dock", "direct Home origin Back uses the safe Ride default fallback", "Home main action keeps route history back to fixed Home"]. Other shared router tests reference the same retired page; their migration scope needs inventory. This is confirmed test-suite fallout from the approved retirement, not evidence to restore the old menu or a confirmed new user-visible defect. Preserve independent compact navigation, origin Back, Store/Work access and basket checks when updating expectations; no skips or weakened checks. Registration only in this audit; no application changes.

Existing C01-C05 local matrix covers scoped carts, Store identity/chat, consolidated Wholesale review, payment/history clutter, Bulk/validation/keyboard/receipt fixtures. No new customer-visible defect found in the bounded additional router/chat checks, but this does not certify untested surfaces. Remaining acceptance: resolve this child, then current-source Redmi matrix and founder visual review; backend-dependent partial receipt separately deferred.

Evidence: six-child-impact-audit-20260923/ in the retained R6634 ZIP; all 422 previous entries byte-preserved. New archive SHA-256 `7f25816a0f16ac9d1765ec65be3c5a4b8c9c88da411bb09a698f25ff6bbef66e`. Existing 87-case passing receipts remain unchanged; failing audit logs are never used as passing acceptance evidence.

### Founder registration update: Compare prices and populated Offers — 23 September 2026

Authority: current founder request, "register defect ticket now, also register a ticket to show real test data in offers in moolsocial and supplier in offer" (Annotation 1). Registration only. Reuse the existing R6633-D05 defect and R6633-D06-B data work package instead of allocating duplicate defect or REG numbers. Neither record is selected for implementation by this update; current machine selection and all prior acceptance evidence remain unchanged.

#### R6633-D05 — Compare prices has no comparative results

- Status: OPEN / provider integration dependency. Existing reproduction: the retained r6633-compare-D05 evidence and r66.34 redmi/r34-compare.png; Refresh cannot supply a missing comparison provider. No new device observation is claimed.
- Actor/capability/outcome: public Buy customer compares eligible Retailer/Grocery Store offers for the same canonical product, variant and pack, identifies the supplying Store, and returns to the exact product or Cart without losing quantities or context.
- Classification: mvp_required for the exposed comparison capability in the connected Store-to-Buy launch journey. Test-only qualification is mvp_supporting and cannot close the live-data dependency.
- Reuse assessment: reuse BuyV2ComparisonSource and comparison query/result contracts in apps/mobile/lib/features/buy/buy_v2_content_contracts.dart, the session in apps/mobile/lib/features/buy/buy_v2_session.dart, and the existing comparison sheet in apps/mobile/lib/ui_v2/buy/buy_v2_views.dart. Reuse existing Buy comparison/product tests; inventory their exact executable names before selection. No new screen, route, catalogue or seller-account system is proposed.
- Smallest complete outcome: coordinate the existing Store-origin offer/identity contract, supply comparison data through its existing interface, and preserve loading, empty, missing-configuration, error and retry behavior. Controlled local fixtures may qualify frontend behavior before the real Store adapter is available.
- Acceptance: multiple eligible sellers with distinct prices; correct product/variant/pack matching; stock, minimum quantity and delivery eligibility; explicit price basis and known charges; exclusion of mismatched, expired or stale offers; location/query changes and pagination; failure then successful retry; correct selected seller/product and exact product/Cart return. Verify compact/enlarged-text layout, actual local screens and a separately authorized checksum-matched Redmi candidate.
- Dependencies/exclusions: authoritative Store identities, visibility permissions, current stock/prices and delivery eligibility must be coordinated with the Store owner before shared changes. No invented live prices, production seed data, real orders/payments, manufacturer/distributor workspace expansion, backend deployment or APK authorization is created here. Live acceptance remains pending even if fixture tests pass.

#### R6633-D06-B — Populate MoolSocial and Suppliers Offers with controlled test data

- Status: OPEN / registered test-data and publisher-identity acceptance scope under existing R6633-D06-B. Linked to R6633-D05; its authentic administrator/Store data dependency remains open. This expands the existing recorded work package into an explicit ticket specification, not a second parent defect.
- Actor/capability/outcome: public Buy customer opens Offers, switches between MoolSocial and Suppliers, sees populated offer cards with the correct publisher and supplying Store, opens the matching product and returns without losing filter, Saved or Cart state.
- Classification: mvp_supporting for controlled review/test data, supporting the launch-required Store-to-Buy offer journey. "Real test data" means working, realistic records rendered in the actual native review UI; it does not mean fabricated live sellers or promotion of fixtures into production.
- Reuse assessment and proposed owners: reuse BuyV2PublishedCatalogueOffer / BuyV2PublishedCatalogueSource and publisher identity fields in apps/mobile/lib/features/buy/buy_v2_content_contracts.dart; existing catalogue/session mapping in apps/mobile/lib/features/buy/buy_v2_session.dart and apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart; existing Offers UI in apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart; and apps/mobile/test/ui_v2/buy/buy_v2_offers_visual_review_test.dart with existing provider fixtures. These are reuse/test-only acceptance units; exact mutation claims and test names must be admitted before execution. No separate offer database, duplicate presentation or new account system is justified.
- Smallest complete review outcome: feed controlled, isolated records through existing offer contracts for BOTH publisher types. MoolSocial-published offers must retain their actual supplying Store reference; supplier-published offers must retain the correct supplier publisher and Store identity. Include multiple Retailer/Grocery Store sellers, product/variant/pack IDs, price/unit, stock, offer validity and delivery eligibility, with common matching items reusable by D05 comparison tests. Do not misrepresent a publisher as the fulfilment seller.
- Acceptance: both tabs populate and keep readable labels; publisher filtering and counts are correct; each card opens the right product/variant/pack and seller; supplier details and available Store/Chat navigation retain identity; Saved and Add/Cart retain the correct destination, seller and quantities; loading/empty/error/retry, expired offers, unavailable stock, location change and stale responses are covered. Check long supplier names, compact/enlarged text and Android Back. Show actual local Flutter screens for founder review; device acceptance requires a separately authorized candidate and replay.
- Data boundary: review/test data stays in the existing isolated test/review path and cannot be returned as production public inventory, persisted into real accounts, or used to claim payment/order success. Review provenance must be explicit in evidence. Later Store/admin transport reuses the same contracts and behavior tests; test records are not automatically promoted to live listings.
- Dependency order: agree public Store/publisher contract and permissions; admit exact fixture/test owners; qualify both Offers tabs and comparison fixtures locally; integrate authoritative Store/admin sources later; verify real-data and device journeys before closure. Account provisioning, supplier/manufacturer/distributor workspaces, paid services, production writes and a new APK are excluded from this registration. Shared Store/Buy contract changes require coordination; Store, Counter Sale and CSV work remain preserved.

Carry-forward: R6634-C06-A01 remains OPEN for the three obsolete shared-navigation expectations. C01-C06 retain their recorded local passes, not full frontend production qualification or Redmi closure. C05 partial-receipt backend acceptance remains pending. No legacy-screen removal or additional runtime fix is performed by this registration.

Registration verification: regression memory passed all 4,616 entries using the existing retained EvidenceArchiveRoot; continuation coordination passed for /root, cursor_ui, buy-ready-20260921, 101 claimed owners and registry generation 4616. Earlier phase invocations (task_start, pre_commit without staged changes, and baseline) rejected their phase prerequisites and are not acceptance evidence; the applicable continuation implementation phase passed. No gate was modified. Only this existing ticket/handoff owner is extended; no source, test, machine selection, evidence archive or device data is changed.

### R6634-C07 — Repeated GST details in Cart after payment selection — 23 September 2026

**OPEN; registration only**, child of the existing R6633-D06-G Cart/review journey. Founder reports GST is requested twice for Shop and Wholesale after selecting payment, and explicitly authorizes capturing the currently open Redmi screen. Registered in config/buy-founder-regression.json with seven pending acceptance scenarios; not added to selected implementation tickets.

Actual 17:24 IST screenshot and XML confirm ONE combined Confirm order screen with two separate cards: Shop / Add GST details (off) and Wholesale / Add GST details (on), the latter displaying GST invoice details required and Add. Offers is the selected bottom-navigation tab; the visible basket contains four items / INR 1,636. This is evidence of repeated scoped presentation, not proof that the same GST record was saved twice or that two invoices were submitted. The preceding payment-selection sequence is founder-reported; Shop-only and Wholesale-only sequential re-prompts were not separately replayed. No taps, toggles, fields, payment, basket or app state were changed during capture.

Installed metadata: com.moolsocial.app.cursorreview, 1.0.0-r66.34-cursorreview, code 2026092301, Redmi TG8HCYTGGQT885OF. APK checksum was not reverified for this observation; this is defect reproduction, not acceptance of a new candidate. Inspected source remains fcba2aba7971fa757b15479df6f0e2c701b6dc7f: _CheckoutConfirmStage in apps/mobile/lib/ui_v2/buy/buy_v2_views.dart loops over invoiceDestinations and mounts _GstInvoiceCard for each. BuyV2GstInvoiceController retains destination-specific selections. This explains two visible sections; any broader persistence or payment-return root cause still needs bounded reproduction.

Actor/capability/outcome: public Buy customer provides invoice-recipient GST details once where applicable and reviews Shop/Wholesale checkout without redundant input, while retaining correct per-destination invoice attribution. Classification: mvp_supporting checkout usability/regression correction. Reuse the existing GST controller, card, sheet and checkout composition in buy_v2_views.dart, its buy_v2_screen.dart integration, and apps/mobile/test/ui_v2/buy/buy_v2_gst_session_continuity_test.dart. No new screen, service, tax model or catalogue is proposed. Smallest complete correction must consolidate repeated entry and retain existing validation, optionality, saved-profile behavior and intentionally distinct recipient profiles; do not silently copy one recipient across unrelated invoices.

Seven pending acceptance cells cover combined checkout with the same recipient, Shop-only and Wholesale-only return after payment, payment/Back/review continuity, different recipient profiles, invalid input and persistence failure/retry, and optional GST preference. Check compact/enlarged text, keyboard and exact Cart quantities/payment state; present actual local screens and later a separately authorized checksum-matched Redmi replay. Exact test names, any needed ownership admission, scope-selection assessment and profile-sharing contract must be established before implementation. No runtime fix, build, tax-rule change, backend write or production qualification is authorized by registration.

Evidence retained in docs/quality/CURSOR-BUY-R6634-EVIDENCE-20260923.zip under gst-duplicate-C07-20260923/: founder-open-cart.png, founder-open-cart.xml and DEFECT.json. PNG SHA-256 b1ad2c39407fe2413e970102a38942a87c18aee81e0ccbdf02e2a4b3b739e44d. Archive SHA-256 3b974e1976c188390d3972ff5858ff8b4a16159dc65bd1aeaa2170a3f211fb6a; all 424 previous entries byte-verified unchanged. Ledger reproduction wrapper hashes refreshed; prior local/device receipts and selected tickets preserved. Device regression memory passed (4,616 entries / 482 applicable), and continuation coordination passed before capture. No other worktree changed.

### R6634-C07 founder amendment — Account GST profile and later-cart reuse

Founder requirement (Annotation 1): GST recipient details belong in the user account profile, not repeated entry for every purchase. Provide an invitation to add GST details in Profile; once added, subsequent Shop and Wholesale carts should reuse them automatically. Register frontend scope now and preserve any required backend business logic in Git under the ticket reference for the later Cursor backend phase. This extends R6634-C07 rather than duplicating its repeated-input defect. **Frontend OPEN; backend PENDING; registration only.**

Frontend acceptance: existing shared Profile surface exposes optional GST details with Add when absent and summary/Edit/Remove when saved. Reuse the existing GST sheet for GSTIN, legal name and billing address. Explicitly saving from checkout or Profile updates the same account recipient profile/default; later carts use it without another Add prompt. Keep a compact review summary with an intentional change/opt-out path, and preserve different recipient profiles where deliberately selected. A failed account read is a recovery state, not evidence that the user needs to enter GST again. Do not make GSTIN compulsory for all users. Retain input and truthful save/retry states. No current frontend implementation is claimed.

Source evidence and reuse: BuyV2GstInvoiceProfileStore, its record and snapshot already exist in apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart. The only implementation found in runtime lib is _BuyV2DeviceReviewGstInvoiceProfileStore in buy_v2_session.dart: an in-memory _snapshot with device-review-session:buy-gst scope. BuyV2GstInvoiceController in buy_v2_views.dart restores saved profiles but maintains separate destination selections. Session-local review storage does not meet the new account-persistence requirement. Reuse these contracts and apps/mobile/lib/ui_v2/profile/global_personal_profile_v2.dart after coordinating the shared Profile and existing store-interface owners; this record grants no cross-owner runtime edit. Existing buy_v2_gst_session_continuity_test.dart provides a starting point; name and admit exact Profile/checkout behavior tests before selection.

**Backend continuation reference: R6634-C07 / backendBusinessLogic in config/buy-founder-regression.json — PENDING, required for full closure.** Later backend selection must read this machine-readable block and this handoff. Reuse the authoritative account/profile store; implement authenticated owner-only persistence, validated add/edit/remove and default selection, restore across restart/re-login, account-switch cache isolation and stale-response rejection, truthful failure/retry and concurrent-edit behavior. Bind recipient details to new order/invoice snapshots without rewriting historical invoices on profile changes. Respect account deletion/retention policy and omit private GSTIN/address from diagnostics. No new database provisioning, deployment, tax calculation changes or backend work now.

Scope: signed-in public Buy customer; mvp_supporting checkout/profile continuity. Smallest complete sequence: coordinate shared Profile/account contract and admit exact owners; qualify frontend against controlled account-store fixtures; separately implement and verify authorized account persistence and order/invoice integration; run current-source Redmi and founder visual acceptance. Fourteen total C07 acceptance scenarios now cover the original duplicate cards plus Profile Add/Edit/Remove, later Shop/Wholesale carts, checkout-to-profile continuity, restart/re-login, account switching and failure/retry. All are pending; fixture passes cannot close the backend dependency. Existing C01-C06 evidence, C06-A01 and the Compare/Offers records remain intact. Founder request to retain this in Git authorizes a ticket/evidence commit on the assigned Buy branch; no push or runtime change is included.

### Pending frontend execution and complete Git reconciliation — 23 September 2026

Founder now authorizes implementation and local testing of all pending frontend defects, followed by reconciliation from the previous integration through the final Buy HEAD, clean Git and a complete next-Redmi inclusion inventory. APK building and device testing are explicitly later. Starting HEAD a3781e60c379f0b73f4055b28090bb596093fdff; prior integration 123ff42cf8179b272d33b480e8267dfa83af2de3. Reuse assessment, exact actor/outcome, exclusions, dependencies and test plan are recorded in CURSOR-BUY-PENDING-LOCAL-SCOPE-20260923.json. This continues UAW-CURSOR-BUY-READY-20260921, not an unrelated lane or new backend ticket.

Selected scope: C06-A01 approved legacy-route test migration; C07 existing Profile GST entry and one shared checkout recipient flow; D05 bounded comparison review provider; D06-B MoolSocial and Suppliers review offers. C01-C06 remain in the regression wave. Classification mvp_supporting for the bounded frontend qualification. No new screen, route, account system or backend. Preserve Store/Counter Sale/CSV and all prior evidence. Real Store offers, account-backed GST persistence, payment/logistics and partial-receipt backend outcomes remain pending with original ticket references.

Root primary coordinates exact Profile ownership transfer from the historical September 13 claim and admits existing GST and shared-navigation tests plus one focused pending-defect test. Shared Profile is limited to an optional GST content slot; the existing Buy controller/store contracts and router bind its behavior. No other worktree is mutated. Review-data adapters remain behind the existing review-data boundary; unavailable production providers remain truthful. Failed/stale account reads must not leak recipient state, and duplicate entry must not erase deliberately different recipients. Local checks and native renders precede source/evidence commits. Final Git inventory must contain every commit/owner and an explicit disposition for every original/new ticket; no missing source is excused by local test success.

Implementation diagnostics retained: initial exact-owner admission found the newly claimed pending-defect test absent; creating its real production-isolation tests resolved admission without relaxing owner checks. First focused analysis of five Dart owners compiled and reported three style diagnostics only: two missing if-statement braces in the review comparison adapter and one unnecessary string interpolation in the GST title. No passing analysis is claimed for that run. Prevention: create/read back exact new test owners during preparation, then run normal formatter/analyzer and correct every diagnostic before tests/acceptance. Prior reconstruction oversized output and inapplicable gate-phase attempts are recorded above; bound subsequent outputs and use only the current continuation phase. Evidence-only registry entry records these agent diagnostics before correction/retry.

Pending frontend analysis follow-up: b4ac5d failed on new-test required regionId and nullable product lookup, plus two brace warnings. Recorded under REG-20260923-4646 before correction; no acceptance claimed.

C06-A01 impact expansion: exact seven historical universal test owners admitted to migrate production calls of retired Home to Buy/compact navigation/Chat/security. Preserve standalone historical root widget tests and unrelated Social projection tests. Fifteen-suite diagnostic retained in build/pending-navigation-impact-machine.jsonl; old Social rails/projection and supplier-chat baseline assumptions are separately classified, not new production fixes.

### Final pending-frontend local qualification

Source fingerprint: `b8d08c881787348202b41048b260ad1c5b8103c8a43c022a0216ebe5f40ad5b4`. All131 registered cells passed; 171 actual tests passed with zero failures/skips. Analysis: no issues in19 changed Dart owners. Evidence ZIP SHA256 `a34c6cae6767e834790d0cf3adc40aefcf939abf28a7209581fb4c322a46ea87`; preserved all427 prior entries, appended59 entries including failures, successful machine log, screenshots, historical audit boundary and full integration inclusion manifest. C07 backend remains pending; all tickets are local_passed, none falsely closed. Review data is isolated from production; Profile details clear on sign-out/account changes. Controlled account-store fixtures prove restoration behavior, not real backend persistence. Source/UI acceptance is separate from founder/Redmi approval.

Broad diagnostic run completed before final corrections:14 failures found and all corresponding corrected behavior families re-executed in final acceptance. Additional historical universal audit33 failures included19 retired-route expectations now migrated;14 non-Buy projection/rail/video/chat oracle findings remain preserved outside this bounded Buy implementation. Unchanged Social/navigation owner hashes match pre-retirement97c71953; this is scope evidence, not a claim those old suites pass.

Final owner/dependency reconciliation is in `pending-local-final-20260923/FINAL-TICKET-DISPOSITION.json`: C06-A01 migration has no remaining selected-scope implementation dependency; C07 remaining dependencies are Redmi/founder review and the explicitly deferred account backend. Two pre-existing comparison tests were added to D05/D06-B affected owners after the first pre-commit gate rejected their missing ticket mapping. Machine checks remain unchanged.

### Source and Git reconciliation seal

Source/ticket/evidence checkpoint **`9206c8dba6d7c8202752e1a53ec027e5c7bbd218`**, tree `6192a6f197ead67cbb27b825fe0a7d2301307b15`. The checkpoint was clean (zero staged/unstaged/untracked records) and its raw application/test fingerprint remained `b8d08c881787348202b41048b260ad1c5b8103c8a43c022a0216ebe5f40ad5b4` after commit. All73 commits after prior integration123ff42cf8179b272d33b480e8267dfa83af2de3 are retained and enumerated in the current inventory;18/18 approved inherited tips remain ancestors and rejected tips remain absent. Store/native/dependency owners remain equal to inherited79d54013. The following documentation-only commit binds this seal; its complete HEAD is the next candidate input. No source changes or new test cycle are introduced by the seal.

Local pre-commit gates passed:131/131 founder scenarios, atomic owner admission, current regression-memory binding and authorized MVP scope. Origin was read-only verified atfcba2aba7971fa757b15479df6f0e2c701b6dc7f; no push was authorized/performed. No new APK exists. Backend dependencies and the14 historical Social/projection/chat test findings remain explicitly listed; clean Git is preservation/inclusion evidence, not production acceptance.


## Local visual approval pack - 23 September 2026

Founder requested review before the next Redmi APK. Native Flutter gallery: `apps/mobile/build/founder-review-4e05d9f7/index.html` (52 screens, nine visual groups; C06-A01 is test-only). Source remains `4e05d9f7a07cab0190f0de000c2d6b5b83880158`, runtime fingerprint `b8d08c881787348202b41048b260ad1c5b8103c8a43c022a0216ebe5f40ad5b4`. No runtime owners changed.

Fresh capture checks: C01-C04 46 tests, collection 1, canonical Buy landing 1, C05 recovery 5, plus one targeted proof-card framing check passed. GST/Compare/Offers reuse exact-source r3 acceptance captures. Rejected fontless capture and initial command/compiler diagnostics are retained; only corrected frames appear in gallery. Controlled fixtures are explicitly labelled. Review storage is session-only pending backend account persistence. Real comparison/publication and partial-receipt outcomes remain backend-pending.

Local retained archive (not Git-hosted): `apps/mobile/build/founder-review-4e05d9f7.zip`, SHA-256 `96757a6820df1348028f1d2407ec79dacd82b99acdb97c9699782a3ea8ab34c1`. Manifest lists each review image and checksum. Founder visual approval remains pending. No APK built or installed; no device acceptance or production qualification claimed.


## Founder visual feedback batch 1 - 23 September 2026

Registration only. Founder explicitly requested recording the following two defects and waiting for the next batch of inputs. Neither ticket is selected for implementation. No runtime/test/selection/APK changes are authorized by this registration. Existing local technical evidence remains historical evidence, not visual approval of these rejected details. These open items must be reconciled before qualifying the next Redmi candidate.

### R6634-C08 - Compare prices header consumes excessive vertical space

- Status: OPEN / awaiting next founder input batch; frontend UI. Parent: R6633-D05.
- Actor/outcome: Buy customer comparing matching offers should see comparison results immediately below a compact title/product summary. Classification: mvp_supporting, readability of the launch comparison journey.
- Founder evidence: comparison-sheet screenshot attached in this conversation, showing the separate Refresh comparison text row and the multi-line incomplete-ranking warning. Current-source reference: apps/mobile/build/founder-review-4e05d9f7/screens/comparison-populated.png (gallery manifest records checksum).
- Required change: replace the Refresh comparison text/button row with a discreet icon in an appropriate existing header position; remove its visible text and dedicated vertical row. Remove the visible warning "Complete price ranking is unavailable. No lowest-price result is confirmed." and its reserved spacing, including when that ranking condition comes from the backend. Move offer results upward by reclaiming this space.
- Reuse/owners for later selection: existing comparison sheet in apps/mobile/lib/ui_v2/buy/buy_v2_views.dart; existing comparison data handling in apps/mobile/lib/features/buy/buy_v2_session.dart. Reuse focused comparison tests in apps/mobile/test/ui_v2/buy/buy_v2_pending_defects_20260923_test.dart and apps/mobile/test/ui_v2/buy/buy_v2_product_continuity_test.dart. No new screen/provider/backend is needed for the presentation correction; exact mutation claims and acceptance test names must be admitted at selection.
- Acceptance: compact header with icon-only refresh; no refresh-text row or ranking-warning gap in ready/partial backend results; cards visibly start higher; refresh remains accessible via tooltip/semantic label and usable hit area; loading, empty, failed/retry and stale response behavior still work; truthful prices and ranking metadata retained without inventing a lowest-price claim. Verify narrow width and enlarged text, product/cart return and new founder screenshots before Redmi replay.
- Backend: no business-logic implementation selected. The UI requirement also applies to backend-supplied incomplete-ranking status; provider completeness/price correctness must not be falsified to hide the warning. Actual load errors and empty states remain meaningful and compact.

### R6634-C09 - Remove decorative boxes around Buy utility icons

- Status: OPEN / awaiting next founder input batch; frontend UI. Related: R6634-C06 navigation and R6633-D06-B Offers.
- Actor/outcome: Buy customer sees natural, unboxed category/menu, filter, Save/bookmark, Profile and Location icons, while existing actions remain clear and tappable. Classification: mvp_supporting, consistent commerce navigation.
- Founder evidence: four attached crops show the boxed category/menu, filter, saved-items badge, and Location/Profile controls. Current-source references: gallery Offers captures and c06-buy-home-review.png in apps/mobile/build/founder-review-4e05d9f7/screens/.
- Required change: remove visible enclosing outlines, filled tile/circle backgrounds and raised/shadowed containers from those utility icons wherever applicable within Buy home/Shop, Buy Store pages, Wholesale, Offers and their related Buy surfaces. Cover category/menu, filter, Save/bookmark (including product-card save actions where the same box treatment exists), Profile and the adjacent Location control. Preserve the icon itself, existing counts/badges, selected/filter-active meaning, action and placement unless later founder feedback says otherwise.
- Reuse/owners for later selection: existing Buy controls in apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart, buy_v2_screen.dart, buy_v2_design.dart and buy_v2_views.dart. Audit actual shared callers before edits; reuse existing controls rather than add another icon system. Relevant existing tests: apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart, buy_v2_offers_visual_review_test.dart and buy_v2_scoped_cart_checkout_dock_continuity_test.dart. Exact per-file ownership and regression cases are to be confirmed at selection.
- Boundaries: Buy-facing Store/product screens are included; no independent Store operations, Counter Sale, Social, authentication or locked-screen redesign is implied by "anywhere applicable". Avoid changing unrelated product cards, payment controls or bottom navigation containers solely because they are boxed.
- Acceptance: no decorative icon boxes on the listed Buy controls; sufficiently large invisible tap targets, tooltips/semantics, focus feedback, contrast and count badges retained; category/filter/saved/Profile/Location navigation and Back return remain intact; no overlap at narrow widths/enlarged text; comparison with the supplied crops and fresh native screenshots for founder approval.
- Backend: none expected for this visual change; preserve all existing permissions, account/region selection, save state and data wiring.

Next action: WAIT for the founder's next batch of feedback. Do not implement C08/C09, rerun runtime tests, change approval status, or prepare/install an APK as part of this registration.


## Founder visual feedback batch 2 - 23 September 2026

Registration only, continuing the founder's instruction to collect defects and wait. C08/C09 remain open. The seven additional records below capture all supplied requirements, including the two separately numbered "4" points. The trailing "7." has no requirement yet; do not invent one. All records: OPEN, NOT SELECTED, implementation/local tests/new visual approval/Redmi acceptance PENDING. Preserve existing technical evidence; no new approval or APK authority follows from these screenshots.

### Read-only check against latest available local Codex Store checkpoint

Checked local branch work/codex-ui/add-product-screen1-20260920 at e5abc55b1808bc4aac7e5c39d37177ec1e6fe168 (23 September 2026, 19:21 IST), and its docs/quality/CURSOR-STORE-PUBLIC-DATA-HANDOFF-20260922.md plus STORE-PUBLICATION-FRONTEND-20260922.md via Git objects. The central ACTIVE-CODEX-HANDOFF.md is older and is not treated as the latest Store contract. No other worktree was changed, no message sent, and no pull/merge performed. This is a verified local checkpoint, not a claim of remote freshness or another agent's live confirmation.

The Store handoff explicitly supplies Store ID/name/full address/region/contact/business identity from existing Store identity and one-time Business details. Buy must join on Store ID, never display name. Canonical product/SKU/variant/pack/category and retail/wholesale offer facts must match the same Store projection. Product description/highlights/specifications use BuyV2ProductContentSnapshot via the Store content adapter, not invented Buy copy. Store publication/readback into the live public source remains backend-dependent. Recheck the latest handed-off checkpoint and coordinate shared-owner changes at implementation/integration time. Do not import the whole Store branch as part of visual feedback registration.

### R6634-C10 - Use authoritative Store name as Store-page heading; raise products

- Founder point 1. Actor: customer opening Visit Store. Classification: mvp_supporting, clear seller identity and visible products; identity correctness supports the launch commerce contract.
- Replace the generic "Store products" heading with the actual Store display name. Apply the same principle to corresponding supplier/wholesale Store headings where applicable. Reclaim redundant header space and bring the SKU list upward; do not merely rename the inner card while retaining the generic heading.
- Data acceptance: heading, Store identity card and public SKU seller must resolve to the same authoritative Store ID and Store workspace name. Test Store-name changes, long/multiline names, missing/loading/error identity, and two Stores with identical display names. No private Store fields or hardcoded review name may become a production fallback. Brand-specific pages retain their distinct brand semantics.
- Reuse: existing supplier/Store sheet and current product seller/storeId mapping in apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart, plus existing models/session/public contract in apps/mobile/lib/features/buy/. Source currently computes literal "Store products" / "Supplier products" in that sheet. Reconcile exact Store adapter contract against the checkpoint above before selection. Backend publication/readback remains explicitly pending when a live source is absent.

### R6634-C11 - Compact, content-adaptive Store identity card

- Founder point 2. Actor: customer viewing Store details above SKUs. Classification: mvp_supporting.
- Remove unused card space; make card dimensions adapt to actual Store name and available identity/details. Short names must not create a tall empty card; long names/details must wrap naturally without clipping, huge blank rows or overlapping Ask/other actions. Preserve truthful address, role and useful available details; do not invent content to fill the card.
- Reuse existing Store identity/truth panel and layout in apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart. Coordinate with C10 and C14 so the overall header is compact and SKU content moves upward. Verify short/long/missing data, narrow screen, 200% text and Ask/Back continuity. No new backend expected for layout.

### R6634-C12 - Reduce oversized rounded Add-to-cart control

- Founder point 3 and tomato screenshot. Actor: customer adding a Store SKU. Classification: mvp_supporting.
- Replace the oversized full-width rounded Add strap with the compact Add treatment used on Buy home; carry consistent compact treatment across applicable SKU cards. Do not misinterpret this as removing the persistent Cart shortcut fixed in C01.
- Reuse existing Buy home product Add/quantity control. Preserve practical invisible touch target, quantity stepper states, feedback, stock limits, pack/MOQ rules and basket scope. Verify Shop/Store/Wholesale/Offers additions and returns without changing price or quantity semantics. Proposed owners: existing product card/control builders in buy_v2_catalogue.dart and buy_v2_screen.dart; exact claim set at selection. Frontend only.

### R6634-C13 - Remove unused SKU-card space across Buy surfaces

- Founder first point 4, including rice and tomato details. Actor: customer browsing products. Classification: mvp_supporting.
- Tighten unnecessary gaps between image, product name, variant/pack, price/unit price, minimum quantity, seller/delivery and Add controls. Content should remain comfortably readable but compact. Remove empty reserved rows/space when optional facts are absent. Apply consistently to Buy/Shop, Store, Wholesale/Bulk, Offers, category and SKU views wherever the shared treatment appears.
- Reuse existing product-card layouts and content models; inspect shared callers rather than duplicate layouts or hide required details. Avoid globally fixed heights or truncating long names, trade terms, pack/minimum/order totals merely to shrink cards. Preserve image proportions, exact Store/SKU/variant/pack binding, prices and scroll/cart continuity.
- Verify short/long content, absent facts, stock/delivery variations, single/multi-column layouts, narrow/enlarged text and applicable accessibility checks. Proposed UI owners: buy_v2_catalogue.dart, buy_v2_screen.dart, buy_v2_views.dart. Layout-only; source-data defects remain separately referenced rather than fabricated.

### R6634-C14 - Smaller gradient Store cards with explicit Visit/Browse CTA

- Founder second point 4 and Other stores screenshot. Actor: customer choosing another Store. Classification: mvp_supporting.
- Give Store discovery/Other stores cards a gradient treatment, reduce excess padding/card height, and provide a clear textual Visit or Browse call to action instead of relying on an unlabeled arrow alone. Keep Store name/essential facts readable; adapt to content length. Coordinate primary Store-card styling with C11 where the same card pattern applies.
- Reuse existing Store-card widget and project gradient tokens in buy_v2_catalogue.dart / buy_v2_design.dart. CTA must open the exact selected Store ID and its products, retaining basket and correct Back return; never route by display name or arbitrary preview SKU. Verify gradient contrast, long names, enlarged text and the related Store-entry regression tests. Frontend only; real Store data dependency follows C10.

### R6634-C15 - Keep blue scroll-position dot; remove vertical rail line

- Founder point 5. Actor: customer gauging browsing progress. Classification: mvp_supporting.
- Remove the metallic/charcoal vertical line while retaining the blue ball. Cover Buy/Shop, Wholesale/Bulk, category, Store, SKU, Store category and Offers wherever this vertical indicator is used. Do not remove the entire indicator or leave a fixed decorative dot: dot position must continue to follow the current vertical scroll extent, including top/middle/bottom and content-size changes.
- Reuse BuyV2VerticalScrollIndicator in apps/mobile/lib/ui_v2/buy/buy_v2_design.dart and existing callers. Preserve vertical-only metrics; nested horizontal rails must not move the dot. Avoid double native tracks, lost touch access, text overlap or capturing product taps. Check zero/short/long content, pagination, sheet scrolling, resize and enlarged text; maintain existing gesture behavior if supported. Frontend only.

### R6634-C16 - Unbox delivery and Wholesale/Bulk selectors

- Founder point 6 and Quick/Scheduled screenshot. Actor: customer switching product channels. Classification: mvp_supporting.
- Remove the enclosing/boxed segmented-control treatment around Quick and Scheduled on Buy, and Wholesale and Bulk on Wholesale, to give the selectors a freer, less squeezed layout. Keep labels/icons legible, active selection clear, and touch/focus semantics intact; coordinate with the utility-icon treatment in C09 without treating these text selectors as icon-only controls.
- Reuse existing selectors in apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart and established design tokens. Presentation change only: preserve exact Quick/Scheduled and Wholesale/Bulk eligibility, source-provided saleType, filters, baskets and Back/return state. Do not infer fulfilment or Bulk from delivery copy/MOQ, as prohibited by the latest Store handoff.
- Verify every selection, repeated/rapid switching, narrow and enlarged text, loading/empty results and return from Store/SKU/cart. No new backend business logic; unresolved source eligibility dependencies remain tracked in the existing Store/Public handoff.

Batch evidence: six founder-supplied crops in this conversation (Store header/identity card, Add control, SKU details, Other stores cards, vertical line/dot, Quick/Scheduled selector). Corresponding current-source local references are the C01/C03/Offers/Buy-home groups in apps/mobile/build/founder-review-4e05d9f7/manifest.json. Exact tests/owner claims must be admitted when implementation is selected; no regression IDs or test passes are invented here. Read-only discovery attempted a nonexistent Store contract filename; no data or source changed, and actual contracts were then located through the verified Store Git handoff.

Next action at registration: WAIT for further founder input. C08-C16 remain open and must not be omitted from next-candidate reconciliation. No runtime edits, tests, merge/pull, commit/push or APK actions performed for that registration batch. Founder subsequently confirmed point 7 is empty.

## Founder implementation authorization and standing impact rule - 23 September 2026

Founder now selects C08-C16 for implementation/local testing and fresh native screenshots for visual approval. All 19 post-Redmi ticket entries remain in the cumulative acceptance matrix. Git checkout/reconciliation, APK preparation/install and device replay are later phases after founder review; do not commit/push/build/install during this implementation batch.

Standing rule for ALL tickets and future continuations: inspect impacted callers and child defects during implementation, after focused tests and before local acceptance. Register every newly observed defect with its parent, reproduction, root cause, affected owners and named regression. Fix authorized affected behavior, rerun the child and impacted parent/neighbor cases, and leave any externally blocked child explicitly open. A passing parent test never hides an unresolved child or qualifies an untested route. Apply this rule to all 19 tickets and retain it across chats.

Plan: select the nine registered requirements and existing shared UI/test owners; implement compact comparison/Store/product presentation and unboxed controls; verify actions, source identity, accessibility, scroll/Back/basket continuity and all existing ticket scenarios; capture exact-source native screens. No new screen/provider or unrelated Store/Counter Sale/backend edits. Reviewed Store source contract remains e5abc55b; real publication/account persistence dependencies remain pending.

### Independent reconciliation: 12 requirements, not nine defects

Founder explicitly requested one independent sub-agent audit after correcting the count. Read-only audit `/root/reconcile_buy_defects` confirms points1-7 map to C10-C16, points8-11 are FOUR separately verifiable requirements grouped in C08, and point12 maps to C09. Point13 is an instruction. Thus12 new requirements /9 grouped tickets;19 is only the selected ticket-entry count (10 historically locally qualified plus9 current), never the complete backlog. Historical131 scenarios/171 tests bind fingerprint b8d08c... and require current-source impact replay after these changes.

Older open workstreams omitted from the former total: account-bound collection D07; assignment/schedule D08/D08-C1; stable shipments D09/D09-C1; live maps/delivery D10/D10-C2; online payment D11; PO issuance/buyer approval/supplier acceptance/communication D17. These are9 overlapping references across6 workstreams; D17 is NOT backend-only. D05/D06-B live data, C07 persistent accounts and C05 partial receipts remain dependencies within already-counted tickets. Fourteen historical Social/projection/rail/video/chat findings remain unqualified test findings, not14 confirmed independent customer defects. Original22 tickets and37 older replay records overlap the current batch; their77 combined literal IDs are not a valid unique-defect total. Historical inventory text saying eleven tickets or r66.32 is not the current aggregate. Preserve records and classify every dependency before next APK qualification.

### Active child/impact findings for the visual batch

Founder follow-up during native-screen review: Store name is duplicated between the heading and details card. C10/C11 acceptance now requires one visible Store-name heading; remove the repeated name from the details card while preserving Store identity semantics, type, address and Ask. This refines the existing requirement, not an additional count. Rerun compact/enlarged and same-ID rename checks and refresh screenshots before approval.

Further founder review: consolidate Store heading, identity/details and empty-product presentation into one compact card. Use an accessible partnership icon in place of the large partnership text; keep Store name once, address/type, Ask/Close/Browse and delivery/status access. Empty products becomes inline text, with no separate large box. This remains C10/C11/C13 refinement. Prior screenshots and local runs are superseded for these owners; refresh acceptance after implementation.

Latest placement correction: keep the empty-products message OUTSIDE the Store card as a thin unboxed text line directly below it. The single Store card contains only identity and actions. Verify the message is outside the card bounds at both text sizes; preserve the empty-state meaning.

- C11-A01 (parent C11): Store heading two-line cap can clip long names. Removed cap; exact named C11 responsive cases now assert no RenderParagraph truncation. Acceptance pending rerun.
- C10-A01 (parent C10, independent audit): same-ID Store rename can leave Store info/related cards and route semantics showing product.seller while paged toolbar uses current Store metadata. Reuse canonical catalogueStore(id).name and test renamed Store data/fallback without changing identity or provider contracts. OPEN pending fix/replay.
- C13-A01 (parent C13, independent audit): layout estimator still measures optional blank fields omitted by rendering, reserving unwanted space. Keep measurement/render conditions identical. OPEN pending fix/responsive replay. Founder confirmed this was already pending implementation: this is an affected path within C13, not an additional defect in the count.
- C14-A01 (parent C14, independent audit): paged Store search cards retained white bordered treatment and tallest-row stretch. Apply compact adaptive gradient cards and Visit/Browse affordance while preserving collection/unavailable state. OPEN pending fix/Store-search replay. Founder confirmed this was already pending implementation: this is an affected path within C14, not an additional defect in the count.

Process diagnostics retained: REG-20260923-4647; initial visual batch16/18 passed, two C14 harness finders used ListView instead of its Scrollable descendant. Those are test-harness failures, not two additional product defects. Never count a passing reduced batch as full qualification.

Impact replay found four older R5 paged Offers tests expecting a MoolSocial promotion while Suppliers is selected, and indexing the supplier carousel using the entire mixed publication page. Align fixture selection/carousel indexing with the already-approved D06-B source grouping, preserving publisher identity, pagination, retry, product and cart assertions. This is test-contract drift; qualification remains pending replay. C10 rename harness initially used a legacy fixture without Store ID; supply an explicit test Store identity before exercising canonical same-ID rename. Neither harness finding adds a founder defect.

## Local visual-review handoff after founder refinements - 23 September 2026

Implemented all12 visual requirements in the9 existing C08-C16 tickets. The selected matrix remains19 ticket entries, not the full backlog. Founder refinements to C10/C11 are implemented: one compact gradient identity card, Store name once, accessible partnership icon, address/type, Ask and existing status/delivery access. The empty-products message is a thin unboxed line OUTSIDE the card. C08 refresh is an accessible icon without its visible text or incomplete-ranking banner; results move upward. C09 utility controls and C16 selectors are unboxed; C12 Add is compact with its touch target preserved; C13 optional empty facts no longer reserve height; C14 Store cards use compact gradients and Visit; C15 retains the moving blue dot without the rail.

Local evidence, with actual source versions retained:

- All149 selected scenarios passed together with identical before/after source fingerprint `e50c7fa2d44f6bd2d0fa24cfc0b770dab6b516d25e576c91fe87072b29c248f9`: `apps/mobile/build/visual-qualified-one-card/machine.jsonl`, SHA256 `a6b8d7d5925cd202c3160b178eba0f9e31a1adbc422f147d8849006c7e2ce00d`.
- The founder then moved the empty-message line outside the card. All6 affected C10/C11/C14 responsive cases passed after that change: `apps/mobile/build/visual-empty-line-machine.jsonl`. Latest source fingerprint `71d2c09dd107eb5326aa32894ceae1346ca99d53e78845ac660d360d8545e7fd`. Tests assert the message is outside the identity-card bounds, single visible name, canonical same-ID rename, untruncated long name, compact message and Visit continuity.
- Separate Store/partner suite184 passed: `apps/mobile/build/visual-partner-one-card-machine.jsonl`; source compiled before the last message-placement refinement. Four controls/compact Store regressions passed in `visual-controls-one-card-machine.jsonl`; six recovery/navigation capture checks passed in `visual-recovery-one-card-machine.jsonl`. The earlier three-file impact run and its four stale Offers failures remain preserved; all four corrected supplier-fixture journeys subsequently passed.
- Analysis of all9 changed Dart owners passed; final analysis of the two owners touched by the empty-line refinement also passed (`visual-one-card-analysis.log`, `visual-empty-line-analysis.log`). Scope, regression-memory and implementation coordination gates passed. Git diff whitespace check passed.

The C11 heading-cap child and C10 same-ID metadata inconsistency are fixed locally. C13/C14 audit findings were incomplete affected paths within the founder's existing requirements, not additional defects; their estimator and paged-card corrections passed responsive/Store regressions. No unresolved new customer-visible child was confirmed in this batch. Older open workstreams and real Store/account/payment/delivery dependencies listed above remain open. No production/device qualification follows from controlled review fixtures.

Rechecked latest available local Store checkpoint: `e985a65c7125c117674dbc7ad02de8d4e6b2c3ba`. It adds Store header-icon/local-approval records after e5abc55b; bounded Git diff found no changes to Store/Buy feature owners or either cited public-data handoff. No other worktree changed and no merge/pull occurred. This is local checkpoint verification, not a claim of remote freshness.

Opened actual native review gallery: `apps/mobile/build/founder-review-one-card-20260923/index.html`;62 screenshots, individual checksums/source paths in its manifest. Latest C10/C11/C14 screenshots supersede earlier images. Review/evidence ZIP: `apps/mobile/build/founder-review-one-card-20260923.zip`,12848931 bytes, SHA256 `c99ee3a57105d9f5f10238a6c434ee848b96a931ef7aa8185a89ca6f1b6faa9c`. Preserve this review evidence during the later Git reconciliation; these ignored local artifacts are not yet a committed release bundle.

Founder visual approval remains PENDING. Ledger marks local passes with their real tested hashes; the minor final refinement is not used to falsely relabel earlier cumulative receipts. After the founder accepts the visual snapshot, the mandatory release gate must replay all selected scenarios on that exact frozen source before Git/APK qualification. Do not claim current single-source release readiness, all-backlog completion or new Redmi acceptance. Branch remains `work/cursor-ui/buy-ready-20260921` at `63a83d05d9d8172947f93ef322501fa7e0400842`; no commit/push/checkout/merge/APK/device action occurred. Continue the standing child/impact rule for every ticket.

Formal production `handoff` gate was also checked and rejected with `production handoff worktree is not clean`. The14 preserved modified owners are the uncommitted review batch; implementation coordination is passing, but production handoff is NOT passing. Do not commit merely to bypass the founder's visual-review-first sequence. Complete the later approved Git phase and exact-source qualification before retrying production handoff. This document records a local review checkpoint, not a completed production handoff.

## Founder approval with final Add-placement correction

Founder states "REST ALL APPROVED" for the reviewed pack; retain that visual approval for every reviewed item other than the requested C12/C13 Add-placement refinement. Move Add from the separate bottom row to the right of the SKU price/details lane to reduce card height. Reuse BuyV2ProductCard, _ProductGlance and existing add/quantity callbacks; no new screen, provider or shared Store model. Classification remains mvp_supporting for existing Buy discovery. Exact source owner: buy_v2_catalogue.dart; acceptance owners: pending-defects, responsive-grid, product-actions and partner-catalogue tests already covered by existing selected ticket owners/impact runs. Verify normal/narrow/enlarged text, long prices, Add touch target, MOQ/stock/review/prescription behavior, quantity editor and return continuity. Keep approved surrounding visuals intact. Required review of this final correction is separate from the approval already granted; backend/device acceptance remains pending.

Founder explicitly extended the final placement check to everywhere the old long SKU Add appeared. Bounded source audit found all five production BuyV2ProductCard construction paths in buy_v2_catalogue.dart: finite Offers; paged catalogue products; progressive grids (Store/category/Wholesale/comparison/saved surfaces); horizontal grid fallback; recently viewed product grids. These all select compact cards (including the horizontal default), so the shared inline price/action correction reaches them without duplicated page implementations. The separate Buy Home image-overlay Add is already the approved compact treatment. Monthly basket bulk-add, product-detail actions and GST Add/Edit are different actions, not the retired SKU bottom strap. Preserve their existing semantics. No other production file constructs this card class.

Responsive impact replay passed186 cases and found one stale geometry assertion: it treated every pixel below Add as dead space, but price-side Add now correctly precedes seller/delivery facts. Register its migration before editing: assert Add is right of price and the last visible detail remains close to card bottom, retaining the 4px no-dead-space bound and existing readability/reachability assertions. Transfer only buy_v2_responsive_product_grid_test.dart from the inherited 13-September audit claim to this task's /root claim; do not borrow that old claim. Add this exact test owner to C12/C13, scope and the coordination gate's selected-owner list. The intermediate claim-only gate rejection correctly identified the unsynchronized exact allowlist; synchronize that one literal owner, preserving all gate assertions and unrelated owners. No runtime source expansion is authorized by this test-owner registration.

## Founder full Redmi and technical re-audit - 25 September 2026

Founder explicitly resumes implementation after full 19-plus-child visual/technical audit, defect listing and repair/retest/hot-reload cycle. Earlier pause is superseded. Scope is frontend; backend remains deferred. No new APK, commit or push authorized.

Pre-selection / pre-execution assessment: actor is public Buy customer, capability is product decision, cart and retained commerce journeys across Shop/Wholesale/Bulk/Offers/Store. Outcome: compact truthful product information, one purchase control, preserved identity/navigation and visible recovery; all 19 original references and18 linked children require individual audit evidence. Classification mvp_required: fixes existing launch commerce surfaces and regressions. Reuse existing buy_v2_views.dart, buy_v2_screen.dart, buy_v2_session.dart, existing content contracts and focused Buy tests. No new screen/state owner/backend/dependency proposed. Sequence: reconcile all references and evidence, inspect reachable Redmi states and contract/test boundaries, register child findings, repair shared owners, focused then impacted tests/analysis, hot reload and inspect again. Preserve provider authority, permission/identity checks and unavailable/retry states; controlled data never proves real publication/payment/shipment. Founder visual approval remains distinct.

Review evidence: apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/REVIEW-FINDINGS.md (17 discussion items, not17 closed tickets). Existing original19+18linked=37 references; no current full visual qualification. R01-R08 amend PDP01/02/03/05 and purchase-control acceptance; R09-R17 require impact audit and exact parent mapping before new child allocation. Continue shopping removal explicitly included. Variants/photos need populated authorized review fixtures; absent sample data alone is not proof code failed.

Source-owned checks remain pending for this new review. Earlier passing counts are historical evidence and do not qualify the requested new presentation. D08 provider/service grouping fix exists with focused passing tests and full session/checkout replay; parent remains open pending contract/visual audit.

### Standing preservation rule for the full audit/repair goal
Founder explicitly requires a non-regressive Git approach across the full goal (25 September 2026). Preserve the prior19-plus-child implementation, evidence and every existing user change. Baseline HEAD5dc6885ada1fe0cd23f3d5d0a2bc62fe56cc0abd and all28 changed owners are retained in apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/git-before-new-repairs/manifest.json plus binary patch (SHA256ca43c819c5a761ba07ae9671ec048c2cbad48ff6f4263c71287f119999fe808d). This preservation snapshot is not a commit or release qualification. Each repair must compare against current prior work, retain unrelated changes, stay within owner scope, run meaningful impacted regressions and preserve test failure evidence before retry. Never use destructive restore/reset/clean, switch branches, weaken tests, or discard prior implementation to obtain a clean tree. Commit/push remains separately authorized. A clean Git state never substitutes for technical or device acceptance.

D09 full-audit technical reproduction selected: late delivery-order refresh after session disposal. Launch-required lifecycle correctness; reuse existing session and _ShopCommerceAdapter.orderRefreshGate production checkout test fixture. Minimal scope rejects stale async completion without notifying disposed state, preserving order/purchase identity and valid refresh. No provider or screen added. Acceptance: delayed completion returns false without exception; normal and invalid-identity behavior retained; session/order regressions before reload. Baseline748 passed; full37-reference qualification open.

### Founder clarification: explicit media / option / price acceptance
The founder reiterated these as separate requirements, not optional interpretation of a generic variant ticket:
1. PDP01: multiple real product photos, swipe and active photo indicator; preserve order, variant association, load/error/retry and zoom behavior. Current Flipkart reference review-23-flipkart-reference.png visibly shows gallery pagination below image. No claim that MoolSocial one-photo review fixture proves multi-photo acceptance.
2. PDP02: size selector only for products with applicable published sizes; include unavailable options with truthful state. Selection binds exact SKU/variant/pack and cart line.
3. PDP02/PDP05: colour selectors where published/applicable, with accessible colour names and unmistakable selected/unavailable states; changing colour updates relevant media and offer facts.
4. PDP02: compact variant/pack option boxes must show the option-specific price, selected state and availability. Do not render a text-only selector when price comparison is required. Size/colour/pack changes preserve valid combinations and cannot silently add another variant.
5. PDP02: current selling price, struck-through original/MRP when valid, discount amount/percentage and separately verified historical price drop. Do not conflate MRP discount with historical reduction or fabricate missing MRP/history.
6. PDP01/02: connect all option changes end to end through photos, title/option summary, price, stock/eligibility, quantity and exact cart item. Audit Buy/Wholesale/Bulk/Offers/Store entry and return routes. Provider fields remain backend-deferred but typed frontend connectors and populated controlled review cases are required now.
7. Keep the founder-specific single Add/quantity flow plus cart icon. Flipkart's Buy now dock is NOT a requirement because the founder explicitly rejected that duplicate action.

All above need dedicated test/evidence rows and actual Redmi states; fixture absence is unverified, never a pass. Reference screenshot captured read-only while founder browses Flipkart; no reference app purchase/action submitted.

D09-A01 minimal disposal guard now implemented;570 session/order impact tests passed, zero errors, analysis clean. Existing Flutter27993 hot reload succeeded1of3185 libraries2419ms. New device screenshots25-30 cover tracking, invoice-missing state, order items and return. Missing ordered quantities and unavailable invoice on retained MS-NEW-11 remain unresolved data/recovery findings, not silently reconstructed. Full38-reference visual audit remains incomplete. Screen31 shows soap product rather than intended delivered list; exclude it from delivered proof.

PDP02/R01 inline-price repair execution: reuse _ProductPriceExtras state and _ProductInfoRow; remove obsolete modal helper. Current price/MRP validity and live updates preserved, no provider/data changes. Reset expansion when selected product changes. Existing price behavior test amended for inline expansion/collapse and no BottomSheet; preserve discount/price-refresh/cart assertions. Shared source covers automatic Shop/Wholesale product paths. Visual/impact qualification remains required after repair.

### Variant-specific premium product design - founder amendment 25 September 2026
Use the founder's phone-family example as an illustrative product family, not a claim about any currently available phone model. Extend existing PDP01, PDP02 and PDP05 acceptance; do not count the same family-selection requirement as three new defects. Implementation pending; no visual approval implied.

**PDP01 - Selected-variant gallery.** One bounded gallery above the product summary, preserving image aspect ratio. Multiple published photos for the exact selected SKU; swipe, active pagination and enlarge access. Colour thumbnails select an actual variant, not a cosmetic recolour of the same asset. Changing SKU replaces/rebinds gallery and resets a now-invalid image index; never retain a previous colour's photo while claiming the newly selected SKU. Missing/failed photo shows an honest compact fallback/retry, without inventing additional photos. Gallery height must let the compact identity/price/action summary become visible promptly.

**PDP02 - Options and prices, one compact selection region.** Below the identity/price summary: `Colour: selected name` with small photo/swatch choices and text-accessible names; below that a named Storage/Size/Pack row only where applicable. For3,4or more variants, adapt/wrap or use a clearly scrollable row rather than squeeze text into clipped boxes. Each option card contains a short option value and its valid current price; selected option uses a thin accent outline/subtle gradient and check indicator, not a large dense blue block. Unavailable combinations remain clearly unavailable, never silently replaced. Preserve applicable earlier dimension choices when selecting another dimension; when impossible, show the required choice rather than auto-buy a different SKU. One selected-variant summary and one Add/quantity control, no duplicated title, price table, Buy now or purchase dock. Keep minimum tap targets and enlarged-text readability despite visually compact styling.

Current price stays prominent. Valid higher original/MRP is struck through beside discount; a verified historical price drop is a separate small line. No made-up crossed price, discount or historical price. Option prices are variant-specific Store offers, not the parent product's copied price. Avoid displaying every variant's full specification card at once.

**PDP05 - Exact-variant details and wiring.** Selection updates gallery, option summary, current/original price, valid discount/history, stock, MOQ/pack quantity, delivery eligibility/promise, seller offer identity and applicable specification/manufacturer/policy data through existing public contracts. Shared family facts may be reused only where authoritative; SKU-specific overrides must win without repeating labels. Cart receives exact product/SKU, canonical family, Store/offer identity, revision, selected dimensions, pack and quantity. Preserve different variants as distinct cart lines. Never use a stale selected-offer quote after switching. Product/cart/Store/Offers return restores the correct variant and prior unrelated cart lines.

**Provider handoff fields required:** stable family ID; unique SKU/variant ID; Store/offer ID and revision; ordered dimension descriptors and option IDs/labels (colour with optional swatch/thumbnail, size/storage/pack as applicable); valid combination mapping; media ordered and bound to SKU/revision; currency/current amount, optional valid MRP and authoritative price history timestamps; stock/availability, pack/unit/MOQ; eligibility/timing; SKU-specific content/policies. No frontend guessing from product-title strings. Reuse and extend existing typed product/content contracts only where fields are missing; Store integration/backend remains deferred, documented against same ticket references.

**Acceptance:** populated controlled fixture with at least4 genuinely different variants (different media, prices and specifications), multiple photos on a variant, unavailable combination, stale/error response, absent optional MRP/history, single-variant/no-size product, long option names and200percent text. Prove changing colour/storage/size/pack updates the same page and exact cart item, blocks stale Add, preserves unrelated cart, and returns correctly through Buy/Wholesale/Bulk/Offers/Store. Distinct family/variant identities are required; duplicated catalogue rows are not multi-variant proof. Each applicable state must be shown on Redmi after local/impact tests. Review-only fixture must not enter live catalogue.

Code audit so far: existing `_ProductVariantSelector` and `_ProductVariantOption` already render pack and price boxes; current BuyV2Product only exposes free-text variant/pack, not explicit colour/storage/size dimension metadata. This is a frontend contract/UI gap to repair, not merely a backend excuse. Multi-photo and price-history structures already exist and must be reused. Latest read-only capture32 is MoolSocial soap product (not Flipkart variant reference); reference23 verifies Flipkart gallery indicators only. Do not claim unseen Flipkart option layout was inspected.

PDP02/R01 inline-price repair checkpoint: replaced modal with stateful inline gradient rows and expand/collapse control, preserving current/MRP validity, discount updates and product-change reset.54 product-content tests and120 variant/decision/offer impact tests passed, zero errors; analysis clean. Two obsolete modal-dismiss expectations changed to inline collapse while retaining seller/product return and cart assertions. Existing Flutter27993 hot reload succeeded7of3185 libraries3139ms. Redmi screenshots35/36 show actual collapsed/expanded price details under Fresh tomatoes without popup. This proves the normal available-price device state only; enlarged text, unavailable-price device state and founder approval remain pending. Other PDP layout/variant issues remain open.

Next shared-cart repair audit: root `_showsMiniCart` explicitly suppresses Shop/Wholesale product pages; `_ProductPurchaseDock` provides duplicated Continue shopping/Buy now/Go to cart. Nested Store-product route separately suppresses bottom navigation and only paints StoreCartBar for medicine. Removing dock alone would strand nested public product carts. Repair must restore root rail cart and nested compact cart control, preserve Care and exact scoped/aggregate cart return; test both shells, empty/nonempty cart, verification/availability and enlarged text. No runtime cart change applied yet.

PDP purchase-control R06/R07 execution: remove obsolete public _ProductPurchaseDock, restore existing root mini-cart eligibility, reuse compact _BuyMiniCartBar in Store-product header alongside optional delivery control. Preserve Care bar, scoped/aggregate fallback, existing inline Add eligibility/MOQ, retained cart and return routing. Reuse exact Buy screen/views/content-test owners; tests amend obsolete Buy-now expectations to Add then actual cart-icon navigation and exact cart quantities/scope, while retaining no-overlap details check against visible viewport. No backend or dependency change.

PDP R06/R07 repaired: removed _ProductPurchaseDock; restored root cart rail; nested Store product uses compact persistent44px cart control (final placement is footer, superseding header proposal).98 final product tests and9 corrected navigation checks passed; analysis clean; Git diff check clean. Wider replay's nine stale failures retained and corrected without removing description visibility, no-overlap, Compare/cart return or unrelated-basket assertions. Hot reload27993 succeeded7of3185libraries3585ms. Actual Redmi38 shows no dock,39 shows quantity1 plus cart badge,40 correct Shop tomato500g INR37 cart,41 same-product return;45 nested Store product compact cart,47 correct nested cart; removed only audit-added unit and49 shows settled empty-cart catalogue. Capture43/46 were transitional and must not count as settled destination proof. No payment/order submitted. Founder approval still pending; other layout/variant defects stay open.

D09 retained-order source audit: BuyV2SharedPreferencesCustomerStateStore._encodeOrder stores line productId/quantity only; _decodeOrderLines resolves against static BuyV2Catalogue.allProducts. Provider-only IDs drop and current static price/content can replace purchase-time snapshots. This is a concrete frontend persistence defect; follow-up reproduction must round-trip provider-only product and a known ID with changed purchased price/variant/pack, then repair retained line serialization without fabricating old lost data. Source owner already admitted for D17 persistence; use existing session tests and preferences fixture. Missing old snapshots must remain honest unavailable with recovery, never infer historical invoice amounts from current catalogue. Device evidence27/29 corroborates missing invoice/quantity, but exact retained-record cause still needs correlation.

D09-A02 execution assessment: launch-required purchased-line identity/price retention. Reuse existing preferences codec and _R669StringPreferences/session tests. Reproduce provider-only lost SKU, known-ID purchase fields changed by static catalogue, and legacy ID-only recovery without fabrication. Repair only purchased display snapshots, not current eligibility/account authority. Preserve legacy order IDs/totals and require provider recovery for missing purchase details; no guessed line values. Full receipt/invoice/backend authority remains deferred.


D09-A02 repair checkpoint: purchased lines now store validated versioned purchase-time SKU identity, seller, variant/pack, unit price and quantity. Restored snapshots cannot grant catalogue eligibility. Legacy ID-only or invalid lines remain unavailable while order identity/product IDs/totals survive. Eight focused checks and477 full session tests passed, zero errors; analysis clean. Evidence: redmi-founder-audit/d09-a02-repaired-focused.jsonl and d09-a02-session-impact.jsonl. Device restart/recovery and invoice metadata audit remain pending; not closed. No APK, commit or push.


PDP01/02/03 compact gallery/services execution assessment: founder requests compact product facts below media and aligned Returns/COD/support. Actual Redmi51 shows gallery occupying60percent viewport and pushing price/actions near bottom. Launch-supporting public buyer presentation; reuse existing shared BuyV2ProductView/gallery/assurance controls and product-content/actions tests, no new screen/provider. Bound gallery height with preserved contain/zoom/swipe; align service icons/text with accessible targets and enlarged-text wrapping. Preserve existing help/returns/payment wiring, truthful availability and Care layout. Verify gallery actions, responsive layout, support/cart return and device before/after. Source owners apps/mobile/lib/ui_v2/buy/buy_v2_views.dart and existing product tests only. Backend unchanged.


PDP compact gallery/service checkpoint: bounded public gallery leaves title/price/Add earlier on screen; Redmi54 proves normal product layout.98 product-content/actions tests passed and analysis clean. Device55 exposed overly broad narrow-screen service stacking; threshold refined and all8 assurance checks passed, preserving shared help and truthful COD/returns. Both hot reloads succeeded; implementation gate passed. Final service-row device capture and enlarged-text device proof still pending. Capture52/53/56 are catalogue/transitional and do not prove final product UI. Other seller/details/variant requirements remain open; no founder acceptance or APK.

Final normal-text Redmi58 verifies Returns/Cash on Delivery/Customer support in one aligned compact row;57 verifies compact gallery and early purchase summary. Hot reload7/3185 libraries3684ms. Device remains on product services. Enlarged-text device check, seller-card spacing/gradient and duplicated similar-product content remain open.


PDP02/03 seller-card execution assessment: launch-supporting buyer clarity; existing _PublicProductOrderInformation/_ProductStoreSummary/_ProductQuickActions own requested card and navigation. Remove empty trust-wrap spacing when no facts exist; use restrained gradient and compact horizontal action labels with48px targets, keeping exact seller identity, delivery/address and truthful states. Preserve Care-specific paths and existing Compare/Ask/Visit callbacks; no providers or backend changed. Test current product-content/actions/navigation regression owners, large text, retained cart, and actual Redmi seller card before accepting.


PDP seller-card checkpoint: subtle gradient, horizontal readable Compare/Ask actions with48px targets, reduced divider spacing, empty trust-wrapper removed. Redmi60/61 show updated product/card; hot reload1/3185 libraries2500ms.313-case impact replay passed291;22 nested Store cart cases failed obsolete product-page bar selectors. All four affected product-page selector sites reconciled while retaining Store-grid bar selectors and scope/count/offset/checkout/repeated-return assertions. Final22-case replay passed (pdp-nested-cart-all-paths.jsonl), zero errors. Analysis clean before test-selector-only edits. Previous failed logs retained. Normal device presentation inspected; enlarged-text device proof, founder approval, seller further compactness, details/variants and similar-product dedup remain open. No ticket-wide closure, APK, commit or push.


PDP05 details/review execution assessment: launch-supporting founder presentation correction. Reuse _CommerceProductDetails tab state and _ProductReviewsPanel actions. Apply subtle gradient container and selected tab, compact readable specification rows, natural unboxed review/report controls with wrapping and48px targets. Preserve all specification/description/manufacturer source precedence, no duplicate content or new state owner; no review/report submission during audit. Verify all product-content/actions cases, tab semantics and200percent text, then hot reload actual Redmi. Source is existing shared views owner; backend/provider remains deferred.


PDP05 details UI checkpoint: light gradient container/selected tab, compact specification rows and unboxed wrapping review/report actions implemented.98 content/action tests passed, analysis and ownership gate passed; hot reload1/3185 libraries2259ms. Redmi64 specifications,65 description tab and66 review actions inspected at normal text. Device description still exposes repeated fixture SKU/price text; retain under existing PDP05 content cleanup, not approved/closed. No review/report submitted. Enlarged device check follows; backend remains deferred.

Redmi font-scale2.0 probe capture67 shows expanded seller actions and stacked readable services/similar-product card, not All details (layout reflow changed visible section). Do not count67 as enlarged details/review proof. Restored original font-scale1.0; remaining enlarged details inspection stays pending.


PDP01/02 typed-variant execution assessment: public buyer exact SKU selection is launch-required. Reuse BuyV2Product/copyWith, productVariantsFor/selectProductVariant, existing gallery and product facts/content providers. Add explicit dimension/value metadata (stable IDs, labels, kind, optional colour swatch) rather than parsing titles. One compact dimension selector resolves only a unique same-Store SKU preserving other dimensions, shows candidate-specific live price and unavailable combinations, and uses existing SKU navigation/eligibility. Legacy pack selector remains for unstructured catalogue records. Backend publication is deferred, typed provider handoff is required. Tests must cover colour/storage changes, exact cart identity, other-dimension preservation, missing/ambiguous combination, price/media changes and large text. Review-only multi-variant fixtures and native proof remain required before closure; no fake provider data in production.


PDP01/02 structured-variant checkpoint: BuyV2Product.variantAttributes now accepts BuyV2VariantAttribute(dimensionId,dimensionLabel,optionId,optionLabel,kind,swatchArgb). Kinds colour/size/storage/pack/other; ordered attributes describe one exact SKU. Provider must publish stable IDs, consistent dimension metadata, unique same-Store family combinations, SKU-bound media and independent prices/content. resolveVariantOption rejects missing/ambiguous/foreign Store candidates and preserves all other dimensions. Shared selector shows named option-specific prices and explicit unavailable combinations; existing session selection/cart flow reused. Selector follows compact summary, with legacy pack fallback for unstructured records. Model and normal/200percent widget journeys pass (3focused); impact162passes plus corrected placement test1pass, analysis clean. Tests preserve two distinct selected SKU cart lines. This is NOT ticket completion: controlled multi-photo4variant Redmi fixture, unavailable-combination UI proof, metadata persistence/provider decoding audit, revision/error cases, thumbnails and all entry/return paths remain pending. Backend mapping only; do not merge Buy/Store worktrees.

Variant runtime checkpoint: hot reload rejected BuyV2Product const shape change; recorded incident, then existing Flutter27993 hot restart succeeded11034ms. No APK/build/install. New model loaded, but populated variant Redmi screens remain pending, not qualified from restart.


PDP02/D09-A02 metadata persistence impact assessment: typed variantAttributes introduced by PDP02 must survive purchased-line and procurement-draft display snapshots. Existing preferences codec currently omits them. Reuse exact saved-products-store/session-test owners, add shared validated attribute codec for both snapshots, preserve legacy absence and fail unavailable on malformed attribute data without granting eligibility. Backend deferred; no new persistence service. Verify round-trip dimension IDs/labels/kinds/swatches and malformed/legacy behavior, then session impact checks. This is an impacted path of existing open PDP02/D09-A02, not a duplicate ticket.


PDP02/D09-A02 variant persistence repaired: shared validated attribute codec used by purchase snapshots and procurement drafts.12 focused checks and481 session impact tests passed; analysis clean after braces-only lint correction. Legacy missing metadata yields no invented dimensions; malformed/duplicate/unknown metadata discarded while purchased SKU/price retained. Procurement metadata does not restore approved/published grant. Evidence pdp-variant-persistence-focused.jsonl, pdp-variant-persistence-impact.jsonl and final analysis. Backend decoder/publisher and four-variant multi-photo Redmi fixture remain pending. Source implementation done for this affected path, device recovery not yet accepted.


PDP05 fallback description root cause: BuyV2CatalogueProductContentAdapter synthesizes description from title/variant/pack/unitPrice. Redmi65/66 shows repeated fixture SKU/price copy. Launch-supporting content integrity repair: stop inventing description when no authoritative description exists; retain typed specifications and genuine policy fields, provider adapter descriptions unchanged. Existing _CommerceProductDetails handles absent description truthfully. Reuse content-contract owner and content tests. Multi-photo device fixture remains separately open: installed bundle contains illustration atlases, not exact phone variant photos; do not substitute unrelated atlas images as photo proof.


PDP05 duplicate-description repair: catalogue fallback no longer synthesizes title/variant/pack/price description. Missing actual description stays absent; typed specs retained and supplied content adapters unchanged.55 content tests passed, analysis clean (pdp-description-impact.jsonl/pdp-description-analysis.log). Exact fallback regression added. Device verification and real provider copy remain pending. Four-variant phone-photo fixture is still open; no unrelated illustrations substituted or media policy relaxed.


PDP04 similar-family repair assessment: Redmi61/64 shows repeated current-family tomato offers. Source admits same canonical family when variant text differs (including fixture SKU suffix). Launch-supporting discovery correction: current family belongs to variant/compare flows; Similar products should show distinct alternative families. Reuse productContinuationsFor and _ProductContinuationSection, allow untruncated candidate retrieval for UI, filter existing availability before family dedup and visible limit. Preserve explicit Recently viewed products and exact listing navigation/cart state. Test current-family exclusion, duplicates, unavailable-first available-later family offer and same-title distinct-family retention. No backend or Store ownership changes.


PDP04 family-dedup repair: current-family variants excluded from Similar products; UI obtains full candidate list, filters existing unavailable states, then chooses distinct canonical families and limits visible cards. Explicit Recently viewed lists retain exact SKU history.7 focused similar tests and537 session/content tests passed; analysis and ownership gate clean. New test proves unavailable-first offer does not consume its family slot and same-title different families remain. Hot reload19/3185 libraries4991ms succeeded. Redmi verification follows; no ticket closure yet.

Redmi70 still repeats tomatoes: development _product creates canonical family per generated listing, contradicting real template identity. PDP04 stays OPEN. Extend same-owner root repair to preserve template family/variant, keep listing IDs unique, scope variant selection to current Store and collapse duplicate legacy option descriptions. Structured option ambiguity must remain rejected, never silently deduplicated. Test development same-family acrossStores, preserved listing uniqueness, cross-Store variant rejection, genuine packs and all source/selection impacts. No backend/other-worktree change.


PDP04 development-family repair final local/device checkpoint:647 session/content/variant cases passed, zero errors, terminal success in pdp-similar-source-final-impact.jsonl. Ownership gate passed. Existing Flutter27993 hot restart5875ms; no APK. Redmi74 confirms clean template titles;75 exact tomato summary;76 Similar products now distinct onion/banana families;77 selecting onion opens correct title/price and tomato return entry. Shared illustration remains explicitly labelled and does not prove supplier photography. Duplicate-description removal now produces truthful Product details unavailable because fallback specs repeat summary and no extra authoritative content exists; no invented description. All-details populated/enlarged proof remains pending. Full PDP04 and all39 references remain open for remaining paths/founder approval; backend deferred.


PDP02 option-readability execution assessment: public buyer exact variant selection, launch-required/supporting presentation; reuse _ProductVariantOption and existing structured selector/test owners. Smallest repair adds subtle selected gradient/check and readable wrapping availability; keeps semantics, dimensions, Store/SKU resolution and Add eligibility. No new screen/provider or backend. Test normal/200percent layout, unavailable combination stays disabled and preserves currentSKU/cart, existing selection/media regressions. Native populated variants remain pending separately.


PDP02 option-readability checkpoint: selected options now subtle lavender/green gradient with visible check; names11px and availability10px wrapping instead of7.5px ellipsis. Existing semantics and unique selection preserved.8 focused checks plus167 full variant/content impact cases passed, zero errors; analysis and ownership gate passed. New normal/200percent missing-combination checks prove disabled option cannot change selectedSKU or existing cart. Evidence pdp-option-readability-tests.jsonl, pdp-option-readability-impact.jsonl and analysis/policy logs. Populated structured-variant native proof and multi-photo fixture remain pending; not closed or founder-approved.


PDP01/02 populated-device fixture assessment: launch-supporting review of existing public buyer gallery/variant/cart contracts. Reuse BuyV2DevelopmentCatalogueSource with explicit default-off includeVariantReviewFixtures; enable only existing debug/device-review source construction. Four clearly labelled iPhone16 review SKUs (pink/ultramarine x128/256), distinct test prices and dimension identity, two actual colour-matched Apple product images. Source https://www.apple.com/shop/buy-iphone/iphone-16; downloaded byte/dimension/SHA provenance in review-phone-media-provenance.json. No iPhone18 availability claim, no live price claim or Store listing. Keep default load-test cohort unchanged; no release activation, policy bypass, asset bundle dependency or new APK. Bind each media record to exact generated Store/family/SKU using existing admission policy. Tests default exclusion, explicit inclusion, distinct pricing, exact binding/media admission and sameStore dimension switching before debug restart. Native network loading/swipe/variant/price/cart/return required; backend remains deferred.


PDP01/02 review cohort implementation checkpoint: explicit opt-in source flag; four iPhone16 Review only colour/storage SKUs with independent test price/MRP and two downloaded/verified Apple colour images. Existing media admission retained; generated Store/SKU bindings rebuilt exactly. Repeated load-test rows cannot create ambiguous copies of these structured combinations. Default cohort unchanged; production source never uses this device-review opt-in. Focused fixture test passed;594 session/variant impact cases passed, zero errors; analysis and ownership gate passed. Native screen review now starts; no APK or accepted provider publication.


PDP02 paged variant repair assessment: Redmi83 proves page-source products lack options because productVariantsFor reads initial list only. Reuse _knownCatalogueProducts union, keeping sameStore/family/procurement checks and ambiguity rejection. Add actual source-pager search-to-selection test. Exact session/test owners; no provider/backend change. Redmi82 also identifies shared SKU-card missing structured dimension summary, separately pending under same parent. Phone media loads, not variant acceptance.


PDP01/02 paged-variant repair final checkpoint: productVariantsFor now uses existing known-catalogue union, retaining sameStore/family/procurement filters. Regression opens real source pager with qualified facts, selects loaded variant, verifies exact media and price.594 session/variant cases passed, zero errors; analysis and gate passed; hot reload2053ms. Redmi83/84 show first/second genuine colour photo;86/87 repaired option controls;88 colour switch changes photo/price and retains128GB;89 storage switch retains Ultramarine and changes to256GB/70000 test price;90Add restores cart icon;91cart exact Ultramarine256GB/photo/price;92cart-item return retains selection/quantity. Only audit-added unit removed after capture92; no checkout/order. Native normal Shop search journey proven for this fixture, not all entries/children or founder acceptance. Open: structured dimensions missing on search SKU cards (82), thumbnails versus swatches review, additional variant-specific content/history/error/unavailable/large-text and Wholesale/Bulk/Offers/Store routes. Backend remains deferred. Apple images used solely in labelled review fixture, provenance preserved.


PDP02 structured-grid summary execution assessment: Redmi82 same-colour storage cards omit variant identity. Launch-required buyer SKU clarity. Reuse customer-copy extension plus shared compact _productGlanceFields and offer/Store summary text/measurement; emit ordered validated dimension labels plus pack once, preserve legacy pack copy and underlying identity/matching. Same summary in accessibility labels. No title parsing/new provider. Test normal/200percent compact grid, Store context and distinct same-name SKU selection; preserve quantity/action measurements and Offers impact. Existing customer-copy/catalogue/variant-test owners only.


PDP02 structured-card summary repaired: customerVariantPack emits validated ordered dimension labels and pack once; shared compact product/offer/store summary measurement and accessibility labels use it. Legacy products unchanged.4 focused normal/200percent Store/nonStore grid cases passed, preserving alternate variant cart identity;122 full variant/Offers impact cases passed, zero errors, analysis/ownership gate passed. Hot reload40/3185libraries4408ms. Redmi95 four variants distinguish colour/storage directly on cards;96 enlarged single-column summary/price/Add readable;97 enlarged hero;98 full-width selectors;99 colour switch updates image/price while preserving128GB. Original font_scale1.0 restored and read back. No cart additions during this replay. Grid identity issue technically/device verified for shown Shop route, founder approval and remaining cross-entry checks pending. No full-ticket closure or APK/publication.


PDP01/02 Store-path native replay:102compact Store header/unboxed close;103Store-scoped search four exact variants;104Pink256 product;105switchUltramarine preserves256;106Add/compactcarticon;107cart exactphoto/SKU/70000 testprice;108AndroidBack restores nested Storeproduct/quantity;109productBack restores search;110searchBack retainsStorequery;111Storeclose restores originatingUltramarine128/scrollposition. Removed only audit-added unit before leaving nestedproduct,109showszero quantities and111no carticon. No checkout. This closes native evidence gap for the shown normal-text Store variant/cart roundtrip, not parent/founder closure. Matrix child definitions recovered for16/20references;4olderchildren still need direct mapping. Machine manifest updated to current partial native evidence; provider/backend remainsdeferred.


R6633-D17-A06 registered from Redmi117: Wholesale footer promises Freight included/Landed cart total while item says Freight confirmed later. Launch-required truthful buyer payable summary; reuse scoped cart lines and existing freightIncluded flag. Minimal repair derives included claim only when every selected line includes freight, otherwise subtotal/pending-freight wording; per-line landed label similarly conditional. Preserve arithmetic, quote/checkout/navigation and GST existing path. Exact views/wholesale trade-summary test owners. Acceptance included/unconfirmed/mixed, normal/enlarged, existing cart impacts and Redmi correction. Backend not required for this frontend fix. Total40references =19original+21linked/newchildren; fullgoalopen.


## Founder multi-variant design amendment — 25 September 2026

Registered against existing BUY-PDP-REF-20260924-01 (gallery), -02 (variants/pricing), with -05 (details) and -06 (identity/continuations) consumers. This adds acceptance requirements, not duplicate parents. Existing 40 references remain 19 original plus 21 linked/new children; no new completion claim.

Execution assessment: public buyer selects an exact published Store SKU; launch-required correctness and launch-supporting presentation. Reuse existing BuyV2Product.variantAttributes, productVariantsFor/selectProductVariant, media/content snapshots, shared product view and cart handlers. Documentation amendment only in this step. No new screen/state owner/dependency or backend activation. Follow existing owner claims and preserve all uncommitted work.

Re-inspected retained Flipkart 02-product/04-price: gallery, size selector, current price/struck MRP/discount and grouped delivery are visible. Phone colour/storage thumbnail layout is a specified MoolSocial design, not claimed observed reference behaviour. Founder iPhone 18 example expresses a product family with 3/4/many variants; no real model facts or prices inferred.

Definitive screen specification and provider acceptance are recorded under founderMultiVariantDesign20260925 in the four linked manifest entries:
- One gallery and one compact title/price/Add summary. Below, applicable colour photo options and size/storage/pack price tiles. No duplicate title, price panel, Buy now or Go to cart action.
- Soft gradient and thin selected outline/check, compact gaps with accessible touch targets. Many options scroll in a single row per dimension; enlarged text wraps without clipping. No four-variant cap.
- Every valid selection updates its exact photo set, selling price, MRP/discount, stock/delivery and differing specifications/policies together. Price drop requires dated history. Shared approved photos are allowed explicitly; missing data never borrows a different SKU fact.
- Unique same-Store combination identity; preserve other dimensions when valid, disable unavailable combinations, reject stale responses. Browsing variants does not mutate existing cart quantities; Add targets selected SKU only.
- Provider field mapping includes stable family/SKU/offer/pack/workspace identity, ordered dimensions and combinations, approved media, prices/tax/tiers, stock/serviceability, content/policies/manufacturer provenance and revisions. Backend deferred; frontend contracts and failure states remain in scope.
- Local tests and native review cover 1/3/4/12 options, different/shared photos, changing details, unavailable combinations, asynchronous races, 320/390dp and 200% text, all Buy/Wholesale/Bulk/Offers/Store/Cart entries and impacted children. Existing partial fixture/device proof is not full acceptance.

The latest compact Add/cart flow and this amendment supersede conflicting old fixed purchase-dock and spacing wording. Status: specified; implementation gaps and full local/device qualification remain open. No APK, commit, push or checkout performed by this amendment.


D17-A06 verification checkpoint: 11 focused freight-summary checks and 343 cart/checkout-return/pack-count impact cases passed, zero errors; analysis clean. Existing debug session hot reload1/3185 libraries2569ms. Redmi120 now Item subtotal/Cart subtotal and Freight confirmed before payment;121 cart-to-product retains exact Ultramarine128/60000 and quantity1;122 only audit-added unit removed, Add restored and cart icon absent. No checkout. Wholesale native repair verified; Bulk native replay and founder approval pending, so child remains in progress and full parent open. No APK or Git publication.


D17-A06 Bulk native follow-up:125 Add respects rice MOQ4;126 exact25kg pack,4x1690=6760, freight-included item/footer consistently landed;127 audit-only four-pack line removed, original Bulk mode retained and cart icon absent. Combined120/126 verifies unconfirmed and included native paths; included/unconfirmed/mixed normal/enlarged covered by11local checks plus343impact. Frontend technical status implemented/local/targeted-device verified; founder approval pending, parent D17 not closed. No orders/payments submitted.

PDP01/02 photo-option execution assessment: public buyer exact colour variant selection; launch-supporting presentation with launch-required identity protection. Reuse admitted supplier media policy and existing structured selector/option, same views and variant-test owners. Add compact colour thumbnail only from admitted exact-SKU image, labelled swatch fallback for absent/rejected/failed image, preserve dimension selection and cart state. No new provider/dependency/assets or backend. Verify unique candidate image sources, fallback, normal/enlarged selection and full variant/content impacts; hot reload and inspect native colours. Existing parent amendment owns this requirement; no duplicate child ID.

Photo-option focused test fixture correction: initial run50839 deliberately interrupted after identifying native image rasterization awaited inside widget fake-async, preventing progress; terminal exit1 observed. This was a fixture harness error, not an observation timeout. Corrected rasterization via tester.runAsync, precached local HTTP images and metadata to actual512x512 and byte count, preserving supplier admission rules. Original logs retained; corrected rerun required.


PDP01/02 thumbnail checkpoint: existing structured colour options now use compact44dp admitted exact-SKU photo; supplied labelled swatch remains for absent/rejected/loading/failed media. No new asset/provider dependency. Two focused normal/200percent exact-photo/storage/colour/cart checks passed;171 full variant/content cases passed with zero errors, including missing-photo swatch checks. Analysis and ownership gate passed. Initial fake-async fixture stall preserved; subsequent painting debug-client cleanup failure fixed with try/finally before binding invariant verification, no runtime checks weakened. Hot reload7/3185libraries4150ms. Redmi129 distinct Pink/Ultramarine thumbnail options and storage prices;130 colour selection updates hero and price60000 while retaining128GB, no cart mutation. Full parent remains open for many-option layout, differing content/history, failed/rejected thumbnail-specific replay, remaining entry paths/children and founder approval. No APK, checkout, commit or push.

PDP02 many-option execution assessment: public buyer selecting exact SKU from1/3/4/12 alternatives, launch-supporting compact presentation and required selection visibility. Reuse structured options and existing dimension resolution; replace normal-text Wrap with horizontal scroll per dimension, no fourth-option limit; retain full-width wrapping at enlarged text. A widget-local scroll controller owns only row position, initializes/updates to selected option, disposes safely; no second product state owner. Exact views/variant-test owners. Test first/last selection, visible selected option after rebuild, many dimensions and inaccessible combination preserving cart; full variant/content impact and Redmi normal/large evidence. No provider/backend/assets/APK.

PDP02 native many-option fixture assessment: extend existing explicitly opt-in review phone fixture from2 to3 storage choices (128/256/512GB) for each existing colour, six total review SKUs. Distinct synthetic test price/MRP, same approved colour photo binding per exactSKU; no publication or factual price claim. Enables actual Redmi horizontal third-option reveal. Update source-pager fixture acceptance six identities, colour/storage preservation, default-source exclusion; existing source/session-test owners. Backend and production unchanged.

Six-review fixture test edit initially failed on Python Windows default encoding before any test-content update. Run31662 interrupted deliberately (exit1) to prevent testing stale four-option expectations; corrected reader/writer to explicitUTF8. Logs preserved; no admission/assertion weakened.


PDP02 many-option checkpoint: normal structured dimensions use horizontal rows with next-option edge and selected-index scroll initialization/update; enlarged text retains readable full-width wrapping. Eight1/3/4/12-option normal/200percent cases passed, included in179 variant/content impact cases;483 session tests passed for opt-in six-SKU fixture, no errors. Analysis/owner gate passed. Existing debug hot restart8814ms required to load source fixture. Redmi133 next-option edge;134 reveals512GB;135 selectsPink512 and80500 test price/MRP85000;136 selected option remains visible after rebuild;137/138 enlarged photo/storage rows readable. Originalfont_scale1.0 restored/readback. No cart additions or checkout. Parent remains open for content/history, failed/rejected thumbnail replay, other entries/children and founder approval. No APK, commit, push or checkout.

PDP02/05 selected-content execution assessment: public buyer sees selected exactSKU details/policies/history; launch-required consistency. Reuse existing catalogue content adapter with explicit default-off review-fixture option, existing content snapshots/spec fields/history validation, fixture product compliance/protection and session adapter injection. Enable only existing reviewDataEnabled lane and explicitly labelled review family; injected provider adapter always wins. Distinguishable synthetic description/bundle/warranty/history perstorage, approved colour media unchanged. No assertion of actual Apple warranty/manufacturer address/prices; all such fixture copy labelled Review. Default nonreview content stays absent where provider missing. Test default isolation, selected content refresh, identity, expiry and native detail tabs; update provider handoff required. No new screen/backend/APK.


PDP02/03/05 selected-content checkpoint: explicit default-off catalogue content review option, selected only in existing review lane; injected real provider adapter wins. Review family/workspace binding identifies fixture (display origin is rewritten to Store area, initial focused mismatch repaired). Six review SKUs have distinguishable description/specification/bundle/history and compliance/protection; no invented production content.662 session/content/variant impact cases passed, zero errors; analysis/gate clean. Debug restart7885ms. Redmi140/147 show perSKU1000/2000 test price drops;142/148 exact128/512 specifications and Basic/Studio bundle;143/149 differing descriptions;144/150 exact test manufacturer addresses;145/151 warranty12/24months. No cart/order/payment action. Remaining registered on existing references: selected Manufacturer info tab clipped (PDP05-A01); duplicate Warranty fixture prefix (PDP03); repeated rating heading/row text (PDP05), other entry/large-text content/founder checks. Parent/goal not closed.

Provider handoff addition — per-variant content mapping (backend deferred; no worktree integration requested):
- Owning workspace publishes a distinct exactSKU/Store/offer/pack revision. BuyV2Product.variantAttributes supplies stable ordered dimensionId/optionId/labels/kind/swatch. BuyV2Product.mediaAssets supplies ordered approved images with matching SKU/workspace/revision. Do not join by display names.
- Inject production BuyV2ProductContentAdapter into BuyV2Session; snapshotFor must return matching productId/sourceId/observedAt/state. Map description, highlightFields/specifications with stable attributeId/groupLabel. The same attribute appears once across highlight/specification sections. Manufacturer legal fields map to BuyV2Product.compliance or documented compliance attribute IDs, independently of seller identity.
- Published purchase policy maps to BuyV2Product.purchaseProtection, including warrantyLabel without a repeated UI heading. Do not infer actual warranty/returns from descriptive content or review fixtures. Authoritative product facts/delivery adapters still own stock/serviceability/COD eligibility.
- Actual dated selling history maps to BuyV2ProductPriceHistory: storeId,canonicalProductId,skuId,offerId,pack,variant,sourceRevision,currency,previous/currentSellingPriceMinor,previous/currentEffectiveAt,validUntil. It must match current product facts; MRP is not previous sale history. UI validates identity/current amount/expiry before displaying a drop.
- Product selection already reads content by exactSKU and preserves separate cart identities. Producer/adapter acceptance must use differing photos,prices,descriptions,specifications,policies and history across at least two variants, absent/invalid/expired data and changed revisions. Review fixtures prove frontend consumption only; actual Store publication remains pending backend/workspace delivery.

PDP05-A01/PDP03 presentation repair assessment: selected manufacturer tab clipped144/150, repeated rating label142 and fixture Warranty prefix145/151. Launch-supporting readability; reuse existing details state/PageStorage/horizontal ScrollPosition to reveal selected tab after layout and restore without moving outerpage. Product-only ratings keep one heading and icon/value; seller trust unchanged. Fixture warranty carries value only. Exact views/session/content-test owners; verify selected tab bounds at normal/200percent, restored selection/cart, no repeated rating label and native replay. No new provider/backend/APK.


PDP05-A01/PDP03 detail-polish checkpoint: selected detail tab now reveals its complete label using existing horizontal ScrollPosition after layout/restore, without outer-page auto-scroll. Product-only ratings show one heading plus star/value; nonproduct seller panel unchanged. Review warranty value removes duplicated prefix. Two normal/200percent bounds/cart-return checks passed within181product-content/variant impact checks; phone fixture check1passed; analysis/gate clean. Debug restart9349ms. Redmi154 full manufacturer label and single rating row,156 full selected label at200percent,157 one Warranty prefix/readable policy. Originalfont_scale1.0 restored/readback; no cart additions or submissions. Three targeted presentation findings technically verified, superseding previous pending entries; parent/all-child qualification and founder approval still pending. No APK or Git publication.


D06-B-A02 registered: Redmi158/159 Suppliers remains Offers need refreshing after Refresh. Source trace finds review Shop/Wholesale include variant templates but publication source uses old cohort with identical numeric SKU IDs; test will establish retained-cache mismatch. Reuse explicit source flag and existing identity/expiry checks, never bypass validation. Exact session/session-test/Offers-test owners; local source/cache recovery, default exclusion, scoped publishers and native replay required.41references=19original+22linked/newchildren. Backend deferred, noAPK/Git publication.

D06-B-A02 local/native checkpoint: aligned explicit variant-review publication cohort and isolated cursors; existing identity/expiry rejection preserved.534 session/Offers/pending-defect cases passed, analysis clean. Broad first run failed fixture count24; regional source has one Store per destination, corrected expectation12 plus six unique SKUs each. Hot restart7692ms; Redmi160-172 prove Suppliers/MoolSocial load, phone search, exact colour/photo/price change, Add/cart icon and exact Cart/product return. Only audit-added unit removed; cart zero. Full native Shop-preview cache replay and founder acceptance remain pending. PDP06 followups recorded: duplicated review delivery prefix and misleading Offers label on immediate Cart return.41 references remain tracked; no blanket closure, APK or Git publication.

PDP06-A03/A04 registered from native168/167: misleading Cart-origin Back label and duplicate review delivery prefix. Reuse exact return-state getter/root label and review fixture text; source/quantity preservation, local and native replay required.43 references=19original+24children; founder acceptance and backend remain separate.

PDP06-A03/A04 repair checkpoint: session exposes Cart return label; root Offers shell respects actual session return label. Review fixture delivery text is Delivery for review only.575 distinct impact cases qualified:549 othercases pass, all26 continuity pass after correcting4 stale simultaneous-viewport assumptions; overlap/drag/report/source checks retained. Analysis and ownership gate pass. Hot restart7571ms; native173-179 verify clean delivery copy, Shop-preview to Offers recovery, Cart-labelled return with same Pink128/60500/qty1 and removal only of audit item restoring Suppliers phone search. No APK/order/Git publication; founder approval remains pending. Failed initial logs preserved.43 references remain tracked.

C07-A01 registered: native Profile GST183 validation,184 stale error after correction,185 successful review save with duplicate persistence notice and incorrect Try again. Repair existing Profile/form feedback; keep actual load/save failure recovery.44references=19original+25children. Review-only GST memory is not backend persistence.

C07-A01 fixed: Profile Retry only for failed load; session success notice appears once. Form edits clear superseded validation while Save revalidates.60 GST/profile/session impact cases pass, analysis and policy pass. Hot reload4345ms;189-191 verify corrected error, fresh save with no Retry and normal Profile return retaining synthetic details. Reload itself reset review memory (188), so not claimed persistent account proof. Synthetic Review Buyer GST fixture remains in review memory for next Cart reuse audit; no backend write/order. C07 combined-cart reuse/enlarged keyboard and backend persistence remain pending.44references still tracked; founder approval distinct; noAPK/Git publication.

C07 native reuse192-210: mixed Shop+Wholesale shows one automatically saved GST profile, Payment Back/Review retains it, Wholesale-only and freshly created Shop-only baskets reuse it without entry. Cancelled edit keeps original address. Review at200percent readable; native200 initial focused billing caret behind fixed save bar until typing201. Registered C07-A02 for focused keyboard-settle repair/replay; not declared keyboard-qualified. Font restored1.0 and all audit cart quantities removed; synthetic GST remains review-only memory. No order/payment.45references=19original+26children. Backend persistence/account lifecycle remains deferred and founder acceptance separate.

C07-A02 technically verified: corrected focused baseline reproduces200percent caret506 below viewport410 after animated keyboard opening. Re-reveal focused render bounds post animation with24dp clearance. First native pass213 revealed text but handle still overlapped; final214 clears handle and text before typing.174 final GST/Profile/checkout cases pass, analysis and gate pass. Final hot reload3290ms. Unsaved test address cancelled; font restored/readback1.0; cart empty and review profile reset by reload. Failed harness/first-pass logs preserved.45references unchanged; founder approval distinct, noAPK/Git publication/backend action.


### D09-A03 tracking product counts — 25 September 2026

Native218/219 confirmed duplicate destination in Products. Existing purchased lines now supply exact product/item/pack counts. Native221 exposed legacy saved orders without line snapshots; recognised count prefixes are displayed without destination, preserving unknown summaries and original persisted data. Final native222 verifies 1 product / 1 item with separate destination retained. 67 impact cases passed; analysis clean. Founder approval pending. Parent shipment scope remains open; backend deferred. No APK or Git publication. Detailed evidence: config/buy-founder-regression.json, D09-A03.


### D07 native audit and D07-A01 — 25 September 2026

Native227 confirms unverified account stops collection without duplicate sign-in. Native228 confirms unchanged Cart quantity1/37rupees. Misleading zero-item footer fixed to Cart saved for unresolved collection with retained basket; native230 verified after hot reload.262 checkout/collection impact cases passed, analysis clean. Successful collection still requires deferred runtime identity/gateway; unavailable-path proof is not full D07 closure. Founder approval pending; no order/payment submitted, APK or publication. Detailed child evidence in regression manifest.


### Exact replay reconciliation — 25 September 2026

Audit header corrected to19 original references plus28 linked children=47; rows unique. 16 existing mapped references now link exact successful, non-skipped test events and suite paths in terminal-success logs with SHA256. These replace stale replay-pending labels, not device/founder acceptance. D11 four launcher cases are present in latest262case checkout/collection impact. D09-A02 purchased snapshot roundtrip is implemented and tested; native recovery remains pending. Full mapping: apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/EXACT-REPLAY-RECONCILIATION-20260925.json and ALL-REFERENCES-AUDIT.json. No additional runtime changes or new APK/publication.


### Delivered legacy order audit — 25 September 2026

Native232-239 verifies MS-240741 delivered list/details, missing-line invoice Back/Refresh, unavailable purchased quantity disclosure, and Items/product/Items exact return. Seven current missing-invoice regression cases pass. No Cart mutation or transaction. C05 itemised receipt is not injected in installed review runtime; cannot claim its native review from legacy invoice evidence. D09-A02 exact new-order restart snapshot recovery remains pending. Detailed hashes and boundaries: apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/LEGACY-ORDER-NATIVE-AUDIT-20260925.json.


### C05 actual Redmi partial receipt — 25 September 2026

Added one explicitly labelled debug device-review receipt fixture through existing order/receipt adapter and UI, no alternate screen or backend. Flag absent/review disabled excludes fixture; exact identity guard prevents applying to other orders. 263 impact cases pass plus enabled/disabled fixture checks; final analysis clean. Actual Redmi242-244 verifies2ordered/1received/1missing, normal and200percent text, readable report action and local report outcome preserving counts. No real report sent; font1.0 restored. C05-A01 receipt action now native verified; reschedule action and founder approval remain pending. Backend receipt/dispute/settlement deferred. No APK/publication. Exact hashes in manifest receiptDeviceVerification20260925.


### D09-A02 Redmi purchased snapshot restart — 25 September 2026

Native245-251: local review order MS-NEW-12 / BUY-NEW-07, Fresh tomatoes500g, quantity2,37each,total74. Invoice249 before and251 after hot restart5652ms match order identity, item/pack/quantity/price, seller, Cash on Delivery and receiving address. New-order purchased snapshot recovery now targeted device verified; old missing-line orders stay explicit. This uses local device-review commerce adapter, no actual order/payment or APK build. Founder approval separate, parent shipment authority deferred. Persisted review record retained; Cart consumed only audit2units. Evidence hashes: apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/D09-A02-NATIVE-RESTART-20260925.json.


### C05-A01 reschedule and new C05-A02 — 25 September 2026

Debug-only reschedule fixture exposes existing UI with exact identity/slot guards; local-only result says no delivery changed. Native254 found slot text fading at200percent. Text-only repair insufficient256 despite earlier limited test. Final adaptive framework button/selected semantics257-259 shows complete label, selection and Confirm new time result. Production-theme test checks wrapped paragraph and full control bounds. 163 impact cases passed; analysis clean. C05-A01 receipt and reschedule actions now targeted native verified, founder pending. New C05-A02 repaired/local/native verified, founder pending. Audit now19 originals+29children=48references. Backend/noAPK/no publication unchanged.


PDP parent acceptance reconciliation, 25 September: pdp-six-current-acceptance.jsonl completed successfully with 84 visible passing tests. Exact mapping found 43/44 parent cases plus one stale PDP02 test name (precedes -> follows identity). Inspected test assertions: selector follows title, switches exact pack and leaves cart unchanged; corrected manifest name to approved current design. No test implementation changed. Evidence PDP-SIX-EXACT-ACCEPTANCE-20260925.json preserves initial mismatch. Native 264-help-return-after-label.png verifies tracking -> existing Shopping Help return with exact tomato500g context. Confirmed open presentation finding: Help shows review seller Mool Market000001 (space before numeric suffix) while PDP/tracking use Mool Market1; existing customer seller/partner formatter is the repair owner. This finding is not repaired or closed. Full product-return/cart verification still pending. No APK or Git publication.


PDP03-A01 completed frontend repair: shared Help now reuses customerSeller/customerPartner and searches displayed plus original names, preserving raw identity and real Store names.85 product/support/continuity checks passed; analysis clean. Hot reload5834ms. Native267-270 verifies header/order label consistency and product -> Help -> MS-NEW-12 -> Help -> original product scroll/cart badge1. Founder approval pending.49 references now19 originals plus30children. Six PDP parent44 exact acceptance cases all mapped to successful current85-test run; parent native/provider qualification remains separate. Reconciled mapping artifact retains original mismatch evidence. One audit-added tomato remains in cart for cleanup/next checks; no user cart line changed. No APK or Git publication.


D17 Redmi follow-up272-279: mixed cart preserves Shop1/37 and selected Wholesale MOQ2/1160; address/payment/confirm retains exact trade pack. Missing delivery blocks placement, retry remains honest, Edit basket restores exact basket. Audit Wholesale additions removed; Shop audit1 remains. No order or payment submitted. D17 PO native states are not reachable in installed default: no purchaseOrderAdapter; controller also requires identity. Existing widget harness injects both. Next bounded device-review work must reuse existing PO adapter/controller with explicit debug-only review fixture and isolated review identity, test absence for release/review-disabled/explicit providers, and run native draft/issue/decision/revision/recovery before claiming qualification. No new backend, native package or APK required for Dart fixture. D17 remains open. Evidence D17-NATIVE-GAP-20260925.json.


D17 device fixture implemented in existing session owner, gated by kDebugMode plus explicit MOOLSOCIAL_DEVICE_REVIEW plus review enabled, absent explicit collection identity/commerce provider; explicit PO adapter preserved. Controller-only ValueNotifier identity disposed with session, never authenticates collection/account. Local adapter exact Store/SKU group identities, stale request/revision rejection and per-document approval. Flag-enabled test1 and normal pending/checkout impact164 passed; analysis clean. Existing APK hot restart7990ms. Native283-287 draft/awaiting/revised/approved states retained2packs10kg1160; delivery independently blocks placement. No real PO/payment or supplier contact. Parent remains open for enlarged/failure/recovery/collection native verification and explicit-provider test expansion. D17-DEVICE-FIXTURE-20260925.json contains SHA evidence. Cart retains audit-only Shop1 plus Wholesale2 for next invalidation checks. No APK or Git publication.


D17-A07 discovered and repaired: native291 changed3pack1740 checkout retained accepted2pack1160 label; Check status refreshed old request and Review basket looped without preparing updated PO. Panel now marks noncurrent documents Previous terms/review required and offers Review updated purchase order using existing prepare, disabled during reconciliation.164 impact cases passed including normal/200percent current-basket assertions; analysis clean. Native294-296 verified old3pack1740 approval clearly stale against4pack2320, enlarged action usable, resulting exact4pack2320 fresh draft still requires approval. Font restored1.0. Added provider-isolation sentinels; enabled/disabled focused runs each passed and explicit PO/commerce/account objects retained. Counts50=19original+31children; founder approval pending, parent D17 still open for other failure/recovery/collection paths. Cart now audit-only Shop1 and Wholesale4 retained, no order or payment. No APK or Git publication.


D17 recovery execution assessment: public Wholesale buyer encountering an interrupted PO issue response; launch-supporting frontend verification. Reuse explicit debug-only private PO adapter and existing controller/panel plus owned checkout/pending tests. The second local review request will deliberately retain awaiting state then throw on issue, permitting native reconciliation through Check status with no supplier call. No production adapter, authentication, payment or backend changes. Verify uncertain issue blocks repeat issue and fresh prepare in panel at normal/200percent text, refresh clears uncertainty for exact original request, cart stays intact; native follows local checks. This extends existing D17 device fixture assessment, adds no duplicate ticket.


D17 uncertain issue native300-302 verified: repeat confirmation and replacement review disabled, Check status readable at200percent and reconciles original REVIEW-PO-2 with6packs3480; revised approval remains separate. A07 collateral wording repaired: uncertain submission now says Submission status unconfirmed, not Previous terms. New normal/enlarged widget tests assert disabled actions and one issue call;166 impact cases plus1 explicit fixture case passed, analysis clean. Debug adapter second local request models interrupted response only; no supplier/payment call. Font restored1.0. Evidence D17-UNCERTAIN-RECOVERY-20260925.json. Remaining rejection/collection/other-child native scopes stay open. Cart audit Shop1 and Wholesale6 preserved. No APK or Git publication.


D08/D08-C1/D09 assigned delivery device assessment: buyer reading retained order assignment; launch-supporting native verification. Reuse existing BuyV2Order fields and debug-only receipt/reschedule seed admission in session, same Orders/tracking UI and owned pending tests. Add one explicit REVIEW-ASSIGNED-01 order with independent Store, courier, delivery service, sample window and display tracking reference, exact purchased line. No live location, authoritative shipment ID, authentication or delivery provider simulation. Verify flag-disabled/review-disabled absence, exact displayed fields and lines, native normal/enlarged tracking/details, preserve cart. Backend mapping still requires customer-authorized assignment/shipment IDs and revisions; display trackingReference is not that contract.


### Local preservation checkpoint status — 25 September 2026

Founder requested accurate counts, next hot reload and clean Git.51 references now comprise19 originals plus32 children;14 children targeted local/Redmi verified,18 pending qualification, founder acceptance separate. New PDP02-A03: Compare word needs99px but gets95px at320px/200percent; enlarged quick actions now one column, normal layout unchanged. Both scale tests passed. Hot reload3620ms completed; exact native replay remains pending.

Cumulative16-file replay:1663passed/33failed/zero skipped. Corrected obsolete compact gallery height, offscreen review tap (now reveal and hit-test), and catalogue-return request baselines measured after legitimate product discovery. Targeted12pass plus final8Store-return pass resolve18 prior failed cases;15 cases remain open: RV6 D011 content uniqueness/preservation12 and RV6 D012 Store listing count3. Preserve failures; no green-suite or production-readiness claim. Final lib/test analysis zero issues; unscoped analyzer12 diagnostics came from retained build capture scripts. Source/test evidence and exact pending cases: GIT-CHECKPOINT-STATUS-20260925.json inside archived redmi-founder-audit snapshot.

D08 debug assigned-order fixture: enabled1test and162impact passed, analysis clean, hot restart7504ms; exact assigned-order native inspection pending. No authoritative delivery/backend integration inferred.

This is an unfinished local preservation checkpoint, not ticket acceptance/closure, APK authority, merge or push. Backend remains deferred. Preserve original19 and every child, continue remaining historical regressions and exact native replay next.


Checkpoint NOT committed: project pre_commit gate rejected selected affected-route ledger coverage for saved_products_store and product_continuity, product_offer_decision, wholesale_cart_trade_summary, wholesale_supplier_continuity, wholesale_trade_decision tests.31 files staged and preserved; HEAD remains5dc6885a. Must reconcile selected owner/scenario coverage and source-bound local evidence without weakening gates;15 historical cases remain failing. Git is not clean. No push/APK/checkout performed.


### Checkpoint gate recovery and native follow-up — 25 September 2026

Archive checksum binding repaired after verifying preserved prior archive. Missing affected-file mapping corrected using existing goal children and PDP02 supplier/trade/offer impact scenarios. All57 existing ledger records selected for accumulated authorized changes; this is broader historical Git evidence, not57 new goal tickets. Fresh source-bound replay covers485 ledger cases /477 unique exact scenarios, zero failures/skips; eight batches plus seven-case exact-name supplement. Two stale ledger names corrected (group prefix and all six parameterized freight cases). Source SHA c95a6227eb8f3b3c3d9ede95900e650bcff1ebb58c9b974a30a73d29240b110c. All33 failures from the earlier broad run are resolved through targeted repairs/replays; no claim of a fresh whole1696-case run.

New PDP05-A03 repairs empty ready summary-only content while preserving genuinely missing/loading/retry states.94 product impact+18 historical content/Store checks pass; analyzer clean. Goal52 references=19 originals+33children.15 children now targeted local/Redmi verified;18 still pending qualification. PDP02-A03 native307-309 readable200percent Compare, refresh/Back preserved scopeCart4; font1.0 restored. D08 native311-315 verifies independent assignment fields, exact review order and failed-refresh retention at1x/2x, Orders return; globalCart5 unchanged. Backend deferred, founder approval separate. No APK, push or merge. New evidence SELECTED-CHECKPOINT-QUALIFICATION-20260925.json and NATIVE-COMPARE-ASSIGNMENT-20260925.json.


### Comparison checkpoint and newly reported children — 25 September 2026

R6633-D05-A01 replaces repeated full SKU cards with compact supplier comparisons and inline Add at normal text size. Reuses existing Save, quantity, offer revalidation and product return. 478 selected current-source scenarios passed; focused78 impact cases and analysis passed. Redmi captures323–327 verify normal/enlarged presentation, requested four-pack Add/removal, refresh and Back. PDP04-A01 captures332–335 verify enlarged Similar products and exact related-product return. Founder approval remains distinct.

New open children: BUY-PDP-REF-20260924-02-A04 (oversized rounded quantity controls across Shop, Wholesale, Bulk, Offers, Store, product, comparison and saved surfaces); BUY-PDP-REF-20260924-02-A05 (unselected address truncation at200percent). Both require implementation and focused/native qualification. Existing quantity owners are BuyV2ProductCard/_QuantityStepper in buy_v2_catalogue.dart and _CompactProductStepper in buy_v2_views.dart. Preserve touch targets, quantity editing, MOQ and cart identity.

Tracking:19 original references plus36 children=55 references;17 children targeted-native verified and19 pending qualification. No original parent fully closed. Backend deferred; no new APK, push or integration. Evidence archive adds comparison-qualified-20260925 entries without deleting prior evidence.


### A04 compact quantity and large-price local checkpoint — 25 September 2026

Shutdown recovery preserved branch work/cursor-ui/buy-ready-20260921 at ebec91c2. Shared SKU quantity now replaces Add beside price, with no added compact-card footer; product, comparison and Cart controls use a thinner visible pill while retaining touch targets, editing and MOQ. Product purchase summaries measure actual price and use a readable full-width fallback when needed. Exact lakh/crore multiples may use precise labels; uneven values retain Indian-formatted digits. Cart monetary totals remain exact.

Fresh replay: 519 unique exact scenarios / 528 ledger cases, zero failures and zero skips. All 26 earlier checkpoint failures resolved; old logs retained. Nine changed Dart owners analyze clean. Source SHA b5e8c60b0b9c9a9ffd0692636e6508f2a55054a789b9647768b0d8aa07383d33. Evidence A04-RESUME-EXACT-QUALIFICATION-20260925.json binds nine successful machine logs. Approved Cart references remain untouched; two new quantity candidate images are not founder-approved. Eight historical tracked golden diagnostics restored byte-for-byte after retaining new failed-run versions in a04-cart-golden-diagnostics.

Redmi existing debug attachment recovered; hot reload947ms, no APK built/installed. Captures395–399 verify retail Add->quantity1->remove and Wholesale Add->MOQ2->remove on Offers, beside price without increasing card bounds. Review additions removed and original absent Cart icon restored. Earlier captures385–389 verify Cart INR1,00,00,360 at normal/200percent and restore original basket. Bulk391–394 verifies inline MOQ4 and removal. These are targeted proofs, not all-state closure. Large-price product/Offers device review, remaining quantity surfaces and founder approval still pending; earlier unexplained extra-addition observation remains retained, not dismissed.

A04 is local_passed, not closed. A05 unselected-address truncation at200percent remains the next source repair. Goal inventory unchanged:19 originals+36 children=55 references,17 children targeted-native verified/19 pending; no original parent fully closed. Backend deferred. This local preservation checkpoint grants no APK, push, merge or integration authority.


### Price/address qualification and Store category clarification — 25 September 2026

A04 requested review prices were exercised on Redmi: Buy INR50,000, Wholesale INR10,00,000 (MOQ2 total INR20,00,000), Offers INR1,00,00,000. Found and repaired banner wrapping and long unit-price wrapping/card-height growth. Normal/enlarged source-bound local checks and native captures400–424 retained. Temporary debug price overrides restored byte-for-byte; no live seller data changed. Review additions removed. Earlier unexplained cart observation retained, not declared resolved without evidence.

A05 address details now wrap completely; local normal/200percent selection/edit/cancel/cart tests pass. Redmi430–434 verifies selected Home details, populated edit form, Back cancellation and restoration of original Work address Basni342005. Normal device font restored. Founder approval remains pending.

BUY-STORE-CATEGORY-20260925-01 is founder-authorized for verification/implementation. Source audit found the existing shared Buy Home illustrated category window already wired into Store. Reuse retained; no duplicate screen added. Eight Store parity/navigation cases passed with temporary additional assertions. Those redundant assertions were archived and removed because existing parity and scoped-product/navigation tests already exercise the contract. The unchanged production/test source fingerprint is435877446cf304112efeaa1866fa5b038868812afdca418bb722f992c52d1803, matching the completed544-scenario replay (zero failures/skips). A final four-profile parity receipt qualifies the added ledger references against the exact restored bytes. Intermediate interrupted replay logs remain non-qualifying.

Founder clarified the window must initially remain partial and expand fully only when dragged upwards. Temporary initial-full edit was restored before hot reload; existing shared behavior retained. Redmi445–446 directly confirms partial opening and full safe-area expansion, with selected Flour/rice/grains preserved. Search, Close and scrolling remain available. Phone left fully expanded at normal text size. Captures442–443 contain unrelated private notification/app UI and must not be published or included in the tracked evidence archive. Use445–446 for the clean final proof.

Store product queries remain bound to exact Store ID. Category taxonomy is currently shared; Store-specific category availability/counts remain provider-deferred. No claim of completed Store/backend integration. Inventory remains19 originals plus37 follow-ups (56 references); individual verification receipts do not imply all-ticket closure or founder acceptance. No APK, push, merge or checkout.

Final native clarification receipt: after founder returned to MoolSocial,445 shows the normal partial opening and446 shows full safe-area expansion by dragging upwards, with Flour/rice/grains selection retained. This replaces the notification-obscured442 attempt for qualification. No automatic full-screen opening and no new APK.


### Founder Git/completion count reconciliation — 25 September 2026

Audited source checkpoint4a62a78b: zero staged, unstaged or untracked files. No ignored source/test/config/script/quality files in the assigned Buy owners. Required source, tests, ticket records and selected evidence are committed; the evidence archive SHA is4ddbd4333a2d3a8635411598d9b9340114004efd829062b31d03ca11af7eb516. Generated build/temp files and private unrelated phone images remain intentionally outside Git. No push/merge/APK.

56 distinct references =19 original references +37 additional children/follow-ups.19 follow-up fixes have implementation, local-test and targeted Redmi verification evidence.37 references still require complete qualification:19 original references +18 follow-ups. This is NOT37 entirely unimplemented defects. A04 quantity remains in the18 because its full surface replay and unexplained extra-add observation are not closed; its requested large-price banner/unit-price repairs passed local/native checks and are no longer labelled open.17 other follow-ups still need their exact native trigger/recovery audit. All original parent closures and founder acceptance remain unproven. Backend is deferred separately.

The exact verified19 and pending18 ID lists are in config/buy-founder-regression.json under boundedGoal19_20260924.reconciledStatus20260925. That snapshot supersedes stale chat/historical totals, without deleting historical evidence. Current source has547 distinct passing local scenarios. Do not call targeted native evidence full parent acceptance.


### Native audit preservation and Git reconciliation follow-up — 25 September 2026

Preserved the interrupted PDP05-A03 native audit from source checkpoint d05f6619 without changing runtime or tests. Screens447–468 are now retained in the existing evidence archive under product-details-native-checkpoint-20260925/. Archive SHA256:273b7d9c4410b8497c571e6e6885184cd15cbbef59a252a36b1ce6fdf02afda8. Store summary-only details collapse at normal/enlarged text; distinct phone facts remain visible. This is partial verification: remaining variant details and unavailable/error recovery still need native replay. The unexpected nested atta navigation in467–468 remains an unconfirmed interaction observation; no root cause or repair is claimed. Screenshot460's filename is misleading; its pixels show populated manufacturer facts.

Inventory unchanged:56 references (19 original plus37 additional follow-ups).19 follow-ups have implementation/local/targeted Redmi evidence;37 references require full qualification (19 original plus18 follow-ups). No original parent fully closed.547 current-source local scenarios remain bound to unchanged fingerprint435877446cf304112efeaa1866fa5b038868812afdca418bb722f992c52d1803. Backend deferred and founder approval separate. No new APK, push, merge or checkout. No ignored source/test/config/script/quality work was found; generated logs and private unrelated screenshots remain intentionally ignored.


### PDP05-A03 variant facts native continuation — 25 September 2026

At unchanged runtime checkpoint5413c8fa, fresh Redmi469–479 verifies the 256GB phone Description and manufacturer facts, both normal and200percent. Manufacturer address correctly contains256; distinct description differs from128GB. The selected horizontal details tab remains reachable by scroll at enlarged text. Back restores iphone search and normal font; no Cart action or new APK. Unexpected prior atta navigation was not reproduced by a fresh Description tap; Back revealed Recently viewed with atta, supporting stale coordinates without asserting a proven root cause.

PDP05-A03 stays pending: missing/loading/error/retry native trigger and remaining entry-path replay are not yet proven. Counts remain56 total,19 targeted-verified follow-ups,37 pending full qualification. Local source/test fingerprint remains435877446cf304112efeaa1866fa5b038868812afdca418bb722f992c52d1803;547 qualified local scenarios unchanged.

Standalone device memory gate initially omitted its existing EvidenceArchiveRoot argument. Historical evidence was found through C:/GUARANTEED OUTCOME/MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904 and the unchanged gate passed with that supported argument. Bounded incident and prevention recorded under REG-20260923-4647-BUY-VISUAL-BATCH-BOUNDARIES; no gate weakened. Archive adds product-details-native-followup-20260925/ with11 screenshots and2 passing gate logs; SHA2568fe91340a23a491e7bf67693efc8ba47844d238c3eebc2dfe56b02a160aac373. Existing Flutter attachment9167 confirmed live; no hot reload needed because source unchanged.


### PDP05-A03 targeted frontend qualification — 25 September 2026

Summary-only ready product details now have targeted Redmi proof across Store/Shop449/451, Wholesale496/498 and Bulk505/508 at normal/enlarged text. Distinct phone descriptions/manufacturer data remain readable472/473/476/478. A temporary debug-only512GB failure adapter showed unavailable/Try again484/487; a once-failing variant of that probe proved actual same-session Try again recovery491–492 to Studio kit and exact512GB specs. All runtime probe edits were restored byte-for-byte before final tests and hot-reloaded successfully4974ms. Fingerprint435877446cf304112efeaa1866fa5b038868812afdca418bb722f992c52d1803 unchanged. Normal font and Bulk grid restored509; no Cart additions, payment, APK or publication.

Fresh focused replay closes a coverage gap in the selected cumulative ledger: all12 RV6 D011 combinations (Shop/Wholesale/Bulk, duplicate-only/distinct, normal/200percent) and4 reference-details navigation/loading/empty/retry/legal-field cases passed, zero errors. Proof PDP05-A03-TARGETED-FINAL-20260925.json. Existing547 selected scenarios remain valid; do not add16 to547 without deduplicating. Loading/genuinely empty/legal retention are local proofs; physical device proof covers summary collapse, unique facts and unavailable/retry. No claim of live backend or every parent-state native acceptance.

PDP05-A03 is local_passed with targeted Redmi verification, founder approval separate. Counts now56 references=19 originals+37follow-ups;20 follow-ups verified and36 pending full qualification=19 originals+17follow-ups. No original parent fully closed. Temporary probe source and30screens480–509 retained under product-details-recovery-qualified-20260925/ in existing archive, SHA256de92dcbe678c50cbaa18cd73bd40bbdf871a55ccb88252d0ee7a2ff69120f277. Hot reload returned review app to home, so restoration alone was not accepted as retry evidence; the one-failure probe avoided reload between error and recovery. Short transitional captures501/499 are not relied on for route acceptance; settled509 proves Bulk return. Repeated Bulk review catalogue cards visible503 remain an observation for existing catalogue/discovery audit, not silently marked corrected.

Flutter test regenerated package_graph.json with ordering-only changes; package names, versions and dependencies verified identical. Generated output retained in the evidence archive; original tracked graph restored. No dependency change.


### Provider-driven variant and gallery expansion — 25 September 2026

Founder request: support the actual provider-supplied product portfolio across Buy/Shop, Wholesale, Bulk, Offers and Store; arbitrary applicable colour/size/storage choices and multiple variant photos. Research/registration authorized; new implementation requires exact selection/owner admission. Backend remains deferred. This is a provider implementation handoff, NOT an instruction to merge or integrate Cursor/Buy worktrees. Codex should implement Store-owned data entry/validation/publication seams in its own authorized lane, then return schema mapping, source commit and tests. Current Store implementation has not been freshly audited in this appendix; provider items below are requirements to reconcile, not assertions that every field is absent.

Decision: a million SKUs requires consistent IDs, category applicability and bounded queries. Do not put every possible field on every product form or load the whole catalogue on a phone. Product families describe shared facts; variants identify selectable sellable configurations; Store offers own commercial terms. Lot/serial fulfilment facts remain separate. Category examples do not activate deferred categories, regulated products or manufacturer/distributor accounts.

Research basis (primary references, accessed25September2026):
- [Google product data specification](https://support.google.com/merchants/answer/7052112?hl=en): stable item identity, explicit variant grouping, product images and separate commercial fields. This is feed guidance, not a universal legal checklist.
- [Schema.org ProductGroup](https://schema.org/ProductGroup): a family declares which dimensions distinguish its variants. [Product](https://schema.org/Product) and [Offer](https://schema.org/Offer) distinguish product characteristics from the commercial offer.
- [Shopify high-variant guidance](https://shopify.dev/docs/storefronts/themes/product-merchandising/variants/support-high-variant-products): fetching every variant is unsuitable for large families; resolve relevant options/combinations on demand. Its platform limits are not MoolSocial limits.
- [GS1 attribute implementation guide](https://ref.gs1.org/guidelines/gdm-implementation/1.0.0/): shared product attributes support listing, ordering, logistics and customer information. Consult the current applicable standard before claiming GS1 conformance.
The contract and UI decisions below are MoolSocial engineering recommendations based on founder requirements and current code, not copied vendor requirements.

#### Field ownership and proposed contract

Exact wire names are proposed until reconciled with Store; reuse equivalent existing fields rather than duplicate them.

| Entity / owner | Fields and types to map | Public use / boundary |
|---|---|---|
| Product family, authorized catalogue editor | familyId:string; categoryId:string; schemaVersion:int; brand/model; localized title/description; GTIN/MPN where applicable; revision:string; publication state | Shared identity and facts; never use display names as keys. Retailer Store branch identity remains independent of manufacturer/brand. |
| Attribute definition, category schema owner | attributeId; localized label; type(enum/multi-enum/string/number/boolean/measurement/date); unit; option IDs/labels; scope(family/variant/offer/lot); required/applicable rule; selectable/filterable/searchable/display flags; order | Drives category-specific editor and public sections. Distinguish missing from zero/false/not-applicable. Allow controlled extensions, not arbitrary executable UI/schema expressions. |
| Variant / exact SKU, authorized Store catalogue editor | skuId; familyId; selected attributeId->optionId map; packId; barcode; condition; status; revision | One exact combination, no duplicate combination in same identity scope. Preserve other choices when changing one dimension; do not invent the full Cartesian matrix. |
| Media, authorized Store catalogue editor | assetId; exact family/SKU applicability; ordered image IDs; primary; rendition URLs; dimensions/mime; alt text; media revision; publication/admission status; explicit shared-image fallback | Variant gallery/thumbnail/hero update together. Different colour usually needs different applicable imagery; size/storage may share images only when provider declares applicability. No stale previous-SKU image; no unsupported seller upload considered approved. |
| Store offer, authorized Retailer/Grocery Store owner | offerId; storeId/branchId; skuId; channel; currency; precise price amount/basis; MRP/compare-price basis; promotion validity; quantity tiers; revision; observedAt/validUntil | Current displayed price belongs to exact seller/channel/pack. Discount and price-drop claims require valid comparable source values/history. Internal cost/margin/supplier invoices stay private. |
| Sale quantity and pack, Store owner | selling unit; net content value/unit; units-per-pack; inner/case hierarchy; min/max order; quantity step; unit-price basis; variable-weight flag and settlement status | Explain piece versus case versus weight. Validate conversions; never multiply an unverified conversion or present estimated weight as final billed quantity. Variable-weight checkout rules need a separate authoritative contract before activation. |
| Availability and fulfilment, authorized Store operations | published/orderable status; stock state; permitted quantity; location/channel scope; lead time; supported delivery/collection; charges/conditions; COD eligibility; snapshot revision/expiry | Unknown is not sold out or available. Do not expose private bin-level stock or promise delivery from a product label. Existing eligibility/checkout checks remain authoritative. |
| Assurance and declarations, authorized catalogue/policy owners | applicable returns/warranty IDs and terms; manufacturer/packer/importer; origin; net quantity; customer-care; category declarations; policy revision | One compact details/assurance owner. Show provided verified declarations; do not invent compliance badges. Applicable jurisdiction/category validation must be confirmed separately, not inferred from this research. |
| Lot/serial inventory and order snapshot, Store fulfilment | lot/batch; actual manufacture/expiry dates; serial where applicable; reserved/fulfilled quantity; immutable purchased SKU/options/pack/price snapshot | Batch facts are not selectable variants by default. Public pre-purchase shelf-life promises must have an actual allocation rule. Preserve historical invoice/order facts when catalogue changes. |

#### Portfolio examples and how they should appear

Only display fields supplied and applicable to the selected category. The following are modelling examples; deferred categories remain disabled until authorized.

| Portfolio | Possible selectable dimensions | Details rather than selector boxes |
|---|---|---|
| Grocery / packaged household goods | weight/volume, pack count, flavour, formulation, grade when separately sold | ingredients, allergens, nutrition, storage instructions, shelf-life basis, manufacturer and net content |
| Clothing / footwear | colour, size, fit, length, material/pattern only when sold as distinct SKUs | size system/chart, measurements, composition, care instructions |
| Electronics / appliances | colour, storage, RAM, capacity, connectivity, configuration when separately sold | model, compatibility, voltage/power, dimensions, included accessories, warranty |
| Beauty / personal care | shade, fragrance, formulation, volume, pack | ingredients, suitability, directions and supplied warnings; no inferred health claims |
| Home / hardware / stationery | dimensions, finish, material, thread/gauge, pages, ruling, set count | assembly, fit/compatibility, technical measurements and care |
| Bundled / bulk offers | exact pack or approved bundle configuration | component quantities and substitutions policy, case/unit conversion, MOQ and tier basis |

A feature becomes a selector only when changing it identifies a separately orderable configuration. Six colours and six sizes do not prove36 sellable SKUs. Three published colours must yield three options; five storage options must yield five, with unavailable combinations explained and Add disabled. With many options, show a compact horizontally scrollable row or searchable choice view as appropriate, selected value always identifiable and reachable at200percent text. Do not add boxes for irrelevant dimensions. Public product facts, price summary and details must not repeat the same content.

#### Eight public tickets and matching provider deliverables

All eight are registered in config/buy-founder-regression.json as open, unimplemented and locally untested. They extend existing parents; earlier implemented pieces must be reused. Tickets are not selected for code mutation by this research update.

| Public ticket | Outcome and existing owner | Codex Store deliverable / dependency |
|---|---|---|
| BUY-CATALOGUE-20260925-01 | Typed category attributes and applicability; reuse BuyV2Product/BuyV2ProductSpecification and details renderer | Category editor/validation schema with stable IDs, types, units, required/applicable rules and public/private classification; field mapping to current Store owners |
| BUY-CATALOGUE-20260925-02 | Complete family/option selector; reuse productVariantsFor and resolveVariantOption | Family option discovery plus exact-combination resolution independent of catalogue pages; revision/completeness/cursors and sparse-combination availability |
| BUY-CATALOGUE-20260925-03 | Exact selected-SKU ordered gallery; reuse media binding/policy and gallery | Multiple uploads, ordering, primary image, exact variant applicability, approved shared fallback, publication/media revision |
| BUY-CATALOGUE-20260925-04 | Correct pack/unit/MOQ/tier display and selection; reuse product/offer/cart contracts | Validated pack hierarchy, quantity steps/bounds, precise price basis and conversion; no inferred variable-weight settlement |
| BUY-CATALOGUE-20260925-05 | Relevant category details/size chart/compatibility and declarations shown once | Structured supplied facts and policy links, category validation and required-field publication errors; do not force every category into one giant form |
| BUY-CATALOGUE-20260925-06 | One consistent selected offer and honest stock/price/fulfilment refresh | Revision-bound SKU+Store+channel+location snapshot; update/conflict/unavailable responses, actual promotion/stock/policy validity |
| BUY-CATALOGUE-20260925-07 | Bounded million-SKU discovery, scoped search/facets and cache | Indexed server queries/pagination/facet contract, snapshot revisions, expired-cursor recovery, exact-ID lookup; provider indexing/capacity tests separately required |
| BUY-CATALOGUE-20260925-08 | Same selection/cart identity across all five entry paths and saved/order returns | Stable identities through edits/unpublish, publication events/revisions and immutable purchase snapshots; never recycle SKU IDs |

Dependency order:01 schema mapping;02/03/04/05 on that mapping;06 reconciles authoritative offer facts;07 builds on indexed query/facet contract;08 verifies connected journeys over all preceding contracts. Store implementation must follow its own ownership/admission gates. A manufacturer/supplier supplying content does not automatically obtain Retailer publishing or stock permissions.

#### Current Buy code evidence and known gaps

- apps/mobile/lib/features/buy/buy_v2_models.dart has BuyV2VariantAttribute with dimensionId/optionId and colour,size,storage,pack,other kinds. resolveVariantOption requires same family,destination,Store and other selected dimensions; ambiguous matches return no result. Reuse it.
- apps/mobile/lib/features/buy/buy_v2_session.dart productVariantsFor currently uses _knownCatalogueProducts. This cannot prove full-family completeness when options live on unloaded pages. Ticket02 must add a bounded family/option contract rather than loading the million-SKU catalogue or presenting a partial subset as complete.
- apps/mobile/lib/features/buy/buy_v2_content_contracts.dart already owns media/size chart/price history/content states, published offers, eligibility and catalogue pages. BuyV2CataloguePage has queryKey,snapshotId,cursors,totalCount; existing page and exact-ID request bounds remain intact. Extend existing owners, not another catalogue.
- Shared apps/mobile/lib/ui_v2/buy/buy_v2_views.dart builds dimension selectors from attributes, not Offers-only UI. Current focused variant tests chiefly cover two colours/two storage options. More-than-six choices, additional size dimension and every entry path still need explicit qualification.
- Existing BuyV2ProductCompliance has manufacturer/packer/importer/origin/net-content/date/customer-care fields. Map these before introducing duplicates. Store-side completeness is not asserted by this Buy audit.

#### Acceptance, scale and error contract

Public fixtures must cover1,2,3,4,5,6,12 options per relevant dimension; exact3colour/5storage family; sparse combinations; long/localized labels; normal/200percent text; multiple photos with unequal gallery lengths; late response after rapid selection; withdrawn media/SKU; expired offer; Back, Cart and process restore. Repeat across Buy,Wholesale,Bulk,Offers,Store without copying screens. One scoped server response must identify query/family,Store/channel/location where applicable,revision/completeness,selected combination and recovery state. Names/labels are not identity. Backend actions remain deferred and cannot be simulated as production success.

For million-SKU qualification, generate a logical on-demand source without a million resident objects. Verify bounded pages, cache eviction, thumbnail loading, exact-ID restoration and cancellation/ignoring stale results. Measure Redmi time to first usable results, frame jank, memory, bytes and request counts. Publish measured results and agreed budgets before capacity acceptance. Backend indexing/load tests are a distinct future gate; a local synthetic pass does not prove production scale.

Codex return checklist: existing Store field->agreed public field mapping; schema examples for grocery,phone and size/colour product; editable versus computed/private ownership; publication validation failures; family/option API contract; media applicability and revision behavior; change/unpublish lifecycle; source commit and tests. Do not merge Cursor worktree, copy credentials or activate backend from this note.

Reconciliation after registration:64 references=19 originals+45 children/follow-ups.20 follow-ups retain targeted verification;44 references pending full qualification, including these8 new unimplemented/untested requirement tickets. Original parents still open; founder acceptance separate. Quantity child audit remains pending and resumes after this registration checkpoint.


Founder follow-up: apply all eight tickets across Buy/Shop,Wholesale,Bulk,Offers,Store and every applicable public surface. Sequential frontend implementation is now explicitly authorized, subject to exact ticket selection/owner andcontract gates. Each ticket has a mandatory all-surfaces case including Cart,Saved andproduct-return navigation. Earlier registration-only wording describes the initial research request and is superseded by this authorization; ticket status remains open/unimplemented/untested. Reuse shared owners;display only provider-supported applicable fields,never force phone selectors onto groceries. Provider work remains Codex Store-lane handoff;no worktree integration requested.


### Compact horizontal selector founder amendment — 25 September 2026

Founder rejected the large scattered colour/storage cards. Existing BUY-CATALOGUE-20260925-02 now records this presentation amendment; no duplicate ticket was allocated. Shared structured and pack-only selectors use compact horizontal rows at normal/enlarged text, with selected option kept reachable. Colour choices retain photo/name/selection without repeated price or available-stock copy; storage/pack choices retain price. Unavailable status remains visible and all semantics retain offer information.

Final focused variant suite:123 passed,0 errors; focused analysis passed. Redmi hot reload:7 libraries,4586ms. Native normal and200percent screens confirm compact layout,sideways scrolling and Pink512->Pink256 price/selection change;cart retained one512 unit. Font restored1.0 and screen left for founder review. Actual screenshots510–524 and proof/tests archived under selector-layout-founder-review-20260925/ in CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip (SHA256 1a7ece123816632c224276031bdddf66601b23c0ab8e43c7beaf8d922bcdf519,249048767bytes).

Earlier quantity continuation510–515 verified exact Add0->1,plus1->2,cart subtotal161000,Back2,minus2->1 without card growth. Its remaining surfaces still require native qualification. No new APK,backend orpublication.64 references remain tracked;20 targeted-verified followups,44 pending full qualification. Of eight catalogue requirements,one now has this implemented/tested layout amendment;none is wholly closed. Previous547 cumulative evidence predates this source change and must not be claimed as a fresh whole-suite pass. Founder approval pending.


### Founder supersession: single variant lane and colour radios — 25 September 2026

The founder rejected the earlier separate colour/storage rows as still occupying too much vertical space, then explicitly requested colour radio buttons. That uncommitted presentation is superseded: structured dimensions now share one horizontal lane; colours use circular swatches with selected ring,accessible names and48logical-pixel targets. Storage/size/pack choices preserve price and unavailable-combination handling. Replaced colour-photo-card code was removed; main selected-SKU gallery and cart assertions remain tested. Pack-only horizontal selectors remain shared.

Focused variant suite123passed and analysis passed on the new code. Redmi hot reload7libraries3981ms;525–533 retain actual evidence.527/533 show the single lane;530–532 cover200percent text and horizontal access,then normal font restored.528 filename was an intended action,not proof: quantity stayed1 and viewport/gallery had changed;do not claim emptycart. Current retained review cart has onePink512GB phone. All547 selected scenarios are being replayed against source fingerprint1c9ead4b220e14a91e91295cce763aa07bfc8e710beaed2f0b576d7884d9f019. Precommit previously rejected staleC01-1,correctly;no bypass orcommit occurred.

BUY-CATALOGUE-20260925-02 remains open for full provider family/option completeness,multi-colour andall-entry-path qualification. Founder confirmed3/4colours andmore may remain pending under that existing researchticket. No duplicate ticket orclosure claim. Backend deferred;no APK orpublication.


Single-lane radio final local checkpoint: all547 unique selected scenarios across561case references passed in15 terminal-success batches; source unchanged at1c9ead4b220e14a91e91295cce763aa07bfc8e710beaed2f0b576d7884d9f019. Every selected case now binds its exact successful test name/log/hash to that source. Earlier progress counters included loading events; final547 excludes them. Focused123 overlaps this suite and is not added to547. Analysis passed. Evidence archived in selector-radio-qualified-20260925/;archive252190506bytes,SHA256079da55f59351dff1d9e57ae2241c99239d996f4e33928a0e33cec1bc98f2ad4. Native proof includes normal/enlarged lane andfont restoration. Founder approval andwhole catalogue requirement remain open;no count reductions,no backend,APK orpublication.


## 2026-09-25 — quantity audit: Saved paging and retained comparison cart

Resumed from preservation commit `d681a1c6942439c363d7195679aff980b0759306` on the assigned Buy branch. Backend remains deferred. No new APK, publication, integration or founder acceptance is claimed.

- `BUY-CATALOGUE-20260925-07-A01`: fixed empty Saved Offers pages hiding the existing Previous/Next controls. Reused the shared catalogue pager; retained Saved mode and cart. Two focused scenarios pass at text scales 1.0 and 2.0; focused analysis reports zero issues. Redmi frames 552–556 prove forward/back paging and readable enlarged controls. This does not close catalogue-wide saved discovery or backend pagination.
- `R6633-D05-A02`: fixed development/review comparison listing resolution after retained-session recreation. The exact review listing ID now reconstructs the same source SKU, seller and price through the development catalogue resolver. Invalid identities remain rejected; production resolver behavior and recovery safeguards are unchanged. One focused scenario passes for Shop and Wholesale, including invalid IDs. Redmi 548 records the original failure; 549–550 prove recovery without clearing the cart: Pink/512GB, Market Square Store, quantity 2, subtotal INR160990. Production providers must independently resolve retained comparison listing IDs under customer authorization.
- Quantity child `BUY-PDP-REF-20260924-02-A04`: frames 534–543 cover product removal, comparison Add, quantity editor, enlarged comparison, product return and retained cart. Frames 559–560 show Saved Add changing to the compact quantity control without adding a row. Frames 563–568 show Store quantity 1 -> 2 -> 1 -> 0, unchanged normal card height, enlarged text readability and exact INR37 total changes. Frame 569 confirms the original comparison cart is retained. Audit-added tomato quantities and Saved entry were removed; font scale restored to 1.0. The child remains pending overall qualification; no all-surface closure is inferred.

The current replay selects 550 distinct scenarios / 564 ticket-case references, including both new children. Source fingerprint: `e4a37aa227f3d0d176cb6d25b284dc6061f6993a62e78ca6336ea9dbfa3264bc`. At this entry the replay and preservation checkpoint are pending; its terminal result must supersede this progress note. Counts remain 66 distinct references (19 originals + 47 children/follow-ups), 20 targeted verified and 46 pending full qualification until the new children are qualified. Founder visual approval is separate.


### Quantity recovery terminal local result and targeted qualification

All 15 batches completed with exit 0: **550 unique required scenarios / 564 case references passed; zero failures or missing scenarios**. The source fingerprint before and after the run is `e4a37aa227f3d0d176cb6d25b284dc6061f6993a62e78ca6336ea9dbfa3264bc`. Loading events are excluded from that count. Every selected case is bound to its exact successful machine log and current source. Both new children are `local_passed` and targeted Redmi verified; no founder approval or parent closure is inferred.

Reconciled total: **66 references = 19 originals + 47 children/follow-ups; 22 targeted-verified follow-ups and 44 pending full qualification** (19 originals + 25 follow-ups). Pending qualification does not mean all those items are entirely unimplemented. Backend remains deferred.

Preserved 87 new evidence entries, including 36 native frames 534–569, original failures, focused retries, analysis, cumulative logs and native proof, under `quantity-recovery-qualified-20260925/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`. Archive size 262251210 bytes; SHA-256 `c9d9be0f03f83f017e790732912ec26fa3448af23fc5100fda4388919dccbc67`. Existing archive entries were preserved; every new entry was read back byte-for-byte. The Git checkpoint gate and commit are the next step; no APK was built.


## 2026-09-25 — public-side polish and service alignment

Founder clarified public Buy, Wholesale, Bulk, Offers and Store browsing first. Store workspace Counter Sale/Add Product is excluded. Registered BUY-PUBLIC-POLISH-20260925-01 and its observed service-row child -A01; both implemented, locally passed and targeted Redmi verified, with founder approval still pending.

Shared product presentation now uses compact title/price/Add, proportional label columns, aligned address and seller actions, restrained gradient Add/selector/detail/terms/service/review surfaces, readable specification and review typography, and consistent recommendation text measurement. Price disclosure stays inline and uses selection haptics; no physical haptic-feel acceptance is claimed. Provider identities, policies and commerce callbacks remain intact. Pack-only selection loses only redundant explanatory copy. Store identity occupies full width with Compare/Ask/Visit in one normal-text row; enlarged text deliberately stacks accessible actions.

Child -A01 was reproduced in native frame572 and a failing normal-scale regression: service controls used outer width, ignoring the border inset, so the third action wrapped. Width allocation now accounts for the inset. Both normal/enlarged geometry and COD-action return checks pass. Original failing evidence is retained.

Final replay: **552 unique selected scenarios /582 ticket-case references passed in15 terminal-success batches**, no missing cases or failures, source fingerprint `cdcf234da9bf6f44761bcc19b08f83cb364086fef7026008df8e3b9fe38dd5ea` unchanged before/after. Focused source/test analysis passed. Earlier550 first-pass replay is superseded and not added to552. Every selected case binds the exact final successful log and fingerprint.

Redmi hot reload3761ms; native frames570–605 cover Offers product/comparison/return, Store browsing, Buy phone gallery and detail tabs, Wholesale inline price/terms, Bulk MOQ/terms and filter gradients. Normal and200percent text verified; font restored1.0. Cart empty at this sweep start and end; only one automation-added atta was removed. Delayed navigation/input incidents are recorded, not mislabeled application defects. Bulk home remains open. No real purchase, support message, new APK, backend work, Store-worktree change or publication.

**68 tracked references =19 originals +49 children/follow-ups;24 targeted-verified follow-ups and44 pending full qualification.** None of the19 original parents is declared fully closed. The8 catalogue research requirements, complete variant families/provider data and founder acceptance remain open; this presentation sweep does not close them.

Archived 125 new files under `public-polish-qualified-20260925/` in `docs/quality/CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip`; 274827842bytes, SHA256 `33e916c63753b8cb0109fdd128e433ee71ed3866ccd8f82b1b36c42c796d464d`. All previous entries retained and every new entry read back byte-for-byte. Includes screenshots, native proof, original child failure, passing retries, final replay and analysis. Git preservation gate/commit is the remaining checkpoint step.


### Founder shutdown instruction — 25 September 2026

Finish only the current public polish, full Store text and subtle copy action. Reconcile the last24 hours of assigned Cursor Buy work, preserve all source/tickets/evidence, pass the checkpoint and verify Git clean before reporting shutdown readiness. Then hold remaining tickets until the founder resumes after approximately30 minutes. Do not start another ticket, new APK, integration or backend work during this pause. At this interim note, current changes are uncommitted and the final556-scenario replay is running; this is not an all-pass or clean-Git claim. The terminal checkpoint entry supersedes this interim status.


## 2026-09-25 — founder refinement and subtle Store copy action

The founder rejected the visual treatment at97035d1b while accepting categorisation. Reopened existing BUY-PUBLIC-POLISH-20260925-01; no duplicate ticket count. Public Buy, Wholesale, Bulk, Offers and Store product presentation remains the scope. Store workspace, backend, categorisation and commerce contracts are unchanged.

Save and Share now occupy the existing top toolbar outside product photos. The gallery maximum height changes from280 to240 to bring purchase information higher. Discount and inline Price details share a wrapping row. Seller, service and review icons use restrained teal with dark neutral labels. Delivery, detail, terms, review and benefit surfaces use nearly white gradients. Table labels11, body13 and headings14 establish hierarchy, with more width for specification values. Benefits retain all eligibility, sponsor and date facts with readable metadata. Disabled review/report controls remain disabled.

The founder additionally requested full Store text and a very small plain copy icon. Store type/status use the available horizontal space and wrap when necessary; supplied name/address wrap without ellipsis. The16px icon has a48px tap target and copies name, newline and address to the local phone clipboard only. An unavailable address is omitted, never invented. Success feedback and clipboard failure/retry are implemented. Two normal/200percent tests verify long text, exact clipboard payload, retry and unchanged SKU/cart; two more tests ensure Save/Share never overlap the gallery and retain identity.

Impact audit: the first replay found a Wholesale test still required the former280px gallery. Updated its exact expectation to240 while preserving MOQ, total, signal, containment, Add and navigation checks. A later replay was intentionally cancelled when the founder added full text; its logs remain preserved. The copy fixture initially mismatched facts/trust seller identities; corrected the fixture without weakening production validation. The Wholesale test also needed explicit scrolling to the moved toolbar. A Windows default-encoding edit damaged three middle-dot separators; all three were restored from verified HEAD text, and the focused test passed. Original failures and lint corrections are retained. These test setup findings are not claimed as new customer-visible defects. The existing service-wrap child remains covered.

Final current-source replay: **556 unique selected scenarios /586 case references passed in15 terminal-success batches, with zero failures or missing scenarios**. Analysis is clean. Source fingerprint: `ef001e3ebcf20dc3194916ff43e53c2d19d56ac65d39667e2fad72a7afba5140`. Earlier failed/interrupted runs are superseded and are not added to556. Every selected case binds its exact final successful log.

Final Redmi hot reload took3605ms. Frames606–635 retain iterations;628–635 show the final Store/copy revision,631 native copied feedback,633 enlarged text,634 review actions and635 the normal founder-review screen. Buy phone pricing/gallery/detail tabs and Wholesale comparison return were also inspected during this sweep. Frames626/627 do not establish Store entry, so fresh all-route device acceptance is not claimed. Final font scale1.0; Wholesale tomato10kg remains open; cart/saved state unchanged. No external message/search submission, purchase, new APK, push or Store-worktree change. Founder aesthetic approval remains pending. The owned Flutter hot-reload session was ended with detach and exit0 for shutdown; resume by attaching to the existing debug app rather than building an APK.

Counts remain **68 references =19 originals +49 follow-ups;24 targeted-verified follow-ups and44 pending full qualification**. No original parent, backend or catalogue closure is inferred. Appended171 evidence files under `refined-polish-copy-20260925/`; archive285753548bytes, SHA256 `b4ee0e08605e915bf66c47bb1e1f3f444d05660b863295dabe64a9f33c66321c`. Previous entries remain intact and every new entry was read back byte-for-byte. A 24-hour audit retained the existing Buy commits and found zero ignored source/test/config/script/quality files. The founder requested that remaining tickets stay on hold after this checkpoint until resumption. Git preservation gate/commit is the final checkpoint step.


## 2026-09-25 — resumed remote preservation reconciliation

Founder requested local/remote parity and then resumed work. Checkpoint 8bd814fc is clean and retains the 556-scenario qualification; no runtime change in this reconciliation. Remote readback remains the existing 5dc6885ada1fe0cd23f3d5d0a2bc62fe56cc0abd. Handoff rejected that historical docs(buy) subject. Extended the existing immutable SHA/subject reconciliation by exactly that one already-pushed commit, preserving root, actor, phase, branch, ticket and baseline restrictions. All other new commit prefixes remain enforced. No rebase, amendment, force push, APK or acceptance inferred. Focused guard validation and final handoff/push readback are required before claiming synchronization. Remaining frontend/device tickets resume after preservation; backend stays deferred.


### Resume outcome and remote storage blocker

Historical-label guard: exact historical commit accepted; wrong subject, SHA, phase and branch rejected (five checks). pre_commit and handoff passed; reconciliation checkpoint dff0b231. GitHub then rejected the normal push with GH001: eleven versions of CURSOR-BUY-REDMI-CHILD-FIXES-20260924.zip are over 100 MB. Remote remains 5dc6885ada1fe0cd23f3d5d0a2bc62fe56cc0abd. No forced push or rewrite attempted. A future commit removing HEAD archive cannot repair oversized ancestor blobs. Before another push, seek founder authorization for migration of unpublished history only, preserve original history in a verified backup, and retain all evidence. Git LFS 3.7.1 is installed; service quota is not established. Do not report local/remote parity.

Redmi TG8HCYTGGQT885OF remains installed r66.35/code2026092302. Device gate passed. Reopened existing debug app with original review/emulator candidate defines; attach session27332, reload1461ms, hot restart7145ms. Native app now shows current source. Shop tomato500g Add changed to quantity1 on the same price row without increasing card height; removal restored empty cart. Product opened with Save/Share outside photo, inline price disclosure and current seller presentation. No all-route closure, new APK, backend, real order or founder acceptance. Resume screenshots636-639 remain preserved locally under the existing ignored audit directory pending suitable remote evidence storage; they are not a new complete qualification archive. Existing556-scenario qualification is unchanged; no runtime edits this resumed turn. Total68 references,24 targeted verified,44 pending full qualification remains unchanged.


## 2026-09-26 — authorized unpublished-history preservation and LFS migration

Founder approved the complete recommended storage repair. Backups and recent resume screenshots were copied and SHA256-verified outside build/cleanup folders at C:/GUARANTEED OUTCOME/MOOLSOCIAL-PRESERVATION/cursor-buy-pre-lfs-20260926. Both bundles verified. Original branch history remains reachable through archive/cursor-buy-pre-lfs-20260926; never push that backup ref because its oversized ordinary blobs are intentional preservation.

Exactly 15 unpublished commits were migrated, leaving published Buy base 5dc6885ada1fe0cd23f3d5d0a2bc62fe56cc0abd unchanged. New migrated tip a766591aceeadb8dcc53d08b0fa1d191e99d47e2. Every non-archive/non-attributes Git blob and mode matches its original commit; all messages and parent mappings verified. All 11 archive versions match original SHA256/size and local LFS objects. gitattributes retains its original rules and adds only the exact evidence ZIP LFS rule; the working archive is hydrated. Current runtime and its 556-scenario qualification are unchanged. Historical commit references resolve using the retained original ref plus the complete mapping in CURSOR-BUY-LFS-MIGRATION-20260926.json; do not overwrite historical test evidence to pretend it ran at new IDs.

The Store lane independently advanced e1cdf7b5 to cad74a79 through a normal commit/push during verification; its code/worktree was untouched. Registered verification recoveries cover attributes whitespace normalization, common-repository LFS media lookup, concurrent Store refs and required hydration. Supplemental immutable CURSOR-BUY-RESUME-EVIDENCE-20260926.zip preserves the four previously local-only screenshots plus migration proof, scripts and backup manifests. New exact metadata/evidence owners are admitted in the existing primary claim.

GitHub billing read is unavailable with the current credential (missing user scope); no scope, payment or budget change. LFS upload must respect the account existing allowance/budget, and free remaining quota is not asserted. Final checkpoint gates and normal fast-forward push/readback remain the next step. No force push, published-history rewrite, APK, backend or ticket acceptance is authorized or inferred.


## 2026-09-26 — founder source-recovery-only decision (supersedes LFS upload plan)

Founder clarified that recovery needs app source and rebuild inputs, not old generated APKs or screenshot archives. Stopped only the verified owned LFS upload. Three objects had reached GitHub; no further archive upload or server-side deletion attempted. Published Buy branch still 5dc6885a at this decision.

Rewrote the 16 still-unpublished commits (15 migrated commits plus preservation metadata) to omit the two generated evidence ZIPs and the archive-specific LFS rule. Original and intermediate histories remain in verified external bundles and local archive refs. Every apps tree is identical before/after; source, assets, platform configuration, lockfiles, build/test scripts, contracts and ticket notes are retained. The two cart PNGs are referenced by regression tests, so they remain test inputs. No new APK was in this batch. Older already-published artifacts are untouched; this is not a global purge.

Source-only mapped tip:56497c5e062767e226cea6b0f82f90cb6559d854. Full mapping and exclusions:CURSOR-BUY-SOURCE-RECOVERY-20260926.json. Exact ZIP paths are ignored and physically retained locally for existing historical QA checks; local gates remain fail-closed and are not weakened to manufacture acceptance. Signing keys/service credentials need separate secure recovery and are never copied into Git. Final metadata checkpoint and normal push/readback are pending. Existing556-case source qualification and68/24/44 ticket counts are unchanged.


## Public catalogue implementation resumed — 26 September 2026

Founder scope: implement public portions of BUY-CATALOGUE-20260925-01 through -08, sequentially, using existing SKU/product/information/cart/saved journeys across applicable public channels. Store workspace implementation and latest Store mapping are deferred until public visual approval and successful Redmi hot reload. No new APK. Backend remains deferred.

Start with -01: typed category-applicable public facts in existing content contracts/session/tables; validate schema, stable IDs, units, duplicate/private/inapplicable fields and distinguish missing from false/zero. Existing variant, offer, compliance and fulfilment owners retain their responsibilities. Controlled fixtures exercise frontend contracts without representing production data. Local tests and Redmi/founder approval remain separate. Source-only Git preservation applies; generated archives stay local.

### Catalogue01 public implementation and device scope

Typed category facts now use stable IDs, public/product-or-variant applicability, explicit number/measurement/boolean/text/list types, schema validation and existing information tables. Unknown optional facts stay hidden; false and zero remain visible; typed IDs suppress stale legacy duplicates. Offer and lot facts are excluded from product-fact projection. Required invalid facts reject content readiness. No production provider or Store workspace changed.

Three CAT01 checks and the full191 content/variant scenarios passed after repairing test-only BUY-CATALOGUE-20260925-03-A01: supplier-photo replay now reveals the relocated toolbar before asserting Save/Share, then returns to the image for zoom/variant/Cart coverage. Parent01 remains open for the full category/channel matrix and native/founder qualification. Catalogue02-08 remain open.

Existing Redmi debug APK accepted hot reload (45 libraries/7882ms). A narrow Shop tomato product/Add/Cart/Back smoke check retained product,500g pack,quantity1 andINR37; removed only the test-added quantity. Source-only evidence stays under ignored apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/catalogue-01-*. No new APK.

Hot reload also resets local product navigation to Buy Home: reproduced with a zero-library reload; existing app-level debug reassemble recreates the router and BuyV2Session. Tracked as a review-lifecycle observation on catalogue08, not a confirmed release defect or a reason to edit shared auth/app ownership without admission. Reopen the visible product after reload before coordinate interaction. Latest Store-to-public mapping and provider implementation handoff remain deferred until founder visual approval, as requested.

Next sequential work: catalogue02. Existing compact selectors and 1/3/4/12-option tests are reusable; productVariantsFor currently enumerates only known catalogue products, so later-page family completeness/revision and exact resolution still need public-side wiring. No claim of complete catalogue01-08 qualification.

Interim preservation qualification:561 unique selected scenarios/591 case references passed in15 batches at source `6c6c0dd20a0d039451da96276193d446a7c859fcb4b5bbe51fadb2b099a8e3c7`; analysis clean for all5 modified source/test owners. Exact child test group names reconciled; unchanged first7 batches retained with membership/fingerprint assertions. Full191 content/variant tests also passed. This is an interim implementation checkpoint, not closure of the eight parents or founder approval. Generated evidence remains local/ignored under the source-only recovery policy.

### Catalogue02 public family loading — implementation in progress

Added optional BuyV2VariantFamilySource to existing public contracts. A snapshot binds selectedSKU,canonicalfamily,Store,channel,query/location/permission context,source revision andvalidity; it supplies complete choice metadata andonly the exact SKUs reachable by changingonedimension. No client-side Cartesian generation or whole-catalogue loading. Existing request limiter,product caches,compactradio/optionrows andCart owners reused. Late/foreign/incomplete/duplicate/stale data fails without replacing selection. Withdrawn variants cannot Add untilaffirmative refresh; offerfacts stillownstock/delivery authorization.

Development source implements this frontend seam using existing explicitlyreview-only catalogue templates, not Store workspace implementation. Local tests cover3colours/5storage,6colour/6size/6storage at1x/2x,1through6and12choices,failedrefresh/retry,withdrawal/removal/republication,late replies andlogicalmillion-SKU lookup bounds. Full entry-path qualification/native/founder review remain open. Latest Store read/mapping/provider scope file remains deferred untilvisualapproval.

### CAT02 Redmi bounded replay — 26 September 2026

Founder clarified that only provider-supplied, published product options should appear; absent colour/size/storage dimensions stay hidden. Test fixtures do not authorize default live choices.

Local content/variant impact run: 202 tests passed (`catalogue-02-impact-final.jsonl`); analysis clean (`catalogue-02-analysis-qualified.txt`). Native Offers -> shared product -> colour/storage -> Add -> Cart -> Back retained Ultramarine / 256 GB, correct image and INR70,000 review price. Test-added quantity was removed; Saved entries were not changed. Gallery reached image 2 of 2 on the repeated swipe. Initial Cart thumbnail placeholder resolved on repeat observation, so no persistent missing-photo defect is claimed. Local-only proof: `apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/catalogue-02-native-observation.json`.

CAT02 remains open for full entry-path qualification and founder approval; CAT03 onward remain in scope. Current implementation is uncommitted; previous pushed checkpoint remains b30ca05eda708586b5580daf22c9619421ed818c. No APK or Store-side mapping performed. Earlier lost screenshot output was recovered by reading the existing image; an incorrect read-only ADB serial probe failed without affecting either device.

### CAT03 gallery lifecycle audit — 26 September 2026

Added explicit last-of-seven -> one -> zero and exact 500ml variant replacement regression. Original Cart quantity stays intact and old photo keys disappear. Existing shared gallery passed without a production-code change. 9 surrounding gallery tests passed; changed test owner analysis clean. Local evidence: `catalogue-03-gallery-impact.jsonl` and `catalogue-03-test-analysis.txt` under the existing ignored Redmi audit directory. CAT03 remains open for the remaining binding/race and full entry-path matrix; founder approval is not inferred.

### CAT04 quantity validation child — 26 September 2026

Registered `BUY-CATALOGUE-20260925-04-A01`: quantity plus bypassed typed-entry validation. Failing numeric-bound regression reproduced before repair; plus now uses `setCartQuantity`, retaining prescription messaging. Revoked wholesale eligibility rejects increases while valid decreases remain possible. All 486 session tests passed after updating the impacted phone-family test to await bounded family choices and prove all six exact variants remain reachable. Analysis clean. Logs: `catalogue-04-plus-before.jsonl`, `catalogue-04-session-impact-qualified.jsonl`, `catalogue-04-child-analysis-qualified.txt` in the ignored Redmi audit directory. Child locally verified, native qualification and current checkpoint pending. Parent04 pack/units/steps/tiers and later tickets remain open.

### Founder amendment: real review catalogue — 26 September 2026

Founder requires real product examples for each applicable field/variant type on review screens, with reusable data for later backend work; synthetic visible products/prices do not satisfy this requirement. Existing review-only phone fixtures are not real seller inventory and must not be presented as such. Preserve automated boundary-test fixtures as test evidence; the new requirement concerns visible review data. Source provenance and exact product/variant IDs must be retained. Never invent missing photos, specifications, colours/sizes/storage, seller prices, stock, MOQ, tax or delivery. Awaiting founder choice between existing Store data read permission (mapping/integration still deferred) and manufacturer catalogue facts with unavailable seller terms. Keep all catalogue tickets open until applicable real-data review coverage is established; no backend readiness inferred from a frontend sample.

### Real-product source reconnaissance — 26 September 2026

Public manufacturer facts gathered while Store read/mapping remains deferred; these are candidate review examples, not published MoolSocial offers or confirmed stock.

- Apple iPhone16 technical archive: https://support.apple.com/en-in/121029 — five finishes (Black, White, Pink, Teal, Ultramarine), capacities128/256/512GB; physical dimensions71.6x147.6x7.80mm, mass170g. Current India sales specs https://www.apple.com/in/iphone-16/specs/ list128GB. Preserve this distinction: historical model options do not prove current seller combinations or availability. Exact Store SKU identities, sale prices, stock and each photo binding remain required.
- Amul official milk catalogue https://shop.amul.com/en/browse/milk — Calci+1L packs4/12, Calci+250mL packs8/32; Moti450mL pack24. Suitable real composition examples; do not confuse individual net content with outer-pack count. Published shop MRP is not a MoolSocial Store offer price or delivery promise. Exact product-page specifications/media still need verification before runtime use. Old Taaza URL redirected to homepage and is not accepted as current pack proof.

Coverage still missing: real apparel size/material options, exact colour/media bindings, supplier-owned MOQ/steps/tiers and sellable offers. No synthetic runtime catalogue was replaced during the source-frozen checkpoint run. This is public-side source reconnaissance, not the postponed Store integration scope document.

### Founder clarification: labelled test supplier — 26 September 2026

Founder permits supplier/product records for real testing, replaceable or removable before go-live. Public review catalogue should use traceable real product facts under an explicitly identified test supplier, with clearly test-only commercial terms where needed for Add/Cart journeys. These are not live seller offers. Keep test identity/provenance separable from real provider records and preserve the same public data contracts for replacement. No actual production account creation, backend write, payment or fulfilment is authorized by this frontend task; Store mapping remains deferred until visual approval. Earlier source-choice question no longer blocks preparation of the local labelled review catalogue.

Founder explicitly approved the labelled test supplier/account approach ("exactly approved"). Use real product facts plus disclosed test commercial terms in the existing public review environment; keep records removable/replacable before launch. No further source-choice confirmation is required for this approach.

### Public catalogue preservation checkpoint — 26 September 2026

582 unique selected scenarios / 614 case references passed in 16 batches at source fingerprint `0587b869d29322a8dff7a6877e56e5d4cf0df381f7068d4d6814c3e2fe00aa18`. Analysis clean across six changed owners. CAT02 provider-family loading, CAT03 gallery lifecycle tests and CAT04-A01 quantity validation are preserved together; this is not completion of eight parents. Real-data catalogue replacement, remaining pack/tier work, all-entry-path qualification and founder review remain pending. Runtime source was frozen during replay; evidence logs stay local under source-only backup policy.

### CAT04 pack checkpoint and requested pause — 26 September 2026

CAT04 resumed implementation: bounded provider pack price tiers now reprice the full Cart line on Add, plus/minus and typed quantity, including restored Cart and reorder; invoice/history snapshots keep their purchased price. Minimum-order labels use the minimum tier, not the currently selected higher-quantity discount. Inline price details show each threshold, exact sell-unit basis and unknown tax/freight honestly. Expired/foreign/malformed quotes fail purchase checks. Shared Cart metadata reuses existing compact variant/pack copy to remove repeated pack composition. Labelled Amul review data has disclosed test tiers400/380/360 for2/5/8 packs. First tier analysis had two missing-braces informational diagnostics, repaired before final qualification. CAT04 full entry-path/native qualification remains pending.

CAT08 child `BUY-CATALOGUE-20260925-08-A01`: persisted consumer Cart restores a same-ID product from a different Store because no retained identity constraint exists. Reproduced by `CAT08 restore rejects same SKU reassigned to another Store` in `catalogue-08-store-identity-before.jsonl`. Reuse the existing customer-state codec and session restore path; retain SKU/Store/family/options identity constraints without restoring purchase authority or replacing backend data. Exact additional frontend owner: `apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart`, already covered by selected customer-state tickets. Mismatches must remain unavailable and retained for explicit recovery; stable option label changes must remain valid. No Store worktree, authentication, backend, policy or governance changes. Separate full five-entry-path Product/Cart/Saved/Back and native matrix remain required.

CAT03 child `BUY-CATALOGUE-20260925-03-A02` — exact-owner cache binding: reproduced supplier media leaking from a cached same-SKU snapshot after Store/canonical identity changed without changing the media list. Original failing assertion and log: `catalogue-03-cache-binding-before.jsonl`, test `R669 supplier media contract CAT03 cached media cannot cross Store or canonical identity`. Repair scope is the existing session content-cache input binding plus focused media tests; no new provider/cache layer, Store worktree or governance change. Must reject old owner media and recover valid media when returning to the original owner. Delayed-photo tests already pass for Shop and Wholesale; this does not establish the full entry-path/device matrix.

Resume amendment: founder subsequently authorized continuing CAT03, CAT04 and CAT08 public implementation. Start by completing CAT03 delayed exact-variant image coverage using the existing gallery and supplier-media tests; retain backend/Store mapping deferral and no governance/policy edits. First added test did not compile because it assumed `BuyV2Product.copyWith` accepts destination. Repaired the test setup to select an existing product in each destination, preserving exact SKU/canonical bindings. Original failure log: `catalogue-03-late-photo-first.jsonl` in the ignored Redmi audit directory. This was a test setup failure, not an application defect or passing evidence.

Founder requested finishing the current Redmi cycle, preserving all Buy work locally/remotely, then pausing. No further catalogue ticket implementation starts in this checkpoint. Founder also explicitly prohibited governance/policy work: those files and gate requirements remain unchanged; this section records application verification and open work only.

Implemented optional exact-SKU pack composition, sell unit, provider unit-price label and legal minimum-plus-step quantities. Invalid bindings, malformed units and unsettled measured-weight products cannot Add. Product, catalogue and Cart controls use the same step; missing unit-price information is hidden. Amul Calci+ four 1L case uses the previously recorded manufacturer composition under a labelled local test supplier. INR400, MOQ2 and step3 are disclosed test commercial terms, not real seller terms. Product photo remains unavailable; no invented image or production supplier account.

Impacted issues repaired within CAT04: Shop pack MOQ/step was initially absent before Add; Cart accessibility tooltips still said Add one for a step of three; catalogue quantity callbacks used one instead of the provider step. Product/Cart widget replay covers these controls at normal and 200% text size. The review-template index test was updated for the additional unique pack template while retaining all six phone variants and rejecting repeated fixture SKUs. Initial wider replay had 622 passes and one stale cohort-index failure, not an all-pass result. A Cart tooltip test failed before repair. The final analysis initially returned exit0 with one missing-braces informational diagnostic; braces were repaired and the interrupted cumulative run is not qualification evidence. Final-source evidence is recorded separately below.

Redmi TG8HCYTGGQT885OF, existing com.moolsocial.app.cursorreview debug APK: model-field changes required a hot restart; subsequent UI hot reload was applied. Shop search -> Amul Product displayed minimum2/step3 before Add; Add2 -> Product plus5 -> Cart INR2000 -> Cart plus8/INR3200 -> Back retained the same product/quantity. Removed only test additions8->5->2->0; Saved not mutated. No APK built, checkout/payment performed or backend written. Local screenshot hashes and observations: apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/catalogue-04-pack-native-observation.json. A screenshot was requested before its capture process finished; the same process was awaited and its existing image read without repeating the action. A Cart transition screenshot was likewise reread after settling. These timing issues are not application-pass evidence.

All eight catalogue parent tickets remain open. CAT01 still needs full category/channel qualification; CAT02 complete entry-path/founder coverage; CAT03 complete gallery binding/race and real approved media coverage; CAT04 quantity-bound tiers/quoted price basis and remaining entry paths; CAT05-08 retain their registered information, offer consistency, catalogue discovery and identity/return work. Existing parents/children and prior 19-ticket dependencies remain in config/buy-founder-regression.json; this checkpoint closes no parent and does not claim backend/provider readiness. Full real-product review examples beyond this Amul pack, missing photos, founder approval, and later Store read/mapping/provider scope remain pending. No worktree integration or broad clean-up is performed.

Native presentation follow-up under CAT04: Cart currently renders both `1 L · Pack of 4` and `4 × 1 L · Case` on one metadata line. Quantity/total behavior passed, but redundant pack wording remains for founder review and a later compact presentation repair; it is not visually approved or silently closed. Final source-only braces correction hot-reloaded successfully (1/3185 libraries,2837ms); debug reassemble returned Home.

Final-source qualification:585 unique selected scenarios/617 ticket-case references passed in16 batches, plus the separate phone/pack review-cohort regression passed. Six-owner analysis reports No issues found. Source SHA256 `e2978fe6a305d895174893e5e57ee016e49f7bc6cc7ddab0f34394dc39d93be4`. Results: `catalogue-04-pack-final-checkpoint-results.json`; cohort:`catalogue-04-pack-final-cohort.jsonl`; analysis:`catalogue-04-pack-zero-analysis.txt`, all under the existing ignored Redmi audit directory. Source frozen throughout successful replay; earlier interrupted run not reused. Ticket ledger binds each selected case to exact final-source passing evidence. Commit/push verification follows; this text does not claim remote equality before readback.

### Resumed CAT03 / CAT04 / CAT08 — current work, 26 September 2026

Replay completion: the four-file impact run finished with 825 passing scenarios and two failed assertions. Both stale assertions were repaired: unsupplied description remains absent (entire seven-case content suite passed), and full Store catalogue uses the existing two-column layout rather than the older three-column width expectation (exact related-store continuation journey passed in `catalogue-08-store-layout-repaired.jsonl`). There is no single fresh all-pass cumulative run yet. The 12 focused CAT04/CAT08 cases passed. Full five-entry-path and codec-specific work remains; selected CAT08 route-test names are planned acceptance, not passing evidence. Do not checkpoint with those cases falsely bound to narrower tests.

The founder resumed implementation after the preceding pause/checkpoint. Previous 585-case qualification applies to checkpoint 01b6a0ed, not to these uncommitted changes. Backend and Store implementation remain deferred; no governance or policy owner changed.

CAT03 now invalidates cached product media when Store/canonical identity changes. Delayed previous-variant images cannot replace the selected image; same-media-ID revisions reset zoom and replace the decoded image. Focused tests passed; full native and entry-path qualification remains open.

CAT04 adds Store-bound, time-limited quantity tiers, explicit tax/freight disclosure, complete-line repricing in both quantity directions, restoration/reorder pricing, and removal of duplicate Cart pack metadata. Child CAT04-A02 reproduced restored quantity four entering checkout despite MOQ two/step three; checkout now reuses existing Cart validation, retaining the quantity for correction. The repaired test passes after correction to five. These are test supplier prices, not live seller offers.

CAT08-A01 reproduced the same SKU ID restoring under another Store. The existing account-scoped state codec now retains Store/family/option/pack identity constraints. Mismatches preserve recovery state and cannot open/Add the substituted product. Valid display/price updates restore normally. Full five-entry-path journeys and codec-specific acceptance remain pending; no parent is closed.

Focused CAT04/CAT08 evidence: `catalogue-04-08-restoration-qualified.jsonl` passed. Six-owner analysis: `catalogue-03-04-08-analysis.txt`, No issues found. Broader replay `catalogue-03-04-08-full-impact.jsonl` found an older assertion requiring a description although the content adapter intentionally leaves unsupplied descriptions absent. Only that assertion was corrected; the complete content-contract suite passed in `catalogue-03-content-impact-repaired.jsonl`. The broader run must not be described as all-pass.

Execution issues, not application qualification: two new identity test fixtures initially omitted the required Store ID and were repaired; Windows command-shell interpretation rejected a pipe-containing test filter before execution, replaced with `CAT0[48]`; two earlier metadata patch attempts failed atomically before edits. Redmi is connected and the existing app process is present, but Flutter attach did not establish a connection and was cancelled. No hot reload, APK, device acceptance, new commit, push or remote equality is claimed for this resumed work. Generated package-graph ordering changes from Flutter must be reconciled before checkpoint; preserve all application changes and complete the existing Git gates.
### CAT03 / CAT04 / CAT08 Redmi hot-reload replay — 26 September 2026

Existing Redmi debug candidate r66.35 (TG8HCYTGGQT885OF) was attached with its original review/emulator/candidate defines. Hot reload and in-process restart succeeded; no APK was built or installed. The product screen was visibly verified after the final restart and left open. Earlier attachment failures are superseded by this successful session, not by a new build.

New child BUY-CATALOGUE-20260925-04-A03 was reproduced on Redmi: a valid eight-case discount falsely showed Price changed and removed quantity controls. The shared offer decision now compares against the validated tier for current quantity at all seven call sites. Genuine price changes and stale facts still block purchase. Repaired Redmi quantity eight/INR360, five/INR380 and two/INR400 remained usable; Cart two total INR800 was verified. Final focused impact replay: 169 passed, zero errors; analysis clean. Source fingerprint: `6d829d8d4d01d24dce3393d7e80e84de5da151b75b1d56316d09cd6225523d8c`.

Native coverage: Shop/Store/Offers two-photo galleries and selected colour/storage; Wholesale horizontal storage selection to512GB; Store Saved return; separate same-variant Cart lines from two Stores; Bulk eligible25kg rice MOQ4; combined Cart totals and exact identity/Saved persistence through an in-process restart. Temporary Cart quantities and Saved phones were removed, preserving the original Saved rice. No checkout/payment/order/message was submitted. Slow thumbnail/loading transition captures are not defects or passing screenshot evidence.

Limits: all three parents remain open. Bulk multi-photo/variant review is pending because the review phone has no Bulk eligibility; rice verifies only that eligible pack journey. Complete entry-path matrices, CAT08 codec/adversarial identity journeys, founder approval and fresh cumulative qualification remain pending. Existing planned CAT08 acceptance names are not falsely bound to narrower tests. This hot-reload proof is separate from installed-APK release acceptance. Changes remain uncommitted; no clean-worktree or remote-equality claim.

Local source-only evidence manifest: `apps/mobile/build/buy-bounded-19-20260924/redmi-founder-audit/catalogue-030408-native-20260926.json`, with screenshot/log SHA256 bindings. Child local evidence is bound in the ticket ledger; founder approval remains unset. Device gate passed using the existing historical evidence archive; no governance or policy changed.
### Founder-requested safe Git checkpoint — 26 September 2026

Founder requested preserving all current work, clean local/remote equality before the next ticket, and selected finishing qualification with Redmi hot reload rather than an unqualified WIP checkpoint. A verified recovery copy of the original12 changed files and a reverse-checkable binary Git patch was created at `C:/GUARANTEED OUTCOME/BUY-SOURCE-RECOVERY-20260926/145101` before further qualification. It contains source/tests/records, not APKs or screenshot archives.

The pre-commit gate first rejected stale cumulative evidence. Added the previously planned CAT08 Product/Cart/Back/Saved-restoration regression across Shop, Wholesale, Bulk, Offers and Store at normal and200percent text. Its initial setup mistakes (lazy Save row lookup) were corrected; the five-path test passed. This adds a concrete checkpoint regression; broader codec/provider-change and founder acceptance requirements remain open.

The ownership check identified one earlier test correction outside the recorded Buy claim: `buy_v2_content_contracts_test.dart`, which correctly leaves a provider-unsupplied description absent. After disclosure, founder instructed following the production-grade approach. Registered only this exact test owner in the existing claim and its exact allowlist. Both changes are one added path; no validation predicate, registry entry, permission model or gate was removed/relaxed. The implementation coordination gate subsequently passed with136 claimed owners.

Further Redmi Cart-return replay reproduced CAT03-A03: the second gallery photo remained visible while its counter returned to1of2. The shared PageController now disables PageStorage page restoration so a recreated gallery resets its visible page and counter together. Local test reproduced actual page1 with counter1of2 before repair, then passed with page0/counter1of2 after repair. Hot reload15 succeeded (one library,4089ms); Redmi second-photo -> Cart -> Back now shows the first photo and1of2 together, retaining Ultramarine256GB, Store000001, INR70000 and quantity1. The temporary test quantity was then removed. Evidence: `catalogue-gallery-return-native-20260926.json` in the existing ignored audit directory. No APK build/install or transaction.

Final runtime/test source fingerprint for qualification: `0563fa92b36daeb6d2c7c038ccd067f590de919d1aa0bbfa60ad93105a7e7abd`. Nine-owner analysis clean. Earlier cumulative attempts were stopped when source changed and are not reused. The fresh601-scenario run is in progress; commit/push and remote equality are not yet claimed in this entry.

Final checkpoint replay completed: **601 unique selected scenarios / 635 ticket-case references passed in16 batches**, with unchanged final source fingerprint0563fa92b36daeb6d2c7c038ccd067f590de919d1aa0bbfa60ad93105a7e7abd. All selected local evidence now binds exact passing test names and final-source log hashes. Results: `catalogue-safe-checkpoint-20260926-results.json` in the ignored audit directory. Nine-owner analysis clean; device-memory gate passed4618 entries/482 applicable. CAT03-A03 and CAT04-A03 are locally passed and hot-reload retested, not founder-approved or release-closed. Parent tickets and broader remaining scope stay open. Temporary Cart item removed and corrected Ultramarine256GB product screen left open. Source-only commit/push verification follows; no APK produced.

Ownership reconciliation follow-up: founder authorized completing the production-discipline reconciliation. Added the same receiving-lines test path to the existing exact Cursor owner allowlist. No assertion, validation predicate, registry pin or permission model removed or relaxed. Prior claim-only attempt failed closed as expected.

### Active compact delivery instructions — 27 September 2026
Founder approved next after clean synchronized eeb88b41. Select only the queued receiving-control refinement under BUY-ACTION-POLISH-20260926-01; comparison redesign stays queued. Actor: public buyer selecting optional delivery instructions in single or mixed Cart, retained into existing checkout/order presentation. Classification: mvp_supporting, reducing space and clarifying destination ownership. Reuse _CartDeliveryInstructionSections/Card, existing destination-scoped session options/selection and existing Cart relevance tests. Owners: apps/mobile/lib/ui_v2/buy/buy_v2_views.dart; apps/mobile/test/ui_v2/buy/buy_v2_cart_relevance_widget_test.dart; existing ledger/scope/handoff records. Smallest complete change: compact horizontal radio-style choices, explicit null/No special instruction, common Delivery instructions heading with separate Shop/Wholesale groups when mixed; preserve supplied labels/IDs, per-destination persistence and clearing. No backend, shipment grouping, Store workspace, comparison redesign, dependency or APK changes. Test normal/200percent text, horizontal reachability, semantics, selection/clear and mixed-basket isolation; reuse existing Cart/checkout regressions, then Redmi hot reload for founder review. No provider capability, transaction success or device approval invented.

Compact instructions device proof: hot reload succeeded in8652ms. Actual Redmi Wholesale Cart at two packs/INR1160 shows a single compact Delivery instructions row. Selected Call receiving contact, scrolled sideways to Deliver to receiving and Loading access needed, returned and cleared to No special instruction; amounts/quantities retained. Left the row open. Evidence and hashes: apps/mobile/build/receiving-compact-20260927/device-evidence.json; final restored image redmi-restored.png.159 impacted cases passed; final two-owner analysis clean. Mixed destination isolation and200percent text verified locally; not represented as fresh mixed-basket device acceptance. Founder approval and full814-case cumulative qualification/Git checkpoint pending. No APK or order submission.

Founder wording correction: delivery choices are confusing; no instruction must not be recorded. Cancelled owned cumulative replay before mutation; its partial results do not qualify the new source. Make instructions optional/unselected with Clear only after selection. Change only public labels/details in existing buy_v2_cart_contracts.dart, preserving IDs, destinations, schemas and selection rules; update exact order-propagation expectation in buy_v2_cart_relevance_test.dart. Those two exact owners transferred from inactive historical Redmi claim to current primary and exact allowlist (156->158), under prior authorization for ownership reconciliation. No policy predicate, provider contract shape or validation rule changed. Verify selected instruction reaches order and clearing stores no instruction.

Latest delivery-instruction correction supersedes earlier No special instruction preview: no radio selected by default; small Clear action appears only after choosing and removes the ID. Shared labels standardized at their existing source so checkout/order copy uses the same words.175 impacted tests passed including selected/cleared order propagation; analysis clean. Native review found Clear inherited a larger font, repaired to11px matching the options;4 focused normal/200percent tests passed and hot reload2542ms succeeded. Current final replay is receiving-final-qualified-20260927; both prior partial runs are preserved but excluded from qualification. No schema or provider/backend mutation.

Final native instructions replay: selected Call on arrival survived hot reload; compact11px Clear was inspected, tapped and disappeared with every radio unselected. No placeholder is recorded; local order-propagation test proves deliveryInstruction null after clear. Redmi remains on this final optional row,2packs/INR1160. Evidence: apps/mobile/build/receiving-final-qualified-20260927/device-evidence.json. Founder approval remains pending.

Qualification binding repair: exact-case reconciliation found one payment-condition test absent from the first batch because a temporary metadata edit used Windows default decoding for the ledger, corrupting its rupee character. Rebuilt ledger from verified HEAD UTF8 bytes, retaining only this task's three new cases and refinement note. Runtime/tests unchanged. Full original text restored; missing exact case will run separately against the same source fingerprint and be included in the final proof before qualification. No tests skipped or expectations weakened.

Final receiving qualification:815 distinct selected cases/874 references passed against unchanged source be549282e3adb8515eb5350754041f970a0713c8f0f2c395ff818b5204d55f3e. Exact-case binder verified every reference, including separate payment-condition case after UTF8 metadata repair; no skipped/missing case is counted. Evidence: apps/mobile/build/receiving-final-qualified-20260927/qualification.json. Runtime instruction IDs/schema preserved; no instruction is null, not placeholder text. Removed tall tile/icon implementation. Technical qualification complete; founder visual approval remains pending and comparison redesign remains queued. Git gates/checkpoint follow. No APK.

Owner classification correction: runtime preservation gate rejected the labels owner because it was placed in the test qualification list. Moved the same exact buy_v2_cart_contracts.dart owner into the existing storefront runtime list; ownership count unchanged158. Only seven public labels changed in this owner; IDs, schema, eligibility and selection logic remain byte-equivalent. Gate predicates and directory permissions unchanged.

### Active R6633-D05-A01 comparison refinement — 27 September2026
Founder authorized Continue after clean synchronized ea980e96 and approved optional delivery instructions. Actor: public buyer comparing the exact product/pack/quantity. mvp_supporting: improve decision readability and visible result density. Reuse existing comparison controller, BuyV2ProductCard comparison-only branch and price calculation presentation. Exact owners: buy_v2_views.dart, buy_v2_catalogue.dart and buy_v2_product_actions_test.dart under apps/mobile existing Buy paths; ledger/scope/handoff records. Compact header; Store/Save/Add one row; delivered total prominent, compact item/delivery breakdown and arrival; retain full long names, large values, unknown charges, stale/refresh/error/pagination behavior. No calculation, provider/identity, backend, other card layout or APK change. Test normal/200percent, narrow width, exact Add/Save/Back/Cart, source admission/refresh and current selected regressions; show actual Redmi hot reload. Source fields remain authoritative; no fabricated additional results or unverified lowest-price claims.

Comparison native inspection: Store/Save/Add aligned, delivered total emphasized, three actual provider offers visible in a compact sheet. Removed duplicate bottom system-inset padding already handled by SafeArea. Changed breakdown label to Items because calculation is the requested quantity subtotal, not a single-unit price; exact numeric expectation preserved in existing buy_v2_session_test.dart comparison test. No arithmetic changes.

Founder refinement: maximise comparison results, one result per Store; right-half card space still rejected. Expand active comparison scope to existing BuyV2ComparisonController presentation projection: request existing contract maximum40, retain first eligible provider-ranked listing per Store across snapshot pages, expose later distinct Stores with current pagination, reset projection on refresh/query change. Do not invent Stores or alter ranking/calculations. Current controlled review source supplies exactly3 Stores; backend complete-query deduplication remains provider integration scope. Reuse already-owned buy_v2_session.dart and its comparison tests. Source rows remain intact for admission, revalidation and page boundary checks. Compress card into Store/total/Save plus price-breakdown/Add rows and arrival; adapt enlarged text. Stopped current817-case replay before mutation; partial logs retained and excluded.

Founder refinement R6633-D05-A01: full available-height comparison sheet with existing Close/Back, subtle blue gradient limited to lower half of result cards, dark readable text. Same public comparison owners and data boundaries; no additional provider rows fabricated. Interrupted prior cumulative replay before changing source; rerun final qualification after layout verification.

Comparison impacted-test repair: cumulative replay reproduced two stale less-than650px sheet assertions in existing owned buy_v2_post_redmi_fixes_test.dart at normal/200percent. Founder now requires full screen. Replace only old height expectation with exact844px/top0 and exercise accessible Close; preserve unavailable-provider and product Add checks. Register this test owner on D05-A01, rerun affected cases and selected replay; no gate predicate changed.

Comparison final qualification:818 distinct selected cases/877 references passed against unchanged source8f7df9f6229935e52f65eeff258cf279b5f390e37f1ddbfb12af87eec006c1de. Exact-case binder verified all selected references; analysis clean. Redmi full-screen lower-half blue cards inspected, Save toggle and Add/minimum quantity/removal verified; original one-product/two-pack ₹1,160 Cart preserved, comparison reopened. Current provider review source supplies3 Stores; maximum40 requested and one Store projection across pages tested locally. No backend or APK change. Founder visual approval remains pending; technical qualification complete. Evidence apps/mobile/build/comparison-release-qualified-20260927/qualification.json and screenshot hashes in ticket. Interrupted/failed runs excluded from qualification.

### Founder-approved comparison; active Buy search sweep — 27 September 2026
Founder approved c317328b comparison preview. New authorized scope: public buyer inline search inventory and contextual action placeholders across Buy/Shop, Wholesale/Bulk, Offers, public Store, Orders/help and Buy chat. Classification mvp_supporting: discover relevant products/orders/conversations without inconsistent boxes or misleading hints. Reuse existing TextFields/controllers/filtering; no search backend, provider workspace, unrelated module, barcode form or message composer changes. Exact runtime owners buy_v2_screen.dart, buy_v2_catalogue.dart, buy_v2_shop_chat.dart. Existing owned search/chat/product-action tests, regression ledger/scope/handoff. Main discovery, Store and category already inline; shopping-help field inherits boxed app theme; Buy conversation and in-thread message search have explicit rounded boxes. Replace these decorations with inline search; contextual hints stay placeholders, never query values. Preserve focus, Clear, Back, scope isolation, debounce, results and accessibility. Verify existing search paths at normal/enlarged text, local regressions, analyzer and Redmi hot reload; Git gates before preservation checkpoint. Other-workspace search inventory is contextual only, not authorization to mutate Store provider or Social/Food/Work owners.

Exact test-owner admission: add existing catalogue_copy_hierarchy_test.dart to root claim to repair its obsolete Wholesale-is-Bulk hint expectation and test both contexts. Ownership metadata only; no policy predicate/permission broadening. Search inventory: main Shop/Wholesale/Bulk/Offers/Orders/Medicine toolbar inline; public Store products inline; shared category search inline; shopping help inherited box repaired; shared commerce chat list and message search explicit boxes repaired. Barcode/manual-code, address forms, review fields and message composer are not searches and remain unchanged. Existing accurate Shop, Offers, Orders, Store and category wording retained.

Queued founder request — subtle current/selected state inventory: after active search-bar task, inventory existing tabs, categories, filters and navigation within public Buy/Wholesale/Bulk/Offers/Store/Orders where buyer cannot tell current screen or selected option. Refine existing selected states with restrained professional cues and accessibility semantics; do not add new selectors or implement during current search task. Status queued, not implemented/tested; exact owners and acceptance to be assessed before execution.

Founder screenshot clarifies queued selected-state defect: Offers Suppliers/MoolSocial top strip lacks a clear active publisher indication. Add a restrained visible selected cue to existing tabs; preserve current compact white strip, no new selector control. Include this concrete reproduction in upcoming inventory.

Search qualification owner reconciliation: claim exact existing catalogue_copy_hierarchy_test.dart and transfer existing shopping_alerts_test.dart from recorded historical claim to root, with matching exact test-owner lists. These are the two focused tests changed for founder-authorized search hints/inline behavior. No live subagents; no borrowed ownership or gate predicate change. Runtime and test source remain frozen for current819-case replay.

Search sweep qualification:12 inventoried contexts including normal shared Chat entry;3 boxed component layouts repaired, Wholesale/Bulk hints separated, existing accurate hints retained.819 selected cases/878 references passed against unchanged aaa165c6f0f5316a8a9c4b907ec166df67fe81a9b5c16b722e825676d8979f0e;16 contextual Chat checks additionally passed, optional capture skipped and not counted. Analysis clean. Redmi hot reload verified Wholesale/Bulk hints, rice query/results and clearing; normal shared Chat already inline, not represented as repaired contextual component evidence. Search UI founder review pending. Queued subtle selected-state inventory remains unimplemented. No APK or backend change.

### Reopened public search behavior parity — 27 September 2026
Founder reports Store search does not behave like Shop after prior visual/hint sweep. Actor public buyer; mvp_supporting consistency across existing public Buy searches. Reuse main search toolbar, paged Store search/controller and existing partner catalogue tests; exact owners buy_v2_catalogue.dart and buy_v2_partner_catalogue_test.dart, existing search tests read/replayed, ledger/scope/handoff. Concrete defects: Store right Done branch unreachable while searching; prefix becomes Back unlike Shop; Store query single-line instead of adaptive multiline. Inventory open/type/clear/submit/Done/system Back/outside focus/retained query/product return across Shop, Wholesale/Bulk, Offers, public Store/full catalogue, category/order/help/contextual Chat search. Scope remains public frontend; preserve Store query isolation, provider requests/80-char validation, filters, Cart and selection; no backend, shared-shell expansion, APK or queued selected-state implementation. Correct root layout condition/prefix and multiline field, local parent/impact tests and actual Redmi inspection before Git gates. Prior search sweep is not claimed to establish behavioral parity.

Reproduced impacted child: Store long unmatched search renders _CataloguePageNotice with onResetFilters callback but null action when maximumPrice is absent; null assertion crashes empty results. Bind reset callback only when a price filter exists; keep matching Reset label/callback and empty-results recovery. Existing Store parity tests now exercise unmatched long query, no crash/no spurious reset and return to valid query at normal/200percent. Width-only expectations superseded by right Done visibility, readable multiline input and preserved closed width; existing navigation/Cart/provider assertions retained.

Additional native parity finding: finishing Store query left both Clear X and Close X visible. Match main search by exposing Clear only during editing, showing Store info outside editing; retain query/results when Done is pressed. Interrupted cumulative replay before this runtime fix; partial run excluded.

Search behavior final qualification:819 selected cases/878 references passed unchanged source b4247389c05f72958102ef7fe8759ae7f246a75e818a255cd6e77e792bc4ef64;12 focused Store parity and Store-first journeys passed; analysis clean. Repaired right Done/prefix, adaptive long query, editing-only Clear, and shared empty-result callback/label crash. Redmi verified Store query/results, no-result recovery, Done retains query, single Close outside editing, Clear/Android Back restores Store without leaving route, original Cart2items/₹1,160 preserved. Store screen left ready. Long query verified locally; incomplete initial ADB long-input attempt is not native proof. Inventory and hashed captures recorded under R6634-C13 searchBehaviorReopened20260927. Founder review pending. Queued selected-state cues remain separate; no APK/backend work.

### Store search expansion parity reopened — 27 September 2026
Founder clarified missing tap/type expansion, not merely controls or wrapping. Public buyer; mvp_supporting existing product discovery. Shop uses animated collapsed44/active70/long120 (162 enlarged) control heights; Store uses natural TextField height with no matching transition. Reuse existing paged Store search/controller and exact owned partner catalogue tests. Smallest complete change: animated Store search sizing matching Shop tap, short-query wrapping, long-query growth and Done collapse; preserve store-only filtering, Cart, keyboard, Clear and Back. Inventory shared Shop/Wholesale/Bulk/Offers/Orders plus Store/full-catalogue entry paths; category/help/chat retain purpose-specific modal behavior. No backend, APK, other worktree or queued selected-state changes. Test active/long/collapsed geometry at normal and200percent, existing parent journeys, analyzer and Redmi hot reload. Prior819 checks did not assert this transition; expansion acceptance reopened.

Expansion inventory result: Shop, Wholesale, Bulk, both Offers publishers, Orders and Medicine reuse the existing animated search toolbar. Public Store/full Store catalogue/Store Saved share the corrected paged Store control. Category selection, help order lookup and contextual chat are dedicated modal/list filters, not product-discovery toolbars; no unrelated layout expansion applied. Additional difference retained openly: Shop blank query shows recent searches/suggestions; Store blank query shows Store products. Store-specific recent-search behavior remains pending assessment and is not represented as identical behavior. Native proof now compares Shop tap/type with Store idle/tap/type/long multiline/Done collapse. Four focused normal/200percent parity cases passed; analysis clean. Existing Store query scope and Cart retained. Screenshots and SHA values recorded under R6634-C13.searchExpansionReopened20260928. Cumulative qualification running; no new APK.

Expansion final qualification:819 selected cases/878references passed unchanged source5924efbda7e04cc08b5ca3479db5fc427451acd746fb0a097d9b0fe1dc481fb0; analyzer clean; actual Redmi idle/tap/type/long/Done inspected. No APK. Store recent-search-panel difference remains pending; no full-parity claim. Founder next instruction: Cart coupons and payment offers should start expanded with user collapse; execute after this checkpoint.

### Cart benefits default visibility and custom instructions — 28 September 2026
Founder requests existing Cart coupons/payment offers expanded by default, retaining collapse; replace rejected boxes-together option with optional customer-written delivery instruction. Public buyer, mvp_supporting existing Cart-to-order outcome. Reuse BuyV2CartView, delivery instruction lane, session and persisted customer snapshot, existing relevance/benefit tests; no new screen/backend/dependency or provider changes. Custom note must remain destination-scoped in mixed Cart, trim whitespace, enforce bounded length, persist through restored Cart, copy into corresponding confirmed order and clear correctly; no invented/default note. Preserve existing useful presets; no automatic coupon application. Test normal/enlarged text, collapse/reopen, unchanged totals, custom save/edit/clear/restore/confirmation; hot reload then Git preservation. Exact existing owners views.dart, cart_contracts.dart, session.dart, saved_products_store.dart and existing owned cart relevance/benefit tests plus ledger/scope/handoff.

Provider handoff addition — custom customer instructions: BuyV2OrderPlacementRequest.deliveryInstructionsByProductId carries optional trimmed max200-grapheme notes only for submitted product IDs. The checkout provider must map each submitted listing to its exact fulfilment order, persist the note there, expose it to the fulfilling Store and assigned delivery partner, and include it in authorized customer order snapshots. Do not send to unrelated suppliers/manufacturers or other sellers in a mixed Cart. For pickup, the recipient is the fulfilling Store; the separate collection-checkout transport still needs its own note binding and provider integration before claiming pickup delivery. No messages/notifications sent by this UI task; actual Store/rider receipt remains pending backend integration. Blank text is absent, not a default instruction. Rejected trade-cartons-together option removed, not reassigned to a different meaning. Customer snapshot retains custom notes separately from preset IDs. Existing Buy order detail/confirmation consumers read deliveryInstruction. Current UI helper and data capture are public-side only.

Cart final qualification — 28 September 2026: founder visually approved the contained composer on Redmi subject to technical verification. Stable Add instructions action reopens saved text; Clear/Save/Cancel are inside the same border directly below the field. Custom Clear changes draft only; saving blank removes the instruction, Cancel preserves the saved text. Coupons/payment offers start expanded without automatic application. Normal/200percent editor tests and analysis pass. All825 selected cases/884 references pass on unchanged source c5300b0a7437480b84a0973aa8111b16aef088ebdafa0f1418255b5f257467b3. Two responsive Cart tests now assert the expanded default and explicitly collapse before comparing unchanged collapsed-state references; five responsive captures pass. Earlier interrupted/failed replays excluded. Generated tracked failure images preserved with hashes in local build evidence before exact original-byte reconciliation. Current Redmi composer observed with keyboard open/dismissed; existing customer text and total preserved. Screenshots/logs are local evidence only, not remote binary backups, per founder source-focused retention preference. Actual Store/rider receipt and collection-checkout transport remain provider integration dependencies. No APK or notification sent. Selected-tab cue and Store recent-search parity remain separate pending work.

### Quiet active-tab cue — 28 September 2026
Founder queued and now resumed: Suppliers/MoolSocial look equally active; indicate the current selection quietly without adding a new selector, heavy fill or bottom underline. Public buyer, mvp_supporting navigation clarity. Reuse existing catalogue source buttons and sale-type segments in buy_v2_catalogue.dart; existing screen tests own selection/navigation and viewport coverage. Smallest change: a tiny dark active dot alongside the selected label, reserve equal space on inactive labels, retain white background/dark typography and existing callbacks. Add selected accessibility semantics to Offers publisher buttons. Inventory: Shop Quick/Scheduled and Wholesale/Bulk share sale selector; both Offers entry paths share publisher summary. Store single-context heading has no competing tabs; its category/filter selections already have their own state cues. Cart basket, product details, category options, filters and Orders already expose selected styling/semantics and are not redesigned. No backend, new route, global bottom bar, provider or APK changes. Verify switching all three pairs, exactly one active cue, selected semantics, normal/200percent readability, preserved Cart and existing impact tests; Redmi hot reload for review. Exact existing owned catalogue.dart and screen_test.dart plus ledger/scope/handoff; execute under BUY-ACTION-POLISH-20260926-01.

Expanded active-state inventory: founder explicitly includes Wholesale/Bulk and further public Buy surfaces. Found _CatalogueChromeAction carries active semantics but does not paint any active cue: affects Store category/filter and shared filters/Saved. Include tiny noninteractive active indicator; bind Offers category/publisher filter state and catalogue non-default category to existing active property. Existing Cart basket raised surface, benefit tabs tint, Orders/details selection border, variant/category/filter/checkout radios remain distinct and unchanged. Exact runtime owner remains catalogue.dart.

Selected-state final checkpoint: founder rejected tiny dot, then checkmark, then outline. Final approved treatment is borderless raised-white surface, soft shadow and bold dark text; inactive choices remain plain. Applies to Quick/Scheduled, Wholesale/Bulk, Suppliers/MoolSocial and active shared Store/catalogue category/filter/Saved controls. Offers accessibility selection merged with native button. Two focused normal/200percent complete pair-switch/category-clear/Cart-preservation cases pass; all827 selected cases/886 references pass unchanged source2b0d60f1b50136d5871a43277de59906f3bca6149beed2c0de4107f7fd9a5f89; analysis clean. Redmi final Suppliers/Scheduled/MoolSocial states captured and founder approved. Store-specific on-device replay paused when phone moved to profile; remains pending, not full device closure. Earlier dot/outline runs interrupted and excluded. No APK. Source and textual records retained in Git; screenshot/log binaries remain local evidence.

Next queued popup repair: current Redmi Offers publisher modal confirmed oversized title/chips, excess handle/gaps and narrow content. Founder specifically requests one horizontally scrollable row of compact content-fitting radio choices, filled selected circle, compact header/close. Inventory42 direct dialog/bottom-sheet entry points: catalogue18, views22, scanner1, product-video1; this is code inventory, not42 defects or completed native audits. Inspect equivalent choice popups; retain form/confirmation/gallery/category purposes. Existing catalogue owner and screen tests suffice for Offers; no shared theme, backend, policy or new route. Test source selection/dismissal, selected radio, horizontal reachability, normal/200percent labels, Cart preservation and actual Redmi preview. Record native screenshot and exact inventory in offerPopupQueued20260928. Start after selected-state Git checkpoint.


### Compact Offers publisher radio popup - 28 September 2026
Replaced oversized wrapped ChoiceChips with a single content-fit horizontal radio row, filled selected centre, compact left heading and Close control. Current selection is brought into view on reopening. Existing publisher callbacks and filtering remain authoritative. Focused normal/200percent checks passed for sizing, scrolling, selection, dismissal and Cart continuity; analysis clean. Actual Redmi hot reload verified sideways scrolling, MoolSocial application and checked selection on reopening, with Cart badge unchanged. Founder visual approval and cumulative qualification pending at this entry.

Popup inventory: 42 direct entry points (catalogue18, views22, scanner1, video1), recorded in the existing action-polish ticket. This is a code inventory, not 42 visually confirmed defects. Store filters already use compact radios; category windows reuse the contextual visual category picker. Shop/Wholesale refinements and payment/address sheets carry forms or extra decision information and require individual native review before further compression. Confirmation/information/video sheets are not single-choice filters. No backend, APK, shared-theme or policy changes.

Offers radio popup final qualification:829 selected cases/888 references passed unchanged source 4d9fafee26b248502c12130ee4507bc7f5f49e20fa6a7e7b43db2025acb76f2b; analysis clean. Native scrolling, immediate selection/application and reopened checked state verified. One tap applies and dismisses; no redundant Apply button. Popup left open for founder visual review; not yet recorded as visually approved. Git checkpoint preserves source and textual evidence records; binary captures/logs remain local under the existing evidence policy. No APK.


28 September founder approval: Annotation 2 explicitly approves the compact Offers radio popup implemented at 2f462ad6. This supersedes its founder-review-pending status; 829 local cases and prior native scroll/select/reopen evidence remain applicable. Separate queue audit requested for other Buy popups, Store selected cues and deferred bottom navigation; do not infer those are complete from this approval.

Queue verification28Sep: restored current2f462ad6 source on Redmi r66.36 with original defines through attach/reload and in-process hot restart. Store category/filter/Saved active raised surfaces and resets passed at normal text portrait; filtered products and Cart2items/INR1160 verified. No runtime changes; existing829-case qualification retained. Native enlarged/landscape/all-modal closure is not claimed. Other-popup42-entry inventory remains only partially device-audited; Store filter header/spacing retained as visual-review candidate. Bottom-nav ticket stays deferred, unimplemented and untested. Offers popup visual approval is explicitly recorded above.


## Customer ratings: definitive work-item specifications - 28 September 2026

Parent BUY-PDP-REF-20260924-05. Seven scoped work items; IDs below are parent-scoped planning references, not central regression IDs. All remain OPEN / not implemented under these new acceptance criteria. Existing composer/drafts are partial foundations. Backend remains deferred. User requested precise tickets and current Redmi testing, not backend deployment.

### 1. Verified-purchase eligibility and exact target
Reference: `BUY-PDP-REF-20260924-05/ratings/eligibility`. Owner: Buy frontend + backend integration.

Only authenticated owner of a delivered order line or confirmed collected line may rate. Placed, unpaid, cancelled before fulfilment and undelivered lines are ineligible. Partial deliveries unlock only fulfilled lines. A return after actual fulfilment must not erase eligibility. Server resolves customer/order/line/store/product/variant; never trust client eligibility or provider-supplied ratings.

Acceptance:
- Delivered/collected own line allowed; another account/Store/variant rejected
- Mixed order resolves each eligible line to its actual Store
- Offline/loading/expired eligibility prevents submit and preserves draft
- Direct API call enforces the same checks

### 2. One coherent ratings section and actionable composer
Reference: `BUY-PDP-REF-20260924-05/ratings/public-ui`. Owner: Buy frontend.

Shared PDP across Shop/Buy, Wholesale, Bulk, Offers and Store: display aggregate separately from Your review. Replace no-personal-review inference with You have not reviewed this purchase. No ratings yet only for authoritative zero published count; loading/unavailable separate. Compact stars1-5; optional written review up to 8000 characters; Write review/Update review; eligible order-detail entry deep-links exact line. Ineligible buyer sees Reviews available after delivery or collection and a factual reason. No redundant duplicate rating summary.

Acceptance:
- Aggregate nonzero and no personal review never says nobody reviewed
- Normal/200percent, keyboard, long text, portrait/landscape no overflow or hidden action
- Cancel/Back restores product/order scroll, variant and Cart
- Empty/zero stars blocked; whitespace-only optional comment stored absent; edit original review instead of creating duplicate

### 3. Authoritative review persistence and idempotent updates
Reference: `BUY-PDP-REF-20260924-05/ratings/durable-storage`. Owner: Backend deferred; Buy connector later.

Persist centrally: reviewId, authenticated customerId, orderId, orderLineId, storeId, productId, variantId, ratingType, stars, optional comment, verifiedFulfilmentAt, createdAt, updatedAt, version, moderationStatus. Delivery target additionally uses actual shipment/provider identity. Enforce uniqueness per customer/order-line/rating-type (Store service per Store suborder); idempotency and optimistic versioning. Backend returns saved record; UI claims success only after acknowledged save. Draft storage remains account-scoped and local.

Acceptance:
- Retry/timeouts/double taps create one review
- Kill/reopen and second signed-in device recover acknowledged review
- Account switch never shows another account draft or review
- Failed save keeps draft, no false success or aggregate increment

### 4. Respective Store reviews inbox and reply/report
Reference: `BUY-PDP-REF-20260924-05/ratings/store-workspace`. Owner: Store workspace + backend deferred.

Store owner sees only feedback linked to its Store, with product/variant, review, fulfilment reference and permitted customer display name. Separate product and Store-service ratings. Owner may reply publicly or report abuse through moderation; cannot change stars/customer text, self-approve moderation or hide negative feedback. Mixed orders never expose another Store private details. Notification/inbox delivery retries must not duplicate records.

Acceptance:
- Two Store accounts cannot read/reply to each other feedback
- One owner reply can be updated with audit history
- Negative valid reviews remain visible; moderation reason recorded independently
- No customer phone/address/payment data in public review projection

### 5. Separate completed-delivery rating
Reference: `BUY-PDP-REF-20260924-05/ratings/delivery-feedback`. Owner: Buy frontend + delivery provider/backend deferred.

Optional separate delivery-service rating after confirmed delivery, tied to delivered shipment and actual assigned provider. No delivery rating for customer collection; do not affect product or Store averages. Store may see an authorised service summary only, not unrelated courier/private records. Unassigned/unknown identity remains unavailable rather than guessing.

Acceptance:
- Collection suppresses rider rating
- Split shipments resolve each feedback to correct provider
- Wrong provider/account rejected; undelivered shipment blocked
- Product rating does not change when delivery rating changes

### 6. Server-owned rating summaries and published review list
Reference: `BUY-PDP-REF-20260924-05/ratings/public-aggregates`. Owner: Backend deferred; shared Buy display.

Public average/count derives only from published eligible reviews; expose rating distribution, verified count, target scope and paginated review list. Keep product, Store and delivery aggregates distinct. Exact variant remains on review; any family aggregate must declare scope. Seller cannot supply or override customer stars. Edit/moderation adjusts counters exactly once. Separate no data, zero ratings, unavailable and loading.

Acceptance:
- Published subset alone contributes; duplicate retry no count inflation
- Edited stars replace prior contribution
- Pagination has stable cursor and no duplicates
- Provider product metadata cannot overwrite customer aggregates

### 7. Complete rating journey and legacy reconciliation
Reference: `BUY-PDP-REF-20260924-05/ratings/qualification`. Owner: Buy QA + backend/Store QA when dependencies ready.

Inventory every active entry and retire superseded legacy local-only Store/rider success paths once route reachability is established. Qualify all five public entry paths, eligible delivered/collected and ineligible cases, mixed Store orders, exact variants, draft recovery, Store reply/report and public aggregate refresh. Native debug preview does not prove backend storage or notification.

Acceptance:
- Local tests for eligibility/identity/retry/account boundaries pass
- Redmi real backend save -> reopen -> Store inbox -> public review readback
- No real message/order/rating publication during frontend-only audit
- Child failures recorded against owning item and repaired before closure

Reuse and owners: existing buy_v2_views.dart composer, buy_v2_session.dart eligibility/submission, buy_v2_content_contracts.dart adapter and buy_v2_saved_products_store.dart account-scoped draft store. Store/backend exact owners require their lane mapping before implementation; no ownership grant or worktree integration implied. Existing frontend source is unchanged.

Redmi result: current attached source f69d63f2 on r66.36, normal portrait. Fresh tomatoes500g, Test supplier000001: Write review opens ineligible delivered-purchase sheet; Check again retains state; no submission enabled or made. Cart badge2 preserved. Evidence paths/hashes are in ratingTicketDefinitions20260928.nativeAudit. Eligible submission, backend save, cross-device recovery, Store inbox and replies are UNTESTED dependencies, not successful checks. False global no-review wording is confirmed from source condition on personal review, not a native nonzero-aggregate reproduction.

### Founder clarification: consumer-facing review discovery
The public-UI ticket must provide visible Rate your purchase beside each delivered/collected order item, Write a review in the product ratings section, and Your review / Update review after submission. Rating summary scrolls to the section. No hidden-menu-only entry or technical eligibility/provider terminology. Both entry paths use the same exact-purchase composer. If several purchases qualify, show item/Store/delivery date choices rather than requesting IDs. Composer: How was your purchase?, clear product/variant/Store identity,1-5stars, Tell others about your experience (optional), max8000characters, Post review / Save changes. After acknowledged save: Thanks for your review and View your review. Sign-in, not-yet-delivered and retry messages are distinct and plain. Rate this store and Rate your delivery are optional separate targets, not mandatory extra steps; collection has no delivery rating. Back/Close preserves origin, scroll, Cart and account-scoped draft. Explicit discovery, semantics, keyboard and enlarged-text acceptance checks added. This defines pending implementation; it does not claim current UI already matches.

Founder star-only clarification: supersede product entry Write a review with Rate or review, retain order Rate your purchase. Choose1-5stars then Submit rating; text optional and never required. No automatic submission on star selection. Whitespace normalizes to absent; repeated submission disabled in flight; failed save preserves stars/draft. Thank you for your rating appears only after acknowledgement. Existing requirement for optional text is retained; explicit star-only, zero-star, correction-before-submit and retry acceptance added. Current source still requires nonempty text, so this is a registered pending implementation gap, not claimed fixed.


### Additional checkout benefits: product-to-Cart wiring check (28 September 2026)
Founder-requested follow-up under the existing product benefits journey. Status: queued for code audit, implementation if gaps are confirmed, local testing and Redmi verification; not yet qualified. Continue the active rating implementation first.

Observable outcome: benefits shown for a product must resolve to the same provider benefit and exact Store/product/variant in Cart and Checkout. A display-only promise with no applicable Cart/Checkout path is not accepted.

Acceptance checks:
- Trace the product-page Additional checkout benefits preview through Add, Cart coupons/payment offers, selection and Checkout using stable benefit, Store, product and variant identities. Preserve the selected item and quantity across navigation.
- Show applicable benefits for the actual Cart lines. Mixed-Store carts must not apply one Store's benefit to another Store's items. Check Buy, Wholesale, Bulk, Offers and Store entry paths where applicable.
- Clearly distinguish available, selected, applied and ineligible benefits. Viewing or expanding benefits must not silently apply them. Show why a visible conditional benefit is unavailable.
- Applying or removing an eligible discount updates the relevant line/Store savings and Cart total exactly once. Conditional payment benefits must show their qualifying method and must not reduce the payable total before their conditions are met; distinguish cashback from an immediate discount.
- Revalidate on product/variant changes, quantity/pack/tier changes, item removal, Store changes, offer expiry/withdrawal and refresh. Remove stale savings and explain changed eligibility without losing Cart contents.
- Checkout must revalidate against the authoritative quote; reject stale eligibility, unsupported combinations and duplicate application. Offline/failure/retry must not claim savings or payment success that were not confirmed.
- Reuse existing product-benefit and Cart-benefit contracts/state owners. Implement public wiring now where missing; record exact deferred backend validation/persistence requirements without inventing provider offers.
- Add focused journey and failure tests, inspect on Redmi through hot reload, and register/fix any confirmed child defects. Record evidence before marking complete; backend end-to-end acceptance remains deferred until connected.

Initial source location: apps/mobile/lib/ui_v2/buy/buy_v2_views.dart, product benefits panel headed Additional checkout benefits. Its current copy says eligibility is checked again at Checkout; that wording alone does not prove Cart wiring. Audit remains pending.


#### Provider-flow clarification: product-specific and Store-specific benefits
Founder clarification: the preceding checkout-benefits ticket must include the originating Store workspace flow and public mapping, not only public-side display. Store/backend implementation stays deferred to the respective lane; this records its required contract, not permission to edit another worktree.

- Provider configures a benefit for its own Store and explicitly chooses product/variant scope or Store-basket scope. Product scope carries exact eligible listing/variant IDs; Store scope applies only to eligible lines belonging to that Store, never the full mixed-Store basket by accident. Any exclusions must be explicit.
- Provider flow: create/edit scoped benefit -> validate conditions and dates -> publish -> public readback -> amend/pause/expire/withdraw. Draft or unpublished benefits must not appear publicly. Provider ownership must be checked by the backend on every mutation.
- Required mapping: stable benefit ID and revision, Store ID, scope, eligible/excluded product/variant IDs where applicable, customer-facing title and terms, benefit type/value/cap, currency, minimum eligible spend/quantity, validity window/timezone, qualifying payment method if any, combination rules and publication status. Usage limits and customer eligibility are authoritative backend checks when configured. Use existing contracts where available; absence must not be interpreted as unrestricted eligibility.
- A Store-scoped benefit may be previewed on a product page as conditional, with its threshold and terms; it must not imply that buying that product alone qualifies. Product-specific benefits must follow the selected exact variant. Cart shows eligible amounts and which Store/items receive the benefit.
- A Store can publish only benefits it is authorized to fund/manage. Platform or payment-provider offers retain their actual issuer/authority and must not be represented as Store-created offers.
- Public wiring preserves the benefit ID/revision and scope through product -> Cart -> Checkout. The authoritative quote returns applied benefit references, eligible lines, discount allocations and payable total; order/invoice snapshots retain those references and allocations for later cancellation/refund reconciliation.
- Acceptance: product-only, variant-only and Store-basket cases; below/at threshold; excluded item; two Stores with separate benefits; combining/conflicting benefits; variant/quantity changes; provider edits or withdrawal during checkout; expired/unpublished benefits; unauthorized cross-Store configuration; duplicate retries. Verify provider publication -> public readback -> Cart allocation -> Checkout after backend integration.

Status: provider contract and cross-lane acceptance recorded; actual Store/provider capability audit, integration and end-to-end backend testing pending. Public frontend work must remain ready for these scopes and fail closed when required eligibility data is unavailable.


Consumer wording refinement: product composer heading is How was this product?; Store feedback heading is How was your experience with this store?; delivery heading is How was your delivery?. Shared guidance: Tap to rate. Add a review if you'd like. This supersedes How was your purchase? without combining product and Store rating targets. Store identity remains visible beneath the heading.


Final founder-approved rating heading: Rate your MoolSocial experience. Supersedes the earlier question headings. A short Product rating / Store service rating / Delivery rating subtitle identifies the target; the relevant product and selling Store identity remain visible. A product review belongs to its exact purchased product/variant and selling Store: backend must persist one review and project it both into public product feedback and that Store's workspace inbox, with authorization and moderation, without counting it as a Store-service rating. Store can reply/report, never edit customer stars or suppress negative feedback. Product feedback Store delivery remains deferred until backend integration.


### Rating frontend connector implementation - 28 September 2026
Implementation reuses the existing commerce snapshot, session, account-scoped draft store and product feedback composer. No new dependency, backend deployment or Store worktree modification.

Backend connection points:
1. The customer-authorized commerce adapter returns `BuyV2CommerceSnapshot.ratingTargets`. Each `BuyV2RatingTarget` has id, ownerScope, orderId, orderLineId, storeId, exact product/listing id, customer-facing purchaseLabel, kind, optional delivery shipmentId/providerId, and existing reviewId/version/rating/comment for edit/readback. Exact product id identifies the purchased variant; do not remap by product-family name. Backend issues targets only for the signed-in customer's fulfilled purchase and revalidates on mutation. Never infer authorization from these client-supplied identifiers.
2. Implement `BuyV2VerifiedRatingAdapter.submitRating(BuyV2RatingRequest)` alongside the existing commerce adapter. Request carries the exact target, stars, optional normalized comment and stable idempotencyKey. Return an acknowledged saved target with durable reviewId and advanced version; reject stale updates rather than overwrite another device's review. Server timestamps, moderation/publication state and authoritative aggregates remain server responsibilities.
3. The session accepts success only when the acknowledgement matches customer, target, order line, Store, exact product, kind, provider/shipment and requested feedback. Malformed success responses show failure. Account/eligibility changes invalidate pending results. Missing capability/target fails closed. Local review-mode feedback is deliberately not a live backend save or persistence claim.
4. Store the product review once and project it to that product's public feedback and the respective selling Store's workspace. Store service and delivery feedback are distinct targets. Enforce access controls for buyer, Store and delivery-provider views; Store cannot change customer stars. Readback must repopulate targets after app restart; local storage retains drafts only.

Verification so far: 538 existing review/session tests passed before the final boundary refinements; 21 focused rating/wording checks passed; final analysis clean. The 834-case selected cumulative run is in progress. Redmi hot reload verified delivered-order item entry, zero-star disabled, four-star submission with no written text and same-session reopening in review mode, and the final branded heading with product/Store identity. This does not prove server storage or Store inbox delivery. Screenshot hashes are recorded in the parent ledger; screenshots remain local ignored evidence.

Seven work-item status: eligibility, public composer and submission connector have frontend implementation; central storage, Store inbox, assigned-provider delivery and public aggregates require their backend/Store contracts and integration testing. Qualification is in progress. No claim that all seven end-to-end items are closed. Checkout-benefits product/Store flow remains queued after rating qualification.


### Founder superseding decision: one completed-purchase feedback entry
One consumer entry, Rate your MoolSocial experience, for a completed purchase spanning the original basket. Offer it after delivery/confirmed collection, not immediately after payment. Remove repeated per-SKU rating actions from the order item list. Product-page product reviews remain a separate optional journey. This supersedes the earlier requirement to place a rating action on every delivered order item. Implementation and requalification of this revised entry/target are pending; earlier per-item native evidence does not qualify the revised design.

Mixed-Store example: a purchase has 10 products from 10 Stores. The customer submits one overall order-experience rating/comment. Persist one purchase-level review and associate its review ID with the 10 participating Store suborders. Each relevant Store receives a scoped view of the same overall feedback, explicitly labelled Overall order feedback / Mixed-Store order. Do not clone it into 10 authored reviews, turn it into product ratings, or count it as each Store's own service rating. Do not require 10 forms.

Optional consumer flow in the same composer: allow feedback about a specific Store or item when the customer chooses to provide it. Those explicitly targeted ratings/comments go only to that target's Store. Overall text must be labelled as shared with Stores in this order before submission; Store-specific comments remain private to their respective Store. Store identity choices must use actual participating Stores, not a free-form destination.

Proposed provider navigation for later Codex implementation: Store workspace -> Orders -> Customer feedback, also linked from the relevant order detail. Reuse an existing feedback/reviews owner if the Store lane has one; confirm exact routes during its code audit. Use this as the operational inbox with filters for Overall order feedback, Store service and Product feedback. Store workspace -> Analytics -> Customer experience provides summaries and links back to the same records, not another review datastore.

Provider/back-end contract and acceptance:
- Authoritative purchaseId, buyer identity, reviewId/version, stars, optional comment, server timestamps and moderation state; target kind overall purchase versus explicit Store/product/delivery; exact participating Store/suborder mappings and fulfilment eligibility.
- Server verifies ownership and completed fulfilment for this purchase. Define partial completion, cancelled/refunded lines and split shipments before enabling overall eligibility; never infer whole-purchase completion from one delivered suborder. Keep available product/suborder review paths distinct where only part is fulfilled.
- Overall review stored once. Server-derived Store projections expose only authorized order context, not other Stores' items, pricing, addresses or internal data. Buyer-facing disclosure explains where shared overall feedback goes. Explicit Store/item feedback must not leak to other Stores.
- Overall purchase score remains an overall-experience metric. In Store Analytics show it separately as Shared order experience; Store-service and product aggregates count only feedback explicitly targeted at those subjects. Platform analytics count the overall review once. Never sum Store projections to inflate total review counts.
- Retry is idempotent; updates replace the same review version and refresh affected Store projections once. Preserve audit/moderation state. Store can respond/report through its authorized feedback record but cannot modify customer feedback or suppress negative ratings. Replies and notifications must preserve target visibility.
- Verify single Store and 10-Store purchase: one overall submission, one authoritative review, 10 correctly scoped overall-feedback views, no false Store/product-star attribution, optional target-only comment isolation, authorization, duplicate retry, edit/readback, withdrawal/moderation and account change.

Status: approved frontend journey change and deferred provider implementation requirements recorded. Do not mark delivery into Store workspace or Analytics implemented until backend publication, authorization, projections and real end-to-end tests pass. No Store code changed by Buy lane.


Implemented revision for single completed purchase: `BuyV2RatingKind.purchase` is a distinct target. Its `purchaseId` and `orderStoreIds` (suborder ID -> Store ID) are required, while single-product, Store, line and shipment identifiers must be empty/absent. The existing `BuyV2VerifiedRatingAdapter.submitRating` handles it with the same idempotency, owner, version and acknowledgement checks. Both purchaseId and the complete mapping must match the acknowledgement. Overall feedback must never update a product aggregate. Do not send a representative SKU as an overall feedback target.

`BuyV2Session.purchaseRatingTarget` requires exactly one valid owner-scoped target, a complete matching set of purchase suborders and delivered status for all suborders. Backend must additionally verify authoritative collection/fulfilment evidence, cancellations/refunds, and authenticated participation; local delivered status cannot grant access by itself. Partial/paginated order sets fail closed. No guessed mapping from Store display names. `submitPurchaseRating` reuses the verified save boundary. Orders renders one entry at the purchase-group level when this target is available; all repeated SKU rating actions have been removed. The product page retains its explicit optional product-rating entry.

The same composer shows the approved MoolSocial heading and clearly says Overall order rating, with disclosure that overall feedback is shared with the Stores in this order. Stars-only works, text is optional, and drafts remain scoped to the target and account. Optional separately targeted Store/product feedback is supported by distinct target kinds, not by automatically copying the overall stars. A combined Store-selection extension in the overall composer is not implemented in this checkpoint.

Local verification of the revised journey: 23 focused checks passed, including one entry/submission for ten Stores, empty comment, ten retained mappings, no product-rating attribution, and rejection when one suborder is still preparing; analysis clean. Cumulative replay is being rerun after repairing a stale Write review text lookup while preserving the existing enlarged-text word-fit assertion. Earlier per-SKU native captures are historical evidence, not acceptance of the new single-purchase entry. Native positive overall-submission needs an authorized purchase target from the connected adapter; do not manufacture one from an old local order.

Latest Redmi evidence: revised purchase-level source hot-reloaded; delivered-order item screen confirms repeated per-SKU prompts removed. Evidence 14-items-without-repeated-prompts.png is hashed in the parent ledger. Positive overall-purchase native submission remains pending an authorized adapter target. Existing device state was not treated as authorization to invent one. No APK built.

Final local replay: all 836 selected scenarios passed, 895 ledger references bound to unchanged source 46fd170b960ef386e31ab3eb5a7806f646d1367864fd59d7d9c57b872fa9c3d6. Analysis clean. Initial stale text-lookup failure repaired and complete replay passed. Native removal confirmed; positive overall-purchase submission and backend/Store delivery remain deferred as above. Git checkpoint gates pending at this recording.


### Queued: checkout journey duplication and screen consolidation
Scoped follow-up under BUY-ACTION-POLISH-20260926-01/checkout/journey-consolidation. Status: queued, not implemented. Founder reports repeated payment steps and excessive screens.
Audit the full Shop/Wholesale/Bulk/Offers/Store journey: browse -> add/multiple adds -> Cart -> delivery address -> continue/payment method -> review -> place order. Record exactly which screen owns address, delivery, optional instructions, coupons/benefits, payment method, final charges and the explicit purchase confirmation. Identify duplicated fields, repeated payment choices and unnecessary navigation. Consolidate where possible while preserving editable summary, cart/variant identity, back navigation, mixed-Store fulfilment, accessibility and recovery. Payment method selection, an authoritative price review and a real payment authorization are different actions; never remove a required authorization merely because wording looks repetitive. One clear final place-order action; no duplicate order/payment side effects on double-tap, retry or Back. Propose the revised sequence based on code and real Redmi screens, then implement and qualify within the authorized frontend lane. Backend/dependent payment behavior remains separately mapped. Do not begin this redesign while the Additional checkout benefits ticket is still being qualified.

Active scoped work: BUY-ACTION-POLISH-20260926-01/benefits/product-cart. Reuse the existing benefits adapter/session and inline Coupons/Payment offers area. Audit confirmed the benefit DTO has lane/destination but no explicit Store or product/variant scope. Add the smallest safe public contract and eligibility checks for actual eligible Cart lines; keep provider/backend scope deferred. Exact assessment/owners/acceptance recorded in the parent ledger before runtime edits.


### Additional checkout benefits: scoped frontend implementation
`BuyV2CartBenefit` now has explicit `scope` (platform/store/products), optional `storeId`, exact listing/variant `productIds`, and nonnegative `revision`. Store scope requires a Store ID; product scope additionally requires nonempty exact product IDs. Platform scope must not carry Store/product IDs. Existing platform benefits retain compatibility. Backend must authorize the issuer's scope: a Store must not publish a platform-wide benefit, and provider publication state, exclusions, customer eligibility and usage limits must be validated server-side.

The same provider benefit is reused in product preview and the existing inline Coupons/Payment offers area; no duplicate third copy is created. Scoped cards show eligible product names in a horizontal For row. Product benefits match exact SKU and Store. Cart thresholds and discount caps use only matching lines. Checkout splits the coupon saving only over eligible fulfilment groups, preventing a Store's discount reaching another Store. Selected benefit revision and scope are retained; changed/withdrawn scope or revision requires reselection. Checkout quote fingerprint carries the scope and revision, and the existing quote adapter receives the full selected benefit object.

Expiry rechecks use the provider's evaluatedAt plus elapsed client time, avoiding an assumption that the server and phone clocks agree. Product/Cart reads remove expired savings without requiring another provider refresh. Refresh must always return a current server eligibility assessment; backend revalidates again at quote/order creation. The frontend does not fabricate payment cashback or reduce payable totals for unconfirmed payment offers.

Existing one-coupon/one-payment-offer selection per shopping lane is preserved; this checkpoint does not invent stacking rules. Provider/backend must supply and enforce combination rules before enabling simultaneous Store coupons. Backend also owns final per-line tax/refund allocations, actual bank eligibility and authoritative order persistence. These are deferred integration requirements, not claims of frontend backend acceptance.

Local coverage: product -> Cart identity, wrong Store, removal, Store-only threshold, changed revision, expiry without refresh, checkout fulfilment-group allocation, and compact inline names at 100/200 percent. 39 focused existing/new cases and five focused scope/layout checks passed; analysis clean. Cumulative 841-scenario qualification running.

Redmi: hot reload succeeded; current rice basket remained 1 item / INR395. Coupons and Payment offers stay inline; switching tabs leaves the basket total unchanged. No offer applied, payment made or order placed. Current review provider supplies legacy platform offers and no scoped Store/product offer, so positive native scoped-benefit application remains pending provider data; mocked local scope tests are not represented as native backend proof. Evidence remains local and is hashed in the ledger. Queued checkout journey consolidation remains unimplemented.

Additional native replay: selected the existing review-only payment offer, saw Not eligible / minimum Shop product subtotal INR499 and Payment savings are not included in this total. INR395 payable remained unchanged. Removed selection and restored the original one-item basket. No payment/order/provider write. Captures 05/06 hashed in ledger.

Additional checkout benefits final local qualification: 841 selected scenarios passed; 900 references bound to source e0b20709371fd1d9044557b73edbe8c560a302d04aaed5387b6dd0d0cc4b9929. Analysis clean. Native inline tabs and conditional payment-offer selection/removal preserved INR395 Cart. Positive scoped-provider native acceptance and backend publication/final settlement remain deferred. Repository checkpoint validation is next.


### Approved mixed Cart execution admission — T01 — 20260928
Founder approved the five-step Add → Cart → Checkout → Final action → Order status flow and sequential frontend implementation with local tests, Redmi hot reload and founder visual review before advancing. Prior benefits UI accepted; positive provider integration remains deferred.

Actor: public Shop customer / Wholesale or Bulk buyer using the shared Buy Cart. Capability: browse Cart by context without silently changing the committed purchase selection. Classification: mvp_supporting under the existing Buy lane, necessary to remove checkout ambiguity. Exact scoped reference: BUY-ACTION-POLISH-20260926-01/checkout/journey-consolidation/T01 (not a new numeric registry allocation).

Reuse: buy_v2_session.dart owns cart/checkout state; buy_v2_models.dart supplies existing destination/sale-type identities; buy_v2_views.dart owns Cart display/actions. Focused existing checkout_cart_return_continuity, scoped_cart_checkout_dock_continuity and session tests are reused subject to recorded ownership. No new route, backend or application state owner. Implement display filtering independently from explicit purchase selection, totals and eligibility; preserve exact item/variant, account and pending-payment identities. Bulk is an existing sale type, not a new destination. Preserve Medicine/procurement behaviour outside this change.

Exclusions: no Store worktree mutation, backend/provider implementation, payment, APK, policy relaxation or T02 redesign. Dependencies: source ownership and required machine gates passed for existing implementation continuation; backend deferred. Acceptance: filtering does not change selected purchase lines; explicit subset does; total/count and validation cover the same selection; Back/restart and pending attempts retain identity; local impacted checks and Redmi review required. Status: admitted, implementation pending. No completion claimed.

Execution diagnostic: invoking task_start on this existing continuation rejected the exact-original-base check while Git was clean at 194bc172. The applicable implementation phase subsequently passed with registry 4618 and the existing recorded claim. No runtime edit preceded the pass; no gate was weakened.

The following two founder-approved planning documents are preserved verbatim in this existing claimed handoff owner, with hashes. Their workspace copies remain review exports; this repository copy becomes durable when the normal commit/push gates pass.

<details>
<summary>MOOLSOCIAL-CART-USER-JOURNEY-20260928.md — SHA256 5ce7fee384370aa70755af122688b65049f7ed0117bdf0f730e68ca2feefa60b</summary>

# MoolSocial Cart User Journey — Add to Delivered

Date: 28 September 2026. Status: founder-approved five-step customer flow; amended implementation specification. Application implementation and test completion remain separate.

Scope: customer-facing Buy, Shop, Wholesale, Bulk, Offers and Store entry paths; connected Store and delivery-workspace requirements. Related existing scope: `BUY-ACTION-POLISH-20260926-01/checkout/journey-consolidation`.

## 1. Decision

Keep **one mixed Cart**, with optional All / Shop / Wholesale / Bulk display filters. Filters must not silently change purchase scope. Purchasing a subset requires an explicit selection; Checkout identifies the selected item count. Do not force separate carts. Preserve exact variants and chosen supplier terms. Checkout groups actions by payment obligation and compatibility, not simply shopping type.

**Approved customer flow: Add products → Cart → Checkout → Final action → Order status.**

1. **Add products:** preserve exact variant, quantity and chosen terms. Do not force Cart navigation.
2. **Cart:** adjust products and offers, then tap Checkout.
3. **Checkout:** saved address, delivery commitments, selected terms and eligible payment method are populated. Change only what is needed.
4. **Final action:** pay the displayed amount or confirm the displayed orders with no payment due now. Required bank authorisation follows without another review page.
5. **Order status:** supplier allocation, acceptance and delivery proceed without compulsory customer steps unless an actual exception needs a decision. Delivered/collected is the fulfilment outcome; any authorised outstanding balance remains separately visible.

For a returning customer with valid details and one compatible payment, target two in-app actions from Cart: **Checkout → Pay & place orders**, plus necessary bank authorisation. New address entry, changed commitments and exceptional recovery can require additional actions.

Founder decision: direct purchase only, with product price, freight, eligibility and available terms already established before purchase. No customer Request quote or negotiation journey. Retail is fully prepaid to MoolSocial through its authorised payment collection arrangement. Retail Store rejection triggers eligible alternative-Store allocation; if supply cannot be secured, MoolSocial refunds the affected customer payment. Wholesale/Bulk retain supplier-authorised terms.

Delivery availability, fees and promises are established before commitment. Actual delivery assignment follows supplier acceptance and operational readiness. Completed orders proceed independently; retail must not wait for an unfinished Bulk payment.

## 2. Current source and required changes

Audited Buy checkpoint: `194bc1720122701085609603d9f422f36635400a`. Store source read from committed branch `work/codex-ui/add-product-screen1-20260920`, checkpoint `eea11308dac52d1baa58be5b63c117daa2db3748`. This does not certify other branches or uncommitted Store work.

Paths below are relative to `apps/mobile/lib/` in the respective branch.

| Current owner / evidence | Required change |
|---|---|
| Buy `features/buy/buy_v2_models.dart`: checkout steps address/payment/confirm | Replace compulsory three-stage presentation with one editable Checkout; retain validation and recovery states. |
| Buy `ui_v2/buy/buy_v2_views.dart`: `_CheckoutAddressStage`, `_CheckoutPaymentStage`, `_CheckoutConfirmStage` | Reuse sections in one screen; remove repeated review navigation and superseded UI after regression qualification. |
| Buy `features/buy/buy_v2_session.dart`: one `selectedPayment`, fulfilment grouping | Support resumable payment groups and independent outcomes. Existing display grouping is not a durable backend order identity. |
| Buy `features/buy/buy_v2_content_contracts.dart`: commercial terms, quotes, balance payment, pending-order recovery and live-delivery adapters | Extend/reuse contracts for authoritative mixed-order coordination; do not build a second commerce state owner. |
| Buy `features/buy/buy_v2_cart_contracts.dart` and session: scoped benefits | Preserve exact product/Store eligibility and allocated savings across checkout splits. |
| Store `features/work/widgets/store_payment_terms.dart`, `work_publication_data.dart` | Existing defaults/customer overrides support advance, balance-before-dispatch, balance-at-delivery, payment-at-delivery and credit preferences. Obtain authoritative customer eligibility and calculated obligations. |
| Store retail wording says full advance; Buy exposes COD | Founder has resolved this: retail is fully prepaid through MoolSocial. Remove retail COD from the applicable purchase flow; Wholesale/Bulk delivery-time payment remains contextual. |
| Store distinguishes Bulk offers, but inspected payment editor has Wholesale defaults | Define explicit Bulk applicability/inheritance and overrides; do not silently reuse Wholesale terms. |
| Store `features/work/work_session.dart`: delivery assignment blocks some scoped orders | Complete authorised Store-order → shipment → delivery-workspace routing. Existing operations do not prove end-to-end readiness. |

## 3. Customer screens and actions

| Stage | What to implement |
|---|---|
| Browse/product | Add exact SKU/variant and quantity. Show only supplied/published options. Respect MOQ, pack increments, stock and current price. Adding does not force Cart navigation. |
| Cart | Group products by Store with shopping-type labels. Allow quantity/removal. Keep coupons, payment offers and additional benefits inline, expanded by default. Show eligibility and actual versus conditional savings. One Checkout entry for the clearly identified selected scope. |
| Unified Checkout | Address; compact Store-order sections; delivery/collection and estimates; optional instructions; applicable payment terms and invoice details; payment actions; final totals. Edit in place or through a returning sheet. No separate final-review page. |
| Commit/payment | Explain the covered orders, amounts and any necessary payment count before the first commitment. Use the final-action rules below. No Request quote action or repeated per-Store confirmation. Each necessary external payment authorisation remains; no silent charging of later groups. |
| Progress/resume | Update the same checkout summary after each action. Show completed, awaiting payment, pending verification and unfinished groups. Preserve unfinished items; committed items remain linked to Orders and cannot be purchased again accidentally. |
| Order details | Show Store acceptance, payment and delivery separately. Keep balance payment, cancellation, help and invoice access with the relevant order. |
| Completion | Verified delivered/collected quantities; eligible return/support actions; one optional “Rate your MoolSocial experience” prompt per completed purchase, not repeated per SKU. Overall feedback may be projected to participating Stores with its overall-order scope clearly labelled. |

Use compact shared components, consistent typography and approved styling. Do not repeat product lists, promotional cards or payment explanations throughout checkout. Keep totals and necessary consent visible; support large amounts, long names, keyboard and enlarged text without clipping.

## 4. One Checkout, separate obligations

1. **Address:** reuse the selected address. Any change revalidates all affected Stores. Collection is offered only when supported.
2. **Store orders:** products, type, delivery fee/freight, estimate, collection location if relevant, and optional custom instructions. Instructions go only to the relevant supplier/assigned delivery provider; empty instructions are not recorded.
3. **Terms:** show authorised choices per Store/order type/customer. Retain the product-level selection; display order value, amount due now, balance and its exact due event/date with Change. Do not ask for the same decision again unless invalidated or materially changed. Credit requires approval; purchase-order documentation is not payment proof.
4. **Invoice:** request applicable GST/business data without duplicating entry; separate seller invoices and identities.
5. **Payment groups:** combine compatible due-now obligations only when the provider supports collection and exact allocation. Otherwise show explicit separate actions within this journey. Cash/COD, credit and bank transfer are available only under authorised terms and applicable limits.
6. **Summary:** Order total / Pay now / Due on delivery / Other scheduled balances, as applicable. All purchased items require final available price, freight and terms. Missing commercial inputs block the affected item with a clear availability message; there is no quotation detour. No hidden freight or assumed free delivery.

Example only: retail ₹2,000 full advance + Wholesale ₹50,000 with authorised 20% advance can produce ₹12,000 due now and ₹40,000 due on delivery. A Bulk credit order can require confirmation without immediate payment. Combine the ₹12,000 only if provider contracts permit it; do not invent these terms for real Stores.


## 4A. Binding UX and commitment rules for the approved flow

These rules refine sections 3–4 and govern their implementation. Payment grouping is an internal responsibility, not a compulsory Retail → Wholesale → Bulk wizard.

### Screen responsibilities

| Screen | Owns | Must not repeat |
|---|---|---|
| Product / SKU | Variant, quantity and applicable selected terms | Checkout or forced Cart opening after every Add |
| Cart | Item editing, optional subset selection, coupons and offers | Address, payment and review as separate compulsory stages |
| Checkout | Existing selections, delivery commitments, applied savings, final total and payment | Full promotional lists, repeated terms selection, per-Store forms, separate Review order page |
| Order status | Submitted/paid/pending orders, delivery, refunds and later balances | Charging paid lines again or requiring all remaining orders to finish |

Use compact summaries with expandable Store details. Only invalid/missing inputs expand automatically. Preserve scroll position and entered data after edits. Show Ready to place and, only when needed, Needs your attention. No generic checklist the customer must tick through.

- Cart offers remain expanded by default as previously approved. Checkout shows applied savings and a returning Change action, not another offers catalogue.
- Reuse saved address and applicable invoice details. Instructions remain optional. Show no empty-note step.
- A payment-method change immediately updates conditional savings and actual total. Material changes must be visible and acknowledged before payment; never charge the old displayed amount with a new hidden total.
- Checkout scope is explicit and independent of display filters. Items excluded by the buyer remain in Cart. A blocked item is not silently excluded: offer one clear Continue with ready items action showing what remains.
- Keep one main action visible. Secondary actions serve correction or recovery; avoid competing Continue, Review, Confirm and Pay buttons for the same decision.

### Mandatory compact design and immediate interaction

Founder requirement: UI/UX and visual design may change wherever necessary to deliver this journey. Enhancement is required when the existing design wastes space, creates clutter, adds repeated actions or breaks brand consistency. Preserve approved behaviour and data while replacing superseded UI; do not retain competing old designs.

- **Compact, balanced layout:** use available horizontal width before adding rows. Avoid empty half-cards, oversized headings, tall tab strips, duplicated labels and full-width buttons without a functional reason. Retain intentional spacing, readable text and accessible touch targets; compact does not mean cramped.
- **Brand consistency:** reuse approved MoolSocial colours, typography, icon sizing, button shapes, selected states and spacing across Shop, Wholesale, Bulk, Offers, Store and Cart. Do not introduce unrelated gradients, decorative panels or inconsistent controls.
- **Zero extra action by default:** retain valid selections and already-applied choices. Display necessary summaries without requiring a tap merely to discover essential charges, eligibility or payment obligations. Do not silently select optional paid services, borrowing or a new financial commitment.
- **At most one tap for routine Cart choices:** selecting an eligible coupon, offer, delivery option or another available single-choice preference immediately selects it, starts validation and updates the result inline. Use compact radio controls or the equivalent existing shared control. No extra Apply, Save, confirmation popup or next-screen-and-back journey for that choice.
- **Immediate, truthful feedback:** show the selected state and updated saving/total when validated. During validation, indicate progress and prevent stale checkout. A rejected selection shows its reason in the same area and preserves the last valid total; never display an unverified offer as applied.
- **Choice layout:** use compact horizontal choices where suitable, with a visible scrolling affordance when more exist. Keep the chosen value identifiable. Let text adapt rather than clip; essential totals and final actions must not require horizontal scrolling to discover.
- **Exceptions are purposeful:** typing a new address or custom instruction, explicit consent to changed financial terms, the final purchase action and bank authentication require their necessary interactions. The one-tap target must not remove those safeguards. Keep editors focused and their controls adjacent; return to the same position with state preserved.
- **Design acceptance:** verify actual screens for wasted vertical space, empty right-hand areas, clutter, repeated text and hidden actions. Test ordinary and enlarged text, long names, many options and large amounts. Routine option selection must complete without a second confirmation tap; previously valid choices must not need reselection.

### Final-action contract

| Situation | Action and effect |
|---|---|
| One compatible online payment | Pay ₹X & place orders. Identify all covered orders and any later balances. No second order-review page. |
| Nothing due now | Place orders under the displayed accepted terms. No dummy payment step. |
| Several necessary payments | Explain the total number and covered orders upfront; Pay ₹X — payment 1 of N. Following authorisations cover only remaining unpaid groups. |
| Bank transfer | Continue with bank transfer opens verified transfer details and establishes a pending-payment order/attempt. Do not claim it is paid or dispatch-eligible until verified. |
| Partial completion | Continue remaining checkout and View placed orders. Completed items never return to payable Cart lines. |

Before the first final action, state that eligible orders proceed independently. That action authorises the displayed no-payment-due orders and initiates the first payment group. Each group has its own durable result; an online payment failure does not silently cancel already-submitted credit orders. Show such partial completion explicitly. The backend must support this contract before enabling it; no client-only imitation of atomic multi-order success.

No-payment-due orders need no repetitive per-Store confirmation once included in the explicit final commitment. Subsequent payment actions must not resubmit them. If a material term changes, pause only the affected group and obtain the necessary new agreement.

### Recovery without trapping the buyer

| Event | Required customer experience and system action |
|---|---|
| Pending payment | Permit safe exit. Recover and reconcile automatically from Orders/checkout; show Check status and contextual help. No second charge while the first remains unknown. |
| Bank transfer | Copy beneficiary/reference details, leave and return. Automatic matching where supported; reference entry only for exceptions. Pending status does not require remaining on the screen. |
| Definitive failure | Keep selections; offer retry or an eligible alternative. Preserve successful groups. |
| Reservation expires before payment | Revalidate stock/price/terms before a fresh payment. Explain changes; do not reset unrelated selections. |
| Payment arrives after cancellation/expiry | Reconcile to the original attempt. Do not silently reopen the order or substitute supply; return funds through the authorised refund process if the commitment is no longer valid. |
| Cancellation races with reassignment | Record cancellation and allocation versions atomically. Once cancellation is accepted, prevent further allocation/dispatch; resolve in-flight payment and delivery events idempotently. |
| Cross-Store discount and partial success | Freeze funded allocations for completed orders. Recalculate only unfinished commitments before their payment; no surprise recovery charge against completed orders. Unsupported promotion structures must not be offered. |
| Supplier allocation delay | Show Payment received · Finding a Store, with the applicable deadline and help/cancellation options. No repeated buyer confirmation for equivalent, previously authorised replacement fulfilment. |
| Delivered on supplier credit | Show Delivered plus balance and due date separately. Delivery completion and optional feedback must not wait for full credit repayment. |

Timeouts must be explicit provider/platform contract fields: stock reservation expiry, payment-attempt reconciliation/escalation timing, supplier acceptance deadline and replacement-supply deadline. Show relevant customer deadlines/statuses. Do not invent durations in UI or activate an indefinite wait; exact values remain integration inputs.

### Additional acceptance checks

- Filter switching never changes checkout scope; explicit subset selection does.
- Product-level terms survive Cart, Checkout, Back and process restart without repeated selection.
- Ten Stores do not require ten forms or ten confirmations; only genuine incompatible payments require separate authorisations.
- Retail-only flow never exposes COD, credit or business-only fields.
- No-payment-due groups submit exactly once, including when a later online payment fails.
- Exit/reopen restores completed, pending and unfinished groups correctly; account changes never expose another customer's attempt.
- Changing payment method shows the revised offer/total before authorisation.
- Large text, long names and high values remain usable without hiding final charges or correction actions.
- No compulsory extra screen after payment; order status is the destination. Exceptions request only the missing decision.

## 5. Provider data and identity

Backend must supply stable IDs for checkout attempt, purchase, Store order, order line/exact variant, payment group/attempt, payment obligation, shipment, assignment and refund. Persist quote/term/offer revisions, validity, currency, integer minor-unit amounts and line allocations. Display strings or mutable SKU lists must not be authoritative IDs.

Required Store inputs: published product/variant, price tiers, MOQ/steps, stock, applicable channel, offers and exclusions, delivery/collection capabilities, published freight rules, acceptance policy, payment terms, authorised customer overrides, invoice identity, cancellation/return rules.

Backend resolves eligibility, inventory reservation/expiry, customer credit, payable amounts, compatible methods, provider limits and allocations. Client renders these results; it cannot grant credit, mark bank transfers paid or fabricate delivery assignments.

UPI limits must follow current category/bank/provider eligibility, not a universal hardcoded maximum. Do not automatically split transfers to bypass limits. Bank-transfer reference entry or screenshots mean awaiting verification, not paid. Review method limits when integrating the provider.

## 6. Placement, acceptance and delivery

Maintain independent state dimensions:

- Order: submitted / awaiting supplier / accepted / rejected / cancelled.
- Payment: not due / unpaid / pending / partially paid / paid / refund pending / refunded.
- Fulfilment: awaiting readiness / preparing / ready / assignment pending / assigned / dispatched / partially delivered / delivered or collected / failed or returned.

Before charging, validate/reserve the quoted basket as supported by the backend. Specify authorisation/capture and rejection-refund behaviour; payment alone never proves supplier acceptance. A backend checkout quote means a calculated, versioned total, not a customer quotation request. All terms must already be available for direct purchase. Retail supplier rejection follows the replacement/refund policy below.

After supplier acceptance, create an eligible delivery job against the shipment, subject to readiness and payment gates. Route it to the authorised MoolSocial or third-party delivery workspace. Dispatch requires any balance-before-dispatch obligation to be verified. Retry assignment with stable operation identity; do not create duplicate jobs.

Delivery providers receive only assigned shipment items and necessary address/contact/instructions. Reassignment removes obsolete access. Store users see only their Store orders. Customers see only their own purchase and shipment records.

Verify pickup/handover and delivery/collection through authoritative proof. Never infer delivery from payment or elapsed time. Separate shipments may complete independently; one delivered package does not complete the whole purchase. Do not expose fake live maps or stale locations as live.

## 7. Required use cases and recovery

| Case | Required outcome |
|---|---|
| Retail only; Wholesale only; Bulk only; mixed basket | Same journey, contextual fields and authorised obligations; no unnecessary business steps for retail. |
| Same Store in multiple shopping types; many Stores | Preserve prices/terms per line; split Store orders where obligations require it, with one readable purchase overview. |
| Conflicting payment methods | Explain separate payment groups before payment; preserve unsupported/unfinished items. |
| Price, MOQ, stock, freight or quote changes | Revalidate and disclose changes; require consent for changed commitments. Never substitute silently. |
| Expired offer or payment-condition failure | Recalculate affected unfinished groups; do not show potential savings as applied or rewrite completed allocations. |
| Cart edited during checkout or in another session | Detect revision conflict and refresh before committing; retain already completed orders. |
| One payment succeeds, another fails; app closes | Recover each immutable attempt; show partial completion; retry only unresolved actions. Unknown is not failed. |
| Duplicate taps, callbacks or reordered events | Idempotent order/payment/refund/assignment effects and authoritative reconciliation. |
| Retail supplier rejects, delays or partially accepts | Reallocate eligible unfulfilled lines under the replacement policy below; prevent double fulfilment; refund affected amounts if no supply is secured. No second customer charge. |
| Bank transfer pending, underpaid or overpaid | Provider reconciles amount and destination; no premature paid state; explicit discrepancy resolution. |
| Address unavailable; delivery plus collection | Explain affected groups; preserve others; revalidate changes and keep distinct fulfilment instructions. |
| Delivery unavailable, reassigned, delayed or failed | Accurate status and resolution; no invented assignment, silent surcharge or premature dispatch. |
| Partial delivery, cancellation, return or refund | Track exact quantities and allocated money; account for already paid/refunded amounts; do not affect unrelated orders. |
| Credit expiry, balance overdue, payment terms changed | Enforce authoritative eligibility and dispatch conditions; never silently replace an agreed committed term. |
| Customer abandons remaining checkout | Completed orders proceed; unfinished reservations expire according to disclosed rules; cart remains recoverable. |

Cross-Store promotions require an explicit partial-completion/cancellation rule. Before first payment, disclose eligibility and allocation. Do not retroactively charge completed orders to recover a discount without an authorised, disclosed process.

## 8. Implementation sequence and acceptance

1. Apply founder decisions: no quotation journey; retail prepaid through MoolSocial; rejection triggers replacement supply then refund if unavailable. Reconcile explicit Bulk/Wholesale terms, collection combinations, acceptance/payment timing, freight responsibility and partial-failure contracts with provider owners.
2. Reuse existing Cart, quote, terms and recovery owners; introduce only the state/contracts needed for payment groups and independent Store orders. Register exact ownership before code changes.
3. Implement unified Checkout and resumable progress. Remove superseded stage UI after impact checks; preserve existing working navigation, benefits, instructions and ratings.
4. Implement provider coordination separately: authoritative quotes/reservations, payment reconciliation/allocations, Store acceptance, delivery routing, balances, refunds and invoice records.
5. Test the matrix above locally, including long Store names, ₹1 crore display, large carts, enlarged text, back navigation, process restart and account switching. Test state transitions and money conservation, not only widget appearance.
6. Hot-reload onto Redmi for public UI/journey review. Record frontend/device results separately from real provider integration evidence. Native dependency changes require an authorised APK, not a hot-reload claim.
7. Qualify integration with real authorised test providers: mixed-store partial failures, payment recovery, Store acceptance, delivery workspace assignment and delivered proof. No actual money movement without separate authorisation.
8. Commit qualified source, tests and ticket/handoff records under existing repository gates; verify clean worktree and local/remote equality. Do not alter unrelated Store work or claim backend readiness from review fixtures.

Track every applicable matrix row as: not implemented / implemented / locally tested / Redmi verified / provider integration pending / integrated verified. Founder visual approval and technical acceptance are separate. This document creates no completion claim for any row.

## 9. Reference notes

- Normal UPI and category-specific limits: [NPCI FAQ](https://www.npci.org.in/what-we-do/upi/faqs). Bank/provider restrictions still apply.
- Bank-transfer characteristics: [RBI payment-systems FAQ](https://www.rbi.org.in/scripts/faqview.aspx/upload/FAQView.aspx?Id=144). Recheck applicable limits at integration time.
- This mixed-cart specification supersedes the earlier proposal to force separate Shop/Wholesale/Bulk checkouts. It does not authorise backend deployment, a payment, a new APK or claim zero remaining defects.


## 10. Retail replacement fulfilment and refunds — required behaviour

- Collect retail payment once through MoolSocial's authorised collection partner/account arrangement. Keep customer payment identity stable while supplier allocation changes. Supplier settlement is separate from payment collection.
- On rejection or acceptance timeout, retire the old allocation before assigning an eligible replacement. Use allocation versions and idempotent events so a late acceptance cannot cause duplicate dispatch or supplier settlement.
- Automatic replacement requires a disclosed customer agreement to alternative-Store fulfilment and the same exact product/variant, pack, quantity, quality commitments, customer payable and acceptable delivery promise. Do not silently change brand, seller-specific benefits, warranty, invoice commitments or delivery time. Obtain consent for material changes; otherwise refund. Clearly identify the actual supplying Store.
- Store-specific offers cannot simply be transferred to another Store. MoolSocial must fund the agreed saving under an approved rule or refund; never silently increase the customer's total. Resolve freight differences internally under a published rule, not by an unapproved second charge.
- Set a published, bounded supply-attempt deadline and cancellation behaviour; do not search indefinitely. If no supply is secured, initiate refund of affected paid items and allocated refundable charges to the original payment route. Display refund reference, status and provider estimate; do not promise an invented instant timeline.
- Partial supply affects only those lines; successful orders continue. Invoice, customer support, feedback, settlement and delivery assignment reference the actual supplier. Preserve the original seller/allocation audit trail.
- Wholesale/Bulk credit and negotiated supplier terms are supplier-specific: do not automatically transfer them to a replacement supplier. Revalidate and obtain customer consent or cancel/refund the affected order.

## 11. Standard Wholesale/Bulk payment terms

These are supported vocabulary and configuration proposals, not automatic credit grants or a claim every Rajasthan trader uses them. Research found advance and short trade-credit patterns; no uniform Rajasthan-wide schedule was established. Supplier-published, customer-authorised terms prevail. Keep Wholesale and Bulk applicability explicit.

| Term shown to customer | Required configuration and behaviour |
|---|---|
| Pay in full now | 100% due through MoolSocial before fulfilment. |
| Advance now; balance before dispatch | Supplier-defined advance amount/percentage; balance due event. Dispatch blocked until verified paid. |
| Advance now; balance on delivery | Advance collected now; remaining obligation assigned to an authorised collection route. |
| Pay on delivery | Wholesale/Bulk only when authorised. Prefer a MoolSocial payment link/QR at delivery; physical cash only where supported and permitted. |
| Supplier credit — pay by date | Customer credit eligibility/limit, outstanding exposure, credit days, due-date basis and overdue rules. Suggested configurable presets 7/15/30 days are UX choices, not mandatory market rules. |
| Scheduled account settlement | Explicit weekly/fortnightly agreed schedule and invoice allocations; no vague unlimited running credit. Treat as controlled supplier credit. |
| Early-payment discount | Published discount amount/rate and deadline; apply once to eligible obligations with correct invoice/credit-note treatment. |
| Bank-guarantee/LC-backed terms or lender finance | Only with a real integrated bank/lender contract and verified approval. Record them as conditional capabilities, not universally available launch buttons. |

Cheque/PDC is an instrument or security arrangement, not proof of cleared payment. If supported later, use pending-clearance/returned states and the supplier's release rules. A guarantee, PO number or uploaded bank receipt must never be treated as money received.

Evidence: [IIFL's FMCG finance overview](https://www.iifl.com/blogs/business-loan/fmcg-distributor-finance-managing-daily-high-turnover-supply) describes upfront/short supplier cycles and 15–30-day retailer credit, with regional variation. [PGC's distributor terms](https://pgcnamkeen.com/distributor) provide one concrete example: initial advance and qualifying BG/LC-backed credit. These examples support configurability, not universal defaults.

For qualifying micro/small-enterprise suppliers, enforce applicable payment-deadline requirements rather than allowing arbitrary credit days; the MSME guidance describes an agreed period not exceeding 45 days from acceptance. Supplier status and the statutory due-date basis must be authoritative. [MSME guidance](https://ramp.msme.gov.in/ramp/pdf-documents/scheme-guidelines/msefc.pdf).

## 12. Payment methods, limits and cost handling

Research date: 28 September 2026. These are reference rules, not a static promise that a bank will approve a transaction. Backend/provider capabilities, effective dates and bank/account limits remain authoritative.

| Method | Reference limit / eligibility | Implementation |
|---|---|---|
| Bank-account UPI | NPCI FAQ lists normal UPI up to ₹1 lakh per transaction; higher category limits are conditional. Bank daily/count limits can bind earlier. | Never assume FMCG gets a higher category limit. Show supported UPI and obtain actual success from provider reconciliation. |
| IMPS | NPCI lists up to ₹5 lakh per transaction except SMS/IVR channels; bank restrictions may be lower. | Offer bank transfer with verified beneficiary/reference and bank confirmation. |
| NEFT | RBI imposes no floor/ceiling for account-funded NEFT; bank/channel limits apply. | Suitable for large amounts; do not mark paid from customer-entered UTR alone. |
| RTGS | Minimum ₹2 lakh; no RBI upper ceiling. Bank/channel caps may apply. | Hide/disable below minimum with explanation; verify settlement through the collection arrangement. |
| Net banking | Bank and payment-provider limits, no single app-wide universal cap. | Treat gateway net banking separately from manual NEFT/RTGS transfer; charges and reconciliation differ. |
| Debit card | Issuer/customer-set online transaction limits, balance and acquirer controls. | No invented universal maximum; online use must be enabled. Provider authorisation determines outcome. |
| Credit card | Available credit, customer-set online limit and issuer/acquirer/merchant-category rules. | No invented universal maximum. EMI or credit-card-on-UPI only if specifically supported. |
| Wallet / other supported rail | Product/KYC/provider-specific limits. | Expose only enabled capabilities; do not inherit bank-account UPI rules. |
| Physical cash | Applicable tax receipt restrictions and collection-provider limits. | Wholesale/Bulk exception only; enforce aggregated applicable restrictions, not just a per-tap cap. No splitting to evade restrictions. |

Cash receipt rules include restrictions at ₹2 lakh or more by person/day, single transaction, or one event/occasion, subject to statutory scope/exceptions. Backend must evaluate the actual receiving party and related receipts. Do not advertise ₹1,99,999 as universally safe. [Income Tax Department guidance](https://www.incometaxindia.gov.in/w/which-transactions-are-covered-in-the-ambit-of-section-269st-?p_l_back_url=%2Fsearch%3Fq%3DSection%2B271C%26category%3D38317%26category%3D37782%26sort%3Dmodified-%26delta%3D60%26start%3D12%26category%3D39781&p_l_back_url_title=Search).

Sources: [NPCI UPI](https://www.npci.org.in/what-we-do/upi/faqs), [NPCI IMPS](https://www.npci.org.in/product/imps), [RBI RTGS](https://www.rbi.org.in/scripts/FS_FAQs.aspx?Id=65), [RBI transfer overview](https://www.rbi.org.in/scripts/faqview.aspx/upload/FAQView.aspx?Id=144), [RBI card controls](https://systemhealth.rbi.org.in/Scripts/PublicationsView.aspx_id%3D20315%281%29.html).

### Collect through MoolSocial wherever supported

- Bank transfer can also pay MoolSocial: provide a bank/payment-partner-issued collection account or virtual account mapped to the purchase/customer, rather than automatically directing money to a supplier's personal account. Final account and settlement architecture must be approved by the authorised bank/payment partner.
- Prefer supported MoolSocial UPI, bank transfer, net banking and cards for advances and later balances. Offer digital payment at delivery before physical cash, while respecting the accepted supplier/customer terms.
- If direct supplier collection is explicitly supported, label the beneficiary and collection owner clearly and reconcile it separately. Never describe those funds as received by MoolSocial.
- Show the previous eligible payment method where available and supported alternatives under More payment methods. Recommend using actual eligibility, verified customer cost and convenience. Never silently select borrowing or change accepted terms. Do not claim most buyers prefer bank transfer without product evidence.
- Distinguish customer charges from merchant MDR/acquirer fees, gateway fees and bank charges. Do not blanket-label debit/credit cards or UPI expensive, or all bank transfers free. Show only actual permitted customer charges before commitment.
- The Ministry of Finance's 15 September 2026 clarification states UPI MDR is not a customer charge and must not be passed to customers. Do not add a UPI surcharge based on merchant costs. Confirm current partner tariffs and applicable rules before activation. [Official clarification](https://www.pib.gov.in/PressReleaseIframePage.aspx?PRID=2310586&lang=2&reg=48).

### Limit and reconciliation logic

Represent method rules with currency, minimum, per-transaction maximum, known daily/count limits, merchant/category eligibility, bank/provider identity, customer fee, effective date and source. Unknown limits remain unknown; never pretend the app can see a customer's remaining bank limit without an authoritative API.

Check the amount actually due in that payment group, not the full order value. Apply the strictest applicable known limit and provider authorisation. Do not automatically split payments to bypass limits. Use an eligible alternative after a verified failure; resolve pending attempts before another charge. Preserve the cart and existing successful orders throughout.

Add acceptance cases for each method's below/at/above boundaries; customer-set lower limits; unavailable limit data; new-beneficiary restrictions; pending bank transfer; duplicate/mismatched UTR; under/overpayment; card failure; partial group success; replacement Store acceptance races; non-transferable coupons; no-supply refund; and late payment after cancellation. Amounts, charges, receipts, allocations and refunds must reconcile exactly.

## 13. Latest Store handoff — evidence boundary

The founder-supplied read-only shutdown handoff identifies Store commit `9fa3f5d94ef4a17280635e4968e03b128233fdfc`; remote readback matched on 28 September 2026. It supersedes the earlier Store checkpoint for future execution. It does not invalidate the earlier source observations, but affected owners must be re-read before editing.

The handoff reports 26/27 findings corrected, with Restock deferred until authorised integration. Physical failed-write, unavailable-provider and save-in-progress recovery remain unverified. Explicit keyboard dismissal was verified on OPPO enlarged landscape; floating-keyboard occlusion is not established as fixed. Store evaluation data and mixed-refund screens do not establish production backend or payment-refund readiness.

Preserve approved Store work; no integration or Store mutations follow from reading this handoff. The 14-ticket execution document records the affected dependencies. Source is pushed, but separate local Store evidence is not thereby remotely backed up. Detailed named evidence reports require review before relying on their acceptance results.

## 14. Founder execution boundary — frontend first

Supermandi payment-provider readiness is founder-confirmed. Current work prepares the frontend and maps to that existing provider; no replacement payment backend is requested. Store workspaces are under development and will map to the finalised public journey/contracts. Backend execution is deferred. MoolSocial and Wholesale/Bulk delivery-partner workspaces are still to be developed and will map to the frontend delivery requirements.

Consequently, current acceptance covers frontend implementation, local checks and Redmi review, with explicit adapter contracts and handoff notes. Production payment/refund orchestration and delivery/workspace integration remain separately deferred. The execution-ticket document's founder scope amendment supersedes earlier backend-dependent current-phase closure wording. Do not infer live transaction success from frontend tests or invent unavailable provider capabilities.

</details>

<details>
<summary>MOOLSOCIAL-CART-EXECUTION-TICKETS-20260928.md — SHA256 5c63f0e338bba62bb7ea5f313fa83065461679142b5028146cd186d3d896b4f6</summary>

# MoolSocial Cart — source-mapped execution tickets

Date: 28 September 2026. **14 execution work packages: 10 public-side, 3 frontend contract/handoff packages, 1 frontend qualification package.** Backend and workspace implementation are deferred. No new child defects confirmed by this planning pass. Counts exclude the pre-existing Buy backlog and do not imply implementation.

Companion: [approved journey](MOOLSOCIAL-CART-USER-JOURNEY-20260928.md).

## Registration and source boundary

These are scoped ticket specifications under existing `BUY-ACTION-POLISH-20260926-01/checkout/journey-consolidation`. Suffixes `T01`–`T14` below are document references, not invented numeric regression-registry IDs. Registry admission/ownership must use the existing process before execution. This review document is outside the Git worktree; it is not a claim of registry registration or remote backup.

Source pinned for mapping:

- Buy: branch `work/cursor-ui/buy-ready-20260921`, commit `194bc1720122701085609603d9f422f36635400a`.
- Store: branch `work/codex-ui/add-product-screen1-20260920`, commit `9fa3f5d94ef4a17280635e4968e03b128233fdfc`. Since the previously inspected `eea11308`, the scoped Work-source diff changes only the dashboard file; payment preference definitions inspected remain unchanged. Re-read affected live source immediately before execution.
- Classification: launch-required commerce journey. Preserve unrelated Social, Medicine, Store, Counter Sale and backend owners. No APK, real charge, deployment or policy edits are authorised by this plan.

## Owner map

All aliases are existing paths under `apps/mobile/`:

| Alias | Exact path |
|---|---|
| V | `lib/ui_v2/buy/buy_v2_views.dart` |
| S | `lib/features/buy/buy_v2_session.dart` |
| M | `lib/features/buy/buy_v2_models.dart` |
| C | `lib/features/buy/buy_v2_content_contracts.dart` |
| B | `lib/features/buy/buy_v2_cart_contracts.dart` |
| WP | `lib/features/work/work_publication_data.dart` |
| WE | `lib/features/work/widgets/store_payment_terms.dart` |
| WS | `lib/features/work/work_session.dart` |
| WG | `lib/features/work/work_services.dart` |
| WV | `lib/features/work/screens/work_workspace_dashboard_screen.dart` |

Aliases identify source areas, not permission to mutate another lane. Shared contracts C/M require coordinated ownership. Provider backend implementation paths were not audited to a current authoritative owner; T11–T13 must resolve those exact owners before implementation, rather than invent files or claim frontend completion is backend completion.

## Conflict prevention

- Execute Buy mutations serially: many tickets touch V/S. Never assign those files to concurrent writers.
- T01 owns selection scope; T02 owns the unified layout/navigation; T03 owns terms; T04 owns benefits presentation; T05 owns payment-method eligibility; T06 owns attempt/group state; T07 owns recovery; T08 owns order status; T09 owns replacement presentation; T10 owns visual consolidation only. Later tickets extend these owners, not parallel copies.
- Existing `BuyV2CartScope` is `all/shop/wholesale/medicine`; Bulk is `BuyV2WholesaleSaleType.bulk`, not a standalone destination. Add contextual display filtering without misclassifying Bulk or exposing Medicine as new launch scope.
- Current S copies `cartScope` into `checkoutScope`. Deliberately replace that coupling in T01 and update tests that encode it; do not merely repaint the scope tabs.
- Legacy checkout step enum and persisted state must be migrated/read safely. Remove obsolete screen transitions only after restore/back tests pass; do not break older saved pending-payment records.
- Existing provider adapters, ratings, optional instructions, scoped offers and recovery logic are reused. No duplicate state owner or speculative payment service.
- Old tests are classified: retain valid invariants, update deliberately superseded UX assertions, add missing behaviour tests. Never delete failing checks solely to obtain green status. Respect test ownership; e.g. `buy_v2_product_benefits_preview_test.dart` is a reuse/read candidate, not an assumed current-lane write owner.

## T01 — Mixed Cart scope and exact-item continuity

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** None.
- **Where:** V: BuyV2CartView, _CartScopeBar; S: cartScope/checkoutScope, _linesForScope and checkout entry; M: scope and sale-type models.
- **Logic/change:** Separate display filter from explicit selected purchase lines. Default to all eligible cart lines; preserve excluded lines. Carry SKU/variant, Store, quantity and chosen terms without conversion. Bulk filtering uses saleType. Persist selection without reviving already committed lines.
- **Expected Redmi UI/UX:** All/Shop/Wholesale/Bulk filters change visible items only. Checkout clearly shows purchase item count; explicit subset selection updates it. Switching filters does not silently buy fewer items.
- **Acceptance/evidence:** Exercise five entry paths, mixed Store/types, Back and restore; extend scoped_cart_checkout_dock_continuity and cart_line_continuity tests. Redmi: add retail+Wholesale+Bulk, switch filters, verify same purchase scope and exact variants.

## T02 — Unified Checkout and removal of repeated stages

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T01.
- **Where:** V: BuyV2CheckoutView, _CheckoutAddressStage, _CheckoutPaymentStage, _CheckoutConfirmStage, progress/action bar; S: continueCheckoutFromAddress/Payment and checkout Back handling; M: BuyV2CheckoutStep.
- **Logic/change:** Recompose existing sections into one editable screen. Retain valid address, terms and method; expand only missing/invalid information. Remove compulsory Address→Payment→Confirm progression. Map restored legacy steps to the correct section/recovery state without resetting attempts.
- **Expected Redmi UI/UX:** Cart→Checkout opens populated compact summaries and one main action. Change opens an inline editor/returning sheet; no Review order screen or repeated confirmation. Focus/scroll return correctly.
- **Acceptance/evidence:** Extend checkout_cart_return_continuity and payment_sheet_motion tests. Redmi: saved address needs no extra selection; edit/back/keyboard restores state; restart on each legacy stage safely resumes.

## T03 — Contextual terms, address, invoices and instructions

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T02; authoritative terms from T11 for integrated closure.
- **Where:** V: _CheckoutCommercialPaymentTerms, BuyV2CheckoutGstDetails, collection/receiving sections and existing instruction composer; S/C: commercial terms, address validation and collection contracts.
- **Logic/change:** Retain product-selected terms; show due-now/balance/date once. Retail prepaid only. Wholesale/Bulk use independently scoped supplier/customer eligibility. Reuse saved GST/address; optional instructions stay optional. Revalidate affected groups on address changes. Do not transfer credit between Stores.
- **Expected Redmi UI/UX:** Retail sees no credit/COD/business-only clutter. Wholesale/Bulk show compact accepted terms with Change. No required instruction or GST step where inapplicable; invalid delivery identifies only affected items.
- **Acceptance/evidence:** Reuse wholesale_checkout_receiving_location/lines and wholesale_payment_attribution tests. Redmi: mixed terms, collection versus delivery, empty note, address invalidating one Store, changed term requiring new consent.

## T04 — One-tap offers and final-total continuity

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T01–T03.
- **Where:** V: _CartBenefitsInline, _InlineCartBenefitPanel, _CartBenefitCard, checkout savings summary; S/B: existing scoped benefit eligibility and allocation.
- **Logic/change:** One tap selects and validates an eligible offer; no Apply page. Keep Cart panel expanded per approval. Checkout shows applied summary only. Recalculate conditional payment savings on method change and preserve committed allocations; show reason for invalid selection inline.
- **Expected Redmi UI/UX:** Tap radio→selected state→validated saving/total in same card. Checkout contains no duplicate offers catalogue. Changed method displays changed payable before authorisation.
- **Acceptance/evidence:** Extend benefit_selection_continuity; preserve existing product preview tests. Redmi: eligible/ineligible/expired offer, Store mismatch, quantity change and method-change savings; no second Apply tap.

## T05 — Payment methods, amount limits and collection destination

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T03–T04; T11 method capabilities.
- **Where:** V: _buyV2CustomerPaymentChoices and shared payment chooser; S: choosePayment/available methods; C: extend current payment/term capability contracts under coordinated ownership.
- **Logic/change:** Remove retail COD; retain authorised Wholesale/Bulk alternatives. Evaluate actual due-now amount against authoritative method minima/maxima and eligibility. Prior valid method first; more methods secondary. Show verified recipient and customer fee. Unknown bank remaining limit is not a fabricated number.
- **Expected Redmi UI/UX:** Eligible UPI/card/bank transfer shown with meaningful labels. RTGS below applicable minimum explains unavailability. Large amount keeps readable digits. No claim transfer is always free or auto-split to evade limits.
- **Acceptance/evidence:** Test lower/equal/upper boundaries, unknown capabilities, changed bank limit and fee/offer refresh. Redmi: ₹1,000 through ₹1 crore, eligible method changes, no dead-end disabled action without a reason/alternative.

## T06 — Payment groups and explicit final commitment

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T01–T05; T11 authoritative orchestration.
- **Where:** S: submitOrder, checkout submission state, existing placement/reconciliation methods; C/M: placement request/result and durable group identities; V: _CheckoutPrimaryActionBar.
- **Logic/change:** Replace single-method assumptions with compatible obligation groups while reusing state owner. Display scope/payment count before first action. No-payment-due orders submit once within explicit commitment. Each payment authorisation covers only its group. Persist independent results; no frontend pretend-atomic success.
- **Expected Redmi UI/UX:** One Pay ₹X & place orders for a compatible basket; otherwise clearly explained payment 1 of N. No-payment-due uses Place orders. Payment success does not claim supplier acceptance.
- **Acceptance/evidence:** Test mixed paid/credit orders, second payment failure, repeated taps and out-of-order responses. Redmi with authorised test provider: no duplicate orders; already-submitted credit group survives payment failure. Integrated acceptance blocked until T11.

## T07 — Resume, bank-transfer pending and safe recovery

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T06.
- **Where:** S/C: pending-order recovery, reconciliation, existing account-scoped persistence and balance-payment adapters; V: _CheckoutPaymentStateRow and confirmation/continuation UI.
- **Logic/change:** Reconcile original immutable attempt before retry. Allow exit during pending transfer/payment; do not require screenshot/UTR as ordinary success proof. Restore completed/pending/unfinished groups separately. Handle late payment after cancellation through original attempt/refund policy.
- **Expected Redmi UI/UX:** Customer may leave safely and resume remaining checkout. Paid lines are not payable again. Pending says payment being checked with status/help; verified failure offers retry/change method.
- **Acceptance/evidence:** Reuse order_resolution and order_issue_recovery_continuity tests. Redmi: process restart, network loss, callback delay, account switch and bank transfer pending. Do not equate emulator/fake-provider proof with live payment proof.

## T08 — Order status, later balances, delivered and feedback

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T06–T07; T13 fulfilment events.
- **Where:** V: BuyV2ConfirmationView, BuyV2OrdersView, order detail/balance/rating sections; S/M/C: order refresh, payment and shipment snapshots.
- **Logic/change:** Render separate order/payment/fulfilment dimensions as concise public status. One purchase may have independent Store orders and shipments. Attach invoice/help/cancel/balance actions to correct order. Preserve existing overall-purchase rating flow; do not recreate it.
- **Expected Redmi UI/UX:** Payment received · Finding a Store, Store confirmed · Preparing, and delivered statuses are truthful. Successful retail proceeds while Bulk remains unpaid. Delivered credit order still shows balance/date without blocking feedback.
- **Acceptance/evidence:** Reuse order_progress, honest_order_motion, orders_purchased_item_continuity and live_delivery_tracking tests. Redmi: partial delivery, credit balance after delivery, eligible optional overall rating, help returning to same order.

## T09 — Alternative-Store fulfilment and refund presentation

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T08; T12 allocation/refund events.
- **Where:** V/S/C: existing order status, issue/recovery contracts, actual supplier attribution and refund representation; coordinate any new event fields.
- **Logic/change:** Show replacement status without charging again. Same-product/commitment replacement follows disclosed permission; changed product/price/time requires consent. Actual supplier owns invoice/review attribution. Cancellation blocks further allocation; no-supply displays verified refund status.
- **Expected Redmi UI/UX:** Finding another Store remains on order details. Equivalent authorised replacement needs no repeated checkout. If unavailable, refund reference/status appears; other orders continue.
- **Acceptance/evidence:** Test Store-offer preservation, partial replacement, late acceptance/cancellation races and no-supply refund via provider contract fixtures. Redmi positive end-to-end closure requires T12; no fabricated supply/refund evidence.

## T10 — Compact brand-consistent sweep across the new journey

- **Lane:** Public. **Status:** specified; not implemented or newly tested.
- **Depends on:** T01–T09.
- **Where:** V and already-approved shared Buy style owners only after literal ownership check; no global app/theme rewrite.
- **Logic/change:** Remove wasted rows, half-empty cards, duplicate labels and oversized controls. Reuse existing approved visual tokens. Routine available options apply in one tap; retain accessible touch targets and necessary bank/consent steps. Remove superseded visual paths after checks.
- **Expected Redmi UI/UX:** Compact Cart and Checkout use width effectively; quiet clear selected states; no repeated Apply/Save for radio choices; no clipping or competing primary actions.
- **Acceptance/evidence:** Redmi portrait/landscape, normal/200% text, long Store names, ten Stores, many offers and ₹1 crore. Screen-by-screen founder review plus technical geometry/navigation checks.

## T11 — Authoritative direct-buy terms, totals and payment coordination

- **Lane:** Frontend contract and future-workspace handoff. **Status:** specified; frontend work pending; backend/workspace implementation deferred.
- **Depends on:** Contract mapping before T03/T05/T06 integrated closure.
- **Where:** Store WP/WE/WS/WG and Buy C adapters; backend bank/payment/commerce owners require exact admission before edits.
- **Logic/change:** Publish explicit Wholesale/Bulk applicability/customer terms. Calculate versioned prices/freight/offers/credit/limits, reservations and obligation groups. Collect via authorised MoolSocial routes; allocate receipts, preserve idempotency, reconcile partial/late transfers and supply refund inputs. Define exact deadlines rather than invent UI values.
- **Expected Redmi UI/UX:** Checkout receives valid pre-established terms and totals, no quotation route. Real supported methods and pending/paid events drive T03–T07.
- **Acceptance/evidence:** Provider permission/idempotency/money conservation tests plus real authorised test-account integration. Redmi verifies actual payment group outcomes; not closable by UI tests alone.

## T12 — Retail allocation, replacement and no-supply refunds

- **Lane:** Frontend contract and future-workspace handoff. **Status:** specified; frontend work pending; backend/workspace implementation deferred.
- **Depends on:** T11; feeds T09.
- **Where:** Store WS/WG/WV order acceptance and authoritative allocation/refund backend owner to be admitted; Buy C event mapping.
- **Logic/change:** Allocate paid retail orders; bound acceptance/replacement search. Atomic versioned acceptance/cancel/reassignment prevents double supply. Preserve exact item and agreed customer amount; fund non-transferable savings under explicit rule or refund. Original-route refund and actual-seller settlement/invoice mapping.
- **Expected Redmi UI/UX:** T09 receives truthful replacement/refund updates; customer does not re-pay or repeat address/checkout.
- **Acceptance/evidence:** Race tests, original Store late acceptance, partial supply, no supply, changed commitment consent, refund retry and actual supplier attribution. Redmi observe controlled test lifecycle without real charge unless separately authorised.

## T13 — Store acceptance to delivery-workspace completion

- **Lane:** Frontend contract and future-workspace handoff. **Status:** specified; frontend work pending; backend/workspace implementation deferred.
- **Depends on:** T11–T12; feeds T08.
- **Where:** Store WS/WG/WV assignment/handover; Buy C live-delivery/order adapters; exact delivery workspace/backend owner admission required.
- **Logic/change:** Create shipment jobs only after acceptance and required readiness/payment gates. Route to assigned MoolSocial/third-party provider with scoped access. Handle rejection/reassignment, dispatch balance gate, proof, partial delivery/collection and failed delivery.
- **Expected Redmi UI/UX:** Customer sees accurate per-shipment status; provider workspace receives only its job. No fabricated live map, premature delivery or retail waiting on unrelated Bulk.
- **Acceptance/evidence:** Cross-role authorisation and duplicate-job tests; Redmi linked to provider test workspace verifies acceptance→assignment→handover→delivery. Native Maps work remains separately gated if needed.

## T14 — Cumulative qualification, superseded-path removal and Git handoff

- **Lane:** Qualification. **Status:** specified; not implemented or newly tested.
- **Depends on:** T01–T13 frontend scope for current-phase closure; production integration closure is deferred.
- **Where:** Existing Buy regression manifest/ticket handoff and scope records under registered ownership; all changed source/test owners.
- **Logic/change:** Map every journey-document case to evidence; classify UI-only versus integrated. Remove obsolete implementation only after restored-state compatibility checks. Commit qualified changes under existing gates and verify local/remote equality. Register only actually discovered child defects.
- **Expected Redmi UI/UX:** Approved five-step journey works on Redmi without repeated choices; exceptions have working recovery. Report separate public completion and backend integration status, never a combined false green.
- **Acceptance/evidence:** Run impacted then required cumulative checks, analysis and repository gates. Hot reload proves live preview only; cold-start/native changes require authorised build qualification. No automatic new APK or real payment.

## Execution and reporting

Public execution order: T01 → T02 → T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10. T11–T13 define frontend interfaces, states and handoffs in this phase; their backend/workspace execution is deferred. They must not block frontend completion solely because future services are unavailable. T14 qualifies the frontend phase and records separate deferred production integration. Early public previews may use existing authorised review contracts, explicitly labelled; provider absence remains pending, never simulated as production success.

Before each source edit: verify pinned-source drift and owner claim, map existing assertions, implement smallest complete change, test affected behaviour, then hot-reload and inspect Redmi. Record status independently as source implemented / local checks passed / Redmi verified / founder approved / provider integration pending or verified. A single status cannot hide missing evidence.

No extra child-ticket count is invented. Register confirmed regressions against the relevant scoped package using the existing registry rules. Source drift may require revising a package; do not silently expand or duplicate an existing ticket.

## Store shutdown handoff reconciliation — 28 September 2026

Read founder-supplied `C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs/CURSOR-READ-ONLY-SHUTDOWN-HANDOFF-20260928.md`. Fresh remote readback confirms Store `9fa3f5d94ef4a17280635e4968e03b128233fdfc`, already used above. No ticket renumbering or additional execution package is needed: total remains 14.

The handoff reports 53 commits pushed, clean application worktree, 26 of 27 original findings corrected, Restock deferred, 31 focused checks passed and clean analysis. These are Store-lane reported results, not new Cursor verification or closure of all findings. The earlier narrow source comparison in this plan was from `eea11308`, not from the previous remote `a4583427`; it must not be interpreted as covering all 53 commits.

| Affected ticket | Amendment / execution constraint |
|---|---|
| T02, T03, T10 | Preserve approved Store layout conventions and shared keyboard/focus behaviour. Test editor open, keyboard visible, explicit dismissal, Back and enlarged landscape. Store reports explicit keyboard-dismiss recovery; floating-keyboard occlusion is not resolved merely by that check. Do not copy Store UI wholesale into Buy or overwrite its approved components. |
| T01, T11 | Preserve existing catalogue/inventory identity owners. Restock is deferred to separately authorised integration; these Cart tickets do not authorise a parallel Restock implementation. If readiness depends on it, record the exact dependency rather than inventing availability. |
| T07, T11, T14 | Physical failed-write, unavailable-provider and in-progress-save checks remain unverified in Store handoff. Add these as required linked recovery evidence where the integrated Buy journey depends on those operations; do not inherit a green status. |
| T09, T12 | Store mixed-refund evaluation is not proof of MoolSocial customer-payment refund, replacement allocation or settlement integration. Retain the need for exact line/payment/refund IDs and authoritative confirmation. Do not close T12 from a Store refund screen demonstration. |
| T11–T13 | Existing evaluation data are not production commerce; backend reuse is unproven. Read and reconcile existing owners before proposing changes. No integration, cherry-pick, worktree synchronisation, backend mutation or deployment authority is granted by this handoff. |
| T14 | Separate source push from device/test evidence. Store evidence lives outside application Git and was not uploaded by that source push. Preserve original findings and unresolved acceptance. Hot reload does not update the installed APK; restoration/cold-start evidence must identify the exact source and binary. |

Store source and its external evidence were not modified. Only these founder-requested local planning documents were amended. Referenced detailed Store evidence reports have not been freshly inspected in this reconciliation; review the relevant named report before accepting a dependent ticket's device evidence. The handoff's reported results must not be promoted to independently verified results.

## Founder scope amendment — frontend now; workspace/backend mapping later

This amendment governs the execution scope above wherever earlier wording implies backend delivery is required to finish the current frontend phase. Total remains **14 packages**; no duplicate tickets are added.

1. **Payment:** founder confirms the Supermandi payment provider is ready. Record readiness as founder-confirmed, not independently reverified here. Do not create a new payment provider or redo its backend. Prepare the MoolSocial frontend payment experience and adapter mapping against the existing provider contract. Exact API access, supported methods, limits and response shapes must be read from that contract when available; readiness is not permission to invent them or assume every proposed method is supported.
2. **Store workspaces:** under development. Finalise the public journey and required input/output contracts here; hand them off for Store mapping. Preserve current Store implementation and flag discrepancies for its owner, without changing another worktree.
3. **Backend:** implementation, deployment and production integration are deferred. All earlier T11–T13 backend logic remains future acceptance requirements, not current execution assignments.
4. **Delivery workspaces:** MoolSocial delivery and Wholesale/Bulk delivery-partner workspaces are not yet developed. Prepare public delivery states and the required shipment/assignment/handover/completion contract; future workspaces map to it. Do not assume existing Store assignment helpers prove those workspaces exist.

| Ticket | Current executable frontend scope | Deferred implementation |
|---|---|---|
| T11 | Define/map checkout totals, terms, payment capability, initiation, reconciliation and balance interfaces. Prepare the existing-provider frontend adapter and readable pending/success/failure/recovery UI. Reuse a callable existing provider only within authorised access; no new backend. Document unavailable contract details explicitly. | Any missing server coordination, money allocation, reservations, settlement and backend integration. |
| T12 | Finalise public replacement/refund states, actual-supplier attribution, customer-consent exceptions and required event/identity fields. Prepare adapter boundaries and test the frontend's handling of each supplied outcome. | Alternative-Store search/allocation, acceptance races, refund execution and supplier settlement. |
| T13 | Finalise public delivery/collection tracking, readiness/balance gating displays, partial completion and failure recovery. Specify the exact data/events future MoolSocial and Wholesale/Bulk delivery workspaces must supply. | Delivery workspace construction, assignment operations, access enforcement, proof verification and backend tracking. |
| T14 | Qualify implemented frontend behaviour locally and through Redmi hot reload, preserve evidence, record founder review and follow Git gates. Report frontend completion independently. | Live end-to-end money movement, workspace integration and production delivery/refund qualification. |

T01–T10 consume these contracts and must handle loading, unavailable, pending, failed and successful responses accurately. Finalising a frontend contract establishes the requested mapping, not evidence that its future server operation works. If existing payment-provider behaviour differs, reconcile the interface explicitly rather than replacing the ready provider.

Testing: local controlled responses may exercise contract/error handling. Any device review scenario must use authorised, clearly identified review data; never display test outcomes as real payment, refund or delivery completion. No real payment is authorised by this document. Missing live services are labelled **backend/workspace integration deferred**, not **frontend implementation blocked**, unless a specific missing contract genuinely prevents an exact implementation; identify that field or operation precisely.

Updated reporting: **frontend implemented / local tests / Redmi verified / founder approved / future integration deferred**. Frontend tickets can close against their frontend acceptance scope with the deferred mapping clearly retained; they must not be reported as production end-to-end complete.

</details>
