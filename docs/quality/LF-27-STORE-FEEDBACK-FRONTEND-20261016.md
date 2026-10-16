# LF27 — Store customer-feedback frontend, 16 October 2026

Parent: LF13. Actor: Retailer/Grocery Store owner. Classification: mvp_supporting.
Founder delegated the minimal frontend versus wait-for-API choice; decision is the minimal frontend now, provider disconnected. New checkpoint review pending.

## Smallest complete scope

Orders entry and order-scoped entry, inbox with Overall order / Store service / Product filters, detail and capability/audience-guarded reply/report fields. Reuse WorkSession account/Store/navigation lifetime and existing Orders surface. No global route or duplicate buyer review datastore. Buyer submit target is not a Store authorization payload.

One optional frontend-proposed adapter supplies exact account/Store page, availability/coverage, central review IDs and opaque versions, permitted author/content and receiving-Store order/product references, and explicit action audiences. Default absence means unavailable, never verified empty. Duplicate pages deduplicate identical IDs/versions; conflicting versions demand refresh, not invented recency.

Commands capture original operation ID, scope, review/version, audience and content. Correlated acceptance/rejection only; timeouts/malformed/mismatched results remain unknown, no blind retry. Reconcile the original command. Session holds are not restart recovery. Enabling live actions requires a separately qualified durable-recovery adapter; this slice connects none. Never mutate customer text/stars, locally hide reports, disclose private buyer/full mixed-order data or aggregate overall into Store/product ratings.

## Acceptance and exclusions

Host-only fixtures test unavailable/empty/partial/error, scoped paging, filters/detail, scope/lifetime races, permissions/audiences, original-command recovery and retained typing, compact/enlarged layout and Orders return. Native OPPO verifies real unavailable state/navigation only; no synthetic feedback or live submission. Saved Cart/Stock/transactions preserved.

Live feed, agreed backend API, authorization, moderation, durable command recovery, order-link authority and analytics synchronization remain dependencies. No endpoint guesses, backend, runtime seeding, actual review/reply/report, APK, push, policy/registry expansion or framework. Existing literal ticket/path admission only; safety predicates/history unchanged.

## Results

Frontend slice implemented; founder review and live/provider acceptance remain pending.

Preparation correction: the first admission attempt rejected the unsupported
`thin_adapter` disposition label before application edits. Use the existing
disposition vocabulary; the optional frontend seam remains described explicitly.
No validation rule was changed and that attempt is not a pass.

First host run: 20 passed, four widget cases failed; not acceptance. Correct the
opaque ColoredBox hiding ListTile ink and test scrolling to lazily unmounted
header controls. Reply submission also did not reach its pending assertion;
diagnose the actual interaction before retry. Initial analysis warnings were
removed; subsequent analysis has zero errors/warnings and eight existing
dashboard style infos. No runtime data was changed.

Second host run: 22 passed, two test viewport assertions failed after lazy-list
scroll/rebuild; do not count it as green. Material/ink and send-after-frame fixes
worked. Re-settle and reveal actual controls before hit-testing, without silencing
missed taps or weakening command assertions. Add scoped order-link validation at
the controller boundary so a retained callback cannot navigate another context.

Third host run: all25 feedback cases passed. Architect review then identified
three additional concrete gaps, not covered by that result: reentrant context
changes during notification could still dispatch, old composers could rebind to
a refreshed version, and stale draft/completion callbacks lacked an editor
generation binding. Add failing reproductions, fix only those boundaries and
rerun. Native/provider acceptance remains pending.

All four new reentrant/stale-editor reproductions failed before the fix, then
all29 leaf cases passed after binding context/read-epoch/review-version and
rechecking immediately before dispatch. The first integrated Orders test attempt
did not compile: the new test registration preceded its local mount helper.
Move that registration below the helper; this is a host-test placement error,
not an application failure. Root-relative inspection must run at repository root,
not apps/mobile (the accompanying hash read used the wrong directory).

## Final scoped evidence

The following section qualifies17fec59f only; the later founder-requested Orders
visual follow-up is specified below and needs its own result.

