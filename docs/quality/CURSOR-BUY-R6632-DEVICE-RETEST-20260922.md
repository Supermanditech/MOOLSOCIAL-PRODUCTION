# Redmi r66.32 defect replay

Replay completed on 22 September 2026. Stopped at founder-requested boundary: every original finding is closed within observed review scope or linked to an open child/dependency. This is not production acceptance.
Scope: implemented Buy defects and compact Store address/Maps entry. Store-origin
integration, authentic photos and live provider/auth completion are postponed by
founder. Preserve existing device data. No real order, payment or message.

Required identity before replay: APK version/package/signer, local SHA-256 versus
pulled installed base APK, source manifest and launch. Evidence requires observed
PNG and UI hierarchy where available; a successful tap alone is not a pass.

| Original | Result | Redmi disposition | Capture evidence |
| --- | --- | --- | --- |
| RB001 | CLOSED | Store details and final other-Store card clear Android navigation. | 008,011 |
| RB002 | CLOSED | Store filter Show products CTA visible and applies selection. | 012,013,015 |
| RB003 | CLOSED | Rice search returns rice/cereal rather than unrelated price labels in observed results. | 018 |
| RB004 | CLOSED | Store filter/category text compact; category selection changes scoped results. | 012,067,068,071 |
| RB005 | CLOSED | Same review illustration/identity in Store saved grid and product detail. Authentic photographs remain DEP-02. | 019,020,022,062 |
| RB006 | OPEN -> NEW-002 | Product Back label corrected; padded Store names remain in Cart and checkout. | 020,026,029,050,055 |
| RB007 | OPEN -> NEW-001 | Store search unboxed, but requested Buy-style expansion remains absent. | 007,016,035 |
| RB008 | OPEN -> NEW-002 | Draft/Save copy improved; customer name still padded in Cart/checkout and Maps query. | 023,090,026,107 |
| RB009 | CLOSED | Selected Shop subtotal/total Rs750 clearly separated from All baskets Rs1910. No arithmetic failure claimed; coupon calculation has host evidence only. | 026,077 |
| RB010 | CLOSED | Quantity dialog says 500 g pack once; keyboard controls reachable; cancelled unchanged. | 027 |
| RB011 | OPEN -> NEW-003; DEP-01 | Sign-in methods reached, but Back loses originating checkout. Live authentication not exercised. | 029-033 |
| RB012 | OPEN -> DEP-01 | Delivery unavailable explanation and Change address/collection recovery work; live order/provider completion remains unqualified. | 055,059 |
| RB013 | OPEN -> NEW-004/005/006 | Compactness is not fully closed: Store/supplier collection promotion, Recently viewed spacing, selected-area contrast remain. | 049,057,062,076,008 |
| RB014 | CLOSED | Wholesale coupon empty state now says current Wholesale order. | 051 |
| RB015 | CLOSED | Observed Shop/Wholesale product images and Offers cards are unobscured by cart; not a universal all-layout claim. | 020,022,040,048 |
| RB016 | CLOSED | Offers promotion uses navy/pale app palette and coordinated background. | 040 |
| RB017 | CLOSED | Final publisher MoolSocial visible/tappable above Android navigation. | 041,042 |
| RB018 | OPEN -> NEW-009 | Payment benefit cards still reserve appreciable blank space beneath content; compactness not accepted. | 052 |
| RB019 | CLOSED | Recently viewed rice and atta show matching product illustrations instead of missing-image icons. Spacing is separate NEW-005. | 062,063,065 |
| RB020 | CLOSED | Store filter selected checkmarks white/readable against navy. Area selector is separate NEW-006. | 012,013 |
| RB021 | CLOSED | Category sheet opaque white with one handle; no ghost SKU text. | 044,067 |
| RB022 | OPEN -> NEW-007 | Duplicate focused EditText removed; remaining node still exposes neither text nor content-desc while empty. | 086,087 |
| RB023 | CLOSED | MoolSocial publisher produces honest empty result with no unrelated general cards. | 041,042 |
| RB024 | CLOSED | Buy search finds displayed Mool Market 1 Store. | 035 |
| RB025 | CLOSED | Visible 1-40/60 footer, Next reaches 41-60/60, end cue and disabled Next. More stores opens Store 11 then returns to prior position. | 070-074 |
| RB026 | OPEN -> NEW-008 | Original MS-NEW-03 still Preparing/40% with Delivered in 30 min suffix. | 098,099 |
| RB027 | CLOSED | Wholesale Saved preserves tomato; Bulk excludes Wholesale-only saved item. Temporary bookmark removed, count back to zero. Store query/category also retained. | 068,069,090-094 |
| RB028 | CLOSED | Price-capped empty rice result explains cap; reset preserves query and reveals matching products. | 016,018 |
| RB029 | OPEN -> DEP-02 | Repeated template catalogue remains visible; authentic Store records/photos postponed. | 018,071 |
| RB030 | CLOSED | Related rice continuation remains the same Store; explicit More stores switches identity intentionally. | 025,073 |
| RB031 | CLOSED | Historical item displays recorded 2 x 500 g pack and Rs74 line amount. Reorder pricing has host evidence; no reorder submitted. | 039 |
| REG4642 initial Store CTA | DUPLICATE CLOSED | Same original as RB002. | 012-015 |
| REG4643 initial rice relevance | DUPLICATE CLOSED | Same original as RB003/004. | 018 |
| Inactive delivery rail | OPEN -> DEP-03 | Current 12 active deliveries legitimately show rail; zero-active state not established on retained device. | 002,096-099 |
| Initial Offers theme | DUPLICATE CLOSED | Same original as RB016. | 040 |
| Address/Google Maps addition | LINK PASS; destination DEP-02 | Compact Store-record address/pin and checkout entry. Offline launch 009; online search 106 PNG/107 fresh XML. Exact Store destination unverified. | 008,029,106-108 |

