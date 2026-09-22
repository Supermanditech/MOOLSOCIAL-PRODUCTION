# Cursor Buy integration handoff and new-baseline request — 22 September 2026

## Current disposition

Founder explicitly requests reconciliation of ALL Cursor work after the previous
integrated baseline, clean local Git, remote preservation and a detailed Codex
handoff. This is a source/evidence handoff, not production or device acceptance.
The verified source checkpoint is `a78b1b38803b4dca6fcc7d715ee9ccc9528a4482`;
the evidence-only completion commit is its direct child containing this record.
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
