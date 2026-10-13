# Buy remaining fixes and frontend eligibility — local-only cutoff

Current Git disposition supersedes the historical uncommitted parking notes:
the founder subsequently authorized complete reconciliation, a clean source
checkpoint and remote preservation. See `CURSOR-BUY-INTEGRATION-HANDOFF-20260922.md`
and its inventory/completion record for exact commits and verification. Runtime
source and the eleven-ticket device/backend obligations below are unchanged.
Backend waits for Codex's newly integrated full baseline; no new APK is made.

Founder instructions, 22 September 2026:
Implement the 10 remaining Redmi findings, test locally with precision, check for
child defects, reconcile Git and park safely. Do NOT build an APK for this batch.
Retest these fixes on the NEXT Redmi APK together with subsequent backend tickets.
Backend implementation begins only after this frontend cutoff is completed.

Current branch: work/cursor-ui/buy-ready-20260921.
Starting HEAD: 87bc96d4c28300146c9e2c3c3b37c7c3aacffed0.
Preserve the existing 30 dirty/untracked records and all earlier APK evidence.
Starting status digest: 8042120ba1c34f6dd0216ca09b1b66d6956201bc124e6e354beadd7d393b39ce.
No merge, push, main mutation, Store-worktree edit or production qualification.

## Tickets 1–10

Use CURSOR-BUY-R6632-DEVICE-RETEST-20260922.md as the immutable device finding
source. Implement residual Buy behavior; do not label provider/data prerequisites
as fixed by fabricated responses.

1. RB006 / NEW-002: consistent customer Store names in Cart/checkout.
2. RB007 / NEW-001: expanded Store search, scoped to the selected Store.
3. RB008 / NEW-002: consistent customer naming through draft/Maps handoff.
4. RB011 / NEW-003: preserve originating pickup checkout through sign-in Back.
5. RB012 / DEP-01: validate unavailable-provider recovery locally; live provider
   completion is a backend-phase dependency, not simulated success.
6. RB013 / NEW-004/005/006: remove pickup promotional block from BOTH public
   Store details and Wholesale supplier preview; compact Recently viewed Add
   layout; correct shopping-area selected-tick contrast.
7. RB018 / NEW-009: compact payment-benefit card spacing.
8. RB022 / NEW-007: address-request field accessible name/focus.
9. RB026 / NEW-008: remove misleading Delivered estimate suffix on active order.
10. RB029 / DEP-02: preserve exact catalogue identities; authentic Store records,
    photographs and exact Maps destination remain coordinated data prerequisites.

## Ticket 11 — Store → Buy eligibility for Quick, Scheduled, Wholesale and Bulk

Status: LOCAL FRONTEND CUTOFF COMPLETE; external/device dependencies retained below. Founder-authorized public contract
ownership; Store-side wiring is Codex-owned. Classification: mvp_required for
truthful availability and safe checkout; local-only frontend stage.

Actor/outcome: public shopper sees and orders only explicitly eligible offers
for their location, without delivery-text or MOQ-based classification guesses.
Reuse existing Buy models/content contracts, catalogue/session filters, search,
Saved, details, cart and checkout screens. Preserve approved layouts and paging.
Do not create four independent Store toggles or another catalogue authority.

Acceptance requirements:
1. Replace delivery-text inference (e.g. 20 minutes) with explicit fulfilment
   eligibility. Missing/stale eligibility never grants Quick delivery.
2. Replace minimumOrder > 2 classification with explicit Wholesale/Bulk offer
   classification. MOQ, pack size and quantity tiers are independent fields.
3. Quick/Scheduled require Store readiness, customer location and MoolSocial
   fleet availability. A Store switch alone cannot grant eligibility.
4. Separate Scheduled booked-slot eligibility from courier availability; the
   existing courier mapping must not imply a reservable delivery slot.
5. Apply the same rules in Buy, Wholesale, Visit Store, search, Saved, product
   details, cart and checkout. Preserve pagination and discard responses from
   stale location/filter generations.
6. Allow multiple delivery options for one SKU; distinguish bulk purchase offer
   classification from bulk freight fulfilment.
7. Publish exact shared public schema/fields and source revision/fingerprints in
   a local handoff. Codex owns Store settings, product editor, CSV and provider
   projections. Never edit Codex's checkout or silently copy its dirty data.
