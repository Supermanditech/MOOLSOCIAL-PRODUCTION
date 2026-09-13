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

## Device round 7 — tracker controls and order-address descendants

107–121 inspected. At resume tracker had collapsed; rail reopened selected MS-NEW-09. Keep displays Kept; sound-on displays active speaker and while-using-app disclosure. No actual arrival audio qualified. Sound-off and unkeep were tapped before opening tracking; final preference readback still needed. Tracker body opens exact MS-NEW-09. Refresh truthfully marks unavailable order updates and last-recorded estimate (B-005). Lower milestones and Address/Items/Help/Manage order/Invoice are reachable; only Address descendants exercised this round.

Order Address displays snapshot and explains that future saved-address changes do not change this order. Manage future addresses opens Home/Work picker. Work menu exposes Edit/Remove; Edit prefills unchanged fields and Close returns without save. Request an address opens optional recipient/share/copy/manual controls. Add it myself opens blank form; blank submission rejects missing recipient street locality. No link created/shared/copied; no address saved or removed; no order or message action.

Totals121 captures;107 action rows (99 narrow passes;2 failures;4 provider-blocked;2 observations);27 public-data rows. No new confirmed defect. Current physical state: blank Add delivery address form with validation at121. Next: remaining manual-address validation and safe dismissal; then Items/Help/Manage/Invoice order descendants. Restore tracker original MS-240782 and confirm muted/unkept preferences after tracker coverage. Full audit incomplete; all unresolved descendants retained in ledgers.

## Device round 8 — address validation and order item/invoice returns

122–135 inspected;133 is native-picker transition only and134 the settled result. Unsaved manual form accepts Audit/Test/Test entries then rejects absent phone; fixture phone9000000000 advances to missing PIN rejection. No address saved. Close returns Request sheet; two Android Backs dismiss Request and picker to tracking. Order Items retains MS-NEW-09 two-item74 snapshot; product opens matching500g37 Fresh tomatoes and returns to same Items then tracking. Invoice matches order and arithmetic. Download opens Android save picker; Back cancels with explicit feedback. No file saved and no existing Downloads item opened or changed. Positive export and reopen remain pending.

Totals135 captures;118 exercised action rows (110 narrow passes;2 failures;4 provider-blocked;2 observations);28 public-data mappings. No new confirmed defect. Current device: MS-NEW-09 invoice after save cancellation135. Existing addresses and basket unchanged. Continue invoice positive export with unique filename and order Help/Manage paths, then remaining families. Do not treat picker cancellation as download qualification.

## Source inventory reconciliation — still incomplete

Read-only class inventory of buy_v2_views.dart identified these remaining families requiring action-level reconciliation and device results or explicit blocked descendants. This is a coverage worklist, not defect enumeration or new implementation scope:

- Product variant selector (2047), trade decision controls (2261), continuation (3171), zoom/gallery (3436/3574), content/trust/review positive cases (3825/4245/4733).
- Cart discovery (17681), delivery instructions (17956), tips (18101), mixed destination/scope (16264), empty and restored carts, campaign replacement/threshold/expiry.
- Checkout collection (7420), commercial terms (6799), quote/price/promise changes (6649/8608/8680), confirmation (8739), recovery (9156); positive provider transitions require safe existing fixtures or explicit blockers.
- Orders tabs and empty/unavailable states (9403/9801/9857), delivery exceptions (10202), balance payment (10373), live panel (10504), collection order (10776), resolution (11937).
- Assistance and nested intents/channels/prescription/share (12469/19672/19751/19824/19908/19986); no real messages or purchases.
- Account (12919), saved lists and shopping tools, Scheduled selection, remaining category/filter paths, Store collection availability and full supplier content.
- Address-request provider completion and ordinary address type/save/removal validation, GST positive form/reuse lifecycle, invoice export bytes/reopen/cancel/failure.
- Cross-cutting Back variants, keyboard,200% text and compact fit, app background/relaunch and retained selection, account/provider-dependent isolation and stale-response cases.