- Optional typed adapter, session-owned account/Store controller and Orders inbox/detail/reply/report view implemented. No adapter is connected in the app. Existing buyer feedback and Store operational authority remain separate.
- Final affected group: 748 passed, 21 pre-existing skips, zero failures (feedback30 + existing Store atomic operations and buyer feedback scope). Orders integration: two additional passed cases at360x720/100% and640x360/200%, preserving products/orders/invoices. Intermediate layout assertions were lazy-list fixture reachability issues; unavailable status now precedes filters and the test scrolls/reveals before asserting.
- After final unknown-refresh/undispatched-draft assertions and selected-check contrast correction, all30 feedback cases passed again. Timeout keeps the original hold; a late acceptance cannot clear it. Refresh cannot enable duplicate submission; only correlated reconciliation resolves the original. An undispatched submission clears its own hold without losing the draft.
- Analysis: zero errors/warnings; new feedback leaves/test have no issues. Broader touched analysis retains nine existing style infos (eight dashboard, one layout test).
- Architect pre-plan and final context-only review completed. Four new reentrant/stale-editor regressions failed before repair and passed afterward. No remaining critical blocker identified by that review; it is not independent source/device/provider qualification.
- OPPO2b3e0f71/com.moolsocial.app.runtime: actual source hot restart5278ms, VM readback confirms both new leaves/bindings; contrast successor hot reload one library1730ms. Orders -> Customer feedback -> Store service/Product -> Back to customer orders exercised. Default unavailable state is truthful, no invented zero/feed/reply/report. Screenshot inspected at task outputs/lf27-feedback-final-20261016.png. Native populated/reply/report, enlarged text/landscape and real provider paths remain host-only or unverified, not passed native cases.
- Restart retained the one-item₹164 Cart readback and Store overview₹29550 Stock cost,18 low-stock products,24 available/6 unavailable. No new Stock/order/invoice/payment/review/reply/report, feedback backend call, runtime injection, APK or publication was performed. Original financial/provider holds were not operated.

Limitations: `commandRecoveryReady` is an adapter assertion, not proof of real authorization or recovery. Before any live adapter is enabled, qualify authentication/Store membership, permitted privacy projection/audience enforcement, original-command durable restoration/correlation, moderation and real feed paging/versions. The current hold and reply drafts are session-local. This source checkpoint does not close LF13 or the whole frontend/MVP.

## Founder-requested Orders visual follow-up

Actual OPPO screenshot: task outputs/lf27-orders-audit-20261016.png, empty saved
queue. Defects: separate Create and Feedback48dp rows push the queue down;
secondary feedback competes with creation; heading repeats the selected count;
selected stage is weakly differentiated; product-barcode scanner occupies order
search space; empty-state coverage explanation is technical and verbose.

Predetermined correction: one compact Customer orders toolbar with one-tap New
order (accessible Create customer order label;48dp icon fallback when labels
cannot fit) and secondary48dp feedback shortcut. Keep title readable at200%,
feedback/order guards unchanged, no collapsed rail or new menu. Selected stage
gets solid navy/white; avoid a repeated heading count, with compact current-scope
text only when the selected chip is offscreen. Hide scanner only in Orders/search context, preserve Stock/procurement
scanning, keep search and alerts. Plain-language coverage warning still says
online orders may be missing; no false verified zero or missing-provider claims.

Acceptance: normal Orders toolbar plus filter strip <=112dp from surface top;
at200% responsive labels/icons remain readable and48dp targets reachable without
overlap. Compare native queue start against audit y630px; do not shrink touch
areas to gain space. Host populated/attention/history/keyboard, order-create
recovery/disabled guards and Feedback return; real OPPO empty view and saved data
only. Same existing LF27 owners, no new governance or application business scope.
Follow-up implemented; results below. Founder screen approval remains pending.

Follow-up test progress: baseline reproductions failed at173dp normal/186dp
enlarged narrow and Feedback unreachable in landscape. New geometry passed after
the toolbar change, but test setup needed correction: selection is a Tristate,
semantics handles must be disposed inside the test lifetime, and repeated
plain-name flags combine rather than selecting alternative groups (no tests ran
in that selection attempt). An added Stock scanner assertion guessed a header
owner that Stock does not use; replace that with actual Orders search-width and
existing procurement scanner coverage. None of those failed/no-test attempts is
acceptance. No native orders were manufactured.

