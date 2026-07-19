# QA-012 — Retailer Stock Statement, Business Book and money control

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 91, 92 and 106
- Business position with explicitly estimated profit and GST values
- Today, week, month and validated custom business periods
- Payment, supplier-invoice and customer-due attention paths
- Explanatory record-based questions, tax summary and controlled reports
- Authoritative routes to Sales Book, Purchase Book and Stock Statement
- Stock value, physical, reserved, available and incoming position
- Search, empty, clear, movement filters, full balance and stock checks
- Audited physical count, damage/expiry and supplier-return corrections
- Counter-sale recovery through the real sale journey, never a stock shortcut
- Money receipts from Sales Book and supplier payments from Purchase Book
- Evidenced manual expenses and money-exception reconciliation
- Offline, role-denied, gateway failure, exact retry and idempotency boundaries

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 91 | Understand and correct stock | Position; Movements and Stock checks; search; empty; clear; All, Received, Sold, Reserved, Returns, Damage and Count filters; every movement; full balance; every stock check; physical count; damage/expiry; supplier return; missing counter sale route; invalid quantity; invalid reason; offline; role denial; gateway failure; exact retry; duplicate protection; refresh; PDF, CSV and accountant export |
| 92 | Understand the business and open authoritative books | Estimated position; today, week, month and custom period; missing custom dates; payment match and duplicate protection; supplier invoice route; customer due route; three record-based questions; Sales Book; Purchase Book; Stock Statement; money control; GST working summary; refresh; offline; role denial; PDF, CSV and accountant reports |
| 106 | Control money without duplicate bookkeeping | UPI, cash and bank/card receipt routes; expense register; supplier-payment route; manual amount, method, category, note and evidence; missing evidence; offline; role denial; save failure; exact retry; duplicate protection; UPI settlement, cash count and missing-bill exceptions; resolution failure; exact retry; duplicate resolution protection |

## Black-box and regression results

- Dedicated Business Book scenarios: 6/6 passed.
- Affected Universal and retailer suite: 53/53 passed.
- Full application regression cycle 1: 145/145 passed.
- Full application regression cycle 2: 145/145 passed.
- Flutter analyzer after all fixes: no issues.
- Physical OPPO CPH2375 replay: 1/1 passed.
- Covered outcomes: successful, invalid, empty, duplicate, cancelled,
  loading, retry, offline, role-denied, gateway failure, compact width and
  larger text.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact original replay |
|---|---|---|---|
| All three Business Book questions crashed the revealed action sheet with duplicate keys | Keys were derived from the first word, and every question began with “What” | Assigned stable intent keys for collect, margin and suppliers | Business Book → Ask → reveal all three questions → choose Collect: sheet renders and the answer completes |
| Sales Book back action returned to itself and Purchase Book returned to the shop instead of the originating book hub | Earlier isolated screens predated the Business Book route family | Made both primary book screens return to Business Book | Business Book → Sales/Purchases → Back → next book: every route is reachable without a dead end |
| Business Book report methods existed but the reports icon bypassed them and opened Money control directly | The visible control had only a route and no nested report choices | Added Money control, PDF, CSV and accountant-link actions to the report sheet | Reports → failed PDF → same PDF retry: failure is visible and the retry produces the report |
| Initial QA rerun waited indefinitely after a deterministic gateway action | The widget test awaited a delayed fake future without advancing Flutter’s fake clock | Added a bounded future-completion helper that advances the deterministic interval | Refresh failure → exact refresh retry: both outcomes complete without a false pass or stalled runner |

## Exact failed-operation replays

- A custom business period cannot apply until both dates are present.
- Business Book refresh/report failure retains approved records; the exact
  retry succeeds.
- Customer payment matching records PH-1182 once.
- Unknown stock search shows a truthful empty state and Clear restores records.
- A stock adjustment cannot save without positive quantity and a clear reason.
- Failed stock change retains quantity and reason; exact retry posts one
  audited movement, and a duplicate call cannot change stock again.
- Failed stock refresh/export keeps all movements and filters.
- An unrecorded counter sale opens the real counter-order journey.
- A manual expense cannot save without evidence.
- Failed expense save retains every field; exact retry creates one expense and
  duplicate submission cannot create another.
- Failed money resolution leaves the exception open; exact retry resolves it
  once and a duplicate cannot create another record.
- Offline and unauthorized roles cannot change stock, add expenses, reconcile
  money or export financial records.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Business Book → Stock Statement: passed.
- Physical stock count → ADJ-9101 recorded once: passed.
- Business Book → Money control: passed.
- Evidenced manual expense → EXP-10601 saved once: passed.
- Cash exception → resolved once: passed.
- Screenshot checkpoints were captured by
  `integration_test/retailer_books_device_replay_test.dart` at screens 91, 92
  and 106 during the device replay.

## Current gate

The deterministic screens 91, 92 and 106 client slice is **GO** for continued
full-scale implementation. It is **NO-GO** for public inventory, accounting,
tax reporting or money reconciliation until sales, purchases, stock ledger,
payment providers, tax documents, evidence storage and role authorization use
certified production services. The gateway contracts and exact replays prove
client behavior and idempotency boundaries; they do not claim external
financial services are active.
