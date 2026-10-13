# Redmi Buy audit: parameters, journeys and defect tickets

Audit phase completed for the identified executable queue. The founder's later
22 September instruction authorizes post-audit implementation and local testing.
Current work is tracked in [post-Redmi fixes](CURSOR-BUY-POST-REDMI-FIXES-20260922.md).
The defects-only restrictions below describe this retained audit phase.

Scope: physical Redmi only, entire reachable public Buy module. Founder explicitly
requests testing and defect registration only. No runtime fixes, builds, policy,
governance, other-module audit, real payment, or messages. Launch-supporting audit.
Reuse installed com.moolsocial.app.cursorreview and actual controls. Each journey
continues to its intended visible result or records its exact blocker. A tap alone
is not a pass. Existing local repairs do not prove this installed APK is repaired.

## Testing parameters

Continuation rule (latest founder request): expand into a new journey, user tap
or previously uncovered parameter/state combination each time. Do not repeat
the same journey/parameter as routine regression. Keep testing and registering
only; implementation remains excluded. Existing failures are extended by new
evidence rather than duplicated.

| ID | Check on each applicable screen |
|---|---|
| P01 | Correct entry, visible destination, title and store/product identity |
| P02 | One-tap action, correct final intent screen, Back and retained state |
| P03 | Android status/navigation clearance, sheet footer and final scrolled content |
| P04 | Keyboard focus, visible query, no covered results/actions, submit and Back dismissal |
| P05 | Search relevance, partial/exact/no-match input, clear and recovery |
| P06 | Store-scoped SKU/search/category/filter/Saved; no home or other-store leakage |
| P07 | Filters and categories apply/reset, selection truth, count and empty result recovery |
| P08 | SKU identity, variants, units, pack size, price/unit price, seller and stock truth |
| P09 | Product images: identity, loading/fallback, crop/fit/aspect ratio, resolution and alignment |
| P10 | Metadata completeness, hierarchy, readable labels and consistent values across journey |
| P11 | Text size, weight, line height, wrapping, truncation, compactness and long names |
| P12 | Brand colors, gradients, contrast, backgrounds, icons and consistent surfaces |
| P13 | Professional visual hierarchy, spacing, alignment, density and product prominence |
| P14 | Scroll reachability, sticky chrome, overlays, bottom CTA, hit targets and accidental taps |
| P15 | Motion continuity, distracting/obscuring animation, loading and settled state |
| P16 | Save/unsave, quantity/add/remove, cart totals and state after navigation |
| P17 | Delivery/collect choice, address validation, review and truthful checkout boundary |
| P18 | Order list/detail, active-delivery visibility, tracking/support entry and terminal state |
| P19 | Errors, unavailable actions, retry, empty states and customer-facing language |
| P20 | Background/resume and keyboard/system Back preserve the current Buy intent |
| P21 | Screen reader semantics from device hierarchy: labels, clickable bounds, zero-size controls |
| P22 | Offers/Wholesale/store navigation reaches the exact advertised product/store |

## Coverage and evidence rules

Record each screen/journey as PASS, DEFECT, BLOCKED or NOT TESTED with capture IDs.
Visual checks require PNG inspection; XML alone cannot establish visual quality.
Device screenshots/XML live under outputs/cursor-buy-redmi-audit-20260922/.
Do not call untested font/device/network variants passed. No fixture success may
be represented as a real production order. Stop before external side effects.

## Device identity

Redmi serial TG8HCYTGGQT885OF, 720x1600. Installed package
com.moolsocial.app.cursorreview, version 1.0.0-r66.31-cursorreview,
code 2026092101. Audit begins with existing user cart (5 items, Rs750), saved
product and store category retained. No data clearing. Source HEAD at start
87bc96d4; this source is newer than installed APK. Screens are installed-build
observations only. No build or installation performed.

## Journey results

Current audit results below. Capture filenames begin with the following IDs;
each has PNG/XML. Prior tested journeys are reused as described below rather
than repeated. This is not a claim of exhaustive current-build acceptance.

| Journey | Result | Evidence / final visible outcome |
|---|---|---|
| Store details from search info | DEFECT | 001: popup opens but store body/Ask lies behind Android navigation |
| Store filter | DEFECT | 006: Show products CTA clipped; XML reports zero bounds |
| Store category selection | PASS navigation; visual defect | 007-008: All products replaces grain selection, 5000 catalogue records |
| Store search rice | DEFECT relevance | 009-010: rice and price labels returned together, still Mool Market 1 |
| No-match and clear recovery | PASS | 012-013: explicit no-match, clear restores catalogue; keyboard Back returns |
| Store Saved | PASS observed scope | 014: only saved atta at this store, one product |
| Saved SKU to detail | PASS identity; visual defect | 015-017: atta Rs279/5kg/Rs55.80 per kg, correct store and metadata retained |
| Product Compare and Retry | BLOCKED data | 018-019: supplier prices unavailable before/after Refresh; final comparison cannot be qualified |
| Review eligibility | PASS unavailable state | 020: delivered purchase required; no review submitted |
| Report issue | PASS entry | 021: correct product, reasons and disabled Send before selection; not sent |
| Ask seller / Back | PASS route; naming defect | 022-023: product conversation opens, auto-draft only, Back restores detail; no message sent |
| Share | PASS destination entry | 024: Android share chooser with product title; cancelled without recipient |
| Cart and quantity keyboard | PASS behavior; copy defect | 025-032: zero rejected, cancel preserves cart, +1 makes Rs787, -1 restores Rs750 |
| Delivery / Collect selection | PASS choice; BLOCKED completion | 033-037: collection sign-in requirement, payment Review disabled, return restores delivery |
| Add address / validation / keyboard | PASS tested states | 038-042: empty input rejected, PIN keyboard, footer reachable by scroll, cancel saves nothing |
| Delivery payment / review | PASS navigation; BLOCKED quote | 043-046: payment then Confirm order reached; standard delivery unavailable, Check delivery did not resolve it in immediate readback |
| Shop filter and mode | PASS sampled behavior; visual defects | 049-053: Up to Rs100 applies to visible products; Scheduled switches catalogue |
| Shopping area | PASS selection; visual defect | 054-055: Jodhpur selection narrows results; list/copy remains oversized |
| Wholesale / Bulk / product | PASS navigation/values | 056-058: Bulk rice detail Rs1690, 25kg, minimum 4, total Rs6760 |
| Supplier preview / full catalogue | PASS navigation; visual defect | 059-060: correct supplier, preview to 5000-product catalogue |
| Wholesale cart / coupons / payment offers | PASS entry | 061-063: Rs1160 for two packs; empty coupons and three payment offers; no offer redeemed |
| Wholesale checkout | PASS to review; delivery blocked | 064-066: receiving address, payment and confirmation visible, delivery still requires check |
| GST form | PASS validation and Back; visual defect | 067-070: empty name rejected, keyboard/footer visible, cancelled without saving; GST toggle restored off |
| Supplier offer to product | PASS navigation; theme defect | 071-072: tomato Rs37/500g opens exact product, Back returns Offers |
| Offer publishers | DEFECT bottom option | 073-074: MoolSocial row has zero bounds and stays hidden after swipe; Manufacturers selection works in 075 |
| MoolSocial offer tab | PASS empty state | 076: clear no-matching-offers state, not an invented offer |
| Orders / tracking / Items / Back | PASS observed navigation | 077-081: MS-NEW-09, two tomatoes, Rs74, recorded packing state, live updates explicitly unavailable |
| Invoice / Download | PASS to Android save intent | 082-084: two units at Rs37 = Rs74, invoice PDF filename opens system save picker; cancelled without saving |
| Manage order / Support / Back | PASS destination entry | 085-088: invoice cancellation returns to tracking; Manage order opens, Support reaches the named order conversation and Back restores tracking. No cancellation or message submitted |