Each family still needs exact action enumeration; this inventory alone proves no pass. Other Buy source owners and public fields must also be reconciled before final handoff. Earlier row-level remaining columns remain authoritative gaps; none is silently closed by this worklist.

## Device round 9 — exported invoice, resolution form and Help freshness defect

136–148 inspected. Invoice saved through Android picker with unique name RedmiV6-audit-MS-NEW-09-20260913-0330.pdf in device Download. App success confirmed;exact191919-byte export pulled to external evidence root;one page parsed and host PDFium render inspected legible with exact order/item74 contents. PDF and render separately indexed;host rendering is not a Redmi viewer-reopen pass. Existing Downloads files untouched. Local PDFium5.13.0 test runtime is outside worktree under external evidence/pdf-audit-runtime;no project dependency changed. Earlier console extraction encoding error recovered by ASCII-safe JSON without touching PDF.

Manage order ties to MS-NEW-09. Cancellation selection exposes reason;empty disables submit;four reasons visible;Need to change address selected enables submit. Back dismisses without request;order remains preparing. Help opens correct seller/order and generated unsent draft. Expanded Chat context drops tracking's last-known/update-unavailable ETA qualifier and shows raw Delivery in12min. Registered RV6-D003 with112/147 and source mapping correlation. Back restores tracking. No cancellation/message/call/payment submitted.

Totals148 physical captures plus exported PDF and host render (150 evidence rows);128 action rows:119 narrow passes;3 failures;4 provider-blocked;2 observations.30 public-data mappings.Three confirmed defects remain open. Current screen: MS-NEW-09 tracking lower controls148. New test export retained as evidence;basket empty;existing addresses untouched. Generated order-support draft remains unsent. Original tracker selection and muted/unkept preference readback still pending. Full audit incomplete.

## Device round 10 — delivered orders and resolution eligibility

149–162 inspected. Back from tracker returns originating Bulk catalogue (150 filename was provisionally named orders;actual content Bulk). Orders rail shows12active2delivered. Delivered tab exposes Shop MS-240741 and Wholesale PO-240728 with original-promise wording. Shop delivered detail shows completed timeline and Delivery partner details unavailable. Post-delivery controls accessible.

Return/Replacement/Refund selection is mutually exclusive and each has unconfirmed item eligibility. Scrolling Refund exposes all eight product rows disabled plus Retry/support. Retry retains unavailable state;B-006 registered. Back restores delivered order without submission. Reorder produces editable eight-product/eight-item cart2020;old purchase2186 is not a new-order total. No order/payment/return/refund/message executed.

Totals162 physical captures plusPDF/render=164 evidence rows;141 action rows (128 narrow passes;3 failures;8 provider-blocked rows;2 observations). The8 blocked rows overlap six blocker records;not eight independent services or defects.32 public-data mappings.Three confirmed defects remain open. Current device:reordered Shop cart162 with only eight test-added products. Do not clear unrelated data;the cart was empty before Reorder and these test lines can be removed after cart checks. Addresses unchanged. Full audit incomplete;Wholesale delivered and collection paths still pending.

## Round 11 - reordered cart instructions and mixed-supplier checkout
Physical Redmi captures 163-182 reviewed against the same checksum-bound installed V6 APK. The eight-item test cart remains 2020. All lower sections were reachable; recommendation card actions remain untested. Call on arrival, Leave with security, Leave at the door and Do not ring each selected exclusively; tapping selected quiet option cleared it. Re-selection survived checkout and Android Back. Original unselected instruction state restored in182.
Shop checkout retained Work, Paytm and GST off. Seven shipment cards account for eight lines; three estimates unavailable extend B-004. No order/payment submitted. The confirmation view does not display the instruction; this is an observation, not evidence of loss, since cart Back retains it and source assigns the selected destination instruction to order groups. Actual provider propagation and relaunch still need qualification.
Twenty new physical captures, nine bounded action rows (eight passes and one provider-blocked), one public-data mapping. Cumulative: 182 physical captures plus exported PDF and host render; 150 journey/action rows; 33 data mappings; three confirmed open defects and six blocker records. Counts do not imply complete journey coverage or backend acceptance. Test basket retained for continued cart audit; no product changes or new APK.