Six new Orders checks now pass. The broader O01-04 group passed55 cases and
failed three legacy Counter-invoice recovery fixtures at their old Profile-on-
Orders tap. HEAD17fec59f contains that same stale tap; current approved design
allows Profile only on Store home. Correct that fixture navigation, keeping its
zero/one/duplicate-invoice recovery assertions unchanged. Do not restore an
unapproved duplicate profile icon or claim the failed group green.

### Follow-up result

- Six LF27 layout/navigation/search checks passed, including standard360x720,
  narrow320x568 at200% and landscape640x360 at200%. Create/Feedback remain aligned,
  independently reachable48dp targets; accessible action names and selected-stage
  semantics checked. Enlarged titles can wrap; no fixed48dp text clipping.
- Existing O01-04 Orders/search/history/invoice group58 passed; DASH06 operational
  Phone composer, journal/recovery, stale/late callback and guarded actions180
  passed; RESTOCK02 procurement catalogue/scanner controls2 passed. Total246
  selected checks, no failures/skips in these groups. No app logic was altered to
  make old profile fixtures pass; they now navigate through approved Store home.
- Current-stage count is in its selected chip normally. When that chip scrolls
  outside the viewport, the existing toolbar shows a small stage/count breadcrumb.
  Measurement key remains on the chip, not that breadcrumb; existing metric
  scheduling covers rebuild/resize, updates only on change and keeps queue width.
- Analysis: zero errors/warnings, nine existing style infos. No new owners,
  routes, framework, policy/registry or admission-script changes in this follow-up.
- OPPO2b3e0f71: four-library hot reload3604ms; loaded source confirms toolbar,
  contextual-scanner flag and retained-scope logic. Actual queue start moved
  y630 -> y484 physical pixels:146px reclaimed. Create and Feedback share one row;
  order-search bounds widened x32-492 -> x32-580, with Store alerts retained.
  Navy/white selected All, More/Earlier stages, offscreen All breadcrumb and
  Feedback/Orders return were checked. No new order was created on the device.
- Inspected native before/after screenshots are task
  outputs/lf27-orders-audit-20261016.png and outputs/lf27-orders-compact-20261016.png.
  OPPO has no applicable live customer orders; populated/large-text queues and
  financial/recovery cases remain labelled host evidence, not native provider
  acceptance. No business data, backend/service, APK or publication changes.

## Second Orders recheck — founder request, 16 October 2026

Fresh OPPO capture `lf27-recheck-0701.png` confirms ca795c04 is loaded, not an old
APK/source diagnosis. Remaining defects: four fixed header/control bands; New
order and Feedback still reserve their own row; duplicate title consumes useful
queue height; horizontal stage edge lacks a strong separation from its arrow.

Predetermined correction: retain Store identity/status. Merge order search,
Create, Feedback and Alerts into one utility row; minimum48dp touch targets,
flexible readable search, named secondary icons, subtly tinted primary creation.
No visible duplicate Customer orders heading; retain screen heading semantics.
Keep active search's existing editable header and return context. Keep filters
immediately below, explicit divided More/Earlier control and current-stage
breadcrumb when its chip is offscreen. A partially visible horizontal chip is
not itself evidence of text truncation inside its full chip.

Acceptance: separate search band absent only on Orders operation; all four
utilities direct/reachable at360x720,320x568200%,640x360200%; existing busy/create,
search/history, feedback return and data-preservation tests retained. Native
before/after queue bounds measured, no invented populated queue or transactions.
Architect context review recommended this consolidation without new action logic.
Founder approval remains pending; backend/APK/publication scope unchanged.

### Second recheck result

- Demonstrated the extra fixed band with three failing unified-layout tests.
  Final selected suites: LF27 layout/semantics/search/feedback9, O01-04 Orders/
  search/history/details58, DASH06 guarded creation/draft/journal/recovery180,
  RESTOCK02 procurement/scanner2:249 passed, no failures/skips. Final analysis
  has no errors/warnings and the same nine existing style infos.