Original approximately 33 findings include overlapping initial Store findings;
this table does not turn duplicates or deferred data prerequisites into new fixes.

## Founder-reported new defect

R6632-NEW-001 — Store search does not expand like Buy Home search.
Reported by founder during r66.32 Redmi replay: Store search remains fixed.
Expected: reuse the established Buy search expansion behavior while keeping every
query/result scoped to the selected Store. State: OPEN, independently reproduced in 016 and contrasted with Buy Home 035. Registration only in this phase;
continue current APK testing and collect further founder inputs.

## Device observations in progress

Installed r66.32-cursorreview (2026092201), signer matches r66.31.
Built and pulled-installed SHA-256 both:
F74ADCD10DE5A5DFA3F6A29F024484DCB8CAF294FB0682C01680EB7190F2CF8A.
Retained launch: Shop cart 5 items/Rs750, Saved 1, 12 active review deliveries.
No app data cleared. Captures 001/003/004/014/017 include startup/transitions;
use settled captures for acceptance. Capture 006 was an incidental system shade,
excluded from Buy evidence; no system settings or notifications changed.

008/010/011: Store info and final other-Store card scroll above Android bar.
Compact Store-record address/map action visible. 009: pin launches Google Maps;
Google Maps reports no internet. Actual destination resolution remains BLOCKED
by offline device and postponed authentic Store location data, not passed.
012/013/015: Store filter CTA reachable; selected white checks visible; Rs100
applies (1135 review listings), visible products 37/42/66 etc remain same Store.
016: rice + Rs100 correctly explains price-limited empty result and offers reset.
R6632-NEW-001 independently reproduced in 016: keyboard opens but Store search
stays inline with Store header/controls; expected Buy-style expanded search.

R6632-NEW-002 (extends RB006/RB008) — Cart Continue browsing still displays
padded provider name Mool Market 000001 while product and Store display Mool
Market 1. Capture 026 PNG/XML independently confirms. Expected consistent
customer-facing Store name through Cart return. OPEN; register only, no code edit.

018: reset price cap retains rice and exposes rice/cereal products, no price-label
matches in observed results. 019/020: saved Store atta identity, price and image
agree; Back label uses Mool Market 1. 022/025: related rice opens same Store.
023/024: Ask seller clean title/name, no separate internal SKU or empty Brand;
structured product link retains exact ID. No message sent. Back restores product.
026: All baskets Rs1910 clearly differs from selected Shop subtotal/total Rs750.
027: quantity copy says 500 g pack once, controls visible with keyboard; cancelled
without quantity change. 028: Delivery/Collect choices visible in ordering.

