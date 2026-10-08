# Cursor Buy baseline capture â€” 21 September 2026

## Store details Android bottom clearance

Founder-reported 22 September: Store details opened from the search info button
can be hidden by Android navigation. The filter repair did not cover this popup;
its scroll view retained only 12px bottom padding. Launch-supporting correction:
reuse the existing modal-inset resolver in the catalogue owner, preserving store
data, Ask/other-store callbacks, close and scrolling. No new model or route.
Acceptance: existing four store journeys with Android top/bottom insets, inspect
the details scroll owner's bottom clearance and its final scrolled content edge,
capture the actual Flutter sheet, and run scoped analysis. Redmi acceptance remains
pending a fresh candidate; installed r66.31 does not contain this repair.

Local verification complete: four existing connected store journeys passed,
including the new measured final-content bottom edge above the 48px Android
navigation exclusion at normal and 2x text. Scoped analysis reported no issues;
format verification passed. Normal and 2x bottom-position screenshots inspected.
Evidence: outputs/cursor-buy-ready-20260921/store-details-safe-r1.log and
store-details-safe-r1/store-details-safe-bottom-*.png. These are local Flutter
captures with Android insets, not physical Redmi acceptance.

## Store search: match Buy Home unboxed presentation

Founder-selected launch-supporting Buy presentation change, 22 September 2026.
Public customer opens Visit store and searches that store's catalogue. Reuse
the existing TextField, controller, query owner and navigation; change only its
decoration and typography to Buy Home's unboxed tokens. Exact runtime owner:
apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart; existing focused journey owner:
apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart.
Store ID filtering, clear/info/close actions, category/filter/Saved, query recovery
and home query isolation remain unchanged. No shared contract, backend, routing,
APK or policy change. Verify the existing four viewport/accessibility journeys,
scoped analysis and local rendered screenshots. Device remains old r66.31.

Completed locally: border and fill removed for every input state; Buy Home's
13px ink text, 12px muted hint, navy search icon and compact padding reused.
Focused analysis: no issues. Existing connected store journeys: all four passed
(360/390 normal, 320 at 2x text, 390 reduced motion), including store-scoped
query, category/filter/Saved, related-store navigation and preserved home query.
Evidence: outputs/cursor-buy-ready-20260921/store-unboxed-search-r1.log and
store-unboxed-search-r1/store-unboxed-search-*.png. Normal and 2x screenshots
inspected. Regression-memory gate passed with the existing historical archive
parameter after its default invocation could not locate retained REG3955 evidence.
No new APK or device acceptance is claimed.

## Founder Redmi recheck: filter action still clipped in installed r66.31

22 September00:39: captured the popup already open on Redmi without navigating
or changing its state. Screenshot and UI XML confirm the lower Show products
action is clipped at the Android navigation area. Installed package readback:
com.moolsocial.app.cursorreview,1.0.0-r66.31-cursorreview,code2026092101.
Same defect REG4642; appended device evidence rather than duplicating registration.
Evidence: outputs/cursor-buy-ready-20260921/redmi-filter-founder-20260922/;
open-popup.png,open-popup.xml,evidence-manifest.json. Screenshot inspected.

Implementation already exists in b69ce92d and current d2728ad8: bounded scrollable
options, pinned equal-width Reset/Show products row, Android bottom clearance,
compact heading/options and full enlarged-text labels. Relevant host checks passed
in buy-compact-final.log (4 profiles), with final screenshots inspected. No new
runtime edits or redundant test runs were needed for this identical old-build
reproduction. Explicit status: IMPLEMENTED LOCALLY, OPEN ON REDMI. Fresh APK
installation and physical replay remain required before closing REG4642. No new
APK was built or installed during this read-only device capture.


## Session reconciliation: remaining Delivery/Offers implementations completed locally

REG4634: global Delivery reads only active placed delivery records. Remove the
retained terminal-order fallback; keep Orders/history and existing active delivery
selection/tracking/navigation. Empty and Care-only sessions have no Delivery
control; multiple and new active deliveries show it; final completion/removal hides
it even after screen restoration. Existing model has no delivery cancellation enum:
withdrawn orders are covered through authoritative refresh; no cancellation state
or successful payment is fabricated. Review fixtures containing active orders still
correctly show Delivery; a seeded review profile is not an empty-account proof.
REG4635: replace dark brown/pink Offers promo palette with existing Buy white,
softBlue, softOrange, ink/navy/muted and line tokens. Preserve content, publication
identity, carousel position, CTA/product/cart/Back behavior. Local1x/2x captures
inspected in outputs/cursor-buy-ready-20260921/offers-brand-r1.

Request-by-request audit (latest founder instruction takes precedence):
- Independent Cursor worktree/full integrated baseline and durable memory: done.
- Public Visit store screen (not operator Store) and home-like store SKU layout: done.
- Store-only search/category/filter/Saved/SKU/navigation: implemented and tested.
- Store name placement, professional size/long-name wrap and charcoal colour: done.
- Recurring text-only store-name sheen, reduced motion and lifecycle pauses: done.
- Header Order/Collect marketing text and its animation: removed by later explicit
  founder instruction; do not re-add superseded copy or a screen video.
- Delivery/Collect at store choice for every resolved store, selected tick and
  existing validation/cart wiring: implemented; optional merchant opt-in removed.
- Delivery rail and Offers theme reports: implemented by this change.
- Redmi findings (filter CTA clipping, rice/price-label relevance): fixed locally.
- More stores below store and branch navigation/Back: restored and tested.
- Compact selection text across Shop/Wholesale/Offers/filters/categories: implemented;
  area/action minimum hit targets and enlarged text retained. Existing compact SKU
  grids remain intact; this is not a claim that every Buy pixel was re-approved.
- Fresh r66.31 APK/checksum/install/device audit: previously completed. Later fixes
  require a new candidate and device replay; installed r66.31 is not current source.
- Native baseline blocker and prior Saved geometry/test defects: fixed, evidence
  preserved. Historical pending sections below are chronological, not current backlog.
No additional forgotten frontend implementation was identified in the session audit.

Remaining qualification/dependencies, not silently closed: fresh Redmi build and
replay including motion/accessibility; founder review of latest visuals; production
pickup gateway/authenticated quote-payment-order completion; future Codex integration
and the previously recorded historical commit-subject handoff blocker. No backend,
provider, native, shared routing or release policy redesign is authorized by this
frontend reconciliation. No push, production release or live order/payment occurred.

Validation: new Delivery lifecycle regression1 pass (9861/cf8c14), existing
delivery/navigation14 pass (17786/4f2399), promotion4 pass (62554/f8b450), scoped
analysis4 files no issues (60265/5ab110). Final Delivery capture replay38243/52163f passed1. Empty-account and completed-history
PNGs in outputs/cursor-buy-ready-20260921/delivery-rail-capture-r2 show no Delivery
rail; completed-history image inspected. No products are seeded in this test profile;
the empty product notice is expected. SHA256 manifests accompany both image sets.
Owner admission required exactly one extra UI owner: transfer screen from recorded
old RV6 task to current primary and add that path to the existing exact owner list;
implementation gate passed32 owners (d6a3b6). No other policy rule or check relaxed.
Whole-screen formatter would have changed unrelated inherited formatting; restored
baseline formatting and retained only3 added/16 removed delivery-predicate lines.
A capture setup command used an incorrect relative working directory and made no
edits; corrected at worktree root. Original test pass remains valid, capture retried.


## Latest: Store repairs and compact Buy selection controls implemented locally

Founder added the compact-spacing ticket during Store repairs. REG4642/4643
repairs and REG4644 More stores wiring are implemented. REG4645 compact controls
cover individual Store filters/categories, Offers publisher/categories, area
selection, and shared Shop/Wholesale discovery sections. Existing compact SKU
and main category grids retain their layout; global app theme is unchanged.
Store SKU queries keep exact storeId; Saved is store-filtered; price/category,
search, sort, empty results and Back preserve scope and the home query. More stores
uses the existing leased regional pager and callback, excludes the current store,
and remains a separate navigation section below products, with retry/disposal.

Validation:
- R6 Store/source/published-catalogue checks:31 passed,0 failed (13030/6775ca).
- Compact initial selection run:47 passed,11 failed; every failure was the
  existing48px list-row requirement. Restored48px, retaining all assertions.
- Corrected Store/area profiles:8 passed (1214/f426d8).
- Shop/Wholesale normal-text store journeys:4 passed (86434/8debed).
- Shop/Wholesale2x store journeys:4 passed (62295/7c1a9f).
- Final compact footer/navigation captures:4 passed (48678/fdb3f1).
  Checks include fully visible Apply, width>=120,height<=100, normal sheet<430,
  store/category/Saved isolation, another-store navigation, Back and home state.
- Final scoped analysis:5 files, no issues (95087/e094f4). Format checked; existing
  unrelated whole-session baseline formatting remains preserved.
All58 scenarios selected for the compact audit are covered by successful runs
and corrected targeted reruns; no full Buy suite or fresh APK claim is made.

Actual local Flutter screenshots inspected at normal and2x text:
C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921/buy-compact-final/.
Normal filter: store-repair-filter-360.0-1.0-false.png.
Large filter: store-repair-filter-320.0-2.0-false.png.
More stores: store-repair-more-360.0-1.0-false.png.
SHA256 evidence-manifest.json binds the final PNGs. Initial selected-label
contrast and large-text footer wrapping findings are repaired and recaptured.

Fresh Redmi requalification remains pending. Installed r66.31 and its SHA-bound
artifact are preserved and do NOT contain these follow-up changes. No production
payment, order, integration, push or technical acceptance is claimed. Formal
handoff still has the previously recorded19127ea6 subject blocker; no history
rewrite or policy rule changes made. Registry binding changed only to record
these founder-requested defects/ticket. Runtime owners:catalogue,session,views;
focused test owners:partner catalogue,session. Existing prior open defects remain.


## Authorized defect repair: REG4642 / REG4643 and Store-specific navigation

Founder CONTINUE FIXING THEM authorizes these two public Buy storefront defects. Launch-required: shoppers must apply filters and find relevant store SKUs. Reuse existing catalogue sheet, development catalogue matcher and existing focused tests; no new screen, backend or state owner. Exact runtime owners buy_v2_catalogue.dart and buy_v2_session.dart; tests buy_v2_partner_catalogue_test.dart and buy_v2_session_test.dart. Preserve production catalogue contracts, Store/Counter Sale/CSV, checkout, navigation and prior APK evidence. Sequence: reproduce, minimal repair, focused regression and analysis. Review data remains review-only; no payment/order action. Device requalification requires a fresh candidate; installed r66.31 cannot prove this repair. Formal integration commit-subject blocker remains separate; no policy expansion.


## Redmi build and device audit complete; two defects remain open

Fresh r66.31 / code2026092101 debug review APK built successfully from
HEAD d73d609d8389101d5981c3c8929b7ac745bf059b (receipt59314/4bf1ae).
Package com.moolsocial.app.cursorreview, installed version1.0.0-r66.31-cursorreview.
Data-preserving installation on Redmi TG8HCYTGGQT885OF succeeded. Pulled installed
base.apk SHA256 equals the fresh artifact:
84A3FEBB5A2DF080E7CB2E645ACE7FE8BA794C49B6B54CF7DD41327C3BFAFB8D.
Build authorization consumed for this candidate; review only, not production accepted.
Artifact: apps/mobile/build/review-candidates/cursor-storefront-pickup-20260921-r1/uaw-cursor-storefront-pickup-20260921-r1-device-review-debug.apk.

Actual device evidence: C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921/redmi-r66-31-uat.
Public product Visit store opens the individual store. Saved filtering, category
selection, product return, price/sort application and Reset work. Search has the
relevance finding below. Cart retains Shop4 items/Rs355 and Wholesale2 items.
Delivery/Collect at store ticks switch exclusively. Collection shows the store;
its payment page retains the sign-in requirement and disables Review order.
Returning to Delivery restores Work address and Rs355 (screen23). Cart values
remain unchanged (24). Continue browsing and background/foreground return to
store with category and cart retained (25). No real order/payment submitted.
Screen22 is collection before the correct Delivery tap, despite its filename.
Bounded current-process error log is empty; this is not a complete crash-history proof.
Font and animation settings were unchanged. Continuous animation and enlarged-text
physical acceptance remain unclaimed; host tests cover their implemented behavior.

Open device findings registered:
- REG-20260921-4642: Store filter Show products button clipped, label offscreen;
  XML zero bounds. Swipe did not recover it; partial blue-edge tap applies.
  Screens07,08,12 preserve the defect. Reset itself works (13).
- REG-20260921-4643: searching rice also returns Self-adhesive price labels (05).
  Source cause and inherited-versus-ticket attribution remain unconfirmed.
Existing REG4634 Delivery rail and REG4635 offer-theme findings remain open.
The seeded profile has active orders, so it does not prove the no-order rail case.
Screens01/15 were transition frames, not confirmed persistent failures. XML04/09
was not captured successfully; only their PNGs are evidence.

No application or test source changed after APK build. Only evidence, the two
requested defect records, and their existing registry count/hash binding changed.
No policy rule or gate behavior changed during this device handoff. No push,
production integration, ticket closure or release acceptance is claimed.


## Both full cycles complete; final analysis passed

45755/293074 exit0: corrected cycle2 passed2459, skipped27 inherited cases,
failed0, matching cycle1. Neither cycle excluded reference tags. Full mobile
analysis59495/9c47c2 exit0: no issues (63.1s). Manifest recheckcd7023:758 owners,
zero drift. Clean checkpoint8d8e32:zero status bytes/records atd278c18b.
Whole-file format checkaa3412 failed on six inherited session-format differences;
no file was changed. Exact baseline-context checkfb5506 proves every difference
exists byte-equivalently in79d54013 and none intersects ticket edits. Other ten
changed Dart files format cleanly. Preserve unrelated baseline formatting;
this is a scoped formatting disposition, not a claim of global format cleanliness.
The first diagnostic33f038 used default console encoding and failed to print;
UTF8 diagnostic8569d5 and exact comparisonfb5506 provide the valid evidence.

Founder queried excessive delay and policy drift. Three complete Buy runs took
about77 minutes (initial failed plus two corrected passes). Registration and
exact-source/hash admission were the bounded previously authorized blocker work;
no further gate/policy development is planned. Proceed to wrapper and Redmi.


## Fresh qualification: first corrected full cycle passed