## Round 12 - recommendations, empty scope, test-cart cleanup and connected profile
Captures183-206 physically reviewed. Recommendation Add increased9/2105 from8/2020; a different recommendation opened matching bhujia85/400g and Back retained cart. Empty Wholesale scope preserved Shop9; Browse Wholesale retained prior Bulk catalogue, cart reopen restored9/2105. Keep Cart cancelled removal. Then only the nine audit-created items were removed, restoring original empty basket; no pre-existing items were removed.
Connected account drawer and Personal profile reached. Invalid whitespace name correctly rejected but error guidance clipped at normal text with and without keyboard: RV6-D004. The initial tap during delayed autofocus hit space on the keyboard (197); this timing artifact is not a product defect. Back left Display name Not added. No valid profile save.
Profile Language routes first to Privacy preferences; Language opens English/Hindi selector. Hindi selected and retained on reopen but preferences and Buy controls remain English without limitation disclosure: RV6-D005. English restored and visually read back206. Device ends on Privacy preferences with original English and service area unchanged. No authentication, messages, orders, payments, implementation or new APK.
Twenty-four captures and12 bounded action rows added (10 passes,2 failures); two field mappings. Cumulative206 physical captures plus PDF/render,162 action rows,35 mappings,five open confirmed defects. Full audit remains incomplete; next reachable preferences/service-area/accessibility and remaining Buy journeys continue. No conclusion of all-account, all-cart or backend qualification.

## Round 13 - preferences external destinations and offline boundary
Captures207-219 physically reviewed. Service-area dialog exposes original Jodhpur label and Save/Use my location/Remove; dismissed without change. Accessibility opens Android settings; Vision controls inspected and Back restores preferences. No OS accessibility change; enlarged text, reduced motion and screenreader behavior remain pending. Blank209 is only transition.
Notifications opens correct Cursor Review App info; scrolling then Notifications reaches OS controls with Show notifications off. No settings changed. Back restores preferences. Privacy opens external Chrome but content is unavailable with ERR_INTERNET_DISCONNECTED (218). Device readbacks: airplane0 wifi0 mobile_data0. B-007 records this current environment limit; earlier provider failures are not retrospectively attributed to it without binding/time evidence. Back restores preferences; blank217 is transition.
Thirteen captures and seven action rows added (six narrow passes,one blocked), four public-data mappings. Cumulative219 physical captures plus PDF/render;169 action rows;39 mappings;five open confirmed defects;seven blocker records. No product change, APK, permission/connectivity toggle, account write or transaction. Full audit remains active. Device ends at preferences with English/Jodhpur unchanged. Continue remaining Buy/profile actions and actual accessibility behavior; online content remains unverified.

## Round 14 - source reachability reconciliation and Security boundary
Source inventory refined: BuyV2AssistView has only its constructor declaration under apps/mobile/lib; current BuyV2View.assist renders BuyV2TrackingView in buy_v2_screen.dart near2576. Legacy Assist topic/composer/channel controls are therefore source-unreachable in the current public route, not device passes. Current Help uses shared Chat. Buy header account is _openBuyProfile > showGlobalProfilePanelV2, not the legacy BuyV2AccountView hub; restored/alternate legacy Account reachability still needs exact disposition before declaring its children unreachable. Other source-family inventory remains incomplete.
Captures220-227 reviewed. Preferences Back restores prior Bulk catalogue. Buy drawer Security opens signed-out boundary. Sign in opens chooser; Android Back restores Security. No provider action, credential entry or authentication. App permissions opens correct Cursor Review App info, then OS list: camera allowed;location microphone notifications not allowed. No permission changed. Back through App info restores Security. Blank224 is transition only.
Eight captures; six narrow device passes plus one excluded authenticated-provider boundary and one source-unreachable ledger row. Cumulative227 physical captures plus PDF/render;177 ledger rows (includes source/exclusion dispositions);40 public-data mappings;five open defects and seven blocker records. No new confirmed defect. Device ends Security;cart remains empty;English/Jodhpur unchanged. Continue remaining public Buy actions, media/variants, collection, saved/scheduled, conditional coverage and actual accessibility/relaunch checks. Full audit remains incomplete.

