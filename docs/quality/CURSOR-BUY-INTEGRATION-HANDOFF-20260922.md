# Cursor Buy integration handoff and new-baseline request — 22 September 2026

## Current disposition

Founder explicitly requests reconciliation of ALL Cursor work after the previous
integrated baseline, clean local Git, remote preservation and a detailed Codex
handoff. This is a source/evidence handoff, not production or device acceptance.
The original parked source checkpoint is `a78b1b38803b4dca6fcc7d715ee9ccc9528a4482`;
the original evidence-only completion commit is its direct child
`a4ff1e5fde01cdfea29f1bf576bde35aa64a3b6e`. The three authorized product-control
repairs below are a subsequent source delta. Integrate the complete branch
including that delta, not only a78b1b38. The original inventory/receipt remains
bound to the historical checkpoint; it is not relabelled as the later source.
Latest application source: `d9ec753b6c2f1dae9a7f9689ac6e1303b80353db`.
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
order/invoice actions, Medicine promotions, and cross-Buy Cart movement). All earlier
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
