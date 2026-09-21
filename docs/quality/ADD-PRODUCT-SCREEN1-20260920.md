# UAW-ADD-PRODUCT-SCREEN1-20260920

## Active v18 — inline periods and export actions, design approved

Founder approved this design on 21 September 2026 after the resumed local work.
This supersedes v17's download modal and pending design approval; it does not
accept backend history, native direct saving or the full Add Product journey.

- No application download popup. Current stock / Today / This week / This month /
  Custom dates are inline, with PDF / Excel / CSV actions directly below.
- Custom dates use inline DD/MM/YYYY fields; invalid, reversed and future ranges
  are checked. Week starts Monday; month starts on day one in local device time.
- Historical selection hides current stock balances and disables all formats.
  Never relabel today's balances as a historical/accounting statement.
- Current stock exports every matching inventory record, not only the visible
  page. No filter means all Store stock. Empty results disable all formats.
- Existing immutable snapshots, duplicate-tap, cancellation, retry and sticky
  Store/account invalidation protections remain. Serializers are unchanged.
- Native FilePicker still presents the operating-system save chooser. Fully
  dialog-free Android Downloads integration remains a frontend/platform follow-up;
  do not claim one-tap native saving is complete or device-tested.

Local evidence: task outputs/store-stock-inline-v18/final-tests.log: 59 passed.
Includes 320px/200% text, search/edit, lazy 5,000/10,000 SKU stock, filter and
keyboard regressions, all inline format triggers, invalid dates, unavailable
history, empty results, cancellation/retry and store-switch guards. Final renders:
C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/store-stock-inline-v18-final.
Focused analysis initially found five brace-style infos; corrected before final
analysis. Earlier full v17 serializer evidence remains valid; no re-run claim.

Keep Store > Reports & Downloads as a future consolidated destination, while
retaining contextual export on each statement. Backend historical records remain
deferred. Existing catalogue/editor/Counter Sale layouts stay unchanged. This is
a scoped source checkpoint, not OPPO acceptance, publication or journey closure.

## Active v17 — stock downloads and complete developed-journey review

Local implementation and review evidence completed; founder approval PENDING.
Contextual Download is on the statement summary row, outside both scroll axes.
All stock is default; current results retain search/category/filter context.
PDF contains current stock/prices and SKU/barcode/category/visibility references;
Excel and CSV include all 32 recorded product fields. No per-SKU download. CSV is
a rectangular table with Store/time/scope columns and formula-injection escaping.
Excel identifiers are typed text (explicit @ format); stock/prices are numeric;
untracked quantities remain blank, not a manufactured zero or availability flag.
Save is via existing native FilePicker, with cancel/failure/retry, busy guarding,
immutable captured records and a sticky account/Store invalidation guard.

Frontend-only dependency: excel_community 2.4.0 plus its equatable transitive
dependency. Existing locked versions unchanged. No backend/platform edits.
Serialization is one shared export owner, not three inventory/report systems.

Verification (task outputs/store-stock-download-v17):
- journey-r2.log: 100 passed, one existing AP-S1-001 landscape skip.
- export-scale-final.log: five final targeted tests passed, including all three
  formats at 10,000 records, PDF pagination, non-Latin fallback and sheet recovery.
- details-r4.log: two earlier supplemental detail/scale tests passed; final
  normal-text detail renders supersede r4 images.
- analysis-final.log: clean focused analysis; scoped git diff --check passed.
- independent-files-verified.log: Python CSV/OpenXML/PDF readback independently
  confirms rectangular CSV, preserved text identifiers, zero vs unknown, first
  and final SKU in the 10,000-record PDF. Sample files are test evidence only.
- ALL-SCREENS.md indexes 25 existing/new screen states; all image paths checked.

Local defect AP-STOCK-EXPORT-001: one giant PDF table repeatedly laid out its
remaining rows, causing a slow 10,000-record run. Interrupted that test without
deleting its log. Fixed by bounded 50-row tables in the worker isolate; final
five-test run completed in 22 seconds. Large PDFs remain lengthy (synthetic
10,000-record example: 1,600 pages including references); Excel/CSV are preferable
for large-list analysis. OPPO memory/performance/native save still unverified.
AP-STOCK-EXPORT-002: bundled Inter cannot render all scripts (Hindi exercised).
PDF fails explicitly and offers Excel/CSV; Unicode survives those exports.
Broader font support remains a frontend follow-up, not a claimed backend feature.
The spreadsheet preview renderer displays some text identifiers as numbers even
though independent OpenXML readback retains exact strings and @ formatting;
native Excel visual verification remains pending. Do not use that preview as
proof of native Excel display. Production catalogue/history/approval remain open.

Preserved preflight mistakes: newly registered helper initially had no file;
created its declaration before retrying the unchanged existence check. First
analysis found XLSX import/constructor and PDF-context API mismatches and a
nullable Store ID; corrected against installed APIs before tests. No failed or
interrupted run is reported as a pass. No commit/push/APK/OPPO acceptance yet.

Founder requested completion of the current-stock frontend on 21 September 2026.
Keep one visible contextual Download action beside the statement controls, never
one download per SKU and never only inside a More menu. Preserve approved compact
rows and existing catalogue/editor architecture. Offer all Store stock (default)
or current search/filter results, across all loaded inventory, not the visible
page; PDF, Excel (.xlsx), CSV. Founder explicitly approved one spreadsheet
dependency. Reuse FilePicker and PDF; isolate serialization in work_stock_export.

Durable follow-up: Store > Reports & Downloads will later collect Store reports.
Contextual statement Download must remain even after that hub is introduced.
Do not build a speculative hub now. The frontend exports Current stock snapshot
from saved Store inventory, with store, scope and generation time. It is not a
historical/accounting statement, audited balance or confirmed backend quantity.
Backend follow-up owns complete authorized dataset retrieval, historical movement
records, receipts, adjustments, returns, valuation and accounting periods. Never
infer these from current balances. Sold today and expiry alerts remain excluded
from the stock screen. Other public/editor mapping stays unchanged.

Qualification: full-scope vs filtered exports, empty/cancel/failure/retry, duplicate
tap and changed Store/account guards, typed Excel values and CSV formula safety,
large inventory, PDF pagination/content, compact/large-text download sheet and
the developed Add Product journey. Native OPPO file saving/backend remain pending.
Show actual local screens to founder; apply feedback. Only AFTER this review is
approved may the requested scoped Git checkpoint/push proceed. No commit, APK,
OPPO acceptance, backend implementation or journey closure from this note.


