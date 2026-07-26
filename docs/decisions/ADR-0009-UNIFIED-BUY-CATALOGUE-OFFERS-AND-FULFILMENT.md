# ADR-0009: Unified Buy catalogue, offers and fulfilment

Status: **Founder-approved for HTML prototyping; final product approval pending HTML review**

Recorded: 26 July 2026

Founder decision: 27 July 2026. The operating model below is approved as the
information-architecture authority for a new Buy HTML founder-review
candidate. This approval does not mark the Buy UI/UX `FINAL`, freeze an
accepted reference, authorize Flutter implementation or authorize a Dev
deployment trial.

## Context

MoolSocial Buy must serve household customers and verified business buyers
without duplicating common products, mixing retail and wholesale commitments,
or forcing one participant type to cover every geography.

The supply network may include shops, retailers, wholesalers, distributors,
manufacturers and delivery partners. Several participants can sell the same
product or pack with different prices, stock, delivery promises and commercial
terms. MoolSocial also needs fast PIN-code expansion, competitive delivered
prices, rapid participant onboarding and truthful fulfilment.

The existing production journey map already separates canonical products from
supplier offers and keeps wholesale terms out of the household product grid.
This decision preserves that rule while defining one coherent Buy architecture
for personal and business use.

## Decision

### 1. One Buy capability, two buying contexts

MoolSocial will have one `Buy` capability and one shared catalogue foundation.
The active identity determines which buying context is available:

- **Personal Buy** is the default. It shows retail packs, final consumer price,
  stock, seller, delivery promise, return/cancellation terms and household
  quantities.
- **Business Buy** becomes available only inside a verified business workspace.
  It shows wholesale packs, MOQ, quantity-price breaks, applicable taxes,
  freight or delivered cost, payment terms and business delivery commitments.

The contexts share search, product identity, category structure and core
interaction patterns. They do not share baskets, price rules, quantities,
invoices, credit claims or commitment language.

### 2. One product record, many eligible offers

A common product appears once in discovery. The platform does not create one
customer-facing product tile for every supplier.

The commerce model is:

`canonical product -> verified pack -> participant offer -> serviceable quote`

- A canonical product owns stable identity such as brand, title, category,
  barcode or recognised product code, attributes and regulated-category flags.
- A pack owns quantity, unit, consumer/case configuration and comparable unit
  measure.
- An offer owns seller, price, tax treatment, stock, MOQ, price breaks,
  fulfilment methods, service area, lead time, return terms and effective
  dates.
- A serviceable quote selects or compares only currently eligible offers for
  the customer's PIN code, pack, quantity, identity and delivery requirement.

Product content is therefore reusable while every participant controls only
its own authorised offer, stock and fulfilment commitments.

### 3. Onboard every useful participant type, activate capabilities separately

MoolSocial should permit self-onboarding for shops, retailers, wholesalers,
distributors, manufacturers and logistics partners. Registration alone does
not make every capability live.

Each workspace receives only the capabilities it has verified:

| Workspace | May fulfil retail | May supply wholesale | May fulfil delivery |
| --- | --- | --- | --- |
| Shop / retailer | Yes, for approved products and service areas | Yes, only after wholesale capability and terms are verified | Yes, with verified in-house capacity, or through a delivery partner |
| Wholesaler / distributor | Only when separately approved for consumer retail | Yes | Yes, for declared business-delivery areas or through a delivery partner |
| Manufacturer / brand owner | Only when separately approved for direct-to-consumer fulfilment | Yes, for eligible products and buyers | Yes, for declared dispatch areas or through a delivery partner |
| Delivery partner | No seller rights | No seller rights | Yes, for verified service areas, capacity and handling types |

Category-specific licences, tax identity, bank and payout checks, service area,
stock ownership, product authenticity, returns and operational capacity remain
independent gates. Medicine, food and other regulated categories retain their
additional legal controls.

### 4. PIN-code fulfilment is capability based

Supply is matched by PIN code and fulfilment capability rather than participant
label alone.

For each order, the platform considers:

- eligible seller and fulfilment node;
- current stock and reservation;
- pack and requested quantity;
- delivery or collection availability;
- promised time and capacity;
- total delivered or landed price;
- seller reliability, cancellation and substitution history;
- category handling requirements; and
- return, refund and support coverage.

A nearby retailer can fulfil a consumer order. A retailer, wholesaler,
distributor or manufacturer can fulfil a business order when its verified
offer and delivery commitment fit the buyer's location. A delivery partner may
move the order but does not become the seller.

