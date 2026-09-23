# Cursor Buy integration handoff and new-baseline request — 22 September 2026

## Current disposition

Latest founder request: reconcile every Cursor ticket and all local/Git work after
the installed Redmi APK before the next candidate. Reconciliation from clean
`5f2b4428a093de2eb9d7ae3f8f47b8c2c117eb4a` identifies **22 post-r66.32 frontend
tickets: 11 initial fixes/contracts + 3 product controls + 8 latest tickets**.
Child fixes are retained under their parent tickets, not counted twice. Approved
application source is `0a224e546b7c570cf2ba7772cf25e2c030ffee98`; all later commits
are retained. Use the COMPLETE clean branch for the next candidate, not only the
latest eight-ticket source commit. See the latest reconciliation record below
and `next-redmi-reconciliation/apk-inclusion-manifest.json` in the evidence ZIP.
Git preservation/inclusion is verified; no fresh APK qualification, build or
installation is claimed. Google/provider and test-maintenance deferrals remain.

Historical eight-ticket implementation assessment follows:

22 September, latest founder authorization: implement the eight OPEN follow-up
tickets below, locally test connected journeys, register impacted-code/child
defects and retest, then show actual local Flutter screens for founder approval.
This supersedes their earlier registration-only status for this bounded batch.
Integration is explicitly postponed while Codex is busy. No APK, backend,
unrelated module, other-worktree or policy changes belong to this batch.
Starting checkpoint: `757640edd252f61bdd03e3c05d43bf56b525834a`, clean and remote-exact.
Application source at start remains d9ec753b; prior fixes/evidence are preserved.

Execution assessment: mvp_supporting; consumer Buy discovery, product decisions,
order/invoice access and scoped location controls. Reuse existing Buy views,
catalogue, screen, design helpers and session/provider contracts; no separate
screen stack or parallel Store catalogue. Implementation owners are the existing
claimed Buy UI files and focused Buy test owners. Shared models, native setup,
provider deployment and Codex-owned invoice/profile implementation are excluded.
Reuse `_openOrderInvoice` and existing downloads wiring rather than fork them.
Sequence: compact Compare/orders/promotions and fixed Cart/search presentation;
product hierarchy; category/search consistency; location popup; focused journey
tests, child inspection/corrections and rerun; actual local captures for review.

Initial dependency `CHILD-8-MAP-PROVIDER`: this baseline exposes
`BuyV2ShoppingAreaSource.locate/resolve` but supplies no production implementation
and no embedded Google Maps dependency/component. Its area value has a Google
place ID/label, not a current GPS coordinate or map controller. Reuse the existing
interface for the compact current-location UI and truthful failure/retry states;
record any remaining actual map/provider integration separately. Do not draw a
fake map, show sample coordinates as current, or claim live location acceptance.
No provider/permission/native change is silently authorized by a local mock test.
Check this dependency while completing independent UI work; it must remain
visible in the final ticket disposition if unresolved.

Validation: reuse focused production-widget/session tests for Shop, Wholesale,
Offers, Orders, Store and nested product/Cart returns, normal/large text, short/
long content, Android/keyboard insets and missing/failed provider states. Capture
real Flutter renders, explicitly distinguish fixtures from live provider proof,
retain failed logs and register any child before retry. No approved reference
image is overwritten and founder visual approval remains pending.

Founder explicitly requests reconciliation of ALL Cursor work after the previous
integrated baseline, clean local Git, remote preservation and a detailed Codex
handoff. This is a source/evidence handoff, not production or device acceptance.
The original parked source checkpoint is `a78b1b38803b4dca6fcc7d715ee9ccc9528a4482`;
the original evidence-only completion commit is its direct child
`a4ff1e5fde01cdfea29f1bf576bde35aa64a3b6e`. The three authorized product-control
repairs below are a subsequent source delta. Integrate the complete branch
including that delta, not only a78b1b38. The original inventory/receipt remains
bound to the historical checkpoint; it is not relabelled as the later source.
Latest application source: `0a224e546b7c570cf2ba7772cf25e2c030ffee98`.
The eight-ticket source `f4d2e116bb1a42f10d588ac82e36cd23065d6523` remains an ancestor.
The d9ec753b product-control source remains preserved in its ancestry.
Backend implementation has NOT started. No APK is made.

Actor/outcome: the integration owner can preserve the complete Buy frontend and
its Store-facing contract while combining it with Store, Counter Sale and CSV.
Classification: mvp_supporting; prerequisite for non-regressive commerce integration.
Reuse the existing branch, repository, source owners, tests and gate mechanisms.
The smallest complete operation is inventory, preservation, commit, validation,
remote readback and this handoff. No production merge, history rewrite, new
feature, provider deployment, release, credential operation or unrelated policy
work is authorized. Cursor's existing narrow blocker authority covers the exact
historical commit-label admission described below.

## Exact history to preserve

- Worktree: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921`.
- Branch: `work/cursor-ui/buy-ready-20260921`; remote: existing repository `origin`.
- Previous Store/Buy integration: `123ff42cf8179b272d33b480e8267dfa83af2de3`.
- Previously integrated Cursor tip: `ee42be0e21f1707e1cbf2ba3ad966579f118b209`.
- Originally assigned checkpoint: `06432e2b946b02007d9946c562f922294f485632`.
- Full inherited checkpoint including subsequent Store CSV work:
  `79d5401338881f55e65b08c0e7843cbac016fcfb`.
- Pre-reconciliation Cursor HEAD: `87bc96d4c28300146c9e2c3c3b37c7c3aacffed0`.
- Thirteen Cursor commits follow the full inherited checkpoint. Fourteen commits
  follow the originally assigned checkpoint because that range also includes
  Codex's `79d54013` CSV checkpoint. Both ranges must remain reachable.

The adjacent `CURSOR-BUY-INTEGRATION-INVENTORY-20260922.json` records full commit
SHAs, parents, trees, changed owners, working-file fingerprints, inherited tips,
protected-owner equality and evidence disposition. Integrate the complete branch
history; selecting only the latest eleven fixes would omit earlier work.

At reconciliation start, all 40 files in the prior parked-source manifest matched
their recorded SHA-256 exactly. The 41-record status also contained unchanged
generated files with stale index metadata. Their content equals HEAD; no source
is discarded to obtain a clean status. The generated Flutter private-plugin path
correctly points into this Cursor worktree. Regenerate local tool metadata for
the integration worktree; never bind it to another owner's filesystem directory.

## Complete functional scope retained

Earlier commits and the pre-APK local changes include the public Visit Store
redesign; compact Store identity with long-name support and founder-reviewed
motion; Store-only catalogue/search/filter/category scope; More stores wiring;
unboxed Store search; keyboard and Android inset repairs; compact filters and
controls across Buy; active-only Delivery rail; theme-consistent Offers cards;
Saved SKU action clearance; explicit Delivery/Collect at store checkout choices;
Store-sourced concise address and user-tapped Google Maps link; precise customer
copy, product information and unavailable-state repairs from the Redmi audit.
The full historical reports and candidate reference captures are retained.

Latest eleven-ticket local cutoff (details and child evidence in
`CURSOR-BUY-LOCAL-CUTOFF-20260922.md`):

| Ticket | Result retained for integration |
| --- | --- |
| 1 / RB006 | Exact generated Store names normalized in Cart/checkout; genuine names preserved. |
| 2 / RB007 | Store search expands; Finish/Android Back restores scoped controls, filters and paging. |
| 3 / RB008 | Consistent names in Store/draft/Maps handoff; authentic destination still needs Store data. |
| 4 / RB011 | Existing Security return preserves pickup checkout and Cart on sign-in cancellation. |
| 5 / RB012 | Local provider-unavailable/payment-failure/retry behavior verified; live completion remains DEP-01. |
| 6 / RB013 | Pickup promotion removed from both public Store info and Wholesale preview; compact Recent Add; visible area checkmark. |
| 7 / RB018 | Compact unselected payment-benefit cards without an empty status row. |
| 8 / RB022 | One stable accessible recipient-field name while focused; no duplicate editable node. |
| 9 / RB026 | Active estimate says Delivery, without changing actual delivered history/status. |
| 10 / RB029 | Exact Store/SKU/variant identity and honest missing-data boundaries; authentic media/projection remains DEP-02. |
| 11 | Explicit offer classification and location/time-bound multi-option eligibility throughout public Buy. |

Nine implementation tickets are locally closed. Tickets 5 and 10 are complete
only for their frontend portion, with external dependencies explicitly OPEN.
Additional locally corrected children cover cached eligibility after invalid
refresh, address changes, missing Store address, available browsing despite
unavailable ordering, courier versus Scheduled labels and MOQ-independent
Wholesale artwork. No unresolved local child is knowingly hidden. These local
results do not imply fresh Redmi acceptance or live commerce completion.

## Shared public contract returned to Codex

Authoritative implementation: `apps/mobile/lib/features/buy/buy_v2_models.dart`,
`buy_v2_content_contracts.dart` and `buy_v2_session.dart`. The inventory binds
their exact Git blobs and SHA-256s to the source checkpoint. Reuse these types;
do not create a competing Buy fixture catalogue or four standalone Store toggles.

- `BuyV2Product.offerClass`: nullable `retail | wholesale | bulk`; unknown stays
  unknown. MOQ, pack size, quantity tiers and freight are independent concepts.
- `BuyV2ProductFactsSnapshot.eligibility`: nullable `BuyV2OfferEligibility`.
- JSON schema version `1`; required fields: `productId`, `storeId`,
  `sourceRevision`, `customerLocationKey`, UTC `observedAt`, UTC `expiresAt`,
  `offerClass`, `channelEnabled`, `storeReady`, `fleetAvailable`,
  `customerLocationConfirmed`, `options`.
- `options`: zero or more `quick | scheduled | courier | freight | collection`.
  A SKU can have several options. Optional `scheduledSlotId`, UTC
  `scheduledStart` and `scheduledEnd` are required for a valid Scheduled grant.
  Optional `reviewFixture` defaults false; simulated grants never qualify live
  production eligibility.
- Malformed schema/enums, missing/expired/future observations, identity/class or
  location mismatch, disabled channel and unready Store fail closed. Quick and
  Scheduled require fleet and confirmed customer location. Scheduled also needs
  a named future interval. Courier alone is not a booked slot.
- Public location keys bind region, selected Google place and selection revision.
  Catalogue query key v4 includes this identity. Empty-location v2/v3 compatibility
  and the separate Store-procurement purchaser/supplier contract are preserved.
  Providers must echo the exact requested location key; never construct a nearby
  but different identity or accept an earlier page after location/filter change.
- Facts are checked at use time, not just when loaded. Add and checkout preserve
  Cart when eligibility expires/changes, and recheck before provider submission.
  Store catalogue may remain browsable when ordering eligibility is unknown.

Codex owns Store settings, shared product editor, CSV and provider projection.
Use the same versioned Store identities, variants, photographs, prices, stock,
address/location and channel/payment terms. The unfinished Store handoff is a
dependency, not proof that this mapping already works. Resolve the recorded
founder rule that every Store offers collection against the earlier Store-side
disable flag; do not hide the disagreement in successful fixtures. An authentic
Store address is still required to give a customer a usable pickup destination.

## Local verification and its limits

The adjacent evidence ZIP retains sanitized host logs, manifests and the exact
historical-admission test. Failed intermediate runs remain available; none is
relabeled passed. The local-only raw evidence archive additionally preserves
device screenshots/XML, videos and APKs without publishing customer/device data.

- Final local regression selection: 630 passed and one old persistence expectation
  failed; its corrected focused rerun passed (1). All 631 selected checks therefore
  passed across those runs, not one claimed all-green run. No runtime change
  followed the main run.
- Partner suite: 11 passed and four old missing-address fixture expectations
  failed; the 20-pass child rerun includes corrected checks refusing fabricated
  Store addresses and retaining Cart.
- Focused router/semantics run: 44 passed, one existing capture-only skip.
- Procurement/payment/retry/paging/eligibility contract run: 146 passed.
- Analysis: zero errors/warnings, style-only information retained.
- Previous r66.32 qualification had two full Buy passes: 2472 passed, 27 skipped,
  zero failed each. Those qualify the old APK source ONLY, not this cutoff.
- Reconciliation reruns the history/owner/secret/whitespace/handoff checks. It does
  not repeat long app suites without a source change or represent a Git-only
  operation as new runtime qualification.

The original r66.32 APK remains `1.0.0-r66.32+2026092201`, debug review only,
SHA-256 `F74ADCD10DE5A5DFA3F6A29F024484DCB8CAF294FB0682C01680EB7190F2CF8A`.
Its build authorization is consumed; its sealed manifest is immutable. It does
not contain the latest eleven-ticket cutoff. Never reuse that APK authorization
or rewrite its source record to suggest that it does.

## Preservation and narrow handoff repair

All 18 required integrated tips are ancestors; the coverage gate also rejects
the two recorded rejected tips. Store/Counter Sale/CSV, native implementation,
backend and dependency owners remain equal to the full inherited checkpoint.
No other worktree has been edited. Existing source-admission/brand/egress changes
belong to the historical exact r66.32 review snapshot, not a grant for new source.

The historical subject blocker is solved without rebase, squash or changed SHAs:
the bootstrap remains validated by its original exact binding; seven subsequent
legacy labels are admitted by exact commit AND subject only in this worktree,
branch, task, ticket and handoff phase. Twenty-five positive/negative checks prove
unknown commits, altered labels and wrong contexts remain rejected. Future
commits still require `ui(buy-ready-20260921): ...`. Cleanliness, owner, ancestry,
secret, integration, acceptance and release checks are unchanged.

Local recovery: `C:/GUARANTEED OUTCOME/outputs/buy-integration-handoff-20260922`.
Initial source ZIP/patch and manifest preserve the pre-commit bytes. A separate
hash-verified archive preserves every file in the five task-specific evidence
directories, deduplicating equal bytes with exact restore-path mappings. Raw
APKs/device evidence remain local; Git receives source, reports, approved local
captures and the sanitized host-evidence archive. Generated build caches are not
application source. A verified Git bundle and final remote readback receipt are
recorded there at completion. No original evidence is deleted or moved.

## Message to Codex: integrate, then hand over the next baseline

Please use the exact source and handoff commits in the completion record below.
Fetch this branch, verify the remote SHA and inventory, and retain its entire
ancestry back through `79d54013`, `123ff42c` and the prior Cursor tip. Do not
integrate only the most recent commit or copy loose files over your checkout.

Use the authorized isolated integration worktree and existing integration rules.
Preserve Store, Counter Sale, CSV, approved Buy layouts, shared navigation and
the above public eligibility contract. Resolve overlaps deliberately, especially
Buy models/content/session, shared Store projections and existing coordination
controls; never replace your current controls wholesale with Cursor's older copy.
Record source-to-integrated owner fingerprints and explain every conflict change.

Run applicable changed-owner, secret, dependency, source/brand/egress/UI-lock,
focused and combined regressions. Cover Store-specific discovery/search/SKU,
variant identity, Saved/details/Cart, quantity/price/stock, pickup versus delivery,
authentication return, unavailable providers, procurement/Counter Sale/CSV,
stale pagination and every eligibility failure case. If the sealed-source gates
reject new integrated code, qualify that exact revision through their existing
process; never carry the r66.32 snapshot exception forward by changing its hash.

After integration, hand Cursor a clean, remotely verified FULL baseline: exact
repository/worktree and branch, commit plus any required annotated tag, both
source branch SHAs included, reconciliation manifest, shared contract hashes,
combined test evidence, remaining dependency list and next ticket ownership.
Confirm that no Cursor commit/file or Store work was omitted. Backend starts
only from that delivered baseline with the required accepted UI/contract binding.
Cursor remains parked until then; this handoff does not start backend work.

Mandatory next Redmi replay, together with backend tickets: all eleven local
dispositions and children, keyboard/Back/insets, Store search and scope, names,
compact Recent/benefit/Offers, accessible request field, active delivery wording,
live authentication/payment/order recovery, authentic Store SKUs/photos/address/
Maps, multiple eligibility options and expiry/location changes. Keep DEP-01
(live providers), DEP-02 (authentic Store projection/media/destination) and DEP-03
(isolated zero-active Delivery rail dataset) open until actually verified. The
founder explicitly deferred an APK for this eleven-ticket batch.

## Completion record

Source commit: `a78b1b38803b4dca6fcc7d715ee9ccc9528a4482`.
Source tree: `087809d63073b6528fe59237efe5180965348136`.
It preserves all 13 earlier Cursor commits and commits all 43 remaining changed
files, including earlier uncommitted source/test/evidence. All 56 payload blobs
match the inventory. The three generated/native files that had stale status
metadata equal HEAD byte-for-byte and contain no omitted changes.

Verified at the source checkpoint:

- Coordination implementation, pre-commit and clean handoff: PASS; 59 exact
  owners, registry 4616 and its original SHA binding unchanged.
- Incremental handoff: PASS. Its r66.32 version arguments identify the historical
  ticket only; this is not a fresh APK build authorization or source qualification.
- All 18 required inherited tips: PASS; two rejected tips remain rejected.
- Historical secret scan: all 13 Cursor commits, 84 unique blobs / 77 text blobs,
  zero matches; staged and committed gate scans also passed.
- Historical subject-admission tests: 25 positive/negative checks passed.
- Staged whitespace: PASS. Payload fingerprints: 56/56 matched.
- Source, tests and captures remain byte-identical to the verified pre-reconcile
  snapshot; only the documented narrow handoff controls and documentation changed.
- Clean status: 0 staged, 0 unstaged, 0 untracked. Empty status SHA-256:
  `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