## Active v16 — horizontally scrollable, compact stock statement

Founder visually approved the displayed final v16/r11 Stock statement on
21 September 2026. This supersedes the pending-review notes below. Preserve the
56px normal rows, frozen product column and horizontal statement; no further
layout changes unless requested or a verified defect requires correction.
Approval is visual only, not a Git checkpoint, APK/OPPO acceptance or backend
authorization. Detailed exports/history and previously recorded gaps remain open.

Founder approved the daily-stock/detail/export separation, explicitly excluded
Sold today and expiry alerts from this stock screen, and then requested compact
bank-statement rows. Only the Stock visual unit advances; catalogue/editor and
Counter Sale approvals remain unchanged. Await revised visual review, no APK.

- One shared horizontal controller moves headings and data rows; the product
  identity column remains frozen. Existing lazy search/category/filter/paging
  remains the owner, not a new inventory collection.
- Current recorded stock, selling price, recorded purchase price, MRP and reorder
  threshold reuse saved product values. Summary low count excludes zero/out stock;
  availability-only products do not invent quantity or reorder thresholds.
- Product names/thumbnails stay fixed; compact normal rows are 56 logical pixels
  (previous attempt 104), with 24x32 thumbnails, two-line names and pack/SKU text.
  More room is retained for enlarged text. Visibility moves into existing product
  details; no separate Public/Private stock column or row control.
- Received today is not implemented without a complete receipt source. No Sold
  today, expiry alert, guessed valuation, synthetic transaction totals or exports
  claiming audit completeness. Current inventory is local/session data, not live
  backend stock or proof of physical quantity.

Deferred follow-up split (not implemented by this screen):
1. Frontend details: use existing editor/ledger where available; remaining batch,
   reservation, physical-count and document drilldowns need exact backend data.
2. Frontend export: date/filter/summary-detail selection, PDF/Excel/CSV output;
   only a current stock snapshot may use local current balances. Complete history
   cannot be reconstructed from today's quantities. No fake download-success UI.
3. Backend reports: authoritative receipts, movements, reservations, batches,
   returns/adjustments with actor/reason/reference, consistent full-dataset export,
   permissions and valuation basis. Stock statement is not a separate database.

Retained development evidence in task outputs/store-stock-horizontal-v16/:
- r1/r2: table gestures in tests targeted an offscreen center and an ambiguous
  Out of stock label; use visible product gesture and the actual filter menu.
- r3: enlarged-text viewport prevented row access; preserve scroll structure but
  scale its minimum extent. Money cells widened by actual formatted amount size;
  tests now explicitly pan cells clear of the frozen column before tapping.
- Existing no-horizontal-money assertion remains for finance/checkout. Only stock
  table assertions follow founder's new horizontal contract; large values retain
  full strings and existing full-width price/editor access, not abbreviation.
- r5: large-record fixture incorrectly used copyWith(id:); use the actual
  immutable-product constructor. Initial parser/lint errors corrected before
  captures. Earlier failed logs are retained, not used as passing evidence.
- Before the bank-statement density revision, r7 passed 97 with one existing
  skip. r8 found a 47px product target and 3px text overflow: use 3px vertical
  padding and explicit 1.2 line height, retaining >=48px edit targets.

Final compact v16: focused-r9.log passed 97, one existing skip. stock-r9.log
passed six capture tests; analysis-final-r9.log is clean. The 10,000-record test
mounts the actual horizontal statement, verifies 50-to-100 lazy paging without
losing horizontal offset, and finds the exact final SKU across the full dataset.
Stock quantity validation/reason/history and repeat editing passed at 1x/2x;
visibility remains available in the existing editor, tested true/false and saved.
No backend paging, camera scanning, OPPO or audit-export acceptance is claimed.
Local renders: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/store-stock-horizontal-v16-r11/.
r10 only aligns the middle capture to the purchase column after the real swipe
assertion, avoiding a transient clipped-edge capture; app source is unchanged.
r11 shortens the three-line purchase heading to Purchase price so it fits the
compact header. Its value still means recorded purchase price, not last receipt.
Await founder visual approval; local work remains uncommitted, no APK or push.

## Active v15 — founder-requested Store stock statement only

Founder rejected Store stock tiles/grid and requested a statement-style tabular
list with thumbnails. All other screens remain approved. Supersedes v14 stock
list/grid only: keep shared saved inventory, search/filter/edit actions, but no
stock view toggle. The MoolSocial catalogue list/grid remains unchanged.

Local r1 detected a header font issue in captures: a fresh DefaultTextStyle lost
the theme font. Inherit the theme label style before applying header emphasis.
One standalone fallback test still expected a separate grid stock label after
grid removal; assert the actual combined list price/availability text instead.
Retain r1 logs/renders; rerun and visually inspect before founder handoff.

r2 broader regression caught loss of the stock-row MRP/SKU display during the
table conversion. Preserve SKU under pack and MRP under selling price; retain
exact-money fitment assertions against the new MRP cell rather than the removed
combined subtitle. No product metadata or price rules are changed.

v15 implemented: one statement list, thumbnail/product/pack/SKU, aligned selling
price with MRP and stock columns, row dividers instead of tiles/cards. Tap the
product to edit; existing direct price/quantity/visibility handlers remain.
Large text/large amounts reflow within divided statement rows to retain readable
values and actions. Stock has no grid toggle; catalogue list/grid is unchanged.
Final focused-r3.log: 96 passed, one existing skip. stock-r3.log: six passed.
analysis-final.log: no issues. Only subsequent source edit adds lint-required
braces around the unchanged WorkCard fallback. Final screenshot visually checked:
C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/store-stock-statement-v15-r3/saved-stock-statement-loaded-360-1.0.png.
Logs retained in task outputs/store-stock-statement-v15/. These are local renders,
not OPPO/backend proof. Await visual approval of this revised stock statement;
all other founder approvals preserved. No commit, push, APK or backend change.

## Active v14 — saved Store stock list/grid

Founder approved v13 and explicitly said continue to Store stock. This authorizes
only the next saved-inventory screen: reuse catalogue search/category/lazy paging
and list/grid, retain existing stock/price/edit/visibility handlers, remove master
suggestions from real stock, and test saved inventory reaching Counter Sale.
No separate inventory owner, backend, APK or changes to approved catalogue/editor
layouts. Show actual owned values, including zero/availability-only stock, not
master quantities. Show the Store stock screen after local tests for founder review.

