# Store to Buy discovery eligibility - coordinated frontend ticket

Founder approved production-grade Store-to-public mapping and requested a
paste-ready Cursor ticket. This is an existing mapping-gap continuation, not
authorization to merge checkouts, deploy backend or redesign approved screens.

## Verified source evidence

Cursor read-only checkout: MOOLSOCIAL-WORKTREE-CURSOR-buy-ready-20260921,
HEAD 87bc96d4c28300146c9e2c3c3b37c7c3aacffed0 plus ongoing local work.
Recheck current source before implementation; never overwrite Cursor's edits.

- ui_v2/buy/buy_v2_catalogue.dart labels Quick/Scheduled but maps Scheduled to
  BuyV2ShopSaleType.courier. Scheduled is not proof that time-slot booking exists.
- features/buy/buy_v2_session.dart fulfilmentModeFor uses product facts then
  buyV2CatalogueFulfilmentModeFor fallback. Wholesale/Bulk filtering and saved
  filtering use minimumOrder <=2 versus >2. Catalogue fixture matching repeats it.
- features/buy/buy_v2_content_contracts.dart fallback maps every wholesale product
  to bulkFreight, minute text to quickLocal and remaining products to standardCourier.
- Store work_models.dart toBuyPublicFacts also calls that text-derived fallback.
  This provider reader is Codex-owned and remains pending correction together with
  the explicit public contract. Do not claim current Store facts are production-ready.

## Ownership and minimum shared contract

Cursor owns Buy shared/public contracts, filters, query identity, saved products,
Visit Store, product/cart/checkout readers and public regression tests. Codex owns
Store settings, shared catalogue/manual/CSV editor, Store serialization and exact
Store-to-public projection. No simultaneous edits to the same shared contract:
Cursor publishes exact schema/commit handoff, then Codex adapts Store to it.

Reuse/extend existing query, product-facts and commercial-offer contracts. Do not
make duplicate retail/wholesale/bulk catalogues, inventory or screens. Bind data to
Store, SKU/variant/pack, offer/channel, source revision, customer location context,
observed/expiry time and an explicit known/unknown/unavailable eligibility state.
Business type is descriptive, not a supplier grant or verified-manufacturer badge.

1. Store-controlled Retail/Wholesale channel intent and per-SKU offers define
   selling eligibility, not delivery eligibility. Both can use the same stock.
2. Wholesale offer classification must be explicit in the public offer contract;
   MOQ, case size, tiers and pack measurements are separate facts. No arbitrary
   MOQ >2, price or pack-name heuristic. Bulk buying is not bulk freight.
3. Fulfilment modes must come from an authoritative serviceability result using
   Store hours/readiness/capacity, buyer destination and MoolSocial fleet/slots.
   Store does not choose coverage radius, fleet charges or promise a Quick ETA.
4. Resolve Scheduled semantics deliberately: courier availability alone cannot
   promise a customer-selected slot. Extend the existing contract if a scheduled
   slot/service is required; do not silently rename courier into slot support.
5. A SKU can have multiple eligible fulfilment options. Do not force one hard-coded
   mode per SKU if the same offer supports both Quick and Scheduled. Missing or
   stale evidence never becomes an affirmative delivery promise through fallback.

Frontend consumes these results; backend later owns serviceability, discovery
query execution, eligibility authority and checkout revalidation. A Google Maps
place/address supplies location, not eligibility. Do not download national stock
to the phone. Live backend and physical-device acceptance remain separate gates.

## Cursor acceptance

Use the same eligibility result across main Buy, Wholesale, Visit Store, search,
category/filter, saved lists, SKU details, cart and checkout. Keep complete published
Store browsing separate from orderability. Include filter/Store/location/mode and
revision in request/cache identity; ignore stale pages after changing a filter.
Unknown eligibility must not enter an affirmative Quick/Bulk filter or auto-select
a delivery option. Clear/revalidate stale cart delivery choices without losing items.

Tests: same Store with retail+wholesale, each channel off, unchanged SKU/pack/stock,
large MOQ standard wholesale, explicit bulk with low MOQ, same SKU supporting two
delivery modes, closed/full Store, fleet unavailable, changed address/expired
eligibility, absent location, and misleading minute text. Assert main catalogue,
saved, Visit Store and checkout agree. Fixtures must be explicitly test-only, not
production fallback. Hand back exact schema and tested source revision to Codex.

## Current Codex result and remaining work

### Provider offer-classification increment - founder visually approved

Shared catalogue/manual/CSV editor now captures `wholesaleSaleType` with values
`wholesale` (Standard wholesale) and `bulk` (Bulk supply). Stored in
`WorkspaceWholesaleOffer.saleType` using the existing BuyV2WholesaleSaleType enum;
operational snapshot JSON is `wholesaleOffer.saleType`. Do not infer from MOQ or
business type. No Buy shared/public contract file or Cursor checkout was edited.

The same WorkspaceSellingInputs parser owns editor and CSV validation. Template
and field guide inherit the new column from its labels; malformed values identify
the CSV field. Blank import preserves an existing exact offer classification.
Unclassified legacy/new rows may save privately, but Wholesale publication now
reports the missing choice and projects catalogueListing=false. Turning the
wholesale channel off preserves classification/price/tiers for future edits.

Store toBuyPublicFacts no longer calls the text-based fulfilment helper; it leaves
fulfilmentMode absent until authoritative data exists. Cursor must still remove
the consumer-side fallback: this provider change alone is NOT end-to-end resolution.
The public BuyV2Product has no offer-classification field in this checkout yet;
Cursor's agreed contract must expose this Store value without reconstructing it.

Checks: 28 focused model/widget/publication tests, 346 Store atomic tests (four
inherited skips), two real shared-editor save journeys at360px and320px/2x pass;
six-owner analysis clean. Actual renders:
MOOLSOCIAL-POST-UI-AUDIT-20260905/store-offer-classification-v1.
Task evidence: outputs/store-offer-type-v1-{tests,regression,journeys}.log.
Founder approved the displayed added editor choice. Preserve its layout; next
frontend batch is Reports & Downloads. This does not accept pending public-filter
integration, backend eligibility or device behavior. No new route, backend or APK.

Locally implemented Store business type and independent Retail/Wholesale switches
inside existing Business details; no new route. Shared editor already captures
channel, packs, MOQ and tiers. Store preferences round-trip in existing JSON;
old records retain SKU selections until explicit Store preference save. Disabled
channels cannot project as catalogueListing=true; sellerType maps both ways and
does not set manufacturerVerified. Counter Sale/private stock stay unchanged.
25 focused model/widget/publication checks passed, five-owner analysis clean.
Actual local widget renders: task outputs/store-selling-v2, normal and 2x text.

Still pending: shared public schema integration and the explicit source-backed
serviceability adapter, public filter readers, backend eligibility and device replay.
Customer/business Reports & Downloads frontend is still pending and must not be
lost while resolving this prerequisite. No commit/push/APK/OPPO this increment.