- Actual `origin` branch readback equals the source commit. No force push,
  history rewrite, merge, production/main or other-worktree mutation occurred.

Verified recovery artifacts:

- `cursor-source-since-integration.bundle`, SHA-256
  `f655abb8230a4d8b616bfffcd7b100a6fe8d2f269a767629d3dd55a2b6f44418`.
  This is an incremental Git bundle containing the complete source branch since
  `123ff42cf8179b272d33b480e8267dfa83af2de3`; that existing integrated commit is
  the explicit prerequisite, not an omitted new change. Bundle verification passed.
- Local raw evidence: 1,560 files, 1,301 hash-verified unique blobs; archive SHA-256
  `bfc6ffb9784e180458b307593cdaff5fefeb316f02748858758490deff77fec6`.
- Remote host-evidence ZIP: 62 retained files, 525,213 bytes; exact hashes and
  per-file mapping are in the committed inventory and ZIP manifest.
- Original r66.32 source manifest is unchanged. Prior archives and evidence are
  preserved in place; the new archive is an additional recovery copy.

The completion commit changes only this handoff and its inventory, with no source,
test, control or asset change. The final receipt at
`C:/GUARANTEED OUTCOME/outputs/buy-integration-handoff-20260922/final-verification.json`
binds that commit, clean status, both handoff gate results, final bundle and exact
remote readback after publication. Verify that receipt/remote ref before consuming
the handoff. This does not claim `ticket_acceptance`, `ticket_close`, new device
acceptance, production promotion or integration of Codex's unfinished Store work.

Cursor is parked pending Codex's new full integrated baseline requested above.

## Reopened ticket: CURSOR-BUY-COMPARE-SHEET-REGRESSION-20260922

Status: **OPEN — previously implemented behavior reported regressed by founder**.
Registered after the original eleven-ticket cutoff and Git handoff. This is a
separate follow-up, not a claim that the prior eleven-ticket batch fixes it.
Founder instruction: "register ticket - earlier this was implemented".
The earlier implementation is founder-reported; its exact commit and where the
behavior was lost must be traced before repair. Do not label this a new feature
or assert an integration-loss cause without that evidence.

Actor/outcome: a public Buy/Wholesale shopper opens Product details -> Compare
prices and sees a compact, readable comparison state with an accessible retry.
Classification: mvp_supporting; restore the previously requested compact Buy UI.
Current authorization is registration only; no implementation or APK in this turn.

Observed on Redmi at 16:50:23 local, 22 September 2026:

- Installed app: `1.0.0-r66.32-cursorreview`, version code `2026092201`.
- Product: Stone-ground wheat atta, Case of 10 x 5 kg; Compare prices is open.
- Supplier prices are unavailable; the retry action is visible, followed by a
  very large unused white area. The sheet does not shrink to the short content.
- The parked source also retains `FractionallySizedBox(heightFactor: .88)` in
  `_showBuyV2ProductComparison`, `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`.
  This is the observed sizing cause; earlier-fix provenance remains to be traced.
- Screenshot: `C:/GUARANTEED OUTCOME/outputs/redmi-current-screen-20260922-165023/current-screen.png`.
  SHA-256: `ed38f866139ea95c5db17f441b30c9db4d94aacf39171d80941bc4875ad1c604`.
  Adjacent `capture.json` records build, foreground app and assessment. No device
  taps or navigation were performed during the capture.

Expected repair scope: reuse the existing comparison sheet, controller and route.
Size unavailable, empty and loading states to their content with safe viewport
limits. Populated comparison results may grow and scroll. Preserve approved
typography, touch targets, SafeArea, Android navigation clearance and retry.
Find and reconcile the earlier implementation rather than introducing a second
comparison UI. No backend, Store-worktree, policy or unrelated redesign work.

Acceptance and child checks for the implementation ticket:

1. Identify the earlier implementation/acceptance revision and record why the
   current source and installed build do not exhibit it; preserve unrelated work.
2. Cover unavailable/error, loading, empty, short and paged/populated results at
   normal and enlarged text, narrow screens and Android system insets. Short
   states must not reserve an almost-full-screen blank area or clip text/actions.
3. Refresh, dismiss and Back retain the exact originating product, Store, filters
   and Cart. Preserve same-SKU/pack comparison, pagination and eligibility checks.
4. Keep supplier-provider data unavailability as the existing separate dependency.
   The layout repair must be testable without live data and must not invent offers
   or prices, turn a failed request into success, or mark provider completion closed.
5. Run focused local layout/navigation tests; inspect children; replay on the next
   authorized Redmi candidate together with the existing eleven-ticket/backend
   obligations. Do not mark this reopened defect closed from registration alone.

Handoff addition for Codex: carry this OPEN regression and its screenshot into
the new integrated baseline/backlog. The app source, existing local test results
and deferred provider/Redmi obligations are unchanged by this registration.

## Authorized follow-up: product controls and truthful Delivery rail

22 September 2026: founder explicitly reopens Buy-only frontend work for the
three defects below after parking. Actor/outcome: a shopper can change quantity,
reach the same Cart while scrolling product details, and see Delivery only for
current confirmed delivery records. Classification: mvp_supporting; repair existing
commerce controls. Reuse screen, views, session and existing focused tests. No new
screen, backend, Store, Counter Sale, CSV, routing, policy or APK work. The separate
Compare-sheet ticket above remains registered, not implicitly implemented here.

Evidence directory: `C:/GUARANTEED OUTCOME/outputs/buy-controls-regressions-20260922-170230`.
Initial Redmi screenshot `001-current-screen.png`, SHA-256
`af7e3692dcb32ae2b8c309fb3913b94dd55a0ab3670e10c076a8c9d9911d87d5`.
Installed r66.32/2026092201; starting source
`fd87c94eff19c8c741624d20b2cf22790f9aab63`. Screenshots 002/003 record scrolling
and the Delivery panel; existing device Cart/orders were not erased.

| Ticket | Observed defect and intended correction | Status |
| --- | --- | --- |
| CURSOR-BUY-QUANTITY-WIDTH-20260922 | Wholesale product `− quantity +` spans the entire screen. Repaired with intrinsic width, readable quantity, 44px targets and existing MOQ/stock/amount behavior. | LOCALLY IMPLEMENTED AND TESTED; Redmi replay pending |
| CURSOR-BUY-DELIVERY-PROVENANCE-20260922 | Main rail shows 9+; panel exposes 12 retained review orders including seed MS-240782. Active delivery now requires current provider confirmation or a fresh completed placement; history is retained. | LOCALLY IMPLEMENTED AND TESTED; Redmi replay pending |
| CURSOR-BUY-CART-SCROLL-STABILITY-20260922 | Product scrolling moves Cart between floating summary and rail. Shop/Wholesale details now keep one fixed Cart target in the bottom rail with basket and return state preserved. | LOCALLY IMPLEMENTED AND TESTED; Redmi replay pending |

Exact implementation owners: `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`,
`buy_v2_screen.dart`, `apps/mobile/lib/features/buy/buy_v2_session.dart` and
existing `buy_v2_post_redmi_fixes_test.dart` / `buy_v2_session_test.dart` plus
affected focused Buy tests if a fixture requires a current placed/provider order.
No shared model or provider schema change is proposed. Eligibility, auth and
live order/payment completion still use the existing contract and dependencies.

Local acceptance: normal/enlarged text, narrow portrait and short landscape;
compact stepper plus/minus/edit/MOQ; stable Cart at top/middle/bottom and Back from
Cart; no badge for no orders, samples, cached-only, completed, Care or pickup;
badge for freshly confirmed/provider-active delivery; provider refresh/expiry of
retained records; existing delivery and cart regression. Capture actual local
screens. New fixes require the next authorized Redmi build for device closure.

Local results and child inspection:

- Ten focused new checks pass, including 320/360/390px portrait, 800x360 landscape,
  100/140/200% text, Android insets, stepper plus/minus/edit, MOQ, Cart top/middle/
  bottom, correct basket and exact product/scroll return. Retained-only orders
  remain history; ready provider confirmation activates Delivery and an empty
  current provider response removes it. New explicit review placement activates
  its own record without activating the inherited samples.
- Initial five-file regression: 725 passed / 53 failed. Investigation found
  38 tracking-double failures (the double declared current order/quick state but
  not the new current-delivery list), 10 comparison/Cart fixture failures (missing
  explicit eligibility prevented Add) and five existing active-delivery image
  fixtures. Focused rerun: 57/57 passed. The final Cart/comparison/reference rerun
  after adding explicit successful-Add assertions: 17/17 passed. No test was
  skipped, no assertion removed and no protected reference image updated.
- Tracking doubles now explicitly declare current deliveries. The existing five
  golden cases explicitly exercise their two-active-delivery fixture, preserving
  the approved images. Separate new real-session tests prove samples alone do
  not activate the rail. The comparison fixture supplies versioned, time/location-
  bound eligibility instead of depending on absent provider data.
- Child found in visual review: enlarged Cart count covered the cart glyph.
  Badge text is bounded at 130% while the full count/total remains accessible.
  All ten new checks and four native Flutter captures were repeated afterwards.
- Analysis of all seven changed Dart owners: exit 0; zero errors/warnings and
  eight existing style information items. No live provider or payment completion
  is claimed. This was a frontend presentation/provenance defect, not proof that
  the backend had an active delivery.
- Logs: `regression-r1.log`, `regression-fixtures-r2.log`,
  `cart-fixtures-final.log`, `controls-captures-final.log`, `analysis-r2.log` in
  the evidence directory. Final images: `local-captures-final/`. The initial
  20 generated failure images and their earlier tracked bytes were archived and
  hash-verified before restoring only those generated owners to exact HEAD bytes;
  `reference-evidence-preservation.json` records this. Nothing was deleted.

Stop boundary: no new APK, backend work or implementation of the OPEN
registered tickets (Compare-sheet height, search Delivery fleet and compact
order/invoice actions, Medicine promotions, cross-Buy Cart movement, and product
information organization, category/search consistency, and the current-location
Shopping area popup). All earlier
eleven-ticket device/provider obligations continue. Carry these three repairs
into the integrated baseline and replay them on the next authorized Redmi APK.

### Registration only: Delivery fleet appears in Buy search

`CURSOR-BUY-SEARCH-DELIVERY-FLEET-20260922` — OPEN, not implemented.
Founder supplied this fourth defect during the three-control repair, then
explicitly limited subsequent inputs to registration. Finish only the three
already-started implementations and their local tests; stop afterwards.

Current Redmi capture `004-buy-search-delivery-fleet.png` in the evidence
directory above shows the expanded Buy search, keyboard and a truck/9+ delivery
control next to the search completion tick. Screenshot SHA-256:
`22a849bb4071ac832d8cfe1629f5f9746768907985c9003a4d08c27a35a62a6d`.
Installed build remains r66.32/2026092201. No navigation was used for this capture.

Expected: no delivery fleet/tracking control or expanded tracking panel anywhere
in the Buy search surface, even when genuine deliveries are active. Preserve
the active order and its tracking outside search. Reuse existing search state
and delivery presentation; no backend or provider change is implied. Future
acceptance must exercise active/no-active delivery, expanded/collapsed tracking,
keyboard shown/hidden, query entry/results, search exit and product/Back return.
The existing keyboard header `trailingAction` calls `_buildDeliveryControl`;
this is the source lead for the future implementation, not a completed fix.

### Registration only: compact order management and invoice actions

`CURSOR-BUY-ORDER-INVOICE-ACTIONS-20260922` — OPEN, not implemented.
Founder reports excessive screen use by Manage order / View invoice and asks
for a decision that preserves Codex's newer invoice/consumer Downloads work.
Current Redmi screenshot `005-offers-order-invoice-actions.png` shows order
tracking with **Orders** selected in the bottom rail (the request called it
Offers). Two large full-width outlined actions are stacked below Address,
Items and Help. SHA-256:
`fc2016ef39b6c81ed3d8d2674cbe3a4861ee8119be3d83559a6545ef48cc8dfe`.
Installed r66.32 remains unchanged; capture used no navigation.

Founder agreed to this design decision (Annotation 1); implementation remains
unauthorized under the explicit registration-only instruction. Retain a compact
**Invoice** action for this exact order, alongside **Manage order** in the
existing lower action area. Use one compact icon/text row where space permits,
with accessible wrapping at enlarged text; preserve at least 44px tap targets.
No new top tabs, oversized full-width cards or second invoice implementation.
Consumer-profile Downloads should remain the central document list. The
contextual action must open the same authoritative invoice/download flow by
order ID, not require searching the full Downloads list for a known order.

Source lead: tracking actions in `buy_v2_views.dart`, keys
`buy-tracking-manage-order-<id>` / `buy-tracking-invoice-<id>` and existing
`_openOrderInvoice`. Retain Manage order eligibility, return/replace/refund,
support and correct Back navigation. Preserve honest invoice-pending/error
states. Inspect the other View invoice/Manage order placements for the same
layout issue when this ticket is authorized; avoid unrelated redesign.

Dependency: verify the exact Codex invoice-format and consumer Downloads source
revision at integration before wiring it. The latest Codex implementation is
reported by the founder, not verified as present in this installed APK or Cursor
baseline. Do not fork its invoice renderer or modify Codex's checkout.
Future checks: same-order invoice identity, visibility by availability/permission,
view/download success/failure/retry, pending invoice, active/delivered order
actions, normal/large text, Android insets and retained scroll/Back context.
Standing instruction remains registration only; no application change for this
ticket was made during the current three-defect repair.

### Follow-up source parking and Codex handoff

Exact application commit: `d9ec753b6c2f1dae9a7f9689ac6e1303b80353db`,
subject `ui(buy-ready-20260921): repair product controls and delivery provenance`.
It directly follows the Compare registration checkpoint
`fd87c94eff19c8c741624d20b2cf22790f9aab63`. All earlier parked/inherited source
checkpoints remain ancestors; no prior commit was rewritten or omitted.
The seven tested Dart owner blobs exactly match the committed source manifest.
No Store, Counter Sale, CSV, shared model/schema, native, backend, dependency or
policy owner changed in this follow-up. The ninth changed file is the existing
evidence ZIP; the eighth is this handoff.

`CURSOR-BUY-INTEGRATION-EVIDENCE-20260922.zip` retains all 63 earlier entries
byte-for-byte and adds the new captures, failed/passing logs, preservation record,
and `product-controls-followup-20260922/followup-manifest.json`. Archive SHA-256:
`247e99e235c7a88cb52c9c78d27735e400ee1b73163807cf7c2e79a36f898980`.
The later invoice registration screenshot and agreed decision have their own
`registration-addendum.json` entry. The original inventory's ZIP fingerprint
continues to identify its original commit, not this extended archive.

