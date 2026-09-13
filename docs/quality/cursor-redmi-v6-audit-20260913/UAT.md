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
| SRC-0001 | buy_v2_catalogue.dart:320 | _BuyV2OffersViewState | onTap | unclassified |
| SRC-0002 | buy_v2_catalogue.dart:436 | _PagedPublishedOffersViewState | onTap | unclassified |
| SRC-0003 | buy_v2_catalogue.dart:493 | _chooseOffersCategory | onPressed | unclassified |
| SRC-0004 | buy_v2_catalogue.dart:502 | _chooseOffersCategory | onTap | unclassified |
| SRC-0005 | buy_v2_catalogue.dart:509 | _chooseOffersCategory | onTap | unclassified |
| SRC-0006 | buy_v2_catalogue.dart:554 | _OffersCategoryControl | onTap | unclassified |
| SRC-0007 | buy_v2_catalogue.dart:633 | _PublishedOfferPromotionState | onTap | unclassified |
| SRC-0008 | buy_v2_catalogue.dart:679 | _PublishedOfferPromotionState | onPressed | unclassified |
| SRC-0009 | buy_v2_catalogue.dart:685 | _PublishedOfferPromotionState | onPressed | unclassified |
| SRC-0010 | buy_v2_catalogue.dart:703 | _PublishedOfferPromotionState | onPressed | unclassified |
| SRC-0011 | buy_v2_catalogue.dart:764 | _LiveOffersState | onPressed | unclassified |
| SRC-0012 | buy_v2_catalogue.dart:823 | _OffersAvailabilityState | onPressed | unclassified |
| SRC-0013 | buy_v2_catalogue.dart:1350 | _CataloguePageControls | onPressed | unclassified |
| SRC-0014 | buy_v2_catalogue.dart:1356 | _CataloguePageControls | onPressed | unclassified |
| SRC-0015 | buy_v2_catalogue.dart:1362 | _CataloguePageControls | onPressed | unclassified |
| SRC-0016 | buy_v2_catalogue.dart:1370 | _CataloguePageControls | onPressed | unclassified |
| SRC-0017 | buy_v2_catalogue.dart:1456 | _CataloguePageNotice | onPressed | unclassified |
| SRC-0018 | buy_v2_catalogue.dart:1574 | showBuyV2CatalogueArea | onPressed | unclassified |
| SRC-0019 | buy_v2_catalogue.dart:1589 | showBuyV2CatalogueArea | onPressed | unclassified |
| SRC-0020 | buy_v2_catalogue.dart:1602 | showBuyV2CatalogueArea | onChanged | unclassified |
| SRC-0021 | buy_v2_catalogue.dart:1621 | showBuyV2CatalogueArea | onSubmitted | unclassified |
| SRC-0022 | buy_v2_catalogue.dart:1629 | showBuyV2CatalogueArea | onPressed | unclassified |
| SRC-0023 | buy_v2_catalogue.dart:1642 | showBuyV2CatalogueArea | onSelected | unclassified |
| SRC-0024 | buy_v2_catalogue.dart:1647 | showBuyV2CatalogueArea | onSelected | unclassified |
| SRC-0025 | buy_v2_catalogue.dart:1699 | showBuyV2CatalogueArea | onTap | unclassified |
| SRC-0026 | buy_v2_catalogue.dart:1723 | showBuyV2CatalogueArea | onTap | unclassified |
| SRC-0027 | buy_v2_catalogue.dart:1735 | showBuyV2CatalogueArea | onTap | unclassified |
| SRC-0028 | buy_v2_catalogue.dart:1943 | _CatalogueSaleTypeSelector | onHorizontalDragEnd | unclassified |
| SRC-0029 | buy_v2_catalogue.dart:2014 | _CatalogueSaleTypeSelector | onTap | unclassified |
| SRC-0030 | buy_v2_catalogue.dart:2062 | _CatalogueSaleSegment | onTap | unclassified |
| SRC-0031 | buy_v2_catalogue.dart:2066 | _CatalogueSaleSegment | onTap | unclassified |
| SRC-0032 | buy_v2_catalogue.dart:2263 | BuyV2ShoppingIntentBar | onPressed | unclassified |
| SRC-0033 | buy_v2_catalogue.dart:2347 | _CatalogueAccountReturn | onTap | unclassified |
| SRC-0034 | buy_v2_catalogue.dart:2631 | _CatalogueStoreMatchesState | onTap | unclassified |
| SRC-0035 | buy_v2_catalogue.dart:2768 | _SearchReadyState | onPressed | unclassified |
| SRC-0036 | buy_v2_catalogue.dart:2785 | _SearchReadyState | onTap | unclassified |
| SRC-0037 | buy_v2_catalogue.dart:2844 | _SearchReadyState | onTap | unclassified |
| SRC-0038 | buy_v2_catalogue.dart:2954 | _SearchProductResults | onPressed | unclassified |
| SRC-0039 | buy_v2_catalogue.dart:3072 | _CatalogueToolbar | onTap | unclassified |
| SRC-0040 | buy_v2_catalogue.dart:3152 | _CatalogueCategoryPickerButton | onTap | unclassified |
| SRC-0041 | buy_v2_catalogue.dart:3215 | _CatalogueOwnedFeature | onTap | unclassified |
| SRC-0042 | buy_v2_catalogue.dart:3433 | _CatalogueCategorySheetState | onPressed | unclassified |
| SRC-0043 | buy_v2_catalogue.dart:3469 | _CatalogueCategorySheetState | onTap | unclassified |
| SRC-0044 | buy_v2_catalogue.dart:3476 | _CatalogueCategorySheetState | onChanged | unclassified |
| SRC-0045 | buy_v2_catalogue.dart:3518 | _CatalogueCategorySheetState | onPressed | unclassified |
| SRC-0046 | buy_v2_catalogue.dart:3628 | _CatalogueCategorySheetState | onTap | unclassified |
| SRC-0047 | buy_v2_catalogue.dart:3916 | _CatalogueCategoryClearButton | onPressed | unclassified |
| SRC-0048 | buy_v2_catalogue.dart:4006 | _CompactCatalogueAction | onTap | unclassified |
| SRC-0049 | buy_v2_catalogue.dart:4052 | _CatalogueChromeActionState | onTap | unclassified |
| SRC-0050 | buy_v2_catalogue.dart:4100 | _CatalogueChromeActionState | onTap | unclassified |
| SRC-0051 | buy_v2_catalogue.dart:4192 | _CatalogueToolsMenu | onTap | unclassified |
| SRC-0052 | buy_v2_catalogue.dart:4200 | _CatalogueToolsMenu | onTap | unclassified |
| SRC-0053 | buy_v2_catalogue.dart:4218 | _CatalogueToolsMenu | onTap | unclassified |
| SRC-0054 | buy_v2_catalogue.dart:4231 | _CatalogueToolsMenu | onTap | unclassified |
| SRC-0055 | buy_v2_catalogue.dart:4243 | _CatalogueToolsMenu | onTap | unclassified |
| SRC-0056 | buy_v2_catalogue.dart:4264 | _CatalogueToolsMenu | onTap | unclassified |
| SRC-0057 | buy_v2_catalogue.dart:4434 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0058 | buy_v2_catalogue.dart:4443 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0059 | buy_v2_catalogue.dart:4462 | _BuyV2ShoppingSettingsSheetState | onChanged | unclassified |
| SRC-0060 | buy_v2_catalogue.dart:4469 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0061 | buy_v2_catalogue.dart:4492 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0062 | buy_v2_catalogue.dart:4499 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0063 | buy_v2_catalogue.dart:4508 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0064 | buy_v2_catalogue.dart:4515 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0065 | buy_v2_catalogue.dart:4534 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0066 | buy_v2_catalogue.dart:4545 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0067 | buy_v2_catalogue.dart:4556 | _BuyV2ShoppingSettingsSheetState | onTap | unclassified |
| SRC-0068 | buy_v2_catalogue.dart:4605 | _ShoppingSettingsRow | onTap | unclassified |
| SRC-0069 | buy_v2_catalogue.dart:4682 | _confirmClearBuyV2RecentlyViewed | onPressed | unclassified |
| SRC-0070 | buy_v2_catalogue.dart:4687 | _confirmClearBuyV2RecentlyViewed | onPressed | unclassified |
| SRC-0071 | buy_v2_catalogue.dart:4844 | _BuyV2ShoppingHelpSheetState | onPressed | unclassified |
| SRC-0072 | buy_v2_catalogue.dart:4913 | _BuyV2ShoppingHelpSheetState | onChanged | unclassified |
| SRC-0073 | buy_v2_catalogue.dart:4926 | _BuyV2ShoppingHelpSheetState | onPressed | unclassified |
| SRC-0074 | buy_v2_catalogue.dart:4965 | _BuyV2ShoppingHelpSheetState | onTap | unclassified |
| SRC-0075 | buy_v2_catalogue.dart:5104 | showBuyV2ShoppingAlerts | onPressed | unclassified |
| SRC-0076 | buy_v2_catalogue.dart:5138 | showBuyV2ShoppingAlerts | onTap | unclassified |
| SRC-0077 | buy_v2_catalogue.dart:5534 | showBuyV2PartnerCatalogue | onTap | unclassified |
| SRC-0078 | buy_v2_catalogue.dart:5611 | showBuyV2PartnerCatalogue | onPressed | unclassified |
| SRC-0079 | buy_v2_catalogue.dart:5729 | showBuyV2PartnerCatalogue | onTap | unclassified |
| SRC-0080 | buy_v2_catalogue.dart:6070 | _PublicStoreTruthPanelState | onPressed | unclassified |
| SRC-0081 | buy_v2_catalogue.dart:6099 | _PublicStoreTruthPanelState | onTap | unclassified |
| SRC-0082 | buy_v2_catalogue.dart:6190 | _PublicStoreTruthPanelState | onTap | unclassified |
| SRC-0083 | buy_v2_catalogue.dart:6422 | BuyV2StoreCartBar | onTap | unclassified |
| SRC-0084 | buy_v2_catalogue.dart:6434 | BuyV2StoreCartBar | onTap | unclassified |
| SRC-0085 | buy_v2_catalogue.dart:6683 | _PagedFullStoreCatalogueState | onPressed | unclassified |
| SRC-0086 | buy_v2_catalogue.dart:6692 | _PagedFullStoreCatalogueState | onTap | unclassified |
| SRC-0087 | buy_v2_catalogue.dart:6701 | _PagedFullStoreCatalogueState | onTap | unclassified |
| SRC-0088 | buy_v2_catalogue.dart:6762 | _PagedFullStoreCatalogueState | onPressed | unclassified |
| SRC-0089 | buy_v2_catalogue.dart:6792 | _PagedFullStoreCatalogueState | onPressed | unclassified |
| SRC-0090 | buy_v2_catalogue.dart:6797 | _PagedFullStoreCatalogueState | onChanged | unclassified |
| SRC-0091 | buy_v2_catalogue.dart:6798 | _PagedFullStoreCatalogueState | onSubmitted | unclassified |
| SRC-0092 | buy_v2_catalogue.dart:6816 | _PagedFullStoreCatalogueState | onTap | unclassified |
| SRC-0093 | buy_v2_catalogue.dart:6928 | _showBuyV2FullStoreCatalogue | onPressed | unclassified |
| SRC-0094 | buy_v2_catalogue.dart:7032 | _RelatedStoreCard | onTap | unclassified |
| SRC-0095 | buy_v2_catalogue.dart:7206 | _BuyV2InfoSheetHeader | onPressed | unclassified |
| SRC-0096 | buy_v2_catalogue.dart:7383 | _RecentlyViewedProductsSheet | onPressed | unclassified |
| SRC-0097 | buy_v2_catalogue.dart:7519 | _RecentlyViewedProductInfoRow | onTap | unclassified |
| SRC-0098 | buy_v2_catalogue.dart:7525 | _RecentlyViewedProductInfoRow | onTap | unclassified |
| SRC-0099 | buy_v2_catalogue.dart:7582 | _RecentlyViewedProductInfoRow | onPressed | unclassified |
| SRC-0100 | buy_v2_catalogue.dart:7700 | _SavedProductInfoRow | onTap | unclassified |
| SRC-0101 | buy_v2_catalogue.dart:7704 | _SavedProductInfoRow | onTap | unclassified |
| SRC-0102 | buy_v2_catalogue.dart:7752 | _SavedProductInfoRow | onPressed | unclassified |
| SRC-0103 | buy_v2_catalogue.dart:7799 | _HouseholdBasket | onPressed | unclassified |
| SRC-0104 | buy_v2_catalogue.dart:7809 | _HouseholdBasket | onPressed | unclassified |
| SRC-0105 | buy_v2_catalogue.dart:8088 | _ProductGrid | onPressed | unclassified |
| SRC-0106 | buy_v2_catalogue.dart:8308 | BuyV2CatalogueAvailabilityView | onPressed | unclassified |
| SRC-0107 | buy_v2_catalogue.dart:8322 | BuyV2CatalogueAvailabilityView | onPressed | unclassified |
| SRC-0108 | buy_v2_catalogue.dart:8369 | _SavedDecisionShelf | onPressed | unclassified |
| SRC-0109 | buy_v2_catalogue.dart:8478 | _SavedDecisionShelf | onPressed | unclassified |
| SRC-0110 | buy_v2_catalogue.dart:8611 | _SavedClearDecisionSheet | onPressed | unclassified |
| SRC-0111 | buy_v2_catalogue.dart:8621 | _SavedClearDecisionSheet | onPressed | unclassified |
| SRC-0112 | buy_v2_catalogue.dart:8636 | _SavedClearDecisionSheet | onPressed | unclassified |
| SRC-0113 | buy_v2_catalogue.dart:9250 | _CataloguePromotionRail | onTap | unclassified |
| SRC-0114 | buy_v2_catalogue.dart:9259 | _CataloguePromotionRail | onTap | unclassified |
| SRC-0115 | buy_v2_catalogue.dart:9270 | _CataloguePromotionRail | onTap | unclassified |
| SRC-0116 | buy_v2_catalogue.dart:9282 | _CataloguePromotionRail | onTap | unclassified |
| SRC-0117 | buy_v2_catalogue.dart:9293 | _CataloguePromotionRail | onTap | unclassified |
| SRC-0118 | buy_v2_catalogue.dart:9302 | _CataloguePromotionRail | onTap | unclassified |
| SRC-0119 | buy_v2_catalogue.dart:9434 | _PrescriptionMatchLane | onTap | unclassified |
| SRC-0120 | buy_v2_catalogue.dart:9444 | _PrescriptionMatchLane | onPressed | unclassified |
| SRC-0121 | buy_v2_catalogue.dart:9557 | _FeaturedProductRail | onTap | unclassified |
| SRC-0122 | buy_v2_catalogue.dart:9561 | _FeaturedProductRail | onTap | unclassified |
| SRC-0123 | buy_v2_catalogue.dart:9673 | _RecentlyViewedRail | onPressed | unclassified |
| SRC-0124 | buy_v2_catalogue.dart:9792 | _RecentlyViewedCard | onTap | unclassified |
| SRC-0125 | buy_v2_catalogue.dart:9903 | _CatalogueSectionHeader | onTap | unclassified |
| SRC-0126 | buy_v2_catalogue.dart:9907 | _CatalogueSectionHeader | onTap | unclassified |
| SRC-0127 | buy_v2_catalogue.dart:10048 | _FeaturedProductCardState | onTap | unclassified |
| SRC-0128 | buy_v2_catalogue.dart:10351 | _FeaturedProductAction | onTap | unclassified |
| SRC-0129 | buy_v2_catalogue.dart:10511 | BuyV2ProductCard | onTap | unclassified |
| SRC-0130 | buy_v2_catalogue.dart:10814 | BuyV2ProductCard | onTap | unclassified |
| SRC-0131 | buy_v2_catalogue.dart:11136 | _QuantityStepperTargets | onTap | unclassified |
| SRC-0132 | buy_v2_catalogue.dart:11139 | _QuantityStepperTargets | onPressed | unclassified |
| SRC-0133 | buy_v2_catalogue.dart:11165 | _QuantityStepperTargets | onTap | unclassified |
| SRC-0134 | buy_v2_catalogue.dart:11168 | _QuantityStepperTargets | onPressed | unclassified |
| SRC-0135 | buy_v2_catalogue.dart:11230 | _ProductSaveButton | onTap | unclassified |
| SRC-0136 | buy_v2_catalogue.dart:11283 | _ProductSaveButton | onPressed | unclassified |
| SRC-0137 | buy_v2_design.dart:2489 | _BuyV2PromotionCardState | onTap | unclassified |
| SRC-0138 | buy_v2_design.dart:2510 | _BuyV2PromotionCardState | onTap | unclassified |
| SRC-0139 | buy_v2_invoice.dart:135 | _BuyV2InvoicePageState | onPressed | unclassified |
| SRC-0140 | buy_v2_invoice.dart:588 | _BuyV2InvoicePageState | onPressed | unclassified |
| SRC-0141 | buy_v2_product_video.dart:204 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0142 | buy_v2_product_video.dart:308 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0143 | buy_v2_product_video.dart:323 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0144 | buy_v2_product_video.dart:341 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0145 | buy_v2_product_video.dart:369 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0146 | buy_v2_product_video.dart:383 | _BuyV2ProductVideoState | onChanged | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0147 | buy_v2_product_video.dart:407 | _BuyV2ProductVideoState | onPressed | blocked_test_data B-008; MEDIA-ROUND75-03 through08; supplier media absent |
| SRC-0148 | buy_v2_scanner.dart:180 | _BuyV2CollectionCameraState | onPressed | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
| SRC-0149 | buy_v2_scanner.dart:207 | _BuyV2CollectionCameraState | onPressed | source_unreachable for public Buy; SCANNER-ROUND74-01; Workspace callers excluded |
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
| SRC-0163 | buy_v2_screen.dart:861 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0164 | buy_v2_screen.dart:878 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0165 | buy_v2_screen.dart:896 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0166 | buy_v2_screen.dart:923 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0167 | buy_v2_screen.dart:954 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0168 | buy_v2_screen.dart:1402 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0169 | buy_v2_screen.dart:1532 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0170 | buy_v2_screen.dart:1546 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0171 | buy_v2_screen.dart:1571 | _BuyV2ScreenState | onTap | unclassified |
| SRC-0172 | buy_v2_screen.dart:1777 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0173 | buy_v2_screen.dart:1784 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0174 | buy_v2_screen.dart:1791 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0175 | buy_v2_screen.dart:1840 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0176 | buy_v2_screen.dart:1857 | _BuyV2ScreenState | onPressed | unclassified |
| SRC-0177 | buy_v2_screen.dart:2671 | _BuyQuickDeliveryStatusBar | onTap | unclassified |
| SRC-0178 | buy_v2_screen.dart:2701 | _BuyQuickDeliveryStatusBar | onPressed | unclassified |
| SRC-0179 | buy_v2_screen.dart:2741 | _BuyQuickDeliveryStatusBar | onTap | unclassified |
| SRC-0180 | buy_v2_screen.dart:2767 | _BuyQuickDeliveryStatusBar | onPressed | unclassified |
| SRC-0181 | buy_v2_screen.dart:2793 | _BuyQuickDeliveryStatusBar | onPressed | unclassified |
| SRC-0182 | buy_v2_screen.dart:2820 | _BuyQuickDeliveryStatusBar | onPressed | unclassified |
| SRC-0183 | buy_v2_screen.dart:2836 | _BuyQuickDeliveryStatusBar | onPressed | unclassified |
| SRC-0184 | buy_v2_screen.dart:3130 | _BuySearchBand | onChanged | unclassified |
| SRC-0185 | buy_v2_screen.dart:3173 | _BuySearchBand | onSubmitted | unclassified |
| SRC-0186 | buy_v2_screen.dart:3182 | _BuySearchBand | onTap | unclassified |
| SRC-0187 | buy_v2_screen.dart:3227 | _BuySearchBand | onPressed | unclassified |
| SRC-0188 | buy_v2_screen.dart:3245 | _BuySearchBand | onPressed | unclassified |
| SRC-0189 | buy_v2_screen.dart:3278 | _BuySearchBand | onPressed | unclassified |
| SRC-0190 | buy_v2_screen.dart:3291 | _BuySearchBand | onPressed | unclassified |
| SRC-0191 | buy_v2_screen.dart:3443 | _BuyMiniCartBarState | onTap | unclassified |
| SRC-0192 | buy_v2_screen.dart:3457 | _BuyMiniCartBarState | onTap | unclassified |
| SRC-0193 | buy_v2_screen.dart:3563 | _BuyMiniCartBarState | onTap | unclassified |
| SRC-0194 | buy_v2_screen.dart:3591 | _BuyMiniCartBarState | onTap | unclassified |
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
| SRC-0266 | buy_v2_views.dart:68 | _openOrderInvoice | onPressed | unclassified |
| SRC-0267 | buy_v2_views.dart:78 | _openOrderInvoice | onPressed | unclassified |
| SRC-0268 | buy_v2_views.dart:593 | BuyV2ProductView | onPressed | unclassified |
| SRC-0269 | buy_v2_views.dart:620 | BuyV2ProductView | onTap | unclassified |
| SRC-0270 | buy_v2_views.dart:952 | BuyV2ProductView | onTap | unclassified |
| SRC-0271 | buy_v2_views.dart:1440 | _ProductQuickActions | onPressed | unclassified |
| SRC-0272 | buy_v2_views.dart:1445 | _ProductQuickActions | onPressed | unclassified |
| SRC-0273 | buy_v2_views.dart:1452 | _ProductQuickActions | onPressed | unclassified |
| SRC-0274 | buy_v2_views.dart:1465 | _ProductQuickActions | onPressed | unclassified |
| SRC-0275 | buy_v2_views.dart:1491 | _ProductQuickActions | onPressed | unclassified |
| SRC-0276 | buy_v2_views.dart:1520 | _ProductQuickActionButton | onTap | unclassified |
| SRC-0277 | buy_v2_views.dart:1523 | _ProductQuickActionButton | onTap | unclassified |
| SRC-0278 | buy_v2_views.dart:1879 | _ProductComparisonSheetState | onPressed | unclassified |
| SRC-0279 | buy_v2_views.dart:1948 | _ProductComparisonSheetState | onPressed | unclassified |
| SRC-0280 | buy_v2_views.dart:1956 | _ProductComparisonSheetState | onPressed | unclassified |
| SRC-0281 | buy_v2_views.dart:2137 | _ProductVariantOption | onTap | unclassified |
| SRC-0282 | buy_v2_views.dart:2153 | _ProductVariantOption | onTap | unclassified |
| SRC-0283 | buy_v2_views.dart:2250 | _WholesaleVerificationCard | onPressed | unclassified |
| SRC-0284 | buy_v2_views.dart:2489 | _WholesaleTradeDecisionPanelState | onPressed | unclassified |
| SRC-0285 | buy_v2_views.dart:2502 | _WholesaleTradeDecisionPanelState | onPressed | unclassified |
| SRC-0286 | buy_v2_views.dart:2751 | _WholesaleTradeSignalCard | onPressed | unclassified |
| SRC-0287 | buy_v2_views.dart:2851 | _WholesaleTradeActionDock | onPressed | unclassified |
| SRC-0288 | buy_v2_views.dart:2861 | _WholesaleTradeActionDock | onPressed | unclassified |
| SRC-0289 | buy_v2_views.dart:3143 | _ProductOfferDecisionPanel | onPressed | unclassified |
| SRC-0290 | buy_v2_views.dart:3155 | _ProductOfferDecisionPanel | onPressed | unclassified |
| SRC-0291 | buy_v2_views.dart:3289 | _ProductContinuationCard | onTap | unclassified |
| SRC-0292 | buy_v2_views.dart:3295 | _ProductContinuationCard | onTap | unclassified |
| SRC-0293 | buy_v2_views.dart:3553 | _BuyV2ZoomableMediaState | onTap | blocked_test_data B-008; MEDIA-ROUND75-02 reset zoom, including reduced motion; actual supplier image absent |
| SRC-0294 | buy_v2_views.dart:3868 | _ProductContentSections | onPressed | unclassified |
| SRC-0295 | buy_v2_views.dart:4118 | _ProductBenefitsPreview | onPressed | unclassified |
| SRC-0296 | buy_v2_views.dart:4286 | _MarketplaceTrustPanel | onPressed | unclassified |
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
| SRC-0309 | buy_v2_views.dart:5364 | _AddressSelectionRequired | onPressed | unclassified |
| SRC-0310 | buy_v2_views.dart:5421 | _MissingOrderSelection | onPressed | unclassified |
| SRC-0311 | buy_v2_views.dart:5569 | _BuyV2CartViewState | onPressed | CART-ROUND12-05/06; MIXED-ROUND63-05/06; empty-disabled and resolution shortcut unqualified |
| SRC-0312 | buy_v2_views.dart:5630 | _BuyV2CartViewState | onPressed | STORE-009 Continue browsing; D002 last-item removal context failure remains open |
| SRC-0313 | buy_v2_views.dart:5677 | _BuyV2CartViewState | onPressed | Browse more products callback; exact nonempty-cart control needs device evidence reconciliation |
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
| SRC-0331 | buy_v2_views.dart:6706 | _CheckoutQuoteCard | onPressed | unclassified |
| SRC-0332 | buy_v2_views.dart:6857 | _CheckoutCommercialPaymentTerms | onPressed | unclassified |
| SRC-0333 | buy_v2_views.dart:6969 | _CommercialPaymentTermGroup | onChanged | unclassified |
| SRC-0334 | buy_v2_views.dart:7068 | BuyV2CheckoutView | onTap | unclassified |
| SRC-0335 | buy_v2_views.dart:7154 | BuyV2CheckoutView | onPressed | unclassified |
| SRC-0336 | buy_v2_views.dart:7490 | _CheckoutCollectionDetails | onTap | unclassified |
| SRC-0337 | buy_v2_views.dart:7508 | _CheckoutCollectionDetails | onTap | unclassified |
| SRC-0338 | buy_v2_views.dart:7565 | _CheckoutCollectionDetails | onTap | unclassified |
| SRC-0339 | buy_v2_views.dart:7602 | _CheckoutAddressStage | onSelected | unclassified |
| SRC-0340 | buy_v2_views.dart:7610 | _CheckoutAddressStage | onSelected | unclassified |
| SRC-0341 | buy_v2_views.dart:7665 | _CheckoutAddressStage | onPressed | unclassified |
| SRC-0342 | buy_v2_views.dart:7698 | _CheckoutAddressChoice | onTap | unclassified |
| SRC-0343 | buy_v2_views.dart:7711 | _CheckoutAddressChoice | onTap | unclassified |
| SRC-0344 | buy_v2_views.dart:7748 | _CheckoutAddressChoice | onPressed | unclassified |
| SRC-0345 | buy_v2_views.dart:7840 | _CheckoutPaymentStage | onTap | unclassified |
| SRC-0346 | buy_v2_views.dart:7921 | _CheckoutPaymentStage | onTap | unclassified |
| SRC-0347 | buy_v2_views.dart:7951 | _CheckoutPaymentStage | onChanged | unclassified |
| SRC-0348 | buy_v2_views.dart:8139 | _CheckoutPaymentStateRow | onPressed | unclassified |
| SRC-0349 | buy_v2_views.dart:8232 | _CheckoutConfirmStage | onTap | unclassified |
| SRC-0350 | buy_v2_views.dart:8293 | _CheckoutConfirmStage | onTap | unclassified |
| SRC-0351 | buy_v2_views.dart:8433 | _CheckoutPrimaryActionBar | onPressed | unclassified |
| SRC-0352 | buy_v2_views.dart:8669 | _CheckoutPriceChangeReview | onPressed | unclassified |
| SRC-0353 | buy_v2_views.dart:8729 | _CheckoutPromiseChangeReview | onPressed | unclassified |
| SRC-0354 | buy_v2_views.dart:8845 | BuyV2ConfirmationView | onPressed | unclassified |
| SRC-0355 | buy_v2_views.dart:8858 | BuyV2ConfirmationView | onPressed | unclassified |
| SRC-0356 | buy_v2_views.dart:9016 | _PlacedOrderCard | onPressed | unclassified |
| SRC-0357 | buy_v2_views.dart:9292 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0358 | buy_v2_views.dart:9302 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0359 | buy_v2_views.dart:9309 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0360 | buy_v2_views.dart:9314 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0361 | buy_v2_views.dart:9322 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0362 | buy_v2_views.dart:9335 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0363 | buy_v2_views.dart:9344 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0364 | buy_v2_views.dart:9353 | BuyV2RecoveryView | onPressed | unclassified |
| SRC-0365 | buy_v2_views.dart:9429 | BuyV2OrdersView | onTap | unclassified |
| SRC-0366 | buy_v2_views.dart:9490 | BuyV2OrdersView | onTap | unclassified |
| SRC-0367 | buy_v2_views.dart:9636 | _OrdersTabButton | onTap | unclassified |
| SRC-0368 | buy_v2_views.dart:9683 | BuyV2OrderItemsView | onTap | unclassified |
| SRC-0369 | buy_v2_views.dart:9727 | BuyV2OrderItemsView | onTap | unclassified |
| SRC-0370 | buy_v2_views.dart:9845 | _OrdersAvailabilityState | onPressed | unclassified |
| SRC-0371 | buy_v2_views.dart:9915 | _OrdersContinuationRail | onTap | unclassified |
| SRC-0372 | buy_v2_views.dart:9924 | _OrdersContinuationRail | onTap | unclassified |
| SRC-0373 | buy_v2_views.dart:9933 | _OrdersContinuationRail | onTap | unclassified |
| SRC-0374 | buy_v2_views.dart:10066 | _showBuyV2OrderDeliveryContextSheet | onPressed | unclassified |
| SRC-0375 | buy_v2_views.dart:10177 | _showBuyV2OrderDeliveryContextSheet | onTap | unclassified |
| SRC-0376 | buy_v2_views.dart:10189 | _showBuyV2OrderDeliveryContextSheet | onTap | unclassified |
| SRC-0377 | buy_v2_views.dart:10251 | _DeliveryExceptionCard | onPressed | unclassified |
| SRC-0378 | buy_v2_views.dart:10329 | _DeliveryExceptionCard | onSelected | unclassified |
| SRC-0379 | buy_v2_views.dart:10344 | _DeliveryExceptionCard | onPressed | unclassified |
| SRC-0380 | buy_v2_views.dart:10358 | _DeliveryExceptionCard | onPressed | unclassified |
| SRC-0381 | buy_v2_views.dart:10493 | _BalancePaymentCard | onPressed | unclassified |
| SRC-0382 | buy_v2_views.dart:10643 | _BuyV2LiveDeliveryPanelState | onPressed | unclassified |
| SRC-0383 | buy_v2_views.dart:10746 | _BuyV2LiveDeliveryPanelState | onPressed | unclassified |
| SRC-0384 | buy_v2_views.dart:10995 | _BuyV2CollectionOrderViewState | onTap | unclassified |
| SRC-0385 | buy_v2_views.dart:11117 | _BuyV2CollectionOrderViewState | onPressed | unclassified |
| SRC-0386 | buy_v2_views.dart:11138 | _BuyV2CollectionOrderViewState | onPressed | unclassified |
| SRC-0387 | buy_v2_views.dart:11232 | _BuyV2CollectionOrderViewState | onPressed | unclassified |
| SRC-0388 | buy_v2_views.dart:11294 | BuyV2TrackingView | onTap | unclassified |
| SRC-0389 | buy_v2_views.dart:11312 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0390 | buy_v2_views.dart:11425 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0391 | buy_v2_views.dart:11781 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0392 | buy_v2_views.dart:11787 | BuyV2TrackingView | onChanged | unclassified |
| SRC-0393 | buy_v2_views.dart:11805 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0394 | buy_v2_views.dart:11815 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0395 | buy_v2_views.dart:11825 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0396 | buy_v2_views.dart:11843 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0397 | buy_v2_views.dart:11863 | BuyV2TrackingView | onPressed | unclassified |
| SRC-0398 | buy_v2_views.dart:11905 | BuyV2TrackingView | onTap | unclassified |
| SRC-0399 | buy_v2_views.dart:12086 | _BuyV2OrderResolutionSheetState | onPressed | unclassified |
| SRC-0400 | buy_v2_views.dart:12097 | _BuyV2OrderResolutionSheetState | onPressed | unclassified |
| SRC-0401 | buy_v2_views.dart:12108 | _BuyV2OrderResolutionSheetState | onTap | unclassified |
| SRC-0402 | buy_v2_views.dart:12147 | _BuyV2OrderResolutionSheetState | onChanged | unclassified |
| SRC-0403 | buy_v2_views.dart:12178 | _BuyV2OrderResolutionSheetState | onPressed | unclassified |
| SRC-0404 | buy_v2_views.dart:12222 | _BuyV2OrderResolutionSheetState | onChanged | unclassified |
| SRC-0405 | buy_v2_views.dart:12229 | _BuyV2OrderResolutionSheetState | onPressed | unclassified |
| SRC-0406 | buy_v2_views.dart:12259 | _BuyV2OrderResolutionSheetState | onPressed | unclassified |
| SRC-0407 | buy_v2_views.dart:12315 | _OrderResolutionItemTile | onChanged | unclassified |
| SRC-0408 | buy_v2_views.dart:12367 | _OrderResolutionItemTile | onPressed | unclassified |
| SRC-0409 | buy_v2_views.dart:12387 | _OrderResolutionItemTile | onPressed | unclassified |
| SRC-0410 | buy_v2_views.dart:12426 | _OrderResolutionOptionTile | onTap | unclassified |
| SRC-0411 | buy_v2_views.dart:12535 | _BuyV2AssistViewState | onTap | unclassified |
| SRC-0412 | buy_v2_views.dart:12633 | _BuyV2AssistViewState | onTap | unclassified |
| SRC-0413 | buy_v2_views.dart:12782 | _BuyV2AssistViewState | onTap | unclassified |
| SRC-0414 | buy_v2_views.dart:12844 | _BuyV2AssistViewState | onChanged | unclassified |
| SRC-0415 | buy_v2_views.dart:12845 | _BuyV2AssistViewState | onSubmitted | unclassified |
| SRC-0416 | buy_v2_views.dart:12855 | _BuyV2AssistViewState | onPressed | unclassified |
| SRC-0417 | buy_v2_views.dart:12886 | _BuyV2AssistViewState | onTap | unclassified |
| SRC-0418 | buy_v2_views.dart:12938 | BuyV2AccountView | onTap | unclassified |
| SRC-0419 | buy_v2_views.dart:13028 | BuyV2AccountView | onTap | unclassified |
| SRC-0420 | buy_v2_views.dart:13036 | BuyV2AccountView | onTap | unclassified |
| SRC-0421 | buy_v2_views.dart:13045 | BuyV2AccountView | onTap | unclassified |
| SRC-0422 | buy_v2_views.dart:13054 | BuyV2AccountView | onTap | unclassified |
| SRC-0423 | buy_v2_views.dart:13061 | BuyV2AccountView | onTap | unclassified |
| SRC-0424 | buy_v2_views.dart:13072 | BuyV2AccountView | onTap | unclassified |
| SRC-0425 | buy_v2_views.dart:13116 | _AccountActionRow | onTap | unclassified |
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
| SRC-0443 | buy_v2_views.dart:13849 | _BuyV2FilterToolAction | onTap | unclassified |
| SRC-0444 | buy_v2_views.dart:13858 | _BuyV2FilterToolAction | onTap | unclassified |
| SRC-0445 | buy_v2_views.dart:13922 | _BuyV2FilterOption | onTap | unclassified |
| SRC-0446 | buy_v2_views.dart:13935 | _BuyV2FilterOption | onTap | unclassified |
| SRC-0447 | buy_v2_views.dart:14062 | showBuyV2PaymentSheet | onPressed | unclassified |
| SRC-0448 | buy_v2_views.dart:14094 | showBuyV2PaymentSheet | onTap | unclassified |
| SRC-0449 | buy_v2_views.dart:14139 | _BuyV2PaymentChoice | onTap | unclassified |
| SRC-0450 | buy_v2_views.dart:14153 | _BuyV2PaymentChoice | onTap | unclassified |
| SRC-0451 | buy_v2_views.dart:14288 | showBuyV2PrescriptionSheet | onPressed | unclassified |
| SRC-0452 | buy_v2_views.dart:14345 | showBuyV2PrescriptionSheet | onTap | unclassified |
| SRC-0453 | buy_v2_views.dart:14355 | showBuyV2PrescriptionSheet | onTap | unclassified |
| SRC-0454 | buy_v2_views.dart:14362 | showBuyV2PrescriptionSheet | onTap | unclassified |
| SRC-0455 | buy_v2_views.dart:14481 | showBuyV2AddressSheet | onPressed | unclassified |
| SRC-0456 | buy_v2_views.dart:14530 | showBuyV2AddressSheet | onTap | unclassified |
| SRC-0457 | buy_v2_views.dart:14549 | showBuyV2AddressSheet | onPressed | unclassified |
| SRC-0458 | buy_v2_views.dart:14557 | showBuyV2AddressSheet | onPressed | unclassified |
| SRC-0459 | buy_v2_views.dart:14577 | showBuyV2AddressSheet | onPressed | unclassified |
| SRC-0460 | buy_v2_views.dart:14589 | showBuyV2AddressSheet | onPressed | unclassified |
| SRC-0461 | buy_v2_views.dart:14653 | _BuyV2AddressChoice | onTap | unclassified |
| SRC-0462 | buy_v2_views.dart:14657 | _BuyV2AddressChoice | onTap | unclassified |
| SRC-0463 | buy_v2_views.dart:14764 | _BuyV2AddressChoice | onTap | unclassified |
| SRC-0464 | buy_v2_views.dart:14769 | _BuyV2AddressChoice | onSelected | unclassified |
| SRC-0465 | buy_v2_views.dart:15010 | _BuyV2AddressRequestFormState | onTap | unclassified |
| SRC-0466 | buy_v2_views.dart:15017 | _BuyV2AddressRequestFormState | onTap | unclassified |
| SRC-0467 | buy_v2_views.dart:15027 | _BuyV2AddressRequestFormState | onPressed | unclassified |
| SRC-0468 | buy_v2_views.dart:15278 | _BuyV2AddAddressFormState | onSelected | unclassified |
| SRC-0469 | buy_v2_views.dart:15346 | _BuyV2AddAddressFormState | onPressed | unclassified |
| SRC-0470 | buy_v2_views.dart:15393 | _AddressFormHeader | onPressed | unclassified |
| SRC-0471 | buy_v2_views.dart:15426 | _ReturnAffordance | onTap | unclassified |
| SRC-0472 | buy_v2_views.dart:15468 | _ReturnAffordance | onTap | unclassified |
| SRC-0473 | buy_v2_views.dart:15650 | _DecisionActionRow | onTap | unclassified |
| SRC-0474 | buy_v2_views.dart:15656 | _DecisionActionRow | onTap | unclassified |
| SRC-0475 | buy_v2_views.dart:15780 | _ProductOwnedActionPanel | onTap | unclassified |
| SRC-0476 | buy_v2_views.dart:15788 | _ProductOwnedActionPanel | onPressed | unclassified |
| SRC-0477 | buy_v2_views.dart:15982 | _ProductPurchaseActionRow | onTap | unclassified |
| SRC-0478 | buy_v2_views.dart:15986 | _ProductPurchaseActionRow | onPressed | unclassified |
| SRC-0479 | buy_v2_views.dart:16141 | _QuantityEditorState | onChanged | unclassified |
| SRC-0480 | buy_v2_views.dart:16144 | _QuantityEditorState | onSubmitted | unclassified |
| SRC-0481 | buy_v2_views.dart:16149 | _QuantityEditorState | onPressed | unclassified |
| SRC-0482 | buy_v2_views.dart:16152 | _QuantityEditorState | onPressed | unclassified |
| SRC-0483 | buy_v2_views.dart:16214 | _CompactProductStepper | onPressed | unclassified |
| SRC-0484 | buy_v2_views.dart:16225 | _CompactProductStepper | onPressed | unclassified |
| SRC-0485 | buy_v2_views.dart:16253 | _CompactProductStepper | onPressed | unclassified |
| SRC-0486 | buy_v2_views.dart:16360 | _CartScopeBar | onTap | unclassified |
| SRC-0487 | buy_v2_views.dart:16594 | _CartBenefitPanel | onTap | unclassified |
| SRC-0488 | buy_v2_views.dart:16614 | _CartBenefitPanel | onTap | unclassified |
| SRC-0489 | buy_v2_views.dart:16677 | _CartBenefitEntry | onTap | unclassified |
| SRC-0490 | buy_v2_views.dart:16916 | _CartBenefitsPageState | onPressed | unclassified |
| SRC-0491 | buy_v2_views.dart:16950 | _CartBenefitsPageState | onChanged | unclassified |
| SRC-0492 | buy_v2_views.dart:16957 | _CartBenefitsPageState | onChanged | unclassified |
| SRC-0493 | buy_v2_views.dart:17065 | _CartBenefitsPageState | onPressed | unclassified |
| SRC-0494 | buy_v2_views.dart:17139 | _CartBenefitDestinationSelector | onTap | unclassified |
| SRC-0495 | buy_v2_views.dart:17235 | _CartBenefitKindSelector | onTap | unclassified |
| SRC-0496 | buy_v2_views.dart:17245 | _CartBenefitKindSelector | onTap | unclassified |
| SRC-0497 | buy_v2_views.dart:17275 | _CartBenefitKindButton | onTap | unclassified |
| SRC-0498 | buy_v2_views.dart:17350 | _CartBenefitEligibilityState | onPressed | unclassified |
| SRC-0499 | buy_v2_views.dart:17571 | _CartBenefitCard | onTap | unclassified |
| SRC-0500 | buy_v2_views.dart:17576 | _CartBenefitCard | onTap | unclassified |
| SRC-0501 | buy_v2_views.dart:17838 | _CartRecommendationCard | onTap | unclassified |
| SRC-0502 | buy_v2_views.dart:17933 | _CartRecommendationCard | onPressed | unclassified |
| SRC-0503 | buy_v2_views.dart:18047 | _CartDeliveryInstructionCard | onTap | unclassified |
| SRC-0504 | buy_v2_views.dart:18164 | _CartTipCard | onSelected | unclassified |
| SRC-0505 | buy_v2_views.dart:18175 | _CartTipCard | onSelected | unclassified |
| SRC-0506 | buy_v2_views.dart:18392 | _CartLine | onTap | unclassified |
| SRC-0507 | buy_v2_views.dart:18398 | _CartLine | onTap | unclassified |
| SRC-0508 | buy_v2_views.dart:18571 | _CartLine | onPressed | unclassified |
| SRC-0509 | buy_v2_views.dart:18583 | _CartLine | onPressed | unclassified |
| SRC-0510 | buy_v2_views.dart:18603 | _CartLine | onPressed | unclassified |
| SRC-0511 | buy_v2_views.dart:18727 | _SavedAddressReminder | onPressed | unclassified |
| SRC-0512 | buy_v2_views.dart:18927 | _CheckoutCard | onTap | unclassified |
| SRC-0513 | buy_v2_views.dart:19022 | _OrderCard | onPressed | unclassified |
| SRC-0514 | buy_v2_views.dart:19044 | _OrderCard | onTap | unclassified |
| SRC-0515 | buy_v2_views.dart:19173 | _OrderCard | onPressed | unclassified |
| SRC-0516 | buy_v2_views.dart:19190 | _OrderCard | onPressed | unclassified |
| SRC-0517 | buy_v2_views.dart:19374 | _TrackingAction | onTap | unclassified |
| SRC-0518 | buy_v2_views.dart:19428 | _OrderDeliveryContinuation | onTap | unclassified |
| SRC-0519 | buy_v2_views.dart:19440 | _OrderDeliveryContinuation | onTap | unclassified |
| SRC-0520 | buy_v2_views.dart:19702 | _AssistIntentState | onTap | unclassified |
| SRC-0521 | buy_v2_views.dart:19781 | _AssistChannelState | onTap | unclassified |
| SRC-0522 | buy_v2_views.dart:19845 | _PrescriptionChoice | onTap | unclassified |
| SRC-0523 | buy_v2_views.dart:19856 | _PrescriptionChoice | onTap | unclassified |
| SRC-0524 | buy_v2_views.dart:19922 | _AddPrescriptionChoice | onTap | unclassified |
| SRC-0525 | buy_v2_views.dart:19933 | _AddPrescriptionChoice | onTap | unclassified |
| SRC-0526 | buy_v2_views.dart:20017 | _ShareChoiceState | onTap | unclassified |
| SRC-0527 | buy_v2_views.dart:20023 | _ShareChoiceState | onTap | unclassified |

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
| SUPSRC-0001 | buy_v2_catalogue.dart:276 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0002 | buy_v2_catalogue.dart:1141 | onArea | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0003 | buy_v2_catalogue.dart:1144 | onPrevious | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0004 | buy_v2_catalogue.dart:1147 | onNext | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0005 | buy_v2_catalogue.dart:1150 | onRefresh | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0006 | buy_v2_catalogue.dart:1172 | onAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0007 | buy_v2_catalogue.dart:1179 | onAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0008 | buy_v2_catalogue.dart:1186 | onAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0009 | buy_v2_catalogue.dart:1247 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0010 | buy_v2_catalogue.dart:1267 | onAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0011 | buy_v2_catalogue.dart:1806 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0012 | buy_v2_catalogue.dart:1808 | onSaved | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0013 | buy_v2_catalogue.dart:1832 | onOpenStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0014 | buy_v2_catalogue.dart:1843 | onShowAll | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0015 | buy_v2_catalogue.dart:2587 | onPrevious | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0016 | buy_v2_catalogue.dart:2590 | onNext | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0017 | buy_v2_catalogue.dart:2591 | onRefresh | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0018 | buy_v2_catalogue.dart:2599 | onAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0019 | buy_v2_catalogue.dart:2694 | onOpenStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0020 | buy_v2_catalogue.dart:3077 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0021 | buy_v2_catalogue.dart:3470 | onFocus | framework-event candidate; unclassified |
| SUPSRC-0022 | buy_v2_catalogue.dart:3471 | onSetText | framework-event candidate; unclassified |
| SUPSRC-0023 | buy_v2_catalogue.dart:3557 | onClear | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0024 | buy_v2_catalogue.dart:3801 | onClear | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0025 | buy_v2_catalogue.dart:3842 | onClear | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0026 | buy_v2_catalogue.dart:3895 | onClear | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0027 | buy_v2_catalogue.dart:4101 | onHighlightChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0028 | buy_v2_catalogue.dart:4221 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0029 | buy_v2_catalogue.dart:4234 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0030 | buy_v2_catalogue.dart:4331 | onOpenSavedProducts | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0031 | buy_v2_catalogue.dart:4336 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0032 | buy_v2_catalogue.dart:4337 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0033 | buy_v2_catalogue.dart:4345 | onOpenRecentlyViewed | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0034 | buy_v2_catalogue.dart:4350 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0035 | buy_v2_catalogue.dart:4351 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0036 | buy_v2_catalogue.dart:4914 | onTapOutside | framework-event candidate; unclassified |
| SUPSRC-0037 | buy_v2_catalogue.dart:5241 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0038 | buy_v2_catalogue.dart:5242 | onSeeProducts | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0039 | buy_v2_catalogue.dart:5244 | onAddToCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0040 | buy_v2_catalogue.dart:5285 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0041 | buy_v2_catalogue.dart:5286 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0042 | buy_v2_catalogue.dart:5327 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0043 | buy_v2_catalogue.dart:5328 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0044 | buy_v2_catalogue.dart:5337 | onClear | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0045 | buy_v2_catalogue.dart:5452 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0046 | buy_v2_catalogue.dart:5453 | onOpenCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0047 | buy_v2_catalogue.dart:5634 | onOrderForCollection | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0048 | buy_v2_catalogue.dart:5641 | onAskStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0049 | buy_v2_catalogue.dart:5653 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0050 | buy_v2_catalogue.dart:5669 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0051 | buy_v2_catalogue.dart:5738 | onAskStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0052 | buy_v2_catalogue.dart:5744 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0053 | buy_v2_catalogue.dart:5745 | onStoreChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0054 | buy_v2_catalogue.dart:5746 | onOpenStoreCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0055 | buy_v2_catalogue.dart:5748 | onOpenCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0056 | buy_v2_catalogue.dart:5773 | onOpenCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0057 | buy_v2_catalogue.dart:5812 | onAskStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0058 | buy_v2_catalogue.dart:5813 | onStoreChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0059 | buy_v2_catalogue.dart:5814 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0060 | buy_v2_catalogue.dart:5815 | onOpenCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0061 | buy_v2_catalogue.dart:5816 | onOpenStoreCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0062 | buy_v2_catalogue.dart:6595 | onAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0063 | buy_v2_catalogue.dart:6607 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0064 | buy_v2_catalogue.dart:6731 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0065 | buy_v2_catalogue.dart:6799 | onTapOutside | framework-event candidate; unclassified |
| SUPSRC-0066 | buy_v2_catalogue.dart:6881 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0067 | buy_v2_catalogue.dart:6883 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0068 | buy_v2_catalogue.dart:6949 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0069 | buy_v2_catalogue.dart:6962 | onOpenCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0070 | buy_v2_catalogue.dart:7260 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0071 | buy_v2_catalogue.dart:7304 | onOpen | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0072 | buy_v2_catalogue.dart:7305 | onRemove | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0073 | buy_v2_catalogue.dart:7375 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0074 | buy_v2_catalogue.dart:7424 | onOpen | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0075 | buy_v2_catalogue.dart:7425 | onAdd | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0076 | buy_v2_catalogue.dart:7809 | onAddToCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0077 | buy_v2_catalogue.dart:7844 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0078 | buy_v2_catalogue.dart:8520 | onKeep | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0079 | buy_v2_catalogue.dart:8521 | onClear | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0080 | buy_v2_catalogue.dart:8752 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0081 | buy_v2_catalogue.dart:8792 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0082 | buy_v2_catalogue.dart:9193 | onNotification | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0083 | buy_v2_catalogue.dart:9215 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0084 | buy_v2_catalogue.dart:10043 | onHighlightChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0085 | buy_v2_catalogue.dart:10420 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0086 | buy_v2_catalogue.dart:10422 | onDecrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0087 | buy_v2_catalogue.dart:10423 | onIncrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0088 | buy_v2_catalogue.dart:10969 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0089 | buy_v2_catalogue.dart:10975 | onDecrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0090 | buy_v2_catalogue.dart:10983 | onIncrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0091 | buy_v2_design.dart:228 | onNotification | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0092 | buy_v2_design.dart:233 | onNotification | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0093 | buy_v2_design.dart:354 | onNotification | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0094 | buy_v2_design.dart:359 | onNotification | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0095 | buy_v2_design.dart:1591 | onPointerDown | framework-event candidate; unclassified |
| SUPSRC-0096 | buy_v2_design.dart:1594 | onPointerUp | framework-event candidate; unclassified |
| SUPSRC-0097 | buy_v2_design.dart:1595 | onPointerCancel | framework-event candidate; unclassified |
| SUPSRC-0098 | buy_v2_scanner.dart:150 | onDetect | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0099 | buy_v2_scanner.dart:733 | onDetect | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0100 | buy_v2_scanner.dart:757 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0101 | buy_v2_scanner.dart:758 | onTorch | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0102 | buy_v2_scanner.dart:759 | onCamera | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0103 | buy_v2_scanner.dart:760 | onScanNow | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0104 | buy_v2_scanner.dart:761 | onEnterCode | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0105 | buy_v2_scanner.dart:788 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0106 | buy_v2_scanner.dart:789 | onTorch | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0107 | buy_v2_scanner.dart:790 | onCamera | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0108 | buy_v2_scanner.dart:791 | onScanNow | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0109 | buy_v2_scanner.dart:792 | onEnterCode | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0110 | buy_v2_scanner.dart:848 | onScanNow | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0111 | buy_v2_scanner.dart:849 | onEnterCode | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0112 | buy_v2_scanner.dart:1001 | onScanNow | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0113 | buy_v2_scanner.dart:1002 | onEnterCode | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0114 | buy_v2_screen.dart:966 | onOpenRoute | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0115 | buy_v2_screen.dart:992 | onReturn | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0116 | buy_v2_screen.dart:1010 | onPopInvokedWithResult | framework-event candidate; unclassified |
| SUPSRC-0117 | buy_v2_screen.dart:1071 | onOpenChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0118 | buy_v2_screen.dart:1073 | onLocation | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0119 | buy_v2_screen.dart:1076 | onAccount | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0120 | buy_v2_screen.dart:1138 | onOpenStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0121 | buy_v2_screen.dart:1153 | onParkingChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0122 | buy_v2_screen.dart:1161 | onPositionChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0123 | buy_v2_screen.dart:1495 | onPointerDown | framework-event candidate; unclassified |
| SUPSRC-0124 | buy_v2_screen.dart:1499 | onPointerUp | framework-event candidate; unclassified |
| SUPSRC-0125 | buy_v2_screen.dart:1500 | onPointerCancel | framework-event candidate; unclassified |
| SUPSRC-0126 | buy_v2_screen.dart:1584 | onMinimizedChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0127 | buy_v2_screen.dart:1586 | onHiddenChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0128 | buy_v2_screen.dart:1596 | onSoundChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0129 | buy_v2_screen.dart:1598 | onKeepOnScreen | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0130 | buy_v2_screen.dart:1606 | onOpen | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0131 | buy_v2_screen.dart:1669 | onPositionChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0132 | buy_v2_screen.dart:1754 | onOpenMool | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0133 | buy_v2_screen.dart:1755 | onOpenAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0134 | buy_v2_screen.dart:1756 | onOpenChat | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0135 | buy_v2_screen.dart:1758 | onPreviousLocalAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0136 | buy_v2_screen.dart:1759 | onNextLocalAction | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0137 | buy_v2_screen.dart:2080 | onAskStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0138 | buy_v2_screen.dart:2081 | onStoreChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0139 | buy_v2_screen.dart:2082 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0140 | buy_v2_screen.dart:2083 | onOpenStoreCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0141 | buy_v2_screen.dart:2086 | onOpenCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0142 | buy_v2_screen.dart:2157 | onReturn | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0143 | buy_v2_screen.dart:2178 | onPopInvokedWithResult | framework-event candidate; unclassified |
| SUPSRC-0144 | buy_v2_screen.dart:2222 | onProductReturn | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0145 | buy_v2_screen.dart:2243 | onReturn | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0146 | buy_v2_screen.dart:2247 | onAskSeller | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0147 | buy_v2_screen.dart:2249 | onVisitComparisonProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0148 | buy_v2_screen.dart:2259 | onOpenPartnerCatalogue | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0149 | buy_v2_screen.dart:2275 | onOpenCart | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0150 | buy_v2_screen.dart:2408 | onPopInvokedWithResult | framework-event candidate; unclassified |
| SUPSRC-0151 | buy_v2_screen.dart:2422 | onReturn | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0152 | buy_v2_screen.dart:2463 | onReturn | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0153 | buy_v2_screen.dart:2489 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0154 | buy_v2_screen.dart:2490 | onReturn | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0155 | buy_v2_screen.dart:2507 | onOpenOrderHelp | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0156 | buy_v2_screen.dart:2522 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0157 | buy_v2_screen.dart:2525 | onOpenStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0158 | buy_v2_screen.dart:2531 | onAskSeller | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0159 | buy_v2_screen.dart:2532 | onVisitComparisonProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0160 | buy_v2_screen.dart:2535 | onOpenPartnerCatalogue | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0161 | buy_v2_screen.dart:2541 | onBrowseStore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0162 | buy_v2_screen.dart:2544 | onBrowseMore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0163 | buy_v2_screen.dart:2569 | onRestoreDeliveryStatus | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0164 | buy_v2_screen.dart:2571 | onOpenOrderHelp | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0165 | buy_v2_screen.dart:2579 | onRestoreDeliveryStatus | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0166 | buy_v2_screen.dart:2581 | onOpenOrderHelp | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0167 | buy_v2_screen.dart:2593 | onOpenOrderHelp | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0168 | buy_v2_screen.dart:2886 | onEnd | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0169 | buy_v2_screen.dart:2943 | onEnd | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0170 | buy_v2_shop_chat.dart:624 | onBack | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0171 | buy_v2_shop_chat.dart:626 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0172 | buy_v2_shop_chat.dart:627 | onOpenAll | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0173 | buy_v2_shop_chat.dart:634 | onBack | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0174 | buy_v2_shop_chat.dart:635 | onOpenInfo | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0175 | buy_v2_shop_chat.dart:636 | onDispatch | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0176 | buy_v2_shop_chat.dart:637 | onOpenContext | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0177 | buy_v2_shop_chat.dart:644 | onBack | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0178 | buy_v2_shop_chat.dart:645 | onDispatch | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0179 | buy_v2_shop_chat.dart:646 | onOpenContext | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0180 | buy_v2_shop_chat.dart:679 | onBack | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0181 | buy_v2_shop_chat.dart:680 | onOpenAll | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0182 | buy_v2_shop_chat.dart:688 | onClear | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0183 | buy_v2_shop_chat.dart:724 | onClearSearch | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0184 | buy_v2_shop_chat.dart:728 | onShowAll | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0185 | buy_v2_shop_chat.dart:732 | onChooseConversation | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0186 | buy_v2_shop_chat.dart:733 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0187 | buy_v2_shop_chat.dart:734 | onOpenAll | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0188 | buy_v2_shop_chat.dart:1712 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0189 | buy_v2_shop_chat.dart:1922 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0190 | buy_v2_shop_chat.dart:1923 | onOpenAll | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0191 | buy_v2_shop_chat.dart:2020 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0192 | buy_v2_shop_chat.dart:2202 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0193 | buy_v2_shop_chat.dart:2203 | onReply | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0194 | buy_v2_shop_chat.dart:2210 | onReact | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0195 | buy_v2_shop_chat.dart:2217 | onCopy | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0196 | buy_v2_shop_chat.dart:2218 | onForward | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0197 | buy_v2_shop_chat.dart:2230 | onBack | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0198 | buy_v2_shop_chat.dart:2231 | onOpenInfo | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0199 | buy_v2_shop_chat.dart:2232 | onVoiceCall | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0200 | buy_v2_shop_chat.dart:2237 | onVideoCall | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0201 | buy_v2_shop_chat.dart:2242 | onMore | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0202 | buy_v2_shop_chat.dart:2258 | onInfo | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0203 | buy_v2_shop_chat.dart:2262 | onSearch | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0204 | buy_v2_shop_chat.dart:2267 | onNotifications | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0205 | buy_v2_shop_chat.dart:2272 | onSafety | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0206 | buy_v2_shop_chat.dart:2283 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0207 | buy_v2_shop_chat.dart:2327 | onForward | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0208 | buy_v2_shop_chat.dart:2398 | onTapField | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0209 | buy_v2_shop_chat.dart:2405 | onCancelReply | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0210 | buy_v2_shop_chat.dart:2406 | onToggleEmoji | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0211 | buy_v2_shop_chat.dart:2419 | onEmoji | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0212 | buy_v2_shop_chat.dart:2427 | onAttachment | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0213 | buy_v2_shop_chat.dart:2442 | onCamera | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0214 | buy_v2_shop_chat.dart:2447 | onSend | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0215 | buy_v2_shop_chat.dart:2448 | onVoice | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0216 | buy_v2_shop_chat.dart:3397 | onClose | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0217 | buy_v2_shop_chat.dart:3523 | onSend | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0218 | buy_v2_shop_chat.dart:3524 | onVoice | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0219 | buy_v2_views.dart:831 | onAdd | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0220 | buy_v2_views.dart:832 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0221 | buy_v2_views.dart:837 | onDecrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0222 | buy_v2_views.dart:838 | onIncrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0223 | buy_v2_views.dart:905 | onOpenWorkspace | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0224 | buy_v2_views.dart:917 | onOpenPartnerCatalogue | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0225 | buy_v2_views.dart:1199 | onReview | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0226 | buy_v2_views.dart:1201 | onReport | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0227 | buy_v2_views.dart:1213 | onAskSeller | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0228 | buy_v2_views.dart:1214 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0229 | buy_v2_views.dart:1234 | onAdd | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0230 | buy_v2_views.dart:1235 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0231 | buy_v2_views.dart:1236 | onDecrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0232 | buy_v2_views.dart:1237 | onIncrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0233 | buy_v2_views.dart:1238 | onRetryOffer | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0234 | buy_v2_views.dart:1240 | onOpenWorkspace | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0235 | buy_v2_views.dart:1457 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0236 | buy_v2_views.dart:1606 | onVisitProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0237 | buy_v2_views.dart:1909 | onOpenProduct | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0238 | buy_v2_views.dart:2385 | onRetry | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0239 | buy_v2_views.dart:2874 | onAdd | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0240 | buy_v2_views.dart:2875 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0241 | buy_v2_views.dart:2876 | onDecrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0242 | buy_v2_views.dart:2877 | onIncrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0243 | buy_v2_views.dart:3529 | onInteractionEnd | B-008 / MEDIA-ROUND75-02; automatic reset at scale <=1.01, same zoom journey; no additional device pass |
| SUPSRC-0244 | buy_v2_views.dart:3679 | onPageChanged | B-008 / MEDIA-ROUND75-01 and 08; gallery paging and active-media selection; no additional device pass |
| SUPSRC-0245 | buy_v2_views.dart:4824 | onPopInvokedWithResult | Eligible review descendant B003 round91; device unverified |
| SUPSRC-0246 | buy_v2_views.dart:4920 | onFocus | Eligible review descendant B003 round91; device unverified |
| SUPSRC-0247 | buy_v2_views.dart:4921 | onSetText | Eligible review descendant B003 round91; device unverified |
| SUPSRC-0248 | buy_v2_views.dart:6166 | onDeleted | Alias of SUP-GST-DELETE-01 round94; same action, not an extra journey |
| SUPSRC-0249 | buy_v2_views.dart:7652 | onSelect | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0250 | buy_v2_views.dart:7653 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0251 | buy_v2_views.dart:8832 | onViewInvoice | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0252 | buy_v2_views.dart:11095 | onDetected | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0253 | buy_v2_views.dart:11282 | onOpenOrderHelp | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0254 | buy_v2_views.dart:11847 | onOpenSupport | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0255 | buy_v2_views.dart:11932 | onOpenSupport | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0256 | buy_v2_views.dart:13020 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0257 | buy_v2_views.dart:14531 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0258 | buy_v2_views.dart:14536 | onDelete | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0259 | buy_v2_views.dart:14875 | onSubmit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0260 | buy_v2_views.dart:15170 | onFocusChange | framework-event candidate; unclassified |
| SUPSRC-0261 | buy_v2_views.dart:15766 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0262 | buy_v2_views.dart:15767 | onDecrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0263 | buy_v2_views.dart:15768 | onIncrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0264 | buy_v2_views.dart:15970 | onEdit | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0265 | buy_v2_views.dart:15972 | onDecrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0266 | buy_v2_views.dart:15973 | onIncrease | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0267 | buy_v2_views.dart:17024 | onSelect | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0268 | buy_v2_views.dart:17029 | onRemove | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0269 | buy_v2_views.dart:19701 | onHighlightChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0270 | buy_v2_views.dart:19780 | onHighlightChanged | custom/forwarded callback candidate; reconcile parent before counting |
| SUPSRC-0271 | buy_v2_views.dart:20024 | onHighlightChanged | custom/forwarded callback candidate; reconcile parent before counting |