8. Test disabled channels, absent/expired eligibility, closed Store, unavailable
   fleet, location changes and explicit Bulk versus Wholesale independent of MOQ.

Backend deferred. Frontend fixtures must be explicitly test-only and cover
unavailable/incomplete cases. Do not claim live production eligibility.
Codex-reported context: Store business type and Retail/Wholesale switches have
25 local tests; explicit offer classification/fulfilment wiring still pending.
Downloads remains queued and excluded from this batch.

Existing owner reuse: apps/mobile/lib/features/buy/buy_v2_models.dart,
buy_v2_content_contracts.dart, buy_v2_session.dart, buy_v2_catalogue_data.dart;
apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart, buy_v2_views.dart,
buy_v2_screen.dart, buy_v2_store_address.dart; affected Buy tests under
apps/mobile/test/ui_v2/buy. Exact edits/tests to be recorded after inspection.
No backend, Store, Counter Sale, CSV, native, dependency or screenbook edits.

## Execution log (historical)

The exact existing owner registration was reconciled under the founder's narrow
blocker authority. Implementation admission passed (admission-r3.log), preserving
registry 4616 and its fingerprint, branch/HEAD and all unrelated owners. No broader
policy or governance work is authorized. Evidence is outside the worktree at
`C:/GUARANTEED OUTCOME/outputs/buy-local-cutoff-20260922`.

Implementation in progress: customer Store names; expanded Store search; safe
Security return to pickup checkout; removal of collection promotions; compact
Recent and benefit cards; recipient accessibility; active estimate wording;
explicit public offer classification and location/time-bound eligibility.

Focused-r1: 12 tests passed. Focused-r2 found two new test-fixture mistakes
(option serialization order and querying an excluded review product in production
mode); corrected without weakening acceptance checks. Storefront expansion tests
are passing in the running widget suite. Further regression remains in progress.
No ticket is declared fully closed yet; no new APK/device acceptance is claimed.

Child risks being tested: missing/expired/disabled eligibility; cached facts after
location changes; multiple fulfilment choices; Scheduled requiring an actual
future slot; MOQ/pack/classification separation; stale pagination identity; nested
Add taps, large text, Android insets and focused recipient semantics.

## Required safe-parking evidence

Before declaring cutoff: per-ticket disposition and focused regression results;
child-defect review; exact HEAD plus tracked/untracked source fingerprints and
Git reconciliation of all work; durable local handoff with no omitted changes.
Do not represent a dirty uncommitted tree as a clean committed checkpoint.
Record unresolved backend/Store dependencies separately from local fixes.

## Mandatory next Redmi retest memory

Retest tickets 1–11 above together with backend integration tickets on the next
fresh Redmi candidate: source/installed checksum reconciliation; Store-specific
expanded search and preserved filter/paging state; names; sign-in return;
provider failure/recovery and authentic completion; compact sheets/cards and
Android keyboard/insets; accessible request field; active-order status wording;
authentic Store SKUs/photos/address/Maps; explicit eligibility for all channels
including expired/missing data and location changes. Also qualify zero-active
Delivery rail with an isolated approved dataset (DEP-03). Local tests do not
close these future device obligations. No APK authorized for this local batch.

## Ticket 11 public contract handoff — local schema v1

Public product field: `offerClass`: `retail | wholesale | bulk` (nullable means
unknown). This is independent of `minimumOrder`, pack description, quantity tiers
and transport. `BuyV2Product.copyWith` preserves it across exact SKU variants.

`BuyV2ProductFactsSnapshot.eligibility` is `BuyV2OfferEligibility?`. Its JSON
schema has required `schemaVersion: 1`, `productId`, `storeId`, `sourceRevision`,
`customerLocationKey`, UTC ISO-8601 `observedAt` and `expiresAt`, `offerClass`,
`channelEnabled`, `storeReady`, `fleetAvailable`, `customerLocationConfirmed`, and array `options` containing
zero or more `quick | scheduled | courier | freight | collection`. Optional
`scheduledSlotId`, UTC `scheduledStart` and `scheduledEnd` are necessary for a
Scheduled grant; `reviewFixture` defaults false. Unknown schemas/enums or malformed
required fields produce no eligibility. A copied display promise never grants it.