Codex: integrate through this latest application commit with the full earlier
history. Carry the OPEN registration-only tickets below and all pending eleven-
ticket/provider/next-Redmi obligations. Return an exact integrated baseline SHA
before Cursor begins the separately authorized backend phase. Latest source
eligibility fields/schema are unchanged; delivery provenance is internal session
state populated through existing current snapshots, order refresh and placement.
No new provider API is requested by these three frontend repairs.

This final metadata commit contains no additional runtime changes. Local receipt
`source-checkpoint.json` binds the tested source; `parking-verification.json` in
the same evidence directory records final clean Git, handoff gate results,
exact remote readback and incremental recovery bundle after the metadata commit.

### Registration only: remove deferred Medicine promotions from public Buy

`CURSOR-BUY-MVP-MEDICINE-PROMO-20260922` — OPEN, reproduced on Redmi.
No implementation started.
Founder requests removal of lower Medicine promotion tiles, or replacement with
a relevant consumer promotion, consistent with the launch scope.

Verified authority: central production `AGENTS.md`, Git commit
`745664fcfe0bdd9049065d7eb0644425462bcfe6`
(`docs(launch-scope): record bounded Buy Store and shared delivery launch`),
20 September decision. Buy, Retailer/Grocery Store and the supporting Bulk/Biker
delivery workspaces are included; Care/Medicine transactional exposure is
deferred and its source/evidence must be preserved. This ticket removes public
promotion/entry affordances; it does not delete the deferred module or rewrite
the launch decision. Broader route/backend exposure controls remain their own
existing launch obligation.

Design decision: remove these lower Medicine promotions and collapse the vacated
space. Do not invent replacement offers or add a new promotional subsystem.
Only reuse an already-wired, launch-relevant consumer Buy/Store promotion if its
content and availability are verified. Preserve products, store navigation,
scroll continuity, Android clearance and brand styling.

Capture attempt after power/network recovery: `006-medicine-promotion.png`
actually shows Android Home, not the reported promotion. SHA-256
`36df3ac3b757eb81910e7c929bd22bd77e5fd88bda2afe25b7a20a4a7d242de5`.
One tap on the visible Cursor Review launcher icon resumed a noodles product
detail screen; `007-review-app-after-resume.png`, SHA-256
`c635b7173a3d06b0a5600590d1ca54df05c0ed1bacde8c74b2eb408805a51d57`.
Neither image proves the Medicine promotion. Founder has been asked to display
the exact screen. Do not mislabel these captures as a reproduced defect.

Founder subsequently displayed the target and requested capture (Annotation 1).
`008-medicine-promotion-target.png` now proves the lower **Medicine and Wellness**
promotion, subtitle **Browse the licensed pharmacy catalogue**, next to another
promotion beneath the SKU grid. Orders is selected and the header reads Search
orders or ID; preserve this observed context without inferring its full entry
journey. Capture used no taps or navigation. SHA-256:
`3527bc6892cc8d2a29069f8ae21a4a78b3ed829289ffafaa602b8ace72724de8`.
This is the target defect evidence; earlier 006/007 remain labelled capture
attempts only. Requested disposition remains remove the Medicine promotion and
collapse the space, without a speculative replacement or module deletion.
The exact subtitle is present in `buy_v2_views.dart` in the lower promotion
owner. The existing evidence ZIP now additionally preserves capture 008 and
`medicine-promotion-confirmed.json`; its extended SHA-256 is
`b1730d10bf1cb7ae2a8234bf31975e4a730a3def7c8fc63543da202820bc4b50`.
The earlier ZIP fingerprint above remains the fingerprint at source commit d9ec753b.

Future acceptance: identify the exact lower promotion owner from the target
screen, remove its deferred Medicine call to action without an empty spacer,
check normal/enlarged text and narrow/landscape layouts, and verify existing
consumer Buy/Store actions and scroll/Back behavior. Retain registration-only
status until the founder separately authorizes implementation.

### Registration only: predictable Cart position across the full Buy module

`CURSOR-BUY-CART-POSITION-ALL-SURFACES-20260922` — OPEN, founder-reported.
Founder reports that the moving Cart is not controllable. Proposed choices are
(A) a fixed position or (B) a fixed default position with movement only when the
customer explicitly drags it. Coverage must include Buy/Shop, Wholesale, Offers
and Orders rather than only one product page.

Recommended design: option A, one fixed Cart position in the existing lower
navigation/action area wherever a Cart entry is appropriate. Eliminate automatic
floating/repositioning while scrolling, changing content or opening overlays.
Reuse the existing Cart target and scope resolution; do not introduce another
Cart or a new gesture/state subsystem. No implementation of this new ticket is
authorized under the standing registration-only instruction. Option B is a
recorded alternative, not permission to add draggable behavior by default.

Relationship to the completed three-defect batch: source commit d9ec753b fixes
the Cart position on Shop/Wholesale product details, with local top/middle/bottom
and return tests. It intentionally leaves catalogue dragging/avoidance intact.
That narrower repair does not close this wider ticket, and the installed Redmi
r66.32 does not contain it. Do not count an older installed observation as proof
that the parked source fix regressed.

Future audit/acceptance: catalogue, category/filter/search and results, Saved,
Visit Store, product details, Offers, Orders and nested order/product return;
Shop/Wholesale and aggregate Cart scope; empty/single/mixed baskets and quantity
changes; active/no-active Delivery; scroll top/middle/bottom, keyboard, overlays,
orientation, enlarged text and Android insets. The Cart must remain reachable,
must not obscure SKU actions, and must preserve basket, scroll and Back context.
Inspect Cart/checkout's own actions for duplicates without adding a floating Cart
to screens that already own the Cart journey. Verify no hidden auto-drag or
reposition callbacks keep moving the control after the fixed design is applied.
Register any uncovered child issue; preserve routing, amounts and checkout wiring.

### Registration only: compact, organized public product information

`CURSOR-BUY-PRODUCT-INFORMATION-REDESIGN-20260922` — OPEN, founder-reported;
registration only. No application implementation or new APK authorized by this
entry. Actor/outcome: a consumer opening an SKU from Shop, Wholesale or Visit
Store can quickly understand the product, price/pack and applicable purchase
terms using only information intended for that public audience. Classification:
mvp_supporting; improve the existing product-information journey.

Founder requirements (a–i), retained in full:

1. Categorize and reorder all text into a clear hierarchy: product identity and
   selected variant; price/pack/quantity; key product facts/specifications; relevant
   fulfilment and purchase terms; concise seller identity and Store access.
   Use existing public fields and condition sections on the actual product data.
2. Highlight decision-critical information with restrained typography and accent
   treatment. Avoid making every label equally prominent or relying on colour
   alone to express availability or other meaningful state.
3. Remove exact repetition and repeated meaning across titles, badges, facts,
   descriptions and terms. Preserve distinct facts: pack price versus unit price,
   MOQ versus pack size or quantity tiers, variant identity and required terms
   must not be mistaken for duplicates. Do not rewrite provider facts inaccurately.
4. Use compact, subtle label/value rows or a responsive tabular arrangement.
   Adapt to short/long provider text, missing optional fields, number of facts and
   available width. Allow useful wrapping/expansion without clipping information,
   oversized blank rows, tiny text or forced equal-height empty sections.
5. Repair the **+ Add** action's largely empty full-width lane. Place the existing
   Add/quantity control compactly with the purchase summary where appropriate;
   retain accessible tap targets, prices/totals, stock/MOQ validation and Cart
   updates. The earlier compact-stepper repair does not close this Add-lane issue.
6. Make the complete page compact, professional and premium, including spacing,
   information density, alignment and the relationship between image and text.
   Keep important purchase information and actions easy to find.
7. Polish text colours, surfaces and gradients within the approved MoolSocial
   brand. Use light/ restrained accents; do not clutter the page with large solid
   colour blocks or a collection of competing highlighted cards.
8. Apply the same information organization wherever this product page is wired:
   Shop/Buy, Wholesale, public Store/supplier pages, search, categories/filters,
   Saved, Offers and existing related/compared/order-to-product entry paths.
   Retain the correct Store/SKU/variant and channel-specific meaning on each path.
   Do not activate deferred Medicine/Care or add new journeys to obtain coverage.
9. Add, remove, retain or relocate information between product and Store pages
   according to its purpose. Keep product-specific facts and relevant purchase
   terms on the product page; centralize general Store information on its existing
   page with concise context/link here. Preserve access to all applicable public
   information supplied by Store instead of deleting it solely to save space.

Data boundary: use the existing Store-to-public mapping and provider contracts.
Only publish fields explicitly intended for the consumer/current permitted
channel; never dump the Store record or expose private stock operations, internal
notes, purchasing costs or account data. Preserve authoritative field values and
their SKU/variant/Store identity. Do not invent information to fill a section.
Omit empty optional presentation; keep honest unavailable/loading/error states
and existing ordering restrictions for missing critical data. Any missing shared
public field requires coordination with Codex, not an unrelated Store-worktree
edit, parallel backend or invented Buy-only fixture contract.

Reuse assessment: existing `BuyV2ProductView`, purchase-action/quantity owners in
`apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`, product-entry/return wiring in
`buy_v2_screen.dart`, and existing public product content/facts/session contracts.
Reuse public Store pages for Store-level information. No separate product screen,
new navigation framework, backend, shared-schema edit or policy work is included.
Record the precise implementation owners and public-field mapping before a future
authorized implementation. Current registration changes only this MD.

Acceptance for that future implementation: normal/large text and narrow/landscape
screens; short/long product, variant and Store names; dense and sparse public
metadata; long prices, units, descriptions and terms; genuine missing provider
data; image fit; contrast/brand consistency; Android/keyboard clearance; compact
Add, quantity editing and totals; correct selected variant, basket, checkout,
originating Store/filter/search and scroll/Back return. Review every existing
entry path for duplicate meaning, blank lanes and inconsistent presentation.
Take actual local screens for visual approval, run focused interaction/regression
tests, register child defects and retain next-Redmi replay as separate acceptance.
Coordinate with the OPEN cross-Buy Cart-position ticket so the redesigned page
does not reintroduce moving Cart or obstruct its product actions.

### Registration only: category presentation, inline search and thumbnails

`CURSOR-BUY-CATEGORY-SEARCH-CONSISTENCY-20260922` — OPEN, founder-reported;
registration only. No application implementation or APK authorized by this entry.
Actor/outcome: a consumer can browse the appropriate category set and search
within Shop, Wholesale or the selected public Store using consistent controls.
Classification: mvp_supporting; presentation and interaction consistency in
existing public catalogue journeys. Store's category-layout mismatch is reported,
not newly reproduced or independently tested during this registration.

Founder requirements:

1. **Separate categories, shared presentation.** Shop, Wholesale and each Store
   retain their own purpose-specific category data, selections and product scope.
   Use the same full-page category picker/pop-up design across all three, including
   title/close controls, typography, spacing, selection treatment, image placement,
   scrolling and Android clearance. A common layout must not merge category sets
   or inject general-home categories/SKUs into a Store. Reuse the existing approved
   category presentation rather than developing three independent screens.
2. **Unboxed, expanding search.** Make the Shop, Wholesale and public Store search
   bars inline/unboxed and expand inline when tapped, matching the Buy-home search
   interaction and visual treatment. Preserve focus/keyboard, clear and finish/
   collapse actions, Android Back, recent/query state and result selection. Store
   search stays within that exact Store; Wholesale and Shop retain their respective
   channel/category/filter context. Returning from a product restores the source
   search, query, selection and scroll position. Do not replace expansion with a
   permanently boxed field, separate new search route or unrelated search service.
3. **Small category photo thumbnails everywhere.** Add compact square photos to
   public category entries wherever those categories appear across Shop, Wholesale
   and Store. Follow the SKU photo-square treatment with a visibly smaller category
   thumbnail, consistent fit/corner treatment and alignment. Keep category labels
   readable and the overall selection target accessible; image size must not force
   tiny tap targets or oversized rows. Use existing public category imagery/mapping,
   with a compact honest fallback for missing/failed images. Do not arbitrarily
   substitute unrelated SKU photos, invent provider content or build a separate
   category taxonomy. Coordinate any genuinely missing shared image field with
   Codex before changing a contract; no Store-worktree edit is included here.

Reuse/relationship: inspect existing category and Store catalogue presentation in
`apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`, search presentation in
`buy_v2_screen.dart`, existing sheets in `buy_v2_views.dart`, and current session
category/search state. Exact owners must be confirmed before future implementation.
RB007 already implements Store search expansion in the earlier local cutoff;
compare its exact source and current route against installed r66.32 first. Carry
forward that work and repair uncovered presentation/entry cases instead of
reimplementing it or claiming a pre-existing fix failed solely from an older APK.
The OPEN search Delivery-fleet ticket remains separate and must not be lost.

Future acceptance: visual parity of the full-page category picker in all three
contexts; distinct category identities and correct scoped results; short/long
labels and sparse/large category lists; thumbnails loaded/loading/missing/broken;
normal/enlarged text, narrow portrait and landscape; keyboard and Android system
insets; search open/type/clear/finish/Back/product-return; selected category/filter
and pagination retained; stale requests after Store/filter/location changes must
not replace current results. Confirm no horizontal clipping, oversized blank
areas, accidental global Store search or deferred Medicine exposure. Reuse current
navigation/providers, preserve Cart and checkout state, capture actual local
screens and inspect child defects when implementation is separately authorized.

### Registration only: compact Shopping area popup with current-location map

`CURSOR-BUY-SHOPPING-AREA-CURRENT-LOCATION-20260922` — OPEN;
registration only under the standing instruction. No application change or APK.
Founder clarifies that the top location icon represents the customer's current
shopping location. Replace the existing Shopping area popup content and manual
area-choice screen with a compact Google Map/pin popup that automatically centers
on where the customer is presently located when opened.

Actor/outcome: a consumer can establish the current shopping location directly
from the top location control without selecting a predefined area list.
Classification: mvp_supporting; location selection supports the existing scoped
catalogue and fulfilment eligibility. The requested design replaces the current
popup; do not layer a second manual-area interface beside it.

Future implementation requirements:

1. Reuse the top location entry and existing shopping-location state. Show a
   compact map with a clearly visible current-location pin, concise resolved
   location label if available, and minimal apply/close controls. Automatically
   request a fresh foreground position when opened with permission, then center
   the map. Do not require typing or choosing an area before showing the location.
2. Respect the OS foreground-location permission flow. Explain loading, denied
   permission, disabled location services, timeout, approximate/low-accuracy
   position and map/network failure truthfully, with a suitable retry/settings
   action. Do not claim an old saved address, default city or invented coordinate
   is the customer's present position. Do not introduce background tracking.
3. On applying a valid location, reuse the existing catalogue-area/provider
   mapping and location-bound eligibility refresh. Prevent stale location or
   search responses from replacing newer results; preserve pagination rules and
   Store/channel scope. A map pin alone does not prove delivery serviceability,
   Store readiness or fleet availability.
4. Keep this browsing location distinct from a Store's physical address, a
   Google Maps route to the Store and the customer's confirmed checkout delivery
   address. Do not silently overwrite checkout addresses or an existing order.
   Dismiss/Back without applying must preserve the prior selected shopping area.
5. Remove the old manual-area content from this entry and reclaim blank space.
   Use compact brand-consistent styling, a useful map viewport and accessible
   controls. Do not add extra tabs, decorative panels or a large empty sheet.
6. Explicitly verify keyboard and Android-hidden-content defects after the
   future implementation. Opening from focused search must handle its keyboard;
   map, pin, close and apply controls must remain reachable above keyboard/system
   navigation insets. Test Android Back, permission/settings return, repeated
   open/close, narrow/short screens, landscape and enlarged text. Do not treat
   keyboard absence in the default map state as sufficient coverage.

