# LF-03 — Product/media producer completeness (Batch 03)

Current direction: founder requested FULL Batch 03, not closure on 03-A. Extend
this same ticket to the existing explicit retail/wholesale/bulk classification
projection and whole supported product/content/media/persistence verification.
No new classification input: reuse selected channel and saved wholesale saleType.
Missing source-held variant IDs, pack/pricing revisions, typed category schemas,
history and optional galleries remain explicit, not invented. Mapping spans all
public modes and Visit Store, while offers/terms/fulfilment execution remains in
the existing later batches. The historical 03-A results below are not full closure.

Founder accepted d5832aae and requested continuation after the complete Store ->
public field map, including Visit Store and non-repetitive owner inputs.

First bounded slice (03-A): optional manufacturer, packer and importer addresses
already supported by Buy but missing from Store. Reuse the saved compliance owner,
catalogue prefill, shared product editor and CSV schema. Capture per product/pack,
not from the selling Store address; do not make optional facts compulsory. Keep
one field-label definition instead of duplicating editor and import schemas.

Preserve old records, explicit clearing, identity/media binding and private Stock.
Keep the retained v1 handoff export unchanged; extend the current typed public
projection and audit. Applicable address fields are descriptive pack facts, not
regulatory verification or live publication.

Run focused failing-before/passing-after persistence/import/projection tests,
existing product/media/handoff regressions and affected Store editor checks.
Load and inspect OPPO without injecting runtime records; distinguish host fixtures,
phone field visibility, actual save/restart and provider acceptance.

Remaining pack/variant/provider mapping decisions stay listed in the calling task's
outputs/store-to-buy-provider-field-map-20261015.md. This slice does not close the
whole map or authorize offers, terms, fulfilment, gallery/video, backend, APK work,
new routes or changes to another tree. Stop for founder OPPO review before advancing.

## Implemented 03-A; founder review pending

Added the three optional addresses to the existing saved compliance record, shared
editor/CSV labels and typed public product. Catalogue matching prefills only actual
matching pack facts; blank CSV preserves matched values (existing import behavior),
while explicitly clearing in the editor removes the value. Old records omit the new
keys. Store/billing addresses are never defaults for these different actors.

Current audit checks the new fields in both directions. Retained v1 export remains
intentionally lossy for these addresses; tests explicitly assert their exclusion.
The current typed product carries them; no backend import/sync is certified.

Host results: 40 product/content/publication/handoff cases, 3 existing responsive
pack-editor cases (360/320px and 200% text), and 2 new 320px normal/200% editor-save
cases passed. The first two new data regressions failed before implementation.
An initial negative CSV assertion expected a row error instead of the existing
whole-file overlong-cell exception; corrected that test, not importer behavior.
Clearing through JSON reload, legacy absence, exact SKU/media preservation and
catalogue/manual-like CSV behavior are host evidence, not runtime user-flow acceptance.
Analysis has no errors/warnings; 8 pre-existing dashboard brace-style infos remain.

OPPO r67.3: hot reload rejected the changed const data class; successful hot restart
loaded source (8251ms), with no APK install/reset. Saved evaluation Store/Stock and
the existing Cart remained available. Opened saved Sunflower oil -> Pack information;
all three blank optional fields are readable, no overlap in the inspected view.
Capture: calling task outputs/lf03-addresses-20261015.png. No field entry or Save tap.
Actual phone address-save/relaunch and live Visit Store/provider readback are pending.
One UI hierarchy dump during menu transition returned null; screenshot/current-screen
readback was used before further navigation. No other app or Settings was operated.

Architect review checked clearing, CSV stability, identity and explicit v1 lossiness.
Only the existing exact LF-03 ticket/owners were admitted; historical policy, registry,
backend, dependency versions and other worktrees are unchanged. No Batch 04 started.

## Full Batch 03 reconciliation — current, not just 03-A

### Supported producer fields and source ownership

