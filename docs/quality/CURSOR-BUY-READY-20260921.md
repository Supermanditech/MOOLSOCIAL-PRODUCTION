# Cursor Buy baseline capture — 21 September 2026

## Corrected public-side scope — supersedes the initial capture below

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
Implementation remains pending the one-time setup commit and exact source-owner
admission; setup bootstrap does not authorize runtime edits. No APK needed.

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

## Initial capture — retained, rejected scope

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
