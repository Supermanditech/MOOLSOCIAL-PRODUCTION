# Buy V2 R35.1 listener-liveness handoff

Date: 31 July 2026

State: `COMPLETE_TEST_ONLY_LISTENER_LIVENESS_HARDENING`

Ticket `BUY-FV2-114` protects the native `ChangeNotifier` seam that makes Buy
session actions visible to Flutter. It changes no application runtime, UI,
backend, approved HTML, protected media, Social source or business rule.

## Protected action classes

Three tests exercise 65 cases:

- 60 customer-visible, state-changing or fail-closed actions that must emit
  at least one listener notification;
- five true no-ops that must remain silent.

The emitting cases cover:

- destination, product, catalogue and category/search/filter changes;
- empty and populated cart/checkout entry;
- add, increase, decrease, remove, clear and scope selection;
- Orders, tracking, order items and reorder;
- Account, assistance, back and return navigation;
- address addition/selection and payment selection;
- saved products, reviews and product reports;
- prescription attachment, approval and quantity enforcement;
- recovery entry/retry, tracking alerts and customer notices;
- missing product/order/address/payment/prescription and invalid
  review/report fail-closed paths.

The tests require one-or-more notifications, not an exact count. Compound
actions may legitimately compose existing methods and emit more than once.
No test invents visual progress, animation timing or backend completion.

The five silent cases are missing-line decrease, missing-line removal,
inactive Account return, empty notice clearing and empty cart-acknowledgement
clearing. None changes state or creates a customer message, so emitting
synthetic progress would be dishonest.

Test-file SHA-256:

`96BF6BC6E6C50AB4C1F0EF5EA431A89B5176D4A49DCD01E076FAED07DA8BE46C`

## Verification

- Focused listener-liveness tests: `3/3` passed.
- Full Flutter analysis: passed.
- Complete Buy regression 1: `126/126` passed; four opt-in captures skipped.
- Complete Buy regression 2: `126/126` passed; four opt-in captures skipped.
- The source fingerprints before both regressions were identical.
- Protected Buy baseline: passed.
- Protected Social baseline: passed.
- Backend-contract boundary: passed.
- Data-egress boundary: passed.
- Approved Screens 01–03/reference locks: passed.
- Founder-FINAL Buy reference: passed.
- Brand integrity: passed.
- User-facing Flutter copy: passed.
- HTML customer copy: `9/9` states passed.
- Interaction contract: `154` routes passed.
- The temporary HTML server and headless browser exited; ports 8765 and 9223
  were verified free.

## Protected and device identity

- Starting HEAD:
  `9fdf232c4a15974191c47d9ba9a380ac6170de22`
- Protected Buy runtime files: `28`
- Protected Buy tree:
  `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`
- Protected Social files: `119`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- OPPO: `2b3e0f71`
- Installed version: `1.0.0-r35.1`
- Installed version code: `2026073045`
- On-device base APK SHA-256:
  `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`

Because runtime bytes did not change, no APK rebuild, reinstall or visual
device replay was warranted. The connected OPPO was used for read-only
installed-artifact identity verification.

## Evidence

`artifacts/quality/buy-r35-1-listener-liveness-hardening-20260731-35`

Evidence includes focused output, case counts, exact source fingerprints,
full analysis, two same-source regressions, all
protected/security/reference/copy gates, HTML lifecycle and read-only OPPO
identity.

Push, deploy, publication and production release remain unauthorized.