## Prior coverage reused: no repeated full sweep

Latest founder clarification: reuse applies only where the evidence covers the
same parameter and screen state. A navigation pass does not cover new typography,
image, keyboard, inset, motion or store-scope checks. Supplemental parameter audit
starts at capture 089. Coverage below supersedes the blanket skip examples where
new parameter evidence is missing. Supplemental execution is recorded below;
no full-pass claim.

Founder explicitly requested avoiding previously tested journeys. The local
[Cursor journey register](cursor-redmi-v6-audit-20260913/JOURNEYS.csv) contains
628 action-level records, not 628 distinct end-to-end journeys:

| Recorded disposition | Count |
|---|---:|
| device_pass | 514 |
| device_failure / device_fail | 24 / 1 |
| blocked_authentication / blocked_provider / blocked_test_data | 9 / 27 / 22 |
| device_observation / data_observation | 20 / 4 |
| excluded_authorization / scope_boundary_observed | 1 / 1 |
| source_gap / source_unreachable | 1 / 4 |

This historical register is reused for coverage, not relabelled as fresh r66.31
acceptance. It includes records across earlier sessions/builds; the linked
[18 September device record](cursor-redmi-v6-audit-20260913/REDMI-20260918.md)
identifies r66.29. Historical failures remain recorded; this audit neither
closes them nor creates duplicate implementation tickets for them. Shared Chat
or account coverage in that register does not expand this Buy-only audit.

The [21 September Buy record](CURSOR-BUY-READY-20260921.md) also records tests
on the same installed r66.31 candidate: Visit store, Saved, category/product
return, price/sort Apply and Reset, Delivery/Collect selection and return,
cart preservation, and background/foreground restoration. Its existing
REG4642/REG4643 failures are linked by RB-002/RB-003 above, not treated as passes.
Evidence is retained at
`C:\GUARANTEED OUTCOME\outputs\cursor-buy-ready-20260921\redmi-r66-31-uat`.

Examples deliberately not repeated after this reconciliation:

| Existing coverage | Register IDs / source | Treatment |
|---|---|---|
| Store pagination, category final page, return and search submit | STORE-ROUND85, STORE-ROUND87, STORE-ROUND144, STORE-ROUND145, STORE-ROUND157 | Reuse historical navigation coverage; current store visual/search defects remain above |
| Category query/clear, search replay and Wholesale category switching | CATEGORY-ROUND106, SEARCH-ROUND152, WHOLESALE-ROUND160 | Reuse recorded passes; do not repeat discovery loops |
| Filter toggles, GST keyboard progression, address types and selector return | FILTER-ROUND93, GST-ROUND95, ADDR-ROUND139, ADDR-ROUND141 | Reuse historical action coverage alongside current sampled keyboard tests |
| Order items, Help, tracking return and visibility controls | ORDER-ROUND168, TRACKING-ROUND169 | Reuse recorded navigation passes; empty active-delivery state remains untested |
| Enlarged-text tracking and cancellation form dismissal | ACCESS-ROUND81, RESOLUTION-ROUND82, RESOLUTION-ROUND83 | Historical only; no new large-font acceptance claimed |
| Cart and app resume on r66.31 | 21 September record, captures 18-25 | Same-candidate coverage reused; current cart quantity separately restored |

Only changed screens, newly exposed defects, or genuinely uncovered Buy intents
need further device execution. Prior blocked and failed results are not skipped
as if passed; their existing records remain the source for follow-up.

## Audit outcome and limits

- 22 testing parameters documented; 31 audit-local defect records, including
  reproduced existing defects and local repairs absent from this APK.
- 327 PNG/XML capture pairs plus 12 timestamped motion PNGs retained in
  `C:\GUARANTEED OUTCOME\outputs\cursor-buy-redmi-audit-20260922`;
  capture-quality exclusions below still apply.
- No implementation, build, installation, policy changes, real order/payment,
  sent message, cancellation, review submission or saved invoice in this audit.
- Authenticated collection completion, authoritative delivery quote/order
  completion and supplier comparison remain blocked. No-active-order rail
  visibility and every catalogue item/store are not newly qualified. Store motion
  was sampled over 16 seconds and store text was checked at 130%; these do not
  qualify smooth frame-rate motion, all text scales or rotation on every screen.
- Installed r66.31 predates source HEAD 87bc96d4. These observations cannot prove
  that later local repairs work on Redmi or qualify the current source release.
- Original cart quantities and GST toggle were restored. Browsing filters/mode/
  area changed during testing; opening seller/support conversations generated
  unsent drafts. No app data was cleared.

## Defect tickets

Ticket IDs are audit-local; no implementation is authorized by registration.