Reuse/dependencies: inspect `showBuyV2CatalogueArea`, the top location handler in
`buy_v2_screen.dart`, current location/map adapters and the shopping-area source
in `buy_v2_session.dart`. Confirm the existing Google Maps/current-position
capability before implementation; actual GPS, permission, map credentials and
location-to-catalogue mapping must work for runtime acceptance. If a capability
or shared contract is missing, register and coordinate that exact dependency
instead of substituting a screenshot/sample pin or claiming live integration.
No native configuration, new dependency, backend, Store-worktree or policy change
is performed or implicitly authorized by this registration.

Future evidence: real current-location centering on Redmi with permission,
denied/offline/services-disabled recovery, fresh versus stale position, apply
and cancel behavior, correctly refreshed scoped catalogue/eligibility, preserved
Cart/checkout state, and local keyboard/inset/layout/navigation tests. Inspect
and register child defects; visual approval is separate from technical/device
acceptance. Existing manual-area behavior remains installed until this ticket
receives implementation authorization and a later authorized APK is qualified.


### Founder additions during the eight-ticket implementation — 22 September 2026
- CHILD-7-STORE-SEARCH-EXPANSION: Visit Store search must expand horizontally when focused/typing, not merely hide its toolbar. Hide the redundant outside close/info chrome while typing, keep an inline Back action, preserve query and Store scope; verify keyboard and Android Back.
- CHILD-7-WHOLESALE-STOREFRONT: Wholesale Visit Store still takes the legacy supplier-preview branch even with a paged Store provider. Use the same Store catalogue and home-style SKU tiles for both public channels; preserve Wholesale prices, MOQ, filtering, save, product navigation and scoped Cart. No Store-provider or Codex-worktree edits.
Both are authorized additions to the current frontend/local-test batch; integration and APK remain postponed.

Founder clarification (Annotation 1): CHILD-7-STORE-SEARCH-EXPANSION applies to every applicable newly implemented public Store entry in Buy/Shop and Wholesale, including alternate full-catalogue routes. Verify focus, typed query, clear, finish, keyboard dismissal and back navigation with exact Store/channel scope; do not limit the fix to a single entry screen.

Founder visual refinement: category popup header must be thinner so categories start higher; support dragging upward to full screen. Applied to the shared Shop, Wholesale and Store picker, preserving safe insets, scroll and category scope.

### Local implementation checks and child findings (in progress)
- CHILD-7-SAVED-SEARCH-BACK: Saved-at-Store branch omitted the normal search PopScope; Android Back could dismiss the Store instead of finish search. Fixed in the shared saved branch; targeted regression pending.
- CHILD-7-CATEGORY-KEYBOARD: shared category grid needs explicit keyboard clearance after draggable expansion. Added bottom clearance and focus-to-full-height; keyboard/large-text verification pending.
- Visual review: duplicated product rating/return summary, fallback pack facts and empty benefit panel took unnecessary space. Removed only already-present fallback/identical summary content; explicit manufacturer, quantity, legal/public metadata and failure/retry remain.
- Preserved failed local evidence: store-r1 exposed an incorrect Wholesale test selector (supplier-action vs actual store-action); focused-r3 caught a duplicate modal argument inserted into the wrong similarly named helper and was corrected; focused-r4 invoice test used a historical seed with no order lines and the wrong page key. The corrected test uses an actual locally confirmed review order with line records and the existing invoice-page identity. No runtime invoice guard was weakened.
- Focused-r2: 11 tests passed before subsequent visual refinements. This is intermediate evidence, not final acceptance.

CHILD-6-ADD-LANE: final screenshot showed compact Add still in a mostly blank hero row. Move the existing Shop Add/quantity control beside the price when width/text size allows, with wrapping at large text. Existing eligibility and cart callbacks remain authoritative; Wholesale retains its dedicated compact trade dock.

CHILD-TEST-CHECKOUT-DELIVERY-FIXTURE: broader run passed 119 functional checks and failed five immutable checkout images. Visual comparison identifies the inherited inactive-seed Delivery rail change, not a Cart/check-out defect from this batch. The protected fixture now explicitly provides its two current deliveries, following the existing scoped-Cart reference-fixture pattern; ordinary sessions and provenance guards are unchanged. Twenty generated diagnostic images were hash-preserved externally before restoring exact pre-run tracked evidence. Original golden images are unchanged. Exact pass/fail logs remain retained.

CHILD-TEST-WHOLESALE-ROUTE: two RV6 assertions still expected the superseded supplier preview underneath the full Store. Updated the expected Back destination to the direct Store route used by both channels, retaining quantity, Store scope, empty-cart and destination-change assertions. Fresh-source behavior passed through the journey before the outdated final route assertion.


## Eight-ticket frontend batch — local review checkpoint

Latest implementation supersedes historical OPEN/registration-only labels for this batch. Founder visual approval, integration and fresh-device acceptance are still pending; no APK or backend work was performed.

| Ticket | Local disposition |
| --- | --- |
| Compare sheet regression | Content-sized short/error sheet, capped and scrollable for populated results; unavailable and populated/nested-return checks pass. |
| Delivery fleet in search | Hidden throughout public search even with a current delivery; restores after search without losing order state. |
| Order/invoice actions | Compact wrapping inline actions with 44px targets; exact-order invoice and resolution routes verified. Existing invoice implementation reused. |
| Medicine promotion | Removed only the deferred Medicine card from public Orders continuation; relevant Shop/Wholesale cards remain. |
| Cart position | Fixed rail Cart on public catalogue/product/Orders/Offers paths; scope, quantity, product return, large text and landscape continuity verified. |
| Product information | Larger readable adaptive fact rows; conservative duplicate/empty-content removal; explicit public compliance retained; compact Add beside price where it fits; Wholesale trade dock preserved. |
| Categories/search consistency | Shared thumbnail grid and thin draggable popup across Shop/Wholesale/Store; drag to full height, keyboard clearance, independent selection; Store search expands horizontally on focus, including saved mode. Wholesale paged Visit Store now uses the same home-style SKU tiles. |
| Shopping location | Compact automatic locate/retry/confirm UI through existing provider interface; selected place opens its Google Maps pin externally. Manual area lists removed. Live current location and embedded Google Map remain dependent on CHILD-8-MAP-PROVIDER; do not close live-map acceptance. |

### Child inspection and validation

In-scope children resolved and retested: saved-Store search Back, category keyboard clearance, Wholesale route parity, Store search width, thin/draggable category header, product Add empty lane, repeated/fallback product facts, and explicit historical reference fixture state. No remaining observed frontend child failure in the exercised checks. This does not claim exhaustive Buy/backend/device acceptance.

- `focused-r5.log`: 13/13 focused checks passed before the final Add-lane refinement.
- `regression-r1.log`: 119 functional checks passed; five inherited active-delivery reference fixture failures subsequently corrected without changing any reference images.
- `store-regression-r1.log`: 18 passed; two assertions still expected the removed Wholesale preview route. Corrected only that expected destination and retested all four affected RV6 journeys.
- `final-validation-r1.log`: **38/38 passed** on final runtime source, covering two root category journeys, 13 targeted cases, 10 product-control checks, four RV6 Store continuation cases, four populated Compare/Offers returns, and five unchanged checkout image comparisons.
- `analyze-final.log`: seven changed Dart source/test owners, **no issues**.
- `git diff --check`: passed. Historical reference files unchanged; 20 generated failure diagnostics preserved with hashes before exact pre-test restoration.

Actual local review screens and every failed/passing log are in:
`C:/GUARANTEED OUTCOME/outputs/buy-eight-ticket-local-review-20260922`.
`review.html` links the final unedited Flutter renders. `captures-final` includes normal/200% text, Store/Wholesale parity, expanded search, category keyboard and drag behavior, product/Cart, order/invoice, comparison and provider-failure states. Test catalogue artwork is explicitly labelled Illustration; fixture data is not a production Store handoff or live location proof.

No shared model/schema, Store, Counter Sale, CSV, native/dependency, backend or policy owner changed. Retain all prior integration ancestry and pending next-Redmi obligations. Codex integration remains postponed; request/verify its exact new baseline before backend work starts.

### Source parked safely; integration postponed

Application commit: **`f4d2e116bb1a42f10d588ac82e36cd23065d6523`**, directly after the clean registration checkpoint `757640edd252f61bdd03e3c05d43bf56b525834a`. All seven changed Dart owners match the tested files and committed normalized blobs. Earlier source and integration checkpoints remain ancestors. Nine changed owners: four Buy UI, three focused tests, this handoff and its existing evidence ZIP.

The source commit is pushed to `origin/work/cursor-ui/buy-ready-20260921`; exact remote readback matched. Pre-commit and clean source handoff checks passed. The incremental handoff initially rejected the staged tree, as designed; rerunning after the commit passed with no control changes. No governance/policy file was edited. Historical r66.32 gate arguments do not authorize a new APK or qualify these changes for device release.

The evidence ZIP retains all 93 pre-batch entries byte-for-byte and adds final screenshots, test logs including failures, diagnostic preservation, source fingerprints and source parking receipts. Final archive SHA-256: `e0ac969d3e12302aaa39e782c3bf0cf2137f42890f77fbe799ae4a6e425072b2`.

Founder review is pending. CHILD-8-MAP-PROVIDER remains an integration prerequisite for real auto-location and an embedded Google Map. Permission/offline/retry/late-result behavior was tested through the existing interface with labelled local fixtures. Do not claim live GPS or complete Store backend acceptance. Preserve the previously recorded next-Redmi replay obligations alongside this batch; no APK was made.

Final metadata parking receipts and incremental recovery bundle will be in the same local evidence directory. Codex should eventually integrate this complete branch, then return its exact new baseline before backend development begins; integration remains postponed now.


### Founder rejection — product information remains scattered

The founder rejected the product information arrangement in the f4d2e116 local screenshots. Those commits are safely parked technical checkpoints, not approved UI. Continue the same bounded product-information ticket from clean `3d837cb54f50c4dfef7c10b3ee6e680f5b66f453`.

Strengthened acceptance: (1) one product/variant/pack/price/Add group, (2) one explicitly labelled Store identity/status/Visit Store group, (3) one aligned Delivery & returns table with promise, method, address and applicable provider terms, (4) Wholesale-only commercial terms in their own group, and (5) specifications/protection/reviews below. No delivery/return sentences floating in the product hero and repeated in a second card; no generic fulfilment explanation occupying its own row. Preserve distinct pack/unit prices, MOQ/tiers, public compliance, actual provider state and all action callbacks. Readable aligned labels/values must wrap for long content and large text, without distributing words across the screen. Reuse the shared product page across Shop, Wholesale and Store entry paths, locally test and show new actual renders for founder approval. No APK/integration/backend/policy changes.

Implemented review revision: compact price/pack/savings and Add group; Store identity, seller type, operating status, provider location and Visit store together; one aligned Delivery & returns table shared by Shop and Wholesale; Wholesale freight/tax/verification grouped under Wholesale terms. Removed repeated hero delivery/returns and generic fulfilment row. Separate fields retain identical values when their meaning differs; only equivalent dispatch/method/return summaries are deduplicated. Existing public compliance, trade quantities, recovery/navigation and purchase callbacks remain. Wholesale Add minimum height restored to its existing 50-pixel regression requirement (CHILD-PRODUCT-TOUCH-TARGET fixed and retested).

Validation on this revision: 42 selected tests passed in `product-organization-final.log`; the one new long-provider test initially failed because it tried to reveal an unbuilt lazy-list child. Corrected to scroll through the actual list; that test and both original Wholesale touch-target/decision cases passed 3/3 in `product-provider-final.log`. Total 45 distinct passing checks include normal/200% text, long provider terms, same-value/different-label retention, closed Store blocking Add, Store/Wholesale route parity, Cart/search, Compare and five unchanged checkout goldens. Analyzer and whitespace checks passed. Actual unedited Flutter screenshots: `product-organization-final` and `product-provider-final` in the existing local evidence directory. These are local fixture renders, not a Redmi APK or live Store-provider acceptance.

CHILD-PRODUCT-LEGACY-ASSERTIONS remains OPEN: a separate historical four-suite run had 12 passes, one existing skip and 11 failed cases. Two Wholesale touch-target cases now pass after the 50-pixel correction. Nine cases still assert superseded presentation/selectors: Wholesale facts/Seller in the old fulfilment card (2), generic fulfilment prose (1), availability text/delivery inside the hero (1), old Delivery details/List price/Available to add copy (3), old catalogue review-button selector (1), and absence of Visit store (1). Exact failures are preserved in `product-contract-regression-r1.log`. Those four test files are outside the current recorded focused-test owners; they were inspected/run, not edited, and no ownership or policy controls changed. Updated layout, data-retention, Store status and actions are asserted in the already-owned focused test. Reconcile the legacy assertions before full-suite/integration acceptance; do not report the complete historical suite or all child tickets closed. Founder approval of this revised screen remains pending. Safe parking is not integration approval.

### Founder approval and propagation verification — 22 September 2026

Annotation 1: founder approved the product information preview at `0a224e546b7c570cf2ba7772cf25e2c030ffee98` and instructed application across Buy, Store, Wholesale and affected entry points. This supersedes the pending visual-review statement for that product layout only. Same bounded ticket: verify the shared `BuyV2ProductView` in root and nested Store routes, including search/saved/recent entry paths. Add focused route assertions in existing owned tests; preserve channel data, minimum quantities, scoped navigation and Cart. No separate screen, provider/backend/APK/integration or policy changes. Approval is visual acceptance, not complete technical or live-provider acceptance.

Propagation evidence: both root and nested Store routes instantiate the same `BuyV2ProductView` (`buy_v2_screen.dart`); search, saved, recently viewed, comparison and order-item entry paths reach those owners. The approved application source remains exactly `0a224e54`; no separate layout or runtime changes were necessary. Ten route-level checks passed in `approved-propagation-r4.log`: Shop/Wholesale search, saved and recently-viewed product actions (6), and Visit Store product opening/return with scoped search/categories at normal/200% text (4). Correct minimum Add quantities and preserved Store search/category state were checked. Analyzer and whitespace checks passed. The recently-viewed tests invoke the existing sheet entry function, then tap its actual product row; they do not claim that every menu entry was exercised.

Earlier failed propagation attempts are retained: initial test setup remained on the product view, missed settling after scroll, toggled an already-saved fixture, and omitted the Bulk filter for the Wholesale rice fixture. A suspected duplicate seller row was investigated: the Store fixture supplies different public seller names, so its existing information was preserved; no such runtime change was retained. The final run uses actual UI taps and the correct channel/filter preconditions. Screens are in `approved-propagation-r4` under the existing local evidence directory.

An external legacy-test candidate preparation aborted on a replacement-count assertion before writing candidate files. The following empty-directory test attempt unintentionally selected the default suite; its live session was interrupted. Its log is preserved at `legacy-assertion-review/validation-r1.log` and is not qualification evidence. Repository Git status was immediately verified unchanged. Subsequent runs used explicit repository test filenames. The nine historical assertion cases and live-map provider dependency remain open as previously recorded; this propagation verification does not close them. Previous goal turn classification: progress (approved layout propagated by shared ownership and verified with new route evidence).

### Verified legacy assertion patch and bounded-goal audit

The nine historical assertion cases have a concrete test-only reconciliation patch: `legacy-assertion-candidates/legacy-layout-assertions-final.patch` in the local evidence directory and `legacy-assertion-reconciliation/legacy-layout-assertions-final.patch` inside this evidence ZIP. SHA-256 `e686e9db2b96a2449b3b4fe28bce46fe4163493b1c779964b1668ebdd5c9a62e`. It updates only the four previously listed historical test files, preserves business/recovery/Cart/MOQ/compliance assertions, verifies facts in their approved groups, and checks stale products remain unavailable in discovery and cannot bypass the decision through a direct product route. No new skips or golden replacements. `git apply --check` passed against the unchanged originals; the patch is NOT applied.

Four isolated candidate suites passed 23 tests with the one pre-existing capture-only skip (`legacy-assertion-candidates/validation-r2.log`). They used this checkout's exact `test/flutter_test_config.dart`, bundled fonts and original helper imports. The unique external group prefix and absolute imports are harness-only and are excluded from the proposed patch. `verified-patch-manifest-final.json` records original/candidate/proposed hashes and the unchanged application revision. The preliminary external run omitted the repository font loader; its findings are not application defects or acceptance evidence. Preliminary patch files used Windows-translated newlines; only the literal-LF final patch above passed applicability. All attempts are retained as evidence.