| Public field group | Existing Store owner / maintenance | Current disposition |
| --- | --- | --- |
| Store ID/name/type/address/contact/hours | Store settings once, editable later; same branch across public views | Reuse Batch 02; no duplicate entries in each product or Visit Store |
| Product ID/canonical/SKU/barcode/category/brand/title/variant/pack | Shared catalogue/manual/CSV record; once per exact SKU/pack | Supported; preserve identity through save and public consumers; no name joins |
| Pack quantity/unit/case count; retail price/MRP/MOQ/unit-price display | Existing product selling inputs; edit only changes; derive comparable unit price | Supported local facts; no re-entry for Quick/Scheduled/public Store |
| Retail/wholesale/bulk classification | Selected public channel and explicit saved wholesale saleType | Fixed loss in public projection; null legacy saleType remains unknown, not inferred from price/MOQ |
| Manufacturer/packer/importer identities/addresses, origin, consumer care, applicable pack/legal facts | Product source or actual pack; prefill exact catalogue match and edit exceptions | Addresses fixed in 03-A; source names/addresses are not selling Store/billing details or verification |
| Description/highlights/specifications/composition/safety/photo description | Existing product editor and shared CSV parser | Supported; private cost/KYC data excluded, optional text never fabricated |
| Approved exact image, metadata, replacement and missing/failure state | Catalogue/media publisher and exact SKU/pack binding | Existing supported behavior verified; current approved image may refresh same identity, never sibling pack |
| Private image and its storage | Existing private Stock image workflow | Not a public approval; no conversion to public image merely by saving |
| Availability/Stock quantity/threshold | Real receiving/sale/return/adjustment activity | Local source retained; do not manually repeat per public tab or claim server reservation |
| Common return/preferences with product exceptions | Existing Store defaults, explicit product override | Reuse existing ownership; versioned policy/consent execution belongs to Batch 05 |

### Every remaining gap has a named destination

| Gap | Why not silently filled in Batch 03 | Owner / completion condition |
| --- | --- | --- |
| Structured variantAttributes and variant-family revisions/options | No genuine structured option IDs in current Store input; free-text variant is not an ID schema | Catalogue source + minimal category-specific mapping when supplied; existing text variant remains supported |
| Full public packTerms and pricing revision/freshness | Local measure does not supply accepted pack revision, measured-pricing semantics, pricing validity or tax/freight inclusion | Existing Batch 04 commercial/pack mapping with accepted source contract; no fake revision/time |
| Wholesale increment/tier public consumption | Local wholesale increment/tier input exists; public product quantityStep currently defaults to 1 without packTerms | Explicit Batch 04 frontend/contract gap, NOT declared solved or purely a backend issue; preserve MOQ/step/tier in accepted public source before launch |
| Simultaneous independent Wholesale and Bulk terms | Current producer has one wholesale offer with one explicit saleType | Batch 04 model/contract decision; never duplicate Stock or overwrite one channel silently |
| Typed categoryFacts/highlightFields; category-specific size charts | Current text fields are not typed attribute IDs; grocery does not require a universal attribute/chart builder | Applicable trusted catalogue schema; irrelevant optional categories stay excluded |
| Real price history / market signals | Today's edit/MRP cannot establish historical effective prices or regional trends | Authoritative history/market source; remain unavailable, not owner-entry fields |
| Public gallery/video/upload approval | Main catalogue photo and private Stock photo exist, not a live gallery publisher | Optional gallery deferred; native media upload/normalization/review source required if launch scope needs it |
| Supplier and MoolSocial offer publication/benefits/lifecycle | Current Store text offer is not a complete public campaign/discount producer; issuer/funding are separate | Batch 04: supplier scope and inputs, platform-only funding/eligibility; no fake publish or applied saving |
| Versioned agreements, customer-specific credit and final money | Store defaults are preferences, not verified consent/credit/quote/payment | Batch 05 and existing checkout/payment batches; private exceptions stay private |
| Quick/Scheduled/courier/freight/collection readiness, slots, ETA, charges | Classification and hours do not grant serviceability or an available fleet | Batch 06 + platform/logistics/Maps providers; operator Store remains separate; preserve platform-assigned delivery direction |
| Public source revision, Stock freshness, pause/withdraw propagation | Local save is not publication acknowledgement | Batch 07/publication provider, with exact Store/SKU/channel/destination/revision |
| Visit Store address-confirmation provenance | Source audit found product-origin fallback/generic trust-ready badge risk | Batch 07 focused reproduction/correction; no false claim of verified Store location |
| Visit Store Cart-bar scope | Existing bar shows destination/global totals, not necessarily one Store | Batch 07 verify intended label/scope before correction; do not erase other Stores' legitimate Cart lines |
| Customer orders/documents/feedback/analytics | Need buyer events and authoritative operational results, not more repeated product forms | Existing later LF batches; immutable purchased facts and exact review/Store targets |

Visit Store scope includes discovery entry, public Store details/contact/hours/maps,
Store-only catalogue/search/filter/pagination/Saved, exact product/media details,
applicable mode/offers, Ask, Add/Cart/checkout, order/invoice and feedback context.
Explicit Other stores and Compare may cross Stores; isolated catalogue must not.
The detailed historical field-by-field map remains at the calling task's
outputs/store-to-buy-provider-field-map-20261015.md; this disposition updates its
address/classification statuses, not a claim all public providers now exist.

