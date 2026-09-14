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


## Round 25 - Wholesale Items, product return and delivery-address boundary
PO-240728 detail resumes at retained lower position321. Items shows three products322;rice product opens with25kg1690/MOQ4 and Android Back returns same order Items323-324. No Add. Items return restores detail;Address shows correct order ID and explicit missing recipient/full address/partner325. Manage future addresses opens existing Home/selected Work326;Android Back returns detail at retained position327. No address/order/payment mutation.
Source productsForOrder resolves current catalogue products and has review-only fallback when product IDs are absent. Items uses current product price/pack/policy;therefore the displayed fixtures are not evidence of purchase-time lines or policy. PD-045 adds immutable order snapshot versus current supplier listing requirements. No fabricated historical-data pass or confirmed repricing defect.
Seven reviewed captures,four rows (three narrow passes,one data observation),one data mapping. Cumulative327 physical captures plus PDF/render=329 evidence;231 journey rows;45 data mappings;eight confirmed defects;nine blockers. Full audit remains incomplete,including historical line revisions,remaining item links and other untested public journeys. Device ends delivered Wholesale detail;no implementation/new APK.


## Round 26 - Wholesale reorder, receiving choices and restoration
Reconciled prior coverage against remaining cart actions. Reorder PO-240728328 creates isolated current-price basket329-330:rice4x1690=6760,oil2x3096=6192,notebook1x3480=3480;7packs total16432. Source11471 uses current MOQ,not proof of original quantity restoration. No purchase submitted. Three discovery sections scroll before receiving/bill331-333;totals match. Their individual card destinations remain untested.
All four Trade receiving choices physically selected:Call334,Deliver335,Loading337,Cartons339. Horizontal rail makes last options reachable336/338. Selection is exclusive;retapping Cartons clears340. Scoped removal confirmation341 removes only the test Wholesale basket and returns catalogue342;Shop was0. Current search Wholesale retained. Original no-instruction/empty-cart state restored;no order/address/payment mutation.
Small60x60 cart image icons329-330 are explained by explicit illustration label-fit fallback (design2078-2081;views18405). Larger same-product illustrations are in322-324. This is not evidence of failed network loading;earlier150%Saved image observation remains consistent with the same mechanism but is not newly reproduced. Supplier-media coverage remains blocked.
Fifteen captures,nine rows(eight narrow passes,one observation),PD-046 receiving-instruction data mapping. Cumulative342 physical captures plus PDF/render=344 evidence rows;240 journey rows;46 data mappings;eight confirmed defects;nine blockers. Full audit remains incomplete:Shop tip actions,quantity editor,remaining conditional checkout/order actions and complete source/action reconciliation still pending. No product implementation/new APK.


## Round 27 - quantity editor validation, keyboard and cancellation
Returned to Shop343;opened generated tomato1/500g37 and added only one test pack344-345. Quantity number opens editor with existing1 selected and numeric keyboard;Save/Cancel visible346. Empty input347 and fractional1.5 input348 reject with readable whole-number error. Cancel restores1/37349. Reopen and keyboard Enter submits3;product/cart3 and111350. Draft4 then AndroidBack hides keyboard351;secondBack dismisses without changing saved3/111352. Zero submitted through keyboard rejects below minimum1pack353. Cancel then decrement only test quantity3 to0 restores Add and empty cart354.
PD-047 maps input,MOQ,numeric capacity,availability and quantity persistence boundaries. Conditional large input,WholesaleMOQ,prescription cap,closed/unavailable supplier,stale comparison offer and relaunch remain unverified;none silently counted passed. No new defect reproduced.
Twelve captures,eight narrow device passes,one mapping. Cumulative354 physical captures plus PDF/render=356 evidence rows;248 journey rows;47 data mappings;eight confirmed defects;nine blockers. User saved wheat/addresses retained;device ends tomato product with empty cart. Full audit remains incomplete. No implementation,new APK,order/payment or message.


## Round 28 - recovery routes and false confirmation
Source reconciliation enumerated confirmation/recovery actions. Initial custom moolsocial://app/buy recovery intent could not resolve;manifest117 restricts that custom host to YouTube path. Device unchanged355;unsupported diagnostic URI is not a Buy defect. Declared HTTPS https://moolsocial.com/app/buy?view=recovery&recovery=network delivered through Android VIEW explicitly to Cursor Review. Native Connection interrupted/Return to product356;tap restores exact tomato product/empty cart357. This is a warm declared-link navigation test,not a real network-error recovery or OS default-handler association qualification.
Declared HTTPS confirmation link https://moolsocial.com/app/buy?view=confirmation with empty cart/no purchase shows green Order placed,0 products/0 total/0 deliveries and saved recipient/address358. Registered high-severity RV6-D009. View order details opens existing list12active/2delivered359;reopen confirmation then Continue shopping returns Shop/empty cart360. No order/payment submitted or created by tested route transitions. Normal successful submission path was not called.
Added six reviewed captures and23 action rows:three narrow device passes,one failure,one observation,one unsupported-route disposition,and17 explicitly UNVERIFIED source-inventory descendants. Those17 are pending inventory,not tested checks or additional defects;safe existing fixtures/route entry must still be sought. Two data mappings PD048/049 bind confirmation authority and recovery context.
Cumulative360 physical captures plus PDF/render=362 evidence rows;271 action records(including17 new untested inventory entries);49 public-data mappings;nine confirmed defects;nine coverage blockers. Full inventory/audit incomplete. Next work can test declared generic price/stock/service/payment/delay links without transactions;affected-item/address/order-help and valid confirmation descendants require their exact prerequisites. Device ends Shop Quick with saved1 and empty cart. No implementation/new APK/policy changes.


## Round 29 - remaining generic recovery route returns
Declared HTTPS /app/buy?view=recovery&recovery=price,stock,service,payment,delay opened through package-targeted Android VIEW on Redmi. Inspected each native message and tapped its primary Return to Shop action:price361-362,stock363-364,service365-366,payment367-368,delay369-370. Each returns same Shop Quick catalogue with saved1 and empty cart. Payment copy explicitly cannot confirm whether money was debited. Generic delay copy refers to exact order but no order was supplied;no order-bound qualification claimed.
Updated existing INVENTORY-ROUND28-01..05 from unverified to narrow device_pass;no duplicate action rows. Remaining12 entries in this specific inventory still unverified,not the full-module pending count. Conditional affected-item/address/help and valid confirmation require exact safe prerequisites. PD049 qualification updated. No actual provider failure/recovery,order/payment,network change or message performed.
Ten captures added. Cumulative370 physical captures plus PDF/render=372 evidence rows;271 action records;49 mappings;nine confirmed defects;nine coverage blockers. No new defect reproduced. Full action inventory/audit remains incomplete. Device ends Shop Quick with empty cart. No implementation/new APK.


## Round 30 - order recovery, Help context and Back
Declared order link opens MS-240782 with Orders selected371. Delay recovery372 Return to order retains exact tracking but selects Shop373. Registered minor navigation defect RV6-D010;initial destination replacement before recovery origin capture is source-correlated,not a product fix.
Recovered374 and fresh375 show tracking. Repeating the identical delay URI376 also leaves tracking;therefore the earlier attempted Help tap is not a Help test. Re-entered order link then delay link;visually confirmed recovery377 before tapping Get help. Opens Sardarpura Supermart Chat378 with exact MS-240782 and unsent draft. Expand379 shows total4839,Sardarpura342003 and delivery awaiting live confirmation. Android Back380 returns exact tracking;D010 selected rail persists. No Help defect fabricated;no message sent. New unsent supplier draft is retained,not silently deleted.
Ten reviewed captures;one existing pending inventory action qualified narrowly and two new action records(one failure,one narrow pass). Cumulative380 physical captures plus PDF/render=382 evidence rows;273 action records;49 mappings;10 confirmed defects;nine blockers. Eleven entries from the specific round28 inventory remain unverified;this is not the full-module pending count. Audit remains incomplete. Device ends MS-240782 tracking;cart and addresses unchanged. No implementation,new APK,policy or backend change.
Read recovery: compacted capture374 was reopened and inspected before further action. A guessed source path and guessed372 filename failed;bounded file discovery recovered exact paths. One UAT tail output truncated;prior round summaries remain preserved and current append is independently read back. No truncated output treated as qualification.


## Round 31 - checkout address recovery and retained basket
Declared checkout link with empty cart returns catalogue381. Added only isolated tomato500g37 through Add382;Cart383 Review order opens normal checkout384 with original Work selected. Declared warm HTTPS service recovery385 shows Work/Basni342005 and conditional Change address/Return to Checkout. Change address opens saved chooser386;AndroidBack cancels and retains Work and one item37 at checkout387.
Re-entered distinct checkout link then service link;confirmed recovery388 before Return to Checkout tap. Restores address step Work and37 basket389. Cart Back390 retains exact tomato;decrement only test item removes it and restores empty Shop391. No address edits,selection changes,order/payment or message. These are route/navigation checks from real checkout state,not actual provider serviceability rejection or changed-address revalidation.
Eleven reviewed captures;two existing inventory actions narrowly qualified and one added journey record. Cumulative391 physical captures plus PDF/render=393 evidence;274 action records;49 public-data mappings;10 defects;nine blockers. Nine round28 conditional actions remain unverified;other full-module coverage also remains open. No new defect,implementation,APK or policy change. Device ends Shop Quick with saved1,empty cart and original addresses preserved.


## Round 32 - quantity calculation limits and conditional coverage prerequisites
Added isolated tomato37 at392;catalogue quantity number opens editor393. Thirty-digit all-nine input via keyboard Enter rejected with readable too-large error394;Cancel restores1/37395. Reopen;13-digit all-nine count parses but exceeds total calculation capacity;396 shows readable smaller-quantity guidance. Cancel then decrement only original test item restores empty catalogue397. No invalid amount saved or order submitted. PD047 adds narrow numeric rejection evidence;exact boundary,valid bulk totals and other supplier/mode limits remain unverified.
Source reconciliation: four affected-stock descendants need valid unavailable product facts or exact placement affectedProductId(session10627-10643,10762-10780,11043-11058). Generic links cannot qualify these. Remaining inventory updated with precise prerequisites,not marked passed. Tip controls use disabled default(router253/session1891/cart_contracts353);views18109 omits empty-option groups. Recorded source-unreachable optional tip action and PD050 ownership/quote/settlement requirements. No enabled tip device pass claimed. A singular contract filename read failed;bounded discovered plural path recovered it without policy changes.
Six reviewed captures;two device action passes and one source-only optional control record. Cumulative397 physical captures plus PDF/render=399 evidence;277 action records;50 mappings;10 defects;nine blockers. No new defect. Full audit/action inventory remains incomplete;device ends Shop Quick with empty cart,saved1 and original addresses preserved. No implementation,new APK,backend or policy work.


## Round 33 - Wholesale minimum quantity and cross-mode retention
Wholesale catalogue398 tomato10kg580 Add startsMOQ2/1160399. Quantity editor400 shows minimum2;enter1 via keyboard rejects with readable minimum2error401. Replacing input with3 and keyboardEnter updates3packs1740402. Shop403 retains separate500gAdd and displays Allcarts1740. That control opensAllcart404 with Shop0/Wholesale3 and exact10kg line;no pack conversion. Minus3to2 gives1160405;minusatMOQ2 removes test line and returns emptyWholesale406.
Nine reviewed captures,four narrow device action passes,PD047 augmented. Cumulative406 physical captures plus PDF/render=408 evidence;281 action records;50 mappings;10 defects;nine blockers. No new defect,order/payment,message,address edit,implementation or APK. Source/provider MOQ revisions,procurement identity and full remaining module audit remain unqualified. Device ends Wholesale with empty cart;original Shop saved wheat and addresses untouched.


## Round 34 - Wholesale public content and commercial claims
Opened tomato10kg580 Wholesale product407. Scrolled order/commercial details408,product/pack/highlights/specifications409 and description/ratings/reviews410. Registered RV6-D011:identical summary-only content repeats across sections,forcing extra scrolling. Source views3877-3910 removes these duplicates only forShop;CatalogueProductContentAdapter1621 generates these summary-only sections. Distinct supplier content must remain;no product implementation.
Commercial claims408 include freight included,GST included/invoice provided and catalogue details verified. Source views2438-2453 uses freightIncluded,constant tax-invoice copy and current signal or confirmedOn fallback. PD052 records required supplier/quote/tax/freshness authority;fixtures do not prove those live claims or an actual supplier mismatch. PD051 records structured content ownership/revision/deduplication. AndroidBack411 returns sameWholesaleempty;no cart/address/order mutation.
Five reviewed captures,three action records(one failure,one data observation,one narrowBack pass),two data mappings. Cumulative411 physical captures plus PDF/render=413 evidence;284 action records;52 mappings;11 confirmed defects;nine blockers. Full audit remains incomplete. Next uncovered conditional source fixtures include closed Pet Family Store,unavailable Beauty Supply and prescription-required catalogue items;their actual public reachability must be checked without forced state. No new APK,implementation,backend or policy work.


## Round 35 - closed-store and unavailable-product entry recovery
Bounded source discovery identifies s-dog-food/Pet Family Store and s-shampoo/Beauty Supply through model s-prefix and catalogue seeds. Declared HTTPS product route522 opens these existing fixtures without state injection. Closed dogfood412 displays closure and tomorrow8am reopening;Add absent. Recovery controls413 Check availability414 leaves same closed state;no actual provider refresh success inferred. Change product415 restores originating Wholesale catalogue.
Unavailable shampoo416 displays non-orderable status and noAdd. Recovery417 explains cannotadd;Check availability418 remains unchanged;Change product419 returns originating Wholesaleempty. This tests product entry and navigation,not stock becoming unavailable after addition:four checkout affected-item descendants remain unverified. No product/cart/address/order mutation or message. The first broad source-match output truncated;bounded seed ID/title/seller projection recovered exact matches;no truncated evidence used as a pass.
Eight reviewed captures;six action records(four narrow passes,two unchanged-refresh observations);PD016 augmented with seller-name fixture limitation and authoritative workspace-state requirement. Cumulative419 physical captures plus PDF/render=421 evidence;290 action records;52 mappings;11 defects;nine blockers. No new defect or APK/implementation/policy/backend work. Full audit remains incomplete;prescription entry and its conditional UI still pending. Device ends Wholesaleempty.


## Round 36 - prescription owner boundary reconciliation
Source m-metformin-500 has destination medicine(models1455). Declared product link opens Care/Medicine bottom rail420 with Use prescription. This is a separate customer journey,not a public Shop/Wholesale quantity descendant. No prescription button,upload,medical data or order action used. AndroidBack421 restores original Wholesaleempty. Earlier generic pending mentions of prescription caps/entry in rounds27/32/34/35 are superseded by this observed ownership disposition:Medicine handling remains untested and outside this audit;not a failed or passed Buy feature.
Reconciled recorded Store,Offers,filter,address,scheduled and collection action names to avoid repeat coverage. Remaining public Buy work still includes complete action/source reconciliation,uncovered address persistence/cancellation variants,Store public information,provider-dependent comparison/checkout/resolution/media and final handoff. No claim that these are all remaining actions or that audit is complete.
Two reviewed boundary captures,one boundary record. Cumulative421 physical captures plus PDF/render=423 evidence;291 action records;52 mappings;11 defects;nine blockers. No new defect,implementation,APK,backend or policy work. Device remains Wholesaleempty;user data preserved.


## Round 37 - closed Store public header and full listing
Product422 Visit store423 preserves closedPet Family Store and non-orderable cards. FirstcardInfo424 opens same dogfood with explicit Back to Store;425 restores. Header collapse426/expand427 works. Viewall428 exposes all4closed cards but heading calls them4availableproducts:registered minor RV6-D012. Count uses products.length with fixed available wording(catalogue6916). Order restriction works;no actual Add bypass. AndroidBack429 returns Store;X430 returns original product.
PD019 extends listed/orderable count semantics;PD053 maps public locality,address verification,affiliation,hours and service labels. Source addressConfirmed is trust.ready+nonemptylocality;fulfilment affiliation label comes from destination. Their actual provider truth is not qualified by these fixtures. A workdir typo prevented one read process from starting;literal correct workdir recovered read only,no file/device mutation from failed call.
Nine reviewed captures;five action records(four narrowpasses,onefailure);one newmapping. Cumulative430 physical captures plus PDF/render=432 evidence;296 actionrecords;53 mappings;12 confirmed defects;nine blockers. No cart/address/order mutation,implementation,APK,backend or policy change. Full public Buy audit remains incomplete. Device ends original closed dogfood product with emptycart.

## Round 38 - Store-only conversation context and return
Pet Family Store431 Ask opens correct Store-only Chat432 with no unrelated product/order attached. Automatic question draft remains unsent. Expand433 reveals only divider and blank spacing:registered RV6-D013. Source _ChatCommerceContextCard always constructs an expansion with divider even when decisionFacts is empty and productAppRoute absent. AndroidBack434 restores exact closed Store. No calls,attachments,messages,orders or cart/address changes.
Recovered prior truncated combined image/source output by separately viewing434 and bounded source discovery. A nonexistent ui_v2/chat read failed;rg --files identified actual features/chat/screens/chat_thread_screen.dart. No truncated or failed output used as qualification. Standing bounded recovery authority used;no safeguards changed.
Four reviewed captures;three action records(two narrow passes,one failure);PD007 augmented. Cumulative434 physical captures plus PDF/render=436 evidence;299 action records;53 mappings;13 confirmed defects;nine blockers. These are cumulative audit observations,not a full-coverage claim. Full public Buy audit remains open;remaining conditional/provider and action reconciliation work preserved. Device ends Pet Family Store with empty cart and unsent Chat draft retained. No implementation or new APK.

## Round 39 - Other Store navigation and horizontal retention
Current device verified435 Pet Family Store. Other Store arrow opens Shree Balaji Fresh436;AndroidBack437 restores original Store. Swipe438 reveals Ghar Bazaar;card-body tap opens that exact Store439. AndroidBack440 restores original Store with horizontal position retained. Four narrow navigation checks pass;no new defect and no cart/address/order/draft changes.
PD054 maps recommendations:session.otherStorePreviewsFor7638 uses same-region/destination eligible previews in paged mode;fallback selects first distinct eligible listed Stores from known catalogue. No claim that suggested grocery Stores match pet-product shopping intent or that actual delivery is available. Those authoritative relevance/serviceability rules remain explicit public-data requirements,not fixture-qualified behavior.
Six reviewed captures;four action records;one mapping. Cumulative440 physical captures plus PDF/render=442 evidence;303 action records;54 mappings;13 confirmed defects;nine blockers. Full action reconciliation and remaining reachable journeys remain unfinished. Device ends Pet Family Store at swiped Other stores. Audit only;no product implementation,new APK,backend or policy change.

## Round 40 - modal-link navigation failure and isolated address lifecycle
Previous round was concrete progress:four Store navigation checks and PD054 sealed. Current gate passed and address coverage reconciled. Declared MS-240782 order link while Pet Family Store modal remained open440 caused navigation assertion441;AndroidBack442 exited to prior Display task. Registered high review-APK RV6-D014;release behavior and exact cause unverified. App-scoped bounded logcat confirmed !_debugLocked in Navigator route push at07:33:45. Normal activity reopen443 transient loading then444 usable Shop. No force-stop or data clear. Normal Profile445 Open orders446 retains12active2delivered;MS-NEW-09 Track447 works. 448-450 historical address and saved Home/selected Work intact.
Isolated Other place entry451-454 used recipient RedmiAudit,existing fixture phone9000000000,non-deliverable test-only street text,areaBasni/PIN342005,no landmark. Rapid automated multi-field entry453 shifted input before keyboard settled;corrected locality/PIN in separate actions454. This automation artifact is not an app defect. Actual stored street is udit test only;not claimed as valid geography. Save455 returns historical order;456 confirms original Aarav Work address unchanged;457 reopens with isolated entry selected. Menu458 Remove459 Keep460 retains entry. Repeated Remove confirmation461 then picker462 proves only test entry removed;Home fallback selected. Work reselected and reopened463 proves exact original two entries and Work selection restored. No transaction,message,original address edit or cart change.
Session10494-10536 adds/selects,persists customer state and invalidates checkout pricing;removal chooses first remaining address. These source calls do not prove disk persistence or live quote correctness. PD025/026 updated with physical scope. A broad CSV search exceeded output budget;bounded exact PD026 projection and64line source read recovered;no truncated evidence used.
23 reviewed captures;eight action records(one failure,seven narrow passes);two mapping updates. Cumulative463 physical captures plus PDF/render=465 evidence;311 action records;54 mappings;14 confirmed defects;nine blockers. Remaining includes address edit-save/process persistence,full action/source reconciliation and provider/auth conditional coverage;not complete enumeration. Device ends saved-address chooser over MS-NEW-09,Home/Work originals intact,Work selected,cart empty. Full goal active;no implementation,new APK,backend or policy change.

## Round 41 - conditional coverage reconciliation
Previous turn made concrete progress:device address lifecycle and navigation failure sealed at d0538ee306ea58f8731ab7cff3a0b57e93e470b7. Current implementation gate passes. Reconciled311 recorded actions by disposition;these are recorded actions,not a complete module denominator. Nine previously unverified round28 branches now have precise blocked_test_data dispositions,without any new pass or closure.
B010 covers four affected-item recovery actions:validated unavailable revision for exact already-carted SKU is required. Source10627-10643 and prior closed/unavailable entry412-419 distinguish product-entry restrictions from after-cart failures. B011 covers five positive confirmation descendants:source confirmedOrders initialization4015,population10682/11029 and completion11231 show why existing historical orders and false empty confirmation358 cannot qualify active purchase confirmation. Missing fixture/provider conditions remain unqualified;no transaction or state injection. Updated three stale early address remaining-notes to point to round40 physical evidence,without claiming edit-save or process persistence.
No device actions/captures this round. Counts remain463 physical captures/465 total evidence,311 action records,54 mappings,14 confirmed defects;coverage blockers now11. Full action/source reconciliation and reachable tests remain incomplete. No product implementation,new APK,backend,policy work or changed user data. Next independent work remains saved-address edit/process persistence and broader uncovered action reconciliation;blocked branches are retained for final handoff rather than retried without changed prerequisites.

## Round 42 - saved clear-list cancellation paths
Previous turn reconciled nine conditional coverage prerequisites with no fabricated pass. Current gate/device pass;normal Back from chooser and Shop464 preserves original saved badge1. Prior saved product/detail/Back/mode checks identified in rounds15/16,so focused uncovered clear-list cancellation paths. Saved465 retains wheat5kg279. Read _confirmClearSaved8495-8525 before tapping:only confirmed true invokes clearSavedProducts. A read parameter typo(sixty instead of60) failed without mutation;corrected bounded65line read under standing recovery authority.
Clear list466 identifies exact Shop/count1 and discloses Cart retention. Keep saved467 preserves original item. Reopen and closeX468 preserves item;reopen and AndroidBack469 preserves item. No positive clear action or original saved deletion. Cart empty;Home/Work unchanged;Work selected. Positive clear-list needs an isolated list and remains unqualified;account-switch race/process persistence not inferred from these cancels.
Six reviewed captures;three narrow action passes. Cumulative469 physical captures plus PDF/render=471 evidence;314 action records;54 public mappings;14 confirmed defects;11 blockers. No new defect,implementation,APK,backend,policy work or transaction/message. Full audit remains incomplete. Device ends original Saved in Shop Quick with wheat and count1.

## Round 43 - isolated Wholesale saved clear and cart separation
Current gate passes. Wholesale470 has Saved0;save firsttomato10kg580 then Saved471shows1. Add472honoursMOQ2/cart1160. Clearlist473 identifiesWholesale1 and cart-preservation disclosure. Confirm474clears onlyWholesaleSaved to0 withcart2/1160retained. Empty-state Showallproducts475 returns catalogue with exactqty2. Minus476 removes onlytestline/cartempty. ShopSaved477 originalwheat5kg279/count1intact. No original saved item deleted;Home/Work unchanged and Work selected.
PD042 augmented. Source session5200 removes only destination-prefixed saved keys,updates mutation revision and persists saved/customer state. Physical clear and cross-destination preservation are qualified here;disk/process persistence and account-switch races are not. Round42 positive-clear pending note now has this isolatedWholesale qualification,not a general all-destination/account pass.
Eight reviewed captures;five narrow action passes. Cumulative477 physical captures plus PDF/render=479 evidence;319 action records;54 mappings;14confirmeddefects;11blockers. No new defect or implementation/APK/backend/policy work. Device ends original Saved in Shop Quick;cartempty andWholesaleSaved0. Full module audit remains incomplete;remaining reachable actions and data requirements still being reconciled.

## Round 44 - physical Redmi saved invoice viewer
Current gate passes. ACTION_VIEW_DOWNLOADS478 resolver Files selected without Rememberchoice;479 exact earlier RedmiV6-audit-MS-NEW-09 PDF selected. Viewer480 opens onepage correctMS-NEW-09,Shop,ShreeBalajiFresh,AaravWork,2x500gtomatoes,totalINR74. Downloads metadata displayed0B but artifact opens;device SHA256 equals retained host D618A5FF426512D2B2D30DCC12B6BCBF528D40E9FEB532C0D9CEE146C8FCD2E2. No corruption inferred from listing metadata. No new download or PDF edit.
480 also shows undated Expected:Deliveryin12min. Raw order.promise is exported in downloader102 and invoiceUI546. Added occurrence to existing RV6-D003 freshness defect,not a new counted defect. Historical invoice should carry absolute/datetime-bound original promise or clear recorded qualifier. Exact content/viewer pass does not establish tax or provider authority. ViewerBack twice returned external browser481;explicit activityresume482 restores SavedShop1. No share,highlight,slideshow,rotation,network,message or file edit;external viewer controls outside audit scope. Source wildcard path failed;correct rg -g invoice discovery recovered. Initial hash tool-call parse failed before execution;separate bounded hash calls succeeded. No failed output used as evidence.
Five reviewed captures;three actionrecords(onepass,oneexistingdefectoccurrence,one external-return observation);PD028updated. Cumulative482physicalcaptures plusPDF/render=484evidence;322actionrecords;54mappings;14distinctdefects;11blockers. Full audit remains incomplete. Device ends original SavedShopQuick,count1,cartempty;original addresses retained. No implementation/APK/backend/policy work.

## Round 45 - Recently viewed orderability and return
Gate passed. Captures483-485 expose Shopping tools with Track active order, Monthly home basket, Recently viewed and Shopping settings. Recently viewed486 shows eight Shop products. Closed-store dog food Add487 and unavailable shampoo Add488 remain enabled without visible recovery feedback. Product489 confirms closed Store; Android Back490 restores history. Current physical capture491 confirms retained sheet. Registered RV6-D015 before further testing; two reproductions are one distinct defect. Session guards reject non-orderable additions; this does not qualify the presentation or feedback. No product implementation or restriction bypass.
Nine reviewed captures preserved and checksum-indexed; five action records, three narrow passes and two occurrences of D015. Cumulative491 physical captures plus PDF/render=493 evidence rows;327 action records;54 public mappings;15 distinct confirmed defects;11 blockers. Original Saved Shop count1 retained; no cart/address edits this round. Monthly basket, Shopping settings, history clear/cancel/normal Add and remaining data mappings still require coverage. These counts are not a complete module denominator.
Resume recovered a source path typo by exact rg file discovery; bounded catalogue5306 source read succeeded. An oversized UAT tail output was not used as new test evidence; exact final paragraph and CSV rows were read independently. Standing recovery authorization used; no policy edits. Full goal remains active and incomplete. No APK, backend, OPPO, real transaction or message.

## Round 46 - history cancellation and monthly basket discovery
Previous turn made concrete progress:round45 device failure and evidence sealed at a1a4426aef84b0c2de113112e279bd7b15288d4b. Current gate passes. History Clear492 explicitly discloses both Shop and Wholesale;Keep493 retains eight Shop entries. Positive clear is blocked by preservation of existing history;requires isolated fixture,not a source-only pass. Normal Back then filter494;expand/scroll495 exposes Monthly home basket. Sheet496 shows12products/21packs/INR5145 product subtotal and Quick6/Scheduled6. View products497 opens Quick basket group;Scheduled498 opens other group. No cart mutation or real transaction.
PD055 maps customer history IDs,global10 cap,destination/procurement filtering,clear scope and unresolved persistence/isolation. PD056 maps fixed first12 static Shop products and quantities,current resolved SKU values,subtotal/fulfilment groups and availability guard. A 30-day household-plan claim needs an authoritative business selection/versioning basis;observed fixture selection is not a personalized or supplier-authoritative plan. Add,partial failure,existing quantities,modal cancel and business-data qualification remain pending.
Seven reviewed captures;five action rows(three narrow passes,one observation,one blocked test-data action);two new mappings. Cumulative498 physical captures plus PDF/render=500 evidence rows;332 action records;56 public mappings;15 distinct defects;11 registered blocker groups plus explicit history-preservation prerequisite in action ledger. These are recorded coverage counts,not a complete denominator. Device ends Monthly basket Scheduled;SavedShop1 retained;cartempty;no address edits. No implementation,APK,backend,OPPO,policy work or messages. Full audit remains incomplete;Shopping settings and remaining reachable descendants are next.

## Round 47 - monthly cart action and settings preference returns
Previous round made concrete progress:history and monthly discovery sealed at833d4c3d95159890c18f5044bed1cd88f53fb598. Current gate passes. From preserved Scheduled monthly view,filter499 -> tools -> monthly sheet500. Add501 produces21packs/INR5145. Cart502 confirms12products21items,Shop21 Wholesale0 and same subtotal. RemoveShop confirmation503 precisely names21items;confirmed504 returns Monthly Scheduled catalogue with emptycart. Only isolated test additions removed;no order/payment. Closed basket intent then tools -> Shopping settings505. Original Saved1,Recent8,Work locality andPaytm retained. Address506 Home/selectedWork;AndroidBack507 settings. Payment508 selectedPaytm;Back509 same settings. No preferences altered.
Eleven reviewed captures;five narrow action passes;PD056 updated. Cumulative509physicalcaptures plusPDF/render=511evidence rows;337actionrecords;56publicmappings;15distinctdefects. No new defect. Existing11blocker groups and explicit history-preservation prerequisite remain. Monthly repeated Add/existing quantity/partial failure not qualified by empty-cart success. Settings Order notifications switch(row and thumb),Shopping alerts,Saved/Recent nested returns,Seller messages,Privacy preferences,lower Help and settings dismissal remain to test. OS notification permission and in-app order-alert preference are distinct;displayed in-app On is not notification delivery proof. Device ends Shopping settings with original data retained and emptycart. Full audit remains incomplete. No implementation,APK,backend,OPPO,policy work or real messages.

## Round 48 - all four Shopping alert destinations and returns
Previous round made concrete progress:monthlycart/settings returns sealed at159ae522a6fec0eaa18c6f37d3d62e692be3d483. Gate passes. Shopping alerts510 has four entries. Delivery511 opens exactMS-NEW-09 LastKnown tracking;Back512 restores sheet. Registered another D003 occurrence:alert Updated recently/Delivery12min lacks destination freshness qualification. After-delivery513 opens deliveredMS-240741 tracking;Back514 restores. Price515 opensFresh tomatoes500g INR37;Back516 restores. NewShopoffers517 incorrectly opens ordinary Scheduled Shop grid with Shopselected;Back518 restores. Registered RV6-D016 before moving on. Return/refund provider eligibility and actual price-update event not qualified;correct historical destination is a narrow navigation pass.
PD057 maps review alert producer,record identifiers,authority,publication/freshness and navigation. Current review snapshot constructs first-active/first-delivered/first-listed-SKU plusstaticoffers and fixedUpdated labels. Requires authoritative customer grants,event timestamps,expiry and revisions. Failed guessed shell filename read recovered using bounded file search;actual screen source1811 confirms normal _openOffers sets localactive state and same URI. Exact pushed-route initialization cause not yet proven;no source change.
Nine reviewed captures;five actionrecords(three narrowpasses,twofailures including existingD003 occurrence);one newmapping. Cumulative518physicalcaptures plusPDF/render=520evidence rows;342actionrecords;57publicmappings;16distinctdefects. Full audit incomplete;remaining settings switch/Saved/Recent/messages/privacy/help and conditional basket cases remain. Device ends alerts sheet over Shopping settings;cartempty;originalSaved1/address/Paytm retained;tomato visit may reorder history. No implementation,APK,backend,OPPO,policy change or real messages/transactions.

## Round 49 - settings notifications and nested saved/history returns
Previous round made concrete progress:alert navigation/freshness sealed atb76325d5064f46a12f8c1588c2da92461ea7f80c. Current gate passes. AlertBack519 returns settings. Switch520 pauses Order notifications;rowtap521 restores originalOn. Source session9397 reviewDataEnabled only changes in-memory flag/notice;non-review adapter has busy/availability/error paths. PD038 augmented;no persisted consent/provider or OS receipt pass claimed.
Saved522 originalwheat5kg INR279;product523;AndroidBack524 exactSaved sheet over settings. Back then Recentlyviewed525 shows8;product526 exactwheat with BacktoRecentlyviewed;AndroidBack527 restores history;secondBack528 settings. OriginalSaved1/Work/Paytm retained;cartempty. No history clear or saved deletion. Viewing wheat updates recency normally.
Ten reviewed captures;five narrow action passes;one mapping update. Cumulative528physicalcaptures plusPDF/render=530evidence rows;347actionrecords;57publicmappings;16distinctdefects. No new defect. Seller messages,privacy/help,settings dismissal,monthly conditional quantities/partial failure and remaining source/action reconciliation still pending. Full audit incomplete;device ends Shopping settings. No implementation,APK,backend,OPPO,policy work or real messages/transactions.

## Round 50 - settings shared routes and Shopping help guidance
Previous round made concrete progress:settings nested returns sealed ata31de8a5201486179b2f1e2760f7cc1f78e986ee. Current gate passes. Seller messages529 opens ShopChat Business filter,MetroWholesalePartner fixture;AndroidBack530 restores settings. No thread opened/message sent/draft edited. Privacy531 shared preferencesEnglish/Jodhpur;Back532 settings. Detailed shared preference controls were covered earlier;new origin/return qualified only. Scroll533 Security534 shows account-required sign-in andApppermissions;Back535 restores lower settings scroll. No authentication/provider/permission changes.
Help536 opens Shoppinghelp with order list and search. Beforeorder537 expands readable pack/price/MOQ/delivery/seller guidance;Delivery/returns538 expands order-specific available-help guidance. Source catalogue4507-4585 maps businessChat return/app/buy;preferences;security andhelp with retained scroll controller. Help order search,matching/empty/keyboard,order destinations and returns,collapse/dismissal remain pending. No full Help completion inferred.
Ten reviewed captures;six narrow passes. Cumulative538physicalcaptures plusPDF/render=540evidence rows;353actionrecords;57publicmappings;16distinctdefects. No new defect. Device ends Shoppinghelp with both guidance sections expanded;cartempty;originalSaved1/Work/Paytm/English/Jodhpur andalertsOn retained. Full audit incomplete;conditional monthly/history/address/media/provider cases and source/action/data reconciliation remain. No implementation,APK,backend,OPPO,policy work or real transactions/messages.

## Round 51 - Help order search and keyboard return
Previous round made concrete progress:shared routes/help guidance sealed at040f15b694ab047401a91568fd33dec8c9effbdd. Current gate passes. ExactShop query539 MS-NEW-09 yields correctresult with keyboard. Tap540 opens correcttracking and hideskeyboard;AndroidBack541 restores query/result and keyboard. Clear then nonexistentquery542 gives readable No matching orders recovery. Replace543 PO-NEW-01 ->544 correctWholesale tracking ->Back545 retainedquery/result. ExistingD008 crowded Retailerbusiness label remains visible544;not a new defect. Clear andAndroidBack546 restores orderlist and hideskeyboard while Help remainsopen.
PD058 maps Help search over session Shop/Wholesale orders;trim/lowercase ID,purchaseID,title,itemSummary,partner,currentproduct andhistorical line matching. Device qualifies ID andno-match paths only. Producer authorization,history retention andquery/scroll return requirements explicit;no backend grant test inferred. Four narrowpasses;eight reviewedcaptures;one mapping. Cumulative546physicalcaptures plusPDF/render=548evidence;357actions;58mappings;16distinctdefects. No new defect.
Device ends Help with emptyquery,keyboardhidden,both guidance expanded. Originalcartempty/Saved1/Work/Paytm/alertsOn unchanged. Seller/product/purchase-ID matching,Help collapse/dismissal,conditional monthly/history/address/provider/media and complete source/action/data reconciliation remain. Full goal active,incomplete. No implementation,APK,backend,OPPO,policy work or real transactions/messages.

## Round 52 - Help seller/product matching and dismissal
Previous round made concrete progress:Help ID searches sealed at7aa72a1aaf9b8eaa3b46fef61c45e9c035f5a4e1. Gate passes. SellerqueryRajasthan547 shows expectedPO-NEW-01;producttomatoes548 showsknownMS-NEW-09. These prove known matching examples,not complete result-set correctness. Clearedquery/hidkeyboard andcollapsedbothguidance549;HelpX550 returns retainedlower settingsscroll;SettingsAndroidBack551 returnsScheduledShop Saved1 andemptycart. PD058 updated. No original customerdata modified.
Five reviewedcaptures;five narrowpasses. Cumulative551physicalcaptures plusPDF/render=553evidence;362actions;58mappings;16distinctdefects. No newdefect. Bounded disposition reconciliation beforeappend showed357rows with294device_pass,11blocked_test_data and provider/auth/source dispositions. Absence of unverified-status rows is NOT complete coverage:remaining fields and source inventory still contain untested descendants. Do not report zero pending from that status filter.
Next concrete gaps:monthly repeatedAdd and above/below target quantities with cleanuptest;history normalAdd/scroll;isolatedaddress edit-save/relaunch;Help alternative dismissal/purchase-ID edge;complete source action/public-field reconciliation and accessibility coverage limits. Existing provider/media/confirmation/recovery fixtures remain explicitly blocked. Scope-state/HANDOFF completion audit still required. Full goal active,incomplete. Device ends ScheduledShop;originalSaved1/Work/Paytm/alertsOn retained;no APK/implementation/backend/OPPO/policy work or realtransaction/message.

## Round 53 - Recently viewed available Add and cart cleanup

Physical Redmi captures 552-559 reviewed. Capture 554 is a transition, not the settled result; 555 confirms Recently viewed. Available wheat Add changes to Added (556), retains exactly one 5 kg SKU 2 from Mool Market 000001 at Rs279 in catalogue/cart (557-558). Cart minus removes only this isolated addition and returns to Scheduled Shop with empty cart and original Saved1 (559). Three narrow action passes; no new defect and no defect closure. D015 remains open for unavailable/closed-store Add behavior. Original addresses and saved product were not edited.

Totals: 559 physical captures, 561 evidence rows including PDF/render, 365 action rows, 58 public-data mappings, 16 distinct defects. These are cumulative evidence counts, not an exhaustive coverage denominator. Monthly repeat/quantity tests, other remaining journeys and final field/action reconciliation remain pending. No product code, APK or policy changed.

## Round 54 - Monthly basket target quantities and repeat Add

Captures 560-570 inspected on Redmi. Empty Add gives 21 packs/Rs5145. Wheat increased from2 to3 and oil decreased from2 to1 yields 21packs/Rs4589. Re-Add restores only missing oil, preserves wheat3, and yields22packs/Rs5424. A further Add leaves this unchanged; cart verifies12products, wheat3/Rs837 and oil2/Rs1670. Confirmed removal clears only the isolated22Shopitems. Saved1 remains; original addresses untouched. Five device action passes; no new defect or closure.

570 physical captures;572 evidence rows including PDF/render;370 action rows;58 data mappings;16 distinct defects. Complete action/data inventory remains unfinished. Partial basket failure requires an appropriate unavailable/revision fixture; host logic is not device qualification. No new APK or product changes.

## Round 55 - Remaining price caps and filter cancellation

Physical captures571-580 reviewed. On the finite six-product monthly Scheduled set: cap250 returns notebooks210/milk66/eggs89; cap500 adds wheat279 and excludes oil835/ghee625; cap1000 restores all6. Clear without Apply then close X retains cap1000 on reopen. Clear then swipe dismissal also retains cap1000 on reopen. Clear plus Apply removes filter badge and restores original six-product monthly view. Cart remains empty;Saved1. Six narrow device passes; no new defect or closure. No inference about equality boundary or provider pagination.

Six older remaining notes reconciled to explicit round54/55 evidence; historical actions/evidence preserved. 580 physical captures;582 evidence rows;376 action rows;58 public-data mappings;16 defects. Source/action completeness reconciliation and other reachable pending cases remain open. No product/policy/APK changes.

## Round 56 - Evidence reconciliation and explicit incomplete scope checkpoint

No new device action or product change. Twelve older remaining notes reconciled to exact later action rows: Bulk MOQ removal; invoice save/cancel/content/physical reopen; saved clear; monthly/tools; Recently viewed Add; settings Help and search/collapse/dismissal. Original observations and evidence references preserved. Verified 53 cited artifact files against EVIDENCE.csv: zero missing or hash mismatches. No pass upgraded beyond the later evidence; provider authority, process persistence, alternate origins and conditional failures remain explicit.

Created scope-state.json as an in-progress requirement checkpoint. Source-derived action inventory and public-field completeness remain false/unproven; final HANDOFF.md remains uncreated. This is audit evidence, not policy or a new scope. Counts unchanged:580 physical captures;582 evidence rows;376 action rows;58 public-data mappings;16 defects. Next work remains physical qualification of reachable gaps and full source/action/data reconciliation.

## Round 57 - Isolated address edit/save and task resume

Captures581-598 physically reviewed. Original Home/Work recorded584. Created Other place RedmiAudit57/ReviewOnly57/Basni342005 using existing fixture phone, selected and reopened588. Edited recipient to RedmiAudit57Edited, saved, and verified same selected entry593. Android Home followed by explicit existing-task bring-to-front retains edited entry/chooser594; this is not process-death qualification. Removed only isolated address with confirmation595; original two records remain597;Work reselected and verified598. Cart untouched/empty;Saved1. Four narrow device passes and one data observation; no new defect/closure. Blank optional landmark becomes literal No nearby landmark on edit590, matching views15136; mapped as current behavior rather than invented provider data.

Counts598 physical captures;600 evidence rows;381 action rows;58 public-data mappings;16 distinct defects. Address process-death/disk persistence and authoritative geography remain unqualified. Complete source/action/data enumeration remains open. No product, policy or APK changes.

## Round 58 - Variant selection and exact cart retention

Physical captures599-608 reviewed. Canonical milk1L66 opened from monthly Scheduled. Selecting2x1L shows128/64perL and correct supplier602;selected option603;repeat tap leaves state unchanged604. Add then switch display back1L:display66/Add606 while cart preserves one2x1L128 Family Dairy and Bake607. Removed isolated line;empty monthly view and Saved1 restored608. Four narrow device passes;no new defect/closure. Wholesale/paged/unavailable variants and supplier-media association remain unqualified. Four old remaining notes reconciled to round12/20/23/58 evidence without broadening claims.

608 physical captures;610 evidence rows;385 action rows;58 public-data mappings;16 defects. Complete inventory and final handoff remain unfinished. No product/policy/APK changes.

## Round 59 - Wholesale filter differences and no-match recovery

Captures609-616 reviewed. Wholesale omits Pack size610, matching views13577 destination condition. Trade price bands2000/5000/10000 visible612. First band applied: visible first-page products all <=2000 at611;not full-pagination proof. Artifact611 was initially named empty from an unconfirmed expectation;it contains populated results and is NOT empty-result evidence. Clearing filter then searching zzredminomatch59 gives readable0products with keyboard613 and confirmed Wholesale state614. Refresh615 retains query/empty state;not provider completion proof. Clear query/confirm restores unfiltered Wholesale616,emptycart,Saved0. Four device passes and one observation;no new defect/closure.

616 physical captures;618 evidence rows;390 action rows;58 public-data mappings;16 defects. Full source/action/public-data completeness remains open;other trade price bands and provider pagination not qualified. No product/policy/APK changes.

## Round 60 - Remaining Wholesale price bands and paged sample

Physical captures617-625 reviewed. Original unfiltered Wholesale617. Applied5000 after explicit option read619:620 result434700000 and visible six prices below cap. Next page621 shows41-80 and six visible prices936/4200/2460/3650/2200/2790;reopened filter retains5000 at622. Applied10000 resets first page623,count494000000;reopen624 retains10000. Clear/Apply625 restores unfiltered first page,no badge,Saved0. No cart/address/saved mutations. Four narrow device passes;no new defect or closure. Full pagination, exact-price boundary, process-death persistence and authoritative offer revision remain unqualified.

625 physical captures;627 evidence rows;394 action rows;58 public-data mappings;16 distinct defects. Complete action/data inventory and final handoff remain unfinished. No product/policy/APK changes.

## Round 61 - Help Android Back and Wholesale origin

Physical captures626-630 reviewed. Wholesale tools opens Settings;lower scroll627. Help628 shows combined Shop/Wholesale orders. AndroidBack with keyboard hidden dismisses Help to identical Settings scroll629. SecondBack returns original Wholesale first page630,no filter badge,Saved0. Two narrow device passes;two stale Help pending notes reconciled. No new defect/closure;no data mutations, messages, transactions, force-stop or process-death qualification.

630 physical captures;632 evidence rows;396 action rows;58 public-data mappings;16 defects. Audit remains incomplete. Source read failed once under platform-default cp1252;bounded UTF-8 retry succeeded under standing read-recovery authority;no source mutation.

## Round 62 - Early coverage residual reconciliation

Reconciled nine early remaining notes against later recorded Store/cart/quantity/order/Help evidence. Original observations and dispositions unchanged. Distinguish multi-product reordered cart quantities from historical line identity:round25 does not qualify historical identity. Mixed two-nonempty carts,Wholesale upper quantity bounds,Store-origin restoration,group controls,process-death and provider truth remain unqualified. Verified57 referenced artifact files against EVIDENCE.csv hashes;zero missing/mismatches. No new device actions,captures,passes,defects or closures.

Counts unchanged630 physical captures;632 evidence rows;396 action rows;58 public mappings;16 defects. First130 early residual notes reviewed in bounded pages;later residual reconciliation and complete source-derived action inventory still open.

## Round 63 - Two nonempty carts and scoped removal

Physical captures631-644 reviewed. Added only isolated Wholesale tomatoes10kg2packs1160 then Shop wheat5kg1pack279;combined1439. Each cart shows exact own line635/636. Trade increment3 makes1740 and combined2019;Shop remains1/279 at637. Shop Address review638 carries1/279;Back/trade639 retained3/1740. Trade Address review640 carries3/1740. Original Work selection unchanged. Scoped clear641 discloses3Wholesale removed and1other retained;AndroidBack642 preservesboth. ConfirmingWholesale removal643 leavesShop1/279. Removed testShopline644;emptycart,Saved1,ScheduledShop restored. Seven narrow device passes;no new defects/closures. No payment,order placement,messages,address edits or product changes. Process-death/account switching/provider authority remain unqualified.

644 physical captures;646 evidence rows;403 action rows;58 public mappings;16 defects. Three old pending notes reconciled. Residual notes131-195 read;complete source inventory and final handoff still open.

## Round 64 - Saved no-match recovery and module return

Physical captures645-650 reviewed. Original savedwheat279/count1. Searchzzsavednomatch64 shows generic editing no-match646;confirm647 correctly shows No matching saved products and explains records still saved. Clear search and filters648 restores exact wheat/count1 with emptyquery. AndroidBack649 goes modulechooser,not catalogue;Shop reentry650 retains Saved/Scheduled and original item. Three narrow device passes and one navigation observation;no process-death claim,no new defect/closure. No original saved item,cart,address or draft mutation.

Five residual notes reconciled against round32/33/43/58/64. Residual rows196-260 reviewed;later reconciliation remains open.650 physical captures;652 evidence rows;407 actions;58 public mappings;16 defects. Source/action/data completeness and final handoff still incomplete.

## Round 65 - Residual ledger review and delivery-control data contract

Reviewed remaining residual rows261-407,completing this pass over the current incremental ledger. Reconciled11 stale notes with later evidence;no original disposition or observation upgraded. This does not establish source-inventory completeness. Added PD-059 for Keep/Hide/Minimize/arrival sound:customer intent,per-order widget state,provider status ownership,foreground operation,timeout/failure behavior and lifecycle limits. Source read anchors screen685-818,1306-1371,1584-1604,2790-2831. Actual arrival audio and runtime identity isolation remain unqualified;no new device action or defect.

650 physical captures;652 evidence rows;407 action rows;59 public-data mappings;16 defects. Next:source-derived missing action inventory and remaining real device cases,including lifecycle,Store categories/paging,Offers controls and address/GST validation. Provider/fixture blockers remain explicit. No product/policy/APK changes;final handoff incomplete.

## Round 66 - Source action inventory: delivery exceptions and balance payment

Enumerated top-level screen/catalogue/views classes and sheet entry points as source inventory input,not coverage proof. Inspected views10202-10500 conditional cards and session adapter guards. Public journey_router253 constructs default session;balancePaymentAdapter/deliveryExceptionAdapter nullable and not wired. Added8 explicit blocked-provider actions SOURCE-ROUND66-01..08;B-012/B-013 prerequisite records;PD-060/061 field/authority/lifecycle maps. Actual reschedule,proof dispute,payment and reconciliation not executed. No new device pass,capture or defect. Initial BLOCKERS read hit cp1252 decode failure before write;bounded UTF-8 retry succeeded under standing recovery authority.

650 physical captures;652 evidence rows;415 action rows;61 public mappings;16 defects. Source enumeration remains incomplete beyond these inspected controls. Remaining source families and physical reachable cases still require qualification. No product/policy/APK changes.

## Round 67 - Offers promotion boundary and Add/cart return

Physical651-659 reviewed. Nextpromotion652 showsmanufacturer580/10kgMOQ2;Previous653 restoresretail37/500g;firstboundarytap654unchanged. Add655creates1/37;cart656exacttomatoSKU1/500g/MoolMarket000001. Back657restoresOffers andquantity. Removedtestline;658Addrestored/no cart. FooterRefresh659settledtop/firstpromotion;notproviderrevisionpass. Fivepasses andoneobservation;no newdefect/closure. Lastpromotionboundary andcataloguepagecontrols remainunqualified.

659 physicalcaptures;661 evidencerows;421 actionrows;61 publicmappings;16 defects. No originalsaved/addressmutation;cartempty. Completeaudit remainsopen. Founder overnightstatus answered using Git timestampwindow10h24m:68commits throughd2ce7ecb at timeofquery;not duration/performance proof.

## Round 68 - collection-order conditional inventory

Source-only reconciliation of buy_v2_views.dart 10794-11250 expands the earlier capture275 signed-out collection boundary into eight explicit descendants in COLLECTION-ROUND68-01 through 08: return context, scan eligibility, close camera, QR reconciliation, lifecycle/account isolation, order help, purchased lines/receipt, and terminal/status transitions. All eight remain blocked_authentication, not device passes or new confirmed defects. An authorised authenticated non-live collection fixture and provider are needed; no real claim/payment/transaction was performed. Existing COLLECTION-ROUND18-05 remains the parent boundary, so row counts are not distinct defect counts.

429 action rows; 659 physical captures unchanged; 16 distinct confirmed defects unchanged. No product, device, APK or user-data mutation. Complete source-derived enumeration and final handoff remain unfinished.

## Round 69 - physical Offers category and product return

Redmi TG8HCYTGGQT885OF connected. Captures660-664 physically reviewed: Offers resumed660; category icon opened661; Dairy & bakery selected662 with paneer46 INR92/200g promotion and dairy results; View offer opened exact product663; Android Back retained dairy promotion/grid664. Three device passes, no new confirmed defect. No cart/address/saved edits or transaction. Product visit can update recent history. Provider price/trust claims are not qualified by fixture navigation.

432 action rows;349 device passes;664 physical captures;666 evidence rows;61 public mappings;16 distinct defects. All-category reset, remaining categories and terminal pagination remain pending; full audit and handoff incomplete.

## Round 70 - physical Offers category reset and page return

Captures665-670 reviewed. Selected Dairy highlighted665;All categories666 restores mixed grid while retaining an eligible paneer promotion. Footer667 Next loads noodles101/juice106/facewash111 and top scroll668. Footer669 Previous restores original tomato1/notebook6/chicken11 grid at lower scroll670 with Previous disabled. Three device passes;terminal page remains untested. No new defect or user cart/address/saved mutation.

Execution sequencing note: implementation-gate command yielded session55531; the category-open/capture command ran before its completion was collected. The same gate session was polled to exit0/pass before further actions. This was a sequencing error, not a product pass; subsequent dependent gate actions must await terminal success. No checker changes or bypass were made.

435 action rows;352 device passes;670 physical captures;672 evidence rows;61 public mappings;16 distinct defects. Full audit remains incomplete.

## Round 71 - collection field and authority mapping

PD-062 records exact purchased SKU/line/account/Store bindings, decimal quantity, INR minor amounts, opaque revision, server-time expiry, readiness/payment/matching distinctions, receipt and optional invoice fields. Sources: scan_and_pick_contract.dart195-318;buy_v2_session.dart3184-3294;buy_v2_views.dart10962-11242. These are source requirements, not authenticated-device or backend passes. Offers source383-462 confirms retained published-offers query/category and published promotion fields;terminal page still needs physical coverage. An initial read-only search included nonexistent features/scan_pick;bounded rg --files located features/work/scan_and_pick_contract.dart without mutation.

62 public-data rows;device/actions/defects unchanged from round70. No product edits or device actions. Full enumeration and handoff remain incomplete.

## Round 72 - Redmi Offers at 200 percent text

Original font_scale1.0 read before change;set2.0/readback2.0. Captures671-672 show two-column Offers cards, visible price/delivery/Add fit and wrapped promotion. Category sheet673 wraps visible labels with accessible close icon. Android Back dismissed;restore1.0/readback1.0;674 reviewed. Category illustration fallback icons at200 return to illustrations at1.0: observation ACCESS-ROUND72-02 pending source investigation, not yet confirmed defect. No cart/address/saved edits or transactions.

439 actions;355 device passes;674 captures;676 evidence rows;62 public mappings;16 confirmed defects. This is limited Offers accessibility coverage, not whole-module200 qualification. No process-death claim.

## Round 73 - illustration fallback reconciliation

ACCESS-ROUND72-02 source explanation: buy_v2_design.dart2044-2081 measures illustration-label words using current text scale and returns BuyV2ProductPhotoUnavailable when width or remaining height cannot fit. Lines2112-2126 expose product-specific unavailable semantics and crossed-image icon. This is consistent with671-672 and restored674;no evidence here of real supplier-photo failure. Observation retained, no new defect. Real supplier media and screen-reader output remain unverified. Initial catalogue read had a Python syntax error before any read/write;corrected bounded design-file read completed.

No device actions or product edits;all counters unchanged. Full audit remains active.

## Round 74 - public scanner reachability

Library-wide references show public Buy only declares scannerLauncher at buy_v2_screen.dart284/312;actual showBuyV2ProductScanner calls occur in Workspace dashboard11278/21635. SCANNER-ROUND74-01 lists unreachable public descendants explicitly;no Workspace navigation or product change. This is not a confirmed customer failure without a promised public entry. Collection camera remains separately authentication-blocked.

440 action rows;other counts unchanged. Source inventory and full audit remain incomplete.

## Round 75 - supplier-media conditional controls

Expanded B-008 into MEDIA-ROUND75-01 through08:gallery/count;pinch/pan/reset/reduced motion;video play/pause/replay;mute;seek;transcript/dismiss;Retry;variant/gallery shrink and background pause. Exact source pointers retained. Each remains blocked_test_data because supplier mediaAssets are absent in the current cohort;illustrations are not substitutes for decoding/playback/variant binding tests. No new defect, asset injection or device action.

448 action rows;19 blocked_test_data rows include parent/descendant coverage and are not19 unique defects. Other counts unchanged;full audit incomplete.

## Round 76 - expired Offers recovery and Orders large text

675 naturally expired Offers;Refresh676 restored fixture grid. Original font1.0 read;set2.0/read2.0.677 was transition only;settled678 shows readable order card and stacked controls. Track679 correct MS-NEW-09 with last-known/live-unavailable copy readable. Android Back;restore1.0/read1.0;680 Orders12active2delivered retained. No cart/address/order mutation or live transaction. Four narrow passes;lower tracking and other orders at200 remain pending.

452 actions;359 device passes;680 captures;682 evidence rows;62 mappings;16 confirmed defects. No full-module qualification claim.

## Round 77 - supplier publication requirements reconciliation

PD-041 strengthened from buy_v2_content_contracts.dart590-648:HTTPS host without userinfo/fragment;asset/semantic labels;workspace revision Store canonical-product and exact-SKU binding;procurement supplier workspace match when grant exists;video poster metadata and nonempty transcript;deduplicated asset IDs capped10. Existing format/size requirements retained. These supplied-metadata checks do not prove bytes were inspected or backend publication enforced. No new device pass or defect. All counts unchanged;full audit remains incomplete.

## Round 78 - GST coverage reconciliation

Reconciled CHECKOUT-005 and007 residuals with091-097 and later177. Empty/short identifier checks are covered;valid details, checksum/state-code cases, reuse/remove and lifecycle remain unqualified. Existing host fixture located in buy_v2_gst_session_continuity_test.dart22-24 provides a local-only test profile;its existence is not a Redmi or tax-authority pass. Initial shell wildcard path search was invalid;bounded rg -g search recovered without mutation. No device actions;no new defect;counts unchanged. Next physical GST checks must preserve original data and avoid checkout submission.

## Round 79 - GST valid-form path and saved-chip defect

681-699 reviewed. Isolated wheat1/279 added;Work/Paytm retained684-686. GST enabled687;form688 blank. Initial injected name689 contained literal percent20;corrected before submission690 to AuditRedmiTest with existing host-fixture identifier and AuditTestAddressJodhpur. Frontend accepted691;settled692 confirms unreadable selected saved-profile chip RV6-D017. Registered before further test actions. Removal693 named exact test profile;694 profile/current details cleared. GST off695. Rapid Back sequence ended at Address696 and is not individual-step evidence;explicit Cart697,remove only wheat;698 transition,699 settled empty/Saved1. No order/payment/message.

457 action rows;363 device passes;699 captures;701 evidence rows;62 mappings;17 confirmed distinct defects. Temporary reuse beyond initial save, multiple profiles, cancellation and lifecycle remain pending. Full audit remains incomplete.

## Round 80 - GST defect source correlation and field reconciliation

D017 linked to Buy InputChip6158-6175 and shared theme174-185 navy selected background/label. Source correlation only;no theme or product edit. PD023 updated for actual acceptance/removal/off captures691/694/695 while retaining invoice/lifecycle/reuse limits. Device and defect counts unchanged. Audit remains incomplete.


## Round 81 - lower tracking and management at enlarged text

Revalidated clean HEAD cc9e4b07899b7e3b9ac0003dc3cb5a3276cfe382 and implementation gate exit0. Previous combined tool output was truncated; existing capture700 was recovered and visually reviewed without overwriting it. Live701 confirmed Orders retained. Opened MS-NEW-09; original font read1.0 then set2.0. Lower tracking702-703 shows wrapping delivery details and readable timeline/action controls. Items704 retains order identity and pack; Android Back705 retains tracking scroll. Manage706 and Cancel choice707 show readable identity and blank reason with Submit disabled. No request submitted. Android Back dismissed; font restored and read1.0;708 confirms retained tracking, alerts ON and normal footer. Invoice below the captured200-percent scroll and reason menu remain unqualified by this round.

Four narrow device passes; no new confirmed defect. 461 action rows,367 device passes,708 recorded captures,710 evidence rows,62 mappings,17 distinct confirmed defects. Source/action inventory and full audit remain incomplete. No product change, new APK, message, payment, order mutation or OPPO action.


## Round 82 - cancellation reasons and conditional resolution inventory

Implementation gate passed before this continuation. 709 reopened Manage at normal text;Cancel selected then font2.0.710 empty reason;711 four readable reasons;712 selected Delivery time does not work fully wraps and Submit enables. Submit was not pressed. Android Back dismissed;original font restored/read1.0;713 retained tracking and packing state. Three narrow device passes. No request, order change or new defect.

Read resolution source11946-12265 and reconciled original RESOLUTION001-012. Added four explicit B006 conditional descendants:positive item quantities;empty-item submission guard;type/refresh selection reset;accepted/rejected/busy/failure outcomes. Source evidence is not device qualification. Existing normal-text reason selection and unavailable delivered branches remain preserved. Dropdown Back, remaining reason selections and reopen draft state still require coverage.

468 action rows;370 device passes;713 captures;715 evidence rows;62 public-data rows;17 distinct confirmed defects. Full source/action inventory and audit remain incomplete.


## Round 83 - complete local cancellation selection gaps

Implementation gate passed. Reopen714 clears prior choice;Cancel715 starts empty reason with disabled Submit. Open dropdown716;Android Back717 closes dropdown only and retains empty form. Ordered by mistake718 and Need to change items719 select correctly and enable Submit. Android Back720 dismisses without request;packing tracking retained. Font unchanged1.0;no request or user-data mutation.

Four narrow passes. Together with144(change address) and712(delivery time),all four reason selections are now observed. Reconciled five older remaining notes without changing original evidence or claiming all variants at200percent. Real submission,provider outcomes and process death remain unqualified. No new defect.

472 action rows;374 device passes;720 captures;722 evidence rows;62 public-data mappings;17 distinct confirmed defects. Full audit and source inventory remain incomplete.


## Round 84 - reconcile superseded coverage notes

Read all75 notes containing pending in three bounded pages, then compared relevant Bulk/filter/Store/coupon/GST/address/order/security evidence rows. Reconciled12 original remaining notes against later captures. No original result, disposition or capture changed;no new device pass. Kept checkout-specific new-address propagation separate from shared settings-editor checks;kept positive return eligibility and provider outcomes unqualified. Corrected draft wording to distinguish cancelled invoice save135 from exported PDF480 before sealing.

This removes stale blanket pending descriptions without declaring whole journeys complete. Counts unchanged:472 actions,374 device passes,720 captures,722 evidence rows,62 mappings,17 distinct confirmed defects. Remaining priority:source-derived full action inventory;Store/category and terminal pagination;conditional data/provider gaps;remaining validation and lifecycle coverage. Full audit remains incomplete.


## Round 85 - Store pagination category and return

Implementation gate passed.721 is transition after Shop tap;722 settled Scheduled catalogue Saved1. Product723 opens from card;Visit724 and Browse725 reach full Mool Market000001 catalogue. Next726 displays41-80. Categories727;Oil728 resets1-40 of238. Five sequential Next actions reach final201-238 in729;intermediate pages not individually captured. Disabled Next730 leaves final page unchanged. Upper-row horizontal swipe731 reveals further products, so initial six visible cards are not all page contents. Android Back732 restores preview;Browse733 retains Oil category,final page and upper-row scroll. No cart/order/data mutation.

Five narrow passes;no new defect.477 action rows;379 device passes;733 captures;735 evidence rows;62 mappings;17 distinct defects. Other categories,final-page Previous,horizontal endpoints and process relaunch remain unqualified. Full audit/source inventory incomplete.


## Round 86 - catalogue public-data contract

Completed PD063 from exact query/page/source contracts and Pager429-688,plus Store binding and scroll retention. Records backend query/snapshot/cursor obligations,identifiers,optional total,cache bounds,missing/error behavior,query/refresh reset and publication/withdrawal limits. Source checks reject inconsistent pages but do not qualify live provider enforcement. Device725-733 remains narrow fixture navigation evidence. No device action,new defect or implementation in this round.

63 public-data mappings;other counts unchanged. Complete user-journey denominator still unavailable:source/action inventory incomplete. Pending work must not be calculated by subtracting passes from action rows because records include repeated checks,observations and conditional descendants. Full audit remains open.


## Round 87 - verified Store Previous and Refresh

Implementation gate passed. First action used older coordinates before a fresh screen read;734 unexpectedly showed tomato product rather than prior Oil catalogue. Cause unknown;this is not a Previous pass or confirmed defect. Future continuation must capture current screen before a navigation tap. Used visible Back-to-Store735 then Browse736 to establish final Oil page. Previous737 displays161-200 of238. Refresh738 resets1-40 with Oil retained. No request,payment,cart or settings change. Original initial-state ambiguity retained,not overwritten.

Two narrow passes;reconciled round85 Previous residuals.479 action rows;381 device passes;738 captures;740 evidence rows;63 mappings;17 distinct defects. Full audit remains incomplete.

## Round 88 - source interaction candidate index

This is a lexical discovery queue for semantic reconciliation, not a count of user journeys or pending device tests. It includes reusable/internal callbacks and can omit gestures expressed through other APIs. No row is a pass and inventoryComplete remains false. Every candidate must be checked for public reachability, duplicate/shared behavior, existing evidence and missing descendants before a complete denominator is claimed. Existing 479 action records are not subtracted from these candidates. No device actions or new defects in this round.

Source hashes bind the following index to the inspected files:

| Source under apps/mobile/lib/ui_v2/buy | SHA-256 | Candidates |
|---|---|---|
| buy_v2_catalogue.dart | 84FEF1B2C1D81178B0F136235298E239963C07323D149E60B3EDB5E0C879C259 | 136 |
| buy_v2_design.dart | 4EA0F4877634CF4250C031B1EDC7739D5AB4BA818FC879A519036F56B3ED719F | 2 |
| buy_v2_invoice.dart | 9F8FD030974B6AD35682B891A3F20D9C9661A80B9F2F411E0CD5221B9A7DC07A | 2 |
| buy_v2_product_video.dart | 5AEFFF18874EF89A108EEDE9A24CA5D5215F0564572205112F0AB306A5703DA7 | 7 |
| buy_v2_scanner.dart | 251C238D8BD807EDB594EE2E862A064036B71E3D92431D51EF9A6B2F8BC4C113 | 15 |
| buy_v2_screen.dart | 7BE1D12EE7CA2ACB96B67B14EC02CAD0DCB25D613A07AF4B0473AE323EB9C0B7 | 32 |
| buy_v2_shop_chat.dart | CFA29EB206A9368F9E6A129EA94CC5EB128FD047F82EC20ACDC62504A155DACC | 71 |
| buy_v2_views.dart | 4787279F1A5064000412846207FAABF3778D318EDB7881F5E90989670398F9D4 | 262 |

| Candidate | Source:line | Enclosing declaration | Callback | Reconciliation |
|---|---|---|---|---|
| SRC-0001 | buy_v2_catalogue.dart:320 | _BuyV2OffersViewState | onTap | alternate finite/live-source category branch; not qualified by paged review captures; conditional source path unverified |
| SRC-0002 | buy_v2_catalogue.dart:436 | _PagedPublishedOffersViewState | onTap | device_pass OFFERS-005 and ROUND69-01; paged category entry |
| SRC-0003 | buy_v2_catalogue.dart:493 | _chooseOffersCategory | onPressed | device_pass OFFERS-ROUND99-01; Close categories retains selection/promotion |
| SRC-0004 | buy_v2_catalogue.dart:502 | _chooseOffersCategory | onTap | device_pass OFFERS-008 and ROUND70-01; All categories |
| SRC-0005 | buy_v2_catalogue.dart:509 | _chooseOffersCategory | onTap | device_pass OFFERS-005 and ROUND69-01 for Ground spices and Dairy; other category values not inferred |
| SRC-0006 | buy_v2_catalogue.dart:554 | _OffersCategoryControl | onTap | forwarder to SRC-0001/0002; same category entry, not additional journey |
| SRC-0007 | buy_v2_catalogue.dart:633 | _PublishedOfferPromotionState | onTap | device_pass OFFERS-ROUND99-02/03; promotion text opens matching product and Back retains promotion |
| SRC-0008 | buy_v2_catalogue.dart:679 | _PublishedOfferPromotionState | onPressed | device_pass OFFERS-ROUND67-01/02; Previous and first boundary |
| SRC-0009 | buy_v2_catalogue.dart:685 | _PublishedOfferPromotionState | onPressed | device_pass OFFERS-002/ROUND67-01 Next and ROUND149-01 final loaded promotion disabled/stable; original paneer46 restored; other pages/provider/accessibility not inferred |
| SRC-0010 | buy_v2_catalogue.dart:703 | _PublishedOfferPromotionState | onPressed | device_pass OFFERS-003/004 and ROUND69-02/03; View offer and Back |
| SRC-0011 | buy_v2_catalogue.dart:764 | _LiveOffersState | onPressed | blocked_provider; live source Retry/loading/offline recovery not qualified by fixture refresh |
| SRC-0012 | buy_v2_catalogue.dart:823 | _OffersAvailabilityState | onPressed | blocked_provider; unavailable catalogue retryCommerce recovery not qualified by fixture refresh |
| SRC-0013 | buy_v2_catalogue.dart:1350 | _CataloguePageControls | onPressed | forwarded Previous; OFFERS-ROUND70-03 retained; PAGER-ROUND161-01/02 Shop and Wholesale first-page disabled boundary; remaining parent/conditional cases separate |
| SRC-0014 | buy_v2_catalogue.dart:1356 | _CataloguePageControls | onPressed | forwarded Next; CAT-002, WHOLESALE-ROUND60-02, OFFERS-ROUND70-02; final boundaries not inferred |
| SRC-0015 | buy_v2_catalogue.dart:1362 | _CataloguePageControls | onPressed | forwarded Refresh; PAGER-ROUND161-01/02 Shop and Wholesale review-data UI retains products/mode/saved state; live revision and failed-fetch recovery unqualified; OFFERS-ROUND67-06 remains observation |
| SRC-0016 | buy_v2_catalogue.dart:1370 | _CataloguePageControls | onPressed | device_pass OFFERS-ROUND148-01; exact Offers footer location button opens area and X retains page/scroll; source431 enables showAreaControl; other parents and provider selection not inferred |
| SRC-0017 | buy_v2_catalogue.dart:1456 | _CataloguePageNotice | onPressed | OFFERS-ROUND106-01 changed/expired notice Refresh restores review listings; other notice/provider-error branches remain unverified |
| SRC-0018 | buy_v2_catalogue.dart:1574 | showBuyV2CatalogueArea | onPressed | AREA-003 query Retry and AREA-ROUND100-04 current-location Retry UI; positive recovery B-001 |
| SRC-0019 | buy_v2_catalogue.dart:1589 | showBuyV2CatalogueArea | onPressed | device_pass AREA-ROUND100-05; X closes failure sheet and retains Offers |
| SRC-0020 | buy_v2_catalogue.dart:1602 | showBuyV2CatalogueArea | onChanged | AREA-002 query input; lookup success B-001; debounce/race/80-char boundary unverified |
| SRC-0021 | buy_v2_catalogue.dart:1621 | showBuyV2CatalogueArea | onSubmitted | device_pass AREA-ROUND142-01 one-character Enter after shortening failed query; two-character explicit submission and positive provider recovery remain unqualified |
| SRC-0022 | buy_v2_catalogue.dart:1629 | showBuyV2CatalogueArea | onPressed | blocked_provider B-001 AREA-ROUND100-03; current location yields visible unavailable message; no success/permission branch pass |
| SRC-0023 | buy_v2_catalogue.dart:1642 | showBuyV2CatalogueArea | onSelected | device_pass AREA-ROUND100-02; regional draft chip; applied serviceability not inferred |
| SRC-0024 | buy_v2_catalogue.dart:1647 | showBuyV2CatalogueArea | onSelected | device_pass AREA-ROUND100-01; national draft chip; applied serviceability not inferred |
| SRC-0025 | buy_v2_catalogue.dart:1699 | showBuyV2CatalogueArea | onTap | blocked_provider B-001; selecting resolved provider area including rejection feedback unverified |
| SRC-0026 | buy_v2_catalogue.dart:1723 | showBuyV2CatalogueArea | onTap | round159 AREA-ROUND159-01 Any area1090-1091 restores original supplier000001 Saved1 emptycart after Jaipur selection;provider coverage separate. |
| SRC-0027 | buy_v2_catalogue.dart:1735 | showBuyV2CatalogueArea | onTap | round159 Jaipur1087-1089 applies supplier000002 and search label Jaipur;reopen1090 lacks selected-city indicator RV6-D022. Seed selection only;Google provider and national coverage unqualified. |
| SRC-0028 | buy_v2_catalogue.dart:1943 | _CatalogueSaleTypeSelector | onHorizontalDragEnd | device_pass CAT-ROUND146-01 Shop and WHOLESALE-ROUND147-01 Wholesale/Bulk bidirectional gestures; threshold/accessibility/relaunch unqualified |
| SRC-0029 | buy_v2_catalogue.dart:2014 | _CatalogueSaleTypeSelector | onTap | Shop pointer evidence retained; WHOLESALE-ROUND160-01 Bulk tap and Shop detour return; Wholesale restored; process death separate |
| SRC-0030 | buy_v2_catalogue.dart:2062 | _CatalogueSaleSegment | onTap | Semantics onTap for same sale-mode action; screen-reader activation unverified; not extra pointer pass |
| SRC-0031 | buy_v2_catalogue.dart:2066 | _CatalogueSaleSegment | onTap | InkWell forwarder to SRC-0029; same physical sale-mode tap |
| SRC-0032 | buy_v2_catalogue.dart:2263 | BuyV2ShoppingIntentBar | onPressed | round156 MONTHLY-ROUND156-02: Monthly basket banner X1078-1079 clears intent and restores ordinary paged Scheduled Shop Saved1 emptycart. Other intents and process death separate. |
| SRC-0033 | buy_v2_catalogue.dart:2347 | _CatalogueAccountReturn | onTap | round157 source distinction: header screen1076 uses _openBuyProfile958-970/global panel, seen1057; it does not establish legacy Buy account-child return. session9489 requires _accountChildReturnActive; alternate entry remains unverified, not authenticated-device pass. |
| SRC-0034 | buy_v2_catalogue.dart:2631 | _CatalogueStoreMatchesState | onTap | round157 STORE-ROUND157-01/02: search Mool opens correct Stores000001 and000041;Back retains query, keyboard and pages1-40/41-80. Null preview-product/provider branch unqualified. Distinct from D018 product-search return. |
| SRC-0035 | buy_v2_catalogue.dart:2768 | _SearchReadyState | onPressed | Clear recent searches; excluded from destructive testing to preserve original history; not device pass |
| SRC-0036 | buy_v2_catalogue.dart:2785 | _SearchReadyState | onTap | round152 SEARCH-ROUND152-01: recent milk replay1046-1047 and keyboard Back1048 retain query/results; active-query clear1049 preserves history. Default pointer path qualified; product return and process death separate. |
| SRC-0037 | buy_v2_catalogue.dart:2844 | _SearchReadyState | onTap | round152 SEARCH-ROUND152-02: Fresh tomatoes suggestion1049 submits exact query1050; Back1051 retains it; Quick1052 populated; Scheduled1053 empty; clear/Done1054 restores catalogue. Mode relevance observation; provider ranking unqualified. |
| SRC-0038 | buy_v2_catalogue.dart:2954 | _SearchProductResults | onPressed | round153 alternate finite-search control: catalogue2684-2700 returns paged catalogue before this control for nonempty query when pagedCatalogueEnabled; current installed search1050/1053 takes that branch. Not a device pass. Finite non-paged variant remains unverified; do not change APK/config to manufacture reachability. |
| SRC-0039 | buy_v2_catalogue.dart:3072 | _CatalogueToolbar | onTap | Saved toolbar forwarder; SAVED-ROUND15-01 and ROUND17-02/05 qualify Shop/Wholesale entries; not additional journey |
| SRC-0040 | buy_v2_catalogue.dart:3152 | _CatalogueCategoryPickerButton | onTap | device_pass CATEGORY-ROUND106-01 Shop; WHOLESALE-ROUND160-02/03 Wholesale opens and reopens selected category |
| SRC-0041 | buy_v2_catalogue.dart:3215 | _CatalogueOwnedFeature | onTap | Shop/Wholesale return sale selector before this handler; feature filter handler belongs other destinations (Medicine/orders), not public Shop feature toggle |
| SRC-0042 | buy_v2_catalogue.dart:3433 | _CatalogueCategorySheetState | onPressed | device_pass CATEGORY-ROUND106-05 Shop; WHOLESALE-ROUND160-02 X hides keyboard and restores Wholesale catalogue |
| SRC-0043 | buy_v2_catalogue.dart:3469 | _CatalogueCategorySheetState | onTap | category search Semantics tap/focus; screen-reader activation unverified |
| SRC-0044 | buy_v2_catalogue.dart:3476 | _CatalogueCategorySheetState | onChanged | device_pass CATEGORY-ROUND106-01/03 Shop queries; WHOLESALE-ROUND160-02 fruit matches; other queries and accessibility separate |
| SRC-0045 | buy_v2_catalogue.dart:3518 | _CatalogueCategorySheetState | onPressed | device_pass CATEGORY-ROUND106-04 Shop; WHOLESALE-ROUND160-02 suffix X clears fruit and restores choices |
| SRC-0046 | buy_v2_catalogue.dart:3628 | _CatalogueCategorySheetState | onTap | device_pass MONTHLY-ROUND156-01/02 Shop Monthly; WHOLESALE-ROUND160-03 Fruits and vegetables selection; reopen selected marker; Best prices restoration; other conditional contexts unqualified |
| SRC-0047 | buy_v2_catalogue.dart:3916 | _CatalogueCategoryClearButton | onPressed | device_pass CATEGORY-ROUND106-02 empty-state Clear restores choices; distinct suffix clear also tested |
| SRC-0048 | buy_v2_catalogue.dart:4006 | _CompactCatalogueAction | onTap | Saved compact action forwarder to chrome; SRC-0039 evidence applies at caller; not additional action |
| SRC-0049 | buy_v2_catalogue.dart:4052 | _CatalogueChromeActionState | onTap | chrome Semantics activation; same caller action but screen-reader path unverified |
| SRC-0050 | buy_v2_catalogue.dart:4100 | _CatalogueChromeActionState | onTap | chrome pointer activation forwarder; caller-specific evidence applies, not one extra journey per wrapper |
| SRC-0051 | buy_v2_catalogue.dart:4192 | _CatalogueToolsMenu | onTap | round155 TRACK-ROUND155-01: tool names MS-NEW-09 and opens that order1067-1069; Back Orders1070 then Shop1071 retains Saved1 emptycart. Not direct tools-sheet restoration; live tracking/provider and alternate order states unqualified. |
| SRC-0052 | buy_v2_catalogue.dart:4200 | _CatalogueToolsMenu | onTap | Monthly home basket entry; MONTHLY-ROUND46-01 observation and ROUND54-01 add journey; live list claims not qualified |
| SRC-0053 | buy_v2_catalogue.dart:4218 | _CatalogueToolsMenu | onTap | Recently viewed tool entry; RECENT-ROUND45-02 device pass; unavailable Add defect RV6-D015 remains |
| SRC-0054 | buy_v2_catalogue.dart:4231 | _CatalogueToolsMenu | onTap | Shopping settings entry; SETTINGS-ROUND47-01 device pass |
| SRC-0055 | buy_v2_catalogue.dart:4243 | _CatalogueToolsMenu | onTap | Medicine-only prescription entry; outside public Buy Shop/Wholesale audit; no pass |
| SRC-0056 | buy_v2_catalogue.dart:4264 | _CatalogueToolsMenu | onTap | tools/refinement entry; RECENT-ROUND45-01 and filter rounds; forwarded child coverage, not additional journey |
| SRC-0057 | buy_v2_catalogue.dart:4434 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND47-02 addresses and Back; downstream address conditional cases retain own status |
| SRC-0058 | buy_v2_catalogue.dart:4443 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND47-03 payment preference and Back; no payment execution qualification |
| SRC-0059 | buy_v2_catalogue.dart:4462 | _BuyV2ShoppingSettingsSheetState | onChanged | device_pass SETTINGS-ROUND49-02 switch Off; busy/unavailable/error persistence unverified |
| SRC-0060 | buy_v2_catalogue.dart:4469 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND49-03 row On restores preference; busy/unavailable state unverified |
| SRC-0061 | buy_v2_catalogue.dart:4492 | _BuyV2ShoppingSettingsSheetState | onTap | shopping alerts entry and return SETTINGS-ROUND49-01; alert destinations retain RV6-D003/D016 and own status |
| SRC-0062 | buy_v2_catalogue.dart:4499 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND49-04 Saved product and return; empty and provider states not inferred |
| SRC-0063 | buy_v2_catalogue.dart:4508 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND49-05 Recently viewed product and Back; zero-count disabled state unverified |
| SRC-0064 | buy_v2_catalogue.dart:4515 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND50-01 seller messages Business inbox and Back; no message sent |
| SRC-0065 | buy_v2_catalogue.dart:4534 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND50-02 preferences and Back; independent shared preferences defects remain |
| SRC-0066 | buy_v2_catalogue.dart:4545 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND50-03 sign-in prerequisite and lower-scroll return; authenticated security unavailable |
| SRC-0067 | buy_v2_catalogue.dart:4556 | _BuyV2ShoppingSettingsSheetState | onTap | device_pass SETTINGS-ROUND50-04 Help entry; descendants retain independent coverage |
| SRC-0068 | buy_v2_catalogue.dart:4605 | _ShoppingSettingsRow | onTap | ShoppingSettingsRow forwards provided onTap; reconcile parent row, not separate user journey |
| SRC-0069 | buy_v2_catalogue.dart:4682 | _confirmClearBuyV2RecentlyViewed | onPressed | device_pass RECENT-ROUND46-01 Keep retains history |
| SRC-0070 | buy_v2_catalogue.dart:4687 | _confirmClearBuyV2RecentlyViewed | onPressed | blocked_test_data RECENT-ROUND46-02; confirmation clears both destinations; original history preserved, no Clear pass |
| SRC-0071 | buy_v2_catalogue.dart:4844 | _BuyV2ShoppingHelpSheetState | onPressed | device_pass HELP-ROUND52-04 X restores lower settings scroll |
| SRC-0072 | buy_v2_catalogue.dart:4913 | _BuyV2ShoppingHelpSheetState | onChanged | device_pass HELP-ROUND51-01/02/03 and ROUND52-01/02 query ID/product/seller/no-match; late data/empty account unverified |
| SRC-0073 | buy_v2_catalogue.dart:4926 | _BuyV2ShoppingHelpSheetState | onPressed | device_pass HELP-ROUND51-04 and ROUND52-03 Clear restores orders; keyboard Back separately recorded |
| SRC-0074 | buy_v2_catalogue.dart:4965 | _BuyV2ShoppingHelpSheetState | onTap | device_pass HELP-ROUND51-01/03 Shop/Wholesale order and exact query return; canOpenOrders false and visiting disable unverified |
| SRC-0075 | buy_v2_catalogue.dart:5104 | showBuyV2ShoppingAlerts | onPressed | blocked_provider live shopping-alert Retry/busy recovery unverified; fixture list not recovery evidence |
| SRC-0076 | buy_v2_catalogue.dart:5138 | showBuyV2ShoppingAlerts | onTap | ALERT-ROUND48-02/03/04 destinations and Back pass; ROUND48-05 RV6-D016 remains; missing router conditional unverified |
| SRC-0077 | buy_v2_catalogue.dart:5534 | showBuyV2PartnerCatalogue | onTap | STORE-002/009 browse all pass; availability heading RV6-D012 remains; separate disabled condition unverified |
| SRC-0078 | buy_v2_catalogue.dart:5611 | showBuyV2PartnerCatalogue | onPressed | device_pass STORE-ROUND144-01; Store X restores wheat2; provider/accessibility/relaunch not inferred |
| SRC-0079 | buy_v2_catalogue.dart:5729 | showBuyV2PartnerCatalogue | onTap | device_pass STORE-ROUND39-01/03/04 other Store navigation and return; horizontal position retained |
| SRC-0080 | buy_v2_catalogue.dart:6070 | _PublicStoreTruthPanelState | onPressed | device_pass COLLECTION-ROUND18-02 entry; downstream sign-in boundary ROUND18-05 and ROUND68 remain blocked |
| SRC-0081 | buy_v2_catalogue.dart:6099 | _PublicStoreTruthPanelState | onTap | device_pass STORE-ROUND37-03 collapse/expand Store header; live fulfilment truth unqualified |
| SRC-0082 | buy_v2_catalogue.dart:6190 | _PublicStoreTruthPanelState | onTap | device_pass STORE-ROUND38-01/03 Store-only Chat and Back; shared Chat expansion RV6-D013 remains |
| SRC-0083 | buy_v2_catalogue.dart:6422 | BuyV2StoreCartBar | onTap | Store cart Semantics tap shares pointer action; screen-reader activation unverified |
| SRC-0084 | buy_v2_catalogue.dart:6434 | BuyV2StoreCartBar | onTap | device_pass STORE-008 basket rail opens; return/last-item RV6-D002 remains |
| SRC-0085 | buy_v2_catalogue.dart:6683 | _PagedFullStoreCatalogueState | onPressed | device_pass STORE-ROUND144-02; Store category X restores unchanged full catalogue; All products choice separate; provider/accessibility/relaunch not inferred |
| SRC-0086 | buy_v2_catalogue.dart:6692 | _PagedFullStoreCatalogueState | onTap | device_pass STORE-ROUND145-03; All products after grain restores wheat results180 and page1; provider/accessibility/relaunch separate |
| SRC-0087 | buy_v2_catalogue.dart:6701 | _PagedFullStoreCatalogueState | onTap | device_pass STORE-005 Fruits and STORE-ROUND85-02 Oil/ghee; all category values not inferred |
| SRC-0088 | buy_v2_catalogue.dart:6762 | _PagedFullStoreCatalogueState | onPressed | device_pass STORE-ROUND144-04; full catalogue X restores originating Store; provider/accessibility/relaunch not inferred |
| SRC-0089 | buy_v2_catalogue.dart:6792 | _PagedFullStoreCatalogueState | onPressed | device_pass STORE-006 clear unmatched search; selected category preserved in recorded scenario |
| SRC-0090 | buy_v2_catalogue.dart:6797 | _PagedFullStoreCatalogueState | onChanged | STORE-003 query executed with RV6-D001 empty recovery; not an overall search pass |
| SRC-0091 | buy_v2_catalogue.dart:6798 | _PagedFullStoreCatalogueState | onSubmitted | device_pass STORE-ROUND144-03; wheat keyboard Enter retains results and dismisses keyboard; provider/accessibility/relaunch not inferred |
| SRC-0092 | buy_v2_catalogue.dart:6816 | _PagedFullStoreCatalogueState | onTap | device_pass STORE-004 and STORE-ROUND85-02 category entry; forwards to Store-specific sheet |
| SRC-0093 | buy_v2_catalogue.dart:6928 | _showBuyV2FullStoreCatalogue | onPressed | alternate finite Store catalogue Close; paged catalogue X is SRC-0088; conditional path unverified |
| SRC-0094 | buy_v2_catalogue.dart:7032 | _RelatedStoreCard | onTap | related Store card forwarder; STORE-ROUND39-03 card body and return evidence applies at caller |
| SRC-0095 | buy_v2_catalogue.dart:7206 | _BuyV2InfoSheetHeader | onPressed | shared info-sheet Close forwarder; exact caller required; RECENT-ROUND53-02 covers Recently viewed close only |
| SRC-0096 | buy_v2_catalogue.dart:7383 | _RecentlyViewedProductsSheet | onPressed | device_pass RECENT-ROUND46-01 opens history Clear confirmation and Keep; confirmation Clear remains blocked |
| SRC-0097 | buy_v2_catalogue.dart:7519 | _RecentlyViewedProductInfoRow | onTap | recent product Semantics activation; screen-reader unverified |
| SRC-0098 | buy_v2_catalogue.dart:7525 | _RecentlyViewedProductInfoRow | onTap | device_pass RECENT-ROUND45-05 and SETTINGS-ROUND49-05 product and Back |
| SRC-0099 | buy_v2_catalogue.dart:7582 | _RecentlyViewedProductInfoRow | onPressed | RECENT-ROUND53-01 available Add pass; ROUND45-03/04 unavailable Add RV6-D015 remains |
| SRC-0100 | buy_v2_catalogue.dart:7700 | _SavedProductInfoRow | onTap | Saved row Semantics activation; screen-reader unverified |
| SRC-0101 | buy_v2_catalogue.dart:7704 | _SavedProductInfoRow | onTap | device_pass SETTINGS-ROUND49-04 Saved product and return |
| SRC-0102 | buy_v2_catalogue.dart:7752 | _SavedProductInfoRow | onPressed | round154 SAVED-ROUND154-01: isolated notebook6 removed via exact settings-row icon1062-1063; original wheat retained; count1 propagated to settings1064 and Shop1065. Default pointer qualified; process-death/provider isolation not asserted. |
| SRC-0103 | buy_v2_catalogue.dart:7799 | _HouseholdBasket | onPressed | device_pass MONTHLY-ROUND46-02 View basket products; empty plan disable unverified |
| SRC-0104 | buy_v2_catalogue.dart:7809 | _HouseholdBasket | onPressed | device_pass MONTHLY-ROUND54-01/03/04 Add/re-add targets; provider rejection and unavailable plan unverified |
| SRC-0105 | buy_v2_catalogue.dart:8088 | _ProductGrid | onPressed | round156 MONTHLY-ROUND156-01: reachable non-Saved Monthly basket Meat/seafood empty1077; exact Clear filters restores6of12 basket products1078. Default pointer qualified. Ordinary paged branch bypasses this widget; alternate contexts separate. |
| SRC-0106 | buy_v2_catalogue.dart:8308 | BuyV2CatalogueAvailabilityView | onPressed | blocked_provider catalogue/recovery Retry; real restore failure and positive retry unverified |
| SRC-0107 | buy_v2_catalogue.dart:8322 | BuyV2CatalogueAvailabilityView | onPressed | workspace procurement Return conditional; outside public consumer journey; no public Buy qualification inferred |
| SRC-0108 | buy_v2_catalogue.dart:8369 | _SavedDecisionShelf | onPressed | device_pass SAVED-ROUND17-01 and ROUND42 confirmation entry |
| SRC-0109 | buy_v2_catalogue.dart:8478 | _SavedDecisionShelf | onPressed | Medicine prescription-only Saved action; outside public Shop/Wholesale |
| SRC-0110 | buy_v2_catalogue.dart:8611 | _SavedClearDecisionSheet | onPressed | device_pass SAVED-ROUND42-02 X keeps saved |
| SRC-0111 | buy_v2_catalogue.dart:8621 | _SavedClearDecisionSheet | onPressed | device_pass SAVED-ROUND42-01 Keep saved |
| SRC-0112 | buy_v2_catalogue.dart:8636 | _SavedClearDecisionSheet | onPressed | device_pass SAVED-ROUND17-04 and ROUND43-02 isolated Wholesale clear; original Shop saved preserved |
| SRC-0113 | buy_v2_catalogue.dart:9250 | _CataloguePromotionRail | onTap | alternate non-paged promotion rail Monthly entry; tools entry does not prove this control; conditional unverified |
| SRC-0114 | buy_v2_catalogue.dart:9259 | _CataloguePromotionRail | onTap | alternate non-paged businessBuying promotion; not mounted in ordinary paged review catalogue; unverified |
| SRC-0115 | buy_v2_catalogue.dart:9270 | _CataloguePromotionRail | onTap | alternate non-paged flexibleRestocking promotion; conditional unverified |
| SRC-0116 | buy_v2_catalogue.dart:9282 | _CataloguePromotionRail | onTap | alternate non-paged homeShopping promotion; omitted for Store procurement; conditional unverified |
| SRC-0117 | buy_v2_catalogue.dart:9293 | _CataloguePromotionRail | onTap | Medicine prescription promotion; outside public Shop/Wholesale |
| SRC-0118 | buy_v2_catalogue.dart:9302 | _CataloguePromotionRail | onTap | Medicine OTC promotion; outside public Shop/Wholesale |
| SRC-0119 | buy_v2_catalogue.dart:9434 | _PrescriptionMatchLane | onTap | Medicine prescription Semantics product entry; outside public Shop/Wholesale |
| SRC-0120 | buy_v2_catalogue.dart:9444 | _PrescriptionMatchLane | onPressed | Medicine prescription pointer product entry; same destination as SRC-0119; outside public Shop/Wholesale |
| SRC-0121 | buy_v2_catalogue.dart:9557 | _FeaturedProductRail | onTap | alternate featured rail category Semantics entry; conditional and screen-reader unverified |
| SRC-0122 | buy_v2_catalogue.dart:9561 | _FeaturedProductRail | onTap | alternate featured rail category pointer entry; not header category entry; conditional unverified |
| SRC-0123 | buy_v2_catalogue.dart:9673 | _RecentlyViewedRail | onPressed | alternate recently viewed rail Clear affects current destination; original history preserved; no Clear pass |
| SRC-0124 | buy_v2_catalogue.dart:9792 | _RecentlyViewedCard | onTap | alternate recently viewed rail product entry; separate from recent sheet; conditional unverified |
| SRC-0125 | buy_v2_catalogue.dart:9903 | _CatalogueSectionHeader | onTap | alternate section header category Semantics action; conditional unverified |
| SRC-0126 | buy_v2_catalogue.dart:9907 | _CatalogueSectionHeader | onTap | alternate section header category pointer action; conditional unverified |
| SRC-0127 | buy_v2_catalogue.dart:10048 | _FeaturedProductCardState | onTap | alternate featured card product tap; ordinary grid tap does not qualify this branch |
| SRC-0128 | buy_v2_catalogue.dart:10351 | _FeaturedProductAction | onTap | alternate featured Add/review-offer action; stale offer and success/failure branches unverified |
| SRC-0129 | buy_v2_catalogue.dart:10511 | BuyV2ProductCard | onTap | ordinary product grid open; STORE-001/WHOLESALE-003 and saved product journeys; per-context returns retain own status |
| SRC-0130 | buy_v2_catalogue.dart:10814 | BuyV2ProductCard | onTap | ordinary grid Add/review-offer branch; CART-ROUND98-01 Shop Add and collection/Wholesale seeded checks; stale offer review branch unverified |
| SRC-0131 | buy_v2_catalogue.dart:11136 | _QuantityStepperTargets | onTap | quantity +/- Semantics forwarder; screen-reader unverified |
| SRC-0132 | buy_v2_catalogue.dart:11139 | _QuantityStepperTargets | onPressed | quantity +/- pointer forwarder; CART-ROUND98-01 and MONTHLY-ROUND54-02 cover recorded quantities; limits/revision remain separate |
| SRC-0133 | buy_v2_catalogue.dart:11165 | _QuantityStepperTargets | onTap | quantity Edit Semantics forwarder; screen-reader unverified |
| SRC-0134 | buy_v2_catalogue.dart:11168 | _QuantityStepperTargets | onPressed | device_pass QTY-ROUND150-01/02 exact Shop grid quantity editor Update2 and Cancel3; original basket restored; other placements/revision/accessibility unqualified |
| SRC-0135 | buy_v2_catalogue.dart:11230 | _ProductSaveButton | onTap | compact save bookmark branch; SAVED-ROUND16-02/03 save/remove; stale/error states not inferred |
| SRC-0136 | buy_v2_catalogue.dart:11283 | _ProductSaveButton | onPressed | alternate IconButton save branch; compact bookmark evidence not automatically equivalent; conditional unverified |
| SRC-0137 | buy_v2_design.dart:2489 | _BuyV2PromotionCardState | onTap | unverified promotion semantics activation; pointer destination evidence remains parent-specific |
| SRC-0138 | buy_v2_design.dart:2510 | _BuyV2PromotionCardState | onTap | promotion pointer forwarder; OFFERS-ROUND99-02 headline only; alternate promotion destinations pending |
| SRC-0139 | buy_v2_invoice.dart:135 | _BuyV2InvoicePageState | onPressed | pending exact invoice toolbar Back; INVOICE-005 Android Back is distinct |
| SRC-0140 | buy_v2_invoice.dart:588 | _BuyV2InvoicePageState | onPressed | INVOICE-002 through004 native save picker cancel and unique PDF export; Wholesale legal-invoice readiness B-009 remains blocked |
| SRC-0141 | buy_v2_product_video.dart:204 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0142 | buy_v2_product_video.dart:308 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0143 | buy_v2_product_video.dart:323 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0144 | buy_v2_product_video.dart:341 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0145 | buy_v2_product_video.dart:369 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0146 | buy_v2_product_video.dart:383 | _BuyV2ProductVideoState | onChanged | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0147 | buy_v2_product_video.dart:407 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0148 | buy_v2_scanner.dart:180 | _BuyV2CollectionCameraState | onPressed | Conditional collection camera caller views11090-11095; blocked collection authentication/state fixture, not universally source_unreachable; correction round130; device unverified |
| SRC-0149 | buy_v2_scanner.dart:207 | _BuyV2CollectionCameraState | onPressed | Conditional collection camera caller views11090-11095; blocked collection authentication/state fixture, not universally source_unreachable; correction round130; device unverified |
| SRC-0150 | buy_v2_scanner.dart:348 | _BuyV2ManualCodePanelState | onTap | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0151 | buy_v2_scanner.dart:358 | _BuyV2ManualCodePanelState | onPressed | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0152 | buy_v2_scanner.dart:369 | _BuyV2ManualCodePanelState | onTap | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0153 | buy_v2_scanner.dart:379 | _BuyV2ManualCodePanelState | onPressed | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0154 | buy_v2_scanner.dart:447 | _BuyV2ManualCodePanelState | onPressed | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0155 | buy_v2_scanner.dart:472 | _BuyV2ManualCodePanelState | onChanged | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0156 | buy_v2_scanner.dart:477 | _BuyV2ManualCodePanelState | onSubmitted | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0157 | buy_v2_scanner.dart:864 | _ScannerOverlay | onTap | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0158 | buy_v2_scanner.dart:882 | _ScannerOverlay | onTap | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0159 | buy_v2_scanner.dart:893 | _ScannerOverlay | onTap | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0160 | buy_v2_scanner.dart:1031 | _ScannerActionPanel | onPressed | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0161 | buy_v2_scanner.dart:1061 | _ScannerActionPanel | onPressed | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0162 | buy_v2_scanner.dart:1200 | _ScannerControl | onTap | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0163 | buy_v2_screen.dart:861 | _BuyV2ScreenState | onPressed | profile-context Offers shortcut; rail OFFERS-001 is different entry; exact profile action unverified |
| SRC-0164 | buy_v2_screen.dart:878 | _BuyV2ScreenState | onPressed | profile-context Orders shortcut; exact profile entry/return unverified |
| SRC-0165 | buy_v2_screen.dart:896 | _BuyV2ScreenState | onPressed | profile-context active Shop orders shortcut; exact conditional entry unverified |
| SRC-0166 | buy_v2_screen.dart:923 | _BuyV2ScreenState | onPressed | profile-context destination Cart shortcut; ordinary basket tap not equivalent; unverified |
| SRC-0167 | buy_v2_screen.dart:954 | _BuyV2ScreenState | onPressed | profile-context discovery shortcut; exact account-origin catalogue/return unverified |
| SRC-0168 | buy_v2_screen.dart:1402 | _BuyV2ScreenState | onPressed | delivery rail expansion TRACK-001/005/006; multi-state minimized controls need own evidence |
| SRC-0169 | buy_v2_screen.dart:1532 | _BuyV2ScreenState | onPressed | blocked_provider delivery refresh; real refreshed tracking B-005; exact button and busy state unverified |
| SRC-0170 | buy_v2_screen.dart:1546 | _BuyV2ScreenState | onPressed | device_pass TRACK-002 delivery list opens; close toggle exact check pending |
| SRC-0171 | buy_v2_screen.dart:1571 | _BuyV2ScreenState | onTap | device_pass TRACK-003 selects MS-NEW-09; other order/split identities require own checks |
| SRC-0172 | buy_v2_screen.dart:1777 | _BuyV2ScreenState | onPressed | device_pass WHOLESALE-001 rail entry; retained context separate |
| SRC-0173 | buy_v2_screen.dart:1784 | _BuyV2ScreenState | onPressed | Orders navigation entry; exact existing Orders evidence needs reconciliation; not inferred from profile shortcut |
| SRC-0174 | buy_v2_screen.dart:1791 | _BuyV2ScreenState | onPressed | device_pass OFFERS-001 and round99 entry; rail not alert destination RV6-D016 |
| SRC-0175 | buy_v2_screen.dart:1840 | _BuyV2ScreenState | onPressed | Care Doctor connected route belongs Book; outside public Shop/Wholesale |
| SRC-0176 | buy_v2_screen.dart:1857 | _BuyV2ScreenState | onPressed | Care Salon connected route belongs Book; outside public Shop/Wholesale |
| SRC-0177 | buy_v2_screen.dart:2671 | _BuyQuickDeliveryStatusBar | onTap | minimized tracker body open; expanded TRACK-009 does not prove exact minimized target; unverified |
| SRC-0178 | buy_v2_screen.dart:2701 | _BuyQuickDeliveryStatusBar | onPressed | minimized tracker expand arrow exact target unverified; general rail reopen not equivalent |
| SRC-0179 | buy_v2_screen.dart:2741 | _BuyQuickDeliveryStatusBar | onTap | device_pass TRACK-009 selected tracker body; live detail B-005 remains |
| SRC-0180 | buy_v2_screen.dart:2767 | _BuyQuickDeliveryStatusBar | onPressed | device_failure RV6-D019 round131 captures909-913 exact Minimize arrow retains wrong compact chevron; Hide distinct; no implementation |
| SRC-0181 | buy_v2_screen.dart:2793 | _BuyQuickDeliveryStatusBar | onPressed | device_pass TRACK-007 Keep; unkeep/auto-collapse combinations unverified |
| SRC-0182 | buy_v2_screen.dart:2820 | _BuyQuickDeliveryStatusBar | onPressed | TRACK-008 enable UI pass only; actual arrival playback/preparing/failure and disable unverified |
| SRC-0183 | buy_v2_screen.dart:2836 | _BuyQuickDeliveryStatusBar | onPressed | device_pass TRACK-004 Hide and TRACK-005 restore; multi-order permutations unverified |
| SRC-0184 | buy_v2_screen.dart:3130 | _BuySearchBand | onChanged | OFFERS-006 and SAVED-ROUND64-01 query typing; long-query/late result variations unverified |
| SRC-0185 | buy_v2_screen.dart:3173 | _BuySearchBand | onSubmitted | keyboard Search submission distinct from Finish button; exact existing submission evidence requires reconciliation |
| SRC-0186 | buy_v2_screen.dart:3182 | _BuySearchBand | onTap | search open evidenced OFFERS-006/SAVED-ROUND64-01; no result-service qualification |
| SRC-0187 | buy_v2_screen.dart:3227 | _BuySearchBand | onPressed | device_pass OFFERS-007 clear; per-mode retention and pending response races unverified |
| SRC-0188 | buy_v2_screen.dart:3245 | _BuySearchBand | onPressed | device_pass OFFERS-007 Finish; nonempty submission variants unverified |
| SRC-0189 | buy_v2_screen.dart:3278 | _BuySearchBand | onPressed | device_pass AREA-001 and AREA-ROUND100 entry; lookup B-001 remains |
| SRC-0190 | buy_v2_screen.dart:3291 | _BuySearchBand | onPressed | device_pass ACCOUNT-001 Buy profile icon; authenticated actions retain own blockers |
| SRC-0191 | buy_v2_screen.dart:3443 | _BuyMiniCartBarState | onTap | compact mini-cart Semantics target; screen-reader unverified |
| SRC-0192 | buy_v2_screen.dart:3457 | _BuyMiniCartBarState | onTap | compact mini-cart pointer target; floating rail evidence does not prove compact branch; unverified |
| SRC-0193 | buy_v2_screen.dart:3563 | _BuyMiniCartBarState | onTap | floating mini-cart Semantics activation; screen-reader unverified; raw drag callbacks need supplemental reconciliation |
| SRC-0194 | buy_v2_screen.dart:3591 | _BuyMiniCartBarState | onTap | device_pass CART-ROUND98-01 basket entry; drag/edge/alternate quantity contexts remain separate |
| SRC-0195 | buy_v2_shop_chat.dart:611 | BuyV2ShopChatViewState | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0196 | buy_v2_shop_chat.dart:625 | BuyV2ShopChatViewState | onSelected | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0197 | buy_v2_shop_chat.dart:687 | BuyV2ShopChatViewState | onChanged | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0198 | buy_v2_shop_chat.dart:696 | BuyV2ShopChatViewState | onSelected | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0199 | buy_v2_shop_chat.dart:784 | BuyV2ShopChatViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0200 | buy_v2_shop_chat.dart:807 | BuyV2ShopChatViewState | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0201 | buy_v2_shop_chat.dart:1076 | _ShopChatHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0202 | buy_v2_shop_chat.dart:1152 | _ShopChatHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0203 | buy_v2_shop_chat.dart:1183 | _ShopChatNavigationForwardBar | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0204 | buy_v2_shop_chat.dart:1244 | _ShopChatSearch | onChanged | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0205 | buy_v2_shop_chat.dart:1256 | _ShopChatSearch | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0206 | buy_v2_shop_chat.dart:1310 | _ShopChatFilters | onSelected | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0207 | buy_v2_shop_chat.dart:1465 | _ShopChatEntryTile | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0208 | buy_v2_shop_chat.dart:1478 | _ShopChatEntryTile | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0209 | buy_v2_shop_chat.dart:1659 | _ShopChatLoadRecoveryState | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0210 | buy_v2_shop_chat.dart:1776 | _ShopChatEmptyState | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0211 | buy_v2_shop_chat.dart:1841 | _ShopChatNewConversationView | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0212 | buy_v2_shop_chat.dart:1985 | _ShopChatNewConversationView | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0213 | buy_v2_shop_chat.dart:2053 | _ShopChatNewConversationEmptyState | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0214 | buy_v2_shop_chat.dart:2185 | _ShopChatConversationViewState | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0215 | buy_v2_shop_chat.dart:2282 | _ShopChatConversationViewState | onChanged | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0216 | buy_v2_shop_chat.dart:2305 | _ShopChatConversationViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0217 | buy_v2_shop_chat.dart:2334 | _ShopChatConversationViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0218 | buy_v2_shop_chat.dart:2344 | _ShopChatConversationViewState | onLongPress | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0219 | buy_v2_shop_chat.dart:2360 | _ShopChatConversationViewState | onSelected | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0220 | buy_v2_shop_chat.dart:2382 | _ShopChatConversationViewState | onSelected | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0221 | buy_v2_shop_chat.dart:2397 | _ShopChatConversationViewState | onChanged | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0222 | buy_v2_shop_chat.dart:2745 | _ShopChatThreadHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0223 | buy_v2_shop_chat.dart:2751 | _ShopChatThreadHeader | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0224 | buy_v2_shop_chat.dart:2791 | _ShopChatThreadHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0225 | buy_v2_shop_chat.dart:2800 | _ShopChatThreadHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0226 | buy_v2_shop_chat.dart:2808 | _ShopChatThreadHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0227 | buy_v2_shop_chat.dart:2847 | _ShopChatSelectionHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0228 | buy_v2_shop_chat.dart:2860 | _ShopChatSelectionHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0229 | buy_v2_shop_chat.dart:2867 | _ShopChatSelectionHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0230 | buy_v2_shop_chat.dart:2874 | _ShopChatSelectionHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0231 | buy_v2_shop_chat.dart:2881 | _ShopChatSelectionHeader | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0232 | buy_v2_shop_chat.dart:2924 | _ShopChatInlineThreadMenu | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0233 | buy_v2_shop_chat.dart:2931 | _ShopChatInlineThreadMenu | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0234 | buy_v2_shop_chat.dart:2938 | _ShopChatInlineThreadMenu | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0235 | buy_v2_shop_chat.dart:2945 | _ShopChatInlineThreadMenu | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0236 | buy_v2_shop_chat.dart:2981 | _ShopChatInlineMenuAction | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0237 | buy_v2_shop_chat.dart:3034 | _ShopChatMessageSearch | onChanged | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0238 | buy_v2_shop_chat.dart:3042 | _ShopChatMessageSearch | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0239 | buy_v2_shop_chat.dart:3107 | _ShopChatCommerceContext | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0240 | buy_v2_shop_chat.dart:3320 | _ShopChatQuickReplies | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0241 | buy_v2_shop_chat.dart:3426 | _ShopChatComposer | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0242 | buy_v2_shop_chat.dart:3452 | _ShopChatComposer | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0243 | buy_v2_shop_chat.dart:3464 | _ShopChatComposer | onChanged | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0244 | buy_v2_shop_chat.dart:3465 | _ShopChatComposer | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0245 | buy_v2_shop_chat.dart:3485 | _ShopChatComposer | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0246 | buy_v2_shop_chat.dart:3492 | _ShopChatComposer | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0247 | buy_v2_shop_chat.dart:3521 | _ShopChatComposer | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0248 | buy_v2_shop_chat.dart:3572 | _ShopChatComposerIcon | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0249 | buy_v2_shop_chat.dart:3642 | _ShopChatReplyPreview | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0250 | buy_v2_shop_chat.dart:3715 | _ShopChatMessageBubble | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0251 | buy_v2_shop_chat.dart:3735 | _ShopChatMessageBubble | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0252 | buy_v2_shop_chat.dart:3736 | _ShopChatMessageBubble | onLongPress | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0253 | buy_v2_shop_chat.dart:3757 | _ShopChatMessageBubble | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0254 | buy_v2_shop_chat.dart:3758 | _ShopChatMessageBubble | onLongPress | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0255 | buy_v2_shop_chat.dart:3866 | _ShopChatMessageForwardButton | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0256 | buy_v2_shop_chat.dart:4031 | _ShopChatInlineAttachmentTray | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0257 | buy_v2_shop_chat.dart:4035 | _ShopChatInlineAttachmentTray | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0258 | buy_v2_shop_chat.dart:4259 | _ShopChatInfoViewState | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0259 | buy_v2_shop_chat.dart:4337 | _ShopChatInfoViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0260 | buy_v2_shop_chat.dart:4351 | _ShopChatInfoViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0261 | buy_v2_shop_chat.dart:4369 | _ShopChatInfoViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0262 | buy_v2_shop_chat.dart:4385 | _ShopChatInfoViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0263 | buy_v2_shop_chat.dart:4398 | _ShopChatInfoViewState | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0264 | buy_v2_shop_chat.dart:4472 | _ShopChatInfoAction | onPressed | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0265 | buy_v2_shop_chat.dart:4541 | _ShopChatInfoCard | onTap | not mounted by public Buy; shared Chat route replacement retained in audit; round89 |
| SRC-0266 | buy_v2_views.dart:68 | _openOrderInvoice | onPressed | invoice unavailable dialog Back; exact failure-dialog target requires device evidence; successful invoice does not qualify |
| SRC-0267 | buy_v2_views.dart:78 | _openOrderInvoice | onPressed | invoice unavailable Refresh orders; provider recovery unverified |
| SRC-0268 | buy_v2_views.dart:593 | BuyV2ProductView | onPressed | device_pass STORE-001/COLLECTION-ROUND18-01 Visit store; PRODUCT-ROUND163-01 exact Wholesale Visit supplier and X returns original product/scroll; provider identity authority separate |
| SRC-0269 | buy_v2_views.dart:620 | BuyV2ProductView | onTap | device_pass PRODUCT-ROUND162-02 visible Shop return from Scheduled first-page notebook; other parents/compared-product B002 and Semantics unqualified |
| SRC-0270 | buy_v2_views.dart:952 | BuyV2ProductView | onTap | Medicine-specific supplier decision row; outside public Shop/Wholesale |
| SRC-0271 | buy_v2_views.dart:1440 | _ProductQuickActions | onPressed | device_pass PRODUCT-ROUND162-01 exact product Save/unsave; catalogue count/marker and reopen verified; original wheat retained; process death/account sync/accessibility unqualified |
| SRC-0272 | buy_v2_views.dart:1445 | _ProductQuickActions | onPressed | device_pass SHARE-001 native chooser and SHARE-002 Cancel; recipient open/provider delivery not qualified |
| SRC-0273 | buy_v2_views.dart:1452 | _ProductQuickActions | onPressed | CMP-001 comparison entry with missing matches B-002; populated results and cart remain unverified |
| SRC-0274 | buy_v2_views.dart:1465 | _ProductQuickActions | onPressed | device_pass CHAT-001 Ask seller entry; no real message sent; shared Chat descendants separate |
| SRC-0275 | buy_v2_views.dart:1491 | _ProductQuickActions | onPressed | quick-action button forwarder to Save/Share/Compare/Ask; not additional journey |
| SRC-0276 | buy_v2_views.dart:1520 | _ProductQuickActionButton | onTap | quick-action Semantics activation; screen-reader unverified |
| SRC-0277 | buy_v2_views.dart:1523 | _ProductQuickActionButton | onTap | quick-action InkWell forwarder; caller-specific evidence applies |
| SRC-0278 | buy_v2_views.dart:1879 | _ProductComparisonSheetState | onPressed | device_pass CMP-002 Refresh empty comparison; populated/stale/provider revision B-002 remains |
| SRC-0279 | buy_v2_views.dart:1948 | _ProductComparisonSheetState | onPressed | blocked_test_data B-002 comparison Previous; multi-page matching suppliers absent |
| SRC-0280 | buy_v2_views.dart:1956 | _ProductComparisonSheetState | onPressed | blocked_test_data B-002 More suppliers; pagination and identity retention unverified |
| SRC-0281 | buy_v2_views.dart:2137 | _ProductVariantOption | onTap | variant Semantics select; screen-reader unverified |
| SRC-0282 | buy_v2_views.dart:2153 | _ProductVariantOption | onTap | device_pass VARIANT-ROUND22-03 and ROUND58-01/02/03 milk variants; unavailable/stale variants unverified |
| SRC-0283 | buy_v2_views.dart:2250 | _WholesaleVerificationCard | onPressed | blocked_test_data B014 PRODUCT-ROUND163-02; card requires !businessVerified; current1119-1120 verified review state; exact workspace chooser entry/return unqualified |
| SRC-0284 | buy_v2_views.dart:2489 | _WholesaleTradeDecisionPanelState | onPressed | Wholesale Check availability refresh facts/local signal; provider success and failure branches unverified |
| SRC-0285 | buy_v2_views.dart:2502 | _WholesaleTradeDecisionPanelState | onPressed | Wholesale unavailable Change product exact control unverified; Back not equivalent |
| SRC-0286 | buy_v2_views.dart:2751 | _WholesaleTradeSignalCard | onPressed | local insight Retry provider path unverified; no fixture claim of real local insight |
| SRC-0287 | buy_v2_views.dart:2851 | _WholesaleTradeActionDock | onPressed | blocked_test_data B014 PRODUCT-ROUND163-02; unverified dock routes workspace chooser; current verified Add dock does not qualify this action |
| SRC-0288 | buy_v2_views.dart:2861 | _WholesaleTradeActionDock | onPressed | Wholesale dock Check availability; distinct from panel retry; provider branches unverified |
| SRC-0289 | buy_v2_views.dart:3143 | _ProductOfferDecisionPanel | onPressed | consumer offer Check availability refresh; provider outcome unverified |
| SRC-0290 | buy_v2_views.dart:3155 | _ProductOfferDecisionPanel | onPressed | consumer unavailable Change product exact target unverified |
| SRC-0291 | buy_v2_views.dart:3289 | _ProductContinuationCard | onTap | continuation product Semantics activation; screen-reader unverified |
| SRC-0292 | buy_v2_views.dart:3295 | _ProductContinuationCard | onTap | related/continuation product pointer entry; VARIANT-ROUND22-02 and RV6-D007 return defect retain separate outcomes |
| SRC-0293 | buy_v2_views.dart:3553 | _BuyV2ZoomableMediaState | onTap | blocked_test_data B-008; MEDIA-ROUND75-02 reset zoom, including reduced motion; actual supplier image absent |
| SRC-0294 | buy_v2_views.dart:3868 | _ProductContentSections | onPressed | product content Retry provider error path unverified |
| SRC-0295 | buy_v2_views.dart:4118 | _ProductBenefitsPreview | onPressed | product benefits Retry provider error path unverified |
| SRC-0296 | buy_v2_views.dart:4286 | _MarketplaceTrustPanel | onPressed | marketplace trust Retry provider error path unverified; source claims do not establish trust authority |
| SRC-0297 | buy_v2_views.dart:4453 | _ProductReviewsPanel | onPressed | REVIEW-001; existing-review Edit branch B003 unqualified |
| SRC-0298 | buy_v2_views.dart:4464 | _ProductReviewsPanel | onPressed | REPORT-001; reported/disabled and reconnect branches provider-unqualified |
| SRC-0299 | buy_v2_views.dart:4559 | _showProductReviewSheet | onPressed | REVIEW-002; positive eligibility/loading outcome B003 unqualified |
| SRC-0300 | buy_v2_views.dart:4656 | _ProductFeedbackSheetHeader | onPressed | REPORT-ROUND90-01; REVIEW-ROUND91-01; eligible editor Close B003 unqualified |
| SRC-0301 | buy_v2_views.dart:4885 | _ProductReviewSheetState | onPressed | B003 eligible rating 1-5 selection/replacement unqualified |
| SRC-0302 | buy_v2_views.dart:4919 | _ProductReviewSheetState | onTap | B003 eligible comment focus/keyboard unqualified |
| SRC-0303 | buy_v2_views.dart:4947 | _ProductReviewSheetState | onChanged | B003 eligible comment validation and draft updates unqualified |
| SRC-0304 | buy_v2_views.dart:5039 | _ProductReviewSheetState | onPressed | B003 eligible editor Cancel and retained draft unqualified |
| SRC-0305 | buy_v2_views.dart:5053 | _ProductReviewSheetState | onPressed | B003 eligible Save validation/busy/rejected/accepted unqualified |
| SRC-0306 | buy_v2_views.dart:5195 | _ProductReportSheetState | onTap | REPORT-002..005; all four reason selections verified; busy branch unqualified |
| SRC-0307 | buy_v2_views.dart:5283 | _ProductReportSheetState | onPressed | REPORT-006; busy-disabled Cancel unqualified |
| SRC-0308 | buy_v2_views.dart:5295 | _ProductReportSheetState | onPressed | Report submission excluded; busy/rejection/accepted/duplicate states provider-unqualified |
| SRC-0309 | buy_v2_views.dart:5364 | _AddressSelectionRequired | onPressed | missing-address recovery Choose address; originals Home/Work preserved; no-address branch unverified |
| SRC-0310 | buy_v2_views.dart:5421 | _MissingOrderSelection | onPressed | missing-order recovery View orders; RV6-D010 recovery context requires exact button reconciliation |
| SRC-0311 | buy_v2_views.dart:5569 | _BuyV2CartViewState | onPressed | CART-ROUND12-05/06; MIXED-ROUND63-05/06; empty-disabled and resolution shortcut unqualified |
| SRC-0312 | buy_v2_views.dart:5630 | _BuyV2CartViewState | onPressed | STORE-009 Continue browsing; D002 last-item removal context failure remains open |
| SRC-0313 | buy_v2_views.dart:5677 | _BuyV2CartViewState | onPressed | device_pass CART-ROUND165-01 exact nonempty Shop Browse more and retained notebook210; Offers/Wholesale/aggregate parents unqualified |
| SRC-0314 | buy_v2_views.dart:5730 | _BuyV2CartViewState | onPressed | CART-ROUND12-04 empty Wholesale Browse; all/Shop variants not separately inferred |
| SRC-0315 | buy_v2_views.dart:5811 | _BuyV2CartViewState | onPressed | MIXED-ROUND63-03/04 Review and Back; no-address continuation/pricing recovery conditional gaps |
| SRC-0316 | buy_v2_views.dart:6008 | _confirmBuyV2CartClear | onPressed | CART-ROUND12-05 Keep Cart; MIXED-ROUND63-05 AndroidBack cancellation |
| SRC-0317 | buy_v2_views.dart:6016 | _confirmBuyV2CartClear | onPressed | CART-ROUND12-06 Empty; MIXED-ROUND63-06 scoped Wholesale removal; async scope changes unqualified |
| SRC-0318 | buy_v2_views.dart:6084 | _GstInvoiceCard | onTap | GST request accessibility callback; screen-reader activation unqualified; pointer SRC-0319 same business action |
| SRC-0319 | buy_v2_views.dart:6089 | _GstInvoiceCard | onTap | GST-001 on; GST-ROUND79-04 off; destination/lifecycle variations unqualified |
| SRC-0320 | buy_v2_views.dart:6133 | _GstInvoiceCard | onChanged | IgnorePointer Switch decorative callback; parent SRC-0319 performs toggle; not separate tap journey |
| SRC-0321 | buy_v2_views.dart:6163 | _GstInvoiceCard | onSelected | Saved-profile selection/multiple profiles unqualified; auto-selected chip RV6-D017 observed GST-ROUND79-02 |
| SRC-0322 | buy_v2_views.dart:6215 | _GstInvoiceCard | onPressed | GST-002 Add; existing-profile Edit remains unqualified |
| SRC-0323 | buy_v2_views.dart:6255 | _GstInvoiceCard | onPressed | Restore-failure Retry conditional; failure fixture and restore outcome unqualified |
| SRC-0324 | buy_v2_views.dart:6283 | _confirmRemoveGstProfile | onPressed | Remove-profile Keep dialog action unqualified |
| SRC-0325 | buy_v2_views.dart:6288 | _confirmRemoveGstProfile | onPressed | GST-ROUND79-03 isolated Remove; multi-profile/cross-destination handling unqualified |
| SRC-0326 | buy_v2_views.dart:6463 | _BuyV2GstInvoiceSheetState | onSubmitted | GST-ROUND95-02 empty Legal-name keyboard Next focus transfer passed; populated/accessibility variants unqualified |
| SRC-0327 | buy_v2_views.dart:6488 | _BuyV2GstInvoiceSheetState | onSubmitted | GST-ROUND95-03 empty GSTIN keyboard Next focus transfer passed; populated/accessibility variants unqualified |
| SRC-0328 | buy_v2_views.dart:6514 | _BuyV2GstInvoiceSheetState | onSubmitted | GST-ROUND95-04 Billing keyboard Done unfocus passed; form retained without saving |
| SRC-0329 | buy_v2_views.dart:6530 | _BuyV2GstInvoiceSheetState | onChanged | GST-ROUND79-01 temporary reuse on save; ROUND95-01 toggle off passed; save-off/restore lifecycle unqualified |
| SRC-0330 | buy_v2_views.dart:6592 | _BuyV2GstInvoiceSheetState | onPressed | GST-003..005 invalid forms; GST-ROUND79-01 local save; full boundaries/busy/failure unqualified |
| SRC-0331 | buy_v2_views.dart:6706 | _CheckoutQuoteCard | onPressed | checkout quote Retry B-004; authoritative quote absent; exact Retry UI not qualified from Check delivery |
| SRC-0332 | buy_v2_views.dart:6857 | _CheckoutCommercialPaymentTerms | onPressed | commercial payment terms Retry provider dependency unverified |
| SRC-0333 | buy_v2_views.dart:6969 | _CommercialPaymentTermGroup | onChanged | commercial term radio selection requires authoritative terms; provider/fixture state absent, unverified |
| SRC-0334 | buy_v2_views.dart:7068 | BuyV2CheckoutView | onTap | device_pass CHECKOUT-ROUND165-01 visible Cart return from Address stage; Payment/Confirm origins and busy guard not inferred |
| SRC-0335 | buy_v2_views.dart:7154 | BuyV2CheckoutView | onPressed | primary action forwarding; CHECKOUT-003/005 next/review and CHECKOUT-006 delivery boundary; real submission excluded |
| SRC-0336 | buy_v2_views.dart:7490 | _CheckoutCollectionDetails | onTap | collection Store option selection; COLLECTION-ROUND18 entry not proof of multi-Store choice; conditional unverified |
| SRC-0337 | buy_v2_views.dart:7508 | _CheckoutCollectionDetails | onTap | collection review Store Change to address step; exact control unverified |
| SRC-0338 | buy_v2_views.dart:7565 | _CheckoutCollectionDetails | onTap | collection review Payment Change; exact control unverified |
| SRC-0339 | buy_v2_views.dart:7602 | _CheckoutAddressStage | onSelected | device_pass COLLECTION-ROUND18-06 switch Delivery; resolution-disabled state unverified |
| SRC-0340 | buy_v2_views.dart:7610 | _CheckoutAddressStage | onSelected | Collect at store chip distinct from Store entry COLLECTION-ROUND18-02; exact chip unverified |
| SRC-0341 | buy_v2_views.dart:7665 | _CheckoutAddressStage | onPressed | device_pass CHECKOUT-ROUND135-03 Add another address and empty form X944-945; populated draft/validation separate |
| SRC-0342 | buy_v2_views.dart:7698 | _CheckoutAddressChoice | onTap | address choice Semantics action; screen-reader unverified |
| SRC-0343 | buy_v2_views.dart:7711 | _CheckoutAddressChoice | onTap | device_pass CHECKOUT-ROUND166-01 exact Home then Work checkout pointer selection; original Work restored;provider/relaunch/accessibility unqualified |
| SRC-0344 | buy_v2_views.dart:7748 | _CheckoutAddressChoice | onPressed | device_pass CHECKOUT-ROUND166-02 checkout Work Edit opens exact original fields and X returns same Work selection;no edit/save/validation qualification inferred |
| SRC-0345 | buy_v2_views.dart:7840 | _CheckoutPaymentStage | onTap | review-data payment choice CHECKOUT-004 Paytm; live provider selection not inferred |
| SRC-0346 | buy_v2_views.dart:7921 | _CheckoutPaymentStage | onTap | runtime payment choice/locked notice conditional unverified; review choice separate SRC-0345 |
| SRC-0347 | buy_v2_views.dart:7951 | _CheckoutPaymentStage | onChanged | procurement PO reference conditional field; workspace procurement scope; public consumer pass not inferred |
| SRC-0348 | buy_v2_views.dart:8139 | _CheckoutPaymentStateRow | onPressed | cancel payment action/status-needs-checking requires real attempt state; provider qualification excluded |
| SRC-0349 | buy_v2_views.dart:8232 | _CheckoutConfirmStage | onTap | device_pass GST-ROUND95 flow capture787 Change address; provider delivery recalculation unverified |
| SRC-0350 | buy_v2_views.dart:8293 | _CheckoutConfirmStage | onTap | device_pass CHECKOUT-ROUND135-04 Confirm Payment Change947-948 retains Paytm; Back route observation949 remains open |
| SRC-0351 | buy_v2_views.dart:8433 | _CheckoutPrimaryActionBar | onPressed | primary action button forwarder SRC-0335; no additional journey |
| SRC-0352 | buy_v2_views.dart:8669 | _CheckoutPriceChangeReview | onPressed | accept updated prices requires exact changed quote; B-004/provider-dependent unverified |
| SRC-0353 | buy_v2_views.dart:8729 | _CheckoutPromiseChangeReview | onPressed | accept updated delivery times requires changed promise; B-004/provider-dependent unverified |
| SRC-0354 | buy_v2_views.dart:8845 | BuyV2ConfirmationView | onPressed | confirmation single/multiple order-details branch; positive purchase fixture B-011; RV6-D009 false confirmation remains |
| SRC-0355 | buy_v2_views.dart:8858 | BuyV2ConfirmationView | onPressed | confirmation Continue shopping exact control requires prior recovery evidence reconciliation; no positive order claim |
| SRC-0356 | buy_v2_views.dart:9016 | _PlacedOrderCard | onPressed | placed-order invoice needs confirmed order B-011; historical invoice not equivalent |
| SRC-0357 | buy_v2_views.dart:9292 | BuyV2RecoveryView | onPressed | checkout issue Retry availability B-010; provider revision fixture missing |
| SRC-0358 | buy_v2_views.dart:9302 | BuyV2RecoveryView | onPressed | checkout issue Remove from Cart B-010; ordinary cart removal not equivalent |
| SRC-0359 | buy_v2_views.dart:9309 | BuyV2RecoveryView | onPressed | checkout issue View product B-010; exact affected SKU absent |
| SRC-0360 | buy_v2_views.dart:9314 | BuyV2RecoveryView | onPressed | product issue return checkout B-010; exact revision recovery unverified |
| SRC-0361 | buy_v2_views.dart:9322 | BuyV2RecoveryView | onPressed | device_pass INVENTORY-ROUND28-10 captures384-387 exact Change address and chooser cancellation; warm declared-link UI only; actual serviceability and changed-address revalidation unverified |
| SRC-0362 | buy_v2_views.dart:9335 | BuyV2RecoveryView | onPressed | device_pass INVENTORY-ROUND28-11 captures388-391 Return to Checkout and cart retention; warm declared-link UI only; provider-generated recovery remains unverified |
| SRC-0363 | buy_v2_views.dart:9344 | BuyV2RecoveryView | onPressed | general recovery primary return; RV6-D010 context remains; exact scenario mapping required |
| SRC-0364 | buy_v2_views.dart:9353 | BuyV2RecoveryView | onPressed | recovery Get help exact order binding conditional unverified |
| SRC-0365 | buy_v2_views.dart:9429 | BuyV2OrdersView | onTap | Orders Account return conditional unverified; regular Orders Back not equivalent |
| SRC-0366 | buy_v2_views.dart:9490 | BuyV2OrdersView | onTap | device_pass ORDER-010 and ORDER-ROUND23-02 Delivered tab/query retention; other tabs require own evidence |
| SRC-0367 | buy_v2_views.dart:9636 | _OrdersTabButton | onTap | Orders tab pointer forwarder to SRC-0366; not additional journey |
| SRC-0368 | buy_v2_views.dart:9683 | BuyV2OrderItemsView | onTap | Items visible Order breadcrumb exact target unverified; ORDER-007 Android Back is distinct |
| SRC-0369 | buy_v2_views.dart:9727 | BuyV2OrderItemsView | onTap | device_pass ORDER-005/006 and ORDER-ROUND25-02 historical item product/Back; withdrawn product conditional unverified |
| SRC-0370 | buy_v2_views.dart:9845 | _OrdersAvailabilityState | onPressed | Orders unavailable Retry provider recovery unverified; populated history not equivalent |
| SRC-0371 | buy_v2_views.dart:9915 | _OrdersContinuationRail | onTap | Orders promotion Shop entry exact target unverified; navigation rail separate |
| SRC-0372 | buy_v2_views.dart:9924 | _OrdersContinuationRail | onTap | Orders promotion Wholesale entry exact target unverified |
| SRC-0373 | buy_v2_views.dart:9933 | _OrdersContinuationRail | onTap | Orders Medicine promotion boundary; downstream Care outside public Shop/Wholesale; boundary tap unverified |
| SRC-0374 | buy_v2_views.dart:10066 | _showBuyV2OrderDeliveryContextSheet | onPressed | order delivery-context Close X exact target requires reconciliation; Back not equivalent |
| SRC-0375 | buy_v2_views.dart:10177 | _showBuyV2OrderDeliveryContextSheet | onTap | device_pass ORDER-ROUND25-04 Manage future addresses and Back; other order contexts separate |
| SRC-0376 | buy_v2_views.dart:10189 | _showBuyV2OrderDeliveryContextSheet | onTap | order delivery-context Help exact continuation requires evidence reconciliation; tracking Help is different entry |
| SRC-0377 | buy_v2_views.dart:10251 | _DeliveryExceptionCard | onPressed | blocked_provider B-012 delivery-exception Retry; adapter absent |
| SRC-0378 | buy_v2_views.dart:10329 | _DeliveryExceptionCard | onSelected | blocked_provider B-012 reschedule slot choice; available slots absent |
| SRC-0379 | buy_v2_views.dart:10344 | _DeliveryExceptionCard | onPressed | blocked_provider B-012 confirm new time; no real reschedule authorized |
| SRC-0380 | buy_v2_views.dart:10358 | _DeliveryExceptionCard | onPressed | blocked_provider B-012 delivery dispute; no real dispute sent |
| SRC-0381 | buy_v2_views.dart:10493 | _BalancePaymentCard | onPressed | blocked_provider B-013 balance-payment action; provider absent and live money action excluded |
| SRC-0382 | buy_v2_views.dart:10643 | _BuyV2LiveDeliveryPanelState | onPressed | live delivery error Retry B-005; authoritative location missing; exact UI evidence unverified |
| SRC-0383 | buy_v2_views.dart:10746 | _BuyV2LiveDeliveryPanelState | onPressed | live delivery Refresh location B-005; successful map/location update unverified |
| SRC-0384 | buy_v2_views.dart:10995 | _BuyV2CollectionOrderViewState | onTap | blocked_authentication COLLECTION-ROUND68-01 return origin |
| SRC-0385 | buy_v2_views.dart:11117 | _BuyV2CollectionOrderViewState | onPressed | blocked_authentication COLLECTION-ROUND68-02 scan enabled/disabled |
| SRC-0386 | buy_v2_views.dart:11138 | _BuyV2CollectionOrderViewState | onPressed | blocked_authentication COLLECTION-ROUND68-03 close camera/reopen |
| SRC-0387 | buy_v2_views.dart:11232 | _BuyV2CollectionOrderViewState | onPressed | blocked_authentication COLLECTION-ROUND68-06 order Help/return |
| SRC-0388 | buy_v2_views.dart:11294 | BuyV2TrackingView | onTap | tracking visible Orders/Help return target exact tap requires reconciliation; Android Back not equivalent |
| SRC-0389 | buy_v2_views.dart:11312 | BuyV2TrackingView | onPressed | ORDER-001 attempted refresh blocked_provider B-005; busy/success unverified |
| SRC-0390 | buy_v2_views.dart:11425 | BuyV2TrackingView | onPressed | TRACKING-ROUND169-01 exact Show delivery status1166-70 restores compact control;selected MS-NEW-09 confirmed;Hide restored;live/race variants unqualified |
| SRC-0391 | buy_v2_views.dart:11781 | BuyV2TrackingView | onPressed | tracking Retry order alerts provider/restore failure unverified |
| SRC-0392 | buy_v2_views.dart:11787 | BuyV2TrackingView | onChanged | TRACKING-ROUND169-02 exact tracking switch Off1172 then On1173 with label/icon/toast;review memory only;provider persistence and unavailable Retry unqualified |
| SRC-0393 | buy_v2_views.dart:11805 | BuyV2TrackingView | onPressed | device_pass ORDER-003 and ORDER-ROUND25-03 order Address entry |
| SRC-0394 | buy_v2_views.dart:11815 | BuyV2TrackingView | onPressed | device_pass ORDER-004 and ORDER-ROUND25-01 Items entry; historical content limitations preserved |
| SRC-0395 | buy_v2_views.dart:11825 | BuyV2TrackingView | onPressed | ORDERHELP-001 non-delivered Help and REORDER-001 delivered Reorder; different branches; successful new purchase not inferred |
| SRC-0396 | buy_v2_views.dart:11843 | BuyV2TrackingView | onPressed | device_pass RESOLUTION-001/006 Manage order; eligible return descendants B-006 |
| SRC-0397 | buy_v2_views.dart:11863 | BuyV2TrackingView | onPressed | INVOICE-001 Shop view/export evidence; Wholesale ORDER-ROUND24-01 B-009; future actual invoice integrity unqualified |
| SRC-0398 | buy_v2_views.dart:11905 | BuyV2TrackingView | onTap | after-delivery support continuation exact target needs reconciliation; tracking Help action not equivalent |
| SRC-0399 | buy_v2_views.dart:12086 | _BuyV2OrderResolutionSheetState | onPressed | provider B-006 resolution Retry; RESOLUTION-011 retains unavailable eligibility, not successful recovery |
| SRC-0400 | buy_v2_views.dart:12097 | _BuyV2OrderResolutionSheetState | onPressed | unavailable-resolution Contact support exact button unverified; no message authorized |
| SRC-0401 | buy_v2_views.dart:12108 | _BuyV2OrderResolutionSheetState | onTap | RESOLUTION-002 cancel selected; RESOLUTION-007/008/009 return types blocked eligibility; positive selection reset ROUND82-06 blocked |
| SRC-0402 | buy_v2_views.dart:12147 | _BuyV2OrderResolutionSheetState | onChanged | blocked_provider RESOLUTION-ROUND82-04 eligible item quantity state absent |
| SRC-0403 | buy_v2_views.dart:12178 | _BuyV2OrderResolutionSheetState | onPressed | blocked_provider RESOLUTION-ROUND82-06 refresh/reset after positive selection absent |
| SRC-0404 | buy_v2_views.dart:12222 | _BuyV2OrderResolutionSheetState | onChanged | device_pass RESOLUTION-003/004 and ROUND82/83 cancellation reasons; return/refund reasons positive eligibility unverified |
| SRC-0405 | buy_v2_views.dart:12229 | _BuyV2OrderResolutionSheetState | onPressed | submission excluded real transaction/request; provider outcomes RESOLUTION-ROUND82-05/07 unverified |
| SRC-0406 | buy_v2_views.dart:12259 | _BuyV2OrderResolutionSheetState | onPressed | Contact support instead exact button unverified; no message authorized |
| SRC-0407 | buy_v2_views.dart:12315 | _OrderResolutionItemTile | onChanged | blocked_provider B-006 / RESOLUTION-ROUND82-04 eligible item checkbox; disabled purchased items observed only |
| SRC-0408 | buy_v2_views.dart:12367 | _OrderResolutionItemTile | onPressed | blocked_provider RESOLUTION-ROUND82-04 selected return quantity decrease unverified |
| SRC-0409 | buy_v2_views.dart:12387 | _OrderResolutionItemTile | onPressed | blocked_provider RESOLUTION-ROUND82-04 increase/eligible maximum unverified |
| SRC-0410 | buy_v2_views.dart:12426 | _OrderResolutionOptionTile | onTap | resolution type pointer forwarder SRC-0401; no additional journey |
| SRC-0411 | buy_v2_views.dart:12535 | _BuyV2AssistViewState | onTap | legacy Assist callback; public Buy entry not established; source reachability reconciliation pending, no device pass |
| SRC-0412 | buy_v2_views.dart:12633 | _BuyV2AssistViewState | onTap | legacy Assist callback; public Buy entry not established; source reachability reconciliation pending, no device pass |
| SRC-0413 | buy_v2_views.dart:12782 | _BuyV2AssistViewState | onTap | legacy Assist callback; public Buy entry not established; source reachability reconciliation pending, no device pass |
| SRC-0414 | buy_v2_views.dart:12844 | _BuyV2AssistViewState | onChanged | legacy Assist callback; public Buy entry not established; source reachability reconciliation pending, no device pass |
| SRC-0415 | buy_v2_views.dart:12845 | _BuyV2AssistViewState | onSubmitted | legacy Assist callback; public Buy entry not established; source reachability reconciliation pending, no device pass |
| SRC-0416 | buy_v2_views.dart:12855 | _BuyV2AssistViewState | onPressed | legacy Assist callback; public Buy entry not established; source reachability reconciliation pending, no device pass |
| SRC-0417 | buy_v2_views.dart:12886 | _BuyV2AssistViewState | onTap | legacy Assist callback; public Buy entry not established; source reachability reconciliation pending, no device pass |
| SRC-0418 | buy_v2_views.dart:12938 | BuyV2AccountView | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0419 | buy_v2_views.dart:13028 | BuyV2AccountView | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0420 | buy_v2_views.dart:13036 | BuyV2AccountView | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0421 | buy_v2_views.dart:13045 | BuyV2AccountView | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0422 | buy_v2_views.dart:13054 | BuyV2AccountView | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0423 | buy_v2_views.dart:13061 | BuyV2AccountView | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0424 | buy_v2_views.dart:13072 | BuyV2AccountView | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0425 | buy_v2_views.dart:13116 | _AccountActionRow | onTap | legacy Buy account callback; shared profile round111 is not this screen; exact route/entry and descendant coverage pending |
| SRC-0426 | buy_v2_views.dart:13301 | showBuyV2FilterSheet | onPressed | Medicine-only entry in catalogue.dart4180; outside public Shop/Wholesale audit |
| SRC-0427 | buy_v2_views.dart:13327 | showBuyV2FilterSheet | onTap | Placeholder action callback; wrapper SRC-0428 handles actual invocation; Medicine-only entry |
| SRC-0428 | buy_v2_views.dart:13329 | showBuyV2FilterSheet | onTap | Medicine-only Sort/refine navigation; outside public Shop/Wholesale audit |
| SRC-0429 | buy_v2_views.dart:13351 | showBuyV2FilterSheet | onTap | Medicine-only tools dispatch; outside public Shop/Wholesale audit |
| SRC-0430 | buy_v2_views.dart:13376 | showBuyV2FilterSheet | onTap | Medicine-only filter options dispatch; Shop/Wholesale options not mounted by current selector |
| SRC-0431 | buy_v2_views.dart:13520 | showBuyV2DiscoveryRefinementSheet | onPressed | FILTER-ROUND55-04 Close after draft Clear; other draft variants unqualified |
| SRC-0432 | buy_v2_views.dart:13546 | showBuyV2DiscoveryRefinementSheet | onTap | FILTER-002..006 sort choices; full ordering across pages unqualified |
| SRC-0433 | buy_v2_views.dart:13562 | showBuyV2DiscoveryRefinementSheet | onTap | FILTER-ROUND93-02 Any price after draft cap then Apply/reopen; prior-applied cap replacement unqualified |
| SRC-0434 | buy_v2_views.dart:13570 | showBuyV2DiscoveryRefinementSheet | onTap | FILTER-005/006; ROUND55-01..03; ROUND59-02; WHOLESALE-ROUND60-01..04; equality/provider boundary unqualified |
| SRC-0435 | buy_v2_views.dart:13588 | showBuyV2DiscoveryRefinementSheet | onTap | FILTER-ROUND93-03 Any pack after draft Standard then Apply/reopen; prior-applied replacement unqualified |
| SRC-0436 | buy_v2_views.dart:13598 | showBuyV2DiscoveryRefinementSheet | onTap | FILTER-008/009 standard/multipack; Wholesale omitted per ROUND59-01 |
| SRC-0437 | buy_v2_views.dart:13631 | showBuyV2DiscoveryRefinementSheet | onTap | FILTER-010 brand unavailable; positive toggle/multiselect requires populated brand fixture |
| SRC-0438 | buy_v2_views.dart:13648 | showBuyV2DiscoveryRefinementSheet | onChanged | FILTER-011 enable; ROUND93-04 direct draft disable and Apply/reopen; mixed availability unqualified |
| SRC-0439 | buy_v2_views.dart:13660 | showBuyV2DiscoveryRefinementSheet | onTap | Tools destinations covered rounds45-61 per FILTER-001; stale-scope rejection unqualified |
| SRC-0440 | buy_v2_views.dart:13693 | showBuyV2DiscoveryRefinementSheet | onPressed | FILTER-012; ROUND55-04..06; ROUND93-01 empty-draft Clear disabled; other combinations unqualified |
| SRC-0441 | buy_v2_views.dart:13711 | showBuyV2DiscoveryRefinementSheet | onPressed | FILTER-003/006/008/009/011/012 and ROUND55/59/60 Apply; stale-scope disabled state unqualified |
| SRC-0442 | buy_v2_views.dart:13792 | _DiscoveryChoice | onTap | Reusable choice dispatch; counted through parent sort/price/pack/brand controls, not another journey |
| SRC-0443 | buy_v2_views.dart:13849 | _BuyV2FilterToolAction | onTap | unverified accessibility semantics activation; tool destinations separately indexed SRC0051-0056 |
| SRC-0444 | buy_v2_views.dart:13858 | _BuyV2FilterToolAction | onTap | forwarder to filter tool action; RECENT-ROUND45-01 expansion is not every tool destination |
| SRC-0445 | buy_v2_views.dart:13922 | _BuyV2FilterOption | onTap | unverified accessibility semantics activation; pointer filters separately indexed SRC0426-0442 |
| SRC-0446 | buy_v2_views.dart:13935 | _BuyV2FilterOption | onTap | pointer forwarder to filter choice; scoped filter evidence only; all option values not inferred |
| SRC-0447 | buy_v2_views.dart:14062 | showBuyV2PaymentSheet | onPressed | device_pass SETTINGS-ROUND136-01 exact payment sheet X957-958 returns Shopping settings with Paytm unchanged |
| SRC-0448 | buy_v2_views.dart:14094 | showBuyV2PaymentSheet | onTap | device_pass SETTINGS-ROUND137-01 Paytm re-selection in exact settings sheet961-962; old087 proves Wholesale checkout only; switching other choices remains unverified |
| SRC-0449 | buy_v2_views.dart:14139 | _BuyV2PaymentChoice | onTap | unverified accessibility semantics activation for payment choices |
| SRC-0450 | buy_v2_views.dart:14153 | _BuyV2PaymentChoice | onTap | pointer forwarder SRC0448; exact settings-sheet Paytm re-selection961-962; other choices and semantic activation unverified |
| SRC-0451 | buy_v2_views.dart:14288 | showBuyV2PrescriptionSheet | onPressed | Medicine prescription boundary BOUNDARY-ROUND36-01; downstream prescription sheet outside public Shop audit |
| SRC-0452 | buy_v2_views.dart:14345 | showBuyV2PrescriptionSheet | onTap | Medicine saved prescription approval outside scoped Shop; no approval performed |
| SRC-0453 | buy_v2_views.dart:14355 | showBuyV2PrescriptionSheet | onTap | Medicine saved prescription approval outside scoped Shop; no approval performed |
| SRC-0454 | buy_v2_views.dart:14362 | showBuyV2PrescriptionSheet | onTap | Medicine prescription attachment outside scoped Shop; no attachment performed |
| SRC-0455 | buy_v2_views.dart:14481 | showBuyV2AddressSheet | onPressed | device_pass SETTINGS-ROUND136-02 exact address selector X959-960 returns Shopping settings with Work retained |
| SRC-0456 | buy_v2_views.dart:14530 | showBuyV2AddressSheet | onTap | AUDIT-ROUND40-08 and ADDR-ROUND57-04 restore original Work selection; other entries not inferred |
| SRC-0457 | buy_v2_views.dart:14549 | showBuyV2AddressSheet | onPressed | AUDIT-ROUND40-06 isolated address removal cancellation captures458-460; originals preserved |
| SRC-0458 | buy_v2_views.dart:14557 | showBuyV2AddressSheet | onPressed | AUDIT-ROUND40-07 and ADDR-ROUND57-04 isolated test-address removal; originals preserved |
| SRC-0459 | buy_v2_views.dart:14577 | showBuyV2AddressSheet | onPressed | ADDR-005 request sheet capture119; recipient/provider completion remains blocked |
| SRC-0460 | buy_v2_views.dart:14589 | showBuyV2AddressSheet | onPressed | AUDIT-ROUND40-04 and ADDR-ROUND57-01 isolated Other place creation; other address types conditional |
| SRC-0461 | buy_v2_views.dart:14653 | _BuyV2AddressChoice | onTap | unverified accessibility semantics activation for address selection |
| SRC-0462 | buy_v2_views.dart:14657 | _BuyV2AddressChoice | onTap | pointer forwarder to address choice SRC0456; scoped Work restoration evidence |
| SRC-0463 | buy_v2_views.dart:14764 | _BuyV2AddressChoice | onTap | unverified semantic menu activation; pointer Work menu ADDR-002 is distinct |
| SRC-0464 | buy_v2_views.dart:14769 | _BuyV2AddressChoice | onSelected | ADDR-003 Work Edit; isolated edit/save ADDR-ROUND57-02 and deletion AUDIT-ROUND40-06/07; other original addresses preserved |
| SRC-0465 | buy_v2_views.dart:15010 | _BuyV2AddressRequestFormState | onTap | device_pass ADDR-ROUND137-01 Share request opens Android chooser966 and Cancel967; fixture link only; recipient binding expiry actual receipt and sending not qualified |
| SRC-0466 | buy_v2_views.dart:15017 | _BuyV2AddressRequestFormState | onTap | pending exact request-address Copy action; provider-issued recipient binding and expiry not qualified |
| SRC-0467 | buy_v2_views.dart:15027 | _BuyV2AddressRequestFormState | onPressed | ADDR-006 manual entry120 and validation007-010; named recipient transfer with keyboard now ADDR-ROUND138-01/02 captures970-973; process-death and remaining input variants unverified |
| SRC-0468 | buy_v2_views.dart:15278 | _BuyV2AddAddressFormState | onSelected | Other place create ROUND40/57;all four kind chips now ADDR-ROUND139-01 through04 captures978-981 retain recipient;per-kind save validation and persistence remain separate |
| SRC-0469 | buy_v2_views.dart:15346 | _BuyV2AddAddressFormState | onPressed | ADDR-007 through009 required-field validation; isolated create AUDIT-ROUND40-04 and edit ADDR-ROUND57-02; other validations pending |
| SRC-0470 | buy_v2_views.dart:15393 | _AddressFormHeader | onPressed | ADDR-004 edit Close and ADDR-010 partial Close; request X968 and named request keyboard-open X974-975 qualified; other parent contexts separate |
| SRC-0471 | buy_v2_views.dart:15426 | _ReturnAffordance | onTap | pointer return forwarder; each parent destination separately indexed; no blanket pass |
| SRC-0472 | buy_v2_views.dart:15468 | _ReturnAffordance | onTap | unverified semantic return activation; pointer/Android Back not equivalent |
| SRC-0473 | buy_v2_views.dart:15650 | _DecisionActionRow | onTap | unverified semantic decision-row activation; each parent decision separately indexed |
| SRC-0474 | buy_v2_views.dart:15656 | _DecisionActionRow | onTap | pointer decision-row forwarder; conditional product recovery paths remain separately pending |
| SRC-0475 | buy_v2_views.dart:15780 | _ProductOwnedActionPanel | onTap | outer gesture Add forwarding; exact owned-panel variant not inferred from another Add control |
| SRC-0476 | buy_v2_views.dart:15788 | _ProductOwnedActionPanel | onPressed | owned-panel button Add forwarding; distinguish conditional product panel from purchase-row Add; mapping pending |
| SRC-0477 | buy_v2_views.dart:15982 | _ProductPurchaseActionRow | onTap | outer gesture purchase Add forwarding; exact hit target not independently verified |
| SRC-0478 | buy_v2_views.dart:15986 | _ProductPurchaseActionRow | onPressed | QTY-ROUND27-01 consumer product Add and QTY-ROUND33-01 Wholesale Add; stale offers remain conditional |
| SRC-0479 | buy_v2_views.dart:16141 | _QuantityEditorState | onChanged | QTY-ROUND33-02 invalid-to-valid correction; error clearing timing before submission not separately captured |
| SRC-0480 | buy_v2_views.dart:16144 | _QuantityEditorState | onSubmitted | QTY-ROUND27-05 keyboard Enter saves3; ROUND27-07 zero rejected; ROUND33-02 Wholesale3 accepted |
| SRC-0481 | buy_v2_views.dart:16149 | _QuantityEditorState | onPressed | QTY-ROUND115-02 visible Update quantity saves2 packs558 from cart; keyboard dismissed; other entry variants pending |
| SRC-0482 | buy_v2_views.dart:16152 | _QuantityEditorState | onPressed | QTY-ROUND27-04 Cancel invalid editor preserves original count; unsaved Back separately ROUND27-06 |
| SRC-0483 | buy_v2_views.dart:16214 | _CompactProductStepper | onPressed | QTY-ROUND27-08 decrement to zero and QTY-ROUND33-04 minimum removal; consumer/Wholesale exact records retained |
| SRC-0484 | buy_v2_views.dart:16225 | _CompactProductStepper | onPressed | QTY-ROUND27-01 editor entry and QTY-ROUND33-01 Wholesale minimum editor; other placements not inferred |
| SRC-0485 | buy_v2_views.dart:16253 | _CompactProductStepper | onPressed | QTY-ROUND115-04 product compact plus2 to3; total837 retained on Back |
| SRC-0486 | buy_v2_views.dart:16360 | _CartScopeBar | onTap | device_pass CART-ROUND12-03 empty Wholesale scope; MIXED-ROUND63-01 both nonempty Shop/Wholesale/combined scope quantities and subtotals; process-death/account switching/provider context remain |
| SRC-0487 | buy_v2_views.dart:16594 | _CartBenefitPanel | onTap | device_pass COUPON-ROUND166-02 exact Shop Coupons row opens Coupons;other destination and populated state separate |
| SRC-0488 | buy_v2_views.dart:16614 | _CartBenefitPanel | onTap | COUPON-003 Payment offers entry capture082; no actual payment qualification |
| SRC-0489 | buy_v2_views.dart:16677 | _CartBenefitEntry | onTap | benefit entry pointer forwarder to SRC0487/0488; no additional journey |
| SRC-0490 | buy_v2_views.dart:16916 | _CartBenefitsPageState | onPressed | device_pass COUPON-ROUND166-02 exact Coupons toolbar Back retains Shop cart210;other selected/provider states separate |
| SRC-0491 | buy_v2_views.dart:16950 | _CartBenefitsPageState | onChanged | pending per-destination coupon selector; initial Wholesale/Shop entries are not every tab switch |
| SRC-0492 | buy_v2_views.dart:16957 | _CartBenefitsPageState | onChanged | COUPON-003 Payment offers kind switch; reverse Coupon tab exact check pending |
| SRC-0493 | buy_v2_views.dart:17065 | _CartBenefitsPageState | onPressed | device_pass COUPON-ROUND166-01 exact footer Return to Cart from empty Coupons retains210/no selection;selected state not inferred |
| SRC-0494 | buy_v2_views.dart:17139 | _CartBenefitDestinationSelector | onTap | destination selector forwarder SRC0491; every eligible destination pending |
| SRC-0495 | buy_v2_views.dart:17235 | _CartBenefitKindSelector | onTap | device_pass COUPON-ROUND166-01 explicit Coupons tab after Payment offers;Shop low-value empty state;other destination/populated states unqualified |
| SRC-0496 | buy_v2_views.dart:17245 | _CartBenefitKindSelector | onTap | COUPON-003 Payment offers; scoped fixture only |
| SRC-0497 | buy_v2_views.dart:17275 | _CartBenefitKindButton | onTap | kind-button forwarder SRC0495/0496; no additional destination |
| SRC-0498 | buy_v2_views.dart:17350 | _CartBenefitEligibilityState | onPressed | blocked live benefit provider Retry; review coupon fixtures do not qualify authoritative refresh |
| SRC-0499 | buy_v2_views.dart:17571 | _CartBenefitCard | onTap | unverified semantic benefit activation; pointer selection not equivalent |
| SRC-0500 | buy_v2_views.dart:17576 | _CartBenefitCard | onTap | COUPON-002 supplier coupon selection; COUPON-ROUND16-01 low-value ineligibility; removal and other offers pending |
| SRC-0501 | buy_v2_views.dart:17838 | _CartRecommendationCard | onTap | CART-ROUND12-02 recommendation product and Back captures185-187 |
| SRC-0502 | buy_v2_views.dart:17933 | _CartRecommendationCard | onPressed | CART-ROUND12-01 recommended tissues Add captures183-184; prescription branch outside Shop scope |
| SRC-0503 | buy_v2_views.dart:18047 | _CartDeliveryInstructionCard | onTap | CART-ROUND11-04 Leave at door; ROUND11-07 restore none; other options and destination variants pending |
| SRC-0504 | buy_v2_views.dart:18164 | _CartTipCard | onSelected | source-unreachable disabled tips per CART-ROUND32-03; no positive device qualification |
| SRC-0505 | buy_v2_views.dart:18175 | _CartTipCard | onSelected | source-unreachable disabled tips per CART-ROUND32-03; nonzero tips not tested |
| SRC-0506 | buy_v2_views.dart:18392 | _CartLine | onTap | unverified semantic cart product activation |
| SRC-0507 | buy_v2_views.dart:18398 | _CartLine | onTap | QTY-ROUND115-03 cart line opens same wheat5kg SKU; Android Back restores cart with updated3packs837 |
| SRC-0508 | buy_v2_views.dart:18571 | _CartLine | onPressed | VARIANT-ROUND58-04 isolated cart removal; other cart line states separately scoped |
| SRC-0509 | buy_v2_views.dart:18583 | _CartLine | onPressed | QTY-ROUND115-01 cart-line quantity editor opens correct selected1 and minimum1 |
| SRC-0510 | buy_v2_views.dart:18603 | _CartLine | onPressed | BULKCART-002 quantity increase; consumer placement and limits need exact reconciliation |
| SRC-0511 | buy_v2_views.dart:18727 | _SavedAddressReminder | onPressed | saved-address Edit forwarder; per-parent account/cart/checkout placements pending |
| SRC-0512 | buy_v2_views.dart:18927 | _CheckoutCard | onTap | checkout-card pointer forwarder; parent-specific destination checks retained, no blanket pass |
| SRC-0513 | buy_v2_views.dart:19022 | _OrderCard | onPressed | conditional nonstandard order View order; exact fixture and owned/unowned states pending |
| SRC-0514 | buy_v2_views.dart:19044 | _OrderCard | onTap | pending order-card body primary activation; button tracking is distinct |
| SRC-0515 | buy_v2_views.dart:19173 | _OrderCard | onPressed | INVOICE-001 consumer invoice; ORDER-ROUND24-01 Wholesale blocked B-009; other identity combinations not inferred |
| SRC-0516 | buy_v2_views.dart:19190 | _OrderCard | onPressed | existing tracking/Delivered order entry evidence; exact card statuses and return contexts need deduplication |
| SRC-0517 | buy_v2_views.dart:19374 | _TrackingAction | onTap | tracking-action forwarder; each Address/Items/Help action separately indexed |
| SRC-0518 | buy_v2_views.dart:19428 | _OrderDeliveryContinuation | onTap | outer delivery continuation gesture forwarder; conditional provider paths B-012/B-013 |
| SRC-0519 | buy_v2_views.dart:19440 | _OrderDeliveryContinuation | onTap | inner delivery continuation pointer forwarder; conditional provider paths B-012/B-013 |
| SRC-0520 | buy_v2_views.dart:19702 | _AssistIntentState | onTap | legacy Assist intent forwarder; reachable public entry not established; not a device pass |
| SRC-0521 | buy_v2_views.dart:19781 | _AssistChannelState | onTap | legacy Assist channel forwarder; reachable public entry not established; not a device pass |
| SRC-0522 | buy_v2_views.dart:19845 | _PrescriptionChoice | onTap | Medicine prescription semantics outside scoped Shop downstream |
| SRC-0523 | buy_v2_views.dart:19856 | _PrescriptionChoice | onTap | Medicine prescription pointer outside scoped Shop downstream |
| SRC-0524 | buy_v2_views.dart:19922 | _AddPrescriptionChoice | onTap | Medicine new-prescription semantics outside scoped Shop downstream |
| SRC-0525 | buy_v2_views.dart:19933 | _AddPrescriptionChoice | onTap | Medicine new-prescription pointer outside scoped Shop downstream |
| SRC-0526 | buy_v2_views.dart:20017 | _ShareChoiceState | onTap | unverified semantic ShareChoice activation; request Share/Copy parents pending SRC0465/0466 |
| SRC-0527 | buy_v2_views.dart:20023 | _ShareChoiceState | onTap | ShareChoice pointer forwarder; request Share/Copy parents pending SRC0465/0466 |

Next: reconcile candidate groups against public route wiring and existing JOURNEYS evidence. Shared destinations outside this directory also remain part of the audit; this index does not exclude them. All existing defect/device/data counts unchanged.


## Round 89 - public Buy Chat route reconciliation

Broad type-name search produced truncated output;recovered with exact constructor search and literal router/screen reads under standing bounded-read recovery authority. No device action or product change. Only external BuyV2ShopChatView constructor found is social_v2_consumer.dart1143 in contextualChatOpen. Public Buy screen2370-2390 instead pushes BuyV2ChatRouteAdapter;adapter46 targets /app/chat/inbox and supplier help/product/store targets shared /app/chat/thread. journey_router.dart762-800 mounts ChatInboxScreen and ChatThreadScreen with return/draft bindings.

Classified71 legacy/contextual widget callback candidates as not mounted by the public Buy route. This does not exclude shared Chat: inbox/thread controls and connected destinations remain required, with original CHAT/ORDERHELP/Store-chat evidence retained. No host/source result promoted to device pass. Shared Chat candidate indexing and semantic reconciliation remain unfinished.

93 of527 lexical candidates now classified (scanner15,video7,contextual chat71);434 remain unclassified. These are source occurrences,not unique journeys or missing device tests. All defect/device/data counts unchanged;full audit open.


## Round 90 - Report sheet Close and Android Back on Redmi

- Fresh physical capture 739 re-established the Store Oil and ghee page 1-40 of 238 before any tap. Opened Refined sunflower oil 3 (740), scrolled to product reviews (741), opened Report issue (742).
- Close icon dismissed the unselected report sheet and restored the same product position (743). Reopened (744), then Android Back also dismissed only the sheet and restored that position (745). Two device passes; no new defect. No report was sent and no cart/address/order data was changed.
- Source read: buy_v2_views.dart 5083-5319. Reason selection clears rejection; submit disables while busy; accepted response closes; rejection stays with session notice. These submission outcomes are source inventory only, not device passes. Existing REPORT-001 through REPORT-006 cover opening, all four reasons and Cancel. Selected-reason alternate dismissal, barrier/drag, enlarged-text and submission descendants remain unqualified. REVIEW-001 through REVIEW-003 only qualify ineligible review/recheck/Back, not eligible review submission.
- Seven new reviewed captures, 745 physical captures total; 747 evidence rows; 481 action rows including 383 device passes. Seventeen distinct confirmed defects unchanged. The unique-journey denominator remains incomplete.
- Read/recovery disclosure: combined policy output truncated; no product mutation followed; existing coordination gate was rerun and exited 0. First evidence-append command had a parse-time unmatched parenthesis and exited 1 before execution; corrected bounded append completed under standing recovery authorization. No policy/checker changes.


## Round 91 - Review conditional inventory and eligibility Close

Physical Redmi captures 746-748 show the current product, the no-eligible-purchase sheet and Close returning to the same product position. One device pass; no review/report sent, no new defect. Totals: 748 physical captures, 750 evidence rows, 482 action rows including 384 device passes; 17 distinct confirmed defects unchanged.

Read buy_v2_views.dart 4363-4612 and 4733-5082 alongside prior report-form read. Reconciled SRC-0297 through SRC-0308 (12 candidates) against REVIEW-001..003, REPORT-001..006 and rounds90-91. Source candidate reconciliation is now 105 classified / 422 unclassified out of 527 lexical occurrences. These are not unique journeys or device-pass counts.

Explicit conditional descendants under existing B003 (not newly discovered defects):
- Eligible editor opening and Edit of an existing review; correct product/existing rating/comment.
- Each rating 1-5, replacement rating and rating-only invalid form.
- Comment focus, keyboard-first Back, second Back, field scroll and accessibility input.
- Empty/whitespace comment rejection; 500-character limit including grapheme input; valid rating plus comment enabling Save.
- Cancel/Close/barrier/drag and reopen retaining the correct product/account draft.
- Failed eligibility refresh after editor opens retaining draft; submission eligibility revalidation.
- Busy submission prevents duplicate action; rejected response retains editable draft and notice; accepted response closes and updates public review.
- Account/product switching, relaunch and stale asynchronous response must not cross draft ownership.
- 200-percent text, keyboard and reduced-motion/screen-reader behavior of the eligible form.

All above remain device-unverified because the tested SKU has no eligible purchase and real submissions are excluded. Source shows a rating/comment draft owner scope and validation but does not prove backend authority or runtime outcomes. Report accepted/failed/busy/Reported states are likewise unqualified; only normal opening, four reasons, Cancel, unselected Close and Android Back have device evidence. Public-panel reconnect fallback remains untested. This inventory does not convert source behavior to device passes or declare the full audit complete.


## Round 92 - Filter source-to-device reconciliation

Read buy_v2_views.dart 13182-13797 and catalogue.dart 4151-4225; matched all library references to showBuyV2FilterSheet / showBuyV2DiscoveryRefinementSheet including callback tear-offs. The legacy filter sheet is selected only for Medicine at catalogue.dart4180; Shop and Wholesale choose the discovery-refinement sheet. A search for call syntax alone would have missed this callback and is not proof of unreachability. No Medicine scope was added.

Reconciled SRC-0426..0442 against existing FILTER-001..012 and rounds55/59/60. Seventeen source candidates reconciled; total 122 classified / 405 unclassified of 527 lexical candidates. This is not a completed unique-journey denominator. No new device result or defect in this source-only round; round91 device totals remain current.

Remaining directly actionable filter checks identified: Any price after a selected cap; Any pack after Standard/Multipack; direct Available-to-order disable; empty-draft Clear disabled. Positive brand toggle/multiselect requires missing brand data. Full price-ordering/equality/mixed availability and provider pagination need suitable data. Scope-change rejection, preview loading/error/count unavailable, shared tool late callbacks, process-death restoration and all accessibility combinations are not qualified by ordinary Apply tests. Current field mapping and provider ownership remain subject to final reconciliation.

The refinement source resets deliveryFastest to relevance when opening, suppresses pack for Wholesale and handles preview scope release in finally. These are implementation observations, not newly registered defects or device passes. The public Shop/Wholesale selectors, existing evidence and remaining cases above are the next device work; no product changes were made.


## Round 93 - Four refinement reset controls on Redmi

Fresh749 established product reviews. Android Back capture750 still displayed the product during transition; not treated as a failed Back. Subsequent capture751 (after an intended scroll) established the Store preview. Close752 returned to originating wheat product; visible Shop Back753 established Scheduled Shop. Navigation setup is not a new pass claim.

754-755: empty refinement Clear visibly disabled and tapping did not change sheet. 756-758: selected cap100 draft then directly selected Any price; preview count restored. 759-762: collapsed price, expanded pack, selected Standard draft then directly Any pack; preview count restored. 763-765: collapsed pack; enabled then directly disabled Available to order. Apply766 and reopen767 preserved Relevance, Any price, Any pack, availability off and disabled Clear. Four device passes; no new defect.

These are draft-selection resets followed by Apply/reopen, not proof of replacing an already-applied non-default filter, complete provider ordering/classification, mixed availability, or process-death persistence. Historical filter qualifications remain unchanged. Source rows433/435/438/440 now reference this exact evidence without broadening the pass.

Nineteen reviewed captures added: 767 physical captures, 769 evidence rows, 486 action rows including 388 device passes; 17 distinct confirmed defects unchanged. Cart untouched, original Saved1 visible766; no review/report/message/order/payment and no product/source implementation. Device remains on default Scheduled Shop refinement sheet767. Full source/action inventory and field mapping remain incomplete.

Evidence edit recovery: first UAT update rejected an incorrect table-field-count assertion before writing; bounded row read confirmed five split fields; corrected operation under standing recovery authorization. Historical rows preserved except the four explicit reconciliation cells.


## Round 94 - Cart and GST source-to-device reconciliation

Read views.dart 5526-6058 and 6059-6646 in bounded source ranges and matched existing cart, Store, GST and mixed-cart rows. Reconciled SRC-0311..0330: twenty candidates, total142 classified /385 unclassified of527 lexical candidates. No new physical result or defect this source-only round. Round93 totals remain current.

The initial lexical index misses InputChip.onDeleted at views.dart6166. Supplemental action SUP-GST-DELETE-01 is explicitly recorded here: open Remove GST details dialog from saved-profile chip; confirm isolated deletion qualified GST-ROUND79-03 (693-694), Keep remains unqualified, disabled delete when busy/persistence unavailable remains unqualified. This is a supplemental candidate, not a new defect or another completed journey. General completeness must include other callback APIs missed by the initial regex.

Exact outstanding cart checks include nonempty Browse more products reconciliation; all/Shop empty Browse variants; empty-cart disabled trash; no-selected-address continuation from Review; resolution-required clear shortcut; changes while clear confirmation is open; account/process-death and pending-price recovery. Existing scoped mixed-cart removal passes do not qualify these descendants.

Exact outstanding GST checks include saved-profile explicit selection and multiple profiles; edit/reuse; Keep cancellation; name/GSTIN/billing keyboard Next/Done; remember toggle off; validation boundary and whitespace/case behavior; restore Retry failure and busy controls; failed-save retention; account/destination/process-death isolation; enlarged text and screen reader. Existing successful local save does not qualify storage/privacy, issuer validity, invoice issuance or backend behavior. The form performs local format validation before controller.save; no production tax-authority validation is inferred.

The GST switch inner callback is IgnorePointer decoration; its parent handles physical toggle and separate Semantics handles accessible activation. These are recorded as one business action with distinct unqualified accessibility coverage, not fabricated separate passes. Cart confirm captures the scope before the sheet and clears that scope after confirmation; no claim about concurrent changes without device evidence.


## Round 95 - GST keyboard traversal and reuse toggle on Redmi

Fresh768 showed default filters; Close769 returned to Scheduled Shop. Added isolated wheat item770 (one item/279), opened cart771, address772 (Work retained), payment773 (Paytm retained). Swipe774 remained on Payment; its filename gst-off is a naming error, not GST evidence. Review order775 reached summary without placing an order. GST on776, Add777.

Turned temporary reuse off778. Legal name focus779 preceded keyboard settlement780. Keyboard Next781 focused GSTIN, Next782 focused Billing address, Done783 hid keyboard and retained form. Four narrow device passes: reuse toggle off and three keyboard transitions with empty fields. No values entered or saved. Populated/validation/accessibility variants and save-with-reuse-off remain unqualified.

AndroidBack784 cancelled form, GST switched off785. Tapping Address progress indicator786 left summary unchanged (not claimed as navigation; Change action used next). Change787 opened original addresses with Work selected; Cart788 retained one279item; minus789 removed only the isolated item and returned to Scheduled Shop with original Saved1. Cart empty; no profile was created; no order/payment/message or provider submission.

Twenty-two reviewed captures:789 physical captures;791 evidence rows;490 action rows including392 device passes. Seventeen distinct confirmed defects unchanged. Source326-329 reconciled to these exact narrow results. Full action inventory, remaining conditional coverage and public-field mapping remain incomplete.


## Round 96 - Supplemental callback inventory

The initial527 callback occurrences used a limited event-name list. Broader lexical scan of on[A-Z] named arguments finds271 additional references, including custom forwarding callbacks and framework-event references. They are supplemental source candidates, NOT271 new journeys, new defects or untested device actions. Reconcile to parent actions and conditional states before deriving a unique-journey denominator. Original527 remain142 classified/385 unclassified. Supplemental rows are an additional queue, not silently marked passed. Shared connected screens outside this directory still require reconciliation.

Scan covers current ui_v2/buy/*.dart source only. It does not establish semantic completeness: gestures/commands can exist without on-prefixed named arguments. Source hashes bind the inventory. No device action, product change or new defect this round; round95 device totals remain current. The first append attempt rejected its count assertion before writing because line-by-line matching missed multiline arguments; the corrected whole-text match retains line locations and matches the original271-count scan under standing bounded recovery authority.

| Source | SHA256 |
|---|---|
| buy_v2_catalogue.dart | 84FEF1B2C1D81178B0F136235298E239963C07323D149E60B3EDB5E0C879C259 |
| buy_v2_design.dart | 4EA0F4877634CF4250C031B1EDC7739D5AB4BA818FC879A519036F56B3ED719F |
| buy_v2_scanner.dart | 251C238D8BD807EDB594EE2E862A064036B71E3D92431D51EF9A6B2F8BC4C113 |
| buy_v2_screen.dart | 7BE1D12EE7CA2ACB96B67B14EC02CAD0DCB25D613A07AF4B0473AE323EB9C0B7 |
| buy_v2_shop_chat.dart | CFA29EB206A9368F9E6A129EA94CC5EB128FD047F82EC20ACDC62504A155DACC |
| buy_v2_views.dart | 4787279F1A5064000412846207FAABF3778D318EDB7881F5E90989670398F9D4 |

| Candidate | Source:line | Callback | Reconciliation |
|---|---|---|---|
| SUPSRC-0001 | buy_v2_catalogue.dart:276 | onRetry | Live-source Offers retry -> _load; separate non-paged provider state; physical retry/error recovery unqualified; no pass inferred from paged review Offers |
| SUPSRC-0002 | buy_v2_catalogue.dart:1141 | onArea | Catalogue footer area -> showBuyV2CatalogueArea; same area-sheet action as SUPSRC-0006, not a second journey; all area selection descendants require reconciliation |
| SUPSRC-0003 | buy_v2_catalogue.dart:1144 | onPrevious | Paged catalogue Previous -> _pager.previous; Offers round70 and Store round87 subsets qualified; ordinary Shop/search previous and retained filters remain separate |
| SUPSRC-0004 | buy_v2_catalogue.dart:1147 | onNext | Paged catalogue Next -> _pager.next; CAT-002, Wholesale round60 and Offers round70 subsets; conditional end/cursor and other contexts not blanket-qualified |
| SUPSRC-0005 | buy_v2_catalogue.dart:1150 | onRefresh | Paged catalogue Refresh -> _pager.refresh; FILTER-ROUND59-04 and OFFERS-ROUND67-06 observations only; provider publication success unqualified |
| SUPSRC-0006 | buy_v2_catalogue.dart:1172 | onAction | Missing-region Choose area -> same showBuyV2CatalogueArea as SUPSRC-0002; missing-region entry and return context require physical qualification |
| SUPSRC-0007 | buy_v2_catalogue.dart:1179 | onAction | Expired/revised publication Refresh offers -> _pager.refresh; ACCESS-ROUND76-01 expiry subset passed; supplier revision/withdrawal authority still unqualified |
| SUPSRC-0008 | buy_v2_catalogue.dart:1186 | onAction | Paged error Try again -> _pager.retry; same recovery as SUPSRC-0010 in alternate placement; injected/provider error and successful recovery pending |
| SUPSRC-0009 | buy_v2_catalogue.dart:1247 | onOpenProduct | Product-card onOpenProduct forwarded from parent; no extra button at assignment; parent context and card tap/Add must be qualified separately |
| SUPSRC-0010 | buy_v2_catalogue.dart:1267 | onAction | Footer error Try again -> _pager.retry; alternate placement of SUPSRC-0008; physical error layout/return recovery pending |
| SUPSRC-0011 | buy_v2_catalogue.dart:1806 | onVisitProduct | Catalogue toolbar onVisitProduct forwarder into tools; parent Saved/Recently viewed product actions, not standalone tap |
| SUPSRC-0012 | buy_v2_catalogue.dart:1808 | onSaved | Saved toolbar toggle -> session.showSavedProducts(!savedOnly), concrete button at3072; SAVED round15/16/17 evidence subsets; no blanket account/process-death qualification |
| SUPSRC-0013 | buy_v2_catalogue.dart:1832 | onOpenStore | Main catalogue Store-search result open forwarder -> onOpenStore; per-result tap/return context needs evidence reconciliation; not a new standalone control |
| SUPSRC-0014 | buy_v2_catalogue.dart:1843 | onShowAll | Empty saved Show all -> session.showSavedProducts(false); SAVED-ROUND43-03 physically passed474-475; ordinary search and other empty branches distinct |
| SUPSRC-0015 | buy_v2_catalogue.dart:2587 | onPrevious | Store-search result pager Previous -> _pager.previous; distinct from product pagination; multi-page Store results physical fixture/retention pending |
| SUPSRC-0016 | buy_v2_catalogue.dart:2590 | onNext | Store-search result pager Next -> _pager.next; distinct from product pagination; multi-page Store results physical fixture/retention pending |
| SUPSRC-0017 | buy_v2_catalogue.dart:2591 | onRefresh | Store-search result Refresh -> _pager.refresh; physical Store-result refresh and retained product/search context pending |
| SUPSRC-0018 | buy_v2_catalogue.dart:2599 | onAction | Store-search error Try stores again -> _pager.retry; provider/error fixture and recovery pending; no product-pager pass substitution |
| SUPSRC-0019 | buy_v2_catalogue.dart:2694 | onOpenStore | Dedicated search Store-result open forwarder -> onOpenStore; same result component as SUPSRC-0013 but distinct entry/return context pending reconciliation |
| SUPSRC-0020 | buy_v2_catalogue.dart:3077 | onVisitProduct | Toolbar tools onVisitProduct forwarder; alias of SUPSRC-0011 through _CatalogueToolsMenu; Saved/Recently viewed destinations carry actual actions |
| SUPSRC-0021 | buy_v2_catalogue.dart:3470 | onFocus | Category-search semantic focus; direct accessibility activation pending; pointer category round106 is separate |
| SUPSRC-0022 | buy_v2_catalogue.dart:3471 | onSetText | Category-search semantic SetText; accessibility value/edit behaviour pending |
| SUPSRC-0023 | buy_v2_catalogue.dart:3557 | onClear | Category no-match Clear -> _clearQuery; parent recovery control; round106 evidence must distinguish keyboard-on/off variants before final qualification |
| SUPSRC-0024 | buy_v2_catalogue.dart:3801 | onClear | Keyboard-visible category empty wrapper forwards same Clear as0023; not an additional action; keyboard-visible fit remains separate acceptance condition |
| SUPSRC-0025 | buy_v2_catalogue.dart:3842 | onClear | Keyboard-hidden category Clear button forwarder; same action0023 with alternate layout; exact evidence reconciliation pending |
| SUPSRC-0026 | buy_v2_catalogue.dart:3895 | onClear | Compact keyboard category Clear forwarder; same action0023/0024; no independent journey |
| SUPSRC-0027 | buy_v2_catalogue.dart:4101 | onHighlightChanged | Pressed-state highlight animation hook; no independent destination; cancellation/reduced-motion visual behaviour not blanket-qualified |
| SUPSRC-0028 | buy_v2_catalogue.dart:4221 | onVisitProduct | Tools Recently viewed forwards product visitor; RECENT-ROUND45-02 entry and round45 product/Back; action lives on resulting product rows |
| SUPSRC-0029 | buy_v2_catalogue.dart:4234 | onVisitProduct | Tools Shopping settings forwards visitor; SETTINGS-ROUND47-01 entry and round49 nested returns; not another product button |
| SUPSRC-0030 | buy_v2_catalogue.dart:4331 | onOpenSavedProducts | Shopping settings Saved entry opens nested sheet; SETTINGS-ROUND49-04 product/Back subset; no provider persistence qualification |
| SUPSRC-0031 | buy_v2_catalogue.dart:4336 | onVisitProduct | Nested Saved visitor forwarded; alias0030/0041 actual product action; direct-return handler versus fallback must remain distinguished |
| SUPSRC-0032 | buy_v2_catalogue.dart:4337 | onOpenProduct | Nested Saved fallback pops selected product through settings; conditional handler path; no pass inferred from visitor-enabled branch |
| SUPSRC-0033 | buy_v2_catalogue.dart:4345 | onOpenRecentlyViewed | Shopping settings Recently viewed entry; SETTINGS-ROUND49-05 product/Back subset; shared history Clear excluded over original data |
| SUPSRC-0034 | buy_v2_catalogue.dart:4350 | onVisitProduct | Nested Recently viewed visitor forwarder; same actual row action0043; SETTINGS-ROUND49-05 subset |
| SUPSRC-0035 | buy_v2_catalogue.dart:4351 | onOpenProduct | Nested Recently viewed fallback pops selected product through settings; conditional no-visitor path pending reachability/evidence |
| SUPSRC-0036 | buy_v2_catalogue.dart:4914 | onTapOutside | Help search tap-outside unfocus; exact pointer-outside keyboard check pending |
| SUPSRC-0037 | buy_v2_catalogue.dart:5241 | onClose | Monthly basket close -> Navigator.pop; Close control versus AndroidBack evidence requires reconciliation; no purchase |
| SUPSRC-0038 | buy_v2_catalogue.dart:5242 | onSeeProducts | Monthly See products -> category all plus choose Quick/Scheduled notice; round46 evidence requires exact action mapping |
| SUPSRC-0039 | buy_v2_catalogue.dart:5244 | onAddToCart | Monthly Add -> session.addMonthlyBasket; MONTHLY-ROUND54-01 passed560-562 and cleanup568-570; actual provider fulfilment not qualified |
| SUPSRC-0040 | buy_v2_catalogue.dart:5285 | onClose | Saved sheet close -> Navigator.pop; explicit Close versus AndroidBack distinct; exact control evidence pending |
| SUPSRC-0041 | buy_v2_catalogue.dart:5286 | onOpenProduct | Saved product action chooses visitor or selected-ID fallback; SETTINGS-ROUND49-04 visitor subset; fallback not blanket-qualified |
| SUPSRC-0042 | buy_v2_catalogue.dart:5327 | onClose | Recently viewed close -> Navigator.pop; RECENT-ROUND53-02 close/cart subset; exact X versus other dismissal pending reconciliation |
| SUPSRC-0043 | buy_v2_catalogue.dart:5328 | onOpenProduct | Recently viewed product action chooses visitor or selected-ID fallback; SETTINGS-ROUND49-05 visitor subset; D015 Add rejection is separate |
| SUPSRC-0044 | buy_v2_catalogue.dart:5337 | onClear | Recently viewed Clear opens confirmation; confirming global original history deletion excluded for preservation; cancellation separate |
| SUPSRC-0045 | buy_v2_catalogue.dart:5452 | onOpenProduct | Full Store product callback forwards onOpenProduct; actual nested product/Back context requires exact evidence; no duplicate action at assignment |
| SUPSRC-0046 | buy_v2_catalogue.dart:5453 | onOpenCart | Full Store cart callback forwards current Store; mandatory Store identity/return acceptance; conditional missing-handler differs, no blanket pass |
| SUPSRC-0047 | buy_v2_catalogue.dart:5634 | onOrderForCollection | Store Order and Collect -> beginStoreCollection then full catalogue only if eligible; collection authentication/receipt cases remain blocked; no authorization inferred from CTA |
| SUPSRC-0048 | buy_v2_catalogue.dart:5641 | onAskStore | Public Store Ask -> selected ask-store product ID; Store Chat entry/Back tested subsets; real messages excluded |
| SUPSRC-0049 | buy_v2_catalogue.dart:5653 | onOpenProduct | Paged Store preview product -> openStoreProduct; actual preview card action; Store/product/Back evidence needs exact branch mapping |
| SUPSRC-0050 | buy_v2_catalogue.dart:5669 | onOpenProduct | Nonpaged/brand progressive preview -> openStoreProduct; alternate rendering branch; do not substitute paged preview evidence |
| SUPSRC-0051 | buy_v2_catalogue.dart:5738 | onAskStore | Other Store nested Ask bubbles exact product ID to parent; public Chat route/return evidence subset only; no send |
| SUPSRC-0052 | buy_v2_catalogue.dart:5744 | onOpenProduct | Other Store product callback forwarder; nested return context distinct from original Store; exact evidence reconciliation pending |
| SUPSRC-0053 | buy_v2_catalogue.dart:5745 | onStoreChanged | Other Store onStoreChanged forwarder; callback after actual Other Store tap5729; not standalone action |
| SUPSRC-0054 | buy_v2_catalogue.dart:5746 | onOpenStoreCart | Other Store cart callback forwarder retains current Store; nested cart identity/return acceptance pending exact evidence |
| SUPSRC-0055 | buy_v2_catalogue.dart:5748 | onOpenCart | Other Store cart fallback pops cart sentinel; conditional missing Store-specific handler; not separate visible button |
| SUPSRC-0056 | buy_v2_catalogue.dart:5773 | onOpenCart | Visible Store cart bar selects Store-specific callback or cart sentinel; D002 last-item removal remains open; cart entry/return separate |
| SUPSRC-0057 | buy_v2_catalogue.dart:5812 | onAskStore | Returned store-ID route recursively forwards Ask; alias0048/0051 conditional path, not standalone button |
| SUPSRC-0058 | buy_v2_catalogue.dart:5813 | onStoreChanged | Returned store-ID route forwards onStoreChanged; alias0053; conditional route path not blanket-qualified |
| SUPSRC-0059 | buy_v2_catalogue.dart:5814 | onOpenProduct | Returned store-ID route forwards product callback; alias0052; conditional route path not blanket-qualified |
| SUPSRC-0060 | buy_v2_catalogue.dart:5815 | onOpenCart | Returned store-ID route forwards generic cart callback; alias0055; preserve origin mapping |
| SUPSRC-0061 | buy_v2_catalogue.dart:5816 | onOpenStoreCart | Returned store-ID route forwards Store cart callback; alias0054; preserve Store identity |
| SUPSRC-0062 | buy_v2_catalogue.dart:6595 | onAction | Store preview Try products again -> _pager.retry; actual provider/error fixture and recovery unqualified |
| SUPSRC-0063 | buy_v2_catalogue.dart:6607 | onOpenProduct | Paged Store preview grid forwards product action0049; no independent action |
| SUPSRC-0064 | buy_v2_catalogue.dart:6731 | onOpenProduct | Full Store paged product entry unfocuses search then forwards product; keyboard+Store query/category/page retention must be qualified in that exact context |
| SUPSRC-0065 | buy_v2_catalogue.dart:6799 | onTapOutside | Store search tap-outside unfocus; exact pointer-outside keyboard check pending |
| SUPSRC-0066 | buy_v2_catalogue.dart:6881 | onOpenProduct | Full Store paged product forwards openProduct; same actual action0064; exact Store search/page/product Back needs evidence, not ordinary Shop pass |
| SUPSRC-0067 | buy_v2_catalogue.dart:6883 | onClose | Full Store paged Close -> Navigator.pop; explicit Close versus AndroidBack requires exact evidence reconciliation |
| SUPSRC-0068 | buy_v2_catalogue.dart:6949 | onOpenProduct | Full Store nonpaged product forwards openProduct; alternate source path to0066; no paged-source pass substitution |
| SUPSRC-0069 | buy_v2_catalogue.dart:6962 | onOpenCart | Full Store cart bar -> provided onOpenCart or cart sentinel; same parent0046, nested Store identity and return scope retained |
| SUPSRC-0070 | buy_v2_catalogue.dart:7260 | onClose | Saved header Close forwards0040; no second visible Close at assignment |
| SUPSRC-0071 | buy_v2_catalogue.dart:7304 | onOpen | Saved row Open -> product.id callback0041; SETTINGS-ROUND49-04 subset qualified; fallback remains conditional |
| SUPSRC-0072 | buy_v2_catalogue.dart:7305 | onRemove | Saved row Remove -> session.toggleSaved(product.id); isolated removal evidence must be distinguished from catalogue bookmark; original saved item preserved |
| SUPSRC-0073 | buy_v2_catalogue.dart:7375 | onClose | Recently viewed header Close forwards0042; single header action |
| SUPSRC-0074 | buy_v2_catalogue.dart:7424 | onOpen | Recently viewed row Open -> product.id callback0043; SETTINGS-ROUND49-05 visitor subset |
| SUPSRC-0075 | buy_v2_catalogue.dart:7425 | onAdd | Recently viewed row Add -> session.addProduct; RECENT-ROUND53-01 positive subset; RV6-D015 unavailable/closed rejection remains open |
| SUPSRC-0076 | buy_v2_catalogue.dart:7809 | onAddToCart | Monthly Add basket enabled only monthlyBasketCanAdd; same0039; MONTHLY-ROUND54-01 positive fixture subset, disabled and partial-capacity conditions separate |
| SUPSRC-0077 | buy_v2_catalogue.dart:7844 | onClose | Monthly header Close forwards0037; exact X versus Back reconciliation pending |
| SUPSRC-0078 | buy_v2_catalogue.dart:8520 | onKeep | Saved clear confirmation Keep -> false; SAVED-ROUND42-01 passed465-467; no deletion |
| SUPSRC-0079 | buy_v2_catalogue.dart:8521 | onClear | Saved clear confirmation Clear -> true then clearSavedProducts(destination); isolated Wholesale clear round17 qualified; do not delete original Shop saved data |
| SUPSRC-0080 | buy_v2_catalogue.dart:8752 | onOpenProduct | Progressive fitted card product callback forwarding; same parent card action, rendering/layout branch distinct |
| SUPSRC-0081 | buy_v2_catalogue.dart:8792 | onOpenProduct | Progressive lane catalogue product callback forwarding; same parent card action, lane scroll/return acceptance distinct |
| SUPSRC-0082 | buy_v2_catalogue.dart:9193 | onNotification | Horizontal lane ScrollNotification -> _loadNextPage; automatic loading, not tap; boundary paging/retention and failure/retry are acceptance conditions |
| SUPSRC-0083 | buy_v2_catalogue.dart:9215 | onOpenProduct | Horizontal lane product card callback forwarding; same0081; source assignment not another journey |
| SUPSRC-0084 | buy_v2_catalogue.dart:10043 | onHighlightChanged | Pressed-state highlight hook; no separate navigation; parent action coverage retained |
| SUPSRC-0085 | buy_v2_catalogue.dart:10420 | onEdit | Inline quantity Edit -> showBuyV2QuantityEditor; exact card variant and editor trigger require evidence; cart editor round115 cannot qualify every card |
| SUPSRC-0086 | buy_v2_catalogue.dart:10422 | onDecrease | Inline quantity decrease -> session.decrease; MOQ-to-zero and last-item return acceptance separate; D002 still open |
| SUPSRC-0087 | buy_v2_catalogue.dart:10423 | onIncrease | Inline quantity increase -> session.increase; max/availability/pack rules require exact context; no product-detail pass substitution |
| SUPSRC-0088 | buy_v2_catalogue.dart:10969 | onEdit | Grid quantity Edit carries beforeCartChange guard to editor; unguarded and guarded rejection cases distinct; exact device fixture/evidence pending |
| SUPSRC-0089 | buy_v2_catalogue.dart:10975 | onDecrease | Grid decrease computes zero at MOQ then awaits beforeCartChange; guard rejection and Store/cart retention must be tested separately |
| SUPSRC-0090 | buy_v2_catalogue.dart:10983 | onIncrease | Grid increase uses session.increase without guard or guarded setCartQuantity; explicit guard branch unqualified from consumer stepper passes |
| SUPSRC-0091 | buy_v2_design.dart:228 | onNotification | ScrollMetricsNotification updates vertical indicator only at depth0 vertical; framework layout hook, not independent action; screen-fit verification remains |
| SUPSRC-0092 | buy_v2_design.dart:233 | onNotification | ScrollNotification duplicates0091 indicator update; not new action; horizontal lane isolation is visual acceptance condition |
| SUPSRC-0093 | buy_v2_design.dart:354 | onNotification | ScrollNotification schedules cart avoidance layout; framework hook, not independent tap; cart overlap/keyboard/large-text conditions remain |
| SUPSRC-0094 | buy_v2_design.dart:359 | onNotification | SizeChangedLayoutNotification schedules same cart avoidance0093; no additional journey |
| SUPSRC-0095 | buy_v2_design.dart:1591 | onPointerDown | Press feedback pointer-down; no independent journey; multi-pointer/cancel visual behaviour pending |
| SUPSRC-0096 | buy_v2_design.dart:1594 | onPointerUp | Press feedback pointer-up; no independent journey; parent action controls remain scoped |
| SUPSRC-0097 | buy_v2_design.dart:1595 | onPointerCancel | Press feedback pointer-cancel; cancellation visual behaviour pending |
| SUPSRC-0098 | buy_v2_scanner.dart:150 | onDetect | Collection camera onDetect -> _detect; conditional public Buy caller views11090-11095 exists inside collection order view. Collection authentication/state fixture blocked; correct earlier blanket source_unreachable classification. No physical detection pass |
| SUPSRC-0099 | buy_v2_scanner.dart:733 | onDetect | Product scanner onDetect trims barcode and invokes _complete unless manualOpen; source_unreachable public Buy per round74; no decoding/permission pass |
| SUPSRC-0100 | buy_v2_scanner.dart:757 | onClose | Scanner Close -> Navigator.pop; public Buy unreachable round74; distinct Workspace scope excluded |
| SUPSRC-0101 | buy_v2_scanner.dart:758 | onTorch | Scanner Torch -> _changeCameraControl(torch:true); public Buy unreachable round74; no camera hardware qualification |
| SUPSRC-0102 | buy_v2_scanner.dart:759 | onCamera | Scanner switch Camera -> _changeCameraControl(torch:false); public Buy unreachable round74; no hardware qualification |
| SUPSRC-0103 | buy_v2_scanner.dart:760 | onScanNow | Scanner Scan now -> _scanNow; public Buy unreachable round74; no barcode/provider qualification |
| SUPSRC-0104 | buy_v2_scanner.dart:761 | onEnterCode | Scanner Enter code -> _enterCode; public Buy unreachable round74; manual validation descendants not device-passed |
| SUPSRC-0105 | buy_v2_scanner.dart:788 | onClose | visibleForTesting overlay wrapper forwards Close0100; test helper, not public route/action |
| SUPSRC-0106 | buy_v2_scanner.dart:789 | onTorch | visibleForTesting overlay wrapper forwards Torch0101; test helper, not public route/action |
| SUPSRC-0107 | buy_v2_scanner.dart:790 | onCamera | visibleForTesting overlay wrapper forwards Camera0102; test helper, not public route/action |
| SUPSRC-0108 | buy_v2_scanner.dart:791 | onScanNow | visibleForTesting overlay wrapper forwards Scan now0103; test helper, not public route/action |
| SUPSRC-0109 | buy_v2_scanner.dart:792 | onEnterCode | visibleForTesting overlay wrapper forwards Enter code0104; test helper, not public route/action |
| SUPSRC-0110 | buy_v2_scanner.dart:848 | onScanNow | Scanner panel Scan now forwarder0103; same action; public Buy unreachable round74 |
| SUPSRC-0111 | buy_v2_scanner.dart:849 | onEnterCode | Scanner panel Enter code forwarder0104; same action; public Buy unreachable round74 |
| SUPSRC-0112 | buy_v2_scanner.dart:1001 | onScanNow | visibleForTesting action-panel Scan now forwarder; test helper, not public action |
| SUPSRC-0113 | buy_v2_scanner.dart:1002 | onEnterCode | visibleForTesting action-panel Enter code forwarder; test helper, not public action |
| SUPSRC-0114 | buy_v2_screen.dart:966 | onOpenRoute | Global profile onOpenRoute -> context.push(route); actual child routes must be inventoried; ACCOUNT-ROUND111-01 Orders subset only, not every shared destination |
| SUPSRC-0115 | buy_v2_screen.dart:992 | onReturn | Stale procurement scope recovery Return -> _exitBuy; authoritative account/Store switch fixture needed; public consumer passes do not qualify procurement recovery |
| SUPSRC-0116 | buy_v2_screen.dart:1010 | onPopInvokedWithResult | Root Back dispatch covers navigation/search/session branches; individual Back evidence retained; Mool overlay and root-exit branches require reconciliation |
| SUPSRC-0117 | buy_v2_screen.dart:1071 | onOpenChanged | Search-band open/close state -> _searchOpen; physical round125 open/clear/Done; product Back wrong surface RV6-D018 remains open |
| SUPSRC-0118 | buy_v2_screen.dart:1073 | onLocation | Location -> catalogue area if paged, address sheet otherwise; two branches, current paged area evidence not nonpaged address-entry proof |
| SUPSRC-0119 | buy_v2_screen.dart:1076 | onAccount | Account -> _openBuyProfile; shared profile ACCOUNT-ROUND111-01 Orders subset; shared child routes require own inventory |
| SUPSRC-0120 | buy_v2_screen.dart:1138 | onOpenStore | Dedicated search Store result -> _openPartnerCatalogue; same result action0019, exact origin query/page/Back qualification pending |
| SUPSRC-0121 | buy_v2_screen.dart:1153 | onParkingChanged | Mini-cart parking callback updates _miniCartParked; parent drag/park action; parked rail/cart return and overlap require exact device evidence |
| SUPSRC-0122 | buy_v2_screen.dart:1161 | onPositionChanged | Mini-cart position callback saves Offset; framework/gesture state, not separate button; drag bounds/keyboard/rotation acceptance pending |
| SUPSRC-0123 | buy_v2_screen.dart:1495 | onPointerDown | Quick tracker pointer-down pauses collapse timer; held/multi-pointer timer interaction pending |
| SUPSRC-0124 | buy_v2_screen.dart:1499 | onPointerUp | Quick tracker pointer-release handler; timer resumption exact physical state pending |
| SUPSRC-0125 | buy_v2_screen.dart:1500 | onPointerCancel | Quick tracker pointer-cancel handler; interruption and timer behaviour pending |
| SUPSRC-0126 | buy_v2_screen.dart:1584 | onMinimizedChanged | Tracker Minimize -> _setQuickTrackerExpanded(!value); distinct from Hide; exact minimized/reopen and timeout acceptance pending |
| SUPSRC-0127 | buy_v2_screen.dart:1586 | onHiddenChanged | Tracker Hide cancels timer, hides/minimizes, unkeeps, closes picker and remembers preferences; TRACK-004 passes Hide subset; restore/persistence contexts separate |
| SUPSRC-0128 | buy_v2_screen.dart:1596 | onSoundChanged | Tracker sound toggle -> _setArrivalSound; TRACK-008 toggle UI only; real playback, preparation error, arrival event and permission conditions unqualified |
| SUPSRC-0129 | buy_v2_screen.dart:1598 | onKeepOnScreen | Tracker Keep toggles kept, remembers and reschedules collapse; TRACK-007 toggle subset; long timer/held-pointer and relaunch conditions separate |
| SUPSRC-0130 | buy_v2_screen.dart:1606 | onOpen | Tracker body Open -> openDeliveryTracking(order.id); TRACK-009 selected order subset; all delivery/split identity cases not blanket-qualified |
| SUPSRC-0131 | buy_v2_screen.dart:1669 | onPositionChanged | Compact parked-cart position callback is no-op; parent parked cart action; no independent position-persistence promise |
| SUPSRC-0132 | buy_v2_screen.dart:1754 | onOpenMool | Shared rail Mool -> _openGlobalMool; Buy exit/return boundary must be reconciled; downstream unrelated module excluded |
| SUPSRC-0133 | buy_v2_screen.dart:1755 | onOpenAction | Shared rail Action -> _openGlobalAction; Buy boundary/return needs evidence; downstream workspace actions excluded |
| SUPSRC-0134 | buy_v2_screen.dart:1756 | onOpenChat | Shared rail Chat -> _openShopChat; CHAT rounds117-122 inbox navigation subsets; every contextual thread remains separate |
| SUPSRC-0135 | buy_v2_screen.dart:1758 | onPreviousLocalAction | Shared rail previous local action -> _moveBuyLocal(-1); alternate navigation affordance, not automatically passed by tab taps |
| SUPSRC-0136 | buy_v2_screen.dart:1759 | onNextLocalAction | Shared rail next local action -> _moveBuyLocal(1); alternate navigation affordance, retained destination and boundaries pending |
| SUPSRC-0137 | buy_v2_screen.dart:2080 | onAskStore | Partner catalogue Ask -> _openStoreQuestion; alias0048 Store Chat action; preserve selected Store/draft/Back, no message |
| SUPSRC-0138 | buy_v2_screen.dart:2081 | onStoreChanged | Partner catalogue Store change -> _rememberStoreBrowse; alias0053 callback after Other Store action; identity anchor/late return acceptance separate |
| SUPSRC-0139 | buy_v2_screen.dart:2082 | onOpenProduct | Partner product -> _openStoreProduct; alias0066 preview/full Store paths; exact parent return retained in per-journey evidence |
| SUPSRC-0140 | buy_v2_screen.dart:2083 | onOpenStoreCart | Store-specific cart -> _openStoreProduct(store,cartEntry:true); nested identity/Back separate; D002 last-item exit remains open |
| SUPSRC-0141 | buy_v2_screen.dart:2086 | onOpenCart | Generic partner cart opens scope Shop/Wholesale/Medicine based on product destination; fallback path differs0140; Medicine outside public Shop audit |
| SUPSRC-0142 | buy_v2_screen.dart:2157 | onReturn | Nested stale procurement Return pops route false; account/Store stale-scope fixture required; no ordinary consumer substitute |
| SUPSRC-0143 | buy_v2_screen.dart:2178 | onPopInvokedWithResult | Embedded Store product/cart Back dispatch; Store/cart defect and retention evidence remain separate; conditional navigation/compared-product states pending |
| SUPSRC-0144 | buy_v2_screen.dart:2222 | onProductReturn | Nested procurement purchase recovery product Return pops route false; denied/revised offer context and original Store require exact fixture |
| SUPSRC-0145 | buy_v2_screen.dart:2243 | onReturn | Nested product explicit Return pops false with Back-to-Store label; exact header action distinct from AndroidBack; parent contexts Saved/Recent/Store retained separately |
| SUPSRC-0146 | buy_v2_screen.dart:2247 | onAskSeller | Nested product Ask seller -> _openProductQuestion; thread/draft/return context separate from root product; no send |
| SUPSRC-0147 | buy_v2_screen.dart:2249 | onVisitComparisonProduct | Nested comparison visitor opens Store product with Compare suppliers return label; populated comparable-supplier fixture B002 remains blocker |
| SUPSRC-0148 | buy_v2_screen.dart:2259 | onOpenPartnerCatalogue | Nested product Visit partner -> _openPartnerCatalogue; nested Store identity and Back branch needs exact evidence |
| SUPSRC-0149 | buy_v2_screen.dart:2275 | onOpenCart | Nested product cart bar opens destination-specific session cart; scope/Back/retained product acceptance distinct from root cart |
| SUPSRC-0150 | buy_v2_screen.dart:2408 | onPopInvokedWithResult | Chat return PopScope dispatcher; CHAT-005 and shared Chat rounds117-119 scoped Back evidence; each source context not blanket-passed |
| SUPSRC-0151 | buy_v2_screen.dart:2422 | onReturn | Procurement scope recovery onReturn forwarded to unavailable-state Back to Store; aliases0115/0142 by parent; authentication/Store-switch qualification pending |
| SUPSRC-0152 | buy_v2_screen.dart:2463 | onReturn | Procurement purchase recovery Return branches checkout->same-scope cart, product->parent or goBack, other->_exitBuy; each conditional context remains explicit dependency |
| SUPSRC-0153 | buy_v2_screen.dart:2489 | onRetry | Linked product unavailable Retry -> openLinkedProduct same ID; exact failed-load/recovery fixture and current-offer authority not qualified by normal product entry |
| SUPSRC-0154 | buy_v2_screen.dart:2490 | onReturn | Linked product unavailable Return -> session.goBack; source recovery branch distinct from general navigation; exact device evidence pending reconciliation |
| SUPSRC-0155 | buy_v2_screen.dart:2507 | onOpenOrderHelp | Orders list Help -> _openOrderHelpChat; retained existing order Help subsets; actual order identity and unsent draft preservation required, no send |
| SUPSRC-0156 | buy_v2_screen.dart:2522 | onVisitProduct | Catalogue tools product visitor -> nested _openStoreProduct return label; Saved/Recent round49 subsets, no standalone callback action |
| SUPSRC-0157 | buy_v2_screen.dart:2525 | onOpenStore | Ordinary catalogue Store result -> _openPartnerCatalogue; alias0013 differs dedicated search0120 origin; exact query/page/Back required |
| SUPSRC-0158 | buy_v2_screen.dart:2531 | onAskSeller | Root product Ask seller -> _openProductQuestion; product/Store thread identity and return evidence scoped; no real messages |
| SUPSRC-0159 | buy_v2_screen.dart:2532 | onVisitComparisonProduct | Root Compare visitor -> nested Store product with Compare suppliers label; populated fixture B002 unresolved; root versus nested parent distinct |
| SUPSRC-0160 | buy_v2_screen.dart:2535 | onOpenPartnerCatalogue | Root product Visit partner -> _openPartnerCatalogue; original Store round evidence only; repeated nested return not blanket-qualified |
| SUPSRC-0161 | buy_v2_screen.dart:2541 | onBrowseStore | Cart Browse Store enabled only for scoped Store anchor; _openPartnerCatalogue(anchor); stale/cross-scope anchor and exact Back acceptance pending |
| SUPSRC-0162 | buy_v2_screen.dart:2544 | onBrowseMore | Cart Browse more returns Offers if active else destination from cart scope; Shop/Wholesale/aggregate branches distinct, Medicine outside; exact retained data required |
| SUPSRC-0163 | buy_v2_screen.dart:2569 | onRestoreDeliveryStatus | Tracking restore-delivery callback -> _deliveryStatusRestore(session); hidden/selected-order preference restoration per physical branch, no live-provider pass |
| SUPSRC-0164 | buy_v2_screen.dart:2571 | onOpenOrderHelp | Tracking Help -> _openOrderHelpChat; seeded order-specific Help evidence; live service and actual sending excluded |
| SUPSRC-0165 | buy_v2_screen.dart:2579 | onRestoreDeliveryStatus | Assist view renders same TrackingView with same delivery restore; legacy name is alias, but entry/return context needs separate proof |
| SUPSRC-0166 | buy_v2_screen.dart:2581 | onOpenOrderHelp | Assist-tracking Help alias0164; no new Help button solely from callback assignment; contextual return unqualified where not tested |
| SUPSRC-0167 | buy_v2_screen.dart:2593 | onOpenOrderHelp | Recovery Help -> _openOrderHelpChat; recovery identity and original route branch distinct; D010 recovery rail issue remains open |
| SUPSRC-0168 | buy_v2_screen.dart:2886 | onEnd | Animation-end cart avoidance scheduling; not separate tap/destination; overlap visual coverage must stay parent-specific |
| SUPSRC-0169 | buy_v2_screen.dart:2943 | onEnd | Navigation animation-end cart avoidance scheduling; not separate tap/destination; no universal fitment claim |
| SUPSRC-0170 | buy_v2_shop_chat.dart:624 | onBack | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0171 | buy_v2_shop_chat.dart:626 | onRetry | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0172 | buy_v2_shop_chat.dart:627 | onOpenAll | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0173 | buy_v2_shop_chat.dart:634 | onBack | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0174 | buy_v2_shop_chat.dart:635 | onOpenInfo | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0175 | buy_v2_shop_chat.dart:636 | onDispatch | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0176 | buy_v2_shop_chat.dart:637 | onOpenContext | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0177 | buy_v2_shop_chat.dart:644 | onBack | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0178 | buy_v2_shop_chat.dart:645 | onDispatch | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0179 | buy_v2_shop_chat.dart:646 | onOpenContext | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0180 | buy_v2_shop_chat.dart:679 | onBack | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0181 | buy_v2_shop_chat.dart:680 | onOpenAll | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0182 | buy_v2_shop_chat.dart:688 | onClear | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0183 | buy_v2_shop_chat.dart:724 | onClearSearch | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0184 | buy_v2_shop_chat.dart:728 | onShowAll | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0185 | buy_v2_shop_chat.dart:732 | onChooseConversation | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0186 | buy_v2_shop_chat.dart:733 | onRetry | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0187 | buy_v2_shop_chat.dart:734 | onOpenAll | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0188 | buy_v2_shop_chat.dart:1712 | onRetry | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0189 | buy_v2_shop_chat.dart:1922 | onRetry | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0190 | buy_v2_shop_chat.dart:1923 | onOpenAll | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0191 | buy_v2_shop_chat.dart:2020 | onRetry | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0192 | buy_v2_shop_chat.dart:2202 | onClose | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0193 | buy_v2_shop_chat.dart:2203 | onReply | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0194 | buy_v2_shop_chat.dart:2210 | onReact | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0195 | buy_v2_shop_chat.dart:2217 | onCopy | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0196 | buy_v2_shop_chat.dart:2218 | onForward | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0197 | buy_v2_shop_chat.dart:2230 | onBack | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0198 | buy_v2_shop_chat.dart:2231 | onOpenInfo | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0199 | buy_v2_shop_chat.dart:2232 | onVoiceCall | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0200 | buy_v2_shop_chat.dart:2237 | onVideoCall | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0201 | buy_v2_shop_chat.dart:2242 | onMore | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0202 | buy_v2_shop_chat.dart:2258 | onInfo | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0203 | buy_v2_shop_chat.dart:2262 | onSearch | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0204 | buy_v2_shop_chat.dart:2267 | onNotifications | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0205 | buy_v2_shop_chat.dart:2272 | onSafety | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0206 | buy_v2_shop_chat.dart:2283 | onClose | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0207 | buy_v2_shop_chat.dart:2327 | onForward | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0208 | buy_v2_shop_chat.dart:2398 | onTapField | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0209 | buy_v2_shop_chat.dart:2405 | onCancelReply | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0210 | buy_v2_shop_chat.dart:2406 | onToggleEmoji | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0211 | buy_v2_shop_chat.dart:2419 | onEmoji | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0212 | buy_v2_shop_chat.dart:2427 | onAttachment | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0213 | buy_v2_shop_chat.dart:2442 | onCamera | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0214 | buy_v2_shop_chat.dart:2447 | onSend | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0215 | buy_v2_shop_chat.dart:2448 | onVoice | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0216 | buy_v2_shop_chat.dart:3397 | onClose | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0217 | buy_v2_shop_chat.dart:3523 | onSend | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0218 | buy_v2_shop_chat.dart:3524 | onVoice | Legacy BuyV2ShopChatView subtree; sole application constructor caller social/social_v2_consumer.dart1143. Public Buy uses BuyV2ChatRouteAdapter -> shared ChatInboxScreen/ChatThreadScreen; source_unreachable from audited public Buy route, not a device pass. Shared equivalent action must be covered separately; no real send/call/forward authorized. |
| SUPSRC-0219 | buy_v2_views.dart:831 | onAdd | Product inline Add -> addProduct; same owned panel action; product pack/orderability and actual cart identity qualification scoped to tested SKU |
| SUPSRC-0220 | buy_v2_views.dart:832 | onEdit | Product inline Edit -> quantity editor; product-entry editor distinct from cart; quantity/keyboard/cancel rules require exact device evidence |
| SUPSRC-0221 | buy_v2_views.dart:837 | onDecrease | Product inline decrease -> session.decrease; MOQ-to-zero and connected navigation separate |
| SUPSRC-0222 | buy_v2_views.dart:838 | onIncrease | Product inline increase -> session.increase; QTY-ROUND115-04 product plus subset; other SKU/MOQ/availability not blanket-qualified |
| SUPSRC-0223 | buy_v2_views.dart:905 | onOpenWorkspace | Wholesale unverified-business Workspace CTA -> workspace choose; boundary/Back only within Buy audit; downstream workspace/auth blocked or excluded |
| SUPSRC-0224 | buy_v2_views.dart:917 | onOpenPartnerCatalogue | Wholesale decision panel partner-catalogue forwarder; actual Store visit parent callback, no independent action at assignment |
| SUPSRC-0225 | buy_v2_views.dart:1199 | onReview | Product Write review -> review sheet; eligibility explanation separate from positive submit; eligible-purchase B003 remains unresolved |
| SUPSRC-0226 | buy_v2_views.dart:1201 | onReport | Product Report -> report sheet only if canReportProduct; duplicate/report authority and real submission remain separate, no provider pass |
| SUPSRC-0227 | buy_v2_views.dart:1213 | onAskSeller | Product quick-actions Ask seller forwards root/nested callback; same action0158/0146, thread identity/draft/Back context preserved |
| SUPSRC-0228 | buy_v2_views.dart:1214 | onVisitProduct | Product quick-actions Compare visitor forwards to comparison; same0235/0236 and0159/0147; populated fixture B002 unresolved |
| SUPSRC-0229 | buy_v2_views.dart:1234 | onAdd | Wholesale dock Add -> addProduct; same product decision but separate dock layout/context; actual MOQ/orderability rules retained |
| SUPSRC-0230 | buy_v2_views.dart:1235 | onEdit | Wholesale dock Edit -> quantity editor; same editor contract with Wholesale pack/MOQ; exact device case required |
| SUPSRC-0231 | buy_v2_views.dart:1236 | onDecrease | Wholesale dock decrease -> session.decrease; MOQ and zero boundary distinct from consumer single-item tests |
| SUPSRC-0232 | buy_v2_views.dart:1237 | onIncrease | Wholesale dock increase -> session.increase; minimum/max/availability conditions not inferred from retail |
| SUPSRC-0233 | buy_v2_views.dart:1238 | onRetryOffer | Wholesale Retry offer -> refreshProductFacts(product.id); provider failed/stale revision fixture and recovery unqualified |
| SUPSRC-0234 | buy_v2_views.dart:1240 | onOpenWorkspace | Wholesale dock Workspace CTA -> workspace choose; alias0223 separate visible placement; boundary/Back only, no workspace implementation |
| SUPSRC-0235 | buy_v2_views.dart:1457 | onVisitProduct | Compare action opens comparison sheet with visitor; alias0228, not another independent Compare button |
| SUPSRC-0236 | buy_v2_views.dart:1606 | onVisitProduct | Comparison modal forwards visitor to sheet; same0235, no independent action |
| SUPSRC-0237 | buy_v2_views.dart:1909 | onOpenProduct | Comparison result card opens matching offer while !_opening; populated offer fixture B002 required; no empty-comparison pass substitution |
| SUPSRC-0238 | buy_v2_views.dart:2385 | onRetry | Wholesale signal Retry -> _loadSignal; adapter/provider signal error and recovery unavailable unless exact fixture supplied |
| SUPSRC-0239 | buy_v2_views.dart:2874 | onAdd | Wholesale purchase row Add forwards0229; same dock action, not extra tap |
| SUPSRC-0240 | buy_v2_views.dart:2875 | onEdit | Wholesale purchase row Edit forwards0230; same dock action |
| SUPSRC-0241 | buy_v2_views.dart:2876 | onDecrease | Wholesale purchase row decrease forwards0231; same dock action |
| SUPSRC-0242 | buy_v2_views.dart:2877 | onIncrease | Wholesale purchase row increase forwards0232; same dock action |
| SUPSRC-0243 | buy_v2_views.dart:3529 | onInteractionEnd | B-008 / MEDIA-ROUND75-02; automatic reset at scale <=1.01, same zoom journey; no additional device pass |
| SUPSRC-0244 | buy_v2_views.dart:3679 | onPageChanged | B-008 / MEDIA-ROUND75-01 and 08; gallery paging and active-media selection; no additional device pass |
| SUPSRC-0245 | buy_v2_views.dart:4824 | onPopInvokedWithResult | Eligible review descendant B003 round91; device unverified |
| SUPSRC-0246 | buy_v2_views.dart:4920 | onFocus | Eligible review descendant B003 round91; device unverified |
| SUPSRC-0247 | buy_v2_views.dart:4921 | onSetText | Eligible review descendant B003 round91; device unverified |
| SUPSRC-0248 | buy_v2_views.dart:6166 | onDeleted | Alias of SUP-GST-DELETE-01 round94; same action, not an extra journey |
| SUPSRC-0249 | buy_v2_views.dart:7652 | onSelect | Checkout address choice Select -> chooseAddress(address.id); exact checkout chooser context distinct from general address sheet; retained order/address identity required |
| SUPSRC-0250 | buy_v2_views.dart:7653 | onEdit | Checkout address choice Edit -> add-address form with existingAddress; exact nested checkout return separate from general address edit |
| SUPSRC-0251 | buy_v2_views.dart:8832 | onViewInvoice | Confirmed split-order invoice opens exact order object; positive confirmation B011 blocked; historical Orders invoice pass does not qualify this caller |
| SUPSRC-0252 | buy_v2_views.dart:11095 | onDetected | Collection tracking camera detection -> _detected(raw); conditional public Buy caller confirms camera reachability when eligible state exists; collection auth/ready challenge fixture required; unverified, not unreachable |
| SUPSRC-0253 | buy_v2_views.dart:11282 | onOpenOrderHelp | Collection tracking Help forwards selected order; collection order state/identity and return fixture blocked; general delivery Help not substitute |
| SUPSRC-0254 | buy_v2_views.dart:11847 | onOpenSupport | Manage-order resolution Support binds onOpenOrderHelp(order); exact selected historical order and sheet return required; provider actions remain excluded |
| SUPSRC-0255 | buy_v2_views.dart:11932 | onOpenSupport | Resolution sheet Support forwards0254; same button; no independent action |
| SUPSRC-0256 | buy_v2_views.dart:13020 | onEdit | Legacy Buy account address reminder Edit -> address sheet; actual shared profile entry differs; legacy account route reachability remains unresolved |
| SUPSRC-0257 | buy_v2_views.dart:14531 | onEdit | Address-sheet row Edit passes exact existingAddress; round57 isolated edit/save subset; original Home/Work preserved; each entry/Back context separate |
| SUPSRC-0258 | buy_v2_views.dart:14536 | onDelete | Address row Delete opens confirmation; isolated round57 removal and prior cancel subset; existing-order snapshot preservation remains required; original addresses not deleted |
| SUPSRC-0259 | buy_v2_views.dart:14875 | onSubmit | Add/edit address form Submit -> saveToExistingOwner; isolated round57 save subset; request-recipient and process-death variants unqualified |
| SUPSRC-0260 | buy_v2_views.dart:15170 | onFocusChange | Address focus reveal hook; ADDR form keyboard evidence retained; every field and accessibility focus path still needs explicit reconciliation |
| SUPSRC-0261 | buy_v2_views.dart:15766 | onEdit | Owned product compact stepper Edit forwards0220; same actual quantity-editor action; compact layout is acceptance condition |
| SUPSRC-0262 | buy_v2_views.dart:15767 | onDecrease | Owned product compact stepper decrease forwards0221; same actual action; MOQ boundary separate |
| SUPSRC-0263 | buy_v2_views.dart:15768 | onIncrease | Owned product compact stepper increase forwards0222; same actual action; availability/max boundary separate |
| SUPSRC-0264 | buy_v2_views.dart:15970 | onEdit | Expanded purchase-row stepper Edit forwards caller; shared retail/Wholesale panel, each caller context retained |
| SUPSRC-0265 | buy_v2_views.dart:15972 | onDecrease | Expanded purchase-row decrease forwards caller; not extra independent action; guard/MOQ criteria per parent |
| SUPSRC-0266 | buy_v2_views.dart:15973 | onIncrease | Expanded purchase-row increase forwards caller; not extra independent action; guard/availability per parent |
| SUPSRC-0267 | buy_v2_views.dart:17024 | onSelect | Coupon/payment-benefit Select -> chooseCartBenefit keyed id+sourceId; existing COUPON subsets; exact provider/amount qualification remains separate |
| SUPSRC-0268 | buy_v2_views.dart:17029 | onRemove | Coupon/payment-benefit Remove -> removeCartBenefit(kind,destination); source/destination isolation and removal conditions need exact evidence; no blanket selection-pass substitution |
| SUPSRC-0269 | buy_v2_views.dart:19701 | onHighlightChanged | Legacy Assist pressed highlight only; parent reachability pending |
| SUPSRC-0270 | buy_v2_views.dart:19780 | onHighlightChanged | Legacy Assist channel pressed highlight only; parent reachability pending |
| SUPSRC-0271 | buy_v2_views.dart:20024 | onHighlightChanged | ShareChoice highlight visual feedback only; Share/Copy actions separately pending; no extra journey |

## Round 97 - media callback reconciliation

Source-only inspection of buy_v2_views.dart lines 3461-3705 binds SRC-0293 and SUPSRC-0243/0244 to the existing eight B-008 media descendants. Zoom allows scale 1 to 2.5, enables panning only above 1.01, exposes Reset while zoomed and honors disabled animations during reset. Gallery paging is enabled only with multiple media and passes active-page state to the media builder. These are source behaviors, not device-qualified results. Actual supplier image/video assets remain absent; no illustration-based pass substitutes for supplier decoding, fit, paging or playback. No new defect, device capture or distinct journey is added. Original callback inventory now has 143 classified and 384 unclassified references; supplemental references are aliases/conditional controls, not a unique-journey denominator.

## Round 98 - nonempty cart Browse more on Redmi

Captures 790-794 physically reviewed. Empty Scheduled Shop basket was seeded with one wheat item INR279. Cart Browse more products returned to Scheduled catalogue with quantity and subtotal retained. Removed only that isolated item afterward; basket empty and saved count 1 retained. CART-ROUND98-01 qualifies the Shop nonempty Browse more control (SRC-0313); Wholesale/all-cart variants, Android Back and relaunch are not inferred. No new defect, order, message or implementation. Totals: 794 physical captures, 796 evidence rows, 491 action rows, 393 device passes, 17 distinct defects. Inventory remains incomplete.

## Round 99 - Offers controls and direct promotion entry

Captures 795-802 reviewed on Redmi. 796 and 800 are transition frames; settled 797 and 801 establish the destinations, not failures. Close categories retains All categories and paneer promotion; tapping promotion title opens paneer46 INR92/200g; Android Back restores same promotion/grid. Empty basket remains unchanged. Three device checks added. SRC-0001 through0012 reconciled to actual source branches, forwarding, existing checks and explicit gaps. Finite/live branch, final Next boundary and provider Retry are not passed. Original source references now 155 classified, 372 unclassified; these are not unique journey counts. Totals: 802 captures, 804 evidence rows, 494 action rows, 396 device passes, 17 defects. Initial source read failed on default Windows encoding before any write; bounded UTF-8 read succeeded under standing parser-recovery authority.

## Round 100 - area scope controls and current-location failure

Captures 803-809 reviewed. Offers header area opens sheet; National delivery and In this area draft chips switch correctly. Use current location yields visible Area search unavailable plus Try again (B-001); Retry retains usable failure sheet. X returns to unchanged paneer promotion/grid and empty basket. No area selected, permission change, successful lookup, transaction or implementation. Four UI passes and one blocked-provider check added; no new defect. SRC-0013 through0027 reconciled with exact conditional/forwarded controls; footer area is not passed from header entry evidence. Totals: 809 captures, 811 evidence rows, 499 action rows, 400 device passes, 17 defects. Original source index: 170 classified, 357 unclassified; not a unique-journey denominator.

## Round 101 - sale-mode and search action reconciliation

Source-only review of catalogue callbacks SRC-0028 through0041 distinguishes sale-selector swipe from product-card lane scrolling, Semantics activation from pointer taps, and forwarding callbacks from unique actions. Existing Shop Quick/Scheduled and Saved entry evidence is linked; wholesale modes, exact search-store entry, recent/suggested query actions, Search all, account return and intent dismissal remain explicitly unverified until their own evidence is reconciled. Clear recent searches remains excluded to preserve original history. Shop/Wholesale never reach the alternate owned-feature filter handler because they return the sale selector first. No new device pass, capture or defect. Original source index now 184 classified and 343 unclassified; classification includes pending actions and does not mean tested. Unique journey denominator remains incomplete.

## Round 102 - category, tools and settings reconciliation

Source-only reconciliation of SRC-0042 through0068 links existing Settings rounds47/49/50 and tool-entry rounds45/46/54 to the actual callbacks. No repeat device passes added. Category search suffix Clear, empty-state Clear, picker X/choice, accessibility Semantics activation, active-order tool destination, settings unavailable/busy and zero-history states remain explicit gaps. Medicine prescriptions are outside public Shop/Wholesale. Shared chrome and row callbacks are forwarding references, not extra journeys. Original source index now 211 classified, 316 unclassified. Device totals remain 809 captures, 499 action rows, 400 device passes, 17 defects; unique journey inventory remains incomplete.

## Round 103 - Help, history, alerts and Store control reconciliation

SRC-0069 through0092 mapped to exact existing Help, Recently viewed, Alerts, Store and collection evidence. Known defects remain failures; Back does not qualify distinct X buttons; category selection does not qualify All products; keyboard dismissal does not qualify Submit. Clear history preserves the existing blocked disposition. Live alert recovery and authenticated collection remain unqualified. No new capture, device pass or defect. Original source index now 235 classified and 292 unclassified. Classification includes explicit pending/blocked controls, not completed journeys. Audit totals unchanged.

## Round 104 - remaining catalogue callbacks

SRC-0093 through0136 reconciled. All 136 original catalogue callback references now have evidence or explicit conditional/pending disposition; this does not close all catalogue journeys. Source1818-1844 selects paged catalogue except Saved/monthly; source8043-8047 requires no Saved/query/category/intent for promotion rails. Alternate promotion, featured and history rails are not assumed exercised by ordinary paged grid or tools sheets. Saved, monthly and recent-sheet evidence linked without duplicate passes. Screen-reader activation, stale offers, quantity edit, alternate controls and provider recovery remain unverified. No device action or source change. Original full index now 279 classified, 248 unclassified; supplemental/shared inventory remains separate. Prior round103 pre-commit observation ordering error is retained: commit/push proceeded before collecting terminal gate output; subsequent poll confirmed exit0 and handoff passed. No claim that ordering was correct.

## Round 105 - Buy shell navigation and tracker controls

All 32 original buy_v2_screen.dart callbacks reconciled to specific entries, existing TRACK/AREA/ACCOUNT/Offers evidence or explicit pending states. Profile-context shortcuts are not qualified by rail taps. Tracker minimize, Hide, reopen and body targets remain distinct; enabled sound UI is not actual arrival playback. Semantics, raw drag and compact mini-cart paths are not pointer/floating rail passes. Care Doctor/Salon belong Book outside public Shop/Wholesale. No device actions or extra passes. Original index now 311 classified and 216 unclassified; classifications include pending and blocked controls. Full semantic/shared inventory and device qualification remain incomplete.

## Round 106 - physical category search and expired Offers recovery

Captures810-819 reviewed. Fresh resume showed Offers changed/expired notice; Refresh offers restored paneer promotion and product grid. This qualifies review-data recovery only, not a live publisher revision. Shop picker opened; zzzz produced readable no-match/Clear above keyboard; empty-state Clear restored choices; dairy filtered to Dairy and bakery; suffix X restored choices; sheet X closed keyboard and retained Scheduled catalogue, Saved1 and empty basket. 818 is transitional; settled819 establishes return. Six device passes, no new defect, no category applied or user item changed. Totals819 captures,821 evidence rows,505 action rows,406 device passes,17 defects. Source index count unchanged; updated existing pending mappings.

## Round 107 - product actions and conditional recovery

32 previously unclassified product/invoice/recovery callbacks linked to existing Share, Compare, Store, Chat and milk-variant evidence or explicit pending/provider states. Native share chooser is not recipient delivery; empty comparison Refresh is not populated comparison; catalogue Save is not product-action Save; Android Back is not a visible Change product control. Conditional business verification and content/benefits/trust Retry remain unverified. No new device action, pass or defect. Original index311 to343 classified,184 unclassified; remaining count is source references, not user journeys.

## Round 108 - checkout and recovery source coverage

SRC-0331 through0368 mapped to existing checkout/collection/Orders UI evidence or explicit conditional/provider gaps. Distinct visible Back, Change, radio/option, invoice and recovery actions are not passed from neighboring controls or historical records. Real payment attempt actions remain outside live transaction authority. Price/promise acceptance needs authoritative revised quotes; confirmed-order paths need B-011. No new device pass, capture, implementation or defect. Original source index381 classified,146 unclassified; this is not a completed-journey count. Audit remains open.

## Round 109 - order and collection action reconciliation

SRC-0369 through0390 linked to historical product/future-address evidence and existing collection, live delivery, delivery-exception and balance-payment blockers. Exact visible return/Close/Restore controls remain pending where only Back or rail evidence exists. No messages, rescheduling, disputes or payments performed. No new device pass/capture/defect. Original index403 classified,124 unclassified; classification includes pending and blocked actions and is not a unique journey denominator.

## Round 110 - tracking and order resolution controls

SRC-0391 through0410 matched to recorded Items/Address/Help/Reorder/Invoice and cancellation reason checks. Return/replacement/refund eligibility and quantity states retain B-006 and round82 descendants. Real submission not performed; disabled or unavailable controls are not positive qualification. Tracking-specific notification and support buttons remain distinct from settings/chat entry evidence. No new device pass/capture/defect. Original index423 classified,104 unclassified; semantic inventory still open.


## Round 111 - shared profile Orders return on Redmi

Captures820-823: fresh Scheduled Shop; header account opens shared global profile panel; Open orders opens Active Orders (12 active/2 delivered); Android Back restores Scheduled catalogue, Saved1 and empty basket. One device-pass journey, no new defect. BuyV2AccountView remains a separately mounted view in source and its callbacks are not passed by this shared profile test. Original index remains423 classified/104 unclassified. Totals823 captures,825 evidence rows,506 journey records,407 device-pass records,17 distinct defects. Full semantic inventory remains incomplete. Read recovery: an attempted rg path apps/mobile/lib/routing did not exist; no product mutation or conclusion relied on that missing path.


## Round 112 - payment and address action reconciliation

Twenty original callbacks classified using exact existing evidence or explicit pending semantics/Close states. Isolated address creation, cancellation, removal and Work restoration retain their original evidence; user addresses remain preserved. Paytm selection does not qualify every payment choice or Close. Prescription operations retain the Medicine scope boundary. No new physical capture, pass or defect. Original index443 classified/84 unclassified; classification includes unverified actions and is not a completed journey count.


## Round 113 - address forms and product quantity reconciliation

Twenty-five callbacks mapped to specific existing device records or explicit pending actions. Keyboard Enter does not qualify Update quantity; cart plus does not qualify product plus; pointer activation does not qualify semantic activation. Original index468 classified/59 unclassified, with no new device pass or defect. Bounded read recovery: an over-broad journey projection truncated; exact QTY-ROUND27/33 IDs were re-read successfully before classification. No omitted output was treated as evidence.


## Round 114 - initial callback triage complete, semantic audit still open

Remaining59 original references have evidence, forwarder, scope, conditional-blocker or explicit pending dispositions. All527 original references now triaged; this does not mean tested or that the complete public action inventory is finished. Pending dispositions, supplemental callbacks and shared-screen coverage must still be deduplicated into actual user actions and physically tested where reachable. No new device pass, capture or defect. Original Assist/Buy account callbacks retain unresolved reachability; shared profile evidence is not substituted. Bounded read recovery corrected a table-column parse and restricted matching to original SRC rows after SUPSRC matches exceeded output; exact four design/invoice rows were reread successfully.


## Round 115 - physical cart quantity and product return

Captures824-835. Five scoped device-pass records: cart quantity entry, visible Update quantity, cart-product entry/Back, product plus, isolated basket removal. Exact SKU wheat5kg;1/279 to2/558 via button then3/837 via product plus; Back retained cart3/837. Minus3 to2 to1 to0 restored empty Scheduled Shop and Saved1. No new defect. Totals835 captures,837 evidence rows,511 journey records,412 device-pass records,17 defects. Original callback triage complete; semantic/shared/conditional inventory and pending device actions remain open. No product implementation.


## Round 116 - shared inbox action grouping

Source apps/mobile/lib/features/chat/screens/chat_inbox_screen.dart SHA256 E9BCBEA050891D497A5BD182E951DC15E8B4ECE2024244777F1AB96DAC0271F6. All37 callback references in this file grouped below; groups may contain distinct branches and are not a tested-journey count. Existing physical evidence must be matched before declaring passes. No device actions, data mutations or new defects this round. Thread, archive and connected settings inventory remains open.

| Group | Source lines | User action | Current disposition |
| --- | --- | --- | --- |
| CHAT-INBOX-A01 | 356;361 | Connection request Not now / Send request | Entry and cancel pending reconciliation; Send request excluded real messages; no execution |
| CHAT-INBOX-A02 | 479 | Undo archive snackbar | Pending isolated fixture; do not archive original conversations |
| CHAT-INBOX-A03 | 539 | More menu settings / archived destinations | Pending exact menu items and return reconciliation |
| CHAT-INBOX-A04 | 583;637;641;800;857;917;919 | Chats / People / Discover selection and return | Buy-connected boundary and return checks pending; broad social discovery is not expanded into Buy scope |
| CHAT-INBOX-A05 | 633;634 | People search and provider refresh | Conditional shared boundary; no authoritative directory qualification |
| CHAT-INBOX-A06 | 635;636 | Connect or begin person chat | No real connection requests/messages authorized; draft-only entry must preserve existing drafts |
| CHAT-INBOX-A07 | 638;918 | Open Feed | Downstream social feed outside Buy audit; shared boundary return needs reconciliation |
| CHAT-INBOX-A08 | 724;726;745;770 | Conversation search open/type/submit/clear/close | Exact existing Chat evidence pending reconciliation; keyboard submit differs from clear and close |
| CHAT-INBOX-A09 | 911;1389 | Empty-search reset / no-query Discover | Reset and Discover are distinct branches; exact device evidence pending |
| CHAT-INBOX-A10 | 950;1118;1189 | Conversation menu via More button or long press | Two entry gestures; pending existing evidence and isolated-data availability |
| CHAT-INBOX-A11 | 952;1117 | Open conversation | Pending exact seller-context and return evidence mapping; tap forwarder is not a second journey |
| CHAT-INBOX-A12 | 1010 | Conversation filter chips | Each visible eligible chip pending reconciliation |
| CHAT-INBOX-A13 | 1260;1278;1290;1300 | Pin / attention / read / archive | Distinct state changes; original user conversation states preserved; isolate before execution |
| CHAT-INBOX-A14 | 1403;1409 | Empty state Open Feed / Start conversation | Forwarded boundary actions A07/A04; no extra journey count |
| CHAT-INBOX-A15 | 662;1492 | Load failure Try again | One provider retry path; unavailable/error fixture not a successful live refresh |


## Round 117 - physical Shop Chat filters and return

Captures836-846: Shop rail Chat opens shared inbox after transition; Unread shows Fresh Basket unread1, People empty state, Clear search restores All, Business shows Metro Wholesale, Orders Fresh Basket, Support two support threads, All restores four. Toolbar Back restores Scheduled Shop/Saved1/empty basket. Nine device-pass action records plus one wording observation: no-query People filter recovery says Clear search but works. No conversation opened, marked read, archived, pinned, messaged or otherwise modified. CHAT-INBOX-A12 all six visible filter chips and A09 no-query filter reset qualified for this fixture; search-query reset, other filters/data and menu actions remain pending. Totals846 captures,848 evidence rows,521 journey records,421 passing records,15 device observations,17 defects. Full audit remains incomplete.


## Round 118 - physical Shop Chat search

Captures847-859. Eight pass records: inline search open, unmatchedzzzz, keyboard Search, settled Clear search CTA, positive Metro, suffix X clear, empty-search close icon, Android Back to Scheduled Buy. Original unread1/pin preserved; no conversation opened or message sent. Capture852 is keyboard transition; tap at prior CTA position then missed after layout settled. Capture853 retains query and is not a failed Clear action; corrected visible CTA tap at854 works. CHAT-INBOX-A08 search branches and A09 query reset now have scoped physical evidence. Totals859 captures,861 evidence rows,529 journey records,429 passing records,17 defects. Other shared menus/conditional actions and full semantic inventory remain pending.


## Round 119 - physical archive/settings navigation and data ownership

Captures860-871. Six navigation passes: More menu, empty archive, Back to Chat, settings entry/scroll, Back to inbox, Back to Scheduled Buy. One settings/disclosure observation; no state changed. Original four inbox entries/unread1/pin and Buy Saved1/empty cart retained. CHAT-INBOX-A03 Settings and Archived entries qualified; Refresh/Open Feed and menu dismissal remain pending. Archive toolbar Back, populated open/restore, undo and session reset remain unverified; empty CTA only qualified. Settings controls viewed are not passed as changed or service-enforced. PD-064/065 map archive/session settings and authoritative privacy/call boundaries. Totals871 captures,873 evidence rows,536 journey records,435 passing,16 device observations,65 public-data rows,17 defects. Full audit still open.


## Round 120 - framework callback reconciliation

Twenty-one supplemental references classified as specific accessibility/keyboard/timer/Back checks or non-independent animation handlers. No pointer pass substituted for semantic activation. Quick tracker held-pointer/cancel timing and address focus reveal remain pending. Original527 triage does not include completion of these supplemental states. No physical action, capture, pass or defect added.


## Round 121 - shared settings action inventory

Source apps/mobile/lib/features/chat/screens/chat_settings_screen.dart SHA256 B357D1E4B798730B23B10E3BF85FE9FAAB5DAB0F92A45AE14B13053A84A578A9. Sixteen callback references grouped below. Grouping is not device qualification; round119 proves navigation and disclosures only.

| Group | Source lines | Action | Qualification gap |
| --- | --- | --- | --- |
| CHAT-SETTINGS-A01 | 197 | Pause/resume composers | Pending reversible state and draft-preservation check; no send |
| CHAT-SETTINGS-A02 | 221;251 | Voice/video availability | Disabled on device866; service-backed enablement blocked; calls excluded |
| CHAT-SETTINGS-A03 | 291 | Review before send | Toggle effect and cancel-only confirmation pending; actual send excluded |
| CHAT-SETTINGS-A04 | 313 | Hide previews | Pending enable/inbox preview masking/restore; preserve unread and pin |
| CHAT-SETTINGS-A05 | 335 | Suggested prompts | Pending display toggle/restore in eligible existing context; no prompt submission |
| CHAT-SETTINGS-A06 | 352 | Notifications and quiet hours | Nested route/return and device-vs-service settings pending |
| CHAT-SETTINGS-A07 | 379;113 | Who can message permission sheet | Open/cancel pending; authoritative update unqualified; no assumed success |
| CHAT-SETTINGS-A08 | 393 | Allow message requests | Service-backed update unqualified; confirmed current state must be retained on error |
| CHAT-SETTINGS-A09 | 412 | Review message requests | Entry/empty/return pending; accept/decline provider descendants not qualified |
| CHAT-SETTINGS-A10 | 427 | Group invitations | Shared boundary/return pending; real joining or invitations excluded |
| CHAT-SETTINGS-A11 | 442 | Blocked accounts | Entry/empty/return pending; real unblock excluded from this audit |
| CHAT-SETTINGS-A12 | 463;488 | Share last seen/read receipts | Two independent service-backed privacy fields; unchanged observed; actual updates unqualified |
| CHAT-SETTINGS-A13 | 695 | Settings row forwarder | No additional user journey; parent routes06/07/09/10/11 retain own checks |


## Round 122 - Chat preview masking and restoration on Redmi

Captures 872-884, bound in EVIDENCE.csv to the existing V6 Cursor Review APK. Settings inventory A04 (chat_settings_screen.dart:313) physically exercised. Original Hide message previews was OFF. Enabling it masked all four inbox snippets (878), preserving names, pin and unread count. Restoring OFF produced the shown-feedback state (881-882); inbox snippets and unread1 returned (883). Android Back returned to Scheduled Shop, Saved1 and empty cart (884). No conversation opened, no message sent and no other setting changed. Three scoped device-pass records added; no new defect.

Recovery: the earlier capture881 tool response was truncated. Bounded read recovered the existing PNG without overwrite; fresh882 confirmed current shown-feedback state before any navigation. Device remained authorized. Original preview state restored. No application restart or data clearing.

Totals: 884 physical captures, 886 evidence rows, 539 action records including 438 device passes; 17 distinct confirmed defects unchanged. These are check records, not unique completed end-to-end journeys. Inventory and shared/conditional descendants remain incomplete. Session preview masking is qualified only for this inbox round; provider privacy, account isolation and process-death behaviour are not established.


## Round 123 - Catalogue supplemental action reconciliation

Read exact catalogue source ranges260-285,1115-1200,1230-1276,1788-1855,2570-2610,2680-2705,3065-3085. Reconciled SUPSRC-0001 through0020 against existing device rows. Repeated forwarders are explicitly linked to their parent controls; product, Store-search and Offers pagination are not treated as interchangeable. Live-source retry, multi-page Store search, supplier revision and error recovery remain unqualified where exact device evidence is absent. No physical-device pass or defect added by this source reconciliation. Complete unique-action/journey denominator remains pending the rest of the supplemental/shared inventory. No application changes.


## Round 124 - Ordinary Scheduled Shop pagination and product return

Physical Redmi captures885-891: original empty-query catalogue885, exposed footer886, Next887 (carry bags82 first), product82 entry888, Android Back889 retaining later-page products, footer890, Previous891 restoring wheat2/notebook6/eggs10. Scheduled mode, Saved1 and empty cart remained. No cart, saved or address mutation; ordinary product visit may add its normal recently-viewed history. Two scoped passes recorded. No new defect. SUPSRC-0003 ordinary Shop Previous subset and SUPSRC-0009 parent product/Back subset now have device evidence; filtered search and Store-search pagination remain separate and pending. Final screen is original page at footer.

Totals: 891 physical captures;893 evidence rows;541 action records;440 device passes;17 distinct defects. Complete unique-journey denominator remains unqualified. No implementation or APK changes.


## Round 125 - Search keyboard submission, paging and wrong product Back destination

Physical captures892-907. Settled milk query897; keyboard Search898 dismisses keyboard and retains results. Next899 reaches41-80; milk1184 product900; AndroidBack901 transition, settled902 ordinary first-page catalogue. RV6-D018 registered: wrong return surface. Reopen search903/904 recovers41-80 internally, so no claim of permanent pager loss. Clear905 and Done906/settled907 restores Scheduled Saved1 emptycart. Search history milk naturally moves to top; existing entries retained; no history clearing. Product visit adds normal recent-view history. No cart/address mutation.

Initial attempt895 unexpectedly produced milke while layout/loading changed; Backspace896 corrected it. This is an observation with undetermined input/keyboard cause, not a reproduced app failure. Later settled keyboard submission passed898. Four passes, one failure and one observation recorded. 907 physical captures;909 evidence rows;547 action records;444 passes;18 distinct defects. Root cause of D018 unimplemented. Shared/provider and complete action inventory remain open; no exhaustive journey count claimed.


## Round 126 - Category recovery, shopping tools and Store callback reconciliation

Reviewed catalogue source3542-3568,3788-3810,3828-3852,3880-3905,4203-4245,4318-4360,5220-5260,5270-5304,5310-5348,5435-5465,5620-5680,5720-5782,5795-5825,6580-6618,6718-6740. Reconciled40 supplemental entries0023-0064 excluding already-classified framework hooks0027/0036. Category Clear variants, visitor/fallback paths, nested Store cart/Chat context and provider Retry remain explicitly distinguished. Existing device evidence is linked only to the tested subset. No source read counted as device pass. Remaining callback and shared-action reconciliation still prevents a final unique-journey denominator;18 defects unchanged. No application changes.


## Round 127 - Remaining catalogue, layout hooks and scanner forwarding

Reconciled 46 supplemental entries0066-0115 excluding already-classified framework hooks0084/0095-0097. Exact source ranges inspected around each callback and scanner test-wrapper declarations770/992. Linked scanner public unreachability to existing SCANNER-ROUND74-01 and original SRC0148-0162 dispositions; no Workspace/device scope expansion. Quantity guard branches, Store return mapping and global-profile child routes remain explicitly unqualified where evidence is missing. Scroll metrics and test wrappers are not unique taps. No physical captures, passes or defects added;18 confirmed defects unchanged. Supplemental entries0001-0116 now have parent/conditional dispositions, not blanket qualification;0117 onward and shared descendant inventory remain incomplete.


## Round 128 - Buy root navigation, delivery controls and procurement recovery aliases

Reconciled 46 supplemental entries0117-0167 excluding already-classified pointer/PopScope hooks. Source ranges1060-1083,1125-1176,1570-1618,1660-1677,1743-1764,2068-2098,2148-2164,2210-2282,2414-2430,2453-2472,2480-2600. Recorded precise distinctions among explicit Return/AndroidBack, ordinary versus dedicated search, root versus nested Store, procurement denial states, cart scopes and delivery lifetime. TRACK004/007/008/009 are limited to their observed controls, not playback/provider/timer success. No device pass or defect added. Original public-data and evidence records preserved;18 defects unchanged. Supplemental0001-0169 now classified by parent/condition; remaining legacy Chat and view callbacks plus shared descendants still require reconciliation.


## Round 129 - Legacy Chat reachability and product action forwarding

Reconciled 73 supplemental entries0170-0242. Literal constructor search identifies BuyV2ShopChatView only at its declaration and social/social_v2_consumer.dart1143. Public Buy screen2370-2390 uses BuyV2ChatRouteAdapter; adapter46/58/368/372 declares shared Chat paths, journey_router737/767/793 mounts ChatInboxScreen/ChatThreadScreen. Legacy49 callback entries are unreachable through the audited Buy route; shared equivalents remain required. Product-view source820-844,890-928,1185-1246,1445-1464,1594-1614,1898-1917,2373-2393,2865-2885 binds remaining24 entries to parent actions. Positive reviews and comparison still blocked by B003/B002. No device passes or findings added;18 defects unchanged.

Read recovery: an overbroad class-symbol read was truncated and two guessed source paths did not exist. No unseen output was used as evidence. Bounded literal constructor search and rg --files resolved actual paths; exact route hits above were read successfully. No policy changes or device restart. Remaining supplemental0243 onward partly classified; full shared descendant inventory and physical pending checks remain incomplete.


## Round 130 - Final supplemental callbacks and collection reachability correction

Reviewed views7640-7665,8822-8843,11085-11110,11272-11294,11835-11862,11920-11945,13010-13033,14518-14551,14862-14890,15757-15778,15960-15982,17013-17040. Classified remaining19 supplemental entries0249-0268 excluding focus hook0260; corrected collection camera0098 and original SRC0148/0149. Contrary to the earlier blanket scanner-unreachable disposition, Buy collection tracking explicitly instantiates BuyV2CollectionCamera at11090 with onDetected11095. Its authentication/ready-order/challenge state is blocked, not an absent public caller. No camera or collection success claimed; product-scanner routing is a separate component. Earlier round74/127 blanket collection-camera reachability inference is superseded by this direct caller evidence. Source review added no device passes or defects.

All271 supplemental rows now have a parent, conditional, framework or blocked disposition. This completes only that callback-triage pass, not unique user-journey enumeration or device qualification. Shared-route descendants, conditional device fixtures and per-field public-data reconciliation remain open. Defects18; physical captures907;action records547 unchanged.


## Round 131 - Delivery Minimize, rail reopen and Hide restoration

Physical Redmi908-915. Explicit panel Minimize closes status but leaves collapse chevron without delivery icon/count in settled911 and repeat913;RV6-D019 registered. Rail reopen912/914 retains12 deliveries and MS-NEW-09. Hide915 restores initial compact bike9+, Scheduled Saved1 and emptycart. Sound and Keep remain OFF;no order mutation or provider call. Source Minimize screen1584/2766-2768 and expanded icon1381-1423 correlated;root cause unproven. SUPSRC0126 now physically checked with failure, not pending-only. Timer45seconds from source1350 is not itself a measured playback/lifetime pass. Two functional passes and one visual failure added;19 distinct defects;915 physical captures;917 evidence rows;550 action records;446 device passes. Full audit still incomplete.


## Round132 - shared notification and privacy destinations

Physical Redmi captures916-929 retained and hash-bound in EVIDENCE.csv. Chat inbox/menu/settings entry916-921 retained original four seeded threads, preview preferences and settings. Notifications922/923 shows device permission separately from message/call/invitation/preview preferences and quiet hours. Android Back924 retains settings position. Message requests926 empty state and Android Back927 pass; Blocked accounts928 empty state and header Back929 pass. No setting, conversation, relationship, order or payment changed. Current device remains at Chat settings privacy section929.

Source chat_notification_settings_screen.dart lines29-60 binds load/save/device enable to session provider methods. No account-backed preference writes or permission changes were attempted. Populated requests/blocked accounts and notification persistence/delivery remain explicitly unqualified, with separate blocked rows. Empty-state passes do not qualify those descendants. Group invitations, audience selection/cancel and other remaining shared destinations remain pending.

The previous oversized notification-source read returned no usable contents; recovered using only the first80 lines under standing bounded-read authorization. No conclusions rely on the truncated output.

Register now has555 action/check rows,449 device passes and19 distinct defects;929 physical captures. These are not deduplicated complete journey counts. No new defect confirmed this round. Full action inventory and field-level reconciliation remain open; no implementation or new APK.


## Round133 - audience cancellation and group invitation destination

Physical Redmi930-936. Who can message you931/settled932 clips the No new conversations explanation above Android navigation; upward swipe933 cannot reveal remaining text. Registered RV6-D020 before continuing. Font scale readback1.0; source chat_settings_screen.dart529 confirms complete text. Source85-125 shows null selection returns without _savePrivacy. Android Back934 preserves Everyone and settings position. Group invitations935 empty state fits; Android Back936 preserves settings position. No service mutation, real invitation or group membership change. Populated invitation decisions explicitly blocked by absent isolated fixture.

Two device passes,one failure,one conditional blocked row added. Totals559 action/check rows,451 device passes,20 distinct defects,936 physical captures. Complete deduplicated journey denominator remains unreconciled. Current device at settings privacy section936; original preferences retained. No implementation or APK.


## Round134 - shared privacy descendant and data ownership reconciliation

Source-backed mapping PD066-069 added for notification preferences/device permission, message requests, blocked accounts and group invitations. These are private customer/platform contracts reached from Buy, not supplier-owned public listing fields. Account/recipient binding, immutable identities, units, freshness, acknowledgement and unavailable behavior are explicitly separated from fixture navigation passes. No device action this round and no additional device pass claimed.

Bounded descendant inventory supplement (not a completed journey denominator):

| Action group | Source | Current qualification |
| --- | --- | --- |
| Request list empty and Back | chat_privacy_screens.dart31-88 | Redmi926-927 pass |
| Request load Retry | chat_privacy_screens.dart76/344 | Provider-error fixture required; unverified |
| Request Decline and failure feedback | chat_privacy_screens.dart130/173-199 | Populated isolated request required; unverified |
| Request Accept and thread insertion | chat_privacy_screens.dart148;chat_session.dart1451-1473 | Populated isolated request required; unverified |
| Blocked list empty and Back | chat_privacy_screens.dart222-279 | Redmi928-929 pass |
| Blocked list Retry | chat_privacy_screens.dart267/344 | Provider-error fixture required; unverified |
| Unblock and failure recovery | chat_privacy_screens.dart297;chat_session.dart1387-1423 | Populated isolated relationship required; unverified |
| Group invitations empty and Back | chat_group_invites_screen.dart30-60 | Redmi935-936 pass |
| Invitation Decline and response failure | chat_group_invites_screen.dart95/130-139 | Populated isolated invitation required; unverified |
| Invitation Accept and response failure | chat_group_invites_screen.dart109/130-139 | Populated isolated invitation required; unverified |

Source investigations, not confirmed Redmi defects: notification load caches until refresh and fixture updates may be local only; actual permission/persistence/delivery remains unqualified. Requests/blocked list no-gateway paths return false without new error; current empty UI must not be described as authoritative server emptiness. Group invitation body selects empty view directly from list state; load-failure distinction requires a provider-error reproduction. These observations require follow-up evidence, not automatic defect closure or invented failure claims.

No application changes.20 confirmed defects and559 action/check records unchanged;public-data mapping now69 rows. Remaining full audit and deduplicated complete journey inventory still open.


## Round135 - Buy checkout dismissal and preserved return

Physical captures937-951. Settings Back937 retains four original inbox threads/pin/unread1;Back938 restores Scheduled Shop Saved1 emptycart. Shopping area header X939-940 returns same catalogue. Isolated wheat1/279 added941 and cart942 opened. Review943 retains original Home/Work with Work selected. Add delivery address944 -> explicit header X945 preserves checkout address step and quantity. This qualifies empty-form X only, not unsaved populated draft dismissal.

Payment946 retains Paytm. Confirm order947 -> Payment Change948 opens the existing full payment step, not a closeable sheet. Android Back949 goes to Address following stepper order. Recorded observation pending contract reconciliation: this is not a claimed return-to-Confirm pass or a confirmed new defect. Older payment-sheet X inventory remains separate until exact caller reconciliation. Address header Cart950 retains wheat1/279;minus951 removes only isolated item and restores original Scheduled Shop Saved1 emptycart. GST remained off;Home/Work and Paytm unchanged;no delivery check/order/payment submission.

Five device pass records and one observation added.565 action/check rows,456 device passes,20 distinct defects,951 physical captures. Remaining complete unique journey denominator and full audit remain open.


## Round136 - exact payment and address sheet closure reconciliation

Caller readback establishes catalogue4434/4443 opens address/payment sheets from Shopping settings; checkout uses different full stages. Captures952-956 navigate Sort/filter -> Shopping tools -> Shopping settings;955 is transition only,956 settled. Payment preference957 -> exact X958 retains Paytm and Shopping settings. Delivery addresses959 -> exact X960 retains Work and settings. No preferences or customer records changed;device remains at Shopping settings960.

SRC0341/0350 updated to round135 evidence;SRC0447/0455 now qualified against exact X controls rather than earlier Android Back or payment selection. Collection change controls, runtime/semantic choices, no-address recovery and other parent callers retain distinct qualification. No new defect. Current20 defects;two new device pass records. Full inventory remains incomplete.


## Round137 - corrected payment evidence and request-share cancellation

Re-inspected existing087-payment-switch PNG: it is Wholesale checkout, not showBuyV2PaymentSheet. Corrected SRC0448/0450 rather than treating that earlier source mapping as valid. Exact settings sheet961 -> Paytm re-selection962 returns settings and preserves Paytm. This is re-selection only, not a different-method switch or runtime payment execution.

Delivery selector963 -> Request an address964 -> Share965 preparing -> Android chooser966 -> Cancel967 returns form with Share request ready. No recipient app chosen and no message sent. Request form X968 returns original Home/Work selector with Work retained. Source features/buy/buy_v2_session.dart380-386 review adapter supplies generic https://moolsocial.com/address/request fixture;production-unavailable adapter249 and workspace router198 return unavailable. No claim of secure recipient binding, expiry or recipient completion. Copy link remains unverified;clipboard not changed.

One initial session-source lookup incorrectly used ui_v2/buy/buy_v2_session.dart and failed. Bounded search recovered actual features/buy/buy_v2_session.dart under standing read-recovery authority;no product edits or conclusions from missing file.

Eight new captures;three scoped device passes;20 defects unchanged.570 action/check records,461 device passes,968 physical captures. Full audit remains open.


## Round138 - named request manual-entry transfer and cancellation

Redmi969-975. Entered isolated unsaved AuditRecipient970 while keyboard visible. Add it myself971 transfers name into recipient field. Android Back972 returns underlying request;settled973 retains name and focused keyboard with readable controls. This is nested-form return, not a keyboard-only dismissal claim. Request X974 and settled975 dismiss keyboard and retain original Home/Work only,Work selected. No address saved,clipboard change,request creation or message. Transition frames972/974 do not establish clipping failures.

Three scoped device passes;SRC0467/0470 reconciled.573 action/check rows,464 device passes,20 confirmed defects,975 physical captures. Full audit and unique complete journey denominator remain incomplete. Device at original address selector975.


## Round139 - address type selection and draft preservation

Redmi976-982. Open unsaved Add address976;enter isolated AuditType recipient and dismiss keyboard977. Select Work978,Third party979,Other place980,Home981. Each selection visibly changes correctly and preserves entered recipient. X982 cancels form;only original Home/Work remain with Work selected. No address saved or backend write. These passes cover pointer chip selection and same-form text retention, not per-kind save validation, persistence or serviceability. SRC0468 updated accordingly.

Five device passes added;578 action/check rows,469 device passes,20 confirmed defects,982 physical captures. Full audit and unique journey denominator remain incomplete. Device at original address selector982.


## Round140 - stale recovery and tracker inventory reconciliation

Re-read JOURNEYS INVENTORY-ROUND28-10/11 and exact source views9322/9335;re-inspected captures385/386/387/389. They prove exact address-recovery Change address/chooser cancellation and Return to Checkout for the warm declared-link scenario with retained Work and basket. Updated SRC0361/0362;retain explicit unqualified actual serviceability failure,changed-address validation and provider-generated recovery. Do not add duplicate pass rows for this reconciliation.

SRC0180 corrected from unverified to existing RV6-D019 round131 exact Minimize failure;other compact tracker targets and timer conditions remain separate. Three stale inventory labels resolved;no device actions,new captures,new defects or implementation this round. Counts remain578 action/check rows,469 passes,20 defects. Full unique journey denominator and audit remain incomplete.


## Round 141 - Shopping settings address selection and restoration

Physical Redmi captures 983-986 qualify ADDR-ROUND141-01. From the original Work-selected saved-address sheet, Home selection returned to Shopping settings showing Sardarpura / 342003. Reopening retained Home selected. Selecting Work returned to settings showing Basni / 342005, restoring the original preference. Paytm remained unchanged; no address was added, edited or deleted. This is one connected action check, not four journeys. No new defect; total distinct defects remains 20. Checkout-origin selection and process-death persistence are not qualified by this settings-origin check.

Catalogue inventory reconciliation resumed with SRC-0001 through SRC-0024: the exact footer area tap (SRC-0016), keyboard submit/minimum query case (SRC-0021), and promotion final boundary (SRC-0009) remain concrete pending device checks. Source-only and provider branches remain separate. No exhaustive journey denominator is claimed. Bounded recovery of the prior truncated inventory read used 12-row pages; no unseen output was used as evidence.

## Round 142 - Area short-query submission and cancellation

Captures 987-993 qualify AREA-ROUND142-01. Settings Back returned Scheduled Shop. In Shopping area, the initial attempted IME tap changed J to Je and showed provider-unavailable feedback; capture990 is not proof of a one-character submission. Deleting one character and issuing Android Enter produced J, dismissed the keyboard, and left no stale error in settled capture992. X returned to unchanged Scheduled Shop with saved1 and empty cart993. No area applied, no new defect. Exact source1602-1622 clears error on edit and guards lookup at two characters. A bounded UTF-8 retry recovered the source read after the default Windows decoder rejected it. Positive location-provider recovery and the explicit two-character submit branch remain unqualified. Total distinct defects20.


## Round 143 - Catalogue pending-action reconciliation

Reviewed all 136 original catalogue SRC rows in bounded pages, retaining distinctions between pointer actions, wrapper aliases, semantics, alternate mounts and provider conditions. Capture994 shows area reopened with empty query and regional draft selected; no selection was applied. It is supporting evidence, not another passed journey. No new defect or JOURNEYS row. Device remains on the area selector; original saved addresses and empty cart preserved.

The following 17 work groups are concrete follow-ups from this catalogue inventory. They are neither defect counts nor an exhaustive unique-journey denominator. Each must first be reconciled against older evidence, then physically tested where still missing. A group containing multiple controls must not be closed from one representative tap.

| Group | SRC references | Exact follow-up |
| --- | --- | --- |
| CAT-P01 | 0009 | Offers promotion final Next boundary |
| CAT-P02 | 0013-0016 | Parent-specific pager boundaries and footer area entry; retain prior Offers/Shop/Wholesale passes |
| CAT-P03 | 0026-0027 | Any area and seed-area selection; establish original applied area before changes and restore it; seed results do not qualify national coverage |
| CAT-P04 | 0028-0031 | Sale-selector horizontal gesture and Wholesale/Bulk pointer retention; semantics separate |
| CAT-P05 | 0032-0033 | Conditional shopping-intent clear and account-origin return; establish reachable public entry or classify blocker |
| CAT-P06 | 0034 | Search Store result entry, associated-product resolution and Back |
| CAT-P07 | 0036-0037 | Recent and recommended suggestion exact query/result/return; preserve history |
| CAT-P08 | 0038 | Search all scope broadening, retained query and eligibility boundary |
| CAT-P09 | 0040-0047 | Shop category choice plus Wholesale picker entry/clear/close; existing Shop query passes retained |
| CAT-P10 | 0051 | Track active order from tools and return to exact originating catalogue |
| CAT-P11 | 0078 | Store sheet X, distinct from Android Back |
| CAT-P12 | 0085-0087 | Store category X and All products selection; selected category return |
| CAT-P13 | 0088 | Full Store catalogue X, distinct from Android Back |
| CAT-P14 | 0091 | Store search keyboard submission and retained query/results |
| CAT-P15 | 0102 | Saved settings-row Remove using isolated additional saved item; preserve original saved item |
| CAT-P16 | 0105 | Non-Saved empty-product-grid Show all recovery, if reachable |
| CAT-P17 | 0134 | Exact quantity Edit sheet; reconcile earlier edit evidence, quantity/limits and return context |

Separate qualification dimensions remain open: screen-reader activation (0030/0043/0049/0083/0097/0100/0131/0133), parent-specific enlarged text and relaunch, live revisions/disabled states, resolved location and provider Retry (0011/0012/0017/0018/0020/0021/0022/0025/0059/0060/0063/0072/0074/0075/0076/0077/0103/0104/0106/0130/0135), and conditional alternate catalogue mounts (0001/0093/0113-0116/0121-0128/0136). These cannot be declared passed through ordinary paged fixtures. History clear remains preservation-excluded (0035/0070/0123). Medicine-only and workspace-only controls remain outside the public Buy boundary as annotated individually. Wrapper aliases retain caller evidence, not additional journey counts. Other source families and shared descendants still require reconciliation; this section is not a final handoff.

## Round 144 - Exact Store close and keyboard controls

Twelve captures995-1006 qualify four action checks STORE-ROUND144-01..04: Store X returns original wheat2; category-sheet X returns full catalogue unchanged; wheat keyboard Enter retains 1-40 of180 and dismisses keyboard; full-catalogue X restores Mool Market Store. No new defect;20 distinct remain. CAT-P11/P13/P14 default seeded pointer cases are qualified. CAT-P12 category X is qualified but All products selection remains pending.

Capture998 caught opening animation. The following tap, intended for categories using that moving layout, actually opened soap5;999 is a transition, not category evidence. Android Back1000 was also transitional;settled1001 returned full catalogue. This accidental product visit is retained in evidence and may update recent-view history; no history was cleared. Correct category tap1002 and X1003 supply the actual category evidence. No Add, save, order, message or address mutation. Current device1006 is Store products with original wheat saved; cart remains empty. All product content/provider truth, enlarged text and process-death return limitations remain open.

## Round 145 - Store search page return and All products

Nine captures1007-1015 qualify STORE-ROUND145-01..03. Reopening full Store after X retained wheat query. Next displayed41-80 of180; opening wheat SKU1178 and Android Back returned exactly that search page and cards. This Store-context pass does not close Shop-search RV6-D018. Grain selection kept wheat query and reset page1 of60; reopening showed grain selected; All products restored wheat1-40of180. Clearing test query restored original All products1-40of5000. No Add/save/order/message/address mutation; viewing1178 may update recent history. No new defect;20 remain. CAT-P12 default pointer controls now have category X round144 plus All products selection round145; accessibility and live-category changes remain unqualified. CAT-P02 gains Store search Next and product Back evidence, not final-page or other-parent blanket qualification. Current device1015 full Store original query/category restored; original wheat bookmark retained.

## Round 146 - Shop sale-selector gesture

Captures1016-1020 retain Store exit through original wheat product and Shop, then qualify CAT-ROUND146-01. Rightward swipe across selector from180,239 to440,239 over250ms selects Quick and displays Quick catalogue. Reverse swipe restores Scheduled and original wheat bookmark; saved1 and empty cart retained. One connected gesture check, not a pass per frame. No new defect;20 remain. CAT-P04 Shop gesture is qualified; Wholesale/Bulk, threshold boundary, screen-reader and process-death variants remain open. No product implementation or user-data deletion.

## Round 147 - Wholesale/Bulk gesture and pager label distinction

Captures1021-1025 qualify WHOLESALE-ROUND147-01: left swipe selects Bulk and rice25kg cards, right swipe restores Wholesale cards and saved0. Return to Shop preserves Scheduled, original wheat saved1 and empty cart. No new defect;20 remain. No purchase or data deletion. CAT-P04 now has Shop and Wholesale/Bulk gesture evidence; pointer taps and other dimensions retain their own status.

Tap on pager Any area label1024 did nothing. Source1343 renders areaLabel as Text; the optional onArea IconButton1365-1371 is distinct and not visible in this pager. Therefore this tap is neither a defect nor proof of SRC0016. Resolve the optional caller/mount before further device testing of that control. Current device1025 is original Scheduled Shop.

## Round 148 - Offers footer area action

Source431 enables showAreaControl for paged Offers;1141 passes onArea into optional button1370. Wholesale summary Any area is not this action. Physical Offers footer button1028 opened Shopping area1029;X returned same Offers cards/footer scroll1030. Five captures retained;1027 attempted scrollbar drag did not move content and is not footer evidence;ordinary upward content swipe yielded1028. OFFERS-ROUND148-01 qualifies exact entry/cancel only. No location change or new defect;20 remain. Current device1030 Offers first page footer;cart empty and original Shop state unchanged. CAT-P02 footer location entry is now qualified for Offers;other pager boundaries retain their own limitations.

## Round 149 - Final loaded promotion boundary

Six captures1031-1036 qualify OFFERS-ROUND149-01 and CAT-P01 default seeded final boundary. Starting paneer46, individual Next yielded manufacturer paneer then mustard51. Capture1033 filename says final but its enabled Next proves it was not final. Twenty sequential Next taps reached manufacturer ghee96 with disabled Next1034. Another exact tap left it unchanged1035. Twenty-one Previous taps restored paneer46/92/200g1036. Intermediate offer contents are not individually qualified from traversal. No purchase, save or data deletion;20 defects remain. Current Offers top has original paneer selection restored; scroll moved from footer to top for this check.

Execution note: the implementation gate returned a live session11334; one bounded read-only source extraction ran before its terminal result was collected. The same session then completed successfully before device actions. No gate output was inferred and no process restarted. Future dependent reads/actions must await terminal success.

## Round 150 - Catalogue quantity editor exact entry

Earlier QTY-ROUND27 covers product editor and ROUND115 cart-line editor; neither was substituted for grid target11168. Physical captures1037-1043 qualify exact grid opening, Update2/558, Cancel unsaved3 retaining2/558, and removal of isolated basket via two minus taps. Original Scheduled Shop saved wheat1 retained;empty cart restored1043. CAT-P17 default Shop pointer entry/update/cancel now qualified. Seven captures, two pass rows and one observation.

Observation QTY-ROUND150-03: grid cards remain taller after basket removal1043 than initial1037. No additional confirmed defect yet; assess stable state/reentry and layout contract before deciding whether this is customer-facing wasted space. Keep observation open. Distinct confirmed defects20. Provider quantity revision, other SKU limits, accessibility and relaunch remain unqualified.


## Round151 - Catalogue empty-cart height recovery
Bounded recovery of the truncated combined source/image call: exact1044 existed339849bytes; inspected separately before use. Reissued source queries with bounded output. Implementation gate passed terminal0; starting HEAD fe26e92fa20374c45b3ff82c79a6939561366064 and zero status bytes verified. Redmi get-state device. No duplicate capture overwrite or unseen-result reliance.
1044 confirms settled empty-cart grid first row bottom880, versus1037 bottom792. Wholesale then Shop reentry1045 restores792, retaining Scheduled, Saved1 and empty cart. Source catalogue8801-8864 adds quantity-label height conditionally; cause of retained sizing is unproven. Registered RV6-D021 minor visual density defect, promoting QTY-ROUND150-03 rather than duplicating it. No implementation or data clearing.
Totals: 21 distinct defects;1045 physical captures;1047 evidence rows;595 action/check rows, including484 device passes and24 failure records. These are not completed end-to-end journey counts; full inventory remains incomplete.


## Round152 - Recent and recommended search navigation
Implementation gate terminal0; clean start. Captures1046-1054 reviewed on Redmi. Recent milk replay opens correct query/results; Back hides keyboard retaining query; clearing only active query returns suggestions. Recommended Fresh tomatoes submits exact query: Scheduled has no results; Back retains query; Quick shows tomatoes1/169/337; Scheduled again empty. This supports mode-specific inventory filtering, not a confirmed search failure. Recommendation relevance remains an observation; no new ticket without establishing customer failure. Clear active query and Done restores Scheduled, original Saved1 and empty cart1054. Search history not cleared; normal replay may update recent history. Source2738 reads session.searchSuggestions and2844-2846 submits the label; provider ranking/publication remains unqualified.
CAT-P07 default pointer suggestion checks evidenced; no blanket product return, accessibility or process-death qualification. Totals21 distinct defects;1054 captures;1056 evidence rows;597 action/check rows;486 device passes. Full inventory remains incomplete.
Evidence-write recovery: initial Python command had literal newline escapes outside a string and failed parsing before execution; output was truncated. Under standing bounded recovery authority, verified Round152 absent and used a literal multiline script. No failed-command mutation relied upon.


## Round153 - Search branch and public-data reconciliation
Implementation gate passed terminal0. No new device actions/captures. Resolved CAT-P08/SRC-0038 reachability for installed paged search: catalogue2684-2700 early return bypasses finite _SearchProductResults, whose empty narrowed state alone mounts Search all at2943-2964. Session2015-2017 enables paging from source availability; captured1050/1053 show paged empty results. Do not report finite button as tested or globally unreachable: alternate non-paged configuration remains unverified. No build/config change authorized for this audit.
Session9810-9827 broadening clears category/filter/intent/discovery refinements and persists customer state; source inspection alone does not qualify procurement eligibility or return persistence. Keep required business boundary testing distinct.
Added PD-070 for suggestion/title authority, query normalization, customer-owned history, publication/freshness/withdrawal and missing-data rules. Suggestions5113-5125 are first4 distinct visible product titles, not popularity claims. Actual provider authority and account-isolated history retention remain unqualified. Counts unchanged:21 defects;597 action records;1054 captures;1056 evidence rows. Public-data mappings70. Finite full journey denominator remains unfinished.


## Round154 - Saved settings-row removal and return
Implementation gate terminal0 and clean status verified. Physical1055 original Scheduled Saved1 wheat and empty cart. Added only notebook6 bookmark1056 Saved2. Profile1057 was a navigation detour, not shopping settings; Back restored Shop without account action. Sort/filter1058 -> Shopping tools1059 -> scroll1060 -> Shopping settings1061 -> Saved products1062. Exact notebook Remove icon621,1070 removed notebook only1063. Android Back1064 returns settings count1; Back1065 returns original Scheduled Shop, wheat saved, notebook unsaved, emptycart. No addresses/payment/notification changes; no original history clearing. Source7302-7306 binds settings row removal to toggleSaved and7752 is exact callback.
CAT-P15/SRC-0102 default pointer path qualified. No accessibility/process-death/provider claim from this pass. Counts21 distinct defects;1065 physical captures;1067 evidence rows;598 action/check records;487 device passes. Full-module inventory remains incomplete. No implementation.


## Round155 - Track active order tool identity and return
Implementation gate terminal0. Captures1066-1071 physically reviewed. Shop Sort/filter -> Shopping tools -> Track active order MS-NEW-09. Opens tracking at retained lower scroll1068; scroll top1069 confirms same MS-NEW-09, LAST KNOWN and unavailable live updates. First Android Back1070 opens Orders list; second1071 returns Scheduled Shop Saved1 emptycart. No order, notification, payment or user-data mutation. Tracking scroll now top due inspection. First return is labelled Orders on tracking; record actual chain rather than assume direct tools restoration or invent a failure.
Source catalogue4192 calls openTracking(activeOrder.id);session8804-8842 resolves exact ID and chooses Orders;returnToOrders8845-8855 uses named origin handlers otherwise Orders. This default route does not preserve the open Shopping tools sheet. Pass narrowly covers named order and navigable two-step return; live provider remains B005 and alternative orders/collection/late revisions remain separate. Retained scroll not diagnosed as a new defect.
CAT-P10/SRC-0051 default path now evidenced. Totals21 defects;1071 captures;1073 evidence rows;599 action/check records;488 device passes. Full inventory remains incomplete.


## Round156 - Monthly basket empty recovery and intent dismissal
Implementation gate terminal0. Source catalogue1818-1844 shows paging bypassed for showingMonthlyBasketProducts, so non-Saved _ProductGrid remains reachable despite normal paged catalogue. Session4923-4925 binds this to monthlyBasket intent. Did not mark the whole finite branch unreachable.
Physical1072 Shopping tools -> Monthly home basket1073 -> View basket products1074. Scheduled shows6of12. Category1075/settled1076 -> Meat and seafood -> empty0of12 with Clear filters1077. Tap Clear filters1078 restores6of12, preserving monthly intent. Banner X1079 clears intent and restores normal paged Shop Scheduled original wheat Saved1 emptycart. No Add basket, checkout, transaction or original-data deletion. CAT-P16 and monthly branch of CAT-P05 now have exact device evidence; other intents remain separate.
Totals21 defects;1079 captures;1081 evidence rows;601 action/check records;490 device passes. Full inventory and provider qualification incomplete. No implementation.


## Round157 - Store search identity and paginated Back
Implementation gate terminal0. Physical1080 query Mool shows Store results1-40; tap000001 opens matching Store1081, Android Back1082 restores exact results and keyboard. Next1083 range41-80;tap000041 opens matching Store1084;Back1085 retains41-80 and query. Clear only active query then Done1086 restores original Scheduled Shop Saved1 emptycart. No store collection, Add, message, original-history deletion or account action. CAT-P06 normal preview-product entry qualified; null preview branch still unverified. This is not D018 product-search Back and does not close it.
Account-return reconciliation: screen1076 header calls _openBuyProfile958-970/global profile panel, not legacy session.openAccount. Buy-local call search for .openAccount yielded no match(exit1 normal search result); this limited search is not proof of global unreachability. session9489-9499 requires account-child origin. SRC-0033 remains alternate-entry unverified instead of assuming sign-in fixes it.
Totals21 defects;1086 captures;1088 evidence rows;603 action/check records;492 device passes. Full inventory remains incomplete; no product changes.


## Round158 - Remaining catalogue work reconciled through round157
No device action, product edit or new defect. Implementation gate terminal0. Verified603 JOURNEYS rows with603 distinct record IDs; this proves ID uniqueness, not distinct semantic journeys. Source inventory has527 SRC and271 SUPSRC records. The first SUP-prefix query matched0 because rows use SUPSRC; corrected exact-prefix read gives271, no omission claim based on the first query. Callback totals are not a pending-work denominator.

| Follow-up group | Latest exact evidence | Remaining qualification |
|---|---|---|
| CAT-P01 Offers promotion final Next | round1491031-1036 final disabled Next and original restoration | Accessible/changed-provider states remain separate |
| CAT-P02 Parent pagers/footer area | Offers footer148;Store search145;Store matches157;earlier Shop/Wholesale records retained | Reconcile each parent's first/final/retry boundary; no blanket pager completion |
| CAT-P03 Any area/seed selection | Selector cancellation and short-query checks141-142 | Explicit Any area and seed-area apply/restore still pending; provider national coverage blocked |
| CAT-P04 Sale selector | Shop gesture146;Wholesale gesture147;Monthly Scheduled156 | Exact Wholesale/Bulk pointer retention still pending; semantics and relaunch separate |
| CAT-P05 Intent/account return | Monthly banner clear156 | Other intents and alternate legacy account-origin entry unverified; global profile is different |
| CAT-P06 Store search entry | round157 first/later page Store identity and Back | Null preview-product and provider stale/revision cases unverified |
| CAT-P07 Search suggestions | round152 recent/recommended query;keyboard/Back/mode return | Provider authority, accessibility and process death unverified |
| CAT-P08 Search all | round153 source branch classification | Not mounted in installed nonempty paged search; alternate finite variant unverified |
| CAT-P09 Category picker | Shop Monthly category156;Store categories144-145;earlier Shop search retained | Wholesale picker exact entry/clear/close pending; do not substitute Store picker passes |
| CAT-P10 Track tool | round155 named MS-NEW-09;Orders then Shop Back | Open tools sheet is not restored; observed labelled Orders route recorded;live/other order states blocked or unverified |
| CAT-P11 Store X | round144 Store X returns product | Context-specific/provider variants remain separate |
| CAT-P12 Store category X/All | rounds144-145 dismiss and all reset with query | Accessibility/provider changes separate |
| CAT-P13 Full Store X | round144 full-catalogue X returns Store | Other origins and process death separate |
| CAT-P14 Store keyboard submit | round144 wheat Enter,round145 retained page | Alternate IME/accessibility/provider separate |
| CAT-P15 Saved settings Remove | round154 isolated notebook removed;original wheat retained | Process death/account sync unavailable or unverified |
| CAT-P16 Non-Saved empty recovery | round156 Monthly Meat/seafood empty Clear filters recovery | Other refinements/text sizes separate; not globally unreachable |
| CAT-P17 Grid quantity Edit | round150 update/cancel/remove;round151 D021 | D021 open;limit/relaunch/provider/semantics cases separate |

Next reachable catalogue priorities: CAT-P03 applied-area restoration, CAT-P04 Wholesale/Bulk pointer retention, CAT-P09 Wholesale picker, then parent-specific pager boundaries. Completed default paths above must not be repeated solely to increase counters. Reconcile the broader product/cart/orders/shared-screen callback families and provider/conditional descendants into stable named cases before claiming an exact full-module denominator. Fields/publication mapping and remaining accessibility/process-death qualification remain required; this table does not shrink scope or declare groups fully complete.
Counts unchanged21 defects;603 action/check records;492 passes;1086 captures;1088 evidence rows;70 public-data rows. Full audit open.


## Round159 - Area application, restoration and selected-state defect
Implementation gate terminal0. Original Any area bound by1080 search header and original supplier000001;1087 chooser. Choose Jaipur1088 changes supplier000002;search milk1089 reports Jaipur and regional total. Clear active query/Done then reopen1090: chooser does not identify Jaipur, same unmarked city list as original. Registered RV6-D022 selection-feedback defect before losing evidence. Select Any area1091 restores original supplier000001 saved wheat marker, Scheduled Saved1 emptycart. No delivery address edits, permissions or transactions. Source1723 chooses null/allAreas;1735 chooses seeded city/regional;session2582-2596 clears resolved-place binding and persists browsing area. Existing baseline had no successful provider place to preserve. Do not conflate this seeded test with Google lookup/publication/serviceability qualification.
CAT-P03 pointer apply/restore evidenced with D022 residual;national/provider and process death separate. Counts22 distinct defects;1091 captures;1093 evidence rows;605 action/check records;493 passes;25 failure records. Full audit incomplete.


## Round160 - Wholesale pointer retention and category picker
Implementation gate terminal0; branch/HEAD and empty Git status digest verified before evidence edits. Captures1092-1098 retained from interrupted round;1099 pull/view output was truncated. Under standing bounded recovery, exact existing1099 file was checked then separately viewed; no unseen output was treated as evidence and no image was overwritten.
1092 Wholesale original;1093 Bulk selected;1094 Shop detour returns Bulk;1095 Wholesale restored and picker opened.1096 fruit narrows to Fruits and vegetables;1097 clear restores categories;1098 X dismisses picker/keyboard.1099 selected category catalogue;1100 reopens with visible selected checkmark.1101 Best prices restores original Wholesale catalogue;1102 Shop Scheduled original wheat Saved1 and empty cart. No cart/saved/address mutations or external actions.
Three narrow action/check passes WHOLESALE-ROUND160-01..03; no new defect. Semantics callbacks, process death, other category descendants and provider inventory remain separate. CAT-P04 pointer/module return and CAT-P09 default picker cases now evidenced; do not count their wrappers as separate journeys. Next parent-specific pager boundaries and broader semantic inventory reconciliation. Counts22 distinct defects;1102 physical captures;1104 evidence rows;608 action/check records;496 passes. Full audit remains incomplete.


## Round161 - Shop and Wholesale first-page controls
Gate terminal0; clean evidence tree verified.1103 Shop footer;1104 tap disabled Previous retains same initial products;1105 Refresh returns to top with original wheat Saved1.1106 Wholesale initial1-40 Previous unchanged;1107 Refresh retains same review products and Wholesale mode.1108 original Scheduled Shop Saved1 emptycart restored. No cart/saved/address changes or external transactions.
Two parent-specific checks PAGER-ROUND161-01/02 pass at the review-data UI boundary only. No claim that Refresh fetched an authoritative revision or exercised network failure. Final cursor, stale response, provider failure, other parent contexts and accessibility remain unqualified. No new defect.610 action/check records;498 passes;1108 captures;1110 evidence rows;22 distinct defects.
Next: reconcile product/cart/order/shared callback families into named remaining cases; preserve parent-specific final-page/provider gaps explicitly rather than attempting millions of Next taps or treating a first-page check as final-page coverage. Full audit remains open.


## Round162 - Product quick-action save and remaining product case groups
Gate terminal0. Source inventory reviewed SRC0266-0316 against recorded journey actions. Catalogue save tests did not evidence product quick-action Save.1109-1111 exact notebook6 product and Save;1112 Saved toast/marker;Android Back1113 catalogue count2 with notebook and original wheat bookmarks.1114 product reopened;1115 Saved retained;1116 same quick action removes only notebook.1117 visible Shop return tapped;1118 original Scheduled catalogue Saved1 wheat, emptycart. No cart/address edits or real messages. Two narrow passes PRODUCT-ROUND162-01/02; no new defect.612 action/check records;500 passes;1118 physical captures;1120 evidence rows;22 distinct defects.

These are 14 named product action groups reconciled from SRC0268-0308, not 14 completed end-to-end journeys. Lower shared purchase/stepper descendants and supplemental callbacks remain separately inventoried; no exhaustive product/module denominator is claimed.

| Group | Action and callback coverage | Evidence or next required case |
|---|---|---|
| PROD-P01 Return | SRC0269 visible return | Round162 Shop pointer passed; Store/search/Wholesale/compared parents and Semantics remain |
| PROD-P02 Visit store/supplier | SRC0268; SRC0270 Medicine excluded | STORE-001/COLLECTION-ROUND18-01 entry recorded; supplier counterpart and context variants need reconciliation |
| PROD-P03 Save | SRC0271;0275/0277 wrappers | Round162 exact quick-action save/unsave and reopen passed; sync/process-death/accessibility separate |
| PROD-P04 Share | SRC0272 | SHARE-001/002 chooser/cancel; recipient deep-link and provider delivery unresolved |
| PROD-P05 Compare | SRC0273/0278-0280 | CMP001/002 empty/refresh; B002 populated matches, page controls, offer identity, Add and return blocked |
| PROD-P06 Ask seller | SRC0274 | CHAT-001 entry; all shared Chat descendants remain separate; no message sent |
| PROD-P07 Variants | SRC0281/0282 | Round22/58 pointer cases; stale/unavailable branches and Semantics unverified |
| PROD-P08 Business verification | SRC0283/0287 | Open business profile and Verify business exact public Wholesale entry/return/auth boundary unverified; inspect current rendered conditions before claiming unreachable |
| PROD-P09 Availability decisions | SRC0284-0286/0288-0290 | Panel/dock Check availability, local insight Retry, unavailable Change product are distinct; provider success/failure branches unverified |
| PROD-P10 Related products | SRC0291/0292 | Pointer entry recorded; D007 return failure remains; Semantics and context variants separate |
| PROD-P11 Media | SRC0293 | B008 actual supplier bytes and media descendants blocked; round75 fixture zoom is not provider qualification |
| PROD-P12 Content and trust retry | SRC0294-0296 | Product content, benefits and trust each have provider-error Retry; missing error states unverified, source trust text is not authoritative proof |
| PROD-P13 Reviews | SRC0297/0299-0305 | REVIEW entry/ineligible handling recorded; B003 existing/eligible editor rating/comment/validation/draft/close/save outcome unqualified |
| PROD-P14 Report issue | SRC0298/0306-0308 | REPORT reasons/cancel recorded; busy/duplicate/rejection/accepted branches unqualified; actual submission excluded |

SRC0276 quick-action Semantics is not a separate pointer journey and remains untested with screen reader. SRC0266-0267 invoice error actions belong order recovery; SRC0309-0310 missing address/order actions belong recovery. Next reconcile cart/checkout/orders/shared groups and physically inspect PROD-P08/P09 reachable branches. Do not rerun default save solely to inflate coverage. Full audit remains incomplete.


## Round163 - Wholesale supplier return and verification-state boundary
Gate terminal0; clean evidence state verified.1119 tomato1 Wholesale10kg/580 MOQ2 shows Add to Cart;1120 decision panel shows order details and no unverified-business card.1121 Visit supplier opens Mool Market000001 Manufacturer catalogue;1122 X returns same tomato product and scroll. AndroidBack then Shop1123 restores original Scheduled Saved1 emptycart. No cart/saved/address/business profile mutations. PRODUCT-ROUND163-01 passed; no new defect.
Source views902/2846 requires !businessVerified for Open business profile/Verify business; both push /app/work/workspace/choose. Session1993-2007 review/nonreview initialization differs;4787-4791 snapshot combines verified enum OR legacy boolean. Source output had a non-ASCII display glyph; relevant source conditions were reread with ascii escaping before mapping. No encoding defect inferred. PRODUCT-ROUND163-02 and B014 explicitly retain untested pending/rejected/unavailable action/return cases. PD071 records purchasing-business authority, binding, revision, conflict and revocation requirements without claiming runtime qualification. Availability retry/provider-error controls remain separate PROD-P09 gaps.
614 action/check records;501 passes;22 blocked_test_data rows;22 distinct defects;1123 physical captures;1125 evidence rows;71 public-data rows. Next cart/checkout/order semantic reconciliation and remaining reachable conditional cases; full audit incomplete.


## Round164 - Cart and checkout named-case reconciliation
Gate terminal0; clean worktree digest verified. No device mutation or new capture this round. Reviewed SRC0311-0364 and SRC0475-0512 plus matching supplemental callbacks against JOURNEYS.csv. SRC0486's pending scope-switch note was obsolete: CART-ROUND12-03 and MIXED-ROUND63-01 already establish empty and populated scope switching. Linked existing evidence without adding a pass or repeating the test. COUPON004 establishes retained selections on return, but its recorded action does not identify every toolbar/footer return target; those are still distinct.

The following 30 action groups organize cart/checkout follow-up. They are neither 30 new journeys nor an exhaustive state-combination denominator. Each row retains normal/error/return/retention/accessibility descendants; confirmed defects remain open and provider-dependent states are not passed. Address editor subfields, payment chooser shared actions, mini-cart controls and other supplemental handlers still require their own reconciliation.

| Group | Controls / binding | Evidence and remaining case |
|---|---|---|
| CART-P01 Entry and Store identity | SUP0046/0054-56/0060-61/0069/0140-41/0149 | Store/root/nested product cart callbacks differ; D002 remains; reconcile exact entry/return identity per parent |
| CART-P02 Mini-cart parking | SUP0121 | Drag, park, restore and overlap require exact device evidence; normal cart entry does not qualify |
| CART-P03 Scope tabs | SRC0486 | Empty scope round12 and both nonempty round63 passed; account switch/relaunch/provider revision separate |
| CART-P04 Empty/browse continuations | SRC0312-14;SUP0161-62 | Store Continue browsing and empty Wholesale Browse recorded; nonempty Browse more, Offers return and stale Store anchor pending |
| CART-P05 Clear cart | SRC0311/0316-17 | Keep/Empty and mixed scoped removal rounds12/63; empty-disabled/late scope change and resolution shortcut pending |
| CART-P06 Line product navigation | SRC0506-07 | Round115 exact product and Back; Semantics and alternate origins unqualified |
| CART-P07 Line quantity/removal | SRC0508-10;0479-85 | Qty editor/update/cancel/keyboard/minimum/remove checks recorded; error-clear timing, exact limits, stale offers and entry variants remain |
| CART-P08 Product/grid quantity guards | SRC0475-78;SUP0085/0088-90 | Product Add rounds27/33; grid Edit round150; D021 remains; beforeCartChange rejection and alternate hit targets unverified |
| CART-P09 Recommendations | SRC0501-02 | Tissues Add and product/Back round12; other eligibility/revision states separate; prescription outside Shop |
| CART-P10 Instructions and tips | SRC0503-05 | Leave-at-door/none round11; other instructions/destinations pending; tip enabled-path not reached and not a positive pass |
| CART-P11 GST enable/profile chooser | SRC0318-23 | Toggle on/off and Add recorded; D017 selected chip remains; multiple profile choice/Edit/restore Retry unqualified; decorative switch not separate action |
| CART-P12 GST form lifecycle | SRC0326-30 | Required fields/short GSTIN/local save and keyboard Next/Done/reuse toggles recorded; full validation, save without reuse, restore/busy/failure unqualified |
| CART-P13 GST profile removal | SRC0324-25 | Isolated Remove round79; Keep dialog/multiple profiles/cross-destination and lifecycle unqualified |
| CART-P14 Benefit entry and return | SRC0487-90/0493 | Coupons001/payment003 and retained selections004; exact coupon entry variants, toolbar Back and completion CTA require target-specific evidence |
| CART-P15 Benefit destination/kind | SRC0491-97 | Payment kind entry003; reverse Coupons tab and each eligible destination switch unqualified; wrappers not extra journeys |
| CART-P16 Benefit select/remove/retry | SRC0498-500;SUP0267-68 | Supplier coupon and PhonePe selected; low-value ineligible state; removal/replacement/reverse kind/source isolation/expiry/provider Retry unqualified |
| CHECK-P01 Cart-to-checkout | SRC0315/0512 | Review/Back round63; no-address and pricing-recovery branches separate; forwarding cards not extra passes |
| CHECK-P02 Visible Back and busy guard | SRC0334 | Android Back checks do not establish visible Back or busy guard; exact control pending |
| CHECK-P03 Primary step progression | SRC0335/0351 | Address/payment/review and delivery boundary recorded; real submission excluded; busy/double tap/provider failure separate |
| CHECK-P04 Delivery/collection mode | SRC0339-40 | Delivery chip round18 passed; exact Collect chip and resolution-disabled behavior pending |
| CHECK-P05 Collection selection/change | SRC0336-38 | Store entry is not multi-Store selector or review Change Store/Payment; require exact collection context and retained identity |
| CHECK-P06 Address selection/edit | SRC0341-44;SUP0249-50 | Add another address empty form X round135; selected Work is not switch evidence; checkout-specific Select/Edit and busy/missing states pending |
| CHECK-P07 Payment choices/reference | SRC0345-48 | Review Paytm selection recorded; runtime locked choice/cancel attempt provider-dependent; procurement PO reference belongs separate workspace purpose |
| CHECK-P08 Confirm Change actions | SRC0349-50 | Address Change round95 and Payment Change round135; recalculation/provider and return observation949 remain separate |
| CHECK-P09 Quote retry and change | SRC0331/0352-53 | B004 authoritative quote and changed price/promise acceptance absent; Check delivery does not qualify Retry or accepted revision |
| CHECK-P10 Commercial terms | SRC0332-33 | Provider Retry and term radios require authoritative eligible terms; no fixture pass substituted |
| CHECK-P11 Valid confirmation | SRC0354-56 | B011 confirmed purchase single/multiple orders, invoice and Continue shopping; D009 false empty confirmation remains |
| CHECK-P12 Affected-item recovery | SRC0357-60 | B010 exact cart SKU revision needed for Retry/remove/view/return; ordinary product removal is not this recovery |
| CHECK-P13 Address/general recovery | SRC0361-64;SRC0309-10 | Declared-link Change address/return rounds28 recorded; true provider serviceability, missing-address, general context and Help binding incomplete; D010 remains |
| CHECK-P14 Saved-address reminder | SRC0511 | Exact account/cart/checkout parent Edit/return paths need reconciliation; general address editing cannot qualify every parent |

Counts unchanged:614 action/check records;501 passes;22 defects;1123 physical captures;1125 evidence rows;71 public-data mappings. Next reachable priorities: CART-P04 nonempty Browse more; CHECK-P02 visible Back; CHECK-P06 checkout Select/Edit; CART-P15 reverse benefit kind. Orders/shared-screen and remaining address/mini-cart inventory follow. Full audit remains incomplete; no implementation or APK.


## Round165 - Nonempty Browse more and visible checkout Back
Gate terminal0; clean status digest verified before evidence edits.1124 isolated notebook6 pack6 quantity1/210 added from original Scheduled Shop.1125 cart Browse more;1126 same Shop quantity;1127 reopened cart. Continue browsing names prior Store000041 despite cart item000001. Initial rapid tap on reentry1127 remained cart;not classified failure. Settled tap1128 opens correctly named Store000041;X1129 restores unchanged cart. Source2493-2498 uses per-destination prior browsing anchor;2540-2543 binds label and callback to same anchor. Retained as CART-ROUND165-02 observation,not a defect based solely on different item seller. No order identity/price mutation observed;stale unavailable or cross-account anchors remain unqualified.
1130 Review opens Address with original Work selected;visible Cart button1131 restores notebook1/210.1132 Browse more then notebook minus1133 removes only test item;known D021 extra tile height reobserved,not duplicated. Wholesale/Shop reentry1134 restores original compact Scheduled catalogue Saved1 wheat and emptycart. No address/payment/saved changes or order submission.
CART-ROUND165-01 and CHECKOUT-ROUND165-01 are narrow passes.617 action/check records;503 passes;20 device observations;22 distinct defects;1134 captures;1136 evidence rows. Exact Payment/Confirm Back and busy guards remain; checkout Select/Edit and reverse benefit kind next. Full audit open.


## Round166 - Coupon reverse navigation and checkout address controls
Gate terminal0; clean digest verified before evidence writes.1135-1136 temporary notebook6 one pack210;1137 Payment offers;1138 reverse Coupons tab displays no eligible Shop coupon;1139 footer Return to Cart unchanged210/no selection.1140 exact cart Coupons entry;1141 toolbar Back unchanged basket. No coupon/payment offer selected or payment action performed.
1142 checkout original Work;1143 Home pointer selection correct342003;1144 Work restored correct342005;1145 Work Edit opens matching original fields;1146 X returns exact checkout Work selection. No address field edits/save/delete.1147 cart retained210;1148 catalogue;remove only notebook and module reentry1149 restores original Scheduled wheat Saved1 emptycart. Original Home/Work and Paytm retained;no real transaction.
Four narrow passes COUPON-ROUND166-01/02 and CHECKOUT-ROUND166-01/02; no new defect.621 action/check records;507 passes;22 defects;1149 physical captures;1151 evidence rows;71 public-data mappings. Selected-benefit replacement/removal, multi-destination coupons, checkout address draft/save/keyboard/provider/relaunch, Payment/Confirm Back and busy guard remain separate. Next orders/shared-screen inventory and remaining reachable cases;full audit incomplete.


## Round167 - Orders, tracking, resolution and collection reconciliation
Gate terminal0; clean worktree digest. No device action/new capture this round. Reviewed SRC0365-0410, earlier recovery/invoice and order-card rows, relevant supplemental caller inventory, and 115 matching order/delivery/resolution journey records. The following 21 named groups expose distinct remaining paths; they are not new passes or an exhaustive state-combination denominator.

| Group | Controls / binding | Evidence and remaining cases |
|---|---|---|
| ORDER-P01 Orders entry/return | SRC0365;shared profile | Profile Open orders/Back round111; Orders Account return is conditional and not inferred from generic Back |
| ORDER-P02 Tabs and query retention | SRC0366-67 | Delivered/query round23; each remaining tab, empty/result/search combination and relaunch require own evidence |
| ORDER-P03 Card entry/status | SRC0513-16 | Tracking and delivered entries recorded; card-body hit target, nonstandard/unowned and every status not blanket qualified |
| ORDER-P04 Orders unavailable Retry | SRC0370 | Provider failure state absent; populated history does not prove Retry recovery |
| ORDER-P05 Browse promotions | SRC0371-73 | Exact Orders Shop/Wholesale promotion controls need evidence; Medicine boundary may be recorded without expanding Care descendants |
| ORDER-P06 Items and product return | SRC0368-69 | Historical product/Back recorded; visible Order breadcrumb and withdrawn item recovery unqualified |
| ORDER-P07 Delivery-context sheet | SRC0374-76/0393 | Address entry/manage future addresses round25; exact Close X and sheet Help require reconciliation; source order identity must persist |
| ORDER-P08 Tracking return | SRC0388;SUP0165 | Named order Back round155; visible Orders/Help breadcrumb is distinct; Assist alias renders tracking but does not qualify every origin |
| ORDER-P09 Live tracking refresh | SRC0382-83/0389 | B005 location/refresh/error states remain provider limited; last-known UI is not current tracking; D003 freshness disclosure remains |
| ORDER-P10 Restore hidden delivery | SRC0390;SUP0163 | Bottom-rail reopen differs from tracking Restore button; selected order and retained keep/sound/visibility require exact branch evidence |
| ORDER-P11 Tracking alert controls | SRC0391-92 | Exact tracking switch and restore-error Retry not implied by settings toggle; OS denied and lifecycle states separate |
| ORDER-P12 Tracking Items/Help/Reorder | SRC0394-95;SUP0155/0164 | Items and order-bound Help/delivered Reorder subsets recorded; no message/order placed; shared Chat draft/return must remain bound |
| ORDER-P13 Manage order entry | SRC0396 | RESOLUTION entry/cancel recorded; eligible returned/delivered branches B006 remain; not all resolutions complete |
| ORDER-P14 Invoice callers | SRC0397/0515/0266-67;SUP0251 | Historical consumer invoice recorded; Wholesale B009, positive confirmation B011, unavailable-dialog Close/Refresh remain distinct; D003 invoice disclosure retained |
| ORDER-P15 After-delivery support | SRC0398 | Exact support continuation differs from tracking Help; destination/order identity/return needs device evidence |
| ORDER-P16 Resolution type/reason/reset | SRC0401/0403-04/0410 | Cancel types/reasons/dismissal rounds82/83; positive eligible item selection/reset and return/refund reasons B006 unqualified |
| ORDER-P17 Resolution items/quantity | SRC0402/0407-09 | B006 checkbox, decrement/increment/eligible maximum need eligible purchased-item fixture; disabled item UI not a pass |
| ORDER-P18 Resolution retry/support/submit | SRC0399-0400/0405-06;SUP0254-55 | Unavailable retry observed; exact support buttons and sheet return pending; accepted/rejected/busy outcome unavailable; actual request submission excluded |
| ORDER-P19 Delivery exceptions | SRC0377-80 | B012 missing adapter/slots/proof; Retry/slot/confirm/dispute unqualified; real rescheduling/dispute excluded |
| ORDER-P20 Balance payment | SRC0381 | B013 due/pending/action-required recovery absent; live money actions excluded; no payment result claimed |
| ORDER-P21 Collection order and scanner | SRC0384-87;SUP0098/0252-53 | Round68 authenticated/ready/challenge state blocked; return, scan/camera close-reopen, detection/manual/error/Help need exact collection state; no scanner pass inferred |

Scanner distinction: SCANNER-ROUND74-01 is specifically the public product-scanner entry (Workspace callers); it explicitly keeps authenticated collection separate. SUP0098/0252 identify a conditional collection-camera caller at views11090-11095. Therefore the former source_unreachable record cannot close or remove collection scanner descendants. No current device pass or global unreachability claim is made. SOURCE-ASSIST-001 concerns the unused legacy Assist implementation; live order Help is shared Chat and remains in scope.
Counts unchanged621 action/check records;507 passes;22 defects;1149 physical captures;1151 evidence rows;71 data mappings. Next reachable exact controls: ORDER-P06 Items breadcrumb, ORDER-P07 context X/Help, ORDER-P08 tracking visible return, ORDER-P15/18 support entry without sending. Shared Chat/account/addresses and mini-cart inventory still remain. Full audit incomplete;no implementation/APK.


## Round168 - exact order entry and return controls

Physical Redmi captures1150-1164; ORDER-ROUND168-01 through05. Five narrow device passes, no new distinct defect. The order card body opened MS-NEW-09; Items breadcrumb returned to its lower tracking scroll. Delivery context identified Shop/MS-NEW-09 and X retained tracking. Its Help action opened Shree Balaji Fresh with MS-NEW-09 attached and the existing unsent draft; visible Back returned to tracking. The tracking screen's visible Orders button returned to Active12/Delivered2 with the same first order. Shop Scheduled, original Saved1 and empty cart restored1164. No message, order, payment, address or alert setting changed.

Capture1156 had a view-output truncation, recovered by exact file verification and separate view under standing bounded recovery authority. Capture1159 shows the navigation transition; only settled1160 proves the Chat destination. No transition was counted as a defect.

This supplies narrow additional evidence for ORDER-P03, P06, P07 and P08. It does not qualify every alternate state within those groups. Provider-bound descendants, filtered/alternate return contexts, tracking alert/restore controls and shared Chat/account/address/mini-cart inventory remain. Totals:22 distinct defects;626 action/check records;512 device passes;1164 physical captures. Records are not unique taps or end-to-end journeys; full semantic denominator remains incomplete.


## Round169 - tracking restore and alert controls

Captures1165-1175; TRACKING-ROUND169-01/02:two scoped passes;22 distinct defects unchanged. Exact Show delivery status clears the hidden state and restores a compact reachable control. It does not expand the panel immediately: screen1638-48 explicitly calls the collapsed state. After returning Orders, the bike control opens Deliveries12 with MS-NEW-09, Keep off and sound off. Hide restores the original hidden/compact presentation and the tracking Show button. No additional defect inferred from the compact presentation.

Tracking-screen Order updates was paused1172 and restored On1173;labels,icons and feedback matched. This qualifies the exact tracking entry independently of settings. Review branch only;OS notifications remain off. Actual alert delivery, persisted consent and unavailable-state Retry remain unqualified. Original Shop Scheduled Saved1 emptycart restored1175;orders,addresses,payment and drafts unchanged.

ORDER-P10 and P11 now have these exact control results, not blanket alternate-state qualification. Totals:628 action/check records;514 device passes;1175 physical captures. Blocked58 remains a recorded subset, not an exhaustive pending denominator. Shared Chat/account/address/mini-cart inventory and untested reachable cases remain.


## RV6-D001 implementation - 14 September 2026

Founder-authorized22-defect implementation begins from clean a846c558fe4bd606a69cfc613112979ba6d6a022. Separate admission48366d66307e425f4cee3b9094a9cea4ce4b9084 admits only catalogue source and search-result-recovery test. Positive implementation/pre-commit/handoff gates passed;three unrelated claim attempts correctly rejected (views source,policy config,journey session). Initial negative runner used incompatible Windows PowerShell and failed on Get-FileHash;that failure was not counted. Correct PowerShell7 negatives verified expected outside-claim rejection. No other worktree changed.

Correction: empty paged-catalogue guidance includes area only when showAreaControl is true. Store scope without the area control now says Try another search or category. Controls,query,category,ordering and navigation are unchanged. Exact source owner: apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart. Test owner: apps/mobile/test/ui_v2/buy/buy_v2_search_result_recovery_test.dart.

Four component regressions at320x568 and text1.0/2.0 use the existing bounded development catalogue. After correcting the fixture's missing source/region, the original product code failed both area-absent wording assertions and passed both area-present controls. After correction all4 passed. Complete search-recovery suite passed27 tests, including quick/scheduled/wholesale/bulk recovery and retained refinements. Flutter analysis of both changed owners:zero issues. Actual Flutter captures below inspected: text wraps and fits at both scales, and area guidance remains only with the visible area control. These are local component captures,not fresh physical Store journey passes. Original Redmi reproduction037-038 remains the scoped later device acceptance.

Recovery transparency: first test-file edit failed before writing due to default encoding;no-test run was not counted. A subsequent initial fixture failed before reaching empty state and was corrected. A truncated failure output was narrowed to one diagnostic case. Initial capture output was accidentally outside workspace;the four self-generated files were hash-matched to correct workspace captures and moved into recovered-misplaced-captures under the same evidence directory;no unrelated file was read/moved. Initial flutter pub generation changed tracked plugin metadata;generated bytes safely archived as generated-flutter-plugins-dependencies.txt and the originally clean tracked bytes restored from HEAD. No dependency/product changes beyond D001 accepted.

Local visual evidence (PNG SHA256;not part of frozen physical514 passes):
- C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\rv6-d001-local-20260914\area-false-text-1.0.png | 666839B297E5658AF099B0EDECEC6AA71FFBBA79932A684E0E989FA2236F4025
- C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\rv6-d001-local-20260914\area-false-text-2.0.png | BB14BC7953471103B9FD4972F81D4E3C12608AEC8DD711FC5A09F22FE64B0747
- C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\rv6-d001-local-20260914\area-true-text-1.0.png | 24D859A02F8CE01FE872688940C798A25E7700D2B2667EF973CF6D3160FE66C7
- C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\rv6-d001-local-20260914\area-true-text-2.0.png | 6435CE2BAFCCD0AFDB4A77CA3ACAAEB93C909F25669EA08D8CAB847225476548

D001 locally implemented and qualified;ticket remains open pending successor-APK Redmi verification. No device action or APK build. D002-D022 implementation remains pending. Historical audit checkpoint and frozen evidence remain intact.


## RV6-D002 local implementation checkpoint - 14 September 2026

- Source base/admission: `cea1699a42bf182c9648719b8780b5ec9afd05ba`, following D001 implementation `d532b9dea97a52473a5a95e090a9831fd9635696`. Admission passed implementation, pre-commit and handoff gates; three unrelated-owner negative cases rejected; clean live remote equality verified before product edits. Only the Buy screen and existing partner-catalogue test were added to the lane.
- Correction: retain the active Store catalogue for the exact navigation sequence caused by emptying the covered Cart/Checkout. Later navigation, explicit destination changes and existing procurement scope protection retain their handling. No session/cart business logic was changed.
- Changed product/test owners: `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`; `apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart`. Existing D001 ownership/checkpoint and frozen audit evidence preserved.
- Before correction: two UI-driven Shop/Wholesale tests reproduced dismissal of the entire Store after the sole cart line was removed; both failed the retained-Store assertion (test process exit 1). After correction, both passed.
- Final focused coverage: eight cases across legacy and paginated Store catalogues, Shop/Wholesale, text 1.0/2.0 at 390x844. Actual Store/cart/continue/browse/remove taps; empty basket rail absent, Add restored, delayed feedback does not dismiss, re-add works, Back retains Store preview, explicit destination change exits, added quantity preserved. Four paginated cases additionally select and retain the product category across Cart return. Paginated source includes Fresh tomatoes in the first Store, matching the recorded operation type.
- Connected regression: the complete partner-catalogue suite passed 72 checks before addition of the four paginated D002 cases. Those four then passed separately and again with captures; total distinct locally passed cases across these runs is 76, not a claim of a single 76-test invocation. Repeat/focused counts overlap and are not added as new coverage.
- Final Flutter analysis of the two changed owners: zero issues, exit 0. Tests used `--no-pub`; no generated files changed. No physical Redmi action, new APK, ticket closure or broad audit occurred.
- Eight actual Flutter captures inspected below: Store and Add state retained; empty cart rail absent. Captures preserve the action's scroll position, so headers/edge cards may be offscreen. At 200% text some fixture images show unavailable-image placeholders. These captures qualify D002 navigation/state only, not supplier-media rendering or all-screen visual fit. Physical acceptance remains the recorded Redmi 040-046 reproduction on the later checksum-bound successor APK.
- Execution recovery: a bounded evidence read first failed with Python stdout cp1252 encoding and was reissued with explicit UTF-8; it made no file changes. A lookup of a nonexistent guessed widget file failed; a bounded search found the actual quantity control in the catalogue. Neither is counted as a test or pass. Unrelated formatter-only source changes were removed before final qualification.
- Status: locally implemented and tested; still open pending scoped Redmi acceptance and Git sealing/readback. D003-D022 remain unimplemented.

Capture directory: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d002-local-20260914`.

| Capture | SHA256 |
|---|---|
| `rv6-d002-paged-shop-text-1.0-empty-store.png` | `02E3E9CFE2DD5EB8B1179C407851A87E8CB5E63B674370B5CB3B3F3A023ADCD5` |
| `rv6-d002-paged-shop-text-2.0-empty-store.png` | `2075D82E5435550BF3514E79F052463725EFEFA6F5599CBBAF75230FAFCF8FAB` |
| `rv6-d002-paged-wholesale-text-1.0-empty-store.png` | `3EAA3153131E3253C2364BE0D273CB8F3CC0687C2CB14788DC0BF6348FD547F1` |
| `rv6-d002-paged-wholesale-text-2.0-empty-store.png` | `1F11EBFCDB043492D7E0F50221A2315A570EC677B26F2E0B980B89A589668832` |
| `rv6-d002-s-eggs-text-1.0-empty-store.png` | `A2262EE0C48FFD8E4CED14DF636A84CBE10A44A431AFADDD5A8BEC145453F3EE` |
| `rv6-d002-s-eggs-text-2.0-empty-store.png` | `26D9152DA239BDB9827D9AC76C1173B1CDD40061D63158EBC9544CF6E1861969` |
| `rv6-d002-w-notebook-text-1.0-empty-store.png` | `82F9127394E62EC9B68107854F9EC1CC858EF5EFC56FEF5E0B02123E504FE244` |
| `rv6-d002-w-notebook-text-2.0-empty-store.png` | `29DA324DCAF3C7D4A97848EB2941395299DBF547811A6F317A2528CA865A48AC` |


## RV6-D003 local qualification - 14 September 2026

- Complete recorded scope: original Order Help/Chat freshness loss (112/147), invoice/PDF occurrence (480), and Shopping alerts occurrence (510-511). All remain open for scoped Redmi acceptance; no device closure is claimed.
- Dependency/admission: `3b0fd2fcdbcc444ead93590f7992e6ccb8d9b384`, parent `55877c20437bdc34c1a90de19904381e94014cde` (sealed D002). The founder-authorized minimal admission added eleven exact owners, transferring only two inherited root claims in this worktree. Implementation/pre-commit/handoff passed; unclaimed session and direct control-file claims still rejected; clean live remote equality verified before source work. No other worktree was changed.
- Implementation: shared presentation formatter preserves recorded/updating/updated/unavailable freshness. Existing tracking delegates with its same session inputs. Order Help passes that same summary to both Chat metadata and the unsent draft; Shop Chat thread/context uses session freshness, with conservative recorded defaults when unknown. Shopping delivery alerts retain the tracking qualifier and the review adapter no longer invents Updated recently. Both screen and PDF invoice output mark estimates historical, preserve a provided original window, explicitly disclose missing recorded time for relative estimates, and do not misrepresent Delivered/Completed/missing text as an original estimate. No new timestamps, backend events, provider authority, native bridge or session state were invented.
- Final combined local regression: **64 passed, zero failures**, terminal exit 0, covering the five suites below. This supersedes earlier intermediate results; counts overlap and must not be added. Final analysis of all thirteen changed Dart owners: zero issues, terminal exit 0. `git diff --check` passed. No broad physical audit was resumed.
- Suites: `buy_v2_shop_chat_test.dart`, `buy_v2_invoice_downloader_test.dart`, `buy_v2_invoice_regulatory_context_test.dart`, `buy_v2_shopping_alerts_test.dart`, `buy_v2_live_delivery_tracking_test.dart` under `apps/mobile/test/ui_v2/buy/`.
- Focused coverage includes unknown/loading/ready/offline/unavailable/updating estimates; shared Chat metadata/draft/order-return identity; historical missing-time/status/known-window cases; invoice channel payload identity and amounts; actual on-screen invoices at 100%/200%; failed-refresh delivery alert consistency and four viewport/text layouts; full tracking -> Help -> expanded context -> swipe to final fact -> one Android Back to the same order at 100%/200%. Tests use fixtures and mocked channels only; no actual message, transaction, Android PDF save or provider refresh was executed.
- Visual review: twelve current relevant captures reviewed: four delivery-alert layouts plus eight corrected invoice/Chat captures in `corrected-visuals`. Text wraps, freshness qualification is readable, and the final Chat fact remains reachable at enlarged text. Other captured alert rows are retained supporting artifacts, not additional visual qualification. Four initial invoice images exposed a status-as-estimate formatting error; the correction and regression are in this slice, and those images remain superseded evidence. Initial Chat captures are superseded by the corrected set. Existing 514 passed physical records/1177 artifacts remain frozen.
- Remaining qualification: build/install is deferred until all22 are locally qualified. Original Redmi reproductions, actual saved PDF output, real provider estimate timestamps and authenticated updates remain unverified. Missing recorded-time disclosure is a frontend fallback, not backend completion or a reconstructed promise time.
- Execution/recovery record: initial invoice display tests asserted before the lazy Delivery section was reached; alert selectors also matched the covered tracking surface. Those eight failed checks were corrected to scroll to the section and match the exact alert row; the later 19-check run passed. A normal-text Help setup tap was obscured by the bottom rail and was corrected with centered scroll plus hit-test assertion. Visual review found the Delivered duplicate and prompted the historical fallback correction. A non-capture 200% test using cross-ancestor `ensureVisible` failed the one-Back return, although keyboard was closed/current route permitted pop. Replacing that setup with actual bounded swipes in the Chat message list preserved the same one-Back assertion and passed isolated and combined runs. No shared Chat/navigation source was changed to accommodate it. Temporary diagnostics were removed. One earlier test-output chunk was truncated; terminal state and failing cases were recovered through the same process handle and exact reruns; it is not qualification evidence. A guarded test edit failed before write due to a formatted anchor mismatch and was reapplied only after bounded source readback. Unrelated formatter-only source changes were removed.
- Status: complete local correction, pending Git seal/readback and later Redmi qualification. D004-D022 are still pending implementation. No new APK.

Changed source/test owners (implementation commit is the commit containing this section):
- `apps/mobile/lib/features/buy/buy_v2_shopping_alerts.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_chat_route_adapter.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_design.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_invoice.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_invoice_downloader.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_shop_chat.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_invoice_downloader_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_invoice_regulatory_context_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_shop_chat_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_shopping_alerts_test.dart`

Final log identity:
- `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d003-local-20260914/final-v3-connected-regression.log` SHA256 `72CE482A2E7768290C400608DBB4073C900C1FB66A1EC44A1187D64589819944`
- `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d003-local-20260914/final-analysis.log` SHA256 `8CABE84C2E219A3C20DF8FFD6485BAA2CBABA940EF133D53C92C7BDAFFB4ACC1`

Retained capture inventory, relative to `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d003-local-20260914`:

| Capture | Disposition | SHA256 |
|---|---|---|
| `corrected-visuals/rv6-d003-chat-context-last-text-1.0.png` | reviewed current | `D8EA966BF74E2F2D55C6E3A5CD157B6BB447B044730284D9A907EC16BD85FF8D` |
| `corrected-visuals/rv6-d003-chat-context-last-text-2.0.png` | reviewed current | `D71BE0D4F29EE2B69CCB6D66111C8289C15739DE9B4EF040B105B657C119B693` |
| `corrected-visuals/rv6-d003-chat-context-text-1.0.png` | reviewed current | `D8EA966BF74E2F2D55C6E3A5CD157B6BB447B044730284D9A907EC16BD85FF8D` |
| `corrected-visuals/rv6-d003-chat-context-text-2.0.png` | reviewed current | `2997D801B3CEB36D17C7EE543273AE61516E9E01F02FE32977E73629DD18C401` |
| `corrected-visuals/rv6-d003-invoice-shop-text-1.0-v2.png` | reviewed current | `D75331EC78D340374D976BDC252DA2273236EDFE0B2B6DC91A865531A734045D` |
| `corrected-visuals/rv6-d003-invoice-shop-text-2.0-v2.png` | reviewed current | `B6E83307A755F4B7A34AEC6F3943DA39F63C920376E3094DFE498DCE12C7CA42` |
| `corrected-visuals/rv6-d003-invoice-wholesale-text-1.0-v2.png` | reviewed current | `4C72D50D0E8B4D49EC3FF85EFFB8A9995F3C1AFBF684431EE31361F993914949` |
| `corrected-visuals/rv6-d003-invoice-wholesale-text-2.0-v2.png` | reviewed current | `73A77B0D901428FB8F49ECB6F3D49EEB421C015543E06D19E78E7FA67C08118C` |
| `r5-alert-delivery-320x700-1.0.png` | reviewed current | `2E04C4FFD3E0804FBC9DDCF0C1FDD02A430325AEA9AFAF8F06C5C6D035BC6FD1` |
| `r5-alert-delivery-320x700-2.0.png` | reviewed current | `57BE45C19778A4F873336282F91630DE36D23719009AED4CC0E41B4C52DD854A` |
| `r5-alert-delivery-640x360-1.0.png` | reviewed current | `3E23D3225FFC58E392326BED93B396D9934F55796C6C971799049836D4334D94` |
| `r5-alert-delivery-640x360-2.0.png` | reviewed current | `9D112336E08A31C0E99E7AD2198A9A9EED5ADA9F225681F3528BD5FBBC2DE924` |
| `r5-alert-offer-320x700-1.0.png` | supporting, not separately visually qualified | `2E04C4FFD3E0804FBC9DDCF0C1FDD02A430325AEA9AFAF8F06C5C6D035BC6FD1` |
| `r5-alert-offer-320x700-2.0.png` | supporting, not separately visually qualified | `9E04E0C61137187292D052A360C0CA90A2D893FB5E603FBE4BF5F12CBC6387F9` |
| `r5-alert-offer-640x360-1.0.png` | supporting, not separately visually qualified | `C298A8AA252D5427B3169053E18768D424A38622ACE51890D324F72809802D33` |
| `r5-alert-offer-640x360-2.0.png` | supporting, not separately visually qualified | `6C0A921BBE001BA62D7533F8ACDA531347E77D3A805511B01A7CA3C6E0338926` |
| `r5-alert-priceDrop-320x700-1.0.png` | supporting, not separately visually qualified | `2E04C4FFD3E0804FBC9DDCF0C1FDD02A430325AEA9AFAF8F06C5C6D035BC6FD1` |
| `r5-alert-priceDrop-320x700-2.0.png` | supporting, not separately visually qualified | `9E04E0C61137187292D052A360C0CA90A2D893FB5E603FBE4BF5F12CBC6387F9` |
| `r5-alert-priceDrop-640x360-1.0.png` | supporting, not separately visually qualified | `C298A8AA252D5427B3169053E18768D424A38622ACE51890D324F72809802D33` |
| `r5-alert-priceDrop-640x360-2.0.png` | supporting, not separately visually qualified | `6C0A921BBE001BA62D7533F8ACDA531347E77D3A805511B01A7CA3C6E0338926` |
| `r5-alert-returnUpdate-320x700-1.0.png` | supporting, not separately visually qualified | `2E04C4FFD3E0804FBC9DDCF0C1FDD02A430325AEA9AFAF8F06C5C6D035BC6FD1` |
| `r5-alert-returnUpdate-320x700-2.0.png` | supporting, not separately visually qualified | `9E04E0C61137187292D052A360C0CA90A2D893FB5E603FBE4BF5F12CBC6387F9` |
| `r5-alert-returnUpdate-640x360-1.0.png` | supporting, not separately visually qualified | `C298A8AA252D5427B3169053E18768D424A38622ACE51890D324F72809802D33` |
| `r5-alert-returnUpdate-640x360-2.0.png` | supporting, not separately visually qualified | `4FAE6A778F1E6316E6602E6D8C62A48C73CD208E295651D5341C43EFAE306FF6` |
| `rv6-d003-chat-context-text-1.0.png` | superseded | `D8EA966BF74E2F2D55C6E3A5CD157B6BB447B044730284D9A907EC16BD85FF8D` |
| `rv6-d003-chat-context-text-2.0.png` | superseded | `2997D801B3CEB36D17C7EE543273AE61516E9E01F02FE32977E73629DD18C401` |
| `rv6-d003-invoice-shop-text-1.0.png` | superseded | `757FAA229A6188D4087A038905E0B1D2221BF4CE6CF4737AFF74DE10AC178E04` |
| `rv6-d003-invoice-shop-text-2.0.png` | superseded | `CB3ED581446413A8AD688DA4FEA5BEDB8584102771C2FAA4EEE1557BD85480F1` |
| `rv6-d003-invoice-wholesale-text-1.0.png` | superseded | `0BB3CE37376679E65E235FEAF7730450E88CEF58893D3B15D2C0C19035798CCE` |
| `rv6-d003-invoice-wholesale-text-2.0.png` | superseded | `8D4C7E1F2F0E180BBDCB5B9BDF48FA960471F3FA631C3FECD5E1000902F711D2` |

## RV6-D004 local qualification - 2026-09-14

- Scope: original Redmi captures198/199 only, full display-name rejection sentence with/without keyboard. No broad audit, real profile save, APK or device action.
- Admission: 41c5e36cfd2950521c918271afb56dcff2e02354, parent e01ff726fd7b92ecb8c3fd6928cc9f248b9f6eaa. Exactly two existing profile owners transferred from inherited root claim in this isolated worktree; claim29. Prior checker reconstructed exactly (normalized-LF SHA256 F0A61705FEE0F03F27034306A814412ED7DB7132739306A3FD2EB5BC01C2B2E2). All other rules preserved. Admission pushed, clean/live-equal; pre_commit and subsequent implementation gate passed (claims29/registry4584).
- Changes: apps/mobile/lib/ui_v2/profile/global_personal_profile_v2.dart uses uncapped wrapping error text and a constrained scrollable editor, preserving the existing flexible bottom placement when space permits. apps/mobile/test/ui_v2/profile/global_personal_profile_v2_test.dart adds four D004 cases and uses MoolTheme.light for representative text metrics.
- Final suite: Flutter test --no-pub test/ui_v2/profile/global_personal_profile_v2_test.dart --reporter expanded with visual defines; 11 passed, zero failures, terminal0 (session18105, final chunk292b0a). Includes four new D004 cases at390x844/320x568, text1.0/2.0, each220px inset and hidden. Checks full error RenderParagraph without exceeded lines, unchanged name, no overflow and Profile return. Existing profile navigation/save/safe-return regressions pass.
- Analysis: Flutter analyze --no-pub for the exact two Dart owners; zero issues, terminal0, chunked5b33. Diff reviewed; no unrelated formatter-only changes.
- Visuals: all eight themed PNGs inspected; full characters guidance readable at both scales. At320/200% with keyboard inset the editor scrolls to the full error. Host captures model the keyboard inset, not Android's keyboard surface or Android Back. These remain successor Redmi acceptance criteria, not device passes.
- Initial attempts: admission edit asserted before writing because the policy uses LF; corrected after bounded read. First pre_commit rejected the unstaged two-file admission; staged exact controls and reran normally, no bypass. Initial focused tests2passed/2failed: enlarged text exposed editor overflow, corrected by scrolling; compact profile setup needed scrolling to its lazy name row. Initial unthemed full suite11passed and capture run4passed are superseded for visual qualification: eight root PNGs use Flutter test glyphs. Retained unmodified and not claimed as readable visuals. Final themed run supersedes them.
- Dependency: no backend/session/native changes. Physical Redmi captures198/199 still await the one successor APK. No D004 device closure.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d004-local-20260914. SHA256 inventory follows.

| Artifact | SHA256 | Disposition |
| --- | --- | --- |
| rv6-d004-320-text-1.0-keyboard-false.png | 9AEFA6B5122ACAFBAC568330834F58C2FC1902211D5B66C2100489B199E0837F | Superseded test-font capture; not visual qualification |
| rv6-d004-320-text-1.0-keyboard-true.png | 5D3D8993412929F407E07AF8FB7E3B68A52DCCB10B1EB5F42D19A5FEC545CDB2 | Superseded test-font capture; not visual qualification |
| rv6-d004-320-text-2.0-keyboard-false.png | 8AF48950755C386A89FBDB13D0EE04B240041C21237E1FE019E9EE3969B855D9 | Superseded test-font capture; not visual qualification |
| rv6-d004-320-text-2.0-keyboard-true.png | 021C59C635CF55A5B638DC33BD304DC13911DE09E922C138F5D2BFDCC0B2482E | Superseded test-font capture; not visual qualification |
| rv6-d004-390-text-1.0-keyboard-false.png | C759BEC3140B6150DFF021E484778E5B14E8345F022E5021C35C419E7AAE7797 | Superseded test-font capture; not visual qualification |
| rv6-d004-390-text-1.0-keyboard-true.png | 459CA7F292A737E8C189DF9DC2230DCC6F27F4A0002DD50AF51236453BA3FD6F | Superseded test-font capture; not visual qualification |
| rv6-d004-390-text-2.0-keyboard-false.png | 511AE1BC485589EF60FDD81B29F602D1D7B2B2F4053FC1371F1947AFE20E2CBD | Superseded test-font capture; not visual qualification |
| rv6-d004-390-text-2.0-keyboard-true.png | C07FE57A602C0C008D606822FDECD0FF1A2D47ED06BA1B7CC0428C80E0818C63 | Superseded test-font capture; not visual qualification |
| themed/rv6-d004-320-text-1.0-keyboard-false.png | E4E06F4263B0D62E3E56379E157F9AA8B8A96572AF3B9AF410D825E9152A1DBE | Reviewed themed Flutter capture |
| themed/rv6-d004-320-text-1.0-keyboard-true.png | 10203127A2CCFC1B2D8FCF1F0C2DA034D1165EAD086207048BD91ACC5858A822 | Reviewed themed Flutter capture |
| themed/rv6-d004-320-text-2.0-keyboard-false.png | FF6FF3BA3F1266A5B448723FA1FD4C576D7F02F68D71475380C94A4F6A777A77 | Reviewed themed Flutter capture |
| themed/rv6-d004-320-text-2.0-keyboard-true.png | 2772A7FDEE6E46F6019B5177ACAA3864CA8AE4E1FB44C0EF9E6E7E287B1D06F3 | Reviewed themed Flutter capture |
| themed/rv6-d004-390-text-1.0-keyboard-false.png | 9E61B97895BAAC6EF9C73D7B40ABB0E3498D3A51FC1395D712546FBA886DA70F | Reviewed themed Flutter capture |
| themed/rv6-d004-390-text-1.0-keyboard-true.png | D9DA3B723190625C017B53440CC9636CA2B173F29BAAFD1744B6173C8A42AAFD | Reviewed themed Flutter capture |
| themed/rv6-d004-390-text-2.0-keyboard-false.png | FE72E2DC1FAB1D665AF8440FD09D4961503FDB6ADB204D09D716EDE0D0A445C8 | Reviewed themed Flutter capture |
| themed/rv6-d004-390-text-2.0-keyboard-true.png | 05C39D5AACE0341A629B1BF4C0C9B981A9C0E368753D54C2F52461A066FF3843 | Reviewed themed Flutter capture |

## RV6-D005 local qualification - 2026-09-14

- Recorded scope:202-204 language selection and return. The ticket permits explicit unavailable coverage. Buy/settings currently lack Hindi interface wiring; this correction labels the saved preference honestly before selection and in Preferences/Personal profile. No translation coverage is claimed; supplier content unchanged. Picker scrolls at enlarged text.
- Source owners: apps/mobile/lib/ui_v2/profile/global_privacy_preferences_v2.dart; apps/mobile/lib/ui_v2/profile/global_personal_profile_v2.dart. Test owner: apps/mobile/test/ui_v2/profile/global_privacy_preferences_v2_test.dart. Existing D004 profile tests unchanged and included in combined run.
- Minimal admission0ee85fd2d98595b0134b6190d3e9af58532990f3, parent2967bf188ffe6587a9f3e6409584ce3686504f60; added only Preferences source/test; claim31. Prior normalized checker SHA2568DBBE73759009EDB7CB03E33275A1082EDCB83A8E95D1532536FC3CFDC824F1A. Initial proposed session owner failed the existing forbidden-owner gate and was excluded; its original ownership and forbidden rule retained. A guarded text edit asserted before writing, then used anchored admission sections. No session/authentication/persistence rules changed. Stored session success copy and legacy UI are not qualified by this correction; the recorded Preferences screen does not display noticeMessage.
- Interrupted qualification: C: became full; Dart compiler could not write output.dill. No tests passed in that attempt. Owned test process34098 stopped with terminal1. Three draft hashes preserved. Founder supplied cleanup report; independently verified134932324352free bytes, unchanged HEAD0ee85fd2 and exact unchanged three draft hashes. No cleanup/deletion performed by this lane.
- After disk recovery, combined run19923 reached34passes then the new restoration test waited on session futures across runAsync clocks. Owned run deliberately stopped (terminal1) and not qualified. Test restoration moved to widget-test clock with pumpAndSettle; no product fix for that harness issue. Two focused D005 tests then passed (chunk3769e9).
- Final exact combined command: flutter test --no-pub test/ui_v2/profile/global_privacy_preferences_v2_test.dart test/ui_v2/profile/global_personal_profile_v2_test.dart --reporter expanded with existing visual capture defines. 42passed,0failures; session91678 final terminal0/fe3635. Includes D004, preferences navigation/return, safe origin, compact insets, persistence, Hindi reopen/restoration and switch to English. These are host checks, not Redmi passes; the helper's return host is Work, not an actual Buy device round.
- Analysis: flutter analyze --no-pub for the three changed Dart owners, zero issues, terminal0/4a2bf7. Diff check passed; formatting limited to changed language block.
- Four D005 native Flutter captures reviewed at320x568/100%-200%. Full disclosure readable; selected summary explicitly says English screens. Enlarged dialog scrolls to choices; tests tap both choices successfully. Existing Hindi label has missing Devanagari glyphs in host font, so glyph appearance is NOT locally visually qualified and requires Android verification. No app font changes or fake glyph substitution. Other PNGs generated by existing suites are retained supporting regression artifacts, not newly audited or blanket visually approved.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d005-local-20260914.
- Device: no new APK/device action. D005 remains open until scoped successor Redmi criteria pass. Frozen514 passes/1177audit artifacts untouched.

| D005 artifact | SHA256 |
| --- | --- |
| rv6-d005-disclosure-text-1.0.png | 89EB98540900A791FE9CE2825D8F89484B0C53245D362962E082564D65F50FEB |
| rv6-d005-disclosure-text-2.0.png | 36C968919D6384CE6C0EF5CF05D753A8D4447BD2A5EAF2434F9D597FE449A2E2 |
| rv6-d005-selected-text-1.0.png | 44EA3664C166C5B0404F53D98E568EEC867554815EC238DC43EDE8B229BEBBD6 |
| rv6-d005-selected-text-2.0.png | EE42B1FA4B4EE90438F3C8A4D8A953E786C71842D064E033B60C529FE73BF7BE |

## RV6-D006 local qualification - 2026-09-14

- Original230-235: Buy Quick > profile > Security > Sign in > Android Back > Security > Android Back must restore Buy. Existing test only used the on-screen Back for its second return; new test uses both actual system Back events in the real MoolSocialApp/Buy/sign-in router, plus the ordinary pushed-route control and exact Buy origin URI.
- Admission9af7e19f79d61cabc5a96ba3be252ec242f2dcbc, parentdce65c05ab54b39751211a608c923c00226e4a26. Only apps/mobile/lib/ui_v2/profile/global_security_v2.dart and apps/mobile/test/ui_v2/profile/global_security_v2_test.dart added; claim33. Existing normalized checker reconstructs SHA256507F26FA6CFBD5C091FEAA6B955C86B88F8B2D1AB741F0CEB04D56B2F53C5FDE. Admission pre_commit/implementation passed and pushed clean/live-equal.
- New regression reproduced before source correction: session15193 terminal1/f90da6; second Android Back left Security instead of Buy. No host claim that Android launcher rendered. Correction adds PopScope to Security with canPop=context.canPop; unsuccessful pop delegates to existing _leave safe return. No shared router/session/authentication/product data changes.
- Final suite: flutter test --no-pub test/ui_v2/profile/global_security_v2_test.dart --reporter expanded with existing visual defines,11passed/0failures, session66862 terminal0/43a091. Previous source-equivalent noncapture run11passed too; counts overlap. Existing success/sign-out/Work/safe-origin/compact checks retained. All providers are review fixtures; no real authentication or sign-out.
- Analysis of both Dart owners: zero issues, terminal0/bb7fe9. Diff check passed. Source reindentation is confined to the Scaffold wrapped by PopScope; no intentional layout change.
- Two actual Flutter captures reviewed: cancellation shows Security; subsequent system Back shows Quick Buy catalogue and Shop rail. Only D006 destinations are visually qualified, not all incidental product content. No broad audit or physical Redmi action. Exact device original230-235 remains pending successor APK; all frozen prior evidence preserved.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d006-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| rv6-d006-android-back-buy.png | 967EB8350DFFD5C2098134F8BDB4742977A309C767E0B47DFC014132F8284EC8 |
| rv6-d006-cancelled-security.png | 832A5496B3DEA606A50D3C3D048C78D31526A94A403D75314F4E9D83319FBACF |

## RV6-D007 local qualification - 2026-09-14

- Scope: original281-283 related-product Back from Saved; full prior product context/position before final catalogue return. No broad audit or device action.
- Admission877656e54eab174f3c4dc698da23799553d8023a, parented0233761e825e22a4d6e14c7d0f0e0073f9ea25. Only apps/mobile/test/ui_v2/buy/buy_v2_product_continuity_test.dart transferred from inherited root claim; source owners already admitted. Claim34. Prior normalized checker reconstructs SHA2562C6140F619B4C8147628C34319EA456CFF8A472EEFABCE8F4C4EA3ADC75B7A51. Gates passed; admission pushed clean/live-equal. Session source untouched.
- Changes: apps/mobile/lib/ui_v2/buy/buy_v2_views.dart enables existing preserveComparisonOrigin for both continuation touch/semantics callbacks. apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart retains per-visit product scroll offsets, restores matching related Back positions with session/sequence/root-depth guards and clears local state on session replacement or invalid procurement scope. Fresh forward details still start at top. Cart/nested Store restoration remains separate.
- Test strengthened the existing continuity expectation, which previously asserted the buggy immediate catalogue return. Initial run96093 failed with selectedProductId null; history-only source fix run18181 returned product but failed original offset0 versus1049. Full correction run48248 passed. Saved/search cases then both passed (15512 terminal0); this includes revisiting an earlier product, Back through both preceding details and their exact offsets, saved flag/bookmark and final root/query.
- Connected source-qualified run: flutter test --no-pub test/ui_v2/buy/buy_v2_product_continuity_test.dart test/ui_v2/buy/buy_v2_partner_catalogue_test.dart --reporter expanded;102passed/0failures,20641 terminal0/97d74b. Exact log connected-regression.log retained below. Includes comparison, cart and Store continuation, variant, paginated and D002 regressions. The two D007 cases in this combined run used default800x600 host size.
- Final test-only viewport adjustment390x844: two D007 Saved/search cases passed with actual Flutter captures (65279 terminal0/2db595). Source unchanged since102-pass connected run; counts overlap, not104 distinct tests. Analysis of exact three Dart owners: zero issues,85774 terminal0/1eadde. No unrelated formatter changes intended; edited test block reformatted.
- Eight actual Flutter captures reviewed (four default host, four phone). Restored lower product content, related rail and Saved marker match the per-visit context; product IDs/offsets additionally asserted. Only D007 navigation/context is visually qualified, not incidental catalogue copy/media. Tests invoke Android Back via handlePopRoute; physical Redmi281-283 remains pending checksum-bound successor APK. No device closure, new APK or child implementation.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d007-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| phone/rv6-d007-original-return-saved-false.png | 4AB0127C93424CC5C7C17D285FA30672E4DA01B87F5D066CF135F4BD786321DA |
| phone/rv6-d007-original-return-saved-true.png | 7575CC4A8716E6B26F316B505C93C11AB0453EF0B621F65547FD6D42DAFA2B3F |
| phone/rv6-d007-related-return-saved-false.png | 1D513C8434884AF85061D77020D7331420DA2BC82CA1E4B44C969675E7A11059 |
| phone/rv6-d007-related-return-saved-true.png | 1BC098ED07607819436DF01F7B5078DDA6DC3B126C2E0B875625C20EC22A42C5 |
| rv6-d007-original-return-saved-false.png | 5F09B82AADDEA7CA7E6177155FAC9B40CF86ACF343D0F753A9771A02D03C0412 |
| rv6-d007-original-return-saved-true.png | D72F5FC28907E36FC9F300A14AC6D7A7724E7DE7E4D4DF2079DD7CDD45DA6ED3 |
| rv6-d007-related-return-saved-false.png | C1D57CFCF13623A32109E4D95C54A4480D871D23F70A925430748717222BD07E |
| rv6-d007-related-return-saved-true.png | C9E18C67CBF6693996664E4678EBF3EDFC3549F65388BD704384F3F4B89F58FF |
| connected-regression.log | 69EE91A18656DA3DCEC0FDBC262BEBDA19AF17458D18D1E28445D7780098ABE3 |

## RV6-D008 local qualification - 2026-09-14

- Scope: recorded Wholesale delivered order PO-240728, capture312; separate Retailer business label from Shree Balaji Retail without changing buyer/order data. No broad audit or device action.
- Admission6104c9cc83d3407a142490e3fd4ac23c2b7cfec3, parent e604579b1f102573766bcaee8bcbf772f9cf96bd. Exactly existing apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart added to Cursor claim35; views source already owned. Normalized prior checker reconstructs SHA256C271B89B203E90D8276D408CA5A0AE897223E6936C43A5D2DA6AC0133F77772E. Initial new-file admission correctly rejected because owner did not exist (757fe7 terminal1); revised to existing screen test, without relaxing the rule. Pre-commit, implementation and handoff passed; pushed/live remote equal. No other lane or forbidden owner expanded.
- Product change: one SizedBox(width:8) between the fixed-width label and Expanded value in _DecisionRow. Existing large-text stack stays unchanged. This shared row is also exercised by the connected screen suite; no data/session/provider contract changed.
- Focused regression: real rendered Wholesale delivered order; tap View order; verify exact buyer type/name, normal-text horizontal gap or enlarged-text vertical separation, unclipped text within viewport, and Android Back retaining delivered tab/query/order and empty cart. 320x800 and360x800 at100/200% text. Before correction normal-text cases reproduced gap0 (32251 terminal1/a0d201); enlarged-text cases already passed. Initial test compiler error used nonexistent cartItemCount (86a3d1 terminal1), corrected to existing cartLines contract.
- Four focused cases passed with actual Flutter capture (84970 terminal0/f65a67). All four reviewed: clear buyer boundary at100%; stacked complete buyer name at200%. Captures show scrolled order content at200%; offscreen adjoining content is not claimed as another defect. Only D008 affected layout is visually qualified, not incidental order claims or provider data.
- A formatter touched unrelated existing test formatting. During its removal, an explicit UTF-8 omission caused a test-file write error (452bac terminal1). Recovered the exact HEAD test content plus only the D008 block using explicit UTF-8; verified removing that block yields original HEAD content exactly (045686 terminal0). No user edits lost. Final regression below ran after recovery. Product source unchanged from reviewed captures; test behavior unchanged.
- Final connected run: flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --reporter expanded. 242passed/0failures, session56148 terminal0/2bdadc. Includes D008 four cases, order/invoice recovery, checkout, shared decision layouts, Store and Buy navigation. Focused four overlap this total. Final analysis of views and screen test: zero issues,97680 terminal0/157934. Diff check passed.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d008-local-20260914. Local checks do not establish physical Redmi closure. Capture312 reproduction remains pending checksum-bound successor APK; no APK/build/install/device/child implementation performed. Frozen514 passes/1177 evidence artifacts preserved.

| Artifact | SHA256 |
| --- | --- |
| rv6-d008-buyer-320.0-text-1.0.png | B6360C16265C917F2BCD1F127410F7CCFEB358E87E695796C3491032C9BFCB34 |
| rv6-d008-buyer-320.0-text-2.0.png | 1DE583AD901DE72F0E0375FDD3867FE6D5B9A53939851D30E6F9CD596EFB59C5 |
| rv6-d008-buyer-360.0-text-1.0.png | FEDAE8779E2ACF15738FADF33A005048E56FDD54D9299BA3F25D3F6F6EC47D4D |
| rv6-d008-buyer-360.0-text-2.0.png | C6A4EAE6EE9B679AD2B99CD3B4282496D2078D6EE8D4EFFCBD779FC7652BB3C6 |
| screen-regression.log | B2F4293F790A6829AC7FEA5DE183A5155E1B8E4F6F821833F6FC92C278DDECEB |

## RV6-D009 local qualification - 2026-09-14

- Scope: original358-360 unsubmitted confirmation deep link falsely showed Order placed/zero delivery totals/current saved address. No physical device, link delivery, payment or provider action performed in this implementation phase.
- Source owner apps/mobile/lib/ui_v2/buy/buy_v2_views.dart; test owner apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart already admitted. No new ownership/control/router/session/backend changes. Start from D0080fe77e604fc4787a3b1584a3c0e3e92bff1e53e5, clean/live-equal with handoff gate pass.
- UI guard applies inside BuyV2ConfirmationView to all callers, including initial confirmation route and direct rendering. Success requires existing confirmed checkout state, nonblank purchase ID, positive confirmed product count, nonempty accepted-order collection, and every order having a nonblank ID with matching purchase ID. It does not submit an order or derive identity from the link/cart/address. Missing/inconsistent context renders Order confirmation unavailable with View orders and Continue shopping; no success mark, totals, delivery list or saved-recipient claim. Recovery preserves cart, saved address and existing orders.
- Valid confirmation header uses recipient/addressLine snapshots from confirmed orders. Missing address is explicitly unavailable; split addresses direct to order details. Current selectedAddressOrNull is no longer used to invent a destination for a previous purchase. Provider-authenticated acceptance and persistence correctness remain outside this fixture/local qualification.
- Baseline reproduction failed as expected: a08778 terminal1 found Order placed after BuyV2Screen initialView confirmation with no submitted purchase. Source fix then passed eight phone entry/recovery combinations:320x568,100/200% text, empty/retained cart, Orders/Shop actions (84232 terminal0/08ce43). Tests assert no success/delivery claim, retained order IDs/cart quantities/address and recovery destination. Host initialView covers the screen reached by the recorded unchanged router mapping; actual Android HTTPS dispatch remains for Redmi358-360.
- Added six inconsistent-context tests: missing/blank purchase reference, mismatched purchase family, empty accepted orders, unconfirmed state, zero products. One accepted confirmation test proves recorded recipient/address wins over unrelated saved address. Existing multi-destination successful purchase and invoice recovery/unmounted-session checks remain. Invoice fixture previously rendered a historical order without a confirmed purchase; updated only that fixture to provide explicit matching confirmed identity/state and keep invoice data missing. No assertions removed to admit an unconfirmed state.
- Connected final-source suite: flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --reporter expanded;257passed/0failures,22527 terminal0/94ec6e, screen-regression.log. Analysis initially found two missing-brace test style infos (ba6edd terminal1); wrapped the two single-statement test conditions without changing source/assertions. Final18 focused checks passed (82838 terminal0/931f3d), final-focused.log; these overlap257, not275 distinct checks. Final analysis zero issues (061f0f terminal0). Diff check passed. Formatter changes outside confirmation source class and D009/confirmation-fixture test regions removed; existing D008 and other test text preserved.
- Two actual Flutter recovery captures reviewed at100/200% text. Title/explanation/actions readable; enlarged content scrolls and both actions remain operable. No fabricated Order placed or recipient/address text. These captures precede formatting-only source changes; behavior/layout unchanged. Captures do not qualify actual recipient binding, backend acceptance, payment, restored authenticated purchase or physical Redmi.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d009-local-20260914. D009 remains open for exact successor-APK Redmi358-360; no new APK or device closure. Frozen514 passes/1177 artifacts untouched.

| Artifact | SHA256 |
| --- | --- |
| final-focused.log | 9FF9D40472DEC6B3A38E535651960CA646AFD081EC0E3551164AEA81CDE74A2E |
| rv6-d009-unsubmitted-text-1.0.png | 818A2D94831E3FC9828B3C663DA0475FAFE8E51A1AB6DDCC7D87A8684594A573 |
| rv6-d009-unsubmitted-text-2.0.png | D3A8CDCC6AC3FE0A5CB677C9B2200129BD223A8699432C6E1FC31087F9C81EEB |
| screen-regression.log | FF59F96A810E1D708A9671D956F0B97B4A688B153296042415DC657733B15213 |

## RV6-D010 local qualification - 2026-09-14

- Scope: original371-373 order MS-240782 -> generic delivery-delay recovery -> Return to order incorrectly selected Shop. Start e29194eb14d0d90ebf37eff329705e8ee4ec2381; prior D009 clean/live-equal and handoff passed. Source/test already owned; no ownership/checker/policy changes.
- Change: apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart no longer writes initialDestination before session.openRecovery in _applyInitialState. Existing recovery origin records the current destination/view/order/query, which its existing restore logic already handles. All other initial route branches unchanged. No shared session/router/Help/Chat/backend source changes; no new route parameters.
- Regression reproduced wrong destination before fix:3e62b2 terminal1, expected Orders, actual Shop. Initial test compiler used nonexistent delay enum (d2e9c0 terminal1), corrected to existing deliveryDelay. Focused capture run5017 passed button/Back but failed two Help expectations (d98a72 terminal1): the test incorrectly expected GlobalHelpSupportV2. Inspection showed this action opens Shop Chat; without a router it honestly reports unavailable. Corrected test setup/assertions to verify that fallback preserves order; added separate GoRouter-bound Chat destination and Android Back tests.
- Nine D010 cases:360x800 at100/200% for warm tracking->recovery->button, Android Back, and no-router Help fallback; two routed Help/Back cases assert exact order/sub=orders/view=tracking return URI and retained order; cold screen entry preserves existing Wholesale query/destination. Cart/order IDs retained and no exceptions. Router Help uses an inert conversation destination to test the navigation boundary, not actual Chat/provider behavior. No messages sent. All9 passed after correction (86377 terminal0/e1f195).
- Final-source connected suite: flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --reporter expanded;266passed/0failures,83422 terminal0/4cf045, screen-regression.log. One redundant test non-null assertion flagged by analysis (94393 terminal1/30bfaf) was removed; no application code or expected value changed. Final focused9passed,78009 terminal0/d593c9, final-focused.log. Counts overlap266. Final analysis of exact two Dart owners zero issues (0727aa terminal0). Diff check passed. Test formatting limited to new D010 block; existing tests preserved.
- Two actual Flutter captures from successful button cases reviewed: original MS-240782, Orders heading and selected Orders rail at100/200%. The earlier capture run's Help-test failures are not presented as passes; the two button captures remain valid evidence of unchanged final source. No incidental order copy/provider/live status claim qualified. Actual Android HTTPS delivery371-373 remains for checksum-bound Redmi successor APK.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d010-local-20260914. No APK/device action/closure, child implementation or broad audit. Frozen514 passes/1177 artifacts untouched.

| Artifact | SHA256 |
| --- | --- |
| final-focused.log | D155195DC60169B2E0A09A1E2421868AE6C8D6FFE17CB89378806C8235A3564A |
| rv6-d010-orders-return-text-1.0.png | 55A9CB81A2751236A0058E41BD97660A422E78C66CC1384992656E0501C38A6C |
| rv6-d010-orders-return-text-2.0.png | 6D5ADA0F4E5D0D9F526A6B0B79FD929A4D1C17BF8D0AFAC78EB21D5CE0B692EA |
| screen-regression.log | C70AA788E35A6BDB8073A5945683211893BDC7A52FA0F03FAEB9C8D75FEB2073 |

## RV6-D011 local qualification - 2026-09-14

- Scope: original407-410 Wholesale Fresh tomatoes w-tomato repeated summary-only Highlights, Specifications and generated Description. Start6fcb36cbd8e9ae1b42ee7f97c31230633b50f0f1; previous D010 clean/live-equal, handoff passed. Existing source/test ownership only; no policy/coordination/backend/provider changes.
- Source apps/mobile/lib/ui_v2/buy/buy_v2_views.dart: extend exact summary deduplication to Shop and Wholesale destinations (Bulk uses Wholesale); compare displayed brandLabel as well as raw brand so Brand not provided does not become a redundant specification. Preserve unique values and supplier-specific description. Care condition remains unchanged. Product details, compliance/pack/price, MOQ controls, policy, ratings and reviews retained. Move content top spacing inside the section only when content exists, preserving loading/error card spacing and avoiding an empty section gap.
- Tests apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart:12 cases (Shop/Wholesale/Bulk; default versus distinct supplier fixture;100/200% at360x800). Default Wholesale w-tomato reproduced redundant Brand not provided before fix (cbff95 terminal1). Assert repeated summary absent from extra content; unique highlight, Handling specification and supplier description retained; price/pack information stays available; exact10px compliance-to-trust gap when no content; product and catalogue Back/context/cart preservation. Supplier details are explicit local test fixtures, not live published claims.
- Initial12 passed (19350 terminal0/43f024); four root captures revealed an extra empty gap left by removed sections. Corrected section spacing and added geometric regression, then12 final capture cases passed (14748 terminal0/0ad809). Four final/ captures reviewed: no redundant cards/gap for default content, complete distinct content at100/200%, price/MOQ/Add control retained. Four root captures retained as superseded spacing evidence. Incidental supplier/trust/delivery data and physical Redmi are not qualified by these visuals.
- Formatter output initially touched unrelated existing formatting; retained only content-section/source spacer and D011 fixture/test blocks, restoring every other region from unchanged HEAD. Final analysis initially found one missing-brace test style info (aa6fb9 terminal1); corrected Bulk test setup braces. Final analysis of two Dart owners zero issues (9f06ac terminal0). No assertion or product behavior changed by that style fix.
- Final connected suite: flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart --reporter expanded;278passed/0failures,80776 terminal0/8d9d42, screen-regression.log. Shorter pages can affect related-product scroll returns, so replayed D007 related products from Saved false/true on final source:2passed/0failures,bafe48 terminal0,d007-affected-regression.log. Focused12 overlap278; the two D007 checks are separate. Diff check passed.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d011-local-20260914. No APK/build/install/device action or closure; physical407-410 remains pending successor Redmi APK. No broad audit or child implementation; frozen514 passed records/1177 artifacts preserved.

| Artifact | SHA256 |
| --- | --- |
| d007-affected-regression.log | FD3051AF73B929B607342FA20D7EEFB484890A8C35DC9786FBE6DFFE0E3052C4 |
| final/rv6-d011-wholesale-unique-false-text-1.0.png | F08D7579C5DC48B6BD691D29DE5FFCCF458B9A0F51F07D28A69B7BFD353AE362 |
| final/rv6-d011-wholesale-unique-false-text-2.0.png | EEF4B34D5F4D5A3454A4B74033CAE4D5BA6C799F7E6C22817F8CB0071E833F11 |
| final/rv6-d011-wholesale-unique-true-text-1.0.png | 659538C4349D3EAE322FBC4AE8B1D698F0B87D838F30F9479502365DFFD67A9E |
| final/rv6-d011-wholesale-unique-true-text-2.0.png | 9C5A1F7CF293C1B1823A71E1D0892BEBA5C3B65C9DFAE7D24D6ADF91EE380705 |
| rv6-d011-wholesale-unique-false-text-1.0.png | FB7B99E16527EE480CEFCFCD4B72DFB7CBDC2C2885F183F5C5E36A20D6C9E6F2 |
| rv6-d011-wholesale-unique-false-text-2.0.png | 0D680A9C533BCB1371611F0A082042AB4BD2B478F8C21257D9B9E6271587A4F9 |
| rv6-d011-wholesale-unique-true-text-1.0.png | 2251195C7FBEDC619864656A47083D6F81915F3452F5B74E5776CFAE3AEA9087 |
| rv6-d011-wholesale-unique-true-text-2.0.png | 161EFB73C2F8CA944BCDDE03B670F7DBD7494A54CD05C90B69BD6C7F45F20D7B |
| screen-regression.log | 370DC9503D123E6736447C30FB6D93C7E188740CCEDD4491DD1C5D4187123C88 |

## RV6-D012 local qualification - 2026-09-14

- Scope: original423/428 closed Pet Family Store View all count claimed4available products while cards rejected ordering. Startb46c582bc747c15576f8349b0c2fd144d452f02b; prior D011 clean/live-equal, handoff passed. Source apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart and test apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart already owned; no owner/governance/backend changes.
- Full Store header now says count plus product/products listed using neutral muted color, not green availability styling. Product array/count, status, orderability, Add and navigation wiring unchanged. Paged catalogue uses its existing separate identity/search header and did not contain this available-products claim.
- Six focused cases open actual Product->Pet Family Store->View all at360x800/100and200% text with all-closed, all-open or mixed provider fixtures. Assert exact neutral4products listed, no available-products text, blocked/open cat-food card action as appropriate, no exceptions, and Android Back preserving Store/product/cart context. Initial expected-copy test failed before correction (55e2b0 terminal1).
- Local dependency found on the required closed-Store setup path: after count correction,200% closed case failed with111px horizontal overflow, five other cases passed (94161 terminal1/c8e2dc). Diagnostic preserved original Flutter error handler and identified existing _PublicStoreTruthPanel status Row at catalogue6261 (31495 terminal1/afd7c8), separate from the count label. It had no width constraint for Closed/next-opening text. Minimal within-owner prerequisite: wrap only that Text in Flexible; preserve wording, opening time, status visibility and availability behavior. Added complete RenderParagraph/no-width-overflow assertion before View all. This is recorded explicitly as D012 affected setup qualification work, not attributed falsely to the count text change, not a broad audit or hidden new feature.
- Six passed after status wrapping (11023 terminal0/f9287e). Final test version adds pre-View-all status captures; no diagnostic/error suppression remains. Final capture run6passed/0failures,30090 terminal0/7f814d, final-focused.log. Final analysis of two Dart owners zero issues (697601 terminal0). Only D012 fixture/tests formatted; previous tests preserved. Diff check passed.
- Connected affected suite: flutter test --no-pub test/ui_v2/buy/buy_v2_partner_catalogue_test.dart --reporter expanded;76passed/0failures,66766 terminal0/1b36c1, store-regression.log. Covers full/paged Store catalogues, compact fit, Cart, supplier/brand scoping, collection branches and Back. These76 plus final6 are82distinct local checks; prior six runs overlap.
- Four qualified/ Flutter captures reviewed: closed status before View all and full listing count at100/200%. Status wraps completely, count remains neutral and closed cards keep information instead of Add. Media placeholders and other incidental card content are not qualified by this count/status review. Earlier root/final captures retained as preliminary evidence; qualified/ is final visual set.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d012-local-20260914. No device/APK/build/install/closure or child implementation. Original423/428 plus affected closed-status setup must pass successor Redmi APK verification. Frozen514 passed records/1177 evidence artifacts preserved.

| Artifact | SHA256 |
| --- | --- |
| final/rv6-d012-closed-store-count-text-1.0.png | 4B28FD5851D38FC689B1B60E81A44A6B5DF1B8254F05AB62CCA3B98D2F97D9E6 |
| final/rv6-d012-closed-store-count-text-2.0.png | 2D80835979AE8424A56AF15078EBE9E06AEAC9F0D06E7AE5775880451874420D |
| final-focused.log | 9D2109873DE2008D532251847868E3993A1C33024AB94925882DB2C462B4E478 |
| qualified/rv6-d012-closed-status-text-1.0.png | 691949341142E1E9A907FD0928833FC57889AA1264C511BE5EC088C86ED4BAA6 |
| qualified/rv6-d012-closed-status-text-2.0.png | 97C61F62E16A840B229DE728345F20A1E751495ACAB415B31610B3C6AFA63671 |
| qualified/rv6-d012-closed-store-count-text-1.0.png | 4B28FD5851D38FC689B1B60E81A44A6B5DF1B8254F05AB62CCA3B98D2F97D9E6 |
| qualified/rv6-d012-closed-store-count-text-2.0.png | 2D80835979AE8424A56AF15078EBE9E06AEAC9F0D06E7AE5775880451874420D |
| rv6-d012-closed-store-count-text-1.0.png | 4B28FD5851D38FC689B1B60E81A44A6B5DF1B8254F05AB62CCA3B98D2F97D9E6 |
| store-regression.log | 5200D4A005D0CC0406F39E4A20F4E7EABFFF73E15C5F6BE9142B70DB9DDECFEA |

## RV6-D013 local qualification - 2026-09-14

- Scope: original431-434 Pet Family Store Ask opened a Store-only conversation whose expansion exposed no facts/action. Start4194ea5985bc95ddd228f25011ccf198dda38926 after D012 clean/live-equal handoff. Exact Chat presentation owner admitted separately at da9555f36919292a19f74ee1bff162a5730dec27 under founder's limited standing admission authorization; claim36, registry4584. No new policy/checker change in this implementation slice.
- Changed source owners: apps/mobile/lib/features/chat/screens/chat_thread_screen.dart and apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart. Tests: apps/mobile/test/ui_v2/buy/buy_v2_shop_chat_test.dart and apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart. All four are admitted owners. No auth/router/backend/provider implementation changed.
- Context card now uses a static ListTile only when decisionFacts is empty and productAppRoute is unavailable. Same identity/icon/subtitle, no tap callback, expansion arrow, empty divider or padding-only expansion. Existing facts and applicable View product actions retain the original ExpansionTile and children. No missing commercial facts invented; drafts remain unsent.
- Initial Store-only expected-static assertion reproduced the original ExpansionTile before correction (64493 terminal1/33602c). An earlier test placement compilation error was corrected by moving the new block after the existing local readyJourney helper. A Wholesale setup tap initially missed its target; the final test uses the product's vertical Scrollable and asserts hit-testability. No error handler suppression or weakened assertions remains.
- Required connected-return finding: the new real-MoolSocialApp check returned to the product without its Store overlay, from both normal Buy-root setup and direct product entry, using both Android Back and visible Chat Back. The existing custom-router Store return test alone had not exposed it. A500ms diagnostic wait did not fix it. Traces confirmed _openStoreQuestion/_openStoreQuestionRoute ran and the route stack changed from RouteMatch+ImperativeRouteMatch to RouteMatch, but the awaited push continuation did not run within the verified return interval. Do not infer an unproven underlying router/library cause. Original Buy source bytes were preserved as buy-screen-before-return-trace.dart (SHA256 B38511612A9EF26E749FBE547F8ED7CA2DFB16DC8C71C4F7C118E86F45FD371F); all temporary source traces were removed and byte restoration verified before correction. Truncated earlier output was not treated as a pass; bounded log reads supplied the evidence recorded here.
- Minimal Buy-owned return correction: observe this Buy route becoming visible after being covered by the Store enquiry; restore its pending Store anchor after the frame. Existing push completion also uses the same one-shot restoration. Bind the request to a generation, session and account identity; reject stale/different account or procurement scope, consume only the matching pending anchor, and avoid duplicate Store overlays. This is an explicit D013 connected-return qualification dependency, not a claim that the empty-card change caused the navigation failure. D014's separate warm-order-link/modal failure remains unimplemented/unqualified.
- Final focused matrix:8 cases at390x844,100/200% text, Shop s-dog-food and Wholesale w-notebook, normal and direct-link entry. Each tests the static card/no expansion, exact Store identity, unchanged unsent draft, visible Chat Back, repeated enquiry, Android Back, exact Store restoration, empty retained cart and one further Back to the original product. Eight passed (64451 terminal0/0b4c40), final-focused.log. An additional account-context fixture test rejects and consumes an old Store return after authentication-context change, including when the old context flag is restored. No real authentication action occurs in that fixture.
- Connected final source regression: flutter test --no-pub test/ui_v2/buy/buy_v2_shop_chat_test.dart test/ui_v2/buy/buy_v2_screen_test.dart --reporter expanded;328passed/0failures,80786 terminal0/aa2a37, connected-regression.log. Includes all9 new cases, existing nonempty product/order context and facts, Cart-origin Store Chat return, Buy navigation and previous relevant correction checks. Focused8 overlap328; do not add counts. Analysis of the four Dart owners: zero issues,6770 terminal0/5f6765,analysis.log. Diff check passed; unrelated formatter changes restored, previous tests preserved.
- Eight actual Flutter captures in qualified/ reviewed: static Shop/Wholesale cards and the correct restored Store at100/200%. Identity remains readable in the card; no empty expansion control; corresponding Store/Ask/product context restored. These captures qualify D013 presentation and return destination only, not unrelated Chat chrome, supplier claims/media or backend behavior. Captures preceded only the final rejected-account-anchor cleanup; connected328 replayed that final guard as well. No visual layout changed after the captures.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d013-local-20260914. Diagnostic/preliminary images and logs retained separately; qualified/ is the reviewed visual set. No APK/build/install/device action or device closure. Original431-434 and directly affected Store enquiry return still require successor Redmi qualification. No broad audit or child implementation; frozen514 passed records/1177 artifacts preserved.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 4EAFEFE91FBD66446B14C0CB34A422D4FA58F70DD3AE4569E43C6423E0AE43B9 |
| buy-screen-before-return-trace.dart | B38511612A9EF26E749FBE547F8ED7CA2DFB16DC8C71C4F7C118E86F45FD371F |
| connected-regression.log | 714BE2D466C0BBAF6BD5D87C848416DC8BE5494C71790BC7A2CF2DF7AB75AF7C |
| final-focused.log | 94A6B35BA327CEC6C522EC9573F7D09B54F2DFF676D14C5A2848E175C2126679 |
| qualified/rv6-d013-static-context-s-dog-food-text-1.0.png | 88E7BD4EAB0EEF06770B87069D2F7A120CB40EA1D2FD4EB0AF20DD81E086F86E |
| qualified/rv6-d013-static-context-s-dog-food-text-2.0.png | FCA9B923E45B439A737DE9FC691A250E10EDA8ADA6A8419C66F0E875977E832E |
| qualified/rv6-d013-static-context-w-notebook-text-1.0.png | 331994766DE3D29B7F1165436FC8E404A654F9E5384BB5DE440A3778A082596B |
| qualified/rv6-d013-static-context-w-notebook-text-2.0.png | 63255276B482ED0900CE133F046686D481289A5D86CDA2116CE654AD3D598C38 |
| qualified/rv6-d013-store-return-s-dog-food-text-1.0.png | C2469070C31BC66BD71B6E3BF24BC6EC816932EF4D4C9DDF47683EAC123FCD1A |
| qualified/rv6-d013-store-return-s-dog-food-text-2.0.png | 8DFFB8A64D9DF1181C6565E4CD6FA885B93867275AFDB53A25FB2B6A2BC4E578 |
| qualified/rv6-d013-store-return-w-notebook-text-1.0.png | FE4B26B1984A1DC45156DD32BC60123463435DADF1F3AE0BEEF963AC5C141CC7 |
| qualified/rv6-d013-store-return-w-notebook-text-2.0.png | 0AAD42149C3EDFD752DEDD7ED62972E4BC2ACA31C83C7431614C7AAAEC53E7DE |
| return-content-back.log | BAB2795F5BFB51E921D195C5158C5EC61B7DADA5B486D5BE8E8E1F90EA878720 |
| return-diagnostic/rv6-d013-return-diagnostic-s-dog-food-text-1.0.png | E3AA45D33D04C28695B45207B23B05572EC80484DED319B19F9B270A4DCFA4D6 |
| return-diagnostic/rv6-d013-static-context-s-dog-food-text-1.0.png | 88E7BD4EAB0EEF06770B87069D2F7A120CB40EA1D2FD4EB0AF20DD81E086F86E |
| return-diagnostic.log | 440753BAD1DEF712B2A9AC40C1E9DAE2A2AAE39B2DBA262CABC057037C613A42 |
| return-entry-trace.log | BAB2795F5BFB51E921D195C5158C5EC61B7DADA5B486D5BE8E8E1F90EA878720 |
| return-root.log | BCC315F7B9BBBED4088CE8ED4E4A27859E64796F724D03FC0120F88A5A65064C |
| return-trace.log | 25175D9A79FDBABFAB336F15297E274DAF235DCA34E2A47444345F182FC2DC04 |
| return-visibility-fallback.log | 507CD7BADF52E62D69C064EEC329A680DB6738234C10A01EF6A45195F3429032 |
| return-wait.log | 826411DA99ABF5A1C8C9F23D44A9AF20E34504E31B32CA5219AA8C03362BF66C |
| route-matches.log | 93625CC54BEE9E2214F4A1973B901F52EB8F21F48986A8D3DE3378F3EE5B24E0 |
| rv6-d013-static-context-s-dog-food-text-1.0.png | 88E7BD4EAB0EEF06770B87069D2F7A120CB40EA1D2FD4EB0AF20DD81E086F86E |
| rv6-d013-static-context-s-dog-food-text-2.0.png | FCA9B923E45B439A737DE9FC691A250E10EDA8ADA6A8419C66F0E875977E832E |
| rv6-d013-static-context-w-notebook-text-1.0.png | 331994766DE3D29B7F1165436FC8E404A654F9E5384BB5DE440A3778A082596B |

## RV6-D014 local qualification - 2026-09-14

- Scope: original440-444 declared HTTPS order link while Pet Family Store overlay was open after Other Store/Back caused Navigator !_debugLocked and lost the requested destination. Start4fccb654d602319e4b7352c5160e93c2bbf4e485 after D013 commit/push, handoff passed and clean exact live remote equality. Existing owners only: apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart and apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart. No admission, policy/checker, shared-router, auth, native or backend change.
- Corrected platform-channel reproduction failed in both root Store and Other Store round-trip cases before the source fix (54619 terminal1,platform-reproduction.log). First error: NavigatorState.finalizeRoute assertion entry.currentState == _RouteLifecycle.popping while notifying the Store AnimationController; followed by navigator.dart5909 !_debugLocked, matching the recorded Redmi navigation failure. The Store helper manually reversed its custom controller after showModalBottomSheet returned, including when a platform route replacement had already removed the sheet.
- Minimal correction: capture that ModalRoute<String>, let Navigator control dismissal, and await its completed future before disposing the supplied controller or opening a selected destination. Removed the extra manual reverse. Recursively opened Other Stores use the same corrected helper. Existing sheet UI, motion settings, product/Cart/Ask callbacks and business data are preserved; formatter reindentation is confined to this changed function. No assertion suppression, timer workaround, route exception or safeguard change.
- Test harness uses documented incoming flutter/navigation pushRouteInformation with the declared https://moolsocial.com/app/buy/order/... URL, pumps the framework, verifies the channel reply and checks the resulting actual MoolSocialApp screen/session. Initial unsupported binding convenience-method compilation failed before product execution (baseline-reproduction.log); it was replaced with the supported channel API. References: [Flutter navigation channel](https://api.flutter.dev/flutter/services/SystemChannels/navigation-constant.html), [test platform-message delivery](https://api.flutter.dev/flutter/flutter_test/TestDefaultBinaryMessenger/handlePlatformMessage.html), [route completion contract](https://api.flutter.dev/flutter/widgets/TransitionRoute/completed.html). Host channel simulation is not Android intent-filter or device acceptance.
- After the source correction, both original paths reached the requested order with no navigation exception; a Saved-count assertion incorrectly assumed an empty fixture (actual existing Saved entries were preserved). Final assertions compare the complete pre-link Saved ID set, current mounted Buy session identity, retained Cart quantity and selected address. Expanded first run15passed/4failed only on test setup/recovery selection:200% lazy Other Store cards required scrolling before ensureVisible, and missing-order recovery uses the actual moolsocial-family-root-buy-tap. Corrected those actions without changing product behavior or dropping assertions. Bounded diagnostic output was reread using UTF8 after a console-encoding error; evidence files remain intact.
- Final19 focused cases at390x844: Shop s-dog-food and Wholesale w-notebook; root Store, Other Store still open, Other Store round-trip and full catalogue;100/200% text. Two missing-order cases exercise explicit recovery without substituting another tracking record; one delivers the link during Store opening motion. Every case preserves Cart, exact Saved IDs and selected address, confirms old Store/full-catalogue overlays are gone, and verifies Back or explicit Shop recovery. Final19passed/0failures,96827 terminal0/2ad7f4,final-focused.log.
- Six final/ Flutter captures reviewed: exact requested order after Shop Other Store return and after Wholesale full catalogue, plus missing-order notice and usable Orders destination, at100/200%. Previous qualified/ captures are retained preliminary evidence from the partially completed matrix; final/ is the final visual set. This verifies the scoped destination/notice and visible fit, not live delivery/provider truth or broader order-screen acceptance.
- Final connected regression: flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart test/ui_v2/buy/buy_v2_shop_chat_test.dart test/ui_v2/buy/buy_v2_partner_catalogue_test.dart --reporter expanded;423passed/0failures,95411 terminal0/66f1b6,connected-regression.log. Covers normal sheet closing, nested/full Store and Cart/product navigation, D013 real-app enquiry return/draft retention, other Buy/Chat contexts and compact/reduced-motion cases. Focused19 overlap423. Analysis of the two Dart owners: zero issues,7d6fa0 terminal0,analysis.log. Diff check passed; prior test bodies preserved.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d014-local-20260914. No APK/build/install/device action or closure. Original440-444 still require checksum-bound successor Redmi verification, including real Android link dispatch and Back behavior. Release/device behavior is not inferred from host assertions. No broad audit or child implementation; frozen514 passed records/1177 artifacts preserved.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 067DC7E66F5A56A4B8E3E826990362480F2B5B2A59496B0BF4C95F036AE37C39 |
| baseline-reproduction.log | 7FB68485F278CB5894421EC32CC91E4CA584EA2F563F6ECBBC37EE5EB0EC570B |
| connected-regression.log | 80B8EFF5DDAC27D3E6C469134D154B24535996A5532A0897602B88B657BADA13 |
| final/rv6-d014-s-dog-food-full-missing-order-text-1.0.png | 2A47D602C6C5055CA60DD733F144A3041DCD0F635352A0C181E42967D9457480 |
| final/rv6-d014-s-dog-food-full-missing-order-text-2.0.png | B05D8F279FDB7658AB8E1D7074AAA05F0C52D05DF10716632FBE6BFA55B4DEB5 |
| final/rv6-d014-s-dog-food-other-return-MS-240782-text-1.0.png | 127F05F7711394A931E2E82ABFE87F0497F97AF93325A69AEE7F8BEC5A7188E6 |
| final/rv6-d014-s-dog-food-other-return-MS-240782-text-2.0.png | CB60B177147AAAC4B4512072E5A74427E840046C4E954DBC84A8793FD90F4E2F |
| final/rv6-d014-w-notebook-full-MS-240782-text-1.0.png | 127F05F7711394A931E2E82ABFE87F0497F97AF93325A69AEE7F8BEC5A7188E6 |
| final/rv6-d014-w-notebook-full-MS-240782-text-2.0.png | CB60B177147AAAC4B4512072E5A74427E840046C4E954DBC84A8793FD90F4E2F |
| final-focused.log | 1B2EC96236EBF74DCF6A209E20062B124451A4C021CAE5E51B3931982198A29F |
| focused-matrix.log | 4905FC9594D0F6F87E6B6722D281E351718C5FF21CF6107A2442DFADBAD167C3 |
| platform-reproduction.log | 7CAFBDA7105C9A523826FED9BE477CAB27B69B81C28C29A91C14CCFF2EE7F732 |
| qualified/rv6-d014-s-dog-food-full-missing-order-text-1.0.png | 2A47D602C6C5055CA60DD733F144A3041DCD0F635352A0C181E42967D9457480 |
| qualified/rv6-d014-s-dog-food-full-missing-order-text-2.0.png | B05D8F279FDB7658AB8E1D7074AAA05F0C52D05DF10716632FBE6BFA55B4DEB5 |
| qualified/rv6-d014-s-dog-food-other-return-MS-240782-text-1.0.png | 127F05F7711394A931E2E82ABFE87F0497F97AF93325A69AEE7F8BEC5A7188E6 |
| qualified/rv6-d014-w-notebook-full-MS-240782-text-1.0.png | 127F05F7711394A931E2E82ABFE87F0497F97AF93325A69AEE7F8BEC5A7188E6 |
| qualified/rv6-d014-w-notebook-full-MS-240782-text-2.0.png | CB60B177147AAAC4B4512072E5A74427E840046C4E954DBC84A8793FD90F4E2F |
| route-completion-fix.log | D75FF63DF2B852FB56E5CC0652314E8D753517D706712B37484F75FE79262F7E |

## RV6-D015 local qualification - 2026-09-14

- Scope: original483-490 Recently Viewed closed Adult dog food and unavailable Daily care shampoo incorrectly offered Add without sheet-local recovery. Start da26e9ff88616262c6677b0cb7903fd952b42656; D014 committed/pushed, clean and live remote-equal at previous boundary. Existing36-owner implementation gate passed (1ec3d8,terminal0). No new owner admission or policy/checker change.
- Source owner: apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart. Recently Viewed rows now use the existing buyV2ResolveProductOfferDecision, matching catalogue orderability. Non-orderable rows show its closure/unavailability detail in neutral styling and a Details control opening the exact product. Available rows retain Add/Added. Session.addProduct remains authoritative and unchanged; rejected additions now show the actual notice in a visible modal above the sheet, with Close and View product recovery. No bypass of Store closure, availability, procurement or account requirements.
- Test owner: apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart. Six new cases exercise real Shopping tools -> Recently Viewed -> Details/product -> Android Back with the recorded two Shop products and a ready Wholesale notebook whose business verification rejects Add. At320x568,100/200% text and48px bottom safe area: no blocked Add, exact explanation, action above system navigation, dialog Close/retry/View product, exact history/product/address and unchanged Cart. Previous test bodies preserved; formatter changes outside the new block were discarded without discarding user work. Local entry uses the normal catalogue tools; original SavedShop setup and physical taps483-490 remain for the authorized successor Redmi round.
- Initial existing Recently Viewed suite29passed (42085 terminal0/1ca02e). Initial new-test failures were setup taps beneath the sheet footer and an assertion expecting the word unavailable instead of the shared decision's actual cannot be added to Cart wording. Corrected scrolling/settling/hit-test preconditions and exact expected explanation, without weakening the product constraints. focused-first.log and focused-visible.log preserve those failures; focused-recovery.log then6passed (95346 terminal0/18fb1e).
- First actual Flutter capture run6passed (40459 terminal0/6d159d). Visual review found the new default dialog heading consumed too much space at200%. Changed only that dialog to titleMedium and explicit scrolling, preserving text scaling. Final6cases pass (79010 terminal0/91d2e1), including an assertion that the final explanation line is reachable above the actions. Final12captures reviewed: six row action views, three200% initial scroll views, two dialog views and the200% dialog end. The six final row images are hash-identical to their already inspected preliminary counterparts; final dialog and scroll-start images were inspected directly. At200% the existing history list requires vertical scrolling; first and action positions are retained, not claimed simultaneously visible. Unavailable supplier media remains an explicit placeholder, not verified media delivery.
- Connected regression before the two-line dialog fit refinement: flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart test/ui_v2/buy/buy_v2_recently_viewed_test.dart --reporter expanded;339passed/0failures (96591 terminal0/fc2d20). Final affected verification after refinement: six focused cases above plus29existing Recently Viewed cases (26066 terminal0/9cadba); analysis of both Dart owners zero issues (c2e8d0 terminal0). Counts overlap and must not be added as unique coverage. Final test-only formatting is semantic-preserving. Full all22 combined regression remains required before APK.
- No APK/build/install/device action or closure. D015 remains open pending complete checksum-bound successor Redmi verification of483-490 and directly affected recovery; no host-to-device qualification claim. Frozen514 passes/1177 artifacts unchanged. No backend, broad audit, OPPO, integration or child implementation.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d015-local-20260914. The historical directory named qualified is preliminary; final is the reviewed final visual set. All retained logs and captures are hashed below.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 122C3D65116017DAC91FE3E87D0A1D3B2826807479E3277D1286AE63A571610D |
| connected-regression.log | D2822D437FBE58D6AC4EC11F31A88FE9A8FCE81FC581EA018CDF2805E46071EC |
| existing-recent-regression.log | E6A07E9FD95C90480AE5914E3637B60C4F51DEA82B771A6FBA74A55F08B2EBBF |
| final/rv6-d015-s-dog-food-row-start-text-2.0.png | A20AF03479A55B416432CA84AA4D6116B2E3E76026262A114FF9F94C70D5CE4F |
| final/rv6-d015-s-dog-food-row-text-1.0.png | 973C3536F15F1FA600379C35194B0971C349C730F531AC420DFE287ABF52AE8F |
| final/rv6-d015-s-dog-food-row-text-2.0.png | 0E5CA8E6BE67F87C9D9BDE626C0A34CFE3617B65B7306EC60DFE034B7372E2E7 |
| final/rv6-d015-s-shampoo-row-start-text-2.0.png | CA39532BF40948A3BF992EC3574FA75E8A6D91FFE23FEDA5F5FB941EA1E9BE02 |
| final/rv6-d015-s-shampoo-row-text-1.0.png | 4D3999F64CC168DBB29F813EE04F8514AFFF263D1A6EE977158594EF1CC9A940 |
| final/rv6-d015-s-shampoo-row-text-2.0.png | A1B3499DA748FBCAEE720EDC48341EC0A041740DC91D762F9144CEBDD17E6ECC |
| final/rv6-d015-w-notebook-rejection-end-text-2.0.png | 14051B0CEE27C5D3A1225E25B5C4CCBA7E1AE2AC20A07C8B053092C7179AA81F |
| final/rv6-d015-w-notebook-rejection-text-1.0.png | 2AFB48FB6F7BAE40DB5291C2C577B7A9EED3AC811EA246CBE6F0B85793B5DB91 |
| final/rv6-d015-w-notebook-rejection-text-2.0.png | 14051B0CEE27C5D3A1225E25B5C4CCBA7E1AE2AC20A07C8B053092C7179AA81F |
| final/rv6-d015-w-notebook-row-start-text-2.0.png | FAB7A2BCC7545FA33C4263FC2166C966738813F81284F9B3B005C2C554B76910 |
| final/rv6-d015-w-notebook-row-text-1.0.png | 59ECCF8D064F0F8A6894F50FFC0490EB129B0D25F09196BEAE2774D135AF97F2 |
| final/rv6-d015-w-notebook-row-text-2.0.png | E88AE70A28AD9AF4A0BAB5FF2CC9F6D3915EB0AA18B50C6BD83560D9D1B466B4 |
| final-focused.log | 2FED576D2280748A9F2CD407612707C864D4556E267737EA8DE4442187A66F65 |
| final-recent-regression.log | A386178C771A72728E73E0D40EBB3F3AED7C854CFF7DB55BA15ACC36F6514A6D |
| focused-first.log | F230FE947CFDEFE58451084A2A1AF03CADCA6CD7E5934FE3D2731E5BEA227477 |
| focused-recovery.log | E7D67DDC878B82781C132256315425D7CB77312FCBA2390F221CA1970D82A9D3 |
| focused-visible.log | CD7A1B7608FD97563E1D241EEAB13E0D7B9E2B3D07714789E1F27098D058F7D6 |
| qualified/rv6-d015-s-dog-food-row-text-1.0.png | 973C3536F15F1FA600379C35194B0971C349C730F531AC420DFE287ABF52AE8F |
| qualified/rv6-d015-s-dog-food-row-text-2.0.png | 0E5CA8E6BE67F87C9D9BDE626C0A34CFE3617B65B7306EC60DFE034B7372E2E7 |
| qualified/rv6-d015-s-shampoo-row-text-1.0.png | 4D3999F64CC168DBB29F813EE04F8514AFFF263D1A6EE977158594EF1CC9A940 |
| qualified/rv6-d015-s-shampoo-row-text-2.0.png | A1B3499DA748FBCAEE720EDC48341EC0A041740DC91D762F9144CEBDD17E6ECC |
| qualified/rv6-d015-w-notebook-rejection-text-1.0.png | 94F92F494C7E3B88D76CB80B5B46E21D1A32A521A294D2D4A3D866AB725B3D4B |
| qualified/rv6-d015-w-notebook-rejection-text-2.0.png | 1F8B164222E48FC7BCAB2710F0E6C7700E266056828F2AA396BC64504EF18B53 |
| qualified/rv6-d015-w-notebook-row-text-1.0.png | 59ECCF8D064F0F8A6894F50FFC0490EB129B0D25F09196BEAE2774D135AF97F2 |
| qualified/rv6-d015-w-notebook-row-text-2.0.png | E88AE70A28AD9AF4A0BAB5FF2CC9F6D3915EB0AA18B50C6BD83560D9D1B466B4 |
| visual-focused.log | A0E31B0F627B54614CB033A447022649C43CF5B8A4146FD63F7B417DBF67B1E6 |

## RV6-D016 local qualification - 2026-09-14

- Scope: original510,516-518 New Shop offers alert opened ordinary catalogue instead of Offers; return to alerts already worked. Start0c10682b9c5e6955e5cf845de8897090b95f60d4 after D015 commit/push, clean exact live remote equality and handoff pass. Existing36-owner implementation gate passed7088c9 terminal0; no admission or governance work.
- Source inspection confirmed buyV2ShoppingAlertLocation already generates /app/buy?sub=offers and journey_router already passes initialOffersActive. No route parameter or shared router change needed. BuyV2Screen initialized _offersActive=false, rendered, then assigned the explicit flag in a post-frame callback without guaranteeing another build when restored session catalogue state was unchanged. The new real MoolSocialApp alert test reproduced no BuyV2OffersView at normal text, while200% passed; baseline-reproduction.log,28483 terminal1/656469. That differing result is retained, not represented as two baseline failures.
- Minimal source owner apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart: initialize _offersActive from widget.initialOffersActive in initState before the first build. Existing deferred session restoration, route updates, Offers UI, catalogue data, price/eligibility rules and alert-return context remain unchanged. No session/router/backend/native/policy/checker change.
- Test owner apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart: two real-app390x844 cases at100/200% use the actual New Shop offers alert twice, assert the actual Offers widget and publisher content, Android Back to the same visible alert, retained Cart quantity, exact Saved IDs and selected address. Two first-frame tests directly assert explicit Offers=true and ordinary Shop=false both before session notifications and after settling. Test setup opens the existing alert sheet directly; physical Shopping settings entry516 remains part of the scoped successor device verification. No test claims live offer/provider validity from review fixtures.
- Initial source fix2passed (70139 terminal0/8e2801). Final4focused cases passed (69016 terminal0/694150,final-focused.log). Four actual Flutter captures inspected: Offers destination and alert return at100/200%. Scope is correct destination/return and readable fit; missing supplier-media placeholders at200% are not evidence of provider delivery. A test-only missing-braces lint was corrected; original analysis.log retained. Final analysis of both owners: zero issues (9eb34a terminal0,final-analysis.log).
- Final connected regression: flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart test/ui_v2/buy/buy_v2_shopping_alerts_test.dart --reporter expanded;327passed/0failures (90040 terminal0/a5f9f0; result output3d7980). Includes the four focused cases, prior Buy corrections, alert identity/return paths and compact fit. Counts overlap. Diff check passed; unrelated formatter changes removed, prior test bodies preserved.
- No APK/device action or closure. D016 remains open pending checksum-bound successor Redmi510,516-518 and directly affected Offers entry/return. Frozen514 records/1177 artifacts unchanged; no broad audit, backend, OPPO, integration or child implementation. Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d016-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 29DD516F334704E52022AD4738163B04BD7311D1E4A8EAE7A330E26B50D68DE7 |
| baseline-reproduction.log | 69B306AAD4F2E91F93E9CF320E48F6A5A1CA2F64EBAFFFFBD8350B18883E0E75 |
| connected-regression.log | 8F127DCF5106008B0246CE40A3908371834939C681F4E6AB4CDF7B0845D20713 |
| final/rv6-d016-alert-return-text-1.0.png | A3A1D3298A206E652951B475111D66891E406CCD79CE3BBD2D5EB01117725F6D |
| final/rv6-d016-alert-return-text-2.0.png | E7A4BEFF5B5050165E8ABE64A98FF9E2A8DAC267F8F6123E112430361E28EB83 |
| final/rv6-d016-offers-text-1.0.png | 58688DE62E5A9358E58EFB50BC085A21EB9E9C944593DC5A4FF27CEB0E68D3C9 |
| final/rv6-d016-offers-text-2.0.png | 7D5A6CDA9CD9CC89D7220B22EEAECAC9874D00B5B38FE57FBD45BC23F7BDD665 |
| final-analysis.log | 0AAAC678E2EC6742F989EFF375243869EA2A4299C4E378008E0E70A592E8E838 |
| final-focused.log | D8010A2415776CFC12237F1F89D5416D5AB936078CB12EB5C4DE48ADF65BD273 |
| initial-offers-fix.log | 940D784FA6E82F1321EFF44F573CAD3113F164AF589CC116D8AC869E90F4D0A3 |

## RV6-D017 local qualification - 2026-09-14

- Scope: original691-692 selected saved GST chip showed no readable profile name and low-contrast check/remove icons. Start ac5a95e5f8fa410ca4e5d0e8c41ca5de7bd271eb; branch/HEAD and zero-byte clean digest revalidated, implementation gate27b026 terminal0,36existing owners. Previous turn made concrete progress sealing D015/D016; no external wait/blocker or scope change.
- Confirmed source cause: shared MoolTheme chipTheme selectedColor navy and labelStyle navy; InputChip did not apply a contrasting selected label or icon foreground. Actual rendered RichText against selected RawChip background measured1.0contrast in both Shop and Wholesale at100/200%. The first Shop fixture used nonexistent s-wheat and failed before rendering; corrected to actual s-atta. Wholesale reproduced in baseline-reproduction.log (65154 terminal1/fcd0bf); corrected Shop reproduced in shop-reproduction.log (70474 terminal1/6daff8). Before captures preserve the invisible selected label. Missing first Shop screenshot was not treated as evidence; actual output inventory and corrected reproduction were used.
- Source owner apps/mobile/lib/ui_v2/buy/buy_v2_views.dart only: Buy GST InputChip now explicitly uses navy selected background, white selected label/checkmark/remove icon, navy unselected label/remove icon. Existing theme font styling retained through copyWith; shared MoolTheme and every selection/removal/persistence callback remain unchanged. No shared-theme, ownership, policy/checker, session, provider or backend edits.
- Test owner apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart: four Shop/Wholesale x100/200% cases at390x844 with48px safe area. Real Buy checkout advances to Confirm without submitting. Two explicit in-memory review GST profiles are seeded through the existing controller to exercise selected/unselected identity; these fixtures do not validate GST registration or backend storage. Tests inspect actual rendered label contrast >=4.5 and explicit icon contrast >=3, switch profiles using the chip label, verify both foreground states, open removal and cancel, and preserve selected profile, two saved entries, one Cart line and Confirm step. Existing GST creation/save/reuse/failure flows are covered by the connected suites. Original device Add/form/Use GST details sequence remains for successor Redmi qualification.
- Focused4passed after source correction (49379 terminal0/dddd0b). Initial final/ capture run4passed (43891 terminal0/8e1dce); its200% scroll alignment placed chips at the screen edge, so the test was refined to center the target for review. Qualified4passed (94919 terminal0/4417b9), eight qualified/ images inspected at both profile selections/scales/destinations. These are the final visual set; before/,before-shop/ and final/ remain retained earlier evidence. Product code did not change during capture alignment. Final analysis zero issues (e8a59a terminal0,qualified-analysis.log); initial missing test-braces lint retained in analysis.log, corrected without assertion changes. Prior test bodies preserved.
- Connected regression: flutter test --no-pub test/ui_v2/buy/buy_v2_gst_session_continuity_test.dart test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart --reporter expanded;54passed/0failures (96687 terminal0/7737f7). Includes profile reuse across screen recreation, account restoration and failed-save handling, optional GST Add/form wiring, checkout/Cart return and compact layout cases. These54 are separate from the four new focused cases. No extra source changes after this run; final test-only centering and formatting were qualified separately above. Diff check passed.
- No APK/build/install/device action or closure. D017 remains open pending full successor Redmi691-692 and directly affected selection/remove-cancel verification bound to APK checksum. No order/payment/provider action was submitted; visible Check delivery limitation in Shop fixtures remains unchanged and is not a successful payment/delivery claim. Frozen514 records/1177 artifacts preserved; no broad audit, child implementation, OPPO or integration.
- Artifact root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d017-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | B9430A4249CC06B783D391490068D9FFD03F110AD7BE39F0648AA6C7BC15F082 |
| baseline-reproduction.log | D169C2B485CA8D8BA3526CF3F3ED3B277BA00502EC6A70830311237AF62F2DB5 |
| before/rv6-d017-wholesale-selected-text-1.0.png | 60B1AC4B6854CB901CE344080A507522327B373752B4DA29935BAC1A8E3E0DC6 |
| before/rv6-d017-wholesale-selected-text-2.0.png | B6BF802AD67BBE4A013FA2CC6D092AA8534BC0E46C43584826DE98FE744C6C81 |
| before-shop/rv6-d017-shop-selected-text-1.0.png | 9E47D486D4AAC14122884A246F701721FC3E281BA0C60CB7ED683F1234CE66B2 |
| before-shop/rv6-d017-shop-selected-text-2.0.png | 0610F458DB4FCA09DD1E6861D323BF95F8BF733EC668D36598ED6DE000F814CF |
| connected-regression.log | 70EDA3D619D0F1308FFF0461C050440E272DF6499809919510F5EB374FC56329 |
| contrast-fix.log | 03362AFB97FEBBBA78F61CFA2ABA9A4CB327BA29CED426435BD6798F7E848B86 |
| final/rv6-d017-shop-selected-text-1.0.png | 28D213691E8A3196A9A3350377E3381002A78E35430A48EFCE7778EF7368DCAF |
| final/rv6-d017-shop-selected-text-2.0.png | DFCDA61EB74B4AADD2E0D30E869CB772314183B51251BDF34E732CC42D7FDB3E |
| final/rv6-d017-shop-switched-text-1.0.png | 015EE484D86B852ECD5BF04614BA6CCCF5E12BA008BAB0863826329EB0725624 |
| final/rv6-d017-shop-switched-text-2.0.png | 27C8F140551F4BC6A43C195E31B00B3AE19F2840C27B917E32FFA7C0476EA29B |
| final/rv6-d017-wholesale-selected-text-1.0.png | 29013F2C945228464BE3228807DF8E53FE01695927C0C01B91FD270417FBF1E4 |
| final/rv6-d017-wholesale-selected-text-2.0.png | F4CECD64C1A72EEF67C12FC64014B79138521AD8E459119E21CFB16019E2864B |
| final/rv6-d017-wholesale-switched-text-1.0.png | FAD30F665975DDAB58F0F59CB333018D7BDFA3F075FD98BCEF620CA9CBED21C6 |
| final/rv6-d017-wholesale-switched-text-2.0.png | 29EF794D81E2A0EFC847F950B1699675869E7AD4D5B51A617B303BC8B443B7AF |
| final-analysis.log | 7C961928B430CDB3BE75FEF8C9058ADE6242D3D0C31393C072F4420C0AE7D3D6 |
| final-focused.log | AFFE5415F6204DFE0E466346F012143163A625AAD11C00B41FDF581087B8F6E6 |
| qualified/rv6-d017-shop-selected-text-1.0.png | F23CA15EC362BC3696D8729D6456DB955EDC53DD34B95BF85B1D9C94F0374660 |
| qualified/rv6-d017-shop-selected-text-2.0.png | D4CA5E649BF92CD305CB996EE48A699FEC631396A0B9A14E11E5362746F66E60 |
| qualified/rv6-d017-shop-switched-text-1.0.png | 0C685698960A8FF9284959DA620F3F1ABD282E3F44690C5E00827868D55254C3 |
| qualified/rv6-d017-shop-switched-text-2.0.png | 4C4510577E52D6CFC49FF51DF9B5AA8F7A8774BFD791F704222B32686F144557 |
| qualified/rv6-d017-wholesale-selected-text-1.0.png | 5167C0802E7A1E6F94813C95541D1BC9E7AE2C561FF92633630AB882C32AFD75 |
| qualified/rv6-d017-wholesale-selected-text-2.0.png | 421D89EA2CE7FE754F5372329B5376535D910B7CCA0F21B875278E3BEF1D48A1 |
| qualified/rv6-d017-wholesale-switched-text-1.0.png | 70BC4667F12094FF35A3162625698AE05C16FDEA446195D7BFA203075F47FC07 |
| qualified/rv6-d017-wholesale-switched-text-2.0.png | AA52AAF48003B974A6A50EA20AEB8FCACFD21C0CD14385DA0D3045DE5E325C3E |
| qualified-analysis.log | 128449F8A393F620158E7A3AC7B004C562E7BD4581066BEC3DA8A9B3AC59D529 |
| qualified-focused.log | CB75888548D28B4BD26146B5EA1D3B1A27525D716A069EF91E4CA8622B9E39F8 |
| shop-reproduction.log | F6E8E4428F82E7E2EAA9F7EC981B31E9CAE2EA4843F0D09DB0047C2E35B717EC |


## RV6-D018 local correction qualification - 14 September 2026

Status: locally qualified; original remains open pending successor-APK Redmi acceptance. Parent: 99f74b80e37850003f7fdd37db81e71387fbc9ca.

Changed owners: apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart and apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart, plus this evidence, DEFECTS.md and scope-state.json. No additional admission or shared session/router changes.

The search pager already retained its page and offsets. Product entry hid the dedicated search surface and Back did not restore it. Retain the originating search surface bound to account, destination, query, sale type and root product; restore only on matching product Back without reopening the keyboard. Clear stale return context on session/route/account/query/mode changes. Preserve the existing pager and unrelated cart.

Baseline: four normal/200% Android/content Back cases reproduced the missing search-results destination. Final focused run: eight passed. Connected Buy-screen, search-recovery and product-continuity run: 379 passed, exit 0 (session 75176, terminal chunk b3cdd7). The eight focused checks overlap the connected count. Analysis of both Dart owners: zero issues. Tests cover page 41-80, query, scroll retention, both Back paths, cart roundtrip and rejection of stale account/query/mode context; retained Wholesale cart remains unchanged.

All five qualified Flutter captures inspected individually: normal and 200% text with both Back paths, plus cart roundtrip. Restored query, page range and product grid fit; keyboard remains dismissed. At 200%, generated media uses missing-image placeholders in this host fixture; these captures qualify return/fit, not supplier-media delivery. Generated catalogue data is local evidence, not provider/device qualification. Exact Redmi reproduction 898-904 remains required on the successor APK. No device actions, ticket closure or new APK in this slice.

Evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d018-local-20260914. Retain baseline failures and intermediate runs; final captures are under qualified/.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 067DC7E66F5A56A4B8E3E826990362480F2B5B2A59496B0BF4C95F036AE37C39 |
| baseline-reproduction.log | BF23937A18EBDEC38CBFD8B2F437D6E161860E7CC227F7C3829E09C06AAFA604 |
| connected-regression.log | 3E65BF3345488A52F5DD60B1470A7C2C7F88CCEC3DD4D5854E4EB2300D5790EF |
| context-regression.log | AA6515D5C2323C0D658FE50C602041A67697970F87522B6B8A0D2FE34F037F3A |
| final-focused.log | 5DC6380FC1AEA9DCF3832770732BB63D97D7ACBCFEBDB915A88ADEFB94F12DDF |
| qualified/rv6-d018-search-return-system-false-text-1.0-none.png | AC8C209AD8216489BE333F8F129AE3BE0DE4478FACA7DFBA0D89E640329B3C8E |
| qualified/rv6-d018-search-return-system-false-text-2.0-none.png | E4EB66FEE2B0F2EEB23AD7E1FAD7B2CFCAD29BEA634BA0FD6ED68751CF445201 |
| qualified/rv6-d018-search-return-system-true-text-1.0-cart.png | AC8C209AD8216489BE333F8F129AE3BE0DE4478FACA7DFBA0D89E640329B3C8E |
| qualified/rv6-d018-search-return-system-true-text-1.0-none.png | AC8C209AD8216489BE333F8F129AE3BE0DE4478FACA7DFBA0D89E640329B3C8E |
| qualified/rv6-d018-search-return-system-true-text-2.0-none.png | E4EB66FEE2B0F2EEB23AD7E1FAD7B2CFCAD29BEA634BA0FD6ED68751CF445201 |
| search-return-fix.log | F3FD5A19500CB882999AC35612C178BB9D1491ECB97BEC4C4A155CB796E05D87 |


## RV6-D019 evidence reconciliation - 14 September 2026

Disposition: original defect description contradicted by its own hash-verified physical evidence. No product correction justified. Preserve ticket ID and original narrative; retain D019 in the planned successor-APK scoped verification, not a device closure or an implemented-fix claim.

Reviewed original Redmi captures909 (expanded),910 (minimized),911 (settled),913 (repeat). 910/911 clearly show bike +9+ in the rail;913 also shows bike +9+. Their bytes match EVIDENCE.csv. 910/911 SHA256 7D92BE68C1E4163E4EFAC14694DC9AE8086AFA70C714451C8AD0C597D21B786F;913 SHA256 530EC8E30C13DFB799C08722219D893421AC4A8B433F8C59DFA4D355756AA982. Expanded909 has the expected collapse chevron; SHA2564362B3F8F313FF3FCCD94EDC0EB07894A93BE863E74B83F747FD017298C54A19. Written claim of absent bike/count after minimizing is not supported by these images.

Added two focused actual-MoolSocialApp regressions in the existing owned buy_v2_screen_test.dart, normal/200% text, two open/minimize rounds each; check panel dismissal, restored delivery artwork/count and Show tooltip. Both pass on unchanged product source; final session92071 terminal exit0. Analysis zero issues. Reviewed first-round actual Flutter capture at both scales; truck +2 remains visible in this local fixture. Fixture has two seeded deliveries, not the physical twelve-order state. Captures for repeated rounds retained. These host passes do not qualify the successor APK on Redmi.

Initial invocation had a misquoted visual-directory argument interpreted as an extra missing test path; its exit1 is an invocation error, not a product failure. Preserve reproduction.log; no claim of a clean baseline from that run. Correct quoted full-app invocation and final formatted regression both passed. A formatter block-extraction read failed before writing, then bounded extraction preserved all existing tests. No application, policy or shared-owner modification. No live order, device action, APK or broad audit.

Parent04afab670c14e5cc425269f6753a3410e0b82548. Changed owners: existing screen test, UAT.md, DEFECTS.md and scope-state.json. D001-D018 remain locally qualified; D019 is separately reconciled without product change; D020-D022 remain pending local work.

Evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d019-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 9462CC0009BB9F0B020E9DD43CAFE9DBB7EB87A2078AD6E5CFB9906A27CEEAC0 |
| qualified/rv6-d019-minimized-0-text-1.0.png | 967EB8350DFFD5C2098134F8BDB4742977A309C767E0B47DFC014132F8284EC8 |
| qualified/rv6-d019-minimized-0-text-2.0.png | 8E6249AC8A14831E34335850A6582932DC68FB1C32CB77769740728759DB657C |
| qualified/rv6-d019-minimized-1-text-1.0.png | 967EB8350DFFD5C2098134F8BDB4742977A309C767E0B47DFC014132F8284EC8 |
| qualified/rv6-d019-minimized-1-text-2.0.png | 8E6249AC8A14831E34335850A6582932DC68FB1C32CB77769740728759DB657C |
| qualified-focused.log | 058E573A34B591ECA4A164C6548908CBDA61A6420C963433ED9E9C194FD86A54 |
| real-app-before/rv6-d019-minimized-0-text-1.0.png | 967EB8350DFFD5C2098134F8BDB4742977A309C767E0B47DFC014132F8284EC8 |
| real-app-before/rv6-d019-minimized-0-text-2.0.png | 8E6249AC8A14831E34335850A6582932DC68FB1C32CB77769740728759DB657C |
| real-app-before/rv6-d019-minimized-1-text-1.0.png | 967EB8350DFFD5C2098134F8BDB4742977A309C767E0B47DFC014132F8284EC8 |
| real-app-before/rv6-d019-minimized-1-text-2.0.png | 8E6249AC8A14831E34335850A6582932DC68FB1C32CB77769740728759DB657C |
| real-app-reproduction.log | 1974531C24BD2A68C5B4E8D553F8E1D6E77093533B885C5D9EAF1C69C6E9D9F4 |
| reproduction.log | EDB6F6C9327A1EAA1DD79C8D9DEE7424096BF23FEAA1B485D4B07D1F03C08B63 |


## RV6-D020 local qualification - 14 September 2026

Locally qualified; open pending successor-APK Redmi acceptance. Original captures931-933 verified against EVIDENCE.csv;932 visibly clips the final No new conversations explanation below Android navigation.

Exact one-source-owner admission under founder limited standing authorization:213d2e6c41fa4c123b9648fb4913e015bb973040, parent70b117b966a58ca4a551edb31742e175c2723dde. Transferred only apps/mobile/lib/features/chat/screens/chat_settings_screen.dart from root to this lane;37 owners, disjoint claims. Existing checker rules preserved by normalized-prior SHA256023D1887F9E52F92CE3374BE3E7B41DB47D7317FD7FD2625B229F90ADB726B89 reconstruction; exact parent/branch/path/subject/two-control admission constraints. Admission gates passed, pushed, clean and live remote equal. No other worktree edits.

Implementation: three lines add bottom viewPadding to the existing message-permission SingleChildScrollView. Existing text, permission choices, save behavior and sheet dismissal remain unchanged. Tests added only to already-owned apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart. No additional test-owner transfer.

Baseline two cases at390x844, normal/200% text,48px Android inset fail: explanation extends to818 instead of usable796 boundary. Earlier reproduction.log failed before sheet entry because a lazy settings row required scrolling; test setup corrected without product edits, retained separately. Corrected and final formatted focused tests:2 passed. Existing chat_settings_hub_test.dart:12 passed (read/run only), covering shared returns and privacy controls. Analysis of both changed Dart owners:zero issues. Two corrected actual Flutter captures reviewed: full final explanation visible above inset. At200%, sheet scrolls; header is partly above viewport after scrolling to final explanation, not missing content. Android Back dismisses picker to settings without a save confirmation. Local fixture, not authenticated provider qualification.

Remaining device requirement: exact931-933 reproduction and necessary dismissal on checksum-bound successor Redmi APK. No device changes, original closure or APK. Changed owners: Chat settings source, Buy screen test, UAT.md, DEFECTS.md and scope-state.json.

Evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d020-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | D3F4445E3EEB1D919B9250CE6326762B1CB464CD31E834510492C7E009F7CCDD |
| baseline/rv6-d020-audience-text-1.0.png | 181099ECB7ED0071C5E10438BFDC7E9FB5ED165A7517EEEFEC09C6434AD8F85F |
| baseline/rv6-d020-audience-text-2.0.png | BAC2470843D70961B7BCD464906CB6AE0344D7ADFE06C954BF097402BA624A08 |
| baseline.log | 24E805FF02CED4544AD28800C9BDB3898805BA8AE2197FF674465268B96C14FE |
| chat-regression.log | F22FAEDA196337699904EB8D4AC23FDB9FD0A1CEB6C93328ADA3A951DE92BF2F |
| corrected/rv6-d020-audience-text-1.0.png | FD3E25A083F1810CF54FE2A3DED56DA2F4A732CE71949532A517FB39F36EE158 |
| corrected/rv6-d020-audience-text-2.0.png | B217E420BE93FE45A3D89BB3FB02AF132DF558E67C619CFADB6E7C596F8998FF |
| corrected.log | 91A3DB0974270C8131DCD7DBD1B62BB2653E27AFE26B53E434D3E98AE3B6D980 |
| final-focused.log | 3C7471E233A05A00B7E76D6A3911F2186BFE53196E35EBCDBEB01EEBD2705080 |
| reproduction.log | F124500B7FFF18A1D7AC6E6EC7BBFA12C8D2E415349EEF96AC5558DCAA0903AB |


## RV6-D021 local qualification - 14 September 2026

Locally qualified; original remains open pending successor Redmi acceptance. Parent9a81541e866975c15c4044f8a5d68906e45dd638. No ownership admission needed. Changed source: apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart; focused tests: apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart; evidence: this document, DEFECTS.md and scope-state.json.

Recorded1037/1043/1044/1045 artifact hashes match EVIDENCE.csv after case normalization (the first two recorded hashes are lowercase). Reviewed1037 initial and1044 settled: empty-cart rows retain44 logical pixels /88 physical pixels. Cause: _QuantityAwareGridLayout retained its largest quantity width until scope or viewport change. Reset it when no displayed product has a quantity; preserve existing maximum while quantities remain. All callers of this shared helper receive the correction. No session/cart arithmetic or provider logic changed.

Normal-text baseline reproduced240px card remaining284px after removal. The200% fixture has wider cards and needs no extra stacked quantity height; its initial assertion incorrectly required growth and was corrected to require no shrink while populated and exact original height after emptying. Do not count that setup assertion as a reproduced200% product failure. Final focused2 pass; selected address and saved item retained, two additions and removals exercised through session actions in the actual Flutter screen. This local layout test is not a claim of physical quantity-editor tap verification.

Connected Buy-screen and partner-catalogue regression:408 passed, terminal exit0, session65399/chunkcb27c3. Focused2 overlap408. Final analysis:zero issues. Four qualified actual Flutter captures reviewed (before/empty at normal/200%); normal row geometry restored, enlarged layout intact. Generated missing-image placeholders at200% are fixture limitations; media-provider qualification not claimed. Initial before captures include a transient Saved notice; layout comparison uses measured card height, not whole-image equality.

Redmi requirement remains exact1037-1045 reproduction including quantity-edit/update/cancel and final minus removal with retained Saved/address and no module reentry. No original closure, device action, new APK or broad audit. Source remains a small shared-layout correction; connected Store cases passed.

Evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d021-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 067DC7E66F5A56A4B8E3E826990362480F2B5B2A59496B0BF4C95F036AE37C39 |
| baseline/rv6-d021-before-text-1.0.png | 23CEE50B65755ED51AD0A53EAC57E6B01DA55B4A142DFFF910D4F3016DF3AD2F |
| baseline/rv6-d021-before-text-2.0.png | 9184339A4CAB92D597E79DCC5252952D52B763114FE7BB5181BF47AD50C991A9 |
| baseline/rv6-d021-empty-text-1.0.png | EE0D16507935559976784AC7C39A7BE993E09D2D43544DCFD07BEFC22AB5AB07 |
| baseline.log | 1053ECA32C670882AB1007F6EB814D0436A7BF5C41C571DCAE135C1E5A219146 |
| connected-regression.log | A372D2814EEFBAC8663C5BB503B643992D8583A675CA50C0164B0613D7D9CA4C |
| corrected/rv6-d021-before-text-1.0.png | 23CEE50B65755ED51AD0A53EAC57E6B01DA55B4A142DFFF910D4F3016DF3AD2F |
| corrected/rv6-d021-before-text-2.0.png | 9184339A4CAB92D597E79DCC5252952D52B763114FE7BB5181BF47AD50C991A9 |
| corrected/rv6-d021-empty-text-1.0.png | CC8BE196EB6B5FFEC04C0BE9263C19CA8D5C061F4F15609E6085CEF79C848740 |
| corrected.log | DD8374B0818437E4B34643E49937FCC19C396BD5BCC1858300E32A201FC7D831 |
| final-analysis.log | 1E54EA91903B8A786BA4C28A3BF79FDB5E8F1C2873147DA237288DE1ABDF0566 |
| final-focused.log | 109D6BB1D725B7D0183EE82E2518B85055505757567D17F9FBCF85AD8A383539 |
| qualified/rv6-d021-before-text-1.0.png | 23CEE50B65755ED51AD0A53EAC57E6B01DA55B4A142DFFF910D4F3016DF3AD2F |
| qualified/rv6-d021-before-text-2.0.png | 9184339A4CAB92D597E79DCC5252952D52B763114FE7BB5181BF47AD50C991A9 |
| qualified/rv6-d021-empty-text-1.0.png | CC8BE196EB6B5FFEC04C0BE9263C19CA8D5C061F4F15609E6085CEF79C848740 |
| qualified/rv6-d021-empty-text-2.0.png | 97F3F29834BC9CB43F7FC64B7609570FE3317754796AB7320FBC049E28F82CA5 |


## RV6-D022 local qualification - 14 September 2026

Locally qualified; original remains open pending successor Redmi acceptance. Parent7e811a753a9896947f514a209f50138d21ea9544. Changed owners: catalogue source and Buy screen test, this evidence, DEFECTS.md and scope-state.json. No new ownership admission.

Hash-verified original1090 area-reopen capture visually confirms Jaipur is unmarked. Add a Current area summary from session.catalogueAreaLabel and selected/checkmark feedback to the matching catalogue city or Any area row. Existing area choices, Google lookup, regional/national selection, filtering and delivery-address behavior are unchanged. The summary also names retained areas not present in the local city list; provider verification remains separate.

Final focused2 pass: actual chooser taps select Jaipur then Any area at normal/200% text, reopen verifies summary/selected row/checkmark, Android Back retains selected region and delivery address. Connected area tests26 pass, including India lookup/search/keyboard/retry/Back and Android final-row visibility. Total28 distinct checks. Final analysis zero issues. Four qualified actual Flutter captures reviewed; summary and checkmark readable. At200% the capture is scrolled to expose the chosen row, so the header is partly above the viewport. No claim that the full list fits without scrolling.

Earlier baseline.log hit a reused widget-key type mismatch, corrected.log lacked a lazily built row, and selection.log matched nested scrollables; these are retained test-setup failures, not product repro passes. Unique summary key, explicit Jodhpur/Jaipur fixture and outer area-list scroll corrected them. The physical evidence establishes the original failure. Initial area-regression invocation used a pipe-containing regex that the Windows batch launcher misinterpreted (exit255); corrected area-name invocation completed26 checks, session49930 terminal930bbd exit0. No unsupported baseline-green claim.

Original1087-1091 Redmi workflow remains required on the successor APK, including supplier change and restored Any-area catalogue with Saved/cart preserved. No device closure or new APK. All22 local dispositions now available:21 corrected/local-qualified, D019 evidence-reconciled without product change. Required combined local/build qualification still pending.

Evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-d022-local-20260914.

| Artifact | SHA256 |
| --- | --- |
| analysis.log | 128449F8A393F620158E7A3AC7B004C562E7BD4581066BEC3DA8A9B3AC59D529 |
| area-regression-v2.log | 2DE90904E703A2EC2AF17BC007C3B668B60D98F5C54341C79B13FFAAC59D6A3C |
| area-regression.log | F2059426286CDA03D5AA375CBD138E26D32D8189EB6BC1A223D9CF3ACB305E78 |
| baseline.log | D3CABCA9B983598A1910252E6D3008E056B3A0FE625EE405A02FE4A270EAD891 |
| corrected.log | 676ADBA95475847B841A9BAE5DDB7F337756ABBD944EE742944B5D08947DE983 |
| final-analysis.log | D3F4445E3EEB1D919B9250CE6326762B1CB464CD31E834510492C7E009F7CCDD |
| final-focused.log | 523401BF4705521EA831828B6FEE1663FEE1D1C40C724B598B68E2BE252717A7 |
| qualified/rv6-d022-any-text-1.0.png | B3B7F55D450B919FBD31690BDFC89796F2152A5FFA4B48B2D4264D6602CBCFFD |
| qualified/rv6-d022-any-text-2.0.png | C2A031CF20AF22CAD72DC23B8B95A6795F02FC8272899B82856A37C5D9EE2747 |
| qualified/rv6-d022-jaipur-text-1.0.png | 3ACA7CBBC885878BA0A47C8DCF4F5BBBA96ECAB3DB7F3385F5B8FDD33509962B |
| qualified/rv6-d022-jaipur-text-2.0.png | 71027E3446EA79757E254E0EE6E10852DF05FF2A68C9BF0FA3DBF3C5441645E7 |
| selection-v2/rv6-d022-any-text-1.0.png | B3B7F55D450B919FBD31690BDFC89796F2152A5FFA4B48B2D4264D6602CBCFFD |
| selection-v2/rv6-d022-any-text-2.0.png | C2A031CF20AF22CAD72DC23B8B95A6795F02FC8272899B82856A37C5D9EE2747 |
| selection-v2/rv6-d022-jaipur-text-1.0.png | 3ACA7CBBC885878BA0A47C8DCF4F5BBBA96ECAB3DB7F3385F5B8FDD33509962B |
| selection-v2/rv6-d022-jaipur-text-2.0.png | 71027E3446EA79757E254E0EE6E10852DF05FF2A68C9BF0FA3DBF3C5441645E7 |
| selection-v2.log | DAB8E89A359A8BD12DA7A2239932BE4C09A303263CAC38AF86B5AE1AD67E9F18 |
| selection.log | 133C52A17B8419565C45217482452A4819B2ECEB1ABAAD739ACB5B87F837C227 |


## Successor combined qualification and D014 retained-origin follow-up - 2026-09-14

Source base4eb257d146fa656b63d7e0fe003cc8898ee8cd09. Combined run terminal exit1:2294 passed,27 skipped,30 failures. Full analysis terminal exit0,zero issues. These results supersede any implication that slice passes establish successor readiness. UI-lock failed unchanged at its committed-source-equals-V6 requirement; no checker changes or APK.

Six failures reproduce product-origin scroll loss after related/nested Store Cart returns. D014 modal completion can finish after the final animation frame, leaving its existing post-frame restoration unscheduled. The Buy screen requests a frame after queuing that guarded restoration. No test assertions, route identities, controller-disposal rules or shared owners changed. Initial depth-guard experiment still failed4/8 and was removed; its log is retained. Corrected unchanged suites: R5 007 eight passed; R66 nested Store Cart22 passed; D014 warm links19 passed;49 distinct checks. Focused analysis zero issues. Two visual invocations repeat one of those49, not additional distinct coverage. First used the wrong capture define and produced no images; second used the existing BUY_R664_VISUAL_DIRECTORY contract and passed with5 captures. Origin and product-return images inspected, confirming the same seller/details viewport; other3 retained but not claimed inspected. No device test or closure.

The other24 failures from the original combined run remain unreconciled, not24 confirmed product defects. Includes route/commerce fixtures, changed content/height expectations and supplier continuity. No failing case silently excluded; no full combined rerun claimed. Required ownership and V6 source-lock compatibility remain explicit before build.

Evidence root: C:\GUARANTEED OUTCOME\MOOLSOCIAL-CURSOR-BUY-UAT-20260905\rv6-successor-qualification-20260914.

| Artifact | SHA256 |
| --- | --- |
| combined-regression.log | 65ED1DE49E825A54EB247611AC65307B460CC5535C7499DEA3A952BD31673A46 |
| full-analysis.log | 8017F324D8CD335AB0CD5E37BA22D112277BC0C0CA8812BD8267C4642E57B0DF |
| ui-locks.log | E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855 |
| store-return-guard.log | 3B66A660549FBBAAA0CF53B21D93E5D741D2B58B7DA1A6CF49B794570998BBD0 |
| store-return-frame.log | DE943CFE67E8F5FD163F240F533B34728268E3B82E36864C12D8EE08601C91F9 |
| nested-store-return-frame.log | 372E236D54B44D016E6CA94CE39554C54F46F392052EBFA2C2C963AC059B9A22 |
| d014-return-regression.log | 999E1E3C8A93C9E9C7625791BD6E7F01313268955E83789C41CA0D89A098FB4E |
| return-frame-analysis.log | A4187CEB299AFFDCC4A0BAFAF09A2C48AE876D96341D9D46AEAE031C9F36DE36 |
| return-frame-visual.log | 20E21495461BD31705FE334A5EBBDAF5663EB04DF01D1B1D92F488F219926EF6 |
| return-frame-visual-v2.log | 20E21495461BD31705FE334A5EBBDAF5663EB04DF01D1B1D92F488F219926EF6 |
| return-frame-visuals/r5-related-shop-360-1.0-final.png | E1A9AA727C0A0C2B3A8274C900ED0665138C4334D803F669EF00FF8759370AE6 |
| return-frame-visuals/r5-related-shop-360-1.0-origin.png | A923B2AC8B447F5FC99B1035C2AA85C4E8FDBEC0ED88CE71CBA276C5ACFF1975 |
| return-frame-visuals/r5-related-shop-360-1.0-product-return.png | A923B2AC8B447F5FC99B1035C2AA85C4E8FDBEC0ED88CE71CBA276C5ACFF1975 |
| return-frame-visuals/r5-related-shop-360-1.0-related-return.png | E8050ACE155EF3777D06FCB5DFE4324E5E4096ED31702C23EC67E827A2C48EC7 |
| return-frame-visuals/r5-related-shop-360-1.0-related.png | E8050ACE155EF3777D06FCB5DFE4324E5E4096ED31702C23EC67E827A2C48EC7 |


## Remaining combined failures: bounded reconciliation - 2026-09-14

Source9d73a543e0aa01dfd01c488eb04897eca1300def. No source/test/checker changes in this reconciliation. Combined30 failures minus6 Store-return failures corrected and replayed leaves24 unresolved failure cases; this is not24 new device defects.

| Existing test owner under apps/mobile/test/ui_v2/buy | Cases | Observed conflict / required reconciliation |
| --- | --- | --- |
| buy_route_continuity_test.dart | 4 | Tests expect Medicine under /app/buy; router returns /app/book/medicine. Check authoritative routing contract and preserve cold-start/root-return assertions; no Care/router scope expansion. |
| buy_v2_cart_relevance_test.dart | 2 | Seeded benefits expected3 but empty; confirmation fails. Verify seeded eligibility and supply authoritative delivery fixtures without weakening fail-closed behavior. |
| buy_v2_state_invariant_test.dart | 1 | Confirmation expected3 orders but produced0; establish required delivery readiness before asserting immutable/single-use success. |
| buy_v2_state_machine_test.dart | 1 | Step9 confirmation rejected: Delivery estimate unavailable. Preserve order/quantity/account assertions and test explicit unavailable plus authoritative-ready fixture paths. |
| buy_v2_vertical_contract_test.dart | 1 | Every product expected nonempty brand; s-tomato brand empty. Reconcile optional brand/public-data contract; do not fabricate brands to satisfy a fixture. |
| buy_v2_order_delivery_address_context_test.dart | 1 | Expects raw promise summary; D003 deliberately uses truthful estimate/refresh summary. Preserve immutable order/address identity and missing-data assertions. |
| buy_v2_scoped_cart_checkout_dock_continuity_test.dart | 10 | Eight D011 description cases expect the removed duplicate generic summary. Test unique supplier content and its return continuity. Two D021 Offers cases require both unchanged scroll offset and card-top position despite empty-grid compaction; reconcile geometry and usable Add/return acceptance explicitly, not blanket dismissal. |
| buy_v2_wholesale_cart_trade_summary_test.dart | 3 | Exact composite Wholesale Cart header absent. Verify actual product/pack/amount presentation and arithmetic before deciding fixture vs product correction. |
| buy_v2_wholesale_supplier_continuity_test.dart | 1 | Exact Surya Oils India text absent at supplier action. Verify retained brand/supplier identity and navigation before deciding fixture vs product correction. |

Isolated serial commerce replay completed21pass/5fail; isolated serial route/Wholesale replay14pass/8fail. These13 failures reproduce outside combined concurrency. This is35 passing checks,13 failing checks, not a qualified regression result. A static local import/export/part closure for the four commerce test files contains17 files, no missing local references; compared with frozena846c558, its only changed dependency is shopping-alert updatedLabel from Updated recently to Recorded order estimate. This supports fixture reconciliation but is not an executed baseline replay or proof that no runtime dependency differs. No baseline checkout was changed.

All nine listed test owners are outside the current37-owner claim. Source fixes remain within admitted owners; changing these tests requires established ownership. The current goal excludes ownership/checker work. Existing check-approved-ui-locks.ps1 also requires committed apps/backend/contracts/packages/dependency source equal unchangedV6, so authorized implementation cannot pass that audit-only gate as written. No exception, new pin, excluded failure, skipped assertion or checker alteration has been applied. Exact test reconciliation and approved successor build admission remain prerequisites; no APK readiness/device closure claim.

| Artifact | SHA256 |
| --- | --- |
| commerce-fixture-reconciliation.log | 4B3F6B3916EB4502859C0AF175EF5712455F16691D927908E329C4DD5BCCC856 |
| route-wholesale-reconciliation.log | D65BF729741A9D4574C60ED722BCA8464894392D9EC748B8AF632B05E039D410 |


## Authorized test admission and D011 fixture reconciliation - 2026-09-14

Founder explicitly authorized narrow test ownership and reviewed successor-build admission in the current chat. Test admission sealed separately at4881429fdfe3ade5cbfb35c1f7c736f22f323a95, parent e65f341b690d4345fda29fa3609d02e6293b6d25, clean/live remote-equal; implementation/pre-commit/handoff gates passed. Exactly nine previously unclaimed test owners added,37 to46. Other claims and policy values preserved; normalized prior checker hash12F1D4D45F7289C12BABD685A71F7067782E21A0B63900B9065294794FCADCA7 is enforced after removing only the explicit admission delta. No runtime/backend/test changes in that admission. Successor build gate remains unchanged and pending qualified-source admission.

D011 reconciliation changes only the two test owners buy_v2_product_continuity_test.dart and buy_v2_scoped_cart_checkout_dock_continuity_test.dart. The shared session helper accepts an optional content adapter, retaining its original default. The eight R5 004 continuity cases explicitly provide distinct supplier storage/batch instructions instead of requiring the generic title/variant/pack/price paragraph that D011 intentionally removes. Existing readability, overlay/Cart obstruction, Compare navigation, scroll return, retained quantities and Back assertions are unchanged. This qualifies original continuity behavior using genuine distinct fixture content; no assertion was skipped and no production description was invented.

Eight formerly failing cases pass at320/360/430 widths and640x360, each100/200% text. Full shared-helper product continuity suite26pass, including original default content and D007 return paths. Total34 distinct local checks. Focused analysis zero issues. Test-only fixture change; no application UI or new device qualification. Remaining16 original combined failure cases require reconciliation and final full combined run; no successor APK readiness claim.

| Artifact | SHA256 |
| --- | --- |
| distinct-description-regression.log | E72CF672BA6DA3E5FA28F87AF8E00A797B38B0D899619877F3A6302CEB13C80D |
| distinct-description-analysis.log | 8C74C00C01DE74A2B98D3635A1F9D87316168732D58E0223101BA68B964C936C |
| description-helper-continuity.log | D421AF186999DE9A50850C59E5A19358D3544EEEED3E76D254E8767CCE33C082 |


## D003 order-address estimate regression reconciliation - 2026-09-14

Test-only correction on parentd67d269d25cfc3376cc95447f7849b7735e1428f. The three-order-family test now explicitly requires Last recorded estimate before the stored promise and rejects the bare unqualified promise. This matches approved D003 freshness semantics without calling the UI formatter under test. All immutable order/address/recipient, accessibility, future-only address editing and return assertions remain. Full file10passed/1skipped; skip is the existing optional founder-capture case, not a functional pass. Focused analysis zero issues. No application change or device closure. Fifteen original combined failures remain to reconcile before final combined qualification.

| Artifact | SHA256 |
| --- | --- |
| order-address-estimate-regression.log | A948746353817A909F5B3577A0567DFDF4BC686A926F6F2EFF8A61584D68A9F7 |
| order-address-estimate-analysis.log | 085C7C220F1922063D981ACC68BE09658BA7912CDF66424C0BC18031F7E366A6 |


## Optional brand contract reconciliation - 2026-09-14

On parentcd92728c56cbfadfbd9fa4cb10703c888311c4d4, corrected only the vertical contract test: a missing supplier brand must produce the explicit Brand not provided label; supplied brands must retain their exact trimmed value. No invented identity or mandatory-brand requirement for loose produce. Every other product, pack, taxonomy, destination, offer identity and Medicine regulatory assertion remains unchanged. Six checks pass and focused analysis has zero issues. No product change, APK or device closure. Fourteen original combined failures remain.

| Artifact | SHA256 |
| --- | --- |
| optional-brand-contract.log | DA8B2721585E18436EE35DBD3B1E83C0F28D8AC210A73F3C330AA70F29C507EE |
| optional-brand-analysis.log | 85345934790F2DBA022A9F2C053291A4F5FC3E093DC0A548B59ABB084FDD4404 |


## Seeded benefits minimum-spend reconciliation - 2026-09-14

On parent8627359d0eb954b3f0909f787eb054362a103c1a, updated only the seed-benefit fixture in buy_v2_cart_relevance_test.dart. It previously requested all coupons after adding a single low-value item, below the existing disclosed minimum spend. It now asserts coupons absent and selection rejected below threshold, then raises quantity through the normal session operation to qualify before running every original selection/replacement/destination/total/savings assertion. It does not enable benefits globally or modify eligibility. Seeded case1pass plus4 related malformed/default-disabled/vertical/stale-selection checks pass; five distinct checks. Focused analysis zero issues. Delivery-instruction confirmation case in this file remains unresolved, not silently omitted from final qualification. No product/APK/device change. Thirteen original combined failures remain.

| Artifact | SHA256 |
| --- | --- |
| seed-benefits-threshold.log | 692B3C0FBE9F924BF85FF9B4BB9A86A62E6341F7BAAB373C9ABC3E5FD430F89F |
| benefits-contract-regression.log | 498A9D31B6B17ACBD127DA16314450B636C7920033D68F76CE93C12326F212B9 |
| benefits-contract-analysis.log | 29B6648BFE36FEC971680DFCAD8393A9A8C329304DB5CA47C1930DABCDF4EAF1 |


## Explicit delivery fixture qualification - 2026-09-14

Parent260e5d4da422da433c8b4181c9069a06ae4b72f5. Three old success-path tests used default products whose delivery estimate is intentionally unavailable. Added one shared test-only QualificationDeliveryFacts adapter in cart_relevance_test, retaining default price, partner, orderability and all other facts but explicitly supplying a fixture window. Used only by delivery-instruction confirmation, immutable/single-use checkout and mixed-action state machine tests. All their original invariant assertions remain. An additional unavailable-window case proves confirmation rejection, unchanged order IDs, no confirmed order, exact retained cart quantities and total. No application or delivery gate change.

Full three-file replay21pass, including the new negative case and prior Cart/Saved/benefits/prescription checks. Focused analysis zero issues. Three original failures reconciled; ten remain (four route, three Wholesale summary, one supplier identity, two Offers geometry). No final combined rerun, APK, device qualification or backend claim.

| Artifact | SHA256 |
| --- | --- |
| explicit-delivery-fixtures.log | FD31300078E32FEEE49BC3152719DEC12CE2E7727A5249AC24C5F0FCFBC0ACFD |
| explicit-delivery-analysis.log | 77E62EFC901DD3CBDD7802106EC6C297910A19E133F96B5C20CAFEFCAE622DF6 |


## Canonical Medicine route and boot fixture reconciliation - 2026-09-14

Parent28a25ab53251eb70642821bb30b6a8384e1eb790. Test-only changes to buy_route_continuity_test.dart align canonical Medicine route assertions with existing _careMedicineRedirect in journey_router.dart: /app/book/medicine, with obsolete sub removed. Legacy /app/buy?sub=medicine inputs remain exercised; route persistence, language refresh, Mool root exit and internal Back assertions remain. The boot fixture now settles asynchronous route mounting before advancing the existing three-second presentation interval, preserving the exact Social cold-launch and no-Buy-screen assertions. No router, startup timer, native code, UI or safeguard change.

Full12 tests pass, including all4 previously failing cases. Focused analysis zero issues. Six original combined failures remain: three Wholesale summary, one supplier identity and two Offers geometry. No final combined run/APK/device qualification claim.

| Artifact | SHA256 |
| --- | --- |
| canonical-route-regression.log | 0BB291136D547FD225C0F003358926278FB020BEC63C4F3126DCAC0BE80D699F |
| canonical-route-analysis.log | 7585FE4B7F59F2ABFD47073CB9533CDECD7BDAE6F16B927BBFD925D91DB2BD5D |


## Wholesale subtotal and supplier identity reconciliation - 2026-09-14

Parent0356a82179a805f63a33f73f62ac3fadbcd6e691. Test-only expectations updated in wholesale_cart_trade_summary_test and wholesale_supplier_continuity_test. Cart expectations retain exact product count, pack count, destination and rupee amount, adding the already-rendered Subtotal qualifier. Supplier expectation retains exact Surya Oils India identity and additionally requires its displayed Manufacturer role; bare standalone name is no longer required. No application behavior or UI changed. All quantity/MOQ, total arithmetic, mixed-cart isolation, landed totals, freight/GST, supplier selection, eligibility and navigation assertions remain.

Five cart checks plus five supplier checks pass; all4 prior Wholesale failures reconciled. Focused analysis zero issues. Two original combined failure cases remain, both Offers last-quantity geometry. No final combined run, APK or Redmi closure claimed.

| Artifact | SHA256 |
| --- | --- |
| wholesale-subtotal-regression.log | 12A6A81125E84B7DDC97D8D2E8253E19B9B427AFF8C7154E900E641F09492F98 |
| wholesale-supplier-identity.log | C90ADD917103F4BAE30719A83D49E2E38B579FA330E604C78C5A01082612BC82 |
| wholesale-contract-analysis.log | B07C8539600EE0AC72232BC73584852B77F1FB1EAD42C5DB4A02058E8F00CF6F |


## D021 Offers compact-grid return qualification - 2026-09-14

Parent84101a16083b065bd822ec09c35a6ef22d5dc732. Test-only reconciliation in scoped_cart_checkout_dock_continuity_test. The two failures were scroll-offset clamping after D021 removes quantity-control height, not a missing product or broken Add. The old assertions required an offset beyond the compact grid maximum and an unchanged viewport top simultaneously. Final test requires exact original empty-card size, exact min/max extent clamping of the previous scroll offset, unchanged card origin in scroll-content coordinates, same product/Add hit target, Offers destination and successful re-add with exact quantity. No application change or free positional tolerance.

First retained attempt incorrectly addressed viewport top before scroll clamp; second proved clamp but still expected unchanged viewport top. Both logs retained as failed test reconciliation attempts. Final12 cases pass across320/430/640 sizes and100/200% text. Separate visual replay2pass overlaps12; four actual Flutter before/after captures inspected, compact Add visible and readable for tomato and notebook at320x700/200%. Missing-media fallback in local fixture is visible; no provider-media qualification claimed. Focused analysis zero issues. All30 original combined failures now have focused reconciliation passes (six through D014 product correction, remaining24 through recorded contract/fixture corrections); the final full combined run is still required. No APK or device closures.

| Artifact | SHA256 |
| --- | --- |
| offers-compact-continuity.log | F01E1163981D45BA4A7F74B9D710CAE2CC363CFC9F2F746E2386F2168B8F0534 |
| offers-compact-continuity-v2.log | 758DDA447FBC548C260790986A04BE3B68D6F5373A0870CAAE726DDB3D19F5B6 |
| offers-compact-continuity-v3.log | EA00A3EA41F2390A6C54AED7C47174FBFA445D658197581B8AD773892B5C6035 |
| offers-compact-analysis.log | 35A681DEACFCF03ABFBD1FF3D12EBB19D3E619F1175935C45ACF896835B4D2F8 |
| offers-compact-visuals.log | E17C97B314C6089CE9F9F5CB29ADFE497E01A586730626797A842B5A99835522 |
| offers-compact-visuals/r5-offers-s-tomato-320-700-2.0-after.png | 7DD065FC9DDC6FE4FA58C150489D9A8EE1DC4DC639750FAF9E192038B8671E2B |
| offers-compact-visuals/r5-offers-s-tomato-320-700-2.0-before.png | F821615CED38A0425DFADD9260ACF09E50A12700E67BAB428D2334F0BB3E8BC2 |
| offers-compact-visuals/r5-offers-w-notebook-320-700-2.0-after.png | ACF41E6D398ADD3404D8A670FE80702BDED0681445BC675C253DF7BF58A82BA5 |
| offers-compact-visuals/r5-offers-w-notebook-320-700-2.0-before.png | D5EA03CD291078254B137AFA063B97B84B414B646EA9D2F307F3098976BFA492 |


## Final connected local regression - 2026-09-14

Exact tested source9b7e5aa7fddc08517432f9b3932da5a36ef7a92d; branch work/cursor-ui/redmi-v6-audit-20260913. Full Buy directory plus personal profile, privacy, security and Chat settings hub: 2325 passed, 27 skipped, zero failures; terminal session95789 exit0 (f0de88). Full flutter analyze --no-pub: zero issues, terminal50778 exit0 (b5a878). This supersedes the first combined failure result only for this corrected source; original failing logs and each reconciliation remain preserved.

All27 skipped cases are inherited capture tests. Each entire skipped test block is unchanged from V6; source inventory and preservation evidence below. These are not passes or device evidence. Defect-specific actual Flutter visuals remain recorded in their per-ticket sections. D019 remains evidence-reconciled without product correction, pending scoped successor-device confirmation. No original ticket is closed by this local result.

Before this evidence update, worktree clean and exact live remote equality at9b7e5aa7fddc08517432f9b3932da5a36ef7a92d (12838b); implementation gate passed46owners/registry4584 (74f43d). All34 changed application/test owners relative to V6 are within this lane. Fifteen protected groups/files, including Android/iOS/assets/dependencies/backend/contracts, saved-products persistence, session and scanner, are unchanged. Entire screen import/arrival-sound prefix is byte-identical to V6. The exact source inventory is retained below.

Prior r66.19 APK copied without overwriting to external evidence root/preserved-r66.19-cursorreview.apk:210792649bytes; SHA25697750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7. Both source and preserved copy verified. No device change or data clearing.

Successor admission remains unapplied: exact three-checker proposal prepared under founder authorization; native rules/data-egress checker unchanged. Proposed protected-source function passes11 preliminary checks, including actual-source acceptance and rejection of wrong source/root/branch, missing ancestry, committed/working/untracked drift, Git failure and Desktop use. First harness had PowerShell argument-forwarding errors; its negative results are not relied upon. Corrected harness verifies each intended rejection boundary; both logs preserved. Remaining: narrow coordination admission, full candidate gates, atomic Git sealing, new build record/APK and scoped Redmi verification. No security/runtime/backend acceptance or build readiness is claimed by proposal tests.

External evidence root: C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/rv6-successor-qualification-20260914.

| Artifact | SHA256 |
| --- | --- |
| combined-regression-v2.log | 3F6E31095B819BF0BB9218D2EBDCC423666192C97A6930546B7E96CA16649508 |
| full-analysis-v2.log | 6FF2F528BA3FB1E9EC5FCC5F57C3DCCCC131C574E6FFD4703F9BA8527F3D0B8F |
| combined-v2-skip-source-inventory.json | CC269A2B438DA84184DA3214CD91DE34CC91CAD5CEBBFB6F2581DE19EAEB4733 |
| combined-v2-skip-preservation.json | 39E5F6C93948CD3BAA627366F32744E7C562C74B64709CA6EAF6321724C0B607 |
| successor-admission-source-review.json | 32E6F60EF5B8D722C01BF4073E03193343846945F21111BCCA11971D10B4F29B |
| successor-admission-proposed-three-checkers.patch | 4D996865AAC0A9353A317F6DAA3549D7506B1B6D09EB649A65A3E09CE83B167C |
| successor-admission-proposed-three-checkers.json | DB12BA2F15245A6FFF2248E40FD4CCBF993DD2F797AFF787671B78D4AE290F60 |
| proposed-source-admission-validation.log | E0A73ED12EC84D94FB61A8BF89D565E5202DAEF3673E51FB97CDE2B765965CD8 |
| proposed-source-admission-validation-v2.log | 7784E021D54643E9DB1599BE7EAFBF1EBF7A52FF0B52E3672DF38A26EB340CB0 |
| successor-admission-validation-plan.md | 883E140C3BB0894ED045C7A67528A259952CF44767259A2BD1900C5BB23AB5A2 |


## RV6 successor APK built and verified

Candidate UAW-CURSOR-REDMI-RV6-FIXES-20260914; exact build source32ebd7361fedf2224dae9cd89bb02337ca53286a, application/test source9b7e5aa7fddc08517432f9b3932da5a36ef7a92d. Two cycles2325passed/27inherited capture skips/zero failures each; analysis zero issues. Build admission242a1b87c21389d3bc65e694d4a3cc8f28a26d05; evidence seal32ebd736. Build started clean/live remote-equal; postbuild Git digest remains empty(42d886).

Existing wrapper preflight passed13gates and actual locked dependency/resource checks. First preflight stopped because REG3955's historical zero-byte preimage was not in live worktrees. Found the actual preserved artifact under MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904/MOOLSOCIAL-WORKTREE-CURSOR-buy-cart-safe-clear-v1-20260901/untracked/artifacts/quality/registry-disk-full-recovery-20260902/codex-development-regression-registry.zero-byte-preimage.json; zero bytes/SHA256E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855 match archive CSV and metadata exists. Used wrapper's existing EvidenceArchiveRoot parameter; no archive copy into worktree, registry edit, reconstruction or gate bypass. Retry preflight exit0(f138ac); exact gate summary recovered in bounded read de4b18 after dependency-output truncation. First failure remains recorded in tool receipt b6fd5d.

One authorized wrapper build completed exit0(213cac), source32ebd7361fedf2224dae9cd89bb02337ca53286a. Candidate APK210801229bytes; SHA2567734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Generated app-debug.apk, candidate artifact and external archived copy all match. Runtime profile CursorUiReview: UI_REVIEW_ONLY=true,DEVICE_REVIEW=true,USE_EMULATORS=true,candidate ID as above; debug packagecom.moolsocial.app.cursorreview. Non-promotable; no provider/backend/payment qualification.

Independent aapt: packagecom.moolsocial.app.cursorreview; versionCode2026091401; versionName1.0.0-r66.20-cursorreview; launchablecom.moolsocial.app.MainActivity. apksigner verify exit0; certificateSHA256CBDFC5969AD51ED570AFB1CF2FE60377E559D43F59D59E2AB66CCAF78EA9AC25 matches independently verified predecessor. Wrapper APK plugin-integrity check passed before artifact receipt. Future Kotlin-plugin compatibility warning recorded; no dependency change made. Installed predecessor stillr66.19/SHA25697750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7; no new installation or ticket closure yet.

Retained candidate:apps/mobile/build/cursor-review-r66.20/apk/uaw-cursor-redmi-rv6-fixes-20260914-device-review-debug.apk. Durable archive:external evidence root/uaw-cursor-redmi-rv6-fixes-20260914-device-review-debug.apk. Exact generated build input and wrapper provenance retained externally. One-build authorization is consumed; do not invoke another build under this goal. Next: data-preserving adb install-r on RedmiTG8HCYTGGQT885OF only, installed-checksum readback, then scoped22verification. All device gates remain pending.

| Artifact (external evidence root) | SHA256 |
| --- | --- |
| successor-apk-build.log | B49CC0C68EF1B6FCC67AAD4FF85BC9349BFC0A8CBA289B4B51D5BBA4AD0F404D |
| successor-apk-build.exit.json | B9963776AE60975FBE077B266837B6A838A5CEF31F75EDFF62AB9CA820EAD298 |
| successor-build-machine-state.json | D146F7F71CC99B52B0B0553887E4C984F785745AC4F99ED4B722061E273B0687 |
| uaw-cursor-redmi-rv6-fixes-20260914-build-provenance.txt | AAC8E3665F300291C0D31D0C6DE9991DD260AE7C18D5217E467DBC5829C0B986 |
| successor-apk-signer.log | DF32B0258C96DAD5939EEE4D72314434AEABE920199912E9976876C51166EE7D |
| successor-apk-badging.log | A49512E1313AC297AA45FF60FE4A223AE512268BF6D691EC345DD7824FD2550D |
| predecessor-apk-signer.log | DF32B0258C96DAD5939EEE4D72314434AEABE920199912E9976876C51166EE7D |
| successor-wrapper-preflight-v2.log | 057A2B63C38ADE9687EC3E5AE558BB5A1B8C1D54854A5C98743C079C03ABCC1B |


## r66.20 Redmi installation and D001 acceptance

Installation: adb-sTG8HCYTGGQT885OF install-r completedSuccess/exit0(335c4f). No uninstall,downgrade,clear-data or permission grant option used. Installed packagecom.moolsocial.app.cursorreview/versionCode2026091401/versionName1.0.0-r66.20-cursorreview(f3cf7f). Installed base.apk SHA2567734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8(c92eca), exactly matching verified candidate and archived APK. Launch via declared MainActivity completedCOLD/Statusok(095a0e). Capturerv620-001shows Shop, Saved1 and minimized delivery9+. This is visible retained state, not a blanket claim that all user data or backend behavior is qualified.

RV6-D001 CLOSED through scoped Redmi acceptance. Implementationd532b9dea97a52473a5a95e090a9831fd9635696; local evidence above; physical acceptance bound to the installed SHA256 above. Normal font_scale1.0/720x1600; exact StoreMoolMarket000001 via Fresh tomatoes1 product. Entry product differs from original audit's preceding product but enters the same Store and same shared paginated search surface; no supplier-data qualification inferred.

Reviewed captures001-011: launch;product;Visit store;Browse all products;searchzzzzzz with keyboard;Store categories;chooseFruits&vegetables with query retained;clear query to restore240listed category products;AndroidBack tosameStore;Back tosameFresh tomatoes1;Back toShop. Empty guidance exactlyTry another search or category;no unavailable area advice. Categorycontrol is real and selection applies;clearingquery recovers listed products withinStore. Returned ShopSavedbadge1,emptybasket/noAdd performed anddelivery9+retained. No real message,order,payment,profile,address or permission action. No child defect found in this D001 verification.

ElevenactualPNGcaptures inspected and hashed inEVIDENCE.csv under successor candidate, preserving all prior1177artifacts/514frozenpasses. Count:1of22device dispositions completed;remaining21(includingD019evidence-reconciliation check)pending. No other original markedclosed. D001closure is limited to its recorded normal-text guidance/recovery/return acceptance;no broadBuy re-audit.

## r66.20 Redmi D002 acceptance

RV6-D002 passed on Redmi TG8HCYTGGQT885OF, installed r66.20 APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Implementation: 55877c20437bdc34c1a90de19904381e94014cde. Normal text (1.0), 720x1600. Captures rv620-012 through rv620-022 preserve the sequence. Entry uses Fresh tomatoes 1 instead of the original preceding Turmeric product; same Store Mool Market 000001 and exact affected cart-over-Store sequence. Fruits & vegetables remains selected (240 listed products). Add only Fresh tomatoes 1, cart confirms 1 item / Rs37, Continue browsing same Store, Browse all products, decrement the sole item to zero. Capture019 and independent later capture020 show Store/category retained, Add restored, empty basket rail removed and compact cards restored. Android Back returns to Store overview (021), then Shop (022); filename022 says back-cart but observed destination is Shop, as expected after empty-cart session transition. Saved1 and minimized delivery9+ remain visible. Test-added item removed; no order/payment/message submitted. No new child found. Local checks remain distinct from this physical acceptance. Two of22 dispositions complete,20 remain including D019 evidence reconciliation.

## r66.20 Redmi D003 acceptance

RV6-D003: all three recorded frontend occurrences pass on Redmi TG8HCYTGGQT885OF, normal text 1.0, installed APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Implementation e01ff726fd7b92ecb8c3fd6928cc9f248b9f6eaa; local qualification above remains distinct. Captures rv620-023 through rv620-046.

1. Orders MS-NEW-09 / BUY-NEW-04, Rs74 / 2 items: tracking Refresh reports updates unavailable. Help and expanded Order conversation retain Last recorded estimate (update unavailable) with Delivery in12min, exact order/purchase/payment identity. No message sent; existing composed draft left untouched. Back restores tracking scroll.
2. View invoice retains same order, seller, two tomato packs and Rs74. Recorded delivery estimate says Original estimate (recorded time unavailable; not a live countdown). Download invoice opens Android Save; saved with unique name Redmi-r6620-D003-MS-NEW-09-20260914.pdf, preserving older files. Pulled actual device PDF (192029 bytes, SHA256 3E3CE6539D9636B17F1C01E55548EB3A8A22ADC1DF945DD75943D53E0952A649), rendered its one page and visually inspected identical historical qualifier, identity, amount and no clipping. Render rv620-d003-downloaded-invoice-page-1.png. Returned to invoice then tracking. No claim about authoritative tax issuance or provider timestamps.
3. Shop Sort & filter / Shopping tools / Shopping settings / Shopping alerts: Delivery update shows Last recorded estimate (update unavailable), Recorded order estimate, without Updated recently. Opens exact MS-NEW-09 with same unavailable state; Android Back restores alert sheet. Settings and preferences not changed. Account drawer was briefly opened as setup then dismissed without changes.

No new child observed. Three of22 originals now have completed scoped Redmi dispositions;19 remain including D019 evidence reconciliation. Existing provider/backend limitations remain unresolved; this closes the reproduced frontend freshness defect only. Frozen514 records and1177 artifacts remain untouched. Read-only tool recoveries: missing guessed Download/MoolSocial path, unsupported rg literal wildcard and absent Poppler; no product state changed. Used scoped external pypdfium2 renderer for actual PDF.

## r66.20 Redmi D004 acceptance

RV6-D004 passed on Redmi TG8HCYTGGQT885OF, normal text1.0,720x1600, installed APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Implementation2967bf188ffe6587a9f3e6409584ce3686504f60. Captures rv620-047 through054 cover setup from preceding Shopping alerts/settings toShop, account drawer, Personal profile, Display name, whitespace-only draft submission, error with keyboard, AndroidBack hides keyboard, Back toProfile. Full error Enter a display name from 2 to 60 characters. wraps across two lines in both keyboard states, no ellipsis/clipping. Whitespace rejected; original Display name Not added and profile setup1of3 retained; no valid profile save or real transaction/message. Source acceptance matches original198/199 at normal text; host enlarged-text checks remain separate. No child found. Four of22 dispositions complete;18 remain including D019 evidence reconciliation.

## r66.20 Redmi D005 disposition - remains open

Captures rv620-055 through064, Redmi TG8HCYTGGQT885OF, normal text1.0, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Implementation dce65c05ab54b39751211a608c923c00226e4a26. Immediate disclosure passes: picker states Buy/settings use English and Hindi preference only; selection summary in Preferences and Profile states Hindi preferred / App screens: English. Hindi glyphs render. Back to Buy preserves same Shop, Saved1 and minimized9+. Cold restart via force-stop exact package then am start declared MainActivity (7472bd Statusok/COLD/exit0) resets preference to English; reopened picker confirms English selected. Registered distinct RV6-D005-C01 before moving on. No claim of full D005 qualification. Host persistence results did not prove Android durability; cause unproven, no child implementation. Dismissed picker; original English now visible, no data clearing or real transaction/message.

Counts:5of22 originals have scoped device dispositions:4closed,1open with failed retention/linkedchild;17not yet dispositioned. Total originals open18;one new child. Frozen514/1177 preserved.

## r66.20 Redmi D006 acceptance

RV6-D006 passed the exact previously failing sequence on Redmi TG8HCYTGGQT885OF, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Implementation ed0233761e825e22a4d6e14c7d0f0e0073f9ea25; local checks above remain distinct. Captures rv620-065 through070: Quick Shop origin, profile drawer, Security, Sign in chooser, AndroidBack cancellation to Security, second AndroidBack to same Quick Shop. No Android launcher exit. Visible original catalogue products, Saved1 and minimized9+ retained; empty basket unchanged. No provider selected, authentication, message or transaction performed. Normal text1.0. No child found for D006. Six of22 dispositions complete:5closed, D005open with C01,16remaining. Prior passes not independently re-audited.

## r66.20 Redmi D007 acceptance

Original281-283 reproduction passes on Redmi TG8HCYTGGQT885OF, normal text1.0, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Implementation e604579b1f102573766bcaee8bcbf772f9cf96bd. Captures rv620-071 through077: SavedShop wheat atta2, open MoolMarket000001 product, scroll to You may also like, open related Stone-ground wheat atta from Sardarpura Supermart, AndroidBack to exact previous lower-product position (074 and076), second AndroidBack to SavedShop one wheat item (071 and077). Correct previous product identity visible in related detail Back label; original lower-page location jodhpur/Market1 restored. Saved1 and emptycart preserved, no Add/bookmark mutation/message/order. No new child. Device closure is for recorded Saved related-product reproduction and required final origin return; additional search/multiple-nested host cases remain local evidence, not claimed as physical passes. Sevenof22 device dispositions:6closed,D005tested-open with onechild,15pending.

## r66.20 Redmi D008 acceptance

RV6-D008 original312 passes on Redmi TG8HCYTGGQT885OF, font1.0/720x1600, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Implementation0fe77e604fc4787a3b1584a3c0e3e92bff1e53e5. Captures rv620-078 through083: Orders, search Wholesale, Delivered, PO-240728 View order, buyer row, AndroidBack. Retailer business and Shree Balaji Retail have visible separation and complete text; correct order identity and Rs8460 retained. Back retains Wholesale query and Delivered tab/order. Initial automated text arrived before focus and showed holesale; cleared and entered exact Wholesale before acceptance; not classified as a customer defect. No order/payment/message action or other testing. No child. Eightof22 dispositions:7closed,D005tested-open/onechild,14pending. Local200% checks remain local evidence, not claimed as physical qualification.

## r66.20 D011 Redmi observation checkpoint

Captures rv620-084 through088 inspect the recorded Wholesale Fresh tomatoes1/10kg/Rs580 listing on Redmi TG8HCYTGGQT885OF, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Normal text. Summary-only Highlights, Specifications and generated Description are absent; price/pack/MOQ2/Rs1160 minimum, freight/tax details, product details, product/pack information, ratings/reviews and related products remain visible. No Add or other product action. D011 final return and disposition not yet recorded; no closure claimed by this checkpoint.

D011 final acceptance: capture089 AndroidBack restores same Wholesale catalogue. Implementation b46c582bc747c15576f8349b0c2fd144d452f02b. Recorded407-410 summary-only repetition correction passes; remaining structured Product details/Product and pack information are retained intentionally, not claimed globally deduplicated. No child; no cart/bookmark mutation. Nineof22 device dispositions complete:8closed,D005tested-open/onechild,13pending including D009/D010.


### RV6-D016 scoped Redmi acceptance - 2026-09-14

Implementation ac5a95e5f8fa410ca4e5d0e8c41ca5de7bd271eb. Redmi TG8HCYTGGQT885OF, r66.20, installed APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Captures rv620-097 through103: existing Shop filter > Shopping tools > Shopping settings > Shopping alerts > New Shop offers opens actual Offers heading, selected Offers tab, offer content and offer cards (102); Android Back restores the same four-alert sheet (103 versus101). No cart, saved item, notification preference, order or message changed. Recorded reproduction and expected return pass; original closed, no child found. This establishes fixture frontend navigation only, not provider offer publication.

D012 setup captures090-096 inspected the nine current Recently viewed products; the required closed Pet Family product was absent. No D012 acceptance is inferred from these setup captures; original remains pending.


### RV6-D017 scoped Redmi acceptance - 2026-09-14

Implementation99f74b80e37850003f7fdd37db81e71387fbc9ca. Redmi TG8HCYTGGQT885OF, r66.20, installed APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Captures104-124. Opened existing saved wheat2, added one temporary 5kg pack at279, reviewed checkout with original Work address and Paytm selection unchanged. Confirm order tab from Address did not advance; normal Continue to payment > Review order reached the required form. No Check delivery, order submission or external payment action.

Enabled GST; initially no saved profile. Added AuditRedmiTest with repository test GSTIN08ABCDE1234F1Z5 and RedmiTestBillingOnly, temporary reuse enabled. Capture117 shows readable white selected name/check/remove on navy, matching current detail card. Remove opens exact named confirmation118; Keep preserves selected profile119. Remove confirmed deletes only temporary test profile and clears current details120. Disabled GST again, AndroidBack through Payment/Address to Cart122, removed only temporary wheat item. Settled124 shows Shop without cart rail, Saved1 unchanged. Capture123 contains an incidental incoming system notification; no notification action taken and it is not application acceptance evidence.

Recorded691-692 reproduction and directly affected Keep/removal pass at normal device text. 200% and Wholesale variants remain local evidence only; no claim they were physically repeated. Original D017 closed, no child found. No real invoice, tax verification, payment, order or provider qualification.


### RV6-D018 partial scoped Redmi evidence - 2026-09-14

Redmi TG8HCYTGGQT885OF, r66.20, APK SHA2567734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Captures125-134. Selected Scheduled, entered milk. Keyboard Search tap produced milke (127), corrected trailing e; adb Enter inserted a newline (128), removed it, then header check returned ordinary Shop129. These setup variations are not passes of the original keyboard Search step. Reopened milk search and hid keyboard with AndroidBack130. Next produced exact41-80 origin131 with milk1184. Opened milk1184(132); AndroidBack133 restores dedicated search, milk query,41-80 range and same product card positions. No cart mutation or message/order/payment action.134 is a subsequent small scroll, not additional return evidence.

Navigation correction passes this equivalent-origin setup, but D018 remains pending full disposition: the exact original keyboard submission and remaining applicable position acceptance have not yet been conclusively qualified. Do not infer a new app keyboard child from ambiguous input automation alone; no child registered at this checkpoint.


### RV6-D019 scoped Redmi reconciliation acceptance - 2026-09-14

Evidence-only reconciliation70b117b966a58ca4a551edb31742e175c2723dde; no product correction claimed. Redmi TG8HCYTGGQT885OF, r66.20, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Captures135-139: closed search via its check control to Scheduled Shop; opened delivery rail136 showing12 deliveries, MS-NEW-09, sound off and Keep off. Minimize137 retains bike and9+ count. Reopen138 retains same order/count and unchanged off controls; Hide139 restores bike9+. No lost identity or stale collapse icon found. Original closed as evidence-reconciled and successor-device confirmed, not an implemented fix. No child. Cart remains empty, Saved1; no sound/Keep toggles, provider action or order/message change.


### RV6-D020 scoped Redmi acceptance - 2026-09-14

Implementation9a81541e866975c15c4044f8a5d68906e45dd638. Redmi TG8HCYTGGQT885OF, r66.20, APK SHA256 7734E316D215809C012FCB961204E46B49C3514DFACBC478600D507D33DC89B8. Captures140-146. Public Shop Chat > More > Chat settings > Privacy and spam > Who can message you.144 and settled145 after upward swipe show full final explanation: Existing conversations stay available; no one new can start. Last line ends above Android navigation with clear bottom space. Everyone remains selected. AndroidBack146 dismisses to original settings position with Everyone unchanged. No permission choice selected, no message or service action. Recorded normal-text931-933 reproduction and dismissal pass; 200% remains local evidence only. Original D020 closed, no child found.