| Ticket | Severity | Parameters | Reproduction / actual vs expected | Evidence | State |
|---|---|---|---|---|---|
| RB-001 | High | P03,P14,P21 | Search info opens Store details; store content/Ask obscured by Android bottom navigation. Must scroll/reach all information and actions above system area. | 001 | Reproduced installed; local repair 87bc96d4 not installed |
| RB-002 | High | P03,P07,P14 | Store filter Show products hidden at bottom; cannot complete apply naturally. | 006 | Existing REG4642 reproduced; local repair not installed |
| RB-003 | Medium | P05,P06 | All store categories, search rice: unrelated self-adhesive price labels match. Results must match product terms. | 009-010 | Existing REG4643 reproduced; local repair not installed |
| RB-004 | Medium | P11,P13 | Store category/filter headings, option text and generous spacing consume much of the sheet; user-required compact treatment absent. | 006-007 | Existing compactness issue reproduced on old APK |
| RB-005 | Medium | P09,P10 | Atta main detail image shows generic mixed grain bags; related atta card uses a different wheat pack image. Illustration disclosure exists, but identity/visual consistency is poor. | 015,017 | Open visual ticket; do not claim genuine supplier photo missing is a code failure |
| RB-006 | Low | P01,P10,P11 | Product Back label says Mool Market 000001 while seller and store say Mool Market 1. Same store should use consistent customer naming. | 015 | Open |
| RB-007 | Medium | P12,P13 | Search remains boxed on installed store screen despite requested Buy Home unboxed appearance. | 001,010 | Local repair 9c8ac6ba not installed |
| RB-008 | Medium | P01,P10,P19 | Ask seller changes atta display name to Stone-ground wheat atta 2 and exposes padded store name; auto-draft includes internal SKU identifier/blank Brand. Wholesale bookmark toast similarly says Fresh tomatoes 1 saved although the card says Fresh tomatoes. Clean customer identity must survive actions/handoff. | 022,190 | Open Buy identity/handoff ticket; Chat internals not audited |
| RB-009 | Medium | P10,P16 | Selected Shop cart shows header/footer Rs750 but top Subtotal Rs1910 without explaining all-cart vs selected-cart scope. Labels must make totals unambiguous; no arithmetic failure claimed. | 025,031-032 | Open copy/clarity ticket |
| RB-010 | Low | P10,P11 | Quantity editor says 500 g pack per pack. Remove redundant unit wording. | 026 | Open |
| RB-011 | High | P02,P17,P19 | Collection shows Sign in to place a store collection order, but no sign-in CTA; Continue still opens payment with disabled Review and Check total. Must provide a recoverable customer path. | 034-035 | Open installed journey blocker; no authentication bypass |
| RB-012 | High | P02,P17,P19 | Delivery confirmation has unavailable standard delivery; Check delivery still leaves same unavailable state on settled recheck. Final placement cannot be qualified. Need actionable availability/recovery, not a repeated dead end. | 044-047 | Blocked installed environment; cause not diagnosed in this testing-only task |
| RB-013 | Medium | P11,P13 | Shop filter/area, GST retention toggle and wholesale supplier preview use oversized text/large gaps; supplier collection banner dominates first viewport. Delivery selector and Shopping help headings/FAQ spacing extend the same compactness issue. Compact professional hierarchy required. | 050,054,059,068,185-186,198-200; supplemental instances below | Open visual ticket; overlaps existing compactness request, not new scope |
| RB-014 | Low | P10,P19 | Wholesale coupons empty state calls purchase Trade order although navigation says Wholesale. Use consistent consumer terminology. | 062 | Open |
| RB-015 | Medium | P09,P13,P14 | Floating cart covers product image/content in grid and Wholesale product media; users must move it to inspect underneath. Keep product content legible and actionable. | 052,056,058 | Open visual/occlusion ticket |
| RB-016 | Medium | P12,P13 | Offers promo uses dark brown/plum and pale pink, visibly mismatching Buy navy/light brand surfaces. | 071 | Existing REG4635 reproduced; local palette repair not installed |
| RB-017 | High | P03,P07,P14,P21 | Offers > Filter: final MoolSocial publisher row is hidden behind Android bottom area; swipe does not expose it, XML zero bounds. All choices must be reachable. | 073-074 | Open |
| RB-018 | Medium | P11,P13 | Payment-offer cards leave large blank vertical areas around small Select buttons; compact card hierarchy would expose more relevant choices. | 063 | Open visual ticket |
| RB-019 | Medium | P09,P10,P13 | Recently viewed shows missing-image icons for tomato/atta although the opened atta detail renders its illustration. Reuse the product's available media or an intentional consistent fallback in history. | 100-102 | New installed visual defect; underlying cause not diagnosed |
| RB-020 | Medium | P07,P12 | Store filter selected Any price/Relevance chips show dark grey ticks on navy, making selection marks hard to distinguish. Give selected marks clear contrast against the selected surface. | 106; also visible in 006 | New contrast defect; reproduced at 130% font |
| RB-021 | Medium | P11-P13 | Shop/Wholesale category sheets show underlying SKU names/prices through a nearly white surface, plus two drag handles. Still present after settled recheck with keyboard. Remove the distracting ghost content and duplicated handle treatment. | 117-119,132-133 | New installed visual defect |
| RB-022 | Low | P04,P21 | Request an address has a visible Recipient name label, but its empty focused EditText exposes no text/content description or label in the dumped hierarchy; duplicate EditText nodes have the same bounds. Verify and repair the field's accessible name/focus structure. | 127-128 XML and PNG | New semantics finding; TalkBack speech/focus behavior not independently certified |
| RB-023 | Medium | P07,P10,P19,P22 | Offers > MoolSocial says No current offers from this publisher while showing retail/wholesale product cards below, without distinguishing a recommendation section. Empty publisher result and general catalogue content are ambiguous. | 135; reproduced after query clear in 140-141 | New installed clarity defect; no claim that the products themselves are unavailable |
| RB-024 | High | P01,P05,P22 | Shop search advertises Stores or products. Exact visible store name Mool Market 1 returns No matching products, including after the actual keyboard Search action. The same store is accessible through product Visit store. | 142,144,146,155 | New installed store-discovery failure; provider/index cause not diagnosed |
| RB-025 | Medium | P02,P13,P14,P21 | Store first-page footer has no visible page count, Next control or swipe cue. Horizontal swipe nevertheless changes the semantic range from 1-40 to 41-80 of 5000. Customers reaching the vertical end cannot discover remaining inventory from the visible UI. Expose an understandable continuation cue. | 157-159 | New discoverability defect; pagination itself works |
| RB-026 | Medium | P10,P18,P19 | Delivery list, selected overlay and tracking for MS-NEW-03 simultaneously say Preparing your order, 40%, and Delivered in 30 min. Correct estimated-delivery wording so it cannot imply completion before dispatch. | 186-188 | New installed contradictory-status copy; no backend diagnosis |
| RB-027 | Medium | P02,P05,P07,P16 | Wholesale Saved silently clears the active tomato query, unlike store Saved which preserves it. In Saved, selecting Bulk still shows the same tomato item excluded from Bulk search, while the banner says Saved for Wholesale. Clarify/apply the controls' scope and preserve or explicitly communicate search resets. | 163-164 versus 180-182,190-192 | New saved-state/selection consistency defect; temporary bookmark removed in 193 |
| RB-028 | Low | P05,P07,P19 | Store atta search under the applied Rs100 cap says Try another search or category, omitting the active price filter and a relevant reset action. Resetting only filters restores 60 atta results with the query unchanged. Explain the limiting filter in the empty state so users can recover without changing a valid search. | 232-234 | New empty-state recovery copy/action defect; filtering itself works |
| RB-029 | Medium | P01,P08,P10,P13 | Store search presents many indistinguishable atta cards with the same name, 5kg pack, Rs279 price, image and Mool Market 1 seller; only one is Saved. Opening a second card still provides the same visible identity. Sorted results similarly repeat cumin/dishwash cards across pages. Customers cannot distinguish these separate selectable listings. | 205,230-231,234-235 | Installed review-catalogue identity defect; no assertion of duplicated production database rows |
| RB-030 | High | P01,P06,P10,P22 | From Mool Market 1 milk product, You may also like contains a milk card with no seller shown. Tapping it opens Family Dairy & Bake's milk product and its variants. This violates the founder's store-specific-only content requirement and switches seller without disclosure on the recommendation. | 236-241 | New public-store related-product scope leakage; implementation/contract diagnosis excluded |
| RB-031 | Medium | P08,P10,P18 | MS-NEW-09 Items shows an order summary of 2 items/Rs74, but its tomato row only says 500g pack/Rs37 and omits purchased quantity 2 and line amount Rs74. Display the order-line quantity and amount rather than requiring inference from an aggregate header. | 282,290; order-list quantity in 279 | New historical-item metadata omission; no changed-price or backend snapshot corruption claimed |