Build-phase memory13593/81c7e8 exit0 validates4612 entries,238 applicable with
EvidenceArchiveRoot=C:/GUARANTEED OUTCOME/MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904.
Earlier invocation67358/fbe745 omitted this existing archive parameter and failed
on historical REG3955 evidence; no evidence was fabricated or gate changed.
The wrapper must receive the same archive root. Current registry binding:
EBB94598682854BBF4D8EEF858A6FD460569CA6EE6C57B1C232C7F7FBA7C006C.
Build drive has46GiB available; no cleanup or user-file deletion performed.

Preserved installed APK signature0882ed exit0 verifies; signer SHA256
cbdfc5969ad51ed570afb1cf2fe60377e559d43f59d59e2ab66ccaf78ea9ac25.
Compare fresh artifact signer before data-preserving install.

Session45755 cycle1 receipt365d8c exit0:2459 passed,27 inherited skips,0 failures.
No tags/reference comparisons excluded. Cycle2 is running, not yet accepted.
Application/test source remains exactly d5279222466211f0526c625e58b8da5dc0d78218;
control-only commits eb7a14e9 and432befc4 qualify that same source.
Manifest758 files created and live hashes verified: SHA256
E2E9F1B5A215DEBCDFC3DD891CDFF911FE9A349E57CF54D16B0A2F782BE00E54.
Path apps/mobile/build/review-candidates/cursor-storefront-pickup-20260921-r1/source-manifest.txt.
Existing manifest helper covers730 app/test/native/build owners; add all tracked
mobile assets and the11 accepted reference-version files. No original owner
removed. Reverify every live hash before the wrapper build.
Motion-policy state beee7a passed. Redmi settings:720x1600,density320,font1.0,
animation1.0. Installed r66.30 APK preserved without device mutation at
outputs/cursor-buy-ready-20260921/redmi-installed-r66-30-before-upgrade.apk,
SHA256 2AA02DA4E28CE087E21D61F558BC8C705251E0A56A1A73721068E6A9C2C160B3.
No new APK has been built or installed. Final analysis/cycle2 remain pending.


## Exact Redmi source admission repair

Candidate preparation retains buildAuthorization pending. Existing current-turn
build-profile/package isolation d40318 passed; clean-support f52278 passed with
fixture containment verified. Clean source digest1d916e had zero records before
repair; app/test source remains exactlyd5279222 after control-only commits.
UI locks a1e567 passed after the Saved repair; integration coverage0af533 proved
18 approved/2 rejected commits. Startup/auth/native/dependency owners unchanged;
existing startup/config regression entries and REG4641 remain active. Earlier
failed candidate logs and installed r66.30 are retained, never relabelled current.
Source manifest, final analysis and both corrected cycles still pending.


Backend import self-testbcfa36 passed all existing eight cases. Exact projection
d51e1f passed positive plus four negatives (altered content, other owner, other
source and production mode). Full backend retry66273/fa8417 exit0 passes with the three inherited review
exceptions explicitly retained; backendQualified=false, productionPromotion=false.
Log: outputs/cursor-buy-ready-20260921/qualified-backend-boundary-r2.log.

### Fresh-candidate motion and device disposition

Candidate UAW-CURSOR-STOREFRONT-PICKUP-20260921-R1 uses existing CursorUiReview
debug isolation; package com.moolsocial.app.cursorreview, version1.0.0-r66.31,
code2026092101. This is a non-promotable review APK, not backend/payment acceptance.
Founder explicitly requested recurring animation of the store name after a
single sweep was rejected. That precise recurring-name exception is recorded;
do not claim it is only a one-time finite transition. Existing implementation
uses finite timed sweeps, pauses for reduced motion, background and covered
routes, and disposes timers/controllers. Existing navigation motion is reused.
Pickup wording is in the existing checkout choice, not a promotional header.
Device motion/accessibility remain pending until this candidate is installed.

Redmi audit: confirm package/version/signer and pull installed base APK for
SHA256 equality. Preserve app data and the old APK. Exercise public Buy ->
product -> Visit store; inspect store name/search/category/filter/save, SKU
layout, Back and cart continuity. Exercise Delivery/Collect at store ticks,
store/address validation and branch/cart preservation using isolated fixtures.
Check long labels, keyboard, background/foreground and enlarged text. Record
screenshots/XML and defects; never perform a real payment or message. Existing
REG4634 delivery-rail persistence and REG4635 offer-theme defects remain open.


Protected source368c52/f12a04 exit0 qualifies51 files at exactd5279222.
Predicate fixtured4847e passes positive plus11 negative cases: wrong root/source/
branch, missing baseline/source ancestry, extra runtime owner, changed protected
inventory, HEAD/working drift, untracked source and failed inventory command.
Data egress51196/e786ea exit0; new-source pin retains existing user Copy checks.
Egress self-test806d5e exit0 rejects seven forbidden cases and accepts two safe.
App brand17569/51d106 exit0. Backend45621/3d844a rejected one unchanged screen dart:io import.
Screen equals baseline79d54013; the former1880614 source differs only in
embedded Store layout/formatting (33 additions/6 deletions), not the arrival
sound/import seam. Register the exact backend checker to bind the existing
review projection to d5279222 and full portable screen hash C6438E31...B4993992.
No new transport or app code is introduced; production rejection stays active.
The build remains isolated CursorUiReview debug, forbidden for promotion; no
integration acceptance or integration-lane candidate_preflight is asserted.


Saved repair is committed at d5279222466211f0526c625e58b8da5dc0d78218.
Two full Buy cycles run against these immutable app/test bytes. During the run,
only two exact source-admission checker owners and their existing registration/
handoff are maintained; no app/test/native/dependency or generated support edits.
The inherited protected-source checker does not recognize this authorized lane.
Admit only this root, branch, source commit, baseline ancestry and exact four
runtime-owner delta; require unchanged apps/backend/contracts/packages and reject
untracked source. Existing accepted baseline and other source pins stay intact.
The existing clipboard action remains byte-equivalent; its exact review-source
pin may advance only after the protected-source gate qualifies that commit.
This is the previously authorized blocker repair, not production integration or
promotion. Debug review only; the future integration requirement is preserved.
Initial registration cf7d6e matched a repeated literal outside primary scope;
its assertion stopped before mutation. Retry targets the exact primary claim.


## Committed reference acceptance; full regression repair

Saved geometry repair96690/799c44 exit0:165 tests passed across cart relevance,
product variants and shared SKU fit. Existing overlap/gap assertions unchanged.
Format/analysisbf099e exit0:2 files,0 changes,no issues. These focused checks do
not substitute for the pending two full cycles.

Founder approval was executed in local commit19127ea6a7c389eeda000016af672409f2defcff.
Full cycle62287/9df18c exit1:2454 passed,27 inherited skips,5 failures.
Log: outputs/cursor-buy-ready-20260921/qualification-full-buy-cycle-1.log.
Four failures expose insufficient clearance for the existing44px Saved Remove
control in square-photo cards. Fix the visual layout using actual Saved action
width/height; preserve photo-square, non-overlap, thin-gap and badge assertions.
The fifth is the old28px assertion in cart relevance; register this exact test
owner and assert44px while retaining Add/Remove/confirmation behavior.
This is mvp_supporting qualification repair within the existing catalogue owner;
no new service, route, backend or dependency. All prior evidence remains below.
Ten accepted-reference replay checks pass. Fresh source qualification, two full
passing runs, APK build and Redmi testing remain pending. No build authority used.


## Founder acceptance and local commit authorization received

Founder APPROVED CONTINUE explicitly accepts the reviewed new reference version
and authorizes the local ticket commit. Approval is recorded in the versioned
candidate_captures/cursor-storefront-pickup-20260921-r2/ACCEPTANCE.json with ten
image hashes. Reviewed source-owner hashes matched current files before copying.
Previous references remain byte-unchanged; tests will select the new version.
Exact27-owner registration adds only the two comparison tests, ten accepted PNGs
and acceptance record. The inherited scoped-cart test claim transfers locally;
other worktrees and claims remain intact. Classification mvp_supporting: qualify
the already authorized Store/Buy checkout UI, without new runtime development.
Acceptance does not imply full regression, integration, APK or device acceptance.
Continue full regression and commit gates, then fresh candidate qualification.

Accepted-reference replay9558/d5459a exit0:10 passed against the copied accepted
bytes. No golden regeneration was used. Local ticket commit is now authorized
and prepared with27 exact owners; existing633 broader tests,4 Saved tests and
clean focused analysis remain evidence. Full pre-APK runs remain pending.

## Current handoff: functional repair passes; reference acceptance pending

Founder NEXT completed the35 non-image failure repairs and their affected
rechecks. Final broader run7391/47ae0d exit0:633 tests passed across partner
catalogue, promotion rail, session and route continuity. Saved run40383 exit0
and fresh capture76538/e22471 exit0:4 passed. Focused analysis18282/08fcc7
exit0:7 items, no issues. No full Buy suite pass or device acceptance claimed.

Runtime fixes: collection browsing no longer requires a cached checkout address;
incomplete store details still block quote/payment (new regression included in
633). Saved context now reaches its existing labelled44px Remove action before
the compact icon branch. Promotion PageController uses keepPage:false because
session publication identity owns restoration; stale numeric PageStorage was
switching the offer after Back. Initial screen-routing hypothesis was wrong,
reverted, and that untouched owner returned to the inherited claim. Final claim
is14 owners, including promotion test; scoped-cart test remains unchanged.
Test repairs retain identity/text bounds/cart/navigation assertions, settle
scrolling before real taps, and reveal a lazy header through its list position.

Final boundaries: UI-lock55328/3e3360 exit0; coordination425dfc exit0 at14
owners; regression-memory49611/01cf55 exit0 at4612 entries; diff-check and
baseline Android/approved-reference equality d6e8f9 exit0. Registry SHA256:
C93554198F3D46CE8AB2BC2AE03676481432C2543E284BDAA0EB76A62FAAEA37.

Fresh protected reference run50147/27bb61 exit1:10 image comparisons fail.
All40 diagnostic PNGs were archived byte-for-byte with checksums and source
owner hashes in outputs/cursor-buy-ready-20260921/reference-review-r2, then only
tracked generated diagnostics restored to HEAD. Approved references unchanged.
Current images include pickup-choice checkout and integrated product-card cart;
older comparison images predate those layouts. No update-goldens or skips used.
Review packet (10 paired images plus4 Saved captures):
C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921/REFERENCE-REVIEW.md.
New proposed version cursor-storefront-pickup-20260921-r2 is NOT accepted yet.

Next required founder decision is concrete visual acceptance of that NEW
reference version and explicit local commit authorization. Worktree AGENTS.md
states accepted versions are never overwritten and require a new acceptance
cycle; central production AGENTS.md Git rule6 requires an explicit commit request.
No commit, push, reference replacement, APK build/install or Redmi mutation
occurred. Candidate remains blocked_visual_reference_and_source_checkpoint.
After acceptance, qualify the new reference/source checkpoint and remaining
full regression/build gates before building and verifying a fresh Redmi APK.

## NEXT: focused regression repair in progress

Founder NEXT continues existing Store/Buy APK qualification. Existing owners,
launch outcome and payment boundaries remain unchanged. REG4641 classification:
18 provider-name failures read the last prefetched page as the visible refreshed
first page; now select the newly loaded startIndex0 page and assert its identity
and new provider label. Four collection discovery failures are a real introduced
browsing regression: beginStoreCollection required a cached checkout address.
Browsing intent now requires a real product/store identity and fresh matching
facts; actual checkout retains address, quote and payment validation.
Four enlarged supplier navigation cases tapped before ensureVisible settled;
now settle and require hitTestable before the same real action.

Focused SKU run23941/60d59b exit1:102 passed,2 failed. Provider-name cases
pass; remaining failures are Icon glyph natural-line metrics22.8 vs23, not
metadata truncation. Matching TextPainter layout settings alone did not fix
the Icon mismatch. Retain qualification-sku-r1.log. Metadata assertions now
apply to text rather than fixed-square Icon glyph paragraphs; no text bound
or truncation assertion removed. This result is registered before retry.

Bounded qualification owner extension: promotion-rail-state and scoped-cart-
checkout-dock-continuity tests only (exact paths in current claim). Classification
mvp_supporting: verify public Buy promotion return and Saved controls against
the integrated UI, preserving quantity/navigation/accessibility assertions.
Reuse existing tests and catalogue controls; no new service/screen/data model.
No locked golden is an added owner. Test fixes cannot authorize visual-reference
replacement or integration acceptance. Collection browsing recovery8412/acecd1
passed all4 viewport/text-scale cases, including exact branch/cart retention.

Qualification scope refined: scoped-cart test requires no edit; its claim is
returned intact. Exact Buy screen owner replaces it to correct verified Offers
Back navigation: wholesale promotion opens correctly, but Back clears Offers
because destination is wholesale even though it has not changed on return.
Reuse existing destination-change tracking; preserve explicit dock switches.
This is Buy-local route state, no Store/backend/shared contract edit. Test the
same offer, retained Cart, fresh product scroll, and unrelated navigation.
Promotion87672 exit1 (2 pass/2 fail) and wholesale29429 exit1 remain retained.
The latter proves the header is lazy, so direct ensureVisible cannot locate it;
reveal through the existing list position before real hit-tested action.

## Completed native repair and final prebuild regression result

Native blocker REG4640 is resolved_gate_active. Final full UI-lock run93660
exit0 includes untracked native/reference rejection. Positive exact projection
and five negative tampering/untracked cases pass (196331/afa490). All Android
and approved-reference files remain identical to baseline79d54013; comparison
86afae exit0. No expected original hash or native source was replaced.

Full Buy run46201 finished at terminal ebe9f8 exit1 after28:39:
2413 passed,27 skipped,45 failed. Retained full log:
C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921/redmi-prebuild-buy-regression-1.log.
Failures: partner catalogue29, checkout-cart-return5, scoped-cart-checkout9,
promotion rail2. Ten are reference-image comparisons; five checkout-return
images include the intentional new pickup choices. Other failures include
provider-page oracles, legacy taps, collection route assertions, saved label
expectations and a non-unique promotion finder. Do not classify every failure
as inherited or every image difference as approved without individual evidence.
Original images and failure artifacts remain intact. REG4641 records this
qualification failure before any retry. Log-extraction cp1252 output error
121746 was corrected with explicit UTF8 stdout (8493cd); no source changed.

