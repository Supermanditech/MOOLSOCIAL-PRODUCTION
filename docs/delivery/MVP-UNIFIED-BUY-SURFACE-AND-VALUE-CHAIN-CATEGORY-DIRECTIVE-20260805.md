# MVP unified Buy surface and value-chain category directive

Date: 5 August 2026
State: founder-directed planning boundary; not executing

## Founder correction

The founder clarified that Manufacturer, Retailer and every other eligible
buyer must not receive a separately built buying application inside its
workspace. The native **Buy** main action is the one buying surface for every
user. An exact selected workspace may change eligible value-chain categories,
packs, terms, addresses, approval requirements and commitment authority, but
it does not create another catalogue, Cart, checkout, order, tracking or
receipt presentation.

This clarification is consistent with
`docs/decisions/ADR-0009-UNIFIED-BUY-CATALOGUE-OFFERS-AND-FULFILMENT.md` and
narrows future MVP implementation planning that might otherwise reproduce the
older review/demo workspace buyer routes.

## One customer Buy surface

The production rule is:

`signed-in person -> Buy -> Shop / Wholesale / Medicine / Orders -> optional
authoritative buyer-workspace context -> eligible value-chain category -> one
shared decision, Cart, commitment and order journey`

1. Every signed-in person remains a Personal user and opens the same native
   Buy owner.
2. Shop and Medicine use the applicable personal buying context.
3. Wholesale may be discovered in the same Buy surface. A wholesale
   commitment requires an eligible verified buyer workspace and its
   authoritative tax, address, approval and commercial-term facts.
4. Grocery / Kirana Shop, General Retail Shop / Dukaan, FMCG Supplier /
   Distributor and bounded FMCG Manufacturer users do not get separate buyer
   screens. When eligible, they select or retain the exact buyer workspace and
   continue in the same Buy surface.
5. Switching buyer context must never merge baskets, leak terms, grant a
   capability locally or change the selected selling/fulfilment workspace.

## Value-chain category projection

The existing Buy category and search owners receive a server-authoritative
projection. A projected category record must declare at least:

- exact category and pack family;
- allowed Personal or exact buyer-workspace contexts;
- exact eligible seller workspace types;
- geography and serviceability;
- price, tax, freight, MOQ, payment and delivery fields required before
  commitment;
- regulatory or approval gates; and
- enabled, held, unavailable or registered-disabled state with reason.

Adding a value-chain category is a data/capability registration, not a new
screen. Raw Material Supplier, Packaging Supplier and other existing
`beyond_mvp` profiles remain registered disabled. Their category slots may be
known to Admin, but they cannot be exposed as live or fulfil an order unless a
later exact founder decision reclassifies and authorizes them.

## Workspace responsibility after this correction

Buying stays in Buy. Exact workspaces retain only their acting-side launch
responsibilities:

| Exact workspace | Retained MVP workspace responsibility | Not rebuilt inside the workspace |
| --- | --- | --- |
| Grocery / Kirana Shop or enabled General Retail Shop / Dukaan | Shop offer/stock, Ready/Busy/Paused, incoming-order Accept/Decline, packing and handover | wholesale discovery, Cart, buyer checkout, purchase tracking, generic POS/books/customers/campaigns depth |
| FMCG Supplier / Distributor | Wholesale offer/pack/terms, incoming purchase-order decision, dispatch and handover | separate procurement catalogue, buyer Cart, buyer payment/tracking or broad ERP |
| bounded FMCG Manufacturer | approved product master/pack, wholesale offer, incoming order decision and dispatch | `ManufacturerProcurementScreen`, raw-material/packaging/machinery buying UI, growth/services/broad ERP depth |
| Medical Store / Pharmacy | medicine offer/licence, pharmacist decision, incoming order, packing and regulated handover | a second Medicine customer catalogue or Cart |

Shared workspace settings, compliance, settlement status and support may be
reused across exact types; the visible wording and capabilities still resolve
to the exact actor.

## Confirmed older presentation duplication not to rebuild

The older read-only Flutter presentation contains ten direct buyer-route
duplicates:

- Manufacturer: `/app/manufacturer/purchases`;
- Retailer: `/app/retailer/wholesale`;
- Retailer: `/app/retailer/wholesale/cart`;
- Retailer: `/app/retailer/wholesale/orders/confirmed`;
- Retailer: `/app/retailer/wholesale/orders/tracking`;
- Retailer: `/app/retailer/wholesale/goods-receipt`;
- Retailer: `/app/retailer/wholesale/goods-receipt/result`;
- Retailer: `/app/retailer/books/purchases`;
- Retailer: `/app/retailer/supplier-bills/:billId`; and
- Retailer: `/app/retailer/supplier-payments/:paymentId/status`.

These files and routes remain preserved as user-owned historical source. The
new isolated native V2 must not reuse their presentation. Future authorized
route containment may resolve them to the canonical Buy destination/order
state with authoritative workspace context; no local query parameter may
grant buyer authority.

The following broad older workspace routes are also outside the smallest
complete current MVP and are not rebuilt as type-specific production screens:

- Manufacturer Books, Growth, broad Control and Services; and
- Retailer POS, broad Books, Services, Customers, Campaigns and separate Team
  administration.

Any launch-required fact from those surfaces must live in the applicable
shared offer, order, fulfilment, workspace-settings, finance or Admin owner.

## Planning reduction

This clarification removes ten confirmed duplicate buyer routes and avoids at
least seventeen broad type-specific ERP/growth/service route implementations.
It reduces the earlier 60-day architecture target from approximately 45-60
canonical routes and 36-44 route-level screens to approximately **35-48
canonical routes** and **32-40 route-level screens**, subject to exact connected
reference inventory.

Exact user-type tickets remain necessary as capability and acceptance records.
They do not require separate screen implementations. The revised planning
range is approximately **730-1,000 active Codex hours** and **42-52 elapsed
engineering days** when dependencies are promptly available, leaving a small
external/store buffer inside the 60-day target.

## Authority and manifest boundary

- This directive reduces future planning; it does not delete or modify the
  protected legacy or V2 runtime.
- The existing Buy V2 Shop, Wholesale, Medicine and Orders surface remains the
  protected presentation checkpoint.
- The 45-child Universal, 47-child Buy and 45-child Work manifest files and
  their recorded SHA-256 identities are unchanged.
- This directive does not activate a child, change the current MVP machine
  state, authorize a runtime/backend write, edit the read-only screenbook,
  build/install an APK, use credentials, send a message/call, move money,
  deploy, promote, commit or push.
- Any later executable routing/category implementation must be covered by the
  applicable exact preauthorized child or a versioned manifest amendment.
