# QA-010 — Retailer POS, counters, payment and Sales Book

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 74, 78, 79, 80 and 90
- Counter, phone and order-linked Chat order creation
- Optional counter-customer lookup with explicit purpose and anonymous sale
- Search, barcode, voice and repeat-basket product entry
- Live-stock quantity limits, live bill, fulfilment and payment choices
- Idempotent stock reservation and assisted-order creation
- Multi-counter creation, editing, operator, open/closed state and activity
- Counter payment proof, immutable invoice and consent-aware delivery
- Unified Sales Book for app, counter, phone and Chat sales
- Payment and return views, source filters, search, detail, invoice, receipt
  sharing, period metrics and role-controlled exports

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 74 | Start a sale from the live shop | Create order; Send invoice; Business Book; existing Orders, Stock, Wholesale, Chat and Mool navigation |
| 78 | Build one connected customer order | Counter, Phone and Chat sources; counter context; manage counter; empty/invalid customer lookup; continue without mobile; customer basket; product search and empty result; clear search; barcode success and denied permission; voice success and denied permission; repeat basket; each product add/reduce; stock limit; clear-bill cancel/confirm; empty bill; each fulfilment and source-appropriate payment choice; offline create; create failure and exact retry; duplicate-create protection; new order; open created customer order; receive counter payment; alerts; Sales Book |
| 79 | Operate shop counters | Shop totals; every counter selector; closed/empty activity; alerts; create counter; purpose examples; optional operator; open/closed choice; empty and duplicate validation; cancel; save failure and retry; edit; duplicate-purpose protection; close failure and retry; duplicate state protection; open closed counter; start order with retained counter identity |
| 80 | Receive and record counter payment | Product detail; Cash, UPI and Card; cash-not-confirmed rejection; cash confirmation; matched UPI; authorised card; completion failure and exact retry; duplicate-completion protection; edit order; sale receipt; stock/sale/invoice posting; invoice detail; Mool Chat, WhatsApp, SMS and QR/Print; consent denied; share failure and retry; duplicate share protection; new sale; Sales Book; alerts |
| 90 | Verify authoritative sale outcome | Today period; Sales, Payments and Returns; payment-attention route; invoice/customer/order search; empty result and clear; App, Counter, Phone, Chat and Due filters; every sale row; customer, payment, fulfilment, stock, margin and order detail; tax invoice; MoolSocial Chat, WhatsApp and QR receipt paths; new Counter/Phone/Chat sale; refresh failure and retry; offline records; role denied; Sales Statement, GST and accountant export failure and retry |

## Black-box and regression results

- Dedicated POS and Sales Book scenarios: 10/10 passed.
- Existing retailer customer-order suite after integration: 11/11 passed.
- Affected Universal, Work and retailer suite: 62/62 passed.
- Full application regression cycle 1: 131/131 passed.
- Full application regression cycle 2: 131/131 passed.
- Flutter analyzer after all fixes: no issues.
- Physical OPPO CPH2375 replay: 1/1 passed.
- Covered outcomes: successful, invalid, empty, duplicate, cancelled, loading,
  retry, offline, permission-denied, role-denied, gateway failure, stock limit,
  consent denied, compact width, larger text and exact route return.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact original replay |
|---|---|---|---|
| Product Add, customer Find and Sales Book period controls could receive infinite width inside a row | The shared full-width button theme uses `Size.fromHeight`, which requires a bounded parent | Added explicit compact widths to row-level controls while retaining the 48 px tap target | Counter order → product list with Salt at zero → render Add; Sales Book → Today: all controls render and tap without layout failure |
| A completed counter sale could fail while adding activity | Approved seed activity used constant, unmodifiable lists | Made mutable operational copies while retaining immutable product definitions | Create RT-3028 → complete UPI sale: one activity, one invoice and one Sales Book record are inserted |
| Bottom-sheet list actions raised invisible-ink assertions | A decorated sheet surface sat between `ListTile` and its nearest Material | Made the rounded sheet itself the Material and clipped its contents | Counter alerts and Sales Book Share/New Sale sheets: every row has visible press feedback and completes its action |
| A newly created Phone/Chat order opened the old seeded order | The order builder stored only the new ID; the customer-order collection did not receive the assisted order | Insert one accepted customer order after authoritative non-counter creation, keyed by the same ID | Chat → Create order → Open RT-3028: RT-3028 opens, not MS-2841 |
| Counter editor could rebuild with disposed text controllers during its close animation | Local controllers were disposed as soon as the modal future resolved | Keep controller ownership for the complete modal lifecycle | Create/edit/cancel counter repeatedly: fields remain stable and no framework exception occurs |
| Automated “scroll to Refresh” caused a hidden refresh before the intended tap | The test helper used a downward overscroll gesture to reset position, triggering `RefreshIndicator` | Replaced it with deterministic scroll-position jumps that cannot trigger user actions | Clean Sales Book → Refresh: call 1 visibly fails; exact tap 2 succeeds; call count is exactly two |
| Physical replay could not reveal View Sales Book after invoice QR success | The success banner changed the OPPO viewport after the lazy list’s extent was calculated | Added a physical-only upward-gesture fallback after deterministic reveal | Exact original device sequence from Home through QR → View Sales Book → MSI-3028 detail: 1/1 passed |

## Exact failed-operation replays

- Empty bill cannot create an order. Products, customer and source remain
  available for correction.
- Create-order failure keeps the full draft. Exact retry reserves stock once;
  repeating Create cannot create a second order.
- Product quantity cannot exceed current shop stock.
- Barcode and voice permission denial leave search and manual Add usable.
- Empty/duplicate counter purpose cannot save. Gateway failure keeps purpose,
  operator and open/closed choice for exact retry.
- Counter close failure preserves the open state. Exact retry closes it; Start
  Order opens a closed counter once and retains its identity.
- Cash cannot complete until physical receipt is confirmed.
- Sale-completion failure keeps payment, order and reserved stock unchanged.
  Exact retry creates one invoice and one Sales Book record.
- WhatsApp/SMS require customer consent. Share failure does not change the
  completed sale; exact retry sends the existing invoice.
- Sales Book refresh/export failure keeps every existing record. Exact retry
  cannot create another sale.
- Offline order, sale, share, refresh and export actions never claim server
  success.
- A staff role without financial permission sees a safe return action and
  cannot export.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Home → Create order → Counter → barcode product → ₹428 bill: passed.
- Create RT-3028 → stock reservation → Receive payment: passed.
- Matched UPI → complete sale → MSI-3028 → invoice QR: passed.
- View Sales Book → MSI-3028 row → authoritative sale detail: passed.
- Screenshot checkpoints were captured by
  `integration_test/retailer_pos_device_replay_test.dart` at screens 78, 80
  and 90 during the device replay.

## Current gate

The deterministic retailer POS slice is **GO** for continued full-scale
implementation. It is **NO-GO** for public money or inventory movement until
orders, stock reservation/debit, payment confirmation, invoice numbering,
customer consent delivery, counter permissions, returns, tax exports and
Business Book projections use certified production services. The gateway
contracts and exact replays prove client behavior and idempotency boundaries;
they do not claim that external services are active.
