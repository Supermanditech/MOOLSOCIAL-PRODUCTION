# V6 Redmi public Buy audit — underway

## Artifact and device

- V6 application baseline: `da4d266f97b4081f55bd98f1e9522f25bc8ee05f`.
- Build HEAD: `ae084c5ea03b569c4746c651b7f6f6d7b545beca`; admission-only parent `7a9e0a291c969fc12aa961a0426aaaea6b9a08ce`.
- Candidate: `UAW-CURSOR-REDMI-V6-REVIEW-20260913`; debug `CursorUiReview`, non-promotable.
- Installed package: `com.moolsocial.app.cursorreview`; version `1.0.0-r66.19-cursorreview`, code `2026091301`.
- Built and installed SHA256: `97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7`; 210792649 bytes.
- Signer SHA256: `CBDFC5969AD51ED570AFB1CF2FE60377E559D43F59D59E2AB66CCAF78EA9AC25`, matching previous installed review APK.
- Device: Redmi `TG8HCYTGGQT885OF`, model `23106RN0DA`, Android 13; physical capture 720×1600.
- `adb install -r` succeeded. Installed APK hash read back on device exactly matches. Original firstInstallTime remains `2026-08-27 15:09:48`. No uninstall, downgrade or clearing data. This verifies upgrade identity, not every retained user field.
- Previous installed APK preserved externally as `redmi-pre-v6-installed-20260913.apk`.
- Final successor binary preserved in the external evidence root as `uaw-cursor-redmi-v6-review-20260913-device-review-debug.apk`, checksum unchanged. The original wrapper provenance retains its build-time path; the binary was moved to the evidence archive after installation so generated APK bytes are not an unclaimed Git owner.

## Build qualification

Actual wrapper preflight and build finished successfully. Build exec session 39980 ended exit 0; Gradle reported 238.9 seconds. PREBUILD.md distinguishes inherited V6 regression evidence from fresh checks. No new source/test changes or fresh device passes inferred from host results.