The test runner overwrote40 tracked diagnostic PNGs, causing coordination
ce6e52 to reject unclaimed generated evidence. All40 new PNGs were preserved
byte-for-byte with captured/HEAD SHA256 manifest in
C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921/redmi-prebuild-buy-regression-1-failures.
Only those generated diagnostics were then restored to their HEAD bytes
(41820f). No approved golden or runtime/test source was overwritten. Initial
artifact inventory9d01ac output was truncated; the retained manifest is exact.

Foundation preflight passed, but protected Buy source check b0b471 exit1 still
requires a qualified sealed source checkpoint. No local implementation commit
has been made: central AGENTS.md Git rule6 requires an explicit founder commit
request. Current changes remain reviewable in this worktree. Candidate state
remains blocked_regression_and_source_checkpoint; no APK built or installed,
no checksum/device acceptance, no inherited authorization consumed.

## Native lock reconciliation â€” founder authorized production-grade fix

REG4640 root cause traced to committed Store export additions: dff6c124 adds
five MainActivity registration/disposal lines;06432e2b extends the bridge's CSV
filename allowlist. All inherited native bytes remain intact. Exact current
worktree projection first pins the full MainActivity and Stock bridge hashes,
keeps baseline ancestry/Android equality guards, strips only the five known
lines IN MEMORY, then applies every original accessibility and reference hash.
No original approved hash, native file, permissions or other worktree changed.
Positive full UI-lock gate session71067 exit0 PASS. In-memory self-tests
chunk196331 exit0: exact projection matches original hash and native extra line,
accessibility mutation, registration mutation and bridge tampering all reject.
This supersedes the native-hash blocker recorded below.

Fresh draft candidate state now exists at
docs/quality/CURSOR-BUY-READY-20260921-APK.json. It is explicitly prebuild_in_progress,
not approved_for_one_build; old r61.5 state remains untouched. Exact13-owner
coordination passed after the new state file was created (initial claim check
correctly rejected the then-missing file). Foundation preflight session81605
exit0 PASS, including locked dependency resolution and wrapper safety fixtures.
Protected Buy gate chunk b0b471 exit1 reports "Protected Buy baseline is missing
and no exact sealed overlay applies." It requires a qualified exact source
checkpoint; this uncommitted worktree is not an admitted sealed source.
Full Buy regression session46201 is running with retained log at
outputs/cursor-buy-ready-20260921/redmi-prebuild-buy-regression-1.log; five
checkout-cart-return screenshot comparisons have already failed. No approved
reference was updated, test skipped or failure converted to passed. Candidate
machine state is blocked_regression_and_source_checkpoint. Native-lock repair
is complete; source qualification and regression failures are separate blockers.
fresh source manifest, complete Buy regressions, clean integration and candidate
qualification are not yet claimed. No APK or device acceptance yet.

## Fresh Redmi APK request: prebuild blocked

Founder requested a fresh final Redmi APK and Store-ticket defect testing.
Authorization is fresh and does not reuse inherited r61.5 authority. Intended
candidate: UAW-CURSOR-STOREFRONT-PICKUP-20260921-R1, proposed version1.0.0-r66.31,
code2026092101, isolated debug Cursor review; no build authorization consumed.
Device readback: Xiaomi23106RN0DA, serialTG8HCYTGGQT885OF, authorized/connected.
Existing com.moolsocial.app.cursorreview is1.0.0-r66.30-cursorreview,
code2026091802. That installed build does not contain this uncommitted ticket;
it was not substituted for fresh-device acceptance. OPPO was not touched.

Prebuild coordination12 owners passes. Approved integration commit coverage
passes at635ab981 (18 approved,2 rejected). Required approved-UI lock fails at
check-approved-ui-locks.ps1:287 (chunk ef9ebd exit1): Accessibility native
implementation hash mismatch. Expected normalized combined MainActivity SHA256:
8a4bf4853c24176662fa9dafc8dced9da3a929903c60438eeaa7731e511460c4.
Actual: AEBB6246F8E040840EFE029557293D202E8B3A822D53752FADAC0FC2743ECB56.
Native file is byte-unchanged from complete baseline79d54013 (Git comparison0).
Exact current-worktree admission already selects combined projection; this is
not another missing path-registration problem. Locked native code and expected
hashes remain unchanged. Existing machine state is consumed r61.5 and was not
repurposed. Fresh candidate state/build admission and clean integration remain
unqualified, not claimed passed.

No APK built, installed or tested; installed checksum verification and Store
defect audit are pending. Unblock by reconciling the inherited approved native
baseline through its protected integration process, then qualify fresh candidate
state and build gates. Do not patch a locked hash or test an old APK as this ticket.
Device audit after admission: public Buy -> product -> Visit store; short/long
name, search/category/filter/saved, Add to cart, pickup/delivery ticks, exact
store/cart retention, back/keyboard/rotation/background, restart and failure
recovery. Record all defects and verify installed APK SHA against fresh artifact.

## Founder rule: pickup offered by every store

Founder subsequently directed "NEED TO IMPLEMENT" after the shared-owner
dependency was explained. This authorizes the bounded local implementation
and exact owner registration for this extension; other worktrees remain intact.
Classification mvp_required: public Shop shopper selects pickup or delivery at
checkout and retains the explicit fulfilment choice into the existing order
controller. Reuse session, store listing, collection basket/quote, checkout
ChoiceChips and session tests. Added exact owners: buy_v2_session.dart,
buy_v2_content_contracts.dart, buy_v2_views.dart and buy_v2_session_test.dart.
No new backend, route, payment adapter, schema, stock rule or delivery service.
Every valid Store listing supports pickup by platform policy independently of
legacy optional capability metadata. Keep required identity/address, fresh quote,
account/session binding, durable intent, payment reconciliation and order checks.
Existing production collection gateway is not wired in this baseline; fail
closed for payment rather than fabricate success. Test missing/false/expired
legacy metadata, explicit selection, mixed-store isolation, stale quote, failed
service/payment, retry/reconciliation, responsive tick controls and screenshots.
Integration must reconcile these exact shared owners with later Codex work.

IMPLEMENTED LOCALLY: all checkout Store listings are selectable independently
of old pickup metadata. A valid branch identity/name/address is required before
quoting. Delivery and Collect at store show explicit white selected ticks;
choosing one deselects the other. Multi-store carts retain the existing explicit
branch selection and leave other stores' items in Cart. Selection does not pay
or create an order. Gateway/account/quote/intent/payment protections remain.

Validation: session52174 exit0, all51 R5 collection purchase tests pass, including
missing/disabled/expired opt-in metadata through paid test-gateway outcomes,
expiry, account/store/SKU mismatch, duplicate taps, durable recovery and mixed
carts. Session60569 exit0: all3 storefront regression profiles pass. Final
capture session63110 exit0: both390px/1x and320px/2x tick journeys pass.
Analyzer session62879 exit0: no issues after restoring unrelated formatting.
REG4639 retains the first missed-scroll test failure; no tap warning suppressed.
Final evidence: outputs/cursor-buy-ready-20260921/all-store-pickup-r2/
all-stores-pickup-390.0-1.0.png (actual native fixture screen).
Logs: all-store-pickup-r2.log and pickup-storefront-regression-r1.log in the
same outputs parent. Whitespace and protected Store/routing/native/backend
comparison pass. Registry4610 and exact12-owner coordination pass.

Limit: this is tested local checkout implementation, not live pickup-payment
acceptance. No production collection checkout gateway is connected in this
baseline. It remains fail-closed; no service/payment success was invented.
No APK, commit, push, integration or other-worktree write. Earlier native UI-lock
and broad baseline-suite findings remain recorded and are not waived.

Earlier requirement/dependency assessment (superseded by implementation above):

Founder clarified every store allows pickup. Desired ordering choice: Delivery
or Collect at store, mutually exclusive with a visible selected tick. Pickup
must not depend on optional merchant opt-in. This is an authorized business
requirement, not yet implemented or technically accepted.

Current exact dependencies: buy_v2_views.dart _CheckoutAddressStage hides choices
when collectionCheckoutStores is empty. buy_v2_session.dart collectionCheckoutStores
filters using store.collection.isSupportedFor; chooseCheckoutCollection rejects
empty stores. Collection basket/quote/payment validation also depends on the
shared BuyV2StoreCollectionCapability in buy_v2_content_contracts.dart.
Showing a chip alone would leave a nonfunctional choice.

This crosses the established Cursor storefront source/test claim and shared
Store/Buy checkout contract boundary. Coordinate the default pickup capability,
existing store records and order fulfilment with the integration owner before
runtime implementation. No shared owner or gate was changed here. Keep sign-in,
store identity/address, current inventory/prices, quote/payment verification,
duplicate-order protection and recovery checks. Do not invent pickup times or
multi-store collection/payment semantics. Acceptance must cover ordinary stores
without legacy capability metadata, delivery/pickup switching, mixed-store carts,
stale stock/quotes, failure/retry and resulting Store order fulfilment.

## Founder amendment: store identity in controls row

Move store name out of the search header into the centre of the controls row,
replacing the collection promotional copy. Moderate 14px semibold charcoal,
centre aligned, full wrapping without ellipsis or a line cap; preserve text
scaling and recurring sheen. Same mvp_supporting actor/scope and owners.
Remove storefront promotional CTA; reuse existing collection/delivery decision
in cart flow without changing routing/contracts. Verify long names at narrow
width and enlarged text, existing controls and a fresh actual screenshot.

Implemented and locally verified: session15286 passed all three scoped journey
profiles, including the full "Shree Radha Krishna Supermarket and General Store
Jodhpur" at320px/2x text, no name in search, no promotional CTA, repeating name
motion, lifecycle/reduced motion and search/filter/save/navigation. Analyzer
passed. Session39328 capture passed; native screenshot at
outputs/cursor-buy-ready-20260921/storefront-name-rail-r1/public-visit-store.png.
Existing buy_v2_views.dart checkout choices at7708-7723 already provide Delivery
and Collect at store; no checkout owner changed. Protected-owner comparison and
whitespace checks passed. Initial source-edit helper stopped before writing due
to Windows default text decoding; the subsequent exact patch preserved UTF-8.
Visual review pending. Changes remain local/uncommitted, with earlier broader
suite/UI-lock limitations unchanged.

## Approved layout: label colour and customer copy refinement

Founder approved the current screenshot and selected non-blue store/collection
text plus benefit-led collection wording. Same public shopper, mvp_supporting
scope, catalogue and focused-test owners. Reuse the private text sheen with
per-label colours: charcoal store identity and warm plum collection copy.
Preserve motion, layout, eligibility and collection callback. No data, routing,
shared theme or dependency edits. Verify narrow/2x text and reduced motion with
existing scoped tests and capture a fresh native screenshot for review.

Current copy: "Shop now / Pick up when ready". Store name charcoal; collection
plum #663852 with #925775 sheen. Reduced-motion text retains the same colours.
Session96037: all three scoped journey profiles passed. Analyzer: no issues.
Session54914: Visit store capture passed; screenshot at
outputs/cursor-buy-ready-20260921/storefront-colour-copy-r1/public-visit-store.png.
Whitespace check passed. Visual amendment awaits review; no APK or commit.

## Ongoing text motion correction

Screenshot-only follow-up: first capture invocation omitted required review
defines and stopped at the review-mode assertion (chunk c80234 exit1), the
already registered REG4633 failure mode. Retry uses all three exact review
defines below; no runtime or assertion change. Fresh still directory:
outputs/cursor-buy-ready-20260921/storefront-recurring-still-r1.

Founder rejected the finite entry movement: store name and collection text must
continue animating. REG4638 records the mismatch. Same public shopper,
mvp_supporting ticket and exact source/test owners. Replace only these two
entrances with a recurring navy/brand-blue text sheen, keeping text stationary,
readable and tappable. Existing card reveal has no repeat API; use a private
text wrapper in the already owned catalogue file, native animation primitives
and existing brand colours. Pause for reduced motion, covered routes and app
background; dispose timers/controllers. No routing, data or dependency changes.
Verify subsequent cycles, reduced motion and existing scoped journeys.

Implemented: 2400ms navy/royal-blue sheen across the glyphs every3600ms,
collection sweep slightly staggered. No translation, fade-out or layout movement.
Recurring-motion-r3 session69393 exit0: all three scoped journey profiles pass,
including two subsequent cycles for both labels, stable bounds, background stop,
foreground restart, enlarged text, reduced motion and disposal. Log retained at
outputs/cursor-buy-ready-20260921/storefront-recurring-motion-r3.log.
Analyzer session32073: no issues. Registry gate4609 passed session91772.
Earlier lifecycle test/disposal failures are retained in REG4638 and r2 log.
Only catalogue presentation and its focused test changed in this correction;
shared/native owners preserved. No new video or APK. Visual review pending;
existing broader suite/UI-lock limitations below still apply.

## Corrected public-side scope â€” supersedes the initial capture below

Founder rejected the first capture: "Store" means the public storefront after
tapping Visit store, not the operator dashboard. The first Buy capture omitted
MOOLSOCIAL_DEVICE_REVIEW and showed the small historical default fixture.
Registered as REG-20260921-4633-CURSOR-CAPTURE-RUNTIME-AND-PUBLIC-STORE-IDENTITY
before retry. Initial PNGs and their hashes below remain immutable evidence.

The Cursor branch fast-forwarded without conflicts from 06432e2b to the newly
available Codex checkpoint 79d5401338881f55e65b08c0e7843cbac016fcfb. The new
commit changes Store CSV validation and its tests/docs; no Buy presentation file
changes between those checkpoints. Integrated Cursor tip
ee42be0e21f1707e1cbf2ba3ad966579f118b209 is an ancestor, and later Store/Buy
integration changes are present. This is the complete local work checkpoint,
not a claim that all native/backend/release gates are qualified.

Corrected test: real MoolSocialApp public Buy route with the reviewed APK flags
MOOLSOCIAL_UI_REVIEW_ONLY=true, MOOLSOCIAL_DEVICE_REVIEW=true and
MOOLSOCIAL_USE_EMULATORS=true. Assert review mode and pagedCatalogueEnabled;
derive the selected product ID from the actual rendered buy-paged-card key,
tap that product, scroll to its Visit store button, tap it,
assert the matching public seller sheet and reject WorkWorkspaceDashboardScreen.
No application source change. The sixth setup owner is the regression registry,
with 4604 entries and its refreshed policy checksum. Corrected output directory:
C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921/corrected-r5.
Correction validation: PASS, two tests, terminal exit0 (session11602,
terminalcebb58). Both PNGs were opened and visually inspected. The second is
public Store products / Order & Collect for Mool Market 1 after a real Visit
store tap; the operator dashboard is asserted absent. Initial capture and
failed correction attempts remain recorded under REG4633. No APK was built.