### 5. Price leadership is transparent and sustainable

MoolSocial will not force a participant to sell below its chosen price and will
not make an unprovable universal “lowest price” promise.

The primary retail offer should optimise the **final delivered consumer
price** while protecting stock truth, delivery reliability, product
authenticity, returns and support. The primary wholesale offer should optimise
the **landed business cost** across MOQ, quantity break, tax, freight, payment
terms and delivery commitment.

The customer sees:

- the selected offer and seller;
- final payable or landed amount;
- pack and comparable unit price;
- delivery promise;
- why the offer is selected, such as `Lowest delivered price`, `Fastest
  delivery` or `Best value`; and
- `Compare sellers` when more than one eligible offer exists.

`Lowest delivered price` may be used only when the quoted eligible comparison
set proves it for the same product, pack, quantity, location and fulfilment
window. Platform-funded promotions remain separate, funded and auditable.

### 6. Fast onboarding uses catalogue matching

Participant onboarding is progressive:

1. verify identity, workspace type, service PIN codes and required licences;
2. match barcode, product code or search input to the canonical catalogue;
3. choose an existing verified pack or request review of a new pack;
4. add price, stock, fulfilment, lead time and applicable terms;
5. validate the offer;
6. publish only to eligible customer or business contexts.

This keeps common product content consistent and lets a participant start with
stock and price instead of rebuilding a full listing. Unmatched or disputed
products remain unavailable until catalogue review completes.

### 7. Fulfilment and basket rules

- Retail baskets prefer a single reliable serviceable seller when that
  preserves price and delivery quality.
- A split order is allowed only when it materially improves availability,
  price or delivery and the customer sees every seller, delivery, fee and
  return boundary before payment.
- Wholesale baskets create supplier-specific purchase orders and revalidate
  MOQ, price, tax, freight, credit and stock before commitment.
- Retail and wholesale baskets never merge.
- Price and stock are reserved before payment or purchase-order commitment.
- Duplicate commands return the original basket, order or purchase order.

### 8. Workspace and customer interests

- Customers receive one clean product catalogue, competitive qualified offers,
  clear delivery promises and accountable support.
- Retailers gain local consumer demand and, when eligible, an additional
  wholesale supply channel without being forced into both.
- Wholesalers and distributors gain verified business demand, MOQ and
  commercial-term controls.
- Manufacturers gain product-master participation, distribution reach and
  direct wholesale capability; direct retail remains an optional verified
  capability.
- Delivery partners gain PIN-code and capacity-matched work without taking
  seller ownership.
- MoolSocial gains geographic density without duplicating products or
  depending on one participant class.

## UI consequences

The first Buy founder-review HTML must demonstrate:

1. Personal Buy with one canonical product grid and retail offer selection.
2. A product decision view with pack, final delivered price, seller, stock and
   delivery promise.
3. A seller comparison that does not duplicate the product grid.
4. A verified-business context change that exposes Wholesale without leaking
   wholesale terms into Personal Buy.
5. A wholesale decision view with MOQ, price breaks, tax, freight/delivery and
   payment terms.
6. PIN-code serviceability, unavailable, changed-price, changed-stock and
   recovery states.

Seller catalogue management, onboarding, stock, fulfilment and settlement
belong to the applicable workspace. They must not be placed in the customer
Buy surface.

## Launch sequence

To build geographic coverage without delaying the controlled launch:

1. open self-onboarding to all supported participant types;
2. activate local retailers and shops first for household retail density;
3. activate delivery partners by proven PIN-code capacity;
4. activate wholesalers/distributors for verified business procurement;
5. activate manufacturers for product-master collaboration and wholesale
   supply; and
6. activate direct-to-consumer manufacturer or wholesaler offers only after
   the separate retail fulfilment gate passes.

The architecture supports the full network from the beginning. The launch may
enable capabilities in stages behind server-owned eligibility and feature
flags.

## Rejected alternatives

- Separate retail and wholesale apps or duplicated catalogues.
- One product tile per seller.
- Treating every onboarded participant as automatically eligible for retail,
  wholesale and delivery.
- Ranking by sticker price while hiding fees, tax, freight, MOQ or delivery
  reliability.
- Letting a delivery partner appear as the seller.
- Showing wholesale commitments in the household product grid.

## Founder decision gate

The founder approved this ADR for the shared Buy HTML information architecture
on 27 July 2026 and reserved final product approval until the complete
interactive HTML is reviewed. Flutter changes, participant activation,
payments, production data, cloud deployment and any live lowest-price claim
remain unauthorized.