## Round 97 - media callback reconciliation

Source-only inspection of buy_v2_views.dart lines 3461-3705 binds SRC-0293 and SUPSRC-0243/0244 to the existing eight B-008 media descendants. Zoom allows scale 1 to 2.5, enables panning only above 1.01, exposes Reset while zoomed and honors disabled animations during reset. Gallery paging is enabled only with multiple media and passes active-page state to the media builder. These are source behaviors, not device-qualified results. Actual supplier image/video assets remain absent; no illustration-based pass substitutes for supplier decoding, fit, paging or playback. No new defect, device capture or distinct journey is added. Original callback inventory now has 143 classified and 384 unclassified references; supplemental references are aliases/conditional controls, not a unique-journey denominator.

## Round 98 - nonempty cart Browse more on Redmi

Captures 790-794 physically reviewed. Empty Scheduled Shop basket was seeded with one wheat item INR279. Cart Browse more products returned to Scheduled catalogue with quantity and subtotal retained. Removed only that isolated item afterward; basket empty and saved count 1 retained. CART-ROUND98-01 qualifies the Shop nonempty Browse more control (SRC-0313); Wholesale/all-cart variants, Android Back and relaunch are not inferred. No new defect, order, message or implementation. Totals: 794 physical captures, 796 evidence rows, 491 action rows, 393 device passes, 17 distinct defects. Inventory remains incomplete.