## Supplemental parameter results (latest request)

| Screen / state | Parameters specifically checked | Result / evidence |
|---|---|---|
| Delivered order cards and Wholesale terminal tracking | P01,P03,P08,P10-P14,P18,P21 | 090-093: identifiers, amount Rs8460, delivered status, long supplier wrapping, brand surfaces and scroll-to-actions inspected. Actions accessible; oversized hierarchy extends RB-013 |
| Return/refund choice and eligibility form | P02,P03,P10-P14,P18,P19,P21 | 094-096: eligibility unavailable; no submission. Footer initially below fold becomes fully reachable after scroll, so zero initial XML bounds alone is not registered as a defect. Large cards/text extend RB-013 |
| Shop tools and Recently viewed | P03,P09-P14,P21 | 098-101: tooling scroll works; recent items have missing thumbnails (RB-019), oversized rows extend RB-013 |
| Recent item to detail and Visit store | P01,P02,P06,P08-P10,P22 | 102-103: correct atta Rs279/5kg/store; product illustration available; store catalogue belongs to Mool Market 1 |
| Store-name motion | P15 | 104: 12 timestamped raw frames across 16.156 seconds; five distinct header images recurring throughout, with no user input. Motion continues beyond entry rather than stopping permanently. Sampling does not certify frame-rate smoothness. Animation settings all 1.0 |
| Store catalogue at font scale 1.3 | P03,P08-P14,P21 | 105: reflows to two columns, short store name and prices readable; images fit their frames. Existing generic image identity issue remains RB-005 |
| Store filters at font scale 1.3 | P03,P07,P11-P14,P21 | 106: Show products still hidden (RB-002), oversized layout (RB-004), dark selected ticks (RB-020) |
| Store milk query, IME, SKU and metadata at font 1.3 | P01-P06,P08-P14,P21 | 107-109: milk results, name/pack/price and store agree; query above keyboard, long return copy wraps, metadata scrolls. Milk illustration is generic category imagery; extends RB-005 |
| Store result Back and nested store close | P02,P06,P20 | 110-111: milk query/results retained after product Back; clear and Close return to original atta detail. Font restored to original 1.0 and read back |
| Monthly basket summary and products | P01-P03,P08-P14,P16,P21 | 115-116: 12 products/21 packs/Rs5145 summary, six Scheduled products exposed by View basket products; no basket added. Existing cart remains Rs750. Large spacing extends RB-013; floating cart extends RB-015 |
| Shop category query and settled sheet | P03-P05,P07,P11-P14,P21 | 117-119: dairy gives Dairy & bakery above keyboard; ghost content and two handles RB-021. Closed without category change |
| Buy settings, alerts, Saved, payment preference and address selector | P01-P03,P08,P10-P14,P17-P19,P21 | 122-127: named settings reached; alert rows, saved atta Rs279, selected Paytm and Work address readable. Existing preference state retained. Large typography/card spacing extends RB-013; no account/privacy/security internals entered |
| Address request with keyboard and close | P02-P04,P10-P14,P21 | 127-129: all three actions above keyboard; Close removes keyboard and returns to address selector. Nothing shared/copied/submitted. Missing exposed field name RB-022 |
| Wholesale category, empty query and filter | P03-P05,P07,P11-P14,P19,P21 | 131-134: current Bulk state retained; zzzz gives explicit empty category result and reachable Clear search; closing preserves category. Same transparent sheet defect RB-021; filter spacing extends RB-013 |
| Offers categories through final option | P02,P03,P07,P11-P14,P21 | 136-138: final Stationery & office fully reachable after scroll. Large single-column typography extends RB-013; no bottom-overlap failure at final option |
| Offers query/clear/finish | P02-P05,P07,P11-P14,P19,P21 | 139-141: actual entered query zzz shows no matching offers above keyboard; clear restores cards and Finish dismisses keyboard. Restored MoolSocial state exposes RB-023 |
| Shop search entry, exact store query and recovery | P01-P05,P10-P14,P19,P21,P22 | 142-148: history and empty result readable; known store lookup fails RB-024. Clear restores history, Finish returns Shop. Failed query now appears in history; prior history was not cleared |
| Orders exact query with IME, tracking and Back | P01-P05,P08,P10-P14,P18,P20,P21 | 149-152: MS-NEW-09 returns matching Rs74/two-item purchase. Track accessible above keyboard opens recorded tracking; Back preserves query. No order changed |
| Store lower-page cards and horizontal continuation | P02,P03,P06,P08-P14,P21 | 155-159: lower cards remain Mool Market 1; pack/unit prices visible; horizontal swipe advances range then reverse restores first page and its scroll. No visible paging cue RB-025. Cat-food illustration appears to show litter and a scoop, extending RB-005's product-image identity issue |

### Existing defects extended by the new parameters

- RB-002/RB-004: 130% text confirms the hidden store-filter footer and excessive
  spacing; do not create a duplicate ticket for another font scale.