Implemented locally; founder review of this screen is pending:
- Store stock defaults to list, with grid toggle and shared search, category,
  filtering and lazy 50-item pages. Existing price/quantity/edit actions remain.
- Only saved workspaceCatalogueItems appear. Master catalogue suggestions do not
  count as stock. Add product opens the approved shared catalogue/editor flow.
- Counter Sale consumes the same saved inventory; no second stock collection.
- Production stock must be backend-authoritative. These local fixtures/session
  values prove frontend behavior only, not live stock synchronization, server
  pagination, publication approval or production persistence.
- Fixed a regression found at 200% text: returning from stock quantity editing
  could lose the visible stock action. Stable scroll structure, page storage and
  restoration of the edited control now preserve access; 1x/2x tests pass.

Final local verification: 96 focused tests passed, one existing skip; six STOCK14
capture tests passed. Analysis of all three changed Dart owners is clean.
Coverage includes saved/empty stock, search, category/visibility filters, zero and
availability-only quantities, edit/save/readback, Add product cancellation,
5,000/10,000 in-memory owned records, lazy pages and scanner-result matching.
This is not a real camera scan, server performance benchmark or OPPO retest.
Earlier failed runs remain retained; final evidence supersedes their stale
navigation and offscreen test interactions, not unverified runtime failures.

Evidence in the task workspace: outputs/store-stock-v14/focused-final-r2.log,
stock-r6.log and analysis-final-r2.log. Final renders inspected at
C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/store-stock-v14-r6/:
saved-stock-list-360-1.0.png, saved-stock-grid-360-1.0.png and
saved-stock-empty-360.png (also narrow 200% variants).
Approved catalogue/editor layouts remain preserved. No backend work, new APK,
OPPO testing, commit or push in this increment. Pause for Store stock approval.

## Current v13 — compact pack fields and real Store stock boundary

Founder visually approved the displayed v13 compact pack-fields screen on
21 September 2026. Preserve this layout; the sizing-review pause is resolved.
Next visual unit is Store stock list/grid for saved retailer inventory, with
local testing and founder review. This is not backend/publication/OPPO approval
and does not imply a Git commit or push.

Founder approved the compact-field proposal and clarified that the next Store
stock screen means saved retailer-owned products/actual stock, not the master
MoolSocial catalogue. This clarification is recorded for the next screen.
Public/private owned items share workspaceCatalogueItems with Counter Sale;
a master catalogue selection is not stock until the retailer saves it. New
copies continue to start at stock zero; do not fabricate physical quantities.

This increment changes only pack-field layout and tests:
- Net quantity and Country of origin share a 2:3 row at >=320px available width
  and text scale <=1.2. At narrower widths or enlarged text they stack.
- Generic/product and long manufacturer/packer/importer/licence/care fields keep
  full width. Vertical gaps reduce from 12px to 8px; fields remain >=48px.
- Enlarged text uses separate wrapping labels, not overlapping floating labels.
  Local r1 visual inspection found label overlap at 200%; corrected in r2 with
  explicit label/input separation assertions. r1 is retained, not final evidence.
- Keyboard Next moves net quantity -> country; edits survive save and Buy
  conversion. The eight editable pack fields remain the exact same compliance
  keys; two batch dates remain read-only with v12 batch isolation unchanged.
- Actual BuyV2ProductCompliancePanel is mounted in a new test: all ten mapped
  facts render and are scroll-reachable. This proves local public presentation,
  not server publication/approval. No Buy presentation owner changed.
- Remaining 400-field mapping gaps, Store-default inheritance, authoritative
  persistence and Wholesale/backend work remain pending as documented in v12.

Final evidence: task outputs/add-product-compact-v13/mapping-r2.log (7 tests),
addreview-final.log (4), addphoto-final.log (9), catalogue01-final.log (3):
23 focused tests. analysis-final.log checks both changed Dart owners.
Local renders inspected:
C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-compact-v13-r2/
including 360px compact, 320px stacked and 200% text.
This is a narrow regression set, not a fresh full-app regression or OPPO test.

Saved locally, uncommitted on work/codex-ui/add-product-screen1-20260920,
HEAD 015e16e4aa018f5a8e5adca6204504fd8fb69b45. No APK, backend or Counter Sale
changes. Show compact screen before the next Store stock list/grid visual unit.

## Founder approval — v12 screens, 21 September 2026

Founder explicitly approved the displayed exact variant/pack catalogue tiles,
prefilled Review product and expanded Pack information screens. This resolves
the v12 visual-approval pause recorded below; preserve these approved layouts.
Next visual unit: Store stock, offering list/grid views over the same inventory
used by Counter Sale. Continue screenwise local testing and founder review.
This approval does not close the 400-field mapping gaps, grant backend work,
prove OPPO acceptance, authorize a release, or claim that local changes are
committed/pushed. Those pending statuses remain unchanged.

## Current v12 — exact variant/pack and product metadata review

Founder requested full public-field/metadata mapping and inspection of catalogue
variant presentation. This increment stays in the shared catalogue/editor:
no new route, backend, Store Settings implementation or Store stock redesign.
All other approved layouts remain unchanged.

- Exact variant and pack are visible on each tile/list row. Add to Store selects
  that exact SKU, not a product family. Grid stays 176px with a 48px action;
  long labels retain full tooltip text. Search includes variant/pack; view
  switching, owned filtering and scanner callback identity are tested.
- Existing WorkspaceProductCompliance supplies eight editable pack facts:
  generic name, net quantity, manufacturer, packer, importer, country of origin,
  manufacturer FSSAI number and consumer care. Existing two batch date fields
  are read-only in SKU reference, preserved on edit and cleared for a new Store
  copy. Real batch receipt workflow remains separate.
- Ten pack facts now project to BuyV2ProductCompliance and the operational
  snapshot; composition/regulatory/prescription/visual/unit-price metadata is
  also retained in that snapshot. Metadata-only changes invalidate the public
  preview cache. No authoritative server readback or approval is implied.
- Edited master facts set a retained catalogueFactsRequireReview hold. It
  survives reopening/copy/save, disables public eligibility and the editor
  visibility switch, without disabling private Counter Sale use. Backend
  restore and authoritative approval must retain/enforce this hold; there is no
  retailer control to clear it.
- Store-wide setup is separated in explanatory copy. It is NOT a working
  default-inheritance engine or Store Settings screen. Payment acceptance,
  coverage/service defaults and private settlement credentials are not repeated
  as product fields. Catalogue/product IDs and photo approval remain read-only.
