# LF-21 — Retailer/Grocery Store enter-once product defaults

MVP-required outcome: recover the three existing new-product defaults (stock
mode, low-stock threshold and customer-listing intent) without re-entry or any
rewrite of saved SKUs. Demonstrate fresh-session loss first. Reuse the existing
Product controls and shared private Store-preference recovery; no new route,
Catalogue, campaign, eligibility or public-publishing engine.

Bounded storage compatibility: read the exact LF20 version1 five-field record
unchanged, without rewriting on read or claiming its absent product defaults
were persisted. Explicit saves upgrade to version2 with the same five fields
plus a separately typed three-field productDefaults sibling. Keep account/Store
scope, strict corrupt-versus-absent handling, actual writer serialization and
confirmed-save/error/retry guards. Either editor must preserve the other group's
latest accepted values, not another editor's unsaved draft. No backward-writer
compatibility or source downgrade claim; older LF20 writers may reject v2.

Resolve recovery before the inline editor or a new Catalogue/manual draft takes
its defaults. Freeze the accepted defaults for each new draft and entire CSV
import, including correction/revalidation; explicit row/draft overrides win and
CSV stays private. Include purchase-assisted new product and unmatched scanner
entry where they consume the same defaults. Existing Stock browse/edit, saved
invoices and Counter operations must remain available during failed recovery.
After async preflight recheck account/Store/visit context. Never retroactively
change retained quantities or grant publication from listing intent.

Tests: legacy v1/no read-write, explicit v2 upgrades from both editors, strict
typing/corruption, failures/retries/interleaving, new session and Store/account/
ABA/newer-input guards. Cover each actual Catalogue/manual/CSV consumer and
existing override rules, not just model round-trip. Native OPPO normal settings
save/source restart and unsaved new-product inspection; no Stock/invoice/order/
payment transaction or runtime seed. Existing real-flow records are retained;
new host fixtures are not native three-path acceptance. Founder overnight work
authority applies; morning acceptance remains pending.

No backend/API/provider action, native dependency, APK/install/release, Cursor/
other tree, push, approved-layout redesign, registry/policy expansion or recovery
framework. Remaining mapped product/channel/offer/checkout/order/feedback/events
requirements do not become complete from this preference slice.

## Implemented checkpoint — morning acceptance pending

Fresh-session host regression reproduced availabilityOnly returning to exact
quantity. The existing encrypted Store-preference key now reads exact LF20v1
without rewriting it and writes explicitv2 on a confirmed owner Save. Product
defaults have strict enum/int/bool decoding and separate saved-status evidence:
v1's five saved fields do not claim its absent product settings are device-saved.
Either editor preserves the other group's accepted inputs; busy writes reject
interleaved edits and failed writes retain inputs/retry. No new key or recovery
framework. Downgrading to an LF20-only writer is not qualified.

Inline controls initialize after the same scoped load; new-entry-only loading
delays the cached Catalogue/manual page until defaults are checked. Each entry
visit and whole CSV import/correction freezes its accepted defaults. Explicit
row/editor choices win. Purchase-assisted creation and new scanner results join
the scoped preflight; existing-owned edits bypass it. Saved Stock is never
retroactively changed. The global Apply action also reflects shared write busy
state instead of silently ignoring taps during a Product controls save.

106 settings/model checks passed, including17 LF21 migration/type/interleaving/
recovery cases;23 neighbouring publication/settings-widget cases and24 legacy
Product-controls/settings/Stock-entry-discard cases passed. Six new full-editor/
consumer cases pass: normal/200% failure/retry, delayed Catalogue/manual recovery,
frozen overrides, actual CSV correction and host Stock Save with frozen17 versus
explicit2 and CSV provenance, plus failed-load Back to unchanged existing Stock.
The relevant8 LF20/LF21 cases passed again after the shared Apply busy predicate.
Focused analysis:0errors/warnings,9 unchanged unrelated style infos.

Candidate failures were corrected and are not counted as passes: two nullable
accesses, missing existing test-widget import, one-frame navigation inspection,
dereferencing the review's immutable original invalid row after correction, and
assuming a one-product standard host fixture. The final tests keep exact saved
data/default/override/provenance and hit-test/accessibility assertions. Architect
context review supports the bounded checkpoint once native evidence is recorded.

OPPO actual evaluation Product controls saved low-stock13 with Keep stock count
enabled and Offer to customers disabled; device-save caption confirmed. Source
restart3218ms, then Work/Workspace -> Stock -> Add products -> Add manually BEFORE
Settings: unsaved manual draft showed stock quantity0, low-stock13 and public
visibility unchecked/private until review. No product or invoice was saved. Back
to Catalogue then Stock, then Store overview still showed29550 purchase cost,
18low/24available/6unavailable. Cart1item₹164 was observed after restart.
Reopening Settings retained21:30/05:15/Unlimited and the three product defaults.
Task screenshots lf21-defaults-saved-20261016.png,
lf21-manual-inherited-20261016.png and lf21-defaults-restored-20261016.png.
Native evidence is manual-entry/input recovery only, not new native Catalogue/
CSV saves, physical scanner/OCR, server sync, new-APK or native failure/account
switch acceptance. No native commerce/Stock mutation or runtime injection.

All original mapped dependencies remain explicit. No founder acceptance, push,
backend connection, public publication, eligibility or full frontend/MVP closure
is claimed. A separate observed empty-title photo accessibility label belongs to
the existing product/image follow-up; no unowned thumbnail widget was edited here.