Corrected PNG SHA-256:

- public-buy.png:
  5C0E0425D38B2623D210473BABC2C58D25BFEE9611E6F270FD6AEB531FABA566
- public-visit-store.png:
  F2535A6ADD7B434ADE90935A8CA7826EF0D028EEA584665E1BF87D49EF84318B

Application source equality to HEAD79d54013 passed. Combined Store/Buy
integration123ff42c and prior Cursor tip ee42be0 are ancestors. Formatting and
diff-whitespace checks passed. Review-ready is not implementation-ticket,
native-lock, runtime/backend, device, integration or release acceptance.
Setup/test/regression edits remain uncommitted and confined to this worktree.

## Founder-selected storefront redesign and reported defects

The founder accepted corrected-r5 public Buy and public Visit store images.
Selected outcome: public shopper opens an individual store through the existing
Visit store action and browses that store's SKUs with home-style search,
category, filter and saved controls. Replace the Quick/Scheduled presentation
there with ordering-in-app and collecting-at-store wording. Preserve collection
eligibility and existing product, cart, checkout and return navigation.

Classification: mvp_supporting, improving existing public Store discovery.
Reuse buy_v2_catalogue.dart's partner sheet, full store catalogue, paging,
product cards and chrome; retain the authoritative storeId query boundary.
Minimal planned runtime owner: apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart.
Reuse apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart and the
existing cursor_buy_store_baseline_capture_test.dart for connected-journey
checks and fresh visual evidence. No new backend, shared contract, router,
dependency, Store operator screen, Counter Sale or CSV work is selected.
Search/filter/category/save must remain store-specific without leaking home
state; retain loading, empty, failure/retry and collection availability behavior.
Founder explicitly authorized the prepared six-file local setup commit:
635ab981, subject coordination(buy-ready-20260921): admit independent baseline
capture. task_start passed with six owners. Exact storefront implementation
registration then passed with eight owners: the two source/test owners above
plus the six setup owners. Bootstrap owner/parent checks remain unchanged;
only buy_v2_catalogue.dart may differ among application owners. APK, acceptance
and release remain excluded. Source/test changes after setup are uncommitted.

Current implementation reuses the full paged public Shop catalogue on Visit
store. Store search/category/price filtering and saved products use exact Store
identity, leaving home discovery state unchanged. Product/cart callbacks remain
the existing ones. Store details and other-branch navigation are behind Info.
The founder approved the storefront layout, questioned the store-name position,
then explicitly corrected that concern: "store name is at right place".
Keep the approved floating store-name label in the search header. The proposed
move into the controls row was undone. Do not reopen the approved layout.

Founder then selected animation of the store name and Order/Collect wording,
preserving their positions and app branding. Same actor, mvp_supporting scope
and owners: reuse BuyV2CinematicCardReveal from buy_v2_design.dart without
editing it or adding an animation framework. Apply its existing finite depth,
fade and blue-white light sweep to the name and collection text, staggered by
140ms. Existing reduced-motion behavior resolves immediately; controls retain
their original hit testing and callbacks. Capture actual Flutter frames for
a short local video; no APK, dependency or shared contract change.

REG4636 records the first screenshot's missing collection action. The paged
grid refreshes product facts independently of Store collection facts. Reusing
the existing exact Store refresh after successful page refresh restores current
collection authority, retaining withdrawal/expiry checks. First evidence
outputs/cursor-buy-ready-20260921/storefront-r1/public-visit-store.png is retained.
Diagnostic session2461 failed with null collection; corrected capture session
14824 passed both tests with capability and action assertions. Storefront-r2
captures the accepted compact layout before the final name positioning change.
Two scoped control/navigation tests passed at 390px/normal text and 320px/2x text.
Broader partner suite session99132 finished with 144 passed / 34 failed.
REG4637 records the failures; the suite is not green. Representative baseline
replay session19203 used the exact committed catalogue blob at635ab981 and
reproduced all three selected failures: provider test mistakes the last
prefetched response for the active page; metadata test reports an icon's
22.9px/23px metric difference; 2x-text legacy supplier/cart tap misses its target.
Evidence: outputs/cursor-buy-ready-20260921/baseline-comparison.log.
The current source was restored byte-for-byte (SHA256
BFF90DD31931CA3A4AA956E4B76D5820F4CDC761B63004A2BB5E3DF008DE8568 before formatting).
Those inherited checks/thresholds and runtime owners were not weakened or fixed
as part of this small storefront ticket. The changed direct-store Back and
retained-page test expectations passed with search, category, saved, price
filters, cart, nested product, keyboard and responsive checks: focused-r5,
session17236, exit0, nine tests. Includes portrait, landscape, 2x text and
reduced motion. Log: outputs/cursor-buy-ready-20260921/storefront-focused-r5.log.
Final Dart analyzer session22082 passed with no issues. UI-lock session65667
still fails the inherited native Accessibility projection; no locks weakened.
Actual Flutter motion capture session46297 passed both tests. Evidence:
outputs/cursor-buy-ready-20260921/storefront-motion-r1/public-visit-store.png
and storefront-animation.mp4 (H264, 780x1688, 12.5fps, 3.44 seconds).
The name and collection copy use finite staggered brand motion in their
approved positions. Animation visual approval remains pending; implementation
is local and uncommitted, not integration or release acceptance.
No APK is needed or built.

Founder specifically reinforced reuse of existing wiring/navigation and a small,
complete change. Do not turn this ticket into a wider development programme.

Two separate defects were reported on 21 September 2026 and registered locally:

1. REG-20260921-4634-CURSOR-DELIVERY-RAIL-WITHOUT-ACTIVE-ORDER:
   main bottom rail Delivery icon persists with no placed order or no active
   delivery. Expected: absent in those states; existing active-delivery route
   available when eligible. Reproduce and test fresh/retained state, active,
   completed/cancelled and multiple orders before closure.
2. REG-20260921-4635-CURSOR-OFFERS-PROMO-CARD-THEME-MISMATCH:
   Offers promotional card design/colours do not match the background/app theme.
   Expected: established Buy theme/card treatment, readable contrast, unchanged
   offer content and tap behavior, followed by actual-screen visual review.

Both are OPEN, founder-reported; root cause, reproduction and fixes are pending.
Existing test paths in their registry records identify verification owners,
not evidence that those tests already prevent these defects. Their registration
does not expand the storefront implementation ticket. Registry now has 4606
entries; its coordination checksum binding is refreshed without relaxing gates.

## Initial capture â€” retained, rejected scope

Ticket: UAW-CURSOR-BUY-READY-20260921. Work ID: buy-ready-20260921.
Lane: cursor_ui. Independent agent: primary /root in this worktree only.
Branch: work/cursor-ui/buy-ready-20260921.
Application checkpoint: 06432e2b946b02007d9946c562f922294f485632.

Founder authorized only exact workspace/path admission and local screenshots of
public Buy and the Store workspace. Redmi APK is fallback-only if local capture
is impossible. This local capture task grants no APK or application mutation.

Classification: mvp_supporting. Actors: public Buy shopper and Store operator.
Outcome: inspect current full-baseline native screens before assigning the first
Buy frontend ticket. Reuse MoolSocialApp, its existing production routes,
BuyV2Screen, WorkWorkspaceDashboardScreen and existing Flutter test font setup.
No new screen, data owner, backend, route or production fixture is introduced.

Exact owners: the coordination JSON/checker, UI-lock checker, this record and
apps/mobile/test/cursor_buy_store_baseline_capture_test.dart. Existing root claim
in this copied worktree is replaced with this setup-only claim; the actual Store
worktree and all its files/claims are untouched. Historical continuation bindings
and other claims are retained. Future Buy tickets require exact source/test owners.

Capture uses in-memory review authentication and Store state in a host-only test,
with existing native widgets and application router. It proves rendering and
visible route ownership, not real account, payment, backend or physical-device
acceptance. No real data, message, order or payment is created.

Checks: coordination bootstrap; unchanged UI-lock checks with exact path admission;
focused host capture with visible-owner and exception assertions; PNG inspection;
application source preservation. Record failures accurately, keep evidence and
do not silently convert a failed gate into a pass.

Evidence destination: C:/GUARANTEED OUTCOME/outputs/cursor-buy-ready-20260921.
Status: local screenshots captured and inspected. Both host capture tests passed;
no Redmi APK was built or installed. Setup changes are uncommitted; this is not
ticket closure, clean-handoff qualification or release acceptance.

## Validation and retained findings

- Regression memory: PASS, 4603/4603 entries, phase general, buildMode none,
  using the existing EvidenceArchiveRoot option with
  C:/GUARANTEED OUTCOME/MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904.
  The initial run without that archive could not find retained evidence for
  REG-20260902-3955-NATIVE-DIFF-CHECK-FAILURE-DID-NOT-STOP-COMMIT. Supplying its
  preserved archive resolved evidence lookup without altering registry/checks.
- Coordination bootstrap: PASS for primary /root, cursor_ui, this exact ticket,
  five claimed owners and unchanged registry generation. Final replay required
  after recording this result. This is bootstrap admission, not ticket_close.
- Negative admission test: PASS; candidate_preflight is rejected with
  "Cursor setup cannot authorize acceptance, APK or release."
- UI locks: FAIL remains. Exact path admission now reaches the pre-existing
  native-content projection check and reports "Approved UI Accessibility
  projection rejects an altered or missing native implementation." Native
  sources, approved references and expected hashes were not changed. This
  inherited release blocker is not repaired by screenshot acceptance.
- Host capture: `flutter test --no-pub
  test/cursor_buy_store_baseline_capture_test.dart --reporter expanded
  --concurrency 1`, through Invoke-MoolSocialFlutterWithCleanSupport: PASS,
  two tests, zero test exceptions, exit 0. Real MoolSocialApp routes resolved
  to BuyV2Screen and WorkWorkspaceDashboardScreen respectively.
- Dart format: one file, zero changes. Application-baseline diff: zero changes
  across lib, Android, iOS, pubspec/lock, backend, contracts and packages.
- Captures: 390x844 logical pixels, 2x raster, inspected with the image viewer.
  Public Buy shows Shop catalogue; Store shows the operator dashboard with an
  empty order queue. These use local fixture state, not live service data.

Image SHA-256:

- public-buy.png:
  32CD183CBD0D0CCEF21EB2A85275EFB4B1B174ED5F83D35B0CAA41B54ED00002
- store-workspace.png:
  C059174E875E60EDFB97DEAB77C82967F1E06EC73EE9BD5F23CA7D2C31113D33

Future integration: retain the complete checkpoint, keep Buy changes isolated,
coordinate shared Store/Buy contracts and routing, and qualify exact commits plus
combined regressions in the designated integration worktree. Visual approval is
not technical acceptance. No inherited r61.5 authorization may be reused.

Founder additionally requested store-specific search/filter/SKU isolation and restoring More stores below the store. Reuse existing related-store cards and callback as a footer; no new navigation contract. Initial tooling invocation used incorrect working-directory-relative paths and made no edits; corrected at worktree root. Its Flutter dependency resolution changed generated support metadata; exact clean-start HEAD bytes restored after archiving generated copies outside the worktree. Subsequent tests use --no-pub.

Navigation test r3 failed4 profiles because cached other-store previews alone were absent after page retention. Repair uses the existing leased Store pager for a bounded same-region list, independent of SKU search/filter, excludes the current store, and keeps retry plus dispose/release. No general-home SKU content is inserted. Earlier r2 passed5 focused tests; analyzer identified one null-aware collection lint, corrected.

R4 navigation exercised the restored cards, selected-store query and Back successfully, then the test failed locating the lazy offscreen Close header. Preserve retained scroll and explicitly scroll back to Close in the test. Search prefix matcher also applies to this store Saved results, retaining Unicode words and excluding price-label infixes.

R5 passed30/failed1: 320px/2x Close test tapped before scroll settled, leaving the sheet open. Add pumpAndSettle plus hitTestable before that tap, without changing the Close callback or weakening its disappearance assertion. Related-store requests explicitly remain regional even when home browses all areas.

## Added in-progress ticket: Buy compact selection spacing

Founder rejected spread-out filter text and explicitly added this ticket between current repairs. Launch-supporting: reduce excess spacing across Buy selection surfaces (Shop/Wholesale discovery, Offers publisher/categories, individual Store filters/categories, related filter tools). Reuse existing catalogue and views owners; preserve 44px minimum actions, enlarged text, callbacks and data scope. Audit already-compact SKU/category layouts without shrinking their tap targets. No global application theme, Store-workspace, backend or policy changes. Validate focused Store navigation plus existing discovery/category/filter tests and actual local captures.

Compact screenshot inspection caught selected chip labels losing contrast when explicit typography replaced inherited state color. Correct selected text/checkmark to white and unselected text to navy. Remove redundant filter drag handle (Close and gesture dismissal retained) to reduce unused header space. Keep screenshot evidence and recapture final controls; no acceptance from an uninspected image.

Compact r1 caught four area-row minimum-target regressions (44/47 versus existing48px requirement). Restore48px list-row minimum; retain compact typography and do not weaken assertions. Store filters remain within compact height bound and footer hit-target checks.

Large-text screenshot review revealed Reset taking most footer width and forcing Apply into character wrapping despite hit-test success. Allocate equal flexible width to both actions; add minimum120px Apply width and maximum100px height checks at every profile. Keep full text and font scaling, no ellipsis or scale suppression.

## Founder-authorized remaining session defects: Delivery and Offers

22 September: implement REG4634 Delivery rail only for active placed delivery records, REG4635 theme-consistent Offers promotions, and reconcile all session requests. Launch-supporting UI correctness using existing order state, navigation, published offers and colours. Exact runtime owners: screen (delivery selection predicate only), catalogue (promo styling), session only if required by existing authoritative lifecycle. Focused existing test owners: session and promotion rail. Exclude backend/provider/native/routing contracts and unrelated worktrees. Validate zero/active/completed/retained/multiple orders, existing fulfilment exclusions, offer callbacks/return and normal/large-text captures. Cancellation not invented where order contract has no cancellation state. Production payment and new Redmi qualification remain separate evidence obligations.

