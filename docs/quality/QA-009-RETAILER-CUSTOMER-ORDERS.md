# QA-009 — Retailer customer orders and delivery

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 74–77
- Retailer home, live availability, search, alerts and operating tabs
- Paid customer-order review and explicit acceptance
- Per-product packing and incomplete-pack protection
- Home-delivery assignment and captain identity matching
- Parcel-ready and captain-arrived checkpoints
- OTP-protected physical handover
- Live delivery status, customer proof and delivery receipt
- Automatic Business Book entry
- Exact return from Chat and Mool to the originating retailer screen

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 74 | Operate the live shop | Business Book; alerts; shop availability; barcode action; paid-order card; search; empty search; clear; refresh; failed refresh; retry; Orders, Stock, Wholesale and Chat; Mool and exact return |
| 75 | Review and pack one paid order | Payment protection; delivery promise; Message; Call; show/hide product groups; accept failure and retry; duplicate acceptance protection; start packing; each product group; incomplete packing; packing failure and exact retry; cannot-fulfil empty, cancel, failure and refund-safe completion |
| 76 | Assign and safely hand over delivery | Delivery request failure and retry; one delivery reference; captain identity and vehicle; Message; Call; parcel ready; captain arrival; invalid OTP; correct OTP; handover failure; retry; delivery issue empty, cancel, failure and retry |
| 77 | Track completion and record the sale | Live status refresh; refresh failure and retry; nearby; delivered; customer proof; receipt; one Business Book entry; duplicate-refresh protection; Orders, Mool and Chat return |

## Dedicated black-box coverage

- Scenarios: 11
- Passed after exact defect replays: 11/11
- Work, retailer, Universal and journey affected suite: 58/58
- Full application regression cycle 1: 121/121
- Full application regression cycle 2: 121/121
- Analyzer after all source fixes: no issues
- Physical OPPO integration replay: 1/1
- Covered outcomes: successful, empty, invalid, duplicate, cancelled,
  loading, retry, gateway failure, incomplete packing, wrong OTP,
  handover failure, tracking failure, compact width, larger text and exact
  route return.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact replay |
|---|---|---|---|
| Compact 360 px layout overflowed by 37 px at 1.35× text | The order-stage capsule and amount shared one fixed horizontal row | Added an adaptive header that stacks the stage and amount for compact width or enlarged text | 360×800, 1.35× text → paid order: no overflow; Message, Call, product controls and primary action remain reachable |
| A deep-linked order could notify listeners while the route was still building | `openOrder` mutated and notified from `initState` | Added silent `ensureOrder` and `ensureTrackingOpen` initialization paths; user actions retain normal notifications | Clean direct order, delivery and tracking entries mount once without `setState during build` |
| Changing the retailer tab through a query route could leave the previous tab visible | The same stateful home widget was reused without reconciling the new query value | Added `didUpdateWidget` route-query reconciliation | Home → Orders → Stock → Wholesale → invalid view → Orders: the requested view renders and recovery stays inside retailer operations |
| Failure replay could lose checked packing work or create duplicate external references | Mutating state was not isolated from the gateway completion boundary | Preserve local checked lines and commit stage/reference only after gateway success; make completed actions idempotent | Packing, delivery request, handover and tracking failure → exact retry: checked products remain and one order, delivery reference, handover and book entry exist |
| Manual ADB coordinates became stale after snackbar and keyboard reflow | The physical test driver reused absolute coordinates after content moved | Added a physical-device integration replay that targets the same production controls by stable keys and captures screens 74–77 | OPPO CPH2375 → home → paid order → four packing groups → captain → OTP → tracking → receipt → Business Book: 1/1 passed |
| The phone could not reach laptop emulators when the APK used `127.0.0.1` | On a physical device, loopback points to the phone rather than the laptop | Built device QA with `MOOLSOCIAL_EMULATOR_HOST=192.168.31.66`; production remains environment-configured | Clean install → OTP request → emulator-issued code → authenticated Universal: passed without bypassing authentication |

## Exact failed-operation replays

- Accept-order failure preserves the same paid order. Exact retry accepts it
  once; repeating Accept cannot duplicate the operation.
- Marking packed with zero or only some groups produces a visible correction
  and cannot advance the order.
- Packing failure keeps every checked product. Exact retry marks the same
  order packed.
- Cannot fulfil requires a reason, supports cancellation, retains the order
  after gateway failure and produces one refund-safe outcome after retry.
- Delivery request failure keeps the packed order. Exact retry creates one
  delivery reference and one assigned captain.
- Wrong or incomplete handover OTP keeps the parcel with the retailer.
  Correct OTP unlocks the separate Hand over parcel action.
- Handover failure keeps the verified handover state and exact retry records
  one handover.
- Delivery-issue submission requires a reason and details, supports
  cancellation, retains the order on failure and retries once.
- Tracking refresh failure preserves the current live status. Exact retry
  reaches Nearby and Delivered without creating a second delivery.
- Receipt creation records the completed sale once in Business Book.
- Chat and Mool return to the exact retailer operating screen rather than
  depending on browser or system back.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Clean install → laptop LAN Auth/Data Connect emulators → mobile OTP →
  Universal: passed.
- Verified retailer setup → Open shop operations → paid order: passed.
- Paid order → Accept → four packing groups → Mark packed: passed.
- Request delivery → captain assignment → parcel ready → captain arrived →
  OTP handover: passed.
- Hand over parcel → live tracking → delivered proof → receipt → Business
  Book: passed through the physical integration replay.
- Evidence:
  - `artifacts/device/moolsocial-production-retailer-home-device.png`
  - `artifacts/device/moolsocial-production-retailer-order-device.png`
  - `artifacts/device/moolsocial-production-retailer-packed-state-device.png`
  - `artifacts/device/moolsocial-production-retailer-delivery-device.png`
  - `integration_test/retailer_device_replay_test.dart`

## Current gate

The deterministic retailer customer-order slice is **GO** for continued
full-scale implementation. It is **NO-GO** for public live transactions until
orders, inventory reservations, payments and refunds, delivery matching,
captain identity, OTP, live location, customer proof and Business Book
posting are connected to certified production services. The deterministic
gateways prove interaction and state contracts; they do not claim that those
external services are active.