- RB-005: generic milk/category images (107-109), and cat-food illustration that
  visually resembles litter/scoop (157), broaden the product-image identity review.
  Illustration disclosure is present; this is not a fabricated photo-loading error.
- RB-013: add delivered-order actions/return cards (091-096), history (100-101),
  monthly basket (115-116), Buy settings/address forms (122-128), Wholesale filters
  (134), Offers categories (136-138) and Shop search history (142). Apply the
  already requested compactness objective consistently; no implementation here.
- RB-015: monthly catalogue floating-cart obstruction also appears in 116.

### All-parameter evidence reconciliation

Every latest parameter has a concrete test or an explicit remaining limit below.
"Checked" means the recorded screens/states were examined, not every possible
product, store, provider response or device configuration. Historical navigation
passes alone are not used as visual or keyboard acceptance.

| Parameter | Current device evidence / disposition | Remaining limit |
|---|---|---|
| P01 | Checked 015,022,058,072,092,102,108,150; naming/search defects RB-006/008/024 | Authoritative production identity not qualified by review data |
| P02 | Checked 020-024,033-046,080-088,094-096,110-112,129,146-152,158-159 | Auth/payment/eligibility prevent certain final outcomes |
| P03 | Checked modal, footer, keyboard and scroll captures 001,006,038-041,073-074,094-096,106,118,126-129,138 | No-active-delivery state unavailable; other device sizes not claimed |
| P04 | Checked numeric cart/address/GST and store/category/offer/order IME: 026-029,038-041,068-069,107,118,128,133,139,150 | Actual keyboard Search proof is 146; 145 is excluded for submit acceptance |
| P05 | Checked rice/milk/unmatched/clear and exact order/store terms: 009-013,107,118,133,139-150 | RB-003/024; not an exhaustive query corpus |
| P06 | Checked Mool Market 1 Saved/category/search/product return/lower-page SKU consistency: 008-017,103,107-111,155-159 | No claim across every store or authenticated inventory source |
| P07 | Checked original price/category/filter controls plus selected semantics, new category/offer states: 006-008,049-055,073-076,106,117-119,132-141 | Hidden store/footer and publisher option fail RB-002/017; contrasting selection RB-020 |
| P08 | Checked Shop and Wholesale price/unit/MOQ, cart amounts and order items: 015-017,025-032,058,061,080-083,108-109,150,157 | Production stock and every variant not qualified |
| P09 | Visually checked grid/detail/history/lower-page images: 015-017,052,058,100-109,116,132,157-158 | RB-005/015/019; no proof of genuine supplier-photo availability |
| P10 | Checked metadata/copy across product, cart, checkout, orders, settings and history | RB-006/008/009/010/014/023; external values not invented |
| P11 | Checked normal text across captured Buy screen families and 130% store states 105-109 | RB-004/013/018/021; not every font scale/long-name fixture |
| P12 | Visually checked brand surfaces/gradients/icons and selected contrast throughout; 071,106,119,132,135 specifically | RB-016/020/021; no formal full-app contrast certification |
| P13 | Checked hierarchy, spacing, density and product prominence throughout captures | Existing compactness/occlusion tickets and RB-019/021/025 remain open |
| P14 | Checked scrolling/final actions/hit bounds, lower cards and keyboard clearance: 026,041,096,106,128,138,150,157-159 | Hidden controls fail; no every-coordinate touch certification |
| P15 | 104: 12 motion samples spanning 16.156 seconds with recurring changes; settled/loading frames reviewed | No frame-rate or transition smoothness claim; order/collect banner removed by latest design, not required to animate |
| P16 | 025-032 quantity validation/restoration; 014/124 Saved identity; 115-116 monthly view preserves cart | No destructive history/Saved clearing; existing save/unsave navigation reused |
| P17 | 033-047 and 064-070 to payment/review; 125-129 preference/address entry | Authenticated collection and authoritative delivery completion blocked RB-011/012 |
| P18 | Active/delivered order, tracking, items, invoice, manage/support, return eligibility: 077-096,149-152 | No new real order, cancellation/refund/payment; return eligibility unavailable |
| P19 | Explicit empty/error/retry states: 012,018-021,034-047,062,069,076,095-096,133,139,144-146 | Provider/auth failures remain blocked rather than passed |
| P20 | Current Back/query/font-change state restoration 110-112,129-130,151-152,159; same-r66.31 background/resume evidence reused from 21 September | No forced process death/data clearing; no new cold-start timing claim |
| P21 | XML labels, selected flags and bounds reviewed alongside PNGs; 106 selected=true confirmed, 128 empty duplicate EditText finding RB-022 | Hierarchy inspection only; actual TalkBack speech/traversal not certified |
| P22 | Offer→tomato 071-072, supplier/full-store 059-060, recent→atta→Visit store 102-103, exact-store discovery 144-146 | RB-023/024; more-stores continuation remains unverified as described below |

More-stores requirement: no related-store cards/entry appeared in the tested
public store first-page header/footer. Horizontal paging correctly loads the
next product page (158); it does not expose a more-stores destination. This is
bounded evidence, not proof that all 125 product pages lack such a section. Keep
the earlier more-stores ticket open; do not claim its wiring accepted.

Supplemental audit end: no runtime fixes or release actions. Font scale restored
to 1.0; all three Android animation scales remain 1.0. Cart still Shop Rs750/five
items and Wholesale Rs1160/two packs; no quantity edits in this supplemental run.
Monthly basket dismissed, category selections preserved, test store query cleared,
first store page restored. Order query MS-NEW-09 remains retained and browsing has
updated recent history. Device remains on the public store first-page lower area.

Supplemental totals: 70 additional PNG/XML pairs and 12 motion samples; seven
new records RB-019 through RB-025, plus added evidence on existing tickets.
All 22 parameters have explicit evidence/limits in the reconciliation table.
SHA-256 evidence index:
`C:\GUARANTEED OUTCOME\outputs\cursor-buy-redmi-audit-20260922\supplemental-parameter-evidence-index.json`.

Capture notes: 139 actually contains zzz, not four z characters; only the observed
query is claimed. 140 proves query clear, while settled Finish-search completion
is 141. Hardware Enter in 145 inserted a newline; removed it and used the actual
IME Search button in 146. No failed automation attempt is counted as a pass.

Delivery visibility caveat: 12 active orders already exist on this device.
Presence of Delivery here is correct and does not reproduce the no-active-order
case. No order data was erased or completed to force that state. REG4634's empty
state remains NOT TESTED in this physical audit.

Capture-quality note: 048 PNG caught the preceding confirmation frame although
its later XML showed Shop home. It is not Shop visual evidence; 052 is the settled
Shop visual. From 050 onward PNG is captured after UIAutomator's settled dump.