- Save to Store / Save changes and shared inventory remain unchanged. Catalogue
  and manual entry share one editor. CSV batch review/parser improvements remain
  pending; no third implementation is created.

### v12 exact mapping and remaining scope

The 400 unique original IDs are retained, with original source/rule/ownership
and an explicit current disposition, at:
C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs/add-product-mapping-v12/field-disposition.md

This is not 400 completed fields or 400 retailer inputs. Newly exercised:
P07/P08 exact variant/pack; C01-C06/C09/C10 editable pack data and Buy projection;
C07/C08 read-only batch isolation; P01/P02 read-only references. Existing
price/stock/identity editor owners are reused, not replaced.

Explicit frontend gaps remain: P03/P10/P14/P22-P24 channel, conversion, Wholesale
prices/increments/tiers; P09 numeric net-amount semantics; P31-P36 structured
merchandising/freight/grant/trust ownership; P40-P43 description/highlights/
specifications; structured returns and Store-default inheritance. P30 is a
restriction, not a new retailer self-approval control. Store-wide payment and
settlement screens are separate approved-owner work, not backend-only gaps.
Integer/decimal price semantics and CSV quoted parsing/ambiguous matches remain
in the original gap register.

Backend remains deferred: real catalogue/cursor API, approved media, publication
acknowledgement, persisted review state, verified payment/settlement/fulfilment.
5000/10000 tests prove local supplied-data paging, not server paging or OPPO
performance. No app-wide approval or production readiness claim.

### v12 local evidence / approval gate

44 focused tests passed: ADDMAP 5, ADDREVIEW 4, ADDBROWSE 3, ADDENTRY 10,
ADDGRID 5, ADDPHOTO 9, CATALOGUE01 3, COUNTER1919 public/private 2, S09 catalogue
suggestions 3. One pre-existing dashboard-landscape skip remains. Six Dart
owners analyzed clean. Not a full application regression or OPPO acceptance.

Logs: task outputs/add-product-mapping-v12/, final runs mapping-r3.log,
review-final.log, browse-final.log, addentry-final.log, addgrid-final.log,
addphoto-final.log, catalogue01-final.log, counter-final.log,
s09-catalogue-suggestions-final.log and analysis-final.log.
Earlier attempts are retained, not final pass evidence: the r1 mapping harness
mistook SelectableText's read-only EditableText for writable inputs and targeted
an expanded tile instead of its visible heading; assertions/tap targeting were
corrected without removing readonly checks.

Inspected actual Flutter renders:
- C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-mapping-v12-r3/
- C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-review-v12-r1/
- C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-variants-v12-r1/

Variant-family images/prices are synthetic test cases. Photographic renders use
generic test-only sample assets, not authenticated brand photos. No media upload.

STOP for founder variant presentation/revised editor approval. Store stock
list/grid is still the next separate visual unit. Source and evidence are local,
uncommitted; no APK/OPPO/commit/push. Branch
work/codex-ui/add-product-screen1-20260920, HEAD
015e16e4aa018f5a8e5adca6204504fd8fb69b45. Counter Sale a425fd89 and pending
CS-OPPO-015 physical retest are preserved.

## Previous v11 — approved catalogue, shared review before saving

Founder approved v10 catalogue and requested fuller thumbnails without larger
tiles, suitable final-action wording, and the shared editable Store stock flow.
This increment implements the next review screen only. Final action is **Save
to Store** (existing product: **Save changes**), not Submit or Publish. Store
stock list/grid redesign remains the next visual approval unit, not complete.

- Catalogue thumbnails remove renderer padding and use 40px of the existing
  176px tile; interior spacing is reduced, not tile size increased. Images keep
  their aspect ratio with contain fit: no stretched/cropped labels and no
  altered originals. List thumbnails also remove internal padding.
- Add to Store opens the existing shared full-page editor; it no longer writes
  an immediate private draft. Product facts, reference selling price, MRP and
  photo link are retained. Retailer purchase cost starts blank and actual stock
  starts at zero: shared-catalogue stock/cost is not asserted as retailer stock.
- Cancel/back creates no inventory record. Save to Store validates then writes
  the same session inventory and returns to the existing Store stock surface.
  Its heading is renamed only; its list/grid redesign is still pending.
- Reopening the saved product prefills retailer edits; Save changes updates the
  same ID. Concurrent duplicate, duplicate SKU and Store switch are rejected.
  Unedited reference unit-price copy now follows the changed selling price.
- Catalogue/manual reuse the editor and save owner. Existing CSV import remains
  shared-model ingestion; CSV batch-review changes are not claimed implemented.
- Stock is private by default; saving is not public Buy publication. Existing
  photo identity/test-only/public validation is retained. No backend, approved
  media upload, APK, OPPO or production operation occurred.

### v11 local evidence

39 targeted tests passed: ADDREVIEW 4, ADDBROWSE 3, ADDENTRY 10, ADDGRID 5,
ADDPHOTO 9, COUNTER1919 public/private inventory 2, CATALOGUE01 3 and S09
catalogue suggestions 3. One pre-existing dashboard-landscape skip remains.
Analysis of the changed Dart owners is clean and diff whitespace check passes.

New connected test saves a private SKU, reopens and changes its price, verifies
one inventory record and retained photo, then finds it by SKU in Counter Sale,
adds directly and simulates barcode keyboard input for another unit. No live
scanner or OPPO proof is implied. Existing Counter Sale private/public/zero
stock tests pass without editing Counter Sale logic.

Final inspected native Flutter renders:
- `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-review-v11-r5/`
- `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-thumbnails-v11-r2/`

Logs: task `outputs/add-product-review-v11/`, using `*-final.log`,
`review-r5.log` and `browse-r2.log`. Earlier attempts are not pass evidence.
Observed/fixed during local verification: missing packshot import and wrong
test helper name; 4px tile overflow after enlarging the image (fixed internal
spacing); missing route-settle before customer entry in the test; enlarged-text
footer wrapping (accessible icon Cancel + wider Save at large scale). Existing
direct-add tests were updated to assert no write before the approved Save action.

Source remains local/uncommitted in branch
`work/codex-ui/add-product-screen1-20260920` at HEAD
`015e16e4aa018f5a8e5adca6204504fd8fb69b45`. Next founder decision: Review product
screen approval; then implement Store stock list/grid against this same inventory.
Counter Sale CS-OPPO-015 physical retest remains pending and untouched.

## Current v10 scope — category / scale / shared inventory journey

