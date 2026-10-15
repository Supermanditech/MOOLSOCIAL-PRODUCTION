# LF-03 — Product/media producer completeness (Batch 03)

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
