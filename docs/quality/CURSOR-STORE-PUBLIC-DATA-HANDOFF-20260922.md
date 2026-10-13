# Store-origin data for Cursor public-side testing

## Current priority: Store/public filter eligibility contract

Provider increment now implemented locally: editor/CSV `wholesaleSaleType` stores
`WorkspaceWholesaleOffer.saleType` (existing BuyV2WholesaleSaleType.wholesale/bulk)
and serializes as `wholesaleOffer.saleType`. Null legacy values stay private until
classified; no MOQ inference. Store facts now leave fulfilmentMode absent instead
of deriving it from text. Consume this exact offer value in Cursor's shared public
contract and remove the public fallback; do not infer eligibility from absence.
Full checks, captures and pending frontend/backend boundaries are in the handoff.

Founder requested coordinated production-grade Quick/Scheduled/Wholesale/Bulk
mapping. Read STORE-PUBLIC-FILTER-ELIGIBILITY-HANDOFF-20260922.md for exact source
findings, ownership, contract and acceptance tests. Cursor owns public contract
changes; Codex consumes the handed-off contract in Store. No cross-checkout writes.
Local Store business type and Retail/Wholesale switches are implemented/tested,
not committed or device accepted. Fulfilment and wholesale/bulk classification
still require the shared contract; do not reuse delivery-text/MOQ heuristics.
Downloads frontend remains queued; PDF formats remain founder-approved.

## Shared invoice format contract - consumer wiring still pending

Founder requires the three reference invoice/document types wherever applicable
across Buy, Wholesale, Store and MoolSocial, available through the correct party's
Download Centre and existing contextual invoice entry. Reuse these new shared
owners after approved integration, rather than copying Work presentation:

- apps/mobile/lib/shared/commerce/commerce_invoice_document.dart:
  CommerceInvoiceDocumentDetails, explicit issuerRole/recipientRole, format,
  account/store/order/invoice/document/source IDs and immutable supplied lines.
- apps/mobile/lib/shared/commerce/commerce_invoice_pdf.dart:
  renderCommerceInvoicePdf; review-only renderer, no backend fetch or issuance.
- test/commerce_invoice_pdf_test.dart: fictional seller/customer, supplier/retailer,
  platform/customer and platform/retailer examples plus financial rejection checks.

Every monetary input is INTEGER MINOR UNITS. Public Buy's existing tax-line fields
must be checked individually for whole-rupee versus minor-unit representation;
convert once in the adapter, never guess from a field name. Confirm current Cursor
contracts at integration time. Tax breakdown, fees, supplier identity and recipient
must come from the matching immutable document, not another party's order or current
Store Settings. No automatic retailer commission disclosure to customers.

This increment only wires Work's existing local review source. Public adapters and
role-scoped Download Centre UI are pending frontend work. Backend must authenticate
document access and establish actual issuance/payment records; client scope checks
are not security enforcement. No new issued-document claim or automatic messaging.
Full requirement/status: STORE-INVOICE-FORMAT-REFERENCES-20260922.md. Source branch
work/codex-ui/add-product-screen1-20260920 remains at e9243d46 with local uncommitted
changes. Cursor's active Buy checkout was not modified or merged.

## Invoice seller snapshot increment — local only

WorkspaceCustomerInvoice.seller now carries issue-time storeId,legalName,
storeAddress,billingAddress. invoiceAddress selects supplied billingAddress or
physical Store address. Existing Store invoice/PDF readers use it, while legacy
invoices keep seller=null; do not hydrate historical invoices from current Settings.
Public Buy's authoritative tax/invoice contract still needs adaptation and verified
issuance; this local snapshot does not claim that connection. Never copy private
bank/settlement data or treat account onboarding GST as branch-verified registration.
370 regression tests plus9 invoice journey checks pass;4 inherited skips. Cursor's
checkout untouched. Local review: task outputs/STORE-INVOICE-SELLER-REVIEW.md.

## Current content increment — founder visually approved, 22 September

Description/highlights/specifications are NOT BuyV2Product fields; they belong to
BuyV2ProductContentSnapshot. Store now supplies them from WorkspaceCatalogueItem.content
through toBuyPublicContent and WorkspacePublicContentAdapter. Adapter rejects wrong
Store/SKU/canonical/variant/pack/title/brand/category; no generic copy fallback.
Existing guarded workspace-public router injects it and includes content in cache
identity; publication blocking remains unchanged. This is not live discovery proof.