- Old visible-heading/search-caption assertions were updated to the consolidated
  toolbar and readable Search text; heading semantics, actual text scale, queue
  viewport, exact-order returns and financial assertions remain. Initial fixture
  errors used search-button instead of existing search-field key; corrected to
  verify actual editable input and retained search query, not remove that check.
- Native inspection also exposed a clipped badge after consolidation; top8dp
  padding fixes it. A focused test reproduced16dp queue movement when the selected
  stage reminder appeared; putting it within the search button fixes that move
  while preserving its visible text and semantic value. No fixed-height text crop.
- Fresh OPPO before `lf27-recheck-0701.png` and final
  `lf27-orders-final-0744.png` inspected: queue starts y484 ->410 physical pixels,
  another74px recovered on this same empty All view. All four utilities are
  separate48dp targets, badge5 fully visible, no duplicate title/action row.
  Final source reload3803ms; VM script readback confirms the actual unified
  header, original search callback and inline selected-stage reminder.
- Native search/Finish, Feedback/Back and Alerts opening checked. More shows the
  full Delivery label; selecting Delivery0 shows its proper empty state and
  Earlier/All restores selection. Queue remains y410 when All scrolls offscreen.
  The strip intentionally remains horizontally scrollable; a partial preview
  chip can still appear at its edge. Do not claim every chip simultaneously fits.
- No native New order submission, business-data edit, fake populated feed,
  backend, APK, push or neighbouring-screen redesign. Enlarged/populated layouts
  are host evidence only; live provider evidence and founder review remain open.

## Single manual entry — founder execution, 16 October 2026

Founder approved removing Orders Create customer order shortcut and manual
Counter/Phone/Chat source selector. Sales -> Counter sale is the shared manual
editor with new-shop defaults and existing optional delivery recipient/address
validation. Keep Orders for incoming/fulfilment and its feedback/search/alerts.

Existing Phone/Chat sources, draft identity, history, amounts, Stock and payment
state must survive. Reuse the old entry's async account/Store/journal guards in
Sales selection, not merely remove the button and strand recovery behind its
Counter+At-the-shop-only condition. Preserve currently mounted bill/invoice.
Delivery completion returns to Orders only for its exact saved context; selecting
a payment method is not collection or dispatch. No provider or schema change.

Regression-first: Orders shortcut absent; retarget existing manual/journal tests
to actual Sales entry, replacing obsolete source-dropdown assertions with source
preservation/no-selector checks. Keep amount/Stock/payment/stale-scope assertions.
Test shop/own/Mool fulfilment and failures, account/Store change during journal
read, unknown submission, close/reopen and accessibility. Hot reload OPPO without
creating commerce. No backend, APK, push, policy/registry or new framework.

Implementation test incident: the new manual-sale smoke test was registered
before local enterSaleCustomer declaration, repeating the known Dart forward-
local helper error. Move the test after that declaration, retaining assertions;
do not alter app logic or skip the test. An earlier readback also used ROOT-style
path in APP cwd; use explicit ROOT reads and APP Flutter commands. Failed compile
and wrong-path diagnostic are not app regressions or passed test evidence.
A generated test-only replacement patch was rejected for a missing added-line
prefix; no file changed. Correct the patch encoding and retain exact-match review.
Another test-only patch mixed reverse-ordered hunks and was rejected without
writes. Keep follow-up hunks in source order. Navigation fixtures must stop at
Sales home instead of blindly issuing the old Orders-based number of Back taps.

Architect review identified a delayed-entry navigation risk. A focused held-read
test reproduced it: leave Sales and return before the journal read completes;
the old async preparation cleared selected APP-1043 to null despite the original
Sales widget being gone. Bind preparation to the originating Sales widget's
mounted/view/scope callback before any selection reset, not merely current root
account/Store equality. Keep the failing test and exact-order assertions.

### Single-entry result

- Orders Create shortcut/callback removed. Source dropdown and operational-only
  widget flag removed, not the shared billing engine or persisted source field.
  Sales Counter selection now awaits the existing journal/scope guards before
  mounting its editor; merely opening Sales home does not load that editor.
  A mounted bill/invoice is retained. New bills default to shop; existing
  Phone/Chat source, draft ID, fulfilment and payment facts survive recovery.
