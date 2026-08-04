# Buy FV2 R58.8.7 scoped Cart/Checkout dock continuity handoff — 4 August 2026

## Founder approval — 4 August 2026

The founder explicitly approved exact candidate
`BUY-R58-SCOPED-CART-CHECKOUT-DOCK-CONTINUITY-FIX1`. It is founder
approved/protected at source SHA-256
`D7D382F57D672E11819173B591F3C4BE30A029CCF3AE5AC426FE30D132E14649`
and APK/install SHA-256
`8584CCD4D37227DC3D00952CBB8A283F85F78CE961F9CF58D55B153FAD1BA052`.
Authority: `artifacts/quality/buy-r58-8-7-founder-approval-20260804-160`.
All exclusions and no-baseline/no-promotion boundaries remain in force.

## Disposition

`BUY-R58-SCOPED-CART-CHECKOUT-DOCK-CONTINUITY-FIX1` is technically/device
qualified and founder approved/protected on the checksum-matched OPPO. No
protected baseline was changed. The next action is read-only audit only; any
runtime successor requires a unique pre-write registration.

## Problem and correction

AUDIT7 reproduced Shop-scoped Cart/Checkout selecting Medicine, Wholesale
selecting Shop, and Medicine selecting Wholesale. `_BuyDock` read stale
`session.destination` even though the live transaction owner was already in
`cartScope` / `checkoutScope`.

The correction adds one side-effect-free derived owner in
`apps/mobile/lib/features/buy/buy_v2_session.dart` and uses it only for active
dock reads in `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`. All scope retains
the actual entry destination. Focused coverage is in
`apps/mobile/test/ui_v2/buy/buy_v2_scoped_cart_checkout_dock_continuity_test.dart`
and five candidate captures. No route, header, Cart, Checkout, payment, order,
provider, backend or shared-motion state changed.

## Qualified identity and evidence

- source: 2,466 files, SHA-256
  `D7D382F57D672E11819173B591F3C4BE30A029CCF3AE5AC426FE30D132E14649`;
- APK/install: profile `1.0.0-r58.16` (`2026080412`), SHA-256
  `8584CCD4D37227DC3D00952CBB8A283F85F78CE961F9CF58D55B153FAD1BA052`;
- immutable evidence:
  `artifacts/quality/buy-scoped-cart-checkout-dock-continuity-r58-8-7-fix1-20260804-159`;
- technical summary: `159/150-technical-device-qualification-summary.md`;
- founder checks: `159/151-founder-review-observation-points.md`.

Focused and related suites, two complete Buy regressions, every release and
protected classifier, mandatory build/install identity gates, all-scope OPPO
journeys, focus/Back/lifecycle/recreation, visible reduced motion, performance,
runtime scan and zero source drift passed. The device is on a clean Shop root
with animation scales `1/1/1`.

Provider/payment/order outcomes, settlement/refunds/disputes, stock,
serviceability, addresses, backend recovery, async loading and campaign/video
effects remain dependency-held. No commit, push, merge, deployment,
publication, cleanup, branch switch or baseline replacement is authorized.
