# Buy V2 R37.3 seeded offers and Saved handoff

Date: 31 July 2026

Status: checksum-matched OPPO candidate verified; founder acceptance and
baseline promotion remain pending.

## Repository identity

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Candidate source fingerprint:
  `AFB65E9D7F4C4F8E51439B3BBD6DE30FAD6AEBB3CB63C924CECDD9E47080DE56`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- The protected R35.1 Buy baseline remains unchanged and correctly rejects
  this unpromoted 31-file runtime candidate against its locked 28-file
  inventory.
- No commit, push, deploy, publication or baseline promotion was performed.

## Candidate identity

- Candidate ID: `BUY-R37.3-SEEDED-OFFERS-SAVED-DEVICE`
- Version: `1.0.0-r37.3`
- Version code: `2026073150`
- APK bytes: `200231916`
- APK SHA-256:
  `EF7823E8902BC65E23F5C3FBB5DCA7E94D9B04059033DA41C85718E8CF27A089`
- Connected OPPO: serial `2b3e0f71`, model `CPH2375`
- Pulled installed `base.apk`: exact byte and SHA-256 match
- Runtime marker: exact candidate ID and ready authenticated device-review
  state passed

The candidate and all additive R37.3 evidence are under:

`artifacts/quality/buy-flutter-r37-cart-relevance-oppo-20260731-40/r37-3-seeded-offers-saved-device`

## Completed behavior

### Coupons and payment offers

1. The normal production default remains fail-closed and empty while the
   benefits backend is disconnected.
2. `MOOLSOCIAL_DEVICE_REVIEW=true` selects a compile-time seeded adapter so the
   same typed production UI/session path can be exercised on the OPPO.
3. Shop, Wholesale and Medicine each expose one coupon and one payment-offer
   state with vertical-owned vocabulary.
4. Seed cards contain no bank, code, amount, percentage, threshold,
   entitlement or redeemed claim.
5. Select and remove are kind- and vertical-owned. A stale or malformed value
   still fails closed.
6. Selection projects into Checkout as a review state without changing the
   Cart, Checkout or order total.

### Saved products

1. The summary and changed-mind clear action share one compact row.
2. Saved products use one horizontal decision lane, showing two product
   decisions together at the OPPO width.
3. Each Saved product exposes an explicit 44-pixel `Remove` target plus its
   own `+`, minus and quantity controls.
4. Adding the second Saved Shop product changed the device Cart from four to
   five items. Removing it from Saved retained all five Cart items.
5. Clearing the final Saved item required explicit confirmation and again
   retained the five-item Cart.
6. The existing Wholesale minimum-order and Medicine prescription gates remain
   owned by the productwise add path.

## Qualification results

- Final `flutter analyze`: passed with no issues.
- Focused Cart/Saved/offer tests: 19/19 passed.
- Final complete Buy regression 1: 167/167 passed; four intentional screenshot
  generators skipped.
- Final complete Buy regression 2: 167/167 passed; four intentional screenshot
  generators skipped.
- Source drift across the two final regressions: zero.
- Source drift after guarded build and OPPO replay: zero.
- Approved UI locks: passed.
- Brand integrity: passed.
- Founder FINAL Buy reference: 25 immutable files passed.
- Interaction contracts: 154 unique routes passed.
- User-facing copy: passed.
- HTML customer copy: nine read-only screenbook states passed; temporary local
  server stopped and port released.
- Buy backend-contract boundary and adversarial self-test: passed.
- Buy data-egress boundary and adversarial self-test: passed.
- Protected Social baseline: 119 files and exact tree hash passed before and
  after device replay.
- OPPO replay log scan: zero fatal, unhandled Flutter, or RenderFlex overflow
  matches.

Primary qualification logs are `09-final-flutter-analyze.log`,
`12-final-buy-regression-1.log`, `13-final-buy-regression-2.log`,
`15-final-source-stability.txt`, `16-approved-ui-locks.log` through
`31-buy-protected-baseline-disposition.txt`, `32-guarded-clean-build.log`,
`40-installed-apk-checksum-match.txt`, `42-runtime-marker-gate.log`,
`65-oppo-replay-crash-overflow-scan.txt` and
`67-final-source-stability-after-device.txt`.

## Device evidence

- Mixed Cart after motion settled: `49-oppo-mixed-cart-settled.png`
- Shop coupon and selected state: `50-oppo-shop-coupon-seeded.png` and
  `51-oppo-shop-coupon-selected.png`
- Shop payment offer: `52-oppo-shop-payment-offer-seeded.png`
- Wholesale coupon and payment offer:
  `53-oppo-wholesale-coupon-seeded.png` and
  `54-oppo-wholesale-payment-offer-seeded.png`
- Medicine coupon and payment offer: `55-oppo-medicine-coupon-seeded.png` and
  `56-oppo-medicine-payment-offer-seeded.png`
- Checkout projection with unchanged `₹1,225` review total:
  `57-oppo-checkout-with-seeded-offer-top.png`
- Two-product Saved decision lane:
  `59-oppo-saved-two-product-decisions-settled.png`
- Second Saved product added to Cart:
  `60-oppo-saved-second-added-to-cart.png`
- Product removed from Saved while Cart retained:
  `61-oppo-saved-second-removed-cart-retained.png`
- Confirmed clear and empty Saved state with Cart retained:
  `62-oppo-saved-clear-confirmation.png` and
  `63-oppo-saved-cleared-cart-retained.png`

Each material screenshot has a matching accessibility hierarchy where the
same numeric prefix is present.

## Candidate-owned files

Modified existing files:

- `apps/mobile/lib/features/buy/buy_v2_models.dart`
- `apps/mobile/lib/features/buy/buy_v2_session.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart`
- `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_session_test.dart`
- `docs/delivery/BUY-FLUTTER-V2-PRODUCTION-TICKETS-20260729.md`

New candidate files:

- `apps/mobile/lib/features/buy/buy_v2_cart_contracts.dart`
- `apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_cart_relevance_test.dart`
- `apps/mobile/test/ui_v2/buy/buy_v2_cart_relevance_widget_test.dart`
- `docs/delivery/BUY-V2-R37-SEGMENT-AWARE-CART-CONTRACT-20260731.md`
- this handoff

Existing unrelated untracked evidence, generated captures and temporary files
remain preserved and are not candidate commit scope.

## Remaining production gaps and founder gate

1. The benefits backend, eligibility quote, redemption and monetary contracts
   do not exist. Normal builds therefore remain honestly empty.
2. The seeded cards are UI-review data only; they are not production offers or
   customer entitlements.
3. Saved choices remain owned only for the active authenticated application
   session. Cross-relaunch retention is blocked on approved account ownership,
   classification, consent, retention, deletion, sign-out and migration
   behavior plus a real store adapter.
4. R37.3 is not a promoted Buy baseline and is not production acceptance.
5. The next founder decision is accept or reject this checksum-matched R37.3
   candidate. Commit, push and baseline promotion require separate explicit
   authorization.
