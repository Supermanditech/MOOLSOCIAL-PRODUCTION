# Shared Reports & Downloads — local frontend batch

## Founder correction: remove redundant Stock menu (v18)

Removed the three-dot More product tools menu from Stock search. Catalogue,
manual and CSV remain in the existing + journey; low stock remains in Filter.
Stock movements now links to the existing statement operation from the central
Stock report panel, alongside exports. Selected-Store/account/draft guards
remain in effect. No new report implementation or backend dependency bypass.
25 focused connected checks pass; scoped analysis clean. Local fixture renders
await founder review, not device acceptance. Offers remains on hold; no claim
of full frontend completion or whole-app download migration.

## Founder correction: centralize Stock downloads (v15)

The latest founder direction supersedes repeated inline export placement.
Stock no longer presents PDF/Excel/CSV or period controls. Its existing entry
inside Reports & Downloads switches to the scoped stock report in-place, using
the existing export component. Documents returns to the normal document list;
no new route or download-selection popup. Stock scope is all saved products for
the selected Store. Dates/history remain fail-closed with an explicit message.
Scope invalidation removes the panel; customer Downloads cannot expose it.
23 shared Downloads and18 connected checks pass, analysis clean. Visual review
pending for this changed Stock/report placement; prior document-row styling is
preserved. This is not a whole-app contextual-download migration: remaining
invoice/customer/public-side entrypoints must use the centralization rule in
their respective frontend batches and later authorized Cursor integration.

Create Offers is separately on hold by founder direction. Determine supported
types, retailer data ownership and exact public/checkout mapping before further
offer implementation; old UI approval is not permission to invent new fields.

## Latest: founder visually approved; local technical checks complete

Founder rejected the earlier chip-heavy v3 design and approved the compact
bank/e-commerce-style revision, then delegated remaining technical verification.
Keep this approved normal-size design fixed. Type and period filters now expand
inline from one restrained filter bar, with no popup. Invoice reference leads each
document row; the original PDF action remains one tap. At 2x text filters/actions
stack to prevent split labels and invoice numbers. This is the same shared screen.
Normal-size v5 (approval) and final v7 captures have identical SHA-256 hashes.

Final local evidence: `outputs/commerce-downloads-final-tests.log` has 41 passing
download/Store-source/invoice checks; `commerce-downloads-v6-connected.log` has two
passing connected route/stock checks. Earlier v5 Profile/affected suite passed63,
and pre-polish broader Store regression v3 passed415 (four inherited skips).
Native writer compiled and passed18 payload checks, not physical I/O. Final scoped
analysis in `commerce-downloads-v7-analysis.log` and
`commerce-downloads-final-recovery-analysis.log` is clean. Final actual renders are
`outputs/commerce-downloads-v7`; review fixtures remain visibly not issued.

Technical recovery: timeout/unconfirmed native saves cannot claim success and do
not auto-retry. Changed/invalid next-page cursors recover through a fresh first-page
load, not an endless retry of the expired cursor. Scope, date, query, duplicate-tap,
late-response and payment-revision safeguards were exercised. Approval does NOT
mean customer/live document-source integration, backend history/issuance/access,
all-customer statement exports, OPPO or Git acceptance. Pending dependencies below
remain explicit. Changes remain local/uncommitted; no new APK or Cursor modification.

Founder scope: customer Profile → Downloads; retailer/grocery and other approved
goods-selling business roles → existing Store tools → Reports & Downloads. One
shared implementation, no separate wholesale/manufacturer download screens.
Founder visual approval is recorded above. No backend, APK, OPPO, commit or
push is authorized by this local review. Existing approved layouts/PDF formats
and Cursor's separate working checkout are preserved.

## Implemented

- `CommerceDownloadsScreen` provides inline, unboxed search; document-kind and
  All time / Today / This week / This month / Custom date filters. End date is
  inclusive; invalid/reversed dates are rejected; editing an applied date clears
  the old result until Apply dates. Custom fields share a row at normal width and
  stack with enlarged text. Controls remain scrollable at 320px / 2x text.
- Each document has one PDF action, without an app confirmation or native file
  chooser. Reuses the existing Android 10+ MediaStore writer, saving original PDF
  bytes into Downloads/MoolSocial. Native filename, MIME, size/signature checks
  retain all existing stock CSV/XLSX/PDF and template restrictions. Unique native
  suffixes avoid overwriting an earlier file. Unsupported platforms fail visibly.
- Existing Work invoice PDF Save uses this same byte writer; Share remains its
  existing explicit user action. No invoice is automatically sent by this work.
- Store source reads the current account/Store's existing invoice/order snapshots,
  retains immutable seller identity and approved PDF generation, and reads current
  payment state on tap. A changed payment revision during generation rejects the
  stale result. Local PDF generation remains explicitly review-only/not issued;
  the production unavailable source does not fabricate an issued PDF.
- Store lists page in batches of 50 with query/revision-bound cursors. The shared
  screen rejects wrong scopes/queries, duplicate identities, oversized pages and
  repeated cursors. Late search results cannot replace a newer query.
- Switching account/Store clears displayed records and prevents a pending PDF
  retrieval from reaching the native writer. This does not revoke a file already
  written to the device or cancel a native write already started; backend document
  access control is still required. Uncertain save results never claim success.
- Stock statement is a contextual link to the existing screen and its PDF/Excel/
  CSV actions, not another statement implementation. Existing ledger and order
  destinations remain intact.

## Explicit remaining frontend/data-source dependencies

The customer route is connected but uses `UnavailableCommerceDownloadSource`.
The existing global Buy order cache lacks reliable per-document account ownership;
it MUST NOT become a customer document feed. Customer runtime documents require an
authenticated account-scoped adapter carrying the exact query/owner/document IDs.
Do not substitute a displayed name, phone, or Store invoice collection as proof.

Public Buy/Wholesale's contextual invoice adaptation to the approved shared PDF
format remains a **frontend integration dependency**, not magically complete from
this hub. Existing public native text-PDF output was not replaced in this batch.
Coordinate that adapter with Cursor in its own isolated worktree/authorized merge.
No money-unit, issuer/recipient or fees assumption is permitted. The shared source
contract supports invoice/platform-fee/summary kinds but does not synthesize missing
fee, purchase or summary records. Backend later supplies issued documents/history
and authorizes access. Customer statement exports and all-customer summaries retain
their separate frontend/backend tickets; current stock snapshots are not historical
audited statements or lender acceptance evidence.

## Local evidence

Task root: `C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store`.

- `outputs/commerce-downloads-v3-tests.log`: 415 passed; four inherited skips.
  Shared download UI/source/native-call tests, Store adapter, invoice formats and
  PDF screen, Profile entry, and atomic Store/Counter Sale regression tests.
- `outputs/commerce-downloads-v2-connected.log`: two connected production-router/
  Store-tools navigation checks passed, including reusing Stock statement.
- `outputs/commerce-download-native-v1.log`: bridge compiled; 18 JVM payload checks
  passed. Does not prove Android MediaStore I/O or OPPO behavior.
- `outputs/commerce-downloads-v3-analysis.log`: final scoped static analysis.
- `outputs/commerce-downloads-v3/`: five actual Flutter renders at 360px/1x and
  320px/2x plus the honest customer-unavailable state. Populated images use fictional
  review records and are explicitly marked Preview/not issued, not backend data.
- Initial serializer/harness/search-style failures retained in v1 evidence and
  registered in `downloadsBatchIncident20260922`. No failure is counted as a pass.

No device testing, historical reporting, backend issuance, publication/payment
activation or Git checkpoint is implied. Preserve the now-approved screen.