Founder requested product-specific test imagery, category onboarding, 5,000–10,000
SKU pagination, editable prefilled review before final Store submission, one
Store stock source feeding Counter Sale, and list/grid choice in both catalogue
and stock. All three input paths still share models/editor/save/publication.
MVP-supporting. Minimal journey: catalogue/manual/CSV -> shared review/editor ->
Submit to Store -> Store stock. Stock remains editable and supplies eligible
products to Counter Sale search/scanner/item selection; publication to Buy is
separate. Never create a second stock collection or a customer-cart dependency.

Screenwise gate remains: implement catalogue browsing (category, list/grid,
bounded local pagination, test images) first, render/test/show it, then pause for
founder approval before redesigning review/submission or Store stock. Record the
later steps; do not claim they are complete from this catalogue change.
Current large-list scope: support a supplied full catalogue of 10,000 records
with indexed inventory matching and lazy 50-item presentation pages, search and
categories across the full input. This is NOT a connected server cursor API;
backend paging/authoritative category/photo delivery remains a later adapter.
No backend uploads, API provisioning, APK, OPPO or production store action.

Imagegen generated three generic TEST SAMPLE packshots: sunflower oil 1 L,
whole wheat atta 1 kg and iodised salt 1 kg. They are review fixtures, not brand
photographs. Saved under the task outputs/add-product-catalogue-v10/test-images
directory. Local tests may serve these via the existing in-process image client;
never mark them approved or package them as production master catalogue media.

### v10 local implementation / evidence

Catalogue now has category counts (including Uncategorised), category-scoped
search, list/grid selection, and lazy 50-record presentation pages with scroll
loading plus an explicit Load more control. Search/filter counts cover the full
supplied input, not just the loaded page. Search/category/view changes reset the
page/scroll safely. Owned SKU lookup uses ID/identity maps rather than scanning
the full inventory for each card. Grid/list share the same existing callbacks.
The approved compact grid remains three columns at 360px with 48px actions;
list actions move below the details with enlarged text.

Actual local Flutter renders were inspected under
`C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-catalogue-v10-r5/`:
grid, list, category chooser/filter and 320px large-text list. Product-specific
test PNGs use an in-process HTTP client; decoded original metadata is used and
test-only publication denial is asserted. A list-button font inheritance defect
found by visual review was corrected and has a regression assertion. Earlier
runs retain test-harness errors; r5 is the corrected browse evidence.

Test logs and asset prompts/hashes are in the task's
`outputs/add-product-catalogue-v10/` directory. Frontend synthetic scale tests
exercise 5,000 and 10,000 records, half already owned, no duplicate rows, lazy
50/100 rows, last-SKU search without walking pages, category counts over all
records, Saved filtering, list/grid state and scroll reset. They do not establish
physical-device performance or a real paginated backend contract.

Final local result: 27 targeted tests pass (ADDBROWSE 3, ADDGRID 5,
ADDENTRY 10, ADDPHOTO 9), with the one pre-existing upstream dashboard landscape
test skipped. Analysis of all six current Dart owners is clean. No new OPPO
evidence or release clearance is implied.

### Explicit next-screen handoff — not implemented by v10

- Keep the name **Store stock** for retailer-owned inventory. It is one shared
  stock source, not a separate catalogue/cart per feature.
- Replace the current immediate-private-draft Add callback with **Add to Store
  -> prefilled editable review -> Submit to Store**. Until that approved next
  screen is implemented, Add still uses the existing private-draft handler.
- Reuse the same editor/validation/save for catalogue, manual and CSV. Preserve
  supplied product facts/photo reference; let the retailer edit selected values.
  Identity changes must revalidate the photo; no silent mismatched packshot.
- Successful final submission updates Store stock; editing remains available.
  Provide list/grid choice there using the same inventory data, not a duplicate
  collection. These stock-screen changes remain pending visual approval.
- Verify submitted eligible public/private stock appears in Counter Sale item
  selection, typed search and barcode lookup. Draft creation alone is not proof
  of sellable stock. Verify price/stock edits and zero-stock behavior end-to-end.
- Public Buy publication remains separate and validates image/identity/rules.
- Backend-owned catalogue cursor/search/filter totals, approved photo upload and
  authoritative persistence are deferred, not represented as implemented.

No commit, push, APK, OPPO run or production media upload in this increment.

## Current frontend follow-up v9 — Add to Store / public photo route

Founder requested Store-contextual button wording and completion of pending
frontend photo work, explicitly deferring backend work. Button is now
"Add to Store", then "Edit" after adding; dense approved grid is unchanged.
One exact ticket/root/branch exception admits journey_router.dart only for this
frontend continuation. No broad journey01 permission or backend authority.
Public Store preview now supplies the actual Store ID to the photo adapter.
Its cache identity includes product identity and photo metadata/revision/source,
so replacement cannot retain the previous public session/photo reference.

Local verification: 26 distinct checks passed (ADDPHOTO 9, ADDENTRY 10,
ADDGRID 5, exact public product navigation 1, Storefront Back 1). The known
upstream dashboard landscape AP-S1-001 remains skipped, not passed. Focused
analysis clean and git diff --check passed. Real Image.network decoding was
exercised with an in-process HTTP fixture, never an external service. Verified
loading/decoded/404 fallback, 32px thumbnail versus retained 1024px metadata,
BoxFit.contain, private add, actual Store-to-Buy route and replacement revision.
Captured normal/200% text, loading/failure, dense 50-SKU fixture and public photo
screens; inspected actual rasters. Fixture image is a synthetic navy test pack,
not a supplier-approved photo. No fixture media is shipped in the catalogue.

Current passing evidence (earlier failed attempts retained separately):
- C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-photo-frontend-v9-r4/
- C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-photo-frontend-v9-entry/
- C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-photo-frontend-v9-grid/

Test-harness corrections: replace the owned record as well as the master fixture;
allow real image decode before settling fake-clock animations; restore the image
HTTP debug override before framework invariants; flush the review-save timer.
The first public capture was taken during its fade (blank body), so the final
test additionally settles after decoding and requires hit-testable product text.
Do not use r1/r2/r3 attempts as passing evidence; r4 passes all nine photo tests.

Release boundary: check-approved-ui-locks.ps1 is still blocked by its inherited
MainActivity accessibility projection's exact-worktree check. No Android or
locked Screen 01-03 owner changed; no lock was relaxed. This is NOT APK/release
clearance. Backend ingestion, trusted photo approval, immutable revision URLs,
live readback and production mandatory-photo migration remain deferred. Existing
photo-less legacy publication eligibility is unchanged. No APK/OPPO/live action.
All changes remain local/uncommitted on registration HEAD 015e16e4. Stop for
founder review of the contextual wording before the next visual journey screen.