External evidence root: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905`. Wrapper receipts: `redmi-v6-wrapper-preflight-20260913.log`, `redmi-v6-wrapper-build-20260913.log`; machine-state recovery receipt `redmi-v6-machine-state-recovery-20260913.log`. Native subprocess output also appeared in the tool session despite outer redirection; one output response was truncated. Terminal build success, artifact provenance and independently verified hash are retained; the redirected file is not represented as the complete native transcript.

## Device round 1

001: Open installed main activity. `am start -W` reported a wait timeout (10792 ms); subsequent physical screenshot shows the working Shop catalogue. Bootstrap log identifies this exact candidate and records first Flutter frame and review runtime passed. Preserve timeout as a launch observation; it is not a reproduced app crash or a proven normal cold-start performance pass.

Evidence: `redmi-v6-001-startup.png` and `.xml`. Catalogue shows Quick/Scheduled, categories, saved count 1, filter, product grid and lower navigation. UIAutomator emitted an MIUI theme-file warning but produced a usable XML; do not classify the OS tooling warning as a Buy defect.

Review services are explicitly isolated (`main.dart` `_runUiReviewOnlyApp`). Product fixtures and placeholder media do not establish live seller, stock, commercial claim or provider authority. Every downstream journey remains pending until physically exercised or explicitly blocked.

002–014: Fourteen physical captures are indexed with hashes in EVIDENCE.csv. JOURNEYS.csv currently contains 13 exercised action rows: 11 narrow device passes, one provider-blocked search, and one startup observation. These are not a complete inventory and are not ticket closures. Device font scale is 1.0 and density 320; other accessibility settings remain pending.

Shopping area opened; the typed numeric search showed provider-unavailable feedback and Retry. Retry remained unavailable. Android Back closed the keyboard first and then returned to Shop. The injected six-character input appeared as five visible characters; retain as an input-timing observation requiring a controlled check, not a confirmed customer typing defect.

Vertical scrolling exposes catalogue pagination above the bottom rail. Next loads a new page; horizontal lane scrolling exposes more products without moving the other lane. Opening Turmeric powder 97 reaches that SKU, 200 g pack, price ₹78. Delivery/benefits/information/reviews sections are scroll-reachable. Write review opens an explicit no-eligible-delivered-purchase sheet; Check again preserves that truthful result. No review was submitted. Remaining review actions and positive eligibility are not passed.

No confirmed new product defect is registered in this initial slice. This does not imply defect-free or completed coverage. Public-field mapping has only source reconnaissance so far; it is still pending.

## Scope and stop condition

## Device round 2 — comparison, report, share, Chat and Store

Captures 015–046 retained. Total evidence index: 46 captures; 025 and 028 are retained transition captures without a qualified UI result. Settled 026 and 029 establish their respective destinations. JOURNEYS.csv now has 40 exercised action rows: 35 narrow passes, 2 failures, 2 provider-blocked rows and 1 launch observation. Rows are individual actions, not whole-ticket or full-journey closure.

Comparison maintains product/pack identity but lacks populated supplier results; Refresh and Back tested. Report reason selection is mutually exclusive across all four reasons and enables Send; Cancel returns without submission. Native Share opens and Cancel restores the product; no recipient or external send selected. Ask seller carries the selected product into the matching Store conversation; context expand/collapse and keyboard/route Back return correctly. No calls, attachments or messages were sent. Untested descendants remain open.

Store preview and full catalogue open. Empty search, categories, category selection with retained query and clear-search recovery exercised. Added one Fresh tomatoes 1 item only, saw the correct ₹37 basket/cart, returned through Store preview and reopened full catalogue with category and quantity retained. Removing that last test item unexpectedly closed Store routes to general Shop. The test-added item is removed; existing saved item was not edited. Store category selection changed only through the tested UI. The newly opened seller conversation contains its generated unsent draft; it was not cleared.

Confirmed open findings: RV6-D001 (inapplicable area recovery advice in Store search) and RV6-D002 (Store exit after last-item removal in a Store-over-cart return). Details and source correlation are in DEFECTS.md. BLOCKERS.md records area lookup, populated comparison and product-specific review eligibility limits independently.

PUBLIC-DATA.csv starts with 12 field/action mappings from observed product, Store, comparison and report surfaces. Publication/update requirements are explicitly requirements, not claims of existing backend implementation or device qualification. This is an incomplete matrix; remaining visible fields and all other families must still be reconciled.

Next device state: general Shop catalogue, second page with first lane horizontally moved, screenshot 046. Next useful scope: remaining Shop controls, Offers, Wholesale, Orders, collection and nested cart/checkout/address journeys, then accessibility/relaunch and conditional coverage. Expand the source/action inventory alongside physical coverage. No implementation or new build.

## Continuing scope

## Device round 3 — catalogue refinements and Offers

Captures 047–070 were inspected and indexed. The action ledger contains 60 rows: 55 narrow device passes, 2 failures, 2 provider-blocked rows and 1 observation. No additional confirmed defect in this round; the two existing findings remain open. These counts do not represent complete journeys or ticket closure.

Tested ascending price, retention on reopening, cancellation of an unapplied sort change, descending price with a ₹100 pack-price cap, Standard and Multipack choices, unavailable brand metadata, Available toggle and Clear/Apply recovery to defaults. Other price thresholds, positive brands and exclusion of unavailable inventory remain unverified.

Offers entry, promotion Next, exact 10 kg/₹580/minimum-two product entry and Back retention passed. Ground spices category, empty search and Clear/Done recovery passed. Capture 067 has an inaccurate provisional filename containing `empty`; it actually shows populated Ground spices offers. All categories was restored at 070. Fixture publication and arithmetic do not establish real supplier approval, inventory or delivered-price authority.

PUBLIC-DATA.csv now contains 19 mappings, including query refinements, publication identity and offer minimum item total. No backend qualification is inferred. Shop refinements are restored to defaults; Offers is on All categories and its manufacturer promotion. No cart, order, payment or message was created in this round. Accessibility, relaunch and remaining nested/conditional journeys remain open.

## Device round 4 — Wholesale/Bulk entry checkpoint

Captures 071–075 inspected; all 75 indexed image hashes verified. Wholesale rail opens its catalogue; Bulk switches the listing set; first rice product preserves 25 kg pack and ₹1690 price with MOQ four and ₹6760 minimum item total. Scrolling exposes supplier navigation, freight inclusion, tax/invoice statements and benefits. These are displayed fixture statements, not verified supplier/logistics/tax authority. No new confirmed defect and no cart mutation in this slice.

Action ledger now has 64 rows: 59 narrow passes, 2 failures, 2 provider-blocked actions and 1 observation. Current physical state is the Bulk rice product scrolled to Order details and Additional checkout benefits (075). Product descendants, quantity/cart, return, remaining Wholesale controls and full audit inventory remain pending. This checkpoint is not full-module qualification.

Continue physical public Buy audit, action inventory, confirmed defect registration and field-level authority mapping. No defect implementation or corrected APK in this goal. Full audit is incomplete. Device retention/relaunch, all nested paths, provider boundaries and the final Git evidence handoff remain pending.

## Device round 5 — Bulk cart and checkout review

Captures 076–089 inspected. Added rice 4 at MOQ four then increased to five: product and cart totals match ₹8450. Selected ₹300 supplier coupon and PhonePe payment offer: cart ₹8150; payment savings remain separate. Switching Payment to Paytm gives explicit PhonePe-offer ineligibility without changing the total. Confirm order retains Work address and five rice packs. Delivery lookup remains unavailable after Check delivery; recorded B-004. No order or payment was submitted.

Payment progress-chip tap at Address had no visible effect (085); Continue to payment works. Treat this as an observation pending intent/source verification rather than declaring a broken navigation control. No new confirmed defect this round.

Current counts: 89 captures;77 action rows (70 narrow passes;2 failures;3 provider-blocked;2 observations);22 public-data mappings. Full inventory and audit remain incomplete. Current device is Confirm order after unavailable delivery feedback. The only test cart item is rice4 five packs; coupon300 and PhonePe offer selected; payment method Paytm. Preserve this explicit temporary state for next GST/details/Back/recovery checks then remove test basket through UI. Existing saved product and addresses unchanged. No live provider qualification inferred.

## Device round 6 — GST validation, Back and recoverable tracker

Captures090–106 inspected. GST Add exposes legal name GSTIN billing address and temporary-reuse disclosure. Empty submission focuses name with visible error above keyboard; Audit name advances validation to GSTIN;123 rejected. Back dismisses keyboard then sheet without applying details. Toggle-off tapped before leaving Confirm; exact off state not separately captured and must not be claimed fully verified. No invoice saved.

Android Back traverses Confirm to Payment to Address to Cart retaining Paytm, Work, five rice packs and coupon-adjusted8150. Decrement to four shows subtotal6760 total6460. Decrement at MOQ removes the sole test item and restores Bulk grid with Add. Basket test data removed; no orders or payments created.

Tracker rail opens; Deliveries12 expands list; selecting MS-NEW-09 restores that identity in Quick delivery tracker. Hide collapses to bike9plus rail; reopening restores MS-NEW-09. No live status authority inferred. Current screen is expanded MS-NEW-09 tracker over Bulk catalogue (106). Original tracker selection was MS-240782; restore after completing tracker checks if available. Keep and sound unchanged. Existing addresses and saved product untouched.

Totals106 captures;93 action rows:86 narrow passes;2 failures;3 provider-blocked;2 observations.24 public-data mappings. No new confirmed defect; two remain open. Full audit remains incomplete. Next reachable work: tracker Keep/sound/expanded order, Orders and remaining saved/scheduled/address journeys, accessibility and lifecycle; complete source/action inventory and blocked-descendant mapping remain required.
