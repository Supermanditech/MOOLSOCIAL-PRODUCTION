# QA-011 — Retailer wholesale procurement and Purchase Book

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 74 and 81–89
- Canonical wholesale catalogue, search, categories, barcode and low-stock
  reorder
- MOQ cart, quantity limits, terms, delivery address, GST profile and saved
  draft
- Commercial-term revalidation and idempotent supplier-wise purchase orders
- Honest pre-dispatch, dispatched, in-transit and delivered tracking
- PO-linked call, Chat, delay reporting and offline tracking fallback
- Accepted, short, damaged, wrong-product and invoice-mismatch receipt paths
- Evidence, GST invoice, protected settlement, GRN and stock posting
- Receipt result, Purchase Book, direct supplier bill capture and controlled
  exports
- Supplier bill reconciliation, issue hold, payment authorization and
  processing, settled, failed and reversed outcomes

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 74 | Enter business procurement | Wholesale preview action; Wholesale dock; return to shop, Orders, Stock, Chat and Mool |
| 81 | Find and add wholesale cases | Alerts; search; empty result; clear; barcode denied and success; All, Deals, Fast delivery, Credit and Brands; low-stock reorder; every product; full buying terms; Add; reduce; increase; availability limit; cart |
| 82 | Review and place purchase orders | Empty cart; every line; Price & terms; reduce; increase; address; GST; saved draft; payment split; review; cancel; offline; placement failure and exact retry; duplicate placement protection |
| 83 | Verify authoritative order outcome | Every supplier-wise PO; PO detail; protected advance; pay-on-receipt balance; invoice timing; stock-not-added truth; download; individual tracking and Track orders |
| 84 | Follow delivery truth | Every PO selector; committed pre-dispatch state; verified dispatch; in-transit live update; delivered state; refresh failure and retry; offline fallback; call; Chat; every delay reason; alerts; Receive goods |
| 85 | Accept goods or hold a discrepancy | Help; All received; Report issue; short, damaged, wrong product and invoice mismatch; camera denied; evidence attached; tax invoice; protected payment; cancel; offline; post failure and exact retry; duplicate GRN/stock protection |
| 86 | Verify business posting | Stock, payment, Purchase Book, GRN and invoice result details; updated stock; help; Purchase Book route; accepted and issue-open outcomes |
| 87 | Operate the Purchase Book | Period; Purchases, Payables and Returns; attention routes; supplier/PO/invoice search; empty and clear; source filters; every record; reorder; return; invoice; supplier bill; add by scan, upload and manual entry; reviewed extraction; refresh failure and retry; offline; role denial; PDF, Excel and CSV export failure and retry; accountant, GST and import tools |
| 88 | Decide a supplier payment | Supplier; original invoice; PO, GRN and GST match; bill tools; external payment truth; every issue hold; UPI and bank transfer; review; cancel; offline; authorization failure and exact retry; duplicate authorization protection |
| 89 | Verify payment result | Processing lockout; refresh failure and retry; settled receipt and UTR; failed payable; reversed payable; bill; acknowledgement; final receipt; Purchase Book outcome |

## Black-box and regression results

- Dedicated wholesale and Purchase Book scenarios: 8/8 passed.
- Affected Universal, Work and retailer suite: 62/62 passed.
- Full application regression cycle 1: 139/139 passed.
- Full application regression cycle 2: 139/139 passed.
- Flutter analyzer after all fixes: no issues.
- Physical OPPO CPH2375 replay: 1/1 passed.
- Covered outcomes: successful, invalid, empty, duplicate, cancelled, loading,
  retry, offline, camera-denied, role-denied, gateway failure, stock limit,
  partial receipt, failed payment, reversed payment, compact width and larger
  text.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact original replay |
|---|---|---|---|
| Cart Price & terms plus quantity controls overflowed 22 px at normal phone width | The shared full-width button theme consumed too much horizontal space in a row | Bounded the terms action with responsive expansion and a compact 48 px button style | Screen 81 reorder → cart → render both cart lines: every terms and quantity control is visible and tappable |
| Purchase Book failed layout with infinite-width period button | The period action used the shared full-width style inside an unconstrained title trailing slot | Added an explicit 104 px responsive bound while retaining the 48 px target | Open screen 87 at 412 × 915 and 360 × 720: period, views and list render without exception |
| Existing retailer regression expected the removed wholesale preview | The test contract still represented the temporary preview instead of approved screen 81 | Replaced the stale assertion with the production catalogue destination | Stock → Wholesale dock: screen 81 opens and the affected suite passes 62/62 |
| Purchase Book QA case appeared to hang after export retry | The test awaited a delayed fake gateway without advancing Flutter’s fake clock | Pumped the deterministic 30 ms gateway interval before awaiting the result | Search → bill capture → period → failed PDF → retry PDF → failed refresh → retry refresh: completes and passes |

## Exact failed-operation replays

- Empty cart cannot place an order.
- Product quantity cannot exceed authoritative case availability.
- Camera denial leaves search and Add available.
- Offline and gateway-failed placement keep the exact cart; retry creates one
  set of supplier-wise purchase orders.
- Delivery refresh failure and offline status retain the last verified update.
- Receipt cannot post before the retailer chooses accepted or issue.
- Receipt failure retains accepted quantity, issue and evidence. Retry creates
  one GRN and increases stock once.
- Disputed quantity never enters stock and its supplier settlement remains
  protected.
- Purchase Book refresh/export failure retains every existing record. Retry
  cannot create a purchase.
- Unauthorized shop roles cannot open or export financial records.
- Supplier authorization failure leaves the bill due. Retry creates one
  processing payment.
- Processing does not expose a final receipt and cannot authorize again.
- Failed and reversed payment states restore the supplier payable.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Shop → Wholesale Buy → five-case MOQ reorder: passed.
- Cart → two supplier-wise purchase orders: passed.
- Verified delivery updates → delivered: passed.
- All received → GRN-85021 → 12 packs added once: passed.
- Receipt result → Purchase Book → one GRN-85021 record: passed.
- Screenshot checkpoints were captured by
  `integration_test/retailer_wholesale_device_replay_test.dart` at screens
  81–87 during the device replay.

## Current gate

The deterministic retailer wholesale slice is **GO** for continued full-scale
implementation. It is **NO-GO** for public procurement, inventory or supplier
money movement until catalogue matching, commercial revalidation, purchase
orders, transport events, invoices, goods receipts, inventory posting, return
holds, tax records and payment settlement use certified production services.
The gateway contracts and exact replays prove client behavior and idempotency
boundaries; they do not claim that external services are active.
