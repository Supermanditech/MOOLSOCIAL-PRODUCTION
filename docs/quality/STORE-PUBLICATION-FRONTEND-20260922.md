# Store publication contract and Product controls — bounded frontend work

## Invoice reference-format batch - founder approved

22 September: shared commerce document contract/renderer now implements seller,
platform-fee and summary reference structures. Work's existing review PDF source
uses it; approved app screens stay unchanged. Explicit issuer/recipient roles,
integer minor-unit reconciliation, immutable input collections, exact Store/account
scope and payment/tax distinctions are tested. Final actual PDFs visually inspected
with the PDF skill: three primary samples, platform-retailer commission, 50-line
wholesale, large amounts and long identity. Totals/payment kept together using an
explicit non-spanning wrapper after an orphan-page regression was caught.

376 broad tests passed with four inherited skips; nine invoice journeys passed;
final focused 22 tests and five-owner analysis pass. Evidence and pending Download
Centre frontend scope: STORE-INVOICE-FORMAT-REFERENCES-20260922.md and task
outputs/COMMERCE-INVOICE-FORMATS-REVIEW.md. PDFs are fictional review-only, not issued.
Buy/Wholesale consumer adapters, role-scoped Download Centre and backend issuance
are NOT complete. Cursor unchanged; no commit/push, APK or OPPO test. Founder has
approved all three v5 PDFs; next frontend batch is scoped Download Centre wiring.
Do not reopen approved screens or invoice formats.

## Invoice seller identity — screen approved; PDF reference format pending

Founder approved the invoice screen on 22 September but requires document formats
to follow three supplied references. Mandatory continuation record:
[Invoice-format requirements](STORE-INVOICE-FORMAT-REFERENCES-20260922.md).
It distinguishes platform-fee invoice, seller invoice and order summary/receipt.
Do not treat the current review PDF as the approved final document format.

22 September: new local invoices freeze Store ID, legal name, physical address
and optional registered/billing address from the active Store's saved one-time
details. Invoice address uses billing address when supplied, otherwise physical
address. Existing invoice details and review PDF use this snapshot; no new page.
Ledger/operational serialization and copyWith retain it. Historical invoices
without it remain absent; later settings edits cannot rewrite issued snapshots.
Review PDF rejects a mismatched Store ID and checks font support for seller text.
No PAN, bank details or unscoped onboarding GST registration is copied.

370 regression tests passed, four inherited skips; nine Cash/Bank/UPI connected
checks passed at 1x/1.4x/2x. Seven-owner analysis and scoped whitespace checks clean.
Actual single-page and six-page PDFs rendered/inspected via the PDF skill. Current
host screen captures: invoice-seller-v2; task review outputs/STORE-INVOICE-SELLER-REVIEW.md.
One legacy listing test expected an incomplete fixture to publish; corrected to
assert preserved listing intent AND blocked publication before/after Counter Sale.
No production publication guard was relaxed. Initial capture command error and
failed wider run retained in evidence/regression record.

This is NOT tax-invoice completeness, verified seller identity, authoritative
issuance or public Buy invoice delivery. GST/signatory/tax snapshot integration,
backend issuance/persistence/delivery and fresh OPPO remain pending. Product content
was founder-approved before this batch. No commit/push, APK or Cursor mutation.

## Public product content — founder approved, 22 September

22 September: next frontend-only dependency is description/highlights/specifications,
which Buy reads from ProductContentSnapshot rather than its product listing model.
Implemented optional fields in existing shared product editor, the same CSV parser
and template, Store snapshot encoding, exact identity-scoped public content adapter,
and guarded router cache/injection. Blank import cells inherit exact catalogue copy;
editor clearing is explicit. Invalid specification lines identify the affected field;
modified catalogue content retains a review hold. No public preview or new route.

34 final model/contract checks passed. Connected shared editor validation/private
save passed at360px and320px/2x;10 existing affected Settings/editor checks passed
in the preceding combined run. Initial harness stopped on required purchase price,
not the new content error; corrected and retained failed evidence. Current captures:
store-product-content-v2. Four content field-register rows and all9 content-snapshot
field dispositions reconciled;400 original register IDs preserved. Cursor's eight
test cases regenerated with actual content projections.

Founder approved the extended Details customers may need section. Previously
approved address/returns/payment/quantity layouts preserved. Backend/live publication,
region resolution, commercial quote/invoice/dispatch reader integration and durable
restore remain pending; this is not100% end-to-end completion. No commit/push/APK/OPPO.

