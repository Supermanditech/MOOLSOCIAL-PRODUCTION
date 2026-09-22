# Cursor Buy integration handoff and new-baseline request — 22 September 2026

## Current disposition

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
Latest application source: `f4d2e116bb1a42f10d588ac82e36cd23065d6523`.
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