- Existing review offers Take now/My delivery/Mool delivery and requires the
  confirmed address for delivery. Its exact successful saved-order callback
  returns to Orders without treating a retired submission as an unsaved draft.
  No inferred serviceability, dispatch or payment collection was added.
- Fixed the reproduced late-read selection reset through a callback bound to
  the originating Sales state. The focused test also proves the existing
  single-flight guard rejects competing Manage/Counter choices while the read
  is pending. No extra global navigation epoch or framework was introduced.
- Final suites: DASH06185 (including Phone and Chat journal states and delayed
  visit), LF2711, O01-0458, DASH096, first-tap2, Mool layout1, RESTOCK022:
  265 passed. One existing local Store1-40 screenshot-capture case stayed skipped;
  it is not native acceptance. Analysis:0errors/0warnings,9existing style infos.
- Native OPPO hot reload4259ms and VM script readback confirm removed shortcut/
  selector, visit-bound preparation and existing fulfilment choice. Inspected
  outputs/lf27-single-entry-orders-20261016.png and
  outputs/lf27-single-entry-counter-final-20261016.png. Search widened after
  shortcut removal. Sales -> Counter -> Back -> Sales -> Counter works; original
  customer9000091941,0units/₹0 and visible saved products remain. No bill saved,
  quantity changed, transaction or synthetic record created on the device.
- OPPO is left on Counter sale. Completed sales/delivery/recovery scenarios are
  host-fixture evidence only; native real commerce/provider results, APK and
  founder acceptance remain unclaimed. Four literal owners only, no policy,
  registry, admission-script, backend, schema, other tree or push changes.

## Founder acceptance and exact source publication — 16 October 2026

Current disposition supersedes the historical pending-review statements above.
Founder accepted the single manual Sales entry and private settings recovery,
then replied "Approve bounded review checkpoint" for LF17/22/24/25/26/27.
The final review reran60 focused cases (LF17:2, LF22:23, LF24:2, LF26:3,
feedback:30), all passed, and reused unchanged valid caller/settings evidence.
Actual OPPO reviewed attention full details, the existing private Cumin offer,
customer defaults, feedback filters/Orders return and the unchanged164 Cart/
original payment hold without Save/Apply, financial commands or injected records.
Running VM source matched six relevant files; unchanged-source hot reload953ms.
Host-only cases, existing customer-title ellipsis, live provider dependencies,
customer-term durability and cold new-APK qualification remain explicitly open.

Founder then answered "yes" to allowing only publication of this checkpoint.
Accepted application SHA:cf08fb91ee6ba64973c9230c7db2f424bdd67cf1. The existing
LF branch contains41 incremental commits after accepted combined base3c5a454b.
Allow only that source or one direct metadata-only successor touching this MD/
JSON and the existing two checker scripts/test. Published HEAD will therefore
be recorded separately from the accepted application SHA. No app/test/assets/
native/build/provider change, history rewrite, force push, split or new framework.

The focused new publication reproduction first rejected the exact accepted LF27
handoff identity before the bounded allowance. Afterward33 checks passed in both
PowerShell7 and Windows PowerShell: exact/missing/foreign identity, unrelated
ticket, source/asset/backend/policy/other-doc delta, unapproved descendant/merge,
empty successor, build denial and wrong accepted-source argument. These are
guard tests, not repeated app/device qualification. Real committed publication
gate and exact remote equality must still pass before reporting publication.

All existing literal ownership, base/history/registry/policy-byte and secret
checks remain. Handoff additionally rejects staged/unstaged/untracked content;
the four already-audited generated support paths may retain only their observed
unstaged, normalized-empty line-ending state, never arbitrary generated work.
No file is reset or deleted to make status appear clean.

This is publication of the existing LF frontend branch under its current
admission, not an integration edit/merge or reopening either old pinned
integration worktree. The completed direct-baseline guard/state is untouched;
its integration-only procedure is not repurposed as a new publication framework.
No application implementation occurs, so no new Store/Counter application-edit
receipt is claimed. Founder-source coverage and all provider/APK limits remain.
Keep the normal remote-state/fast-forward safety check immediately before push.