The provider must bind the response to the exact request location key and product
and Store identities. Empty source/Store/location, future observations, expiry,
wrong identities/classification, disabled channels and Store-not-ready fail closed.
Quick and Scheduled require fleet availability and a provider-confirmed customer location. Scheduled additionally requires a
named future interval. Courier alone never means a booked slot. Multiple grants
are retained and checked independently. Provider projections must compute readiness
and serviceability; a Store switch alone is insufficient.

Public session selection key includes authoritative region, Google place identity
and local selection revision. Catalogue query key v4 includes it; existing empty-
location query v2/v3 and Store-procurement context remain compatible. Cached facts
are evaluated at use time; Add/checkout preserve the Cart on an expired or changed
location. Store browsing remains possible when ordering eligibility is unknown.
Store procurement continues to use its existing purchaser/supplier grant, not this
new public consumer contract.

Legacy screenbook review options are explicitly marked fixture-only model inputs
and honored only in review mode. Test fixtures use explicit simulated grants.
Neither is live Store or fleet evidence. Codex owns Store settings/editor/CSV and
provider mapping. No Codex checkout was modified. Exact final source fingerprints
will be recorded at safe parking; this dirty worktree is not a committed revision.

## Intermediate local evidence

Focused-r4: 44 passed, 1 pre-existing capture-only skip. Includes actual app-router
pickup sign-in -> Android Back -> Security -> exact checkout, retained pickup and
Cart, focused recipient semantic ownership, expiry/location changes and contract
failure cases. Recent/benefit regression in focused-r3 passed; its one recipient
failure was corrected and passed in r4. No device acceptance is inferred.

Contract-r2 retained procurement behavior and passed more than 500 checks; two
paging fixtures used the wrong initial location key (Jodhpur instead of unset).
They are corrected to match their exact session; rerun pending. Partner reruns
exposed old test navigation that tried to tap hidden category controls while search
was expanded; the revised journey finishes search first. Android Back now finishes
expanded search before leaving the Store. Test fixture clocks are explicitly bound
to the same clock as their session.

Preservation check: Flutter's package-graph reorder had identical package names,
versions and dependencies; its generated bytes were preserved in external evidence
and original ordering restored. The generated plugin registry corrected the local
private-plugin path from the inherited Codex worktree to this Cursor worktree.
That exact file was admitted as a generated qualification owner; no plugin,
dependency, native implementation or unrelated workspace was changed. This avoids
parking a newly verified checkout with a reference to another owner's directory.

The public source handoff is bound to starting commit
`87bc96d4c28300146c9e2c3c3b37c7c3aacffed0` plus exact current dirty-file SHA-256s in
`C:/GUARANTEED OUTCOME/outputs/buy-local-cutoff-20260922/public-contract-source-fingerprints.json`.
A source fingerprint is not a commit or backend qualification. Changing, editing,
or removing the selected delivery address invalidates previously cached public
eligibility by changing the selection revision. An invalid facts refresh clears
its eligibility and marks previous facts stale; no cached Quick grant survives it.

## Final local disposition — 22 September 2026

Local frontend cutoff is complete. Nine change tickets (1–4, 6–9, 11) are
implemented and locally verified. Tickets 5 and 10 are closed only for their local
frontend portion; their explicitly postponed provider/Store-data dependencies
remain OPEN for backend integration and next-Redmi acceptance. They are not
represented as fully production-closed defects.

| Ticket | Local result and child disposition |
| --- | --- |
| 1 RB006 | Exact generated Store naming normalized in Cart and checkout; genuine numeric Store names preserved. |
| 2 RB007 | Store-scoped search expands; Finish/Android Back restores controls; filters, category, paging and selected Store remain intact. |
| 3 RB008 | Maps and Store/draft customer copy use the same exact-identity normalization; authentic destination remains DEP-02. |
| 4 RB011 | Pickup sign-in uses existing Security safe-return wiring; real app-router cancellation returns to checkout with Cart and pickup preserved. |
| 5 RB012 | Local provider-unavailable/payment-failure/retry recovery verified; Cart retained, no fabricated order/payment success. Live-provider DEP-01 remains open. |
| 6 RB013 | Pickup banners removed from public Store info, Wholesale preview and alternate header path; Recent Add is compact; selected area tick is white. Children NEW-004/005/006 locally closed. |
| 7 RB018 | Unselected payment-benefit cards no longer reserve empty selection-status space; selection/continuity regression passes. NEW-009 locally closed. |
| 8 RB022 | Recipient input has one stable accessible name while focused, without duplicate editable nodes; keyboard/Back/inset checks pass. NEW-007 locally closed. |
| 9 RB026 | Active estimate suffix says Delivery rather than Delivered; actual order status/history remain separate. NEW-008 locally closed. |
| 10 RB029 | Exact branch/SKU/variant identity, honest unavailable metadata and authentic-media boundaries retained and verified. No invented replacement catalogue. Authentic Store projection/photos/address DEP-02 remains open. |
| 11 | Explicit offer class and location/time-bound multi-option eligibility; no delivery-text or MOQ inference; fleet/location/slot checks; public discovery/Saved/details/Cart/checkout consistency and stale-query identity; Store procurement contract preserved. Backend projection remains deferred. |