The public-route and actual-render blockers in the historical section below are
resolved for this frontend slice; its backend/migration exclusions still apply.

## Approved v8 grid / bounded photo continuation — 2026-09-21

Founder approved the compact grid and directed production-compatible image
references with test photography permitted for later local review. Next is
authorized for frontend photo wiring, not photo ingestion/backend deployment.
Classification: mvp_supporting, reusing Buy media validation/rendering and the
shared Store model rather than a new media service or three entry implementations.
Keep layout unchanged. Retain exact SKU/variant/pack identity, original source and
revision; pricing/stock edits preserve media, identity edits invalidate it.
Test images are preview-only, never admitted to public product media. Approved
references can be replaced without re-adding inventory. Missing/broken media uses
the existing fallback. Source reference is serialized into the existing
operational snapshot; backend readback/authority remains separately pending.
Test identity changes, invalid metadata, replacement revision/source, test-media
isolation, serialization and private Add/Edit retention. No new route, dependency,
Buy owner edit, photo upload, production action, APK or OPPO work.
Narrow additional owners: work_models.dart and work_session.dart. Photo tests
reuse work_workspace_layout_safety_test.dart; no separate test owner was added.

Local result: shared WorkspaceCataloguePhoto stores exact identity, source,
revision, file metadata and pending/testOnly/approved status. Store grid reuses
Buy's media renderer through an explicit preview adapter. Public conversion
excludes test/pending/mismatched/invalid media and requires a supplied Store ID.
Price/stock/local-SKU edits retain references; identity changes suppress photos.
Operational snapshot includes the reference and decoder preserves test status.
Seven ADDPHOTO, five ADDGRID and three CATALOGUE01 tests passed (15 distinct).
Focused analysis clean; diff whitespace check passed. No UI layout change or
new photographed render; no network media was fetched in these metadata tests.
Fixture URLs use example.invalid and are not deployed catalogue entries.

Still OPEN, not a production-readiness claim:
- Protected journey_router.dart currently calls the public adapter without a
  Store ID and caches without photo revision; exact public-route binding and
  invalidation need an admitted follow-up. Its claim was rejected by the lane
  allowlist and removed; no router or Buy source was edited or gate weakened.
- Real catalogue photo ingestion, trusted approval, immutable revision-specific
  URLs, production snapshot readback and cache-refresh/device testing are pending.
- Existing photo-less records retain legacy publication eligibility. Mandatory
  photo enforcement/migration is not implemented by this bounded reference slice.
- Actual test-photo rendering/loading/failure visual evidence remains pending;
  the founder explicitly allowed test photography later.
All app work remains local/uncommitted; no APK, OPPO, backend or live-store action.
Preflight correction: a proposed new test owner did not yet exist; reuse the
already-claimed test owner. Flutter-generated dependency ordering/timestamp churn
was reverted only in its two generated files; subsequent tests used --no-pub.

## Current founder revision — denser SKU tiles v8

Reduce tile footprint, keeping approved search/selector chrome. Three columns at
normal phone text size, fewer columns for enlarged text; small 32px thumbnail,
readable title/pack and 48px Add/Edit target. Reuse Buy photo rendering and
unchanged product identity; display thumbnail size never changes original media.
No fabricated pack photos or live-photo/publication wiring claim. Prove density,
scroll reachability and enlarged text locally, then show for founder approval.

v8 result: normal 360-width layout is three columns with 176px tiles (previously
two columns/220px), 32px media display and 48px Add/Edit buttons. Up to three
title lines; enlarged text reduces columns automatically. Fifteen distinct
focused local checks passed: ADDENTRY 10, ADDGRID 5 (includes 50-SKU synthetic
fixture and scroll-to-last-item). One existing upstream dashboard-landscape
test remains explicitly skipped. Focused analysis clean. Nine complete tiles
visible at 360x806 in the 50-record test fixture, with another row partly visible.
Actual three-record catalogue and synthetic density captures inspected under
`C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-dense-grid-v8/`.
Fixture records are test-only, never added to the master catalogue. Product photo
source/identity adapter is unchanged; still no admitted photos in the real seed.
Small inventory thumbnail does not establish public photo/publication readiness.
Saved locally, uncommitted; no APK/OPPO/backend. Await founder tile approval.

## Current founder revision — visible mode selector v7

Founder visually approved this selector on 2026-09-21. MoolSocial catalogue is
the default; visible label/arrow switches manual/CSV in-place. Approval applies
to this entry/selector layout, not full Add Product field/publication/CSV-scale
or physical OPPO acceptance. No further layout changes without a found defect.

Keep MoolSocial catalogue as default. Its visible label and dropdown arrow select
MoolSocial catalogue / Add manually / Import CSV in-place. Remove the hidden
top-right overflow trigger. Reuse the same selector on manual/CSV headers so the
current mode and return path stay discoverable. Search-first layout, private
inventory Add/Edit, existing handlers and retained drafts stay unchanged.
Local visual/function checks only; stop for founder approval, no APK/backend.

v7 local result: 17 focused tests passed (ADDENTRY 10, ADDGRID 4, CATALOGUE01 3),
one known upstream dashboard-landscape reproduction skipped; focused analysis
clean. Arrow hit-testing opens the three mode choices inside the catalogue
toolbar; no overflow icon remains. Existing route-identity, search/draft retention,
menu switching, keyboard, CSV, private Add/Edit, filters and duplicate/Store
guards pass. Grid still starts around y=125 at 360x806. Inspected normal/200%
catalogue, opened selector, manual and CSV renders under
`C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-visible-selector-v7/`.
No new routes/data owners: one inherited callback scope and one shared selector
reuse the entry's existing state. Local uncommitted changes; no APK/OPPO/backend.
Enlarged-text inspection caught brand splitting in the narrow label; compact
identity typography corrected to keep MoolSocial intact and a word-box regression
added at 320/360/412 and 200% text. This is a local fit correction, not new scope.

## Current founder revision — search-first v6

Remove the Add product title and persistent three-mode tabs from catalogue.
Search is the first safe-area row, with Back and a compact Add options menu.
Menu retains catalogue/manual/CSV in-place switching and draft retention. Manual,
CSV and catalogue editor may show their own compact contextual header; never a
misleading catalogue search. Preserve v5 catalogue toolbar/grid and all handlers.
Only local rendering/testing and founder visual review; no APK/backend scope.