## Round 15 - second Back defect and saved-product retention
First Back from prior Security checkpoint reached Android home228. Controlled re-entry verified: Security without sign-in returns Buy231-232;Security > Sign in > cancel234 > next Android Back235 exits to launcher. RV6-D006 registered. Earlier first-return passes stay narrow;PD040 corrected to unresolved full chain. No provider selected. App reopened normally without force-stop or clear data;Shop Quick and saved count1 restored230/237. Splash229/236 not qualified as failures.
Existing saved wheat2 5kg279 survives reopening;detail matches and Back returns saved list238-241. No saved mutation or cart change. Single hero tap no action;source shows pinch InteractiveViewer not single-tap full-screen. Supplier image/video input and publication constraints now mappedPD041;this is source contract evidence only, not actual supplier bytes or device decoding acceptance. Pinch/reset/multiple-media/video/variant qualification remains pending.
Fourteen captures and six action rows added (four passes,one failure,one observation). Cumulative241 physical captures plus PDF/render;183 ledger rows;41 public-data mappings;six open defects;seven blocker records. Device ends saved Shop list with original wheat intact and empty cart. Continue saved test-item lifecycle, Scheduled, media/variants and remaining full audit. No implementation or new APK.


## Round 16 - saved-item lifecycle and Scheduled checkout
Captures242-256 physically reviewed. Saved wheat survives Quick-to-Scheduled switch. Isolated notebook6 pack6 INR210 saved, added to cart, then removed from Saved: original wheat remains and notebook cart line is retained. Low-value basket coupons show no eligible Shop offers. Scheduled checkout retains Work address, Paytm, one notebook and INR210. Delivery review remains unavailable; this extends B-004, not a duplicate defect. Positive slot selection, quote acceptance and provider serviceability remain unqualified. No order/payment action executed.
Three Android Back presses return to retained notebook cart254; intermediate screens were not individually captured. Removing only the test notebook restores empty cart and saved wheat255. Quick restored and visually read back256. Original saved product, addresses and payment selection preserved.
Fifteen captures and eight bounded action rows added (seven narrow passes,one provider-blocked). Cumulative256 physical captures plus PDF/render;191 ledger rows;41 public-data mappings;six confirmed open defects;seven blocker records. No product implementation or new APK. Full audit remains incomplete; remaining scheduled/provider, media/variant, collection, accessibility and other public Buy action coverage continues. Capture250 was re-viewed after a context-output truncation; original file preserved.


## Round 17 - Saved clear confirmation and destination isolation
Captures257-265 physically reviewed. Shop clear confirmation describes removal of one saved item and cart preservation. Keep saved cancels;original wheat confirmed retained265. Wholesale starts Saved0;empty-state Show all products returns catalogue. Isolated wholesale notebook6 carton120 INR3480 saved, then cleared using explicit confirmation. Toast and empty state confirm removal. Returning Shop and opening Saved shows original wheat5kg INR279 unchanged. No cart changes;Quick retained. Close-icon/Android-Back cancellation, clear with nonempty cart, stale listing and authenticated owner switching remain separate unverified cases.
Source mappingPD042 records bookmark keys, destination-limited clearing, ownerScope/mutation protection and catalogue resolution;these are not backend/storage-security passes. Nine captures,five narrow passes,one data mapping added. Cumulative265 physical captures plus PDF/render;196 ledger rows;42 data mappings;six open confirmed defects;seven blocker records. No new defect, product change, APK or transaction. Full audit incomplete;remaining product/media/collection/accessibility and conditional journeys continue.