## Latest: founder-approved payment terms revision

22 September founder visually approved the revised payment screen and preserved
approval of address/invoicing and return layouts. Replace provider/method chips
with retail full advance through MoolSocial and one/more wholesale terms matching
Buy checkout. Shared StorePaymentTermsEditor serves both defaults and the existing
customer details. Private customer overrides support explicit reset to defaults;
retail remains unchanged. No lender-credit creation or automatic relationship scoring.

WorkspacePaymentTerm validates canonical kind/advancePercent/netDays. Session saves
remain Store scoped; customer save rejects unknown customer/stale Store. Serialization
retains immutable selections; no public product payload contains customer overrides.
Wholesale publication requires default terms, not a selected gateway. Backend
acknowledgement and remaining publication checks stay intact. Old method fields are
retained for compatibility, not exposed in this UI or substituted for term eligibility.

Thirty model/contract tests and thirteen affected widget checks passed; focused
v2 rerun/captures tracked in task outputs/store-payment-terms-v2-tests.log.
No backend, live checkout adaptation, APK, OPPO, commit or push. Frontend eligibility
preferences are not backend-authorised grants. See Cursor handoff's latest section
for exact customer identity, quote and order-snapshot responsibilities still pending.

Earlier statements about awaiting this batch's visual approval are superseded.

## Current batch — one-time Store inputs and Cursor address alignment

22 September: founder supplied Cursor's address/Maps implementation and authorized
provider dependencies inside the existing batches. Cursor remains read-only;
Redmi/public UI belong to Cursor. No duplicated Maps control or exact-pin input.

Implemented locally inside existing Settings > Business details: collapsible
address/invoicing and payment/return preferences. City/state and PIN/signatory
pair at normal width; enlarged text stacks. Street and terms wrap as needed.
Active Store ID/name/full address project through workspacePublicStoreDetails,
matching Cursor's BuyV2StoreListing inputs. Address changes invalidate the old
resolved location. This projection does not publish or bypass backend confirmation.

Store return summary/window/conditions/remedies inherit into both channel product
projections unless overridden. Allowlisted accepted methods intersect provider and
customer capabilities; this is preference capture, not payment activation. Changes
preserve stock and visibility and reject a changed Store identity. Snapshot encoding
and decoding exist; authoritative restart/cross-device restore is NOT complete.

Local checks: 28 model/contract tests; 2 connected new Settings tests at360px/1x
and320px/2x; 9 affected existing Settings/editor tests. Eleven-owner analysis clean.
v6 actual Flutter renders inspected: store-one-time-settings-v6 in the external
MOOLSOCIAL-POST-UI-AUDIT-20260905 evidence directory. Earlier failed captures retained.
Nested PageStorage regression recorded; no APK/OPPO/commit/push this batch.

17 Store/return register rows updated with scoped evidence, preserving all400 IDs.
Remaining FRONTEND: location-source integration, commercial payment timing/credit,
complete content/specification mapping, invoice/dispatch/public reader integration
and authoritative restore adapter. Backend: publication/readback, verification,
provider activation and transactions. Neither inventory coverage nor passing local
tests means full publication completion. Stop for founder visual approval.

The following sections describe preceding increments, not the latest status.

## Latest increment — Store-origin Cursor data, 22 September

Founder approved the preceding screens and requested complete public-side mapping,
including data/metadata for Cursor to test directly from Store. Current handoff:
`CURSOR-STORE-PUBLIC-DATA-HANDOFF-20260922.md`, generated
`store-public-test-handoff-v1.json`, and `store-public-field-register-v1.json`.
Cursor's latest committed and dirty references were read-only compared; no merge
or Cursor mutation occurred. The pickup/address-only semantic mismatch is recorded.

This increment implements structured quantity and explicit Wholesale terms in the
shared model/parser, CSV and collapsible shared editor, with product projections
for both channels. It adds 8 test-only Store-origin cases with all 33 current public
product properties, including exact media metadata/bindings and negative states.
Private costs/settlement data stay out of public product payloads. CSV never publishes.

Full 400-field runtime mapping remains unfinished. Address/region capture, structured
commercial/return terms, content specification sources, public comparison/checkout
consumers and durable restore are still explicit frontend work, not merely backend
dependencies. Publication confirmation and transactional services remain deferred.
The older status below describes the preceding accepted increment, not completion.

