# LF-02.1 — Public Store details (Batch 02)

Status: founder authorized after dddbe8df approval, 15 October 2026 IST.
Implementation tested and loaded on OPPO; founder acceptance pending.
Single Codex writer on the existing
last-frontend feature branch; no new tree, framework, policy or registry.

## Bounded outcome

For the existing Retailer/Grocery Store, capture a dedicated customer-facing
contact in existing Store details, and expose explicitly saved opening/closing
hours through the existing typed public Store projection and details widget.
Do not copy account/KYC numbers or infer hours from unsaved default controls.
Optional fields preserve old records. Keep Store/branch identity, private invoice
fields, Stock and existing collection behavior unchanged.

The founder approved the explained LF-01 correction and said "approved go ahead
with next scope". Ordered Batch 02 is approved for this minimal frontend work.
No Batch 03 until this slice is tested, hot-reloaded and approved on OPPO.

## Reuse and acceptance

Existing publication/settings baseline: 25 tests pass. Existing address and terms
capture, scope guards and hour pickers stay in place. Add focused tests for old
records with absent values, valid and invalid input, saved-hour projection, Store
isolation, public/private separation and visible public details. Run affected
settings/publication/navigation tests and changed-file analysis. Inspect actual
OPPO hot reload; host fixtures do not establish a live published Store.

## Deferred

Backend publication/acknowledgement, current live open/closed/orderability status,
serviceability/Maps configuration and authoritative collection eligibility stay
provider-held. No KYC, new routes, runtime data injection, transaction or APK work.
Public contact/hours are descriptive inputs, never ordering authorization.

## Preservation

Accepted LF-01 checkpoint dddbe8df08063d3332006b605aadfece565228d8 remains in
history. Base 3c5a454bf8af173d9736c75213cafb88e641765c and Cursor stay untouched.
Only this successor's literal owners are added to existing local ticket admission.

## Verified implementation and founder correction

- Added optional public contact and explicitly saved opening/closing hours to
  existing Store details, JSON and public Store projection. Old records retain
  absent fields; account/KYC contact is never copied. Invalid input is rejected;
  overnight schedules remain valid. Direct invalid phone drafts do not project.
- Existing address form captures "Customer contact number (public)". Its explicit
  address-field list preserves invoice signatory and private references. Clearing
  contact removes it; later address saves retain saved hours. Saving hours keeps
  the existing address/contact. Public display uses existing Store details rows.
- Descriptive data survives existing catalogue wrappers and retained Store detail
  fallback. No publication acknowledgement, live state or orderability is added.
- Founder rejected the proposed "Open business profile" button in Store status.
  It has been removed, not shipped. Reused MoolGlobalProfileShortcutV2 on Store
  home and moved the existing header icon from the optional search band to the
  persistent Store-name row, avoiding duplicates on noncompact views. Updated
  title-width measurement for its 48px touch target. No global profile owner,
  second account, sign-in or admin approval was added or changed.
- The same global user authenticates through the supported auth methods, then
  receives Store capability only after authoritative admin approval. OPPO's saved
  evaluation Store is not proof of a live authenticated/admin-approved account.

Host results: 44 settings/publication/Buy routing tests, 7 affected Store atomic
configuration tests, and 2 profile/navigation tests at 412x915 and 320x568 pass.
The public contact/hours regressions failed before implementation. Existing
handoff tests also passed in a preceding focused run. Changed-source analysis
found no errors/warnings; the large dashboard retains 8 pre-existing style infos
outside the changed lines. Script parsers and 13 exact identity/negative probes
passed. No global policy or registry changes. A machine ticket ID used a dot on
the first check and was corrected to existing allowed syntax LF-02-1; the pattern
was not weakened. A whole-file formatter reflow was removed before qualification.
An initial test placement above local helpers and an incorrect profile-context
expectation were corrected; neither failed run is reported as a pass.

OPPO: existing runtime r67.3, no APK install or data reset. Const-record additions
required a hot restart (reload was rejected and not claimed passed); source loaded
after restart. Subsequent profile correction hot-reloaded one library. Saved Cart
remains 1 soap pack / INR164 with its original payment hold, and saved Store/Stock
remain available. Real Store status -> existing business profile -> Operations ->
Store settings was inspected before the founder's icon correction; the new icon
was then inspected on Store home and tapped successfully into that same panel.
Current screen is the global profile panel with the saved Store context.

Current captures, in the calling task outputs folder:
`lf02-global-profile-icon-20261015.png` and `lf02-global-profile-final.xml` (phone
temporary XML; semantic readback retained in tool output). Earlier popup captures
are superseded observations, not accepted references. No number/hours were seeded
or saved on OPPO, and no transactions were created. Actual phone contact
save/relaunch and public-provider display remain unverified, not silently passed.
The new contact field's visual review is still pending. Batch 03 has not started.