| Goal requirement | Current evidence and limits |
| --- | --- |
| Compact Compare | Implemented in shared comparison sheet; short/unavailable and populated navigation cases pass in the saved focused runs. |
| Hide Delivery in search | Root delivery control and restore control are suppressed for active catalogue search; active-order tests cover Shop/Wholesale and retain order state. |
| Compact order/invoice actions | Existing order-specific callbacks are compact actions; saved normal/200% tests verify Manage order and exact invoice identity. |
| Remove Medicine promotion | The out-of-scope Orders continuation promotion was removed; MVP promotion assertions pass. Protected Care/Medicine journeys were not redesigned. |
| Fixed Cart | Public catalogue/product/Offers/Orders use fixed Cart behavior; saved drag, scroll, landscape and large-text checks pass. |
| Organized product information | Application `0a224e54` is founder approved; 45 focused checks, 10 entry-route checks and the 23 candidate legacy checks support the new layout and preserved data/actions. Shared root/nested product owners cover public entry routes; source unchanged at `34e51875`. |
| Scoped categories/search/thumbnails | Shared draggable category design and expanding Store search cover Shop/Wholesale, regular and saved Store paths; normal/200% search, keyboard, scoped query and Back checks pass. |
| Current-location popup | Compact locate/retry/confirm UI exists and simulated-interface failure/late-result checks pass. Full requested live-location/map outcome is NOT complete: no production `BuyV2ShoppingAreaSource` implementation or injection exists in `apps/mobile/lib`; `locateShoppingArea()` fails unavailable without it. The existing contract carries region/Google Place ID/label, not map coordinates. Only the resolved-place external Google Maps link is wired. |
| Screens and safe parking | Actual local Flutter galleries and founder product approval are recorded. Approved source and all earlier history are retained locally/remotely. No APK, backend or integration was performed. |

Remaining blockers are unchanged across the product-review, propagation and this audit: (1) applying the verified four-file test patch requires those exact test owners to be admitted or the owning agent to apply it; the current recorded owners omit them and the repository explicitly prohibits unclaimed edits; (2) live location/Google map needs its real provider, permissions/Place-to-region resolution and approved map integration. The user's prohibition on policy/backend/unrelated work remains in force. No control was weakened or amended. All meaningful work available within the admitted frontend owners is parked; do not claim all eight outcomes technically complete or close the live-map dependency. The goal is ready to be marked blocked on these external prerequisites, not complete.

### Latest founder decision — defer integration dependencies and proceed with frontend

Annotation 1: founder instructed: "mark this backend or google dependencies and move on - we will again do it through google api after front end complets , google api is ready with us".

This supersedes the preceding stop/block disposition for the current frontend batch. Live current-location and map integration is a DEFERRED GOOGLE API / PROVIDER DEPENDENCY, to be resumed after frontend completion. The founder confirms the Google API is ready; no credentials or live API capability were inspected or validated in this work. Preserve `CHILD-8-MAP-PROVIDER` with its existing interface, failure/retry states, exact missing integration and future verification requirements. Do not substitute simulated location for live acceptance or close this deferred dependency as implemented.

The four-file legacy assertion patch is a separate DEFERRED TEST-MAINTENANCE / INTEGRATION HANDOFF item, not a Google/backend defect. Its exact verified patch, fingerprints and 23-pass/one-existing-skip evidence remain preserved; it is still unapplied to the repository originals. Carry it forward for the appropriate file owners before full-suite/integration qualification. It does not block further authorized frontend work under this founder decision. No policy or ownership edits are authorized or needed by this deferral.

Current bounded frontend batch: implemented, locally checked and screens presented; product layout founder-approved and verified across public entry routes. Frontend batch can be closed with these explicit carry-forward dependencies. No live-provider/full-suite/device/integration acceptance is claimed. Preserve the approved application revision `0a224e54`, all prior commits, the next-Redmi testing obligations and the latest evidence archive. Backend/API work and APK remain deferred; integration remains postponed. Continue with founder-authorized frontend scope without repeatedly stopping on these deferred items.

### Next Redmi APK — full ticket and source reconciliation

Bounded actor/outcome: Cursor preserves the complete Buy frontend for a future device-review candidate. Classification: mvp_supporting. Reuse the current worktree/branch, APK source manifest, ticket registers, existing Git checks and handoff/evidence owners. This task inventories and preserves; no feature, backend/API integration, APK build, other-worktree edit or policy change. Reconciliation does not reuse consumed r66.32 build authority or claim new release qualification.

Baseline was verified directly on Redmi `TG8HCYTGGQT885OF`: package `com.moolsocial.app.cursorreview`, version `1.0.0-r66.32-cursorreview`, code `2026092201`. Installed APK SHA-256 equals both the retained local APK and its record: `f74adcd10de5a5dfa3f6a29f024484dcb8caf294fb0682c01680eb7190f2cf8a`. APK Git label is `87bc96d4c28300146c9e2c3c3b37c7c3aacffed0`; its actual 3,233-file source manifest was also verified, SHA-256 `75d1b6f69eee462c70c1205e37011f4f4ee9b461cf006235a50d0a2398dae73d`. Comparing against this manifest prevents counting pre-APK local changes as new work merely because they were committed later.

**22 ticket outcomes since that APK:** the 11 rows in the local cutoff, the three quantity/Delivery-provenance/product-Cart controls, and the eight rows in the latest frontend batch. The exact numbered list and implementation-commit mapping are in `APK-INCLUSION-REPORT.md` and `apk-inclusion-manifest.json` under `C:/GUARANTEED OUTCOME/outputs/buy-next-redmi-reconciliation-20260922`, and under `next-redmi-reconciliation/` in the evidence ZIP. Provider-related tickets count their implemented/verified frontend portion only; live provider completion is not claimed. Later Store search/Wholesale SKU/category/header/product-polish child work is included under these parents, not silently omitted or double-counted.

Preservation results at `5f2b4428`: 16 post-APK work commits, including four runtime-source commits (`a78b1b38`, `d9ec753b`, `f4d2e116`, `0a224e54`); all parents and exact changed-owner lists retained. All 18 required integrated tips plus the previous integration, inherited/assigned checkpoints, prior Cursor tip and APK label remain ancestors. Git connectivity passed. Local branch equals origin; zero staged/unstaged/untracked records. All 3,233 candidate inputs exist, are tracked and match their Git blobs (accounting for Git text line endings); no ignored source/assets under lib/assets. No committed input or required baseline tip is missing.

Relative to the actual APK manifest: 3,215 input files unchanged; 18 changed. Nine are substantive Buy runtime files, eight are focused test files, and the generated Android plugin registrant is line-ending-only (the exact APK hash is reproduced from current bytes using CRLF). Native, Store/Counter Sale, backend, shared packages/contracts and dependency Git trees are unchanged. The evidence archive's 337 pre-reconciliation entries were integrity-checked and preserved. Pending four-file test maintenance remains archived as an unapplied patch with 23 passing candidate tests; it is not an omitted application source change.

The next APK must include the entire branch at its final clean remotely verified reconciliation HEAD and all exact input fingerprints from this manifest. Metadata-only reconciliation commits do not change the qualified application input set; recompute and verify it when the fresh candidate is prepared. Create a unique next candidate/version and run its required fresh gates before any build/install; r66.32 authorization is consumed. Replay all 22 post-APK outcomes and their children on the new APK. Current result is **Git-safe and source-reconciled, not yet a qualified/built new APK**. Google API/location/map, live Store/provider mapping and legacy-test maintenance remain explicitly deferred as instructed. No new app or device test run was necessary for this documentation/inventory task; no application source changed.

### Fresh r66.33 Redmi authorization and qualification

Founder now authorizes: "if git is safe then move ahead with redme apk". Start `3959b3c23ba09f66397b74313b8ddfb90c761442` is clean and equals live origin. Outcome: consumer reviews all 22 reconciled Buy frontend outcomes on Redmi; mvp_supporting. Reuse the complete existing branch, isolated CursorUiReview debug package and guarded build wrapper. No Store integration, backend/Google work, production promotion or new feature scope. Candidate `UAW-CURSOR-BUY-R6633-20260922`, version `1.0.0-r66.33`, code `2026092202`; prior r66.32 remains immutable and consumed.

The previously deferred four-file test patch is now required for fresh full Buy qualification. It was applied from the exact archived patch (SHA-256 `e686e9db2b96a2449b3b4fe28bce46fe4163493b1c779964b1668ebdd5c9a62e`) after `git apply --check`; its four repository suites pass 23 tests, with one existing capture-only skip. Logs: `apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/legacy.log` and `.result.json`. Formatting changes only the wrapped Wholesale test import. Application source is unchanged. The existing admission lists transfer only these four test owners to Cursor's primary claim; no rule, regression requirement or other worktree changes. This uses standing narrow authority to resolve necessary APK blockers.

Initial regression-memory invocation omitted the retained evidence archive and reported missing historical evidence; passing the existing `EvidenceArchiveRoot` parameter resolved it without file changes. The paired owner-list admission rejected the intermediate policy-only edit and passed after the exact four entries were added to its matching checker. A documentation patch guessed an absent title and made no change; the actual tail was then read before this edit. No failed invocation is counted as acceptance evidence. Two fresh complete Buy passes, source/positive gates, APK identity and installed checksum remain pending.

### r66.33 prebuild regression replay — diagnostic run 1

Retained log: `apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/buy1.log`.
Result: 2,407 passed, 27 skipped, 120 failed test cases (many repeat the same assertion at multiple viewport/text sizes). This is not a qualification pass. No APK built or installed.

- Child R6633-C01: public current-location popup intercepted Store procurement address entry. Restore the original address route for Store procurement; retain the public popup. Existing Store return tests must pass unchanged.
- R6633-T01: reconcile superseded product sections, compact Add/Cart, removed empty benefits/Medicine promotion, expandable category sheet and automatic location popup assertions. Preserve actual purchase, cart, Back, Android inset, accessible tap and provider-data checks.
- R6633-T02: custom review/photo provider fixtures must supply explicit eligibility for their named test SKUs. Do not bypass production fail-closed eligibility or use unrelated review-data shortcuts.
- R6633-C02 investigation: Recent card action and narrow-screen delivery controls must be visibly reachable; distinguish an offscreen test tap from a real inaccessible control with focused geometry/tap replay.

Only exact Buy test owners were admitted in the existing worktree registration to repair the APK qualification blocker. No broader rules changed. Backend/Google dependencies remain deferred.

Focused follow-up: C01's two existing procurement return tests pass unchanged after the one-condition route repair. C02 reproduced as offscreen test actions: Recent opens after centering its actual control; narrow navigation remains horizontally reachable; search correctly removes fleet controls. No extra runtime layout change was needed. T01/T02 were reconciled with named simulated provider identities, explicit eligibility, actual grouped information and the approved fixed Cart/current-location UI. Retained runs: `focused-r1` (513 pass, 18 fail, 1 skip), `focused-r2` (96 pass, 19 fail), `focused-r3` (14 pass, 5 fail), `focused-r4` (5 pass, no failures). Each follow-up reran the remaining failures; complete qualification is still pending two full Buy passes. Analysis exits 0 with no errors/warnings and eight existing informational brace-style notices in unchanged eligibility/session code.


### r66.33 built, installed and source-safe — final qualification disposition

This section supersedes earlier pending-build/full-test/test-maintenance descriptions above; historical entries remain preserved. Founder authorized the new Redmi APK after Git reconciliation. All 22 post-r66.32 outcomes, including explicit Quick/Scheduled/Wholesale/Bulk frontend eligibility, are included. Google/API/backend/Store-provider dependencies remain deferred; no integration or backend development performed.

- Frozen build source: `1650a1ddb3bf3672530c8d345d0a5c3e9f475aba`; exact qualified review source pin `02369e96a293e4588cca06efad17a02bf53470a8`. All 18 required integrated tips retained. Source was clean, pushed and live-origin verified before build; local recovery bundle retained.
- Manifest: 3,236 inputs, SHA-256 `AFCDD9532CEB895C144414C0ED7066F78813A825A27E2616CC6BB5B357ADA799`; every input matched again after both complete test passes, build and device replay. No new runtime edits after freeze.
- Two full Buy runs: **2,527 passed, 27 skipped, zero failures EACH** (`buy2`, `buy3`). Analyzer: zero errors/warnings and eight existing informational notices. Formatting unchanged. Required source/brand/native/negative-control/prebuild checks passed; APK native plugin integrity passed. Earlier failed diagnostics retained, not counted as passes.
- Installed isolated review candidate `UAW-CURSOR-BUY-R6633-20260922`, `1.0.0-r66.33-cursorreview`, code `2026092202`, package `com.moolsocial.app.cursorreview`, Redmi `TG8HCYTGGQT885OF`. The one-build authorization is consumed. Production/backend acceptance is not claimed.
- APK SHA-256 **968933D16519BBE6AC757C10ACA39368F87A7605CFAB0CF1F6C4E28DD73E1FC7** exactly matches on-device `base.apk` and separately pulled installed bytes. Same verified signer as predecessor. `adb install -r`; no uninstall or data clear. Binary: `apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/uaw-cursor-buy-r6633-20260922-device-review-debug.apk` (215,594,961 bytes).
- Six packs in three Wholesale lines and one Saved product retained. Work/Basni address and Delivery restored after replay; Redmi left on Shop. No order, payment, chat or message submitted. Displayed total rose from INR14,692 to INR14,992; investigation O01 below remains open.

Focused Redmi replay captured 48 actual screenshots including preinstall/startup evidence. Confirmed grouped Shop/Wholesale/nested product information, compact primary Add/Cart quantities, main-rail Cart stability, Store and Wholesale Store expanding search, scoped search/price filter, full-height draggable categories and thumbnails, Store details without pickup banner, Android-visible Store filter controls, honest unavailable checkout/comparison/location states and pickup sign-in Back retention. Screenshots do not substitute for live provider qualification or all device-case closure. Recipient edit/keyboard and the specific Offers Manage order/View invoice context were not repeated on device in this bounded replay; their host checks passed, device obligations remain explicit. Full per-ticket dispositions are in `device-replay.json` and `DEVICE-REPORT.md` in the candidate directory and evidence ZIP.

**Open device findings — registered, not implemented in this frozen APK:**

| Finding | Parent / evidence | Required follow-up |
|---|---|---|
| R6633-D01 | RB026; `redmi/027-orders-lower.png` | Historical mixed-product MS-NEW-03 is Preparing but combined estimate retains “Delivered in 30 min”. Normalize each component; preserve real completed history. |
| R6633-D02 | Cart across surfaces; `redmi/043-product-actions.png` | Product opened through Recently viewed omits aggregate Cart access when six Wholesale packs exist. Root Shop product retains it. Check nested route scope/fixed control. |
| R6633-D03 — founder reopened | RB013 / Recently viewed compactness; `redmi/042-recently-viewed.png` | Narrower Add still sits on its own row, leaving wasted space. Large thumbnail/card and separate Clear row keep popup sparse. Full compact premium requirement is incomplete. |
| R6633-O01 — investigation | Retained-data update; preinstall screenshot and `018`, `019`, `024` | Same six packs but displayed total increases INR300. Determine selected coupon persistence/revalidation; no price-change or data-loss cause claimed yet. |

**Founder correction on Recently viewed:** the partial change is present in Git and in the verified APK; no commit was omitted. `_RecentlyViewedProductInfoRow` still ends its metadata Column with a right-aligned Add on a separate row. The earlier assessment accepted button width too narrowly and overstated completion. Reopen the original requirement as R6633-D03: compact header/Clear and product card, thumbnail/metadata/action grouped without an empty full-width Add lane, readable long text and accessible tap targets, Android/keyboard-safe sheet, same SKU/navigation wiring. Validate actual Redmi/Flutter geometry and founder screen approval; button width alone is not acceptance. Initial replay report retained and explicitly superseded by corrected report.