## Round 18 - Store collection entry and signed-out checkout
Captures266-278 reviewed. Saved wheat > Visit store displays Order & Collect benefit and CTA. CTA opens matching full Store catalogue;269 is pre-settled transition,not a failure. Added only test tomato500g INR37. Store minicart opens Cart with Continue browsing same Store;272 likewise transition,settled273 qualified. Review order selects Collect at store and exact store. Continue to payment retains collection and Paytm;sign-in requirement visible and Review order disabled. No authenticated provider/order/payment action.
Back and Delivery switch restore original Work address and37 basket276. Back Cart retains item277;remove only test item restores empty cart and original saved wheat Quick278. No new defect. Authentication-dependent collection quote/payment/order/QR/ready/collected/relaunch descendants explicitly blocked in COLLECTION-ROUND18-05;not a production pass. Reverse mode toggle,expiry/withdrawal,other stores and full remaining collection actions still need disposition.
Thirteen captures,six narrow passes and one authentication-blocked row added;PD043 maps capability ownership expiry and checkout identity. Cumulative278 physical captures plus PDF/render;203 ledger rows;43 data mappings;six open confirmed defects;seven existing blocker records plus authentication boundary explicitly indexed in JOURNEYS. Full audit remains incomplete. No implementation or new APK.


## Round 19 - supplier-media fixture reconciliation and product content
Default public session and generated development template chain inspected. Empty mediaAssets flows into illustration fallback;B-008 now explicitly records missing real supplier-media coverage for this cohort. Alternate workspace-published session remains to be checked;no global claim that all routes lack media. PD041 technical formats remain source-only. A combined read of long catalogue seed rows exceeded output budget;recovered with non-emitting counts and bounded source ranges under standing read-recovery authority. No files or evidence lost and no safeguard changed.
Captures279-283 reviewed. Wheat product content shows pack5kg unit55.80/kg,Brand not provided,no ratings/reviews and reachable lower controls. Related wheat card opens canonical Sardarpura Supermart offer279 with illustration label. Android Back returns Saved list instead of prior product detail;recorded observation pending navigation-contract assessment,not a fabricated pass or confirmed defect. Cart remains empty;original saved wheat and Quick intact.
Five captures,two narrow passes,one navigation observation and one test-data-blocked row added. Cumulative283 physical captures plus PDF/render;207 ledger rows;43 data mappings;six confirmed open defects;eight blocker records. Full audit incomplete. Next work includes alternate published-media fixture reachability,remaining variant/Store controls and physical accessibility checks. No implementation/new APK.


## Round 20 - alternate media mapping and physical enlarged text
Alternate workspace-public conversion inspected: work_models1663-1699 passes no mediaAssets,so this route also retains default empty supplier-media list. B-008 extended with exact conversion evidence;not a renderer failure or permission to alter Store.
Physical Android Display > Text size entered. Original S/font_scale1.0 recorded284-286. XXL selected287;immediate pre-Back read1.0 was not treated as applied. After Back,readback1.5 and enlarged Buy288 confirm150% runtime. Saved header and product text reflow;product sections scroll and review actions wrap289-291. No visible text clipping in inspected sections. Saved image shows missing-image icon288 while product illustration renders289;recorded observation requiring settled reproduction,not a confirmed defect. Not a200% pass or full accessibility qualification.
Restored S through OS control292-293,Back committed;readback1.0. Buy Saved wheat/Quick/empty cart restored294. No user cart/address/bookmark mutation. Eleven captures and six rows added:four narrow passes,one media observation,one source gap. Cumulative294 physical captures plus PDF/render;213 ledger rows;43 data mappings;six confirmed open defects;eight blocker records. Full audit remains incomplete;remaining enlarged-text actions,keyboard,reduced motion,media observation and other public Buy journey gaps remain active. No new APK or product implementation.