v6 local evidence: search band starts at y=0 inside the safe area; grid begins
around y=125 at 360x806 (v5 about y=241). No persistent title/mode tabs. Menu
items remain reachable, switch in-place and preserve draft/search. Catalogue
editor has contextual Back to grid. ADDENTRY 10 and ADDGRID 4 tests passed with
one known upstream dashboard-landscape skip; CATALOGUE01 3 passed, including
editor Back and re-entry. Focused analysis clean. Existing toolbar, draft/save,
filters and scanner behavior retained. Inspected normal/200% catalogue and menu
captures under `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-search-first-v6/`.
No APK/OPPO/commit. Await founder approval; v5 and earlier chrome superseded.

## Current founder revision — Buy-aligned compact chrome (2026-09-21)

Founder rejected v4 catalogue chrome's wasted space. Reuse Buy's visual placement:
borderless inline search/scanner band followed by 48px category menu on the left,
compact catalogue identity/count in the middle and Saved/filter icons on the
right. No separate heading/count row. Three entry modes remain above catalogue
search (hidden in manual/CSV) because embedding all three labels beside actions
would crowd the Buy two-mode slot. Preserve grid/private Add/Edit and shared
handlers; no customer-cart coupling, Buy owner edits, backend or new routes.
Verify local behavior, vertical fit and enlarged text; show v5 for approval.

v5 local result: 17 tests passed (ADDENTRY 10, ADDGRID 4, CATALOGUE01 3), one
known upstream dashboard-landscape test skipped. Focused analysis clean.
Grid starts at about y=241 rather than v4 y=321 at 360x806. Regression asserts
grid top <=250, search above toolbar, category left of Saved left of filter,
48px hit targets and no search/toolbar/grid in manual or CSV modes. Private
Add/Edit, search/filter, scanner retry and CSV behavior remain checked.
Buy's private cart-bound toolbar cannot be embedded directly without coupling
Store inventory to BuySession. Store uses the same menu/bookmark/tune icon order,
48px rounded chrome and borderless search treatment with its existing callbacks;
no Buy source/session/offer/card code was changed. Actual v5 local renders:
`C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-buy-chrome-v5/`.
Normal/200% catalogue and manual/CSV views inspected. Missing-photo fallback
remains truthful. No APK, OPPO or implementation commit; await founder approval.

## Current founder revision — compact inventory grid (2026-09-21)

Founder approved the tabs/layout, not the catalogue row presentation. Change
only catalogue content to compact SKU tiles with inline search/scanner, category,
Saved and filters. Reuse Buy media/scanner and the existing shared product editor;
do not reuse its customer cart/session as Store inventory. Add saves a private,
unavailable inventory draft without invented stock/cost; Edit opens the shared
editor. Saved means products already saved in this Store, not customer bookmarks.
Keep manual/CSV and approved tabs unchanged. Categories/brands derive from actual
inventory/catalogue records; do not invent extra products or supplier photos.
Local UI/functional tests and actual renders precede founder approval. No APK,
backend, new catalogue data pipeline, or publication authority is implied.

Local v4 result: 17 focused tests passed (ADDENTRY 10, ADDGRID 4, CATALOGUE01 3),
one existing upstream dashboard-landscape reproduction explicitly skipped.
Focused analysis of both runtime owners and the test owner: no issues. Tested
private Add/idempotence, duplicate SKU and Store-switch guards, Saved/category/
brand/new-only/search composition, empty results, scanner retry/barcode matching,
shared edit/save, responsive tabs, retained draft and keyboard controls, and CSV
regressions. Scanner was injected locally; no camera/device proof is claimed.
Inspected actual local normal, Saved/after-add and 200% text renders under
`C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-grid-local-v4/`.
Buy packshot component reused via the existing Store-to-Buy identity adapter;
these three records have no admitted photo, so the truthful fallback is shown.
Buy customer-cart/session code remains untouched. Source/tests remain saved
locally, uncommitted; no APK, physical OPPO or live catalogue acceptance.
STOP for founder approval of the revised product tiles.

## Current founder revision — one page, in-place tabs

Supersedes the v2 arrow-card entry and its local result below. Founder rejected
forward-arrow journeys: Catalogue, Add manually and Import CSV must switch the
full content area inside the same Add product screen. No further route or modal
for selecting these entry modes. Use a compact premium white/navy tab treatment,
catalogue-first content and existing picker/editor/import handlers. The native
file chooser is still needed to select a CSV file; it is not a separate app journey.
Keep input/search when switching tabs, prevent repeated imports, retain Store
scope/validation, and show actual local renders before further screen work.
Embedding the existing editor/import content is authorised by this revision;
do not build separate product pipelines or claim backend/OPPO completion.

## Current local result — tabbed revision v3, awaiting founder approval

One Add product route now opens catalogue-first with Catalogue / Add manually /
Import CSV tabs. Modes replace the body in place: no chevron entry cards, new
mode routes or editor bottom sheet. Catalogue selection embeds the existing
editor; manual reuses that editor; CSV reuses the existing importer with inline
result/error status and guarded duplicate taps. Draft and search text persist
across tab switches. Cancel clears the manual draft and returns to catalogue.
Save/Cancel remain above a simulated 300-pixel keyboard inset. Embedded Save
uses a short label to avoid the tall wrapped footer found at 200% text.

Verification: ADDENTRY 10 passed, one explicitly skipped AP-S1-001 upstream
dashboard reproduction; catalogue persistence/validation and dashboard return
checks are recorded in the task's v3 evidence report. Focused analysis of both
runtime owners and the test owner reports no issues. Normal 360-width catalogue,
manual and CSV renders, compact 200% views and keyboard-inset evidence inspected.
Catalogue preview contains review fixture products, not a connected live master
catalogue. Keyboard inset simulation is not physical keyboard/OPPO evidence.

Evidence directory:
`C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-tabs-local-v3/`.
Historical v1/v2 evidence below is retained, not the current accepted design.
No APK, OPPO, backend, publication, new dependency or implementation commit/push.
Stop for founder approval of these three states of Screen 1. Full catalogue,
manual and CSV architecture/scale qualification remain open beyond this revision.

## Historical local result — v2 arrow-card entry (superseded)

Screen 1 is implemented locally. Both Store quick action and Products Add button
open the same entry. Catalogue/manual/CSV reuse existing handlers. Entry remains
available after cancelling a picker/editor; repeated import taps are suppressed.
Store identity is checked before entry actions and after asynchronous CSV reading.
No inventory is created by opening or cancelling Screen 1.