Google location/map API, authentic Store/public catalogue/photos, live identity/provider mapping, delivery fleet/booked slots and payment execution remain deferred. All source is included; **not all 22 tickets are device-closed**. Three confirmed children plus one investigation remain open. No new APK rebuild for these findings is implied by this evidence-only parking.

Evidence ZIP SHA-256: `7bb5e85be9152971818f3b495c278386ae438cea59801ba2aae35d7f98d7f8ab` (68,279,648 bytes). All 342 prior entries verified unchanged; 222 candidate evidence files plus 24 helper files appended under `r6633-qualification/`. APK binaries remain locally retained; reproducible source, receipts, logs and screenshots are Git-backed. Final metadata commit changes only this handoff, inventory and evidence archive.


### R6633-D04 — founder white strip behind Cart, register only

Founder explicitly requests inspection and registration only; **do not implement**. OPEN, launch-supporting public Buy visual defect.

Current Redmi screenshot `051-founder-cart-strip.png` confirms the full-width empty white strip behind the right-aligned Cart pill in Store search. Catalogue and nested Store product reproduce it (052/053). Retained same-APK Wholesale Store screenshot032 confirms that variant; current Wholesale basket is empty, so no new scoped Cart was fabricated. Root Shop/Wholesale/product/Orders/Offers/Saved Cart placements were inspected (055–062): their normal navigation rail has no separate Store-style blank strip. Preserve that distinction.

The three shared Store Cart placements are in buy_v2_catalogue.dart (Store sheet/full catalogue) and buy_v2_screen.dart (nested product). Register all shared callers and their Saved/Recent/related routes for future regression; no claim that every route variant was separately tapped. Expected correction: eliminate only redundant opaque Cart-only whitespace, preserve fixed compact Cart, product visibility/scrolling, theme continuity, accessible targets and Android/keyboard safe areas. No backend dependency. No source/test/APK change made.

Full ticket and 14 fresh PNG/XML/receipt sets are archived under `r6633-cart-strip-D04/` in the existing evidence ZIP. Latest ZIP SHA-256 `c47201d6b956cf86a94112bf867a4ad1193dfd8b3356361de4729008544bc0d7`; all 588 earlier entries integrity-checked and preserved. Five Shop items / INR694 and one Saved item unchanged; device returned to public Shop Visit Store. R6633-D04 remains open alongside D01/D02/D03 and observation O01.


### R6633-D05 — Compare prices remains functionally incomplete (23 September)

Founder-current Redmi capture065: A4 ruled notebooks / Carton of120, unavailable supplier prices. Tapping Refresh yields the same state in066. **OPEN functional provider-wiring gap; registration only, no fix now.** The prior Compare ticket fixed sheet sizing, while its acceptance item4 explicitly deferred supplier data. Layout inclusion is not a missing Git commit, and local fixture success is not functional device acceptance.

Read-only source trace: `_reload` in buy_v2_views.dart (~1964) returns unavailable before loading when nullable `session.comparisonSource` or query is absent. The full apps/mobile/lib tree has a BuyV2ComparisonSource interface and controller/session references, but no implementation or constructor injection. Therefore Refresh cannot fetch comparison offers in this app configuration; restoring internet cannot supply the missing adapter. Earlier completion wording must distinguish the implemented sheet layout from this unimplemented end-to-end outcome.

Future acceptance: wire the existing contract to coordinated, versioned Store-origin identities/offers; same SKU/variant/pack, correct prices/stock/eligibility, pagination and stale/location rejection, genuine recovery and exact product/Cart return. Distinguish missing configuration from transient network errors so retry is truthful. Preserve compact layout and Android safety. Backend/Store provider work remains deferred; no invented live prices, new screen, policy or other-worktree work. Device left on the comparison sheet; no basket or transaction changes.

Full ticket and before/after Refresh screenshots are preserved under `r6633-compare-D05/` in the evidence ZIP. Latest SHA-256 `887b6cba1d44bee296afdd80b0df9ef1054bcc2b6e26a31161f36b5eafaf165b`; all 631 previous entries preserved. No source/test/APK changes.


### R6633-D06 — Offers and Cart journey, registration only (23 September)

Founder requested inspection and full visual/technical ticket definition, explicitly no implementation. **OPEN: one parent with seven work packages**: A publisher-tab visibility/loading; B authentic MoolSocial admin/Store offer-data dependency; C compact publisher filter; D inline Saved parity and correct scope; E approved price-row Add across SKU entry routes; F compact Cart browsing actions; G premium compact Cart through final review, including keyboard/insets and state correctness. Future actual local Flutter screens remain required for founder approval after authorized implementation.

Redmi captures067–081 and timed070/071 reproduce Suppliers text becoming invisible during switching, no MoolSocial review offers, oversized filter/Saved sheets, Wholesale SKU bottom Add dock and competing full-width Cart browsing controls. Read-only source inspection confirms review offer generation never emits the moolSocial publisher type; no backend/admin data was injected. Future data must come from exact Store/admin identities and the existing BuyV2PublishedCatalogueOffer mapping, with simulated transport labelled and no claim of live eligibility.

Two linked child defects: **R6633-D06-D-C1**, Offers Saved uses the last Shop destination and omits the saved Wholesale item shown in Offers; **R6633-D06-G-C1**, Shop payment chooser shows a stale Purchase order reference despite that method being unavailable. Both remain OPEN. Final payment/order/provider success was not tested or claimed. Address recipient keyboard was inspected, but lower-field reachability still needs its explicit future checks.

Cart restored unchanged: four products / six Shop items / ₹760. No quantity/Saved/payment selection, address save, transaction, app/test/config/policy changes, new APK or other-worktree work. Existing D03/D04/D05 remain separate linked issues. Detailed acceptance covers query freshness/pagination, accessible compact layout, product MOQ/stock/verification, exact Cart totals/routes, keyboard/Android safety, and honest provider-deferred states.

Full ticket: `r6633-offers-cart-D06/OFFERS-CART-JOURNEY-D06.md` inside the evidence ZIP. Archive SHA-256 `254abfb88c033055f1159abea9ed9a30adf7da4304c2eb7598f2f7721cf44c0e`, 79,403,754 bytes; all 638 prior entries preserved, 50 new entries. Registration complete; all seven work packages and two children remain open.


### R6633-D07–D10 — Authenticated checkout and customer delivery audit (23 September)

**Delivery wording/choice correction:** the founder subsequently rejected the service/time chooser described below. The platform-assigned delivery correction at the end of this handoff is authoritative for D08/D09/D10 and D06-G; original observations remain historical evidence.

**Four new OPEN tickets, registration only:** D07 remove redundant checkout sign-in by connecting the authoritative app identity; D08 consumer delivery wording and explicit service/slot eligibility; D09 delivery selection, stable fulfilment grouping and complete compact review; D10 live order/delivery updates for consumer, Wholesale, retailer procurement and bulk buyers. **D06-G extended** to require compact premium polish from Cart through address/collection, payment, review and tracking; this is not an extra duplicate ticket.

Current Redmi082 confirms the collection sign-in notice/button. The review harness deliberately starts Buy without normal account entry, and no collectionIdentity injection was found in runtime lib; reaching that review Cart is not authentication evidence. Future fix must reuse real app identity, remove normal-session duplicate login, distinguish provider unavailability from expiry, and preserve authorization/account isolation. No auth bypass.

Proposed consumer copy: **Express delivery** for eligible retail biker service; **Choose a delivery time** for scheduled Wholesale/Bulk; **Standard delivery** for eligible retail/Wholesale parcels; retain **Collect at store**. Show verified ETA/date/slot/fee, not operational fleet language or invented capacities. Existing explicit eligibility checks stay intact. Source child D08-C1: scheduled is an eligibility option but the three-mode display/group model cannot represent its selected slot distinctly. Source child D09-C1: current grouping keys use seller display text and promise strings rather than stable Store/fulfilment/quote IDs; no cross-Store collision was reproduced.

Device095–098 reaches delivery review with six items/₹760; delivery remains correctly blocked as unconfirmed. Three same-Store products occupy separate shipment cards with different estimates, requiring compact provider-correct grouping, not blindly merged deliveries. Existing Retail088/089 and Wholesale/retailer091 tracking show last-known state and unavailable live updates. Existing tracking polls an optional adapter; no runtime liveDeliveryAdapter injection was found. Provider/Google/order lifecycle integration remains explicitly pending. Bulk checkout and retailer-owned procurement end-to-end were source-audited/spec'd, not device-passed.

All actors have a documented acceptance matrix, including live/stale/offline/reconnect/slot/quantity/address/payment and multi-delivery recovery. Actual local Flutter screens are required after later implementation for founder approval. No application/test/policy changes, data injection, APK, payment/order submission or provider workspace edits. Basket preserved and original five-item collection/payment choice restored in102; Pine Labs was preselected before inspection.

Full report and fresh device evidence: `r6633-checkout-delivery-D07-D10/CART-CHECKOUT-DELIVERY-AUDIT-D07-D10.md` inside the evidence ZIP. SHA-256 `cd260c05d34acee1440d35801ff4f8b10a46ebf7fcb38fe1124c0d4d077bf178`; 84,177,530 bytes; all 688 existing entries preserved plus 61 new entries. All four tickets and two source children remain OPEN.


### Founder correction — platform-assigned MoolSocial delivery (23 September)

**Annotation1: customers do not choose a delivery service or time slot.** Supplier/Store and logistics partners follow MoolSocial's delivery algorithm; it assigns the service, timing and subsequent updates. This supersedes the earlier Express / Choose a delivery time / Standard proposal, D09's suggested customer chooser, and the slot-picker preview requirement. Absence of that chooser is not a defect.

Professional platform labels proposed for the registered design: **MoolSocial Quick Delivery** for eligible small biker orders; **MoolSocial Scheduled Delivery** for Wholesale/bulk; **MoolSocial Courier Delivery** for remote parcels, which are also scheduled. Courier service and assigned timing must coexist. No invented thresholds, promised minutes or local assignment algorithm.

Product descriptions show the existing intended Store/supplier-backed delivery type and estimate. Cart/checkout show the platform-assigned service, timing and charges compactly, without delivery-service/time selectors. After placement, all buyers see the actual live/scheduled/courier progress, assigned date/window and freshness updates from the order/Store/logistics source. D08-C1 now concerns assigned schedule separate from transport, including courier; D09-C1 stable shipment identity remains open. D06-G full compact premium polish and D07 auth work remain required. Existing Store collection scope is preserved; no new pickup rule is inferred.

Updated D08/D09/D10 requirements and future preview/test matrix; no additional ticket count. No implementation, provider/algorithm work, APK, device interaction or tests in this documentation correction.

Operative report: `r6633-platform-delivery-correction/PLATFORM-ASSIGNED-DELIVERY-CORRECTION-20260923.md` in the evidence ZIP. Latest SHA-256 `e10bce97ca96eec54ae7baf8db70529f566c282be3cc9a59257c57d96e28ce3a`; 749 prior entries preserved plus one correction. Earlier audit reports are retained for observations but their rejected chooser/copy requirements are superseded.


### R6633-D11–D16 — Add-to-order real-user Redmi replay (23 September)

**Six NEW OPEN defects, registration only:** D11 missing online payment handoff after final review; D12 misleading locked method controls/cancelled-state recovery (child C1 blocks Shop Add from an unavailable Wholesale attempt); D13 dispatch promise labelled Arrives; D14 Add/Edit basket opens deep recommendations rather than affected items; D15 required PO reference below viewport without focus on validation; D16 inconsistent public Store/product names after order. Existing D07 collection identity/service block, D09 unconfirmed delivery, D10 missing live updates, D06-G-C1 orphan PO field and compact Cart/white-band tickets have fresh linked evidence, not duplicate closures.

**30 route/state checks across Shop, Wholesale, Bulk, Offers and Visit Store:** online method selection can reach review, then Place order returns to unavailable handoff. Collection PhonePe/Paytm/Pine Labs leave Review disabled. Cancel alone leaves a contradictory complete-payment instruction; Choose again restores idle. Empty PO correctly blocks, but its field is not brought into view. Bulk MOQ validation, category recovery, offer refresh, invalid carried payment method gating, below-minimum benefit protection, exact totals and removal of test items passed their stated checks. Bulk and some Store products correctly block on unavailable delivery timing; those provider outcomes remain open.

One existing-review-adapter COD order was created for the test-added Shop tomato: **BUY-NEW-05 / MS-NEW-10 / ₹37**, local simulation only. Actual confirmation, invoice preview, Android save-picker cancellation and tracking were inspected. No real order/payment/delivery or saved PDF success claimed. Current invoice/tracking exposes Mool Market000001 and invoice Fresh tomatoes1 where preceding public screens showed Mool Market1/Fresh tomatoes. No arbitrary number stripping or alteration of legal invoice identity is authorized by registration.

Original founder basket preserved: **Fresh red onions, Wholesale25kg sacks,2packs,₹1550**. Other test additions explicitly removed, temporary PO reference cleared, temporary benefit removed, Paytm restored.183 leaves payment idle/Review available after cancelling the initial failed attempt. Local test order retained and disclosed. No address/Saved edits, app/test/config/policy change, APK, provider injection or external payment/message. Two private Android picker-context captures132/133 remain local-only; app proof, manifest and other captures are archived unchanged. Full live/authenticated retailer/procurement/delivery combinations remain dependency-pending and are not claimed tested.

Full report `r6633-add-checkout-replay-D11-D16/ADD-CART-CHECKOUT-REPLAY-D11-D16.md` and capture manifest `r6633-add-checkout-replay-D11-D16/ADD-CART-CHECKOUT-REPLAY-MANIFEST.json` in evidence ZIP. SHA-256 `b70a51f7a7a06593d7e36e40074976dc12f7a3777f47c53ae306d59517093563`, 101,158,738 bytes; all 750 previous entries preserved plus 238 entries. No implementation; six findings plus D12-C1 and existing linked defects remain OPEN.


### Frontend Add-to-Cart through completion — nine visual/workflow children (23 September)

Founder clarification: missing providers must not stop frontend visual/workflow registration or local frontend qualification. **R6633-D06-G-V01–V09 are OPEN**, refining the existing Cart-polish parent rather than duplicating D06-E/F, D12–D16. Scope: product/Add parity; compact Cart and bill; address/collection forms; payment/reference/recovery; final review; confirmation; tracking/invoice actions; brand/typography; keyboard/Android/edit continuity. Each child has evidence, expected layout/behavior and acceptance criteria. Applies across Shop, Wholesale, Bulk, Offers and Visit Store.

Required sequence: product/quantity → Cart → address or collection → payment → review → placement result → tracking/invoice/support. Platform assigns delivery service/timing; no customer slot/service picker. Keep approved collection choice. Existing state/contracts and screens must be reused; no new backend or invented provider success. Nine visual/workflow children are registered, not implemented or passed. Existing 30 route/state checks and screenshots reused; six frames visually re-inspected, no new device run or order. Lower-field keyboard, enlarged-text and unexecuted lifecycle variants remain explicit acceptance checks rather than invented passed results.

Full actionable MD: `r6633-frontend-journey-visual/FRONTEND-CART-JOURNEY-VISUAL-TICKETS-20260923.md` inside evidence ZIP (local review artifact `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921/apps/mobile/build/review-candidates/cursor-buy-r6633-20260922/FRONTEND-CART-JOURNEY-VISUAL-TICKETS-20260923.md`). Archive SHA-256 `9dbc8698a4520de9a409c48860e65943a9a07d8f9336e3e721d16e9030c32419`, 101,164,838 bytes; all 988 earlier entries preserved. Source untouched. Provider/live acceptance is separate and deferred; visual tickets remain actionable.


### Founder correction — only MoolSocial-issued Purchase Orders (23 September)

**Binding requirement for D15 and D06-G-V04:** a Purchase Order must be issued by MoolSocial before its reference can be accepted. Arbitrary buyer-entered text, a supplier PO or a non-empty field is not proof of a valid MoolSocial PO. This supersedes any earlier wording that suggested a procurement-approved reference alone was sufficient.