Catalogue/manual/CSV use the same parser/editor fields. Optional columns description,
highlights (one per line),specifications (Name: value per line) retain exact catalogue
prefill when blank on import. CSV multiline cells must be quoted. Editor can explicitly
clear optional content. New/changed copy remains under catalogue review, not silently
approved. Media continues through existing approved exact-pack binding.

The eight generated test cases now include publicContent from the actual projection,
alongside the33-property public product projections. Fixture copy is test-only;
sourceId is not an authoritative publication acknowledgement. Private customer terms,
purchase cost and settlement details are not content fields. Nine public content
snapshot fields have source ownership and a source-coverage regression test.

Remaining: authoritative source revision/timestamp, persistence/restore, approval,
live Store publication/content delivery and public/device replay after integration.
Customer preview remains removed. Cursor's current checkout was not changed.

## Latest: payment TERMS replace retailer payment-method selection

Founder correction/visual approval,22 September: keep approved address and returns
layouts. Payment provider/method chips are removed from Store preference UI.
Retail is full advance through MoolSocial; payment rail selection is checkout's
separate concern. Do not copy these deleted chips into public Store/SKU pages.

Store-owned wholesale defaults and private customer overrides now use the exact
BuyV2CommercialPaymentTermKind vocabulary: wholesaleAdvance,
bookingBalanceBeforeDispatch, bookingBalanceOnDelivery, paymentOnDelivery,
supplierCredit. Advance percentage and net days are captured where applicable.
Lender/regulatedCredit cannot be created by the retailer. Older method fields are
retained for compatibility but are not the retailer's commercial-term settings.

Provider: WorkspaceStorePublicationDetails.wholesalePaymentTerms and private
customerPaymentTerms; paymentTermsFor(channel,customerId) returns preference
inputs only. Retail ignores wholesale overrides. Missing override inherits defaults;
an explicit empty override permits none. Restore Store defaults removes the override.
Existing Customers > customer details embeds the same editor; no parallel route.
Saved Store/customer checks reject stale Store and unknown local customer IDs.

Backend/integration contract, still deferred: resolve local customer IDs to verified
buyer/Store relationships; authenticate the owner and enforce eligibility/constraints;
map the exact kind/advancePercent/netDays to checkout's existing terms adapter.
Only that authoritative response supplies sourceId,term ID,fulfilmentKey, amounts
due now/balance, quote revision and order snapshot. Do not publish the override map
to other customers or include it in product/catalogue payloads. Current frontend
preferences do not grant credit, activate a provider or alter any existing invoice.
Live public adapter wiring and order snapshot confirmation remain untested/pending.

The sections below record prior increments; accepted-method preference UI descriptions
are superseded by this correction. Address/return contracts remain unchanged.

## Address alignment with Cursor's current work, 22 September

Founder provided Cursor's running update and authorized reading it to implement
provider dependencies within Codex's existing batches. Read-only source inspected:
`apps/mobile/lib/ui_v2/buy/buy_v2_store_address.dart`, SHA256
`36D926CADF3B5F7988B48C300F3BC128E056E8322BFE47470D36A01DEF989F91`.
Cursor's uncommitted control consumes Store ID/name/address and launches an encoded
Google Maps address search on tap. It does NOT require coordinates or a place ID.
Do not duplicate this control or block it on a new exact-pin feature. An address
search is not verification of the exact map location. No browsing-area place ID
is substituted for the Store's physical address.

Provider owner: `WorkSession.workspacePublicStoreDetails`, projected from the
active workspace's ID/name/locality and `workspacePublicationDetails.address`.
One-time street/building, city, state and PIN are captured inside Store Settings.
The session checks Store identity on apply and preserves separate Store records.
This is a frontend projection, not a live publication acknowledgement. Authenticated
Store publication/readback into Cursor's live Store source remains backend-dependent.

One-time return summary/window/conditions/remedies now map to product protection
for Shop and Wholesale when no per-product override exists. Override summaries
do not inherit contradictory defaults. Accepted-method preferences are allowlisted
and intersect provider-supported and customer-supported methods. Live activation,
commercial payment timing/credit terms, region resolution and checkout authority
are NOT inferred from these inputs. Banking/verification data is not public product data.