Owner workflow: Store settings once -> catalogue-prefilled or manual/CSV product
once -> explicit product/channel exceptions -> update only changed values at their
source. Stock/order events update their own records. Platform promotions, verified
ratings, payment/settlement and eligibility are never owner-entered 'success'.

### Supported correction and acceptance boundary

New projection uses only the selected shop channel or saved wholesale/bulk saleType.
It grants no delivery choices, verified supplier role or publication acknowledgement.
Retained v1 export stays unchanged; current audit checks expected class and rejects
wrong classes/review-only delivery options. New regression failed with null class,
then passed. Full inventory JSON round trip preserves content, new addresses,
money, pack, exact image metadata and SKU; current-image refresh returns its actual
new revision, while a sibling pack's content remains unavailable.

No phone Stock/invoice/order/payment was injected or created in this continuation.
Host Catalogue/manual/CSV paths and persistence are labelled host evidence. Fresh
physical Catalogue/manual/CSV saves/relaunch and founder review remain distinct
acceptance work, not silently inferred from test fixtures. Public provider readback
and the named later-batch gaps remain pending. Therefore the full connected
Store-to-public MVP is NOT declared complete by this Batch 03 source checkpoint.

### Current verification result

441 distinct selected host tests passed on the changed source: 42 product/content/
publication/handoff; 42 existing ADD product/media/entry/layout cases; 4 LF02/LF03
navigation/editor cases; 7 connected CSV34 cases; 346 public content-contract,
partner/Visit Store catalogue and variant-selection cases. Successful terminal
results read for all five groups. No failures/skips in these selected runs.
Changed model/publication/test analysis: no issues. No rerun of the historical
integration qualification machinery. Two initial Windows .bat regex selectors
were interpreted as shell pipes before tests started; used plain prefixes instead.
Those launcher errors are not test results and no checks were bypassed.

OPPO successfully hot-reloaded 22 libraries in 4830ms. Current screenshot inspected:
calling task outputs/lf03-full-review-20261015.png. Saved Sunflower oil editor's
optional pack addresses remain visible, no new overlap; no data entry or Save tap.
Runtime phone save/relaunch across all three entry methods and founder acceptance
are still pending, not replaced by the 441 host results. No APK or live publication.
Architect closing review found no additional concrete blocker in the supplied
evidence, subject to the successful final test results and these truthful limits.

Supported Batch 03 frontend corrections are checkpointed for review; source-held
fields and named later work remain open. Do not count this as complete acceptance
of all Store-to-public provider flows or proceed to Batch 04 without founder review.

### Physical entry continuation — 15 October 2026

The founder requested continuing the remaining checks. The earlier native-entry
pending status above is superseded for these bounded paths only; source remains
95c19d9b, with no application code change in this continuation.

Actual OPPO UI saves in TEST Store · product entry:

| Path | Saved SKU / product | Quantity | Purchase / selling price |
| --- | --- | --- | --- |
| Catalogue | EVAL-LENTILS-500G / Red lentils, 500 g pouch | 6 | ₹60 / ₹75 |
| Manual | LF03-MAN-CUMIN100 / custom-1792061502317910, 100 g pouch | 4 | ₹70 / ₹90 |
| CSV file picker → review → Save 1 | LF03-CSV-CORI200 / import-1792061788605945-0, 200 g pouch | 8 | ₹40 / ₹55 |

All private/review-only. The existing catalogue evaluation image stayed attached
to the exact lentil pack; manual/CSV correctly showed photo unavailable. Manual
manufacturer address and CSV manufacturer/packer addresses were entered/imported
as explicitly evaluation-only values, then observed unchanged after Flutter hot
restart (3706 ms), navigation back to the same Store, and reopening each product.
All three Stock SKUs, quantities and prices survived. No runtime-storage injection,
invoices/orders/receipts/payments, live publication, backend or APK operations.
No intentional edit/deletion of existing evaluation records or Cart was performed.

Evidence and exact values: calling task outputs/lf03-native-entry-20261015.md,
lf03-three-saved.png, lf03-manual-address-restored.png and
lf03-csv-address-restored.png. CSV fixture was an actual input document selected
through Android Downloads, not a storage seed. System picker Search could not
load content; ordinary Downloads browsing successfully selected the exact CSV.

Hot restart is NOT cold-process/fresh-APK upgrade or backend-sync acceptance.
Nonempty importer-address native save, invoices and exported Sales statements
were not exercised in this bounded product-entry continuation. Host evidence stays
separate; no need to rerun unchanged 441 cases. No new app defect reproduced here.
Founder screenwise approval still required before Batch 04. The source-held and
explicit later-batch gaps above remain open, not silently declared implemented.