Frontend ticket: label the field “MoolSocial purchase order reference”; explain concisely that it must refer to a MoolSocial-issued PO. Distinguish empty, checking, verified, not found/not MoolSocial-issued, unusable and verification unavailable states. Changing the reference or relevant purchase context invalidates the previous verification. Do not imply acceptance or allow submission on an unverified reference. Preserve entered text for correction and expose inline errors above the keyboard. Keep the compact payment layout and field-reveal requirements.

Backend dependency: authoritative MoolSocial PO issuance/lookup and validation against the authenticated buyer and applicable order. Exact validity, status and purchase constraints must come from the coordinated contract, not locally invented rules or a reference-prefix check. Local frontend fixtures may demonstrate these states but cannot issue a real PO or establish production validity. Include tests for arbitrary/non-empty text, unknown/foreign reference, valid issued reference, changed reference/context and unavailable verification. Existing AUDIT-R6633-LOCAL was a review-only form-validation probe, NOT an issued/accepted MoolSocial PO; it must not be cited as business PO acceptance.

Status: registered only; no code, provider or APK change. This is a refinement of the existing payment/PO ticket, not a duplicate parent ticket.

### Wholesale/Bulk PO journey inspection and implementation authorization

Founder now authorizes the missing Wholesale/Bulk PO frontend journey, reusing the existing workflow and adding only what is necessary. This supersedes registration-only for this specific PO ticket; all other newly registered visual tickets remain registration-only.

Read-only findings: BuyV2Session.purchaseOrderEligibleForCheckout checks verified business and Wholesale-destination lines; purchaseOrderDetailsComplete checks only trimmed reference length >=3. Both continueCheckoutFromPayment and submitOrder use that insufficient check. The shared payment view exposes a free-text reference, not a MoolSocial issuance/verification journey. Bulk replay153/154 previously traversed this same field into review; that proves form navigation only. Existing retailer placeWholesaleOrders/ReviewRetailerWholesaleGateway generate fixed review PO IDs and supplier records, not an authoritative issuer suitable for reuse as production validation.

Reuse decision: retain Buy's existing Cart, quantity/MOQ, address, payment, review and order details owners; do not route public checkout into the legacy retailer review workflow or copy its fixed IDs. Issuance/lookup can join the existing checkout through a narrowly scoped provider contract. Backend implementation remains deferred.

Required product clarification presented to founder: should MoolSocial issue the PO from this reviewed basket, or must the buyer bring a MoolSocial PO issued beforehand? This is a workflow decision, not an additional permission request. It determines whether the frontend needs a generate/request outcome or a reference verification action; no operational issuance rule is inferred while the answer is pending. No runtime changes yet. Future focused checks must cover Wholesale and Bulk, arbitrary references, issued reference/context binding, unavailable verification, edit/back continuity and keyboard visibility.

### R6633-D17 — MoolSocial-generated buyer PO and connected Wholesale/Bulk journey

**OPEN; founder decision resolved.** MoolSocial generates the PO from the reviewed basket on the buyer's behalf. Identify the actual buyer and supplier; MoolSocial is the generating platform, not automatically the buyer. PO is an order document, NOT a payment method. This supersedes the earlier existing-reference-input proposal and the pending clarification above. Link D15/D06-G-V04; do not implement a parallel free-text PO authorization workflow.

Required sequence: products/variants/quantities → Cart → receiving address or collection → review commercial terms and buyer/supplier details → explicit buyer confirmation → platform-generated PO/reference → supplier acceptance or clearly stated exception → separate payment under agreed terms → packing/dispatch → assigned delivery or collection → completion → invoice/support. Avoid extra screens: reuse existing Cart, checkout/review, order details, document access and order conversation. For a multi-supplier basket, bind each supplier-facing PO to its exact lines; final grouping/issuance and payment timing are authoritative contract data, not frontend guesses. Changes/rejections require explicit revised terms and buyer confirmation where applicable, never silent changes in chat.

Order-linked chat is required between buyer and supplier, and logistics where relevant and authorized. PO/order identity and concise context must remain accessible in the conversation; messages alone do not change price, quantity, payment, acceptance or delivery state. Distinguish supplier chat from MoolSocial support. Reuse the existing order-conversation route demonstrated in195/199/200; do not build another chat system. Show pending/failed/retry states truthfully, preserve drafts and prevent duplicate PO/order submissions.

Classification: mvp_required connected commerce frontend. Existing Buy session/views and shared order-chat owner are the reuse boundary; shared Store acceptance, PO issuance and party permissions need coordinated contracts, with no edits to another worktree. Backend remains deferred, but frontend layouts and all state transitions must be locally qualified with explicitly labelled fixtures. Register rather than implement in the current audit. No PO issued or message sent.

Acceptance: Wholesale and Bulk, single/multiple supplier, MOQ/variant totals, buyer identity, address edits, terms changes, issuance pending/failure/retry, acceptance/rejection, payment independent of PO, order-linked chat/back/draft retention, delivery/collection, completion and invoice/support. Apply the V01–V09 compactness, brand, text grouping, Android and keyboard criteria at every stage. Actual local screens and focused regression are required after implementation; no live-provider claim from fixtures.

### Frontend audit continuation — order management and communication (23 September)

Latest founder clarification again confirms visual/workflow tickets only. Existing nine D06-G visual children cover product/Add, Cart, address/collection, payment, review, confirmation, tracking/invoice, brand and keyboard. New actual Redmi captures184–200 inspect remaining Orders → Wholesale tracking → Manage order → cancellation reason → contact → order-linked chat → keyboard → expanded order context → Back. Earlier30 route/state checks are not recounted as new. All observations below are OPEN; no source changes.

**R6633-D06-G-V07-C1 — Tracking and history repetition.** 185–191 repeat status text in history cards and tracking, then repeat balance/date in both delivery details and Upcoming balance. Expected one current-state/timing summary, one aligned payment table (paid/due/when), compact conditional payment action, concise timeline and secondary order actions. Keep meaningful operational differences; remove repeated meaning and oversized panels, not necessary facts. This refines V07 rather than duplicating the parent.

**R6633-D06-G-V07-C2 — Manage-order form density.** 192/193 show large action selection, repeated headings, tall reason field and full-width support action for one cancellation option. Expected compact action/reason grouping with concise order context, one primary submission action and quiet secondary contact.194 is a dropdown, NOT a keyboard screenshot despite its filename; all four choices were visible above Android navigation. Empty reason correctly leaves submission disabled. Do not claim a clipping failure here. Register long-text/text-scale and correction/back cases for local qualification. No cancellation submitted or reason persisted.

**R6633-D17-C1 — Contact-support label opens supplier chat.** From Wholesale PO-240783: Manage order → Contact support instead opens Marwar Foods Distribution conversation (193→195). Expected action label and destination agree: Contact supplier for supplier chat, separately scoped MoolSocial support where required. Do not silently route platform escalation to the seller. Preserve order ID, party scope and return location. Reuse existing callback; coordinated Chat change only where necessary.

**R6633-D17-C2 — Order-chat compactness and duplicate draft.** 195/196/199: tall conversation header/card plus oversized empty-state text; long generated draft duplicates amount, delivery and payment details already in expandable order context. Header truncates partner/order detail. Expected compact persistent party/order identification, restrained empty state, concise editable help draft and accessible expandable facts; prevent required identity from becoming ambiguous. Keep brand typography/neutral surfaces and restrained accents, not additional solid-colour blocks. Composer and Send were physically above the keyboard in196;197 dismissed keyboard;198 cleared only this newly generated audit draft;199 expanded correct order context;200 Back returned to original tracking position. No messages sent. Do not label keyboard concealment as reproduced here.

**R6633-D06-G-V07-C3 — Completion/receipt/return frontend coverage.** Registration/acceptance gap, NOT a claimed reproduced delivered-state visual defect. The installed Orders list reached its recommendation section in189 with only preparing/supplier-confirmed records; no delivered record was available. Do not wait for live backend to design/qualify frontend states: use the existing order model and labelled local fixtures in the future implementation/test batch to expose delivered/collected summary, received items, partial/problem receipt where supported, balance/invoice, help/return/refund eligibility and unavailable states. Show actual recorded completion time, concise outcome and next relevant actions; hide obsolete active-delivery/promotional clutter. Group products, payment and service facts consistently. Inspect every conditional form for long text, validation, keyboard, Android safe areas, edit/cancel/back. Missing contract states become explicit integration requirements, not invented customer promises. No false claim that a full live Add-to-delivered run was completed.

Current audit outcome: frontend tickets specify the complete purchase lifecycle; actual device evidence covers available states, with completion-only states explicitly unrendered and awaiting local fixture coverage. All defects remain open. Backend absence is not a reason to postpone frontend polish. Original basket remains untouched; no payment, new order, cancellation, message, source change or APK in this continuation. Redmi left on Wholesale tracking after correct chat return.

### Active implementation checkpoint — post-r66.33 bounded replay

No ticket is closed by this checkpoint. Source is local and qualification is in progress; r66.33 remains installed. The final stopping point is the fresh APK replay and a disposition for every parent/child, with unresolved or new findings registered and no further fix cycle after that replay.

Implemented locally for qualification: D01 combined active-estimate copy; D02 aggregate Cart on nested product routes; D03 compact Recent header, thumbnails and inline Add with accessible large-text fallback; D04 transparent overlay Cart on Store/product surfaces with final-content clearance; D06-A publisher switch transition, C compact filter chips, D inline Saved across offer destinations, E Wholesale price/Add parity, F quiet Cart browsing controls; D07 remove redundant collection sign-in entry without bypassing account validation; D08 platform delivery labels; D09 grouping by Store identity when available; D12 truthful disabled unresolved-payment methods and terminal retry recovery; D13 dispatch/arrival-neutral Timing label; D14 new-Add/Edit basket entry reveals items while normal Cart-return offset stays retained; D15/D06-G-C1 retire PO-as-payment and stale reference field; D16 consistent public names in confirmation/tracking/invoice and PDF; D17-C1 supplier contact label and C2 concise editable help draft retaining structured order facts. V04/V05/V06/V07 shared changes include compact payment rows, progress header, success mark, separated payment facts and one balance owner.

Explicit dependencies remain open: D05 authoritative comparison data; D06-B authoritative administrator/Store offers; D07 actual account/provider binding; D08-C1 authoritative service assignment and scheduling independent of transport; D10/D10-C2 live logistics/Google Maps; D11 real payment handoff; D17 authoritative PO issuance, supplier acceptance and lifecycle integration. Removing PO from payment does not implement or qualify its whole lifecycle. Shared Chat header/empty-state density still needs its exact disposition; concise draft alone does not close D17-C2. Completion/receipt states require explicit test evidence. No production success may be inferred from labelled review fixtures.

Qualification evidence retained under `C:/GUARANTEED OUTCOME/outputs/buy-r6633-qualification/`: `successor-chat-continuity-02.log` (89 pass, three obsolete-expectation failures, corrected locally); `successor-product-offers-01.log` (39 pass, test import failure and obsolete Saved popup expectation, corrected); `successor-trade-payment-02.log` (24 pass, one existing capture-only skip). Recent Android last-Add and all Recent text-scale cases pass. Full Buy regression is now running; these are not final candidate results.

Exact ownership registration only: transferred Buy invoice view/downloader and state-invariant test from historical Cursor audit claim to current primary; admitted Offers visual and payment-sheet tests. No rule/registry requirement changed. `successor-admission-02.log` passes with78 current owners. All changes remain confined to this worktree. Fresh candidate planned as r66.34; no build authorization is consumed until source and required gates qualify.

### R6633-D10-C2 — Customer live Google Maps delivery tracking; required before go-live

### Active bounded successor execution — founder authorized

Starting source checkpoint 0b11940a3c57176ea96e0bc5fd071279bf115f91; installed predecessor remains r66.33. Founder authorizes implementation, local tests, a fresh Redmi APK and one final affected-journey device replay. Close only verified outcomes; if final replay finds unresolved/new child defects, register them and stop without a further implementation cycle. This is not authorization to close deferred provider work using review simulations.

Scope: D01–D17 and registered children, reusing Buy catalogue/session/product/Cart/checkout/tracking and order-chat entry owners. Frontend logic and visuals are required; live Google Maps, real payment handoff, authoritative identity/catalogue/PO issuance and delivery services explicitly deferred by the founder remain tracked integration dependencies. Preserve Store/CSV/Counter Sale and all current working data. Shared changes require exact contract handoff. No other worktree edits.

Plan: shared presentation and navigation defects → payment recovery and PO/order semantics → focused cross-route tests and actual Flutter screens → fresh version/source reconciliation and required build checks → checksum-verified Redmi install → final device defect/closure report. Test meaningful state, quantities, amounts, source scope, keyboard/insets, long text, stale results and recovery using existing tests first. Do not treat screenshots as technical acceptance or fixture orders as live commerce. All ticket status remains open until its evidence is recorded.

Local D03 correction evidence: first focused run40 pass/1skip/2fail. Isolated four Android-last-Add checks proved both normal-scale cases pass and both200% text cases miss the Add tap because the tall compact row puts its centred action behind the sheet header when scrolled to the end. Exact log retained at outputs/buy-r6633-qualification/successor-recent-isolation.log in the workspace. Correct large-text arrangement without weakening hit testing or Android insets; retain compact side-by-side action at normal text size. This is an implementation-stage correction, not final Redmi acceptance or a reason to stop the authorized local-fix cycle.

Founder explicitly requires customer-visible live delivery on Google Maps. Extend existing D10 live-delivery ticket; do not count this as another duplicate parent. **OPEN, mvp_required, scheduled for later provider/backend integration phase, mandatory before go-live.** The current installed review build does not demonstrate verified live Google Maps delivery tracking. Current frontend visual audit can proceed independently.

Outcome: from the relevant order/tracking screen, the authorized customer sees the assigned delivery partner's current position on Google Maps during active delivery, destination, provider-backed ETA/status and update freshness. Apply across Shop/Visit Store/Offers and Wholesale/Bulk deliveries using the shared tracking owner. Scheduled orders show the assigned schedule before dispatch and transition to active tracking when authoritative location becomes available. Courier must expose truthful carrier status and supported tracking; absence of carrier coordinates cannot be disguised as a moving live map. Any unavailable courier live-map capability remains an explicit pre-launch scope/acceptance decision, not an assumed pass. Collect-at-store retains Store directions and pickup progress, not an invented moving driver.

Dependencies: delivery workspace location publication and assignment; authenticated order/party authorization; backend delivery events and subscription; Google Maps integration and configuration; authoritative timing and completion. Reuse BuyV2LiveDeliveryAdapter, BuyV2Session and existing tracking UI in buy_v2_views.dart, plus shared delivery contracts. Do not build separate Biker/Bulk tracking systems or expose another customer's order, unrelated driver location or location after access ends.

Frontend acceptance: compact expandable map with clear status/ETA and restrained brand styling; no oversized empty map while awaiting assignment; accessible controls, Android safe areas, correct Back/resume and order-linked contact. Live/stale/offline/permission-denied states clearly distinguished; last update shown, no synthetic movement/countdown. Test assignment/reassignment, schedule-to-dispatch, moving updates, reconnect/out-of-order events, app background/resume, delivered/cancelled end state and access revocation. Verify with actual provider-fed Redmi journey before launch; fixtures only qualify frontend states. No implementation, credentials, provider setup or APK authorized by this registration.

Order-chat D17-C2 exact frontend scope: reuse chat_thread_screen.dart and chat_widgets.dart for a compact order-only header and empty state, preserving all non-order Chat layouts and existing contextual identity, message, call and composer handlers. Exact owners moved into the current Cursor claim; no contract, provider or other-worktree edits. Validate Buy order-chat return/draft/context and keyboard cases; no real messages sent.

### r66.34 local qualification continuation

The initial complete diagnostic Buy run retained 2,451 passes, 27 skips and 84 failures. Failures are not hidden: obsolete UI expectations were updated to the current inline controls and Timing/Checkout wording, while actual payment feedback, UPI submission and dropdown clipping regressions were corrected. The new check rejects retired PO-as-payment without rejecting a provider-supplied UPI method. Cancelled/failed payment feedback remains visible while selecting another method; pending/unknown attempts stay locked.