Founder request: Cursor needs provider data/metadata from Store to test Buy,
Wholesale, Visit Store and their product/checkout journeys. Share the actual
Store contract and test projections; do not create independent public sample
values that hide missing provider inputs. Backend development remains deferred.

## Source and status

Founder visually approved the new shared Pack quantity & selling channels screen
on 22 September 2026. Preserve its layout across catalogue/manual/CSV review.
Remaining field mapping and public consumption gaps below are still open; visual
approval is not end-to-end publication or backend acceptance.

- Codex source: `work/codex-ui/add-product-screen1-20260920`, base HEAD
  `e9243d4644749c4fe805052b41b4a225f41e5d91`; this mapping increment is uncommitted.
- Integrated reference: `f27c09e147569e49e0e2881eb66adde3c292586f`.
- Cursor read-only reference: `work/cursor-ui/buy-ready-20260921`, HEAD
  `87bc96d4c28300146c9e2c3c3b37c7c3aacffed0`. Its current dirty UI was inspected,
  not merged or approved as an integration baseline. Exact inspected file hashes
  are in `store-public-field-register-v1.json`. They were rechecked unchanged.
- No Cursor files were changed. This document is a handoff to read, not authority
  to overwrite Cursor's worktree or merge uncommitted Codex changes.

## Read these together

1. `store-public-field-register-v1.json`: 400 unique historical field IDs, owners,
   one-time/per-product/order distinction and frontend/backend responsibilities.
   Inventory coverage is NOT runtime completion; audit-required rows remain open.
2. `store-public-test-handoff-v1.json`: generated through the real Store product
   projection, not handwritten public product values. Test-only; no Store is live.
3. `apps/mobile/test/fixtures/store_public_handoff_v1.dart`: reusable fixture owner.
4. `apps/mobile/test/work_public_handoff_test.dart` and `work_publication_test.dart`:
   mapping, exact identity, photo binding, failure, quantity and CSV checks.
5. `apps/mobile/lib/features/work/work_publication_data.dart`: shared selling
   input parser, structured quantity, Wholesale offer and one-time detail model.

The JSON is a test/review transport, NOT the production API schema. Cursor can
inspect it now. Consume the shared Dart fixtures after coordinated source
integration; do not copy production Store models into Buy or add release fixtures.

## Responsibility matrix

| Information | Provider owner | Public consumer / rule |
| --- | --- | --- |
| Store ID, name, full address, resolved region, contact, business identity | Existing Store identity + one-time Business details | Visit Store and seller/invoice identity; join on ID, never display name |
| Exact canonical product, SKU, variant, pack, barcode, category | Shared catalogue/editor; same CSV mapping | Buy and Wholesale discovery, full SKU page, cart and invoice retain exact identity |
| Approved photo source, revision, file metadata, exact pack binding | MoolSocial catalogue; retailer may request changes | Same photo at different render sizes; missing/wrong pack must not silently show an old asset |
| Retail price, Wholesale price/MOQ/increment/tiers | Per-product shared editor or CSV | Channel-specific offer; both reference the same stock, not two inventories |
| Structured quantity and case units | Exact catalogue prefill or per-product editor/CSV | Unit comparison uses kg/L/count and thousandths; never parse a pack label into identity |
| Description, highlights, specifications, product facts | Catalogue or applicable per-product fields | Complete content-source mapping still needs reconciliation; do not fill with invented copy |
| Accepted payment methods and trade/return terms | One-time Store/channel setup, product override only where applicable | Intersect Store acceptance with live provider capabilities and selected fulfilment |
| Pickup preference | Store setting | Off stays off even with an address; source freshness and Store identity matter |
| Delivery serviceability, charges, promise | MoolSocial fleet/backend for buyer destination | Store does not set delivery radius/fee; browsing location alone is not deliverability |
| Verification, supplier grant, publication acknowledgement | Verified backend/service response | Never retailer-edit or infer from a filled field; no fabricated verified/paid state |
| Reservation, final quote, payment result, order/invoice, delivery status | Backend transaction/service response | Revalidate at checkout; preserve IDs/revisions through payment and delivery |
| Purchase price, low-stock threshold, bank settlement details | Private Store/accounting settings | Not public product fields; do not expose in public fixtures or customer pages |