## Round 21 - disposition of related-product Back observation
Resolved CONTENT-ROUND19-03 using its retained physical sequence281-283 and exact callback/session read. Related cards call openProduct with default preserveComparisonOrigin=false;while already in product view the prior product is not stacked. closeProduct therefore returns to original Saved/catalogue root. Registered RV6-D007 for loss of preceding product-detail return and position during related-offer exploration. Original ledger observation updated to device_fail;historical round19 record preserved. No new captures or test execution claimed and no duplicate ticket created.
Cumulative294 physical captures plus PDF/render;213 ledger rows;43 data mappings;seven confirmed open defects;eight blocker records. Product/media audit still has unresolved image-after-text-change observation and conditional coverage. Full action inventory and field-level mapping remain incomplete. No product implementation,APK,device mutation or policy edits this round.


## Round 22 - canonical milk variant selection and Cart identity
Source inventory found existing milk500ml/2L and Wholesale rice/oil variants. productVariantsFor enumerates _catalogueProducts by canonicalId/destination,not _pagedProducts;generated IDs differ from canonical templates. Reached canonical milk through real Scheduled search and related-product carousel,without route injection. Quick milk query empty296-297;Scheduled results retain query298. Related horizontal scroll and selection299-301 exposes1L66,500ml35,2x1L128. Select500ml updates pack/price/unit70/L302;Add and Cart retain500ml35 Family Dairy and Bake303-304. No supplier photo qualification;illustration remains labelled.
Cart Continue browsing Mool Market000001 persists from earlier Store visit despite canonical Family Dairy cart item;observation recorded pending exact expected browsing-context assessment. Removed only test500ml item305. Cleared active query through search X/Done306,restored Quick/Saved307. Original saved wheat and empty cart retained;recent search/history from testing preserved. Font remains original1.0.
Thirteen captures,five narrow passes,one observation and PD044 mapping added. Cumulative307 physical captures plus PDF/render;219 ledger rows;44 data mappings;seven confirmed open defects;eight blocker records. Remaining2L and Wholesale variant selection,unavailable variants,cart retention across variant changes,paged supplier variant mapping and full audit still incomplete. No product code/new APK/order/payment actions.


## Round 23 - Wholesale order identity, return eligibility and Back
Orders search Wholesale filters Active and remains when switching to Delivered (309-311). PO-240728 opens with three purchased trade products, delivered timeline, full-advance bank-transfer payment presentation and retained order identity (312-313). These are recorded fixture states, not qualified financial truth. Buyer label touches Shree Balaji Retail at normal text: registered RV6-D008. Return shows all three items disabled with eligibility unavailable (314-315), extending B-006. No order, payment or resolution submitted; Order updates unchanged. Back retains Wholesale query and Delivered tab (316).
Nine physical captures and six ledger rows added: four narrow passes, one confirmed failure, one provider-blocked action. Cumulative316 physical captures plus PDF/render =318 evidence rows;225 journey rows;44 public-data mappings;eight confirmed open defects;eight blocker records. Cart remains empty and original saved wheat retained. Device ends on filtered Delivered orders. Full action inventory and audit remain incomplete. No product implementation, new APK or policy changes.


## Round 24 - Wholesale invoice recovery
Resumed retained Wholesale/Delivered Orders317. PO-240728 Invoice shows missing item details318. Refresh returns unchanged filtered list319;reopen still missing320. Back action tapped after capture320;no separate settled Back capture yet. Source confirms invoice entry requires nonempty order.lines and retryCommerce is owner/procurement guarded. Added B-009 for positive Wholesale invoice-data qualification;not a new confirmed product defect.
Four reviewed physical captures and two ledger rows (one narrow retry-navigation pass,one blocked invoice). Cumulative320 physical captures plus PDF/render=322 evidence rows;227 journey rows;44 public-data mappings;eight confirmed defects;nine blockers. No user order/payment mutation, implementation or new APK. Full audit remains incomplete.