Execution note: capture 002 PNG/XML succeeded but console label rendering hit a
Windows Unicode encoding error. Preserved both files; capture helper now emits
ASCII-escaped console labels. 004 is not a filter-open proof: rapid input had not
settled, so the independently verified filter evidence is 006. No app changes.

## Expansion: new action and parameter combinations, captures 160-204

This batch applies the founder's no-repeat instruction. Prior JOURNEYS.csv
functional results remain reused. Setup, routing, cleanup and a second capture
to settle a screen are evidence, not additional successful test cases. The
following eleven combinations add current-device coverage rather than repeat
the earlier basic entry/tap checks. No runtime implementation occurred.

| ID | New combination and parameters | Observed result and evidence |
|---|---|---|
| EX-01 | Store query plus Saved while keyboard is open; P04-P06,P16 | PASS: atta query remains; Saved narrows 60 matching products to the saved atta, dismisses keyboard and keeps Mool Market 1 scope. 162-164 |
| EX-02 | Saved plus query plus a disjoint store category; P06-P07,P19 | PASS: selecting Dairy & bakery with Saved and atta gives explicit No matching saved products; all three selections remain meaningful. 165-166 |
| EX-03 | Clear only query, then disable Saved in that empty intersection; P05-P07,P16 | PASS: clearing atta preserves Saved and Dairy, still empty. Disabling Saved reveals 238 dairy products from Mool Market 1. Store category restored to All products afterward. 167-170 |
| EX-04 | Dismiss an unapplied store price draft; P07,P16 | PASS: select Up to Rs100, close X without Show products; Rs279 atta remains in the 5000-product catalogue. No accidental filter application. 170-172 |
| EX-05 | Type below Wholesale MOQ in cart editor, Update, Cancel; P04,P08,P16,P19 | PASS: changing 2 to 1 yields Minimum order 2 packs; cart remains 2 packs/Rs1160. Cancel restores the original cart. This checks typed rejection, not the previously tested decrement control. 174-177 |
| EX-06 | Carry a search between Bulk and Wholesale; P05,P07,P08 | PASS query retention: tomato has no Bulk results; switching to Wholesale preserves query and shows tomato 10kg/Rs580 and ketchup. Different catalogue membership alone is not a defect. 179-182 |
| EX-07 | Open delivery selector above search keyboard, choose a different order, open tracking, Back; P02-P04,P10,P14,P18-P20 | Correct MS-NEW-03 tracking opens and keyboard dismisses; Back retains Wholesale/tomato. RB-026: Preparing/40% conflicts with Delivered in 30 min in list, overlay and tracking. Selector spacing extends RB-013. 183-189 |
| EX-08 | Save a searched Wholesale SKU, enter Saved, change to Bulk; P02,P05,P07,P10,P16 | DEFECT RB-027: Saved silently clears query; Bulk selection still displays the same Saved tomato excluded from Bulk discovery search. Toast's numeric name suffix extends RB-008. Test bookmark removed; Wholesale Saved returns to zero and cart unchanged. 190-193 |
| EX-09 | Both Shopping help FAQs expanded; P03,P10-P14,P21 | Text wraps readably and both expanded states are exposed in hierarchy; spacing extends RB-013. This adds current-build visual/semantic evidence to the old FAQ tap result. 197-199 |
| EX-10 | Search Help for Wholesale order with both FAQs expanded and IME visible, follow result; P01-P05,P14,P18 | PASS: PO-NEW-01 result arrow remains tappable above keyboard; opens the matching Wholesale tracking screen with Rajasthan Chilled Distribution, 2 packs and last-known status. No support message sent. 200-201 |
| EX-11 | Back from Help's searched order to expanded Help state; P02,P04,P20 | PASS: both FAQs and PO-NEW-01 query retained. Cleared audit query and closed Help/settings afterward; final Shop screen has 5 items/Rs750. 202-204 |

Batch evidence: 45 new PNG/XML pairs, IDs 160-204. New records RB-026 and
RB-027 bring the audit-local register to 27; RB-008 and RB-013 gain evidence.
No duplicates created for existing compactness/identity failures. Screenshot
177 is a cart-restoration capture despite its search-focus filename; rapid
routing had not completed. 195 is initial settings, 196 its settled lower area.

State at batch end: physical Redmi still runs r66.31; no build/install, checkout,
order, refund, review or message submission. Shop cart 5 items/Rs750; Wholesale
cart 2 packs/Rs1160. Existing Shop Saved atta preserved; temporary Wholesale
bookmark removed. Store category restored to All; Shop Scheduled/For you and
Wholesale Bulk retained. Wholesale tomato query was cleared by the observed
Saved behavior. Help test query cleared. Selected delivery panel now references
MS-NEW-03 (view selection only); no order status changed. Device left on Shop.

### Remaining coverage boundaries, not repeated attempts

- Authenticated pickup/payment and delivery quote/provider completion remain
  blocked at the recorded destinations. Repeating identical retries adds no
  new parameter coverage, and this audit does not authorize live transactions.
- The no-active-delivery state remains untestable with the existing 12 active
  orders. Preserve them; do not clear or finish orders to manufacture that case.
- Genuine product-photo gallery/video/zoom and unavailable scanner paths retain
  the prior test-data/unreachable limits. Illustrations do not qualify them.
- More-stores continuation remains unverified; no such entry exists in the
  observed first-page public-store header/footer. Do not equate working SKU
  pagination with restored related-store wiring.
- Full TalkBack traversal, every font scale, every SKU/store and every network
  condition are not passed by screenshot/hierarchy sampling. This register is
  bounded observed coverage, not exhaustive production acceptance.

The eleven selected expansion combinations reached their visible destination,
restored state, or recorded defect. Any subsequent expansion must name a new
reachable action/state/parameter gap before device execution; reuse the two
ledgers instead of cycling the same screens. No fixes are authorized by this
audit record.

Expansion SHA-256 evidence index:
`C:\GUARANTEED OUTCOME\outputs\cursor-buy-redmi-audit-20260922\expansion-160-204-evidence-index.json`.

## Continuous bounded follow-up: explicit remaining queue

Founder requested continued testing to finish reachable remaining combinations.
Reuse the 628-action historical register and this current-device ledger. Queue
selected from their remaining fields, with current installed-build visual checks:

1. Product report: selected-reason drag dismissal and reopen/reset state, visual
   reason selection and bottom action clearance; stop before Send.
2. Populated cart benefit choice: inspect available coupons/payment offers,
   select and remove/replace only if reachable without transaction; verify
   selected-benefit state through kind switch and Cart return.
