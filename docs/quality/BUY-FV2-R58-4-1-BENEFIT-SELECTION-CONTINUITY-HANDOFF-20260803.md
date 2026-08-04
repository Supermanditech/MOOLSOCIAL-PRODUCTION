# Buy FV2 R58.4.1 benefit-selection continuity handoff

Date: 3 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED; FOUNDER REVIEW PENDING**

Candidate: `BUY-R58-BENEFIT-SELECTION-CONTINUITY-FIX1`

Profile: `1.0.0-r58.4` (`2026080317`)

## Exact identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,419 files, SHA-256
  `D1EE0B6DFC0D0282B45238A10BFC3A78CFDE3A9C458EFD911D025A1DACE5C6A1`
- Wrapper-produced and pulled-installed APK: 134,017,505 bytes, SHA-256
  `468C76D18ABC6756D6AA9A7BB017DE6F8061E4277F4AAA11EA1A9290331FB0CA`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Immutable evidence:
  `artifacts/quality/buy-offers-coupons-continuation-r58-4-audit-20260803-127`

## Defect and bounded fix

The established Cart Benefits page supported separate Shop/Wholesale/Medicine
Coupons and Payment offers, truthful selection/removal and Back. After a real
selection, however, it exposed no explicit forward owner to review that
selection in Cart.

The qualified fix adds one stable native completion action. With no selections
it says `Return to Cart`; with real session-owned selections it says
`Review <count> selection(s) in Cart`. It pops exactly one route, restores the
exact underlying Cart scope/scroll and never claims eligibility, application,
acceptance, discount or savings. It reuses R46 selection motion, R54 Back and
R58.3.1 Cart scroll ownership; reduced motion is immediate/static.

Exact runtime/test files:

- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_benefit_selection_continuity_test.dart`

## Qualification result

Host qualification passed clean analysis, 3/3 focused tests, 33/33 related
tests, two complete Buy regressions at 304 active passes plus 15 established
skips each, all positive gates and exact protected-boundary rejections.

On the checksum-matched OPPO install:

- Shop coupon, Wholesale payment offer and Medicine coupon selections produced
  honest one/two/three selection labels;
- Cart restored the exact original anchor, four products, vertical quantities
  and ₹1,296 total;
- Cart kept Coupons (two) and Payment offers (one) separate;
- reopening retained the exact selected owner and Remove action;
- Android system Back, visible app-bar Back and hot resume preserved route,
  state and scroll ownership;
- native semantics expose completion, destination and Select/Remove actions
  separately;
- process recreation returned to the approved Shop root without inventing
  in-memory persistence;
- the corrected 104-frame trace has p95 17.123 ms, zero frames over 33 or
  100 ms and zero shader/compile event;
- classified MoolSocial failures are zero;
- post-device source remains exact.

## Founder review points

1. In Cart, open Coupons and confirm the zero-state `Return to Cart` action is
   visible, stable and returns to the same Cart position.
2. Select one Shop coupon and confirm the label changes to
   `Review 1 selection in Cart` without saying applied, accepted or saved.
3. Add one Wholesale payment offer and one Medicine coupon; confirm the label
   reaches three and Cart reports Coupons two / Payment offers one separately.
4. Reopen the selected Wholesale payment offer and confirm its action is
   `Remove`, then use system Back and visible Back to verify exact Cart return.
5. With reduced motion enabled, confirm label/return behavior is immediate and
   static with no geometry jump.

Technical/device qualification is not founder approval. R58.2 remains founder
approved/protected. R58.1 and R58.3.1 remain founder-review pending. R58.4.2
and later families require their own registered audit and source seal.