Current user authorization transfers only buy_v2_screen.dart ownership from the recorded retired RV6 audit task to this independent Cursor ticket, to fix its actual rail predicate; no other task owner or policy rule changes.

## Current local-only batch and next-device memory (22 September)

Founder added ticket 11: explicit Store-to-Buy channel/fulfilment eligibility.
Complete scope, the ten residual findings, safe-parking requirements and mandatory
next-Redmi/backend retest queue are in CURSOR-BUY-LOCAL-CUTOFF-20260922.md.
No APK for this batch. Existing implementation admission rejected the newer
scope; no new runtime implementation is claimed yet.


## Local 11-ticket cutoff — 22 September 2026

Frontend fixes and child checks completed locally; see
`docs/quality/CURSOR-BUY-LOCAL-CUTOFF-20260922.md` for per-ticket dispositions,
explicit eligibility schema and final test evidence. No new APK. Nine change
tickets are locally closed; provider/data tickets 5 and 10 retain their previously
deferred external dependencies. All 11 must be replayed on the next Redmi APK
with backend tickets. Source remains uncommitted on the same branch/HEAD, safely
archived with exact hashes under the workspace outputs directory. Formal handoff
requires a clean committed tree; the existing gate was not waived. Stop here.


## Latest: complete Git reconciliation and Codex baseline request

Founder authorized preserving all Cursor work locally and remotely, a clean
committed handoff, and requesting the next full integrated baseline from Codex.
See CURSOR-BUY-INTEGRATION-HANDOFF-20260922.md and its inventory for exact source,
commit coverage, local/remote verification and recovery artifacts. This supersedes
the earlier uncommitted cutoff state without changing app source or device claims.
All eleven tickets and children still require next-Redmi replay with backend;
DEP-01/02/03 remain explicit. No backend work or new APK starts from this handoff.

## Current Cart execution — 2 October 2026

The founder authorized T06 payment grouping followed by T07 recovery and A09,
then a stop before T08. T06 frontend implementation has clean seven-owner analysis,
28 focused passes and924 distinct selected passes against final unchanged source.
Actual Redmi Cart/Checkout and shared instructions were reviewed after full Dart
restart, including200-percent text; original device settings were restored.
See T06 qualification in `CURSOR-BUY-INTEGRATION-HANDOFF-20260922.md` and the
founder ledger's `cartPaymentGroupingT0620261002` for exact evidence.

Native grouping, backend and workspace provider execution remain deferred;
workspace implementation is **Codex after integration**. Google and Maps
dependencies remain listed. The historical commit-prefix blocker prevents formal
handoff. Save an ordinary correctly prefixed T06 feature checkpoint, then admit
the already-authorized T07/A09 recovery sweep. No new APK or live payment.

### T06 checkpoint saved; T07 execution held

T06 is committed/pushed as `ee258a5e0dea49bf5d62286e6cc8c21f9ae416cd`;
clean status and local/remote equality were verified. T07 scope/ownership,
incremental and coordinator admission passed, but its mandatory memory gate
failed on missing historical r60.52 AAB evidence. No T07 runtime/test edits
or device attempts occurred; A09 remains unresolved. The exact artifact,
bounded investigation and restore/governance requirement are recorded in the
latest T07 handoff section and existing REG4647. Admission/hold records are
uncommitted; do not bypass the gate to implement or checkpoint T07. Stop before
T08 until authentic evidence restoration or explicit governance resolution.

### Historical artifact retention repair verified — 2 October 2026

The founder authorized this repair after the cleanup deleted permanent evidence.
The original hold above is retained as incident history and is now resolved by
explicit, exact historical-loss governance. Three rejected, non-reusable binaries
remain lost; no binary was rebuilt, substituted, recovered or approved. The
immutable authority is `docs/quality/CURSOR-BUY-ARTIFACT-RETENTION-20261002.json`,
SHA256 `70F6FE4BAB84B29D9A0C323B6B48CC2CFC2515E25761431AEF2F69E186138370`.
Original registry evidence paths and rejection/provenance records remain intact.
The memory gate allows exactly five consuming references to these three lost
artifacts, validates independently pinned original evidence, rejects changed or
wrong restored identity and current-candidate collisions across accepted roots,
and grants no build, install, promotion or release authority.

The external executed cleanup plan remains retired: `-Apply` refuses execution.
Its inline reference-aware guard matches the tracked source, protects audit roots
and ancestors containing evidence, and verifies every current registered active
root before deletion. No cleanup was executed. Final external SHA256:
`90D2D59DCA7CFF509536EBE022BC3EE31B6DF57AB982776D3367197521653CA3`.

Final verification: 39 checks passed on each of PowerShell7.6.6 (session18292,
exit0) and Windows PowerShell5.1.26100.9444 (session99382, exit0); six files passed
syntax parsing on each. Actual implementation memory gate session48580 closed0:
4618 entries,2552 applicable,3 retired artifacts,5 exact consuming references.
Architect excerpt review found no remaining checkpoint blocker after its
ancestor, complete-root-inventory and cross-root candidate findings were fixed
and tested. Earlier trials remain historical and do not qualify final source.

Application source/test diff against T06 `ee258a5e` is zero; its source fingerprint
remains `7aa0f6ed1d5916996b63c2ba49a835b06007dfc5b19c51dc831e6497e4b5ed0d`.
A09 remains authorized, in_progress, reproduced, and locally/device unqualified.
Only its premature selected test reservation is deferred for this maintenance
checkpoint; all983 existing T06 references stay selected. Reselect and qualify
A09 during actual T07 runtime work. No T07 runtime fix, Redmi attempt, live
integration or formal ticket closure is claimed. Required final precommit and
ordinary prefixed commit/push follow; then resume T07 under fresh gates, not T08.
Backend remains deferred; workspace mapping is Codex after integration. Google,
Maps, T03 supplier-policy work and the historical0e90a6ca handoff blocker remain.

Durable final verification transcripts:

Host 7.6.6; closed session18292; exit0; original log SHA256 `3d6f6a1635ac59ab95c9606c26b6c2fd3bc601971b4672b14cc88693a511f978`.

```text
PASS maintenance rejects wrong Role
PASS maintenance rejects wrong Task
PASS maintenance rejects wrong ClaimTask
PASS maintenance rejects wrong ClaimRole
PASS maintenance rejects wrong Root
PASS maintenance rejects wrong Branch
PASS maintenance rejects wrong Lane
PASS maintenance rejects wrong WorkId
PASS maintenance rejects wrong TicketId
PASS maintenance rejects wrong Phase
PASS maintenance rejects wrong Owner
PASS maintenance rejects wrong AuthoritySha256
PASS maintenance rejects wrong GenerationVerified
PASS exact three historical artifacts / five consumers; unlisted evidence denied
PASS current candidate references retired artifact without registry or contract changes
PASS absolute current candidate references retired artifact under another accepted evidence root
PASS changed registry path / unused retirement
PASS changed registry consumer identity
PASS missing retirement authority document
PASS tampered retirement digest
PASS tampered retirement duplicate
PASS tampered retirement extra
PASS tampered retirement current-candidate
PASS tampered retirement deletion-evidence
PASS changed independent original provenance
PASS present binary with wrong identity
PASS present same-size binary with wrong checksum
PASS cleanup protects registry/manifests/audit roots and permits ordinary generated candidate
PASS recursive ancestor protects referenced evidence outside audit roots; sibling remains eligible
PASS recursive ancestor protects unindexed review candidates
PASS cleanup inventory outside authorized workspace
PASS live registered inventory includes production and active roots, excludes explicit inactive removal
PASS missing active snapshot inventory
PASS mismatched active snapshot roots
PASS active root omitted from both snapshots
PASS newly registered active root after capture
PASS unchanged active snapshot
PASS active HEAD changed during cleanup
PASS active status changed during cleanup
Artifact evidence retention tests passed: 39; fixtures retained: C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921\apps\mobile\build\artifact-retention-tests-9d7ae9e49ef7434a870eb3d0aeea31c2
VERIFIED host=7.6.6; syntaxFiles=6; cleanupExecuted=false; exit=0
```

Host 5.1.26100.9444; closed session99382; exit0; original log SHA256 `abf12a6b2b09bfa27d89b832e7ccd44ef0221a611a48e76cfe0aa8046a05d615`.

```text
PASS maintenance rejects wrong Role
PASS maintenance rejects wrong Task
PASS maintenance rejects wrong ClaimTask
PASS maintenance rejects wrong ClaimRole
PASS maintenance rejects wrong Root
PASS maintenance rejects wrong Branch
PASS maintenance rejects wrong Lane
PASS maintenance rejects wrong WorkId
PASS maintenance rejects wrong TicketId
PASS maintenance rejects wrong Phase
PASS maintenance rejects wrong Owner
PASS maintenance rejects wrong AuthoritySha256
PASS maintenance rejects wrong GenerationVerified
PASS exact three historical artifacts / five consumers; unlisted evidence denied
PASS current candidate references retired artifact without registry or contract changes
PASS absolute current candidate references retired artifact under another accepted evidence root
PASS changed registry path / unused retirement
PASS changed registry consumer identity
PASS missing retirement authority document
PASS tampered retirement digest
PASS tampered retirement duplicate
PASS tampered retirement extra
PASS tampered retirement current-candidate
PASS tampered retirement deletion-evidence
PASS changed independent original provenance
PASS present binary with wrong identity
PASS present same-size binary with wrong checksum
PASS cleanup protects registry/manifests/audit roots and permits ordinary generated candidate
PASS recursive ancestor protects referenced evidence outside audit roots; sibling remains eligible
PASS recursive ancestor protects unindexed review candidates
PASS cleanup inventory outside authorized workspace
PASS live registered inventory includes production and active roots, excludes explicit inactive removal
PASS missing active snapshot inventory
PASS mismatched active snapshot roots
PASS active root omitted from both snapshots
PASS newly registered active root after capture
PASS unchanged active snapshot
PASS active HEAD changed during cleanup
PASS active status changed during cleanup
Artifact evidence retention tests passed: 39; fixtures retained: C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921\apps\mobile\build\artifact-retention-tests-d5b14bcec64346449682fcfa57e83a71
VERIFIED host=5.1.26100.9444; syntaxFiles=6; cleanupExecuted=false; exit=0
```


## T07 frontend qualification and Cursor-owned checkpoint — 2 October 2026

This section supersedes the earlier T07 pending-runtime notes while preserving their admission and artifact-loss history. Cursor branch `work/cursor-ui/buy-ready-20260921` starts this checkpoint from remotely verified retention commit `1a66f12c4153d98962cc639945af215d44b1d7c1`; T06 remains `ee258a5e0dea49bf5d62286e6cc8c21f9ae416cd`.

T07 frontend recovery and A09 are implemented and locally qualified at source SHA-256 `be62e47d9a84488e5703e4abf1c38353dad36e340a16985a8bae0221599e3a24`. Original request, amount, owner and allocations are frozen and durably saved before submission. Uncertain/incomplete retained attempts cannot authorize new Pay; confirmation and financially closed retry must match original facts. A09 retains the submitted32 amount after current-cart coupon expiry. Both complete frozen historical instructions and genuinely key-only older snapshots have truthful regression coverage.

- Analysis: seven affected Dart owners clean, session64850 exit0.
- Affected:141 passing cases, including69 T06/T07 cases; session84244 exit0.
- Selected:965 distinct passing cases,1025 selected references,53 files; batches445/468/52, session27365 exit0. Closed logs show unchanged source and zero failures/warnings.
- Immutable contract: `CURSOR-BUY-T07-RECOVERY-20261002-CONTRACT.json`, SHA-256 `c7f7f1d3c12e6755baf4ffc9aba7f0cf1f0c4078a5fc1d3857bc073dde936d8a`.
- Durable report: [T07 evidence](CURSOR-BUY-T07-RECOVERY-20261002-EVIDENCE.json), SHA-256 `66cb0d1b8a1134e2dd7512d092b2882e3588d051573d71192ead876bca4f9175`.
- Durable archive: [T07 receipts and screenshots](CURSOR-BUY-T07-RECOVERY-20261002-EVIDENCE.zip), SHA-256 `105c621179c2b04e0075b2120d38195159113453f83ae798ee83da3e16730751`,133 members. Raw attach/session material is excluded. Failed/superseded trials remain separately retained and do not qualify the final source.

Redmi TG8HCYTGGQT885OF used the existing `com.moolsocial.app.cursorreview` r66.36 package. Full hot restart session11934 closed exit0 at the qualified Dart source. Mixed Cart/Checkout retained2 products/3 items/837 through navigation at normal and200percent text. One shared optional delivery note remains; Clear appears only inside its composer, and cancelling the keyboard draft retains the saved note. Payment method navigation was checked without starting payment. Font scale restored1.0. Installed APK SHA-256 remains `7D2E95B6A3D7BE9136457D9103DBF262CECA306788C904E4170E85F16F70C4D5`; this authenticates the retained package, not the refreshed Dart source. No APK build/install, native recovery-fixture injection or live Pay occurred.

A09 local display recovery is verified; original-key real-provider recovery remains unverified and integration-pending. Existing A09 stays in_progress with device recovery evidence null. Backend is deferred. Workspace original-key lookup, financial retry permission, late settlement and original-key support handoff remain **Codex after integration**. Google/Maps and T03 supplier-policy acceptance remain separate. The observed Wholesale minimum-order trailing separator/semantic punctuation is recorded for existing T10 visual polish.

Historical retention hold is resolved at1a66f12c without recovering or substituting lost rejected binaries. The original failure/deletion/rejection evidence remains preserved. Founder visual approval is pending. Formal handoff/ticket_close remains unclaimed because historical commit0e90a6ca lacks the required subject prefix; no history rewrite or gate weakening is authorized.

Required pre_commit, ordinary scoped feature commit/push and clean exact remote readback follow this evidence capture. Their actual closed results are retained in the post-checkpoint receipt; this narrative does not pre-claim success. Stop before T08.

### Founder-directed time and credit arrangement for this Cursor task

This ongoing turn started with a recorded GPT-6.1 Sol/Extra High (`xhigh`) context; saved shared user defaults are GPT-6.1 Sol/High with auto_review/on-request. Host approval policy is currently never, distinct from the saved default. No project config, selected profile, default-subagent-model override or model/reasoning flags were found in the inspected current launch ancestry. Saved roles already use explorer/researcher Luna/Medium, worker Sol/Medium and architect Astra/High; existing task spawns match those scoped review roles.