Confirmed evidence in outputs/buy-r6633-qualification: successor-corrections-03.log (306 passes, one existing skip); successor-session-05.log (440 passes); successor-screen-corrections-07.log (10 passes); successor-store-corrections-04.log (12 passes); successor-captures-03.log (10 new candidate captures, previous reference images preserved); successor-order-chat-visual-01.log (two actual renders at 100/200%); successor-completion-visual-01.log (two collected-order/receipt journeys at 320px, 100/200%). These labelled fixtures prove frontend states, not live delivery or real payment.

Inspected actual Cart, checkout at enlarged text, order-chat expanded facts and collected receipt images. Collected receipt groups status/payment, purchased items and receipt identity with Order help and no active-delivery control. Buy order-chat header/empty state is compact; full supplier identity wraps and structured facts remain expandable. Non-Buy/Care conversations preserve their existing header behavior. Shared Chat regression and remaining continuity/full Buy qualification are running. No Redmi defect closure or new APK is claimed yet.

Exact admission now passes with 94 owners (successor-admission-03.log), including two shared Chat presentation files and ten new candidate images. Historical tracked failure images generated by the diagnostic were preserved under outputs/buy-r6633-qualification/successor-full-01-failure-artifacts before restoring their original tracked bytes. No old evidence was discarded. Full app commit history remains unchanged pending the authorized source commit.

Final r66.34 evidence will be retained in a separate `docs/quality/CURSOR-BUY-R6634-EVIDENCE-20260923.zip`: the existing evidence ZIP is already near the remote file-size limit and remains unchanged. Exact archive ownership added only; no broader rule changes. Runtime implementation d029c185 and format-only test adjustment 71c48d9c are preserved. Source gates bind the exact latter snapshot. First full Buy qualification: 2,535 pass, 27 skip, zero failures. Second full pass is running. Format now passes; analyzer has zero errors/warnings and one inherited informational brace-style notice. All 37 parent/child records are listed in the candidate replay plan; no device closure yet. Redmi still runs r66.33 pending fresh build/install.

### Final r66.34 Redmi replay — 23 September 2026


Build source 821590ce845f6719439fc92077ce3bf1eea23053. Installed SHA-256 6B624757007AF342491BE1360DC0EE0D625C5E265C889DF3C0A43BD6F5FD21AC.
Two full local Buy runs: 2535 passed / 27 skipped each. All 3246 sealed source inputs unchanged after build/device replay.

Review fixtures only. No live payment, sent chat, provider-issued PO, real delivery or production acceptance. One local COD order BUY-NEW-06/MS-NEW-11 was created. Original Wholesale basket remains 2 packs/INR1550; temporary Shop basket item removed. Invoice save dialog cancelled.

All 37 original records have a disposition; this is not a claim that all defects are closed. Five child records registered, including one explicit acceptance-coverage gap. Stop now without another implementation/build cycle.

{'closed_verified': 13, 'partial_child_registered': 12, 'open_dependency': 6, 'partial_dependency': 4, 'closed_superseded': 2}

| Record | Status | Disposition |
|---|---|---|
| R6633-D01 | closed_verified | Mixed MS-NEW-03 preparing estimate now says Delivery; delivered history remains Delivered. Evidence: redmi/r34-order-wording-search.png |
| R6633-D02 | partial_child_registered | Original Recent nested product Cart fixed. Retail Visit Store with only Wholesale basket still lacks aggregate Cart; C01. Evidence: redmi/r34-recent-product-final.png, redmi/r34-nested-product-scroll.png, redmi/r34-store-ready.png |
| R6633-D03 | closed_verified | Compact header and inline Add; host large-text variants qualified separately. Evidence: redmi/r34-recent.png, redmi/r34-recent-final.png |
| R6633-D04 | closed_verified | Transparent floating Cart on inspected Store and nested product surfaces; no white backing strip. Evidence: redmi/r34-store-added.png, redmi/r34-wholesale-store-ready.png, redmi/r34-nested-product-scroll.png |
| R6633-D05 | open_dependency | Authoritative comparable supplier/variant offers unavailable; refresh remains truthful. Evidence: redmi/r34-compare.png |
| R6633-D06 | partial_child_registered | Compact filter, inline Saved, inline price/Add and quiet browse verified; administrator data and C03/C05 remain. Evidence: redmi/r34-offers-filter-ready.png, redmi/r34-offers-saved.png, redmi/r34-offer-wholesale-product.png, redmi/r34-cart-scope.png |
| R6633-D07 | partial_dependency | Duplicate sign-in removed. Account binding unavailable; collection does not bypass verification. Evidence: redmi/r34-collection.png |
| R6633-D08 | partial_dependency | Platform delivery names render; authoritative service assignment remains deferred. Evidence: redmi/r34-shop-product.png, redmi/r34-offer-wholesale-product.png |
| R6633-D09 | partial_dependency | Store identity grouping qualified locally; authoritative shipment identity not supplied. Evidence: redmi/r34-wholesale-review.png |
| R6633-D10 | open_dependency | Live delivery explicitly unavailable; no live provider route or physical delivery claimed. Evidence: redmi/r34-tracking.png |
| R6633-D11 | open_dependency | PhonePe/Paytm review flow works but real provider handoff unavailable; no live payment. Evidence: redmi/r34-payment-unavailable.png, redmi/r34-wholesale-provider-unavailable.png |
| R6633-D12 | closed_verified | Unavailable attempt locks methods; cancellation restores selection and next review. Evidence: redmi/r34-payment-unavailable.png, redmi/r34-payment-cancelled.png, redmi/r34-review-cod.png |
| R6633-D13 | closed_verified | Timing preserves Dispatch within one day, not a fabricated arrival promise. Evidence: redmi/r34-wholesale-review.png |
| R6633-D14 | partial_child_registered | New Add reveals purchased item. Exhaustive Edit basket/scroll matrix remains C05. Evidence: redmi/r34-crossscope-add-cart.png |
| R6633-D15 | closed_superseded | PO reference and PO-as-payment removed; legitimate PO workflow remains D17. Evidence: redmi/r34-wholesale-payment.png, redmi/r34-payment.png |
| R6633-D16 | partial_child_registered | New Buy/invoice names normalized; historical Orders and chat retain padded names, C02. Evidence: redmi/r34-supplier-chat.png, redmi/r34-orders.png, redmi/r34-invoice.png |
| R6633-D17 | partial_dependency | PO removed from payment and supplier chat works. Issuance, buyer approval, supplier acceptance, communication lifecycle still incomplete, not solely backend acceptance. Evidence: redmi/r34-wholesale-payment.png, redmi/r34-supplier-chat.png |
| R6633-D06-D-C1 | closed_verified | Saved Wholesale offer is accessible from Offers even after Shop context; inline presentation. Evidence: redmi/r34-offers-saved.png, redmi/r34-offer-wholesale-product.png |
| R6633-D06-G-C1 | closed_superseded | No stale PO reference field remains; D17 owns replacement workflow. Evidence: redmi/r34-payment.png, redmi/r34-wholesale-payment.png |
| R6633-D08-C1 | open_dependency | Schedule independent of transport requires authoritative Store/logistics assignment. Evidence: redmi/r34-wholesale-review.png |
| R6633-D09-C1 | open_dependency | Authoritative stable fulfilment IDs remain integration dependency. Evidence: redmi/r34-wholesale-review.png |
| R6633-D12-C1 | closed_verified | Cancelled Wholesale payment then Shop Add succeeds, original basket preserved. Evidence: redmi/r34-wholesale-provider-unavailable.png, redmi/r34-crossscope-add-cart.png |
| R6633-D06-G-V01 | closed_verified | Inline price/Add on Shop and Wholesale offer details; Cart item visible on entry. Evidence: redmi/r34-shop-product.png, redmi/r34-offer-wholesale-product.png, redmi/r34-cart-scope.png |
| R6633-D06-G-V02 | closed_verified | Quiet browse, aligned price/quantity and persistent total/Checkout on inspected scopes. Evidence: redmi/r34-cart-scope.png, redmi/r34-wholesale-cart.png |
| R6633-D06-G-V03 | partial_child_registered | Address/pickup frontends inspected. Compact lower-field/validation matrix remains C05; account binding deferred. Evidence: redmi/r34-address-edit.png, redmi/r34-address-keyboard.png, redmi/r34-collection.png |
| R6633-D06-G-V04 | closed_verified | Compact methods, no PO field, explicit recovery; production provider success excluded. Evidence: redmi/r34-payment.png, redmi/r34-payment-cancelled.png, redmi/r34-wholesale-payment.png |
| R6633-D06-G-V05 | partial_child_registered | Review works, but Wholesale duplicates product/amount across shipment and trade table, C03. Evidence: redmi/r34-review-phonepe.png, redmi/r34-wholesale-review.png |
| R6633-D06-G-V06 | closed_verified | Compact confirmation and next action verified with labelled local COD order only. Evidence: redmi/r34-local-cod-confirmation.png |
| R6633-D06-G-V07 | partial_child_registered | Compact actions work; empty historical Payment section C04 and provider completion remain. Evidence: redmi/r34-tracking-actions.png, redmi/r34-invoice.png, redmi/r34-delivered-detail.png |
| R6633-D06-G-V08 | partial_child_registered | Normal-size device samples inspected and local enlarged-text renders passed; complete physical-device variant matrix C05. Evidence: redmi/r34-shop-product.png, redmi/r34-cart-scope.png, redmi/r34-wholesale-review.png |
| R6633-D06-G-V09 | partial_child_registered | Inspected keyboard/form cases retain content; exhaustive lower-field/correction matrix C05, not a blanket keyboard pass. Evidence: redmi/r34-address-keyboard.png, redmi/r34-chat-keyboard.png, redmi/r34-wholesale-quantity.png |
| R6633-D06-G-V07-C1 | partial_child_registered | Payment facts reduced; historical status repetition and empty Payment remain C04. Evidence: redmi/r34-orders.png, redmi/r34-tracking.png, redmi/r34-delivered-detail.png |
| R6633-D06-G-V07-C2 | closed_verified | Compact single cancellation choice and correctly named quiet supplier action. Evidence: redmi/r34-manage-order.png |
| R6633-D06-G-V07-C3 | partial_child_registered | Historical delivered fixture visible; returns correctly unavailable. Collected/partial receipt qualified locally only, full device matrix C05. Evidence: redmi/r34-delivered-detail.png, redmi/r34-delivered-return.png, redmi/r34-return-reason.png |
| R6633-D17-C1 | closed_verified | Contact supplier opens supplier order conversation. No message sent. Evidence: redmi/r34-manage-order.png, redmi/r34-supplier-chat.png |
| R6633-D17-C2 | partial_child_registered | Concise draft and compact context; padded name/truncated party subtitle remain C02. Evidence: redmi/r34-supplier-chat.png, redmi/r34-chat-keyboard.png |
| R6633-D10-C2 | open_dependency | Google live map and provider location/events remain mandatory before go-live. Evidence: redmi/r34-tracking.png |

## Open children

### R6634-C01 — Retail Visit Store hides aggregate Cart when only Wholesale basket exists
Parents: R6633-D02. Retain a reachable aggregate Cart on every nested Store surface, even with no local-scope items. Do not add empty carts.
Evidence: redmi/r34-store-ready.png

### R6634-C02 — Public Store naming and chat header remain inconsistent
Parents: R6633-D16, R6633-D17-C2. Use the same safe public display identity in historical Orders and order chat, retaining full party/order access and legal identity. Header subtitle currently ellipsizes.
Evidence: redmi/r34-supplier-chat.png, redmi/r34-orders.png

### R6634-C03 — Wholesale review repeats product and subtotal
Parents: R6633-D06, R6633-D06-G-V05. Combine shipment items with pack/MOQ/unit-price facts in one compact table; preserve totals, tax, returns and Store grouping.
Evidence: redmi/r34-wholesale-review.png

### R6634-C04 — Historical tracking has empty Payment section and repeated status
Parents: R6633-D06-G-V07, R6633-D06-G-V07-C1. Hide empty payment group or provide truthful concise unavailable information; avoid repeated current status in history while preserving timeline facts.
Evidence: redmi/r34-delivered-detail.png, redmi/r34-orders.png

### R6634-C05 — Remaining acceptance matrix is not device-qualified
Parents: R6633-D06, R6633-D14, R6633-D06-G-V03, R6633-D06-G-V08, R6633-D06-G-V09, R6633-D06-G-V07-C3. Coverage gap, not a reproduced failure: complete Bulk-specific paths, every editable lower field/validation/back case, Edit basket scroll matrix, publisher rapid-switch frames, physical-device enlarged text and collected/partial receipt states using labelled fixtures. Existing local passes do not imply this entire Redmi matrix passed.
Evidence: redmi/r34-address-keyboard.png, redmi/r34-return-reason.png


Evidence archive SHA-256: b97036ace077a798bb571099b0197967dac768995c7c136292a7c0a07144edf2. Previous archive entries preserved byte-for-byte. Source implementation is unchanged after qualification; this update records evidence only. No integration into Codex/Store or main performed.

### Founder-authorized recurrence prevention gate — 23 September 2026

Scope: gate setup only, before any R6634 child implementation. Actor is Cursor Buy; launch-supporting reliability work prevents repeated founder-visible defects and false closure. Reuse the permanent founder-repeat regression entry, current owner check and existing review APK wrapper. No application, Store, backend or other-worktree changes; no APK and no child fix authorized by this setup.

Root cause: host test counts and broad partial acceptance did not prove each affected route/state; review-only provider boundaries and visual checks were conflated with complete acceptance. Permanent REG-20260807-058-REPEATED-FOUNDER-NAVIGATION-DIRECTIVE-NOT-GATED now also records this Buy recurrence, retaining its original evidence and gates.

Mandatory machine gate: `scripts/check-buy-founder-regression.py`, ledger `config/buy-founder-regression.json`. The 5 open children have 64 explicit route/state cells linked to founder requirements and retained r66.34 evidence. No test or device pass has been fabricated. `selected` is deliberately empty: the next authorized implementation must select exact ticket(s), name behavior tests and preserve reproduction evidence before editing. Tests may be added in the preparation step; runtime fixes require the implementation gate. Old records remain in the existing handoff/archive.

- Implementation rejects missing selection, missing original reproduction, unnamed behavior tests and deleted/weakened original scenario cells.
- Pre-commit rejects application deltas outside the declared affected owners and requires exact, non-skipped Flutter machine-log success for every selected scenario, bound to current source bytes.
- The existing APK wrapper invokes the same local-evidence gate before building. It does not require future device proof before a review APK can exist.
- Closure additionally requires each scenario's current-source Redmi evidence, screenshot and hierarchy hashes, built and pulled-installed APK hashes matching, visual inspection, separate recorded founder approval, no open children and no unresolved dependencies.
- A coverage gap remains open. A backend dependency cannot be called a completed frontend journey. A partial improvement cannot close its parent. Historical screenshots or unrelated passing tests cannot substitute for an exact scenario.
- These gates enforce evidence and completeness, not an impossible guarantee of zero future bugs. Human visual judgment and truthful evidence collection remain necessary. Raw filesystem writes are not intercepted; the mandatory workflow boundaries enforce the contract.

Commands: `python -B scripts/check-buy-founder-regression.py --phase setup|implementation|pre_commit|build|close`. Obtain current input fingerprint with `--phase setup --fingerprint`. Run regression self-tests with `python -B scripts/test-buy-founder-regression.py`. Local evidence uses the Flutter `test --machine` JSON event log, exact test name, file hash and source fingerprint; device entries additionally identify Redmi TG8HCYTGGQT885OF, retained APKs, PNG/XML, visual review and outcome. Keep original evidence immutable and add new attempt records. Do not weaken expected outcomes to match an implementation.

Validation: 21 focused gate tests passed (including wrong APK/device, missing visual approval, skipped or unrelated tests, stale source, removed scenarios and open children). Both PowerShell hooks parsed. Existing permanent regression checker passed 4,616 entries / 2,550 applicable. Setup and metadata pre-commit pass; implementation/build deliberately fail with no selected ticket. Application source/tests and installed r66.34 are unchanged.
