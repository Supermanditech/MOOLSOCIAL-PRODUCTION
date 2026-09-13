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
| SRC-0013 | buy_v2_catalogue.dart:1350 | _CataloguePageControls | onPressed | forwarded Previous; OFFERS-ROUND70-03 covers Offers; other parent contexts require own evidence |
| SRC-0014 | buy_v2_catalogue.dart:1356 | _CataloguePageControls | onPressed | forwarded Next; CAT-002, WHOLESALE-ROUND60-02, OFFERS-ROUND70-02; final boundaries not inferred |
| SRC-0015 | buy_v2_catalogue.dart:1362 | _CataloguePageControls | onPressed | forwarded Refresh; OFFERS-ROUND67-06 observation only; live revisions unqualified |
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
| SRC-0026 | buy_v2_catalogue.dart:1723 | showBuyV2CatalogueArea | onTap | Any area choice remains pending device check and retained context verification |
| SRC-0027 | buy_v2_catalogue.dart:1735 | showBuyV2CatalogueArea | onTap | seed area choice remains pending device check; not proof of national provider coverage |
| SRC-0028 | buy_v2_catalogue.dart:1943 | _CatalogueSaleTypeSelector | onHorizontalDragEnd | device_pass CAT-ROUND146-01 Shop and WHOLESALE-ROUND147-01 Wholesale/Bulk bidirectional gestures; threshold/accessibility/relaunch unqualified |
| SRC-0029 | buy_v2_catalogue.dart:2014 | _CatalogueSaleTypeSelector | onTap | sale-mode pointer selection; SAVED-ROUND16-01/04 and VARIANT-ROUND22-01 cover Shop Quick/Scheduled; Wholesale/Bulk and retained contexts need separate evidence |
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
| SRC-0040 | buy_v2_catalogue.dart:3152 | _CatalogueCategoryPickerButton | onTap | device_pass CATEGORY-ROUND106-01 Shop header picker opens; Wholesale separate |
| SRC-0041 | buy_v2_catalogue.dart:3215 | _CatalogueOwnedFeature | onTap | Shop/Wholesale return sale selector before this handler; feature filter handler belongs other destinations (Medicine/orders), not public Shop feature toggle |
| SRC-0042 | buy_v2_catalogue.dart:3433 | _CatalogueCategorySheetState | onPressed | device_pass CATEGORY-ROUND106-05 Shop picker X hides keyboard and restores catalogue; Wholesale separate |
| SRC-0043 | buy_v2_catalogue.dart:3469 | _CatalogueCategorySheetState | onTap | category search Semantics tap/focus; screen-reader activation unverified |
| SRC-0044 | buy_v2_catalogue.dart:3476 | _CatalogueCategorySheetState | onChanged | device_pass CATEGORY-ROUND106-01/03 unmatched zzzz and matched dairy; other queries/large-text states separate |
| SRC-0045 | buy_v2_catalogue.dart:3518 | _CatalogueCategorySheetState | onPressed | device_pass CATEGORY-ROUND106-04 suffix X clears dairy and restores choices |
| SRC-0046 | buy_v2_catalogue.dart:3628 | _CatalogueCategorySheetState | onTap | category choice closes sheet then awaits route completion before selection; Store category evidence does not automatically qualify Shop picker; pending reconciliation |
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
| SRC-0268 | buy_v2_views.dart:593 | BuyV2ProductView | onPressed | device_pass STORE-001 and COLLECTION-ROUND18-01 Visit store; supplier counterpart separate |
| SRC-0269 | buy_v2_views.dart:620 | BuyV2ProductView | onTap | product visible return control; Android Back evidence not automatically equivalent; compared-product return B-002 |
| SRC-0270 | buy_v2_views.dart:952 | BuyV2ProductView | onTap | Medicine-specific supplier decision row; outside public Shop/Wholesale |
| SRC-0271 | buy_v2_views.dart:1440 | _ProductQuickActions | onPressed | product-page Save action exact button needs reconciliation; catalogue bookmark pass not equivalent |
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
| SRC-0283 | buy_v2_views.dart:2250 | _WholesaleVerificationCard | onPressed | conditional Open business profile; exact public Wholesale entry/return and auth boundary unverified |
| SRC-0284 | buy_v2_views.dart:2489 | _WholesaleTradeDecisionPanelState | onPressed | Wholesale Check availability refresh facts/local signal; provider success and failure branches unverified |
| SRC-0285 | buy_v2_views.dart:2502 | _WholesaleTradeDecisionPanelState | onPressed | Wholesale unavailable Change product exact control unverified; Back not equivalent |
| SRC-0286 | buy_v2_views.dart:2751 | _WholesaleTradeSignalCard | onPressed | local insight Retry provider path unverified; no fixture claim of real local insight |
| SRC-0287 | buy_v2_views.dart:2851 | _WholesaleTradeActionDock | onPressed | Verify business unverified-business dock; profile/auth route boundary not yet device-qualified |
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
| SRC-0331 | buy_v2_views.dart:6706 | _CheckoutQuoteCard | onPressed | checkout quote Retry B-004; authoritative quote absent; exact Retry UI not qualified from Check delivery |
| SRC-0332 | buy_v2_views.dart:6857 | _CheckoutCommercialPaymentTerms | onPressed | commercial payment terms Retry provider dependency unverified |
| SRC-0333 | buy_v2_views.dart:6969 | _CommercialPaymentTermGroup | onChanged | commercial term radio selection requires authoritative terms; provider/fixture state absent, unverified |
| SRC-0334 | buy_v2_views.dart:7068 | BuyV2CheckoutView | onTap | visible checkout Back and busy notice; Android Back CHECKOUT-007/008/009 does not prove exact target or busy guard |
| SRC-0335 | buy_v2_views.dart:7154 | BuyV2CheckoutView | onPressed | primary action forwarding; CHECKOUT-003/005 next/review and CHECKOUT-006 delivery boundary; real submission excluded |
| SRC-0336 | buy_v2_views.dart:7490 | _CheckoutCollectionDetails | onTap | collection Store option selection; COLLECTION-ROUND18 entry not proof of multi-Store choice; conditional unverified |
| SRC-0337 | buy_v2_views.dart:7508 | _CheckoutCollectionDetails | onTap | collection review Store Change to address step; exact control unverified |
| SRC-0338 | buy_v2_views.dart:7565 | _CheckoutCollectionDetails | onTap | collection review Payment Change; exact control unverified |
| SRC-0339 | buy_v2_views.dart:7602 | _CheckoutAddressStage | onSelected | device_pass COLLECTION-ROUND18-06 switch Delivery; resolution-disabled state unverified |
| SRC-0340 | buy_v2_views.dart:7610 | _CheckoutAddressStage | onSelected | Collect at store chip distinct from Store entry COLLECTION-ROUND18-02; exact chip unverified |
| SRC-0341 | buy_v2_views.dart:7665 | _CheckoutAddressStage | onPressed | device_pass CHECKOUT-ROUND135-03 Add another address and empty form X944-945; populated draft/validation separate |
| SRC-0342 | buy_v2_views.dart:7698 | _CheckoutAddressChoice | onTap | address choice Semantics action; screen-reader unverified |
| SRC-0343 | buy_v2_views.dart:7711 | _CheckoutAddressChoice | onTap | checkout address pointer selection; selected Work observed but exact switch action requires reconciliation |
| SRC-0344 | buy_v2_views.dart:7748 | _CheckoutAddressChoice | onPressed | checkout address Edit exact button; address-sheet Edit not automatically equivalent |
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
| SRC-0390 | buy_v2_views.dart:11425 | BuyV2TrackingView | onPressed | Restore delivery status from tracking exact button unverified; bottom rail reopen TRACK-005 distinct |
| SRC-0391 | buy_v2_views.dart:11781 | BuyV2TrackingView | onPressed | tracking Retry order alerts provider/restore failure unverified |
| SRC-0392 | buy_v2_views.dart:11787 | BuyV2TrackingView | onChanged | tracking-screen alert switch exact target unverified; settings switch is distinct entry |
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
| SRC-0486 | buy_v2_views.dart:16360 | _CartScopeBar | onTap | QTY-ROUND33-03 All carts scope visibility; exact scope-chip switching remains pending |
| SRC-0487 | buy_v2_views.dart:16594 | _CartBenefitPanel | onTap | pending exact coupon benefit panel CTA; other coupon entry evidence must be reconciled |
| SRC-0488 | buy_v2_views.dart:16614 | _CartBenefitPanel | onTap | COUPON-003 Payment offers entry capture082; no actual payment qualification |
| SRC-0489 | buy_v2_views.dart:16677 | _CartBenefitEntry | onTap | benefit entry pointer forwarder to SRC0487/0488; no additional journey |
| SRC-0490 | buy_v2_views.dart:16916 | _CartBenefitsPageState | onPressed | pending exact Coupons toolbar Back; other returns not inferred |
| SRC-0491 | buy_v2_views.dart:16950 | _CartBenefitsPageState | onChanged | pending per-destination coupon selector; initial Wholesale/Shop entries are not every tab switch |
| SRC-0492 | buy_v2_views.dart:16957 | _CartBenefitsPageState | onChanged | COUPON-003 Payment offers kind switch; reverse Coupon tab exact check pending |
| SRC-0493 | buy_v2_views.dart:17065 | _CartBenefitsPageState | onPressed | pending exact benefit completion-to-cart CTA and retained selection |
| SRC-0494 | buy_v2_views.dart:17139 | _CartBenefitDestinationSelector | onTap | destination selector forwarder SRC0491; every eligible destination pending |
| SRC-0495 | buy_v2_views.dart:17235 | _CartBenefitKindSelector | onTap | pending explicit Coupon kind tab after Payment offers |
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