029: pickup checkout shows Store-record address and Google Maps pin; extend
R6632-NEW-002 to this padded Store name too. 030/031: Sign in options reaches
Security > Account access > actual sign-in methods. No provider authentication.
R6632-NEW-003 (RB011 recovery extension) — Back from sign-in methods returns
Security (032), then Back returns main Mool menu (033), not the originating
Collect-at-store checkout. Expected cancel/back preserves checkout intent and
selection. OPEN; no implementation during replay. Sign-in entry works, full
recovery/return cannot be marked passed.

## R6632-NEW-004 — Remove pickup promotion from discovery details

State: OPEN; founder-confirmed scope, registration only during Redmi replay.
Wholesale product > Visit supplier still shows a large Order & Collect banner
and Order for collection CTA above SKU cards (049 PNG/XML).
Founder additionally reports the same banner in public Store > icon beside
search > Store details. Existing Redmi capture 008 records this second location.
Expected: remove the Order & Collect promotional block and its discovery CTA
from BOTH supplier preview and public Store details. Retain the compact Store
identity/address/Google Maps entry and existing checkout Delivery/Collect choice.
Do not remove pickup capability or change shared Store settings/contracts.

Replay continuation: 035 verifies Buy Home expanded search and known Store-name
lookup. 039 verifies historical items show 2 x 500 g pack and Rs74 line amount.
041 publisher sheet final MoolSocial row is above Android navigation; 042 selecting
it gives a genuine empty Offers result without unrelated product cards.
044 Wholesale categories have opaque background and one handle. 045 filter CTA
remains above Android navigation. 048 wholesale image is not covered by Cart.
050/055 extend NEW-002 padded Store name to Wholesale cart/confirmation.
051 Wholesale coupon empty state references the Wholesale order.
052 payment-benefit content and action are readable; no offer selected.
055 delivery-unavailable recovery controls shown; 059 Change address or collection
returns to address selection. No payment/order submitted. 057/058 GST form and CTA
are visible with keyboard, then cancelled and GST toggle restored off.
062 recent rice/atta images match their product illustrations; authentic photos
remain a postponed Store/provider dependency. No basket quantities changed.

## R6632-NEW-005 — Compact Recently viewed cards and Add action

State: OPEN; founder-reported and confirmed in Redmi capture 062 PNG/XML.
Shop > filters > Shopping tools > Recently viewed: each product card reserves
an extra lower row for Add, leaving substantial blank space beneath the image
and product metadata and reducing the number of visible products.
Expected: compact the card and place the existing Add/quantity action beside
appropriate product information without a largely empty dedicated row. Preserve
readable image/name/pack/price/Store details, accessible touch target, existing
add/quantity wiring, scrolling and Android/keyboard safe areas. Check the shared
Recently viewed presentation in Shop and Wholesale. No implementation during
this device-test/registration phase; no cart additions made to demonstrate it.


## Final child findings and dependencies

All NEW identifiers in this report have the prefix R6632-.
No child below was implemented during the replay.

