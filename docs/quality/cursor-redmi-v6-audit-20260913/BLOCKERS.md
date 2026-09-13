# V6 Redmi audit coverage blockers

These are unavailable qualification prerequisites, not closed tickets or automatic product defects. Independent reachable UI testing continues.

## B-001 — authoritative Shopping area search

Observed on matching V6 Redmi APK: numeric query in Shopping area returns “Area search is unavailable right now. Try again shortly.” Retry preserves that state. Evidence 004–006; AREA-002/003. Safe dismissal works. Successful locality/PIN lookup, provider-selected location identity, serviceability and recovery after actual provider restoration remain unverified. Do not substitute the static city list for authoritative nationwide lookup. Owner boundary: location provider and its Buy adapter; exact binding investigation pending.

## B-002 — populated supplier comparison

Turmeric powder 97 / 200 g pack opens Compare prices with the correct identity, but reports other supplier prices unavailable; Refresh comparison preserves this state. Evidence 016–017. `buy_v2_views.dart` `_ProductComparisonSheetState._reload` (line 1677 onward) returns this unavailable state when `session.comparisonSource` or the exact comparison query is missing. The session declares an optional comparison source; determine this artifact's concrete binding before treating it as a service outage.

Blocked descendants: supplier-result cards, price and delivery winner correctness, same-product/variant/pack/quantity eligibility, quantity changes, direct Add and cart retention from comparison, stale-offer refresh, scheduled-slot comparisons, procurement-specific comparison eligibility. The empty/unavailable UI is testable, but none of those positive-result branches is passed. No app code or runtime state will be injected to fabricate the missing authority under this audit goal.

## B-003 — eligible purchase for this product review

Turmeric powder 97 has no eligible delivered purchase in the current review state. Write review and Check again show the explicit eligibility message, evidence 013–014. Positive rating/comment/submission paths for this SKU remain unverified. Existing eligible fixture products may provide independent safe coverage; that search remains pending. Real purchases and public review submission are excluded.

## B-004 — Bulk checkout delivery estimate

Rice 4 / five 25 kg packs reaches Confirm order with retained Work address and ₹8150 after the ₹300 coupon. Delivery is unavailable; Check delivery returns explicit unavailable feedback (088–089). The button is wired to session.refreshCheckoutDeliveryEstimates in buy_v2_views.dart near 7252. Successful authoritative estimate, recovery after provider availability and subsequent eligible order placement are not qualified. Exact runtime provider binding remains to be traced; this is not proof of a service outage or a new customer-facing implementation defect. No order/payment was submitted. Other checkout controls and Back remain independently testable.

## B-005 — live order tracking refresh

MS-NEW-09 opens with last-known preparation status and no live delivery updates. Refresh shows Order updates are unavailable and labels the retained estimate update unavailable (111–112). Positive provider recovery, changing courier/location/ETA and terminal-state transitions are not qualified. Recorded-order UI and safe nested navigation remain testable. No order state was changed and no contact or message sent. Runtime source binding and safe fixture alternatives remain to be reconciled before final coverage disposition.

## B-006 — delivered-item resolution eligibility

For delivered Shop MS-240741, Return/Replacement/Refund each shows no confirmed eligible items. All eight purchased product rows remain visible with eligibility unavailable and disabled checkboxes; Check eligibility again in Refund preserves unavailable state (156–160). No request submitted. Positive selection quantities reasons evidence attachments and accepted/rejected resolution execution cannot be qualified from this state. Other eligible fixtures must be sought before final disposition; no live return/refund or artificial source mutation is authorized. This is a provider/test-data prerequisite, not automatically a product defect.

### B-004 additional Shop reproduction (round 11)
Captures 177-180: the eight-item reordered Shop basket shows seven shipments. Wheat, sunflower oil and notebooks have unavailable delivery estimates; the action remains Check delivery. This extends the existing quote-provider coverage blocker beyond Bulk. No order/payment was submitted and no positive quote/provider recovery is claimed.

## B-007 - Online privacy content unavailable with device connectivity off
Capture218: Privacy policy opens Chrome and shows ERR_INTERNET_DISCONNECTED. Read-only device settings on this round: airplane_mode_on=0, wifi_on=0, mobile_data=0. Source points to https://moolsocial.com/privacy/. Link launch and Back are observed; policy content and online recovery are not qualified. Connectivity was not changed. Earlier provider failures must not automatically be attributed to this condition: their query bindings, review-mode sources and connectivity at those earlier moments still require separate assessment. Independent offline UI audit remains possible.