Product prices currently use whole INR rupees; comparison tiers use INR minor
units. Convert explicitly by 100. Fractional-rupee selling prices remain unsupported
by the legacy product model; never silently truncate them. Quantities are selling
packs, with base quantity in thousandths. Minimum + n × increment is the allowed
Wholesale quantity rule. `unitsPerCase` does not multiply stock a second time.

## Test pack and Cursor acceptance

Eight Store-origin cases: retail/Wholesale, different pack, another Store with
the same display name, private stock, zero stock, Wholesale-only, replaced photo
and missing photo. Each contains scoped stock input, both channel projections,
and explicit non-live order/publication state. All stored BuyV2Product properties
are represented; backend-owned nullable values remain unavailable, not fabricated.
URLs under `example.invalid` intentionally cannot fetch real photos. This pack
tests binding/metadata, not visual image rendering or backend approval.

Replay after integration using the public screens Cursor owns:

1. Store stock → public projection: identity, pack, description/facts, price, MRP,
   unit price, media and channel availability match, including empty/invalid data.
2. Main Buy and Visit Store reference the same retail offer. Wholesale uses the
   selected channel terms and the same underlying stock. Do not copy stock.
3. Variant/pack change updates price, quantity and exact photo together. Same-name
   Stores remain separate. A revision change invalidates stale media/quotes.
4. Private and unacknowledged products stay out of live discovery. Out-of-stock
   browsing and orderability are separate; being visible does not permit checkout.
5. Cart quantity respects MOQ/step/available stock; tier pricing never leaks to
   retail or another Store. A fresh quote is required for a changed quantity.
6. Payment choices are Store/channel/fulfilment/provider intersection, not every
   rail in Buy's existing default list. Buyer contact and settlement credentials
   are not catalogue properties. Paid state requires confirmation, not a tap.
7. Test pickup Off, wrong-Store capability and expired capability. Test unavailable
   location/fleet response, offline/error/stale quotes and rejected publication
   via clearly test-only injected service responses, not release fallback data.
8. Query/page identity includes region, Store, channel, filters and snapshot;
   do not mix cursors or download a nationwide catalogue onto the phone.

## Confirmed cross-side mismatch — resolve before acceptance

`BuyV2StoreListing.hasCollectionAddress` and
`BuyV2CollectionBasket.collectionAvailableAt` in Cursor's latest reference allow
collection based on non-empty ID/name/address alone. Store still offers pickup
Off. An address-only check therefore ignores that setting and capability expiry.
The handoff test exercises pickup Off, wrong Store and expired capability with a
valid address. This is NOT marked fixed in Cursor; do not alter test data to pass
the address-only behaviour. Preserve explicit Store preference and service scope.

## Remaining frontend vs backend — not hidden behind publication blocking

Frontend still needs: resolved location wiring; commercial payment timing/credit
terms; dispatch/invoice consumer wiring; complete content/highlight/specification
source mapping; case-identity and Wholesale discovery/comparison reader wiring;
authoritative restore adapter integration; remaining per-field reconciliation.
Current batch supplies inline address/legal/return/dispatch input capture, payment
allowlists/intersection and return-policy projection. It does not supply live
publication, payment activation or backend-enforced eligibility.

Current increment supplies structured quantity/channel/Wholesale parser, CSV columns,
shared editor capture and product projections. This is not full Store-to-checkout
completion. Existing local route remains guarded, so passing a projection test does
not prove the current public UI consumes these inputs end-to-end.

Backend later: authenticate/authorize Store writes, exact catalogue/image approvals,
location-to-region resolution, acknowledged publication, indexed/paginated discovery,
fleet serviceability/quotes, grants, durable state, atomic reservations, payment
confirmation, invoices, delivery tracking, settlement and report histories. Backend
rules must validate the same contract; frontend checks are not trust enforcement.

## Reproduce locally

From `apps/mobile`, run `test/work_store_publication_settings_test.dart`,
`test/work_public_handoff_test.dart` and
`test/work_publication_test.dart`. The handoff test compares committed/exported JSON
with a freshly generated projection. `--dart-define=EMIT_STORE_HANDOFF=true` emits
the regenerated payload for a reviewed artifact update; never bypass other tests.
Shared-editor widget cases use name `PROVIDER-MAP` in
`test/work_workspace_layout_safety_test.dart` (360px and 320px/2× text).

No backend, live publication/payment, APK, OPPO, commit or push is claimed here.