Retain shared defaults and other lanes. Prefer Medium for well-defined implementation and final metadata/checkpoint work; escalate only for unresolved architecture, concurrency or difficult debugging, then return to Medium. Keep the same tests, ownership and acceptance gates. Use a small group for useful independent review, root as sole current editor, and avoid duplicate exploration/testing. The founder's new instruction applies this task guidance now; it does not itself change the active reasoning control. The founder subsequently supplied a screenshot showing GPT-6.1 Sol/Medium selected in the Cursor composer. There is no newer turn_context record yet; the existing turn-start log is not a live reading of that picker. Retain the selection and verify a fresh turn record when available; no automatic mid-turn switch or configuration repair is claimed.

Sources: [model/reasoning selection](https://learn.chatgpt.com/docs/models#choose-a-model), [subagent settings](https://learn.chatgpt.com/docs/agent-configuration/subagents#choosing-models-and-reasoning), [configuration precedence](https://learn.chatgpt.com/docs/config-file/config-basic#configuration-precedence). This audit covers the Cursor-owned lane; no separate Store worktree or shared configuration was modified.


## Supplier policy moves to Product/Add — frontend qualification, 3 October 2026

Current founder instructions supersede old Stop before T08 wording for the next frontend Cart subjourney within the same open Buy parent. Live-provider recovery stays deferred; T07 recovery history and A09 in_progress/device-null status remain intact. Current checkpoint starts from remotely verified T07 commit34122f2950758476c86719f07684fe42773712fe on work/cursor-ui/buy-ready-20260921.

Published supplier policies are removed from Cart. Product shows the exact Store policy when published; only an authoritative acceptance-required decision opens an unchecked consent sheet on Add. The tick saves the current buyer/Store/policy fingerprint and adds the frozen quantity once, with no separate completion tap. Missing/expired/mismatched/changed required policy, failed persistence, duplicate actions, cancellation and account changes cannot add. Required displayed-intent identity prevents an old A callback accepting replacement B. Existing financial amount/advance/balance/due-date agreement remains behind compact Checkout Order approval/Review; payment validation is preserved.

Final source SHA-256: 6716bfc67ba6a9b22c9f3770e9a3ec02e369a13ddd00987ad1fc5839113bbd19. Analysis of seven owners is clean; consent18 and financial26 (6 UI plus20 controller/correlation cases) pass. Final selected983 distinct cases/1043 references/53 files and affected141 pass with unchanged source, zero failures and zero warnings. All selected local receipts bind the new immutable JSONL evidence. New policy device-acceptance fields and A09 device recovery stay null.

Redmi TG8HCYTGGQT885OF used a full hot restart of this final Dart source with the retained com.moolsocial.app.cursorreview r66.36 package. Settled native Cart2products/3items/837 and Checkout837/shared Call on arrival remain intact; Checkout is reachable. Normal/200percent order-review action is visible and has positive accessibility bounds; Back returns without changing Cart. Font restored1.0 and installed APK SHA-256 remains7D2E95B6A3D7BE9136457D9103DBF262CECA306788C904E4170E85F16F70C4D5. Package checksum authenticates the existing APK, independently of hot-source fingerprint. No new APK/install, native fake supplier policy, financial agreement issuance or payment occurred. Native policy acceptance cannot be claimed without an authoritative Store producer; the conditional popup is tested in isolated nested host fixtures, portrait/landscape and enlarged text.

Contract: CURSOR-BUY-SUPPLIER-POLICY-20261003-CONTRACT.json (ca39d72592a86151dc152e6d3b747b77ae5010998fd9066850a0fa66dde58e0d). Report: CURSOR-BUY-SUPPLIER-POLICY-20261003-EVIDENCE.json (d753fe1425e910ce5732ed947f5c29ef53def9b8e26cbdad4453be98db2ae196). Archive: CURSOR-BUY-SUPPLIER-POLICY-20261003-EVIDENCE.zip (9b99f4d350a9e2777cf7763bef0d77770219a665cb4fb9cc834d7f7fb738548e; 200 members). Failed/superseded trials, rejected patches, initial splash/null-root dumps and route-transition frames remain history; they do not qualify the source. Raw attach/VM-session logs are excluded. Architect reviewed supplied exact concurrency/modal excerpts, identified stale callback binding, and confirmed the displayed-intent fix after its direct callback regression; no seven-file independent diff review is claimed.

Backend is deferred. Store/workspace policy publication, receipt consumption/enforcement and original-key recovery mapping remain Codex after integration. Google/Maps remain separately listed. Existing T10 owns inherited Wholesale minimum-order trailing punctuation. This UX is conditional on actual published requirements, not a claim that Indian law mandates a popup on every Add.

Evidence checkout child: existing Git core.autocrlf conversion changes raw JSONL hashes on fresh checkout (T07 selected1 raw61add0fe versus checkout-filteredbb04c89b). Authentic original receipts remain preserved in Git blobs and the hash-verified ZIP, including raw contract bytes. Correct checkout evidence handling during integration without weakening byte/hash checks; no shared Git settings or historic proof files changed here. This is an open Codex-after-integration child, not lost evidence or current-worktree test failure.

Founder visual approval and live integration are distinct from local technical qualification. Historic0e90a6ca subject-prefix/formal ticket_close blocker remains; no history rewrite, gate weakening, formal closure or production promotion is claimed. Required fresh memory/pre_commit gates, scoped commit/push and exact clean remote readback must close after this evidence capture; no success is pre-claimed here. Next authorized frontend subjourney: T08 order status and later balances, with fresh scope/admission after this safe checkpoint.


### T08 Orders and later balances — scoped frontend qualification, 3 October 2026

Founder continuation selects T08 inside the same open Buy parent/lane after clean remotely matched8499799a. Actor: Buyer, mvp_required. Reuse existing Orders/detail views and order/payment fields; no new screen, service, model or backend. Changed runtime/test owners: buy_v2_views.dart and buy_v2_checkout_cart_return_continuity_test.dart. Source SHA256 d1621fe1c19f578cb2eb4e9e03a511ec5db75ec6c6bc9c1b58b12c8dd13a9caf.

Each delivery order now shows its own supplied payment status and remaining balance. Existing balance-result state overrides stale labels/amounts. Missing status is unavailable; pending/unknown zero never establishes payment. List has no payment action; Collection cards and detail financial actions unchanged. Supplier policies remain Product/Add only.

Closed analysis exit0; two mixed six-state cases at1x/2x text passed; required985 distinct cases/1045 selected references passed across53 files. Evidence docs/quality/CURSOR-BUY-T08-ORDERS-20261003-EVIDENCE.json SHA256 90eeb5b63ef9f831e1bbdb316daa815c3886bd43b3828d581d98bf725193dec1; contract SHA256 b004ef4e9c403d48e2d8213992b2fa7fc131fac9f36d711d48f24778c6bd5959; archive SHA256 4b628b7bbbd0419ab7136e016c60c6e9589ff904ad14d90ce1dec7f77c9de94b, verified 106 members. Raw JSONL Git-blob hashes must remain authentic; archive preservation does not qualify fresh-clone byte conversion.

Actual Redmi full restart with existingr66.36 APK checksum unchanged; Orders normal/200percent/scrolled, legacy MS-NEW-12 COD detail and Back verified, font1.0 restored. No order/payment/financial issue submitted. Native legacy orders correctly show unavailable payment status. Supplied paid/advance/pending/settled/later balance states are isolated host-fixture evidence, not live acceptance.

Broader affected suite FAILED:219 passed,25 distinct failed test names reproduced at exact baseline8499799a with identical assertion bodies. Original assertions/logs retained as an open legacy-test verification child; do not call the wider suite passing. Future live balance enablement is blocked on current account/order correlation, identity clearing, late callback rejection and fresh zero-balance validation. Current runtime has no adapter injection or map restoration path; the existing getter alone does not prove account freshness. Backend deferred; workspace Codex after integration; Google separate. T10 repeated Payment prefix copy-polish child retained.

Founder visual approval, live integration and formal closure remain pending. Historic0e90a6ca subject-prefix blocker and checkout-evidence portability child preserved. Fresh memory/pre_commit, scoped ordinary commit/push and exact clean remote readback follow this capture; no success pre-claimed. Stop this sweep at safe checkpoint. Next T09 replacement/refunds requires founder continuation and fresh scope/admission.


T08 generated-metadata staged-byte correction — 3 October 2026

The original generated contract/report used Python Windows CRLF and were superseded before commit because staged hashes differed. Their authentic raw UTF8 bytes and checksums remain in EVIDENCE.json metadataStagingRepair. Current contract SHA256 d53189ab00ac498329975b31990b918c4f79e7c59e5aab74f236cb15a52c399d; current evidence report SHA256 9e5429c190b9e9ca49930b3fdf469adcd062906f83eccd003f53bdab6ad72410. Four raw closed JSONL receipts and immutable106-member archive remain unchanged. Explicit UTF8LF writing fixes generated metadata only; no Git configuration, source/test or raw-evidence hash checks changed. Fresh staged-byte verification and memory/pre_commit/checkpoint still required; no success pre-claimed.


### T09 replacement/refunds — scoped frontend qualification, 3 October 2026

Founder continuation selects T09 under the same open Buy parent/lane after clean remotely matchedc4959047. Buyer, mvp_required. Reuse buy_v2_views.dart, buy_v2_session.dart and existing buy_v2_order_resolution_test.dart; no new screen/service/model/provider/storage. Final source SHA256 9e75eb05f199f354e26ec99a12e1958e4b63c910bb5639c1145283048b330e8f.

Matching order detail and reopened ready resolution sheet show Request received, server-supplied message and selectable reference. Eligibility refresh preserves accepted in-memory receipt and clears rejected feedback. Refund/replacement completion is never inferred. Supplier policies stay Product/Add only; no Cart terms.

Analysis three owners exit0; eight focused refund/replacement accepted/rejected cases at1x/2x passed. Required993 distinct cases/1053 references across53files passed. Broader order/support run129 passed, two existing optional founder capture cases skipped; no full-suite qualification claimed. Inherited25 legacy Checkout failures remain open.

Redmi existingr66.36 package fully restarted at final source, unchanged installed checksum verified. Delivered order → replacement/refund with unavailable eligibility → read-only check again → Back detail/Orders tested at1x/2x; font1.0 restored. No financial request/support message/payment/order/build/install. Accepted response screenshots are isolated host fixtures, not live acceptance. Initial debug attach timeout and corrected parse/test-harness/eligibility-refresh failures retained. Raw session-specific attach logs remain ignored and excluded from archive.

Evidence docs/quality/CURSOR-BUY-T09-REFUNDS-20261003-EVIDENCE.json SHA256 4e0d1b4c1e4f5e5795f7587cbef94fa38eeff518b2767f1a9bb44220eacf6cba; contract SHA256 05d0dd50871a4690a7e82abc855c1f75004a9d7ddace6e25c4058dc9845a03e5; archive SHA256 06c37b96918e1203dd6934dd8053770341dab433898dfed7706faa21ac32f0be (196 verified members). Generated JSON uses explicitUTF8LF; immutable raw JSONL Git blobs require exact staged/commit SHA readback. Fresh-checkout conversion child remains open.

Backend/provider deferred; workspace Codex after integration; Google separate. Before live resolution enablement prove account/order/request correlation, identity clearing/late response rejection, duplicate prevention/reconciliation and accepted history retention. Latest in-memory receipt only; restart persistence unqualified. Preserve T08 live balance hold, historic0e90a6ca formal-closure blocker, legacy verification and T10 visual polish children. Founder visual approval pending.

Fresh memory/pre_commit/scoped ordinary commit/push/clean remote readback follows this capture; no success pre-claimed. Stop at safe checkpoint. Next T10 requires founder continuation and fresh scope/admission.


### T10 Cart visual/technical journey audit — 3 October 2026

Founder authorized actual Cart audit, listing defects then implementing within same open Buy parent/lane. Actor Buyer; mvp_required. Baseline30961fa92fd7f7f8ca619a6d8b27755cdad8335c; final source SHA256 6c35cbaec4bc375014f9bc4f6eb1ffb878032f84be105a1ad4383a36afba7bfd. Existing views/catalogue/session and checkout_cart_return_continuity test reused; no new screen/service/model/provider/storage.

Listed and registered before fixes: misleading Cart quantity/Empty controls; misleading catalogue Add; hidden recovery context; guarded instruction entry/chips; guarded benefit/tip callbacks; disabled Add/quantity pointer reaching product-card navigation. Shared existing session hold now drives disabled UI, explicit disabled semantics and pointer handling. Cart shows a persistent reason and Review payment navigates existing attempt. Supplier policies remain Product/Add only, never Cart. One standard public instruction for shared address; Clear remains composer-only.

Analysis four owners exit0. Four focused cases1x/2x passed: held Cart explanation/disabled quantity/instruction/empty, original attempt/amount retained, catalogue Add accessibility/pointer and quantity pointer; fresh Shop+Wholesale actual quantity edit/instruction Save/Checkout Back total retention/clear cancellation then confirmed empty browsing. Required997 distinct/1057 references across53files passed at final source. No full legacy Checkout suite qualification; inherited25 failures remain open. Existing protected-reference tag warnings retained; layout/hit warnings zero. Failed test selectors/vertical-scroll/harness cleanup and actual pointer regression discovery preserved in immutable archive.

Redmi unchanged installedr66.36 checksum verified. Cold reload and one bounded warm mtime-only retry each reported Reloaded 0 libraries; new Cart markers absent. Source bytes unchanged, mtimes restored. NATIVE ACTIVATION CHILD OPEN: fixed-source normal/200percent/disabled-pointer/fresh journey unqualified. Existing old Cart→Checkout→Back confirms original unavailable payment and one tomato/37 rupees retained; phone left existing held Cart, font1.0. No full restart/reset/build/install/payment/order/support submission. Stop retries; verify supported activation and authentic attempt persistence before full restart or a separately authorized candidate. Fresh mixed/empty native journey unqualified; isolated host proof separate. Some host labels render glyph rectangles; no production-identical rendering claim. One native XML harness assertion corrected because Original total and37 amount are separate nodes; actual original capture preserved.

Evidence docs/quality/CURSOR-BUY-T10-CART-AUDIT-20261003-EVIDENCE.json SHA256 fe89078b41743d9484d980544a64f86c74a569587d93d44102050b9f940d8a18; contract SHA256 847be494b9cc24b65c4c90de89ff2e96c5142e5a1132632e59eb931c7488cae1; archive SHA256 1e8d2cfe2cb77ffc40690ec4a66647596260799c3b0debcb56b6ade072cbd47b (192 verified members). Generated JSON UTF8LF and raw logs preserved byte-for-byte; fresh-checkout conversion remains an open child. Session-specific attach/VM logs excluded.

Backend/provider recovery deferred; workspace Codex after integration; Google separate. Require original attempt/account correlation, unknown/pending reconciliation/duplicate prevention, identity clearing/late callback rejection and fresh quantity/price/availability/terms before live enablement. T08 live balance, T09 live request persistence, historic0e90a6ca formal closure and founder visual approval remain open.

Fresh staged-byte readback, memory/pre_commit, ordinary scoped checkpoint/push/clean remote equality follows; success not pre-claimed. Stop after checkpoint.


### T10 founder-rejected Add and Cart navigation regressions — 3 October 2026

Founder requests fresh journey through last available frontend screen, reproduction/fix of Add appearance and wiring, selected Cart, persistent Cart access and Product return, plus00:35–14:35 IST Git preservation audit. Existing Buy parent/owners reused; global navigation/Store/backend/native package untouched. Baselinec1122992; final source SHA256 611eb5916fc050425c2a44286f906f993828ef4a9bde87f64bd7fef68e7c5700.

Cart remains reachable across public Buy with items, including Cart/Checkout; Shop/Wholesale/Offers origin is no longer marked current while Cart is active. Repeated Cart taps preserve scope/Product return; Checkout Cart uses existing scope. Existing Add face colors/shape preserved; blanket held opacity removed. Held pointer explains the central guard without quantity/payment mutation. Disabled Empty icon muted. Supplier policies Product/Add only, never Cart; shared-address instruction and composer-only Clear unchanged.

Native mixed target discrepancy3/1197 versus Wholesale2/1160 fixed: active mixed Cart/Checkout now summarizes whole basket; discovery keeps its scope. Seventy final-source screenshots cover two repeated mixed route sweeps and fresh standard Empty→actual Add→tabs→Product/Cart/Checkout→Cart at1x/2x. Full Dart restart response0/detach/process0 verified after independent original-held and fresh3/1197 snapshot preservation. Visible glyph and badge inspected together with selection/tap destination; earlier warm-reload glyph absence did not recur, original cause unproven. Inline shared instruction composer and keyboard checked separately; Clear only in editor, Cancel without mutation, one-item37 Cart retained. A subsequent capture observed two-item97 Checkout; transition origin awaiting founder clarification, device actions stopped without inferring user action or app defect. Font1.0 restored.

Seven-owner analysis exit0; ten focused cases1x/2x and1003 distinct selected cases/1063 references across53files passed at exact source. Original held guard/amount/request assertions retained; no full legacy Checkout suite claim. Six new cases registered under existing parent. Closed raw logs/ZIP hashes verified; no gates weakened.

Twelve critical checks, including all ten active selected golden cases, passed before the final selected run. Seven Cart/Checkout images remain draft/founder approval pending; original founder references unchanged. Checkout badge correction is1→4 for fixture Shop1+Wholesale2+Care1, while selected Checkout stays1/37; two Cart references reflect corrected navigation. Drafts were staged before qualification to include their bytes in the source fingerprint. Native activation fingerprint fa0816989c400d50a71ccdc1e4966cf656206533bc9f567804b2bbb3af6114ae differs only by two test-reference paths and seven new draft PNGs; exact reconstruction proves runtime code/assets/Android/pubspec unchanged. Both draft generations and all failed/partial run evidence retained. Process gap recorded: draft references predated final aggregation change. New evidence receives six exact LF attributes and staged/checkout-filter SHA verification; inherited portability child remains open.

Git14h audit: four ordinary commits/reflog entries (supplier policy,T08,T09,T10), all retained; c1122992 exact origin readback before edits. No uncommitted/ignored runtime or test source found; only2 current admission metadata changes existed. T06/T07 and all subsequent checkpoints ancestor-confirmed. Handoff Git content preserved; one handoff working CRLF hash differs from its committed blob with identical normalized content, recorded separately from raw-byte qualification.

Original review37 pending payment preserved with exact owner/key/frozen request/live identity, review adapter, no pending writer and same-key unchanged-value restoration/readback verified. Removed only isolated device-review Buy key then full Dart restart; no app-wide clear, credentials copy, fixture injection, APK build/install or real financial action. Fresh and held evidence remain separate. Native fresh Add/tabs/Product→Cart→Back/Checkout→Cart at1x/2x recorded; font1.0 restored. Settled fresh and mixed Cart start with selected items at top; host new-Add reset independently passes. Earlier recommendation-offset cause unproven; no runtime scroll edit. Held original native status: Original37 exact snapshot preserved separately, host held guard proof; native held restoration/replay not yet performed

Evidence docs/quality/CURSOR-BUY-T10-NAVIGATION-REGRESSIONS-20261003-EVIDENCE.json SHA256 f3fbb36576cbd4df18cc17137dfa8ab302ea51471abca531c2d81ecbaf8e9f9c; contract SHA256 709db2501147ffaeec8740010aeb3338c9e025e4ba8beb4e40f0de27d07f9ce9; archive SHA256 4b90e13b193027dc7af6d4a89de399c6702f98d3b008b04282a11f88b2bceeca (788 verified members). Private attach/VM logs and raw customer-state snapshots excluded; their local originals remain intact. Earlier native-activation limitations remain immutable in their old T10 records; current evidence supersedes only the new sweep's verified claims.

Backend/live-provider deferred; workspace Codex after integration; Google/Maps separate. Existing legacy25 failures, raw evidence checkout conversion, T08 live balances,T09 live resolution persistence, historic formal closure and founder visual acceptance remain open. Fresh original-key/account freshness and duplicate-payment safeguards remain integration prerequisites. The last frontend screen is Checkout review before payment/order submission, not a live end-to-end order acceptance.

Fresh native coverage does not qualify held native replay or unavailable conditional supplier-policy popup fixtures; their host checks are recorded separately. Catalogue/Offers blue corner marker provenance remains a scoped follow-up.

Actual staged-byte check,memory/precommit, ordinary scoped checkpoint/push and clean exact remote readback follow; no Git success preclaimed. Stop at safe checkpoint.

Pre-commit correction: memory passed, but the first pre-commit attempt rejected seven draft PNGs absent from the affected-route owner list. The exact seven existing draft paths were added to the same Buy parent; no gate logic, runtime/test/image bytes, selected cases or thresholds changed. Failed gate logs remain preserved locally; final gates must rerun and close successfully.


### Founder-selected frontend-first sequence — 3 October 2026

Founder explicitly chose Option1 and said go ahead: complete the connected Buyer frontend from Add/Cart and Checkout through Confirmation, Orders, delivery/collection progress and Delivered; keep backend/workspace/Google dependencies deferred and integration hooks ready. Then execute Option2 as one end-to-end real-user audit, not repeated disconnected Cart sweeps. This continues the existing open Buy parent/lane, not formal ticket closure or build/payment authority. Starting clean remotely matched checkpoint2aefc200; source611eb5916fc050425c2a44286f906f993828ef4a9bde87f64bd7fef68e7c5700.

Reuse/selection: T11 existing commercial terms, quote/payment eligibility/group placement/recovery/balance interfaces and public Confirmation/Orders views; T12 existing order-resolution, provider refresh and supplier attribution; T13 existing Tracking/live-delivery/collection/exception/itemised-receipt owners; T14 frontend qualification. Classification mvp_required: correct connected purchase and fulfilment outcomes. No duplicate screen/route/service, Store/workspace implementation, new dependency, live backend, Google/Maps activation, APK, release, real payment/order/support request or fabricated successful delivery. Supplier policy stays Product/Add only; instructions stay shared-address and Clear only in composer.

First executable T11 gap: refreshOrder keeps a pre-await list index and lacks post-await owner/account freshness checks. Existing T08 integration hold already records this risk. Smallest correction reuses BuyV2Session and existing order_progress tests: bind refresh to original owner/identity generation and immutable order identity; re-find its current index after await; reject account/disposal/list-removal drift without corrupting a different order or clearing a newer owner's busy state. Register delayed-response reproduction and verify positive unchanged-owner/index-shift refresh, mismatched response, identity change and disposal. Existing payment hooks remain authoritative; no arbitrary new provider interface invented. Further T12/T13 changes require concrete gap inventory and bounded assessment before editing.

Queued Option2 acceptance matrix: fresh Shop-only, Wholesale-only and Offers-origin purchases separately, then Shop+Wholesale, Shop+Offers, Wholesale+Offers and all-three mixed Cart. Offers is a discovery origin, not a fabricated fulfilment supplier/channel. For each, actual Add, correct listing/pack/MOQ, quantity/removal, display filter versus checkout scope, exact totals/offers, Cart visibility/current selection, Product/Cart/Back, Checkout/Confirmation, correct Store orders, Tracking/Delivered and returns/help where provided. Inspect all reachable wording/labels/hints/semantics, redundant or irrelevant text, geometry, keyboard, normal/200% text, retained/reopened data and recovery. Register actual visual/technical/copy defects before retry/fix. Isolated provider outcomes are labelled frontend fixtures; unavailable live provider is a deferred dependency, never a production success. The unexplained Cart1/37→Checkout2/97 observation remains open for this audit.

Dependency ownership: backend deferred; workspace provider/Store/allocation/delivery implementation Codex after integration; Google location/Maps/source/key/permission listed separately. Native fixture review, host qualification, founder visual approval, installed-APK persistence and live acceptance remain separate. Completion records exact source, screens, checks, unresolved children and safe ordinary scoped Git checkpoint; no formal historic closure bypass.


### T12 frontend supply/refund and replacement-consent assessment — 3 October 2026

Actor Buyer; capability inspect authoritative per-order supply/refund progress and choose a changed replacement offer without repeating Cart, address, Checkout or payment. Outcome remains provider-confirmed supply/refund, never confirmation inferred from a local consent tick. Classification mvp_required: these are explicit T12/T09 connected-journey outcomes. Founder frontend-first authorization applies; backend/workspace implementation stays deferred.

Reuse existing BuyV2Order optional progress data, commerce refresh, resolution adapter capability, Orders/Tracking presentation and order_resolution/order_progress tests. Existing resolution request receipt cannot express later allocation/refund or version-bound replacement consent. Add an optional typed provider snapshot in existing model owner and an optional distinct resolution-adapter consent capability; no new service, route, backend, deadline, source credentials, new payment or seller-settlement calculation. Bind snapshot to order/purchase/source/revision, exact purchased lines/quantities and original customer amount; unknown quantities remain pending. Refund status/route/amount/reference come from provider; refunded requires an authoritative reference. Changed replacement displays exact provider proposal and expiry and consent targets that offer/version. Receipt acceptance is not delivery/refund success. Server atomically validates owner, freshness, duplicate identity and exact original agreement after integration.

Source owners: apps/mobile/lib/features/buy/buy_v2_models.dart, buy_v2_session.dart and existing buy_v2_order_resolution_contracts.dart (exact ownership must be admitted before its edit); public apps/mobile/lib/ui_v2/buy/buy_v2_views.dart. Focused test owners existing buy_v2_order_resolution_test.dart and buy_v2_order_progress_test.dart. Preserve supplier policy Product/Add only and existing Cart/payment identity. Keep missing capabilities unavailable and honest. Validate quantities/correlation/money/stale offers, duplicate taps, exceptions, account changes/disposal, normal/200% layouts and current public status. No review-provider fixture enabled in production. Frontend fixtures prove contract behavior only; live Store allocations, original-route refund settlement and actual-seller invoice mapping are deferred Codex after integration; Google remains separate.

T11 source qualification is frozen before this execution. Do not change runtime/test source while its selected run is open. Further T12 source edits require the refreshed exact ownership/memory/MVP gate and a T11 safe checkpoint; this assessment is planning, not a claim of implementation or acceptance.


### T11 order-refresh qualification — 3 October 2026

Final local worktree source0efb09b11f6f8b892dd0433550ae6ec0b96bf9dece9811f0c8db8e0e7df260f0. Before fix7/11 delayed-response cases failed; final12 targeted cases and115 order/tracking cases pass; analysis zero issues. Fresh frozen cumulative runner passed1015 distinct cases/1075 references across54 files in378/362/275 batches, zero errors/warnings, stable registry/policy/ledger/source pins throughout. Exact file-and-name mapping independently checked for every1075 reference. The interrupted stale-generation run remains diagnostic only, with its process-tree stop and original logs preserved. All newly encountered metadata/parser/admission mistakes remain registered; original founder scenarios were proved unchanged.

Evidence report 511d8547b54c9e3bbe535578e7d04633e15bfb790bd8744c41a9812d275fda7f; archive 424d961e2be3972c7e77ff59622cddfa47cadf7034dc48f78cf9b076caa59d7f contains32 verified original members, including failed reproduction, diagnostic run, fresh admission/pins and successful machine logs. Three selected receipts and focused log are tracked with LF attributes. The two source owners have recorded tested working and expected LF checkout hashes; staging must prove any difference is CRLF→LF only. Current host worktree qualification is not independent clone/integration, Redmi, founder visual, installed-APK persistence, provider/payment or formal historical ticket closure. Backend deferred; workspace Codex after integration; Google separate. Prior unexplained Cart1/37→Checkout2/97 remains open.

Proceed through existing open Buy parent: T12 frontend provider supply/refund and replacement consent (bounded assessment above), then T13 fulfilment/collection and T14 qualification, then seven separate/mixed origin journeys. A suspected T13 partial-receipt/completed-history inconsistency requires reproduction before implementation. No supplier policy in Cart, no changed Add styling, no duplicate service/screen, no new APK/live transaction or another lane mutation. Safe T11 commit/push still pending machine pre-commit and remote readback.


T11 final-pin correction: focused derivative log was CRLF-normalized to LF with identical244 nonblank parsed JSON values; original raw bytes remain in the verified32-member archive. Raw SHAeeefda1a7e4161e8a26766c983ea47fe9715f328d98064c35ed81f2ecaf44ddd; LF SHA61964c18b5a44eb0ff312978b1623acc68f54db4840b4fb566485ff30bf472e4. Cumulative1015 run was already terminal before this metadata incident; its original stable generation is retained separately from refreshed final readiness. Current report SHA6861933f41d2aff5d9319651ea3c0e553c5b8dd0c45ed2df4a5dfb440b677b85. No runtime/test byte changed; fresh pre-commit gates required.

### T12 execution boundary and T11 checkpoint readback — 3 October 2026

T11 checkpoint4758b5b6f7f522b7b7d3049df2694618d45455e9 pushed and exact remote verified; qualification recorded above. Formal handoff exit1 rejects inherited non-atomic0e90a6ca; no history rewrite or formal closure. Existing open Buy parent implementation gate passes, current MVP and implementation memory gates pass; continue founder-authorized frontend substeps, not a new formal ticket.

T12 reuse amendment: exact admitted owners are buy_v2_models.dart, buy_v2_content_contracts.dart, buy_v2_session.dart, public buy_v2_views.dart and existing order_resolution/order_progress tests. The unclaimed order_resolution_contracts.dart stays untouched. Optional consent capability belongs in existing owned content_contracts; existing resolution adapter can opt in. No new route, service or dependency. Retail Shop delivery supply snapshots only; Wholesale operating rules and collection replacement remain integration-dependent. Validate order/purchase/source/version, purchased quantities, INR minor-unit amount, authoritative refund route/reference and unchanged original customer total. No entitlement/tax/seller settlement calculation. A changed offer requires fresh review, including changed contents with reused IDs. Missing provider is unavailable. Consent receipt never changes original invoice, payment, delivery or refund settlement. Account change/disposal invalidates pending responses; retries preserve exact decision identity. Backend enforcement and actual invoice mapping: deferred, Codex after integration. Google separate. Host fixtures and screenshots are frontend evidence; native acceptance remains pending.


### T12-T14 frontend and founder Cart defect continuation — 3 October 2026

Buyer / existing public Buy Cart and Shop order progress; mvp_required because editing, correct basket visibility, return navigation and truthful fulfilment/refund recovery support the connected launch journey. Continue the existing open Buy parent BUY-ACTION-POLISH-20260926-01 and Cursor ownership; this is not another formally closed ticket.

Reuse the existing Order model, optional content-contract adapter, session refresh/consent state and Tracking/Receipt views for T12/T13. The founder-reported Cart continuation reuses addProduct, the existing Cart display filter and Back handler, and existing ReturnAffordance. Exact changed runtime/test owners: buy_v2_models.dart, buy_v2_content_contracts.dart, buy_v2_session.dart, buy_v2_views.dart, buy_v2_order_progress_test.dart, buy_v2_checkout_cart_return_continuity_test.dart and buy_v2_scoped_cart_checkout_dock_continuity_test.dart, all under the existing apps/mobile Buy owners. No new route, state owner, service, dependency or production fixture activation.

Confirmed Redmi defects and result: Cart lacked visible Back; existing Back affordance added. Clearing Shop-filtered Cart then adding Wholesale retained Shop and hid the new lines; first successful public non-Medicine addition to an empty basket now resets display to All. Rejected additions and nonempty-basket filter choices remain unchanged. Original reported non-deletion was reproduced with paymentActionRequired/pending and disabled controls; do not remove legitimate payment holds. The original37 and pending395 review snapshots and the currentWholesale snapshot were preserved. Exact frozen request/key/quantities restored after restart, and isolated review-key restoration was proved before fresh review testing.

Latest native runtime source e8d227c80f072c0dc084bca0f05a1261412d328362ea4500b2f95c97134a74b6: exact session/views/screen VM source equality verified. Shop Add1/37, last-line removal, Shop-filter whole-Cart bin Cancel/Confirm, clear-to-Wholesale2/1160 filter fix, Checkout-to-Cart, Cart Back to Shop/Wholesale/Orders/Offers, Offers Add and mixed3/1197 Cancel/Confirm deletion all replayed with retained settled PNG/XML. Current mixed review screen is retained. No new APK/install; r66.36 remains installed, full Dart restarts activate source only. Canonical local source mapping to later test-only reference changes must be recorded separately; a successful attach alone is not activation proof.

Ten focused Cart tests and two targeted responsive Cart draft captures passed; 47 T12/T13 cases passed on their earlier frozen source. Final combined qualification remains pending at this note. Existing historical reference PNGs stay immutable. Two new T14 responsive Cart drafts capture the requested Back; their technical repeatability is not founder visual acceptance. The final evidence owner is docs/quality/CURSOR-BUY-T12-T14-FRONTEND-20261003.json, with original machine receipts and a checksummed archive; pending placeholders do not constitute passed evidence.

Keep backend deferred, workspace Codex after integration, Google separately listed. Live supply allocation, replacement effect/invoices, refund entitlement/original-route settlement and authoritative payment recovery require integration evidence. Keep the full seven separate/mixed Add-to-Delivered journeys registered pending their complete matrix and dependencies; scoped Cart replay does not close that matrix. Earlier unexplained Cart1/37-to-Checkout2/97 remains open. No supplier terms in Cart, no changed Add style, no public instruction Clear, no real transaction or other-lane mutation. Inherited non-atomic history still prevents formal ticket closure; ordinary scoped tested Git checkpoint/push is distinct.


## T12–T14 bounded technical checkpoint — 4 October 2026

Final source `83abbd2481b84b993f44b828d101c13181efa9792d3b70b6d1813e8222721637`: analysis/admission and 59 focused cases passed; 1,068 distinct selected cases / 1,128 exact ledger references / 54 files passed in three frozen batches. Closed original machine streams and verified archive are in `docs/quality/CURSOR-BUY-T12-T14-FRONTEND-20261003` evidence owners. The two named focused receipts preserve the same combined 59-case execution, not separate runs.

Cart Back is a 44px arrow inside the existing header. The initial extra Back row caused a small-screen 200% coupon scroll regression; the unchanged original case now passes. Fresh empty-basket Add resets stale display filtering only after successful validation. Pending-payment holds remain protected. Supplier policy stays Product/Add-only.

Redmi current isolated review runtime verified stable restored product quantities, current three-library VM hashes, Back return, Checkout return, bin cancel and confirmed entire-Cart deletion under Shop filtering, fresh Shop and Wholesale Add, and mixed Cart 3/₹1,197. Latest frame: `apps/mobile/build/t06-t07-cart-20261002/t14-native/compact-header-final-fresh-mixed-cart-review.png`. No new APK/install or real payment/order. Cold installed APK remains r66.36; this is not whole-APK/native-provider acceptance.

Open: seven full separate/mixed Add-to-Delivered native matrices; scoped catalogue shortcut count/total and All carts accessibility wording continuity audit; earlier 1/₹37→2/₹97 discrepancy; founder draft visual approval; backend/provider integration deferred, workspace Codex after integration, Google separately listed. Formal handoff remains blocked by inherited non-atomic history; no rewrite or formal closure claim. Ordinary safe tested Git checkpoint proceeds separately.

## T14 bounded seven-journey execution — 4 October 2026

Founder selected the queued audit and design/payment review as a bounded goal. Personal Buyer / public Buy Cart-to-fulfilment continuity is mvp_required; accessible design and copy consistency is mvp_supporting. Continue the existing open Buy parent, starting clean at dd8d9080ff832b918b5ff380d651b206ae605eab. Reuse existing native screen/catalogue/views/session/contracts and existing scoped-cart, screen and order-progress tests; no new route, service, state owner or dependency.

First reproduced contract gap: catalogue Shop/Wholesale Cart shortcut summarizes one destination while the public mixed Cart shows the complete basket. Reconcile public shortcut count, amount, acknowledgement and target scope together; standardize single-Cart wording. Preserve Store procurement and Medicine scoping, accepted Add appearance, Product/Add-only supplier policy, shared-address instructions and composer-only Clear. Exact first runtime owner: apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart. Exact test owners: existing buy_v2_scoped_cart_checkout_dock_continuity_test.dart, buy_v2_screen_test.dart and buy_v2_order_progress_test.dart. Further fixes require registered reproductions and a bounded assessment.

Acceptance covers fresh Shop, Wholesale, Offers origin, Shop+Wholesale, Shop+Offers, Wholesale+Offers and all-three: real Add, quantity/removal, Cart visibility/count/total/current selection, Product/Back/Checkout return, payment and order correlation, Confirmation/Orders/Tracking/Delivered where available, relevant receipt/help, large text, wording, motion and visual inventory. Isolated host fixtures may prove deferred frontend fulfilment states; never label them live or native provider acceptance. The current Redmi review adapter returns unavailable order refresh, so full native Delivered replay is an explicit integration child. Existing r66.36 warm runtime only; no build/install, real payment/order/support or Store implementation.

Design polish includes cards/details/hierarchy, consistent icons, meaningful solid colours/gradients, accessible motion and reduced motion, finished copy and reachable navigation. Implement only scoped confirmed fixes after the audit; keep larger drafts distinct from founder acceptance. Inspect card-field ownership and payment intent/QR capability without disconnected card forms. QR/intent completion is not payment verification. Store receive-payment QR is deferred to Codex after integration; backend deferred and Google separately listed. Preserve failure/pending/retry/idempotency and recipient/amount/reference validation. Finish evidence, focused/selected tests, native source activation/retest and safe exact Git checkpoint; retain unresolved children and stop.

### T14 supplier-test scope assessment correction — 4 October 2026

The existing selected/owned apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart needed an exact current assessment entry when broad tests exposed eight global Product Cart scope conflicts. The correction changed only that control's expectation and added both-product/quantity assertions; contextual supplier Cart/Add MOQ/Back/status checks remain. The path was already in the recorded primary claim and existing selected founder owner ledger, but was omitted from this assessment's explicit sharedImplementationOwners. This entry is recorded after the admitted test edit, not retrodated. No other lane or application runtime owner was changed by this correction. Preserve the sequencing variance and failed original437/8 batch; correct assessment and recheck before final qualification. Source is unchanged while the replacement selected run executes; its registry/policy/ledger pins remain frozen.

### T14 routing-hint correction assessed before implementation — 4 October 2026

Broader original tests exposed a real regression in the attempted force-All shortcut target. Personal Buy already uses mixed cartLines and Checkout All while cartScope retains Shop/Wholesale return context; forcing All is not required for full-basket continuity. Preserve existing aggregate routing decisions and introduce a display-only aggregate summary for public Shop/Wholesale count, amount, pending-price and acknowledgement. No checkout eligibility, provider action, session model, Store or Medicine scope change.

Exact existing owners: apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart; tests buy_v2_screen_test.dart, buy_v2_partner_catalogue_test.dart, buy_v2_scoped_cart_checkout_dock_continuity_test.dart, buy_v2_order_progress_test.dart in apps/mobile/test/ui_v2/buy. Restore original Shop/Wholesale scope assertions; keep additional both-product/quantity checks. Four scoped-feedback assertions must compare the mixed basket summary while retaining scope/Back/quantities. Fourteen new preview cases assert observable full lines/totals and Checkout All while allowing the existing origin hint. The 23 nested Store return assertions remain unchanged. Product gallery and post-Redmi test owners remain untouched. Focus all28 observed failures, eight partner cases and existing100 focus before full1096 final generation. Preserve both failed full runs, corrected diagnosis and original scope mistakes; no partial or retroactive acceptance.

### T14 empty-notice fix assessed before implementation — 4 October 2026

Within this bounded visual audit, suppress empty/whitespace content in existing _BuyNotice (apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart). Existing fourteen isolated host cases in apps/mobile/test/ui_v2/buy/buy_v2_order_progress_test.dart will assert no blank live-notice key after ready refresh and a meaningful message remains announced. Reuse current host adapter only; do not alter production provider/session contracts, meaningful failure notices, gestures or navigation. Normal/200% captures and final original regressions qualify the local fix. New-source Redmi activation remains unresolved; no independent native acceptance.

## T14 bounded stop checkpoint — 4 October 2026

Public Shop and Wholesale shortcuts preview the full mixed personal basket count/amount while preserving original routing hints for Product and nested Store/provider return. Native pre-fix reproduction: Wholesale 2/₹1,160 versus mixed Cart 3/₹1,197. Store/Care boundaries and accepted Add styling remain unchanged. Supplier terms stay on Product/Add; one shared-address instructions composer remains the standard.

Host technical proof: 136 focused checks; 1,096 distinct selected cases across 54 files; 1,156 exact file/name ledger references. Fourteen seeded preview cases and fourteen isolated development fixture fulfilment cases cover seven compositions at 100%/200% text. Existing28 failing route/feedback cases and8supplier variants were rechecked against the corrected runtime; original scope hints remain. Corrected confirmation mount now asserts the actual view/key and captures Order placed. This is not actual native Add-origin, real payment or provider delivery acceptance. Source fingerprint is the tested working bytes; Git LF canonical source equivalence is separately recorded, not independently tested fresh-clone proof.

Redmi still runs the earlier c6da01c7 warm runtime. Current fix was not activated. Final raw read-only service probe qualified false; no further attach retry, build/install/reset or financial action. Native screenshots reproduce the original discrepancy only. T14-native-activation and T14-seven-actual-origins remain unresolved. Final native screen is the pre-fix mixed Cart 3/₹1,197, not a review of the new correction.

T14-empty-refresh-notice is host fixed: existing _BuyNotice suppresses empty/whitespace content;14 fulfilment cases assert blank absence and meaningful announcements; normal/200% Delivered captures no longer have the blank pill. Native acceptance remains pending. The earlier information-action diagnosis was wrong: this was a passive IgnorePointer notice. Force-All was a real routing regression, corrected by aggregating summary only and retaining original nested/context scope assertions. Existing personal cartLines are mixed even with a return hint; no separate public basket is inferred from the enum. Checkout-return recommendation scroll and earlier Cart1/₹37→Checkout2/₹97 remain unresolved observations. Broader cards/icons/gradients/solid colours/motion/UX/wording polish is registered pending, not accepted.

Card detail collection belongs to the selected payment provider. Existing card choice, UPI intent and amount/reference/expiry-bound QR hooks remain; no disconnected card/CVV inputs or simulated payment. Store receive-payment QR is workspace Codex after integration. Backend deferred; Google-related dependencies separately listed. Full connected journey and live integration remain pending.

Evidence and all children: docs/quality/CURSOR-BUY-T14-SEVEN-JOURNEY-20261004.md, matching JSON, original SDK streams and manifest-verified ZIP. Existing inherited non-atomic 0e90a6ca74b81e212f118995f7c4fab0d3b78620 still blocks formal handoff/closure. No history rewrite or full acceptance claim. Safe scoped checkpoint/remote readback, then stop this bounded goal.