Additional child checks/fixes: invalid facts refresh revokes cached eligibility;
address selection/edit/removal changes invalidate old grants; missing Store address
is never invented at pickup; Store catalogue stays browsable when ordering is
unavailable; related Store labels no longer equate courier with Scheduled; Wholesale
artwork uses offer classification rather than MOQ. Each is locally covered; Android
rendering/provider behavior remain mandatory next-device checks.

### Verification evidence

Evidence directory: `C:/GUARANTEED OUTCOME/outputs/buy-local-cutoff-20260922`.
- `final-regression.log`: 630 passed, one legacy persistence expectation failed.
  No runtime change followed that run; its test now explicitly verifies address
  change invalidates eligibility without losing Cart. `address-persistence-final.log`:
  1 passed. Together all 631 checks in that regression selection pass.
- `partner-r5.log`: 11 passed (expanded Store search, Android Back, exact Store
  navigation and compact layouts), four missing-address fixture expectations failed.
  Their revised checks correctly reject an invented Store address and retain Cart:
  `children-final.log`, 20 passed including those four and eligibility failure cases.
- `focused-r3.log`: Recent/payment-benefit regression passed across compact and
  enlarged text profiles. Its recipient-label child failed then passed in
  `focused-r4.log`: 44 passed, one existing capture-only skip.
- `contracts-r3.log`: 146 passed, including procurement preservation, production
  payment/retry, paged-state restoration and eligibility checks.
- Dart analysis: zero errors/warnings; style-only info diagnostics retained.
- `git diff --check`: passed. Implementation admission: passed with exact owners,
  unchanged 4616-entry registry binding and unchanged branch/HEAD.

These are overlapping focused runs, not a claimed sum of unique tests or an APK
qualification cycle. Failed intermediate logs are retained with their correction
and passing rerun. No unresolved local child defect is knowingly hidden.

### Stop and next-device memory

No APK built, installed or authorized by this cutoff. Prior r66.32 source manifest
remains byte-identical. Mandatory next Redmi replay: all 11 local dispositions,
Android keyboard/navigation/insets, focused recipient accessibility, Store search
expansion/Back, names/Maps, compact Recent/offers, active delivery wording, all
eligibility combinations and new backend integration tickets. Retain DEP-01,
DEP-02 and prior DEP-03 as explicit device/provider/data obligations.

Git is parked on the original feature branch and HEAD with uncommitted work
preserved. This is not a clean commit, merge, push, release or production acceptance.
The recovery archive/patch and exact file manifest will be referenced below.

Formal integration handoff check was run once and rejected the uncommitted tree
(`handoff-check.log`: production handoff worktree is not clean). No check was
weakened and no commit/push authorization was inferred. This does not invalidate
the local regression; it means the preserved patch must be reviewed/committed
before a future formal integration handoff. Backend/Store-data and device closure
remain separate as listed above.

Safe parking artifacts:
- `C:/GUARANTEED OUTCOME/outputs/buy-local-cutoff-20260922/parked-source.zip`
- `C:/GUARANTEED OUTCOME/outputs/buy-local-cutoff-20260922/parked-source-manifest.json`
- `C:/GUARANTEED OUTCOME/outputs/buy-local-cutoff-20260922/worktree.patch`
- `C:/GUARANTEED OUTCOME/outputs/buy-local-cutoff-20260922/index.patch`

The archive preserves every current modified/untracked task file at its relative
path, including earlier uncommitted work and evidence. The manifest records exact
bytes/SHA-256, original branch/HEAD, status digest and archive/patch fingerprints.
It is verified against disk after creation. No existing evidence is removed.