- NEW-006 — Shopping area selected In this area tick is dark grey on navy (076 PNG); reuse a clearly contrasting selected mark. RB020 Store filter itself passed.
- NEW-007 — RB022 residual accessible-name defect: 087 XML has exactly one focused android.widget.EditText at [32,478][688,632], but text and content-desc are both empty. Visible label remains Recipient name (optional). Verify native accessibility name/focus with TalkBack when fixing; hierarchy evidence is not TalkBack certification. No request shared/copied.
- NEW-008 — RB026 remains: exact original MS-NEW-03 has Preparing your order and Delivered in 30 min in the list (098) and 40% selected overlay (099). Fix estimate normalization wherever the stale suffix occurs; do not convert an unfulfilled order to completed. 100 was not a successful tracking navigation and is not tracking evidence.
- NEW-009 — RB018 residual compactness: payment-benefit cards in 052 still leave a substantial lower blank area after the description/terms, around a small Select action. Compact shared card height without reducing accessible targets or clipping wrapped terms. No offer selected.
- DEP-01 — RB011/RB012 live authentication/provider/order completion remains postponed and unqualified. UI entry and unavailable recovery were exercised. Do not simulate acceptance or place orders to close this prerequisite.
- DEP-02 — RB029 authentic catalogue, photos and Store location mapping remain postponed. New Maps action launches Google Maps online with the existing Store record's name/address (107 fresh XML). Google returns general Jodhpur markets (106 PNG), not a verified Store destination. Do not claim a correct physical pin or invent coordinates. NEW-002 also covers padded display name in the query.
- DEP-03 — Inactive-delivery rail device acceptance remains open: retained data has 12 active records. No cancellation/data reset was used to create zero-active state. Preserve host regression evidence; qualify zero-order/zero-active state with an isolated approved dataset later.

NEW-001 through NEW-005 are fully described above. NEW-004 includes BOTH
Wholesale supplier preview and public Store details (founder annotation).

## Completion and evidence limits

31 unique RB findings: 21 CLOSED within the stated review-build replay scope;
10 OPEN with child/dependency links. Initial REG4642/4643 are two duplicates,
accounting for the earlier approximate 33; they do not inflate closure counts.
The additional inactive-delivery requirement is DEP-03, not falsely closed.
9 child defects registered; 3 explicit dependency/retest records. Some original
findings share a child. No new development, second APK, commit or policy work
was performed in this replay. Stop requested by founder after this report.

Capture directory: ../../apps/mobile/build/review-candidates/cursor-buy-post-redmi-20260922-r1/redmi-retest/.
Use numbered PNG/XML names in that directory. Screenshots are evidence for visual
findings; XML alone does not establish rendered acceptance. 001/003/004/014/017
are transition/startup observations, and 006 incidental system shade is excluded.
An evidence-helper limitation was found near the end: uiautomator can return a
zero exit status without refreshing a reused remote XML file. 100/101/106 XML
are demonstrably stale relative to PNG and MUST NOT support acceptance. Capture
107 onward uses a unique remote path per capture so an absent fresh dump fails
the pull. 107 independently confirms the Maps query; 108 independently confirms
return to Buy. No missing/uncertain screenshot is used to close a visual defect.
101 PNG is transitional (placeholder images/missing rail); no settled defect
claim based on that frame. 098 PNG independently confirms NEW-008 regardless
of XML. Previously inspected paired visual captures support closures above.

Retained state: Shop 5 items/Rs750, Wholesale 2 packs/Rs1160, Shop Saved1 and
Wholesale Saved0 after temporary test bookmark removal. Selected delivery was
changed to MS-NEW-03 for original reproduction; no delivery status was changed.
GST temporary toggle reverted; address request/GST forms cancelled. No real
order, payment, authentication, chat message, share, phone call or navigation
route was submitted. Online Maps query was user-initiated by testing the pin.
Authentic Store/provider acceptance, complete TalkBack and every font/device
combination are not certified by this bounded pass.

## Built candidate and preservation

Installed review package com.moolsocial.app.cursorreview, version
1.0.0-r66.32-cursorreview (2026092201). Built APK and pulled installed base.apk
SHA-256: F74ADCD10DE5A5DFA3F6A29F024484DCB8CAF294FB0682C01680EB7190F2CF8A.
Source HEAD 87bc96d4c28300146c9e2c3c3b37c7c3aacffed0 plus pinned local changes.
3233 inputs in source-manifest-final.txt; post-replay-source-verification.json
confirms zero input mismatches and the same two APK hashes after replay.
All 18 required integrated tips passed the recorded ancestry check.
Two required full cycles each passed 2472 with 27 inherited skips and zero failures.
Dart analysis has no errors/warnings; 3 inherited informational brace notices
remain (Flutter analyzer's nonzero info-only exit is preserved, not called clean).
Candidate remains nonpromotable review build; testing/report completion is not
production release qualification. Build/install/gate receipts remain in the
candidate directory; failed earlier test receipts are preserved.