## B-008 - Real supplier media absent from default development catalogue
Default public Buy session creation in journey_router.dart253 uses BuyV2Session(core: buySession), whose default productContentAdapter is BuyV2CatalogueProductContentAdapter (session1885). Device-review default sources are generated from BuyV2Catalogue.products (session696/1974). Product mediaAssets defaults empty (models413); catalogue-data rows have no media asset fields; generated _product copy (session816-840) does not supply media. Adapter (content_contracts1621-1660) uses admitted media or explicitly labelled illustration fallback. Physical captures280-282 show generated and canonical products with illustrations, not supplier pack photos.
Actual JPEG/PNG/WebP and MP4 byte decoding, portrait/landscape fit, multi-asset navigation, zoom/reset, video controls and cross-variant asset identity cannot be qualified from this default cohort. This is a fixture/data coverage gap, not a reproduced renderer failure. PD041 records the technical contract only. Workspace-published alternate session route exists (journey_router resolveWorkspacePublicBuySession) and must still be inspected for usable existing media before final disposition. No fixture injection, source change or new APK performed. Current device is offline; do not treat network media as tested. Independent device journeys remain available.


### B-008 alternate workspace-public route reconciliation (round 20)
journey_router257-287 resolves only a published workspace product and creates _WorkspacePublicBuySession using the default content adapter. WorkspaceCatalogueItem.toBuyPublicProduct in work_models1663-1699 transfers identity,price,stock-related publication flag,pack,variant and other commercial fields but no mediaAssets. BuyV2Product therefore retains its empty media default. This inspected alternate conversion does not supply real photo/video test assets either. Store source is read-only in this audit;no publication or supplier-data mutation performed. The required supplier-media publication/propagation contract and actual byte-format device matrix remain unqualified.


### B-006 Wholesale extension (round 23)
Delivered Wholesale PO-240728 exposes three purchased items (rice, oil and notebooks), all disabled with eligibility unavailable in Return (314-315). This extends the existing delivered-item resolution prerequisite to Wholesale. No request submitted; replacement/refund were not repeated in this round. Positive resolution remains unqualified.


## B-009 - Wholesale invoice lines unavailable
PO-240728 Invoice shows item details missing (318). Refresh returns the retained Wholesale/Delivered list (319);reopening remains unavailable (320). _openOrderInvoice in buy_v2_views.dart31-88 gates invoice entry on nonempty order.lines and calls retryCommerce under owner/procurement guards. Positive historical Wholesale invoice contents and successful refresh are unqualified. Return eligibility product rows do not establish invoice-line availability. No invoice fabricated or order/payment changed;source/test-data prerequisite,not a confirmed renderer defect.

## B-010 - Checkout affected-item recovery requires an unavailable-item revision
Actions INVENTORY-ROUND28-06 through09 (Retry availability,Remove affected product,View affected product,Return to checkout) remain device-unqualified. Session10627-10643 creates the affected-item identity only after validating current product facts during checkout;placement failure can also supply exact affectedProductId. Existing generic stock link supplies no issue. Device closed/unavailable product-entry cases412-419 correctly prohibit Add;they do not reproduce an already-carted item becoming unavailable. No safe matching provider revision is available in the exercised cohort. Required:authorized fixture/provider revision for exact existing cart SKU and valid quote/context,without placing a real order. This is a coverage prerequisite,not a new product defect or a passed recovery branch.

## B-011 - Positive purchase-confirmation descendants require a confirmed purchase fixture
Actions INVENTORY-ROUND28-13 through17 remain device-unqualified:confirmed-delivery invoice,single/multiple confirmed-order destinations,Continue shopping after valid confirmation and reduced-motion valid confirmation. Confirmation view8739-8864 uses session.confirmedOrders and confirmedPurchaseId. Session4015 initializes confirmedOrders empty;population occurs in checkout submission paths10682-10683/11029-11030,with completion11231 onward inserting orders and clearing purchased cart lines. Existing historical Orders do not themselves establish this active confirmation state. Declared confirmation link358 exposed empty false success RV6-D009;its buttons359-360 cannot qualify a valid purchase. Required:an authorized non-transactional confirmed purchase fixture including one and multiple deliveries,or later separately authorized end-to-end provider purchase qualification. No state injection,source edit,real purchase or fixture pass substituted. Existing historical invoice and order navigation evidence remains separately valid within its scope.

## B-012 - Delivery exception provider states

Source inventory round66 found Retry,slot selection,Confirm new time,and proof-dispute actions at buy_v2_views.dart10202-10369. Public journey_router253 creates BuyV2Session without deliveryExceptionAdapter;constructor1899 is nullable;card hides when adapter absent. No approved isolated exception/slot/proof state reached in installed APK. SOURCE-ROUND66-01..04 remain provider-blocked;need order-bound safe provider fixtures before device execution. Real rescheduling/disputes are excluded. No product defect or device pass inferred. PD-060 records data ownership/lifecycle requirements.

## B-013 - Post-order balance payment provider states

Source inventory round66 found Pay balance,Continue payment,Check payment,and Retry at views10373-10500. Public session wiring omits balancePaymentAdapter;session4297/4325 fails closed without it. Due/overdue/pending/unknown/offline/action-required states require safe authoritative fixtures and handoff;none qualified on Redmi. SOURCE-ROUND66-05..08 remain provider-blocked. Live payment is excluded. Source mapping PD-061 is not settlement/security qualification or a new confirmed defect.