Final focused run: 13 passed, one explicitly skipped upstream defect reproduction.
Command: `flutter test --no-pub test/work_workspace_layout_safety_test.dart
--name 'ADDENTRY01|CATALOGUE01|DASHRAIL product and promotion' --reporter expanded
--update-goldens --dart-define=MOOL_CAPTURE_STORE_VIEW_V2=true
--dart-define=MOOL_STORE_VIEW_CAPTURE_DIR=add-product-screen1-local-v2`.
These newly captured renders are review evidence, not approved golden baselines.
Focused analysis of both touched runtime owners and the test owner: no issues.

Coverage: empty Store navigation and cancel at 320/360/412 portrait widths,
200% text, direct entry in 740x360 landscape at 140% text, native-picker adapter
cancel/error/retry, simple private CSV row import, Store switch during file
selection, duplicate-tap suppression, existing catalogue save/duplicate-SKU/Store
switch protections and return to dashboard/promotion. Fixture import is not live
publication, CSV scale qualification or completion of the full shared journey.

Local images: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/add-product-screen1-local-v2/`.
Normal 360-width, 200% compact and landscape renders visually inspected.
v1 images remain retained; v2 supersedes their large-text card layout only.

| Finding | Exact reproduction / actual | Disposition |
| --- | --- | --- |
| AP-S1-001 | Empty Store dashboard, 740x360, 140% text: RenderFlex overflows by 102 pixels BEFORE tapping Add product. A stage assertion reproduced it before entry code executes. | OPEN upstream dashboard defect. Reproduction retained explicitly skipped; no landscape connected-journey pass claimed. No dashboard redesign in this ticket. |
| AP-S1-002 | Screen 1 catalogue card at 320x568, 200% text split MoolSocial across lines in v1 despite no framework overflow. | Fixed locally: icons move above full-width labels at enlarged text. Word-box regression asserts brand fits one line; v2 visually inspected. OPPO pending. |

No APK, OPPO test, backend work or downstream redesign. Runtime/test edits remain
uncommitted while founder reviews Screen 1. Registration checkpoint is
`015e16e4`; annotated work-start tag identifies a425fd89 only, not acceptance.
Next: founder approve/reject Screen 1; do not implement Screen 2 before approval.

Status: OPEN. Screen 1 implementation/local review only; no founder visual or
physical OPPO acceptance yet. Actor: authorised Retailer/Grocery Store operator.

## Founder authority and isolation

Founder approved Screen 1 registration/isolation and explicitly approved starting
from remotely verified `a425fd89445a4650533b14903d99215cfed74034` when v88 was
confirmed absent. This is a ticket-specific work checkpoint, not accepted runtime.
Do not create/move v88, alter central baseline, or falsely close Counter Sale.
Counter Sale CS-OPPO-015 is committed/pushed and remains physically unverified.
Its original checkout stays untouched; there is no concurrent Counter Sale work.

Standing authority covers only narrow, necessary blockers for this approved
ticket. No broad governance changes, new modules/backend scope, paid services,
destructive operations, production actions, APK/install or automatic acceptance.
Implement/test one screen, present the actual render, then wait for founder
approval before downstream work. Routine covered prerequisites need no repeated
permission request. Preserve source, evidence and all existing checks.

## Outcome and minimum complete scope

Classification: mvp_supporting / launch-supporting. Store inventory entry supports
the approved Buy-to-Retailer/Grocery commerce launch. Opening Add product presents
three understandable options, including when the Store has no products:

- Find in MoolSocial catalogue: existing search/scan picker.
- Add manually: existing blank product and shared editor.
- Import CSV: existing importer, not another product system.

The title is Add product. Never label this First product. Back/cancel returns
without creating inventory. Keep Store identity stable across async navigation.

## Reuse and exact owners

- `apps/mobile/lib/features/work/screens/store_add_product_sheet.dart`: entry
  presentation alongside existing picker; no additional state/service owner.
- `apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart`:
  existing `_addProducts`, `_blankProduct`, `_edit`, `_importCatalogue` wiring.
- `apps/mobile/test/work_workspace_layout_safety_test.dart`: affected entry route.
  Reuse this existing test owner for focused entry actions, responsive layout
  and retained local renders rather than adding another harness.

Existing `work_models.dart`, WorkSession inventory/persistence, scanner and CSV
handler are reused, not rewritten. New entry presentation is necessary because
the old picker immediately mixes search and products and does not expose all
three approved entry choices. No new backend, route registry or dependencies.

## Standing journey architecture — remains open beyond Screen 1

Three inputs, ONE product implementation: catalogue/search/scan prefills the
Store record; manual starts blank; CSV populates multiple records. Share model,
editor, validation, inventory, save/update and publication rules. Only input
handling differs. Do not code three independent systems.

Later approved catalogue blocks must support tap-to-add and selective editing
without compulsory review; existing Store products edit instead of duplicating.
One-time Store/payment/delivery setup stays in Store Settings. Never mutate a
global master product from a Store edit. Do not invent prices, stock, approved
photos or cloud publication. Added and publicly published are different states.
Current catalogue fixtures are not proof of a live shared catalogue or 5,000-SKU
scale. CSV matching/quoted fields/errors/retry and downstream editor shortcomings
remain separate later journey work; exposing entry buttons does not solve them.

## Tests and approval boundary

Test entry actions/cancellation, existing picker/manual/CSV dispatch, zero-product
Store, Store-switch guard, 320/360/412 widths, enlarged text and landscape.
Inspect actual Flutter local renders, not imagined mockups. No OPPO/APK claim.
Show ONLY Screen 1 for founder approval; later screens require separate approval.
Full journey remains open until all three paths have connected local tests,
founder-approved screens and physical OPPO testing with defects dispositioned.

## Scope guard

Apply the founder's supplied scope-guard image: smallest sufficient change,
reuse first, relevant call paths only, no speculative abstractions or unrelated
refactors/dependencies. Preserve validation/security/accessibility. Run relevant
checks and don't repeat passing tests absent changed inputs or required gates.
Report actual evidence/gaps; do not substitute planning for implementation.

## Exclusions and dependencies

No catalogue-block/editor/import redesign before Screen 1 approval. No shared
catalogue backend, media pipeline, payment, Store setup, Counter Sale redesign,
APK, live messages/payments, production release or acceptance tag. The exact
checkpoint admission does not approve a missing central baseline.