Final focused contract tests: 22 passed. Final shared-editor/defaults checks: 6
passed. Eight-owner focused analysis and scoped whitespace check: clean.
Earlier combined gateway/contract pass: 259 (overlaps, before final parser edge fix).
Current shared-editor captures: `store-provider-map-v2`, 360px and 320px/2x text.
Founder visually approved the Pack quantity & selling channels screen on
22 September 2026 ("SCREEN APPROVED"). Preserve this layout. This approves the
shown screen, not completion of all mapping, backend or device testing.
Changes remain local/uncommitted; no new APK, backend or OPPO acceptance.

Local implementation/test corrections retained: parser used an undefined row name
(corrected to the existing trimmed record); new inventory test read `fields` instead
of actual `entries`; widget fixture initially assumed hidden Store and kept text focus
while scrolling; final tests preserve initial visibility and unfocus before navigation.
Blank CSV tier columns now inherit existing tiers; explicit editor clearing removes
them. Invalid prices return publication issues rather than throwing during conversion.

Founder approved 22 September 2026: published Store products feed both Visit Store
and relevant Buy/Wholesale discovery. One inventory; no duplicate upload, copied
customer screens or customer-preview route. Business details stays inline Settings.

## Approved distribution, not implemented backend

- Visit Store: complete published branch catalogue, paginated; exclude private
  stock/drafts. Browsing and orderability are separate.
- Buy: retail offers eligible for selected customer location; publication grants
  discovery eligibility, not guaranteed first-page placement.
- Wholesale: explicit wholesale prices/packs/MOQ/trade terms, never inferred from
  retail. Both offer types reference the same inventory.
- Preserve Store ID, exact SKU/variant/pack and photo revision across entry points.
- Maps resolves location; backend owns publication acknowledgement, discovery,
  ranking and region/service-area queries. Fleet owns biker/bulk coverage/charges,
  not the retailer. Frontend uses existing Buy catalogue query/page contracts.
- Nationwide inventory is never downloaded to a phone for local filtering.
  Million-Store capacity is a backend load-test target, not frontend acceptance.
- Checkout must revalidate current price, stock and fulfilment eligibility.

## Current local changes (not publication completion)

The publication contract enumerates public product/Store property ownership and
compares supported source/public values in both directions, including pack facts
and exact photo binding/revision. Missing/invalid product details, missing approved
photos, mismatches and unsupported Wholesale projection produce issues.
Store visibility and retailer setup cannot publish while requirements are unmet.
The local workspaceProduct deep link cannot bypass these checks or expose demo
fallback stock. No automatic payment acceptance is inferred from a product.

Full address/region, inherited payment/delivery/return/invoice terms, structured
unit-price/pack quantities and Wholesale selling terms remain unfinished frontend
mappings. Backend publication confirmation remains deferred. The report therefore
fails closed; it is NOT a claim that those mappings are implemented. Store stock
and Counter Sale remain independent of public discovery eligibility.

## AP-OPPO-032 bounded next batch: Product controls

Inline collapsible Product controls replaces the misleading Settings-to-Stock tap.
Store-scoped defaults: count-based versus availability-only stock, low-stock count,
and customer-listing intent for new products. Catalogue/manual drafts inherit the
defaults; CSV inherits omitted tracking/threshold values, honours explicit values
and always remains private. Shared product review permits per-product low-stock
and applicable visibility overrides. Existing records are never bulk-modified.
Changing defaults does not publish the Store or any product.

Preferences use the existing Store operational state and snapshot boundary.
Authoritative restore/cross-device persistence is NOT implemented or accepted;
follow the existing backend deferral. UI confirms only 'Defaults applied'.
Local-session changes are not evidence of persistence after process death.

## Review boundary

Preserve founder-approved 64px unboxed thumbnails and previously approved layouts.
No backend, APK, OPPO, commit/push or independent Cursor changes in this work.
Await founder approval of changed Settings/shared-editor states before advancing.
Local evidence and test logs are retained in the task outputs directory; host
renders are not physical OPPO proof. Source checkpoint remains e9243d46 until a
separately authorized Git checkpoint; this document and code are uncommitted.

Final local checks: 250 gateway/model tests passed; 66 affected journey checks
passed (one inherited skip); final focused pass 22; final capture/interaction pass
4. These counts overlap. Eight-owner analysis and scoped whitespace check clean.
Final host renders: MOOLSOCIAL-POST-UI-AUDIT-20260905/store-product-defaults-publication-v6.
Task review: outputs/STORE-PUBLICATION-DEFAULTS-REVIEW.md. Await founder feedback.
