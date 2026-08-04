# Buy FV2 R58.8.6 Checkout Cart return continuity handoff — 4 August 2026

## Founder approval — 4 August 2026

The founder explicitly approved exact candidate
`BUY-R58-CHECKOUT-CART-RETURN-CONTINUITY-FIX1`. It is now founder
approved/protected at source SHA-256
`8F3ACE96BDF036AEB28F2A2EFF448DDF1B72B9152F9D43B435DD21B224FEA075`
and APK/install SHA-256
`137E8DC5A9013115A9F45BDCD644445BBB98D0039B92580C8BC4A924A7E7EA05`.
Authority: `artifacts/quality/buy-r58-8-6-founder-approval-20260804-157`.
All exclusions and no-baseline/no-promotion boundaries remain in force.

## Disposition

`BUY-R58-CHECKOUT-CART-RETURN-CONTINUITY-FIX1` is technically/device qualified
on OPPO and founder approved/protected. No protected baseline was changed. A
next read-only audit is authorized by the existing navigation directive; any
runtime successor still requires a new pre-write registration and qualification.

## Problem and correction

AUDIT6 reproduced a Shop-scoped Checkout whose visible `Cart` semantic centre
did not hit the compact chip and whose visual tap called default `openCart()`,
changing Shop scope into combined Cart. Android Back already used the correct
`checkoutScope`.

The fix binds the visible action to `session.openCart(scope:
session.checkoutScope)`, gives that private call a single compact semantic and
physical owner with a 44 logical-pixel minimum height, and leaves shared
defaults unchanged. Exact files:

- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`;
- `apps/mobile/test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart`;
- five R58.8.6 captures under
  `apps/mobile/test/ui_v2/buy/candidate_captures/`.

## Qualified identity and evidence

- source: 2,460 files, SHA-256
  `8F3ACE96BDF036AEB28F2A2EFF448DDF1B72B9152F9D43B435DD21B224FEA075`;
- APK/install: profile `1.0.0-r58.15` (`2026080411`), SHA-256
  `137E8DC5A9013115A9F45BDCD644445BBB98D0039B92580C8BC4A924A7E7EA05`;
- immutable evidence:
  `artifacts/quality/buy-checkout-cart-return-continuity-r58-8-6-fix1-20260804-156`;
- technical summary: `156/150-technical-device-qualification-summary.md`;
- founder checks: `156/151-founder-review-observation-points.md`.

Every host/release/machine gate, two complete Buy regressions, checksum-matched
OPPO all-scope replay, Android Back/child sheet/lifecycle/recreation, visible
reduced motion, performance and runtime-failure scan passed. The device is on a
clean Shop root with animation scales `1/1/1`.

## Next isolated audit after disposition

During mixed-family replay, a Shop-scoped Checkout could still show Medicine as
the selected bottom-navigation vertical because destination ownership and
Checkout scope are currently separate. This was not changed or qualified in
R58.8.6. The safe successor is a read-only bottom-navigation/Checkout-owner
audit; any confirmed defect must be registered under a unique candidate before
runtime write.

Provider payment/order truth, settlement, refunds, disputes, stock,
serviceability, addresses, backend recovery, loading effects and campaign/video
effects remain dependency-held. No commit, push, merge, deployment, publication,
cleanup, branch switch, or protected-baseline replacement is authorized.