3. Public store applied price/sort plus next-page/query intersection; verify
   visible SKU prices and store identity on the next result page, then restore.
4. Product variant choice with keyboard/long metadata and parent return: inspect
   current reachable choices; unavailable variant data is a blocker, not a pass.

Expand this queue only for a concrete new reachable action/parameter discovered
during these journeys. Existing authentication/provider/fixture boundaries stay
recorded rather than repeatedly retried. Do not submit reports, messages, orders
or payments. Changes remain restricted to audit evidence and this MD.

Follow-up queue refinement from historical remaining fields: inspect native
Share preview only (no recipient); cold process relaunch with retained cart,
Saved and store-query context (no data clearing); Orders group expand/collapse
and lower-list boundary; Help purchase-order-reference search. These are new
state/parameter gaps, not repeats of earlier warm navigation checks.

### Completed follow-up evidence through 278

| ID | New check | Result |
|---|---|---|
| CF-01 | Selected report reason, drag dismissal, reopen; P02,P03,P11-P14,P21 | 207-210: selection enables Send, drag returns to the exact product position, reopening resets reason and disables Send. PASS; nothing submitted |
| CF-02 | Selected report reason, outside-tap dismissal; P02,P14 | 211: same product position restored. PASS |
| CF-03 | Replace an applied coupon; P07,P16 | 214-216: select Rs40 basket coupon, replace with Rs60 product coupon; exactly one coupon selected. PASS |
| CF-04 | Coupon plus payment offer, switch cart scope and return; P02,P10,P16,P17 | 217-221: coupon retained while selecting Paytm offer; two selections survive scope/kind switches and cart return. Cart Rs690 reflects Rs60 coupon only; payment saving explicitly pending. PASS UI state; no provider confirmation claimed |
| CF-05 | Remove payment offer without removing coupon, then remove coupon; P07,P16 | 222-224: one coupon remains after payment-offer removal; removing coupon restores Rs750 and no selections. PASS; original cart untouched |
| CF-06 | Store cap + descending sort + next page; P05-P08,P14 | 228-231: Up to Rs100 and descending applies to 1135 results; next page range 41-80 retains store and visible Rs95 prices. PASS sampled scope/order; RB-002 still blocks normal readable Apply use, only exposed blue button edge at y1484 was tappable. No exhaustive sorted-dataset claim |
| CF-07 | Search under applied cap, then reset only filter; P05-P07,P19 | 232-234: atta empty under Rs100; reset restores 60 results without clearing query. Filter behavior passes; recovery guidance fails RB-028 |
| CF-08 | Distinguish repeated result identities; P01,P08-P10,P13 | 230-235: separate indistinguishable cards and second atta detail substantiate RB-029. This is review-catalogue UI evidence, not a production-data diagnosis |
| CF-09 | Related product inside a selected store; P01,P06,P22 | 236-241: Mool Market 1 milk recommendations lead to Family Dairy & Bake without naming seller on the entry card. RB-030 |
| CF-10 | Variant selection at 130% font; P08,P10-P14,P21 | 241-244: 2x1L/Rs128 updates summary and Rs64/L; options fit, selected=true in hierarchy. Restore 1L/Rs66, then font1.0. PASS; no product added. Variant keyboard/quantity descendants reuse prior functional evidence rather than duplicate an Add test |
| CF-11 | Back through related detail to store query; P02,P20 | 245,248: original Mool Market 1 product and milk query restored. PASS. 247 is still product, despite its provisional filename |
| CF-12 | Store-product Share preview; P01,P03,P10,P14 | 246: native chooser title correctly says Toned fresh milk and Cancel is accessible. Full URL/payload not exposed by chooser; recipient/app-uninstalled result remains BLOCKED without a receiving surface. No recipient chosen/message sent |
| CF-13 | Cold process relaunch with shopping state; P01,P16,P20 | 249-251,259,271: explicit force-stop then ordinary activity launch (no data clearing). Launcher reports COLD/6073ms activity start, but 249 still splash so that is not content-ready time. Settled destination Quick Shop; carts 750/1160, Saved1/0, Paytm/Work and 12 active/2 delivered preserved. Open store/milk query, Scheduled/Bulk choice and selected delivery view not restored. Record lifecycle observation, not a claim that every navigation state must persist |
| CF-14 | Purchase-ID group search and final delivery; P01-P05,P08,P10,P14,P18 | 253-258: BUY-NEW-01 exposes seven deliveries, including PO-NEW-01 and MS-NEW-01..06; last Track opens MS-NEW-06, Back restores query/footer. Group amount Rs3310 equals 1290+37+279+999+395+210+100. PASS. Group headers have no expand/collapse control; that historical residual is N/A in this visible UI |
| CF-15 | Orders footer Restock action and Back; P02,P14,P22 | 256,258-261: visible upper part of Restock card opens Wholesale. Back goes to Shop; reentering Orders clears search but retains scroll. Record top-level navigation observation. Floating cart hides lower Restock content, extending RB-015 |
| CF-16 | Unfiltered Orders lower boundary, recommendation and return; P02,P03,P08-P14,P18 | 262-267: final active order PO-240783 reachable; then 18-product recommendation region and footer. Tomato recommendation opens Shree Balaji Fresh detail; Back returns Orders position. Header says Shop instead of Orders on that detail, extending RB-006. 264 filename is provisional: it opened tomato, not Continue shopping |
| CF-17 | Actual Continue shopping footer; P02,P22 | 267-268: observed footer button opens Shop. PASS |
| CF-18 | Help purchase-ID matching with keyboard/scroll; P04,P05,P14,P18 | 274-275: BUY-NEW-01 finds seven correct deliveries; scrolling dismisses keyboard and final MS-NEW-06 row is accessible. PASS; subsequent business PO reference SGSHSSJEJ yields no result in 276 although displayed on tracking201. Record unsupported lookup-field limitation; no unsupported search-contract assumption |

New defects RB-028..030; existing RB-005 additionally evidenced by dishwash bars
represented by liquid bottles (231), RB-008 by related-product Back title Toned
fresh milk 8 (240/242), RB-018 by coupon card dead space (214/223). No fixes.
Cold launch reset the store/query and delivery selection; selected delivery now
MS-240782. Both temporary benefit selections cleared, variant restored, font1.0.
Capture252 contains UY-NEW-01 due early input; 253 is corrected BUY-NEW-01 proof.
Capture237 is the top product because an early swipe did not settle; 238/239
are the actual lower-page evidence. Preserve originals; do not relabel mistakes
as successful intended actions.

Still executing: historical-order product Add and existing-cart isolation, which
the old ORDER-006 row explicitly left open. Preserve original cart identities
and quantities, remove only the new test line afterward. No Reorder/clear-all or
transaction is implied by this selected test.

Historical Add completed (279-290): order MS-NEW-09 -> Items -> current Shree
Balaji Fresh tomato -> Add one -> cart. Six products/Rs787 and Wholesale2 remain;
five original lines retain qty1 (tomato37, biscuits60, curd48, notebooks210,
rice395). New tomato appears as a separate seller-labelled line, not a merge
with Mool Market 1's tomato. Back to its exact product and Remove restores
five/Rs750; historical order remains two items/Rs74. PASS P02,P08,P16,P18;
order-line metadata fails RB-031. No report/order/payment sent.

Next safe residuals selected from the historical register: applied coupon
minimum-threshold invalidation when an existing SKU quantity changes, and
Reorder into an existing cart with exact line reconciliation. These extend
the queue deliberately; no global cart clearing or real order submission.

### Follow-up closure through capture 328

| ID | New check | Result |
|---|---|---|
| CF-19 | Historical order -> product Add -> existing cart -> remove exact test line; P02,P08,P16,P18 | 279-290: new Shree Balaji Fresh tomato Rs37 remains separate from original Mool Market tomato; Shop 750->787->750, Wholesale unchanged. All five original lines qty1, historical order still2/Rs74. PASS isolation; RB-031 records missing quantity/line amount in Items |
| CF-20 | Applied coupon crosses minimum, then basket restored; P07,P16,P19 | 297-305: Rs40 coupon gives Cart710 from750; open exact Mool Market rice395 and remove temporarily -> four items355, coupon invalidates and discount disappears. Re-add from the same product restores five750; coupon remains unselected and three become available. PASS. This is below/above minimum transition, not exact Rs499 equality or expiry/provider qualification |
| CF-21 | Reorder into a nonempty mixed cart; P02,P08,P10,P16,P18 | 306-318: delivered MS-240741's eight listed products add eight separate qty1 lines to five original Shop lines; Shop2770=750+2020, Wholesale1160 untouched, combined3930. All original lines keep qty1. PASS addition/reconciliation; not a live purchase, supplier availability proof, repeated-Reorder race or changed historical-price acceptance |
| CF-22 | Restore after Reorder; P16 | 319-327: remove only the eight appended test lines in order: tomato37, atta279, oil835, rice395, soap164, notebooks210, onions42, bananas58. Shop totals2733,2454,1619,1224,1060,850,808,750; five original lines remain. No clear-all used. PASS cleanup; these cleanup taps are not eight new journey claims |

CF-21 source Items captures311-312 omit purchased quantities just as RB-031.
The delivered historical total2186 differs from current displayed product sum
2020; no price-history cause is inferred. Reorder uses the current displayed
amounts; this does not establish authoritative historical quantity/price mapping.
The current test shows preservation of unrelated existing SKUs; repeated Reorder,
concurrent updates and genuine unavailable/revised SKU outcomes are not inferred.

Final state328: Quick Shop, For you, five items/Rs750 and Saved1. Wholesale
remains two packs/Rs1160, Saved0; selected delivery MS-240782 after cold restart.
Font restored1.0. Both benefit selections cleared; all test cart lines removed;
original rice SKU restored to qty1 from its own detail. No build/install,
commit/push, runtime change, report/message/payment/order/refund submission.
Recent browsing history naturally includes the inspected products. Query/order
tab navigation state changed during testing; existing orders/data were preserved.

This continuation adds 124 PNG/XML pairs (205-328), 22 explicitly recorded
combinations including restoration, and four new audit-local defects RB-028..031.
Total audit-local defects:31. Reused controls used for setup are not new tests.
Existing RB-002/005/006/008/013/015/018 received additional occurrences described
above. Card/image defects are based on inspected PNGs; accessibility conclusions
remain bounded to UIAutomator semantics, not full TalkBack certification.

Additional capture notes:292 is a chicken product reached during routing, not
the cart despite its filename;293 is the actual cart. 294-296 are positioning
captures, not coupon-state passes. Screenshot300's floating cart reports the
product subtotal750 while Cart298 shows discounted710; this extends RB-009's
need for unambiguous amount labels. Capture304's accessibility announcement uses
Premium basmati rice 2860, extending RB-008's internal suffix exposure.

### Bounded completion and remaining prerequisites

The executable follow-up queue identified from the prior register is closed by
CF-01..22 and EX-01..11. This means the selected gaps reached an observed end
screen or explicit limit; it does not mean every conceivable input combination
or every production journey passed. No unresolved visible defect was repaired.

| Remaining class | Why another identical tap is not useful now |
|---|---|
| Authenticated pickup, payment, authoritative quote, accepted order and receipt | Current authentication/provider boundaries already recorded; no credentials, provider success or actual transaction fabricated |
| Return/refund/cancellation success, rejection, busy, duplicate and late response | Eligibility/provider data unavailable; real submission outside this audit |
| True price/stock/serviceability changes after cart, unavailable variants and brand-positive filtering | Requires authoritative changed or mixed data absent from sampled catalogue; changing fixture/source/device clock is not a real-user test |
| Coupon expiry/exact minimum and payment-provider confirmation | Time/provider/eligible boundary data absent; threshold crossing was tested, exact equality and confirmed saving were not |
| No-active-delivery rail | 12 existing active orders; removing them to manufacture the state would destroy user evidence |
| Genuine photo/video/gallery and scanner descendants | Current illustrations/unreachable paths and prior blockers; not supplier-media acceptance |
| Share receiver and app-uninstalled deep-link fallback | Native chooser only exposes title; no recipient/external send or uninstall authorized |
| Missing related-store continuation | No entry in observed public-store first-page header/footer; keep wiring ticket open. Product pagination is not a substitute |
| Runtime validation of local repairs | Installed r66.31 predates local fixes; another identical tap cannot qualify an uninstalled change. No fresh APK built in this bounded audit |
| Every store/SKU/page, arbitrary locale/font/device/network/race permutation and full TalkBack | Sampled coverage only; no blanket exhaustiveness or production acceptance. Concrete new data/state can create a new follow-up case |

No further concrete executable gap was selected after this reconciliation.
Continue only when a distinct reachable action/state/parameter gap is identified,
preserving this no-repeat ledger and the founder's defect-only boundary.

Evidence SHA-256 index for this continuation:
`C:\GUARANTEED OUTCOME\outputs\cursor-buy-redmi-audit-20260922\continuous-205-328-evidence-index.json`.
